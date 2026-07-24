# Covers detect_render_format() (R/functions.R) - the function's own
# roxygen comment documents a real bug this was rewritten to fix (a
# hand-rolled version failed with "object 'is_html' not found" whenever
# QUARTO_EXECUTE_INFO was unset), so it's the one function in this
# template worth a regression test.

test_that("defaults to FALSE/NA when QUARTO_EXECUTE_INFO is unset", {
  withr::local_envvar(QUARTO_EXECUTE_INFO = "")

  fmt <- detect_render_format()

  expect_false(fmt$is_html)
  expect_false(fmt$is_typst)
  expect_false(fmt$is_docx)
  expect_true(is.na(fmt$ext))
})

test_that("reads target-format out of a QUARTO_EXECUTE_INFO JSON file", {
  info_file <- withr::local_tempfile(fileext = ".json")
  jsonlite::write_json(
    list(format = list(identifier = list(`target-format` = "docx"))),
    info_file,
    auto_unbox = TRUE
  )
  withr::local_envvar(QUARTO_EXECUTE_INFO = info_file)

  fmt <- detect_render_format()

  expect_true(fmt$is_docx)
  expect_false(fmt$is_html)
  expect_false(fmt$is_typst)
  expect_identical(fmt$ext, "docx")
})

test_that("typst maps to ext = \"pdf\", not \"typst\"", {
  info_file <- withr::local_tempfile(fileext = ".json")
  jsonlite::write_json(
    list(format = list(identifier = list(`target-format` = "typst"))),
    info_file,
    auto_unbox = TRUE
  )
  withr::local_envvar(QUARTO_EXECUTE_INFO = info_file)

  fmt <- detect_render_format()

  expect_true(fmt$is_typst)
  expect_identical(fmt$ext, "pdf")
})
