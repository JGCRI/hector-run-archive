# Script that generates the benchmarks & key metrics. This script assumes 
# that the run_v3.5.0 script has already been run. 
# TODO add other possible benchmarking chunks

# 1.AR6 ------------------------------------------------------------------------
# Load the required functions 
source(file.path("fxns", "AR6_benchmark_fxns.R"))


# Calculate the AR6 benchmarks. 
file <- here::here("output", "output-V3.5.0.csv")
out  <- get_AR6_benchmarks(file)
write.csv(out, 
          file = here::here("output", "AR6_benchmarks-V3.5.0.csv"), 
          row.names = FALSE)

