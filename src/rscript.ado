*! rscript 1.0 8jul2019 by David Molitor and Julian Reif

program define rscript, nclass

	version 13.0

	tempfile shell out err
	tempname shellfile errfile

	syntax using/, [rpath(string) args(string asis) force]
	
	****************
	* Error checking
	****************	
	confirm file "`using'"
	
	* If user does not specify the location of the R executable, set the default to what is stored in RSCRIPT_PATH
	if mi(`"`rpath'"') local rpath "$RSCRIPT_PATH"
	
	if mi(`"`rpath'"') {
		di as error "Location of R executable must be specified using option rpath() or using the global RSCRIPT_PATH"
		exit 198
	}
	
	confirm file "`rpath'"
	
	****************
	* Run the script. Redirect stdout to `out' and stderr to `err'
	****************

	di as result `"Running R script: `using'"'
	if !mi(`"`args'"') di as result `"Args: `args'"'	
	di as result _n
		
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
	* Display stdout and stderr output
	****************
	di as result "Begin R output:"
	di as result "`="_"*80'"
	
	di as result "{ul:stdout}:"
	type `"`out'"'
	di as result _n
	di as result "{ul:stderr}:"
	type `"`err'"'
	
	di as result "`="_"*80'"
	di as result "...end R output"
	
	****************
	* If there was an error in the execution of the R script, notify the user (and break, unless -force- option is specified)
	****************
	* Note: both warnings and errors get sent to stderr, so exit only if the word "error" is sent to stderr. (This could be made more specific.)
	file open `errfile' using `"`err'"', read
	file read `errfile' errline
	while r(eof)==0 {
		cap assert strpos(lower(`"`macval(errline)'"'), "error")==0
		if _rc==9 {
			display as error "`using' ended with an error"
			if "`force'"=="" error 198
		}
		else if _rc {
			display as error "Encountered a problem while parsing the error output file"
			display as error "Error code: " _rc
		}
		file read `errfile' errline
	}
	file close `errfile'

end

** EOF
