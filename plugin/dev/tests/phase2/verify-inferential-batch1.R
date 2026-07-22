# ============================================================================
# EML Stats Inferential Statistics — Batch 1 Reference Values
# ============================================================================
# Purpose: Independent verification of test assertions in
#          test-inferential-batch1.praat
# Date: 26 February 2026
#
# Run this script in R (>= 4.0) to regenerate all reference values.
# Compare output against Praat test assertions.
# ============================================================================

cat("==============================================================\n")
cat("BATCH 1 REFERENCE VALUES\n")
cat("==============================================================\n\n")

g1 <- c(10, 12, 14, 16, 18)
g2 <- c(8, 9, 10, 11, 12)

# --- Welch t-test (default) ---
cat("--- @emlTTest: Welch ---\n")
welch <- t.test(g1, g2, var.equal = FALSE)
cat(sprintf("  t = %.6f\n", welch$statistic))
cat(sprintf("  df = %.6f\n", welch$parameter))
cat(sprintf("  p (2-tail) = %.6f\n", welch$p.value))
cat(sprintf("  p (1-tail) = %.6f\n", welch$p.value / 2))
cat("\n")

# --- Student t-test (pooled) ---
cat("--- @emlTTest: Student ---\n")
student <- t.test(g1, g2, var.equal = TRUE)
cat(sprintf("  t = %.6f\n", student$statistic))
cat(sprintf("  df = %d\n", student$parameter))
cat(sprintf("  p (2-tail) = %.6f\n", student$p.value))
cat(sprintf("  p (1-tail) = %.6f\n", student$p.value / 2))
cat("\n")

# --- Paired t-test ---
cat("--- @emlTTestPaired ---\n")
paired <- t.test(g1, g2, paired = TRUE)
diffs <- g1 - g2
cat(sprintf("  diffs: %s\n", paste(diffs, collapse = ", ")))
cat(sprintf("  mean_diff = %.6f\n", mean(diffs)))
cat(sprintf("  sd_diff = %.6f\n", sd(diffs)))
cat(sprintf("  se_diff = %.6f\n", sd(diffs) / sqrt(length(diffs))))
cat(sprintf("  t = %.6f\n", paired$statistic))
cat(sprintf("  df = %d\n", paired$parameter))
cat(sprintf("  p (2-tail) = %.6f\n", paired$p.value))
cat(sprintf("  p (1-tail) = %.6f\n", paired$p.value / 2))
cat("\n")

# --- Paired: Larger sample ---
cat("--- @emlTTestPaired: Larger sample ---\n")
pre <- c(85, 90, 78, 92, 88, 76, 95, 82, 91, 87)
post <- c(88, 93, 82, 94, 91, 80, 97, 86, 93, 90)
paired_lg <- t.test(pre, post, paired = TRUE)
diffs_lg <- pre - post
cat(sprintf("  diffs: %s\n", paste(diffs_lg, collapse = ", ")))
cat(sprintf("  mean_diff = %.6f\n", mean(diffs_lg)))
cat(sprintf("  t = %.6f\n", paired_lg$statistic))
cat(sprintf("  p (2-tail) = %.6f\n", paired_lg$p.value))
cat("\n")

# --- Cohen's d and Hedges' g ---
cat("--- @emlCohenD ---\n")
n1 <- length(g1)
n2 <- length(g2)
pooled_var <- ((n1 - 1) * var(g1) + (n2 - 1) * var(g2)) / (n1 + n2 - 2)
pooled_sd <- sqrt(pooled_var)
d <- (mean(g1) - mean(g2)) / pooled_sd
df_d <- n1 + n2 - 2
J <- 1 - 3 / (4 * df_d - 1)
g <- d * J
cat(sprintf("  pooled_sd = %.6f\n", pooled_sd))
cat(sprintf("  d = %.6f\n", d))
cat(sprintf("  J (correction) = %.6f\n", J))
cat(sprintf("  g (Hedges) = %.6f\n", g))
cat("\n")

# --- Reversed groups ---
cat("--- Reversed groups ---\n")
welch_rev <- t.test(g2, g1, var.equal = FALSE)
cat(sprintf("  t = %.6f (should be negative)\n", welch_rev$statistic))
d_rev <- (mean(g2) - mean(g1)) / pooled_sd
cat(sprintf("  d = %.6f (should be negative)\n", d_rev))
cat("\n")

cat("==============================================================\n")
cat("All values computed. Compare against Praat test assertions.\n")
cat("==============================================================\n")
