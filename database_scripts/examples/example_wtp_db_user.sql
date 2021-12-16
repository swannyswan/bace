/*
    ------------------------------------------------------------
    ----------------- USER INPUT HERE --------------------------
    ------------------------------------------------------------
*/

/*
    This script shows an example specification of the key database functions when we want to estimate WTP for a good.
    We expect the individual values the good between -$15 and +$15
    
    Thetas
        [-15, 15, 0.25] Range for WTP parameters
        [1, 5, 3] Consistency Parameters

    Design [WTP, 1{Has Good}]
        design_structures 
            ARRAY[1] Option always has good
        designs
            difference in price ranges from [start, end, increment] = [-15, 15, 0.1]

    Likelihood
        util_diff = diff_price + wtp_for_good = design[1] + design[2] * theta[1]
        Pr(Yes | design, theta) = 1.0 / ( 1.0 + exp(-1.0 * theta[2] * util_diff))

*/

-- Thetas
SELECT gen_grid_thetas(theta => ARRAY[
    -- INSERT ARRAY PARAMETERS HERE TO GENERATE GRID
    [-15, 15, 0.25],
    [1, 5, 2]
]);

-- Designs
INSERT INTO design_structures(design_structure)
VALUES
    (ARRAY[1]); -- Treated option has the good.    

SELECT gen_grid_designs(diff_earnings => ARRAY[-15, 15, 0.1]); -- earnings differences in designs will be [-15, -14.5, -14, ..., 14, 14.5, 15]


--Likelihood
CREATE OR REPLACE FUNCTION likelihood_func(design float[], theta float[])
RETURNS float
AS $$
DECLARE
    util_diff float; 
	likelihood float;
BEGIN
    util_diff := design[1] + theta[1] * design[2];
    likelihood := 1.0 / (1.0 + exp(-1.0 * theta[2] * util_diff));
	RETURN likelihood;
END;
$$ LANGUAGE plpgsql;

-- Generate likelihood functions
SELECT gen_full_likelihood(tolerance => 1e-15);

-- Generate indexes
CREATE INDEX pid ON profiles (profile_id);
CREATE INDEX did ON designs (index_d);
CREATE INDEX tid ON thetas (index_t);
CREATE INDEX fid ON full_likelihood (index_d);

-- Run Completion Message
SELECT exit_message();