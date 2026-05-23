#' Retrieve Active NPS Park Unit Codes
#'
#' @return A character vector of 4-letter park unit codes.
get_park_units <- function() {
  # Querying the v2 Unit service REST endpoint
  endpoint <- "/v2/rest/unit"
  
  payload <- irma_get_request(endpoint)
  
  if (is.null(payload) || !("Code" %in% names(payload))) {
    warning("Could not read unit codes from IRMA payload.")
    return(character(0))
  }
  
  # Extract, filter out empty values, convert to uppercase, and take unique entries
  park_codes <- payload$Code |> 
    as.character() |> 
    stringr::str_trim() |> 
    stringr::str_to_upper()
  
  park_codes <- unique(park_codes[park_codes != ""])
  
  return(park_codes)
}
