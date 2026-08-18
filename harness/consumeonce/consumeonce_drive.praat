# ============================================================================
# harness/consumeonce/consumeonce_drive.praat — the axis publication is
# consumed once, and a later draw in the same process gets its own range
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# ONE LEG PER PRAAT PROCESS, chosen by $EML_CO_LEG, for the reason
# harness/stress_graphs.sh gives: a Praat script error aborts the script, so a
# dozen legs in one process report one failure and hide eleven.
#
# WHAT THIS RIG IS FOR, AND WHY IT HAD TO BE A NEW ONE.
#
# PRAAT CANNOT UNSET A VARIABLE. The graphs form publishes the axis range the
# user asked for as emlGraphsAxisYReqMin / emlGraphsAxisYReqMax (ruling 10(b);
# harness/formaxis drives that half), and @emlRecordAxisRequest preferred that
# pair whenever it EXISTED — which, in Praat, is for ever. So one press of
# Draw armed every recorded draw in the rest of the session with the form's
# range, in any menu command, from any file.
#
# THE DEFECT NEEDS TWO DRAWS IN ONE PROCESS, WHICH IS EXACTLY WHAT NO EXISTING
# RIG DOES. harness/formaxis draws once per leg and every draw it makes is a
# form draw, so the publication is always legitimately live. harness/axisspec
# publishes the globals by hand and then draws once. harness/record's
# roundtrip calls @emlDrawViolinPlot directly with no form at all, so the
# fallback fires and the round trip is byte-perfect while the defect sits
# untouched one layer up. Every one of them is green on a tree with the bug
# in it. The leak only appears when a form draw is followed, in the SAME
# process, by a draw that never went near the form — and graphs/eml-draw-qq.
# praat is precisely that draw: it calls @emlDrawScatterPlot with 0, 0, 0, 0,
# its own auto sentinel, and has no dialog of its own.
#
# THE FORM RANGE IS TYPED, NEVER AUTO, ON EVERY LEG THAT MATTERS. 0 .. 100 is
# a range a user types; 0, 0 is the auto sentinel. If the form leg were left
# on auto, the leaked value and the Q-Q plot's own correct answer would both
# be 0.0 and the leg would pass on a broken tree. That is the trap this whole
# file is built around.
#
# EVERY STAGE BELOW IS THE SHIPPED PROCEDURE. graphs/eml-graphs-form.praat is
# a library — array initialisation at top level, no `form:` and no
# `beginPause:` — so an `include` gets every procedure and no dialog, and
# @emlGraphsPublishAxisRequest, @emlGraphsStampAxisRequest,
# @emlGraphsPreDispatchHeadroom and @emlGraphsDispatchDraw are called, not
# transcribed. The bill for the alternative is written down in
# harness/disclosure/probe_formpath.praat, which transcribed the form's
# annotation block by hand, passed the wrong variable, and therefore tested a
# CORRECTED copy of the block while the shipped one was clipping an omnibus
# box off the figure.
#
# Env in:  EML_CO_LEG   leg name
#          EML_CO_OUT   TSV to append key/value pairs to
#          EML_CO_AUX   scratch folder for this leg (recordings)
#          EML_CO_ROOT  the source tree this leg is running out of
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
include ../../plugin/graphs/eml-draw-qq.praat
include ../../plugin/graphs/eml-graphs-form.praat

# EVERY FILE THIS DRIVE WRITES IS UTF-8, AND SAYING SO IS NOT OPTIONAL. Praat
# converts a file to UTF-16 the moment a non-ASCII character is written into
# it, and a validator reading a UTF-16 TSV with readLines() sees keys spelled
# "l e g" with NULs between the letters — which is indistinguishable from a
# harness that never ran. Learned the hard way by harness/drawlayer.
Text writing preferences: "UTF-8"

@emlInitDrawingDefaults

leg$ = environment$ ("EML_CO_LEG")
out$ = environment$ ("EML_CO_OUT")
aux$ = environment$ ("EML_CO_AUX")
coRoot$ = environment$ ("EML_CO_ROOT")
if out$ = ""
    exitScript: "EML_CO_OUT unset."
endif

procedure emit: .key$, .value$
    appendFileLine: out$, .key$, tab$, .value$
    appendInfoLine: .key$, tab$, .value$
endproc

# @emitStamp — the stamp global, or the fact that it does not exist.
# BOTH OR NEITHER is the contract: a pair with no stamp must be read as
# absent, so presence and value are reported separately and the validator
# asserts the pair rather than inferring one from the other.
procedure emitStamp: .prefix$
    .has = 0
    if variableExists ("emlGraphsAxisYReqStep")
        .has = 1
    endif
    @emit: .prefix$ + "_stamp_exists", string$ (.has)
    if .has = 1
        @emit: .prefix$ + "_stamp", string$ (emlGraphsAxisYReqStep)
    endif
    .hasPair = 0
    if variableExists ("emlGraphsAxisYReqMin")
        if variableExists ("emlGraphsAxisYReqMax")
            .hasPair = 1
        endif
    endif
    @emit: .prefix$ + "_pair_exists", string$ (.hasPair)
    if .hasPair = 1
        @emit: .prefix$ + "_pair",
        ... fixed$ (emlGraphsAxisYReqMin, 4) + ".."
        ... + fixed$ (emlGraphsAxisYReqMax, 4)
    endif
    @emit: .prefix$ + "_recordn", string$ (emlRecordN)
endproc

# ---------------------------------------------------------------------------
# THE FIXTURE. Deterministic — a byte comparison or a repeated run cannot be
# built on randomGauss with no seed — and the same linear congruential
# sequence harness/formaxis writes, so the two rigs' numbers are comparable.
#
# The values sit around 200 Hz, WELL OUTSIDE the 0 .. 100 the form leg types.
# That is deliberate: if the leaked range and the data's own extent overlapped,
# a Q-Q plot drawn on the wrong axis would still have ink in the frame and the
# only visible difference would be in a number nobody reads.
# ---------------------------------------------------------------------------
procedure coTable
    Create Table with column names: "co", 0, "grp val"
    .row = 0
    .rng = 20260816
    for .g from 1 to 4
        for .k from 1 to 14
            .rng = (1103515245 * .rng + 12345) mod 2147483648
            .u = .rng / 2147483648
            .row = .row + 1
            Append row
            Set string value: .row, "grp", "Cohort " + string$ (.g)
            Set numeric value: .row, "val", 200 + .g * 6 + (.u - 0.5) * 9
        endfor
    endfor
    .id = selected ("Table")
endproc

# ---------------------------------------------------------------------------
# THE FORM'S INPUT STATE. Everything a dialog would have filled in, at the
# point the range-validation block has just finished. Values, not logic:
# getting one wrong produces a different figure, not a check that cannot fail.
# ---------------------------------------------------------------------------
procedure coFormState: .type, .id
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
    timeColName$ = ""
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

procedure coRecordBegin
    @emlRecordInit
    emlRecordPluginRoot$ = coRoot$ + "/plugin"
    @emlRecordBegin: aux$
    emlRecordPluginRoot$ = coRoot$ + "/plugin"
    @emlRecordLoadPhrases: coRoot$ + "/plugin/data/eml-record-phrases.csv"
    @emlRecordHeader: "co", 100, 4, "consume once"
endproc

# The vector the Q-Q plot is drawn from. Taken off the fixture table so that
# the two figures in a leg describe the same numbers — a Q-Q plot of unrelated
# data would still draw, and the leg would still measure the axis, but the
# scenario would no longer be one a user can walk.
procedure coVector: .tableId
    selectObject: .tableId
    .n = Get number of rows
    .v# = zero# (.n)
    for .i from 1 to .n
        .v# [.i] = Get value: .i, "val"
    endfor
endproc

# ---------------------------------------------------------------------------
# LEG form_then_qq — THE LEAK ITSELF, DRIVEN.
#
# One press of the graphs form on a violin with a TYPED range of 0 .. 100,
# recorded; then, in the same process and with the same recording still
# running, a Q-Q plot, which goes nowhere near the form and passes its own
# 0, 0, 0, 0 to @emlDrawScatterPlot.
#
# On a tree with the defect the second step declares axisYMin = 0.0 and
# axisYMax = 100.0 — the first figure's dialog, on a figure whose dialog does
# not exist. On a repaired tree it declares the auto sentinel, and the first
# step still declares the 0 .. 100 the user really typed. BOTH halves are
# asserted: a repair that simply stopped preferring the publication would
# satisfy the second and lose the first, which is ruling 10(b) undone.
# ---------------------------------------------------------------------------
if leg$ = "form_then_qq"
    @coTable
    @coRecordBegin
    @coFormState: 7, coTable.id
    valueMin = 0
    valueMax = 100
    @emit: "form_then_qq_dialog", fixed$ (valueMin, 4) + ".." + fixed$ (valueMax, 4)

    @emlGraphsPublishAxisRequest
    @emitStamp: "form_then_qq_afterpublish"
    @emlSetAdaptiveTheme: figure_width, figure_height
    @emlGraphsDispatchDraw
    @emitStamp: "form_then_qq_afterdraw"

    ; THE SECOND DRAW. No form, no dispatch, nothing republished — the shape
    ; of every menu command in this plugin that is not EML Graphs. A menu
    ; command is its own run: in a user's session it is its own script scope
    ; and the recorder sees the boundary for itself, and this driver stays in
    ; one scope, so it marks the boundary the way the form does.
    @emlRecordNewRun
    @coVector: coTable.id
    Erase all
    @emlDrawQQPlot: coVector.v#, "val", 6, 4, "color", 1
    @emit: "form_then_qq_qq_drew", string$ (emlDrawQQPlot.drew)
    @emit: "form_then_qq_qq_error", emlDrawQQPlot.error$
    @emitStamp: "form_then_qq_afterqq"

    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "form_then_qq_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# LEG bridge_then_qq — THE SAME LEAK WITH A STEP RECORDED IN BETWEEN.
#
# This is the leg that says the stamp names the RIGHT step. An annotated
# violin runs the annotation bridge, and the bridge RECORDS A STEP OF ITS OWN:
# the group comparison is step 1 and the figure is step 2. A stamp taken where
# the pair is published — before the bridge — would name step 1, and the
# figure would be refused its own user's range, which is ruling 10(b) undone
# by the repair meant to protect it. The stamp is therefore re-taken in
# @emlGraphsDispatchDraw, and this leg is what that claim rests on.
#
# The bracket pass also resolves the typed 0 .. 100 into a widened ceiling
# before the draw, so the recorded 100 cannot have come from the variable the
# draw was handed.
# ---------------------------------------------------------------------------
elsif leg$ = "bridge_then_qq"
    @coTable
    @coRecordBegin
    @coFormState: 7, coTable.id
    annotate = 1
    valueMin = 0
    valueMax = 100
    @emit: "bridge_then_qq_dialog", fixed$ (valueMin, 4) + ".." + fixed$ (valueMax, 4)

    @emlGraphsPublishAxisRequest
    @emitStamp: "bridge_then_qq_afterpublish"

    @emlSetAdaptiveTheme: figure_width, figure_height
    @emlBridgeGroupComparison: coTable.id, "val", "grp", 0.05, "stars", 0, 0,
    ... "auto", 2
    @emit: "bridge_then_qq_brackets", string$ (annotBracketN)
    @emitStamp: "bridge_then_qq_afterbridge"

    @emlGraphsPreDispatchHeadroom
    @emit: "bridge_then_qq_resolved",
    ... fixed$ (valueMin, 4) + ".." + fixed$ (valueMax, 4)

    @emlGraphsDispatchDraw
    @emitStamp: "bridge_then_qq_afterdraw"

    ; The Q-Q is a second menu command, hence a second run -- see the note in
    ; leg form_then_qq.
    @emlRecordNewRun
    @coVector: coTable.id
    Erase all
    @emlDrawQQPlot: coVector.v#, "val", 6, 4, "color", 1
    @emit: "bridge_then_qq_qq_drew", string$ (emlDrawQQPlot.drew)
    @emitStamp: "bridge_then_qq_afterqq"

    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "bridge_then_qq_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# LEG form_then_violin — THE LEAK IS NOT ABOUT THE Q-Q PLOT.
#
# The Q-Q plot is where it was found, not where it lives. Any draw procedure
# reached without the form inherits the same publication, so this leg follows
# the form press with a DIRECT @emlDrawViolinPlot at 150 .. 400 — the shape of
# the API export, the batch module and every user script. Its recorded range
# must be 150 .. 400.
#
# It also separates two repairs that the Q-Q leg alone cannot tell apart:
# refusing a spent publication, and refusing every publication whose values
# are not the caller's. 150 .. 400 is neither the form's 0 .. 100 nor the auto
# sentinel, so only a correct fallback produces it.
# ---------------------------------------------------------------------------
elsif leg$ = "form_then_violin"
    @coTable
    @coRecordBegin
    @coFormState: 7, coTable.id
    valueMin = 0
    valueMax = 100
    @emlGraphsPublishAxisRequest
    @emlSetAdaptiveTheme: figure_width, figure_height
    @emlGraphsDispatchDraw
    @emitStamp: "form_then_violin_afterdraw"

    ; A second menu command, hence a second run -- see leg form_then_qq.
    @emlRecordNewRun
    Erase all
    @emlDrawViolinPlot: coTable.id, "f0 by cohort", "Cohort", "f0 (Hz)",
    ... 6, 4, "color", 1, "grp", "val", 150, 400
    @emitStamp: "form_then_violin_afterviolin"

    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "form_then_violin_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# LEG stamp_live — THE POSITIVE CONTROL, AND THE REASON THE OTHER LEGS MEAN
# ANYTHING.
#
# A recorder that ignored the publication entirely — deleted the preference,
# kept the fallback — passes every leg above. This leg is the one it cannot
# pass. The pair is published by hand as the AUTO sentinel with a CORRECT
# stamp, and the draw is handed 150 .. 400, which is what the form's resolving
# passes do. The recorded range must be the sentinel.
#
# The stamp is written as emlRecordN + 1, never as a literal 1: @emlRecordStep
# increments emlRecordN and then appends, and @emlRecordAxisRequest runs before
# it, so that expression IS the definition of "the step being recorded".
# ---------------------------------------------------------------------------
elsif leg$ = "stamp_live"
    @coTable
    @coRecordBegin
    emlGraphsAxisYReqMin = 0
    emlGraphsAxisYReqMax = 0
    emlGraphsAxisYReqStep = emlRecordN + 1
    @emitStamp: "stamp_live_before"
    Erase all
    @emlDrawViolinPlot: coTable.id, "f0 by cohort", "Cohort", "f0 (Hz)",
    ... 6, 4, "color", 1, "grp", "val", 150, 400
    @emitStamp: "stamp_live_after"
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "stamp_live_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# LEG stamp_stale — THE EQUALITY, NOT THE EXISTENCE.
#
# Same publication as stamp_live, with a stamp naming a step this draw will
# never be. A repair that only asked whether a stamp EXISTS passes stamp_live
# and every leak leg above — the stamp exists on all of them — and fails only
# here. The offset is +5 rather than +1 so that no plausible off-by-one in the
# reader's arithmetic can make it match by accident.
# ---------------------------------------------------------------------------
elsif leg$ = "stamp_stale"
    @coTable
    @coRecordBegin
    emlGraphsAxisYReqMin = 0
    emlGraphsAxisYReqMax = 0
    emlGraphsAxisYReqStep = emlRecordN + 5
    @emitStamp: "stamp_stale_before"
    Erase all
    @emlDrawViolinPlot: coTable.id, "f0 by cohort", "Cohort", "f0 (Hz)",
    ... 6, 4, "color", 1, "grp", "val", 150, 400
    @emitStamp: "stamp_stale_after"
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "stamp_stale_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# LEG pair_unstamped — BOTH OR NEITHER, ASSERTED RATHER THAN ASSUMED.
#
# The pair published with no stamp at all. This is the state every tree before
# ruling A was permanently in, and it is the state a future caller reaches by
# copying the two publication lines and not the third. It must be read as
# ABSENT: the draw's own 150 .. 400 survives.
#
# Praat cannot unset a variable, so this leg cannot be built by publishing a
# stamp and removing it. It is built by never writing one, which is why it has
# to be its own process rather than a phase of another leg.
# ---------------------------------------------------------------------------
elsif leg$ = "pair_unstamped"
    @coTable
    @coRecordBegin
    emlGraphsAxisYReqMin = 0
    emlGraphsAxisYReqMax = 0
    @emitStamp: "pair_unstamped_before"
    Erase all
    @emlDrawViolinPlot: coTable.id, "f0 by cohort", "Cohort", "f0 (Hz)",
    ... 6, 4, "color", 1, "grp", "val", 150, 400
    @emitStamp: "pair_unstamped_after"
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "pair_unstamped_flushed", string$ (emlRecordFlush.written)

# ---------------------------------------------------------------------------
# LEG stamp_types — THE STAMP TRAVELS WITH ALL THIRTEEN TYPES.
#
# The publication is TYPE-DISPATCHED: a pitch contour is handed freqMin/
# freqMax, a waveform ampMin/ampMax, a spectrum and an LTAS powerMin/powerMax,
# everything from the line chart down valueMin/valueMax. harness/formaxis's
# `pairs` leg drives the map itself. What this leg adds is the stamp: a type
# whose branch published a pair and no stamp would be a type that keeps the
# permanent-existence defect while the other twelve are repaired, and nothing
# would raise, because the pair it publishes is correct.
#
# The recorder is running, so a live stamp is a NUMBER and not zero. Each
# type's stamp and pair are reported together.
# ---------------------------------------------------------------------------
elsif leg$ = "stamp_types"
    @coTable
    @coRecordBegin
    for t from 1 to 13
        @coFormState: t, coTable.id
        freqMin = 11
        freqMax = 12
        ampMin = 21
        ampMax = 22
        powerMin = 31
        powerMax = 32
        valueMin = 41
        valueMax = 42
        ; Praat cannot unset a variable, so a type that failed to stamp would
        ; otherwise be covered by the PREVIOUS type's stamp. Zeroed before
        ; each publication, so what is read back was written by this branch.
        emlGraphsAxisYReqStep = 0
        @emlGraphsPublishAxisRequest
        @emit: "stamp_types_t" + string$ (t),
        ... fixed$ (emlGraphsAxisYReqMin, 0) + ".."
        ... + fixed$ (emlGraphsAxisYReqMax, 0) + "@"
        ... + string$ (emlGraphsAxisYReqStep)
    endfor
    @emit: "stamp_types_recordn", string$ (emlRecordN)

# ---------------------------------------------------------------------------
# LEG qq_alone — THE CONTROL THAT SAYS THE Q-Q PLOT'S OWN ANSWER IS 0.0.
#
# A Q-Q plot with no form in the process at all. Without this leg, "the Q-Q
# step declares the auto sentinel" is a claim with no baseline: it could be
# the sentinel because the leak was closed, or because the sentinel is what a
# Q-Q step declares under every condition including the broken one. It is the
# second half of that pair — on a defective tree this leg is GREEN and
# form_then_qq is red, which is what localises the defect to the inheritance
# rather than to the Q-Q path.
# ---------------------------------------------------------------------------
elsif leg$ = "qq_alone"
    @coTable
    @coRecordBegin
    @coVector: coTable.id
    Erase all
    @emlDrawQQPlot: coVector.v#, "val", 6, 4, "color", 1
    @emit: "qq_alone_drew", string$ (emlDrawQQPlot.drew)
    @emitStamp: "qq_alone_after"
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: "qq_alone_flushed", string$ (emlRecordFlush.written)

else
    exitScript: "consumeonce_drive: unknown leg '", leg$, "'"
endif
