# ============================================================================
# nummiss_drive.praat -- drive @emlCheckNumericColumn on a column that mixes
# clean numeric cells, blank cells, and PRAAT'S OWN NATIVE MISSING CELL, and
# capture the verdict, headlessly.
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS EXISTS. @emlCheckNumericColumn's own cell taxonomy names four
# kinds of cell: missing (blank), numeric, coerced, non-numeric. Its
# "missing" test recognised only the blank/whitespace form. A numeric column
# with a cell set to Praat's `undefined` -- which "Get value:" reads back as
# the literal string "--undefined--", not "" -- fell through the blank test,
# failed the numeric-literal regex, failed number() as well (number()
# returns undefined() for that literal), and was therefore counted as a
# NON-NUMERIC offending cell: .isNumeric = 0, "not numeric" cited in
# .reason$, and the column vanished from every dialog and draw path that
# calls this check instead of being offered and analysed complete-case.
#
# THIS FIXTURE builds one Table with a numeric-looking column of 6 rows:
# four clean numeric cells, one BLANK cell (the already-recognised missing
# form), and one cell set via `Set numeric value: r, col, undefined` (the
# native missing form -- what a formula or a lookup that failed to find a
# match leaves behind). A correct checker: .isNumeric = 1, .nMissing = 2,
# .nNonNumeric = 0, .nCoerced = 0, .nNumeric = 4.
#
# THE PLUGIN TREE IS NOT HARD-CODED, for the same reason
# harness/directional/directional_drive.praat gives: `include` resolves at
# parse time against the top-level script's own directory. run.sh stages
# this file into out/work beside a `plugin` symlink, and the symlink is what
# selects the tree under test.
#
# Run:  bash harness/nummiss/run.sh
# ============================================================================

include plugin/graphs/eml-graph-procedures.praat

Text writing preferences: "UTF-8"

outFile$ = environment$ ("EML_NUMMISS_CAPTURE")
if outFile$ = ""
    outFile$ = "../../evidence/info/v123_nummiss_info.txt"
endif

tableId = Create Table with column names: "nummiss", 6, "measure"
Set numeric value: 1, "measure", 10.5
Set numeric value: 2, "measure", 20.25
Set string value:  3, "measure", ""
Set numeric value: 4, "measure", 30
Set numeric value: 5, "measure", undefined
Set numeric value: 6, "measure", 40.75

@emlCheckNumericColumn: tableId, "measure"

clearinfo
appendInfoLine: "V123 NUMMISS CAPTURE"
appendInfoLine: "isNumeric  ", emlCheckNumericColumn.isNumeric
appendInfoLine: "nRows      ", emlCheckNumericColumn.nRows
appendInfoLine: "nNumeric   ", emlCheckNumericColumn.nNumeric
appendInfoLine: "nMissing   ", emlCheckNumericColumn.nMissing
appendInfoLine: "nCoerced   ", emlCheckNumericColumn.nCoerced
appendInfoLine: "nNonNumeric  ", emlCheckNumericColumn.nNonNumeric
appendInfoLine: "nBad       ", emlCheckNumericColumn.nBad
appendInfoLine: "reason     ", emlCheckNumericColumn.reason$
appendInfoLine: ""
appendInfoLine: "V123NUMMISS DONE"

writeFile: outFile$, info$ ()
