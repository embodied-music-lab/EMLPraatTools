# ---------------------------------------------------------------------------
# PLACEMENT x MATRIX. Grouped violin with a 4-category comparison matrix,
# rendered at every legend placement, through the FORM's own layout path.
#
# Types 11 and 12 are the only two that carry BOTH a legend and a comparison
# matrix panel, so they are the only two where the two pieces of furniture can
# argue. This case transcribes the form's pre-dispatch matrix measurement, its
# dispatch, and its post-dispatch @emlDrawMatrixPanel call, term for term, so
# what comes out is what the wrapper draws and not a demo that resembles it.
#
# Run: praat --run placement_matrix_case.praat <placement 1..5>
#
# ---------------------------------------------------------------------------
# THE MATRIX PANEL ONLY EVER MATCHES THE WIDTH OF THE GRAPH ITSELF. Author
# ruling, 9 Aug 2026, and the reason this file carries a correction rather
# than a finding.
#
# The commit that first added these renders (2b93fe9) called placement 2 an
# open defect on the strength of one measurement: on out_p2.png the canvas
# centre is 1096 px and the matrix ink is centred at 862 px, so the panel
# "sits 234 px left of centre". That measured the panel against the CANVAS,
# which is not the reference. Measured against the graph, which is:
#
#     plot inner box   251..1548 px   in BOTH placement 1 and placement 2
#     matrix ink       322..1401 px   in BOTH placement 1 and placement 2
#
# Identical. Widening the canvas for a right-hand legend does not move the
# panel relative to the plot by a single pixel, because
# eml-graphs-form.praat:7376 hands @emlDrawMatrixPanel `0, figure_width` —
# the graph's own width — and the legend band is added outside it. That is
# the specified behaviour, not an oversight, and it is why the panel must
# NOT be re-centred on the widened midpoint or stretched to span it: either
# change would break the alignment between the matrix columns and the
# categories they describe, which is the whole point of putting the panel
# under the plot.
#
# The residual 38 px between the plot-box centre (899.5) and the matrix ink
# centre (861.5) is internal to the panel — the row-label column reaches
# further left than the last cell column reaches right — and is present at
# every placement including 1. It is not a placement effect.
# ---------------------------------------------------------------------------
include _prelude.praat

form: "Placement"
    word: "Placement", "1"
endform
placement = number (placement$)

Erase all
@emlInitializeDrawingDefaults

figure_width = 6
figure_height = 4.5

; ---- data: 4 categories x 3 sub-groups -------------------------------------
Create Table with column names: "gv", 0, "cat sub val"
catName$[1] = "Preprofessional"
catName$[2] = "Professional"
catName$[3] = "Continuing ed"
catName$[4] = "Faculty"
subName$[1] = "Pre-training"
subName$[2] = "Mid-training"
subName$[3] = "Post-training"
row = 0
for c from 1 to 4
    for s from 1 to 3
        for k from 1 to 18
            row = row + 1
            Append row
            Set string value: row, "cat", catName$[c]
            Set string value: row, "sub", subName$[s]
            Set numeric value: row, "val",
            ... 180 + c * 12 + s * 7 + randomGauss (0, 9)
        endfor
    endfor
endfor
objectId = selected ("Table")

; ---- annotations: omnibus block + 4x4 comparison matrix --------------------
@emlClearAnnotations
annotBlockN = 1
annotBlockLabel$[1] = "Two-way ANOVA: F(3, 204) = 18.44, p < .001"
annotBlockDraw$[1] = "Two-way ANOVA: %F(3, 204) = 18.44, %p < .001"

annotMatrixN = 4
for i from 1 to 4
    annotMatrixLabel$[i] = catName$[i]
endfor
annotMatrixOmnibus$ = "Tukey HSD, family-wise alpha = .05"
annotMatrixPosthoc$ = "Tukey HSD"
annotMatrixEffectLabel$ = "|d|"
for i from 1 to 4
    for j from 1 to 4
        if i = j
            annotMatrixCell'i'_'j'$ = "—"
            annotMatrixSig'i'_'j' = 0
            annotMatrixD'i'_'j' = 0
        else
            .gap = abs (i - j)
            if .gap >= 2
                annotMatrixCell'i'_'j'$ = "<.001"
                annotMatrixSig'i'_'j' = 1
                annotMatrixD'i'_'j' = 0.9 + 0.2 * .gap
            elsif .gap = 1
                annotMatrixCell'i'_'j'$ = ".021"
                annotMatrixSig'i'_'j' = 1
                annotMatrixD'i'_'j' = 0.55
            endif
        endif
    endfor
endfor

; ---- theme, palette, placement --------------------------------------------
@emlSetAdaptiveTheme: figure_width, figure_height
@emlSetColorPalette: "color"
@emlInitAlphaSprites
emlLegendPlacement = placement

; ---- FORM PRE-DISPATCH: categorical label measurement ----------------------
graphOverhangInches = 0
@emlMeasureCategoricalLabels: objectId, "cat", figure_width, figure_height
graphOverhangInches = emlFitCategoricalLabels.overhangInches

; ---- FORM PRE-DISPATCH: matrix panel measurement ---------------------------
matrixPanelHeight = 0
mFontInch = emlSetAdaptiveTheme.matrixSize / 72
mEstHeight = mFontInch * (6 + annotMatrixN * 2.5)
if mEstHeight < 1.0
    mEstHeight = 1.0
endif
@emlMeasureMatrixLayout: 0, figure_width, figure_height,
... figure_height + mEstHeight, emlSetAdaptiveTheme.matrixSize
if emlMatrixLayout_suppressed = 0
    matrixPanelHeight = emlMatrixLayout_yMax
    if matrixPanelHeight < 1.0
        matrixPanelHeight = 1.0
    endif
endif
if matrixPanelHeight > 0
    matrixGap = emlSetAdaptiveTheme.bodyInch * 1.0 + graphOverhangInches
else
    matrixGap = 0
endif
totalCanvasHeight = figure_height + matrixGap + matrixPanelHeight

; ---- DISPATCH -------------------------------------------------------------
selectObject: objectId
@emlDrawGroupedViolin: objectId, "Fundamental frequency by cohort",
... "Cohort", "f0 (Hz)", figure_width, figure_height, "color", 1,
... "cat", "sub", "val", 0, 0

; ---- FORM POST-DISPATCH: omnibus block + matrix panel ----------------------
@emlDrawAnnotationBlock: "top-right",
... emlDrawGroupedViolin.axisXMin, emlDrawGroupedViolin.axisXMax,
... emlDrawGroupedViolin.axisYMin, emlDrawGroupedViolin.axisYMax,
... emlSetAdaptiveTheme.annotSize

if annotMatrixN > 0 and matrixPanelHeight > 0
    @emlDrawMatrixPanel: 0, figure_width, figure_height + matrixGap,
    ... totalCanvasHeight, emlSetAdaptiveTheme.matrixSize, "color"
endif

@emlAssertFullViewport
Save as 300-dpi PNG file: "out_p'placement'.png"

; The parked legend is a SECOND FILE, exactly as the form writes it.
if emlLegendSepActive = 1
    Select outer viewport: emlLegendSepX0, emlLegendSepX1,
    ... emlLegendSepY0, emlLegendSepY1
    Save as 300-dpi PNG file: "out_p'placement'_legend.png"
    @emlAssertFullViewport
endif

appendInfoLine: "PLACEMENT=", placement
appendInfoLine: "SEPACTIVE=", emlLegendSepActive
appendInfoLine: "MATRIXPANEL=0..", figure_width, " top=",
... figure_height + matrixGap, " bottom=", totalCanvasHeight
