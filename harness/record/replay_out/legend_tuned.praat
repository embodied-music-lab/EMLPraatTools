#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 16 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table lg -- 56 rows, 3 columns
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
# Recorded against: Table lg -- 56 rows, 3 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range.
data1$ = "Table lg"   ; step 1 (draw)
categoryCol$ = "grp"   ; the category column -- step 1 (draw)
subgroupCol$ = "sub"   ; the sub-group column -- step 1 (draw)
valueCol$    = "val"   ; the measured column -- step 1 (draw)
axisYMin     = 195.0000   ; the y-axis range -- AUTO (both 0 = computed from the data) -- step 1 (draw)
axisYMax     = 275.0000   ; on the recorded data it resolved to 195.0000 .. 275.0000
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# Grouped violin: f0 by cohort
# Violin width is a kernel density estimate, not a count.

annotate = 0
@emlDrawGroupedViolin: data, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4, "color", 1, categoryCol$, subgroupCol$, valueCol$, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...


