# ---------------------------------------------------------------------------
# Does the disclosure block collide with the graphs form's own omnibus block?
#
# eml-graphs-form.praat renders TWO floating boxes on an annotated
# categorical figure: the one @emlDiscloseEnd draws inside the draw procedure,
# and the one its own POST-DISPATCH block draws afterwards from annotBlockN
# (bracket comparisons + omnibus line). The form's box goes to "bottom-right"
# when brackets are present and "top-right" when they are not, and
# @emlPlaceElements picks the disclosure's corner independently.
#
# This reproduces the form's sequence around a real @emlDrawViolinPlot call:
# brackets, omnibus line, both corners. Look at the PNGs.
#   <EML_OUT>/formpath_brackets.png     (omnibus bottom-right)
#   <EML_OUT>/formpath_nobrackets.png   (omnibus top-right)
# ---------------------------------------------------------------------------
; Relative, and it resolves against the TOP-LEVEL script's folder -- this
; file's own folder, which is two levels below the repository root, the same
; depth as harness/stress_cases/. So the prelude's own "../../plugin/..."
; lines resolve correctly too. Absolute paths here meant a copy of the repo
; silently tested the ORIGINAL tree. See harness/_env.sh.
include ../stress_cases/_prelude.praat

; Where this probe writes. EML_OUT is set by harness/disclosure/run.sh; the
; fallback is the current folder, never another tree.
probeOut$ = environment$ ("EML_OUT")
if probeOut$ = ""
    probeOut$ = "."
endif

annotate = 1
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

# ---- with brackets: the form sends its omnibus to bottom-right ------------
@emlClearAnnotations
@buildTable
annotBracketN = 2
annotBracketI[1] = 1
annotBracketJ[1] = 2
annotBracketTier[1] = 1
annotBracketLabel$[1] = "*"
annotBracketI[2] = 3
annotBracketJ[2] = 4
annotBracketTier[2] = 1
annotBracketLabel$[2] = "**"
Erase all
@emlDrawViolinPlot: tblId, "Form path, brackets", "Group", "Value", 6, 4,
... "color", 1, "grp", "v", 0, 0
appendInfoLine: "FORMPATH brackets: annotBlockN after draw = ", annotBlockN
# emlPlaceElements.corner1$ is left holding the corner @emlDiscloseEnd chose:
# it is the only caller of @emlPlaceElements inside @emlDrawViolinPlot.
appendInfoLine: "FORMCORNER brackets disclosure=", emlPlaceElements.corner1$,
... " omnibus=bottom-right"
# --- the form's POST-DISPATCH block, transcribed ---
annotBlockN = annotBlockN + 1
annotBlockLabel$[annotBlockN] = "Kruskal-Wallis: H(3) = 7.81, p = .050"
annotBlockDraw$[annotBlockN] = "Kruskal-Wallis: %H(3) = 7.81, %p = .050"
@emlDrawAnnotations: emlDrawViolinPlot.axisXMin, emlDrawViolinPlot.axisXMax,
... emlDrawViolinPlot.axisYMax, emlDrawViolinPlot.axisYMax
... - emlDrawViolinPlot.axisYMin, "{0.3, 0.3, 0.3}",
... emlSetAdaptiveTheme.annotSize,
... emlDrawViolinPlot.axisYMin, emlDrawViolinPlot.axisYMax
@emlDrawAnnotationBlock: "bottom-right", emlDrawViolinPlot.axisXMin,
... emlDrawViolinPlot.axisXMax, emlDrawViolinPlot.axisYMin,
... emlDrawViolinPlot.axisYMax, emlSetAdaptiveTheme.annotSize
select all
n = numberOfSelected ()
if n > 0
    Remove
endif
@emlAssertFullViewport
Save as 300-dpi PNG file: probeOut$ + "/formpath_brackets.png"

# ---- no brackets: the form sends its omnibus to top-right -----------------
@emlClearAnnotations
@buildTable
Erase all
@emlDrawViolinPlot: tblId, "Form path, no brackets", "Group", "Value", 6, 4,
... "color", 1, "grp", "v", 0, 0
appendInfoLine: "FORMPATH nobrackets: annotBlockN after draw = ", annotBlockN
appendInfoLine: "FORMCORNER nobrackets disclosure=", emlPlaceElements.corner1$,
... " omnibus=top-right"
annotBlockN = annotBlockN + 1
annotBlockLabel$[annotBlockN] = "Kruskal-Wallis: H(3) = 7.81, p = .050"
annotBlockDraw$[annotBlockN] = "Kruskal-Wallis: %H(3) = 7.81, %p = .050"
@emlDrawAnnotationBlock: "top-right", emlDrawViolinPlot.axisXMin,
... emlDrawViolinPlot.axisXMax, emlDrawViolinPlot.axisYMin,
... emlDrawViolinPlot.axisYMax, emlSetAdaptiveTheme.annotSize
select all
n = numberOfSelected ()
if n > 0
    Remove
endif
@emlAssertFullViewport
Save as 300-dpi PNG file: probeOut$ + "/formpath_nobrackets.png"
