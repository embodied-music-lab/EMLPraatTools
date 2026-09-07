#!/usr/bin/env Rscript
# ============================================================================
# v166 -- repeated-measures / Friedman: the LONG path, driven and proven
#         equivalent to the WIDE path
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. @emlRunRepeatedMeasuresAnalysis and
# @emlRunFriedmanAnalysis (plugin_EML_StatsGraphs/stats/eml-analysis.praat)
# accept a WIDE table directly, or a LONG table that @eml_rmResolveMatrix
# reshapes to wide first (@emlReshapeSeriesWide) before handing it to the
# SAME @emlExtractConditionMatrix the wide door calls directly. Every
# validator that exercises these two procedures elsewhere in this suite --
# v03, v04, v163 -- drives the WIDE door only. This file drives the LONG
# door, for the first time, and settles the one property that makes "the
# long door works" a meaningful claim rather than "the long door runs
# without erroring": on the SAME underlying data, wide and long must produce
# the IDENTICAL statistics, because internally they are the identical
# computation on the identical matrix.
#
# THREE LEGS.
#
#   LEG A (core) -- validate/rm_wide_long_probe.praat builds three fixtures
#   (n=6/k=3 no ties, n=5/k=4 sphericity-violated, and n=5/k=3 with one
#   cell blanked so one subject is excluded) as both a wide table and the
#   same data melted to long, drives @emlRunRepeatedMeasuresAnalysis and
#   @emlRunFriedmanAnalysis on all four (proc x shape) combinations per
#   fixture, and every number that comes back is printed with Praat's
#   `string$ ()` -- which round-trips a double exactly (measured: 0.1 + 0.2
#   prints "0.30000000000000004", the same string R's own %.17g gives the
#   same sum) -- so a STRING-EQUALITY check between the wide and long columns
#   is a bit-identity check, not a numeric check with a tolerance that could
#   paper over a real divergence. n, nExcluded, fStat/dfCond/dfErr/p/
#   ggEpsilon/pGG/ssCond/ssErr (RM), chiSq/df/p/Kendall's W (Friedman), and
#   every post-hoc raw/adjusted p (holm) are all checked this way. The pair
#   each rawP_i/adjP_i belongs to is confirmed identical between shapes
#   (pairKey_i) before the values themselves are compared -- so a column
#   permutation would fail here, loudly, rather than comparing the wrong
#   pair to the wrong pair and agreeing by coincidence.
#
#   LEG B (red demo) -- the long door alone can refuse two shapes wide data
#   cannot express: a subject missing one condition's row entirely (an
#   INCOMPLETE cell) and a subject x condition pair appearing twice (a
#   DUPLICATE cell). @eml_rmResolveMatrix's own two refusal sentences are
#   asserted verbatim (read from eml-analysis.praat, not guessed), plus a
#   self-test in the v163/v145/v158 EML_*_RED convention: a deliberately
#   WRONG expected refusal text is asserted to DIFFER from the real one
#   (passes, proving the real assertion above is falsifiable and not a
#   tautology), and the same wrong text can be asserted to MATCH by setting
#   EML_V166_RED=1 -- which fails on purpose and is not part of the normal
#   green run.
#
#   LEG C (R-oracle, belt-and-suspenders) -- Leg A's own long-path numbers
#   for the first fixture (n=6, k=3, no ties) are compared against base R's
#   aov()/Error() and friedman.test(), the same two independent oracles v03
#   and v04 already use on the wide door. This does not re-run Praat: Leg A
#   already captured the long door's fStat/p and chiSq/p for this fixture,
#   and re-reading them here is what "belt-and-suspenders on top of Leg A"
#   means -- a second, independent check on numbers already in hand, not a
#   second drive of the same probe.
#
# WHY THIS COULDN'T HAVE BEEN A DIFF OF THE PRINTED REPORT. The Info-window
# report's header line names the input Table by `selected$ ("Table")`, which
# necessarily differs between the wide Table object and the long Table
# object -- diffing the two reports whole would fail on that line before
# ever reaching a statistic. Reading named fields off the run instead (as
# v163's PART 1-3 do for @emlHodgesLehmannPaired) sidesteps exactly that,
# which is why this file's probe is a field dumper and not a report capture.
#
# HOW TO RUN
#
#     PRAAT=/usr/local/bin/praat6630 \
#     EML_PLUGIN_DIR=/tmp/eml-repo/plugin_EML_StatsGraphs \
#     Rscript validate/v166_rm_wide_long_equivalence.R
#
# Requires a Praat at or above the plugin's floor (6.6.30); skips (not
# fails) below it, the v108/v143/v152/v163/v164 convention.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v166"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}
# gxr_locate_praat / gxr_praat_version_num are general-purpose Praat-locating
# plumbing, not group-extraction-specific despite their prefix -- reused here
# rather than re-implemented, per validate/tools/group_extraction_runner.R's
# own header ("ONE FUNCTION, TWO CALLERS"); this file is a third.
source(file.path(repo_path("validate"), "tools", "group_extraction_runner.R"))

STD_REL <- 1e-9
STD_ABS <- 1e-12
std_tol <- function(computed) max(STD_ABS, STD_REL * abs(computed))

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)

praat <- gxr_locate_praat()
pvnum <- gxr_praat_version_num(praat)
canDrive <- pvnum >= 6630

if (!canDrive) {
    cat(paste0("      SKIP: v166 needs Praat >= 6.6.30 to drive the probe;\n",
               "            found ", if (nzchar(praat)) praat else "none", ".\n"))
    check_true(V, sprintf("a Praat at or above the plugin's floor is available (found %s)",
                          if (nzchar(praat)) praat else "none"), FALSE)
} else {

work <- file.path(tempdir(), "v166")
unlink(work, recursive = TRUE)
dir.create(work, showWarnings = FALSE, recursive = TRUE)
prefs <- file.path(work, "prefs")
dir.create(prefs, showWarnings = FALSE)

# ---------------------------------------------------------------------------
# prelude -- the full stats+graphs include list @emlRunRepeatedMeasuresAnalysis
# and @emlRunFriedmanAnalysis need. Copied from validate/v163_hl_paired_
# disclosure.R's own `prelude(inferential_file, analysis_file)`, which is
# itself the include list v163 measured against the real orchestrators;
# reused verbatim rather than re-derived so a change to what eml-analysis.praat
# needs is fixed in one place if it ever drifts.
# ---------------------------------------------------------------------------
INF <- file.path(plug, "stats", "eml-inferential.praat")
ANA <- file.path(plug, "stats", "eml-analysis.praat")
PROBE <- repo_path("validate", "rm_wide_long_probe.praat")
stopifnot(file.exists(INF), file.exists(ANA), file.exists(PROBE))

prelude <- c(
    paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
    paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
    paste0("include ", file.path(plug, "stats", "eml-extract.praat")),
    paste0("include ", file.path(plug, "stats", "eml-output.praat")),
    paste0("include ", file.path(plug, "stats", "eml-wilcoxon-interval.praat")),
    paste0("include ", INF),
    paste0("include ", file.path(plug, "stats", "eml-result-writer.praat")),
    paste0("include ", file.path(plug, "graphs", "eml-graph-procedures.praat")),
    paste0("include ", file.path(plug, "graphs", "eml-annotation-procedures.praat")),
    paste0("include ", ANA),
    paste0("include ", PROBE))

drive <- function(probe_path, secs = "180") {
    suppressWarnings(system2("timeout",
        c(secs, "env", "-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
        stdout = TRUE, stderr = TRUE))
}

mat_lit <- function(M) {
    rows <- apply(M, 1, function(r) paste0("{", paste(sprintf("%.17g", r), collapse = ", "), "}"))
    paste0("{", paste(rows, collapse = ", "), "}")
}
str_vec_lit <- function(v) paste0("{", paste(sprintf('"%s"', v), collapse = ", "), "}")

# -------------------------------------------------------------------------
# THE THREE FIXTURES. RM_A and RM_B are dev/tests/phase2/
# test-repeated-measures.praat's own literals, reused rather than
# reinvented -- clean/no-ties (A) and sphericity-violated (B). RM_C_EXCL is
# that same suite's RM_C (heavy within-row ties) with subject 3's "c2" cell
# blanked, so the wide door's complete-case filter excludes it -- MEASURED
# below (not assumed) to be non-degenerate once excluded: F = 2.667,
# p = 0.148, GG epsilon pinned to its lower bound 0.5 (k=3 -> 1/(k-1)),
# Friedman chi-square = 4, p = 0.1353.
# -------------------------------------------------------------------------
dsA <- list(name = "dsA_n6k3", M = matrix(c(
    12, 15, 19, 10, 14, 17, 13, 16, 21,
    9, 12, 16, 11, 15, 20, 14, 18, 23), ncol = 3, byrow = TRUE),
    cols = c("c1", "c2", "c3"), exSubj = 0, exCol = 0)

dsB <- list(name = "dsB_n5k4", M = matrix(c(
    2, 8, 3, 30, 3, 9, 5, 10, 4, 11, 4, 50,
    2, 7, 6, 5, 5, 12, 3, 40), ncol = 4, byrow = TRUE),
    cols = c("c1", "c2", "c3", "c4"), exSubj = 0, exCol = 0)

dsC <- list(name = "dsC_n5k3_excl", M = matrix(c(
    5, 5, 8, 7, 7, 7, 3, 6, 6, 4, 4, 9, 6, 6, 6), ncol = 3, byrow = TRUE),
    cols = c("c1", "c2", "c3"), exSubj = 3, exCol = 2)

datasets <- list(dsA, dsB, dsC)
ADJ_METHOD <- "holm"

cat("      v166 R oracle (fixture pre-check, dsC after exclusion, re-derived not assumed):\n")
oracleC <- rm_anova(dsC$M[-dsC$exSubj, ])
ftC <- suppressWarnings(friedman.test(dsC$M[-dsC$exSubj, ]))
cat(sprintf("        F=%.6f p=%.6f gg=%.6f | chi-sq=%.6f p=%.6f\n",
            oracleC$F, oracleC$p, oracleC$gg,
            unname(ftC$statistic), ftC$p.value))

# ===========================================================================
# LEG A + LEG B, ONE PRAAT PROCESS.
# ===========================================================================
outTsv <- file.path(work, "v166_legA.tsv")

legA_lines <- character(0)
for (ds in datasets) {
    legA_lines <- c(legA_lines,
        sprintf('%s_M## = %s', ds$name, mat_lit(ds$M)),
        sprintf('%s_cols$# = %s', ds$name, str_vec_lit(ds$cols)),
        sprintf('@v166_buildWideTable: %s_M##, %s_cols$#, %d, %d',
                ds$name, ds$name, ds$exSubj, ds$exCol),
        sprintf('%s_wide = v166_buildWideTable.tableId', ds$name),
        sprintf('@v166_buildLongTable: %s_M##, %s_cols$#, %d, %d',
                ds$name, ds$name, ds$exSubj, ds$exCol),
        sprintf('%s_long = v166_buildLongTable.tableId', ds$name),
        sprintf('@v166_dumpRM: outTsv$, "%s", "wide", %s_wide, "wide", "", %s_cols$#, "", "", "%s"',
                ds$name, ds$name, ds$name, ADJ_METHOD),
        sprintf('@v166_dumpRM: outTsv$, "%s", "long", %s_long, "long", "subject", emptyVec$#, "condition", "value", "%s"',
                ds$name, ds$name, ADJ_METHOD),
        sprintf('@v166_dumpFriedman: outTsv$, "%s", "wide", %s_wide, "wide", "", %s_cols$#, "", "", "%s"',
                ds$name, ds$name, ds$name, ADJ_METHOD),
        sprintf('@v166_dumpFriedman: outTsv$, "%s", "long", %s_long, "long", "subject", emptyVec$#, "condition", "value", "%s"',
                ds$name, ds$name, ADJ_METHOD),
        sprintf('removeObject: %s_wide, %s_long', ds$name, ds$name))
}

# --- LEG B fixtures, appended to the same run -----------------------------
# dropSubj/dropCol and dupSubj/dupCol are chosen on dsA's own matrix and
# column names, reused rather than a fourth fixture invented for this leg
# alone.
dropSubj <- 3L; dropCol <- 2L
dupSubj  <- 2L; dupCol  <- 1L

legB_lines <- c(
    sprintf('@v166_buildLongIncomplete: %s_M##, %s_cols$#, %d, %d',
            dsA$name, dsA$name, dropSubj, dropCol),
    'incompleteId = v166_buildLongIncomplete.tableId',
    'selectObject: incompleteId',
    '@emlRunRepeatedMeasuresAnalysis: incompleteId, "long", "subject", emptyVec$#, "condition", "value", 0, "holm"',
    'appendInfoLine: "INCOMPLETE_ERROR|", emlRunRepeatedMeasuresAnalysis.error$, "|END"',
    'removeObject: incompleteId',
    '',
    sprintf('@v166_buildLongDuplicate: %s_M##, %s_cols$#, %d, %d',
            dsA$name, dsA$name, dupSubj, dupCol),
    'duplicateId = v166_buildLongDuplicate.tableId',
    'selectObject: duplicateId',
    '@emlRunRepeatedMeasuresAnalysis: duplicateId, "long", "subject", emptyVec$#, "condition", "value", 0, "holm"',
    'appendInfoLine: "DUPLICATE_ERROR|", emlRunRepeatedMeasuresAnalysis.error$, "|END"',
    'removeObject: duplicateId')

wrapper <- c(prelude,
    'writeInfoLine: "v166 probe"',
    sprintf('outTsv$ = "%s"', outTsv),
    '@v166_tsvHeader: outTsv$',
    'emptyVec$# = empty$# (0)',
    '',
    legA_lines,
    '',
    legB_lines,
    '',
    'appendInfoLine: "V166_DONE"')
wrapper_path <- file.path(work, "v166-wrapper.praat")
writeLines(wrapper, wrapper_path)

out <- drive(wrapper_path)
ran <- any(grepl("^V166_DONE$", out)) && !any(grepl("^Error", out))
check_true(V, "the combined Leg A/Leg B probe ran to completion with no Praat error", ran)

if (!ran) {
    cat("      v166 probe output:\n      ",
        paste(utils::tail(out, 40), collapse = "\n      "), "\n", sep = "")
} else {

# ===========================================================================
# LEG A -- parse the TSV, assert wide == long, field by field, dataset by
# dataset.
# ===========================================================================
ok_tsv <- file.exists(outTsv)
check_true(V, sprintf("the field-dump TSV was written (%s)", outTsv), ok_tsv)

if (ok_tsv) {
    raw <- readLines(outTsv, warn = FALSE)
    parts <- strsplit(raw[-1], "\t", fixed = TRUE)
    parts <- lapply(parts, function(p) { length(p) <- 5; ifelse(is.na(p), "", p) })
    m <- do.call(rbind, parts)
    tsv <- data.frame(dataset = m[, 1], proc = m[, 2], path = m[, 3],
                      field = m[, 4], value = m[, 5], stringsAsFactors = FALSE)

    get_field <- function(dataset, proc, path, field) {
        r <- tsv[tsv$dataset == dataset & tsv$proc == proc & tsv$path == path &
                 tsv$field == field, "value"]
        if (!length(r)) NA_character_ else r[1]
    }
    has_pair_fields <- function(dataset, proc, path) {
        n <- suppressWarnings(as.integer(get_field(dataset, proc, path, "nPairs")))
        if (is.na(n) || n < 1) return(character(0))
        as.vector(outer(c("pairKey_", "rawP_", "adjP_"), seq_len(n), paste0))
    }

    RM_FIELDS <- c("n", "k", "nExcluded", "fStat", "dfCond", "dfErr", "p",
                   "ggEpsilon", "pGG", "ssCond", "ssErr", "warning")
    FR_FIELDS <- c("n", "k", "nExcluded", "chiSq", "df", "p", "kendallsW", "warning")

    for (ds in datasets) {
        for (proc in c("rm", "friedman")) {
            errW <- get_field(ds$name, proc, "wide", "error")
            errL <- get_field(ds$name, proc, "long", "error")
            check_true(V, sprintf("[%s/%s] wide door ran with no refusal (error empty)", ds$name, proc),
                      identical(errW, ""))
            check_true(V, sprintf("[%s/%s] long door ran with no refusal (error empty)", ds$name, proc),
                      identical(errL, ""))

            if (identical(errW, "") && identical(errL, "")) {
                flds <- if (proc == "rm") RM_FIELDS else FR_FIELDS
                for (f in flds) {
                    vw <- get_field(ds$name, proc, "wide", f)
                    vl <- get_field(ds$name, proc, "long", f)
                    check_true(V, sprintf("[%s/%s] %s: wide and long are BIT-IDENTICAL (wide=%s, long=%s)",
                                          ds$name, proc, f, shQuote(vw), shQuote(vl)),
                              !is.na(vw) && !is.na(vl) && identical(vw, vl))
                }

                # -- post-hoc: confirm the SAME pair sits at slot i on both
                # doors before comparing its raw/adjusted p, rather than
                # assuming column order survived the reshape.
                pairFields <- has_pair_fields(ds$name, proc, "wide")
                pairFieldsL <- has_pair_fields(ds$name, proc, "long")
                check_true(V, sprintf("[%s/%s] wide and long report the same nPairs", ds$name, proc),
                          identical(get_field(ds$name, proc, "wide", "nPairs"),
                                    get_field(ds$name, proc, "long", "nPairs")))
                keyFields <- grep("^pairKey_", pairFields, value = TRUE)
                for (kf in keyFields) {
                    kw <- get_field(ds$name, proc, "wide", kf)
                    kl <- get_field(ds$name, proc, "long", kf)
                    check_true(V, sprintf("[%s/%s] %s: wide and long agree on which pair occupies this slot (wide=%s, long=%s)",
                                          ds$name, proc, kf, shQuote(kw), shQuote(kl)),
                              !is.na(kw) && identical(kw, kl))
                    i <- sub("^pairKey_", "", kf)
                    for (pf in c(paste0("rawP_", i), paste0("adjP_", i))) {
                        pw <- get_field(ds$name, proc, "wide", pf)
                        pl <- get_field(ds$name, proc, "long", pf)
                        check_true(V, sprintf("[%s/%s] %s (pair %s): wide and long are BIT-IDENTICAL (wide=%s, long=%s)",
                                              ds$name, proc, pf, kw, shQuote(pw), shQuote(pl)),
                                  !is.na(pw) && !is.na(pl) && identical(pw, pl))
                    }
                }
            }
        }
    }

    # -----------------------------------------------------------------
    # LEG C -- R-oracle, belt-and-suspenders on top of Leg A. Reads dsA's
    # already-captured LONG-door numbers (no second Praat drive) and checks
    # them against base R's aov()/Error() and friedman.test(), the same two
    # independent oracles v03/v04 already trust on the wide door.
    # -----------------------------------------------------------------
    num_or_na <- function(s) if (is.na(s) || identical(s, "--undefined--")) NA_real_ else suppressWarnings(as.numeric(s))

    longF <- num_or_na(get_field(dsA$name, "rm", "long", "fStat"))
    longP <- num_or_na(get_field(dsA$name, "rm", "long", "p"))
    longChi <- num_or_na(get_field(dsA$name, "friedman", "long", "chiSq"))
    longFrP <- num_or_na(get_field(dsA$name, "friedman", "long", "p"))

    long <- data.frame(
        subject   = factor(rep(seq_len(nrow(dsA$M)), times = ncol(dsA$M))),
        condition = factor(rep(dsA$cols, each = nrow(dsA$M)), levels = dsA$cols),
        value     = as.vector(dsA$M))
    a <- summary(aov(value ~ condition + Error(subject / condition), data = long))
    f_aov <- a[["Error: subject:condition"]][[1]][["F value"]][1]
    p_aov <- a[["Error: subject:condition"]][[1]][["Pr(>F)"]][1]
    ft <- friedman.test(dsA$M)

    check_true(V, "[Leg C] the long door's fStat and p were captured in Leg A", !is.na(longF) && !is.na(longP))
    check(V, "[Leg C] long-door RM fStat vs base R aov()", longF, f_aov, tol = std_tol(f_aov))
    check(V, "[Leg C] long-door RM p vs base R aov()", longP, p_aov, tol = std_tol(p_aov))
    check_true(V, "[Leg C] the long door's Friedman chi-square and p were captured in Leg A",
              !is.na(longChi) && !is.na(longFrP))
    check(V, "[Leg C] long-door Friedman chi-square vs R friedman.test()",
          longChi, unname(ft$statistic), tol = std_tol(unname(ft$statistic)))
    check(V, "[Leg C] long-door Friedman p vs R friedman.test()",
          longFrP, unname(ft$p.value), tol = std_tol(unname(ft$p.value)))
}

# ===========================================================================
# LEG B -- the two long-only refusals, and the self-test that this file's
# exact-wording assertions are falsifiable.
# ===========================================================================
grab <- function(tag) {
    ln <- grep(paste0("^", tag, "\\|"), out, value = TRUE)
    if (!length(ln)) return(NA_character_)
    m <- regmatches(ln[1], regexec(paste0("^", tag, "\\|(.*)\\|END$"), ln[1]))
    if (length(m[[1]]) == 2) m[[1]][2] else NA_character_
}
incompleteErr <- grab("INCOMPLETE_ERROR")
duplicateErr  <- grab("DUPLICATE_ERROR")

check_true(V, "[Leg B] the INCOMPLETE-cell probe printed a result line", !is.na(incompleteErr))
check_true(V, "[Leg B] the DUPLICATE-cell probe printed a result line", !is.na(duplicateErr))

# Subject labels are the RAW text Get value: returns for a Table cell set by
# Set numeric value: -- "3", not "3.0" (measured against Praat 6.6.30, see
# rm_wide_long_probe.praat's header). Condition labels are dsA$cols verbatim.
dropSubjLabel <- as.character(dropSubj)
dropCondLabel <- dsA$cols[dropCol]
dupSubjLabel  <- as.character(dupSubj)
dupCondLabel  <- dsA$cols[dupCol]

# Wording read verbatim from eml_rmResolveMatrix (stats/eml-analysis.praat,
# "pin 3: every subject x condition cell present exactly once"), not guessed.
expectIncomplete <- paste0(
    'No observation for subject "', dropSubjLabel, '" in condition "',
    dropCondLabel, '". A repeated-measures test needs every subject measured ',
    'in every condition.')
expectDuplicate <- paste0(
    'Subject "', dupSubjLabel, '" appears 2 times in condition "',
    dupCondLabel, '". Each subject must appear once per condition; nothing ',
    'is averaged for you.')

if (!is.na(incompleteErr)) {
    check_true(V, "[Leg B] INCOMPLETE cell: the long door refuses with eml_rmResolveMatrix's exact wording",
              identical(incompleteErr, expectIncomplete))
}
if (!is.na(duplicateErr)) {
    check_true(V, "[Leg B] DUPLICATE cell: the long door refuses with eml_rmResolveMatrix's exact wording",
              identical(duplicateErr, expectDuplicate))
}

# -------------------------------------------------------------------------
# SELF-TEST, in the v163/v145/v158 EML_*_RED convention: a deliberately
# WRONG expected refusal text (plausible, but not what the source says) is
# asserted to DIFFER from the real one -- passes today, and proves the exact
# check just above is falsifiable rather than a tautology that would pass no
# matter what the plugin printed. Setting EML_V166_RED=1 flips the SAME
# comparison to "the wrong text matches", which is expected to FAIL and is
# not part of the normal green run.
# -------------------------------------------------------------------------
wrongIncomplete <- paste0('Missing observation: subject "', dropSubjLabel,
                          '" has no row for condition "', dropCondLabel, '".')
if (!is.na(incompleteErr)) {
    check_true(V,
        "[self-test] a deliberately WRONG expected INCOMPLETE-cell refusal text differs from the real one -- the exact-wording assertion above is falsifiable, not a tautology",
        !identical(incompleteErr, wrongIncomplete))
    if (nzchar(Sys.getenv("EML_V166_RED", unset = ""))) {
        cat("      EML_V166_RED: asserting the deliberately WRONG refusal text -- EXPECTED to FAIL.\n")
        check_true(V, "[RED] wrong refusal text asserted as if correct (must go red; unset EML_V166_RED for the real suite)",
                  identical(incompleteErr, wrongIncomplete))
    }
}

} # ran
} # canDrive

if (!exists("EML_SUITE")) {
    eml_report("v166 repeated-measures / Friedman: the long path proven equivalent to wide")
    eml_exit()
}
