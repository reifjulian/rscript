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

# This error is raised inside a function call, so R reports it as
# "Error in gzfile(file, "rb") : cannot open the connection" rather than "Error: ..."
# See https://github.com/reifjulian/rscript/issues/12
x <- readRDS("this_file_does_not_exist.Rds")

write.csv(x, file=arg2)


## EOF
