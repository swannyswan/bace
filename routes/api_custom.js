// Require express components
const express = require('express');
const router = express.Router();

// Other requirements
const db = require('../db.js'); // db connection
const types = require('pg').types; // process postgres data types
const user = require('../user_modules/characteristics.js'); // import user specific functions
const user_defaults = require('../user_modules/user_defaults.js');

// Converts numeric type, which arrives as a string from postgres, to float
types.setTypeParser(1700, function(val) { return parseFloat(val); });

// Generate profile
router.post('/create_profile', async (req, res) => {

    // Return sample output from fake API call
    if (req.body.test === 'test') {

        // Example output helpful for setting up embedded data in Qualtrics
        var sample_output = {
            profile_id: 0,
            characteristic_a: 'TEST',
            characteristic_b: 'TEST'
        }

        // Return sample_output as response to user.
        res.json(sample_output);

    } else {

        // Store query variables from req.body. Set sample_percentage_h to default value in characteristics.js if unspecified.
        const survey_id = req.body.survey_id;
        const sample_percentage_theta = (typeof req.body.sample_percentage_theta === 'undefined' ? user_defaults.default_sample_percentage_theta : req.body.sample_percentage_h);  

        // Structure query to creat profile
        const query = 'SELECT create_profile AS profile_id FROM create_profile(this_survey_id => $1, sample_percentage_theta => $2);';
        const values = [survey_id, sample_percentage_theta];

        // Assign characteristics a and b
        const [characteristic_a, characteristic_b] = user.sample_characteristics(user.characteristics);

        // Set payment frequency (monthly or one-time) and base value
        const [monthly_payment, base_earnings] = user.gen_payment_params();

        // Query database
        db.one(
            query,
            values
        ).then(data => {

            // Receive data. Format as JSON object with additional information that you want to include.
            
            // Add characteristic a and b variables to data
            data.characteristic_a = characteristic_a;
            data.characteristic_b = characteristic_b;

            // Add payment frequency and base earnings to data
            data.monthly_payment = monthly_payment;
            data.base_earnings = base_earnings;

            // Send data in json format as response.
            res.json(data)

        }).catch(err => {
            
            // Catch errors and return
            res.json(err)

        });

    }


    
})

router.put('/choose_first_design', async (req, res) => {

    const qnumber = 0;
    var query;

    // Return example test call for randomly selected questions to set up Qualtrics embedded data
    if (req.body.test === 'test') {

        // Query random design
        query = 'SELECT * FROM random_design();';

        db.one(
            query
        ).then(data => {

            // Format output object with sample values.
            var output = user.convert_design(
                data,
                user.characteristics,
                qnumber,
                user.example_base_earnings,
                Object.keys(user.characteristics)[0], 
                Object.keys(user.characteristics)[1]
            )

            // Change output labels to indicate test is selected.
            output['label_a'] = 'TEST';
            output['label_b'] = 'TEST';

            // Send json as response
            res.json(output);

        })

    } else {

        // Store request variables.
        const profile_id = parseInt(req.body.profile_id);
        const monthly_payment = parseInt(req.body.monthly_payment);
        const base_earnings = parseInt(req.body.base_earnings);
        const characteristic_a = req.body.characteristic_a;
        const characteristic_b = req.body.characteristic_b;
        const sample_percentage_designs = (typeof req.body.sample_percentage_designs === 'undefined' ? user_defaults.sample_percentage_designs : req.body.sample_percentage_designs);  

        // Structure database query
        query = 'SELECT * FROM choose_design(this_profile_id => $1, sample_percentage_designs => $2);';
        const values = [profile_id, sample_percentage_designs];

        // Send query
        db.one(
            query,
            values
        ).then(data => {

            // Convert data using user-specified function
            var output = user.convert_design(data, user.characteristics, qnumber, monthly_payment, base_earnings, characteristic_a, characteristic_b);

            // Return output to user
            res.json(output)

        }).catch(err => {

            // Catch errors and send
            res.json(err);

        })
    }

})

router.put('/update_and_choose_design', async (req, res) => {

    // Store qnumber
    const qnumber = req.body.qnumber;
    var query;

    // Return example test call for randomly selected questions to set up Qualtrics embedded data
    if (req.body.test === 'test') {

        // Query random design
        query = 'SELECT * FROM random_design();';

        db.one(
            query
        ).then(data => {

            // Format output object with sample values.
            var output = user.convert_design(
                data,
                user.characteristics,
                qnumber,
                user.example_base_earnings,
                Object.keys(user.characteristics)[0], 
                Object.keys(user.characteristics)[1]
            )

            // Change output labels to indicate test is selected.
            output['label_a'] = 'TEST';
            output['label_b'] = 'TEST';

            // Send json as response
            res.json(output);

        })

    } else {

        // Store request variables.
        const profile_id = parseInt(req.body.profile_id);
        const base_earnings = parseFloat(req.body.base_earnings);
        const characteristic_a = req.body.characteristic_a;
        const characteristic_b = req.body.characteristic_b;
        const sample_percentage_designs = (typeof req.body.sample_percentage_designs === 'undefined' ? user_defaults.sample_percentage_designs : req.body.sample_percentage_designs);  

        // Check whether user chose the treated option
        const answer = user.check_answer(parseInt(req.body.answer));

        // Structure database query
        query = 'SELECT * FROM update_and_choose_design(this_profile_id => $1, answer => $2, sample_percentage_designs => $3, allow_repeats => $4);';
        const values = [profile_id, answer, sample_percentage_designs, user_defaults.allow_repeated_designs];

        // Send query
        db.one(
            query,
            values
        ).then(data => {

            // Convert data using user-specified function
            var output = user.convert_design(data, user.characteristics, qnumber, base_earnings, characteristic_a, characteristic_b);

            // Return output to user
            res.json(output)

        }).catch(err => {

            // Catch errors and send
            res.json(err);

        });
    }

})

//update posterior and return estimates
router.put('/update_and_return_estimates', async (req, res) => {

    var query;

    // Send test output back for setting up embedded data variables
    if (req.body.test === 'test'){

        // Sample query of database to get design array
        query = 'SELECT * FROM random_design();'

        db.one(
            query
        ).then(data => {
            
            // Convert variables to 'test'
            var output = {
                estimates: data.design.map(x => 'test')
            };

            // Return test output
            res.json(output);

        }).catch(err => {
            res.json(err) // Catch and return errors
        })
    
    } else {

        // Store request variables.
        const profile_id = parseInt(req.body.profile_id);

        // Check whether user chose the treated option
        const answer = user.check_answer(parseInt(req.body.answer));

        // Structure database query
        query = 'SELECT * FROM update_and_return_estimates(this_profile_id => $1, answer => $2);';
        const values = [profile_id, answer];

        // Send query and return estimates to user.
        db.one(
            query,
            values
        ).then(data => {        
            res.json(data) // Return estimates to user
        }).catch(err => {
            res.json(err); // Catch errors and send
        });
    }
})

// Retrieve random design
// Not implemented for custom features yet.
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