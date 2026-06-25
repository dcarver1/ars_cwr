# scripts/02_process_and_join.R
# Task 2.4 & 2.5: Taxonomic Standardization and Index Alignment
# This script joins our compiled NPS plant lists with the processed
# CWR taxonomic index to classify each species record as CWR or WUS.

# 1. Source Dependencies --------------------------------------------------
source("R/join_index.R")

# Load required libraries
library(dplyr)
library(readr)

# Paths to the processed data files
plant_list_path <- "data/processed/nps_plant_list.rds"
index_path <- "data/processed/cwr_index.rds"

message("Loading compiled NPS plant lists and taxonomic index...")

# 2. Load Input Datasets ---------------------------------------------------
if (!file.exists(plant_list_path)) {
  stop(paste("Compiled plant lists not found. Please run scripts/process_nps_plant_list.R first. Missing:", plant_list_path))
}

if (!file.exists(index_path)) {
  stop(paste("Taxonomic index not found. Please run scripts/process_cwr_index.R first. Missing:", index_path))
}

plant_list_df <- readr::read_rds(plant_list_path)
index_df <- readr::read_rds(index_path)

message(paste("Loaded", nrow(plant_list_df), "plant list records."))
message(paste("Loaded", nrow(index_df), "taxonomic index records."))

# 3. Perform Join and Classification ----------------------------------------
message("Performing taxonomic index alignment (joining plant list with index)...")

classified_df <- join_index(plant_list_df, index_df)

# 4. Generate Classification Diagnostic Report -----------------------------
total_records <- nrow(classified_df)

cwr_records <- sum(classified_df$Type == "CWR", na.rm = TRUE)
wus_records <- sum(classified_df$Type == "WUS", na.rm = TRUE)
unmatched_records <- sum(is.na(classified_df$Type))

cwr_pct <- (cwr_records / total_records) * 100
wus_pct <- (wus_records / total_records) * 100
unmatched_pct <- (unmatched_records / total_records) * 100

message("\n--- Plant List Classification Report ---")
message(paste("Total Plant List Records:    ", total_records))
message(paste0("Crop-Wild Relative (CWR):    ", cwr_records, " (", round(cwr_pct, 2), "%)"))
message(paste0("Wild Utilized Species (WUS): ", wus_records, " (", round(wus_pct, 2), "%)"))
message(paste0("Unmatched / Unclassified:    ", unmatched_records, " (", round(unmatched_pct, 2), "%)"))
message("----------------------------------------\n")

# Report on top unmatched species to highlight potential spelling variations
if (unmatched_records > 0) {
  message("Top Unmatched Species (Candidates for Fuzzy Matching/Review):")
  unmatched_summary <- classified_df %>%
    dplyr::filter(is.na(Type)) %>%
    dplyr::count(raw_scientific_name, sort = TRUE)
  
  for (i in 1:nrow(unmatched_summary)) {
    message(paste0("  - ", unmatched_summary$raw_scientific_name[i], ": ", unmatched_summary$n[i], " occurrences"))
  }
  message("----------------------------------------\n")
}

# 5. Export Classified Dataset ----------------------------------------------
output_path <- "data/processed/classified_nps_plant_list.rds"
readr::write_rds(classified_df, output_path, compress = "gz")
message(paste("Successfully exported classified plant lists to:", output_path))
