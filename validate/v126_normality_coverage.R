# ============================================================================
# v126_normality_coverage.R -- an assessment that could not test every group
#                              says so, on every path that can skip one
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR. Punch list 2026-08-25, lane 5, item 5.1. Language batch
# item 13, verbatim. Both call sites that can skip a group too small to test
# (n < 3) were repaired -- the group-mode summary states coverage, and the
# "no group shows a strong departure" generalisation is never printed over a
# group the run never examined -- but nothing in validate/ asserts either
# half, and harness/normality/out/pergroup/p01_groups_grouped.txt sits
# committed and unread by any check. This file is that assertion.
#
# THE POPULATION IS DERIVED, not listed. Both call sites share one idiom --
# the group loop tests `eml_getGroupData.n >= 3` before running Shapiro-Wilk
# on a group, and skips the group otherwise -- so a grep for that literal
# condition finds every place in the shipping tree that CAN produce an
# incomplete assessment, without anyone naming the two files by hand. A
# third site added tomorrow that copies the same n>=3 gate falls into this
# population the day it lands.
#
# TWO MEMBERS TODAY, and they are not siblings running the same code: the
# standalone checker (scripts/eml-check-normality.praat) is inline main-
# script code reached from the Describe menu, and the wizard's own copy
# (@wizardNormCheck in scripts/eml-wizard.praat) is a separate procedure with
# its own summary and its own recommendation line. Each is asserted on its
# own wording, because language batch item 13 gives each a different
# sentence:
#
#   STANDALONE (driven, from committed evidence):
#     "No strong departure in the groups large enough to test (N of M
#      assessed)." -- replaces the unconditional "no group in this column
#      shows a strong departure" exactly when coverage is incomplete, never
#      alongside it.
#
#   WIZARD (static -- no headless or GUI drive exists for this branch yet;
#   @wizardNormCheck is reached only through the wizard's own beginPause
#   flow, which `praat --run` cannot open at all, the same limitation
#   documented at the top of harness/normality/pergroup.sh for the
#   standalone checker's per-group branch. Reading the source honestly, as
#   the task instructions allow, beats deferring the check to a GUI harness
#   this round does not build):
#     "Assessed N of M groups; <name> (n = k) too small to test (needs 3)."
#     always prints when coverage is incomplete, and the recommendation line
#     is qualified ("...based on the groups large enough to test.") exactly
#     when it is.
#
# THE RATCHET. Both members are asserted STRUCTURALLY, not just for the
# presence of a string: the qualified sentence must sit inside the branch
# that tests incomplete coverage, and the unconditional generalisation must
# sit in that branch's `else` -- so a regression that printed the
# unconditional line unconditionally (removing the guard, not the text)
# still goes red, which a bare grep for both strings would not catch.
#
# THE RED DEMONSTRATION. harness/normalitycoverage/seed_*.sh build seeded
# copies -- one with the standalone checker's guard collapsed so the
# unqualified summary prints regardless of coverage, one with the wizard's
# coverage line and qualified recommendation deleted -- and this file, run
# unmodified against each through $EML_NORMCOV_SRC (source) and
# $EML_NORMCOV_EVIDENCE (the driven evidence directory, for the standalone
# half), goes red.
#
# Base R only.
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

V <- "v126"

ROOT <- Sys.getenv("EML_NORMCOV_SRC", unset = "")
if (!nzchar(ROOT)) ROOT <- repo_path("plugin_EML_StatsGraphs")
if (!dir.exists(ROOT)) stop("v126: no plugin tree at ", ROOT)

EVID <- Sys.getenv("EML_NORMCOV_EVIDENCE", unset = "")
if (!nzchar(EVID)) EVID <- repo_path("harness", "normality", "out", "pergroup")

rd <- function(rel) {
    p <- file.path(ROOT, rel)
    if (!file.exists(p)) return(character(0))
    readLines(p, warn = FALSE)
}

CHECK_FILES <- c("scripts/eml-check-normality.praat", "scripts/eml-wizard.praat")

# ---------------------------------------------------------------------------
# 0. THE POPULATION -- every source file carrying the n>=3 skip idiom
# ---------------------------------------------------------------------------
GATE <- "eml_getGroupData\\.n\\s*>=\\s*3"
present <- character(0)
gate_lines <- list()
for (rel in CHECK_FILES) {
    lines <- rd(rel)
    hit <- grep(GATE, lines)
    if (length(hit)) { present <- c(present, rel); gate_lines[[rel]] <- lines }
}
check_true(V,
           sprintf("RESOLVER: the n>=3 skip idiom was found in at least one file (%d)",
                   length(present)),
           length(present) >= 1L)
check_true(V,
           sprintf("both known call sites still carry the idiom (%d of %d)%s",
                   length(present), length(CHECK_FILES),
                   if (!setequal(present, CHECK_FILES))
                       paste0(" -- population changed: found ",
                              paste(present, collapse = ", ")) else ""),
           setequal(present, CHECK_FILES))

# ---------------------------------------------------------------------------
# 1. THE STANDALONE CHECKER -- STATIC STRUCTURE
# ---------------------------------------------------------------------------
sc <- gate_lines[["scripts/eml-check-normality.praat"]]
if (!is.null(sc)) {
    i_guard <- which(grepl("if\\s*\\.nAssessed\\s*<\\s*emlCountGroups\\.nGroups", sc))[1]
    i_qual  <- which(grepl("No strong departure in the", sc))[1]
    i_else  <- if (!is.na(i_guard))
        i_guard + which(grepl("^\\s*else\\s*$", sc[(i_guard + 1):length(sc)]))[1] else NA
    i_uncond <- which(grepl("no group in this column shows a", sc))[1]
    i_endif <- if (!is.na(i_else))
        i_else + which(grepl("^\\s*endif\\s*$", sc[(i_else + 1):length(sc)]))[1] else NA

    check_true(V, "STANDALONE: the coverage guard, qualified summary, unconditional summary, and its close were all located",
               !is.na(i_guard) && !is.na(i_qual) && !is.na(i_else) &&
               !is.na(i_uncond) && !is.na(i_endif))
    check_true(V, "STANDALONE: the qualified summary sits inside the incomplete-coverage branch",
               !is.na(i_guard) && !is.na(i_qual) && !is.na(i_else) &&
               i_guard < i_qual && i_qual < i_else)
    check_true(V, "STANDALONE: the unconditional 'no group shows a departure' claim sits ONLY in the else -- never beside the qualified one",
               !is.na(i_else) && !is.na(i_uncond) && !is.na(i_endif) &&
               i_else < i_uncond && i_uncond < i_endif)
    check_true(V, "STANDALONE: the qualified sentence names N of M assessed, verbatim shape",
               !is.na(i_qual) &&
               any(grepl('"\\s*groups large enough to test \\("', sc[i_qual:min(i_qual + 4, length(sc))])) )
} else {
    check_true(V, "STANDALONE: source located", FALSE)
}

# ---------------------------------------------------------------------------
# 2. THE STANDALONE CHECKER -- DRIVEN EVIDENCE
# ---------------------------------------------------------------------------
# p01_groups has three groups, one of them n = 2 -- too small to test. The
# grouped-mode Info window this evidence captures is the one thing a purely
# static read cannot prove: that the guarded branch is the one the plugin
# ACTUALLY takes on a real incomplete fixture, not merely the one the source
# reads as reachable.
grouped_path <- file.path(EVID, "p01_groups_grouped.txt")
ev_present <- file.exists(grouped_path)
check_true(V, sprintf("driven evidence is present: %s", grouped_path), ev_present)
if (ev_present) {
    ev <- paste(readLines(grouped_path, warn = FALSE), collapse = "\n")
    check_true(V, "EVIDENCE: the per-group column ran and skipped the n=2 group",
               grepl("skipped \\(n < 3\\)", ev))
    check_true(V, "EVIDENCE: the coverage-qualified summary is present, with the right counts",
               grepl("No strong departure in the groups large enough to test \\(2 of 3 assessed\\)\\.",
                     ev, fixed = FALSE))
    check_true(V, "EVIDENCE: the unconditional 'no group in this column' claim is ABSENT -- it would be false here",
               !grepl("no group in this column shows a strong departure", ev, fixed = TRUE))
} else {
    check_true(V, "EVIDENCE: p01_groups_grouped.txt readable", FALSE)
}

# A CONTRAST CASE, same evidence directory, complete coverage (g01_normal, or
# any case whose grp column holds one group covering every row -- see
# pergroup.sh's own header). The unconditional line is CORRECT there, and a
# check that only ever asserted the qualified sentence would not notice a
# regression that started qualifying EVERY summary, complete coverage
# included -- which would be its own kind of dishonesty, understating instead
# of overstating.
complete_path <- file.path(EVID, "g01_normal_grouped.txt")
if (file.exists(complete_path)) {
    cev <- paste(readLines(complete_path, warn = FALSE), collapse = "\n")
    check_true(V, "EVIDENCE: complete coverage still prints the unconditional summary, unqualified",
               grepl("no group in this column shows a strong departure", cev, fixed = TRUE) &&
               !grepl("groups large enough to test", cev, fixed = TRUE))
} else {
    check_true(V, "EVIDENCE: g01_normal_grouped.txt (complete-coverage contrast) readable", FALSE)
}

# ---------------------------------------------------------------------------
# 3. THE WIZARD -- STATIC STRUCTURE (@wizardNormCheck)
# ---------------------------------------------------------------------------
scan_procedures <- function(files) {
    out <- list()
    for (f in files) {
        lines <- rd(f)
        if (!length(lines)) next
        cur <- NULL; body <- character(0)
        for (ln in lines) {
            m <- regmatches(ln, regexec("^procedure\\s+([A-Za-z0-9_]+)", ln))[[1]]
            if (length(m) == 2L) { cur <- m[2]; body <- character(0) }
            else if (grepl("^endproc", ln) && !is.null(cur)) {
                out[[cur]] <- body; cur <- NULL
            } else if (!is.null(cur)) body <- c(body, ln)
        }
    }
    out
}
wprocs <- scan_procedures("scripts/eml-wizard.praat")
wb <- wprocs[["wizardNormCheck"]]
check_true(V, "WIZARD: @wizardNormCheck was located", !is.null(wb))

if (!is.null(wb)) {
    i_incomplete_set <- which(grepl("\\.nGroupsIncomplete\\s*=\\s*1\\b", wb))[1]
    i_cov_print <- which(grepl('"  Assessed "', wb, fixed = TRUE))[1]
    i_cov_guard <- if (!is.na(i_cov_print))
        rev(which(grepl("if\\s*\\.nGroupsIncomplete\\b", wb[1:i_cov_print])))[1] else NA
    check_true(V, "WIZARD: coverage is tracked per group (.nGroupsIncomplete set when a group is skipped)",
               !is.na(i_incomplete_set))
    check_true(V, "WIZARD: the 'Assessed N of M groups; ... too small to test' line prints, guarded by that same flag",
               !is.na(i_cov_print) && !is.na(i_cov_guard) && i_cov_guard < i_cov_print)
    check_true(V, "WIZARD: the skip list names the group and its n, verbatim shape",
               any(grepl('") too small to test (needs 3)"', wb, fixed = TRUE)))

    # The recommendation half: qualified inside `.mode$ = "group" and
    # .nGroupsIncomplete`, unqualified in the else beside it -- both under
    # the "no fail" (parametric-reasonable) branch, never under the
    # nonparametric branch, which does not generalise over groups at all.
    i_rec_guard <- which(grepl('\\.mode\\$\\s*=\\s*"group"\\s+and\\s+\\.nGroupsIncomplete', wb))[1]
    i_rec_qual  <- which(grepl("based on the groups large enough to test", wb))[1]
    i_rec_else  <- if (!is.na(i_rec_guard))
        i_rec_guard + which(grepl("^\\s*else\\s*$", wb[(i_rec_guard + 1):length(wb)]))[1] else NA
    i_rec_uncond <- if (!is.na(i_rec_else))
        i_rec_else + which(grepl('"  Recommendation: parametric test is "', wb[(i_rec_else + 1):length(wb)], fixed = TRUE))[1] else NA
    check_true(V, "WIZARD: the qualified recommendation sits inside the incomplete-coverage branch",
               !is.na(i_rec_guard) && !is.na(i_rec_qual) && !is.na(i_rec_else) &&
               i_rec_guard < i_rec_qual && i_rec_qual < i_rec_else)
    check_true(V, "WIZARD: the unqualified recommendation sits in that branch's else, not beside the qualified one",
               !is.na(i_rec_else) && !is.na(i_rec_uncond))
}

# ---------------------------------------------------------------------------
# 4. THE RESOLVER GATE
# ---------------------------------------------------------------------------
accounted <- present[vapply(present, function(rel) {
    if (rel == "scripts/eml-check-normality.praat") ev_present else !is.null(wb)
}, logical(1))]
eml_census(V, "normality coverage call site",
           present = present, accounted = accounted)

if (!exists("EML_SUITE")) {
    eml_report("v126 normality coverage is honest about what it assessed")
    eml_exit()
}
