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

displayColumn$ = replace$ (dataColumn$, "_", " ", 0)
displayTable$ = replace$ (tableName$, "_", " ", 0)

@emlReportHeader: "Descriptive Statistics"

@emlReportLineString: "Table", displayTable$
@emlReportLineString: "Column", displayColumn$
@emlReportLine: "N (valid)", emlDescribe.n, 0
if nUndefined > 0
    @emlReportLine: "N (undefined)", nUndefined, 0
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
