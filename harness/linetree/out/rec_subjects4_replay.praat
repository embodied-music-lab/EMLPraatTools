#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# Fri Aug 21 04:10:47 2026  --  recorded on Praat 6.6.30
# Input: Table lt_subjects4 -- 12 rows, 5 columns
# ============================================================

# ------------------------------------------------------------
# THE EML LIBRARY
# Recorded under Praat 6.6.30. Paths are home-relative, so they work
# for any user on this platform. If this file fails to parse, the
# plugin is somewhere else -- edit this block and nothing else.
#
#   Praat 6.x  Linux    /home/claude/repo/plugin_EML_StatsGraphs
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

include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-extract.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-output.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-psychometrics.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-categorical.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-record.praat
include /home/claude/repo/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include /home/claude/repo/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include /home/claude/repo/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-analysis.praat
include /home/claude/repo/plugin_EML_StatsGraphs/stats/eml-demo-tables.praat

@emlInitDrawingDefaults
@emlClearAnnotations
# ---------------------------------------------------------------------------
# harness/linetree/data_subjects4.praat
#
# FOUR SUBJECT COLUMNS, ONE ROW PER TIME. The shape the tree calls shape 1
# with role = subjects: four numeric columns beside the time column, no text
# column, and exactly one observation at each time.
#
# THE FOUR SERIES OCCUPY FOUR DISJOINT BANDS -- 100s, 200s, 300s, 400s -- so
# that "four series are on the page" is answerable by looking at the figure
# rather than by trusting the melt. A fixture whose lines crossed would make
# the same claim unfalsifiable at the pixel level.
#
# NO TIME VALUE REPEATS, which is the ABSENT arm of the replication fork: the
# interval field must not appear on this leg's column page.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_subjects4", 0, "time S1 S2 S3 S4"
for i from 1 to 12
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i
    Set numeric value: r, "S1", 100 + i * 3 + (i mod 3) * 2
    Set numeric value: r, "S2", 200 + i * 2 + (i mod 4) * 3
    Set numeric value: r, "S3", 300 + i * 3 - (i mod 3) * 4
    Set numeric value: r, "S4", 400 + i * 2 + (i mod 5) * 2
endfor
ltSubjects4Id = selected ("Table")

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table lt_subjects4 -- 12 rows, 5 columns.
# The objects this workflow ran on are named in the block below.
# None of them is built or opened by a step below: see
# PRECONDITION, and open them before you run this script.
# ------------------------------------------------------------

# ============================================================
# PRECONDITION -- THIS SCRIPT CANNOT REBUILD ITS DATA
#
# Table lt_subjects4 was already open when this recording started.
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
data1$ = "Table lt_subjects4"   ; run 1, steps 1 (convert), 2 (draw)
timeCol$     = "time"   ; the time column -- run 1, steps 1 (convert), 2 (draw)
seriesCols$  = "S1,S2,S3,S4"   ; the columns drawn as series, in order -- run 1, step 1 (convert)
valueCol$    = "eml_value"   ; the measured column -- run 1, step 2 (draw)
groupCol$    = "eml_series"   ; the grouping column -- run 1, step 2 (draw)
axisYMin     = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 2 (draw)
axisYMax     = 0.0   ; on the recorded data this resolved to 50.0000 .. 722.7072; auto adapts to other data
eraseFirst   = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 2 (draw)
panelOriginX = 0   ; inches from the left of the page to this panel's corner -- run 1, step 2 (draw)
panelOriginY = 0   ; inches from the top of the page to this panel's corner -- run 1, step 2 (draw)
seriesRole$  = "subjects"   ; a page setting -- run 1, step 2 (draw)
lineStyle    = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 2 (draw)
secondAxisOn = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 2 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (convert) ---
selectObject: data1$
data = selected ()
# Converted Table lt_subjects4 to Table eml_melt.
# These columns are one measurement on several subjects, so they are stacked into the long shape every line chart is drawn from: the time column, a series name and a value.

prev_violinShowJitter = 0
prev_boxShowJitter = 0
prev_gvShowJitter = 0
prev_gbShowJitter = 0
annotate = 0
@emlGraphsMeltSeries: data, timeCol$, seriesCols$
data = emlGraphsMeltSeries.tableId
selectObject: data

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 2 (draw) ---
# Line chart: Line Chart (±CI): lt subjects4

prev_violinShowJitter = 0
prev_boxShowJitter = 0
prev_gvShowJitter = 0
prev_gbShowJitter = 0
annotate = 0
emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlSeriesRole$ = seriesRole$
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
@emlDrawTimeSeries: data, "Line Chart (±CI): lt subjects4", "Time", "", 6, 4, "color", 1, timeCol$, valueCol$, groupCol$, 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...


Select outer viewport: 0, 6, 0, 4
Save as 300-dpi PNG file: "/home/claude/repo/harness/linetree/out/rec_subjects4_replay.png"
