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

**Wired into `_targets.R`:** `example_data_file` tracks
`data/example-data.rds` by content (`format = "file"`), `import_data`
reads it, and `calculate_model` fits `lm(measurement ~ group, data =
import_data)` - the actual example table/figure in the manuscript come
from this raw file, not synthetic data. `runme.R` runs
`data-raw/import-data.R` on first setup if `data/example-data.rds` doesn't
exist yet; re-run it by hand (`source("data-raw/import-data.R")`) after
editing the raw csv, since it isn't part of `_targets.R` itself.
