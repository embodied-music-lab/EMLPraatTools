#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 21 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table H_input -- 12 rows, 2 columns
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

include /home/claude/repo/harness/edithook/out/stage/stats/eml-core-utilities.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-core-descriptive.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-extract.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-output.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-inferential.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-psychometrics.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-categorical.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-result-writer.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-record.praat
include /home/claude/repo/harness/edithook/out/stage/graphs/eml-graph-procedures.praat
include /home/claude/repo/harness/edithook/out/stage/graphs/eml-annotation-procedures.praat
include /home/claude/repo/harness/edithook/out/stage/graphs/eml-draw-procedures.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-analysis.praat
include /home/claude/repo/harness/edithook/out/stage/stats/eml-demo-tables.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table H_input -- 12 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# Every one of them is built or opened by a step below, so
# this script supplies its own data and runs on its own.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table H_input"   ; run 1, steps 1 (read), 2 (edit)
data2$ = "Table H_input"   ; run 2, step 3 (analysis)
# The data file this workflow was recorded from. The path is absolute
# and spelled the way the recording machine spells it:
#   macOS / Linux   /Users/you/data/table.csv
#   Windows         C:/Users/you/data/table.csv
#   Not sure?  Select the Table and press Info -- its Associated file line
#              names the file Praat read it from.
inputFile$ = "/home/claude/repo/harness/edithook/out/H_input.csv"   ; the data file read from disk -- step 1 (read)
valueCol2$ = "f0_Hz"   ; the measured column -- run 2, step 3 (analysis)
groupCol2$ = "group"   ; the grouping column -- run 2, step 3 (analysis)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (read) ---
# Loaded /home/claude/repo/harness/edithook/out/H_input.csv as supplied. Nothing below modifies it.

@emlRecordReplayRead: inputFile$
@emlRecordReplayName: data1$

# The same step through the menu:
# In the GUI: Praat's own Open menu. This plugin registers no
# reader of its own, so a data file arrives through
# Open > Read from file... or Open > Read Table from
# comma-separated file...

# --- Step 2 (edit) ---
selectObject: data1$
data = selected ()
# Changed f0_Hz in row 1 from 100 to 4242
# This step changes the table in memory.
# Nothing here writes back to the file the table came from.


# The same step through the menu:
# In the GUI: select the Table, open EML's Table editor and make
# the change there. An edit typed into Praat's own table
# window is not captured by this recorder.

# --- Step 3 (analysis) ---
selectObject: data2$
data = selected ()
# One-way ANOVA of f0_Hz by group, 3 groups.
# Normality was NOT tested on this path.

@emlReportContext: "recorded script (recorded 21 August 2026, originally analysis dialog)", ""
@emlRunAnovaAnalysis: data, valueCol2$, groupCol2$, 0

# F(2, 9) = 0.8730, p = 0.4503, eta-squared = 0.1625
#   A: n = 4, mean = 1129.5000
#   B: n = 4, mean = 120.0000
#   C: n = 4, mean = 206.0000
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare k groups (ANOVA)...,
# with Data column "f0_Hz" and Group column "group".


