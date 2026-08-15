#!praat
# ============================================================
# EML Praat Tools -- recorded workflow
# 14 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table vt -- 40 rows, 2 columns
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
# Recorded against: Table vt -- 40 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects here for this recorded workflow.
# Edit a name to run the same workflow on other data;
# nothing below this block names an object.
data1$ = "Table vt"   ; steps 1 (analysis), 2 (save)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# Two-group comparison: val by grp, parametric
# Equal-variance assumption: Welch.

@emlRunTwoGroupAnalysis: data, "val", "grp", "parametric", 0

# Cohort 1: n = 20, mean = 2.2104, SD = 0.3165
#   Cohort 2: n = 20, mean = 3.3083, SD = 0.4774
# The same step through the menu:
# In the GUI: New > EML Tools > Compare two groups...

# --- Step 2 (save) ---
selectObject: data1$
data = selected ()
# Save the outputs of this analysis
# Every output shares one folder and one name, so they stay a set.

outputFolder$ = "/home/claude/EMLPraatTools/harness/record/replay_out/saved"
@emlRecordReplaySave: 0, "vt_two-group_20260814_120000", outputFolder$

# The same step through the menu:
# In the GUI: the Save button on the post-analysis or post-draw dialog.


