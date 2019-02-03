* This script runs a series of tests on the -rscript- package to help prevent inadvertent bugs.
* Authors: David Molitor and Julian Reif
clear
adopath ++ "../src"
set more off
tempfile t
version 13
program drop _all

* Typical R location for OS X
local rscript_exe "/usr/local/bin/Rscript"

* Specify path
rscript using example_1.R, rpath("`rscript_exe'") args("arg1" "arg2")


* Use a default path (not working on OS X currently)
rscript using example_1.R, args("arg1" "arg2")

** EOF
