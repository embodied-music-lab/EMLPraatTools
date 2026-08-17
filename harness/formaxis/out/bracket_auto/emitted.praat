#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# form axis  --  recorded on Praat 6.6.30
# Input: fa -- 100 rows, 4 columns
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
# Recorded against: fa -- 100 rows, 4 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range.
data1$ = "Table fa"   ; steps 1 (analysis), 2 (draw)
valueCol$ = "val"   ; the measured column -- steps 1 (analysis), 2 (draw)
groupCol$ = "grp"   ; the grouping column -- steps 1 (analysis), 2 (draw)
axisYMin  = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- step 2 (draw)
axisYMax  = 0.0   ; on the recorded data it resolved to 195.0000 .. 268.9205
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# Group comparison on a figure: val by grp, auto, 4 groups
# Reached through the figure's annotation rather than the stats menu; the test and the correction are the same.

annotate = 1
@emlBridgeGroupComparison: data, valueCol$, groupCol$, 0.05, "stars", 0, 0, "auto", 2

# One-way ANOVA: F(3, 52) = 151.39, p < .001
#   4 groups, alpha = 0.050
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs..., with statistical annotation switched on.

# --- Step 2 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of val, grouped by grp, 4 groups.
# Violin width is a kernel density estimate, not a count.

annotate = 1
@emlDrawViolinPlot: data, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax
# The figure's statistical annotation. In the GUI the graphs form
# draws this after the figure returns; a recorded script has no
# form, so the step carries its own render.
annotXMin = emlDrawViolinPlot.axisXMin
annotXMax = emlDrawViolinPlot.axisXMax
annotYMin = emlDrawViolinPlot.axisYMin
annotYMax = emlDrawViolinPlot.axisYMax
annotYRange = annotYMax - annotYMin
if annotTextN > 0
    annotBlockN = annotBlockN + 1
    annotBlockLabel$[annotBlockN] = annotTextLabel$[1]
    annotBlockDraw$[annotBlockN] = annotTextLabel$[1]
    annotTextN = 0
endif
if annotBracketN > 0
    @emlDrawAnnotations: annotXMin, annotXMax, 227.473491, annotYRange, "{0.3, 0.3, 0.3}", emlSetAdaptiveTheme.annotSize, annotYMin, annotYMax
endif
if annotBlockN > 0
    if annotBracketN > 0
        omnibusCorner$ = "bottom-right"
    else
        omnibusCorner$ = "top-right"
    endif
    @emlDrawAnnotationBlock: omnibusCorner$, annotXMin, annotXMax, annotYMin, annotYMax, emlSetAdaptiveTheme.annotSize
endif
@emlClearAnnotations

# Axis resolved to 195.0000 .. 268.9205 over 4 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "val".


