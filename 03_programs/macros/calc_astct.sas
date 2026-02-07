/******************************************************************************
 * Macro:        calc_astct
 * Purpose:      Centralize ASTCT 2019 Grading logic for CAR-T toxicity
 * Parameters:   source_grade - Raw categorical grade (Grade 1-4)
 *               out_grade - Resultant numeric analysis grade
 ******************************************************************************/

%macro calc_astct(source_grade=, out_grade=);
    /* Standard map: preserve numeric portion of "GRADE X", handle case-insensitivity */
    length _tmp $50;
    _tmp = upcase(&source_grade);
    
    if index(_tmp, 'GRADE 4') or _tmp = '4' then &out_grade = 4;
    else if index(_tmp, 'GRADE 3') or _tmp = '3' then &out_grade = 3;
    else if index(_tmp, 'GRADE 2') or _tmp = '2' then &out_grade = 2;
    else if index(_tmp, 'GRADE 1') or _tmp = '1' then &out_grade = 1;
    else &out_grade = .;
%mend calc_astct;
