# ============================================================
# EML Praat Tools -- recorded workflow
#   --  recorded on Praat 6.6.30
# ============================================================

# ------------------------------------------------------------
# THE EML LIBRARY
# Recorded under Praat 6.6.30. Paths are home-relative, so they work
# for any user on this platform. If this file fails to parse, the
# plugin is somewhere else -- edit this block and nothing else.
#
#   Praat 6.x  Linux    ~/.praat-dir/plugin_EMLPraatTools
#   Praat 7.x  Linux    ~/.config/praat/plugin_EMLPraatTools
#   macOS      ~/Library/Preferences/Praat Prefs/plugin_EMLPraatTools
#   Windows    ~/Praat/plugin_EMLPraatTools
#   Not sure?  Run  writeInfoLine: preferencesDirectory$
#
# A version guard cannot help here: `include` is refused inside an
# if-block, so the file cannot choose its own path at run time.
# The barrel eml-lib-stats.praat will NOT work in place of this
# list: its own relative includes resolve against THIS file's
# folder, not its own.
# ------------------------------------------------------------

include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-core-utilities.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-core-descriptive.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-extract.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-output.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-inferential.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-result-writer.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-record.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/graphs/eml-graph-procedures.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/graphs/eml-annotation-procedures.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/graphs/eml-draw-procedures.praat
include /home/claude/EMLPraatTools/harness/record_e2e/prefs/plugin_EMLPraatTools/stats/eml-analysis.praat

@emlInitDrawingDefaults

# ------------------------------------------------------------
# THE OBJECT
# NOT RECORDED. Nothing in this session named the object it
# ran on, so a reader cannot check that the right Table is
# selected before running this file.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects here for this recorded workflow.
# Edit a name to run the same workflow on other data;
# nothing below this block names an object.
data1$ = "Table voiceA"   ; steps 1 (analysis), 2 (analysis), 3 (analysis), 4 (analysis), 5 (analysis), 6 (analysis), 7 (analysis), 8 (draw), 9 (draw), 10 (draw)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# One-way ANOVA of spl by grp, 2 groups.
# Normality was NOT tested on this path.

@emlRunAnovaAnalysis: data, "spl", "grp", 0

# F(1, 22) = 4.7550, p = 0.0402, eta-squared = 0.1777
#   y: n = 12, mean = 65.7757
#   x: n = 12, mean = 62.9633
# The same step through the menu:
# In the GUI: New > EML Tools > Compare k groups (ANOVA)...,
# with Data column "spl" and Group column "grp".

# --- Step 2 (analysis) ---
selectObject: data1$
data = selected ()
# Two-group comparison: spl by grp, welch
# Equal-variance assumption: Welch.

@emlRunTwoGroupAnalysis: data, "spl", "grp", "welch", 0

# The same step through the menu:
# In the GUI: New > EML Tools > Compare two groups...

# --- Step 3 (analysis) ---
selectObject: data1$
data = selected ()
# Kruskal-Wallis: spl by grp
# Rank-based; it does not assume normality and does not test it.

@emlRunKWAnalysis: data, "spl", "grp", 0, "holm"

# The same step through the menu:
# In the GUI: New > EML Tools > Compare k groups (Kruskal-Wallis)...

# --- Step 4 (analysis) ---
selectObject: data1$
data = selected ()
# Descriptive statistics: spl
# Descriptives only; no test was run and no assumption was checked.

@emlRunDescriptiveAnalysis: data, "spl"

# The same step through the menu:
# In the GUI: New > EML Tools > Describe Table column...

# --- Step 5 (analysis) ---
selectObject: data1$
data = selected ()
# Normality: spl, both
# A normality test answers a question about the sample, not a licence for a later test.

@emlRunNormalityAnalysis: data, "spl", "both"

# The same step through the menu:
# In the GUI: New > EML Tools > Check normality (all columns)...

# --- Step 6 (analysis) ---
selectObject: data1$
data = selected ()
# Correlation: spl with spl2, pearson
# Correlation is not causation, and a single coefficient hides the shape of the cloud.

@emlRunCorrelationAnalysis: data, "spl", "spl2", "pearson"

# The same step through the menu:
# In the GUI: New > EML Tools > Correlate two columns...

# --- Step 7 (analysis) ---
selectObject: data1$
data = selected ()
# Linear regression: spl on spl2
# Residual diagnostics are not run on this path.

@emlRunRegressionAnalysis: data, "spl", "spl2"

# The same step through the menu:
# In the GUI: New > EML Tools > Linear regression...

# --- Step 8 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of spl, grouped by grp, 2 groups.
# Violin width is a kernel density estimate, not a count.

@emlDrawViolinPlot: data, "Violin", "grp", "spl", 6, 4, "color", 1, "grp", "spl", 54.000000, 74.000000

# Axis resolved to 54.0000 .. 74.0000 over 2 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "spl".

# --- Step 9 (draw) ---
selectObject: data1$
data = selected ()
# Scatter plot: Scatter
# A fitted line, where one is drawn, is descriptive and carries no test.

@emlDrawScatterPlot: data, "Scatter", "x", "y", 6, 4, "color", 1, "spl", "spl2", "", 0, 0, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 10 (draw) ---
selectObject: data1$
data = selected ()
# Histogram: Histogram
# Bin count changes the shape; it is a display choice, not a property of the data.

@emlDrawHistogram: data, "Histogram", "spl", "Count", 6, 4, "color", 1, "spl", "", 0, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...


