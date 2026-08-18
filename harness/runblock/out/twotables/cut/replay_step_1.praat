#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 17 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table cityA -- 24 rows, 2 columns
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
include ~/EMLPraatTools/plugin/stats/eml-psychometrics.praat
include ~/EMLPraatTools/plugin/stats/eml-categorical.praat
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
# Recorded against: Table cityA -- 24 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range or a figure format.
data1$ = "Table cityA"   ; run 1, step 1 (draw)
data2$ = "Table cityB"   ; run 2, step 2 (draw)
groupCol$     = "site"   ; the grouping column -- run 1, step 1 (draw)
valueCol$     = "n"   ; the measured column -- run 1, step 1 (draw)
groupCol2$    = "ward"   ; the grouping column -- run 2, step 2 (draw)
valueCol2$    = "n"   ; the measured column -- run 2, step 2 (draw)
axisYMin      = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 1, step 1 (draw)
axisYMax      = 0.0   ; on the recorded data it resolved to 3.5000 .. 7.0000
axisYMin2     = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 2, step 2 (draw)
axisYMax2     = 0.0   ; on the recorded data it resolved to 9.5000 .. 14.0000
eraseFirst    = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 1, step 1 (draw)
panelOriginX  = 0   ; inches from the left of the page to this panel's corner -- run 1, step 1 (draw)
panelOriginY  = 0   ; inches from the top of the page to this panel's corner -- run 1, step 1 (draw)
lineStyle     = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 1, step 1 (draw)
secondAxisOn  = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 1, step 1 (draw)
eraseFirst2   = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 2, step 2 (draw)
panelOriginX2 = 0   ; inches from the left of the page to this panel's corner -- run 2, step 2 (draw)
panelOriginY2 = 0   ; inches from the top of the page to this panel's corner -- run 2, step 2 (draw)
lineStyle2    = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 2, step 2 (draw)
secondAxisOn2 = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 2, step 2 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# Two tables that each call their count column "n" -- the collision the
# (role, literal) key used to collapse into one variable.
Create Table with column names: "cityA", 0, "site n"
st = 20260817
for g from 1 to 2
    for k from 1 to 12
        st = (1103515245 * st + 12345) mod 2147483648
        Append row
        r = Get number of rows
        Set string value: r, "site", "Site " + string$ (g)
        Set numeric value: r, "n", 3 + g * 1.5 + (st / 2147483648 - 0.5) * 1.2
    endfor
endfor
tableA = selected ("Table")
Create Table with column names: "cityB", 0, "ward n"
st = 77770001
for g from 1 to 2
    for k from 1 to 12
        st = (1103515245 * st + 12345) mod 2147483648
        Append row
        r = Get number of rows
        Set string value: r, "ward", "Ward " + string$ (g)
        Set numeric value: r, "n", 9 + g * 2.0 + (st / 2147483648 - 0.5) * 1.6
    endfor
endfor
tableB = selected ("Table")
Erase all
# --- Step 1 (draw) ---
selectObject: data1$
data = selected ()
# Box plot: City A
# Whisker convention and outlier rule are stated in the figure, not assumed.

emlEraseFirst = eraseFirst
emlPanelOriginX = panelOriginX
emlPanelOriginY = panelOriginY
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle
emlSecondAxisOn = secondAxisOn
@emlDrawBoxPlot: data, "City A", "Site", "n", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/runblock/out/twotables/REPLAY_step1.png"
