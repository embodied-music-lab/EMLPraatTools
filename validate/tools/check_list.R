#!/usr/bin/env Rscript
# ============================================================================
# check_list.R -- run_all.R's own list of checks, parsed before anything runs
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS RUNS FIRST, AND SEPARATELY.
#
# The suite's list of validators is a long `c(...)` with a commented line per
# entry. Three times now a comma has landed in the wrong place while an entry
# was being added -- once inside a comment, where it is invisible to the eye
# that put it there. R parses a whole file before it runs any of it, so the
# damage is not "one check is skipped": the file does not parse, NOTHING runs,
# and the run reports an error rather than a verdict.
#
# run_all.R cannot catch that about itself. By the time its own code could
# check anything, R has already refused to parse it. The guard has to be
# outside, and it has to run before the suite -- which is what this file is
# and why CI calls it first.
#
# WHAT IT ASSERTS, in order of how quietly each one fails:
#
#   1. run_all.R parses at all. The loudest failure and the cheapest test.
#   2. The list block parses ON ITS OWN, evaluated in a fresh session. A
#      trailing comma inside it reaches R as "argument N is empty", which is
#      a different error from a syntax error and does not always surface the
#      same way.
#   3. Every entry names a file that exists. A renamed check that stayed in
#      the list takes the suite down at source() time, after a hundred other
#      checks have already printed and a reader has started believing them.
#   4. Every check file in validate/ is IN the list. This is the one that
#      matters most and it is not about commas at all: a validator nobody
#      listed is a validator that never runs, and it will sit there passing
#      in isolation while catching nothing. That is exactly what happened to
#      the figure-geometry check, which was written, green, and unlisted.
#   5. No entry appears twice.
#
#     Rscript validate/tools/check_list.R
# ============================================================================

args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args)) args[1] else "."
runall <- file.path(root, "validate", "run_all.R")

fail <- function(...) {
    cat("check_list: FAIL -- ", ..., "\n", sep = "")
    quit(status = 1)
}

if (!file.exists(runall)) fail("no validate/run_all.R under ", root)

# --- 1. the whole file parses ----------------------------------------------
p <- tryCatch(parse(runall), error = function(e) e)
if (inherits(p, "error")) {
    cat("check_list: FAIL -- validate/run_all.R does not parse.\n")
    cat("  ", conditionMessage(p), "\n", sep = "")
    cat("  Nothing in the suite would have run. This is not a failing check;\n")
    cat("  it is the suite never starting.\n")
    quit(status = 1)
}

src <- readLines(runall, warn = FALSE)

# --- 2. the list block parses on its own -----------------------------------
i <- grep('^\\s*"v[0-9]', src)
if (!length(i)) fail("no validator entries found in run_all.R -- the list ",
                     "moved or was renamed; fix this file rather than ",
                     "trusting its silence")
first <- i[1]
close <- grep("^\\)\\s*$", src)
close <- close[close > first]
if (!length(close)) fail("the list block is never closed")
block <- src[first:(close[1] - 1)]

lst <- tryCatch(eval(parse(text = paste0("c(\n", paste(block, collapse = "\n"),
                                         "\n)"))),
                error = function(e) e)
if (inherits(lst, "error")) {
    cat("check_list: FAIL -- the check list does not evaluate on its own.\n")
    cat("  ", conditionMessage(lst), "\n", sep = "")
    cat("  A comma after the last entry, or a comma that landed inside a\n")
    cat("  comment, reads as an empty argument. The list is then never built\n")
    cat("  and no validator is sourced.\n")
    quit(status = 1)
}

# --- 3, 4, 5. the list and the directory agree ------------------------------
vdir <- file.path(root, "validate")
on_disk <- sort(list.files(vdir, pattern = "^v[0-9]+_.*\\.R$"))
listed <- sort(unique(lst))

dup <- lst[duplicated(lst)]
if (length(dup)) fail("listed twice: ", paste(unique(dup), collapse = ", "))

missing_file <- setdiff(listed, on_disk)
if (length(missing_file))
    fail("listed but not on disk: ", paste(missing_file, collapse = ", "),
         "\n  The suite would abort at source() time, after other checks had ",
         "already printed.")

unlisted <- setdiff(on_disk, listed)
if (length(unlisted)) {
    cat("check_list: FAIL -- on disk but not in the list: ",
        paste(unlisted, collapse = ", "), "\n", sep = "")
    cat("  A check nobody listed never runs. It passes in isolation and\n")
    cat("  catches nothing, which is worse than not existing, because the\n")
    cat("  suite looks like it covers what that file covers.\n")
    quit(status = 1)
}

cat("check_list: PASS -- ", length(listed),
    " checks listed, all present, none duplicated, none unlisted.\n", sep = "")
