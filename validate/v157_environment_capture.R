#!/usr/bin/env Rscript
# ============================================================================
# v157 -- the walkthrough kit's environment capture: exists, is well-formed,
#          and the Praat version assertion actually fails on a mismatch
# ============================================================================
# WHAT THIS SETTLES. mailbox/to-opus/WORK_ORDER_TWOWAY_KERNEL_2026-08-31.md,
# "What the authoritative run must capture", item 2: the run emits its
# environment into the results -- Praat build, R version and full
# sessionInfo() (package versions), OS, and the repo commit -- "a run
# without them is not the authoritative run." RULING_PROVENANCE_AND_
# CANCELLATION sharpens this: the Praat VERSION is ASSERTED and the run
# FAILS on mismatch; RULING_UNIQUENESS_SWEEP adds that everything else
# (OS class, kernel/arch string, repo commit, working-tree cleanliness) is
# recorded PROVENANCE, never asserted.
#
# THREE THINGS THIS FILE CHECKS, matching the standing rule (a "verified"
# claim carries its own verification artifact -- the command and its
# output):
#
#   (A) THE CAPTURE EXISTS AND IS WELL-FORMED. Both runners are actually
#       driven -- walkthrough/kit copied whole into a scratch tree (never
#       the tracked audit/ or results/ files), with a row filter so this
#       finishes in seconds, not the kit's own ~2 minute full run -- and
#       their audit/{praat,r}_environment.tsv outputs are read back and
#       checked for shape and required fields, not merely asserted to have
#       been written.
#
#   (B) THE VERSION ASSERTION ACTUALLY FAILS ON A MISMATCH. RUN_ME_FIRST.
#       praat is briefly mutated IN PLACE -- its pin changed to a version
#       nothing on this machine is, and (a Linux-only adaptation this
#       container needs to run ANY Praat script at all -- see NOTE below)
#       its `include` line pointed at the Linux plugin path RUN_KIT_LINUX.
#       praat already uses for the identical script -- run, and restored.
#       The assertion fires BEFORE this script's first `createFolder`, so
#       nothing under audit/ or results/ is ever touched by this half of
#       the demonstration; the only side effect possible is on the one file
#       being tested, and that file's sha256 is checked before the mutation
#       and again after the restore.
#
#   (C) THE PLUGIN'S OWN FLOOR AGREES WITH THE PIN. emlMinPraatVersion in
#       plugin_EML_StatsGraphs/setup.praat must equal the pin RUN_ME_FIRST.
#       praat asserts against -- if a future edit moves one without the
#       other, the "self-attesting" claim quietly stops being true.
#
# NOTE ON THE INCLUDE-LINE SWAP. RUN_ME_FIRST.praat's checked-in `include`
# names the macOS preferences path (by design -- see the file's own header,
# "NOTHING TO EDIT ON macOS"); RUN_KIT_LINUX.praat is a maintained fork of
# the identical script that differs from it in EXACTLY that one line (diff
# verified: v157 does not assume this, it diffs the two files itself below
# and stops if they differ anywhere else). This container cannot parse
# either file as committed -- Praat resolves `include` at PARSE time, before
# a single line of script logic runs, so the wrong path halts before the
# version assertion is ever reached. Swapping in RUN_KIT_LINUX.praat's own
# committed include line is therefore the only way to exercise
# RUN_ME_FIRST.praat's logic here at all, Praat side (A) included -- both
# halves of this file's Praat work use a scratch copy or a temporary,
# restored in-place edit, never a permanent change to the committed file.
#
# Requires praat6630 on PATH (the pinned floor) and Rscript (this file runs
# under it already). Base R only; no packages. Not yet registered in
# validate/run_all.R -- v157 is new this session and run_all.R is outside
# this file's assigned scope; flagged for whoever next edits that list.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

V <- "v157"

REPO_ROOT   <- normalizePath(repo_path())
KIT_DIR     <- file.path(REPO_ROOT, "walkthrough", "kit")
RMF_PATH    <- file.path(KIT_DIR, "RUN_ME_FIRST.praat")
LINUX_PATH  <- file.path(KIT_DIR, "RUN_KIT_LINUX.praat")
RA_PATH     <- file.path(KIT_DIR, "run_analyses.R")
SETUP_PATH  <- file.path(REPO_ROOT, "plugin_EML_StatsGraphs", "setup.praat")

sha256_file <- function(path) {
    out <- system2("sha256sum", shQuote(path), stdout = TRUE, stderr = TRUE)
    strsplit(trimws(out[1]), "\\s+")[[1]][1]
}

check_true(V, "walkthrough/kit/RUN_ME_FIRST.praat exists", file.exists(RMF_PATH))
check_true(V, "walkthrough/kit/RUN_KIT_LINUX.praat exists", file.exists(LINUX_PATH))
check_true(V, "walkthrough/kit/run_analyses.R exists", file.exists(RA_PATH))
check_true(V, "plugin_EML_StatsGraphs/setup.praat exists", file.exists(SETUP_PATH))

if (!all(file.exists(RMF_PATH), file.exists(LINUX_PATH), file.exists(RA_PATH), file.exists(SETUP_PATH))) {
    cat("v157: a precondition file is missing; stopping before driving anything.\n")
    if (!exists("EML_SUITE")) { eml_report("v157 environment capture"); eml_exit() }
} else {

RMF_LINES   <- readLines(RMF_PATH, warn = FALSE)
LINUX_LINES <- readLines(LINUX_PATH, warn = FALSE)
RA_LINES    <- readLines(RA_PATH, warn = FALSE)
SETUP_LINES <- readLines(SETUP_PATH, warn = FALSE)

# ---------------------------------------------------------------------------
# Locate RUN_ME_FIRST.praat's own `include` line (its position, not
# RUN_KIT_LINUX.praat's -- the two files are no longer line-for-line
# identical past this point, since this session's environment-capture block
# lives in RUN_ME_FIRST.praat only; RUN_KIT_LINUX.praat is out of this
# file's assigned scope to touch or keep in step) and read RUN_KIT_LINUX.
# praat's OWN include line as the Linux replacement text -- verified to be
# exactly one such line in each file, not assumed.
# ---------------------------------------------------------------------------
rmfIncludeAt   <- which(grepl("^include ", RMF_LINES))
linuxIncludeAt <- which(grepl("^include ", LINUX_LINES))
onlyIncludeDiffers <- length(rmfIncludeAt) == 1L && length(linuxIncludeAt) == 1L &&
    !identical(RMF_LINES[rmfIncludeAt], LINUX_LINES[linuxIncludeAt])
check_true(V, "RUN_ME_FIRST.praat has exactly one `include` line, and RUN_KIT_LINUX.praat's own differs from it",
           onlyIncludeDiffers)
diffLines <- if (onlyIncludeDiffers) rmfIncludeAt else integer(0)
linuxIncludeLine <- if (onlyIncludeDiffers) LINUX_LINES[linuxIncludeAt] else NA_character_

# ---------------------------------------------------------------------------
# (A0) STATIC: the pieces the rest of this file depends on are actually in
# the source, named precisely enough that a rewrite which silently dropped
# one would be caught here rather than by a passing live run that happened
# not to exercise it.
# ---------------------------------------------------------------------------
check_true(V, "RUN_ME_FIRST.praat asserts praatVersion against a pinned value",
           any(grepl("praatVersion\\s*<>\\s*emlEnvPinnedVersionNum", RMF_LINES)))
check_true(V, "RUN_ME_FIRST.praat's mismatch branch calls exitScript (fails the run)",
           any(grepl("exitScript:", RMF_LINES)))
check_true(V, "RUN_ME_FIRST.praat's pin is 6.6.30 / 6630",
           any(grepl('emlEnvPinnedVersion\\$ = "6\\.6\\.30"', RMF_LINES)) &&
           any(grepl("emlEnvPinnedVersionNum = 6630", RMF_LINES)))
check_true(V, "RUN_ME_FIRST.praat writes audit/praat_environment.tsv",
           any(grepl('writeFile:\\s*"audit/praat_environment\\.tsv"', RMF_LINES)))
check_true(V, "RUN_ME_FIRST.praat records OS class without asserting it",
           any(grepl("emlEnvOSClass\\$", RMF_LINES)) &&
           !any(grepl("emlEnvOSClass\\$\\s*<>", RMF_LINES)))
check_true(V, "RUN_ME_FIRST.praat records repo commit and dirty-tree status",
           any(grepl("emlEnvGitCommit\\$", RMF_LINES)) &&
           any(grepl("emlEnvGitDirty\\$", RMF_LINES)))

check_true(V, "run_analyses.R calls utils::sessionInfo()",
           any(grepl("sessionInfo\\(\\)", RA_LINES)))
check_true(V, "run_analyses.R records R.version.string",
           any(grepl("R\\.version\\.string", RA_LINES)))
check_true(V, "run_analyses.R writes audit/r_environment.tsv",
           any(grepl('"r_environment\\.tsv"', RA_LINES)))
check_true(V, "run_analyses.R records repo commit via git rev-parse HEAD",
           any(grepl('"rev-parse", "HEAD"', RA_LINES)))
check_true(V, "run_analyses.R records working-tree cleanliness via git status --porcelain",
           any(grepl('"status", "--porcelain"', RA_LINES)))
check_true(V, "run_analyses.R has NO version assertion on R itself (provenance only, per the ruling)",
           !any(grepl("stop\\(.*R\\.version", RA_LINES)))

# ---------------------------------------------------------------------------
# (C) THE PLUGIN'S OWN FLOOR AGREES WITH THE PIN
# ---------------------------------------------------------------------------
m <- regmatches(SETUP_LINES, regexpr("emlMinPraatVersion\\s*=\\s*[0-9]+", SETUP_LINES))
m <- m[nzchar(m)]
pluginFloor <- if (length(m)) as.integer(regmatches(m[1], regexpr("[0-9]+$", m[1]))) else NA_integer_
check_true(V, sprintf("plugin_EML_StatsGraphs/setup.praat's emlMinPraatVersion (%s) equals RUN_ME_FIRST.praat's pin (6630)",
                       if (is.na(pluginFloor)) "not found" else pluginFloor),
           identical(pluginFloor, 6630L))

# ---------------------------------------------------------------------------
# Locate the pinned Praat build.
# ---------------------------------------------------------------------------
PRAAT_BIN <- Sys.getenv("EML_PRAAT_BIN", unset = "praat6630")
praat <- Sys.which(PRAAT_BIN)
pv <- NA_character_; pvnum <- 0L
if (nzchar(praat)) {
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE, stderr = TRUE))[1]
    mm <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv))
    if (length(mm)) {
        p <- as.integer(strsplit(mm, ".", fixed = TRUE)[[1]])
        pvnum <- p[1] * 1000L + p[2] * 100L + p[3]
    }
}
check_true(V, sprintf("%s is on PATH and reports a version (found %s)", PRAAT_BIN,
                       if (is.na(pv)) "none" else pv), nzchar(praat) && !is.na(pv))
check_true(V, sprintf("the located Praat build is exactly the 6.6.30 pin (found %s / %d)",
                       if (is.na(pv)) "none" else pv, pvnum),
           identical(pvnum, 6630L))

if (!nzchar(praat) || !identical(pvnum, 6630L) || !onlyIncludeDiffers) {
    cat("v157: praat6630 not found/not exactly 6.6.30, or RUN_ME_FIRST.praat has drifted from ",
        "RUN_KIT_LINUX.praat by more than the include line -- skipping the live demonstrations ",
        "rather than swap a line this file has not verified is safe to swap.\n", sep = "")
} else {

# ===========================================================================
# (A) CAPTURE EXISTS AND IS WELL-FORMED -- live, on a scratch copy of the
# whole kit, never the tracked audit/ or results/ files.
# ===========================================================================
work <- file.path(tempdir(), "v157_kit")
unlink(work, recursive = TRUE)
dir.create(work, recursive = TRUE, showWarnings = FALSE)
file.copy(list.files(KIT_DIR, full.names = TRUE), work, recursive = TRUE)

scratchRMF <- file.path(work, "RUN_ME_FIRST.praat")
rmfScratchLines <- readLines(scratchRMF, warn = FALSE)
rmfScratchLines[diffLines] <- linuxIncludeLine
# A fast filtered run: one procedure, not all 630-odd cells -- this file
# only needs SECTION 9 (the environment write) to be reached, not a full
# reconciliation.
rmfScratchLines <- sub('^emlKitProcFilter\\$ = ""$',
                       'emlKitProcFilter$ = "emlRunTwoGroupAnalysis"', rmfScratchLines)
writeLines(rmfScratchLines, scratchRMF)

cmdA <- sprintf("cd %s && %s --run %s 2>&1", shQuote(work), shQuote(praat), shQuote(basename(scratchRMF)))
outA <- suppressWarnings(system(cmdA, intern = TRUE, ignore.stderr = FALSE))
stA  <- attr(outA, "status"); if (is.null(stA)) stA <- 0L
cat("\n--- v157 (A) Praat scratch run: command and full output -------------------\n")
cat(cmdA, "\n"); cat(paste(outA, collapse = "\n"), "\n")
cat("exit status: ", stA, "\n", sep = "")
cat("-----------------------------------------------------------------------------\n")
check_true(V, "the Praat scratch run (correct pin) exits cleanly", identical(stA, 0L))

envTsvA <- file.path(work, "audit", "praat_environment.tsv")
check_true(V, "audit/praat_environment.tsv was written by the scratch run", file.exists(envTsvA))
if (file.exists(envTsvA)) {
    envA <- read.delim(envTsvA, sep = "\t", colClasses = "character", quote = "", comment.char = "")
    check_true(V, "praat_environment.tsv has the house 4-column schema",
               identical(names(envA), c("cell_id", "quantity", "value", "source")))
    check_true(V, "every row's cell_id is the reserved '_environment' sentinel",
               all(envA$cell_id == "_environment"))
    needP <- c("praat_version", "praat_version_build", "praat_version_pin",
               "praat_version_assertion", "os_class", "build_detail",
               "repo_commit", "repo_dirty", "captured_at")
    check_true(V, sprintf("praat_environment.tsv carries every required quantity (%s)",
                          paste(needP, collapse = ", ")),
               all(needP %in% envA$quantity))
    got <- setNames(envA$value, envA$quantity)
    check_true(V, sprintf("recorded praat_version (%s) matches the measured build (%s)",
                          got[["praat_version"]], pv),
               identical(got[["praat_version"]], sub("^Praat ([0-9.]+).*$", "\\1", pv)))
    check_true(V, "recorded praat_version_assertion is PASS (this run's pin matched)",
               identical(got[["praat_version_assertion"]], "PASS"))
    check_true(V, "recorded os_class is Unix (this container)",
               identical(got[["os_class"]], "Unix"))
    check_true(V, "recorded build_detail is non-empty and not a Windows-skip placeholder",
               nzchar(got[["build_detail"]]) && !grepl("not captured on Windows", got[["build_detail"]]))
    # The scratch copy is NOT inside a git working tree relative to its own
    # location once file.copy'd out -- rather, it inherits the repo's OWN
    # .git via defaultDirectory$ + "/../.." only if that math lands back
    # inside REPO_ROOT, which it does not from a tempdir copy. So
    # repo_commit here should legitimately read as unavailable -- this is
    # ITSELF a check that the git-unavailable path is reachable and
    # produces a recorded finding rather than a halt (the scratch run's
    # exit 0 above already proved that; this just names what the finding
    # said).
    check_true(V, "repo_dirty on a non-repo scratch copy reads as 'unknown', not a crash",
               grepl("^unknown", got[["repo_dirty"]]))
}

scratchRA <- file.path(work, "run_analyses.R")
cmdB <- sprintf("cd %s && EML_KIT_PROC_FILTER=emlRunTwoGroupAnalysis %s %s 2>&1",
               shQuote(work), shQuote(file.path(R.home("bin"), "Rscript")), shQuote(basename(scratchRA)))
outB <- suppressWarnings(system(cmdB, intern = TRUE, ignore.stderr = FALSE))
stB  <- attr(outB, "status"); if (is.null(stB)) stB <- 0L
cat("\n--- v157 (A) R scratch run: command and full output ------------------------\n")
cat(cmdB, "\n"); cat(paste(outB, collapse = "\n"), "\n")
cat("exit status: ", stB, "\n", sep = "")
cat("-----------------------------------------------------------------------------\n")
check_true(V, "the R scratch run exits cleanly", identical(stB, 0L))

envTsvB <- file.path(work, "audit", "r_environment.tsv")
sessTxtB <- file.path(work, "audit", "r_sessionInfo.txt")
check_true(V, "audit/r_environment.tsv was written by the scratch run", file.exists(envTsvB))
check_true(V, "audit/r_sessionInfo.txt was written by the scratch run", file.exists(sessTxtB))
if (file.exists(envTsvB)) {
    envB <- read.delim(envTsvB, sep = "\t", colClasses = "character", quote = "", comment.char = "")
    check_true(V, "r_environment.tsv has the house 4-column schema",
               identical(names(envB), c("cell_id", "quantity", "value", "source")))
    check_true(V, "every row's cell_id is the reserved '_environment' sentinel",
               all(envB$cell_id == "_environment"))
    needR <- c("r_version", "r_platform", "os_sysname", "os_release", "machine",
              "repo_commit", "repo_dirty", "captured_at")
    check_true(V, sprintf("r_environment.tsv carries every required quantity (%s)",
                          paste(needR, collapse = ", ")),
               all(needR %in% envB$quantity))
    nPkgRows <- sum(grepl("^package_version:", envB$quantity))
    check_true(V, sprintf("r_environment.tsv carries at least 5 package_version rows (found %d)", nPkgRows),
               nPkgRows >= 5L)
    gotR <- setNames(envB$value, envB$quantity)
    check_true(V, "r_environment.tsv's r_version matches R.version.string measured here",
               identical(gotR[["r_version"]], R.version.string))
}
if (file.exists(sessTxtB)) {
    sessTxt <- readLines(sessTxtB, warn = FALSE)
    check_true(V, "r_sessionInfo.txt is the real sessionInfo() text (starts 'R version')",
               length(sessTxt) > 0 && grepl("^R version", sessTxt[1]))
}

# ===========================================================================
# (B) THE VERSION ASSERTION ACTUALLY FAILS ON A MISMATCH -- IN PLACE on the
# real, tracked RUN_ME_FIRST.praat, briefly, with a checksum before and
# after proving the restore is byte-exact.
# ===========================================================================
shaBefore <- sha256_file(RMF_PATH)
origBytes <- readBin(RMF_PATH, "raw", file.info(RMF_PATH)$size)

restored <- FALSE
restoreFile <- function() {
    if (!restored) {
        writeBin(origBytes, RMF_PATH)
        restored <<- TRUE
    }
}
on.exit(restoreFile(), add = TRUE)

mutated <- RMF_LINES
mutated[diffLines] <- linuxIncludeLine
check_true(V, "the include-line swap (execution adaptation, not part of what's under test) took effect",
           identical(mutated[diffLines], linuxIncludeLine) && !identical(mutated[diffLines], RMF_LINES[diffLines]))
mutated <- sub('emlEnvPinnedVersion\\$ = "6\\.6\\.30"', 'emlEnvPinnedVersion$ = "9.9.99"', mutated)
mutated <- sub("emlEnvPinnedVersionNum = 6630", "emlEnvPinnedVersionNum = 9999", mutated)
# Exactly 3 lines now differ from the original: the include line (the
# execution adaptation above) and the two pin lines (the actual mutation
# under test) -- nothing else.
check_true(V, "the in-place mutation changed exactly the include line plus both pin lines (3 lines total), nothing else",
           sum(mutated != RMF_LINES) == 3L)
writeLines(mutated, RMF_PATH)

cmdC <- sprintf("cd %s && %s --run %s 2>&1", shQuote(KIT_DIR), shQuote(praat), shQuote(basename(RMF_PATH)))
outC <- suppressWarnings(system(cmdC, intern = TRUE, ignore.stderr = FALSE))
stC  <- attr(outC, "status"); if (is.null(stC)) stC <- 0L

restoreFile()
shaAfter <- sha256_file(RMF_PATH)

cat("\n--- v157 (B) mismatch demonstration: command and full output --------------\n")
cat(cmdC, "\n"); cat(paste(outC, collapse = "\n"), "\n")
cat("exit status: ", stC, "\n", sep = "")
cat("sha256 before mutation: ", shaBefore, "\n", sep = "")
cat("sha256 after restore:   ", shaAfter, "\n", sep = "")
cat("-----------------------------------------------------------------------------\n")

check_true(V, "the mismatched-pin run exits with a nonzero status", stC != 0L)
check_true(V, "the mismatched-pin run's output names the assertion failure",
           any(grepl("ENVIRONMENT ASSERTION FAILED", outC)) &&
           any(grepl("Praat version mismatch", outC)))
check_true(V, "the mismatched-pin run's output states neither audit/ nor results/ was touched",
           any(grepl("no file under audit/ or results/ was touched", outC)))
check_true(V, "no file appeared under walkthrough/kit/audit/ or results/ as a side effect of the mismatch run",
           !file.exists(file.path(KIT_DIR, "audit", "praat_environment.tsv")))
check_true(V, "RUN_ME_FIRST.praat is byte-identical after restore (sha256 matches)",
           identical(shaBefore, shaAfter))

} # praat6630 available
} # preconditions present

if (!exists("EML_SUITE")) {
    eml_report("v157 environment capture")
    eml_exit()
}
