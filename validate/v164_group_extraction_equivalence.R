#!/usr/bin/env Rscript
# ============================================================================
# v164 -- @eml_getGroupData equivalence probe (pre-rewrite oracle)
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. A rewrite of @eml_getGroupData (plugin_EML_StatsGraphs/
# stats/eml-extract.praat) is coming: today it builds a per-group subset
# Table (@eml_groupSubset) before extracting; the rewrite is to walk the
# table once and scatter values into per-group vectors, with no subset
# Table at all. THIS FILE DOES NOT TEST THE REWRITE -- it captures the
# CURRENT implementation's exact behaviour, on eight adversarial fixtures,
# as a committed oracle (validate/group_extraction_oracle.tsv), and asserts
# that re-running the identical probe against whatever
# plugin_EML_StatsGraphs/stats/eml-extract.praat is on disk RIGHT NOW
# reproduces that oracle exactly. Run again once the rewrite lands (still
# pointed at the same, or a different, EML_PLUGIN_DIR) and any behavioural
# drift -- a different vector, a different group order, a different skip
# count, a different error or remedy string -- fails loudly here, by design.
#
# THE EIGHT FIXTURES (validate/fixtures/group_extraction/
# group_extraction_fixtures.praat), one per adversarial case:
#   gx01  a blank/empty cell in the data column
#   gx02  non-numeric text in the data column
#   gx03  two group labels differing only by leading/trailing whitespace
#   gx04  two group labels differing only by letter case
#   gx05  a group with exactly one row
#   gx06  a table with a single group only
#   gx07  a request for a data column name that does not exist
#   gx08  a factor column whose labels look numeric ("1", "2", "3")
# 16 (fixture, group) cases in total (gx01-gx08 have 2, 2, 2, 2, 2, 1, 2, 3
# groups respectively).
#
# THE PROBE (validate/group_extraction_probe.praat) discovers each
# fixture's groups and their order with the plugin's OWN @emlCountGroups,
# not a reimplementation -- so the whitespace- and case-folding fixtures
# (gx03, gx04) are judged by the plugin's own @eml_normalizeLabel, exactly
# as @eml_getGroupData and @eml_groupSubset judge them internally. Nothing
# in this file or the probe re-derives what counts as "the same label" or
# "a strictly numeric cell" -- see @eml_normalizeLabel and
# @eml_strictNumericColumn in eml-extract.praat.
#
# THE ORACLE FORMAT. validate/group_extraction_oracle.tsv is long-form, one
# row per (fixture, group, field): fixture, group_index, group_label,
# field, value. field is one of vector / group_order / skipped / error /
# note -- see the header comment of group_extraction_probe.praat for exactly
# what each holds and how the vector is formatted.
#
# THE COMPARISON is EXACT, not toleranced: every (fixture, group, field)
# key present in the oracle must be present in the fresh run with the
# IDENTICAL value string, and no key may appear in the fresh run that the
# oracle does not have (an orphan/phantom check in both directions, so a
# fixture or group silently dropped -- or one silently added -- fails here
# too, not just a changed value).
#
#     PRAAT=/usr/local/bin/praat6630 \
#     EML_PLUGIN_DIR=/tmp/eml-repo/plugin_EML_StatsGraphs \
#     Rscript validate/v164_group_extraction_equivalence.R
#
# Requires a Praat at or above the plugin's floor; skips (not fails) below
# it, the same convention v108/v143/v152 use.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v164"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}
source(file.path(repo_path("validate"), "tools", "group_extraction_runner.R"))

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)

praat <- gxr_locate_praat()
pvnum <- gxr_praat_version_num(praat)
canDrive <- pvnum >= 6630

if (!canDrive) {
    cat(paste0("      SKIP: v164 needs Praat >= 6.6.30 to drive the probe;\n",
               "            found ", if (nzchar(praat)) praat else "none", ".\n"))
    check_true(V, sprintf("a Praat at or above the plugin's floor is available (found %s)",
                          if (nzchar(praat)) praat else "none"), FALSE)
} else {

fixtures_praat <- repo_path("validate", "fixtures", "group_extraction",
                            "group_extraction_fixtures.praat")
probe_praat <- repo_path("validate", "group_extraction_probe.praat")
oracle_path <- repo_path("validate", "group_extraction_oracle.tsv")

stopifnot(file.exists(fixtures_praat), file.exists(probe_praat))
ok_oracle <- file.exists(oracle_path)
check_true(V, sprintf("committed oracle exists (%s)", oracle_path), ok_oracle)

if (ok_oracle) {

work <- file.path(tempdir(), "v164")
unlink(work, recursive = TRUE)

res <- gxr_run_probe(plug, praat, fixtures_praat, probe_praat, work)
check_true(V, "the probe ran to completion with no Praat error against the current extractor",
           res$ok)

if (!res$ok) {
    cat("      v164 probe output (current extractor):\n")
    cat(paste("       ", utils::tail(res$lines, 30)), sep = "\n")
} else {

    parse_tsv <- function(lines) {
        # Base R only, and NOT read.delim/strip.white -- a group_label field
        # is deliberately whitespace-significant here (gx03 IS the "differs
        # only by leading/trailing whitespace" fixture), so trimming would
        # silently defeat the exact case this validator exists to hold.
        body <- lines[-1]
        if (!length(body)) {
            return(data.frame(fixture = character(0), group_index = character(0),
                              group_label = character(0), field = character(0),
                              value = character(0), stringsAsFactors = FALSE))
        }
        parts <- strsplit(body, "\t", fixed = TRUE)
        # A trailing empty field (error="" or note="" or vector="") is
        # dropped by strsplit rather than kept as "", so pad every row out
        # to 5 columns before binding.
        parts <- lapply(parts, function(p) { length(p) <- 5; ifelse(is.na(p), "", p) })
        m <- do.call(rbind, parts)
        data.frame(fixture = m[, 1], group_index = m[, 2], group_label = m[, 3],
                  field = m[, 4], value = m[, 5], stringsAsFactors = FALSE)
    }

    oracle_df  <- parse_tsv(readLines(oracle_path, warn = FALSE))
    current_df <- parse_tsv(res$tsv_lines)

    key <- function(df) paste(df$fixture, df$group_index, df$group_label, df$field, sep = "")
    oracle_df$key  <- key(oracle_df)
    current_df$key <- key(current_df)

    check_true(V, sprintf("oracle has 16 (fixture, group) cases x 5 fields = 80 data rows (found %d)",
                          nrow(oracle_df)), nrow(oracle_df) == 80)

    orphan  <- setdiff(oracle_df$key, current_df$key)   # in oracle, missing from current run
    phantom <- setdiff(current_df$key, oracle_df$key)   # in current run, not in oracle

    check_true(V, "every (fixture, group, field) key in the oracle is present in the current run",
              length(orphan) == 0)
    if (length(orphan) > 0) {
        check_true(V, paste("  missing from current run:", paste(utils::head(orphan, 10), collapse = ", ")), FALSE)
    }
    check_true(V, "the current run introduces no (fixture, group, field) key absent from the oracle",
              length(phantom) == 0)
    if (length(phantom) > 0) {
        check_true(V, paste("  unexpected in current run:", paste(utils::head(phantom, 10), collapse = ", ")), FALSE)
    }

    common <- intersect(oracle_df$key, current_df$key)
    ord  <- oracle_df[match(common, oracle_df$key), ]
    curr <- current_df[match(common, current_df$key), ]
    mismatch <- ord$value != curr$value

    n_fixtures <- length(unique(oracle_df$fixture))
    n_cases <- length(unique(paste(oracle_df$fixture, oracle_df$group_index)))
    check_true(V, sprintf("every value for every shared key matches the oracle exactly (%d fixtures, %d fixture/group cases, %d fields checked)",
                          n_fixtures, n_cases, length(common)),
              !any(mismatch))
    if (any(mismatch)) {
        bad <- which(mismatch)
        for (i in utils::head(bad, 15)) {
            check_true(V, sprintf("  [%s / group %s (%s) / %s] oracle=%s  current=%s",
                                  ord$fixture[i], ord$group_index[i], ord$group_label[i], ord$field[i],
                                  shQuote(ord$value[i]), shQuote(curr$value[i])),
                      FALSE)
        }
        if (length(bad) > 15) {
            check_true(V, sprintf("  ... and %d more mismatching field(s)", length(bad) - 15), FALSE)
        }
    }
}

} # ok_oracle
} # canDrive

if (!exists("EML_SUITE")) {
    eml_report("v164 @eml_getGroupData equivalence probe (pre-rewrite oracle)")
    eml_exit()
}
