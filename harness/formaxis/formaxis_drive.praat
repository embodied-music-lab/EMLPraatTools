# ============================================================================
# harness/formaxis/formaxis_drive.praat — the graphs form's side of Ruling
# 10(b), and the Info window's side of the fixed$ ruling
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# ONE LEG PER PRAAT PROCESS, chosen by $EML_FA_LEG, for the reason
# harness/stress_graphs.sh gives: a Praat script error aborts the script, so a
# dozen legs in one process report one failure and hide eleven.
#
# WHY THE FORM IS INCLUDED AND ITS OWN PROCEDURES ARE CALLED, rather than the
# sequence being written out here. graphs/eml-graphs-form.praat is a LIBRARY:
# its top-level code is array initialisation only, there is no `form:` or
# `beginPause:` at top level, and @emlGraphsWorkflow is never called from
# inside it, so an `include` gets every procedure and no dialog. That is not a
# convenience, it is the whole design of this rig, and the bill for the
# alternative is already written down: harness/disclosure/probe_formpath.praat
# called itself a reproduction of "the form's sequence", transcribed the
# annotation block by hand, and passed the wrong variable in the
# transcription — so it tested a CORRECTED copy of the block and would have
# gone on passing however wrong the shipped one became. It did, while an
# omnibus box was being clipped off the figure entirely. Every stage below is
# the shipped procedure:
#
#     @emlGraphsPublishAxisRequest      the publication under test
#     @emlGraphsPreDispatchHeadroom     the bracket path that resolves auto
#     @emlGraphsDispatchDraw            the draw the recorder records
#     @emlGraphsDrawWithLegendRoom      the legend path that resolves auto
#     @emlGraphsPostDispatchAnnotations the brackets and the omnibus box
#
# What IS written out here is the form's INPUT state — the twenty-odd globals
# a dialog would have filled in. Those are values, not logic; getting one
# wrong produces a different figure, not a check that cannot fail.
#
# Env in:  EML_FA_LEG   leg name
#          EML_FA_OUT   TSV to append key/value pairs to
#          EML_FA_AUX   scratch folder for this leg (recordings)
#          EML_FA_PIC   PNG path for legs that save a figure
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
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

@emlInitDrawingDefaults

leg$ = environment$ ("EML_FA_LEG")
out$ = environment$ ("EML_FA_OUT")
aux$ = environment$ ("EML_FA_AUX")
pic$ = environment$ ("EML_FA_PIC")
faRoot$ = environment$ ("EML_FA_ROOT")

procedure emit: .key$, .value$
    if out$ <> ""
        appendFileLine: out$, .key$, tab$, .value$
    endif
    appendInfoLine: .key$, tab$, .value$
endproc

# @emitPub — the two globals under test, or the fact that they do not exist.
# BOTH OR NEITHER is the contract @emlRecordAxisRequest reads by, so the
# presence of each is reported separately and the validator asserts the pair.
procedure emitPub: .prefix$
    .hasMin = 0
    .hasMax = 0
    if variableExists ("emlGraphsAxisYReqMin")
        .hasMin = 1
    endif
    if variableExists ("emlGraphsAxisYReqMax")
        .hasMax = 1
    endif
    @emit: .prefix$ + "_pub_hasmin", string$ (.hasMin)
    @emit: .prefix$ + "_pub_hasmax", string$ (.hasMax)
    if .hasMin = 1
        @emit: .prefix$ + "_pub_min", fixed$ (emlGraphsAxisYReqMin, 4)
    endif
    if .hasMax = 1
        @emit: .prefix$ + "_pub_max", fixed$ (emlGraphsAxisYReqMax, 4)
    endif
endproc

# ---------------------------------------------------------------------------
# THE FIXTURE. Deterministic, because a byte-for-byte comparison cannot be
# built on randomGauss with no seed — see §14 of
# audit/GRAPHING_PUSH_REMAINING.md. Four cohorts around 200 Hz, well enough
# separated that @emlBridgeGroupComparison returns at least one bracket, which
# is the gate @emlGraphsPreDispatchHeadroom's resolver sits behind.
# ---------------------------------------------------------------------------
procedure faTable: .sep, .spread, .nPer
    Create Table with column names: "fa", 0, "grp val t sub"
    .row = 0
    .rng = 20260816
    for .g from 1 to 4
        for .k from 1 to .nPer
            .rng = (1103515245 * .rng + 12345) mod 2147483648
            .u = .rng / 2147483648
            .row = .row + 1
            Append row
            Set string value: .row, "grp", "Cohort " + string$ (.g)
            Set numeric value: .row, "val",
            ... 200 + .g * .sep + (.u - 0.5) * .spread
            Set numeric value: .row, "t", .k
            Set string value: .row, "sub", "S" + string$ (.k)
        endfor
    endfor
    .id = selected ("Table")
endproc

# ---------------------------------------------------------------------------
# THE FORM'S INPUT STATE. Everything a dialog would have filled in, at the
# point the range-validation block has just finished. Legs override the axis
# pair and the graph type; nothing else moves.
# ---------------------------------------------------------------------------
procedure faFormState: .type, .id
    graph_type = .type
    objectId = .id
    title$ = "f0 by cohort"
    x_axis_label$ = "Cohort"
    y_axis_label$ = "f0 (Hz)"
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
    @emlClearAnnotations
endproc

procedure faRecordBegin
    @emlRecordInit
    emlRecordPluginRoot$ = faRoot$ + "/plugin"
    @emlRecordBegin: aux$
    emlRecordPluginRoot$ = faRoot$ + "/plugin"
    @emlRecordLoadPhrases: faRoot$ + "/plugin/data/eml-record-phrases.csv"
    @emlRecordHeader: "fa", 100, 4, "form axis"
endproc

# ---------------------------------------------------------------------------
# LEG bracket_auto — THE REPRODUCTION, AND THE POINT OF THE WHOLE FILE.
#
# An annotated violin plot with the y-range left on AUTO. The bracket path
# resolves (0, 0) into the data's extent and then widens the ceiling for the
# brackets, so by the time the draw runs — and the draw is what the recorder
# records — every variable the draw procedure can see holds a number the user
# never typed. The published request must still read 0 and 0, and the emitted
# block must carry 0.0 with the resolution demoted to a note beside it.
# ---------------------------------------------------------------------------
if leg$ = "bracket_auto" or leg$ = "bracket_typed"
    @faTable: 6.0, 9.0, 14
    @faRecordBegin
    @faFormState: 7, faTable.id
    annotate = 1
    if leg$ = "bracket_typed"
        # THE VALUE CHECK. A "fix" that clamped every published number to a
        # zero of the right width would satisfy every width and format
        # assertion in this rig; this leg is what it cannot survive. The user
        # typed 150 and 400, the bracket path widens the ceiling past 400, and
        # the block must read 150.0 and 400.0 — not 0.0, and not the widened
        # ceiling either.
        valueMin = 150
        valueMax = 400
    endif
    @emit: leg$ + "_dialog_min", fixed$ (valueMin, 4)
    @emit: leg$ + "_dialog_max", fixed$ (valueMax, 4)

    # THE ORDER IS THE FORM'S OWN, and it is not incidental: the publication
    # is the first thing after range validation, the theme comes next because
    # the headroom reads its tick target and its annotation size, and the
    # bridge runs before the headroom because the headroom's resolver is gated
    # on the bracket count the bridge produces.
    @emlGraphsPublishAxisRequest
    @emitPub: leg$ + "_afterpublish"

    @emlSetAdaptiveTheme: figure_width, figure_height
    @emlBridgeGroupComparison: faTable.id, "val", "grp", 0.05, "stars", 0, 0,
    ... "auto", 2
    @emit: leg$ + "_brackets", string$ (annotBracketN)
    @emitPub: leg$ + "_afterbridge"

    @emlGraphsPreDispatchHeadroom
    @emit: leg$ + "_resolved_min", fixed$ (valueMin, 4)
    @emit: leg$ + "_resolved_max", fixed$ (valueMax, 4)
    @emitPub: leg$ + "_afterheadroom"

    @emlGraphsDispatchDraw
    @emlGraphsPostDispatchAnnotations
    @emitPub: leg$ + "_afterannot"
    @emit: leg$ + "_axis_min", fixed$ (emlDrawViolinPlot.axisYMin, 4)
    @emit: leg$ + "_axis_max", fixed$ (emlDrawViolinPlot.axisYMax, 4)

    if pic$ <> ""
        @emlAssertFullViewport
        Save as 300-dpi PNG file: pic$
    endif
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: leg$ + "_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# LEG legend_auto / legend_typed — THE OTHER CONVERSION SITE.
#
# A grouped violin carries a legend, and @emlGraphsDrawWithLegendRoom draws it
# once, measures the legend, writes the widened extent back into valueMin and
# valueMax and DRAWS AGAIN. The second draw is the recorded one. Same
# assertion as the bracket legs, on the other path, and the same typed control
# beside it.
# ---------------------------------------------------------------------------
elsif leg$ = "legend_auto" or leg$ = "legend_typed"
    @faTable: 6.0, 9.0, 14
    @faRecordBegin
    @faFormState: 11, faTable.id
    gvCatCol$ = "grp"
    gvSubCol$ = "sub"
    gvValueCol$ = "val"
    config_legendPlacement = 1
    if leg$ = "legend_typed"
        valueMin = 100
        valueMax = 300
    endif
    @emit: leg$ + "_dialog_min", fixed$ (valueMin, 4)
    @emit: leg$ + "_dialog_max", fixed$ (valueMax, 4)

    @emlGraphsPublishAxisRequest
    @emitPub: leg$ + "_afterpublish"

    @emlGraphsDrawWithLegendRoom
    @emit: leg$ + "_resolved_min", fixed$ (valueMin, 4)
    @emit: leg$ + "_resolved_max", fixed$ (valueMax, 4)
    @emit: leg$ + "_passes", string$ (legendRoomPass)
    @emitPub: leg$ + "_afterlegend"

    if pic$ <> ""
        @emlAssertFullViewport
        Save as 300-dpi PNG file: pic$
    endif
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: leg$ + "_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# LEG pairs — THE MAP FROM GRAPH TYPE TO DIALOG PAIR.
#
# "The y-axis range" is not one variable in this form. @emlGraphsDispatchDraw
# hands the F0 contour freqMin/freqMax, the waveform ampMin/ampMax, the
# spectrum and the LTAS powerMin/powerMax, and everything from the time series
# down valueMin/valueMax — and the recorder inside each of those draw
# procedures reads whichever of them it was given. Publishing valueMin for a
# waveform would replace an amplitude range with a range the amplitude dialog
# never showed, and nothing would raise: the numbers are all plausible doubles.
#
# Every dialog pair is set to a DIFFERENT, RECOGNISABLE value, so a
# publication that reads the wrong pair cannot coincide with the right answer.
# ---------------------------------------------------------------------------
elsif leg$ = "pairs"
    for t from 1 to 13
        @faFormState: t, 0
        freqMin = 11
        freqMax = 12
        ampMin = 21
        ampMax = 22
        powerMin = 31
        powerMax = 32
        valueMin = 41
        valueMax = 42
        @emlGraphsPublishAxisRequest
        @emit: "pairs_t" + string$ (t),
        ... fixed$ (emlGraphsAxisYReqMin, 0) + ".."
        ... + fixed$ (emlGraphsAxisYReqMax, 0)
    endfor

# ---------------------------------------------------------------------------
# LEG noform — THE FALLBACK, WHICH IS HALF THE CONTRACT.
#
# The form file is included and every one of its procedures is defined, but
# @emlGraphsPublishAxisRequest is never called. Neither global exists,
# @emlRecordAxisRequest must fall back to the draw's own arguments, and the
# recorded range must be the argument rather than 0. This is what the API
# export, the batch module, the Q-Q path and every other harness in this tree
# look like from the recorder's side.
# ---------------------------------------------------------------------------
elsif leg$ = "noform"
    @faTable: 6.0, 9.0, 14
    @faRecordBegin
    @emitPub: "noform_before"
    Erase all
    @emlDrawViolinPlot: faTable.id, "f0 by cohort", "Cohort", "f0 (Hz)",
    ... 6, 4, "color", 1, "grp", "val", 150, 400
    @emitPub: "noform_after"
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "noform_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# LEG clamp_min / clamp_real — RULING B, AND THE SIZE OF ITS DOMAIN.
#
# @emlDrawLegendPanel's ellipsis NOTE is on an active path: every draw
# procedure with a legend calls @emlDrawLegend, which dispatches here, and
# EML Graphs... is registered on Objects > New and on seven action lists. The
# two numbers in that sentence are a panel width in inches and a font size in
# points, and the ruling moves both off fixed$.
#
# WHAT THESE TWO LEGS MEASURE IS HOW MUCH THAT CHANGES, WHICH IS NOTHING, AND
# THAT IS THE FINDING RATHER THAN AN EXCUSE. fixed$ diverges from a true
# fixed-precision formatter only below 10^-precision — 0.01 at two decimals —
# and a legend panel that narrow does not reach this sentence at all. Swept
# 16 August 2026 on 6.6.30, three entries with one over-wide label, the panel
# budget stepped from 4.04 in down to 0.002 in: .clamped is 1 from 4.04 down
# to 0.052 and 0 at 0.048 and below, where @emlMeasureLegendPanel reports
# capacity 0, shows nothing and prints no note. So the narrowest panel that
# can print this sentence is about 0.05 in, at which fixed$ and @eml_fixed
# agree to the last digit — as they do at every width above it, and at every
# adaptive font size, which never approaches 0.1 pt.
#
# clamp_min drives that boundary; clamp_real drives the 6 x 4 case
# validate/v32 asserts the exact wording of. Both notes must be identical
# across the change. The ruling here is a UNIFORMITY ruling: it closes the
# escape hatch in an active path so that no later edit to this sentence can
# introduce a magnitude where fixed$ lies, and it moves no number today. The
# leg that shows where the two formatters actually part company is
# `formatter`, below, and it is a measurement of the built-in rather than a
# claim about this figure.
# ---------------------------------------------------------------------------
elsif leg$ = "clamp_min" or leg$ = "clamp_real"
    @faTable: 6.0, 9.0, 14
    Erase all
    Select outer viewport: 0, 6, 0, 4
    @emlSetAdaptiveTheme: 6, 4
    @emlSetColorPalette: "color"
    wide$ = ""
    for i to 30
        wide$ = wide$ + "Sustained vowel "
    endfor
    legendN = 3
    legendPatterned = 0
    for i to legendN
        legendColor$[i] = emlSetColorPalette.line$[i]
        legendFill$[i] = emlSetColorPalette.fill$[i]
        legendPattern[i] = emlSetColorPalette.pattern[i]
        legendLabel$[i] = "Group " + string$ (i)
    endfor
    legendLabel$[1] = wide$
    Select inner viewport: 0.8, 5.6, 0.5, 3.6
    Axes: 0, 1, 0, 1
    if leg$ = "clamp_min"
        # The narrowest budget that still clamps and still prints. 0.048 and
        # below reports capacity 0 and says nothing at all.
        panelW = 0.052
        panelFont = 8
    else
        # The panel width and font of harness/legend's 6 x 4 wide case, which
        # validate/v32 asserts the exact wording of. Both magnitudes are ones
        # fixed$ and @eml_fixed agree on to the last digit, so this leg is the
        # control that says the ruling changed a FORMATTER and not a VALUE.
        panelW = 4.0426
        panelFont = 8.3
    endif
    @emlDrawLegendPanel: 0.1, 0.1 + panelW, 0.5, 3.6, panelFont
    @emit: leg$ + "_clamped", string$ (emlDrawLegendPanel.clamped)
    @emit: leg$ + "_panelw", fixed$ (panelW, 6)

# ---------------------------------------------------------------------------
# LEG formatter — WHAT THE TWO FORMATTERS DO TO THE SAME NUMBER.
#
# Not a test of the plugin: a measurement of the built-in, kept beside the
# ruling so the claim in @emlDrawLegendPanel's comment is a recorded fact
# rather than an assertion. Each row is one value, fixed$ of it, and
# @eml_fixed of it, at the two precisions this file's note uses.
# ---------------------------------------------------------------------------
elsif leg$ = "formatter"
    nv = 8
    v[1] = 0
    v[2] = 0.004
    v[3] = 0.001
    v[4] = 0.06
    v[5] = 0.5
    v[6] = 4.0426
    v[7] = 8.3
    v[8] = -0.0000000001
    for i to nv
        @eml_fixed: v[i], 2
        @emit: "fmt2_" + string$ (i),
        ... fixed$ (v[i], 6) + "|" + fixed$ (v[i], 2) + "|" + eml_fixed.result$
        @eml_fixed: v[i], 1
        @emit: "fmt1_" + string$ (i),
        ... fixed$ (v[i], 6) + "|" + fixed$ (v[i], 1) + "|" + eml_fixed.result$
    endfor

else
    exitScript: "formaxis_drive: unknown leg '", leg$, "'"
endif
