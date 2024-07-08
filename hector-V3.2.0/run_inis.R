# Script to run all of the V3.2.0 ini files

# Imports and constants
library(hector)
library(tidyr)

VERSION_DIR <- here::here("hector-v3.2.0")
INPUT_DIR <- file.path(VERSION_DIR, "input")
OUTPUT_FILE <- file.path(VERSION_DIR, "output-V3.2.0.csv")

VARIABLES <- c(GLOBAL_TAS(), GMST(), 
               RF_TOTAL(), 
               CONCENTRATIONS_CO2(), RF_CO2(), NPP(),
               SST(), HEAT_FLUX())
YEARS <- 1750:2300

# Function to run Hector with a given ini file
run_hector <- function(ini_name) {
  ini_path <- file.path(INPUT_DIR, ini_name)
  core <- newcore(ini_path)
  run(core)
  results <- fetchvars(core, 
                       dates = YEARS, 
                       vars = VARIABLES, 
                       scenario = substr(ini_name, 8, nchar(ini_names) - 4))
  return(pivot_wider(results, names_from = year))
}

# Getting vector of ini files
all_input_names <- list.files(INPUT_DIR)
is_ini <- grepl(pattern = ".ini", all_input_names)
ini_names <- all_input_names[which(is_ini)]

comb_results <- NULL

# Running Hector on all the ini files
for (name in ini_names) {
  comb_results <- rbind(comb_results, run_hector(name))
}

# Adding relevant columns
comb_results$version <- "3.2.0"
comb_results$commit  <- "1ef0b4d"

# Reordering cols
comb_results <- comb_results[,c(ncol(comb_results) - 1, 
                                ncol(comb_results), 
                                1:(ncol(comb_results) - 2))]

# Writing results to a csv
write.csv(comb_results, OUTPUT_FILE, row.names = FALSE)