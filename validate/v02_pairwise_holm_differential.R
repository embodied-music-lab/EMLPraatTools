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
g <- split(d$SPL_dB, d$voice_type)
pairs <- list(c("Soprano", "Mezzo"), c("Soprano", "Alto"), c("Mezzo", "Alto"))

raw <- vapply(pairs, function(p)
    t.test(g[[p[1]]], g[[p[2]]], var.equal = FALSE)$p.value, numeric(1))
bonf <- p.adjust(raw, method = "bonferroni")
holm <- p.adjust(raw, method = "holm")
dvals <- vapply(pairs, function(p) cohens_d(g[[p[1]]], g[[p[2]]]), numeric(1))

# --- run 1, Adjustment = Bonferroni ---------------------------------------
check      ("v02", "Bonferroni Soprano-Mezzo", 0.0527, bonf[1], tol = 5e-5)
check_below("v02", "Bonferroni Soprano-Alto is < .001", 0.001, bonf[2])
check      ("v02", "Bonferroni Mezzo-Alto",    0.0342, bonf[3], tol = 5e-5)

# --- run 2, Adjustment = Holm ---------------------------------------------
check      ("v02", "Holm Soprano-Mezzo", 0.0228, holm[1], tol = 5e-5)
check_below("v02", "Holm Soprano-Alto is < .001", 0.001, holm[2])
check      ("v02", "Holm Mezzo-Alto",    0.0228, holm[3], tol = 5e-5)

# --- Cohen's d is unaffected by the adjustment ----------------------------
check("v02", "Cohen's d Soprano-Mezzo", 0.924, dvals[1], tol = 5e-4)
check("v02", "Cohen's d Soprano-Alto",  2.100, dvals[2], tol = 5e-4)
check("v02", "Cohen's d Mezzo-Alto",    0.990, dvals[3], tol = 5e-4)

# --- the differential itself ----------------------------------------------
check_true("v02",
    "Bonferroni and Holm disagree at alpha = .05 on Soprano-Mezzo",
    bonf[1] > 0.05 && holm[1] < 0.05)

check_true("v02",
    "Holm monotonicity: Mezzo-Alto is raised to the Soprano-Mezzo value",
    abs(holm[3] - holm[1]) < 1e-12)

if (!exists("EML_SUITE")) { eml_report("v02 Holm vs Bonferroni differential"); eml_exit() }
