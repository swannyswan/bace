// Require express components
const express = require('express');
const router = express.Router();

// Other requirements
const db = require('../db.js'); // db connection
const types = require('pg').types; // process postgres data types
const user_defaults = require('../user_modules/user_defaults.js'); // import user default values

// Converts numeric type, which arrives as a string from postgres, to float
types.setTypeParser(1700, function(val) { return parseFloat(val); });

// Generate profile
router.post('/create_profile', async (req, res) => {

    // Store query variables from req.body. Set sample_percentage_h to default value in characteristics.js if unspecified.
    const survey_id = req.body.survey_id;
    const sample_percentage_theta = (typeof req.body.sample_percentage_theta === 'undefined' ? user_defaults.default_sample_percentage_theta : req.body.sample_percentage_theta);  

    // Structure query to creat profile
    const query = 'SELECT create_profile AS profile_id FROM create_profile(this_survey_id => $1, sample_percentage_theta => $2);';
    const values = [survey_id, sample_percentage_theta];

    // Query database
    db.one(
        query,
        values
    ).then(data => {
        // Send data in json format as response.
        res.json(data)
    }).catch(err => {
        // Catch errors and return
        // Returns { profile_id }
        res.json(err)
    });    
})

router.put('/choose_first_design', async (req, res) => {

    // Store request variables.
    const profile_id = parseInt(req.body.profile_id);
    const sample_percentage_designs = (typeof req.body.sample_percentage_designs === 'undefined' ? user_defaults.sample_percentage_designs : req.body.sample_percentage_designs);  

    // Structure database query
    const query = 'SELECT * FROM choose_design(this_profile_id => $1, sample_percentage_designs => $2);';
    const values = [profile_id, sample_percentage_designs];

    // Send query
    db.one(
        query,
        values
    ).then(data => {
        // Return data to user. Data has form { index_d: INT , design: ARRAY }.
        res.json(data)
    }).catch(err => {
        // Catch errors and send
        res.json(err);
    });
})

router.put('/update_and_choose_design', async (req, res) => {

    // Store request variables.
    const profile_id = parseInt(req.body.profile_id);
    const sample_percentage_designs = (typeof req.body.sample_percentage_designs === 'undefined' ? user_defaults.sample_percentage_designs : req.body.sample_percentage_designs);  
    const answer = parseInt(req.body.answer); // 1 if treated option is chosen

    // Structure database query
    const query = 'SELECT * FROM update_and_choose_design(this_profile_id => $1, answer => $2, sample_percentage_designs => $3, allow_repeats => $4);';
    const values = [profile_id, answer, sample_percentage_designs, user_defaults.allow_repeated_designs];

    // Send query
    db.one(
        query,
        values
    ).then(data => {
        // Return data to user. Data has form { index_d: INT , design: ARRAY }.
        res.json(data)
    }).catch(err => {
        // Catch errors and send
        res.json(err);
    });
})

//update posterior and return estimates
router.put('/update_and_return_estimates', async (req, res) => {

    // Store request variables.
    const profile_id = parseInt(req.body.profile_id);

    // Check whether user chose the treated option
    const answer = parseInt(req.body.answer);

    // Structure database query
    const query = 'SELECT * FROM update_and_return_estimates(this_profile_id => $1, answer => $2);';
    const values = [profile_id, answer];

    // Send query and return estimates to user.
    db.one(
        query,
        values
    ).then(data => {        
        res.json(data) // Return estimates to user in form { estimates: ARRAY }
    }).catch(err => {
        res.json(err); // Catch errors and send
    });
})

// Retrieve random design
router.get('/random_design', async (req, res) => {

    const query = 'SELECT * FROM random_design()';

    db.one(
        query
    ).then(data => {
        res.json(data)
    }).catch(err => {
        res.json(err)
    })
})

module.exports = router;