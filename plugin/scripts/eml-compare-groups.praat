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

include eml-lib.praat

# ── Init ────────────────────────────────────────────────────────────────────

@emlWrapperInit: 2
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
guessDataIdx = emlWrapperInit.guessDataIdx
guessGroupIdx = emlWrapperInit.guessGroupIdx

# Seeds for the entry form. Initialised from the column-role guess, then
# overwritten with the user's own answers each time round the loop. Before
# the D93 fix these were re-read from the guess on every iteration, so any
# return to the form — after an error or after "New" — silently discarded
# what the user had set. (D93)
selTest = 1
selGroupOrder = 1

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
        optionmenu: "Test", selTest
            option: "Welch t-test"
            option: "Student t-test"
            option: "Mann-Whitney U"
            option: "Both parametric and nonparametric"
        optionmenu: "Group order", selGroupOrder
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

    # Carry the answers forward so a return to this form shows them. (D93)
    @emlKeepChoice: dataCol$, guessDataIdx
    guessDataIdx = emlKeepChoice.idx
    @emlKeepChoice: groupCol$, guessGroupIdx
    guessGroupIdx = emlKeepChoice.idx
    selTest = testChoice
    selGroupOrder = group_order

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
        # D93: an error must not strand the user on a form the error has
        # just ruled out. Present it with guidance, and honour Quit.
        @emlErrorDialog: emlRunTwoGroupAnalysis.error$, emlRunTwoGroupAnalysis.remedy$, "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
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
                @emlWrapperExportCSV: tableName$, "two-group"
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
