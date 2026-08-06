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
# Where the DRIVEN inputs live. The tables under outdir are constructed here
# for R to reason about; the tables under indir are the ones actually loaded
# into Praat, saved out of the live instance before the analysis ran.
indir  <- repo_path("evidence", "csv")
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
# on 5 August the plugin did not survive it. Every complete case has
# medium = soft + 10 and loud = soft + 20 exactly, so the subject x condition
# residual is identically zero and the RM-ANOVA error term is 0. The plugin
# printed
#   F(2, 6) = 21110623253299200.0000
# — a floating-point artefact of dividing by a zero error term — and a
# p-value in 48 decimal places. Its own post-hoc detected the same condition
# correctly and refused ("All differences are identical (zero variance)") on
# all three pairs, so the omnibus was the only place that did not check.
# Recorded as finding D97.
#
# FIXED 6 August, and re-driven on a purpose-built exactly-linear table
# (evidence/csv/rp_r1_rmanova_input.csv). The floor has to be RELATIVE: the
# residual leaves ssErr at around 1e-16 of ssTot rather than at 0, so an
# equality test against zero does not fire. R confirms the residual below.
Y  <- as.matrix(na.omit(read.csv(file.path(outdir, "r1_incomplete_cases.csv"))[, 2:4]))
res <- Y - rowMeans(Y) %o% rep(1, 3) - rep(1, nrow(Y)) %o% colMeans(Y) + mean(Y)
check_true("R1", "error term is exactly zero, so F is undefined",
           max(abs(res)) < 1e-12)

r1cap <- capture("rp_r1_rmanova_info.txt")
Y1 <- as.matrix(read.csv(file.path(indir, "rp_r1_rmanova_input.csv"))[, 2:4])
res1 <- Y1 - rowMeans(Y1) %o% rep(1, 3) -
        rep(1, nrow(Y1)) %o% colMeans(Y1) + mean(Y1)
check_true("R1", "the driven table has a zero subject x condition residual",
           max(abs(res1)) < 1e-12)
check_true("R1", "D97 FIXED: the omnibus printed no F at all",
           !any(grepl("F(", r1cap$lines, fixed = TRUE)))
check_true("R1", "D97 FIXED: and no p-value",
           !any(grepl("p = ", r1cap$lines, fixed = TRUE)))
check_true("R1", "the capture stops at 'Running analysis...'",
           any(grepl("Running analysis", r1cap$lines, fixed = TRUE)))
# The refusal itself is a modal dialog, not Info-window text, so it is
# evidenced by screenshot: evidence/shots/d97_r1_zero_error_term_refused.png.
check_true("R1", "the wizard reached the analysis with RM-ANOVA selected",
           any(grepl("RM-ANOVA", r1cap$lines, fixed = TRUE)))

# --- R2: n = 2 subjects, k = 3 ---------------------------------------------
# Same path. The requirement was: compute or refuse, but SAY WHICH, and do
# not present a p-value from df_error = 2 without comment.
#
# On 5 August the plugin computed F(2, 2) = 441.0000, p = 0.0023,
# GG epsilon = 0.5000, GG-corrected p = 0.0303 and three post-hoc p-values,
# with no comment of any kind. It does print "Subjects (complete cases)
# n = 2", which is honest as far as it goes, but nothing marked the result as
# uninterpretable. Recorded as finding D98.
#
# The epsilon is itself the tell: 0.5 is exactly the Greenhouse-Geisser lower
# bound 1/(k-1), which is forced whenever n = 2. A value pinned to its floor
# means the design has no information left for the correction to use, and the
# plugin has that value in hand at the moment it prints.
#
# FIXED 6 August. The result is still computed and printed — refusing would
# be too strong, the numbers are a fair description of two subjects — but a
# caution now sits directly under the line it qualifies. Position matters: a
# note at the foot of the report would read as being about the post-hoc.
f2 <- rm_anova(as.matrix(read.csv(file.path(outdir, "r2_two_subjects.csv"))[, 2:4]))
check("R2", "R reproduces the plugin's F", 441.0000, f2$F,   tol = 5e-4)
check("R2", "R reproduces the plugin's p",   0.0023, f2$p,   tol = 5e-5)
check("R2", "R reproduces the plugin's GG epsilon", 0.5000, f2$gg, tol = 5e-5)
check_true("R2", "epsilon sits exactly on the 1/(k-1) floor",
           abs(f2$gg - 1 / 2) < 1e-12)

# Re-driven 6 August on a two-subject table. Every printed number is read
# from the capture and checked against R, so the caution cannot have been
# bought by breaking the arithmetic.
r2cap <- capture("rp_r2_rmanova_info.txt")
D2 <- as.matrix(read.csv(file.path(indir, "rp_r2_rmanova_input.csv"))[, 2:4])
g2 <- rm_anova(D2)
# The RM report is written as "label = value", not in the two-space columnar
# form the descriptive reports use, so these read through printed_eq().
check("R2", "driven F",   printed_eq(r2cap, "F(2, 2) ="), g2$F, tol = 5e-4)
check("R2", "driven p",   printed_eq(r2cap, "F(2, 2) =", which = 2), g2$p,
      tol = 5e-5)
check("R2", "driven GG epsilon",
      printed_eq(r2cap, "Greenhouse-Geisser epsilon ="), g2$gg, tol = 5e-5)
check("R2", "driven GG-corrected p",
      printed_eq(r2cap, "Greenhouse-Geisser epsilon =", which = 2),
      g2$p_gg, tol = 5e-5)
check_true("R2", "driven epsilon is on the floor 1/(k-1)",
           abs(printed_eq(r2cap, "Greenhouse-Geisser epsilon =") - 0.5) < 5e-5)
check_true("R2", "D98 FIXED: the report carries a caution",
           any(grepl("Caution:", r2cap$lines, fixed = TRUE)))
check_true("R2", "the caution names n = 2 as the cause",
           any(grepl("n = 2 subjects", r2cap$lines, fixed = TRUE)))
check_true("R2", "and names the forced lower bound",
           any(grepl("lower bound", r2cap$lines, fixed = TRUE)))
# Placement: the caution must come after the GG line and before the post-hoc.
.gg  <- grep("Greenhouse-Geisser epsilon", r2cap$lines, fixed = TRUE)[1]
.cau <- grep("Caution:", r2cap$lines, fixed = TRUE)[1]
.ph  <- grep("Post-hoc", r2cap$lines, fixed = TRUE)[1]
check_true("R2", "the caution sits between the GG line and the post-hoc",
           .gg < .cau && .cau < .ph)

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
# On 5 August the plugin refused before computing, which is the important
# half, but it named only the first offending group:
#   emlOneWayAnova: group "G01" has fewer than 2 observations
# A user with six singleton groups fixes G01, re-runs, and meets G02. The
# diagnosis that ends it in one step — six groups for six rows, so this
# column is an identifier and not a grouping — was never stated, and the
# message leaked the internal procedure name into user-facing text.
# Recorded as finding D99.
#
# FIXED 6 August and re-driven. The refusal is a modal dialog rather than
# Info-window text, so the evidence is the screenshot
# evidence/shots/d99_r5_refusal_names_diagnosis.png, which reads:
#
#   Group column "singer_id" has 6 groups for 6 rows - one per row.
#   This is an identifier column, not a grouping column.
#
# What R can assert here is the shape of the input that must produce it, and
# that the old message's premise (one nameable offender) was never true.
check_true("R5", "plugin refuses before computing anything (driven)", TRUE)
check_true("R5", "every group in this input is a singleton",
           all(table(r5$voice_type) == 1L))
check_true("R5", "so naming one offender at a time would take 6 attempts",
           length(unique(r5$voice_type)) == 6L)
check_true("R5", "D99 FIXED: the refusal states groups-vs-rows, not one group",
           TRUE)

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
# FIXED 6 August, and re-driven on a table carrying all three conditions at
# once (evidence/csv/rp_r6_parse_conditions_input.csv): "n/a" in row 3,
# "73,4" in row 4, an empty cell in row 5.
#
# The fix is one classifier, @eml_classifyCell, used by every extraction
# entry point in eml-extract.praat — the row-wise readers as well as the
# column-wise ones, which is what the author asked for. It also changed a
# result: "73,4" used to coerce to 73 and enter the mean. It is now excluded
# and named, because 1,234 is 1.234 to a European reader and 1234 to an
# American one and the plugin has no basis to choose.
r6cap <- capture("rp_r6_parse_conditions_info.txt")
# The parse note is word-wrapped to the report width, so a sentence spans
# lines and a line-by-line grep would miss it. Collapse to one string first;
# that is what a reader sees, and it is what should be asserted.
r6flat <- paste(trimws(r6cap$lines), collapse = " ")
r6drv <- read.csv(file.path(indir, "rp_r6_parse_conditions_input.csv"),
                  colClasses = "character")
check_true("R6", "driven input has 6 rows", nrow(r6drv) == 6L)
check_true("R6", "one cell is an unparseable string", r6drv$SPL_soft[3] == "n/a")
check_true("R6", "one cell is a decimal comma", r6drv$SPL_soft[4] == "73,4")
check_true("R6", "one cell is empty", r6drv$SPL_soft[5] == "")

check("R6", "D96 FIXED: N (valid) counts only the 3 clean cells",
      printed(r6cap, "N (valid)"), 3, tol = 0)
check("R6", "N (excluded) counts the other 3",
      printed(r6cap, "N (excluded)"), 3, tol = 0)
check_true("R6", "the decimal comma is reported as its own condition",
           grepl("comma where a decimal point belongs", r6flat, fixed = TRUE))
check_true("R6", "and the offending row and value are named",
           grepl("row 4: 73,4", r6flat, fixed = TRUE))
check_true("R6", "the unparseable string is reported separately",
           grepl("not numeric in any locale", r6flat, fixed = TRUE))
check_true("R6", "and named as a type error rather than missing data",
           grepl("type error, not missing data", r6flat, fixed = TRUE))
check_true("R6", "and its row and value are named",
           grepl("row 3: n/a", r6flat, fixed = TRUE))
check_true("R6", "the empty cell is reported as missing data",
           grepl("cell(s) are empty (row 5 first)", r6flat, fixed = TRUE))
check_true("R6", "the three conditions are three distinct sentences",
           length(gregexpr("cell(s)", r6flat, fixed = TRUE)[[1]]) == 3L)

# The mean must be the mean of the three CLEAN values. If "73,4" had been
# coerced the way it was before, the mean would be 72.45 instead of 72.2667 —
# a difference no other number in the report would contradict.
clean <- as.numeric(r6drv$SPL_soft[c(1, 2, 6)])
check("R6", "mean is over the clean values only",
      printed(r6cap, "Mean"), mean(clean), tol = 5e-4)
with_coerced <- c(clean, 73)
check("R6", "and is NOT the mean that coercing the comma cell would give",
      mean(clean), mean(with_coerced), tol = 5e-3, expect = "differ")

# --- R7: small-range measure -----------------------------------------------
# Not driven. This is an axis case, testable only by looking at a figure, and
# it belongs with the graphing work rather than in an R suite.
# Still not driven. It is an axis case: the only way to see it is to look at
# a rendered figure, which belongs with the graphing work and not in an R
# suite. Left failing deliberately so the gap stays visible in the count
# rather than disappearing into a comment.
check_true("R7", "plugin behaviour observed on this input (PENDING DRIVE)", FALSE)

cat("\nRed-path tables written to: ", outdir, "\n", sep = "")

if (!exists("EML_SUITE")) { eml_report("v07 red path — degenerate inputs"); eml_exit() }
