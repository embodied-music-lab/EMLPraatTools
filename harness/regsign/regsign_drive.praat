# ============================================================================
# regsign_drive.praat -- drive @emlRunRegressionAnalysis on a NEGATIVE-slope
# fixture and capture the Info window report, headlessly.
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS EXISTS. v13's committed regression fixture
# (evidence/csv/v13_regression_input.csv) has a positive slope, so v13's
# existing check "sign of the printed R agrees with the printed slope" can
# never fire: a wrapper that always printed R = abs(sqrt(R-squared)) would
# pass it just as well as a correct one, because on that fixture the true
# sign IS positive. This driver runs the same production procedure,
# @emlRunRegressionAnalysis, on evidence/csv/v13_regression_neg_input.csv,
# whose slope is negative (R = -0.985 in R), so the sign-agreement check
# actually has something to disagree with when it should.
#
# Explanations are switched OFF before the call so the capture has the same
# shape as the committed v13_regression_info.txt (no prose lines).
#
# THE PLUGIN TREE IS NOT HARD-CODED, for the same reason
# harness/directional/directional_drive.praat gives: `include` resolves at
# parse time against the top-level script's own directory. run.sh stages
# this file into out/work beside a `plugin` symlink, and the symlink is
# what selects the tree under test.
#
# Run:  bash harness/regsign/run.sh
# ============================================================================

include plugin/stats/eml-core-utilities.praat
include plugin/stats/eml-core-descriptive.praat
include plugin/stats/eml-extract.praat
include plugin/stats/eml-inferential.praat
include plugin/stats/eml-output.praat
include plugin/stats/eml-result-writer.praat
include plugin/stats/eml-analysis.praat
include plugin/graphs/eml-annotation-procedures.praat

; The report banner uses non-ASCII box-drawing and bullet characters. Praat's
; default text-writing preference is "try ASCII, else UTF-16", so without
; this line writeFile: below would silently emit UTF-16BE and every
; downstream grep/R read would see garbage -- see CLAUDE.md, "Writing Praat
; in this repository". UTF-8, as harness/influence/ols_influence_drive.praat
; and the committed v13_regression_info.txt both are.
Text writing preferences: "UTF-8"

fixture$ = environment$ ("EML_REGSIGN_FIXTURE")
if fixture$ = ""
    fixture$ = "../../evidence/csv/v13_regression_neg_input.csv"
endif
outFile$ = environment$ ("EML_REGSIGN_CAPTURE")
if outFile$ = ""
    outFile$ = "../../evidence/info/v13_regression_neg_info.txt"
endif

tableId = Read Table from comma-separated file: fixture$
Rename: "demo regression neg"

emlShowExplanations = 0

clearinfo
selectObject: tableId
@emlRunRegressionAnalysis: tableId, "vibrato_regularity_pct", "practice_hrs_wk"

appendInfoLine: ""
appendInfoLine: "V13NEG DONE"

writeFile: outFile$, info$ ()
