/******************************************************************************
 * Program:      GIT_RECOVERY.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Synchronization and Environment Recovery
 * Author:       Clinical Programming Lead
 * Date:         2026-02-07
 * SAS Version:  9.4+
 *
 * Description:  This utility performs a full environment recovery by:
 *               1. Removing existing local repository contents.
 *               2. Re-cloning the repository from the source.
 ******************************************************************************/

OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

/*=============================================================================
  USER CONFIGURATION
=============================================================================*/
%let repo_url   = https://github.com/antonybevan/safety_oncology.git;
%let home_dir   = /home/u63849890;
%let target_dir = &home_dir/clinical_safety;

/*=============================================================================
  MACRO: DELETE_FILE
  Deletes a single file using SAS I/O functions
=============================================================================*/
%macro delete_file(filepath);
    data _null_;
        length fref $8;
        rc = filename(fref, "&filepath");
        if rc = 0 then do;
            rc = fdelete(fref);
            rc = filename(fref);
        end;
    run;
%mend;

/*=============================================================================
  MACRO: DELETE_EMPTY_FOLDER
  Deletes an empty folder
=============================================================================*/
%macro delete_empty_folder(folderpath);
    data _null_;
        length fref $8;
        rc = filename(fref, "&folderpath");
        if rc = 0 then do;
            rc = fdelete(fref);
            rc = filename(fref);
        end;
    run;
%mend;

/*=============================================================================
  MACRO: TRAVERSAL
  Recursive depth-first traversal to delete directory tree
=============================================================================*/
%macro traversal(dir);
    data _null_;
        length name $256 path $1024;
        rc = filename("d", "&dir");
        did = dopen("d");
        
        if did > 0 then do;
            num = dnum(did);
            do i = 1 to num;
                name = dread(did, i);
                path = catx("/", "&dir", name);
                
                /* Check if directory */
                rc2 = filename("t", path);
                did2 = dopen("t");
                
                if did2 > 0 then do;
                    /* It is a directory: Close it, Recurse into it */
                    rc3 = dclose(did2);
                    call execute('%traversal(' || strip(path) || ')'); 
                end;
                else do;
                     /* It is a file: Delete it */
                     call execute('%delete_file(' || strip(path) || ')');
                end;
                rc2 = filename("t");
            end;
            rc = dclose(did);
        end;
        rc = filename("d");
        
        /* Delete the directory itself */
        call execute('%delete_empty_folder(' || strip("&dir") || ')');
    run;
%mend;

/*=============================================================================
  MACRO: DO_CLONE
  Re-clone the repository
=============================================================================*/
%macro do_clone;
    data _null_;
        put "NOTE: Attempting fresh CLONE...";
    run;
    
    proc git;
        clone url="&repo_url" out="&target_dir";
    run; 
    quit; /* Explicit QUIT to prevent active procedure block issues */
%mend;

/*=============================================================================
  MAIN EXECUTION
=============================================================================*/
%macro main;
    /* Step 1: Check inputs */
    %if %length(&target_dir) = 0 %then %return;

    /* Step 2: Clean existing directory if it exists */
    %if %sysfunc(fileexist(&target_dir)) %then %do;
        %traversal(&target_dir);
    %end;

    /* Step 3: Clone fresh */
    %do_clone;
    
    /* Step 4: Verify */
    data _null_;
        if fileexist("&target_dir/.git") then 
            put "NOTE: RECOVERY COMPLETE.";
        else 
            put "ERROR: Recovery failed.";
    run;
%mend;

%main;

OPTIONS NOTES STIMER SOURCE SYNTAXCHECK;
