# scripts/03_aggregate.R
# Task 2.6: Aggregation and Export
# This script groups the classified occurrence data by various dimensions
# (State, Database Source, and Genus) to generate rich summary statistics
# of Crop-Wild Relative (CWR) and Wild Utilized Species (WUS) distributions.

# 1. Source Dependencies --------------------------------------------------
source("R/aggregate_data.R")

# Load required libraries
library(dplyr)
library(readr)
library(stringr)

# Paths
input_path <- "data/processed/classified_occurrences.rds"
output_dir <- "data/processed"

message("Loading classified occurrence data...")

# 2. Ingest Classified Occurrences -----------------------------------------
if (!file.exists(input_path)) {
  stop(paste("Classified occurrences dataset not found. Please run scripts/02_process_and_join.R first. Missing:", input_path))
}

classified_df <- readr::read_rds(input_path)
message(paste("Loaded", nrow(classified_df), "classified occurrence records."))

# 3. Spatial Parsing: Extract State ---------------------------------------
message("Parsing State identifiers from localityInformation...")

# Sanitize character encoding in localityInformation to avoid UTF-8 errors in stringr/stringi
classified_df <- classified_df %>%
  dplyr::mutate(localityInformation = iconv(localityInformation, to = "UTF-8", sub = ""))

# Extracting the state from patterns like 'USA -- State Name -- ...' or 'United States -- State Name -- ...'
# We use stringr::str_split to safely find the second token, falling back to 'Unknown/External' if not in standard format
classified_df <- classified_df %>%
  dplyr::mutate(
    parts = stringr::str_split(localityInformation, " -- "),
    State = sapply(parts, function(x) {
      if (length(x) >= 2 && nzchar(x[2])) {
        # Normalize to Title Case
        return(stringr::str_to_title(stringr::str_trim(x[2])))
      } else {
        return("Unknown/External")
      }
    })
  ) %>%
  dplyr::select(-parts) # Clean up temporary column

# 4. Perform Aggregations --------------------------------------------------
message("Aggregating CWR and WUS metrics across various dimensions...")

# A. Aggregate by State
state_summary <- aggregate_data(classified_df, group_col = "State")

# B. Aggregate by Genus
genus_summary <- aggregate_data(classified_df, group_col = "genus")

# C. Aggregate by Database Source
source_summary <- aggregate_data(classified_df, group_col = "databaseSource")

# 5. Generate Diagnostic Reports -------------------------------------------
message("\n=== TOP 10 STATES BY UNIQUE CWR SPECIES ===")
top_cwr_states <- state_summary %>%
  dplyr::filter(State != "Unknown/External") %>%
  dplyr::arrange(dplyr::desc(unique_cwr_species)) %>%
  dplyr::slice_head(n = 10)

for (i in 1:nrow(top_cwr_states)) {
  message(paste0(i, ". ", top_cwr_states$State[i], ": ", top_cwr_states$unique_cwr_species[i], " CWR species (", top_cwr_states$cwr_occurrences[i], " occurrences)"))
}

message("\n=== TOP 10 GENERA BY UNIQUE CWR SPECIES ===")
top_cwr_genera <- genus_summary %>%
  dplyr::arrange(dplyr::desc(unique_cwr_species)) %>%
  dplyr::slice_head(n = 10)

for (i in 1:nrow(top_cwr_genera)) {
  message(paste0(i, ". ", top_cwr_genera$genus[i], ": ", top_cwr_genera$unique_cwr_species[i], " CWR species (", top_cwr_genera$cwr_occurrences[i], " occurrences)"))
}
message("===========================================\n")

# 6. Export Aggregated Datasets --------------------------------------------
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

# Export State Summary
readr::write_csv(state_summary, file.path(output_dir, "aggregated_by_state.csv"))
readr::write_rds(state_summary, file.path(output_dir, "aggregated_by_state.rds"), compress = "gz")
message("Exported State-level aggregation to csv and rds.")

# Export Genus Summary
readr::write_csv(genus_summary, file.path(output_dir, "aggregated_by_genus.csv"))
message("Exported Genus-level aggregation to csv.")

# Export Source Summary
readr::write_csv(source_summary, file.path(output_dir, "aggregated_by_source.csv"))
message("Exported Database Source aggregation to csv.")

message("\nAggregation and Export phase completed successfully!")
