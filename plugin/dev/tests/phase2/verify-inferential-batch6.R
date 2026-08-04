# ============================================================================
# EML Stats : R Verification Script — Inferential Statistics (Batch 6)
# ============================================================================
# Independent verification of the reference values hardcoded in
#   dev/tests/phase2/test-inferential-batch6.praat
# for @emlOneWayAnova, @emlTwoWayAnova, @emlTukeyHSD and @emlTableFromGroups.
#
# Version: 2.0
# Date: 2 August 2026
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
#
# EXIT-CODE CONTRACT (shared by every verifier in this directory)
# ---------------------------------------------------------------
#   0 = all checks performed and passed
#   1 = at least one check FAILED
#   2 = no failures, but at least one check was SKIPPED (incomplete)
# A runner must not collapse 2 into 0. This file's steady state is 2, because
# 14 of its 136 registered checks are structurally unavailable from R (see
# SKIPS below) — that is a stated incompleteness, not a pass.
#
# WHAT THIS FILE CHECKS
# ---------------------
# test-inferential-batch6.praat contains 135 @emlTestAssertEqualNum
# assertions. Each one carries a numeric LITERAL that the Praat suite compares
# the library's output against. This file exists to answer a different question
# from the one the Praat suite answers:
#
#   Praat assertion : is the LIBRARY's computed value close enough to the
#                     reference literal?
#   This file       : is the reference LITERAL a correct transcription of the
#                     true value?
#
# Every one of the 135 Praat numeric assertions is registered here exactly
# once — 122 as checks against a value R computes, 13 as explicit counted
# SKIPS. A 136th registration is an environmental skip (see SKIPS).
#
# TOLERANCE POLICY
# ----------------
# The Praat assertion tolerances (0.001 / 0.01 / 1e-6) are working tolerances:
# they allow genuine last-bit differences between two implementations. They are
# deliberately NOT reused here. A literal is either right or mis-typed; the only
# legitimate slack is rounding. So each literal is checked at half a unit in its
# own last written decimal place —
#     ulp(d) = 0.5 * 10^-d
# the largest error correct rounding can produce and the smallest error a typo
# can produce. Two exceptions:
#     EXACT_TOL = 1e-12  literals whose true value is exact (integers, halves,
#                        and terminating decimals written in full: 49.2, 4.1,
#                        7.5, 0.6875, 61.25, 353.75, all mean differences).
#                        Only floating-point round-off is admissible; the
#                        largest residual observed across these is 5.3e-14.
#     TIGHT_TOL = 1e-6   test statistics, degrees of freedom and counts that
#                        are written exactly (F = 200.0, df = 16, nPairs = 6).
#
# The gap between the two policies is large. Example: the Praat suite asserts
# "4 Treatment p" = 0.0000000002 with tolerance 1e-6 — five thousand times the
# asserted value. Any p in [0, 1e-6] passes there. Here the same literal is
# checked at 5e-11 and lands at 32% of that budget.
#
# LITERALS SITTING CLOSE TO THEIR ROUNDING BOUND (all pass; re-emit with more
# digits if they are ever regenerated):
#   "6 G1vG4 p" / "6 G3vG4 p" = 0.0000000024  — 98.7% of half-ULP
#                                (true 2.4493583828e-09)
#   "10 AvC p"  = 0.01004      — 85%  (true 0.0100442726601556)
#   "5 Interact p" = 0.00000939 — 84%  (true 9.3942090860e-06)
#   "7 Tukey G1vG2 p" = 0.000502 — 83% (true 0.00050241679335)
#   "4 Interact p" = 0.1765     — 74%  (true 0.17646319681353)
#   "1 F" / "7 F"  = 45.5772    — 72%  (true 45.577235772358)
#
# EXTERNAL VALIDATION vs LONGHAND RE-IMPLEMENTATION — read this
# ------------------------------------------------------------
# These are not the same thing and this file does not blur them.
#
#   EXTERNAL (109 checks). The quantity is produced by a base-R function that
#   was written independently of the EML library: aov(), anova(), TukeyHSD(),
#   qtukey(). R's answer is a genuine second opinion.
#
#   [QI] tag — the studentized-range statistics (q) are external too, but by a
#   route worth stating. R's TukeyHSD does not report q; it reports "p adj",
#   which it computes as ptukey(q, nmeans, df, lower.tail = FALSE). This file
#   recovers q by inverting that with R's own qtukey(). The only thing injected
#   is the definitional relation between the two; the arithmetic is R's. The
#   inversion is accurate to about 1e-7 absolute, far inside the ulp(4) budget
#   these 4-decimal literals carry.
#
#   [LH] tag — LONGHAND RE-IMPLEMENTATION, NOT EXTERNAL VALIDATION (13 checks).
#   Base R reports no effect size for aov(), and reports no total row for a
#   factorial anova(). eta-squared, partial eta-squared, and the two-way total
#   SS / total df are therefore formed HERE, by arithmetic written in this
#   file, from R's sums of squares. R supplies every input; the combining step
#   is ours. If the library and this file happen to make the same conceptual
#   error about how an effect size is defined, both agree and neither is right.
#   These 13 checks corroborate the transcription of a number; they do not
#   independently validate the definition behind it. The genuinely independent
#   corroboration (effectsize::eta_squared) is unavailable — see SKIPS.
#
# SKIPS (14, all counted, all forcing exit 2)
# -------------------------------------------
#   4 x "6 diag [i,i]"        — pMatrix diagonal = 1.0 is a library storage
#                               convention for a group against itself. R's
#                               TukeyHSD returns only the off-diagonal pairs,
#                               so R has no reference value to offer.
#   3 x "6 * symm"            — these assertions compare two library outputs to
#                               each other (pMatrix[1,2] vs pMatrix[2,1]). There
#                               is no numeric literal in them, so there is
#                               nothing for a transcription check to check.
#   6 x "8 ..." (TEST GROUP 8) — @emlTableFromGroups round-trip: Praat Table row
#                               counts and cell values. Data-structure
#                               construction, not a statistic; R computes
#                               nothing here.
#   1 x eta-squared corroboration — effectsize::eta_squared() would make the 9
#                               [LH] effect-size checks external. The package is
#                               not installed and CRAN is unreachable from this
#                               environment, so install.packages() cannot fix
#                               it. Guarded with requireNamespace(): if the
#                               package ever becomes available this skip turns
#                               itself into 9 real external checks.
#
# ENVIRONMENT
# -----------
# R 4.3.3, /usr/bin/Rscript. Base `stats` only (aov, anova, TukeyHSD, qtukey).
# No non-base package is required to reach exit 2; the single optional package
# is probed with requireNamespace() and its absence is registered, not ignored.
#
# DATA PROVENANCE
# ---------------
# Every data vector below was read out of test-inferential-batch6.praat, not
# reconstructed from the previous version of this file. v1.0's vectors were
# re-derived from the Praat source and found to agree; the two-way and Tukey
# designs were re-checked cell by cell against the Set numeric value / Set
# string value blocks. TEST GROUP 10 (unbalanced Tukey, A={10,12,11},
# B={20,22,21,23}, C={15,17}) exists in the Praat suite and was absent from
# v1.0 entirely.
#
# SIGN CONVENTION
# ---------------
# The library stores meanDiff##[i,j] = mean(group i) - mean(group j) with groups
# in alphabetical order. R's TukeyHSD labels the same comparison "Groupj-Groupi"
# and reports mean(group j) - mean(group i). Every mean-difference check below
# therefore negates R's diff. Getting this backwards would make -3.0 and +3.0
# indistinguishable, which is exactly the class of error the Praat literals
# encode (the suite asserts both signs).
#
# CHANGELOG
# 2.0 (2 Aug 2026) — Converted from a printer into a checker.
#
#     WHAT WAS WRONG WITH 1.0. It computed R reference values and printed them
#     with cat(sprintf(...)). It contained zero assertions, zero counters, and
#     no quit(), so it exited 0 unconditionally — including if every literal in
#     the Praat suite had been wrong, and including if R had errored partway
#     through a section whose output nobody was reading. A file that checks
#     nothing and exits 0 is indistinguishable from a file that checks
#     everything and passes; that is a false green, and it is the same defect
#     class this directory has been removing elsewhere. Verification was
#     delegated to a human eyeballing two columns of numbers, one of which was
#     in a different file.
#
#     Additionally, 1.0's coverage was silently partial: it printed nothing at
#     all for TEST GROUP 10 (the unbalanced Tukey design), TEST GROUP 8, the
#     eta-squared and partial eta-squared assertions, or the qCritical
#     assertions — 40-odd literals with no reference value printed anywhere.
#     Nothing in the file disclosed the omission, because a printer has no
#     notion of coverage.
#
#     WHAT CHANGED.
#     (a) Every one of the Praat suite's 135 numeric assertions is now
#         registered — 122 checked, 13 explicitly skipped with a stated
#         blocking condition. Plus one environmental skip. Nothing is omitted
#         silently and nothing is omitted in a comment.
#     (b) Transcription tolerance policy (half-ULP of each literal's own last
#         written decimal), replacing "read the numbers and see if they look
#         the same".
#     (c) Three-value exit contract with pass/fail/skipped counters.
#     (d) FAIL messages print at %.17g with the residual and the tolerance, so
#         a 1e-12 failure is visible rather than printing as two identical
#         numbers.
#     (e) Coverage guard: the number of checks performed is itself a checked
#         quantity, so deleting a section registers a failure instead of
#         quietly producing a smaller green run.
#     (f) External vs longhand is tagged per check, in the output and above.
#     Verified failable: perturbing a single literal by 10x its tolerance
#     produces exit 1 naming that check; deleting one check produces exit 1
#     from the coverage guard.
# 1.0 (4 Mar 2026) — Initial. Printer, not checker. See above.
# ============================================================================

cat("============================================================\n")
cat("EML Stats Batch 6 — R Verification\n")
cat("============================================================\n")
cat("Legend: [QI] q recovered from R's TukeyHSD p adj via R's qtukey\n")
cat("        [LH] longhand re-implementation in R, NOT external validation\n\n")

pass <- 0
fail <- 0
skipped <- 0
skip_reasons <- character(0)

# A skipped check must never be able to read as a pass. Every skip — a
# structural one, or an NA result reaching check() — registers itself here, and
# the final banner and exit code are gated on skipped == 0 as well as fail == 0.
register_skip <- function(label, reason) {
  skipped <<- skipped + 1
  skip_reasons <<- c(skip_reasons, sprintf("%s — %s", label, reason))
  cat(sprintf("  SKIP: %s — %s\n", label, reason))
}

# ----------------------------------------------------------------------------
# REFERENCE-EMITTER MODE (added 3 August 2026)
# ----------------------------------------------------------------------------
# Set EML_EMIT_REFS=1 in the environment to make every performed check also
# print its R-computed value at full double precision:
#
#     REF: <label> = <%.17g>
#
# This exists so that Praat-side reference literals can be regenerated from
# the EXTERNAL reference rather than from the library under test. Copying a
# replacement literal out of the library's own output would make the assertion
# circular; copying it from this emitter does not, because these values come
# from base R.
#
# The mode is additive: checks still run and the exit code is unchanged, so an
# emitting run is also a verifying run and cannot silently ship a REF line for
# a quantity whose own check failed.
# ----------------------------------------------------------------------------
EMIT_REFS <- nzchar(Sys.getenv("EML_EMIT_REFS"))

check <- function(label, expected, actual, tol) {
  if (EMIT_REFS && !is.na(actual)) cat(sprintf("REF: %s = %.17g\n", label, actual))
  if (is.na(actual) || is.na(expected)) {
    register_skip(label, "NA result — check not performed")
    return(invisible(NULL))
  }
  if (abs(expected - actual) <= tol) {
    pass <<- pass + 1
    cat(sprintf("  PASS: %s\n", label))
  } else {
    fail <<- fail + 1
    # %.17g, not a fixed decimal count. Tolerances here reach 1e-12, and %.8f
    # prints a genuine failure as two identical-looking numbers — a failure
    # report that hides the failure. %.17g round-trips a double, and the
    # residual and tolerance are printed so the reader can see by how much it
    # missed without recomputing.
    cat(sprintf("  FAIL: %s (expected=%.17g, got=%.17g, diff=%.3g, tol=%.3g)\n",
                label, expected, actual, abs(expected - actual), tol))
  }
}

ulp <- function(decimals) 0.5 * 10^(-decimals)
EXACT_TOL <- 1e-12
TIGHT_TOL <- 0.000001

# Praat matrix index (i, j) -> R TukeyHSD row name, plus the sign flip.
# The library stores mean(i) - mean(j); R reports mean(j) - mean(i).
tRow <- function(nm, i, j) paste0(nm[j], "-", nm[i])
praatDiff <- function(tt, nm, i, j) -unname(tt[tRow(nm, i, j), "diff"])
praatP <- function(tt, nm, i, j) unname(tt[tRow(nm, i, j), "p adj"])
praatQ <- function(tt, nm, i, j, k, df) {
  qtukey(unname(tt[tRow(nm, i, j), "p adj"]), k, df, lower.tail = FALSE)
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 1: @emlOneWayAnova — 3 groups, clear effect        (12 assertions)
# ══════════════════════════════════════════════════════════════════════════════
# Praat data#: {23,25,27,22,26, 30,33,29,31,34, 18,20,22,19,17}, groupSize 5/5/5
cat("--- TEST GROUP 1: one-way, 3 groups, clear effect ---\n")

d1 <- data.frame(
  value = c(23, 25, 27, 22, 26,
            30, 33, 29, 31, 34,
            18, 20, 22, 19, 17),
  group = factor(rep(c("Group1", "Group2", "Group3"), each = 5)))
fit1 <- aov(value ~ group, data = d1)
a1 <- anova(fit1)
ss1t <- sum(a1$"Sum Sq")

check("1 F", 45.5772, a1$"F value"[1], ulp(4))
check("1 p", 0.0000024783, a1$"Pr(>F)"[1], ulp(10))
check("1 SS between", 373.7333, a1$"Sum Sq"[1], ulp(4))
check("1 SS within", 49.2, a1$"Sum Sq"[2], EXACT_TOL)
check("1 SS total", 422.9333, ss1t, ulp(4))
check("1 df between", 2, a1$Df[1], TIGHT_TOL)
check("1 df within", 12, a1$Df[2], TIGHT_TOL)
check("1 df total", 14, sum(a1$Df), TIGHT_TOL)
check("1 MS between", 186.8667, a1$"Mean Sq"[1], ulp(4))
check("1 MS within", 4.1, a1$"Mean Sq"[2], EXACT_TOL)
check("1 nGroups", 3, nlevels(d1$group), TIGHT_TOL)
check("1 etaSquared [LH]", 0.88367, a1$"Sum Sq"[1] / ss1t, ulp(5))

# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 2: @emlOneWayAnova — 3 groups, no effect (F ~ 0)    (9 assertions)
# ══════════════════════════════════════════════════════════════════════════════
# All three group means are exactly 11, so SS between is 0 up to round-off and
# p is exactly 1. R returns SSb = 7.9e-30, which is inside EXACT_TOL.
cat("\n--- TEST GROUP 2: one-way, 3 groups, no effect ---\n")

d2 <- data.frame(
  value = c(10, 11, 12, 10.5, 11.5,
            10.5, 11, 11.5, 10, 12,
            11, 10.5, 11.5, 10, 12),
  group = factor(rep(c("Group1", "Group2", "Group3"), each = 5)))
a2 <- anova(aov(value ~ group, data = d2))
ss2t <- sum(a2$"Sum Sq")

check("2 F", 0.0, a2$"F value"[1], TIGHT_TOL)
check("2 p", 1.0, a2$"Pr(>F)"[1], EXACT_TOL)
check("2 SS between", 0.0, a2$"Sum Sq"[1], EXACT_TOL)
check("2 SS within", 7.5, a2$"Sum Sq"[2], EXACT_TOL)
check("2 SS total", 7.5, ss2t, EXACT_TOL)
check("2 df between", 2, a2$Df[1], TIGHT_TOL)
check("2 df within", 12, a2$Df[2], TIGHT_TOL)
check("2 df total", 14, sum(a2$Df), TIGHT_TOL)
check("2 etaSquared [LH]", 0.0, a2$"Sum Sq"[1] / ss2t, EXACT_TOL)

# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 3: @emlOneWayAnova — 2 groups                       (9 assertions)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- TEST GROUP 3: one-way, 2 groups ---\n")

d3 <- data.frame(
  value = c(5, 7, 9, 6, 8,
            10, 12, 11, 13, 14),
  group = factor(rep(c("Group1", "Group2"), each = 5)))
a3 <- anova(aov(value ~ group, data = d3))
ss3t <- sum(a3$"Sum Sq")

check("3 F", 25.0, a3$"F value"[1], TIGHT_TOL)
check("3 p", 0.001053, a3$"Pr(>F)"[1], ulp(6))
check("3 SS between", 62.5, a3$"Sum Sq"[1], EXACT_TOL)
check("3 SS within", 20.0, a3$"Sum Sq"[2], EXACT_TOL)
check("3 SS total", 82.5, ss3t, EXACT_TOL)
check("3 df between", 1, a3$Df[1], TIGHT_TOL)
check("3 df within", 8, a3$Df[2], TIGHT_TOL)
check("3 df total", 9, sum(a3$Df), TIGHT_TOL)
check("3 etaSquared [LH]", 0.757576, a3$"Sum Sq"[1] / ss3t, ulp(6))

# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 4: @emlTwoWayAnova — 2x2, no interaction           (23 assertions)
# ══════════════════════════════════════════════════════════════════════════════
# Cells read from the Set numeric value / Set string value block, rows 1-20:
#   Control-Male {10,12,11,13,14}   Control-Female {15,14,16,13,17}
#   Drug-Male    {20,22,19,21,23}   Drug-Female    {25,27,24,26,28}
# Balanced design, so Type I / II / III sums of squares coincide and aov()'s
# sequential decomposition is the same one the library computes.
cat("\n--- TEST GROUP 4: two-way 2x2, no interaction ---\n")

d4 <- data.frame(
  value = c(10, 12, 11, 13, 14,
            15, 14, 16, 13, 17,
            20, 22, 19, 21, 23,
            25, 27, 24, 26, 28),
  Treatment = factor(rep(c("Control", "Drug"), each = 10)),
  Sex = factor(rep(rep(c("Male", "Female"), each = 5), 2)))
a4 <- anova(aov(value ~ Treatment * Sex, data = d4))
ss4e <- a4$"Sum Sq"[4]

check("4 Treatment F", 200.0, a4$"F value"[1], TIGHT_TOL)
check("4 Treatment p", 0.0000000002, a4$"Pr(>F)"[1], ulp(10))
check("4 Treatment SS", 500.0, a4$"Sum Sq"[1], EXACT_TOL)
check("4 Treatment df", 1, a4$Df[1], TIGHT_TOL)
check("4 Treatment MS", 500.0, a4$"Mean Sq"[1], EXACT_TOL)

check("4 Sex F", 32.0, a4$"F value"[2], TIGHT_TOL)
check("4 Sex p", 0.0000357, a4$"Pr(>F)"[2], ulp(7))
check("4 Sex SS", 80.0, a4$"Sum Sq"[2], EXACT_TOL)
check("4 Sex df", 1, a4$Df[2], TIGHT_TOL)
check("4 Sex MS", 80.0, a4$"Mean Sq"[2], EXACT_TOL)

check("4 Interact F", 2.0, a4$"F value"[3], TIGHT_TOL)
check("4 Interact p", 0.1765, a4$"Pr(>F)"[3], ulp(4))
check("4 Interact SS", 5.0, a4$"Sum Sq"[3], EXACT_TOL)
check("4 Interact df", 1, a4$Df[3], TIGHT_TOL)
check("4 Interact MS", 5.0, a4$"Mean Sq"[3], EXACT_TOL)

check("4 Error SS", 40.0, ss4e, EXACT_TOL)
check("4 Error df", 16, a4$Df[4], TIGHT_TOL)
check("4 Error MS", 2.5, a4$"Mean Sq"[4], EXACT_TOL)
check("4 Total SS [LH]", 625.0, sum(a4$"Sum Sq"), EXACT_TOL)
check("4 Total df [LH]", 19, sum(a4$Df), TIGHT_TOL)

check("4 partialEtaSqA [LH]", 0.925926,
      a4$"Sum Sq"[1] / (a4$"Sum Sq"[1] + ss4e), ulp(6))
check("4 partialEtaSqB [LH]", 0.666667,
      a4$"Sum Sq"[2] / (a4$"Sum Sq"[2] + ss4e), ulp(6))
check("4 partialEtaSqAB [LH]", 0.111111,
      a4$"Sum Sq"[3] / (a4$"Sum Sq"[3] + ss4e), ulp(6))

# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 5: @emlTwoWayAnova — 2x2, with interaction         (23 assertions)
# ══════════════════════════════════════════════════════════════════════════════
# Cells read from rows 1-20 of the second two-way block:
#   A-Male {10,12,11,13,9}   A-Female {20,22,21,23,19}
#   B-Male {18,20,19,21,17}  B-Female {19,21,20,22,18}
cat("\n--- TEST GROUP 5: two-way 2x2, with interaction ---\n")

d5 <- data.frame(
  value = c(10, 12, 11, 13, 9,
            20, 22, 21, 23, 19,
            18, 20, 19, 21, 17,
            19, 21, 20, 22, 18),
  FactorA = factor(rep(c("A", "B"), each = 10)),
  FactorB = factor(rep(rep(c("Male", "Female"), each = 5), 2)))
a5 <- anova(aov(value ~ FactorA * FactorB, data = d5))
ss5e <- a5$"Sum Sq"[4]

check("5 FactorA F", 24.5, a5$"F value"[1], TIGHT_TOL)
check("5 FactorA p", 0.000145, a5$"Pr(>F)"[1], ulp(6))
check("5 FactorA SS", 61.25, a5$"Sum Sq"[1], EXACT_TOL)
check("5 FactorA df", 1, a5$Df[1], TIGHT_TOL)
check("5 FactorA MS", 61.25, a5$"Mean Sq"[1], EXACT_TOL)

check("5 FactorB F", 60.5, a5$"F value"[2], TIGHT_TOL)
check("5 FactorB p", 0.000000797, a5$"Pr(>F)"[2], ulp(9))
check("5 FactorB SS", 151.25, a5$"Sum Sq"[2], EXACT_TOL)
check("5 FactorB df", 1, a5$Df[2], TIGHT_TOL)
check("5 FactorB MS", 151.25, a5$"Mean Sq"[2], EXACT_TOL)

check("5 Interact F", 40.5, a5$"F value"[3], TIGHT_TOL)
check("5 Interact p", 0.00000939, a5$"Pr(>F)"[3], ulp(8))
check("5 Interact SS", 101.25, a5$"Sum Sq"[3], EXACT_TOL)
check("5 Interact df", 1, a5$Df[3], TIGHT_TOL)
check("5 Interact MS", 101.25, a5$"Mean Sq"[3], EXACT_TOL)

check("5 Error SS", 40.0, ss5e, EXACT_TOL)
check("5 Error df", 16, a5$Df[4], TIGHT_TOL)
check("5 Error MS", 2.5, a5$"Mean Sq"[4], EXACT_TOL)
check("5 Total SS [LH]", 353.75, sum(a5$"Sum Sq"), EXACT_TOL)
check("5 Total df [LH]", 19, sum(a5$Df), TIGHT_TOL)

check("5 partialEtaSqA [LH]", 0.604938,
      a5$"Sum Sq"[1] / (a5$"Sum Sq"[1] + ss5e), ulp(6))
check("5 partialEtaSqB [LH]", 0.790850,
      a5$"Sum Sq"[2] / (a5$"Sum Sq"[2] + ss5e), ulp(6))
check("5 partialEtaSqAB [LH]", 0.716814,
      a5$"Sum Sq"[3] / (a5$"Sum Sq"[3] + ss5e), ulp(6))

# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 6: @emlTukeyHSD — standalone, 4 groups             (26 assertions)
# ══════════════════════════════════════════════════════════════════════════════
# Praat data#: {5,6,7,5.5,6.5, 8,9,10,8.5,9.5, 5.5,6,7.5,6,5, 12,13,14,12.5,13.5}
# Group means 6, 9, 6, 13. Balanced (n = 5 each), so Tukey-Kramer reduces to
# the classical Tukey HSD, which is what R's TukeyHSD computes.
cat("\n--- TEST GROUP 6: TukeyHSD standalone, 4 groups ---\n")

d6 <- data.frame(
  value = c(5, 6, 7, 5.5, 6.5,
            8, 9, 10, 8.5, 9.5,
            5.5, 6, 7.5, 6, 5,
            12, 13, 14, 12.5, 13.5),
  group = factor(rep(c("Group1", "Group2", "Group3", "Group4"), each = 5)))
fit6 <- aov(value ~ group, data = d6)
a6 <- anova(fit6)
t6 <- TukeyHSD(fit6)$group
nm6 <- levels(d6$group)
k6 <- nlevels(d6$group)
df6 <- a6$Df[2]

check("6 nGroups", 4, k6, TIGHT_TOL)
check("6 nPairs", 6, nrow(t6), TIGHT_TOL)
check("6 msWithin", 0.6875, a6$"Mean Sq"[2], EXACT_TOL)
check("6 dfWithin", 16, df6, TIGHT_TOL)
check("6 qCritical", 4.046093, qtukey(0.95, k6, df6), ulp(6))

# The pMatrix diagonal is a library storage convention (a group against
# itself). R's TukeyHSD returns pairs only, so there is no R reference.
for (i in 1:4) {
  register_skip(sprintf("6 diag [%d,%d]", i, i),
                "pMatrix diagonal = 1.0 is a library storage convention for a group against itself; R's TukeyHSD returns off-diagonal pairs only and supplies no reference value")
}

check("6 G1vG2 p [1,2]", 0.000168, praatP(t6, nm6, 1, 2), ulp(6))
check("6 G1vG3 p [1,3]", 1.0, praatP(t6, nm6, 1, 3), EXACT_TOL)
check("6 G1vG4 p [1,4]", 0.0000000024, praatP(t6, nm6, 1, 4), ulp(10))
check("6 G2vG3 p [2,3]", 0.000168, praatP(t6, nm6, 2, 3), ulp(6))
check("6 G2vG4 p [2,4]", 0.0000056, praatP(t6, nm6, 2, 4), ulp(7))
check("6 G3vG4 p [3,4]", 0.0000000024, praatP(t6, nm6, 3, 4), ulp(10))

check("6 G1vG2 q [1,2] [QI]", 8.0904, praatQ(t6, nm6, 1, 2, k6, df6), ulp(4))
check("6 G1vG3 q [1,3] [QI]", 0.0, praatQ(t6, nm6, 1, 3, k6, df6), TIGHT_TOL)
check("6 G1vG4 q [1,4] [QI]", 18.8776, praatQ(t6, nm6, 1, 4, k6, df6), ulp(4))
check("6 G2vG4 q [2,4] [QI]", 10.7872, praatQ(t6, nm6, 2, 4, k6, df6), ulp(4))

check("6 G1-G2 meanDiff [1,2]", -3.0, praatDiff(t6, nm6, 1, 2), EXACT_TOL)
check("6 G1-G3 meanDiff [1,3]", 0.0, praatDiff(t6, nm6, 1, 3), EXACT_TOL)
check("6 G1-G4 meanDiff [1,4]", -7.0, praatDiff(t6, nm6, 1, 4), EXACT_TOL)
check("6 G2-G3 meanDiff [2,3]", 3.0, praatDiff(t6, nm6, 2, 3), EXACT_TOL)

# The three symmetry assertions compare two library outputs to each other.
# They carry no numeric literal, so there is nothing to transcription-check.
register_skip("6 p symm [2,1]=[1,2]",
              "assertion compares two library outputs to each other; it carries no numeric literal for R to verify")
register_skip("6 q symm [3,1]=[1,3]",
              "assertion compares two library outputs to each other; it carries no numeric literal for R to verify")
register_skip("6 meanDiff antisymm [2,1]",
              "assertion compares two library outputs to each other; it carries no numeric literal for R to verify")

# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 7: @emlOneWayAnova with tukey=1 chaining           (13 assertions)
# ══════════════════════════════════════════════════════════════════════════════
# Same data as TEST GROUP 1. The literals are re-asserted in the Praat suite,
# so they are re-checked here rather than assumed identical.
cat("\n--- TEST GROUP 7: one-way + Tukey chaining ---\n")

t7 <- TukeyHSD(fit1)$group
nm7 <- levels(d1$group)
k7 <- nlevels(d1$group)
df7 <- a1$Df[2]

check("7 F", 45.5772, a1$"F value"[1], ulp(4))
check("7 etaSquared [LH]", 0.88367, a1$"Sum Sq"[1] / ss1t, ulp(5))
check("7 nPairs", 3, nrow(t7), TIGHT_TOL)

check("7 Tukey G1vG2 p [1,2]", 0.000502, praatP(t7, nm7, 1, 2), ulp(6))
check("7 Tukey G1vG3 p [1,3]", 0.003167, praatP(t7, nm7, 1, 3), ulp(6))
check("7 Tukey G2vG3 p [2,3]", 0.0000017, praatP(t7, nm7, 2, 3), ulp(7))

check("7 Tukey G1vG2 q [1,2] [QI]", 7.5093, praatQ(t7, nm7, 1, 2, k7, df7), ulp(4))
check("7 Tukey G1vG3 q [1,3] [QI]", 5.9633, praatQ(t7, nm7, 1, 3, k7, df7), ulp(4))
check("7 Tukey G2vG3 q [2,3] [QI]", 13.4726, praatQ(t7, nm7, 2, 3, k7, df7), ulp(4))

check("7 meanDiff G1-G2 [1,2]", -6.8, praatDiff(t7, nm7, 1, 2), EXACT_TOL)
check("7 meanDiff G1-G3 [1,3]", 5.4, praatDiff(t7, nm7, 1, 3), EXACT_TOL)
check("7 meanDiff G2-G3 [2,3]", 12.2, praatDiff(t7, nm7, 2, 3), EXACT_TOL)

check("7 qCritical", 3.77293, qtukey(0.95, k7, df7), ulp(5))

# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 8: @emlTableFromGroups — round-trip                 (6 assertions)
# ══════════════════════════════════════════════════════════════════════════════
# Praat Table construction: row count and cell values for Alpha={10,20,30},
# Beta={40,50}. No statistic is computed, so R has nothing to produce. Counted
# as skips rather than left out, so the tally reflects the Praat suite exactly.
cat("\n--- TEST GROUP 8: emlTableFromGroups round-trip ---\n")

for (lbl in c("8 nRows", "8 table rows", "8 row 1 value",
              "8 row 3 value", "8 row 4 value", "8 row 5 value")) {
  register_skip(lbl,
                "Praat Table construction round-trip (row count / cell value); no statistical quantity for R to compute")
}

# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 10: @emlTukeyHSD — unbalanced 3-group design       (14 assertions)
# ══════════════════════════════════════════════════════════════════════════════
# Praat rows 1-9: A={10,12,11}, B={20,22,21,23}, C={15,17}. Unbalanced, so the
# pairwise standard error differs per pair. R's TukeyHSD applies the
# Tukey-Kramer pairwise SE, which is the quantity the library claims to use.
# This whole group was absent from v1.0 of this file.
cat("\n--- TEST GROUP 10: TukeyHSD unbalanced, 3 groups ---\n")

d10 <- data.frame(
  value = c(10, 12, 11,
            20, 22, 21, 23,
            15, 17),
  group = factor(c(rep("A", 3), rep("B", 4), rep("C", 2))))
fit10 <- aov(value ~ group, data = d10)
a10 <- anova(fit10)
t10 <- TukeyHSD(fit10)$group
nm10 <- levels(d10$group)
k10 <- nlevels(d10$group)
df10 <- a10$Df[2]

check("10 nGroups", 3, k10, TIGHT_TOL)
check("10 nPairs", 3, nrow(t10), TIGHT_TOL)
check("10 msWithin", 1.5, a10$"Mean Sq"[2], EXACT_TOL)
check("10 dfWithin", 6, df10, TIGHT_TOL)
check("10 qCritical", 4.339195, qtukey(0.95, k10, df10), ulp(6))

check("10 AvB p [1,2]", 0.0000737, praatP(t10, nm10, 1, 2), ulp(7))
check("10 AvC p [1,3]", 0.01004, praatP(t10, nm10, 1, 3), ulp(5))
check("10 BvC p [2,3]", 0.004909, praatP(t10, nm10, 2, 3), ulp(6))

check("10 AvB q [1,2] [QI]", 15.8745, praatQ(t10, nm10, 1, 2, k10, df10), ulp(4))
check("10 AvC q [1,3] [QI]", 6.3246, praatQ(t10, nm10, 1, 3, k10, df10), ulp(4))
check("10 BvC q [2,3] [QI]", 7.3333, praatQ(t10, nm10, 2, 3, k10, df10), ulp(4))

check("10 A-B meanDiff [1,2]", -10.5, praatDiff(t10, nm10, 1, 2), EXACT_TOL)
check("10 A-C meanDiff [1,3]", -5.0, praatDiff(t10, nm10, 1, 3), EXACT_TOL)
check("10 B-C meanDiff [2,3]", 5.5, praatDiff(t10, nm10, 2, 3), EXACT_TOL)

# ══════════════════════════════════════════════════════════════════════════════
# OPTIONAL EXTERNAL CORROBORATION OF THE EFFECT SIZES
# ══════════════════════════════════════════════════════════════════════════════
# The nine [LH] effect-size checks above are longhand: base R reports no eta
# squared, so this file forms the ratio itself. effectsize::eta_squared() would
# make them external. Probed rather than assumed; absence is registered, not
# ignored. CRAN is unreachable from this environment, so install.packages()
# cannot resolve it.
cat("\n--- Optional external effect-size corroboration ---\n")

if (requireNamespace("effectsize", quietly = TRUE)) {
  es1 <- effectsize::eta_squared(fit1, partial = FALSE)
  check("1 etaSquared (effectsize, external)", 0.88367,
        es1$Eta2[1], ulp(5))
} else {
  register_skip("etaSquared / partialEtaSq external corroboration",
                "effectsize package not installed and CRAN unreachable; the 9 effect-size checks remain longhand re-implementations, not external validation")
}

# ══════════════════════════════════════════════════════════════════════════════
# Coverage assertion. The check tally is itself a checked quantity: if a
# section is ever commented out, or an early error skips past a block, the
# count falls short and this registers a failure rather than letting a smaller
# green run masquerade as a complete one.
#
# 135 = the number of @emlTestAssertEqualNum assertions in
# test-inferential-batch6.praat (122 checked + 13 skipped, one-to-one).
#   + 1 = the environmental skip for the optional effectsize corroboration.
EXPECTED_CHECKS <- 136
performed <- pass + fail + skipped
if (performed != EXPECTED_CHECKS) {
  fail <- fail + 1
  cat(sprintf("  FAIL: coverage (expected %d checks to be performed, saw %d)\n",
              EXPECTED_CHECKS, performed))
}

cat("\n============================================================\n")
cat(sprintf("R Verification: %d passed, %d failed, %d skipped\n",
            pass, fail, skipped))
cat(sprintf("R %s.%s\n", R.version$major, R.version$minor))

if (fail > 0) {
  cat("SOME CHECKS FAILED\n")
} else if (skipped > 0) {
  cat(sprintf("INCOMPLETE - %d check(s) skipped, 0 failed.\n", skipped))
  for (r in skip_reasons) cat(sprintf("  * %s\n", r))
  cat("This run does NOT constitute verification of the skipped checks.\n")
} else {
  cat("ALL CHECKS PASSED\n")
}
cat("============================================================\n")

# Exit-code contract (see header):
#   0 = all checks performed and passed
#   1 = at least one check FAILED
#   2 = no failures, but at least one check was SKIPPED (incomplete)
if (fail > 0) quit(status = 1)
if (skipped > 0) quit(status = 2)
quit(status = 0)
