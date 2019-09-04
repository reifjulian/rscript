# Required libraries
library(tidyverse)
library(haven)
library(estimatr)

# Parse arguments (if present)
args = commandArgs(trailingOnly = "TRUE")
if (length(args)) {
  arg1 <- args[1]
  arg2 <- args[2]
} else {
  
  arg1 <- "C:/Program Files/Stata16/ado/base/a/auto.dta"
  
  arg2 <- "output.csv"
}

# Estimate OLS model with robust standard errors
my_data <- read_dta(arg1)
ols1 <- lm_robust(price ~ mpg, data = my_data, se_type = "HC1")
ols1

# Outsheet OLS results
x <- tidy(ols1)
write.csv(x, file=arg2)

## EOF