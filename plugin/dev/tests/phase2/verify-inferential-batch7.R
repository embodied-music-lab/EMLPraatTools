# ============================================================================
# EML Stats Batch 7 — R Verification Script
# ============================================================================
# Verifies KW H statistics, p-values, epsilon-squared, and Dunn's post-hoc
# against scipy-computed reference values baked into the Praat test suite.
#
# Version: 1.2.1
# Date: 3 August 2026
#
# Requires: dunn.test package (install.packages("dunn.test")) for the
# Dunn's post-hoc section. Where that package is unavailable (no CRAN
# access), Dunn's test is covered instead by the sibling artifact
# verify-inferential-batch7-dunn.py, which checks the same literals
# against scikit-posthocs and carries the same exit-code contract.
#
# CHANGELOG
# 1.2 (3 Aug 2026) - Four fixes, all of the same family: a check that
#     cannot fail, or cannot report its failure, is not a check.
#     (a) NA guard in check(). An NA actual made ok <- NA, and if (NA)
#         aborts R with "missing value where TRUE/FALSE needed" rather
#         than registering a counted skip. A verifier must not exit on
#         a control-flow error inside its own comparator.
#     (b) PASS/FAIL printing %.6f -> %.17g. At %.6f every quantity below
#         5e-7 renders as "0.000000", so a failure among the small
#         p-values would have printed expected=0.000000, got=0.000000.
#     (c) EXPECTED_CHECKS coverage assertion. An audit tool must report
#         its own coverage; without it, checks removed by a control-flow
#         change reduce the count silently and the run still reads green.
#     (d) Blanket tol <- 1e-4 replaced with per-literal tolerances.
#         This is the same R-side vacuity defect fixed in batch6b v1.3:
#         the reference literals here are transcribed to 10 decimals
#         (Kruskal-Wallis) and 8 decimals (Dunn) but were verified to
#         only ~4, so a mis-transcription in digits 5..10 passed. Each
#         literal now carries ulp(d) = 0.5 * 10^(-d) for its own
#         transcribed precision, and quantities that are exact in double
#         precision (df, H = 0, H = 2, p = 1) carry EXACT_TOL. Exactness
#         was confirmed empirically in R before assignment, not assumed:
#         kruskal.test() on three singleton groups returns H identical
#         to 2, and its p identical to exp(-1) to the last bit.
# 1.1 (2 Aug 2026) - Removed a structural false green. The whole Dunn's
#     section sits inside if (requireNamespace("dunn.test")). When the
#     package is absent the section was silently skipped, leaving fail = 0
#     from the Kruskal-Wallis checks alone, and the unqualified banner
#     "ALL CHECKS PASSED" printed having verified nothing about Dunn's
#     test. Skips are now counted, reported by reason, and gate the banner
#     (INCOMPLETE), and the script exits non-zero on skip as well as on
#     failure. Also records R and dunn.test versions in the summary.
# 1.0 - Initial.
#
# CONVENTION DIFFERENCES between dunn.test and our implementation:
#
# 1. ONE-SIDED vs TWO-SIDED p-values:
#    dunn.test: P.adjusted = adjustment(Pr(Z >= |z|))  -- one-tailed
#    Ours:      adj_p = adjustment(2 * Pr(Z >= |z|))   -- two-tailed
#    Conversion: our_adj_p = 2 * dunn.test$P.adjusted (capped at 1)
#    This follows Dunn's original 1964 convention. The dunn.test package
#    prints "Reject Ho if p <= alpha/2" to compensate. Our convention
#    matches scipy, scikit-posthocs, PMCMRplus, and most post-2010
#    implementations.
#
# 2. PAIR ORDERING:
#    dunn.test: row-major LOWER triangle
#      k=3: (2,1), (3,1), (3,2)
#      k=4: (2,1), (3,1), (3,2), (4,1), (4,2), (4,3)
#    Ours: row-major UPPER triangle
#      k=3: (1,2), (1,3), (2,3)
#      k=4: (1,2), (1,3), (1,4), (2,3), (2,4), (3,4)
#    For k=3 the indices align. For k>=4 they diverge.
#    The dunn_to_our_idx() helper computes the mapping for any k.
#
# 3. HOLM NON-LINEARITY:
#    The to_twotailed() conversion (multiply by 2) works exactly for
#    Bonferroni (multiplication commutes) and for most Holm pairs.
#    However, Holm's step-down algorithm applies rank-based multipliers
#    then enforces a running maximum. When the input p-values are
#    half-size (one-sided), the running-max can lock in at a different
#    value than when inputs are full-size (two-sided). This means
#    2 * holm(p_onesided) != holm(2 * p_onesided) for some pairs.
#    Affected pairs are documented as NOTEs rather than assertions.
#    The Praat test suite (108/108 vs scipy) is the authoritative check.
#
# 4. Z-SIGN CONVENTION:
#    dunn.test computes col_mean - row_mean (lower triangle perspective).
#    Ours computes mean_rank[i] - mean_rank[j] where i < j.
#    The magnitudes are identical; signs may differ.
#    We compare abs(z) throughout.
#
# Run: source("verify-inferential-batch7.R") in RStudio
# ============================================================================

cat("==================================================\n")
cat("EML Stats Batch 7 — R Verification\n")
cat("==================================================\n\n")

pass <- 0
fail <- 0
skipped <- 0
skip_reasons <- character(0)

# ----------------------------------------------------------------------------
# PER-LITERAL TOLERANCES (v1.2)
# ----------------------------------------------------------------------------
# The question this file asks is NOT "is the library close enough?" — that is
# the Praat suite's job. It is "is the literal baked into the Praat suite a
# correct transcription of the true value?" A transcription is correct to the
# number of decimals actually written down, so the tolerance is the half-unit
# in the last transcribed place:
#
#     ulp(d) = 0.5 * 10^(-d)     for a literal written to d decimals
#
# A blanket tolerance looser than that (v1.1 used 1e-4 for every check) makes
# the trailing digits of every literal unverified: a 10-decimal literal
# checked at 1e-4 has six digits nothing is looking at.
#
# EXACT_TOL is for quantities that are exact in IEEE double arithmetic —
# integer degrees of freedom, H = 0 for perfectly tied groups, H = 2 for
# three singleton groups, p = 1. Each was confirmed by direct comparison in
# R before being assigned EXACT_TOL; none is assumed exact from theory alone.
ulp <- function(d) 0.5 * 10^(-d)
EXACT_TOL <- 1e-12

# A skipped section must never be able to read as a pass. Every optional
# block registers itself here; the final banner is gated on skipped == 0
# as well as fail == 0.
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

# tolerance is REQUIRED. There is deliberately no default: a default is how
# v1.1 came to verify ten-decimal literals to four decimals without anyone
# choosing that. Every call site states the precision it is asserting.
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

# Convert dunn.test one-sided adjusted p to our two-tailed convention
to_twotailed <- function(p) { min(p * 2, 1.0) }

# Build index mapping from dunn.test (row-major lower) to ours (row-major upper)
# Returns a vector where result[dunn_idx] = our_idx (1-based)
dunn_to_our_idx <- function(k) {
  # dunn.test order: row-major lower triangle
  dunn_pairs <- list()
  idx <- 0
  for (row in 2:k) {
    for (col in 1:(row-1)) {
      idx <- idx + 1
      dunn_pairs[[idx]] <- c(min(row, col), max(row, col))
    }
  }
  # our order: row-major upper triangle
  our_pairs <- list()
  idx <- 0
  for (row in 1:(k-1)) {
    for (col in (row+1):k) {
      idx <- idx + 1
      our_pairs[[idx]] <- c(row, col)
    }
  }
  # map dunn index -> our index
  mapping <- integer(length(dunn_pairs))
  for (d in seq_along(dunn_pairs)) {
    for (o in seq_along(our_pairs)) {
      if (all(dunn_pairs[[d]] == our_pairs[[o]])) {
        mapping[d] <- o
        break
      }
    }
  }
  return(mapping)
}

# ══════════════════════════════════════════════════════════════════════════════
# KRUSKAL-WALLIS
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Kruskal-Wallis ---\n")

g1 <- c(23, 25, 27, 22, 26)
g2 <- c(30, 33, 29, 31, 34)
g3 <- c(18, 20, 22, 19, 17)
r <- kruskal.test(list(g1, g2, g3))
check("KW-1 H", 12.2769230769, r$statistic, ulp(10))
check("KW-1 p", 0.0021582414, r$p.value, ulp(10))
check("KW-1 df", 2, r$parameter, EXACT_TOL)

N1 <- length(g1) + length(g2) + length(g3)
eps1 <- r$statistic / (N1 - 1)
check("KW-1 epsilon_sq", 0.8769230769, eps1, ulp(10))

g4 <- c(10, 11, 12, 10.5, 11.5)
g5 <- c(10.5, 11, 11.5, 10, 12)
g6 <- c(11, 10.5, 11.5, 10, 12)
r <- kruskal.test(list(g4, g5, g6))
# Perfectly tied groups: H is exactly 0 and p exactly 1 in double arithmetic
# (confirmed in R, not assumed). A zero-target check is not vacuous — zero is
# the whole claim — but it does need a tolerance tight enough that a small
# nonzero H would be caught, which 1e-10 was not obliged to be.
check("KW-2 H", 0.0, r$statistic, EXACT_TOL)
check("KW-2 p", 1.0, r$p.value, EXACT_TOL)

g7 <- c(5, 6, 7, 5, 6)
g8 <- c(8, 9, 10, 8)
g9 <- c(5, 6, 7)
g10 <- c(12, 13, 14, 12, 13, 15)
r <- kruskal.test(list(g7, g8, g9, g10))
check("KW-3 H", 14.9405781958, r$statistic, ulp(10))
check("KW-3 p", 0.0018681395, r$p.value, ulp(10))
check("KW-3 df", 3, r$parameter, EXACT_TOL)

g11 <- c(5, 7, 9, 6, 8)
g12 <- c(10, 12, 11, 13, 14)
r <- kruskal.test(list(g11, g12))
check("KW-4 H", 6.8181818182, r$statistic, ulp(10))
check("KW-4 p", 0.0090234388, r$p.value, ulp(10))

g16 <- c(1)
g17 <- c(2)
g18 <- c(3)
r <- kruskal.test(list(g16, g17, g18))
# Three singleton groups: H = 2 exactly and p = exp(-1) to the last bit
# (both confirmed by identical() in R before EXACT_TOL was assigned here).
# The 10-decimal p literal is still only a 10-decimal transcription, so it
# takes ulp(10), not EXACT_TOL — the underlying quantity being exact does
# not make an abbreviated transcription of it exact.
check("KW-6 H", 2.0, r$statistic, EXACT_TOL)
check("KW-6 p", 0.3678794412, r$p.value, ulp(10))

# ══════════════════════════════════════════════════════════════════════════════
# DUNN'S TEST
# ══════════════════════════════════════════════════════════════════════════════
cat("\n--- Dunn's post-hoc ---\n")

if (requireNamespace("dunn.test", quietly = TRUE)) {
  cat("  Using dunn.test package\n")
  cat("  NOTE: converting one-sided p to two-tailed; remapping pair indices\n\n")

  # --- KW-1 (k=3): pair map is identity ---
  map3 <- dunn_to_our_idx(3)

  data1 <- c(g1, g2, g3)
  group1 <- rep(1:3, each = 5)
  dt1 <- dunn.test::dunn.test(data1, group1, method = "bonferroni",
                               alpha = 0.05)

  # Our expected values by our pair index: (1,2), (1,3), (2,3)
  our_z1 <- c(1.80473438, 1.69857354, 3.50330792)
  our_adjp1 <- c(0.21334877, 0.26819870, 0.00137855)

  for (d in 1:3) {
    o <- map3[d]
    check(sprintf("Dunn-1 |z| pair %d", o), our_z1[o], abs(dt1$Z[d]), ulp(8))
    check(sprintf("Dunn-1 adj_p pair %d (2t)", o), our_adjp1[o],
          to_twotailed(dt1$P.adjusted[d]), ulp(8))
  }

  # --- KW-3 (k=4): indices 3 and 4 swap ---
  map4 <- dunn_to_our_idx(4)
  cat(sprintf("\n  k=4 index map: dunn[1..6] -> ours[%s]\n\n",
              paste(map4, collapse=", ")))

  data3 <- c(g7, g8, g9, g10)
  group3 <- c(rep(1,5), rep(2,4), rep(3,3), rep(4,6))
  dt3 <- dunn.test::dunn.test(data3, group3, method = "bonferroni",
                               alpha = 0.05)

  # Our expected values by our pair index:
  # [1]=(1,2), [2]=(1,3), [3]=(1,4), [4]=(2,3), [5]=(2,4), [6]=(3,4)
  our_z3 <- c(1.74208332, 0.13765210, 3.48630836,
              1.39846873, 1.46002104, 2.84332963)
  our_adjp3_bonf <- c(0.48896320, 1.00000000, 0.00293842,
                      0.97183414, 0.86570575, 0.02678692)

  for (d in 1:6) {
    o <- map4[d]
    check(sprintf("Dunn-3 |z| pair %d", o), our_z3[o], abs(dt3$Z[d]), ulp(8))
    check(sprintf("Dunn-3 Bonf adj_p pair %d (2t)", o), our_adjp3_bonf[o],
          to_twotailed(dt3$P.adjusted[d]), ulp(8))
  }

  # --- Holm (KW-3, k=4) ---
  cat("\n  --- Holm adjustment ---\n")
  dt3h <- dunn.test::dunn.test(data3, group3, method = "holm",
                                alpha = 0.05)

  our_adjp3_holm <- c(0.32597546, 0.89051537, 0.00293842,
                      0.43285287, 0.43285287, 0.02232244)

  # Holm is non-linear (running-max step). The to_twotailed() conversion
  # works for most pairs but fails for pair 4 (groups 2,3) because
  # Holm's running-max propagates differently when applied to one-sided
  # vs two-sided inputs. See KNOWN CONVENTION DIFFERENCES note 3 above.
  for (d in 1:6) {
    o <- map4[d]
    r_val <- to_twotailed(dt3h$P.adjusted[d])
    if (o == 4) {
      # Pair 4: Holm running-max mismatch — not assertable against R.
      register_skip(sprintf(paste0("Dunn-3 Holm adj_p pair %d not verified here: R(2t)=%.6f ",
                                   "vs ours=%.6f. Holm's running-max is not linear, so ",
                                   "doubling R's one-tailed adjusted p-values does not commute ",
                                   "with the adjustment for this pair (see CONVENTION ",
                                   "DIFFERENCES note 3). R cannot supply an independent ",
                                   "reference for it. This pair IS checked externally by ",
                                   "the sibling artifact verify-inferential-batch7-dunn.py, ",
                                   "which uses scikit-posthocs (natively two-sided, so no ",
                                   "doubling is involved); that file must exit 0 before this ",
                                   "pair may be called verified."),
                            o, r_val, our_adjp3_holm[o]))
    } else {
      check(sprintf("Dunn-3 Holm adj_p pair %d (2t)", o), our_adjp3_holm[o],
            r_val, ulp(8))
    }
  }

} else {
  register_skip(paste0("Dunn's post-hoc section not run: the 'dunn.test' ",
                       "package is not installed. Install with ",
                       "install.packages('dunn.test') and re-run. ",
                       "THIS FILE verifies Kruskal-Wallis only and CANNOT ",
                       "be reported as verifying Dunn's test. Dunn's test ",
                       "is instead covered by the sibling artifact ",
                       "verify-inferential-batch7-dunn.py (scikit-posthocs), ",
                       "which must be run and must exit 0 before Dunn's ",
                       "test may be called externally verified. A runner ",
                       "reporting only this file's exit code has not ",
                       "checked Dunn's test."))
}

# ══════════════════════════════════════════════════════════════════════════════
# COVERAGE ASSERTION (v1.2)
# ══════════════════════════════════════════════════════════════════════════════
# An audit tool must report its own coverage. Without this, a control-flow
# change that removes call sites lowers pass and the run still reads green:
# "13 passed, 0 failed" is indistinguishable from "37 passed, 0 failed"
# unless something states how many checks were supposed to happen.
#
# The expected count is conditional on the environment because the Dunn
# section either runs (13 KW + 6 Dunn-1 + 12 Dunn-3 Bonf + 5 Holm checks +
# 1 structural Holm pair-4 skip = 37) or does not (13 KW + 1 environmental
# skip = 14). Both are legitimate; neither is 0 exit status.
HAS_DUNN <- requireNamespace("dunn.test", quietly = TRUE)
EXPECTED_CHECKS <- if (HAS_DUNN) 37 else 14

performed <- pass + fail + skipped
if (performed != EXPECTED_CHECKS) {
  fail <- fail + 1
  cat(sprintf("  FAIL: coverage (expected %d checks to be performed%s, saw %d)\n",
              EXPECTED_CHECKS,
              if (HAS_DUNN) " with dunn.test present" else " with dunn.test absent",
              performed))
}

cat("\n==================================================\n")
cat(sprintf("R Verification: %d passed, %d failed, %d skipped (of %d expected)\n",
            pass, fail, skipped, EXPECTED_CHECKS))
cat(sprintf("R %s.%s; dunn.test %s\n",
            R.version$major, R.version$minor,
            if (requireNamespace("dunn.test", quietly = TRUE))
              as.character(utils::packageVersion("dunn.test")) else "ABSENT"))

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
# A runner must not collapse 2 into 0. The dunn.test skip is environmental
# (fixable by installing the package); the Holm pair-4 skip is structural
# (R cannot supply an independent reference, because doubling dunn.test's
# one-tailed Holm output does not commute with Holm's running-max). Either
# way the run is incomplete, not green, and distinguishable from a failure.
#
# Both skips are covered by verify-inferential-batch7-dunn.py, which checks
# the same literals against scikit-posthocs. Exit 2 from THIS file is only
# discharged when that file exits 0; a runner must invoke both.
if (fail > 0) quit(status = 1)
if (skipped > 0) quit(status = 2)
quit(status = 0)
