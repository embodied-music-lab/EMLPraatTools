# ============================================================================
# v20_shipping_anova_broom.R -- the SHIPPING ANOVA path, in broom's shape.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT MAKES THIS DIFFERENT FROM v17, AND WHY IT HAD TO EXIST
#
# v17 checks `harness/broom_cases/anova_oneway.praat`, which calls the result
# writer DIRECTLY. That proved the writer works. It did not prove that any
# code a user can reach produces those files -- and the CSV migration was
# once recorded as done on exactly that evidence.
#
# This checks the output of `@emlRunAnovaAnalysis`, the orchestrator the menu
# calls, driven end to end by `harness/broom_cases/anova_shipping_drive.praat`.
# A path is not converted until it has a check at this level.
#
# BROOM ITSELF IS NOT INSTALLABLE ON R 4.3.3 HERE, so the contract is asserted
# from broom's documentation rather than by diffing against a live broom call,
# and every VALUE is checked against base R. The distinction is stated on each
# structural check so no reader mistakes one for the other.
#
#     Rscript validate/v20_shipping_anova_broom.R
#
# Input:  evidence/csv/v09_anova_tukey_input.csv  (the driven fixture)
#         evidence/csv_export/broom/shipping_anova_*.csv
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

B   <- repo_path("evidence", "csv_export", "broom")
d   <- read.csv(repo_path("evidence", "csv", "v09_anova_tukey_input.csv"))
fit <- aov(SPL_dB ~ voice_type, data = d)
s   <- summary(fit)[[1]]
sl  <- summary.lm(fit)

rd <- function(f) read.csv(file.path(B, paste0("shipping_anova_", f, ".csv")),
                           stringsAsFactors = FALSE, check.names = FALSE)

# --- tidy ------------------------------------------------------------------
# broom::tidy(aov) is documented as exactly: term, df, sumsq, meansq,
# statistic, p.value -- in that order, one row per term plus Residuals, with
# statistic and p.value NA on the Residuals row. Column ORDER is asserted, not
# just membership: a reader diffing against a real broom frame would see order.
ti <- rd("tidy")
check_true("v20", "tidy columns are broom's, in broom's order",
           identical(names(ti),
                     c("term","df","sumsq","meansq","statistic","p.value")))
check_true("v20", "tidy has one row per term plus Residuals",
           nrow(ti) == 2L && ti$term[2] == "Residuals")
check_true("v20", "tidy term names the factor, not the formula",
           ti$term[1] == "voice_type")
check("v20", "tidy df (factor)",      ti$df[1],     s[["Df"]][1],      tol = 0)
check("v20", "tidy df (Residuals)",   ti$df[2],     s[["Df"]][2],      tol = 0)
check("v20", "tidy sumsq (factor)",   ti$sumsq[1],  s[["Sum Sq"]][1],  tol = 1e-9)
check("v20", "tidy sumsq (Residuals)",ti$sumsq[2],  s[["Sum Sq"]][2],  tol = 1e-9)
check("v20", "tidy meansq (factor)",  ti$meansq[1], s[["Mean Sq"]][1], tol = 1e-9)
check("v20", "tidy meansq (Residuals)",ti$meansq[2],s[["Mean Sq"]][2], tol = 1e-9)
check("v20", "tidy statistic",        ti$statistic[1], s[["F value"]][1], tol = 1e-9)
check("v20", "tidy p.value",          ti$p.value[1],   s[["Pr(>F)"]][1],  tol = 1e-14)

# broom leaves these NA on Residuals. An empty CSV cell reads as NA, which is
# the point -- a zero here would be a different and wrong claim.
check_true("v20", "tidy Residuals statistic is NA, as broom leaves it",
           is.na(ti$statistic[2]))
check_true("v20", "tidy Residuals p.value is NA, as broom leaves it",
           is.na(ti$p.value[2]))

# --- glance ----------------------------------------------------------------
gl <- rd("glance")
check_true("v20", "glance is exactly one row", nrow(gl) == 1L)
ssb <- s[["Sum Sq"]][1]; ssw <- s[["Sum Sq"]][2]
check("v20", "glance r.squared",     gl$r.squared,     ssb / (ssb + ssw), tol = 1e-12)
check("v20", "glance adj.r.squared", gl$adj.r.squared, sl$adj.r.squared,  tol = 1e-12)
check("v20", "glance sigma",         gl$sigma,         sl$sigma,          tol = 1e-12)
check("v20", "glance statistic",     gl$statistic,     s[["F value"]][1], tol = 1e-9)
check("v20", "glance p.value",       gl$p.value,       s[["Pr(>F)"]][1],  tol = 1e-14)
check("v20", "glance df",            gl$df,            s[["Df"]][1],      tol = 0)
check("v20", "glance df.residual",   gl$df.residual,   s[["Df"]][2],      tol = 0)
check("v20", "glance deviance",      gl$deviance,      ssw,               tol = 1e-9)
check("v20", "glance nobs",          gl$nobs,          nrow(d),           tol = 0)

# logLik / AIC / BIC are the checks that catch a hand-rolled Gaussian
# likelihood being subtly wrong -- k, or the +1, or the 2*pi.
check("v20", "glance logLik", gl$logLik, as.numeric(logLik(fit)), tol = 1e-9)
check("v20", "glance AIC",    gl$AIC,    AIC(fit),                tol = 1e-9)
check("v20", "glance BIC",    gl$BIC,    BIC(fit),                tol = 1e-9)

# --- augment ---------------------------------------------------------------
# broom::augment returns the input data plus dot-prefixed columns, one row per
# observation. The dot prefix is the convention that keeps them from colliding
# with a user column, so it is asserted rather than assumed.
au <- rd("augment")
check_true("v20", "augment is one row per observation", nrow(au) == nrow(d))
check_true("v20", "augment carries the input columns through",
           all(names(d) %in% names(au)))
check_true("v20", "augment adds only dot-prefixed columns",
           all(startsWith(setdiff(names(au), names(d)), ".")))
check_true("v20", "augment has .fitted, .resid, .std.resid",
           all(c(".fitted",".resid",".std.resid") %in% names(au)))
check("v20", "augment .fitted total deviation",
      sum(abs(au$.fitted - fitted(fit))), 0, tol = 1e-9)
check("v20", "augment .resid total deviation",
      sum(abs(au$.resid - residuals(fit))), 0, tol = 1e-9)
check("v20", "augment .std.resid total deviation",
      sum(abs(au$.std.resid - residuals(fit) / sl$sigma)), 0, tol = 1e-9)

# --- post-hoc: a SECOND model object, therefore a second file --------------
# tidy(TukeyHSD(fit)) is documented as term, contrast, null.value, estimate,
# conf.low, conf.high, adj.p.value. It is emphatically not extra rows on
# tidy(aov), and the file layout has to say so.
ph <- rd("posthoc_tidy")
check_true("v20", "post-hoc is its own frame with broom's TukeyHSD columns",
           identical(names(ph), c("term","contrast","null.value","estimate",
                                  "conf.low","conf.high","adj.p.value")))
tk <- TukeyHSD(fit)$voice_type
check_true("v20", "post-hoc has one row per pair", nrow(ph) == nrow(tk))
check_true("v20", "post-hoc null.value is 0 throughout", all(ph$null.value == 0))
for (rn in rownames(tk)) {
  i <- match(rn, ph$contrast)
  check_true("v20", paste("post-hoc names contrast", rn, "as R does"), !is.na(i))
  if (is.na(i)) next
  check("v20", paste("post-hoc estimate", rn),  ph$estimate[i],  tk[rn,"diff"], tol = 1e-9)
  # The interval is the studentised-range one, not a t interval -- checking it
  # against TukeyHSD's own lwr/upr is what distinguishes them.
  check("v20", paste("post-hoc conf.low", rn),  ph$conf.low[i],  tk[rn,"lwr"],  tol = 1e-7)
  check("v20", paste("post-hoc conf.high", rn), ph$conf.high[i], tk[rn,"upr"],  tol = 1e-7)
  check("v20", paste("post-hoc adj.p.value", rn), ph$adj.p.value[i],
        tk[rn,"p adj"], tol = 1e-7)
}

# --- effect sizes: a THIRD object ------------------------------------------
es <- rd("effectsize_tidy")
check_true("v20", "effect sizes are their own frame",
           all(c("term","effect.size","effect.size.type") %in% names(es)))
eta <- es$effect.size[es$effect.size.type == "eta.squared"]
check_true("v20", "exactly one eta squared row", length(eta) == 1L)
check("v20", "effect size eta squared", eta[1], ssb / (ssb + ssw), tol = 1e-12)
check_true("v20", "one Cohen's d per pair",
           sum(es$effect.size.type == "cohens.d") == nrow(tk))

# --- the whole point: these came from the shipping orchestrator ------------
attest("v20", "these five files were produced by @emlRunAnovaAnalysis",
       "harness/broom_cases/anova_shipping_drive.praat calls the orchestrator the menu calls, not the writer directly")

if (!exists("EML_SUITE")) { eml_report("v20 shipping ANOVA, broom shape"); eml_exit() }
