* This script runs a series of tests on the -rscript- package
* Authors: David Molitor and Julian Reif
adopath ++ "../src"
set more off
tempfile t t1 t2
version 13
program drop _all

* This script requires RSCRIPT_PATH to be defined
local rscript_exe "$RSCRIPT_PATH"
assert !mi("`rscript_exe'")


******************************
* Run examples and verify output
******************************

***
* Example 1
***

* (a) using $RSCRIPT_PATH 
rscript using example_1.R, args("arg1 with spaces" "`t1'")
confirm file "`t1'"
erase "`t1'"

* (b) using rpath(), with and without RSCRIPT_PATH defined
rscript using example_1.R, rpath("`rscript_exe'") args("arg1 with spaces" "`t1'")
confirm file "`t1'"
erase "`t1'"

global RSCRIPT_PATH ""
rscript using example_1.R, rpath("`rscript_exe'") args("arg1 with spaces" "`t1'")
confirm file "`t1'"
erase "`t1'"

* (c) "Using default path" (should be noted in text output)
rscript using example_1.R, args("arg1 with spaces" "`t1'")
confirm file "`t1'"
erase "`t1'"

global RSCRIPT_PATH "`rscript_exe'"

* Example 2: replicate OLS with robust standard errors (note: requires estimatr package)
sysuse auto, clear
reg price mpg, robust
save "`t1'", replace
rscript using example_2.R, args("`t1'" "`t2'")
insheet using "`t2'", comma clear
assert abs(stderror - 57.47701)<0.0001 & abs(estimate+238.8943)<0.0001 if term=="mpg"
erase "`t2'"

* Example 3: expanding ~ to user's home directory (unix/mac only)
* Note: for this example to work, the /rscript folder must be placed in user's home directory)
if "`c(os)'"!="Windows" {
	rscript using "~/rscript/test/example_1.R", args("Hello World!" "`t2'")
	confirm file "`t2'"
	erase "`t2'"	
}

******************************
* Generate intentional errors
******************************

* Specifying wrong file path
rcof noi rscript using example_1.R, args("Hello World!" "`t2'") rpath("xxx:/xxx")==601
assert _rc==601

* Example_error.R has an error in the R code ("Error: object 'error_command' not found"), so rscript should return _rc==198
di as error "example_error.R ended with an error" _n "See stderr output above for details" _n "invalid syntax"
rcof noi rscript using example_error.R, args("arg1 with spaces" "`t1'")==198

******************************
* rversion() and require() examples 
******************************
* Note, `rscript, rversion(Y X)`, where Y>X is allowable syntax, but will always generate an error

* Check that R >= 3.6, and that 3.6 <= R <= 19.2
rscript, rversion(3.6.0)
rscript, rversion("3.6.0   ")
rscript, rversion("  3.6.0   " "")
rscript, rversion(3.6.0 19.2)

rcof noi rscript, rversion(1.5 1.5)
assert _rc==9

rcof noi rscript, rversion(9)
assert _rc==9

rcof noi rscript, rversion(9.)
assert _rc==198

rcof noi rscript, rversion("9.    ")
assert _rc==198

rscript using example_1.R, args("arg1 with spaces" "`t1'") rversion(3.6)
confirm file "`t1'"
erase "`t1'"

rcof noi rscript, rversion(3.6.0 3.2 1)
assert _rc==198

rcof noi rscript, rversion(3.6..0)
assert _rc==198

rcof noi rscript, rversion(-3.6.0)
assert _rc==198

rscript, rversion(3.6) require("tidyverse")

rcof noi rscript, rversion(3.6) require("tidyverse" "fakepackage")
assert _rc==9

rcof noi rscript, require("hi" 3 "32hi" "tidyverse" `"32""')
assert _rc==198

***
* Miscellaneous QC's
***

* No using specified
rcof noi rscript, args("arg1 with spaces" "`t1'")
assert _rc==100

* Missing file specified
rcof noi rscript using missing.R, args("arg1 with spaces" "`t1'")
assert _rc==601


** EOF
