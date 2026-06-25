#' Aggregate CWR Counts
#' 
#' Groups matched data by park code and calculates counts.
#' 
#' @param joined_data Data frame from the join step.
#' @return A summary data frame with park counts.
aggregate_data <- function(joined_data, group_col = "State") {
  if (is.null(joined_data)) {
    stop("Input data cannot be NULL.")
  }
  
  if (!(group_col %in% colnames(joined_data))) {
    stop(paste("Grouping column", group_col, "not found in joined_data."))
  }
  
  # Group by the specified column and calculate rich summary statistics
  summary_df <- joined_data %>%
    dplyr::group_by(dplyr::across(dplyr::all_of(group_col))) %>%
    dplyr::summarise(
      total_occurrences = dplyr::n(),
      cwr_occurrences = sum(Type == "CWR", na.rm = TRUE),
      wus_occurrences = sum(Type == "WUS", na.rm = TRUE),
      # Count unique species for CWR and WUS
      unique_cwr_species = dplyr::n_distinct(cleaned_taxon[Type == "CWR"], na.rm = TRUE),
      unique_wus_species = dplyr::n_distinct(cleaned_taxon[Type == "WUS"], na.rm = TRUE),
      .groups = "drop"
    ) %>%
    # Order by total occurrences descending
    dplyr::arrange(dplyr::desc(total_occurrences))
  
  return(summary_df)
}
