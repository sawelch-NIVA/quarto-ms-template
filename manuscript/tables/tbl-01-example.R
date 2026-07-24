# manuscript/tables/tbl-01-example.R ----
# Builds tbl-01-example. Standalone so it's easy to tinker with directly,
# and so this table's styling packages aren't loaded by every pipeline
# target. Sourced by _targets.R's tar_source("manuscript/tables"); wired in
# as the tbl_01_example target there, which passes upstream targets in
# explicitly (here just `model`) so targets' dependency scanner can see the
# edge - it only reads _targets.R's own command expressions, not code
# inside a sourced file.
library(flextable)

build_tbl_01_example <- function(model) {
  flextable(
    tibble::tibble(term = names(model), estimate = round(model, 3))
  ) |>
    theme_vanilla() |>
    flextable::bold(part = "header") |>
    autofit()
}
