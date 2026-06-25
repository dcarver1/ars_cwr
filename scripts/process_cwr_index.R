# scripts/process_cwr_index.R
# This script processes the raw Crop-Wild Relative (CWR) Excel sheet
# into a standardized, usable taxonomic index for the study.

# 1. Source Dependencies --------------------------------------------------
source("R/clean_taxonomy.R")

# Load required libraries
library(readxl)
library(dplyr)
library(stringr)
library(readr)

message("Loading raw CWR taxonomy from Excel...")

# Path to the raw Excel file
excel_path <- "data/raw/pnas.2007029117.sd01.xlsx"

# Check if the file exists
if (!file.exists(excel_path)) {
  stop(paste("Raw Excel file not found at:", excel_path))
}

# 2. Read and Parse Table S1 -----------------------------------------------
# Read sheet 'Table S1' which contains the taxonomic record
raw_index <- readxl::read_excel(excel_path, sheet = "Table S1")

message(paste("Loaded", nrow(raw_index), "rows from sheet Table S1."))

# 3. Clean and Standardize -------------------------------------------------
message("Processing and standardizing taxonomic columns...")

processed_index <- raw_index %>%
  # Rename column 13 (Type...13) to Type for easier access
  dplyr::rename(Type = `Type...13`) %>%
  # Select the key taxonomic and relational columns
  dplyr::select(
    Taxon,
    Family,
    Genus,
    species,
    `rank 1`,
    `infraspecific 1`,
    `Taxon 2019 final without ranks`,
    CWR_WUS_common_name,
    Type,
    Associated_crop_taxon,
    `Crop or WUS use_very general`,
    `Crop or WUS use_general`
  ) %>%
  # Standardize taxonomic names using clean_taxonomy()
  dplyr::mutate(
    cleaned_taxon = clean_taxonomy(Taxon),
    cleaned_taxon_no_rank = clean_taxonomy(`Taxon 2019 final without ranks`)
  ) %>%
  # Deduplicate by cleaned_taxon to prevent many-to-many join duplication
  dplyr::distinct(cleaned_taxon, .keep_all = TRUE)

# 4. Generate Diagnostic Summary -------------------------------------------
message("\n--- Index Diagnostic Summary ---")
message(paste("Total Records:", nrow(processed_index)))
message(paste("Unique Taxa:", length(unique(processed_index$cleaned_taxon))))
message(paste("CWR Count:", sum(processed_index$Type == "CWR", na.rm = TRUE)))
message(paste("WUS Count:", sum(processed_index$Type == "WUS", na.rm = TRUE)))
message("---------------------------------\n")

# 5. Export Processed Data -------------------------------------------------
output_dir <- "data/processed"
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Save as RDS for R pipeline integration
rds_output_path <- file.path(output_dir, "cwr_index.rds")
readr::write_rds(processed_index, rds_output_path)
message(paste("Processed index saved as RDS to:", rds_output_path))

# Save as CSV for general use/review
csv_output_path <- file.path(output_dir, "cwr_index.csv")
readr::write_csv(processed_index, csv_output_path)
message(paste("Processed index saved as CSV to:", csv_output_path))
