include _prelude.praat
t = Create Table with column names: "ll", 30, "grp val"
for i to 30
    k = (i - 1) mod 3 + 1
    if k = 1
        g$ = "Preprofessional undergraduate"
    elsif k = 2
        g$ = "Continuing education adult"
    else
        g$ = "Professional performing"
    endif
    Set string value: i, "grp", g$
    Set numeric value: i, "val", 40 + 5 * k + randomGauss (0, 2)
endfor
Erase all
@emlDrawViolinPlot: t, "Long category labels", "Cohort", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
