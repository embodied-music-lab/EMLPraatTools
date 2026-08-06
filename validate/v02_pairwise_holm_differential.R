# ============================================================================
# v02 — Pairwise comparisons: the Holm vs Bonferroni differential
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Wrapper:  Objects > New > EML Tools > Pairwise comparisons...
# Settings: identical in both runs except Adjustment (Bonferroni, then Holm).
# Input:    evidence/csv/demo_3groups_b_input.csv
#
# Why this table and not v01's: on this instance the two adjustments fall on
# opposite sides of .05 for the Soprano-Mezzo contrast (0.0527 vs 0.0228).
# A control that merely relabelled the adjustment could not produce that, so
# this is the test that distinguishes an applied adjustment from a labelled
# one. It also covers Holm's monotonicity constraint, which is the part a
# naive step-down implementation gets wrong.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d <- read_input("demo_3groups_b_input.csv")
# Two captures: the SAME table and columns run twice, one adjustment apart.
# That is the whole design of this script — a control that relabelled the
# adjustment without applying it could not produce two different matrices.
capB <- capture("v02_pairwise_bonferroni_info.txt")
capH <- capture("v02_pairwise_holm_info.txt")

# The differential design rests on a premise this script had been ASSUMING:
# that the two captures differ in the adjustment and in nothing else. If they
# were run on different tables or different columns, two different matrices
# would prove nothing at all. Asserted rather than assumed, 6 Aug 2026, at the
# suggestion of an external audit of this suite.
#
# Asserted from the captures rather than by diffing input files, because the
# captures are what the comparison actually reads: they name the table, the
# data column, the group column and the group count in their own headers.
for (.k in c("Table", "Data column", "Group column", "Groups", "Pairs tested")) {
    check_true("v02", paste0("both runs report the same '", .k, "'"),
               identical(printed_str(capB, .k, 1, 1),
                         printed_str(capH, .k, 1, 1)))
}
check_true("v02", "the two runs really do differ in the adjustment named",
           !identical(grep("adjustment", capB$lines, value = TRUE),
                      grep("adjustment", capH$lines, value = TRUE)))
g <- split(d$SPL_dB, d$voice_type)
pairs <- list(c("Soprano", "Mezzo"), c("Soprano", "Alto"), c("Mezzo", "Alto"))

raw <- vapply(pairs, function(p)
    t.test(g[[p[1]]], g[[p[2]]], var.equal = FALSE)$p.value, numeric(1))
bonf <- p.adjust(raw, method = "bonferroni")
holm <- p.adjust(raw, method = "holm")
dvals <- vapply(pairs, function(p) cohens_d(g[[p[1]]], g[[p[2]]]), numeric(1))

# --- run 1, Adjustment = Bonferroni ---------------------------------------
check("v02", "Bonferroni Soprano-Mezzo", printed_cell(capB, "Adjusted p-values", "Soprano", "Mezzo"), bonf[1], tol = 5e-5)
check_true("v02", "Bonferroni Soprano-Alto is floored in the matrix",
           grepl("<", printed_cell(capB, "Adjusted p-values", "Soprano", "Alto", as_string = TRUE)))
check_true("v02", "and R agrees it is below .001", bonf[2] < 0.001)
check("v02", "Bonferroni Mezzo-Alto", printed_cell(capB, "Adjusted p-values", "Mezzo", "Alto"), bonf[3], tol = 5e-5)

# --- run 2, Adjustment = Holm ---------------------------------------------
check("v02", "Holm Soprano-Mezzo", printed_cell(capH, "Adjusted p-values", "Soprano", "Mezzo"), holm[1], tol = 5e-5)
check_true("v02", "Holm Soprano-Alto is floored in the matrix",
           grepl("<", printed_cell(capH, "Adjusted p-values", "Soprano", "Alto", as_string = TRUE)))
check_true("v02", "and R agrees it is below .001", holm[2] < 0.001)
check("v02", "Holm Mezzo-Alto", printed_cell(capH, "Adjusted p-values", "Mezzo", "Alto"), holm[3], tol = 5e-5)

# THE DIFFERENTIAL, now asserted between two captures rather than between
# two transcriptions. Soprano-Mezzo is 0.0527 under Bonferroni and 0.0228
# under Holm — opposite sides of .05. An adjustment that was relabelled but
# not applied would print the same number twice, and this is the check that
# would catch it.
check("v02", "the two captures disagree on Soprano-Mezzo",
      printed_cell(capB, "Adjusted p-values", "Soprano", "Mezzo"),
      printed_cell(capH, "Adjusted p-values", "Soprano", "Mezzo"),
      tol = 5e-4, expect = "differ")
check_true("v02", "and they fall on opposite sides of .05",
      printed_cell(capB, "Adjusted p-values", "Soprano", "Mezzo") > 0.05 &&
      printed_cell(capH, "Adjusted p-values", "Soprano", "Mezzo") < 0.05)
# The headers must name the adjustment that was actually applied.
check_true("v02", "the Bonferroni capture says bonferroni",
           any(grepl("bonferroni", capB$lines, fixed = TRUE)))
check_true("v02", "the Holm capture says holm",
           any(grepl("holm", capH$lines, fixed = TRUE)))
# Cohen's d is unaffected by the adjustment, so the two captures must AGREE
# on it. That separates "the adjustment changed" from "the run changed".
check("v02", "both captures report the same Cohen's d",
      printed_cell(capB, "Cohen's d", "Soprano", "Mezzo"),
      printed_cell(capH, "Cohen's d", "Soprano", "Mezzo"), tol = 1e-12)

# --- Cohen's d is unaffected by the adjustment ----------------------------
check("v02", "Cohen's d Soprano-Mezzo", printed_cell(capB, "Cohen's d", "Soprano", "Mezzo"), dvals[1], tol = 5e-4)
check("v02", "Cohen's d Soprano-Alto", printed_cell(capB, "Cohen's d", "Soprano", "Alto"), dvals[2], tol = 5e-4)
check("v02", "Cohen's d Mezzo-Alto", printed_cell(capB, "Cohen's d", "Mezzo", "Alto"), dvals[3], tol = 5e-4)

# --- the differential itself ----------------------------------------------
check_true("v02",
    "Bonferroni and Holm disagree at alpha = .05 on Soprano-Mezzo",
    bonf[1] > 0.05 && holm[1] < 0.05)

check_true("v02",
    "Holm monotonicity: Mezzo-Alto is raised to the Soprano-Mezzo value",
    abs(holm[3] - holm[1]) < 1e-12)

if (!exists("EML_SUITE")) { eml_report("v02 Holm vs Bonferroni differential"); eml_exit() }
