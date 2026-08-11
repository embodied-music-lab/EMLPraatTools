# ---------------------------------------------------------------------------
# Does the form's second floating box collide with the draw procedure's?
#
# eml-graphs-form.praat renders TWO floating boxes on an annotated categorical
# figure: the one @emlDiscloseEnd draws inside the draw procedure, and the one
# the POST-DISPATCH stage draws afterwards from annotBlockN (bracket
# comparisons + omnibus line). Drawn 7 Aug 2026 without a guard, an annotated
# violin plot with two brackets put BOTH in the bottom-right and the
# Kruskal-Wallis line was painted straight over "6 row(s) skip...". Neither
# the Info transcript nor the ledger showed anything wrong: both boxes had the
# right contents and the right counts, and the figure was unreadable.
#
# THIS PROBE CALLS THE SHIPPED CODE. It did not until 11 August 2026, and the
# difference is the point of the rewrite.
#
# The old version TRANSCRIBED the post-dispatch block by hand. Two things went
# wrong with that, and both are the same mistake:
#
#   1. It passed `emlDrawViolinPlot.axisYMin` where the form passed
#      `valueMin`. So it exercised a CORRECTED copy of the block. The shipped
#      one was handing @emlDrawAnnotationBlock the dialog's (0, 0) whenever
#      there were no brackets, and putting the statistics box off the figure
#      — and this probe went on passing throughout. See §2b of
#      audit/GRAPHING_PUSH_REMAINING.md.
#   2. It printed `omnibus=bottom-right` as a LITERAL STRING it had typed
#      itself, next to a disclosure corner it read from the code. So v29's
#      "the two corners differ" check was comparing a real value against a
#      constant this file asserted. It could not have failed for the reason
#      it exists.
#
# Both are fixed by calling @emlGraphsPostDispatchAnnotations — the actual
# procedure, out of the actual form file — and READING `omnibusCorner$` back
# out of it. The form file is includable here because it is a library: its
# top-level code is array initialisation only, there is no `form:` or
# `beginPause:` at top level, and @emlGraphsWorkflow is never called from
# within it.
#
# WHAT IS FIXTURE AND WHAT IS UNDER TEST. The globals set below are the
# OUTPUTS of the form's earlier stages — the resolved y-range, the bracket
# and omnibus state @emlBridgeGroupComparison produced, the canvas geometry.
# Supplying those is fixture. Everything from @emlGraphsPostDispatchAnnotations
# onward is the shipped code, unmodified. The pre-dispatch bracket-headroom
# step is a different stage and is not under test here; valueMin/valueMax are
# therefore set to the drawn extent rather than the drawn extent plus
# headroom.
#
#   <EML_OUT>/formpath_brackets.png     (omnibus expected bottom-right)
#   <EML_OUT>/formpath_nobrackets.png   (omnibus expected top-right)
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------
; Relative, and it resolves against the TOP-LEVEL script's folder -- this
; file's own folder, which is two levels below the repository root, the same
; depth as harness/stress_cases/. So the prelude's own "../../plugin/..."
; lines resolve correctly too. Absolute paths here meant a copy of the repo
; silently tested the ORIGINAL tree. See harness/_env.sh.
include ../stress_cases/_prelude.praat
; The form, for @emlGraphsPostDispatchAnnotations. The prelude deliberately
; leaves it out -- it is the interactive wrapper -- and that exclusion is
; right for the stress cases, which have no business loading the UI. Here it
; IS the thing under test.
include ../../plugin/graphs/eml-graphs-form.praat

probeOut$ = environment$ ("EML_OUT")
if probeOut$ = ""
    probeOut$ = "."
endif

emlSubtitle$ = "SENTINEL-SUBTITLE"

procedure buildTable
    .id = Create Table with column names: "fp", 20, "grp v"
    for .i to 20
        .g = (.i - 1) mod 4 + 1
        Set string value: .i, "grp", "G" + string$ (.g)
        if .i = 3 or .i = 7 or .i = 11 or .i = 14 or .i = 17 or .i = 20
            Set string value: .i, "v", ""
        else
            Set numeric value: .i, "v", 10 + 2 * ((.i - 1) div 4) + .g
        endif
    endfor
    tblId = .id
endproc

# The form-scope globals @emlGraphsPostDispatchAnnotations reads and does not
# set for itself. Canvas geometry is only consulted on the matrix-panel
# branch, which is off here (matrixPanelHeight = 0), but it is set anyway so
# an accidental read is a wrong number rather than "Unknown variable".
procedure formScope
    annotate = 1
    graph_type = 7
    annotMatrixN = 0
    matrixPanelHeight = 0
    matrixGap = 0
    figure_width = 6
    figure_height = 4
    totalCanvasHeight = 4
    colorMode$ = "color"
endproc

# ---------------------------------------------------------------------------
# @drawLikeTheForm — the fixture, built with the form's own procedures
# ---------------------------------------------------------------------------
# The stage before the one under test resolves the y-range and buys headroom
# for the brackets. Skipping it drew the brackets across the title, which
# would read as a defect in the artefact rather than as a gap in the fixture,
# so it is reproduced here — by CALLING @emlComputeNiceStep,
# @emlComputeAxisRange and @emlComputeAnnotationHeadroom, which is what the
# form calls, rather than by copying their arithmetic. Copying arithmetic is
# the mistake this whole file is a rewrite of.
#
# Two draws, and the first is thrown away, for the reason
# @emlGraphsDrawWithLegendRoom gives at length: the theme constants those
# three procedures need (targetTicksY, annotSize) do not exist until a figure
# has been drawn once.
#
# dataYMax_forAnnotation is the VISIBLE data maximum, not the axis ceiling —
# brackets start just above the tallest violin, which is what the form means
# by the name.
procedure drawLikeTheForm: .title$
    Erase all
    @emlDrawViolinPlot: tblId, .title$, "Group", "Value", 6, 4,
    ... "color", 1, "grp", "v", 0, 0
    ; @emlGraphsColumnExtent, not `Get maximum:`, and the fixture is why the
    ; distinction was found: this table blanks six of its twenty values on
    ; purpose, and `Get maximum:` ABORTS on a column with a blank cell rather
    ; than returning undefined. The form called it here until 11 Aug 2026.
    @emlGraphsColumnExtent: tblId, "v"
    .visMax = emlGraphsColumnExtent.max
    .visMin = emlGraphsColumnExtent.min
    @emlComputeNiceStep: .visMax - .visMin, emlSetAdaptiveTheme.targetTicksY
    @emlComputeAxisRange: .visMin, .visMax, emlComputeNiceStep.step, 0
    valueMin = emlComputeAxisRange.axisMin
    valueMax = emlComputeAxisRange.axisMax
    if annotBracketN > 0
        @emlComputeAnnotationHeadroom: valueMax - valueMin,
        ... emlSetAdaptiveTheme.annotSize, 0, ""
        valueMax = valueMax + emlComputeAnnotationHeadroom.headroom
    endif
    dataYMax_forAnnotation = .visMax
    Erase all
    @emlDrawViolinPlot: tblId, .title$, "Group", "Value", 6, 4,
    ... "color", 1, "grp", "v", valueMin, valueMax
endproc

# ---- with brackets: the form should send its omnibus to bottom-right ------
@emlClearAnnotations
@buildTable
@formScope
annotBracketN = 2
annotBracketI[1] = 1
annotBracketJ[1] = 2
annotBracketTier[1] = 1
annotBracketLabel$[1] = "*"
annotBracketI[2] = 3
annotBracketJ[2] = 4
annotBracketTier[2] = 1
annotBracketLabel$[2] = "**"
annotTextN = 1
annotTextX[1] = 0
annotTextY[1] = 0
annotTextLabel$[1] = "Kruskal-Wallis: H(3) = 7.81, p = .050"
annotTextAnchor$[1] = "right"
@drawLikeTheForm: "Form path, brackets"
appendInfoLine: "FORMPATH brackets: annotBlockN after draw = ", annotBlockN
# emlPlaceElements.corner1$ is left holding the corner @emlDiscloseEnd chose:
# it is the only caller of @emlPlaceElements inside @emlDrawViolinPlot. Read
# BEFORE the post-dispatch stage runs, because that stage calls
# @emlDrawAnnotationBlock, which calls @emlPlaceElements again.
discCorner$ = emlPlaceElements.corner1$
# --- the shipped post-dispatch stage, called, not copied ---
@emlGraphsPostDispatchAnnotations
appendInfoLine: "FORMCORNER brackets disclosure=", discCorner$,
... " omnibus=", omnibusCorner$
select all
n = numberOfSelected ()
if n > 0
    Remove
endif
@emlAssertFullViewport
Save as 300-dpi PNG file: probeOut$ + "/formpath_brackets.png"

# ---- no brackets: the form should send its omnibus to top-right -----------
@emlClearAnnotations
@buildTable
@formScope
annotBracketN = 0
annotTextN = 1
annotTextX[1] = 0
annotTextY[1] = 0
annotTextLabel$[1] = "Kruskal-Wallis: H(3) = 7.81, p = .050"
annotTextAnchor$[1] = "right"
@drawLikeTheForm: "Form path, no brackets"
appendInfoLine: "FORMPATH nobrackets: annotBlockN after draw = ", annotBlockN
discCorner$ = emlPlaceElements.corner1$
@emlGraphsPostDispatchAnnotations
appendInfoLine: "FORMCORNER nobrackets disclosure=", discCorner$,
... " omnibus=", omnibusCorner$
select all
n = numberOfSelected ()
if n > 0
    Remove
endif
@emlAssertFullViewport
Save as 300-dpi PNG file: probeOut$ + "/formpath_nobrackets.png"
