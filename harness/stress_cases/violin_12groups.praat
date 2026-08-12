include _prelude.praat
; Deterministic noise -- tracker section 14. Praat's built-in Gaussian draw
; gave every run a different data set, so this figure's ink and chroma numbers
; churned and no run-to-run comparison of the case was possible. LCG, folded
; to roughly +/-1, scaled at the use site. The seed is per-case so that two
; cases drawing the same number of values do not get the same data.
rngState = 20260827
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .v = rngState / 2147483648
    .g = (.v - 0.5) * 3.4
endproc

t = Create Table with column names: "g12", 120, "grp val"
for i to 120
    k = (i - 1) mod 12 + 1
    Set string value: i, "grp", "G" + string$ (k)
    @rnd
    Set numeric value: i, "val", 20 + k + rnd.g * 3
endfor
Erase all
@emlDrawViolinPlot: t, "Twelve groups", "Group", "Value", 6, 4, "color", 1, "grp", "val", 0, 0
@stressSave: 6, 4
