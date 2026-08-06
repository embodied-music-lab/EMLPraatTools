# ============================================================================
# EML Stats : Analysis Orchestrators
# ============================================================================
# Module: eml-analysis.praat
# Version: 1.2
# Date: 2 August 2026
#
# v1.2: Correctness + robustness fixes in the orchestrator layer.
#   item 1 — emlRMPostHoc no longer renders a failed pairwise test as an
#            adjusted p of 0. A test that fails (or returns an undefined p)
#            now propagates "undefined" into the raw p-vector, so the
#            adjustment procedures exclude it from k the way R's p.adjust
#            excludes NA. Undefined p-values print as "n/a" in both the raw
#            and adjusted columns, and a note names each skipped pair with
#            the reason.
#   item 2 — emlRMPostHoc validates .adjMethod$. An unrecognised string used
#            to fall through to Holm silently while the header printed the
#            requested name; the header now prints the method that actually
#            ran and the substitution is disclosed.
#   item 3 — emlRunCorrelationAnalysis captures each test's outputs into
#            locals immediately after its own call and restores them before
#            reporting, so a nested/re-entrant call cannot overwrite them.
#            Previously "both" reported Spearman's rank-based r, t, df and p
#            under the Pearson heading, in the Info report AND the CSV.
#            The same capture/restore is applied to the Mann-Whitney outputs
#            in emlRunTwoGroupAnalysis, which @emlRankBiserialR re-enters.
#   item 4 — emlRunTwoGroupAnalysis checks the error$ of every test it runs.
#            The reporter performs no error checks, so a failed test used to
#            be printed as undefined results and written to the CSV. Failed
#            branches are now dropped from the reported test type and the
#            reason is surfaced. emlRunCorrelationAnalysis likewise surfaces
#            a failed Spearman test, which the reporter swallowed silently.
#   item 5 — emlReportPairwiseComparison header said "Pairwise holm (holm
#            adjustment)": it used emlPairwiseT.method$, which is the
#            ADJUSTMENT method, as the test name. Now derived from .test$.
#   item 6 — emlRunRegressionAnalysis and emlRunNormalityAnalysis guard
#            their column names with "Get column index:" instead of aborting
#            the whole script with a raw Praat error.
#   item 7 — Documented the reserved-but-unread parameters
#            (emlRunNormalityAnalysis.testType$,
#            emlRunRepeatedMeasuresAnalysis.subjectCol$,
#            emlRunFriedmanAnalysis.subjectCol$) and the unimplemented
#            emlRunReliabilityAnalysis stub. Parameter lists are unchanged
#            because callers pass arguments positionally.
#   item 8 — Friedman tie correction verified against R's friedman.test on
#            tied data; formula and clamp are correct. No change.
#
# v1.1: Missing-data fix (correctness). emlRunPairedAnalysis and
#        emlRunCorrelationAnalysis now extract their two columns with
#        row-wise complete-case deletion (@emlExtractPairedColumns)
#        instead of two independent per-column @emlExtractColumn calls,
#        which misaligned the pairs when cells were missing in different
#        rows. Analyzed n is now the complete-pair count and a
#        "rows excluded for missing data" note is emitted when any row
#        is dropped.
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
# ============================================================================


# ============================================================================
#
#  1. TWO-GROUP COMPARISON
#
# ============================================================================

procedure emlRunTwoGroupAnalysis: .tableId, .dataCol$, .groupCol$, .testType$, .equalVar
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlCountGroups: .tableId, .groupCol$
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

    label END_TWO_GROUP
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
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlCountGroups: .tableId, .groupCol$
    if emlCountGroups.error$ <> ""
        .error$ = emlCountGroups.error$
        goto END_ANOVA
    endif
    .nGroups = emlCountGroups.nGroups
    if .nGroups < 2
        .error$ = "Group column """ + .groupCol$ + """ has fewer than 2 groups."
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
    ; reporter, not inside it, for two reasons: @emlReportAnovaComparison
    ; re-runs @emlOneWayAnova itself, so its outputs here are exactly the
    ; numbers that were printed; and the lifecycle then sits beside
    ; @emlCSVInit in the orchestrator rather than being split across
    ; graphs/eml-annotation-procedures.praat.
    ; ORDER MATTERS. The separate frames are staged FIRST, because staging
    ; reuses the one tidy collector and the model's own tidy has to be what
    ; is left in it when @emlResultWrite runs.
    if emlOneWayAnova.error$ = ""
        @emlResultClearExtras
        if .doTukey
            @emlDeclareTukeyResult: .groupCol$
            @emlResultStageExtra: "posthoc"
        endif
        @emlDeclareAnovaEffectSizes: .groupCol$
        @emlResultStageExtra: "effectsize"
    endif
    @emlDeclareOneWayAnovaResult: .tableName$, .dataCol$, .groupCol$,
    ... .tableId, .doTukey

    label END_ANOVA
    selectObject: .tableId
endproc


# ============================================================================
#
#  3. KRUSKAL-WALLIS
#
# ============================================================================

procedure emlRunKWAnalysis: .tableId, .dataCol$, .groupCol$, .doDunn, .adjMethod$
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlCountGroups: .tableId, .groupCol$
    if emlCountGroups.error$ <> ""
        .error$ = emlCountGroups.error$
        goto END_KW
    endif
    .nGroups = emlCountGroups.nGroups
    if .nGroups < 2
        .error$ = "Group column """ + .groupCol$ + """ has fewer than 2 groups."
        goto END_KW
    endif

    @emlKruskalWallis: .tableId, .dataCol$, .groupCol$
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
        if .doDunn and emlDunnTest.error$ = ""
            @emlDeclareDunnResult: .groupCol$
            @emlResultStageExtra: "posthoc"
        endif
        @emlDeclareKWResult: .tableName$, .dataCol$, .groupCol$
    endif

    label END_KW
    selectObject: .tableId
endproc


# ============================================================================
#
#  4. PAIRWISE COMPARISONS
#
# ============================================================================

procedure emlRunPairwiseAnalysis: .tableId, .dataCol$, .groupCol$, .test$, .adjMethod$
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlCountGroups: .tableId, .groupCol$
    if emlCountGroups.error$ <> ""
        .error$ = emlCountGroups.error$
        goto END_PAIRWISE
    endif
    if emlCountGroups.nGroups < 2
        .error$ = "Group column """ + .groupCol$ + """ has fewer than 2 groups."
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
    @emlReportPairwiseComparison: .tableName$, .dataCol$, .groupCol$, .test$, .adjMethod$

    ; BUILD, not a conversion: this orchestrator called @emlCSVInit and never
    ; added a row, so its export could not succeed at all (D66).
    if .error$ = ""
        @emlResultClearExtras
        @emlDeclarePairwiseResult: .tableName$, .groupCol$, .test$, .adjMethod$
    endif

    label END_PAIRWISE
    selectObject: .tableId
endproc


# ============================================================================
# @emlReportPairwiseComparison — NEW
# Extracted from inline code in eml-pairwise.praat.
# ============================================================================

procedure emlReportPairwiseComparison: .tableName$, .dataCol$, .groupCol$, .test$, .adjMethod$
    @emlUnderscoreToSpace: .tableName$
    .displayTable$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .dataCol$
    .displayData$ = emlUnderscoreToSpace.result$
    @emlUnderscoreToSpace: .groupCol$
    .displayGroup$ = emlUnderscoreToSpace.result$

    if .test$ = "welch" or .test$ = "student"
        # v1.2 item 5: emlPairwiseT.method$ is the ADJUSTMENT method
        # (bonferroni/holm/bh), not the name of the test — the header read
        # "Pairwise holm (holm adjustment)". The test is .test$
        # (welch/student), which this reporter already receives.
        if .test$ = "welch"
            .testLabel$ = "Welch t-test"
        else
            .testLabel$ = "Student t-test"
        endif
        .methodLabel$ = "Pairwise " + .testLabel$ + " (" + .adjMethod$ + " adjustment)"
        .nGroups = emlPairwiseT.nGroups

        @emlReportHeader: .methodLabel$
        @emlReportLineString: "Table", .displayTable$
        @emlReportLineString: "Data column", .displayData$
        @emlReportLineString: "Group column", .displayGroup$
        @emlReportLine: "Groups", .nGroups, 0
        @emlReportLine: "Pairs tested", emlPairwiseT.nPairs, 0

        @emlReportBlank
        @emlReportSection: "Adjusted p-values"
        appendInfoLine: ""
        .headerLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            .colName$ = replace$ (emlPairwiseT.groupName$ [.jGroup], "_", " ", 0)
            if length (.colName$) > 10
                .colName$ = left$ (.colName$, 10)
            endif
            .headerLine$ = .headerLine$ + left$ (.colName$ + "            ", 12)
        endfor
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            .rowName$ = replace$ (emlPairwiseT.groupName$ [.iGroup], "_", " ", 0)
            if length (.rowName$) > 12
                .rowName$ = left$ (.rowName$, 12)
            endif
            .rowLine$ = left$ (.rowName$ + "                ", 14)
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .pVal = emlPairwiseT.pMatrix## [.iGroup, .jGroup]
                    if .pVal < 0.001
                        .cellText$ = "< .001"
                    else
                        .cellText$ = fixed$ (.pVal, 4)
                    endif
                endif
                .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            appendInfoLine: .rowLine$
        endfor

        @emlReportBlank
        @emlReportSection: "Cohen's d (effect sizes)"
        appendInfoLine: ""
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            .rowName$ = replace$ (emlPairwiseT.groupName$ [.iGroup], "_", " ", 0)
            if length (.rowName$) > 12
                .rowName$ = left$ (.rowName$, 12)
            endif
            .rowLine$ = left$ (.rowName$ + "                ", 14)
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .dVal = emlPairwiseT.dMatrix## [.iGroup, .jGroup]
                    .cellText$ = fixed$ (.dVal, 3)
                endif
                .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            appendInfoLine: .rowLine$
        endfor

    elsif .test$ = "wilcoxon"
        .methodLabel$ = "Pairwise Wilcoxon/Mann-Whitney (" + .adjMethod$ + " adjustment)"
        .nGroups = emlPairwiseWilcoxon.nGroups

        @emlReportHeader: .methodLabel$
        @emlReportLineString: "Table", .displayTable$
        @emlReportLineString: "Data column", .displayData$
        @emlReportLineString: "Group column", .displayGroup$
        @emlReportLine: "Groups", .nGroups, 0
        @emlReportLine: "Pairs tested", emlPairwiseWilcoxon.nPairs, 0

        @emlReportBlank
        @emlReportSection: "Adjusted p-values"
        appendInfoLine: ""
        .headerLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            .colName$ = replace$ (emlPairwiseWilcoxon.groupName$ [.jGroup], "_", " ", 0)
            if length (.colName$) > 10
                .colName$ = left$ (.colName$, 10)
            endif
            .headerLine$ = .headerLine$ + left$ (.colName$ + "            ", 12)
        endfor
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            .rowName$ = replace$ (emlPairwiseWilcoxon.groupName$ [.iGroup], "_", " ", 0)
            if length (.rowName$) > 12
                .rowName$ = left$ (.rowName$, 12)
            endif
            .rowLine$ = left$ (.rowName$ + "                ", 14)
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .pVal = emlPairwiseWilcoxon.pMatrix## [.iGroup, .jGroup]
                    if .pVal < 0.001
                        .cellText$ = "< .001"
                    else
                        .cellText$ = fixed$ (.pVal, 4)
                    endif
                endif
                .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            appendInfoLine: .rowLine$
        endfor

        @emlReportBlank
        @emlReportSection: "Rank-biserial r (effect sizes)"
        appendInfoLine: ""
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            .rowName$ = replace$ (emlPairwiseWilcoxon.groupName$ [.iGroup], "_", " ", 0)
            if length (.rowName$) > 12
                .rowName$ = left$ (.rowName$, 12)
            endif
            .rowLine$ = left$ (.rowName$ + "                ", 14)
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .rVal = emlPairwiseWilcoxon.rMatrix## [.iGroup, .jGroup]
                    .cellText$ = fixed$ (.rVal, 3)
                endif
                .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            appendInfoLine: .rowLine$
        endfor

    elsif .test$ = "scheffe"
        .nGroups = emlScheffe.nGroups

        @emlReportHeader: "Scheffe Post-Hoc Comparisons"
        @emlReportLineString: "Table", .displayTable$
        @emlReportLineString: "Data column", .displayData$
        @emlReportLineString: "Group column", .displayGroup$
        @emlReportLine: "Groups", .nGroups, 0
        @emlReportLine: "Pairs tested", emlScheffe.nPairs, 0
        @emlReportLine: "MSE", emlScheffe.mse, 4
        @emlReportLine: "df (within)", emlScheffe.dfWithin, 0

        @emlReportBlank
        @emlReportSection: "Scheffe p-values"
        appendInfoLine: ""
        .headerLine$ = left$ ("" + "                ", 14)
        for .jGroup from 1 to .nGroups
            .colName$ = replace$ (emlScheffe.groupName$ [.jGroup], "_", " ", 0)
            if length (.colName$) > 10
                .colName$ = left$ (.colName$, 10)
            endif
            .headerLine$ = .headerLine$ + left$ (.colName$ + "            ", 12)
        endfor
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            .rowName$ = replace$ (emlScheffe.groupName$ [.iGroup], "_", " ", 0)
            if length (.rowName$) > 12
                .rowName$ = left$ (.rowName$, 12)
            endif
            .rowLine$ = left$ (.rowName$ + "                ", 14)
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .pVal = emlScheffe.pMatrix## [.iGroup, .jGroup]
                    if .pVal < 0.001
                        .cellText$ = "< .001"
                    else
                        .cellText$ = fixed$ (.pVal, 4)
                    endif
                endif
                .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            appendInfoLine: .rowLine$
        endfor

        @emlReportBlank
        @emlReportSection: "Mean Differences"
        appendInfoLine: ""
        appendInfoLine: .headerLine$

        for .iGroup from 1 to .nGroups
            .rowName$ = replace$ (emlScheffe.groupName$ [.iGroup], "_", " ", 0)
            if length (.rowName$) > 12
                .rowName$ = left$ (.rowName$, 12)
            endif
            .rowLine$ = left$ (.rowName$ + "                ", 14)
            for .jGroup from 1 to .nGroups
                if .iGroup = .jGroup
                    .cellText$ = "---"
                else
                    .diffVal = emlScheffe.diffMatrix## [.iGroup, .jGroup]
                    .cellText$ = fixed$ (.diffVal, 3)
                endif
                .rowLine$ = .rowLine$ + left$ (.cellText$ + "            ", 12)
            endfor
            appendInfoLine: .rowLine$
        endfor
    endif

    @emlReportFooter
endproc


# ============================================================================
#
#  5. TWO-WAY ANOVA
#
# ============================================================================

procedure emlRunTwoWayAnalysis: .tableId, .dataCol$, .factor1$, .factor2$
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    # Save current Info window content before Report two-way anova:
    # clears it (Praat's built-in command uses MelderInfo_open)
    .savedInfo$ = info$ ()

    @emlTwoWayAnova: .tableId, .dataCol$, .factor1$, .factor2$
    if emlTwoWayAnova.error$ <> ""
        .error$ = emlTwoWayAnova.error$
        goto END_TWOWAY
    endif

    # Restore previous Info window content.
    # Report two-way anova: cleared it; values have been parsed.
    if .savedInfo$ <> "" and .savedInfo$ <> newline$
        writeInfo: .savedInfo$
    else
        writeInfoLine: ""
    endif

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
    selectObject: .tableId
endproc


# ============================================================================
#
#  6. PAIRED COMPARISON
#
# ============================================================================

procedure emlRunPairedAnalysis: .tableId, .col1$, .col2$, .testType$
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""
    .nExcluded = 0

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

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
    # statistic under the t-test was finding D15 — the two can differ by a
    # wide margin whenever changes are consistent in direction but variable
    # in size, and nothing on screen distinguished them. In "both" mode each
    # test reports its own, under its own heading.
    if .testType$ = "parametric" or .testType$ = "both"
        @emlTTestPaired: .v1#, .v2#, 2
        @emlCohenDz: .v1#, .v2#
    endif
    if .testType$ = "nonparametric" or .testType$ = "both"
        @emlWilcoxonSignedRank: .v1#, .v2#, 2
        @emlMatchedPairsR: .v1#, .v2#, 2
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

    label END_PAIRED
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
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""
    .nExcluded = 0

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

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

    label END_CORR
    selectObject: .tableId
endproc


# ============================================================================
#
#  8. DESCRIPTIVE STATISTICS
#
# ============================================================================

procedure emlRunDescriptiveAnalysis: .tableId, .dataCol$
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

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

    # D96. The count of excluded rows was already honest; what it did not say
    # was WHY, and the three conditions need different responses from the
    # user. @emlExtractColumn has the breakdown, so pass it through rather
    # than recomputing it here and risking a second, disagreeing account.
    @emlReportDescriptiveAnalysis: .tableName$, .dataCol$, .nValid,
    ... .nUndefined, emlExtractColumn.note$

    label END_DESCRIBE
    selectObject: .tableId
endproc




# ============================================================================
#
#  PHASE 4 STUBS
#
# ============================================================================

procedure emlRunRegressionAnalysis: .tableId, .depCol$, .predCol$
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
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
endproc

# v1.2 item 7: .testType$ is RESERVED and deliberately unread. This
# orchestrator always computes both families of evidence — descriptive shape
# (skewness/kurtosis) and the formal Shapiro-Wilk test — and combines them
# into one recommendation; there is no branch to select. Existing call sites
# already pass different values ("both", "auto") with identical results.
# The parameter is retained because callers pass arguments positionally.
# Do not remove it without updating every call site.
procedure emlRunNormalityAnalysis: .tableId, .dataCol$, .testType$
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
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
        # SHAPIRO-WILK IS THE TEST. Skewness and kurtosis are descriptive
        # statistics, not tests, and they act as a backup — used to decide
        # only where Shapiro-Wilk cannot.
        #
        # Until 5 August this gate read `skKurtFail OR swFail`, which let a
        # descriptive rule of thumb overrule a formal test: a column
        # Shapiro-Wilk had declined to reject was still sent nonparametric
        # because its skewness crossed a threshold. That inverts the
        # hierarchy. Shapiro-Wilk is the most powerful of the common
        # omnibus normality tests across a broad range of alternatives
        # (Razali & Wah 2011); a rule of thumb does not outvote it.
        #
        # The one place shape legitimately intervenes is the large-n case,
        # where Shapiro-Wilk rejects departures too small to matter for a
        # parametric test. That override is kept, unchanged.
        #
        # Thresholds live in emlSkewThreshold / emlKurtosisThreshold
        # (stats/eml-output.praat) so this gate, the wizard's classifier and
        # the printed verdicts cannot drift apart, which they had.
        .shapeSevere = abs (.skewness) >= emlSkewThreshold
        ... or abs (.kurtosis) >= emlKurtosisThreshold
        .swUsable = (.swError$ = "")
        .swFail = 0
        if .swUsable and .swP < 0.05
            .swFail = 1
        endif

        .largeNOverride = 0
        if .swUsable
            if .swFail
                # Large-n override: Shapiro-Wilk rejects trivial departures
                # at large n. If the shape is not severe by the published
                # guideline, recommend parametric anyway — parametric tests
                # are robust at this sample size.
                if (not .shapeSevere) and .nValid > 50
                    .recommendation$ = "parametric"
                    .largeNOverride = 1
                else
                    .recommendation$ = "nonparametric"
                endif
            else
                # The test did not reject. Severe shape is still REPORTED —
                # @emlReportNormalityAnalysis prints the verdict either way —
                # but it does not overturn the test's finding.
                .recommendation$ = "parametric"
            endif
        else
            # Shapiro-Wilk unavailable (n outside its defined range, or an
            # internal error). This is the backup case, and the only one in
            # which shape decides anything.
            if .shapeSevere
                .recommendation$ = "nonparametric"
            else
                .recommendation$ = "parametric"
            endif
        endif

        @emlCSVInit
        @emlReportNormalityAnalysis: .tableName$, .dataCol$,
        ... .nValid, .nUndefined
    endif

    if .error$ = ""
        @emlResultClearExtras
        @emlDeclareNormalityResult: .tableName$, .dataCol$, .swW, .swP,
        ... .swError$, .skewness, .kurtosis, .nValid, .nUndefined,
        ... .recommendation$
    endif

    label END_NORMALITY
    selectObject: .tableId
endproc

# v1.2 item 7: unimplemented stub. It has no call sites anywhere in the
# plugin; it exists so the Phase 4 API surface is declared. It returns a
# non-empty .error$ and computes nothing — callers must check .error$ before
# reading any other output, because no other output is set.
procedure emlRunReliabilityAnalysis: .tableId, .subjectCol$, .raterCols$, .measure$, .scale$
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = "Not yet implemented — scheduled for Phase 4."
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""
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
    # D96. This is the row-wise reader: a subject is complete only if every
    # condition cell is present. It used to ask "Get value:", which counts a
    # European "1,5" as present and then puts 1 into the matrix. It now goes
    # through @eml_readCell like every other extraction path, so a row is
    # complete here exactly when it would be complete anywhere else.
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

    # --- D97: refuse a zero error term -----------------------------------
    # If every subject shows the same pattern across conditions, the
    # subject x condition residual is identically zero, .ssErr is zero, and
    # F is a division by zero. Praat does not raise on that; it returns a
    # finite number built out of the last bits of the subtraction, which is
    # how this printed F(2, 6) = 21110623253299200.0000 with a p-value
    # carrying 48 decimal places. The post-hoc in this same module already
    # caught the condition and refused, naming it "All differences are
    # identical (zero variance)" — the omnibus simply never asked.
    #
    # The floor has to be RELATIVE. An exactly-linear design leaves .ssErr
    # at around 1e-16 of .ssTot rather than at 0, so an absolute test for
    # equality with zero does not fire.
    .error$ = ""
    .warning$ = ""
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

    # --- D98: say when the design has no information left ----------------
    # With n = 2 subjects, df error = k - 1 and the Greenhouse-Geisser
    # epsilon is forced to its lower bound 1 / (k - 1) whatever the data
    # are. The result computes and prints; nothing about it is
    # interpretable. Epsilon pinned to the bound is the tell, and it is
    # already in hand at the moment of printing.
    if .n <= 2
        .warning$ = "n = " + string$ (.n) + " subjects. Greenhouse-Geisser "
        ... + "epsilon is forced to its lower bound "
        ... + fixed$ (1 / (.k - 1), 4) + " for any data at this n, so the "
        ... + "sphericity correction carries no information. Read F, p "
        ... + "and the corrected p as description of these two subjects, "
        ... + "not as a test."
    elsif .ggEpsilon <= 1 / (.k - 1) + 1e-9
        .warning$ = "Greenhouse-Geisser epsilon is at its lower bound "
        ... + fixed$ (1 / (.k - 1), 4) + ", the maximum possible departure "
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
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
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

    # D97. A zero error term is a property of the data, not a bad form
    # setting, so there is no other menu item that would work on it: the
    # remedy stays empty and the dialog says only what is wrong.
    if emlRMAnovaTest.error$ <> ""
        .error$ = emlRMAnovaTest.error$
        goto END_RM
    endif

    @emlCSVInit
    .h$ = "Repeated-measures ANOVA — " + .tableName$
    appendInfoLine: .h$
    .subj$ = "  Subjects (complete cases) n = " + string$ (.n)
        ... + ", conditions k = " + string$ (.k)
    appendInfoLine: .subj$
    for .j from 1 to .k
        .cm$ = "    " + emlExtractConditionMatrix.colLabel$ [.j] + " mean = "
            ... + fixed$ (emlRMAnovaTest.condMean# [.j], 4)
        appendInfoLine: .cm$
    endfor
    .fLine$ = "  F(" + string$ (emlRMAnovaTest.dfCond) + ", "
        ... + string$ (emlRMAnovaTest.dfErr) + ") = "
        ... + fixed$ (emlRMAnovaTest.fStat, 4) + ", p = "
        ... + fixed$ (emlRMAnovaTest.p, 4)
    appendInfoLine: .fLine$
    .ggLine$ = "  Greenhouse-Geisser epsilon = "
        ... + fixed$ (emlRMAnovaTest.ggEpsilon, 4) + ", GG-corrected p = "
        ... + fixed$ (emlRMAnovaTest.pGG, 4)
    appendInfoLine: .ggLine$

    # D98. Printed immediately under the numbers it qualifies, not at the
    # foot of the report, because a caveat below the post-hoc table reads
    # as being about the post-hoc.
    if emlRMAnovaTest.warning$ <> ""
        @emlWrapText: "Caution: " + emlRMAnovaTest.warning$, 68
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
        # D96: say WHICH condition dropped the row and why.
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
        if .doPostHoc and emlRMPostHoc.nPairs > 0
            @emlDeclareRMPostHoc
            @emlResultStageExtra: "posthoc"
        endif
        @emlDeclareRMResult: .tableName$, .n, .k
    endif

    label END_RM
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
    ; The three-file declaration flag is cleared HERE, at entry, and not at
    ; @emlCSVInit -- an orchestrator can fail its guards and reach `goto END_*`
    ; without ever calling @emlCSVInit, and the flag from the PREVIOUS analysis
    ; would then still be set. Demonstrated 6 Aug 2026: a repeated-measures run
    ; that bailed on "Need at least 2 condition columns" exported the previous
    ; analysis's tidy and glance under the RM name.
    emlResult_declared = 0
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
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

    @emlCSVInit
    .h$ = "Friedman test — " + .tableName$
    appendInfoLine: .h$
    .subj$ = "  Subjects (complete cases) n = " + string$ (.n)
        ... + ", conditions k = " + string$ (.k)
    appendInfoLine: .subj$
    for .j from 1 to .k
        .rs$ = "    " + emlExtractConditionMatrix.colLabel$ [.j] + " rank sum = "
            ... + fixed$ (emlFriedmanTest.rankSum# [.j], 1)
        appendInfoLine: .rs$
    endfor
    .chiLine$ = "  chi-square(" + string$ (emlFriedmanTest.df) + ") = "
        ... + fixed$ (emlFriedmanTest.chiSq, 4) + ", p = "
        ... + fixed$ (emlFriedmanTest.p, 4)
    appendInfoLine: .chiLine$

    if .doPostHoc
        @emlRMPostHoc: .data##, .n, .k, "nonparametric", .adjMethod$
    endif
    if .nExcluded > 0
        .exclNote$ = "  Note: " + string$ (.nExcluded)
            ... + " row(s) excluded for missing data (analyzed n = "
            ... + string$ (.n) + " complete cases)."
        appendInfoLine: .exclNote$
        # D96: say WHICH condition dropped the row and why.
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
        if .doPostHoc and emlRMPostHoc.nPairs > 0
            @emlDeclareFriedmanPostHoc
            @emlResultStageExtra: "posthoc"
        endif
        @emlDeclareFriedmanResult: .tableName$, .n, .k
    endif

    label END_FRIED
    selectObject: .tableId
endproc

# ============================================================================
# @emlRMPostHoc — pairwise post-hoc for repeated-measures designs.
# Parametric -> paired t; nonparametric -> Wilcoxon signed-rank.
# p-values adjusted by .adjMethod$ (bonferroni / holm / bh).
# ============================================================================
procedure emlRMPostHoc: .data##, .n, .k, .testType$, .adjMethod$
    # v1.2 item 2: validate the requested adjustment method. An unrecognised
    # string previously fell through to Holm silently while the header still
    # printed the requested name. Now the fallback is disclosed and the
    # header prints the method that actually ran (.adjUsed$).
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
    .phHdr$ = "  Post-hoc pairwise (" + .testType$ + ", "
        ... + .adjUsed$ + "-adjusted):"
    appendInfoLine: .phHdr$
    if .adjWarn$ <> ""
        appendInfoLine: .adjWarn$
    endif
    for .pp from 1 to .nPairs
        .ai = .pairLabelA [.pp]
        .bi = .pairLabelB [.pp]
        if .rawP# [.pp] = undefined
            .rawTxt$ = "n/a"
            .adjTxt$ = "n/a"
        else
            .rawTxt$ = fixed$ (.rawP# [.pp], 4)
            if .adj# [.pp] = undefined
                .adjTxt$ = "n/a"
            else
                .adjTxt$ = fixed$ (.adj# [.pp], 4)
            endif
        endif
        .row$ = "    " + emlExtractConditionMatrix.colLabel$ [.ai] + " vs "
            ... + emlExtractConditionMatrix.colLabel$ [.bi] + ": p(raw) = "
            ... + .rawTxt$ + ", p(adj) = " + .adjTxt$
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
# @emlRunLMMAnalysis lived here until 6 August 2026. It now lives at the
# foot of stats/eml-lmm.praat, beside the engine it calls.
#
# It was moved, not deleted. The author tabled linear mixed models and took
# the menu entry out of setup.praat on 5 August, but the orchestrator stayed
# in this file — which every wrapper includes — while the engine it calls
# (@emlLMM, @emlLMMSummary, @emlJohnsonR2, @emlWaldCI) is in a module no
# wrapper includes. Praat resolves a procedure name when it is CALLED, so
# nine wrappers carried four calls apiece that could not resolve, invisible
# to any parse check. harness/check_includes.py finds this class of defect;
# it was written after the same thing bit the describe wrapper on 6 August.
#
# Orchestrator and engine now travel together: including eml-lmm.praat gets
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
    @emlAugmentFrom: .tableId
    selectObject: .tableId
    .nRows = Get number of rows
    for .r from 1 to .nRows
        selectObject: .tableId
        .g$ = Get value: .r, .groupCol$
        .v$ = Get value: .r, .dataCol$
        .v = number (.v$)
        .fit = undefined
        for .g from 1 to emlOneWayAnova.nGroups
            if emlOneWayAnova.groupLabel$ [.g] = .g$
                .fit = emlOneWayAnova.groupMean [.g]
            endif
        endfor
        if .fit <> undefined and .v <> undefined
            @emlAugmentNum: ".fitted", .r, .fit
            @emlAugmentNum: ".resid", .r, .v - .fit
            @emlAugmentNum: ".std.resid", .r,
            ... (.v - .fit) / sqrt (emlOneWayAnova.msWithin)
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
procedure emlDeclareAnovaEffectSizes: .groupCol$
    @emlTidyClear
    @emlTidyRow: .groupCol$
    @emlTidyNum: "effect.size", emlOneWayAnova.etaSquared
    @emlTidyStr: "effect.size.type", "eta.squared"
    for .i from 1 to emlOneWayAnova.nGroups - 1
        for .j from .i + 1 to emlOneWayAnova.nGroups
            @emlTidyRow: .groupCol$
            @emlTidyStr: "contrast", emlOneWayAnova.groupName$ [.i] + "-"
            ... + emlOneWayAnova.groupName$ [.j]
            @emlTidyNum: "effect.size", emlOneWayAnova.dMatrix## [.i, .j]
            @emlTidyStr: "effect.size.type", "cohens.d"
        endfor
    endfor
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

    if .doPar and emlTTest.error$ = ""
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
    if .doNon and emlMannWhitneyU.error$ = ""
        @emlTidyRow: ""
        @emlTidyNum: "statistic",   emlMannWhitneyU.u1
        @emlTidyNum: "p.value",     emlMannWhitneyU.p
        @emlTidyStr: "method",      emlMannWhitneyU.method$
        @emlTidyStr: "alternative", emlMannWhitneyU.alternative$
    endif

    ; glance for an htest is broom's tidy again, plus what we know about the
    ; design. The parametric row wins when both ran, matching the report.
    if .doPar and emlTTest.error$ = ""
        @emlGlanceNum: "statistic", emlTTest.t
        @emlGlanceNum: "p.value",   emlTTest.p
        @emlGlanceNum: "parameter", emlTTest.df
        @emlGlanceNum: "estimate",  emlTTest.meanDiff
        @emlGlanceStr: "method",    emlTTest.method$
        @emlGlanceNum: "nobs",      emlTTest.n1 + emlTTest.n2
    elsif .doNon and emlMannWhitneyU.error$ = ""
        @emlGlanceNum: "statistic", emlMannWhitneyU.u1
        @emlGlanceNum: "p.value",   emlMannWhitneyU.p
        @emlGlanceStr: "method",    emlMannWhitneyU.method$
        @emlGlanceNum: "nobs",      emlMannWhitneyU.n1 + emlMannWhitneyU.n2
    endif
    @emlGlanceNum: "n.groups", 2
endproc


procedure emlDeclareTwoGroupEffects: .doPar, .doNon
    @emlTidyClear
    if .doPar and emlCohenD.error$ = ""
        @emlTidyRow: ""
        @emlTidyNum: "effect.size", emlCohenD.d
        @emlTidyStr: "effect.size.type", "cohens.d"
        @emlTidyRow: ""
        @emlTidyNum: "effect.size", emlCohenD.g
        @emlTidyStr: "effect.size.type", "hedges.g"
    endif
    if .doNon and emlRankBiserialR.error$ = ""
        @emlTidyRow: ""
        @emlTidyNum: "effect.size", emlRankBiserialR.r
        @emlTidyStr: "effect.size.type", "rank.biserial"
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
# @emlRunPairwiseAnalysis called @emlCSVInit and never added a row, so its
# export could not succeed at all (D66). There is no existing shape to mirror.
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

    @emlAugmentFrom: .tableId
    for .r from 1 to emlTwoWayAnova.nRows
        .c = emlTwoWayAnova.cellOf [.r]
        if .c > 0
            .fit = emlTwoWayAnova.cellMean [.c]
            @emlAugmentNum: ".fitted", .r, .fit
            @emlAugmentNum: ".resid", .r, emlTwoWayAnova.yValue [.r] - .fit
            @emlAugmentNum: ".std.resid", .r,
            ... (emlTwoWayAnova.yValue [.r] - .fit) / sqrt (emlTwoWayAnova.msError)
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

    if .doPar and emlTTestPaired.error$ = ""
        @emlTidyRow: ""
        @emlTidyNum: "estimate",  emlTTestPaired.meanDiff
        @emlTidyNum: "statistic", emlTTestPaired.t
        @emlTidyNum: "p.value",   emlTTestPaired.p
        @emlTidyNum: "parameter", emlTTestPaired.df
        @emlTidyStr: "method",      "Paired t-test"
        @emlTidyStr: "alternative", "two.sided"
    endif
    ; @emlMatchedPairsR re-runs @emlWilcoxonSignedRank, so the Wilcoxon row is
    ; declared BEFORE the effect sizes are staged. Ordering, not preference.
    if .doNon and emlWilcoxonSignedRank.error$ = ""
        @emlTidyRow: ""
        @emlTidyNum: "statistic",   emlWilcoxonSignedRank.tPlus
        @emlTidyNum: "p.value",     emlWilcoxonSignedRank.p
        @emlTidyStr: "method",      emlWilcoxonSignedRank.method$
        @emlTidyStr: "alternative", emlWilcoxonSignedRank.alternative$
    endif

    if .doPar and emlTTestPaired.error$ = ""
        @emlGlanceNum: "estimate",  emlTTestPaired.meanDiff
        @emlGlanceNum: "statistic", emlTTestPaired.t
        @emlGlanceNum: "p.value",   emlTTestPaired.p
        @emlGlanceNum: "parameter", emlTTestPaired.df
        @emlGlanceNum: "nobs",      emlTTestPaired.n
        @emlGlanceStr: "method",    "Paired t-test"
    elsif .doNon and emlWilcoxonSignedRank.error$ = ""
        @emlGlanceNum: "statistic", emlWilcoxonSignedRank.tPlus
        @emlGlanceNum: "p.value",   emlWilcoxonSignedRank.p
        @emlGlanceNum: "nobs",      emlWilcoxonSignedRank.n
        @emlGlanceStr: "method",    emlWilcoxonSignedRank.method$
    endif
endproc


procedure emlDeclarePairedEffects: .doPar, .doNon
    @emlTidyClear
    if .doPar and emlCohenDz.error$ = ""
        @emlTidyRow: ""
        @emlTidyNum: "effect.size", emlCohenDz.dz
        @emlTidyStr: "effect.size.type", "cohens.dz"
    endif
    if .doNon and emlMatchedPairsR.error$ = ""
        @emlTidyRow: ""
        @emlTidyNum: "effect.size", emlMatchedPairsR.r
        @emlTidyStr: "effect.size.type", "matched.pairs.rank.biserial"
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
    selectObject: .tableId
    .nRows = Get number of rows
    for .r from 1 to .nRows
        selectObject: .tableId
        .x = Get value: .r, .predCol$
        .y = Get value: .r, .depCol$
        if .x <> undefined and .y <> undefined
            .fit = emlLinearRegression.intercept + emlLinearRegression.slope * .x
            @emlAugmentNum: ".fitted", .r, .fit
            @emlAugmentNum: ".resid", .r, .y - .fit
            @emlAugmentNum: ".std.resid", .r,
            ... (.y - .fit) / emlLinearRegression.seResidual
        endif
    endfor
endproc


# --- 9. Normality ----------------------------------------------------------
# Reads emlRunNormalityAnalysis.* -- the one orchestrator that copies every
# value onto itself, so nothing here depends on procedure-global survival.
procedure emlDeclareNormalityResult: .tableName$, .dataCol$, .swW, .swP,
    ... .swError$, .skewness, .kurtosis, .nValid, .nUndefined, .recommendation$
    @emlResultBegin: .tableName$, "Normality"

    if .swError$ = ""
        @emlTidyRow: .dataCol$
        @emlTidyNum: "statistic", .swW
        @emlTidyNum: "p.value",   .swP
        @emlTidyStr: "method",    "Shapiro-Wilk normality test"
        @emlGlanceNum: "statistic", .swW
        @emlGlanceNum: "p.value",   .swP
        @emlGlanceStr: "method",    "Shapiro-Wilk normality test"
    else
        ; Shapiro-Wilk out of range is not a failed export -- the shape
        ; statistics are still the answer, and the reason is carried.
        @emlTidyRow: .dataCol$
        @emlTidyStr: "method", "Shape statistics only"
        @emlGlanceStr: "method",  "Shape statistics only"
        @emlGlanceStr: "warning", .swError$
    endif
    @emlGlanceNum: "skewness",    .skewness
    @emlGlanceNum: "kurtosis",    .kurtosis
    @emlGlanceNum: "nobs",        .nValid
    @emlGlanceNum: "n.excluded",  .nUndefined
    @emlGlanceStr: "alternative", .recommendation$
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
