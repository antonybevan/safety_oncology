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

/* Define Study Metadata */
%let target_study = BV-CAR20-P1;

/* 1. Generate Demographics (DM) and Population Flags */
   retain STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL dose_level i subid AGE dt;
   length STUDYID $20 USUBJID $20 ARM $40 SEX $1 RACE $40 DISEASE $5 RFSTDTC TRTSDT LDSTDT $10;
   length SAFFL ITTFL EFFFL $1;
   STUDYID = "&target_study";
   do dose_level = 1 to 3;
      do i = 1 to 6;
         subid = 100 + dose_level*100 + i;
         USUBJID = catx('-', '101', subid);
         
         /* Protocol Defined Doses */
         if dose_level = 1 then ARM = "1x10^6 cells/kg";
         else if dose_level = 2 then ARM = "3x10^6 cells/kg";
         else ARM = "480x10^6 cells";
         
         AGE = round(45 + (78-45)*ranuni(123));
         SEX = scan("M,F", mod(i,2)+1, ',');
         RACE = "WHITE";
         /* Target Populations */
         DISEASE = scan("NHL,CLL,SLL", mod(i,3)+1, ',');
         
         /* Population Flags (All treated in this sim) */
         SAFFL = 'Y';
         ITTFL = 'Y';
         EFFFL = 'Y';
         
         /* Anchor dates - CAR-T Infusion is Day 0 */
         dt = '15JAN2023'd + (dose_level-1)*30 + i*5;
         RFSTDTC = put(dt, yymmdd10.);
         TRTSDT  = put(dt + 7, yymmdd10.);
         LDSTDT  = put(dt + 30, yymmdd10.);
         
         output;
      end;
   end;
run;

/* 2. Generate Exposure (EX) - Lymphodepletion and CAR-T */
data raw_ex;
   retain STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL dose_level i subid AGE dt EXTRT EXDOSE EXDOSU EXSTDTC EXENDTC day0 d;
   set raw_dm;
   length EXTRT $100 EXDOSE 8 EXDOSU $20 EXSTDTC EXENDTC $10;
   day0 = input(TRTSDT, yymmdd10.);
   
   /* Fludarabine Days -5 to -3 */
   EXTRT = "FLUDARABINE";
   EXDOSE = 30; EXDOSU = "mg/m^2";
   do d = -5 to -3;
      EXSTDTC = put(day0 + d, yymmdd10.);
      EXENDTC = EXSTDTC;
      output;
   end;
   
   /* Cyclophosphamide Days -5 to -3 */
   EXTRT = "CYCLOPHOSPHAMIDE";
   EXDOSE = 500; EXDOSU = "mg/m^2";
   do d = -5 to -3;
      EXSTDTC = put(day0 + d, yymmdd10.);
      EXENDTC = EXSTDTC;
      output;
   end;
   
   /* Study Drug Day 0 */
   EXTRT = "BV-CAR20";
   EXDOSU = "10^6 cells";
   if dose_level = 1 then EXDOSE = 1; /* Simplification: assuming avg weight/dose */
   else if dose_level = 2 then EXDOSE = 3;
   else EXDOSE = 480;
   EXSTDTC = put(day0, yymmdd10.);
   EXENDTC = EXSTDTC;
   output;
run;

/* 3. Generate Adverse Events (AE) */
data raw_ae(drop=dt);
   retain STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL dose_level i subid AGE AETERM AEDECOD AESTDTC AEENDTC day0 AETOXGR_NUM AETOXGR AESER;
   set raw_dm;
   length AETERM AEDECOD $100 AESTDTC AEENDTC $10;
   day0 = input(TRTSDT, yymmdd10.);
   
   /* CRS simulation (Primary safety endpoint) */
   if (dose_level=1 and ranuni(0)<0.50) or (dose_level=2 and ranuni(0)<0.7) or (dose_level=3 and ranuni(0)<1.0) then do;
      AETERM = "Cytokine Release Syndrome";
      AEDECOD = "Cytokine release syndrome";
      AETOXGR_NUM = round(1 + 2*ranuni(0));
      AETOXGR = put(AETOXGR_NUM, 1.);
      AESTDTC = put(day0 + 3, yymmdd10.);
      AEENDTC = put(day0 + 10, yymmdd10.);
      AESER = 'N'; if AETOXGR_NUM >= 3 then AESER = 'Y';
      output;
   end;
run;

/* 4. Generate Lab Data (LB) */
data raw_lb;
   retain STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL dose_level i subid AGE dt LBTESTCD LBTEST LBORRES LBORRESU LBDTC VISIT day0 visit_idx LBORNRLO LBORNRHI;
   set raw_dm;
   length LBTESTCD $8 LBTEST $40 LBORRES $20 LBORRESU $20 LBDTC $10 VISIT $20;
   day0 = input(TRTSDT, yymmdd10.);
   do visit_idx = 0, 7, 14, 28;
      if visit_idx = 0 then VISIT = "Baseline";
      else VISIT = catx(' ', "Day", visit_idx);
      
      LBDTC = put(day0 + visit_idx, yymmdd10.);
      
      /* Neutrophils */
      LBTESTCD = "NEUT"; LBTEST = "Neutrophils"; LBORRESU = "10^9/L";
      LBORNRLO = 1.8; LBORNRHI = 7.5;
      LBORRES = put(LBORNRLO + ranuni(0)*(LBORNRHI-LBORNRLO), 8.2);
      output;
      
      /* Platelets */
      LBTESTCD = "PLAT"; LBTEST = "Platelets"; LBORRESU = "10^9/L";
      LBORNRLO = 150; LBORNRHI = 400;
      LBORRES = put(LBORNRLO + ranuni(0)*(LBORNRHI-LBORNRLO), 8.2);
      output;
   end;
run;

/* 5. Generate Response Data (RS) */
data raw_rs;
   retain STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL dose_level i subid AGE dt RSTESTCD RSTEST RSORRES RSDTC VISIT day0 p;
   set raw_dm;
   length RSTESTCD $8 RSTEST $40 RSORRES $20 RSDTC $10 VISIT $20;
   day0 = input(TRTSDT, yymmdd10.);
   
   VISIT = "Cycle 3 Day 1";
   RSDTC = put(day0 + 84, yymmdd10.); /* Approx 3 months */
   RSTESTCD = "OVRLRESP"; RSTEST = "Overall Response";
   
   /* Progression probabilities increase with dose (just for sim) */
   p = ranuni(0);
   if p < 0.4 then RSORRES = "CR";
   else if p < 0.7 then RSORRES = "PR";
   else if p < 0.9 then RSORRES = "SD";
   else RSORRES = "PD";
   
   output;
run;

/* 6. Export to CSV */
%macro export_raw(ds);
   proc export data=&ds 
      outfile="&LEGACY_PATH/&ds..csv"
      dbms=csv replace;
   run;
%mend;

%export_raw(raw_dm);
%export_raw(raw_ex);
%export_raw(raw_ae);
%export_raw(raw_lb);
%export_raw(raw_rs);

%put NOTE: ✅ Synthetic raw data generated and saved to &LEGACY_PATH;
