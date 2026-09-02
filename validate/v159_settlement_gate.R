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
# Check E is REPORT-ONLY. It measures the recorder against the registry,
# which is a proposal in MEMO_RECORDER_NAME_BINDING_2026-09-02.md and not yet
# ruled. It prints its findings and does not fail the file. Promote it to a
# binding check only when a ruling says to.
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

# ---- E. recorder against registry, REPORT ONLY ----------------------------
# Not ruled. Prints; never fails.
cat("\n  ---- E. recorder against registry (report only, not ruled) ----\n")
lits <- unique(unlist(regmatches(recText,
          gregexpr('"eml[A-Za-z0-9_]+"', recText))))
lits <- gsub('"', '', lits)
calls <- unique(unlist(regmatches(recText,
          gregexpr('@eml[A-Za-z0-9_]+', recText))))
calls <- gsub('@', '', calls)
mentioned <- union(lits, calls)

missing <- setdiff(regNames, mentioned)
cat(sprintf("      registry rows the recorder never mentions: %d\n", length(missing)))
for (m in missing) cat(sprintf("        %s\n", m))

stale <- intersect(lits, unlist(lapply(RENAMES, `[`, 1)))
cat(sprintf("      retired names still present as recorder strings: %d\n", length(stale)))
for (s in stale) cat(sprintf("        %s\n", s))

looksPublic <- grep("^eml(Run|Draw)[A-Z]", lits, value = TRUE)
orphan <- setdiff(looksPublic, regNames)
cat(sprintf("      recorder strings that look public but are not registry rows: %d\n",
            length(orphan)))
for (o in orphan) cat(sprintf("        %s\n", o))

if (!exists("EML_SUITE")) { eml_report("v159 -- the settlement gate"); eml_exit() }
