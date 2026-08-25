# ============================================================================
# v123 — @emlCheckNumericColumn recognises Praat's native missing cell
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Punch list 7.2. @emlCheckNumericColumn's own cell taxonomy names four cell
# kinds — missing, numeric, coerced, non-numeric — and its "missing" test
# recognised only the blank/whitespace form. A numeric column with a cell
# set to Praat's `undefined` reads back from "Get value:" as the literal
# string "--undefined--", not "". That string is not blank, does not match
# the strict numeric-literal regex, and number() cannot parse it either, so
# it fell into "non-numeric": the checker set .isNumeric = 0 and the whole
# column vanished from every dialog and draw path that calls this check,
# instead of being offered and analysed complete-case per the plugin-wide
# complete-case-with-disclosure convention.
#
# harness/nummiss drives @emlCheckNumericColumn directly (headless, no
# dialog) on a 6-row column: 4 clean numeric cells, 1 blank cell (the
# already-recognised missing form), 1 cell set via
# `Set numeric value: r, col, undefined` (the native missing form under
# test). A correct checker: isNumeric = 1, nNumeric = 4, nMissing = 2,
# nCoerced = 0, nNonNumeric = 0.
#
# DRIVEN 25 August 2026:
#   bash harness/nummiss/run.sh
#
# Output: evidence/info/v123_nummiss_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

cap <- capture("v123_nummiss_info.txt")

check_true("v123", "capture reached its end marker",
           any(grepl("^V123NUMMISS DONE$", cap$lines)))

# The bug's own symptom: a column with a native-missing cell must be
# recognised as numeric, not vanish.
check("v123", "isNumeric", printed(cap, "isNumeric"), 1, tol = 0)

# All 6 rows scanned.
check("v123", "nRows", printed(cap, "nRows"), 6, tol = 0)

# 4 clean numeric cells counted as numeric.
check("v123", "nNumeric", printed(cap, "nNumeric"), 4, tol = 0)

# Both the blank cell AND the native "--undefined--" cell counted as
# missing — this is the line that was 1 before the fix (the blank alone)
# and must be 2 after it.
check("v123", "nMissing counts both the blank AND the native-missing cell",
      printed(cap, "nMissing"), 2, tol = 0)

# Neither missing form is a coercion hazard or an unparseable cell.
check("v123", "nCoerced", printed(cap, "nCoerced"), 0, tol = 0)
check_true("v123", "nNonNumeric — the native-missing cell is no longer counted as non-numeric",
           printed(cap, "nNonNumeric") == 0)
check("v123", "nBad", printed(cap, "nBad"), 0, tol = 0)

# The reason string must not cite "--undefined--" as an offending cell.
check_true("v123", "reason string does not cite the native-missing cell as an offender",
           !grepl("--undefined--", printed_str(cap, "reason", 1, expect_hits = 1), fixed = TRUE))
check_true("v123", "reason string reports the column as numeric",
           grepl("is numeric", cap$lines[grepl("^reason", trimws(cap$lines))], fixed = TRUE))

if (!exists("EML_SUITE")) { eml_report("v123 native missing values"); eml_exit() }
