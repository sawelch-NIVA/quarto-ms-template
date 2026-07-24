# data-raw/

Raw, as-received data and the scripts that clean it, tracked in git (unlike
`data/`, which holds the cleaned output and is git-ignored — see "Directory
layout" in the repo root's README.md/CLAUDE.md). Mirrors the
`usethis::use_data_raw()` R-package convention.

- **`example-data.csv`** — a 6-row synthetic placeholder standing in for a
  real as-received data file. Replace with your own raw data.
- **`import-data.R`** — reads `example-data.csv`, does minimal cleaning
  (factor levels on `group`), and writes the result to
  `data/example-data.rds`. Run manually (`source("data-raw/import-data.R")`)
  whenever the raw file changes; it is a one-time script, not part of
  `_targets.R` — raw input doesn't change on every pipeline run the way
  computed targets do.
- The resulting `example_data` object is documented in
  [`R/data.R`](../R/data.R), the same way an R package documents a bundled
  dataset (roxygen block + bare quoted object name). Keep that
  documentation in sync with `import-data.R` if the columns ever change.

**Not currently wired into `_targets.R`:** the pipeline's `simulate_data`
target generates synthetic data inline (`rnorm()`) rather than reading
`data/example-data.rds`. This example shows the raw-data pattern this
template expects you to follow; when you have real data, either point
`simulate_data` (or a new target) at `tar_read()`-able output from this
folder, or add a target that calls `readRDS(here("data/example-data.rds"))`
directly.
