include _prelude.praat
t = Create Table with column names: "base", 30, "grp val"
for i to 30
    g$ = if i <= 10 then "A" else if i <= 20 then "B" else "C" fi fi
    Set string value: i, "grp", g$
    Set numeric value: i, "val", 50 + 10 * randomGauss (0, 1) + 5 * (i mod 3)
endfor
Erase all
@emlDrawViolinPlot: t, "Baseline violin (bw)", "Group", "Value", 6, 4, "bw", 1, "grp", "val", 0, 0
@stressSave: 6, 4
