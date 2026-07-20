# quarto-ms-template

A Quarto + `targets` template for manuscripts: reproducible analysis
pipeline, rendered straight into the manuscript, in both HTML and Word.

Uses Quarto's `website` project type rather than `manuscript` —
`manuscript` projects force a Jupyter engine/kernel even for pure-R
content, which this template avoids entirely.

## Quick start

```r
source("runme.R")
```

That installs missing R packages, creates `data/` and `output/` if
they don't exist, checks the Quarto CLI is on `PATH`, then runs
`targets::tar_make()` to build the pipeline and render the manuscript.

After the first run, day to day you just need:

```r
targets::tar_make()
```

## How it fits together

```
_targets.R  →  defines the pipeline: data/model targets, then a
               tar_quarto() target that renders the whole Quarto
               project as the last step
_quarto.yml →  Quarto project config: formats (html + docx), theme,
               bibliography/CSL, default figure size & DPI
R/          →  custom functions, tar_source()'d automatically
index.qmd   →  the manuscript itself — reads pipeline results with
               tar_read()/tar_load()
supplementary/ → extra notebooks (see below)
styles/     →  CSL file + Word reference doc
output/     →  rendered HTML/docx + figures (git-ignored, rebuilt by
               tar_make())
```

**Always render through `targets::tar_make()`, not `quarto render`
directly.** `index.qmd` (and any notebook that calls `tar_read()`/
`tar_load()`) depends on the `_targets/` data store; rendering it
standalone can pick up stale or missing data. Every `.qmd` in this repo
has a comment at the top of its YAML front matter as a reminder.

## Output formats

Both HTML and docx are configured under `format:` in `_quarto.yml`, and
both come out of a single `tar_make()` run — no separate pipeline
targets needed. `format.docx.reference-doc` points at
`db-space-line-n.docx`, which supplies all the Word paragraph/table
styles pandoc writes into (see below).

Default figure size is 6in × 4in at 300 DPI (`fig-width`/`fig-height`/
`fig-dpi` in `_quarto.yml`) — sized for print-quality docx output.
HTML figures come out at double that pixel density (knitr's
`fig.retina = 2` default) for sharp on-screen rendering; that's
intentional, not a bug, and doesn't affect the docx copy.

## Adding a notebook

Anything under `supplementary/` renders automatically as part of the
site (Quarto renders every `.qmd` in the project by default), but
isn't added to the navbar automatically. Copy
`supplementary/notebook-template.qmd` as a starting point — it has a
comment explaining how to link it from `_quarto.yml` if you want it in
the site nav, or leave it unlinked for scratch/working notebooks.

`supplementary/tables-mre.qmd` is a working comparison of R's main
table packages (`kable`, `kableExtra`, `gt`, `flextable`, `huxtable`)
rendered to both HTML and docx — useful reading before picking a
tables package, since several of them behave very differently, or
outright fail, across the two formats.

## The Word reference doc (`db-space-line-n.docx`)

Pandoc/Quarto write Word output by re-using named styles from this
file — anything it doesn't define, Word silently substitutes a
generic default for. As shipped, `db-space-line-n.docx` covers
headings, title/subtitle, quotes, and line numbering, but is missing
several styles pandoc actively references, most importantly:

- **`Table`** — the style applied to every rendered table. Missing it
  is very likely why tables look inconsistent/plain in Word.
- **`Table Caption` / `Caption` / `Image Caption`** — figure/table
  caption styling and numbering.
- **`Body Text`, `Block Text`, `Compact`, `First Paragraph`** — main
  paragraph and blockquote styling.
- **`Author`, `Date`, `Abstract`, `Abstract Title`** — title-page
  metadata.
- Also absent: `Hyperlink`, `TOC Heading`, footnote styles, `Verbatim
  Char` (inline code).

Fix: open the docx in Word and define new styles with these exact
names (Word's *Styles* pane → *New Style*), formatted however your
target journal wants. You don't need to import anything — pandoc just
needs a style with the matching name to exist.

## Citations

Add references to `references.bib` and cite with `[@key]`. The
citation style is set via `csl: styles/apa.csl` in `_quarto.yml` —
swap in your target journal's `.csl` from the [Zotero Style
Repository](https://www.zotero.org/styles).
