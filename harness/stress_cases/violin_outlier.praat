include _prelude.praat
t = Create Table with column names: "out", 21, "grp val"
for i to 20
    Set string value: i, "grp", if i <= 10 then "A" else "B" fi
    Set numeric value: i, "val", 50 + randomGauss (0, 2)
endfor
Set string value: 21, "grp", "B"
Set numeric value: 21, "val", 5000
Erase all
@emlDrawViolinPlot: t, "One value 100x the rest", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
