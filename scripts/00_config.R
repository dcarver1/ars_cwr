# scripts/00_config.R
# Global configuration and initialization script for the ars_cwr pipeline

# 1. Package Management ---------------------------------------------------
# Centralized package attachment using pacman
if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")

# Add 'stringr' and 'tidyr' globally since they are heavy workforce packages 
# for your data separation and text cleaning steps
pacman::p_load(httr2, purrr, dplyr, tidyr, readr, stringr)


# 2. Directory Initialization ---------------------------------------------
message("Initializing project directory structure...")
required_dirs <- c("data", "data/raw", "data/processed")

purrr::walk(required_dirs, function(dir) {
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE)
  }
})


# 3. Global File Path Definitions -----------------------------------------
# Defining paths here prevents typos across different workflow scripts
PATH_RAW_SPECIES    <- "data/raw/raw_nps_species.rds"
PATH_SPECIES_CORE   <- "data/processed/nps_species_core.rds"
PATH_SYNONYM_LOOKUP <- "data/processed/nps_synonym_lookup.rds"

message("Configuration successfully loaded.")