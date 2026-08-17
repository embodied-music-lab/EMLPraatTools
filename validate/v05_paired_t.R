# ============================================================================
# v05 — Compare paired/repeated: paired t-test and descriptives
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Wrapper:  Objects > New > EML Stats & Graphs > Compare paired/repeated...
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
cap <- capture("v05_paired_info.txt")
a <- d$jitter_pre; b <- d$jitter_post
tt <- t.test(a, b, paired = TRUE)

check_true("v05", "20 pairs", length(a) == 20L && length(b) == 20L)

# --- descriptives ---------------------------------------------------------
# The descriptives print in the wizard-style "label: Mean = x, SD = y,
# Median = z" form, one line per column, so they are read with @printed_eq.
check("v05", "jitter_pre mean",   printed_eq(cap, "jitter pre:", 1), mean(a),   tol = 5e-4)
check("v05", "jitter_pre SD",     printed_eq(cap, "jitter pre:", 2), sd(a),     tol = 5e-4)
check("v05", "jitter_pre median", printed_eq(cap, "jitter pre:", 3), median(a), tol = 5e-4)
check("v05", "jitter_post mean",   printed_eq(cap, "jitter post:", 1), mean(b),   tol = 5e-4)
check("v05", "jitter_post SD",     printed_eq(cap, "jitter post:", 2), sd(b),     tol = 5e-4)
check("v05", "jitter_post median", printed_eq(cap, "jitter post:", 3), median(b), tol = 5e-4)

# --- the test -------------------------------------------------------------
check("v05", "t statistic", printed(cap, "t"), unname(tt$statistic), tol = 5e-4)
check("v05", "df", printed(cap, "df"), unname(tt$parameter), tol = 0)
check_floored("v05", "paired t p", cap, "p", unname(tt$p.value), occurrence = 1)
check("v05", "mean difference",   printed(cap, "Mean difference"),   mean(a - b), tol = 5e-5)
check("v05", "SD of differences", printed(cap, "SD of differences"), sd(a - b),   tol = 5e-5)
# t must follow from the two printed summaries of the differences.
check("v05", "printed t follows from the printed mean and SD of differences",
      printed(cap, "t"),
      printed(cap, "Mean difference") / (printed(cap, "SD of differences") / sqrt(length(a))),
      tol = 5e-3)

# --- the CSV row exported from the graphs side ----------------------------
# This is the export that succeeds, and it carries more precision than the
# Info window does. Validating it separately keeps the two surfaces honest.
csv <- read_input("pairedLong_results_5aug.csv")
check_true("v05", "CSV export has exactly one data row", nrow(csv) == 1L)
# The CSV carries more precision than the Info window, which is the point of
# checking both surfaces. Compared against R, and against the Info window's
# own rounded t, so the two exports must describe the same run.
check("v05", "CSV statistic",  unname(tt$statistic), csv$statistic[1], tol = 5e-7)
check("v05", "CSV statistic agrees with the Info window t to its precision",
      printed(cap, "t"), csv$statistic[1], tol = 5e-4)
check("v05", "CSV df", printed(cap, "df"), csv$df[1], tol = 1e-9)
check("v05", "CSV p", csv$p[1], unname(tt$p.value), tol = 5e-8)
# D14/D35 as a test: the Info window floors this p to "< .001" while the CSV
# carries it to seven decimals. Two surfaces, two precisions, same run.
check_true("v05", "the Info window floors the p the CSV reports in full",
           grepl("<", printed_str(cap, "p", 1, 1)) && csv$p[1] > 0)
check_true("v05", "CSV effect_label is empty (finding D17)",
           is.na(csv$effect_label[1]) || csv$effect_label[1] == "")
check_true("v05", "CSV table name keeps its underscore (contrast with D6)",
           csv$table[1] == "demo_paired")

if (!exists("EML_SUITE")) { eml_report("v05 paired t-test"); eml_exit() }
