# ---------------------------------------------------------------------------
# Does the form's post-dispatch annotation block ever get a DEGENERATE
# y-range, and does it matter on the page?
#
# THE CLAIM THIS TESTS, AND WHY IT NEEDED TESTING RATHER THAN READING.
# On 11 Aug 2026 the audit recorded (as §2b) that types 6, 7 and 9 seed
# `annotYMin`/`annotYMax` from `valueMin`/`valueMax` -- the range the USER
# typed -- with no override from the draw procedure, so an auto-ranged figure
# would annotate against (0, 0). That was written from the POST-dispatch
# block alone, and it was wrong: the form has a PRE-dispatch block, gated on
#
#     (graph_type = 6 or 7 or 9) and annotate = 1 and annotBracketN > 0
#
# which resolves valueMin/valueMax from the visible data extent and adds
# bracket headroom BEFORE dispatch. It then passes those resolved values into
# the draw procedure as .vMin/.vMax, so the drawn axis IS valueMin/valueMax
# and the two spellings agree exactly. The bracket path is correct.
#
# WHAT SURVIVES THE CORRECTION is narrower and is what this probe measures.
# The pre-dispatch block requires `annotBracketN > 0`. The post-dispatch
# block runs on `annotBracketN > 0 OR (annotTextN > 0 and annotMatrixN = 0)`.
# So with an omnibus line and NO brackets, on an auto-ranged 6/7/9 figure,
# nothing resolves valueMin/valueMax and @emlDrawAnnotationBlock is handed
#
#     valueMin = 0, valueMax = 0
#
# while the axes were drawn somewhere else entirely. @emlDrawAnnotations is
# NOT reached -- it is guarded by `if annotBracketN > 0` -- so the brackets
# are not the exposure; the omnibus box is.
#
# Two panels, same data, same everything but the two numbers:
#   annot_yrange_asis.png   the form's arithmetic, transcribed literally
#   annot_yrange_fixed.png  the same call with the drawn extent instead
#
# If they are byte-identical there is nothing here. If they differ, the
# difference IS the defect, and it is visible rather than argued.
#
# Run: praat --run probe_annot_yrange.praat     (EML_OUT = output folder)
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------
; Relative, and it resolves against the TOP-LEVEL script's folder -- this
; file's own folder. See harness/_env.sh for why absolute paths are banned.
include ../stress_cases/_prelude.praat

probeOut$ = environment$ ("EML_OUT")
if probeOut$ = ""
    probeOut$ = "."
endif

emlSubtitle$ = "SENTINEL-SUBTITLE"

procedure buildTable
    .id = Create Table with column names: "ay", 20, "grp v"
    for .i to 20
        .g = (.i - 1) mod 4 + 1
        Set string value: .i, "grp", "G" + string$ (.g)
        ; Deliberately far from zero. If the omnibus box is placed against a
        ; (0, 0) y-range while the axis sits near 200, the box lands outside
        ; the frame rather than merely a little low, and the two panels
        ; cannot coincide by luck.
        Set numeric value: .i, "v", 200 + 2 * ((.i - 1) div 4) + .g
    endfor
    tblId = .id
endproc

# The form's state for this path: an omnibus line, no brackets, no matrix.
procedure setUpAnnotations
    @emlClearAnnotations
    annotBracketN = 0
    annotMatrixN = 0
    annotBlockN = 0
    annotBlockN = annotBlockN + 1
    annotBlockLabel$[annotBlockN] = "Kruskal-Wallis: H(3) = 7.81, p = .050"
    annotBlockDraw$[annotBlockN] = "Kruskal-Wallis: %H(3) = 7.81, %p = .050"
endproc

# ---- panel A: the form's arithmetic, transcribed ---------------------------
# valueMin/valueMax are the DIALOG's values and stay (0, 0) on auto, because
# the pre-dispatch resolver is gated on annotBracketN > 0.
@buildTable
@setUpAnnotations
valueMin = 0
valueMax = 0
Erase all
@emlDrawViolinPlot: tblId, "As-is", "Group", "Value", 6, 4,
... "color", 1, "grp", "v", valueMin, valueMax
annotXMin = emlDrawViolinPlot.axisXMin
annotXMax = emlDrawViolinPlot.axisXMax
@emlDrawAnnotationBlock: "top-right", annotXMin, annotXMax,
... valueMin, valueMax, emlSetAdaptiveTheme.annotSize
appendInfoLine: "ASIS  axis=", emlDrawViolinPlot.axisYMin, " ",
... emlDrawViolinPlot.axisYMax, "  block got=", valueMin, " ", valueMax
@emlAssertFullViewport
Save as 300-dpi PNG file: probeOut$ + "/annot_yrange_asis.png"
selectObject: tblId
Remove

# ---- panel B: the same call with the DRAWN extent ---------------------------
@buildTable
@setUpAnnotations
valueMin = 0
valueMax = 0
Erase all
@emlDrawViolinPlot: tblId, "As-is", "Group", "Value", 6, 4,
... "color", 1, "grp", "v", valueMin, valueMax
annotXMin = emlDrawViolinPlot.axisXMin
annotXMax = emlDrawViolinPlot.axisXMax
@emlDrawAnnotationBlock: "top-right", annotXMin, annotXMax,
... emlDrawViolinPlot.axisYMin, emlDrawViolinPlot.axisYMax,
... emlSetAdaptiveTheme.annotSize
appendInfoLine: "FIXED axis=", emlDrawViolinPlot.axisYMin, " ",
... emlDrawViolinPlot.axisYMax, "  block got=",
... emlDrawViolinPlot.axisYMin, " ", emlDrawViolinPlot.axisYMax
@emlAssertFullViewport
Save as 300-dpi PNG file: probeOut$ + "/annot_yrange_fixed.png"
selectObject: tblId
Remove
