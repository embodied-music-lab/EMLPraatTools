# ---------------------------------------------------------------------------
# harness/secondaxis/data.praat -- THE TABLE, AND NOTHING ELSE.
#
# Split out of the fixture so that the REPLAY case can rebuild the same data
# without loading the plugin twice: an emitted script includes the library
# itself, so a replay that also included the fixture would define every
# procedure in the plugin a second time.
# ---------------------------------------------------------------------------
Create Table with column names: "secondaxis", 0, "t f0 cq g noise"
for i from 1 to 24
    Append row
    r = Get number of rows
    tt = (i - 1) mod 12 + 1
    Set numeric value: r, "t", tt
    ; The contact quotient RISES as the fundamental FALLS, and it does so
    ; identically in both singers -- the right-hand series is one series
    ; whatever the primary's grouping is, so a second series that differed by
    ; group would be drawn as the mean of the two and say nothing.
    Set numeric value: r, "cq", 0.40 + tt * 0.019
    if i <= 12
        Set numeric value: r, "f0", 268 - tt * 5 + (tt mod 3) * 4
        Set string value: r, "g", "soprano"
    else
        Set numeric value: r, "f0", 244 - tt * 4 - (tt mod 4) * 3
        Set string value: r, "g", "tenor"
    endif
    Set string value: r, "noise", "n" + string$ (tt)
endfor
