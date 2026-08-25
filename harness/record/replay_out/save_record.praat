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
include /home/claude/repo/plugin/stats/eml-analysis.praat
@emlInitDrawingDefaults
@emlRecordInit
@emlRecordBegin: ""
emlRecordPluginRoot$ = "/home/claude/repo/plugin"
@emlRecordLoadPhrases: "/home/claude/repo/plugin/data/eml-record-phrases.csv"
@emlRecordHeader: "Table vt", 40, 2, "14 August 2026, 00:00:00"

Create Table with column names: "vt", 0, "grp val"
rngState = 20260814
row = 0
for g from 1 to 2
    for k from 1 to 20
        rngState = (1103515245 * rngState + 12345) mod 2147483648
        row = row + 1
        Append row
        Set string value: row, "grp", "Cohort " + string$ (g)
        Set numeric value: row, "val",
        ... 1 + g * 1.2 + (rngState / 2147483648 - 0.5) * 1.4
    endfor
endfor
table = selected ("Table")

@emlRunTwoGroupAnalysis: table, "val", "grp", "parametric", 0
@emlRecordSource: table
@emlRecordStep: "save",
... "Save the outputs of this analysis",
... "Every output shares one folder and one name, so they stay a set.",
... "outputFolder$ = " + """" + "/home/claude/repo/harness/record/replay_out/saved" + """" + newline$
... + "@emlSavePanel: 0, " + """" + "vt_two-group_20260814_120000" + """" + ", outputFolder$, "
... + """""",
... "In the GUI: the Save button on the post-analysis or post-draw dialog."

@emlRecordFlush: "/home/claude/repo/harness/record/replay_out/save_emitted.praat"
@emlRecordDiscard
