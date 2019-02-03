*! rscript 1.0 3feb2019 by David Molitor and Julian Reif

* TO DO: establish default for rpath() option
* TO DO: implement a better error-catching mechanism for the R output

program define rscript, nclass

	version 13.0

	tempfile shell out err
	tempname shellfile errfile

	syntax using/, [rpath(string) args(string) force]
	
	****************
	* Error checking
	****************	
	confirm file "`using'"
	
	* If user does not specify the R executable, set the default to "rscript.exe"
	if !mi("`rpath'") confirm file "`rpath'"
	else {
		local rpath "rscript"
	}
	
	****************
	* Run the script. Redirect stdout to `out' and stderr to `err'
	****************

	di as result `"Running R script: `using'"'
	if !mi(`"`args'"') di as result `"Args: `args'"'	
	
	di ""
	di as result "Begin R output:"
	di as result "`="_"*80'"
	
	* Syntax for the -shell- call depends on which version of the shell is running:
	*	Unix csh:  /bin/csh
	*	Unix tcsh: /usr/local/bin/tcsh (default on NBER server)
	*	Unix bash: /bin/bash
	*	Windows
	shell echo "$0" > `shell'
	file open `shellfile' using `"`shell'"', read
	file read `shellfile' shellline
	file close `shellfile'	
	
	* Unix: tcsh or csh shell
	if strpos("`shellline'", "csh") {	
		shell ("`rpath'" "`using'" `args' > `out') >& `err'
	}
	
	* Unix: bash shell
	else if strpos("`shellline'", "bash") {
		shell "`rpath'" "`using'" `args' > `out' 2>`err'
	}
	
	* Other (including Windows)
	else {
		shell "`rpath'" "`using'" `args' > `out' 2>`err'
	}

	****************
	* Display output and errors
	****************
	type `"`out'"'  
	type `"`err'"'
	
	****************
	* If there was an error in the execution of the R script, generate an error in Stata
	****************
	* Note: both warnings and errors get sent to the err file, so exit if the word "error" is sent to stderr.
	file open `errfile' using `"`err'"', read
	file read `errfile' errline
	while r(eof)==0 {
		cap assert strpos(lower(`"`errline'"'), "error")==0
		if _rc {
			display as error "`using' ended with an error"
			if "`force'"=="" error 1
		}
		file read `errfile' errline
	}
	file close `errfile'

	di as result "`="_"*80'"
	di as result "...end R output"	
end

** EOF
