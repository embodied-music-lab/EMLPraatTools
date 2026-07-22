# ============================================================================
# EML Stats : R Verification Script — Inferential Statistics (Batch 5)
# ============================================================================
# Independent verification of reference values for:
#   @emlBonferroni, @emlHolm, @emlBenjaminiHochberg
#
# Uses R's built-in p.adjust() — the standard reference implementation.
#
# Date: 3 March 2026
# ============================================================================

cat("==================================================\n")
cat("EML Stats Batch 5 — R Verification\n")
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
    cat(sprintf("  PASS: %s (expected=%.6f, got=%.6f)\n", label, expected, actual))
  } else {
    assign("fail", get("fail", envir=.GlobalEnv) + 1, envir=.GlobalEnv)
    cat(sprintf("  FAIL: %s (expected=%.8f, got=%.8f)\n", label, expected, actual))
  }
}

check_vec <- function(prefix, expected, actual, tol=0.001) {
  for (i in seq_along(expected)) {
    check(sprintf("%s p%d", prefix, i), expected[i], actual[i], tol)
  }
}


# ══════════════════════════════════════════════════════════════════════════════
# BONFERRONI
# ══════════════════════════════════════════════════════════════════════════════

cat("--- Bonferroni ---\n")

raw1 <- c(0.001, 0.013, 0.029, 0.05, 0.8)
check_vec("BON-1.1", c(0.005, 0.065, 0.145, 0.25, 1.0),
          p.adjust(raw1, method="bonferroni"), 1e-6)

raw2 <- c(0.001, 0.005, 0.01, 0.02)
check_vec("BON-1.2", c(0.004, 0.02, 0.04, 0.08),
          p.adjust(raw2, method="bonferroni"), 1e-6)

raw3 <- c(0.2, 0.4, 0.6, 0.8)
check_vec("BON-1.3", c(0.8, 1.0, 1.0, 1.0),
          p.adjust(raw3, method="bonferroni"), 1e-6)

check("BON-1.4 single", 0.03, p.adjust(0.03, method="bonferroni"), 1e-6)

raw5 <- c(0.0, 0.01, 0.05)
check_vec("BON-1.5", c(0.0, 0.03, 0.15),
          p.adjust(raw5, method="bonferroni"), 1e-6)

raw6 <- c(0.01, 0.5, 1.0)
check_vec("BON-1.6", c(0.03, 1.0, 1.0),
          p.adjust(raw6, method="bonferroni"), 1e-6)

raw7 <- c(0.01, 0.01, 0.05, 0.05)
check_vec("BON-1.7", c(0.04, 0.04, 0.2, 0.2),
          p.adjust(raw7, method="bonferroni"), 1e-6)


# ══════════════════════════════════════════════════════════════════════════════
# HOLM
# ══════════════════════════════════════════════════════════════════════════════

cat("\n--- Holm ---\n")

check_vec("HOLM-2.1", c(0.005, 0.052, 0.087, 0.1, 0.8),
          p.adjust(raw1, method="holm"), 1e-6)

check_vec("HOLM-2.2", c(0.004, 0.015, 0.02, 0.02),
          p.adjust(raw2, method="holm"), 1e-6)

raw_rev <- c(0.5, 0.1, 0.05, 0.01, 0.001)
check_vec("HOLM-2.3", c(0.5, 0.2, 0.15, 0.04, 0.005),
          p.adjust(raw_rev, method="holm"), 1e-6)

raw_cap <- c(0.04, 0.06, 0.08, 0.3, 0.7)
check_vec("HOLM-2.4", c(0.2, 0.24, 0.24, 0.6, 0.7),
          p.adjust(raw_cap, method="holm"), 1e-6)

check("HOLM-2.5 single", 0.03, p.adjust(0.03, method="holm"), 1e-6)

check_vec("HOLM-2.6", c(0.04, 0.04, 0.1, 0.1),
          p.adjust(raw7, method="holm"), 1e-6)

check_vec("HOLM-2.7", c(0.8, 1.0, 1.0, 1.0),
          p.adjust(raw3, method="holm"), 1e-6)

check_vec("HOLM-2.8", c(0.0, 0.02, 0.05),
          p.adjust(raw5, method="holm"), 1e-6)


# ══════════════════════════════════════════════════════════════════════════════
# BENJAMINI-HOCHBERG
# ══════════════════════════════════════════════════════════════════════════════

cat("\n--- Benjamini-Hochberg ---\n")

check_vec("BH-3.1", c(0.005, 0.0325, 0.04833, 0.0625, 0.8),
          p.adjust(raw1, method="BH"), 1e-3)

check_vec("BH-3.2", c(0.004, 0.01, 0.01333, 0.02),
          p.adjust(raw2, method="BH"), 1e-3)

check_vec("BH-3.3", c(0.5, 0.125, 0.08333, 0.025, 0.005),
          p.adjust(raw_rev, method="BH"), 1e-3)

check_vec("BH-3.4", c(0.13333, 0.13333, 0.13333, 0.375, 0.7),
          p.adjust(raw_cap, method="BH"), 1e-3)

check_vec("BH-3.5", c(0.8, 0.8, 0.8, 0.8),
          p.adjust(raw3, method="BH"), 1e-6)

check("BH-3.6 single", 0.03, p.adjust(0.03, method="BH"), 1e-6)

check_vec("BH-3.7", c(0.02, 0.02, 0.05, 0.05),
          p.adjust(raw7, method="BH"), 1e-6)

raw10 <- c(0.001, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.1, 0.5, 0.9)
check_vec("BH-3.8", c(0.01, 0.025, 0.03333, 0.05, 0.06, 0.06667, 0.07143, 0.125, 0.55556, 0.9),
          p.adjust(raw10, method="BH"), 1e-3)

check_vec("BH-3.9", c(0.0, 0.015, 0.05),
          p.adjust(raw5, method="BH"), 1e-6)

check_vec("BH-3.10", c(0.03, 0.75, 1.0),
          p.adjust(raw6, method="BH"), 1e-6)


# ══════════════════════════════════════════════════════════════════════════════
# CROSS-METHOD CONSISTENCY
# ══════════════════════════════════════════════════════════════════════════════

cat("\n--- Cross-method consistency ---\n")

bon <- p.adjust(raw1, method="bonferroni")
hol <- p.adjust(raw1, method="holm")
bh  <- p.adjust(raw1, method="BH")

for (i in seq_along(raw1)) {
  ok_bh <- bon[i] >= hol[i] - 1e-10 && hol[i] >= bh[i] - 1e-10
  if (ok_bh) {
    assign("pass", get("pass", envir=.GlobalEnv) + 1, envir=.GlobalEnv)
    cat(sprintf("  PASS: Ordering p%d: Bon=%.4f >= Holm=%.4f >= BH=%.4f\n", i, bon[i], hol[i], bh[i]))
  } else {
    assign("fail", get("fail", envir=.GlobalEnv) + 1, envir=.GlobalEnv)
    cat(sprintf("  FAIL: Ordering p%d: Bon=%.4f, Holm=%.4f, BH=%.4f\n", i, bon[i], hol[i], bh[i]))
  }
}


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

cat("\n==================================================\n")
cat(sprintf("TOTAL: %d PASS, %d FAIL\n", pass, fail))
if (fail > 0) {
  cat("*** FAILURES DETECTED ***\n")
} else {
  cat("All checks passed.\n")
}
cat("==================================================\n")
