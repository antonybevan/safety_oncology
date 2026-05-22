/******************************************************************************
 * Macro:        calc_astct
 * Purpose:      Centralize ASTCT 2019 Grading logic for CAR-T toxicity
 * Parameters:   source_grade - Raw categorical grade (Grade 1-4)
 *               out_grade - Resultant numeric analysis grade
 ******************************************************************************/

%macro calc_astct(source_grade=, out_grade=);
    /* Standard map: preserve numeric portion of "GRADE X", handle case-insensitivity without leaking temporary variables */
    if index(upcase(strip(&source_grade)), 'GRADE 5') or strip(&source_grade) = '5' then &out_grade = 5;
    else if index(upcase(strip(&source_grade)), 'GRADE 4') or strip(&source_grade) = '4' then &out_grade = 4;
    else if index(upcase(strip(&source_grade)), 'GRADE 3') or strip(&source_grade) = '3' then &out_grade = 3;
    else if index(upcase(strip(&source_grade)), 'GRADE 2') or strip(&source_grade) = '2' then &out_grade = 2;
    else if index(upcase(strip(&source_grade)), 'GRADE 1') or strip(&source_grade) = '1' then &out_grade = 1;
    else &out_grade = .;
%mend calc_astct;
