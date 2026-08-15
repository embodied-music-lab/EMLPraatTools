#!praat
# ============================================================
# EML Praat Tools -- recorded workflow
# Sat Aug 15 15:22:10 2026  --  recorded on Praat 6.6.30
# (The session's start time was lost -- its record table was
# removed from the Objects window -- so the time above is when
# the recorder noticed, not when recording began.)
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

include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/stats/eml-core-utilities.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/stats/eml-core-descriptive.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/stats/eml-extract.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/stats/eml-output.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/stats/eml-inferential.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/stats/eml-result-writer.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/stats/eml-record.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/graphs/eml-graph-procedures.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/graphs/eml-annotation-procedures.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/graphs/eml-draw-procedures.praat
include ~/.eml_replay_meta_prefs/plugin_EML_Praat_Tools/stats/eml-analysis.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table vt -- 40 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object or a column.
data1$ = "Table vt"   ; steps 1 (analysis), 2 (analysis)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# a recorded step

; nothing


# --- Step 2 (analysis) ---
selectObject: data1$
data = selected ()
# a recorded step

; nothing



