# ============================================================================
# EML Stats Batch 6B — R Verification Script
# ============================================================================
# Verifies pairwise t-tests, pairwise MWU, and Scheffe post-hoc
# against scipy-computed reference values baked into the Praat test suite.
#
# No special packages required — uses base R functions.
#
# Version: 1.3
# Date: 3 August 2026
#
# CHANGELOG
# 1.3 (3 Aug 2026) — Closed a coverage hole and the tolerance hole that hid it.
#     (a) The file covered only three of the suite's test groups: PT-1, PW-1
#         and Sch-1. test-inferential-batch6b.praat also asserts a PT-3 group
#         (4 groups, unequal n, Welch + Bonferroni, lines 158-176) and a Sch-3
#         group (same 4 groups, Scheffe, lines 388-401). Twelve Praat
#         assertions across those two groups had NO external reference at all.
#         Both groups are now covered.
#     (b) There was no coverage assertion, so (a) was invisible: a file that
#         verifies three groups and a file that verifies five both printed a
#         clean banner. EXPECTED_CHECKS added, matching batch1/batch6.
#     (c) Every check ran at a blanket tol=1e-4 / tol_loose=1e-3. Against a
#         literal like PT-3 adj p(1,4) = 0.00000482 that is vacuous on the R
#         side too — zero would have passed. Tolerances are now per-literal:
#         half a unit in the literal's own last written decimal place, via
#         ulp(). See TOLERANCE POLICY below.
#     (d) check() printed at %.6f, so a genuine failure below 5e-7 rendered as
#         two identical numbers. Now %.17g, matching batch1/batch3/batch6.
#     (e) Reference-emitter mode (EML_EMIT_REFS=1) documented in place.
# 1.2 (2 Aug 2026) — Corrected the characterisation of R's tied-pair behaviour
#     in the two skip messages and their surrounding comments. They said R took
#     a "tie-aware exact" path and quoted 0.015873 / 0.047619; R 4.3.3 actually
#     warns "cannot compute exact p-value with ties" and falls back to the
#     normal approximation WITH continuity correction, giving 0.015971 /
#     0.047912 (verified live). The conclusion is unchanged and in fact
#     stronger — R is not computing an exact p-value at all here, so it cannot
#     arbitrate — but the stated reason was wrong and the hardcoded figures
#     were stale.
# 1.1 (2 Aug 2026) — Removed two structural false greens. (a) The banner was
#     gated on fail == 0 only, and the file never called quit(), so Rscript
#     exited 0 even when it printed "SOME CHECKS FAILED" — a runner reading
#     the exit status could not see a failure at all. (b) The two tie-convention
#     cases, PW-1 raw_p(1,3) and PW-1 adj_p(1,3), printed a comparison with
#     cat() and asserted nothing; they incremented no counter, so 2 of 24
#     expectations were silently unverified while the file reported "ALL CHECKS
#     PASSED". Both are now registered skips. check() also gained an NA guard
#     (previously an NA propagated into `if (ok)` and aborted the run mid-file
#     with an error, losing the summary). Adopted the shared 0/1/2 exit
#     contract used by every verifier in this directory.
# 1.0 (12 Mar 2026) — Initial.
#
# TOLERANCE POLICY
#   The Praat assertion and this R check answer different questions. The Praat
#   assertion asks "is the LIBRARY's value close enough to the literal?" and
#   uses the suite's own tolerance. This file asks "is the LITERAL a correct
#   transcription of the true value?" — so it must NOT reuse the suite's
#   tolerance, which would be circular, and it must not use a blanket tolerance
#   wider than the literal's own precision, which cannot distinguish a correct
#   transcription from a wrong one.
#
#   Each literal is therefore checked at half a unit in its own last written
#   decimal place: ulp(d) = 0.5 * 10^-d for a literal written with d decimals.
#   A literal that is exactly representable (an integer, or a value the data
#   determine exactly such as a mean difference) is checked at EXACT_TOL.
#
# KNOWN CONVENTION DIFFERENCE — MWU exact path with ties:
#   Our @emlMannWhitneyU uses a no-tie null distribution for the exact
#   DP path (n1+n2 <= 20). This is the standard conservative approach:
#   the exact distribution is computed assuming no ties, and when ties
#   exist the resulting p-value is slightly conservative.
#
#   R's wilcox.test(exact=TRUE) falls back to a normal approximation
#   when ties are present (with a warning: "cannot compute exact
#   p-value with ties"). The two methods produce different p-values
#   for the same data when ties create half-integer U statistics.
#
#   Neither is wrong, but they are not the same quantity, so R cannot
#   arbitrate. Pairs where ties affect the result are registered as
#   counted SKIPs (never silent NOTEs) and the file exits 2. The Praat
#   test suite (scipy exact-path values) is the authoritative check for
#   those pairs.
#
#   For pairs without ties, R exact and our DP exact agree perfectly.
#
# Run: source("verify-inferential-batch6b.R") in RStudio
# ============================================================================

cat("==================================================\n")
cat("EML Stats Batch 6B — R Verification\n")
cat("==================================================\n\n")

pass <- 0
fail <- 0
skipped <- 0
skip_reasons <- character(0)

# Half a unit in the last written decimal place of a literal with d decimals.
ulp <- function(d) 0.5 * 10^(-d)

# For quantities the data determine exactly (integers, exact mean differences).
EXACT_TOL <- 1e-12

# A skipped check must never be able to read as a pass. Every skip — whether a
# deliberate convention-difference skip or an NA result — registers itself here,
# and the final banner is gated on skipped == 0 as well as fail == 0.
register_skip <- function(reason) {
  skipped <<- skipped + 1
  skip_reasons <<- c(skip_reasons, reason)
  cat(sprintf("  SKIP: %s\n", reason))
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

check <- function(label, expected, actual, tolerance) {
  if (EMIT_REFS && !is.na(actual)) cat(sprintf("REF: %s = %.17g\n", label, actual))
  if (is.na(expected) || is.na(actual)) {
    register_skip(sprintf("%s (NA result - check not performed)", label))
    return(invisible(NULL))
  }
  diff <- abs(expected - actual)
  ok <- diff < tolerance
  if (ok) {
    cat(sprintf("  PASS: %s (expected=%.17g, got=%.17g)\n", label, expected, actual))
    pass <<- pass + 1
  } else {
    cat(sprintf("  FAIL: %s (expected=%.17g, got=%.17g, diff=%.17g, tol=%.17g)\n",
                label, expected, actual, diff, tolerance))
    fail <<- fail + 1
  }
}

# Cohen's d with the pooled SD, matching @emlPairwiseT.
pooled_sd <- function(x, y) {
  n1 <- length(x); n2 <- length(y)
  sqrt(((n1-1)*var(x) + (n2-1)*var(y)) / (n1+n2-2))
}
cohen_d <- function(x, y) (mean(x) - mean(y)) / pooled_sd(x, y)

# ══════════════════════════════════════════════════════════════════════════════
# PAIRWISE T-TESTS — Test Set 1 (3 groups, equal n)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Pairwise Welch t (Test Set 1) ---\n")

g1 <- c(23, 25, 27, 22, 26)
g2 <- c(30, 33, 29, 31, 34)
g3 <- c(18, 20, 22, 19, 17)

# Pair (1,2)
r12 <- t.test(g1, g2, var.equal = FALSE)
check("PT-1 t(1,2)", -5.184951, r12$statistic, ulp(6))
check("PT-1 raw_p(1,2)", 0.00083766, r12$p.value, ulp(8))

# Pair (1,3)
r13 <- t.test(g1, g3, var.equal = FALSE)
check("PT-1 t(1,3)", 4.269075, r13$statistic, ulp(6))
check("PT-1 raw_p(1,3)", 0.00276291, r13$p.value, ulp(8))

# Pair (2,3)
r23 <- t.test(g2, g3, var.equal = FALSE)
check("PT-1 t(2,3)", 9.644947, r23$statistic, ulp(6))
check("PT-1 raw_p(2,3)", 0.00001155, r23$p.value, ulp(8))

# Bonferroni adjustment
raw_p <- c(r12$p.value, r13$p.value, r23$p.value)
adj_bonf <- p.adjust(raw_p, method = "bonferroni")
check("PT-1 adj_p(1,2) Bonf", 0.00251299, adj_bonf[1], ulp(8))
check("PT-1 adj_p(1,3) Bonf", 0.00828872, adj_bonf[2], ulp(8))
check("PT-1 adj_p(2,3) Bonf", 0.00003464, adj_bonf[3], ulp(8))

# Holm adjustment
adj_holm <- p.adjust(raw_p, method = "holm")
check("PT-1 adj_p(1,2) Holm", 0.00167533, adj_holm[1], ulp(8))
check("PT-1 adj_p(1,3) Holm", 0.00276291, adj_holm[2], ulp(8))
check("PT-1 adj_p(2,3) Holm", 0.00003464, adj_holm[3], ulp(8))

# Cohen's d
check("PT-1 d(1,2)", -3.279251, cohen_d(g1, g2), ulp(6))
check("PT-1 d(1,3)", 2.700000, cohen_d(g1, g3), ulp(6))
check("PT-1 d(2,3)", 6.100000, cohen_d(g2, g3), ulp(6))

# ══════════════════════════════════════════════════════════════════════════════
# PAIRWISE T-TESTS — Test Set 3 (4 groups, unequal n)
# ══════════════════════════════════════════════════════════════════════════════
# Added at v1.3. test-inferential-batch6b.praat:151-176 exercises @emlPairwiseT
# on four unequal-sized groups with Welch + Bonferroni; before v1.3 none of
# those assertions had any external reference.
#
# Pair index order is the library's: (1,2) (1,3) (1,4) (2,3) (2,4) (3,4), i.e.
# adjustedP#[1..6]. The suite asserts indices 1, 2, 3, 5, 6.
cat("\n--- Pairwise Welch t (Test Set 3) ---\n")

g7  <- c(5, 6, 7, 5, 6)
g8  <- c(8, 9, 10, 8)
g9  <- c(5, 6, 7)
g10 <- c(12, 13, 14, 12, 13, 15)

pt3_groups <- list(g7, g8, g9, g10)
pt3_pairs  <- list(c(1,2), c(1,3), c(1,4), c(2,3), c(2,4), c(3,4))
pt3_raw    <- sapply(pt3_pairs, function(p)
  t.test(pt3_groups[[p[1]]], pt3_groups[[p[2]]], var.equal = FALSE)$p.value)
pt3_adj    <- p.adjust(pt3_raw, method = "bonferroni")

check("PT-3 nPairs", 6, length(pt3_pairs), EXACT_TOL)
check("PT-3 adj_p(1,2)", 0.01638900, pt3_adj[1], ulp(8))
check("PT-3 adj_p(1,3)", 1.00000000, pt3_adj[2], ulp(8))
check("PT-3 adj_p(1,4)", 0.00000482, pt3_adj[3], ulp(8))
check("PT-3 adj_p(2,4)", 0.00145398, pt3_adj[5], ulp(8))
check("PT-3 adj_p(3,4)", 0.00162428, pt3_adj[6], ulp(8))
check("PT-3 d(1,4)", -7.120393, cohen_d(g7, g10), ulp(6))

# ══════════════════════════════════════════════════════════════════════════════
# PAIRWISE MWU
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Pairwise MWU ---\n")

# NOTE: Our @emlMannWhitneyU uses a no-tie null DP for the exact path
# (n1+n2 <= 20). R's wilcox.test handles ties differently in the
# two-tailing step, producing slightly larger p-values when ties create
# half-integer U values. Both are valid. We verify R's MWU against
# R's own values (internal consistency), then note the convention
# difference for pairs where ties affect the result.

# Test Set 1 — pairs (1,2) and (2,3) have no ties in U (integer U),
# pair (1,3) has ties (value 22 in both groups, U=24.5).
w12 <- wilcox.test(g1, g2, exact = TRUE)
w13 <- wilcox.test(g1, g3, exact = TRUE)
w23 <- wilcox.test(g2, g3, exact = TRUE)

# Pairs without tie-affected U: R exact matches our DP exactly
check("PW-1 raw_p(1,2) R exact", 0.00793651, w12$p.value, ulp(8))
check("PW-1 raw_p(2,3) R exact", 0.00793651, w23$p.value, ulp(8))

# Pair (1,3): the value 22 appears in both groups, so U is half-integer and
# wilcox.test warns "cannot compute exact p-value with ties" and silently
# falls back to the normal approximation with continuity correction
# (p = 0.015971, verified live in R 4.3.3). Our DP gives 0.007937 from a
# no-tie exact null. R is therefore not computing the same quantity at all,
# and cannot arbitrate.
register_skip(sprintf(paste0("PW-1 raw_p(1,3) not verified here: ties force wilcox.test off its ",
                             "exact path onto the normal approximation with continuity correction ",
                             "(R gives %.6f) while our no-tie exact null DP gives 0.007937. R is ",
                             "not computing an exact p-value here, so it cannot supply an ",
                             "independent exact reference for this pair; it is asserted against ",
                             "scipy in test-inferential-batch6b.praat."),
                      w13$p.value))

# Bonferroni using R's values (R-internal consistency check)
raw_p_mwu <- c(w12$p.value, w13$p.value, w23$p.value)
adj_bonf_mwu <- p.adjust(raw_p_mwu, method = "bonferroni")
check("PW-1 adj_p(1,2) Bonf (R)", 0.02380952, adj_bonf_mwu[1], ulp(8))
check("PW-1 adj_p(2,3) Bonf (R)", 0.02380952, adj_bonf_mwu[3], ulp(8))

# Our Praat adj_p(1,3) = 0.023810 (3 x 0.007937, no-tie exact DP)
# R's adj_p(1,3) = 0.047912 (3 x 0.015971, normal-approximation fallback)
# Downstream of the raw_p difference above; document, do not assert.
register_skip(sprintf(paste0("PW-1 adj_p(1,3) not verified here: R=%.6f (3 x its normal-",
                             "approximation fallback) vs our Praat 0.023810 (3 x no-tie exact ",
                             "DP). Downstream of the raw_p(1,3) difference above, so R cannot ",
                             "supply an independent reference for it either."),
                      adj_bonf_mwu[2]))

# ══════════════════════════════════════════════════════════════════════════════
# SCHEFFE
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Scheffe (Test Set 1) ---\n")

# Scheffe F and p for one pair, given the omnibus MSE / dfWithin and k groups.
scheffe_test <- function(g_i, g_j, mse, k, df_w) {
  diff <- mean(g_i) - mean(g_j)
  se <- sqrt(mse * (1/length(g_i) + 1/length(g_j)))
  f_sch <- (diff / se)^2 / (k - 1)
  p <- pf(f_sch, k - 1, df_w, lower.tail = FALSE)
  return(c(diff = diff, F = f_sch, p = p))
}

# Omnibus MSE / dfWithin from a one-way aov over the supplied groups.
omnibus <- function(groups) {
  y <- unlist(groups)
  g <- factor(rep(seq_along(groups), sapply(groups, length)))
  s <- summary(aov(y ~ g))[[1]]
  list(mse = s["Residuals", "Mean Sq"], df = s["Residuals", "Df"])
}

# Test Set 1
o1 <- omnibus(list(g1, g2, g3))
check("Sch-1 MSE", 4.1, o1$mse, EXACT_TOL)
check("Sch-1 dfWithin", 12, o1$df, EXACT_TOL)

s12 <- scheffe_test(g1, g2, o1$mse, 3, o1$df)
s13 <- scheffe_test(g1, g3, o1$mse, 3, o1$df)
s23 <- scheffe_test(g2, g3, o1$mse, 3, o1$df)

check("Sch-1 diff(1,2)", -6.8, s12["diff"], EXACT_TOL)
check("Sch-1 F(1,2)", 14.097561, s12["F"], ulp(6))
check("Sch-1 p(1,2)", 0.00070802, s12["p"], ulp(8))
check("Sch-1 diff(1,3)", 5.4, s13["diff"], EXACT_TOL)
check("Sch-1 F(1,3)", 8.890244, s13["F"], ulp(6))
check("Sch-1 p(1,3)", 0.00428052, s13["p"], ulp(8))
check("Sch-1 diff(2,3)", 12.2, s23["diff"], EXACT_TOL)
check("Sch-1 F(2,3)", 45.378049, s23["F"], ulp(6))
check("Sch-1 p(2,3)", 0.00000254, s23["p"], ulp(8))

# ══════════════════════════════════════════════════════════════════════════════
# SCHEFFE — Test Set 3 (4 groups, unequal n)
# ══════════════════════════════════════════════════════════════════════════════
# Added at v1.3, same omission as PT-3 above:
# test-inferential-batch6b.praat:381-401 had no external reference.
cat("\n--- Scheffe (Test Set 3) ---\n")

o3 <- omnibus(list(g7, g8, g9, g10))
check("Sch-3 MSE", 1.027381, o3$mse, ulp(6))
check("Sch-3 dfWithin", 14, o3$df, EXACT_TOL)

s3_13 <- scheffe_test(g7, g9,  o3$mse, 4, o3$df)
s3_14 <- scheffe_test(g7, g10, o3$mse, 4, o3$df)
s3_34 <- scheffe_test(g9, g10, o3$mse, 4, o3$df)

check("Sch-3 F(1,3)", 0.024334, s3_13["F"], ulp(6))
check("Sch-3 p(1,3)", 0.99462313, s3_13["p"], ulp(8))
check("Sch-3 F(1,4)", 48.019523, s3_14["F"], ulp(6))
check("Sch-3 p(1,4)", 0.00000013, s3_14["p"], ulp(8))
check("Sch-3 p(3,4)", 0.00000125, s3_34["p"], ulp(8))

# ══════════════════════════════════════════════════════════════════════════════
# Coverage assertion. The check tally is itself a checked quantity: if a
# section is ever commented out, or an early error skips past a block, the
# count falls short and this registers a failure rather than letting a smaller
# green run masquerade as a complete one.
#
# 44 performed checks + 2 structural skips (the two MWU tie-convention pairs).
# Breakdown: PT-1 15, PT-3 7, PW-1 4 (+2 skips), Sch-1 11, Sch-3 7.
EXPECTED_CHECKS <- 46
performed <- pass + fail + skipped
if (performed != EXPECTED_CHECKS) {
  fail <- fail + 1
  cat(sprintf("  FAIL: coverage (expected %d checks to be performed, saw %d)\n",
              EXPECTED_CHECKS, performed))
}

cat("\n==================================================\n")
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
cat("==================================================\n")

# Exit-code contract, shared by every verifier in this directory:
#   0 = all checks performed and passed
#   1 = at least one check FAILED
#   2 = no failures, but at least one check was SKIPPED (incomplete)
# A runner must not collapse 2 into 0. Skips here are structural (R cannot
# supply an independent reference), not transient, so 2 is the expected steady
# state for some files - the point is that it can never be mistaken for green.
if (fail > 0) quit(status = 1)
if (skipped > 0) quit(status = 2)
quit(status = 0)
