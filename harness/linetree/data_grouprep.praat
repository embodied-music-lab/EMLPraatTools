# ---------------------------------------------------------------------------
# harness/linetree/data_grouprep.praat
#
# ONE VALUE COLUMN AND A GROUP COLUMN, WITH FOUR OBSERVATIONS AT EVERY
# (time, group). The shape the tree calls shape 2: one numeric column beside
# the time column and one text column that names the series.
#
# THE REPEATS ARE THE POINT. @emlLineTreeRepeats scans (time, group) and must
# find four per point, the column page must then OFFER the interval and say
# "four" in its own label, and accepting it must dispatch to
# @emlDrawTimeSeriesCI rather than to @emlDrawTimeSeries.
#
# THE SCATTER IS DETERMINISTIC -- a linear congruential stream, not
# randomGauss -- so the interval this leg draws is the same interval tomorrow
# and a PNG digest means something.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_grouprep", 0, "time f0 speaker"
ltGrRng = 20260818
for g from 1 to 2
    for tt from 1 to 6
        for k from 1 to 4
            Append row
            r = Get number of rows
            ltGrRng = (1103515245 * ltGrRng + 12345) mod 2147483648
            ltGrU = ltGrRng / 2147483648
            Set numeric value: r, "time", tt
            Set numeric value: r, "f0",
            ... 180 + g * 60 + tt * 4 + (ltGrU - 0.5) * 18
            Set string value: r, "speaker", "Speaker " + string$ (g)
        endfor
    endfor
endfor
ltGroupRepId = selected ("Table")
