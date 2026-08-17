# ============================================================================
# v15 — Check normality (all columns): orchestrator and its recommendation
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Covers @emlRunNormalityAnalysis across all three numeric columns of one
# table, plus the part no other script in this suite touches: the DECISION.
# This wrapper does not only report W and p, it tells the user whether to
# use a parametric test. That recommendation is a function of three inputs —
# |G1|, |G2| and the Shapiro-Wilk p — and it is the only place in the plugin
# where a threshold constant changes what a user is told to do.
#
# The table is well chosen for that: two columns pass and one fails, so the
# per-column verdicts and the summary counts can both be checked against a
# non-degenerate answer.
#
# WHAT THIS SCRIPT PINS, deliberately:
#   * THE DECISION RULE. Shapiro-Wilk decides. Skewness and kurtosis are
#     descriptive and act as a backup, used to decide only where
#     Shapiro-Wilk cannot. Until 5 August the gate was `shape OR sw`, which
#     let a rule of thumb overrule a formal test.
#   * Shape thresholds are emlSkewThreshold and emlKurtosisThreshold, 2 and
#     7, from West, Finch & Curran (1995). Until 5 August three sites
#     disagreed — the gate used 1, this report's printed verdict used 3, and
#     the wizard's classifier used 1 and 3 — so a column could be called
#     "within typical limits" on one line and drive a nonparametric
#     recommendation on the next. That is finding D95.
#   * G1 and G2 are the sample-corrected forms. See helpers.R and v14.
#
# DRIVEN 5 August 2026, AFTER the D95 fix:
#   New > EML Stats & Graphs > Check normality (all columns)...
#   Group column (none), Clear Info window ON.
#
# Input:  evidence/csv/v15_normality_input.csv
# Output: evidence/info/v15_normality_info.txt
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

d   <- read_input("v15_normality_input.csv")
cap <- capture("v15_normality_info.txt")
# West, Finch & Curran (1995): |skew| > 2 and |kurtosis| > 7 indicate
# moderate-to-serious non-normality. Loose guidelines for DESCRIBING a
# distribution, not a test of it. See eml-output.praat.
SKEW_T <- 2     # emlSkewThreshold
KURT_T <- 7     # emlKurtosisThreshold

# The three columns appear in the capture in file order. `occ` is the
# occurrence of each repeated label — the report prints one block per
# column, so "Mean", "SD", "W" and the rest each appear three times.
# `parametric` is read from the capture's own Recommendation sentence, not
# asserted from memory.
cols <- list(
    F0_Hz       = list(occ = 1L),
    shimmer_pct = list(occ = 2L),
    jitter_pct  = list(occ = 3L)
)
rec_lines <- grep("Parametric tests|Consider nonparametric",
                  cap$lines, value = TRUE)
stopifnot(length(rec_lines) == 3L)
for (i in seq_along(cols)) {
    cols[[i]]$parametric <- grepl("Parametric tests", rec_lines[i], fixed = TRUE)
}

# "SUMMARY: 3 columns tested" separates label from value with ONE space, so
# @printed does not apply — it requires the two-or-more-space column
# separator Praat uses everywhere else. Parsed from the line instead.
sum_line <- grep("SUMMARY:", cap$lines, value = TRUE, fixed = TRUE)
stopifnot(length(sum_line) == 1L)
check("v15", "the wrapper tested all 3 numeric columns",
      as.numeric(sub(".*SUMMARY:\\s*(\\d+).*", "\\1", sum_line)),
      sum(sapply(d, is.numeric)), tol = 0)

for (nm in names(cols)) {
    e <- cols[[nm]]
    x <- d[[nm]]
    id <- paste0("v15:", nm)

    o <- e$occ
    check(id, "N",      printed(cap, "N", 1, o),      length(x), tol = 0)
    check(id, "mean",   printed(cap, "Mean", 1, o),   mean(x),   tol = 5e-5)
    check(id, "SD",     printed(cap, "SD", 1, o),     sd(x),     tol = 5e-5)
    check(id, "median", printed(cap, "Median", 1, o), median(x), tol = 5e-5)

    g1p <- printed(cap, "Skewness", 1, o)
    g2p <- printed(cap, "Kurtosis (excess)", 1, o)
    check(id, "skewness G1",         g1p, skewness_g1(x),     tol = 5e-5)
    check(id, "kurtosis G2, excess", g2p, excess_kurtosis(x), tol = 5e-5)

    sw <- shapiro.test(x)
    check(id, "Shapiro-Wilk W", printed(cap, "W", 1, o), unname(sw$statistic), tol = 5e-5)
    # p prints as "p = .412", one field, so read as text and parsed.
    p_str <- printed_str(cap, "p", 1, o)
    check(id, "Shapiro-Wilk p",
          as.numeric(sub("^p\\s*=\\s*", "0", p_str)), unname(sw$p.value), tol = 5e-4)

    # --- the printed shape verdicts ---------------------------------------
    # Asserted against the CONSTANTS, so that changing the house convention
    # in eml-output.praat and re-running the drive is a coherent operation.
    check_true(id, "printed skew verdict matches |G1| against the threshold",
               (abs(skewness_g1(x)) < SKEW_T) == (abs(g1p) < SKEW_T))
    check_true(id, "printed kurtosis verdict matches |G2| against the threshold",
               (abs(excess_kurtosis(x)) < KURT_T) == (abs(g2p) < KURT_T))

    # --- the recommendation ------------------------------------------------
    # Shapiro-Wilk decides. Shape only intervenes in the large-n override,
    # where SW rejects departures too small to matter (n > 50 with shape not
    # severe), and in the case where SW is unavailable. All three columns
    # here have n = 40, so no override applies and the rule reduces to SW.
    shape_severe <- abs(skewness_g1(x)) >= SKEW_T ||
                    abs(excess_kurtosis(x)) >= KURT_T
    sw_ok        <- unname(sw$p.value) >= 0.05
    expected     <- if (!sw_ok && !shape_severe && length(x) > 50) TRUE else sw_ok
    check_true(id, "recommendation follows Shapiro-Wilk, not the shape heuristic",
               expected == e$parametric)

    # Shape must not overrule the test. Before 5 August the gate was
    # `shape OR sw`, so a column SW had declined to reject was still sent
    # nonparametric on a rule of thumb.
    # V11, 6 Aug 2026. The "|| length(x) > 50" escape excused a violation the
    # stated rule never permits: the large-n override applies only when SW
    # REJECTS, so it can never license overruling an SW that did not. It was
    # vacuous on the committed data -- no column here has severe shape and all
    # have n = 40 -- which is why it passed unnoticed. Dropped.
    check_true(id, "a column SW does not reject is not sent nonparametric on shape",
               !(sw_ok && shape_severe && !e$parametric))
}

# --- the summary block -----------------------------------------------------
# The plugin prints "Parametric OK: 2 / Nonparametric rec: 1" and calls the
# result mixed. Counting is the orchestrator's job, not the primitive's.
para <- sum(sapply(cols, function(e) e$parametric))
# The two count lines pad inconsistently — "Parametric OK:" is followed by
# five spaces and "Nonparametric rec:" by one — so only the first is
# readable by @printed. Both are parsed from the line instead, and the
# inconsistency is noted rather than worked around silently.
count_of <- function(lbl) {
    ln <- grep(lbl, cap$lines, value = TRUE, fixed = TRUE)
    stopifnot(length(ln) == 1L)
    as.numeric(sub(paste0(".*", lbl, "\\s*(\\d+).*"), "\\1", ln))
}
check("v15", "summary count, parametric OK",
      count_of("Parametric OK:"), para, tol = 0)
check("v15", "summary count, nonparametric rec",
      count_of("Nonparametric rec:"), length(cols) - para, tol = 0)
check_true("v15", "'mixed results' is the right summary for 2 of 3",
           para > 0 && para < length(cols))

# --- the discriminating column --------------------------------------------
# shimmer_pct is the only one that fails, and it fails on Shapiro-Wilk while
# both shape statistics sit well inside the thresholds. That is what makes
# this table a test of the rule and not of one input: a gate that ignored
# Shapiro-Wilk would recommend parametric here and be wrong.
sh <- d$shimmer_pct
check_true("v15", "shimmer_pct fails on Shapiro-Wilk, not on shape",
           shapiro.test(sh)$p.value < 0.05 &&
           abs(skewness_g1(sh))     < SKEW_T &&
           abs(excess_kurtosis(sh)) < KURT_T)
check_true("v15", "so a rule ignoring Shapiro-Wilk would get this column wrong",
           (abs(skewness_g1(sh)) < SKEW_T && abs(excess_kurtosis(sh)) < KURT_T) !=
           cols$shimmer_pct$parametric)

# WHAT THIS TABLE DOES NOT TEST, stated so the coverage is not overclaimed.
# No column here has severe shape, so the drive cannot distinguish the old
# `shape OR sw` gate from the new SW-decides gate: on these three columns
# both rules give the same three answers. The restructure is verified by
# reading the gate, not by this data. A column with |skew| > 2 that
# Shapiro-Wilk declines to reject would separate them, and no demo table
# produces one.
check_true("v15", "no column here has severe shape, so this table cannot separate the two rules",
           all(sapply(d[sapply(d, is.numeric)], function(v)
               abs(skewness_g1(v)) < SKEW_T && abs(excess_kurtosis(v)) < KURT_T)))

if (!exists("EML_SUITE")) { eml_report("v15 normality orchestrator"); eml_exit() }
