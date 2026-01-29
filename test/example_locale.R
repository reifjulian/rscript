rm(list=ls())

# Set language to French. Without the LC_ALL=C override by rscript,
# this would cause R to produce French error messages (e.g., "Erreur"
# instead of "Error"), which rscript would fail to detect.
Sys.setenv(LANGUAGE = "fr")
stop("locale test error")


## EOF
