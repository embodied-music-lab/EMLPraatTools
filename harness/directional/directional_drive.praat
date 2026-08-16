# ============================================================================
# directional_drive.praat -- the sign-reversal matrix, driven headlessly
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS PRODUCES. One Info-window capture, evidence/info/
# v73_directional_info.txt, holding every directional p the parametric
# inferential kernels compute on the committed fixture evidence/csv/
# v73_directional_input.csv -- each family run FORWARD and again with its two
# arguments EXCHANGED. validate/v73_directional_p.R reads that capture and
# nothing else about this run.
#
# WHY REVERSAL IS THE MEASUREMENT. Until 16 August 2026 the one-tailed p in
# every parametric kernel here was studentQ(abs(t), df) -- the smaller tail of
# the ABSOLUTE statistic. That number does not move when the two groups are
# exchanged, so a directional test answered .0227 whichever way round the
# hypothesis was stated. A capture that ran each family once could not show
# it: every value in it would have been perfectly plausible. It takes the
# SECOND run, with the arguments swapped, for the defect to have a symptom at
# all, and that is the only reason this driver exists rather than an extra
# block bolted onto an existing one.
#
# FULL PRECISION ON PURPOSE, AND IT IS NOT A DISPLAY-STANDARD VIOLATION. The
# author's ruling of 15 August 2026 -- statistics print at four decimals, no
# raw double reaches the Info window -- governs the REPORT layer, the text a
# user reads. This is a harness transcript whose sole reader is an R script
# comparing against R at 1e-14, and four decimals would put the tolerance
# floor five orders of magnitude above the quantity under test: .0227 and
# .0227 agree at four decimals whether the second one came from the fixed
# kernel or from the defect. So every number here goes out through string$,
# Praat's round-trip renderer, exactly as harness/sweep and harness/parity do,
# and nothing in plugin/ is asked to print this way.
#
# THE PLUGIN TREE IS NOT HARD-CODED. Praat resolves `include` at parse time
# against the TOP-LEVEL script's directory and cannot take a variable, so the
# tree under test is selected by where run.sh puts this file: it stages a
# `plugin` link beside a copy of this script and runs it there. That is what
# makes a break test possible -- point EML_PLUGIN_DIR at a corrupted copy and
# every include below follows it, with no edit here.
#
# Run:  bash harness/directional/run.sh
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

include plugin/stats/eml-core-utilities.praat
include plugin/stats/eml-core-descriptive.praat
include plugin/stats/eml-extract.praat
include plugin/stats/eml-output.praat
include plugin/stats/eml-inferential.praat

Text writing preferences: "UTF-8"

outFile$ = environment$ ("EML_V73_CAPTURE")
if outFile$ = ""
    outFile$ = "evidence/info/v73_directional_info.txt"
endif

fixture$ = environment$ ("EML_V73_FIXTURE")
if fixture$ = ""
    fixture$ = "evidence/csv/v73_directional_input.csv"
endif

tid = Read Table from comma-separated file: fixture$

# clearinfo, not merely a fresh writeFile: info$() returns the CUMULATIVE
# Info window, and the include chain above prints nothing only as long as
# nobody adds a banner to it.
clearinfo


# ---------------------------------------------------------------------------
# @v73_vec -- one numeric vector out of the long-format fixture
# ---------------------------------------------------------------------------
# The fixture is long (fam, slot, idx, x) rather than wide because a wide
# table would need padding for the families of unequal length, and a padded
# cell is a value this driver would have to decide how to drop -- a decision
# the validator could not see. Long format has no empty cells at all.
#
# Nested ifs, not `if .f$ = A and .s$ = B`: Praat does not short-circuit
# `and`, and both operands here are cheap but the habit is the point.
# ---------------------------------------------------------------------------
procedure v73_vec: .tid, .fam$, .slot$
    selectObject: .tid
    .nRows = Get number of rows
    .k = 0
    for .r from 1 to .nRows
        .f$ = Get value: .r, "fam"
        .s$ = Get value: .r, "slot"
        if .f$ = .fam$
            if .s$ = .slot$
                .k += 1
            endif
        endif
    endfor
    .n = .k
    .out# = zero# (.n)
    .k = 0
    for .r from 1 to .nRows
        .f$ = Get value: .r, "fam"
        .s$ = Get value: .r, "slot"
        if .f$ = .fam$
            if .s$ = .slot$
                .k += 1
                .cell = Get value: .r, "x"
                .out#[.k] = .cell
            endif
        endif
    endfor
endproc

# @v73_emit -- one labelled full-precision line.
# Praat cannot nest a procedure call inside an expression, so every caller
# hoists its value into a temporary first; that is why this takes a number
# and not an expression to evaluate.
procedure v73_emit: .label$, .value
    appendInfoLine: .label$, "  ", string$ (.value)
endproc

procedure v73_emitS: .label$, .value$
    appendInfoLine: .label$, "  ", .value$
endproc


@v73_vec: tid, "welch", "a"
wa# = v73_vec.out#
@v73_vec: tid, "welch", "b"
wb# = v73_vec.out#
@v73_vec: tid, "paired", "a"
qa# = v73_vec.out#
@v73_vec: tid, "paired", "b"
qb# = v73_vec.out#
@v73_vec: tid, "corr", "x"
cx# = v73_vec.out#
@v73_vec: tid, "corr", "y"
cy# = v73_vec.out#
@v73_vec: tid, "perfect", "x"
fx# = v73_vec.out#
@v73_vec: tid, "perfect", "y"
fy# = v73_vec.out#
@v73_vec: tid, "mwu", "a"
ma# = v73_vec.out#
@v73_vec: tid, "mwu", "b"
mb# = v73_vec.out#

appendInfoLine: "V73 DIRECTIONAL CAPTURE"
appendInfoLine: "praat_version  ", praatVersion$
@v73_emit: "n_welch_a", size (wa#)
@v73_emit: "n_welch_b", size (wb#)
@v73_emit: "n_paired", size (qa#)
@v73_emit: "n_corr", size (cx#)
@v73_emit: "n_perfect", size (fx#)
@v73_emit: "n_mwu_a", size (ma#)
@v73_emit: "n_mwu_b", size (mb#)
appendInfoLine: ""


# ---------------------------------------------------------------------------
# @v73_ttest -- one t-test in one direction, every directional field emitted
# ---------------------------------------------------------------------------
# .tails = 2 and .tails = 1 are BOTH driven on the same data, in that order,
# because the whole risk of the 16 August repair was that fixing the
# one-tailed p moved the two-sided one. Emitting them from separate calls
# means the capture can be read for a two-sided regression without reference
# to anything directional.
#
# @emlTTestAlt is driven beside them because it is the entry point the
# repair asks callers to prefer, and an entry point nothing exercises is a
# dead door in the sense audit finding v59 is about.
# ---------------------------------------------------------------------------
procedure v73_ttest: .tag$, .v1#, .v2#, .equalVar
    @emlTTest: .v1#, .v2#, 2, .equalVar
    .t = emlTTest.t
    .df = emlTTest.df
    .pTwo = emlTTest.p
    .alt2$ = emlTTest.alternative$
    .pG = emlTTest.pGreater
    .pL = emlTTest.pLess
    .err$ = emlTTest.error$
    @v73_emit: .tag$ + "_t", .t
    @v73_emit: .tag$ + "_df", .df
    @v73_emit: .tag$ + "_pTwo", .pTwo
    @v73_emitS: .tag$ + "_alt2", .alt2$
    @v73_emit: .tag$ + "_pGreater", .pG
    @v73_emit: .tag$ + "_pLess", .pL
    @v73_emitS: .tag$ + "_err", "[" + .err$ + "]"

    @emlTTest: .v1#, .v2#, 1, .equalVar
    .pOne = emlTTest.p
    .alt1$ = emlTTest.alternative$
    @v73_emit: .tag$ + "_pOne", .pOne
    @v73_emitS: .tag$ + "_alt1", .alt1$

    @emlTTestAlt: .v1#, .v2#, "greater", .equalVar
    .pAltG = emlTTestAlt.p
    .altG$ = emlTTestAlt.alternative$
    @v73_emit: .tag$ + "_pAltGreater", .pAltG
    @v73_emitS: .tag$ + "_altGname", .altG$

    @emlTTestAlt: .v1#, .v2#, "less", .equalVar
    .pAltL = emlTTestAlt.p
    .altL$ = emlTTestAlt.alternative$
    @v73_emit: .tag$ + "_pAltLess", .pAltL
    @v73_emitS: .tag$ + "_altLname", .altL$
    appendInfoLine: ""
endproc

procedure v73_paired: .tag$, .v1#, .v2#
    @emlTTestPaired: .v1#, .v2#, 2
    .t = emlTTestPaired.t
    .df = emlTTestPaired.df
    .pTwo = emlTTestPaired.p
    .pG = emlTTestPaired.pGreater
    .pL = emlTTestPaired.pLess
    @v73_emit: .tag$ + "_t", .t
    @v73_emit: .tag$ + "_df", .df
    @v73_emit: .tag$ + "_pTwo", .pTwo
    @v73_emit: .tag$ + "_pGreater", .pG
    @v73_emit: .tag$ + "_pLess", .pL

    @emlTTestPaired: .v1#, .v2#, 1
    .pOne = emlTTestPaired.p
    .alt1$ = emlTTestPaired.alternative$
    @v73_emit: .tag$ + "_pOne", .pOne
    @v73_emitS: .tag$ + "_alt1", .alt1$

    @emlTTestPairedAlt: .v1#, .v2#, "less"
    .pAltL = emlTTestPairedAlt.p
    @v73_emit: .tag$ + "_pAltLess", .pAltL
    appendInfoLine: ""
endproc

procedure v73_pearson: .tag$, .x#, .y#
    @emlPearsonCorrelation: .x#, .y#, 2
    .r = emlPearsonCorrelation.r
    .t = emlPearsonCorrelation.t
    .df = emlPearsonCorrelation.df
    .pTwo = emlPearsonCorrelation.p
    .pG = emlPearsonCorrelation.pGreater
    .pL = emlPearsonCorrelation.pLess
    .perfect = emlPearsonCorrelation.perfect
    @v73_emit: .tag$ + "_r", .r
    @v73_emit: .tag$ + "_t", .t
    @v73_emit: .tag$ + "_df", .df
    @v73_emit: .tag$ + "_pTwo", .pTwo
    @v73_emit: .tag$ + "_pGreater", .pG
    @v73_emit: .tag$ + "_pLess", .pL
    @v73_emit: .tag$ + "_perfect", .perfect

    @emlPearsonCorrelation: .x#, .y#, 1
    .pOne = emlPearsonCorrelation.p
    @v73_emit: .tag$ + "_pOne", .pOne

    @emlPearsonCorrelationAlt: .x#, .y#, "less"
    .pAltL = emlPearsonCorrelationAlt.p
    @v73_emit: .tag$ + "_pAltLess", .pAltL
    appendInfoLine: ""
endproc

procedure v73_spearman: .tag$, .x#, .y#
    @emlSpearmanCorrelation: .x#, .y#, 2
    .rho = emlSpearmanCorrelation.rho
    .t = emlSpearmanCorrelation.t
    .df = emlSpearmanCorrelation.df
    .pTwo = emlSpearmanCorrelation.p
    .pG = emlSpearmanCorrelation.pGreater
    .pL = emlSpearmanCorrelation.pLess
    @v73_emit: .tag$ + "_rho", .rho
    @v73_emit: .tag$ + "_t", .t
    @v73_emit: .tag$ + "_df", .df
    @v73_emit: .tag$ + "_pTwo", .pTwo
    @v73_emit: .tag$ + "_pGreater", .pG
    @v73_emit: .tag$ + "_pLess", .pL

    @emlSpearmanCorrelation: .x#, .y#, 1
    .pOne = emlSpearmanCorrelation.p
    @v73_emit: .tag$ + "_pOne", .pOne

    @emlSpearmanCorrelationAlt: .x#, .y#, "less"
    .pAltL = emlSpearmanCorrelationAlt.p
    @v73_emit: .tag$ + "_pAltLess", .pAltL
    appendInfoLine: ""
endproc

procedure v73_mwu: .tag$, .v1#, .v2#
    @emlMannWhitneyU: .v1#, .v2#, 2
    .u1 = emlMannWhitneyU.u1
    .pTwo = emlMannWhitneyU.p
    .pG = emlMannWhitneyU.pGreater
    .pL = emlMannWhitneyU.pLess
    .method$ = emlMannWhitneyU.method$
    @v73_emit: .tag$ + "_u1", .u1
    @v73_emit: .tag$ + "_pTwo", .pTwo
    @v73_emit: .tag$ + "_pGreater", .pG
    @v73_emit: .tag$ + "_pLess", .pL
    @v73_emitS: .tag$ + "_method", .method$

    @emlMannWhitneyU: .v1#, .v2#, 1
    .pOne = emlMannWhitneyU.p
    @v73_emit: .tag$ + "_pOne", .pOne
    appendInfoLine: ""
endproc


# --- Family 1: Welch, both directions --------------------------------------
@v73_ttest: "welch_fwd", wa#, wb#, 0
@v73_ttest: "welch_rev", wb#, wa#, 0

# --- Family 2: Student (pooled), same data, both directions ----------------
@v73_ttest: "student_fwd", wa#, wb#, 1
@v73_ttest: "student_rev", wb#, wa#, 1

# --- Family 3: paired, both directions -------------------------------------
@v73_paired: "paired_fwd", qa#, qb#
@v73_paired: "paired_rev", qb#, qa#

# --- Family 4: Pearson. Reversing a CORRELATION is not exchanging x and y --
# r(x, y) = r(y, x), so swapping the arguments of a correlation is not the
# reversal at all -- it is the identity, and a matrix built on it would have
# passed on the defective kernel for the wrong reason. The direction of a
# correlation is the SIGN of r, so the reversed run negates one variable.
# The forward and reversed runs therefore have equal |r| and opposite sign,
# which is the same relationship the two t-test directions have.
@v73_pearson: "pearson_fwd", cx#, cy#
negy# = - cy#
@v73_pearson: "pearson_rev", cx#, negy#

# --- Family 5: Spearman, the same reversal on ranks ------------------------
@v73_spearman: "spearman_fwd", cx#, cy#
@v73_spearman: "spearman_rev", cx#, negy#

# --- The wrong-direction perfect effect ------------------------------------
# r = -1 EXACTLY on this fixture: the kernel's centred-sum form gives
# -10 / sqrt(10 * 10), and 10 is representable, so .rSquared >= 1 holds and
# the perfect branch is entered. The whole question this case settles is what
# the perfect branch does with the tail nobody asked for: pGreater must be 1,
# not 0 and not undefined.
@v73_pearson: "perfectneg", fx#, fy#
negfy# = - fy#
@v73_pearson: "perfectpos", fx#, negfy#
@v73_spearman: "perfectnegrho", fx#, fy#

# --- The boundary family: where the two invariants legitimately fail -------
# Mann-Whitney is NOT part of the 16 August repair -- .tails = 1 already
# meant the fixed "greater" alternative there, which is what the repair made
# the parametric kernels match. It is driven here as the CONTROL that keeps
# the invariants above from being vacuous: its exact tails are P(U <= u1) and
# P(U >= u1) over a DISCRETE null, so they share the point mass at u1 and sum
# to 1 + P(U = u1), and its two-sided p is clamped at 1. On this fixture both
# exceptions fire at once.
@v73_mwu: "mwu_fwd", ma#, mb#
@v73_mwu: "mwu_rev", mb#, ma#

appendInfoLine: "V73 DIRECTIONAL DONE"

writeFile: outFile$, info$ ()
removeObject: tid

writeInfoLine: "capture written: ", outFile$
