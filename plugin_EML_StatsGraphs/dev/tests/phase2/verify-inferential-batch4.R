# ============================================================================
# EML Stats : R Verification Script — Inferential Statistics (Batch 4)
# ============================================================================
# Independent verification of reference values for:
#   @emlRankBiserialR and @emlMatchedPairsR
#
# Run this script in R to confirm that our Praat test expectations
# match an independent statistical implementation.
#
# r values are deterministic arithmetic on U1/U2 (or T+/T-) and ranks.
# Since the ranking algorithm is standard, these should match exactly.
#
# NOTE on p-values: Our Praat procedure uses its own exact DP / normal
# approximation with specific continuity and tie correction. R's
# wilcox.test may give slightly different p-values. This script verifies
# the effect size r values, not p-values (those are already verified
# in Batch 3).
#
#
# Version: 1.1
# Date: 2 August 2026
#
# CHANGELOG
# 1.1 (2 Aug 2026) - Removed a structural false green. check() returned
#     silently on an NA result, so a check that never ran was
#     indistinguishable from one that passed and the file could still
#     print its all-clear banner. Skips are now registered, counted,
#     echoed in the summary, and the banner degrades to INCOMPLETE.
#     Added the shared exit-code contract (0 pass / 1 fail / 2 incomplete).
# 1.0 (3 Mar 2026) - Initial.
# ============================================================================

cat("==================================================\n")
cat("EML Stats Batch 4 — R Verification\n")
cat("==================================================\n\n")

pass <- 0
fail <- 0
skipped <- 0
skip_reasons <- character(0)

# A skipped check must never be able to read as a pass. Every skip registers
# itself here, and the final banner is gated on skipped == 0 as well as
# fail == 0.
register_skip <- function(reason) {
  skipped <<- skipped + 1
  skip_reasons <<- c(skip_reasons, reason)
  cat(sprintf("  SKIP: %s\n", reason))
}

check <- function(label, expected, actual, tol=0.001) {
  if (is.na(actual) || is.na(expected)) {
    register_skip(sprintf("%s (NA result - check not performed)", label))
    return(invisible(NULL))
  }
  if (abs(expected - actual) <= tol) {
    assign("pass", get("pass", envir=.GlobalEnv) + 1, envir=.GlobalEnv)
    cat(sprintf("  PASS: %s (expected=%.6f, got=%.6f)\n", label, expected, actual))
  } else {
    assign("fail", get("fail", envir=.GlobalEnv) + 1, envir=.GlobalEnv)
    cat(sprintf("  FAIL: %s (expected=%.8f, got=%.8f)\n", label, expected, actual))
  }
}

# Helper: compute rank-biserial r matching our Praat procedure
# r = (U1 - U2) / (n1 * n2)
# where U1 = R1 - n1*(n1+1)/2, R1 = rank sum of group 1
rank_biserial_r <- function(v1, v2) {
  n1 <- length(v1)
  n2 <- length(v2)
  combined <- c(v1, v2)
  ranks <- rank(combined, ties.method = "average")
  r1 <- sum(ranks[1:n1])
  u1 <- r1 - n1 * (n1 + 1) / 2
  u2 <- n1 * n2 - u1
  r <- (u1 - u2) / (n1 * n2)
  return(list(r = r, u1 = u1, u2 = u2))
}

# Helper: compute matched-pairs r matching our Praat procedure
# r = (T+ - T-) / S where S = n_nonzero * (n_nonzero + 1) / 2
matched_pairs_r <- function(v1, v2) {
  diffs <- v1 - v2
  nonzero <- diffs[diffs != 0]
  n_nonzero <- length(nonzero)
  if (n_nonzero == 0) return(list(r = NA, t_plus = NA, t_minus = NA))

  abs_diffs <- abs(nonzero)
  ranks <- rank(abs_diffs, ties.method = "average")
  t_plus <- sum(ranks[nonzero > 0])
  t_minus <- sum(ranks[nonzero < 0])
  s_max <- n_nonzero * (n_nonzero + 1) / 2
  r <- (t_plus - t_minus) / s_max
  return(list(r = r, t_plus = t_plus, t_minus = t_minus, s_max = s_max,
              n_nonzero = n_nonzero))
}


# ══════════════════════════════════════════════════════════════════════════════
# RANK-BISERIAL r
# ══════════════════════════════════════════════════════════════════════════════

cat("--- Rank-Biserial r (exact path) ---\n")

res <- rank_biserial_r(c(1,2,3), c(4,5,6,7))
check("RBS-1.1 r (g2>g1)", -1.0, res$r, 1e-6)

res <- rank_biserial_r(c(1,2,3,4), c(2,3,5,6))
check("RBS-1.2 r (ties)", -0.5, res$r, 1e-6)

res <- rank_biserial_r(c(10,20,30), c(1,2,3))
check("RBS-1.3 r (g1>>g2)", 1.0, res$r, 1e-6)

res <- rank_biserial_r(c(1,2,3), c(10,20,30))
check("RBS-1.4 r (g1<<g2)", -1.0, res$r, 1e-6)

res <- rank_biserial_r(c(1,2,3,4,5), c(1,2,3,4,5))
check("RBS-1.5 r (identical)", 0.0, res$r, 1e-6)

res <- rank_biserial_r(c(5.1,4.9,5.3,4.8,5.0,5.2,4.7,5.4),
                        c(5.0,5.1,4.8,5.2,4.9,5.3,5.1,4.7))
check("RBS-1.6 r (overlapping)", 0.09375, res$r, 1e-4)

res <- rank_biserial_r(c(5), c(3))
check("RBS-1.8 r (minimal)", 1.0, res$r, 1e-6)

res <- rank_biserial_r(c(8,9,10,11,12), c(1,2,3))
check("RBS-1.9 r (unequal)", 1.0, res$r, 1e-6)

cat("\n--- Rank-Biserial r (approximation path) ---\n")

res <- rank_biserial_r(c(2.1,3.4,4.5,5.2,6.1,7.3,8.0,9.1,10.2,11.5,12.0),
                        c(1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0,9.0,10.0))
check("RBS-2.1 r (large)", 0.33636, res$r, 1e-4)

cat("\n--- Direction consistency ---\n")
res_fwd <- rank_biserial_r(c(10,20,30), c(1,2,3))
res_rev <- rank_biserial_r(c(1,2,3), c(10,20,30))
check("RBS-7.1 sign flips", res_fwd$r, -res_rev$r, 1e-6)


# ══════════════════════════════════════════════════════════════════════════════
# MATCHED-PAIRS r
# ══════════════════════════════════════════════════════════════════════════════

cat("\n--- Matched-Pairs r (exact path) ---\n")

res <- matched_pairs_r(c(1.2,3.4,5.6,7.8,9.0), c(0.5,2.1,4.3,6.5,8.7))
check("MPR-4.1 r (all positive)", 1.0, res$r, 1e-6)
check("MPR-4.1 T+", 15.0, res$t_plus, 1e-6)

res <- matched_pairs_r(c(10,20,15,25,30), c(12,18,22,20,28))
check("MPR-4.2 r (mixed)", 0.06667, res$r, 1e-3)
check("MPR-4.2 T+", 8.0, res$t_plus, 1e-6)
check("MPR-4.2 T-", 7.0, res$t_minus, 1e-6)

res <- matched_pairs_r(c(10,20,30,40,50), c(1,2,3,4,5))
check("MPR-4.3 r (concordance)", 1.0, res$r, 1e-6)

res <- matched_pairs_r(c(1,2,3,4,5), c(10,20,30,40,50))
check("MPR-4.4 r (all neg)", -1.0, res$r, 1e-6)

res <- matched_pairs_r(c(10,20,30,40,50), c(10,18,30,35,55))
check("MPR-4.5 r (zero diffs)", 0.16667, res$r, 1e-3)
check("MPR-4.5 n_nonzero", 3, res$n_nonzero, 1e-6)

res <- matched_pairs_r(c(5,10), c(3,7))
check("MPR-4.7 r (minimal n=2)", 1.0, res$r, 1e-6)

res <- matched_pairs_r(c(10,20,30,40,50,60), c(8,18,28,38,52,57))
check("MPR-4.8 r (ties)", 0.71429, res$r, 1e-3)
check("MPR-4.8 T+", 18.0, res$t_plus, 1e-6)
check("MPR-4.8 T-", 3.0, res$t_minus, 1e-6)

cat("\n--- Matched-Pairs r (approximation path) ---\n")

v1_l <- c(12.1,14.3,11.8,15.2,13.7,16.0,12.5,14.8,
           13.1,15.5,11.9,14.0,16.2,13.3,15.8,12.7,
           14.5,11.6,15.0,13.9)
v2_l <- c(10.5,12.1,10.2,13.0,11.5,13.8,10.9,12.6,
           11.0,13.3,10.0,11.8,14.0,11.2,13.5,10.5,
           12.3,9.8,12.8,11.7)

res <- matched_pairs_r(v1_l, v2_l)
check("MPR-5.1 r (large)", 1.0, res$r, 1e-6)
check("MPR-5.1 T+", 210.0, res$t_plus, 1e-6)

# rZ verification: compute z matching our Praat procedure
# (normal approximation with continuity and tie correction)
diffs <- v1_l - v2_l
nonzero <- diffs[diffs != 0]
n_nz <- length(nonzero)
abs_d <- abs(nonzero)
ranks_d <- rank(abs_d, ties.method = "average")
t_plus <- sum(ranks_d[nonzero > 0])
expected_t <- n_nz * (n_nz + 1) / 4
var_t <- n_nz * (n_nz + 1) * (2 * n_nz + 1) / 24

# Tie correction
tab <- table(ranks_d)
tie_sizes <- as.numeric(tab)
tie_corr <- sum(tie_sizes^3 - tie_sizes) / 48
var_t_corr <- var_t - tie_corr

# Continuity correction
if (t_plus > expected_t) {
  z_num <- t_plus - 0.5 - expected_t
} else if (t_plus < expected_t) {
  z_num <- t_plus + 0.5 - expected_t
} else {
  z_num <- 0
}
z <- z_num / sqrt(var_t_corr)
rZ <- z / sqrt(n_nz)
cat(sprintf("  INFO: MPR-5.1 z=%.8f, rZ=%.8f\n", z, rZ))
check("MPR-5.1 rZ", 0.88201, rZ, 1e-3)

# Near-zero effect
v1_n <- c(5.1,4.9,5.3,4.8,5.0,5.2,4.7,5.4,5.0,4.6,5.5,4.8,5.1,5.3,4.9,5.2)
v2_n <- c(5.0,5.1,4.8,5.2,4.9,5.3,5.1,4.7,5.2,4.8,5.0,5.1,4.9,5.2,5.0,4.8)
res <- matched_pairs_r(v1_n, v2_n)
check("MPR-5.2 r (near-zero)", 0.07353, res$r, 1e-3)

# rZ for near-zero
diffs2 <- v1_n - v2_n
nonzero2 <- diffs2[diffs2 != 0]
n_nz2 <- length(nonzero2)
abs_d2 <- abs(nonzero2)
ranks_d2 <- rank(abs_d2, ties.method = "average")
t_plus2 <- sum(ranks_d2[nonzero2 > 0])
expected_t2 <- n_nz2 * (n_nz2 + 1) / 4
var_t2 <- n_nz2 * (n_nz2 + 1) * (2 * n_nz2 + 1) / 24
tab2 <- table(ranks_d2)
tie_sizes2 <- as.numeric(tab2)
tie_corr2 <- sum(tie_sizes2^3 - tie_sizes2) / 48
var_t2_corr <- var_t2 - tie_corr2
if (t_plus2 > expected_t2) {
  z_num2 <- t_plus2 - 0.5 - expected_t2
} else if (t_plus2 < expected_t2) {
  z_num2 <- t_plus2 + 0.5 - expected_t2
} else {
  z_num2 <- 0
}
z2 <- z_num2 / sqrt(var_t2_corr)
rZ2 <- z2 / sqrt(n_nz2)
cat(sprintf("  INFO: MPR-5.2 z=%.8f, rZ=%.8f\n", z2, rZ2))
check("MPR-5.2 rZ (near-zero)", 0.05841, rZ2, 1e-3)

cat("\n--- Direction consistency ---\n")
res_fwd <- matched_pairs_r(c(10,20,30,40,50), c(1,2,3,4,5))
res_rev <- matched_pairs_r(c(1,2,3,4,5), c(10,20,30,40,50))
check("MPR-7.2 sign flips", res_fwd$r, -res_rev$r, 1e-6)


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

cat("\n==================================================\n")
cat(sprintf("TOTAL: %d PASS, %d FAIL, %d SKIP\n", pass, fail, skipped))
cat(sprintf("R %s.%s\n", R.version$major, R.version$minor))

if (fail > 0) {
  cat("*** FAILURES DETECTED ***\n")
} else if (skipped > 0) {
  cat(sprintf("INCOMPLETE - %d check(s) skipped, 0 failed.\n", skipped))
  for (r in skip_reasons) cat(sprintf("  * %s\n", r))
  cat("This run does NOT constitute verification of the skipped checks.\n")
} else {
  cat("All checks passed.\n")
}
cat("==================================================\n")

# Exit-code contract, shared by every verifier in this directory:
#   0 = all checks performed and passed
#   1 = at least one check FAILED
#   2 = no failures, but at least one check was SKIPPED (incomplete)
# A runner must not collapse 2 into 0. Skips here are structural (R cannot
# compute the quantity), not transient, so 2 is the expected steady state
# for some files - the point is that it can never be mistaken for green.
if (fail > 0) quit(status = 1)
if (skipped > 0) quit(status = 2)
quit(status = 0)
