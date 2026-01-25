/******************************************************************************
 * Program:      generate_data.sas
 * Purpose:      SAS-Native Synthetic Data Generator for BV-CAR20-P1
 ******************************************************************************/

%macro load_config;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
   %else %if %symexist(_SASPROGRAMFILE) %then %do;
      %let path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
      %if %sysfunc(fileexist(&path/00_config.sas)) %then %include "&path/00_config.sas";
      %else %if %sysfunc(fileexist(&path/../00_config.sas)) %then %include "&path/../00_config.sas";
   %end;
%mend;
%load_config;

/* 1. Generate Demographics (DM) */
data raw_dm;
   length USUBJID $10 ARM $40 SEX $1 RACE $40 DISEASE $5 RFSTDTC TRTSDT LDSTDT $10;
   do dose_level = 1 to 3;
      do i = 1 to 6;
         subid = 100 + dose_level*100 + i;
         USUBJID = catx('-', '101', subid);
         
         if dose_level = 1 then ARM = "1x10^6 cells/kg";
         else if dose_level = 2 then ARM = "3x10^6 cells/kg";
         else ARM = "480x10^6 cells";
         
         AGE = round(45 + (78-45)*ranuni(123));
         SEX = scan("M,F", mod(i,2)+1, ',');
         RACE = "WHITE";
         DISEASE = scan("NHL,CLL,SLL", mod(i,3)+1, ',');
         
         /* Anchor dates */
         dt = '15JAN2023'd + (dose_level-1)*30 + i*5;
         RFSTDTC = put(dt, yymmdd10.);
         LDSTDT  = put(dt + 2, yymmdd10.);
         TRTSDT  = put(dt + 7, yymmdd10.);
         
         output;
      end;
   end;
run;

/* 2. Generate Adverse Events (AE) with CAR-T Toxicology */
data raw_ae;
   set raw_dm;
   length AETERM AEDECOD $100 AESTDTC AEENDTC $10;
   day0 = input(TRTSDT, yymmdd10.);
   
   /* CRS simulation */
   if (dose_level=1 and ranuni(0)<0.33) or (dose_level=2 and ranuni(0)<0.5) or (dose_level=3 and ranuni(0)<0.7) then do;
      AETERM = "Cytokine Release Syndrome";
      AEDECOD = "Cytokine release syndrome";
      AETOXGR = round(1 + 2*ranuni(0));
      AESTDTC = put(day0 + 3, yymmdd10.);
      AEENDTC = put(day0 + 10, yymmdd10.);
      AESER = 'N'; if AETOXGR >= 3 then AESER = 'Y';
      output;
   end;
   
   /* ICANS simulation */
   if ranuni(0) < 0.25 then do;
      AETERM = "ICANS";
      AEDECOD = "Immune effector cell-associated neurotoxicity syndrome";
      AETOXGR = round(1 + ranuni(0));
      AESTDTC = put(day0 + 7, yymmdd10.);
      AEENDTC = put(day0 + 14, yymmdd10.);
      AESER = 'N';
      output;
   end;
   
   keep USUBJID AETERM AEDECOD AETOXGR AESTDTC AEENDTC AESER;
run;

/* 3. Export to CSV for Pipeline training */
%macro export_raw(ds);
   proc export data=&ds 
      outfile="&LEGACY_PATH/&ds..csv" 
      dbms=csv replace;
   run;
%mend;

%export_raw(raw_dm);
%export_raw(raw_ae);

/* Also fill the SDTM library directly to save time */
data sdtm.dm; set raw_dm; run;
data sdtm.ae; set raw_ae; run;

%put NOTE: ✅ Synthetic data generated and saved to &LEGACY_PATH;
