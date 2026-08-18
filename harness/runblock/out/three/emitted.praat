#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 17 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table t1 -- 20 rows, 2 columns
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

include ~/EMLPraatTools/plugin/stats/eml-core-utilities.praat
include ~/EMLPraatTools/plugin/stats/eml-core-descriptive.praat
include ~/EMLPraatTools/plugin/stats/eml-extract.praat
include ~/EMLPraatTools/plugin/stats/eml-output.praat
include ~/EMLPraatTools/plugin/stats/eml-inferential.praat
include ~/EMLPraatTools/plugin/stats/eml-result-writer.praat
include ~/EMLPraatTools/plugin/stats/eml-record.praat
include ~/EMLPraatTools/plugin/graphs/eml-graph-procedures.praat
include ~/EMLPraatTools/plugin/graphs/eml-annotation-procedures.praat
include ~/EMLPraatTools/plugin/graphs/eml-draw-procedures.praat
include ~/EMLPraatTools/plugin/stats/eml-analysis.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table t1 -- 20 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table t1"   ; run 1, step 1 (draw)
data2$ = "Table t2"   ; run 2, step 2 (draw)
data3$ = "Table t3"   ; run 3, step 3 (draw)
groupCol$  = "site"   ; the grouping column -- run 1, step 1 (draw)
valueCol$  = "n"   ; the measured column -- run 1, step 1 (draw)
groupCol2$ = "ward"   ; the grouping column -- run 2, step 2 (draw)
valueCol2$ = "n"   ; the measured column -- run 2, step 2 (draw)
groupCol3$ = "block"   ; the grouping column -- run 3, step 3 (draw)
valueCol3$ = "n"   ; the measured column -- run 3, step 3 (draw)
axisYMin   = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 1 (draw)
axisYMax   = 0.0   ; on the recorded data it resolved to 2.5000 .. 5.5000
axisYMin2  = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 2, step 2 (draw)
axisYMax2  = 0.0   ; on the recorded data it resolved to 10.0000 .. 14.0000
axisYMin3  = 2   ; the y-axis range -- as typed in the dialog -- run 3, step 3 (draw)
axisYMax3  = 30   ; the figure was drawn on 2.0000 .. 30.0000
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# Box plot: One
# Whisker convention and outlier rule are stated in the figure, not assumed.

@emlDrawBoxPlot: data, "One", "Site", "n", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 2 (draw) ---
selectObject: data2$
data = selected ()
# Box plot: Two
# Whisker convention and outlier rule are stated in the figure, not assumed.

@emlDrawBoxPlot: data, "Two", "Ward", "n", 6, 4, "color", 1, groupCol2$, valueCol2$, axisYMin2, axisYMax2

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 3 (draw) ---
selectObject: data3$
data = selected ()
# Box plot: Three
# Whisker convention and outlier rule are stated in the figure, not assumed.

@emlDrawBoxPlot: data, "Three", "Block", "n", 6, 4, "color", 1, groupCol3$, valueCol3$, axisYMin3, axisYMax3

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...


