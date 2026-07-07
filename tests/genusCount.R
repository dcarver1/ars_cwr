pacman::p_load(readr, dplyr)
data <- read_csv("data/raw/cwr_taxonomyPNAS2020.csv")

d1 <- data |>
  dplyr::select(Genus)|>
  dplyr::distinct()
write_csv(d1, file = "data/temp/genus_list.csv")
