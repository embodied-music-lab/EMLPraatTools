# ============================================================
# EML Praat Tools -- recorded workflow
# roundtrip  --  recorded on Praat 6.6.30
# Input: demo_3groups_input.csv -- 45 rows, 4 columns
# ============================================================

# ------------------------------------------------------------
# THE EML LIBRARY
# Recorded under Praat 6.6.30. Paths are home-relative, so they work
# for any user on this platform. If this file fails to parse, the
# plugin is somewhere else -- edit this block and nothing else.
#
#   Praat 6.x  Linux    ~/.praat-dir/plugin_EMLPraatTools
#   Praat 7.x  Linux    ~/.config/praat/plugin_EMLPraatTools
#   macOS      ~/Library/Preferences/Praat Prefs/plugin_EMLPraatTools
#   Windows    ~/Praat/plugin_EMLPraatTools
#   Not sure?  Run  writeInfoLine: preferencesDirectory$
#
# A version guard cannot help here: `include` is refused inside an
# if-block, so the file cannot choose its own path at run time.
# The barrel eml-lib-stats.praat will NOT work in place of this
# list: its own relative includes resolve against THIS file's
# folder, not its own.
# ------------------------------------------------------------

include /home/claude/EMLPraatTools/plugin/stats/eml-core-utilities.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-core-descriptive.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-extract.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-output.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-inferential.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-result-writer.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-record.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-graph-procedures.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/EMLPraatTools/plugin/graphs/eml-draw-procedures.praat
include /home/claude/EMLPraatTools/plugin/stats/eml-analysis.praat

@emlInitDrawingDefaults

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: demo_3groups_input.csv -- 45 rows, 4 columns.
# Select that Table in the Objects window, then run this script.
# NOTE: later steps in this session ran on a DIFFERENT object.
# Running this file against one Table will not reproduce them.
# ------------------------------------------------------------

table = selected ("Table")

# --- Step 1 (analysis) ---
# One-way ANOVA of SPL_dB by voice_type, 3 groups.
# Tukey HSD requested. Alpha 0.05 (default, not specified by the user).
# Normality was NOT tested on this path.

@emlRunAnovaAnalysis: table, "SPL_dB", "voice_type", 1

# F(2, 42) = 18.0603, p = 0.000002, eta-squared = 0.4624
#   Soprano: n = 15, mean = 93.8877
#   Mezzo: n = 15, mean = 87.8207
#   Alto: n = 15, mean = 85.1470
# The same step through the menu:
# In the GUI: New > EML Tools > Compare k groups (ANOVA)...,
# with Data column "SPL_dB" and Group column "voice_type".


