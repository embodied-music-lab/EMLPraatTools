# ============================================================================
# v03 — Stats Wizard, repeated measures: RM-ANOVA with Greenhouse-Geisser
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Route:    Stats Wizard > Compare groups or conditions > Yes, repeated >
#           Three or more (RM-ANOVA / Friedman) > conditions SPL_soft,
#           SPL_medium, SPL_loud > Test approach Parametric > Adjustment holm
# Input:    evidence/csv/demo_rm3_input.csv
# Printed:  evidence/info/wizard_rm3_rmanova_and_friedman.txt
# Retake:   bash evidence/redrive/run.sh wizard_rm3
#
# The RM-ANOVA is cross-checked two ways: against the closed-form sums of
# squares in helpers.R, and against base R's aov() with an Error() stratum,
# which is an independent implementation.
#
# ────────────────────────────────────────────────────────────────────────────
# V8, 16 AUGUST 2026 — THE CAPTURE WAS STALE IN SHAPE AND THE TOLERANCES WERE
# WRITTEN FOR A LINE THE PLUGIN NO LONGER PRINTS.
#
# WHY THIS FILE EXISTS IN THIS FORM, and it is not a hypothetical. Until today
# the capture read by these checks was taken by hand on 6 August, before
# @emlFormatP grew an exact tail and before RULING 6 routed the wizard's own
# numbers through @eml_fixed. It said
#
#     F(2, 38) = 583.1232, p = 0.00000000000000000000000000003
#
# and the plugin says
#
#     F(2, 38) = 583.1232, p < .001  (3.04e-29)
#
# — the APA label the rest of the plugin uses, with the floored magnitude in a
# tail beside it. The VALUE is the same value. What moved is the rendering and
# the POSITION on the line, and that is what made the staleness dangerous
# rather than merely untidy: every check here kept passing, against a token
# the shipping plugin had stopped emitting in that position two formats ago.
# A green v03 meant "the 6 August build was right", which is not what anyone
# reading it thought it meant.
#
# THE TOLERANCES ARE THE DELICATE PART, and re-deriving them is the whole
# reason this was not a re-run. The old bounds — 5e-30 on the uncorrected p,
# 5e-26 on the GG-corrected one — were half a display ULP of the OLD line's
# decimal count, and half a display ULP is only half a display ULP of the
# string it was computed from. Carried across unchanged onto a different
# rendering they would have been arbitrary numbers wearing a derivation's
# clothes. So nothing is carried. `p_ulp_bound` reads the tail the capture
# actually holds and computes the bound from its mantissa width and its
# exponent, and if the rendering moves again the bound moves with it.
#
# WHAT THAT COMES OUT AT, AND IT IS THE HAPPY DIRECTION. "3.04e-29" carries
# THREE significant figures; the twenty-nine-decimal string it replaced
# carried ONE. Half a ULP therefore falls from 5e-30 — sixteen percent of the
# value being asserted — to 5e-32, which is a sixth of a percent. The check is
# a hundred times tighter than the one it replaces, not a loosened one
# presented as an equal. |3.04e-29 - 3.03596e-29| = 4.04e-32 clears the 5e-32
# bound, at eighty percent of it, which is what a half-ULP bound is supposed
# to look like on a correctly rounded value.
#
# THE FLOORED-p HOLE, WHICH IS WHY ANY OF THIS MATTERS. Before 6 August the
# tolerance here was 1e-28 against a p of 3.036e-29, so |0 - p| < tol: a
# plugin that floored this p to zero PASSED — the exact failure D24 exists to
# catch on the CSV side, admitted on the printed side. That hole is closed
# twice over and both closures are kept. The positivity assertions say in as
# many words that the printed p is not zero, and they are the ones that close
# it directly. The bound closes it a second way, because |0 - 3.036e-29| is
# 3.036e-29 against 5e-32 and misses by three orders of magnitude.
#
# AND THE SHAPE OF THE TAIL IS ASSERTED, not just its value, because the bound
# is DERIVED from the tail. A tolerance read out of the artefact is a
# tolerance the artefact can widen: re-render "3.04e-29" as "3e-29" and the
# derived bound relaxes from 5e-32 to 5e-30 with every check still green and
# nobody told. So the mantissa is required to carry three significant figures
# — one digit, a point, two digits — which is the author ruling of 16 August
# on @eml_sig3, pinned here as the precondition of the bound rather than as a
# cosmetic preference.
#
# WHAT COULD NOT HAVE CAUGHT ANY OF IT.
#
#   - THE VALUE CHECKS THEMSELVES, IN THEIR OLD FORM. They read a token from
#     a committed file and compared it to R. The file was right about a build
#     that no longer existed, so they agreed, correctly, about the wrong
#     thing. A check against a frozen oracle cannot notice the oracle froze.
#
#   - A GOLDEN-FILE DIFF. It would have shown the capture changing on the day
#     someone retook it, and said nothing at all in the eight days nobody did.
#     The failure here is an artefact that DOESN'T change while the thing it
#     describes does, which is the one direction a golden file is blind in.
#
#   - A WIDTH OR FORMAT ASSERTION ON ITS OWN. "The line matches p [<>=] ..."
#     is satisfied by "p < .001  (0.00e+00)", and a plugin that clamped every
#     tail to a zero of the right width would sail through every shape check
#     in this file. That is why `p_ulp_bound` refuses to return a bound for a
#     tail with no significant digit in it, and why the positivity assertions
#     are stated separately from the value assertions rather than folded into
#     them.
#
#   - THE CSV VALIDATORS. v16 and v57 read the exported files, where full
#     precision is required and present. The report and the export are
#     opposite assertions over two artefacts and only the first one is here.
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
# p_exact_tail / p_ulp_bound — read @emlFormatP's exact tail, and the bound
# implied by how wide it was printed.
#
# The wizard's p no longer sits after an "=". It sits after an APA label, in
# parentheses, at the end of the clause:
#
#     F(2, 38) = 583.1232, p < .001  (3.04e-29)
#     SPL_soft vs SPL_medium: raw p < .001  (1.54e-12), adj p < .001  (3.08e-12)
#
# so `printed_eq` cannot read it and correctly refuses to. The tail is matched
# through the p-label it belongs to, never as "the first parenthesis on the
# line" — "F(2, 38)" and "chi-square(2)" are parentheses holding numbers, and
# a reader that took the first one would silently return the degrees of
# freedom and compare THOSE to a p-value.
#
# A line whose p is at or above .001 carries no tail; @emlFormatP has already
# shown the number exactly and appends nothing. That returns NA rather than
# stopping, so a capture that loses its tails fails the checks red instead of
# aborting the suite before the rest of the file runs.
#
# DUPLICATED IN v04_friedman.R, deliberately and with this note on both
# copies. helpers.R is where a third caller would put it; two callers that
# each read the file they own is the smaller risk today, and neither file may
# assume the other has been sourced when it is run on its own.
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

# Half a display ULP of a three-significant-figure scientific string: the
# mantissa's last decimal, scaled by the exponent. "3.04e-29" -> 0.005e-29.
#
# A tail with NO significant digit — "0", the honest rendering of a p that
# underflowed — gets a bound of zero, not 0.5. Half a ULP of "0" is
# arithmetically 0.5 and using it would be the fix-shaped fix: clamp every
# tail to a zero of the right width and every value assertion in this file
# passes. A string that carries no digits carries no precision, so there is no
# tolerance at which asserting a value against it is honest, and the right
# answer is a bound nothing can satisfy.
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

# Three significant figures, as ruled on 16 August: one digit, a point, two
# digits, then the exponent. Asserted because p_ulp_bound is derived from this
# width — a narrower tail would silently widen every bound below.
p_tail_is_sig3 <- function(s) {
    !is.na(s) && grepl("^-?[0-9]\\.[0-9]{2}e[-+][0-9]{2,}$", s)
}

d <- read_input("demo_rm3_input.csv")
cap <- capture("wizard_rm3_rmanova_and_friedman.txt")
conds <- c("SPL_soft", "SPL_medium", "SPL_loud")
Y <- as.matrix(d[, conds])
fit <- rm_anova(Y)

check_true("v03", "20 complete-case subjects, 3 conditions",
           fit$n == 20L && fit$k == 3L && !any(is.na(Y)))

# --- condition means ------------------------------------------------------
check("v03", "SPL_soft mean",   printed_eq(cap, "SPL_soft mean"),   unname(fit$means["SPL_soft"]),   tol = 5e-5)
check("v03", "SPL_medium mean", printed_eq(cap, "SPL_medium mean"), unname(fit$means["SPL_medium"]), tol = 5e-5)
check("v03", "SPL_loud mean",   printed_eq(cap, "SPL_loud mean"),   unname(fit$means["SPL_loud"]),   tol = 5e-5)

# --- omnibus --------------------------------------------------------------
check("v03", "F statistic", printed_eq(cap, "F(2, 38)", 1), fit$F, tol = 5e-5)
# The df are in the printed LABEL, so assert the label itself exists rather
# than trusting a transcription of the numbers inside it.
check_true("v03", "the capture prints F with df (2, 38)",
           any(grepl("F(2, 38)", cap$lines, fixed = TRUE)))
check_true("v03", "df reported as (2, 38)", fit$df1 == 2L && fit$df2 == 38L)
check("v03", "Greenhouse-Geisser epsilon",
      printed_eq(cap, "Greenhouse-Geisser epsilon", 1), fit$gg, tol = 5e-5)

# --- the two floored p, read from @emlFormatP's exact tail ------------------
# Both are printed. Reading both lets the relationship between them be
# asserted: correcting with epsilon < 1 costs df, so the corrected p must be
# the LARGER of the two.
t_unc <- p_exact_tail(cap, "F(2, 38)", 1)
t_gg  <- p_exact_tail(cap, "Greenhouse-Geisser epsilon", 1)
p_unc <- suppressWarnings(as.numeric(t_unc))
p_gg  <- suppressWarnings(as.numeric(t_gg))

check_true("v03", "uncorrected p prints an exact tail beside the APA label",
           !is.na(t_unc))
check_true("v03", "GG-corrected p prints an exact tail beside the APA label",
           !is.na(t_gg))
check_true("v03", "uncorrected p tail carries three significant figures",
           p_tail_is_sig3(t_unc))
check_true("v03", "GG-corrected p tail carries three significant figures",
           p_tail_is_sig3(t_gg))
# The hole D24 names, closed directly and in as many words.
check_true("v03", "printed uncorrected p is not floored to zero",
           isTRUE(p_unc > 0))
check_true("v03", "printed GG-corrected p is not floored to zero",
           isTRUE(p_gg > 0))
check("v03", "printed uncorrected p", p_unc, fit$p,    tol = p_ulp_bound(t_unc))
check("v03", "printed GG-corrected p", p_gg, fit$p_gg, tol = p_ulp_bound(t_gg))
check_true("v03", "GG correction increases p, since epsilon < 1",
           fit$gg < 1 && isTRUE(p_gg > p_unc))

# D85, settled. The p on these two lines used to print as a bare double —
# twenty-nine and twenty-five decimal places in the Info window. It now prints
# the plugin's own APA rendering with the floored magnitude beside it.
#
# STATED AS A SHAPE, NOT AS A STRING. The obvious way to write this is
# grepl("p < .001  (3.04e-29)", fixed = TRUE), and that is the mistake this
# whole file is a correction of: it freezes a VALUE inside a format assertion,
# so a re-render of the same correct number reads as a regression and the
# value check eight lines above — which is where the value belongs, at half a
# display ULP — says the same thing better. What D85 settled is the SHAPE of
# the omnibus line: the APA floor, then two spaces, then a parenthesised tail.
# That is what is asserted, on the line the finding was raised about.
f_line <- cap$lines[grepl("F(2, 38)", cap$lines, fixed = TRUE)][1]
check_true("v03", "D85 settled: the omnibus p prints the APA floor plus an exact tail",
           isTRUE(grepl("p < \\.001\\s+\\([^)]+\\)$", f_line)))
check_true("v03", "D85 settled: no bare long-decimal p survives in the capture",
           !any(grepl("p = 0.00000000", cap$lines, fixed = TRUE)))

# --- independent cross-check against base R aov() -------------------------
long <- data.frame(
    subject   = factor(rep(d$singer, times = length(conds))),
    condition = factor(rep(conds, each = nrow(d)), levels = conds),
    value     = as.vector(Y)
)
a <- summary(aov(value ~ condition + Error(subject / condition), data = long))
f_aov <- a[["Error: subject:condition"]][[1]][["F value"]][1]
check("v03", "F agrees with base R aov()", fit$F, f_aov, tol = 1e-6)

# --- post-hoc pairwise, holm-adjusted -------------------------------------
pr <- c(
    t.test(Y[, "SPL_soft"],   Y[, "SPL_medium"], paired = TRUE)$p.value,
    t.test(Y[, "SPL_soft"],   Y[, "SPL_loud"],   paired = TRUE)$p.value,
    t.test(Y[, "SPL_medium"], Y[, "SPL_loud"],   paired = TRUE)$p.value
)
pa <- p.adjust(pr, method = "holm")

# The pair rows carry the same APA-plus-tail shape, twice each — raw then
# adjusted. Both are read and both are asserted at half a display ULP of the
# tail that was actually printed. V6's 50%-relative window is gone for the
# reason V6 gave for retiring it: a window that wide admits a mis-rounding
# 43% wide, and a fixed-width print has a principled bound available.
posthoc <- function(label, which, r, occurrence = 1L) {
    txt <- p_exact_tail(cap, label, which, occurrence)
    b <- p_ulp_bound(txt)
    v <- suppressWarnings(as.numeric(txt))
    isTRUE(v > 0) && isTRUE(abs(v - r) <= b)
}
pairs <- c("SPL_soft vs SPL_medium", "SPL_soft vs SPL_loud", "SPL_medium vs SPL_loud")
for (i in seq_along(pairs)) {
    check_true("v03", paste("post-hoc raw p", pairs[i]), posthoc(pairs[i], 1, pr[i]))
    check_true("v03", paste("post-hoc adj p", pairs[i]), posthoc(pairs[i], 2, pa[i]))
}
check_true("v03", "holm adjusted p are >= raw p",        all(pa >= pr))
check_true("v03", "holm ordering preserved",             !is.unsorted(pa[order(pr)]))

# --- D86, settled on this path --------------------------------------------
# The report gave F, p and epsilon and no effect size at all, so nothing in it
# said how big the condition effect was — only how unlikely it was under the
# null. Partial eta squared is now printed, and is asserted against R rather
# than merely recorded as computable.
check_true("v03", "partial eta squared computable", abs(fit$partial_eta2 - 0.9684) < 5e-5)
check("v03", "D86 settled: printed partial eta squared",
      printed_eq(cap, "Partial eta squared", 1), fit$partial_eta2, tol = 5e-5)

if (!exists("EML_SUITE")) { eml_report("v03 RM-ANOVA + Greenhouse-Geisser"); eml_exit() }
