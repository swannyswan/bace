/*
    ------------------------------------------------------------
    ----------------- USER INPUT HERE --------------------------
    ------------------------------------------------------------
*/

/*
    STEP 1: Generate Thetas - Create grid of possible parameter values for theta
    theta = ARRAY with size nparameters * 3.
    Generates a grid in R ^ nparameters of parameter values
    Each row is of the form [start, end, increment] and generates a sequence from theta[i][1] to theta[i][2] in steps of theta[i][3]    
*/

SELECT 'Generating theta grid...';

SELECT gen_grid_thetas(theta => ARRAY[
    -- INSERT ARRAY PARAMETERS HERE TO GENERATE GRID
    [0, 50, 5], -- Parameter 1 values
    [0, 50, 5], -- Parameter 2 values
    [0, 50, 5], -- Parameter 3 values
    [0, 32, 4], -- Parameter 4 values
    [1, 7, 3]] -- Parameter 5 values
--         [-4, 4, 2], -- Parameter 1 values will be: [-5, -4, ..., 4, 5]
--         [-4, 4, 2], -- Parameter 2 values will be: [-5, -4, ..., 4, 5]
--         [-4, 4, 2], -- Parameter 3 values will be: [-5, -4, ..., 4, 5]
--         [-15, 15, 5], -- Parameter 4 values will be: [-1.5, -1, -0.5, 0, 0.5, 1, 1.5]
--         [1, 11, 2]] -- Parameter 5 values will be: [1, 3, 5]
    );

/*
    STEP 2: CREATE Designs - Grid of possible discrete choice designs that can be asked
    design_structure - table with discrete choice values. design_structure - table with discrete choice values. Set up for 2 characteristics and an interaction term.
    Cross joined with diff_earnings = sequence from diff_earnings[1] to diff_earnings[2] in steps of diff_earnings[3]
        Generates the table designs:
        index_d: primary key
        design: ARRAY[diff_earnings] || ARRAY[design_structure]
*/

/* [grass, small trees, large trees, grass*trees] */

INSERT INTO design_structures(design_structure)
VALUES
--     (ARRAY[2, 1, 1]),
--     (ARRAY[2, -1, 0]),
--     (ARRAY[2, 0, 0]),
--     (ARRAY[2, 0, 1]),
--     (ARRAY[1, 1, 1]),
--     (ARRAY[1, -1, 0]),
--     (ARRAY[1, 0, 0]),
--     (ARRAY[1, 0, 1]),
--     (ARRAY[0, 1, 0]),
--     (ARRAY[0, 1, 1]);
    (ARRAY[1, 0, 1, 1]), -- A: nothing B: grass, large trees ; (0,0,0,0), (1,0,1,1)
    (ARRAY[0, 1, 0, 0]), -- A: small trees, B: nothing ; (0,1,0,0), (0,0,0,0)
    (ARRAY[0, 1, 0, 1]), -- A: grass, B: grass, small trees ;
    (ARRAY[-1, 1, 0, 0]), -- A: grass, B: small trees ;
    (ARRAY[1, 0, 0, 0]), -- A: nothing, B: grass
    (ARRAY[1, 1, 0, 1]), -- A: nothing, B: grass, small trees
    (ARRAY[0, 0, 1, 1]), -- A: grass, B: grass, large trees
    (ARRAY[0, 0, 1, 0]), -- A: large trees, B: nothing
    (ARRAY[1, 0, 0, 1]), -- A: small trees, B: grass, small trees
    (ARRAY[-1, 0, 1, 0]); -- A: grass, B: large trees


-- SELECT gen_grid_designs(diff_earnings => ARRAY[-12, 12, 0.25]); -- earnings differences in designs will be [-12, -11.75, -11.5, ..., 11.75, 12]
SELECT gen_grid_designs(diff_earnings => ARRAY[0, 20, 1]); -- earnings differences in designs will be [0, 0.25, 0.5, ..., 14.75, 15]

/*
    STEP 3: Update Likelihood Function
    Input
        design: array of design parameters defined in Step 2
        theta: array of coefficient parameters defined in Step 1
    -- Return likelihood of choosing the treated option
*/

CREATE OR REPLACE FUNCTION likelihood_func(design float[], theta float[])
RETURNS float
AS $$
DECLARE
util_diff float;
	likelihood float;
BEGIN
    -- Note, PostgreSQL arrays are 1-based. E.g. IF x = ARRAY[10, 4, 7], then x[1] = 10, x[2] = 4, ...
    -- util_diff = u(treat) - u(base)
    util_diff := -1.0 * design[1] + design[2] * theta[1] + design[3] * theta[2] + design[4] * theta[3] + design[5] * theta[4];
    -- Likelihood of choosing the treated option
    likelihood := 1.0 / (1.0 + exp_safe(-1.0 * theta[5] * util_diff));
RETURN likelihood;
END;
$$ LANGUAGE plpgsql;

/*
    Create likelihood table. (Optional) Set tolerance to scale numbers away from 0 and 1 to avoid underflow/divide by zero errors.
    likelihood < tolerance => likelihood = tolerance
    likelihood > (1 - tolerance) => likelihood = (1 - tolerance)
*/
SELECT gen_full_likelihood(tolerance => 1e-15);

-- Generate Indexes
CREATE INDEX pid ON profiles (profile_id);
CREATE INDEX did ON designs (index_d);
CREATE INDEX tid ON thetas (index_t);
CREATE INDEX fid ON full_likelihood (index_d);

-- Run Completion Message
SELECT exit_message();