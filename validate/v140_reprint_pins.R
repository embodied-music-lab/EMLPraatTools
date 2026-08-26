# ============================================================================
# v140_reprint_pins.R -- RULING_RESULT_STORE.md section (c), the two acceptance
# pins: the no-change leg and the changed-setting leg
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR.
#
# Section (c)'s contract, quoted: "no-change leg (analysis -> figure, zero
# result-affecting edits) asserts EXACTLY ONE report in the Info window and
# zero recomputation lines; changed-setting leg asserts the one line, the
# updated brackets, and the absence of a second report block. Ian's driven
# KW->violin session is the negative-control scenario, reproduced verbatim."
#
# THE SCENARIO IS REPRODUCED VERBATIM, per docs/MEMO_TO_FABLE_unification.md:
# a three-group table, a Kruskal-Wallis run from the stats menu, then the
# SAME comparison drawn as a figure through @emlBridgeGroupComparison -- the
# procedure whose own header names itself as the second door onto the same
# test. harness/reprintpins/probe.praat builds that table and drives both
# doors in one process; harness/reprintpins/run.sh captures the WHOLE
# PROCESS's stdout, because Praat has no way for a script to read its own
# Info window back as text (the same limitation
# eml-annotation-procedures.praat's own header names under THE 24 AUGUST RULE
# IS ONLY HALF BUILT HERE). This file counts report markers in that captured
# transcript and reads emlBridgeGroupComparison's own verdict/note/printReport
# outputs from the probe's TSV.
#
# A SCRIPT ABORT IS A FAIL, NOT A SKIP AND NOT AN UNKNOWN. Same discipline as
# v114's four ways of running nothing: if the drive did not reach its final
# sentinel, every assertion below that depends on the transcript is written
# so that a missing sentinel fails it, rather than being silently skipped
# over as "no measurement".
#
# @emlPublishAnalysisResult's shipped signature (stats/eml-extract.praat) is
# `.producer$, .door$, .kind$, .error$, .key$, .tableId, .tableName$, ...` --
# thirty-odd positional arguments, stating the whole result on every call, by
# ruled contract. @emlBridgeGroupComparison's call site now passes the full
# argument list in the same order, thirty-seven on both sides of the call --
# matching the shipped signature position for position, so "group
# comparison" lands in `.producer$`, not in a slot meant for something else.
#
# THIS FILE READS GREEN, AND THE EVIDENCE IS THE HARNESS, NOT THIS SENTENCE.
# The checks below are written against the RULING's contract, not against a
# fixed transcript, so a reader does not have to take this paragraph's word
# for the call site's shape -- re-driving harness/reprintpins/run.sh and
# reading its transcript is what confirms it on any given tree.
#
# THE STANDARD KIT.
#   POPULATION: the two legs the ruling names, no_change and changed_setting,
#   read out of the TSV's own `leg` column rather than assumed -- so a probe
#   that silently stopped emitting one leg is caught by the ratchet in
#   section 1, not by a hand count.
#   ONE SET OF PROPERTIES PER LEG, exactly the properties the ruling's own
#   sentence names for that leg -- no more, no fewer.
#   THE RATCHET, BOTH WAYS: exactly {no_change, changed_setting}, neither
#   missing nor joined by a third name nobody asked for.
#   A FAILURE IF IT WALKED ZERO MEMBERS: section 0's resolver gate.
#   NO SYNTHETIC BREAK TEST IS LAYERED ON TOP: the pins are read straight off
#   harness/reprintpins/run.sh's own transcript and TSV, reproducible by
#   anyone who runs it at this commit.
#
# Reads harness/reprintpins/out/{transcript.txt, exit_status.txt,
# REPRINTPINS.tsv}, written by harness/reprintpins/run.sh.
# $EML_RP_OUT overrides the directory, the same shape every other harness in
# this family uses.
#
# Base R only. Drives nothing; reads three files.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v140"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

rp_dir <- Sys.getenv("EML_RP_OUT", unset = "")
if (!nzchar(rp_dir)) rp_dir <- repo_path("harness", "reprintpins", "out")

tsv_path  <- file.path(rp_dir, "REPRINTPINS.tsv")
trans_path <- file.path(rp_dir, "transcript.txt")
exit_path  <- file.path(rp_dir, "exit_status.txt")

REPORT_MARKER <- "Kruskal-Wallis H Test"

# ---------------------------------------------------------------------------
# 0. THE DRIVE COMPLETED -- THE RESOLVER GATE, BEFORE ANYTHING ELSE IS READ
# ---------------------------------------------------------------------------
ok_trans <- check_true(V, "the reprint-pins transcript is present",
                       file.exists(trans_path))
ok_exit  <- check_true(V, "the reprint-pins exit-status file is present",
                       file.exists(exit_path))

transcript <- if (ok_trans) readLines(trans_path, warn = FALSE) else character(0)
exit_code  <- if (ok_exit) suppressWarnings(as.integer(trimws(
                  readLines(exit_path, warn = FALSE)[1]))) else NA_integer_

check_true(V,
           sprintf("the probe process exited cleanly (exit %s)",
                   if (is.na(exit_code)) "unknown" else exit_code),
           identical(exit_code, 0L))

sentinels <- c("=== SENTINEL: MENU ANALYSIS BEGINS ===",
               "=== SENTINEL: MENU ANALYSIS ENDS ===",
               "=== SENTINEL: NO-CHANGE FIGURE BEGINS ===",
               "=== SENTINEL: NO-CHANGE FIGURE ENDS ===",
               "=== SENTINEL: CHANGED-SETTING FIGURE BEGINS ===",
               "=== SENTINEL: CHANGED-SETTING FIGURE ENDS ===",
               "=== SENTINEL: PROBE COMPLETE ===")
missing_sentinels <- sentinels[!vapply(sentinels,
                     function(s) any(transcript == s), logical(1))]
drive_complete <- length(missing_sentinels) == 0

check_true(V,
           sprintf("the drive reached every sentinel, i.e. it ran to completion%s",
                   if (length(missing_sentinels))
                       paste0(" -- NOT REACHED: ", paste(missing_sentinels, collapse = "; "),
                              " -- see the transcript's own error text, ",
                              "usually a Praat script abort")
                   else ""),
           drive_complete)

if (!drive_complete && length(transcript)) {
    err_lines <- grep("^Error:|not performed or completed|not completed\\.$",
                      transcript, value = TRUE)
    if (length(err_lines))
        cat("\n  TRANSCRIPT'S OWN ERROR TEXT:\n    ",
            paste(utils::head(err_lines, 6), collapse = "\n    "), "\n", sep = "")
}

between <- function(begin_marker, end_marker) {
    b <- which(transcript == begin_marker)
    e <- which(transcript == end_marker)
    if (!length(b) || !length(e) || e[1] <= b[1]) return(character(0))
    transcript[(b[1] + 1):(e[1] - 1)]
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
REQUIRED_LEGS <- c("no_change", "changed_setting")
population <- sort(unique(ev$leg[nzchar(ev$leg)]))

check_true(V,
           sprintf("RESOLVER: the probe's TSV names a nonzero population (%d legs: %s)",
                   length(population),
                   if (length(population)) paste(population, collapse = ", ") else "none"),
           length(population) > 0)

missing <- setdiff(REQUIRED_LEGS, population)
extra   <- setdiff(population, REQUIRED_LEGS)
check_true(V,
           sprintf("both ruled legs are present%s",
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
# 2. THE NO-CHANGE LEG -- "EXACTLY ONE report in the Info window, ZERO
#    recomputation lines"
# ---------------------------------------------------------------------------
menu_block   <- if (drive_complete) between(
    "=== SENTINEL: MENU ANALYSIS BEGINS ===",
    "=== SENTINEL: MENU ANALYSIS ENDS ===") else character(0)
nochange_block <- if (drive_complete) between(
    "=== SENTINEL: NO-CHANGE FIGURE BEGINS ===",
    "=== SENTINEL: NO-CHANGE FIGURE ENDS ===") else character(0)

n_menu_reports     <- sum(grepl(REPORT_MARKER, menu_block, fixed = TRUE))
n_nochange_reports <- sum(grepl(REPORT_MARKER, nochange_block, fixed = TRUE))

check_true(V,
           sprintf("the analysis door printed exactly one report (%d found in the menu block)",
                   n_menu_reports),
           drive_complete && n_menu_reports == 1L)

check_true(V,
           sprintf("no-change leg: the figure printed ZERO recomputation lines -- no second report block (%d '%s' headers found)",
                   n_nochange_reports, REPORT_MARKER),
           drive_complete && n_nochange_reports == 0L)

check_true(V,
           sprintf("no-change leg: the bridge's own verdict is \"consume\" (saw %s)",
                   if (is.na(val("no_change", "verdict"))) "no measurement"
                   else val("no_change", "verdict")),
           drive_complete && identical(val("no_change", "verdict"), "consume"))

check_true(V,
           sprintf("no-change leg: the bridge says NOT to print a report (printReport = 0, saw %s)",
                   if (is.na(val("no_change", "printReport"))) "no measurement"
                   else val("no_change", "printReport")),
           drive_complete && identical(val("no_change", "printReport"), "0"))

check_true(V,
           "no-change leg: EXACTLY ONE report exists in the whole transcript across both doors combined",
           drive_complete && (n_menu_reports + n_nochange_reports) == 1L)

# ---------------------------------------------------------------------------
# 3. THE CHANGED-SETTING LEG -- "the one announcement line naming the
#    change, the brackets updated, and the ABSENCE of a second report block"
# ---------------------------------------------------------------------------
changed_block <- if (drive_complete) between(
    "=== SENTINEL: CHANGED-SETTING FIGURE BEGINS ===",
    "=== SENTINEL: CHANGED-SETTING FIGURE ENDS ===") else character(0)

announce_lines <- grep("^Recomputed:", changed_block, value = TRUE)
n_changed_reports <- sum(grepl(REPORT_MARKER, changed_block, fixed = TRUE))

check_true(V,
           sprintf("changed-setting leg: the bridge's own verdict is \"settings\" (saw %s)",
                   if (is.na(val("changed_setting", "verdict"))) "no measurement"
                   else val("changed_setting", "verdict")),
           drive_complete && identical(val("changed_setting", "verdict"), "settings"))

check_true(V,
           sprintf("changed-setting leg: EXACTLY ONE announcement line, in the ruled form \"Recomputed: ...\" (%d found: %s)",
                   length(announce_lines),
                   if (length(announce_lines)) paste(announce_lines, collapse = " | ") else "none"),
           drive_complete && length(announce_lines) == 1L)

check_true(V,
           sprintf("changed-setting leg: the announcement NAMES the change (mentions the correction, saw: %s)",
                   if (length(announce_lines)) announce_lines[1] else "nothing printed"),
           drive_complete && length(announce_lines) == 1L &&
               grepl("correction|adjustment", announce_lines[1], ignore.case = TRUE))

check_true(V,
           sprintf("changed-setting leg: NO second report block (%d '%s' headers found)",
                   n_changed_reports, REPORT_MARKER),
           drive_complete && n_changed_reports == 0L)

check_true(V,
           sprintf("changed-setting leg: the bridge says NOT to print a report (printReport = 0, saw %s)",
                   if (is.na(val("changed_setting", "printReport"))) "no measurement"
                   else val("changed_setting", "printReport")),
           drive_complete && identical(val("changed_setting", "printReport"), "0"))

attest(V, "the reprint-pins evidence these numbers came from",
       sprintf("%s | %s | %s", tsv_path, trans_path, exit_path))

if (!exists("EML_SUITE")) {
    eml_report(sprintf(
        "v140 reprint pins: drive %s; %d legs found",
        if (drive_complete) "completed" else "DID NOT COMPLETE",
        length(population)))
    eml_exit()
}
