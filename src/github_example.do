* Stata: OLS with robust standard errors
sysuse auto, clear
reg price mpg, robust

* R: OLS with robust standard errors
* Note: this R script requires 3 add-on libraries: tidyverse, haven, and estimatr
* Note: we are requiring user to have R version 3.6 or later
tempfile auto output
save "`auto'", replace
rscript using ols_robust.R, args("`auto'" "`output'") rversion(3.6) require("tidyverse" "haven" "estimatr")

* Read in the R results
insheet using "`output'", comma clear
list
