# ============================================================================
# EML Praat Tools — Compare k Groups (ANOVA)
# ============================================================================
# Purpose: One-way ANOVA with optional Tukey HSD post-hoc comparisons.
# Date: 11 May 2026
# Version: 3.0
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

@emlWrapperInit: 2
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
guessDataIdx = emlWrapperInit.guessDataIdx
guessGroupIdx = emlWrapperInit.guessGroupIdx

# Seeds for the entry form. Initialised from the column-role guess, then
# overwritten with the user's own answers each time round the loop. Before
# The fix these were re-read from the guess on every iteration, so any
# return to the form — after an error or after "New" — silently discarded
# What the user had set.
selTukey = 1
selGroupOrder = 1

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
        boolean: "Tukey HSD post hoc", selTukey
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
    doTukey = tukey_HSD_post_hoc
    # Carry the answers forward so a return to this form shows them.
    @emlKeepChoice: dataCol$, guessDataIdx
    guessDataIdx = emlKeepChoice.idx
    @emlKeepChoice: groupCol$, guessGroupIdx
    guessGroupIdx = emlKeepChoice.idx
    selTukey = doTukey
    selGroupOrder = group_order

    if group_order = 2
        emlGroupSortAlphabetical = 1
    else
        emlGroupSortAlphabetical = 0
    endif
    @emlHandleCommonFields

    selectObject: tableId
    @emlRunAnovaAnalysis: tableId, dataCol$, groupCol$, doTukey
    if emlRunAnovaAnalysis.error$ <> ""
        # An error must not strand the user on a form the error has
        # just ruled out. Present it with guidance, and honour Quit.
        @emlErrorDialog: emlRunAnovaAnalysis.error$, emlRunAnovaAnalysis.remedy$, "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    else
        runAgain = 0
        repeat
            beginPause: "Analysis complete"
                comment: "📊 Results are in the Info window."
            clicked = endPause: "Done", "Save", "Draw", "New", 3, 0

            if clicked = 1
                allDone = 1
            elsif clicked = 2
                # ONE PANEL FOR EVERY OUTPUT. This was @emlWrapperExportCSV,
                # which wrote only the numbers and remembered its own folder.
                # @emlSavePanel offers the results AND the Info window report
                # under one folder and one stem. 0 = there is no figure here;
                # nothing has been drawn at the end of an analysis.
                @emlSavePanel: 0, tableName$ + "_ANOVA",
                ... emlLastCSVFolder$
                if emlSavePanel.cancelled = 0
                    emlLastCSVFolder$ = emlSavePanel.folder$
                endif
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
