# data-raw/

Mirrors the usual R-package convention (`usethis::use_data_raw()`):
this folder holds raw, as-received data plus the scripts that clean it,
and is tracked in git (aside from anything large/sensitive — see the
root `.gitignore`).

`data/` is the opposite: it's regenerated output (the pipeline's
processed/derived data), git-ignored, and gets rebuilt by
`targets::tar_make()`. Don't hand-edit anything in `data/`.

Typical flow:

1. Drop the raw file(s) here, e.g. `data-raw/survey-responses.csv`.
2. Write an import/cleaning script here, e.g. `data-raw/import-data.R`
   (see the example in this folder).
3. Wire that logic into a function in `R/` and call it from a
   `tar_target()` in `_targets.R`, so cleaning happens as a reproducible
   pipeline step rather than a one-off script you ran once and forgot
   about.
