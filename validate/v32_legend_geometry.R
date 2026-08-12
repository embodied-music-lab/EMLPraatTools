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
# Input:  <legend>/RESULTS.tsv     72 fields per case; see harness/legend/run.sh
#         <legend>/<case>.png      the rendered figure
#         <legend>/<case>.log      the Info-window transcript
#         plugin/graphs/eml-graph-procedures.praat   read here, statically
#         harness/legend/case.praat                  read here, statically
#         harness/legend/series_case.praat           read here, statically
#
#   <legend> is $EML_LEGEND_DIR, default harness/legend/out (IN-REPO, like
#   harness/stress_out and harness/disclosure/out). A missing artefact is a
#   HARD STOP, not a skip, for the reason v27 gives: "the driver never ran
#   this" is precisely the failure a silently shrinking suite would hide.
#
# WHAT IS DRIVEN. 205 figures, in six blocks, from TWO fixtures.
#
# THE TWO FIXTURES, AND WHY THERE ARE TWO. harness/legend/case.praat is a
# RULER: two violins under a legend of 0 to 24 entries, corner forced to
# "top-left", so that the figure is bit-identical while the legend sweeps and
# every rectangle it measures is attributable to the legend alone. That is the
# right design for measuring a box and it is not a picture of a legend doing
# its job -- the key names ten groups that are not in the figure, no part of
# corner selection is exercised, and a grouped violin has its category labels
# on the x-axis anyway. Blocks 1 to 4 are that fixture, and every geometry pin
# in sections 1 to 9 is measured on it.
#
# harness/legend/series_case.praat is the DEMONSTRATION: a k-series line chart
# and a k-group grouped scatter, drawn through @emlDrawTimeSeries and
# @emlDrawScatterPlot, where the number of legend entries IS the number of
# series, the corner is the one @emlPlaceElements scored, and the key is the
# only way to tell one series from another. Blocks 5 and 6, section 10.
#
#   BLOCK 1, 42 figures: the legend matrix -- three figure sizes including a
#   SQUARE one, entry counts 0 / 1 / 3 / 12 / 24, one label 480 characters
#   wide, colour and greyscale, and a no-legend control at every size --
#   rendered with no emlLegendPlacement declared at all, which is the calling
#   convention every existing caller uses.
#
#   BLOCK 2, 15 figures: the five placements at twelve entries, one render
#   each per size.
#
#   BLOCK 3, 36 figures: the five placements AGAIN, this time with a real
#   four-group post-hoc comparison matrix drawn below the plot, at twelve and
#   at twenty-four entries, per size, each with a legend-free control.
#
#   BLOCK 4, 10 figures: the red paths, named rp_*.
#
#   BLOCK 5, 72 figures, named sr_*: the multi-series coverage pairs. Two
#   graph types x three sizes x three SERIES counts (3, 5, 12) x two headroom
#   arms, each a treatment at placement 1 and its own legend-free control at
#   placement 5 pinned to the treatment's own axis. The measurement is
#   coverPx: pixels that are data-coloured in the control and changed in the
#   treatment -- how much of the data the key sits on, read off the ink.
#
#   BLOCK 6, 30 figures, named sp_*: the five placements again, on the real
#   path, with a real legend and a chosen corner. p5 doubles as the control
#   for p1 and p4.
#
# WHY BLOCKS 3 AND 4 EXIST, which is a question the author asked in one
# sentence: a graph carrying a post-hoc comparison matrix puts that matrix in
# a band BELOW the plot, and placement 3 puts the legend below the plot too --
# do they collide? Reading the code says no, and the reading is correct as far
# as it goes: @emlDrawLegend's placement-3 branch reads totalCanvasHeight and
# starts its band below it, and the form sets that global before it selects
# the outer viewport and before any draw procedure runs. But nothing in the
# tree had ever RENDERED the two together, so that was an argument. Block 3 is
# the rendering, and it settles the argument in the direction the reading
# predicted: at every size, at both counts, in all five placements, the ink
# inside the matrix band is EXACTLY the ink the matrix draws on its own.
#
# WHY BLOCKS 5 AND 6 EXIST, and it is the assertion this file did not have.
# At placement 1 the legend is drawn INSIDE the plot, so it can cover the very
# series it names. Blocks 1 to 4 could not measure that -- the figure under
# their legend is two violins and the key describes twelve groups, so "the
# data it names" is not on the page. Blocks 5 and 6 draw a figure where series
# identity lives nowhere but the key, and count the covered pixels against a
# control render. Both arms are recorded as NUMBERS in RESULTS.tsv rather than
# reduced to a verdict, so a change to @emlComputeAnnotationHeadroom, to
# @emlPlaceElements or to the legend's layout moves a visible figure here.
# Measured 9 August 2026 on the 6 x 4 five-series line chart: 1348 data pixels
# covered with no headroom pass, 0 with one.
#
# BLOCK 4 IS WHERE THE DEFECT WAS. totalCanvasHeight is a FORM local.
# @emlInitDrawingDefaults -- the documented entry point for "standalone
# scripts or PraatGen companion files" -- sets emlLegendPlacement and does not
# set it. A caller outside the form that laid out its own matrix and asked for
# placement 3 got a legend band starting at the plot's own bottom edge, drawn
# straight through the panel: 11636 dark pixels of legend ink inside the
# matrix band on the default figure, and 25564 on the twelve-group one, with
# the panel's omnibus line and its correction subtitle overprinted. Closed in
# eml-graph-procedures.praat v3.29 by settling the page bottom once, from the
# form's global OR the matrix's own published measurement, whichever is lower
# down the page. Section 9 asserts the closed behaviour and keeps the open
# numbers as the guard.
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
#   [F8] DISJOINTNESS (sections 8 and 9), and this is the load-bearing one of
#        the two new sections. The legend band and the comparison-matrix band
#        must not overlap -- in any placement, at any figure size, at any
#        entry count, whether or not the caller published totalCanvasHeight.
#        It is asserted twice over and the two are independent: on the
#        RECTANGLES the two procedures reported, which is arithmetic, and on
#        the PIXELS, by counting the ink inside the matrix band and requiring
#        it to equal, exactly, the count in the same figure drawn with no
#        legend at all. A failure here is a figure in which a reader cannot
#        read one of the two things the figure was drawn to say.
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
                                "layoutW", "layoutH", "note",
                                # The comparison-matrix band. 0 / -1 on every
                                # case that carries no matrix; see the head of
                                # harness/legend/measure_bands.py for what
                                # each ink count is counted over.
                                "mxK", "mxTch", "mxSupp",
                                "mxGap", "mxPanelH", "mxTotal",
                                "panelBot", "mxTop", "mxBot",
                                "mxInk", "lgInk", "strayInk", "belowInk",
                                "inkTop", "inkBot",
                                # The multi-series block. "-" / -1 / NA on
                                # every case that is not one; see BLOCK 5 in
                                # the head of harness/legend/run.sh.
                                "graph", "k", "room", "roomApp", "corner",
                                "axMin", "axMax", "ctl",
                                "dataPx", "coverPx", "diffPx"))
num <- c("mxK", "mxTch", "mxSupp", "mxGap", "mxPanelH", "mxTotal",
         "panelBot", "mxTop", "mxBot", "mxInk", "lgInk", "strayInk",
         "belowInk", "inkTop", "inkBot",
         "k", "room", "roomApp", "axMin", "axMax",
         "dataPx", "coverPx", "diffPx",
         "vpW", "vpH", "n", "legend", "pReq", "pAct",
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
#
# BOTH ARE FILTERED ON mxK == 0, which is the whole of what blocks 1 and 2
# were before blocks 3 and 4 existed: no comparison matrix. Without the
# filter the new legend-free controls, which declare no placement, would fall
# into block 1 and the new placement renders into block 2, and every count
# and every "identical in all 14 renders" below would be quietly measuring a
# different population. Block 3 is the matrix cases that name a placement;
# block 4 is the red paths, which are named rather than counted because each
# one is a different question.
#
# AND ALL FOUR ARE FILTERED ON graph == "-", which is the geometry rig. Blocks
# 5 and 6 are the multi-series fixture (harness/legend/series_case.praat) and
# every one of their cases names a placement, so without this filter they
# would fall into block 2 and every "identical in all 15 renders" below would
# be measuring a population three times its size and of two different shapes.
rig <- res$graph == "-"
b1 <- res[rig & !is.na(res$pReq) & res$pReq == -1 & res$mxK == 0, ]
b2 <- res[rig & !is.na(res$pReq) & res$pReq >= 1 & res$mxK == 0, ]
b3 <- res[rig & res$mxK > 0 & !startsWith(res$case, "rp_"), ]
b4 <- res[rig & startsWith(res$case, "rp_"), ]
# BLOCK 5, the coverage pairs, and BLOCK 6, the five placements on the real
# path. Split on the case-name prefix and not on any measured field, so a case
# that was renamed shows up as a count mismatch rather than as a silently
# smaller population.
b5 <- res[!rig & startsWith(res$case, "sr_"), ]
b6 <- res[!rig & startsWith(res$case, "sp_"), ]
# BLOCK 7, the four non-categorical types at all five placements
# (harness/legend/placement_sweep_case.praat). Same rule: split on the name.
b7 <- res[!rig & startsWith(res$case, "sw_t"), ]

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

# BLOCK 3, and the shape of its inventory. Three sizes x two entry counts x
# (five placements + one legend-free control). The control is what makes the
# block a measurement rather than a picture: it is the same figure with the
# same matrix and WITHOUT the @emlDrawLegend call, so the ink it counts
# inside the matrix band is the matrix's own and nothing else.
MX_COUNTS <- c(12, 24)
MATRIX_CASES <- as.vector(t(outer(
    paste(rep(SIZES$size, each = length(MX_COUNTS)),
          paste0("n", MX_COUNTS), sep = "_"),
    c(paste0("mx_p", 1:5), "mx_ctl"), paste, sep = "_")))

# BLOCK 4, named one by one because each is a different question. The three
# groups share their controls; RP_CTL says which control answers for which
# treatment, and the treatments are compared against it by name below.
RP_CASES <- c("rp_notch_p3", "rp_notch_p2", "rp_notch_p4", "rp_notch_ctl",
              "rp_tall_p3", "rp_tall_p2", "rp_tallnotch_p3", "rp_tall_ctl",
              "rp_supp_p3", "rp_supp_ctl")
# BLOCK 5, the multi-series coverage pairs. Two graph types x three sizes x
# three series counts x two headroom arms, each a TREATMENT and its own
# legend-free CONTROL. The control is not an extra: it is the other half of
# every coverage number, so it is inventoried with the treatments and a
# missing one is a missing measurement rather than a missing picture.
SR_GRAPHS <- c("line", "scatter")
SR_K      <- c(3, 5, 12)
SR_ROOM   <- c(0, 1)
SR_TREAT <- as.vector(t(outer(
    as.vector(t(outer(paste("sr", SR_GRAPHS, sep = "_"), SIZES$size,
                      paste, sep = "_"))),
    as.vector(t(outer(paste0("k", SR_K), paste0("r", SR_ROOM),
                      paste, sep = "_"))),
    paste, sep = "_")))
SR_CASES <- as.vector(rbind(SR_TREAT, paste0(SR_TREAT, "_ctl")))

# BLOCK 6, the five placements on the real path. Two graph types x three
# sizes x five placements, at five series.
SP_CASES <- as.vector(t(outer(
    as.vector(t(outer(paste("sp", SR_GRAPHS, sep = "_"), SIZES$size,
                      paste, sep = "_"))),
    paste0("p", 1:5), paste, sep = "_")))

# BLOCK 7, the four NON-CATEGORICAL types that offer the Legend placement
# menu, at all five placements, one figure size. Section 11 is the check;
# harness/legend/placement_sweep_case.praat is the fixture. Inventoried here
# with the rest so that a type dropped from the sweep is a count mismatch
# rather than a quietly smaller pass total.
SW_TYPES <- c(5, 8, 10, 13)
SW_CASES <- as.vector(t(outer(paste0("sw_t", SW_TYPES), paste0("p", 1:5),
                              paste, sep = "_")))

RP_CTL <- c(rp_notch_p3 = "rp_notch_ctl", rp_notch_p2 = "rp_notch_ctl",
            rp_notch_p4 = "rp_notch_ctl",
            rp_tall_p3 = "rp_tall_ctl", rp_tall_p2 = "rp_tall_ctl",
            rp_tallnotch_p3 = "rp_tall_ctl",
            rp_supp_p3 = "rp_supp_ctl")

check("v32", "block 1 rendered in full (3 sizes x 2 modes x 7 variants)",
      nrow(b1), length(expected_cases), tol = 0)
check("v32", "block 2 rendered in full (3 sizes x 5 placements)",
      nrow(b2), length(PLACEMENT_CASES), tol = 0)
check("v32", "block 3 rendered in full (3 sizes x 2 counts x 5 placements + control)",
      nrow(b3), length(MATRIX_CASES), tol = 0)
check("v32", "block 4 rendered in full (the ten red paths)",
      nrow(b4), length(RP_CASES), tol = 0)
check_true("v32", "every matrix case in block 3 is present",
           all(MATRIX_CASES %in% b3$case))
check_true("v32", "every red path in block 4 is present",
           all(RP_CASES %in% b4$case))
check("v32", "block 5 rendered in full (2 types x 3 sizes x 3 k x 2 arms, paired)",
      nrow(b5), length(SR_CASES), tol = 0)
check_true("v32", "every coverage pair in block 5 is present",
           all(SR_CASES %in% b5$case))
check("v32", "block 6 rendered in full (2 types x 3 sizes x 5 placements)",
      nrow(b6), length(SP_CASES), tol = 0)
check_true("v32", "every placement in block 6 is present",
           all(SP_CASES %in% b6$case))
check("v32", "block 7 rendered in full (4 non-categorical types x 5 placements)",
      nrow(b7), length(SW_CASES), tol = 0)
check_true("v32", "every non-categorical sweep case in block 7 is present",
           all(SW_CASES %in% b7$case))
# The seven blocks partition the file. A case that fell out of all seven -- a
# new name, a mis-typed prefix -- would otherwise be rendered, measured and
# never looked at. This check EARNED ITS KEEP on 11 August 2026: block 7 was
# added to the driver, every one of its own assertions passed, and this line
# was the only thing in the tree that noticed twenty figures had appeared in a
# population nothing had been told about.
# Declared for validate/coverage.R (§19). v32 is the only reader of this
# artefact and its seven blocks partition it, so the union of the blocks IS
# the claim -- built from the block frames themselves rather than restated, so
# a block that stopped being asserted on stops being claimed in the same edit.
eml_claim("v32", "legend_out",
          c(b1$case, b2$case, b3$case, b4$case, b5$case, b6$case, b7$case))
check("v32", "the seven blocks account for every rendered case",
      nrow(b1) + nrow(b2) + nrow(b3) + nrow(b4) + nrow(b5) + nrow(b6) +
      nrow(b7),
      nrow(res), tol = 0)
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

# --- ...and the matrix half of it drives the real thing too. The matrix has
# to be REAL -- @emlBridgeGroupComparison run on a table, not a hand-filled
# set of annotMatrix* globals -- or the panel would be measured against
# content the bridge never produces, and the height that decides where the
# legend band starts is content-driven. The order matters as much: the form
# measures the matrix BEFORE dispatch and renders it AFTER, so the legend is
# drawn while the matrix exists as a measurement and not yet as ink.
check_true("v32", "the fixture's matrix comes from the real bridge",
           any(grepl("@emlBridgeGroupComparison:", case_src, fixed = TRUE)))
check_true("v32", "the fixture sizes the matrix the way the form's pre-dispatch block does",
           any(grepl("@emlMeasureMatrixLayout:", case_src, fixed = TRUE)) &&
           any(grepl("emlMatrixLayout_yMax", case_src, fixed = TRUE)) &&
           any(grepl("emlMatrixLayout_suppressed", case_src, fixed = TRUE)))
check_true("v32", "the fixture renders the matrix through @emlDrawMatrixPanel",
           any(grepl("@emlDrawMatrixPanel:", case_src, fixed = TRUE)))
# The one variable of the red path, read out of the fixture: the global is
# written under a condition, and the outer viewport is NOT -- so the two arms
# differ in whether totalCanvasHeight exists and in nothing else.
check_true("v32", "the fixture writes totalCanvasHeight conditionally",
           any(grepl("^[[:space:]]+totalCanvasHeight = matrixTotal$", case_src)) &&
           any(grepl("^[[:space:]]+if declareTotal = 1$", case_src)))
check_true("v32", "the fixture selects the outer viewport from a local, not from the global",
           any(grepl("Select outer viewport: 0, vpW, 0, matrixTotal",
                     case_src, fixed = TRUE)))

# ---------------------------------------------------------------------------
# 8. THE COMPARISON MATRIX AND THE LEGEND, ON THE SAME PAGE.
#
# THE AUTHOR'S QUESTION, and it is a good one: a graph carrying a post-hoc
# comparison matrix puts that matrix in a band BELOW the plot, and the
# legend's "Below plot" placement wants a band below the plot too. Do they
# collide?
#
# Reading the code says no. @emlDrawLegend's placement-3 branch takes the
# bottom of the page rather than the bottom of the plot, and the graphs form
# has already pushed that past the matrix panel before it selects the outer
# viewport and before any draw procedure runs. That is an argument. This
# section is the rendering: 36 figures, three sizes, twelve and twenty-four
# entries, a REAL four-group one-way ANOVA with Tukey HSD in the panel, every
# one of the five placements, and a legend-free control for each.
#
# THE ANSWER IS NO, AND HERE IS WHAT IT IS MEASURED ON. The load-bearing
# check is stated twice, on two independent kinds of evidence:
#
#   (a) THE RECTANGLES. The band @emlDrawLegend reported and the band
#       @emlDrawMatrixPanel was drawn into do not overlap. Arithmetic, on two
#       numbers each procedure computed for itself.
#
#   (b) THE PIXELS. The count of dark pixels inside the matrix band is
#       EXACTLY the count in the same figure drawn with no legend call at
#       all. Not "close to": exactly. If the legend put one mark inside the
#       panel this number moves, and (a) could still pass -- a rectangle is
#       only as good as the drawing that honours it, and v1.23 of this same
#       procedure reported a box it did not draw.
#
# WHY EXACT AND NOT WITHIN A TOLERANCE. The two files are different sizes, so
# the same panel is written into a slightly different number of pixels and its
# anti-aliased edges do move -- 3256 grey values differ between the 6 x 4
# placement-3 figure and its control. The THRESHOLDED ink count does not: it
# was 17621 both ways on 8 August 2026, and 16365 and 26149 both ways on the
# other two sizes. So the comparison needs no tolerance and is given none,
# and a failure is a real mark in a place it should not be.
#
# AND THE PLOT IS STILL THE PLOT. Two panels below one figure is the case in
# which "the dimensions you typed describe the DATA AREA" is under the most
# pressure, so section 3's composition check is repeated here with BOTH
# present, against the same figure drawn with neither.
# ---------------------------------------------------------------------------
MXBAND <- rbind(
  # size    the band the form's arithmetic produced, and the ink in it
  data.frame(size = "6x4",  gap = 0.1300, panelH = 2.0736, total = 6.2036,
             mxTop = 1239, mxBot = 1861, mxInk = 17621, ctlImgH = 1861),
  data.frame(size = "5x5",  gap = 0.1250, panelH = 1.9938, total = 7.1188,
             mxTop = 1538, mxBot = 2136, mxInk = 16365, ctlImgH = 2135),
  data.frame(size = "10x3", gap = 0.1528, panelH = 2.4369, total = 5.5897,
             mxTop = 946,  mxBot = 1677, mxInk = 26149, ctlImgH = 1676),
  stringsAsFactors = FALSE)
# What placement 3 costs the FILE once a matrix is already under the plot: the
# legend band, on top of a canvas that is already the plot plus the panel.
MXGROWTH <- rbind(
  data.frame(size = "6x4",  n12H = 2072, n24H = 2169, n12W = 2130, n24W = 2359),
  data.frame(size = "5x5",  n12H = 2388, n24H = 2481, n12W = 1821, n24W = 1821),
  data.frame(size = "10x3", n12H = 1925, n24H = 1982, n12W = 3634, n24W = 3904),
  stringsAsFactors = FALSE)

# THE DISJOINTNESS PREDICATE, written once and used by both sections. Two
# horizontal bands are disjoint when one ends at or before the other begins.
# A row with no legend box (placement 5, or a legend-free control) has no
# band and cannot overlap anything, and a row with no matrix band (mxTop = -1,
# the suppressed panel) likewise -- both are TRUE rather than skipped, so a
# case that stopped drawing its legend does not disappear from this check.
bands_disjoint <- function(r) {
  if (is.na(r$mxTop) || r$mxTop < 0 || is.na(r$boxW) || r$boxW <= 0)
      return(TRUE)
  lgTop <- r$boxY
  lgBot <- r$boxY + r$boxH
  isTRUE(lgBot <= r$mxTop || lgTop >= r$mxBot)
}

for (s in seq_len(nrow(SIZES))) {
  sz  <- SIZES$size[s]
  e   <- MXBAND[MXBAND$size == sz, ]
  gr  <- MXGROWTH[MXGROWTH$size == sz, ]
  # The same figure at the same size with NO matrix and NO legend: the
  # reference for "the plot rectangle did not move".
  ref <- b1[b1$case == paste0(sz, "_color_none"), ]
  if (!check_true("v32", sprintf("%s: the no-matrix reference rendered", sz),
                  nrow(ref) == 1)) next

  for (nn in MX_COUNTS) {
    ctl <- b3[b3$case == sprintf("%s_n%d_mx_ctl", sz, nn), ]
    lab0 <- sprintf("%s matrix, %d entries", sz, nn)
    if (!check_true("v32", paste(lab0, "control rendered"), nrow(ctl) == 1))
        next

    # --- The control, pinned. Everything below is measured against it, so
    # what it is has to be stated rather than assumed.
    check("v32", paste(lab0, "control: matrix gap (inches)"),
          ctl$mxGap, e$gap, tol = 0.0001)
    check("v32", paste(lab0, "control: matrix panel height (inches)"),
          ctl$mxPanelH, e$panelH, tol = 0.0001)
    check("v32", paste(lab0, "control: total canvas height (inches)"),
          ctl$mxTotal, e$total, tol = 0.0001)
    check("v32", paste(lab0, "control: matrix band top (px)"),
          ctl$mxTop, e$mxTop, tol = 0)
    check("v32", paste(lab0, "control: matrix band bottom (px)"),
          ctl$mxBot, e$mxBot, tol = 0)
    check("v32", paste(lab0, "control: ink inside the matrix band (px)"),
          ctl$mxInk, e$mxInk, tol = 0)
    check("v32", paste(lab0, "control: the matrix was measured, not suppressed"),
          ctl$mxSupp, 0, tol = 0)
    # The panel is genuinely below the plot and genuinely there: it starts
    # below the plot panel's own bottom edge and it carries ink.
    check_true("v32", paste(lab0, "control: the panel begins below the plot"),
               ctl$mxTop > ctl$panelBot && ctl$mxInk > 0)
    # ...and the legend-free control draws no legend, which is what makes it
    # a control. Stated rather than assumed: a control that had quietly
    # started drawing one would make every comparison below vacuous.
    check_true("v32", paste(lab0, "control: no legend box was drawn"),
               ctl$boxW == 0 && ctl$boxH == 0 && ctl$lgInk == 0)

    for (p in 1:5) {
      cs  <- sprintf("%s_n%d_mx_p%d", sz, nn, p)
      lab <- sprintf("%s matrix, %d entries, placement %d", sz, nn, p)
      r   <- b3[b3$case == cs, ]
      if (!check_true("v32", paste(lab, "rendered"), nrow(r) == 1)) next
      check_true("v32", paste(lab, "drew cleanly"), r$verdict == "OK")
      check_true("v32", paste(lab, "got the placement it asked for"),
                 r$pAct == p)

      # --- (a) THE RECTANGLES DO NOT OVERLAP. [F8]
      check_true("v32", paste(lab, "the legend band and the matrix band are disjoint"),
                 bands_disjoint(r))
      # --- (b) THE PIXELS SAY THE SAME THING, and they say it exactly. [F8]
      check("v32", paste(lab, "ink inside the matrix band is the matrix's own, to the pixel"),
            r$mxInk, ctl$mxInk, tol = 0)
      # Nothing below the plot belongs to neither band. Ink that no procedure
      # reported is ink nobody made room for, and it is how a THIRD thing
      # drifting under the plot would show.
      check("v32", paste(lab, "no ink below the plot outside the two bands"),
            r$strayInk, 0, tol = 0)
      # The three counts are the whole of the ink below the plot. An identity,
      # checked rather than assumed, because measure_bands.py attributes a row
      # that falls in BOTH bands to the matrix -- so if the bands ever did
      # overlap, this is a second place it would surface.
      check("v32", paste(lab, "the band counts account for all the ink below the plot"),
            r$mxInk + r$lgInk + r$strayInk, r$belowInk, tol = 0)

      # --- THE MATRIX IS FULLY INSIDE THE EXPORTED IMAGE. The panel reports
      # itself to @emlExpandDrawnExtent, so the save has to cover it. Within
      # one pixel on the band's own boundary, which is the same rounding
      # section 3b describes: the band's bottom edge is an inch measurement
      # rounded to a pixel and the file's height is the extent rounded to a
      # pixel, and on 5 x 5 and 10 x 3 those two round apart.
      check_true("v32", paste(lab, "the matrix band is inside the saved image"),
                 r$mxBot <= r$imgH + 1)
      # ...and its INK is strictly inside, with no rounding excuse: the panel
      # draws into an inner viewport, so its marks stop short of the band's
      # own edges.
      check_true("v32", paste(lab, "the matrix's ink is inside the saved image"),
                 r$inkBot > 0 && r$inkBot < r$imgH)
      check("v32", paste(lab, "nothing clipped at the bottom edge of the canvas"),
            r$edgeB, 0, tol = 0)
      check("v32", paste(lab, "nothing clipped at the right edge of the canvas"),
            r$edgeR, 0, tol = 0)

      # --- THE PLOT RECTANGLE, WITH BOTH PRESENT. This is the author's
      # constraint under the most pressure it ever comes under: two panels
      # below one figure, and the plot still the size that was typed.
      check_true("v32", paste(lab, "the plot frame is the no-matrix frame, within 1 px"),
                 abs(r$frameW - ref$frameW) <= 1 &&
                 abs(r$frameH - ref$frameH) <= 1 &&
                 abs(r$frameL - ref$frameL) <= 1 &&
                 abs(r$frameT - ref$frameT) <= 1)
      check("v32", paste(lab, "frame + margins is still the requested width"),
            r$frameWin + r$mL + r$mR, r$vpW, tol = 0.01)
      check("v32", paste(lab, "frame + margins is still the requested height"),
            r$frameHin + r$mT + r$mB, r$vpH, tol = 0.01)

      # --- WHAT EACH PLACEMENT DOES TO THE FILE, on top of a canvas that is
      # already the plot plus the panel. 1, 4 and 5 add nothing; 2 widens;
      # 3 heightens. The same rule as section 3b, restated with the matrix in
      # the picture, because the matrix's own growth must not be mistaken for
      # the legend's.
      if (p %in% c(1, 4, 5)) {
        check("v32", paste(lab, "the file is the control's file, exactly"),
              r$imgH, ctl$imgH, tol = 0)
        check("v32", paste(lab, "...and the same width"), r$imgW, ctl$imgW, tol = 0)
        check("v32", paste(lab, "no legend ink below the plot"), r$lgInk, 0, tol = 0)
      } else if (p == 2) {
        check("v32", paste(lab, "the file widened for the legend"),
              r$imgW, if (nn == 12) gr$n12W else gr$n24W, tol = 0)
        check("v32", paste(lab, "...and did not grow downwards"),
              r$imgH, ctl$imgH, tol = 0)
        # The legend is beside the PLOT, which is above the matrix band, so
        # nothing of it lands below the plot at all.
        check("v32", paste(lab, "no legend ink below the plot"), r$lgInk, 0, tol = 0)
      } else {
        check("v32", paste(lab, "the file heightened for the legend band"),
              r$imgH, if (nn == 12) gr$n12H else gr$n24H, tol = 0)
        check("v32", paste(lab, "...and did not grow across"),
              r$imgW, ctl$imgW, tol = 0)
        # THE BAND IS UNDER THE MATRIX, not over it and not beside it. This
        # is the sentence the whole section exists to be able to say.
        check_true("v32", paste(lab, "the legend band starts below the matrix band"),
                   r$boxY >= r$mxBot)
        check_true("v32", paste(lab, "and it carries the legend's ink"),
                   r$lgInk > 0)
      }
      check("v32", paste(lab, "no entry was dropped"), r$hidden, 0, tol = 0)
      check("v32", paste(lab, "entries shown"), r$shown,
            if (p == 5) 0 else nn, tol = 0)
    }
  }
  # The matrix does not depend on the legend, in either direction: the same
  # panel at twelve entries and at twenty-four, in every placement.
  b12 <- b3[b3$case %in% sprintf("%s_n12_mx_p%d", sz, 1:5), ]
  b24 <- b3[b3$case %in% sprintf("%s_n24_mx_p%d", sz, 1:5), ]
  check_true("v32", sprintf("%s: the matrix band is the same whatever the legend holds", sz),
             nrow(b12) == 5 && nrow(b24) == 5 &&
             length(unique(c(b12$mxInk, b24$mxInk))) == 1 &&
             length(unique(c(b12$mxTop, b24$mxTop))) == 1 &&
             length(unique(c(b12$mxBot, b24$mxBot))) == 1)
}

# ---------------------------------------------------------------------------
# 9. RED PATHS: THE MATRIX AT THE EDGES OF WHAT THE PAGE BOTTOM CAN BE.
#
# Section 8 drives the matrix the way the graphs form drives it, and the form
# always publishes totalCanvasHeight. Three things it cannot publish are
# driven here.
#
# --- rp_notch_*  THE GLOBAL IS NOT THERE, AND THIS IS WHERE THE DEFECT WAS.
#
# totalCanvasHeight is a FORM local. @emlInitDrawingDefaults -- whose own
# comment says it is for "standalone scripts or PraatGen companion files" --
# sets emlLegendPlacement and does not set it. So "matrix present, page bottom
# unpublished" is not a contrived input: it is every caller of the drawing
# layer that is not the form.
#
# MEASURED OPEN, 8 Aug 2026, against eml-graph-procedures.praat v3.28, on a
# 6 x 4 figure with a four-group Tukey matrix:
#
#     the matrix band ran 4.130 to 6.204 inches   (px 1239 to 1861)
#     the legend band ran 4.140 to 4.566 inches   (px 1242, height 128)
#     ink inside the matrix band     29257 px, against 17621 for the matrix
#                                    alone -- 11636 pixels of legend drawn
#                                    through the panel
#     the saved file                 1800 x 1861, i.e. the legend band did not
#                                    even grow it, because it was inside the
#                                    matrix's own extent
#
# and on the twelve-group matrix, 90398 against 64834: 25564 pixels. What was
# overprinted was the panel's omnibus line and the subtitle naming the
# correction -- the two lines that say which test produced the p-values.
#
# CLOSED in v3.29 by settling the page bottom once, before the placement
# branch dispatches, from totalCanvasHeight OR the matrix's own published
# measurement, whichever is further down. What is asserted below is the
# closed behaviour, with the open numbers kept as the guard, and the closure
# is stated in the strongest available form: the figure a caller gets WITHOUT
# the global is now identical, in every measurement this fixture takes, to
# the figure the form gets WITH it.
#
# --- rp_tall_*   A PANEL AS DEEP AS THE FIGURE. Twelve groups on a 6 x 4:
# the panel is 3.96 inches under a 4 inch plot, so the legend band starts past
# 8 inches on a figure the user asked for 4 of. The question this answers is
# whether anything is pushed off the canvas -- and the answer is that nothing
# is, because the band is reported to @emlExpandDrawnExtent and Praat's
# picture space is not bounded at the 12 inches the Picture window shows
# (probed to 44 inches on 8 Aug 2026). The file simply gets taller.
#
# --- rp_supp_*   A PANEL THAT WAS MEASURED AND REFUSED. Sixteen groups on a
# 2 x 2 figure: @emlMeasureMatrixLayout sets emlMatrixLayout_suppressed and no
# panel is drawn at all. The band must NOT reserve space for it -- a guard
# that keyed off "annotMatrixN > 0" alone would leave an inch and a half of
# white page between the plot and a legend, on the smallest figure in the
# suite, for a panel that does not exist.
# ---------------------------------------------------------------------------

# Every measurement the fixture takes, for the identity comparisons below.
# Named rather than "all numeric columns" so that adding a column does not
# silently weaken a check that reads as exhaustive.
MEASURED <- c("imgW", "imgH", "frameL", "frameT", "frameR", "frameB",
              "inkLeft", "inkRight", "inkAbove", "inkBelow",
              "edgeR", "edgeB", "inkDark",
              "boxX", "boxY", "boxW", "boxH", "cols", "rows", "shown",
              "extMinX", "extMaxX", "extMinY", "extMaxY",
              "mxTop", "mxBot", "mxInk", "lgInk", "strayInk", "belowInk",
              "inkTop", "inkBot")
same_figure <- function(a, b) {
  nrow(a) == 1 && nrow(b) == 1 &&
    all(vapply(MEASURED, function(k) isTRUE(a[[k]] == b[[k]]), logical(1)))
}

# --- Every red path drew, and drew cleanly. Section 1 has already said so for
# the whole file; this says it again over block 4 alone, so a red path that
# stopped rendering reads as a red path rather than as a count.
check_true("v32", "every red path drew cleanly",
           nrow(b4) == length(RP_CASES) && all(b4$verdict == "OK"))
check_true("v32", "every red path set up a matrix", all(b4$mxK >= 2))
# ...and the three controls really are legend-free, which is what the ink
# comparisons below rest on.
check_true("v32", "the red-path controls draw no legend",
           all(b4$boxW[endsWith(b4$case, "_ctl")] == 0))

# --- THE LOAD-BEARING CHECK, over every red path at once: disjoint bands and
# the matrix's own ink, unchanged. [F8]
for (cs in names(RP_CTL)) {
  r   <- b4[b4$case == cs, ]
  ctl <- b4[b4$case == RP_CTL[[cs]], ]
  if (!check_true("v32", sprintf("red path %s and its control rendered", cs),
                  nrow(r) == 1 && nrow(ctl) == 1)) next
  check_true("v32", sprintf("red path %s: the legend band and the matrix band are disjoint", cs),
             bands_disjoint(r))
  check("v32", sprintf("red path %s: ink inside the matrix band is the matrix's own", cs),
        r$mxInk, ctl$mxInk, tol = 0)
  check("v32", sprintf("red path %s: no ink below the plot outside the two bands", cs),
        r$strayInk, 0, tol = 0)
  check("v32", sprintf("red path %s: the band counts account for the ink below the plot", cs),
        r$mxInk + r$lgInk + r$strayInk, r$belowInk, tol = 0)
  check("v32", sprintf("red path %s: nothing clipped at the bottom of the canvas", cs),
        r$edgeB, 0, tol = 0)
  check("v32", sprintf("red path %s: nothing clipped at the right of the canvas", cs),
        r$edgeR, 0, tol = 0)
  check_true("v32", sprintf("red path %s: every mark below the plot is inside the file", cs),
             r$inkBot < r$imgH)
  check("v32", sprintf("red path %s: nothing folded into '+N more'", cs),
        r$hidden, 0, tol = 0)
}

# --- rp_notch: THE GLOBAL IS ABSENT AND IT NO LONGER MATTERS.
notch3  <- b4[b4$case == "rp_notch_p3", ]
notchC  <- b4[b4$case == "rp_notch_ctl", ]
form3   <- b3[b3$case == "6x4_n12_mx_p3", ]
check_true("v32", "rp_notch_p3 declared no totalCanvasHeight",
           nrow(notch3) == 1 && notch3$mxTch == 0 && notch3$mxK == 4)
check_true("v32", "6x4_n12_mx_p3 did declare one",
           nrow(form3) == 1 && form3$mxTch == 1)
# THE CLOSURE, in its strongest form: same figure, both ways.
check_true("v32",
           "placement 3 with a matrix is the same figure with and without totalCanvasHeight",
           same_figure(notch3, form3))
# The pinned numbers, closed. Open they were imgH 1861, boxY 1242, mxInk 29257.
check("v32", "rp_notch_p3: saved image height (was 1861 with the band on the panel)",
      notch3$imgH, 2072, tol = 0)
check("v32", "rp_notch_p3: legend band top (px) (was 1242, inside the panel)",
      notch3$boxY, 1903, tol = 0)
check("v32", "rp_notch_p3: ink inside the matrix band (was 29257)",
      notch3$mxInk, 17621, tol = 0)
check_true("v32", "rp_notch_p3: the band starts below the matrix band, not inside it",
           notch3$boxY >= notch3$mxBot && notch3$mxBot == 1861)
check("v32", "rp_notch_p3: legend ink below the plot (was 0 -- it was all on the panel)",
      notch3$lgInk, 12451, tol = 0)
# THE GUARD. 11636 px is the defect, stated as the number that must stay
# absent: legend ink counted inside the matrix band.
check("v32", "rp_notch_p3: no legend ink inside the matrix band (was 11636 px)",
      notch3$mxInk - notchC$mxInk, 0, tol = 0)

# Placements 2 and 4 are the control for the claim above: they do not consult
# the page bottom at all, so the missing global cannot have changed them --
# and both were bit-identical before and after v3.29.
for (p in c(2, 4)) {
  a <- b4[b4$case == sprintf("rp_notch_p%d", p), ]
  b <- b3[b3$case == sprintf("6x4_n12_mx_p%d", p), ]
  check_true("v32",
             sprintf("placement %d with a matrix is unaffected by totalCanvasHeight", p),
             same_figure(a, b))
}
check_true("v32", "rp_notch_ctl is the same page as the form-driven control",
           same_figure(notchC, b3[b3$case == "6x4_n12_mx_ctl", ]))
# Placement 4 parks its panel off the figure, and a matrix under the plot does
# not change that: the park is twelve inches clear of the page bottom or 24,
# whichever is lower, and on this figure the floor still wins.
np4 <- b4[b4$case == "rp_notch_p4", ]
check_true("v32", "rp_notch_p4: the parked legend is still outside the saved area",
           nrow(np4) == 1 && np4$boxY == 7242 && np4$boxY > np4$imgH)

# --- rp_tall: A PANEL AS DEEP AS THE PLOT ABOVE IT.
tall3 <- b4[b4$case == "rp_tall_p3", ]
tallN <- b4[b4$case == "rp_tallnotch_p3", ]
tallC <- b4[b4$case == "rp_tall_ctl", ]
check_true("v32", "rp_tall: twelve groups make a panel almost as deep as the figure",
           nrow(tallC) == 1 && abs(tallC$mxPanelH - 3.9563) < 0.0001 &&
           abs(tallC$mxTotal - 8.0863) < 0.0001)
check("v32", "rp_tall_p3: the legend band starts past the panel (px)",
      tall3$boxY, 2468, tol = 0)
check_true("v32", "rp_tall_p3: the band is below a 2426 px matrix band",
           tall3$mxBot == 2426 && tall3$boxY >= tall3$mxBot)
# NOTHING IS PUSHED OFF THE CANVAS. A 4 inch figure saved 9.11 inches tall,
# and every mark of both panels inside it.
check("v32", "rp_tall_p3: the file grew to hold plot, panel and band",
      tall3$imgH, 2734, tol = 0)
check("v32", "rp_tall_p3: the exported extent is 9.1159 inches",
      tall3$extMaxY, 9.1159, tol = 0.0001)
check_true("v32", "rp_tall_p3: the last mark on the page is inside the page",
           tall3$inkBot == 2674 && tall3$inkBot < tall3$imgH)
# ...and the same, with the global unpublished. Open, this figure put 25564 px
# of legend on the panel and saved 1800 x 2425.
check_true("v32",
           "rp_tallnotch_p3: the deep panel is cleared with no totalCanvasHeight either",
           same_figure(tallN, tall3))
check("v32", "rp_tallnotch_p3: ink inside the matrix band (was 90398)",
      tallN$mxInk, tallC$mxInk, tol = 0)
check("v32", "rp_tallnotch_p3: saved image height (was 2425)",
      tallN$imgH, 2734, tol = 0)
# Placement 2 beside a deep panel: the legend goes to the RIGHT of the plot,
# the matrix stays under it, and the file grows in both directions -- across
# for the legend and down for the panel. Neither growth is the other's.
tall2 <- b4[b4$case == "rp_tall_p2", ]
check_true("v32", "rp_tall_p2: the file widened for the legend and deepened for the panel",
           nrow(tall2) == 1 && tall2$imgW == 2359 && tall2$imgH == 2425 &&
           tall2$imgH == tallC$imgH && tall2$imgW > tallC$imgW)
check("v32", "rp_tall_p2: no legend ink below the plot at all",
      tall2$lgInk, 0, tol = 0)

# --- rp_supp: A PANEL THAT WAS REFUSED RESERVES NOTHING.
supp3 <- b4[b4$case == "rp_supp_p3", ]
suppC <- b4[b4$case == "rp_supp_ctl", ]
check_true("v32", "rp_supp: sixteen groups on a 2 x 2 figure are suppressed",
           nrow(supp3) == 1 && supp3$mxSupp == 1 && supp3$mxK == 16)
check_true("v32", "rp_supp: no panel was drawn, and no band was reported",
           supp3$mxTop == -1 && supp3$mxBot == -1 && supp3$mxInk == 0)
check_true("v32", "rp_supp: the control's page is empty below the plot",
           nrow(suppC) == 1 && suppC$belowInk == 0 && suppC$inkBot == -1)
# The band sits directly under the plot, one boxInsetInches down -- exactly
# where it sits on a figure that never had a matrix at all. panelBot is 600 px
# (2 inches at 300 dpi) and the band's top is 636.
check_true("v32", "rp_supp: the legend band sits directly below the plot",
           supp3$boxY == 636 && supp3$panelBot == 600 &&
           supp3$boxY - supp3$panelBot < 0.2 * DPI)
check_true("v32", "rp_supp: the file grew by the band and nothing else",
           supp3$imgH == 912 && suppC$imgH == 600 && supp3$imgW == suppC$imgW)
check_true("v32", "rp_supp: the band is on the page, not off the bottom of it",
           supp3$lgInk > 0 && supp3$inkBot < supp3$imgH)

# ---------------------------------------------------------------------------
# 9b. THE PAGE BOTTOM, READ OUT OF THE SOURCE.
#
# Section 9 measures that placements 3 and 4 clear whatever is below the plot.
# This is the same statement about the SHAPE of the code, in v27's and v29's
# style: the quantity is computed ONCE and both branches read it, so a sixth
# placement, or a future edit to one branch, cannot leave the other reading a
# stale rule. The failure this catches is the one that was there: two branches
# each consulting the page bottom in their own words, and only one of them
# ever being corrected.
# ---------------------------------------------------------------------------
if (!is.null(legend_body)) {
  check("v32", "@emlDrawLegend computes the page bottom exactly once",
        sum(grepl("^\\.pageBottom = emlSetAdaptiveTheme\\.outerBottom$",
                  legend_body)), 1, tol = 0)
  # It is SEEDED with the plot's own bottom edge and every later write is a
  # widening comparison, so no source can ever pull the band up above the
  # plot. Two writes, both of them behind a `>` test.
  check("v32", "every later write to the page bottom is a widening one",
        sum(grepl("^\\.pageBottom = ", legend_body)), 3, tol = 0)
  check("v32", "...and each of the two is guarded by a comparison against it",
        sum(grepl("^if (totalCanvasHeight|\\.matrixBottom) > \\.pageBottom$",
                  legend_body)), 2, tol = 0)
  check_true("v32", "the placement-3 band starts from the page bottom",
             any(grepl("^\\.below = \\.pageBottom$", legend_body)))
  check_true("v32", "the placement-4 park clears the page bottom",
             any(grepl("^\\.park = \\.pageBottom \\+ 12$", legend_body)))
  # NEITHER PLACEMENT BRANCH READS totalCanvasHeight ANY MORE. The form's
  # global appears in the page-bottom block and nowhere else -- four mentions,
  # which are the variableExists test, the undefined test, the comparison and
  # the assignment. A fifth would be a second rule, and a second rule is how
  # placements 3 and 4 came to disagree in the first place.
  check("v32", "totalCanvasHeight is read only where the page bottom is settled",
        sum(grepl("totalCanvasHeight", legend_body)), 4, tol = 0)
  # The matrix half of the answer, and the guard on it: the measurement is
  # consulted through variableExists, so a caller that publishes nothing at
  # all still draws, and the suppressed flag is honoured so a refused panel
  # reserves no space.
  check_true("v32", "the page bottom consults the matrix's own measurement",
             any(grepl('variableExists \\("emlMatrixLayout_yMax"\\)', legend_body)) &&
             any(grepl('variableExists \\("annotMatrixN"\\)', legend_body)))
  check_true("v32", "...and honours a suppressed panel",
             any(grepl("emlMatrixLayout_suppressed", legend_body)))
}


# ---------------------------------------------------------------------------
# 10. THE LEGEND OVER THE SERIES IT NAMES.  Blocks 5 and 6.
#
# WHAT WAS WRONG WITH EVERYTHING ABOVE, STATED PLAINLY. Sections 1 to 9 are
# measured on harness/legend/case.praat, which draws TWO VIOLINS and asks for
# a legend of up to TWENTY-FOUR entries, with the corner hardcoded to
# "top-left". Every rectangle they assert is correct. None of them can say
# anything about a legend doing its job, for three reasons that are properties
# of that fixture and not of the plugin:
#
#   (a) THE KEY DESCRIBED SERIES THAT WERE NOT IN THE FIGURE. Two violins,
#       twelve entries. "Does the legend cover the data it names" was not
#       merely untested — it was not expressible, because the data it named
#       was not on the page.
#   (b) THE CORNER WAS FORCED. The product does not force it: seven draw
#       procedures set `.legendCorner$ = emlPlaceElements.corner1$` and pass
#       that. A fixture that hardcodes "top-left" exercises no part of the
#       scoring, so no claim about which corner the product picks could be
#       supported by any figure above.
#   (c) A VIOLIN DOES NOT NEED A LEGEND. On a grouped violin or box the
#       x-axis already carries the category labels. The key is redundant
#       furniture there, and a redundant key covering the data costs the
#       reader nothing.
#
# harness/legend/series_case.praat is the fixture that can be wrong. A
# k-series LINE CHART (@emlDrawTimeSeries, graph type 5) and a k-group
# GROUPED SCATTER (@emlDrawScatterPlot, graph type 8), drawn through the
# product's own graph-level procedures, where series identity has no home but
# the key: the lines cross, so position does not name them, and the x-axis
# carries time. The number of legend entries IS the number of series, and the
# corner is whatever @emlPlaceElements scored.
#
# HOW COVERAGE IS MEASURED, and why it needs two renders. Each treatment has
# its own CONTROL: the same figure, ON THE SAME AXIS, with
# emlLegendPlacement = 5 so @emlDrawLegend draws nothing. Placement 5 is a
# single `.draw = 0` inside that procedure — the axis, the quadrant scan, the
# chosen corner and the drawn extent are all computed identically — so the two
# files differ in legend ink and in nothing else. coverPx is the count of
# pixels that are DATA-COLOURED in the control and CHANGED in the treatment.
# See the head of harness/legend/measure_cover.py for why data ink is
# identified by chroma and why the count is taken inside the plot frame.
#
# The reported rectangles are not consulted anywhere in this section. That is
# the same discipline section 8 applies to the matrix band, and for the same
# reason: v1.23 of @emlDrawLegend reported a box it did not draw.
#
# coverPx IS A LOWER BOUND, and it is worth knowing why. As of 9 August 2026
# an on-figure box's background is drawn at alpha 0.702 — an alpha sprite
# where the platform has one, a STIPPLE screen on Linux, which is what this
# harness renders on. A legend sitting on data therefore changes roughly seven
# pixels in ten and lets three show through as dots, and this measure counts
# the seven. Every use it is put to below survives that: a count of zero still
# means no overlap, because any real overlap changes the large majority of the
# pixels under it, and the "no worse than" comparison between the two headroom
# arms is between two figures drawn the same way. What would NOT survive is
# reading a fall in coverPx as an improvement in readability — a translucent
# key over the data is a key over the data — which is why nothing here rewards
# a smaller number except against its own control.
# ---------------------------------------------------------------------------

# --- Every series case drew a REAL figure of the type it claimed, and the
# fixture drove the product rather than a copy of it.
series_p <- repo_path("harness", "legend", "series_case.praat")
if (!file.exists(series_p))
    stop(sprintf("v32: %s missing", series_p))
series_src <- readLines(series_p, warn = FALSE)
check_true("v32", "the series fixture drives @emlDrawTimeSeries itself",
           any(grepl("@emlDrawTimeSeries:", series_src, fixed = TRUE)))
check_true("v32", "the series fixture drives @emlDrawScatterPlot itself",
           any(grepl("@emlDrawScatterPlot:", series_src, fixed = TRUE)))
# THE CORNER IS NOT CHOSEN BY THE FIXTURE. Neither a corner name nor a call to
# @emlDrawLegend appears in it: the legend is reached only from inside the
# draw procedures, which is the only way @emlPlaceElements gets to decide.
check_true("v32", "the series fixture never calls @emlDrawLegend itself",
           !any(grepl("@emlDrawLegend:", series_src, fixed = TRUE)))
# Comment lines are stripped first -- the file DISCUSSES corners at length,
# and the claim is about the code, which must name none.
series_code <- grep("^[[:space:]]*[#;]", series_src, value = TRUE,
                    invert = TRUE)
check_true("v32", "...and names no corner of its own",
           !any(grepl('"(top|bottom)-(left|right)"', series_code)))
# The headroom pass is the PRODUCT's, included rather than reimplemented.
check_true("v32", "the series fixture drives the form's own headroom pass",
           any(grepl("@emlLegendHeadroomAfterDraw:", series_src, fixed = TRUE)) &&
           any(grepl("eml-graphs-form.praat", series_src, fixed = TRUE)))
check_true("v32", "the series fixture saves through the plugin's pre-save idiom",
           any(grepl("@stressSave:", series_src, fixed = TRUE)))

# --- THE PROPERTY THE WHOLE BLOCK RESTS ON: entries = series. Asserted on
# three numbers that are produced independently — the table the fixture built
# (k), the group count the DRAW PROCEDURE resolved from that table (nGroups),
# and the count @emlDrawLegend was handed (legendN) — so a legend that named
# a different number of things than the figure drew could not pass by
# agreeing with itself.
sr_all <- rbind(b5, b6)
for (i in seq_len(nrow(sr_all))) {
  cs <- sr_all$case[i]
  lg <- readLines(file.path(leg_dir, paste0(cs, ".log")), warn = FALSE)
  sl <- grep("^SERIES ", lg, value = TRUE)
  if (!check_true("v32", paste(cs, "reported its series count"),
                  length(sl) == 1)) next
  f <- function(key) as.numeric(sub(paste0("^.*[ ]", key, "=([^ ]*).*$"),
                                    "\\1", sl[1]))
  check("v32", paste(cs, "the draw procedure grouped every series in the table"),
        f("nGroups"), sr_all$k[i], tol = 0)
  check("v32", paste(cs, "the legend has exactly one entry per series"),
        f("legendN"), sr_all$k[i], tol = 0)
}

# --- WHICH CORNER THE PRODUCT ACTUALLY CHOOSES. Recorded, not guessed. The
# fixture prints @emlDrawLegend's own .position$ and, separately,
# @emlPlaceElements.corner1$; these are the same string on every one of these
# figures, which is the statement that the draw procedures pass the scored
# corner through unmodified.
for (i in seq_len(nrow(sr_all))) {
  cs <- sr_all$case[i]
  lg <- readLines(file.path(leg_dir, paste0(cs, ".log")), warn = FALSE)
  cl <- grep("^CORNER ", lg, value = TRUE)
  if (!check_true("v32", paste(cs, "reported a corner"), length(cl) == 1)) next
  got   <- sub("^CORNER corner=([^ ]*).*$", "\\1", cl[1])
  place <- sub("^.* placed=([^ ]*).*$", "\\1", cl[1])
  check_true("v32", paste(cs, "the corner drawn is the corner @emlPlaceElements scored"),
             got == place)
  # ...and it is the emptiest quadrant, recomputed here from the four scores
  # the draw procedure counted. Ties go to the earlier corner in the
  # procedure's own order -- top-left, top-right, bottom-left, bottom-right --
  # because every comparison in it is a strict `<`.
  q <- sapply(c("qTL", "qTR", "qBL", "qBR"), function(k)
      as.numeric(sub(paste0("^.*[ ]", k, "=([^ ]*).*$"), "\\1", cl[1])))
  want <- c("top-left", "top-right", "bottom-left", "bottom-right")[which.min(q)]
  check_true("v32", paste(cs, "the corner is the emptiest quadrant"),
             got == want)
}

# THE CHOICE ITSELF, PINNED. Which corner each figure gets is a fact about the
# product and about this data, and it is written down so that a change to the
# scoring, to the quadrant scan, or to the headroom's effect on the y midpoint
# moves a visible number here rather than passing unnoticed. Recorded 9 Aug
# 2026 against the tree of that morning.
CORNER_PIN <- c(
  # THE LINE CHART TAKES TOP-LEFT, at every size and every entry count. Its
  # series sweep the full height of the panel, so all four quadrant counts are
  # within a handful of vertices of each other and the winner is decided by
  # very little -- which is exactly the figure on which "choose the emptiest
  # corner" buys the reader nothing, because the emptiest corner still has
  # three lines through it.
  sr_line_6x4_k5_r0 = "top-left", sr_line_5x5_k5_r0 = "top-left",
  sr_line_10x3_k5_r0 = "top-left", sr_line_6x4_k12_r0 = "top-left",
  # THE GROUPED SCATTER TAKES BOTTOM-RIGHT, at every size, with no headroom
  # pass.
  sp_scatter_6x4_p1 = "bottom-right", sp_scatter_5x5_p1 = "bottom-right",
  sp_scatter_10x3_p1 = "bottom-right",
  sr_scatter_6x4_k5_r0 = "bottom-right",
  # ...AND MOVES TO BOTTOM-LEFT WHEN THE HEADROOM PASS RUNS. This is the
  # behaviour @emlPlaceElements' own comment predicts and bounds: room is made
  # by moving ONE axis bound, so the y midpoint the quadrants are split on
  # moves with it, and "only left and right can trade places". They trade
  # here. It is pinned because it is the observable consequence of the
  # headroom work on corner selection, and because the comment's claim -- that
  # nothing crosses between top and bottom -- is only worth anything if a
  # figure that DID cross would be caught. Every scatter case in block 5 makes
  # the same move; three of them are named.
  sr_scatter_6x4_k5_r1 = "bottom-left",
  sr_scatter_5x5_k5_r1 = "bottom-left",
  sr_scatter_10x3_k5_r1 = "bottom-left")
for (nm in names(CORNER_PIN)) {
  r <- res[res$case == nm, ]
  if (!check_true("v32", paste(nm, "is in the results"), nrow(r) == 1)) next
  check_true("v32", paste(nm, "takes the", CORNER_PIN[[nm]], "corner"),
             r$corner[1] == CORNER_PIN[[nm]])
}
# The claim in @emlPlaceElements' comment, over the whole block rather than
# over three named cases: the headroom pass may move a legend from left to
# right or back, and may NOT move it between the top of the figure and the
# bottom. Half of a corner name is the half that is protected.
for (g in SR_GRAPHS) for (sz in SIZES$size) for (kk in SR_K) {
  r0 <- b5[b5$case == paste0("sr_", g, "_", sz, "_k", kk, "_r0"), ]
  r1 <- b5[b5$case == paste0("sr_", g, "_", sz, "_k", kk, "_r1"), ]
  if (nrow(r0) != 1 || nrow(r1) != 1) next
  check_true("v32",
             sprintf("sr_%s_%s k=%d: the headroom pass does not move the legend top<->bottom (%s / %s)",
                     g, sz, kk, r0$corner[1], r1$corner[1]),
             sub("-.*$", "", r0$corner[1]) == sub("-.*$", "", r1$corner[1]))
}

# --- THE CONTROL IS THE SAME FIGURE. Every coverage pair must agree on the
# plot rectangle, the saved image and the drawn extent, or the pixel
# comparison between them is comparing two different figures.
b5t <- b5[b5$ctl != "-", ]
check("v32", "every block 5 treatment names a control",
      nrow(b5t), length(SR_TREAT), tol = 0)
for (i in seq_len(nrow(b5t))) {
  cs <- b5t$case[i]
  c0 <- res[res$case == b5t$ctl[i], ]
  if (!check_true("v32", paste(cs, "its control was rendered"), nrow(c0) == 1))
      next
  check_true("v32", paste(cs, "treatment and control are the same saved image"),
             b5t$imgW[i] == c0$imgW[1] && b5t$imgH[i] == c0$imgH[1])
  check_true("v32", paste(cs, "treatment and control share one plot rectangle"),
             b5t$frameL[i] == c0$frameL[1] && b5t$frameT[i] == c0$frameT[1] &&
             b5t$frameR[i] == c0$frameR[1] && b5t$frameB[i] == c0$frameB[1])
  # THE AXIS. The whole coverage measurement is void if the two figures are
  # not on one axis, so it is checked rather than arranged for: the driver
  # pins the control to the number the treatment printed, and this is that
  # pin read back off both transcripts.
  check("v32", paste(cs, "treatment and control are on one y-axis (min)"),
        c0$axMin[1], b5t$axMin[i], tol = 1e-9)
  check("v32", paste(cs, "treatment and control are on one y-axis (max)"),
        c0$axMax[1], b5t$axMax[i], tol = 1e-9)
  # The control draws no legend at all: placement 5, nothing shown, no box.
  check_true("v32", paste(cs, "the control drew no legend"),
             c0$pAct[1] == 5 && c0$shown[1] == 0)
}

# --- THE MEASUREMENT IS SOUND BEFORE IT IS INTERESTING.
for (i in seq_len(nrow(sr_all))) {
  cs <- sr_all$case[i]
  if (is.na(sr_all$coverPx[i])) next
  check_true("v32", paste(cs, "there is data ink to cover"),
             sr_all$dataPx[i] > 0)
  # coverPx counts a subset of the pixels diffPx counts: an identity, checked
  # rather than assumed, because a coverage number larger than the total
  # number of changed pixels would mean the two counts were taken over
  # different regions.
  check_true("v32", paste(cs, "covered pixels are a subset of changed pixels"),
             sr_all$coverPx[i] <= sr_all$diffPx[i])
  check_true("v32", paste(cs, "covered pixels are a subset of the data ink"),
             sr_all$coverPx[i] <= sr_all$dataPx[i])
}
# The legend leaves a mark SOMEWHERE. A coverage measurement that reported
# zero because the two renders were identical would be indistinguishable from
# a legend that covers nothing, and one of those is a broken fixture.
for (i in seq_len(nrow(b5t))) {
  check_true("v32", paste(b5t$case[i], "the treatment differs from its control at all"),
             !is.na(b5t$diffPx[i]) && b5t$diffPx[i] > 0)
}

# ---------------------------------------------------------------------------
# 10b. THE NUMBER. How much data the key sits on, at placement 1.
#
# PIN-THEN-CHANGE, v27's and v29's discipline. coverPx is RECORDED as a
# number and not reduced to a boolean, so that a future change to
# @emlComputeAnnotationHeadroom, to @emlPlaceElements, or to the legend's own
# layout moves a visible figure in this file rather than flipping a check that
# was already green.
#
# THE TWO ARMS, and both of them are real callers:
#
#   room = 0   The figure is drawn ONCE. This is every caller that is not the
#              graphs form — every PraatGen companion file, every direct call
#              into eml-draw-procedures.praat, every stress case in this repo.
#              No headroom pass exists for them, so whatever the legend
#              covers, it covers.
#   room = 1   The form's two-pass path: draw, ask @emlLegendHeadroomAfterDraw
#              whether the legend needs y-axis room, and if it says yes, draw
#              again on the widened axis.
#
# WHAT WAS MEASURED, 9 August 2026, on the 6 x 4 line chart:
#
#     k    room 0        room 1
#     3    0             0            the box is small and the corner it takes
#                                     is genuinely empty; nothing to fix
#     5    1348          0            the case the plugin's own defect note is
#                                     written about
#    12    20932         7385         twelve entries on a 4-inch panel: the
#                                     band exceeds emlLegendHeadroomShare and
#                                     the axis is widened as far as the cap
#                                     allows, which is not far enough
#
# SO THE HEADROOM WORKS AND IT IS NOT A CURE. Where the legend can be
# afforded, room = 1 drives the overlap to exactly zero. Where it cannot, the
# cap holds the line at half the panel and the rest is REPORTED — the NOTE in
# @emlLegendHeadroomAfterDraw names the shortfall and tells the reader to move
# the legend out of the plot. The assertion below is written to that shape and
# not to "coverPx is zero", because "zero everywhere" is a claim the product
# does not make and should not be held to.
# ---------------------------------------------------------------------------

# (a) THE HEADROOM PASS NEVER MAKES IT WORSE. Over every pair of arms, at
# every graph type, size and entry count. This is the one that holds whichever
# way the headroom work lands: if it is reverted the two arms are equal and
# this still passes; if it is improved the inequality only widens.
sr_pairs <- 0L
for (g in SR_GRAPHS) for (sz in SIZES$size) for (kk in SR_K) {
  n0 <- paste0("sr_", g, "_", sz, "_k", kk, "_r0")
  n1 <- paste0("sr_", g, "_", sz, "_k", kk, "_r1")
  r0 <- b5[b5$case == n0, ]; r1 <- b5[b5$case == n1, ]
  if (nrow(r0) != 1 || nrow(r1) != 1) next
  sr_pairs <- sr_pairs + 1L
  check_true("v32",
             sprintf("%s %s k=%d: the headroom pass covers no more data than no pass (%d -> %d)",
                     g, sz, kk, r0$coverPx[1], r1$coverPx[1]),
             r1$coverPx[1] <= r0$coverPx[1])
}
check("v32", "every headroom pair was compared", sr_pairs,
      length(SR_GRAPHS) * nrow(SIZES) * length(SR_K), tol = 0)

# (b) WHERE THE LEGEND FITS, THE OVERLAP IS EXACTLY ZERO. "Fits" is not this
# script's opinion: @emlComputeAnnotationHeadroom reports .legendOverflow when
# the band it wanted exceeded emlLegendHeadroomShare of the panel, and
# @emlLegendHeadroomAfterDraw prints a NOTE naming the shortfall. So the
# figures that carry no such NOTE are the figures the product says it served,
# and on those the count is required to be 0 — not small, zero.
served <- 0L
capped <- 0L
for (i in seq_len(nrow(b5))) {
  if (b5$room[i] != 1 || b5$ctl[i] == "-") next
  lg <- readLines(file.path(leg_dir, paste0(b5$case[i], ".log")), warn = FALSE)
  short <- any(grepl("^NOTE: The legend asked for", lg))
  if (short) {
    capped <- capped + 1L
    # A capped legend is required to SAY SO, and to say what to do instead.
    check_true("v32", paste(b5$case[i], "the shortfall names the way out"),
               any(grepl("Right of plot or Below plot", lg)))
  } else {
    served <- served + 1L
    check("v32", paste(b5$case[i],
                       "the legend was afforded, and covers no data at all"),
          b5$coverPx[i], 0, tol = 0)
  }
}
# Both populations are non-empty, or one of the two branches above is never
# exercised and the section is weaker than it reads.
check_true("v32", "the headroom arm contains legends that fit", served > 0)
check_true("v32", "...and legends that could not be afforded", capped > 0)

# (c) THE NUMBERS THEMSELVES, on the default figure. Pinned so a change moves
# a visible figure. Stated as an INEQUALITY on the no-pass arm rather than an
# equality, because the exact count depends on where the palette puts each
# series and a re-ordered palette is not a legend defect; the ordering between
# the arms, and the zero, are the load-bearing halves and they are exact.
COVER_PIN <- rbind(
  data.frame(case = "sr_line_6x4_k3_r0",  atMost = 200,   stringsAsFactors = FALSE),
  data.frame(case = "sr_line_6x4_k5_r0",  atMost = 4000,  stringsAsFactors = FALSE),
  data.frame(case = "sr_line_6x4_k12_r0", atMost = 40000, stringsAsFactors = FALSE))
for (i in seq_len(nrow(COVER_PIN))) {
  r <- b5[b5$case == COVER_PIN$case[i], ]
  if (!check_true("v32", paste(COVER_PIN$case[i], "is in the results"),
                  nrow(r) == 1)) next
  check_below("v32", paste(COVER_PIN$case[i], "data pixels under the legend"),
              COVER_PIN$atMost[i], r$coverPx[1])
}
# A LEGEND THAT COVERS DATA IS ACTUALLY REACHED. If every case in the block
# came out at zero without the headroom pass, the fixture would be measuring
# nothing and every check above would be vacuously green.
check_true("v32", "at least one no-pass figure does put the key on the data",
           sum(b5$coverPx[b5$room == 0 & b5$ctl != "-"] > 0, na.rm = TRUE) > 0)

# ---------------------------------------------------------------------------
# 10c. THE FIVE PLACEMENTS, ON THE REAL PATH.  Block 6.
#
# Section 3b makes this statement on the geometry rig, where the corner is
# forced and the key describes nothing. Here it is made where the legend is
# real, the corner is chosen and the figure is one that needs a key: the PLOT
# RECTANGLE is the same rectangle in all five placements, and what is allowed
# to differ is the SAVED FILE.
# ---------------------------------------------------------------------------
for (g in SR_GRAPHS) for (sz in SIZES$size) {
  fam <- b6[b6$case %in% paste0("sp_", g, "_", sz, "_p", 1:5), ]
  if (!check_true("v32", sprintf("sp_%s_%s: all five placements rendered", g, sz),
                  nrow(fam) == 5)) next
  # Inches, not pixels: placements 2 and 3 grow the export, so a figure whose
  # extent is not a whole number of inches is written at an effective
  # resolution a hair off 300. Section 2's note has the arithmetic.
  check_true("v32", sprintf("sp_%s_%s: one plot width across all five placements", g, sz),
             max(fam$frameWin) - min(fam$frameWin) < 0.01)
  check_true("v32", sprintf("sp_%s_%s: one plot height across all five placements", g, sz),
             max(fam$frameHin) - min(fam$frameHin) < 0.01)
  # ...and it is the rectangle the user asked for, once the margins are added
  # back. The same composition statement section 3 makes, on the real path.
  for (i in seq_len(nrow(fam))) {
    check("v32", paste(fam$case[i], "frame + margins = requested width"),
          fam$frameW[i] + (fam$mL[i] + fam$mR[i]) * fam$dpiX[i],
          fam$vpW[i] * fam$dpiX[i], tol = PX_TOL)
    check("v32", paste(fam$case[i], "frame + margins = requested height"),
          fam$frameH[i] + (fam$mT[i] + fam$mB[i]) * fam$dpiY[i],
          fam$vpH[i] * fam$dpiY[i], tol = PX_TOL)
  }
  # WHICH PLACEMENTS MAY GROW THE FILE. 2 across, 3 down, and 1/4/5 not at
  # all -- the same rule section 3b states, restated on a figure whose legend
  # has real content to lay out.
  gp <- function(n) fam[fam$case == paste0("sp_", g, "_", sz, "_p", n), ]
  p1 <- gp(1); p2 <- gp(2); p3 <- gp(3); p4 <- gp(4); p5 <- gp(5)
  check_true("v32", sprintf("sp_%s_%s: placement 1 leaves the export alone", g, sz),
             p1$imgW == p5$imgW && p1$imgH == p5$imgH)
  check_true("v32", sprintf("sp_%s_%s: placement 4 leaves the export alone", g, sz),
             p4$imgW == p5$imgW && p4$imgH == p5$imgH)
  check_true("v32", sprintf("sp_%s_%s: placement 2 grows the export across only", g, sz),
             p2$imgW > p5$imgW && p2$imgH == p5$imgH)
  check_true("v32", sprintf("sp_%s_%s: placement 3 grows the export down only", g, sz),
             p3$imgH > p5$imgH && p3$imgW == p5$imgW)
  # THE PIXELS, for the two placements where the comparison is defined.
  # Placement 4 parks the legend twelve inches past the page bottom and writes
  # it to a second file, so the first file must carry no legend ink at all --
  # which on this figure means it must cover no data. Placement 1 draws it
  # inside the plot, so its count is whatever it is, recorded above.
  check("v32", sprintf("sp_%s_%s: placement 4 covers no data in the main file", g, sz),
        p4$coverPx, 0, tol = 0)
  check_true("v32", sprintf("sp_%s_%s: placement 4 changes nothing in the main file", g, sz),
             p4$diffPx == 0)
  check_true("v32", sprintf("sp_%s_%s: placement 1 does change the figure", g, sz),
             p1$diffPx > 0)
}


# ---------------------------------------------------------------------------
# 11. THE FOUR NON-CATEGORICAL TYPES.  Block 7.
#
# WHAT WAS MISSING, AND IT IS A COVERAGE HOLE RATHER THAN A DEFECT. Six graph
# types offer the Legend placement menu (legendPlacementStyle[t] = 5):
#
#      5 Line Chart (+/-CI)     8 Scatter Plot        10 Histogram
#     11 Grouped Violin        12 Grouped Box         13 Spaghetti Plot
#
# Sections 1 to 9 are measured on the geometry rig, which draws a GROUPED
# VIOLIN. Section 10 is measured on the series fixture, which draws a line
# chart and a grouped scatter. Between them, three of the six. Types 5, 10 and
# 13 had never been swept by anything an R script reads -- they were measured
# BY HAND on 9 August 2026 and the numbers were written into section 1 of
# audit/GRAPHING_PUSH_REMAINING.md. A table in a markdown file is a record of
# what someone saw once; section 7's standard is that nothing counts as
# validated until an authored R script tests the output. This section is that
# script, and harness/legend/placement_sweep_case.praat -- rewritten to the
# driver's own calling convention -- is what produces its input.
#
# The claim being pinned, in the author's words: the dimensions a user types
# describe the DATA AREA. So across all five placements, on every one of these
# four types, the PLOT RECTANGLE is one rectangle and the SAVED IMAGE is what
# moves.
#
# INCHES, NOT PIXELS, for the cross-placement comparison. Placement 2 grows
# the extent by one boxInsetInches, which is not a whole number of inches, so
# the file is written at an effective resolution a hair off 300 and the same
# plot measures one pixel narrower. Section 2's note has the arithmetic; this
# section uses the frameWin/frameHin the loader already derives from each
# file's own scale. The pixel numbers ARE pinned, further down, for the four
# placements whose extent is a whole number of inches.
#
# WHAT ONLY THIS BLOCK CAN SAY. Placement 4 parks the legend some two feet
# below the figure and writes it to a SECOND FILE. No other fixture in this
# tree performs that select-and-save, so until now the second file was
# asserted from the source and never from a file on disk. Here it is a file on
# disk.
# ---------------------------------------------------------------------------
# SW_TYPES, SW_CASES and b7 are declared with the rest of the inventory, up
# where the block census is, so that "which cases exist" is one list and not
# two that can drift apart.
SW_TYPE_NAME <- c("5" = "Line Chart (+/-CI)", "8" = "Scatter Plot",
                  "10" = "Histogram", "13" = "Spaghetti Plot")

for (tp in SW_TYPES) {
  fam <- b7[b7$case %in% paste0("sw_t", tp, "_p", 1:5), ]
  nm  <- SW_TYPE_NAME[[as.character(tp)]]
  if (!check_true("v32", sprintf("type %d (%s): all five placements rendered",
                                 tp, nm), nrow(fam) == 5)) next

  # --- THE DESIGN GUARANTEE. One plot rectangle, five placements.
  check_true("v32", sprintf("type %d: one plot width across all five placements", tp),
             max(fam$frameWin) - min(fam$frameWin) < 0.01)
  check_true("v32", sprintf("type %d: one plot height across all five placements", tp),
             max(fam$frameHin) - min(fam$frameHin) < 0.01)
  # ...and its ORIGIN does not move either. A rectangle of the right size in
  # the wrong place would pass the two checks above.
  check_true("v32", sprintf("type %d: the plot rectangle does not move", tp),
             max(fam$frameLin) - min(fam$frameLin) < 0.01 &&
             max(fam$frameTin) - min(fam$frameTin) < 0.01)

  # --- ...AND IT IS THE RECTANGLE THE USER ASKED FOR, once the margins are
  # added back. The composition statement section 3 makes on the rig, restated
  # on four types it has never been made on.
  for (i in seq_len(nrow(fam))) {
    check("v32", paste(fam$case[i], "frame + margins = requested width"),
          fam$frameW[i] + (fam$mL[i] + fam$mR[i]) * fam$dpiX[i],
          fam$vpW[i] * fam$dpiX[i], tol = PX_TOL)
    check("v32", paste(fam$case[i], "frame + margins = requested height"),
          fam$frameH[i] + (fam$mT[i] + fam$mB[i]) * fam$dpiY[i],
          fam$vpH[i] * fam$dpiY[i], tol = PX_TOL)
  }

  gp <- function(n) fam[fam$case == paste0("sw_t", tp, "_p", n), ]
  p1 <- gp(1); p2 <- gp(2); p3 <- gp(3); p4 <- gp(4); p5 <- gp(5)

  # --- WHICH PLACEMENTS MAY GROW THE FILE. 2 across, 3 down, 1/4/5 not at
  # all. The same rule sections 3b and 10c state, on four more types.
  check_true("v32", sprintf("type %d: placement 1 leaves the export alone", tp),
             p1$imgW == p5$imgW && p1$imgH == p5$imgH)
  check_true("v32", sprintf("type %d: placement 4 leaves the export alone", tp),
             p4$imgW == p5$imgW && p4$imgH == p5$imgH)
  check_true("v32", sprintf("type %d: placement 2 grows the export across only", tp),
             p2$imgW > p5$imgW && p2$imgH == p5$imgH)
  check_true("v32", sprintf("type %d: placement 3 grows the export down only", tp),
             p3$imgH > p5$imgH && p3$imgW == p5$imgW)

  # --- THE PIXEL PIN, on the four placements whose extent is a whole number
  # of inches and whose scale is therefore exactly 300. 6 x 4.5 at 300 dpi is
  # 1800 x 1350, and that is the number section 1 of the audit tracker
  # records by hand. Placement 2 is excluded by the arithmetic above, not by
  # convenience: its extent is 6 + boxInsetInches wide.
  # Width: placement 3 grows DOWN, so all four of these are the requested
  # width at exactly 300 dpi.
  for (r in list(p1, p3, p4, p5)) {
    check("v32", paste(r$case, "saved image width = requested inches x 300 dpi"),
          r$imgW, r$vpW * DPI, tol = 0)
  }
  # Height: the three that grow in neither direction.
  for (r in list(p1, p4, p5)) {
    check("v32", paste(r$case, "saved image height = requested inches x 300 dpi"),
          r$imgH, r$vpH * DPI, tol = 0)
  }

  # --- THE RESOLVED AXES ARE THE SAME IN ALL FIVE. This is the other half of
  # "only the furniture moves", and it is the half a pixel measurement cannot
  # see: a legend that quietly widened the y range to make room for itself
  # would leave the plot rectangle exactly where it is and change the figure.
  # The fixture's data is generated by an LCG rather than randomGauss for
  # precisely this comparison to be defined.
  check_true("v32", sprintf("type %d: one y-axis across all five placements", tp),
             max(fam$axMin) - min(fam$axMin) < 1e-9 &&
             max(fam$axMax) - min(fam$axMax) < 1e-9)

  # --- THE LEGEND HAS THE ENTRIES THE FIGURE HAS SERIES, on four types that
  # reach @emlDrawLegend by four different routes. Read out of the transcript
  # from three independently produced numbers, as section 10 does.
  for (i in seq_len(nrow(fam))) {
    cs <- fam$case[i]
    lg <- readLines(file.path(leg_dir, paste0(cs, ".log")), warn = FALSE)
    sl <- grep("^SERIES ", lg, value = TRUE)
    if (!check_true("v32", paste(cs, "reported its series count"),
                    length(sl) == 1)) next
    f <- function(key) as.numeric(sub(paste0("^.*[ ]", key, "=([^ ]*).*$"),
                                      "\\1", sl[1]))
    check("v32", paste(cs, "the draw procedure grouped every series in the table"),
          f("nGroups"), 4, tol = 0)
    check("v32", paste(cs, "the legend has exactly one entry per series"),
          f("legendN"), 4, tol = 0)
  }

  # --- PLACEMENT 4 WROTE A SECOND FILE, AND NO OTHER PLACEMENT DID.
  # emlLegendSepActive is the handshake the graphs form performs at its own
  # save site; the fixture performs the same one. Both halves are asserted --
  # a run that wrote a legend file for every placement would be as wrong as
  # one that wrote none.
  for (i in seq_len(nrow(fam))) {
    cs   <- fam$case[i]
    sep  <- file.path(leg_dir, paste0(cs, "_legend.png"))
    lg   <- readLines(file.path(leg_dir, paste0(cs, ".log")), warn = FALSE)
    sfl  <- grep("^SEPFILE ", lg, value = TRUE)
    if (!check_true("v32", paste(cs, "reported the parked-legend handshake"),
                    length(sfl) == 1)) next
    act  <- as.numeric(sub("^SEPFILE active=([^ ]*).*$", "\\1", sfl[1]))
    want <- if (fam$pReq[i] == 4) 1 else 0
    check("v32", paste(cs, "emlLegendSepActive is what the placement implies"),
          act, want, tol = 0)
    if (want == 1) {
      check_true("v32", paste(cs, "the parked legend was written to its own file"),
                 file.exists(sep) && file.info(sep)$size > 0)
    } else {
      check_true("v32", paste(cs, "no stray legend file"), !file.exists(sep))
    }
  }
}

# --- WHICH CORNER EACH TYPE TAKES. Recorded rather than guessed, and it is
# the corner @emlPlaceElements scored: the fixture names none of its own, so
# a corner in the transcript can only have come from the scoring.
#
# Measured 11 August 2026. The line chart takes TOP-LEFT -- its series sweep
# the full height of the panel and the winner is decided by very little, the
# same observation section 10 makes about sr_line_*. The other three take
# BOTTOM-RIGHT: the scatter's cloud rises to the right, the histogram's bars
# are tallest at the left, and the spaghetti's trajectories climb.
SW_CORNER_PIN <- c("5" = "top-left", "8" = "bottom-right",
                   "10" = "bottom-right", "13" = "bottom-right")
for (tp in SW_TYPES) {
  fam <- b7[b7$case %in% paste0("sw_t", tp, "_p", 1:5), ]
  if (nrow(fam) != 5) next
  want <- SW_CORNER_PIN[[as.character(tp)]]
  # ALL FIVE PLACEMENTS, not one: the corner is scored before the placement
  # is consulted, so a figure that changed corner when the legend moved out
  # of the plot would mean the scoring had started reading the placement.
  check_true("v32", sprintf("type %d takes the %s corner in all five placements",
                            tp, want),
             all(fam$corner == want))
}

# ---------------------------------------------------------------------------
# 11b. THE AXIS CONTRACT, MEASURED ON THE FOUR TYPES.
#
# Section 7 reads the contract out of the source. This reads it off four
# running draw procedures, and it is worth having both because the two can
# disagree: a procedure that publishes .axis* from the wrong local satisfies
# every static check in section 7.
#
# `.axis*` ALWAYS MEANS THE RANGE THE AXES WERE ACTUALLY DRAWN AT. `.xMin` and
# friends do NOT: in @emlDrawScatterPlot they are the procedure's PARAMETERS,
# carrying what the caller REQUESTED, with (0, 0) meaning auto. That is the
# whole reason the contract exists and the reason aliasing the two spellings
# would have preserved the defect under a tidier name -- a caller reading
# .xMin uniformly gets 0 for an auto-ranged scatter instead of an error.
#
# So the assertion is TWO-SIDED. On 5, 10 and 13 the two spellings agree. On
# 8 they must NOT: the requested range is 0 and the drawn range is not.
# ---------------------------------------------------------------------------
for (tp in SW_TYPES) {
  cs <- paste0("sw_t", tp, "_p1")
  lp <- file.path(leg_dir, paste0(cs, ".log"))
  if (!check_true("v32", paste(cs, "log written"), file.exists(lp))) next
  lg <- readLines(lp, warn = FALSE)
  al <- grep("^AXCONTRACT ", lg, value = TRUE)
  if (!check_true("v32", paste(cs, "reported both axis spellings"),
                  length(al) == 1)) next
  f <- function(key) as.numeric(sub(paste0("^.*[ ]", key, "=([^ ]*).*$"),
                                    "\\1", al[1]))
  ax <- c(f("axisXMin"), f("axisXMax"), f("axisYMin"), f("axisYMax"))
  pr <- c(f("paramXMin"), f("paramXMax"), f("paramYMin"), f("paramYMax"))

  # The published range is a real range, whatever else is true of it.
  check_true("v32", sprintf("type %d publishes a non-degenerate axis* range", tp),
             all(is.finite(ax)) && ax[2] > ax[1] && ax[4] > ax[3])

  if (tp == 8) {
    # THE EXCEPTION, AND IT IS THE POINT. Called with 0, 0, 0, 0 -- auto on
    # both axes -- the scatter's four parameters are still 0 after the draw,
    # and its axis* is the range it drew. If these ever became equal, either
    # the parameters started being overwritten (and a caller could no longer
    # tell what it asked for) or axis* stopped being resolved.
    check_true("v32",
               "the scatter's .xMin.. are the caller's REQUEST, not the drawn range",
               all(pr == 0) && !isTRUE(all.equal(ax, pr)))
  } else {
    check_true("v32", sprintf("type %d: axis* agrees with the resolved locals", tp),
               isTRUE(all.equal(ax, pr, tolerance = 1e-9)))
  }
}

if (!exists("EML_SUITE")) { eml_report("v32 legend geometry: the plot is what the user asked for"); eml_exit() }
