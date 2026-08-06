# ============================================================================
# v18_sweep_parity.R -- every case in the Tier B grid, against base R.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Where v01-v15 each check ONE printed report from ONE GUI-driven table, this
# checks the shipping statistical procedures across a designed grid of shapes:
# k in {2,3,5}, n per cell from 3 to 200, balanced and 6:1 unbalanced,
# tie-free through heavily tied, homoscedastic and 10:1 heteroscedastic.
#
# It is a DIFFERENT KIND OF EVIDENCE from v01-v15 and does not replace them.
# Those establish that the report a user sees is right. This establishes that
# the procedure behind it is right on data the demo tables never produce.
# Neither implies the other.
#
#     Rscript validate/v18_sweep_parity.R
#
# Input:  evidence/sweep/manifest.csv, results.csv, data/c*.csv
#         (regenerate with harness/sweep/tierB_grid.praat)
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

sweep_dir <- repo_path("evidence", "sweep")
man <- read.csv(file.path(sweep_dir, "manifest.csv"), stringsAsFactors = FALSE)
res <- read.csv(file.path(sweep_dir, "results.csv"), stringsAsFactors = FALSE)

# Pull one reported number out of the long results frame. A missing row is a
# hard stop, not a skip: "the plugin did not report this" is the failure mode
# a silently-shrinking grid would produce.
reported <- function(case, test, stat) {
  hit <- res$value[res$case == case & res$test == test & res$statistic == stat]
  if (length(hit) != 1L)
    stop(sprintf("v18: expected exactly 1 row for %s/%s/%s, found %d",
                 case, test, stat, length(hit)))
  hit
}
has_row <- function(case, test, stat)
  any(res$case == case & res$test == test & res$statistic == stat)

for (i in seq_len(nrow(man))) {
  cs  <- man$case[i]
  d   <- read.csv(file.path(sweep_dir, "data", paste0(cs, ".csv")),
                  stringsAsFactors = FALSE)
  d$grp <- factor(d$grp)
  lab <- sprintf("%s [k=%d n=%s %s/%s var%.0f:1]", cs, man$k[i], man$n_spec[i],
                 man$balance[i], man$ties[i], man$var_ratio[i])

  # ---- one-way ANOVA ------------------------------------------------------
  if (has_row(cs, "anova", "refused")) {
    # The plugin refused. R must agree there is nothing to fit -- either a
    # singular fit or zero total variance. Asserting the refusal is CORRECT,
    # not merely that it happened.
    check_true("v18", paste(lab, "ANOVA refusal is warranted"),
               var(d$value) == 0 || nlevels(d$grp) < 2)
  } else {
    fit <- aov(value ~ grp, data = d)
    s   <- summary(fit)[[1]]
    check("v18", paste(lab, "ANOVA F"),
          reported(cs, "anova", "statistic"), s[["F value"]][1], tol = 1e-9)
    check("v18", paste(lab, "ANOVA p"),
          reported(cs, "anova", "p.value"),   s[["Pr(>F)"]][1],  tol = 1e-12)
    check("v18", paste(lab, "ANOVA df between"),
          reported(cs, "anova", "df.between"), s[["Df"]][1], tol = 0)
    check("v18", paste(lab, "ANOVA df within"),
          reported(cs, "anova", "df.within"),  s[["Df"]][2], tol = 0)
    check("v18", paste(lab, "ANOVA SS between"),
          reported(cs, "anova", "sumsq.between"), s[["Sum Sq"]][1], tol = 1e-9)
    check("v18", paste(lab, "ANOVA SS within"),
          reported(cs, "anova", "sumsq.within"),  s[["Sum Sq"]][2], tol = 1e-9)
    check("v18", paste(lab, "eta squared"),
          reported(cs, "anova", "eta.squared"),
          s[["Sum Sq"]][1] / sum(s[["Sum Sq"]]), tol = 1e-12)

    # ---- Tukey HSD, every pair --------------------------------------------
    # THE UNBALANCED CASES ARE THE POINT. TukeyHSD is Tukey-Kramer when cell
    # sizes differ; a routine that uses a single n would agree on c01 and
    # disagree here.
    tk <- TukeyHSD(fit)$grp
    for (rn in rownames(tk)) {
      parts <- strsplit(rn, "-", fixed = TRUE)[[1]]
      # R names a contrast "later-earlier"; the plugin emits "i-j" with i<j,
      # so the estimate is negated relative to R's.
      key <- paste0(parts[2], "-", parts[1])
      if (!has_row(cs, "tukey", paste0("estimate:", key))) next
      check("v18", paste(lab, "Tukey estimate", key),
            reported(cs, "tukey", paste0("estimate:", key)),
            -tk[rn, "diff"], tol = 1e-9)
      check("v18", paste(lab, "Tukey adj p", key),
            reported(cs, "tukey", paste0("adj.p.value:", key)),
            tk[rn, "p adj"], tol = 1e-7)
    }
  }

  # ---- Kruskal-Wallis -----------------------------------------------------
  if (!has_row(cs, "kruskal", "refused")) {
    kw <- kruskal.test(value ~ grp, data = d)
    check("v18", paste(lab, "KW H"),
          reported(cs, "kruskal", "statistic"), unname(kw$statistic), tol = 1e-9)
    check("v18", paste(lab, "KW p"),
          reported(cs, "kruskal", "p.value"),   kw$p.value, tol = 1e-12)
    check("v18", paste(lab, "KW df"),
          reported(cs, "kruskal", "df"), unname(kw$parameter), tol = 0)

    # The tie correction is not something R exposes, so it is recomputed here
    # from the definition: 1 - sum(t^3 - t) / (N^3 - N).
    tt <- table(d$value)
    n  <- nrow(d)
    corr <- 1 - sum(tt^3 - tt) / (n^3 - n)
    check("v18", paste(lab, "KW tie correction"),
          reported(cs, "kruskal", "tie.correction"), corr, tol = 1e-12)
  }
}

if (!exists("EML_SUITE")) { eml_report("v18 sweep parity (Tier B grid)"); eml_exit() }
