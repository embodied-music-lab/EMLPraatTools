# ============================================================================
# EML Praat Tools — Compare k Groups (ANOVA)
# ============================================================================
# Purpose: One-way ANOVA with optional Tukey HSD post-hoc comparisons.
# Date: 11 May 2026
# Version: 3.0
# v3.0: Full convergence — @emlRunAnovaAnalysis orchestrator,
#        @emlWrapperInit, @emlWrapperExportCSV, @emlWrapperCommonFields,
#        @emlGuessColumnRoles. repeat/until replaces goto/label.
# v1.7: Step 6 wiring — inline draw replaced with @emlGraphsWorkflow.
# v1.6: Two-loop architecture. Shared @emlReportAnovaComparison. CSV.
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

@emlWrapperInit: 2
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
guessDataIdx = emlWrapperInit.guessDataIdx
guessGroupIdx = emlWrapperInit.guessGroupIdx

allDone = 0
repeat
    beginPause: "Compare k Groups (ANOVA)"
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
        boolean: "Tukey HSD post hoc", 1
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
    doTukey = tukey_HSD_post_hoc

    if group_order = 2
        emlGroupSortAlphabetical = 1
    else
        emlGroupSortAlphabetical = 0
    endif
    @emlHandleCommonFields

    selectObject: tableId
    @emlRunAnovaAnalysis: tableId, dataCol$, groupCol$, doTukey
    if emlRunAnovaAnalysis.error$ <> ""
        pauseScript: emlRunAnovaAnalysis.error$
    else
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
                emlGraphsPresetType = 7
                emlGraphsPresetDataCol$ = dataCol$
                emlGraphsPresetGroupCol$ = groupCol$
                emlGraphsPresetTestType$ = "parametric"
                emlGraphsPresetAnnotate = 1
                @emlGraphsWorkflow: tableId
            elsif clicked = 4
                runAgain = 1
            endif
        until allDone or runAgain
    endif
    endif
until allDone
