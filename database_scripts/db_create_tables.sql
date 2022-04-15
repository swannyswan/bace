
-- Below are useful for dev. Uncomment this block if you want to delete tables that were created previously
DROP TABLE IF EXISTS thetas CASCADE;
DROP TABLE IF EXISTS design_structures;
DROP TABLE IF EXISTS designs CASCADE;
-- DROP TABLE IF EXISTS profiles CASCADE;
DROP TABLE IF EXISTS full_likelihood;


-- Schema for thetas
CREATE TABLE thetas(
	index_t SERIAL PRIMARY KEY,
    theta float[]
);

-- STEP 2: Schema for designs  ---
create table design_structures(
    design_id SERIAL PRIMARY KEY,
    design_structure float[]
);

create table designs(
	index_d SERIAL PRIMARY KEY,
	design float[]
);

--- CREATE profiles TABLE ----

CREATE TABLE profiles(
    profile_id SERIAL PRIMARY KEY,
    survey_id VARCHAR(50),
    design_history INT[] DEFAULT array[]::integer[],
    keep_indices INT[],
    posterior float[],
    sample_percentage_theta float
);

-- CREATE likelihood table in array format

CREATE TABLE full_likelihood(
    index_d INT PRIMARY KEY,
    likelihood float[]
);

-- Exit message
SELECT 'Finished running db_create_tables.sql';