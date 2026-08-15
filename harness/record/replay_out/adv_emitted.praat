#!praat
# ============================================================
# EML Praat Tools -- recorded workflow
# 14 August 2026, 00:00:00  --  recorded on Praat 6.6.30
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
# Recorded against: Table vt -- 40 rows, 2 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects here for this recorded workflow.
# Edit a name to run the same workflow on other data;
# nothing below this block names an object.
data1$ = "Table vt"   ; steps 1 (analysis), 2 (draw)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# Group comparison on a figure: val by grp, parametric, 2 groups
# Reached through the figure's annotation rather than the stats menu; the test and the correction are the same.

prev_violinShowJitter = 1
annotate = 1
@emlBridgeGroupComparison: data, "val", "grp", 0.05, "p-value", 0, 1, "parametric", 1

# Welch t: t(33.0) = -8.57, p < .001, d = -2.71
#   2 groups, alpha = 0.050
# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs..., with statistical annotation switched on.

# --- Step 2 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of val, grouped by grp, 2 groups.
# Violin width is a kernel density estimate, not a count.

prev_violinShowJitter = 1
annotate = 1
@emlDrawViolinPlot: data, "advanced violin", "Cohort", "val", 6, 4, "color", 1, "grp", "val", 1.554964, 4.416270
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
    @emlDrawAnnotations: annotXMin, annotXMax, 4.009083, annotYRange, "{0.3, 0.3, 0.3}", emlSetAdaptiveTheme.annotSize, annotYMin, annotYMax
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

# Axis resolved to 1.5550 .. 4.4163 over 2 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "val".


