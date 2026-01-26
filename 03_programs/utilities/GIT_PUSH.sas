/******************************************************************************
 * Program:      GIT_PUSH.sas
/* 1. ENTER YOUR GITHUB PAT HERE (Required for Push) */
/* NOTE: Even for Public repos, you need a Token to PUSH (Write) changes. */
/* PULLing (Read) is free, but PUSHing needs auth. */
%let my_pat = ; 

/* 2. REPO DETAILS */
%let github_user = antonybevan;
%let repo_name   = safety_oncology;
%let local_path  = /home/u63849890/clinical_safety; 

/* Construct Secure URL with Token */
/* "oauth2" is the username when using a Token */
%let repo_url = https://oauth2:&my_pat@github.com/&github_user/&repo_name..git;

/* 3. EXECUTE PUSH SEQUENCE */
proc git;
    /* Stage all changes */
    add 
        repo="&local_path"
        path="*"
    ;
    
    /* Commit changes */
    commit 
        repo="&local_path"
        message="Update analysis programs and datasets from SAS OnDemand"
        author_name="&github_user"
        author_email="user@example.com"
    ;
    
    /* Push to remote */
    push 
        repo="&local_path"
        url="&repo_url"
    ;
run;

%put NOTE: Push sequence complete. Check your GitHub repo for updates!;
