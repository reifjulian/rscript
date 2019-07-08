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

error_command

x <- matrix(1:10, ncol = 5)
write.csv(x, file=arg2)


## EOF