include _prelude.praat
t = Create Table with column names: "un", 24, "grp val"
for i to 24
    Set string value: i, "grp", if i <= 12 then "A" else "B" fi
    if i mod 4 = 0
        Set string value: i, "val", ""
    else
        Set numeric value: i, "val", 30 + randomGauss (0, 4)
    endif
endfor
Erase all
@emlDrawViolinPlot: t, "One in four cells blank", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
