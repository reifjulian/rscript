# RSCRIPT: call an R script from Stata.

- Current version: `1.1.2 4feb2024`
- Jump to: [`overview`](#overview) [`installation`](#installation) [`platforms`](#platforms) [`usage`](#usage) [`tutorial`](#tutorial) [`update history`](#update-history) [`authors`](#authors)

-----------

## Overview 

`rscript` is a cross-platform [Stata](http://www.stata.com) command that calls an external R script and displays the resulting R output and error messages in the Stata console. It allows the user to supply arguments to the R script, enforce base R version control, and check for required packages.

## Installation

```stata
* Determine which version of -rscript- you have installed
which rscript

* Install the most recent version of -rscript-
net install rscript, from("https://raw.githubusercontent.com/reifjulian/rscript/master") replace
```

## Platforms

`rscript` is compatible with Windows, Mac, and Linux when Stata is invoked in interactive mode (the usual case). In batch mode, `rscript` is compatible only with Mac and Linux. `rscript` [does not work in batch mode on Windows](https://github.com/reifjulian/rscript/issues/2).

## Usage

`rscript` works by calling the Rscript executable that comes with your R installation. You can specify the location of this executable using the  option `rpath(pathname)` or by defining the global macro `RSCRIPT_PATH`. On Mac/Linux, the Rscript path is typically `/usr/local/bin/Rscript` or `/usr/bin/Rscript`. On Windows, the path for R version X.Y.Z is typically `C:/Program Files/R/R-X.Y.Z/bin/Rscript.exe`. If you don't specify a path, `rscript` will try to find the Rscript executable on its own by searching commonly used paths. 

Here are the three different ways to call an R script:

```stata
* Use the -rpath()- option to specify the path to the Rscript executable
rscript using filename.R, rpath("C:/Program Files/R/R-X.Y.Z/bin/Rscript.exe")

* Use global macro RSCRIPT_PATH to specify the path to the Rscript executable
global RSCRIPT_PATH "C:/Program Files/R/R-X.Y.Z/bin/Rscript.exe"
rscript using filename.R

* Let -rscript- find the Rscript executable on its own
global RSCRIPT_PATH ""
rscript using filename.R
```

For more details on `rscript` syntax and options, see the Stata help file included with the package.

## Tutorial 

This tutorial assumes you have [installed](#installation) the `rscript` Stata package and have successfully installed R version 3.6 or later, which is freely available [online](https://www.r-project.org). You also need to install the following R packages: `tidyverse`, `haven`, and `estimatr`. Install these packages by opening R and executing the following three lines of code:

```R
install.packages('tidyverse', repos='http://cran.us.r-project.org')
install.packages('haven', repos='http://cran.us.r-project.org')
install.packages('estimatr', repos='http://cran.us.r-project.org')
```

We will write a Stata script that calls an R script, **ols_robust.R**, and feeds it two arguments: an input filename and an output filename. The R script will read the input file, estimate an OLS regression with robust standard errors, and write the results to the output file. Here is the code for **ols_robust.R**:

```R
# Required libraries
library('tidyverse')
library('haven')
library('estimatr')

# Parse arguments (if present)
args = commandArgs(trailingOnly = "TRUE")
if (length(args)) {
  arg1 <- args[1]
  arg2 <- args[2]
} else {
  arg1 <- "C:/Program Files/Stata16/ado/base/a/auto.dta"
  arg2 <- "output.csv"
}

# Estimate OLS model with robust standard errors and display output
my_data <- read_dta(arg1)
ols <- lm_robust(price ~ mpg, data = my_data, se_type = "HC1")
ols

# Outsheet OLS results
write_csv(tidy(ols), arg2)

## EOF
```
Below is the Stata code that calls **ols_robust.R**. We use the `args()` option to feed it the two inputs it expects, and require the user's base R installation to be version 3.6 or higher by specifying the option `rversion(3.6)`:

```stata
* Stata: OLS with robust standard errors
sysuse auto, clear
reg price mpg, robust

* R: OLS with robust standard errors
* Note: this R script requires 3 add-on libraries: tidyverse, haven, and estimatr
* Note: we are requiring user to have R version 3.6 or later
tempfile auto output
save "`auto'", replace
rscript using ols_robust.R, args("`auto'" "`output'") rversion(3.6)

* Read in the R results
insheet using "`output'", comma clear
list
```

The Stata script begins by running the OLS regression in Stata.

![Stata OLS output](images/stata_ols.png)

We then save the dataset to a tempfile and call the R script that we wrote.

![Running rscript](images/stata_rscript.png)

`rscript` reports that we are calling **ols_robust.R** and feeding it two arguments, which correspond to the names of the two tempfiles. `rscript` also displays the output produced by R. We can see here that the point estimates and standard errors are the same as those that were computed by Stata. (Don't worry about the `tidyverse` conflicts that are shown in the stderr output. These namespace conflicts are quite common in R.) 

Finally, we read in the results that were outputted from R into Stata and display them. We again have confirmation that that the point estimates and standard errors are the same in both Stata and R. 

![rscript output](images/stata_rscript_output.png)

## Update History
* **February 4, 2024**
  - `rscript` now breaks after errors when running R scripts on non-English R installations
* **May 16, 2023**
  - Added `async` option
  - `rscript` now breaks only when first word of stderr is "Error:"
* **August 3, 2021**
  - Added `rversion()` option
  - Added `require()` option
  - Edited output text for case when not using a default path (no effect on functionality)
  - Calls to `rscript` in batch mode on Stata for Windows now break with an informative error message (no effect on functionality) 
* **November 25, 2020**
  - `rscript` now searches for the R executable if `RSCRIPT_PATH` undefined and `rpath()` not specified
* **March 23, 2020**
  - Added support for pathnames with "~"
* **September 4, 2019**
  - stderr is now parsed by Mata rather than Stata
* **May 2, 2019**
  - Default path is now set by the global macro `RSCRIPT_PATH`
* **January 22, 2019**
  - Added `force` option

## Authors

[David Molitor](http://www.davidmolitor.com)
<br>University of Illinois
<br>dmolitor@illinois.edu

[Julian Reif](http://www.julianreif.com)
<br>University of Illinois
<br>jreif@illinois.edu
