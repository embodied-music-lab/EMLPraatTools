# ============================================================================
# EML Praat Tools — Compare Two Factors (Two-Way ANOVA)
# ============================================================================
# Purpose: Two-way ANOVA for a Table with two categorical factors and one
#          numeric dependent variable. Reports main effects, interaction,
#          and partial eta-squared.
# Date: 11 May 2026
# Version: 2.1
# v2.1: D32 — the Draw preset now carries the SECOND factor
#        (emlGraphsPresetSubgroupCol$ = factor2$). Without it the default
#        grouped violin dropped factor 2 entirely and the Column Mapping
#        dialog opened with Category and Subgroup pointing at the same column.
# v2.0: Full convergence — @emlRunTwoWayAnalysis orchestrator,
#        @emlWrapperInit, @emlWrapperExportCSV, @emlWrapperCommonFields,
#        @emlGuessColumnRoles. Inline draw replaced with @emlGraphsWorkflow
#        (grouped violin preset). repeat/until replaces goto/label.
# v1.0: Initial release with inline draw and direct procedure calls.
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

@emlWrapperInit: 3
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols
guessDataIdx = emlWrapperInit.guessDataIdx
guessGroupIdx = emlWrapperInit.guessGroupIdx

# For two-way, guess second factor as next column after group
guessFactor2Idx = min (guessGroupIdx + 1, nCols)
if guessFactor2Idx = guessDataIdx
    guessFactor2Idx = min (guessFactor2Idx + 1, nCols)
endif

# Every field on this form is a column menu, so the three guess indices below
# are the whole of its state. They are overwritten with the user's own
# answers after each run: before the D93 fix a return to this form reseeded
# from the original guesses and silently discarded what the user had set.

allDone = 0
repeat
    beginPause: "Two-Way ANOVA"
        comment: "📋 Table: " + tableName$
        comment: "─────────────────────────────────────"
        optionmenu: "Data column", guessDataIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Factor 1", guessGroupIdx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        optionmenu: "Factor 2", guessFactor2Idx
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$ [iCol]
        endfor
        @emlWrapperCommonFields
    clicked = endPause: "Quit", "Run", 2, 0
    if clicked = 1
        allDone = 1
    endif

    if not allDone

    dataCol$ = data_column$
    factor1$ = factor_1$
    factor2$ = factor_2$
    # Carry the answers forward so a return to this form shows them. (D93)
    @emlKeepChoice: dataCol$, guessDataIdx
    guessDataIdx = emlKeepChoice.idx
    @emlKeepChoice: factor1$, guessGroupIdx
    guessGroupIdx = emlKeepChoice.idx
    @emlKeepChoice: factor2$, guessFactor2Idx
    guessFactor2Idx = emlKeepChoice.idx
    @emlHandleCommonFields

    if factor1$ = factor2$
        # D93: uniform error surface; Quit must actually quit.
        @emlErrorDialog: "Please select two different factor columns.", "", "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    elsif dataCol$ = factor1$ or dataCol$ = factor2$
        # D93: uniform error surface; Quit must actually quit.
        @emlErrorDialog: "Data column cannot be the same as a factor column.", "", "menu"
        if not emlErrorDialog.back
            allDone = 1
        endif
    else
        selectObject: tableId
        @emlRunTwoWayAnalysis: tableId, dataCol$, factor1$, factor2$
        if emlRunTwoWayAnalysis.error$ <> ""
            # D93: an error must not strand the user on a form the error has
            # just ruled out. Present it with guidance, and honour Quit.
            @emlErrorDialog: emlRunTwoWayAnalysis.error$, emlRunTwoWayAnalysis.remedy$, "menu"
            if not emlErrorDialog.back
                allDone = 1
            endif
        else
            runAgain = 0
            repeat
                beginPause: "Analysis complete"
                    comment: "📊 Results are in the Info window."
                clicked = endPause: "Done", "CSV", "Draw", "New", 3, 0

                if clicked = 1
                    allDone = 1
                elsif clicked = 2
                    @emlWrapperExportCSV: tableName$, "two-way ANOVA"
                elsif clicked = 3
                    # Grouped violin: factor 1 is the category, factor 2 the
                    # subgroup.
                    #
                    # D32. The wrapper used to hand over factor1 and the data
                    # column only. factor2 — half of the design, and on the
                    # demo table the factor with the LARGER effect — reached
                    # the graph layer nowhere, so the Column Mapping dialog
                    # kept its initialiser (min (2, nCols)) for Subgroup and
                    # the default figure came out as a single-factor plot with
                    # the second factor silently dropped.
                    emlGraphsPresetType = 11
                    emlGraphsPresetGroupCol$ = factor1$
                    emlGraphsPresetDataCol$ = dataCol$
                    # Consumed by the Grouped Violin preset branch in
                    # graphs/eml-graphs-form.praat once its subgroup preset
                    # lands; setting it here is inert until then, and binds
                    # with no further change to this file when it does.
                    emlGraphsPresetSubgroupCol$ = factor2$
                    @emlGraphsWorkflow: tableId
                elsif clicked = 4
                    runAgain = 1
                endif
            until allDone or runAgain
        endif
    endif
    endif
until allDone
