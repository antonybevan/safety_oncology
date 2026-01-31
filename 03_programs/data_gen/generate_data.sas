/******************************************************************************
 * Program:      generate_data.sas
 * Purpose:      SAS-Native Synthetic Data Generator for BV-CAR20-P1
 ******************************************************************************/

%macro load_config;
   %if %symexist(CONFIG_LOADED) %then %if &CONFIG_LOADED=1 %then %return;
   %if %sysfunc(fileexist(00_config.sas)) %then %include "00_config.sas";
   %else %if %sysfunc(fileexist(../00_config.sas)) %then %include "../00_config.sas";
%mend;
%load_config;

/* Define Study Metadata */
%let target_study = BV-CAR20-P1;

/* 1. Generate Demographics (DM) and Population Flags */
data raw_dm;
   /* Standardize column order for all child datasets */
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
   retain STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL dose_level i subid AGE dt 
          EXTRT EXDOSE EXDOSU EXSTDTC EXENDTC day0 d;
   length EXTRT $40 EXDOSU $10 EXSTDTC EXENDTC $10;
   set raw_dm;
   
   day0 = input(TRTSDT, yymmdd10.);

   /* Infusion Day 0 */
   EXTRT = "BV-CAR20";
   EXDOSE = dose_level;
   EXDOSU = "CELLS";
   EXSTDTC = TRTSDT;
   EXENDTC = TRTSDT;
   output;

   /* Lymphodepletion Days -5 to -3 */
   do d = day0 - 5 to day0 - 3;
      EXTRT = "Cyclophosphamide";
      EXDOSE = 500;
      EXDOSU = "mg/m2";
      EXSTDTC = put(d, yymmdd10.);
      EXENDTC = put(d, yymmdd10.);
      output;
      
      EXTRT = "Fludarabine";
      EXDOSE = 30;
      EXDOSU = "mg/m2";
      EXSTDTC = put(d, yymmdd10.);
      EXENDTC = put(d, yymmdd10.);
      output;
   end;
run;

/* 3. Generate Adverse Events (AE) with CRS and ICANS */
data raw_ae;
   retain STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL dose_level i subid AGE dt 
          AEDECOD AETERM AETOXGR AESTDTC AEENDTC AESER AESID day0;
   length AEDECOD AETERM AETOXGR $100 AESTDTC AEENDTC $10 AESER $1;
   set raw_dm;
   day0 = input(TRTSDT, yymmdd10.);
   
   /* Every subject gets a common AE */
   AEDECOD = "Fatigue";
   AETERM  = "Fatigue";
   AETOXGR = "GRADE 1";
   AESTDTC = put(day0 + 2, yymmdd10.);
   AEENDTC = put(day0 + 15, yymmdd10.);
   AESER   = "N";
   AESID   = 0;
   output;

   /* CRS for higher dose levels */
   if dose_level >= 2 then do;
      AEDECOD = "Cytokine release syndrome";
      AETERM  = "Cytokine release syndrome";
      AETOXGR = "GRADE 2";
      AESTDTC = put(day0 + 4, yymmdd10.);
      AEENDTC = put(day0 + 10, yymmdd10.);
      AESER   = "Y";
      AESID   = 1;
      output;
   end;

   /* ICANS for Dose level 3 */
   if dose_level = 3 then do;
      AEDECOD = "Immune effector cell-associated neurotoxicity syndrome";
      AETERM  = "ICANS";
      AETOXGR = "GRADE 3";
      AESTDTC = put(day0 + 6, yymmdd10.);
      AEENDTC = put(day0 + 14, yymmdd10.);
      AESER   = "Y";
      AESID   = 1;
      output;
   end;
run;

/* 4. Generate Lab Data (LB) */
data raw_lb;
   retain STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL dose_level i subid AGE dt 
          LBTESTCD LBTEST LBORRES LBORNRLO LBORNRHI VISIT LBDTC day0 d;
   length LBTESTCD $8 LBTEST $40 LBORRES LBORNRLO LBORNRHI $20 VISIT $20 LBDTC $10;
   set raw_dm;
   day0 = input(TRTSDT, yymmdd10.);
   
   do VISIT = 'Screening', 'Day 0', 'Day 7', 'Day 14';
      if VISIT = 'Screening' then d = day0 - 10;
      else if VISIT = 'Day 0' then d = day0;
      else if VISIT = 'Day 7' then d = day0 + 7;
      else d = day0 + 14;
      
      LBDTC = put(d, yymmdd10.);
      
      LBTESTCD = 'NEUT'; LBTEST = 'Neutrophils'; LBORRES = put(2.5 + rannor(123)*0.5, 5.1); LBORNRLO = '1.5'; LBORNRHI = '8.0'; output;
      LBTESTCD = 'PLAT'; LBTEST = 'Platelets'; LBORRES = put(220 + rannor(123)*50, 5.0);   LBORNRLO = '150'; LBORNRHI = '450'; output;
   end;
run;

/* 5. Generate Response Data (RS) */
data raw_rs;
   retain STUDYID USUBJID ARM SEX RACE DISEASE RFSTDTC TRTSDT LDSTDT SAFFL ITTFL EFFFL dose_level i subid AGE dt 
          RSTESTCD RSTEST RSORRES RSSTRESC RSDTC VISIT day0 r;
   length RSTESTCD $8 RSTEST $40 RSORRES RSSTRESC $20 RSDTC $10 VISIT $20;
   set raw_dm;
   day0 = input(TRTSDT, yymmdd10.);
   
   do VISIT = 'Day 28', 'Day 56';
      if VISIT = 'Day 28' then d_rs = day0 + 28;
      else d_rs = day0 + 56;
      
      RSDTC = put(d_rs, yymmdd10.);
      RSTESTCD = 'BOR';
      RSTEST = 'Best Overall Response';
      
      /* Simulating response: Better response for higher dose */
      r = ranuni(456);
      if dose_level = 1 then do;
         if r > 0.6 then RSORRES = 'PR'; else RSORRES = 'SD';
      end;
      else do;
         if r > 0.4 then RSORRES = 'CR'; else RSORRES = 'PR';
      end;
      
      RSSTRESC = RSORRES;
      output;
   end;
run;

/* 6. Export all to CSV in Legacy Folder */
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

%put NOTE: --------------------------------------------------;
%put NOTE: ✅ SYNTHETIC DATA GENERATION COMPLETE;
%put NOTE: --------------------------------------------------;
