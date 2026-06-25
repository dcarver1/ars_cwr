library(testthat)
library(stringr)
source("../../R/clean_taxonomy.R")

test_that("clean_taxonomy standardizes names", {
  expect_equal(clean_taxonomy("Genus species var. variety"), "genus species variety")
  expect_equal(clean_taxonomy("Acer saccharum subsp. floridanum"), "acer saccharum floridanum")
  expect_equal(clean_taxonomy("  Acer  saccharum  "), "acer saccharum")
  expect_equal(clean_taxonomy("Genus species ssp. subspecies"), "genus species subspecies")
  expect_equal(clean_taxonomy("Genus species f. rosea"), "genus species rosea")
  expect_equal(clean_taxonomy("Helianthus annuus L."), "helianthus annuus")
})
