// Require express components
const express = require('express');
const router = express.Router();

//
const db = require('../db');
const types = require('pg').types;
const user = require('../user_modules/characteristics.js');

/*
// Add API CALLS HERE

// Example api call - router.get() for GET requests, router.put() for PUT requests, etc...
// Draw from random uniform
router.get('/random_number', async (req, res) => {

    // Draw from random uniform 0, 1
    var random_number = Math.random();

    // Return to user
    res.json({
        random_number: random_number
    })
    
})

*/

module.exports = router;
