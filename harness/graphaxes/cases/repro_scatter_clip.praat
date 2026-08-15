include _prelude.praat
# NEW-G8-1 reproduction: user-set axis range that excludes data.
t = Create Table with column names: "clip", 30, "x y"
for i from 1 to 30
    selectObject: t
    xv = 90 + (i - 1) * 8
    yv = 2 * xv + 5 + (i mod 5) * 3
    Set numeric value: i, "x", xv
    Set numeric value: i, "y", yv
endfor
Erase all
# X range 100..300 typed by the user; data runs 90..322.
@emlDrawScatterPlot: t, "Clip probe", "X", "Y", 6, 4, "color", 4, "x", "y", "", 100, 300, 0, 0, 1
appendInfoLine: "AXISX ", emlDrawScatterPlot.axisXMin, " ", emlDrawScatterPlot.axisXMax
@axSave
