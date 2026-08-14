# ============================================================================
# v53_batch_flow.R -- the batch module RUN, not read
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR. plugin/scripts/eml-batch-process.praat is the one part of
# the plugin that reads a folder of somebody's recordings, calls Praat's own
# acoustic extraction over them unattended, and writes a file the user will
# treat as data. v52 covers the CALLS -- the canonical APPENDIX_D parameter
# sets, the routing of the two pitch algorithms to their two purposes, and,
# now that the sandbox is at 6.6.30, the live argument order of all nine. This
# file covers everything AROUND them, which is where a batch actually fails.
#
# THE FAILURES IT IS SHAPED AROUND, and what each looks like from the outside:
#
#   THE LOOP PAIRS THE WRONG ROW WITH THE WRONG FILE. There is no symptom. The
#   CSV has the right number of rows, the right columns, and a plausible number
#   in every cell; only the correspondence between the stem and the numbers
#   beside it is wrong, and nothing in the artefact asserts that correspondence.
#   So the corpus here is five files at five different F0s whose alphabetical
#   order is deliberately not their creation order, and the check is per row:
#   this stem, therefore this F0, to within 2 Hz.
#
#   ONE BAD FILE COSTS THE WHOLE NIGHT. Until 14 August 2026 the read was
#   unguarded and the analysis was attempted on any duration, so a zero-length
#   take -- what a stopped interface leaves behind -- ended the script at exit
#   255. The results Table is built row by row and written to disk AFTER the
#   loop, so an abort at file 372 of 500 produced no CSV at all. The defect and
#   its fix are described at @emlAppendFailureRow; what this file holds is the
#   behaviour: four unanalysable files, two good ones around them, six rows.
#
#   THE TEXTGRID BRANCH DOES NOT ACTUALLY CONSTRAIN ANYTHING. This is the
#   subtlest of the three. A branch that reads the grid, finds the labelled
#   intervals, fills in interval_start and interval_end correctly and then
#   measures the WHOLE FILE produces an artefact that passes every structural
#   check anyone would think to write: right rows, right bounds, right columns,
#   numbers in range. The only thing that can tell the two apart is a MEASURED
#   DIFFERENCE, so c1_split is 130 Hz for one second and 260 Hz for the next
#   with only the second half labelled -- unconstrained it must read near 194,
#   constrained it must read 260, and the gap between those two numbers is the
#   evidence that the constraint is applied.
#
#   THE STOP FILE STOPS NOTHING, OR EATS THE USER'S OWN. A sentinel is only
#   real if a mid-run flip is honoured, and @emlSentinelIsOurs is only real if
#   a foreign STOP.txt comes out byte-identical. Both are driven here: twelve
#   files, a stop-word list already sitting in the output folder under that
#   name, and the sentinel flipped by a second process while the run is going.
#
#   THE RESULTS LAND IN THE CORPUS. The author's ruling of 14 August 2026 --
#   "Output folder is user designated. Not the input folder." -- shipped in
#   39530d3 with no way to observe it. Here the input folder is counted after
#   the run: no CSV, no STOP file, nothing.
#
#   A WARNING BECOMES AN ABORT. APPENDIX_D §7 is explicit that an implausible
#   measurement gets a non-blocking appendInfoLine and never exitScript. Six
#   files, one per measure, each engineered to land outside its own band, all
#   six measures on at once -- and the run must still reach COMPLETE with six
#   rows.
#
# WHAT COULD NOT HAVE CAUGHT ANY OF IT, which is the part worth being precise
# about, because this module was not un-covered by oversight -- it was covered
# by things that are blind to it BY CONSTRUCTION:
#
#   v52 never runs the module. It joins the "..." continuations and pins the
#   argument lists, and its live half runs harness/acoustic/drive.praat, which
#   is a SEPARATE script that makes the same calls in the same order on one
#   synthetic sound. Every check in it would pass unchanged if the module's
#   file loop ran backwards, wrote every row for the first file, or never
#   opened a second file at all.
#
#   harness/wrappers proves this module PARSES, and that is genuinely all. It
#   runs each entry point headless and treats the SIGTRAP at beginPause: as
#   success, because reaching the dialog means the script was built. Not one
#   line below that dialog has ever executed under it -- the loop, the branch,
#   the sentinel, the CSV and the summary are all downstream of the crash it
#   counts as a pass.
#
#   The GUI harnesses (gui_e2e, savepaths, gui_adv) drive real dialogs under
#   Xvfb, and they could in principle have driven this one -- except that
#   "Batch voice analysis..." has been unregistered in plugin/setup.praat since
#   6 August 2026, tabled by the author for exactly the reason this file
#   exists. It has no menu entry, so a harness that drives menus cannot reach
#   it. The coverage gap and the tabling have the same cause, and neither could
#   fix the other.
#
#   validate/v35's census knows the file only as a name in a list of entry
#   points that parse. No validator in this tree has ever read a CSV this
#   module wrote, because until harness/batch existed the module had never
#   written one here.
#
# HOW THE MODULE IS RUN AT ALL. Every EML entry point collects its settings
# with beginPause:/endPause, which hard-crashes under `praat --run`. So
# harness/batch/run.sh cuts the two dialog stanzas out by line number, from
# anchors it requires to be unique, and replaces them with two include lines
# that set the variables the dialogs set. That would be worthless as evidence
# if the cut could touch anything else, so it is hashed: the shipped file minus
# those two regions and the twin minus those two lines must be the same bytes,
# and the excised text is committed to out/EXCISED.txt for a reader to check
# rather than take on trust. Section 1 below holds that, and holds it first,
# because every other check in this file is a claim about the shipped module
# only for as long as it is true.
#
#     bash harness/batch/run.sh
#     Rscript validate/v53_batch_flow.R
#
# Input: harness/batch/out/. $EML_BATCH_DIR overrides that folder and
#        $EML_BATCH_FILE the source under test, so a break test drives a
#        damaged copy and never goes near the shipped file. Same two names v52
#        uses, for the same reason.
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

src <- Sys.getenv("EML_BATCH_FILE", unset = "")
if (!nzchar(src)) src <- repo_path(file.path("plugin", "scripts",
                                             "eml-batch-process.praat"))
bd <- Sys.getenv("EML_BATCH_DIR", unset = "")
if (!nzchar(bd)) bd <- repo_path(file.path("harness", "batch", "out"))

tsvPath <- file.path(bd, "BATCH.tsv")
have <- check_true("v53", "the batch drive was run (bash harness/batch/run.sh)",
                   file.exists(tsvPath))
if (!have) {
    if (!exists("EML_SUITE")) {
        eml_report("v53 batch flow: NO EVIDENCE -- run bash harness/batch/run.sh")
        eml_exit()
    }
}

# ---------------------------------------------------------------------------
# Readers
# ---------------------------------------------------------------------------
B <- list()
if (have) {
    .x <- read.delim(tsvPath, header = FALSE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE)
    B <- setNames(as.list(trimws(as.character(.x[[2]]))),
                  trimws(as.character(.x[[1]])))
}
bs <- function(k) if (is.null(B[[k]])) NA_character_ else B[[k]]
bn <- function(k) suppressWarnings(as.numeric(bs(k)))

# THE MODULE WRITES --undefined-- INTO A NUMERIC CELL when Praat returns one,
# so a column can arrive as character. Coerced here rather than at read time,
# because a check that silently turned "--undefined--" into NA at the door
# would make an undefined measure indistinguishable from a failed row, and
# those are different findings.
#
# A CSV THAT WILL NOT PARSE IS A MISSING CSV, NOT A CRASH. read.csv stops the
# interpreter on a malformed file -- "more columns than column names" is what a
# truncated header gives -- and a validator that stops has reported nothing.
# The same reasoning as one() below: the artefact under test is exactly the
# thing that is allowed to be wrong, so every reader of it has to survive it.
csv_of <- function(case) {
    p <- file.path(bd, paste0(case, ".csv"))
    if (!file.exists(p)) return(NULL)
    tryCatch(read.csv(p, stringsAsFactors = FALSE, check.names = FALSE),
             error = function(e) NULL, warning = function(w) NULL)
}
log_of <- function(case) {
    p <- file.path(bd, paste0(case, ".log"))
    if (!file.exists(p)) return(character(0))
    readLines(p, warn = FALSE)
}
num <- function(v) suppressWarnings(as.numeric(as.character(v)))

# A LOOKUP THAT FINDS NOTHING MUST GO RED, NOT DIE. Every per-row check below
# picks a row by its stem, and under a break test the stem is exactly what
# goes missing -- a mutation that wrote a constant into the file column left
# every lookup zero-length, sprintf() returned character(0), and the whole
# validator exited on an R error instead of printing a failure. A suite that
# crashes on a broken input has reported nothing at all, which is strictly
# worse than a red line: the run has no count, and "it errored" is a sentence
# somebody has to interpret. So a missing row becomes NA here and NA fails
# every check it reaches.
one <- function(v) if (length(v) == 0) NA_real_ else suppressWarnings(as.numeric(as.character(v))[1])
one_s <- function(v) if (length(v) == 0) NA_character_ else as.character(v)[1]
allof <- function(v) length(v) > 0 && all(v)

CASES <- c("A_loop", "B_errors", "C_free", "C_grid", "D_stop",
           "E_folder", "F_warn")

# ---------------------------------------------------------------------------
# 0. THE RUN ITSELF
# ---------------------------------------------------------------------------
check_true("v53", "the drive ran to completion", identical(bs("completed"), "1"))
check_true("v53", "the fixtures were built", identical(bs("fixtures_ok"), "1"))
check_true("v53",
           sprintf("the drive used the target Praat (%s)", bs("praat_version")),
           grepl("^Praat 6\\.6\\.30", bs("praat_version")))

# EVERY CASE EXITED 0. An abort is exit 255 and would leave no CSV -- which is
# the historical failure this module had, so it is asserted first and by name
# rather than inferred from a missing file further down.
for (cs in CASES) {
    check_true("v53", sprintf("%s: the run exited cleanly (not an abort)", cs),
               identical(bs(paste0(cs, "_exit")), "0"))
    check_true("v53", sprintf("%s: the run reached COMPLETE", cs),
               identical(bs(paste0(cs, "_completed")), "1"))
}

# ---------------------------------------------------------------------------
# 1. THE TWIN IS THE SHIPPED MODULE
# ---------------------------------------------------------------------------
# Everything below is evidence about plugin/scripts/eml-batch-process.praat
# only for as long as this holds. If it fails, the rest of the file is
# measuring something else and its passes mean nothing.
check_true("v53",
           "the driven twin is byte-identical to the shipped module outside the two dialog stanzas",
           identical(bs("twin_body_identical"), "1"))
check_true("v53", "exactly two lines were injected in place of the dialogs",
           identical(bs("twin_injected_lines"), "2"))

exc <- if (file.exists(file.path(bd, "EXCISED.txt"))) {
    readLines(file.path(bd, "EXCISED.txt"), warn = FALSE)
} else character(0)
check_true("v53", "the excised dialog text was recorded for inspection",
           length(exc) > 20)
# WHAT WAS CUT MUST BE DIALOG AND NOTHING ELSE. The hash above proves the cut
# did not disturb its surroundings; it cannot prove the cut did not REMOVE
# something that mattered, because a removed line is absent from both sides of
# the comparison. So the excised text is read for the vocabulary of the flow:
# a file read, an analysis, a row, a save, a library call. Finding any of those
# in there would mean the twin is a shorter program than the one that ships.
flowWords <- paste0("Read from file|To Pitch|To Intensity|To Harmonicity|",
                    "To PowerCepstrogram|To PointProcess|Append row|",
                    "Set numeric value|Set string value|Save as|@eml|",
                    "Create Strings|Extract part")
codeExc <- exc[!grepl("^\\s*#", exc)]
check_true("v53",
           "the excised text is dialog only -- no read, no analysis, no row, no save",
           !any(grepl(flowWords, codeExc)))

# ---------------------------------------------------------------------------
# 2. THE FILE LOOP: N IN, N OUT, IN ORDER, EACH ROW ITS OWN FILE
# ---------------------------------------------------------------------------
A <- csv_of("A_loop")
A_truth <- c(alpha = 100, bravo = 140, charlie = 180, delta = 220, echo = 260)

if (check_true("v53", "A_loop: the results CSV was written", !is.null(A))) {
    check_true("v53", "A_loop: five files in, five rows out", nrow(A) == 5)
    # ORDER AND CONTENT IN ONE ASSERTION. The files were written to disk as
    # charlie, echo, alpha, delta, bravo; a loop that returned creation order
    # would give a set-equal but differently ordered vector, which a %in% test
    # would pass.
    check_true("v53",
               sprintf("A_loop: the rows are in file-list order, one per stem (%s)",
                       paste(A$file, collapse = " ")),
               identical(as.character(A$file), names(A_truth)))
    check_true("v53", "A_loop: every row is marked ok",
               nrow(A) == 5 && allof(A$status == "ok"))

    # THE PAIRING. This is the check the whole corpus was built for: each row's
    # measured F0 must be the F0 of the file its stem names.
    for (st in names(A_truth)) {
        i <- which(A$file == st)
        got <- if (length(i) == 1) one(A$mean_F0_Hz[i]) else NA_real_
        check("v53", sprintf("A_loop: row '%s' carries its own F0", st),
              A_truth[[st]], got, tol = 2)
    }

    # THE COLUMNS ARE NOT TRANSPOSED. Every measure has a band it belongs in on
    # this material, and a shifted column lands outside all of them at once.
    check_true("v53", "A_loop: mean intensity is in the speech band on every row",
               allof(num(A$mean_intensity_dB) > 20 & num(A$mean_intensity_dB) < 120))
    check_true("v53", "A_loop: HNR is very high on every row (noise-free signal)",
               allof(num(A$HNR_dB) > 30))
    check_true("v53", "A_loop: CPPS is in band on every row",
               allof(num(A$CPPS_dB) > 4 & num(A$CPPS_dB) < 40))
    check_true("v53", "A_loop: jitter and shimmer are near zero on every row",
               allof(num(A$jitter_local) < 0.01) &&
               allof(num(A$shimmer_local) < 0.05))
}

# ---------------------------------------------------------------------------
# 3. ERROR ROWS: THE BATCH SURVIVES, AND SAYS WHICH FILE DID NOT
# ---------------------------------------------------------------------------
Bcsv <- csv_of("B_errors")
B_expect <- c(b01_good = "ok", b02_zero = "FAILED", b03_wrongtype = "FAILED",
              b04_short = "FAILED", b05_good = "ok", b06_corrupt = "FAILED")

if (check_true("v53", "B_errors: the results CSV was written", !is.null(Bcsv))) {
    check_true("v53", "B_errors: six files in, six rows out -- nothing skipped in silence",
               nrow(Bcsv) == 6 && identical(bs("B_errors_input_files"), "6"))
    check_true("v53", "B_errors: the rows are in file-list order",
               identical(as.character(Bcsv$file), names(B_expect)))
    for (st in names(B_expect)) {
        i <- which(Bcsv$file == st)
        got <- one_s(Bcsv$status[i])
        want <- B_expect[[st]]
        check_true("v53",
                   sprintf("B_errors: %s is marked %s (status: %s)", st, want,
                           if (is.na(got)) "MISSING" else got),
                   !is.na(got) &&
                   ((want == "ok" && got == "ok") ||
                    (want == "FAILED" && grepl("^FAILED", got))))
    }
    # THE FAILURE REASON IS SPECIFIC, not one word for four different faults.
    check_true("v53", "B_errors: the 0.02 s file is failed for being too short",
               isTRUE(grepl("too short", one_s(Bcsv$status[Bcsv$file == "b04_short"]))))
    check_true("v53", "B_errors: the unreadable and non-Sound files are failed for that",
               allof(grepl("unreadable or not a Sound",
                           Bcsv$status[Bcsv$file %in% c("b02_zero", "b03_wrongtype",
                                                        "b06_corrupt")])))
    # THE SURVIVORS STILL CARRY REAL MEASUREMENTS. A run that caught the errors
    # but then wrote nothing useful for the good files would satisfy every
    # check above.
    check("v53", "B_errors: the first good file is still measured (120 Hz)",
          120, one(Bcsv$mean_F0_Hz[Bcsv$file == "b01_good"]), tol = 2)
    check("v53", "B_errors: the LAST good file is still measured (200 Hz)",
          200, one(Bcsv$mean_F0_Hz[Bcsv$file == "b05_good"]), tol = 2)
    # A FAILED ROW IS EMPTY, NOT ZERO. A 0 or a -999 in a measure column is a
    # number somebody will average.
    fr <- Bcsv[grepl("^FAILED", Bcsv$status), ]
    check_true("v53", "B_errors: failed rows carry no measurements at all",
               nrow(fr) == 4 && all(is.na(num(fr$mean_F0_Hz))) &&
               all(is.na(num(fr$mean_intensity_dB))) &&
               all(is.na(num(fr$HNR_dB))) && all(is.na(num(fr$CPPS_dB))))
    check_true("v53", "B_errors: the summary counts the four failures",
               any(grepl("^Failed:\\s+4$", log_of("B_errors"))))
}

# ---------------------------------------------------------------------------
# 4. THE TEXTGRID-CONSTRAINED PATH
# ---------------------------------------------------------------------------
CF <- csv_of("C_free")
CG <- csv_of("C_grid")

if (check_true("v53", "C: both the free and the constrained run wrote a CSV",
               !is.null(CF) && !is.null(CG))) {
    check_true("v53", "C_free: three files, three rows, no interval columns",
               nrow(CF) == 3 && !("interval_label" %in% names(CF)))
    check_true("v53", "C_grid: the interval columns appear only in the constrained run",
               all(c("interval_label", "interval_start", "interval_end") %in%
                   names(CG)))

    ff <- one(CF$mean_F0_Hz[CF$file == "c1_split"])
    gg <- one(CG$mean_F0_Hz[CG$file == "c1_split"])
    # THE DIFFERENCE IS THE EVIDENCE. c1_split is 130 Hz then 260 Hz, and only
    # the 260 Hz half is labelled. A branch that read the grid and then measured
    # the whole file would put the same number on both sides of this.
    check("v53", "C_grid: the labelled interval of c1_split reads 260 Hz",
          260, gg, tol = 2)
    check("v53", "C_free: the SAME file unconstrained reads the whole-file mean",
          194, ff, tol = 4)
    check_true("v53",
               sprintf("C: constrained and unconstrained DIFFER (%s vs %s Hz) -- the constraint is applied",
                       format(gg, digits = 5), format(ff, digits = 5)),
               is.finite(gg) && is.finite(ff) && abs(gg - ff) > 50)

    # ONE FILE, TWO LABELLED INTERVALS, TWO ROWS -- each with its own bounds
    # and its own F0. The segment loop is a second loop inside the file loop and
    # has its own ways to go wrong.
    c2 <- CG[CG$file == "c2_three", ]
    check_true("v53", "C_grid: the file with two labelled intervals gives two rows",
               nrow(c2) == 2)
    if (nrow(c2) == 2) {
        check_true("v53", "C_grid: the interval bounds are the TextGrid's own",
                   isTRUE(all.equal(num(c2$interval_start), c(0.6, 1.2))) &&
                   isTRUE(all.equal(num(c2$interval_end), c(1.2, 1.8))))
        check("v53", "C_grid: the first labelled interval reads 220 Hz",
              220, one(c2$mean_F0_Hz[1]), tol = 2)
        check("v53", "C_grid: the second labelled interval reads 330 Hz",
              330, one(c2$mean_F0_Hz[2]), tol = 2)
        check_true("v53", "C_grid: both interval rows are labelled V",
                   allof(as.character(c2$interval_label) == "V"))
    }

    # THE SOUND WITH NO TEXTGRID. It is analysed in the free run and skipped,
    # with a warning and a count, in the constrained one -- and the run carries
    # on to COMPLETE either way.
    check_true("v53", "C_free: the file with no TextGrid is analysed normally",
               "c3_nogrid" %in% CF$file)
    check_true("v53", "C_grid: the file with no TextGrid produces no row",
               !("c3_nogrid" %in% CG$file))
    lg <- log_of("C_grid")
    check_true("v53", "C_grid: it is skipped out loud, naming the file",
               any(grepl("No TextGrid for c3_nogrid", lg)))
    check_true("v53", "C_grid: the summary counts it as one skipped file",
               any(grepl("^Files skipped:\\s+1$", lg)))
}

# ---------------------------------------------------------------------------
# 5. THE STOP SENTINEL UNDER A REAL DRIVE
# ---------------------------------------------------------------------------
D <- csv_of("D_stop")
dlg <- log_of("D_stop")

if (check_true("v53", "D_stop: the results CSV was written even though the run was cut short",
               !is.null(D))) {
    nIn <- suppressWarnings(as.numeric(bs("D_stop_input_files")))
    # NOT A ROW COUNT. Where a mid-run stop lands depends on how fast the
    # machine analyses twelve files, and a check pinned to "stopped at file 4"
    # would be asserting a fact about the sandbox. What is a fact about the
    # module is that it stopped, that it stopped BEFORE THE END, and that it
    # still wrote what it had.
    check_true("v53",
               sprintf("D_stop: the run stopped mid-batch (%d rows of %d files)",
                       nrow(D), nIn),
               nrow(D) >= 1 && nrow(D) < nIn)
    check_true("v53", "D_stop: the stop is announced in the Info window",
               any(grepl("STOPPED BY USER", dlg)))
    # THE ANNOUNCED COUNT AND THE CSV AGREE. A stop that halted the loop but
    # lost the rows already computed would pass the line above.
    stopped <- sub(".*after ([0-9]+) of.*", "\\1",
                   grep("STOPPED BY USER", dlg, value = TRUE)[1])
    check_true("v53",
               sprintf("D_stop: the count it reports (%s) is the number of rows it wrote (%d)",
                       stopped, nrow(D)),
               identical(as.integer(stopped), nrow(D)))
    check_true("v53", "D_stop: the rows written are the first files, in order",
               identical(as.character(D$file),
                         sprintf("d%02d", seq_len(nrow(D)))))

    # OWNERSHIP. @emlSentinelIsOurs and @emlResolveSentinelPath, under a real
    # run rather than in the abstract.
    check_true("v53",
               "D_stop: the user's own STOP.txt is byte-identical after the run",
               nzchar(bs("D_stop_foreign_sha_before")) &&
               identical(bs("D_stop_foreign_sha_before"),
                         bs("D_stop_foreign_sha_after")))
    check_true("v53", "D_stop: the sentinel walked to STOP_2.txt",
               identical(bs("D_stop_sentinel_2_exists"), "1") &&
               any(grepl("Sentinel file:.*STOP_2\\.txt", dlg)))
    check_true("v53",
               "D_stop: the user is told which file to edit, and that theirs was left alone",
               any(grepl("a STOP.txt already in that folder was not written", dlg)) &&
               any(grepl("edit that", dlg)))
    # RE-ARMED. The sentinel is rewritten to RUN on the way out, or the next
    # run over the same folder would stop before its first file.
    check_true("v53", "D_stop: the sentinel is left saying RUN for the next run",
               identical(bs("D_stop_sentinel_2_first_line"), "RUN"))
}

# ---------------------------------------------------------------------------
# 6. THE USER-DESIGNATED OUTPUT FOLDER (author ruling, 14 August 2026)
# ---------------------------------------------------------------------------
# "re stop file, yes? To users output folder. Output folder is user designated.
# Not the input folder." Shipped in 39530d3 with nothing able to observe it.
check_true("v53", "A_loop: NOTHING was written into the corpus -- no CSV",
           identical(bs("A_loop_input_folder_csv"), "0"))
check_true("v53", "A_loop: NOTHING was written into the corpus -- no STOP file",
           identical(bs("A_loop_input_folder_stop"), "0"))
check_true("v53", "A_loop: the CSV is in the output folder",
           identical(bs("A_loop_output_folder_csv"), "1"))
check_true("v53", "A_loop: the sentinel is in the output folder too",
           identical(bs("A_loop_sentinel_exists"), "1") &&
           identical(bs("A_loop_sentinel_first_line"), "RUN"))
# THE NAME COMES FROM THE SOUND FOLDER, THE PATH FROM THE OUTPUT FOLDER. Since
# the two are no longer the same folder, the corpus name in the file name is
# the only thing that says which corpus a CSV describes.
check_true("v53",
           sprintf("A_loop: the CSV is named for the CORPUS, not the output folder (%s)",
                   bs("A_loop_csv_name")),
           identical(bs("A_loop_csv_name"), bs("A_loop_expected_csv_name")))

# A FOLDER THE USER TYPED AND THAT DOES NOT EXIST YET, two levels deep, with
# spaces -- "~/Documents/Study A/run 1" is what goes in that field, and
# createFolder: is mkdir, not mkdir -p.
check_true("v53", "E_folder: an output folder two levels below a missing parent was created",
           identical(bs("E_folder_created"), "1"))
check_true("v53", "E_folder: the CSV landed in it",
           identical(bs("E_folder_csv_rows"), "1"))
check_true("v53", "E_folder: the sentinel landed in it",
           identical(bs("E_folder_sentinel_exists"), "1"))
check_true("v53", "E_folder: still nothing written into the corpus",
           identical(bs("E_folder_input_folder_writes"), "0"))

# ---------------------------------------------------------------------------
# 7. PLAUSIBILITY WARNINGS (APPENDIX_D §7)
# ---------------------------------------------------------------------------
# "If outside these ranges, emit a non-blocking warning via appendInfoLine. Do
# NOT exitScript -- the user may have valid reasons."
Fc <- csv_of("F_warn")
flg <- log_of("F_warn")

# One file per measure, each carrying a value outside its own band. The
# expected line is matched on the MEASURE and the BAND, not on the whole
# sentence, so re-wording a warning does not fail the suite -- but dropping one,
# or silently widening a band, does.
F_trips <- list(
    list(measure = "mean F0",    stem = "f1_f0high", col = "mean_F0_Hz",
         pat = "WARNING: Mean F0 = .* outside range \\(50-1000\\)"),
    list(measure = "intensity",  stem = "f2_quiet",  col = "mean_intensity_dB",
         pat = "WARNING: Mean intensity = .* outside range \\(20 to 120\\)"),
    list(measure = "jitter",     stem = "f3_jitter", col = "jitter_local",
         pat = "WARNING: Jitter = .* unusually high \\(> 5%\\)"),
    list(measure = "shimmer",    stem = "f4_shimmer", col = "shimmer_local",
         pat = "WARNING: Shimmer = .* unusually high \\(> 15%\\)"),
    list(measure = "HNR",        stem = "f5_hnr",    col = "HNR_dB",
         pat = "WARNING: HNR = .* outside range \\(-20 to 40\\)"),
    list(measure = "CPPS",       stem = "f6_cpps",   col = "CPPS_dB",
         pat = "WARNING: CPPS = .* outside range \\(0 to 25\\)")
)
F_bands <- list(mean_F0_Hz = c(50, 1000), mean_intensity_dB = c(20, 120),
                jitter_local = c(-Inf, 0.05), shimmer_local = c(-Inf, 0.15),
                HNR_dB = c(-20, 40), CPPS_dB = c(0, 25))

if (check_true("v53", "F_warn: the results CSV was written", !is.null(Fc))) {
    check_true("v53",
               "F_warn: the run CONTINUED -- six files in, six rows out, all six measures",
               nrow(Fc) == 6 && allof(Fc$status == "ok"))
    check_true("v53", "F_warn: no run was aborted by a plausibility check",
               identical(bs("F_warn_exitscript"), "0"))
    for (tr in F_trips) {
        check_true("v53",
                   sprintf("F_warn: %s out of band is warned about, not fatal", tr$measure),
                   any(grepl(tr$pat, flg)))
        # AND THE FILE THAT WAS SUPPOSED TO TRIP IT DID. A warning present in
        # the log but produced by a different file would pass the line above,
        # and would mean the fixture no longer tests what it says it tests.
        v <- one(Fc[[tr$col]][Fc$file == tr$stem])
        band <- F_bands[[tr$col]]
        check_true("v53",
                   sprintf("F_warn: %s is genuinely outside %g-%g on %s (%s)",
                           tr$measure, band[1], band[2], tr$stem,
                           format(v, digits = 4)),
                   is.finite(v) && (v < band[1] || v > band[2]))
    }
}

# ---------------------------------------------------------------------------
# 8. THE BANDS THEMSELVES, READ OFF THE SOURCE
# ---------------------------------------------------------------------------
# Driving one value past one edge of a band cannot show that the OTHER edge is
# guarded, and APPENDIX_D §7 is explicit -- "GUARD BOTH ENDS OF EVERY BOUNDED
# RANGE (hard) ... A floor-only guard is half a guard." A band silently widened
# to (50-10000), or with its lower test deleted, produces no warning and no
# other symptom whatsoever. So the four two-sided bands are pinned as written.
check_true("v53", "the module under test is present", file.exists(src))
if (file.exists(src)) {
    raw <- readLines(src, warn = FALSE)
    joined <- character(0)
    for (ln in raw) {
        if (grepl("^\\s*\\.\\.\\.", ln) && length(joined)) {
            joined[length(joined)] <- paste0(joined[length(joined)], " ",
                                             sub("^\\s*\\.\\.\\.\\s*", "", ln))
        } else {
            joined <- c(joined, ln)
        }
    }
    code <- gsub("\\s+", " ", trimws(joined))
    code <- code[!grepl("^#", code)]

    bands <- list(
        list(id = "F0 (50-1000)",        pat = "if meanF0Val < 50 or meanF0Val > 1000"),
        list(id = "HNR (-20 to 40)",     pat = "if hnrVal < -20 or hnrVal > 40"),
        list(id = "CPPS (0 to 25)",      pat = "if cppsVal < 0 or cppsVal > 25"),
        list(id = "intensity (20-120)",  pat = "if intVal < 20 or intVal > 120")
    )
    # WHOLE-LINE EQUALITY, NOT A SUBSTRING SEARCH, and that distinction was not
    # theoretical: the first version of this block used grepl(fixed = TRUE), and
    # the break test that widened the CPPS band from 25 to 250 SAILED THROUGH IT
    # -- "cppsVal > 250" contains "cppsVal > 25". A pin that a widened band
    # satisfies is not a pin. The comparison is against the whitespace-collapsed
    # code line, so the source may be re-indented or re-wrapped, but not
    # re-numbered.
    for (bnd in bands) {
        check_true("v53",
                   sprintf("APPENDIX_D §7: the %s band guards BOTH ends", bnd$id),
                   any(code == bnd$pat))
    }
    # Jitter and shimmer are one-sided in the appendix and correctly one-sided
    # here: the floor of both is zero and a perturbation measure cannot go
    # below it, so there is no lower end to guard.
    check_true("v53", "APPENDIX_D §7: the jitter ceiling is 5%",
               any(code == "if jitterVal > 0.05"))
    check_true("v53", "APPENDIX_D §7: the shimmer ceiling is 15%",
               any(code == "if shimmerVal > 0.15"))
    # AND NONE OF THEM MAY EXIT. The appendix forbids it in the same sentence
    # that requires the warning, and a warning turned into an exitScript is a
    # one-word edit that stops a batch dead on its first unusual file.
    #
    # THE ANCHORS ARE ASSERTED, NOT ASSUMED, and this is a lesson from writing
    # this file rather than a precaution. The first version anchored on
    # "^# +[Pp]lausibility" — no leading space — and the section header in the
    # module is indented eight spaces because it sits inside the segment loop.
    # The regex matched nothing, the `if` around the check was false, and the
    # check simply did not exist: it printed no line, it was in no count, and
    # the break test that turned a warning into an exitScript did not flag it.
    # A check that can silently not run is worse than no check, because the
    # total at the bottom of the report says otherwise. So a missing anchor is
    # now itself a failure.
    warnBlock <- grep("^\\s*# +Plausibility warnings", raw)
    rowBlock <- grep("^\\s*# +Write row to results table", raw)
    if (check_true("v53",
                   "the plausibility section can be located in the source",
                   length(warnBlock) == 1 && length(rowBlock) == 1 &&
                   warnBlock[1] < rowBlock[1])) {
        seg <- raw[warnBlock[1]:rowBlock[1]]
        check_true("v53",
                   "APPENDIX_D §7: no plausibility check calls exitScript",
                   !any(grepl("exitScript", seg)))
    } else {
        check_true("v53",
                   "APPENDIX_D §7: no plausibility check calls exitScript",
                   FALSE)
    }
    # THE STATUS COLUMN IS UNCONDITIONAL. Every other column in this CSV is
    # behind an `if <measure>`, so a status behind one too would be the natural
    # thing to write and would give a schema that changes shape with the
    # settings -- and a failed row with nowhere to say so.
    check_true("v53", "the status column is written for every run, not per measure",
               any(code == 'colNames$ = "file status"'))
}

# ---------------------------------------------------------------------------
# COVERAGE
# ---------------------------------------------------------------------------
# Every case the driver ran is asserted on by something above. A case added to
# run.sh and forgotten here would otherwise be a drive that produces evidence
# nothing reads -- green, and covering less than it did yesterday.
present <- sub("_exit$", "", grep("_exit$", names(B), value = TRUE))
eml_census("v53", "batch drive case", present, CASES)
eml_claim("v53", "batch_out", CASES)

if (!exists("EML_SUITE")) {
    eml_report("v53 batch flow: the loop, the failures, the branch, the sentinel, the folder, the warnings")
    eml_exit()
}
