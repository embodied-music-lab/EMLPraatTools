include _prelude.praat
; Deterministic noise -- tracker section 14. Praat's built-in Gaussian draw
; gave every run a different data set, so this figure's ink and chroma numbers
; churned and no run-to-run comparison of the case was possible. LCG, folded
; to roughly +/-1, scaled at the use site. The seed is per-case so that two
; cases drawing the same number of values do not get the same data.
rngState = 20260832
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .v = rngState / 2147483648
    .g = (.v - 0.5) * 3.4
endproc

t = Create Table with column names: "out", 21, "grp val"
for i to 20
    Set string value: i, "grp", if i <= 10 then "A" else "B" fi
    @rnd
    Set numeric value: i, "val", 50 + rnd.g * 2
endfor
Set string value: 21, "grp", "B"
Set numeric value: 21, "val", 5000
Erase all
@emlDrawViolinPlot: t, "One value 100x the rest", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
