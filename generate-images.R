# generate-images.R ----
# One-time generator for fixture images in manuscript/figures/, used by
# supplementary/images-mre.qmd to stand in for "images created elsewhere
# and loaded from a file" (vs. figures generated inline by an R chunk). Run
# manually to regenerate; outputs are committed to git, not rebuilt by the
# pipeline. Lives at the project root, not R/, since tar_source() sources
# every .R file under R/ on every pipeline load - a side-effecting script
# doesn't belong there (see CLAUDE.md's runme.R note).
#
# Produces, at a deliberately large pixel size so format/legibility
# differences show up once scaled down to page width:
#   figures/sample-photo.png   - busy raster content (photo/micrograph stand-in)
#   figures/sample-photo.jpg   - same content, lossy JPEG, for comparison
#   figures/sample-scan.tiff   - same content, TIFF (scientific-imaging format,
#                                not supported by every renderer - the point)
#   figures/sample-diagram.svg - true vector diagram (boxes/arrows/fine text)
#                                via svglite, standing in for an Illustrator/
#                                Inkscape/PowerPoint export

library(magick)
library(svglite)
library(grid)
library(here)

here::i_am("generate-images.R")

set.seed(42)
out_dir <- here("manuscript/figures")

# --- Raster content: a busy, high-resolution synthetic "micrograph" ----
# Large canvas + fine text at several sizes + thin lines, so downscaling to
# page width actually stresses legibility instead of hiding the problem.
w <- 3000
h <- 2000

img <- image_graph(width = w, height = h, res = 300, bg = "white")
par(mar = c(0, 0, 0, 0))
plot.new()
plot.window(xlim = c(0, w), ylim = c(0, h))

# Dense scatter of small coloured cells, like a micrograph field
n <- 4000
points(
  x = runif(n, 0, w),
  y = runif(n, 0, h),
  pch = 16,
  cex = runif(n, 0.15, 0.6),
  col = adjustcolor(
    sample(c("firebrick", "steelblue", "darkgreen", "goldenrod"), n, replace = TRUE),
    alpha.f = 0.6
  )
)

# Thin grid lines, to see whether they survive lossy compression / downscale
abline(h = seq(0, h, length.out = 11), col = "grey70", lwd = 0.5)
abline(v = seq(0, w, length.out = 11), col = "grey70", lwd = 0.5)

# Fine text at decreasing sizes, the actual legibility stress test
labels <- c(
  "Sample field 4C - stress test label",
  "Scale bar 100um (not to scale, synthetic)",
  "n = 4000 synthetic events",
  "fine print fine print fine print"
)
for (i in seq_along(labels)) {
  text(
    x = w * 0.05,
    y = h * (0.95 - 0.05 * i),
    labels = labels[i],
    adj = 0,
    cex = 1.4 - 0.3 * i,
    col = "black"
  )
}
dev.off()

image_write(img, file.path(out_dir, "sample-photo.png"), format = "png")
image_write(img, file.path(out_dir, "sample-photo.jpg"), format = "jpg", quality = 60)
# LZW compression - real scientific TIFFs are usually compressed;
# uncompressed here just bloats the repo.
image_write(img, file.path(out_dir, "sample-scan.tiff"), format = "tiff", compression = "LZW")

# --- Vector content: a small schematic drawn directly with grid/svglite ----
svglite(file.path(out_dir, "sample-diagram.svg"), width = 7, height = 4)
grid.newpage()
boxes <- data.frame(
  x = c(0.15, 0.5, 0.85),
  y = c(0.5, 0.5, 0.5),
  label = c("Raw data", "Processing", "Manuscript")
)
for (i in seq_len(nrow(boxes))) {
  grid.roundrect(
    x = boxes$x[i], y = boxes$y[i], width = 0.22, height = 0.28,
    gp = gpar(fill = "grey95", col = "black", lwd = 1.2)
  )
  grid.text(boxes$label[i], x = boxes$x[i], y = boxes$y[i], gp = gpar(fontsize = 11))
}
grid.text(
  "microscopic fine print to test vector text legibility at small sizes",
  x = 0.5, y = 0.12, gp = gpar(fontsize = 6)
)
for (i in 1:2) {
  grid.lines(
    x = c(boxes$x[i] + 0.11, boxes$x[i + 1] - 0.11),
    y = c(0.5, 0.5),
    arrow = arrow(length = unit(2, "mm")),
    gp = gpar(lwd = 1.5)
  )
}
dev.off()

message("Wrote fixture images to ", out_dir)
