# R/functions.R ----
# Custom functions used by the targets pipeline (_targets.R) or in Quarto files.
# Split into multiple files here as the project grows
# (e.g. R/read_data.R, R/models.R, R/figures.R) — tar_source() picks up
# everything in R/ automatically. So don't put random scripts in here!

# --- Standalone submission exports --------------------------------------
# Some journals require every table/figure as its own individually named
# file (tbl-01-*.docx, fig-01-*.tif), on top of (or instead of) embedding
# them in the manuscript. Rather than a second render pass, these export
# the *same* flextable/ggplot objects used in index.qmd directly to their
# own file — one source per table/figure, packaged twice.

#' Export a single flextable as a standalone docx
#'
#' Goes through flextable::save_as_docx() directly, not Quarto/pandoc —
#' sidesteps the docx reference-doc style-mapping quirks in CLAUDE.md
#' entirely, since nothing here depends on named Word styles resolving.
export_table_docx <- function(ft, name, dir) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  path <- file.path(dir, paste0(name, ".docx"))
  flextable::save_as_docx(ft, path = path)
  path
}

#' Export a single ggplot as a standalone LZW-compressed TIFF
#'
#' Renders to PNG first, then converts with magick — mirrors
#' generate-images.R's approach rather than ggsave's built-in tiff
#' device, whose LZW support isn't consistent across platforms. Deliberately
#' never runs inside a knitr chunk that also feeds the typst render: TIFF
#' hard-errors typst (see CLAUDE.md), and because tar_quarto() renders every
#' format in one pass, a TIFF failure there would take html/docx down too.
export_figure_tiff <- function(plot, name, dir, width = 6, height = 4, dpi = 300) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  png_path <- tempfile(fileext = ".png")
  ggplot2::ggsave(png_path, plot, width = width, height = height, dpi = dpi)
  tiff_path <- file.path(dir, paste0(name, ".tif"))
  magick::image_write(
    magick::image_read(png_path),
    path = tiff_path,
    format = "tiff",
    compression = "LZW"
  )
  tiff_path
}
