*! rscript 1.2 30mar2025 by David Molitor and Julian Reif
* 1.2    consolidated shell calls. For unix-based systems, return the PID.
* 1.1.2  fixed bug that caused rscript to not break after errors when running on non-English installations.
* 1.1.1  added async() option. edited parse_stderr to break only when first word of stderr is "Error:"
* 1.1:   added rversion() and require() options. fixed text output when using RSCRIPT_PATH
* 1.0.4: added default pathname
* 1.0.3: added support for "~" pathnames
* 1.0.2: stderr is now parsed by Mata instead of Stata
* 1.0.1: updated error handling

program define rscript, rclass

	version 13.0

	tempfile shell out err tmpfile_require rversion_control_script stata_pid_file
	tempname shellfile tmpname_require stata_pid_fh

	syntax [using/], [rpath(string) args(string asis) rversion(string) require(string asis) async force]
	
	************************************************
	* Error checking
	************************************************
  
	local os = lower("`c(os)'")
  
	* rscript does not work in batch mode on Stata for Windows because Stata ignores shell requests (as of Stata 17.0)
	if "`os'" == "windows" & "`c(mode)'" == "batch" {
		di as error "rscript does not work in batch mode on Stata for Windows because Stata ignores shell requests in this setting"
		exit 1
	}
  
	* User must specify a filename, unless rversion() was specified
	if mi(`"`rversion'`require'"') & mi("`using'") {
		di as error "using required"
		exit 100
	}
	if !mi("`using'") confirm file "`using'"
	
	* If user does not specify the location of the R executable, set the default to what is stored in RSCRIPT_PATH
	* If both are blank, then try using an os-specific default
	if mi(`"`rpath'"') {
		local rpath `"$RSCRIPT_PATH"'
		
		if mi(`"`rpath'"') {
			
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

	* Do basic QC to help ensure valid version numbers were specified in rversion():
	*  (1) Check that no more than 2 version numbers were passed
	*  (2) ".." is not allowable syntax in R
	*  (3) R does not allow version numbers to end in "."
	*  (4) some additional checks by regex
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
			
			if substr(trim(`"`1'"'),-1,1)=="." {
				di as error `"rversion() invalid: `1' is invalid version number (cannot end in '.')"'
				exit 198
			}			
			
			* The following regex:
			*   (1) allows trailing and leading spaces
			*   (2) requires first char to be a digit (requirement by R when checking string version numbers)
			*   (3) allows remainder to be an arbitrary number of digits and decimals
			if !regexm(`"`1'"',"^[ ]*[0-9]+[.0-9]* *$") {
				di as error `"rversion() invalid: `1' is invalid version number"'
				exit 198					
			}			
			macro shift
		}
		
		* Second argument to rversion is optional; set to -1 if not specified
		if wordcount(`"`rversion'"')==1 local rversion `"`rversion' -1"'
	}
	
	* Ensure no quotation marks passed to require()
	if !mi(`"`require'"') {
		
		tokenize `"`require'"'
		while !mi(`"`1'"') {
			if strpos(`"`1'"',`"""') {
				di as error "require() invalid: embedded quotation marks not allowed"
				exit 198
			}			
			macro shift
		}
	}
	
	* If async option specified, rpath call will be run in the background
	if !mi("`async'") {
		
		if !mi(`"`rversion'"') {
			di as error "Cannot specify async with rversion()"
			exit 198
		}
		
		* Unix/mac: "nohup" keeps command running even after logging out; '&' makes it run in the background; "echo $!" returns the PID
		if inlist("`os'","macosx","unix") {
			local rpath_start "nohup "
			local rpath_end "& echo $! > `stata_pid_file'"
		}
		
		* Windows: "cmd.exe /c start /B /min "" " to run in the background (using winexec)
		else if "`os'" == "windows" {
			local rpath_start `"cmd.exe /c start /B /MIN "" "'
		}
		
		else {
			di as error "async option not supported for the `c(os)' operating system"
			exit 198
		}
	}

	************************************************
	* Version control: rversion() and/or require() options. Redirect stdout to `out' and stderr to `err'
	************************************************
	if !mi(`"`rversion'`require'"') {
		
		* If rversion() not specified, set to default values of -1
		if mi(`"`rversion'"') local rversion "-1 -1"

		* If require() specified, write out list of packages to file
		if !mi(`"`require'"') {
			
			qui file open `tmpname_require' using `"`tmpfile_require'"', write text replace
			
			tokenize `"`require'"'
			while !mi(`"`1'"') {
				file write `tmpname_require' `"`1'"' _n	
				macro shift
			}
			qui file close `tmpname_require'
			
			local arg_require "`tmpfile_require'"
		}
		
		* Create an R script that will be used to check R version and/or installed packages
		qui write_r_script `rversion_control_script'

		if inlist("`os'","macosx","unix") {
			shell sh -c 'LANG=C "`rpath'" "`rversion_control_script'" `rversion' `arg_require' </dev/null >`out' 2>`err''
		}
		else {
			qui shell set "LANGUAGE=en" & "`rpath'" "`rversion_control_script'" `rversion' `arg_require' > `out' 2>`err'
		}

		* Report output from version control script call
		di as result "Version information:"
		type `"`out'"'
		type `"`err'"'
		
		cap mata: parse_stderr_version_control("`err'")
		if _rc==1 {
			di as error "This R installation does not meet the version requirements specified in rversion()"
			di as error _skip(2) `"You can download the version you need by visiting {browse "https://www.r-project.org"}"'
			error 9
		}
		else if _rc==2 {
			di as error "This R installation is missing packages specified in require()"
			di as error _skip(2) `"Packages can usually be installed by typing install.packages("X") at the R prompt, where X is the name of the package"'
			error 9
		}
		else if _rc==198 {
			display as error _n "Version and package requirement checks ended with an error in R"
			display as error "See stderr output above for details"
			if "`force'"=="" error 198
		}			
		else if _rc {
			di as error "Encountered a problem while parsing stderr"
			di as error "Mata error code: " _rc
		}
		if !mi("`using'") di ""
	}
	
	************************************************
	* Run the script specified by user. Redirect stdout to `out' and stderr to `err'. If run asynchronously on unix, store the PID.
	************************************************
	if !mi("`using'") {
		
		di as result `"Running R script: `using'"'
		if !mi(`"`args'"') di as result `"Args: `args'"'	

		if inlist("`os'","macosx","unix") {
			shell sh -c 'LANG=C `rpath_start' "`rpath'" "`using'" `args' </dev/null >`out' 2>`err' `rpath_end''
			if !mi("`async'") {
				file open `stata_pid_fh' using `"`stata_pid_file'"', read
				file read `stata_pid_fh' stata_pid
				file close `stata_pid_fh'
				local stata_pid = trim(`"`stata_pid'"')
				cap confirm number `stata_pid'
				if _rc local stata_pid = .
				return scalar PID = `stata_pid'
				if !mi(`stata_pid') global RSCRIPT_PID "$RSCRIPT_PID `stata_pid'"
				global RSCRIPT_PID = trim("$RSCRIPT_PID")
			}
		}
		else {
			if !mi("`async'") {
				winexec `rpath_start'"`rpath'" "`using'" `args' > `out' 2>`err' `rpath_end'
			}
			else shell set "LANGUAGE=en" & `rpath_start'"`rpath'" "`using'" `args' > `out' 2>`err' `rpath_end'
		}
		
		return local rpath `rpath'
		
		* If running aynchronously, exit without looking for stdout and stderr output
		if !mi("`async'") exit
		
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
		di as result "...end R output"
		
		************************************************
		* If there was an "error" in the execution of the R script, notify the user (and break, unless -force- option is specified)
		************************************************
		cap mata: parse_stderr("`err'")
		if _rc==198 {
			display as error _n "`using' ended with an error"
			display as error "See stderr output above for details"
			if "`force'"=="" error 198
		}
		else if _rc {
			display as error _n "Encountered a problem while parsing stderr"
			display as error "Mata error code: " _rc
		}
		
		* In a few (rare) cases, a "fatal error" message will be written to stdout rather than stderr
		cap mata: parse_stdout("`out'")
		if _rc==198 {
			display as error _n "`using' ended with a fatal error"
			display as error "See stdout output above for details"
			if "`force'"=="" error 198
		}
		else if _rc {
			display as error _n "Encountered a problem while parsing stdout"
			display as error "Mata error code: " _rc
		}
	}
end

********************************
* AUXILIARY FUNCTIONS
********************************

***
* write_r_script writes out an R script that checks the version of base R and confirms package installations 
***

* The program write_r_script expects one argument: the name of the file being written

* The R script that is written accepts three arguments:
*  (1) rmin (default, '-1', causes script to ignore enforcmement of minimum version)
*  (2) rmax (default, '-1', causes script to ignore enforcmement of maximum version)
*  (3) filename containing list of package names (optional)

program define write_r_script

	tempname filebf

	***
	* Write file to the first argument passed to write_script
	***
	qui file open `filebf' using "`1'", write text replace
	
	***
	* R script contents
	***
			
	* Parse arguments. Third argument (list of package names) is optional and referenced later on
	file write `filebf' `"args = commandArgs(trailingOnly = "TRUE")"' _n
	file write `filebf' `"rmin <- args[1]"' _n
	file write `filebf' `"rmax <- args[2]"' _n _n
	
	* Report curent version
	file write `filebf' `"rcurrent <- packageVersion("base")"' _n
	file write `filebf' `"print(paste("R installation is version", rcurrent))"' _n _n
	
	* Enforce minimum version requirements (if specified)
	file write `filebf' `"if (rmin != '-1') {"' _n
	file write `filebf' `"  if (rcurrent < rmin) {"' _n
	file write `filebf' `"    vers_ex_msg = paste0("This R installation is older than version ", rmin)"' _n
	file write `filebf' `"    stop(vers_ex_msg)"' _n
	file write `filebf' `"  }"' _n
	file write `filebf' `"}"' _n _n
	
	* Enforce maximum version requirements (if specified)
	file write `filebf' `"if (rmax != '-1') {"' _n
	file write `filebf' `"  if (rcurrent > rmax ) {"' _n
	file write `filebf' `"    vers_ex_msg = paste0("This R installation is newer than version ", rmax)"' _n
	file write `filebf' `"    stop(vers_ex_msg)"' _n
	file write `filebf' `"  }"' _n
	file write `filebf' `"}"' _n _n

	* If arg[3] (filename) was specified, read the file and check whether those packages were installed
	file write `filebf' `"if(length(args)==3) {"' _n
	file write `filebf' `"  packages <-  as.character(read.csv(args[3],header = FALSE)\$V1)"' _n
	file write `filebf' `"  installed <- packages %in% installed.packages()[, "Package"]"' _n
	file write `filebf' `"  if(any(!installed)) {"' _n
	file write `filebf' `"    vers_ex_msg = paste0("The following packages are not installed:\n  ", paste(packages[!installed],collapse="\n  "))"' _n
	file write `filebf' `"    stop(vers_ex_msg)"' _n
	file write `filebf' `"  }"' _n
	file write `filebf' `"}"' _n
	
	***
	* File close
	***	
	qui file close `filebf'

end

*********
* Mata functions used to parse the stderr and stdout output files to check for errors
*********

// Parser for the stderr file created by rversion() and require() options
mata:
void parse_stderr_version_control(string scalar filename)
{
	real scalar input_fh
	string scalar line

	input_fh = fopen(filename, "r")
	
	while ((line=fget(input_fh)) != J(0,0,"")) {
		if (strpos(strlower(line), "error: this r installation is")!=0) exit(error(1))
		if (strpos(strlower(line), "error: the following packages are not installed")!=0) exit(error(2))
		if (strpos(strlower(line), "error")!=0) exit(error(198))
	}
	
	fclose(input_fh)
}

// Parsers for the stderr and stdout files created when running the R script specified by the user
void parse_stderr(string scalar filename)
{
	real scalar input_fh
	string scalar line

	input_fh = fopen(filename, "r")
	
	while ((line=fget(input_fh)) != J(0,0,"")) {
		if (strpos(line, "Error:")==1) exit(error(198))
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
