# ============================================================================
# v110_roundtrip_replay.R -- the recorded script is the session, run again
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS FILE IS ABOUT. The recorder's promise to a user is not that it
# writes a file. It is that the file it writes IS the session: run it and the
# numbers are the numbers, the figure is the figure, and neither depends on
# the machine it lands on. Everything else the plugin does can be checked by
# reading one artefact. This claim cannot: it needs a session and a replay of
# that session, in separate Praat processes, compared.
#
# harness/roundtrip/run.sh performs one recording session of eight user
# actions and then runs the script it produced three times. This file reads
# the transcript.
#
# THE FOUR CLAIMS, AND WHY EACH NEEDS THE LEG IT HAS.
#
#   THE NUMBERS COME BACK. The colleague's leg -- the data file exactly as it
#   was sent, the script exactly as it was received, nothing staged -- must
#   land on the session's F, write the five machine-readable result files byte
#   for byte, and produce the session's report. It can only do that because
#   the recording carries the hand edit to row 1 as a step of its own; the
#   session analysed 4242 where the CSV on disk holds 100, and one cell moves
#   cohort alpha's mean by 518. Section 4 reads that cell back out of the
#   replay.
#
#   THE FIGURE COMES BACK BYTE FOR BYTE. Not "looks the same" -- `cmp`, and a
#   per-pixel count beside it so a failure says how far off it was.
#
#   AND IT COMES BACK OUT OF A HOSTILE PRAAT. This is the strongest claim in
#   the rig, and it is the one an ordinary replay is structurally unable to
#   make: an identical replay in an identical Praat proves the script is
#   deterministic, not that it is immune to the machine it lands on. The
#   hostile leg sets a different typeface, font size 60, thick lines, red ink,
#   a redefined page area, a redefined coordinate system, and draws a figure
#   onto the page BEFORE running the recorded script. Zero differing pixels.
#
#   AND THE CONTROL IS PART OF THAT CLAIM RATHER THAN A FOOTNOTE. A
#   perturbation that moves nothing proves nothing. The same four settings are
#   applied one at a time to an ordinary Praat drawing, each in a fresh
#   process off a fresh preferences folder, and section 7 holds the counts:
#   tens of thousands of pixels move. The plugin's figure moves zero, because
#   it re-asserts colour, line width, font size and the page before it draws.
#
#   EVERY STEP KIND THE RECORDER CAN EXPRESS IS IN THE FILE. The vocabulary is
#   not a list anybody maintains -- it is every literal ever handed to
#   @emlRecordStep, read out of the sources the drive loaded. Section 3
#   compares that set against the kinds the emitted script carries, as a set
#   rather than as a count, so a kind added to the recorder and never
#   exercised is named rather than averaged away. Two of the eight are the
#   reason the session has eight actions and not six: a session built out of
#   tables reaches `refusal` and `convert` by accident never.
#
# WHAT MAKES ANY OF IT A MEASUREMENT: THE RETARGET LEG. Identical is evidence
# only where different was available. Section 8 runs the same script over a
# second fixture -- same three columns, same 24 rows, different numbers --
# through the one line the emitted file's editable block exists for. A
# different F, a different figure, none of the five result files matching, and
# a run that still reaches its end. Without it, every comparison in sections 4
# to 6 would pass just as well against a rig that compared the session's own
# outputs with themselves.
#
# WHAT THIS HARNESS CANNOT SEE, and it is the same list harness/roundtrip's
# own header carries. The four dialog-bearing scripts are driven as headless
# twins, so the WORDING of every dialog is outside this file -- what is
# asserted is that the twin's body is byte-identical to the shipped body, in
# section 1, first and unconditionally, because every other check here is a
# statement about the plugin only for as long as that holds. The graphs form
# is not twinned at all; its own draw chain is driven at the wrapper's call
# site. The refusal is originated by calling the shipped orchestrator rather
# than by pressing the wrapper's button, because a refused analysis lands in
# @emlErrorDialog, whose pause region holds two `endPause` lines on opposite
# arms of an `if` and which the rig therefore refuses to excise. And the save
# panel cannot be originated without a display at all.
#
#     bash harness/roundtrip/run.sh
#     Rscript validate/v110_roundtrip_replay.R
#     bash harness/roundtrip/break.sh
#
# Input: harness/roundtrip/out/. $EML_ROUNDTRIP_DIR overrides that folder and
#        $EML_ROUNDTRIP_FILE the recorder files under test -- a colon-separated
#        list, because the recorder is stats/eml-record.praat AND the
#        scripts/eml-record-*.praat the wrappers reach by runScript -- so a
#        break test drives damaged copies and never goes near the shipped
#        ones. The same two names harness/edittable and harness/correlgroup
#        use, for the same reason.
#
# Base R only. No packages.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v110"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

rd <- Sys.getenv("EML_ROUNDTRIP_DIR", unset = "")
if (!nzchar(rd)) rd <- repo_path("harness", "roundtrip", "out")
fixDir <- repo_path("harness", "roundtrip", "fixtures")

tsvPath <- file.path(rd, "ROUNDTRIP.tsv")
have <- check_true(V, "the roundtrip drive was run (bash harness/roundtrip/run.sh)",
                   file.exists(tsvPath) && file.info(tsvPath)$size > 0)
if (!have && !exists("EML_SUITE")) {
    eml_report("v110 roundtrip replay: NO EVIDENCE -- run bash harness/roundtrip/run.sh")
    eml_exit()
}

# A MISSING FACT IS NA AND NA FAILS. Under a break test whole keys go missing,
# because a damaged recorder can write no script at all -- and a validator
# that stops on the missing key has reported nothing, which is strictly worse
# than a red line. Same reasoning as v55's and v53's.
E <- list()
if (have) {
    .x <- read.delim(tsvPath, header = FALSE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE)
    E <- setNames(as.list(trimws(as.character(.x[[2]]))),
                  trimws(as.character(.x[[1]])))
}
es <- function(k) if (is.null(E[[k]])) NA_character_ else E[[k]]
en <- function(k) suppressWarnings(as.numeric(es(k)))
is1 <- function(k) identical(es(k), "1")
csv_set <- function(k) {
    v <- es(k)
    if (is.na(v) || !nzchar(v)) character(0) else sort(strsplit(v, ",", fixed = TRUE)[[1]])
}
lines_of <- function(p) if (file.exists(p)) readLines(p, warn = FALSE) else character(0)

LEGS_SAME <- c("colleague", "hostile")

# ---------------------------------------------------------------------------
# 1. THE THING THAT RAN WAS THE PLUGIN
# ---------------------------------------------------------------------------
# FIRST, AND UNCONDITIONALLY, for v55's reason: every claim below is a
# statement about the shipped plugin only while the thing that ran was the
# shipped plugin with its dialogs replaced and nothing else touched. The
# driver hashes each shipped file minus its pause stanzas against its twin
# minus the lines the driver injected. If those differ, the rest of this file
# is measuring some other program.
check_true(V, "the drive ran to completion", identical(es("drive_exit"), "0"))
check_true(V, "the recording started from the shipped wrapper", is1("record_started"))
check_true(V, "a script was written", is1("flush_written"))
check_true(V, sprintf("the drive used the target Praat (%s)", es("praat_version")),
           grepl("^Praat 6\\.6\\.30", es("praat_version")))

for (tw in c(dmo = "eml-create-demo.praat", edt = "eml-edit-table.praat",
             anv = "eml-compare-k-groups.praat", out = "eml-output.praat")) {
    k <- names(which(c(dmo = "eml-create-demo.praat", edt = "eml-edit-table.praat",
                       anv = "eml-compare-k-groups.praat",
                       out = "eml-output.praat") == tw))
    check_true(V, sprintf("the %s twin's body is byte-identical to the shipped file",
                          sub("\\.praat$", "", tw)),
               is1(sprintf("twin_%s_body_identical", k)))
}

# THE DIALOGS ARE NAMED, NOT JUST COUNTED. An index is a fragile handle and a
# count is a weaker one: a refactor that moved the cell-write out of the
# editor's main dialog, or dropped the save panel's confirmation, would keep
# the count and change the map -- and the tapes, which press buttons by
# stanza index, would then be pressing them on something else.
stanzaTitles <- unname(unlist(E[grep("^stanza_[a-z]+_[0-9]+$", names(E))]))
for (want in c("Create Demo Table", "EML Table Editor",
               "Compare k Groups (ANOVA)", "Analysis complete", "Saved")) {
    check_true(V, sprintf("the driven files still hold the dialog '%s'", want),
               any(grepl(want, stanzaTitles, fixed = TRUE)))
}

# THE FIXTURES ARE THE COMMITTED ONES. Read from the tree rather than from a
# literal in this file, so a fixture edited without a re-drive is caught by
# the row and cell checks below rather than by a sha nobody can recompute.
fixIn  <- lines_of(file.path(fixDir, "rt_input.csv"))
fixOth <- lines_of(file.path(fixDir, "rt_other.csv"))
check_true(V, "the recorded input fixture is in the tree, 24 rows and a header",
           length(fixIn) == 25L)
check_true(V, "the retarget fixture is in the tree, the same shape",
           length(fixOth) == length(fixIn) &&
               length(fixIn) > 0 && identical(fixIn[1], fixOth[1]))
check_true(V, "the two fixtures hold different data",
           length(fixIn) > 1 && !identical(fixIn[-1], fixOth[-1]))
check_true(V, "the drive read the fixture it says it read (24 rows)",
           identical(es("input_csv_rows"), "24"))
check_true(V, "the recorded cell starts at 100 in the file on disk",
           length(fixIn) > 1 && grepl(",100$", fixIn[2]))

# WHICH RECORDER RAN IS ATTESTED, NOT ASSERTED. A break run drives a damaged
# copy on purpose, and a check that went red on that would put a line in the
# report saying nothing about the break -- the reds have to come from the
# claims. The attestation is here so a reader of a green report can see which
# files produced it.
attest(V, "the recorder that produced this transcript",
       sprintf("%s | overrides: %s", es("recorder_files"), es("stage_overrides")))

# ---------------------------------------------------------------------------
# 2. THE SESSION DID THE EIGHT THINGS
# ---------------------------------------------------------------------------
check_true(V, "1. the demo generator built its table (45 rows)",
           is1("action1_create_demo_ran") && identical(es("action1_create_demo_rows"), "45"))
check_true(V, "2. the CSV was opened (24 rows, 3 columns)",
           is1("action2_load_file_ran") && identical(es("action2_load_file_rows"), "24") &&
               identical(es("action2_load_file_cols"), "3"))
check_true(V, "3. the editor wrote 4242 over the 100 in row 1",
           is1("action3_edit_cell_ran") && identical(es("action3_edit_cell_before"), "100") &&
               identical(es("action3_edit_cell_after"), "4242"))
check_true(V, "4. the wrong column was refused, and the refusal names it",
           is1("action4_refusal_ran") && grepl("speaker", es("action4_refusal_message"), fixed = TRUE))
check_true(V, "5. the ANOVA ran", identical(es("action4_analysis_ran"), "1"))
check_true(V, "6. the violin was drawn", identical(es("action5_draw_ran"), "1"))
check_true(V, "7. the save panel wrote seven files",
           identical(es("action6_files_written"), "7"))
check_true(V, "8. a Sound was converted for a figure it cannot draw itself",
           is1("action8_convert_ran") &&
               grepl("^Sound ", es("action8_convert_source")) &&
               grepl("^Spectrum ", es("action8_convert_result")))

# THE EDIT IS THE THING THE WHOLE RIG TURNS ON, so its consequence is read
# rather than its occurrence. 4242 in a column of 100..107 moves the table's
# mean to 609.416667 and nothing else in this arrangement of steps does.
check(V, "the edit moved the table's mean where only that edit can",
      609.416667, en("action3_table_mean_after"), tol = 1e-5)

# ---------------------------------------------------------------------------
# 3. EVERY STEP KIND THE RECORDER CAN EXPRESS IS IN THE EMITTED SCRIPT
# ---------------------------------------------------------------------------
vocab <- csv_set("recorder_kinds")
inFile <- csv_set("emitted_kinds_sorted")
check_true(V, sprintf("the recorder's vocabulary was read at all (%d kinds)", length(vocab)),
           length(vocab) >= 7)
check_true(V, "the vocabulary holds the two a table session never reaches",
           all(c("refusal", "convert") %in% vocab))
check_true(V, sprintf("no kind the recorder can express is missing from the file (%s)",
                      if (nzchar(es("kinds_missing_from_emitted")))
                          es("kinds_missing_from_emitted") else "none missing"),
           identical(es("kinds_missing_from_emitted"), ""))
check_true(V, "no kind in the file is outside the vocabulary that was read",
           identical(es("kinds_not_in_vocabulary"), ""))

# SET-BASED, NOT A COUNT. Two counts agree by coincidence -- one kind dropped
# and one added is a wash -- and a count cannot say WHICH kind fell through.
eml_census(V, "step kind the recorder can express", vocab, inFile)

check_true(V, "the file's steps are numbered and headed, one per action",
           en("emitted_step_headings") >= 8)
check_true(V, "no phrase came back unresolved",
           identical(es("emitted_missing_phrases"), "0"))

# ---------------------------------------------------------------------------
# 4. THE NUMBERS COME BACK
# ---------------------------------------------------------------------------
sessF <- es("session_F")
check_true(V, sprintf("the session's own ANOVA produced an F (%s)", sessF),
           !is.na(sessF) && nzchar(sessF) && !is.na(suppressWarnings(as.numeric(sessF))))

for (leg in LEGS_SAME) {
    k <- function(x) sprintf("leg_%s_%s", leg, x)
    check_true(V, sprintf("%s: the emitted script ran to its end", leg),
               identical(es(k("exit")), "0") && identical(es(k("reached_end")), "1"))
    check_true(V, sprintf("%s: only the output folder was edited (2 lines)", leg),
               identical(es(k("edited_lines")), "2"))
    # THE CELL, READ BACK OUT OF THE REPLAY. This is the whole of the claim
    # that the recording carries the hand edit: the CSV on disk holds 100.
    check_true(V, sprintf("%s: the replayed table holds the edited cell, not the file's", leg),
               identical(es(k("cell_row1")), "4242"))
    check_true(V, sprintf("%s: the ANOVA is the session's ANOVA (F %s)", leg, es(k("F"))),
               identical(es(k("F")), sessF) &&
                   identical(es(k("anova_between")), es("action4_anova_between")))
    check_true(V, sprintf("%s: all five result files are byte-identical", leg),
               identical(es(k("result_csvs_identical")), es(k("result_csvs_total"))) &&
                   identical(es(k("result_csvs_total")), "5"))
    check_true(V, sprintf("%s: the report is the session's report, same length", leg),
               identical(es(k("report_body_lines")), es("leg_colleague_report_body_lines")) &&
                   en(k("report_body_lines")) > 50)

    # THE TWO LINES THAT MAY DIFFER ARE NAMED, NOT COUNTED. A count would go
    # red on a repair that carried the provenance line through unchanged --
    # an improvement -- and would stay green on a report that had swapped a
    # sum of squares for a wall clock. What is pinned is that every differing
    # line is either the clock or the line that says where the numbers came
    # from, whatever those lines end up saying.
    d <- es(k("report_body_diff"))
    dl <- if (is.na(d) || !nzchar(d)) character(0) else strsplit(d, "~", fixed = TRUE)[[1]]
    check_true(V, sprintf("%s: the report differs only in its clock and its provenance line", leg),
               length(dl) <= 4 &&
                   all(grepl("^[<>] *([A-Z][a-z]{2} [A-Z][a-z]{2} +[0-9]|from:)", dl)))
    check_true(V, sprintf("%s: the replayed report says it came from a recorded script", leg),
               any(grepl("^> *from:.*recorded", dl)))
}

# ---------------------------------------------------------------------------
# 5. THE FIGURE COMES BACK, BYTE FOR BYTE
# ---------------------------------------------------------------------------
for (leg in LEGS_SAME) {
    k <- function(x) sprintf("leg_%s_%s", leg, x)
    check_true(V, sprintf("%s: the figure is the same file (cmp)", leg), is1(k("png_identical")))
    check_true(V, sprintf("%s: the figure has the session's fingerprint", leg),
               identical(es(k("png_md5")), es("session_png_md5")) &&
                   identical(es(k("png_bytes")), es("session_png_bytes")))
    check(V, sprintf("%s: pixels differing from the session's figure", leg),
          0, en(k("png_pixels_differing")), tol = 0.5)
    check(V, sprintf("%s: worst channel difference in any pixel", leg),
          0, en(k("png_max_delta")), tol = 0.5)
}

# ---------------------------------------------------------------------------
# 6. AND THE HOSTILE LEG WAS ACTUALLY HOSTILE
# ---------------------------------------------------------------------------
# Section 5 has already required zero differing pixels from it. What is left
# is the thing a green line cannot distinguish on its own: whether the leg
# perturbed anything at all. The settings are read out of the transcript and
# each one is required BY NAME, so a hostile prelude that quietly lost its
# typeface line stops being able to claim a typeface.
hs <- es("hostile_settings")
for (want in c("Palatino", "Font size: 60", "Line width: 5", "Colour: \"red\"",
               "Select outer viewport", "Axes:", "Draw inner box", "Draw line")) {
    check_true(V, sprintf("the hostile leg set %s before running the script", want),
               !is.na(hs) && grepl(want, hs, fixed = TRUE))
}
check_true(V, "the hostile prelude is nine lines of perturbation",
           en("hostile_lines") >= 9)

# ---------------------------------------------------------------------------
# 7. THE CONTROL -- those settings are not inert
# ---------------------------------------------------------------------------
# WITHOUT THIS SECTION THE HOSTILE LEG PROVES NOTHING. "The figure came back
# identical out of a hostile Praat" and "those settings reach no Praat drawing
# at all" are the same transcript, and only one of them is a fact about the
# plugin. Each setting is applied on its own to an ordinary drawing -- box,
# two lines, two circles, marks, one text -- in a fresh process off a fresh
# preferences folder, because Praat persists Picture-window settings and a
# control started from somebody else's leftovers measures a state it did not
# choose.
#
# THE FLOOR IS 1000 AND THE MEASURED VALUES ARE 10,206 to 196,601. It is a
# floor rather than a band because the point is that the perturbation is real,
# and pinning a font renderer's exact pixel count would make this file fail on
# somebody else's machine for a reason that is not about the plugin.
check_true(V, "the control drawing was rendered", en("control_base_png_bytes") > 1000)
for (kk in c(typeface = "a different typeface", fontsize = "font size 60",
             linewidth = "line width 5", ink = "red ink")) {
    key <- names(which(c(typeface = "a different typeface", fontsize = "font size 60",
                         linewidth = "line width 5", ink = "red ink") == kk))
    n <- en(sprintf("control_%s_pixels_differing", key))
    check_true(V, sprintf("%s moves an ordinary Praat drawing (%s px)", kk,
                          if (is.na(n)) "no measurement" else format(n, big.mark = ",",
                                                                    scientific = FALSE)),
               !is.na(n) && n > 1000)
}

# ---------------------------------------------------------------------------
# 8. IDENTICAL WAS AVAILABLE -- THE RETARGET LEG
# ---------------------------------------------------------------------------
# The same script, over the second fixture, through the one line the editable
# block exists for. Everything in sections 4 to 6 is a constant unless this
# leg comes out different, and a leg that came out different by CRASHING would
# be worse than useless -- so it has to still reach its end.
check_true(V, "retarget: the second fixture is the same shape as the first",
           is1("other_csv_shape_matches"))
check_true(V, "retarget: and holds different numbers",
           en("other_csv_values_differ") > 0)
check_true(V, "retarget: the emitted script still ran to its end on other data",
           identical(es("leg_retarget_exit"), "0") &&
               identical(es("leg_retarget_reached_end"), "1"))
check_true(V, "retarget: two lines were edited -- the folder and the input file",
           identical(es("leg_retarget_edited_lines"), "4"))
check_true(V, "retarget: the recorded edit step ran on the new data too",
           identical(es("leg_retarget_cell_row1"), "4242"))
check_true(V, sprintf("retarget: the ANOVA moved (%s against the session's %s)",
                      es("leg_retarget_F"), sessF),
           !is.na(es("leg_retarget_F")) && nzchar(es("leg_retarget_F")) &&
               !identical(es("leg_retarget_F"), sessF))
check_true(V, "retarget: the figure is NOT the session's file",
           identical(es("leg_retarget_png_identical"), "0"))
check_true(V, sprintf("retarget: and differs by a figure's worth of pixels (%s)",
                      es("leg_retarget_png_pixels_differing")),
           en("leg_retarget_png_pixels_differing") > 1000)
check_true(V, "retarget: none of the five result files matches the session's",
           identical(es("leg_retarget_result_csvs_identical"), "0"))

if (!exists("EML_SUITE")) {
    eml_report("v110 roundtrip replay: one session, one emitted script, three replays")
    eml_exit()
}
