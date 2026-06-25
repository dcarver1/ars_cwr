# scripts/process_nps_plant_list.R
# This script consolidates the 8 CSV plant list files in data/processed/ltra_plantList/
# into a single standardized dataset and exports it as an RDS file.

# 1. Source Dependencies --------------------------------------------------
source("R/clean_taxonomy.R")

# Load required libraries
library(dplyr)
library(readr)
library(purrr)
library(stringr)

# 2. Setup Paths and Find Files --------------------------------------------
raw_dir <- "data/processed/ltra_plantList"
output_dir <- "data/processed"

if (!dir.exists(raw_dir)) {
  stop(paste("NPS plant list directory not found at:", raw_dir))
}

# Find all CSV files
csv_files <- list.files(path = raw_dir, pattern = "\\.csv$", full.names = TRUE)

if (length(csv_files) == 0) {
  stop(paste("No CSV files found in directory:", raw_dir))
}

message(paste("Found", length(csv_files), "NPS/LTAR plant list CSV files to process."))

# 3. Define Scientific Name Extractor --------------------------------------
# An intelligent parser that handles the diverse column layouts of the plant list CSVs
extract_scientific_name <- function(df) {
  cols <- tolower(colnames(df))
  
  # A. Look for standard 'scientific name' keys
  match_idx <- which(cols %in% c("scientific name", "scientific_name", "scientificname"))
  if (length(match_idx) > 0) {
    return(df[[match_idx[1]]])
  }
  
  # B. Look for 'scientific' key
  match_idx <- which(cols == "scientific")
  if (length(match_idx) > 0) {
    return(df[[match_idx[1]]])
  }
  
  # C. Look for 'taxon' key
  match_idx <- which(cols == "taxon")
  if (length(match_idx) > 0) {
    return(df[[match_idx[1]]])
  }
  
  # D. Combine Genus and Species/Specific columns if separate
  genus_idx <- which(grepl("^genus", cols))
  species_idx <- which(cols == "species" | cols == "specific")
  
  if (length(genus_idx) > 0 && length(species_idx) > 0) {
    genus_vals <- stringr::str_trim(as.character(df[[genus_idx[1]]]))
    species_vals <- stringr::str_trim(as.character(df[[species_idx[1]]]))
    names <- paste(genus_vals, species_vals)
    
    # Check for subspecies and variety columns to reconstruct the trinomial name
    subspecies_idx <- which(cols == "subspecies")
    variety_idx <- which(cols == "variety")
    
    if (length(subspecies_idx) > 0) {
      subsp_vals <- as.character(df[[subspecies_idx[1]]])
      valid_subsp <- !is.na(subsp_vals) & subsp_vals != "" & subsp_vals != "NA"
      names[valid_subsp] <- paste(names[valid_subsp], "subsp.", subsp_vals[valid_subsp])
    }
    
    if (length(variety_idx) > 0) {
      var_vals <- as.character(df[[variety_idx[1]]])
      valid_var <- !is.na(var_vals) & var_vals != "" & var_vals != "NA"
      names[valid_var] <- paste(names[valid_var], "var.", var_vals[valid_var])
    }
    
    return(names)
  }
  
  # Return NA if no suitable column found
  return(rep(NA_character_, nrow(df)))
}

# 4. Read and Combine Plant Lists ------------------------------------------
message("Reading and standardizing plant lists...")

combined_plant_list <- csv_files %>%
  purrr::map_df(function(file_path) {
    # Extract site name from file name
    site_name <- stringr::str_trim(stringr::str_replace(basename(file_path), "\\.csv$", ""))
    
    # Read CSV
    df <- readr::read_csv(
      file_path,
      col_types = readr::cols(.default = readr::col_character()), # Safe character read
      show_col_types = FALSE,
      progress = FALSE
    )
    
    # Extract full scientific name
    raw_names <- extract_scientific_name(df)
    
    # Clean and standardize names
    df_clean <- tibble::tibble(
      site = site_name,
      raw_scientific_name = raw_names,
      cleaned_taxon = clean_taxonomy(raw_names)
    ) %>%
      dplyr::filter(!is.na(raw_scientific_name) & raw_scientific_name != "")
    
    return(df_clean)
  })

message("Finished combining all plant list records.")

# 5. Generate Diagnostic Summary -------------------------------------------
message("\n--- Plant List Diagnostic Summary ---")
message(paste("Total Species Records across Sites:", nrow(combined_plant_list)))
message(paste("Unique Standardized Species Count:", length(unique(combined_plant_list$cleaned_taxon))))
message("-------------------------------------\n")

# 6. Export Consolidated Plant List ----------------------------------------
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}

rds_output_path <- file.path(output_dir, "nps_plant_list.rds")
readr::write_rds(combined_plant_list, rds_output_path)
message(paste("Consolidated plant list saved as RDS to:", rds_output_path))

csv_output_path <- file.path(output_dir, "nps_plant_list.csv")
readr::write_csv(combined_plant_list, csv_output_path)
message(paste("Consolidated plant list saved as CSV to:", csv_output_path))
