#!praat
# ============================================================
# EML Stats & Graphs -- recorded workflow
# 12 August 2026, 00:00:00  --  recorded on Praat 6.6.30
# Input: Table voiceA -- 24 rows, 13 columns
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
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-record.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-analysis.praat

@emlInitDrawingDefaults
@emlClearAnnotations

# ------------------------------------------------------------
# THE OBJECT
# Recorded against: Table voiceA -- 24 rows, 13 columns.
# The objects this workflow ran on are named in the block below.
# All of them must be open before you run this script.
# ------------------------------------------------------------

# Name your data objects and columns here for this recorded
# workflow. Edit a name to run the same workflow on other data;
# nothing below this block names an object, a column or an axis
# range.
data1$ = "Table voiceA"   ; steps 1 (analysis), 2 (analysis), 3 (analysis), 4 (analysis), 5 (analysis), 6 (analysis), 7 (analysis), 8 (refusal), 9 (analysis), 10 (refusal), 11 (refusal), 12 (analysis), 13 (analysis), 14 (draw), 15 (draw), 16 (draw), 17 (draw), 18 (draw), 19 (draw), 20 (draw), 21 (draw), 22 (draw), 23 (draw), 44 (analysis), 45 (draw), 46 (draw)
data2$ = "Sound tone"   ; steps 24 (draw), 28 (convert), 29 (draw), 30 (convert), 31 (draw), 32 (convert), 33 (draw)
data3$ = "Pitch tone"   ; step 25 (draw)
data4$ = "Spectrum tone"   ; steps 26 (draw), 34 (convert), 35 (draw), 36 (convert), 37 (draw), 38 (convert), 39 (draw)
data5$ = "Ltas tone"   ; step 27 (draw)
data6$ = "TableOfReal tor"   ; steps 40 (convert), 41 (draw)
data7$ = "Matrix mat"   ; steps 42 (convert), 43 (draw)
valueCol$      = "spl"   ; the measured column -- steps 1 (analysis), 2 (analysis), 3 (analysis), 4 (analysis), 5 (analysis), 9 (analysis), 14 (draw), 16 (draw), 17 (draw), 18 (draw), 19 (draw), 20 (draw), 21 (draw), 22 (draw), 23 (draw), 44 (analysis)
groupCol$      = "grp"   ; the grouping column -- steps 1 (analysis), 2 (analysis), 3 (analysis), 14 (draw), 17 (draw), 18 (draw), 19 (draw), 20 (draw), 21 (draw)
xCol$          = "spl"   ; the x column -- steps 6 (analysis), 15 (draw), 45 (draw), 46 (draw)
yCol$          = "spl2"   ; the y column -- steps 6 (analysis), 15 (draw), 45 (draw), 46 (draw)
outcomeCol$    = "spl"   ; the outcome column -- step 7 (analysis)
predictorCol$  = "spl2"   ; the predictor column -- step 7 (analysis)
factorACol$    = "grp"   ; the first factor -- step 9 (analysis)
factorBCol$    = "grp2"   ; the second factor -- step 9 (analysis)
subjectCol$    = "subj"   ; the subject identifier -- steps 12 (analysis), 13 (analysis)
conditionCols$ = "c1|c2|c3"   ; the condition columns -- steps 12 (analysis), 13 (analysis)
timeCol$       = "t"   ; the time column -- steps 17 (draw), 18 (draw)
conditionCol$  = "t"   ; the condition column -- step 19 (draw)
idCol$         = "subj"   ; the case identifier -- step 19 (draw)
categoryCol$   = "grp"   ; the category column -- steps 22 (draw), 23 (draw)
subgroupCol$   = "grp2"   ; the sub-group column -- steps 22 (draw), 23 (draw)
valueCol2$     = "row"   ; the measured column -- steps 41 (draw), 43 (draw)
groupCol2$     = "grp3"   ; the grouping column -- step 44 (analysis)
axisYMin       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- steps 14 (draw), 15 (draw), 17 (draw), 18 (draw), 19 (draw), 20 (draw), 21 (draw), 22 (draw), 23 (draw), 24 (draw), 25 (draw), 26 (draw), 27 (draw), 29 (draw), 31 (draw), 33 (draw), 35 (draw), 37 (draw), 39 (draw), 45 (draw), 46 (draw)
axisYMax       = 0.0   ; on the recorded data it resolved to 56.0000 .. 74.0000
axisValueMin   = 0.0   ; the value-axis range (the histogram's horizontal axis) -- AUTO (both 0 = computed from the data) -- steps 16 (draw), 41 (draw), 43 (draw)
axisValueMax   = 0.0   ; on the recorded data it resolved to 59.8175 .. 70.2386
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# One-way ANOVA of spl by grp, 2 groups.
# Normality was NOT tested on this path.

@emlRunAnovaAnalysis: data, valueCol$, groupCol$, 0

# F(1, 22) = 5.2251, p = 0.0323, eta-squared = 0.1919
#   y: n = 12, mean = 66.1949
#   x: n = 12, mean = 63.4196
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare k groups (ANOVA)...,
# with Data column "spl" and Group column "grp".

# --- Step 2 (analysis) ---
selectObject: data1$
data = selected ()
# Two-group comparison: spl by grp, welch
# Equal-variance assumption: Welch.

@emlRunTwoGroupAnalysis: data, valueCol$, groupCol$, "welch", 0

# y: n = 12, mean = 66.1949, SD = 3.1734
#   x: n = 12, mean = 63.4196, SD = 2.7601
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare two groups...

# --- Step 3 (analysis) ---
selectObject: data1$
data = selected ()
# Kruskal-Wallis: spl by grp
# Rank-based; it does not assume normality and does not test it.

@emlRunKWAnalysis: data, valueCol$, groupCol$, 0, "holm"

# H(1) = 4.5633, p = 0.0327
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare k groups (Kruskal-Wallis)...

# --- Step 4 (analysis) ---
selectObject: data1$
data = selected ()
# Descriptive statistics: spl
# Descriptives only; no test was run and no assumption was checked.

@emlRunDescriptiveAnalysis: data, valueCol$

# n = 24 valid
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Describe Table column...

# --- Step 5 (analysis) ---
selectObject: data1$
data = selected ()
# Normality: spl, both
# A normality test answers a question about the sample, not a licence for a later test.

@emlRunNormalityAnalysis: data, valueCol$, "both"

# Shapiro-Wilk W = 0.9502, p = 0.2739
#   skewness = 0.1775, kurtosis = -1.0820, n = 24
#   Recommendation: parametric
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Check normality (all columns)...

# --- Step 6 (analysis) ---
selectObject: data1$
data = selected ()
# Correlation: spl with spl2, pearson
# Correlation is not causation, and a single coefficient hides the shape of the cloud.

@emlRunCorrelationAnalysis: data, xCol$, yCol$, "pearson"

# Pearson r = 0.0678, t(22) = 0.3189, p = 0.7528
#   n = 24
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Correlate two columns...

# --- Step 7 (analysis) ---
selectObject: data1$
data = selected ()
# Linear regression: spl on spl2
# Residual diagnostics are not run on this path.

@emlRunRegressionAnalysis: data, outcomeCol$, predictorCol$

# spl = 49.6803 + 0.0741 x spl2
#   R-squared = 0.0046, n = 24
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Linear regression...

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

@emlRunTwoWayAnalysis: data, valueCol$, factorACol$, factorBCol$

# grp: F(1, 20) = 3.8873, p = 0.0626
#   grp2: F(1, 20) = 0.0136, p = 0.9083
#   interaction: F(1, 20) = 0.0688, p = 0.7958
#   n = 24, cells = 4
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare two-way (ANOVA)...

# --- Step 10 (refusal) ---
selectObject: data1$
data = selected ()
# Refused: No paired test could be run on these two columns. "spl" and "spl2" give n = 24 complete pairs, and every one of those pairs has the same difference, so there is no variation in the differences for a paired test to work on.

; (nothing executed at this step -- see the note above)


# --- Step 11 (refusal) ---
selectObject: data1$
data = selected ()
# Refused: Not yet implemented -- scheduled for Phase 4.

; (nothing executed at this step -- see the note above)


# --- Step 12 (analysis) ---
selectObject: data1$
data = selected ()
# Repeated-measures ANOVA: c1|c2|c3, subject subj
# Sphericity is corrected, not assumed; the report names the correction.

@emlRunRepeatedMeasuresAnalysis: data, subjectCol$, conditionCols$, 0, "holm"

# F(2, 46) = 110.3303, p = 0.000000000000000003
#   Greenhouse-Geisser epsilon = 0.9078, corrected p = 0.00000000000000008
#   n = 24 subjects, k = 3 conditions
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare paired/repeated...

# --- Step 13 (analysis) ---
selectObject: data1$
data = selected ()
# Friedman: c1|c2|c3, subject subj
# Rank-based repeated measures; it does not assume normality and does not test it.

@emlRunFriedmanAnalysis: data, subjectCol$, conditionCols$, 0, "holm"

# chi-square(2) = 42.2500, p = 0.0000000007
#   n = 24 subjects, k = 3 conditions
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare paired/repeated (Friedman)...

# --- Step 14 (draw) ---
selectObject: data1$
data = selected ()
# Violin plot of spl, grouped by grp, 2 groups.
# Violin width is a kernel density estimate, not a count.

@emlDrawViolinPlot: data, "Violin", "grp", "spl", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax

# Axis resolved to 56.0000 .. 74.0000 over 2 groups.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "spl".

# --- Step 15 (draw) ---
selectObject: data1$
data = selected ()
# Scatter plot: Scatter
# A fitted line is descriptive and carries no test.

scatterAnalysisType = 0
annotCorrType$ = "pearson"
scatterRegressionLine = 0
@emlDrawScatterPlot: data, "Scatter", "x", "y", 6, 4, "color", 1, xCol$, yCol$, "", 0, 0, axisYMin, axisYMax, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 16 (draw) ---
selectObject: data1$
data = selected ()
# Histogram: Histogram
# Bin count changes the shape; it is a display choice, not a property of the data.

@emlDrawHistogram: data, "Histogram", "spl", "Count", 6, 4, "color", 1, valueCol$, "", 0, 1, axisValueMin, axisValueMax, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 17 (draw) ---
selectObject: data1$
data = selected ()
# Line chart: Line

@emlDrawTimeSeries: data, "Line", "t", "spl", 6, 4, "color", 1, timeCol$, valueCol$, groupCol$, 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 18 (draw) ---
selectObject: data1$
data = selected ()
# Line chart (+/-CI): Line CI

@emlDrawTimeSeriesCI: data, "Line CI", "t", "spl", 6, 4, "color", 1, timeCol$, valueCol$, groupCol$, 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 19 (draw) ---
selectObject: data1$
data = selected ()
# Spaghetti plot: Spaghetti

@emlDrawSpaghettiPlot: data, "Spaghetti", "t", "spl", 6, 4, "color", 1, conditionCol$, valueCol$, idCol$, groupCol$, 1, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 20 (draw) ---
selectObject: data1$
data = selected ()
# Bar chart: Bar
# Bars show means. The spread, not the bar, is what tells you about the data.

@emlDrawBarChart: data, "Bar", "grp", "spl", 6, 4, "color", 1, groupCol$, valueCol$, 0, "", axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 21 (draw) ---
selectObject: data1$
data = selected ()
# Box plot: Box
# Whisker convention and outlier rule are stated in the figure, not assumed.

@emlDrawBoxPlot: data, "Box", "grp", "spl", 6, 4, "color", 1, groupCol$, valueCol$, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 22 (draw) ---
selectObject: data1$
data = selected ()
# Grouped violin: GViolin
# Violin width is a kernel density estimate, not a count.

@emlDrawGroupedViolin: data, "GViolin", "grp", "spl", 6, 4, "color", 1, categoryCol$, subgroupCol$, valueCol$, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 23 (draw) ---
selectObject: data1$
data = selected ()
# Grouped box plot: GBox
# Whisker convention and outlier rule are stated in the figure, not assumed.

@emlDrawGroupedBoxPlot: data, "GBox", "grp", "spl", 6, 4, "color", 1, categoryCol$, subgroupCol$, valueCol$, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 24 (draw) ---
selectObject: data2$
data = selected ()
# Waveform: Waveform

@emlDrawWaveform: data, "Waveform", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 25 (draw) ---
selectObject: data3$
data = selected ()
# F0 contour: F0

@emlDrawF0Contour: data, "F0", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax, 1

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 26 (draw) ---
selectObject: data4$
data = selected ()
# Spectrum: Spectrum

@emlDrawSpectrum: data, "Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 27 (draw) ---
selectObject: data5$
data = selected ()
# Long-term average spectrum: LTAS

@emlDrawLTAS: data, "LTAS", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

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

@emlDrawF0Contour: data, "F0 from Sound", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax, 1

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

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

@emlDrawSpectrum: data, "Spectrum from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

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

@emlDrawLTAS: data, "LTAS from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

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

@emlDrawLTAS: data, "LTAS from Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

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

@emlDrawWaveform: data, "Waveform from Spectrum", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

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

@emlDrawF0Contour: data, "F0 from Spectrum", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, axisYMin, axisYMax, 1

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

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

@emlDrawHistogram: data, "Histogram from TableOfReal", "row", "Count", 6, 4, "color", 1, valueCol2$, "", 0, 1, axisValueMin, axisValueMax, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

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

@emlDrawHistogram: data, "Histogram from Matrix", "row", "Count", 6, 4, "color", 1, valueCol2$, "", 0, 1, axisValueMin, axisValueMax, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 44 (analysis) ---
selectObject: data1$
data = selected ()
# Group comparison on a figure: spl by grp3, parametric, 3 groups
# Reached through the figure's annotation rather than the stats menu; the test and the correction are the same.

@emlBridgeGroupComparison: data, valueCol$, groupCol2$, 0.05, "stars", 0, 1, "parametric", 1

# One-way ANOVA: F(2, 21) = 0.02, p = .979
#   3 groups, alpha = 0.050
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs..., with statistical annotation switched on.

# --- Step 45 (draw) ---
selectObject: data1$
data = selected ()
# Scatter plot: Scatter with stats
# A fitted line is descriptive and carries no test. The correlation and regression below were reported from this figure.

scatterAnalysisType = 3
annotCorrType$ = "spearman"
scatterRegressionLine = 1
@emlDrawScatterPlot: data, "Scatter with stats", "x", "y", 6, 4, "color", 1, xCol$, yCol$, "", 0, 0, axisYMin, axisYMax, 1

# spearman correlation reported on 24 complete pairs
#   spl2 = 199.9998 + 0.0620 x spl, R-squared = 0.0046
#   fit line: OLS (linear), slope = 0.0620, intercept = 199.9998
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 46 (draw) ---
selectObject: data1$
data = selected ()
# Scatter plot: Scatter, monotonic fit
# A fitted line is descriptive and carries no test. The correlation and regression below were reported from this figure.

scatterAnalysisType = 1
annotCorrType$ = "spearman"
scatterRegressionLine = 1
@emlDrawScatterPlot: data, "Scatter, monotonic fit", "x", "y", 6, 4, "color", 1, xCol$, yCol$, "", 0, 0, axisYMin, axisYMax, 1

# spearman correlation reported on 24 complete pairs
#   fit line: Theil-Sen (monotonic), slope = 0.0374, intercept = 201.0878
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...


