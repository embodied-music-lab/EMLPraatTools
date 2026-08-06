# ============================================================================
# EML Praat Tools — Describe Table Column
# ============================================================================
# Purpose: Descriptive statistics for one numeric column of a Table.
#          Reports n, mean, SD, SEM, median, Q1/Q3/IQR, range,
#          skewness, kurtosis, and 95% CI via the Info window.
# Date: 16 March 2026
# Version: 1.0
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: [Your name here] — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Acoustic analysis scripts were developed using the EML Praat
#    Assistant (Howell, Embodied Music Lab) with code generation
#    by Claude (Anthropic). All scripts were reviewed, tested,
#    and validated by [your name]."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
include ../stats/eml-output.praat
include ../stats/eml-inferential.praat

# ── Check that a Table is selected ──────────────────────────────────────────

nTables = numberOfSelected ("Table")
if nTables <> 1
    exitScript: "Please select exactly one Table object, then run this script again."
endif
tableId = selected ("Table")
tableName$ = selected$ ("Table")

# ── Read column names (numeric only) ────────────────────────────────────────

@emlTableColumnNames: tableId
nCols = emlTableColumnNames.nCols
if nCols = 0
    exitScript: "The selected Table has no columns."
endif

# Filter to numeric columns only (check first non-empty row)
selectObject: tableId
nRows = Get number of rows
nNumericCols = 0
for iCol from 1 to nCols
    .colName$ = emlTableColumnNames.name$ [iCol]
    .isNumeric = 0
    for iRow from 1 to min (nRows, 5)
        .val$ = Get value: iRow, .colName$
        if .val$ <> "" and .val$ <> "--undefined--"
            if number (.val$) <> undefined
                .isNumeric = 1
            endif
            iRow = nRows + 1
        endif
    endfor
    if .isNumeric
        nNumericCols = nNumericCols + 1
        numericCol$ [nNumericCols] = .colName$
    endif
endfor

if nNumericCols = 0
    exitScript: "No numeric columns found in the selected Table."
endif

# ── Present column choice ──────────────────────────────────────────────────

beginPause: "Describe Table Column"
    comment: "📋 Table: " + tableName$
        comment: "─────────────────────────────────────"
    optionmenu: "Column", 1
    for iCol from 1 to nNumericCols
        option: numericCol$ [iCol]
    endfor
clicked = endPause: "Quit", "Run", 2, 0
if clicked = 1
    exitScript: ""
endif

dataColumn$ = column$

# ── Validate column ─────────────────────────────────────────────────────────

selectObject: tableId
@emlExtractColumn: tableId, dataColumn$
if emlExtractColumn.error$ <> ""
    exitScript: emlExtractColumn.error$
endif
data# = emlExtractColumn.data#
nValid = emlExtractColumn.n
nUndefined = emlExtractColumn.nUndefined

if nValid < 1
    exitScript: "Column """ + dataColumn$ + """ contains no valid numeric values."
endif

# ── Compute descriptive statistics ──────────────────────────────────────────

@emlDescribe: data#

# ── Format report ───────────────────────────────────────────────────────────

# The report body lived here as a second copy of
# @emlReportDescriptiveAnalysis, line for line. Two copies of a report is
# two places for a label to drift, and the D96 work needed a change in
# both. Call the procedure instead; it is the same output.

@emlReportDescriptiveAnalysis: tableName$, dataColumn$, emlDescribe.n,
... nUndefined, emlExtractColumn.note$
