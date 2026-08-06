include _prelude.praat
t = Create Table with column names: "n1", 3, "grp val"
Set string value: 1, "grp", "A"
Set numeric value: 1, "val", 10
Set string value: 2, "grp", "B"
Set numeric value: 2, "val", 20
Set string value: 3, "grp", "C"
Set numeric value: 3, "val", 30
Erase all
@emlDrawViolinPlot: t, "n = 1 per group", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
