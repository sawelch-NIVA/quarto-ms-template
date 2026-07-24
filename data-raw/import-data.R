# data-raw/import-data.R ----
# One-time import/cleaning script, following the usethis::use_data_raw()
# convention: raw input lives in data-raw/ (tracked in git), the
# cleaned/processed result is written to data/ (git-ignored, regenerated
# from here rather than the pipeline - see data-raw/README.md). Run
# manually when the raw file changes; not sourced by tar_source() or
# wired into _targets.R, since raw input doesn't change on every pipeline
# run the way computed targets do.
library(tibble)
library(here)

here::i_am("data-raw/import-data.R")

example_data <- read.csv(here("data-raw/example-data.csv"))
example_data$group <- factor(example_data$group, levels = c("control", "treatment"))
example_data <- as_tibble(example_data)

# See R/data.R for this object's roxygen documentation - keep the two in
# sync if columns here ever change.

dir.create(here("data"), showWarnings = FALSE)
saveRDS(example_data, here("data/example-data.rds"))
