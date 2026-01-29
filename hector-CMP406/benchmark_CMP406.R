# Script that generates the benchmarks & key metrics. This script assumes 
# that the run_v3.5.0 script has already been run. 
# TODO add other possible benchmarking chunks

# 1.AR6 ------------------------------------------------------------------------
# Load the required functions - this needs to be the gcam specific funtions 
# since there are no future multiforcing runs
source(file.path("fxns", "AR6_benchmark_fxns-gcam.R"))


# Calculate the AR6 benchmarks. 
file <- here::here("output", "output-CMP406.csv")

# Note that since 
out  <- get_AR6_benchmarks(file)
write.csv(out, 
          file = here::here("output", "AR6_benchmarks-CMP406.csv"), 
          row.names = FALSE)

