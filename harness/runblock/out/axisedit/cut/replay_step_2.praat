#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 17 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table ax1 -- 24 rows, 2 columns
# ============================================================

# ------------------------------------------------------------
# THE EML LIBRARY
# Recorded under Praat 6.6.30. Paths are home-relative, so they work
# for any user on this platform. If this file fails to parse, the
# plugin is somewhere else -- edit this block and nothing else.
#
#   Praat 6.x  Linux    ~/.praat-dir/plugin_EML_StatsGraphs
#   Praat 7.x  Linux    ~/.config/praat/plugin_EML_StatsGraphs
#   macOS      ~/Library/Preferences/Praat Prefs/plugin_EML_StatsGraphs
#   Windows    ~/Praat/plugin_EML_StatsGraphs
#   Not sure?  Run  writeInfoLine: preferencesDirectory$
#
# A version guard cannot help here: `include` is refused inside an
# if-block, so the file cannot choose its own path at run time.
# The barrel eml-lib-stats.praat will NOT work in place of this
# list: its own relative includes resolve against THIS file's
# folder, not its own.
# ------------------------------------------------------------

include ~/repo/plugin/stats/eml-core-utilities.praat
include ~/repo/plugin/stats/eml-core-descriptive.praat
include ~/repo/plugin/stats/eml-extract.praat
include ~/repo/plugin/stats/eml-output.praat
include ~/repo/plugin/stats/eml-inferential.praat
include ~/repo/plugin/stats/eml-psychometrics.praat
include ~/repo/plugin/stats/eml-categorical.praat
include ~/repo/plugin/stats/eml-result-writer.praat
include ~/repo/plugin/stats/eml-record.praat
include ~/repo/plugin/graphs/eml-graph-procedures.praat
include ~/repo/plugin/graphs/eml-annotation-procedures.praat
include ~/repo/plugin/graphs/eml-draw-procedures.praat
include ~/repo/plugin/stats/eml-analysis.praat
include ~/repo/plugin/stats/eml-demo-tables.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table ax1 -- 24 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# None of them is built or opened by a step below: see
# PRECONDITION, and open them before you run this script.
# ------------------------------------------------------------

# ============================================================
# PRECONDITION -- THIS SCRIPT CANNOT REBUILD ITS DATA
#
# These objects were already open when this recording started.
#     Table ax1
#     Table ax2
# Nothing in the session made them, so nothing below can remake them.
#
# YOU MUST SUPPLY THE DATA YOURSELF, open and named as above, before you
# run this file. The steps below select by name: with nothing of that name
# open the script stops at its first step, and with DIFFERENT data of that
# name it runs to the end and answers a different question without saying so.
# ============================================================

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table ax1"   ; run 1, step 1 (draw)
data2$ = "Table ax2"   ; run 2, step 2 (draw)
groupCol$     = "grp"   ; the grouping column -- run 1, step 1 (draw)
valueCol$     = "val"   ; the measured column -- run 1, step 1 (draw)
groupCol2$    = "grp"   ; the grouping column -- run 2, step 2 (draw)
valueCol2$    = "val"   ; the measured column -- run 2, step 2 (draw)
axisYMin      = 2   ; the y-axis range -- as typed in the dialog -- run 1, step 1 (draw)
axisYMax      = 30   ; the figure was drawn on 2.0000 .. 30.0000
axisYMin2     = 2   ; the y-axis range -- as typed in the dialog -- run 2, step 2 (draw)
axisYMax2     = 30   ; the figure was drawn on 2.0000 .. 30.0000
eraseFirst    = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 1 (draw)
panelOriginX  = 0   ; inches from the left of the page to this panel's corner -- run 1, step 1 (draw)
panelOriginY  = 0   ; inches from the top of the page to this panel's corner -- run 1, step 1 (draw)
lineStyle     = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 1 (draw)
secondAxisOn  = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 1 (draw)
eraseFirst2   = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 2, step 2 (draw)
panelOriginX2 = 0   ; inches from the left of the page to this panel's corner -- run 2, step 2 (draw)
panelOriginY2 = 0   ; inches from the top of the page to this panel's corner -- run 2, step 2 (draw)
lineStyle2    = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 2, step 2 (draw)
secondAxisOn2 = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 2, step 2 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# Two tables whose figures are drawn on the SAME typed axis literals. The
# old (role, literal) key made those one variable; the run rule makes them
# two, and the difference is visible only when one of them is edited.
procedure mkAx: .nm$, .seed, .lift
    Create Table with column names: .nm$, 0, "grp val"
    .st = .seed
    for .g from 1 to 2
        for .k from 1 to 12
            .st = (1103515245 * .st + 12345) mod 2147483648
            Append row
            .r = Get number of rows
            Set string value: .r, "grp", "G" + string$ (.g)
            Set numeric value: .r, "val",
            ... 6 + .lift + .g * 2.0 + (.st / 2147483648 - 0.5) * 1.5
        endfor
    endfor
    .id = selected ("Table")
endproc
@mkAx: "ax1", 606061, 0
tableAx1 = mkAx.id
@mkAx: "ax2", 707071, 6
tableAx2 = mkAx.id
Erase all
# --- Step 2 (draw) ---
selectObject: data2$
data = selected ()
# Box plot: Ax two
# Whisker convention and outlier rule are stated in the figure, not assumed.

emlEraseFirst = eraseFirst2
emlPanelOriginX = panelOriginX2
emlPanelOriginY = panelOriginY2
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle2
emlSecondAxisOn = secondAxisOn2
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 1
@emlDrawBoxPlot: data, "Ax two", "Group", "val", 6, 4, "color", 1, groupCol2$, valueCol2$, axisYMin2, axisYMax2

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...



@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/runblock/out/axisedit/REPLAY_step2.png"
