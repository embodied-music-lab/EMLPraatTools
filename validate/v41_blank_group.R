# ============================================================================
# v41_blank_group.R -- a blank group cell is missing data, not a category
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. @emlCountGroups matches on the NORMALISED label and
# had no test for an empty one, so a row whose group cell was blank -- or
# whitespace only, which @eml_normalizeLabel folds to empty -- became a group
# of its own, indistinguishable from a real level.
#
# THE COUNT IS NOT A DISPLAY DETAIL. It is k, and k propagates:
#
#   dfBetween = k - 1 and dfWithin = N - k in @emlOneWayAnova
#   k(k-1)/2 comparisons in every post-hoc, so one phantom group at a real
#     k = 3 gives SIX adjusted p-values instead of three, each inflated
#   @emlRunTwoGroupAnalysis refuses at k > 2 and routes the user to ANOVA, so
#     a single blank cell made the t-test unavailable on a genuine two-group
#     table
#   the draw layer sizes its palette and legend from k, so the figure grew an
#     unlabelled entry
#
# Under emlGroupSortAlphabetical = 1 the blank also sorted FIRST, taking index
# 1 and shifting every real group's index by one.
#
# WHY NOTHING CAUGHT IT. No fixture in the tree had a blank group cell --
# every value-column blank in harness/ is in a VALUE column, not a group one
# -- with a single exception: harness/disclosure/probe_exclusion_parity.praat,
# which has DEMONSTRATED the defect since it was written ("a blank group label
# is counted as a category") and which no validator consumes. Documented,
# unasserted, unfixed.
#
#     bash harness/blankgroup/run.sh      regenerate the input
#     Rscript validate/v41_blank_group.R
#
# Input: <dir>/BLANKGROUP.tsv, four fields, no header:
#            case  nGroups  nBlank  labels
#        <dir> is $EML_BLANKGROUP_DIR, default harness/blankgroup/out. A
#        missing artefact is a HARD STOP, not a skip.
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

bg_dir <- Sys.getenv("EML_BLANKGROUP_DIR", unset = "")
if (!nzchar(bg_dir)) bg_dir <- repo_path("harness", "blankgroup", "out")
bg_p <- file.path(bg_dir, "BLANKGROUP.tsv")

if (!file.exists(bg_p)) {
    stop("blank-group artefact not found: ", bg_p,
         "\n  Run: bash harness/blankgroup/run.sh")
}

bg <- read.delim(bg_p, header = FALSE, stringsAsFactors = FALSE,
                 col.names = c("case", "nGroups", "nBlank", "labels"))
bg$nGroups <- as.integer(bg$nGroups)
bg$nBlank  <- as.integer(bg$nBlank)

CASES <- c("clean", "oneblank", "whitespace", "twogroupblank")
eml_census("v41", "blank-group case", bg$case, CASES)
eml_claim("v41", "blankgroup_out", CASES)
check("v41", "every declared case was driven", nrow(bg), length(CASES),
      tol = 0)

.g <- function(nm, col) bg[[col]][match(nm, bg$case)]

# ---------------------------------------------------------------------------
# THE CONTROL. Without it every assertion below could be met by a procedure
# that had simply stopped counting.
# ---------------------------------------------------------------------------
check("v41", "clean: three real groups", 3, .g("clean", "nGroups"), tol = 0)
check("v41", "clean: nothing reported blank", 0, .g("clean", "nBlank"),
      tol = 0)

# ---------------------------------------------------------------------------
# THE ASSERTION THIS FILE WAS BUILT FOR
# ---------------------------------------------------------------------------
check("v41", "oneblank: the empty cell is not a fourth group", 3,
      .g("oneblank", "nGroups"), tol = 0)
check("v41", "oneblank: and it is counted, not silently dropped", 1,
      .g("oneblank", "nBlank"), tol = 0)

# WHITESPACE FOLDS TO EMPTY, so "   " must be neither a fourth group nor a
# second kind of blank. @eml_normalizeLabel trims before this file sees it,
# and one test has to cover both or the cheaper fix (== "") would pass.
check("v41", "whitespace: a spaces-only cell is not a fourth group", 3,
      .g("whitespace", "nGroups"), tol = 0)
check("v41", "whitespace: it is counted as blank, like an empty cell", 1,
      .g("whitespace", "nBlank"), tol = 0)
check_true("v41", "whitespace and oneblank agree on both counts",
           .g("whitespace", "nGroups") == .g("oneblank", "nGroups") &&
           .g("whitespace", "nBlank") == .g("oneblank", "nBlank"))

# THE CASE WITH TEETH. @emlRunTwoGroupAnalysis refuses at k > 2, so before the
# fix one blank cell in a genuine two-group table made the t-test unavailable
# and routed the user to ANOVA instead.
check("v41", "twogroupblank: a two-group table stays a two-group table", 2,
      .g("twogroupblank", "nGroups"), tol = 0)
check("v41", "twogroupblank: the blank row is reported", 1,
      .g("twogroupblank", "nBlank"), tol = 0)

# ---------------------------------------------------------------------------
# THE LABELS ARE THE REAL ONES, and no empty string is among them
# ---------------------------------------------------------------------------
# A count can be right while the labels are wrong -- dropping a real group and
# keeping the blank would also give 3. Checked on the names.
for (nm in CASES) {
    lab <- strsplit(.g(nm, "labels"), ",", fixed = TRUE)[[1]]
    check_true("v41", paste(nm, "labels are all non-empty"),
               length(lab) > 0 && !any(trimws(lab) == ""))
    check("v41", paste(nm, "label count equals the group count"),
          .g(nm, "nGroups"), length(lab), tol = 0)
}

if (!exists("EML_SUITE")) {
    eml_report("v41 blank group: an empty group cell is missing data")
    eml_exit()
}
