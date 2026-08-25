# ============================================================================
# describesniff_drive.praat -- drive @emlDescribeFilterNumericColumns (the
# procedure scripts/eml-describe-table.praat's numeric-column menu is built
# from) on a table designed to expose the old first-five-rows sniff, headlessly.
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS EXISTS. Until 25 August scripts/eml-describe-table.praat judged a
# column by its FIRST non-missing cell among the first FIVE rows only, then
# stopped looking -- the exact violation @emlCheckNumericColumn's own header
# warns against ("SAMPLING IS NOT ENOUGH"). Two symptoms, one fixture:
#
#   late_numeric   the first 5 rows are missing (a mix of blank and Praat's
#                  own native missing cell), rows 6-12 are clean numbers.
#                  The old sniff never found a non-missing cell in its
#                  5-row window and judged the column NOT numeric --
#                  offered never, no matter how much data followed.
#   early_only     the first 5 rows are clean numbers, row 8 is text. The
#                  old sniff judged the column numeric from row 1 alone and
#                  stopped looking -- offered wrongly, and every downstream
#                  read of it as "numeric" is now built on an unscanned tail.
#   all_missing    every row missing. Neither sniff should offer this one --
#                  the negative control that proves the fixture can fail.
#   label          ordinary text, for realism; never offered either way.
#
# A correct filter: late_numeric offered, early_only NOT offered, all_missing
# NOT offered, label NOT offered.
#
# THE PLUGIN TREE IS NOT HARD-CODED, for the same reason
# harness/directional/directional_drive.praat gives: `include` resolves at
# parse time against the top-level script's own directory. run.sh stages
# this file into out/work beside a `plugin` symlink, and the symlink is what
# selects the tree under test.
#
# Run:  bash harness/describesniff/run.sh
# ============================================================================

include plugin/stats/eml-core-utilities.praat
include plugin/stats/eml-core-descriptive.praat
include plugin/stats/eml-extract.praat
include plugin/stats/eml-output.praat
include plugin/stats/eml-inferential.praat
include plugin/stats/eml-result-writer.praat
include plugin/stats/eml-analysis.praat
include plugin/graphs/eml-annotation-procedures.praat
include plugin/graphs/eml-graph-procedures.praat

Text writing preferences: "UTF-8"

outFile$ = environment$ ("EML_DESCRIBESNIFF_CAPTURE")
if outFile$ = ""
    outFile$ = "../../evidence/info/v124_describesniff_info.txt"
endif

tableId = Create Table with column names: "describesniff", 12,
... "late_numeric early_only all_missing label"

# late_numeric: rows 1-5 missing (blank/native), rows 6-12 clean numbers.
Set string value:  1, "late_numeric", ""
Set numeric value: 2, "late_numeric", undefined
Set string value:  3, "late_numeric", ""
Set numeric value: 4, "late_numeric", undefined
Set string value:  5, "late_numeric", ""
for .r from 6 to 12
    Set numeric value: .r, "late_numeric", .r * 1.5
endfor

# early_only: rows 1-5 clean numbers, row 8 text, the rest numbers.
for .r from 1 to 12
    Set numeric value: .r, "early_only", .r * 2.0
endfor
Set string value: 8, "early_only", "n/a"

# all_missing: every row missing (blank).
for .r from 1 to 12
    Set string value: .r, "all_missing", ""
endfor

# label: ordinary text throughout.
word1$ = "alpha"
word2$ = "beta"
word3$ = "gamma"
word4$ = "delta"
word5$ = "epsilon"
word6$ = "zeta"
word7$ = "eta"
word8$ = "theta"
word9$ = "iota"
word10$ = "kappa"
word11$ = "lambda"
word12$ = "mu"
for .r from 1 to 12
    Set string value: .r, "label", word'.r'$
endfor

@emlDescribeFilterNumericColumns: tableId

clearinfo
appendInfoLine: "V124 DESCRIBESNIFF CAPTURE"
appendInfoLine: "nNumericCols  ", emlDescribeFilterNumericColumns.nNumericCols
for .k from 1 to emlDescribeFilterNumericColumns.nNumericCols
    appendInfoLine: "offered'.k'  ", emlDescribeFilterNumericColumns.numericCol'.k'$
endfor
appendInfoLine: ""
appendInfoLine: "V124DESCRIBESNIFF DONE"

writeFile: outFile$, info$ ()
