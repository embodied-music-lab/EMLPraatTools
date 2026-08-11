# ---------------------------------------------------------------------------
# Is "significant omnibus, no significant pair" reachable, and what does the
# figure look like when it happens?
#
# This is the second half of probe_annot_yrange.praat. That probe showed that
# @emlDrawAnnotationBlock, handed a degenerate (0, 0) y-range while the axis
# sits near 200, places the omnibus box off the frame and it is CLIPPED AWAY
# ENTIRELY -- the statistical result vanishes from the figure with no error
# and no note. What it did not show is whether a real analysis can put the
# form in that state, and a defect that no input reaches is a different thing
# from one that a common input reaches.
#
# THE STATE REQUIRED is annotBracketN = 0 AND annotTextN > 0 AND
# annotMatrixN = 0, on graph type 6, 7 or 9, with the y-range left on auto.
# The form's PRE-dispatch resolver -- the block that turns valueMin/valueMax
# from (0, 0) into the real extent -- is gated on `annotBracketN > 0`, so
# with no brackets nothing resolves them and the post-dispatch block hands
# (0, 0) to the annotation box.
#
# @emlBridgeGroupComparison produces exactly that state on its BRACKET path
# (nGroups <= 3, or layoutMode forcing brackets):
#
#     annotBracketN = 0
#     for each pair: if .pairP < .alpha or .showNS = 1 -> annotBracketN + 1
#     ...
#     annotTextN = 1                       <- the omnibus, set unconditionally
#
# So a SIGNIFICANT OMNIBUS WITH NO SURVIVING PAIRWISE COMPARISON leaves
# annotBracketN at 0 while annotTextN is 1. That is not an exotic input. It
# is what a corrected post-hoc routinely returns.
#
# This probe asks the bridge directly, with data built to land there, and
# prints the two counters. It asserts nothing about aesthetics; the counters
# either reach the state or they do not.
#
# Run: praat --run probe_annot_omnibus_only.praat     (EML_OUT = folder)
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------
include ../stress_cases/_prelude.praat

probeOut$ = environment$ ("EML_OUT")
if probeOut$ = ""
    probeOut$ = "."
endif
emlSubtitle$ = "SENTINEL-SUBTITLE"

; THE DEFAULTS REPRODUCE. Four groups, means separated by less than a third
; of the within-group spread, so the omnibus does not clear alpha and no pair
; does either -- annotBracketN stays 0 while annotTextN is 1. Values sit near
; 200 so a box placed at y = 0 is unambiguously off the frame rather than
; merely low. Seeded, so the verdict does not move between runs.
;
; The four knobs are exposed because finding the state took a sweep, and the
; sweep is worth being able to repeat: EML_NGRP x EML_SEP x EML_SPREAD x
; EML_NPER. Separation is what moves the boundary -- at sep 1.6, spread 9,
; four groups gives three brackets and the defect does not appear.
;
; TWO ROUTES REACH THE SAME STATE, and the defaults take the first:
;   1. Omnibus NOT significant. @emlBridgeGroupComparison's else-branch still
;      sets annotTextN = 1, so the "F(3, 52) = 0.46, p = .709" line exists
;      and has to be drawn somewhere.
;   2. Omnibus significant, no pair surviving correction. The bracket path
;      counts only pairs below alpha, so annotBracketN stays 0.
; Route 1 is the common one: EVERY non-significant omnibus on an auto-ranged
; bar, violin or box plot lands here.
nPer = number (environment$ ("EML_NPER"))
if nPer = undefined or nPer = 0
    nPer = 14
endif
nGrp = number (environment$ ("EML_NGRP"))
if nGrp = undefined or nGrp = 0
    nGrp = 4
endif
sep = number (environment$ ("EML_SEP"))
if sep = undefined
    sep = 0.9
endif
spread = number (environment$ ("EML_SPREAD"))
if spread = undefined or spread = 0
    spread = 12
endif
tbl = Create Table with column names: "om", 0, "grp v"
row = 0
rngState = 20260811
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .u = rngState / 2147483648
endproc
for g from 1 to nGrp
    for k from 1 to nPer
        @rnd
        row = row + 1
        Append row
        Set string value: row, "grp", "G" + string$ (g)
        Set numeric value: row, "v", 200 + g * sep + (rnd.u - 0.5) * spread
    endfor
endfor
tblId = selected ("Table")

@emlClearAnnotations
; layoutMode 2 = brackets. alpha .05, style "stars", showNS 0, showEffect 0.
@emlBridgeGroupComparison: tblId, "v", "grp", 0.05, "stars", 0, 0, "auto", 2

appendInfoLine: "OMNIBUSONLY brackets=", annotBracketN,
... " text=", annotTextN, " matrix=", annotMatrixN

; The form's entry condition for the post-dispatch annotation block.
reaches = 0
if annotBracketN > 0 or (annotTextN > 0 and annotMatrixN = 0)
    reaches = 1
endif
appendInfoLine: "OMNIBUSONLY postDispatchRuns=", reaches,
... " preDispatchResolverRuns=", (annotBracketN > 0)

; Draw it the way the form does, to see the consequence rather than infer it.
if annotBracketN = 0 and annotTextN > 0 and annotMatrixN = 0
    valueMin = 0
    valueMax = 0
    annotBlockN = 0
    annotBlockN = annotBlockN + 1
    annotBlockLabel$[annotBlockN] = annotTextLabel$[1]
    annotBlockDraw$[annotBlockN] = annotTextLabel$[1]
    annotTextN = 0
    Erase all
    @emlDrawViolinPlot: tblId, "Omnibus only", "Group", "Value", 6, 4,
    ... "color", 1, "grp", "v", valueMin, valueMax
    @emlDrawAnnotationBlock: "top-right", emlDrawViolinPlot.axisXMin,
    ... emlDrawViolinPlot.axisXMax, valueMin, valueMax,
    ... emlSetAdaptiveTheme.annotSize
    appendInfoLine: "OMNIBUSONLY drew axis=", emlDrawViolinPlot.axisYMin,
    ... " ", emlDrawViolinPlot.axisYMax, " box got=", valueMin, " ", valueMax
    appendInfoLine: "OMNIBUSONLY label=", annotBlockLabel$[1]
    @emlAssertFullViewport
    Save as 300-dpi PNG file: probeOut$ + "/annot_omnibus_only.png"
endif
