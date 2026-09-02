# ============================================================================
# v115_settings_publication.R -- the settings that decide the numbers reach
# the recorded script, and a replay obeys them
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS FILE IS FOR
#
# A recorded step is a procedure CALL WITH ITS ARGUMENTS. So a setting the
# plugin hands over as an argument is in the record, and a setting the plugin
# reads from a global is not -- and three of the globals the computing layer
# reads decide what the answer IS rather than how it looks:
#
#   annotCorrectionMethod$    the multiple-comparison correction.
#                             @emlRunAnnotationComparison takes no parameter for
#                             it and resolves it from the global, falling back
#                             to holm.
#   annotAlpha                the level every confidence interval in the
#                             reporters is built at, through
#                             @emlCIAlphaInForce. An emitted script opens with
#                             @emlInitializeDrawingDefaults, which seeds 0.05.
#   emlGroupSortAlphabetical  the order @emlCountGroups puts the levels in. It
#                             decides which level is group 1, so it flips the
#                             sign of every reported difference and swaps
#                             which group the report names first.
#
# A replay that misses one of these runs clean, draws its figure and prints a
# well-formed answer to a question the user did not ask. That is the failure
# the recorder exists to prevent, and it is silent.
#
# WHY GREPPING THE EMITTED SCRIPT WOULD NOT SETTLE IT
#
# A check that finds "annotAlpha" in an emitted file has established that the
# NAME was written. It has not established that the replay obeys it: a line
# emitted after the call that reads it, a value formatted through fixed$ and
# rounded on the way out, or a name the replay's own seed overwrites further
# down would all satisfy that grep and change the answer anyway. So the claim
# is made behaviourally, by harness/settingspub: six record legs, one Praat
# process each, two values of each setting; six replay legs, one fresh process
# each, running the emitted file. Two things are then asserted together:
#
#   session == replay          the recorded script reproduces its session
#   replay(A) != replay(B)     and it does so BECAUSE of the setting
#
# THE SECOND LINE CANNOT BE SKIPPED. A replay that ignored the setting
# entirely would still satisfy the first at whichever value happens to equal
# the seed -- which is exactly what a one-value rig would have reported as a
# pass. The alpha_05, sort_disc and corr_holm legs are green with nothing
# carried at all, because 0.05, discovery order and holm ARE the fallbacks.
# Only the second value of each setting can fail, and only the pair of
# assertions together says why.
#
# WHAT THE OBSERVABLES ARE, AND WHY THEY ARE NUMBERS RATHER THAN PIXELS
#
#   the correction    the adjusted p-values Dunn's test produces, read out of
#                     annotBracketP[] -- 0.941113 under bonferroni against
#                     0.313704 under holm on the same fixture and the same
#                     ranks. The bracket caption naming the resolved method is
#                     read beside them, so a leg cannot pass by carrying the
#                     caption and computing the other correction.
#   the alpha         the interval the two-group reporter prints, level and
#                     bounds together: 95% CI [-9.8411, -4.8599] against
#                     99% CI [-10.7174, -3.9836]. The level alone would not
#                     do -- a label is a string and the bounds are the claim.
#   the group order   the sign of t, the sign of the mean difference, the
#                     sentence naming which group is subtracted from which,
#                     and the order of the two group rows. The fixture's
#                     labels sort against their order of appearance on
#                     purpose: "zulu" is first in the file and second in the
#                     alphabet, so discovery and alphabetical name different
#                     groups first and the difference changes sign. Labels
#                     that sorted the way they appeared would leave this leg
#                     unable to fail.
#
# WHAT WENT RED WHEN THE CAPTURE WAS REMOVED. harness/settingspub/break.sh
# builds a copy of the plugin with @emlRecordCaptureStats' call taken out of
# @emlRecordStep -- the whole of the change and nothing else -- and drives the
# same twelve legs against it, and runs this file against the result: 53 of
# the 105 checks below go red. Measured 24 August 2026:
#
#   no emitted script carries any of the three names (0 lines against 18)
#   corr_bonf   session p = 0.941113, replay p = 0.313704 -- holm came back
#   alpha_01    session 99% CI [-10.7174, -3.9836],
#               replay  95% CI [-9.8411, -4.8599]
#   sort_alpha  session [4.8599, 9.8411], alfa minus zulu,
#               replay  [-9.8411, -4.8599], zulu minus alfa -- the sign of
#               every reported difference reversed, and the group the report
#               names first swapped
#
# WHAT ELSE IN THIS SUITE COULD HAVE CAUGHT IT, AND DOES NOT
#
#   v110's roundtrip replays a recorded session and compares five result files
#   and a figure byte for byte -- and is green on a tree carrying this defect,
#   because its session runs at the defaults. All three settings are invisible
#   to a rig that never moves them.
#   v107's census asks whether each menu command reaches a record step. All
#   the commands here do; the step they reach is the one missing the setting.
#   validate/tools/recorder_census.py measures seeded against emitted and sees
#   ONE of the three: its frame is @emlInitializeDrawingDefaults' seeded block,
#   which holds annotAlpha and neither of the other two.
#
#     Rscript validate/v115_settings_publication.R
#
# Inputs: harness/settingspub/out/SETTINGSPUB.tsv and the emitted scripts
#         beneath it, plus the four source files. $EML_SP_DIR overrides the
#         evidence folder and $EML_SP_STATS_SRC / $EML_SP_GRAPH_SRC the source
#         folders, so a break test can point this file at a different copy of
#         the tree without touching the working one.
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

ID <- "v115"

sdir <- Sys.getenv("EML_SP_STATS_SRC", unset = "")
if (!nzchar(sdir)) sdir <- repo_path(file.path("plugin", "stats"))
gdir <- Sys.getenv("EML_SP_GRAPH_SRC", unset = "")
if (!nzchar(gdir)) gdir <- repo_path(file.path("plugin", "graphs"))
edir <- Sys.getenv("EML_SP_DIR", unset = "")
if (!nzchar(edir)) edir <- repo_path(file.path("harness", "settingspub", "out"))

f_rec  <- file.path(sdir, "eml-record.praat")
f_form <- file.path(gdir, "eml-graphs-form.praat")
f_ann  <- file.path(gdir, "eml-annotation-procedures.praat")
f_ext  <- file.path(sdir, "eml-extract.praat")

check_true(ID, "the recorder, the form, the bridge and the extractor are present",
           all(file.exists(c(f_rec, f_form, f_ann, f_ext))))

SETTINGS <- c("annotCorrectionMethod$", "annotAlpha", "emlGroupSortAlphabetical")

# JOINED 25 AUG (punch list 6.3): emlShowExplanations captures in the SAME
# procedure, on the SAME analysis-and-draw steps, for a DIFFERENT reason --
# it is classified DISPLAY-ONLY in v112 (no number a result-store re-run
# would need moves when it changes), so it is deliberately NOT in SETTINGS
# above, which this file's own header says is the three that decide what a
# group comparison REPORTS. It is still a user's own choice (the menu
# dialog's "Annotate results with explanations" toggle, language batch item
# 9), and 6.3's ruling is "a recorded script reproduces it", which does not
# require moving a number. Named separately so a guard count of 4 reads as
# stated rather than as this file having quietly stopped checking.
ALSO_CAPTURED <- c("emlShowExplanations")

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS, AND STRIP WHOLE-LINE COMMENTS BEFORE MATCHING.
#
# Both halves have bitten this repository. Calls in these files are written
# across two and three physical lines with "...", so a line-at-a-time regex
# sees a name with no arguments and an argument list with no name. And every
# repair here carries a paragraph above it naming the globals being checked
# for -- @emlRecordCaptureStats' own header names all three of them several
# times -- so an unstripped grep finds the wiring present after every line of
# it has been deleted.
#
# Praat whole-line comment forms are `#`, `;` and `!`.
# ---------------------------------------------------------------------------
read_code <- function(path) {
    if (!file.exists(path)) return(character(0))
    raw <- readLines(path, warn = FALSE)
    joined <- character(0)
    for (ln in raw) {
        if (grepl("^\\s*\\.\\.\\.", ln) && length(joined)) {
            joined[length(joined)] <- paste0(joined[length(joined)], " ",
                                             sub("^\\s*\\.\\.\\.\\s*", "", ln))
        } else {
            joined <- c(joined, ln)
        }
    }
    norm <- gsub("\\s+", " ", trimws(joined))
    norm[!grepl("^#", norm) & !grepl("^;", norm) & !grepl("^!", norm)]
}

proc_body_of <- function(code, name) {
    i <- grep(sprintf("^procedure %s(:|$)", name), code)
    if (!length(i)) return(character(0))
    j <- grep("^endproc\\b", code)
    j <- j[j > i[1]]
    if (!length(j)) return(character(0))
    code[(i[1] + 1L):(j[1] - 1L)]
}

code_rec  <- read_code(f_rec)
code_ann  <- read_code(f_ann)
code_ext  <- read_code(f_ext)

`%or%` <- function(a, b) if (length(a) != 1L || is.na(a) || !nzchar(a)) b else a
# A setting's name is matched as TEXT, and two of the three carry a `$`. The
# escaper is spelled out character by character rather than with a class,
# because a class containing both braces is itself an invalid interval to R's
# regex engine -- which fails loudly here and would fail silently in a
# narrower pattern.
lit <- function(x) {
    for (ch in c("\\", ".", "$", "^", "|", "(", ")", "[", "]",
                 "{", "}", "*", "+", "?")) {
        x <- gsub(ch, paste0("\\", ch), x, fixed = TRUE)
    }
    x
}

# ===========================================================================
# 1. THE CAPTURE EXISTS, NAMES ALL THREE, AND GUARDS EACH ONE
# ===========================================================================
# DELIBERATELY THE SMALLEST SECTION IN THIS FILE, and nothing in it is trusted
# on its own: every claim here is re-made as a driven number in section 4. It
# is here because the source shape is what a later reader edits, and because a
# capture that named two of the three would show up below as one red rather
# than as a missing name.
# ===========================================================================
body_cap <- proc_body_of(code_rec, "emlRecordCaptureStats")
check_true(ID, "@emlRecordCaptureStats' body is closed and non-empty",
           length(body_cap) > 0)

for (s in SETTINGS) {
    check_true(ID,
        sprintf("@emlRecordCaptureStats writes %s into the step's code", s),
        any(grepl(sprintf("\"%s = ", lit(s)), body_cap)))
    # READ THROUGH variableExists, ONE NAME AT A TIME. The three belong to
    # three layers, so a stats-only script has the sort order and neither
    # annotation setting; reading one unconditionally ends a user's recording
    # with "Unknown variable". Praat does not short-circuit `and`, so a
    # combined guard would read the very name it was written to protect.
    check_true(ID,
        sprintf("and reads %s only through its own variableExists guard", s),
        any(grepl(sprintf("variableExists \\(\"%s\"\\)", lit(s)), body_cap)))
}
for (s in ALSO_CAPTURED) {
    check_true(ID,
        sprintf("@emlRecordCaptureStats also writes %s into the step's code", s),
        any(grepl(sprintf("\"%s = ", lit(s)), body_cap)))
    check_true(ID,
        sprintf("and reads %s only through its own variableExists guard", s),
        any(grepl(sprintf("variableExists \\(\"%s\"\\)", lit(s)), body_cap)))
}
check_true(ID,
    sprintf("the guards are one per setting (SETTINGS + ALSO_CAPTURED) and nothing is read unguarded (%d)",
            sum(grepl("variableExists \\(", body_cap))),
    sum(grepl("variableExists \\(", body_cap)) == length(SETTINGS) + length(ALSO_CAPTURED))

# THE ALPHA IS WRITTEN WITH string$, NOT fixed$. fixed$ takes a width, and an
# alpha finer than that width comes back a different number -- which is the
# one thing a value emitted for fidelity may not do.
check_true(ID, "the alpha is written with string$, so the value read is the value written",
           any(grepl("annotAlpha.*string\\$ \\(annotAlpha\\)", body_cap)) &&
           !any(grepl("fixed\\$ \\(annotAlpha", body_cap)))

# ===========================================================================
# 2. THE CAPTURE IS CALLED, ON THE STEPS THAT COMPUTE, IN FRONT OF THE CALL
# ===========================================================================
body_step <- proc_body_of(code_rec, "emlRecordStep")
check_true(ID, "@emlRecordStep's body is closed", length(body_step) > 0)
check_true(ID, "@emlRecordStep calls @emlRecordCaptureStats",
           any(grepl("^@emlRecordCaptureStats$", body_step)))
check_true(ID, "and prepends its output to the step's code rather than appending it",
           any(grepl("^\\.codeOut\\$ = emlRecordCaptureStats\\.out\\$ \\+ \\.codeOut\\$$",
                     body_step)))
# ON ANALYSIS AND DRAW ONLY. A read, a create, a convert and a save decide
# nothing these three govern. The guard is read off the line above the call
# rather than inferred, so a widening of it is visible here.
i_cap <- grep("^@emlRecordCaptureStats$", body_step)
guard <- if (length(i_cap)) body_step[max(1L, i_cap[1] - 1L)] else ""
check_true(ID,
    sprintf("the capture runs on analysis and draw steps and no others (%s)",
            guard %or% "<no call>"),
    identical(guard, "if .kind$ = \"analysis\" or .kind$ = \"draw\""))

# NEAREST THE CALL OF EVERYTHING PREPENDED. The page settings and the pens go
# in front of a draw too, and @emlBeginPanel is among them; the three settings
# here are what the recorded CALL itself reads, so they belong between that
# preamble and the call. Prepending in the other order would put
# @emlBeginPanel between a setting and the procedure that reads it, which is
# harmless today and is exactly the kind of ordering a later edit gets wrong.
i_page <- grep("^@emlRecordCapturePage$", body_step)
check_true(ID,
    "and it is prepended before the page and pen preamble, so it lands nearest the call",
    length(i_cap) == 1L && length(i_page) == 1L && i_cap[1] < i_page[1])

# ===========================================================================
# 3. THE PUBLICATION HALF -- EACH SETTING IS STATED BEFORE IT IS READ
# ===========================================================================
# THE RECORDER CAN ONLY CARRY WHAT IS LIVE AND CORRECT WHEN A STEP IS
# RECORDED. @emlRecordStep runs inside the same script scope as the operation
# that recorded it, so the form's globals are still readable there -- that is
# the whole reason the capture is in that procedure and not in the flush. What
# has to hold on the form's side is that each of the three states THIS press,
# not the one before it, and that it is stated before the bridge reads it.
# ===========================================================================
check_true(ID,
    "the bridge resolves the correction from the global, taking no parameter for it",
    !any(grepl("^procedure emlRunAnnotationComparison:.*annotCorrectionMethod", code_ann)) &&
    any(grepl("variableExists \\(\"annotCorrectionMethod\\$\"\\)", code_ann)))
check_true(ID,
    "every confidence interval in the reporters is built at @emlCIAlphaInForce's answer",
    sum(grepl("^@emlCIAlphaInForce$", code_ann)) >= 3 &&
    any(grepl("^\\.alpha = annotAlpha$", proc_body_of(code_ann, "emlCIAlphaInForce"))))
check_true(ID,
    "the level ordering the groups is the one @emlCountGroups reads",
    any(grepl("^if emlGroupSortAlphabetical = 1$", code_ext)))

# THE TWO ANNOTATION SETTINGS TRAVEL TOGETHER, ON EVERY PAGE THAT COMMITS
# EITHER. The form re-commits both from each graph type's column-mapping page,
# so a press of any annotating type states its complete choice; a page that
# committed the alpha and left the correction to the press before it would be
# a figure whose two halves came from two dialogs.
raw_form <- readLines(f_form, warn = FALSE)
i_alpha <- grep("^\\s*annotAlpha = alpha\\s*$", raw_form)
i_corr  <- grep("^\\s*annotCorrectionMethod\\$ = emlAdjustMethodName\\.name\\$\\s*$",
                raw_form)
check_true(ID,
    sprintf("every column-mapping page that commits the alpha commits the correction with it (%d pages)",
            length(i_alpha)),
    length(i_alpha) >= 6 &&
    all(vapply(i_alpha, function(k) any(i_corr > k & i_corr <= k + 15), logical(1))))

# AND THE SORT ORDER IS STATED BEFORE THE BRIDGE READS IT, in the dispatch
# region, from the dialog's own field. A statement after the bridge would
# order the levels by the previous press's menu and draw them by this one's.
i_sort <- grep("^\\s*emlGroupSortAlphabetical = config_groupSort - 1\\s*$", raw_form)
i_bridge <- grep("^\\s*@emlRunAnnotationComparison:", raw_form)
check_true(ID,
    sprintf("the group order is published from the dialog before the bridge reads it (line %s before %s)",
            paste(i_sort, collapse = "/") %or% "<none>",
            paste(head(i_bridge, 1), collapse = "/") %or% "<none>"),
    length(i_sort) >= 1 && length(i_bridge) >= 1 && any(i_sort < i_bridge[1]))

# ===========================================================================
# 4. THE DRIVEN HALF -- RECORD, REPLAY, COMPARE
# ===========================================================================
# The harness TSV, scoped by leg. Keys repeat inside a leg on purpose -- a
# report leg emits two group rows and a correction leg three p-values -- so a
# flat map would answer every one of them with the first.
read_legged_tsv <- function(path) {
    if (!file.exists(path)) return(list())
    x <- readLines(path, warn = FALSE)
    x <- x[nzchar(x)]
    out <- list(); leg <- ""
    for (ln in x) {
        p <- strsplit(ln, "\t", fixed = TRUE)[[1]]
        if (length(p) < 2L) next
        k <- p[1]; v <- paste(p[-1], collapse = "\t")
        if (identical(k, "leg")) { leg <- v; next }
        key <- if (nzchar(leg) && !identical(leg, "--shell--"))
                   paste0(leg, ".", k) else k
        if (is.null(out[[key]])) out[[key]] <- v
        else out[[key]] <- c(out[[key]], v)
    }
    out
}

TSV <- file.path(edir, "SETTINGSPUB.tsv")
kv <- read_legged_tsv(TSV)
check_true(ID, "harness/settingspub has been driven and left its evidence",
           length(kv) > 0)

LEGS <- c("corr_holm", "corr_bonf", "alpha_05", "alpha_01",
          "sort_disc", "sort_alpha")
REPORT_LEGS <- c("alpha_05", "alpha_01", "sort_disc", "sort_alpha")

one <- function(leg, k) {
    v <- kv[[paste0(leg, ".", leg, "_", k)]]
    if (is.null(v)) NA_character_ else v[1]
}
all_of <- function(leg, k) {
    v <- kv[[paste0(leg, ".", leg, "_", k)]]
    if (is.null(v)) character(0) else v
}

if (length(kv) > 0) {

check_true(ID,
    sprintf("the evidence was driven on a supported Praat (%s)",
            kv[["praat_version"]] %or% "<absent>"),
    grepl("^Praat 6\\.6\\.3[0-9]|^Praat [7-9]", kv[["praat_version"]] %or% ""))

for (leg in LEGS) {
    check_true(ID, sprintf("%s: the recording ran and flushed a script", leg),
               identical(one(leg, "record_exit"), "0") &&
               identical(one(leg, "flushed"), "1") &&
               identical(one(leg, "emitted"), "yes"))
    check_true(ID, sprintf("%s: and the emitted script ran in a fresh process", leg),
               identical(one(leg, "replay_exit"), "0"))
    # EVERY LEG STATES ALL THREE, not only the one under test. A step is
    # self-contained only when it states the settings it did not use: an
    # emitted script is one scope, so a step that leaves a correction behind
    # it hands the next step in the file one its own session never had.
    for (s in c("annotCorrectionMethod", "annotAlpha", "emlGroupSortAlphabetical")) {
        n <- one(leg, paste0("emits_", s))
        check_true(ID,
            sprintf("%s: the emitted script states %s exactly once (%s)",
                    leg, s, n %or% "<absent>"),
            identical(n, "1"))
    }
    # AND THE VALUE IN THE FILE IS THE VALUE THE SESSION SET. A name written
    # with the wrong number is the failure a name-only check cannot see.
    lines <- all_of(leg, "settingline")
    want <- c(sprintf("annotCorrectionMethod$ = \"%s\"", one(leg, "set_corr")),
              sprintf("annotAlpha = %s", one(leg, "set_alpha")),
              sprintf("emlGroupSortAlphabetical = %s", one(leg, "set_sort")))
    check_true(ID,
        sprintf("%s: and states the values the session ran under (%s)",
                leg, paste(lines, collapse = " | ") %or% "<none>"),
        setequal(lines, want))
    # AND THE REPLAYING PROCESS REALLY HELD THEM WHEN IT FINISHED. Read out
    # of the replay's own scope after the emitted file has run, each behind
    # its own variableExists, so a setting that never arrived reports
    # "<unset>" instead of aborting the probe -- "the setting did not arrive"
    # and "the replay crashed" are not the same finding.
    check_true(ID,
        sprintf("%s: the replaying process ends holding the session's three settings (%s, %s, %s)",
                leg, one(leg, "replay_corr_inforce") %or% "<absent>",
                one(leg, "replay_alpha_inforce") %or% "<absent>",
                one(leg, "replay_sort_inforce") %or% "<absent>"),
        identical(one(leg, "replay_corr_inforce"), one(leg, "set_corr")) &&
        identical(one(leg, "replay_alpha_inforce"), one(leg, "set_alpha")) &&
        identical(one(leg, "replay_sort_inforce"), one(leg, "set_sort")))
}

# ---- THE CORRECTION -------------------------------------------------------
# THE ADJUSTED p-VALUES THEMSELVES, not the caption above them. Both are read,
# because a replay that carried the caption and computed the other correction
# would satisfy either one alone.
for (leg in c("corr_holm", "corr_bonf")) {
    sp <- c(all_of(leg, "session_p1"), all_of(leg, "session_p2"),
            all_of(leg, "session_p3"))
    rp <- c(all_of(leg, "replay_p1"), all_of(leg, "replay_p2"),
            all_of(leg, "replay_p3"))
    check_true(ID,
        sprintf("%s: the replay computed the session's adjusted p-values (%s against %s)",
                leg, paste(sp, collapse = ", ") %or% "<none>",
                paste(rp, collapse = ", ") %or% "<none>"),
        length(sp) == 3L && identical(sp, rp))
    check_true(ID,
        sprintf("%s: and resolved the same correction (%s)",
                leg, one(leg, "replay_adjust") %or% "<absent>"),
        identical(one(leg, "session_adjust"), one(leg, "replay_adjust")) &&
        grepl(one(leg, "set_corr") %or% " ",
              one(leg, "replay_adjust") %or% "", fixed = TRUE))
}
check_true(ID,
    sprintf("and the correction is what moved them: holm %s against bonferroni %s",
            one("corr_holm", "replay_p1") %or% "<absent>",
            one("corr_bonf", "replay_p1") %or% "<absent>"),
    !is.na(one("corr_holm", "replay_p1")) && !is.na(one("corr_bonf", "replay_p1")) &&
    !identical(one("corr_holm", "replay_p1"), one("corr_bonf", "replay_p1")))
# The omnibus is the control: Kruskal-Wallis is computed before any
# correction, so it must NOT move between the two legs. A rig whose fixtures
# had drifted would move it too, and every difference above would then be
# about the data rather than about the setting.
check_true(ID,
    sprintf("the omnibus is unmoved by the correction, so the legs share their data (%s)",
            one("corr_holm", "omnibus") %or% "<absent>"),
    identical(one("corr_holm", "omnibus"), one("corr_bonf", "omnibus")) &&
    nzchar(one("corr_holm", "omnibus") %or% ""))

# ---- THE ALPHA AND THE GROUP ORDER ---------------------------------------
for (leg in REPORT_LEGS) {
    check_true(ID, sprintf("%s: both sides printed a report to compare", leg),
               identical(one(leg, "session_report"), "1") &&
               identical(one(leg, "replay_report"), "1"))
    for (k in c("ci", "meandiff", "sign", "t", "grouprow")) {
        s <- all_of(leg, paste0("session_", k))
        r <- all_of(leg, paste0("replay_", k))
        check_true(ID,
            sprintf("%s: the replay printed the session's %s (%s)",
                    leg, k, paste(s, collapse = " | ") %or% "<none>"),
            length(s) > 0 && identical(s, r))
    }
}
check_true(ID,
    sprintf("and the alpha is what moved the interval: %s against %s",
            one("alpha_05", "replay_ci") %or% "<absent>",
            one("alpha_01", "replay_ci") %or% "<absent>"),
    !identical(one("alpha_05", "replay_ci"), one("alpha_01", "replay_ci")) &&
    grepl("95%", one("alpha_05", "replay_ci") %or% "", fixed = TRUE) &&
    grepl("99%", one("alpha_01", "replay_ci") %or% "", fixed = TRUE))
# THE TWO ALPHA LEGS SHARE THEIR POINT ESTIMATE. Only the interval may move:
# a difference in the mean difference itself would mean the two legs analysed
# different numbers, and the interval comparison would then be about the data.
check_true(ID,
    sprintf("and only the interval moved -- the difference itself is the same (%s)",
            one("alpha_05", "replay_meandiff") %or% "<absent>"),
    identical(one("alpha_05", "replay_meandiff"),
              one("alpha_01", "replay_meandiff")) &&
    nzchar(one("alpha_05", "replay_meandiff") %or% ""))

check_true(ID,
    sprintf("the group order is what reversed the difference: %s against %s",
            one("sort_disc", "replay_meandiff") %or% "<absent>",
            one("sort_alpha", "replay_meandiff") %or% "<absent>"),
    !identical(one("sort_disc", "replay_meandiff"),
               one("sort_alpha", "replay_meandiff")) &&
    grepl("zulu minus alfa", one("sort_disc", "replay_sign") %or% "", fixed = TRUE) &&
    grepl("alfa minus zulu", one("sort_alpha", "replay_sign") %or% "", fixed = TRUE))
check_true(ID,
    sprintf("and it swapped which group the replay names first (%s | %s)",
            all_of("sort_disc", "replay_grouprow")[1] %or% "<absent>",
            all_of("sort_alpha", "replay_grouprow")[1] %or% "<absent>"),
    grepl("^ zulu", all_of("sort_disc", "replay_grouprow")[1] %or% "") &&
    grepl("^ alfa", all_of("sort_alpha", "replay_grouprow")[1] %or% ""))
# The sort legs run at one alpha, so their intervals must be the same width
# and opposite in sign. That is what separates "the order moved" from "the
# whole analysis moved".
check_true(ID,
    sprintf("the sort legs share their alpha, so only the sign moved (%s | %s)",
            one("sort_disc", "replay_ci") %or% "<absent>",
            one("sort_alpha", "replay_ci") %or% "<absent>"),
    grepl("95%", one("sort_disc", "replay_ci") %or% "", fixed = TRUE) &&
    grepl("95%", one("sort_alpha", "replay_ci") %or% "", fixed = TRUE) &&
    !identical(one("sort_disc", "replay_ci"), one("sort_alpha", "replay_ci")))

# ---- WHAT THE EMITTED FILE LOOKS LIKE, READ OFF DISK ----------------------
# Read out of the file a user would run, not out of the TSV, and anchored, so
# a comment that names a setting is never counted as a statement of one. The
# ORDER is the claim: a setting written after the call that reads it is a line
# in the file and a value the replay never saw.
for (leg in LEGS) {
    f <- file.path(edir, leg, "emitted.praat")
    if (!file.exists(f)) {
        check_true(ID, sprintf("%s: the emitted script is on disk", leg), FALSE)
        next
    }
    txt <- readLines(f, warn = FALSE)
    i_set <- grep(paste0("^(", paste(vapply(SETTINGS, lit, ""), collapse = "|"),
                         ") = "), txt)
    i_call <- grep("^@(emlRunAnnotationComparison|emlRunTwoGroupAnalysis):", txt)
    check_true(ID,
        sprintf("%s: all three settings stand ahead of the call that reads them (%d of 3 before line %s)",
                leg, sum(i_set < (if (length(i_call)) i_call[1] else 0L)),
                paste(head(i_call, 1), collapse = "") %or% "<no call>"),
        length(i_call) >= 1 && length(i_set) == 3L && all(i_set < i_call[1]))
}

}

# ===========================================================================
# 5. WHAT THIS FILE DOES NOT OWN
# ===========================================================================
attest(ID,
    "the census's frame holds one of the three, and moves by one",
    "validate/tools/recorder_census.py counts globals seeded in @emlInitializeDrawingDefaults: 14 of 41 assigned in a committed recording before this work, 15 after, with the not-emitted user choices going 18 to 17. The one it can see is annotAlpha. annotCorrectionMethod$ belongs to the graphs form and emlGroupSortAlphabetical to stats/eml-extract.praat, so neither is in that frame however faithfully a recording carries it -- section 4 is where those two are measured.")
attest(ID,
    "twelve display-only settings still reach no recorded script",
    "v112's census classifies them and names them: the font, the gridline mode, the legend placement, the tick, axis-name and axis-value flags, the inner box, the subtitle, the annotation style, the scatter's dot size and its formula toggle. None of them changes a number, which is why they are a separate unit of work and not this one. Their absence is measured, not assumed.")

if (!exists("EML_SUITE")) {
    eml_report("v115 the settings that decide the numbers reach the recorded script")
    eml_exit()
}
