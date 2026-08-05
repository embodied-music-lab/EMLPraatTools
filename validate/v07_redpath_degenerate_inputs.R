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
# STATUS: the R side is complete and runnable now. The plugin side is NOT
# YET DRIVEN — no EML wrapper has been given any of these inputs. This file
# is therefore two things at once:
#
#   1. a runnable record of what R does with each case, which is the
#      reference an independent reviewer can check, and
#   2. the specification for the drive that has not happened yet — each
#      case names the behaviour the plugin must show.
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
# Plugin-side status. Each case that has NOT been given to the plugin through
# its GUI carries a deliberately failing check, so the suite cannot report
# green while that work is outstanding.
#
# R4 was driven on 5 August 2026 and is no longer pending. The table above
# was loaded into Praat unchanged (Open > Read Table from comma-separated
# file) and taken through the Stats Wizard: Compare > independent > two
# groups > SPL_dB by voice_type > Welch > Run. The plugin refused, and the
# refusal named the group and its n, which is what this case requires:
#
#     Each group needs at least 2 observations. Group "Soprano":
#     n=6, group "Alto": n=1
#
# Screenshot: evidence/shots/d93_wizard_analysis_error_R4.png
# ---------------------------------------------------------------------------
check_true("R4", "plugin refuses, naming the group and its n (driven 5 Aug 2026)",
           TRUE)

for (case in c("R1", "R2", "R3", "R5", "R6", "R7")) {
    check_true(case, "plugin behaviour observed on this input (PENDING DRIVE)", FALSE)
}

cat("\nRed-path tables written to: ", outdir, "\n", sep = "")

if (!exists("EML_SUITE")) { eml_report("v07 red path — degenerate inputs"); eml_exit() }
