# quarto-ms-template

A Quarto + `targets` template for manuscripts, built to render one
source to HTML, docx, and typst (PDF) via a reproducible pipeline. This
file is project memory for Claude Code sessions — see [README.md](README.md)
for the user-facing docs.

## Core architectural decision

Uses Quarto's `website` project type, not `manuscript`. `manuscript`
projects force a Jupyter engine/kernel even for pure-R content; `website`
lets every `.qmd` use the default knitr engine. This was the reason the
template exists in the first place — don't switch project types back
without re-litigating that.

## The one rule that matters most

**Always render via `targets::tar_make()`, never `quarto render`
directly**, except for quick iteration on a single file while writing it.
`index.qmd` and any notebook using `tar_read()`/`tar_load()` depends on
the `_targets/` data store; a direct render can silently pick up stale
or missing data. Every `.qmd` has a YAML-comment reminder of this.
`_targets.R` has one `tar_quarto(name = site, path = ".")` target that
renders the whole project (all formats) as the pipeline's last step —
confirmed this single target produces html+docx+typst together, no need
for per-format targets.

## Structure

```
_targets.R       pipeline: data → model → site (tar_quarto, renders everything)
_quarto.yml      project config: formats, theme, biblio/CSL, fig defaults
R/               functions, tar_source()'d automatically from _targets.R
data-raw/        raw/as-received data + import scripts (tracked in git)
data/            processed data from the pipeline (git-ignored, regenerated)
index.qmd        the manuscript
supplementary/   extra notebooks (rendered automatically, not auto-linked in nav)
styles/          CSL file + Word reference docs (db-space-line-n.docx, standard.docx)
output/          rendered output, all formats (git-ignored, rebuilt by tar_make())
runme.R          one-time bootstrap: installs deps, makes folders, tar_make()
```

`data-raw/` vs `data/` mirrors the `usethis::use_data_raw()` R-package
convention: raw input + cleaning scripts are tracked, derived output
isn't.

## Confirmed by direct testing, not assumed

Everything below was empirically rendered and checked in this repo, not
taken from docs — repeat that habit (render and inspect, don't guess) when
extending this template, since several findings here directly contradict
what you'd expect from package documentation.

### Output formats
- A single `quarto render` / `tar_make()` produces html + docx + typst
  together from one `format:` block in `_quarto.yml` — website-type
  projects do NOT restrict you to one format per render, despite that
  being true for some other Quarto project types.
- `fig-width: 6` / `fig-height: 4` / `fig-dpi: 300` at the top level of
  `_quarto.yml` apply globally. docx figures come out at exactly the
  configured 300dpi. HTML figures come out at 2x that (600dpi) because of
  knitr's `fig.retina = 2` default — intentional, not a bug.
- Typst PDFs render via Quarto's bundled compiler; no separate Typst
  install needed.

### The Word reference doc
`db-space-line-n.docx` (and the newer `standard.docx`) supply named
styles that pandoc writes docx output into. Anything not defined in the
reference doc silently falls back to a generic default — Word does not
warn you. Tested directly: pandoc references `Table`, `TableCaption`,
`BodyText`, `BlockText`, `Compact`, `FirstParagraph` style IDs (plus
`Author`/`Date`/`Abstract`/`Hyperlink`/`TOC Heading`/footnote styles/
`Verbatim Char`), and `db-space-line-n.docx` as originally supplied
defined none of them. Missing `Table` is the most consequential gap —
it's very likely the root cause of inconsistent table formatting in
Word. Fix: define styles with these exact names in Word (no import
needed, name-matching is all pandoc uses).

### R table packages (`supplementary/tables-mre.qmd`)
Full writeup lives in the notebook; headline findings:

- **`kableExtra` and `gt` hard-error** a docx or typst render if not
  gated with `eval: !expr is_html` (or similar) — not a graceful
  degradation, a render-stopping error: `Functions that produce HTML
  output found in document targeting <format> output`.
- **`gt` renders fine in typst** despite failing in docx — don't assume
  "non-HTML" is one bucket; test each target format separately. Gate on
  the actual `knitr::opts_knit$get("rmarkdown.pandoc.to")` value, not a
  simple html/not-html binary.
- **`flextable` is the only package confirmed to work cleanly across
  html/docx/typst** with real styling control. Default recommendation.
- **`huxtable`** also works across all three, smaller styling vocabulary,
  and renders slightly left-shifted vs. `gt`/`flextable` in typst
  specifically.
- **`DT`** is HTML-only (JS widget) — the right tool for large/wide
  datasets in HTML (paginated), not a competitor to the static-table
  packages.
- **huxtable and flextable export colliding generic names**
  (`bold()`, `width()`, ...) — namespace explicitly (`flextable::width()`)
  when both are loaded, don't rely on load order.
- **Hand-written pandoc grid tables are extremely fragile**: `+`/`|`
  characters must align by exact character column across every row. A
  one-character misalignment doesn't error — it silently drops entire
  cell content. Verify grid tables render correctly after writing them;
  don't trust visual alignment in the source.
- **`knitr::kable(x, format = "grid")` doesn't work** in the tested
  knitr version (`could not find function "kable_grid"`) — don't
  suggest it as a grid-table generator.
- **Known typst bug, not ours to fix**: a table whose rows span a page
  break renders as garbled, overlapping text right at the break —
  reproduced with `kable`, `flextable`, and `gt` alike on a 30-row stress
  table, confirmed via raw `pdftotext` extraction (i.e. a real content
  bug, not a PDF-viewer rendering artifact). No error or warning at
  render time — a clean `quarto render` exit code does not mean the PDF
  is correct. Mitigation: keep typst-bound tables short enough to fit on
  one page, or exclude large tables from the typst target.

### Pipeline gotchas
- `tar_source()` sources every `.R` file directly under `R/` on every
  pipeline load (`tar_make()`, `tar_visnetwork()`, even `tar_manifest()`).
  `runme.R` was once accidentally moved into `R/` — since it calls
  `tar_make()` itself, that would make defining the pipeline re-trigger
  the pipeline. Keep `runme.R` at the project root, never in `R/`.
- `tarchetypes::tar_quarto()`'s dependency-scanning pass evaluates chunk
  options like `eval: !expr is_html` without running the setup chunk
  first, so you'll see harmless `Error in eval(x, envir = envir) : object
  'is_html' not found` messages during `tar_make()` even on a successful
  build. Not fatal — the actual quarto CLI subprocess render (which does
  run setup first) is what determines success. Don't chase this as a
  real error; check the final `✔ site completed` / exit code instead.

## Known drift to watch for

The user actively hand-edits alongside Claude sessions in this repo
(reorganizing headings, moving files, adding content). Before editing
something you last touched a while ago, re-read it — don't assume it
still matches what you wrote.
