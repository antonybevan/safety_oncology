/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Protocol:     BV-CAR20-P1
 * Purpose:      Force-sync SAS OnDemand repository (Nuclear Reset)
 * Author:       Clinical Programming Lead
 * Date:         2026-02-05
 * SAS Version:  9.4+ / SAS OnDemand compatible
 *
 * Description:  When Git conflicts arise that cannot be resolved normally,
 *               this program performs a "nuclear" reset:
 *               1. Deletes ALL local files recursively (Pure SAS - no shell)
 *               2. Re-clones the repository from GitHub
 *
 * WARNING:      This will DESTROY all local uncommitted changes!
 *               Use GIT_PUSH.sas first if you have work to save.
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
        rc = filename("del", "&filepath");
        rc = fdelete("del");
        if rc ne 0 then put "NOTE: (Delete File) Failed for &filepath";
        rc = filename("del");
    run;
%mend;

/*=============================================================================
  MACRO: DELETE_EMPTY_FOLDER
  Deletes an empty folder (must be called after contents are removed)
=============================================================================*/
%macro delete_empty_folder(folderpath);
    data _null_;
        rc = filename("rdir", "&folderpath");
        rc = fdelete("rdir");
        if rc ne 0 then put "NOTE: (Delete Folder) Waiting for contents: &folderpath";
        rc = filename("rdir");
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
                
                /* Check if directory by trying to open it */
                rc2 = filename("t", path);
                did2 = dopen("t");
                
                if did2 > 0 then do;
                    /* It is a directory: Close it, Recurse into it */
                    rc3 = dclose(did2);
                    call execute('%traversal(' || strip(path) || ')'); 
                end;
                else do;
                     /* It is a file: Delete it immediately */
                     call execute('%delete_file(' || strip(path) || ')');
                end;
                rc2 = filename("t");
            end;
            rc = dclose(did);
        end;
        rc = filename("d");
        
        /* Queue the deletion of the directory itself (runs after contents) */
        call execute('%delete_empty_folder(' || strip("&dir") || ')');
    run;
%mend;

/*=============================================================================
  MACRO: DO_CLONE
  Re-clone the repository after cleanup
=============================================================================*/
%macro do_clone;
    data _null_;
        put "NOTE: ==================================================";
        put "NOTE: Cleanup complete. Attempting fresh CLONE...";
        put "NOTE: ==================================================";
    run;
    
    proc git;
        clone url="&repo_url" out="&target_dir";
    run;
    
    data _null_;
        rc = filename("chk", "&target_dir/.git");
        exists = fileexist("&target_dir/.git");
        
        if exists then do;
            put "NOTE: ==================================================";
            put "NOTE: ✅ SUCCESS! Repository reset in-place.";
            put "NOTE: You can continue working in: &target_dir";
            put "NOTE: ==================================================";
        end;
        else do;
            put "ERR" "OR: Clone failed. Check network/permissions.";
        end;
    run;
%mend;

/*=============================================================================
  MAIN EXECUTION
=============================================================================*/
data _null_;
    put "NOTE: ==================================================";
    put "NOTE: ⚠️  GIT RESCUE - NUCLEAR RESET";
    put "NOTE: Target: &target_dir";
    put "NOTE: ==================================================";
    put "NOTE: ";
    put "NOTE: WARNING: All local changes will be DESTROYED!";
    put "NOTE: ";
run;

/* Step 1: Attempt a simple pull first */
data _null_;
    rc = gitfn_pull("&target_dir");
    
    if rc = 0 then do;
        put "NOTE: ✅ Pull successful - no rescue needed!";
        call symputx('NEED_RESCUE', '0');
    end;
    else if rc = 1 then do;
        put "NOTE: ✓ Already up to date.";
        call symputx('NEED_RESCUE', '0');
    end;
    else do;
        put "NOTE: ⚠️ Conflict Detected (RC=" rc ").";
        put "NOTE: Initiating NUCLEAR CLEANUP...";
        call symputx('NEED_RESCUE', '1');
    end;
run;

/* Step 2: If rescue needed, execute recursive delete and re-clone */
%macro execute_rescue;
    %if &NEED_RESCUE = 1 %then %do;
        %traversal(&target_dir);
        %do_clone;
    %end;
%mend;
%execute_rescue;

OPTIONS NOTES STIMER SOURCE SYNTAXCHECK;

%put NOTE: ==================================================;
%put NOTE: GIT RESCUE SCRIPT COMPLETE;
%put NOTE: ==================================================;
