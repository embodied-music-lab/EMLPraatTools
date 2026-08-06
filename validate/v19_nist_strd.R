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
# Scored in LOG RELATIVE ERROR (correct significant digits), which is the
# convention StRD work is reported in, not pass/fail at a tolerance. The
# floor below which a check fails is deliberately generous; the number that
# matters is the LRE printed on each line.
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
  cat("          See validate/tools/nist_ingest.R for the two curl lines.\n")
} else {

res <- read.csv(res_file, stringsAsFactors = FALSE)

for (ds in unique(res$dataset)) {
  cert <- read.csv(file.path(nist_dir, paste0(ds, "_certified.csv")),
                   stringsAsFactors = FALSE)
  got  <- function(stat) {
    v <- res$value[res$dataset == ds & res$statistic == stat]
    if (length(v) != 1L) stop(sprintf("v19: %s/%s not reported once", ds, stat))
    v
  }
  # NIST names the rows per dataset ("Between Instrument", "Between
  # Treatment", ...), so the label is matched by its leading word rather than
  # hardcoded -- otherwise adding SmLs01 would silently match nothing and
  # contribute no checks.
  cv <- function(prefix, field) {
    row <- cert[startsWith(cert$label, prefix) & cert$field == field, ]
    if (nrow(row) != 1L) return(NA_real_)
    row$certified[1]
  }

  if (any(res$dataset == ds & res$statistic == "error")) {
    check_true("v19", paste(ds, "plugin ran without refusing"), FALSE)
    next
  }

  # The four ANOVA-table quantities, then the two certified summaries.
  # sumsq.between is the one that separates a two-pass routine from the
  # textbook computational form on a constant-leading-digits dataset.
  map <- list(
    c("df.between",     "Between", 1), c("sumsq.between",  "Between", 2),
    c("meansq.between", "Between", 3), c("statistic",      "Between", 4),
    c("df.within",      "Within",  1), c("sumsq.within",   "Within",  2),
    c("meansq.within",  "Within",  3),
    c("r.squared",      "Certified R-Squared", 1),
    c("residual.sd",    "Standard Deviation",  1)
  )
  for (m in map) {
    certified <- cv(m[2], as.integer(m[3]))
    if (is.na(certified)) next
    check_lre("v19", paste(ds, m[1]), got(m[1]), certified, floor_digits = 10)
  }
}

}

if (!exists("EML_SUITE")) { eml_report("v19 NIST StRD certified values"); eml_exit() }
