# ============================================================================
# v95_second_axis.R -- two series in one draw, and the pens that separate them
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT SHIPPED. A boolean on the line chart's column-mapping page opens ONE
# follow-up page that asks for everything a right-hand y-axis needs: the
# column, the range (0 and 0 = auto, the sentinel every other range field in
# this plugin uses), the axis name, and that series' own line style. The
# second series adopts the first one's plot box, maps its own range onto it,
# and draws its ticks and its name in the right margin with Praat's own
# `One mark right:` and `Text right:`. Every other figure type refuses the
# request out loud.
#
# AND THE PENS. Measured at HEAD before this change order: not one call to a
# line-style command anywhere in the graphs layer and no user option for one,
# so every line the plugin had ever drawn was solid. There are now four
# styles on the line chart, the pitch contour and the spaghetti plot, and the
# second series carries its OWN style option -- two controls, not one with a
# hardcoded partner.
#
# ============================================================================
# THE RULING, AND THE ONE THING IT DID NOT SETTLE
# ============================================================================
# Ian, 18 August 2026, superseding an earlier colour rule: the first series
# SELECTS THE THEME (the existing colour mode), the second series takes SLOT
# TWO of that theme, and each series carries its own line style. No new colour
# control, no per-series colour picker, and no new colour logic -- the palette
# and its contrast optimiser already produce exactly this at two series.
#
# WHAT HE LEFT OPEN was whether the right axis's FURNITURE -- its ticks, its
# numbers, its name -- takes slot two's colour or stays default ink. PRAAT
# SETTLES IT: its margin commands draw in black whatever colour is current.
# Section 12 is that measurement, made on the rendered pixels of a probe that
# drives all three margin commands under a red pen and a `Draw line` under the
# same pen for control. It is in the suite because it is the reason the
# shipped behaviour is what it is: a future reader who wonders why the right
# scale is not orange gets a number rather than an opinion.
#
# ============================================================================
# WHAT THIS FILE READS
# ============================================================================
#
# harness/secondaxis/out/SECONDAXIS.tsv and the PNGs beside it. Every case is
# one press of Draw through @emlGraphsDrawWithLegendRoom -- the graphs form's
# own dispatch, at file scope precisely so a probe can drive it without a
# dialog -- with the request globals set to what the follow-up page would have
# set them to.
#
#     bash harness/secondaxis/run.sh        regenerate
#     bash harness/secondaxis/gui_pause.sh  regenerate the dialog transcript
#
# harness/secondaxis/out/gui/GUIPAUSE.tsv, which is the DIALOGS, driven under
# Xvfb with no screen coordinates: the tickbox is ticked with the keyboard and
# every page is dismissed with Return on its default button.
#
# and the source of the four files the feature lives in, for the statements
# that are about SHAPE rather than about pixels.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v95"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

OUT  <- repo_path("harness", "secondaxis", "out")
TSVP <- file.path(OUT, "SECONDAXIS.tsv")
GUIP <- file.path(OUT, "gui", "GUIPAUSE.tsv")

# Every case the harness draws, and every one this file asserts on. The two
# lists are compared at the end (eml_census): a case the driver renders that
# nothing here reads is silent non-coverage, which is the failure that census
# exists for.
CASES <- c("auto_pair", "typed_pair", "grouped_pair", "bw_pair",
           "styles_sweep", "single_untouched", "solid_default",
           "refuse_violin", "refuse_histogram", "refuse_ci", "refuse_scatter",
           "refuse_column", "margin_ink", "melt_carry", "recorded", "replay")

ok_tsv <- check_true(V, "the second-axis harness has been driven",
                     file.exists(TSVP) && file.info(TSVP)$size > 0)
if (!ok_tsv) {
    check_true(V, paste0("SECONDAXIS.tsv is missing or empty",
                         "\n  Run: bash harness/secondaxis/run.sh"), FALSE)
}

TR <- if (ok_tsv) {
    # quote = "" because the emitted block's values ARE quoted strings and
    # read.delim would otherwise strip the quotes it is being asked about.
    read.delim(TSVP, header = FALSE, sep = "\t", stringsAsFactors = FALSE,
               quote = "", col.names = c("case", "key", "value"),
               colClasses = "character")
} else {
    data.frame(case = character(0), key = character(0), value = character(0),
               stringsAsFactors = FALSE)
}

# One measurement by name. NA when the driver recorded none, which makes a
# check about a missing measurement fail rather than error.
trv <- function(case, key) {
    hit <- TR$value[TR$case == case & TR$key == key]
    if (length(hit) == 1L) hit else NA_character_
}
trn <- function(case, key) suppressWarnings(as.numeric(trv(case, key)))

# ============================================================================
# 1. EVERY CASE DREW
# ============================================================================
# A refusal is not a failure to draw. Six of these cases ask for a second axis
# on a figure that cannot carry one, and every one of them must still produce
# its figure -- with one y-axis, and a sentence saying why. A refusal that
# also lost the figure would be a worse defect than the one being prevented.
for (cs in CASES) {
    check_true(V, paste0("[", cs, "] drew and saved"),
               identical(trv(cs, "verdict"), "OK"))
}

# ============================================================================
# 2. THE FIGURE A CALLER WHO NEVER HEARD OF THIS CHANGE ORDER GETS
# ============================================================================
# THE CLAIM THAT MATTERS MOST IS THE ONE ABOUT WHAT DID NOT CHANGE. Two
# renders of the same figure -- one with neither global assigned at all, one
# with both set to their documented defaults (off, and solid) -- must be the
# same file. Compared between two PNGs this harness produced in the same run,
# not against a hash written into this file, which would only say that nothing
# had changed since somebody typed a hash.
md5_untouched <- trv("single_untouched", "png_md5")
md5_default   <- trv("solid_default",    "png_md5")
check_true(V, "the documented defaults draw the untouched figure, byte for byte",
           !is.na(md5_untouched) && identical(md5_untouched, md5_default))
check_true(V, "and it is a figure, not an empty file",
           identical(trv("single_untouched", "png_px"), "1800x1200"))
check_true(V, "a figure that asked for nothing reports no second axis",
           identical(trv("single_untouched", "secondon"), "0"))
check_true(V, "and says nothing in the Info window",
           identical(trv("single_untouched", "note_lines"), "0"))

# ============================================================================
# 3. THE AUTO RANGE, RECOMPUTED FROM THE DATA
# ============================================================================
# THE RULE, from @emlSecondAxisResolve: an auto right-hand range puts the
# right series at THE SAME FRACTIONS of the plot box that the left series
# occupies. Whatever headroom the figure negotiated once -- for nice numbers,
# for a legend, for a bracket -- both series got it, and a rising left series
# and a rising right series cannot be made to cross by an accident of scaling.
#
# The two columns are recomputed here from the fixture's own arithmetic
# (harness/secondaxis/data.praat), so this is an independent calculation of
# the number rather than a restatement of it. The primary is UNGROUPED in this
# case, so its series is the per-time mean of the two singers -- which is what
# the draw procedure collapses to, and what the figure shows.
tt   <- 1:12
sop  <- 268 - tt * 5 + (tt %% 3) * 4
ten  <- 244 - tt * 4 - (tt %% 4) * 3
lefty  <- (sop + ten) / 2
righty <- 0.40 + tt * 0.019

axL <- c(trn("auto_pair", "left_min"), trn("auto_pair", "left_max"))
check_true(V, "the left axis is the nice-number range the data asked for",
           isTRUE(all.equal(axL, c(190, 260))))
check_true(V, "and it contains the left series",
           min(lefty) >= axL[1] && max(lefty) <= axL[2])

f0 <- (min(lefty) - axL[1]) / (axL[2] - axL[1])
f1 <- (max(lefty) - axL[1]) / (axL[2] - axL[1])
span <- (max(righty) - min(righty)) / (f1 - f0)
expect_rmin <- min(righty) - f0 * span
expect_rmax <- expect_rmin + span

check(V, "auto right-axis floor is the left series' own headroom, applied to the right column",
      trn("auto_pair", "right_min"), expect_rmin, tol = 1e-6)
check(V, "auto right-axis ceiling likewise",
      trn("auto_pair", "right_max"), expect_rmax, tol = 1e-6)
# THE PROPERTY, STATED SEPARATELY FROM THE ARITHMETIC. A reader who does not
# want to follow the formula can read this instead: the two series sit at the
# same height in the box.
frac_r0 <- (min(righty) - trn("auto_pair", "right_min")) /
           (trn("auto_pair", "right_max") - trn("auto_pair", "right_min"))
frac_r1 <- (max(righty) - trn("auto_pair", "right_min")) /
           (trn("auto_pair", "right_max") - trn("auto_pair", "right_min"))
check(V, "the right series' lowest point sits where the left one's does", frac_r0, f0, tol = 1e-6)
check(V, "and its highest point where the left one's does",              frac_r1, f1, tol = 1e-6)
check_true(V, "the right column is on a plainly different scale from the left",
           max(righty) < 1 && min(lefty) > 100)

# ============================================================================
# 4. THE TYPED RANGE IS OBEYED AND IS NOT RE-DERIVED
# ============================================================================
# A pair the user typed is the range, exactly as on the left axis, and the
# proportional placement of section 3 is NOT applied to it. 0 to 1 is the
# whole of a proportion; the figure shows the series in the middle band of the
# box, which is what asking for it means.
check(V, "a typed right-axis floor is the floor that was typed",
      trn("typed_pair", "right_min"), 0, tol = 0)
check(V, "and a typed ceiling the ceiling that was typed",
      trn("typed_pair", "right_max"), 1, tol = 0)
check_true(V, "the typed range is not the auto one",
           trn("typed_pair", "right_max") != trn("auto_pair", "right_max"))
check_true(V, "and the left axis is untouched by either",
           trn("typed_pair", "left_min") == trn("auto_pair", "left_min") &&
           trn("typed_pair", "left_max") == trn("auto_pair", "left_max"))
check_true(V, "the two figures are different files",
           !identical(trv("typed_pair", "png_md5"), trv("auto_pair", "png_md5")))

# ============================================================================
# 5. SLOT ONE AND SLOT TWO, AND NO NEW COLOUR LOGIC
# ============================================================================
# The first series selects the theme; the second takes the next slot of it.
# Ungrouped that is slot two of two -- Okabe-Ito blue and orange in colour
# mode, the two ends of the grey ramp in black and white. Grouped it is slot
# nGroups + 1, which is the same rule with more series in it.
check_true(V, "the right series takes slot two of a two-series figure",
           identical(trv("auto_pair", "rightslot"), "2"))
check_true(V, "in colour, slot one is Okabe-Ito blue",
           identical(trv("auto_pair", "left_ink"), "{0.00, 0.45, 0.70}"))
check_true(V, "and slot two Okabe-Ito orange",
           identical(trv("auto_pair", "right_ink"), "{0.90, 0.62, 0.00}"))
check_true(V, "in black and white the first series is the ramp's black end",
           identical(trv("bw_pair", "left_ink"), "{0, 0, 0}"))
check_true(V, "and the second a grey plainly apart from it",
           identical(trv("bw_pair", "right_ink"), "{0.63, 0.63, 0.63}"))
check_true(V, "a grouped primary pushes the right series to the slot after its groups",
           identical(trv("grouped_pair", "rightslot"), "3"))
check_true(V, "and that slot is a third colour, not either group's",
           !identical(trv("grouped_pair", "right_ink"), trv("grouped_pair", "left_ink")))
# THE RENDERED PIXELS, not the reported strings: both inks are on the page.
check_true(V, "slot one's ink is on the figure",  trn("auto_pair", "ink_slot1_px") > 3000)
check_true(V, "slot two's ink is on the figure",  trn("auto_pair", "ink_slot2_px") > 3000)
check_true(V, "a one-series figure lays down none of slot two's ink",
           trn("single_untouched", "ink_slot2_px") == 0)
check_true(V, "and a black-and-white one none of either colour",
           trn("bw_pair", "ink_slot1_px") == 0 && trn("bw_pair", "ink_slot2_px") == 0)

# NO COLOUR LITERAL WAS WRITTEN. The ruling's own instruction -- "if you find
# yourself declaring a colour literal, stop" -- as a statement about the
# source: the second-axis block of the draw procedure names palette slots and
# nothing else.
draw_src <- readLines(repo_path("plugin_EML_StatsGraphs", "graphs",
                                "eml-draw-procedures.praat"), warn = FALSE)
graph_src <- readLines(repo_path("plugin_EML_StatsGraphs", "graphs",
                                 "eml-graph-procedures.praat"), warn = FALSE)
form_src  <- readLines(repo_path("plugin_EML_StatsGraphs", "graphs",
                                 "eml-graphs-form.praat"), warn = FALSE)
i0 <- grep("STEP 7C: THE SECOND SERIES", draw_src)
i1 <- grep("THE KEY IS DRAWN AFTER BOTH SERIES", draw_src)
block <- if (length(i0) && length(i1)) draw_src[i0[1]:i1[1]] else character(0)
check_true(V, "the second series' block exists to be read", length(block) > 20)
check_true(V, "and declares no colour literal of its own",
           !any(grepl("Colour:\\s*\"\\{", block)))
check_true(V, "it takes its ink from the palette by slot",
           any(grepl("emlSetColorPalette\\.line\\$\\[\\.rightSlot\\]", block)))

# ============================================================================
# 6. THE PENS, MEASURED ON THE PAGE
# ============================================================================
# A dotted line lays down fewer pixels than a solid line along the same path.
# styles_sweep draws the same left series as auto_pair with the primary pen
# set to Dotted and the second series to Dashed-dotted, so both counts must
# fall -- and if a style option were accepted and ignored, neither would.
# MOST OF A SERIES' INK IS ITS MARKERS, not its line: a filled dot at every
# vertex outweighs the stroke between them, and markers are never styled --
# two of @emlDrawMarker's shapes are themselves strokes, so a dashed pen would
# render a cross as two broken pieces. The line's own contribution is what
# moves here, which is why this is a difference of hundreds of pixels rather
# than a fraction of the total.
check_true(V, "a dotted primary lays down less ink than a solid one",
           trn("styles_sweep", "ink_slot1_px") <
           trn("auto_pair", "ink_slot1_px") - 300)
check_true(V, "a dashed-dotted second series lays down less than a dashed one",
           trn("styles_sweep", "ink_slot2_px") < trn("auto_pair", "ink_slot2_px"))
check_true(V, "and the styled figure is a different file from the default one",
           !identical(trv("styles_sweep", "png_md5"), trv("auto_pair", "png_md5")))
# THE DEFAULTS ARE SOLID THEN DASHED. The second series' ink in the default
# figure is well under the first's, because the first is solid and the second
# is not -- both series have the same number of points and span the same box.
check_true(V, "the second series is dashed by default while the first is solid",
           trn("auto_pair", "ink_slot2_px") < trn("auto_pair", "ink_slot1_px"))

# ============================================================================
# 7. THE REFUSALS, AND THAT THEY ARE NOT ONE REFUSAL
# ============================================================================
# Three kinds of figure cannot carry a second axis for three different
# reasons, and a reader told only "not this type" learns nothing about
# whether to ask again. Each message is quoted whole, because the sentence the
# user reads is the deliverable.
refusals <- c(
  refuse_violin = paste(
    "A second y-axis needs a continuous horizontal axis under it, and a",
    "Violin plot puts categories along the bottom: two series on two scales",
    "would have no common x to be read against. The figure was drawn with",
    "one y-axis."),
  refuse_histogram = paste(
    "A histogram is a distribution -- its vertical axis counts the values on",
    "its horizontal axis -- so a second vertical scale would have nothing of",
    "its own to measure. The figure was drawn with one y-axis."),
  refuse_ci = paste(
    "In this version the second axis ships on the plain time series -- the",
    "Line chart with the confidence-interval box unticked -- and this figure",
    "is a Time series with CI. The figure was drawn with one y-axis."),
  refuse_scatter = paste(
    "In this version the second axis ships on the plain time series -- the",
    "Line chart with the confidence-interval box unticked -- and this figure",
    "is a Scatter plot. The figure was drawn with one y-axis."))
for (cs in names(refusals)) {
    check_true(V, paste0("[", cs, "] refuses in the words the user reads"),
               identical(trv(cs, "refusal"), unname(refusals[cs])))
    check_true(V, paste0("[", cs, "] says it out loud rather than ignoring it"),
               trn(cs, "note_lines") >= 1)
    check_true(V, paste0("[", cs, "] draws its figure anyway"),
               identical(trv(cs, "verdict"), "OK") &&
               identical(trv(cs, "png_px"), "1800x1200"))
}
check_true(V, "the axis-shape reason and the scope reason are different sentences",
           !identical(unname(refusals["refuse_violin"]), unname(refusals["refuse_ci"])))
check_true(V, "and the distribution reason is a third",
           !identical(unname(refusals["refuse_histogram"]), unname(refusals["refuse_ci"])))
check_true(V, "the scope refusal names the type that was asked for",
           grepl("Scatter plot", refusals["refuse_scatter"], fixed = TRUE) &&
           grepl("Time series with CI", refusals["refuse_ci"], fixed = TRUE))
check_true(V, "and names the current scope, so the answer is a version and not a shrug",
           grepl("In this version", refusals["refuse_ci"], fixed = TRUE))

# ============================================================================
# 8. THE COLUMN GUARD IN THE LIBRARY, NOT ONLY AT THE DIALOG
# ============================================================================
# The dialog validates the column and re-presents its page on a bad one
# (section 10). The dialog is not the only caller: a recorded script, the API
# export and any user script set these globals directly. A column that is not
# numeric must produce the one-axis figure and a sentence naming the column,
# never an abort in the middle of somebody's drawing.
check_true(V, "a non-numeric right-hand column draws one axis",
           identical(trv("refuse_column", "secondon"), "0"))
check_true(V, "and says so",  trn("refuse_column", "note_lines") >= 1)
check_true(V, "and still produces the figure",
           identical(trv("refuse_column", "verdict"), "OK"))
check_true(V, "with none of slot two's ink on it",
           trn("refuse_column", "ink_slot2_px") == 0)

# ============================================================================
# 8B. WIDE FORMAT DRAWS FROM A DIFFERENT OBJECT, AND THE COLUMN GOES WITH IT
# ============================================================================
# Two or more series in wide format are MELTED into a three-column table --
# time, `eml_series`, `eml_value` -- and that table is what the draw procedure
# is handed. The right-hand column is chosen from the ORIGINAL table, which
# the melt does not carry, so @emlGraphsCarrySecondColumn copies it in under
# its own name and nothing downstream has to know a melt happened.
#
# THE ROW MAPPING IS WHAT CAN BE WRONG HERE. The melt writes the whole table
# once per series, so row r of the melt is row ((r-1) mod n) + 1 of the
# source: the first row of the SECOND series' block is row 1 of the source
# again, and an off-by-one there would put every value one row out without
# changing the column's length.
check_true(V, "the melted table gains a fourth column",
           identical(trv("melt_carry", "meltcols"), "4"))
check_true(V, "and keeps its two-series length",
           identical(trv("melt_carry", "meltrows"), "48"))
check_true(V, "the carried column's first row is the source's first row",
           identical(trv("melt_carry", "carry1_melt"),
                     trv("melt_carry", "carry1_source")) &&
           !is.na(trv("melt_carry", "carry1_melt")))
check_true(V, "the second series' block starts at the source's first row again",
           identical(trv("melt_carry", "carry2_melt"),
                     trv("melt_carry", "carry2_source")))
check_true(V, "and the melt's last row is the source's last row",
           identical(trv("melt_carry", "carryn_melt"),
                     trv("melt_carry", "carryn_source")))
check_true(V, "the two carried rows are different values, so the mapping is doing work",
           !identical(trv("melt_carry", "carry1_melt"),
                      trv("melt_carry", "carryn_melt")))
check_true(V, "the melted figure draws its right-hand series",
           identical(trv("melt_carry", "secondon"), "1") &&
           trn("melt_carry", "ink_slot2_px") > 3000)
check_true(V, "and the right series takes the slot after the melted ones",
           identical(trv("melt_carry", "rightslot"), "3"))
check_true(V, "the copy is a procedure, defined once",
           sum(grepl("^procedure emlGraphsCarrySecondColumn\\b", form_src)) == 1)
# The call, not a comment naming it: a line whose first non-blank character
# is the @ sign.
check_true(V, "and called once, from the melt's own branch",
           sum(grepl("^\\s*@emlGraphsCarrySecondColumn:", form_src)) == 1)

# ============================================================================
# 9. THE RECORDED SCRIPT CARRIES THE SECOND AXIS, AND REPLAYS IT
# ============================================================================
# The request is not a parameter of any draw procedure -- it is globals -- so
# a recorded call that carried every argument faithfully would still replay a
# one-axis figure. The recorder writes the settings as assignments in front of
# the call and the manifest lifts them into the editable block by name, under
# the numbering convention every other choice follows.
blockv <- function(name) trv("block", name)
check_true(V, "the block declares the primary pen",        identical(blockv("lineStyle"), "2"))
check_true(V, "the block declares the switch",             identical(blockv("secondAxisOn"), "1"))
check_true(V, "the block declares the column, quoted",     identical(blockv("secondAxisCol$"), "\"cq\""))
check_true(V, "the block declares the range floor",        identical(blockv("secondAxisMin"), "0"))
check_true(V, "the block declares the range ceiling",      identical(blockv("secondAxisMax"), "0"))
check_true(V, "the block declares the axis name, quoted",
           identical(blockv("secondAxisLabel$"), "\"Contact quotient\""))
check_true(V, "the block declares the second series' pen", identical(blockv("secondAxisStyle"), "3"))
# THE REPLAY IS THE CLAIM. Same picture, byte for byte, from the emitted file
# with the library pointed at this repository and the data rebuilt -- and
# nothing else edited.
check_true(V, "the emitted script replays the two-scale figure byte for byte",
           !is.na(trv("replay", "png_md5")) &&
           identical(trv("replay", "png_md5"), trv("recorded", "png_md5")))
check_true(V, "and it is the figure, not a blank page of the right size",
           trn("recorded", "ink_slot1_px") > 3000 && trn("recorded", "ink_slot2_px") > 3000)

rec_path <- file.path(OUT, "recorded_script.praat")
rec_ok <- file.exists(rec_path)
check_true(V, "the emitted script is on disk to be read", rec_ok)
rec <- if (rec_ok) readLines(rec_path, warn = FALSE) else character(0)
call_at <- grep("^@emlDrawTimeSeries:", rec)
set_at  <- grep("^emlSecondAxisOn = ", rec)
check_true(V, "the settings are stated in front of the call that acts on them",
           length(call_at) == 1 && length(set_at) == 1 && set_at[1] < call_at[1])
check_true(V, "and they read from the block rather than repeating its literals",
           any(grepl("^emlSecondAxisCol\\$ = secondAxisCol\\$$", rec)))

# ============================================================================
# 10. THE DIALOGS, DRIVEN
# ============================================================================
# ONE TICKBOX AND ONE FOLLOW-UP PAGE. Praat forms cannot reveal fields
# dynamically, so the alternative -- the second series' five fields sitting on
# the main page, dead until the box is ticked -- is the defect class where a
# control looks live and is not. The transcript below is the proof that the
# page appears only when asked for, and that a refusal RE-PRESENTS it.
gui_ok <- file.exists(GUIP) && file.info(GUIP)$size > 0
check_true(V, "the dialog transcript has been driven", gui_ok)
GU <- if (gui_ok) {
    read.delim(GUIP, header = FALSE, sep = "\t", stringsAsFactors = FALSE,
               col.names = c("run", "step", "title"), colClasses = "character")
} else {
    data.frame(run = character(0), step = character(0), title = character(0),
               stringsAsFactors = FALSE)
}
seq_of <- function(run) GU$title[GU$run == run & GU$step != "steps"]
refuse_seq <- seq_of("refuse")
accept_seq <- seq_of("accept")
PAGE <- "Line Chart -- Second Dataset on a Right Y-Axis"
check_true(V, "the journey starts at the graphs form",
           length(refuse_seq) >= 1 && refuse_seq[1] == "EML Graphs")
check_true(V, "and reaches the line chart's own pages",
           identical(refuse_seq[2:3], c("Line Chart -- Data Format",
                                        "Line Chart -- Column Mapping")))
check_true(V, "ticking the box opens the follow-up page",
           length(refuse_seq) >= 4 && refuse_seq[4] == PAGE)
check_true(V, "an invalid column is refused on a page of its own",
           length(refuse_seq) >= 5 && refuse_seq[5] == "Second dataset")
check_true(V, "and the follow-up page comes straight back",
           length(refuse_seq) >= 6 && refuse_seq[6] == PAGE)
check_true(V, "the accepting run meets the same page once",
           sum(accept_seq == PAGE) >= 1)
check_true(V, "and is not refused on it",
           !any(accept_seq == "Second dataset"))
check_true(V, "and reaches the post-draw dialog",
           "Graph Complete" %in% accept_seq)
check_true(V, "the figure the dialogs drew was saved",
           file.exists(file.path(OUT, "gui", "accept_figure.png")))
# THE PHOTOGRAPHS. Each named page was captured before it was dismissed, so
# the artefact is the dialog as the user meets it.
for (shot in c("refuse_03_Line_Chart_Column_Mapping_ticked.png",
               "refuse_04_Line_Chart_Second_Dataset_on_a_Right_Y_Axis.png",
               "refuse_05_Second_dataset.png",
               "refuse_06_Line_Chart_Second_Dataset_on_a_Right_Y_Axis.png")) {
    check_true(V, paste0("photographed: ", shot),
               file.exists(file.path(OUT, "gui", shot)))
}

# ============================================================================
# 11. THE SHAPE OF THE CODE
# ============================================================================
# ONE JUDGE, CALLED BY EVERY FIGURE. The scope decision is not thirteen
# opinions: @emlSecondAxisScope decides and @emlSecondAxisGate announces, and
# every figure-drawing procedure in the draw library calls the gate exactly
# once. A new graph type that forgets to fails this census rather than
# silently ignoring a request.
src <- paste(draw_src, collapse = "\n")
parts  <- strsplit(src, "(?m)^procedure ", perl = TRUE)[[1]]
parts  <- parts[-1]
pnames <- sub("^(\\w+).*$", "\\1", parts)
figs   <- pnames[grepl("@emlSetColorPalette", parts)]
gates  <- vapply(parts, function(b)
                 length(grep("(?m)^\\s*@emlSecondAxisGate:", b, perl = TRUE)),
                 integer(1))
names(gates) <- pnames
check_true(V, "the draw library holds fifteen figure-drawing procedures",
           length(figs) == 15)
for (f in figs) {
    check_true(V, paste0("[", f, "] asks the one judge, exactly once"),
               identical(unname(gates[f]), 1L))
}
check_true(V, "and only the plain time series goes on to honour it",
           sum(grepl("@emlSecondAxisRequest", parts)) == 1 &&
           grepl("@emlSecondAxisRequest", parts[pnames == "emlDrawTimeSeries"]))

# THE COMMAND THAT DOES NOT EXIST. Praat 6.6.30 refuses `Line style:` with
# "Command not available for current selection"; the four styles are set by
# the state-setting commands `Solid line`, `Dotted line`, `Dashed line` and
# `Dashed-dotted line`, and they are named in ONE procedure.
all_src <- c(graph_src, draw_src, form_src)
check_true(V, "nothing calls the line-style command Praat does not have",
           !any(grepl("^\\s*Line style:", all_src)))
for (word in c("Dotted line", "Dashed line", "Dashed-dotted line")) {
    check_true(V, paste0("`", word, "` is issued from one place only"),
               sum(grepl(paste0("^\\s*", word, "\\s*$"), all_src)) == 1)
}
check_true(V, "and that place is @emlApplyLineStyle",
           any(grepl("^procedure emlApplyLineStyle:", graph_src)))

# THE PEN IS PUT BACK. Praat keeps the line style in the Picture window, so a
# style left set dashes the next tick mark and the next figure. Every
# procedure that applies one resets it at least as often.
apply_n <- vapply(parts, function(b) length(grep("@emlApplyLineStyle:", b)), integer(1))
reset_n <- vapply(parts, function(b) length(grep("@emlResetLineStyle", b)),  integer(1))
names(apply_n) <- pnames; names(reset_n) <- pnames
for (p in pnames[apply_n > 0]) {
    check_true(V, paste0("[", p, "] resets the pen as often as it sets it"),
               reset_n[[p]] >= apply_n[[p]])
}
check_true(V, "at least three figure types carry a pen",
           sum(apply_n > 0) >= 3)

# THE REQUEST ENDS WITH THE PRESS. The form states the whole request on every
# press and takes it back after the draw, so that a figure drawn by some other
# menu command in the same session cannot inherit it.
check_true(V, "the form publishes the pens and the request in one place",
           any(grepl("^procedure emlGraphsPublishSeriesPens", form_src)) &&
           sum(grepl("^\\s*@emlGraphsPublishSeriesPens\\s*$", form_src)) == 1)
check_true(V, "and clears them after the drawing is on the page",
           any(grepl("^procedure emlGraphsResetSeriesPens", form_src)) &&
           sum(grepl("^\\s*@emlGraphsResetSeriesPens\\s*$", form_src)) == 1)
# THE RESOLVED RANGE IS NEVER WRITTEN BACK INTO THE REQUEST. Praat cannot
# unset a variable, so a resolved range parked in emlSecondAxisMin/Max would
# be the range the next figure drew on while its user believed they had asked
# for auto. Nothing in the draw library assigns to those two names.
check_true(V, "the draw layer never writes the request globals",
           !any(grepl("^\\s*emlSecondAxisM(in|ax)\\s*=", draw_src)))
check_true(V, "nor the switch, so a script's request survives a figure that refused it",
           !any(grepl("^\\s*emlSecondAxisOn\\s*=", draw_src)))

# ============================================================================
# 12. WHY THE RIGHT SCALE IS BLACK -- THE MEASUREMENT THAT SETTLED IT
# ============================================================================
# The probe draws, under one red pen: a `Draw line` inside the plot as a
# control, then `One mark right:`, `Marks right every:` and `Text right:`.
# If the margin commands honoured the current colour, the right margin would
# be full of red. It holds a residue of a few pixels -- text is drawn with
# subpixel anti-aliasing, so a black glyph carries coloured fringes -- against
# hundreds on the control stroke.
red_plot   <- trn("margin_ink", "red_plot_px")
red_margin <- trn("margin_ink", "red_margin_px")
check_true(V, "the red pen reaches an ordinary stroke inside the plot",
           red_plot > 500)
check_true(V, "and does not reach the right margin's ticks, numbers or name",
           red_margin < red_plot / 20)
check_true(V, "so the right axis furniture cannot be bound to the series' colour",
           red_margin < 40)
# AND THE SHIPPED CODE SAYS SO RATHER THAN PRETENDING OTHERWISE. A hook that
# claimed to colour the margin would be a comment, not an instruction.
check_true(V, "no colour hook survives in the right-margin drawing",
           !any(grepl("emlRightAxisColour", c(graph_src, draw_src, form_src))))
check_true(V, "and the file records the measurement where the ruling is discussed",
           any(grepl("draw in black whatever colour is current|IGNORE the",
                     graph_src)))

# ============================================================================
# EVERYTHING THE DRIVER RENDERED IS LOOKED AT
# ============================================================================
present <- unique(TR$case[TR$case != "block"])
eml_census(V, "second-axis cases", present, CASES)

if (!exists("EML_SUITE")) eml_report("v95 -- the second vertical axis")
