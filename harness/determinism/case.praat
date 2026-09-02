# ---------------------------------------------------------------------------
# DETERMINISM CASE. One graph type, drawn from a SEEDED fixture.
# Run twice in two Praat processes; the two PNGs must be identical.
#
# WHY THIS EXISTS. A test that cannot detect a regression is not a test, and
# 22 of the 39 cases in harness/stress_cases/ call randomGauss with no seed.
# Two consecutive runs of violin_baseline, with no code change between them:
#
#     violin_baseline   OK   11.348%   230063
#     violin_baseline   OK   14.106%   289575
#
# v27 survives that because it asserts inequalities -- verdict, ink > 0,
# chromatic > 0, empty below every populated sibling -- and never exact
# values. But nothing in the suite would notice a draw procedure that started
# producing a DIFFERENT correct-looking figure, because no two runs of it are
# comparable in the first place.
#
# This harness asks the narrower question the stress suite cannot: given the
# same data, does a draw procedure produce the same picture twice? A type
# that fails here has no reproducible baseline, and every check built on its
# output is weaker than it appears.
#
# Run: praat --run case.praat <type>
#      1 ts   2 tsci   3 spaghetti   4 bar    5 violin
#      6 box  7 gviolin 8 gbox       9 scatter 10 histogram
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------
include ../stress_cases/_prelude.praat

form: "Determinism"
    word: "Gtype", "5"
endform
gtype = number (gtype$)

; SEEDED. An in-script LCG, not randomGauss, because the entire point is that
; two processes see identical data. Praat has no seed control for its own
; generator, so the generator has to be ours.
rngState = 20260810
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .u = rngState / 2147483648
    .g = (.u - 0.5) * 3.2
endproc

@emlInitializeDrawingDefaults
Erase all

; --- the fixture. One long table serves every type; each draw call reads the
; columns it needs and ignores the rest, so the DATA is constant across types
; and only the procedure under test varies.
Create Table with column names: "det", 0, "t val grp sub id x"
row = 0
for g from 1 to 3
    for tt from 1 to 6
        for k from 1 to 6
            @rnd
            row = row + 1
            Append row
            Set numeric value: row, "t", tt
            Set numeric value: row, "val", 200 + g * 9 + tt * 2 + rnd.g * 6
            Set string value: row, "grp", "Cohort " + string$ (g)
            Set string value: row, "sub", "Phase " + string$ ((k mod 3) + 1)
            Set numeric value: row, "id", (g - 1) * 6 + k
            @rnd
            Set numeric value: row, "x", 10 + rnd.u * 40
        endfor
    endfor
endfor
tid = selected ("Table")

selectObject: tid
if gtype = 1
    @emlDrawTimeSeries: tid, "Determinism", "Session", "f0 (Hz)", 6, 4,
    ... "color", 1, "t", "val", "grp", 0, 0, 0, 0
elsif gtype = 2
    @emlDrawTimeSeriesCI: tid, "Determinism", "Session", "f0 (Hz)", 6, 4,
    ... "color", 1, "t", "val", "grp", 0, 0, 0, 0
elsif gtype = 3
    @emlDrawSpaghettiPlot: tid, "Determinism", "Session", "f0 (Hz)", 6, 4,
    ... "color", 1, "t", "val", "id", "grp", 1, 0, 0
elsif gtype = 4
    @emlDrawBarChart: tid, "Determinism", "Cohort", "f0 (Hz)", 6, 4,
    ... "color", 1, "grp", "val", 1, "", 0, 0
elsif gtype = 5
    @emlDrawViolinPlot: tid, "Determinism", "Cohort", "f0 (Hz)", 6, 4,
    ... "color", 1, "grp", "val", 0, 0
elsif gtype = 6
    @emlDrawBoxPlot: tid, "Determinism", "Cohort", "f0 (Hz)", 6, 4,
    ... "color", 1, "grp", "val", 0, 0
elsif gtype = 7
    @emlDrawGroupedViolin: tid, "Determinism", "Cohort", "f0 (Hz)", 6, 4,
    ... "color", 1, "grp", "sub", "val", 0, 0
elsif gtype = 8
    @emlDrawGroupedBoxPlot: tid, "Determinism", "Cohort", "f0 (Hz)", 6, 4,
    ... "color", 1, "grp", "sub", "val", 0, 0
elsif gtype = 9
    @emlDrawScatterPlot: tid, "Determinism", "Intensity", "f0 (Hz)", 6, 4,
    ... "color", 1, "x", "val", "grp", 0, 0, 0, 0, 0
elsif gtype = 10
    @emlDrawHistogram: tid, "Determinism", "f0 (Hz)", "Count", 6, 4,
    ... "color", 1, "val", "grp", 0, 1, 0, 0, 0
else
    exitScript: "Unknown type ", gtype
endif

@emlAssertFullViewport
Save as 300-dpi PNG file: stressOut$
