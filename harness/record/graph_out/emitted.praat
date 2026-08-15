#!praat
# ============================================================
# EML Praat Tools -- recorded workflow
# graph roundtrip  --  recorded on Praat 6.6.30
# Input: vt -- 100 rows, 2 columns
# ============================================================

# ------------------------------------------------------------
# THE EML LIBRARY
# Recorded under Praat 6.6.30. These paths are ABSOLUTE to the machine
# that recorded this session: the plugin does not sit under a
# home folder here, so there is no ~ to write and this file is
# NOT portable as it stands. To run it anywhere else you must
# edit this block and nothing else -- the usual locations are
# listed below.
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
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: vt -- 100 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects here for this recorded workflow.
# Edit a name to run the same workflow on other data;
# nothing below this block names an object.
data1$ = "Table vt"   ; step 1 (draw)

# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of val, grouped by grp, 4 groups.
# Violin width is a kernel density estimate, not a count.

@emlDrawViolinPlot: data, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4, "color", 1, "grp", "val", 170.000000, 270.000000

# Axis resolved to 170.0000 .. 270.0000 over 4 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "val".


