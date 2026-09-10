# ============================================================================
# v171_missing_value_tokens.R -- one canon, two places, checked (v105 pattern)
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. The missing-value token list -- "na", "n/a", "nan",
# "--undefined--", and the rest -- is stated ONCE in the Praat source, at
# @eml_isMissingToken (stats/eml-extract.praat), per RULING_MISSING_VALUE_
# TOKENS (9 Sep 2026): a non-empty cell whose text is on this list is
# missing, exactly as an empty cell is. The R oracle (walkthrough/kit/
# run_analyses.R) needs the SAME list, for the SAME reason `na.strings`
# exists: `read.csv(..., na.strings = <this list>)` is how R is told a
# token means NA rather than a factor level or a parse failure, and if the
# two lists ever disagreed, R and the plugin would exclude a different set
# of rows from the identical fixture and every downstream quantity would
# differ for a reason invisible to anyone reading either file on its own --
# each one internally consistent, each one passing its own tests.
#
# So the R side does not restate the list: it reads the committed copy,
# validate/canon/missing_tokens.tsv, and THIS file is the only thing that
# checks that copy still says what the Praat procedure says. A change to
# either side with no matching change to the other fails here, not three
# files downstream where the symptom would be a numeric disagreement with
# no visible cause -- exactly the failure v105 exists to catch for the
# pitch-argument canon, hence "the v105 pattern": a canon that has to exist
# in two places, with a text check asserting the two agree, reading canon
# out of the PROCEDURE rather than restating it a third time here.
#
# SOURCE-LEVEL, NOT A RUN. This never launches Praat: the comparison is
# between the literal Praat source and the literal committed TSV.
#
#     Rscript validate/v171_missing_value_tokens.R
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

V <- "v171"

SRC <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-extract.praat")
TSV <- repo_path("validate", "canon", "missing_tokens.tsv")

# ---------------------------------------------------------------------------
# join_continuations -- collapse a Praat "..." continuation onto the line it
# continues, so the multi-line `if .low$ = "na" or ... or .low$ = "undefined"`
# statement in @eml_isMissingToken reads as ONE line, the same reason v105
# joins continuations before scanning a pitch call.
# ---------------------------------------------------------------------------
join_continuations <- function(lines) {
    out <- character(0)
    i <- 1L
    while (i <= length(lines)) {
        cur <- lines[i]
        while (i + 1L <= length(lines) && grepl("^\\s*\\.\\.\\.", lines[i + 1L])) {
            cur <- paste0(sub("\\s+$", "", cur), " ",
                          sub("^\\s*\\.\\.\\.\\s*", "", lines[i + 1L]))
            i <- i + 1L
        }
        out <- c(out, cur)
        i <- i + 1L
    }
    out
}

# ---------------------------------------------------------------------------
# Extract the canon: the body of @eml_isMissingToken, between its
# "procedure eml_isMissingToken" line and its "endproc", then every literal
# on the RIGHT of a ".low$ = " comparison inside it.
# ---------------------------------------------------------------------------
if (!file.exists(SRC)) {
    stop("v171: source not found: ", SRC)
}
src_lines <- readLines(SRC, warn = FALSE)
start <- grep("^procedure eml_isMissingToken:", src_lines)
if (length(start) != 1L) {
    stop("v171: expected exactly one @eml_isMissingToken definition, found ",
         length(start))
}
end_rel <- which(grepl("^endproc", src_lines[start:length(src_lines)]))[1]
if (is.na(end_rel)) stop("v171: no endproc found for @eml_isMissingToken")
body <- src_lines[start:(start + end_rel - 1L)]
body <- join_continuations(body)

token_lines <- grep('\\.low\\$\\s*=\\s*"', body, value = TRUE)
if (length(token_lines) == 0L) {
    stop("v171: found no `.low$ = \"...\"` comparisons in @eml_isMissingToken")
}
# Each matched line can carry more than one token (the "or"-joined
# continuation lines do). Pull every quoted literal that follows ".low$ =".
matches <- gregexpr('\\.low\\$\\s*=\\s*"([^"]*)"', token_lines)
extracted <- regmatches(token_lines, matches)
source_tokens <- unlist(lapply(extracted, function(v) {
    sub('.*"([^"]*)"$', "\\1", v)
}))
source_tokens <- unique(source_tokens)

# ---------------------------------------------------------------------------
# The committed copy.
# ---------------------------------------------------------------------------
if (!file.exists(TSV)) {
    stop("v171: canon copy not found: ", TSV)
}
tsv <- read.delim(TSV, stringsAsFactors = FALSE, colClasses = "character")
if (!"token" %in% names(tsv)) {
    stop("v171: ", TSV, " has no `token` column")
}
tsv_tokens <- tsv$token

# ---------------------------------------------------------------------------
# The checks: both directions, by name, so a token added to one side and
# not the other names exactly which one and which token.
# ---------------------------------------------------------------------------
check_true(V, "the source list is non-empty", length(source_tokens) >= 10)
check_true(V, "the TSV list is non-empty", length(tsv_tokens) >= 10)

missing_in_tsv <- setdiff(source_tokens, tsv_tokens)
extra_in_tsv <- setdiff(tsv_tokens, source_tokens)

check_true(V,
    paste0("every @eml_isMissingToken literal is in the committed TSV",
           if (length(missing_in_tsv)) paste0(" (missing: ",
               paste(sprintf('"%s"', missing_in_tsv), collapse = ", "), ")")
           else ""),
    length(missing_in_tsv) == 0L)

check_true(V,
    paste0("the committed TSV carries no token @eml_isMissingToken does not",
           if (length(extra_in_tsv)) paste0(" (extra: ",
               paste(sprintf('"%s"', extra_in_tsv), collapse = ", "), ")")
           else ""),
    length(extra_in_tsv) == 0L)

# The two 9 Sep 2026 additions, named explicitly so a revert of either one
# (rather than a typo in an unrelated token) is unambiguous in the failure.
check_true(V, "\"--undefined--\" is on both lists",
    "--undefined--" %in% source_tokens && "--undefined--" %in% tsv_tokens)
check_true(V, "\"undefined\" is on both lists",
    "undefined" %in% source_tokens && "undefined" %in% tsv_tokens)

if (!exists("EML_SUITE")) {
    eml_report("v171 missing-value token canon -- Praat source vs the committed R-side copy")
    eml_exit()
}
