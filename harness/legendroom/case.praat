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

; ADVANCED MODE, AND THE PROBE IS WRONG WITHOUT IT -- 16 August 2026.
;
; @emlGraphsDispatchDraw carries the D8 beginner-mode override, added in
; 7f62e75 (15 Aug 2026):
;
;     emlLegendPlacement = config_legendPlacement
;     if config_showAdvanced = 0
;         emlLegendPlacement = 1
;     endif
;
; and the same commit repointed @emlLegendHeadroomAfterDraw's first argument
; from config_legendPlacement to emlLegendPlacement, correctly, so that the
; room asked for is room for the legend that is actually on the page.
;
; @emlLoadConfig defaults config_showAdvanced to 0. This probe never set it,
; so from 7f62e75 onward the "scatter_right" case set config_legendPlacement
; to 2, had it silently rewritten to 1 before the draw, and measured a second
; inside-plot figure while still PRINTING placement=2. Driven 16 Aug 2026: the
; figure that case produced was byte-identical to the scatter_inside figure.
; The probe was reporting a placement the plugin had already discarded, which
; is the same class of defect the plugin fixed by reading emlLegendPlacement
; here -- committed one file over and not in this one.
;
; The beginner page has no "Legend placement" field, so a placement other than
; 1 is only reachable from the advanced page. A probe that wants to drive one
; must say it is on that page. The resolved placement is now REPORTED as well
; (see `resolved=` below) so the two can never again disagree in silence.
config_showAdvanced = 1

procedure probe: .label$, .type, .placement
    ; EVERY CASE STARTS FROM AUTO, exactly as a real press does.
    ; @emlGraphsWorkflow zeroes valueMin/valueMax at the top of every press
    ; ("Initialize range variables (0/0 = auto per pair)") and each column
    ; page then assigns them from that press's own typed field. This probe
    ; calls @emlGraphsDrawWithLegendRoom directly, with no workflow and no
    ; dialog between cases, so without this reset it inherits whatever the
    ; PREVIOUS case's headroom pass wrote back into valueMin/valueMax -- and
    ; the loop does write them back, that is how the widened axis reaches the
    ; second pass.
    ;
    ; That carry-over was live until 16 Aug 2026 and it is what made one
    ; behaviour change look like four. When scatter_right began taking a
    ; second pass, its widened 203.4668 became gviolin's TYPED axis, gviolin's
    ; widened 273.9246 became spaghetti's, and the histogram -- whose x-axis
    ; is valueMin/valueMax -- rebinned at width 26.2749 instead of 16.2095,
    ; which moved its legend out of the bottom-right corner and gave it a
    ; second pass too. Four rows moved; one thing changed. Cases that cannot
    ; be read one at a time cannot be diagnosed one at a time.
    valueMin = 0
    valueMax = 0
    histFreqMax = 0
    graph_type = .type
    config_legendPlacement = .placement
    @emlClearAnnotations
    Erase all
    @emlGraphsDrawWithLegendRoom
    ; `resolved` is emlLegendPlacement -- the placement the figure was drawn
    ; with, after the D8 override, not the one this case asked for. It is
    ; reported so the artefact carries the evidence that the case drove the
    ; placement it is named for. v42 checks the two agree.
    appendInfoLine: "ROOM ", .label$, " type=", .type,
    ... " placement=", .placement,
    ... " passes=", legendRoomPass,
    ... " axisMode=", legendRoomAxis,
    ... " baseMin=", fixed$ (legendRoomBaseMin, 4),
    ... " baseMax=", fixed$ (legendRoomBaseMax, 4),
    ... " resolved=", emlLegendPlacement
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
