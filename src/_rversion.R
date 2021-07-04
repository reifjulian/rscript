########
# This script enforces version control by checking the user's base R version
########

########
# Syntax
# _rversion.R rmin [ rmax ]

# ARGUMENTS:
# rmin (required): minimum R version
# rmax (optional): maximum R version


# Syntax 1 example: require a minimum version of R
# _rversion 3.6.0

# Syntax 2 example: require that R is between 3.4 and 3.6
# _rversion 3.4 3.6
########

args = commandArgs(trailingOnly = "TRUE")
rmin <- args[1]
rmax <- args[2]

  
###
# Base R version control
###

rcurrent <- packageVersion("base")
print(paste("R installation is version", rcurrent))

# Minimum version requirements
if (rcurrent < rmin) {
  vers_ex_msg = paste0("This R installation is older than version ", rmin)
  stop(vers_ex_msg)
}

# Maximum version requirements (optional)
if (rmax != '-1') {
  if (rcurrent > rmax ) {
    vers_ex_msg = paste0("This R installation is newer than version ", rmax)
    stop(vers_ex_msg)
  }
}

##EOF


