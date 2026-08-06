# ============================================================================
# v03 — Stats Wizard, repeated measures: RM-ANOVA with Greenhouse-Geisser
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Route:    Stats Wizard > Compare groups or conditions > Yes, repeated >
#           Three or more (RM-ANOVA / Friedman) > conditions SPL_soft,
#           SPL_medium, SPL_loud > Test approach Parametric > Adjustment holm
# Input:    evidence/csv/demo_rm3_input.csv
# Printed:  evidence/info/wizard_rm3_rmanova_and_friedman.txt
#
# The RM-ANOVA is cross-checked two ways: against the closed-form sums of
# squares in helpers.R, and against base R's aov() with an Error() stratum,
# which is an independent implementation.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d <- read_input("demo_rm3_input.csv")
cap <- capture("wizard_rm3_rmanova_and_friedman.txt")
conds <- c("SPL_soft", "SPL_medium", "SPL_loud")
Y <- as.matrix(d[, conds])
fit <- rm_anova(Y)

check_true("v03", "20 complete-case subjects, 3 conditions",
           fit$n == 20L && fit$k == 3L && !any(is.na(Y)))

# --- condition means ------------------------------------------------------
check("v03", "SPL_soft mean",   printed_eq(cap, "SPL_soft mean"),   unname(fit$means["SPL_soft"]),   tol = 5e-5)
check("v03", "SPL_medium mean", printed_eq(cap, "SPL_medium mean"), unname(fit$means["SPL_medium"]), tol = 5e-5)
check("v03", "SPL_loud mean",   printed_eq(cap, "SPL_loud mean"),   unname(fit$means["SPL_loud"]),   tol = 5e-5)

# --- omnibus --------------------------------------------------------------
check("v03", "F statistic", printed_eq(cap, "F(2, 38)", 1), fit$F, tol = 5e-5)
# The df are in the printed LABEL, so assert the label itself exists rather
# than trusting a transcription of the numbers inside it.
check_true("v03", "the capture prints F with df (2, 38)",
           any(grepl("F(2, 38)", cap$lines, fixed = TRUE)))
check_true("v03", "df reported as (2, 38)", fit$df1 == 2L && fit$df2 == 38L)
check("v03", "Greenhouse-Geisser epsilon",
      printed_eq(cap, "Greenhouse-Geisser epsilon", 1), fit$gg, tol = 5e-5)
# The uncorrected and GG-corrected p are both printed. Reading both lets the
# relationship between them be asserted: correcting with epsilon < 1 costs
# df, so the corrected p must be the LARGER of the two.
p_unc <- printed_eq(cap, "F(2, 38)", 2)
p_gg  <- printed_eq(cap, "Greenhouse-Geisser epsilon", 2)
# V5, 6 Aug 2026. tol was 1e-28 against p = 3.036e-29, so |0 - p| < tol and a
# plugin that floored this p to zero would have PASSED -- the exact failure
# D24 exists to catch on the CSV side, admitted here on the printed side.
# The prints are fixed-decimal, so the principled bound is half a display ULP:
# 5e-30 for the 29-decimal line, 5e-26 for the 25-decimal one. Both committed
# values clear it with room (|diff| = 3.6e-31). The positivity assertions
# beside them close the hole directly rather than relying on the tolerance.
check_true("v03", "printed uncorrected p is not floored to zero", p_unc > 0)
check_true("v03", "printed GG-corrected p is not floored to zero", p_gg > 0)
check("v03", "printed uncorrected p", p_unc, fit$p,    tol = 5e-30)
check("v03", "printed GG-corrected p", p_gg, fit$p_gg, tol = 5e-26)
check_true("v03", "GG correction increases p, since epsilon < 1",
           fit$gg < 1 && p_gg > p_unc)

# D85, confirmed still present from the capture rather than from memory:
# these p-values print as long decimal strings instead of the plugin's own
# "< .001" convention. 29 and 25 decimal places here.
check_true("v03", "D85: p printed as a long decimal string, not '< .001'",
           any(grepl("p = 0.0000000000000000000000000", cap$lines, fixed = TRUE)))

# --- independent cross-check against base R aov() -------------------------
long <- data.frame(
    subject   = factor(rep(d$singer, times = length(conds))),
    condition = factor(rep(conds, each = nrow(d)), levels = conds),
    value     = as.vector(Y)
)
a <- summary(aov(value ~ condition + Error(subject / condition), data = long))
f_aov <- a[["Error: subject:condition"]][[1]][["F value"]][1]
check("v03", "F agrees with base R aov()", fit$F, f_aov, tol = 1e-6)

# --- post-hoc pairwise, holm-adjusted -------------------------------------
pr <- c(
    t.test(Y[, "SPL_soft"],   Y[, "SPL_medium"], paired = TRUE)$p.value,
    t.test(Y[, "SPL_soft"],   Y[, "SPL_loud"],   paired = TRUE)$p.value,
    t.test(Y[, "SPL_medium"], Y[, "SPL_loud"],   paired = TRUE)$p.value
)
pa <- p.adjust(pr, method = "holm")

# The plugin prints these as long decimal strings (finding D85). The values
# are validated on a relative scale because absolute tolerance is meaningless
# at 1e-12 and below.
# V6, 6 Aug 2026. These were rel(printed, r) < 0.5, justified as "absolute
# tolerance is meaningless at 1e-12". True, but a 50% relative window admits a
# mis-rounding 43% wide, and the print is FIXED-DECIMAL, so there is a
# principled bound available: half a display ULP, 0.5 * 10^-decimals, read
# from the capture string itself. All three committed values clear it
# (|2e-12 - 1.538e-12| = 4.6e-13 against a 5e-13 bound).
ulp_bound <- function(s) {
    dp <- regmatches(s, regexpr("\\.[0-9]+", s))
    if (!length(dp)) return(0.5)
    0.5 * 10^(-(nchar(dp) - 1L))
}
posthoc_ulp <- function(label, r) {
    txt <- printed_eq_str(cap, label, 1, 1)
    abs(as.numeric(txt) - r) <= ulp_bound(txt)
}
check_true("v03", "post-hoc raw p soft-medium",
           posthoc_ulp("SPL_soft vs SPL_medium", pr[1]))
check_true("v03", "post-hoc raw p soft-loud",
           posthoc_ulp("SPL_soft vs SPL_loud", pr[2]))
check_true("v03", "post-hoc raw p medium-loud",
           posthoc_ulp("SPL_medium vs SPL_loud", pr[3]))
check_true("v03", "holm adjusted p are >= raw p",        all(pa >= pr))
check_true("v03", "holm ordering preserved",             !is.unsorted(pa[order(pr)]))

# --- D86: the plugin reports no effect size for this test -----------------
# Recorded so the value an independent reviewer would expect is on file.
check_true("v03", "partial eta squared computable (D86: plugin omits it)",
           abs(fit$partial_eta2 - 0.9684) < 5e-5)

if (!exists("EML_SUITE")) { eml_report("v03 RM-ANOVA + Greenhouse-Geisser"); eml_exit() }
