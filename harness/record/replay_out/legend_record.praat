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
include /home/claude/EMLPraatTools/plugin/graphs/eml-graphs-form.praat
@emlInitDrawingDefaults
@emlRecordInit
@emlRecordBegin: ""
emlRecordPluginRoot$ = "/home/claude/EMLPraatTools/plugin"
@emlRecordLoadPhrases: "/home/claude/EMLPraatTools/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "Table lg", 56, 3, "16 August 2026, 00:00:00"

Create Table with column names: "lg", 0, "grp sub val"
rngState = 20260816
row = 0
for g from 1 to 4
    for k from 1 to 14
        rngState = (1103515245 * rngState + 12345) mod 2147483648
        row = row + 1
        Append row
        Set string value: row, "grp", "Cohort " + string$ (g)
        Set string value: row, "sub", "S" + string$ (k)
        Set numeric value: row, "val",
        ... 200 + g * 6.0 + (rngState / 2147483648 - 0.5) * 9.0
    endfor
endfor
table = selected ("Table")

graph_type = 11
objectId = table
title$ = "f0 by cohort"
x_axis_label$ = "Cohort"
y_axis_label$ = "f0 (Hz)"
figure_width = 6
figure_height = 4
colorMode$ = "color"
gridline_mode = 1
gvCatCol$ = "grp"
gvSubCol$ = "sub"
gvValueCol$ = "val"
groupColName$ = "grp"
valueColName$ = "val"
valueMin = 0
valueMax = 0
histFreqMax = 0
tsShowCI = 0
matrixGap = 0
matrixPanelHeight = 0
totalCanvasHeight = figure_height
config_legendPlacement = 1
config_showAdvanced = 1
config_groupSort = 1
emlGroupSortAlphabetical = 0
annotate = 0
dataYMax_forAnnotation = 0
@emlClearAnnotations

@emlGraphsPublishAxisRequest
random_initializeWithSeedUnsafelyButPredictably (20260816)
@emlGraphsDrawWithLegendRoom
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/record/replay_out/LEG_ORIG.png"

writeInfoLine: "legend_passes=", legendRoomPass
appendInfoLine: "legend_final_min=", fixed$ (valueMin, 6)
appendInfoLine: "legend_final_max=", fixed$ (valueMax, 6)

@emlRecordFlush: "/home/claude/EMLPraatTools/harness/record/replay_out/legend_emitted.praat"
@emlRecordDiscard
