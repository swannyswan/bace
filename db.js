const pgp = require('pg-promise')();
require('dotenv').config({ path: './.env'});

const db = pgp({
    connectionString: process.env.DATABASE_URL,
    ssl: {
        rejectUnauthorized: false
    }
});


/*
// You can test on a PostgreSQL database hosted locally by setting up a local connection as well
const db = pgp({
    user: ,
    host: ,
    database: ,
    password: ,
    port: 
})
*/


module.exports = db;