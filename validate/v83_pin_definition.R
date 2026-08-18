# ============================================================================
# v83_pin_definition.R -- a ledger row may not name as its pin a validator
#                         whose value under test came out of a committed file
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS FILE ASSERTS, in one sentence: every validator named in a
# `pinnedBy` field of audit/FINDINGS_MACHINE.json READS THE PLUGIN'S SOURCE
# WITHIN ITS RUN, or EXECUTES SOMETHING UNDER TEST WITHIN ITS RUN.
#
# That second clause used to read "or drives Praat live", and the change is a
# correction rather than a relaxation. See THE TWO ROLES OF AN ARTEFACT below:
# driving Praat is one way of executing and not the only one, and the wording
# it replaces could not see the strongest regenerating check in the suite.
#
# ────────────────────────────────────────────────────────────────────────────
# WHY. THE NEXT READER WILL WANT TO RELAX THIS, SO THE ARGUMENT IS HERE.
#
# A COMMITTED ARTEFACT IS A WITNESS STATEMENT, NOT A LIVE WITNESS.
#
# harness/legend/out/RESULTS.tsv records what the plugin did on the afternoon
# somebody drove it. It is real evidence and it was true when it was taken. But
# it is a STATEMENT ABOUT THAT AFTERNOON, and it goes on making that statement,
# unchanged and in perfect confidence, for as long as it sits in the tree --
# including after the code it describes has been rewritten, reverted or
# deleted. A check that reads only the artefact therefore pins THE ARTEFACT. It
# proves the file still says what it said. It never proves the code still does
# what the file says. Those two claims look identical in a green run and they
# are not the same claim at all.
#
# That is not a worry, it is a measurement, and it has now been taken three
# times from three directions:
#
#   1. THE RE-DRIVE CENSUS (validate/tools/redrive_census.sh). Of 34 harnesses
#      re-driven from source into a scratch tree, NINE reproduced their
#      committed artefacts. FIFTEEN differed. Several of the stale ones were
#      the evidence this suite was quoting to state things about the plugin
#      that had stopped being true -- harness/legendroom/out/LEGENDROOM.tsv had
#      been wrong since 15 August and green the whole time.
#
#   2. v29. It asserts 144 renders that the tree has never, at any commit in
#      its history, been able to produce. The evidence was carried in from
#      somewhere else. Every check reading it passed, because every check
#      reading it was reading the file rather than the plugin.
#
#   3. THE LEDGER BACKFILL. plugin/ was reverted wholesale -- the strongest
#      possible mutation, every repair in the tree undone at once -- and 36
#      validators were run against it. EIGHT rows' pinning validators stayed
#      GREEN. Every one of the eight was pinned by a validator whose only input
#      is a committed harness artefact. A pin's entire claim is "something
#      would notice if this repair were undone". These eight were handed the
#      undoing and did not notice.
#
# (1) and (3) are one fact seen from opposite ends: the artefact drifting away
# from the code, and the check failing to see the code move. The disease is the
# DECOUPLING, and the eight rows were never eight separate mistakes -- they were
# one definition that had never been written down.
#
# So it is written down here, as a definition rather than as a review:
#
#     A pinnedBy may only name a validator that READS plugin/ WITHIN THE RUN
#     OR EXECUTES SOMETHING UNDER TEST WITHIN THE RUN.
#
# ────────────────────────────────────────────────────────────────────────────
# THE TWO ROLES OF AN ARTEFACT. READ THIS BEFORE SIMPLIFYING THE RULE BACK
# INTO "IT READS AN ARTEFACT", WHICH IS WHAT IT SAID UNTIL 17 AUGUST 2026.
#
# "Does this validator read an artefact" is not the question. The question is
#
#         DOES THE VALUE UNDER TEST COME FROM EXECUTION?
#
# and the two questions come apart, because a committed file can be standing
# in either of two completely different places in a check:
#
#   AS ORACLE. The validator regenerates the subject from source inside its
#   own run and compares the result against the committed file. The file is
#   the EXPECTATION. Change the code and the measured thing changes with it.
#
#   AS SUBJECT. The measured value is read out of the committed file. Nothing
#   ran. The check proves the file still says what it said.
#
# Only the second is what the three measurements above found. The first is the
# remedy, and it touches an artefact, so a rule keyed on "touches an artefact"
# condemns the cure along with the disease.
#
# THE WORKED EXAMPLE, AND THE REASON THIS PARAGRAPH EXISTS: v79. It classifies
# SOURCE+ARTEFACT. What it does is BUILD the release artefact out of plugin/
# during the run, by invoking plugin/dev/tools/build-release.py; unpack the
# zip under `umask 077`; and measure the modes that land on disk -- the only
# reading in this tree taken on a tree that unzip created rather than one the
# builder chmodded. Its committed record covers only the three facts that need
# an X server, and is bound by digest to the two source files those facts rest
# on. It is close to the strongest pin in the suite, and under the old wording
# the census could not distinguish it from a validator that opens a TSV and
# stops. v78 is the same shape: `build-manifest.py --check` RE-RENDERS the
# manifest from the tree and compares it with the committed one.
#
# So the census now answers "did anything under test run" in its own column,
# `executes` (NO / PRAAT / TOOL / UNKNOWN), and this file's rule rests on that
# column rather than on the reading classes alone. PRAAT is a strict subset of
# executing, so nothing that qualified as a pin before qualifies less now.
#
# AND THE ERROR DIRECTION IS CHOSEN. A validator that regenerates but is
# called artefact-only would be disqualified here, and the project would be
# pushed into "repairing" a check that was already right -- so where the
# derivation cannot settle the two roles from the source, it resolves towards
# executing. That admits, at worst, one pin too many; the other way loses the
# suite's best allies. The vacuity section below is what keeps "resolve
# towards executing" from decaying into "everything executes".
#
# ────────────────────────────────────────────────────────────────────────────
# WHAT THIS DOES NOT SAY, and the distinction is the whole reason the rule can
# be this sharp. Artefact-only checks are not weakened, deprecated, or worth
# less. v03 pinning a printed p against R at half a display ULP, v73's
# reversal matrix, v18's sweep across sixteen designed shapes -- these are
# ORACLE AGREEMENTS. They settle the plugin's arithmetic against an
# independent computation, which is a thing no amount of re-driving can do,
# and they are the reason a reviewer with no Praat can still check the
# statistics. Nothing here touches them and nothing here should be read as
# an argument for deleting one. They simply are not PINS, because a pin is a
# claim about what would be noticed, and measurement (3) settled what an
# artefact-only check notices.
#
# ────────────────────────────────────────────────────────────────────────────
# HOW IT IS CHECKED, AND WHY IT CANNOT BECOME A SECOND THING TO DRIFT.
#
# This file carries NO LIST of which validator is which class. It sources
# validate/tools/evidence_census.R and calls eml_evidence_census(), which
# derives the classification from the validator sources with R's own parser,
# every run. A validator that stops reading plugin/ is reclassified by the same
# edit that stops it, and this check sees the new class on the next run. The
# committed record, validate/tools/EVIDENCE_CENSUS.tsv, is asserted here to
# REPRODUCE from that live classification -- so the census's own artefact is
# held to the standard this file exists to state, rather than being the one
# exception to it.
#
# THIS FILE IS READ-ONLY ON THE LEDGER. It reports; it never edits. A row it
# names is a row for a human to act on -- by finding evidence that qualifies,
# or by withdrawing the pin and letting the row read `fixed-unpinned`, which is
# an honest status and a much better one than a `closed` that is not true.
#
# ────────────────────────────────────────────────────────────────────────────
# VACUITY. There are exactly three ways this check could be green and mean
# nothing, and all three are asserted against POSITIVELY rather than hoped
# about.
#
#   * THE READING CLASSIFIER MATCHES NOTHING. A broken parser, an emptied root
#     list, a regex that stopped matching -- and every validator classifies as
#     one thing, or as nothing, and "no artefact-only pin was found" becomes
#     true for the worst possible reason. So four named validators are
#     asserted to land in their known classes: v77 and v70 LIVE (both resolve
#     a Praat and drive it), v80 SOURCE and NOT artefact-only (it lints the
#     shipped tree and reads no harness), v01 and v37 ARTEFACT-ONLY (a
#     transcribed capture and a committed DETERMINISM.tsv). Naming them is the
#     point -- a classifier that has stopped working cannot satisfy assertions
#     in two opposite directions at once.
#
#   * THE EXECUTION DETECTOR MATCHES NOTHING. The new half fails the same way,
#     and fails SILENTLY, which is worse: if `executes` came back NO for
#     everything, this file would still be green today, because every pin in
#     the ledger also reads plugin/ and qualifies on the first clause. Nothing
#     downstream would notice that the distinction this file exists for had
#     stopped being computed. So v79 is named explicitly -- it must come back
#     EXECUTING, by TOOL, and must not be disqualified -- and every validator
#     the reading side calls LIVE must come back executing PRAAT, since
#     driving Praat is executing by definition and a detector that disagreed
#     with the classifier beside it is broken whichever of the two is right.
#
#   * THE EXECUTION DETECTOR MATCHES EVERYTHING. A classifier that qualifies
#     every validator is exactly as useless as one that qualifies none, and it
#     is the failure mode that "resolve towards executing" invites. So v01,
#     v37 and v03 are named in the other direction: three checks that open a
#     committed capture, compare it with arithmetic done in R, and start no
#     process at all. If those three come back executing, the detector has
#     stopped discriminating and this file says so instead of waving every
#     pin through. The count is asserted to be a partition as well.
#
#   * THE LEDGER HAS NO ROWS, or no row claims a pin at all. Zero rows satisfy
#     "no row names an artefact-only pin" vacuously, which is the same shape of
#     nothing as a pin satisfied by the absence of the thing it names. So a
#     ledger that cannot be read is a FAILURE, an empty one is a FAILURE, and
#     one in which nothing is pinned by anything is a FAILURE.
#
# A pinnedBy naming a validator that DOES NOT EXIST is also a failure, and is
# reported as UNRESOLVED rather than skipped. The schema checker
# (validate/tools/check_findings_schema.py) allows a dev-test ID there; if one
# is ever used it must be given a classification route through the census
# before this file will accept it, because "we could not classify it" is not a
# reason to treat something as a pin.
#
#     Rscript validate/v83_pin_definition.R
#
# Inputs: audit/FINDINGS_MACHINE.json, and every validator in validate/, read
#         through validate/tools/evidence_census.R.
#
# Overrides, for the break tests -- a check that cannot be pointed at a fixture
# is a check that cannot be break-tested:
#   EML_FINDINGS_LEDGER   read this ledger instead of audit/FINDINGS_MACHINE.json
#   EML_CENSUS_SCRIPT     source this census instead of validate/tools/
#                         evidence_census.R (used to blind the classifier)
#   EML_CENSUS_VALIDATE_DIR   classify the validators in this directory
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

# ---------------------------------------------------------------------------
# 0. THE CENSUS, COMPUTED HERE AND NOW.
# ---------------------------------------------------------------------------
census_script <- Sys.getenv("EML_CENSUS_SCRIPT", unset = "")
if (!nzchar(census_script)) {
    census_script <- repo_path("validate", "tools", "evidence_census.R")
}
check_true("v83", "the evidence census tool is present",
           file.exists(census_script))
if (!file.exists(census_script)) {
    if (!exists("EML_SUITE")) {
        eml_report("v83 pin definition: NO CENSUS -- validate/tools/evidence_census.R is missing")
        eml_exit()
    }
}

CEN <- NULL
.cenv <- new.env(parent = globalenv())
if (file.exists(census_script)) {
    # Sourced into a child environment so the census's own script-mode block
    # cannot fire and cannot rewrite the record from inside a validator run.
    ok <- tryCatch({ sys.source(census_script, envir = .cenv); TRUE },
                   error = function(e) { message("census source failed: ",
                                                 conditionMessage(e)); FALSE })
    check_true("v83", "the census tool loads as a library", isTRUE(ok))
    if (isTRUE(ok)) {
        vdir <- Sys.getenv("EML_CENSUS_VALIDATE_DIR", unset = "")
        if (!nzchar(vdir)) vdir <- repo_path("validate")
        CEN <- tryCatch(.cenv$eml_evidence_census(vdir),
                        error = function(e) NULL)
    }
}
check_true("v83", "the census returns a classification table",
           !is.null(CEN) && is.data.frame(CEN) &&
           all(c("id", "class") %in% names(CEN)))

if (is.null(CEN) || !is.data.frame(CEN)) {
    CEN <- data.frame(id = character(0), file = character(0),
                      class = character(0), executes = character(0),
                      runs = character(0), reads = character(0),
                      unrooted = character(0), note = character(0),
                      stringsAsFactors = FALSE)
}

# THE `executes` COLUMN IS REQUIRED, NOT OPTIONAL. A census too old to carry
# it would make every validator look non-executing, and this file would go
# green on a rule it was no longer applying. That is the exact failure the
# column was added to stop, so its absence is a red rather than a default.
check_true("v83",
           "the census answers the execution question (an `executes` column)",
           "executes" %in% names(CEN))
if (!("executes" %in% names(CEN))) CEN$executes <- rep("UNKNOWN", nrow(CEN))
if (!("runs" %in% names(CEN)))     CEN$runs     <- rep("", nrow(CEN))

# DID ANYTHING UNDER TEST RUN. NO is a settled negative; UNKNOWN is a file
# that would not parse, and "we could not tell" is not a reason to accept a
# pin, so it is not treated as executing either.
executed <- function(ex) {
    !is.na(ex) && nzchar(ex) && !identical(ex, "NO") && !identical(ex, "UNKNOWN")
}
# THE RULE. Reads the plugin's source in the run, or ran something under test
# in the run. LIVE is retained in the disjunction only because it is cheap:
# any LIVE validator also executes PRAAT, which section 1 asserts.
qualifies <- function(cls, ex = "NO") {
    grepl("SOURCE", cls, fixed = TRUE) || grepl("LIVE", cls, fixed = TRUE) ||
        executed(ex)
}
class_of <- function(id) {
    hit <- CEN$class[CEN$id == id]
    if (!length(hit)) NA_character_ else hit[1]
}
exec_of <- function(id) {
    hit <- CEN$executes[CEN$id == id]
    if (!length(hit)) NA_character_ else hit[1]
}
runs_of <- function(id) {
    hit <- CEN$runs[CEN$id == id]
    if (!length(hit) || is.na(hit[1]) || !nzchar(hit[1])) "-" else hit[1]
}

cls_tab <- table(CEN$class)
cat("\n-- census: what each validator READS -----------------------------------\n")
for (nm in sort(names(cls_tab))) {
    cat(sprintf("     %-18s %d\n", nm, as.integer(cls_tab[[nm]])))
}
cat(sprintf("     %-18s %d\n", "TOTAL", nrow(CEN)))
cat("\n-- census: did anything under test RUN ---------------------------------\n")
ex_tab <- table(CEN$executes)
for (nm in sort(names(ex_tab))) {
    cat(sprintf("     %-18s %d\n", nm, as.integer(ex_tab[[nm]])))
}
cat("     ARTEFACT AS ORACLE (reads a committed file AND regenerated it): ",
    paste(CEN$id[grepl("ARTEFACT", CEN$class, fixed = TRUE) &
                 vapply(CEN$executes, executed, logical(1))], collapse = " "),
    "\n", sep = "")

# ---------------------------------------------------------------------------
# 1. VACUITY GUARD A -- THE CLASSIFIER IS ALIVE, IN BOTH DIRECTIONS.
#
# Two named validators must come back LIVE, two named validators must come back
# ARTEFACT-ONLY, and one must come back SOURCE and not artefact-only. A
# classifier that has silently stopped matching -- an emptied root list, a
# parser that returns nothing, a rule inverted -- cannot satisfy assertions
# that point in opposite directions. Everything below this section is only
# worth reading if this section is green.
# ---------------------------------------------------------------------------
cat("\n-- vacuity: the classifier is alive -----------------------------------\n")

check_true("v83", "the census classified a plausible number of validators",
           nrow(CEN) >= 20)

for (id in c("v77", "v70")) {
    cl <- class_of(id)
    check_true("v83",
               sprintf("%s classifies LIVE (it resolves a Praat and drives it) [%s]",
                       id, if (is.na(cl)) "absent" else cl),
               !is.na(cl) && grepl("LIVE", cl, fixed = TRUE))
}

cl80 <- class_of("v80")
check_true("v83",
           sprintf("v80 classifies SOURCE (it lints the shipped tree) [%s]",
                   if (is.na(cl80)) "absent" else cl80),
           !is.na(cl80) && grepl("SOURCE", cl80, fixed = TRUE))
check_true("v83", "v80 is therefore NOT artefact-only",
           !is.na(cl80) && !identical(cl80, "ARTEFACT"))

for (id in c("v01", "v37")) {
    cl <- class_of(id)
    check_true("v83",
               sprintf("%s classifies ARTEFACT-ONLY (a committed capture, nothing else) [%s]",
                       id, if (is.na(cl)) "absent" else cl),
               identical(cl, "ARTEFACT"))
}

# The set must be genuinely mixed. A classifier that answered "SOURCE" for
# everything would pass three of the assertions above and fail the artefact
# ones; one that answered "ARTEFACT" for everything would do the reverse. This
# says the outcome is a partition rather than a constant, which is the property
# the two directions are really testing for.
n_ao   <- sum(CEN$class == "ARTEFACT")
n_qual <- sum(vapply(seq_len(nrow(CEN)),
                     function(i) qualifies(CEN$class[i], CEN$executes[i]),
                     logical(1)))
check_true("v83",
           sprintf("the classification is a partition, not a constant (%d artefact-only, %d qualifying)",
                   n_ao, n_qual),
           n_ao > 0 && n_qual > 0)

# NONE and UNKNOWN are reported, not asserted away. A validator can honestly
# read none of the three roots -- this file is one, its subject being the
# suite's own ledger rather than the plugin -- and one that will not parse is
# UNKNOWN. Neither qualifies as a pin, and section 4 refuses both by name; what
# would be wrong is to let either slide through as if it did.
odd <- CEN$id[CEN$class %in% c("NONE", "UNKNOWN")]
cat("     reads none of the three evidence roots: ",
    if (length(odd)) paste(odd, collapse = " ") else "none", "\n", sep = "")

# ---------------------------------------------------------------------------
# 1b. VACUITY GUARD B -- THE EXECUTION DETECTOR IS ALIVE, IN BOTH DIRECTIONS.
#
# This is the newer half and the one that can fail invisibly. If `executes`
# came back NO for every validator, section 4 would still be green today --
# every pin in the ledger also reads plugin/ -- and the distinction this file
# exists for would have stopped being computed with nothing to say so. So it
# is asserted here, by name, in both directions at once.
# ---------------------------------------------------------------------------
cat("\n-- vacuity: the execution detector is alive ---------------------------\n")

# THE REGENERATING VALIDATOR, NAMED. v79 builds the release artefact from
# plugin/ inside its run -- plugin/dev/tools/build-release.py, then the zip
# unpacked under umask 077 and the modes measured on what unzip created -- and
# then compares three GUI facts against a committed record bound by digest to
# the source they rest on. It reads an artefact and it is not artefact-only in
# any sense that matters. This assertion is the whole reason the column exists.
ex79 <- exec_of("v79")
check_true("v83",
           sprintf("v79 EXECUTES its subject (it builds the release artefact from source in-run) [%s: %s]",
                   if (is.na(ex79)) "absent" else ex79, runs_of("v79")),
           !is.na(ex79) && executed(ex79))
check_true("v83",
           sprintf("v79 runs a TOOL out of this tree, not merely a Praat [%s]",
                   if (is.na(ex79)) "absent" else ex79),
           !is.na(ex79) && grepl("TOOL", ex79, fixed = TRUE))
check_true("v83",
           sprintf("v79 is therefore NOT disqualified as a pin [class %s, executes %s]",
                   class_of("v79"), if (is.na(ex79)) "absent" else ex79),
           !is.na(ex79) && qualifies(class_of("v79"), ex79))

# THE OTHER DIRECTION, ALSO NAMED. Three checks that open a committed capture,
# compare it against arithmetic done in R, and start no process at all. A
# detector that has become permissive -- every subprocess counted, every path
# under a root counted as a program -- turns these three green and is then
# qualifying the whole suite, which is as useless as qualifying none of it.
for (id in c("v01", "v37", "v03")) {
    ex <- exec_of(id)
    check_true("v83",
               sprintf("%s executes NOTHING (it reads a committed capture and computes in R) [%s]",
                       id, if (is.na(ex)) "absent" else ex),
               identical(ex, "NO"))
}

n_exec <- sum(vapply(CEN$executes, executed, logical(1)))
check_true("v83",
           sprintf("the execution answer is a partition, not a constant (%d execute, %d do not)",
                   n_exec, nrow(CEN) - n_exec),
           n_exec > 0 && n_exec < nrow(CEN))

# A CEILING, MEASURED A DIFFERENT WAY ON PURPOSE. "Not a constant" is a weak
# guard against a detector that has gone permissive: one reporting sixty of
# eighty-two as executing is still not a constant, and is still useless. So
# the executing set is bounded by something computed WITHOUT the parse tree --
# a validator cannot start a process it does not mention. This is grep, and
# grep is emphatically not the classifier: it would be far too crude to
# DECIDE anything, since a `system2` in a comment counts and a helper called
# four hundred lines away does not. As a one-sided CEILING that is exactly
# what is wanted, because it can only ever catch over-reporting, and it shares
# no code and no assumption with the thing it is bounding.
#
# IF A VALIDATOR EVER SPAWNS THROUGH A HELPER IN helpers.R this guard will go
# red on an honest file, and the fix is to widen the ceiling here rather than
# to delete it. As of today helpers.R starts no process at all.
vfiles <- sort(list.files(if (nzchar(Sys.getenv("EML_CENSUS_VALIDATE_DIR")))
                              Sys.getenv("EML_CENSUS_VALIDATE_DIR")
                          else repo_path("validate"),
                          pattern = "^v[0-9]+_.*\\.R$", full.names = TRUE))
mentions <- vapply(vfiles, function(p) {
    any(grepl("system2?[[:space:]]*\\(", readLines(p, warn = FALSE)))
}, logical(1))
can_spawn <- sub("^(v[0-9]+).*$", "\\1", basename(vfiles[mentions]))
claimed   <- CEN$id[vapply(CEN$executes, executed, logical(1))]
over      <- setdiff(claimed, can_spawn)
check_true("v83",
           sprintf("nothing is reported as executing that never mentions a subprocess (%d claimed, %d could; over-claimed: %s)",
                   length(claimed), length(can_spawn),
                   if (length(over)) paste(utils::head(over, 8), collapse = " ")
                   else "none"),
           length(can_spawn) > 0 && length(over) == 0)

# DRIVING PRAAT IS EXECUTING, BY DEFINITION. The reading side and the
# execution side are computed by different code over the same parse tree, and
# they overlap in exactly one place: a validator the first calls LIVE must be
# one the second calls PRAAT. If they disagree, one of them is broken, and
# which one hardly matters -- neither answer can be relied on until they
# agree. This is what catches a blinded detector even in a suite where every
# pin would qualify on its SOURCE clause anyway.
live_ids <- CEN$id[grepl("LIVE", CEN$class, fixed = TRUE)]
live_bad <- live_ids[!grepl("PRAAT", CEN$executes[match(live_ids, CEN$id)],
                            fixed = TRUE)]
check_true("v83",
           sprintf("every LIVE validator also EXECUTES a Praat (%d LIVE; disagreeing: %s)",
                   length(live_ids),
                   if (length(live_bad)) paste(live_bad, collapse = " ") else "none"),
           length(live_ids) > 0 && length(live_bad) == 0)

# AND THE SETS ARE NOT THE SAME SET. If executing were only ever Praat-driving
# the column would be a copy of LIVE with a new name, and the correction this
# file records would not have happened. v78 and v79 are the difference.
tool_ids <- CEN$id[grepl("TOOL", CEN$executes, fixed = TRUE)]
check_true("v83",
           sprintf("executing is BROADER than driving Praat -- some validator runs a tool of this tree (%s)",
                   if (length(tool_ids)) paste(tool_ids, collapse = " ") else "none"),
           length(tool_ids) > 0)

# ---------------------------------------------------------------------------
# 2. THE COMMITTED CENSUS RECORD REPRODUCES.
#
# The census emits validate/tools/EVIDENCE_CENSUS.tsv so a reader can diff the
# classification between commits without running anything. That file is a
# committed artefact, which makes it exactly the kind of thing this validator
# is about -- so it is not trusted, it is REGENERATED and compared. The record
# never becomes the authority; the parser is.
# ---------------------------------------------------------------------------
cat("\n-- the census record reproduces ---------------------------------------\n")
rec_p <- Sys.getenv("EML_CENSUS_RECORD", unset = "")
if (!nzchar(rec_p)) rec_p <- repo_path("validate", "tools", "EVIDENCE_CENSUS.tsv")
rec <- if (exists("eml_census_read", envir = .cenv)) .cenv$eml_census_read(rec_p) else NULL
check_true("v83", "the committed census record exists",
           file.exists(rec_p))
same <- !is.null(rec) && identical(dim(rec), dim(CEN)) &&
        identical(as.character(unlist(rec)), as.character(unlist(CEN)))
check_true("v83",
           paste0("the committed record reproduces from source",
                  if (!same) " -- regenerate: Rscript validate/tools/evidence_census.R" else ""),
           isTRUE(same))

# ---------------------------------------------------------------------------
# 3. THE LEDGER.
# ---------------------------------------------------------------------------
cat("\n-- the ledger ---------------------------------------------------------\n")
ledger_p <- Sys.getenv("EML_FINDINGS_LEDGER", unset = "")
if (!nzchar(ledger_p)) ledger_p <- repo_path("audit", "FINDINGS_MACHINE.json")

check_true("v83", sprintf("the findings ledger is readable (%s)",
                          basename(ledger_p)),
           file.exists(ledger_p))

# A minimal JSON reader, because the suite is stock R with no packages. The
# ledger is a flat array of flat string/number objects; nothing here needs a
# general parser, and a general parser written here would be one more thing to
# be wrong. Values are pulled per row with a field regex over the row's text.
rows <- list()
if (file.exists(ledger_p)) {
    txt <- paste(readLines(ledger_p, warn = FALSE), collapse = "\n")
    # The findings array, from "findings" to the last closing bracket.
    body <- sub('^.*"findings"\\s*:\\s*\\[', "", txt)
    body <- sub("\\]\\s*\\}?\\s*$", "", body)
    chunks <- regmatches(body, gregexpr("\\{[^{}]*\\}", body))[[1]]
    fld <- function(chunk, name) {
        m <- regmatches(chunk, regexpr(
            paste0('"', name, '"\\s*:\\s*"(\\\\.|[^"\\\\])*"'), chunk))
        if (!length(m)) return(NA_character_)
        v <- sub(paste0('^"', name, '"\\s*:\\s*"'), "", m)
        sub('"$', "", v)
    }
    for (ch in chunks) {
        id <- fld(ch, "id")
        if (is.na(id)) next
        rows[[length(rows) + 1L]] <- list(
            id = id, pinnedBy = fld(ch, "pinnedBy"),
            status = fld(ch, "status"))
    }
}

check_true("v83", sprintf("the ledger holds at least one finding (%d)",
                          length(rows)),
           length(rows) > 0)

pinned <- Filter(function(r) !is.na(r$pinnedBy) && nzchar(trimws(r$pinnedBy)),
                 rows)
check_true("v83",
           sprintf("at least one row claims a pin -- otherwise this check asserts nothing (%d of %d)",
                   length(pinned), length(rows)),
           length(pinned) > 0)

# ---------------------------------------------------------------------------
# 4. THE RULE ITSELF, one check per (row, validator) pair.
#
# Named individually rather than counted, so the output is directly actionable:
# a reader sees the row, the validator, and the class, and needs no
# investigation to know what to do about it.
# ---------------------------------------------------------------------------
cat("\n-- every pin reads source, or ran something ---------------------------\n")
bad_rows <- character(0)
for (r in pinned) {
    ids <- trimws(strsplit(r$pinnedBy, "[,;[:space:]]+")[[1]])
    ids <- ids[nzchar(ids)]
    for (vid in ids) {
        cl <- class_of(vid); ex <- exec_of(vid)
        if (is.na(cl)) {
            check_true("v83",
                       sprintf("%s pinnedBy %s -- UNRESOLVED: no such validator",
                               r$id, vid),
                       FALSE)
            bad_rows <- unique(c(bad_rows, r$id))
        } else if (!qualifies(cl, ex)) {
            # ARTEFACT AS SUBJECT is the case this file was written for: the
            # measured value came out of a committed file and nothing ran.
            # NONE and UNKNOWN land here too, and for the same reason --
            # neither reads the plugin nor executes it, so neither can carry
            # the claim a pin makes. The message says WHICH of the two
            # questions failed, because the repair differs: an artefact-only
            # check needs evidence that regenerates, while an UNKNOWN needs
            # someone to find out why the file will not parse.
            why <- if (identical(cl, "ARTEFACT"))
                       "ARTEFACT AS SUBJECT -- reads a committed file, executes nothing"
                   else sprintf("%s, executes %s", cl,
                                if (is.na(ex)) "unknown" else ex)
            check_true("v83",
                       sprintf("%s pinnedBy %s -- %s, does not qualify as a pin",
                               r$id, vid, why),
                       FALSE)
            bad_rows <- unique(c(bad_rows, r$id))
        } else {
            how <- if (executed(ex))
                       sprintf("executes %s: %s", ex, runs_of(vid))
                   else "reads plugin/ in the run"
            check_true("v83",
                       sprintf("%s pinnedBy %s qualifies [%s; %s]",
                               r$id, vid, cl, how),
                       TRUE)
        }
    }
}

check_true("v83",
           sprintf("no ledger row is pinned by an artefact-as-subject or unresolved validator%s",
                   if (length(bad_rows))
                       paste0(" -- rows: ", paste(bad_rows, collapse = ", "))
                   else ""),
           length(bad_rows) == 0)

if (length(bad_rows)) {
    cat("\n  A row named above is a row whose repair nothing in this tree would\n",
        "  notice the loss of. Fix it by giving the finding a validator that\n",
        "  reads plugin/, or that REGENERATES what it measures inside its own\n",
        "  run -- driving Praat, or running a builder or a harness out of this\n",
        "  tree, as v79 does -- or by withdrawing the pin so the row reads\n",
        "  `fixed-unpinned`, which is honest. Do NOT relax this check, and in\n",
        "  particular do not simplify it back into `it reads an artefact`: an\n",
        "  artefact that a validator REGENERATED is an expectation, not a\n",
        "  subject. The argument is in this file's header.\n", sep = "")
}

# ---------------------------------------------------------------------------
# NO VALIDATOR MAY END THE SUITE EARLY, WHICH IS THE SAME SUBJECT AS THIS FILE
#
# eml_exit() is quit(status = 1) as soon as ANY check in the run has failed,
# and nothing before that point. A script that calls it OUTSIDE the
# `!exists("EML_SUITE")` guard is therefore invisible while the suite is green
# and, the first time anything goes red, ends run_all.R where it stands.
#
# MEASURED 18 AUGUST 2026, and this is why the check is here rather than
# argued for. v81 and v87 both called it unguarded. With one failing check in
# v83, run_all.R sourced 86 of its 91 scripts, stopped inside v87, and printed
# "13340 checks, 13339 passed, 1 FAILED" with no indication that v90, v91,
# v92, v93 and coverage.R had never run -- 294 checks absent from a total that
# reads like a complete pass. Against the same tree with nothing red it
# sourced all 91 and reported 13627.
#
# THAT IS THIS FILE'S OWN SUBJECT, one level up. A check that ran nothing is
# not a pin; a SUITE that ran 86 of 91 scripts and says so nowhere is not a
# suite. And the script it drops first is coverage.R, whose whole job is to
# find checks that are green because they measured an empty population --
# switched off by exactly the condition that makes it worth running.
#
# The guard is the fix, so the guard is what is asserted. An eml_exit() call
# indented inside a block counts as guarded; one at column zero does not,
# except where the next non-blank line is an explicit quit(), which is a
# deliberate hard stop on a missing artefact rather than an accident.
val_files <- sort(list.files(repo_path("validate"), pattern = "^v[0-9]+.*\\.R$",
                             full.names = TRUE))
unguarded <- character(0)
for (f in val_files) {
    ln <- readLines(f, warn = FALSE)
    hits <- grep("^eml_exit\\(\\)", ln)          # column zero == outside any block
    for (h in hits) {
        nxt <- ln[seq_len(length(ln))[-seq_len(h)]]
        nxt <- nxt[nzchar(trimws(nxt))]
        if (length(nxt) && grepl("^\\s*quit\\(", nxt[1])) next
        unguarded <- c(unguarded, sprintf("%s:%d", basename(f), h))
    }
}
check_true("v83",
           sprintf("no validator calls eml_exit() outside the EML_SUITE guard, so no red check can truncate the run (%d file(s) read)%s",
                   length(val_files),
                   if (length(unguarded))
                       paste0(" -- ", paste(unguarded, collapse = ", ")) else ""),
           length(val_files) > 0 && length(unguarded) == 0)
if (length(unguarded)) {
    cat("\n  The line named above ends run_all.R the first time anything in the\n",
        "  suite goes red, and reports a total that looks complete. Wrap it in\n",
        "  `if (!exists(\"EML_SUITE\")) { ... }` the way every other validator\n",
        "  does. Do not relax this check by counting scripts instead: the\n",
        "  truncation happens INSIDE the sourcing loop, so there is nothing\n",
        "  left running to count them.\n", sep = "")
}

if (!exists("EML_SUITE")) {
    eml_report("v83 pin definition — a check that ran nothing is not a pin")
    eml_exit()
}
