# ============================================================================
# harness/dispatch/drive.praat — every figure type, through the form's dispatch
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE HOLE THIS FILLS. Thirteen figure types reach the page through
# @emlGraphsDispatchDraw, and until this harness existed no check drove any of
# them through it. Every other harness reaches a draw procedure directly, or
# drives one type. So a fault in the seam between the form and a draw
# procedure -- a variable the draw reads that only the form sets, a recorder
# prelude that assumes state the dispatch does not publish -- was reachable by
# a user and by nothing in the suite. One shipped: a scatter with recording
# off aborted on an uninitialised note variable, and it reached the author's
# machine before anything here saw it.
#
# ONE LEG PER PRAAT PROCESS, chosen by $EML_DP_LEG. That is not tidiness: an
# abort kills the process, so a loop over types inside one process would stop
# at the first failure and report nothing about the rest. run.sh runs each leg
# and treats a missing report row as the failure it is.
#
# WHAT A LEG ASSERTS. That the dispatch returns, that ink reached the page,
# and that the Info window carries no error. It does NOT assert what the
# figure looks like -- v100 and the per-type harnesses do that. The subject
# here is the seam, and the failure it catches is an abort, not a wrong pixel.
#
# RECORDED AND UNRECORDED ARE SEPARATE LEGS, because the fault that shipped
# lived in a recorder prelude and was invisible with recording on: the
# variable it read was initialised on the recorded path and not on the other.
#
# Env in:  EML_DP_LEG   "<type>" or "<type>_rec"
#          EML_DP_OUT   TSV to append to
#          EML_DP_PNG   where to save the figure
#          EML_DP_ROOT  repo root
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================

dpLeg$ = environment$ ("EML_DP_LEG")
dpOut$ = environment$ ("EML_DP_OUT")
dpPng$ = environment$ ("EML_DP_PNG")
dpRoot$ = environment$ ("EML_DP_ROOT")

; THE WHOLE LIBRARY, SPLICED. Praat's include is a parse-time splice, so the
; form file arrives as procedure definitions with no dialog run -- which is
; exactly what this harness wants: the dispatch, reached the way the form
; reaches it, without a human pressing keys.
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
include ../../plugin/graphs/eml-graphs-form.praat

procedure emit: .key$, .value$
    appendFileLine: dpOut$, dpLeg$, tab$, .key$, tab$, .value$
endproc

# ---------------------------------------------------------------------------
# THE FIXTURES. One table that satisfies every categorical and continuous
# type, and one Sound for the acoustic four. Deterministic: the generator is
# a fixed linear congruential sequence, because a figure that differs run to
# run cannot be compared to itself.
# ---------------------------------------------------------------------------
procedure dpTable
    Create Table with column names: "dp", 0, "grp sub val val2 t"
    .row = 0
    .rng = 20260820
    for .g from 1 to 3
        for .k from 1 to 12
            .rng = (1103515245 * .rng + 12345) mod 2147483648
            .u = .rng / 2147483648
            .row = .row + 1
            Append row
            Set string value: .row, "grp", "Cohort " + string$ (.g)
            Set string value: .row, "sub", "S" + string$ (.k)
            Set numeric value: .row, "val", 200 + .g * 12 + (.u - 0.5) * 30
            Set numeric value: .row, "val2", 50 + .g * 3 + (.u - 0.5) * 8
            Set numeric value: .row, "t", .k
        endfor
    endfor
    .id = selected ("Table")
endproc

procedure dpSound
    .id = Create Sound from formula: "dpsound", 1, 0, 1.2, 16000,
    ... "0.5 * sin (2 * pi * (180 + 20 * x) * x) * (1 - 0.3 * cos (2 * pi * x))"
endproc

# ---------------------------------------------------------------------------
# THE FORM'S INPUT STATE, at the moment its dispatch is called. Everything a
# dialog would have filled in. A leg overrides the type and nothing else, so a
# difference between legs is a difference in the dispatch and not in the seed.
# ---------------------------------------------------------------------------
procedure dpFormState: .type, .id
    ; THE DRAW LAYER'S DOCUMENTED PRECONDITION, FIRST. @emlInitializeDrawingDefaults
    ; seeds every global the draw procedures read. The shipped form does not
    ; call it -- it sets those globals itself, from its own dialogs -- so a
    ; harness that skips it aborts on the first one the form would have set
    ; and this one does not. That is not a hypothetical: the first run of this
    ; file died on an unguarded read of the subtitle. Seeding the defaults and
    ; then overriding with the form's values is what any non-form caller must
    ; do, and it is what the emitted recorder scripts do.
    @emlInitializeDrawingDefaults
    graph_type = .type
    objectId = .id
    title$ = "dispatch leg"
    x_axis_label$ = ""
    y_axis_label$ = ""
    figure_width = 6
    figure_height = 4
    colorMode$ = "color"
    gridline_mode = 1
    groupColName$ = "grp"
    valueColName$ = "val"
    timeColName$ = "t"
    errorColName$ = ""
    errorBarMode = 0
    tsShowCI = 0
    timeMin = 0
    timeMax = 0
    freqMin = 0
    freqMax = 0
    powerMin = 0
    powerMax = 0
    ampMin = 0
    ampMax = 0
    valueMin = 0
    valueMax = 0
    histFreqMax = 0
    matrixGap = 0
    matrixPanelHeight = 0
    totalCanvasHeight = figure_height
    config_legendPlacement = 1
    config_showAdvanced = 1
    config_groupSort = 1
    emlGroupSortAlphabetical = 0
    annotate = 0
    dataYMax_forAnnotation = 0

    # The per-type column choices the dialogs collect.
    scatterXCol$ = "val"
    scatterYCol$ = "val2"
    scatterGroupCol$ = ""
    histValueCol$ = "val"
    histGroupCol$ = ""
    histBinCount = 8
    histDisplayMode = 1
    gvCatCol$ = "grp"
    gvSubCol$ = "sub"
    gvValueCol$ = "val"
    gbCatCol$ = "grp"
    gbSubCol$ = "sub"
    gbValueCol$ = "val"
    spGroupCol$ = ""
    spSubjectCol$ = "sub"
    spTimeCol$ = "t"
    spValueCol$ = "val"
    barValueCol$ = "val"
    barGroupCol$ = "grp"
    f0YUnit = 1
    ltasShowCurve = 1
    ltasShowBars = 0
    ltasShowPoles = 0
    ltasShowSpeckles = 0
    scatterXMin = 0
    scatterXMax = 0
    spCondCol$ = "grp"
    spShowMean = 0

    @emlClearAnnotations
endproc

# ---------------------------------------------------------------------------
# THE LEG
# ---------------------------------------------------------------------------
dpType = 0
dpRec = 0
if index (dpLeg$, "_rec") > 0
    dpRec = 1
endif
dpBase$ = replace$ (dpLeg$, "_rec", "", 0)
dpType = number (dpBase$)

# Acoustic types take a Sound; everything else takes the table.
if dpType >= 1 and dpType <= 4
    ; THE FORM CONVERTS BEFORE IT DISPATCHES. A Pitch figure is drawn from a
    ; Pitch, a Spectrum figure from a Spectrum: the dialog offers a Sound and
    ; @emlGraphsConvertForDraw makes the object the draw procedure expects.
    ; Handing the raw Sound to the dispatch would test a state the form never
    ; produces, and the failure would be the harness's, not the plugin's.
    @dpSound
    dpObj = dpSound.id
    selectObject: dpObj
    if dpType = 1
        dpObj = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no",
        ... 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
    elsif dpType = 3
        dpObj = To Spectrum: "yes"
    elsif dpType = 4
        dpObj = To Ltas: 100
    endif
else
    @dpTable
    dpObj = dpTable.id
endif

if dpRec = 1
    @emlRecordInit
    emlRecordPluginRoot$ = dpRoot$ + "/plugin"
    @emlRecordBegin: ""
    emlRecordPluginRoot$ = dpRoot$ + "/plugin"
    @emlRecordLoadPhrases: dpRoot$ + "/plugin/data/eml-record-phrases.csv"
    @emlRecordHeader: "dispatch", 36, 5, "dispatch leg"
endif

@dpFormState: dpType, dpObj
@emit: "type", string$ (dpType)
@emit: "recording", string$ (dpRec)

@emlGraphsPublishAxisRequest
@emlGraphsDispatchDraw

# REACHED ONLY IF THE DISPATCH RETURNED. An abort inside it kills the process
# before this line, and run.sh reads the absence of these rows as the failure.
@emit: "returned", "1"
@emit: "drawnMinX", fixed$ (emlDrawnMinX, 4)
@emit: "drawnMaxX", fixed$ (emlDrawnMaxX, 4)
@emit: "drawnMinY", fixed$ (emlDrawnMinY, 4)
@emit: "drawnMaxY", fixed$ (emlDrawnMaxY, 4)

@emlAssertFullViewport
Save as 300-dpi PNG file: dpPng$
@emit: "png", string$ (fileReadable (dpPng$))

if dpRec = 1
    @emit: "steps", string$ (emlRecordN)
endif
