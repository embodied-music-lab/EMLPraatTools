# ============================================================================
# harness/corrscope/probe.praat -- the scatter page's "Relationships shown"
# scope control (punch list 8.3), drawing side
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Calls @emlDrawScatterPlot (graphs/eml-draw-procedures.praat) directly, three
# times, with scatterCorrScope at 1 (Per group), 2 (Overall) and 3 (Both) --
# the same global the form's "Relationships shown" field now writes, and the
# same procedure both the form and the recorder's replayed script reach. No
# dialog is opened; this is a direct kernel/drawing-layer call, the same
# choice harness/regressiongroup/probe.praat makes for item 4.5's port, and
# for the same reason: @emlDrawScatterPlot IS the shared call, so driving it
# here is driving the shipped code, not a stand-in for it.
#
# THE FIXTURE is harness/doorcensus/fixtures/leg6_correlation_scope.csv,
# copied here as literal vectors (the same choice harness/regressiongroup's
# probe makes for leg5's vectors) rather than re-derived: within each of
# groups A and B, x and y rise together (r ~ +.999 each); group B's whole
# y-range sits far below group A's despite higher x, so the POOLED
# (Overall) r is ~ -.561. Sol's Simpson-for-correlation exhibit, and the
# exact numbers the punch list's item 8.3 cites.
#
# WHAT THIS PROVES, read by validate/v137_correlation_scope.R:
#   1. scope = Per group draws exactly the two group lines (A, B), no
#      "Overall" line -- today's only behaviour, preserved as one of the
#      three choices rather than silently dropped.
#   2. scope = Overall draws exactly one line, "Overall: ...", and NO
#      group line -- the capability this item adds. Its r matches base R's
#      cor.test() on the pooled data.
#   3. scope = Both draws all three lines, each carrying its own label
#      ("A: ...", "B: ...", "Overall: ..."), so a reader cannot mistake one
#      model's number for another's on one figure.
#   4. Every drawn r, in every scope, matches cor.test() run on exactly the
#      data that produced it (the oracle side is validate/v137's own R).
#
# THE OLD BEHAVIOUR, FOR THE RED DEMONSTRATION.
# Before this item, scatterCorrScope did not exist: @emlDrawScatterPlot's
# grouped path always ran the per-group loop and never computed a pooled
# line. Setting scatterCorrScope here against the pre-fix source (`git show
# <rev before 8.3>:plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat`)
# is inert -- the global is set but nothing reads it -- so scope = Overall
# and scope = Both both come back looking exactly like scope = Per group:
# two group lines, no "Overall" line, no matter what scatterCorrScope is
# set to. That is the red validate/v137's own structural section demands:
# every one of the three scopes producing IDENTICAL annotation content is
# exactly the "three-way control that only ever shows one thing" defect the
# item exists to close. See harness/corrscope/run.sh's `--pre-fix` mode.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

outPath$ = environment$ ("EML_CORRSCOPE_OUT")
if outPath$ = ""
    outPath$ = "out/CORRSCOPE.tsv"
endif
writeFileLine: outPath$, "key", tab$, "value"

procedure emit: .key$, .val$
    appendFileLine: outPath$, .key$, tab$, .val$
endproc

# ----------------------------------------------------------------------------
# THE FIXTURE -- harness/doorcensus/fixtures/leg6_correlation_scope.csv,
# literal vectors. r_A = r_B ~ +0.999, r_pooled ~ -0.561.
# ----------------------------------------------------------------------------
csX# = { 1,2,3,4,5,6,7,8, 11,12,13,14,15,16,17,18 }
csY# = { 7.20,8.90,11.15,12.80,15.10,16.85,19.20,20.90,
    ... -7.80,-6.10,-3.85,-2.20,0.10,1.85,4.20,5.90 }
csGrp$# = { "A","A","A","A","A","A","A","A",
    ... "B","B","B","B","B","B","B","B" }
csN = size (csX#)

csTab = Create Table with column names: "corrscope", csN, { "x", "y", "group" }
for csI from 1 to csN
    selectObject: csTab
    Set numeric value: csI, "x", csX# [csI]
    Set numeric value: csI, "y", csY# [csI]
    Set string value: csI, "group", csGrp$# [csI]
endfor

@emlInitializeDrawingDefaults

# The form's globals @emlDrawScatterPlot reads directly (not as procedure
# arguments) -- see the ruling on undotted globals in CLAUDE.md. Correlation
# only (Pearson), annotation on, no regression line, so every drawn
# annotation line is a bare "label: r = ..., p = ..." this probe can parse
# without also untangling a fitted-line equation.
annotate = 1
scatterAnalysisType = 1
annotCorrType$ = "pearson"
annotStyle$ = "p-value"
scatterShowDots = 0
scatterDotSize = 2
scatterRegressionLine = 0
scatterShowFormula = 0

# @csRunScope: .scope, .label$
# One press of the drawing layer at one scope setting. Clears the annotation
# block first (@emlDrawScatterPlot does this itself at its own Step 7, but
# clearing here too means a probe run with a filter cannot inherit a
# previous case's leftover array on a code path that errors before Step 7).
procedure csRunScope: .scope, .label$
    annotBlockN = 0
    scatterCorrScope = .scope
    selectObject: csTab
    @emlDrawScatterPlot: csTab, "Corrscope probe", "x", "y", 6, 4, "color", 4,
    ... "x", "y", "group", 0, 0, 0, 0, 1
    @emit: .label$ + "_n_lines", string$ (annotBlockN)
    for csK from 1 to annotBlockN
        @emit: .label$ + "_line_" + string$ (csK), annotBlockLabel$ [csK]
    endfor
endproc

@csRunScope: 1, "scope_pergroup"
@csRunScope: 2, "scope_overall"
@csRunScope: 3, "scope_both"

@emit: "completed", "1"
writeInfoLine: "CORRSCOPE wrote ", outPath$
