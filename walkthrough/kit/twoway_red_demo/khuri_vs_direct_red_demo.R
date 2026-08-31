# ============================================================================
# khuri_vs_direct_red_demo.R -- the numeric half of the two-way ANOVA red
# demo (mailbox/to-opus/WORK_ORDER_TWOWAY_KERNEL_2026-08-31.md).
#
# Confirms, on data built here (no Praat needed), that:
#   1. Praat's built-in two-way ANOVA recovers Error by subtraction --
#      SS_E = SS_T - SS_A - SS_B - SS_AB, with SS_A/B/AB from Khuri's (1998)
#      unweighted-means method and Total centered on the UNWEIGHTED mean of
#      the cell means -- and that this subtraction is exact on a balanced
#      design and WRONG on an unbalanced one.
#   2. The correct direct computation (residual pooled within cells; Total
#      centered on the ordinary observation-weighted grand mean) agrees with
#      the subtraction method exactly when balanced and diverges when not.
#   3. Type II SS (car::Anova(fit, type=2) as the kit's R oracle actually
#      computes -- see run_analyses.R ~L925, ~L158) and Type III SS (with
#      sum-to-zero contrasts) coincide with Khuri-unweighted on the balanced
#      fixture and separate from it -- and from each other -- on the
#      unbalanced one. Computed via base R, see twoway_functions.R for why
#      (no `car` package here) and how (RSS differences for Type II, a
#      sum-to-zero Wald quadratic form for Type III).
#
# Run: Rscript khuri_vs_direct_red_demo.R  (from this file's own directory,
# or any directory -- paths below are relative to this script's location).
# Needs only base R. No packages.
# ============================================================================

# Resolve this script's own directory so it can be run (via `Rscript`) from
# any working directory -- the shared functions file and the data/ fixtures
# are found relative to here, not to the caller's cwd.
.args <- commandArgs(trailingOnly = FALSE)
.fileArg <- sub("^--file=", "", .args[grep("^--file=", .args)])
here <- if (length(.fileArg) == 1) dirname(normalizePath(.fileArg)) else "."
source(file.path(here, "twoway_functions.R"))

options(width = 100)

# ----------------------------------------------------------------------------
# Print the full two-way story for one fixture: both tables, the
# divergence, additivity, and the Type II/III/Khuri oracle spread.
# ----------------------------------------------------------------------------
run_fixture <- function(path, y, A, B, label) {
    d <- read.csv(path, stringsAsFactors = FALSE)
    both <- twoway_both_tables(d, y, A, B)
    kh <- both$kh; dr <- both$dr; w <- both$wrong; c_ <- both$correct
    t2 <- type2_ss(d, y, A, B)
    t3 <- type3_ss(d, y, A, B)

    cat("\n================================================================\n")
    cat(label, "\n")
    cat("  file:", path, "\n")
    cat("  N =", dr$N, " cells (", kh$r, "x", kh$s, ") = ", kh$rs, "\n", sep = "")
    cat("  cell sizes:\n")
    print(kh$cellN)
    balanced <- length(unique(as.vector(kh$cellN))) == 1
    cat("  balanced:", balanced, "  n_h =", fmt(kh$n_h, 6), "\n")

    cat("\n-- Khuri unweighted effects (same numbers feed BOTH tables below) --\n")
    eff <- data.frame(
        term = c(A, B, paste0(A, ":", B)),
        SS = c(kh$ssA, kh$ssB, kh$ssAB), df = c(kh$dfA, kh$dfB, kh$dfAB)
    )
    print(eff, digits = 8, row.names = FALSE)

    cat("\n-- (WRONG) Praat built-in method: SS_E = SS_T(unweighted-centered) - SS_A - SS_B - SS_AB --\n")
    wrong <- data.frame(
        Source = c(A, B, paste0(A, ":", B), "Error", "Total"),
        SS = c(kh$ssA, kh$ssB, kh$ssAB, w$ssE, w$ssT),
        Df = c(kh$dfA, kh$dfB, kh$dfAB, w$dfE, w$dfT),
        F  = c(w$fA, w$fB, w$fAB, NA, NA),
        P  = c(w$pA, w$pB, w$pAB, NA, NA)
    )
    print(wrong, digits = 8, row.names = FALSE)

    cat("\n-- (CORRECT) direct method: SS_E pooled within cells; Total about weighted grand mean --\n")
    correct <- data.frame(
        Source = c(A, B, paste0(A, ":", B), "Error", "Total"),
        SS = c(kh$ssA, kh$ssB, kh$ssAB, c_$ssE, c_$ssT),
        Df = c(kh$dfA, kh$dfB, kh$dfAB, c_$dfE, c_$dfT),
        F  = c(c_$fA, c_$fB, c_$fAB, NA, NA),
        P  = c(c_$pA, c_$pB, c_$pAB, NA, NA)
    )
    print(correct, digits = 8, row.names = FALSE)

    cat("\n-- Divergence (wrong vs correct) --\n")
    cat("  SS_Error : wrong =", fmt(w$ssE), " correct =", fmt(c_$ssE),
        " ratio(wrong/correct) =", fmt(w$ssE / c_$ssE, 6), "\n")
    cat("  SS_Total : wrong =", fmt(w$ssT), " correct =", fmt(c_$ssT),
        " diff =", fmt(w$ssT - c_$ssT), "\n")
    cat("  F(", A, ") : wrong =", fmt(w$fA), " correct =", fmt(c_$fA),
        " ratio(wrong/correct) =", fmt(w$fA / c_$fA, 6), "\n", sep = "")
    cat("  F(", B, ") : wrong =", fmt(w$fB), " correct =", fmt(c_$fB),
        " ratio(wrong/correct) =", fmt(w$fB / c_$fB, 6), "\n", sep = "")
    cat("  F(", A, ":", B, ") : wrong =", fmt(w$fAB), " correct =", fmt(c_$fAB),
        " ratio(wrong/correct) =", fmt(w$fAB / c_$fAB, 6), "\n", sep = "")
    # Same identity the work order points at for Peterson-Barney: because
    # the effect SS are untouched by the subtraction bug, F_correct/F_wrong
    # for every effect equals SS_Error(wrong)/SS_Error(correct) exactly (same
    # error df in numerator and denominator on both sides) -- i.e. the whole
    # discrepancy lives in the error term, none of it in the effect sums.
    cat("  Identity check -- F_correct/F_wrong should equal SS_Error(wrong)/SS_Error(correct)",
        "for every effect, since the effect SS are untouched by the subtraction bug:\n")
    cat("    F(", A, ")_correct/wrong = ", fmt(c_$fA / w$fA, 6),
        "   F(", B, ")_correct/wrong = ", fmt(c_$fB / w$fB, 6),
        "   F(", A, ":", B, ")_correct/wrong = ", fmt(c_$fAB / w$fAB, 6),
        "   SS_Error(wrong)/SS_Error(correct) = ", fmt(w$ssE / c_$ssE, 6), "\n", sep = "")

    cat("\n-- Additivity check: does SS_A+SS_B+SS_AB+SS_E(correct) == SS_T(correct)? --\n")
    addSum <- kh$ssA + kh$ssB + kh$ssAB + c_$ssE
    cat("  sum(effects)+SS_E(correct) =", fmt(addSum), "  SS_T(correct) =", fmt(c_$ssT),
        "  gap =", fmt(addSum - c_$ssT), "\n")

    cat("\n-- Oracle spread: Type II vs Type III (sum-to-zero) vs Khuri-unweighted --\n")
    spread <- data.frame(
        term = c(A, B, paste0(A, ":", B)),
        TypeII_SS  = c(t2$ssA, t2$ssB, t2$ssAB),
        TypeIII_SS = c(t3$ssA, t3$ssB, t3$ssAB),
        Khuri_SS   = c(kh$ssA, kh$ssB, kh$ssAB)
    )
    spread$maxpct_spread <- 100 * apply(spread[, 2:4], 1, function(x) (max(x) - min(x)) / mean(x))
    print(spread, digits = 8, row.names = FALSE)
    cat("  Type II SS_E =", fmt(t2$ssE), " Type III SS_E =", fmt(t3$ssE),
        " direct SS_E =", fmt(c_$ssE), " (all three must be identical -- same model, same residuals)\n")

    invisible(list(kh = kh, dr = dr, wrong = w, correct = c_))
}

cat("############################################################################\n")
cat("# RED DEMO -- balanced fixture first (sanity: both methods must agree)\n")
cat("############################################################################\n")
bal <- run_fixture(file.path(here, "..", "data", "v11_twoway_input.csv"),
                    "SPL_dB", "voice_type", "task",
                    "BALANCED fixture: v11_twoway_input.csv (2x2, n=12/cell, N=48)")

cat("\n\n############################################################################\n")
cat("# RED DEMO -- unbalanced fixture (the demonstration)\n")
cat("############################################################################\n")
unb <- run_fixture(file.path(here, "..", "data", "v11_twoway_unbalanced_input.csv"),
                    "SPL_dB", "voice_type", "task",
                    "UNBALANCED fixture: v11_twoway_unbalanced_input.csv (2x2, cells 2/4/6/9, N=21)")

cat("\n\n############################################################################\n")
cat("# SUMMARY\n")
cat("############################################################################\n")
cat("Balanced fixture:   wrong/correct SS_Error ratio =", fmt(bal$wrong$ssE / bal$correct$ssE, 6),
    " (expect 1.0)\n")
cat("Unbalanced fixture: wrong/correct SS_Error ratio =", fmt(unb$wrong$ssE / unb$correct$ssE, 6),
    " (expect clearly != 1.0 -- this IS the red demo)\n")
cat("Compare to Praat manual's Peterson-Barney case: 1600534/914449 =",
    fmt(1600534 / 914449, 6), "\n")

cat("\nNOTE on Type III without `car`: this environment has no `car` package\n")
cat("installed (verified: install.packages(\"car\") fails, no network access to\n")
cat("CRAN either). Type III here is computed directly via a sum-to-zero-contrast\n")
cat("Wald quadratic form (see twoway_functions.R::type3_ss), which is the textbook\n")
cat("definition of Type III SS for a full-rank model and is what car::Anova(type=3)\n")
cat("reduces to internally. Type II is computed via plain RSS differences, which is\n")
cat("exactly what car::Anova(type=2) reduces to for a two-factor model with an\n")
cat("interaction. Both are cross-checkable against car on Ian's machine.\n")
