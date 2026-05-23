#' Fetch Full Detailed Species List for a Specific Park
#'
#' @param park_code A 4-letter character string (e.g., "YOSE").
#' @param category An optional category string. Defaults to "11" (Vascular Plants).
#' @return A data frame containing raw species details, or NULL if empty.
get_species_lists <- function(park_code, category = "11") {
  if (missing(park_code) || is.null(park_code) || park_code == "") return(NULL)
  
  clean_code <- stringr::str_to_upper(stringr::str_trim(park_code))
  
  # Paths must prefix the app directory precisely as provided in the email sample
  endpoint <- paste0("/NPSpecies/v3/rest/detaillist/", clean_code, "/", category)
  
  payload <- irma_get_request(endpoint)
  
  if (!is.null(payload) && is.data.frame(payload) && nrow(payload) > 0) {
    payload <- payload |> dplyr::mutate(ParkCode = clean_code)
    return(payload)
  }
  
  return(NULL)
}
