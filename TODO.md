# TODO

Deferred items, not urgent - noted here instead of GitHub Issues since
this is currently a single-maintainer template repo.

- **`execute: freeze` setting is unsettled.** `manuscript/_quarto.yml`
  currently uses `freeze: false` (never freeze, always re-execute) rather
  than `freeze: auto`, deliberately, to sidestep a staleness bug found
  earlier (see CLAUDE.md's "Related, separate gotcha"). Not confirmed
  whether `freeze: auto` would reintroduce a subtler version of the same
  problem. Revisit once render times actually become annoying enough to
  justify testing it properly.
- **`README.md`/`CLAUDE.md` duplicate a fair amount of the same bug
  narratives** (output-dir, docx caption bug, PATH/multiple-R gotcha).
  Consider consolidating so one is the source of truth and the other
  links to it, rather than keeping both in sync by hand.
- **No `LICENSE` file yet.** Fine for now; add one before treating this
  as a template other people are expected to reuse externally.
- **CI has no caching** (`actions/cache` for R packages / `_targets/` /
  `_freeze/`) - every push pays the full install + render cost. Only
  worth adding if render time in Actions becomes a real annoyance; see
  manuscript/supplementary/ci-pipeline.qmd's "What this doesn't do".
- **`flextable_use_format_font()` (R/functions.R) has no test.** Skipped
  when adding the barebones test suite since checking it picked the right
  font means introspecting flextable's internal `fp_text` structure - more
  machinery than "barebones" was meant to cover. Worth adding a real test
  if this function grows more format-specific branches.
- **`renv` deliberately not adopted** - considered and declined for now;
  not a gap, just recorded so a future session doesn't re-suggest it
  without checking first.
