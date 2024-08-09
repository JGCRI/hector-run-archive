# Script to run V3.2.0 Hector simulations.

# 0. Set Up --------------------------------------------------------------------
# Using correct Hector version
# options(download.file.method = "wininet") # Line to make this work on Windows
remotes::install_github("jgcri/hector@v3.2.0")
stopifnot(packageVersion("hector") == "3.2.0")

# Imports and constants
library(hector)
library(tidyr)

VERSION_DIR <- here::here("hector-v3.2.0")
INPUT_DIR <- file.path(VERSION_DIR, "input")

OUTPUT_DIR <- here::here("output")
OUTPUT_FILE <- file.path(OUTPUT_DIR, "output-V3.2.0.csv")

VARIABLES <- c(GLOBAL_TAS(), GMST(), LAND_TAS(), RF_TOTAL(), CONCENTRATIONS_CO2(), RF_CO2(), 
               NPP(), VEG_C(), SOIL_C(), DETRITUS_C(), SST(), HEAT_FLUX(), SST_HL(), 
               SST_LL(),  OCEAN_C_HL(), OCEAN_C_LL(), OCEAN_C_IO(), OCEAN_C_DO(), 
               CONCENTRATIONS_CH4(), HL_OCEAN_UPTAKE(), OCEAN_UPTAKE())
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


# 2. DECK Runs  -----------------------------------------------------------
scns <- c("1pctCO2-4xext", "1pctCO2", "abruptx0p5CO2", "abruptx2CO2", 
          "abruptx4CO2", "picontrol_concentration")

list.files(INPUT_DIR, pattern = paste0(scns, collapse = "|")) %>% 
  lapply(run_hector, vars = VARIABLES) %>% 
  do.call(what = "rbind") %>%  
  mutate(scenario = if_else(scenario ==  "picontrol_concentration", "piControl",  scenario)) -> 
  results2


# 3. Impulse Runs  -----------------------------------------------------------

ini_path <- file.path(INPUT_DIR, "picontrol_concentration.ini")
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
commit <-  substring(desc$RemoteSha, 1, 6)

results <- bind_cols(version = version,
                     commit = commit, 
                     comb_results)

# Writing results to a csv
write.csv(results, OUTPUT_FILE, row.names = FALSE)
