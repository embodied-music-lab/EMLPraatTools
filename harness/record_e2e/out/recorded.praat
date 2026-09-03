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
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-anova-kernel.praat
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

@emlInitializeDrawingDefaults
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
data9$ = "Table voiceA"   ; run 9, step 9 (analysis)
data10$ = "Table voiceA"   ; run 10, step 10 (refusal)
data11$ = "Table voiceA"   ; run 11, step 11 (analysis)
data12$ = "Table voiceA"   ; run 12, step 12 (analysis)
data13$ = "Table voiceA"   ; run 13, step 13 (analysis)
data14$ = "Table voiceA"   ; run 14, step 14 (draw)
data15$ = "Table voiceA"   ; run 15, step 15 (draw)
data16$ = "Table voiceA"   ; run 16, step 16 (draw)
data17$ = "Table voiceA"   ; run 17, step 17 (draw)
data18$ = "Table voiceA"   ; run 18, step 18 (draw)
data19$ = "Table voiceA"   ; run 19, step 19 (draw)
data20$ = "Table voiceA"   ; run 20, step 20 (draw)
data21$ = "Table voiceA"   ; run 21, step 21 (draw)
data22$ = "Table voiceA"   ; run 22, step 22 (draw)
data23$ = "Table voiceA"   ; run 23, step 23 (draw)
data24$ = "Sound tone"   ; run 24, step 24 (draw)
data25$ = "Pitch tone"   ; run 25, step 25 (draw)
data26$ = "Spectrum tone"   ; run 26, step 26 (draw)
data27$ = "Ltas tone"   ; run 27, step 27 (draw)
data28$ = "Sound tone"   ; run 28, steps 28 (convert), 29 (draw)
data29$ = "Sound tone"   ; run 29, steps 30 (convert), 31 (draw)
data30$ = "Sound tone"   ; run 30, steps 32 (convert), 33 (draw)
data31$ = "Spectrum tone"   ; run 31, steps 34 (convert), 35 (draw)
data32$ = "Spectrum tone"   ; run 32, steps 36 (convert), 37 (draw)
data33$ = "Spectrum tone"   ; run 33, steps 38 (convert), 39 (draw)
data34$ = "TableOfReal tor"   ; run 34, steps 40 (convert), 41 (draw)
data35$ = "Matrix mat"   ; run 35, steps 42 (convert), 43 (draw)
data36$ = "Table voiceA"   ; run 36, step 44 (analysis)
data37$ = "Table voiceA"   ; run 37, step 45 (draw)
data38$ = "Table voiceA"   ; run 38, step 46 (draw)
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
valueCol9$       = "spl"   ; the measured column -- run 9, step 9 (analysis)
factorACol9$     = "grp"   ; the first factor -- run 9, step 9 (analysis)
factorBCol9$     = "grp2"   ; the second factor -- run 9, step 9 (analysis)
itemCols1_11$    = "c1"   ; item column 1 -- run 11, step 11 (analysis)
itemCols2_11$    = "c2"   ; item column 2 -- run 11, step 11 (analysis)
itemCols3_11$    = "c3"   ; item column 3 -- run 11, step 11 (analysis)
subjectCol12$    = "subj"   ; the subject identifier -- run 12, step 12 (analysis)
conditionCols12$ = "c1|c2|c3"   ; the condition columns -- run 12, step 12 (analysis)
subjectCol13$    = "subj"   ; the subject identifier -- run 13, step 13 (analysis)
conditionCols13$ = "c1|c2|c3"   ; the condition columns -- run 13, step 13 (analysis)
groupCol14$      = "grp"   ; the grouping column -- run 14, step 14 (draw)
valueCol14$      = "spl"   ; the measured column -- run 14, step 14 (draw)
xCol15$          = "spl"   ; the x column -- run 15, step 15 (draw)
yCol15$          = "spl2"   ; the y column -- run 15, step 15 (draw)
valueCol16$      = "spl"   ; the measured column -- run 16, step 16 (draw)
timeCol17$       = "t"   ; the time column -- run 17, step 17 (draw)
valueCol17$      = "spl"   ; the measured column -- run 17, step 17 (draw)
groupCol17$      = "grp"   ; the grouping column -- run 17, step 17 (draw)
timeCol18$       = "t"   ; the time column -- run 18, step 18 (draw)
valueCol18$      = "spl"   ; the measured column -- run 18, step 18 (draw)
groupCol18$      = "grp"   ; the grouping column -- run 18, step 18 (draw)
conditionCol19$  = "t"   ; the condition column -- run 19, step 19 (draw)
valueCol19$      = "spl"   ; the measured column -- run 19, step 19 (draw)
idCol19$         = "subj"   ; the case identifier -- run 19, step 19 (draw)
groupCol19$      = "grp"   ; the grouping column -- run 19, step 19 (draw)
groupCol20$      = "grp"   ; the grouping column -- run 20, step 20 (draw)
valueCol20$      = "spl"   ; the measured column -- run 20, step 20 (draw)
groupCol21$      = "grp"   ; the grouping column -- run 21, step 21 (draw)
valueCol21$      = "spl"   ; the measured column -- run 21, step 21 (draw)
categoryCol22$   = "grp"   ; the category column -- run 22, step 22 (draw)
subgroupCol22$   = "grp2"   ; the sub-group column -- run 22, step 22 (draw)
valueCol22$      = "spl"   ; the measured column -- run 22, step 22 (draw)
categoryCol23$   = "grp"   ; the category column -- run 23, step 23 (draw)
subgroupCol23$   = "grp2"   ; the sub-group column -- run 23, step 23 (draw)
valueCol23$      = "spl"   ; the measured column -- run 23, step 23 (draw)
valueCol34$      = "row"   ; the measured column -- run 34, step 41 (draw)
valueCol35$      = "row"   ; the measured column -- run 35, step 43 (draw)
valueCol36$      = "spl"   ; the measured column -- run 36, step 44 (analysis)
groupCol36$      = "grp3"   ; the grouping column -- run 36, step 44 (analysis)
xCol37$          = "spl"   ; the x column -- run 37, step 45 (draw)
yCol37$          = "spl2"   ; the y column -- run 37, step 45 (draw)
xCol38$          = "spl"   ; the x column -- run 38, step 46 (draw)
yCol38$          = "spl2"   ; the y column -- run 38, step 46 (draw)
axisYMin14       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 14, step 14 (draw)
axisYMax14       = 0.0   ; on the recorded data this resolved to 56.0000 .. 74.0000; auto adapts to other data
axisYMin15       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 15, step 15 (draw)
axisYMax15       = 0.0   ; on the recorded data this resolved to 196.0000 .. 212.0000; auto adapts to other data
axisValueMin16   = 0.0   ; the value-axis range (the histogram's horizontal axis) -- AUTO (both 0 = computed from the data) -- run 16, step 16 (draw)
axisValueMax16   = 0.0   ; on the recorded data this resolved to 59.8175 .. 70.2386; auto adapts to other data
axisYMin17       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 17, step 17 (draw)
axisYMax17       = 0.0   ; on the recorded data this resolved to 62.5000 .. 67.0000; auto adapts to other data
axisYMin18       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 18, step 18 (draw)
axisYMax18       = 0.0   ; on the recorded data this resolved to 56.0000 .. 76.0000; auto adapts to other data
axisYMin19       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 19, step 19 (draw)
axisYMax19       = 0.0   ; on the recorded data this resolved to 58.0000 .. 72.0000; auto adapts to other data
axisYMin20       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 20, step 20 (draw)
axisYMax20       = 0.0   ; on the recorded data this resolved to 0.0000 .. 80.0000; auto adapts to other data
axisYMin21       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 21, step 21 (draw)
axisYMax21       = 0.0   ; on the recorded data this resolved to 58.0000 .. 72.0000; auto adapts to other data
axisYMin22       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 22, step 22 (draw)
axisYMax22       = 0.0   ; on the recorded data this resolved to 54.0000 .. 76.0000; auto adapts to other data
axisYMin23       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 23, step 23 (draw)
axisYMax23       = 0.0   ; on the recorded data this resolved to 58.0000 .. 72.0000; auto adapts to other data
axisYMin24       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 24, step 24 (draw)
axisYMax24       = 0.0   ; on the recorded data this resolved to -0.4500 .. 0.4500; auto adapts to other data
axisYMin25       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 25, step 25 (draw)
axisYMax25       = 0.0   ; on the recorded data this resolved to 219.2000 .. 220.8000; auto adapts to other data
axisYMin26       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 26, step 26 (draw)
axisYMax26       = 0.0   ; on the recorded data this resolved to 0.0000 .. 80.0000; auto adapts to other data
axisYMin27       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 27, step 27 (draw)
axisYMax27       = 0.0   ; on the recorded data this resolved to -20.0000 .. 80.0000; auto adapts to other data
axisYMin28       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 28, step 29 (draw)
axisYMax28       = 0.0   ; on the recorded data this resolved to 219.0000 .. 220.8000; auto adapts to other data
axisYMin29       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 29, step 31 (draw)
axisYMax29       = 0.0   ; on the recorded data this resolved to 0.0000 .. 80.0000; auto adapts to other data
axisYMin30       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 30, step 33 (draw)
axisYMax30       = 0.0   ; on the recorded data this resolved to -20.0000 .. 80.0000; auto adapts to other data
axisYMin31       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 31, step 35 (draw)
axisYMax31       = 0.0   ; on the recorded data this resolved to -20.0000 .. 80.0000; auto adapts to other data
axisYMin32       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 32, step 37 (draw)
axisYMax32       = 0.0   ; on the recorded data this resolved to -0.4500 .. 0.4500; auto adapts to other data
axisYMin33       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 33, step 39 (draw)
axisYMax33       = 0.0   ; on the recorded data this resolved to 217.5000 .. 220.5000; auto adapts to other data
axisValueMin34   = 0.0   ; the value-axis range (the histogram's horizontal axis) -- AUTO (both 0 = computed from the data) -- run 34, step 41 (draw)
axisValueMax34   = 0.0   ; on the recorded data this resolved to 0.0000 .. 1.0000; auto adapts to other data
axisValueMin35   = 0.0   ; the value-axis range (the histogram's horizontal axis) -- AUTO (both 0 = computed from the data) -- run 35, step 43 (draw)
axisValueMax35   = 0.0   ; on the recorded data this resolved to 0.0000 .. 1.0000; auto adapts to other data
axisYMin37       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 37, step 45 (draw)
axisYMax37       = 0.0   ; on the recorded data this resolved to 196.0000 .. 212.0000; auto adapts to other data
axisYMin38       = 0.0   ; the y-axis range -- AUTO (both 0 = computed from the data) -- run 38, step 46 (draw)
axisYMax38       = 0.0   ; on the recorded data this resolved to 196.0000 .. 212.0000; auto adapts to other data
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
eraseFirst27     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 27, step 27 (draw)
panelOriginX27   = 0   ; inches from the left of the page to this panel's corner -- run 27, step 27 (draw)
panelOriginY27   = 0   ; inches from the top of the page to this panel's corner -- run 27, step 27 (draw)
lineStyle27      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 27, step 27 (draw)
secondAxisOn27   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 27, step 27 (draw)
eraseFirst28     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 28, step 29 (draw)
panelOriginX28   = 0   ; inches from the left of the page to this panel's corner -- run 28, step 29 (draw)
panelOriginY28   = 0   ; inches from the top of the page to this panel's corner -- run 28, step 29 (draw)
lineStyle28      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 28, step 29 (draw)
secondAxisOn28   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 28, step 29 (draw)
eraseFirst29     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 29, step 31 (draw)
panelOriginX29   = 0   ; inches from the left of the page to this panel's corner -- run 29, step 31 (draw)
panelOriginY29   = 0   ; inches from the top of the page to this panel's corner -- run 29, step 31 (draw)
lineStyle29      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 29, step 31 (draw)
secondAxisOn29   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 29, step 31 (draw)
eraseFirst30     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 30, step 33 (draw)
panelOriginX30   = 0   ; inches from the left of the page to this panel's corner -- run 30, step 33 (draw)
panelOriginY30   = 0   ; inches from the top of the page to this panel's corner -- run 30, step 33 (draw)
lineStyle30      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 30, step 33 (draw)
secondAxisOn30   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 30, step 33 (draw)
eraseFirst31     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 31, step 35 (draw)
panelOriginX31   = 0   ; inches from the left of the page to this panel's corner -- run 31, step 35 (draw)
panelOriginY31   = 0   ; inches from the top of the page to this panel's corner -- run 31, step 35 (draw)
lineStyle31      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 31, step 35 (draw)
secondAxisOn31   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 31, step 35 (draw)
eraseFirst32     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 32, step 37 (draw)
panelOriginX32   = 0   ; inches from the left of the page to this panel's corner -- run 32, step 37 (draw)
panelOriginY32   = 0   ; inches from the top of the page to this panel's corner -- run 32, step 37 (draw)
lineStyle32      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 32, step 37 (draw)
secondAxisOn32   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 32, step 37 (draw)
eraseFirst33     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 33, step 39 (draw)
panelOriginX33   = 0   ; inches from the left of the page to this panel's corner -- run 33, step 39 (draw)
panelOriginY33   = 0   ; inches from the top of the page to this panel's corner -- run 33, step 39 (draw)
lineStyle33      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 33, step 39 (draw)
secondAxisOn33   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 33, step 39 (draw)
eraseFirst34     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 34, step 41 (draw)
panelOriginX34   = 0   ; inches from the left of the page to this panel's corner -- run 34, step 41 (draw)
panelOriginY34   = 0   ; inches from the top of the page to this panel's corner -- run 34, step 41 (draw)
lineStyle34      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 34, step 41 (draw)
secondAxisOn34   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 34, step 41 (draw)
eraseFirst35     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 35, step 43 (draw)
panelOriginX35   = 0   ; inches from the left of the page to this panel's corner -- run 35, step 43 (draw)
panelOriginY35   = 0   ; inches from the top of the page to this panel's corner -- run 35, step 43 (draw)
lineStyle35      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 35, step 43 (draw)
secondAxisOn35   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 35, step 43 (draw)
eraseFirst37     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 37, step 45 (draw)
panelOriginX37   = 0   ; inches from the left of the page to this panel's corner -- run 37, step 45 (draw)
panelOriginY37   = 0   ; inches from the top of the page to this panel's corner -- run 37, step 45 (draw)
lineStyle37      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 37, step 45 (draw)
secondAxisOn37   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 37, step 45 (draw)
eraseFirst38     = 1   ; 1 clears the page before this figure, 0 adds it to the page already there -- run 38, step 46 (draw)
panelOriginX38   = 0   ; inches from the left of the page to this panel's corner -- run 38, step 46 (draw)
panelOriginY38   = 0   ; inches from the top of the page to this panel's corner -- run 38, step 46 (draw)
lineStyle38      = 1   ; the series' pen: 1 Solid, 2 Dotted, 3 Dashed, 4 Dashed-dotted -- run 38, step 46 (draw)
secondAxisOn38   = 0   ; 1 draws a second series on a right-hand y-axis, 0 draws one axis -- run 38, step 46 (draw)
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
@emlRunKruskalWallisAnalysis: data, valueCol3$, groupCol3$, 0, "holm"

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


# --- Step 9 (analysis) ---
selectObject: data9$
data = selected ()
# Two-way ANOVA: spl by grp and grp2
# Type of sums of squares and the balance of the design both matter here; see the report.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunTwoWayAnalysis: data, valueCol9$, factorACol9$, factorBCol9$

# grp: F(1, 20) = 3.8873, p = 0.0626
#   grp2: F(1, 20) = 0.0136, p = 0.9083
#   interaction: F(1, 20) = 0.0688, p = 0.7958
#   n = 24, cells = 4
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Compare two-way (ANOVA)...

# --- Step 10 (refusal) ---
selectObject: data10$
data = selected ()
# Refused: No paired test could be run on these two columns. "spl" and "spl2" give n = 24 complete pairs, and every one of those pairs has the same difference, so there is no variation in the differences for a paired test to work on.

; (nothing executed at this step -- see the note above)


# --- Step 11 (analysis) ---
selectObject: data11$
data = selected ()
# Reliability: Cronbach's alpha over 3 item(s) (c1, c2, c3)
# Alpha describes internal consistency of THIS scale on THIS sample; it is not evidence the items measure one trait, and it is not a licence for any later test.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunReliabilityAnalysis: data, {itemCols1_11$, itemCols2_11$, itemCols3_11$}, 0.95, 1

# alpha = 0.2725, 95% CI [-0.4339, 0.6618]
#   n = 24 respondents, k = 3 items
# The same step through the menu:
# Not in the GUI: there is no menu entry for this yet.

# --- Step 12 (analysis) ---
selectObject: data12$
data = selected ()
# Repeated-measures ANOVA: c1|c2|c3, subject subj
# Sphericity is corrected, not assumed; the report names the correction.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunRepeatedMeasuresAnalysis: data, subjectCol12$, conditionCols12$, 0, "holm"

# F(2, 46) = 110.3303, p = 0.000000000000000003
#   Greenhouse-Geisser epsilon = 0.9078, corrected p = 0.00000000000000008
#   n = 24 subjects, k = 3 conditions
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Stats Wizard... (three or more conditions)

# --- Step 13 (analysis) ---
selectObject: data13$
data = selected ()
# Friedman: c1|c2|c3, subject subj
# Rank-based repeated measures; it does not assume normality and does not test it.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunFriedmanAnalysis: data, subjectCol13$, conditionCols13$, 0, "holm"

# chi-square(2) = 42.2500, p = 0.0000000007
#   n = 24 subjects, k = 3 conditions
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > Stats Wizard... (three or more conditions, Friedman)

# --- Step 14 (draw) ---
selectObject: data14$
data = selected ()
# Violin plot of spl, grouped by grp, 2 groups.
# Violin width is a kernel density estimate, not a count.

emlEraseFirst = eraseFirst14
emlPanelOriginX = panelOriginX14
emlPanelOriginY = panelOriginY14
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle14
emlSecondAxisOn = secondAxisOn14
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawViolinPlot: data, "Violin", "grp", "spl", 6, 4, "color", 1, groupCol14$, valueCol14$, axisYMin14, axisYMax14

# Axis resolved to 56.0000 .. 74.0000 over 2 groups on the recorded data; auto adapts to other data.
# The same step through the menu:
# In the GUI: EML Graphs..., type Violin Plot,
# Group column "grp", Value column "spl".

# --- Step 15 (draw) ---
selectObject: data15$
data = selected ()
# Scatter plot: Scatter
# A fitted line is descriptive and carries no test.

emlEraseFirst = eraseFirst15
emlPanelOriginX = panelOriginX15
emlPanelOriginY = panelOriginY15
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle15
emlSecondAxisOn = secondAxisOn15
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
scatterAnalysisType = 0
annotCorrType$ = "pearson"
scatterRegressionLine = 0
scatterCorrScope = 1
@emlDrawScatterPlot: data, "Scatter", "x", "y", 6, 4, "color", 1, xCol15$, yCol15$, "", 0, 0, axisYMin15, axisYMax15, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 16 (draw) ---
selectObject: data16$
data = selected ()
# Histogram: Histogram
# Bin count changes the shape; it is a display choice, not a property of the data.

emlEraseFirst = eraseFirst16
emlPanelOriginX = panelOriginX16
emlPanelOriginY = panelOriginY16
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle16
emlSecondAxisOn = secondAxisOn16
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawHistogram: data, "Histogram", "spl", "Count", 6, 4, "color", 1, valueCol16$, "", 0, 1, axisValueMin16, axisValueMax16, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 17 (draw) ---
selectObject: data17$
data = selected ()
# Line chart: Line

emlEraseFirst = eraseFirst17
emlPanelOriginX = panelOriginX17
emlPanelOriginY = panelOriginY17
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle17
emlSecondAxisOn = secondAxisOn17
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawTimeSeries: data, "Line", "t", "spl", 6, 4, "color", 1, timeCol17$, valueCol17$, groupCol17$, 0, 0, axisYMin17, axisYMax17

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 18 (draw) ---
selectObject: data18$
data = selected ()
# Line chart (+/-CI): Line CI

emlEraseFirst = eraseFirst18
emlPanelOriginX = panelOriginX18
emlPanelOriginY = panelOriginY18
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle18
emlSecondAxisOn = secondAxisOn18
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawTimeSeriesCI: data, "Line CI", "t", "spl", 6, 4, "color", 1, timeCol18$, valueCol18$, groupCol18$, 0, 0, axisYMin18, axisYMax18

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 19 (draw) ---
selectObject: data19$
data = selected ()
# Spaghetti plot: Spaghetti

emlEraseFirst = eraseFirst19
emlPanelOriginX = panelOriginX19
emlPanelOriginY = panelOriginY19
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle19
emlSecondAxisOn = secondAxisOn19
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawSpaghettiPlot: data, "Spaghetti", "t", "spl", 6, 4, "color", 1, conditionCol19$, valueCol19$, idCol19$, groupCol19$, 1, axisYMin19, axisYMax19

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 20 (draw) ---
selectObject: data20$
data = selected ()
# Bar chart: Bar
# Bars show means. The spread, not the bar, is what tells you about the data.

emlEraseFirst = eraseFirst20
emlPanelOriginX = panelOriginX20
emlPanelOriginY = panelOriginY20
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle20
emlSecondAxisOn = secondAxisOn20
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawBarChart: data, "Bar", "grp", "spl", 6, 4, "color", 1, groupCol20$, valueCol20$, 0, "", axisYMin20, axisYMax20

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 21 (draw) ---
selectObject: data21$
data = selected ()
# Box plot: Box
# Whisker convention and outlier rule are stated in the figure, not assumed.

emlEraseFirst = eraseFirst21
emlPanelOriginX = panelOriginX21
emlPanelOriginY = panelOriginY21
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle21
emlSecondAxisOn = secondAxisOn21
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawBoxPlot: data, "Box", "grp", "spl", 6, 4, "color", 1, groupCol21$, valueCol21$, axisYMin21, axisYMax21

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 22 (draw) ---
selectObject: data22$
data = selected ()
# Grouped violin: GViolin
# Violin width is a kernel density estimate, not a count.

emlEraseFirst = eraseFirst22
emlPanelOriginX = panelOriginX22
emlPanelOriginY = panelOriginY22
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle22
emlSecondAxisOn = secondAxisOn22
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawGroupedViolin: data, "GViolin", "grp", "spl", 6, 4, "color", 1, categoryCol22$, subgroupCol22$, valueCol22$, axisYMin22, axisYMax22

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 23 (draw) ---
selectObject: data23$
data = selected ()
# Grouped box plot: GBox
# Whisker convention and outlier rule are stated in the figure, not assumed.

emlEraseFirst = eraseFirst23
emlPanelOriginX = panelOriginX23
emlPanelOriginY = panelOriginY23
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle23
emlSecondAxisOn = secondAxisOn23
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawGroupedBoxPlot: data, "GBox", "grp", "spl", 6, 4, "color", 1, categoryCol23$, subgroupCol23$, valueCol23$, axisYMin23, axisYMax23

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 24 (draw) ---
selectObject: data24$
data = selected ()
# Waveform: Waveform

emlEraseFirst = eraseFirst24
emlPanelOriginX = panelOriginX24
emlPanelOriginY = panelOriginY24
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle24
emlSecondAxisOn = secondAxisOn24
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawWaveform: data, "Waveform", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, axisYMin24, axisYMax24

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 25 (draw) ---
selectObject: data25$
data = selected ()
# F0 contour: F0

emlEraseFirst = eraseFirst25
emlPanelOriginX = panelOriginX25
emlPanelOriginY = panelOriginY25
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle25
emlSecondAxisOn = secondAxisOn25
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawF0Contour: data, "F0", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, axisYMin25, axisYMax25, 1

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 26 (draw) ---
selectObject: data26$
data = selected ()
# Spectrum: Spectrum

emlEraseFirst = eraseFirst26
emlPanelOriginX = panelOriginX26
emlPanelOriginY = panelOriginY26
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle26
emlSecondAxisOn = secondAxisOn26
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawSpectrum: data, "Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin26, axisYMax26

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 27 (draw) ---
selectObject: data27$
data = selected ()
# Long-term average spectrum: LTAS

emlEraseFirst = eraseFirst27
emlPanelOriginX = panelOriginX27
emlPanelOriginY = panelOriginY27
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle27
emlSecondAxisOn = secondAxisOn27
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawLTAS: data, "LTAS", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin27, axisYMax27, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 28 (convert) ---
selectObject: data28$
data = selected ()
# Converted Sound tone to Pitch tone.
# The pitch floor and ceiling are the ones this session used. They change the contour, so they belong in a methods section.

data = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 29 (draw) ---
# F0 contour: F0 from Sound

emlEraseFirst = eraseFirst28
emlPanelOriginX = panelOriginX28
emlPanelOriginY = panelOriginY28
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle28
emlSecondAxisOn = secondAxisOn28
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawF0Contour: data, "F0 from Sound", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, axisYMin28, axisYMax28, 1

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 30 (convert) ---
selectObject: data29$
data = selected ()
# Converted Sound tone to Spectrum tone.
# Fast (FFT) transform, which is what the figure was drawn from.

data = To Spectrum: "yes"

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 31 (draw) ---
# Spectrum: Spectrum from Sound

emlEraseFirst = eraseFirst29
emlPanelOriginX = panelOriginX29
emlPanelOriginY = panelOriginY29
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle29
emlSecondAxisOn = secondAxisOn29
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawSpectrum: data, "Spectrum from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin29, axisYMax29

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 32 (convert) ---
selectObject: data30$
data = selected ()
# Converted Sound tone to Ltas tone.
# 100 Hz bandwidth, the value this session used.

data = To Ltas: 100

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 33 (draw) ---
# Long-term average spectrum: LTAS from Sound

emlEraseFirst = eraseFirst30
emlPanelOriginX = panelOriginX30
emlPanelOriginY = panelOriginY30
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle30
emlSecondAxisOn = secondAxisOn30
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawLTAS: data, "LTAS from Sound", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin30, axisYMax30, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 34 (convert) ---
selectObject: data31$
data = selected ()
# Converted Spectrum tone to Ltas tone.
# One LTAS bin per spectral bin -- no rebinning, so the figure shows the spectrum's own resolution.

data = To Ltas (1-to-1)

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 35 (draw) ---
# Long-term average spectrum: LTAS from Spectrum

emlEraseFirst = eraseFirst31
emlPanelOriginX = panelOriginX31
emlPanelOriginY = panelOriginY31
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle31
emlSecondAxisOn = secondAxisOn31
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawLTAS: data, "LTAS from Spectrum", "Frequency (Hz)", "dB", 6, 4, "color", 1, 0, 0, axisYMin31, axisYMax31, 1, 0, 0, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 36 (convert) ---
selectObject: data32$
data = selected ()
# Converted Spectrum tone to Sound tone.
# Inverse transform back to a waveform.

data = To Sound

# The same step through the menu:
# In the GUI: this happens automatically when you ask for a figure that needs it.

# --- Step 37 (draw) ---
# Waveform: Waveform from Spectrum

emlEraseFirst = eraseFirst32
emlPanelOriginX = panelOriginX32
emlPanelOriginY = panelOriginY32
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle32
emlSecondAxisOn = secondAxisOn32
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawWaveform: data, "Waveform from Spectrum", "Time (s)", "Amplitude", 6, 4, "color", 1, 0, 0, axisYMin32, axisYMax32

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 38 (convert) ---
selectObject: data33$
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

# --- Step 39 (draw) ---
# F0 contour: F0 from Spectrum

emlEraseFirst = eraseFirst33
emlPanelOriginX = panelOriginX33
emlPanelOriginY = panelOriginY33
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle33
emlSecondAxisOn = secondAxisOn33
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawF0Contour: data, "F0 from Spectrum", "Time (s)", "F0 (Hz)", 6, 4, "color", 1, 0, 0, axisYMin33, axisYMax33, 1

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 40 (convert) ---
selectObject: data34$
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

emlEraseFirst = eraseFirst34
emlPanelOriginX = panelOriginX34
emlPanelOriginY = panelOriginY34
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle34
emlSecondAxisOn = secondAxisOn34
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawHistogram: data, "Histogram from TableOfReal", "row", "Count", 6, 4, "color", 1, valueCol34$, "", 0, 1, axisValueMin34, axisValueMax34, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 42 (convert) ---
selectObject: data35$
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

emlEraseFirst = eraseFirst35
emlPanelOriginX = panelOriginX35
emlPanelOriginY = panelOriginY35
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle35
emlSecondAxisOn = secondAxisOn35
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlDrawHistogram: data, "Histogram from Matrix", "row", "Count", 6, 4, "color", 1, valueCol35$, "", 0, 1, axisValueMin35, axisValueMax35, 0

# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 44 (analysis) ---
selectObject: data36$
data = selected ()
# Group comparison on a figure: spl by grp3, parametric, 3 groups
# Reached through the figure's annotation rather than the stats menu; the test and the correction are the same.

@emlReportContext: "recorded script (recorded 12 August 2026, originally analysis dialog)", ""
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
@emlRunAnnotationComparison: data, valueCol36$, groupCol36$, 0.05, "stars", 0, 1, "parametric", 1

# One-way ANOVA: F(2, 21) = 0.02, p = .979
#   3 groups, alpha = 0.050
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs..., with statistical annotation switched on.

# --- Step 45 (draw) ---
selectObject: data37$
data = selected ()
# Scatter plot: Scatter with stats
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
scatterAnalysisType = 3
annotCorrType$ = "spearman"
scatterRegressionLine = 1
scatterCorrScope = 1
@emlDrawScatterPlot: data, "Scatter with stats", "x", "y", 6, 4, "color", 1, xCol37$, yCol37$, "", 0, 0, axisYMin37, axisYMax37, 1

# spearman correlation reported on 24 complete pairs
#   spl2 = 199.9998 + 0.0620 x spl, R-squared = 0.0046
#   fit line: OLS (linear), slope = 0.0620, intercept = 199.9998
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...

# --- Step 46 (draw) ---
selectObject: data38$
data = selected ()
# Scatter plot: Scatter, monotonic fit
# A fitted line is descriptive and carries no test. The correlation and regression below were reported from this figure.

emlEraseFirst = eraseFirst38
emlPanelOriginX = panelOriginX38
emlPanelOriginY = panelOriginY38
@emlBeginPanel: emlPanelOriginX, emlPanelOriginY, emlEraseFirst
emlLineStyle = lineStyle38
emlSecondAxisOn = secondAxisOn38
annotAlpha = 0.05
emlGroupSortAlphabetical = 0
emlShowExplanations = 0
scatterAnalysisType = 1
annotCorrType$ = "spearman"
scatterRegressionLine = 1
scatterCorrScope = 1
@emlDrawScatterPlot: data, "Scatter, monotonic fit", "x", "y", 6, 4, "color", 1, xCol38$, yCol38$, "", 0, 0, axisYMin38, axisYMax38, 1

# spearman correlation reported on 24 complete pairs
#   fit line: Theil-Sen (monotonic), slope = 0.0374, intercept = 201.0878
# The same step through the menu:
# In the GUI: New > EML Stats & Graphs > EML Graphs...


