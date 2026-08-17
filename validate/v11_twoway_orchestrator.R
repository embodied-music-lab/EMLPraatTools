# ============================================================================
# v11 — Compare two-way (ANOVA): orchestrator
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Covers @emlRunTwoWayAnalysis: two main effects, the interaction, the error
# and total rows, and partial eta-squared for all three terms.
#
# The design is balanced (12 per cell), so Type I, II and III sums of squares
# coincide and there is no ambiguity to argue about. That is worth stating
# explicitly, because on an UNBALANCED design the three types differ and a
# suite that did not say which it used would be meaningless. This script
# asserts the balance before it asserts anything else.
#
# EVERY REPORTED VALUE IS READ FROM THE COMMITTED CAPTURE; see v08.
#
# DRIVEN 5 August 2026:
#   New > EML Stats & Graphs > Compare two-way (ANOVA)...
#   Data column SPL_dB, Factor 1 voice_type, Factor 2 task.
#
# Input:  evidence/csv/v11_twoway_input.csv
# Output: evidence/info/v11_twoway_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d   <- read_input("v11_twoway_input.csv")
cap <- capture("v11_twoway_info.txt")
d$voice_type <- factor(d$voice_type)
d$task       <- factor(d$task)

# --- the design ------------------------------------------------------------
cells <- table(d$voice_type, d$task)
check_true("v11", "design is 2 x 2", all(dim(cells) == c(2, 2)))
check_true("v11", "design is balanced, 12 per cell", all(cells == 12))
# Not a printed value — the two-way report gives no N. This asserts the
# committed INPUT is the 48-row table, so the literal is deliberate.
check("v11", "committed input has 48 rows", 48, nrow(d), tol = 0)

fit <- aov(SPL_dB ~ voice_type * task, data = d)
s   <- summary(fit)[[1]]
ss  <- s[["Sum Sq"]]; df <- s[["Df"]]
names(ss) <- names(df) <- trimws(rownames(s))
ss_err <- ss[["Residuals"]]; df_err <- df[["Residuals"]]

# --- ANOVA table -----------------------------------------------------------
# V4, 6 Aug 2026. "voice type" and "task" each match 2 lines: the ANOVA table
# row and the marginal-means row below it. Occurrence 1 is the ANOVA row.
check("v11", "SS voice_type", printed(cap, "voice type", 1, 1, expect_hits = 2), ss[["voice_type"]], tol = 5e-3)
check("v11", "SS task", printed(cap, "task", 1, 1, expect_hits = 2), ss[["task"]], tol = 5e-3)
check("v11", "SS interaction", printed(cap, "voice type x task", 1), ss[["voice_type:task"]], tol = 5e-3)
check("v11", "SS error", printed(cap, "Error", 1), ss_err, tol = 5e-3)
check("v11", "SS total", printed(cap, "Total", 1), sum(ss), tol = 2e-2)

check("v11", "df voice_type", printed(cap, "voice type", 2, 1, expect_hits = 2), df[["voice_type"]], tol = 0)
check("v11", "df task", printed(cap, "task", 2, 1, expect_hits = 2), df[["task"]], tol = 0)
check("v11", "df interaction", printed(cap, "voice type x task", 2), df[["voice_type:task"]], tol = 0)
check("v11", "df error", printed(cap, "Error", 2), df_err, tol = 0)

check("v11", "MS voice_type", printed(cap, "voice type", 3, 1, expect_hits = 2), ss[["voice_type"]] / df[["voice_type"]], tol = 5e-3)
check("v11", "MS task", printed(cap, "task", 3, 1, expect_hits = 2), ss[["task"]] / df[["task"]], tol = 5e-3)
check("v11", "MS interaction", printed(cap, "voice type x task", 3), ss[["voice_type:task"]] / df[["voice_type:task"]], tol = 5e-3)
check("v11", "MS error", printed(cap, "Error", 3), ss_err / df_err, tol = 5e-3)

fv <- s[["F value"]]; pv <- s[["Pr(>F)"]]
check("v11", "F voice_type", printed(cap, "voice type", 4, 1, expect_hits = 2), fv[1], tol = 5e-5)
check("v11", "F task", printed(cap, "task", 4, 1, expect_hits = 2), fv[2], tol = 5e-5)
check("v11", "F interaction", printed(cap, "voice type x task", 4), fv[3], tol = 5e-5)
check_floored("v11", "p voice_type", cap, "voice type", pv[1], field = 5)
check_floored("v11", "p task", cap, "task", pv[2], field = 5)
# Printed as "p = .116" in one field, so read as text and parsed.
p_int <- printed_str(cap, "voice type x task", 5)
check("v11", "p interaction", as.numeric(sub("^p\\s*=\\s*", "0", p_int)), pv[3], tol = 5e-4)

# The df must partition: 1 + 1 + 1 + 44 = 47 = N - 1. A wrapper that read
# the error df off the wrong row would still print plausible F values.
check("v11", "printed df partition sums to N - 1", nrow(d) - 1,
      printed(cap, "voice type", 2, 1, expect_hits = 2) + printed(cap, "task", 2, 1, expect_hits = 2) +
      printed(cap, "voice type x task", 2) + printed(cap, "Error", 2), tol = 0)

# The printed total SS must equal the printed parts.
check("v11", "printed SS total equals the printed parts",
      printed(cap, "Total", 1),
      printed(cap, "voice type", 1, 1, expect_hits = 2) + printed(cap, "task", 1, 1, expect_hits = 2) +
      printed(cap, "voice type x task", 1) + printed(cap, "Error", 1), tol = 5e-3)

# --- partial eta-squared ---------------------------------------------------
# eta_p^2 = SS_effect / (SS_effect + SS_error). Note this is NOT SS/SS_total;
# the two coincide only when there is a single effect. Getting this wrong is
# the classic two-way reporting error, and the values differ here by enough
# to catch it: SS_voice/SS_total would be 0.2487, not 0.6399.
check("v11", "partial eta2 voice_type", printed(cap, "voice type", 1, 2, expect_hits = 2),
      partial_eta2(ss[["voice_type"]], ss_err), tol = 5e-5)
check("v11", "partial eta2 task", printed(cap, "task", 1, 2, expect_hits = 2),
      partial_eta2(ss[["task"]], ss_err), tol = 5e-5)
check("v11", "partial eta2 interaction", printed(cap, "voice type x task", 1, 2),
      partial_eta2(ss[["voice_type:task"]], ss_err), tol = 5e-5)

check("v11", "partial eta2 is NOT SS/SS_total",
      partial_eta2(ss[["voice_type"]], ss_err),
      ss[["voice_type"]] / sum(ss), tol = 5e-4, expect = "differ")

# Partial eta-squareds need not sum to anything, but each must lie in [0,1].
check_true("v11", "all partial eta2 in [0,1]",
           all(sapply(c("voice_type", "task", "voice_type:task"),
                      function(k) {
                          e <- partial_eta2(ss[[k]], ss_err)
                          e >= 0 && e <= 1
                      })))

# --- independent cross-check on the balanced decomposition -----------------
gm <- mean(d$SPL_dB)
a_m <- tapply(d$SPL_dB, d$voice_type, mean)
b_m <- tapply(d$SPL_dB, d$task, mean)
ss_a <- sum(table(d$voice_type) * (a_m - gm)^2)
ss_b <- sum(table(d$task) * (b_m - gm)^2)
check("v11", "SS voice_type, hand-rolled", ss[["voice_type"]], ss_a, tol = 1e-8)
check("v11", "SS task, hand-rolled",       ss[["task"]],       ss_b, tol = 1e-8)

if (!exists("EML_SUITE")) { eml_report("v11 two-way ANOVA orchestrator"); eml_exit() }
