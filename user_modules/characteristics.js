const characteristics_per_scenario = 3; // 3 characteristics (trees presence, tree size, and grass presence)
const example_base_earnings = 100; // Example base_earnings used for returning test output
const treated_survey_value = 1; // Recode value in Qualtrics

const characteristics = {
    characteristic_x: {
        label: 'Characteristic X - Small Trees Present',
        values: [
            0,
            1
        ]
    },
    characteristic_y: {
        label: 'Characteristic Y - Large Trees Present',
        values: [
            0,
            1
        ]
    },
    characteristic_z : {
        label: 'Characteristic Z - Grass Present',
        values: [
            0,
            1
        ]
    }
};

// Takes in design input. Returns Base and Treated Values
const convert_design = function(data, characteristics, qnumber, base_earnings, characteristic_a, characteristic_b){

    // Store earnings difference
    const diff_earnings = parseFloat(data.design[0]);

    var base_a, base_b, treat_a, treat_b;

    // Set base_earn and treat_earn from base_earning and treat_earnings.
    const [base_e, treat_e] = transform_earnings(base_earnings, diff_earnings)

    // Set base and treat values based on question designs.
    if (data.design[1] === 1 && data.design[2] === 1 & data.design[3] === 1) {
        
        base_a = 0;
        base_b = 0;
        treat_a = 1;
        treat_b = 1;

    } else if (data.design[1] === 1 && data.design[2] === -1 & data.design[3] === 0) {

        base_a = 0;
        base_b = 1;
        treat_a = 1;
        treat_b = 0;

    } else if (data.design[1] === 1 && data.design[2] === 0 & data.design[3] === 0) {

        base_a = 0;
        base_b = 0;
        treat_a = 1;
        treat_b = 0;

    } else if (data.design[1] === 1 && data.design[2] === 0 & data.design[3] === 1) {

        base_a = 0;
        base_b = 1;
        treat_a = 1;
        treat_b = 1;

    } else if (data.design[1] === 0 && data.design[2] === 1 & data.design[3] === 0) {

        base_a = 0;
        base_b = 0;
        treat_a = 0;
        treat_b = 1;

    } else if (data.design[1] === 0 && data.design[2] === 1 & data.design[3] === 1) {

        base_a = 1;
        base_b = 0;
        treat_a = 1;
        treat_b = 1;

    };

    // Set base and treat text values
    var base_char_a, base_char_b, treat_char_a, treat_char_b;
    base_char_a = characteristics[characteristic_a].values[base_a];
    treat_char_a = characteristics[characteristic_a].values[treat_a];
    base_char_b = characteristics[characteristic_b].values[base_b];
    treat_char_b = characteristics[characteristic_b].values[treat_b];

    // Prepare output as json object
    var output = {};

    // Set raw design information
    output['diff_earnings_' + qnumber] = diff_earnings;
    output['diff_d1_' + qnumber] = data.design[1];
    output['diff_d2_' + qnumber] = data.design[2];
    output['diff_d3_' + qnumber] = data.design[3];

    // Set Label Information
    output['label_a'] = characteristics[characteristic_a].label;
    output['label_b'] = characteristics[characteristic_b].label;

    // Set design information that will be seen by respondent
    output['base_earnings_' + qnumber] = base_e;
    output['treat_earnings_' + qnumber] = treat_e;
    output['base_a_' + qnumber] = base_char_a;
    output['base_b_' + qnumber] = base_char_b;
    output['treat_a_' + qnumber] = treat_char_a;
    output['treat_b_' + qnumber] = treat_char_b;

    // Return output
    return(output);

}

// Transform Earnings
const transform_earnings = function(base_earnings, diff_earnings){

    const base_e = parseFloat(base_earnings);
    const treat_e = base_e + diff_earnings;
    
    return([base_e, treat_e]);

}

// Compare answer to value for treated option. Return 1 if individual chose treated option. 0 otherwise.
const check_answer = function(answer, value_of_treated_option = treated_survey_value) {

    var is_correct = 1 * (answer === value_of_treated_option);
    return(is_correct);
}

// Sample n keys from obj without replacement.
const sample_characteristics = function(obj, n = characteristics_per_scenario) {

    var obj_keys = Object.keys(obj);
    return(shuffle(obj_keys).slice(0, n));

}

// Shuffle array using Fisher-Yates algorithm
function shuffle(array) {
    for (let i = array.length - 1; i > 0; i--) {
      let j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j], array[i]];
    }
    return(array);
}

// Export Functions to be used in other files.
module.exports = {
    characteristics,
    example_base_earnings,
    convert_design,
    shuffle,
    sample_characteristics,
    check_answer,
    transform_earnings
};
