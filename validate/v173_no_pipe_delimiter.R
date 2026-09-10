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
# BROADENED, ORDER §10 (revised). Sections 10-11 below widen the check from
# the six §1b fixed points to the full frozen statistical surface: every
# round==kit procedure REGISTRY.tsv names (sources column carries "1") plus
# every private helper/kernel it reaches, walked automatically rather than
# hand-listed, is read for ANY hand-rolled text-to-vector splitter -- not
# only "|", any delimiter -- and required to be either @emlCommaListToVector
# or a Praat built-in. One real one was found this way and fixed:
# @eml_orderedCols (stats/eml-result-writer.praat) hand-split its column-
# vocabulary string on " " with its own index() loop; it now calls
# `splitBy$# (.vocab$, " ")`. Section 11 confirms the one other hand-rolled
# splitter this sweep found -- graphs/eml-graph-procedures.praat:7007's
# @emlLightenColor comma parse -- is out of the round==kit closure (nothing
# in stats/ reaches a graphs/-layer color helper) and is already logged in
# validate/canon/helper_homes_allowlist.tsv; it is deferred to the graphs
# round, not fixed here.
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

# ============================================================================
# 10. THE BROADENED SWEEP (ORDER revised §10). Every round==kit procedure in
#     REGISTRY.tsv -- the sources-column-1 emlRun* entry points, the ones the
#     kit compares against R -- plus every private helper/kernel reached from
#     one of them by an "@Name" call anywhere across
#     plugin_EML_StatsGraphs/stats/*.praat, is read for the fingerprint a
#     hand-rolled text-to-vector splitter actually has: a loop (for/while)
#     that both calls index()/rindex()/index_regex() AND, in that SAME loop,
#     accumulates the result into an indexed array element
#     (".foo$ [.n] = ..." / ".foo# [.n] = ...") -- the
#     @emlCommaListToVector shape, minus the @emlCommaListToVector call. A
#     single index() used once to answer a yes/no or one-way-split question
#     (a decimal point, a "Type name" selected$() parse, a doubled-quote
#     scan, a row-by-row Table cell classification) is not this shape and is
#     not flagged; every one of the false-positive categories that shape
#     produced on this tree was read by hand once, this session, and is
#     accounted for below rather than asserted.
#
#     WHY THE FULL PLUGIN-RELATIVE CLOSURE, NOT A HAND LIST OF FILES. "round"
#     is not yet a REGISTRY.tsv column (065 adds it); until then, round==kit
#     is read the way the order phrases it -- the entry points are the
#     emlRun* doors REGISTRY.tsv's "sources" column marks 1 (the 15 original
#     name-pattern admissions plus @emlRunCleanData, admitted the same way by
#     the 9 Sep data-cleaning ruling) -- and the closure is walked from
#     there, so a NEW private helper introduced next wave is swept
#     automatically instead of waiting for someone to add it to a list here.
# ============================================================================

registry_path <- PLUGIN_FILE("REGISTRY.tsv")
registry_lines <- read_lines_or_stop(registry_path)
reg_data <- registry_lines[!grepl("^#", registry_lines) & nzchar(registry_lines)]
reg_data <- reg_data[!grepl("^name\t", reg_data)]
reg_fields <- strsplit(reg_data, "\t", fixed = TRUE)
reg_name <- vapply(reg_fields, function(f) f[1], character(1))
reg_sources <- vapply(reg_fields, function(f) if (length(f) >= 5) f[5] else "", character(1))
kit_entry_names <- unique(reg_name[grepl("(^|,)1(,|$)", reg_sources)])
check_true(V,
    paste0("REGISTRY.tsv names at least 14 round==kit (sources column carries \"1\") entry points (found ",
           length(kit_entry_names), ")"),
    length(kit_entry_names) >= 14L)

# A line whose first non-blank character is "#" or ";" is a comment in this
# tree's house style (confirmed against stats/eml-analysis.praat's own
# ";"-led prose blocks); blanked so neither the call-graph walk nor the
# splitter fingerprint below ever reads a name or a shape out of prose.
strip_praat_comment <- function(line) if (grepl("^\\s*[#;]", line)) "" else line

stats_files <- Sys.glob(PLUGIN_FILE("stats", "*.praat"))
proc_at <- new.env(parent = emptyenv())     # name -> list(file, start, end)
file_lines <- new.env(parent = emptyenv())  # file -> character vector
for (fp in stats_files) {
    fl <- read_lines_or_stop(fp)
    assign(fp, fl, envir = file_lines)
    starts <- grep("^procedure\\s+[A-Za-z_][A-Za-z0-9_]*", fl)
    for (s in starts) {
        nm <- sub("^procedure\\s+([A-Za-z_][A-Za-z0-9_]*).*$", "\\1", fl[s])
        rel_e <- which(grepl("^endproc", fl[(s + 1L):length(fl)]))
        if (length(rel_e) == 0L) next
        assign(nm, list(file = fp, start = s, end = s + rel_e[1]), envir = proc_at)
    }
}
get_body <- function(nm) {
    if (!exists(nm, envir = proc_at, inherits = FALSE)) return(NULL)
    info <- get(nm, envir = proc_at, inherits = FALSE)
    fl <- get(info$file, envir = file_lines, inherits = FALSE)
    vapply(fl[info$start:info$end], strip_praat_comment, character(1), USE.NAMES = FALSE)
}
callees_of <- function(body) {
    m <- gregexpr("@([A-Za-z_][A-Za-z0-9_]*)", body)
    unique(sub("^@", "", unlist(regmatches(body, m))))
}

# BFS from the round==kit entry points over the stats/ call graph.
visited <- character(0)
queue <- kit_entry_names
while (length(queue) > 0L) {
    nm <- queue[1]; queue <- queue[-1]
    if (nm %in% visited) next
    visited <- c(visited, nm)
    body <- get_body(nm)
    if (is.null(body)) next
    for (callee in callees_of(body)) {
        if (!(callee %in% visited) && exists(callee, envir = proc_at, inherits = FALSE)) {
            queue <- c(queue, callee)
        }
    }
}
check_true(V,
    paste0("the round==kit call-graph closure over stats/*.praat reaches more than 100 procedures (found ",
           length(visited), ")"),
    length(visited) > 100L)

# has_splitter_loop -- TRUE when some (for|while) ... (endfor|endwhile) block
# in .body both calls index()/rindex()/index_regex() and accumulates into an
# indexed array element. Nesting is tracked with a keyword stack (for/while
# push, matching endfor/endwhile pop); if/endif is not tracked, which only
# widens a loop's own range to include its own if-branches -- exactly where a
# real splitter's token consumption lives.
has_splitter_loop <- function(body) {
    starts <- integer(0); kinds <- character(0)
    for (i in seq_along(body)) {
        if (grepl("^\\s*for\\b", body[i])) {
            starts <- c(starts, i); kinds <- c(kinds, "for")
        } else if (grepl("^\\s*while\\b", body[i])) {
            starts <- c(starts, i); kinds <- c(kinds, "while")
        } else if (grepl("^\\s*endfor\\b", body[i]) && length(starts) && kinds[length(kinds)] == "for") {
            s <- starts[length(starts)]
            starts <- starts[-length(starts)]; kinds <- kinds[-length(kinds)]
            block <- body[s:i]
            if (any(grepl("\\b(index|rindex|index_regex)\\s*\\(", block)) &&
                any(grepl('\\.[A-Za-z_]\\w*[$#]\\s*\\[\\s*\\.[A-Za-z_]\\w*\\s*\\]\\s*=[^=]', block)))
                return(TRUE)
        } else if (grepl("^\\s*endwhile\\b", body[i]) && length(starts) && kinds[length(kinds)] == "while") {
            s <- starts[length(starts)]
            starts <- starts[-length(starts)]; kinds <- kinds[-length(kinds)]
            block <- body[s:i]
            if (any(grepl("\\b(index|rindex|index_regex)\\s*\\(", block)) &&
                any(grepl('\\.[A-Za-z_]\\w*[$#]\\s*\\[\\s*\\.[A-Za-z_]\\w*\\s*\\]\\s*=[^=]', block)))
                return(TRUE)
        }
    }
    FALSE
}

# Two named, justified exceptions -- neither is a list-delimiter splitter, so
# @emlCommaListToVector is not their fix (see the two checks that read them
# by name below). Anything else that matches is a regression.
WORD_WRAP_WHITELIST <- c("emlWrapText", "eml_saveReceiptLines")

flagged <- character(0)
for (nm in visited) {
    body <- get_body(nm)
    if (!is.null(body) && has_splitter_loop(body)) flagged <- c(flagged, nm)
}
unexplained <- setdiff(flagged, WORD_WRAP_WHITELIST)
check_true(V,
    paste0("every round==kit-reachable stats/ procedure with a splitter-loop shape is a named, ",
           "justified exception -- flagged: ",
           if (length(flagged)) paste(flagged, collapse = ", ") else "none",
           "; unexplained: ",
           if (length(unexplained)) paste(unexplained, collapse = ", ") else "none"),
    length(unexplained) == 0L)

# eml_orderedCols regression pin. Found by this broadened sweep: the vocab
# string driving tidy/glance/augment column ordering (stats/eml-result-
# writer.praat) was walked by a hand-rolled while/index($, " ") loop,
# accumulating into .name$[.n] -- the exact shape this section detects, on a
# delimiter (a bare space) @emlCommaListToVector does not even use. Fixed in
# this commit to `splitBy$# (.vocab$, " ")`, a Praat built-in. Pinned here by
# name so a future edit that reverts to the hand loop fails this assertion
# immediately.
check_true(V, "eml_orderedCols is reached by the round==kit closure",
    "eml_orderedCols" %in% visited)
oc_body <- get_body("eml_orderedCols")
check_true(V,
    paste0("stats/eml-result-writer.praat's @eml_orderedCols splits .vocab$ with splitBy$# ",
           "(a Praat built-in), not a hand-rolled index() loop"),
    !is.null(oc_body) &&
        any(grepl('splitBy\\$# ?\\(\\.vocab\\$, ?" "\\)', oc_body)) &&
        !any(grepl("\\b(index|rindex|index_regex)\\s*\\(", oc_body)))

# emlWrapText / eml_saveReceiptLines -- read by name, confirming the
# exception still applies rather than trusting it forever. Both build an
# indexed .line$[] array inside a loop that also calls index(), which is why
# the fingerprint above finds them -- and neither is a list-delimiter
# splitter. @emlWrapText greedy-breaks PROSE at a character-width budget
# (Praat has no word-wrap primitive, and @emlCommaListToVector's comma
# convention has nothing to unify with a width-limited line break).
# @eml_saveReceiptLines only separates already-distinct PHYSICAL LINES
# (newline$, not a delimiter choice that could drift out of sync with a
# writer elsewhere) before handing each one to @emlWrapText. Neither turns a
# delimited LIST OF ITEMS into a vector of items to process further; both are
# display formatting, the same kind of exception the header's markdown-table
# and regex-alternation categories already are.
wt_body <- get_body("emlWrapText")
check_true(V,
    paste0("stats/eml-output.praat's @emlWrapText still exists and still wraps prose with its ",
           "own width-scan loop (named exception, not a list-delimiter splitter)"),
    !is.null(wt_body) && has_splitter_loop(wt_body))
src_body <- get_body("eml_saveReceiptLines")
check_true(V,
    paste0("stats/eml-output.praat's @eml_saveReceiptLines still exists and still splits its ",
           "newline-separated input with its own loop (named exception, not a list-delimiter ",
           "splitter)"),
    !is.null(src_body) && has_splitter_loop(src_body))

# ============================================================================
# 11. THE GRAPHS-LAYER COMMA LOOP THIS SWEEP ALSO FOUND, DEFERRED BY NAME.
#     graphs/eml-graph-procedures.praat's @emlLightenColor hand-parses an RGB
#     triple ("{0.3, 0.5, 0.7}") with two index(.., ",")-driven splits at
#     lines 7002 and 7007. It is never reached from the round==kit closure
#     above (nothing in stats/ calls a graphs/-layer color helper), so
#     section 10 never touches it -- the same graphs-round boundary section 8
#     already draws for @emlReshapeSeriesLong/Wide. It is not fixed here: the
#     order (§10) files it for the graphs round by name, and this file does
#     not touch graphs/eml-graph-procedures.praat:7007.
#
#     ALREADY LOGGED, NOT LOGGED AGAIN. Both of @emlLightenColor's index(...,
#     ",") lines (7002 and 7007) already carry a standing-ledger row --
#     validate/canon/helper_homes_allowlist.tsv, "AUDIT_PROCEDURES_2026-09-08
#     section 6 (deferred to the graphs/scripts round)" -- from the same
#     comma-splitter canon @emlCommaListToVector's own helper_homes.tsv
#     pattern row names. This check confirms the two rows are still there
#     rather than adding a third record of the same fact in a second ledger.
# ============================================================================

lightencolor_path <- PLUGIN_FILE("graphs", "eml-graph-procedures.praat")
lightencolor_lines <- read_lines_or_stop(lightencolor_path)
check_true(V,
    "graphs/eml-graph-procedures.praat:7007 is still @emlLightenColor's comma-split line (unchanged; deferred, not fixed, by this order)",
    length(lightencolor_lines) >= 7007L &&
        grepl('\\.comma2 = index \\(\\.rest\\$, ","\\)', lightencolor_lines[7007]))

allowlist_path <- repo_path("validate", "canon", "helper_homes_allowlist.tsv")
allowlist_lines <- read_lines_or_stop(allowlist_path)
ledger_7002 <- grep("^graphs/eml-graph-procedures\\.praat\t7002\t", allowlist_lines)
ledger_7007 <- grep("^graphs/eml-graph-procedures\\.praat\t7007\t", allowlist_lines)
check_true(V,
    "validate/canon/helper_homes_allowlist.tsv already carries the graphs-round deferral for @emlLightenColor's two comma-split lines (7002 and 7007)",
    length(ledger_7002) >= 1L && length(ledger_7007) >= 1L)

if (!exists("EML_SUITE")) {
    eml_report(paste0("v173 no-pipe-delimiter canon -- six §1b fixes stay fixed, and the ",
                       "§10 sweep now covers the round==kit closure (", length(visited),
                       " procedures): one real hand-rolled splitter found and fixed ",
                       "(eml_orderedCols), the graphs-layer comma loop logged for the graphs round"))
    eml_exit()
}
