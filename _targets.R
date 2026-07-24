# Created by use_targets().
# Follow the comments below to fill in this target script.
# Then follow the manual to check and run the pipeline:
#   https://books.ropensci.org/targets/walkthrough.html#inspect-the-pipeline

# # Load packages required to define the pipeline:
library(targets)
library(tarchetypes) # tar_quarto() and friends
library(here) # anchors file paths to the project root regardless of where
# tar_make()/quarto render/knit is actually invoked from

# # Establishes the project root here() resolves to, independent of relying on
# .git/.Rproj auto-detection - matters if this template is ever unzipped
# rather than git-cloned.
here::i_am("_targets.R")

# Set target options:
tar_option_set(
  packages = c("tibble"), # Packages that your targets need for their tasks.
  format = "qs" # Optionally set the default storage format. qs is fast.
)

# # Source scripts in ~/R with custom functions:
tar_source()
# manuscript/tables/ and manuscript/figures/ hold one .R file per
# table/figure (the build_*() function) plus a matching _*.qmd include
# partial (see manuscript/manuscript.qmd) - keeps each table/figure's
# construction code and package loads out of this file and out of every
# other target's hands. tar_source() only picks up *.R, so it ignores the
# .qmd partials living alongside them.
suppressMessages(
  {
    tar_source("manuscript/tables")
    tar_source("manuscript/figures")
  }
)
# Replace the target list below with your own:
# Target names are verbs describing the action each target performs - every
# target is an action, not just the noun it produces (personal preference).
list(
  tar_target(
    name = simulate_data,
    command = tibble(x = rnorm(100), y = rnorm(100))
  ),
  tar_target(
    name = calculate_model,
    command = coefficients(lm(y ~ x, data = simulate_data))
  ),
  # One target per table/figure, each just calling out to its own file
  # (tables/tbl-01-example.R, figures/fig-01-example.R). Upstream targets
  # (calculate_model, simulate_data) are passed in explicitly as arguments
  # here, not referenced inside the sourced file - targets' dependency
  # scanner only reads the command expression written in _targets.R, so a
  # dependency used only inside the sourced file wouldn't be tracked.
  # R object names use underscores (tbl_01_example); the journal's required
  # filename (tbl-01-example.docx) uses hyphens - the two are related but
  # not literally the same string anywhere in this pipeline.
  tar_target(
    name = tbl_01_example,
    command = build_tbl_01_example(calculate_model)
  ),
  tar_target(
    name = fig_01_example,
    command = build_fig_01_example(simulate_data, calculate_model)
  ),
  # # Standalone submission exports — deliberately separate targets from
  # render_site below, not chunks inside it: export_figures writes TIFFs,
  # and a TIFF anywhere in the tar_quarto() render would take html/docx down
  # with it if typst choked on it (see CLAUDE.md). Keeping export a sibling
  # target means that risk never touches the manuscript render at all.
  # Written to submission/, NOT output/ - confirmed by direct testing that
  # Quarto's website-project render deletes anything under output-dir it
  # doesn't recognize as its own output (a whole subdirectory and an
  # unrelated stray file both got silently wiped by a plain `quarto render`
  # in this repo). output/ is Quarto's territory; submission/ isn't.
  # One export target per table/figure - add a matching line here whenever
  # a new tbl_NN_slug/fig_NN_slug target is added above.
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
  # # Renders the whole Quarto project rooted at manuscript/ (manuscript.qmd,
  # supplementary/*.qmd, ...) - a self-contained Quarto sub-project, see
  # manuscript/_quarto.yml. tarchetypes scans each .qmd for tar_read()/
  # tar_load() calls and wires up the matching target dependencies
  # automatically - confirmed this scan also follows {{< include >}}'d
  # partials (manuscript/tables/_tbl-01-example.qmd,
  # manuscript/figures/_fig-01-example.qmd), not just the top-level .qmd,
  # so render_manuscript correctly depends on tbl_01_example/fig_01_example too.
  tar_quarto(
    name = render_manuscript,
    path = "manuscript",
    execute = TRUE, # keep this unless you know you've just changed text, not code,
    quiet = TRUE # set to true to get better logs if anything fails
  )
)
