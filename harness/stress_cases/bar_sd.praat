include _prelude.praat
; Deterministic noise -- tracker section 14. Praat's built-in Gaussian draw
; gave every run a different data set, so this figure's ink and chroma numbers
; churned and no run-to-run comparison of the case was possible. LCG, folded
; to roughly +/-1, scaled at the use site. The seed is per-case so that two
; cases drawing the same number of values do not get the same data.
rngState = 20260814
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .v = rngState / 2147483648
    .g = (.v - 0.5) * 3.4
endproc

# Repeated-measures fixture: 12 subjects x 3 conditions.
#   cat   - condition (within-subject)
#   sub   - between-subject grouping, constant within a subject
#   id    - subject, appears once per condition
#   time  - condition index, for the continuous-x types
t = Create Table with column names: "d", 36, "cat sub val err time id"
for i to 36
    subj = (i - 1) div 3 + 1
    c = (i - 1) mod 3 + 1
    s = (subj - 1) mod 2 + 1
    Set string value: i, "cat", "Cat" + string$ (c)
    Set string value: i, "sub", "S" + string$ (s)
    Set string value: i, "id", "P" + string$ (subj)
    @rnd
    Set numeric value: i, "val", 20 + 4 * c + 3 * s + rnd.g * 2
    Set numeric value: i, "err", 1.5
    Set numeric value: i, "time", c
endfor
Erase all
@emlDrawBarChart: t, "Bar with SD bars", "Category", "Value", 6, 4, "color", 1, "cat", "val", 2, "", 0, 0
@stressSave: 6, 4
