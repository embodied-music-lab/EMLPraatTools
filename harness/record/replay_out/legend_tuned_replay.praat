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
Erase all
random_initializeWithSeedUnsafelyButPredictably (20260816)
include /home/claude/repo/harness/record/replay_out/legend_tuned.praat
@emlAssertFullViewport
Save as 300-dpi PNG file: "/home/claude/repo/harness/record/replay_out/LEG_TUNED.png"
