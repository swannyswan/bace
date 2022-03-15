const characteristics_per_scenario = 2; // 2 characteristics (X: tree size, Y: grass presence)
const example_base_earnings = 100; // Example base_earnings used for returning test output
const treated_survey_value = 1; // Recode value in Qualtrics

// Image urls from Qualtrics
// const baseline = "https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_3BExhm4UusJYfga";
// const small_trees = "https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_3BExhm4UusJYfga";
// const small_trees_grass = "https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_eCAXoH8FEEgqMjc";
// const large_trees = "https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_6x1QMgV79lnzrWC";
// const large_trees_grass = "https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_eu3gFaniycmoKUK";

// const baseline = 0;
// const small_trees = 1;
// const small_trees_grass = 1.5;
// const large_trees = 2;
// const large_trees_grass = 2.5;

const characteristics = {
    characteristic_x: {
        label: 'Characteristic X - Tree Size',
        values: [
            0, // no trees
            1, // small trees
            2 // large trees
        ]
    },
    characteristic_y: {
        label: 'Characteristic Y - Grass Present',
        values: [
            0, // no grass
            1 // grass
        ]
    }
};

// Takes in design input. Returns Base and Treated Values
const convert_design = function(data, characteristics, qnumber, base_earnings, characteristic_a, characteristic_b){

    // Store earnings difference
    const diff_earnings = parseFloat(data.design[0]);

    const baseline = "\"https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_3BExhm4UusJYfga\"";
    const small_trees = "\"https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_bpbbTyvDu0bNWFo\"";
    const small_trees_grass = "\"https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_eCAXoH8FEEgqMjc\"";
    const large_trees = "\"https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_6x1QMgV79lnzrWC\"";
    // const large_trees_grass = "\"https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_eu3gFaniycmoKUK\"";
    const large_trees_grass = "\"https://brown.co1.qualtrics.com/ControlPanel/Graphic.php?IM=IM_8qqRVOS6rtEqN2m\"";
    const grass = "\"https://brown.co1.qualtrics.com/CP/Graphic.php?IM=IM_5ps4NErUcNoGTd4\"";

    // const baseline = 0;
    // const small_trees = 1;
    // const small_trees_grass = 1.5;
    // const large_trees = 2;
    // const large_trees_grass = 2.5;

    var base_a, base_b, treat_a, treat_b;
    var base_img;
    var treat_img;

    // Set base_earn and treat_earn from base_earning and treat_earnings.
    const [base_e, treat_e] = transform_earnings(base_earnings, diff_earnings)

    // Set base and treat values based on question designs.
    if (data.design[1] === 2 && data.design[2] === 1 & data.design[3] === 1) {

        base_a = 0;
        base_b = 0;
        treat_a = 2;
        treat_b = 1;

        base_img = baseline;
        treat_img = large_trees_grass;

    } else if (data.design[1] === 2 && data.design[2] === -1 & data.design[3] === 0) {

        base_a = 0;
        base_b = 1;
        treat_a = 2;
        treat_b = 0;

        base_img = grass;
        treat_img = large_trees;

    } else if (data.design[1] === 2 && data.design[2] === 0 & data.design[3] === 0) {

        base_a = 0;
        base_b = 0;
        treat_a = 2;
        treat_b = 0;

        base_img = baseline;
        treat_img = large_trees;

    } else if (data.design[1] === 2 && data.design[2] === 0 & data.design[3] === 1) {

        base_a = 0;
        base_b = 1;
        treat_a = 2;
        treat_b = 1;

        base_img = grass;
        treat_img = large_trees_grass;

    } else if (data.design[1] === 1 && data.design[2] === 1 & data.design[3] === 1) {
        
        base_a = 0;
        base_b = 0;
        treat_a = 1;
        treat_b = 1;

        base_img = baseline;
        treat_img = small_trees_grass;

    } else if (data.design[1] === 1 && data.design[2] === -1 & data.design[3] === 0) {

        base_a = 0;
        base_b = 1;
        treat_a = 1;
        treat_b = 0;

        base_img = grass;
        treat_img = small_trees;

    } else if (data.design[1] === 1 && data.design[2] === 0 & data.design[3] === 0) {

        base_a = 0;
        base_b = 0;
        treat_a = 1;
        treat_b = 0;

        base_img = baseline;
        treat_img = small_trees;

    } else if (data.design[1] === 1 && data.design[2] === 0 & data.design[3] === 1) {

        base_a = 0;
        base_b = 1;
        treat_a = 1;
        treat_b = 1;

        base_img = grass;
        treat_img = small_trees_grass;

    } else if (data.design[1] === 0 && data.design[2] === 1 & data.design[3] === 0) {

        base_a = 0;
        base_b = 0;
        treat_a = 0;
        treat_b = 1;

        base_img = baseline;
        treat_img = grass;

    } else if (data.design[1] === 0 && data.design[2] === 1 & data.design[3] === 1) {

        base_a = 1;
        base_b = 0;
        treat_a = 1;
        treat_b = 1;

        base_img = small_trees;
        treat_img = small_trees_grass;

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

    // new
    output['base_img_' + qnumber] = base_img;
    output['treat_img_' + qnumber] = treat_img;

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
