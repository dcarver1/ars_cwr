# scripts/plot_species_summary.R
# This script generates a beautiful, publication-quality bar plot showing
# the total unique species identified in the NPS/LTAR Plant List dataset, along with
# the breakdown of those matched to Crop-Wild Relatives (CWR) and Wild Utilized Species (WUS).

# 1. Load Required Libraries -----------------------------------------------
library(ggplot2)
library(dplyr)
library(readr)

# Paths
input_path <- "data/processed/classified_nps_plant_list.rds"
output_plot_path <- "data/processed/species_summary_plot.png"

message("Loading classified NPS plant list data...")

# 2. Ingest Classified Plant Lists -----------------------------------------
if (!file.exists(input_path)) {
  stop(paste("Classified plant lists dataset not found. Please run scripts/02_process_and_join.R first. Missing:", input_path))
}

classified_df <- readr::read_rds(input_path)

# 3. Calculate Unique Species Counts ---------------------------------------
message("Calculating unique species metrics...")

total_unique <- length(unique(classified_df$cleaned_taxon))
cwr_unique <- length(unique(classified_df$cleaned_taxon[which(classified_df$Type == "CWR")]))
wus_unique <- length(unique(classified_df$cleaned_taxon[which(classified_df$Type == "WUS")]))
unmatched_unique <- length(unique(classified_df$cleaned_taxon[is.na(classified_df$Type)]))

# Create a clean data frame for plotting
plot_data <- tibble::tibble(
  Category = c(
    "Total Unique Species", 
    "Crop-Wild Relatives (CWR)", 
    "Wild Utilized Species (WUS)",
    "Unmatched Species"
  ),
  Count = c(total_unique, cwr_unique, wus_unique, unmatched_unique),
  Type = c("Total", "CWR", "WUS", "Unmatched")
)

# Reorder Category levels to ensure logical plotting order
plot_data$Category <- factor(plot_data$Category, levels = plot_data$Category)

# 4. Generate the Plot -----------------------------------------------------
message("Generating the species summary plot...")

# Professional botanical palette
colors <- c(
  "Total" = "#1E4620",      # Dark Green
  "CWR" = "#438A5E",        # Sage Green
  "WUS" = "#D97B24",        # Warm Orange
  "Unmatched" = "#A63F3F"   # Soft Red
)

p <- ggplot(plot_data, aes(x = Category, y = Count, fill = Type)) +
  # Add geom_col with custom width
  geom_col(width = 0.55, show.legend = FALSE) +
  # Use custom colors
  scale_fill_manual(values = colors) +
  # Add value labels above the bars
  geom_text(
    aes(label = Count),
    vjust = -0.5,
    size = 4.8,
    fontface = "bold",
    color = "#333333"
  ) +
  # Clean minimal theme with adjustments
  theme_minimal(base_size = 14) +
  theme(
    plot.title = element_text(face = "bold", size = 18, hjust = 0.5, color = "#1E4620"),
    plot.subtitle = element_text(size = 12, hjust = 0.5, color = "#555555", margin = margin(b = 20)),
    axis.title.x = element_blank(),
    axis.title.y = element_text(face = "bold", size = 12, margin = margin(r = 10)),
    axis.text.x = element_text(face = "bold", size = 11, color = "#333333"),
    panel.grid.major.x = element_blank(), # Remove vertical gridlines
    panel.grid.minor = element_blank(),
    panel.grid.major.y = element_line(color = "#E5E5E5"), # Light horizontal gridlines
    plot.margin = margin(20, 20, 20, 20)
  ) +
  # Labels and scales
  labs(
    title = "NPS Plant List taxonomic Summary",
    subtitle = "Consolidated LTAR plant list datasets joined with CWR Index",
    y = "Number of Unique Species"
  ) +
  # Adjust y-limit slightly to give space for labels on top of bars
  scale_y_continuous(limits = c(0, max(plot_data$Count) * 1.1))

# 5. Export Plot -----------------------------------------------------------
message(paste("Saving plot to:", output_plot_path))
ggplot2::ggsave(
  filename = output_plot_path,
  plot = p,
  width = 8.5,
  height = 6.2,
  dpi = 300,
  bg = "white"
)

message("Species summary plot generated and saved successfully!")
