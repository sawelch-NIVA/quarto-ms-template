# # manuscript/tables/tbl-01-example.R ----
# Builds tbl-01-example. Standalone file so it's easy to open and tinker
# with directly, and so this table's own styling packages don't have to be
# loaded by every target in the pipeline. Sourced automatically by
# _targets.R's tar_source("manuscript/tables") call; wired in as the
# tbl_01_example target there, which passes in whatever upstream targets
# this needs explicitly (here just `model`) so targets' static dependency
# scanner can still see the edge - that scanner only reads _targets.R's own
# command expressions, not code inside a sourced file, so a bare
# source()-and-return pattern would silently lose dependency tracking.
library(flextable)

build_tbl_01_example <- function(model) {
  flextable(
    tibble::tibble(term = names(model), estimate = round(model, 3))
  ) |>
    theme_vanilla() |>
    flextable::bold(part = "header") |>
    autofit()
}
