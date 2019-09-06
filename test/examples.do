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

* Specify location of R and run example_1.R. Should work regardless of whether global RSCRIPT_PATH was specified
rscript using example_1.R, rpath("`rscript_exe'") args("arg1 with spaces" "`t1'")
global RSCRIPT_PATH ""
rscript using example_1.R, rpath("`rscript_exe'") args("arg1 with spaces" "`t1'")
global RSCRIPT_PATH "`rscript_exe'"
confirm file "`t1'"
erase "`t1'"

* Use a default path and run example_1.R (not working on OS X currently)
global RSCRIPT_PATH "`rscript_exe'"
rscript using example_1.R, args("Hello World!" "`t2'")
confirm file "`t2'"
erase "`t2'"

* Example 2: replicate OLS with robust standard errors
sysuse auto, clear
reg price mpg, robust
save "`t1'", replace
rscript using example_2.R, args("`t1'" "`t2'")
insheet using "`t2'", comma clear
erase "`t2'"

******************************
* Generate intentional errors
******************************

* Failing to specify location of rscript.exe
di as text "Location of R executable must be specified using option rpath() or using the global RSCRIPT_PATH"
global RSCRIPT_PATH ""
rcof noi rscript using example_1.R, args("Hello World!" "`t2'")==198
global RSCRIPT_PATH "`rscript_exe'"

* Specifying wrong file path
di as text "file xxx:/xxx not found"
rcof noi rscript using example_1.R, args("Hello World!" "`t2'") rpath("xxx:/xxx")==601
assert _rc==601

* Example_error.R has an error in the R code ("Error: object 'error_command' not found"), so rscript should return _rc==198
di as text "example_error.R ended with an error" _n "invalid syntax"
rcof noi rscript using example_error.R, args("arg1 with spaces" "`t1'")==198


** EOF