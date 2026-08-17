# ============================================================================
# v01 — Pairwise comparisons: Welch t, Bonferroni adjustment, Cohen's d
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Wrapper:  Objects > New > EML Stats & Graphs > Pairwise comparisons...
# Settings: Data SPL_dB, Group voice_type, Test "Pairwise t-test",
#           Adjustment Bonferroni, T test type Welch, Group order Table order
# Input:    evidence/csv/demo_3groups_input.csv — the exact table driven,
#           saved out of the live Praat instance BEFORE analysis. The demo
#           tables are randomly generated on each creation, so re-creating
#           one would not reproduce these numbers.
# Printed:  evidence/info/pairwise_3groups_welch_bonferroni.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d <- read_input("demo_3groups_input.csv")
cap <- capture("pairwise_3groups_welch_bonferroni.txt")
g <- split(d$SPL_dB, d$voice_type)
ord <- c("Soprano", "Mezzo", "Alto")

check_true("v01", "three groups present", all(ord %in% names(g)))
check_true("v01", "15 observations per group",
           all(vapply(g[ord], length, integer(1)) == 15L))

pairs <- list(c("Soprano", "Mezzo"), c("Soprano", "Alto"), c("Mezzo", "Alto"))
raw <- vapply(pairs, function(p)
    t.test(g[[p[1]]], g[[p[2]]], var.equal = FALSE)$p.value, numeric(1))
bonf <- p.adjust(raw, method = "bonferroni")
dvals <- vapply(pairs, function(p) cohens_d(g[[p[1]]], g[[p[2]]]), numeric(1))

# --- adjusted p-values, as printed in the Info window ----------------------
# Soprano-Mezzo and Soprano-Alto printed as "< .001"; only the threshold
# claim can be validated for those.
check_true("v01", "Soprano-Mezzo adjusted p is floored in the matrix",
           grepl("<", printed_cell(cap, "Adjusted p-values", "Soprano", "Mezzo", as_string = TRUE)))
check_true("v01", "and R agrees it is below .001", bonf[1] < 0.001)
check_true("v01", "Soprano-Alto adjusted p is floored in the matrix",
           grepl("<", printed_cell(cap, "Adjusted p-values", "Soprano", "Alto", as_string = TRUE)))
check_true("v01", "and R agrees it is below .001", bonf[2] < 0.001)
check("v01", "Mezzo-Alto adjusted p", printed_cell(cap, "Adjusted p-values", "Mezzo", "Alto"), bonf[3], tol = 5e-5)

# --- Cohen's d -------------------------------------------------------------
check("v01", "Cohen's d Soprano-Mezzo", printed_cell(cap, "Cohen's d", "Soprano", "Mezzo"), dvals[1], tol = 5e-4)
check("v01", "Cohen's d Soprano-Alto", printed_cell(cap, "Cohen's d", "Soprano", "Alto"), dvals[2], tol = 5e-4)
check("v01", "Cohen's d Mezzo-Alto", printed_cell(cap, "Cohen's d", "Mezzo", "Alto"), dvals[3], tol = 5e-4)
# Both matrices are printed with a full mirror, so their symmetry is
# assertable from the capture alone: p is symmetric, d is antisymmetric.
check("v01", "adjusted-p matrix is symmetric as printed",
      printed_cell(cap, "Adjusted p-values", "Mezzo", "Alto"),
      printed_cell(cap, "Adjusted p-values", "Alto", "Mezzo"), tol = 1e-12)
check("v01", "Cohen's d matrix is antisymmetric as printed",
      printed_cell(cap, "Cohen's d", "Soprano", "Mezzo"),
      -printed_cell(cap, "Cohen's d", "Mezzo", "Soprano"), tol = 1e-12)
check("v01", "groups reported", printed(cap, "Groups"), 3, tol = 0)
check("v01", "pairs tested", printed(cap, "Pairs tested"), choose(3, 2), tol = 0)

# --- the adjustment is Bonferroni and not something else -------------------
# A relabelled no-op would leave the raw value in place. Assert the printed
# value is the raw p multiplied by the number of pairs.
check("v01", "Mezzo-Alto adjusted p equals raw x 3",
      printed_cell(cap, "Adjusted p-values", "Mezzo", "Alto"),
      min(raw[3] * 3, 1), tol = 5e-5)

if (!exists("EML_SUITE")) { eml_report("v01 pairwise Welch + Bonferroni"); eml_exit() }
