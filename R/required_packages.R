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
  "rlang", # used by geom_sf_shadowtext() (R/functions.R)
  "cli", # used by geom_sf_shadowtext() (R/functions.R)
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
  # Used by supplementary/maps-mre.qmd - drop if you delete that notebook.
  # sf + ggplot2's geom_sf() draw the maps; rnaturalearth(data) and
  # giscoR/eurostat supply boundaries as sf objects directly (no manual
  # shapefile download); ggspatial adds north-arrow/scale-bar annotations
  # geom_sf() has no native equivalent for; terra/tidyterra handle raster
  # layers (e.g. bathymetry) alongside sf vector layers; classInt supplies
  # proper choropleth breaks (Jenks/quantile) instead of raw continuous
  # scales; shadowtext is used via geom_sf_shadowtext() (R/functions.R) for
  # legible labels over complex map backgrounds. mregions2 and marmap are
  # marine-specific: IHO Sea Areas/EEZ boundaries and NOAA bathymetry
  # grids respectively - neither has a general-purpose land-map
  # equivalent, both are this project's actual domain (marine work).
  #
  # rnaturalearthhires: back in this list as of the "Putting it together"
  # Norway map template in maps-mre.qmd - confirmed by direct testing that
  # section is the first thing in this notebook to actually need
  # scale = "large" (ne_countries(country = "Norway", scale = "medium")
  # silently drops Bouvet Island from its returned multipolygon; only
  # "large" keeps it - see the notebook for the full comparison table).
  # rnaturalearthhires isn't on CRAN at all (only rnaturalearthdata is;
  # it's ~76MB of high-res shapefiles, distributed via ropensci's
  # r-universe instead, specifically because of that size) - listing it
  # here alone is NOT sufficient for CI: plain install.packages()-style
  # CRAN listing can't reach an off-CRAN package regardless of what's in
  # this vector. The matching fix is on the CI workflow's setup-r@v2 step
  # (extra-repositories: https://ropensci.r-universe.dev), not here - see
  # .github/workflows/render.yml. Previously deliberately excluded for
  # exactly this reason, before any notebook needed scale = "large" -
  # that gap was invisible locally because it was already installed on
  # the dev machine for unrelated reasons, the same root cause as the
  # tidygraph/NetSwan incident below.
  "sf",
  "rnaturalearth",
  "rnaturalearthdata",
  "rnaturalearthhires",
  "giscoR",
  "eurostat",
  "ggspatial",
  "terra",
  "tidyterra",
  "classInt",
  "shadowtext",
  "ggrepel",
  "mregions2",
  "marmap",
  # Used by tests/testthat/ - see manuscript/supplementary/testing-mre.qmd.
  "testthat",
  "withr"
)
