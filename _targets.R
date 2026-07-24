# Created by use_targets().
# See https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

library(targets)
library(tarchetypes) # tar_quarto() and friends
library(here) # anchors paths to the project root regardless of invocation cwd

# Anchors here()'s root independent of .git/.Rproj auto-detection - matters
# if this template is ever unzipped rather than git-cloned.
here::i_am("_targets.R")

tar_option_set(
  packages = c("tibble"), # packages targets need for their tasks
  format = "qs" # fast default storage format
)

tar_source()
# manuscript/tables/ and manuscript/figures/ hold one .R file per
# table/figure (its build_*() function) plus a matching _*.qmd include
# partial - keeps construction code and package loads out of this file.
# tar_source() only picks up *.R, so the .qmd partials are ignored here.
suppressMessages(
  {
    tar_source("manuscript/tables")
    tar_source("manuscript/figures")
  }
)
# Target names are verbs (every target is an action, not just its output noun).
list(
  # example_data_file tracks data/example-data.rds by content hash
  # (format = "file") so import_data reruns when the file changes, even
  # though targets can't see inside readRDS()'s external file access on
  # its own - same idiom export_tables/export_figures use below. The rds
  # itself comes from data-raw/import-data.R, a one-time script run
  # manually (see data-raw/data-raw-readme.md), not part of this pipeline -
  # a fresh clone's runme.R generates it before the first tar_make().
  tar_target(
    name = example_data_file,
    command = here("data/example-data.rds"),
    format = "file"
  ),
  tar_target(
    name = import_data,
    command = readRDS(example_data_file)
  ),
  tar_target(
    name = calculate_model,
    command = coefficients(lm(measurement ~ group, data = import_data))
  ),
  # One target per table/figure, calling out to its own file
  # (tables/tbl-01-example.R, figures/fig-01-example.R). Upstream targets
  # are passed in explicitly as arguments - targets' dependency scanner
  # only reads _targets.R's own command expressions, so a dependency used
  # only inside the sourced file wouldn't be tracked.
  # R names use underscores (tbl_01_example); the journal-required filename
  # (tbl-01-example.docx) uses hyphens - related, not the same string.
  tar_target(
    name = tbl_01_example,
    command = build_tbl_01_example(calculate_model)
  ),
  tar_target(
    name = fig_01_example,
    command = build_fig_01_example(import_data, calculate_model)
  ),
  # Standalone submission exports - separate targets from render_manuscript
  # below, not chunks inside it: export_figures writes TIFFs, and a TIFF
  # anywhere in the tar_quarto() render would take html/docx down with it
  # if typst chokes on it (see CLAUDE.md). Written to submission/, NOT
  # output/ - Quarto's website render deletes anything under output-dir it
  # doesn't recognize as its own (confirmed: a subdirectory and a stray
  # file were both silently wiped by a plain `quarto render` here).
  # Add a matching export target whenever a new tbl/fig target is added above.
  tar_target(
    name = export_tables,
    command = export_table_docx(
      tbl_01_example,
      "tbl-01-example",
      dir = here("submission")
    ),
    format = "file"
  ),
  tar_target(
    name = export_figures,
    command = export_figure_tiff(
      fig_01_example,
      "fig-01-example",
      dir = here("submission")
    ),
    format = "file"
  ),
  # Renders the whole Quarto project at manuscript/ (manuscript.qmd,
  # supplementary/*.qmd, ...) - see manuscript/_quarto.yml. tarchetypes
  # scans each .qmd for tar_read()/tar_load() calls and wires up matching
  # target dependencies automatically - confirmed this also follows
  # {{< include >}}'d partials, so render_manuscript correctly depends on
  # tbl_01_example/fig_01_example even though they're only referenced
  # inside those partials, not manuscript.qmd itself.
  tar_quarto(
    name = render_manuscript,
    path = "manuscript",
    execute = TRUE, # keep this unless you know you've just changed text, not code,
    quiet = TRUE # set to true to get better logs if anything fails
  )
)
