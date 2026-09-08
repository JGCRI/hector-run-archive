# Script that generates the benchmarks & key metrics. This script assumes 
# that the run_v3.5.5 script has already been run. 
# TODO add other possible benchmarking chunks


# 0. Set Up --------------------------------------------------------------------
# Using correct Hector version
VERSION <- "3.5.5"

# TODO users may need to make changes as to how hector is installed/built. 
devtools::load_all("~/Documents/Hector-WD/hector/")
repo_release <- paste0("jgcri/hector@v", VERSION)
# remotes::install_github(repo_release)
stopifnot(packageVersion("hector") == VERSION)

# Required packages
library(dplyr)
library(hector)
library(tidyr)

# 1.AR6 ------------------------------------------------------------------------
# Load the required functions 
source(file.path("fxns", "AR6_benchmark_fxns.R"))


# Calculate the AR6 benchmarks. 
file <- here::here("output", paste0("output-V", VERSION, ".csv"))
out  <- get_AR6_benchmarks(file)
write.csv(out, 
          file = here::here("output", paste0("AR6_benchmarks-V", VERSION, ".csv")), 
          row.names = FALSE)

