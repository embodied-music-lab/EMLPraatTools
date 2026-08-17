# ============================================================================
# EML Stats : Analysis Orchestrators
# ============================================================================
# Module: eml-analysis.praat
# Version: 1.3
# Date: 8 August 2026
#
#
# Purpose: Centralizes computation + reporting for all analysis types.
#          Each orchestrator: validate → compute → report.
#
# Reporters live in eml-annotation-procedures.praat (existing) except
# for two NEW reporters defined here:
#   @emlReportPairwiseComparison  — extracted from eml-pairwise.praat
#   @emlReportDescriptiveAnalysis — extracted from eml-describe-table.praat
#
# Dependencies (must be included before this file):
#   eml-core-utilities.praat
#   eml-core-descriptive.praat
#   eml-extract.praat
#   eml-output.praat
#   eml-inferential.praat
#
# Reporters called by orchestrators are defined in files included
# AFTER this one (eml-annotation-procedures.praat). Praat resolves
# all procedure names at parse time, so forward references work.
#
# Architecture: EML_V1_ARCHITECTURE.md §5
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================


# ============================================================================
#
#  1. TWO-GROUP COMPARISON
#
# ============================================================================

procedure emlRunTwoGroupAnalysis: .tableId, .dataCol$, .groupCol$, .testType$, .equalVar
    .recResult$ = ""
    ; DEFAULTED, NOT ASSUMED. .doPar = 1 says the parametric arm was
    ; REQUESTED, not that it produced a p -- a test that errors leaves .p
    ; unset, and reading it killed plugin/dev/tests/phase2 with "Unknown
    ; variable". The record then reports only what was actually computed.
    .p = undefined
    .mwP = undefined
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlCountGroups: .tableId, .groupCol$
    ; BLANK GROUP CELLS ARE MISSING DATA, not a category -- see
    ; @emlCountGroups. Captured immediately, because every
    ; post-hoc procedure re-invokes @emlCountGroups and would clobber it, and
    ; surfaced in the wording this tree already uses for excluded rows.
    .nBlankGroup = emlCountGroups.nBlankRows
    if .nBlankGroup > 0
        appendInfoLine: "  Note: ", .nBlankGroup,
        ... " row(s) excluded -- the group column is empty for them."
    endif
    if emlCountGroups.error$ <> ""
        .error$ = emlCountGroups.error$
    elsif emlCountGroups.nGroups < 2
        .error$ = "Group column """ + .groupCol$ + """ has only "
        ... + string$ (emlCountGroups.nGroups)
        ... + " group. This test compares exactly 2."
        # No other tool helps here: one group is one group. The way out is a
        # different group column, which the entry form can still supply.
    elsif emlCountGroups.nGroups > 2
        .error$ = "Group column """ + .groupCol$ + """ has "
        ... + string$ (emlCountGroups.nGroups)
        ... + " groups. This test compares exactly 2."
        .remedy$ = "Compare k groups (ANOVA)...|Compare k groups (Kruskal-Wallis)..."
    endif

    if .error$ <> ""
        goto END_TWO_GROUP
    endif

    ; The data column must BE there, asked before it is asked to hold
    ; numbers. Every other orchestrator hands the Table to something that
    ; asks this itself -- a test in eml-inferential.praat, or a reader in
    ; eml-extract.praat -- and gets the refusal back from there. This one
    ; cannot: @emlTTest and @emlMannWhitneyU take vectors, and
    ; @eml_getGroupData answers a missing column with an empty vector rather
    ; than an error, so this orchestrator is the lowest layer on this path
    ; that ever sees the Table. Without the guard the n1/n2 check below fired
    ; instead and said
    ;   Each group needs at least 2 observations. Group "G1": n=0, ...
    ; which is true, is about the groups, and sends the reader to inspect a
    ; grouping variable that is perfectly fine.
    @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
    if emlRequireColumnPresent.error$ <> ""
        .error$ = emlRequireColumnPresent.error$
        goto END_TWO_GROUP
    endif

    ; The data column must hold numbers. See @emlRequireNumericColumn
    ; in eml-inferential.praat: this call is the same in every orchestrator
    ; below and differs only in the role word and the column, which is the
    ; whole point -- the diagnosis is written once.
    @emlRequireNumericColumn: .tableId, "Data column", .dataCol$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_TWO_GROUP
    endif

    .group1$ = emlCountGroups.groupLabel$[1]
    .group2$ = emlCountGroups.groupLabel$[2]

    @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .group1$
    .g1# = eml_getGroupData.data#
    .n1 = eml_getGroupData.n
    @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .group2$
    .g2# = eml_getGroupData.data#
    .n2 = eml_getGroupData.n

    if .n1 < 2 or .n2 < 2
        .error$ = "Each group needs at least 2 observations. Group """ + .group1$ + """: n=" + string$ (.n1) + ", group """ + .group2$ + """: n=" + string$ (.n2)
        goto END_TWO_GROUP
    endif

    @emlMean: .g1#
    .mean1 = emlMean.result
    @emlSD: .g1#
    .sd1 = emlSD.result
    @emlMedian: .g1#
    .median1 = emlMedian.result

    @emlMean: .g2#
    .mean2 = emlMean.result
    @emlSD: .g2#
    .sd2 = emlSD.result
    @emlMedian: .g2#
    .median2 = emlMedian.result

    # v1.2 item 4: @emlReportTwoGroupComparison performs NO error$ checks — it
    # prints emlTTest.*, emlCohenD.*, emlMannWhitneyU.*, emlRankBiserialR.*
    # unconditionally and emits a CSV row for each branch. A failed test left
    # its outputs undefined and the report presented them as results. Capture
    # each error$ here, drop the failed branch from the reported test type so
    # neither the report lines nor the CSV row are produced, and disclose why.
    .ttErr$ = ""
    .dErr$ = ""
    .mwErr$ = ""
    .rbErr$ = ""
    .doPar = 0
    .doNon = 0
    if .testType$ = "parametric" or .testType$ = "both"
        .doPar = 1
    endif
    if .testType$ = "nonparametric" or .testType$ = "both"
        .doNon = 1
    endif

    if .doPar
        @emlTTest: .g1#, .g2#, 2, .equalVar
        .ttErr$ = emlTTest.error$
        @emlCohenD: .g1#, .g2#
        .dErr$ = emlCohenD.error$
        if .ttErr$ <> ""
            .doPar = 0
        endif
        if .dErr$ <> ""
            .doPar = 0
        endif
    endif

    if .doNon
        @emlMannWhitneyU: .g1#, .g2#, 2
        .mwErr$ = emlMannWhitneyU.error$
        # item 3 pattern: @emlRankBiserialR re-runs @emlMannWhitneyU internally
        # and so overwrites emlMannWhitneyU.* — the values the reporter and the
        # CSV row read. Capture before, restore after.
        .mwU1 = emlMannWhitneyU.u1
        .mwU2 = emlMannWhitneyU.u2
        .mwZ = emlMannWhitneyU.z
        .mwP = emlMannWhitneyU.p
        .mwMethod$ = emlMannWhitneyU.method$
        @emlRankBiserialR: .g1#, .g2#, 2
        .rbErr$ = emlRankBiserialR.error$
        emlMannWhitneyU.u1 = .mwU1
        emlMannWhitneyU.u2 = .mwU2
        emlMannWhitneyU.z = .mwZ
        emlMannWhitneyU.p = .mwP
        emlMannWhitneyU.method$ = .mwMethod$
        emlMannWhitneyU.error$ = .mwErr$
        if .mwErr$ <> ""
            .doNon = 0
        endif
        if .rbErr$ <> ""
            .doNon = 0
        endif
    endif

    # Reported test type reflects what actually succeeded.
    .effType$ = ""
    if .doPar
        .effType$ = "parametric"
    endif
    if .doNon
        .effType$ = "nonparametric"
    endif
    if .doPar
        if .doNon
            .effType$ = "both"
        endif
    endif

    @emlCSVInit
    @emlReportTwoGroupComparison: .tableName$, .dataCol$, .groupCol$, .group1$, .group2$, .n1, .mean1, .sd1, .median1, .n2, .mean2, .sd2, .median2, .effType$

    if .ttErr$ <> ""
        .ttNote$ = "  Parametric results omitted — t-test failed: " + .ttErr$
        appendInfoLine: .ttNote$
    endif
    if .dErr$ <> ""
        .dNote$ = "  Parametric results omitted — Cohen's d failed: " + .dErr$
        appendInfoLine: .dNote$
    endif
    if .mwErr$ <> ""
        .mwNote$ = "  Nonparametric results omitted — Mann-Whitney U failed: " + .mwErr$
        appendInfoLine: .mwNote$
    endif
    if .rbErr$ <> ""
        .rbNote$ = "  Nonparametric results omitted — rank-biserial r failed: " + .rbErr$
        appendInfoLine: .rbNote$
    endif

    ; --- three-file declaration. Extras first: staging reuses the tidy
    ; collector, so the model's own tidy must be last in it.
    if .error$ = ""
        @emlResultClearExtras
        @emlDeclareTwoGroupEffects: .doPar, .doNon
        @emlResultStageExtra: "effectsize"
        @emlDeclareTwoGroupResult: .tableName$, .dataCol$, .groupCol$,
        ... .doPar, .doNon, .group1$, .group2$
    endif

    ; The numbers the reporter printed, from this procedure's OWN locals.
    if .error$ = ""
        .recResult$ = .group1$ + ": n = " + string$ (.n1) + ", mean = "
        ... + fixed$ (.mean1, 4) + ", SD = " + fixed$ (.sd1, 4) + newline$
        ... + "  " + .group2$ + ": n = " + string$ (.n2) + ", mean = "
        ... + fixed$ (.mean2, 4) + ", SD = " + fixed$ (.sd2, 4)
        if .doPar = 1 and .p <> undefined
            .recResult$ = .recResult$ + newline$ + "  p = " + fixed$ (.p, 4)
        endif
        if .doNon = 1 and .mwP <> undefined
            .recResult$ = .recResult$ + newline$ + "  Mann-Whitney p = "
            ... + fixed$ (.mwP, 4)
        endif
    endif
    label END_TWO_GROUP

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Two-group comparison",
        ... .dataCol$ + " by " + .groupCol$ + ", " + .testType$,
        ... "Equal-variance assumption: " + if .equalVar then "pooled" else "Welch" fi + ".",
        ... "@emlRunTwoGroupAnalysis: data, """ + .dataCol$ + """, """ + .groupCol$ + """, """ + .testType$ + """, " + string$ (.equalVar),
        ... "In the GUI: New > EML Tools > Compare two groups...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc


# ============================================================================
#
#  2. ONE-WAY ANOVA
#
# ============================================================================

procedure emlRunAnovaAnalysis: .tableId, .dataCol$, .groupCol$, .doTukey
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlCountGroups: .tableId, .groupCol$
    ; BLANK GROUP CELLS ARE MISSING DATA, not a category -- see
    ; @emlCountGroups. Captured immediately, because every
    ; post-hoc procedure re-invokes @emlCountGroups and would clobber it, and
    ; surfaced in the wording this tree already uses for excluded rows.
    .nBlankGroup = emlCountGroups.nBlankRows
    if .nBlankGroup > 0
        appendInfoLine: "  Note: ", .nBlankGroup,
        ... " row(s) excluded -- the group column is empty for them."
    endif
    if emlCountGroups.error$ <> ""
        .error$ = emlCountGroups.error$
        goto END_ANOVA
    endif
    .nGroups = emlCountGroups.nGroups
    if .nGroups < 2
        .error$ = "Group column """ + .groupCol$ + """ has fewer than 2 groups."
        goto END_ANOVA
    endif

    ; See the note in @emlRunTwoGroupAnalysis.
    @emlRequireNumericColumn: .tableId, "Data column", .dataCol$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_ANOVA
    endif

    @emlOneWayAnova: .tableId, .dataCol$, .groupCol$, .doTukey
    if emlOneWayAnova.error$ <> ""
        .error$ = emlOneWayAnova.error$
        goto END_ANOVA
    endif

    # Ensure pairwise Cohen's d matrix always exists
    if .doTukey = 0
        emlOneWayAnova.dMatrix## = zero## (.nGroups, .nGroups)
        for .i from 1 to .nGroups - 1
            @eml_getGroupData: .tableId, .dataCol$, .groupCol$, emlOneWayAnova.groupLabel$[.i]
            .vi# = eml_getGroupData.data#
            for .j from .i + 1 to .nGroups
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$, emlOneWayAnova.groupLabel$[.j]
                @emlCohenD: .vi#, eml_getGroupData.data#
                if emlCohenD.error$ = ""
                    emlOneWayAnova.dMatrix## [.i, .j] = emlCohenD.d
                    emlOneWayAnova.dMatrix## [.j, .i] = -emlCohenD.d
                endif
            endfor
        endfor
    endif

    @emlCSVInit
    @emlReportAnovaComparison: .tableName$, .dataCol$, .groupCol$, .tableId, .nGroups, .doTukey

    ; Declare the same result in broom's three-file shape. Placed AFTER the
    ; reporter, not inside it, for two reasons: the reporter is what prints
    ; these numbers, so declaring after it means the frames and the report
    ; describe one run of @emlOneWayAnova rather than two; and the lifecycle
    ; then sits beside
    ; @emlCSVInit in the orchestrator rather than being split across
    ; graphs/eml-annotation-procedures.praat.
    ; ORDER MATTERS. The separate frames are staged FIRST, because staging
    ; reuses the one tidy collector and the model's own tidy has to be what
    ; is left in it when @emlResultWrite runs.
    ;
    ; ONE GUARD OVER THE WHOLE SEQUENCE, which is how every other declaring
    ; orchestrator writes it (two-group, KW, pairwise, two-way, paired,
    ; correlation, regression, normality, RM, Friedman). Splitting it -- the
    ; model declaration outside this `if`, only @emlResultClearExtras and the
    ; extra frames inside -- means a run that reaches here with
    ; emlOneWayAnova.error$ non-empty skips the clear and still declares:
    ; the PREVIOUS analysis's staged post-hoc and effect-size frames would
    ; survive in emlResult_extra*, and @emlExportResultFiles would write them
    ; beside this analysis's tidy/glance/augment, under this analysis's base
    ; name. The clear and the declaration are one decision and belong under
    ; one condition.
    if emlOneWayAnova.error$ = ""
        @emlResultClearExtras
        if .doTukey
            @emlDeclareTukeyResult: .groupCol$
            @emlResultStageExtra: "posthoc"
        endif
        @emlDeclareAnovaEffectSizes: .groupCol$, .doTukey
        @emlResultStageExtra: "effectsize"
        @emlDeclareOneWayAnovaResult: .tableName$, .dataCol$, .groupCol$,
        ... .tableId, .doTukey
    endif

    label END_ANOVA

    ; ---------------------------------------------------------------------
    ; RECORD WORKFLOW. Inert unless a recording is running: every entry point
    ; in eml-record.praat returns immediately while emlRecordActive is 0, so
    ; this costs one procedure call per analysis and changes nothing else.
    ;
    ; PLACED AFTER `label END_ANOVA`, WHICH IS THE WHOLE POINT. Every guard
    ; above jumps here, so a run that refused -- fewer than two groups, a
    ; non-numeric data column, an @emlOneWayAnova failure -- is recorded as a
    ; step with its refusal, rather than vanishing. A log that only shows the
    ; analyses that succeeded is a log that lies by omission, and the failure
    ; it hides is usually the one worth reading.
    ;
    ; THE NUMBERS COME FROM THE SAME VARIABLES THE REPORTER PRINTED, not from
    ; a re-read of the Info window. @emlReportAnovaComparison re-runs
    ; @emlOneWayAnova itself, so emlOneWayAnova.* here holds exactly what was
    ; printed. Scraping info$() instead would reintroduce the label-matching
    ; hazard validate/REGISTRY.md already records -- "Soprano" matches five
    ; lines in the v09 capture and seven in v10.
    ; ---------------------------------------------------------------------
    ; GUARDED ON EXISTENCE, not just on state. @emlRecordAnova opens with
    ; @emlRecordInit, so calling it unconditionally made this whole file
    ; require eml-record.praat -- the same shipped-API break the violin hook
    ; documents, and the one that took plugin/dev/tests/phase2 down with
    ; Procedure "emlRecordAnalysisStep" not found. Praat only errors on an
    ; undefined procedure when it EXECUTES the call, so a call inside a false
    ; branch costs nothing.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnova: .tableId, .dataCol$, .groupCol$, .doTukey, .error$
    endif

    selectObject: .tableId
endproc


# ----------------------------------------------------------------------------
# @emlRecordAnova
# The recording half of @emlRunAnovaAnalysis, kept as its own procedure so the
# orchestrator gains one line rather than thirty, and so the mapping from
# analysis to log line can be read and reviewed on its own.
#
# Arguments: .tableId, .dataCol$, .groupCol$, .doTukey, .error$
# ----------------------------------------------------------------------------
procedure emlRecordAnova: .tableId, .dataCol$, .groupCol$, .doTukey, .error$
    @emlRecordInit
    if emlRecordActive = 0
        goto END_RECORD_ANOVA
    endif

    ; Provenance: WHICH object this record describes. "Whatever is selected"
    ; gives a reader no way to check they selected the right thing.
    @emlRecordSource: .tableId

    if .error$ <> ""
        @emlPhrase: "refusal.intent", .error$, "", "", "", "", ""
        @emlRecordStep: "refusal", emlPhrase.result$, "", "", ""
        goto END_RECORD_ANOVA
    endif

    ; --- intent. Composed from two keys, and the FIRST is captured before
    ; the second call: emlPhrase.result$ is one namespace per procedure, not
    ; per call, so reading it after two calls yields only the second.
    @emlPhrase: "anova.intent", "One-way ANOVA", .dataCol$, .groupCol$,
    ... string$ (emlOneWayAnova.nGroups), "", ""
    .intent$ = emlPhrase.result$
    if .doTukey
        @emlPhrase: "alpha.source.default", "", "", "", "", "", ""
        .alphaSrc$ = emlPhrase.result$
        @emlPhrase: "posthoc.intent", "Tukey HSD", "0.05", .alphaSrc$,
        ... "", "", ""
        .intent$ = .intent$ + newline$ + emlPhrase.result$
    endif

    ; --- caveat. Stream C: one static string per wrapper, defined beside the
    ; wrapper it describes, because that is where it goes stale if the
    ; wrapper changes. This path runs Brown-Forsythe but never tests
    ; normality, and a reader has no way to know that from the output.
    .caveat$ = "Normality was NOT tested on this path."
    if emlOneWayAnova.warning$ <> ""
        .caveat$ = .caveat$ + newline$ + emlOneWayAnova.warning$
    endif

    ; --- code. Resolved values only. A record saying a field was left at its
    ; default is not reproducible once the default changes; a record saying
    ; 0.05 is.
    if .doTukey
        .tukey$ = "1"
    else
        .tukey$ = "0"
    endif
    ; ------------------------------------------------------------------
    ; EMITTED AT THE API LEVEL, WHICH IS WHY THIS FILE RE-RUNS AT ALL.
    ;
    ; A wrapper-level `runScript:` call does not work, and a probe script
    ; with a `form: ... endform` block does not show that it does: NO EML
    ; WRAPPER HAS ONE. Every wrapper uses `beginPause:`. Measured against a
    ; real plugin tree:
    ;
    ;   runScript: ".../eml-compare-k-groups.praat", "SPL_dB", "voice_type", 1
    ;     -> Error: Found 3 arguments but expected only 0.
    ;   runScript: ".../eml-compare-k-groups.praat"   (Table selected)
    ;     -> Gtk-ERROR: Can't create a GtkStyleContext without a display
    ;
    ; And `beginPause:` cannot be converted to `form:` either, because a
    ; form is parsed once and cannot hold the loop that builds the column
    ; menus from the table:
    ;
    ;   Error: Unknown parameter type inside form: "for i from 1 to n".
    ;
    ; The orchestrator has no dialogs at all, so calling IT is the whole
    ; answer. Measured, same session, headless:
    ;
    ;   include <plugin>/stats/... ; @emlRunAnovaAnalysis: table, ...
    ;     -> exit 0, F = 18.0603 — the number the recorder captured.
    ;
    ; This is also what makes §9's round trip achievable without touching a
    ; single wrapper: the emitted file calls the same procedure the GUI
    ; called, so diffing the two Info outputs tests exactly the claim that
    ; the log and the analysis agree.
    ; ------------------------------------------------------------------
    .code$ = "@emlRunAnovaAnalysis: data, """ + .dataCol$ + """, """
    ... + .groupCol$ + """, " + .tukey$

    ; The API line IS the code now, so the api slot names the GUI route
    ; instead — the one thing the emitted file cannot show by running.
    .api$ = "In the GUI: New > EML Tools > Compare k groups (ANOVA)...,"
    ... + newline$ + "with Data column """ + .dataCol$
    ... + """ and Group column """ + .groupCol$ + """."

    @emlRecordStep: "analysis", .intent$, .caveat$, .code$, .api$

    ; --- results, Stream A. Same variables the reporter printed.
    @emlRecordResult: "F(" + string$ (emlOneWayAnova.dfBetween) + ", "
    ... + string$ (emlOneWayAnova.dfWithin) + ") = "
    ... + fixed$ (emlOneWayAnova.fValue, 4) + ", p = "
    ... + fixed$ (emlOneWayAnova.p, 4) + ", eta-squared = "
    ... + fixed$ (emlOneWayAnova.etaSquared, 4)
    for .g from 1 to emlOneWayAnova.nGroups
        @emlRecordResult: "  " + emlOneWayAnova.groupLabel$[.g] + ": n = "
        ... + string$ (emlOneWayAnova.groupN[.g]) + ", mean = "
        ... + fixed$ (emlOneWayAnova.groupMean[.g], 4)
    endfor

    label END_RECORD_ANOVA
endproc


# ============================================================================
#
#  3. KRUSKAL-WALLIS
#
# ============================================================================

procedure emlRunKWAnalysis: .tableId, .dataCol$, .groupCol$, .doDunn, .adjMethod$
    .recResult$ = ""
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlCountGroups: .tableId, .groupCol$
    ; BLANK GROUP CELLS ARE MISSING DATA, not a category -- see
    ; @emlCountGroups. Captured immediately, because every
    ; post-hoc procedure re-invokes @emlCountGroups and would clobber it, and
    ; surfaced in the wording this tree already uses for excluded rows.
    .nBlankGroup = emlCountGroups.nBlankRows
    if .nBlankGroup > 0
        appendInfoLine: "  Note: ", .nBlankGroup,
        ... " row(s) excluded -- the group column is empty for them."
    endif
    if emlCountGroups.error$ <> ""
        .error$ = emlCountGroups.error$
        goto END_KW
    endif
    .nGroups = emlCountGroups.nGroups
    if .nGroups < 2
        .error$ = "Group column """ + .groupCol$ + """ has fewer than 2 groups."
        goto END_KW
    endif

    ; See the note in @emlRunTwoGroupAnalysis.
    @emlRequireNumericColumn: .tableId, "Data column", .dataCol$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_KW
    endif

    @emlKruskalWallis: .tableId, .dataCol$, .groupCol$
    ; CAPTURED AT THE TEST, not at the end label. A Praat procedure's outputs
    ; live only until it runs again, and everything downstream of here reads
    ; emlKruskalWallis' namespace -- so the capture belongs where the values
    ; are still unambiguously this comparison's. (@emlReportKWComparison and
    ; @emlDeclareKWResult do not re-invoke the test; the rule is about any
    ; procedure that might, which is what someone placing a declare call has
    ; to reason about.)
    if emlKruskalWallis.error$ = ""
        .recResult$ = "H(" + string$ (emlKruskalWallis.df) + ") = "
        ... + fixed$ (emlKruskalWallis.h, 4) + ", p = "
        ... + fixed$ (emlKruskalWallis.p, 4)
    endif
    if emlKruskalWallis.error$ <> ""
        .error$ = emlKruskalWallis.error$
        goto END_KW
    endif

    if .doDunn
        @emlDunnTest: .tableId, .dataCol$, .groupCol$, .adjMethod$
        if emlDunnTest.error$ = ""
            emlKruskalWallis.rMatrix## = emlDunnTest.rMatrix##
        endif
    endif

    # Ensure pairwise rank-biserial r matrix always exists
    # (when Dunn ran successfully, rMatrix was already copied above)
    .needRMatrix = 1
    if .doDunn
        if emlDunnTest.error$ = ""
            .needRMatrix = 0
        endif
    endif
    if .needRMatrix
        emlKruskalWallis.rMatrix## = zero## (.nGroups, .nGroups)
        for .i from 1 to .nGroups - 1
            @eml_getGroupData: .tableId, .dataCol$, .groupCol$, emlKruskalWallis.groupName$[.i]
            .vi# = eml_getGroupData.data#
            for .j from .i + 1 to .nGroups
                @eml_getGroupData: .tableId, .dataCol$, .groupCol$, emlKruskalWallis.groupName$[.j]
                @emlRankBiserialR: .vi#, eml_getGroupData.data#, 2
                if emlRankBiserialR.error$ = ""
                    emlKruskalWallis.rMatrix## [.i, .j] = emlRankBiserialR.r
                    emlKruskalWallis.rMatrix## [.j, .i] = -emlRankBiserialR.r
                endif
            endfor
        endfor
    endif

    @emlCSVInit
    @emlReportKWComparison: .tableName$, .dataCol$, .groupCol$, .tableId, .nGroups, .doDunn

    if .error$ = ""
        @emlResultClearExtras
        ; NESTED, NOT `and`. Praat evaluates BOTH operands of `and`, so
        ; `if .doNon and emlX.error$ = ""` reads emlX's namespace even when
        ; .doNon is 0 -- and on a single-family run that namespace does not
        ; exist, which aborts the script before any wrapper code. Only a
        ; "both" run survives an `and` here, and "both" is what a driver that
        ; does not vary the family exercises.
        if .doDunn = 1
            if variableExists ("emlDunnTest.error$")
                if emlDunnTest.error$ = ""
                    @emlDeclareDunnResult: .groupCol$
                    @emlResultStageExtra: "posthoc"
                endif
            endif
        endif
        @emlDeclareKWResult: .tableName$, .dataCol$, .groupCol$
    endif

    label END_KW

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Kruskal-Wallis",
        ... .dataCol$ + " by " + .groupCol$,
        ... "Rank-based; it does not assume normality and does not test it.",
        ... "@emlRunKWAnalysis: data, """ + .dataCol$ + """, """ + .groupCol$ + """, " + string$ (.doDunn) + ", """ + .adjMethod$ + """",
        ... "In the GUI: New > EML Tools > Compare k groups (Kruskal-Wallis)...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc


# ============================================================================
#
#  4. PAIRWISE COMPARISONS
#
# ============================================================================

procedure emlRunPairwiseAnalysis: .tableId, .dataCol$, .groupCol$, .test$, .adjMethod$
    .recResult$ = ""
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlCountGroups: .tableId, .groupCol$
    ; BLANK GROUP CELLS ARE MISSING DATA, not a category -- see
    ; @emlCountGroups. Captured immediately, because every
    ; post-hoc procedure re-invokes @emlCountGroups and would clobber it, and
    ; surfaced in the wording this tree already uses for excluded rows.
    .nBlankGroup = emlCountGroups.nBlankRows
    if .nBlankGroup > 0
        appendInfoLine: "  Note: ", .nBlankGroup,
        ... " row(s) excluded -- the group column is empty for them."
    endif
    if emlCountGroups.error$ <> ""
        .error$ = emlCountGroups.error$
        goto END_PAIRWISE
    endif
    ; CAPTURED HERE. @emlCountGroups is re-invoked inside every post-hoc
    ; procedure below -- the hazard @emlBridgeGroupComparison documents at
    ; length -- so .nGroups must be taken now or not at all.
    .recGroups = emlCountGroups.nGroups
    if emlCountGroups.nGroups < 2
        .error$ = "Group column """ + .groupCol$ + """ has fewer than 2 groups."
        goto END_PAIRWISE
    endif

    ; THE DATA-COLUMN GUARD. @emlPairwiseT has none of its own: pointed at a
    ; column that is not in the table it returns an empty error$ and prints a
    ; full comparison matrix of "n/a". This is the shared guard, and
    ; @emlPairwiseT, @emlPairwiseWilcoxon and @emlScheffe ask it too, so a
    ; script calling those three directly gets the same refusal rather than
    ; an empty error$ from the first two and a sentence about within-groups
    ; degrees of freedom from the third. Wording is @emlOneWayAnova's,
    ; verbatim.
    @emlRequireColumnPresent: .tableId, "Data column", .dataCol$
    if emlRequireColumnPresent.error$ <> ""
        .error$ = emlRequireColumnPresent.error$
        goto END_PAIRWISE
    endif

    ; See the note in @emlRunTwoGroupAnalysis.
    @emlRequireNumericColumn: .tableId, "Data column", .dataCol$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_PAIRWISE
    endif

    if .test$ = "welch" or .test$ = "student"
        if .test$ = "welch"
            .tType$ = "welch"
        else
            .tType$ = "student"
        endif
        selectObject: .tableId
        @emlPairwiseT: .tableId, .dataCol$, .groupCol$, .adjMethod$, .tType$
        if emlPairwiseT.error$ <> ""
            .error$ = emlPairwiseT.error$
            goto END_PAIRWISE
        endif
    elsif .test$ = "wilcoxon"
        selectObject: .tableId
        @emlPairwiseWilcoxon: .tableId, .dataCol$, .groupCol$, .adjMethod$
        if emlPairwiseWilcoxon.error$ <> ""
            .error$ = emlPairwiseWilcoxon.error$
            goto END_PAIRWISE
        endif
    elsif .test$ = "scheffe"
        selectObject: .tableId
        @emlScheffe: .tableId, .dataCol$, .groupCol$
        if emlScheffe.error$ <> ""
            .error$ = emlScheffe.error$
            goto END_PAIRWISE
        endif
    else
        .error$ = "Unknown pairwise test: """ + .test$ + """"
        goto END_PAIRWISE
    endif

    @emlCSVInit
    ; .tableId leads the argument list because the reporter now prints the
    ; per-group n / mean / SD and has to re-read the column to do it.
    @emlReportPairwiseComparison: .tableId, .tableName$, .dataCol$, .groupCol$,
    ... .test$, .adjMethod$

    ; BUILD, not a conversion: an orchestrator that calls @emlCSVInit and
    ; adds no row cannot export at all.
    if .error$ = ""
        @emlResultClearExtras
        @emlDeclarePairwiseResult: .tableName$, .groupCol$, .test$, .adjMethod$
    endif

    ; A pairwise family has no single statistic; it has a shape. What a
    ; reader needs from the record is which test, which correction, and over
    ; how many comparisons -- the family size is what makes an adjusted p
    ; interpretable, and the per-pair table is in the Info report.
    if .error$ = ""
        .recResult$ = .test$ + " with " + .adjMethod$ + " correction over "
        ... + string$ (.recGroups * (.recGroups - 1) / 2) + " pairwise "
        ... + "comparison(s), " + string$ (.recGroups) + " groups"
    endif

    label END_PAIRWISE

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Pairwise comparisons",
        ... .dataCol$ + " by " + .groupCol$ + ", " + .test$ + ", " + .adjMethod$,
        ... "The adjustment named here was APPLIED, not only labelled.",
        ... "@emlRunPairwiseAnalysis: data, """ + .dataCol$ + """, """ + .groupCol$ + """, """ + .test$ + """, """ + .adjMethod$ + """",
        ... "In the GUI: New > EML Tools > Pairwise comparisons...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc


# ============================================================================
# @emlAdjustMethodDisplay — display casing for a p-adjustment key
# ============================================================================
# The key travels through the plugin lowercase ("bonferroni", "holm", "bh")
# because that is what @emlPairwiseT, @emlHolm and R's p.adjust all accept.
# Interpolating it straight into a report heading produced
#   Pairwise Welch t-test (bonferroni adjustment)
# which matches neither the "Bonferroni" the user picked in the optionmenu
# nor any way a reader would write Benjamini-Hochberg.
#
# This is DISPLAY ONLY. Nothing may branch on .name$ — the lowercase key
# stays canonical everywhere a comparison is made.
#
# NAME. The obvious name @emlAdjustMethodName is already defined in
# graphs/eml-graphs-form.praat, where it maps an optionmenu INDEX to the
# lowercase key. Praat resolves a duplicated procedure name to whichever
# definition it meets first, and scripts/eml-lib.praat includes THIS file
# before eml-graphs-form.praat — so defining that name here would silently
# capture the graphs form's integer calls and pass a number into a string
# parameter. Hence the distinct name.
#
# Arguments:
#   .key$  — "bonferroni", "holm" or "bh" (surrounding space tolerated)
# Output:
#   .name$ — "Bonferroni", "Holm", "Benjamini-Hochberg". An unrecognised key
#            is returned unchanged, so a new method shows up in the report
#            rather than being silently renamed to a wrong one.
# ============================================================================
procedure emlAdjustMethodDisplay: .key$
    .trimmed$ = replace_regex$ (.key$, "^\s+|\s+$", "", 0)
    if .trimmed$ = "bonferroni" or .trimmed$ = "Bonferroni"
        .name$ = "Bonferroni"
    elsif .trimmed$ = "holm" or .trimmed$ = "Holm"
        .name$ = "Holm"
    elsif .trimmed$ = "bh" or .trimmed$ = "BH" or .trimmed$ = "Bh"
        .name$ = "Benjamini-Hochberg"
    elsif .trimmed$ = "none" or .trimmed$ = "None"
        .name$ = "none"
    else
        .name$ = .trimmed$
    endif
endproc


# ============================================================================
# @emlReportAlpha — the alpha the report marks significance against
# ============================================================================
# No stats dialog in the plugin collects an alpha; only the graphing form
# does (annotAlpha). A report that marks significance must nevertheless say
# what it marked against, so this returns the criterion in force: a caller's
# global emlAlpha when one has been set to a usable value, otherwise .05.
#
# Output:
#   .value — the alpha, as a number
#   .text$ — the same value formatted for printing
# ============================================================================
procedure emlReportAlpha
    .value = 0.05
    if variableExists ("emlAlpha")
        if emlAlpha <> undefined and emlAlpha > 0 and emlAlpha < 1
            .value = emlAlpha
        endif
    endif
    ; Three decimals so .001 and .010 survive, then trailing zeros trimmed
    ; back to two places so the ordinary case reads "0.05" and not "0.050".
    .text$ = fixed$ (.value, 3)
    while right$ (.text$, 1) = "0" and length (.text$) > 4
        .text$ = left$ (.text$, length (.text$) - 1)
    endwhile
endproc


# ============================================================================
# @emlInlineP — a p-value inside a running sentence
# ============================================================================
# @emlReportPWithExact prints a LABELLED ROW. The repeated-measures and
# Friedman reporters do not print rows — they compose one line per test
# ("F(2, 38) = 583.1232, p = ...") — so they cannot call it, and they instead
# reached for fixed$ (p, 4), which renders a p of 3e-29 as twenty-nine
# decimal places. This is the same rendering @emlReportPWithExact applies,
# returned as a string a caller can concatenate.
#
# Arguments:
#   .pValue — the p-value
# Output:
#   .text$  — "p = .032" / "p < .001  (3.0114e-29)", i.e. the APA form with
#             the unrounded value appended only when the APA form floored it
#   .bare$  — the same without the leading "p = ", for a caller whose own
#             label already names which p this is ("p(adj) = ...")
# ============================================================================
procedure emlInlineP: .pValue
    @emlFormatP: .pValue
    .text$ = emlFormatP.formatted$
    .bare$ = emlFormatP.bare$
    if emlFormatP.exact$ <> ""
        .suffix$ = "  (" + emlFormatP.exact$ + ")"
        .text$ = .text$ + .suffix$
        .bare$ = .bare$ + .suffix$
    endif
endproc


# ============================================================================
# @emlSigMark — significance marker for one p-value
# ============================================================================
# Output: .mark$ — " *" when the p-value clears alpha, "" otherwise, "" for
#                  an undefined p (a comparison that could not be made is
#                  missing, not significant).
# ============================================================================
procedure emlSigMark: .pValue, .alpha
    if .pValue = undefined
        .mark$ = ""
    elsif .pValue < .alpha
        .mark$ = " *"
    else
        .mark$ = ""
    endif
endproc


# ============================================================================
# @emlPadCell — fixed-width column cell for the fixed-pitch report tables
# ============================================================================
# @emlPadRight pads but never truncates, so one long group label shifts every
# column to its right. These tables are read down the column, so a cell that
# overflows is worse than one that is cut: truncate to width-1 and always
# leave at least one separating space.
# ============================================================================
procedure emlPadCell: .text$, .width
    .out$ = .text$
    if length (.out$) > .width - 1
        .out$ = left$ (.out$, .width - 1)
    endif
    while length (.out$) < .width
        .out$ = .out$ + " "
    endwhile
    .result$ = .out$
endproc


# ============================================================================
# @emlReportPairwiseDescriptives — n, mean and SD per group
# ============================================================================
# The pairwise report handed the reader Cohen's d for every pair and never
# printed a single input to it: no group n, no group mean, no group SD. The
# CSV carried all of them, so the numbers were in hand and simply not shown.
#
# Group labels and their ORDER come from @emlCountGroups, which is the same
# procedure and the same table @emlPairwiseT / @emlPairwiseWilcoxon /
# @emlScheffe build their matrices, so row i here is group i there.
#
# Arguments:
#   .tableId, .dataCol$, .groupCol$ — as passed to the test
# ============================================================================
procedure emlReportPairwiseDescriptives: .tableId, .dataCol$, .groupCol$
    @emlCountGroups: .tableId, .groupCol$
    ; BLANK GROUP CELLS ARE MISSING DATA, not a category -- see
    ; @emlCountGroups. Captured immediately, because every
    ; post-hoc procedure re-invokes @emlCountGroups and would clobber it, and
    ; surfaced in the wording this tree already uses for excluded rows.
    .nBlankGroup = emlCountGroups.nBlankRows
    if .nBlankGroup > 0
        appendInfoLine: "  Note: ", .nBlankGroup,
        ... " row(s) excluded -- the group column is empty for them."
    endif
    if emlCountGroups.error$ <> ""
        goto PAIR_DESCR_DONE
    endif
    .k = emlCountGroups.nGroups

    @emlReportBlank
    @emlReportSection: "Group descriptives"
    appendInfoLine: ""
    @emlPadCell: "Group", 20
    .hdr$ = "  " + emlPadCell.result$
    @emlPadCell: "n", 7
    .hdr$ = .hdr$ + emlPadCell.result$
    @emlPadCell: "Mean", 13
    .hdr$ = .hdr$ + emlPadCell.result$
    .hdr$ = .hdr$ + "SD"
    appendInfoLine: .hdr$

    for .g from 1 to .k
        ; The LITERAL label, not an underscore-stripped prettification.
        ; This is a value the user has to type into a form or match against
        ; the table, so it is printed exactly as it is stored.
        .label$ = emlCountGroups.groupLabel$ [.g]
        @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .label$
        if eml_getGroupData.error$ <> ""
            .nG = 0
            .meanTxt$ = "n/a"
            .sdTxt$ = "n/a"
        else
            .nG = eml_getGroupData.n
            @emlMean: eml_getGroupData.data#
            @emlSD: eml_getGroupData.data#
            ; Every rounded number the report prints
            ; goes through @eml_fixed (stats/eml-output.praat) and not through
            ; fixed$, because Praat's fixed$ is a MINIMUM-significance
            ; formatter wearing a fixed-precision name: it returns the LARGER
            ; of the precision asked for and however many decimals are needed
            ; to show one significant digit, and a bare "0" for an exact zero.
            ; Measured on 6.6.30 -- fixed$ (-1e-16, 4) is
            ; "-0.0000000000000001" and fixed$ (0, 4) is "0". A group mean of
            ; zero would otherwise print as "0" in a column of "2.5000"s, and
            ; a mean a few ulps off zero would print seventeen digits of
            ; arithmetic
            ; noise. @eml_fixed keeps fixed$'s answer whenever fixed$ honoured
            ; the request, so every value that already printed correctly still
            ; prints identically. Nothing computed moves and the CSV export is
            ; untouched -- it uses string$ and keeps full precision on purpose.
            if emlMean.result = undefined
                .meanTxt$ = "n/a"
            else
                @eml_fixed: emlMean.result, 4
                .meanTxt$ = eml_fixed.result$
            endif
            if emlSD.result = undefined
                .sdTxt$ = "n/a"
            else
                @eml_fixed: emlSD.result, 4
                .sdTxt$ = eml_fixed.result$
            endif
        endif
        @emlPadCell: .label$, 20
        .row$ = "  " + emlPadCell.result$
        @emlPadCell: string$ (.nG), 7
        .row$ = .row$ + emlPadCell.result$
        @emlPadCell: .meanTxt$, 13
        .row$ = .row$ + emlPadCell.result$
        .row$ = .row$ + .sdTxt$
        appendInfoLine: .row$
    endfor

    label PAIR_DESCR_DONE
endproc


# ============================================================================
# @emlReportPairwiseComparison
# Extracted from inline code in eml-pairwise.praat.
# ============================================================================
# WHAT THE REPORT CARRIES, AND WHY:
#
#   * n, mean and SD per group, so d is not reported without its inputs.
#   * t and df per pair. For Welch, df is fractional and differs per pair,
#     and without it the result cannot be re-tested.
#   * BOTH the raw and the adjusted p, each labelled, under a heading that
#     names the method.
#   * Significant pairs carry "*", and the alpha that marks them is echoed in
#     the header block and again in the legend.
#   * The Cohen's d matrix is ANTISYMMETRIC, because the sign carries the
#     direction of the difference, and the convention is stated under the
#     matrix that uses it -- read in the same idiom as the symmetric p matrix
#     above, a negative d reads as a negative effect size.
#   * The adjustment method is title-cased for display through
#     @emlAdjustMethodDisplay, so the heading matches the optionmenu.
#   * Table, column and group names print LITERALLY, not underscore-stripped
#     (F0_Hz -> "F0 Hz", demo_3groups -> "demo 3groups"), which would rename
#     the user's data in the one place they need to copy it back out of.
#     Underscore-to-space is a Picture window convention (Rule 28B); it does
#     not belong in plain text that names something the user has to type or
#     select.
#
# Arguments:
#   .tableId — the table the test ran on. Required for the per-group
#              descriptives, which re-read the column.
# ============================================================================

procedure emlReportPairwiseComparison: .tableId, .tableName$, .dataCol$, .groupCol$, .test$, .adjMethod$
    @emlReportAlpha
    .alpha = emlReportAlpha.value
    .alphaText$ = emlReportAlpha.text$
    @emlAdjustMethodDisplay: .adjMethod$
    .adjLabel$ = emlAdjustMethodDisplay.name$

    if .test$ = "welch" or .test$ = "student"
        # emlPairwiseT.method$ is the ADJUSTMENT method (bonferroni/holm/bh),
        # not the name of the test -- using it here gives a header reading
        # "Pairwise holm (holm adjustment)". The test is .test$
        # (welch/student), which this reporter receives.
        if .test$ = "welch"
            .testLabel$ = "Welch t-test"
        else
            .testLabel$ = "Student t-test"
        endif
        .methodLabel$ = "Pairwise " + .testLabel$ + " (" + .adjLabel$
            ... + " adjustment)"
        .nGroups = emlPairwiseT.nGroups

        @emlReportHeader: .methodLabel$
        @emlReportLineString: "Table", .tableName$
        @emlReportLineString: "Data column", .dataCol$
        @emlReportLineString: "Group column", .groupCol$
        @emlReportLine: "Groups", .nGroups, 0
        @emlReportLine: "Pairs tested", emlPairwiseT.nPairs, 0
        @emlReportLineString: "p adjustment", .adjLabel$
        @emlReportLineString: "Alpha", .alphaText$

        @emlReportPairwiseDescriptives: .tableId, .dataCol$, .groupCol$

        @emlReportBlank
        @emlReportSection: "Per-pair results"
        appendInfoLine: ""
        @emlPadCell: "Comparison", 26
        .hdr$ = "  " + emlPadCell.result$
        @emlPadCell: "t (df)", 20
        .hdr$ = .hdr$ + emlPadCell.result$
        @emlPadCell: "p (raw)", 11
        .hdr$ = .hdr$ + emlPadCell.result$
        @emlPadCell: "p (adj)", 11
        .hdr$ = .hdr$ + emlPadCell.result$
        .hdr$ = .hdr$ + "d"
        appendInfoLine: .hdr$

        .pair = 0
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .pair = .pair + 1
                .cmp$ = emlPairwiseT.groupName$ [.iGroup] + " vs "
                    ... + emlPairwiseT.groupName$ [.jGroup]
                .tVal = emlPairwiseT.tMatrix## [.iGroup, .jGroup]
                .dfVal = emlPairwiseT.dfMatrix## [.iGroup, .jGroup]
                if .tVal = undefined or .dfVal = undefined
                    .statTxt$ = "not computed"
                else
                    ; Two identical groups give t = 0 exactly, and
                    ; fixed$ (0, 3) is "0" -- the reported symptom, a bare
                    ; zero in a three-decimal column. @eml_fixed prints
                    ; "0.000". See @emlReportPairwiseDescriptives above.
                    @eml_fixed: .tVal, 3
                    .statTxt$ = eml_fixed.result$ + " ("
                    @eml_fixed: .dfVal, 2
                    .statTxt$ = .statTxt$ + eml_fixed.result$ + ")"
                endif
                @emlFormatP: emlPairwiseT.rawP# [.pair]
                .rawTxt$ = emlFormatP.bare$
                .adjP = emlPairwiseT.adjustedP# [.pair]
                @emlFormatP: .adjP
                .adjTxt$ = emlFormatP.bare$
                .dVal = emlPairwiseT.dMatrix## [.iGroup, .jGroup]
                if .dVal = undefined
                    .dTxt$ = "n/a"
                else
                    ; A Cohen's d of no difference is zero, which
                    ; fixed$ renders as a bare "0".
                    @eml_fixed: .dVal, 3
                    .dTxt$ = eml_fixed.result$
                endif
                @emlSigMark: .adjP, .alpha
                @emlPadCell: .cmp$, 26
                .row$ = "  " + emlPadCell.result$
                @emlPadCell: .statTxt$, 20
                .row$ = .row$ + emlPadCell.result$
                @emlPadCell: .rawTxt$, 11
                .row$ = .row$ + emlPadCell.result$
                @emlPadCell: .adjTxt$, 11
                .row$ = .row$ + emlPadCell.result$
                .row$ = .row$ + .dTxt$ + emlSigMark.mark$
                appendInfoLine: .row$
            endfor
        endfor
        appendInfoLine: "  * adjusted p < ", .alphaText$,
            ... ". d is Cohen's d, first group minus second."

        @emlReportBlank
        @emlReportSection: "Adjusted p-values (" + .adjLabel$ + ")"
        appendInfoLine: ""
        .headerLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            @emlPadCell: emlPairwiseT.groupName$ [.jGroup], 12
            .headerLine$ = .headerLine$ + emlPadCell.result$
        endfor
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            @emlPadCell: emlPairwiseT.groupName$ [.iGroup], 14
            .rowLine$ = emlPadCell.result$
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .pVal = emlPairwiseT.pMatrix## [.iGroup, .jGroup]
                    @emlFormatP: .pVal
                    @emlSigMark: .pVal, .alpha
                    .cellText$ = emlFormatP.bare$ + emlSigMark.mark$
                endif
                @emlPadCell: .cellText$, 12
                .rowLine$ = .rowLine$ + emlPadCell.result$
            endfor
            appendInfoLine: .rowLine$
        endfor
        appendInfoLine: "  Symmetric: the p for A vs B is the p for B vs A."
        appendInfoLine: "  * adjusted p < ", .alphaText$

        @emlReportBlank
        @emlReportSection: "Cohen's d (effect sizes)"
        appendInfoLine: ""
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            @emlPadCell: emlPairwiseT.groupName$ [.iGroup], 14
            .rowLine$ = emlPadCell.result$
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .dVal = emlPairwiseT.dMatrix## [.iGroup, .jGroup]
                    if .dVal = undefined
                        .cellText$ = "n/a"
                    else
                        ; As in the per-pair table above. A sweep
                        ; matrix is read DOWN the column, so one cell of a
                        ; different width is the worst place for this.
                        @eml_fixed: .dVal, 3
                        .cellText$ = eml_fixed.result$
                    endif
                endif
                @emlPadCell: .cellText$, 12
                .rowLine$ = .rowLine$ + emlPadCell.result$
            endfor
            appendInfoLine: .rowLine$
        endfor
        ; Unlike the p matrix above, this one is ANTISYMMETRIC: the
        ; sign is the direction of the difference, not the sign of the
        ; effect. Say so, under the matrix it applies to.
        appendInfoLine: "  Row minus column: a negative d means the ROW "
            ... + "group's mean is"
        appendInfoLine: "  lower than the COLUMN group's. |d| is the "
            ... + "effect size."

    elsif .test$ = "wilcoxon"
        .methodLabel$ = "Pairwise Wilcoxon/Mann-Whitney (" + .adjLabel$
            ... + " adjustment)"
        .nGroups = emlPairwiseWilcoxon.nGroups

        @emlReportHeader: .methodLabel$
        @emlReportLineString: "Table", .tableName$
        @emlReportLineString: "Data column", .dataCol$
        @emlReportLineString: "Group column", .groupCol$
        @emlReportLine: "Groups", .nGroups, 0
        @emlReportLine: "Pairs tested", emlPairwiseWilcoxon.nPairs, 0
        @emlReportLineString: "p adjustment", .adjLabel$
        @emlReportLineString: "Alpha", .alphaText$

        @emlReportPairwiseDescriptives: .tableId, .dataCol$, .groupCol$

        @emlReportBlank
        @emlReportSection: "Per-pair results"
        appendInfoLine: ""
        @emlPadCell: "Comparison", 26
        .hdr$ = "  " + emlPadCell.result$
        @emlPadCell: "U", 20
        .hdr$ = .hdr$ + emlPadCell.result$
        @emlPadCell: "p (raw)", 11
        .hdr$ = .hdr$ + emlPadCell.result$
        @emlPadCell: "p (adj)", 11
        .hdr$ = .hdr$ + emlPadCell.result$
        .hdr$ = .hdr$ + "r"
        appendInfoLine: .hdr$

        .pair = 0
        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .pair = .pair + 1
                .cmp$ = emlPairwiseWilcoxon.groupName$ [.iGroup] + " vs "
                    ... + emlPairwiseWilcoxon.groupName$ [.jGroup]
                .uVal = emlPairwiseWilcoxon.uMatrix## [.iGroup, .jGroup]
                if .uVal = undefined
                    .statTxt$ = "not computed"
                else
                    ; U is zero when every value of one group
                    ; outranks every value of the other -- the most extreme
                    ; result the statistic has, printed as a bare "0".
                    @eml_fixed: .uVal, 2
                    .statTxt$ = eml_fixed.result$
                endif
                @emlFormatP: emlPairwiseWilcoxon.rawP# [.pair]
                .rawTxt$ = emlFormatP.bare$
                .adjP = emlPairwiseWilcoxon.adjustedP# [.pair]
                @emlFormatP: .adjP
                .adjTxt$ = emlFormatP.bare$
                .rVal = emlPairwiseWilcoxon.rMatrix## [.iGroup, .jGroup]
                if .rVal = undefined
                    .rTxt$ = "n/a"
                else
                    ; Rank-biserial r is zero for two groups that
                    ; interleave perfectly.
                    @eml_fixed: .rVal, 3
                    .rTxt$ = eml_fixed.result$
                endif
                @emlSigMark: .adjP, .alpha
                @emlPadCell: .cmp$, 26
                .row$ = "  " + emlPadCell.result$
                @emlPadCell: .statTxt$, 20
                .row$ = .row$ + emlPadCell.result$
                @emlPadCell: .rawTxt$, 11
                .row$ = .row$ + emlPadCell.result$
                @emlPadCell: .adjTxt$, 11
                .row$ = .row$ + emlPadCell.result$
                .row$ = .row$ + .rTxt$ + emlSigMark.mark$
                appendInfoLine: .row$
            endfor
        endfor
        appendInfoLine: "  * adjusted p < ", .alphaText$,
            ... ". U is for the first group of the pair."

        @emlReportBlank
        @emlReportSection: "Adjusted p-values (" + .adjLabel$ + ")"
        appendInfoLine: ""
        .headerLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            @emlPadCell: emlPairwiseWilcoxon.groupName$ [.jGroup], 12
            .headerLine$ = .headerLine$ + emlPadCell.result$
        endfor
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            @emlPadCell: emlPairwiseWilcoxon.groupName$ [.iGroup], 14
            .rowLine$ = emlPadCell.result$
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .pVal = emlPairwiseWilcoxon.pMatrix## [.iGroup, .jGroup]
                    @emlFormatP: .pVal
                    @emlSigMark: .pVal, .alpha
                    .cellText$ = emlFormatP.bare$ + emlSigMark.mark$
                endif
                @emlPadCell: .cellText$, 12
                .rowLine$ = .rowLine$ + emlPadCell.result$
            endfor
            appendInfoLine: .rowLine$
        endfor
        appendInfoLine: "  Symmetric: the p for A vs B is the p for B vs A."
        appendInfoLine: "  * adjusted p < ", .alphaText$

        @emlReportBlank
        @emlReportSection: "Rank-biserial r (effect sizes)"
        appendInfoLine: ""
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            @emlPadCell: emlPairwiseWilcoxon.groupName$ [.iGroup], 14
            .rowLine$ = emlPadCell.result$
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .rVal = emlPairwiseWilcoxon.rMatrix## [.iGroup, .jGroup]
                    if .rVal = undefined
                        .cellText$ = "n/a"
                    else
                        ; As in the per-pair table above.
                        @eml_fixed: .rVal, 3
                        .cellText$ = eml_fixed.result$
                    endif
                endif
                @emlPadCell: .cellText$, 12
                .rowLine$ = .rowLine$ + emlPadCell.result$
            endfor
            appendInfoLine: .rowLine$
        endfor
        ; Same convention as the d matrix above.
        appendInfoLine: "  Row minus column: a negative r means the ROW "
            ... + "group ranks"
        appendInfoLine: "  lower than the COLUMN group. |r| is the effect "
            ... + "size."

    elsif .test$ = "scheffe"
        .nGroups = emlScheffe.nGroups

        @emlReportHeader: "Scheffe Post-Hoc Comparisons"
        @emlReportLineString: "Table", .tableName$
        @emlReportLineString: "Data column", .dataCol$
        @emlReportLineString: "Group column", .groupCol$
        @emlReportLine: "Groups", .nGroups, 0
        @emlReportLine: "Pairs tested", emlScheffe.nPairs, 0
        @emlReportLine: "MSE", emlScheffe.mse, 4
        @emlReportLine: "df (within)", emlScheffe.dfWithin, 0
        ; Scheffe's p IS familywise-controlled; there is no separate
        ; adjustment step and therefore no raw p to show beside it.
        @emlReportLineString: "p adjustment", "Scheffe (familywise, built in)"
        @emlReportLineString: "Alpha", .alphaText$

        @emlReportPairwiseDescriptives: .tableId, .dataCol$, .groupCol$

        @emlReportBlank
        @emlReportSection: "Per-pair results"
        appendInfoLine: ""
        @emlPadCell: "Comparison", 26
        .hdr$ = "  " + emlPadCell.result$
        @emlPadCell: "F (df)", 20
        .hdr$ = .hdr$ + emlPadCell.result$
        @emlPadCell: "p", 11
        .hdr$ = .hdr$ + emlPadCell.result$
        .hdr$ = .hdr$ + "Mean diff"
        appendInfoLine: .hdr$

        for .iGroup from 1 to .nGroups - 1
            for .jGroup from .iGroup + 1 to .nGroups
                .cmp$ = emlScheffe.groupName$ [.iGroup] + " vs "
                    ... + emlScheffe.groupName$ [.jGroup]
                .fVal = emlScheffe.fMatrix## [.iGroup, .jGroup]
                if .fVal = undefined
                    .statTxt$ = "not computed"
                else
                    ; Scheffe's F is zero for two groups with the same mean,
                    ; which is the case this most often arises on.
                    @eml_fixed: .fVal, 3
                    .statTxt$ = eml_fixed.result$ + " ("
                        ... + string$ (.nGroups - 1) + ", "
                        ... + string$ (emlScheffe.dfWithin) + ")"
                endif
                .pVal = emlScheffe.pMatrix## [.iGroup, .jGroup]
                @emlFormatP: .pVal
                .pTxt$ = emlFormatP.bare$
                .diffVal = emlScheffe.diffMatrix## [.iGroup, .jGroup]
                if .diffVal = undefined
                    .diffTxt$ = "n/a"
                else
                    ; A mean difference of zero is the whole point
                    ; of the row it sits in.
                    @eml_fixed: .diffVal, 3
                    .diffTxt$ = eml_fixed.result$
                endif
                @emlSigMark: .pVal, .alpha
                @emlPadCell: .cmp$, 26
                .row$ = "  " + emlPadCell.result$
                @emlPadCell: .statTxt$, 20
                .row$ = .row$ + emlPadCell.result$
                @emlPadCell: .pTxt$, 11
                .row$ = .row$ + emlPadCell.result$
                .row$ = .row$ + .diffTxt$ + emlSigMark.mark$
                appendInfoLine: .row$
            endfor
        endfor
        appendInfoLine: "  * p < ", .alphaText$,
            ... ". Mean diff is first group minus second."

        @emlReportBlank
        @emlReportSection: "Scheffe p-values"
        appendInfoLine: ""
        .headerLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            @emlPadCell: emlScheffe.groupName$ [.jGroup], 12
            .headerLine$ = .headerLine$ + emlPadCell.result$
        endfor
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            @emlPadCell: emlScheffe.groupName$ [.iGroup], 14
            .rowLine$ = emlPadCell.result$
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .pVal = emlScheffe.pMatrix## [.iGroup, .jGroup]
                    @emlFormatP: .pVal
                    @emlSigMark: .pVal, .alpha
                    .cellText$ = emlFormatP.bare$ + emlSigMark.mark$
                endif
                @emlPadCell: .cellText$, 12
                .rowLine$ = .rowLine$ + emlPadCell.result$
            endfor
            appendInfoLine: .rowLine$
        endfor
        appendInfoLine: "  Symmetric: the p for A vs B is the p for B vs A."
        appendInfoLine: "  * p < ", .alphaText$

        @emlReportBlank
        @emlReportSection: "Mean Differences"
        appendInfoLine: ""
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            @emlPadCell: emlScheffe.groupName$ [.iGroup], 14
            .rowLine$ = emlPadCell.result$
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .diffVal = emlScheffe.diffMatrix## [.iGroup, .jGroup]
                    if .diffVal = undefined
                        .cellText$ = "n/a"
                    else
                        ; As in the per-pair table above.
                        @eml_fixed: .diffVal, 3
                        .cellText$ = eml_fixed.result$
                    endif
                endif
                @emlPadCell: .cellText$, 12
                .rowLine$ = .rowLine$ + emlPadCell.result$
            endfor
            appendInfoLine: .rowLine$
        endfor
        ; Antisymmetric, for the same reason the d matrix is.
        appendInfoLine: "  Row minus column: a negative difference means "
            ... + "the ROW group's"
        appendInfoLine: "  mean is lower than the COLUMN group's."
    endif

    @emlReportFooter
endproc


# ============================================================================
#
#  5. TWO-WAY ANOVA
#
# ============================================================================

procedure emlRunTwoWayAnalysis: .tableId, .dataCol$, .factor1$, .factor2$
    .recResult$ = ""
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    # NO INFO-WINDOW SAVE/RESTORE HERE. Praat's built-in
    # `Report two-way anova` clears the Info window, but snapshotting info$ ()
    # and replaying it with writeInfo: afterwards is not the answer: under
    # `praat --run` the replay prints the whole preceding transcript a second
    # time, because Info is streamed to stdout in batch and nothing can be
    # un-printed. @emlTwoWayAnova ASSIGNS the built-in's result instead of
    # running it bare, which never touches the Info window, so there is
    # nothing to put back. See the note there.
    @emlTwoWayAnova: .tableId, .dataCol$, .factor1$, .factor2$
    if emlTwoWayAnova.error$ <> ""
        .error$ = emlTwoWayAnova.error$
        goto END_TWOWAY
    endif

    ; Same reason as the Kruskal-Wallis path: the reporter re-runs the test.
    .recResult$ = .factor1$ + ": F(" + string$ (emlTwoWayAnova.dfA) + ", "
    ... + string$ (emlTwoWayAnova.dfError) + ") = "
    ... + fixed$ (emlTwoWayAnova.fA, 4) + ", p = "
    ... + fixed$ (emlTwoWayAnova.pA, 4) + newline$
    ... + "  " + .factor2$ + ": F(" + string$ (emlTwoWayAnova.dfB) + ", "
    ... + string$ (emlTwoWayAnova.dfError) + ") = "
    ... + fixed$ (emlTwoWayAnova.fB, 4) + ", p = "
    ... + fixed$ (emlTwoWayAnova.pB, 4) + newline$
    ... + "  interaction: F(" + string$ (emlTwoWayAnova.dfAB) + ", "
    ... + string$ (emlTwoWayAnova.dfError) + ") = "
    ... + fixed$ (emlTwoWayAnova.fAB, 4) + ", p = "
    ... + fixed$ (emlTwoWayAnova.pAB, 4) + newline$
    ... + "  n = " + string$ (emlTwoWayAnova.nObs) + ", cells = "
    ... + string$ (emlTwoWayAnova.nCells)

    @emlCSVInit
    @emlReportTwoWayAnova: .tableName$, .dataCol$, .factor1$, .factor2$

    if .error$ = ""
        @emlResultClearExtras
        @emlDeclareTwoWayEffects: .factor1$, .factor2$
        @emlResultStageExtra: "effectsize"
        @emlDeclareTwoWayResult: .tableName$, .dataCol$, .factor1$, .factor2$,
        ... .tableId
    endif

    label END_TWOWAY

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Two-way ANOVA",
        ... .dataCol$ + " by " + .factor1$ + " and " + .factor2$,
        ... "Type of sums of squares and the balance of the design both matter here; see the report.",
        ... "@emlRunTwoWayAnalysis: data, """ + .dataCol$ + """, """ + .factor1$ + """, """ + .factor2$ + """",
        ... "In the GUI: New > EML Tools > Compare two-way (ANOVA)...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc


# ============================================================================
#
#  6. PAIRED COMPARISON
#
# ============================================================================

procedure emlRunPairedAnalysis: .tableId, .col1$, .col2$, .testType$
    .recResult$ = ""
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""
    .nExcluded = 0

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    ; See the note in @emlRunTwoGroupAnalysis. Both columns are
    ; checked, first then second, so the message names the one the user has
    ; to change rather than reporting the pair count that resulted.
    @emlRequireNumericColumn: .tableId, "First column", .col1$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_PAIRED
    endif
    @emlRequireNumericColumn: .tableId, "Second column", .col2$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_PAIRED
    endif

    # Row-wise complete-case extraction: a pair is kept only when BOTH
    # columns are defined in the same row, preserving the pairing.
    # Extracting each column independently (per-column undefined removal)
    # misaligns the pairs whenever cells are missing in different rows.
    @emlExtractPairedColumns: .tableId, .col1$, .col2$
    if emlExtractPairedColumns.error$ <> ""
        .error$ = emlExtractPairedColumns.error$
        goto END_PAIRED
    endif
    .v1# = emlExtractPairedColumns.data1#
    .v2# = emlExtractPairedColumns.data2#
    .n = emlExtractPairedColumns.n
    .nExcluded = emlExtractPairedColumns.nExcludedRows

    if .n < 2
        .error$ = "Need at least 2 complete paired observations."
        goto END_PAIRED
    endif

    @emlMean: .v1#
    .mean1 = emlMean.result
    @emlSD: .v1#
    .sd1 = emlSD.result
    @emlMedian: .v1#
    .median1 = emlMedian.result

    @emlMean: .v2#
    .mean2 = emlMean.result
    @emlSD: .v2#
    .sd2 = emlSD.result
    @emlMedian: .v2#
    .median2 = emlMedian.result

    # Each test carries its own effect size. Cohen's d_z is built from the
    # same standard deviation of differences the paired t is built from;
    # matched-pairs r is built from the Wilcoxon ranks. Reporting the rank
    # statistic under the t-test is wrong — the two can differ by a
    # wide margin whenever changes are consistent in direction but variable
    # in size, and nothing on screen distinguished them. In "both" mode each
    # test reports its own, under its own heading.
    .didParametric = 0
    .didNonparametric = 0
    .failParametric$ = ""
    .failNonparametric$ = ""
    if .testType$ = "parametric" or .testType$ = "both"
        @emlTTestPaired: .v1#, .v2#, 2
        @emlCohenDz: .v1#, .v2#
        .didParametric = 1
        .failParametric$ = emlTTestPaired.error$
    endif
    if .testType$ = "nonparametric" or .testType$ = "both"
        @emlWilcoxonSignedRank: .v1#, .v2#, 2
        @emlMatchedPairsR: .v1#, .v2#, 2
        .didNonparametric = 1
        .failNonparametric$ = emlWilcoxonSignedRank.error$
    endif

    # ── A FAILED ANALYSIS IS A REFUSAL, NOT A RESULT ─────────────────────
    #
    # A column of one repeated value gives every pair the same difference:
    # @emlTTestPaired sets "All differences are identical (zero variance)"
    # and @emlWilcoxonSignedRank sets "All differences are zero; cannot
    # perform test". Unread here, .error$ stays empty, the orchestrator
    # returns success, and scripts/eml-compare-paired.praat puts up "Analysis
    # complete" with Save, Draw and New under it -- while the only sentence
    # saying nothing had run sits six lines up the Info window, prefixed
    # "Paired t-test error:".
    #
    # So the refusal is raised the way the singleton-group refusal raises
    # its own -- naming the columns, the n and the rule, and keeping the
    # user's selections on Back -- through
    # .error$, which scripts/eml-compare-paired.praat already routes into
    # @emlErrorDialog, and it carries the same three things -- WHICH columns,
    # WHAT n, and WHY, in each test's own words rather than a paraphrase that
    # can drift from them.
    #
    # ONLY WHEN NOTHING RAN. In "both" mode a t-test that fails beside a
    # Wilcoxon that succeeds is not a refusal: the report prints the one that
    # worked and names the one that did not. The gate is that no requested
    # family produced a test.
    #
    # .remedy$ stays empty: zero variance is a property of the data, not a
    # wrong menu choice, so there is no other EML entry to send the user to
    # and the dialog must not invent one.
    .ranSomething = 0
    if .didParametric = 1
        if .failParametric$ = ""
            .ranSomething = 1
        endif
    endif
    if .didNonparametric = 1
        if .failNonparametric$ = ""
            .ranSomething = 1
        endif
    endif
    if .ranSomething = 0
        .error$ = "No paired test could be run on these two columns. """
        ... + .col1$ + """ and """ + .col2$ + """ give n = " + string$ (.n)
        ... + " complete pairs, and every one of those pairs has the same "
        ... + "difference, so there is no variation in the differences for "
        ... + "a paired test to work on."
        if .failParametric$ <> ""
            .error$ = .error$ + " Paired t-test: " + .failParametric$ + "."
        endif
        if .failNonparametric$ <> ""
            .error$ = .error$ + " Wilcoxon signed-rank: "
            ... + .failNonparametric$ + "."
        endif
        if .nExcluded > 0
            @eml_completeCaseDisclosure: .n + .nExcluded, .n, .nExcluded, ""
            .error$ = .error$ + " " + eml_completeCaseDisclosure.note$
        endif
        goto END_PAIRED
    endif

    @emlCSVInit
    @emlReportPairedComparison: .tableName$, .col1$, .col2$, .n, .mean1, .sd1, .median1, .mean2, .sd2, .median2, .testType$

    if .nExcluded > 0
        .exclNote$ = "  Note: " + string$ (.nExcluded) + " row(s) excluded for missing data (analyzed n = " + string$ (.n) + " complete pairs)."
        appendInfoLine: .exclNote$
    endif

    ; @emlMatchedPairsR re-runs @emlWilcoxonSignedRank, so the Wilcoxon row is
    ; read inside the model declaration, which runs last.
    if .error$ = ""
        @emlResultClearExtras
        @emlDeclarePairedEffects:
        ... (.testType$ = "parametric" or .testType$ = "both"),
        ... (.testType$ = "nonparametric" or .testType$ = "both")
        @emlResultStageExtra: "effectsize"
        @emlDeclarePairedResult: .tableName$, .col1$, .col2$,
        ... (.testType$ = "parametric" or .testType$ = "both"),
        ... (.testType$ = "nonparametric" or .testType$ = "both")
    endif

    ; This procedure's own locals. The test statistics live in the sub-
    ; procedures and are not re-read here, so only what is provably fresh
    ; goes into the record.
    if .error$ = ""
        .recResult$ = "n = " + string$ (.n) + " complete pairs" + newline$
        ... + "  " + .col1$ + ": mean = " + fixed$ (.mean1, 4) + ", SD = "
        ... + fixed$ (.sd1, 4) + newline$
        ... + "  " + .col2$ + ": mean = " + fixed$ (.mean2, 4) + ", SD = "
        ... + fixed$ (.sd2, 4)
        if .nExcluded > 0
            .recResult$ = .recResult$ + newline$ + "  " + string$ (.nExcluded)
            ... + " row(s) excluded for missing data"
        endif
    endif
    label END_PAIRED

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Paired comparison",
        ... .col1$ + " vs " + .col2$ + ", " + .testType$,
        ... "Rows with a missing value in either column are dropped pairwise.",
        ... "@emlRunPairedAnalysis: data, """ + .col1$ + """, """ + .col2$ + """, """ + .testType$ + """",
        ... "In the GUI: New > EML Tools > Compare paired/repeated...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc


# ============================================================================
#
#  7. CORRELATION
#
# ============================================================================

procedure emlRunCorrelationAnalysis: .tableId, .colX$, .colY$, .testType$
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit

    ; These per-test locals are read UNCONDITIONALLY by
    ; @emlDeclareCorrelationResult but assigned only inside their own branch.
    ; Initialising them is load-bearing: without it a Pearson-only run --
    ; this wrapper's DEFAULT -- aborted with "Unknown variable: .spearRho"
    ; before any wrapper code ran.
    .pearR = undefined
    .pearT = undefined
    .pearDf = undefined
    .pearP = undefined
    .spearRho = undefined
    .spearT = undefined
    .spearDf = undefined
    .spearP = undefined
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""
    .nExcluded = 0

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    ; See the note in @emlRunTwoGroupAnalysis.
    @emlRequireNumericColumn: .tableId, "X column", .colX$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_CORR
    endif
    @emlRequireNumericColumn: .tableId, "Y column", .colY$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_CORR
    endif

    # Row-wise complete-case extraction: keep a row only when BOTH X and Y
    # are defined, preserving the pairing. Independent per-column extraction
    # would correlate misaligned values when cells are missing.
    @emlExtractPairedColumns: .tableId, .colX$, .colY$
    if emlExtractPairedColumns.error$ <> ""
        .error$ = emlExtractPairedColumns.error$
        goto END_CORR
    endif
    .dataX# = emlExtractPairedColumns.data1#
    .dataY# = emlExtractPairedColumns.data2#
    .n = emlExtractPairedColumns.n
    .nExcluded = emlExtractPairedColumns.nExcludedRows

    if .n < 3
        .error$ = "Need at least 3 complete pairs for correlation."
        goto END_CORR
    endif

    # v1.2 item 3: capture each test's outputs into locals IMMEDIATELY after
    # its own call. @emlReportCorrelationAnalysis (and the CSV rows it emits)
    # read the qualified globals emlPearsonCorrelation.* / emlSpearmanCorrelation.*,
    # and any procedure that runs between the call and the report can overwrite
    # them — @emlSpearmanCorrelation did exactly that by calling
    # @emlPearsonCorrelation on the ranks, so "both" reported rank-based
    # numbers under the Pearson heading in the report AND in the exported CSV.
    # The captured values are restored below, immediately before the report.
    .pearErr$ = ""
    .spearErr$ = ""
    if .testType$ = "pearson" or .testType$ = "both"
        @emlPearsonCorrelation: .dataX#, .dataY#, 2
        .pearR = emlPearsonCorrelation.r
        .pearT = emlPearsonCorrelation.t
        .pearDf = emlPearsonCorrelation.df
        .pearP = emlPearsonCorrelation.p
        .pearErr$ = emlPearsonCorrelation.error$
    endif
    if .testType$ = "spearman" or .testType$ = "both"
        @emlSpearmanCorrelation: .dataX#, .dataY#, 2
        .spearRho = emlSpearmanCorrelation.rho
        .spearT = emlSpearmanCorrelation.t
        .spearDf = emlSpearmanCorrelation.df
        .spearP = emlSpearmanCorrelation.p
        .spearErr$ = emlSpearmanCorrelation.error$
    endif

    # Restore the captured outputs into the qualified names the reporter reads.
    if .testType$ = "pearson" or .testType$ = "both"
        emlPearsonCorrelation.r = .pearR
        emlPearsonCorrelation.t = .pearT
        emlPearsonCorrelation.df = .pearDf
        emlPearsonCorrelation.p = .pearP
        emlPearsonCorrelation.error$ = .pearErr$
    endif
    if .testType$ = "spearman" or .testType$ = "both"
        emlSpearmanCorrelation.rho = .spearRho
        emlSpearmanCorrelation.t = .spearT
        emlSpearmanCorrelation.df = .spearDf
        emlSpearmanCorrelation.p = .spearP
        emlSpearmanCorrelation.error$ = .spearErr$
    endif

    @emlCSVInit
    @emlReportCorrelationAnalysis: .tableName$, .colX$, .colY$, .n, .testType$

    # v1.2 item 4: the reporter's Spearman branch has no else-branch, so a
    # failed Spearman test was reported as nothing at all. Surface it here.
    # (The Pearson branch already prints its own error, so it is not repeated.)
    if .spearErr$ <> ""
        .spearNote$ = "  Spearman correlation not computed: " + .spearErr$
        appendInfoLine: .spearNote$
    endif

    if .nExcluded > 0
        .exclNote$ = "  Note: " + string$ (.nExcluded) + " row(s) excluded for missing data (analyzed n = " + string$ (.n) + " complete pairs)."
        appendInfoLine: .exclNote$
    endif

    if .error$ = ""
        @emlResultClearExtras
        @emlDeclareCorrelationResult: .tableName$, .colX$, .colY$, .n,
        ... (.testType$ = "pearson" or .testType$ = "both"),
        ... .pearR, .pearT, .pearDf, .pearP,
        ... (.testType$ = "spearman" or .testType$ = "both"),
        ... .spearRho, .spearT, .spearDf, .spearP
    endif

    ; THE COEFFICIENT IS THE STEP. Built from the orchestrator's OWN locals,
    ; which lines 1770-1782 above restore explicitly after the reporters run,
    ; precisely so they cannot be stale here.
    .recResult$ = ""
    if .error$ = ""
        if .testType$ = "pearson" or .testType$ = "both"
            .recResult$ = "Pearson r = " + fixed$ (.pearR, 4)
            ... + ", t(" + string$ (.pearDf) + ") = " + fixed$ (.pearT, 4)
            ... + ", p = " + fixed$ (.pearP, 4)
        endif
        if .testType$ = "spearman" or .testType$ = "both"
            if .recResult$ <> ""
                .recResult$ = .recResult$ + newline$ + "  "
            endif
            .recResult$ = .recResult$ + "Spearman rho = " + fixed$ (.spearRho, 4)
            ... + ", p = " + fixed$ (.spearP, 4)
        endif
        if .recResult$ <> ""
            .recResult$ = .recResult$ + newline$ + "  n = " + string$ (.n)
        endif
    endif

    label END_CORR

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Correlation",
        ... .colX$ + " with " + .colY$ + ", " + .testType$,
        ... "Correlation is not causation, and a single coefficient hides the shape of the cloud.",
        ... "@emlRunCorrelationAnalysis: data, """ + .colX$ + """, """ + .colY$ + """, """ + .testType$ + """",
        ... "In the GUI: New > EML Tools > Correlate two columns...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc


# ============================================================================
#
#  8. DESCRIPTIVE STATISTICS
#
# ============================================================================

procedure emlRunDescriptiveAnalysis: .tableId, .dataCol$
    .recResult$ = ""
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    ; See the note in @emlRunTwoGroupAnalysis. This orchestrator
    ; already refused a text column, but with "contains no valid numeric
    ; values", which names neither the offending cell nor the diagnosis.
    @emlRequireNumericColumn: .tableId, "Data column", .dataCol$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_DESCRIBE
    endif

    @emlExtractColumn: .tableId, .dataCol$
    if emlExtractColumn.error$ <> ""
        .error$ = emlExtractColumn.error$
        goto END_DESCRIBE
    endif
    .data# = emlExtractColumn.data#
    .nValid = emlExtractColumn.n
    .nUndefined = emlExtractColumn.nUndefined

    if .nValid < 1
        .error$ = "Column """ + .dataCol$ + """ contains no valid numeric values."
        goto END_DESCRIBE
    endif

    @emlDescribe: .data#

    # THE COUNT OF EXCLUDED ROWS ALSO SAYS WHY, because the three conditions
    # need different responses from the user.
    # @emlExtractColumn has the breakdown, so pass it through rather
    # than recomputing it here and risking a second, disagreeing account.
    @emlReportDescriptiveAnalysis: .tableName$, .dataCol$, .nValid,
    ... .nUndefined, emlExtractColumn.note$

    # EXPORTABLE. The Save panel offers a CSV only when there is something
    # to export, so an orchestrator that fills neither collector leaves the
    # wizard's Describe page with no Save button.
    #
    # It fills the LEGACY buffer rather than declaring -- see the note above
    # @emlCSVAddDescriptiveRow. It is UNCONVERTED in the broom sense, which
    # is what makes it harness/broom_cases/contamination_probe.praat's
    # canonical unconverted subject.
    #
    # Filled AFTER the report and from the same @emlDescribe pass, so the file
    # and the screen cannot disagree.
    @emlCSVSetTable: .tableName$
    @emlCSVAddDescriptiveRow: .dataCol$

    ; A descriptive pass has no single test statistic; what it has is how
    ; much data it actually described, which is the number a reader needs in
    ; order to judge the rest.
    if .error$ = ""
        .recResult$ = "n = " + string$ (.nValid) + " valid"
        if .nUndefined > 0
            .recResult$ = .recResult$ + ", " + string$ (.nUndefined)
            ... + " undefined"
        endif
    endif
    label END_DESCRIBE

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Descriptive statistics",
        ... .dataCol$,
        ... "Descriptives only; no test was run and no assumption was checked.",
        ... "@emlRunDescriptiveAnalysis: data, """ + .dataCol$ + """",
        ... "In the GUI: New > EML Tools > Describe Table column...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc




# ============================================================================
#
#  PHASE 4 STUBS
#
# ============================================================================

procedure emlRunRegressionAnalysis: .tableId, .depCol$, .predCol$
    ; The line the record carries. Empty until the fit succeeds, so a refusal
    ; records its refusal and no coefficients.
    .recResult$ = ""
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")
    .nRows = Get number of rows

    if .nRows < 3
        .error$ = "Need at least 3 rows for regression."
    endif

    # v1.2 item 6: guard the column names. Without this, "Get value:" below
    # aborts the whole script with a raw Praat error naming no column.
    if .error$ = ""
        selectObject: .tableId
        .predIdx = Get column index: .predCol$
        .depIdx = Get column index: .depCol$
        if .predIdx = 0
            .error$ = "Column """ + .predCol$ + """ not found in table """
            ... + .tableName$ + """."
        elsif .depIdx = 0
            .error$ = "Column """ + .depCol$ + """ not found in table """
            ... + .tableName$ + """."
        endif
    endif

    ; See the note in @emlRunTwoGroupAnalysis.
    if .error$ = ""
        @emlRequireNumericColumn: .tableId, "Dependent column", .depCol$, 0
        .error$ = emlRequireNumericColumn.error$
    endif
    if .error$ = ""
        @emlRequireNumericColumn: .tableId, "Predictor column", .predCol$, 0
        .error$ = emlRequireNumericColumn.error$
    endif

    if .error$ = ""
        # Extract paired values, pairwise-delete undefined
        .nValid = 0
        for .iRow from 1 to .nRows
            selectObject: .tableId
            .xVal = Get value: .iRow, .predCol$
            .yVal = Get value: .iRow, .depCol$
            if .xVal <> undefined and .yVal <> undefined
                .nValid += 1
            endif
        endfor

        if .nValid < 3
            .error$ = "Need at least 3 non-missing paired observations (found "
            ... + string$ (.nValid) + ")."
        endif
    endif

    if .error$ = ""
        .xClean# = zero# (.nValid)
        .yClean# = zero# (.nValid)
        .idx = 0
        for .iRow from 1 to .nRows
            selectObject: .tableId
            .xVal = Get value: .iRow, .predCol$
            .yVal = Get value: .iRow, .depCol$
            if .xVal <> undefined and .yVal <> undefined
                .idx += 1
                .xClean# [.idx] = .xVal
                .yClean# [.idx] = .yVal
            endif
        endfor

        @emlLinearRegression: .xClean#, .yClean#
        if emlLinearRegression.error$ <> ""
            .error$ = emlLinearRegression.error$
        else
            ; CAPTURED HERE, NOT AT THE HOOK. @emlReportRegressionAnalysis and
            ; @emlDeclareRegressionResult both re-invoke @emlLinearRegression,
            ; and a Praat procedure's outputs survive only until it runs
            ; again -- the same hazard @emlBridgeGroupComparison documents for
            ; @emlCountGroups. Reading emlLinearRegression.slope after those
            ; calls would read whatever the LAST invocation left.
            .recResult$ = .depCol$ + " = "
            ... + fixed$ (emlLinearRegression.intercept, 4) + " + "
            ... + fixed$ (emlLinearRegression.slope, 4) + " x " + .predCol$
            ... + newline$ + "  R-squared = "
            ... + fixed$ (emlLinearRegression.rSquared, 4)
            ... + ", n = " + string$ (.nValid)
        endif
    endif

    if .error$ = ""
        .nUndefined = .nRows - .nValid

        @emlCSVInit
        @emlReportRegressionAnalysis: .tableName$, .depCol$, .predCol$,
        ... .nValid, .nUndefined

        @emlResultClearExtras
        @emlDeclareRegressionResult: .tableName$, .depCol$, .predCol$,
        ... .tableId, .nValid
    endif

    selectObject: .tableId

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Linear regression",
        ... .depCol$ + " on " + .predCol$,
        ... "Residual diagnostics are not run on this path.",
        ... "@emlRunRegressionAnalysis: data, """ + .depCol$ + """, """ + .predCol$ + """",
        ... "In the GUI: New > EML Tools > Linear regression...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc

# ============================================================================
# @emlNormalityRecommendation
# ============================================================================
# THE normality decision rule. This procedure is the ONLY place in the plugin
# where the hierarchy and its thresholds are written down.
#
# @wizardNormDiag (scripts/eml-wizard.praat) and the per-group branch of
# scripts/eml-check-normality.praat call it rather than carrying copies.
# Three copies of a rule is three chances to drift -- hard-coded thresholds
# against the shared constants, or an older gate on one path only, and ONE
# wrapper then gives two different answers for the same data depending on
# whether the user picked a grouping column. This is one copy with three
# callers.
#
# THE HIERARCHY
#
# SHAPIRO-WILK IS THE TEST. Skewness and kurtosis are descriptive statistics,
# not tests. They are the backup — they decide only where Shapiro-Wilk cannot
# — plus the one large-n override below.
#
#   Shapiro-Wilk usable and rejects (p < 0.05)
#       shape not severe and n > 50  → parametric  (large-n override)
#       otherwise                    → nonparametric
#   Shapiro-Wilk usable, does not reject
#                                    → parametric. Severe shape is REPORTED
#                                      by the caller but does not overturn a
#                                      formal test. Shapiro-Wilk is the most
#                                      powerful of the common omnibus
#                                      normality tests across a broad range
#                                      of alternatives (Razali & Wah 2011); a
#                                      rule of thumb does not outvote it.
#   Shapiro-Wilk unusable            → shape decides, and this is the ONLY
#                                      branch in which it decides anything.
#
# The large-n override exists because Shapiro-Wilk rejects departures too
# small to matter for a parametric test once n is large.
#
# Arguments:
#   .skewness — sample skewness
#   .kurtosis — EXCESS kurtosis (0 = normal), not raw kurtosis
#   .n        — count the statistics were computed on (non-missing values)
#   .swP      — @emlShapiroWilk's .p. MAY BE undefined; see the note below.
#   .swError$ — @emlShapiroWilk's .error$; "" means the test produced a p
#
# Output:
#   .recommendation$ — "parametric" or "nonparametric"
#   .swUsable        — 1 when Shapiro-Wilk produced a p-value
#   .swFail          — 1 when Shapiro-Wilk ran AND rejected (p < 0.05)
#   .shapeSevere     — 1 when |skew| >= emlSkewThreshold or
#                      |excess kurtosis| >= emlKurtosisThreshold
#   .largeNOverride  — 1 when Shapiro-Wilk rejected but shape is within
#                      limits at n > 50, so the answer is parametric anyway
#
# This procedure is PURE DECISION. It prints nothing, declares no result
# object, touches no global and selects no object, so the wizard can call it
# without disturbing wizard state. Callers own every message; they select it
# from the flags above rather than re-deriving the rule.
#
# Thresholds are emlSkewThreshold / emlKurtosisThreshold (stats/
# eml-output.praat), the same constants the printed verdicts use, so the gate
# and the prose cannot disagree.
#
# UNDEFINED .swP IS EXPECTED, NOT AN ERROR. @emlShapiroWilk initialises .p to
# undefined and leaves it there whenever it sets .error$ (n < 3, n > 5000,
# zero range). The .swUsable test is therefore NESTED, not `and`-ed: Praat
# does not short-circuit `and`, so `.swError$ = "" and .swP < 0.05` evaluates
# the comparison against undefined on every call. Do not "simplify" it back.
# ============================================================================
procedure emlNormalityRecommendation: .skewness, .kurtosis, .n, .swP, .swError$
    .shapeSevere = abs (.skewness) >= emlSkewThreshold
    ... or abs (.kurtosis) >= emlKurtosisThreshold

    .swUsable = 0
    if .swError$ = ""
        .swUsable = 1
    endif

    ; Nested, not `and` -- .swP is undefined when .swUsable is 0.
    .swFail = 0
    if .swUsable
        if .swP < 0.05
            .swFail = 1
        endif
    endif

    .largeNOverride = 0
    if .swUsable
        if .swFail
            if (not .shapeSevere) and .n > 50
                .recommendation$ = "parametric"
                .largeNOverride = 1
            else
                .recommendation$ = "nonparametric"
            endif
        else
            .recommendation$ = "parametric"
        endif
    else
        if .shapeSevere
            .recommendation$ = "nonparametric"
        else
            .recommendation$ = "parametric"
        endif
    endif
endproc

# ============================================================================
# @eml_normalityPress: .tableName$, .dataCol$, .testType$   ->  .accumulate
#
# INIT ONCE PER PRESS, ACCUMULATE PER LOOP.
#
# scripts/eml-check-normality.praat tests EVERY numeric column in one press of
# Run: one `for iSel from 1 to nNumericCols` loop, one call to
# @emlRunNormalityAnalysis per column, then one Save. An orchestrator that
# cleared the collectors at its own entry would have each pass of that loop
# wipe the pass before it, and Save would write the LAST column only -- with
# the report still carrying all three columns and the tidy frame carrying one
# row, numerically perfect and quietly short.
#
# It cannot be "clear at the wrapper instead": the wrapper's per-press
# hook would be a line in scripts/eml-check-normality.praat, and the wizard
# reaches the same orchestrator with no loop at all. So the boundary is
# detected here, from state that is already maintained, and every clause below
# is a way for a call to be the FIRST of a press rather than the second:
#
#   .testType$ = "single"   the wizard's literal, at eml-wizard.praat:1698.
#                           That page runs one column per press and offers
#                           Save on each; two presses must not merge. This is
#                           the one place the third argument is read.
#   no press open           emlNorm_n is this procedure's own record of the
#                           press in flight. Zero or absent means there is no
#                           press to join. NOT emlResult_declared: v46 pins
#                           that only stats/eml-output.praat may branch on the
#                           migration flag, one decision point for one
#                           question, and this is a different question asked
#                           in a different file. The press keeps its own
#                           state rather than borrowing that one.
#   a different analysis    an ANOVA ran in between; its frames are not ours.
#   a different table       the user changed objects.
#   emlReportAnalysis$ set  @emlHandleCommonFields sets it on EVERY Run, in
#                           every wrapper, and @emlReportHeader consumes it on
#                           the first report printed. So it is non-empty at
#                           the top of column 1 and empty at the top of column
#                           2 -- the once-per-Run signal, already in the tree
#                           for report provenance, and the only one that
#                           survives Save/New.
#   the column repeats      belt and braces: a second press over the same
#                           column list starts with a column already held.
#
# Praat evaluates BOTH operands of `and`, so these are nested ifs, not one
# conjunction: none of these globals exists until something has set it.
# ============================================================================
procedure eml_normalityPress: .tableName$, .dataCol$, .testType$
    .accumulate = 0
    if .testType$ <> "single"
        if variableExists ("emlNorm_n")
            if emlNorm_n > 0
                if emlNorm_table$ = .tableName$
                    .accumulate = 1
                endif
            endif
        endif
    endif
    if .accumulate = 1
        .stillOurs = 0
        if variableExists ("emlResult_analysis$")
            if emlResult_analysis$ = "Normality"
                .stillOurs = 1
            endif
        endif
        .accumulate = .stillOurs
    endif
    if .accumulate = 1
        if variableExists ("emlReportAnalysis$")
            if emlReportAnalysis$ <> ""
                .accumulate = 0
            endif
        endif
    endif
    if .accumulate = 1
        for .i from 1 to emlNorm_n
            if emlNorm_col$ [.i] = .dataCol$
                .accumulate = 0
            endif
        endfor
    endif
endproc

# .testType$ SELECTS NO TEST. This orchestrator always computes both families
# of evidence — descriptive shape (skewness/kurtosis) and the formal
# Shapiro-Wilk test — and combines them into one recommendation, so there is
# no branch to select. It is read in exactly one place, @eml_normalityPress
# above, where the wizard's "single" marks a press that tests one column and
# must not be merged into a neighbouring one. Call sites pass "both", "auto"
# and "single"; the first two behave identically.
# The parameter is retained because callers pass arguments positionally.
# Do not remove it without updating every call site.
procedure emlRunNormalityAnalysis: .tableId, .dataCol$, .testType$
    .recResult$ = ""

    ; The press boundary is decided BEFORE anything is cleared, because the
    ; evidence it reads is what the clearing would destroy.
    selectObject: .tableId
    .pressTable$ = selected$ ("Table")
    @eml_normalityPress: .pressTable$, .dataCol$, .testType$
    .accumulate = eml_normalityPress.accumulate

    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    ;
    ; NOT on a continuation, which is the whole point: mid-loop the
    ; flag describes THIS press, which is still running, and clearing it would
    ; throw away the columns already tested. Skipping it also means a column
    ; that fails its guard at pass 3 leaves passes 1 and 2 exportable rather
    ; than taking the press down with it.
    if .accumulate = 0
        @emlCSVInit
    endif
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")
    .nRows = Get number of rows

    # v1.2 item 6: guard the column name. Without this, "Get value:" below
    # aborts the whole script with a raw Praat error naming no column.
    .dataIdx = Get column index: .dataCol$
    if .dataIdx = 0
        .error$ = "Column """ + .dataCol$ + """ not found in table """
        ... + .tableName$ + """."
        goto END_NORMALITY
    endif

    ; See the note in @emlRunTwoGroupAnalysis.
    @emlRequireNumericColumn: .tableId, "Data column", .dataCol$, 0
    if emlRequireNumericColumn.error$ <> ""
        .error$ = emlRequireNumericColumn.error$
        goto END_NORMALITY
    endif

    # Extract column data (exclude undefined)
    .nValid = 0
    for .iRow from 1 to .nRows
        selectObject: .tableId
        .val = Get value: .iRow, .dataCol$
        if .val <> undefined
            .nValid += 1
        endif
    endfor

    if .nValid < 3
        .error$ = "Need at least 3 non-missing values (found "
        ... + string$ (.nValid) + ")."
    endif

    if .error$ = ""
        .data# = zero# (.nValid)
        .idx = 0
        for .iRow from 1 to .nRows
            selectObject: .tableId
            .val = Get value: .iRow, .dataCol$
            if .val <> undefined
                .idx += 1
                .data# [.idx] = .val
            endif
        endfor

        .nUndefined = .nRows - .nValid

        # Descriptive shape measures
        @emlSkewness: .data#
        .skewness = emlSkewness.result
        @emlKurtosis: .data#
        .kurtosis = emlKurtosis.result
        @emlMean: .data#
        .mean = emlMean.result
        @emlSD: .data#
        .sd = emlSD.result
        @emlMedian: .data#
        .median = emlMedian.result

        # Shapiro-Wilk formal test
        @emlShapiroWilk: .data#
        .swW = emlShapiroWilk.w
        .swP = emlShapiroWilk.p
        .swError$ = emlShapiroWilk.error$

        # ── Interpretation ─────────────────────────────────────────────
        #
        # The rule itself lives in @emlNormalityRecommendation, above. It is
        # not restated here, and it must not be: the wizard's @wizardNormDiag
        # and the per-group branch of scripts/eml-check-normality.praat call
        # the same procedure with the same five arguments, and the whole
        # point of v1.3 is that there is now exactly one copy to maintain.
        #
        # The flags are copied out into this orchestrator's own namespace
        # because @emlReportNormalityAnalysis and @emlDeclareNormalityResult
        # read them from here, and because anything called between now and
        # those two could re-enter @emlNormalityRecommendation.
        @emlNormalityRecommendation: .skewness, .kurtosis, .nValid,
        ... .swP, .swError$
        .shapeSevere = emlNormalityRecommendation.shapeSevere
        .swUsable = emlNormalityRecommendation.swUsable
        .swFail = emlNormalityRecommendation.swFail
        .largeNOverride = emlNormalityRecommendation.largeNOverride
        .recommendation$ = emlNormalityRecommendation.recommendation$

        ; Skipped mid-loop for the reason given at entry: on a continuation
        ; this would clear the declaration flag that the columns already
        ; tested are riding on.
        if .accumulate = 0
            @emlCSVInit
        endif
        @emlReportNormalityAnalysis: .tableName$, .dataCol$,
        ... .nValid, .nUndefined
    endif

    if .error$ = ""
        @emlResultClearExtras
        @emlDeclareNormalityResult: .tableName$, .dataCol$, .swW, .swP,
        ... .swError$, .skewness, .kurtosis, .nValid, .nUndefined,
        ... .recommendation$, .accumulate
    endif

    ; .swW, .swP, .skewness and .kurtosis are this procedure's own locals --
    ; @emlDeclareNormalityResult is PASSED them rather than reading them
    ; back, which is exactly why they are safe to read here.
    if .error$ = ""
        .recResult$ = ""
        if .swError$ = ""
            .recResult$ = "Shapiro-Wilk W = " + fixed$ (.swW, 4) + ", p = "
            ... + fixed$ (.swP, 4) + newline$ + "  "
        endif
        .recResult$ = .recResult$ + "skewness = " + fixed$ (.skewness, 4)
        ... + ", kurtosis = " + fixed$ (.kurtosis, 4)
        ... + ", n = " + string$ (.nValid) + newline$
        ... + "  Recommendation: " + .recommendation$
    endif
    label END_NORMALITY

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Normality",
        ... .dataCol$ + ", " + .testType$,
        ... "A normality test answers a question about the sample, not a licence for a later test.",
        ... "@emlRunNormalityAnalysis: data, """ + .dataCol$ + """, """ + .testType$ + """",
        ... "In the GUI: New > EML Tools > Check normality (all columns)...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc

# v1.2 item 7: unimplemented stub. It has no call sites anywhere in the
# plugin; it exists so the Phase 4 API surface is declared. It returns a
# non-empty .error$ and computes nothing — callers must check .error$ before
# reading any other output, because no other output is set.
procedure emlRunReliabilityAnalysis: .tableId, .subjectCol$, .raterCols$, .measure$, .scale$
    .recResult$ = ""
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    ; ASCII HYPHENS, NOT AN EM DASH, and the reason is Praat's file writer.
    ; Praat writes a text file as UTF-16 the moment its content contains one
    ; non-ASCII character. This string reaches a RECORDED SCRIPT verbatim as
    ; the refusal note for the step, so a session that touched the LMM path
    ; produced a UTF-16 .praat file -- runnable, but undiffable in git and
    ; unreadable by anything that assumes bytes. One em dash, one encoding.
    .error$ = "Not yet implemented -- scheduled for Phase 4."
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Reliability",
        ... .measure$ + " over " + .raterCols$ + ", subject " + .subjectCol$,
        ... "The ICC form and the scale of interest are choices; both are stated in the report.",
        ... "@emlRunReliabilityAnalysis: data, """ + .subjectCol$ + """, """ + .raterCols$ + """, """ + .measure$ + """, """ + .scale$ + """",
        ... "Not in the GUI: there is no menu entry for this yet.",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc

# ============================================================================
# @eml_completeCaseDisclosure: .nRows, .n, .nExcluded, .parseNote$  -> .note$
#
# WHAT A REFUSAL IS ALLOWED TO CLAIM.
#
# The repeated-measures and Friedman paths drop a row unless every condition
# cell in it is present -- listwise, because per-column deletion would break
# the within-subject pairing. The SUCCESS path discloses that in the
# "row(s) excluded for missing data" note printed under the results, and the
# REFUSAL path has to disclose it too, because the refusal text is a claim
# about the very population that was reduced:
#
#   "The subject x condition residual is zero: every subject shows exactly
#    the same pattern across conditions."
#
# Undisclosed, that sentence is true of the subjects that survived listwise
# deletion and says nothing about the ones that did not: a reader is told a
# fact about "every subject" over half a table, with no indication that the
# other half was ever there. The arithmetic is right and the sentence is not.
#
# The wording follows describe's -- "N excluded 3 · 3 cell(s) empty (row 3
# first). Treated as missing data." -- because two disclosure styles for one
# condition is how a reader learns to skip both. @emlAuditColumn's per-column
# note is carried through verbatim, so the row numbers a user would go and
# look at are the ones they are given.
#
# ONE PARAGRAPH, NO NEWLINES. This string reaches @emlErrorDialog, which
# hands it to @emlWrapText at 62 columns; an embedded newline would survive
# into a `comment:` line and print as a control character rather than a break.
#
# ASCII ONLY, and this is the one place the wording departs from describe's.
# Describe's disclosure carries a middle dot -- "N excluded 3 · 3 cell(s)
# empty (row 3 first)." -- and that separator cannot be used here. The
# string is appended to an orchestrator's .error$, and .error$ is passed
# to @emlRecordAnalysisStep as the refusal note for the step, which is written
# into a RECORDED SCRIPT. Praat writes a text file as UTF-16 the moment its
# content contains one non-ASCII character, so a session that hit this refusal
# while recording would produce a .praat file that runs and cannot be diffed.
# The reliability path learned this in its own words; see the comment in
# @emlRunReliabilityAnalysis. The substance is describe's -- the count, the
# per-column note verbatim from @emlAuditColumn, and "Treated as missing
# data." -- and only the punctuation is ASCII.
# ============================================================================
procedure eml_completeCaseDisclosure: .nRows, .n, .nExcluded, .parseNote$
    .note$ = ""
    if .nExcluded > 0
        .note$ = "Assessed on " + string$ (.n) + " of " + string$ (.nRows)
        ... + " rows. N excluded " + string$ (.nExcluded)
        ... + " -- a row is used only when every column in the comparison "
        ... + "has a value, which is what keeps the pairing intact. "
        ... + "Treated as missing data."
        if .parseNote$ <> ""
            .note$ = .note$ + " " + .parseNote$
        endif
    endif
endproc


# ============================================================================
# @emlExtractConditionMatrix
# Row-wise COMPLETE-CASE extraction of k condition columns into a matrix.
# A subject (row) is kept only when ALL k condition cells are defined, which
# preserves the within-subject blocking that repeated-measures tests require
# (per-column deletion would break the pairing — same principle as C1/C2).
# Input:  .tableId, .conditionCols$  ("|"-delimited column names)
# Output: .data## (n x k), .n, .k, .colLabel$[1..k], .nExcluded, .error$
# ============================================================================
procedure emlExtractConditionMatrix: .tableId, .conditionCols$
    .error$ = ""
    .parseNote$ = ""
    .nExcluded = 0
    .k = 0
    .rest$ = .conditionCols$ + "|"
    .barPos = index (.rest$, "|")
    while .barPos > 0
        .tok$ = left$ (.rest$, .barPos - 1)
        .tok$ = replace_regex$ (.tok$, "^ +", "", 0)
        .tok$ = replace_regex$ (.tok$, " +$", "", 0)
        if .tok$ <> ""
            .k = .k + 1
            .colLabel$ [.k] = .tok$
        endif
        .rest$ = mid$ (.rest$, .barPos + 1, length (.rest$) - .barPos)
        .barPos = index (.rest$, "|")
    endwhile
    if .k < 2
        .error$ = "Need at least 2 condition columns."
        goto END_EXTRACT_COND
    endif
    selectObject: .tableId
    .nRows = Get number of rows
    for .j from 1 to .k
        .ci = Get column index: .colLabel$ [.j]
        if .ci = 0
            .error$ = "Column not found: " + .colLabel$ [.j]
            goto END_EXTRACT_COND
        endif
    endfor

    ; Both @emlRunRepeatedMeasuresAnalysis and @emlRunFriedmanAnalysis
    ; reach their condition columns through here, so the column-type guard is
    ; applied ONCE, for both, at the shared reader -- see the note in
    ; @emlRunTwoGroupAnalysis. Without it a text condition column presented
    ; as "Need at least 2 complete-case subjects", which reads as a data
    ; shortage rather than as the wrong column.
    for .j from 1 to .k
        if .error$ = ""
            @emlRequireNumericColumn: .tableId, "Condition column",
            ... .colLabel$ [.j], 0
            .error$ = emlRequireNumericColumn.error$
        endif
    endfor
    if .error$ <> ""
        goto END_EXTRACT_COND
    endif
    # THE ROW-WISE READER: a subject is complete only if every condition cell
    # is present. It goes through @eml_readCell like every other extraction
    # path, so a row is complete here exactly when it would be complete
    # anywhere else -- `Get value:` would count a European "1,5" as present
    # and then put 1 into the matrix.
    for .j from 1 to .k
        @eml_openColumn: .tableId, .colLabel$ [.j]
        .clean [.j] = eml_openColumn.clean
        @emlAuditColumn: .tableId, .colLabel$ [.j]
        if emlAuditColumn.note$ <> ""
            if .parseNote$ <> ""
                .parseNote$ = .parseNote$ + " "
            endif
            .parseNote$ = .parseNote$ + .colLabel$ [.j] + ": "
            ... + emlAuditColumn.note$
        endif
    endfor

    # First pass: count complete rows
    .nComplete = 0
    for .row from 1 to .nRows
        .complete = 1
        for .j from 1 to .k
            @eml_readCell: .tableId, .row, .colLabel$ [.j], .clean [.j]
            if eml_readCell.value = undefined
                .complete = 0
            endif
        endfor
        if .complete = 1
            .nComplete = .nComplete + 1
        endif
    endfor
    .n = .nComplete
    .nExcluded = .nRows - .nComplete
    if .n < 2
        .error$ = "Need at least 2 complete-case subjects (rows with all conditions present)."
        ; "Need at least 2" over a table of eight reads as a data
        ; shortage the user does not have. What they have is an exclusion,
        ; and the note names which column emptied which row.
        @eml_completeCaseDisclosure: .nRows, .n, .nExcluded, .parseNote$
        if eml_completeCaseDisclosure.note$ <> ""
            .error$ = .error$ + " " + eml_completeCaseDisclosure.note$
        endif
        goto END_EXTRACT_COND
    endif
    # Second pass: fill matrix
    .data## = zero## (.n, .k)
    .r = 0
    for .row from 1 to .nRows
        .complete = 1
        for .j from 1 to .k
            @eml_readCell: .tableId, .row, .colLabel$ [.j], .clean [.j]
            .cellValue [.j] = eml_readCell.value
            if eml_readCell.value = undefined
                .complete = 0
            endif
        endfor
        if .complete = 1
            .r = .r + 1
            for .j from 1 to .k
                .data## [.r, .j] = .cellValue [.j]
            endfor
        endif
    endfor
    label END_EXTRACT_COND
endproc

# ============================================================================
# @emlFriedmanTest — Friedman rank test for k related samples (tie-corrected).
# Matches scipy.stats.friedmanchisquare.
# Input:  .data## (n x k), .n, .k
# Output: .chiSq, .df, .p, .rankSum#[1..k]
# ============================================================================
procedure emlFriedmanTest: .data##, .n, .k
    .rankSum# = zero# (.k)
    .tieSum = 0
    for .i from 1 to .n
        for .j from 1 to .k
            .val = .data## [.i, .j]
            .nLess = 0
            .nEqual = 0
            for .jj from 1 to .k
                if .data## [.i, .jj] < .val
                    .nLess = .nLess + 1
                elsif .data## [.i, .jj] = .val
                    .nEqual = .nEqual + 1
                endif
            endfor
            .rank = .nLess + (.nEqual + 1) / 2
            .rankSum# [.j] = .rankSum# [.j] + .rank
        endfor
        # tie correction: sum over distinct tie groups of (t^3 - t), row-wise
        for .j from 1 to .k
            .val = .data## [.i, .j]
            .firstOcc = 1
            for .jj from 1 to .j - 1
                if .data## [.i, .jj] = .val
                    .firstOcc = 0
                endif
            endfor
            if .firstOcc = 1
                .t = 0
                for .jj from 1 to .k
                    if .data## [.i, .jj] = .val
                        .t = .t + 1
                    endif
                endfor
                .tieSum = .tieSum + (.t * .t * .t - .t)
            endif
        endfor
    endfor
    .sumRankSq = 0
    for .j from 1 to .k
        .sumRankSq = .sumRankSq + .rankSum# [.j] * .rankSum# [.j]
    endfor
    .chiRaw = 12 / (.n * .k * (.k + 1)) * .sumRankSq - 3 * .n * (.k + 1)
    .c = 1 - .tieSum / (.n * (.k * .k * .k - .k))
    if .c <= 0
        .c = 1
    endif
    .chiSq = .chiRaw / .c
    .df = .k - 1
    .p = chiSquareQ (.chiSq, .df)
endproc

# ============================================================================
# @emlGGEpsilon — Greenhouse-Geisser sphericity epsilon for RM-ANOVA.
# Input:  .data## (n x k), .n, .k ; Output: .epsilon (clamped to [1/(k-1), 1])
# ============================================================================
procedure emlGGEpsilon: .data##, .n, .k
    .cmean# = zero# (.k)
    for .j from 1 to .k
        for .i from 1 to .n
            .cmean# [.j] = .cmean# [.j] + .data## [.i, .j]
        endfor
        .cmean# [.j] = .cmean# [.j] / .n
    endfor
    .s## = zero## (.k, .k)
    for .a from 1 to .k
        for .b from 1 to .k
            .acc = 0
            for .i from 1 to .n
                .acc = .acc + (.data## [.i, .a] - .cmean# [.a]) *
                    ... (.data## [.i, .b] - .cmean# [.b])
            endfor
            .s## [.a, .b] = .acc / (.n - 1)
        endfor
    endfor
    .diagMean = 0
    for .a from 1 to .k
        .diagMean = .diagMean + .s## [.a, .a]
    endfor
    .diagMean = .diagMean / .k
    .grandMeanS = 0
    for .a from 1 to .k
        for .b from 1 to .k
            .grandMeanS = .grandMeanS + .s## [.a, .b]
        endfor
    endfor
    .grandMeanS = .grandMeanS / (.k * .k)
    .sumSq = 0
    for .a from 1 to .k
        for .b from 1 to .k
            .sumSq = .sumSq + .s## [.a, .b] * .s## [.a, .b]
        endfor
    endfor
    .sumRowMeanSq = 0
    for .a from 1 to .k
        .rm = 0
        for .b from 1 to .k
            .rm = .rm + .s## [.a, .b]
        endfor
        .rm = .rm / .k
        .sumRowMeanSq = .sumRowMeanSq + .rm * .rm
    endfor
    .num = .k * .k * (.diagMean - .grandMeanS) * (.diagMean - .grandMeanS)
    .den = (.k - 1) * (.sumSq - 2 * .k * .sumRowMeanSq +
        ... .k * .k * .grandMeanS * .grandMeanS)
    if .den <= 0
        .epsilon = 1
    else
        .epsilon = .num / .den
    endif
    if .epsilon > 1
        .epsilon = 1
    endif
    .lowerBound = 1 / (.k - 1)
    if .epsilon < .lowerBound
        .epsilon = .lowerBound
    endif
endproc

# ============================================================================
# @emlRMAnovaTest — one-way repeated-measures ANOVA with GG correction.
# Matches statsmodels AnovaRM. Input: .data## (n x k), .n, .k
# Output: .fStat, .dfCond, .dfErr, .p, .ggEpsilon, .pGG, .condMean#[1..k]
# ============================================================================
procedure emlRMAnovaTest: .data##, .n, .k
    .grand = 0
    .condMean# = zero# (.k)
    .subjMean# = zero# (.n)
    for .i from 1 to .n
        for .j from 1 to .k
            .grand = .grand + .data## [.i, .j]
            .condMean# [.j] = .condMean# [.j] + .data## [.i, .j]
            .subjMean# [.i] = .subjMean# [.i] + .data## [.i, .j]
        endfor
    endfor
    .grand = .grand / (.n * .k)
    for .j from 1 to .k
        .condMean# [.j] = .condMean# [.j] / .n
    endfor
    for .i from 1 to .n
        .subjMean# [.i] = .subjMean# [.i] / .k
    endfor
    .ssCond = 0
    for .j from 1 to .k
        .ssCond = .ssCond + (.condMean# [.j] - .grand) * (.condMean# [.j] - .grand)
    endfor
    .ssCond = .n * .ssCond
    .ssSubj = 0
    for .i from 1 to .n
        .ssSubj = .ssSubj + (.subjMean# [.i] - .grand) * (.subjMean# [.i] - .grand)
    endfor
    .ssSubj = .k * .ssSubj
    .ssTot = 0
    for .i from 1 to .n
        for .j from 1 to .k
            .dev = .data## [.i, .j] - .grand
            .ssTot = .ssTot + .dev * .dev
        endfor
    endfor
    .ssErr = .ssTot - .ssCond - .ssSubj
    if .ssErr < 0
        .ssErr = 0
    endif
    .dfCond = .k - 1
    .dfErr = (.k - 1) * (.n - 1)
    .msCond = .ssCond / .dfCond
    .msErr = .ssErr / .dfErr

    # --- refuse a zero error term ----------------------------------------
    # If every subject shows the same pattern across conditions, the
    # subject x condition residual is identically zero, .ssErr is zero, and
    # F is a division by zero. Praat does not raise on that; it returns a
    # finite number built out of the last bits of the subtraction, which
    # prints as F(2, 6) = 21110623253299200.0000 with a p-value carrying 48
    # decimal places. The post-hoc in this same module refuses the same
    # condition, naming it "All differences are identical (zero variance)".
    #
    # The floor has to be RELATIVE. An exactly-linear design leaves .ssErr
    # at around 1e-16 of .ssTot rather than at 0, so an absolute test for
    # equality with zero does not fire.
    .error$ = ""
    ; .warning$ is the EXPORTED sentence and .warningPrinted$ the printed one;
    ; both are cleared here rather than at the branch, because the degenerate
    ; arm jumps to RM_TEST_DONE without reaching either and a Praat procedure's
    ; locals survive from the previous invocation. See item 12b below.
    .warning$ = ""
    .warningPrinted$ = ""
    .degenerate = 0
    if .ssTot <= 0
        .degenerate = 1
        .error$ = "Every value in every condition is identical, so there "
        ... + "is no variance to partition."
    elsif .ssErr <= 1e-10 * .ssTot
        .degenerate = 1
        .error$ = "The subject x condition residual is zero: every "
        ... + "subject shows exactly the same pattern across conditions. "
        ... + "The error term for the F test is therefore zero and F is "
        ... + "undefined. Data that behaves this way is usually "
        ... + "simulated, already averaged, or derived from one of its "
        ... + "own columns."
    endif

    if .degenerate
        .fStat = undefined
        .p = undefined
        .ggEpsilon = undefined
        .pGG = undefined
        goto RM_TEST_DONE
    endif

    .fStat = .msCond / .msErr
    .p = fisherQ (.fStat, .dfCond, .dfErr)
    @emlGGEpsilon: .data##, .n, .k
    .ggEpsilon = emlGGEpsilon.epsilon
    .pGG = fisherQ (.fStat, .dfCond * .ggEpsilon, .dfErr * .ggEpsilon)

    # --- say when the design has no information left ----------------------
    # With n = 2 subjects, df error = k - 1 and the Greenhouse-Geisser
    # epsilon is forced to its lower bound 1 / (k - 1) whatever the data
    # are. The result computes and prints; nothing about it is
    # interpretable. Epsilon pinned to the bound is the tell, and it is
    # already in hand at the moment of printing.
    #
    # ONE SENTENCE, TWO ARTEFACTS, TWO RULES. This warning has two
    # destinations that do not want the same thing from it.
    # @emlReportRepeatedMeasures wraps it into the Info window, where every
    # statistic is four decimals wide; @emlDeclareRMResult hands the same
    # string to @emlGlanceStr as the glance frame's `warning` cell, where the
    # file is the artefact a reader computes from and precision is owed rather
    # than trimmed. Reformatting one string for the report would silently edit
    # an exported value, so there are two: .warning$ keeps the exact bytes the
    # export needs and is what @emlGlanceStr writes; .warningPrinted$ is the
    # same sentence with the bound routed through @eml_fixed and is what the
    # report prints. Neither destination constrains the other, and an edit to
    # either cannot reach across into the artefact it does not own.
    # validate/v65_display_standard.R's census names the export class this
    # sits in.
    #
    # THE TWO STRINGS ARE IDENTICAL FOR EVERY k THIS PLUGIN CAN BE DRIVEN AT,
    # and saying so plainly is more useful than implying a symptom that is not
    # there. Measured on Praat 6.6.30: fixed$ (x, 4) escalates
    # past four decimals once |x| < 1e-4, and the bound is 1 / (k - 1), so the
    # first k at which the two renderings differ is 10002 -- fixed$ writes
    # "0.00010" and @eml_fixed writes "0.0001". Above about k = 20002 the gap
    # widens to "0.00005" against "0.0000". Neither is a repeated-measures
    # design. validate/v71_tidy_vocab_and_warning.R re-measures the threshold
    # on the binary under test rather than quoting this paragraph, so the day
    # a future Praat changes fixed$ the file says so.
    #
    # What the split buys is therefore not a difference in today's output: it
    # is that the report and the export do not share a formatter, so neither
    # can be changed by an edit aimed at the other. A validator that only
    # measured the printed width would not see the difference, and v71 says so
    # in its own header rather than pretending otherwise.
    #
    # NOT A SECOND FORMATTER. @eml_fixed lives in stats/eml-output.praat and is
    # the only rounding in the plugin; this builds a second STRING, not a
    # second rule for how a number is written.
    if .n <= 2
        .warning$ = "n = " + string$ (.n) + " subjects. Greenhouse-Geisser "
        ... + "epsilon is forced to its lower bound "
        ... + fixed$ (1 / (.k - 1), 4) + " for any data at this n, so the "
        ... + "sphericity correction carries no information. Read F, p "
        ... + "and the corrected p as description of these two subjects, "
        ... + "not as a test."
        @eml_fixed: 1 / (.k - 1), 4
        .warningPrinted$ = "n = " + string$ (.n) + " subjects. "
        ... + "Greenhouse-Geisser epsilon is forced to its lower bound "
        ... + eml_fixed.result$ + " for any data at this n, so the "
        ... + "sphericity correction carries no information. Read F, p "
        ... + "and the corrected p as description of these two subjects, "
        ... + "not as a test."
    elsif .ggEpsilon <= 1 / (.k - 1) + 1e-9
        .warning$ = "Greenhouse-Geisser epsilon is at its lower bound "
        ... + fixed$ (1 / (.k - 1), 4) + ", the maximum possible departure "
        ... + "from sphericity. The corrected p is the most conservative "
        ... + "value the correction can produce."
        @eml_fixed: 1 / (.k - 1), 4
        .warningPrinted$ = "Greenhouse-Geisser epsilon is at its lower bound "
        ... + eml_fixed.result$ + ", the maximum possible departure "
        ... + "from sphericity. The corrected p is the most conservative "
        ... + "value the correction can produce."
    endif

    label RM_TEST_DONE
endproc

# ============================================================================
# @emlRunRepeatedMeasuresAnalysis — parametric RM-ANOVA orchestrator.
#
# v1.2 item 7: .subjectCol$ is RESERVED and deliberately unread. The data are
# in wide format — one row per subject, one column per condition — so the row
# index already identifies the subject and no subject column is required.
# The parameter is retained because callers pass arguments positionally;
# removing it would silently shift .conditionCols$, .doPostHoc and
# .adjMethod$ at every call site. It is kept for a future long-format path.
# ============================================================================
procedure emlRunRepeatedMeasuresAnalysis: .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$
    .recResult$ = ""
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""
    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlExtractConditionMatrix: .tableId, .conditionCols$
    if emlExtractConditionMatrix.error$ <> ""
        .error$ = emlExtractConditionMatrix.error$
        goto END_RM
    endif
    .n = emlExtractConditionMatrix.n
    .k = emlExtractConditionMatrix.k
    .data## = emlExtractConditionMatrix.data##
    .nExcluded = emlExtractConditionMatrix.nExcluded

    @emlRMAnovaTest: .data##, .n, .k
    ; CAPTURED AT THE TEST. The reporter re-runs it, and a Praat procedure's
    ; outputs live only until the next invocation. Greenhouse-Geisser is
    ; carried too: the corrected p is the one a reader should quote when
    ; sphericity is doubtful, and it was nowhere in the record.
    if emlRMAnovaTest.degenerate = 0
        .recResult$ = "F(" + string$ (emlRMAnovaTest.dfCond) + ", "
        ... + string$ (emlRMAnovaTest.dfErr) + ") = "
        ... + fixed$ (emlRMAnovaTest.fStat, 4) + ", p = "
        ... + fixed$ (emlRMAnovaTest.p, 4) + newline$
        ... + "  Greenhouse-Geisser epsilon = "
        ... + fixed$ (emlRMAnovaTest.ggEpsilon, 4) + ", corrected p = "
        ... + fixed$ (emlRMAnovaTest.pGG, 4) + newline$
        ... + "  n = " + string$ (.n) + " subjects, k = " + string$ (.k)
        ... + " conditions"
    endif

    # A zero error term is a property of the data, not a bad form setting,
    # so there is no other menu item that would work on it: the remedy stays
    # empty and the dialog says only what is wrong.
    #
    # AND IT HAS TO BE TRUE OF THE SAMPLE IT WAS COMPUTED ON.
    # @emlRMAnovaTest sees the complete-case matrix, so "every subject shows
    # exactly the same pattern" means every RETAINED subject. The exclusion
    # note is printed further down, on the success path, which this jump
    # skips -- so the disclosure is attached here.
    if emlRMAnovaTest.error$ <> ""
        .error$ = emlRMAnovaTest.error$
        @eml_completeCaseDisclosure: .n + .nExcluded, .n, .nExcluded,
        ... emlExtractConditionMatrix.parseNote$
        if eml_completeCaseDisclosure.note$ <> ""
            .error$ = .error$ + " " + eml_completeCaseDisclosure.note$
        endif
        goto END_RM
    endif

    @emlCSVInit
    .h$ = "Repeated-measures ANOVA — " + .tableName$
    appendInfoLine: .h$
    .subj$ = "  Subjects (complete cases) n = " + string$ (.n)
        ... + ", conditions k = " + string$ (.k)
    appendInfoLine: .subj$
    ; As in @emlReportPairwiseDescriptives -- a condition mean of
    ; zero is a mean like any other and prints at the column's width.
    for .j from 1 to .k
        @eml_fixed: emlRMAnovaTest.condMean# [.j], 4
        .cm$ = "    " + emlExtractConditionMatrix.colLabel$ [.j] + " mean = "
            ... + eml_fixed.result$
        appendInfoLine: .cm$
    endfor
    ; BOTH NUMBERS ON THIS LINE ARE FORMATTED. "p = " + fixed$ (p, 4) prints
    ; twenty-nine decimal places for a real RM-ANOVA p of 3e-29, so the p goes
    ; through @emlInlineP, which gives the APA rendering the rest of the
    ; plugin uses and appends the unrounded value when that rendering has
    ; floored it. The F goes through @eml_fixed for the same reason: an F of
    ; zero -- which is what identical condition means give -- comes out of a
    ; bare fixed$ as "0", next to an APA p.
    @emlInlineP: emlRMAnovaTest.p
    @eml_fixed: emlRMAnovaTest.fStat, 4
    .fLine$ = "  F(" + string$ (emlRMAnovaTest.dfCond) + ", "
        ... + string$ (emlRMAnovaTest.dfErr) + ") = "
        ... + eml_fixed.result$ + ", " + emlInlineP.text$
    appendInfoLine: .fLine$
    @emlInlineP: emlRMAnovaTest.pGG
    @eml_fixed: emlRMAnovaTest.ggEpsilon, 4
    .ggLine$ = "  Greenhouse-Geisser epsilon = "
        ... + eml_fixed.result$ + ", GG-corrected "
        ... + emlInlineP.text$
    appendInfoLine: .ggLine$

    ; AN EFFECT SIZE, not only F, p and epsilon: without one the report says
    ; how unlikely the condition effect is under the null and not how big it
    ; is. Partial eta squared is
    ; ssCond / (ssCond + ssErr) and both terms are already computed; this is
    ; the same quantity the glance frame exports as partial.eta.squared.
    .denom = emlRMAnovaTest.ssCond + emlRMAnovaTest.ssErr
    if .denom > 0
        ; An eta squared of nothing is the case this most often
        ; lands on, and it is exactly where fixed$ gives a bare "0".
        @eml_fixed: emlRMAnovaTest.ssCond / .denom, 4
        .petaLine$ = "  Partial eta squared = "
            ... + eml_fixed.result$
            ... + "  (condition SS / (condition SS + error SS))"
    else
        .petaLine$ = "  Partial eta squared = n/a (no variance to partition)"
    endif
    appendInfoLine: .petaLine$

    # Printed immediately under the numbers it qualifies, not at the
    # foot of the report, because a caveat below the post-hoc table reads
    # as being about the post-hoc.
    #
    # THE PRINTED half of the split pair. The test still decides
    # WHETHER there is a caution from .warning$ -- the two are empty and
    # non-empty together, and reading the condition off the exported string
    # keeps that fact in one place -- but what reaches the Info window is
    # .warningPrinted$, whose epsilon bound went through @eml_fixed. Swapping
    # this back to .warning$ would put a raw fixed$ in front of a reader
    # without touching a number, which is why validate/v71 asserts the
    # reference here by name and not just the width of what came out.
    if emlRMAnovaTest.warning$ <> ""
        @emlWrapText: "Caution: " + emlRMAnovaTest.warningPrinted$, 68
        for .wl from 1 to emlWrapText.nLines
            appendInfoLine: "  ", emlWrapText.line$ [.wl]
        endfor
    endif

    if .doPostHoc
        @emlRMPostHoc: .data##, .n, .k, "parametric", .adjMethod$
    endif
    if .nExcluded > 0
        .exclNote$ = "  Note: " + string$ (.nExcluded)
            ... + " row(s) excluded for missing data (analyzed n = "
            ... + string$ (.n) + " complete cases)."
        appendInfoLine: .exclNote$
        # Say WHICH condition dropped the row and why.
        if emlExtractConditionMatrix.parseNote$ <> ""
            @emlWrapText: emlExtractConditionMatrix.parseNote$, 66
            for .pl from 1 to emlWrapText.nLines
                appendInfoLine: "  ", emlWrapText.line$ [.pl]
            endfor
        endif
    endif

    ; BUILD: no reporter and no CSV emission ever existed for this path.
    if .error$ = ""
        @emlResultClearExtras
        ; Nested, not `and`: with post-hoc off, @emlRMPostHoc never ran and
        ; emlRMPostHoc.nPairs does not exist. Praat evaluates both operands.
        if .doPostHoc = 1
            if variableExists ("emlRMPostHoc.nPairs")
                if emlRMPostHoc.nPairs > 0
                    @emlDeclareRMPostHoc
                    @emlResultStageExtra: "posthoc"
                endif
            endif
        endif
        @emlDeclareRMResult: .tableName$, .n, .k
    endif

    label END_RM

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Repeated-measures ANOVA",
        ... .conditionCols$ + ", subject " + .subjectCol$,
        ... "Sphericity is corrected, not assumed; the report names the correction.",
        ... "@emlRunRepeatedMeasuresAnalysis: data, """ + .subjectCol$ + """, """ + .conditionCols$ + """, " + string$ (.doPostHoc) + ", """ + .adjMethod$ + """",
        ... "In the GUI: New > EML Tools > Compare paired/repeated...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc

# ============================================================================
# @emlRunFriedmanAnalysis — nonparametric repeated-measures orchestrator.
#
# v1.2 item 7: .subjectCol$ is RESERVED and deliberately unread, for the same
# reason as @emlRunRepeatedMeasuresAnalysis — wide-format input, so the row
# index identifies the subject. Retained because callers pass positionally.
# ============================================================================
procedure emlRunFriedmanAnalysis: .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$
    .recResult$ = ""
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set: a repeated-measures run that bails on "Need at
    ; least 2 condition columns" would export the previous analysis's tidy and
    ; glance under the RM name.
    @emlCSVInit
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists.
    .remedy$ = ""
    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlExtractConditionMatrix: .tableId, .conditionCols$
    if emlExtractConditionMatrix.error$ <> ""
        .error$ = emlExtractConditionMatrix.error$
        goto END_FRIED
    endif
    .n = emlExtractConditionMatrix.n
    .k = emlExtractConditionMatrix.k
    .data## = emlExtractConditionMatrix.data##
    .nExcluded = emlExtractConditionMatrix.nExcluded

    @emlFriedmanTest: .data##, .n, .k
    ; Same rule as the repeated-measures path: captured where it is fresh.
    .recResult$ = "chi-square(" + string$ (emlFriedmanTest.df) + ") = "
    ... + fixed$ (emlFriedmanTest.chiSq, 4) + ", p = "
    ... + fixed$ (emlFriedmanTest.p, 4) + newline$
    ... + "  n = " + string$ (.n) + " subjects, k = " + string$ (.k)
    ... + " conditions"

    @emlCSVInit
    .h$ = "Friedman test — " + .tableName$
    appendInfoLine: .h$
    .subj$ = "  Subjects (complete cases) n = " + string$ (.n)
        ... + ", conditions k = " + string$ (.k)
    appendInfoLine: .subj$
    ; As on the repeated-measures path above.
    for .j from 1 to .k
        @eml_fixed: emlFriedmanTest.rankSum# [.j], 1
        .rs$ = "    " + emlExtractConditionMatrix.colLabel$ [.j] + " rank sum = "
            ... + eml_fixed.result$
        appendInfoLine: .rs$
    endfor
    ; BOTH NUMBERS FORMATTED, as on the RM path: a bare fixed$ (p, 4) renders
    ; a p of 2e-25 as a twenty-five place decimal string, and a chi-square of
    ; zero as "0".
    @emlInlineP: emlFriedmanTest.p
    @eml_fixed: emlFriedmanTest.chiSq, 4
    .chiLine$ = "  chi-square(" + string$ (emlFriedmanTest.df) + ") = "
        ... + eml_fixed.result$ + ", " + emlInlineP.text$
    appendInfoLine: .chiLine$

    ; AN EFFECT SIZE beside the chi-square and p. Kendall's W is
    ; chi-square / (n * (k - 1)) — the same quantity the glance frame
    ; exports as kendalls.w — and runs 0 (no agreement across subjects) to
    ; 1 (every subject ranks the conditions identically).
    if .n > 0 and .k > 1
        ; W = 0 is "no agreement", a stated endpoint of the scale
        ; the sentence beside it describes, and a bare fixed$ prints it as
        ; "0".
        @eml_fixed: emlFriedmanTest.chiSq / (.n * (.k - 1)), 4
        .wLine$ = "  Kendall's W = "
            ... + eml_fixed.result$
            ... + "  (0 = no agreement, 1 = identical rankings)"
    else
        .wLine$ = "  Kendall's W = n/a"
    endif
    appendInfoLine: .wLine$

    if .doPostHoc
        @emlRMPostHoc: .data##, .n, .k, "nonparametric", .adjMethod$
    endif
    if .nExcluded > 0
        .exclNote$ = "  Note: " + string$ (.nExcluded)
            ... + " row(s) excluded for missing data (analyzed n = "
            ... + string$ (.n) + " complete cases)."
        appendInfoLine: .exclNote$
        # Say WHICH condition dropped the row and why.
        if emlExtractConditionMatrix.parseNote$ <> ""
            @emlWrapText: emlExtractConditionMatrix.parseNote$, 66
            for .pl from 1 to emlWrapText.nLines
                appendInfoLine: "  ", emlWrapText.line$ [.pl]
            endfor
        endif
    endif

    ; BUILD. @emlFriedmanTest exposes NO .error$ field -- referencing one is a
    ; runtime error -- so the gate is the extractor's error and the
    ; orchestrator's own.
    if .error$ = "" and emlExtractConditionMatrix.error$ = ""
        @emlResultClearExtras
        ; Nested, not `and`: with post-hoc off, @emlRMPostHoc never ran and
        ; emlRMPostHoc.nPairs does not exist. Praat evaluates both operands.
        if .doPostHoc = 1
            if variableExists ("emlRMPostHoc.nPairs")
                if emlRMPostHoc.nPairs > 0
                    @emlDeclareFriedmanPostHoc
                    @emlResultStageExtra: "posthoc"
                endif
            endif
        endif
        @emlDeclareFriedmanResult: .tableName$, .n, .k
    endif

    label END_FRIED

    ; RECORD WORKFLOW. Inert unless a recording is running. Placed after
    ; the end label so a refusal is recorded as a step rather than
    ; vanishing -- see @emlRecordAnalysisStep.
    ; PRESENT, INITIALISED, RECORDING -- the same three-part guard every
    ; draw hook uses, and it was missing here. eml-analysis.praat is
    ; loadable WITHOUT the recorder: plugin/dev/tests/phase2 includes the
    ; stats tree and not eml-record.praat, and an unguarded call killed
    ; that suite outright with Procedure "emlRecordAnalysisStep" not
    ; found. emlRecordLoaded is set at LOAD time, so a caller that never
    ; loaded the recorder executes nothing here.
    if variableExists ("emlRecordLoaded")
        @emlRecordAnalysisStep: .tableId, "Friedman",
        ... .conditionCols$ + ", subject " + .subjectCol$,
        ... "Rank-based repeated measures; it does not assume normality and does not test it.",
        ... "@emlRunFriedmanAnalysis: data, """ + .subjectCol$ + """, """ + .conditionCols$ + """, " + string$ (.doPostHoc) + ", """ + .adjMethod$ + """",
        ... "In the GUI: New > EML Tools > Compare paired/repeated (Friedman)...",
        ... .recResult$, .error$
    endif

    selectObject: .tableId
endproc

# ============================================================================
# @emlRMPostHoc — pairwise post-hoc for repeated-measures designs.
# Parametric -> paired t; nonparametric -> Wilcoxon signed-rank.
# p-values adjusted by .adjMethod$ (bonferroni / holm / bh).
# ============================================================================
procedure emlRMPostHoc: .data##, .n, .k, .testType$, .adjMethod$
    # THE REQUESTED ADJUSTMENT METHOD IS VALIDATED. An unrecognised string
    # falls back to Holm, and the fallback is disclosed: the header prints
    # the method that actually ran (.adjUsed$), never the one that was asked
    # for, because a header naming a method that did not run is a false claim.
    .adjUsed$ = .adjMethod$
    .adjWarn$ = ""
    if .adjMethod$ <> "bonferroni" and .adjMethod$ <> "bh" and .adjMethod$ <> "holm"
        .adjUsed$ = "holm"
        .adjWarn$ = "    WARNING: unrecognised adjustment method """
            ... + .adjMethod$ + """ — used ""holm"" instead."
    endif
    .nPairs = .k * (.k - 1) / 2
    .rawP# = zero# (.nPairs)
    .nSkipped = 0
    .pairIdx = 0
    for .a from 1 to .k - 1
        for .b from .a + 1 to .k
            .pairIdx = .pairIdx + 1
            .va# = zero# (.n)
            .vb# = zero# (.n)
            for .i from 1 to .n
                .va# [.i] = .data## [.i, .a]
                .vb# [.i] = .data## [.i, .b]
            endfor
            # v1.2 item 1: the pairwise test can fail (zero-variance
            # differences, all-zero differences, too few pairs). Previously
            # its undefined .p was written straight into .rawP#, and the
            # adjustment procedure rendered it as an adjusted p of 0 — a
            # false "significant" result. Propagate undefined instead.
            if .testType$ = "parametric"
                @emlTTestPaired: .va#, .vb#, 2
                .pairErr$ = emlTTestPaired.error$
                .pairP = emlTTestPaired.p
            else
                @emlWilcoxonSignedRank: .va#, .vb#, 2
                .pairErr$ = emlWilcoxonSignedRank.error$
                .pairP = emlWilcoxonSignedRank.p
            endif
            .pairNote$ [.pairIdx] = ""
            if .pairErr$ <> ""
                .rawP# [.pairIdx] = undefined
                .pairNote$ [.pairIdx] = .pairErr$
                .nSkipped = .nSkipped + 1
            elsif .pairP = undefined
                .rawP# [.pairIdx] = undefined
                .pairNote$ [.pairIdx] = "test returned an undefined p-value"
                .nSkipped = .nSkipped + 1
            else
                .rawP# [.pairIdx] = .pairP
            endif
            .pairLabelA [.pairIdx] = .a
            .pairLabelB [.pairIdx] = .b
        endfor
    endfor
    if .adjUsed$ = "bonferroni"
        @emlBonferroni: .rawP#
        .adj# = emlBonferroni.adjusted#
    elsif .adjUsed$ = "bh"
        @emlBenjaminiHochberg: .rawP#
        .adj# = emlBenjaminiHochberg.adjusted#
    else
        @emlHolm: .rawP#
        .adj# = emlHolm.adjusted#
    endif
    ; Same reason as the pairwise report header: the adjustment key is
    ; lowercase because that is what the engines take; the heading should
    ; read the way the user's optionmenu reads.
    @emlAdjustMethodDisplay: .adjUsed$
    .phHdr$ = "  Post-hoc pairwise (" + .testType$ + ", "
        ... + emlAdjustMethodDisplay.name$ + "-adjusted):"
    appendInfoLine: .phHdr$
    if .adjWarn$ <> ""
        appendInfoLine: .adjWarn$
    endif
    for .pp from 1 to .nPairs
        .ai = .pairLabelA [.pp]
        .bi = .pairLabelB [.pp]
        ; A bare fixed$ (p, 4) prints these p-values as long decimal
        ; strings. @emlInlineP.bare$ is the APA rendering
        ; without the "p = " prefix, because the label here already says
        ; which p it is.
        if .rawP# [.pp] = undefined
            .rawTxt$ = "p n/a"
            .adjTxt$ = "p n/a"
        else
            @emlInlineP: .rawP# [.pp]
            .rawTxt$ = emlInlineP.text$
            if .adj# [.pp] = undefined
                .adjTxt$ = "p n/a"
            else
                @emlInlineP: .adj# [.pp]
                .adjTxt$ = emlInlineP.text$
            endif
        endif
        ; "raw p < .001" rather than "p(raw) = < .001": the APA rendering
        ; carries its own relational operator, so the label must not supply
        ; a second one.
        .row$ = "    " + emlExtractConditionMatrix.colLabel$ [.ai] + " vs "
            ... + emlExtractConditionMatrix.colLabel$ [.bi] + ": raw "
            ... + .rawTxt$ + ", adj " + .adjTxt$
        appendInfoLine: .row$
    endfor
    if .nSkipped > 0
        .skipHdr$ = "    NOTE: " + string$ (.nSkipped) + " of "
            ... + string$ (.nPairs) + " comparisons could not be computed"
            ... + " and are excluded from the multiplicity adjustment:"
        appendInfoLine: .skipHdr$
        for .pp from 1 to .nPairs
            if .pairNote$ [.pp] <> ""
                .ai = .pairLabelA [.pp]
                .bi = .pairLabelB [.pp]
                .warnRow$ = "      " + emlExtractConditionMatrix.colLabel$ [.ai]
                    ... + " vs " + emlExtractConditionMatrix.colLabel$ [.bi]
                    ... + ": " + .pairNote$ [.pp]
                appendInfoLine: .warnRow$
            endif
        endfor
    endif
endproc


# ============================================================================
# @emlRunLMMAnalysis LIVES AT THE FOOT OF stats/eml-lmm.praat, beside the
# engine it calls, and not in this file.
#
# This file is included by every wrapper; the engine (@emlLMM,
# @emlLMMSummary, @emlJohnsonR2, @emlWaldCI) is in a module no wrapper
# includes. An orchestrator here would therefore give nine wrappers four
# calls apiece that cannot resolve -- and Praat resolves a procedure name
# when it is CALLED, so no parse check can see them.
# harness/check_includes.py is what finds this class of defect.
#
# Orchestrator and engine travel together: including eml-lmm.praat gets
# both, including neither gets neither, and there is no third state.
# ============================================================================


# ============================================================================
# END OF EML ANALYSIS ORCHESTRATORS
# ============================================================================


# ============================================================================
# @emlDeclareOneWayAnovaResult
# ============================================================================
# Declare a completed one-way ANOVA in broom's three-file shape, so the export
# surface can write tidy / glance / augment instead of one wide file.
#
# WHY THE SPLIT IS THREE FILES AND NOT ONE
#
# broom's three verbs answer three different questions and have three
# different row counts, which is exactly why they cannot share a table:
#
#   tidy()     one row per model TERM        (here: the factor, and Residuals)
#   glance()   one row for the MODEL         (r.squared, AIC, nobs, ...)
#   augment()  one row per OBSERVATION       (.fitted, .resid, .std.resid)
#
# A single wide file has to pick one of those row counts and pad or repeat for
# the other two, which is what the old exporter did.
#
# TukeyHSD and the effect sizes are SEPARATE MODEL OBJECTS in R --
# tidy(TukeyHSD(fit)) and effectsize::eta_squared(fit) each return their own
# frame, and base aov carries neither. Keeping them out of the two files above
# is what makes those two comparable with broom's own output rather than
# merely broom-flavoured. They are written as their own tidy files.
#
# Called by @emlRunAnovaAnalysis AFTER the reporter, so emlOneWayAnova.* holds
# the values that were actually printed.
#
# Input:
#   .tableName$ - name of the source Table, for the file base name
#   .dataCol$   - measure column
#   .groupCol$  - factor column
#   .tableId    - the Table, for augment
#   .doTukey    - whether post-hoc contrasts were run
#
# Output:
#   emlResult_* collectors, ready for @emlResultWrite / @emlResultWriteTidy
#   .extraTidy$ - newline-separated base names of the additional tidy frames
# ============================================================================
procedure emlDeclareOneWayAnovaResult: .tableName$, .dataCol$, .groupCol$,
    ... .tableId, .doTukey
    .extraTidy$ = ""

    if emlOneWayAnova.error$ <> ""
        goto DECLARE_ANOVA_DONE
    endif

    @emlResultBegin: .tableName$, "One-way ANOVA"

    ; ---- tidy: one row per term, then Residuals, exactly as tidy(aov) ----
    @emlTidyRow: .groupCol$
    @emlTidyNum: "df", emlOneWayAnova.dfBetween
    @emlTidyNum: "sumsq", emlOneWayAnova.ssBetween
    @emlTidyNum: "meansq", emlOneWayAnova.msBetween
    @emlTidyNum: "statistic", emlOneWayAnova.fValue
    @emlTidyNum: "p.value", emlOneWayAnova.p

    @emlTidyRow: "Residuals"
    @emlTidyNum: "df", emlOneWayAnova.dfWithin
    @emlTidyNum: "sumsq", emlOneWayAnova.ssWithin
    @emlTidyNum: "meansq", emlOneWayAnova.msWithin
    ; statistic and p.value deliberately absent on Residuals: broom leaves them
    ; NA, and an empty cell is how this writer says NA.

    ; ---- glance: one row for the model ----
    .nobs = 0
    for .g from 1 to emlOneWayAnova.nGroups
        .nobs = .nobs + emlOneWayAnova.groupN [.g]
    endfor
    @emlGlanceNum: "r.squared", emlOneWayAnova.etaSquared
    @emlGlanceNum: "adj.r.squared", 1 - (1 - emlOneWayAnova.etaSquared)
    ... * (.nobs - 1) / emlOneWayAnova.dfWithin
    @emlGlanceNum: "sigma", sqrt (emlOneWayAnova.msWithin)
    @emlGlanceNum: "statistic", emlOneWayAnova.fValue
    @emlGlanceNum: "p.value", emlOneWayAnova.p
    @emlGlanceNum: "df", emlOneWayAnova.dfBetween

    ; Gaussian log-likelihood in closed form, so AIC and BIC are the numbers R
    ; reports. k = nGroups fitted means + 1 residual variance.
    .rss = emlOneWayAnova.ssWithin
    .logLik = -0.5 * .nobs * (ln (2 * pi) + ln (.rss / .nobs) + 1)
    .k = emlOneWayAnova.nGroups + 1
    @emlGlanceNum: "logLik", .logLik
    @emlGlanceNum: "AIC", -2 * .logLik + 2 * .k
    @emlGlanceNum: "BIC", -2 * .logLik + ln (.nobs) * .k
    @emlGlanceNum: "deviance", .rss
    @emlGlanceNum: "df.residual", emlOneWayAnova.dfWithin
    @emlGlanceNum: "nobs", .nobs
    @emlGlanceNum: "n.groups", emlOneWayAnova.nGroups
    @emlGlanceStr: "method", "One-way ANOVA"

    ; ---- augment: the input table plus what the model says about each row ----
    ;
    ; LEVERAGE, AND WHY IT IS EXACT HERE.
    ; `.std.resid` is NOT resid / sigma. broom's augment(aov) returns
    ; rstandard(), which is e_i / (s * sqrt(1 - h_i)); the regression arm gets
    ; that from @emlOLSInfluence, and the ANOVA arms have to publish the same
    ; quantity under R's name. Dropping the leverage term costs a uniform
    ; 4.4% understatement on a balanced two-way design (1 / sqrt(1 - 1/12) =
    ; 1.044466) and a per-observation one that grows with leverage as soon as
    ; the design is unbalanced.
    ;
    ; No hat matrix has to be formed. A one-way ANOVA fits one mean per group,
    ; so the fitted value of an observation is its own group's mean and the
    ; leverage is exactly 1 / n_group -- the projection onto a group-indicator
    ; basis, computed here from the count the glance frame already used. Same
    ; identity, same arithmetic, no linear algebra.
    ;
    ; `.hat` is in emlVocabAugment$, so the leverage that does the correcting
    ; is in the file beside the corrected value. A column NOT in the
    ; vocabulary would be dropped by @eml_orderedCols in silence rather than
    ; refused, which is why the vocabulary entry is stated rather than
    ; assumed.
    ;
    ; A group of one has leverage 1, so its standardised residual is 0/0.
    ; @emlOneWayAnova refuses that case before reaching here (a group needs at
    ; least 2 observations), but the guard is written anyway: an empty cell
    ; reads back as NA, which is what R prints for the same row.
    @emlAugmentFrom: .tableId
    selectObject: .tableId
    .nRows = Get number of rows
    .sigma = sqrt (emlOneWayAnova.msWithin)
    for .r from 1 to .nRows
        selectObject: .tableId
        .g$ = Get value: .r, .groupCol$
        .v$ = Get value: .r, .dataCol$
        .v = number (.v$)
        .fit = undefined
        .hat = undefined
        for .g from 1 to emlOneWayAnova.nGroups
            if emlOneWayAnova.groupLabel$ [.g] = .g$
                .fit = emlOneWayAnova.groupMean [.g]
                .hat = 1 / emlOneWayAnova.groupN [.g]
            endif
        endfor
        if .fit <> undefined and .v <> undefined
            @emlAugmentNum: ".fitted", .r, .fit
            @emlAugmentNum: ".resid", .r, .v - .fit
            @emlAugmentNum: ".hat", .r, .hat
            .std = undefined
            if .hat < 1
                .std = (.v - .fit) / (.sigma * sqrt (1 - .hat))
            endif
            @emlAugmentNum: ".std.resid", .r, .std
        endif
    endfor

    label DECLARE_ANOVA_DONE
endproc


# ============================================================================
# @emlDeclareTukeyResult
# ============================================================================
# tidy(TukeyHSD(fit)) is its own frame: term, contrast, null.value, estimate,
# conf.low, conf.high, adj.p.value. The interval is Tukey's own,
# diff +/- qCrit * sqrt(msWithin/2 * (1/ni + 1/nj)), using the studentised-range
# critical value @emlTukeyHSD already computed -- not a t interval, which would
# be narrower and would not carry the familywise correction adj.p carries.
#
# Call AFTER @emlResultWrite has flushed tidy/glance/augment, since it reuses
# the tidy collector.
# ============================================================================
procedure emlDeclareTukeyResult: .groupCol$
    @emlTidyClear
    for .i from 1 to emlOneWayAnova.nGroups - 1
        for .j from .i + 1 to emlOneWayAnova.nGroups
            .diff = emlOneWayAnova.meanDiff## [.i, .j]
            .ni = emlOneWayAnova.groupN [.i]
            .nj = emlOneWayAnova.groupN [.j]
            .halfWidth = emlOneWayAnova.qCritical
            ... * sqrt (emlOneWayAnova.msWithin / 2 * (1 / .ni + 1 / .nj))
            @emlTidyRow: .groupCol$
            @emlTidyStr: "contrast", emlOneWayAnova.groupName$ [.i] + "-"
            ... + emlOneWayAnova.groupName$ [.j]
            @emlTidyNum: "null.value", 0
            @emlTidyNum: "estimate", .diff
            @emlTidyNum: "conf.low", .diff - .halfWidth
            @emlTidyNum: "conf.high", .diff + .halfWidth
            @emlTidyNum: "adj.p.value", emlOneWayAnova.pMatrix## [.i, .j]
        endfor
    endfor
endproc


# ============================================================================
# @emlDeclareAnovaEffectSizes
# ============================================================================
# effectsize::eta_squared(fit) and effectsize::cohens_d() are again separate
# frames in R; base aov and TukeyHSD carry neither. Same treatment here.
# Call AFTER the Tukey frame has been flushed.
# ============================================================================
procedure emlDeclareAnovaEffectSizes: .groupCol$, .doTukey
    @emlTidyClear
    @emlTidyRow: .groupCol$
    @emlTidyNum: "effect.size", emlOneWayAnova.etaSquared
    @emlTidyStr: "effect.size.type", "eta.squared"

    ; The per-pair Cohen's d, and the group names it labels them with, are
    ; produced by the Tukey pass. With post-hoc off they do not exist, and
    ; reading them aborts the script -- the same shape of defect as the
    ; single-family guards above, found the same way.
    if .doTukey <> 1
        goto ANOVA_EFFECTS_DONE
    endif
    for .i from 1 to emlOneWayAnova.nGroups - 1
        for .j from .i + 1 to emlOneWayAnova.nGroups
            @emlTidyRow: .groupCol$
            @emlTidyStr: "contrast", emlOneWayAnova.groupName$ [.i] + "-"
            ... + emlOneWayAnova.groupName$ [.j]
            @emlTidyNum: "effect.size", emlOneWayAnova.dMatrix## [.i, .j]
            @emlTidyStr: "effect.size.type", "cohens.d"
        endfor
    endfor

    label ANOVA_EFFECTS_DONE
endproc


# ============================================================================
#  BROOM-SHAPE DECLARATIONS FOR THE REMAINING ORCHESTRATORS
# ============================================================================
# Each @emlDeclare* below is called by its orchestrator AFTER the analysis has
# run, and fills the tidy / glance / augment collectors in eml-result-writer.
#
# THREE RULES THESE ALL FOLLOW, EACH FOR A REASON FOUND THE HARD WAY:
#
# 1. Gate on `.error$ = ""`, never on "is the value defined". Praat globals
#    persist across invocations, so a guard path leaves the PREVIOUS run's
#    numbers sitting in the namespace. Declaring on definedness would export
#    the last analysis's result under this one's name.
#
# 2. Stage the extra frames BEFORE the model frames. Staging reuses the one
#    tidy collector, so the model's own tidy has to be the last thing left in
#    it when @emlResultWrite runs.
#
# 3. Do not read a namespace that a later procedure re-enters. @emlRankBiserialR
#    re-runs @emlMannWhitneyU, @emlMatchedPairsR re-runs @emlWilcoxonSignedRank,
#    @emlDunnTest re-runs both. Read the outer values first or use the
#    orchestrator's own restored locals.
#
# SHAPE NOTE. broom has no augment() for htest objects -- there is no model to
# fit values from -- so the two-group, paired, correlation, KW, normality and
# Friedman declarations emit tidy and glance only. That is broom's shape, not
# an omission, and @emlResultWrite reports the absent augment as skipped
# rather than writing an empty file.
# ============================================================================


# --- 2. Two independent groups ---------------------------------------------
# tidy(t.test) is ONE row: estimate (the mean difference), estimate1,
# estimate2, statistic, p.value, parameter (df), method, alternative. There is
# no `term`. When the wrapper runs both families, one row per family is
# emitted and `method` is what distinguishes them -- an extension of broom's
# shape rather than a departure from it, since broom would produce two frames.
procedure emlDeclareTwoGroupResult: .tableName$, .dataCol$, .groupCol$,
    ... .doPar, .doNon, .g1$, .g2$
    @emlResultBegin: .tableName$, "Two-group comparison"

    if .doPar = 1
        if variableExists ("emlTTest.error$")
            if emlTTest.error$ = ""
                @emlTidyRow: ""
                @emlTidyNum: "estimate",  emlTTest.meanDiff
                @emlTidyNum: "estimate1", emlTTest.mean1
                @emlTidyNum: "estimate2", emlTTest.mean2
                @emlTidyNum: "statistic", emlTTest.t
                @emlTidyNum: "p.value",   emlTTest.p
                @emlTidyNum: "parameter", emlTTest.df
                @emlTidyStr: "method",      emlTTest.method$
                @emlTidyStr: "alternative", "two.sided"
            endif
        endif
    endif
    if .doNon = 1
        if variableExists ("emlMannWhitneyU.error$")
            if emlMannWhitneyU.error$ = ""
                @emlTidyRow: ""
                @emlTidyNum: "statistic",   emlMannWhitneyU.u1
                @emlTidyNum: "p.value",     emlMannWhitneyU.p
                @emlTidyStr: "method",      emlMannWhitneyU.method$
                @emlTidyStr: "alternative", emlMannWhitneyU.alternative$
            endif
        endif
    endif

    ; glance for an htest is broom's tidy again, plus what we know about the
    ; design. The parametric row wins when both ran, matching the report.
    if .doPar = 1
        if variableExists ("emlTTest.error$")
            if emlTTest.error$ = ""
                @emlGlanceNum: "statistic", emlTTest.t
                @emlGlanceNum: "p.value",   emlTTest.p
                @emlGlanceNum: "parameter", emlTTest.df
                @emlGlanceNum: "estimate",  emlTTest.meanDiff
                @emlGlanceStr: "method",    emlTTest.method$
                @emlGlanceNum: "nobs",      emlTTest.n1 + emlTTest.n2
            endif
        endif
    endif
    elsif .doNon = 1
        if variableExists ("emlMannWhitneyU.error$")
            if emlMannWhitneyU.error$ = ""
                @emlGlanceNum: "statistic", emlMannWhitneyU.u1
                @emlGlanceNum: "p.value",   emlMannWhitneyU.p
                @emlGlanceStr: "method",    emlMannWhitneyU.method$
                @emlGlanceNum: "nobs",      emlMannWhitneyU.n1 + emlMannWhitneyU.n2
            endif
        endif
    endif
    @emlGlanceNum: "n.groups", 2
endproc


procedure emlDeclareTwoGroupEffects: .doPar, .doNon
    @emlTidyClear
    if .doPar = 1
        if variableExists ("emlCohenD.error$")
            if emlCohenD.error$ = ""
                @emlTidyRow: ""
                @emlTidyNum: "effect.size", emlCohenD.d
                @emlTidyStr: "effect.size.type", "cohens.d"
                @emlTidyRow: ""
                @emlTidyNum: "effect.size", emlCohenD.g
                @emlTidyStr: "effect.size.type", "hedges.g"
            endif
        endif
    endif
    if .doNon = 1
        if variableExists ("emlRankBiserialR.error$")
            if emlRankBiserialR.error$ = ""
                @emlTidyRow: ""
                @emlTidyNum: "effect.size", emlRankBiserialR.r
                @emlTidyStr: "effect.size.type", "rank.biserial"
            endif
        endif
    endif
endproc


# --- 3. Kruskal-Wallis -----------------------------------------------------
procedure emlDeclareKWResult: .tableName$, .dataCol$, .groupCol$
    @emlResultBegin: .tableName$, "Kruskal-Wallis"
    @emlTidyRow: .groupCol$
    @emlTidyNum: "statistic", emlKruskalWallis.h
    @emlTidyNum: "p.value",   emlKruskalWallis.p
    @emlTidyNum: "parameter", emlKruskalWallis.df
    @emlTidyStr: "method",    "Kruskal-Wallis rank sum test"

    @emlGlanceNum: "statistic",       emlKruskalWallis.h
    @emlGlanceNum: "p.value",         emlKruskalWallis.p
    @emlGlanceNum: "parameter",       emlKruskalWallis.df
    @emlGlanceNum: "epsilon.squared", emlKruskalWallis.epsilonSq
    @emlGlanceNum: "tie.correction",  emlKruskalWallis.tieCorrection
    @emlGlanceNum: "nobs",            emlKruskalWallis.n
    @emlGlanceNum: "n.groups",        emlKruskalWallis.nGroups
    @emlGlanceStr: "method",          "Kruskal-Wallis rank sum test"
endproc


# Dunn is a second object: its own frame, with the raw p AND the adjusted p,
# because which one a reader wants depends on their correction policy and the
# old exporter forced a choice.
procedure emlDeclareDunnResult: .groupCol$
    @emlTidyClear
    .pair = 0
    for .i from 1 to emlDunnTest.nGroups - 1
        for .j from .i + 1 to emlDunnTest.nGroups
            .pair = .pair + 1
            @emlTidyRow: .groupCol$
            @emlTidyStr: "contrast", emlDunnTest.groupName$ [.i] + "-"
            ... + emlDunnTest.groupName$ [.j]
            @emlTidyNum: "statistic",   emlDunnTest.zMatrix## [.i, .j]
            @emlTidyNum: "p.value",     emlDunnTest.rawP# [.pair]
            @emlTidyNum: "adj.p.value", emlDunnTest.adjustedP# [.pair]
            @emlTidyStr: "method",      "Dunn (" + emlDunnTest.method$ + ")"
        endfor
    endfor
endproc


# --- 4. Pairwise comparisons — a BUILD, not a conversion -------------------
# There is no earlier shape to mirror here: @emlRunPairwiseAnalysis calls
# @emlCSVInit, so without these rows its export could not succeed at all.
# Three underlying procedures with three different output sets, so the branch
# is on .test$ exactly as the orchestrator's is.
procedure emlDeclarePairwiseResult: .tableName$, .groupCol$, .test$, .adjMethod$
    @emlResultBegin: .tableName$, "Pairwise comparisons"

    if .test$ = "wilcoxon"
        .k = emlPairwiseWilcoxon.nGroups
        .pair = 0
        for .i from 1 to .k - 1
            for .j from .i + 1 to .k
                .pair = .pair + 1
                @emlTidyRow: .groupCol$
                @emlTidyStr: "contrast", emlPairwiseWilcoxon.groupName$ [.i]
                ... + "-" + emlPairwiseWilcoxon.groupName$ [.j]
                @emlTidyNum: "statistic",   emlPairwiseWilcoxon.uMatrix## [.i, .j]
                @emlTidyNum: "p.value",     emlPairwiseWilcoxon.rawP# [.pair]
                @emlTidyNum: "adj.p.value", emlPairwiseWilcoxon.adjustedP# [.pair]
                @emlTidyNum: "effect.size",      emlPairwiseWilcoxon.rMatrix## [.i, .j]
                @emlTidyStr: "effect.size.type", "rank.biserial"
                @emlTidyStr: "method", "Wilcoxon rank sum"
            endfor
        endfor
        @emlGlanceNum: "n.groups", .k
        @emlGlanceNum: "n.pairs",  emlPairwiseWilcoxon.nPairs
        @emlGlanceStr: "method",   "Pairwise Wilcoxon rank sum"
        ; NOTE: emlPairwiseWilcoxon.method$ holds the ADJUSTMENT method, not a
        ; test name -- the reverse of emlPairwiseT.method$. Using the literal
        ; here rather than the field is deliberate.

    elsif .test$ = "scheffe"
        .k = emlScheffe.nGroups
        for .i from 1 to .k - 1
            for .j from .i + 1 to .k
                @emlTidyRow: .groupCol$
                @emlTidyStr: "contrast", emlScheffe.groupName$ [.i] + "-"
                ... + emlScheffe.groupName$ [.j]
                @emlTidyNum: "estimate",  emlScheffe.diffMatrix## [.i, .j]
                @emlTidyNum: "statistic", emlScheffe.fMatrix## [.i, .j]
                ; Scheffe's p IS the familywise-controlled one -- it exposes no
                ; raw p, so adj.p.value is the honest column for it.
                @emlTidyNum: "adj.p.value", emlScheffe.pMatrix## [.i, .j]
                @emlTidyStr: "method", "Scheffe"
            endfor
        endfor
        @emlGlanceNum: "n.groups",    .k
        @emlGlanceNum: "n.pairs",     emlScheffe.nPairs
        @emlGlanceNum: "df.residual", emlScheffe.dfWithin
        @emlGlanceNum: "sigma",       sqrt (emlScheffe.mse)
        @emlGlanceStr: "method",      "Scheffe"

    else
        .k = emlPairwiseT.nGroups
        .pair = 0
        for .i from 1 to .k - 1
            for .j from .i + 1 to .k
                .pair = .pair + 1
                @emlTidyRow: .groupCol$
                @emlTidyStr: "contrast", emlPairwiseT.groupName$ [.i] + "-"
                ... + emlPairwiseT.groupName$ [.j]
                @emlTidyNum: "statistic",   emlPairwiseT.tMatrix## [.i, .j]
                @emlTidyNum: "p.value",     emlPairwiseT.rawP# [.pair]
                @emlTidyNum: "adj.p.value", emlPairwiseT.adjustedP# [.pair]
                @emlTidyNum: "effect.size",      emlPairwiseT.dMatrix## [.i, .j]
                @emlTidyStr: "effect.size.type", "cohens.d"
                @emlTidyStr: "method", emlPairwiseT.method$
            endfor
        endfor
        @emlGlanceNum: "n.groups", .k
        @emlGlanceNum: "n.pairs",  emlPairwiseT.nPairs
        @emlGlanceStr: "method",   emlPairwiseT.method$
    endif
endproc


# --- 5. Two-way ANOVA ------------------------------------------------------
# The only orchestrator with a real augment available without re-deriving:
# .cellOf[r] is indexed by TABLE ROW and .yValue[r] is that row's response.
procedure emlDeclareTwoWayResult: .tableName$, .dataCol$, .factor1$, .factor2$,
    ... .tableId
    @emlResultBegin: .tableName$, "Two-way ANOVA"

    @emlTidyRow: .factor1$
    @emlTidyNum: "df", emlTwoWayAnova.dfA
    @emlTidyNum: "sumsq", emlTwoWayAnova.ssA
    @emlTidyNum: "meansq", emlTwoWayAnova.msA
    @emlTidyNum: "statistic", emlTwoWayAnova.fA
    @emlTidyNum: "p.value", emlTwoWayAnova.pA

    @emlTidyRow: .factor2$
    @emlTidyNum: "df", emlTwoWayAnova.dfB
    @emlTidyNum: "sumsq", emlTwoWayAnova.ssB
    @emlTidyNum: "meansq", emlTwoWayAnova.msB
    @emlTidyNum: "statistic", emlTwoWayAnova.fB
    @emlTidyNum: "p.value", emlTwoWayAnova.pB

    ; R names the interaction "a:b". Matching that exactly is what lets a
    ; reader join this frame against a broom frame without renaming.
    @emlTidyRow: .factor1$ + ":" + .factor2$
    @emlTidyNum: "df", emlTwoWayAnova.dfAB
    @emlTidyNum: "sumsq", emlTwoWayAnova.ssAB
    @emlTidyNum: "meansq", emlTwoWayAnova.msAB
    @emlTidyNum: "statistic", emlTwoWayAnova.fAB
    @emlTidyNum: "p.value", emlTwoWayAnova.pAB

    @emlTidyRow: "Residuals"
    @emlTidyNum: "df", emlTwoWayAnova.dfError
    @emlTidyNum: "sumsq", emlTwoWayAnova.ssError
    @emlTidyNum: "meansq", emlTwoWayAnova.msError

    .nobs = emlTwoWayAnova.dfTotal + 1
    @emlGlanceNum: "r.squared", 1 - emlTwoWayAnova.ssError / emlTwoWayAnova.ssTotal
    @emlGlanceNum: "sigma", sqrt (emlTwoWayAnova.msError)
    @emlGlanceNum: "df.residual", emlTwoWayAnova.dfError
    @emlGlanceNum: "deviance", emlTwoWayAnova.ssError
    @emlGlanceNum: "nobs", .nobs
    @emlGlanceNum: "n.cells", emlTwoWayAnova.nCells
    @emlGlanceStr: "method", "Two-way ANOVA"
    if emlTwoWayAnova.warning$ <> ""
        @emlGlanceStr: "warning", emlTwoWayAnova.warning$
    endif

    ; LEVERAGE, exactly as in @emlDeclareOneWayAnovaResult and for the same
    ; reason -- read the note there first.
    ; This model is saturated: the fitted value of an observation is its
    ; CELL's mean, so the leverage is 1 / n_cell and no hat matrix is formed.
    ; On a balanced design every cell holds the same count and the correction
    ; is a single constant, which is why omitting it reads as a scale factor;
    ; it is not one, and on an unbalanced design the cells and the correction
    ; run together.
    @emlAugmentFrom: .tableId
    .sigma = sqrt (emlTwoWayAnova.msError)
    for .r from 1 to emlTwoWayAnova.nRows
        .c = emlTwoWayAnova.cellOf [.r]
        if .c > 0
            .fit = emlTwoWayAnova.cellMean [.c]
            .hat = 1 / emlTwoWayAnova.cellN [.c]
            @emlAugmentNum: ".fitted", .r, .fit
            @emlAugmentNum: ".resid", .r, emlTwoWayAnova.yValue [.r] - .fit
            @emlAugmentNum: ".hat", .r, .hat
            ; A cell of one has leverage 1 and no standardised residual.
            ; @emlTwoWayAnova already declines that design; the cell stays
            ; empty rather than infinite if it ever arrives.
            .std = undefined
            if .hat < 1
                .std = (emlTwoWayAnova.yValue [.r] - .fit)
                ... / (.sigma * sqrt (1 - .hat))
            endif
            @emlAugmentNum: ".std.resid", .r, .std
        endif
    endfor
endproc


procedure emlDeclareTwoWayEffects: .factor1$, .factor2$
    @emlTidyClear
    @emlTidyRow: .factor1$
    @emlTidyNum: "effect.size", emlTwoWayAnova.partialEtaSqA
    @emlTidyStr: "effect.size.type", "partial.eta.squared"
    @emlTidyRow: .factor2$
    @emlTidyNum: "effect.size", emlTwoWayAnova.partialEtaSqB
    @emlTidyStr: "effect.size.type", "partial.eta.squared"
    @emlTidyRow: .factor1$ + ":" + .factor2$
    @emlTidyNum: "effect.size", emlTwoWayAnova.partialEtaSqAB
    @emlTidyStr: "effect.size.type", "partial.eta.squared"
endproc


# --- 6. Paired / repeated pair ---------------------------------------------
procedure emlDeclarePairedResult: .tableName$, .col1$, .col2$, .doPar, .doNon
    @emlResultBegin: .tableName$, "Paired comparison"

    if .doPar = 1
        if variableExists ("emlTTestPaired.error$")
            if emlTTestPaired.error$ = ""
                @emlTidyRow: ""
                @emlTidyNum: "estimate",  emlTTestPaired.meanDiff
                @emlTidyNum: "statistic", emlTTestPaired.t
                @emlTidyNum: "p.value",   emlTTestPaired.p
                @emlTidyNum: "parameter", emlTTestPaired.df
                @emlTidyStr: "method",      "Paired t-test"
                @emlTidyStr: "alternative", "two.sided"
            endif
        endif
    endif
    ; @emlMatchedPairsR re-runs @emlWilcoxonSignedRank, so the Wilcoxon row is
    ; declared BEFORE the effect sizes are staged. Ordering, not preference.
    if .doNon = 1
        if variableExists ("emlWilcoxonSignedRank.error$")
            if emlWilcoxonSignedRank.error$ = ""
                @emlTidyRow: ""
                @emlTidyNum: "statistic",   emlWilcoxonSignedRank.tPlus
                @emlTidyNum: "p.value",     emlWilcoxonSignedRank.p
                @emlTidyStr: "method",      emlWilcoxonSignedRank.method$
                @emlTidyStr: "alternative", emlWilcoxonSignedRank.alternative$
            endif
        endif
    endif

    if .doPar = 1
        if variableExists ("emlTTestPaired.error$")
            if emlTTestPaired.error$ = ""
                @emlGlanceNum: "estimate",  emlTTestPaired.meanDiff
                @emlGlanceNum: "statistic", emlTTestPaired.t
                @emlGlanceNum: "p.value",   emlTTestPaired.p
                @emlGlanceNum: "parameter", emlTTestPaired.df
                @emlGlanceNum: "nobs",      emlTTestPaired.n
                @emlGlanceStr: "method",    "Paired t-test"
            endif
        endif
    endif
    elsif .doNon = 1
        if variableExists ("emlWilcoxonSignedRank.error$")
            if emlWilcoxonSignedRank.error$ = ""
                @emlGlanceNum: "statistic", emlWilcoxonSignedRank.tPlus
                @emlGlanceNum: "p.value",   emlWilcoxonSignedRank.p
                @emlGlanceNum: "nobs",      emlWilcoxonSignedRank.n
                @emlGlanceStr: "method",    emlWilcoxonSignedRank.method$
            endif
        endif
    endif
endproc


procedure emlDeclarePairedEffects: .doPar, .doNon
    @emlTidyClear
    if .doPar = 1
        if variableExists ("emlCohenDz.error$")
            if emlCohenDz.error$ = ""
                @emlTidyRow: ""
                @emlTidyNum: "effect.size", emlCohenDz.dz
                @emlTidyStr: "effect.size.type", "cohens.dz"
            endif
        endif
    endif
    if .doNon = 1
        if variableExists ("emlMatchedPairsR.error$")
            if emlMatchedPairsR.error$ = ""
                @emlTidyRow: ""
                @emlTidyNum: "effect.size", emlMatchedPairsR.r
                @emlTidyStr: "effect.size.type", "matched.pairs.rank.biserial"
            endif
        endif
    endif
endproc


# --- 7. Correlation --------------------------------------------------------
# Reads the ORCHESTRATOR's restored locals rather than the procedure globals,
# passed in, because @emlSpearmanCorrelation shares @eml_pearsonCore.
procedure emlDeclareCorrelationResult: .tableName$, .colX$, .colY$, .n,
    ... .doPear, .pearR, .pearT, .pearDf, .pearP,
    ... .doSpear, .spearRho, .spearT, .spearDf, .spearP
    @emlResultBegin: .tableName$, "Correlation"

    if .doPear
        @emlTidyRow: ""
        @emlTidyNum: "estimate",  .pearR
        @emlTidyNum: "statistic", .pearT
        @emlTidyNum: "p.value",   .pearP
        @emlTidyNum: "parameter", .pearDf
        @emlTidyStr: "method",      "Pearson's product-moment correlation"
        @emlTidyStr: "alternative", "two.sided"
    endif
    if .doSpear
        @emlTidyRow: ""
        @emlTidyNum: "estimate",  .spearRho
        @emlTidyNum: "statistic", .spearT
        @emlTidyNum: "p.value",   .spearP
        @emlTidyNum: "parameter", .spearDf
        @emlTidyStr: "method",      "Spearman's rank correlation rho"
        @emlTidyStr: "alternative", "two.sided"
    endif

    if .doPear
        @emlGlanceNum: "estimate",  .pearR
        @emlGlanceNum: "r.squared", .pearR * .pearR
        @emlGlanceNum: "statistic", .pearT
        @emlGlanceNum: "p.value",   .pearP
        @emlGlanceNum: "parameter", .pearDf
        @emlGlanceStr: "method",    "Pearson's product-moment correlation"
    elsif .doSpear
        @emlGlanceNum: "estimate",  .spearRho
        @emlGlanceNum: "statistic", .spearT
        @emlGlanceNum: "p.value",   .spearP
        @emlGlanceNum: "parameter", .spearDf
        @emlGlanceStr: "method",    "Spearman's rank correlation rho"
    endif
    @emlGlanceNum: "nobs", .n
endproc


# --- 8. Simple linear regression -------------------------------------------
# This is the one that is literally broom's tidy(lm): one row per coefficient,
# term / estimate / std.error / statistic / p.value.
procedure emlDeclareRegressionResult: .tableName$, .depCol$, .predCol$,
    ... .tableId, .nValid
    @emlResultBegin: .tableName$, "Linear regression"

    @emlTidyRow: "(Intercept)"
    @emlTidyNum: "estimate",  emlLinearRegression.intercept
    @emlTidyNum: "std.error", emlLinearRegression.seIntercept
    @emlTidyNum: "statistic", emlLinearRegression.tIntercept
    @emlTidyNum: "p.value",   emlLinearRegression.pIntercept

    @emlTidyRow: .predCol$
    @emlTidyNum: "estimate",  emlLinearRegression.slope
    @emlTidyNum: "std.error", emlLinearRegression.seSlope
    @emlTidyNum: "statistic", emlLinearRegression.tSlope
    @emlTidyNum: "p.value",   emlLinearRegression.pSlope

    .n = emlLinearRegression.n
    .rss = emlLinearRegression.ssRes
    .logLik = -0.5 * .n * (ln (2 * pi) + ln (.rss / .n) + 1)
    ; k = intercept + slope + residual variance
    .k = 3
    @emlGlanceNum: "r.squared", emlLinearRegression.rSquared
    @emlGlanceNum: "adj.r.squared",
    ... 1 - (1 - emlLinearRegression.rSquared) * (.n - 1) / (.n - 2)
    @emlGlanceNum: "sigma",       emlLinearRegression.seResidual
    @emlGlanceNum: "statistic",   emlLinearRegression.fStat
    @emlGlanceNum: "p.value",     emlLinearRegression.pF
    @emlGlanceNum: "df",          emlLinearRegression.dfReg
    @emlGlanceNum: "logLik",      .logLik
    @emlGlanceNum: "AIC",         -2 * .logLik + 2 * .k
    @emlGlanceNum: "BIC",         -2 * .logLik + ln (.n) * .k
    @emlGlanceNum: "deviance",    .rss
    @emlGlanceNum: "df.residual", emlLinearRegression.dfRes
    @emlGlanceNum: "nobs",        .n
    @emlGlanceStr: "method",      "Simple linear regression"

    @emlAugmentFrom: .tableId

    ; Leverage, Cook's distance and the LEVERAGE-CORRECTED standardised
    ; residual come from @emlOLSInfluence (stats/eml-inferential.praat).
    ; .std.resid is NOT resid / sigma: that form omits the leverage term, is
    ; not broom's rstandard(), and the correction it leaves out is largest
    ; exactly where leverage is largest. .hat and .cooksd are reserved in
    ; emlVocabAugment$ and are emitted here.
    ;
    ; Every returned vector is indexed by TABLE ROW, not by fitted
    ; observation, so listwise-dropped rows carry undefined and
    ; @emlAugmentNum skips them into an empty cell that reads back as NA.
    ;
    ; Called AFTER the glance emissions above: it re-enters
    ; @emlLinearRegression on the same table and columns under the same
    ; listwise rule, so emlLinearRegression.* is left bit-identical either
    ; way, but this ordering makes that irrelevant rather than merely safe.
    @emlOLSInfluence: .tableId, .predCol$, .depCol$
    if emlOLSInfluence.error$ = ""
        for .r from 1 to emlOLSInfluence.nRows
            if emlOLSInfluence.used# [.r] = 1
                @emlAugmentNum: ".fitted",    .r, emlOLSInfluence.fitted# [.r]
                @emlAugmentNum: ".resid",     .r, emlOLSInfluence.resid# [.r]
                @emlAugmentNum: ".hat",       .r, emlOLSInfluence.hat# [.r]
                @emlAugmentNum: ".std.resid", .r, emlOLSInfluence.stdResid# [.r]
                @emlAugmentNum: ".cooksd",    .r, emlOLSInfluence.cooksd# [.r]
            endif
        endfor
    endif
endproc


# --- 8b. Descriptives ------------------------------------------------------
# DESCRIBE AND NORMALITY CAN SAVE. Every analysis that produces results a
# user can read produces results a user can keep.
#
# THE LEGACY BUFFER, NOT THE BROOM COLLECTORS, and this is the interesting
# part. Declaring into tidy/glance like every other converted analysis would
# silently throw the answer away: eml-result-writer.praat's tidy vocabulary
# is a WHITELIST walked by
# @eml_orderedCols, so a column not in emlVocabTidy$ is dropped without
# comment -- and mean, sd, se, median, q1, q3, iqr, min, max, range,
# variance, skewness and kurtosis are none of them broom column names,
# because broom has no tidy method for a summary of a vector. The written
# file would have carried `term` and `method` and nothing else.
#
# TWO OF THE SIXTEEN ARE TIDY COLUMNS -- emlVocabTidy$ carries skewness and
# kurtosis for the normality frame -- so the arithmetic above is `term`,
# `skewness`, `kurtosis` and `method`, and eleven of the sixteen still go over
# the side without a word. That does not move the conclusion an inch, and the
# reason it does not is worth stating: a whitelist that has grown by two is
# not a whitelist that has stopped dropping things, and a describe declared
# into tidy would still lose the mean.
#
# That is a reason not to convert describe, and not a reason describe cannot
# export: the legacy long format (table, analysis, term, term_type, field,
# value) is the container built for a heterogeneous bag of named scalars, and
# it takes all sixteen without inventing a single non-broom column name. See
# validate/REGISTRY.md.
#
# It also makes the fork's UNDECLARED arm reachable from a dialog: a path
# that fills the legacy buffer without declaring is what exercises the half
# of the branch validate/v46 exists to protect.
#
# @emlCSVAddDescriptives already existed and is deliberately NOT used here:
# it writes n, mean, sd and median only -- the four a post-hoc reporter needs
# beside a contrast -- and is idempotent by (analysis, term) for that reason.
# A describe is the analysis, not an aside to one, so it writes the full set.
# ----------------------------------------------------------------------------
# .term$ is the column (or the group) being described. The TABLE is not an
# argument: it travels on emlCSV_table$ via @emlCSVSetTable, which every
# analysis calls once, and `analysis` is the METHOD -- "Welch t-test",
# "Descriptive statistics" -- not the table. Got this backwards on the first
# write and the exported file came out with an empty `table` column and the
# table name sitting in `analysis`; caught by reading the CSV the drive
# produced rather than by any check, which is why v50 now reads it.
procedure emlCSVAddDescriptiveRow: .term$
    @emlCSVTermType: "group"
    @emlCSVAdd: "Descriptive statistics", .term$, "n",         emlDescribe.n
    @emlCSVAdd: "Descriptive statistics", .term$, "mean",      emlDescribe.mean
    @emlCSVAdd: "Descriptive statistics", .term$, "sd",        emlDescribe.sd
    @emlCSVAdd: "Descriptive statistics", .term$, "se",        emlDescribe.sem
    @emlCSVAdd: "Descriptive statistics", .term$, "median",    emlDescribe.median
    @emlCSVAdd: "Descriptive statistics", .term$, "q1",        emlDescribe.q1
    @emlCSVAdd: "Descriptive statistics", .term$, "q3",        emlDescribe.q3
    @emlCSVAdd: "Descriptive statistics", .term$, "iqr",       emlDescribe.iqr
    @emlCSVAdd: "Descriptive statistics", .term$, "min",       emlDescribe.min
    @emlCSVAdd: "Descriptive statistics", .term$, "max",       emlDescribe.max
    @emlCSVAdd: "Descriptive statistics", .term$, "range",     emlDescribe.range
    @emlCSVAdd: "Descriptive statistics", .term$, "variance",  emlDescribe.variance
    @emlCSVAdd: "Descriptive statistics", .term$, "skewness",  emlDescribe.skewness
    @emlCSVAdd: "Descriptive statistics", .term$, "kurtosis",  emlDescribe.kurtosis
    @emlCSVAdd: "Descriptive statistics", .term$, "ci95.lower", emlDescribe.ci95Lower
    @emlCSVAdd: "Descriptive statistics", .term$, "ci95.upper", emlDescribe.ci95Upper
endproc

# --- 9. Normality ----------------------------------------------------------
# Reads emlRunNormalityAnalysis.* -- the one orchestrator that copies every
# value onto itself, so nothing here depends on procedure-global survival.
#
# ACCUMULATION IS A REPLAY, NOT AN APPEND.
#
# Skipping @emlResultBegin on a continuation and letting @emlTidyRow append
# does not work, and the reason is the GLANCE frame: it holds exactly one row,
# already filled with column 1's W, p, skewness and kurtosis, and the result
# writer offers a tidy-only clear (@emlTidyClear) and no glance-only clear.
# Appending would fix the tidy frame and leave glance asserting one unnamed
# column's statistics over a three-column run.
#
# So the press keeps its own record, in emlNorm_*, and EVERY call re-declares
# the whole press from it. @emlResultBegin then runs on every call as it
# always did, the collectors are never half-written, and the glance decision
# is taken knowing how many columns the press holds rather than guessing on
# the first one.
#
# WHAT THE GLANCE ROW SAYS WHEN THERE IS MORE THAN ONE MODEL. broom has no
# answer to this -- you would map glance() over the models and rbind -- and
# emlVocabGlance$ has no `term`, so a per-column identifier cannot be added
# from here (the vocabulary is a whitelist in eml-result-writer.praat, and a
# column not in it is dropped by @eml_orderedCols without a word). The row
# therefore carries only what is true OF THE RUN: the method, a `warning` that
# names the columns and says where the per-column numbers are, and nobs /
# n.excluded / alternative when every column agrees on them and nothing at all
# when they do not.
#
# THE SHAPE STATISTICS ARE NOT IN THAT ROW BUT THEY ARE IN THE FILE. skewness
# and kurtosis are tidy columns, one pair per row, declared in the loop below.
# "The vocabulary does not have it" would not have been a reason to leave them
# out of any file -- the whitelist is ours. The `warning` still says the
# recommendation is in the report, because a recommendation is a sentence and
# there is no column of any vocabulary it belongs in.
procedure emlDeclareNormalityResult: .tableName$, .dataCol$, .swW, .swP,
    ... .swError$, .skewness, .kurtosis, .nValid, .nUndefined,
    ... .recommendation$, .accumulate
    ; Nested, not `or`: Praat evaluates both operands, and emlNorm_n does not
    ; exist on the first call of a session.
    .reset = 1
    if .accumulate = 1
        if variableExists ("emlNorm_n")
            .reset = 0
        endif
    endif
    if .reset = 1
        emlNorm_n = 0
    endif
    emlNorm_table$ = .tableName$
    emlNorm_n = emlNorm_n + 1
    emlNorm_col$ [emlNorm_n]    = .dataCol$
    emlNorm_w [emlNorm_n]       = .swW
    emlNorm_p [emlNorm_n]       = .swP
    emlNorm_err$ [emlNorm_n]    = .swError$
    emlNorm_skew [emlNorm_n]    = .skewness
    emlNorm_kurt [emlNorm_n]    = .kurtosis
    emlNorm_nValid [emlNorm_n]  = .nValid
    emlNorm_nExcl [emlNorm_n]   = .nUndefined
    emlNorm_rec$ [emlNorm_n]    = .recommendation$

    @emlResultBegin: .tableName$, "Normality"

    ; ---- tidy: one row per column tested, in the order they were tested ----
    ;
    ; SKEWNESS AND KURTOSIS BELONG HERE, one pair per tested column. The
    ; alternative is the glance frame, which on more than one model carries
    ; only what is true OF THE RUN -- so a one-column press would export them
    ; and a two-column press would export them nowhere, leaving the shape
    ; statistics for column 2 in the Info window and in no file at all. That
    ; asymmetry gets worse the more columns a user tests, which is the wrong
    ; direction for an export to fail in.
    ; validate/v64_display_and_coercion.R measures it.
    ;
    ; OUTSIDE THE ERROR BRANCH, DELIBERATELY, and the branch's own comment below
    ; is the argument: a column whose n puts Shapiro-Wilk out of range still has
    ; a skewness and a kurtosis, and those are the whole of what the analysis
    ; found. Emitting them only on the branch that ALSO has a W would drop them
    ; from exactly the rows that have nothing else in them.
    ;
    ; THEY ARE UNDEFINED BELOW n = 3 AND n = 4 RESPECTIVELY (@emlSkewness,
    ; @emlKurtosis, stats/eml-core-descriptive.praat), and @emlTidyNum writes
    ; nothing for an undefined value, so those cells stay empty and R reads NA.
    ; That is broom's own behaviour for a statistic a model does not have, and
    ; it is why no guard is written here.
    ;
    ; ADDING THE CALLS IS HALF THE CHANGE. emlVocabTidy$ in
    ; stats/eml-result-writer.praat is a WHITELIST walked by @eml_orderedCols
    ; and it decides both the order and whether a column is written at all; a
    ; declaration under a name it does not carry is dropped in silence, and the
    ; file that comes out looks like a successful export. The two names were
    ; added there in the same change, and validate/v71_tidy_vocab_and_warning.R
    ; drives a two-column press and reads the values back off the written CSV
    ; rather than trusting either half on its own.
    for .i from 1 to emlNorm_n
        @emlTidyRow: emlNorm_col$ [.i]
        if emlNorm_err$ [.i] = ""
            @emlTidyNum: "statistic", emlNorm_w [.i]
            @emlTidyNum: "p.value",   emlNorm_p [.i]
            @emlTidyNum: "skewness",  emlNorm_skew [.i]
            @emlTidyNum: "kurtosis",  emlNorm_kurt [.i]
            @emlTidyStr: "method",    "Shapiro-Wilk normality test"
        else
            ; Shapiro-Wilk out of range is not a failed export -- the shape
            ; statistics are still the answer, and the reason is carried.
            @emlTidyNum: "skewness",  emlNorm_skew [.i]
            @emlTidyNum: "kurtosis",  emlNorm_kurt [.i]
            @emlTidyStr: "method", "Shape statistics only"
        endif
    endfor

    ; ---- glance: one row for the model, when there is one model ----
    if emlNorm_n = 1
        if emlNorm_err$ [1] = ""
            @emlGlanceNum: "statistic", emlNorm_w [1]
            @emlGlanceNum: "p.value",   emlNorm_p [1]
            @emlGlanceStr: "method",    "Shapiro-Wilk normality test"
        else
            @emlGlanceStr: "method",  "Shape statistics only"
            @emlGlanceStr: "warning", emlNorm_err$ [1]
        endif
        @emlGlanceNum: "skewness",    emlNorm_skew [1]
        @emlGlanceNum: "kurtosis",    emlNorm_kurt [1]
        @emlGlanceNum: "nobs",        emlNorm_nValid [1]
        @emlGlanceNum: "n.excluded",  emlNorm_nExcl [1]
        @emlGlanceStr: "alternative", emlNorm_rec$ [1]
    else
        .sameN = 1
        .sameExcl = 1
        .sameRec = 1
        .list$ = emlNorm_col$ [1]
        for .i from 2 to emlNorm_n
            .list$ = .list$ + ", " + emlNorm_col$ [.i]
            if emlNorm_nValid [.i] <> emlNorm_nValid [1]
                .sameN = 0
            endif
            if emlNorm_nExcl [.i] <> emlNorm_nExcl [1]
                .sameExcl = 0
            endif
            if emlNorm_rec$ [.i] <> emlNorm_rec$ [1]
                .sameRec = 0
            endif
        endfor
        @emlGlanceStr: "method", "Shapiro-Wilk normality test"
        if .sameN
            @emlGlanceNum: "nobs", emlNorm_nValid [1]
        endif
        if .sameExcl
            @emlGlanceNum: "n.excluded", emlNorm_nExcl [1]
        endif
        if .sameRec
            @emlGlanceStr: "alternative", emlNorm_rec$ [1]
        endif
        ; THIS SENTENCE IS A DIRECTION, AND IT HAS TO MATCH THE ARTEFACT. It
        ; is the one exported string in this procedure whose content is a
        ; claim about where a reader should look, so it names the tidy frame
        ; for the per-column W, p, skewness and kurtosis -- all four are
        ; columns there -- and sends a reader to the Info window only for the
        ; recommendation, which is a sentence and has no column in any
        ; vocabulary. A direction that named the report for numbers sitting
        ; in the file the reader already has open would waste their time.
        @emlGlanceStr: "warning", string$ (emlNorm_n)
        ... + " columns were tested in this run (" + .list$ + "). A glance "
        ... + "frame is one row per model and cannot describe "
        ... + string$ (emlNorm_n) + "; the per-column W, p, skewness and "
        ... + "kurtosis are in the tidy frame, and the recommendation for "
        ... + "each column is in the report."
    endif
endproc


# --- 10. Repeated-measures ANOVA — a BUILD --------------------------------
procedure emlDeclareRMResult: .tableName$, .n, .k
    @emlResultBegin: .tableName$, "Repeated-measures ANOVA"

    @emlTidyRow: "condition"
    @emlTidyNum: "df",        emlRMAnovaTest.dfCond
    @emlTidyNum: "sumsq",     emlRMAnovaTest.ssCond
    @emlTidyNum: "meansq",    emlRMAnovaTest.msCond
    @emlTidyNum: "statistic", emlRMAnovaTest.fStat
    @emlTidyNum: "p.value",   emlRMAnovaTest.p

    @emlTidyRow: "Residuals"
    @emlTidyNum: "df",     emlRMAnovaTest.dfErr
    @emlTidyNum: "sumsq",  emlRMAnovaTest.ssErr
    @emlTidyNum: "meansq", emlRMAnovaTest.msErr

    @emlGlanceNum: "statistic",   emlRMAnovaTest.fStat
    @emlGlanceNum: "p.value",     emlRMAnovaTest.p
    @emlGlanceNum: "df",          emlRMAnovaTest.dfCond
    @emlGlanceNum: "df.residual", emlRMAnovaTest.dfErr
    @emlGlanceNum: "gg.epsilon",  emlRMAnovaTest.ggEpsilon
    @emlGlanceNum: "p.value.gg",  emlRMAnovaTest.pGG
    @emlGlanceNum: "partial.eta.squared",
    ... emlRMAnovaTest.ssCond / (emlRMAnovaTest.ssCond + emlRMAnovaTest.ssErr)
    @emlGlanceNum: "n.subjects",  .n
    @emlGlanceNum: "n.groups",    .k
    @emlGlanceNum: "nobs",        .n * .k
    @emlGlanceStr: "method",      "Repeated-measures ANOVA"
    ; THE EXPORTED half of the split pair, and the one that must not move.
    ; .warning$ carries the bytes the export needs; the formatted sibling is
    ; .warningPrinted$ and it goes nowhere near a file.
    if emlRMAnovaTest.warning$ <> ""
        @emlGlanceStr: "warning", emlRMAnovaTest.warning$
    endif
endproc


# Post-hoc pair labels are INTEGERS indexing emlExtractConditionMatrix.colLabel$,
# not strings -- the contrast text is built inline by the printer and stored
# nowhere, so it is rebuilt here.
procedure emlDeclareRMPostHoc
    @emlTidyClear
    for .i from 1 to emlRMPostHoc.nPairs
        .a = emlRMPostHoc.pairLabelA [.i]
        .b = emlRMPostHoc.pairLabelB [.i]
        @emlTidyRow: "condition"
        @emlTidyStr: "contrast", emlExtractConditionMatrix.colLabel$ [.a]
        ... + "-" + emlExtractConditionMatrix.colLabel$ [.b]
        @emlTidyNum: "p.value",     emlRMPostHoc.rawP# [.i]
        @emlTidyNum: "adj.p.value", emlRMPostHoc.adj# [.i]
        @emlTidyStr: "method", "Paired t (" + emlRMPostHoc.adjUsed$ + ")"
    endfor
endproc


# --- 11. Friedman — a BUILD -----------------------------------------------
# @emlFriedmanTest exposes NO .error$ field. Referencing one is a runtime
# error, so the caller gates on emlExtractConditionMatrix.error$ instead.
# It also exposes no effect size, so Kendall's W is computed here from its
# definition, W = chiSq / (n * (k - 1)).
procedure emlDeclareFriedmanResult: .tableName$, .n, .k
    @emlResultBegin: .tableName$, "Friedman"

    @emlTidyRow: "condition"
    @emlTidyNum: "statistic", emlFriedmanTest.chiSq
    @emlTidyNum: "p.value",   emlFriedmanTest.p
    @emlTidyNum: "parameter", emlFriedmanTest.df
    @emlTidyStr: "method",    "Friedman rank sum test"

    @emlGlanceNum: "statistic",  emlFriedmanTest.chiSq
    @emlGlanceNum: "p.value",    emlFriedmanTest.p
    @emlGlanceNum: "parameter",  emlFriedmanTest.df
    @emlGlanceNum: "kendalls.w", emlFriedmanTest.chiSq / (.n * (.k - 1))
    @emlGlanceNum: "n.subjects", .n
    @emlGlanceNum: "n.groups",   .k
    @emlGlanceNum: "nobs",       .n * .k
    @emlGlanceStr: "method",     "Friedman rank sum test"
endproc


procedure emlDeclareFriedmanPostHoc
    @emlTidyClear
    for .i from 1 to emlRMPostHoc.nPairs
        .a = emlRMPostHoc.pairLabelA [.i]
        .b = emlRMPostHoc.pairLabelB [.i]
        @emlTidyRow: "condition"
        @emlTidyStr: "contrast", emlExtractConditionMatrix.colLabel$ [.a]
        ... + "-" + emlExtractConditionMatrix.colLabel$ [.b]
        @emlTidyNum: "p.value",     emlRMPostHoc.rawP# [.i]
        @emlTidyNum: "adj.p.value", emlRMPostHoc.adj# [.i]
        @emlTidyStr: "method", "Wilcoxon signed rank ("
        ... + emlRMPostHoc.adjUsed$ + ")"
    endfor
endproc
