# ============================================================================
# v54_batch_praatgen.R -- every OTHER call the batch module makes, against the
#                         PraatGen corpus that defines what they mean
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS COVERS AND WHAT IT DELIBERATELY DOES NOT. v52 owns the nine
# acoustic calls -- their parameter lists, the pitch-algorithm routing, the
# max() floors, noprogress -- and it owns them by execution as well as by
# reading. Nothing here repeats any of that. This file is everything else
# eml-batch-process.praat asks Praat to do: the Strings file list, the results
# Table, the TextGrid interval queries, the Sound channel handling, the folder
# scaffolding, the CSV write, the two dialogs, the object lifecycle, and the
# plausibility warnings. Twenty-three commands, and the rules that govern how
# a batch script is allowed to behave.
#
# WHY THE CORPUS IS NOT ENOUGH ON ITS OWN, which is the reason this file has a
# harness behind it. Every COMMANDS_*.txt in the PKB carries the same banner
# over its arity check: it "establishes that each command EXISTS on this object
# type and that its documented PARAMETER COUNT is right. It does NOT verify
# parameter ORDER, parameter TYPES, default values, or semantic correctness."
# So the corpus settles how many arguments and nothing past it. `Extract part:
# from time, to time, window shape$, relative width, preserve times?` is two
# numbers, a string, a number and a boolean; a call that moved the window shape
# to the end would still have five arguments and would still pass a count. Only
# running it separates those, and harness/batchcmd runs it.
#
# THE FAILURE THIS FILE IS ACTUALLY ABOUT. A batch script's characteristic
# defect is not a wrong number. It is that one bad file out of five hundred
# takes the whole run with it, because `Save as comma-separated file:` sits
# AFTER the loop and a Praat error is not catchable. Measured on 6.6.30,
# 14 August 2026, four of the module's calls end the process rather than the
# file, and three of the four take an argument straight from an unclamped
# `natural:` field:
#
#     Get string: past the end     returns "" -- and then Read from file:
#                                  fails on "<folder>/" and the run is over
#     Get number of intervals:     tier past the tier count -> abort
#     Get number of intervals:     tier is a POINT tier -> abort
#     Is interval tier:            tier past the tier count -> abort, which is
#                                  why the count must be asked for first
#
# Each exits 255 and writes no CSV. An overnight run that reached file 499 of
# 500 produces nothing at all, and the only artefact is an error message naming
# a Praat command. That is the shape of loss this file pins guards against.
#
# WHAT COULD NOT HAVE CAUGHT ANY OF IT, and why.
#
#   THE COMMANDS_*.txt FILES could not, twice over. They settle arity, and by
#   their own banner nothing beyond it -- so the three `Get mean` calls in this
#   module, which share a name across three object classes and differ in arity
#   (Pitch and Intensity take a unit string, Harmonicity does not), are exactly
#   the case the banner is warning about. And a signature file says nothing at
#   all about whether the argument you pass is in range: `Get number of
#   intervals: tier number` is correctly documented and still aborts.
#
#   THE ACOUSTIC HARNESS could not. It drives a synthesised tone through the
#   nine analysis calls with hand-picked arguments. It never opens a folder,
#   never reads a TextGrid, never builds a Strings list, and never runs a
#   second iteration -- so it cannot see a leak, a range overrun, or a tier
#   mismatch, because none of those has anywhere to happen in it.
#
#   A GREEN END-TO-END RUN could not, and this is the one worth stating
#   plainly. Drive the module over a clean folder of well-formed wavs with
#   matching single-tier TextGrids and every one of these defects is invisible:
#   the range is in range, the tier exists and is an interval tier, nothing
#   returns undefined, and the CSV is written. The bugs live entirely in the
#   inputs a careful test folder does not contain. Malformed input is not an
#   edge case for a batch tool -- it is the ordinary case, because the folder
#   is the user's corpus and not ours.
#
#   AND A LEAK COULD NOT BE READ OFF THE SOURCE. Pairing each creation with a
#   removeObject: is static reading and this file does it, but it proves the
#   text is consistent, not that the object list is. Only `select all` +
#   numberOfSelected () across three iterations proves that, and the harness
#   takes that count after every one.
#
#     bash harness/batchcmd/run.sh
#     Rscript validate/v54_batch_praatgen.R
#
# THE VERSION FLOOR IS A REPORTED DISCREPANCY, NOT A CHECK. PraatGen's floor is
# MEASURED at 6.4.39 (pkb/PRAAT_VERSION_FLOOR.txt, "THE FLOOR"), set by the
# second cepstral tilt-fit revision. Every command checked in this file is
# available there: none of the twenty-three appears in that file's §2 or §3
# will-not-run lists, and its §5 explicitly CLEARS `To Pitch (filtered
# autocorrelation)` at 11 arguments -- "same arity and effectively the same
# answer from 6.4.14 up". The module's one genuine version exposure is avoided:
# §3 records that the `Get CPPS` fit method "Robust slow" is REJECTED on 6.4.39
# and 6.4.46 while "Robust" is accepted on every build tested, and the module
# emits "Robust" (pinned in v52).
#
# ONE MINIMUM IS NOT ESTABLISHED AND IS NOT PRETENDED TO BE. `To Pitch (raw
# cross-correlation)` appears in no list in PRAAT_VERSION_FLOOR.txt, and that
# file's closing line is explicit about what that means: "A command absent from
# this file has an UNKNOWN minimum, not a safe one." Only 6.4.06 and 6.6.30 are
# installed here, so the 6.4.39 question cannot be settled by execution either.
# Recorded as a gap rather than assumed clear.
#
# THE PLUGIN DECLARES 6.6.30 AND REFUSES BELOW IT, AND THAT IS CORRECT --
# AUTHOR RULING, 15 AUGUST 2026. This paragraph previously filed the difference
# as "two departures from the corpus", which was a category error, and the
# ruling names it:
#
#     "The plugin's floor is 6.6.30 and it is FINE for setup.praat to refuse
#      below it -- the validation evidence exists only at 6.6.30, and a
#      warn-and-continue plugin would print unvalidated numbers under a
#      validated banner. PraatGen has its own, lower measured floor (6.4.39)
#      governed by its own §S15A warn-don't-refuse rule for generated scripts.
#      These are different artifacts with different contracts."
#
# The distinction is worth stating precisely, because the two rules look like
# they contradict and do not. A PraatGen-generated script is handed to a user
# who owns the result and whose Praat is whatever it is; refusing to run would
# be the tool substituting its judgement for theirs, so it warns. This plugin
# ships a validation suite that says its numbers are right, and every capture
# under evidence/info/ was produced on 6.6.30. Running below that floor would
# not produce slightly-less-validated output -- it would produce output whose
# banner claims a validation that does not exist for that build. A refusal is
# the honest response to a claim the artefact cannot honour.
#
# So both numbers stand, and neither is a defect against the other. What is
# pinned below is setup.praat's declared floor, so that moving it is a
# deliberate act that has to argue with this header.
#
# Input: harness/batchcmd/out/COMMANDS.tsv. $EML_BATCHCMD_DIR overrides it, and
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

check_true("v54", "the batch module is present", file.exists(src))
if (!file.exists(src)) {
    if (!exists("EML_SUITE")) { eml_report("v54 batch commands"); eml_exit() }
}

# ---------------------------------------------------------------------------
# JOIN CONTINUATIONS, THEN DROP COMMENTS
# ---------------------------------------------------------------------------
# Half the calls in this module are written across two or three lines, and this
# module's comments quote the very command names being checked -- the tier
# guard's comment contains the string "Get number of intervals: 5" as part of
# the error message it is explaining. A checker that read comments would find
# its evidence in the prose and pass on a file whose code had been deleted.
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

has  <- function(re) any(grepl(re, code))
hits <- function(re) grep(re, code, value = TRUE)

# .call_args -- the argument text of the FIRST call to a command, normalised.
# Returns NA when the command is absent, and "" when it is called with no
# colon at all, so "absent" and "called bare" never look alike.
.call_args <- function(cmd) {
    h <- hits(paste0("(^|[=:] |^\\s*)", cmd, "( |:|$)"))
    if (!length(h)) return(NA_character_)
    a <- sub(paste0("^.*", cmd, "\\s*"), "", h[1])
    if (!grepl("^:", a)) return("")
    gsub("\\s*,\\s*", ", ", trimws(sub("^:\\s*", "", a)))
}

# .arity -- how many top-level arguments a call carries. Commas inside quoted
# strings do not count; the module has none today, but a column name with a
# comma in it is exactly how this would silently start miscounting.
.arity <- function(argtext) {
    if (is.na(argtext)) return(NA_integer_)
    if (!nzchar(argtext)) return(0L)
    ch <- strsplit(argtext, "")[[1]]
    inq <- FALSE; n <- 1L
    for (c in ch) {
        if (c == "\"") inq <- !inq
        else if (c == "," && !inq) n <- n + 1L
    }
    n
}

# ---------------------------------------------------------------------------
# 1. COMMAND SIGNATURES -- arity and argument order, each cited to the corpus
# ---------------------------------------------------------------------------
# The `want` column is the documented parameter list; `n` is its length. A call
# that has drifted in arity fails on the count; one that has drifted in ORDER
# is caught by harness/batchcmd, which runs each of these for real and records
# what came back. Both halves are needed and neither substitutes for the other.
sigs <- list(
  list(cmd = "Create Strings as file list", n = 2L,
       src = "COMMANDS_Strings.txt, Create/Read",
       doc = "name$, path$"),
  list(cmd = "Get number of strings", n = 0L,
       src = "COMMANDS_Strings.txt, Query (session-verified)",
       doc = "(none)"),
  list(cmd = "Get string", n = 1L,
       src = "COMMANDS_Strings.txt, Query (API)",
       doc = "position"),
  list(cmd = "Create Table with column names", n = 3L,
       src = "COMMANDS_Table.txt, Create/Read",
       doc = "name$, number of rows, column names$"),
  list(cmd = "Append row", n = 0L,
       src = "COMMANDS_Table.txt, Extract/Combine",
       doc = "(none)"),
  list(cmd = "Set string value", n = 3L,
       src = "COMMANDS_Table.txt, Modify",
       doc = "row number, column name$, string value$"),
  list(cmd = "Set numeric value", n = 3L,
       src = "COMMANDS_Table.txt, Modify",
       doc = "row number, column name$, numeric value"),
  list(cmd = "Save as comma-separated file", n = 1L,
       src = "COMMANDS_Table.txt, Other; COMMANDS_Universal.txt, Save",
       doc = "file name$"),
  list(cmd = "Read from file", n = 1L,
       src = "COMMANDS_Universal.txt, Universal",
       doc = "file path$"),
  list(cmd = "Get number of channels", n = 0L,
       src = "COMMANDS_Sound.txt:80",
       doc = "(none)"),
  list(cmd = "Convert to mono", n = 0L,
       src = "COMMANDS_Sound.txt:249",
       doc = "(none)"),
  list(cmd = "Extract one channel", n = 1L,
       src = "COMMANDS_Sound.txt:190",
       doc = "channel"),
  list(cmd = "Extract part", n = 5L,
       src = "COMMANDS_Sound.txt:192",
       doc = "from time, to time, window shape$, relative width, preserve times?"),
  list(cmd = "Get total duration", n = 0L,
       src = "COMMANDS_Universal.txt, time-domain queries",
       doc = "(none)"),
  list(cmd = "Get number of tiers", n = 0L,
       src = "PRAAT_DEFINITIVE_CATALOGUE.txt:9133",
       doc = "(none)"),
  list(cmd = "Is interval tier", n = 1L,
       src = "COMMANDS_TextGrid.txt, Other",
       doc = "tier number"),
  list(cmd = "Get number of intervals", n = 1L,
       src = "COMMANDS_TextGrid.txt, Query -- interval tier",
       doc = "tier number"),
  list(cmd = "Get label of interval", n = 2L,
       src = "COMMANDS_TextGrid.txt, Query (API)",
       doc = "tier number, interval number"),
  list(cmd = "Get start time of interval", n = 2L,
       src = "COMMANDS_TextGrid.txt, Query -- interval tier",
       doc = "tier number, interval number"),
  list(cmd = "Get end time of interval", n = 2L,
       src = "COMMANDS_TextGrid.txt, Query -- interval tier",
       doc = "tier number, interval number")
)

for (s in sigs) {
    got <- .call_args(s$cmd)
    n <- .arity(got)
    check_true("v54",
               sprintf("%s takes %d argument(s) -- %s [%s]",
                       s$cmd, s$n, s$doc, s$src),
               !is.na(n) && identical(n, s$n))
    if (!is.na(n) && !identical(n, s$n)) {
        cat(sprintf("      documented: %d (%s)\n      built:      %d (%s)\n",
                    s$n, s$doc, n, got))
    }
}

# THE THREE `Get mean` CALLS, which share a name across three object classes
# and do NOT share a signature. This is the single likeliest place in the file
# for a silently wrong call, because the name gives no clue which one you have
# and Praat resolves it from the selection:
#
#   Pitch:        Get mean: from time, to time, unit$          COMMANDS_Pitch.txt:53
#   Intensity:    Get mean: from time, to time, averaging$     COMMANDS_Intensity.txt
#   Harmonicity:  Get mean: from time, to time                 COMMANDS_Harmonicity.txt
#
# Harmonicity takes NO third argument -- the same asymmetry COMMANDS_Harmonicity
# flags for Draw: (4 params where Intensity's takes 5). Passing a unit string to
# it is "requires only 2 arguments, not the 3 given" and kills the batch.
getmeans <- hits("Get mean:")
check_true("v54",
           sprintf("exactly three Get mean call sites (found %d)",
                   length(getmeans)),
           length(getmeans) == 3L)
check_true("v54",
           "Pitch Get mean takes the unit string \"Hertz\" [COMMANDS_Pitch.txt:53-54]",
           has("meanF0Val = Get mean: 0, 0, \"Hertz\"$"))
check_true("v54",
           "Intensity Get mean takes the averaging method \"dB\" [COMMANDS_Intensity.txt, Query]",
           has("intVal = Get mean: 0, 0, \"dB\"$"))
check_true("v54",
           "Harmonicity Get mean takes TWO arguments and no unit [COMMANDS_Harmonicity.txt, Query]",
           has("hnrVal = Get mean: 0, 0$"))

# ---------------------------------------------------------------------------
# 2. OBJECT-SELECTION PREREQUISITES
# ---------------------------------------------------------------------------
# Half of Praat's API is the selection, and a wrong selection is not an error
# -- it is a different command, or the same command on the wrong object. v52
# pins the two pitch chains. These are the rest.
#
# The selection immediately preceding a call is what matters, not whether the
# right object was selected somewhere earlier in the file; v52 learned that the
# hard way when a break test walked through a presence-only check.
.prev_select <- function(target) {
    i <- grep(target, code)
    if (!length(i)) return(NA_character_)
    j <- rev(grep("^selectObject: ", code[seq_len(i[1] - 1)]))
    if (!length(j)) return(NA_character_)
    trimws(sub("^selectObject:\\s*", "", code[j[1]]))
}

# .enclosing_if -- the condition of the innermost `if` that encloses line i,
# found by walking backwards and stepping over complete endif...if blocks.
# The immediately-preceding line is NOT the condition: every analysis call in
# this module has a `selectObject:` between it and its guard, and a check that
# assumed adjacency would report a leak in correct code and, worse, would go
# green the moment an unrelated line was inserted.
.enclosing_if <- function(i) {
    depth <- 0L
    k <- i - 1L
    while (k >= 1L) {
        ln <- code[k]
        if (grepl("^endif$", ln)) depth <- depth + 1L
        else if (grepl("^if ", ln)) {
            if (depth == 0L) return(sub("^if\\s+", "", ln))
            depth <- depth - 1L
        } else if (depth == 0L && grepl("^(else|elsif)", ln)) return(NA_character_)
        k <- k - 1L
    }
    NA_character_
}

# APPENDIX_D §3B: "Then select PointProcess ALONE for jitter queries".
# COMMANDS_PointProcess.txt puts it in the header of the jitter block:
# "Query -- jitter (PointProcess only)".
.jit <- grep("jitterVal = Get jitter", code)[1]
.ppc <- grep("^ppId = noprogress To PointProcess", code)[1]
check_true("v54",
           "jitter is queried with the PointProcess selected ALONE [APPENDIX_D §3B]",
           identical(.prev_select("jitterVal = Get jitter"), "ppId") &&
           !is.na(.jit) && !is.na(.ppc) && .jit > .ppc &&
           !any(grepl("^plusObject:", code[(.ppc + 1L):(.jit - 1L)])))

# APPENDIX_D §3C / COMMANDS_PointProcess.txt: "Query -- shimmer (requires
# PointProcess + Sound selected)". Sound co-selected, and it must be the
# SEGMENT the PointProcess was built from, not the whole file.
.shim <- grep("shimmerVal = Get shimmer", code)[1]
check_true("v54",
           "shimmer co-selects the PointProcess and the analysed Sound [APPENDIX_D §3C]",
           identical(.prev_select("shimmerVal = Get shimmer"), "ppId") &&
           !is.na(.shim) && identical(code[.shim - 1L], "plusObject: segId"))

check_true("v54",
           "the TextGrid is selected before its tier count is asked for",
           identical(.prev_select("nTiers = Get number of tiers"), "gridId"))
# EVERY `Append row`, not the first one. A second row-writing site was added on
# 14 Aug 2026 (the failure row), and a check anchored to the first would have
# stopped covering the one in the main loop without ever going red.
.appends <- grep("^Append row$", code)
check_true("v54",
           sprintf("every Append row is immediately preceded by a selectObject (%d sites)",
                   length(.appends)),
           length(.appends) >= 1L &&
           all(grepl("^selectObject: ", code[.appends - 1L])))
# ADJACENCY, not "selected somewhere earlier". A break test that deleted the
# selectObject: immediately above the CSV write sailed through a nearest-
# preceding-selection check, because the row-writing loop above it also selects
# the Table -- so the last selection in the file was still resultsId and the
# check could not tell the two apart. The line before the write is the only
# thing that settles what is selected when it runs.
.csv <- grep("^Save as comma-separated file:", code)[1]
check_true("v54",
           "the results Table is selected on the line before the CSV is written",
           !is.na(.csv) && identical(code[.csv - 1L], "selectObject: resultsId"))

# ---------------------------------------------------------------------------
# 3. OBJECT LIFECYCLE -- creation and removal under the SAME condition
# ---------------------------------------------------------------------------
# A per-segment object removed under a different flag from the one that made it
# is a leak on one branch and a double-free on the other. In a batch the leak
# is the quieter half and the worse one: nothing errors, the Objects window
# fills up over hundreds of files, and Praat slows and then runs out of memory
# somewhere with no line number attached.
lifecycle <- list(
    c("facPitchId", "mean_F0"), c("rccPitchId", "needsRccPitch"),
    c("ppId", "needsPointProcess"), c("intId", "mean_intensity"),
    c("harmId", "hNR"), c("cepId", "cPPS")
)
for (l in lifecycle) {
    v <- l[1]; flag <- l[2]
    i <- grep(paste0("^", v, " = "), code)
    j <- grep(paste0("^removeObject: ", v, "$"), code)
    ok <- length(i) == 1L && length(j) == 1L && j[1] > i[1] &&
          identical(.enclosing_if(i[1]), flag) &&
          identical(.enclosing_if(j[1]), flag)
    check_true("v54",
               sprintf("%s is created and removed under the same condition (if %s)",
                       v, flag), ok)
    if (!ok) cat(sprintf("      created under: %s   removed under: %s\n",
                         if (length(i)) .enclosing_if(i[1]) else "(absent)",
                         if (length(j)) .enclosing_if(j[1]) else "(absent)"))
}
# The extracted segment is a special case: it is a NEW object only when
# TextGrids are in use. Without them segId IS soundId, and removing it here
# would destroy the sound the next segment needs -- and then remove it twice.
# EVERY removal site is checked, not the first: there are two as of
# 14 Aug 2026, the segment teardown and the too-short failure path.
.segrm <- grep("^removeObject: segId$", code)
check_true("v54",
           sprintf("the extracted segment is removed only where it was extracted (%d sites, all under use_TextGrids)",
                   length(.segrm)),
           has("^segId = soundId$") && length(.segrm) >= 1L &&
           all(vapply(.segrm, function(i)
               identical(.enclosing_if(i), "use_TextGrids"), logical(1))))

# EVERY EARLY EXIT TIDIES UP AFTER ITSELF. Each of these leaves the script from
# a point where the file list is already open, and each must take it with it.
# Anchored on the exitScript line, not on the message text: "End at file" is
# also the LABEL of the field, and a check that matched the label would be
# reading the dialog and calling it the exit.
exits <- c("No \\.\" \\+ file_extension\\$", "Cannot write to the output folder",
           "End at file \\(", "Start from file \\(", "is after")
for (e in exits) {
    i <- grep(paste0("^exitScript: .*", e), code)
    ok <- length(i) > 0 &&
          any(grepl("^removeObject: fileListId", code[max(1, i[1] - 3):i[1]]))
    check_true("v54",
               sprintf("the exit at \"%s\" removes the file list first",
                       gsub("\\\\|\\$", "", e)), ok)
}
# The in-loop skips: no TextGrid, tier count, tier type, no matching intervals,
# unreadable file. Each jumps out of the middle of a file, so each owns
# whatever it has already read -- an object abandoned here is abandoned once
# per bad file, which over a corpus is the leak that has no line number.
#
# TWO IDIOMS ARE ACCEPTED, because a failed read is a different problem from a
# failed match. `removeObject: <id>` needs the id to exist, and after a read
# that may not have produced an object there is nothing to name; the disposal
# there is `if numberOfSelected () > 0 / Remove`, which is the same intent with
# the only test that is available.
#
# THE WINDOW IS THE SKIP'S OWN BLOCK, not a fixed number of lines. A first
# draft looked back twelve lines and went green on a break test that deleted a
# skip's removeObject: entirely -- it found the removeObject: belonging to the
# skip ABOVE it and counted that. The disposal has to be inside the branch that
# does the jumping, so the search starts at that branch's own `if`.
skips <- grep("^goto NEXT_FILE$", code)
.disposes <- function(i) {
    k <- i - 1L; depth <- 0L; start <- 1L
    while (k >= 1L) {
        if (grepl("^endif$", code[k])) depth <- depth + 1L
        else if (grepl("^if ", code[k])) {
            if (depth == 0L) { start <- k; break }
            depth <- depth - 1L
        }
        k <- k - 1L
    }
    w <- code[start:(i - 1L)]
    any(grepl("^removeObject: ", w)) ||
        (any(grepl("^if numberOfSelected \\(\\) > 0$", w)) && any(grepl("^Remove$", w)))
}
check_true("v54",
           sprintf("every in-loop skip disposes of what it read before jumping (%d skips)",
                   length(skips)),
           length(skips) >= 4L &&
           all(vapply(skips, .disposes, logical(1))))
check_true("v54",
           "the file list is removed at the end and the results Table is not",
           has("^removeObject: fileListId$") &&
           !has("^removeObject: resultsId") &&
           has("^selectObject: resultsId$"))

# ---------------------------------------------------------------------------
# 4. BOUNDED RANGES ARE GUARDED AT BOTH ENDS
# ---------------------------------------------------------------------------
# APPENDIX_D §7, "GUARD BOTH ENDS OF EVERY BOUNDED RANGE (hard)": "A floor-only
# guard is half a guard." The two ranges below come from `natural:` fields,
# which guarantee only that the value is 1 or more -- so Praat supplies the
# floor and the ceiling is entirely ours. Neither existed before 14 Aug 2026,
# and the harness records what the missing one cost: exit 255, no CSV.
check_true("v54",
           "the batch END index is checked against the file count [APPENDIX_D §7]",
           has("^if end_at_file > nFiles$"))
check_true("v54",
           "the batch START index is checked against the file count [APPENDIX_D §7]",
           has("^if start_from_file > nFiles$"))
check_true("v54",
           "an inverted batch range is refused rather than silently yielding no rows",
           has("^if start_from_file > end_at_file$"))
# The tier number is the same shape of unclamped `natural:`, against a bound
# that lives in each TextGrid on disk rather than in the dialog.
check_true("v54",
           "the requested tier is checked against the grid's tier count before use",
           has("^nTiers = Get number of tiers$") &&
           has("^if tier_number > nTiers$"))
check_true("v54",
           "the tier's TYPE is checked, and only after its number is known to be valid",
           has("^isIntervalTier = Is interval tier: tier_number$") &&
           has("^if not isIntervalTier$") &&
           grep("^nTiers = Get number of tiers$", code) <
           grep("^isIntervalTier = Is interval tier: tier_number$", code))

# ---------------------------------------------------------------------------
# 5. PLAUSIBILITY WARNINGS -- APPENDIX_D §7 table, Rule 30
# ---------------------------------------------------------------------------
# The bounds are transcribed from the §7 table, not chosen. A plausibility band
# that has quietly widened is a band that stops firing, and nothing downstream
# notices: the CSV is the same shape and the summary still counts zero.
bands <- list(
    list(m = "mean F0",         b = "if meanF0Val < 50 or meanF0Val > 1000$",
         cite = "F0 (Hz) 50 - 1000"),
    list(m = "HNR",             b = "if hnrVal < -20 or hnrVal > 40$",
         cite = "HNR (dB) -20 - 40"),
    list(m = "CPPS",            b = "if cppsVal < 0 or cppsVal > 25$",
         cite = "CPPS (dB) 0 - 25"),
    list(m = "mean intensity",  b = "if intVal < 20 or intVal > 120$",
         cite = "Intensity (dB SPL) 20 - 120")
)
for (b in bands) {
    check_true("v54",
               sprintf("%s is warned at BOTH ends [APPENDIX_D §7: %s]",
                       b$m, b$cite),
               has(b$b))
}
# Jitter and shimmer are ratio measures whose §7 floor is 0. The module guards
# the ceiling only; whether a provably unreachable floor test should be written
# anyway, to keep §7's "both ends" rule uniform across all six measures, is
# recorded for the author and is NOT decided here. The ceilings themselves are
# §7's 5% and 15% and are pinned.
check_true("v54",
           "jitter's ceiling is §7's 5% [APPENDIX_D §7: Jitter (local, %) 0 - 5]",
           has("if jitterVal > 0.05$"))
check_true("v54",
           "shimmer's ceiling is §7's 15% [APPENDIX_D §7: Shimmer (local, %) 0 - 15]",
           has("if shimmerVal > 0.15$"))

# RULE 30 (hard) AND §7: "emit non-blocking warnings via appendInfoLine: --
# never exitScript: for out-of-range values (the user may have valid reasons)".
# In a batch the reason is stronger still: an exitScript here would discard
# every row already measured, because the CSV is written after the loop.
warnLines <- grep("WARNING", code, value = TRUE)
check_true("v54",
           sprintf("no plausibility path calls exitScript (%d WARNING sites)",
                   length(warnLines)),
           length(warnLines) >= 6L &&
           !any(grepl("exitScript", warnLines)))

# RULE 30's else branch. Every measure is guarded against `undefined` before
# comparison -- and until 14 Aug 2026 none of them SAID SO when it was
# undefined. Praat returns undefined for an unvoiced or too-short segment,
# which in a folder of field recordings is routine, and the Table takes it
# without complaint: the harness confirms the CSV writes the literal string
# --undefined--. Without the branch a run ends "Warnings: 0" with a third of a
# column empty and nothing naming the files.
for (v in c("meanF0Val", "jitterVal", "shimmerVal", "hnrVal", "cppsVal",
            "intVal")) {
    i <- grep(paste0("^if ", v, " <> undefined$"), code)
    ok <- length(i) == 1L &&
          any(grepl("returned undefined", code[i[1]:min(length(code), i[1] + 12)]))
    check_true("v54",
               sprintf("%s reports when it comes back undefined [Rule 30 else branch]",
                       v), ok)
}
# EACH report, checked at its own site. Counting nWarnings++ across the file
# and asserting a total went green when one of the six was deleted -- the total
# was still above the floor the check asked for. A warning the summary does not
# count is a warning that scrolled past, which is APPENDIX_F §S7C's whole point.
.undef <- grep("returned undefined", code)
check_true("v54",
           sprintf("each of the %d undefined reports increments the warning counter [APPENDIX_F §S7C]",
                   length(.undef)),
           length(.undef) == 6L &&
           all(grepl("^nWarnings = nWarnings \\+ 1$", code[.undef + 1L])))

# ---------------------------------------------------------------------------
# 6. DIALOG CONVENTIONS -- APPENDIX_C, APPENDIX_F §S0
# ---------------------------------------------------------------------------
# THE LABEL IS THE VARIABLE. APPENDIX_C §C.3: truncate at the first "(",
# lowercase the FIRST character only, preserve every other, spaces to
# underscores. That is why "HNR" is hNR and "Clear Info window" is
# clear_Info_window -- and why reading them back as hnr or clear_info_window
# would not error. It would be an undefined variable, which Praat treats as 0,
# so every measure would silently be off. That rule cost eml-output.praat a
# silent no-op save on 13 Aug 2026.
derive <- list(
    c("Sound folder",              "sound_folder$"),
    c("File extension",            "file_extension$"),
    c("Channel handling",          "channel_handling"),
    c("Output folder",             "output_folder$"),
    c("Mean F0",                   "mean_F0"),
    c("Mean intensity",            "mean_intensity"),
    c("Jitter \\(local\\)",        "jitter"),
    c("Shimmer \\(local\\)",       "shimmer"),
    c("HNR",                       "hNR"),
    c("CPPS",                      "cPPS"),
    c("Highest expected F0 \\(Hz\\)", "highest_expected_F0"),
    c("Use TextGrids",             "use_TextGrids"),
    c("TextGrid folder",           "textGrid_folder$"),
    c("Tier number",               "tier_number"),
    c("Target label",              "target_label$"),
    c("Clear Info window",         "clear_Info_window"),
    c("Start from file",           "start_from_file"),
    c("End at file",               "end_at_file")
)
for (d in derive) {
    label <- d[1]; var <- d[2]
    declared <- has(paste0("^(folder|word|boolean|positive|natural|optionmenu):",
                           " \"", label, "\","))
    plain <- sub("\\$$", "", var)
    read <- any(grepl(paste0("(^|[^A-Za-z0-9_.])", plain,
                             if (grepl("\\$$", var)) "\\$" else "(?![A-Za-z0-9_$])"),
                      code, perl = TRUE))
    check_true("v54",
               sprintf("\"%s\" is declared and read back as %s [APPENDIX_C §C.3]",
                       gsub("\\\\", "", label), var),
               declared && read)
}
# optionmenu yields TWO names (§C.3 step 6) and the module uses both -- the
# index to branch on, the string to print.
check_true("v54",
           "the optionmenu's string readback channel_handling$ is used as well as the index",
           has("channel_handling\\$"))
# §C.3 REFERENCEABILITY GATE (hard): a derived name that is not a Praat
# identifier exists but cannot be referenced. Every one of these must pass.
badnames <- Filter(function(d) !grepl("^[A-Za-z][A-Za-z0-9_]*$",
                                      sub("\\$$", "", d[2])), derive)
check_true("v54",
           sprintf("every derived name passes the §C.3 referenceability gate (%d labels)",
                   length(derive)),
           length(badnames) == 0L)

# APPENDIX_F §S0A: the cancel argument is 0, not a button index, "which ensures
# field variables are always updated regardless of which button is clicked"
# (APPENDIX_C §C.2, field-variable caveat). A cancel index here would leave the
# folder paths holding their prior values on one path out of the dialog.
ends <- hits("^clicked = endPause:")
check_true("v54",
           sprintf("both dialogs pass 0 as the cancel argument [APPENDIX_F §S0A] (%d dialogs)",
                   length(ends)),
           length(ends) == 2L && all(grepl(", 0$", ends)))
# §S0B: Quit, not Cancel. §S0C: a Standard button on the parameter dialog.
check_true("v54", "the first button on both dialogs is Quit [APPENDIX_F §S0B]",
           all(grepl("endPause: \"Quit\",", ends)))
check_true("v54",
           "the parameter dialog carries a Standard button and loops on it [APPENDIX_F §S0C]",
           has("endPause: \"Quit\", \"Standard\", \"Run\", 3, 0") &&
           has("^until clicked <> 2$"))

# ---------------------------------------------------------------------------
# 7. REPORTING -- Rule 22, APPENDIX_E
# ---------------------------------------------------------------------------
# Rule 22's output-richness list: script identification, source identification,
# summary totals, warnings.
check_true("v54", "the Info window names the script [Rule 22, richness 1]",
           has("appendInfoLine: \"Batch Voice Analysis\""))
check_true("v54",
           "it names BOTH folders and the CSV, since they are no longer the same place [Rule 22, richness 2]",
           has("Sound folder: ") && has("Output folder: ") &&
           has("Results CSV: "))
for (t in c("Files processed", "Files skipped", "Warnings", "Data rows")) {
    check_true("v54", sprintf("the summary reports %s [Rule 22, richness 5; §S8A]", t),
               has(paste0("\"", t)))
}
# APPENDIX_E governs Praat's PICTURE-window text renderer, where % # ^ _ are
# style toggles. It applies to this module only in that it must not: the module
# draws nothing, so no string it emits reaches that renderer, and the
# underscores in its CSV column names are safe. Pinning the absence is what
# keeps that reasoning true -- add one Text: command and the escaping question
# is live again and this check is the thing that says so.
check_true("v54",
           "the module draws nothing, so APPENDIX_E's toggle characters never reach a renderer",
           !has("^(Text|Text special|Draw|Erase all|Select outer viewport|Axes|Marks)[ :]"))
# Units in parentheses on every warning that carries one, and the measure named.
check_true("v54", "out-of-range warnings state the unit and the range",
           has("Hz — outside range \\(50-1000\\)") &&
           has("dB — outside range \\(-20 to 40\\)") &&
           has("dB — outside range \\(0 to 25\\)") &&
           has("dB — outside range \\(20 to 120\\)"))

# ---------------------------------------------------------------------------
# 8. THE DECLARED VERSION FLOOR
# ---------------------------------------------------------------------------
# Pinned, not judged. See the header: PraatGen measures 6.4.39 and requires a
# warn-and-continue check; the plugin declares 6.6.30 and refuses. Moving this
# number is a decision that has to pass through that discussion.
setup <- repo_path(file.path("plugin", "setup.praat"))
if (check_true("v54", "plugin/setup.praat is present", file.exists(setup))) {
    s <- readLines(setup, warn = FALSE)
    check_true("v54",
               "setup.praat still declares the 6.6.30 floor it enforces [setup.praat:45-59]",
               any(grepl("^emlMinPraatVersion = 6630$", trimws(s))) &&
               any(grepl("praatVersion < emlMinPraatVersion", s)))
}

# ---------------------------------------------------------------------------
# 9. THE EVIDENCE ONLY RUNNING CAN PRODUCE
# ---------------------------------------------------------------------------
bd <- Sys.getenv("EML_BATCHCMD_DIR", unset = "")
if (!nzchar(bd)) bd <- repo_path(file.path("harness", "batchcmd", "out"))
tf <- file.path(bd, "COMMANDS.tsv")

if (check_true("v54",
               "the command drive was run (bash harness/batchcmd/run.sh)",
               file.exists(tf))) {
    x <- read.delim(tf, header = FALSE, sep = "\t", quote = "",
                    stringsAsFactors = FALSE, fill = TRUE)
    m <- setNames(as.list(trimws(as.character(x[[2]]))),
                  trimws(as.character(x[[1]])))
    num <- function(k) suppressWarnings(as.numeric(m[[k]]))

    check_true("v54", "the drive ran to completion", identical(m[["completed"]], "1"))
    check_true("v54",
               sprintf("the drive ran at the plugin's target version (praat %s)",
                       m[["praat_version"]]),
               identical(m[["at_target_version"]], "1"))

    # NO LEAK. The object list is the same size after every iteration and back
    # to baseline at the end. Two objects persist between iterations by
    # design -- the Strings file list and the results Table -- which is why the
    # constancy across iterations is the check and not the absolute number.
    after <- c(num("objects_after_iter1"), num("objects_after_iter2"),
               num("objects_after_iter3"))
    check_true("v54",
               sprintf("the object list does not grow across iterations (%s)",
                       paste(after, collapse = ", ")),
               all(is.finite(after)) && length(unique(after)) == 1L)
    check_true("v54",
               sprintf("teardown returns the object list to its baseline (%s -> %s)",
                       m[["objects_baseline"]], m[["objects_final"]]),
               identical(m[["objects_final"]], m[["objects_baseline"]]))

    # THE FOUR ABORT PATHS. Every one must still abort. If Praat ever made one
    # of these return a value instead, the module's guard would be moot and
    # this check going red is how that gets noticed rather than assumed.
    for (p in c("read_after_string_overrun", "intervals_tier_overrange",
                "intervals_on_point_tier", "isintervaltier_overrange")) {
        check_true("v54",
                   sprintf("%s still ends the process (exit %s)", p,
                           m[[paste0(p, "_exit")]]),
                   identical(m[[paste0(p, "_aborted")]], "1") &&
                   identical(m[[paste0(p, "_exit")]], "255"))
    }
    check_true("v54",
               "Get string past the end returns the EMPTY STRING, not an error",
               identical(m[["strings_get_string_overrun_len"]], "0"))

    # THE FORM DERIVATION, PROVED RATHER THAN REASONED. Seventeen names, every
    # one asked for by variableExists () at 6.6.30.
    check_true("v54",
               sprintf("every derived form variable exists at 6.6.30 (%s declared, %s missing)",
                       m[["form_derived_declared"]], m[["form_derived_missing"]]),
               identical(m[["form_derived_missing"]], "0") &&
               identical(m[["form_derived_declared"]], "17"))
    check_true("v54",
               sprintf("the optionmenu reads back its option TEXT (%s) [APPENDIX_C §C.3 step 6]",
                       m[["form_optionmenu_readback"]]),
               identical(m[["form_optionmenu_readback"]], "Left channel only"))
    check_true("v54",
               "a quoted numeric default in a numeric field binds correctly [APPENDIX_C §C.1, 6.6.30 correction]",
               identical(num("form_positive_readback"), 500))

    # THE TABLE TAKES undefined AND SAYS SO IN THE CSV. This is what makes
    # Rule 30's else branch load-bearing: without it the only trace of a failed
    # measurement is a token in a file nobody reads until later.
    check_true("v54", "Set numeric value: accepts undefined",
               identical(m[["table_csv_written"]], "1"))
    check_true("v54", "and the CSV records it as --undefined--",
               identical(m[["table_undefined_token"]], "1"))

    # createFolder: IS mkdir, NOT mkdir -p -- the measured claim
    # @emlEnsureOutputFolder's ancestor loop rests on.
    check_true("v54",
               "createFolder: refuses when the parent is missing [module: @emlEnsureOutputFolder]",
               identical(m[["createfolder_missing_parent"]], "0"))
    check_true("v54", "and succeeds when each level is created in turn",
               identical(m[["createfolder_each_level"]], "1"))

    # ALL THREE ARMS OF THE CHANNEL OPTIONMENU RAN, on a real stereo file, and
    # each produced one channel. A mono file skips the block and keeps its id.
    chans <- c(num("iter1_channels_out"), num("iter2_channels_out"),
               num("iter3_channels_out"))
    check_true("v54",
               "Convert to mono / Extract one channel 1 / Extract one channel 2 each yield one channel",
               all(chans == 1) && identical(num("iter1_channels_in"), 2) &&
               identical(num("mono_file_channels"), 1))

    # Extract part BEYOND THE DOMAIN pads with silence rather than failing --
    # so a TextGrid longer than its recording yields measures on zeros, with no
    # warning from Praat. Recorded here because it is the module's one
    # remaining silent-wrong path and it is on the author's desk.
    check_true("v54",
               sprintf("Extract part past the sound's end pads instead of failing (%s s from a 1 s sound)",
                       m[["extract_part_overhang_duration"]]),
               identical(num("extract_part_overhang_duration"), 2.5) &&
               identical(num("extract_part_outside_duration"), 1.0))
}

if (!exists("EML_SUITE")) {
    eml_report(paste("v54 batch commands: corpus signatures, selection",
                     "discipline, object lifecycle, guarded ranges"))
    eml_exit()
}
