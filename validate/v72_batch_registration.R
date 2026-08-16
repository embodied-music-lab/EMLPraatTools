# ============================================================================
# v72_batch_registration.R -- the door is registered, and somebody walked it
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULING THIS FILE IMPLEMENTS (author, 16 August 2026): register batch
# voice analysis, and double-check it against PraatGen standards. The module
# was unregistered on 6 August 2026 for want of coverage, and the coverage
# arrived -- 255 checks over v52, v53 and v54. What none of those three could
# say anything about is the two things a registration is: that the MENU ENTRY
# is there and reaches this module and nothing else, and that the FORM behind
# it comes up and works. This file is about those two, and about the two
# APPENDIX_D §7 rules the module had never implemented.
#
# WHY THE EXISTING 255 CANNOT COVER ANY OF IT. v52 reads the source. v54 reads
# the source and probes command signatures. v53 is the strong one -- seven
# corpora driven end to end -- and it reaches the loop by CUTTING THE TWO
# DIALOG STANZAS OUT of the shipped file, mechanically and hash-verified,
# because beginPause:/endPause: hard-crashes under `praat --run` (exit 133,
# GUI_HARNESS_RECIPE §0). So the best evidence in this tree about this module
# is evidence gathered with its form deleted, and no amount of it says the
# form opens. v53's own header says as much at :78-84: the entry had no menu
# registration, so a harness that drives menus could not reach it, and the
# coverage gap and the tabling had the same cause.
#
# WHAT THE FAILURE LOOKS LIKE, and it has happened here twice. The graphs
# form's Exp CSV button wrote the wrong format for weeks because nothing
# pressed it. Nine of @emlSavePanel's ten callers died on the FIRST press of
# Save with "Unknown variable: emlLastCSVFolder$", taking the user's analysis
# with them, while v46 -- which reads the call sites and proves the string
# "@emlSavePanel" appears in each -- passed every day. Both are the same
# shape: a claim about source, true, standing in for a claim about behaviour,
# untested. A registered menu entry that has never been clicked is that shape
# with a menu bar in front of it, which is what the audit's severity-2 "dead
# door" findings were about.
#
# WHAT COULD NOT HAVE CAUGHT ANY OF THIS, and why:
#
#   A CHECK ON THE REGISTRATION LINES ALONE. Sections 1 and 2 below are
#   exactly that check, and they are worth having, but they would pass
#   word-perfect against an entry pointing at a script whose first dialog
#   raises an error, against an entry that renders in a different place than
#   its after$ argument says, and against an entry that renders nowhere at all
#   because a duplicate anchor swallowed it. All three are live risks in this
#   file: setup.praat's own comment about the after$ chain was WRONG, and the
#   proof is section 3.
#
#   COUNTING THE MENU ENTRIES. Eighteen commands render where seventeen did.
#   A count moves the same way whether the new entry is where it should be,
#   at the foot of the submenu, or in the middle of the compare group. It also
#   moves the same way if one entry is added and none removed, which is the
#   only case a count can distinguish, and it is the case nobody was worried
#   about.
#
#   A SCREENSHOT. harness/batchgui takes five, and they are for a human. GTK
#   menu items have no X window and no queryable property, so no validator can
#   read one. The machine-readable fact about a menu item's position is which
#   command a FIXED KEYBOARD WALK arrives at -- and that fact is worth nothing
#   on its own, because a walk that reached the right dialog by luck reports
#   the same string. So the harness walks TWICE, the second time against a
#   setup.praat with the two registration lines mechanically cut, and the two
#   walks must reach DIFFERENT dialogs. Section 3 is that pair. Without the
#   negative leg this whole file would be unfalsifiable and green.
#
#   A SIZE OR PRESENCE THRESHOLD ON THE OUTPUT. The drive writes a CSV. A
#   check that it exists, or that it is over some number of bytes, passes on a
#   file of three rows of --undefined--. Section 4 reads the VALUES back and
#   requires them to be the synthesised frequencies of the three fixtures --
#   78, 180 and 640 Hz -- which is also the only thing here that proves the
#   row-to-file pairing survived the GUI.
#
#   A CHECK THAT THE WARNINGS EXIST. Section 5 is the APPENDIX_D §7 work, and
#   the tempting check is "the log contains a range warning". That passes on a
#   guard that fires on every segment, which is a guard that says nothing. So
#   the fixtures are built to divide: 78 Hz must trip the 75 Hz raw-cross-
#   correlation floor and must NOT trip the 50 Hz filtered-autocorrelation
#   floor; 640 Hz must trip the 330 Hz cepstral ceiling and must NOT trip its
#   60 Hz floor; 180 Hz must trip nothing. The silences are checked as hard as
#   the warnings.
#
#   A CHECK ON THE COMMENT RATHER THAN THE CODE. Every band in section 5 is
#   pinned against the whitespace-collapsed CODE line with WHOLE-LINE
#   equality, never a substring search -- v53 learned that one the hard way
#   when a break test widening the CPPS band from 25 to 250 sailed through
#   grepl(fixed = TRUE), "cppsVal > 250" containing "cppsVal > 25". And the
#   comparisons are pinned as `.lo < .floor * 1.1` and `.hi > .ceiling * 0.9`,
#   both of them, because APPENDIX_D says in terms that "a floor-only guard is
#   half a guard" and a half guard leaves no other trace.
#
# THE FIX-SHAPED FIX THIS FILE HAS TO REFUSE. The two new guards produce Info
# window text and nothing else -- no column, no cell, no exported number. The
# cheap way to satisfy a validator asking for a warning is to emit one
# unconditionally; the cheap way to satisfy one asking for a value is to write
# a constant. Section 5 therefore requires the warning to CARRY THE MEASURED
# NUMBER and the stated-value warning to NAME THE TWO PARAMETERS THAT WERE
# DERIVED FROM THE STATED VALUE with their computed values (800 and 600 for a
# stated 300), which is what APPENDIX_D §7 asks for in terms and what a
# constant cannot supply.
#
# Inputs: harness/batchgui/out/BATCHGUI.tsv, INFO.txt, RESULTS.csv.
#         $EML_BATCHGUI_DIR overrides the evidence folder, $EML_SETUP_FILE the
#         registration under test and $EML_BATCH_FILE the module -- the last
#         two are the names v59 and v52 already use, so one break test drives
#         every validator that reads the same file.
#
#   bash harness/batchgui/run.sh
#   Rscript validate/v72_batch_registration.R
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

setup_path <- Sys.getenv("EML_SETUP_FILE", unset = "")
if (!nzchar(setup_path)) setup_path <- repo_path(file.path("plugin", "setup.praat"))
src <- Sys.getenv("EML_BATCH_FILE", unset = "")
if (!nzchar(src)) src <- repo_path(file.path("plugin", "scripts",
                                             "eml-batch-process.praat"))
plug <- dirname(setup_path)

ok_setup <- check_true("v72", "plugin/setup.praat is present",
                       file.exists(setup_path))
ok_src <- check_true("v72", "the batch module is present", file.exists(src))
if (!ok_setup || !ok_src) {
    if (!exists("EML_SUITE")) { eml_report("v72 batch registration"); eml_exit() }
}

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS, AND DROP COMMENTS
# ---------------------------------------------------------------------------
# The same preparation v52 and v53 make, and for the same two reasons. Every
# guard call in this module is written across two or three lines with "..."
# continuations, so a line-at-a-time regex matches the head of a call and never
# sees the arguments -- the shape of a check that passes while proving nothing.
# And a commented-out registration is not a promise to anybody: v59 excludes
# them explicitly because the tabled entries sit in setup.praat as comments by
# standing author ruling.
.prep <- function(path) {
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
    list(raw = raw, norm = norm, code = norm[!grepl("^#", norm)])
}

S <- if (file.exists(setup_path)) .prep(setup_path) else list(raw = character(0),
                                                              norm = character(0),
                                                              code = character(0))
M <- if (file.exists(src)) .prep(src) else list(raw = character(0),
                                                norm = character(0),
                                                code = character(0))

# ---------------------------------------------------------------------------
# 1. THE REGISTRATION ITSELF
# ---------------------------------------------------------------------------
# Add menu command: window$, menu$, title$, after$, depth, script$
# (BEST_PRACTICES_PLUGIN_ARCHITECTURE §3). The strings in order ARE the string
# arguments in order -- nothing in this file's arguments carries an escaped
# quote -- which is how v59 reads the same lines.
.fields <- function(ln) gsub('"', "", regmatches(ln, gregexpr('"[^"]*"', ln))[[1]])

menu_lines <- S$code[grepl("^Add menu command:", S$code)]
act_lines  <- S$code[grepl("^Add action command:", S$code)]

# THE ENTRY IS FOUND BY TITLE **OR** BY SCRIPT, AND THE `OR` IS THE WHOLE
# POINT. This took two corrections to get right, and both were found by break
# tests rather than by reading.
#
# The first version located the line by grepping for "Batch voice analysis...",
# ellipsis and all, and then checked that its title ended in an ellipsis. That
# check COULD ONLY PASS: stripping the ellipsis made the line invisible to the
# finder, so a different check failed and the ellipsis check was never
# evaluated. The second version located it by its script path and then checked
# the script path — the identical trap, one attribute along, and the break test
# that repointed the registration at a file that does not exist sailed through
# for the same reason.
#
# A finder keyed on ONE attribute can never fail a check ON that attribute. So
# the line is found if EITHER identifies it, and then every attribute is
# asserted separately and every one of them can disagree. Damage both and the
# entry really has gone, which is what the count check below is for.
cmd_line <- Filter(function(ln) {
    f <- .fields(ln)
    (length(f) >= 3 && identical(f[3], "Batch voice analysis...")) ||
        grepl("eml-batch-process\\.praat", ln)
}, menu_lines)

# AND THE SEPARATOR IS FOUND BY STRUCTURE: it is the scriptless entry whose
# TITLE is what the command's after$ names. Found by its label instead, a
# renamed label would again vanish rather than fail.
after_of_cmd <- if (length(cmd_line) == 1) .fields(cmd_line[1])[4] else NA_character_
sep_line <- Filter(function(ln) {
    f <- .fields(ln)
    length(f) >= 4 && !is.na(after_of_cmd) && identical(f[3], after_of_cmd) &&
        (length(f) < 5 || !nzchar(f[5]))
}, menu_lines)

check_true("v72",
           sprintf("the batch command is registered exactly once (%d live line(s))",
                   length(cmd_line)),
           length(cmd_line) == 1)
check_true("v72",
           sprintf("its separator is registered exactly once (%d live line(s))",
                   length(sep_line)),
           length(sep_line) == 1)

if (length(cmd_line) == 1) {
    f <- .fields(cmd_line[1])
    # window$, menu$, title$, after$, script$  (depth is a bare number)
    check_true("v72", sprintf("it registers on the Objects window (%s)", f[1]),
               identical(f[1], "Objects"))
    check_true("v72", sprintf("in the New menu (%s)", f[2]),
               identical(f[2], "New"))
    # "..." IS A PROMISE OF A DIALOG (architecture §3). This entry raises a
    # form before it does anything, so the ellipsis is required; an entry that
    # opens a dialog without one is the mirror of a dead door.
    check_true("v72",
               sprintf("its title ends in the ellipsis that promises a dialog (%s)",
                       f[3]),
               grepl("\\.\\.\\.$", f[3]))
    check_true("v72",
               sprintf("its title is the one the ruling names (%s)", f[3]),
               identical(f[3], "Batch voice analysis..."))
    check_true("v72", "it is chained to the batch separator",
               identical(f[4], "-- eml batch --"))
    check_true("v72", "it points at scripts/eml-batch-process.praat",
               identical(f[5], "scripts/eml-batch-process.praat"))
    # A REGISTRATION IS A PROMISE THAT THE FILE IS THERE. The cheapest dead
    # door in this plugin has already shipped once -- the interactive tutorial
    # was registered at v1.3 against an include of a directory that does not
    # exist. v59 makes this check over every registration; it is repeated here
    # because a break test that repoints this one line must go red in the file
    # that owns it.
    check_true("v72", "and that script exists on disk",
               file.exists(file.path(plug, f[5])))
    # DEPTH 1 -- a child of the EML Tools cascade, not a sibling of it. Depth 0
    # would put "Batch voice analysis..." in Praat's own New menu beside
    # "Create TextGrid...", which is a different claim about what this plugin
    # is.
    check_true("v72", "at depth 1, inside the EML Tools cascade",
               grepl(",\\s*1\\s*,\\s*\"scripts/eml-batch-process\\.praat\"",
                     cmd_line[1]))
}

if (length(sep_line) == 1) {
    fs <- .fields(sep_line[1])
    check_true("v72", "the separator carries no script, as a separator must",
               length(fs) == 4 || (length(fs) >= 5 && !nzchar(fs[5])))
    # THE AUTHOR'S OWN RESTORE POSITION, from the tabling note of 6 August
    # 2026: after "EML Graphs...". Pinned so that moving the entry is a
    # deliberate act that has to argue with this line.
    check_true("v72", sprintf("it is chained after EML Graphs... (%s)", fs[4]),
               identical(fs[4], "EML Graphs..."))
    # THE LABEL FOLLOWS THIS PLUGIN'S OWN CONVENTION, which is the only thing
    # about it that can be checked: section 3 establishes that the text is
    # never rendered at all, so "reads correctly for a voice researcher" is a
    # question about this FILE's legibility and about the grouping the rule
    # makes, not about anything on screen.
    check_true("v72", "and its label follows the -- eml <section> -- convention",
               grepl("^-- eml [a-z]+ --$", fs[3]))
}

# ---------------------------------------------------------------------------
# 2. NO ACTION BUTTON, ON ANY OBJECT TYPE
# ---------------------------------------------------------------------------
# THE RULING, and it is a ruling rather than an omission. Every other EML entry
# point is registered on the class it CONSUMES -- Table, TableOfReal, Matrix,
# Sound, Pitch, Spectrum, Ltas -- because it acts on the selection. This module
# never looks at the selection: it takes a folder of files off disk. PraatGen's
# BEST_PRACTICES_PLUGIN_ARCHITECTURE §4 shows the legal shape for exactly this
# idea, `Add action command: "Sound", 0, …` for a "Batch process..." button,
# and taking that shape here would produce a button that appears BECAUSE a
# Sound is selected and then ignores it. That is the same class of defect as a
# button that does nothing, and it is the kind that gets added later by someone
# reading §4 and not this note -- which is why it is pinned rather than assumed.
check_true("v72",
           sprintf("no action button registers the batch module (%d of %d action lines)",
                   sum(grepl("eml-batch-process", act_lines)), length(act_lines)),
           !any(grepl("eml-batch-process", act_lines)))

# ---------------------------------------------------------------------------
# 3. THE MENU AS RENDERED, AND THE WALK THAT PROVES IT
# ---------------------------------------------------------------------------
bg <- Sys.getenv("EML_BATCHGUI_DIR", unset = "")
if (!nzchar(bg)) bg <- repo_path(file.path("harness", "batchgui", "out"))
tsvp <- file.path(bg, "BATCHGUI.tsv")

B <- NULL
if (file.exists(tsvp)) {
    x <- read.delim(tsvp, header = FALSE, sep = "\t", quote = "",
                    stringsAsFactors = FALSE, fill = TRUE,
                    col.names = c("k", "v"))
    B <- setNames(as.list(trimws(as.character(x$v))), trimws(as.character(x$k)))
}
bs <- function(k) if (!is.null(B) && !is.null(B[[k]])) B[[k]] else NA_character_
bn <- function(k) suppressWarnings(as.numeric(bs(k)))

ran <- check_true("v72",
                  "the GUI drive was run (bash harness/batchgui/run.sh)",
                  !is.null(B))

if (ran) {
    check_true("v72", "the drive ran to completion",
               identical(bs("completed"), "1"))
    # THE FLOOR. A green drive on a build below the plugin's own floor is not
    # evidence about the plugin, and two of the pitch commands this module
    # calls do not exist below 6.6.30 at all. Same rule as v52's.
    check_true("v72",
               sprintf("driven on the target build (%s)", bs("praat_version")),
               grepl("6\\.6\\.30|7\\.", bs("praat_version")))

    # THE POSITIVE LEG.
    check_true("v72",
               sprintf("a keyboard walk of %s commands into the EML Tools cascade reaches the batch dialog (\"%s\")",
                       bs("menu_ordinal"), bs("menu_after_title")),
               identical(bs("menu_after_title"), "Batch Voice Analysis"))
    check_true("v72", "and the dialog it reached is the one the drive then filled",
               identical(bs("drive_reached_dialog"), "1"))

    # THE NEGATIVE LEG, WITHOUT WHICH THE POSITIVE ONE IS NOT EVIDENCE. The
    # same keystrokes against a setup.praat with the two registration lines
    # cut must arrive somewhere else. If they arrive at the batch dialog
    # anyway, the entry is reachable by some route this file does not know
    # about and every position claim above is void; if they arrive nowhere,
    # there is no comparison at all and the positive leg could have been luck.
    check_true("v72",
               sprintf("with the registration removed the SAME walk reaches a different dialog (\"%s\")",
                       bs("menu_before_title")),
               nzchar(bs("menu_before_title")) &&
                   !identical(bs("menu_before_title"), "Batch Voice Analysis"))
    # AND IT REACHES THE NEIGHBOUR, which is the positive form of the same
    # fact: with the entry gone, the thirteenth command is the one that sits
    # immediately after it, so this string is where the entry was inserted.
    check_true("v72",
               "and that dialog is the entry's own neighbour, Check & repair data",
               grepl("Check & repair data", bs("menu_before_title"), fixed = TRUE))
    # EXACTLY TWO LINES WERE CUT. A cut that took three would have removed
    # something else and the two legs would differ by more than the
    # registration, which is the only thing they are allowed to differ by.
    check_true("v72",
               sprintf("exactly the two registration lines were cut to make the negative leg (%s)",
                       bs("setup_before_removed")),
               identical(bs("setup_batch_lines"), "2") &&
                   identical(bs("setup_before_removed"), "2"))

    # THE ENTRY COUNT, BEFORE AND AFTER, re-derived here rather than read off
    # the harness -- two presentations of the same fact that can disagree.
    #
    # Menu commands WITH A SCRIPT: cascade headers and separators carry an
    # empty script and are not entry points, which is v59's rule. AND IN THE
    # OBJECTS WINDOW'S New MENU, which the first version of this check forgot:
    # setup.praat also registers "EML: Edit Table..." in the TableEditor's Edit
    # menu, so the unfiltered count came to 19 against a submenu that renders
    # 18 items in harness/batchgui/out/menu_after.png. A count that disagrees
    # with the photograph of the thing it counts is worse than no count -- it
    # is a number a reader would carry into a release note.
    with_script <- Filter(function(ln) {
        f <- .fields(ln)
        length(f) >= 5 && nzchar(f[5]) &&
            identical(f[1], "Objects") && identical(f[2], "New")
    }, menu_lines)
    n_after <- length(with_script)
    n_before <- n_after - length(cmd_line)
    check_true("v72",
               sprintf("the Objects>New>EML Tools cascade registers %d commands, one more than the %d it carried while batch was tabled",
                       n_after, n_before),
               n_after == n_before + 1 && n_after == 18)
}

# ---------------------------------------------------------------------------
# 4. THE FORM CAME UP AND THE RUN WENT THROUGH IT
# ---------------------------------------------------------------------------
csvp <- file.path(bg, "RESULTS.csv")
if (ran) {
    check_true("v72", "the batch range dialog followed the settings dialog",
               identical(bs("range_title"), "Batch range"))
    check_true("v72", "the Info window was raised",
               identical(bs("info_window_present"), "1"))

    # THE COLUMN SET IS THE PROOF THAT THE TICKBOXES WERE TICKED. The drive
    # clicks six checkboxes by in-window offset, and a click that missed
    # produces no error and no visible difference -- it produces a CSV with
    # fewer measure columns. So the header is the readback of six presses.
    want_header <- paste("file,status,mean_F0_Hz,mean_intensity_dB",
                         "jitter_local,shimmer_local,HNR_dB,CPPS_dB", sep = ",")
    check_true("v72",
               sprintf("all six measure boxes registered as ticked (%s)",
                       bs("csv_header")),
               identical(bs("csv_header"), want_header))

    # THE AUTHOR RULING OF 14 AUGUST 2026, both halves: the results go to the
    # designated output folder, and nothing this script writes lands among the
    # recordings. The GUI leg is the first evidence for it that came through
    # the form's own pre-filled default rather than a variable set by a twin.
    check_true("v72",
               sprintf("the CSV landed in the output folder the form proposed (%s)",
                       bs("csv_folder")),
               identical(bs("csv_folder"), "EML Batch Results"))
    check_true("v72",
               sprintf("and nothing was written into the corpus (%s extra file(s))",
                       bs("corpus_extra_files")),
               identical(bs("corpus_extra_files"), "0"))

    check_true("v72", "three files in, three rows out, three processed",
               identical(bs("csv_rows"), "3") &&
                   identical(bs("summary_rows"), "3") &&
                   identical(bs("summary_processed"), "3"))
}

# THE VALUES, NOT THE FILE. A check that the CSV exists, or that it is over
# some size, passes on three rows of --undefined--; the 20 KB threshold that a
# 52 KB empty frame sailed through is the same mistake with a different unit.
# These three numbers are the frequencies the fixtures were synthesised at, so
# recovering them proves the drive measured the corpus AND that row 1 is
# g1_low -- the pairing that no static check can see.
fixture_f0 <- c(g1_low = 78, g2_mid = 180, g3_high = 640)
covered <- character(0)
if (ran && check_true("v72", "the drive's own CSV was collected",
                      file.exists(csvp))) {
    R <- read.csv(csvp, stringsAsFactors = FALSE)
    for (stem in names(fixture_f0)) {
        v <- suppressWarnings(as.numeric(R$mean_F0_Hz[R$file == stem]))
        check("v72",
              sprintf("%s recovers its synthesised F0 through the GUI", stem),
              fixture_f0[[stem]], if (length(v) == 1) v else NA_real_, tol = 1)
        check_true("v72", sprintf("%s is marked ok, not FAILED", stem),
                   identical(R$status[R$file == stem], "ok"))
    }
}

# ---------------------------------------------------------------------------
# 5. APPENDIX_D §7, THE TWO HARD RULES THIS MODULE DID NOT IMPLEMENT
# ---------------------------------------------------------------------------
# "GUARD BOTH ENDS OF EVERY BOUNDED RANGE (hard) -- A floor-only guard is half
# a guard. Warn when a measurement approaches EITHER limit of any bounded
# ANALYSIS range", and "CHECK THE USER'S STATED RANGE AGAINST THE MEASUREMENT
# (hard) -- the stated value is an INPUT to parameter derivation … so a wrong
# statement propagates silently into every downstream parameter."
#
# A PLAUSIBILITY BAND IS NOT AN ANALYSIS RANGE, and v53 already covers the
# bands. The distinction is the whole point of this section: a band asks
# whether a RESULT is credible, and no band can ask whether the SEARCH that
# produced it was wide enough. A tracker asked for 50-800 Hz returns a value in
# 50-800 Hz whatever the voice did, so the number is censored rather than
# wrong, and nothing about its value says so.
if (file.exists(src)) {
    # BOTH COMPARISONS, PINNED WHOLE-LINE. Substring matching is what let a
    # break test widening v53's CPPS band from 25 to 250 pass -- "cppsVal >
    # 250" contains "cppsVal > 25" -- so the comparison is against the
    # whitespace-collapsed code line in full. The margins are APPENDIX_D's
    # own: its sample code is `if maxF0 > 0.9 * ceiling`, and the floor test
    # is its mirror.
    check_true("v72",
               "APPENDIX_D §7: the range guard tests the FLOOR (.lo < .floor * 1.1)",
               any(M$code == "if .lo < .floor * 1.1"))
    check_true("v72",
               "APPENDIX_D §7: and the CEILING (.hi > .ceiling * 0.9), which is the half the appendix says is missed",
               any(M$code == "if .hi > .ceiling * 0.9"))
    check_true("v72", "both live in one procedure, so there is one place to break",
               sum(grepl("^procedure emlWarnNearRangeEnd:", M$code)) == 1)

    # EVERY BOUNDED RANGE IN THE MODULE IS HANDED TO IT, with its own limits.
    # Three ranges, three different floors -- 50, 75 and 60 -- so a single
    # guard against the lowest of them would pass a segment two of the three
    # could not measure.
    calls <- list(
        list(id = "filtered autocorrelation (50 .. facPitchTop)",
             pat = "@emlWarnNearRangeEnd: facMinF0, facMaxF0, 50, facPitchTop,"),
        list(id = "raw cross-correlation (75 .. rccPitchCeiling)",
             pat = "@emlWarnNearRangeEnd: rangeF0Min, rangeF0Max, 75, rccPitchCeiling,"),
        list(id = "cepstral peak search (cppsSearchFloor .. cppsSearchCeiling)",
             pat = paste("@emlWarnNearRangeEnd: rangeF0Min, rangeF0Max,",
                         "cppsSearchFloor, cppsSearchCeiling,"))
    )
    for (k in calls) {
        check_true("v72",
                   sprintf("APPENDIX_D §7: the %s range is guarded against its OWN limits",
                           k$id),
                   any(grepl(k$pat, M$code, fixed = TRUE)))
    }

    # THE MIRROR PIN. 60 and 330 are canonical LITERALS inside `Get CPPS:` --
    # v52 compares that whole argument list to the appendix argument by
    # argument, which is why they were not replaced by the two variables the
    # guard needs. Two copies of a number is a drift risk, and this is where it
    # is closed: the guard's constants are required to equal the fourth and
    # fifth arguments of the shipped call. Change either end alone and this
    # goes red.
    cpps <- M$code[grepl("Get CPPS\\s*:", M$code)]
    if (check_true("v72", "the Get CPPS call can be read", length(cpps) == 1)) {
        a <- trimws(strsplit(sub("^.*Get CPPS\\s*:\\s*", "", cpps[1]), ",")[[1]])
        check_true("v72",
                   sprintf("cppsSearchFloor mirrors the search floor in Get CPPS (%s)",
                           a[4]),
                   any(M$code == paste0("cppsSearchFloor = ", a[4])))
        check_true("v72",
                   sprintf("cppsSearchCeiling mirrors the search ceiling in Get CPPS (%s)",
                           a[5]),
                   any(M$code == paste0("cppsSearchCeiling = ", a[5])))
    }

    # THE EXTREMES ARE ACTUALLY READ. Guard calls against variables nothing
    # assigns would be a guard that never fires and never errors, because
    # Praat would raise "Unknown variable" only when the branch ran -- and the
    # branch is inside `if mean_F0`.
    for (q in c("facMinF0 = Get minimum: 0, 0, \"Hertz\", \"parabolic\"",
                "facMaxF0 = Get maximum: 0, 0, \"Hertz\", \"parabolic\"",
                "rccMinF0 = Get minimum: 0, 0, \"Hertz\", \"parabolic\"",
                "rccMaxF0 = Get maximum: 0, 0, \"Hertz\", \"parabolic\"")) {
        check_true("v72", sprintf("the extreme is measured, not assumed: %s",
                                  sub(" = .*", "", q)),
                   any(M$code == q))
    }

    # THE STATED VALUE IS COMPARED TO THE MEASUREMENT. The appendix's own
    # observed failure: "user stated F0 stayed below 300 Hz; measurement
    # returned 322.87 Hz; nothing flagged it."
    check_true("v72",
               "APPENDIX_D §7: the measured maximum is compared with the stated highest expected F0",
               any(M$code == "if rangeF0Max > highest_expected_F0"))

    # AND NONE OF IT MAY EXIT. The appendix forbids it in the same sentence
    # that requires the warning -- "Do NOT exitScript -- the user may have
    # valid reasons" -- and a warning turned into an exit stops an overnight
    # batch on its first unusual file. THE ANCHORS ARE ASSERTED, NOT ASSUMED:
    # v53 records that its first version anchored on an unindented comment,
    # matched nothing, and the check silently did not exist.
    a1 <- grep("^\\s*# Bounded analysis ranges, both ends", M$raw)
    a2 <- grep("^\\s*# Write row to results table", M$raw)
    if (check_true("v72", "the range-guard section can be located in the source",
                   length(a1) == 1 && length(a2) == 1 && a1[1] < a2[1])) {
        seg <- M$raw[a1[1]:a2[1]]
        check_true("v72",
                   "APPENDIX_D §7: nothing in the range-guard section calls exitScript",
                   !any(grepl("exitScript", seg)))
        # AND IT MOVES NO NUMBER. The standing constraint on this work is that
        # a printed format may change and a computed or exported value may
        # not. The section is Info-window output and a warning count; if it
        # ever writes a cell or names a column, the CSV a user already has
        # stops matching the CSV this module produces.
        check_true("v72",
                   "and writes nothing to the results Table -- no cell, no column",
                   !any(grepl("Set (numeric|string) value|colNames\\$", seg)))
    }

    # THE CONFIGURATION THAT SWITCHES A GUARD OFF SAYS SO. Tick CPPS and no
    # pitch measure and there is no track to compare against the 60-330 Hz
    # window. A guard that quietly does not run is this whole section's own
    # failure mode one level up, and the summary's "Warnings: 0" would read as
    # "nothing was wrong" while meaning "nothing was checked".
    check_true("v72",
               "a CPPS-only run is TOLD its range guard cannot run",
               any(M$code == "if cPPS and not mean_F0 and not needsRccPitch"))
}

# ---------------------------------------------------------------------------
# 6. THE GUARDS FIRED, AND THEY FIRED SELECTIVELY
# ---------------------------------------------------------------------------
# The silences matter as much as the warnings. A guard that fires on every
# segment satisfies "the log contains a range warning" and tells a user
# nothing, and it is the cheapest way to make section 5 green without making
# anything true. Each fixture was built to answer differently.
if (ran) {
    fires <- list(
        list(k = "warn_rcc_floor", want = "1",
             why = "78 Hz is 4% above the 75 Hz raw-cross-correlation floor, so the track under its jitter and shimmer is censored"),
        list(k = "warn_fac_floor", want = "0",
             why = "and 56% above the 50 Hz filtered-autocorrelation floor, so THAT guard must stay silent"),
        list(k = "warn_cpps_ceiling", want = "1",
             why = "640 Hz is nearly twice the 330 Hz cepstral search ceiling, which no user setting widens"),
        list(k = "warn_cpps_floor", want = "0",
             why = "and nowhere near its 60 Hz floor"),
        list(k = "warn_stated", want = "1",
             why = "640 Hz measured against 300 Hz stated is the appendix's own observed failure"),
        list(k = "warn_stated_names_derived", want = "1",
             why = "and the warning names the two parameters the stated value derived, 800 and 600")
    )
    for (fr in fires) {
        check_true("v72",
                   sprintf("%s = %s -- %s", fr$k, fr$want, fr$why),
                   identical(bs(fr$k), fr$want))
    }
    covered <- c(covered, vapply(fires, function(z) z$k, character(1)))

    # S7C: EVERY WARNING IS COUNTED. The summary's number is what a user reads,
    # and a warning the summary does not count is a warning that scrolled past
    # during a four-hour run. The two-line stated-value warning counts once,
    # which is why the line count and the summary agree at six rather than
    # seven.
    check_true("v72",
               sprintf("APPENDIX_F S7C: the summary counts every warning line (%s printed, %s counted)",
                       bs("info_warning_lines"), bs("summary_warnings")),
               is.finite(bn("info_warning_lines")) &&
                   bn("info_warning_lines") == bn("summary_warnings"))

    # THE WARNING CARRIES THE MEASUREMENT, which is what a constant cannot do.
    # Clamping every number to a zero of the right width satisfies a width
    # assertion; emitting a fixed sentence satisfies a presence assertion. So
    # the measured value is read out of the sentence and compared with the
    # fixture it came from.
    infop <- file.path(bg, "INFO.txt")
    if (check_true("v72", "the Info window was captured as text, not only as pixels",
                   file.exists(infop))) {
        L <- readLines(infop, warn = FALSE, encoding = "UTF-8")
        rcc <- grep("within 10% of the 75 Hz floor", L, value = TRUE)
        v <- suppressWarnings(as.numeric(sub(".*minimum F0 ([0-9.]+) Hz.*", "\\1",
                                             rcc[1])))
        check("v72", "the raw-cross-correlation floor warning carries g1_low's own measured minimum",
              78, v, tol = 1)
        stated <- grep("measured F0 reached", L, value = TRUE)
        v2 <- suppressWarnings(as.numeric(sub(".*reached ([0-9.]+) Hz.*", "\\1",
                                              stated[1])))
        check("v72", "the stated-range warning carries g3_high's own measured maximum",
              640, v2, tol = 1)
        # APPENDIX_D §7 asks for the discrepancy AND for which parameters were
        # derived from the stated value. 300 stated gives max(2*300, 800) = 800
        # and max(1.1*300, 600) = 600, and the warning must print both -- a
        # user cannot decide whether to re-run without knowing what the
        # statement cost.
        check_true("v72",
                   "and names the two parameters the stated value derived, with their values",
                   any(grepl("pitch top (800 Hz) and the pitch ceiling (600 Hz)",
                             L, fixed = TRUE)))
    }
}

# ---------------------------------------------------------------------------
# COVERAGE
# ---------------------------------------------------------------------------
# Every warning outcome the harness recorded is asserted on by something above.
# A key added to run.sh and forgotten here would otherwise be a measurement
# nothing reads -- green, and covering less than it did yesterday.
#
# THE POPULATION IS READ OFF THE ARTEFACT, NOT OFF A LIST IN THIS FILE. The
# first version intersected the artefact's keys with a vector written here, so
# a new outcome the harness recorded was filtered out before the census saw
# it and the census could only pass -- the same "could only pass" shape the
# ellipsis check had, arriving through the door marked coverage. The two sides
# must be able to disagree, which means neither may be derived from the other:
# `present` comes from the TSV's own key names, `covered` from the vector the
# checks above looped over.
if (ran) {
    present <- grep("^warn_", names(B), value = TRUE)
    eml_census("v72", "range-guard outcome", present, covered)
    eml_claim("v72", "batchgui_out", covered)
}

if (!exists("EML_SUITE")) {
    eml_report("v72 batch registration: the menu entry, the real dialog, and APPENDIX_D §7")
    eml_exit()
}
