# ============================================================================
# v04 — Stats Wizard, repeated measures: Friedman test
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Route:    as v03 but Test approach = Nonparametric (Friedman)
# Input:    evidence/csv/demo_rm3_input.csv
# Printed:  evidence/info/wizard_rm3_rmanova_and_friedman.txt
# Retake:   bash evidence/redrive/run.sh wizard_rm3
#
# This instance is the tied case: all three post-hoc raw p-values are
# identical, so Holm's monotonicity constraint must give all three the same
# adjusted value rather than three different step values. That is the part
# worth checking independently.
#
# ────────────────────────────────────────────────────────────────────────────
# V3, 16 AUGUST 2026 — THE CAPTURE MOVED UNDER THIS FILE TOO, AND IT MOVED IN
# THE ONE WAY A VALUE CHECK CANNOT FEEL.
#
# The capture these checks read was hand-taken on 6 August, before @emlFormatP
# grew an exact tail. Its omnibus line said
#
#     chi-square(2) = 40.0000, p = 0.000000002
#
# and the shipping plugin says
#
#     chi-square(2) = 40.0000, p < .001  (2.06e-09)
#
# Same number, different rendering, different POSITION. Every check in this
# file kept passing throughout, because a check that reads a committed file
# and agrees with R is making a statement about the file, and the file was
# right about a build that had been replaced. The header of v03 sets out the
# argument at length; it is the same argument here and is not repeated.
#
# WHAT IS DIFFERENT ABOUT THE FRIEDMAN LINE, and it is why the tail reader
# below matches through the p-label rather than through the parentheses. The
# omnibus line carries TWO parenthesised numbers: the degrees of freedom in
# "chi-square(2)" and the exact tail at the end. A reader that took the first
# parenthesis on the line would return 2 and compare the degrees of freedom to
# a p-value — and 2 is not close to 2.06e-09 at any tolerance, so it would
# have failed loudly here. It would NOT have failed loudly everywhere: on a
# line where the leading parenthesis happened to hold something p-shaped, the
# wrong token would have been asserted quietly and for ever. Anchoring on the
# label is not a convenience, it is the difference.
#
# THE TOLERANCE IS RE-DERIVED, NOT CARRIED. The old bound on the omnibus p was
# 5e-10, half a display ULP of a nine-decimal fixed string. The tail is
# rendered at three significant figures, so half a ULP of "2.06e-09" is 5e-12
# — the assertion is two hundred and fifty times tighter than the one it
# replaces. It is computed from the string in the capture, by the same
# `p_ulp_bound` v03 uses, so a further change in the rendering moves the bound
# with it instead of leaving a number nobody can re-derive.
#
# THE TIED POST-HOC ROW IS WHY THE TAIL IS READ AND NOT JUST THE LABEL. All
# three pairs floor to "p < .001" and the label alone therefore says nothing
# about whether Holm did its job: three different adjusted values and three
# identical ones print the same six characters. The tail is what makes the
# tie assertable at all, and the tie is the whole point of this validator.
#
# WHAT COULD NOT HAVE CAUGHT IT. The APA label, asserted on its own — it is
# identical for every p below .001, which is D35 stated as a test. A
# golden-file diff — the artefact did not change, that was the defect. The
# CSV checks — full precision is required there and present there, and the
# question here is what a reader sees in the Info window.
# ────────────────────────────────────────────────────────────────────────────
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

# ---------------------------------------------------------------------------
# p_exact_tail / p_ulp_bound / p_tail_is_sig3 — see the long note on the same
# three functions in v03_rm_anova_greenhouse_geisser.R. DUPLICATED there and
# here, deliberately: helpers.R is where a third caller would put them, and
# neither validator may assume the other has been sourced when it is run on
# its own.
# ---------------------------------------------------------------------------
p_exact_tail <- function(cap, key, which = 1L, occurrence = 1L) {
    stopifnot(inherits(cap, "eml_capture"))
    hits <- grep(key, cap$lines, fixed = TRUE)
    if (!length(hits)) stop(sprintf("key '%s' not found in capture %s", key, cap$name))
    if (occurrence > length(hits)) {
        stop(sprintf("key '%s' occurs %d time(s) in %s; occurrence %d requested",
                     key, length(hits), cap$name, occurrence))
    }
    ln <- cap$lines[hits[occurrence]]
    m <- regmatches(ln, gregexpr("p\\s*[<>=]\\s*[.0-9]+\\s*\\(([^)]*)\\)",
                                 ln, perl = TRUE))[[1]]
    if (which > length(m)) return(NA_character_)
    sub(".*\\(([^)]*)\\).*", "\\1", m[which])
}

# A tail with no significant digit — "0", an underflowed p — gets a bound of
# zero rather than half a ULP of nothing, so that clamping the tail to a zero
# of the right width fails the value checks instead of satisfying them.
p_ulp_bound <- function(s) {
    if (is.na(s)) return(NA_real_)
    m <- regmatches(s, regexec("^(-?)([0-9]+)(?:\\.([0-9]+))?(?:e([-+]?[0-9]+))?$", s))[[1]]
    if (!length(m)) return(NA_real_)
    int_part <- m[3]; dec_part <- m[4]; expo <- m[5]
    digits <- paste0(int_part, dec_part)
    if (!grepl("[1-9]", digits)) return(0)
    ndec <- nchar(dec_part)
    e <- if (nzchar(expo)) as.integer(expo) else 0L
    0.5 * 10^(-ndec) * 10^e
}

p_tail_is_sig3 <- function(s) {
    !is.na(s) && grepl("^-?[0-9]\\.[0-9]{2}e[-+][0-9]{2,}$", s)
}

d <- read_input("demo_rm3_input.csv")
cap <- capture("wizard_rm3_rmanova_and_friedman.txt")
conds <- c("SPL_soft", "SPL_medium", "SPL_loud")
Y <- as.matrix(d[, conds])

ft <- friedman.test(Y)

check("v04", "Friedman chi-square", printed_eq(cap, "chi-square(2)", 1),
      unname(ft$statistic), tol = 5e-5)
check_true("v04", "the capture prints chi-square with df 2",
           any(grepl("chi-square(2)", cap$lines, fixed = TRUE)))
check_true("v04", "df reported as 2", unname(ft$parameter) == 2L)

# --- the omnibus p, read from @emlFormatP's exact tail ---------------------
t_om <- p_exact_tail(cap, "chi-square(2)", 1)
p_om <- suppressWarnings(as.numeric(t_om))
check_true("v04", "omnibus p prints an exact tail beside the APA label", !is.na(t_om))
check_true("v04", "omnibus p tail carries three significant figures", p_tail_is_sig3(t_om))
check_true("v04", "printed omnibus p is not floored to zero", isTRUE(p_om > 0))
check("v04", "Friedman p", p_om, unname(ft$p.value), tol = p_ulp_bound(t_om))
check_true("v04", "the exact tail is NOT the printed degrees of freedom",
           isTRUE(p_om < 1e-6))

# --- rank sums ------------------------------------------------------------
ranks <- t(apply(Y, 1, rank))
rs <- colSums(ranks)
check("v04", "SPL_soft rank sum",   printed_eq(cap, "SPL_soft rank sum"),   unname(rs["SPL_soft"]),   tol = 1e-9)
check("v04", "SPL_medium rank sum", printed_eq(cap, "SPL_medium rank sum"), unname(rs["SPL_medium"]), tol = 1e-9)
check("v04", "SPL_loud rank sum",   printed_eq(cap, "SPL_loud rank sum"),   unname(rs["SPL_loud"]),   tol = 1e-9)

# --- post-hoc Wilcoxon signed-rank, holm-adjusted -------------------------
pr <- suppressWarnings(c(
    wilcox.test(Y[, "SPL_soft"],   Y[, "SPL_medium"], paired = TRUE)$p.value,
    wilcox.test(Y[, "SPL_soft"],   Y[, "SPL_loud"],   paired = TRUE)$p.value,
    wilcox.test(Y[, "SPL_medium"], Y[, "SPL_loud"],   paired = TRUE)$p.value
))
pa <- p.adjust(pr, method = "holm")

# occurrence 2: the pair labels appear under RM-ANOVA first, then under
# Friedman in the same capture.
pairs <- c("SPL_soft vs SPL_medium", "SPL_soft vs SPL_loud", "SPL_medium vs SPL_loud")
raw_txt <- vapply(pairs, function(k) p_exact_tail(cap, k, 1, 2), character(1))
adj_txt <- vapply(pairs, function(k) p_exact_tail(cap, k, 2, 2), character(1))
raw_num <- suppressWarnings(as.numeric(raw_txt))
adj_num <- suppressWarnings(as.numeric(adj_txt))

for (i in seq_along(pairs)) {
    check_true("v04", paste("post-hoc raw p tail present and non-zero", pairs[i]),
               isTRUE(raw_num[i] > 0))
    check_true("v04", paste("post-hoc adj p tail present and non-zero", pairs[i]),
               isTRUE(adj_num[i] > 0))
    check("v04", paste("post-hoc raw p", pairs[i]),
          raw_num[i], pr[i], tol = p_ulp_bound(raw_txt[i]))
    check("v04", paste("post-hoc adj p", pairs[i]),
          adj_num[i], pa[i], tol = p_ulp_bound(adj_txt[i]))
}
check_true("v04", "all three raw p are equal", diff(range(pr)) < 1e-15)
# The three pairs are tied, so Holm must give all three the SAME adjusted
# value. This is read from the exact tails and not from the APA labels: the
# labels are "< .001" whatever Holm did, so they cannot distinguish a tie from
# three different step values.
check_true("v04", "printed holm adjusted p are identical across the tied pairs",
           all(!is.na(adj_num)) && diff(range(adj_num)) == 0)
check_true("v04", "holm ties: all three adjusted p equal",
           diff(range(pa)) < 1e-15)
check_true("v04", "holm tied value is raw x 3 (monotonicity, not step-down)",
           abs(pa[1] - min(pr[1] * 3, 1)) < 1e-15)
# The tie is only informative if adjusted and raw are DISTINGUISHABLE at the
# printed precision — three identical adjusted values that merely repeat the
# raw ones would satisfy the check above and mean nothing.
check_true("v04", "adjusted tails differ from raw tails at the printed precision",
           all(!is.na(raw_num)) && all(adj_num > raw_num))

# --- D86, settled on this path --------------------------------------------
# The report gave chi-square and p and no effect size, so nothing said how
# much the rankings agreed. Kendall's W is now printed, and is asserted
# against R rather than merely recorded as computable.
w <- kendalls_w(unname(ft$statistic), nrow(Y), ncol(Y))
check_true("v04", "Kendall's W computable", abs(w - 1.0) < 1e-9)
check("v04", "D86 settled: printed Kendall's W",
      printed_eq(cap, "Kendall's W", 1), w, tol = 5e-5)

if (!exists("EML_SUITE")) { eml_report("v04 Friedman"); eml_exit() }
