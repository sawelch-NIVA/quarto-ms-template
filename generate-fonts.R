# generate-fonts.R ----
# One-time fetch of a fixture font file for
# manuscript/supplementary/fonts-mre.qmd's "I have a font file, not a
# system-installed font" demonstrations (systemfonts::register_font(),
# extrafont's font_import() limitation) - stands in for a licensed brand
# font file someone hands you directly, as opposed to a Google Fonts
# catalog entry fetched live via sysfonts::font_add_google(). Run
# manually to regenerate; the output is committed to git like the
# manuscript/figures/ fixture images, not rebuilt by the pipeline - see
# generate-images.R for the same reasoning.
#
# Space Mono, chosen because it's visually distinctive (a geometric
# monospace, easy to tell apart from a fallback at a glance) and NOT
# preinstalled on a typical Windows/CI machine - confirmed via
# systemfonts::system_fonts() before picking it, so the demo actually
# proves registration works rather than accidentally matching a font
# that was already there. SIL Open Font License - freely embeddable,
# confirmed via the font's own OFL.txt in the same Google Fonts repo
# directory.
library(here)
here::i_am("generate-fonts.R")

dir.create(here("manuscript/fonts"), showWarnings = FALSE)
download.file(
  "https://github.com/google/fonts/raw/main/ofl/spacemono/SpaceMono-Regular.ttf",
  here("manuscript/fonts/SpaceMono-Regular.ttf"),
  mode = "wb",
  quiet = TRUE
)

message("Wrote fixture font to ", here("manuscript/fonts/SpaceMono-Regular.ttf"))
