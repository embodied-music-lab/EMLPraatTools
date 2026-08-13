# ---------------------------------------------------------------------------
# THE FORM'S TWO-PASS HEADROOM LOOP, DRIVEN.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# @emlGraphsDrawWithLegendRoom draws the figure, asks
# @emlLegendHeadroomAfterDraw whether the legend needs y-axis room, and if so
# THROWS THE FIRST PASS AWAY and draws again on the widened axis. It was
# extracted to file scope with a comment saying it was done so that a probe
# could drive it. No probe ever did.
#
# harness/legend covers the headroom BEHAVIOUR by reimplementing the two-pass
# in its own fixture — room=0 and room=1 arms — which is a statement about the
# arithmetic, not about this procedure. Nothing had executed this loop, its
# pass counter, its per-type axis read-back, or @emlGraphsDispatchDraw.
#
# WHY IT IS DRIVABLE AT ALL: @emlGraphsDispatchDraw is a flat dispatch on
# graph_type where every argument is a form global. A probe that sets those
# globals reaches it without a dialog.
#
# FOUR TYPES, CHOSEN FOR THE TWO AXIS MODES. legendRoomAxis is 1 for the
# value-axis types and 2 for the histogram, whose y-axis is FREQUENCY with a
# hard floor at 0 — it can be given room above and none below, and a legend
# that lands in a bottom corner is reported rather than silently unserved.
# Driving only axis-mode 1 would leave that branch untouched.
#
# Output: one ROOM line per case, read by run.sh.
# ---------------------------------------------------------------------------
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
include ../../plugin/graphs/eml-graphs-form.praat

@emlInitDrawingDefaults
@emlLoadConfig

# A fixture with enough groups that the legend is real rather than decorative.
Create Table with column names: "vt", 0, "t v g s"
rng = 20260813
procedure rnd
    rng = (1103515245 * rng + 12345) mod 2147483648
    .g = (rng / 2147483648 - 0.5) * 6
endproc
for i from 1 to 60
    Append row
    r = Get number of rows
    Set numeric value: r, "t", (i mod 10) + 1
    @rnd
    Set numeric value: r, "v", 100 + (i mod 5) * 12 + rnd.g
    Set string value: r, "g", "grp" + string$ ((i mod 5) + 1)
    Set numeric value: r, "s", ((i - 1) mod 6) + 1
endfor
objectId = selected ("Table")

# --- the form's variable set, as @emlGraphsWorkflow leaves it -------------
title$ = "Headroom probe"
x_axis_label$ = "x"
y_axis_label$ = "y"
figure_width = 6
figure_height = 4
colorMode$ = "color"
gridline_mode = 1
annotate = 0
timeColName$ = "t"
valueColName$ = "v"
groupColName$ = "g"
timeMin = 0
timeMax = 0
valueMin = 0
valueMax = 0
ciMode = 0
errorBarMode = 0
errorColName$ = ""
scatterXCol$ = "t"
scatterYCol$ = "v"
scatterGroupCol$ = "g"
scatterXMin = 0
scatterXMax = 0
histValueCol$ = "v"
histGroupCol$ = "g"
histBinCount = 0
histDisplayMode = 1
histFreqMax = 0
gvCatCol$ = "g"
gvSubCol$ = "g"
gvValueCol$ = "v"
gbCatCol$ = "g"
gbSubCol$ = "g"
gbValueCol$ = "v"
; THE SPAGHETTI PATH'S NAMES ARE sp*, NOT spaghetti* -- discovered by the
; dispatcher refusing them. Every argument @emlGraphsDispatchDraw passes is a
; form global, so a probe has to know each one's exact name; nothing before
; this had ever had to.
spCondCol$ = "t"
spValueCol$ = "v"
spSubjectCol$ = "s"
spGroupCol$ = "g"
spShowMean = 1

; THE PRE-DISPATCH STATE. @emlGraphsDispatchDraw selects an outer viewport
; of figure_width x totalCanvasHeight, which @emlGraphsWorkflow computes just
; before it from the comparison-matrix panel geometry. With no matrix panel
; the gap and the panel are both zero and the canvas is the figure. Setting
; them here is what a probe has to supply in place of that block -- and the
; fact that it has to is the measurement: this state is produced by a stage
; nothing outside the dialog had ever run.
matrixPanelHeight = 0
matrixGap = 0
totalCanvasHeight = figure_height
annotMatrixN = 0
annotBlockN = 0

procedure probe: .label$, .type, .placement
    graph_type = .type
    config_legendPlacement = .placement
    @emlClearAnnotations
    Erase all
    @emlGraphsDrawWithLegendRoom
    appendInfoLine: "ROOM ", .label$, " type=", .type,
    ... " placement=", .placement,
    ... " passes=", legendRoomPass,
    ... " axisMode=", legendRoomAxis,
    ... " baseMin=", fixed$ (legendRoomBaseMin, 4),
    ... " baseMax=", fixed$ (legendRoomBaseMax, 4)
endproc

; PLACEMENT 1 IS INSIDE THE PLOT, which is the only placement that can force
; a second pass -- a legend parked outside the frame needs no axis room. Both
; are driven so that "passes = 1" is a measured outcome for one and not the
; only outcome the loop can produce.
@probe: "scatter_inside", 8, 1
@probe: "scatter_right", 8, 2
@probe: "histogram_inside", 10, 1
@probe: "gviolin_inside", 11, 1
@probe: "spaghetti_inside", 13, 1

appendInfoLine: "LEGENDROOM DONE"
