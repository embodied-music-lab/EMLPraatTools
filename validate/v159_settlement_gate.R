#!/usr/bin/env Rscript
# ============================================================================
# v159 -- the settlement gate
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES
#
# The pre-run settlement wave renames six public procedures, removes one row
# from the public registry, adds two recorder hooks, and puts every public
# procedure on one outcome contract. Every part of that wave is mechanical
# and every part of it can be claimed done without being done. This file is
# the objective check on the claim.
#
# Praat resolves procedure names at call time and never checks a name that
# appears inside a string. A half-finished rename therefore produces no error
# anywhere: the procedure is simply never reached. Checks A through C exist
# because that failure is silent.
#
# WHICH CHECKS BIND
#
# Checks A through D carry a Fable ruling and FAIL the file when they fail:
#   A  the six old names appear nowhere
#   B  the six new names are defined and registered
#   C  the registry holds 42 rows and the mixed-model row is excluded by an
#      explicit entry rather than by deletion
#   D  the two ordered recorder hooks exist
#
# Check E BINDS. RULING_RECORDER_AND_WIRING_2026-09-02.md ruled the recorder's
# dispatch table stays hand-kept with a check asserting the copies agree, and
# RULING_SPLIT_AND_ACCEPTANCE ordered E promoted before the delegated session
# starts. It fails the file.
#
# Check F is the one that still reports only: the repeated-measures signature
# is accepted but not yet implemented, so F prints the current form.
#
# HOW TO RUN
#
#   Rscript validate/v159_settlement_gate.R
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v159"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

plug     <- repo_path("plugin_EML_StatsGraphs")
registry <- file.path(plug, "REGISTRY.tsv")
recorder <- file.path(plug, "stats", "eml-record.praat")
# The procedure-level exclusion lives in v155's RUN_EXCLUSIONS list, which
# the erosion check consults: every emlRun* procedure in the tree must have a
# registry row unless that list names it with a stated reason. RELEASE_EXCLUDE.tsv
# is a different thing entirely -- it names FILE PATHS the release zip drops,
# and the builder rejects an entry that matches no path, so a procedure name
# placed there would break the build.
v155     <- repo_path("validate", "v155_public_registry.R")

# The accepted renames are READ FROM THE PROPOSAL, not restated here. The
# proposal at mailbox/to-fable/PROPOSAL_CANONICAL_NAMES_2026-09-01.md is what
# NOTE_NAMES_ACCEPTED_2026-09-01.md accepts as written, so it is the canon.
# A copy typed into this file would be a second canon free to drift from it,
# and the first draft of this gate proved the point: one pair was typed from
# memory as emlGraphsInitDefaults and the true old name is emlInitDrawingDefaults,
# which produced a check that passed because it was looking for nothing.
#
# Row shape in the proposal: | `oldName` | **`newName`** | rationale |
# Rows whose second cell is *(same)* are unchanged and are skipped.
proposalFile <- repo_path("mailbox", "to-fable",
                          "PROPOSAL_CANONICAL_NAMES_2026-09-01.md")
if (!file.exists(proposalFile)) {
    stop("v159: cannot find the accepted naming proposal at ", proposalFile)
}
pl <- readLines(proposalFile, warn = FALSE)
rowRe <- "^\\|\\s*`([A-Za-z0-9_]+)`\\s*\\|\\s*\\*\\*`([A-Za-z0-9_]+)`\\*\\*\\s*\\|"
hits <- regmatches(pl, regexec(rowRe, pl))
RENAMES <- lapply(Filter(function(h) length(h) == 3, hits),
                  function(h) c(h[2], h[3]))

cat(sprintf("\n  renames read from the accepted proposal: %d\n", length(RENAMES)))
for (p in RENAMES) cat(sprintf("      %s -> %s\n", p[1], p[2]))
check_true(V, "the accepted proposal yields exactly six renames",
           length(RENAMES) == 6)

praatFiles <- list.files(plug, pattern = "\\.praat$", recursive = TRUE,
                         full.names = TRUE)
allText <- setNames(lapply(praatFiles, function(f)
    paste(readLines(f, warn = FALSE), collapse = "\n")), praatFiles)

countName <- function(nm) {
    pat <- sprintf("\\b%s\\b", nm)
    sum(vapply(allText, function(t)
        length(gregexpr(pat, t)[[1]][gregexpr(pat, t)[[1]] > 0]), integer(1)))
}
filesWith <- function(nm) {
    pat <- sprintf("\\b%s\\b", nm)
    names(allText)[vapply(allText, function(t) grepl(pat, t), logical(1))]
}

# ---- A. the six old names are gone ---------------------------------------
cat("\n  ---- A. old names retired ----\n")
for (p in RENAMES) {
    old <- p[1]; n <- countName(old)
    check_true(V, sprintf("old name %s appears nowhere", old), n == 0)
    if (n > 0) {
        cat(sprintf("      %s: %d reference(s) remain in %d file(s)\n",
                    old, n, length(filesWith(old))))
        for (f in filesWith(old)) cat(sprintf("        %s\n", sub(plug, "", f)))
    }
}

# ---- A2. the wider footprint, REPORT ONLY ----------------------------------
# Check A globs *.praat inside plugin_EML_StatsGraphs/ only, and the settlement
# session measured what that misses. THE SCOPE IS NOT RESTATED HERE: it is read
# from RENAME_SCOPE.tsv, which RULING_RENAME_SCOPE_2026-09-02.md orders stated
# once. Before that file existed, this check, list_sites.sh, the inventory grep
# and the work order each carried their own copy and disagreed.
#
# Reporting against the shared scope means these counts go to zero as the
# rename lands, instead of counting history forever.
cat("\n  ---- A2. retired names outside plugin_EML_StatsGraphs (report only) ----\n")

scopeFile <- repo_path("RENAME_SCOPE.tsv")
check_true(V, "RENAME_SCOPE.tsv exists (the scope is stated once)",
           file.exists(scopeFile))

if (file.exists(scopeFile)) {
    sc <- readLines(scopeFile, warn = FALSE)
    sc <- sc[!grepl("^#", sc) & nzchar(sc)]
    sc <- sc[-1]                                  # column header
    parts <- strsplit(sc, "\t", fixed = TRUE)
    pats  <- vapply(parts, `[`, character(1), 1)
    disps <- vapply(parts, `[`, character(1), 2)

    # First matching row wins; unmatched is RENAME, per the file's own default.
    dispositionFor <- function(path) {
        hit <- which(vapply(pats, function(p) grepl(p, path, fixed = TRUE),
                            logical(1)))
        if (length(hit)) disps[hit[1]] else "RENAME"
    }

    # THE REPOSITORY, NOT THE WORKING DIRECTORY. list.files() reads whatever
    # happens to be on the disk this runs on, including gitignored local
    # artifacts, and on 2 September that made the census describe one
    # container rather than the repository everyone shares. git ls-files is
    # the repository by definition. Same fix as build_rename_inventory.py,
    # made in the same pass so the two cannot disagree again.
    allFiles <- tryCatch(
        system2("git", c("-C", shQuote(repo_path(".")), "ls-files"),
                stdout = TRUE, stderr = FALSE),
        error = function(e) character(0))
    check_true(V, "git ls-files returned the repository's file list",
               length(allFiles) > 0)
    inScope  <- allFiles[vapply(allFiles, dispositionFor, character(1)) == "RENAME"]
    inScope  <- inScope[!grepl("^plugin_EML_StatsGraphs/", inScope)]

    cat(sprintf("      scope: %d file(s) marked RENAME outside the plugin tree\n",
                length(inScope)))
    stillThere <- 0
    for (p in RENAMES) {
        old <- p[1]; n <- 0
        for (f in inScope) {
            fp <- repo_path(f)
            if (!file.exists(fp)) next
            ln <- tryCatch(readLines(fp, warn = FALSE), error = function(e) character(0))
            if (any(grepl(sprintf("\\b%s\\b", old), ln))) n <- n + 1
        }
        if (n > 0) {
            cat(sprintf("      %-26s %d file(s)\n", old, n))
            stillThere <- stillThere + n
        }
    }
    if (stillThere == 0)
        cat("      none remain -- the rename has landed across the shared scope\n")
    else
        cat("      Check A does not see these. They are in scope per the ruling.\n")
}

# ---- B. the six new names are live ---------------------------------------
cat("\n  ---- B. new names defined and registered ----\n")
regLines <- readLines(registry, warn = FALSE)
regRows  <- regLines[grepl("^eml", regLines)]
regNames <- sub("\t.*$", "", regRows)
for (p in RENAMES) {
    new <- p[2]
    defs <- sum(vapply(allText, function(t)
        grepl(sprintf("(?m)^\\s*procedure\\s+%s\\b", new), t, perl = TRUE),
        logical(1)))
    check_true(V, sprintf("new name %s defined exactly once", new), defs == 1)
    check_true(V, sprintf("new name %s has a registry row", new),
               sum(regNames == new) == 1)
}

# ---- C. registry shape ----------------------------------------------------
cat("\n  ---- C. registry at 42 rows, mixed model excluded by entry ----\n")
check_true(V, "registry holds exactly 42 data rows", length(regRows) == 42)
cat(sprintf("      registry data rows now: %d\n", length(regRows)))
check_true(V, "emlRunLMMAnalysis absent from registry",
           sum(regNames == "emlRunLMMAnalysis") == 0)
v155txt <- paste(readLines(v155, warn = FALSE), collapse = "\n")
runExcl <- regmatches(v155txt,
             regexpr("(?s)RUN_EXCLUSIONS <- c\\(.*?\\n\\)", v155txt, perl = TRUE))
exclNames <- if (length(runExcl))
    unique(unlist(regmatches(runExcl, gregexpr("emlRun[A-Za-z0-9_]+", runExcl)))) else character(0)
cat(sprintf("      v155 RUN_EXCLUSIONS currently names: %s\n",
            paste(exclNames, collapse = ", ")))
check_true(V, "emlRunLMMAnalysis named in v155 RUN_EXCLUSIONS",
           "emlRunLMMAnalysis" %in% exclNames)
check_true(V, "its exclusion entry states a reason",
           length(runExcl) > 0 &&
           grepl("emlRunLMMAnalysis\\s*=\\s*paste\\(|emlRunLMMAnalysis\\s*=\\s*\"", runExcl))

# ---- D. the two ordered recorder hooks ------------------------------------
cat("\n  ---- D. ordered recorder hooks ----\n")
recText <- paste(readLines(recorder, warn = FALSE), collapse = "\n")
for (nm in c("emlRunGroupedRegressionAnalysis", "emlDrawQQPlot")) {
    check_true(V, sprintf("recorder mentions %s", nm),
               grepl(sprintf("\\b%s\\b", nm), recText))
}

# ---- E. recorder binding, BINDING ------------------------------------------
# Promoted from report-only by RULING_RECORDER_AND_WIRING_2026-09-02.md, which
# rules that the recorder's dispatch table stays hand-kept for 1.0 and a check
# asserts the copies agree. Generating the table from the registry is filed
# post-1.0, because it would require the registry to grow argument-role
# metadata that today lives only in the recorder's spec strings.
#
# The recorder emits from more than one file. An earlier draft of this section
# searched stats/eml-record.praat alone and therefore reported four registry
# rows as unreachable when one of them, emlCleanConvertedTable, is emitted from
# graphs/eml-graph-procedures.praat. The emission surface is whatever
# validate/recorder_coverage.tsv names, which comes from the measured census.
cat("\n  ---- E. recorder binding (RULING_RECORDER_AND_WIRING) ----\n")

covFile <- repo_path("validate", "recorder_coverage.tsv")
covRaw  <- readLines(covFile, warn = FALSE)
covRows <- covRaw[grepl("^eml", covRaw)]
covName <- sub("\t.*$", "", covRows)
covFld  <- strsplit(covRows, "\t", fixed = TRUE)
covOf   <- function(nm, i) {
    r <- covFld[[which(covName == nm)[1]]]
    if (length(r) >= i) r[i] else ""
}

# E1. every registry row is accounted for in the table
for (nm in regNames) {
    check_true(V, sprintf("recorder table accounts for registry row %s", nm),
               nm %in% covName)
}

# E2. no retired name survives anywhere in the emission surface
emitFiles <- unique(Filter(nzchar, vapply(covName, covOf, character(1), 2)))
emitPaths <- file.path(plug, emitFiles)
emitPaths <- emitPaths[file.exists(emitPaths)]
emitText  <- paste(unlist(lapply(emitPaths, readLines, warn = FALSE)),
                   collapse = "\n")
cat(sprintf("      emission surface: %d file(s) named by the coverage table\n",
            length(emitPaths)))
for (p in RENAMES) {
    old <- p[1]
    check_true(V, sprintf("retired name %s absent from the emission surface", old),
               !grepl(sprintf("\\b%s\\b", old), emitText))
}

# E3. a covered row's named emitting file still mentions it.
# This is the check that catches a rename which updated the procedure but not
# the recorder string, which Praat would never report.
for (nm in regNames) {
    st <- covOf(nm, 4)
    if (!(st %in% c("live", "code-trace", "live (refusal)"))) next
    f  <- covOf(nm, 2)
    fp <- file.path(plug, f)
    ok <- nzchar(f) && file.exists(fp) &&
          any(grepl(sprintf("\\b%s\\b", nm), readLines(fp, warn = FALSE)))
    check_true(V, sprintf("emitting site for %s still names it (%s)", nm, f), ok)
}

# E4. every GAP row is one the rulings ordered fixed, and every EXEMPT row
# carries a committed reason.
for (i in seq_along(covName)) {
    nm <- covName[i]; st <- covOf(nm, 4); why <- covOf(nm, 5)
    if (st == "GAP") {
        check_true(V, sprintf("GAP row %s is closed (a hook now exists)", nm), FALSE)
    } else if (st == "EXEMPT") {
        check_true(V, sprintf("exemption for %s states a reason", nm),
                   nchar(why) > 80)
    }
}

# ---- F. repeated-measures signature, REPORT ONLY ----------------------------
# WORK_ORDER_API_SETTLEMENT item 1 rules the string-vector form canonical for
# 1.0. Ian ruled on 2 September that the pipe form does not become a
# compatibility wrapper: the plugin has never shipped, so it simply stops
# existing. Still report-only, because the change is held on Ian's
# wire-or-remove ruling for .subjectCol$ in the same signature. Promote to a
# binding check when that lands.
cat("\n  ---- F. repeated-measures signature (report only, held on .subjectCol$) ----\n")
for (nm in c("emlRunRepeatedMeasuresAnalysis", "emlRunFriedmanAnalysis")) {
    sig <- grep(sprintf("^%s\\t", nm), regRows, value = TRUE)
    form <- if (length(sig) && grepl("conditionCols\\$", sig)) {
        "pipe-delimited string (ruled against)"
    } else if (length(sig) && grepl("conditionCols\\$#", sig)) {
        "string vector (canonical)"
    } else "unrecognised"
    cat(sprintf("      %-32s %s\n", nm, form))
}

if (!exists("EML_SUITE")) { eml_report("v159 -- the settlement gate"); eml_exit() }
