
/*
	create_profile:
		@param this_survey_id varchar(50): id string for profile
		@param sample_percentage_theta float: Probability of sampling each row from thetas table when creating a profile. Number between 0 (no rows) to 100 (full table).
	
	Creates a profile using survey id.
	Initialize uniform prior over parameters in thetas.
	Returns profile_id int: index of profile just created.
*/
CREATE OR REPLACE FUNCTION create_profile(this_survey_id VARCHAR(50), sample_percentage_theta float DEFAULT 100)
RETURNS INT
AS $BODY$
DECLARE
    random_sample text := '';
	query_text text;
	return_id INT;
BEGIN

	-- If sample_percentage_theta < 100, then sample each row from thetas with probability sample_percentage_theta
	IF sample_percentage_theta < 100 THEN
		random_sample := ' TABLESAMPLE BERNOULLI('|| quote_literal(sample_percentage_theta) ||') ';
	END IF;

	-- Generate a uniform prior for the thetas under consideration.
	-- Create a profile for this_survey_id and store indices and posterior
	query_text := '
		INSERT INTO profiles(survey_id, keep_indices, posterior, sample_percentage_theta)
		WITH theta_values AS (
			SELECT
				index_t,
				1.0 / COUNT(index_t) OVER () posterior
			FROM thetas '|| random_sample ||'
		)
		SELECT
			'|| quote_literal(this_survey_id) ||' survey_id,
			array_agg(index_t order by index_t) keep_indices,
			array_agg(posterior order by index_t) posterior,
			'|| quote_literal(sample_percentage_theta) ||' sample_percentage_theta
		FROM theta_values
		RETURNING profile_id AS return_id';
	
	EXECUTE query_text INTO return_id;
	RETURN return_id;

END;
$BODY$ LANGUAGE plpgsql;


/*
	Choose design for a given profile_id

	@param this_profile_id int: primary key in profiles specifying profile_id
	@param sample_percentage_designs float: Percentage of designs in the full_likelihood grid for which the mutual information is calculated
	@param allow_repeats boolean: If true, allow the algorithm to consider designs that have been previously shown. If false, consider designs that have not been returned.

	Calculates the mutual information for sample_percentage_designs % of designs. Updates design_history and returns the design with the largest mutual information gain. 

*/
CREATE OR REPLACE FUNCTION choose_design(this_profile_id INT, sample_percentage_designs float DEFAULT 100, allow_repeats boolean DEFAULT true)
RETURNS TABLE(
    index_d INT,
    design float[]
)
AS $BODY$
DECLARE
    best_design INT;
	conditional text := '';
	query_text text;
	sample_designs text := '';
BEGIN

	-- Lock design History
	EXECUTE 'SELECT profiles.design_history FROM profiles WHERE profiles.profile_id = '|| quote_literal(this_profile_id) ||' FOR UPDATE';
	
	-- text to avoid repeats
	IF NOT allow_repeats THEN 
		conditional := 'AND NOT fl.index_d  = ANY(profiles.design_history) ';
	END IF;

	-- text to sample designs for consideration with probability sample_percentage_designs
	IF sample_percentage_designs < 100 THEN
		sample_designs := ' TABLESAMPLE BERNOULLI('|| quote_literal(sample_percentage_designs) ||') ';
	END IF;

	query_text := '
		WITH mutual_info AS (
			SELECT
				CASE
					WHEN sample_percentage_theta < 100 THEN mutual_information(subset_array(keep_indices, likelihood), posterior)
					ELSE mutual_information(likelihood, posterior)
				END mi,
				fl.index_d
			FROM full_likelihood fl '|| sample_designs ||'
			LEFT JOIN profiles ON true
			WHERE profile_id = '|| quote_literal(this_profile_id) || conditional ||'
			)
			SELECT
				mutual_info.index_d
			FROM mutual_info
			WHERE mutual_info.mi = (SELECT max(mi) FROM mutual_info)
			ORDER BY random()
			LIMIT 1;
	';

	EXECUTE query_text INTO best_design;

    -- Update design_history in profile
    UPDATE profiles
    SET design_history = ARRAY_APPEND(design_history, best_design)
    WHERE profile_id = this_profile_id;

    -- Return design characteristics for best_design
    RETURN QUERY
    SELECT
        designs.*
    FROM designs
    WHERE designs.index_d = best_design;
	

END;
$BODY$ LANGUAGE plpgsql;

/*
    Update posterior based on answer:
		@param this_profile_id int: primary key in profiles specifying profile_id
		@param answer int: answer chosen by the individual: {1 - treated option, 0 - base option}

	Updates profile posterior using Bayes rule based on answer.
*/
CREATE OR REPLACE FUNCTION update_posterior(this_profile_id INT, answer INT)
RETURNS void
AS $BODY$
DECLARE
	calc_new_posterior text;
	query_text text;
BEGIN

	-- Lock posterior
	EXECUTE ' SELECT profiles.posterior FROM profiles WHERE profiles.profile_id = '|| quote_literal(this_profile_id) ||' FOR UPDATE;';

	IF answer = 1 THEN
		calc_new_posterior := ' u.likelihood * u.posterior / sum(u.likelihood * u.posterior) OVER () new_posterior';
	ELSE
		calc_new_posterior := ' (1 - u.likelihood) * u.posterior / sum((1 - u.likelihood) * u.posterior) OVER () new_posterior';
	END IF;

	query_text := '
		WITH this_profile AS (
			SELECT
				prof.keep_indices,
				prof.posterior,
				CASE
					WHEN prof.sample_percentage_theta < 100 THEN subset_array(prof.keep_indices, fl.likelihood)
					ELSE fl.likelihood
				END likelihood
			FROM profiles prof
			LEFT JOIN full_likelihood fl ON fl.index_d = prof.design_history[array_length(prof.design_history, 1)]
			WHERE prof.profile_id = '|| quote_literal(this_profile_id) ||'
		), calc_posterior AS (
			SELECT
				u.index_t,
				'|| calc_new_posterior ||'
			FROM this_profile tp, unnest(tp.keep_indices, tp.likelihood, tp.posterior) AS u(index_t, likelihood, posterior)
		), new_prof AS (
			SELECT
				array_agg(cp.new_posterior ORDER BY cp.index_t) new_posterior
			FROM calc_posterior cp
		)
		UPDATE profiles
		SET posterior = np.new_posterior
		FROM new_prof np
		WHERE profiles.profile_id = '|| quote_literal(this_profile_id) ||';';

	EXECUTE query_text;

END;
$BODY$ LANGUAGE plpgsql;

/*
	update_and_choose_design:
		@param this_profile_id int: primary key in profiles specifying profile_id
		@param answer int: answer chosen by the individual: {1 - treated option, 0 - base option}
		@param sample_percentage_designs float: Percentage of designs in the full_likelihood grid for which the mutual information is calculated
		@param allow_repeats boolean: If true, allow the algorithm to consider designs that have been previously shown. If false, consider designs that have not been returned.
*/

CREATE OR REPLACE FUNCTION update_and_choose_design(this_profile_id INT, answer INT, sample_percentage_designs FLOAT DEFAULT 100, allow_repeats boolean DEFAULT true)
RETURNS TABLE(
	index_d INT,
	design float[]
)
AS $BODY$
BEGIN

	-- Update posterior based on answer using Bayes rule
	PERFORM update_posterior(this_profile_id, answer);

	-- Choose optimal design
	RETURN QUERY
	SELECT *
	FROM choose_design(this_profile_id, sample_percentage_designs, allow_repeats);

END;
$BODY$ LANGUAGE plpgsql;


/*
	return_estimates
		@param this_profile_id int: primary key in profiles specifying profile_id
	
	Calculate posterior estimates: sum(theta * posterior)
	Returns float[] array of estimates.
*/
CREATE OR REPLACE FUNCTION return_estimates(this_profile_id INT)
RETURNS float[]
AS $$
DECLARE
	query_text text;
	estimates float[];
BEGIN
	
	query_text := '
		WITH this_profile AS (
			SELECT
				unnest(keep_indices) index_t,
				unnest(posterior) posterior
			FROM profiles
			WHERE profile_id = '|| quote_literal(this_profile_id) ||' 
		), merged_thetas AS (
			SELECT
				thetas.index_t,
				thetas.theta,
				this_profile.posterior
			FROM this_profile
			LEFT JOIN thetas USING(index_t)
		), unnest_array_vals AS (
			SELECT
				merged_thetas.index_t,
				merged_thetas.posterior,
				u.tval,
				u.ti
			FROM merged_thetas, unnest(merged_thetas.theta) WITH ORDINALITY AS u(tval, ti)
		), weighted_sum AS (
			SELECT
				uav.ti ti,
				sum(uav.posterior * uav.tval) estimate
			FROM unnest_array_vals uav
			GROUP BY uav.ti
		)
		SELECT
			array_agg(weighted_sum.estimate ORDER BY weighted_sum.ti) estimates
		FROM weighted_sum;	
	';

	EXECUTE query_text INTO estimates;
	RETURN estimates;

END;
$$ LANGUAGE plpgsql;

-- Update posterior based on answer then calculate and return estimates.
CREATE OR REPLACE FUNCTION update_and_return_estimates(this_profile_id INT, answer INT)
RETURNS TABLE(
	estimates float[]
)
LANGUAGE plpgsql
AS $$
BEGIN

	-- Update posterior based on answer using Bayes' rule
	PERFORM update_posterior(this_profile_id, answer);
	
	-- Calculate posterior estimates and return
	RETURN QUERY
	SELECT *
	FROM return_estimates(this_profile_id);
	
END;
$$;

/*
	random_design: Return random design from designs.
*/
CREATE OR REPLACE FUNCTION random_design()
RETURNS TABLE(
	index_d INT,
	design float[]
)
AS $$
BEGIN

	RETURN QUERY
	SELECT *
	FROM designs
	OFFSET random() * (SELECT COUNT(*) FROM designs)
	LIMIT 1;

END;
$$ LANGUAGE plpgsql;


/*
	subset_array:
		@param indices_to_keep int[]: array of integers that correspond to indices from arr_in that should be returned
		@param arr_in float[]: array to be subsetted
	
	Maps indices in indices_to_keep to corresponding element in arr_in

	Ex. subset_array(
		indices_to_keep => ARRAY[1, 3, 5, 6],
		arr_in => ARRAY[0.1, 0.2, 0.3, 0.4, 0.5, 0.7, 0.9]
	)
	Returns: ARRAY[0.1, 0.3, 0.5, 0.7]
*/

 CREATE OR REPLACE FUNCTION subset_array(indices_to_keep INT[], arr_in float[])
 RETURNS float[]
 AS $$
 DECLARE
 	arr_out float[] := array_fill(NULL::float, ARRAY[array_length($1, 1)]);
	ind INT;
	counter INT := 1;
 BEGIN
 	
	
	FOREACH ind IN ARRAY $1
	LOOP
		arr_out[counter] := $2[ind];
		counter := counter + 1;
	END LOOP;
				
	RETURN arr_out;
 
 END;
 $$ LANGUAGE plpgsql IMMUTABLE STRICT;


/* 
    Calculate Mutual Information between likelihood and posterior
		@param likelihood_array float[]: likelihood_array[i] is the likelihood of choosing the treated option under theta with index_t = i
		@param posterior_array float[]: posterior_array[i] is the posterior estimate that the theta with index_t = i is correct based on design and answer history

	Returns mutual_info float the mutual information between outcome random value (likelihood_array) and parameter random value (posterior)

*/
CREATE OR REPLACE FUNCTION mutual_information(likelihood_array float[], posterior_array float[])
RETURNS float 
AS
$$
DECLARE
	mutual_info float;
	tolerance float := 1e-15;
BEGIN

	WITH unnested AS (
		SELECT
			u.likelihood,
			u.posterior
			--SUM(u.likelihood * u.posterior) OVER () denominator
		FROM unnest($1, $2) AS u(likelihood, posterior)
	), calc_denominator AS (
		SELECT
			SUM(u.likelihood * u.posterior) denominator
		FROM unnested u
	), fix_denominator AS (
		SELECT
			CASE
				WHEN (cd.denominator - 1) >= 0 THEN 1 - tolerance
				WHEN cd.denominator < tolerance THEN tolerance
				ELSE cd.denominator
			END denominator
		FROM calc_denominator cd
	)
	SELECT
		SUM( u.posterior * ( ln(u.likelihood / fd.denominator) * u.likelihood + ln((1 - u.likelihood) / (1 - fd.denominator)) * (1 - u.likelihood) ) ) mi
	INTO
		mutual_info
	FROM unnested u
	LEFT JOIN fix_denominator fd ON true;

	RETURN ROUND(mutual_info::numeric, 12);
END;
$$ LANGUAGE plpgsql IMMUTABLE;


/*
	Functions used in db_user.sql to fill table values
*/
CREATE OR REPLACE FUNCTION select_cols(dim_m INT)
RETURNS text
AS $$
DECLARE
    query_text text;
    x INT;
BEGIN

    query_text := 'SELECT ARRAY[';

    FOR x IN 1..dim_m
    LOOP
        IF x > 1 THEN
            query_text := query_text || ', ';
        END IF;

        query_text := query_text || quote_ident('theta' || x);

    END LOOP;

    query_text := query_text || ']';

    RETURN query_text;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION order_cols(dim_m INT)
RETURNS text
AS $$
DECLARE
    query_text text;
    x INT;
BEGIN

    query_text := 'ORDER BY ';

    FOR x IN 1..dim_m
    LOOP
        IF x > 1 THEN
            query_text := query_text || ', ';
        END IF;

        query_text := query_text || quote_ident('theta' || x);

    END LOOP;

    RETURN query_text;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gen_grid_thetas(theta anyarray)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    dim_m int := array_length(theta, 1);
    dim_n int := array_length(theta, 2);
    query_text text;
    selected_cols text := select_cols(dim_m);
	order_of_cols text := order_cols(dim_m);
BEGIN

    query_text := 'INSERT INTO thetas(theta) ';

    IF dim_n IS NULL THEN
        query_text := query_text || 'SELECT ARRAY[theta] FROM generate_series(' || $1[1] || ', ' || $1[2] || ', ' || $1[3] || ') theta;';
    ELSE
	
		query_text := query_text || selected_cols ;

        FOR x IN 1..dim_m
        LOOP
            IF x = 1 THEN
                query_text := query_text || ' FROM ';
            ELSE
                query_text := query_text || ' CROSS JOIN ';
            END IF;

            query_text := query_text || '(SELECT theta theta' || x || ' FROM generate_series('|| $1[x][1] ||', '|| $1[x][2] ||', '|| $1[x][3] ||') theta ) theta'|| x ||'s ';

        END LOOP;

        query_text := query_text || order_of_cols || ';';
		
    END IF;

    EXECUTE query_text;

END;
$$;

CREATE OR REPLACE FUNCTION gen_grid_designs(diff_earnings anyarray)
RETURNS void
AS $$
BEGIN

    WITH earnings AS (
        SELECT *
        FROM generate_series($1[1]::numeric, $1[2]::numeric, $1[3]::numeric) x
    )
    INSERT INTO designs(design)
    SELECT
        array_prepend(earnings.x::float, design_structures.design_structure) design
    FROM earnings
    CROSS JOIN design_structures;
END;
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION exp_safe(x float)
RETURNS float
AS $$
BEGIN

	RETURN exp(x);
	EXCEPTION
		WHEN numeric_value_out_of_range THEN
			IF x > 0 THEN
				RETURN 1e15;
			ELSE
				RETURN 1e-15;
			END IF;

END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


CREATE OR REPLACE FUNCTION ln_safe(x float)
RETURNS float
AS $$
DECLARE
    default_low float := -1e6;

BEGIN
	RETURN ln(x);
	EXCEPTION
		WHEN numeric_value_out_of_range THEN
            IF x < 1 THEN
                RETURN default_low;
            END IF;

END;
$$ LANGUAGE plpgsql IMMUTABLE STRICT;


-- Exit Message to be read after db_user.sql runs
CREATE OR REPLACE FUNCTION exit_message()
RETURNS void
AS $$
DECLARE
    n_designs INT; 
    n_thetas INT; 
    n_likelihood_designs INT; 
    n_likelihood_length INT;
	null_rows INT;
BEGIN

    SELECT COUNT(*) FROM designs INTO n_designs; -- Number of rows in designs table
    SELECT COUNT(*) FROM thetas INTO n_thetas; -- Number of rows in thetas table
    SELECT COUNT(*) FROM full_likelihood INTO n_likelihood_designs; -- Number of rows in full_likelihood table
    SELECT DISTINCT(array_length(likelihood, 1)) FROM full_likelihood INTO n_likelihood_length; -- Length of likelihood array in full_likelihood table
	SELECT COUNT(*) FROM full_likelihood WHERE array_position(likelihood, NULL) IS NOT NULL INTO null_rows;

    RAISE NOTICE '
        Number of designs: %
        Number of full_likelihood designs: %
        Number of thetas: %
        Length of likelihood array in full_likelihood: %
		Number of rows in full_likelihood containing null values: %
    ', n_designs, n_likelihood_designs, n_thetas, n_likelihood_length, null_rows;

    PERFORM check_empty(n_designs, 'designs');
    PERFORM check_empty(n_thetas, 'thetas');
    PERFORM check_empty(n_likelihood_designs, 'full_likelihood');
		
	IF n_designs != n_likelihood_designs THEN
		RAISE NOTICE 'ALERT: Number of rows in designs and full_likelihood are inequal. Something went wrong';
	END IF;

    If n_thetas != n_likelihood_length THEN
        RAISE NOTICE 'ALERT: Number of rows in thetas and the length of the precomputed array in full_likelihood are inequal.';
    END IF;

END; $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_empty(n INT, table_name text)
RETURNS void
AS $$
BEGIN
    IF n = 0 THEN
        RAISE NOTICE 'ALERT: % table is empty', table_name;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION gen_full_likelihood(tolerance float default 1e-15)
RETURNS void
AS $$
BEGIN
    
    INSERT INTO full_likelihood(index_d, likelihood)
    WITH likelihood_long AS (
        SELECT
            index_d,
            index_t,
            likelihood_func(design, theta) likelihood
        FROM designs, thetas
    )
    SELECT
        index_d,
        ARRAY_AGG(
            CASE 
                WHEN likelihood < tolerance THEN tolerance
                WHEN likelihood > (1 - tolerance) THEN (1 - tolerance)
                ELSE likelihood
            END
            ORDER BY index_t
        )
    FROM likelihood_long
    GROUP BY index_d;


END;
$$ LANGUAGE plpgsql;
