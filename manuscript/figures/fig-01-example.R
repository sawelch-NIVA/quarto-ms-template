# figures/fig-01-example.R ----
# Builds fig-01-example. See tables/tbl-01-example.R for why this lives in
# its own file rather than inline in _targets.R - this is the file to add
# patchwork/cowplot/ggrepel calls into for one figure without those
# packages touching the rest of the pipeline.
library(ggplot2)

build_fig_01_example <- function(data, model) {
  # model[["grouptreatment"]] is lm()'s default coefficient name for factor
  # `group`'s "treatment" level (varname + level, no separator) - matches
  # the "measurement ~ group" formula in _targets.R's calculate_model.
  fitted_means <- data.frame(
    group = c("control", "treatment"),
    measurement = c(
      model[["(Intercept)"]],
      model[["(Intercept)"]] + model[["grouptreatment"]]
    )
  )

  ggplot(data, aes(group, measurement)) +
    geom_jitter(width = 0.1) +
    geom_point(data = fitted_means, color = "red", size = 3, shape = 18) +
    theme_bw()
}
