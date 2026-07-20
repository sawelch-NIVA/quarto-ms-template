# data-raw/import-data.R ----
# Example of the pattern described in data-raw/README.md. Not sourced by
# the pipeline automatically — the point is to move this logic into a
# function in R/ and call it from a tar_target(), not to run this script
# by hand each time.

library(here)
here::i_am("data-raw/import-data.R")

raw <- read.csv(here("data-raw", "survey-responses.csv"))

# clean_survey_data() would live in R/functions.R
# clean <- clean_survey_data(raw)
# write.csv(clean, "data/survey-responses-clean.csv", row.names = FALSE)
