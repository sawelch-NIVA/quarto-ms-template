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
`manuscript/manuscript.qmd` and any notebook using `tar_read()`/`tar_load()`
depends on the `_targets/` data store; a direct render can silently pick
up stale or missing data. Every `.qmd` has a YAML-comment reminder of
this. `_targets.R` has one `tar_quarto(name = render_site, path =
"manuscript")` target that renders the whole `manuscript/` project (all
formats) as the pipeline's last step — confirmed this single target
produces html+docx+typst together, no need for per-format targets.

## Conventions

- **Target names are verbs** (`simulate_data`, `calculate_model`,
  `render_site`) — every target is an action, not just the noun it
  produces. Applies to every `tar_target()`/`tar_quarto()` added going
  forward.
- **`here::here()` (with an explicit `here::i_am(<this file's own path>)`
  anchor) for every file path constructed in R** — scripts and notebooks
  alike (`_targets.R`, `runme.R`, `generate-images.R`,
  `data-raw/import-data.R`, every `.qmd`'s setup chunk). Keeps path
  resolution identical regardless of whether something is run via
  `tar_make()`, knit standalone from an editor, or `Rscript`'d from an
  arbitrary directory. `i_am()`'s argument is always the *calling* file's
  own path relative to the **repo root** (where `.git`/`_targets.R`
  live) — not the file's path relative to `manuscript/`, and not the path
  of whatever it's trying to reach (easy to get backwards). E.g.
  `manuscript/manuscript.qmd` calls `here::i_am("manuscript/manuscript.qmd")`,
  not `here::i_am("manuscript.qmd")`.
- **`tar_read()`/`tar_load()` calls anywhere under `manuscript/` need an
  explicit `store = here::here("_targets")` argument** — see "Directory
  layout" below for why this is required, not defensive styling.

## Directory layout

```
_targets.R       pipeline: simulate_data → calculate_model → render_site (tar_quarto, renders manuscript/)
R/               functions, tar_source()'d automatically from _targets.R
data-raw/        raw/as-received data + import scripts (tracked in git)
data/            processed data from the pipeline (git-ignored, regenerated)
submission/      standalone per-table/per-figure exports for journals that need
                 individually named files (git-ignored, rebuilt by tar_make()) —
                 see "Standalone submission exports" below
runme.R          one-time bootstrap: installs deps, makes folders, tar_make()
generate-images.R  one-time generator for manuscript/img/ fixtures (root, not R/ — see Pipeline gotchas)
manuscript/      a SELF-CONTAINED Quarto project, one level below the repo root —
                 its own _quarto.yml, own _freeze/, .quarto/, and output/,
                 isolated from everything else. Pattern borrowed from
                 https://github.com/kazuyanagimoto/quarto-research-blog. All of
                 the following live inside manuscript/:
  _quarto.yml      project config: formats, theme, biblio/CSL, fig defaults.
                   output-dir MUST resolve inside manuscript/ (currently just
                   `output`, i.e. manuscript/output/) — see the warning below,
                   this isn't a style preference.
  manuscript.qmd   the manuscript
  tables/          one build file (tbl-NN-slug.R) + include partial
                   (_tbl-NN-slug.qmd) per table — see "Standalone submission
                   exports" below
  figures/         same pattern as tables/, one pair of files per figure
  supplementary/   extra notebooks (rendered automatically, not auto-linked in nav)
  styles/          CSL file + Word reference docs (db-space-line-n.docx, standard.docx)
  img/             fixture images for supplementary/images-mre.qmd (tracked in git)
  references.bib   bibliography
  output/          rendered output, all formats (git-ignored, rebuilt by
                   tar_make()) — Quarto's website render deletes anything
                   under here it doesn't recognize as its own, so nothing
                   else is ever written here
```

`data-raw/` vs `data/` mirrors the `usethis::use_data_raw()` R-package
convention: raw input + cleaning scripts are tracked, derived output
isn't.

**`output-dir` must resolve INSIDE `manuscript/`'s own project directory —
confirmed by direct testing that pointing it outside (e.g.
`output-dir: ../output`, tried in an earlier version of this template to
keep output at the repo root) is a genuinely broken configuration, not
just unusual.** Quarto itself warns `did not expect the path configuration
being used in this project, and strange behavior may result` and
`Refusing to remove directory ... since it is not a subdirectory of the
main project directory`, and in practice scattered rendered output across
three different locations in one render (a stray `index_files/` at the
repo root, a full duplicate render dropped directly in `manuscript/`, and
the intended `output/`) instead of writing cleanly to one place. This was
very likely the root cause of a recurring typst `file not found` error for
intermediate `_files/` images. After moving `output-dir` back inside
`manuscript/`: a full clean rebuild reproduced correctly with output
landing in exactly one place, and direct inspection of the docx's internal
OOXML (`[Content_Types].xml`, `document.xml`, `_rels/document.xml.rels` —
checked for XML well-formedness and that every `r:id`/`r:embed` reference
resolves to an existing relationship target) came back clean, with no
missing relationship targets and no dangling references.

**A second, separate docx "Word found unreadable content" bug recurred
after the output-dir fix above — don't assume that fix covers every table
corruption symptom, it doesn't.** At the time `output-dir` was fixed, a
`manuscript/output/manuscript.docx` repair prompt was (incorrectly) attributed
entirely to it, on the strength of one test (commenting out the
flextable-produced table stopped the prompt) — that test only proved the
table was *involved*, not that `output-dir` was the cause. The prompt came
back later on unrelated renders with `output-dir` already correct. The
actual root cause: **any docx table whose caption is crossreferenced
(`@tbl-foo`) triggers "unreadable content" specifically when the caption
renders above the table** (`tbl-cap-location: top`, docx's default) —
this is an upstream, still-open Quarto bug
([quarto-dev/quarto-cli#7321](https://github.com/quarto-dev/quarto-cli/issues/7321)),
not a misconfiguration in this template, and it affects `flextable`
output specifically (the table package this project uses everywhere per
"R table packages" below) though the upstream thread suggests it isn't
exclusive to it. Even the Quarto maintainer who investigated it directly
couldn't identify the specific malformed XML causing Word's complaint;
independently checking a minimal repro in this session (a crossreferenced
`flextable` table rendered through this project's own reference doc, top-
vs bottom-caption) reproduced the same inconclusiveness — relationship
IDs, bookmarks, and generic XSD structure validation were all identical
between the two, so whatever Word actually objects to isn't visible at
that level either. **Fix, confirmed working by direct testing in real
Word:** `manuscript/_quarto.yml`'s `format.docx` sets
`tbl-cap-location: bottom`, moving every table caption below its table.
This is a docx-only setting — it's nested under `format.docx` in
`manuscript/_quarto.yml`, not set at the document's top level — so html
and typst are unaffected and keep Quarto's own default of caption-above-
table for both: confirmed directly in this project's own rendered output,
`manuscript/output/manuscript.html`'s table caption carries class
`quarto-float-caption-top`, and `pdftotext`-extracting
`manuscript/output/manuscript.pdf` shows the "Table 1: ..." caption line
printed before the table body, same as docx's own pre-fix default. There's
also no known way to scope the docx fix to crossreferenced tables only —
`tbl-cap-location: bottom` is document-wide within docx, so every docx
table caption in this project now renders below its table, whether or not
that particular table is crossreferenced. Word itself wasn't available in
this Claude Code session to visually confirm the repair prompt is gone (no
Word/LibreOffice installed in this environment) — that confirmation came
from the user testing directly in real Word, not from this session.

**Why `manuscript/` is isolated as its own nested Quarto project in the
first place, separate from the output-dir bug above:** Quarto's freeze
cache (`_freeze/`) and per-document intermediate artifacts (`*_files/`)
are scoped to whatever project they're rendered under. Giving
`manuscript/` its own project root means its cache can never be
cross-contaminated by anything else in the repo, and `rm -rf
manuscript/_freeze manuscript/.quarto manuscript/output` is always a
safe, complete "start fresh."

**Consequence of nesting `manuscript/` one level below the repo root:**
the `_targets/` data store (defined by `_targets.R` at the repo root)
is *not* inside `manuscript/`'s own project root. With
`execute-dir: project` in `manuscript/_quarto.yml`, R code inside
`manuscript/**/*.qmd` runs with cwd = `manuscript/`, and `tar_read()`'s
default store lookup is cwd-relative (not `here()`-anchored) — so a bare
`tar_read(x)` inside `manuscript/` would look for `manuscript/_targets/`
and fail to find it. Fix used throughout `manuscript/`: pass
`store = here::here("_targets")` explicitly to every `tar_read()`/
`tar_load()` call — confirmed by direct testing this is genuinely
required, not just defensive.

**Correction, confirmed by direct testing while debugging an unrelated
`source()` failure: `execute-dir: project` does NOT reliably mean
`cwd = manuscript/` during chunk execution — it depends on how Quarto
itself was invoked, not just this setting.** A plain `quarto render
manuscript` (or `quarto::quarto_render()` called directly) does give
`cwd = manuscript/`, matching the explanation above and Quarto's own docs
for `execute-dir: project`. But this project's actual render path,
`tarchetypes::tar_quarto()` (the `render_manuscript` target), gives
`cwd = ` **the repo root** instead, at least in the installed Quarto/
tarchetypes versions used here — confirmed directly with a
`getwd()`/`list.files()` dump inside a knitr chunk, comparing the two
invocation paths side by side. This had never surfaced as a bug before
because every existing `tar_read()`/`tar_load()` call already used the
explicit `store = here::here("_targets")` workaround above rather than
relying on cwd - so the underlying cwd assumption was untested rather
than confirmed. It only became visible when a *new* chunk used a plain
cwd-relative path (`source("../R/functions.R")`) instead of
`here::here(...)`, which worked under a direct `quarto render` but failed
with `cannot open the connection` under `tar_quarto()` specifically.
**Practical upshot: never write a cwd-relative path in any
`manuscript/**/*.qmd` or partial, even ones that appear to only ever get
rendered through `quarto render` during interactive testing — use
`here::here(...)` (anchored via that file's own `here::i_am()`, called
before the path is needed) for every file path, exactly as CLAUDE.md
already prescribes elsewhere, but now for a second, independently
confirmed reason beyond the `tar_read()`/`tar_load()` case above.**

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

### R table packages (`manuscript/supplementary/tables-mre.qmd`)
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

### Images & diagrams (`manuscript/supplementary/images-mre.qmd`)
Full writeup lives in the notebook; headline findings:

- **Mermaid diagrams (```` ```{mermaid} ````) work natively across
  html/docx/typst with zero extra install** — Quarto converts them to a
  static PNG for docx/typst on its own, confirmed with no system
  Node/Deno/mermaid-cli on `PATH` in this environment. The docx/typst
  version is a raster image, not an editable diagram, though — a
  collaborator "fixing it in Word" is editing a picture.
- **PNG/JPEG are the only formats confirmed to work everywhere with zero
  warnings.**
- **SVG is native (vector) in html and typst** — typst confirmed via
  `pdftotext` pulling real text out of the compiled PDF, not a rasterized
  blob — **but docx needs a system `rsvg-convert` binary (librsvg) on
  `PATH`.** Without it, pandoc warns
  (`Could not convert image ...svg: check that rsvg-convert is in path`)
  and embeds the raw SVG with no raster fallback — a known way to get a
  blank/broken image in Word. Not visually confirmed in actual Word (no
  Word/LibreOffice available in this environment) — treat as
  unverified-risky, not verified-fine, until checked in real Word.
- **TIFF hard-errors typst** (`error: unknown image format`) — typst's
  image decoder doesn't support it at all. **Consequential part:** because
  `tar_quarto()`/`quarto render --to all` renders every format from one
  invocation, that single typst failure blocks html and docx from being
  updated too, even though both render clean with no warning for the same
  TIFF on their own. Confirmed by timestamp: after a typst failure,
  `output/*.html` and `output/*.docx` are left stale from the previous
  run. A stale-looking html/docx after `tar_make()` can mean a typst error
  further up the log, not that the pipeline didn't run.
- Fine text/thin lines that read fine at 100% become illegible once a
  figure is scaled to fit page width — confirmed by rendering and
  inspecting the actual PDF page, not just the source image. Don't trust
  legibility at authoring size as evidence it holds at rendered size.
- Uncompressed TIFF from synthetic test content came to ~24MB vs. ~850KB
  PNG / ~350KB JPEG for identical content — LZW compression brought it to
  ~1MB. Compress before committing raster fixtures to git.

### Pipeline gotchas
- `tar_source()` sources every `.R` file directly under `R/` on every
  pipeline load (`tar_make()`, `tar_visnetwork()`, even `tar_manifest()`).
  `runme.R` was once accidentally moved into `R/` — since it calls
  `tar_make()` itself, that would make defining the pipeline re-trigger
  the pipeline. Keep `runme.R` at the project root, never in `R/` — same
  reasoning applies to `generate-images.R` (a one-off script with file
  I/O side effects, not a function library).
- `tarchetypes::tar_quarto()`'s dependency-scanning pass evaluates chunk
  options like `eval: !expr is_html` without running the setup chunk
  first, so you'll see harmless `Error in eval(x, envir = envir) : object
  'is_html' not found` messages during `tar_make()` even on a successful
  build. Not fatal — the actual quarto CLI subprocess render (which does
  run setup first) is what determines success. Don't chase this as a
  real error; check the final `✔ render_site completed` / exit code
  instead.
- **Quarto's website render deletes anything under `output-dir` it doesn't
  recognize as its own output** — confirmed by direct testing: a stray file
  and an entire unrelated subdirectory placed directly under `output/`
  were both silently gone after a plain `quarto render . --to html`, no
  warning. Consequential part: any pipeline step that writes files into
  `output/` outside of `tar_quarto()` itself (e.g. an export step that
  runs before `render_site` in a given `tar_make()`) can have its output
  wiped by the same `tar_make()` invocation that created it, and whether
  that happens depends on target execution order, not something visible
  from reading `_targets.R`. Fix used here: anything that isn't a
  `tar_quarto()` output goes in a sibling directory (`submission/`) that
  Quarto never touches, never inside `output/`.
- **A single `tar_make()` run involves three separately-resolved R/Quarto
  processes, not one, and none of them re-read `PATH` from an
  already-running session.** (1) whatever R actually ran
  `targets::tar_make()`; (2) `quarto.exe` itself — not R, found on `PATH`,
  invoked as a subprocess by `tar_quarto()`; (3) the R that `quarto`
  spawns to execute the `.qmd`'s knitr chunks — also `PATH`-resolved, not
  guaranteed to be the same R as (1). A shell, Positron R console, or
  coding-assistant terminal that was already open when `PATH` changed
  (e.g. a new R version installed) keeps resolving whatever it originally
  saw, even after a reboot, if that specific process itself wasn't closed
  and reopened. Confirmed directly: after removing an old R install and
  updating `PATH`, an already-running shell (including a Claude Code
  session's own persistent shell) kept resolving the now-deleted
  `Rscript.exe` and failed with `Rscript: command not found`, while a
  fresh process using the full path to the same install worked fine. This
  is a likely contributor to orphaned intermediate/temp files turning up
  in unexpected places, too (a render started or interrupted under one
  R/Quarto resolution while another part of the toolchain used a
  different one) — compounds the `output-dir` issue above rather than
  being fully separate from it. When something works in one
  session/terminal but not another with apparently identical code: check
  what's actually being resolved *in the session having trouble*
  (`Sys.which("R")`/`Sys.which("Rscript")`/`Sys.which("quarto")`, or
  `where.exe Rscript`/`where.exe quarto`) rather than assuming — don't
  trust "it's on PATH" without checking the live value in that specific
  process. After changing an R or Quarto install, fully close and reopen
  every terminal/IDE window; a "reload window" doesn't necessarily
  restart every background process an IDE spawned (language server,
  persistent R session), so it can still serve a stale environment.

### Standalone submission exports
Some journals require every table/figure as its own individually named
file (`tbl-01-slug.docx`, `fig-01-slug.tif`), not just embedded in the
manuscript. Each table/figure gets its own build file —
`manuscript/tables/tbl-01-example.R` / `manuscript/figures/fig-01-example.R`,
defining a `build_*()` function — kept deliberately separate from
`_targets.R` so each one can load whatever styling packages it personally
needs (e.g. `patchwork`, `ggrepel`) without those becoming pipeline-wide
dependencies, and so the construction code itself is a normal,
directly-runnable R script rather than an expression buried inside a
`tar_target()` call. `_targets.R` wires each in as its own target
(`tbl_01_example`, `fig_01_example`), passing upstream targets (e.g.
`calculate_model`) in explicitly as function arguments — targets'
dependency scanner only reads the literal `command =` expression in
`_targets.R`, so a dependency used only *inside* the sourced file
wouldn't be tracked otherwise.

Embedding into the manuscript goes through a thin include partial per
table/figure — `manuscript/tables/_tbl-01-example.qmd` /
`manuscript/figures/_fig-01-example.qmd` — pulled into
`manuscript/manuscript.qmd` via `{{< include >}}`. The leading underscore
matters: it's the standard Quarto convention (same idea as `_quarto.yml`,
`_freeze`, `_targets`) that keeps the website-project renderer from also
rendering these partials as their own standalone pages. Confirmed by
direct testing that `tarchetypes::tar_quarto()`'s automatic dependency
scan follows `tar_read()` calls inside an `{{< include >}}`'d partial, not
just the top-level `.qmd` — changing `manuscript/figures/fig-01-example.R`
correctly triggered `render_site` to rerun with no manual
`tar_invalidate()` needed.

`export_tables`/`export_figures` write the *same* built object to a
standalone file in `submission/`, via `flextable::save_as_docx()` / a
PNG→TIFF `magick` conversion in `R/functions.R` — one definition per
table/figure, packaged twice, not a second render pass. `export_figures`
renders to PNG first and converts with `magick` rather than using
`ggsave(device = "tiff")` directly, mirroring `generate-images.R`'s
approach, since LZW support in the `tiff` graphics device isn't consistent
across platforms.

**Gotcha confirmed by direct testing: an include partial needs its own
`library(pkg)` call for whatever it prints, even though the object itself
was already built (with that package loaded) inside the targets
pipeline.** Without `library(flextable)` in
`manuscript/tables/_tbl-01-example.qmd`, the table rendered in both html
and docx as a dumped R object structure (`$header`, `$dataset`,
`$content`, raw `fpstruct`/`complex_tabpart` internals as literal text)
instead of an actual table — `targets::tar_read()`
happily deserializes a flextable-classed object either way, but S3 print
dispatch inside the Quarto/knitr render session silently falls back to
`print.default()` if the printing package's namespace was never loaded in
*that* session. Not obviously wrong from a normal render (no error, no
warning — it "renders" and looks plausible until you actually read the
table). Each include partial should `library()` whatever package owns the
print method for the object it's pulling in, don't assume it's loaded.

**Related, separate gotcha confirmed by direct testing:
`execute: freeze: true` can serve stale rendered content for a document
indefinitely, regardless of source changes.** Confirmed (under the old
pre-`manuscript/` layout, when `_quarto.yml`/`index.qmd` were still at the
repo root): `_freeze/index/execute-results/html.json` sat untouched through several
`tar_make()` runs that each reported `render_site completed`, while the
actual rendered `output/index.html` kept showing old chunk labels/content.
`freeze: true` means *always* reuse the frozen result once one exists, not
"reuse if the source hasn't changed" (that's `freeze: auto`) — so editing
the qmd or anything it depends on has no visible effect until the relevant
`_freeze/<doc>/` subfolder is deleted (or `tar_invalidate(render_site)` +
deleting it) to force re-execution. `manuscript/_quarto.yml` now uses
`freeze: auto`, which re-executes when the source is newer than the
freeze cache — the setting itself was changed by the user after this was
flagged, not by a Claude session. A second, likely-related instance of
this same staleness surfaced later as a recurring typst bug in
`manuscript/supplementary/tables-mre.qmd` (font warnings + a hard `file
not found` error for a `_files/` image that should have existed) — see
"Why `manuscript/` is isolated" above.

## Known drift to watch for

The user actively hand-edits alongside Claude sessions in this repo
(reorganizing headings, moving files, adding content). Before editing
something you last touched a while ago, re-read it — don't assume it
still matches what you wrote.
