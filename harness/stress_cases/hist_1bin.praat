include _prelude.praat
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
    Set numeric value: i, "val", 20 + 4 * c + 3 * s + randomGauss (0, 2)
    Set numeric value: i, "err", 1.5
    Set numeric value: i, "time", c
endfor
Erase all
@emlDrawHistogram: t, "Histogram 1 bin", "Value", "Count", 6, 4, "color", 1, "val", "", 1, 0, 0, 0, 0
@stressSave: 6, 4
