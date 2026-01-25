/******************************************************************************
 * Program:      deep_file_audit.sas
 * Purpose:      List all files in the project folder with exact case and size
 ******************************************************************************/

%macro load_config;
   %if %symexist(_SASPROGRAMFILE) %then %do;
      %let path = %sysfunc(prxchange(s/(.*)[\/\\].*$/$1/, 1, &_SASPROGRAMFILE));
      %if %sysfunc(fileexist(&path/00_config.sas)) %then %include "&path/00_config.sas";
      %else %if %sysfunc(fileexist(&path/../00_config.sas)) %then %include "../00_config.sas";
   %end;
   %else %include "00_config.sas";
%mend;
%load_config;

/* 1. Deep directory search using SAS functions (Case Sensitive) */
data file_list;
   length folder fid $200 filename $100;
   folder = "&LEGACY_PATH";
   rc = filename('dirid', folder);
   fid = dopen('dirid');
   if fid > 0 then do;
      do i = 1 to dnum(fid);
         filename = dread(fid, i);
         /* Get file size */
         fid2 = mopen(fid, filename);
         if fid2 > 0 then size = finfo(fid2, 'File Size (bytes)');
         output;
      end;
      rc = dclose(fid);
   end;
   keep filename size;
run;

proc print data=file_list;
   title "Exact Files found in &LEGACY_PATH";
run;

/* 2. Test reading any file found (First 3 lines) */
data _null_;
   set file_list(obs=3);
   if index(upcase(filename), '.CSV') > 0 then do;
      file_path = catx('/', "&LEGACY_PATH", filename);
      put "--- PEEKING INTO " filename " ---";
      infile dummy filevar=file_path obs=3;
      input;
      put _infile_;
   end;
run;
