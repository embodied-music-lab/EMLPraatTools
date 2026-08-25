#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# SESSION_B  --  recorded on Praat 6.6.30
# Input: Table vt -- 40 rows, 2 columns
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

include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-psychometrics.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-categorical.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-record.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-analysis.praat
include ~/.eml_replay_meta_prefs/plugin_EML_StatsGraphs/stats/eml-demo-tables.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table vt -- 40 rows, 2 columns.
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
data1$ = "Table vt"   ; run 1, step 1 (analysis)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# a recorded step

@emlReportContext: "recorded script (recorded SESSION_B, originally analysis dialog)", ""
emlGroupSortAlphabetical = 0
emlShowExplanations = 1
; nothing



