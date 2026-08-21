#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 21 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table demo -- 4 rows, 2 columns
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

include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-psychometrics.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-categorical.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-record.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-analysis.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-demo-tables.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table demo -- 4 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# None of them is built or opened by a step below: see
# PRECONDITION, and open them before you run this script.
# ------------------------------------------------------------

# ============================================================
# PRECONDITION -- THIS SCRIPT CANNOT REBUILD ITS DATA
#
# Table demo was already open when this recording started.
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
data1$ = "Table demo"   ; run 1, step 1 (edit)
data2$ = "Table demo"   ; run 2, step 2 (edit)
data3$ = "Table demo"   ; run 3, step 3 (edit)
data4$ = "Table demo"   ; run 4, step 4 (edit)
data5$ = "Table demo"   ; run 5, step 5 (edit)
data6$ = "Table demo"   ; run 6, step 6 (edit)
data7$ = "Table demo"   ; run 7, step 7 (edit)

# --- Step 1 (edit) ---
selectObject: data1$
data = selected ()
# Added a row at the end. The table now has 4 rows
# This step changes the table in memory.
# Nothing here writes back to the file the table came from.

Append row

# The same step through the menu:
# In the GUI: select the Table, open EML's Table editor and make
# the change there. An edit typed into Praat's own table
# window is not captured by this recorder.

# --- Step 2 (edit) ---
selectObject: data2$
data = selected ()
# Inserted a row at position 2
# This step changes the table in memory.
# Nothing here writes back to the file the table came from.

Insert row: 2

# The same step through the menu:
# In the GUI: select the Table, open EML's Table editor and make
# the change there. An edit typed into Praat's own table
# window is not captured by this recorder.

# --- Step 3 (edit) ---
selectObject: data3$
data = selected ()
# Deleted row 2
# This step changes the table in memory.
# Nothing here writes back to the file the table came from.

Remove row: 2

# The same step through the menu:
# In the GUI: select the Table, open EML's Table editor and make
# the change there. An edit typed into Praat's own table
# window is not captured by this recorder.

# --- Step 4 (edit) ---
selectObject: data4$
data = selected ()
# Added column added at the end
# This step changes the table in memory.
# Nothing here writes back to the file the table came from.

Append column: "added"

# The same step through the menu:
# In the GUI: select the Table, open EML's Table editor and make
# the change there. An edit typed into Praat's own table
# window is not captured by this recorder.

# --- Step 5 (edit) ---
selectObject: data5$
data = selected ()
# Inserted column inserted at position 2
# This step changes the table in memory.
# Nothing here writes back to the file the table came from.

Insert column: 2, "inserted"

# The same step through the menu:
# In the GUI: select the Table, open EML's Table editor and make
# the change there. An edit typed into Praat's own table
# window is not captured by this recorder.

# --- Step 6 (edit) ---
selectObject: data6$
data = selected ()
# Renamed column inserted to renamed
# This step changes the table in memory.
# Nothing here writes back to the file the table came from.

Rename column (by number): 2, "renamed"

# The same step through the menu:
# In the GUI: select the Table, open EML's Table editor and make
# the change there. An edit typed into Praat's own table
# window is not captured by this recorder.

# --- Step 7 (edit) ---
selectObject: data7$
data = selected ()
# Deleted column renamed, which was column 2 of 4
# This step changes the table in memory.
# Nothing here writes back to the file the table came from.

Remove column: "renamed"

# The same step through the menu:
# In the GUI: select the Table, open EML's Table editor and make
# the change there. An edit typed into Praat's own table
# window is not captured by this recorder.


