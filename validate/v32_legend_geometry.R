# ============================================================================
# v32_legend_geometry.R -- the plot rectangle is what the user asked for, and
#                          the legend is not allowed to take any of it.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE CONSTRAINT, in the author's words: the dimensions a user types describe
# the DATA AREA, not the data area plus its furniture. If a legend carves
# space out of the 6 x 4 someone asked for, "make my figure square" stops
# being satisfiable -- the plot goes oblong while the file stays square, and
# there is nothing the user can type to get a square plot back. So the plot
# rectangle must be IDENTICAL in every legend placement, and anything the
# legend needs beyond it has to come out of the SAVED IMAGE growing.
#
# Five placements, persisted as `config_legendPlacement`:
#
#     1 Inside plot (the default, and what the plugin has always drawn)
#     2 Right of plot     3 Below plot
#     4 Separate figure   5 None
#
#     harness/legend/run.sh             regenerate the inputs to this script
#     Rscript validate/v32_legend_geometry.R
#
# Input:  <legend>/RESULTS.tsv     46 fields per case; see harness/legend/run.sh
#         <legend>/<case>.png      the rendered figure
#         <legend>/<case>.log      the Info-window transcript
#         plugin/graphs/eml-graph-procedures.praat   read here, statically
#         harness/legend/case.praat                  read here, statically
#
#   <legend> is $EML_LEGEND_DIR, default harness/legend/out (IN-REPO, like
#   harness/stress_out and harness/disclosure/out). A missing artefact is a
#   HARD STOP, not a skip, for the reason v27 gives: "the driver never ran
#   this" is precisely the failure a silently shrinking suite would hide.
#
# WHAT IS DRIVEN. 57 figures. 42 of them are the legend matrix -- three figure
# sizes including a SQUARE one, entry counts 0 / 1 / 3 / 12 / 24, one label
# 480 characters wide, colour and greyscale, and a no-legend control at every
# size -- rendered with no emlLegendPlacement declared at all, which is the
# calling convention every existing caller uses. The other 15 are the five
# placements at twelve entries, one render each per size.
#
# WHERE THE GEOMETRY COMES FROM
# -----------------------------
# From the PIXELS OF THE SAVED PNG, not from what the script believed it
# drew. harness/legend/measure.py finds the plot frame by thresholding at 50%
# grey and taking the rows and columns whose longest dark run spans at least
# half the image -- the four lines of the inner box are the only marks in the
# figure that do, since the gridlines ({0.85} and {0.90}) and the legend
# border ({0.7}) are all lighter than the threshold.
#
# The alternative -- reading @emlDrawLegend's own reported box, as
# harness/stress_cases/legend_cap.praat does -- is the right check for
# CONTAINMENT and the wrong one for GEOMETRY, because both sides of that
# comparison are computed with the same arithmetic and move together. That is
# not hypothetical: v1.23 of @emlDrawLegend measured itself at one font size
# and drew itself at another, so the box the caller was told about was not the
# box on the page, and it looked right because the whole legend moved
# together. The reported box IS recorded and IS used below, but only where
# the question is what the procedure decided, never where the question is
# what the page shows.
#
# THE THREE RECTANGLES, kept apart on purpose
# -------------------------------------------
#   REQUESTED   what the user typed: 6 x 4 inches. Reaches the drawing code
#               as @emlSetAdaptiveTheme's .vpWidth / .vpHeight.
#   PANEL       the rectangle that requested size buys. Under placements 1, 4
#               and 5 it is the whole saved image; under 2 and 3 the image is
#               larger and the panel is a sub-rectangle of it.
#   FRAME       the inner box @emlDrawAxes strokes -- the panel inset by the
#               theme's four margins. This is what measure.py finds, and it is
#               NOT the requested rectangle: at 6 x 4 it is 4.323 x 3.113
#               inches, because 0.84 inches of margin go on each side for the
#               tick labels and the axis title.
#
# So "the plot is what you asked for" is asserted as a COMPOSITION --
# frame + the plugin's own margins == the requested rectangle, one side
# measured in pixels and the other in the inches the user typed -- and not as
# an equality between the frame and 6 x 4, which is false and always was.
#
# WRITTEN ACROSS THE CHANGE, AND MEASURING BOTH SIDES OF IT
# ---------------------------------------------------------
# This file was begun to pin TODAY'S geometry so that the placement work would
# have something to be measured against, and the placement work landed WHILE
# IT WAS BEING WRITTEN: eml-graph-procedures.praat was rewritten under it on
# the afternoon of 8 August 2026. The fixture therefore rendered the same 42
# figures twice, three hours apart, against the tree before and the tree
# after. Both sets of numbers are in this file. What is ASSERTED is the state
# of the tree the script runs against; what is RECORDED beside each assertion
# is what the number was before, so that a pin reads as a before-and-after
# rather than as a bare constant, and so that the old behaviour returning
# fails here.
#
# THE NUMBERS THAT DID NOT MOVE, which is the half that had to be measured
# rather than believed. The placement work's own claim is that placement 1 is
# "the pixels the plugin has always produced". Rendered before and after, at
# three figure sizes, two colour modes and five entry counts:
#
#   the plot frame     6 x 4  -> (251,116)-(1548,1050)      unchanged
#                      5 x 5  -> (209,111)-(1290,1350)      unchanged
#                      10 x 3 -> (254,137)-(2745,774)       unchanged
#   the saved image    still exactly the requested inches at 300 dpi
#   the legend box     at 1, 3, 12 and 24 entries, to the pixel, at every size
#   the column layout  1 x 1, 1 x 3, 1 x 12, 2 x 12 on the default figure
#
# THE NUMBERS THAT MOVED, each named where it is asserted:
#
#   D135 CLOSED (section 6). A single label wider than the frame used to be
#   drawn whole and cut off by the canvas -- an 8208 px box on an 1800 px
#   file, 1735 px of ink to the right of the frame and 25 px of it against the
#   edge of the image. It is now ellipsized to fit, with a NOTE naming the
#   panel width and the font size. The open numbers are kept as the guard.
#
#   THE EMPTY LEGEND (section 5). legendN = 0 used to paint a background and
#   stroke a border -- a 96 x 31 px blank rectangle in the corner of the plot,
#   standing for no series at all. It now draws nothing.
#
#   THE LAYOUT ESTIMATE (section 3). @emlMeasureGraphLayout's legend estimate
#   was a single uncapped column measured at the body font while the procedure
#   drew columns that fitted the frame at the annotation font; on the
#   480-character label it read 30.96 INCHES of legend width on a 6 inch
#   figure. Nothing consumed it, so nothing broke. It is now the same
#   measurement the drawing uses, and section 3 asserts the two agree to a
#   pixel across all 30 renders that drew a box.
#
#   @emlDrawLegend NOW GROWS THE DRAWN EXTENT (section 7c), for placements 2
#   and 3 only. It is a fourth entry in EXPANDERS_ALLOWED, and it is the
#   mechanism the whole design rests on: the room a legend needs outside the
#   plot is bought by growing the EXPORT, never by shrinking the plot.
#
# WHAT GOES RED FROM HERE, and what each failure would mean
# ---------------------------------------------------------
#   [F1] the pinned plot rectangle (sections 3 and 3b). It must not move, in
#        any placement, at any entry count, in either colour mode. This is the
#        author's constraint and there is no acceptable reason for it to fail.
#   [F2] the saved-image relationship (sections 2 and 3b). Placements 1, 4 and
#        5 give exactly the requested inches; 2 widens; 3 heightens. A change
#        here is a change in what a user's figure size means, and it should
#        be argued for in this file before it is made.
#   [F3] EXPANDERS_ALLOWED (section 7c). A fifth entry is a fifth way for a
#        saved file to be bigger than the figure that was asked for.
#   [F4] the renderer's viewport rule (section 7a). Every viewport a legend
#        renderer selects is the rectangle it was handed -- its own parameters
#        or the theme's inner rectangle -- and never a page coordinate, the
#        figure-level drawn extent, or the panel origin.
#   [F5] the estimate-against-the-box agreement (section 3). Two independent
#        numbers for the same rectangle; they disagreed by five figure-widths
#        as recently as this morning.
#   [F6] the D135 guard (section 6): no ink to the right of the frame, nothing
#        against the edge of the canvas, and no ordinary label ellipsized.
#   [F7] the compatibility guarantee (sections 3b and 7a): a caller that
#        declares no emlLegendPlacement gets placement 1, and placement 1 is
#        byte-for-byte the figure it has always drawn.
#
# WHAT THIS FILE DOES NOT COVER. Placement 4 saves a SECOND FILE, and this
# fixture drives @emlDrawLegend directly rather than through the form, so it
# measures only that the legend is parked outside the saved area of the FIRST
# one. The second file is written by the form, and it is not covered here.
# Neither is the dialog: config_legendPlacement's encoding, its clamp on load
# and its optionmenu belong with v31's registry checks, in eml-graphs-form.praat,
# which this script does not read.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

leg_dir <- Sys.getenv("EML_LEGEND_DIR",
                      unset = repo_path("harness", "legend", "out"))
res_p   <- file.path(leg_dir, "RESULTS.tsv")
proc_p  <- repo_path("plugin", "graphs", "eml-graph-procedures.praat")
case_p  <- repo_path("harness", "legend", "case.praat")

if (!file.exists(res_p))
    stop(sprintf("v32: %s missing -- run harness/legend/run.sh first", res_p))
if (!file.exists(case_p))
    stop(sprintf("v32: %s missing", case_p))

# The save resolution the fixture uses, and the plugin's own default. The
# whole file is arithmetic between inches and pixels, so it is named once.
DPI <- 300
# One pixel of tolerance is not enough and three is too loose. The frame's
# edges are STROKED lines of finite width, so the outermost dark pixel of an
# edge sits up to a line-width inside or outside the geometric rectangle the
# theme computed; measured across the matrix the disagreement is 0 to 2 px.
PX_TOL <- 2

res <- read.delim(res_p, header = FALSE, stringsAsFactors = FALSE,
                  quote = "", comment.char = "",
                  col.names = c("case", "vpW", "vpH", "n", "mode", "labels",
                                "legend", "pReq", "pAct", "verdict",
                                "imgW", "imgH", "frameL", "frameT",
                                "frameR", "frameB",
                                "inkLeft", "inkRight", "inkAbove", "inkBelow",
                                "edgeR", "edgeB", "inkDark",
                                "boxX", "boxY", "boxW", "boxH",
                                "cols", "rows", "shown", "hidden",
                                "mL", "mR", "mT", "mB",
                                "innerL", "innerR", "innerT", "innerB",
                                "extMinX", "extMaxX", "extMinY", "extMaxY",
                                "layoutW", "layoutH", "note"))
num <- c("vpW", "vpH", "n", "legend", "pReq", "pAct",
         "imgW", "imgH", "frameL", "frameT",
         "frameR", "frameB", "inkLeft", "inkRight", "inkAbove", "inkBelow",
         "edgeR", "edgeB", "inkDark", "boxX", "boxY", "boxW", "boxH",
         "cols", "rows", "shown", "hidden", "mL", "mR", "mT", "mB",
         "innerL", "innerR", "innerT", "innerB", "extMinX", "extMaxX",
         "extMinY", "extMaxY", "layoutW", "layoutH")
for (k in num) res[[k]] <- suppressWarnings(as.numeric(res[[k]]))

res$frameW <- res$frameR - res$frameL
res$frameH <- res$frameB - res$frameT

# THE EFFECTIVE RESOLUTION OF EACH FILE, and why it is not always 300.
#
# Praat writes an INTEGER number of pixels for a canvas measured in inches, so
# a figure whose drawn extent is 7.1025 inches wide comes out 2130 px rather
# than 2130.75, and every inch of it is 299.89 px rather than 300. That is
# invisible while the extent is a whole number of inches -- which it is for
# every figure the plugin drew before a legend could grow it -- and it is why
# the plot frame of a placement-2 figure measures one pixel narrower than the
# same plot in the same figure at placement 1. The plot is the same size; the
# ruler shrank by four ten-thousandths.
#
# So pixels are converted back to inches through each file's OWN scale before
# any cross-placement comparison, and the pixel pins are stated for the
# figures that are a whole number of inches, where the scale is exactly 300.
res$dpiX <- res$imgW / (res$extMaxX - res$extMinX)
res$dpiY <- res$imgH / (res$extMaxY - res$extMinY)
res$frameWin <- res$frameW / res$dpiX      # frame width,  inches
res$frameHin <- res$frameH / res$dpiY      # frame height, inches
res$frameLin <- res$frameL / res$dpiX
res$frameTin <- res$frameT / res$dpiY

# BLOCK 1 is the legend matrix, rendered with no emlLegendPlacement declared
# at all -- the world every caller written before the placements still lives
# in. BLOCK 2 is the five placements, twelve entries, one render each per
# size. They are kept apart because block 2 deliberately changes the size of
# the saved file and block 1 deliberately does not.
b1 <- res[!is.na(res$pReq) & res$pReq == -1, ]
b2 <- res[!is.na(res$pReq) & res$pReq >= 1, ]

# ---------------------------------------------------------------------------
# THE MATRIX IS ITSELF AN ASSERTION.
#
# Three figure sizes x two colour modes x seven legend variants. If a case is
# added or dropped, that surfaces here rather than in a quietly smaller pass
# count -- v27's rule, and the reason harness/legend/run.sh clears its output
# directory before every run.
# ---------------------------------------------------------------------------
SIZES <- rbind(
  data.frame(size = "6x4",  vpW = 6, vpH = 4,
             # The plugin's default figure, and the size D123 and D135 were
             # both measured on.
             imgW = 1800, imgH = 1200,
             frameL = 251, frameT = 116, frameR = 1548, frameB = 1050),
  data.frame(size = "5x5",  vpW = 5, vpH = 5,
             # SQUARE. The author's objection is stated in this case.
             imgW = 1500, imgH = 1500,
             frameL = 209, frameT = 111, frameR = 1290, frameB = 1350),
  data.frame(size = "10x3", vpW = 10, vpH = 3,
             # Short and wide: a legend below has nowhere to go, a legend to
             # the right has room to spare.
             imgW = 3000, imgH = 900,
             frameL = 254, frameT = 137, frameR = 2745, frameB = 774),
  stringsAsFactors = FALSE)

VARIANTS <- c("g0", "g1", "g3", "g12", "g24", "wide", "none")
MODES    <- c("color", "bw")

# ---------------------------------------------------------------------------
# THE SOURCE PINS. Everything this file asserts about the SHAPE of the code,
# as opposed to the pixels, is declared here so that a reviewer can see the
# whole inventory in one place and a future change has one place to argue
# with.
#
# EXPANDERS_ALLOWED — every procedure permitted to grow the drawn extent, and
# therefore every procedure that can make the saved file bigger than the
# figure the user asked for. @emlExpandDrawnExtent is the single source of
# truth for the box @emlAssertFullViewport selects before the save, so this
# list IS the list of ways a 6 x 4 request becomes a file that is not 6 x 4.
# ---------------------------------------------------------------------------
EXPANDERS_ALLOWED <- c(
  # The panel itself. Every figure's extent starts here: @emlSetAdaptiveTheme
  # reports the outer viewport it just computed, which is exactly the
  # requested rectangle at the panel origin.
  "eml-graph-procedures.praat @emlSetAdaptiveTheme",
  # A second panel, drawn below the figure, whose height the form has already
  # added to the canvas it asked for.
  "eml-annotation-procedures.praat @emlDrawMatrixPanel",
  # Rotated category labels reach below and to the left of the frame; before
  # they were reported here, @emlAssertFullViewport cut them off.
  "eml-graph-procedures.praat @emlDrawCategoricalXAxis",
  # The legend, when its placement puts it outside the plot. This is the
  # mechanism the whole placement design rests on: the plot rectangle is never
  # touched, and the room a legend needs beyond it is bought by growing the
  # EXPORT. A legend placed outside the plot that did NOT appear here would be
  # drawn where the save cannot see it -- which is exactly what D135's
  # overhang did, and why it was clipped rather than visible.
  "eml-graph-procedures.praat @emlDrawLegend")

# LAYOUT_READERS_EXPECTED — how many places read emlLayout_legendWidthInches
# or emlLayout_legendHeightInches. @emlMeasureGraphLayout computes them and
# its own comment says nothing consumes them; this is that claim as a number.
# Section 3 measures what the estimate says on the over-wide label -- 30.96
# inches of legend on a 6 inch figure -- so anything that starts consuming it
# has to handle that first.
LAYOUT_READERS_EXPECTED <- 0L

expected_cases <- as.vector(t(outer(
    paste(rep(SIZES$size, each = length(MODES)), MODES, sep = "_"),
    VARIANTS, paste, sep = "_")))

PLACEMENT_CASES <- as.vector(t(outer(SIZES$size, paste0("p", 1:5),
                                     paste, sep = "_")))

check("v32", "block 1 rendered in full (3 sizes x 2 modes x 7 variants)",
      nrow(b1), length(expected_cases), tol = 0)
check("v32", "block 2 rendered in full (3 sizes x 5 placements)",
      nrow(b2), length(PLACEMENT_CASES), tol = 0)
check("v32", "no duplicate case name", length(unique(res$case)), nrow(res), tol = 0)
check_true("v32", "every case in block 1 is present",
           all(expected_cases %in% b1$case))
check_true("v32", "every placement in block 2 is present",
           all(PLACEMENT_CASES %in% b2$case))
check("v32", "the square case is in the matrix",
      sum(b1$vpW == b1$vpH), 14, tol = 0)
# Block 1 declares no placement at all, and gets placement 1. That is the
# compatibility statement the whole placement design rests on: 42 renders
# through the pre-placement calling convention, every one of them reported by
# @emlDrawLegend as placement 1.
check_true("v32", "block 1 declares no placement and every render used placement 1",
           all(b1$pReq == -1) &&
           all(b1$pAct[b1$legend == 1] == 1))
check_true("v32", "block 2 got the placement it asked for, unclamped",
           nrow(b2) == 15 && all(b2$pAct == b2$pReq))

# ---------------------------------------------------------------------------
# 1. EVERY CASE DREW, AND DREW CLEANLY.
# ---------------------------------------------------------------------------
for (i in seq_len(nrow(res))) {
  cs  <- res$case[i]
  png_p <- file.path(leg_dir, paste0(cs, ".png"))
  log_p <- file.path(leg_dir, paste0(cs, ".log"))
  check_true("v32", paste(cs, "driver verdict is OK"), res$verdict[i] == "OK")
  check_true("v32", paste(cs, "figure written"),
             file.exists(png_p) && file.info(png_p)$size > 0)
  if (!check_true("v32", paste(cs, "log written"), file.exists(log_p))) next
  lg <- readLines(log_p, warn = FALSE)
  check_true("v32", paste(cs, "no Praat error in the transcript"),
             !any(grepl("^Error|not completed|Unknown variable", lg)))
  check_true("v32", paste(cs, "wrote the PNG it reported"),
             any(grepl("^SAVED ", lg)))
}

# ---------------------------------------------------------------------------
# 2. REQUESTED SIZE -> SAVED IMAGE. The relationship, named.
#
# BLOCK 1 ONLY -- the 42 renders that declare no placement, which is what
# every existing caller supplies. For those the drawn extent IS the panel:
# @emlSetAdaptiveTheme reports the outer viewport to @emlExpandDrawnExtent,
# nothing else in these figures reports anything, and @emlAssertFullViewport
# selects exactly that box before the save. So the saved PNG measures the
# requested figure and not one pixel more, at every size, entry count, label
# width and colour mode.
#
# THE ONLY THING ALLOWED TO CHANGE THIS IS A PLACEMENT THAT SAYS SO. Section
# 3b drives all five and asserts which of them may grow the file (2 across,
# 3 down) and which may not (1, 4 and 5). Here the statement is the one a
# user cares about: ask for 6 x 4 and get 1800 x 1200 pixels. A run in which
# these go red is a report that a figure size stopped meaning what it meant.
# ---------------------------------------------------------------------------
for (i in seq_len(nrow(b1))) {
  cs <- b1$case[i]
  check("v32", paste(cs, "saved image width = requested inches x 300 dpi"),
        b1$imgW[i], b1$vpW[i] * DPI, tol = 0)
  check("v32", paste(cs, "saved image height = requested inches x 300 dpi"),
        b1$imgH[i], b1$vpH[i] * DPI, tol = 0)
  # The drawn extent is the panel, at the origin. This is the mechanism
  # behind the two checks above, asserted separately so that a change of
  # mechanism is distinguishable from a change of outcome. [F2]
  check_true("v32", paste(cs, "drawn extent is exactly the requested panel"),
             isTRUE(b1$extMinX[i] == 0 && b1$extMinY[i] == 0 &&
                    b1$extMaxX[i] == b1$vpW[i] &&
                    b1$extMaxY[i] == b1$vpH[i]))
}

# The square case, stated as the author states it: a square figure gives a
# square file. Asserted on the pixels, not on the request.
sq <- b1[b1$vpW == b1$vpH, ]
check_true("v32", "the square request produces a square image, in every variant",
           nrow(sq) == 14 && all(sq$imgW == sq$imgH))
# ...and the FRAME of a square figure is NOT square: 1081 x 1239 px, because
# the four margins differ. Recorded so that nobody satisfies the check above
# by making the frame square, which would mean the panel was no longer 5 x 5.
check_true("v32", "the frame of the square figure is 1081 x 1239 px (not square)",
           all(sq$frameW == 1081) && all(sq$frameH == 1239))

# ---------------------------------------------------------------------------
# 3. THE PLOT RECTANGLE. The load-bearing half.
#
# Two statements, and between them they are the author's constraint:
#
#   (a) COMPOSITION. The measured frame plus the plugin's own four margins is
#       exactly the requested rectangle -- so every inch the user asked for is
#       plot or the plot's own furniture, and nothing else takes any of it. One
#       side of this comparison is pixels off the page; the other is the inches
#       the user typed. It is asserted in POSITION as well as in SIZE, because
#       a frame of the right size in the wrong place would satisfy a size-only
#       check while sitting half outside the figure.
#
#   (b) INVARIANCE. At a given requested size the frame is the same rectangle
#       in every case -- 0 entries or 24, an ordinary label or one 480
#       characters long, colour or greyscale, legend or no legend. This is the
#       constraint in its testable form. Section 3b makes the same statement
#       across the five placements; this one makes it across everything the
#       legend can be asked to contain at a fixed placement.
#
# The no-legend control is what gives (b) its force. `none` is identical to
# `g24` in every input but the @emlDrawLegend call itself, so a frame that
# matched across entry counts but shrank when a legend appeared would still
# fail here.
# ---------------------------------------------------------------------------
for (i in seq_len(nrow(b1))) {
  cs <- b1$case[i]
  # (a) composition, in both dimensions.
  check("v32", paste(cs, "frame + margins = requested width"),
        b1$frameW[i] + (b1$mL[i] + b1$mR[i]) * DPI, b1$vpW[i] * DPI,
        tol = PX_TOL)
  check("v32", paste(cs, "frame + margins = requested height"),
        b1$frameH[i] + (b1$mT[i] + b1$mB[i]) * DPI, b1$vpH[i] * DPI,
        tol = PX_TOL)
  # (a) position: the frame is the requested rectangle inset by the margins
  # the theme computed, on all four sides.
  check("v32", paste(cs, "frame's left edge is the theme's left margin"),
        b1$frameL[i], b1$mL[i] * DPI, tol = PX_TOL)
  check("v32", paste(cs, "frame's top edge is the theme's top margin"),
        b1$frameT[i], b1$mT[i] * DPI, tol = PX_TOL)
  check("v32", paste(cs, "frame's right edge is the theme's inner right"),
        b1$frameR[i], b1$innerR[i] * DPI, tol = PX_TOL)
  check("v32", paste(cs, "frame's bottom edge is the theme's inner bottom"),
        b1$frameB[i], b1$innerB[i] * DPI, tol = PX_TOL)
}

for (s in seq_len(nrow(SIZES))) {
  sz  <- SIZES$size[s]
  grp <- b1[startsWith(b1$case, paste0(sz, "_")), ]
  lab <- sprintf("%s inch figure", sz)

  check("v32", paste(lab, "has all 14 renders"), nrow(grp), 14, tol = 0)

  # (b) invariance. Stated as "one distinct value", so the failure message is
  # about the frame having moved rather than about which case moved it.
  check("v32", paste(lab, "frame width is identical in all 14 renders"),
        length(unique(grp$frameW)), 1, tol = 0)
  check("v32", paste(lab, "frame height is identical in all 14 renders"),
        length(unique(grp$frameH)), 1, tol = 0)
  check("v32", paste(lab, "frame position is identical in all 14 renders"),
        length(unique(paste(grp$frameL, grp$frameT))), 1, tol = 0)

  # The control, named on its own: a legend must not cost the plot anything.
  withL <- grp[grp$case == paste0(sz, "_color_g24"), ]
  noL   <- grp[grp$case == paste0(sz, "_color_none"), ]
  check_true("v32", paste(lab, "24-entry legend and no legend give the same frame"),
             nrow(withL) == 1 && nrow(noL) == 1 &&
             withL$frameW == noL$frameW && withL$frameH == noL$frameH &&
             withL$frameL == noL$frameL && withL$frameT == noL$frameT)
  # ...and the same file. Today the legend is inside the plot, so it cannot
  # change the image either; after the change this is what separates
  # placement 1 from placements 2-4.
  check_true("v32", paste(lab, "24-entry legend and no legend give the same image size"),
             nrow(withL) == 1 && nrow(noL) == 1 &&
             withL$imgW == noL$imgW && withL$imgH == noL$imgH)

  # Colour mode is a palette, not a layout. Asserted because the greyscale
  # swatch is drawn by a different branch with its own ink rule (@emlMarkInk),
  # and a branch that sized its swatch differently would move the box.
  for (v in VARIANTS) {
    a <- grp[grp$case == paste0(sz, "_color_", v), ]
    b <- grp[grp$case == paste0(sz, "_bw_", v), ]
    check_true("v32", sprintf("%s [%s]: greyscale geometry equals colour geometry",
                              lab, v),
               nrow(a) == 1 && nrow(b) == 1 &&
               a$frameW == b$frameW && a$frameH == b$frameH &&
               a$boxW == b$boxW && a$boxH == b$boxH &&
               a$inkRight == b$inkRight)
  }

  # The pinned numbers. Everything above is structural and would survive a
  # theme change that moved all three sizes together; these are the actual
  # pixels of 8 August 2026, so that "the plot rectangle is identical in
  # every legend placement" has a rectangle to be identical TO.
  e <- SIZES[s, ]
  check("v32", paste(lab, "pinned image width (px)"),  grp$imgW[1],  e$imgW, tol = 0)
  check("v32", paste(lab, "pinned image height (px)"), grp$imgH[1],  e$imgH, tol = 0)
  check("v32", paste(lab, "pinned frame left (px)"),   grp$frameL[1], e$frameL, tol = 0)
  check("v32", paste(lab, "pinned frame top (px)"),    grp$frameT[1], e$frameT, tol = 0)
  check("v32", paste(lab, "pinned frame right (px)"),  grp$frameR[1], e$frameR, tol = 0)
  check("v32", paste(lab, "pinned frame bottom (px)"), grp$frameB[1], e$frameB, tol = 0)
}

# @emlMeasureGraphLayout's legend estimate, against the box that was drawn.
#
# emlLayout_legendWidthInches / HeightInches are the form's advance estimate
# of the legend's size, computed before draw dispatch. THE ESTIMATE AND THE
# DRAWN BOX MUST BE THE SAME MEASUREMENT, and this is where that is checked --
# in pixels, one side from the estimate x 300, the other from the box
# @emlDrawLegend reported. Two independent numbers agreeing is worth having:
# they were NOT the same measurement until the placement work made them share
# @emlMeasureLegendPanel, and the divergence was gross rather than subtle --
# measured on this same fixture at 17:10 on 8 Aug 2026, the estimate for the
# 480-character label was 30.96 INCHES of legend width on a 6 inch figure,
# because it modelled a single uncapped column at the body font while the
# procedure drew columns that fitted the frame at the annotation font. Nothing
# consumed it, so nothing broke; anything that had would have been reserving
# five figure-widths of margin.
#
# The tolerance is 1 px, which is rounding: the estimate is inches and the box
# is rounded pixels.
lg_drawn <- b1[b1$boxW > 0 & b1$verdict == "OK", ]
# 42 renders less the six zero-entry cases and the six no-legend controls,
# neither of which draws a box at all.
check_true("v32", "the legend renders that drew a box are the 30 expected",
           nrow(lg_drawn) == 30)
for (i in seq_len(nrow(lg_drawn))) {
  cs <- lg_drawn$case[i]
  check("v32", paste(cs, "layout estimate width matches the drawn box (px)"),
        lg_drawn$layoutW[i] * DPI, lg_drawn$boxW[i], tol = 1)
  check("v32", paste(cs, "layout estimate height matches the drawn box (px)"),
        lg_drawn$layoutH[i] * DPI, lg_drawn$boxH[i], tol = 1)
}
# ...and the estimate never becomes a claim on the plot. Whatever it says, the
# frame is the frame: this is [F4]'s claim made from the rendered evidence
# rather than from the source.
wide64 <- res[res$case == "6x4_color_wide", ]
g24    <- res[res$case == "6x4_color_g24", ]
check_true("v32", "the over-wide label's estimate does not shrink the frame",
           nrow(wide64) == 1 && wide64$frameW == 1297 && wide64$frameH == 934)
check_true("v32", "the 24-entry estimate does not shrink the frame either",
           nrow(g24) == 1 && g24$frameW == 1297 && g24$frameH == 934)

# ---------------------------------------------------------------------------
# 3b. THE FIVE PLACEMENTS, DRIVEN.
#
# This is the constraint itself, measured rather than argued: twelve entries,
# one render per placement per size, against the same figure block 1 renders
# with no placement declared at all.
#
#     1 Inside plot   2 Right of plot   3 Below plot
#     4 Separate figure                 5 None
#
# THE PLOT RECTANGLE IS THE SAME RECTANGLE IN ALL FIVE. What changes is the
# saved image: placement 2 widens it, placement 3 heightens it, and 1, 4 and 5
# leave it exactly the requested size. That is the whole design in two
# sentences, and it is what the checks below are.
#
# WITHIN ONE PIXEL, AND WHY IT IS NOT ZERO. Praat writes an INTEGER number of
# pixels for a canvas measured in inches. A placement-2 figure on a 6 x 4
# request has a drawn extent of 7.1025 inches and comes out 2130 px wide, so
# its effective resolution is 299.89 dpi rather than 300 and the plot frame's
# right edge lands on pixel 1547 where the placement-1 figure puts it on 1548.
# The plot did not move; the ruler shrank by four ten-thousandths. So the
# cross-placement comparison is made in INCHES, through each file's own scale,
# and the pixel comparison carries a one-pixel tolerance with this as its
# reason. The 5 x 5 placement-2 figure is 6.07 inches exactly and lands on a
# whole 1821 px, and its frame is bit-identical to placement 1's -- which is
# the same explanation from the other side.
#
# UNSET IS NOT THE SAME INPUT AS 1. Every caller written before the
# placements -- all thirteen graph types in eml-draw-procedures.praat, every
# stress case in this repo, every PraatGen companion file -- declares no
# emlLegendPlacement at all. Block 1 drives that path 42 times; here the two
# are compared directly, on every measurement the fixture takes, so
# "unchanged for existing callers" is a measurement and not a promise.
# ---------------------------------------------------------------------------
GROWTH <- rbind(
  # size    p2 image      p3 image     what the legend bought, in inches
  data.frame(size = "6x4",  p2W = 2130, p2H = 1200, p3W = 1800, p3H = 1411),
  data.frame(size = "5x5",  p2W = 1821, p2H = 1500, p3W = 1500, p3H = 1752),
  data.frame(size = "10x3", p2W = 3634, p2H = 900,  p3W = 3000, p3H = 1148),
  stringsAsFactors = FALSE)

for (s in seq_len(nrow(SIZES))) {
  sz  <- SIZES$size[s]
  ref <- b1[b1$case == paste0(sz, "_color_g12"), ]     # placement undeclared
  if (!check_true("v32", sprintf("%s: the unset-placement reference rendered", sz),
                  nrow(ref) == 1)) next

  for (p in 1:5) {
    cs  <- sprintf("%s_p%d", sz, p)
    lab <- sprintf("%s placement %d", sz, p)
    r   <- b2[b2$case == cs, ]
    if (!check_true("v32", paste(lab, "rendered"), nrow(r) == 1)) next
    check_true("v32", paste(lab, "drew cleanly"), r$verdict == "OK")

    # --- THE PLOT RECTANGLE. The load-bearing check, five times over.
    check("v32", paste(lab, "plot frame width, in inches, is unchanged"),
          r$frameWin, ref$frameWin, tol = 0.005)
    check("v32", paste(lab, "plot frame height, in inches, is unchanged"),
          r$frameHin, ref$frameHin, tol = 0.005)
    check("v32", paste(lab, "plot frame is in the same place, in inches"),
          r$frameLin + r$frameTin, ref$frameLin + ref$frameTin, tol = 0.005)
    # ...and in pixels, to within the one-pixel rounding described above.
    check_true("v32", paste(lab, "plot frame is within 1 px of placement 1's"),
               abs(r$frameW - ref$frameW) <= 1 &&
               abs(r$frameH - ref$frameH) <= 1 &&
               abs(r$frameL - ref$frameL) <= 1 &&
               abs(r$frameT - ref$frameT) <= 1)
    # The composition, restated for this placement: the plot is still the
    # requested rectangle less the plugin's own margins, whatever the legend
    # did to the file.
    check("v32", paste(lab, "frame + margins is still the requested width"),
          r$frameWin + r$mL + r$mR, r$vpW, tol = 0.01)
    check("v32", paste(lab, "frame + margins is still the requested height"),
          r$frameHin + r$mT + r$mB, r$vpH, tol = 0.01)

    # --- THE SAVED IMAGE. What each placement is allowed to do to the file.
    if (p %in% c(1, 4, 5)) {
      check("v32", paste(lab, "saved image is exactly the requested width"),
            r$imgW, r$vpW * DPI, tol = 0)
      check("v32", paste(lab, "saved image is exactly the requested height"),
            r$imgH, r$vpH * DPI, tol = 0)
      check_true("v32", paste(lab, "the drawn extent is exactly the panel"),
                 r$extMaxX == r$vpW && r$extMaxY == r$vpH)
    } else if (p == 2) {
      check("v32", paste(lab, "saved image is WIDER by the legend's rectangle"),
            r$imgW, GROWTH$p2W[s], tol = 0)
      check("v32", paste(lab, "saved image is the requested HEIGHT"),
            r$imgH, GROWTH$p2H[s], tol = 0)
      check_true("v32", paste(lab, "the drawn extent grew across, not down"),
                 r$extMaxX > r$vpW && r$extMaxY == r$vpH)
      # The legend is beside the plot, so there IS ink to the right of the
      # frame -- and it is the legend, inside the image rather than clipped by
      # it. This is the direction D135's overhang failed in.
      check_true("v32", paste(lab, "the legend is on the page to the right of the plot"),
                 r$inkRight > 0)
    } else {
      check("v32", paste(lab, "saved image is the requested WIDTH"),
            r$imgW, GROWTH$p3W[s], tol = 0)
      check("v32", paste(lab, "saved image is TALLER by the legend's band"),
            r$imgH, GROWTH$p3H[s], tol = 0)
      check_true("v32", paste(lab, "the drawn extent grew down, not across"),
                 r$extMaxY > r$vpH && r$extMaxX == r$vpW)
      check_true("v32", paste(lab, "the legend is on the page below the plot"),
                 r$inkBelow > ref$inkBelow)
    }

    # --- Nothing is ever cut off by the canvas, in any placement. A legend
    # drawn outside the plot that was NOT reported to @emlExpandDrawnExtent
    # would land past the edge of the file and be clipped there, which is
    # precisely what D135's overhang did.
    check("v32", paste(lab, "nothing clipped at the right edge of the canvas"),
          r$edgeR, 0, tol = 0)
    check("v32", paste(lab, "nothing clipped at the bottom edge of the canvas"),
          r$edgeB, 0, tol = 0)
    check("v32", paste(lab, "no entry was dropped"), r$hidden, 0, tol = 0)
    # Every placement that draws a legend draws ALL of it. Placement 5 draws
    # none of it, which is what it is for, so it is asserted at zero rather
    # than exempted -- an exemption would also pass on a placement 2 that had
    # quietly stopped drawing.
    check("v32", paste(lab, "entries shown"), r$shown,
          if (p == 5) 0 else 12, tol = 0)
  }

  # --- Placement 1 is what a caller that declares nothing already gets. Every
  # measurement, not a summary of them: image, frame, box, layout and total
  # ink, so a legend that moved by a pixel or lost a swatch would show.
  p1 <- b2[b2$case == paste0(sz, "_p1"), ]
  check_true("v32", sprintf("%s: declaring placement 1 renders the same file as declaring nothing", sz),
             nrow(p1) == 1 &&
             p1$imgW == ref$imgW && p1$imgH == ref$imgH &&
             p1$frameL == ref$frameL && p1$frameT == ref$frameT &&
             p1$frameR == ref$frameR && p1$frameB == ref$frameB &&
             p1$boxX == ref$boxX && p1$boxY == ref$boxY &&
             p1$boxW == ref$boxW && p1$boxH == ref$boxH &&
             p1$cols == ref$cols && p1$rows == ref$rows &&
             p1$inkDark == ref$inkDark)

  # --- 4 and 5 leave the figure alone. Placement 4 parks the legend off the
  # figure to be saved as a file of its own, and placement 5 does not draw one
  # at all; in both cases the figure that IS saved here has to be the figure
  # with no legend in it, to the last pixel of ink. Compared against block 1's
  # no-legend control, which is the same figure drawn without the call.
  ctl <- b1[b1$case == paste0(sz, "_color_none"), ]
  for (p in c(4, 5)) {
    r <- b2[b2$case == sprintf("%s_p%d", sz, p), ]
    check_true("v32", sprintf("%s placement %d: the figure is the no-legend figure, pixel for pixel",
                              sz, p),
               nrow(r) == 1 && nrow(ctl) == 1 &&
               r$inkDark == ctl$inkDark &&
               r$imgW == ctl$imgW && r$imgH == ctl$imgH)
  }
  # ...and they are NOT the same as each other in what they computed: 4 lays
  # the panel out (it has a second file to write), 5 does not lay anything
  # out at all. Asserted so that "leaves no mark" is not being satisfied by
  # placement 4 quietly becoming placement 5.
  p4 <- b2[b2$case == paste0(sz, "_p4"), ]
  p5 <- b2[b2$case == paste0(sz, "_p5"), ]
  check_true("v32", sprintf("%s: placement 4 still measured a panel, placement 5 did not", sz),
             nrow(p4) == 1 && nrow(p5) == 1 &&
             p4$boxW > 0 && p4$boxH > 0 && p5$boxW == 0 && p5$boxH == 0)
  # Placement 4's panel is parked OFF the figure -- below every pixel of it --
  # which is how it stays out of a save that covers only the drawn extent.
  check_true("v32", sprintf("%s: placement 4's panel is parked outside the saved area", sz),
             nrow(p4) == 1 && p4$boxY > p4$imgH)
}

# ---------------------------------------------------------------------------
# 4. INK OUTSIDE THE FRAME.
#
# measure.py counts dark pixels in four disjoint bands outside the frame. The
# left, above and below bands are never empty and are not meant to be -- the
# axis titles and the tick labels live there. The RIGHT band is the one that
# carries the argument: today the legend is drawn INSIDE the plot, so the
# strip beside the frame is blank in every figure, and is not blank in the two
# per size that trip D135.
#
# edgeR counts dark pixels in the image's last COLUMN. Ink against the edge of
# the canvas is ink that was clipped, which is what a box running off the page
# looks like once the PNG has been written.
# ---------------------------------------------------------------------------
for (i in seq_len(nrow(b1))) {
  cs   <- b1$case[i]
  wide <- b1$labels[i] == "wide"
  if (!wide) {
    check("v32", paste(cs, "no ink to the right of the frame"),
          b1$inkRight[i], 0, tol = 0)
    check("v32", paste(cs, "nothing clipped at the right edge of the canvas"),
          b1$edgeR[i], 0, tol = 0)
  }
  # Nothing is ever clipped at the BOTTOM, in any case: the legend is anchored
  # top-left and D123 keeps it inside the frame's height.
  check("v32", paste(cs, "nothing clipped at the bottom edge of the canvas"),
        b1$edgeB[i], 0, tol = 0)
  # The furniture is present. A figure whose left band went empty has lost its
  # y-axis labels, which would also make the frame-finding suspect.
  check_true("v32", paste(cs, "the frame's own furniture is on the page"),
             b1$inkLeft[i] > 0 && b1$inkAbove[i] > 0 && b1$inkBelow[i] > 0)
}

# ---------------------------------------------------------------------------
# 5. RED PATHS.
#
# Three inputs at the edges of what a legend can be asked to draw. What is
# asserted is what ACTUALLY HAPPENS -- by exact numbers, and by the exact
# message where anything is said at all -- and where nothing is said, the
# silence is asserted, because silence is the finding.
# ---------------------------------------------------------------------------

# --- ZERO ENTRIES. legendN = 0 through @emlDrawLegend.
#
# It draws nothing at all, and says nothing about it. No box, no border, no
# background: the reported box is empty (w = h = 0) and the layout reports
# no columns, no rows, nothing shown and nothing hidden. The figure is the
# figure it would have been with no legend call, and the two are asserted to
# be the same size below.
#
# THIS IS THE RIGHT ANSWER AND IT IS WORTH A CHECK, because the wrong answer
# is cheap to write and hard to see: an empty legend that still painted its
# background and stroked its border would put a small blank rectangle in the
# corner of the plot, standing for no series at all. That is also what
# placement 5 (None) must not become -- an empty box IS a legend, and a
# legend the user turned off has to leave no mark.
zeros <- b1[b1$n == 0 & b1$legend == 1, ]
check("v32", "zero-entry cases rendered", nrow(zeros), 6, tol = 0)
check_true("v32", "zero entries: every case still drew a figure",
           all(zeros$verdict == "OK"))
check_true("v32", "zero entries: nothing refused and nothing warned",
           all(zeros$note == "" | is.na(zeros$note)))
check_true("v32", "zero entries: no box is drawn (w = h = 0)",
           all(zeros$boxW == 0 & zeros$boxH == 0))
check_true("v32", "zero entries: no columns, no rows, nothing shown, nothing hidden",
           all(zeros$cols == 0 & zeros$rows == 0 &
               zeros$shown == 0 & zeros$hidden == 0))
check_true("v32", "zero entries: @emlMeasureGraphLayout reports a zero legend",
           all(zeros$layoutW == 0 & zeros$layoutH == 0))
# The empty legend and the no-legend control must produce the same PAGE. Ink
# is counted over the whole figure, so a stray border or background would
# show here as a different number even if the box were reported empty.
for (s in seq_len(nrow(SIZES))) {
  sz <- SIZES$size[s]
  z  <- res[res$case == paste0(sz, "_color_g0"), ]
  n0 <- res[res$case == paste0(sz, "_color_none"), ]
  check_true("v32", sprintf("zero entries [%s]: the page is identical to drawing no legend",
                            sz),
             nrow(z) == 1 && nrow(n0) == 1 && z$inkDark == n0$inkDark)
}

# --- ONE ENTRY, and the single-column promise.
#
# D123's commitment was that "one entry, or any number that fits in one
# column, gets the identical single-column geometry v1.24 drew, to the last
# decimal". That promise is now load-bearing in a second way: the placement
# work restated the whole layout in inches against a rectangle, and the
# argument that placement 1 is unchanged rests on the box coming out the same
# size. These are the numbers, per size, measured on 8 August 2026.
#
# The 1-entry and 3-entry boxes must be the SAME WIDTH -- the labels are
# "Group 1" and "Group 3", identical rendered widths -- so a layout that
# started sizing the column by the entry count rather than by the widest
# label would show here even though both boxes still fitted.
ones <- b1[b1$n == 1, ]
check("v32", "one-entry cases rendered", nrow(ones), 6, tol = 0)
check_true("v32", "one entry: one column, one row, nothing hidden",
           all(ones$cols == 1 & ones$rows == 1 &
               ones$shown == 1 & ones$hidden == 0))

BOXES <- rbind(
  # size   variant  boxW  boxH  cols rows shown
  data.frame(size = "6x4",  v = "g1",  boxW = 227, boxH = 79,   cols = 1, rows = 1,  shown = 1),
  data.frame(size = "6x4",  v = "g3",  boxW = 227, boxH = 176,  cols = 1, rows = 3,  shown = 3),
  data.frame(size = "6x4",  v = "g12", boxW = 247, boxH = 613,  cols = 1, rows = 12, shown = 12),
  data.frame(size = "6x4",  v = "g24", boxW = 475, boxH = 613,  cols = 2, rows = 12, shown = 24),
  data.frame(size = "5x5",  v = "g1",  boxW = 220, boxH = 76,   cols = 1, rows = 1,  shown = 1),
  data.frame(size = "5x5",  v = "g3",  boxW = 220, boxH = 170,  cols = 1, rows = 3,  shown = 3),
  data.frame(size = "5x5",  v = "g12", boxW = 239, boxH = 590,  cols = 1, rows = 12, shown = 12),
  # The square figure is tall enough to take all 24 in ONE column, where the
  # default figure needs two. Same entries, same palette, different shape.
  data.frame(size = "5x5",  v = "g24", boxW = 239, boxH = 1150, cols = 1, rows = 24, shown = 24),
  data.frame(size = "10x3", v = "g1",  boxW = 266, boxH = 93,   cols = 1, rows = 1,  shown = 1),
  data.frame(size = "10x3", v = "g3",  boxW = 266, boxH = 207,  cols = 1, rows = 3,  shown = 3),
  # ...and the short, wide figure needs two columns at 12 and three at 24,
  # because the height is what runs out first.
  data.frame(size = "10x3", v = "g12", boxW = 535, boxH = 378,  cols = 2, rows = 6,  shown = 12),
  data.frame(size = "10x3", v = "g24", boxW = 805, boxH = 492,  cols = 3, rows = 8,  shown = 24),
  stringsAsFactors = FALSE)

for (i in seq_len(nrow(BOXES))) {
  cs <- sprintf("%s_color_%s", BOXES$size[i], BOXES$v[i])
  r  <- res[res$case == cs, ]
  if (!check_true("v32", paste(cs, "rendered"), nrow(r) == 1)) next
  check("v32", paste(cs, "pinned legend box width (px)"),  r$boxW, BOXES$boxW[i], tol = 0)
  check("v32", paste(cs, "pinned legend box height (px)"), r$boxH, BOXES$boxH[i], tol = 0)
  check("v32", paste(cs, "pinned column count"),           r$cols, BOXES$cols[i], tol = 0)
  check("v32", paste(cs, "pinned rows per column"),        r$rows, BOXES$rows[i], tol = 0)
  # Every entry is on the page. A legend that quietly dropped entries would be
  # D127's silence again: names present, marks unexplained.
  check("v32", paste(cs, "every entry is shown"),          r$shown, BOXES$shown[i], tol = 0)
  check("v32", paste(cs, "nothing folded into '+N more'"), r$hidden, 0, tol = 0)
  # The box is inside the frame it was given -- containment, from the box the
  # procedure reports against the frame the pixels show.
  check_true("v32", paste(cs, "the box is inside the plot frame"),
             r$boxX >= r$frameL && r$boxY >= r$frameT &&
             r$boxX + r$boxW <= r$frameR && r$boxY + r$boxH <= r$frameB)
}

o64 <- res[res$case == "6x4_color_g1", ]
t64 <- res[res$case == "6x4_color_g3", ]
check_true("v32", "1 and 3 entries share a column width; only the height differs",
           o64$boxW == t64$boxW && t64$boxH > o64$boxH)
# The whole matrix truncates nothing. Every one of these figures has room for
# its legend, so if a later change starts folding entries into "+N more" here,
# that is a real behaviour change and it is caught in the count rather than in
# a picture nobody looks at.
check("v32", "nothing in the matrix was truncated into '+N more'",
      sum(res$hidden, na.rm = TRUE), 0, tol = 0)

# ---------------------------------------------------------------------------
# 6. A LABEL WIDER THAN THE WHOLE FRAME -- D135, AND THE DAY IT CLOSED.
#
# THIS SECTION WAS WRITTEN TO PIN D135 OPEN AND HAD TO BE REWRITTEN BEFORE IT
# WAS FIRST COMMITTED, because D135 was closed while it was being written --
# by the placement work, on 8 August 2026, a few hours after this fixture
# first measured it. Both states were rendered and measured HERE, and both
# sets of numbers are kept, because a pin is only readable next to what it
# replaced. This is the same treatment v06 got when D15 was fixed under it:
# rewritten to assert the corrected behaviour, keeping the guard that turns
# red if the old behaviour comes back.
#
# THE DEFECT, as filed. "@emlDrawLegend computes .colsMax from the frame width
# and the widest label; when even one column does not fit it FLOORS .colsMax
# at 1 and computes capacity as though one column had fitted, and the box is
# then drawn whole and runs off the right of the canvas." It was the legend's
# copy of D124, and the one case the D123 multi-column layout deliberately did
# not take.
#
# MEASURED OPEN, 8 Aug 2026, 17:10, one 480-character label among three:
#
#     figure   canvas      legend box   ink right of frame   clipped at edge
#     6 x 4    1800 px      8208 px           1735 px              25 px
#     5 x 5    1500 px      7922 px           1393 px               8 px
#     10 x 3   3000 px      9689 px           2084 px               2 px
#
# The box was four to five times the width of the whole canvas, and the part
# of it past the canvas was not merely outside the frame, it was GONE: the
# legend does not report itself to @emlExpandDrawnExtent under placement 1, so
# @emlAssertFullViewport never saw it and the save cut it off mid-label.
#
# MEASURED CLOSED, the same renders re-run against the placement work: the
# label is ellipsized to fit the panel, the box is inside the frame, there is
# no ink to the right of the frame and nothing at the canvas edge, and a NOTE
# names the panel and the font size and tells the user what to do about it --
# including, now, that there is a placement that does not have this problem.
# Nothing is silent and nothing is lost off the page.
#
# What is asserted below is the CLOSED behaviour, with the open numbers folded
# in as the guard: if the overhang returns, the ink counts stop being zero and
# these fail.
# ---------------------------------------------------------------------------
D135 <- rbind(
  # size   canvas  boxW   panel inches / font pt, as the NOTE states them
  data.frame(size = "6x4",  canvas = 1800, boxW = 1208, panel = "4.04", font = "8.3"),
  data.frame(size = "5x5",  canvas = 1500, boxW = 994,  panel = "3.32", font = "8.0"),
  data.frame(size = "10x3", canvas = 3000, boxW = 2383, panel = "7.97", font = "9.8"),
  stringsAsFactors = FALSE)
D135_NOTE <- paste0(
  "NOTE: legend labels were shortened with an ellipsis — the widest one ",
  "does not fit a %s inch panel at %s pt. Widen the figure, shorten the ",
  "labels, or set Legend placement to Right of plot or Separate figure.")

wides <- b1[b1$labels == "wide", ]
check("v32", "over-wide cases rendered", nrow(wides), 6, tol = 0)
check_true("v32", "over-wide label: the figure still draws",
           all(wides$verdict == "OK"))
check_true("v32", "over-wide label: nothing is folded into '+N more'",
           all(wides$shown == 3 & wides$hidden == 0))

for (i in seq_len(nrow(D135))) {
  sz  <- D135$size[i]
  lab <- sprintf("D135 [%s]", sz)
  for (md in MODES) {
    cs <- paste0(sz, "_", md, "_wide")
    r  <- res[res$case == cs, ]
    if (!check_true("v32", paste(lab, md, "rendered"), nrow(r) == 1)) next
    # CLOSED: the box fits the canvas, and fits the frame.
    check("v32", paste(lab, md, "legend box width (px)"), r$boxW, D135$boxW[i], tol = 0)
    check_true("v32", paste(lab, md, "the box is narrower than the canvas (was 4-5x wider)"),
               r$boxW < D135$canvas[i])
    check_true("v32", paste(lab, md, "the box is inside the plot frame"),
               r$boxX + r$boxW <= r$frameR)
    # CLOSED: no ink escapes the frame, and nothing is cut off by the canvas.
    # These two are the guard. Open, they read 1735 and 25 on the 6 x 4.
    check("v32", paste(lab, md, "no ink to the right of the frame (was 1735 px at 6x4)"),
          r$inkRight, 0, tol = 0)
    check("v32", paste(lab, md, "nothing clipped at the canvas edge (was 25 px at 6x4)"),
          r$edgeR, 0, tol = 0)
    # The shortening is DISCLOSED, in exact wording, with the panel width and
    # the font size that made the decision -- so a user who cannot read a
    # label knows why and what to change. v29's rule: the Info channel always.
    log_p <- file.path(leg_dir, paste0(cs, ".log"))
    lg <- if (file.exists(log_p)) readLines(log_p, warn = FALSE) else character(0)
    check_true("v32", paste(lab, md, "the ellipsis is disclosed in exact house wording"),
               any(trimws(lg) == sprintf(D135_NOTE, D135$panel[i], D135$font[i])))
    # ...and the figure is untouched by any of it, which is what makes this a
    # legend question and not a layout one.
    check_true("v32", paste(lab, md, "the plot frame is unharmed"),
               r$frameW == res$frameW[res$case == paste0(sz, "_", md, "_g3")])
    check("v32", paste(lab, md, "the saved image is still the requested size"),
          r$imgW, D135$canvas[i], tol = 0)
  }
}

# An ordinary label is NOT ellipsized. A shortening rule that fired on
# everything would satisfy every check above and quietly truncate the legends
# of figures that had room -- so the negative direction is asserted too, over
# the whole matrix, by the absence of the NOTE.
non_wide <- b1[b1$labels != "wide" & b1$verdict == "OK", ]
ell <- vapply(non_wide$case, function(cs) {
  p <- file.path(leg_dir, paste0(cs, ".log"))
  if (!file.exists(p)) return(TRUE)
  any(grepl("shortened with an ellipsis", readLines(p, warn = FALSE), fixed = TRUE))
}, logical(1))
check("v32", "no ordinary label is ellipsized (36 renders)", sum(ell), 0, tol = 0)

# ---------------------------------------------------------------------------
# 7. STATIC READING OF THE SOURCE.
#
# Same shape as v27's ban on `goto` in the draw library and v29's ban on
# assigning to emlSubtitle$: the construct is how the defect would get in, so
# the construct is read out of the file rather than driven. No amount of
# rendering catches a NEW placement branch computing a page position for
# itself; reading the file does.
#
# Comments are stripped first, for the reason v27 and v29 both give: every one
# of these rules is DOCUMENTED in the file's own header and changelog, and a
# naive grep fails on the fix's own description. Praat's alternative comment
# marker `;` is stripped with `#`, since the legend code uses both.
# ---------------------------------------------------------------------------
proc_src  <- readLines(proc_p, warn = FALSE)
code_only <- trimws(sub("[#;!].*$", "", proc_src))

# Praat continues a statement onto the next line with a leading "...", and
# every viewport selection in this file is written that way. Any assertion
# about a whole STATEMENT has to fold them first; v29 folds for the same
# reason and says what happened when an earlier draft did not.
fold_continuations <- function(x) {
  out <- character(0)
  for (ln in x) {
    if (startsWith(ln, "...") && length(out))
      out[length(out)] <- paste(out[length(out)], sub("^\\.\\.\\.", "", ln))
    else
      out <- c(out, ln)
  }
  out
}

# The body of a named procedure, comments stripped and continuations folded.
# The name may be followed by a colon, by whitespace, or by nothing at all --
# @emlAssertFullViewport takes no arguments, and a pattern that required a
# separator silently found no body and passed a check about a procedure it had
# never read.
proc_body <- function(src, name) {
  starts <- grep(sprintf("^procedure[[:space:]]+%s([[:space:]:]|$)", name), src)
  if (length(starts) != 1L) return(NULL)
  ends <- grep("^endproc[[:space:]]*$", src)
  to   <- ends[ends > starts[1]][1]
  if (is.na(to)) return(NULL)
  fold_continuations(src[starts[1]:to])
}

# ---------------------------------------------------------------------------
# 7a. THE RENDERER DRAWS INTO THE RECTANGLE IT WAS GIVEN.
#
# This is the rule the brief asks for, and it is written so that it means the
# same thing before and after the placement work. Before, the legend was a
# corner box and the rectangle it was given was implicit -- the theme's inner
# viewport, the panel its caller was drawing into. After, the renderer takes
# an explicit rectangle. In BOTH shapes the rule is one sentence:
#
#     every viewport a legend renderer selects is named by the rectangle it
#     was handed, and never by a page coordinate of its own.
#
# So the four arguments of every `Select ... viewport:` inside the renderer
# chain must each be either
#
#   .something                     a parameter or local of the procedure --
#                                  i.e. the rectangle it was given, or a
#                                  rectangle derived from it
#   emlSetAdaptiveTheme.inner*     the panel, which is the implicit argument
#                                  of the corner-box shape
#
# and never
#
#   a numeric literal              a page coordinate of its own
#   emlDrawnMin/Max X/Y            the FIGURE's extent, which belongs to
#                                  @emlAssertFullViewport alone. A renderer
#                                  that read it could place itself relative to
#                                  everything drawn so far, which is how a
#                                  legend ends up moving when a different
#                                  chart type is drawn first
#   emlPanelOriginX/Y              the multi-panel offset, which is the
#                                  theme's to apply and not the legend's to
#                                  read
#
# THE CHAIN IS DISCOVERED BY NAME, not listed, so that splitting the renderer
# does not silently empty this section: every procedure in the file whose name
# begins emlDrawLegend is in it, and the set that was found is printed in the
# check so a reviewer can see what was actually read.
# ---------------------------------------------------------------------------
all_procs <- sub("^procedure[[:space:]]+([A-Za-z0-9_]+).*$", "\\1",
                 grep("^procedure[[:space:]]+", code_only, value = TRUE))
renderers <- sort(unique(all_procs[startsWith(all_procs, "emlDrawLegend")]))

check_true("v32",
           sprintf("the legend renderer chain is present [%s]",
                   if (length(renderers)) paste(renderers, collapse = ", ")
                   else "NONE FOUND"),
           length(renderers) >= 1L && "emlDrawLegend" %in% renderers)
check("v32", "@emlDrawLegend defined exactly once",
      sum(grepl("^procedure[[:space:]]+emlDrawLegend([[:space:]:]|$)", code_only)),
      1, tol = 0)

THEME_RECT <- c("emlSetAdaptiveTheme.innerLeft", "emlSetAdaptiveTheme.innerRight",
                "emlSetAdaptiveTheme.innerTop", "emlSetAdaptiveTheme.innerBottom")

for (rn in renderers) {
  body <- proc_body(code_only, rn)
  if (!check_true("v32", sprintf("@%s's body is closed", rn), !is.null(body)))
      next
  sel  <- grep("^Select[[:space:]]+(inner|outer)[[:space:]]+viewport:",
               body, value = TRUE)
  args <- sub("^Select[[:space:]]+(inner|outer)[[:space:]]+viewport:", "", sel)
  toks <- unlist(lapply(args, function(a) trimws(strsplit(a, ",")[[1]])))
  toks <- toks[toks != ""]

  check_true("v32", sprintf("@%s selects at least one viewport", rn),
             length(sel) >= 1L)
  check_true("v32",
             sprintf("@%s: every viewport it selects is the rectangle it was given [%s]",
                     rn, if (length(toks)) paste(unique(toks), collapse = " ") else "none"),
             length(toks) > 0 &&
             all(startsWith(toks, ".") | toks %in% THEME_RECT))
  check("v32", sprintf("@%s: no page coordinate in a viewport selection", rn),
        sum(grepl("^[-+]?[0-9]", toks)), 0, tol = 0)
  check("v32", sprintf("@%s never reads the figure-level drawn extent", rn),
        sum(grepl("emlDrawn(Min|Max)[XY]", body)), 0, tol = 0)
  check("v32", sprintf("@%s never reads the panel origin", rn),
        sum(grepl("emlPanelOrigin[XY]", body)), 0, tol = 0)
}

# --- THE COMPATIBILITY GUARANTEE, in the source.
#
# Every caller written before the placements declares no emlLegendPlacement,
# and section 3b measures that all 42 of block 1's renders come back as
# placement 1. This is the same statement read out of the code: the renderer
# reads the global through variableExists, defaults to 1 when it is absent,
# and clamps anything outside 1..5 back to 1 rather than to "no legend". A
# hand-edited config file is the reason the clamp is not an assertion -- v31
# was filed for exactly this shape, a persisted key arriving out of range at a
# dialog that could not express it.
legend_body <- proc_body(code_only, "emlDrawLegend")
if (!is.null(legend_body)) {
  check_true("v32", "@emlDrawLegend reads the placement through variableExists",
             any(grepl('variableExists \\("emlLegendPlacement"\\)', legend_body)))
  check_true("v32", "@emlDrawLegend defaults an undeclared placement to 1",
             any(grepl("^\\.placement = 1$", legend_body)))
  check_true("v32", "@emlDrawLegend clamps a placement below 1 and above 5",
             any(grepl("^if \\.placement < 1$", legend_body)) &&
             any(grepl("^if \\.placement > 5$", legend_body)))
  check_true("v32", "@emlDrawLegend treats an undefined placement as 1, not as none",
             any(grepl("^if \\.placement = undefined$", legend_body)))
}

# ---------------------------------------------------------------------------
# 7b. @emlAssertFullViewport IS THE MECHANISM, so it is pinned as one.
#
# Its body is one statement: select the tracked box. No arithmetic, no
# padding, no margin. Everything in this file rests on it -- the saved PNG is
# the drawn extent because this is what every save path calls, so "the image
# is the figure the user asked for" and "the image grew to hold a legend
# outside the plot" are both statements about @emlExpandDrawnExtent and this.
#
# If a placement were implemented by fattening the box HERE instead of by
# reporting the legend's rectangle to @emlExpandDrawnExtent, every figure
# would grow whether or not it had a legend, and this is where that shows.
# ---------------------------------------------------------------------------
assert_body <- proc_body(code_only, "emlAssertFullViewport")
check_true("v32", "@emlAssertFullViewport's body is closed", !is.null(assert_body))
if (!is.null(assert_body)) {
  stmts <- assert_body[assert_body != "" &
                       !grepl("^(procedure|endproc)", assert_body)]
  check("v32", "@emlAssertFullViewport is one statement", length(stmts), 1, tol = 0)
  check_true("v32", "...and that statement is the tracked box, unmodified",
             length(stmts) == 1 &&
             identical(gsub("[[:space:]]+", "", stmts[1]),
                       "Selectouterviewport:emlDrawnMinX,emlDrawnMaxX,emlDrawnMinY,emlDrawnMaxY"))
}

# ---------------------------------------------------------------------------
# 7c. THE INVENTORY OF EVERYTHING THAT MAY MAKE THE FILE BIGGER THAN THE
#     FIGURE.
#
# @emlExpandDrawnExtent is the single source of truth for the box
# @emlAssertFullViewport selects, so it is the single place where a user's
# 6 x 4 request turns into a file that is not 6 x 4. Every caller is
# attributed to its ENCLOSING PROCEDURE -- the way v29 attributes its
# emlSubtitle$ assignments, so that "who does this" is answered rather than
# "how many" -- and the list is pinned. An entry appearing here without being
# argued for is a fourth thing quietly making the saved image bigger than the
# plot.
# ---------------------------------------------------------------------------
graphs_dir <- repo_path("plugin", "graphs")
graphs_files <- sort(list.files(graphs_dir, pattern = "\\.praat$",
                                full.names = TRUE))
check_true("v32", "plugin/graphs/ holds the files this inventory covers",
           length(graphs_files) >= 4)

expanders <- character(0)
layout_readers <- character(0)
for (gf in graphs_files) {
  g_code <- trimws(sub("[#;!].*$", "", readLines(gf, warn = FALSE)))
  cur <- "<top level>"
  for (i in seq_along(g_code)) {
    if (grepl("^procedure[[:space:]]+", g_code[i]))
      cur <- sub("^procedure[[:space:]]+([A-Za-z0-9_]+).*$", "\\1", g_code[i])
    if (grepl("^@emlExpandDrawnExtent", g_code[i]))
      expanders <- c(expanders, sprintf("%s @%s", basename(gf), cur))
    # A READ of the layout estimate: the name appearing anywhere other than on
    # the left of its own assignment.
    if (grepl("emlLayout_legend(Width|Height)Inches", g_code[i]) &&
        !grepl("^emlLayout_legend(Width|Height)Inches[[:space:]]*=", g_code[i]))
      layout_readers <- c(layout_readers,
                          sprintf("%s @%s:%d", basename(gf), cur, i))
    if (grepl("^endproc[[:space:]]*$", g_code[i])) cur <- "<top level>"
  }
}

check_true("v32",
           sprintf("plugin/graphs/: the drawn extent is grown only by the pinned procedures [found: %s]",
                   if (length(expanders)) paste(sort(unique(expanders)), collapse = " | ")
                   else "none"),
           setequal(unique(expanders), EXPANDERS_ALLOWED))
check("v32", "every extent-growing call is inside a procedure",
      sum(grepl("<top level>", expanders)), 0, tol = 0)

# --- emlLayout_legendWidthInches / HeightInches, and who reads them.
#
# @emlMeasureGraphLayout computes a single-column, uncapped estimate of the
# legend's size and its own comment says nothing consumes it, re-checked
# 8 Aug 2026 with `grep -rn "emlLayout_legend" plugin/ harness/ validate/`.
# A comment is not a check. This is the check, and it is worth having in both
# directions: section 3 has already measured what that estimate says on the
# over-wide label -- 30.96 inches of legend on a 6 inch figure -- so anything
# that starts consuming it has to handle that first, and this is where a
# reviewer is told that it started.
check_true("v32",
           sprintf("emlLayout_legend*Inches readers are the pinned set [found: %s]",
                   if (length(layout_readers))
                       paste(layout_readers, collapse = ", ") else "no reader"),
           length(layout_readers) == LAYOUT_READERS_EXPECTED)
check("v32", "emlLayout_legend*Inches is assigned in exactly six places",
      sum(grepl("^emlLayout_legend(Width|Height)Inches[[:space:]]*=", code_only)),
      6, tol = 0)

# ---------------------------------------------------------------------------
# 7d. THE FIXTURE DRIVES THE REAL PROCEDURE, NOT A COPY OF IT.
#
# v27's rule: a case file that drifted onto a different procedure would still
# render a figure, and every measurement above would still pass, while testing
# nothing.
# ---------------------------------------------------------------------------
case_src <- readLines(case_p, warn = FALSE)
check_true("v32", "the fixture calls @emlDrawLegend itself",
           any(grepl("@emlDrawLegend:", case_src, fixed = TRUE)))
check_true("v32", "the fixture calls @emlSetAdaptiveTheme with the requested size",
           any(grepl("@emlSetAdaptiveTheme: vpW, vpH", case_src, fixed = TRUE)))
check_true("v32", "the fixture saves through the plugin's own pre-save idiom",
           any(grepl("@stressSave:", case_src, fixed = TRUE)))
check_true("v32", "the fixture sets up the legend the way the grouped types do",
           any(grepl("legendPatterned = 1", case_src, fixed = TRUE)) &&
           any(grepl("legendFill\\$\\[i\\]", case_src)))
check_true("v32", "the fixture calls @emlMeasureGraphLayout where the form does",
           any(grepl("@emlMeasureGraphLayout:", case_src, fixed = TRUE)))

if (!exists("EML_SUITE")) { eml_report("v32 legend geometry: the plot is what the user asked for"); eml_exit() }
