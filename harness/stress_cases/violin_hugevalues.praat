include _prelude.praat
t = Create Table with column names: "huge", 20, "grp val"
for i to 20
    Set string value: i, "grp", if i <= 10 then "A" else "B" fi
    Set numeric value: i, "val", 1.0e12 * (1 + 0.05 * i)
endfor
Erase all
@emlDrawViolinPlot: t, "Values near 1e12", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
