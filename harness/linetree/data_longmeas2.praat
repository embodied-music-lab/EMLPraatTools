# ---------------------------------------------------------------------------
# harness/linetree/data_longmeas2.praat
#
# THE SAME TWO MEASUREMENTS AS data_meas2.praat, STORED LONG. One numeric
# column called "value", one text column called "measure" whose two levels are
# spelled exactly as data_meas2's two numeric columns are -- "f0" and "cq" --
# and the same 24 time points, carrying the same two arithmetic expressions in
# the same order.
#
# THE IDENTITY IS THE WHOLE POINT OF THIS FIXTURE. Meaning and storage are
# independent, so the same numbers under the same names must produce the same
# figure whichever shape they arrive in. The f0 rows come first and the cq
# rows second, which is the order data_meas2's COLUMNS are in, so "table
# order" means the same thing on both sides and series 1 is f0 on both.
#
# The arithmetic is copied rather than shared: an include that built both
# tables from one loop would make the two fixtures the same statement written
# once, and the claim being pinned is that two independently written tables
# holding the same numbers draw the same picture.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_longmeas2", 0, "time value measure"
for i from 1 to 24
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i / 24
    Set numeric value: r, "value", 220 + 30 * sin (i / 4)
    Set string value: r, "measure", "f0"
endfor
for i from 1 to 24
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i / 24
    Set numeric value: r, "value", 0.45 + 0.09 * cos (i / 3)
    Set string value: r, "measure", "cq"
endfor
ltLongMeas2Id = selected ("Table")
