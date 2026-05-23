#' Retrieve Active NPS Park Unit Codes
#'
#' @return A character vector of 4-letter park unit codes.
get_park_units <- function() {
  endpoint <- "/unit/v2/api/unitselector"
  
  payload <- irma_get_request(endpoint)
  
  # Validate using the exact uppercase "Unit" as returned by the API
  if (is.null(payload) || !("Unit" %in% names(payload)) || !("Code" %in% names(payload$Unit))) {
    warning("Could not read unit codes from IRMA unitselector payload.")
    return(character(0))
  }
  
  # Extract the codes from the nested Unit data frame
  park_codes <- payload$Unit$Code |> 
    as.character() |> 
    stringr::str_trim() |> 
    stringr::str_to_upper()
  
  # Filter out empty strings and return unique values
  park_codes <- unique(park_codes[park_codes != ""])
  
  return(park_codes)
}
