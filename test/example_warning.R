rm(list=ls())

args = commandArgs(trailingOnly = "TRUE")
if (length(args)) {
  arg1 <- args[1]
} else {
  arg1 <- "This is a warning, not an error."
}

# warning that contains the word "error"
warning(arg1)


## EOF