#!/usr/bin/env Rscript
# ============================================================================
# v17 — broom parity for the three-verb CSV export
# ============================================================================
# Fits the same model in R, then checks our tidy/glance/augment against it,
# structurally first and numerically second.
#
# TWO MODES, and the script says which one it ran in.
#
#   BROOM   — broom is installed. Structure is compared against
#             broom::tidy/glance/augment output directly, so the expected
#             column names come from broom itself and cannot drift.
#   BASE    — broom is not installed. Numbers still come from R (aov,
#             TukeyHSD), but the expected COLUMN LAYOUT is the literal list
#             below, transcribed from broom's documented output. A BASE pass
#             is weaker: it proves the numbers, not that we match broom's
#             current naming.
#
# A BASE run is not a substitute for a BROOM run before release.
#
# Usage: Rscript validate/v17_broom_parity.R <dir-with-anova_*.csv> <fixture.csv>
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
dir <- if (length(args) >= 1) args[1] else "/home/claude/stress/broom"
fixture <- if (length(args) >= 2) args[2] else file.path(dir, "fixture.csv")

HAVE_BROOM <- requireNamespace("broom", quietly = TRUE)
MODE <- if (HAVE_BROOM) "BROOM" else "BASE"

pass <- 0L; fail <- 0L; notes <- character(0)
ok <- function(label, cond, detail = "") {
  if (isTRUE(cond)) { pass <<- pass + 1L; cat(sprintf("  ok    %s\n", label)) }
  else { fail <<- fail + 1L
         cat(sprintf("  FAIL  %s%s\n", label,
                     if (nzchar(detail)) paste0("  [", detail, "]") else "")) }
}
near <- function(a, b, tol = 1e-8) {
  if (length(a) != length(b)) return(FALSE)
  both_na <- is.na(a) & is.na(b)
  all(both_na | (!is.na(a) & !is.na(b) &
                 abs(a - b) <= tol * pmax(1, abs(a), abs(b))))
}

cat(sprintf("v17 broom parity  [mode: %s]\n", MODE))
cat(sprintf("R %s\n\n", getRversion()))

dat <- read.csv(fixture, stringsAsFactors = FALSE, check.names = FALSE)
dat$voice_type <- factor(dat$voice_type)
fit <- aov(value ~ voice_type, data = dat)
sm  <- summary(fit)[[1]]

tidy_csv    <- read.csv(file.path(dir, "anova_tidy.csv"),
                        stringsAsFactors = FALSE, check.names = FALSE)
glance_csv  <- read.csv(file.path(dir, "anova_glance.csv"),
                        stringsAsFactors = FALSE, check.names = FALSE)
augment_csv <- read.csv(file.path(dir, "anova_augment.csv"),
                        stringsAsFactors = FALSE, check.names = FALSE)

# ---------------------------------------------------------------- structure
cat("STRUCTURE\n")

# broom::tidy(aov) columns, in order.
expect_tidy_core <- c("term", "df", "sumsq", "meansq", "statistic", "p.value")
expect_tukey <- c("term", "contrast", "null.value", "estimate",
                  "conf.low", "conf.high", "adj.p.value")
if (HAVE_BROOM) {
  bt <- broom::tidy(fit)
  expect_tidy_core <- names(bt)
  notes <- c(notes, "tidy column names taken from broom::tidy(aov)")
}
ok("tidy is EXACTLY broom::tidy(aov)'s columns, in order",
   identical(names(tidy_csv), expect_tidy_core),
   paste("got:", paste(names(tidy_csv), collapse = ", ")))
ok("tidy carries every broom::tidy(aov) column",
   all(expect_tidy_core %in% names(tidy_csv)),
   paste("missing:", paste(setdiff(expect_tidy_core, names(tidy_csv)),
                           collapse = ", ")))

ok("tidy columns appear in broom's relative order",
   {
     have <- intersect(expect_tidy_core, names(tidy_csv))
     identical(have, expect_tidy_core[expect_tidy_core %in% have]) &&
       !is.unsorted(match(have, names(tidy_csv)))
   })

posthoc_csv <- read.csv(file.path(dir, "anova_posthoc_tidy.csv"),
                        stringsAsFactors = FALSE, check.names = FALSE)
es_csv <- read.csv(file.path(dir, "anova_effectsize_tidy.csv"),
                   stringsAsFactors = FALSE, check.names = FALSE)
if (HAVE_BROOM) expect_tukey <- names(broom::tidy(TukeyHSD(fit)))
ok("post-hoc is its own file, not extra rows on tidy(aov)",
   !("contrast" %in% names(tidy_csv)))
ok("post-hoc is EXACTLY broom::tidy(TukeyHSD)'s columns, in order",
   identical(names(posthoc_csv), expect_tukey),
   paste("got:", paste(names(posthoc_csv), collapse = ", ")))

model_rows <- tidy_csv
ok("tidy has one row per ANOVA term plus Residuals",
   nrow(model_rows) == nrow(sm),
   sprintf("csv %d vs aov %d", nrow(model_rows), nrow(sm)))
ok("last model row is Residuals",
   trimws(model_rows$term[nrow(model_rows)]) == "Residuals")
ok("glance is exactly one row", nrow(glance_csv) == 1)
ok("augment has one row per observation",
   nrow(augment_csv) == nrow(dat),
   sprintf("csv %d vs data %d", nrow(augment_csv), nrow(dat)))
ok("augment carries every input column",
   all(names(dat) %in% names(augment_csv)),
   paste("missing:", paste(setdiff(names(dat), names(augment_csv)),
                           collapse = ", ")))
ok("augment derived columns use broom's dot prefix",
   all(c(".fitted", ".resid") %in% names(augment_csv)))

# ------------------------------------------------------------------ numbers
cat("\nNUMBERS\n")
term_row <- model_rows[1, ]
res_row  <- model_rows[nrow(model_rows), ]

ok("df between",    near(as.numeric(term_row$df),     sm[1, "Df"]))
ok("df residual",   near(as.numeric(res_row$df),      sm[2, "Df"]))
ok("sumsq between", near(as.numeric(term_row$sumsq),  sm[1, "Sum Sq"],  1e-6))
ok("sumsq residual",near(as.numeric(res_row$sumsq),   sm[2, "Sum Sq"],  1e-6))
ok("meansq between",near(as.numeric(term_row$meansq), sm[1, "Mean Sq"], 1e-6))
ok("meansq residual",near(as.numeric(res_row$meansq), sm[2, "Mean Sq"], 1e-6))
ok("F statistic",   near(as.numeric(term_row$statistic), sm[1, "F value"], 1e-6))
ok("p value",       near(as.numeric(term_row$p.value),   sm[1, "Pr(>F)"],  1e-6))

r2  <- sm[1, "Sum Sq"] / (sm[1, "Sum Sq"] + sm[2, "Sum Sq"])
n   <- nrow(dat)
ok("glance nobs",        near(as.numeric(glance_csv$nobs), n))
ok("glance F",           near(as.numeric(glance_csv$statistic), sm[1, "F value"], 1e-6))
ok("glance df.residual", near(as.numeric(glance_csv$df.residual), sm[2, "Df"]))
ok("glance r.squared",   near(as.numeric(glance_csv$r.squared), r2, 1e-6))
ok("glance sigma = residual SE",
   near(as.numeric(glance_csv$sigma), sqrt(sm[2, "Mean Sq"]), 1e-6))
ok("glance adj.r.squared",
   near(as.numeric(glance_csv$adj.r.squared),
        1 - (1 - r2) * (n - 1) / sm[2, "Df"], 1e-6))
ok("glance deviance = residual sum of squares",
   near(as.numeric(glance_csv$deviance), sm[2, "Sum Sq"], 1e-6))
ok("glance logLik matches R", near(as.numeric(glance_csv$logLik),
                                   as.numeric(logLik(fit)), 1e-6))
ok("glance AIC matches R", near(as.numeric(glance_csv$AIC), AIC(fit), 1e-6))
ok("glance BIC matches R", near(as.numeric(glance_csv$BIC), BIC(fit), 1e-6))
glance_lm_order <- c("r.squared", "adj.r.squared", "sigma", "statistic",
                     "p.value", "df", "logLik", "AIC", "BIC", "deviance",
                     "df.residual", "nobs")
if (HAVE_BROOM) glance_lm_order <- names(broom::glance(lm(value ~ voice_type,
                                                          data = dat)))
ok("glance leads with broom::glance(lm)'s columns, in order",
   identical(head(names(glance_csv), length(glance_lm_order)), glance_lm_order),
   paste("got:", paste(names(glance_csv), collapse = ", ")))

ok("effect sizes are their own file",
   !any(c("effect.size", "effect.size.type") %in%
        c(names(tidy_csv), names(posthoc_csv))))
ok("eta squared equals r.squared",
   near(as.numeric(es_csv$effect.size[es_csv$effect.size.type ==
                                      "eta.squared"]), r2, 1e-6))

fitted_r <- as.numeric(ave(dat$value, dat$voice_type))
ok("augment .fitted = group means",
   near(as.numeric(augment_csv$.fitted), fitted_r, 1e-6))
ok("augment .resid = value - fitted",
   near(as.numeric(augment_csv$.resid), dat$value - fitted_r, 1e-6))
ok("augment .resid sums to zero",
   abs(sum(as.numeric(augment_csv$.resid))) < 1e-6)

# Tukey
tk <- as.data.frame(TukeyHSD(fit)$voice_type)
contrast_rows <- posthoc_csv
ok("one tidy row per Tukey contrast",
   nrow(contrast_rows) == nrow(tk),
   sprintf("csv %d vs R %d", nrow(contrast_rows), nrow(tk)))
if (nrow(contrast_rows) == nrow(tk)) {
  # Match on VALUES, not on contrast names. R builds Tukey rownames by pasting
  # the two level names with "-", so a level that itself contains a hyphen --
  # "Mezzo-soprano" is an ordinary voice type -- makes the name ambiguous to
  # parse in R's own output as much as in ours. Sorting the (|difference|,
  # adjusted p) pairs sidesteps a fragile string split entirely and still
  # proves every contrast is present with the right numbers.
  ours <- data.frame(d = abs(as.numeric(contrast_rows$estimate)),
                     p = as.numeric(contrast_rows$adj.p.value))
  theirs <- data.frame(d = abs(tk$diff), p = tk$`p adj`)
  ours   <- ours[order(ours$d), ]
  theirs <- theirs[order(theirs$d), ]
  ok("Tukey estimate (mean difference), as a set",
     near(ours$d, theirs$d, 1e-6))
  ok("Tukey adjusted p, as a set", near(ours$p, theirs$p, 1e-4))
  lo <- sort(as.numeric(contrast_rows$conf.low))
  hi <- sort(as.numeric(contrast_rows$conf.high))
  ok("Tukey conf.low matches R", near(lo, sort(tk$lwr), 1e-5))
  ok("Tukey conf.high matches R", near(hi, sort(tk$upr), 1e-5))
  ok("Tukey null.value is 0 on every row",
     all(as.numeric(contrast_rows$null.value) == 0))
  ok("every Tukey contrast names both of its levels",
     all(vapply(seq_len(nrow(contrast_rows)), function(i) {
       lv <- levels(dat$voice_type)
       sum(vapply(lv, function(L) grepl(L, contrast_rows$contrast[i],
                                        fixed = TRUE), TRUE)) >= 2
     }, TRUE)))
}

# -------------------------------------------------------------- red path
cat("\nRED PATH\n")
raw <- readLines(file.path(dir, "anova_tidy.csv"))
ok("no --undefined-- anywhere in any file",
   !any(grepl("--undefined--", c(raw,
        readLines(file.path(dir, "anova_glance.csv")),
        readLines(file.path(dir, "anova_augment.csv"))), fixed = TRUE)))
ok("Residuals row leaves statistic empty, not 0",
   is.na(res_row$statistic) | res_row$statistic == "")
ok("Residuals row leaves p.value empty, not 0",
   is.na(res_row$p.value) | res_row$p.value == "")
ok("a level name containing a comma survives the round trip",
   any(grepl(",", levels(dat$voice_type))) &&
   any(grepl(",", augment_csv$voice_type)))
ok("every tidy row has the same field count",
   length(unique(count.fields(file.path(dir, "anova_tidy.csv"),
                              sep = ",", quote = "\""))) == 1)
ok("every augment row has the same field count",
   length(unique(count.fields(file.path(dir, "anova_augment.csv"),
                              sep = ",", quote = "\""))) == 1)

cat(sprintf("\n%d passed, %d failed  [mode: %s]\n", pass, fail, MODE))
if (MODE == "BASE") {
  cat("NOTE: broom is not installed here, so column names were checked against\n")
  cat("      a transcribed list rather than against broom itself. Re-run where\n")
  cat("      broom is available before treating naming as validated.\n")
}
for (nte in notes) cat("NOTE:", nte, "\n")
quit(status = if (fail > 0) 1 else 0)
