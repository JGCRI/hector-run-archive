# Script to run V3.5.0 Hector simulations.

# 0. Set Up --------------------------------------------------------------------
# Using correct Hector version

#devtools::load_all("~/Documents/Hector-WD/hector/")
remotes::install_github("jgcri/hector@v3.5.0")
# TODO this will need to be updated to the correct version! 
stopifnot(packageVersion("hector") == "3.5.0")

# Imports and constants
library(dplyr)
library(hector)
library(tidyr)

VERSION_DIR <- here::here("hector-CMP406")
INPUT_DIR <- file.path(VERSION_DIR, "input")

OUTPUT_DIR <- here::here("output")
OUTPUT_FILE <- file.path(OUTPUT_DIR, "output-CMP406.csv")

VARIABLES <- ALL_VARS()
YEARS <- 1750:2300

# Function to run Hector with a given ini file
run_hector <- function(ini_name, yrs = YEARS, vars = VARIABLES) {
  ini_path <- file.path(INPUT_DIR, ini_name)
  name <- gsub(pattern = "hector_|.ini", replacement = "", x = ini_name)
  core <- newcore(ini_path)
  
  # READ IN THE GCAM PARAMETERIZATION SO THAT EVEN THE IDEALIZED RUNS 
  # USE THIS... 
  # diff	beta	q10_rh
  # 0.821	0.866	1.884
  
  setvar(core = core, dates = NA, var = DIFFUSIVITY(), values =  0.821, unit = getunits(DIFFUSIVITY()))
  reset(core)
  setvar(core = core, dates = NA, var = BETA(), values =  0.866, unit = getunits(BETA()))
  reset(core)
  setvar(core = core, dates = NA, var = Q10_RH(), values =  1.884, unit = getunits(Q10_RH()))
  reset(core)
  
  run(core, runtodate = max(yrs))
  results <- fetchvars(core, 
                       dates = yrs, 
                       vars = vars, 
                       scenario = name)
  return(pivot_wider(results, names_from = year))
}


# 1. GCAM historical run   -----------------------------------------------------

# Since this version of hector is calibrated using the GCAM emissions we cannot 
# run the standard ssp scenarios. 
 
results1 <- run_hector(ini_name = "hector-gcam.ini", yrs = 1750:2021)




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

comb_results <- bind_rows(results1, results2, results3)
version      <- paste0("CMP406")
desc   <- packageDescription("hector")
commit <- NULL

results <- bind_cols(version = version,
                     commit = commit, 
                     comb_results)

# Writing results to a csv
write.csv(results, OUTPUT_FILE, row.names = FALSE)
