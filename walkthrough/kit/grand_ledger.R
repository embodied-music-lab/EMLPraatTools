# grand_ledger.R -- the single source of every count the paper cites.
#
# Tracker item A.7 (mailbox/to-opus/TRACKER_KIT_AND_1p0.md, section A) says
# this file must exist and that every headline count the paper prints comes
# from it, nowhere else. Tracker section C repeats the same rule for the
# paper's final procedure/cell/comparison counts specifically: "set by
# grand_ledger at the authoritative run and nowhere else."
#
# WHAT THIS FILE DOES. It reads the kit's own declaration and output files
# and writes walkthrough/kit/grand_ledger.tsv, one row per reported
# quantity: quantity_name, value, unit, derived_from, as_of, status, note.
# It computes nothing that isn't traceable to a file already on disk --
# no number here is typed in by hand.
#
# TWO CLASSES OF INPUT, TWO DIFFERENT FAILURE MODES.
#
#   HARD-REQUIRED declaration files -- matrix.tsv, quantities.tsv, the
#   plugin's REGISTRY.tsv, and the validate/ suite's own script files.
#   These are supposed to exist in any working checkout of the kit,
#   authoritative run or not. If one is missing, that is a broken kit, not
#   a pre-run kit, and this script REFUSES TO WRITE A LEDGER AT ALL: it
#   prints exactly which path is missing and exits with status 1. A partial
#   ledger with a silent zero standing in for "the file wasn't there" is
#   exactly what the tracker's ban on placeholder counts is written
#   against, so this script does not produce one.
#
#   RUN-DEPENDENT output files -- audit/praat_results.tsv,
#   audit/r_results.tsv, audit/VERDICT.txt, results/reconciliation.tsv, and
#   a captured pass/fail summary of validate/run_all.R. These are the
#   authoritative run's own outputs (tracker item A.8: "run NOT RUN" as of
#   this writing). Their absence is not a broken kit, it is the expected
#   PRE-RUN state, so a missing or STALE file in this group does not abort
#   the script. Instead every quantity that depends on it gets one row with
#   value NA, status AWAITING_RUN, and a note naming exactly what is
#   missing or which file is older than which. FRESHNESS is checked by
#   file mtime, the same signal compare.R itself already uses for its own
#   internal stale-cell_id check: a runner output older than the
#   declaration it is supposed to have run against, or a compare.R output
#   older than either of the two runner tables, is stale, not current, no
#   matter that a byte sits on disk at that path.
#
# Re-running this script after the authoritative run needs no edit: once
# audit/VERDICT.txt (and the files it is derived from) are all newer than
# matrix.tsv and quantities.tsv, the run-dependent rows switch themselves
# from AWAITING_RUN to MEASURED and carry the real numbers.
#
# EXIT STATUS.
#   0  every at-minimum quantity is MEASURED and fresh -- the ledger is
#      complete and citable.
#   1  a HARD-REQUIRED input is missing -- no ledger was written.
#   2  the ledger WAS written (walkthrough/kit/grand_ledger.tsv exists and
#      is complete for what can currently be known) but at least one
#      at-minimum quantity is AWAITING_RUN -- this is the expected exit
#      status before the authoritative run.

emlThisFile <- function() {
    args <- commandArgs(trailingOnly = FALSE)
    fileArg <- sub("^--file=", "", args[grepl("^--file=", args)])
    if (length(fileArg)) return(normalizePath(fileArg))
    for (i in rev(seq_along(sys.frames()))) {
        ofile <- sys.frames()[[i]]$ofile
        if (!is.null(ofile)) return(normalizePath(ofile))
    }
    if (requireNamespace("rstudioapi", quietly = TRUE) &&
        isTRUE(tryCatch(rstudioapi::isAvailable(), error = function(e) FALSE))) {
        ctx <- tryCatch(rstudioapi::getSourceEditorContext(), error = function(e) NULL)
        if (!is.null(ctx) && nzchar(ctx$path)) return(normalizePath(ctx$path))
    }
    stop("grand_ledger.R can't find its own location.\nIn RStudio: Session > Set ",
         "Working Directory > To Source File Location, then Source again.",
         call. = FALSE)
}
kitDir     <- dirname(emlThisFile())
repoRoot   <- dirname(dirname(kitDir))          # walkthrough/kit -> walkthrough -> repo root
pluginDir  <- file.path(repoRoot, "plugin_EML_StatsGraphs")
validateDir<- file.path(repoRoot, "validate")
auditDir   <- file.path(kitDir, "audit")
resultsDir <- file.path(kitDir, "results")

cat("grand_ledger.R: kitDir =", kitDir, "\n")

# ---------------------------------------------------------------------------
# HARD-REQUIRED declaration inputs. Missing any one of these aborts the
# whole run -- no ledger, exit 1, message names the exact path(s) missing.
# ---------------------------------------------------------------------------
mxPath <- file.path(kitDir, "matrix.tsv")
qtPath <- file.path(kitDir, "quantities.tsv")
regPath <- file.path(pluginDir, "REGISTRY.tsv")

required <- c(
    "walkthrough/kit/matrix.tsv"                    = mxPath,
    "walkthrough/kit/quantities.tsv"                 = qtPath,
    "plugin_EML_StatsGraphs/REGISTRY.tsv"            = regPath
)
missingReq <- required[!file.exists(required)]
validatorFiles <- if (dir.exists(validateDir)) sort(Sys.glob(file.path(validateDir, "v*.R"))) else character(0)
if (length(missingReq) || length(validatorFiles) == 0) {
    cat("\ngrand_ledger.R: FATAL -- required input(s) missing. No ledger written.\n\n")
    if (length(missingReq)) {
        for (nm in names(missingReq))
            cat(sprintf("  MISSING  %-42s (looked at %s)\n", nm, missingReq[[nm]]))
    }
    if (length(validatorFiles) == 0) {
        cat(sprintf("  MISSING  %-42s (looked at %s/v*.R)\n", "validate/ suite scripts", validateDir))
    }
    cat("\nThese are declaration files a working checkout of the kit always has,\n",
        "authoritative run or not. This is not the pre-run state the ledger is\n",
        "designed to tolerate -- it is a broken or incomplete checkout, and the\n",
        "ledger refuses to guess at counts it cannot read.\n", sep = "")
    quit(status = 1, save = "no")
}

# ---------------------------------------------------------------------------
# Provenance for this ledger build itself: same "ask git, record what
# happens, never let a git failure stop the run" contract as
# run_analyses.R's environment capture (walkthrough/kit/run_analyses.R,
# lines ~204-236), reused verbatim here for the same reason it exists
# there -- a real fact about what ran, not a guess.
# ---------------------------------------------------------------------------
if (nzchar(Sys.which("git"))) {
    .gitRun <- function(...) {
        out <- suppressWarnings(system2("git", c("-C", repoRoot, ...), stdout = TRUE, stderr = TRUE))
        st <- attr(out, "status")
        list(ok = is.null(st) || st == 0, text = paste(out, collapse = "\n"))
    }
    .gitCommit <- .gitRun("rev-parse", "HEAD")
    .gitStatus <- .gitRun("status", "--porcelain")
    gitCommit <- if (.gitCommit$ok) .gitCommit$text else paste0("GIT_ERROR: ", .gitCommit$text)
    gitDirty  <- (if (!.gitCommit$ok) "unknown (commit not available)"
                 else if (!.gitStatus$ok) "unknown (git status unavailable)"
                 else if (!nzchar(.gitStatus$text)) "clean"
                 else "DIRTY")
} else {
    gitCommit <- "GIT_UNAVAILABLE (git not found on PATH)"
    gitDirty  <- "unknown (git not found on PATH)"
}
ledgerBuiltAt <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %z")
ledgerRunId <- sprintf("grand_ledger run at %s, repo commit %s (%s)",
                        ledgerBuiltAt, substr(gitCommit, 1, 12), gitDirty)
cat("grand_ledger.R: this run's identifier ->", ledgerRunId, "\n\n")

# ---------------------------------------------------------------------------
# Row accumulator.
# ---------------------------------------------------------------------------
`%+%` <- function(a, b) paste0(a, b)

rows <- list()
addRow <- function(quantity_name, value, unit, derived_from, as_of, status, note = "") {
    rows[[length(rows) + 1]] <<- data.frame(
        quantity_name = quantity_name,
        value          = value,
        unit           = unit,
        derived_from   = derived_from,
        as_of          = as_of,
        status         = status,
        note           = note,
        stringsAsFactors = FALSE
    )
}

liveAsOf <- ledgerRunId  # for quantities recomputed live from a declaration
                         # file present right now, "as of" is this ledger
                         # build, over whatever the file currently contains.

# ---------------------------------------------------------------------------
# LIVE quantities: recomputed directly from the declaration files, using
# the SAME parse compare.R itself uses (comment.char = "#" over matrix.tsv;
# the '#'-preamble stripped by hand over quantities.tsv, because Praat
# matrix names end '##' and comment.char would truncate those rows
# mid-line -- see compare.R's own comment beside its quantities.tsv read).
# These do not depend on the authoritative run having happened: they are
# true of the checkout right now, and are exactly what "not hardcoding
# anything" requires reading, rather than typing in the number compare.R
# printed on some earlier run.
# ---------------------------------------------------------------------------
mx <- read.delim(mxPath, sep = "\t", comment.char = "#", colClasses = "character", quote = "")
qtLines <- readLines(qtPath, warn = FALSE)
QT <- read.delim(text = qtLines[!startsWith(qtLines, "#")], sep = "\t",
                  colClasses = "character", quote = "", comment.char = "")
regLines <- readLines(regPath, warn = FALSE)
regDataLines <- regLines[!startsWith(regLines, "#") & nzchar(trimws(regLines))]
REG <- read.delim(text = regDataLines, sep = "\t", colClasses = "character",
                   quote = "", comment.char = "")

addRow("n_public_procedures", nrow(REG), "procedures",
       "plugin_EML_StatsGraphs/REGISTRY.tsv: data rows after the '#' header block "
       %+% "(rule: read.delim over the lines that are neither blank nor start with '#'; first "
       %+% "surviving row is the 'name/file/signature/description/sources' header, not counted)."
       %+% " READ-ONLY per this job's hard rules -- no edit proposed here, none needed.",
       liveAsOf, "MEASURED")

addRow("n_numerically_validated_procedures", length(unique(mx$procedure)), "procedures",
       "walkthrough/kit/matrix.tsv: count of distinct values in the procedure column, "
       %+% "read.delim(sep='\\t', comment.char='#') -- the exact parse compare.R uses "
       %+% "to build 'mx' before it prints 'cells declared in matrix.tsv'.",
       liveAsOf, "MEASURED",
       "This is the subset of the public surface the kit numerically validates -- "
       %+% "walkthrough/kit/README.md and tracker section C are explicit that this number "
       %+% "must never be presented as if it covered the drawing or utility rows too.")

addRow("n_validation_cells", nrow(mx), "cells",
       "walkthrough/kit/matrix.tsv: data row count, same parse as above.",
       liveAsOf, "MEASURED")

studyTab <- table(mx$study)
for (s in names(studyTab))
    addRow(paste0("n_validation_cells_", s), as.integer(studyTab[[s]]), "cells",
           sprintf("walkthrough/kit/matrix.tsv: rows where study == \"%s\".", s),
           liveAsOf, "MEASURED")

addRow("n_contract_clauses", nrow(QT), "clauses",
       "walkthrough/kit/quantities.tsv: data rows after stripping lines starting with '#' "
       %+% "by hand (comment.char is not used here -- Praat matrix names in the source "
       %+% "column end '##', and comment.char would truncate those rows mid-line; same "
       %+% "reasoning and same code shape as compare.R's own quantities.tsv read).",
       liveAsOf, "MEASURED")

addRow("n_validators_total", length(validatorFiles), "scripts",
       sprintf("validate/v*.R: file count in the repository's separate validate/ suite (%d files matched). "
               %+% "validate/README.md's own prose calls each such script a 'validator' "
               %+% "(\"seven validators -- v59, v63, v64, v65, v70, v71, v77 -- resolve a Praat binary...\").",
               length(validatorFiles)),
       liveAsOf, "MEASURED")

# ---------------------------------------------------------------------------
# RUN-DEPENDENT quantities. Freshness gate first: a runner output older
# than the declaration it should have run against, or a compare.R output
# older than either runner table or the declarations, is STALE regardless
# of whether the byte exists on disk. Every stale/missing reason is
# collected so the ledger's note column, and this run's console output,
# name exactly which file is older than which -- not just "stale".
# ---------------------------------------------------------------------------
praatPath <- file.path(auditDir, "praat_results.tsv")
rPath     <- file.path(auditDir, "r_results.tsv")
verdictPath <- file.path(auditDir, "VERDICT.txt")
reconPath   <- file.path(resultsDir, "reconciliation.tsv")

mt <- function(p) if (file.exists(p)) file.info(p)$mtime else as.POSIXct(NA)
fmt <- function(t) if (is.na(t)) "n/a" else format(t, "%Y-%m-%d %H:%M:%S %z")

declFiles   <- c("matrix.tsv" = mxPath, "quantities.tsv" = qtPath)
runnerFiles <- c("audit/praat_results.tsv" = praatPath, "audit/r_results.tsv" = rPath)

staleReasons <- character(0)

for (rn in names(runnerFiles)) {
    rp <- runnerFiles[[rn]]
    if (!file.exists(rp)) {
        staleReasons <- c(staleReasons, sprintf("%s does not exist", rn))
        next
    }
    for (dn in names(declFiles)) {
        dp <- declFiles[[dn]]
        if (mt(dp) > mt(rp))
            staleReasons <- c(staleReasons, sprintf(
                "%s (mtime %s) is OLDER than %s (mtime %s) -- this runner has not been re-driven since the declaration changed",
                rn, fmt(mt(rp)), dn, fmt(mt(dp))))
    }
}

if (!file.exists(verdictPath)) {
    staleReasons <- c(staleReasons, "audit/VERDICT.txt does not exist -- compare.R has never been run to completion")
} else {
    for (nm in c(names(declFiles), names(runnerFiles))) {
        p <- c(declFiles, runnerFiles)[[nm]]
        if (file.exists(p) && mt(p) > mt(verdictPath))
            staleReasons <- c(staleReasons, sprintf(
                "%s (mtime %s) is NEWER than audit/VERDICT.txt (mtime %s) -- compare.R has not been re-run since",
                nm, fmt(mt(p)), fmt(mt(verdictPath))))
    }
}

runFresh <- length(staleReasons) == 0 && file.exists(verdictPath)

if (length(staleReasons)) {
    cat("grand_ledger.R: run-dependent inputs are NOT fresh -- reasons:\n")
    for (r in staleReasons) cat("  -", r, "\n")
    cat("\n")
} else {
    cat("grand_ledger.R: run-dependent inputs ARE fresh relative to the current declarations.\n\n")
}

staleNote <- (if (length(staleReasons))
    paste0("AWAITING_RUN: ", paste(staleReasons, collapse = " | "))
else
    "AWAITING_RUN: audit/VERDICT.txt not found.")

if (runFresh) {
    vLines <- readLines(verdictPath, warn = FALSE)
    grabInt <- function(pattern) {
        hit <- grep(pattern, vLines, value = TRUE)
        if (!length(hit)) return(NA_integer_)
        m <- regmatches(hit[1], regexpr("[0-9]+", hit[1]))
        if (!length(m)) return(NA_integer_)
        as.integer(m)
    }
    nComparisons  <- grabInt("^value comparisons made")
    nAgree        <- grabInt("^\\s*AGREE\\s+[0-9]+")
    nContractBkt  <- grabInt("^\\s*CONTRACT\\s+[0-9]+\\s+\\(one-sided")
    nDeclaredBkt  <- grabInt("^\\s*DECLARED\\s+[0-9]+\\s+\\(differences")
    nUnexplained  <- grabInt("^\\s*UNEXPLAINED\\s+[0-9]+\\s*$")
    verdictLine   <- (if (any(grepl("^\\s*NOT GREEN\\.\\s*$", vLines))) "NOT GREEN"
                       else if (any(grepl("^\\s*GREEN\\.\\s*$", vLines))) "GREEN"
                       else NA_character_)
    runAsOf <- sprintf("audit/VERDICT.txt, mtime %s (compare.R's captured verdict)", fmt(mt(verdictPath)))
    runDerived <- "audit/VERDICT.txt: parsed from compare.R's own printed summary lines "
    runStatus <- "MEASURED"
    runNote <- ""
} else {
    nComparisons <- nAgree <- nContractBkt <- nDeclaredBkt <- nUnexplained <- NA_integer_
    verdictLine <- NA_character_
    runAsOf <- "PENDING -- authoritative run not yet executed (tracker item A.8: run NOT RUN)"
    runDerived <- "audit/VERDICT.txt (compare.R's output) -- would be parsed from its printed summary lines "
    runStatus <- "AWAITING_RUN"
    runNote <- staleNote
}

addRow("n_comparisons", nComparisons, "quantity comparisons",
       runDerived %+% "(\"value comparisons made : %d\").", runAsOf, runStatus, runNote)
addRow("n_comparisons_agree", nAgree, "quantity comparisons",
       runDerived %+% "(the AGREE bucket line: relative difference < 1e-9, or absolute < 1e-12 near zero).",
       runAsOf, runStatus, runNote)
addRow("n_comparisons_contract_one_sided", nContractBkt, "quantity comparisons",
       runDerived %+% "(the CONTRACT bucket line: one-sided rows quantities.tsv accounts for).",
       runAsOf, runStatus, runNote)
addRow("n_comparisons_declared", nDeclaredBkt, "quantity comparisons",
       runDerived %+% "(the DECLARED bucket line: differences and one-sided rows with a written reason).",
       runAsOf, runStatus, runNote)
addRow("n_comparisons_unexplained", nUnexplained, "quantity comparisons",
       runDerived %+% "(the UNEXPLAINED bucket line -- must be 0 for the kit to be green).",
       runAsOf, runStatus, runNote)
addRow("kit_verdict", verdictLine, "GREEN | NOT GREEN",
       runDerived %+% "(the run's final GREEN./NOT GREEN. line).",
       runAsOf, runStatus, runNote)

# ---------------------------------------------------------------------------
# validate/ suite pass count. The suite's own scripts are counted live
# above (n_validators_total); how many of them PASS is a property of an
# actual execution of `Rscript validate/run_all.R`, and no captured,
# current summary of that execution exists anywhere in this repository --
# checked directly below, not assumed. (The one full-suite log this repo
# does contain, harness/suiteguard/out/break_control.run_all.log, is a
# fixture for testing the suiteguard harness itself: dated 20 Aug 2026,
# 91 scripts, run from a /tmp copy -- 60 scripts fewer than validate/
# currently holds, so using it here would misstate the current suite.)
# ---------------------------------------------------------------------------
validatorSummaryPath <- file.path(validateDir, "RUN_ALL_SUMMARY.tsv")
if (file.exists(validatorSummaryPath)) {
    vs <- read.delim(validatorSummaryPath, sep = "\t", colClasses = "character", quote = "")
    nPass <- sum(vs$status == "PASS", na.rm = TRUE)
    addRow("n_validators_passing", nPass, "scripts",
           "validate/RUN_ALL_SUMMARY.tsv: count of rows with status == \"PASS\".",
           sprintf("validate/RUN_ALL_SUMMARY.tsv, mtime %s", fmt(mt(validatorSummaryPath))),
           "MEASURED")
} else {
    addRow("n_validators_passing", NA_integer_, "scripts",
           "validate/RUN_ALL_SUMMARY.tsv (a captured pass/fail summary of `Rscript validate/run_all.R`) -- would be read from that file.",
           "PENDING -- no captured summary of a validate/run_all.R execution exists in this repository",
           "AWAITING_RUN",
           "AWAITING_RUN: validate/RUN_ALL_SUMMARY.tsv does not exist. validate/run_all.R does not currently write one; "
           %+% "running the full suite and capturing PASS/FAIL per validator to this path is a prerequisite this ledger "
           %+% "cannot substitute for. The nearest artifact on disk, harness/suiteguard/out/break_control.run_all.log, "
           %+% "is a suiteguard-harness fixture (20 Aug 2026, 91 of the current 151 scripts, run from a /tmp copy), not a "
           %+% "current capture, and is not used here.")
}

# ---------------------------------------------------------------------------
# Write the ledger.
# ---------------------------------------------------------------------------
ledger <- do.call(rbind, rows)
ledgerPath <- file.path(kitDir, "grand_ledger.tsv")
write.table(ledger, ledgerPath, sep = "\t", quote = FALSE, row.names = FALSE, na = "NA")

cat(sprintf("grand_ledger.R: wrote %d rows to %s\n\n", nrow(ledger), ledgerPath))
print(ledger[, c("quantity_name", "value", "unit", "status")], row.names = FALSE)

nAwaiting <- sum(ledger$status == "AWAITING_RUN")
cat(sprintf("\ngrand_ledger.R: %d row(s) MEASURED, %d row(s) AWAITING_RUN.\n",
            sum(ledger$status == "MEASURED"), nAwaiting))

if (nAwaiting > 0) {
    cat("grand_ledger.R: ledger written, but INCOMPLETE -- the authoritative run has not\n",
        "happened (tracker item A.8) and/or its outputs are stale relative to the current\n",
        "declarations. These rows are not citable in the paper yet. Exiting 2.\n", sep = "")
    quit(status = 2, save = "no")
} else {
    cat("grand_ledger.R: every at-minimum quantity is MEASURED and fresh. Exiting 0.\n")
    quit(status = 0, save = "no")
}
