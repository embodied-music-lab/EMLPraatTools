include _prelude.praat
t = Create Table with column names: "g12", 120, "grp val"
for i to 120
    k = (i - 1) mod 12 + 1
    Set string value: i, "grp", "G" + string$ (k)
    Set numeric value: i, "val", 20 + k + randomGauss (0, 3)
endfor
Erase all
@emlDrawViolinPlot: t, "Twelve groups", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
