*! rscript 1.0.5 4jul2021 by David Molitor and Julian Reif
* 1.0.5: added rversion() option. fixed text output when using RSCRIPT_PATH
* 1.0.4: added default pathname
* 1.0.3: added support for "~" pathnames
* 1.0.2: stderr is now parsed by Mata instead of Stata
* 1.0.1: updated error handling

program define rscript, rclass

	version 13.0

	tempfile shell out err
	tempname shellfile

	syntax [using/], [rpath(string) args(string asis) rversion(string) force]
	
	************************************************
	* Error checking
	************************************************
	* User must specify a filename, unless rversion() was specified
	if mi("`rversion'") & mi("`using'") {
		di as error "using required"
		exit 100
	}
	if !mi("`using'") confirm file "`using'"
	
	* If user does not specify the location of the R executable, set the default to what is stored in RSCRIPT_PATH
	* If both are blank, then try using an os-specific default
	if mi(`"`rpath'"') {
		local rpath `"$RSCRIPT_PATH"'
		
		if mi(`"`rpath'"') {
			
			local os = lower("`c(os)'")
			
			* Unix/mac default paths: (1) /usr/local/bin/Rscript (2) /usr/bin/Rscript
			if inlist("`os'","macosx","unix") {
				local rpath "/usr/local/bin/Rscript"
				cap confirm file "`rpath'"
				if _rc local rpath "/usr/bin/Rscript"
				cap confirm file "`rpath'"
				if _rc local rpath 
			}
			
			* Windows default path: "C:/Program Files/R/R-X.Y.Z/bin/Rscript.exe" (newest version)
			else if "`os'" == "windows" {
				local subdirs : dir "C:/Program Files/R/" dirs "R-?.?.?", respectcase
				local subdirs : list clean subdirs
				local subdirs : list sort subdirs
				local ndirs   : list sizeof subdirs
				if `ndirs' > 0 {
					local newest  : word `ndirs' of `subdirs'
					local rpath "C:/Program Files/R/`newest'/bin/Rscript.exe"
				}
			}
			
			if mi(`"`rpath'"') {
				di as error "No default R executable found. Specify R executable using option rpath() or using the global RSCRIPT_PATH"
				exit 198	
			}
			else di as result `"Using default path: `rpath'"'
		}
	}
	
	cap confirm file "`rpath'"
	if _rc {
		di as error "R executable not found. Specify R executable using option rpath() or using the global RSCRIPT_PATH"
		exit 601		
	}
	
	* Calling a script using "~" notation causes a fatal error with shell (Unix/Mac). Avoid by converting to absolute path.
	qui if strpos("`using'","~") {
		mata: pathsplit(st_local("using"), path = "", fname = "")
		mata: st_local("path", path)
		mata: st_local("fname", fname)
		
		local workdir_orig "`c(pwd)'"
		cd `"`path'"'
		local using "`c(pwd)'/`fname'"
		cd "`workdir_orig'"
		confirm file "`using'"
	}
	
	* Ensure valid version numbers were passed to version()
	if !mi(`"`rversion'"') {
		if wordcount(`"`rversion'"')>2 {
			di as error "rversion() invalid -- too many elements"
			exit 198
		}
		
		tokenize `"`rversion'"'
		while !mi(`"`1'"') {
			if strpos(`"`1'"',"..") {
				di as error `"rversion() invalid: `1' is invalid version number"'
				exit 198
			}
			
			* The following regex:
			*   (1) allows trailing and leading spaces
			*   (2) requires first and last elements to be a digit
			*   (3) allows middle to have arbitrary number of digits and decimals
			if !regexm(`"`1'"',"^[ ]*[0-9][.0-9]*[0-9] *$") {
				di as error `"rversion() invalid: `1' is invalid version number"'
				exit 198					
			}			
			macro shift
		}
		
		* Second argument to rversion is optional; set to -1 if not specified
		if wordcount(`"`rversion'"')==1 local rversion `"`rversion' -1"'
	}
	
	************************************************
	* Detect shell version
	************************************************	
	* Syntax for the -shell- call depends on which version of the shell is running:
	*	Unix csh:  /bin/csh
	*	Unix tcsh: /usr/local/bin/tcsh (default on NBER server)
	*	Unix bash: /bin/bash
	*	Windows
	shell echo "$0" > `shell'
	file open `shellfile' using `"`shell'"', read
	file read `shellfile' shellline
	file close `shellfile'		

	************************************************
	* Version control. Redirect stdout to `out' and stderr to `err'
	************************************************
	if !mi(`"`rversion'"') {
		
		local rversion_script "$GITHUB/rscript/src/_rversion.R"
		
		* shell call differs for csh/bash/other (windows is "other")
		if strpos("`shellline'", "csh") {	
			shell ("`rpath'" "`rversion_script'" `rversion' > `out') >& `err'
		}

		else if strpos("`shellline'", "bash") {
			shell "`rpath'" "`rversion_script'" `rversion' > `out' 2>`err'
		}

		else {
			shell "`rpath'" "`rversion_script'" `rversion' > `out' 2>`err'
		}
		
		* Report output from version control call
		di as result "Version information:"
		type `"`out'"'
		di as result ""
		type `"`err'"'
		
		cap mata: parse_stderr("`err'")
		if _rc==198 {
			di as error "This R installation does not meet the version requirements specified in rversion()"
			di as error _skip(5) `"You can download the version you need by visiting {browse "https://www.r-project.org"}"'
			error 9
		}
		else if _rc {
			di as error "Encountered a problem while parsing stderr"
			di as error "Mata error code: " _rc
		}		
	}
	
	************************************************
	* Run the script. Redirect stdout to `out' and stderr to `err'
	************************************************
	if !mi("`using'") {
		
		di as result `"Running R script: `using'"'
		if !mi(`"`args'"') di as result `"Args: `args'"'	
		di as result _n
		
		* shell call differs for csh/bash/other (windows is "other")
		if strpos("`shellline'", "csh") {	
			shell ("`rpath'" "`using'" `args' > `out') >& `err'
		}
		
		else if strpos("`shellline'", "bash") {
			shell "`rpath'" "`using'" `args' > `out' 2>`err'
		}
		
		else {
			shell "`rpath'" "`using'" `args' > `out' 2>`err'
		}
		
		return local rpath `rpath'
		
		************************************************
		* Display stdout and stderr output
		************************************************
		di as result "Begin R output:"
		di as result "`="_"*80'"
		
		di as result "{ul:stdout}:"
		type `"`out'"'
		di as result _n
		di as result "{ul:stderr}:"
		type `"`err'"'
		
		di as result "`="_"*80'"
		di as result "...end R output"_n
		
		
		************************************************
		* If there was an "error" in the execution of the R script, notify the user (and break, unless -force- option is specified)
		************************************************
		cap mata: parse_stderr("`err'")
		if _rc==198 {
			display as error "`using' ended with an error"
			display as error "See stderr output above for details"
			if "`force'"=="" error 198
		}
		else if _rc {
			display as error "Encountered a problem while parsing stderr"
			display as error "Mata error code: " _rc
		}
		
		* In a few (rare) cases, a "fatal error" message will be written to stdout rather than stderr
		cap mata: parse_stdout("`out'")
		if _rc==198 {
			display as error "`using' ended with a fatal error"
			display as error "See stdout output above for details"
			if "`force'"=="" error 198
		}
		else if _rc {
			display as error "Encountered a problem while parsing stdout"
			display as error "Mata error code: " _rc
		}
	
	}
end

********************************
* AUXILIARY FUNCTIONS
********************************

* Parse the stderr and stdout output files to check for errors
mata:
void parse_stderr(string scalar filename)
{
	real scalar input_fh
	string scalar line

	input_fh = fopen(filename, "r")
	
	while ((line=fget(input_fh)) != J(0,0,"")) {
		if (strpos(strlower(line), "error")!=0) exit(error(198))
	}
	
	fclose(input_fh)
}

void parse_stdout(string scalar filename)
{
	real scalar input_fh
	string scalar line

	input_fh = fopen(filename, "r")
	
	while ((line=fget(input_fh)) != J(0,0,"")) {
		if (strpos(strlower(line), "fatal error")!=0) exit(error(198))
	}
	
	fclose(input_fh)
}

end
** EOF
