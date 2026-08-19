# ---------------------------------------------------------------------------
# harness/linetree/data_meas3.praat
#
# THREE UNLIKE MEASUREMENTS -- the refusal.
#
# Hertz, a fraction and decibels. A figure has two vertical axes and there is
# no third, so the tree refuses toward page composition rather than
# normalising three quantities onto one scale behind the user's back.
#
# THE THIRD COLUMN IS UNTICKABLE, and this leg unticks it after reading the
# refusal, so the same fixture proves both that the refusal happens and that
# the page it sends the user back to still works.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_meas3", 0, "time f0 cq spl"
for i from 1 to 20
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i / 20
    Set numeric value: r, "f0", 220 + 30 * sin (i / 4)
    Set numeric value: r, "cq", 0.45 + 0.09 * cos (i / 3)
    Set numeric value: r, "spl", 68 + 6 * sin (i / 5)
endfor
ltMeas3Id = selected ("Table")
