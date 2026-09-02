# ============================================================================
# harness/verifyerrorlane/probe.praat -- does a REAL failure now name its own
#                                        cause? (verification of punch 9.2/9.3)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS EXISTS. Item 9.3's sweep is measured by a lint (v134), and a lint
# going green proves the SHAPE of a call site, not the BEHAVIOUR of a failure.
# This probe breaks two swept sites for real -- a column that does not exist,
# and a column holding a non-numeric cell -- and records, verbatim, what the
# orchestrator says. The question it answers is not "was a guard added" but
# "does the message name the actual cause".
#
# The two sites, both swept this round:
#   SITE A  @emlRunTwoGroupAnalysis's two @eml_getGroupData reads
#           (commit 8b9f77c, and the pair item 9.2 had pinned exempt).
#   SITE B  @emlReportAnovaComparison / @emlReportKWComparison in the
#           annotation layer (commits 50645ae, 301656a).
#
# READ THIS BEFORE READING out/console.txt. SITE B here calls those two
# REPORTERS DIRECTLY, which no shipped door does -- both read
# emlOneWayAnova / emlKruskalWallis globals their CALLER filled, so reaching
# them with a bad column indexes an empty group vector and ends the script.
# That behaviour is already documented at the call site
# (graphs/eml-annotation-procedures.praat, the "WHAT THE SPLIT COST HERE"
# comment) and is NOT a finding. probe2.praat is the file that asks the same
# question at the real doors -- @emlRunAnovaAnalysis, @emlRunKruskalWallisAnalysis,
# @emlRunAnnotationComparison -- and its answers are the ones that count.
#
# Usage:
#     source harness/_env.sh
#     EML_VERIFYERR_OUT=harness/verifyerrorlane/out \
#         "$PRAAT" $PRAAT_TRUST --run harness/verifyerrorlane/probe.praat
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_VERIFYERR_OUT")
if outDir$ = ""
    outDir$ = "out"
endif
createDirectory: outDir$
reportPath$ = outDir$ + "/report.txt"
deleteFile: reportPath$

clearinfo

# ---------------------------------------------------------------------------
# Fixture 1: a clean two-group table.
# ---------------------------------------------------------------------------
tGood = Create Table with column names: "good", 8, "g score"
for i to 8
    if i <= 4
        Set string value: i, "g", "A"
        Set numeric value: i, "score", 10 + i
    else
        Set string value: i, "g", "B"
        Set numeric value: i, "score", 20 + i
    endif
endfor

# ---------------------------------------------------------------------------
# Fixture 2: same shape, but row 3 of the data column holds a word.
# ---------------------------------------------------------------------------
tBad = Create Table with column names: "bad", 8, "g score"
for i to 8
    if i <= 4
        Set string value: i, "g", "A"
    else
        Set string value: i, "g", "B"
    endif
    Set numeric value: i, "score", 10 + i
endfor
Set string value: 3, "score", "n/a"

# ---------------------------------------------------------------------------
# Fixture 3: three groups, for the ANOVA/KW bridge.
# ---------------------------------------------------------------------------
tThree = Create Table with column names: "three", 12, "g score"
for i to 12
    if i <= 4
        Set string value: i, "g", "A"
        Set numeric value: i, "score", 10 + i
    elsif i <= 8
        Set string value: i, "g", "B"
        Set numeric value: i, "score", 20 + i
    else
        Set string value: i, "g", "C"
        Set numeric value: i, "score", 30 + i
    endif
endfor

appendInfoLine: "=== SITE A1: two-group, DATA column that does not exist ==="
@emlRunTwoGroupAnalysis: tGood, "nosuchcol", "g", "parametric", 0
appendInfoLine: "error=[", emlRunTwoGroupAnalysis.error$, "]"
appendInfoLine: ""

appendInfoLine: "=== SITE A2: two-group, GROUP column that does not exist ==="
@emlRunTwoGroupAnalysis: tGood, "score", "nosuchgroup", "parametric", 0
appendInfoLine: "error=[", emlRunTwoGroupAnalysis.error$, "]"
appendInfoLine: ""

appendInfoLine: "=== SITE A3: two-group, data column with a non-numeric cell ==="
@emlRunTwoGroupAnalysis: tBad, "score", "g", "parametric", 0
appendInfoLine: "error=[", emlRunTwoGroupAnalysis.error$, "]"
appendInfoLine: ""

appendInfoLine: "=== SITE B1: ANOVA bridge report, DATA column that does not exist ==="
@emlReportAnovaComparison: "three", "nosuchcol", "g", tThree, 3, 0
appendInfoLine: "-- end of bridge output --"
appendInfoLine: ""

appendInfoLine: "=== SITE B2: KW bridge report, DATA column that does not exist ==="
@emlReportKWComparison: "three", "nosuchcol", "g", tThree, 3, 0
appendInfoLine: "-- end of bridge output --"
appendInfoLine: ""

appendInfoLine: "=== SITE B3: KW bridge report, GROUP column that does not exist ==="
@emlReportKWComparison: "three", "score", "nosuchgroup", tThree, 3, 0
appendInfoLine: "-- end of bridge output --"
appendInfoLine: ""

removeObject: tGood, tBad, tThree

writeInfoLine_dummy = 0
report$ = info$ ()
writeFile: reportPath$, report$
