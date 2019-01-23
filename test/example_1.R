rm(list=ls())

args = commandArgs(trailingOnly = "TRUE")
if (length(args)) {
  arg1 <- args[1]
  arg2 <- args[2]
} else {
  arg1 <- "3"
  arg2 <- "4"
}

arg1
arg2


## EOF