include /home/claude/repo/plugin/stats/eml-core-utilities.praat
include /home/claude/repo/plugin/stats/eml-core-descriptive.praat
include /home/claude/repo/plugin/stats/eml-extract.praat
include /home/claude/repo/plugin/stats/eml-output.praat
include /home/claude/repo/plugin/stats/eml-inferential.praat
include /home/claude/repo/plugin/stats/eml-result-writer.praat
include /home/claude/repo/plugin/stats/eml-record.praat
include /home/claude/repo/plugin/graphs/eml-graph-procedures.praat
include /home/claude/repo/plugin/graphs/eml-annotation-procedures.praat
include /home/claude/repo/plugin/graphs/eml-draw-procedures.praat

@emlInitializeDrawingDefaults
@emlRecordInit
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordBegin: "/home/claude/repo/harness/graphseams/axis_out"
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordLoadPhrases: "/home/claude/repo/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "vt", 100, 2, "axis choice explicit"

Create Table with column names: "vt", 0, "grp val"
rngState = 20260815
row = 0
for g from 1 to 4
    for k from 1 to 25
        rngState = (1103515245 * rngState + 12345) mod 2147483648
        row = row + 1
        Append row
        Set string value: row, "grp", "Cohort " + string$ (g)
        Set numeric value: row, "val",
        ... 200 + g * 8 + (rngState / 2147483648 - 0.5) * 34
    endfor
endfor
table = selected ("Table")

Erase all
@emlDrawViolinPlot: table, "f0 by cohort", "Cohort", "f0 (Hz)", 6, 4,
... "color", 1, "grp", "val", 150, 300
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/graphseams/axis_out/leg5.png"
appendInfoLine: "AXISLO=", fixed$ (emlDrawViolinPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed$ (emlDrawViolinPlot.axisYMax, 6)

@emlRecordFlush: "/home/claude/repo/harness/graphseams/axis_out/expl_emitted.praat"
@emlRecordDiscard
