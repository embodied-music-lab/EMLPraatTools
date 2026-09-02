# ============================================================================
# harness/regressiongroup/probe.praat -- per-group regression, kernel side
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Punch list 4.5 / OPEN_ITEMS "the regression group column" ruling. Drives
# stats/eml-analysis.praat's @emlRunGroupedRegressionAnalysis directly -- the same
# choice harness/doorcensus/probe.praat makes ("direct kernel calls where
# [the door] is an API") -- rather than through a dialog: @emlRunGroupedRegressionAnalysis
# IS the shared call both eml-regress.praat and eml-wizard.praat now make, so
# driving it here is driving the shipped code, not a stand-in for it.
#
# THE FIXTURE is Sol's Simpson exhibit, the same values committed at
# harness/doorcensus/fixtures/leg5_grouped_regression.csv (copied here as
# literal vectors, the same choice harness/doorcensus/probe.praat itself
# makes for its own leg5): x = 1..10 in both groups, slopes +2 and -2 with
# light noise, pooled slope ~ 0. Group C is added HERE, local to this probe,
# with only two rows -- below the n = 3 floor @emlLinearRegression itself
# enforces -- to exercise the "too small to fit, named and skipped" half of
# the ruling that the two-group door-census fixture does not exercise.
#
# WHAT THIS PROVES, beside the door-census's own numeric agreement legs:
#   1. The per-group fit for A and B matches base R's lm() exactly (this
#      file's own oracle is validate/v135_regression_grouping.R, run
#      against the vectors below).
#   2. Group C (n = 2) is named and skipped, not silently dropped and not
#      silently run.
#   3. The tidy export carries labelled rows -- "(overall) ..." and
#      "<group> = <level> ..." -- and NOTHING else, once the per-group
#      block has run (the grouped rebuild, not an accumulation).
#   4. glance's n.groups records exactly the groups actually fit.
#
# Base R only for the oracle (validate/v135). No packages.
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
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/stats/eml-analysis.praat

outPath$ = environment$ ("EML_REGGROUP_OUT")
if outPath$ = ""
    outPath$ = "out/REGGROUP.tsv"
endif
writeFileLine: outPath$, "key", tab$, "value"

procedure emit: .key$, .val$
    appendFileLine: outPath$, .key$, tab$, .val$
endproc

procedure emitNum: .key$, .val
    if .val = undefined
        @emit: .key$, "undefined"
    else
        @emit: .key$, fixed$ (.val, 12)
    endif
endproc

# ----------------------------------------------------------------------------
# THE FIXTURE -- x = 1..10 in both groups A and B (Sol's Simpson exhibit,
# harness/doorcensus/fixtures/leg5_grouped_regression.csv), plus a
# below-floor group C local to this probe.
# ----------------------------------------------------------------------------
regX# = { 1,2,3,4,5,6,7,8,9,10, 1,2,3,4,5,6,7,8,9,10, 1,2 }
regY# = { 7.30,8.80,11.10,12.60,15.20,16.90,19.30,20.70,23.10,24.80,
    ... 97.80,96.30,93.90,92.20,89.70,88.10,85.80,84.20,81.90,80.30,
    ... 50.00,51.00 }
regGrp$# = { "A","A","A","A","A","A","A","A","A","A",
    ... "B","B","B","B","B","B","B","B","B","B",
    ... "C","C" }

regN = size (regX#)
regTab = Create Table with column names: "reggroup", regN, { "x", "y", "group" }
for regI from 1 to regN
    selectObject: regTab
    Set numeric value: regI, "x", regX# [regI]
    Set numeric value: regI, "y", regY# [regI]
    Set string value: regI, "group", regGrp$# [regI]
endfor

# ── Door step 1: the overall fit, exactly as eml-regress.praat's own
# @emlRunRegressionAnalysis call runs it (respCol$ = "y", predCol$ = "x") ──
selectObject: regTab
@emlRunRegressionAnalysis: regTab, "y", "x"
if emlRunRegressionAnalysis.error$ <> ""
    @emit: "overall_error", emlRunRegressionAnalysis.error$
else
    @emitNum: "overall_slope", emlLinearRegression.slope
    @emitNum: "overall_intercept", emlLinearRegression.intercept
    @emitNum: "overall_r2", emlLinearRegression.rSquared

    # ── Door step 2: the per-group port (punch list 4.5) -- the SAME call
    # both eml-regress.praat and eml-wizard.praat now make. ──
    selectObject: regTab
    @emlRunGroupedRegressionAnalysis: regTab, "x", "y", "group"

    @emitNum: "pgTotal", emlRunGroupedRegressionAnalysis.pgTotal
    @emitNum: "pgRun", emlRunGroupedRegressionAnalysis.pgRun
    @emitNum: "pgSkipped", emlRunGroupedRegressionAnalysis.pgSkipped

    @eml_colIndex: "glance", "n.groups"
    @emit: "glance_n_groups", emlGlance_val$ [eml_colIndex.idx]

    # ── The tidy export: every row, verbatim, so the check can assert both
    # WHICH rows are there and that nothing else is. ──
    @emitNum: "tidy_nRows", emlTidy_nRows
    @eml_colIndex: "tidy", "term"
    termCol = eml_colIndex.idx
    @eml_colIndex: "tidy", "estimate"
    estCol = eml_colIndex.idx
    @eml_colIndex: "tidy", "std.error"
    seCol = eml_colIndex.idx
    @eml_colIndex: "tidy", "statistic"
    statCol = eml_colIndex.idx
    @eml_colIndex: "tidy", "p.value"
    pCol = eml_colIndex.idx
    for regR from 1 to emlTidy_nRows
        @emit: "tidy_term_" + string$ (regR), emlTidy_cell$ [regR, termCol]
        @emit: "tidy_estimate_" + string$ (regR), emlTidy_cell$ [regR, estCol]
        @emit: "tidy_se_" + string$ (regR), emlTidy_cell$ [regR, seCol]
        @emit: "tidy_stat_" + string$ (regR), emlTidy_cell$ [regR, statCol]
        @emit: "tidy_p_" + string$ (regR), emlTidy_cell$ [regR, pCol]
    endfor
endif

@emit: "completed", "1"
