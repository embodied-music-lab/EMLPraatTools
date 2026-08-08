# ---------------------------------------------------------------------------
# THE LOOK CASES. A REAL grouped figure at a chosen group count, drawn through
# the real procedure, so the marker work can be looked at rather than only
# measured.
#
# The measured claim ("all 24 styles are pairwise distinguishable") is settled
# by marker_case.praat on isolated marks. It does not answer the second
# question the author asked -- where the shapes stop being distinguishable in
# a REAL figure, with marks crowding each other and a legend to match them
# against. These renders are that question, at 8, 16 and 24 groups, in colour
# and in greyscale, for the two chart types that draw the most marks.
#
# Driven by harness/markers/run.sh, which sets:
#   EML_MODE     color | bw
#   EML_CHART    scatter | spaghetti | ts
#   EML_NGROUPS  number of groups
#   EML_OUT      PNG path
#
# Deterministic: no randomGauss anywhere, so a re-run is byte-comparable and
# any difference between two runs is a code change.
# ---------------------------------------------------------------------------
include /home/claude/EMLPraatTools/harness/stress_cases/_prelude.praat

mode$ = environment$ ("EML_MODE")
if mode$ = ""
    mode$ = "color"
endif
chart$ = environment$ ("EML_CHART")
if chart$ = ""
    chart$ = "scatter"
endif
nGroups = number (environment$ ("EML_NGROUPS"))
if nGroups = undefined
    nGroups = 8
endif
if nGroups < 1
    nGroups = 1
endif

# Three conditions per group, five subjects per group. One row per
# (group, subject, condition).
nCond = 3
nSubj = 5
nRows = nGroups * nSubj * nCond
t = Create Table with column names: "look", nRows, "grp id cat val time xc"
r = 0
for g to nGroups
    for s to nSubj
        for c to nCond
            r = r + 1
            Set string value: r, "grp", "G" + string$ (g)
            Set string value: r, "id", "G" + string$ (g) + "P" + string$ (s)
            Set string value: r, "cat", "C" + string$ (c)
            Set numeric value: r, "time", c
            # A CONTINUOUS x for the scatter. "time" stays an integer so the
            # time series draws three tidy time points per group; a scatter
            # against it would stack every group in three vertical columns
            # and hide exactly what these renders are for.
            Set numeric value: r, "xc", c + 0.34 * cos (g * 2.1 + s * 1.3)
            ... + 0.11 * s - 0.33
            # Deterministic spread: groups fan out, subjects sit inside the
            # group, conditions rise. No RNG.
            v = 20 + 1.4 * g + 2.2 * c + 0.6 * s
            ... + 0.9 * sin (g * 1.7 + s * 2.3 + c * 0.9)
            Set numeric value: r, "val", v
        endfor
    endfor
endfor

Erase all
if chart$ = "spaghetti"
    @emlDrawSpaghettiPlot: t, "Spaghetti, " + string$ (nGroups) + " groups",
    ... "Condition", "Value", 12, 7, mode$, 1, "cat", "val", "id", "grp",
    ... 1, 0, 0
elsif chart$ = "ts"
    @emlDrawTimeSeries: t, "Time series, " + string$ (nGroups) + " groups",
    ... "Time", "Value", 12, 7, mode$, 1, "time", "val", "grp", 0, 0, 0, 0
else
    @emlDrawScatterPlot: t, "Scatter, " + string$ (nGroups) + " groups",
    ... "Time", "Value", 12, 7, mode$, 1, "xc", "val", "grp",
    ... 0, 0, 0, 0, 0
endif
@stressSave: 12, 7
