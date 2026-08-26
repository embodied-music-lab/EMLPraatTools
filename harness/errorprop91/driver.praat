# ============================================================================
# harness/errorprop91/driver.praat -- red/green demonstration for punch list
#                                     item 9.1, sites ONE, TWO and FOUR
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Three hand fixes from docs/ERROR_CENSUS_2026-08-25.md / punch list 9.1,
# each exercised through the REAL orchestrator entry point (never a
# hand-copied re-implementation of the loop):
#
#   SITE 1  @emlRequireNumericColumn (stats/eml-inferential.praat) wraps its
#           whole body in `if emlAuditColumn.error$ = ""` with no else. A
#           column that does not exist left .error$ untouched -- "" -- so
#           the gate reported success. Driven directly (this is the lowest
#           level a caller can reach it at; every shipped caller asks
#           @emlRequireColumnPresent first and so never sees this branch).
#
#   SITE 2  The pairwise Cohen's d matrix @emlRunAnovaAnalysis builds when
#           Tukey did not run (stats/eml-analysis.praat, "Ensure pairwise
#           Cohen's d matrix always exists") kept its zero## default on a
#           failed pair -- indistinguishable from a true zero effect. Driven
#           with two groups whose within-group SD is exactly zero (pooled SD
#           zero -> @emlCohenD refuses), beside a third group with real
#           spread so the omnibus ANOVA itself has something to work on.
#           This one call also exercises graphs/eml-annotation-procedures.praat's
#           own copy of the same loop (@emlReportAnovaComparison recomputes
#           the matrix itself, "backward compat" branch, and prints it) --
#           one fixture, both files, in the order the shipped chain runs
#           them.
#
#   SITE 4  @emlRunPairedAnalysis "both" mode drops a single-arm failure
#           silently: when one test fails beside one that succeeds,
#           .ranSomething stays 1 (this is not the "nothing ran" refusal) and
#           until the fix nothing said which arm was missing or why. Driven
#           with a constant nonzero difference: the paired t-test refuses
#           (zero variance in the differences) while Wilcoxon signed-rank
#           still computes (ties, not a zero-variance test).
#
# The KW/rank-biserial sibling of SITE 2 (stats/eml-analysis.praat's
# @emlRunKWAnalysis and its graphs/eml-annotation-procedures.praat twin) gets
# the identical mechanical fix but is NOT driven here: @emlKruskalWallis
# itself refuses outright when any group has 0 observations ("Group ""X""
# has 0 observations. Every group needs at least 1.", stats/eml-inferential.praat,
# @emlKruskalWallis), which is the only way @emlRankBiserialR can fail on a
# real pair -- so the omnibus never reaches the post-hoc loop with a failing
# pair on data a user could actually have. validate/v134_errorprop91.R
# asserts the fix structurally there (grep, the @emlNormalityRecommendation
# wizard-member idiom from v126) rather than pretending a drive exists that
# does not.
#
# WHERE THIS RUNS: unmodified, against TWO plugin trees.
#   green  the real, currently-fixed plugin (../../plugin, the repo's own
#          symlink) -- run this copy of the file in place.
#   red    harness/errorprop91/seed_red.sh builds a temp copy of the plugin
#          with fixes_9_1.patch reverse-applied (`git apply -R`) and places
#          THIS SAME FILE inside it at the matching relative depth, so the
#          include lines below resolve to the reverted copy without any
#          template substitution.
#
# Usage (run FROM the location the includes below are written for --
# seed_red.sh does this for the red half):
#
#     source harness/_env.sh
#     EML_ERRORPROP91_OUT=harness/errorprop91/out/green \
#         "$PRAAT" $PRAAT_TRUST --run harness/errorprop91/driver.praat
#
# Output: $EML_ERRORPROP91_OUT/report.txt -- the Info window verbatim.
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

outDir$ = environment$ ("EML_ERRORPROP91_OUT")
if outDir$ = ""
    outDir$ = "out/green"
endif
createDirectory: outDir$
reportPath$ = outDir$ + "/report.txt"
deleteFile: reportPath$

clearinfo

# ---------------------------------------------------------------------------
# SITE 1 -- @emlRequireNumericColumn on a column that is not in the table,
# called DIRECTLY (no @emlRequireColumnPresent ahead of it, which is the
# shadow every shipped caller has and this probe removes on purpose).
# ---------------------------------------------------------------------------
appendInfoLine: "=== SITE 1: emlRequireNumericColumn, missing column, no shadow ==="
tid1 = Create Table with column names: "s1", 3, "x"
Set numeric value: 1, "x", 1.0
Set numeric value: 2, "x", 2.0
Set numeric value: 3, "x", 3.0

@emlRequireNumericColumn: tid1, "Data column", "y", 0
appendInfoLine: "strict=0 error=[", emlRequireNumericColumn.error$, "]"
@emlRequireNumericColumn: tid1, "Data column", "y", 1
appendInfoLine: "strict=1 error=[", emlRequireNumericColumn.error$, "]"
removeObject: tid1
appendInfoLine: ""

# ---------------------------------------------------------------------------
# SITE 2 -- one-way ANOVA, no post-hoc (Tukey off): the pairwise Cohen's d
# matrix is the only pairwise thing in the report. Group A and group B are
# both exactly constant (zero within-group SD each) so their pooled SD is
# zero and @emlCohenD refuses that ONE pair; group C has real spread, which
# is what keeps the omnibus ANOVA itself computable (MSE is not zero).
# ---------------------------------------------------------------------------
appendInfoLine: "=== SITE 2: ANOVA, no post-hoc, one pair's Cohen's d fails ==="
tid2 = Create Table with column names: "s2", 11, "grp y"
for i from 1 to 3
    Set string value: i, "grp", "A_flat"
    Set numeric value: i, "y", 5.0
endfor
for i from 4 to 6
    Set string value: i, "grp", "B_flat"
    Set numeric value: i, "y", 8.0
endfor
c_y# = { 10, 14, 9, 12, 11 }
for i from 7 to 11
    Set string value: i, "grp", "C_spread"
    Set numeric value: i, "y", c_y# [i - 6]
endfor
@emlRunAnovaAnalysis: tid2, "y", "grp", 0
removeObject: tid2
appendInfoLine: ""

# ---------------------------------------------------------------------------
# SITE 4 -- paired "both" mode: column 1 minus column 2 is the SAME nonzero
# constant (2) for every one of the 5 pairs. The paired t-test refuses --
# zero variance in the differences -- while Wilcoxon signed-rank still runs
# (ties among equal |differences|, not a zero-variance test), so exactly one
# arm fails beside one that succeeds.
# ---------------------------------------------------------------------------
appendInfoLine: "=== SITE 4: paired both-mode, parametric arm fails alone ==="
tid4 = Create Table with column names: "s4", 5, "c1 c2"
c1# = { 12, 14, 9, 20, 7 }
for i from 1 to 5
    Set numeric value: i, "c1", c1# [i]
    Set numeric value: i, "c2", c1# [i] - 2
endfor
@emlRunPairedAnalysis: tid4, "c1", "c2", "both"
removeObject: tid4

writeFile: reportPath$, info$ ()
appendInfoLine: newline$, "wrote ", reportPath$
