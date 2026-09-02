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
# Recorded against: Table voiceA -- 24 rows, 13 columns.
# The objects this workflow ran on are named in the block below.
# None of them is built or opened by a step below: see
# PRECONDITION, and open them before you run this script.
# ------------------------------------------------------------

# ============================================================
# PRECONDITION -- THIS SCRIPT CANNOT REBUILD ITS DATA
#
# These objects were already open when this recording started.
#     Table voiceA
#     Sound tone
#     Pitch tone
#     Spectrum tone
#     Ltas tone
#     TableOfReal tor
#     Matrix mat
# Nothing in the session made them, so nothing below can remake them.
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
data1$ = "Table voiceA"   ; run 1, step 1 (analysis)
data2$ = "Table voiceA"   ; run 2, step 2 (analysis)
data3$ = "Table voiceA"   ; run 3, step 3 (analysis)
data4$ = "Table voiceA"   ; run 4, step 4 (analysis)
data5$ = "Table voiceA"   ; run 5, step 5 (analysis)
data6$ = "Table voiceA"   ; run 6, step 6 (analysis)
data7$ = "Table voiceA"   ; run 7, step 7 (analysis)
data8$ = "Table voiceA"   ; run 8, step 8 (refusal)
data9$ = "Table voiceA"   ; run 9, step 9 (refusal)
data10$ = "Table voiceA"   ; run 10, step 10 (refusal)
data11$ = "Table voiceA"   ; run 11, step 11 (analysis)
data12$ = "Table voiceA"   ; run 12, step 12 (analysis)
data13$ = "Table voiceA"   ; run 13, step 13 (draw)
data14$ = "Table voiceA"   ; run 14, step 14 (draw)
data15$ = "Table voiceA"   ; run 15, step 15 (draw)
data16$ = "Table voiceA"   ; run 16, step 16 (draw)
data17$ = "Table voiceA"   ; run 17, step 17 (draw)
data18$ = "Table voiceA"   ; run 18, step 18 (draw)
data19$ = "Table voiceA"   ; run 19, step 19 (draw)
data20$ = "Table voiceA"   ; run 20, step 20 (draw)
data21$ = "Table voiceA"   ; run 21, step 21 (draw)
data22$ = "Table voiceA"   ; run 22, step 22 (draw)
data23$ = "Sound tone"   ; run 23, step 23 (draw)
data24$ = "Pitch tone"   ; run 24, step 24 (draw)
data25$ = "Spectrum tone"   ; run 25, step 25 (draw)
data26$ = "Ltas tone"   ; run 26, step 26 (draw)
data27$ = "Sound tone"   ; run 27, steps 27 (convert), 28 (draw)
data28$ = "Sound tone"   ; run 28, steps 29 (convert), 30 (draw)
data29$ = "Sound tone"   ; run 29, steps 31 (convert), 32 (draw)
data30$ = "Spectrum tone"   ; run 30, steps 33 (convert), 34 (draw)
data31$ = "Spectrum tone"   ; run 31, steps 35 (convert), 36 (draw)
data32$ = "Spectrum tone"   ; run 32, steps 37 (convert), 38 (draw)
data33$ = "TableOfReal tor"   ; run 33, steps 39 (convert), 40 (draw)
data34$ = "Matrix mat"   ; run 34, steps 41 (convert), 42 (draw)
data35$ = "Table voiceA"   ; run 35, step 43 (analysis)
data36$ = "Table voiceA"   ; run 36, step 44 (draw)
data37$ = "Table voiceA"   ; run 37, step 45 (draw)
valueCol$        = "spl"   ; the measured column -- run 1, step 1 (analysis)
groupCol$        = "grp"   ; the grouping column -- run 1, step 1 (analysis)
valueCol2$       = "spl"   ; the measured column -- run 2, step 2 (analysis)
groupCol2$       = "grp"   ; the grouping column -- run 2, step 2 (analysis)
valueCol3$       = "spl"   ; the measured column -- run 3, step 3 (analysis)
groupCol3$       = "grp"   ; the grouping column -- run 3, step 3 (analysis)
valueCol4$       = "spl"   ; the measured column -- run 4, step 4 (analysis)
valueCol5$       = "spl"   ; the measured column -- run 5, step 5 (analysis)
xCol6$           = "spl"   ; the x column -- run 6, step 6 (analysis)
yCol6$           = "spl2"   ; the y column -- run 6, step 6 (analysis)
outcomeCol7$     = "spl"   ; the outcome column -- run 7, step 7 (analysis)
predictorCol7$   = "spl2"   ; the predictor column -- run 7, step 7 (analysis)
subjectCol11$    = "subj"   ; the subject identifier -- run 11, step 11 (analysis)
conditionCols11$ = "c1|c2|c3"   ; the condition columns -- run 11, step 11 (analysis)
subjectCol12$    = "subj"   ; the subject identifier -- run 12, step 12 (analysis)
conditionCols12$ = "c1|c2|c3"   ; the condition columns -- run 12, step 12 (analysis)
groupCol13$      = "grp"   ; the grouping column -- run 13, step 13 (draw)
valueCol13$      = "spl"   ; the measured column -- run 13, step 13 (draw)
xCol14$          = "spl"   ; the x column -- run 14, step 14 (draw)
yCol14$          = "spl2"   ; the y column -- run 14, step 14 (draw)
valueCol15$      = "spl"   ; the measured column -- run 15, step 15 (draw)
timeCol16$       = "t"   ; the time column -- run 16, step 16 (draw)
valueCol16$      = "spl"   ; the measured column -- run 16, step 16 (draw)
groupCol16$      = "grp"   ; the grouping column -- run 16, step 16 (draw)
timeCol17$       = "t"   ; the time column -- run 17, step 17 (draw)
valueCol17$      = "spl"   ; the measured column -- run 17, step 17 (draw)
groupCol17$      = "grp"   ; the grouping column -- run 17, step 17 (draw)
conditionCol18$  = "t"   ; the condition column -- run 18, step 18 (draw)
valueCol18$      = "spl"   ; the measured column -- run 18, step 18 (draw)
idCol18$         = "subj"   ; the case identifier -- run 18, step 18 (draw)
groupCol18$      = "grp"   ; the grouping column -- run 18, step 18 (draw)
groupCol19$      = "grp"   ; the grouping column -- run 19, step 19 (draw)
valueCol19$      = "spl"   ; the measured column -- run 19, step 19 (draw)
groupCol20$      = "grp"   ; the grouping column -- run 20, step 20 (draw)
valueCol20$      = "spl"   ; the measured column -- run 20, step 20 (draw)
categoryCol21$   = "grp"   ; the category column -- run 21, step 21 (draw)
subgroupCol21$   = "grp2"   ; the sub-group column -- run 21, step 21 (draw)
valueCol21$      = "spl"   ; the measured column -- run 21, step 21 (draw)
categoryCol22$   = "grp"   ; the category column -- run 22, step 22 (draw)
subgroupCol22$   = "grp2"   ; the sub-group column -- run 22, step 22 (draw)
valueCol22$      = "spl"   ; the measured column -- run 22, step 22 (draw)
valueCol33$      = "row"   ; the measured column -- run 33, step 40 (draw)
valueCol34$      = "row"   ; the measured column -- run 34, step 42 (draw)
valueCol35$      = "spl"   ; the measured column -- run 35, step 43 (analysis)
groupCol35$      = "grp3"   ; the grouping column -- run 35, step 43 (analysis)
xCol36$          = "spl"   ; the x column -- run 36, step 44 (draw)
yCol36$          = "spl2"   ; the y column -- run 36, step 44 (draw)
xCol37$          = "spl"   ; the x column -- run 37, step 45 (draw)
yCol37$          = "spl2"   ; the y column -- run 37, step 45 (draw)
axisYMin13       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 13, step 13 (draw)
axisYMax13       = 0.0   ; on the recorded data this resolved to 56.0000 .. 74.0000; auto adapts to other data
axisYMin14       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 14, step 14 (draw)
axisYMax14       = 0.0   ; on the recorded data this resolved to 196.0000 .. 212.0000; auto adapts to other data
axisValueMin15   = 0.0   ; the value-axis range (the histogram's horizontal axis) -- AUTO (both 0 = computed from the data) -- run 15, step 15 (draw)
axisValueMax15   = 0.0   ; on the recorded data this resolved to 59.8175 .. 70.2386; auto adapts to other data
axisYMin16       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 16, step 16 (draw)
axisYMax16       = 0.0   ; on the recorded data this resolved to 62.5000 .. 67.0000; auto adapts to other data
axisYMin17       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 17, step 17 (draw)
axisYMax17       = 0.0   ; on the recorded data this resolved to 56.0000 .. 76.0000; auto adapts to other data
axisYMin18       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 18, step 18 (draw)
axisYMax18       = 0.0   ; on the recorded data this resolved to 58.0000 .. 72.0000; auto adapts to other data
axisYMin19       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 19, step 19 (draw)
axisYMax19       = 0.0   ; on the recorded data this resolved to 0.0000 .. 80.0000; auto adapts to other data
axisYMin20       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 20, step 20 (draw)
axisYMax20       = 0.0   ; on the recorded data this resolved to 58.0000 .. 72.0000; auto adapts to other data
axisYMin21       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 21, step 21 (draw)
axisYMax21       = 0.0   ; on the recorded data this resolved to 54.0000 .. 76.0000; auto adapts to other data
axisYMin22       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 22, step 22 (draw)
axisYMax22       = 0.0   ; on the recorded data this resolved to 58.0000 .. 72.0000; auto adapts to other data
axisYMin23       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 23, step 23 (draw)
axisYMax23       = 0.0   ; on the recorded data this resolved to -0.4500 .. 0.4500; auto adapts to other data
axisYMin24       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 24, step 24 (draw)
axisYMax24       = 0.0   ; on the recorded data this resolved to 219.2000 .. 220.8000; auto adapts to other data
axisYMin25       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 25, step 25 (draw)
axisYMax25       = 0.0   ; on the recorded data this resolved to 0.0000 .. 80.0000; auto adapts to other data
axisYMin26       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 26, step 26 (draw)
axisYMax26       = 0.0   ; on the recorded data this resolved to -20.0000 .. 80.0000; auto adapts to other data
axisYMin27       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 27, step 28 (draw)
axisYMax27       = 0.0   ; on the recorded data this resolved to 219.0000 .. 220.8000; auto adapts to other data
axisYMin28       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 28, step 30 (draw)
axisYMax28       = 0.0   ; on the recorded data this resolved to 0.0000 .. 80.0000; auto adapts to other data
axisYMin29       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 29, step 32 (draw)
axisYMax29       = 0.0   ; on the recorded data this resolved to -20.0000 .. 80.0000; auto adapts to other data
axisYMin30       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 30, step 34 (draw)
axisYMax30       = 0.0   ; on the recorded data this resolved to -20.0000 .. 80.0000; auto adapts to other data
axisYMin31       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 31, step 36 (draw)
axisYMax31       = 0.0   ; on the recorded data this resolved to -0.4500 .. 0.4500; auto adapts to other data
axisYMin32       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 32, step 38 (draw)
axisYMax32       = 0.0   ; on the recorded data this resolved to 217.5000 .. 220.5000; auto adapts to other data
axisValueMin33   = 0.0   ; the value-axis range (the histogram's horizontal axis) -- AUTO (both 0 = computed from the data) -- run 33, step 40 (draw)
axisValueMax33   = 0.0   ; on the recorded data this resolved to 0.0000 .. 1.0000; auto adapts to other data
axisValueMin34   = 0.0   ; the value-axis range (the histogram's horizontal axis) -- AUTO (both 0 = computed from the data) -- run 34, step 42 (draw)
axisValueMax34   = 0.0   ; on the recorded data this resolved to 0.0000 .. 1.0000; auto adapts to other data
axisYMin36       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 36, step 44 (draw)
axisYMax36       = 0.0   ; on the recorded data this resolved to 196.0000 .. 212.0000; auto adapts to other data
axisYMin37       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 37, step 45 (draw)
axisYMax37       = 0.0   ; on the recorded data this resolved to 196.0000 .. 212.0000; auto adapts to other data
eraseFirst13     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 13, step 13 (draw)
panelOriginX13   = 0   ; inches from the left of the page to this panel's corner -- run 13, step 13 (draw)
panelOriginY13   = 0   ; inches from the top of the page to this panel's corner -- run 13, step 13 (draw)
lineStyle13      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 13, step 13 (draw)
secondAxisOn13   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 13, step 13 (draw)
eraseFirst14     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 14, step 14 (draw)
panelOriginX14   = 0   ; inches from the left of the page to this panel's corner -- run 14, step 14 (draw)
panelOriginY14   = 0   ; inches from the top of the page to this panel's corner -- run 14, step 14 (draw)
lineStyle14      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 14, step 14 (draw)
secondAxisOn14   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 14, step 14 (draw)
eraseFirst15     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 15, step 15 (draw)
panelOriginX15   = 0   ; inches from the left of the page to this panel's corner -- run 15, step 15 (draw)
panelOriginY15   = 0   ; inches from the top of the page to this panel's corner -- run 15, step 15 (draw)
lineStyle15      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 15, step 15 (draw)
secondAxisOn15   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 15, step 15 (draw)
eraseFirst16     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 16, step 16 (draw)
panelOriginX16   = 0   ; inches from the left of the page to this panel's corner -- run 16, step 16 (draw)
panelOriginY16   = 0   ; inches from the top of the page to this panel's corner -- run 16, step 16 (draw)
lineStyle16      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 16, step 16 (draw)
secondAxisOn16   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 16, step 16 (draw)
eraseFirst17     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 17, step 17 (draw)
panelOriginX17   = 0   ; inches from the left of the page to this panel's corner -- run 17, step 17 (draw)
panelOriginY17   = 0   ; inches from the top of the page to this panel's corner -- run 17, step 17 (draw)
lineStyle17      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 17, step 17 (draw)
secondAxisOn17   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 17, step 17 (draw)
eraseFirst18     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 18, step 18 (draw)
panelOriginX18   = 0   ; inches from the left of the page to this panel's corner -- run 18, step 18 (draw)
panelOriginY18   = 0   ; inches from the top of the page to this panel's corner -- run 18, step 18 (draw)
lineStyle18      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 18, step 18 (draw)
secondAxisOn18   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 18, step 18 (draw)
eraseFirst19     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 19, step 19 (draw)
panelOriginX19   = 0   ; inches from the left of the page to this panel's corner -- run 19, step 19 (draw)
panelOriginY19   = 0   ; inches from the top of the page to this panel's corner -- run 19, step 19 (draw)
lineStyle19      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 19, step 19 (draw)
secondAxisOn19   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 19, step 19 (draw)
eraseFirst20     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 20, step 20 (draw)
panelOriginX20   = 0   ; inches from the left of the page to this panel's corner -- run 20, step 20 (draw)
panelOriginY20   = 0   ; inches from the top of the page to this panel's corner -- run 20, step 20 (draw)
lineStyle20      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 20, step 20 (draw)
secondAxisOn20   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 20, step 20 (draw)
eraseFirst21     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 21, step 21 (draw)
panelOriginX21   = 0   ; inches from the left of the page to this panel's corner -- run 21, step 21 (draw)
panelOriginY21   = 0   ; inches from the top of the page to this panel's corner -- run 21, step 21 (draw)
lineStyle21      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 21, step 21 (draw)
secondAxisOn21   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 21, step 21 (draw)
eraseFirst22     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 22, step 22 (draw)
panelOriginX22   = 0   ; inches from the left of the page to this panel's corner -- run 22, step 22 (draw)
panelOriginY22   = 0   ; inches from the top of the page to this panel's corner -- run 22, step 22 (draw)
lineStyle22      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 22, step 22 (draw)
secondAxisOn22   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 22, step 22 (draw)
eraseFirst23     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 23, step 23 (draw)
panelOriginX23   = 0   ; inches from the left of the page to this panel's corner -- run 23, step 23 (draw)
panelOriginY23   = 0   ; inches from the top of the page to this panel's corner -- run 23, step 23 (draw)
lineStyle23      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 23, step 23 (draw)
secondAxisOn23   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 23, step 23 (draw)
eraseFirst24     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 24, step 24 (draw)
panelOriginX24   = 0   ; inches from the left of the page to this panel's corner -- run 24, step 24 (draw)
panelOriginY24   = 0   ; inches from the top of the page to this panel's corner -- run 24, step 24 (draw)
lineStyle24      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 24, step 24 (draw)
secondAxisOn24   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 24, step 24 (draw)
eraseFirst25     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 25, step 25 (draw)
panelOriginX25   = 0   ; inches from the left of the page to this panel's corner -- run 25, step 25 (draw)
panelOriginY25   = 0   ; inches from the top of the page to this panel's corner -- run 25, step 25 (draw)
lineStyle25      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 25, step 25 (draw)
secondAxisOn25   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 25, step 25 (draw)
eraseFirst26     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 26, step 26 (draw)
panelOriginX26   = 0   ; inches from the left of the page to this panel's corner -- run 26, step 26 (draw)
panelOriginY26   = 0   ; inches from the top of the page to this panel's corner -- run 26, step 26 (draw)
lineStyle26      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 26, step 26 (draw)
secondAxisOn26   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 26, step 26 (draw)
eraseFirst27     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 27, step 28 (draw)
panelOriginX27   = 0   ; inches from the left of the page to this panel's corner -- run 27, step 28 (draw)
panelOriginY27   = 0   ; inches from the top of the page to this panel's corner -- run 27, step 28 (draw)
lineStyle27      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 27, step 28 (draw)
secondAxisOn27   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 27, step 28 (draw)
eraseFirst28     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 28, step 30 (draw)
panelOriginX28   = 0   ; inches from the left of the page to this panel's corner -- run 28, step 30 (draw)
panelOriginY28   = 0   ; inches from the top of the page to this panel's corner -- run 28, step 30 (draw)
lineStyle28      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 28, step 30 (draw)
secondAxisOn28   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 28, step 30 (draw)
eraseFirst29     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 29, step 32 (draw)
panelOriginX29   = 0   ; inches from the left of the page to this panel's corner -- run 29, step 32 (draw)
panelOriginY29   = 0   ; inches from the top of the page to this panel's corner -- run 29, step 32 (draw)
lineStyle29      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 29, step 32 (draw)
secondAxisOn29   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 29, step 32 (draw)
eraseFirst30     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 30, step 34 (draw)
panelOriginX30   = 0   ; inches from the left of the page to this panel's corner -- run 30, step 34 (draw)
panelOriginY30   = 0   ; inches from the top of the page to this panel's corner -- run 30, step 34 (draw)
lineStyle30      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 30, step 34 (draw)
secondAxisOn30   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 30, step 34 (draw)
eraseFirst31     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 31, step 36 (draw)
panelOriginX31   = 0   ; inches from the left of the page to this panel's corner -- run 31, step 36 (draw)
panelOriginY31   = 0   ; inches from the top of the page to this panel's corner -- run 31, step 36 (draw)
lineStyle31      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 31, step 36 (draw)
secondAxisOn31   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 31, step 36 (draw)
eraseFirst32     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 32, step 38 (draw)
panelOriginX32   = 0   ; inches from the left of the page to this panel's corner -- run 32, step 38 (draw)
panelOriginY32   = 0   ; inches from the top of the page to this panel's corner -- run 32, step 38 (draw)
lineStyle32      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 32, step 38 (draw)
secondAxisOn32   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 32, step 38 (draw)
eraseFirst33     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 33, step 40 (draw)
panelOriginX33   = 0   ; inches from the left of the page to this panel's corner -- run 33, step 40 (draw)
panelOriginY33   = 0   ; inches from the top of the page to this panel's corner -- run 33, step 40 (draw)
lineStyle33      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 33, step 40 (draw)
secondAxisOn33   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 33, step 40 (draw)
eraseFirst34     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 34, step 42 (draw)
panelOriginX34   = 0   ; inches from the left of the page to this panel's corner -- run 34, step 42 (draw)
panelOriginY34   = 0   ; inches from the top of the page to this panel's corner -- run 34, step 42 (draw)
lineStyle34      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 34, step 42 (draw)
secondAxisOn34   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 34, step 42 (draw)
eraseFirst36     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 36, step 44 (draw)
panelOriginX36   = 0   ; inches from the left of the page to this panel's corner -- run 36, step 44 (draw)
panelOriginY36   = 0   ; inches from the top of the page to this panel's corner -- run 36, step 44 (draw)
lineStyle36      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 36, step 44 (draw)
secondAxisOn36   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 36, step 44 (draw)
eraseFirst37     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 37, step 45 (draw)
panelOriginX37   = 0   ; inches from the left of the page to this panel's corner -- run 37, step 45 (draw)
panelOriginY37   = 0   ; inches from the top of the page to this panel's corner -- run 37, step 45 (draw)
lineStyle37      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 37, step 45 (draw)
secondAxisOn37   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 37, step 45 (draw)
# (Titles and axis labels are text, not column names, so they
#  stay as they were typed -- edit those in the step itself.)

# --- Step 1 (analysis) ---
selectObject: data1$
data = selected ()
# One-way ANOVA of spl by grp, 2 groups.
# Normality was NOT tested on this path.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunAnovaAnalysis: data, valueCol$, groupCol$, 0

# F(1, 22) = 5.2251, p = 0.0323, eta-squared = 0.1919
#   y: n = 12, mean = 66.1949
#   x: n = 12, mean = 63.4196
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare k groups (ANOVA)...,
# with Data column "spl" and Group column "grp".

# --- Step 2 (analysis) ---
selectObject: data2$
data = selected ()
# Two-group comparison: spl by grp, welch
# Equal-variance assumption: Welch.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunTwoGroupAnalysis: data, valueCol2$, groupCol2$, "welch", 0

# y: n = 12, mean = 66.1949, SD = 3.1734
#   x: n = 12, mean = 63.4196, SD = 2.7601
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare two groups...

# --- Step 3 (analysis) ---
selectObject: data3$
data = selected ()
# Kruskal-Wallis: spl by grp
# Rank-based; it does not assume normality and does not test it.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunKWAnalysis: data, valueCol3$, groupCol3$, 0, "holm"

# H(1) = 4.5633, p = 0.0327
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare k groups (Kruskal-Wallis)...

# --- Step 4 (analysis) ---
selectObject: data4$
data = selected ()
# Descriptive statistics: spl
# Descriptives only; no test was run and no assumption was checked.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunDescriptiveAnalysis: data, valueCol4$

# n = 24 valid
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Describe Table column...

# --- Step 5 (analysis) ---
selectObject: data5$
data = selected ()
# Normality: spl, both
# A normality test answers a question about the sample, not a licence for a later test.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunNormalityAnalysis: data, valueCol5$, "both"

# Shapiro-Wilk W = 0.9502, p = 0.2739
#   skewness = 0.1775, kurtosis = -1.0820, n = 24
#   Recommendation: parametric
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Check normality (all columns)...

# --- Step 6 (analysis) ---
selectObject: data6$
data = selected ()
# Correlation: spl with spl2, pearson
# Correlation is not causation, and a single coefficient hides the shape of the cloud.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunCorrelationAnalysis: data, xCol6$, yCol6$, "pearson"

# Pearson r = 0.0678, t(22) = 0.3189, p = 0.7528
#   n = 24
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Correlate two columns...

# --- Step 7 (analysis) ---
selectObject: data7$
data = selected ()
# Linear regression: spl on spl2
# Residual diagnostics are not run on this path.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunRegressionAnalysis: data, outcomeCol7$, predictorCol7$

# spl = 49.6803 + 0.0741 x spl2
#   R-squared = 0.0046, n = 24
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Linear regression...

# --- Step 8 (refusal) ---
selectObject: data8$
data = selected ()
# Refused: Unknown pairwise test: "t"

; (nothing executed at this step -- see the note above)


# --- Step 9 (refusal) ---
selectObject: data9$
data = selected ()
# Refused: No paired test could be run on these two columns. "spl" and "spl2" give n = 24 complete pairs, and every one of those pairs has the same difference, so there is no variation in the differences for a paired test to work on.

; (nothing executed at this step -- see the note above)


# --- Step 10 (refusal) ---
selectObject: data10$
data = selected ()
# Refused: Not yet implemented -- scheduled for Phase 4.

; (nothing executed at this step -- see the note above)


# --- Step 11 (analysis) ---
selectObject: data11$
data = selected ()
# Repeated-measures ANOVA: c1|c2|c3, subject subj
# Sphericity is corrected, not assumed; the report names the correction.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunRepeatedMeasuresAnalysis: data, subjectCol11$, conditionCols11$, 0, "holm"

# F(2, 46) = 110.3303, p = 0.000000000000000003
#   Greenhouse-Geisser epsilon = 0.9078, corrected p = 0.00000000000000008
#   n = 24 subjects, k = 3 conditions
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Stats Wizard... (three or more conditions)

# --- Step 12 (analysis) ---
selectObject: data12$
data = selected ()
# Friedman: c1|c2|c3, subject subj
# Rank-based repeated measures; it does not assume normality and does not test it.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunFriedmanAnalysis: data, subjectCol12$, conditionCols12$, 0, "holm"

# chi-square(2) = 42.2500, p = 0.0000000007
#   n = 24 subjects, k = 3 conditions
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Stats Wizard... (three or more conditions, Friedman)

# --- Step 13 (draw) ---
selectObject: data13$
data = selected ()
# Violin plot of spl, grouped by grp, 2 groups.
# Violin width is a kernel density estimate, not a count.

emlEraseFirst = eraseFirst13
emlPanelOriginX = panelOriginX13
emlPanelOriginY = panelOriginY13
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle13
emlSecondAxisOn = secondAxisOn13
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawViolinPlot: data, "Violin", "grp", "spl", 6, 4, "color", 1, groupCol13$, valueCol13$, axisYMin13, axisYMax13

# Axis resolved to 56.0000 .. 74.0000 over 2 groups on the recorded data; auto adapts to other data.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "spl".

# --- Step 14 (draw) ---
selectObject: data14$
data = selected ()
# Scatter plot: Scatter
# A fitted line is descriptive and carries no test.

emlEraseFirst = eraseFirst14
emlPanelOriginX = panelOriginX14
emlPanelOriginY = panelOriginY14
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle14
emlSecondAxisOn = secondAxisOn14
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
scatterAnalysisType = 0
annotCorrType$ = "pearson"
scatterRegressionLine = 0
@emlDrawScatterPlot: data, "Scatter", "x", "y", 6, 4, "color", 1, xCol14$, yCol14$, "", 0, 0, axisYMin14, axisYMax14, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 15 (draw) ---
selectObject: data15$
data = selected ()
# Histogram: Histogram
# Bin count changes the shape; it is a display choice, not a property of the data.

emlEraseFirst = eraseFirst15
emlPanelOriginX = panelOriginX15
emlPanelOriginY = panelOriginY15
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle15
emlSecondAxisOn = secondAxisOn15
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawHistogram: data, "Histogram", "spl", "Count", 6, 4, "color", 1, valueCol15$, "", 0, 1, axisValueMin15, axisValueMax15, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 16 (draw) ---
selectObject: data16$
data = selected ()
# Line chart: Line

emlEraseFirst = eraseFirst16
emlPanelOriginX = panelOriginX16
emlPanelOriginY = panelOriginY16
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle16
emlSecondAxisOn = secondAxisOn16
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawTimeSeries: data, "Line", "t", "spl", 6, 4, "color", 1, timeCol16$, valueCol16$, groupCol16$, 0, 0, axisYMin16, axisYMax16

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 17 (draw) ---
selectObject: data17$
data = selected ()
# Line chart (+/-CI): Line CI

emlEraseFirst = eraseFirst17
emlPanelOriginX = panelOriginX17
emlPanelOriginY = panelOriginY17
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle17
emlSecondAxisOn = secondAxisOn17
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawTimeSeriesCI: data, "Line CI", "t", "spl", 6, 4, "color", 1, timeCol17$, valueCol17$, groupCol17$, 0, 0, axisYMin17, axisYMax17

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 18 (draw) ---
selectObject: data18$
data = selected ()
# Spaghetti plot: Spaghetti

emlEraseFirst = eraseFirst18
emlPanelOriginX = panelOriginX18
emlPanelOriginY = panelOriginY18
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle18
emlSecondAxisOn = secondAxisOn18
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawSpaghettiPlot: data, "Spaghetti", "t", "spl", 6, 4, "color", 1, conditionCol18$, valueCol18$, idCol18$, groupCol18$, 1, axisYMin18, axisYMax18

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 19 (draw) ---
selectObject: data19$
data = selected ()
# Bar chart: Bar
# Bars show means. The spread, not the bar, is what tells you about the data.

emlEraseFirst = eraseFirst19
emlPanelOriginX = panelOriginX19
emlPanelOriginY = panelOriginY19
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle19
emlSecondAxisOn = secondAxisOn19
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawBarChart: data, "Bar", "grp", "spl", 6, 4, "color", 1, groupCol19$, valueCol19$, 0, "", axisYMin19, axisYMax19

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 20 (draw) ---
selectObject: data20$
data = selected ()
# Box plot: Box
# Whisker convention and outlier rule are stated in the figure, not assumed.

emlEraseFirst = eraseFirst20
emlPanelOriginX = panelOriginX20
emlPanelOriginY = panelOriginY20
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle20
emlSecondAxisOn = secondAxisOn20
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawBoxPlot: data, "Box", "grp", "spl", 6, 4, "color", 1, groupCol20$, valueCol20$, axisYMin20, axisYMax20

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 21 (draw) ---
selectObject: data21$
data = selected ()
# Grouped violin: GViolin
# Violin width is a kernel density estimate, not a count.

emlEraseFirst = eraseFirst21
emlPanelOriginX = panelOriginX21
emlPanelOriginY = panelOriginY21
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle21
emlSecondAxisOn = secondAxisOn21
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawGroupedViolin: data, "GViolin", "grp", "spl", 6, 4, "color", 1, categoryCol21$, subgroupCol21$, valueCol21$, axisYMin21, axisYMax21

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 22 (draw) ---
selectObject: data22$
data = selected ()
# Grouped box plot: GBox
# Whisker convention and outlier rule are stated in the figure, not assumed.

emlEraseFirst = eraseFirst22
emlPanelOriginX = panelOriginX22
emlPanelOriginY = panelOriginY22
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle22
emlSecondAxisOn = secondAxisOn22
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawGroupedBoxPlot: data, "GBox", "grp", "spl", 6, 4, "color", 1, categoryCol22$, subgroupCol22$, valueCol22$, axisYMin22, axisYMax22

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 23 (draw) ---
selectObject: data23$
data = selected ()
# Waveform: Waveform

emlEraseFirst = eraseFirst23
emlPanelOriginX = panelOriginX23
emlPanelOriginY = panelOriginY23
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle23
emlSecondAxisOn = secondAxisOn23
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawWaveform: data, "Waveform", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, axisYMin23, axisYMax23

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 24 (draw) ---
selectObject: data24$
data = selected ()
# F0 contour: F0

emlEraseFirst = eraseFirst24
emlPanelOriginX = panelOriginX24
emlPanelOriginY = panelOriginY24
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle24
emlSecondAxisOn = secondAxisOn24
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawF0Contour: data, "F0", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, axisYMin24, axisYMax24, 1

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 25 (draw) ---
selectObject: data25$
data = selected ()
# Spectrum: Spectrum

emlEraseFirst = eraseFirst25
emlPanelOriginX = panelOriginX25
emlPanelOriginY = panelOriginY25
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle25
emlSecondAxisOn = secondAxisOn25
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawSpectrum: data, "Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin25, axisYMax25

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 26 (draw) ---
selectObject: data26$
data = selected ()
# Long-term average spectrum: LTAS

emlEraseFirst = eraseFirst26
emlPanelOriginX = panelOriginX26
emlPanelOriginY = panelOriginY26
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle26
emlSecondAxisOn = secondAxisOn26
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawLTAS: data, "LTAS", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin26, axisYMax26, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 27 (convert) ---
selectObject: data27$
data = selected ()
# Converted Sound tone to Pitch tone.
# The pitch floor and ceiling are the ones this session used. They change the contour, so they belong in a methods section.

data = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 28 (draw) ---
# F0 contour: F0 from Sound

emlEraseFirst = eraseFirst27
emlPanelOriginX = panelOriginX27
emlPanelOriginY = panelOriginY27
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle27
emlSecondAxisOn = secondAxisOn27
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawF0Contour: data, "F0 from Sound", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, axisYMin27, axisYMax27, 1

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 29 (convert) ---
selectObject: data28$
data = selected ()
# Converted Sound tone to Spectrum tone.
# Fast (FFT) transform, which is what the figure was drawn from.

data = To Spectrum: "yes"

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 30 (draw) ---
# Spectrum: Spectrum from Sound

emlEraseFirst = eraseFirst28
emlPanelOriginX = panelOriginX28
emlPanelOriginY = panelOriginY28
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle28
emlSecondAxisOn = secondAxisOn28
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawSpectrum: data, "Spectrum from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin28, axisYMax28

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 31 (convert) ---
selectObject: data29$
data = selected ()
# Converted Sound tone to Ltas tone.
# 100 Hz bandwidth, the value this session used.

data = To Ltas: 100

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 32 (draw) ---
# Long-term average spectrum: LTAS from Sound

emlEraseFirst = eraseFirst29
emlPanelOriginX = panelOriginX29
emlPanelOriginY = panelOriginY29
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle29
emlSecondAxisOn = secondAxisOn29
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawLTAS: data, "LTAS from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin29, axisYMax29, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 33 (convert) ---
selectObject: data30$
data = selected ()
# Converted Spectrum tone to Ltas tone.
# One LTAS bin per spectral bin -- no rebinning, so the figure shows the spectrum's own resolution.

data = To Ltas (1-to-1)

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 34 (draw) ---
# Long-term average spectrum: LTAS from Spectrum

emlEraseFirst = eraseFirst30
emlPanelOriginX = panelOriginX30
emlPanelOriginY = panelOriginY30
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle30
emlSecondAxisOn = secondAxisOn30
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawLTAS: data, "LTAS from Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin30, axisYMax30, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 35 (convert) ---
selectObject: data31$
data = selected ()
# Converted Spectrum tone to Sound tone.
# Inverse transform back to a waveform.

data = To Sound

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 36 (draw) ---
# Waveform: Waveform from Spectrum

emlEraseFirst = eraseFirst31
emlPanelOriginX = panelOriginX31
emlPanelOriginY = panelOriginY31
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle31
emlSecondAxisOn = secondAxisOn31
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawWaveform: data, "Waveform from Spectrum", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, axisYMin31, axisYMax31

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 37 (convert) ---
selectObject: data32$
data = selected ()
# Converted Spectrum tone to Pitch tone.
# A Spectrum carries no pitch track, so the route is back through a Sound. The pitch floor and ceiling are the ones this session used. They change the contour, so they belong in a methods section.

tmp = To Sound
selectObject: tmp
data = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
removeObject: tmp
selectObject: data

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 38 (draw) ---
# F0 contour: F0 from Spectrum

emlEraseFirst = eraseFirst32
emlPanelOriginX = panelOriginX32
emlPanelOriginY = panelOriginY32
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle32
emlSecondAxisOn = secondAxisOn32
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawF0Contour: data, "F0 from Spectrum", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, axisYMin32, axisYMax32, 1

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 39 (convert) ---
selectObject: data33$
data = selected ()
# Converted TableOfReal tor to Table tor.
# Kept as a working object rather than removed after drawing, so the session goes on using the Table.

data = To Table: "row"
@emlCleanConvertedTable: data

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 40 (draw) ---
# Histogram: Histogram from TableOfReal
# Bin count changes the shape; it is a display choice, not a property of the data.

emlEraseFirst = eraseFirst33
emlPanelOriginX = panelOriginX33
emlPanelOriginY = panelOriginY33
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle33
emlSecondAxisOn = secondAxisOn33
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawHistogram: data, "Histogram from TableOfReal", "row", "Count", 6, 4, "color", 1, valueCol33$, "", 0, 1, axisValueMin33, axisValueMax33, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 41 (convert) ---
selectObject: data34$
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

# --- Step 42 (draw) ---
# Histogram: Histogram from Matrix
# Bin count changes the shape; it is a display choice, not a property of the data.

emlEraseFirst = eraseFirst34
emlPanelOriginX = panelOriginX34
emlPanelOriginY = panelOriginY34
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle34
emlSecondAxisOn = secondAxisOn34
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawHistogram: data, "Histogram from Matrix", "row", "Count", 6, 4, "color", 1, valueCol34$, "", 0, 1, axisValueMin34, axisValueMax34, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 43 (analysis) ---
selectObject: data35$
data = selected ()
# Group comparison on a figure: spl by grp3, parametric, 3 groups
# Reached through the figure's annotation rather than the stats menu; the test and the correction are the same.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlBridgeGroupComparison: data, valueCol35$, groupCol35$, 0.05, "stars", 0, 1, "parametric", 1

# One-way ANOVA: F(2, 21) = 0.02, p = .979
#   3 groups, alpha = 0.050
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs..., with statistical annotation switched on.

# --- Step 44 (draw) ---
selectObject: data36$
data = selected ()
# Scatter plot: Scatter with stats
# A fitted line is descriptive and carries no test. The correlation and regression below were reported from this figure.

emlEraseFirst = eraseFirst36
emlPanelOriginX = panelOriginX36
emlPanelOriginY = panelOriginY36
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle36
emlSecondAxisOn = secondAxisOn36
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
scatterAnalysisType = 3
annotCorrType$ = "spearman"
scatterRegressionLine = 1
@emlDrawScatterPlot: data, "Scatter with stats", "x", "y", 6, 4, "color", 1, xCol36$, yCol36$, "", 0, 0, axisYMin36, axisYMax36, 1

# spearman correlation reported on 24 complete pairs
#   spl2 = 199.9998 + 0.0620 x spl, R-squared = 0.0046
#   fit line: OLS (linear), slope = 0.0620, intercept = 199.9998
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 45 (draw) ---
selectObject: data37$
data = selected ()
# Scatter plot: Scatter, monotonic fit
# A fitted line is descriptive and carries no test. The correlation and regression below were reported from this figure.

emlEraseFirst = eraseFirst37
emlPanelOriginX = panelOriginX37
emlPanelOriginY = panelOriginY37
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle37
emlSecondAxisOn = secondAxisOn37
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
scatterAnalysisType = 1
annotCorrType$ = "spearman"
scatterRegressionLine = 1
@emlDrawScatterPlot: data, "Scatter, monotonic fit", "x", "y", 6, 4, "color", 1, xCol37$, yCol37$, "", 0, 0, axisYMin37, axisYMax37, 1

# spearman correlation reported on 24 complete pairs
#   fit line: Theil-Sen (monotonic), slope = 0.0374, intercept = 201.0878
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...


