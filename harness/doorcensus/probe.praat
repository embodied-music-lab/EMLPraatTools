# ============================================================================
# harness/doorcensus/probe.praat -- the door-agreement census, kernel side
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS DRIVES, AND WHY NOT THE DIALOGS.
#
# docs/WORK_ORDER_DOOR_CENSUS.md section 4 names the split: "driven doors
# use the GUI harness where the door is a dialog ... and direct kernel
# calls where it is an API." Every leg here compares two CALL SEQUENCES
# this repository's own dialog scripts make -- cited by file:line in each
# fixture's header comment -- not the beginPause chrome around them. The
# chrome does not change a number; the kernel calls are the door. This is
# the same choice v90/v93 made for the psychometrics lane (a symlinked
# stats/ tree, no GUI), for the same reason: a dialog rig here would be
# harness/correlgroup/run.sh's excise-and-hash machinery six times over,
# and it would still bottom out at these same procedure calls.
#
# THE SIX LEGS, each an intent named in punch-list item 8.1:
#
#   leg1  pairwise comparisons      -- Pairwise dialog (Student t,
#         vs draw's annotation         Bonferroni) vs the bridge's
#                                       hardcoded Tukey HSD
#                                       (eml-annotation-procedures.praat
#                                       :3543-3544, literal "1")
#   leg2  unequal-spread ANOVA      -- the SAME shared reporter,
#         vs draw                      @emlReportAnovaComparison, called
#                                       from both the analysis door
#                                       (eml-analysis.praat:379) and the
#                                       bridge (eml-annotation-procedures
#                                       .praat:3543-3544) -- probed here
#                                       one level down, at the Welch F /
#                                       Games-Howell kernels the reporter
#                                       calls when Brown-Forsythe rejects
#   leg3  post-hoc opt-out          -- Compare k Groups with "Tukey HSD
#         vs draw                      post hoc" UNCHECKED (doTukey = 0)
#                                       vs the same hardcoded "1" leg1
#                                       names
#   leg4  paired comparison         -- Compare Paired Observations
#         vs spaghetti's own door       (@emlTTestPaired) vs the plugin's
#                                       own independent-samples kernel
#                                       (@emlTTest) run on the identical
#                                       eight subjects with the pairing
#                                       dropped -- the spaghetti plot
#                                       itself prints no inferential
#                                       statistic at all (eml-draw-
#                                       procedures.praat:3417-3462) to
#                                       warn a reader off reaching for
#                                       that door on its reshaped table
#   leg5  grouped regression        -- Simple Linear Regression, whose
#         (Simpson)                    Group column is read and never
#                                       passed to the analysis
#                                       (eml-regress.praat:107-108) vs
#                                       the scatter draw door, which
#                                       fits per group
#   leg6  correlation display       -- the correlate dialog's per-group
#         scope                        block (eml-correlate.praat, the
#                                       "(overall)" / group-level terms)
#                                       vs the scatter's own per-group
#                                       block -- BOTH call
#                                       @emlReportCorrelationAnalysis
#                                       (eml-draw-procedures.praat:4709
#                                       and :5117), probed here at the
#                                       @emlPearsonCorrelation kernel
#                                       underneath it
#
# Every fixture is harness/doorcensus/fixtures/<name>.csv, committed, with
# its own adversarial-construction note. The literals below are that same
# data, typed once here because Praat has no CSV reader worth the
# indirection for eighteen numbers -- validate/v127 reads the CSV as the
# checked-in record and asserts this file's own oracle-comparison numbers
# against a value it derives afresh from that CSV's numbers in R, so nei-
# ther file is trusted blind against the other.
#
# OUTPUT: harness/doorcensus/out/DOORCENSUS.tsv, one "leg|key|value" row
# per fact, plus a HEADER row. Base R (validate/v127) reads it and holds
# every number to a live oracle; this file computes nothing it asserts
# passes or fails -- it only reports what the kernels said.
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

outPath$ = environment$ ("EML_DOORCENSUS_OUT")
if outPath$ = ""
    outPath$ = "out/DOORCENSUS.tsv"
endif
writeFileLine: outPath$, "leg", tab$, "key", tab$, "value"

procedure emit: .leg$, .key$, .val$
    appendFileLine: outPath$, .leg$, tab$, .key$, tab$, .val$
endproc

procedure emitNum: .leg$, .key$, .val
    if .val = undefined
        @emit: .leg$, .key$, "undefined"
    else
        @emit: .leg$, .key$, fixed$ (.val, 12)
    endif
endproc

# ----------------------------------------------------------------------
# Build a 2-column (value, group) Table from three parallel Praat vectors
# ----------------------------------------------------------------------
procedure buildGroupTable: .name$, .val#, .grp$#
    .n = size (.val#)
    .id = Create Table with column names: .name$, .n, { "value", "group" }
    for .i from 1 to .n
        Set numeric value: .i, "value", .val# [.i]
        Set string value: .i, "group", .grp$# [.i]
    endfor
    selectObject: .id
endproc

# ============================================================================
# LEG 1 -- pairwise vs draw (also the leg3 table, reused deliberately)
# ============================================================================
leg1val# = { 13.81,12.29,8.47,7.09,7.81,10.59,
    ... 13.01,15.31,17.27,13.48,10.43,13.07,
    ... 28.14,25.32,23.51,22.86,21.75,22.86 }
leg1grp$# = { "A","A","A","A","A","A",
    ... "B","B","B","B","B","B",
    ... "C","C","C","C","C","C" }
@buildGroupTable: "leg1", leg1val#, leg1grp$#
leg1tab = buildGroupTable.id

# Door A: Pairwise dialog, "Student t", "Bonferroni" -- @emlRunPairwiseAnalysis's
# own call, scripts/eml-pairwise.praat -> stats/eml-analysis.praat:714, which
# for test$ = "student" calls @emlPairwiseT with .type$ = "student".
selectObject: leg1tab
@emlPairwiseT: leg1tab, "value", "group", "bonferroni", "student"
@emit: "leg1", "door", "pairwise_dialog"
@emit: "leg1", "test_label", emlPairwiseT.method$
@emit: "leg1", "adjust_label", emlPairwiseT.adjustMethod$
@emitNum: "leg1", "p_AB", emlPairwiseT.pMatrix## [1, 2]
@emitNum: "leg1", "p_AC", emlPairwiseT.pMatrix## [1, 3]
@emitNum: "leg1", "p_BC", emlPairwiseT.pMatrix## [2, 3]
@emitNum: "leg1", "t_AB", emlPairwiseT.tMatrix## [1, 2]
@emitNum: "leg1", "df_AB", emlPairwiseT.dfMatrix## [1, 2]

# Door B: the figure's own annotation -- @emlBridgeGroupComparison's
# parametric k-group branch always runs @emlOneWayAnova with .tukey = 1
# (eml-annotation-procedures.praat:3543-3544, the literal argument).
selectObject: leg1tab
@emlOneWayAnova: leg1tab, "value", "group", 1
@emit: "leg1", "door2", "draw_bridge"
@emit: "leg1", "door2_label", "Tukey HSD"
@emitNum: "leg1", "anova_F", emlOneWayAnova.fValue
@emitNum: "leg1", "anova_p", emlOneWayAnova.p
selectObject: leg1tab
@emlTukeyHSD: leg1tab, "value", "group", 0.05
@emitNum: "leg1", "tukey_p_AB", emlTukeyHSD.pMatrix## [1, 2]
@emitNum: "leg1", "tukey_p_AC", emlTukeyHSD.pMatrix## [1, 3]
@emitNum: "leg1", "tukey_p_BC", emlTukeyHSD.pMatrix## [2, 3]
@emitNum: "leg1", "tukey_q_AB", emlTukeyHSD.qMatrix## [1, 2]
@emitNum: "leg1", "tukey_df", emlTukeyHSD.dfWithin

# ============================================================================
# LEG 3 -- post-hoc opt-out vs draw (SAME table as leg 1)
# ============================================================================
# Door A: Compare k Groups (ANOVA) with "Tukey HSD post hoc" unchecked --
# @emlRunAnovaAnalysis: tableId, dataCol$, groupCol$, doTukey with
# doTukey = 0 (scripts/eml-compare-k-groups.praat, the boolean field).
# @emlRunAnovaAnalysis calls @emlOneWayAnova with .tukey taken straight
# from that argument, so the kernel call below IS the analysis door's own
# call with the user's choice honoured.
selectObject: leg1tab
@emlOneWayAnova: leg1tab, "value", "group", 0
@emit: "leg3", "door", "analysis_optout"
@emitNum: "leg3", "anova_F", emlOneWayAnova.fValue
@emitNum: "leg3", "anova_p", emlOneWayAnova.p
@emit: "leg3", "posthoc_ran", "0"

# Door B: the figure's own annotation -- identical call to leg1's door2,
# named again here because it is THIS leg's comparator: the bridge never
# reads doTukey at all.
@emit: "leg3", "door2", "draw_bridge"
@emit: "leg3", "posthoc_ran_door2", "1"
@emitNum: "leg3", "tukey_p_CA", emlTukeyHSD.pMatrix## [1, 3]
@emitNum: "leg3", "tukey_p_CB", emlTukeyHSD.pMatrix## [2, 3]

# ============================================================================
# LEG 2 -- unequal-spread ANOVA vs draw
# ============================================================================
leg2val# = { 11.14,9.40,9.65,9.79,9.51,9.53,
    ... 15.37,11.47,12.69,21.85,13.61,24.23,
    ... 29.25,13.59,26.17,14.74,3.85,8.54 }
leg2grp$# = { "A","A","A","A","A","A",
    ... "B","B","B","B","B","B",
    ... "C","C","C","C","C","C" }
@buildGroupTable: "leg2", leg2val#, leg2grp$#
leg2tab = buildGroupTable.id

selectObject: leg2tab
@emlBrownForsythe: leg2tab, "value", "group"
@emitNum: "leg2", "bf_p", emlBrownForsythe.p

# Door A path (analysis door's supplemental block) and Door B path (bridge's
# supplemental block) are the SAME call
# (@emlReportAnovaComparison, both sites, .bfFlags gate) -- run twice here
# under the two names to record that the SAME arguments reach the SAME
# kernel from either site, not merely that the kernel is deterministic.
selectObject: leg2tab
@emlWelchAnova: leg2tab, "value", "group"
@emit: "leg2", "door", "analysis_supplement"
@emitNum: "leg2", "welch_F", emlWelchAnova.f
@emitNum: "leg2", "welch_df1", emlWelchAnova.df1
@emitNum: "leg2", "welch_df2", emlWelchAnova.df2
@emitNum: "leg2", "welch_p", emlWelchAnova.p

selectObject: leg2tab
@emlWelchAnova: leg2tab, "value", "group"
@emit: "leg2", "door2", "draw_supplement"
@emitNum: "leg2", "welch_F_door2", emlWelchAnova.f
@emitNum: "leg2", "welch_p_door2", emlWelchAnova.p

selectObject: leg2tab
@emlGamesHowell: leg2tab, "value", "group", 0.05
@emitNum: "leg2", "gh_p_AB", emlGamesHowell.pMatrix## [1, 2]
@emitNum: "leg2", "gh_p_AC", emlGamesHowell.pMatrix## [1, 3]
@emitNum: "leg2", "gh_p_BC", emlGamesHowell.pMatrix## [2, 3]
@emitNum: "leg2", "gh_q_AB", emlGamesHowell.qMatrix## [1, 2]
@emitNum: "leg2", "gh_df_AB", emlGamesHowell.dfMatrix## [1, 2]

# ============================================================================
# LEG 4 -- paired vs the plugin's own unpaired kernel on the same subjects
# ============================================================================
leg4c1# = { 14.30,15.80,18.10,18.90,21.20,21.70,24.15,25.85 }
leg4c2# = { 14.90,17.20,18.85,20.25,21.80,23.10,24.75,27.20 }

# Door A: Compare Paired Observations, "Paired t-test" --
# @emlRunPairedAnalysis calls @emlTTestPaired: .v1#, .v2#, 2 directly on
# the two condition columns (stats/eml-analysis.praat:1784ff).
@emlTTestPaired: leg4c1#, leg4c2#, 2
@emit: "leg4", "door", "paired_dialog"
@emit: "leg4", "test_label", "Paired t-test"
@emitNum: "leg4", "paired_t", emlTTestPaired.t
@emitNum: "leg4", "paired_df", emlTTestPaired.df
@emitNum: "leg4", "paired_p", emlTTestPaired.p
@emitNum: "leg4", "paired_meandiff", emlTTestPaired.meanDiff

# Door B: the same eight subjects, pairing dropped -- the plugin's own
# independent two-sample kernel (Welch, the plugin's stated safer default
# -- language batch item 1) on Condition/Value, which is what a reader
# reaches for on the spaghetti's reshaped long table since the spaghetti
# figure itself prints no test at all to say otherwise.
@emlTTest: leg4c1#, leg4c2#, 2, 0
@emit: "leg4", "door2", "unpaired_kernel"
@emit: "leg4", "test_label_door2", "Welch t-test"
@emitNum: "leg4", "unpaired_t", emlTTest.t
@emitNum: "leg4", "unpaired_df", emlTTest.df
@emitNum: "leg4", "unpaired_p", emlTTest.p
@emitNum: "leg4", "unpaired_meandiff", emlTTest.meanDiff

# ============================================================================
# LEG 5 -- grouped regression (Simpson)
# ============================================================================
leg5x# = { 1,2,3,4,5,6,7,8,9,10 }
leg5yA# = { 7.30,8.80,11.10,12.60,15.20,16.90,19.30,20.70,23.10,24.80 }
leg5yB# = { 97.80,96.30,93.90,92.20,89.70,88.10,85.80,84.20,81.90,80.30 }
leg5xAll# = { 1,2,3,4,5,6,7,8,9,10,1,2,3,4,5,6,7,8,9,10 }
leg5yAll# = { 7.30,8.80,11.10,12.60,15.20,16.90,19.30,20.70,23.10,24.80,
    ... 97.80,96.30,93.90,92.20,89.70,88.10,85.80,84.20,81.90,80.30 }

# Door A: Simple Linear Regression dialog -- @emlRunRegressionAnalysis:
# tableId, respCol$, predCol$ (scripts/eml-regress.praat:107). The group
# column the user selected is never in that argument list, so the kernel
# call it actually reaches is the POOLED one, x/y run together.
@emlLinearRegression: leg5xAll#, leg5yAll#
@emit: "leg5", "door", "regression_dialog"
@emit: "leg5", "scope_label", "pooled (group column read, never passed)"
@emitNum: "leg5", "pooled_slope", emlLinearRegression.slope
@emitNum: "leg5", "pooled_intercept", emlLinearRegression.intercept
@emitNum: "leg5", "pooled_r2", emlLinearRegression.rSquared

# Door B: the scatter Draw door, which DOES fit per group.
@emlLinearRegression: leg5x#, leg5yA#
@emit: "leg5", "door2", "scatter_draw"
@emitNum: "leg5", "slopeA", emlLinearRegression.slope
@emitNum: "leg5", "r2A", emlLinearRegression.rSquared
@emlLinearRegression: leg5x#, leg5yB#
@emitNum: "leg5", "slopeB", emlLinearRegression.slope
@emitNum: "leg5", "r2B", emlLinearRegression.rSquared

# ============================================================================
# LEG 6 -- correlation display scope
# ============================================================================
leg6xA# = { 1,2,3,4,5,6,7,8 }
leg6yA# = { 7.20,8.90,11.15,12.80,15.10,16.85,19.20,20.90 }
leg6xB# = { 11,12,13,14,15,16,17,18 }
leg6yB# = { -7.80,-6.10,-3.85,-2.20,0.10,1.85,4.20,5.90 }
leg6xAll# = { 1,2,3,4,5,6,7,8,11,12,13,14,15,16,17,18 }
leg6yAll# = { 7.20,8.90,11.15,12.80,15.10,16.85,19.20,20.90,
    ... -7.80,-6.10,-3.85,-2.20,0.10,1.85,4.20,5.90 }

# Door A: the correlate dialog's per-group block -- the "(overall)" row
# and each group row both go through @emlReportCorrelationAnalysis, which
# calls @emlPearsonCorrelation per group; probed here one level down.
@emlPearsonCorrelation: leg6xA#, leg6yA#, 2
@emit: "leg6", "door", "correlate_dialog"
@emit: "leg6", "scope_label_A", "group A"
@emitNum: "leg6", "r_A", emlPearsonCorrelation.r
@emitNum: "leg6", "p_A", emlPearsonCorrelation.p
@emitNum: "leg6", "df_A", emlPearsonCorrelation.df
@emlPearsonCorrelation: leg6xB#, leg6yB#, 2
@emit: "leg6", "scope_label_B", "group B"
@emitNum: "leg6", "r_B", emlPearsonCorrelation.r
@emitNum: "leg6", "p_B", emlPearsonCorrelation.p

# Door B: the scatter's own per-group annotation block -- same kernel,
# same call shape (graphs/eml-draw-procedures.praat:5117 calls
# @emlReportCorrelationAnalysis exactly as the dialog's per-group loop
# does), run again under its own name so the TSV shows two independent
# calls agreeing rather than one call read twice.
@emlPearsonCorrelation: leg6xA#, leg6yA#, 2
@emit: "leg6", "door2", "scatter_draw"
@emitNum: "leg6", "r_A_door2", emlPearsonCorrelation.r
@emlPearsonCorrelation: leg6xB#, leg6yB#, 2
@emitNum: "leg6", "r_B_door2", emlPearsonCorrelation.r

# The pooled figure neither door claims to show -- present so the
# adversarial gap (per-group vs pooled) is on the record, not merely
# implied.
@emlPearsonCorrelation: leg6xAll#, leg6yAll#, 2
@emit: "leg6", "pooled_scope_label", "pooled (neither door draws this)"
@emitNum: "leg6", "r_pooled", emlPearsonCorrelation.r
@emitNum: "leg6", "p_pooled", emlPearsonCorrelation.p

appendFileLine: outPath$, "DONE", tab$, "DONE", tab$, "DONE"
writeInfoLine: "DOORCENSUS wrote ", outPath$
