#' Safe GET Request Wrapper for IRMA Services
#'
#' @param endpoint String appending the specific API path.
#' @param query_params Optional list of query parameters.
#' @return A parsed JSON object (list/dataframe) or NULL if failed.
irma_get_request <- function(endpoint, query_params = list()) {
  base_url <- "https://irmaservices.nps.gov"
  
  req <- httr2::request(base_url) |> 
    httr2::req_url_path(endpoint) |> 
    httr2::req_user_agent("CSU Geospatial Centroid Data Pipeline (contact: dcarver1)") |> 
    httr2::req_headers(Accept = "application/json")
  
  if (length(query_params) > 0) {
    req <- req |> httr2::req_url_query(!!!query_params)
  }
  
  # Inject robustness: retry up to 3 times if server hiccups, space requests by 0.5s
  resp <- req |> 
    httr2::req_retry(max_tries = 3) |> 
    httr2::req_throttle(rate = 2 / 1) |> # Max 2 requests per second
    httr2::req_error(is_error = function(resp) FALSE) |> # Handle errors manually below
    httr2::req_perform()
  
  # Handle HTTP status codes
  status <- httr2::resp_status(resp)
  if (status == 200) {
    return(httr2::resp_body_json(resp, simplifyVector = TRUE))
  } else {
    warning(paste("API request failed for endpoint:", endpoint, "with Status:", status))
    return(NULL)
  }
}
