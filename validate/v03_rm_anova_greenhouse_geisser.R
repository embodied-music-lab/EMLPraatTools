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
conds <- c("SPL_soft", "SPL_medium", "SPL_loud")
Y <- as.matrix(d[, conds])
fit <- rm_anova(Y)

check_true("v03", "20 complete-case subjects, 3 conditions",
           fit$n == 20L && fit$k == 3L && !any(is.na(Y)))

# --- condition means ------------------------------------------------------
check("v03", "SPL_soft mean",   72.4646, unname(fit$means["SPL_soft"]),   tol = 5e-5)
check("v03", "SPL_medium mean", 83.3546, unname(fit$means["SPL_medium"]), tol = 5e-5)
check("v03", "SPL_loud mean",   94.1294, unname(fit$means["SPL_loud"]),   tol = 5e-5)

# --- omnibus --------------------------------------------------------------
check("v03", "F statistic", 583.1232, fit$F, tol = 5e-5)
check_true("v03", "df reported as (2, 38)", fit$df1 == 2L && fit$df2 == 38L)
check("v03", "Greenhouse-Geisser epsilon", 0.8486, fit$gg, tol = 5e-5)

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
rel <- function(a, b) abs(a - b) / b
check_true("v03", "post-hoc raw p soft-medium ~ 2e-12",  rel(pr[1], 1.5384e-12) < 0.01)
check_true("v03", "post-hoc raw p soft-loud ~ 1e-20",    rel(pr[2], 1.0687e-20) < 0.01)
check_true("v03", "post-hoc raw p medium-loud ~ 5e-12",  rel(pr[3], 5.4312e-12) < 0.01)
check_true("v03", "holm adjusted p are >= raw p",        all(pa >= pr))
check_true("v03", "holm ordering preserved",             !is.unsorted(pa[order(pr)]))

# --- D86: the plugin reports no effect size for this test -----------------
# Recorded so the value an independent reviewer would expect is on file.
check_true("v03", "partial eta squared computable (D86: plugin omits it)",
           abs(fit$partial_eta2 - 0.9684) < 5e-5)

if (!exists("EML_SUITE")) { eml_report("v03 RM-ANOVA + Greenhouse-Geisser"); eml_exit() }
