#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# roundtrip  --  recorded on Praat 6.6.30
# Input: demo_3groups_input.csv -- 45 rows, 4 columns
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
# Recorded against: demo_3groups_input.csv -- 45 rows, 4 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range.
data1$ = "Table demo_3groups_input"   ; step 1 (analysis)
valueCol$ = "SPL_dB"   ; the measured column -- step 1 (analysis)
groupCol$ = "voice_type"   ; the grouping column -- step 1 (analysis)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# One-way ANOVA of SPL_dB by voice_type, 3 groups.
# Tukey HSD requested. Alpha 0.05 (default, not specified by the user).
# Normality was NOT tested on this path.

@emlRunAnovaAnalysis: data, valueCol$, groupCol$, 1

# F(2, 42) = 18.0603, p = 0.000002, eta-squared = 0.4624
#   Soprano: n = 15, mean = 93.8877
#   Mezzo: n = 15, mean = 87.8207
#   Alto: n = 15, mean = 85.1470
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare k groups (ANOVA)...,
# with Data column "SPL_dB" and Group column "voice_type".


