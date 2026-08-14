# ============================================================================
# v52_acoustic_calls.R -- the acoustic calls are ours; the DSP is Praat's
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULING THIS FILE IMPLEMENTS (author, 14 Aug 2026): Praat's processes are
# validated within Praat. We do not re-derive its pitch tracker or its
# cepstrum. What we owe is narrower and entirely ours -- that the CORRECT
# process is applied, with the CANONICAL PraatGen settings, to the right
# object, for the right purpose.
#
# That splits into four things a validator can hold, and this file holds all
# four:
#
#   1. THE PARAMETER LISTS ARE THE CANONICAL ONES. Nine call sites, pinned
#      argument by argument against APPENDIX_D. A parameter set is not the kind
#      of thing that announces its own corruption: change 0.02 to 0.2 in the
#      jitter call and every file still yields a number, the CSV still has the
#      right shape, the suite is still green, and the column is quietly a
#      different measurement than the one its header names. There is no
#      downstream consequence to notice. The only defence is a pin.
#
#   2. THE TWO PITCH ALGORITHMS GO TO THEIR OWN PURPOSES. Filtered
#      autocorrelation is for mean F0; raw cross-correlation is for the
#      PointProcess that jitter and shimmer are measured from. This is not
#      interchangeable and it is not stylistic -- autocorrelation-derived point
#      processes give systematically different perturbation values. Swapping
#      them produces no error and no missing column.
#
#   3. THE FLOORS AND CEILINGS MAY RISE BUT NOT FALL. facPitchTop and
#      rccPitchCeiling take max() against their canonical bases, 800 and 600,
#      so a user's highest-expected-F0 can widen the search but never narrow it
#      below canon. Written as a bare assignment instead, a soprano study would
#      silently octave-halve.
#
#   4. IN-LOOP ANALYSIS COMMANDS CARRY noprogress. House rule, and in a batch
#      over hundreds of files a progress bar is not cosmetic -- it blocks.
#
# WHAT THE HARNESS ADDS, AND WHY IT IS A SEPARATE KIND OF EVIDENCE. Everything
# above is static: it proves the source says what canon says. It cannot prove
# the ARGUMENT ORDER is what the source assumes, because Praat's positional
# forms accept a number wherever a number is expected. If a signature moved the
# ceiling from last position to third, a call written for the old order would
# set max-candidates to 600 and the ceiling to 0.14 -- no error, no warning, a
# plausible wrong number in every row. Only running the call finds that.
#
#     praat --run harness/acoustic/drive.praat
#     Rscript validate/v52_acoustic_calls.R
#
# VERSION HONESTY, and what it bought. The plugin targets Praat 6.6.30. Two
# commands do not exist below it -- To Pitch (filtered autocorrelation) and To
# Pitch (raw cross-correlation) -- and jitter and shimmer sit downstream of the
# second. This file was first written on a sandbox carrying 6.4.06, where those
# four could not run at all, and rather than pass over them it recorded them as
# UNRUN and reported their argument-order evidence as MISSING. A validator that
# goes green over four untested calls is worse than one that did not run.
#
# That report is what made the gap actionable: 6.6.30 was installed on 14 Aug
# 2026 and the four now RUN. Mean F0 recovers 119.9999 Hz on the filtered
# autocorrelation track and 120.0000 on raw cross-correlation against a
# synthesised 120 Hz, and jitter and shimmer come back at 4e-9 and 3e-9 on an
# unperturbed signal. The raw-cross-correlation result is the one that matters
# most: it is the only evidence that the ceiling really does sit THIRD in that
# signature rather than last, which no amount of reading the source could
# settle. The gate is kept exactly as it was -- an older sandbox will again
# report MISSING rather than lie.
#
# CPPS moved 14.1888 -> 17.1922 between the two versions on the same signal
# with the same parameters. That is not drift in this plugin; it is the
# tilt-line fit revision recorded in PraatGen's PRAAT_VERSION_FLOOR.txt, and it
# is why that document sets the framework floor where it does.
#
# Input: harness/acoustic/out/MEASURES.tsv. $EML_ACOUSTIC_DIR overrides, and
#        $EML_BATCH_FILE overrides the source under test, for break tests.
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

check_true("v52", "the batch module is present", file.exists(src))
if (!file.exists(src)) {
    if (!exists("EML_SUITE")) { eml_report("v52 acoustic calls"); eml_exit() }
}

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS FIRST
# ---------------------------------------------------------------------------
# Every one of these calls is written across two or three lines with "..."
# continuations. A line-at-a-time regex would match the head of a call and
# never see the arguments that matter -- which is exactly the shape of a check
# that passes while proving nothing.
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
norm <- gsub("\\s+", " ", trimws(joined))
code <- norm[!grepl("^#", norm)]

.args_after <- function(cmd) {
    hit <- grep(paste0(cmd, "\\s*:"), code, fixed = FALSE, value = TRUE)
    if (!length(hit)) return(NA_character_)
    a <- sub(paste0("^.*", cmd, "\\s*:\\s*"), "", hit[1])
    gsub("\\s*,\\s*", ", ", trimws(a))
}

# ---------------------------------------------------------------------------
# 1. THE CANONICAL PARAMETER LISTS
# ---------------------------------------------------------------------------
# The pitch calls carry a variable in the top/ceiling slot -- that is the
# widen-but-never-narrow rule of section 3 -- so those two are matched with the
# variable named, not with a literal.
canon <- list(
    list(id = "S1A To Pitch (filtered autocorrelation)",
         cmd = "To Pitch \\(filtered autocorrelation\\)",
         want = "0.0, 50, facPitchTop, 15, \"no\", 0.03, 0.09, 0.5, 0.055, 0.35, 0.14"),
    list(id = "S1B To Pitch (raw cross-correlation)",
         cmd = "To Pitch \\(raw cross-correlation\\)",
         want = "0.0, 75, rccPitchCeiling, 15, \"no\", 0.03, 0.45, 0.01, 0.35, 0.14"),
    list(id = "S3B Get jitter (local)",
         cmd = "Get jitter \\(local\\)",
         want = "0, 0, 0.0001, 0.02, 1.3"),
    list(id = "S3C Get shimmer (local)",
         cmd = "Get shimmer \\(local\\)",
         want = "0, 0, 0.0001, 0.02, 1.3, 1.6"),
    list(id = "S6 To Intensity",
         cmd = "To Intensity",
         want = "100, 0.0, \"yes\""),
    list(id = "S2A To Harmonicity (cc)",
         cmd = "To Harmonicity \\(cc\\)",
         want = "0.01, 75, 0.1, 1.0"),
    list(id = "S5 To PowerCepstrogram",
         cmd = "To PowerCepstrogram",
         want = "60, 0.002, 5000, 50"),
    list(id = "S5 Get CPPS",
         cmd = "Get CPPS",
         want = paste("\"no\", 0.01, 0.001, 60, 330, 0.05, \"parabolic\",",
                      "0.001, 0, \"Straight\", \"Robust\""))
)

for (k in canon) {
    got <- .args_after(k$cmd)
    check_true("v52",
               sprintf("%s carries the canonical parameter set", k$id),
               !is.na(got) && identical(got, k$want))
    if (!is.na(got) && !identical(got, k$want)) {
        cat(sprintf("      canon: %s\n      built: %s\n", k$want, got))
    }
}

# S3A takes no arguments at all, so it needs its own shape of check: present,
# and NOT given any.
pp <- grep("To PointProcess \\(cc\\)", code, value = TRUE)
check_true("v52", "S3A To PointProcess (cc) is called with no arguments",
           length(pp) == 1 && !grepl("To PointProcess \\(cc\\)\\s*:", pp[1]))

# ---------------------------------------------------------------------------
# 2. ALGORITHM-TO-PURPOSE ROUTING
# ---------------------------------------------------------------------------
# Mean F0 is read off the filtered-autocorrelation object; the PointProcess is
# built from the raw-cross-correlation one. Reading the object ids is what
# separates these -- both branches otherwise look identical.
facVar <- sub("^\\s*(\\w+)\\s*=.*", "\\1",
              grep("To Pitch \\(filtered autocorrelation\\)", code, value = TRUE)[1])
rccVar <- sub("^\\s*(\\w+)\\s*=.*", "\\1",
              grep("To Pitch \\(raw cross-correlation\\)", code, value = TRUE)[1])
#
# ADJACENCY, not mere presence. An earlier draft of this check asked only
# whether the FAC object was selected ANYWHERE in the file, and a break test
# that re-pointed the mean-F0 read at the cross-correlation object sailed
# through it -- the FAC object was still selected, two lines earlier, for
# nothing. What has to be true is that the selection IMMEDIATELY PRECEDING the
# mean-F0 read is the filtered-autocorrelation one.
.prev_select <- function(target) {
    i <- grep(target, code)
    if (!length(i)) return(NA_character_)
    j <- rev(grep("^selectObject: |^\\s*selectObject: ", code[seq_len(i[1] - 1)]))
    if (!length(j)) return(NA_character_)
    trimws(sub("^\\s*selectObject:\\s*", "", code[j[1]]))
}
sel <- .prev_select("meanF0Val = Get mean")
check_true("v52",
           sprintf("mean F0 is read off the FILTERED AUTOCORRELATION object (selected: %s, expected %s)",
                   sel, facVar),
           identical(sel, facVar))
check_true("v52",
           sprintf("the PointProcess is built from the RAW CROSS-CORRELATION object (%s)",
                   rccVar),
           any(grepl(paste0("plusObject: ", rccVar, "$"), code)))
check_true("v52", "the two pitch objects are not the same variable",
           !identical(facVar, rccVar))

# ---------------------------------------------------------------------------
# 3. THE CANONICAL BASES WIDEN, THEY DO NOT NARROW
# ---------------------------------------------------------------------------
topLine <- grep("^facPitchTop\\s*=", code, value = TRUE)
ceilLine <- grep("^rccPitchCeiling\\s*=", code, value = TRUE)
check_true("v52", "facPitchTop takes max() against the canonical 800",
           length(topLine) == 1 && grepl("max\\s*\\(", topLine[1]) &&
           grepl("\\b800\\b", topLine[1]))
check_true("v52", "rccPitchCeiling takes max() against the canonical 600",
           length(ceilLine) == 1 && grepl("max\\s*\\(", ceilLine[1]) &&
           grepl("\\b600\\b", ceilLine[1]))

# ---------------------------------------------------------------------------
# 4. noprogress ON EVERY IN-LOOP ANALYSIS COMMAND
# ---------------------------------------------------------------------------
for (cmd in c("To Pitch \\(filtered autocorrelation\\)",
              "To Pitch \\(raw cross-correlation\\)",
              "To PointProcess \\(cc\\)", "To Intensity",
              "To Harmonicity \\(cc\\)", "To PowerCepstrogram")) {
    hit <- grep(cmd, code, value = TRUE)
    check_true("v52",
               sprintf("%s is prefixed noprogress",
                       gsub("\\\\", "", cmd)),
               length(hit) >= 1 && all(grepl("noprogress ", hit)))
}

# ---------------------------------------------------------------------------
# 5. THE ARGUMENT ORDER, WHICH ONLY RUNNING CAN SETTLE
# ---------------------------------------------------------------------------
ad <- Sys.getenv("EML_ACOUSTIC_DIR", unset = "")
if (!nzchar(ad)) ad <- repo_path(file.path("harness", "acoustic", "out"))
mf <- file.path(ad, "MEASURES.tsv")

if (check_true("v52",
               "the acoustic drive was run (praat --run harness/acoustic/drive.praat)",
               file.exists(mf))) {
    x <- read.delim(mf, header = FALSE, sep = "\t", quote = "",
                    stringsAsFactors = FALSE, fill = TRUE)
    m <- setNames(as.list(trimws(as.character(x[[2]]))),
                  trimws(as.character(x[[1]])))
    num <- function(k) suppressWarnings(as.numeric(m[[k]]))

    check_true("v52", "the drive ran to completion",
               identical(m[["completed"]], "1"))

    # The three that exist at every version. The signal is a noise-free 120 Hz
    # complex, so each has a value it must be near: intensity in the ordinary
    # speech band, HNR enormous because there is no noise to be harmonic
    # against, CPPS high for the same reason. A mis-ordered argument list would
    # not land here.
    check_true("v52",
               sprintf("mean intensity is in band (%s dB)", m[["mean_intensity"]]),
               !is.na(num("mean_intensity")) && num("mean_intensity") > 20 &&
               num("mean_intensity") < 120)
    check_true("v52",
               sprintf("HNR is very high for a noise-free periodic signal (%s dB)",
                       m[["hnr"]]),
               !is.na(num("hnr")) && num("hnr") > 30)
    check_true("v52",
               sprintf("CPPS is high for a fully periodic signal (%s dB)",
                       m[["cpps"]]),
               !is.na(num("cpps")) && num("cpps") > 4 && num("cpps") < 40)

    # THE FOUR THAT NEED THE TARGET VERSION. Reported as missing evidence, not
    # passed over. This is the check that keeps the file honest on a sandbox.
    ranPitch <- identical(m[["pitch_chains_ran"]], "1")
    if (ranPitch) {
        check("v52", "mean F0 recovers the synthesised 120 Hz (filtered autocorrelation)",
              120, num("meanF0"), tol = 2)
        check("v52", "mean F0 recovers 120 Hz on the raw-cross-correlation track too",
              120, num("meanF0_rcc"), tol = 2)
        check_true("v52",
                   sprintf("jitter is near zero on an unperturbed signal (%s)",
                           m[["jitter_local"]]),
                   !is.na(num("jitter_local")) && num("jitter_local") < 0.01)
        check_true("v52",
                   sprintf("shimmer is near zero on an unperturbed signal (%s)",
                           m[["shimmer_local"]]),
                   !is.na(num("shimmer_local")) && num("shimmer_local") < 0.05)
    } else {
        cat(sprintf(paste0("      NOTE v52: argument-order evidence MISSING for ",
                           "4 calls.\n            Praat here is %s; the plugin ",
                           "targets 6.6.30, and\n            %s\n            ",
                           "do not exist below it. Static pins above still hold.\n"),
                    m[["praat_version"]], m[["unrun_commands"]]))
        check_true("v52",
                   sprintf(paste0("the drive DECLARED the four unrun calls rather ",
                                  "than skipping them (praat %s)"),
                           m[["praat_version"]]),
                   nzchar(m[["unrun_commands"]]) &&
                   identical(m[["at_target_version"]], "0"))
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v52 acoustic calls: canonical settings, correct routing, live argument order")
    eml_exit()
}
