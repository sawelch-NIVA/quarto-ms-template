# R/required_packages.R ----
# Single source of truth for this project's R package dependencies -
# sourced by both runme.R (local bootstrap, installs only what's missing)
# and .github/workflows/render.yml (CI, which computes this list at
# runtime and feeds it to r-lib/actions/setup-r-dependencies rather than
# hardcoding a second copy - see the workflow's own comment for why it
# uses that action instead of plain install.packages(): it also resolves
# and installs the Ubuntu system libraries these packages need via pak's
# sysreqs database, which install.packages() alone does not).
#
# Keep this a plain vector with no side effects - it needs to be
# `source()`-able by CI before any package (including this project's own
# helpers) is installed.
required_pkgs <- c(
  "targets", # pipeline
  "tarchetypes", # tar_quarto() and friends
  "quarto", # render + project helpers
  "tibble", # used by the example target — swap/extend as needed
  "here", # anchors file paths to the project root everywhere
  "jsonlite", # used by detect_render_format() (R/functions.R)
  # Used by supplementary/tables-mre.qmd - drop if you delete that notebook.
  "kableExtra",
  "gt",
  "flextable",
  "huxtable",
  "DT",
  # Used by supplementary/images-mre.qmd and generate-images.R - drop if
  # you delete that notebook. Mermaid needs no extra R package (Quarto
  # handles it), but docx SVG embedding also needs a system `rsvg-convert`
  # (librsvg) on PATH - see the notebook for details.
  "ggplot2",
  "magick",
  "svglite",
  # Used by supplementary/plots-mre.qmd - drop if you delete that notebook.
  "ggtext",
  "patchwork",
  # Used by supplementary/fonts-mre.qmd and generate-fonts.R - drop if you
  # delete that notebook. systemfonts/ragg is the recommended combo;
  # showtext/sysfonts and extrafont are also loaded there for direct
  # comparison (extrafont specifically to demonstrate why it's a poor fit
  # here - see the notebook).
  "systemfonts",
  "ragg",
  "showtext",
  "sysfonts",
  "extrafont",
  # Also used by supplementary/fonts-mre.qmd - its Emoji section
  # specifically. emojifont is used once, deliberately, to demonstrate a
  # real failure (its emoji-name registry doesn't match the `emoji`
  # package's) - not a working example.
  "emoji",
  "emojifont",
  # Used by supplementary/diagrams-mre.qmd - drop if you delete that
  # notebook. cetz (typst-native drawing) needs no R package - it's a raw
  # `{=typst}` block. The knitr `dot` engine needs a system Graphviz `dot`
  # binary, not an R package - see the notebook for the PATH-resolution
  # gotcha found while testing that.
  "ggraph",
  "tidygraph",
  "DiagrammeR",
  # Used by supplementary/colour-mre.qmd - drop if you delete that
  # notebook. RColorBrewer/viridis/colorspace/scales are already pulled in
  # by other notebooks above; scico, MetBrewer, and paletteer are new
  # here.
  "scico",
  "MetBrewer",
  "paletteer",
  # Used by tests/testthat/ - see manuscript/supplementary/testing-mre.qmd.
  "testthat",
  "withr"
)
