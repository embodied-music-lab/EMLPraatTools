#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 17 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table sa -- 24 rows, 2 columns
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

include ~/EMLPraatTools/plugin/stats/eml-core-utilities.praat
include ~/EMLPraatTools/plugin/stats/eml-core-descriptive.praat
include ~/EMLPraatTools/plugin/stats/eml-extract.praat
include ~/EMLPraatTools/plugin/stats/eml-output.praat
include ~/EMLPraatTools/plugin/stats/eml-inferential.praat
include ~/EMLPraatTools/plugin/stats/eml-result-writer.praat
include ~/EMLPraatTools/plugin/stats/eml-record.praat
include ~/EMLPraatTools/plugin/graphs/eml-graph-procedures.praat
include ~/EMLPraatTools/plugin/graphs/eml-annotation-procedures.praat
include ~/EMLPraatTools/plugin/graphs/eml-draw-procedures.praat
include ~/EMLPraatTools/plugin/stats/eml-analysis.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table sa -- 24 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table sa"   ; run 1, steps 1 (draw), 2 (save)
data2$ = "Table sb"   ; run 2, steps 3 (draw), 4 (save)
groupCol$      = "grp"   ; the grouping column -- run 1, step 1 (draw)
valueCol$      = "val"   ; the measured column -- run 1, step 1 (draw)
groupCol2$     = "grp"   ; the grouping column -- run 2, step 3 (draw)
valueCol2$     = "val"   ; the measured column -- run 2, step 3 (draw)
axisYMin       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 1 (draw)
axisYMax       = 0.0   ; on the recorded data it resolved to 5.5000 .. 9.0000
axisYMin2      = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 2, step 3 (draw)
axisYMax2      = 0.0   ; on the recorded data it resolved to 15.5000 .. 19.0000
figureFormat$  = "PNG"   ; the figure formats saved -- PNG always, EPS and PDF when ticked -- run 1, step 2 (save)
figureFormat2$ = "PNG, PDF"   ; the figure formats saved -- PNG always, EPS and PDF when ticked -- run 2, step 4 (save)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# Two tables, so that two passes each draw a figure and each save it with a
# different format choice.
procedure mkS: .nm$, .seed, .lift
    Create Table with column names: .nm$, 0, "grp val"
    .st = .seed
    for .g from 1 to 2
        for .k from 1 to 12
            .st = (1103515245 * .st + 12345) mod 2147483648
            Append row
            .r = Get number of rows
            Set string value: .r, "grp", "G" + string$ (.g)
            Set numeric value: .r, "val",
            ... 5 + .lift + .g * 1.5 + (.st / 2147483648 - 0.5) * 1.2
        endfor
    endfor
    .id = selected ("Table")
endproc
@mkS: "sa", 121212, 0
tableSa = mkS.id
@mkS: "sb", 343434, 10
tableSb = mkS.id
Erase all
# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# Box plot: A
# Whisker convention and outlier rule are stated in the figure, not assumed.

@emlDrawBoxPlot: data, "A", "Group", "val", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 2 (save) ---
selectObject: data1$
data = selected ()
# Save the outputs of this analysis
# Every output shares one folder and one name, so they stay a set.

outputFolder$ = "/home/claude/EMLPraatTools/harness/runblock/out/saveruns/saved1"
@emlRecordReplaySave: 1, "figA_20260817_120000", outputFolder$, figureFormat$

# The same step through the menu:
# In the GUI: the Save button on the post-analysis or post-draw dialog.

