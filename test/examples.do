* This script runs a series of tests on the -rscript- package
* Authors: David Molitor and Julian Reif
clear
adopath ++ "../src"
set more off
tempfile t
version 13
program drop _all

* Typical R location for OS X
local rscript_exe "/usr/local/bin/Rscript"

* Typical R location for Windows
local rscript_exe "C:/Program Files/R/R-3.4.4/bin/x64/Rscript.exe"

* Specify location of R and run example_1.R
tempfile t1
rscript using example_1.R, rpath("`rscript_exe'") args("arg1 with spaces" "`t1'")
confirm file "`t1'"


* Use a default path and run example_1.R (not working on OS X currently)
tempfile t2
global RSCRIPT_PATH "`rscript_exe'"
rscript using example_1.R, args("Hello World!" "`t2'")
confirm file "`t2'"

** EOF
