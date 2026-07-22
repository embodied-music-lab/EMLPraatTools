# ============================================================================
# EML Praat Tools — Compare Two Groups
# ============================================================================
# Purpose: Compare two independent groups from a Table using parametric
#          (Welch/Student t) and/or nonparametric (Mann-Whitney U) tests,
#          with corresponding effect sizes (Cohen's d / rank-biserial r).
# Date: 11 May 2026
# Version: 3.0
# v3.0: Wrapper infrastructure refactor. Shared @emlWrapperInit,
#        @emlWrapperExportCSV. repeat/until replaces goto/label.
# v2.0: Full convergence — analysis via @emlRunTwoGroupAnalysis orchestrator.
# v1.6: Step 6 wiring — inline draw replaced with @emlGraphsWorkflow.
# v1.5: Two-loop architecture. Shared @emlReportTwoGroupComparison. CSV.
#
# ATTRIBUTION
# Framework: EML Praat Tools by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: [Your name here] — created and verified by this individual
# ============================================================================

include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
include ../stats/eml-output.praat
include ../stats/eml-inferential.praat
include ../stats/eml-analysis.praat
include ../graphs/eml-graph-procedures.praat
include ../graphs/eml-annotation-procedures.praat
include ../graphs/eml-draw-procedures.praat
include ../graphs/eml-graphs-form.praat

# ── Init ────────────────────────────────────────────────────────────────────

@emlWrapperInit: 2
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
guessDataIdx = emlWrapperInit.guessDataIdx
guessGroupIdx = emlWrapperInit.guessGroupIdx

# ── Main loop ───────────────────────────────────────────────────────────────

allDone = 0
repeat

    # ── Dialog ──────────────────────────────────────────────────────────────

    beginPause: "Compare Two Groups"
        comment: "📋 Table: " + tableName$
        comment: "─────────────────────────────────────"
        optionmenu: "Data column", guessDataIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Group column", guessGroupIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Test", 1
            option: "Welch t-test"
            option: "Student t-test"
            option: "Mann-Whitney U"
            option: "Both parametric and nonparametric"
        optionmenu: "Group order", 1
            option: "Table order"
            option: "Alphabetical"
        @emlWrapperCommonFields
    clicked = endPause: "Quit", "Run", 2, 0
    if clicked = 1
        allDone = 1
    endif

    if not allDone

    dataCol$ = data_column$
    groupCol$ = group_column$
    testChoice = test

    if group_order = 2
        emlGroupSortAlphabetical = 1
    else
        emlGroupSortAlphabetical = 0
    endif

    @emlHandleCommonFields

    # ── Derive orchestrator parameters ──────────────────────────────────────

    if testChoice = 1 or testChoice = 2
        testType$ = "parametric"
    elsif testChoice = 3
        testType$ = "nonparametric"
    else
        testType$ = "both"
    endif

    if testChoice = 2
        equalVar = 1
    else
        equalVar = 0
    endif

    # ── Run analysis ────────────────────────────────────────────────────────

    selectObject: tableId
    @emlRunTwoGroupAnalysis: tableId, dataCol$, groupCol$, testType$, equalVar
    if emlRunTwoGroupAnalysis.error$ <> ""
        pauseScript: emlRunTwoGroupAnalysis.error$
    else

        # ── Post-analysis loop ──────────────────────────────────────────────

        runAgain = 0
        repeat
            beginPause: "Analysis complete"
                comment: "📊 Results are in the Info window."
            clicked = endPause: "Done", "CSV", "Draw", "New", 3, 0

            if clicked = 1
                allDone = 1
            elsif clicked = 2
                @emlWrapperExportCSV: tableName$
            elsif clicked = 3
                if testChoice = 3
                    presetTestType$ = "nonparametric"
                else
                    presetTestType$ = "parametric"
                endif
                emlGraphsPresetType = 7
                emlGraphsPresetDataCol$ = dataCol$
                emlGraphsPresetGroupCol$ = groupCol$
                emlGraphsPresetTestType$ = presetTestType$
                emlGraphsPresetAnnotate = 1
                @emlGraphsWorkflow: tableId
            elsif clicked = 4
                runAgain = 1
            endif
        until allDone or runAgain
    endif
    endif
until allDone
