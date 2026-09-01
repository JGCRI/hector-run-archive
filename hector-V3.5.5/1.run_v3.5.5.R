# Script to run V3.5.5 Hector simulations.

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

# Define/create directories. 
VERSION_DIR <- here::here(paste0("hector-v", VERSION))
INPUT_DIR <- file.path(VERSION_DIR, "input")

OUTPUT_DIR <- here::here("output")
OUTPUT_FILE <- file.path(OUTPUT_DIR, paste0("output-V", VERSION, ".csv"))

# Define some constants
VARIABLES <- ALL_VARS()
YEARS <- 1750:2300

# Function to run Hector with a given ini file
run_hector <- function(ini_name, yrs = YEARS, vars = VARIABLES) {
  ini_path <- file.path(INPUT_DIR, ini_name)
  name <- gsub(pattern = "hector_|.ini", replacement = "", x = ini_name)
  core <- newcore(ini_path)
  run(core)
  results <- fetchvars(core, 
                       dates = yrs, 
                       vars = vars, 
                       scenario = name)
  return(pivot_wider(results, names_from = year))
}


# 1. Multi-forcing Runs  -------------------------------------------------------
# Getting vector of ini files for the spp runs... 
list.files(INPUT_DIR, pattern = "ssp") %>% 
  lapply(run_hector) %>% 
  do.call(what = "rbind") -> 
  results1


# 2. DECK Runs  ----------------------------------------------------------------
# TODO need to add these inputs into the frame work! 
scns <- c("1pctCO2-4xext", "1pctCO2", "abruptx0p5CO2", "abruptx2CO2", 
          "abruptx4CO2", "picontrol")


list.files(INPUT_DIR, pattern = paste0(scns, collapse = "|")) %>% 
  lapply(run_hector, vars = VARIABLES) %>% 
  do.call(what = "rbind") %>%  
  mutate(scenario = if_else(scenario ==  "picontrol", "piControl",  scenario)) -> 
  results2

# 3. Impulse Runs  -----------------------------------------------------------

ini_path <- file.path(INPUT_DIR, "hector_picontrol.ini")
core <- newcore(ini_path, name = "impulsex2CO2")
run(core)
pi_co2 <- fetchvars(core, dates = 1850, vars = CONCENTRATIONS_CO2())[["value"]]
setvar(core, dates = 1850, var = CO2_CONSTRAIN(), 
       unit = getunits(CO2_CONSTRAIN()), values = pi_co2 * 2)
reset(core)
run(core)
fetchvars(core, 
          dates = YEARS, 
          vars = VARIABLES) %>% 
  pivot_wider(names_from = year) -> 
  results3 

# 4. Save Results  -------------------------------------------------------------

comb_results <- rbind(results1, results2, results3)
version      <- packageVersion("hector")
desc   <- packageDescription("hector")
commit <- NULL

results <- bind_cols(version = version,
                     commit = commit, 
                     comb_results)

# Writing results to a csv
write.csv(results, OUTPUT_FILE, row.names = FALSE)
