# ============================================================================
# v153 (redo) — LMM result-store clear on entry: real end-to-end drive
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS FILE WAS REDONE, IN FULL, AS RULING_WAVE_TWO REQUIRED
#
# Wave one's v153 never called @emlRunLMMAnalysis at all. It called
# @emlResultBegin (which is what a DECLARING orchestrator calls, and LMM is
# the one orchestrator that never declares), then @emlResultClearAll
# directly, then asserted the collectors it had just told to clear were
# clear. Tautological — it could not have gone red under any version of
# eml-lmm.praat, fixed or not.
#
# An adversarial review then built the real reproduction and found two
# things, both reproduced again here, independently, by this file:
#
#   1. @emlResultClearAll DOES clear genuine stale global state. Run ANOVA,
#      then LMM, and without it emlTidy_nRows / emlGlance_nCols /
#      emlAugment_nRows still hold the ANOVA's row and column counts after
#      the LMM call returns — because emlTidyRow/emlGlanceNum/emlAugmentNum
#      APPEND onto whatever is already in those arrays (see emlTidyRow in
#      eml-result-writer.praat: "emlTidy_nRows = emlTidy_nRows + 1"), and
#      @emlRunLMMAnalysis calls none of the emlDeclare* procedures that
#      would otherwise clear them via @emlResultBegin.
#
#   2. BUT in both cases — with the fix and without it — the user-visible
#      symptom the original report described (an export under the LMM's
#      base name whose glance says "One-way ANOVA") does NOT reproduce on
#      the code this repo ships. @emlExportResultFiles branches on
#      emlResult_declared alone (eml-output.praat, @emlExportResultFiles:
#      ".declared = 0 / if variableExists (\"emlResult_declared\") ...").
#      emlResult_declared is zeroed unconditionally by @emlCSVInit
#      (eml-output.praat: "emlResult_declared = 0", no condition on it), and
#      @emlRunLMMAnalysis has called @emlCSVInit at entry since 14 August
#      2026 (commit 8716191b, "the LMM inherited the previous analysis's
#      declaration" — its own message: "Fixed with @emlCSVInit at entry ...
#      Confirmed by re-running the reproduction: declared=0, nWritten=0,
#      reason=empty, no files."). @emlResultClearAll was added three weeks
#      later, 1 September 2026, and never touches emlResult_declared. So the
#      export path was already closed, by a different fix, weeks before this
#      one landed — a fact this file demonstrates directly below rather than
#      taking on faith, and which the shipped comment in eml-lmm.praat did
#      not say correctly until this pass corrected it (it read "Calling
#      @emlResultClearAll ensures the LMM export is ... never stale", which
#      credits this call with something @emlCSVInit alone already does).
#
# So: KEEP THE FIX, DESCRIBE IT ACCURATELY. It is real defensive hardening
# of the collector globals — those globals are read directly by code other
# than @emlExportResultFiles (nothing today, but @emlTidyRow's append
# behaviour means any FUTURE declaring code added to @emlRunLMMAnalysis
# would silently continue a prior analysis's rows without it) — and it is
# not, contrary to the comment as wave one left it, what makes today's
# export honest. That is item #1 above; item #2, the non-finding, is exactly
# as interesting and is asserted with equal weight below.
#
# WHAT THIS FILE ACTUALLY DOES
#
# It drives the real path: builds a demo table, runs @emlRunAnovaAnalysis
# (which declares and populates tidy/glance/augment), then runs
# @emlRunLMMAnalysis on the SAME table with the SAME data columns, exactly
# docs/API_EXPORT.md's own worked example ("Known trap: do not export after
# a mixed model", SPL_dB ~ vibrato_rate_Hz + (1 | voice_type)), then calls
# @emlExportResultFiles and inspects both the returned state and the files
# actually written to disk.
#
# It runs that drive THREE times against the INSTALLED plugin copy
# (~/.praat-dir/plugin_EML_StatsGraphs/ — never the repo tree, which this
# file only reads):
#
#   green_before — the repo's eml-lmm.praat as committed (fix present)
#   red          — a COPY of that file with the "@emlResultClearAll" call
#                  commented out, installed in its place
#   green_after  — the original repo file re-installed, to prove the
#                  restore is exact and the suite ends in the state it
#                  started in
#
# and it checksums the repo file (sha256) before red is installed and after
# green_after is restored, and checksums green_after's installed copy
# against the repo file, so a re-run of this suite is itself the
# verification artifact the standing ruling requires — not a transcript
# pasted into a report that nobody can re-execute.
#
# The discriminating assertion is on the COLLECTOR STATE after the LMM call
# (tidy/glance/augment row and column counts), because that is the one
# observable that actually differs between green and red — the export
# state does not, and asserting equality there in both arms is the point,
# not a gap in coverage.
#
# Base R only, plus the `sha256sum` and `praat6630` binaries already
# required by this container (see CLAUDE.md / the environment notes this
# suite runs under). No R packages.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

PRAAT_BIN       <- Sys.getenv("EML_PRAAT_BIN", unset = "praat6630")
INSTALL_ROOT    <- path.expand(Sys.getenv("EML_INSTALL_ROOT",
                        unset = "~/.praat-dir/plugin_EML_StatsGraphs"))
INSTALL_SCRIPTS <- file.path(INSTALL_ROOT, "scripts")
INSTALL_LMM     <- file.path(INSTALL_ROOT, "stats", "eml-lmm.praat")
REPO_LMM        <- repo_path("plugin_EML_StatsGraphs", "stats", "eml-lmm.praat")

sha256_file <- function(path) {
    out <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = TRUE)
    strsplit(trimws(out[1]), "\\s+")[[1]][1]
}

# ---------------------------------------------------------------------------
# The gates this file's own coverage depends on, asserted before anything
# else runs — a rename or move of any of these turns "the checks below
# passed" into "the checks below never ran," which must be a red, not a
# silent skip.
# ---------------------------------------------------------------------------
check_true("v153", "praat6630 is on PATH",
           nzchar(Sys.which(PRAAT_BIN)))
check_true("v153", "sha256sum is on PATH",
           nzchar(Sys.which("sha256sum")))
check_true("v153", "the repo's eml-lmm.praat exists",
           file.exists(REPO_LMM))
check_true("v153", "the installed plugin's scripts/ barrel dir exists",
           dir.exists(INSTALL_SCRIPTS))
check_true("v153", "eml-lib-lmm.praat (the LMM barrel) exists in the install",
           file.exists(file.path(INSTALL_SCRIPTS, "eml-lib-lmm.praat")))

REPO_LMM_TEXT   <- readLines(REPO_LMM, warn = FALSE)
CLEAR_LINE_RE   <- "^\\s*@emlResultClearAll\\s*$"
CLEAR_HITS      <- grep(CLEAR_LINE_RE, REPO_LMM_TEXT)
check_true("v153", "exactly one bare '@emlResultClearAll' call line in eml-lmm.praat",
           length(CLEAR_HITS) == 1L)

if (any(!sapply(list(nzchar(Sys.which(PRAAT_BIN)), nzchar(Sys.which("sha256sum")),
                      file.exists(REPO_LMM), dir.exists(INSTALL_SCRIPTS),
                      file.exists(file.path(INSTALL_SCRIPTS, "eml-lib-lmm.praat")),
                      length(CLEAR_HITS) == 1L), isTRUE))) {
    cat("v153: a precondition gate failed; stopping before driving Praat.\n")
    if (!exists("EML_SUITE")) { eml_report("v153 LMM result-store clear-on-entry"); eml_exit() }
} else {

# ---------------------------------------------------------------------------
# The probe script. Placed INSIDE the installed scripts/ directory when run
# — Praat resolves a relative `include` against the TOP-LEVEL script's own
# directory, not the including file's, so eml-lib-lmm.praat's own
# "include eml-lib-stats.praat" only resolves when the probe lives beside it.
# ---------------------------------------------------------------------------
probe_source <- function(outdir, tag) {
    paste0(
        'include eml-lib-lmm.praat\n\n',
        'outdir$ = "', outdir, '"\n',
        'createFolder: outdir$\n',
        'random_initializeWithSeedUnsafelyButPredictably (20260901)\n\n',
        'writeInfoLine: "V153 PROBE ', tag, '"\n',
        '@emlDemoTable: 2, 20260901\n',
        'data = emlDemoTable.tableId\n\n',
        '@emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1\n',
        'appendInfoLine: "PRE_TIDY=", emlTidy_nRows\n',
        'appendInfoLine: "PRE_GLANCE=", emlGlance_nCols\n',
        'appendInfoLine: "PRE_DECLARED=", emlResult_declared\n\n',
        'selectObject: data\n',
        '@emlRunLMMAnalysis: data, "SPL_dB ~ vibrato_rate_Hz + (1 | voice_type)", "treatment", 1, 0, 0\n',
        'appendInfoLine: "LMM_ERROR=", emlRunLMMAnalysis.error$\n',
        'appendInfoLine: "POST_TIDY=", emlTidy_nRows\n',
        'appendInfoLine: "POST_GLANCE=", emlGlance_nCols\n',
        'appendInfoLine: "POST_AUGMENT=", emlAugment_nRows\n',
        'appendInfoLine: "POST_DECLARED=", emlResult_declared\n\n',
        'selectObject: data\n',
        '@emlExportResultFiles: outdir$, "lmm_probe"\n',
        'appendInfoLine: "EXPORT_DECLARED=", emlExportResultFiles.declared\n',
        'appendInfoLine: "EXPORT_SUCCESS=", emlExportResultFiles.success\n',
        'appendInfoLine: "EXPORT_NWRITTEN=", emlExportResultFiles.nWritten\n',
        'appendInfoLine: "EXPORT_REASON=", emlExportResultFiles.reason$\n\n',
        'Create Strings as file list: "flist", outdir$ + "/lmm_probe*"\n',
        'nf = Get number of strings\n',
        'appendInfoLine: "EXPORT_NFILES=", nf\n',
        'contaminated = 0\n',
        'for fidx to nf\n',
        '    selectObject: "Strings flist"\n',
        '    fn$ = Get string: fidx\n',
        '    ftxt$ = readFile$ (outdir$ + "/" + fn$)\n',
        '    if index (ftxt$, "One-way ANOVA") > 0\n',
        '        contaminated = 1\n',
        '    endif\n',
        'endfor\n',
        'appendInfoLine: "EXPORT_CONTAMINATED=", contaminated\n',
        'appendInfoLine: "V153 PROBE END"\n'
    )
}

parse_probe <- function(lines) {
    grab <- function(key) {
        hit <- grep(paste0("^", key, "="), lines, value = TRUE)
        if (!length(hit)) return(NA_character_)
        sub(paste0("^", key, "="), "", hit[1])
    }
    list(
        raw          = lines,
        ok           = any(grepl("^V153 PROBE END$", lines)),
        pre_tidy     = suppressWarnings(as.integer(grab("PRE_TIDY"))),
        pre_glance   = suppressWarnings(as.integer(grab("PRE_GLANCE"))),
        pre_declared = suppressWarnings(as.integer(grab("PRE_DECLARED"))),
        lmm_error    = grab("LMM_ERROR"),
        post_tidy    = suppressWarnings(as.integer(grab("POST_TIDY"))),
        post_glance  = suppressWarnings(as.integer(grab("POST_GLANCE"))),
        post_augment = suppressWarnings(as.integer(grab("POST_AUGMENT"))),
        post_declared= suppressWarnings(as.integer(grab("POST_DECLARED"))),
        exp_declared = suppressWarnings(as.integer(grab("EXPORT_DECLARED"))),
        exp_nwritten = suppressWarnings(as.integer(grab("EXPORT_NWRITTEN"))),
        exp_reason   = grab("EXPORT_REASON"),
        exp_nfiles   = suppressWarnings(as.integer(grab("EXPORT_NFILES"))),
        exp_contam   = suppressWarnings(as.integer(grab("EXPORT_CONTAMINATED")))
    )
}

# Runs one probe against whatever is CURRENTLY installed at INSTALL_LMM.
run_probe <- function(tag) {
    outdir  <- file.path(tempdir(), paste0("v153_out_", tag, "_", Sys.getpid()))
    unlink(outdir, recursive = TRUE)
    probe_name <- paste0(".v153_probe_", tag, "_", Sys.getpid(), ".praat")
    probe_path <- file.path(INSTALL_SCRIPTS, probe_name)
    writeLines(probe_source(outdir, tag), probe_path)
    old_wd <- getwd()
    on.exit({ setwd(old_wd); unlink(probe_path) }, add = TRUE)
    setwd(INSTALL_SCRIPTS)
    out <- system2(PRAAT_BIN, c("--run", shQuote(probe_name)),
                    stdout = TRUE, stderr = TRUE)
    parsed <- parse_probe(out)
    parsed$stdout <- out
    parsed
}

cat("v153: repo eml-lmm.praat sha256 (baseline) =",
    sha256_baseline <- sha256_file(REPO_LMM), "\n")

# Sync repo -> install so the probe runs against exactly the committed fix,
# regardless of whatever the install copy held before this run.
file.copy(REPO_LMM, INSTALL_LMM, overwrite = TRUE)
check_true("v153", "installed eml-lmm.praat matches repo before the drive",
           sha256_file(INSTALL_LMM) == sha256_baseline)

cat("\nv153: === ARM 1/3 -- green_before (fix present, as committed) ===\n")
green_before <- run_probe("green_before")
cat(paste(green_before$stdout, collapse = "\n"), "\n")

check_true("v153", "green_before: probe ran to completion", green_before$ok)
check_true("v153", "green_before: LMM call itself did not error",
           identical(green_before$lmm_error, ""))
check_true("v153", "green_before: ANOVA actually populated the collectors first (precondition)",
           isTRUE(green_before$pre_tidy > 0) && isTRUE(green_before$pre_glance > 0) &&
           isTRUE(green_before$pre_declared == 1))

# --- THE DISCRIMINATING ASSERTION -------------------------------------------
check_true("v153", "green_before: tidy/glance/augment are ALL clear after the LMM call",
           isTRUE(green_before$post_tidy == 0) && isTRUE(green_before$post_glance == 0) &&
           isTRUE(green_before$post_augment == 0))
# --- documented, non-discriminating (see header): export was already safe --
check_true("v153", "green_before: export never declared (emlCSVInit's independent gate)",
           isTRUE(green_before$exp_declared == 0))
check_true("v153", "green_before: export wrote nothing, reason 'empty'",
           isTRUE(green_before$exp_nwritten == 0) &&
           identical(green_before$exp_reason, "empty"))
check_true("v153", "green_before: no file on disk contains the stale ANOVA method",
           isTRUE(green_before$exp_nfiles == 0) && isTRUE(green_before$exp_contam == 0))

# ---------------------------------------------------------------------------
# ARM 2/3 — install a COPY of the repo file with the fix's call commented
# out. The repo file itself is never opened for writing anywhere in this
# script; only INSTALL_LMM is touched from here down.
# ---------------------------------------------------------------------------
red_text <- REPO_LMM_TEXT
red_text[CLEAR_HITS] <- sub("@emlResultClearAll",
    "; @emlResultClearAll  ; DISABLED by v153's red arm -- restored below",
    red_text[CLEAR_HITS])
writeLines(red_text, INSTALL_LMM)
check_true("v153", "red arm: installed copy now differs from the repo file",
           sha256_file(INSTALL_LMM) != sha256_baseline)

cat("\nv153: === ARM 2/3 -- red (the @emlResultClearAll call disabled) ===\n")
red <- run_probe("red")
cat(paste(red$stdout, collapse = "\n"), "\n")

check_true("v153", "red: probe ran to completion", red$ok)
check_true("v153", "red: LMM call itself did not error", identical(red$lmm_error, ""))

# --- THE SAME DISCRIMINATING ASSERTION MUST NOW FAIL -- so it is inverted --
check_true("v153",
    "red: with the fix removed, tidy/glance/augment now hold the ANOVA's STALE counts",
    isTRUE(red$post_tidy > 0) && isTRUE(red$post_glance > 0) && isTRUE(red$post_augment > 0))
check_true("v153", "red: the stale counts match what ANOVA actually produced",
           isTRUE(red$post_tidy == green_before$pre_tidy) &&
           isTRUE(red$post_glance == green_before$pre_glance))
# --- the non-finding holds EVEN IN THE RED ARM: this is item #2 -----------
check_true("v153", "red: export STILL never declared -- @emlCSVInit's gate, not this fix",
           isTRUE(red$exp_declared == 0))
check_true("v153", "red: export STILL wrote nothing, even with the fix removed",
           isTRUE(red$exp_nwritten == 0) && identical(red$exp_reason, "empty") &&
           isTRUE(red$exp_nfiles == 0) && isTRUE(red$exp_contam == 0))

# ---------------------------------------------------------------------------
# ARM 3/3 — restore, and prove the restore is exact.
# ---------------------------------------------------------------------------
file.copy(REPO_LMM, INSTALL_LMM, overwrite = TRUE)
sha256_after_restore <- sha256_file(INSTALL_LMM)
check_true("v153", "restore: installed copy is byte-identical to the repo file (sha256)",
           sha256_after_restore == sha256_baseline)
check_true("v153", "restore: the repo file itself was never modified by this run (sha256 unchanged)",
           sha256_file(REPO_LMM) == sha256_baseline)

cat("\nv153: === ARM 3/3 -- green_after (restored) ===\n")
green_after <- run_probe("green_after")
cat(paste(green_after$stdout, collapse = "\n"), "\n")

check_true("v153", "green_after: probe ran to completion", green_after$ok)
check_true("v153",
    "green_after: collectors clear again, matching green_before exactly",
    isTRUE(green_after$post_tidy == 0) && isTRUE(green_after$post_glance == 0) &&
    isTRUE(green_after$post_augment == 0))

cat("\nv153: sha256 summary\n")
cat("  repo eml-lmm.praat, baseline       ", sha256_baseline, "\n")
cat("  repo eml-lmm.praat, after this run ", sha256_file(REPO_LMM), "\n")
cat("  installed copy, after restore      ", sha256_after_restore, "\n")

if (!exists("EML_SUITE")) { eml_report("v153 LMM result-store clear-on-entry"); eml_exit() }

} # precondition gate
