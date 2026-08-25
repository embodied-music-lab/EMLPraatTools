# ============================================================================
# v124 — Describe Table's column sniff scans every row, complete-case
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Punch list 7.3. scripts/eml-describe-table.praat used to judge a column
# numeric by its FIRST non-missing cell among the first FIVE rows only, then
# stop looking — exactly the violation @emlCheckNumericColumn's own header
# warns against ("SAMPLING IS NOT ENOUGH"). The filter now runs through
# @emlDescribeFilterNumericColumns, which reads every row of every column
# via @emlCheckNumericColumn, the plugin's one reader of "numeric".
#
# harness/describesniff drives that exact procedure (headless, no dialog) on
# a 12-row table with four columns:
#   late_numeric  rows 1-5 missing (blank AND Praat's native missing cell),
#                 rows 6-12 clean numbers. The old sniff never found a
#                 non-missing cell in its 5-row window: NEVER offered.
#   early_only    rows 1-5 clean numbers, row 8 text. The old sniff judged
#                 it numeric from row 1 alone and never looked further:
#                 WRONGLY offered.
#   all_missing   every row missing. The negative control — neither sniff
#                 should offer this one.
#   label         ordinary text throughout. Never offered either way.
#
# A correct filter offers exactly late_numeric.
#
# DRIVEN 25 August 2026:
#   bash harness/describesniff/run.sh
#
# Output: evidence/info/v124_describesniff_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

cap <- capture("v124_describesniff_info.txt")

check_true("v124", "capture reached its end marker",
           any(grepl("^V124DESCRIBESNIFF DONE$", cap$lines)))

offered <- trimws(sub("^offered[0-9]+\\s+", "",
                       grep("^offered[0-9]+", trimws(cap$lines), value = TRUE)))

# Exactly one column offered, and it is the one whose numeric data was
# scanned into after the missing first five rows — the symptom this item
# names by name: "a column whose first rows are missing is never offered."
check("v124", "nNumericCols", printed(cap, "nNumericCols"), 1, tol = 0)
check_true("v124", "late_numeric (missing first, numeric later) IS offered",
           "late_numeric" %in% offered)

# The false positive the old 5-row-only sniff also produced: a column
# numeric in its sampled window but not in the rows beyond it must NOT be
# offered, because this wrapper analyses whatever it offers complete-case,
# and "numeric" has to mean numeric everywhere counted, not just in the
# first five rows.
check_true("v124", "early_only (numeric first, text later) is NOT offered",
           !("early_only" %in% offered))

# Negative controls: an all-missing column and a label column must not be
# offered either way — if they were, the fixture itself would be suspect,
# not just the sniff.
check_true("v124", "all_missing is NOT offered",
           !("all_missing" %in% offered))
check_true("v124", "label is NOT offered",
           !("label" %in% offered))

if (!exists("EML_SUITE")) { eml_report("v124 describe-table column sniff"); eml_exit() }
