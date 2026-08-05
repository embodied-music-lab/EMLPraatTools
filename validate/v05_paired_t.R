# ============================================================================
# v05 — Compare paired/repeated: paired t-test and descriptives
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Wrapper:  Objects > New > EML Tools > Compare paired/repeated...
# Settings: Column 1 jitter_pre, Column 2 jitter_post, Test Paired t-test
#           (NOTE: the dialog's own defaults were jitter_pre and HNR_pre —
#           two different measures. See finding D77. The columns were set
#           deliberately for this run.)
# Input:    evidence/csv/demo_paired_input.csv
# Also validates the CSV row exported from the graphs side,
#           evidence/csv/pairedLong_results_5aug.csv
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d <- read_input("demo_paired_input.csv")
a <- d$jitter_pre; b <- d$jitter_post
tt <- t.test(a, b, paired = TRUE)

check_true("v05", "20 pairs", length(a) == 20L && length(b) == 20L)

# --- descriptives ---------------------------------------------------------
check("v05", "jitter_pre mean",    2.696, mean(a),   tol = 5e-4)
check("v05", "jitter_pre SD",      0.823, sd(a),     tol = 5e-4)
check("v05", "jitter_pre median",  2.683, median(a), tol = 5e-4)
check("v05", "jitter_post mean",   1.967, mean(b),   tol = 5e-4)
check("v05", "jitter_post SD",     0.917, sd(b),     tol = 5e-4)
check("v05", "jitter_post median", 2.280, median(b), tol = 5e-4)

# --- the test -------------------------------------------------------------
check("v05", "t statistic", 7.726, unname(tt$statistic), tol = 5e-4)
check_true("v05", "df reported as 19", unname(tt$parameter) == 19L)
check_below("v05", "p is < .001", 0.001, unname(tt$p.value))
check("v05", "mean difference",   0.7285, mean(a - b), tol = 5e-5)
check("v05", "SD of differences", 0.4217, sd(a - b),   tol = 5e-5)

# --- the CSV row exported from the graphs side ----------------------------
# This is the export that succeeds, and it carries more precision than the
# Info window does. Validating it separately keeps the two surfaces honest.
csv <- read_input("pairedLong_results_5aug.csv")
check_true("v05", "CSV export has exactly one data row", nrow(csv) == 1L)
check("v05", "CSV statistic",  7.725968, csv$statistic[1], tol = 5e-7)
check("v05", "CSV df",         19,       csv$df[1],        tol = 1e-9)
check("v05", "CSV p",          0.0000003, unname(tt$p.value), tol = 5e-8)
check_true("v05", "CSV effect_label is empty (finding D17)",
           is.na(csv$effect_label[1]) || csv$effect_label[1] == "")
check_true("v05", "CSV table name keeps its underscore (contrast with D6)",
           csv$table[1] == "demo_paired")

if (!exists("EML_SUITE")) { eml_report("v05 paired t-test"); eml_exit() }
