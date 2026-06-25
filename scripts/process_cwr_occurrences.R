# scripts/process_cwr_occurrences.R
# This script aggregates the raw genus occurrence CSV files into a single,
# standardized occurrence dataset and exports it as an RDS file.

# 1. Source Dependencies --------------------------------------------------
source("R/clean_taxonomy.R")

# Load required libraries
library(dplyr)
library(readr)
library(purrr)
library(stringr)

# 2. Setup Paths and Find Files --------------------------------------------
raw_dir <- "data/raw/CWR of the USA occurrences by genus 2020_7_30"
output_dir <- "data/processed"

if (!dir.exists(raw_dir)) {
  stop(paste("Raw occurrences directory not found at:", raw_dir))
}

# Find all CSV files in the raw occurrences directory
csv_files <- list.files(path = raw_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(csv_files) == 0) {
  stop(paste("No CSV files found in directory:", raw_dir))
}

message(paste("Found", length(csv_files), "genus occurrence CSV files to process."))

# 3. Define Column Specification -------------------------------------------
# Using explicit col_types ensures R doesn't guess differing types across files
col_spec <- readr::cols(
  .default = readr::col_character(), # Default to character for safety
  V1 = readr::col_integer(),
  latitude = readr::col_double(),
  longitude = readr::col_double()
)

# 4. Read and Combine Genus Files ------------------------------------------
message("Reading and combining occurrences (this may take a moment)...")

# Read each CSV, adding a cleaned_taxon column, and bind them together
combined_occurrences <- csv_files %>%
  purrr::map_df(function(file_path) {
    # Extract genus name from the file name for diagnostic/metadata purposes
    genus_name <- stringr::str_match(basename(file_path), "^([A-Za-z]+)")[, 2]
    
    # Read the CSV file
    df <- readr::read_csv(
      file_path,
      col_types = col_spec,
      show_col_types = FALSE,
      progress = FALSE
    )
    
    # Remove the first unnamed/index column if it exists
    if ("...1" %in% colnames(df)) {
      df <- df %>% dplyr::select(-`...1`)
    }
    
    # Standardize and add taxonomy/metadata
    df <- df %>%
      dplyr::mutate(
        source_file_genus = genus_name,
        # Standardize the scientific name for seamless joining later
        cleaned_taxon = clean_taxonomy(taxon)
      )
    
    return(df)
  })

message("Finished combining all occurrence data.")

# 5. Generate Diagnostic Summary -------------------------------------------
message("\n--- Occurrences Diagnostic Summary ---")
message(paste("Total Occurrence Records:", nrow(combined_occurrences)))
message(paste("Unique Standardized Taxa:", length(unique(combined_occurrences$cleaned_taxon))))
message(paste("Unique Genera:", length(unique(combined_occurrences$genus))))

# Show top 10 genera by occurrence count
message("\nTop 10 Genera by Occurrence Count:")
top_genera <- combined_occurrences %>%
  dplyr::count(genus, sort = TRUE) %>%
  dplyr::slice_head(n = 10)

for (i in 1:nrow(top_genera)) {
  message(paste0("  - ", top_genera$genus[i], ": ", top_genera$n[i], " occurrences"))
}
message("--------------------------------------\n")

# 6. Export Consolidated Data ----------------------------------------------
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

rds_output_path <- file.path(output_dir, "cwr_occurrences.rds")
readr::write_rds(combined_occurrences, rds_output_path, compress = "gz")
message(paste("Successfully compiled occurrences saved as RDS to:", rds_output_path))
