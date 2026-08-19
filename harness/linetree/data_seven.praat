# ---------------------------------------------------------------------------
# harness/linetree/data_seven.praat
#
# SEVEN NUMERIC COLUMNS BESIDE THE TIME COLUMN -- the ceiling test.
#
# The page this fixture opens used to be five hardcoded "Series N" menus, so
# a seventh column was not merely inconvenient: it could not be named. Seven
# is chosen rather than six because the colour palette has eight slots and
# seven is the largest count that still gives every series its own hue, which
# is what makes "the seventh is on the page" measurable by colour.
#
# THE SEVEN BANDS ARE DISJOINT, 100 apart, and the SEVENTH IS THE TOP ONE.
# A figure that quietly dropped the last column would have a different
# y-axis maximum and no ink in the top band, and both are read off the PNG.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_seven", 0, "time c1 c2 c3 c4 c5 c6 c7"
for i from 1 to 10
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i
    for k from 1 to 7
        ltColName$ = "c" + string$ (k)
        Set numeric value: r, ltColName$, k * 100 + i * 4 + (i mod 3) * 5
    endfor
endfor
ltSevenId = selected ("Table")
