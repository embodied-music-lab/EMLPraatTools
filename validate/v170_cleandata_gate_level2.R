# ============================================================================
# v170 — data-cleaning wave: level-2 fixtures for the doors with no
# dedicated orchestrator file of their own (paired, repeated measures,
# survey items / reliability, survey counts / categorical)
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Built 8 September 2026 under RULING_DATA_CLEANING_POLICY /
# RULING_DATA_CLEANING_TWO_ITEMS, per
# ANSWER_DATA_CLEANING_ESTIMATE_PART1_2026-09-08's fixture answer: "Every
# other door that sits on the shared gate ... gets one level-2 fixture,
# which proves the refusal text relays through that door's orchestrator. No
# level-1 fixture for those: the repair is proved once in the extraction
# layer." Four of those doors -- paired comparison, repeated-measures
# ANOVA, reliability (Cronbach's alpha, the survey ITEMS door) and
# categorical association (chi-square, the survey COUNTS door) -- have no
# existing v-numbered orchestrator file the way descriptives (v14),
# normality (v15), Kruskal-Wallis (v10) and two-way (v11) do, so their one
# level-2 case each lives here instead of forcing a new home-file split
# four ways.
#
# Every table below carries exactly one genuinely unreadable cell ("??"),
# driven headlessly (none of these four procedures use beginPause:) by
# evidence/redrive/kit_cleandata_other_doors.praat under `praat --run`.
#
# EVERY REPORTED VALUE IS READ FROM THE COMMITTED CAPTURE; see the note at
# the head of v08.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

# ---------------------------------------------------------------------------
# PAIRED — @emlRunPairedAnalysis. Both columns are checked with strict = 0
# (see eml-analysis.praat:2873/2878), so an unreadable cell in one column
# drops that row under the same complete-case convention paired comparisons
# already used, and the door prints an explicit exclusion sentence -- the
# same wording @emlRunCorrelationAnalysis uses.
# ---------------------------------------------------------------------------
pd  <- read_input("kit_cleandata_l2_paired_input.csv")
pcap <- capture("kit_cleandata_l2_paired_info.txt")
keep_p <- !is.na(suppressWarnings(as.numeric(pd$pre)))
p_pre <- as.numeric(pd$pre[keep_p])
p_post <- pd$post[keep_p]
check_true("v170-paired", "the fixture's one unreadable cell (\"??\") leaves 5 complete pairs",
           length(p_pre) == 5L)
check("v170-paired", "L2: N (pairs) is 5 -- the unreadable cell is refused",
      printed(pcap, "N (pairs)"), length(p_pre), tol = 0)
tt_p <- t.test(p_pre, p_post, paired = TRUE)
check("v170-paired", "L2: paired t over the reduced sample",
      printed(pcap, "t"), unname(tt_p$statistic), tol = 5e-3)
check_true("v170-paired", "L2: the door's own exclusion sentence names 1 row and 5 complete pairs",
           any(grepl("1 row(s) excluded for missing data (analyzed n = 5 complete pairs)",
                     pcap$lines, fixed = TRUE)))

# ---------------------------------------------------------------------------
# REPEATED MEASURES — @emlRunRepeatedMeasuresAnalysis (wide format). Its
# complete-case matrix is resolved by @eml_rmResolveMatrix, which reads
# every condition column row-wise through the same @eml_cleanVerdict path
# (via eml_readCell) as every other extraction entry point; an unreadable
# cell drops that SUBJECT (the whole row), not just one condition value,
# because the RM design needs every condition present to keep a subject.
# ---------------------------------------------------------------------------
rmd  <- read_input("kit_cleandata_l2_rm_input.csv")
rmcap <- capture("kit_cleandata_l2_rm_info.txt")
rm_keep <- !is.na(suppressWarnings(as.numeric(rmd$medium)))
check_true("v170-rm", "the fixture's one unreadable cell (\"??\") leaves 5 of 6 complete subjects",
           sum(rm_keep) == 5L)
check_true("v170-rm", "L2: the report states 5 complete cases",
           any(grepl("Subjects (complete cases) n = 5", rmcap$lines, fixed = TRUE)))
check_true("v170-rm", "L2: the door's own exclusion note names 1 row excluded",
           any(grepl("Note: 1 row(s) excluded for missing data (analyzed n = 5 complete cases)",
                     rmcap$lines, fixed = TRUE)))
check_true("v170-rm", "L2: the parse note names the offending column, row and value",
           any(grepl("medium: 1 cell(s) are not numeric in any locale (row 3: ??)",
                     rmcap$lines, fixed = TRUE)))
rm_dat <- as.matrix(rmd[rm_keep, c("soft", "medium", "loud")])
storage.mode(rm_dat) <- "numeric"
f_rm <- rm_anova(rm_dat)
check("v170-rm", "L2: RM-ANOVA F over the 5 retained subjects",
      printed_eq(rmcap, "F(2, 8) ="), f_rm$F, tol = 5e-3)

# ---------------------------------------------------------------------------
# RELIABILITY (survey ITEMS) — @emlRunReliabilityAnalysis. Each item column
# is checked with strict = 0 (eml-analysis.praat:4255), and a respondent
# missing any item is dropped from the complete-case matrix, disclosed in
# its own wording ("assessed n = X of Y respondents").
# ---------------------------------------------------------------------------
rel  <- read_input("kit_cleandata_l2_reliability_input.csv")
relcap <- capture("kit_cleandata_l2_reliability_info.txt")
rel_keep <- !is.na(suppressWarnings(as.numeric(rel$item1)))
check_true("v170-reliability", "the fixture's one unreadable cell (\"??\") leaves 5 of 6 complete respondents",
           sum(rel_keep) == 5L)
check_true("v170-reliability", "L2: the report states 5 respondents were assessed",
           any(grepl("respondents (n) = 5", relcap$lines, fixed = TRUE)))
check_true("v170-reliability", "L2: the door's own exclusion note names 1 row and 5 of 6 respondents",
           any(grepl("1 row(s) excluded for missing data (assessed n = 5 of 6 respondents)",
                     paste(trimws(relcap$lines), collapse = " "), fixed = TRUE)))
items_kept <- as.matrix(rel[rel_keep, c("item1", "item2", "item3")])
storage.mode(items_kept) <- "numeric"
k_items <- ncol(items_kept)
item_var <- apply(items_kept, 2, var)
total_var <- var(rowSums(items_kept))
alpha_r <- (k_items / (k_items - 1)) * (1 - sum(item_var) / total_var)
check("v170-reliability", "L2: Cronbach's alpha over the 5 retained respondents",
      printed_eq(relcap, "Cronbach's alpha ="), alpha_r, tol = 5e-3)

# ---------------------------------------------------------------------------
# CATEGORICAL (survey COUNTS) — @emlRunCategoricalAnalysis. UNIQUE among
# these four: its count column is checked with strict = 1
# (eml-analysis.praat:4524), because the chi-square kernel reads it as a
# whole with no per-cell drop available. One unreadable count cell refuses
# the ENTIRE table, the same way two-way's data column does -- see v11's
# level-2 block for the parallel case. The refusal text is the literal
# .error$ string, captured by the driver immediately after the call.
# ---------------------------------------------------------------------------
catcap <- capture("kit_cleandata_l2_categorical_info.txt")
catflat <- paste(trimws(catcap$lines), collapse = " ")
check_true("v170-categorical", "L2: categorical refuses the whole table on one unreadable count cell (strict column read)",
           grepl("not numeric in every row", catflat, fixed = TRUE))
check_true("v170-categorical", "and names the offending row and value",
           grepl("row 3: ??", catflat, fixed = TRUE))
check_true("v170-categorical", "and the refusal is the door's own .error$, not a silent pass",
           grepl("emlRunCategoricalAnalysis.error$ = \"", catflat, fixed = TRUE) &&
           !grepl("emlRunCategoricalAnalysis.error$ = \"\"", catflat, fixed = TRUE))

if (!exists("EML_SUITE")) {
    eml_report("v170 data-cleaning gate — level-2 fixtures (paired, RM, reliability, categorical)")
    eml_exit()
}
