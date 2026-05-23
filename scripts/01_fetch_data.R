# scripts/01_fetch_data.R
# Core execution script to pull raw data from NPS web services

# 1. Environment Setup & Dependencies -------------------------------------
source("scripts/00_config.R")

# Source the local functional blocks from the R/ directory
source("R/api_helpers.R")
source("R/get_park_units.R")
source("R/get_species_lists.R")
source("R/split_synonyms.R")


# 2. Retrieve Park Units --------------------------------------------------
message("Fetching park units from NPS service...")
park_units <- get_park_units()

if (length(park_units) == 0) {
  stop("No park units retrieved. Aborting data fetch workflow.")
}


# 3. Iterate and Fetch Species Lists --------------------------------------
message(paste("Beginning iteration across", length(park_units), "park units..."))

raw_species_data <- purrr::map(
  park_units[1:100], 
  ~get_species_lists(.x), 
  .progress = TRUE
)


# 4. Process and Combine --------------------------------------------------
message("Combining and splitting raw data into relational tables...")

combined_species_df <- dplyr::bind_rows(raw_species_data)

relational_tables <- split_synonyms(combined_species_df)
species_core      <- relational_tables$core
synonym_lookup    <- relational_tables$synonyms


# 5. Export Raw Data ------------------------------------------------------
# Paths are now safely supplied by the global environment config
readr::write_rds(combined_species_df, PATH_RAW_SPECIES)
readr::write_rds(species_core,        PATH_SPECIES_CORE)
readr::write_rds(synonym_lookup,      PATH_SYNONYM_LOOKUP)

message(paste("Raw species list successfully saved to:", PATH_RAW_SPECIES))
message(paste("Core species table saved to:", PATH_SPECIES_CORE))
message(paste("Synonym lookup table saved to:", PATH_SYNONYM_LOOKUP))