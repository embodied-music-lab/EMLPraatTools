# ============================================================================
# EML Praat Tools — Compare K Groups (Kruskal-Wallis)
# ============================================================================
# Purpose: Compare 3+ groups using Kruskal-Wallis H test with Dunn's
#          post-hoc and rank-biserial r effect sizes.
# Date: 11 May 2026
# Version: 3.1
# v3.1: D26 — the post-hoc is now under the user's control. "Run Dunn post
#        hoc" and "Adjustment" fields replace the hardcoded 1, "holm"
#        arguments to @emlRunKWAnalysis, matching the ANOVA sibling's
#        "Tukey HSD post hoc" control. The chosen adjustment is also carried
#        into the graph annotation so Draw cannot silently disagree with the
#        report.
# v3.0: Wrapper infrastructure refactor. Shared @emlWrapperInit,
#        @emlWrapperExportCSV. repeat/until replaces goto/label.
# v2.0: Full convergence — orchestrator + @emlGuessColumnRoles.
# ============================================================================

include eml-lib.praat

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
selGroupOrder = 1
selDunn = 1
selAdj = 2

allDone = 0
repeat
    beginPause: "Compare K Groups (Kruskal-Wallis)"
        comment: "Table: " + tableName$
        optionmenu: "Data column", guessDataIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Group column", guessGroupIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        boolean: "Run Dunn post hoc", selDunn
        optionmenu: "Adjustment (post hoc only)", selAdj
            option: "Bonferroni"
            option: "Holm"
            option: "Benjamini-Hochberg"
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
    # Carry the answers forward so a return to this form shows them. (D93)
    @emlKeepChoice: dataCol$, guessDataIdx
    guessDataIdx = emlKeepChoice.idx
    @emlKeepChoice: groupCol$, guessGroupIdx
    guessGroupIdx = emlKeepChoice.idx
    doDunn = run_Dunn_post_hoc
    adjChoice = adjustment
    selDunn = doDunn
    selAdj = adjChoice
    selGroupOrder = group_order
    if adjChoice = 1
        adjMethod$ = "bonferroni"
    elsif adjChoice = 2
        adjMethod$ = "holm"
    else
        adjMethod$ = "bh"
    endif
    if group_order = 2
        emlGroupSortAlphabetical = 1
    else
        emlGroupSortAlphabetical = 0
    endif
    @emlHandleCommonFields

    selectObject: tableId
    @emlRunKWAnalysis: tableId, dataCol$, groupCol$, doDunn, adjMethod$
    if emlRunKWAnalysis.error$ <> ""
        # D93: an error must not strand the user on a form the error has
        # just ruled out. Present it with guidance, and honour Quit.
        @emlErrorDialog: emlRunKWAnalysis.error$, emlRunKWAnalysis.remedy$, "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    else
        runAgain = 0
        repeat
            beginPause: "Analysis Complete"
                comment: "Results are in the Info window."
            clicked = endPause: "Done", "CSV", "Draw", "New", 3, 0

            if clicked = 1
                allDone = 1
            elsif clicked = 2
                @emlWrapperExportCSV: tableName$, "Kruskal-Wallis"
            elsif clicked = 3
                emlGraphsPresetType = 7
                emlGraphsPresetDataCol$ = dataCol$
                emlGraphsPresetGroupCol$ = groupCol$
                emlGraphsPresetTestType$ = "nonparametric"
                emlGraphsPresetAnnotate = 1
                ; Carry the dialog's adjustment into the annotation so the
                ; figure cannot report a correction the analysis did not use.
                emlGraphsPresetCorrection$ = adjMethod$
                @emlGraphsWorkflow: tableId
            elsif clicked = 4
                runAgain = 1
            endif
        until allDone or runAgain
    endif
    endif
until allDone
