# ARS Crop-Wild Relative (CWR) NPS Pipeline

This repository contains an automated data pipeline to extract, standardize, and analyze species data from the National Park Service (NPS) to identify crop-wild relatives.

## Overview

The project follows the plan outlined in `plan.md`, focusing on:
1.  **Extraction:** Retrieving park units and species lists via the NPS REST API.
2.  **Standardization:** Cleaning taxonomic names for consistent matching.
3.  **Alignment:** Joining NPS data with a Crop-Wild Relative taxonomic index.
4.  **Aggregation:** Reporting counts of CWR species per national park.

## Project Structure

- `R/`: Modular functions for each task in the pipeline.
- `scripts/`: Top-level scripts to execute the data pipeline.
- `data/`: Raw and processed data storage (ignored by git).
- `tests/`: Unit and integration tests using `testthat`.

## Getting Started

1. Open `ars_cwr.Rproj` in RStudio.
2. Ensure required packages are installed (`httr2`, `jsonlite`, `dplyr`, `stringr`, `testthat`).
3. Run scripts in `scripts/` in sequence.
