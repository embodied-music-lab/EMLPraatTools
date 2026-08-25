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
Create Table with column names: "rt", 0, "cohort room dB"
rngState = 20260814
row = 0
for g from 1 to 2
    for s from 1 to 2
        for k from 1 to 10
            rngState = (1103515245 * rngState + 12345) mod 2147483648
            row = row + 1
            Append row
            Set string value: row, "cohort", "Cohort " + string$ (g)
            Set string value: row, "room", "Room " + string$ (s)
            Set numeric value: row, "dB",
            ... 1 + g * 1.2 + s * 0.4 + (rngState / 2147483648 - 0.5) * 1.4
        endfor
    endfor
endfor
table = selected ("Table")
@emlRunTwoWayAnalysis: table, "dB", "cohort", "room"
