# figures/fig-01-example.R ----
# Builds fig-01-example. See tables/tbl-01-example.R for why this lives in
# its own file rather than inline in _targets.R - this is the file to add
# patchwork/cowplot/ggrepel calls into for one figure without those
# packages touching the rest of the pipeline.
library(ggplot2)

build_fig_01_example <- function(data, model) {
  ggplot(data, aes(x, y)) +
    geom_point() +
    geom_abline(intercept = model[["(Intercept)"]], slope = model[["x"]]) +
    theme_bw()
}
