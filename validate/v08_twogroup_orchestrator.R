# ============================================================================
# v08 — Compare two groups: does the orchestrator wire the right primitives?
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS IS FOR. The statistics themselves are already validated: Welch's
# t, Mann-Whitney U, Cohen's d and the rank-biserial correlation each have an
# external R or scipy oracle in plugin/dev/tests/phase2. What has never been
# tested is @emlRunTwoGroupAnalysis — the procedure that reads the Table,
# splits it on the group column, decides which primitive to call from the
# form's Test menu, and prints the results under headings.
#
# That layer is where D15 lived: two individually-correct effect sizes, one
# printed under the other's heading. A primitive-level suite cannot see it.
#
# EVERY REPORTED VALUE IS READ FROM THE COMMITTED CAPTURE. Nothing below is
# a number typed in by hand. @printed pulls the value out of
# evidence/info/v08_twogroup_info.txt by its printed label, so a green run
# means "what the capture says Praat printed agrees with base R" rather than
# "what the script's author believed Praat printed agrees with base R". A
# label that has moved, vanished or stopped parsing is an error that stops
# the script — the suite breaks rather than quietly testing nothing.
#
# DRIVEN 5 August 2026 through the real GUI under Xvfb:
#   New > EML Stats & Graphs > Compare two groups...
#   Data column jitter_pct, Group column group,
#   Test = "Both parametric and nonparametric", Group order = Table order.
#
# Input:  evidence/csv/v08_twogroup_input.csv   (the exact Table analysed —
#         demo tables are randomly generated, so regenerating will not
#         reproduce any number here)
# Output: evidence/info/v08_twogroup_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d   <- read_input("v08_twogroup_input.csv")
cap <- capture("v08_twogroup_info.txt")
stopifnot(all(c("group", "jitter_pct") %in% names(d)))

# Table order, as the form was set. Control appears first in the file.
lv <- unique(d$group)
check_true("v08", "group order is table order, Control first", lv[1] == "Control")
a <- d$jitter_pct[d$group == lv[1]]   # Control
b <- d$jitter_pct[d$group == lv[2]]   # Patient

# --- descriptives table ----------------------------------------------------
# The row reads: Group | N | Mean | SD | Median, so fields 1..4 after the
# group name. Reading them positionally from the row keeps each value tied
# to the group it was printed against.
check("v08", "N Control",      printed(cap, "Control", 1), length(a), tol = 0)
check("v08", "N Patient",      printed(cap, "Patient", 1), length(b), tol = 0)
check("v08", "mean Control",   printed(cap, "Control", 2), mean(a),   tol = 5e-3)
check("v08", "mean Patient",   printed(cap, "Patient", 2), mean(b),   tol = 5e-3)
check("v08", "SD Control",     printed(cap, "Control", 3), sd(a),     tol = 5e-3)
check("v08", "SD Patient",     printed(cap, "Patient", 3), sd(b),     tol = 5e-3)
check("v08", "median Control", printed(cap, "Control", 4), median(a), tol = 5e-3)
check("v08", "median Patient", printed(cap, "Patient", 4), median(b), tol = 5e-3)

# --- Welch t-test ----------------------------------------------------------
tt <- t.test(a, b, var.equal = FALSE)
check("v08", "Welch t",  printed(cap, "t"),  unname(tt$statistic), tol = 5e-4)
check("v08", "Welch df", printed(cap, "df"), unname(tt$parameter), tol = 5e-2)
check_floored("v08", "Welch p", cap, "p", unname(tt$p.value), occurrence = 1)
check("v08", "mean difference", printed(cap, "Mean difference"),
      mean(a) - mean(b), tol = 5e-5)

# The direction is part of the wiring, not of the arithmetic. If the
# orchestrator handed the groups over in the other order every sign here
# would flip while every magnitude stayed right.
check_true("v08", "sign convention is group1 - group2", (mean(a) - mean(b)) < 0)

# --- parametric effect size ------------------------------------------------
check("v08", "Cohen's d", printed(cap, "Cohen's d"), cohens_d(a, b), tol = 5e-4)

# Hedges' g = d * J, J = 1 - 3/(4(n1+n2) - 9).
J <- 1 - 3 / (4 * (length(a) + length(b)) - 9)
check("v08", "Hedges' g", printed(cap, "Hedges' g"), cohens_d(a, b) * J, tol = 5e-4)

# --- Mann-Whitney U --------------------------------------------------------
# R's wilcox.test returns U for the FIRST argument. The plugin prints both
# U1 and U2; U1 + U2 must equal n1*n2, which is the check that catches a
# wrapper reporting the same U twice under two labels.
U1 <- suppressWarnings(unname(wilcox.test(a, b, exact = TRUE)$statistic))
U2 <- length(a) * length(b) - U1
check("v08", "Mann-Whitney U1", printed(cap, "U1"), U1, tol = 0)
check("v08", "Mann-Whitney U2", printed(cap, "U2"), U2, tol = 0)
check("v08", "printed U1 + printed U2 = n1 n2",
      printed(cap, "U1") + printed(cap, "U2"),
      length(a) * length(b), tol = 0)
check_floored("v08", "Mann-Whitney p", cap, "p",
              suppressWarnings(wilcox.test(a, b, exact = TRUE)$p.value),
              occurrence = 2)

# The plugin claims Method = "exact". n1 = n2 = 20 with no ties, so the
# exact test is available and is what R uses too. Read the claim, do not
# assume it.
check_true("v08", "capture claims the exact method",
           printed_str(cap, "Method") == "exact")
check_true("v08", "no ties, so the exact method is the correct claim",
           !any(duplicated(c(a, b))))

# --- nonparametric effect size ---------------------------------------------
# The plugin computes (U1 - U2) / (n1 n2), the directed form. See the note on
# rank_biserial_indep in helpers.R: the opposite sign convention exists and a
# reviewer who prefers it will see this value flip.
rb <- printed(cap, "Rank-biserial r")
check("v08", "rank-biserial r", rb, rank_biserial_indep(a, b), tol = 5e-4)

# The invariant that actually matters, independent of which convention you
# hold: the rank effect size and the mean difference must point the same way.
# A wrapper that handed the groups to the rank test in the opposite order
# from the t-test would satisfy every magnitude check above and fail this.
check_true("v08", "rank-biserial sign agrees with the mean difference",
           sign(rb) == sign(mean(a) - mean(b)))
check_true("v08", "rank-biserial sign agrees with Cohen's d",
           sign(rb) == sign(cohens_d(a, b)))

# --- the two effect sizes must remain distinguishable ----------------------
# This is the D15 regression guard carried into the independent-samples case.
# Both are read from the capture, so this compares two things the plugin
# printed rather than two things R computed.
check("v08", "printed rank-biserial is NOT the printed Cohen's d",
      rb, printed(cap, "Cohen's d"), tol = 5e-4, expect = "differ")

if (!exists("EML_SUITE")) { eml_report("v08 two-group orchestrator"); eml_exit() }
