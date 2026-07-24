# R/functions.R ----
# Custom functions used by the targets pipeline (_targets.R) or in Quarto files.
# Split into multiple files here as the project grows
# (e.g. R/read_data.R, R/models.R, R/figures.R) — tar_source() picks up
# everything in R/ automatically. So don't put random scripts in here!

# --- Render format detection ---------------------------------------------
# manuscript/manuscript.qmd's own basename (without extension). Supplementary
# notebooks' "back to manuscript" link partial reads this instead of
# hardcoding it in four separate files, so a future rename only needs
# updating here.
MANUSCRIPT_BASENAME <- "manuscript"

#' Detect which format Quarto is currently rendering, robustly
#'
#' Every .qmd/partial that needs is_html/is_typst/is_docx-style format
#' gating used to copy-paste the QUARTO_EXECUTE_INFO env var lookup
#' (confirmed working in manuscript/supplementary/tables-mre.qmd) by hand.
#' One hand-rolled copy in manuscript.qmd broke two ways at once: it used
#' `exists("info_file")` to guard against the env var being unset, but
#' info_file is *always* assigned on the line just above (as `""` when
#' unset, not absent) so exists() was always TRUE and never actually
#' guarded anything; and the fallback branch that ran when the var *was*
#' genuinely empty only ever set is_interactive, never is_html/is_typst/
#' is_docx - so downstream code checking `is_html` failed with
#' "object 'is_html' not found" whenever QUARTO_EXECUTE_INFO was unset.
#' That happens in two situations, both confirmed in this project: (1)
#' tarchetypes::tar_quarto()'s own dependency-scanning pass evaluates chunk
#' options like `eval: !expr is_html` without running the setup chunk (or a
#' real render) first - see CLAUDE.md's "Pipeline gotchas"; (2) a .qmd knit
#' standalone/interactively in an editor, outside any `quarto render`
#' invocation.
#'
#' This always returns every field with a real, non-NULL value - FALSE
#' rather than undefined for the is_* flags when the format can't be
#' determined - so callers never need exists()/is.null() guards, and
#' `eval: !expr is_html`-style YAML chunk options (which need a bare
#' symbol, not a list member - unpack the return value into your own
#' is_html/is_typst/is_docx variables) always have something to read.
#'
#' `ext` is the actual output file extension for the CURRENT format,
#' useful for linking to a sibling output file (e.g. "See the main
#' manuscript") - note typst compiles to PDF on disk, not .typ (see
#' rendering-pipeline.qmd), so this is "pdf" for typst, not "typst".
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
# Some journals require every table/figure as its own individually named
# file (tbl-01-*.docx, fig-01-*.tif), on top of (or instead of) embedding
# them in the manuscript. Rather than a second render pass, these export
# the *same* flextable/ggplot objects used in manuscript.qmd directly to their
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

#' Set a flextable's font to match the current render format's own default
#'
#' flextable defaults to Arial regardless of output format (its own
#' package-level default, confirmed via `flextable::get_flextable_defaults()`)
#' — html/typst/docx all pick this up identically, which reads as
#' "consistent" but actually means the table never matches any of the three
#' formats' own body font: html uses `mainfont: Fira Sans`
#' (manuscript/_quarto.yml), docx falls back to the reference doc's theme
#' font (`Aptos`, confirmed by reading db-space-line-n.docx's
#' word/theme/theme1.xml), and typst uses its own built-in default
#' (`Libertinus Serif`, confirmed via `pdffonts`-equivalent inspection of a
#' rendered PDF's embedded font names — this project sets no typst
#' `mainfont` override).
#'
#' A flextable object is built once upstream (tar_target) and reused
#' verbatim across all three format renders via {{< include >}} - it can't
#' know its eventual output format at construction time, and
#' set_flextable_defaults() only affects flextables created *after* it's
#' called, not ones already built. So this has to run at print time, in the
#' include partial, on the already-built object - flextable::font()
#' explicitly overrides an existing table's font regardless of how it was
#' originally styled, unlike changing the defaults.
#'
#' Uses detect_render_format() (above) for the format lookup, so both
#' this and every notebook's format-gating logic stay consistent if the
#' detection approach ever needs to change.
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
