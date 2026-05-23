# scripts/01_fetch_data.R
# Core execution script to pull raw data from NPS web services

# 1. Source Dependencies --------------------------------------------------
# Sourcing the functional building blocks from the R/ directory
source("R/api_helpers.R")
source("R/get_park_units.R")
source("R/get_species_lists.R")

# Load required libraries for the data pipeline
library(httr2)
library(purrr)
library(dplyr)
library(readr)

# 2. Retrieve Park Units --------------------------------------------------
message("Fetching park units from NPS service...")

# Calls the existing function name from R/get_park_units.R
# Expected to return a character vector or dataframe of park codes
park_units <- get_park_units()

# Basic validation check to ensure we have data before proceeding
if (length(park_units) == 0) {
  stop("No park units retrieved. Aborting data fetch workflow.")
}


# 3. Iterate and Fetch Species Lists --------------------------------------
message(paste("Beginning iteration across", length(park_units), "park units..."))

# Using purrr::map to iterate through the codes using your existing function
# name from R/get_species_lists.R. 
# Note: Ensure get_species_lists handles single park inputs, rate-limiting, 
# and error handling internally via R/api_helpers.R.
raw_species_data <- purrr::map(
  park_units, 
  ~get_species_lists(.x), 
  .progress = TRUE
)


# 4. Process and Combine --------------------------------------------------
# Bind the list elements into a single data frame if they share a schema
combined_species_df <- dplyr::bind_rows(raw_species_data)


# 5. Export Raw Data ------------------------------------------------------
# Save the final raw pull to disk. 
# Note: As seen in image_cd4320.jpg, your .gitignore automatically excludes 
# tracking for data/ and common data extensions like .csv or .rds.
output_path <- "data/raw_nps_species.rds"

if (!dir.exists("data")) dir.create("data")

readr::write_rds(combined_species_df, output_path)
message(paste("Raw species list successfully saved to:", output_path))
