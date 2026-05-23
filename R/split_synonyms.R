#' Split Raw Species Data into Core and Synonym Relational Tables with Park Context
#'
#' @param raw_df The combined data frame containing a nested synonym list-column.
#' @return A list containing two flat data frames: 'core' and 'synonyms'.
split_synonyms <- function(raw_df) {
  
  # Check if the expected column exists before attempting to split
  if (!"Synonyms" %in% names(raw_df)) {
    warning("No 'Synonyms' column found. Returning raw data as core.")
    return(list(core = raw_df, synonyms = data.frame()))
  }
  
  # 1. Build the Synonym Lookup Table
  # Added 'ParkCode' to the select statement to retain regional context 
  # for individual synonym records.
  synonym_lookup <- raw_df |>
    dplyr::select(ParkCode, TaxaCode, Synonyms) |>
    dplyr::filter(purrr::map_lgl(Synonyms, is.data.frame)) |>
    tidyr::unnest(cols = c(Synonyms), names_sep = "_") |>
    dplyr::distinct()
  
  # 2. Build the Flat Core Table
  # Drop the nested list-column so the resulting dataframe is standard 2D tabular data
  species_core <- raw_df |>
    dplyr::select(-Synonyms)
  
  return(list(
    core = species_core,
    synonyms = synonym_lookup
  ))
}