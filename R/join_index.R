#' Join Species with Index
#' 
#' Merges standardized NPS data with the CWR index.
#' 
#' @param nps_data Data frame of NPS species.
#' @param cwr_index Data frame of the CWR index.
#' @return A joined data frame.
join_index <- function(nps_data, cwr_index) {
  if (is.null(nps_data) || is.null(cwr_index)) {
    stop("Input datasets cannot be NULL.")
  }
  
  if (!("cleaned_taxon" %in% colnames(nps_data))) {
    stop("nps_data must contain a 'cleaned_taxon' column.")
  }
  
  if (!("cleaned_taxon" %in% colnames(cwr_index))) {
    stop("cwr_index must contain a 'cleaned_taxon' column.")
  }
  
  # Perform a left join to align occurrence data with taxonomic index
  joined_df <- nps_data %>%
    dplyr::left_join(
      cwr_index,
      by = "cleaned_taxon",
      suffix = c("", "_index")
    )
  
  # Advanced Binomial Fallback:
  # For records that failed to match on the full trinomial (subspecies/variety),
  # we fall back to matching on the binomial species name ("genus species").
  unmatched_indices <- which(is.na(joined_df$Type))
  
  if (length(unmatched_indices) > 0) {
    # Extract binomial keys (first 2 words) of the unmatched plant list records
    binomial_keys <- sapply(joined_df$cleaned_taxon[unmatched_indices], function(name) {
      if (is.na(name)) return(NA_character_)
      words <- stringr::str_split(name, " ")[[1]]
      if (length(words) >= 2) {
        return(paste(words[1], words[2]))
      } else {
        return(name)
      }
    }, USE.NAMES = FALSE)
    
    # Create a deduplicated binomial lookup table from the CWR index
    index_binomial <- cwr_index %>%
      dplyr::filter(!is.na(cleaned_taxon)) %>%
      dplyr::mutate(
        binomial_key = sapply(cleaned_taxon, function(name) {
          words <- stringr::str_split(name, " ")[[1]]
          return(paste(words[1], words[2]))
        }, USE.NAMES = FALSE)
      ) %>%
      dplyr::distinct(binomial_key, .keep_all = TRUE)
    
    # Find matching rows in the index
    match_indices <- match(binomial_keys, index_binomial$binomial_key)
    valid_matches <- !is.na(match_indices)
    
    if (any(valid_matches)) {
      # Columns to copy from index
      cols_to_copy <- setdiff(intersect(colnames(cwr_index), colnames(joined_df)), "cleaned_taxon")
      
      for (col in cols_to_copy) {
        joined_df[[col]][unmatched_indices[valid_matches]] <- index_binomial[[col]][match_indices[valid_matches]]
      }
    }
  }
  
  return(joined_df)
}
