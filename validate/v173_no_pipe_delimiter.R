# ============================================================================
# v173_no_pipe_delimiter.R -- the pipe delimiter is gone from the frozen
#                              statistical surface, and stays gone (v105
#                              pattern)
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS CHECKS. ORDER_PIPE_DELIMITER_REMOVAL_2026-09-10 (§1b) removed
# every use of "|" as a list delimiter on the frozen statistical surface: the
# reliability item list (run_analyses.R, RUN_ME_FIRST.praat/RUN_KIT_LINUX.
# praat, matrix.tsv col_a), the repeated-measures/Friedman col_a split in
# compare.R (in lockstep with run_analyses.R's parseConditions, closing the
# reader/comparator disagreement commit 754f5c72 left open), @eml_kwScan's
# keyword lists (now house-syntax string vectors, declared once by
# @emlColumnRoleKeywordDefaults), and the "|" splitter at the top of
# @emlErrorDialog (.remedy$ is prose on the public contract; @emlErrorDialog
# prints it as it stands). @emlReshapeSeriesLong/@emlReshapeSeriesWide were
# confirmed to already carry no splitter (their signatures already take
# .cols$#/.levels$#).
#
# This file is the thing that would notice a regression -- a "|" delimiter
# creeping back into any of those six places -- for the same reason v105
# exists for the pitch-argument canon and v171 for the missing-value token
# canon: the fix lives in six different files in two languages, nothing
# forces them to agree tomorrow, and the failure mode is silent (a plugin
# that still runs, still returns a number, just reads or joins a list
# wrong).
#
# WHY ANCHORED, NOT A WHOLE-TREE GREP. A bare `grep -n '|'` over these files
# is almost pure noise: regex alternation in compare.R's own DECLARED
# clauses and quantity patterns ("^(posthoc_.*_padj|...)$"), statistical
# absolute-value notation printed in report text ("|d|", "|r|", "Pr(>|t|)"),
# a human-readable "%.4f | Hedges' g=%.4f" report line, and a markdown table
# row builder all contain a literal "|" that has nothing to do with the
# list-delimiter canon this order retired. So, exactly as v171 reads canon
# out of @eml_isMissingToken rather than scanning the whole file, this file
# reads each of the six fixed places OUT OF THE NAMED PROCEDURE OR FUNCTION
# BODY, by name, and checks only inside that anchor. A "|" anywhere else in
# these files -- regex, absolute-value bars, report punctuation -- is never
# in scope and never flagged.
#
# THE ONE EXPLICIT EXCLUSION, STATED ONCE. The mixed-model formula syntax
# "(term | group)" / "(term || group)" in stats/eml-lmm.praat is kept by
# standing rule and this file never reads that file's list-parsing code --
# it only confirms (v105-style positive control) that the formula parser's
# own pipe-index call is still there, unmodified, so a future "cleanup" that
# quietly breaks it would be caught by a DIFFERENT failure (the parser no
# longer working), not silently absorbed into this file's green.
#
# THE OTHER EXPLICIT EXCLUSION. graphs/eml-graph-procedures.praat carries
# unit and acronym label maps (lines 3423-3524) that ALSO use "|" as a
# delimiter -- ORDER_PIPE_DELIMITER_REMOVAL_2026-09-10, §1b, sends those to
# the graphs round by name, not this wave. This file never reads that range;
# it reads only @emlReshapeSeriesLong and @emlReshapeSeriesWide by name; the
# two graphs-round frozen-set members §1b actually names.
#
# SOURCE-LEVEL, NOT A RUN. This never launches Praat.
#
#     Rscript validate/v173_no_pipe_delimiter.R
#
# Base R only. No packages.
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

V <- "v173"

PLUGIN_FILE <- function(...) repo_path("plugin_EML_StatsGraphs", ...)
KIT_FILE    <- function(...) repo_path("walkthrough", "kit", ...)

read_lines_or_stop <- function(path) {
    if (!file.exists(path)) stop("v173: source not found: ", path)
    readLines(path, warn = FALSE)
}

# ---------------------------------------------------------------------------
# extract_block -- lines[s:e], where s is the ONE line matching start_re and
# e is the first line AT OR AFTER s matching end_re (inclusive of e unless
# exclude_end is TRUE, in which case e is the line just before the end_re
# match -- for a "next sibling branch" marker that is not itself part of the
# block). Same anchor-by-name approach v171 uses for @eml_isMissingToken: the
# canon is read out of the named procedure, never out of the whole file.
# ---------------------------------------------------------------------------
extract_block <- function(lines, start_re, end_re, label, file, exclude_end = FALSE) {
    s <- grep(start_re, lines)
    if (length(s) != 1L) {
        stop("v173: expected exactly one `", label, "` in ", file,
             ", found ", length(s))
    }
    rel_e <- which(grepl(end_re, lines[(s + 1L):length(lines)]))
    if (length(rel_e) == 0L) {
        stop("v173: no closing marker for `", label, "` in ", file)
    }
    e <- s + rel_e[1]
    if (exclude_end) e <- e - 1L
    lines[s:e]
}

# extract_blocks -- same anchor as extract_block, but for a name defined more
# than once in the same file (run_analyses.R carries two identical copies of
# parseConditions()/buildConditionMatrix(), pre-existing and unrelated to
# §1b): returns every block found rather than requiring exactly one, so a
# regression in ANY copy is still caught.
extract_blocks <- function(lines, start_re, end_re, label, file) {
    starts <- grep(start_re, lines)
    if (length(starts) == 0L) {
        stop("v173: expected at least one `", label, "` in ", file, ", found 0")
    }
    lapply(starts, function(s) {
        rel_e <- which(grepl(end_re, lines[(s + 1L):length(lines)]))
        if (length(rel_e) == 0L) {
            stop("v173: no closing marker for `", label, "` at line ", s, " in ", file)
        }
        e <- s + rel_e[1]
        lines[s:e]
    })
}

has_pipe_delim_call <- function(block) {
    # The exact shape of every bug this order retired: a lone "|" string
    # literal handed to a splitting/finding call (Praat's index/rindex/
    # index_regex, R's strsplit) -- @emlCommaListToVector's own job now.
    any(grepl('\\b(index|rindex|index_regex)\\s*\\([^)]*"\\|"', block)) ||
        any(grepl('\\bstrsplit\\s*\\([^,]*,\\s*"\\|"', block))
}

has_compound_pipe_literal <- function(block) {
    # A single quoted string that itself packs more than one alternative
    # separated by "|" -- "group|condition|category", the old two-item
    # remedy join, and so on. Word/underscore/paren/space characters
    # immediately either side of the pipe, inside the SAME quoted literal,
    # is the signature; a lone "|" concatenated in from elsewhere (a cache
    # key, a box-drawing character swap) never matches this.
    any(grepl('"[^"\n]*[A-Za-z0-9_][^"\n]*\\|[^"\n]*[A-Za-z0-9_][^"\n]*"', block))
}

# ============================================================================
# 1. matrix.tsv -- col_a (5th tab field) carries no "|" on any data row.
# ============================================================================
mtx_path <- KIT_FILE("matrix.tsv")
mtx_lines <- read_lines_or_stop(mtx_path)
mtx_data <- mtx_lines[!grepl("^#", mtx_lines) & nzchar(mtx_lines)]
# Drop the header row itself (col_a is a literal column name there, not data).
mtx_data <- mtx_data[!grepl("^cell_id\t", mtx_data)]
mtx_fields <- strsplit(mtx_data, "\t", fixed = TRUE)
col_a <- vapply(mtx_fields, function(f) if (length(f) >= 5) f[5] else "", character(1))
bad_rows <- mtx_fields[nzchar(col_a) & grepl("|", col_a, fixed = TRUE)]
bad_ids <- vapply(mtx_fields[nzchar(col_a) & grepl("|", col_a, fixed = TRUE)],
                   function(f) f[1], character(1))
check_true(V,
    paste0("matrix.tsv col_a carries no \"|\" delimiter",
           if (length(bad_ids)) paste0(" (cells: ",
               paste(bad_ids, collapse = ", "), ")") else ""),
    length(bad_ids) == 0L)

# ============================================================================
# 2. run_analyses.R -- parseConditions() splits col_a on comma, and
#    process_reliability_analysis() calls it (not a fixed "|" strsplit).
# ============================================================================
ra_path <- KIT_FILE("run_analyses.R")
ra_lines <- read_lines_or_stop(ra_path)

pc_blocks <- extract_blocks(ra_lines, "^parseConditions <- function", "^\\}$",
                             "parseConditions", ra_path)
check_true(V,
    paste0("run_analyses.R parseConditions() splits col_a on comma (",
           length(pc_blocks), " definition(s) checked)"),
    all(vapply(pc_blocks, function(b) any(grepl('strsplit\\(colspec,\\s*","\\)', b)),
               logical(1))))
check_true(V,
    paste0("run_analyses.R parseConditions() contains no \"|\" split (",
           length(pc_blocks), " definition(s) checked)"),
    all(vapply(pc_blocks, function(b) !any(grepl('strsplit\\(colspec,\\s*"\\|"', b)),
               logical(1))))

pr_block <- extract_block(ra_lines, "^process_reliability_analysis <- function",
                           "^\\}$", "process_reliability_analysis", ra_path)
check_true(V,
    "run_analyses.R process_reliability_analysis() reads col_a through parseConditions()",
    any(grepl('items <- parseConditions\\(row\\$col_a\\)', pr_block)))
check_true(V,
    "run_analyses.R process_reliability_analysis() contains no \"|\" split of col_a",
    !any(grepl('strsplit\\(row\\$col_a,\\s*"\\|"', pr_block)))

# ============================================================================
# 3. compare.R -- indexSet()'s level/pair branch splits col_a on comma, in
#    lockstep with run_analyses.R's parseConditions (§1b closes the
#    reader/comparator disagreement commit 754f5c72 left open).
# ============================================================================
cmp_path <- KIT_FILE("compare.R")
cmp_lines <- read_lines_or_stop(cmp_path)
idx_block <- extract_block(cmp_lines, "^indexSet <- function", "^\\}$",
                            "indexSet", cmp_path)
check_true(V, "compare.R indexSet() splits col_a on comma",
    any(grepl('strsplit\\(cell\\$col_a,\\s*","', idx_block)))
check_true(V, "compare.R indexSet() contains no \"|\" split of col_a",
    !any(grepl('strsplit\\(cell\\$col_a,\\s*"\\|"', idx_block)))

# ============================================================================
# 4. RUN_ME_FIRST.praat -- the reliability branch routes col_a through
#    @emlCommaListToVector, the one shared bridge, same as the RM/Friedman
#    branch just above it; no hand-rolled pipe walk remains.
# ============================================================================
kit_path <- KIT_FILE("RUN_ME_FIRST.praat")
kit_lines <- read_lines_or_stop(kit_path)
rel_block <- extract_block(kit_lines,
    '^\\s*elsif \\.proc\\$ = "emlRunReliabilityAnalysis"',
    '^\\s*elsif \\.proc\\$ = "emlRunCategoricalAnalysis"',
    "the emlRunReliabilityAnalysis branch", kit_path, exclude_end = TRUE)
check_true(V,
    "RUN_ME_FIRST.praat's reliability branch calls @emlCommaListToVector on col_a",
    any(grepl("@emlCommaListToVector: \\.colA\\$", rel_block)))
check_true(V,
    "RUN_ME_FIRST.praat's reliability branch has no \"|\" delimiter",
    !any(grepl("|", rel_block, fixed = TRUE)))

# The generated Linux mirror (walkthrough/kit/RUN_KIT_LINUX.praat, gitignored
# per walkthrough/kit/.gitignore -- regenerated from RUN_ME_FIRST.praat by
# `sed 's|~/Library/Preferences/Praat Prefs/|~/.praat-dir/|'`) is not a
# committed source and is not read here for the same reason no check reads
# any other gitignored, regenerated artifact: it carries nothing that is not
# already checked on RUN_ME_FIRST.praat.

# ============================================================================
# 5. stats/eml-extract.praat -- @eml_kwScan takes a keyword VECTOR (never a
#    delimited string) and has nothing left to split; its keyword lists are
#    declared once, as house-syntax string vectors, by
#    @emlColumnRoleKeywordDefaults; @emlGuessColumnRoles carries no
#    compound "|"-joined literal anywhere in its body.
# ============================================================================
ext_path <- PLUGIN_FILE("stats", "eml-extract.praat")
ext_lines <- read_lines_or_stop(ext_path)

check_true(V,
    "eml-extract.praat's @eml_kwScan signature takes a keyword string VECTOR",
    any(grepl('^procedure eml_kwScan: \\.colName\\$, \\.kwList\\$#$', ext_lines)))

kw_block <- extract_block(ext_lines, "^procedure eml_kwScan:", "^endproc",
                           "eml_kwScan", ext_path)
check_true(V, "eml-extract.praat's @eml_kwScan body has no pipe-delimiter split call",
    !has_pipe_delim_call(kw_block))
check_true(V, "eml-extract.praat's @eml_kwScan body has no compound \"|\"-joined literal",
    !has_compound_pipe_literal(kw_block))

defaults_block <- extract_block(ext_lines,
    "^procedure emlColumnRoleKeywordDefaults$", "^endproc",
    "emlColumnRoleKeywordDefaults", ext_path)
n_vectors <- length(grep('\\$# = \\{', defaults_block))
check_true(V,
    paste0("eml-extract.praat's @emlColumnRoleKeywordDefaults declares the keyword ",
           "lists as house-syntax vectors (found ", n_vectors, ")"),
    n_vectors >= 10L)
check_true(V,
    "eml-extract.praat's @emlColumnRoleKeywordDefaults has no \"|\"-delimited string",
    !any(grepl("|", defaults_block, fixed = TRUE)))

gcr_block <- extract_block(ext_lines, "^procedure emlGuessColumnRoles:", "^endproc",
                            "emlGuessColumnRoles", ext_path)
check_true(V,
    "eml-extract.praat's @emlGuessColumnRoles has no compound \"|\"-joined literal",
    !has_compound_pipe_literal(gcr_block))
check_true(V,
    "eml-extract.praat's @emlGuessColumnRoles calls @eml_kwScan with a keyword vector, never a literal string",
    !any(grepl('@eml_kwScan: \\.cn\\$, "', gcr_block)))

# ============================================================================
# 6. stats/eml-output.praat -- @emlErrorDialog prints .remedy$ as prose, with
#    no "|" splitter left at its top.
# ============================================================================
out_path <- PLUGIN_FILE("stats", "eml-output.praat")
out_lines <- read_lines_or_stop(out_path)
dlg_block <- extract_block(out_lines, "^procedure emlErrorDialog:", "^endproc",
                            "emlErrorDialog", out_path)
check_true(V, "eml-output.praat's @emlErrorDialog has no pipe-delimiter split call",
    !has_pipe_delim_call(dlg_block))
check_true(V,
    "eml-output.praat's @emlErrorDialog carries no .nRemedy/.remLine$ splitter state",
    !any(grepl("\\.nRemedy|\\.remLine\\$", dlg_block)))

# ============================================================================
# 7. stats/eml-analysis.praat -- no door assigns .remedy$ a literal
#    containing "|"; .remedy$ is prose everywhere on the public contract.
# ============================================================================
ana_path <- PLUGIN_FILE("stats", "eml-analysis.praat")
ana_lines <- read_lines_or_stop(ana_path)
bad_remedy <- grep('\\.remedy\\$\\s*=\\s*"[^"]*\\|[^"]*"', ana_lines, value = TRUE)
check_true(V,
    paste0("eml-analysis.praat assigns no .remedy$ literal containing \"|\"",
           if (length(bad_remedy)) paste0(" (", length(bad_remedy), " found)") else ""),
    length(bad_remedy) == 0L)

# ============================================================================
# 8. graphs/eml-graph-procedures.praat -- the two graphs-round frozen-set
#    members (§1b names them explicitly) carry no splitter. The unit/acronym
#    label maps at lines 3423-3524 are OUT of this wave by the same order
#    text and are never read here.
# ============================================================================
grp_path <- PLUGIN_FILE("graphs", "eml-graph-procedures.praat")
grp_lines <- read_lines_or_stop(grp_path)
long_block <- extract_block(grp_lines, "^procedure emlReshapeSeriesLong:", "^endproc",
                             "emlReshapeSeriesLong", grp_path)
wide_block <- extract_block(grp_lines, "^procedure emlReshapeSeriesWide:", "^endproc",
                             "emlReshapeSeriesWide", grp_path)
check_true(V, "@emlReshapeSeriesLong carries no \"|\" anywhere in its body",
    !any(grepl("|", long_block, fixed = TRUE)))
check_true(V, "@emlReshapeSeriesWide carries no \"|\" anywhere in its body",
    !any(grepl("|", wide_block, fixed = TRUE)))

# ============================================================================
# 9. Positive control -- the ONE thing this order keeps. stats/eml-lmm.praat
#    is never read for list-splitting canon above; this only confirms the
#    mixed-model formula parser's own pipe-index call is still there,
#    unmodified, so this file's green is never mistaken for "eml-lmm.praat
#    was swept too".
# ============================================================================
lmm_path <- PLUGIN_FILE("stats", "eml-lmm.praat")
lmm_lines <- read_lines_or_stop(lmm_path)
check_true(V,
    "stats/eml-lmm.praat's mixed-model formula parser still reads \"(term | group)\" (kept by standing rule, untouched by §1b)",
    any(grepl('index \\(\\.groupContent\\$, "\\|"\\)', lmm_lines)))

if (!exists("EML_SUITE")) {
    eml_report("v173 no-pipe-delimiter canon -- six §1b fixes, read by name, stay fixed")
    eml_exit()
}
