OPTIONS NONOTES NOSTIMER NOSOURCE NOSYNTAXCHECK;

/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Purpose:      Force-sync SAS OnDemand (In-Place Fix)
 * Description:  Recursively clears the original folder using Pure SAS logic
 *               (bypassing shell restrictions) to allow a clean Git Clone.
 ******************************************************************************/

%let repo_url = https://github.com/antonybevan/safety_oncology.git;
%let home_dir = /home/u63849890;
%let target_dir = &home_dir/clinical_safety;

/* -------------------------------------------------------------------------
   MACRO: DELETE_DIR_TREE
   Recursively deletes all files and subdirectories in a target path.
   Uses 'CALL EXECUTE' to traverse the tree structure.
   ------------------------------------------------------------------------- */
%macro delete_file(filepath);
    data _null_;
        rc = filename("del", "&filepath");
        rc = fdelete("del");
        /* verify deletion? */
        if rc ne 0 then put "NOTE: (Delete File) Failed for &filepath";
    run;
%mend;

%macro delete_empty_folder(folderpath);
    data _null_;
        rc = filename("rdir", "&folderpath");
        rc = fdelete("rdir");
        if rc ne 0 then put "NOTE: (Delete Folder) Failed or not empty: &folderpath";
    run;
%mend;

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
                
                /* Heuristic: Check if directory by trying to open it */
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
            end;
            rc = dclose(did);
        end;
        
        /* Queue the deletion of the directory itself (will run after contents) */
        call execute('%delete_empty_folder(' || strip("&dir") || ')');
    run;
%mend;


data _null_;
   put "NOTE: --------------------------------------------------";
   put "NOTE: Starting In-Place GIT RESCUE...";
   put "NOTE: Target: &target_dir";
   
   /* 1. Attempt PULL first just in case */
   rc = gitfn_pull("&target_dir");
   
   if rc = 0 then put "NOTE: ✅ SUCCESS! Project updated.";
   else if rc = 1 then put "NOTE: Already up to date.";
   
   else do;
       put "NOTE: ⚠️ Conflict Detected (RC=" rc ").";
       put "NOTE: Initiating IN-PLACE CLEANUP (Deleting local files)...";
       
       /* 2. Execute Recursive Delete */
       call execute('%traversal(&target_dir)');
       
       /* 3. Helper to Re-Clone (Queued to run AFTER deletion) */
       /* We wrap this in a macro so it enters the queue at the end */
       call execute('%do_clone');
   end;
run;

%macro do_clone;
   data _null_;
       put "NOTE: Cleanup commands issued. Attempting CLONE...";
       rc_clone = gitfn_clone("&repo_url", "&target_dir");
       
       if rc_clone = 0 then do;
            put "NOTE: ========================================";
            put "NOTE: ✅ SUCCESS! Repository reset in-place.";
            put "NOTE: You can continue working in: &target_dir";
            put "NOTE: ========================================";
       end;
       else put "ERR" "OR: Clone failed. RC=" rc_clone " (Folder might not be empty yet?)";
   run;
%mend;
