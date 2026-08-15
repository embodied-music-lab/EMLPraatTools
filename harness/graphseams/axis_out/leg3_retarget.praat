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
        ... 1100 + g * 24 + (rngState / 2147483648 - 0.5) * 102
    endfor
endfor
table = selected ("Table")
Erase all
include /home/claude/EMLPraatTools/harness/graphseams/axis_out/auto_emitted.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/EMLPraatTools/harness/graphseams/axis_out/leg3.png"
appendInfoLine: "AXISLO=", fixed$ (emlDrawViolinPlot.axisYMin, 6)
appendInfoLine: "AXISHI=", fixed$ (emlDrawViolinPlot.axisYMax, 6)
selectObject: table
dLo = Get minimum: "val"
dHi = Get maximum: "val"
appendInfoLine: "DATALO=", fixed$ (dLo, 6)
appendInfoLine: "DATAHI=", fixed$ (dHi, 6)
