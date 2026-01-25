/******************************************************************************
 * Program:      GIT_RESCUE.sas
 * Purpose:      Force-sync SAS OnDemand with GitHub (Public Repo)
 ******************************************************************************/

%let repo_url = https://github.com/antonybevan/safety_oncology.git;
%let home_dir = /home/u63849890;

data _null_;
    /* Generate a folder name with NO COLONS (e.g., safety_oncology_26JAN26_0018) */
    unique_name = catx('_', "safety_oncology", put(date(), date9.), compress(put(time(), time5.), ':'));
    unique_path = catx('/', "&home_dir", unique_name);
    
    put "NOTE: Attempting clean clone into: " unique_path;
    
    rc = gitfn_clone("&repo_url", unique_path);
    
    if rc = 0 then do;
        put "NOTE: ========================================";
        put "NOTE: ✅ SUCCESS! Project cloned to: " unique_path;
        put "NOTE: ========================================";
    end;
    else put "ERR" "OR: Clone failed. RC=" rc;
run;
