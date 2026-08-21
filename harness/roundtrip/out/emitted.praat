#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 21 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table rt_input -- 24 rows, 3 columns
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
# Recorded against: Table rt_input -- 24 rows, 3 columns.
# The objects this workflow ran on are named in the block below.
# Some are built or opened by a step below; the rest are
# listed under PRECONDITION and must be open before you run
# this script.
# ------------------------------------------------------------

# ============================================================
# PRECONDITION -- THIS SCRIPT CANNOT REBUILD ITS DATA
#
# Sound rt_tone was already open when this recording started.
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
data1$ = "Table demo_3groups"   ; run 1, step 1 (create)
data2$ = "Table rt_input"   ; run 2, steps 2 (read), 3 (edit)
data3$ = "Table rt_input"   ; run 3, step 4 (refusal)
data4$ = "Table rt_input"   ; run 4, steps 5 (analysis), 6 (draw), 7 (save)
data5$ = "Sound rt_tone"   ; run 5, step 5 (convert)
# The data file this workflow was recorded from. The path is absolute
# and spelled the way the recording machine spells it:
#   macOS / Linux   /Users/you/data/table.csv
#   Windows         C:/Users/you/data/table.csv
#   Not sure?  Select the Table and press Info -- its Associated file line
#              names the file Praat read it from.
inputFile$     = "/home/claude/repo/harness/roundtrip/out/data/rt_input.csv"   ; the data file read from disk -- step 2 (read)
valueCol4$     = "f0_Hz"   ; the measured column -- run 4, steps 5 (analysis), 6 (draw)
groupCol4$     = "cohort"   ; the grouping column -- run 4, steps 5 (analysis), 6 (draw)
axisYMin4      = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 4, step 6 (draw)
axisYMax4      = 0.0   ; on the recorded data this resolved to -2000.0000 .. 6000.0000; auto adapts to other data
figureFormat4$ = "PNG"   ; the figure formats saved -- PNG always, EPS and PDF when ticked -- run 4, step 7 (save)
eraseFirst4    = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 4, step 6 (draw)
panelOriginX4  = 0   ; inches from the left of the page to this panel's corner -- run 4, step 6 (draw)
panelOriginY4  = 0   ; inches from the top of the page to this panel's corner -- run 4, step 6 (draw)
lineStyle4     = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 4, step 6 (draw)
secondAxisOn4  = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 4, step 6 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (create) ---
# Built Table demo_3groups with the plugin's demo generator: Three-group comparison (Soprano / Mezzo / Alto).
# Seeded with 2067519806, so this rebuilds the recorded table and not a differently-random one.

@emlDemoTable: 2, 2067519806

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Create demo table..., Demo type option 2.

# --- Step 2 (read) ---
# Loaded /home/claude/repo/harness/roundtrip/out/data/rt_input.csv as supplied. Nothing below modifies it.

@emlRecordReplayRead: inputFile$
@emlRecordReplayName: data2$

# The same step through the menu:
# In the GUI: Praat's own Open menu. This plugin registers no
# reader of its own, so a data file arrives through
# Open > Read from file... or Open > Read Table from
# comma-separated file...

# --- Step 3 (edit) ---
selectObject: data2$
data = selected ()
# Changed f0_Hz in row 1 from 100 to 4242
# This step changes the table in memory.
# Nothing here writes back to the file the table came from.

Set string value: 1, "f0_Hz", "4242"

# The same step through the menu:
# In the GUI: select the Table, open EML's Table editor and make
# the change there. An edit typed into Praat's own table
# window is not captured by this recorder.

# --- Step 4 (refusal) ---
selectObject: data3$
data = selected ()
# Refused: Data column "speaker" holds no numbers. 24 cell(s) are not numeric in any locale (row 1: A01). Unrecognized nonnumeric token; excluded.

; (nothing executed at this step -- see the note above)


# --- Step 5 (analysis) ---
selectObject: data4$
data = selected ()
# One-way ANOVA of f0_Hz by cohort, 3 groups.
# Tukey HSD requested. Alpha 0.05 (default, not specified by the user).
# Normality was NOT tested on this path.

@emlReportContext: "recorded script (recorded 21 August 2026, originally analysis dialog)", ""
@emlRunAnovaAnalysis: data, valueCol4$, groupCol4$, 1

# F(2, 21) = 1.0103, p = 0.3811, eta-squared = 0.0878
#   alpha: n = 8, mean = 621.2500
#   bravo: n = 8, mean = 303.5000
#   charlie: n = 8, mean = 903.5000
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare k groups (ANOVA)...,
# with Data column "f0_Hz" and Group column "cohort".

# --- Step 6 (draw) ---
selectObject: data4$
data = selected ()
# Violin plot of f0_Hz, grouped by cohort, 3 groups.
# Violin width is a kernel density estimate, not a count.

annotate = 0
emlEraseFirst = eraseFirst4
emlPanelOriginX = panelOriginX4
emlPanelOriginY = panelOriginY4
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle4
emlSecondAxisOn = secondAxisOn4
@emlDrawViolinPlot: data, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4, "color", 1, groupCol4$, valueCol4$, axisYMin4, axisYMax4

# Axis resolved to -2000.0000 .. 6000.0000 over 3 groups on the recorded data; auto adapts to other data.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "cohort", Value column "f0_Hz".

# --- Step 7 (save) ---
selectObject: data4$
data = selected ()
# Save the outputs of this analysis
# Every output shares one folder and one name, so they stay a set.

annotate = 0
outputFolder$ = "/home/claude/repo/harness/roundtrip/out/saved"
@emlRecordReplaySave: 1, "rt_roundtrip", outputFolder$, figureFormat4$

# The same step through the menu:
# In the GUI: the Save button on the post-analysis or post-draw dialog.

# --- Step 5 (convert) ---
selectObject: data5$
data = selected ()
# Converted Sound rt_tone to Spectrum rt_tone.
# Fast (FFT) transform, which is what the figure was drawn from.

data = To Spectrum: "yes"

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.


