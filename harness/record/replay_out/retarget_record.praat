include /home/claude/repo/plugin/stats/eml-core-utilities.praat
include /home/claude/repo/plugin/stats/eml-core-descriptive.praat
include /home/claude/repo/plugin/stats/eml-extract.praat
include /home/claude/repo/plugin/stats/eml-output.praat
include /home/claude/repo/plugin/stats/eml-anova-kernel.praat
include /home/claude/repo/plugin/stats/eml-inferential.praat
include /home/claude/repo/plugin/stats/eml-result-writer.praat
include /home/claude/repo/plugin/stats/eml-record.praat
include /home/claude/repo/plugin/graphs/eml-graph-procedures.praat
include /home/claude/repo/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/repo/plugin/graphs/eml-draw-procedures.praat
include /home/claude/repo/plugin/stats/eml-analysis.praat
@emlInitializeDrawingDefaults
@emlRecordInit
@emlRecordBegin: ""
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordLoadPhrases: "/home/claude/repo/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "Table wt", 40, 3, "14 August 2026, 00:00:00"

Create Table with column names: "wt", 0, "grp site val"
rngState = 20260814
row = 0
for g from 1 to 2
    for s from 1 to 2
        for k from 1 to 10
            rngState = (1103515245 * rngState + 12345) mod 2147483648
            row = row + 1
            Append row
            Set string value: row, "grp", "Cohort " + string$ (g)
            Set string value: row, "site", "Room " + string$ (s)
            Set numeric value: row, "val",
            ... 1 + g * 1.2 + s * 0.4 + (rngState / 2147483648 - 0.5) * 1.4
        endfor
    endfor
endfor
table = selected ("Table")

@emlRunTwoWayAnalysis: table, "val", "grp", "site"

selectObject: table
vMin = Get minimum: "val"
vMax = Get maximum: "val"
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260814)
@emlDrawViolinPlot: table, "retarget violin", "Cohort", "val", 6, 4,
... "color", 1, "grp", "val", vMin, vMax
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/record/replay_out/RET_ORIG.png"

@emlRecordFlush: "/home/claude/repo/harness/record/replay_out/retarget_emitted.praat"
@emlRecordDiscard
