# ============================================================================
# harness/lane4parity/doors.praat — wizard-row vs menu-door engine-call parity
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS PROVES. Punch list lane 4's acceptance is "each new row drives to
# the SAME ENGINE CALL its menu sibling makes." The wizard cannot be driven
# headless (`beginPause:` crashes under --run — see harness/posthocgate's own
# header for the measured facts). What CAN be driven headless, and IS
# elsewhere in this tree (harness/posthocgate/doors.praat, same idiom), is
# the analysis engine the dialogs are wrappers around. This file drives, for
# every new or changed row in eml-wizard.praat's two-group, paired,
# correlation, and three-or-more-groups pages, TWO calls per row:
#
#   WIZARD <row>   the exact @emlRun*Analysis / @emlRunPairwiseAnalysis call
#                   eml-wizard.praat's dispatch code makes for that row, with
#                   its argument values copied VERBATIM from the file's own
#                   *FromMenu decode procedures (read at
#                   scripts/eml-wizard.praat, the emlWizard2GroupTestFromMenu /
#                   emlWizardPairedTestFromMenu / emlWizard3GroupTestFromMenu
#                   procedures, and their call sites in the dispatch blocks).
#   MENU <row>     the exact call the row's menu-door sibling makes for the
#                   equivalent selection, copied VERBATIM from that door's own
#                   source (eml-compare-groups.praat, eml-compare-paired.praat,
#                   eml-correlate.praat, eml-compare-k-groups.praat,
#                   eml-compare-kw.praat, eml-pairwise.praat).
#
# Both calls run on the SAME fixture, back to back, Info window cleared
# between. If the transcripts differ, either the two calls are not actually
# the same engine call (a real defect) or this file mistranscribed one side
# (fix the transcription). Because Praat is deterministic and both sides call
# the identical library procedure, byte-identical transcripts are the
# expected — and asserted — result.
#
# Usage: run.sh drives this once per row pair and diffs the two captured
# blocks; see run.sh for the row table.
# ============================================================================

include ../../plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ../../plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ../../plugin_EML_StatsGraphs/stats/eml-extract.praat
include ../../plugin_EML_StatsGraphs/stats/eml-output.praat
include ../../plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ../../plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ../../plugin_EML_StatsGraphs/stats/eml-analysis.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat

Text writing preferences: "UTF-8"
emlGroupSortAlphabetical = 0

leg$ = environment$ ("EML_L4P_LEG")
if leg$ = ""
    exitScript: "lane4parity: EML_L4P_LEG is not set."
endif

procedure loadTwo
    .id = Read Table from comma-separated file: "fixture_two.csv"
endproc
procedure loadPaired
    .id = Read Table from comma-separated file: "fixture_paired.csv"
endproc
procedure loadCorr
    .id = Read Table from comma-separated file: "fixture_corr.csv"
endproc
procedure loadK
    .id = Read Table from comma-separated file: "fixture_kgroups.csv"
endproc
procedure loadCorrGroup
    .id = Read Table from comma-separated file: "fixture_corr_group.csv"
endproc
procedure loadNormality
    .id = Read Table from comma-separated file: "fixture_normality.csv"
endproc

appendInfoLine: "== LEG ", leg$, " =="

# ---------------------------------------------------------------------------
# 4.1 two-group "Both": wizard test_approach = 3 -> wizEqualVar = 0 (default
# prevVarAssume = 1), test approach "both". Menu sibling: testChoice = 4 in
# eml-compare-groups.praat -> testType$ = "both", equalVar = 0 (only
# testChoice = 2 sets equalVar = 1).
# ---------------------------------------------------------------------------
if leg$ = "two_both_wizard" or leg$ = "two_both_menu"
    @loadTwo
    selectObject: loadTwo.id
    @emlRunTwoGroupAnalysis: loadTwo.id, "value", "group", "both", 0
endif

# ---------------------------------------------------------------------------
# 4.1 paired "Both": wizard test_approach = 3 -> "both". Menu sibling:
# testChoice = 3 in eml-compare-paired.praat -> testType$ = "both".
# ---------------------------------------------------------------------------
if leg$ = "paired_both_wizard" or leg$ = "paired_both_menu"
    @loadPaired
    selectObject: loadPaired.id
    @emlRunPairedAnalysis: loadPaired.id, "pre", "post", "both"
endif

# ---------------------------------------------------------------------------
# 4.1 correlation "Both": wizard test_approach = 3 -> "both". Menu sibling:
# testChoice = 3 in eml-correlate.praat -> testType$ = "both".
# ---------------------------------------------------------------------------
if leg$ = "corr_both_wizard" or leg$ = "corr_both_menu"
    @loadCorr
    selectObject: loadCorr.id
    @emlRunCorrelationAnalysis: loadCorr.id, "x", "y", "both"
endif

# ---------------------------------------------------------------------------
# 4.2 "ANOVA only, no pairwise tests": wizard row 2 -> phTest$ = "" ->
# doTukey = 0, no @emlRunPairwiseAnalysis call. Menu sibling:
# eml-compare-k-groups.praat with tukey_HSD_post_hoc = 0 -> doTukey = 0, no
# further call either.
# ---------------------------------------------------------------------------
if leg$ = "anova_only_wizard" or leg$ = "anova_only_menu"
    @loadK
    selectObject: loadK.id
    @emlRunAnovaAnalysis: loadK.id, "F0_Hz", "voice_type", 0
endif

# ---------------------------------------------------------------------------
# 4.2 "Kruskal-Wallis only, no pairwise tests": wizard row 12 -> phTest$ = ""
# -> doDunn = 0, adjMethod$ = "holm" (unused, matches the menu wrapper's own
# filler value). Menu sibling: eml-compare-kw.praat, comparison = 1 ->
# doDunn = 0, adjMethod$ = "holm".
# ---------------------------------------------------------------------------
if leg$ = "kw_only_wizard" or leg$ = "kw_only_menu"
    @loadK
    selectObject: loadK.id
    @emlRunKruskalWallisAnalysis: loadK.id, "F0_Hz", "voice_type", 0, "holm"
endif

# ---------------------------------------------------------------------------
# 4.3 pairwise grid — one representative NEW cell that the old three-row
# grid never offered: "Pairwise Student t, Bonferroni". Wizard row 9 ->
# phTest$ = "student", phAdj$ = "bonferroni". Menu sibling: the standalone
# pairwise dialog (eml-pairwise.praat), testChoice = 1 (Pairwise t-test),
# tVariantChoice = 2 (Student) -> test$ = "student"; adjChoice = 1
# (Bonferroni) -> adjMethod$ = "bonferroni". Both run the ANOVA first (the
# wizard's page always does; the pairwise dialog is analysis-agnostic and
# is driven here on its own, since the omnibus is not part of its own
# report) — the parity claim is on the PAIRWISE call, so the ANOVA call is
# run for the wizard leg only, matching what the wizard page actually does,
# and excluded from the diffed block.
# ---------------------------------------------------------------------------
if leg$ = "pw_student_bonf_wizard"
    @loadK
    selectObject: loadK.id
    @emlRunAnovaAnalysis: loadK.id, "F0_Hz", "voice_type", 0
    appendInfoLine: "===PARITY_BLOCK_START==="
    selectObject: loadK.id
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "student", "bonferroni"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif
if leg$ = "pw_student_bonf_menu"
    @loadK
    appendInfoLine: "===PARITY_BLOCK_START==="
    selectObject: loadK.id
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "student", "bonferroni"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif

# ---------------------------------------------------------------------------
# 4.3 CORRECTION — the three rows the first wording of 4.3 left out: the
# standalone pairwise dialog's rank-based cells (test$ = "wilcoxon"), decoded
# like the twelve rows above, into the SAME @emlRunPairwiseAnalysis call the
# standalone dialog makes for each cell. One leg per adjustment, both doors,
# so all three new rows carry their own proof rather than one row standing
# in for the family. Wizard rows 16/17/18 -> phTest$ = "wilcoxon", phAdj$ =
# "holm"/"bonferroni"/"bh" (eml-wizard.praat's emlWizard3GroupTestFromMenu).
# Menu sibling: eml-pairwise.praat, testChoice = 2 (Pairwise Wilcoxon) ->
# test$ = "wilcoxon"; adjChoice 2/1/3 -> adjMethod$ "holm"/"bonferroni"/"bh"
# respectively. Same shape as pw_student_bonf above: the wizard leg also
# runs the preceding ANOVA/KW-omnibus page code the pairwise leg does not,
# so the ANOVA-page KW omnibus runs OUTSIDE the diffed block and the parity
# claim is on the PAIRWISE call only.
# ---------------------------------------------------------------------------
if leg$ = "pw_wilcoxon_holm_wizard"
    @loadK
    selectObject: loadK.id
    @emlRunKruskalWallisAnalysis: loadK.id, "F0_Hz", "voice_type", 0, "holm"
    appendInfoLine: "===PARITY_BLOCK_START==="
    selectObject: loadK.id
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "wilcoxon", "holm"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif
if leg$ = "pw_wilcoxon_holm_menu"
    @loadK
    appendInfoLine: "===PARITY_BLOCK_START==="
    selectObject: loadK.id
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "wilcoxon", "holm"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif

if leg$ = "pw_wilcoxon_bonf_wizard"
    @loadK
    selectObject: loadK.id
    @emlRunKruskalWallisAnalysis: loadK.id, "F0_Hz", "voice_type", 0, "holm"
    appendInfoLine: "===PARITY_BLOCK_START==="
    selectObject: loadK.id
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "wilcoxon", "bonferroni"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif
if leg$ = "pw_wilcoxon_bonf_menu"
    @loadK
    appendInfoLine: "===PARITY_BLOCK_START==="
    selectObject: loadK.id
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "wilcoxon", "bonferroni"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif

if leg$ = "pw_wilcoxon_bh_wizard"
    @loadK
    selectObject: loadK.id
    @emlRunKruskalWallisAnalysis: loadK.id, "F0_Hz", "voice_type", 0, "holm"
    appendInfoLine: "===PARITY_BLOCK_START==="
    selectObject: loadK.id
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "wilcoxon", "bh"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif
if leg$ = "pw_wilcoxon_bh_menu"
    @loadK
    appendInfoLine: "===PARITY_BLOCK_START==="
    selectObject: loadK.id
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "wilcoxon", "bh"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif

# ---------------------------------------------------------------------------
# 4.4 correlation "Group column" — per-group report. Fixture has cohort
# A (n=4), B (n=3), C (n=1, too small to test). Wizard row: corrCol1$ = "x",
# corrCol2$ = "y", wizCorrGroupCol$ = "cohort", wizCorrTestType$ = "both"
# (exercises both the Pearson and Spearman per-group branches). Both legs
# call the identical sequence of engine procedures
# (emlCountGroups / eml_getGroupPairedData / emlPearsonCorrelation /
# emlSpearmanCorrelation / emlReportCorrelationAnalysis / emlTidy* /
# emlGlanceNum), copied VERBATIM from eml-wizard.praat's B_TEST_PAGE
# dispatch (wizard leg) and eml-correlate.praat's hasGroupCol branch
# (menu leg).
# ---------------------------------------------------------------------------
if leg$ = "corr_group_wizard"
    @loadCorrGroup
    tableName$ = "fixture_corr_group"
    corrCol1$ = "x"
    corrCol2$ = "y"
    wizCorrGroupCol$ = "cohort"
    wizCorrTestType$ = "both"
    wizCorrHasGroupCol = 1
    selectObject: loadCorrGroup.id
    @emlRunCorrelationAnalysis: loadCorrGroup.id, corrCol1$, corrCol2$, wizCorrTestType$

    selectObject: loadCorrGroup.id
    @emlCountGroups: loadCorrGroup.id, wizCorrGroupCol$
    wizPgTotal = emlCountGroups.nGroups
    wizPgRun = 0
    wizPgSkipped = 0
    wizPgSkipList$ = ""
    wizPgSkipMore = 0
    for wizPgI from 1 to wizPgTotal
        wizPgLabel$ [wizPgI] = emlCountGroups.groupLabel$ [wizPgI]
        selectObject: loadCorrGroup.id
        @eml_getGroupPairedData: loadCorrGroup.id, corrCol1$, corrCol2$,
        ... wizCorrGroupCol$, wizPgLabel$ [wizPgI]
        wizPgN [wizPgI] = eml_getGroupPairedData.n
        if wizPgN [wizPgI] >= 3
            wizPgRun = wizPgRun + 1
        else
            wizPgSkipped = wizPgSkipped + 1
            if length (wizPgSkipList$) < 45
                if wizPgSkipList$ <> ""
                    wizPgSkipList$ = wizPgSkipList$ + ", "
                endif
                wizPgSkipList$ = wizPgSkipList$
                ... + replace$ (wizPgLabel$ [wizPgI], "_", " ", 0)
            else
                wizPgSkipMore = wizPgSkipMore + 1
            endif
        endif
    endfor
    if wizPgSkipMore > 0
        wizPgSkipList$ = wizPgSkipList$ + ", and " + string$ (wizPgSkipMore) + " more"
    endif

    @emlUnderscoreToSpace: wizCorrGroupCol$
    wizPgColDisplay$ = emlUnderscoreToSpace.result$

    appendInfoLine: "===PARITY_BLOCK_START==="
    @emlReportHeader: "Correlation by " + wizPgColDisplay$
    @emlReportLineString: "Grouping column", wizPgColDisplay$
    @emlReportLine: "Groups", wizPgTotal, 0
    @emlReportLine: "Analysed", wizPgRun, 0

    wizPgCsvN = emlCSV_n
    @emlTidyClear
    @emlTidyRow: "(overall)"
    @emlTidyNum: "estimate", emlRunCorrelationAnalysis.pearR
    @emlTidyNum: "statistic", emlRunCorrelationAnalysis.pearT
    @emlTidyNum: "p.value", emlRunCorrelationAnalysis.pearP
    @emlTidyNum: "parameter", emlRunCorrelationAnalysis.pearDf
    @emlTidyStr: "method", "Pearson's product-moment correlation"
    @emlTidyStr: "alternative", "two.sided"
    @emlTidyRow: "(overall)"
    @emlTidyNum: "estimate", emlRunCorrelationAnalysis.spearRho
    @emlTidyNum: "statistic", emlRunCorrelationAnalysis.spearT
    @emlTidyNum: "p.value", emlRunCorrelationAnalysis.spearP
    @emlTidyNum: "parameter", emlRunCorrelationAnalysis.spearDf
    @emlTidyStr: "method", "Spearman's rank correlation rho"
    @emlTidyStr: "alternative", "two.sided"

    for wizPgI from 1 to wizPgTotal
        if wizPgN [wizPgI] >= 3
            wizPgDisplay$ = replace$ (wizPgLabel$ [wizPgI], "_", " ", 0)
            selectObject: loadCorrGroup.id
            @eml_getGroupPairedData: loadCorrGroup.id, corrCol1$, corrCol2$,
            ... wizCorrGroupCol$, wizPgLabel$ [wizPgI]
            wizPgX# = eml_getGroupPairedData.dataX#
            wizPgY# = eml_getGroupPairedData.dataY#
            wizPgThisN = eml_getGroupPairedData.n
            wizPgExcluded = eml_getGroupPairedData.nExcluded
            wizPgTerm$ = wizCorrGroupCol$ + " = " + wizPgLabel$ [wizPgI]
            @emlPearsonCorrelation: wizPgX#, wizPgY#, 2
            wizPgPearR = emlPearsonCorrelation.r
            wizPgPearT = emlPearsonCorrelation.t
            wizPgPearDf = emlPearsonCorrelation.df
            wizPgPearP = emlPearsonCorrelation.p
            wizPgPearErr$ = emlPearsonCorrelation.error$
            @emlSpearmanCorrelation: wizPgX#, wizPgY#, 2
            wizPgSpearRho = emlSpearmanCorrelation.rho
            wizPgSpearT = emlSpearmanCorrelation.t
            wizPgSpearDf = emlSpearmanCorrelation.df
            wizPgSpearP = emlSpearmanCorrelation.p
            wizPgSpearErr$ = emlSpearmanCorrelation.error$
            @emlReportCorrelationAnalysis: tableName$
            ... + " -- " + wizPgColDisplay$ + " = " + wizPgDisplay$,
            ... corrCol1$, corrCol2$, wizPgThisN, wizCorrTestType$
            if wizPgExcluded > 0
                appendInfoLine: "  Note: " + string$ (wizPgExcluded)
                ... + " row(s) excluded for missing data"
                ... + " (analyzed n = " + string$ (wizPgThisN)
                ... + " complete pairs)."
            endif
            if wizPgPearErr$ = ""
                @emlTidyRow: wizPgTerm$
                @emlTidyNum: "estimate", wizPgPearR
                @emlTidyNum: "statistic", wizPgPearT
                @emlTidyNum: "p.value", wizPgPearP
                @emlTidyNum: "parameter", wizPgPearDf
                @emlTidyStr: "method", "Pearson's product-moment correlation"
                @emlTidyStr: "alternative", "two.sided"
            endif
            if wizPgSpearErr$ = ""
                @emlTidyRow: wizPgTerm$
                @emlTidyNum: "estimate", wizPgSpearRho
                @emlTidyNum: "statistic", wizPgSpearT
                @emlTidyNum: "p.value", wizPgSpearP
                @emlTidyNum: "parameter", wizPgSpearDf
                @emlTidyStr: "method", "Spearman's rank correlation rho"
                @emlTidyStr: "alternative", "two.sided"
            endif
        endif
    endfor
    emlCSV_n = wizPgCsvN
    @emlGlanceNum: "n.groups", wizPgRun
    if wizPgSkipped > 0
        @emlReportBlank
        @emlReportLineString: "Skipped (n < 3)",
        ... string$ (wizPgSkipped) + " of " + string$ (wizPgTotal) + ": " + wizPgSkipList$
    endif
    appendInfoLine: emlReportHeader.border$
    appendInfoLine: "===PARITY_BLOCK_END==="
endif

if leg$ = "corr_group_menu"
    @loadCorrGroup
    tableName$ = "fixture_corr_group"
    colX$ = "x"
    colY$ = "y"
    groupCol$ = "cohort"
    testType$ = "both"
    hasGroupCol = 1
    selectObject: loadCorrGroup.id
    @emlRunCorrelationAnalysis: loadCorrGroup.id, colX$, colY$, testType$

    selectObject: loadCorrGroup.id
    @emlCountGroups: loadCorrGroup.id, groupCol$
    pgTotal = emlCountGroups.nGroups
    pgRun = 0
    pgSkipped = 0
    pgSkipList$ = ""
    pgSkipMore = 0
    for pgI from 1 to pgTotal
        pgLabel$ [pgI] = emlCountGroups.groupLabel$ [pgI]
        selectObject: loadCorrGroup.id
        @eml_getGroupPairedData: loadCorrGroup.id, colX$, colY$,
        ... groupCol$, pgLabel$ [pgI]
        pgN [pgI] = eml_getGroupPairedData.n
        if pgN [pgI] >= 3
            pgRun = pgRun + 1
        else
            pgSkipped = pgSkipped + 1
            if length (pgSkipList$) < 45
                if pgSkipList$ <> ""
                    pgSkipList$ = pgSkipList$ + ", "
                endif
                pgSkipList$ = pgSkipList$ + replace$ (pgLabel$ [pgI], "_", " ", 0)
            else
                pgSkipMore = pgSkipMore + 1
            endif
        endif
    endfor
    if pgSkipMore > 0
        pgSkipList$ = pgSkipList$ + ", and " + string$ (pgSkipMore) + " more"
    endif

    @emlUnderscoreToSpace: groupCol$
    pgColDisplay$ = emlUnderscoreToSpace.result$

    appendInfoLine: "===PARITY_BLOCK_START==="
    @emlReportHeader: "Correlation by " + pgColDisplay$
    @emlReportLineString: "Grouping column", pgColDisplay$
    @emlReportLine: "Groups", pgTotal, 0
    @emlReportLine: "Analysed", pgRun, 0

    pgCsvN = emlCSV_n
    @emlTidyClear
    @emlTidyRow: "(overall)"
    @emlTidyNum: "estimate", emlRunCorrelationAnalysis.pearR
    @emlTidyNum: "statistic", emlRunCorrelationAnalysis.pearT
    @emlTidyNum: "p.value", emlRunCorrelationAnalysis.pearP
    @emlTidyNum: "parameter", emlRunCorrelationAnalysis.pearDf
    @emlTidyStr: "method", "Pearson's product-moment correlation"
    @emlTidyStr: "alternative", "two.sided"
    @emlTidyRow: "(overall)"
    @emlTidyNum: "estimate", emlRunCorrelationAnalysis.spearRho
    @emlTidyNum: "statistic", emlRunCorrelationAnalysis.spearT
    @emlTidyNum: "p.value", emlRunCorrelationAnalysis.spearP
    @emlTidyNum: "parameter", emlRunCorrelationAnalysis.spearDf
    @emlTidyStr: "method", "Spearman's rank correlation rho"
    @emlTidyStr: "alternative", "two.sided"

    for pgI from 1 to pgTotal
        if pgN [pgI] >= 3
            pgDisplay$ = replace$ (pgLabel$ [pgI], "_", " ", 0)
            selectObject: loadCorrGroup.id
            @eml_getGroupPairedData: loadCorrGroup.id, colX$, colY$,
            ... groupCol$, pgLabel$ [pgI]
            pgX# = eml_getGroupPairedData.dataX#
            pgY# = eml_getGroupPairedData.dataY#
            pgThisN = eml_getGroupPairedData.n
            pgExcluded = eml_getGroupPairedData.nExcluded
            pgTerm$ = groupCol$ + " = " + pgLabel$ [pgI]
            @emlPearsonCorrelation: pgX#, pgY#, 2
            pgPearR = emlPearsonCorrelation.r
            pgPearT = emlPearsonCorrelation.t
            pgPearDf = emlPearsonCorrelation.df
            pgPearP = emlPearsonCorrelation.p
            pgPearErr$ = emlPearsonCorrelation.error$
            @emlSpearmanCorrelation: pgX#, pgY#, 2
            pgSpearRho = emlSpearmanCorrelation.rho
            pgSpearT = emlSpearmanCorrelation.t
            pgSpearDf = emlSpearmanCorrelation.df
            pgSpearP = emlSpearmanCorrelation.p
            pgSpearErr$ = emlSpearmanCorrelation.error$
            @emlReportCorrelationAnalysis: tableName$
            ... + " -- " + pgColDisplay$ + " = " + pgDisplay$,
            ... colX$, colY$, pgThisN, testType$
            if pgExcluded > 0
                appendInfoLine: "  Note: " + string$ (pgExcluded)
                ... + " row(s) excluded for missing data"
                ... + " (analyzed n = " + string$ (pgThisN)
                ... + " complete pairs)."
            endif
            if pgPearErr$ = ""
                @emlTidyRow: pgTerm$
                @emlTidyNum: "estimate", pgPearR
                @emlTidyNum: "statistic", pgPearT
                @emlTidyNum: "p.value", pgPearP
                @emlTidyNum: "parameter", pgPearDf
                @emlTidyStr: "method", "Pearson's product-moment correlation"
                @emlTidyStr: "alternative", "two.sided"
            endif
            if pgSpearErr$ = ""
                @emlTidyRow: pgTerm$
                @emlTidyNum: "estimate", pgSpearRho
                @emlTidyNum: "statistic", pgSpearT
                @emlTidyNum: "p.value", pgSpearP
                @emlTidyNum: "parameter", pgSpearDf
                @emlTidyStr: "method", "Spearman's rank correlation rho"
                @emlTidyStr: "alternative", "two.sided"
            endif
        endif
    endfor
    emlCSV_n = pgCsvN
    @emlGlanceNum: "n.groups", pgRun
    if pgSkipped > 0
        @emlReportBlank
        @emlReportLineString: "Skipped (n < 3)",
        ... string$ (pgSkipped) + " of " + string$ (pgTotal) + ": " + pgSkipList$
    endif
    appendInfoLine: emlReportHeader.border$
    appendInfoLine: "===PARITY_BLOCK_END==="
endif

# ---------------------------------------------------------------------------
# 4.6 normality "All numeric columns" mode. Wizard: loops
# @emlRunNormalityAnalysis over every numeric column with testType$ = "both"
# (eml-wizard.praat C_NORM_ALL). Menu sibling: eml-check-normality.praat's
# own ungrouped branch makes the identical call for the identical reason.
# ---------------------------------------------------------------------------
if leg$ = "norm_all_wizard" or leg$ = "norm_all_menu"
    @loadNormality
    selectObject: loadNormality.id
    nRows = Get number of rows
    numericCol$ [1] = "F0_Hz"
    numericCol$ [2] = "jitter_pct"
    for iSel from 1 to 2
        selectObject: loadNormality.id
        @emlRunNormalityAnalysis: loadNormality.id, numericCol$ [iSel], "both"
    endfor
endif

# ---------------------------------------------------------------------------
# 4.6 normality "One column, by group" mode. Fixture cohort A (n=4), B
# (n=3), C (n=1, too small). Wizard: eml-wizard.praat's C_NORM_GROUP block,
# copied verbatim below. Menu sibling: eml-check-normality.praat's own
# grouped branch, copied verbatim below. Both call the identical sequence
# (emlCountGroups / eml_getGroupData / emlShapiroWilk / emlSkewness /
# emlKurtosis / emlNormalityRecommendation / eml_fixed / emlFormatP).
# ---------------------------------------------------------------------------

procedure normGroupBlock: .prefix$, .tableId, .dataCol$, .groupCol$
    # ONE PROCEDURE, TWO CALL SITES BELOW — not because the two doors share
    # code (they do not; eml-wizard.praat's C_NORM_GROUP and
    # eml-check-normality.praat's grouped branch are separate, independently
    # written blocks), but so THIS FILE does not carry the same fifty lines
    # twice with the drift risk that implies. What is asserted is that this
    # procedure IS the sequence both sources call, in the order they call
    # it — read against eml-wizard.praat and eml-check-normality.praat
    # directly, not inferred from this file matching itself.
    appendInfoLine: "  Grouped by: ", replace$ (.groupCol$, "_", " ", 0)
    appendInfoLine: "── ", replace$ (.dataCol$, "_", " ", 0), " ──"
    appendInfoLine: ""
    selectObject: .tableId
    @emlCountGroups: .tableId, .groupCol$
    .allOK = 1
    .nAssessed = 0
    for .iGroup from 1 to emlCountGroups.nGroups
        .gLabel$ = emlCountGroups.groupLabel$ [.iGroup]
        .gDisplay$ = replace$ (.gLabel$, "_", " ", 0)
        selectObject: .tableId
        @eml_getGroupData: .tableId, .dataCol$, .groupCol$, .gLabel$
        if eml_getGroupData.n >= 3
            .nAssessed = .nAssessed + 1
            .data# = eml_getGroupData.data#
            .n = eml_getGroupData.n
            @emlShapiroWilk: .data#
            .swW = emlShapiroWilk.w
            .swP = emlShapiroWilk.p
            @emlSkewness: .data#
            .skew = emlSkewness.result
            @emlKurtosis: .data#
            .kurt = emlKurtosis.result
            @emlNormalityRecommendation: .skew, .kurt, .n,
            ... emlShapiroWilk.p, emlShapiroWilk.error$
            .largeNOverride = emlNormalityRecommendation.largeNOverride
            .rec$ = emlNormalityRecommendation.recommendation$
            .nonparam = 0
            if .rec$ = "nonparametric"
                .nonparam = 1
            endif
            @eml_fixed: .swW, 4
            .wTxt$ = eml_fixed.result$
            @eml_fixed: .skew, 3
            .skewTxt$ = eml_fixed.result$
            @eml_fixed: .kurt, 3
            .kurtTxt$ = eml_fixed.result$
            @emlFormatP: .swP
            appendInfoLine: "  ", .gDisplay$, " (n = ", .n, "):"
            appendInfoLine: "    W = ", .wTxt$, "  ", emlFormatP.formatted$
            appendInfoLine: "    Skewness = ", .skewTxt$,
            ... "  Kurtosis (excess) = ", .kurtTxt$
            @eml_fixed: emlSkewThreshold, 0
            .skewLimit$ = eml_fixed.result$
            @eml_fixed: emlKurtosisThreshold, 0
            .kurtLimit$ = eml_fixed.result$
            .criteria$ = "thresholds: Shapiro-Wilk p < .05, |skew| >= "
            ... + .skewLimit$ + ", |excess kurt| >= " + .kurtLimit$
            if .largeNOverride
                appendInfoLine: "    -> large-n override (", .criteria$, ")"
            elsif .nonparam
                appendInfoLine: "    -> Strong departure (", .criteria$, ")"
                .allOK = 0
            else
                appendInfoLine: "    -> No strong departure (", .criteria$, ")"
            endif
        else
            appendInfoLine: "  ", .gDisplay$, " (n = ", eml_getGroupData.n,
            ... "): skipped (n < 3)"
        endif
    endfor
    appendInfoLine: ""
    if .allOK
        if .nAssessed < emlCountGroups.nGroups
            appendInfoLine: "  Summary: assessed ", .nAssessed, " of ",
            ... emlCountGroups.nGroups, "."
        else
            appendInfoLine: "  Summary: no strong departure"
        endif
    else
        appendInfoLine: "  Summary: one or more groups depart"
    endif
endproc

if leg$ = "norm_group_wizard"
    @loadNormality
    appendInfoLine: "===PARITY_BLOCK_START==="
    @normGroupBlock: "wiz", loadNormality.id, "F0_Hz", "cohort"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif
if leg$ = "norm_group_menu"
    @loadNormality
    appendInfoLine: "===PARITY_BLOCK_START==="
    @normGroupBlock: "menu", loadNormality.id, "F0_Hz", "cohort"
    appendInfoLine: "===PARITY_BLOCK_END==="
endif

appendInfoLine: "== END ", leg$, " =="
