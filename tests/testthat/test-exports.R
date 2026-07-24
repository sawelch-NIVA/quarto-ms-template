# Covers the standalone submission exports (R/functions.R) - just enough
# to catch "this doesn't create a file where it says it does", not a full
# check of docx/TIFF internals.

test_that("export_table_docx() writes a docx to the given directory", {
  ft <- flextable::flextable(data.frame(x = 1:2))
  out_dir <- withr::local_tempdir()

  path <- export_table_docx(ft, "test-table", out_dir)

  expect_true(file.exists(path))
  expect_match(path, "test-table\\.docx$")
})

test_that("export_figure_tiff() writes a tiff to the given directory", {
  p <- ggplot2::ggplot(
    data.frame(x = 1:2, y = 1:2),
    ggplot2::aes(x, y)
  ) +
    ggplot2::geom_point()
  out_dir <- withr::local_tempdir()

  path <- export_figure_tiff(p, "test-fig", out_dir)

  expect_true(file.exists(path))
  expect_match(path, "test-fig\\.tif$")
})
