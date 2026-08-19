# ---------------------------------------------------------------------------
# harness/linetree/data_meas2.praat
#
# TWO UNLIKE MEASUREMENTS, ONE ROW PER TIME. Fundamental frequency in hertz
# and contact quotient as a fraction: two numeric columns whose ranges differ
# by three orders of magnitude, which is the whole reason the right-hand axis
# exists. Plotted on one scale the quotient is a flat line on the floor.
#
# NO TIME VALUE REPEATS: this leg is the one that reaches the right-hand axis
# page with nothing to average.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_meas2", 0, "time f0 cq"
for i from 1 to 24
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i / 24
    Set numeric value: r, "f0", 220 + 30 * sin (i / 4)
    Set numeric value: r, "cq", 0.45 + 0.09 * cos (i / 3)
endfor
ltMeas2Id = selected ("Table")
