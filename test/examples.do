adopath ++ "../src"

* OS X location
local rscript_exe "/usr/local/bin/Rscript"

* Windows location
local rscript_exe "C:/Program Files/R/R-3.4.4/bin/x64/Rscript.exe"

rscript using example_1.R, rpath("`rscript_exe'") args("arg1" "arg2")

** EOF
