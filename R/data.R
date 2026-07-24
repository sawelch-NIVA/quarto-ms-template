# R/data.R ----
# Documents the object data-raw/import-data.R produces, in the same style
# an R package documents a bundled dataset (roxygen block + bare quoted
# name) - see data-raw/README.md for how the two files relate. This file
# has no side effects, so tar_source() sourcing it on every pipeline load
# is harmless.

#' Example measurements (data-raw/example-data.csv)
#'
#' A tiny synthetic dataset standing in for real as-received data, cleaned
#' by data-raw/import-data.R and saved to data/example-data.rds. Replace
#' with a real dataset and update this block when adapting the template.
#'
#' @format A data frame with 6 rows and 3 columns:
#' \describe{
#'   \item{id}{integer. Row identifier.}
#'   \item{group}{factor. Example group label, levels "control"/"treatment".}
#'   \item{measurement}{double. Example measured value.}
#' }
#' @source Synthetic; generated for this template, not real data.
"example_data"
