# ---------------------------------------------------------------------------
# harness/linetree/data_longmeas3.praat
#
# THREE MEASUREMENTS IN ONE NAME COLUMN. The long-shape twin of
# data_meas3.praat: the same three quantities -- hertz, a fraction and a
# decibel level -- but stacked, so the third series arrives as a third LEVEL
# of "measure" rather than as a third column.
#
# A figure has two vertical axes however the third quantity is stored, so this
# is the fixture the level refusal is driven on, and the refusal it meets has
# to be worded for levels: there is no tickbox to untick here.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_longmeas3", 0, "time value measure"
for i from 1 to 20
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i / 20
    Set numeric value: r, "value", 210 + 25 * sin (i / 5)
    Set string value: r, "measure", "f0"
endfor
for i from 1 to 20
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i / 20
    Set numeric value: r, "value", 0.5 + 0.08 * cos (i / 4)
    Set string value: r, "measure", "cq"
endfor
for i from 1 to 20
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i / 20
    Set numeric value: r, "value", 62 + 6 * sin (i / 3)
    Set string value: r, "measure", "spl"
endfor
ltLongMeas3Id = selected ("Table")
