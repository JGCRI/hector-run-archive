# Script to run V3.2.0 Hector simulations.

# 0. Set Up --------------------------------------------------------------------
# Using correct Hector version
# options(download.file.method = "wininet") # Line to make this work on Windows
remotes::install_github("jgcri/hector@main")
stopifnot(packageVersion("hector") == "3.2.0")

# Imports and constants
library(hector)
library(tidyr)
library(dplyr)

VERSION_DIR <- here::here("hector-v3.2.0")
INPUT_DIR <- file.path(VERSION_DIR, "input")

OUTPUT_DIR <- here::here("output")
OUTPUT_FILE <- file.path(OUTPUT_DIR, "output-V3.2.0.csv")

VARIABLES <- c("TAU_OH", "CH4_concentration", "O3_concentration", "N2O_concentration", "HL_ocean_uptake", "LL_ocean_uptake",  
               "DO_ocean_c", "HL_ocean_c", "IO_ocean_c", "LL_ocean_c", "HL_DIC", "LL_DIC",           
               "ocean_uptake", "HL_PCO2", "LL_PCO2", "HL_pH", "LL_pH", "HL_sst",           
               "LL_sst", "ocean_c", "HL_CO3", "LL_CO3", "NBP", "NPP",              
               "RH", "rh_ch4", "CO2_concentration", "atmos_co2", "veg_c", "detritus_c",       
               "soil_c", "permafrost_c", "thawedp_c", "f_frozen", "earth_c", "global_tas",       
               "gmst", "heatflux_mixed", "heatflux_interior", "heatflux", "land_tas", "sst",              
               "RF_BC", "FadjC2F6", "FadjCCl4", "FadjCF4", "FadjCFC11", "FadjCFC113",         
               "FadjCFC114", "FadjCFC115", "FadjCFC12", "FadjCH3Br", "FadjCH3CCl3", "FadjCH3Cl",         
               "FCH4", "RF_CO2", "RF_H2O_strat", "FadjHCFC141b", "FadjHCFC142b", "FadjHCFC22",        
               "FadjHFC125", "FadjHFC134a", "FadjHFC143a", "FadjHFC227ea", "FadjHFC23", "FadjHFC245fa",      
               "FadjHFC32", "FadjHFC4310", "RF_N2O", "RF_NH3", "RF_O3_trop", "RF_OC",            
               "FadjSF6", "RF_SO2","RF_aci","RF_albedo", "Fadjhalon1211", "Fadjhalon1301",     
               "Fadjhalon2402", "RF_misc", "RF_tot", "RF_vol")
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
                     comb_results) %>% 
  # Change the FCH4 variable name to be consistent
  # with V35 & the benchmarking fxn.  
  mutate(variable = if_else(variable == "FCH4", "RF_CH4", variable))


# Writing results to a csv
write.csv(results, OUTPUT_FILE, row.names = FALSE)
