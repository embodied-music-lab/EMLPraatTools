# ============================================================================
# v24_influence.R -- @emlOLSInfluence against base R's hatvalues(),
# rstandard() and cooks.distance().
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Ruling 4(d). Three quantities are new to the regression augment frame, and
# one that was already there was WRONG:
#
#   .hat        h_i = 1/n + (x_i - xbar)^2 / SSxx           <- hatvalues()
#   .cooksd     e_i^2 h_i / (p s^2 (1-h_i)^2)               <- cooks.distance()
#   .std.resid  e_i / (s sqrt(1 - h_i))                     <- rstandard()
#
# The last is the correction. The augment sites emitted `.std.resid` as
# e_i / s, with no leverage term at all. That is not broom's .std.resid and
# it is not R's rstandard(); it is only what both reduce to as h_i -> 0. The
# evidence file carries BOTH forms per row, so this script asserts the
# corrected one against R AND asserts that the uncorrected one is genuinely
# different -- otherwise a green run would not distinguish "the correction
# was applied" from "the correction was a no-op on this data".
#
# BASE R ONLY. No packages. Every reference value comes from stats::lm and
# its own influence accessors, not from a reimplementation here, because the
# point of this file is to check the plugin against R rather than against a
# second copy of the plugin's arithmetic.
#
#     Rscript validate/v24_influence.R
#
# Input:  evidence/influence/rows.csv, fits.csv, data/<case>.csv
#         (regenerate with
#          praat --run harness/influence/ols_influence_drive.praat)
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

infl_dir <- repo_path("evidence", "influence")
rows <- read.csv(file.path(infl_dir, "rows.csv"), stringsAsFactors = FALSE)
fits <- read.csv(file.path(infl_dir, "fits.csv"), stringsAsFactors = FALSE)

case_data <- function(cs)
    read.csv(file.path(infl_dir, "data", paste0(cs, ".csv")),
             stringsAsFactors = FALSE)

fit_row <- function(cs) {
    hit <- fits[fits$case == cs, , drop = FALSE]
    if (nrow(hit) != 1L)
        stop(sprintf("v24: expected exactly 1 fits.csv row for %s, found %d",
                     cs, nrow(hit)))
    hit
}

# check_na_pair -- both sides must be missing, or neither. Written out rather
# than folded into check() because check() compares numbers and NaN is not a
# number the tolerance machinery can talk about. This is the assertion that
# the leverage-1 row is undefined on BOTH sides, which is the point of the
# clamp; asserting only "the plugin said NA" would pass if R had said 46.56.
check_na_pair <- function(id, what, reported, computed) {
    check_true(id, what, is.na(reported) == is.na(computed))
}

# Every case in fits.csv must be accounted for below. A case that is driven
# by the harness and then silently not checked here is the failure mode a
# growing harness produces, so the ledger is explicit and reconciled at the
# end.
seen <- character(0)
saw <- function(cs) { seen <<- c(seen, cs); invisible(NULL) }


# ===========================================================================
# GREEN PATHS
# ===========================================================================
green <- list(
    committed     = c("practice_hrs_wk", "vibrato_regularity_pct"),
    committed_exp = c("experience_yrs",  "vibrato_regularity_pct"),
    missing       = c("practice_hrs_wk", "vibrato_regularity_pct"),
    leverage      = c("x", "y"),
    outlier       = c("x", "y"),
    tiny          = c("x", "y"),
    red_lev1      = c("x", "y"),
    red_lev1b     = c("x", "y")
)

for (cs in names(green)) {
    saw(cs)
    xc <- green[[cs]][1]; yc <- green[[cs]][2]
    f  <- fit_row(cs)
    d  <- case_data(cs)
    r  <- rows[rows$case == cs, , drop = FALSE]
    r  <- r[order(r$row), , drop = FALSE]

    check_true("v24", paste(cs, "refused nothing"), identical(f$error, ""))
    check_true("v24", paste(cs, "one evidence row per table row"),
               nrow(r) == nrow(d) && identical(r$row, seq_len(nrow(d))))

    # ---- the fit R will be asked about -----------------------------------
    dd <- data.frame(x = d[[xc]], y = d[[yc]])
    ok <- complete.cases(dd)
    m  <- lm(y ~ x, data = dd[ok, , drop = FALSE])

    check("v24", paste(cs, "n (complete cases)"), f$n, sum(ok), tol = 0)
    check("v24", paste(cs, "p (model rank)"), f$p, m$rank, tol = 0)
    check("v24", paste(cs, "sigma"), f$sigma, summary(m)$sigma, tol = 1e-12)
    # @emlOLSInfluence forms sigma from sum(e^2); @emlLinearRegression forms
    # it from SSyy - b*SSxy. On real data the two must be indistinguishable,
    # or the augment frame's .std.resid would be scaled by a different sigma
    # than the one the glance frame prints as `sigma`. This is the assertion
    # that the better-conditioned formula did not buy accuracy at the price
    # of consistency. Relative, because sigma spans 0.88 to 10.1 here.
    check("v24", paste(cs, "sigma agrees with the fit's own, relatively"),
          abs(f$sigma - f$sigma.lr) / f$sigma, 0, tol = 1e-12)
    check("v24", paste(cs, "slope"), f$slope, unname(coef(m)[2]), tol = 1e-12)
    check("v24", paste(cs, "intercept"), f$intercept, unname(coef(m)[1]),
          tol = 1e-12)

    # ---- ROW ALIGNMENT ---------------------------------------------------
    # The plugin's vectors are indexed by TABLE ROW; R's are indexed by
    # complete case. If the plugin had reported its values in fitted order
    # while claiming table order, every number would still be individually
    # correct and every row would be attached to the wrong singer. The
    # `missing` case is here to make that failure visible: it has holes in
    # x and in y, in three different rows.
    check_true("v24", paste(cs, "used# marks exactly the complete cases"),
               identical(as.logical(r$used), unname(ok)))

    hat <- rep(NA_real_, nrow(d)); hat[ok] <- unname(hatvalues(m))
    rst <- rep(NA_real_, nrow(d)); rst[ok] <- unname(rstandard(m))
    ckd <- rep(NA_real_, nrow(d)); ckd[ok] <- unname(cooks.distance(m))
    fitv <- rep(NA_real_, nrow(d)); fitv[ok] <- unname(fitted(m))
    resv <- rep(NA_real_, nrow(d)); resv[ok] <- unname(residuals(m))

    fin <- !is.na(hat) & !is.na(rst) & !is.na(ckd)

    check("v24", paste(cs, "hat: max |plugin - hatvalues|"),
          max(abs(r$hat[!is.na(hat)] - hat[!is.na(hat)])), 0, tol = 1e-12)
    check("v24", paste(cs, "std.resid: max |plugin - rstandard|"),
          max(abs(r$std.resid[fin] - rst[fin])), 0, tol = 1e-11)
    check("v24", paste(cs, "cooksd: max |plugin - cooks.distance|"),
          max(abs(r$cooksd[fin] - ckd[fin])), 0, tol = 1e-11)
    check("v24", paste(cs, "fitted: max |plugin - fitted|"),
          max(abs(r$fitted[!is.na(fitv)] - fitv[!is.na(fitv)])), 0, tol = 1e-11)
    check("v24", paste(cs, "resid: max |plugin - residuals|"),
          max(abs(r$resid[!is.na(resv)] - resv[!is.na(resv)])), 0, tol = 1e-11)

    # Missingness must agree cell by cell, not only in count.
    check_true("v24", paste(cs, "std.resid NA pattern matches R"),
               identical(is.na(r$std.resid), is.na(rst)))
    check_true("v24", paste(cs, "cooksd NA pattern matches R"),
               identical(is.na(r$cooksd), is.na(ckd)))

    # ---- sum(h) = p, the identity that catches a wrong hat wholesale -----
    check("v24", paste(cs, "sum(hat) = p"), sum(r$hat, na.rm = TRUE), m$rank,
          tol = 1e-10)

    # ---- THE CORRECTION --------------------------------------------------
    # old = e/s. new = e/(s sqrt(1-h)). Their ratio is 1/sqrt(1-h), so the
    # correction is a shrink of the denominator, never a sign change, and it
    # is largest exactly where leverage is largest. Both halves are asserted:
    # the identity, and that it is not the identity map.
    oldv <- r$old.std.resid
    ratio_ok <- fin & abs(oldv) > 1e-9
    if (any(ratio_ok)) {
        check("v24", paste(cs, "std.resid = old / sqrt(1 - h)"),
              max(abs(r$std.resid[ratio_ok] -
                      oldv[ratio_ok] / sqrt(1 - r$hat[ratio_ok]))), 0,
              tol = 1e-11)
        check_true("v24",
                   paste(cs, "correction is non-trivial (old != rstandard)"),
                   max(abs(oldv[ratio_ok] - rst[ratio_ok])) > 1e-6)
        # And the OLD form must NOT pass as rstandard. Pinned, so that if
        # someone reverts the augment site to e/s this file goes red.
        check("v24", paste(cs, "old e/s is NOT rstandard"),
              max(abs(oldv[ratio_ok] - rst[ratio_ok])), 0,
              tol = 1e-6, expect = "differ")
    }
}

# The high-leverage row must actually be high-leverage, or the "designed
# high-leverage case" is only a claim. 2p/n is the conventional flag.
lv <- rows[rows$case == "leverage", , drop = FALSE]
check_true("v24", "leverage case: row 26 exceeds the 2p/n rule of thumb",
           lv$hat[lv$row == 26] > 2 * 2 / nrow(lv))
check_true("v24", "leverage case: row 26 has the largest hat",
           which.max(lv$hat) == 26)
# Leverage alone is not influence: the same point ON the line has small
# Cook's D; move it off the line and it dominates. This is the distinction
# .hat and .cooksd exist to draw, and if both columns tracked each other
# perfectly one of them would be redundant.
ot <- rows[rows$case == "outlier", , drop = FALSE]
check_true("v24", "outlier case: same leverage, far larger Cook's D",
           ot$cooksd[ot$row == 26] > 20 * lv$cooksd[lv$row == 26])
check_true("v24", "leverage case: high-leverage point is not flagged by D",
           which.max(lv$cooksd) != 26)


# ===========================================================================
# RED PATHS -- a refusal is only correct if R agrees there was nothing to fit
# ===========================================================================
refuse <- function(cs, why, warranted) {
    saw(cs)
    f <- fit_row(cs)
    check_true("v24", paste(cs, "refused"), nzchar(f$error))
    check_true("v24", paste(cs, "refusal is warranted:", why), warranted)
    check_true("v24", paste(cs, "emitted no rows"),
               sum(rows$case == cs) == 0)
    f$error
}

# --- n = 2: n <= p, no residual df -----------------------------------------
d <- case_data("red_n2")
e <- refuse("red_n2", "n <= p", nrow(d) <= 2)
check_true("v24", "red_n2 wording names the shortfall",
           grepl("at least 3", e, fixed = TRUE) && grepl("found 2", e, fixed = TRUE))
# R's own verdict on the same data: zero residual degrees of freedom.
m <- lm(y ~ x, data = d)
check("v24", "red_n2: R residual df", 0, df.residual(m), tol = 0)
check_true("v24", "red_n2: R's sigma is not a number",
           !is.finite(summary(m)$sigma) || is.nan(summary(m)$sigma))

# --- constant predictor: SSxx = 0 ------------------------------------------
d <- case_data("red_const")
e <- refuse("red_const", "predictor has zero variance", var(d$x) == 0)
check_true("v24", "red_const wording matches the regression's own",
           identical(e, "Predictor has zero variance."))
# R does not refuse; it drops the term and returns NA for the slope. That is
# a different contract, and the point of asserting it is that the plugin's
# refusal is a CHOICE, not an accident of agreeing with R.
m <- lm(y ~ x, data = d)
check_true("v24", "red_const: R silently drops the slope (rank 1, NA coef)",
           m$rank == 1 && is.na(coef(m)["x"]))

# --- perfect fit: sigma = 0 ------------------------------------------------
d <- case_data("red_perfect")
m <- suppressWarnings(lm(y ~ x, data = d))
e <- refuse("red_perfect", "sigma = 0", summary(m)$sigma < 1e-12)
check_true("v24", "red_perfect wording names the collinearity",
           grepl("exactly on the line", e, fixed = TRUE))

# WHAT R DOES HERE IS THE ARGUMENT FOR THE REFUSAL, and it is not what this
# script first claimed. The first draft asserted "R returns NaN for every
# row". That is true only when the residuals come out bit-exactly zero. On
# THIS data they do not: R fits by QR and leaves residuals of order 1e-15,
# so sigma is 1.6e-15 rather than 0, nothing is NaN, and rstandard returns
# values of order 1 -- -1.43, 2.52, 0.88 -- computed entirely from rounding
# error. R warns ("essentially perfect fit") and reports the noise anyway.
#
# The plugin's normal-equations RSS came out exactly 0 on the same data, so
# it refuses. That is the better contract, and asserting it honestly is
# worth more than asserting the tidier claim that was false.
check_true("v24", "red_perfect: R's residuals are all below 1e-12",
           max(abs(residuals(m))) < 1e-12)
check_true("v24", "red_perfect: yet R's rstandard is O(1) -- noise, not NaN",
           max(abs(suppressWarnings(rstandard(m)))) > 0.5)
check_true("v24", "red_perfect: R's cooks.distance likewise",
           max(abs(suppressWarnings(cooks.distance(m)))) > 0.5)
# But hat is perfectly well defined, which is why this is a refusal about
# sigma and not about leverage.
check_true("v24", "red_perfect: R's hatvalues are all finite",
           all(is.finite(hatvalues(m))))

# --- near-perfect fit: sigma tiny but REAL ---------------------------------
# The flip side, and the limit of the refusal. The guard is `sigma > 0`
# exactly, so a fit that misses by 1e-9 is NOT refused and produces large
# standardised residuals. That is not a defect, it is parity: R does the
# same, and the two must agree numerically. Without this case the refusal
# above could be widened to a tolerance by a later editor with nothing to
# tell them what that would break.
saw("nearperfect")
f <- fit_row("nearperfect")
d <- case_data("nearperfect")
m <- suppressWarnings(lm(y ~ x, data = d))
r <- rows[rows$case == "nearperfect", , drop = FALSE]
r <- r[order(r$row), , drop = FALSE]
check_true("v24", "nearperfect did NOT refuse", identical(f$error, ""))
check_true("v24", "nearperfect: sigma is tiny but positive",
           f$sigma > 0 && f$sigma < 1e-8)
# TOLERANCES HERE ARE LOOSE ON PURPOSE, and the reason is not slack.
# The residuals on this fit are of order 1e-10, and a residual formed in
# double precision from data of order 10 carries absolute rounding of order
# 1e-15 whatever the algorithm. So the best RELATIVE agreement any two
# implementations can reach on these residuals is ~1e-5, and sigma and every
# standardised quantity inherit that. R itself would not agree with a second
# R to better than this. Measured gaps: sigma 7.8e-7 relative, residuals
# 3.9e-15 absolute, std.resid 1.2e-5, cooksd 2.3e-6. The tolerances are set
# an order of magnitude above what was measured, not at the noise floor, so
# they document the limit rather than encoding today's exact rounding.
check("v24", "nearperfect: sigma matches R (relative, 1e-5 floor)",
      abs(f$sigma - summary(m)$sigma) / summary(m)$sigma, 0, tol = 1e-5)

# THE CANCELLATION, pinned. This is the case that forced @emlOLSInfluence to
# form sigma from sum(e^2) rather than read @emlLinearRegression.seResidual.
# The fit's own sigma is wrong here by more than two orders of magnitude,
# while its slope, intercept and residuals are all correct to the last bit.
# Asserted as a DIFFERENCE so that if @emlLinearRegression is ever fixed to
# accumulate sum(e^2) itself, this check goes red and points at the comment
# in @emlOLSInfluence that is then obsolete.
check_true("v24", "nearperfect: the fit's own sigma is the broken one",
           f$sigma.lr / summary(m)$sigma > 100)
check("v24", "nearperfect: fit sigma vs R (pinning the SSyy-SSreg defect)",
      f$sigma.lr, summary(m)$sigma, tol = 1e-9, expect = "differ")
check("v24", "nearperfect: residuals agree to the rounding floor",
      max(abs(r$resid - unname(residuals(m)))), 0, tol = 1e-14)
check("v24", "nearperfect: slope is exact despite the bad sigma",
      f$slope, unname(coef(m)[2]), tol = 1e-14)
check("v24", "nearperfect: std.resid still matches rstandard",
      max(abs(r$std.resid - unname(rstandard(m)))), 0, tol = 1e-4)
check("v24", "nearperfect: cooksd still matches cooks.distance",
      max(abs(r$cooksd - unname(cooks.distance(m)))), 0, tol = 1e-4)
check_true("v24", "nearperfect: values are large but finite, not inf",
           all(is.finite(r$std.resid)) && max(abs(r$std.resid)) > 1)

# --- column not found ------------------------------------------------------
saw("red_nocol")
f <- fit_row("red_nocol")
check_true("v24", "red_nocol refused", nzchar(f$error))
check_true("v24", "red_nocol names the missing column and the table",
           grepl("not_a_column", f$error, fixed = TRUE) &&
           grepl("red_nocol", f$error, fixed = TRUE))
check_true("v24", "red_nocol emitted no rows", sum(rows$case == "red_nocol") == 0)

# --- leverage EXACTLY 1: not a refusal, one undefined row ------------------
# The two cases differ only in x[24], and only in the last bit of the
# resulting hat: 1.4 lands below 1, 0.7 lands above. Both must clamp to 1 and
# both must yield undefined. Before the clamp, the two sides answered
# differently -- @emlLMMInfluence, on the same shape, returned Cook's D =
# 46.56 for the below case and undefined for the above.
for (cs in c("red_lev1", "red_lev1b")) {
    f <- fit_row(cs)
    r <- rows[rows$case == cs, , drop = FALSE]
    d <- case_data(cs)
    m <- lm(y ~ x, data = d)
    check_true("v24", paste(cs, "did NOT refuse: 23 rows are still reportable"),
               identical(f$error, ""))
    check("v24", paste(cs, "n.singular"), f$n.singular, 1, tol = 0)
    check("v24", paste(cs, "hat at the leverage-1 row is exactly 1"),
          r$hat[r$row == 24], 1, tol = 0)
    check("v24", paste(cs, "R's hatvalues agree it is exactly 1"),
          unname(hatvalues(m))[24], 1, tol = 0)
    check_na_pair("v24", paste(cs, "std.resid undefined there, as R's NaN"),
                  r$std.resid[r$row == 24], unname(rstandard(m))[24])
    check_na_pair("v24", paste(cs, "cooksd undefined there, as R's NaN"),
                  r$cooksd[r$row == 24], unname(cooks.distance(m))[24])
    check_true("v24", paste(cs, "no inf, no absurd finite value, anywhere"),
               all(is.finite(r$cooksd[!is.na(r$cooksd)])) &&
               all(is.finite(r$std.resid[!is.na(r$std.resid)])))
    check_true("v24", paste(cs, "the other 23 rows are finite and reported"),
               sum(!is.na(r$cooksd)) == 23)
}
# The two ulp neighbours must agree with each other, not merely each with R.
a <- rows[rows$case == "red_lev1",  ]; b <- rows[rows$case == "red_lev1b", ]
check_true("v24", "the two ulp neighbours give the same verdict at row 24",
           is.na(a$cooksd[a$row == 24]) && is.na(b$cooksd[b$row == 24]) &&
           a$hat[a$row == 24] == b$hat[b$row == 24])


# ===========================================================================
# LEDGER -- every driven case was checked
# ===========================================================================
check_true("v24", "every harness case is checked by this script",
           setequal(seen, fits$case))

if (!exists("EML_SUITE")) { eml_report("v24 influence diagnostics (OLS)"); eml_exit() }
