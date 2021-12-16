const express = require('express');
const app = express();
const cors = require('cors');
const db = require('./db');
const types = require('pg').types;
const user_defaults = require('./user_modules/user_defaults.js');

//Import Routes
const api_custom = require('./routes/api_custom.js');
const api_raw = require('./routes/api_raw.js');
const user_defined_calls = require('./routes/user_defined_calls.js');

// Middleware
app.use(cors());
app.use(express.json());
app.use('/api_custom', api_custom);
app.use('/api_raw', api_raw);
app.use('/user_defined_calls', user_defined_calls);

// Converts numeric type, which arrives as a string from postgres, to float
types.setTypeParser(1700, function(val) {
    return parseFloat(val);
});

// Routes

app.get('/', async (req, res) => {

    const homepage = `
    <h1>Bayesian Adaptive Choice Experiment (BACE)</h1>
    <br>
    Author: ${user_defaults.author_name}
    <br>
    Your application is up and running. For more information, check out our <a href="https://github.com/mhdrake/bace_backend">github repository</a>.
    `;

    res.send(homepage);

})

const port = process.env.PORT || 8080;
app.listen(port, () => {
    console.log(`Application running successfully. Server has started on port ${port}`)
})
