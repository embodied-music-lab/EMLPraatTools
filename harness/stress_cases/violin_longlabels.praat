include _prelude.praat
; Deterministic noise -- tracker section 14. Praat's built-in Gaussian draw
; gave every run a different data set, so this figure's ink and chroma numbers
; churned and no run-to-run comparison of the case was possible. LCG, folded
; to roughly +/-1, scaled at the use site. The seed is per-case so that two
; cases drawing the same number of values do not get the same data.
rngState = 20260830
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .v = rngState / 2147483648
    .g = (.v - 0.5) * 3.4
endproc

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
    @rnd
    Set numeric value: i, "val", 40 + 5 * k + rnd.g * 2
endfor
Erase all
@emlDrawViolinPlot: t, "Long category labels", "Cohort", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
