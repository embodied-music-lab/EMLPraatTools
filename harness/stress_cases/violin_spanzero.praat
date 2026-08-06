include _prelude.praat
t = Create Table with column names: "sz", 30, "grp val"
for i to 30
    Set string value: i, "grp", if i <= 15 then "A" else "B" fi
    Set numeric value: i, "val", (i - 15) * 1.5
endfor
Erase all
@emlDrawViolinPlot: t, "Spanning zero", "Group", "Cents deviation", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
