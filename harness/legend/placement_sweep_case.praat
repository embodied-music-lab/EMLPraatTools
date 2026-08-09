# ---------------------------------------------------------------------------
# PLACEMENT SWEEP over the FOUR NON-CATEGORICAL legend types.
#
# harness/legend/placement_matrix_case.praat covers 11 and 12, the two types
# whose x axis is a category and which also carry a comparison matrix. This
# file covers the other four types that offer a Legend placement menu:
#
#     5   Line Chart (+/-CI)   @emlDrawTimeSeriesCI
#     8   Scatter Plot         @emlDrawScatterPlot
#    10   Histogram            @emlDrawHistogram   (overlay, grouped)
#    13   Spaghetti Plot       @emlDrawSpaghettiPlot
#
# None of them has a matrix panel, so the question here is narrower and
# sharper: does the PLOT RECTANGLE stay put across all five placements, does
# the canvas grow on the axis it is supposed to grow on, and does placement 4
# park a legend the save path can actually find.
#
# Run: praat --run placement_sweep_case.praat <type> <placement>
# ---------------------------------------------------------------------------
include _prelude.praat

form: "Sweep"
    word: "Gtype", "8"
    word: "Placement", "1"
endform
gtype = number (gtype$)
placement = number (placement$)

Erase all
@emlInitDrawingDefaults

; Deterministic noise. randomGauss would give every placement a different
; data set, and the whole point of this sweep is that only the FURNITURE
; moves. LCG, folded to roughly +/-1, scaled at the use site.
rngState = 20260809
procedure rnd
    rngState = (1103515245 * rngState + 12345) mod 2147483648
    .v = rngState / 2147483648
    .g = (.v - 0.5) * 3.4
endproc

figure_width = 6
figure_height = 4.5

seriesName$[1] = "Pre-training"
seriesName$[2] = "Mid-training"
seriesName$[3] = "Post-training"
seriesName$[4] = "Follow-up"

; ---- data ------------------------------------------------------------------
if gtype = 5 or gtype = 13
    ; long format: time/condition x group, several ids per cell
    Create Table with column names: "d", 0, "t val grp id"
    row = 0
    for g from 1 to 4
        for tt from 1 to 6
            for k from 1 to 8
                row = row + 1
                Append row
                Set numeric value: row, "t", tt
                @rnd
                Set numeric value: row, "val",
                ... 200 + g * 9 + tt * 3 + rnd.g * 7
                Set string value: row, "grp", seriesName$[g]
                Set numeric value: row, "id", (g - 1) * 8 + k
            endfor
        endfor
    endfor
elsif gtype = 8
    Create Table with column names: "d", 0, "x y grp"
    row = 0
    for g from 1 to 4
        for k from 1 to 60
            row = row + 1
            Append row
            @rnd
            .xv = (rngState / 2147483648) * 10
            Set numeric value: row, "x", .xv
            @rnd
            Set numeric value: row, "y",
            ... 200 + g * 10 + .xv * 2.5 + rnd.g * 8
            Set string value: row, "grp", seriesName$[g]
        endfor
    endfor
else
    Create Table with column names: "d", 0, "val grp"
    row = 0
    for g from 1 to 4
        for k from 1 to 90
            row = row + 1
            Append row
            @rnd
            Set numeric value: row, "val", 200 + g * 11 + rnd.g * 10
            Set string value: row, "grp", seriesName$[g]
        endfor
    endfor
endif
objectId = selected ("Table")

@emlClearAnnotations
@emlSetAdaptiveTheme: figure_width, figure_height
@emlSetColorPalette: "color"
@emlInitAlphaSprites
emlLegendPlacement = placement

selectObject: objectId
if gtype = 5
    @emlDrawTimeSeriesCI: objectId, "f0 over training", "Session", "f0 (Hz)",
    ... figure_width, figure_height, "color", 1, "t", "val", "grp", 0, 0, 0, 0
    ; 5 and 13 expose .xMin/.xMax/.yMin/.yMax; 8, 10, 11 and 12 expose
    ; .axisXMin/.axisXMax/.axisYMin/.axisYMax. See the note at the foot of
    ; this file -- the inconsistency is real and is not fixed here.
    axXMin = emlDrawTimeSeriesCI.xMin
    axXMax = emlDrawTimeSeriesCI.xMax
    axYMin = emlDrawTimeSeriesCI.yMin
    axYMax = emlDrawTimeSeriesCI.yMax
elsif gtype = 8
    @emlDrawScatterPlot: objectId, "f0 by intensity", "Intensity (dB)",
    ... "f0 (Hz)", figure_width, figure_height, "color", 1,
    ... "x", "y", "grp", 0, 0, 0, 0, 0
    axXMin = emlDrawScatterPlot.axisXMin
    axXMax = emlDrawScatterPlot.axisXMax
    axYMin = emlDrawScatterPlot.axisYMin
    axYMax = emlDrawScatterPlot.axisYMax
elsif gtype = 10
    @emlDrawHistogram: objectId, "f0 distribution", "f0 (Hz)", "Count",
    ... figure_width, figure_height, "color", 1, "val", "grp", 0, 1, 0, 0, 0
    axXMin = emlDrawHistogram.axisXMin
    axXMax = emlDrawHistogram.axisXMax
    axYMin = emlDrawHistogram.axisYMin
    axYMax = emlDrawHistogram.axisYMax
else
    @emlDrawSpaghettiPlot: objectId, "Individual trajectories", "Session",
    ... "f0 (Hz)", figure_width, figure_height, "color", 1,
    ... "t", "val", "id", "grp", 1, 0, 0
    axXMin = emlDrawSpaghettiPlot.xMin
    axXMax = emlDrawSpaghettiPlot.xMax
    axYMin = emlDrawSpaghettiPlot.yMin
    axYMax = emlDrawSpaghettiPlot.yMax
endif

@emlAssertFullViewport
Save as 300-dpi PNG file: "sw_t'gtype'_p'placement'.png"

if emlLegendSepActive = 1
    Select outer viewport: emlLegendSepX0, emlLegendSepX1,
    ... emlLegendSepY0, emlLegendSepY1
    Save as 300-dpi PNG file: "sw_t'gtype'_p'placement'_legend.png"
    @emlAssertFullViewport
endif

appendInfoLine: "TYPE=", gtype, " PLACEMENT=", placement,
... " SEPACTIVE=", emlLegendSepActive, " LEGENDN=", legendN
appendInfoLine: "AXES=", axXMin, ",", axXMax, ",", axYMin, ",", axYMax

; ---------------------------------------------------------------------------
; FINDING, recorded here because it is what this sweep tripped over first.
; The six types that offer a Legend placement menu do NOT expose their
; resolved axes under one name:
;
;     8, 10, 11, 12   .axisXMin / .axisXMax / .axisYMin / .axisYMax
;     5, 13           .xMin / .xMax / .yMin / .yMax
;
; Every caller outside the form has to know which convention its graph type
; follows, and picking wrong is "Unknown variable:" at run time rather than
; at parse time. Not fixed here -- fixing it means touching the annotation
; bridge and the form's post-dispatch block, which is graphing-push work.
; ---------------------------------------------------------------------------
