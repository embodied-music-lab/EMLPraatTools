# ============================================================================
# v141_r1_settings_permutation.R -- Risk R1's settings-permutation drive
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR.
#
# docs/RISK_REGISTER_2026-08-25.md, R1 ("Cross-lane interactions in the
# reprint rule"): "Inspection: the whole-house pass runs ONLY after every
# text-changing lane has landed, and includes a settings-permutation drive --
# same data, every display setting toggled between draws -- asserting zero
# reprints."
#
# THE SETTINGS UNDER TEST are the four @emlBridgeGroupComparison itself takes
# as arguments and validate/v112's own census (section 2, DISPLAY_ONLY)
# classifies as display-only for that door: .style$ (p-value / stars / both),
# .showNS, .showEffect, .layoutMode (brackets / matrix). The census is the
# authority on what counts as display-only here -- this file does not
# reclassify anything, it asks whether the bridge's own behaviour agrees with
# a classification v112 already ratchets against the source.
#
# THE CLAIM UNDER TEST, PER R1's OWN WORDING: toggling a DISPLAY setting must
# never cause a reprint. Read against @emlConsumeGroupResult's own verdict
# vocabulary (docs/RULING_RESULT_STORE.md section c and the read side's own
# header in eml-annotation-procedures.praat), "zero reprints" is two
# assertions per draw: the verdict must never become "settings" (that is the
# vocabulary's own name for the case that DOES reprint, with its one
# announcement line), and no "Recomputed:" line may be printed. A verdict of
# "consume" is what R1 asks for; a verdict of "none" or "data" would be a
# DIFFERENT failure (the store not being consulted at all, or the guard
# thinking the data moved when only a display choice did) and is called out
# by name rather than folded into "not settings".
#
# harness/settingspermute/probe.praat drives one published analysis and then
# six draws -- two values of each of the four settings, one setting moved at
# a time, every result-affecting setting (test type, correction, alpha, group
# sort) held fixed at what the published analysis used. Each draw's own leg
# name records which setting moved.
#
# A SCRIPT ABORT IS A FAIL, NOT A SKIP. Same discipline as v114 and v140: a
# probe that did not reach its final sentinel has told this file nothing, and
# every assertion below is written so a missing measurement fails rather than
# reading as "no evidence either way".
#
# @emlBridgeGroupComparison's call site to @emlPublishAnalysisResult now
# passes the full argument list in the same order as the shipped signature
# (stats/eml-extract.praat) -- thirty-seven on both sides of the call -- the
# same call site validate/v140's header describes for the reprint pins,
# because it is the identical call site. A draw that recomputes and has a
# pairwise result to publish runs to completion, for any display setting
# under test. R1's drive and section (c)'s pins read against the same one
# call site, not six or two different ones.
#
# THE STANDARD KIT.
#   POPULATION: the six leg names, read out of the TSV rather than assumed --
#   a probe that silently dropped one leg is caught by the ratchet, not by a
#   hand count.
#   ONE PROPERTY PER LEG: verdict != "settings" and no reprint line, for
#   every leg -- what "zero reprints" means, applied uniformly.
#   THE RATCHET, BOTH WAYS: exactly the six required legs, no fewer and none
#   ungraded.
#   A FAILURE IF IT WALKED ZERO MEMBERS: section 0's resolver gate.
#   NO SYNTHETIC BREAK TEST IS LAYERED ON TOP: the legs are read straight off
#   harness/settingspermute/run.sh's own transcript and TSV, reproducible by
#   re-running it at this commit.
#
# Reads harness/settingspermute/out/{transcript.txt, exit_status.txt,
# SETTINGSPERMUTE.tsv}, written by harness/settingspermute/run.sh.
# $EML_SPM_OUT overrides the directory.
#
# Base R only. Drives nothing; reads three files.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v141"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

spm_dir <- Sys.getenv("EML_SPM_OUT", unset = "")
if (!nzchar(spm_dir)) spm_dir <- repo_path("harness", "settingspermute", "out")

tsv_path   <- file.path(spm_dir, "SETTINGSPERMUTE.tsv")
trans_path <- file.path(spm_dir, "transcript.txt")
exit_path  <- file.path(spm_dir, "exit_status.txt")

REQUIRED_LEGS <- c("style_pvalue", "style_stars",
                   "shownsigns_0", "shownsigns_1",
                   "showeffect_0", "showeffect_1",
                   "layout_brackets", "layout_matrix")

WHICH_SETTING <- c(
    style_pvalue = "emlBridgeGroupComparison.style$",
    style_stars = "emlBridgeGroupComparison.style$",
    shownsigns_0 = "emlBridgeGroupComparison.showNS",
    shownsigns_1 = "emlBridgeGroupComparison.showNS",
    showeffect_0 = "emlBridgeGroupComparison.showEffect",
    showeffect_1 = "emlBridgeGroupComparison.showEffect",
    layout_brackets = "emlBridgeGroupComparison.layoutMode",
    layout_matrix = "emlBridgeGroupComparison.layoutMode")

# ---------------------------------------------------------------------------
# 0. THE DRIVE COMPLETED -- THE RESOLVER GATE
# ---------------------------------------------------------------------------
ok_trans <- check_true(V, "the settings-permutation transcript is present",
                       file.exists(trans_path))
ok_exit  <- check_true(V, "the settings-permutation exit-status file is present",
                       file.exists(exit_path))

transcript <- if (ok_trans) readLines(trans_path, warn = FALSE) else character(0)
exit_code  <- if (ok_exit) suppressWarnings(as.integer(trimws(
                  readLines(exit_path, warn = FALSE)[1]))) else NA_integer_

check_true(V,
           sprintf("the probe process exited cleanly (exit %s)",
                   if (is.na(exit_code)) "unknown" else exit_code),
           identical(exit_code, 0L))

drive_complete <- ok_trans && any(transcript == "=== SENTINEL: PROBE COMPLETE ===")
check_true(V,
           "the drive reached its final sentinel, i.e. it ran to completion",
           drive_complete)

if (!drive_complete && length(transcript)) {
    err_lines <- grep("^Error:|not performed or completed|not completed\\.$",
                      transcript, value = TRUE)
    if (length(err_lines))
        cat("\n  TRANSCRIPT'S OWN ERROR TEXT:\n    ",
            paste(utils::head(err_lines, 6), collapse = "\n    "), "\n", sep = "")
}

ev <- data.frame(leg = character(0), field = character(0),
                 value = character(0), stringsAsFactors = FALSE)
if (file.exists(tsv_path)) {
    raw <- readLines(tsv_path, warn = FALSE)
    raw <- raw[nzchar(raw)]
    if (length(raw) > 1) {
        raw <- raw[-1]
        rows <- strsplit(raw, "\t", fixed = TRUE)
        ev <- data.frame(
            leg   = vapply(rows, function(r) if (length(r) >= 1) r[1] else "", ""),
            field = vapply(rows, function(r) if (length(r) >= 2) r[2] else "", ""),
            value = vapply(rows, function(r) if (length(r) >= 3) r[3] else "", ""),
            stringsAsFactors = FALSE)
    }
}
val <- function(lg, fl) {
    i <- which(ev$leg == lg & ev$field == fl)
    if (!length(i)) NA_character_ else ev$value[i[length(i)]]
}

# ---------------------------------------------------------------------------
# 1. THE POPULATION -- DERIVED FROM THE TSV, RATCHETED BOTH WAYS
# ---------------------------------------------------------------------------
population <- sort(unique(ev$leg[nzchar(ev$leg)]))
check_true(V,
           sprintf("RESOLVER: the probe's TSV names a nonzero population (%d legs)",
                   length(population)),
           length(population) > 0)

missing <- setdiff(REQUIRED_LEGS, population)
extra   <- setdiff(population, REQUIRED_LEGS)
check_true(V,
           sprintf("every required display-setting leg is present%s",
                   if (length(missing))
                       paste0(" -- MISSING: ", paste(missing, collapse = ", "))
                   else ""),
           length(missing) == 0)
check_true(V,
           sprintf("no leg is present that this file does not recognise%s",
                   if (length(extra))
                       paste0(" -- UNGRADED: ", paste(extra, collapse = ", "))
                   else ""),
           length(extra) == 0)

# ---------------------------------------------------------------------------
# 2. ONE PROPERTY PER LEG: TOGGLING A DISPLAY SETTING CAUSES ZERO REPRINTS
# ---------------------------------------------------------------------------
for (leg in REQUIRED_LEGS) {
    verdict <- val(leg, "verdict")
    note    <- val(leg, "note")
    setting <- WHICH_SETTING[[leg]]

    check_true(V,
               sprintf("%s (%s): verdict is not \"settings\" -- toggling this display setting must not trigger a reprint (saw %s)",
                       leg, setting,
                       if (is.na(verdict)) "no measurement" else verdict),
               drive_complete && !is.na(verdict) && verdict != "settings")

    check_true(V,
               sprintf("%s (%s): no \"Recomputed:\" announcement was printed (saw %s)",
                       leg, setting,
                       if (is.na(note) || !nzchar(note)) "nothing"
                       else shQuote(note)),
               drive_complete && (is.na(note) || !nzchar(note) ||
                                  !grepl("^Recomputed:", note)))
}

# ---------------------------------------------------------------------------
# 3. THE RESOLVER GATE
# ---------------------------------------------------------------------------
n_walked <- length(intersect(population, REQUIRED_LEGS))
check_true(V,
           sprintf("RESOLVER: %d of %d required display-setting legs were walked and graded",
                   n_walked, length(REQUIRED_LEGS)),
           n_walked > 0)

attest(V, "the settings-permutation evidence these numbers came from",
       sprintf("%s | %s | %s", tsv_path, trans_path, exit_path))

if (!exists("EML_SUITE")) {
    eml_report(sprintf(
        "v141 R1 settings permutation: drive %s; %d/%d legs walked",
        if (drive_complete) "completed" else "DID NOT COMPLETE",
        n_walked, length(REQUIRED_LEGS)))
    eml_exit()
}
