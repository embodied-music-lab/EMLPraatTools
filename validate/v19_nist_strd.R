# ============================================================================
# v19_nist_strd.R -- the plugin against NIST's certified values.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Every other script in this folder ultimately asks "does R agree?". R is a
# peer implementation, not a referee: if the plugin and R made the same
# mistake, the suite would be green. This one asks a different question --
# does the plugin agree with a value certified by an outside body, computed
# in multiple-precision arithmetic and published to 15 significant digits?
#
# WHAT THE ANSWER TURNED OUT TO BE, AND WHY THE CRITERION IS WHAT IT IS
#
# NIST grades these datasets by difficulty, and the grading is real. The SmLs
# family increases the number of CONSTANT LEADING DIGITS in the observations:
# 1 in SmLs01-03, 7 in SmLs04-06, 13 in SmLs07-09. The between-group sum of
# squares stays around 1.68 while the observations grow to thirteen identical
# leading digits, so forming it at all means cancelling away almost the whole
# mantissa. Run on 6 August 2026:
#
#     dataset   plugin LRE   base R LRE
#     SmLs01      15.40        15.03
#     SmLs04       9.33        10.05
#     SmLs07       3.31         4.03
#     SmLs09       3.31         2.97
#
# Both lose digits, together, at the same rate -- and on the hardest set the
# plugin is AHEAD of R. That is the shape of a double-precision limit, not of
# an implementation defect. An absolute pass/fail floor would therefore be
# measuring the arithmetic of the IEEE double, not the quality of this code,
# and would fail four of eleven datasets for the wrong reason.
#
# So the assertion here is RELATIVE: the plugin must come within one
# significant digit of base R on the same data. That is falsifiable, it is
# about the thing actually under test, and it is the question a reviewer
# cares about -- is this implementation as numerically sound as the reference
# everyone else uses? The absolute LRE against NIST is printed on every line
# regardless, because it is the number worth reading.
#
# One digit of slack, not zero: the two implementations legitimately differ in
# summation order, and on a dataset engineered to cancel thirteen digits that
# alone moves the last surviving digit around.
#
#     Rscript validate/v19_nist_strd.R
#
# Input:  evidence/nist/<Name>_data.csv, <Name>_certified.csv, results.csv
#         (regenerate: nist_ingest.R for each .dat, then tierC_nist.praat)
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}
source(file.path(dirname(repo_path("validate", "helpers.R")), "lre.R"))

nist_dir <- repo_path("evidence", "nist")
res_file <- file.path(nist_dir, "results.csv")

# No datasets present is NOT a silent pass. The .dat files are not
# redistributable, so a fresh clone legitimately has none -- but the suite
# must say so out loud rather than contribute zero checks and look complete.
if (!file.exists(res_file)) {
  cat("SKIP  v19  no evidence/nist/results.csv -- NIST .dat files not ingested.\n")
  cat("          See validate/tools/nist_ingest.R for the fetch commands.\n")
} else {

res <- read.csv(res_file, stringsAsFactors = FALSE)
SLACK <- 1.0   # significant digits the plugin may trail base R by

summary_rows <- list()

for (ds in sort(unique(res$dataset))) {
  cert <- read.csv(file.path(nist_dir, paste0(ds, "_certified.csv")),
                   stringsAsFactors = FALSE)
  d <- read.csv(file.path(nist_dir, paste0(ds, "_data.csv")),
                stringsAsFactors = FALSE)

  if (any(res$dataset == ds & res$statistic == "error")) {
    check_true("v19", paste(ds, "plugin ran without refusing"), FALSE)
    next
  }

  got <- function(stat) {
    v <- res$value[res$dataset == ds & res$statistic == stat]
    if (length(v) != 1L) stop(sprintf("v19: %s/%s not reported once", ds, stat))
    v
  }
  # NIST names the ANOVA rows per dataset ("Between Instrument", "Between
  # Treatment", ...), so labels are matched by leading word rather than
  # hardcoded -- otherwise a new dataset would silently match nothing and
  # contribute no checks.
  cv <- function(prefix, field) {
    row <- cert[startsWith(cert$label, prefix) & cert$field == field, ]
    if (nrow(row) != 1L) return(NA_real_)
    row$certified[1]
  }

  # base R on the same file, as the comparison implementation
  s   <- summary(aov(value ~ factor(grp), data = d))[[1]]
  ssb <- s[["Sum Sq"]][1];  ssw <- s[["Sum Sq"]][2]
  rv  <- list(
    df.between     = s[["Df"]][1],       sumsq.between  = ssb,
    meansq.between = s[["Mean Sq"]][1],  statistic      = s[["F value"]][1],
    df.within      = s[["Df"]][2],       sumsq.within   = ssw,
    meansq.within  = s[["Mean Sq"]][2],  r.squared      = ssb / (ssb + ssw),
    residual.sd    = sqrt(s[["Mean Sq"]][2])
  )

  map <- list(
    c("df.between",     "Between", 1), c("sumsq.between",  "Between", 2),
    c("meansq.between", "Between", 3), c("statistic",      "Between", 4),
    c("df.within",      "Within",  1), c("sumsq.within",   "Within",  2),
    c("meansq.within",  "Within",  3),
    c("r.squared",      "Certified R-Squared", 1),
    c("residual.sd",    "Standard Deviation",  1)
  )

  for (m in map) {
    stat <- m[1]
    certified <- cv(m[2], as.integer(m[3]))
    if (is.na(certified)) next

    plugin_lre <- lre(got(stat), certified)
    r_lre      <- lre(rv[[stat]], certified)

    check_true("v19",
      sprintf("%s %s | NIST LRE %.2f digits (base R %.2f, may trail by %.1f)",
              ds, stat, plugin_lre, r_lre, SLACK),
      is.finite(plugin_lre) && plugin_lre >= r_lre - SLACK)

    if (stat == "sumsq.between")
      summary_rows[[length(summary_rows) + 1L]] <-
        sprintf("  %-9s plugin %6.2f   base R %6.2f", ds, plugin_lre, r_lre)
  }
}

if (length(summary_rows)) {
  cat("\n  Correct significant digits on the between-group sum of squares,\n")
  cat("  the quantity NIST's difficulty grading is built to stress:\n\n")
  cat(paste(unlist(summary_rows), collapse = "\n"), "\n")
}

}

if (!exists("EML_SUITE")) { eml_report("v19 NIST StRD certified values"); eml_exit() }
