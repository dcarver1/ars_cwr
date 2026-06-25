library(testthat)
library(dplyr)
source("../../R/join_index.R")

test_that("join_index merges data frames correctly", {
  # Mock datasets
  nps_mock <- tibble(
    taxon = c("Acer saccharum", "Citrus depressa", "Unknown taxon"),
    cleaned_taxon = c("acer saccharum", "citrus depressa", "unknown taxon"),
    latitude = c(45.1, 28.1, NA)
  )
  
  cwr_mock <- tibble(
    Taxon = c("Acer saccharum", "Citrus depressa"),
    cleaned_taxon = c("acer saccharum", "citrus depressa"),
    Type = c("WUS", "CWR"),
    Family = c("Sapindaceae", "Rutaceae")
  )
  
  # Perform join
  result <- join_index(nps_mock, cwr_mock)
  
  # Expectations
  expect_equal(nrow(result), 3)
  expect_equal(result$Type, c("WUS", "CWR", NA))
  expect_equal(result$Family, c("Sapindaceae", "Rutaceae", NA))
})

test_that("join_index throws error on missing cleaned_taxon column", {
  nps_bad <- tibble(taxon = "Acer")
  cwr_mock <- tibble(cleaned_taxon = "acer")
  
  expect_error(join_index(nps_bad, cwr_mock))
  expect_error(join_index(cwr_mock, nps_bad))
})
