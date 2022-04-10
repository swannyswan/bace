// Input your name here
const author_name = 'Anna Swanson';

// Should the algorithm consider designs that have already been shown to a respondent?
const allow_repeated_designs = Boolean(false); // true if yes, false if no

// Percentage of rows from theta to randomly sample and assign to each profile. Default 100 - All rows.
const default_sample_percentage_theta = 100;

// Percentage of question designs to randomly search over when choosing the optimal design each round. Default 100 - All rows
const default_sample_percentage_designs = 20;

// Export Functions to be used in other files.
module.exports = {
    author_name,
    allow_repeated_designs,
    default_sample_percentage_theta,
    default_sample_percentage_designs
};
