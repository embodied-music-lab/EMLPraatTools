# ============================================================
# EML Praat Tools -- recorded workflow
# 12 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table voiceA -- 24 rows, 13 columns
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
# Recorded against: Table voiceA -- 24 rows, 13 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects here for this recorded workflow.
# Edit a name to run the same workflow on other data;
# nothing below this block names an object.
data1$ = "Table voiceA"   ; steps 1 (analysis), 2 (analysis), 3 (analysis), 4 (analysis), 5 (analysis), 6 (analysis), 7 (analysis), 8 (refusal), 9 (analysis), 10 (analysis), 11 (refusal), 12 (refusal), 13 (refusal), 14 (draw), 15 (draw), 16 (draw), 17 (draw), 18 (draw), 19 (draw), 20 (draw), 21 (draw), 22 (draw), 23 (draw)
data2$ = "Sound tone"   ; steps 24 (draw), 28 (convert), 29 (draw), 30 (convert), 31 (draw), 32 (convert), 33 (draw)
data3$ = "Pitch tone"   ; step 25 (draw)
data4$ = "Spectrum tone"   ; steps 26 (draw), 34 (convert), 35 (draw), 36 (convert), 37 (draw), 38 (convert), 39 (draw)
data5$ = "Ltas tone"   ; step 27 (draw)
data6$ = "TableOfReal tor"   ; steps 40 (convert), 41 (draw)
data7$ = "Matrix mat"   ; steps 42 (convert), 43 (draw)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# One-way ANOVA of spl by grp, 2 groups.
# Normality was NOT tested on this path.

@emlRunAnovaAnalysis: data, "spl", "grp", 0

# F(1, 22) = 5.2251, p = 0.0323, eta-squared = 0.1919
#   y: n = 12, mean = 66.1949
#   x: n = 12, mean = 63.4196
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

# --- Step 8 (refusal) ---
selectObject: data1$
data = selected ()
# Refused: Unknown pairwise test: "t"

; (nothing executed at this step -- see the note above)


# --- Step 9 (analysis) ---
selectObject: data1$
data = selected ()
# Two-way ANOVA: spl by grp and grp2
# Type of sums of squares and the balance of the design both matter here; see the report.

@emlRunTwoWayAnalysis: data, "spl", "grp", "grp2"

# The same step through the menu:
# In the GUI: New > EML Tools > Compare two-way (ANOVA)...

# --- Step 10 (analysis) ---
selectObject: data1$
data = selected ()
# Paired comparison: spl vs spl2, t
# Rows with a missing value in either column are dropped pairwise.

@emlRunPairedAnalysis: data, "spl", "spl2", "t"

# The same step through the menu:
# In the GUI: New > EML Tools > Compare paired/repeated...

# --- Step 11 (refusal) ---
selectObject: data1$
data = selected ()
# Refused: Not yet implemented -- scheduled for Phase 4.

; (nothing executed at this step -- see the note above)


# --- Step 12 (refusal) ---
selectObject: data1$
data = selected ()
# Refused: Need at least 2 condition columns.

; (nothing executed at this step -- see the note above)


# --- Step 13 (refusal) ---
selectObject: data1$
data = selected ()
# Refused: Need at least 2 condition columns.

; (nothing executed at this step -- see the note above)


# --- Step 14 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of spl, grouped by grp, 2 groups.
# Violin width is a kernel density estimate, not a count.

@emlDrawViolinPlot: data, "Violin", "grp", "spl", 6, 4, "color", 1, "grp", "spl", 56.000000, 74.000000

# Axis resolved to 56.0000 .. 74.0000 over 2 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "spl".

# --- Step 15 (draw) ---
selectObject: data1$
data = selected ()
# Scatter plot: Scatter
# A fitted line, where one is drawn, is descriptive and carries no test.

@emlDrawScatterPlot: data, "Scatter", "x", "y", 6, 4, "color", 1, "spl", "spl2", "", 0, 0, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 16 (draw) ---
selectObject: data1$
data = selected ()
# Histogram: Histogram
# Bin count changes the shape; it is a display choice, not a property of the data.

@emlDrawHistogram: data, "Histogram", "spl", "Count", 6, 4, "color", 1, "spl", "", 0, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 17 (draw) ---
selectObject: data1$
data = selected ()
# Line chart: Line

@emlDrawTimeSeries: data, "Line", "t", "spl", 6, 4, "color", 1, "t", "spl", "grp", 0, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 18 (draw) ---
selectObject: data1$
data = selected ()
# Line chart (+/-CI): Line CI

@emlDrawTimeSeriesCI: data, "Line CI", "t", "spl", 6, 4, "color", 1, "t", "spl", "grp", 0, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 19 (draw) ---
selectObject: data1$
data = selected ()
# Spaghetti plot: Spaghetti

@emlDrawSpaghettiPlot: data, "Spaghetti", "t", "spl", 6, 4, "color", 1, "t", "spl", "subj", "grp", 1, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 20 (draw) ---
selectObject: data1$
data = selected ()
# Bar chart: Bar
# Bars show means. The spread, not the bar, is what tells you about the data.

@emlDrawBarChart: data, "Bar", "grp", "spl", 6, 4, "color", 1, "grp", "spl", 0, "", 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 21 (draw) ---
selectObject: data1$
data = selected ()
# Box plot: Box
# Whisker convention and outlier rule are stated in the figure, not assumed.

@emlDrawBoxPlot: data, "Box", "grp", "spl", 6, 4, "color", 1, "grp", "spl", 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 22 (draw) ---
selectObject: data1$
data = selected ()
# Grouped violin: GViolin
# Violin width is a kernel density estimate, not a count.

@emlDrawGroupedViolin: data, "GViolin", "grp", "spl", 6, 4, "color", 1, "grp", "grp2", "spl", 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 23 (draw) ---
selectObject: data1$
data = selected ()
# Grouped box plot: GBox
# Whisker convention and outlier rule are stated in the figure, not assumed.

@emlDrawGroupedBoxPlot: data, "GBox", "grp", "spl", 6, 4, "color", 1, "grp", "grp2", "spl", 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 24 (draw) ---
selectObject: data2$
data = selected ()
# Waveform: Waveform

@emlDrawWaveform: data, "Waveform", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 25 (draw) ---
selectObject: data3$
data = selected ()
# F0 contour: F0

@emlDrawF0Contour: data, "F0", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, 0, 0, 1

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 26 (draw) ---
selectObject: data4$
data = selected ()
# Spectrum: Spectrum

@emlDrawSpectrum: data, "Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 27 (draw) ---
selectObject: data5$
data = selected ()
# Long-term average spectrum: LTAS

@emlDrawLTAS: data, "LTAS", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 28 (convert) ---
selectObject: data2$
data = selected ()
# Converted Sound tone to Pitch tone.
# The pitch floor and ceiling are the ones this session used. They change the contour, so they belong in a methods section.

data = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "yes", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 29 (draw) ---
# F0 contour: F0 from Sound

@emlDrawF0Contour: data, "F0 from Sound", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, 0, 0, 1

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 30 (convert) ---
selectObject: data2$
data = selected ()
# Converted Sound tone to Spectrum tone.
# Fast (FFT) transform, which is what the figure was drawn from.

data = To Spectrum: "yes"

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 31 (draw) ---
# Spectrum: Spectrum from Sound

@emlDrawSpectrum: data, "Spectrum from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 32 (convert) ---
selectObject: data2$
data = selected ()
# Converted Sound tone to Ltas tone.
# 100 Hz bandwidth, the value this session used.

data = To Ltas: 100

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 33 (draw) ---
# Long-term average spectrum: LTAS from Sound

@emlDrawLTAS: data, "LTAS from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 34 (convert) ---
selectObject: data4$
data = selected ()
# Converted Spectrum tone to Ltas tone.
# One LTAS bin per spectral bin -- no rebinning, so the figure shows the spectrum's own resolution.

data = To Ltas (1-to-1)

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 35 (draw) ---
# Long-term average spectrum: LTAS from Spectrum

@emlDrawLTAS: data, "LTAS from Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, 0, 0, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 36 (convert) ---
selectObject: data4$
data = selected ()
# Converted Spectrum tone to Sound tone.
# Inverse transform back to a waveform.

data = To Sound

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 37 (draw) ---
# Waveform: Waveform from Spectrum

@emlDrawWaveform: data, "Waveform from Spectrum", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 38 (convert) ---
selectObject: data4$
data = selected ()
# Converted Spectrum tone to Pitch tone.
# A Spectrum carries no pitch track, so the route is back through a Sound. The pitch floor and ceiling are the ones this session used. They change the contour, so they belong in a methods section.

tmp = To Sound
selectObject: tmp
data = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "yes", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
removeObject: tmp
selectObject: data

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 39 (draw) ---
# F0 contour: F0 from Spectrum

@emlDrawF0Contour: data, "F0 from Spectrum", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, 0, 0, 1

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 40 (convert) ---
selectObject: data6$
data = selected ()
# Converted TableOfReal tor to Table tor.
# Kept as a working object rather than removed after drawing, so the session goes on using the Table.

data = To Table: "row"
@emlCleanConvertedTable: data

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 41 (draw) ---
# Histogram: Histogram from TableOfReal
# Bin count changes the shape; it is a display choice, not a property of the data.

@emlDrawHistogram: data, "Histogram from TableOfReal", "row", "Count", 6, 4, "color", 1, "row", "", 0, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...

# --- Step 42 (convert) ---
selectObject: data7$
data = selected ()
# Converted Matrix mat to Table mat.
# A Matrix reaches a Table through a TableOfReal. Kept as a working object rather than removed after drawing.

tmp = To TableOfReal
data = To Table: "row"
removeObject: tmp
selectObject: data
@emlCleanConvertedTable: data

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 43 (draw) ---
# Histogram: Histogram from Matrix
# Bin count changes the shape; it is a display choice, not a property of the data.

@emlDrawHistogram: data, "Histogram from Matrix", "row", "Count", 6, 4, "color", 1, "row", "", 0, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Tools > EML Graphs...


