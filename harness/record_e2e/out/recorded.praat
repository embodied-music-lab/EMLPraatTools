# ============================================================
# EML Praat Tools -- recorded workflow
#   --  recorded on Praat 6.6.30
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

include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-core-utilities.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-core-descriptive.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-extract.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-output.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-inferential.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-result-writer.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-record.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/graphs/eml-graph-procedures.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/graphs/eml-annotation-procedures.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/graphs/eml-draw-procedures.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-analysis.praat

@emlInitDrawingDefaults

# ------------------------------------------------------------
# THE OBJECT
# NOT RECORDED. Nothing in this session named the object it
# ran on, so a reader cannot check that the right Table is
# selected before running this file.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects here for this recorded workflow.
# Edit a name to run the same workflow on other data;
# nothing below this block names an object.
data1$ = "Table voiceA"   ; steps 1 (analysis), 2 (draw)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# One-way ANOVA of spl by grp, 2 groups.
# Normality was NOT tested on this path.

@emlRunAnovaAnalysis: data, "spl", "grp", 0

# F(1, 22) = 4.7550, p = 0.0402, eta-squared = 0.1777
#   y: n = 12, mean = 65.7757
#   x: n = 12, mean = 62.9633
# The same step through the menu:
# In the GUI: New > EML Tools > Compare k groups (ANOVA)...,
# with Data column "spl" and Group column "grp".

# --- Step 2 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of spl, grouped by grp, 2 groups.
# Violin width is a kernel density estimate, not a count.

@emlDrawViolinPlot: data, "Violin", "grp", "spl", 6, 4, "color", 1, "grp", "spl", 54.000000, 74.000000

# Axis resolved to 54.0000 .. 74.0000 over 2 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "spl".


