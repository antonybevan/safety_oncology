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
   length USUBJID $20 ARM $40 SEX $1 RACE $40 DISEASE $5 RFSTDTC TRTSDT LDSTDT $10;
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
         
         /* Anchor dates - Force ISO 8601 for CSV compatibility */
         dt = '15JAN2023'd + (dose_level-1)*30 + i*5;
         RFSTDTC = put(dt, yymmdd10.);
         TRTSDT  = put(dt + 7, yymmdd10.);
         LDSTDT  = put(dt + 30, yymmdd10.);
         
         output;
      end;
   end;
run;

/* 2. Generate Adverse Events (AE) and SUPPAE */
data raw_ae(drop=dt) raw_suppae(keep=USUBJID IDVAR IDVARVAL QNAM QLABEL QVAL);
   set raw_dm;
   length AETERM AEDECOD $100 AESTDTC AEENDTC $10 QNAM $8 QLABEL $40 QVAL $20 IDVAR $8;
   day0 = input(TRTSDT, yymmdd10.);
   
   /* CRS simulation */
   if (dose_level=1 and ranuni(0)<0.50) or (dose_level=2 and ranuni(0)<0.7) or (dose_level=3 and ranuni(0)<1.0) then do;
      AETERM = "Cytokine Release Syndrome";
      AEDECOD = "Cytokine release syndrome";
      AETOXGR_NUM = round(1 + 2*ranuni(0));
      AETOXGR = put(AETOXGR_NUM, 1.);
      AESTDTC = put(day0 + 3, yymmdd10.);
      AEENDTC = put(day0 + 10, yymmdd10.);
      AESER = 'N'; if AETOXGR_NUM >= 3 then AESER = 'Y';
      AESEQ = 1;
      output raw_ae;
      
      /* Add Toxicity Grade to SUPPAE */
      IDVAR = "AESEQ";
      IDVARVAL = "1";
      QNAM = "AETOXGR";
      QLABEL = "Analysis Toxicity Grade";
      QVAL = AETOXGR;
      output raw_suppae;
   end;
run;

/* 3. Generate Lab Data (LB) */
data raw_lb;
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

/* 4. Export to CSV */
%macro export_raw(ds);
   proc export data=&ds 
      outfile="&LEGACY_PATH/raw_&ds..csv" 
      dbms=csv replace;
   run;
%mend;

%export_raw(dm);
%export_raw(ae);
%export_raw(lb);
%export_raw(suppae);

/* Manual SDTM creation to bypass PROC IMPORT guessing if needed */
data sdtm.dm; set raw_dm; run;
data sdtm.ae; set raw_ae; run;
data sdtm.lb; set raw_lb; run;
data sdtm.suppae; set raw_suppae; run;

%put NOTE: ✅ Synthetic data (including SUPPAE) generated and saved to &LEGACY_PATH;

%put NOTE: ✅ Synthetic data generated and saved to &LEGACY_PATH;
