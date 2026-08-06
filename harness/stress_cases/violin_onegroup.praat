include _prelude.praat
t = Create Table with column names: "og", 15, "grp val"
for i to 15
    Set string value: i, "grp", "Only"
    Set numeric value: i, "val", 10 + randomGauss (0, 2)
endfor
Erase all
@emlDrawViolinPlot: t, "Single group", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
