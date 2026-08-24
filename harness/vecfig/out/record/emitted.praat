#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# vecfig  --  recorded on Praat 6.6.30
# Input: vt -- 60 rows, 2 columns
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

include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-core-utilities.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-core-descriptive.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-extract.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-output.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-inferential.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-psychometrics.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-categorical.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-result-writer.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-record.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/graphs/eml-graph-procedures.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/graphs/eml-draw-procedures.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-analysis.praat
include /home/claude/repo/harness/vecfig/out/work/record/plugin/stats/eml-demo-tables.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: vt -- 60 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# None of them is built or opened by a step below: see
# PRECONDITION, and open them before you run this script.
# ------------------------------------------------------------

# ============================================================
# PRECONDITION -- THIS SCRIPT CANNOT REBUILD ITS DATA
#
# Table vt was already open when this recording started.
# Nothing in the session made it, so nothing below can remake it.
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
data1$ = "Table vt"   ; run 1, steps 1 (draw), 2 (save)
data2$ = "Table vt"   ; run 2, steps 3 (draw), 4 (save)
groupCol$      = "grp"   ; the grouping column -- run 1, step 1 (draw)
valueCol$      = "val"   ; the measured column -- run 1, step 1 (draw)
groupCol2$     = "grp"   ; the grouping column -- run 2, step 3 (draw)
valueCol2$     = "val"   ; the measured column -- run 2, step 3 (draw)
axisYMin       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 1 (draw)
axisYMax       = 0.0   ; on the recorded data this resolved to 140.0000 .. 320.0000; auto adapts to other data
axisYMin2      = 0   ; the y-axis range -- as typed in the dialog -- run 2, step 3 (draw)
axisYMax2      = 300   ; the figure was drawn on 0.0000 .. 300.0000
figureFormat$  = "PNG, EPS"   ; the figure formats saved -- PNG always, EPS and PDF when ticked -- run 1, step 2 (save)
figureFormat2$ = "PNG, PDF"   ; the figure formats saved -- PNG always, EPS and PDF when ticked -- run 2, step 4 (save)
eraseFirst     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 1 (draw)
panelOriginX   = 0   ; inches from the left of the page to this panel's corner -- run 1, step 1 (draw)
panelOriginY   = 0   ; inches from the top of the page to this panel's corner -- run 1, step 1 (draw)
lineStyle      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 1 (draw)
secondAxisOn   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 1 (draw)
eraseFirst2    = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 2, step 3 (draw)
panelOriginX2  = 0   ; inches from the left of the page to this panel's corner -- run 2, step 3 (draw)
panelOriginY2  = 0   ; inches from the top of the page to this panel's corner -- run 2, step 3 (draw)
lineStyle2     = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 2, step 3 (draw)
secondAxisOn2  = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 2, step 3 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of val, grouped by grp, 3 groups.
# Violin width is a kernel density estimate, not a count.

emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
@emlDrawViolinPlot: data, "first figure", "Group", "val", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax

# Axis resolved to 140.0000 .. 320.0000 over 3 groups on the recorded data; auto adapts to other data.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "val".

# --- Step 2 (save) ---
selectObject: data1$
data = selected ()
# Save the outputs of this analysis
# Every output shares one folder and one name, so they stay a set.

outputFolder$ = "/home/claude/repo/harness/vecfig/out/files/replay"
@emlRecordReplaySave: 1, "figA_20260817_120000", outputFolder$, figureFormat$

# The same step through the menu:
# In the GUI: the Save button on the post-analysis or post-draw dialog.

# --- Step 3 (draw) ---
selectObject: data2$
data = selected ()
# Box plot: second figure
# Whisker convention and outlier rule are stated in the figure, not assumed.

emlEraseFirst = eraseFirst2
emlPanelOriginX = panelOriginX2
emlPanelOriginY = panelOriginY2
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle2
emlSecondAxisOn = secondAxisOn2
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
@emlDrawBoxPlot: data, "second figure", "Group", "val", 6, 4, "color", 1, groupCol2$, valueCol2$, axisYMin2, axisYMax2

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 4 (save) ---
selectObject: data2$
data = selected ()
# Save the outputs of this analysis
# Every output shares one folder and one name, so they stay a set.

outputFolder$ = "/home/claude/repo/harness/vecfig/out/files/replay"
@emlRecordReplaySave: 1, "figB_20260817_120000", outputFolder$, figureFormat2$

# The same step through the menu:
# In the GUI: the Save button on the post-analysis or post-draw dialog.


