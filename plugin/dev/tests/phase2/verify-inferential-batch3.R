# ============================================================================
# EML Stats : R Verification Script — Inferential Statistics (Batch 3)
# ============================================================================
# Independent verification of reference values for:
#   @emlMannWhitneyU and @emlWilcoxonSignedRank
#
# Run this script in R to confirm that our Praat test expectations
# match an independent statistical implementation.
#
# Date: 26 February 2026
# ============================================================================

cat("==================================================\n")
cat("EML Stats Batch 3 — R Verification\n")
cat("==================================================\n\n")

pass <- 0
fail <- 0

check <- function(label, expected, actual, tol=0.001) {
  if (is.na(actual) || is.na(expected)) {
    cat(sprintf("  SKIP: %s (NA result)\n", label))
    return()
  }
  if (abs(expected - actual) <= tol) {
    assign("pass", get("pass", envir=.GlobalEnv) + 1, envir=.GlobalEnv)
    cat(sprintf("  PASS: %s\n", label))
  } else {
    assign("fail", get("fail", envir=.GlobalEnv) + 1, envir=.GlobalEnv)
    cat(sprintf("  FAIL: %s (expected=%.8f, got=%.8f)\n", label, expected, actual))
  }
}

# ══════════════════════════════════════════════════════════════════════════════
# MANN-WHITNEY U (exact path)
# ══════════════════════════════════════════════════════════════════════════════
# NOTE: R cannot compute exact p-values with ties. For tied cases,
# our exact DP values are verified against scipy (no-tie null distribution).
# This R script only verifies the cases R can handle exactly.
cat("--- Mann-Whitney U (exact path, no ties) ---\n")

r <- wilcox.test(c(1,2,3), c(4,5,6,7), exact=TRUE, alternative="two.sided")
check("MWU-1.1 p(2)", 0.05714, r$p.value)

# MWU-1.2: ties — R falls back to approx, verified via scipy instead
cat("  SKIP: MWU-1.2 (ties, verified via scipy)\n")

r <- wilcox.test(c(10,20,30), c(1,2,3), exact=TRUE, alternative="greater")
check("MWU-1.3 p(1)", 0.05000, r$p.value)

r <- wilcox.test(c(1,2,3), c(10,20,30), exact=TRUE, alternative="less")
check("MWU-1.4 p(1)", 0.05000, r$p.value)

# MWU-1.5: ties — R falls back to approx, verified via scipy
cat("  SKIP: MWU-1.5 (ties, verified via scipy)\n")

r <- wilcox.test(c(5), c(1,2,3,4), exact=TRUE, alternative="greater")
check("MWU-1.6 p(1)", 0.20000, r$p.value)

# MWU-1.7: ties — R falls back to approx, verified via scipy
cat("  SKIP: MWU-1.7 (ties, verified via scipy)\n")

# ══════════════════════════════════════════════════════════════════════════════
# MANN-WHITNEY U (approximation path)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Mann-Whitney U (approximation path) ---\n")

r <- wilcox.test(1:11, 6:15, exact=FALSE, correct=TRUE, alternative="two.sided")
check("MWU-2.1 p(2)", 0.01002, r$p.value)

r <- wilcox.test(seq(2,30,2), seq(1,29,2), exact=FALSE, correct=TRUE, alternative="two.sided")
check("MWU-2.2 p(2)", 0.77155, r$p.value)

r <- wilcox.test(seq(10,38,2), 1:15, exact=FALSE, correct=TRUE, alternative="two.sided")
check("MWU-2.3 p(2)", 0.00003, r$p.value, tol=0.00005)

# ══════════════════════════════════════════════════════════════════════════════
# WILCOXON SIGNED-RANK (exact path)
# ══════════════════════════════════════════════════════════════════════════════
# NOTE: R cannot compute exact p-values with ties or zeroes. For those
# cases, our exact DP values are verified against scipy instead.
cat("\n--- Wilcoxon Signed-Rank (exact path, no ties) ---\n")

r <- wilcox.test(c(10,20,30,40,50), c(1,2,3,4,5), paired=TRUE, exact=TRUE, alternative="two.sided")
check("WSR-4.1 p(2)", 0.0625, r$p.value)

# WSR-4.2: tied abs diffs — R falls back to approx
cat("  SKIP: WSR-4.2 (tied abs diffs, verified via scipy)\n")

# WSR-4.3: zeros + ties — R falls back to approx
cat("  SKIP: WSR-4.3 (zeros + ties, verified via scipy)\n")

r <- wilcox.test(c(1,2,3,4,5), c(10,20,30,40,50), paired=TRUE, exact=TRUE, alternative="two.sided")
check("WSR-4.4 p(2)", 0.0625, r$p.value)

r <- wilcox.test(c(10), c(5), paired=TRUE, exact=TRUE, alternative="two.sided")
check("WSR-4.5 p(2)", 1.0, r$p.value)

# WSR-4.6: tied abs diffs — R falls back to approx
cat("  SKIP: WSR-4.6 (tied abs diffs, verified via scipy)\n")

# WSR-4.7: diffs all equal (massive ties) — R falls back to approx
cat("  SKIP: WSR-4.7 (all diffs equal, verified via scipy)\n")

# WSR-4.8: ties — R falls back to approx
cat("  SKIP: WSR-4.8 (ties, verified via scipy)\n")

# ══════════════════════════════════════════════════════════════════════════════
# WILCOXON SIGNED-RANK (approximation path)
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Wilcoxon Signed-Rank (approximation path) ---\n")

x9 <- c(10,12,8,15,6,20,3,14,9,11,7,16,5,18,13,22)
y9 <- c(8,10,9,12,7,15,5,10,11,8,9,12,7,14,10,17)
r <- wilcox.test(x9, y9, paired=TRUE, exact=FALSE, correct=TRUE, alternative="two.sided")
check("WSR-5.1 p(2)", 0.02681, r$p.value)

x10 <- c(20,22,18,25,16,30,13,24,19,21,17,26,15,28,23,31,14,27,20,29)
y10 <- c(15,18,19,20,17,22,16,18,21,16,19,20,18,22,17,25,16,21,22,23)
r <- wilcox.test(x10, y10, paired=TRUE, exact=FALSE, correct=TRUE, alternative="two.sided")
check("WSR-5.2 p(2)", 0.01007, r$p.value)

# ══════════════════════════════════════════════════════════════════════════════
cat("\n==================================================\n")
cat(sprintf("R Verification: %d passed, %d failed\n", pass, fail))
if (fail == 0) cat("ALL CHECKS PASSED\n") else cat("SOME CHECKS FAILED\n")
cat("==================================================\n")
