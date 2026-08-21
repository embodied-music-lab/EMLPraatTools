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

include ~/repo/plugin/stats/eml-core-utilities.praat
include ~/repo/plugin/stats/eml-core-descriptive.praat
include ~/repo/plugin/stats/eml-extract.praat
include ~/repo/plugin/stats/eml-output.praat
include ~/repo/plugin/stats/eml-inferential.praat
include ~/repo/plugin/stats/eml-psychometrics.praat
include ~/repo/plugin/stats/eml-categorical.praat
include ~/repo/plugin/stats/eml-result-writer.praat
include ~/repo/plugin/stats/eml-record.praat
include ~/repo/plugin/graphs/eml-graph-procedures.praat
include ~/repo/plugin/graphs/eml-annotation-procedures.praat
include ~/repo/plugin/graphs/eml-draw-procedures.praat
include ~/repo/plugin/stats/eml-analysis.praat
include ~/repo/plugin/stats/eml-demo-tables.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: demo_3groups_input.csv -- 45 rows, 4 columns.
# The objects this workflow ran on are named in the block below.
# Every one of them is built or opened by a step below, so
# this script supplies its own data and runs on its own.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table demo_3groups_input"   ; run 1, steps 1 (read), 2 (analysis)
# The data file this workflow was recorded from. The path is absolute
# and spelled the way the recording machine spells it:
#   macOS / Linux   /Users/you/data/table.csv
#   Windows         C:/Users/you/data/table.csv
#   Not sure?  Select the Table and press Info -- its Associated file line
#              names the file Praat read it from.
inputFile$ = "/home/claude/repo/evidence/csv/demo_3groups_input.csv"   ; the data file read from disk -- step 1 (read)
valueCol$  = "SPL_dB"   ; the measured column -- run 1, step 2 (analysis)
groupCol$  = "voice_type"   ; the grouping column -- run 1, step 2 (analysis)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (read) ---
# Loaded /home/claude/repo/evidence/csv/demo_3groups_input.csv as supplied. Nothing below modifies it.

@emlRecordReplayRead: inputFile$
@emlRecordReplayName: data1$

# The same step through the menu:
# In the GUI: Praat's own Open menu. This plugin registers no
# reader of its own, so a data file arrives through
# Open > Read from file... or Open > Read Table from
# comma-separated file...

# --- Step 2 (analysis) ---
selectObject: data1$
data = selected ()
# One-way ANOVA of SPL_dB by voice_type, 3 groups.
# Tukey HSD requested. Alpha 0.05 (default, not specified by the user).
# Normality was NOT tested on this path.

@emlReportContext: "recorded script (recorded roundtrip, originally analysis dialog)", ""
@emlRunAnovaAnalysis: data, valueCol$, groupCol$, 1

# F(2, 42) = 18.0603, p = 0.000002, eta-squared = 0.4624
#   Soprano: n = 15, mean = 93.8877
#   Mezzo: n = 15, mean = 87.8207
#   Alto: n = 15, mean = 85.1470
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare k groups (ANOVA)...,
# with Data column "SPL_dB" and Group column "voice_type".


