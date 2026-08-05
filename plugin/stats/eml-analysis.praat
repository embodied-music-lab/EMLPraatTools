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

    label END_TWO_GROUP
    selectObject: .tableId
endproc


# ============================================================================
#
#  2. ONE-WAY ANOVA
#
# ============================================================================

procedure emlRunAnovaAnalysis: .tableId, .dataCol$, .groupCol$, .doTukey
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

    label END_ANOVA
    selectObject: .tableId
endproc


# ============================================================================
#
#  3. KRUSKAL-WALLIS
#
# ============================================================================

procedure emlRunKWAnalysis: .tableId, .dataCol$, .groupCol$, .doDunn, .adjMethod$
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

    label END_KW
    selectObject: .tableId
endproc


# ============================================================================
#
#  4. PAIRWISE COMPARISONS
#
# ============================================================================

procedure emlRunPairwiseAnalysis: .tableId, .dataCol$, .groupCol$, .test$, .adjMethod$
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

    label END_TWOWAY
    selectObject: .tableId
endproc


# ============================================================================
#
#  6. PAIRED COMPARISON
#
# ============================================================================

procedure emlRunPairedAnalysis: .tableId, .col1$, .col2$, .testType$
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

    label END_PAIRED
    selectObject: .tableId
endproc


# ============================================================================
#
#  7. CORRELATION
#
# ============================================================================

procedure emlRunCorrelationAnalysis: .tableId, .colX$, .colY$, .testType$
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

    label END_CORR
    selectObject: .tableId
endproc


# ============================================================================
#
#  8. DESCRIPTIVE STATISTICS
#
# ============================================================================

procedure emlRunDescriptiveAnalysis: .tableId, .dataCol$
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

    @emlReportDescriptiveAnalysis: .tableName$, .dataCol$, .nValid, .nUndefined

    label END_DESCRIBE
    selectObject: .tableId
endproc


# ============================================================================
# @emlReportDescriptiveAnalysis — NEW
# Extracted from inline code in eml-describe-table.praat.
# ============================================================================

procedure emlReportDescriptiveAnalysis: .tableName$, .dataCol$, .nValid, .nUndefined
    .displayColumn$ = replace$ (.dataCol$, "_", " ", 0)
    .displayTable$ = replace$ (.tableName$, "_", " ", 0)

    @emlReportHeader: "Descriptive Statistics"

    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Column", .displayColumn$
    @emlReportLine: "N (valid)", .nValid, 0
    if .nUndefined > 0
        @emlReportLine: "N (undefined)", .nUndefined, 0
    endif

    @emlReportBlank
    @emlReportSection: "Central Tendency"
    @emlReportLine: "Mean", emlDescribe.mean, 4
    @emlReportLine: "Median", emlDescribe.median, 4
    @emlReportLine: "SEM", emlDescribe.sem, 4

    @emlReportBlank
    @emlReportSection: "Dispersion"
    @emlReportLine: "SD", emlDescribe.sd, 4
    @emlReportLine: "Variance", emlDescribe.variance, 4
    @emlReportLine: "Range", emlDescribe.range, 4
    @emlReportLine: "Min", emlDescribe.min, 4
    @emlReportLine: "Max", emlDescribe.max, 4

    @emlReportBlank
    @emlReportSection: "Quartiles"
    @emlReportLine: "Q1", emlDescribe.q1, 4
    @emlReportLine: "Q2 (Median)", emlDescribe.median, 4
    @emlReportLine: "Q3", emlDescribe.q3, 4
    @emlReportLine: "IQR", emlDescribe.iqr, 4

    @emlReportBlank
    @emlReportSection: "Distribution Shape"
    @emlReportLine: "Skewness", emlDescribe.skewness, 4
    @emlReportLine: "Kurtosis (excess)", emlDescribe.kurtosis, 4

    @emlReportBlank
    @emlReportSection: "95% Confidence Interval"
    @emlReportLine: "Lower", emlDescribe.ci95Lower, 4
    @emlReportLine: "Upper", emlDescribe.ci95Upper, 4

    @emlReportFooter
endproc


# ============================================================================
#
#  PHASE 4 STUBS
#
# ============================================================================

procedure emlRunRegressionAnalysis: .tableId, .depCol$, .predCol$
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

        # Interpretation
        # Thresholds come from emlSkewThreshold / emlKurtosisThreshold
        # (stats/eml-output.praat) so this gate cannot drift from the
        # wizard's classifier, which it had — 3 here against 1 there.
        .skKurtFail = abs (.skewness) >= emlSkewThreshold
        ... or abs (.kurtosis) >= emlKurtosisThreshold
        .swFail = 0
        if .swError$ = ""
            if .swP < 0.05
                .swFail = 1
            endif
        endif

        if .skKurtFail or .swFail
            # Large-n override: Shapiro-Wilk rejects trivial departures
            # at large n. If distribution shape is acceptable (skewness
            # and kurtosis within limits), recommend parametric anyway —
            # parametric tests are robust at this sample size.
            if .swFail and (not .skKurtFail) and .nValid > 50
                .recommendation$ = "parametric"
                .largeNOverride = 1
            else
                .recommendation$ = "nonparametric"
                .largeNOverride = 0
            endif
        else
            .recommendation$ = "parametric"
            .largeNOverride = 0
        endif

        @emlCSVInit
        @emlReportNormalityAnalysis: .tableName$, .dataCol$,
        ... .nValid, .nUndefined
    endif

    label END_NORMALITY
    selectObject: .tableId
endproc

# v1.2 item 7: unimplemented stub. It has no call sites anywhere in the
# plugin; it exists so the Phase 4 API surface is declared. It returns a
# non-empty .error$ and computes nothing — callers must check .error$ before
# reading any other output, because no other output is set.
procedure emlRunReliabilityAnalysis: .tableId, .subjectCol$, .raterCols$, .measure$, .scale$
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
    # First pass: count complete rows
    .nComplete = 0
    for .row from 1 to .nRows
        .complete = 1
        for .j from 1 to .k
            selectObject: .tableId
            .cellVal = Get value: .row, .colLabel$ [.j]
            if .cellVal = undefined
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
            selectObject: .tableId
            .cellVal = Get value: .row, .colLabel$ [.j]
            if .cellVal = undefined
                .complete = 0
            endif
        endfor
        if .complete = 1
            .r = .r + 1
            for .j from 1 to .k
                selectObject: .tableId
                .data## [.r, .j] = Get value: .row, .colLabel$ [.j]
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
    .dfCond = .k - 1
    .dfErr = (.k - 1) * (.n - 1)
    .msCond = .ssCond / .dfCond
    .msErr = .ssErr / .dfErr
    .fStat = .msCond / .msErr
    .p = fisherQ (.fStat, .dfCond, .dfErr)
    @emlGGEpsilon: .data##, .n, .k
    .ggEpsilon = emlGGEpsilon.epsilon
    .pGG = fisherQ (.fStat, .dfCond * .ggEpsilon, .dfErr * .ggEpsilon)
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

    if .doPostHoc
        @emlRMPostHoc: .data##, .n, .k, "parametric", .adjMethod$
    endif
    if .nExcluded > 0
        .exclNote$ = "  Note: " + string$ (.nExcluded)
            ... + " row(s) excluded for missing data (analyzed n = "
            ... + string$ (.n) + " complete cases)."
        appendInfoLine: .exclNote$
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
# @emlRunLMMAnalysis — Linear mixed model orchestrator (Phase 4).
# Shared entry point for the menu front-end, the wizard, and the direct API.
# Wraps the verified EML LMM engine (@emlLMM) and its lme4-style reporter
# (@emlLMMSummary), then appends marginal/conditional R-squared and, on
# request, 95% Wald CIs. DRY: every path calls THIS, so a change here
# propagates to all of them.
#
# Input:  .tableId          — Table with the response + predictor + group cols
#         .formula$         — lme4-style formula, e.g. "y ~ x + (1 + x | group)"
#         .contrastCoding$  — "treatment" / "sum" / "helmert" / "poly"
#         .useREML          — 1 = REML (default), 0 = ML
#         .doR2             — 1 = append Nakagawa/Johnson R-squared
#         .doCI             — 1 = append 95% Wald CIs for fixed effects
# Output: .error$           — non-empty on failure (nothing printed)
# ============================================================================
procedure emlRunLMMAnalysis: .tableId, .formula$, .contrastCoding$, .useREML, .doR2, .doCI
    .error$ = ""
    # Menu item that WOULD work on this table, when one exists (D93).
    .remedy$ = ""

    selectObject: .tableId
    .tableName$ = selected$ ("Table")

    @emlLMM: .tableId, .formula$, .contrastCoding$, .useREML, 3000
    if emlLMM.error$ <> ""
        .error$ = emlLMM.error$
        goto END_LMM_ORCH
    endif

    # Standard lme4-style summary (engine's own reporter — reused, not copied).
    @emlLMMSummary

    # Marginal / conditional R-squared (canonical Nakagawa/Johnson).
    if .doR2
        @emlJohnsonR2
        appendInfoLine: ""
        .r2mLine$ = "Marginal R" + "^2" + " (fixed effects): "
            ... + fixed$ (emlJohnsonR2.r2Marginal, 4)
        appendInfoLine: .r2mLine$
        .r2cLine$ = "Conditional R" + "^2" + " (fixed + random): "
            ... + fixed$ (emlJohnsonR2.r2Conditional, 4)
        appendInfoLine: .r2cLine$
    endif

    # 95% Wald confidence intervals for the fixed effects (t / Satterthwaite df).
    if .doCI
        @emlWaldCI: 0.95
        appendInfoLine: ""
        .ciHdr$ = "95% Wald confidence intervals (fixed effects):"
        appendInfoLine: .ciHdr$
        for .j from 1 to emlLMM.nFixedCols
            .cn$ = emlModelMatrix.colName'.j'$
            .lo$ = fixed$ (emlWaldCI.lower# [.j], 4)
            .hi$ = fixed$ (emlWaldCI.upper# [.j], 4)
            .ciRow$ = "  " + .cn$ + ": [" + .lo$ + ", " + .hi$ + "]"
            appendInfoLine: .ciRow$
        endfor
    endif

    if emlLMM.converged = 0
        appendInfoLine: ""
        .warnLine$ = "WARNING: the optimizer did not fully converge — "
            ... + "interpret estimates with caution (try simplifying the "
            ... + "random-effects structure)."
        appendInfoLine: .warnLine$
    endif

    label END_LMM_ORCH
    selectObject: .tableId
endproc


# ============================================================================
# END OF EML ANALYSIS ORCHESTRATORS
# ============================================================================
