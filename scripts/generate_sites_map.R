# scripts/generate_sites_map.R
# This script reads USDA LTRA (LTAR) geometries and National Park Service (NPS) 
# boundaries from web-accessible REST APIs, integrates species richness statistics 
# from both processed LTRA plant lists and fetched NPS species inventories, and 
# generates a rich interactive Leaflet map separating sites with data from reference ones.

# 1. Load Required Libraries -----------------------------------------------
message("Loading mapping and taxonomy libraries...")
library(sf)
library(leaflet)
library(htmlwidgets)
library(dplyr)
library(readr)
library(stringr)

# Source taxonomical helpers
source("R/clean_taxonomy.R")
source("R/join_index.R")

# 2. File Path and URL Configuration -----------------------------------------
ltar_bndy_path <- "data/raw/LTAR_Standard_GIS_Layers_v2020_GeoJSON_ADC/LTAR_Standard_GIS_Layers_v2020_GeoJSON/ltar_legacy_site_bndy_a.geojson"
nps_species_path <- "data/processed/nps_species_core.rds"
cwr_index_path <- "data/processed/cwr_index.rds"
ltar_classified_path <- "data/processed/classified_nps_plant_list.rds"

# Authoritative NPS Land Resources Division boundary service REST endpoint
nps_rest_url <- "https://services1.arcgis.com/fBc8EJBxQRMcHlei/arcgis/rest/services/NPS_Land_Resources_Division_Boundary_and_Tract_Data_Service/FeatureServer/2/query?where=1%3D1&outFields=*&outSR=4326&f=geojson"

# 3. Load Datasets ---------------------------------------------------------
message("Ingesting local and online GIS datasets...")

# A. Read local USDA LTAR geometries
if (!file.exists(ltar_bndy_path)) {
  stop(paste("LTAR boundaries GeoJSON not found at:", ltar_bndy_path))
}
ltar_bndy <- sf::read_sf(ltar_bndy_path)
message(paste("Loaded", nrow(ltar_bndy), "USDA LTAR legacy boundary polygons."))

# B. Read local processed species plant list
if (!file.exists(ltar_classified_path)) {
  stop(paste("Classified LTRA plant list RDS not found. Run pipeline first. Missing:", ltar_classified_path))
}
ltar_plants <- readr::read_rds(ltar_classified_path)
message(paste("Loaded", nrow(ltar_plants), "taxonomically classified LTRA species records."))

# C. Read local fetched NPS species core data
if (!file.exists(nps_species_path)) {
  stop(paste("NPS species core RDS not found. Run scripts/01_fetch_data.R first. Missing:", nps_species_path))
}
nps_core <- readr::read_rds(nps_species_path)
message(paste("Loaded", nrow(nps_core), "raw NPS species inventories across multiple parks."))

# D. Read local CWR index
if (!file.exists(cwr_index_path)) {
  stop(paste("CWR index RDS not found. Missing:", cwr_index_path))
}
cwr_index <- readr::read_rds(cwr_index_path)
message("Loaded Crop-Wild Relative (CWR) taxonomic index.")

# E. Fetch online NPS unit boundaries with local caching
nps_bndy_cache_path <- "data/processed/nps_boundaries_cache.geojson"
if (file.exists(nps_bndy_cache_path)) {
  message("Loading National Park Service boundary polygons from local cache...")
  nps_bndy <- sf::read_sf(nps_bndy_cache_path)
} else {
  message("Downloading 437 National Park Service boundary polygons from ArcGIS REST service...")
  nps_bndy <- sf::read_sf(nps_rest_url)
  message("Caching National Park Service boundary polygons locally...")
  sf::write_sf(nps_bndy, nps_bndy_cache_path)
}
message(paste("Successfully loaded and parsed", nrow(nps_bndy), "NPS unit boundaries."))

# 4. Standardize and Classify NPS Species Data -----------------------------
message("Cleaning and classifying NPS species lists with CWR index...")

# Standardize names and perform classification join
nps_core$cleaned_taxon <- clean_taxonomy(nps_core$ScientificName)
nps_classified <- join_index(nps_core, cwr_index)

# 5. Species Data Aggregation by Research Area -----------------------------
message("Aggregating species richness statistics...")

# A. USDA LTRA Sites
# Mapping table connecting processed plant list files to spatial boundaries Site_ID
ltar_id_map <- c(
  "Archbold Buck Island Ranch Plant List 1.15.2020" = "ABS-UF",
  "CPER_plants" = "CPER",
  "Great Basin long-term monitoring sites species-list 2018" = "GB",
  "Great Basin RCEW plant species list 2015" = "GB",
  "Jornada LTAR PlantList-JER_web" = "JER",
  "NGPRL_Mandan_2015 Inventory" = "NP",
  "SouthernPlainsPlantList Jan 2020" = "SP",
  "Walnut Gulch Herbarium, 6.2018" = "WGEW"
)

ltar_stats <- ltar_plants %>%
  dplyr::mutate(Site_ID = ltar_id_map[site]) %>%
  dplyr::filter(!is.na(Site_ID)) %>%
  dplyr::group_by(Site_ID) %>%
  dplyr::summarize(
    total_species = dplyr::n_distinct(cleaned_taxon),
    cwr_species   = dplyr::n_distinct(cleaned_taxon[Type == "CWR" & !is.na(Type)]),
    wus_species   = dplyr::n_distinct(cleaned_taxon[Type == "WUS" & !is.na(Type)]),
    .groups = "drop"
  )

# B. National Park Service Sites (filtering for scientifically verified present/probably present species)
nps_stats <- nps_classified %>%
  dplyr::filter(Occurrence %in% c("Present", "Probably Present")) %>%
  dplyr::group_by(ParkCode) %>%
  dplyr::summarize(
    total_species = dplyr::n_distinct(cleaned_taxon),
    cwr_species   = dplyr::n_distinct(cleaned_taxon[Type == "CWR" & !is.na(Type)]),
    wus_species   = dplyr::n_distinct(cleaned_taxon[Type == "WUS" & !is.na(Type)]),
    .groups = "drop"
  )

# 6. Integrate Spatial Boundaries with Statistics --------------------------
message("Aligning spatial datasets with study statistics...")

# Ensure coordinates are in WGS84 (EPSG:4326) for Leaflet compatibility
ltar_bndy <- sf::st_transform(ltar_bndy, crs = 4326)
nps_bndy  <- sf::st_transform(nps_bndy, crs = 4326)

# Separate LTAR boundaries into sites with active data vs reference-only sites
ltar_with_data <- ltar_bndy %>%
  dplyr::inner_join(ltar_stats, by = "Site_ID")

ltar_ref <- ltar_bndy %>%
  dplyr::anti_join(ltar_stats, by = "Site_ID")

# Separate NPS boundaries based on ParkCode (matching UNIT_CODE)
nps_with_data <- nps_bndy %>%
  dplyr::inner_join(nps_stats, by = c("UNIT_CODE" = "ParkCode"))

nps_ref <- nps_bndy %>%
  dplyr::anti_join(nps_stats, by = c("UNIT_CODE" = "ParkCode"))

message(paste("Joined study data to", nrow(ltar_with_data), "LTAR polygon boundaries."))
message(paste("Joined study data to", nrow(nps_with_data), "NPS unit boundaries."))
message(paste("Separated", nrow(ltar_ref), "LTAR reference and", nrow(nps_ref), "NPS reference boundary polygons."))

# 7. Build Interactive Leaflet Map -----------------------------------------
message("Assembling the interactive dual-layer map...")

# Setup color palettes
# LTAR: Yellow-Orange-Red palette
ltar_palette <- leaflet::colorNumeric(
  palette = "YlOrRd",
  domain = ltar_with_data$cwr_species
)

# NPS: Yellow-Green-Blue (YlGnBu) palette to visually differentiate from LTAR sites
nps_palette <- leaflet::colorNumeric(
  palette = "YlGnBu",
  domain = nps_with_data$cwr_species
)

# Construct rich HTML popups for LTAR sites with data
ltar_popups <- paste0(
  "<div style='font-family: sans-serif; min-width: 250px;'>",
  "<h3 style='margin: 0 0 5px 0; color: #1E4620; border-bottom: 2px solid #1E4620; padding-bottom: 3px;'>", 
  ltar_with_data$Site_Name, " (", ltar_with_data$Site_ID, ")</h3>",
  "<b>State:</b> ", ltar_with_data$State, "<br/>",
  "<b>City/Location:</b> ", ltar_with_data$City, "<br/>",
  "<b>Established:</b> ", ltar_with_data$Year_Estab, "<br/>",
  "<div style='margin-top: 8px; background: #f7f7f7; padding: 8px; border-radius: 4px; border: 1px solid #e0e0e0;'>",
  "<b style='color: #444;'>Taxonomic Summary:</b><br/>",
  "• Total Unique Species: <b>", ltar_with_data$total_species, "</b><br/>",
  "• Crop-Wild Relatives (CWR): <span style='color: #d73027;'><b>", ltar_with_data$cwr_species, "</b></span><br/>",
  "• Wild Utilized Species (WUS): <span style='color: #4575b4;'><b>", ltar_with_data$wus_species, "</b></span>",
  "</div>",
  "</div>"
)

# Construct popups for LTAR reference-only sites
ltar_ref_popups <- paste0(
  "<div style='font-family: sans-serif; min-width: 250px;'>",
  "<h3 style='margin: 0 0 5px 0; color: #555; border-bottom: 2px solid #999; padding-bottom: 3px;'>", 
  ltar_ref$Site_Name, " (", ltar_ref$Site_ID, ")</h3>",
  "<b>State:</b> ", ltar_ref$State, "<br/>",
  "<b>City/Location:</b> ", ltar_ref$City, "<br/>",
  "<b>Established:</b> ", ltar_ref$Year_Estab, "<br/>",
  "<hr style='margin: 8px 0; border: 0; border-top: 1px solid #ddd;'/>",
  "<span style='color: #666; font-style: italic;'>No species list dataset was processed for this site in the current study.</span>",
  "</div>"
)

# Construct rich HTML popups for NPS sites with data
nps_popups <- paste0(
  "<div style='font-family: sans-serif; min-width: 250px;'>",
  "<h3 style='margin: 0 0 5px 0; color: #1f4e79; border-bottom: 2px solid #1f4e79; padding-bottom: 3px;'>", 
  nps_with_data$UNIT_NAME, " (", nps_with_data$UNIT_CODE, ")</h3>",
  "<b>Unit Type:</b> ", nps_with_data$UNIT_TYPE, "<br/>",
  "<b>State(s):</b> ", nps_with_data$STATE, "<br/>",
  "<div style='margin-top: 8px; background: #f0f4f8; padding: 8px; border-radius: 4px; border: 1px solid #d0dce5;'>",
  "<b style='color: #444;'>Taxonomic Summary (Vascular Plants):</b><br/>",
  "• Total Unique Species: <b>", nps_with_data$total_species, "</b><br/>",
  "• Crop-Wild Relatives (CWR): <span style='color: #1f78b4;'><b>", nps_with_data$cwr_species, "</b></span><br/>",
  "• Wild Utilized Species (WUS): <span style='color: #33a02c;'><b>", nps_with_data$wus_species, "</b></span>",
  "</div>",
  "<hr style='margin: 8px 0; border: 0; border-top: 1px solid #ddd;'/>",
  "<a href='https://www.nps.gov/", tolower(nps_with_data$UNIT_CODE), "/index.htm' target='_blank' ",
  "style='background: #1f4e79; color: white; padding: 4px 8px; text-decoration: none; border-radius: 3px; font-size: 11px; display: inline-block;'>",
  "Visit NPS Website</a>",
  "</div>"
)

# Construct popups for NPS reference-only sites
nps_ref_popups <- paste0(
  "<div style='font-family: sans-serif; min-width: 220px;'>",
  "<h3 style='margin: 0 0 5px 0; color: #555; border-bottom: 2px solid #999; padding-bottom: 3px;'>", 
  nps_ref$UNIT_NAME, " (", nps_ref$UNIT_CODE, ")</h3>",
  "<b>Unit Type:</b> ", nps_ref$UNIT_TYPE, "<br/>",
  "<b>State(s):</b> ", nps_ref$STATE, "<br/>",
  "<hr style='margin: 8px 0; border: 0; border-top: 1px solid #ddd;'/>",
  "<span style='color: #666; font-style: italic;'>No species list dataset was processed for this unit in the current study.</span>",
  "<br/><br/>",
  "<a href='https://www.nps.gov/", tolower(nps_ref$UNIT_CODE), "/index.htm' target='_blank' ",
  "style='background: #555; color: white; padding: 4px 8px; text-decoration: none; border-radius: 3px; font-size: 11px; display: inline-block;'>",
  "Visit NPS Website</a>",
  "</div>"
)

# Render Leaflet Map
map <- leaflet::leaflet() %>%
  # Base Maps
  leaflet::addProviderTiles(leaflet::providers$Esri.WorldTopoMap, group = "Topographic Map") %>%
  leaflet::addProviderTiles(leaflet::providers$Esri.WorldImagery, group = "Satellite Imagery") %>%
  leaflet::addTiles(group = "OpenStreetMap") %>%
  
  # A. NPS Parks without study data (Reference Layer)
  leaflet::addPolygons(
    data = nps_ref,
    fillColor = "#95a5a6",
    fillOpacity = 0.1,
    weight = 1.0,
    color = "#7f8c8d",
    opacity = 0.35,
    dashArray = "3, 3",
    popup = nps_ref_popups,
    label = ~paste0(UNIT_NAME, " (", UNIT_CODE, ") [No Data]"),
    group = "NPS Parks (Reference)"
  ) %>%
  
  # B. NPS Parks with active study data
  leaflet::addPolygons(
    data = nps_with_data,
    fillColor = ~nps_palette(cwr_species),
    fillOpacity = 0.70,
    weight = 1.8,
    color = "#1f4e79",
    opacity = 0.85,
    popup = nps_popups,
    label = ~paste0(UNIT_NAME, " (", UNIT_CODE, ") - CWR Species: ", cwr_species),
    group = "NPS Parks (With Species Data)"
  ) %>%
  
  # C. USDA LTAR Sites without study data (Reference Layer)
  leaflet::addPolygons(
    data = ltar_ref,
    fillColor = "#7f8c8d",
    fillOpacity = 0.12,
    weight = 1.2,
    color = "#7f8c8d",
    opacity = 0.45,
    dashArray = "4, 4",
    popup = ltar_ref_popups,
    label = ~paste0(Site_Name, " (", Site_ID, ") [No Data]"),
    group = "USDA LTRA (Reference)"
  ) %>%
  
  # D. USDA LTAR Sites with active study data
  leaflet::addPolygons(
    data = ltar_with_data,
    fillColor = ~ltar_palette(cwr_species),
    fillOpacity = 0.75,
    weight = 2,
    color = "#2c3e50",
    opacity = 0.9,
    popup = ltar_popups,
    label = ~paste0(Site_Name, " (", Site_ID, ") - CWR Species: ", cwr_species),
    group = "USDA LTRA (With Species Data)"
  ) %>%
  
  # Legend for LTAR CWR Species Richness
  leaflet::addLegend(
    data = ltar_with_data,
    pal = ltar_palette,
    values = ~cwr_species,
    title = "LTRA CWR Richness",
    position = "bottomright",
    opacity = 0.8,
    group = "USDA LTRA (With Species Data)"
  ) %>%
  
  # Legend for NPS CWR Species Richness
  leaflet::addLegend(
    data = nps_with_data,
    pal = nps_palette,
    values = ~cwr_species,
    title = "NPS CWR Richness",
    position = "bottomleft",
    opacity = 0.8,
    group = "NPS Parks (With Species Data)"
  ) %>%
  
  # Interactive Map controls
  leaflet::addLayersControl(
    baseGroups = c("Topographic Map", "Satellite Imagery", "OpenStreetMap"),
    overlayGroups = c(
      "USDA LTRA (With Species Data)", 
      "USDA LTRA (Reference)", 
      "NPS Parks (With Species Data)",
      "NPS Parks (Reference)"
    ),
    options = leaflet::layersControlOptions(collapsed = FALSE)
  )

# 8. Export Interactive HTML Map -------------------------------------------
output_map_path <- "data/processed/research_sites_map.html"
message(paste("Saving updated interactive map to:", output_map_path))
htmlwidgets::saveWidget(map, output_map_path, selfcontained = TRUE)

message("\nMap generation completed successfully!")
message(paste("You can open and view the interactive map directly in your browser at:", normalizePath(output_map_path)))
