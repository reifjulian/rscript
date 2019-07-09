rm(list=ls())

library(tidyverse)
library(haven)
library(estimatr)

args = commandArgs(trailingOnly = "TRUE")
if (length(args)) {
  arg1 <- args[1]
  arg2 <- args[2]
} else {
  arg1 <- "3"
  arg2 <- "4"
}

my_data <- read_dta(arg1)
ols1 <- lm_robust(price ~ mpg, data = my_data, se_type = "HC1")
ols1

x <- matrix(1:10, ncol = 5)
write.csv(x, file=arg2)


## EOF