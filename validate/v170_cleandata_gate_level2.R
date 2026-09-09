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
# PAIRED — @emlRunPairedAnalysis. RE-DERIVED 9 September 2026 under
# CORRECTION_LEVEL2_IS_A_REFUSAL: both columns were checked with strict = 0
# (eml-analysis.praat:2873/2878), which used to mean an unreadable cell in
# one column dropped that row under complete-case. Level 2 now refuses
# unconditionally regardless of strict, so the door REFUSES on col1's ("pre")
# unreadable cell instead: @emlExtractPairedColumns' dirty-column path audits
# .col1$ first and refuses with role "First column" before .col2$ is even
# looked at, so no pair is ever built and no report is printed. .remedy$
# reads "" here (orchestrators do not forward it -- see v08's level-2
# comment; the text itself is proved at its source, see the categorical
# block below).
# ---------------------------------------------------------------------------
pcap <- capture("kit_cleandata_l2_paired_info.txt")
pcapflat <- paste(trimws(pcap$lines), collapse = " ")
check_true("v170-paired", "L2: no report is printed -- the refusal happens before either column is read",
           !any(grepl("^N", trimws(pcap$lines))))
check_true("v170-paired", "L2: emlRunPairedAnalysis.ok = 0",
           any(grepl("emlRunPairedAnalysis.ok = 0", pcap$lines, fixed = TRUE)))
check_true("v170-paired", "L2: the three-part .error$ names the first column, row 3, and the literal \"??\"",
           grepl('emlRunPairedAnalysis.error$ = "First column "pre" has a cell that is not numeric, at row 3: "??"."',
                 pcapflat, fixed = TRUE))
check_true("v170-paired", "L2: .remedy$ is empty -- orchestrators do not forward the gate's .remedy$ (documented gap, out of scope)",
           any(grepl('emlRunPairedAnalysis.remedy$ = ""', pcap$lines, fixed = TRUE)))

# ---------------------------------------------------------------------------
# REPEATED MEASURES — @emlRunRepeatedMeasuresAnalysis (wide format).
# RE-DERIVED 9 September 2026: its complete-case matrix used to be resolved
# by dropping any SUBJECT (whole row) whose condition cell was unreadable.
# Level 2 now refuses unconditionally: @eml_getGroupData's non-fast-path
# branch (which @eml_rmResolveMatrix's per-condition read goes through) runs
# one column-wide audit on the "medium" condition column up front and
# refuses with role "Condition column" before any subject matrix is built,
# so no RM-ANOVA is ever computed. .remedy$ reads "" here (orchestrators do
# not forward it -- see v08's level-2 comment; the text itself is proved at
# its source, see the categorical block below).
# ---------------------------------------------------------------------------
rmcap <- capture("kit_cleandata_l2_rm_info.txt")
rmcapflat <- paste(trimws(rmcap$lines), collapse = " ")
check_true("v170-rm", "L2: no report is printed -- the refusal happens before any subject matrix is built",
           !any(grepl("Subjects", rmcap$lines, fixed = TRUE)))
check_true("v170-rm", "L2: emlRunRepeatedMeasuresAnalysis.ok = 0",
           any(grepl("emlRunRepeatedMeasuresAnalysis.ok = 0", rmcap$lines, fixed = TRUE)))
check_true("v170-rm", "L2: the three-part .error$ names the condition column, row 3, and the literal \"??\"",
           grepl('emlRunRepeatedMeasuresAnalysis.error$ = "Condition column "medium" has a cell that is not numeric, at row 3: "??"."',
                 rmcapflat, fixed = TRUE))
check_true("v170-rm", "L2: .remedy$ is empty -- orchestrators do not forward the gate's .remedy$ (documented gap, out of scope)",
           any(grepl('emlRunRepeatedMeasuresAnalysis.remedy$ = ""', rmcap$lines, fixed = TRUE)))

# ---------------------------------------------------------------------------
# RELIABILITY (survey ITEMS) — @emlRunReliabilityAnalysis. RE-DERIVED
# 9 September 2026: each item column used to be checked with strict = 0
# (eml-analysis.praat:4255) and a respondent missing any item was dropped
# from the complete-case matrix. Level 2 now refuses unconditionally on
# item1's unreadable cell, with role "Item column 1", before Cronbach's
# alpha is ever computed. .remedy$ reads "" here (orchestrators do not
# forward it -- see v08's level-2 comment; the text itself is proved at its
# source, see the categorical block below).
# ---------------------------------------------------------------------------
relcap <- capture("kit_cleandata_l2_reliability_info.txt")
relcapflat <- paste(trimws(relcap$lines), collapse = " ")
check_true("v170-reliability", "L2: no report is printed -- the refusal happens before Cronbach's alpha is computed",
           !any(grepl("respondents", relcap$lines, fixed = TRUE)))
check_true("v170-reliability", "L2: emlRunReliabilityAnalysis.ok = 0",
           any(grepl("emlRunReliabilityAnalysis.ok = 0", relcap$lines, fixed = TRUE)))
check_true("v170-reliability", "L2: the three-part .error$ names item column 1, row 3, and the literal \"??\"",
           grepl('emlRunReliabilityAnalysis.error$ = "Item column 1 "item1" has a cell that is not numeric, at row 3: "??"."',
                 relcapflat, fixed = TRUE))
check_true("v170-reliability", "L2: .remedy$ is empty -- orchestrators do not forward the gate's .remedy$ (documented gap, out of scope)",
           any(grepl('emlRunReliabilityAnalysis.remedy$ = ""', relcap$lines, fixed = TRUE)))

# ---------------------------------------------------------------------------
# CATEGORICAL (survey COUNTS) — @emlRunCategoricalAnalysis. UNCHANGED IN
# BEHAVIOUR: its count column was already checked with strict = 1
# (eml-analysis.praat:4524), because the chi-square kernel reads it as a
# whole with no per-cell drop available, so one unreadable count cell was
# already refusing the ENTIRE table before this correction -- the same way
# two-way's data column does (see v11's level-2 block for the parallel
# case). RE-DERIVED ANYWAY, 9 September 2026: the WORDING changed, the same
# way it changed for two-way -- @emlRequireNumericColumn now tests
# emlAuditColumn.nLevel2 > 0 before it ever consults .strict, so a "??" cell
# is caught by the new @eml_level2Refusal branch and gets the three-part
# column/row/value sentence, not the old whole-column "is not numeric in
# every row" wording. The refusal text is the literal .error$ string,
# captured by the driver immediately after the call.
# ---------------------------------------------------------------------------
catcap <- capture("kit_cleandata_l2_categorical_info.txt")
catflat <- paste(trimws(catcap$lines), collapse = " ")
check_true("v170-categorical", "L2: categorical refuses the whole table on one unreadable count cell (strict column read)",
           grepl('emlRunCategoricalAnalysis.error$ = "Count column "count" has a cell that is not numeric, at row 3: "??"."',
                 catflat, fixed = TRUE))
check_true("v170-categorical", "L2: emlRunCategoricalAnalysis.ok = 0",
           any(grepl("emlRunCategoricalAnalysis.ok = 0", catcap$lines, fixed = TRUE)))
check_true("v170-categorical", "L2: .remedy$ is empty -- orchestrators do not forward the gate's .remedy$ (documented gap, out of scope)",
           any(grepl('emlRunCategoricalAnalysis.remedy$ = ""', catcap$lines, fixed = TRUE)))
check_true("v170-categorical", "and the refusal is the door's own .error$, not a silent pass",
           grepl("emlRunCategoricalAnalysis.error$ = \"", catflat, fixed = TRUE) &&
           !grepl("emlRunCategoricalAnalysis.error$ = \"\"", catflat, fixed = TRUE))

if (!exists("EML_SUITE")) {
    eml_report("v170 data-cleaning gate — level-2 fixtures (paired, RM, reliability, categorical)")
    eml_exit()
}
