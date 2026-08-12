include _prelude.praat
; Deterministic noise -- tracker section 14. Praat's built-in Gaussian draw
; gave every run a different data set, so this figure's ink and chroma numbers
; churned and no run-to-run comparison of the case was possible. LCG, folded
; to roughly +/-1, scaled at the use site. The seed is per-case so that two
; cases drawing the same number of values do not get the same data.
rngState = 20260833
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .v = rngState / 2147483648
    .g = (.v - 0.5) * 3.4
endproc

t = Create Table with column names: "un", 24, "grp val"
for i to 24
    Set string value: i, "grp", if i <= 12 then "A" else "B" fi
    if i mod 4 = 0
        Set string value: i, "val", ""
    else
        @rnd
        Set numeric value: i, "val", 30 + rnd.g * 4
    endif
endfor
Erase all
@emlDrawViolinPlot: t, "One in four cells blank", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
