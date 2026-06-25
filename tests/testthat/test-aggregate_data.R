library(testthat)
library(dplyr)
source("../../R/aggregate_data.R")

test_that("aggregate_data summarizes dataset correctly", {
  # Mock joined dataset
  joined_mock <- tibble(
    cleaned_taxon = c("acer saccharum", "acer saccharum", "citrus depressa", "citrus depressa", "unknown"),
    Type = c("WUS", "WUS", "CWR", "CWR", NA),
    State = c("Illinois", "Wisconsin", "Illinois", "Florida", "Illinois")
  )
  
  # Aggregate by State
  summary_state <- aggregate_data(joined_mock, group_col = "State")
  
  # Expectations by State
  expect_equal(nrow(summary_state), 3) # Illinois, Wisconsin, Florida
  
  illinois_stats <- summary_state %>% filter(State == "Illinois")
  expect_equal(illinois_stats$total_occurrences, 3)
  expect_equal(illinois_stats$cwr_occurrences, 1)
  expect_equal(illinois_stats$wus_occurrences, 1)
  expect_equal(illinois_stats$unique_cwr_species, 1)
  expect_equal(illinois_stats$unique_wus_species, 1)
  
  # Aggregate by Type (with custom grouping)
  # (though Type is already in mock, let's just make sure it supports any column name)
  summary_custom <- aggregate_data(joined_mock, group_col = "cleaned_taxon")
  expect_equal(nrow(summary_custom), 3) # acer saccharum, citrus depressa, unknown
})

test_that("aggregate_data throws error on missing grouping column", {
  joined_mock <- tibble(taxon = "Acer", Type = "CWR")
  expect_error(aggregate_data(joined_mock, group_col = "NonexistentColumn"))
})
