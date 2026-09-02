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
# ITEM 1.2, AS AMENDED BY FABLE ON 26 AUGUST -- THE MINIMAL RENDERER. Two
# further legs and one source-shape section were added when that item was
# built, and they are what turns section (c)'s contract into Ian's rule of
# 24 August: "THE REPORT COMPARISON, NOT THE KEY, DECIDES WHAT THE USER
# SEES ... a re-run that reproduces the stored report exactly prints
# nothing."
#
#   changed_data_same_report  one cell moves from 10.1 to 10.2, inside its
#                             own rank position, so not one number in a rank
#                             test moves. The KEY sees the edit -- it digests
#                             every cell -- so the figure re-runs; and the
#                             re-run renders the same report, so it must
#                             print NOTHING. Not a second report, and not the
#                             "Data changed" line above it.
#   changed_data_new_report   one cell moves from 8.4 to 12.0, across a rank
#                             boundary. The report really is different, so
#                             the line and exactly one report print. Without
#                             this leg a comparison that answered "identical"
#                             to everything would pass the leg above.
#
# THE RED DEMONSTRATION IS THE PRE-ITEM TREE, driven with this same probe:
# `git worktree add --detach <dir> <pre-item sha>`, copy
# harness/reprintpins/probe.praat in, and run it. Measured on 2bccd8e: the
# same-report figure prints the 24 August line and a SECOND COMPLETE 62-LINE
# REPORT that diffs byte-identical against the first, timestamp line aside.
#
# THE PROBE NOW CALLS THE REPRINT GATE. @emlRunAnnotationComparison does not
# print the report -- the graphs form does, through
# @emlGraphsReportBridgeIfNew -- so before that call was added to the probe,
# every "no second report" pin below could not have failed on any tree.
#
# THE SCENARIO IS REPRODUCED VERBATIM, per docs/MEMO_TO_FABLE_unification.md:
# a three-group table, a Kruskal-Wallis run from the stats menu, then the
# SAME comparison drawn as a figure through @emlRunAnnotationComparison -- the
# procedure whose own header names itself as the second door onto the same
# test. harness/reprintpins/probe.praat builds that table and drives both
# doors in one process; harness/reprintpins/run.sh captures the WHOLE
# PROCESS's stdout, because Praat has no way for a script to read its own
# Info window back as text (the same limitation
# eml-annotation-procedures.praat's own header names under THE 24 AUGUST RULE
# IS ONLY HALF BUILT HERE). This file counts report markers in that captured
# transcript and reads emlRunAnnotationComparison's own verdict/note/printReport
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
# ruled contract. @emlRunAnnotationComparison's call site now passes the full
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
               "=== SENTINEL: LEG C MENU ANALYSIS BEGINS ===",
               "=== SENTINEL: LEG C MENU ANALYSIS ENDS ===",
               "=== SENTINEL: SAME-REPORT FIGURE BEGINS ===",
               "=== SENTINEL: SAME-REPORT FIGURE ENDS ===",
               "=== SENTINEL: NEW-REPORT FIGURE BEGINS ===",
               "=== SENTINEL: NEW-REPORT FIGURE ENDS ===",
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
    # ITEM 1.2 -- ADJACENT SENTINELS MEAN AN EMPTY BLOCK, AND R'S `:` DOES NOT
    # SAY SO. With the two markers on consecutive lines, (b+1):(e-1) is
    # (b+1):b, which counts DOWNWARDS and hands back BOTH SENTINELS as if they
    # were the block's contents. Latent until this file grew a check that
    # counts what a figure printed rather than only searching it for a report
    # header: an empty block came back as two lines and the empty-output pin
    # failed on a tree that printed nothing at all, which is the answer it
    # exists to confirm.
    if (e[1] == b[1] + 1) return(character(0))
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
REQUIRED_LEGS <- c("no_change", "changed_setting",
                   "changed_data_same_report", "changed_data_new_report")
population <- sort(unique(ev$leg[nzchar(ev$leg)]))

check_true(V,
           sprintf("RESOLVER: the probe's TSV names a nonzero population (%d legs: %s)",
                   length(population),
                   if (length(population)) paste(population, collapse = ", ") else "none"),
           length(population) > 0)

missing <- setdiff(REQUIRED_LEGS, population)
extra   <- setdiff(population, REQUIRED_LEGS)
check_true(V,
           sprintf("every ruled leg is present%s",
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

# ---------------------------------------------------------------------------
# 4. ITEM 1.2 -- THE CHANGED-DATA / SAME-REPORT LEG.
#    "A re-run that reproduces the stored report exactly prints nothing."
# ---------------------------------------------------------------------------
# NOTHING MEANS NOTHING, and both halves are asserted separately, because the
# obvious half-fix -- suppress the report, keep the line -- leaves a reader
# staring at a "Data changed since this analysis was last run; re-measured."
# with no re-measurement under it, which says less than silence does.
legc_menu_block <- if (drive_complete) between(
    "=== SENTINEL: LEG C MENU ANALYSIS BEGINS ===",
    "=== SENTINEL: LEG C MENU ANALYSIS ENDS ===") else character(0)
same_block <- if (drive_complete) between(
    "=== SENTINEL: SAME-REPORT FIGURE BEGINS ===",
    "=== SENTINEL: SAME-REPORT FIGURE ENDS ===") else character(0)

n_legc_menu_reports <- sum(grepl(REPORT_MARKER, legc_menu_block, fixed = TRUE))
n_same_reports      <- sum(grepl(REPORT_MARKER, same_block, fixed = TRUE))
same_data_lines     <- grep("^Data changed", same_block, value = TRUE)

check_true(V,
           sprintf("the analysis door re-run printed exactly one report, so the store carries a report a reader has seen (%d found)",
                   n_legc_menu_reports),
           drive_complete && n_legc_menu_reports == 1L)

check_true(V,
           sprintf("same-report leg: the edit really was recorded as the 10.1 -> 10.2 one (saw %s)",
                   if (is.na(val("changed_data_same_report", "edit"))) "no measurement"
                   else val("changed_data_same_report", "edit")),
           drive_complete &&
               identical(val("changed_data_same_report", "edit"),
                         "row 1 value 10.1 -> 10.2"))

check_true(V,
           sprintf("same-report leg: the KEY still says the data moved, so this is not the store quietly agreeing -- verdict \"data\" (saw %s)",
                   if (is.na(val("changed_data_same_report", "verdict"))) "no measurement"
                   else val("changed_data_same_report", "verdict")),
           drive_complete &&
               identical(val("changed_data_same_report", "verdict"), "data"))

check_true(V,
           sprintf("same-report leg: NO second report block (%d '%s' headers found between the sentinels)",
                   n_same_reports, REPORT_MARKER),
           drive_complete && n_same_reports == 0L)

check_true(V,
           sprintf("same-report leg: NOT EVEN THE ONE LINE -- zero \"Data changed\" lines (%d found: %s)",
                   length(same_data_lines),
                   if (length(same_data_lines)) paste(same_data_lines, collapse = " | ")
                   else "none"),
           drive_complete && length(same_data_lines) == 0L)

check_true(V,
           sprintf("same-report leg: the bridge says NOT to print a report (printReport = 0, saw %s)",
                   if (is.na(val("changed_data_same_report", "printReport"))) "no measurement"
                   else val("changed_data_same_report", "printReport")),
           drive_complete &&
               identical(val("changed_data_same_report", "printReport"), "0"))

check_true(V,
           sprintf("same-report leg: and the bridge lowered its own pending line (notePending = 0, saw %s)",
                   if (is.na(val("changed_data_same_report", "notePending"))) "no measurement"
                   else val("changed_data_same_report", "notePending")),
           drive_complete &&
               identical(val("changed_data_same_report", "notePending"), "0"))

check_true(V,
           sprintf("same-report leg: the figure's whole contribution to the Info window is empty (%d non-blank lines)",
                   sum(nzchar(trimws(same_block)))),
           drive_complete && sum(nzchar(trimws(same_block))) == 0L)

# ---------------------------------------------------------------------------
# 5. ITEM 1.2 -- THE CHANGED-DATA / NEW-REPORT LEG. THE ANTI-VACUITY HALF.
# ---------------------------------------------------------------------------
# Section 4 is satisfied by a mechanism that never prints anything again.
# This leg moves a value across a rank boundary, so the report genuinely
# differs, and the ruled behaviour is the one the 24 August rule describes:
# the line, and exactly one report under it.
new_block <- if (drive_complete) between(
    "=== SENTINEL: NEW-REPORT FIGURE BEGINS ===",
    "=== SENTINEL: NEW-REPORT FIGURE ENDS ===") else character(0)
n_new_reports  <- sum(grepl(REPORT_MARKER, new_block, fixed = TRUE))
new_data_lines <- grep("^Data changed", new_block, value = TRUE)

check_true(V,
           sprintf("new-report leg: the edit really was the rank-moving one (saw %s)",
                   if (is.na(val("changed_data_new_report", "edit"))) "no measurement"
                   else val("changed_data_new_report", "edit")),
           drive_complete &&
               identical(val("changed_data_new_report", "edit"),
                         "row 8 value 8.4 -> 12.0"))

check_true(V,
           sprintf("new-report leg: verdict \"data\" (saw %s)",
                   if (is.na(val("changed_data_new_report", "verdict"))) "no measurement"
                   else val("changed_data_new_report", "verdict")),
           drive_complete &&
               identical(val("changed_data_new_report", "verdict"), "data"))

check_true(V,
           sprintf("new-report leg: EXACTLY ONE report block (%d found)", n_new_reports),
           drive_complete && n_new_reports == 1L)

check_true(V,
           sprintf("new-report leg: EXACTLY ONE 24 August line above it (%d found: %s)",
                   length(new_data_lines),
                   if (length(new_data_lines)) paste(new_data_lines, collapse = " | ")
                   else "none"),
           drive_complete && length(new_data_lines) == 1L)

check_true(V,
           sprintf("new-report leg: the line comes ABOVE the report, not under it"),
           drive_complete && n_new_reports == 1L && length(new_data_lines) == 1L &&
               which(grepl("^Data changed", new_block))[1] <
                   which(grepl(REPORT_MARKER, new_block, fixed = TRUE))[1])

check_true(V,
           sprintf("new-report leg: the bridge says to print (printReport = 1, saw %s)",
                   if (is.na(val("changed_data_new_report", "printReport"))) "no measurement"
                   else val("changed_data_new_report", "printReport")),
           drive_complete &&
               identical(val("changed_data_new_report", "printReport"), "1"))

check_true(V,
           sprintf("new-report leg: with the line still pending for the caller (notePending = 1, saw %s)",
                   if (is.na(val("changed_data_new_report", "notePending"))) "no measurement"
                   else val("changed_data_new_report", "notePending")),
           drive_complete &&
               identical(val("changed_data_new_report", "notePending"), "1"))

# THE TWO DATA LEGS ARE NOT ONE LEG. A rig that silently drove the same edit
# twice would satisfy sections 4 and 5 only if it also contradicted itself,
# but a rig that never edited at all would produce two identical legs and
# could satisfy neither -- so say out loud that the two differ.
check_true(V,
           "the two changed-data legs are genuinely two different edits",
           drive_complete &&
               !identical(val("changed_data_same_report", "edit"),
                          val("changed_data_new_report", "edit")))

# ---------------------------------------------------------------------------
# 6. ITEM 1.2 -- THE SOURCE SHAPE OF THE MINIMAL RENDERER
# ---------------------------------------------------------------------------
# The legs above measure BEHAVIOUR on one fixture. This section asserts the
# SHAPE Fable ruled, because behaviour on one fixture cannot see a reporter
# line that was never exercised: one appendInfoLine left behind in a
# store-wired reporter prints during a buffer-only rendering, which is a line
# of a report nobody asked for appearing in the middle of a figure draw, and
# it does not enter the buffer either, so the comparison silently stops
# matching.
ann_src <- readLines(repo_path("plugin_EML_StatsGraphs", "graphs",
                               "eml-annotation-procedures.praat"), warn = FALSE)
out_src <- readLines(repo_path("plugin_EML_StatsGraphs", "stats",
                               "eml-output.praat"), warn = FALSE)
ext_src <- readLines(repo_path("plugin_EML_StatsGraphs", "stats",
                               "eml-extract.praat"), warn = FALSE)

proc_body <- function(src, name) {
    b <- grep(sprintf("^procedure %s(:|\\s*$)", name), src)
    if (!length(b)) return(character(0))
    e <- grep("^endproc\\s*$", src)
    e <- e[e > b[1]]
    if (!length(e)) return(character(0))
    src[(b[1] + 1):(e[1] - 1)]
}

# THE THREE SHARED REPORTERS ARE THE SLICE THE TWO STORE-WIRED DOORS BOTH
# CALL: @emlReportTwoGroupComparison, @emlReportAnovaComparison and
# @emlReportKWComparison, which sit consecutively between these two anchors.
rep_from <- grep("^procedure emlReportTwoGroupComparison:", ann_src)
rep_to   <- grep("^# @emlReportCorrelationAnalysis\\s*$", ann_src)
shared_ok <- length(rep_from) == 1L && length(rep_to) == 1L && rep_to[1] > rep_from[1]
check_true(V,
           "RESOLVER: the three shared comparison reporters were located in the source",
           shared_ok)
shared_slice <- if (shared_ok) ann_src[rep_from[1]:rep_to[1]] else character(0)
stray <- grep("(^|\\s)appendInfoLine:", shared_slice, value = TRUE)
check_true(V,
           sprintf("the two store-wired doors' shared reporters emit ONLY through the helper -- zero raw appendInfoLine (%d found%s)",
                   length(stray),
                   if (length(stray)) paste0(": ", paste(trimws(stray), collapse = " | "))
                   else ""),
           shared_ok && length(stray) == 0L)
check_true(V,
           sprintf("and the slice is not empty, so that count is a measurement (%d lines walked)",
                   length(shared_slice)),
           length(shared_slice) > 200L)

emit_body <- proc_body(out_src, "emlEmit")
check_true(V, "RESOLVER: @emlEmit exists and has a body",
           length(emit_body) > 0L)
check_true(V,
           "@emlEmit is dual-mode: it buffers unconditionally and prints only when emlEmitPrint = 1",
           any(grepl("emlEmitText\\$ = emlEmitText\\$ \\+", emit_body)) &&
               any(grepl("if emlEmitPrint = 1", emit_body)))

explain_body <- proc_body(out_src, "emlExplainLine")
check_true(V, "RESOLVER: @emlExplainLine exists and has a body",
           length(explain_body) > 0L)
check_true(V,
           "THE EXPLAIN HELPER NEVER BUFFERS -- its body assigns emlEmitText$ nowhere",
           length(explain_body) > 0L &&
               !any(grepl("emlEmitText\\$\\s*=", explain_body)))
check_true(V,
           "and it is gated on the explanations toggle, so nothing can print one with the toggle off",
           length(explain_body) > 0L &&
               any(grepl("if emlShowExplanations", explain_body)))

hdr_body <- proc_body(out_src, "emlReportHeader")
check_true(V,
           "the header's TIMESTAMP is printed raw and never buffered -- a canonical timestamp can never compare equal twice",
           length(hdr_body) > 0L &&
               any(grepl("appendInfoLine: \\.timestamp\\$", hdr_body)) &&
               !any(grepl("@emlEmit: \\.timestamp\\$", hdr_body)))

# ONE WRITER FOR THE STORED TEXT, the same contract every other emlStore name
# is under (v138 asserts the general form; this is the new name).
report_writes <- grep("^\\s*emlStoreReport\\$\\s*=", c(ann_src, out_src, ext_src),
                      value = TRUE)
check_true(V,
           sprintf("emlStoreReport$ is assigned in the write site's file and nowhere else in the reporting path (%d assignments, all in eml-extract.praat)",
                   length(report_writes)),
           length(grep("^\\s*emlStoreReport\\$\\s*=", c(ann_src, out_src))) == 0L &&
               length(grep("^\\s*emlStoreReport\\$\\s*=", ext_src)) >= 1L)

attest(V, "the reprint-pins evidence these numbers came from",
       sprintf("%s | %s | %s", tsv_path, trans_path, exit_path))

if (!exists("EML_SUITE")) {
    eml_report(sprintf(
        "v140 reprint pins and the minimal renderer: drive %s; %d legs found",
        if (drive_complete) "completed" else "DID NOT COMPLETE",
        length(population)))
    eml_exit()
}
