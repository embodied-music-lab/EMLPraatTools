#!praat
# ============================================================
# EML Praat Tools -- recorded workflow
# 16 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table lg -- 56 rows, 3 columns
# ============================================================

# ------------------------------------------------------------
# THE EML LIBRARY
# Recorded under Praat 6.6.30. Paths are home-relative, so they work
# for any user on this platform. If this file fails to parse, the
# plugin is somewhere else -- edit this block and nothing else.
#
#   Praat 6.x  Linux    ~/.praat-dir/plugin_EML_Praat_Tools
#   Praat 7.x  Linux    ~/.config/praat/plugin_EML_Praat_Tools
#   macOS      ~/Library/Preferences/Praat Prefs/plugin_EML_Praat_Tools
#   Windows    ~/Praat/plugin_EML_Praat_Tools
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
data1$ = "Table lg"   ; steps 1 (analysis), 2 (draw)
valueCol$    = "val"   ; the measured column -- steps 1 (analysis), 2 (draw)
groupCol$    = "grp"   ; the grouping column -- step 1 (analysis)
categoryCol$ = "grp"   ; the category column -- step 2 (draw)
subgroupCol$ = "sub"   ; the sub-group column -- step 2 (draw)
axisYMin     = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- step 2 (draw)
axisYMax     = 0.0   ; on the recorded data it resolved to 195.0000 .. 275.0000
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# One-way ANOVA of val by grp, 4 groups.
# Normality was NOT tested on this path.

@emlRunAnovaAnalysis: data, valueCol$, groupCol$, 0

# F(3, 52) = 151.3899, p = 0.0000000000000000000000001, eta-squared = 0.8973
#   Cohort 1: n = 14, mean = 206.1773
#   Cohort 2: n = 14, mean = 212.9870
#   Cohort 3: n = 14, mean = 217.2132
#   Cohort 4: n = 14, mean = 224.6427
# The same step through the menu:
# In the GUI: New > EML Tools > Compare k groups (ANOVA)...,
# with Data column "val" and Group column "grp".

# --- Step 2 (draw) ---
selectObject: data1$
data = selected ()
# Grouped violin: f0 by cohort
# Violin width is a kernel density estimate, not a count.

annotate = 0
@emlDrawGroupedViolin: data, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4, "color", 1, categoryCol$, subgroupCol$, valueCol$, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...


