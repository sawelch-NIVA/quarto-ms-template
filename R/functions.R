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

# --- Default plot colour scales ------------------------------------------

#' Set project-wide default ggplot2 colour/fill scales
#'
#' viridis, not ggplot2's own hue-wheel defaults - see
#' manuscript/supplementary/colour-mre.qmd for why: the built-in defaults
#' lost on every scale type tested there (muddy continuous gradients, a
#' non-neutral diverging midpoint), while viridis was the one "genuinely
#' safe default" that came out of that comparison. Confirmed directly
#' that `options(ggplot2.discrete.colour = "viridis", ...)` is real,
#' working ggplot2 API (not a hypothetical) - the string form is accepted
#' directly, no wrapper function needed, and it actually changes both
#' discrete and continuous scale colours when no `scale_*_()` is set
#' explicitly in a chunk.
#'
#' Global, not automatic: only takes effect in a document that calls this
#' - `manuscript.qmd` and `notebook-template.qmd` both do, in their setup
#' chunks, so every new notebook copied from the template inherits it.
#' A chunk can still override with its own explicit `scale_*_()` call -
#' this only sets what happens when none is specified. scico remains the
#' documented (not enforced) recommendation for water/earth-science
#' figures specifically, per colour-mre.qmd - viridis is the safer
#' general-purpose default, not a claim that it's always the better
#' choice.
set_default_palettes <- function() {
  options(
    ggplot2.discrete.colour = "viridis",
    ggplot2.discrete.fill = "viridis",
    ggplot2.continuous.colour = "viridis",
    ggplot2.continuous.fill = "viridis"
  )
}

# --- Pipeline-definition noise ------------------------------------------

#' Suppress raw stderr noise from tar_quarto()'s dependency-scanning pass
#'
#' tarchetypes::tar_quarto()'s dependency scanner evaluates chunk options
#' like `eval: !expr is_html` in every source .qmd, before any setup chunk
#' has run, to look for tar_read()/tar_load() calls hidden inside them -
#' confirmed harmless (see CLAUDE.md's "Pipeline gotchas"), but the
#' resulting "Error in eval(x, envir = envir): object 'is_html' not found"
#' text goes straight to stderr via `try(silent = FALSE)`, not through
#' message()/warning() - confirmed by testing that suppressMessages()
#' around the same tar_quarto() call does NOT catch it, while
#' sink(type = "message") does, since that's the connection try() writes
#' to. A real problem during this scan still raises a stop()-class
#' condition, which propagates through this wrapper exactly as if it
#' weren't there - only the raw stderr text is discarded, not real errors.
quiet_quarto_scan <- function(expr) {
  con <- file(nullfile(), open = "wt")
  on.exit(
    {
      sink(type = "message")
      close(con)
    },
    add = TRUE
  )
  sink(con, type = "message")
  force(expr)
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

#' Add shadow/outline text to an sf-based ggplot
#'
#' Wraps GuangchuangYu's shadowtext (https://github.com/GuangchuangYu/shadowtext)
#' for sf geometries specifically - shadowtext's own geom_shadowtext() takes
#' plain x/y aesthetics, not an sf geometry column, so it can't label an
#' sf layer (e.g. a country/region centroid) directly the way
#' ggplot2::geom_sf_text()/geom_sf_label() can. This is the sf-aware
#' counterpart: same stat = "sf_coordinates" mechanism as geom_sf_text(),
#' with shadowtext::GeomShadowText as the geom instead of GeomText - the
#' outline is what keeps a label legible sitting on top of a
#' many-coloured choropleth or coastline, where a plain geom_sf_text()
#' label can disappear into the background.
#'
#' Every external call is namespace-qualified rather than relying on
#' library() having been called first, matching every other function in
#' this file (e.g. detect_render_format()'s jsonlite::fromJSON) - R/ is
#' tar_source()'d on every pipeline load, and this project has no
#' NAMESPACE/roxygen import mechanism to lean on since there's no
#' DESCRIPTION file (see CLAUDE.md's "Pipeline gotchas").
#'
#' @param mapping Set of aesthetic mappings created by ggplot2::aes()
#' @param data The data to be displayed (an sf object/column)
#' @param stat The statistical transformation to use
#' @param position Position adjustment
#' @param ... Other arguments passed to the layer (e.g. bg.colour, size)
#' @param parse If TRUE, labels will be parsed as expressions
#' @param nudge_x Horizontal adjustment to nudge labels by
#' @param nudge_y Vertical adjustment to nudge labels by
#' @param check_overlap If TRUE, overlapping labels will be removed
#' @param na.rm If FALSE (default), removes missing values with warning
#' @param show.legend Logical indicating whether this layer should be included in legends
#' @param inherit.aes If FALSE, overrides default aesthetics
#' @param fun.geometry Function for transforming geometry (sf-specific)
#'
#' @return A ggplot2 layer
geom_sf_shadowtext <- function(
  mapping = ggplot2::aes(),
  data = NULL,
  stat = "sf_coordinates",
  position = "identity",
  ...,
  parse = FALSE,
  nudge_x = 0,
  nudge_y = 0,
  check_overlap = FALSE,
  na.rm = FALSE,
  show.legend = NA,
  inherit.aes = TRUE,
  fun.geometry = NULL
) {
  if (!missing(nudge_x) || !missing(nudge_y)) {
    if (!missing(position)) {
      cli::cli_abort(c(
        "Both {.arg position} and {.arg nudge_x}/{.arg nudge_y} are supplied.",
        i = "Only use one approach to alter the position."
      ))
    }
    position <- ggplot2::position_nudge(nudge_x, nudge_y)
  }

  ggplot2::layer_sf(
    data = data,
    mapping = mapping,
    stat = stat,
    geom = shadowtext::GeomShadowText,
    position = position,
    show.legend = show.legend,
    inherit.aes = inherit.aes,
    params = rlang::list2(
      parse = parse,
      check_overlap = check_overlap,
      na.rm = na.rm,
      fun.geometry = fun.geometry,
      ...
    )
  )
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
