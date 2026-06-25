# Project Plan

## 1. Scope
**Define the project boundaries**

The primary objective of this repository is to build an automated, reproducible data pipeline that extracts species data from the National Park Service, standardizes it, and aligns it with an external taxonomic index.

### In-Scope:
* Querying the NPS "Units" web service to retrieve a comprehensive list of park codes.
* Iterating through park codes to query the NPSpecies REST API for species lists.
* Developing text-cleaning functions to standardize scientific names returned by the API.
* Implementing a joining mechanism to cross-reference the standardized NPS species against the crop-wild relative index.
* Aggregating the final data to produce a count of crop-wild species present within each national park.
* Developing unit and integration tests for API calls and data manipulation.

### Out-of-Scope:
* Spatial analysis or geospatial mapping of the results.
* Downstream statistical modeling of species distribution.
* Manual data entry or manual taxonomic corrections outside of automated rules.
---

## 2. Tasks
**Break the work into steps**

This phase translates the scope into a chronological series of development tasks. In alignment with the structured workflow, each task should have associated checks or tests developed alongside the code to validate quality at each pass.

### Task 2.1: Establish API Infrastructure and Helper Functions
* **Implementation:** Write the core functions responsible for executing HTTP GET requests against the `irmaservices.nps.gov/v3/rest/` endpoints. This includes setting up rate-limiting to be a good citizen on the NPS servers and configuring error handling.
* **Operational Note:** The NPS API defaults to returning XML. You will need to explicitly configure your requests to request JSON (or CSV) for easier parsing into tabular data structures.
* **Testing:** Develop tests using mocked API responses. This ensures your error-handling logic correctly catches HTTP errors (such as a 404 when a species list has zero records) without needing to hit the live server repeatedly.

### Task 2.2: Retrieve Park Units
* **Implementation:** Build a module that queries the Units service and extracts a clean vector of park codes (e.g., 'YOSE', 'ROMO').
* **Testing:** Implement a check to verify that the returned object is a character vector, contains expected known park codes, and contains no missing values.

### Task 2.3: Retrieve Species Lists
* **Implementation:** Create the iteration logic to loop over the retrieved park codes and query the NPSpecies service. Based on the email details provided, you will need to select the appropriate endpoint. The example URL provided (`.../detaillist/YOSE/11`) points to the "Full List with Details" endpoint, filtered by a specific category code ('11'). You will need to decide if limiting the request to specific taxonomic categories is necessary for your crop-wild relative workflow.
* **Testing:** Write tests to validate the schema of the returned data. Ensure that the required columns (scientific name, presence status, etc.) exist in the resulting tabular format before proceeding to the next park code.

### Task 2.4: Taxonomic Standardization
* **Implementation:** Develop string manipulation routines to normalize the scientific names. This step is critical for a successful join and typically involves converting to a standard case, removing author citations, standardizing subspecies/variety abbreviations (e.g., "var.", "ssp."), and stripping whitespace.
* **Testing:** Populate unit tests with known edge cases of messy taxonomic names (e.g., hyphenated names, symbols, trailing spaces) to ensure the cleaning logic consistently outputs the expected standard string.

### Task 2.5: Index Alignment
* **Implementation:** Ingest the crop-wild relative taxonomic index. Perform the join between the standardized NPS data and the index.
* **Testing:** Develop data integrity checks that flag and quantify unmatched species. This will provide a diagnostic report on the effectiveness of the taxonomic standardization and highlight any discrepancies that may require fuzzy matching logic.

### Task 2.6: Aggregation and Export
* **Implementation:** Group the matched data by the park code unit and calculate the total counts of crop-wild relative species per park. Export the final dataset.
* **Testing:** Implement a final validation step to ensure that the number of unique park codes in the final export matches the number of park codes evaluated, ensuring no spatial units were lost during the joins.
