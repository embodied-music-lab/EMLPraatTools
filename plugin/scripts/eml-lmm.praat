# ============================================================================
# EML Praat Tools — Linear Mixed Model
# ============================================================================
# Purpose: Fit a linear mixed-effects model (lme4-style formula) to a Table
#          and report fixed effects (with Satterthwaite df), random-effect
#          variance components, marginal/conditional R-squared, and optional
#          95% Wald confidence intervals. Wraps the verified EML LMM engine.
# Date: 22 July 2026
# Version: 1.0
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Script author: [Your name here] — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use per your
# target journal's policy. The mixed-model engine reproduces lme4/lmerTest to
# 5-6 decimals and R-squared matches performance::r2_nakagawa; all scripts
# were reviewed, tested, and validated by [your name].
# ============================================================================

include eml-lib-lmm.praat

@emlWrapperInit: 2
tableId = emlWrapperInit.tableId
tableName$ = emlWrapperInit.tableName$
nCols = emlWrapperInit.nCols

# Build a column-name hint so the user knows what to type in the formula.
colHint$ = ""
for iCol from 1 to nCols
    if iCol > 1
        colHint$ = colHint$ + ", "
    endif
    colHint$ = colHint$ + emlTableColumnNames.name$ [iCol]
endfor

allDone = 0
repeat
    beginPause: "Linear Mixed Model"
        comment: "Table: " + tableName$
        comment: "Columns: " + colHint$
        comment: "lme4-style formula, e.g.  y ~ x + (1 + x | group)"
        comment: "Random effects go in parentheses: (1 | group) = random intercept."
        sentence: "Formula", "y ~ x + (1 | group)"
        optionmenu: "Contrast coding", 1
            option: "treatment"
            option: "sum"
            option: "helmert"
            option: "poly"
        boolean: "Use REML", 1
        boolean: "Report R squared", 1
        boolean: "Report confidence intervals", 1
        boolean: "Clear Info window", 1
    clicked = endPause: "Quit", "Run", 2, 0
    if clicked = 1
        allDone = 1
    endif

    if not allDone
        if clear_Info_window
            @emlClearInfo
        endif

        selectObject: tableId
        @emlRunLMMAnalysis: tableId, formula$, contrast_coding$, use_REML,
        ... report_R_squared, report_confidence_intervals
        if emlRunLMMAnalysis.error$ <> ""
            # D93: an error must not strand the user on a form the error has
            # just ruled out. Present it with guidance, and honour Quit.
            @emlErrorDialog: emlRunLMMAnalysis.error$, emlRunLMMAnalysis.remedy$, "menu"
            if not emlErrorDialog.back
                allDone = 1
            endif
        else
            runAgain = 0
            repeat
                beginPause: "LMM Complete"
                    comment: "Results are in the Info window."
                    comment: "Coefficient plot draws the fixed effects with 95% CIs."
                clicked = endPause: "Done", "Coefficient plot", "New model", 3, 0
                if clicked = 1
                    allDone = 1
                elsif clicked = 2
                    @emlWaldCI: 0.95
                    @emlDrawLMMForest
                elsif clicked = 3
                    runAgain = 1
                endif
            until allDone or runAgain
        endif
    endif
until allDone
