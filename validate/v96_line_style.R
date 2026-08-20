# ============================================================================
# v96_line_style.R -- four pens, measured along the stroke
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT WAS MEASURED AT HEAD, BEFORE THIS CHANGE ORDER. Not one call to a
# line-style command anywhere in the graphs layer and no user option for one:
# every line this plugin had ever drawn was solid, on every figure type.
# Praat provides four styles natively -- `Solid line`, `Dotted line`,
# `Dashed line`, `Dashed-dotted line` -- and none of them was reachable.
#
# WHAT SHIPPED. A "Line style" option menu, four options in that order,
# default Solid, on every figure type that strokes a series: the pitch
# contour, the waveform, the spectrum, the LTAS, the line chart (with its
# confidence band or without it) and the spaghetti plot. The choice is
# remembered per type, recorded per drawing under the numbering convention,
# and surfaced in the emitted script's editable block. The second series on a
# right-hand axis carries its OWN option, default Dashed -- two controls, not
# one with a hardcoded partner.
#
# ============================================================================
# WHY THIS FILE MEASURES A RUN STRUCTURE AND NOT A PIXEL COUNT
# ============================================================================
# A count of ink says a figure changed. It does not say the figure changed in
# the way the option names. Two figures with the same amount of ink can be a
# dashed line and a shorter solid one, and no count separates Dashed from
# Dashed-dotted: on this fixture their totals sit 229 pixels apart out of ten
# thousand, which is inside the noise of one extra marker.
#
# WHAT DOES SEPARATE THE FOUR PENS IS WHERE THE INK STOPS AND STARTS along the
# path. harness/linestyle/stroke.py walks the columns strictly inside the plot
# frame and reports, for each figure, how many columns carry ink, how many
# maximal runs of inked columns there are, how long the longest is, and how
# many holes lie between the first and the last. A solid line is one run and
# no holes. A dotted line is hundreds of short runs. A dashed line is fewer,
# longer runs. Dashed-dotted alternates, so its run COUNT sits between the
# other two broken pens while its inked FRACTION does as well. Section 3
# requires those four signatures to be four different things, in the order the
# geometry predicts, with the margins stated.
#
# AND THE FRAME IS MEASURED WITH THEM, THOUGH NOT FOR THE REASON THE FIRST
# DRAFT OF THIS FILE GAVE. Praat keeps the line style in the PICTURE WINDOW
# rather than in the figure, so a pen left set outlives the figure it was set
# for -- but its PLOT FURNITURE does not honour it. Measured, in
# harness/linestyle/furniture_pen.praat: under one dotted pen, an ordinary
# `Draw line` comes back in 331 pieces while `Draw inner box` and
# `Marks left every:` come back solid the full width and height of the box.
# The same shape of finding as v95 section 12, which measured that the
# right-margin commands draw black whatever colour is current.
#
# So the frame is not a leak detector, and section 5 no longer pretends it is.
# It is a STABLE REFERENCE: the box is the one thing on the page that no
# line-style option in this plugin can change, and a figure whose frame is
# broken has something wrong with it that this feature cannot have caused.
# What the leaked pen DOES reach is measured where it lands -- on the error
# bars of the next figure, in section 6.
#
# ============================================================================
# WHAT THIS FILE READS
# ============================================================================
#
# harness/linestyle/out/LINESTYLE.tsv and the PNGs beside it. Every case is
# one or more presses of Draw through @emlGraphsDrawWithLegendRoom -- the
# graphs form's own dispatch -- with the per-type dialog variable set to what
# its option menu would have set it to, published through the form's own
# @emlGraphsPublishSeriesPens and taken back through
# @emlGraphsResetSeriesPens. A case that assigned emlLineStyle directly would
# be testing the draw layer while claiming to test the control.
#
#     bash harness/linestyle/run.sh          regenerate
#     bash harness/linestyle/break.sh        drive the deliberate defects
#
# and the source of the four files the feature lives in -- the form, the
# graph library, the drawing library and the recorder -- for the statements
# that are about SHAPE rather than about pixels.
#
# $EML_LS_DIR and $EML_LS_SRC point this file at a different artefact and a
# different tree, which is how break.sh scores a broken copy without touching
# the working tree.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v96"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

OUT  <- Sys.getenv("EML_LS_DIR", unset = repo_path("harness", "linestyle", "out"))
PLUG <- Sys.getenv("EML_LS_SRC", unset = repo_path("plugin_EML_StatsGraphs"))
TSVP <- file.path(OUT, "LINESTYLE.tsv")

# Every case the harness draws, and every one this file reads. The two lists
# are compared at the end: a case the driver renders that nothing here looks
# at is silent non-coverage, which is what eml_census exists for.
CASES <- c(
    # the four pens on the type that has all four driven
    "ts_solid", "ts_dotted", "ts_dashed", "ts_dashdot",
    # one pair per remaining type that strokes a series
    "ci_solid", "ci_dotted", "f0_solid", "f0_dotted",
    "wave_solid", "wave_dotted", "spec_solid", "spec_dotted",
    "ltas_solid", "ltas_dotted", "spag_solid", "spag_dotted",
    # the reset, and its control
    "bar_alone", "leak_bar_after_dotted", "leak_ts_after_dotted",
    # the reset seen from OUTSIDE the form -- a caller that states no pen
    "unpublished_alone", "unpublished_after_dotted",
    # recorded, emitted, replayed
    "recorded_wave", "replay",
    # what Praat's own furniture does under a pen -- no library loaded
    "furniture_pen",
    # the figure Ian is sent, and the full-resolution strip cut out of it
    "fourstyles", "detail")

ok_tsv <- check_true(V, "the line-style harness has been driven",
                     file.exists(TSVP) && file.info(TSVP)$size > 0)
if (!ok_tsv) {
    check_true(V, paste0("LINESTYLE.tsv is missing or empty",
                         "\n  Run: bash harness/linestyle/run.sh"), FALSE)
}

TR <- if (ok_tsv) {
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
# The verdict is the driver's, not this file's: a case whose Praat process
# died is DREW_THEN_FAILED or NO_FIGURE, and a run that reported neither still
# has to have produced a file with a size.
for (cs in setdiff(CASES, "detail")) {
    check_true(V, paste0("[", cs, "] drew and saved"),
               identical(trv(cs, "verdict"), "OK"))
    check_true(V, paste0("[", cs, "] wrote a 300-dpi page"),
               isTRUE(nzchar(trv(cs, "png_px"))) &&
               isTRUE(grepl("^[0-9]+x[0-9]+$", trv(cs, "png_px"))))
}

# ============================================================================
# 2. WHAT THE PRESS ASKED FOR, IN THE PLUGIN'S OWN WORDS
# ============================================================================
# Each case prints the option index it set and the word @emlLineStyleName
# gives for it. The words are not restated by the driver, so a renamed option
# renames what is printed here -- and the pairing below is then wrong, which
# is the point: the menu, the name procedure and this file cannot drift apart
# quietly.
STYLE_WORDS <- c("Solid", "Dotted", "Dashed", "Dashed-dotted")
WANT <- list(ts_solid = 1, ts_dotted = 2, ts_dashed = 3, ts_dashdot = 4,
             ci_solid = 1, ci_dotted = 2, f0_solid = 1, f0_dotted = 2,
             wave_solid = 1, wave_dotted = 2, spec_solid = 1, spec_dotted = 2,
             ltas_solid = 1, ltas_dotted = 2, spag_solid = 1, spag_dotted = 2,
             recorded_wave = 3, fourstyles = 4)
for (cs in names(WANT)) {
    want <- WANT[[cs]]
    check_true(V, paste0("[", cs, "] pressed Draw with style ", want),
               identical(trn(cs, "style"), as.numeric(want)))
    check_true(V, paste0("[", cs, "] and the plugin names it ",
                         STYLE_WORDS[want]),
               identical(trv(cs, "stylename"), STYLE_WORDS[want]))
}

# THE TYPE EACH CASE PRESSED, so that a case cannot pass section 4 by drawing
# the wrong figure. The numbers are the graphs form's own graph_type.
TYPE_OF <- list(f0_solid = 1, f0_dotted = 1, wave_solid = 2, wave_dotted = 2,
                recorded_wave = 2, spec_solid = 3, spec_dotted = 3,
                ltas_solid = 4, ltas_dotted = 4, ts_solid = 5, ts_dotted = 5,
                ts_dashed = 5, ts_dashdot = 5, ci_solid = 5, ci_dotted = 5,
                fourstyles = 5, spag_solid = 13, spag_dotted = 13,
                bar_alone = 6, leak_bar_after_dotted = 6,
                leak_ts_after_dotted = 5)
for (cs in names(TYPE_OF)) {
    check_true(V, paste0("[", cs, "] is a figure of type ", TYPE_OF[[cs]]),
               identical(trn(cs, "type"), as.numeric(TYPE_OF[[cs]])))
}

# ============================================================================
# 3. FOUR PENS, FOUR SIGNATURES
# ============================================================================
# THE CENTRAL CLAIM OF THE CHANGE ORDER, and the reason it is not "the option
# was accepted": four presses of Draw on the same data, differing in one
# option, produce four DIFFERENT PATTERNS OF INK along the same path.
FOUR <- c("ts_solid", "ts_dotted", "ts_dashed", "ts_dashdot")
md5s  <- vapply(FOUR, function(c) trv(c, "png_md5"), character(1))
runs  <- vapply(FOUR, function(c) trn(c, "ink_runs"), numeric(1))
cols  <- vapply(FOUR, function(c) trn(c, "ink_cols"), numeric(1))
gaps  <- vapply(FOUR, function(c) trn(c, "ink_gaps"), numeric(1))
longs <- vapply(FOUR, function(c) trn(c, "longest_ink_run"), numeric(1))

check_true(V, "the four pens make four different files",
           length(unique(md5s)) == 4L && !any(is.na(md5s)))
check_true(V, "four different counts of inked columns",
           length(unique(cols)) == 4L && !any(is.na(cols)))
check_true(V, "four different counts of stroke runs",
           length(unique(runs)) == 4L && !any(is.na(runs)))
check_true(V, "so the four signatures are four distinct pairs",
           nrow(unique(data.frame(cols, runs))) == 4L)

# SOLID IS THE UNBROKEN ONE, and it is unbroken in both senses: one run, and
# no holes anywhere between the first inked column and the last.
check_true(V, "[Solid] crosses the plot in a single unbroken run",
           identical(runs[["ts_solid"]], 1))
check_true(V, "[Solid] leaves no hole in the stroke",
           identical(gaps[["ts_solid"]], 0))
check_true(V, "[Solid] and its one run is every column it inks",
           identical(longs[["ts_solid"]], cols[["ts_solid"]]))

# AND THE OTHER THREE ARE BROKEN, which is the whole of what a user asked for.
# The floor is 50 rather than 2: a stroke broken into a handful of pieces
# would satisfy "more than one run" while looking solid on the page.
for (cs in c("ts_dotted", "ts_dashed", "ts_dashdot")) {
    check_true(V, paste0("[", trv(cs, "stylename"),
                         "] breaks the stroke into many pieces (",
                         runs[[cs]], " runs)"),
               isTRUE(runs[[cs]] > 50))
    check_true(V, paste0("[", trv(cs, "stylename"),
                         "] with a hole between each pair (", gaps[[cs]], ")"),
               isTRUE(gaps[[cs]] > 50))
    check_true(V, paste0("[", trv(cs, "stylename"),
                         "] inks less of the path than Solid does"),
               isTRUE(cols[[cs]] < cols[["ts_solid"]]))
}

# THE ORDER THE GEOMETRY PREDICTS, stated twice over because either statement
# alone could be satisfied by an accident.
#
# HOW MUCH OF THE PATH IS INKED: a dash lays down more than a dash-dot, which
# lays down more than a dot. HOW MANY MARKS IT IS BROKEN INTO: the opposite --
# dots are the most numerous, dashes the fewest, and a dash-dot alternates so
# it sits between them. A pen wired to the wrong Praat command lands in the
# wrong place in one of these two orders.
ord_cols <- c("ts_solid", "ts_dashed", "ts_dashdot", "ts_dotted")
check_true(V, "inked fraction falls Solid > Dashed > Dashed-dotted > Dotted",
           all(diff(cols[ord_cols]) < 0))
ord_runs <- c("ts_dotted", "ts_dashdot", "ts_dashed")
check_true(V, "and mark count falls Dotted > Dashed-dotted > Dashed",
           all(diff(runs[ord_runs]) < 0))

# THE MARGINS, SO THAT "DISTINCT" IS NOT ONE PIXEL. The smallest gap in each
# order is reported in the check's own text: a fixture change that narrowed
# these to nothing would fail here rather than pass on a coincidence.
check_true(V, sprintf("no two inked fractions are within 30 columns (min %g)",
                      min(abs(diff(cols[ord_cols])))),
           min(abs(diff(cols[ord_cols]))) > 30)
check_true(V, sprintf("no two mark counts are within 20 runs (min %g)",
                      min(abs(diff(runs[ord_runs])))),
           min(abs(diff(runs[ord_runs]))) > 20)

# ONE OPTION CHANGED AND NOTHING ELSE. The four figures are the same chart:
# same page, same plot box, same axis. A "style" that moved the box would be
# changing the figure rather than the pen.
for (k in c("png_px", "frame_l", "frame_t", "frame_r", "frame_b")) {
    vals <- vapply(FOUR, function(c) trv(c, k), character(1))
    check_true(V, paste0("the four pens share the same ", k),
               length(unique(vals)) == 1L && !any(is.na(vals)))
}

# ============================================================================
# 4. THE PEN REACHES EVERY TYPE THAT STROKES A SERIES
# ============================================================================
# One pair per type: the same figure twice, differing in the option alone. The
# claim is the same each time -- a dotted pen puts LESS INK on the same path
# than a solid one -- and it is made on the measure that can see that type's
# series.
#
# THE SPAGHETTI PLOT NEEDS THE OTHER THRESHOLD AND THAT IS RECORDED HERE.
# Its strands go through @emlLightenColor at 0.6, which puts them lighter than
# the 50% grey every other ink measurement in this tree thresholds at, so a
# DARK-pixel count of a dotted spaghetti figure and a solid one comes back
# equal to within a handful of pixels while thousands of pixels have changed.
# interior_any_px counts every interior pixel that is not paper, and that is
# what a strand is judged on. Section 4b states the trap as a measurement so
# that a later reader does not "simplify" the two thresholds into one.
PAIRS <- list(
    list(t = "line chart",         s = "ts_solid",   d = "ts_dotted",   m = "interior_ink_px"),
    list(t = "line chart with CI", s = "ci_solid",   d = "ci_dotted",   m = "interior_ink_px"),
    list(t = "pitch contour",      s = "f0_solid",   d = "f0_dotted",   m = "interior_ink_px"),
    list(t = "waveform",           s = "wave_solid", d = "wave_dotted", m = "interior_ink_px"),
    list(t = "spectrum",           s = "spec_solid", d = "spec_dotted", m = "interior_ink_px"),
    list(t = "LTAS",               s = "ltas_solid", d = "ltas_dotted", m = "interior_ink_px"),
    list(t = "spaghetti plot",     s = "spag_solid", d = "spag_dotted", m = "interior_any_px"))

for (p in PAIRS) {
    si <- trn(p$s, p$m); di <- trn(p$d, p$m)
    check_true(V, paste0("[", p$t, "] a dotted pen lays down less ink than a solid one (",
                         di, " < ", si, ")"),
               isTRUE(di < si))
    check_true(V, paste0("[", p$t, "] and the reduction is real, not a rounding (",
                         sprintf("%.1f%%", 100 * (1 - di / si)), ")"),
               isTRUE(di < 0.995 * si))
    check_true(V, paste0("[", p$t, "] so the two options are two different files"),
               !identical(trv(p$s, "png_md5"), trv(p$d, "png_md5")) &&
               !is.na(trv(p$s, "png_md5")))
}

# 4b. THE MEASUREMENT THAT FORCED THE SECOND THRESHOLD.
spag_dark  <- abs(trn("spag_solid", "interior_ink_px") -
                  trn("spag_dotted", "interior_ink_px"))
spag_light <- abs(trn("spag_solid", "interior_any_px") -
                  trn("spag_dotted", "interior_any_px"))
check_true(V, sprintf("a dark-pixel count cannot see a spaghetti strand's pen (%g px)",
                      spag_dark),
           isTRUE(spag_dark < 50))
check_true(V, sprintf("while the light threshold sees it plainly (%g px)", spag_light),
           isTRUE(spag_light > 500))

# ============================================================================
# 5. THE FRAME IS THE ONE THING THE PEN CANNOT REACH
# ============================================================================
# THIS SECTION USED TO CLAIM THE OPPOSITE, AND IT WAS WRONG. The frame is
# drawn AFTER the series, by @emlDrawAxes, so a pen left standing looked
# certain to dash it -- and harness/linestyle/break.sh, driving a tree with
# every @emlResetLineStyle commented out, produced a next figure whose ERROR
# BARS were in pieces and whose frame was perfectly solid.
#
# furniture_pen.praat is why, and it is in the harness so that the claim is a
# measurement rather than a recollection: Praat's `Draw inner box` and
# `Marks ... every:` IGNORE the current line style, exactly as its margin
# commands ignore the current colour (v95 section 12). Section 5b reads it.
#
# WHAT THE CHECKS BELOW ARE FOR, THEN. Not leak detection -- section 6 does
# that, on the ink a leak really does reach. These say that every figure in
# this harness has a whole box around it, and that matters for a reason
# internal to the method: stroke.py FINDS the frame by looking for a dark run
# spanning half the image, so a figure that lost its frame would have its run
# structure measured on whatever else happened to be longest, and every number
# section 3 compares would be about the wrong rectangle.
#
# The comparison is against the box the same figure reported, not against a
# number written down here: the six types put their boxes in different places.
#
# THREE CASES ARE NOT MEASURED HERE AND EACH HAS ITS REASON. `detail` is a
# crop, not a figure. `fourstyles` is a four-panel page with no single frame
# spanning it -- section 11 asserts that. And `replay` is byte-identical to
# recorded_wave by section 7, so its frame IS recorded_wave's frame; the
# driver spends no stroke measurement on it and this file does not pretend to
# have one.
for (cs in setdiff(CASES, c("detail", "fourstyles", "replay"))) {
    fw <- trn(cs, "frame_w"); fh <- trn(cs, "frame_h")
    for (e in c("top", "bottom")) {
        check_true(V, paste0("[", cs, "] the frame's ", e,
                             " edge is one unbroken run"),
                   isTRUE(trn(cs, paste0("frame_", e, "_run")) >= fw))
    }
    for (e in c("left", "right")) {
        check_true(V, paste0("[", cs, "] the frame's ", e,
                             " edge is one unbroken run"),
                   isTRUE(trn(cs, paste0("frame_", e, "_run")) >= fh))
    }
}
# AND THE FRAME OF A DOTTED FIGURE IS THE FRAME OF A SOLID ONE, exactly -- the
# statement the inequality above cannot make on its own. This is the pair-wise
# form of what furniture_pen.praat measures in isolation: whatever the series'
# pen, the box around it is the same box.
for (p in PAIRS) {
    for (e in c("frame_top_run", "frame_left_run")) {
        check_true(V, paste0("[", p$t, "] ", e, " is unchanged by the pen"),
                   identical(trn(p$s, e), trn(p$d, e)))
    }
}

# ----------------------------------------------------------------------------
# 5b. WHY, MEASURED ON A PAGE THIS PLUGIN DID NOT DRAW
# ----------------------------------------------------------------------------
# furniture_pen.praat loads no library. It sets ONE dotted pen and then draws
# two things under it: an ordinary `Draw line` across the plot, and the three
# commands @emlDrawAxes uses for its box and its ticks. If the furniture
# honoured the pen, the box's top edge would be a row of short dashes.
fp_runs  <- trn("furniture_pen", "ink_runs")
fp_long  <- trn("furniture_pen", "longest_ink_run")
fp_top   <- trn("furniture_pen", "frame_top_run")
fp_left  <- trn("furniture_pen", "frame_left_run")
fp_w     <- trn("furniture_pen", "frame_w")
fp_h     <- trn("furniture_pen", "frame_h")
check_true(V, sprintf("under a dotted pen an ordinary stroke comes back in pieces (%g)",
                      fp_runs),
           isTRUE(fp_runs > 100))
check_true(V, sprintf("and none of those pieces is longer than a dot (%g px)", fp_long),
           isTRUE(fp_long <= 3))
check_true(V, "while `Draw inner box` under that same pen is solid across the top",
           isTRUE(fp_top >= fp_w))
check_true(V, "and solid down the side",
           isTRUE(fp_left >= fp_h))
# THE CONCLUSION, STATED AS THE RATIO IT IS. The furniture is not the caller's
# to style, so a broken frame anywhere in this harness is not something a line
# style did.
check_true(V, sprintf("so the box outlives the pen by a factor of %.0f",
                      fp_top / max(1, fp_long)),
           isTRUE(fp_top > 100 * fp_long))

# ============================================================================
# 6. THE RESET, PINNED ON A SECOND FIGURE DRAWN IN THE SAME PROCESS
# ============================================================================
# The change order asks for exactly this: a dashed draw followed by a default
# draw must yield solid, and the check must go red if the reset is removed.
#
# TWO CASES, BECAUSE THERE ARE TWO RESETS AND THEY FAIL DIFFERENTLY.
#
#   leak_ts_after_dotted pins the FORM's: a dotted line chart, then a line
#   chart whose dialog says Solid. @emlGraphsPublishSeriesPens states the pen
#   on every press from the per-type variable, so the second press cannot
#   inherit the first one's choice.
#
#   leak_bar_after_dotted pins the DRAW LAYER's, and it is the stronger of the
#   two: the bar chart sets NO pen at all. It paints rectangles and strokes
#   error bars, and its error bars are what a leaked pen reaches -- measured,
#   on the tree break.sh builds with every reset removed: the bar chart's
#   interior ink falls from 1668 pixels to 625 and its inked columns from four
#   to two, while its frame stays solid because Praat's furniture ignores the
#   pen. Nothing in the bar chart's own code would be wrong.
#
# THE CLAIM IS BYTE IDENTITY WITH A FIGURE DRAWN ALONE, which is the strongest
# form available: not "similar", not "still solid to within a threshold", but
# the same file.
check_true(V, "a bar chart after a dotted line chart is the bar chart drawn alone",
           identical(trv("leak_bar_after_dotted", "png_md5"),
                     trv("bar_alone", "png_md5")) &&
           !is.na(trv("bar_alone", "png_md5")))
check_true(V, "a solid line chart after a dotted one is the solid figure, byte for byte",
           identical(trv("leak_ts_after_dotted", "png_md5"),
                     trv("ts_solid", "png_md5")) &&
           !is.na(trv("ts_solid", "png_md5")))
# AND NOT BECAUSE THE TWO LEAK CASES DREW NOTHING. A blank page is also
# identical to a blank page.
for (cs in c("bar_alone", "leak_bar_after_dotted", "leak_ts_after_dotted",
             "unpublished_alone", "unpublished_after_dotted")) {
    check_true(V, paste0("[", cs, "] has a figure on it, not an empty page"),
               isTRUE(trn(cs, "interior_any_px") > 1000))
}

# THE THIRD RESET, AND THE ONLY ONE THE TWO CASES ABOVE CANNOT SEE. Both of
# them press Draw, and a press states the whole request through
# @emlGraphsPublishSeriesPens -- so both would still be green with the pen
# line taken out of @emlGraphsResetSeriesPens, because the second press
# publishes Solid over the leak.
#
# THE CALLER THAT CANNOT IS THE ONE THAT NEVER PRESSES. A stats wrapper, a
# PraatGen companion, a probe in this tree, a script replayed in the same
# session: each calls @emlDrawTimeSeries directly and reads emlLineStyle
# without ever setting it. Praat cannot unset a variable, so after a dotted
# press the last thing standing between such a caller and a dotted figure is
# the reset. unpublished_after_dotted is that caller after a dotted press;
# unpublished_alone is the same caller with nothing drawn before it, and the
# claim is byte identity between them.
check_true(V, "a caller that states no pen, after a dotted press, draws what it draws alone",
           identical(trv("unpublished_after_dotted", "png_md5"),
                     trv("unpublished_alone", "png_md5")) &&
           !is.na(trv("unpublished_alone", "png_md5")))
# AND THAT FIGURE IS SOLID, not merely repeatable: two dotted figures are
# also identical to each other.
check_true(V, "and what it draws alone is a solid stroke, one run and no holes",
           isTRUE(trn("unpublished_alone", "ink_runs") == 1) &&
           isTRUE(trn("unpublished_alone", "ink_gaps") == 0))

# ============================================================================
# 7. RECORDED, EMITTED, REPLAYED
# ============================================================================
# THE PEN IS NOT AN ARGUMENT OF ANY DRAW PROCEDURE. It is a global the form
# publishes and the draw layer reads, so a recorded call that carried every
# one of @emlDrawWaveform's arguments faithfully would still replay a SOLID
# waveform. @emlRecordCaptureSeriesPens is what makes the record true, and
# these are the three statements that check it did.
blockv <- function(name) {
    hit <- TR$value[TR$case == "block" & TR$key == name]
    if (length(hit) == 1L) hit else NA_character_
}
check_true(V, "the emitted block declares the pen the session drew with",
           identical(blockv("lineStyle"), "3"))
check_true(V, "beside the page setting that was already there",
           identical(blockv("eraseFirst"), "1"))
check_true(V, "and running the emitted script draws the same figure, byte for byte",
           identical(trv("replay", "png_md5"), trv("recorded_wave", "png_md5")) &&
           !is.na(trv("recorded_wave", "png_md5")))
check_true(V, "on the same page rectangle",
           identical(trv("replay", "png_px"), trv("recorded_wave", "png_px")))
# THE RECORDED FIGURE IS ACTUALLY DASHED, which is what makes the replay worth
# anything: if the session had drawn solid, a solid replay would agree.
check_true(V, "and the recorded waveform is a dashed waveform, not a solid one",
           isTRUE(trn("recorded_wave", "interior_ink_px") <
                  trn("wave_solid", "interior_ink_px")))

# ============================================================================
# 8. THE CONTROL EXISTS ON EVERY TYPE THAT STROKES A SERIES
# ============================================================================
FORM  <- file.path(PLUG, "graphs", "eml-graphs-form.praat")
GRAPH <- file.path(PLUG, "graphs", "eml-graph-procedures.praat")
DRAW  <- file.path(PLUG, "graphs", "eml-draw-procedures.praat")
REC   <- file.path(PLUG, "stats",  "eml-record.praat")
rd <- function(p) if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
form_src <- rd(FORM); graph_src <- rd(GRAPH); draw_src <- rd(DRAW)
rec_src  <- rd(REC)
check_true(V, "the four source files this feature lives in are all present",
           all(lengths(list(form_src, graph_src, draw_src, rec_src)) > 0))

# THE SIX TYPES, THEIR NUMBERS AND THEIR VARIABLES. The number is the graphs
# form's graph_type; the variable is the one that type's dialog fills in.
CTRL <- list(list(n = 1,  v = "f0LineStyle",   t = "Pitch Contour"),
             list(n = 2,  v = "wavLineStyle",  t = "Waveform"),
             list(n = 3,  v = "specLineStyle", t = "Spectrum"),
             list(n = 4,  v = "ltasLineStyle", t = "LTAS"),
             list(n = 5,  v = "tsLineStyle",   t = "Line Chart (±CI)"),
             list(n = 13, v = "spLineStyle",   t = "Spaghetti Plot"))

for (c1 in CTRL) {
    check_true(V, paste0("[", c1$t, "] its dialog carries a Line style menu"),
               any(grepl(paste0('optionmenu: "Line style", ', c1$v),
                         form_src, fixed = TRUE)))
    check_true(V, paste0("[", c1$t, "] the publish reads that type's own variable"),
               any(grepl(paste0("^\\s*emlLineStyle = ", c1$v, "\\s*$"), form_src)))
    check_true(V, paste0("[", c1$t, "] on graph_type ", c1$n),
               any(grepl(paste0("^\\s*(els)?if graph_type = ", c1$n, "$"),
                         form_src)))
    # SEEDED BEFORE THE FIRST PRESS, live copy and remembered copy both. The
    # publish states the whole request every press and reads all six by name,
    # so a type whose dialog never opened still has to have an answer.
    check_true(V, paste0("[", c1$t, "] its live variable is seeded Solid"),
               any(grepl(paste0("^", c1$v, " = 1$"), form_src)))
    check_true(V, paste0("[", c1$t, "] and its remembered choice starts Solid"),
               any(grepl(paste0("^prev_", c1$v, " = 1$"), form_src)))
    # REMEMBERED ACROSS PRESSES, which is what makes it per type: the dialog
    # is seeded from prev_ on the way in and writes prev_ on the way out.
    check_true(V, paste0("[", c1$t, "] the dialog comes back with the choice in it"),
               any(grepl(paste0("^\\s*", c1$v, " = prev_", c1$v, "\\s*$"),
                         form_src)) &&
               any(grepl(paste0("^\\s*prev_", c1$v, " = ", c1$v, "\\s*$"),
                         form_src)))
}

# THE PUBLISH IS EXHAUSTIVE AND ITS DEFAULT IS SOLID. Six branches, one per
# type that has a control, and the assignment before them means every OTHER
# type publishes Solid rather than whatever the last press left behind.
pub_from <- grep("^procedure emlGraphsPublishSeriesPens\\s*$", form_src)
pub_to   <- grep("^endproc\\s*$", form_src)
pub <- if (length(pub_from) == 1L) {
    form_src[pub_from:min(pub_to[pub_to > pub_from])]
} else character(0)
check_true(V, "the publish procedure exists exactly once",
           length(pub_from) == 1L)
check_true(V, "its first statement sets the pen to Solid",
           identical(trimws(pub[grep("emlLineStyle", pub)[1]]), "emlLineStyle = 1"))
check_true(V, "and exactly six types override it",
           sum(grepl("^\\s*emlLineStyle = \\w+LineStyle\\s*$", pub)) == 6L)
check_true(V, "so no other graph type can publish anything but Solid",
           length(setdiff(
               sub("^\\s*emlLineStyle = ", "",
                   grep("^\\s*emlLineStyle = \\w+LineStyle\\s*$", pub,
                        value = TRUE)),
               vapply(CTRL, function(c1) c1$v, character(1)))) == 0L)

# AND THE SECOND SERIES CARRIES ITS OWN, DEFAULTING TO DASHED. Two controls,
# not one with a hardcoded partner: the right-hand menu is a separate widget
# bound to a separate variable, and its default is style 3.
check_true(V, "the second series has its own Line style menu",
           any(grepl('optionmenu: "Right line style", tsSecondStyle',
                     form_src, fixed = TRUE)))
check_true(V, "seeded Dashed rather than Solid",
           any(grepl("^tsSecondStyle = 3$", form_src)) &&
           any(grepl("^prev_tsSecondStyle = 3$", form_src)))
check_true(V, "and it is not the primary's variable under another name",
           !any(grepl("tsSecondStyle = tsLineStyle", form_src, fixed = TRUE)))

# ============================================================================
# 9. FOUR WORDS, ONE ORDER, EVERYWHERE
# ============================================================================
# Seven menus -- six types, one of which offers the page twice, plus the
# right-hand series -- and one naming procedure. If any of them listed the
# options in a different order, the index a dialog returns would mean a
# different pen than the one the recorder wrote down.
menu_at <- grep('optionmenu: "(Line style|Right line style)"', form_src)
check_true(V, "every line-style menu in the form is found",
           length(menu_at) >= 7L)
for (i in menu_at) {
    words <- trimws(form_src[(i + 1):(i + 4)])
    check_true(V, paste0("the menu at line ", i,
                         " offers the four styles in order"),
               identical(words, sprintf('option: "%s"', STYLE_WORDS)))
}
# THE NAMING PROCEDURE AGREES WITH THE MENUS. It is what the recorder's
# comment, the panel titles on Ian's figure and this file's own section 2 all
# read the words from.
nm_from <- grep("^procedure emlLineStyleName:", graph_src)
nm <- if (length(nm_from) == 1L) {
    graph_src[nm_from:min(grep("^endproc\\s*$", graph_src)[
        grep("^endproc\\s*$", graph_src) > nm_from])]
} else character(0)
check_true(V, "@emlLineStyleName exists exactly once",
           length(nm_from) == 1L)
for (k in seq_along(STYLE_WORDS)) {
    check_true(V, paste0("@emlLineStyleName calls style ", k, " ",
                         STYLE_WORDS[k]),
               any(grepl(paste0('\\.word\\$ = "', STYLE_WORDS[k], '"'), nm)))
}
check_true(V, "and an out-of-range index falls back to Solid",
           identical(trimws(nm[grep("\\.word\\$ =", nm)[1]]),
                     '.word$ = "Solid"'))

# ============================================================================
# 10. THE DRAW LAYER READS ONE NAME, THROUGH A GUARD
# ============================================================================
# The per-type variables belong to the dialogs. A draw procedure that read
# tsLineStyle directly would draw correctly from the form and abort at
# "Unknown variable" from a PraatGen companion, a harness case or a replayed
# script -- none of which has the form's variables.
for (c1 in CTRL) {
    check_true(V, paste0("the draw layer never reads ", c1$v),
               !any(grepl(c1$v, draw_src, fixed = TRUE)))
}
check_true(V, "it reads the published pen through @emlPrimaryLineStyle",
           any(grepl("^procedure emlPrimaryLineStyle\\s*$", graph_src)) &&
           any(grepl("@emlPrimaryLineStyle", draw_src)))
check_true(V, "and that procedure defaults to Solid when nothing published one",
           any(grepl('variableExists \\("emlLineStyle"\\)', graph_src)))
# NOR DOES IT WRITE THE PUBLISHED PEN BACK. Praat cannot unset a variable, so
# a pen parked in emlLineStyle by the drawing layer would be the pen the next
# figure drew with while its user believed they had asked for nothing.
check_true(V, "the draw layer never assigns the published pen",
           !any(grepl("^\\s*emlLineStyle\\s*=", draw_src)))

# THE RECORDER NAMES IT IN THE BLOCK TABLE. The editable block's variable is
# `lineStyle`; the global it restores is emlLineStyle.
check_true(V, "the recorder maps emlLineStyle to the block's lineStyle",
           any(grepl('\\.lhs\\$ = "emlLineStyle"', rec_src)) &&
           any(grepl('\\.base\\$ = "lineStyle"', rec_src)))
check_true(V, "and captures it through variableExists, for a stats-only caller",
           any(grepl('variableExists \\("emlLineStyle"\\)', rec_src)))

# ============================================================================
# 11. THE FIGURE IAN IS SENT
# ============================================================================
# fourstyles.png is four presses of Draw laid out by the page composition --
# one erase, four panel origins -- and each panel's title is taken from
# @emlLineStyleName, so a renamed option renames the label rather than making
# it a lie. PENS_DETAIL.png is the same four files cropped to one stretch of
# stroke at full resolution and stacked in menu order: at page scale a dash
# and a dash-dot are the same grey line, and the strip is where a reader can
# actually see the difference the option makes.
check_true(V, "the four-pen page was drawn",
           identical(trv("fourstyles", "verdict"), "OK"))
check_true(V, "it is a four-panel page, not a single panel",
           identical(trv("fourstyles", "png_px"), "3600x2400"))
# stroke.py says so in one row rather than in a row of NAs: a page with four
# boxes on it has no single frame spanning half the image.
check_true(V, "and stroke.py records that a four-panel page has no one frame",
           identical(trv("fourstyles", "frame"), "frame_not_found"))
check_true(V, "the full-resolution detail strip was cut from those same files",
           isTRUE(nzchar(trv("detail", "png_md5"))) &&
           isTRUE(grepl("^[0-9]+x[0-9]+$", trv("detail", "png_px"))))

# ============================================================================
# EVERYTHING THE DRIVER RENDERED IS LOOKED AT
# ============================================================================
present <- unique(TR$case[TR$case != "block"])
eml_census(V, "line-style cases", present, CASES)

if (!exists("EML_SUITE")) { eml_report("v96 -- the four pens"); eml_exit() }
