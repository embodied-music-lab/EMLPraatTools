# ============================================================================
# v07 — Red path: degenerate and failing inputs
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# The other scripts validate the happy path against inputs the plugin has
# actually been driven with. This one covers the other half: inputs that
# SHOULD fail, or that sit on a boundary where an implementation can quietly
# produce a number instead of an error.
#
# STATUS as of 5 August 2026: SIX OF SEVEN CASES HAVE BEEN DRIVEN through
# the plugin's real GUI. R7 has not; it is an axis case, judged from a
# figure, and belongs with the graphing work rather than in an R suite.
#
# Of the six driven, two behave as required (R3, R4), one behaves as required
# on the point it was written for and then fails on a second degeneracy the
# case did not anticipate (R1), and three fail (R2, R5, R6). Four checks in
# this file therefore fail ON PURPOSE and name the finding they belong to:
# D96, D97, D98, D99. They pass when those findings are fixed, not before.
#
# Each case still carries two things:
#   1. a runnable record of what R does with the input, which is the
#      reference an independent reviewer can check, and
#   2. the behaviour the plugin must show, stated before the drive rather
#      than after, so the drive could fail.
#
# The generated tables are written to validate/redpath/ so the same files
# can be loaded into Praat and driven through the GUI unchanged. Nothing
# here is random; every case is constructed deterministically.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

outdir <- repo_path("validate", "redpath")
dir.create(outdir, showWarnings = FALSE, recursive = TRUE)
w <- function(name, df) {
    write.csv(df, file.path(outdir, name), row.names = FALSE, quote = FALSE)
    invisible(file.path(outdir, name))
}

# ---------------------------------------------------------------------------
# R1 — a repeated-measures table with genuinely incomplete cases.
#
# The wizard raised "Need at least 2 complete-case subjects" on COMPLETE data
# (finding D83), because a string column had been selected as a condition.
# Its behaviour on actually incomplete data has never been observed.
#
# Required plugin behaviour: report the number of complete cases it is
# analysing, and either drop incomplete subjects with that count stated, or
# refuse. Silently analysing 5 subjects while the table shows 8 is a defect.
# ---------------------------------------------------------------------------
r1 <- data.frame(
    singer     = sprintf("S%02d", 1:8),
    SPL_soft   = c(70.1, 71.2, 72.3, 73.4, 74.5, 75.6, 76.7, 77.8),
    SPL_medium = c(80.1, 81.2,   NA, 83.4, 84.5,   NA, 86.7, 87.8),
    SPL_loud   = c(90.1, 91.2, 92.3, 93.4,   NA, 95.6, 96.7,   NA)
)
w("r1_incomplete_cases.csv", r1)
complete_n <- sum(stats::complete.cases(r1[, c("SPL_soft", "SPL_medium", "SPL_loud")]))
check_true("R1", "constructed table has exactly 4 complete cases of 8",
           complete_n == 4L && nrow(r1) == 8L)
check_true("R1", "R's aov on complete cases is computable",
           is.finite(rm_anova(as.matrix(na.omit(r1[, 2:4])))$F))

# ---------------------------------------------------------------------------
# R2 — the minimum viable repeated-measures design: n = 2 subjects.
#
# df error = (k-1)(n-1) = 2. The F test is computable but the result is
# meaningless. Required plugin behaviour: compute or refuse, but say which,
# and do not present a p-value from df_error = 2 without comment.
# ---------------------------------------------------------------------------
r2 <- data.frame(singer = c("S01", "S02"),
                 SPL_soft = c(70, 72), SPL_medium = c(80, 83), SPL_loud = c(90, 94))
w("r2_two_subjects.csv", r2)
f2 <- rm_anova(as.matrix(r2[, 2:4]))
check_true("R2", "df error is 2", f2$df2 == 2L)
check_true("R2", "F is finite but the design is degenerate", is.finite(f2$F))

# ---------------------------------------------------------------------------
# R3 — zero variance: every value identical.
#
# Required plugin behaviour: refuse with a message naming the zero variance.
# A t or F statistic here is 0/0. The axis-range code has its own guard for
# this (emlComputeAxisRange handles range = 0), so the graphing side is
# expected to survive; the statistics side is the open question.
# ---------------------------------------------------------------------------
r3 <- data.frame(singer = sprintf("S%02d", 1:6),
                 SPL_soft = rep(80, 6), SPL_medium = rep(80, 6), SPL_loud = rep(80, 6))
w("r3_zero_variance.csv", r3)
f3 <- suppressWarnings(rm_anova(as.matrix(r3[, 2:4])))
check_true("R3", "R yields a non-finite F on zero variance", !is.finite(f3$F))

# ---------------------------------------------------------------------------
# R4 — a two-group comparison where one group has a single observation.
#
# Welch's t is undefined when a group variance cannot be estimated.
# Required plugin behaviour: refuse, naming the group and its n.
# ---------------------------------------------------------------------------
r4 <- data.frame(
    singer     = sprintf("S%02d", 1:7),
    voice_type = c(rep("Soprano", 6), "Alto"),
    SPL_dB     = c(88.1, 89.2, 90.3, 91.4, 92.5, 93.6, 70.0)
)
w("r4_singleton_group.csv", r4)
g4 <- split(r4$SPL_dB, r4$voice_type)
check_true("R4", "one group has n = 1", min(vapply(g4, length, integer(1))) == 1L)
check_true("R4", "R's t.test errors on a singleton group",
           inherits(try(t.test(g4$Soprano, g4$Alto, var.equal = FALSE),
                        silent = TRUE), "try-error"))

# ---------------------------------------------------------------------------
# R5 — a "grouping" column that is unique per row.
#
# 6 groups of 1. A pairwise routine would attempt 15 comparisons, none of
# them estimable. Required plugin behaviour: refuse before running, naming
# the group count against the row count. This is the case the unfiltered
# group-column optionmenu (D47 family) makes easy to reach by accident.
# ---------------------------------------------------------------------------
r5 <- data.frame(singer = sprintf("S%02d", 1:6),
                 voice_type = sprintf("G%02d", 1:6),
                 SPL_dB = c(88.1, 89.2, 90.3, 91.4, 92.5, 93.6))
w("r5_all_singleton_groups.csv", r5)
check_true("R5", "group count equals row count",
           length(unique(r5$voice_type)) == nrow(r5))
check_true("R5", "15 pairs would be attempted", choose(6, 2) == 15)

# ---------------------------------------------------------------------------
# R6 — a numeric column carrying non-numeric entries.
#
# This is the shape D82 produces by accident: a column that is not a measure
# gets selected as one. Required plugin behaviour: reject the column by type
# at selection time, and say which column and why — NOT report the data as
# incomplete, which is what D83 records it doing.
# ---------------------------------------------------------------------------
r6 <- data.frame(singer = sprintf("S%02d", 1:5),
                 SPL_soft = c("70.1", "71.2", "n/a", "73.4", "74.5"),
                 SPL_medium = c(80.1, 81.2, 82.3, 83.4, 84.5),
                 SPL_loud = c(90.1, 91.2, 92.3, 93.4, 94.5),
                 stringsAsFactors = FALSE)
w("r6_nonnumeric_in_measure.csv", r6)
coerced <- suppressWarnings(as.numeric(r6$SPL_soft))
check_true("R6", "coercion introduces exactly one NA", sum(is.na(coerced)) == 1L)

# ---------------------------------------------------------------------------
# R7 — a measure whose full range is far below the axis rounding granularity.
#
# This is finding D88 as a data case rather than a code case: contact
# quotient in the 0.4-0.6 range. With roundTo = 10 the axis becomes 0-10 and
# the data occupies 2% of the panel. Required plugin behaviour after the D88
# fix: an axis that fits the data.
# ---------------------------------------------------------------------------
r7 <- data.frame(
    singer = sprintf("S%02d", 1:10),
    CQ_pre  = c(0.412, 0.438, 0.455, 0.471, 0.483, 0.494, 0.507, 0.519, 0.532, 0.548),
    CQ_post = c(0.401, 0.425, 0.442, 0.459, 0.468, 0.481, 0.492, 0.505, 0.517, 0.530)
)
w("r7_small_range_measure.csv", r7)
rng <- range(c(r7$CQ_pre, r7$CQ_post))
check_true("R7", "full data range is well under one axis unit",
           diff(rng) < 1)
check_true("R7", "roundTo = 10 would give a 0-10 axis",
           floor((rng[1] - diff(rng) * 0.1) / 10) * 10 == 0 &&
           ceiling((rng[2] + diff(rng) * 0.1) / 10) * 10 == 10)

# ---------------------------------------------------------------------------
# PLUGIN-SIDE STATUS — six of seven cases driven 5 August 2026
#
# Each case below was loaded into Praat unchanged (Open > Read Table from
# comma-separated file) and taken through the wrapper named. Captures are in
# evidence/info/. R7 remains undriven; it is a figure case and belongs with
# the graphing work rather than here.
# ---------------------------------------------------------------------------

# --- R1: 8 subjects, 4 complete cases --------------------------------------
# Stats Wizard > Compare > paired/repeated > three or more > RM-ANOVA.
#
# The requirement was met: the plugin printed
#   "Subjects (complete cases) n = 4, conditions k = 3"
#   "Note: 4 row(s) excluded for missing data (analyzed n = 4 complete cases)."
# It analysed 4 and said so, twice. It did NOT silently analyse 4 of 8.
check_true("R1", "plugin states the complete-case count it analysed", TRUE)
check_true("R1", "plugin states how many rows it excluded and why", TRUE)

# But this table is also degenerate in a way the case did not anticipate, and
# the plugin did not survive it. Every complete case has medium = soft + 10
# and loud = soft + 20 exactly, so the subject x condition residual is
# identically zero and the RM-ANOVA error term is 0. The plugin printed
#   F(2, 6) = 21110623253299200.0000
# — a floating-point artefact of dividing by a zero error term — and a
# p-value in 48 decimal places. Its own post-hoc detected the same condition
# correctly and refused ("All differences are identical (zero variance)") on
# all three pairs, so the omnibus is the only place that does not check.
# Recorded as finding D97; this check fails until the omnibus refuses too.
Y  <- as.matrix(na.omit(read.csv(file.path(outdir, "r1_incomplete_cases.csv"))[, 2:4]))
res <- Y - rowMeans(Y) %o% rep(1, 3) - rep(1, nrow(Y)) %o% colMeans(Y) + mean(Y)
check_true("R1", "error term is exactly zero, so F is undefined",
           max(abs(res)) < 1e-12)
check_true("R1", "PLUGIN DEFECT D97: omnibus must refuse on a zero error term",
           FALSE)

# --- R2: n = 2 subjects, k = 3 ---------------------------------------------
# Same path. The requirement was: compute or refuse, but SAY WHICH, and do
# not present a p-value from df_error = 2 without comment.
#
# The plugin computed F(2, 2) = 441.0000, p = 0.0023, GG epsilon = 0.5000,
# GG-corrected p = 0.0303, and three post-hoc p-values — with no comment of
# any kind. It does print "Subjects (complete cases) n = 2", which is honest
# as far as it goes, but nothing marks the result as uninterpretable.
#
# The epsilon is itself the tell: 0.5 is exactly the Greenhouse-Geisser lower
# bound 1/(k-1), which is forced whenever n = 2. A value pinned to its floor
# is a signal the design has no information left, and the plugin has it in
# hand at the moment it prints.
f2 <- rm_anova(as.matrix(read.csv(file.path(outdir, "r2_two_subjects.csv"))[, 2:4]))
check("R2", "R reproduces the plugin's F", 441.0000, f2$F,   tol = 5e-4)
check("R2", "R reproduces the plugin's p",   0.0023, f2$p,   tol = 5e-5)
check("R2", "R reproduces the plugin's GG epsilon", 0.5000, f2$gg, tol = 5e-5)
check_true("R2", "epsilon sits exactly on the 1/(k-1) floor",
           abs(f2$gg - 1 / 2) < 1e-12)
check_true("R2", "PLUGIN DEFECT D98: no comment on a df_error = 2 result",
           FALSE)

# --- R3: zero variance throughout ------------------------------------------
# Compare paired/repeated, SPL_soft against SPL_medium.
# Requirement: refuse, naming the zero variance. The plugin printed
#   "SPL soft: Mean = 80.000, SD = 0, Median = 80.000"
#   "Paired t-test error: All differences are identical (zero variance)"
# It refused, named the condition, and fabricated no statistic. Case closed.
check_true("R3", "plugin refuses and names the zero variance (driven)", TRUE)

# --- R5: grouping column unique per row ------------------------------------
# Compare k groups (ANOVA). Requirement: refuse BEFORE running, naming the
# group count against the row count.
#
# The plugin refuses before computing, which is the important half. But it
# names only the first offending group:
#   emlOneWayAnova: group "G01" has fewer than 2 observations
# A user with six singleton groups fixes G01, re-runs, and meets G02. The
# diagnosis that would end it in one step — six groups for six rows, so this
# column is an identifier and not a grouping — is never stated. The message
# also leaks the internal procedure name into user-facing text.
# Recorded as finding D99.
check_true("R5", "plugin refuses before computing anything (driven)", TRUE)
check_true("R5", "PLUGIN DEFECT D99: names one group, not the count-vs-rows diagnosis",
           FALSE)

# --- R6: non-numeric entry in a measure column -----------------------------
# Describe Table column, SPL_soft — the column holding "n/a" in row 3 of 5.
#
# CORRECTION, same day. This case was first recorded as "the plugin silently
# analyses 4 of 5 rows, naming nothing". That was WRONG, and it was wrong
# because the capture was read from its tail. The header block says:
#
#     Column              SPL soft
#     N (valid)           4
#     N (undefined)       1
#
# The plugin reports the count. It follows the complete-case convention set
# on 21 July (plugin/FIX_NOTES.md, audit item C1/C2): analyse the rows that
# parse, state how many were excluded. Nothing is silent.
check_true("R6", "plugin reports N (valid) 4 and N (undefined) 1 (driven)", TRUE)

# What is genuinely missing is narrower, and is the open question the author
# raised: "undefined" is one bucket holding three different conditions that
# a user needs to tell apart —
#
#   1. an empty cell           — missing data, the C1/C2 convention applies
#   2. an unparseable string   — a type error; the column is not a measure
#   3. a European decimal comma — recoverable data being discarded
#
# `Get value:` returns undefined for all three, so nothing downstream can
# distinguish them, and the report names neither the row nor the offending
# value. A user cannot tell a gap in their data from a locale mismatch that
# threw away a number they have. Recorded as finding D96, restated.
r6read <- read.csv(file.path(outdir, "r6_nonnumeric_in_measure.csv"),
                   stringsAsFactors = FALSE)
check_true("R6", "constructed column has exactly one non-numeric entry",
           sum(is.na(suppressWarnings(as.numeric(r6read$SPL_soft)))) == 1L)
check_true("R6", "the offending value is a string, not an empty cell",
           any(!is.na(r6read$SPL_soft) & r6read$SPL_soft != "" &
               is.na(suppressWarnings(as.numeric(r6read$SPL_soft)))))
check_true("R6", "PLUGIN DEFECT D96: missing, unparseable and locale-decimal are one bucket",
           FALSE)

# --- R7: small-range measure -----------------------------------------------
# Not driven. This is an axis case, testable only by looking at a figure, and
# it belongs with the graphing work rather than in an R suite.
check_true("R7", "plugin behaviour observed on this input (PENDING DRIVE)", FALSE)

cat("\nRed-path tables written to: ", outdir, "\n", sep = "")

if (!exists("EML_SUITE")) { eml_report("v07 red path — degenerate inputs"); eml_exit() }
