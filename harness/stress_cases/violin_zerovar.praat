include _prelude.praat
t = Create Table with column names: "zv", 20, "grp val"
for i to 20
    Set string value: i, "grp", if i <= 10 then "A" else "B" fi
    Set numeric value: i, "val", 42
endfor
Erase all
@emlDrawViolinPlot: t, "Every value identical", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
