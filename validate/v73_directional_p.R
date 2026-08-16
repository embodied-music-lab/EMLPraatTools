# ============================================================================
# v73_directional_p.R -- the sign-reversal matrix, read out of a committed
#                        capture and settled against R
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. Until 16 August 2026 every parametric kernel in
# plugin/stats/eml-inferential.praat computed its one-tailed p as
#
#     .absT = abs (.t)
#     .p    = studentQ (.absT, .df)
#
# the smaller tail of the ABSOLUTE statistic. A number computed from |t| does
# not move when the two groups are exchanged, so a test whose stated
# alternative is directional returned .0227 for (A, B) and .0227 again for
# (B, A). Whichever way the data happened to fall was reported as the
# direction the analyst had predicted.
#
# THE MEASUREMENT IS THE SECOND RUN, NOT THE FIRST. Every number the
# defective kernel printed was individually plausible: .0227 IS the correct
# one-tailed p for the direction the data actually took. Nothing about a
# single run is wrong, which is why the defect survived a suite that was green
# on 72 validators. It has a symptom only when the same data is put through
# the same procedure with its two arguments exchanged, and the two answers are
# compared. That comparison is this file, and evidence/info/
# v73_directional_info.txt exists so that it can be made against a capture
# rather than against a live process.
#
# WHAT THIS COVERS THAT v77_one_tailed_direction.R DOES NOT. Both files are
# v73 and both are about the same repair; they are not the same evidence.
# That file drives Praat LIVE from R, which is what lets it sweep counter-
# factual kernels and measure studentQ on the binary. Nothing it reads
# survives the run. This file is the suite's ordinary shape and the one
# REGISTRY states as the rule: a number the plugin PRINTED, read out of a
# COMMITTED capture, against a number R computes from the same COMMITTED
# input. It therefore keeps working on a machine with no Praat at all, and a
# reviewer can diff the capture between releases. Where they overlap they
# should agree; where they disagree, one of the two is reading a tree the
# other is not, and that is worth knowing.
#
# THE PAIR OF COMMITTED FILES:
#     evidence/csv/v73_directional_input.csv   the data, long format
#     evidence/info/v73_directional_info.txt   what the plugin printed from it
# produced by  bash harness/directional/run.sh  on Praat 6.6.30. The capture
# carries the version it was driven on and section 1 asserts it, because a p
# is a property of a tail function and this file's entire subject is which
# tail that function returns.
#
# FULL PRECISION IN THE CAPTURE IS DELIBERATE AND IS NOT A DISPLAY-STANDARD
# BREACH. The 15 August ruling -- four decimals, no raw double in the Info
# window -- governs the REPORT layer. This capture is a harness transcript
# with one reader, and at four decimals the defect is invisible: .0227 and
# .0227 agree to four decimals whether the second came from the repaired
# kernel or from abs(). See the header of harness/directional/
# directional_drive.praat.
#
# ---------------------------------------------------------------------------
# WHAT THE PRE-FIX KERNEL WOULD HAVE PRINTED, family by family. Every one of
# these is the number this file now asserts is NOT there.
#
#   family      pre-fix .p at tails = 1, BOTH DIRECTIONS   repaired fwd .p
#   Welch       0.022732309485465237                       0.9772676905145348
#   Student     0.017632601737540027                       0.98236739826246
#   paired      0.0004583737571992018                      0.9995416262428009
#   Pearson     0.0003185959242512343                      0.0003185959242512343
#   Spearman    0.001259736201897353                       0.001259736201897353
#   perfect r=-1  0                                        1
#
# Read the Pearson and Spearman rows carefully: forward, the repaired kernel
# prints the SAME NUMBER the defect did, because forward is the direction the
# data took. That is the trap this file is built around, and it is why the
# forward run alone proves nothing. What separates the two kernels there is
# the REVERSED run -- pre-fix 0.0003185959242512343 again, repaired
# 0.9996814040757488 -- and the pGreater/pLess fields, which the pre-fix
# kernel did not have at all.
#
# The pre-fix kernel exposed no .pGreater and no .pLess. A driver asking for
# them against that kernel does not print a wrong number, it aborts on an
# unknown symbol -- which is a real break-test result but a weak one, since it
# proves nothing about arithmetic. So the break test below restores the DEFECT
# rather than the FILE: the two fields are kept and both are fed
# studentQ(|t|, df), which is exactly the number the pre-fix .p carried, and
# the driver still runs end to end.
#
# THE BREAK TEST, 16 August 2026, watched red and restored. A copy of
# plugin/ under /tmp/wf_v73 had the three parametric kernels reverted to the
# absolute-t form (@emlTTest, @emlTTestPaired, @eml_pearsonCore -- Spearman
# and all four Alt entry points inherit through those kernels), the perfect
# branch reverted to p = 0 regardless of the sign of r, the capture re-driven
# through EML_PLUGIN_DIR onto the committed path, and this file run:
#
#     181 checks, 142 passed, 39 FAILED
#
# Red in EVERY ONE of the five families, in the perfect-effect section, and in
# the named entry points:
#   Welch 6   Student 6   paired 6   Pearson 6   Spearman 6
#   perfect 8   Alt 1
# The clearest single line it prints is the reversal check, which quotes both
# numbers it compared:
#     FAIL  welch: reversal MOVES pGreater (|0.0227323 - 0.0227323| > 0.9)
# -- the defect stated as a measurement. Restored, and the file returns to
# 181 of 181.
#
# THREE FURTHER BREAKS, each watched red and restored, because one break only
# proves the file sees ONE mistake. All four were driven the same way, and the
# counts below are what this file actually printed, not an estimate:
#
#   * THE DIRECTION INVERTED (pGreater and pLess exchanged at source, so a
#     directional test answers the mirror question): 28 red, and EVERY ONE of
#     them in section 2. Sections 3, 4 and 5 stayed completely green -- the p
#     moves, and it moves to a number that satisfies sum-to-1, satisfies the
#     reversal exchange and satisfies the doubling identity, because the
#     mirror of a valid answer is a valid-looking answer. Only the R oracle
#     catches it. THIS IS THE MOST IMPORTANT RESULT IN THIS FILE: a
#     sign-reversal matrix on its own is not sufficient evidence, and section 2
#     is not redundant with it.
#
#   * .pLess COMPUTED AS 1 - .pGreater instead of studentQ(-t): 10 red -- five
#     in section 4 and five in section 5, and NONE in section 3 and NONE
#     against R. A subtraction sums to exactly 1 by construction, so the
#     sum-to-1 invariant is blind to it by definition; and 1 - pGreater agrees
#     with R to about 7e-18 here, far inside TOL_R. What catches it is the
#     zero tolerance: 1 - 0.9772676905145348 is 0.02273230948546522967 against
#     studentQ(-t)'s 0.022732309485465236609, a gap of 6.9e-18, which is TWO
#     ULPS and which tol = 0 sees and tol = 1e-12 does not. That is the whole
#     argument for TOL_EXACT, made as a measurement. On this fixture the loss
#     is two ulps; the reason the plugin does not use the subtraction is that
#     on a small tail it is total -- 1 - (1 - 5.6e-46) is exactly 0.
#
#   * THE PERFECT BRANCH TAKING pGreater = 0 REGARDLESS OF THE SIGN OF r:
#     6 red, all in section 6, including the mirror check that exists for
#     precisely this. Nothing else in the file moves, which is why section 6
#     is not folded into the families above.
#
# WHAT COULD NOT HAVE CAUGHT THIS, AND WHY.
#
#   - v12_correlation_orchestrator.R AND v08_twogroup_orchestrator.R, which
#     read these very procedures through the shipping report. Every registered
#     menu path in the tree passes tails = 2 -- confirmed by reading the call
#     sites, not by memory -- so no report either of them can see ever carried
#     a one-tailed p. They are correct and they are blind here by
#     construction.
#
#   - v18_sweep_parity.R, the Tier B grid over 16 designed shapes. It sweeps
#     SHAPES of data through the procedures; the defect is not a property of
#     any shape. Both runs of a reversed pair are in its population and it has
#     no assertion that relates them, because relating them was not an idea
#     anyone had until the defect was found.
#
#   - THE DEV SUITES, which passed unchanged across the semantics inversion.
#     All six tails = 1 call sites in plugin/dev/tests happen to use data
#     whose observed direction is positive, so the pre-fix and repaired
#     kernels agree on every literal they assert. A suite that survives a
#     semantics change unchanged has not confirmed the semantics.
#
#   - A GOLDEN-FILE DIFF of the committed captures. There was no committed
#     capture of a one-tailed p anywhere in the tree before this one. A golden
#     file can only say "this changed"; the whole difficulty here is that
#     nothing had ever been recorded to change from.
#
# Input:  evidence/csv/v73_directional_input.csv  (committed)
#         evidence/info/v73_directional_info.txt  (committed)
# Re-drive with: bash harness/directional/run.sh
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

cap <- capture("v73_directional_info.txt")
raw <- read.csv(repo_path("evidence", "csv", "v73_directional_input.csv"),
                stringsAsFactors = FALSE)

# One reader for the whole file, with expect_hits = 1 always. Every label in
# this capture is unique by construction, and saying so turns a driver that
# starts emitting a family twice into a HALT rather than into a silent read of
# whichever copy came first -- the ambiguity helpers.R documents at .cap_fields.
pv  <- function(lab) printed(cap, lab, expect_hits = 1L)
pvs <- function(lab) printed_str(cap, lab, expect_hits = 1L)

vec <- function(fam, slot) {
    v <- raw$x[raw$fam == fam & raw$slot == slot]
    v[order(raw$idx[raw$fam == fam & raw$slot == slot])]
}

wa <- vec("welch", "a");   wb <- vec("welch", "b")
qa <- vec("paired", "a");  qb <- vec("paired", "b")
cx <- vec("corr", "x");    cy <- vec("corr", "y")
fx <- vec("perfect", "x"); fy <- vec("perfect", "y")
ma <- vec("mwu", "a");     mb <- vec("mwu", "b")

# ---------------------------------------------------------------------------
# TOLERANCES, stated once and derived rather than inherited
# ---------------------------------------------------------------------------
# TOL_R = 1e-14, for every comparison against R. Praat and R evaluate the
# incomplete beta by different routes, so agreement is bounded by accumulated
# rounding, not by algebra. Measured on this capture the largest disagreement
# in any of the 62 oracle comparisons is 5.6e-17 (Welch's two-sided p), which
# is one ulp at 0.045. 1e-14 sits two and a half orders above the worst
# observed error and eight orders BELOW the smallest quantity compared here
# (3.19e-4), so it cannot hide a direction error: the two directions of every
# family differ by at least 0.0006 and mostly by 0.95. It is not a number
# copied from another validator -- v70 uses 5e-4 on printed four-decimal
# statistics, which would be meaningless here.
#
# TOL_EXACT = 0, for the three structural invariants. This is not strictness
# for its own sake and it is not an assumption: the sums, the exchanges and
# the doubling in this capture ARE exact, and section 3's comment says why
# each one is exactly representable. A structural identity asserted at 1e-12
# is a weaker statement than the artefact supports, and it invites a future
# reader to believe float error is expected here when none has been observed.
#
# TOL_T_CORR = 1e-13, for the CORRELATION t statistic only, and it is the one
# loosened tolerance in this file so it gets its own name rather than hiding
# inside a call. The plugin computes t = r * sqrt(df / (1 - r^2)); R's
# cor.test computes r * sqrt(df) / sqrt(1 - r^2). Algebraically identical, and
# numerically not: at r = 0.9591 the subtraction 1 - r^2 loses about a decimal
# digit to cancellation and the two orderings of the divide and the square
# root round differently. Measured on this capture the gap is 2.31e-14 on the
# Pearson t and 1.33e-14 on the Spearman t -- about 3 ulp, and 3.0e-15
# RELATIVE. 1e-13 is four times the worst observed absolute gap and still
# fourteen orders below the statistic. The p-values derived from these t's
# stay at TOL_R, because a 3-ulp shift in t moves a tail of 3.19e-4 by far
# less than 1e-14; that is measured too -- those checks pass at TOL_R.
TOL_R      <- 1e-14
TOL_T_CORR <- 1e-13
TOL_EXACT  <- 0


# ===========================================================================
# 1. PROVENANCE -- the capture and the fixture are the same run
# ===========================================================================
# Every number below is compared against R's answer for a vector R read out of
# the CSV. If the driver had read a different file, or a stale one, all 62
# oracle comparisons would go red at once and none of them would say why. So
# the driver emits the length of each vector it built, and this block compares
# those against the CSV. It is the only thing in the file that can distinguish
# "the plugin is wrong" from "the two sides are looking at different data".
#
# Pre-fix kernel: identical. These checks are not about the repair and would
# have passed against it -- deliberately, so that a red result anywhere below
# can be read as being about the arithmetic.
check_true("v73", "the capture reached its end marker",
           any(trimws(cap$lines) == "V73 DIRECTIONAL DONE"))
check_true("v73", "the capture was driven on Praat 6.6.30",
           identical(pvs("praat_version"), "6.6.30"))
check("v73", "fixture: welch group a has n rows", pv("n_welch_a"), length(wa), tol = TOL_EXACT)
check("v73", "fixture: welch group b has n rows", pv("n_welch_b"), length(wb), tol = TOL_EXACT)
check("v73", "fixture: paired has n pairs",       pv("n_paired"),  length(qa), tol = TOL_EXACT)
check("v73", "fixture: correlation has n pairs",  pv("n_corr"),    length(cx), tol = TOL_EXACT)
check("v73", "fixture: perfect has n pairs",      pv("n_perfect"), length(fx), tol = TOL_EXACT)
check("v73", "fixture: mwu group a has n rows",   pv("n_mwu_a"),   length(ma), tol = TOL_EXACT)
check("v73", "fixture: mwu group b has n rows",   pv("n_mwu_b"),   length(mb), tol = TOL_EXACT)
# The paired and correlation vectors must be equal-length or the procedures
# refuse; asserted against the CSV rather than against the capture, so a
# fixture edited to ragged lengths fails here rather than inside Praat.
check_true("v73", "fixture: the paired vectors are equal length",
           length(qa) == length(qb))
check_true("v73", "fixture: the correlation vectors are equal length",
           length(cx) == length(cy))


# ===========================================================================
# 2. THE R ORACLE -- t.test and cor.test with alternative = greater and less
# ===========================================================================
# THIS IS THE SECTION THE BREAK TESTS SAY IS LOAD-BEARING. Sections 3, 4 and 5
# assert relationships AMONG the plugin's own numbers, and the second break
# above -- returning pLess where pGreater belongs -- satisfies all three of
# them while reporting the opposite conclusion. An invariant cannot tell which
# of two mirror-image answers is the right one. Only an independent
# implementation can, and that is what this section is.
#
# Pre-fix kernel: the `_pGreater`, `_pLess` and `_pOne` rows here go red in
# every family. The `_t`, `_df` and `_pTwo` rows do NOT -- the repair did not
# touch the statistic or the two-sided p, and asserting them at 1e-14 is how
# this file would catch a "repair" that moved them.

# --- Welch, forward: a vs b -----------------------------------------------
# Pre-fix: pGreater and pLess did not exist; .p at tails = 1 was
# 0.022732309485465237 -- the value that now appears as pLess, printed under
# the name of a hypothesis it does not test.
tw <- t.test(wa, wb)
check("v73", "welch fwd: t",  pv("welch_fwd_t"),  unname(tw$statistic), tol = TOL_R)
check("v73", "welch fwd: df", pv("welch_fwd_df"), unname(tw$parameter), tol = TOL_R)
check("v73", "welch fwd: two-sided p", pv("welch_fwd_pTwo"), tw$p.value, tol = TOL_R)
check("v73", "welch fwd: pGreater = t.test(a,b,greater)",
      pv("welch_fwd_pGreater"), t.test(wa, wb, alternative = "greater")$p.value, tol = TOL_R)
check("v73", "welch fwd: pLess = t.test(a,b,less)",
      pv("welch_fwd_pLess"), t.test(wa, wb, alternative = "less")$p.value, tol = TOL_R)
# .tails = 1 means the FIXED greater alternative. Pre-fix it meant "the tail
# the data happens to be in", which on this data is the LESS tail, so this
# single check separates the two kernels on its own.
check("v73", "welch fwd: tails=1 p is the GREATER alternative, not the smaller tail",
      pv("welch_fwd_pOne"), t.test(wa, wb, alternative = "greater")$p.value, tol = TOL_R)
check_true("v73", "welch fwd: tails=1 names its alternative 'greater'",
           identical(pvs("welch_fwd_alt1"), "greater"))
check_true("v73", "welch fwd: tails=2 names its alternative 'two-sided'",
           identical(pvs("welch_fwd_alt2"), "two-sided"))
check_true("v73", "welch fwd: no error was raised", identical(pvs("welch_fwd_err"), "[]"))

# --- Welch, reversed: b vs a ----------------------------------------------
# THE DEFECT'S WHOLE SIGNATURE IS HERE. Pre-fix, every p in this block was
# byte-identical to the block above; repaired, pGreater and pLess have
# exchanged and pOne has moved from 0.977 to 0.023.
tr <- t.test(wb, wa)
check("v73", "welch rev: t",  pv("welch_rev_t"),  unname(tr$statistic), tol = TOL_R)
check("v73", "welch rev: df", pv("welch_rev_df"), unname(tr$parameter), tol = TOL_R)
check("v73", "welch rev: two-sided p", pv("welch_rev_pTwo"), tr$p.value, tol = TOL_R)
check("v73", "welch rev: pGreater = t.test(b,a,greater)",
      pv("welch_rev_pGreater"), t.test(wb, wa, alternative = "greater")$p.value, tol = TOL_R)
check("v73", "welch rev: pLess = t.test(b,a,less)",
      pv("welch_rev_pLess"), t.test(wb, wa, alternative = "less")$p.value, tol = TOL_R)
check("v73", "welch rev: tails=1 p follows the arguments, not the data",
      pv("welch_rev_pOne"), t.test(wb, wa, alternative = "greater")$p.value, tol = TOL_R)

# --- Student (pooled), forward and reversed --------------------------------
# The same fixture through the other variance branch, because the repair
# touched one shared tail computation but two code paths reach it, and a
# repair applied to the Welch arm alone would pass every Welch check above.
# Pre-fix: 0.017632601737540027 both ways.
ts <- t.test(wa, wb, var.equal = TRUE)
check("v73", "student fwd: t",  pv("student_fwd_t"),  unname(ts$statistic), tol = TOL_R)
check("v73", "student fwd: df", pv("student_fwd_df"), unname(ts$parameter), tol = TOL_R)
check("v73", "student fwd: two-sided p", pv("student_fwd_pTwo"), ts$p.value, tol = TOL_R)
check("v73", "student fwd: pGreater = t.test(a,b,greater,var.equal)",
      pv("student_fwd_pGreater"),
      t.test(wa, wb, var.equal = TRUE, alternative = "greater")$p.value, tol = TOL_R)
check("v73", "student fwd: pLess = t.test(a,b,less,var.equal)",
      pv("student_fwd_pLess"),
      t.test(wa, wb, var.equal = TRUE, alternative = "less")$p.value, tol = TOL_R)
check("v73", "student fwd: tails=1 p is the GREATER alternative",
      pv("student_fwd_pOne"),
      t.test(wa, wb, var.equal = TRUE, alternative = "greater")$p.value, tol = TOL_R)
tsr <- t.test(wb, wa, var.equal = TRUE)
check("v73", "student rev: t",  pv("student_rev_t"),  unname(tsr$statistic), tol = TOL_R)
check("v73", "student rev: df", pv("student_rev_df"), unname(tsr$parameter), tol = TOL_R)
check("v73", "student rev: two-sided p", pv("student_rev_pTwo"), tsr$p.value, tol = TOL_R)
check("v73", "student rev: pGreater = t.test(b,a,greater,var.equal)",
      pv("student_rev_pGreater"),
      t.test(wb, wa, var.equal = TRUE, alternative = "greater")$p.value, tol = TOL_R)
check("v73", "student rev: pLess = t.test(b,a,less,var.equal)",
      pv("student_rev_pLess"),
      t.test(wb, wa, var.equal = TRUE, alternative = "less")$p.value, tol = TOL_R)
check("v73", "student rev: tails=1 p follows the arguments",
      pv("student_rev_pOne"),
      t.test(wb, wa, var.equal = TRUE, alternative = "greater")$p.value, tol = TOL_R)

# --- Paired, forward and reversed ------------------------------------------
# A separate procedure with its own copy of the tail computation, not a
# wrapper over @emlTTest, so it needs its own oracle rather than an argument
# from the independent case. Pre-fix: 0.0004583737571992018 both ways.
tp <- t.test(qa, qb, paired = TRUE)
check("v73", "paired fwd: t",  pv("paired_fwd_t"),  unname(tp$statistic), tol = TOL_R)
check("v73", "paired fwd: df", pv("paired_fwd_df"), unname(tp$parameter), tol = TOL_R)
check("v73", "paired fwd: two-sided p", pv("paired_fwd_pTwo"), tp$p.value, tol = TOL_R)
check("v73", "paired fwd: pGreater = t.test(a,b,paired,greater)",
      pv("paired_fwd_pGreater"),
      t.test(qa, qb, paired = TRUE, alternative = "greater")$p.value, tol = TOL_R)
check("v73", "paired fwd: pLess = t.test(a,b,paired,less)",
      pv("paired_fwd_pLess"),
      t.test(qa, qb, paired = TRUE, alternative = "less")$p.value, tol = TOL_R)
check("v73", "paired fwd: tails=1 p is the GREATER alternative",
      pv("paired_fwd_pOne"),
      t.test(qa, qb, paired = TRUE, alternative = "greater")$p.value, tol = TOL_R)
check_true("v73", "paired fwd: tails=1 names its alternative 'greater'",
           identical(pvs("paired_fwd_alt1"), "greater"))
tpr <- t.test(qb, qa, paired = TRUE)
check("v73", "paired rev: t",  pv("paired_rev_t"),  unname(tpr$statistic), tol = TOL_R)
check("v73", "paired rev: df", pv("paired_rev_df"), unname(tpr$parameter), tol = TOL_R)
check("v73", "paired rev: two-sided p", pv("paired_rev_pTwo"), tpr$p.value, tol = TOL_R)
check("v73", "paired rev: pGreater = t.test(b,a,paired,greater)",
      pv("paired_rev_pGreater"),
      t.test(qb, qa, paired = TRUE, alternative = "greater")$p.value, tol = TOL_R)
check("v73", "paired rev: pLess = t.test(b,a,paired,less)",
      pv("paired_rev_pLess"),
      t.test(qb, qa, paired = TRUE, alternative = "less")$p.value, tol = TOL_R)
check("v73", "paired rev: tails=1 p follows the arguments",
      pv("paired_rev_pOne"),
      t.test(qb, qa, paired = TRUE, alternative = "greater")$p.value, tol = TOL_R)

# --- Pearson, forward and reversed -----------------------------------------
# REVERSING A CORRELATION IS NOT EXCHANGING x AND y. r(x, y) = r(y, x), so a
# matrix built on argument order would be comparing a run with itself and
# would have passed against the defective kernel for a reason that has nothing
# to do with the repair. The direction of a correlation is the SIGN of r, so
# the reversed run is against -y. Forward and reversed then stand in exactly
# the relationship the two t-test directions do: equal |statistic|, opposite
# sign.
#
# Pre-fix: 0.0003185959242512343 both ways -- and note that forward, that is
# also the REPAIRED answer. The forward Pearson run cannot separate the two
# kernels at all; the reversed run and the pGreater/pLess pair are the whole
# of the evidence here.
cf <- cor.test(cx, cy)
check("v73", "pearson fwd: r",  pv("pearson_fwd_r"),  unname(cf$estimate), tol = TOL_R)
check("v73", "pearson fwd: t",  pv("pearson_fwd_t"),  unname(cf$statistic), tol = TOL_T_CORR)
check("v73", "pearson fwd: df", pv("pearson_fwd_df"), unname(cf$parameter), tol = TOL_R)
check("v73", "pearson fwd: two-sided p", pv("pearson_fwd_pTwo"), cf$p.value, tol = TOL_R)
check("v73", "pearson fwd: pGreater = cor.test(x,y,greater)",
      pv("pearson_fwd_pGreater"),
      cor.test(cx, cy, alternative = "greater")$p.value, tol = TOL_R)
check("v73", "pearson fwd: pLess = cor.test(x,y,less)",
      pv("pearson_fwd_pLess"),
      cor.test(cx, cy, alternative = "less")$p.value, tol = TOL_R)
check("v73", "pearson fwd: |r| < 1 so the perfect branch is NOT taken",
      pv("pearson_fwd_perfect"), 0, tol = TOL_EXACT)
ncy <- -cy
cr <- cor.test(cx, ncy)
check("v73", "pearson rev: r is negated", pv("pearson_rev_r"), unname(cr$estimate), tol = TOL_R)
check("v73", "pearson rev: t", pv("pearson_rev_t"), unname(cr$statistic), tol = TOL_T_CORR)
check("v73", "pearson rev: two-sided p", pv("pearson_rev_pTwo"), cr$p.value, tol = TOL_R)
check("v73", "pearson rev: pGreater = cor.test(x,-y,greater)",
      pv("pearson_rev_pGreater"),
      cor.test(cx, ncy, alternative = "greater")$p.value, tol = TOL_R)
check("v73", "pearson rev: pLess = cor.test(x,-y,less)",
      pv("pearson_rev_pLess"),
      cor.test(cx, ncy, alternative = "less")$p.value, tol = TOL_R)
check("v73", "pearson rev: tails=1 p is near 1, not near 0",
      pv("pearson_rev_pOne"),
      cor.test(cx, ncy, alternative = "greater")$p.value, tol = TOL_R)

# --- Spearman, forward and reversed ----------------------------------------
# THE ORACLE IS cor.test(rank(x), rank(y)) AND NOT
# cor.test(x, y, method = "spearman"). The plugin computes Spearman as Pearson
# on ranks and takes the t-approximation from the shared kernel; R's spearman
# method uses the exact AS 89 permutation distribution. On this fixture they
# are 0.0012597362018973678 and 0.0011904761904761905 -- close enough to look
# like a rounding difference and far enough apart to fail at 1e-14. That is
# the plugin's long-standing documented design, not something this repair
# changed, and it is written here so that a future reader who "corrects" the
# oracle toward method = "spearman" understands they are changing the claim
# rather than fixing the test.
#
# Pre-fix: 0.001259736201897353 both ways.
sf <- cor.test(rank(cx), rank(cy))
check("v73", "spearman fwd: rho", pv("spearman_fwd_rho"), unname(sf$estimate), tol = TOL_R)
check("v73", "spearman fwd: t",   pv("spearman_fwd_t"),   unname(sf$statistic), tol = TOL_T_CORR)
check("v73", "spearman fwd: df",  pv("spearman_fwd_df"),  unname(sf$parameter), tol = TOL_R)
check("v73", "spearman fwd: two-sided p", pv("spearman_fwd_pTwo"), sf$p.value, tol = TOL_R)
check("v73", "spearman fwd: pGreater = cor.test(rank x, rank y, greater)",
      pv("spearman_fwd_pGreater"),
      cor.test(rank(cx), rank(cy), alternative = "greater")$p.value, tol = TOL_R)
check("v73", "spearman fwd: pLess = cor.test(rank x, rank y, less)",
      pv("spearman_fwd_pLess"),
      cor.test(rank(cx), rank(cy), alternative = "less")$p.value, tol = TOL_R)
sr <- cor.test(rank(cx), rank(ncy))
check("v73", "spearman rev: rho is negated", pv("spearman_rev_rho"), unname(sr$estimate), tol = TOL_R)
check("v73", "spearman rev: two-sided p", pv("spearman_rev_pTwo"), sr$p.value, tol = TOL_R)
check("v73", "spearman rev: pGreater = cor.test(rank x, rank -y, greater)",
      pv("spearman_rev_pGreater"),
      cor.test(rank(cx), rank(ncy), alternative = "greater")$p.value, tol = TOL_R)
check("v73", "spearman rev: pLess = cor.test(rank x, rank -y, less)",
      pv("spearman_rev_pLess"),
      cor.test(rank(cx), rank(ncy), alternative = "less")$p.value, tol = TOL_R)
check("v73", "spearman rev: tails=1 p is near 1, not near 0",
      pv("spearman_rev_pOne"),
      cor.test(rank(cx), rank(ncy), alternative = "greater")$p.value, tol = TOL_R)
# AND THE ORACLE CHOICE IS ITSELF ASSERTED, so the paragraph above is not the
# only thing holding it. If a future kernel switched to the exact
# distribution, this goes red and names the reason.
check_true("v73",
           "spearman: the plugin is the t-approximation, NOT R's exact AS 89 p",
           abs(pv("spearman_fwd_pTwo") -
               suppressWarnings(cor.test(cx, cy, method = "spearman")$p.value)) > 1e-6)

# --- Mann-Whitney, the boundary family -------------------------------------
# NOT part of the repair: .tails = 1 in @emlMannWhitneyU already meant the
# fixed greater alternative, and matching it is what the repair did to the
# parametric kernels. It is here as the control that keeps sections 3 and 5
# from being vacuous -- see the comments there.
mf <- wilcox.test(ma, mb, alternative = "greater")
check("v73", "mwu fwd: U1", pv("mwu_fwd_u1"), unname(mf$statistic), tol = TOL_EXACT)
check("v73", "mwu fwd: pGreater = wilcox.test(a,b,greater)",
      pv("mwu_fwd_pGreater"), mf$p.value, tol = TOL_R)
check("v73", "mwu fwd: pLess = wilcox.test(a,b,less)",
      pv("mwu_fwd_pLess"), wilcox.test(ma, mb, alternative = "less")$p.value, tol = TOL_R)
check("v73", "mwu fwd: two-sided p", pv("mwu_fwd_pTwo"),
      wilcox.test(ma, mb)$p.value, tol = TOL_R)
check_true("v73", "mwu fwd: the exact path was taken",
           identical(pvs("mwu_fwd_method"), "exact"))
check("v73", "mwu rev: pGreater = wilcox.test(b,a,greater)",
      pv("mwu_rev_pGreater"),
      wilcox.test(mb, ma, alternative = "greater")$p.value, tol = TOL_R)
check("v73", "mwu rev: pLess = wilcox.test(b,a,less)",
      pv("mwu_rev_pLess"),
      wilcox.test(mb, ma, alternative = "less")$p.value, tol = TOL_R)


# ===========================================================================
# 3. INVARIANT: pGreater + pLess == 1, at zero tolerance
# ===========================================================================
# WHY EXACTLY 1 AND NOT "1 WITHIN 1e-12". The two tails come from studentQ(t)
# and studentQ(-t) -- two evaluations of the same continuous distribution
# function, and on 6.6.30 that function is complementary to the last bit at
# these magnitudes. Measured on this capture, all ten sums are the double
# 1.0 with a residue of exactly 0, so a tolerance would be describing an error
# that does not occur. If a future Praat loses that property this goes red and
# a human decides whether to loosen it -- which is the right way round.
#
# WHAT THIS CHECK CANNOT DO, said here rather than left to be discovered: it
# cannot distinguish pLess = studentQ(-t) from pLess = 1 - pGreater. The
# subtraction sums to exactly 1 BY CONSTRUCTION, so this section is blind to
# it by definition rather than by accident. It was one of the four breaks
# above and all thirteen checks here stayed green through it; sections 4 and 5
# are what caught it, on the two-ulp gap that only tol = 0 can see. Recorded
# so that nobody reads a green section 3 as evidence about how the tails are
# computed -- it is evidence only that they are complementary.
#
# Pre-fix kernel: there were no such fields, so nothing here existed to check.
sum1 <- function(tag) {
    g <- pv(paste0(tag, "_pGreater")); l <- pv(paste0(tag, "_pLess"))
    check("v73", sprintf("%s: pGreater + pLess is exactly 1", tag),
          g + l, 1, tol = TOL_EXACT)
}
for (tag in c("welch_fwd", "welch_rev", "student_fwd", "student_rev",
              "paired_fwd", "paired_rev", "pearson_fwd", "pearson_rev",
              "spearman_fwd", "spearman_rev")) sum1(tag)
# The perfect branch writes its tails out at their limits rather than taking
# them from studentQ, so it is a separate claim and gets its own check rather
# than being folded into the loop above.
for (tag in c("perfectneg", "perfectpos", "perfectnegrho")) sum1(tag)

# --- WHERE THE INVARIANT DOES NOT HOLD, AND WHY -----------------------------
# Mann-Whitney's exact tails are P(U <= u1) and P(U >= u1) over a DISCRETE
# null distribution. Both are closed intervals, so both contain the point mass
# at U = u1 and the two sum to 1 + P(U = u1), not to 1. That is not a defect
# and it is not something to widen a tolerance around: it is what a one-sided
# p means when the statistic is discrete, and R's wilcox.test does exactly the
# same thing.
#
# THE CHECK IS NOT DROPPED, IT IS INVERTED. On this fixture n1 = n2 = 2 and
# u1 = 2, the centre of the null, where P(U = 2) = 2/6. So the sum must be
# 4/3 EXACTLY, and asserting that value rather than merely "not 1" is what
# makes this a measurement of the point mass instead of a shrug.
#
# It also does something for the ten checks above: it proves they are
# falsifiable. A sum-to-1 assertion that no artefact in the tree ever violates
# is indistinguishable from an assertion of nothing.
mwuSum <- pv("mwu_fwd_pGreater") + pv("mwu_fwd_pLess")
check("v73",
      "mwu: pGreater + pLess = 1 + P(U = u1) = 4/3, NOT 1 (discrete null)",
      mwuSum, 4 / 3, tol = TOL_R)
check_true("v73",
           "mwu: and that sum is genuinely not 1, so section 3 is falsifiable",
           abs(mwuSum - 1) > 0.3)


# ===========================================================================
# 4. INVARIANT: reversing the arguments EXCHANGES pGreater and pLess
# ===========================================================================
# This is the sign-reversal matrix proper. Two claims, and both are needed:
#
#   (a) pGreater(fwd) == pLess(rev) and pLess(fwd) == pGreater(rev). The two
#       runs are the same test read from opposite ends, so this is an identity
#       and holds at tol = 0 -- the same double, produced by the same call on
#       the same numbers, not two roundings of one quantity.
#
#   (b) pGreater(fwd) != pGreater(rev). THIS IS THE DEFECT'S DIRECT NEGATION.
#       The pre-fix kernel satisfied (a) trivially, because it returned one
#       number for both directions and one number exchanged with itself is
#       still itself. Only (b) separates a directional test from an absolute
#       one, and the margin asserted is the observed one rather than a token
#       epsilon.
#
# Pre-fix kernel: (a) vacuously true, (b) red in all five families.
exch <- function(fam, gap) {
    f <- paste0(fam, "_fwd"); r <- paste0(fam, "_rev")
    fg <- pv(paste0(f, "_pGreater")); fl <- pv(paste0(f, "_pLess"))
    rg <- pv(paste0(r, "_pGreater")); rl <- pv(paste0(r, "_pLess"))
    check("v73", sprintf("%s: pGreater(fwd) == pLess(rev)", fam), fg, rl, tol = TOL_EXACT)
    check("v73", sprintf("%s: pLess(fwd) == pGreater(rev)", fam), fl, rg, tol = TOL_EXACT)
    check_true("v73",
               sprintf("%s: reversal MOVES pGreater (|%.6g - %.6g| > %g)", fam, fg, rg, gap),
               abs(fg - rg) > gap)
    # And the statistic itself is negated, which is what makes the exchange a
    # consequence rather than a coincidence. Pre-fix this passed: the defect
    # was in the tail taken from the statistic, never in the statistic.
    sf <- pv(paste0(f, "_", if (fam == "spearman") "rho" else if (fam == "pearson") "r" else "t"))
    sr <- pv(paste0(r, "_", if (fam == "spearman") "rho" else if (fam == "pearson") "r" else "t"))
    check("v73", sprintf("%s: the statistic is negated by reversal", fam),
          sf, -sr, tol = TOL_R)
}
# The gaps are the OBSERVED separations, quoted so a reader can see that the
# margin is 0.95 for the t-tests -- half the unit interval -- and 0.999 for
# the correlations, not a hair either side of a tolerance.
exch("welch",    0.9)
exch("student",  0.9)
exch("paired",   0.99)
exch("pearson",  0.99)
exch("spearman", 0.99)


# ===========================================================================
# 5. INVARIANT: two-sided p == 2 * min(pGreater, pLess)
# ===========================================================================
# WHERE IT HOLDS AND WHY IT IS EXACT. The two-sided p is 2 * studentQ(|t|, df)
# and min(pGreater, pLess) is whichever of studentQ(t) and studentQ(-t) took
# the absolute value's sign -- so the two sides are the SAME double multiplied
# by 2, and a multiply by a power of two is exact in binary floating point.
# tol = 0 is therefore not optimism, it is the only defensible tolerance:
# anything else would pass a kernel that computed the two-sided p by a
# different route and happened to land close.
#
# WHY IT IS WORTH CHECKING AT ALL, given the repair did not touch the
# two-sided branch. Because that is the regression risk. Every registered menu
# path in the plugin passes tails = 2, so a repair that fixed the invisible
# one-tailed API while nudging the two-sided p would have broken every
# shipping report in the tree to fix something no user could reach. This
# section and the `_pTwo` oracle checks in section 2 are the guard on that,
# and they are asserted from two independent directions: against R, and
# against the plugin's own tails.
#
# Pre-fix kernel: HELD, in all five families. These checks pass against the
# defect and are not evidence of the repair -- they are evidence that the
# repair cost nothing, which is a different claim and needs its own checks.
twoSided <- function(tag) {
    p2 <- pv(paste0(tag, "_pTwo"))
    g  <- pv(paste0(tag, "_pGreater")); l <- pv(paste0(tag, "_pLess"))
    check("v73", sprintf("%s: two-sided p == 2 * min(pGreater, pLess)", tag),
          p2, 2 * min(g, l), tol = TOL_EXACT)
}
for (tag in c("welch_fwd", "welch_rev", "student_fwd", "student_rev",
              "paired_fwd", "paired_rev", "pearson_fwd", "pearson_rev",
              "spearman_fwd", "spearman_rev")) twoSided(tag)
# And the two-sided p does NOT move under reversal -- it is the one number in
# the matrix that must be identical in both directions. Pre-fix: also true.
for (fam in c("welch", "student", "paired", "pearson", "spearman")) {
    check("v73", sprintf("%s: the two-sided p is identical in both directions", fam),
          pv(paste0(fam, "_fwd_pTwo")), pv(paste0(fam, "_rev_pTwo")), tol = TOL_EXACT)
}

# --- WHERE THE IDENTITY DOES NOT HOLD, AND WHY ------------------------------
# @emlMannWhitneyU's exact two-sided p is min(1, 2 * min(pLess, pGreater)) --
# the doubling CLAMPED at 1, because on a discrete null 2 * min can exceed 1
# and a probability cannot. On this fixture it does: min is 2/3, twice that is
# 4/3, and the reported two-sided p is exactly 1. The identity therefore fails
# here by 1/3, and the honest thing is to assert the clamp rather than to omit
# the family or to widen a tolerance until the failure fits inside it.
#
# The parametric kernels need no clamp: min(pGreater, pLess) <= 0.5 always for
# a continuous symmetric null, so 2 * min <= 1 by construction. That is why
# ten checks above can be written at tol = 0 with no clamp in sight.
mwuTwo  <- pv("mwu_fwd_pTwo")
mwuTwice <- 2 * min(pv("mwu_fwd_pGreater"), pv("mwu_fwd_pLess"))
check("v73", "mwu: 2 * min(pGreater, pLess) = 4/3, above the unit interval",
      mwuTwice, 4 / 3, tol = TOL_R)
check("v73", "mwu: the reported two-sided p is the CLAMP, exactly 1",
      mwuTwo, 1, tol = TOL_EXACT)
check_true("v73",
           "mwu: so the doubling identity genuinely fails here (by 1/3)",
           abs(mwuTwo - mwuTwice) > 0.3)


# ===========================================================================
# 6. THE WRONG-DIRECTION PERFECT EFFECT: p == 1, not 0 and not undefined
# ===========================================================================
# WHY THIS CASE IS THE HARDEST ONE. At |r| = 1 the t statistic is infinite, so
# there is no studentQ call to take a tail from and the kernel has to write
# both limits out by hand. That is the one place in the repair where the
# direction is decided by an explicit `if` on the sign of r rather than
# falling out of the arithmetic, and an explicit branch is the kind of thing
# that gets written for the case the author was thinking about and not for its
# mirror.
#
# THE FIXTURE IS CONSTRUCTED SO THE BRANCH IS REACHED, and that is not
# automatic. The kernel enters it on .rSquared >= 1, so r must be EXACTLY -1
# in double arithmetic. x = 1..5 against y = 5..1 gives centred sums of -10,
# 10 and 10, and -10 / sqrt(10 * 10) is exactly -1. Worth knowing: R's own
# cor() returns -0.99999999999999978 for the same vectors, by a different
# route, so the R oracle here recomputes r from the centred sums the way the
# kernel does rather than calling cor(). Asserted, not assumed.
dx <- fx - mean(fx); dy <- fy - mean(fy)
rExact <- sum(dx * dy) / sqrt(sum(dx * dx) * sum(dy * dy))
check_true("v73", "perfect fixture: R's centred-sum r is exactly -1",
           identical(rExact, -1))
check("v73", "perfectneg: the plugin also gets exactly -1",
      pv("perfectneg_r"), -1, tol = TOL_EXACT)
check("v73", "perfectneg: the perfect branch was entered",
      pv("perfectneg_perfect"), 1, tol = TOL_EXACT)
# t is not a number here and is printed as such. Read as a STRING: parsing it
# would turn a disclosure into an NA and the check into a tautology.
check_true("v73", "perfectneg: t is disclosed as undefined, not printed as a number",
           identical(pvs("perfectneg_t"), "--undefined--"))
# THE CHECK THIS SECTION EXISTS FOR. r = -1 is the strongest possible evidence
# AGAINST H1: r > 0. The correct greater-tail p is 1 -- certainty in the other
# direction -- and the two ways to get it wrong are both live: the pre-fix
# kernel set .p = 0 unconditionally in this branch (a perfect effect is
# significant, whichever way it points), and a kernel computing pLess as
# 1 - pGreater lands on 0 here too.
check("v73", "perfectneg: pGreater is 1 EXACTLY -- the wrong direction is certain, not significant",
      pv("perfectneg_pGreater"), 1, tol = TOL_EXACT)
check("v73", "perfectneg: pLess is 0", pv("perfectneg_pLess"), 0, tol = TOL_EXACT)
check("v73", "perfectneg: tails=1 p is 1, where the pre-fix kernel printed 0",
      pv("perfectneg_pOne"), 1, tol = TOL_EXACT)
check("v73", "perfectneg: the two-sided p is still 0 in the limit",
      pv("perfectneg_pTwo"), 0, tol = TOL_EXACT)
# THE MIRROR, so that the branch is shown to depend on the sign of r rather
# than to be constant. A kernel that hard-coded pGreater = 1 in the perfect
# branch would pass every check above and fail here.
check("v73", "perfectpos: r is exactly +1", pv("perfectpos_r"), 1, tol = TOL_EXACT)
check("v73", "perfectpos: pGreater is 0", pv("perfectpos_pGreater"), 0, tol = TOL_EXACT)
check("v73", "perfectpos: pLess is 1", pv("perfectpos_pLess"), 1, tol = TOL_EXACT)
check("v73", "perfectpos: tails=1 p is 0", pv("perfectpos_pOne"), 0, tol = TOL_EXACT)
check_true("v73",
           "perfect: the branch reads the SIGN of r (pGreater 1 vs 0 on the two mirrors)",
           pv("perfectneg_pGreater") != pv("perfectpos_pGreater"))
# Spearman reaches the identical branch through the shared kernel, on ranks.
# Asserted rather than argued, because "it shares the kernel" is a claim about
# source that a caller could stop honouring.
check("v73", "perfectnegrho: rho is exactly -1", pv("perfectnegrho_rho"), -1, tol = TOL_EXACT)
check("v73", "perfectnegrho: pGreater is 1", pv("perfectnegrho_pGreater"), 1, tol = TOL_EXACT)
check("v73", "perfectnegrho: pLess is 0", pv("perfectnegrho_pLess"), 0, tol = TOL_EXACT)


# ===========================================================================
# 7. THE NAMED ENTRY POINTS -- @...Alt agrees with the tails form
# ===========================================================================
# The repair's public advice is "prefer the Alt entry point, which names the
# alternative in words". An entry point nothing exercises is a dead door in
# exactly the sense v59 is about, and a SECOND implementation of the same
# decision is somewhere the two can drift apart. So each Alt result is
# asserted against the corresponding field of the tails-form call on the same
# data -- at tol = 0, since they should be the same double, not the same
# quantity computed twice.
#
# Pre-fix kernel: these procedures did not exist.
altPair <- function(tag, which, field) {
    check("v73", sprintf("%s: Alt '%s' p == %s from the tails form", tag, which, field),
          pv(paste0(tag, "_pAlt", if (which == "greater") "Greater" else "Less")),
          pv(paste0(tag, "_", field)), tol = TOL_EXACT)
}
for (tag in c("welch_fwd", "welch_rev", "student_fwd", "student_rev")) {
    altPair(tag, "greater", "pGreater")
    altPair(tag, "less",    "pLess")
    check_true("v73", sprintf("%s: Alt echoes the alternative it was given (greater)", tag),
               identical(pvs(paste0(tag, "_altGname")), "greater"))
    check_true("v73", sprintf("%s: Alt echoes the alternative it was given (less)", tag),
               identical(pvs(paste0(tag, "_altLname")), "less"))
}
for (tag in c("paired_fwd", "paired_rev", "pearson_fwd", "pearson_rev",
              "spearman_fwd", "spearman_rev", "perfectneg", "perfectpos",
              "perfectnegrho")) {
    altPair(tag, "less", "pLess")
}
# And 'less' is not silently the same door as 'greater'. Two entry points that
# both returned pGreater would satisfy every check above except this one.
check_true("v73",
           "Alt: 'less' and 'greater' return different p on directional data",
           pv("welch_fwd_pAltLess") != pv("welch_fwd_pAltGreater"))


# ===========================================================================
# 8. CENSUS -- every family in the capture is asserted on by something
# ===========================================================================
# The population is read OFF THE CAPTURE, not from the list the checks loop
# over, so adding a family to harness/directional/directional_drive.praat and
# forgetting to assert on it turns this red. That is the failure eml_census
# exists for and it is live here: this capture is authored alongside its
# validator, which is precisely the situation where a new block gets driven,
# committed, and never read.
labels <- sub("  .*$", "",
              grep("^[a-z][A-Za-z0-9_]*  ", trimws(cap$lines), value = TRUE))
# The header rows (n_*, praat_version) are dropped BEFORE the field suffix is
# stripped, not after. Stripping first turns "n_perfect" into "n" -- a family
# that does not exist, orphaned against a check nobody could write. Found by
# running this section, which is the only way that class of mistake surfaces.
labels <- labels[!grepl("^(n_|praat_)", labels)]
fams <- unique(sub(paste0("_(t|df|r|rho|u1|perfect|pTwo|pOne|pGreater|pLess|",
                          "alt[A-Za-z0-9]*|err|method|pAlt[A-Za-z]*)$"),
                   "", labels))
asserted <- c("welch_fwd", "welch_rev", "student_fwd", "student_rev",
              "paired_fwd", "paired_rev", "pearson_fwd", "pearson_rev",
              "spearman_fwd", "spearman_rev", "perfectneg", "perfectpos",
              "perfectnegrho", "mwu_fwd", "mwu_rev")
eml_census("v73", "family in the directional capture", fams, asserted)
# The count is stated too, so a capture that lost half its families -- which
# would satisfy the census, since the set relation only cares about what IS
# present -- goes red as well.
check("v73", "the capture holds 15 driven family x direction blocks",
      length(fams), 15, tol = TOL_EXACT)

if (!exists("EML_SUITE")) {
    eml_report("v73 directional p: the sign-reversal matrix, from a committed capture")
    eml_exit()
}
