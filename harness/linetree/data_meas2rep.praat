# ---------------------------------------------------------------------------
# harness/linetree/data_meas2rep.praat
#
# THE SAME TWO UNLIKE MEASUREMENTS, THREE OBSERVATIONS AT EVERY TIME.
#
# This is the row of the dispatch table that gets means and no band: the
# repeats exist, so @emlLineTreeRepeats finds them, but the role is
# "different measurements" and an interval across two scales is not offered.
# The column page must NOT carry the interval field on this leg, the figure
# must be drawn from the per-time means, and the form must SAY so.
#
# The scatter is the same deterministic stream data_grouprep.praat uses.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_meas2rep", 0, "time f0 cq"
ltM2Rng = 20260819
for i from 1 to 8
    for k from 1 to 3
        Append row
        r = Get number of rows
        ltM2Rng = (1103515245 * ltM2Rng + 12345) mod 2147483648
        ltM2U = ltM2Rng / 2147483648
        Set numeric value: r, "time", i / 8
        Set numeric value: r, "f0", 220 + 30 * sin (i / 2) + (ltM2U - 0.5) * 12
        Set numeric value: r, "cq", 0.45 + 0.09 * cos (i / 2) + (ltM2U - 0.5) * 0.05
    endfor
endfor
ltMeas2RepId = selected ("Table")
