#' Clean Taxonomic Names
#' 
#' Normalizes scientific names for matching.
#' 
#' @param names A vector of scientific names.
#' @return A vector of standardized names.
clean_taxonomy <- function(names) {
  if (is.null(names)) return(NULL)
  
  # Convert to character vector and handle encoding errors
  names_char <- as.character(names)
  names_char <- iconv(names_char, to = "UTF-8", sub = "")
  
  # Clean each name individually using standard botanical nomenclature rules
  cleaned <- sapply(names_char, function(name) {
    if (is.na(name) || name == "") return(NA_character_)
    
    # Trim and collapse multiple spaces
    name <- stringr::str_trim(name)
    name <- stringr::str_replace_all(name, "\\s+", " ")
    
    # Split into words
    words <- stringr::str_split(name, " ")[[1]]
    if (length(words) == 0) return("")
    
    # Keep the Genus (first word)
    genus <- words[1]
    
    # Keep the Species (second word) if it exists
    if (length(words) < 2) return(tolower(genus))
    species <- words[2]
    
    result_words <- c(genus, species)
    
    # If we have 3 or more words, parse for ranks and infraspecific epithets
    if (length(words) >= 3) {
      for (i in 3:length(words)) {
        w <- words[i]
        
        # Skip rank abbreviations
        if (tolower(w) %in% c("subsp", "subsp.", "ssp", "ssp.", "var", "var.", "f", "f.", "forma", "subvar", "subvar.")) {
          next
        }
        
        # Stop at the start of author citation (capitalized word, parentheses, ex, &, and)
        if (grepl("[\\(\\)]", w) || grepl("^[A-Z]", w) || w %in% c("ex", "&", "and")) {
          break
        }
        
        # Keep lowercase infraspecific epithet
        if (grepl("^[a-z]", w)) {
          result_words <- c(result_words, w)
        }
      }
    }
    
    # Convert result to lowercase and collapse
    return(tolower(paste(result_words, collapse = " ")))
  }, USE.NAMES = FALSE)
  
  return(cleaned)
}
