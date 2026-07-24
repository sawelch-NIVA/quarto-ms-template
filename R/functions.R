# R/functions.R ----
# Functions used by the pipeline (_targets.R) and Quarto files. Split into
# more files as the project grows (R/read_data.R, R/models.R, ...) -
# tar_source() picks up everything in R/, so don't put scripts with side
# effects in here.

# --- Render format detection ---------------------------------------------
# manuscript.qmd's basename, without extension. Read by the supplementary
# notebooks' "back to manuscript" link partial instead of hardcoding it in
# every notebook, so a rename only needs updating here.
MANUSCRIPT_BASENAME <- "manuscript"

#' Detect which format Quarto is currently rendering
#'
#' Reads QUARTO_EXECUTE_INFO once so every .qmd/partial needing
#' is_html/is_typst/is_docx-style gating doesn't hand-roll the lookup. A
#' previous hand-rolled copy in manuscript.qmd broke because its
#' `exists("info_file")` guard was always TRUE (info_file is assigned `""`
#' when unset, never absent) and its fallback branch never set
#' is_html/is_typst/is_docx - so downstream code failed with "object
#' 'is_html' not found" whenever the env var was unset. That happens when
#' tar_quarto()'s dependency-scan pass evaluates chunk options like
#' `eval: !expr is_html` before running the setup chunk (see CLAUDE.md's
#' "Pipeline gotchas"), or when a .qmd is knit standalone outside
#' `quarto render`.
#'
#' Always returns every field with a real value (FALSE, not undefined, for
#' unknown is_*), so callers never need exists()/is.null() guards, and
#' `eval: !expr is_html`-style YAML options (which need a bare symbol -
#' unpack the list into your own variables) always have something to read.
#'
#' `ext` is the current format's actual output extension, for linking to a
#' sibling output file - typst compiles to PDF on disk, so this is "pdf",
#' not "typst".
detect_render_format <- function() {
  info_file <- Sys.getenv("QUARTO_EXECUTE_INFO")

  if (!nzchar(info_file)) {
    return(list(
      is_html = FALSE,
      is_typst = FALSE,
      is_docx = FALSE,
      is_interactive = interactive(),
      ext = NA_character_
    ))
  }

  info <- jsonlite::fromJSON(info_file)
  render_format <- info$format$identifier$`target-format`

  is_docx <- identical(render_format, "docx")
  is_typst <- identical(render_format, "typst")
  is_html <- identical(render_format, "html")

  list(
    is_html = is_html,
    is_typst = is_typst,
    is_docx = is_docx,
    is_interactive = FALSE,
    ext = if (is_docx) "docx" else if (is_typst) "pdf" else if (is_html) "html" else NA_character_
  )
}

# --- Standalone submission exports --------------------------------------
# Some journals require every table/figure as its own named file
# (tbl-01-*.docx, fig-01-*.tif) in addition to the embedded manuscript
# copy. These export the same flextable/ggplot object used in
# manuscript.qmd - one source, packaged twice, not a second render pass.

#' Export a single flextable as a standalone docx
#'
#' Uses flextable::save_as_docx() directly, not Quarto/pandoc - sidesteps
#' the reference-doc style-mapping quirks in CLAUDE.md, since nothing here
#' depends on named Word styles resolving.
export_table_docx <- function(ft, name, dir) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  path <- file.path(dir, paste0(name, ".docx"))
  flextable::save_as_docx(ft, path = path)
  path
}

#' Set a flextable's font to match the current render format's body font
#'
#' flextable defaults to Arial regardless of format (confirmed via
#' `get_flextable_defaults()`), so left alone it matches none of this
#' project's actual body fonts: html uses `Fira Sans`
#' (manuscript/_quarto.yml), docx falls back to the reference doc's theme
#' font (`Aptos`, from db-space-line-n.docx's word/theme/theme1.xml), and
#' typst uses its built-in `Libertinus Serif` (confirmed via the rendered
#' PDF's embedded font names - no typst `mainfont` override is set here).
#'
#' Must run at print time (in the include partial), not build time: the
#' flextable object is built once upstream and reused across all three
#' formats via {{< include >}}, so it can't know its eventual format at
#' construction, and set_flextable_defaults() only affects tables built
#' after it's called. flextable::font() overrides an existing table's font
#' regardless of prior styling, which is what makes this work.
#'
#' Uses detect_render_format() so this stays consistent with every
#' notebook's own format-gating logic.
flextable_use_format_font <- function(ft) {
  fmt <- detect_render_format()

  font <- if (fmt$is_html) {
    "Fira Sans"
  } else if (fmt$is_docx) {
    "Aptos"
  } else if (fmt$is_typst) {
    "Libertinus Serif"
  } else {
    NULL
  }
  if (is.null(font)) return(ft)

  flextable::font(ft, fontname = font, part = "all")
}

#' Export a single ggplot as a standalone LZW-compressed TIFF
#'
#' Renders to PNG first, then converts with magick, mirroring
#' generate-images.R - ggsave's built-in tiff device has inconsistent LZW
#' support across platforms. Runs as its own target, not a chunk in the
#' typst render: TIFF hard-errors typst (see CLAUDE.md), and tar_quarto()
#' renders every format in one pass, so a TIFF failure there would take
#' html/docx down too.
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
