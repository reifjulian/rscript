
* OS X
local rscript_exe "/usr/local/bin/Rscript"

rscript using example_1.R, rpath("`rscript_exe'") args("arg1" "arg2")

** EOF
