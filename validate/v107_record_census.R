# ============================================================================
# v107_record_census.R -- every command in the menu either records, or says why
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR, and why it is a census rather than a list of cases.
#
# The recorder's job is to write down what the user did, so the script it
# produces reproduces the session. A step that is never recorded is not a
# wrong entry in that script -- it is an ABSENCE, and an absence is the one
# defect a reader of the script cannot see. The script looks complete. It
# simply does not mention that a column was edited, or that the table it
# operates on was invented by the demo generator thirty seconds earlier.
#
# So the question this file asks is not "do the paths we thought of record?"
# It is: OF EVERY COMMAND THE PLUGIN PUTS IN A MENU, which ones record, and
# has anyone decided about the rest? The universe is read from setup.praat --
# the file Praat itself reads to build the menus -- so a command added
# tomorrow is in the population tomorrow, without anyone remembering to add
# it here. That is the property a hand-kept list does not have, and the
# reason this is written as a census.
#
# HOW REACHABILITY IS DECIDED. A wrapper almost never records for itself:
# scripts/eml-correlate.praat contains no record call at all, and records
# only because the analysis procedure it calls does. So each command is
# followed through the CALL GRAPH -- `@procName` references, resolved against
# every procedure defined anywhere in the plugin -- and counts as recording if
# any procedure it can reach contains a record call. Calls, not includes: a
# wrapper includes eml-lib.praat, which pulls in the whole plugin, so
# following includes would mark every command as recording and prove nothing.
#
# THE EXEMPTIONS ARE NAMED WITH THEIR REASONS, one line each, and they are
# the interesting part of this file. A command that legitimately does not
# record -- the tutorial, which teaches; the recorder's own controls, which
# would record themselves -- says so here. Anything else that does not record
# is a finding, not an omission, and the check names it.
#
# Base R only. Reads source; drives nothing.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v107"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

plug <- repo_path("plugin_EML_StatsGraphs")
setup <- file.path(plug, "setup.praat")

read_lines <- function(p) if (file.exists(p)) readLines(p, warn = FALSE) else character(0)

ok_setup <- check_true(V, "setup.praat is where the menus come from",
                       file.exists(setup))
if (!ok_setup) {
    if (!exists("EML_SUITE")) { eml_report("v107 -- the recording census"); eml_exit() }
}

# ---------------------------------------------------------------------------
# 1. THE UNIVERSE, READ FROM THE FILE PRAAT READS
# ---------------------------------------------------------------------------
# A registration line ends with the script it runs, in quotes. Lines whose
# script is "" are structure -- the cascade itself, and the "-- eml describe --"
# separators -- and are not commands a user can invoke.
# THE WALK ITSELF NOW LIVES IN helpers.R, as eml_setup_commands(). It moved
# there on 24 August 2026 when v111 needed the same population -- of every
# command the menu registers, which ones has anything ever opened from an
# empty Objects window -- and two files deriving one universe separately is
# the drift this census exists to refuse. Nothing about what is read changed:
# the same registration lines, the same last-quoted-field rule, the same
# collapse of the several object-type registrations of one script.
cmd <- eml_setup_commands(setup)

check_true(V, sprintf("the menu registers %d runnable commands across %d files",
                      attr(cmd, "registrations"), nrow(cmd)),
           nrow(cmd) >= 15)

# ---------------------------------------------------------------------------
# 2. THE CALL GRAPH
# ---------------------------------------------------------------------------
praat <- list.files(plug, pattern = "\\.praat$", recursive = TRUE,
                    full.names = TRUE)
praat <- praat[!grepl("/dev/", praat)]

# procedure name -> its body's text
bodies <- list()
toplevel <- list()
for (p in praat) {
    ln <- read_lines(p)
    starts <- grep("^procedure [A-Za-z]", ln)
    ends <- grep("^endproc[[:space:]]*$", ln)
    used <- logical(length(ln))
    for (s in starts) {
        e <- ends[ends > s]
        if (!length(e)) next
        e <- e[1]
        nm <- sub("^procedure ([A-Za-z0-9_]+).*$", "\\1", ln[s])
        bodies[[nm]] <- c(bodies[[nm]], ln[s:e])
        used[s:e] <- TRUE
    }
    toplevel[[basename(p)]] <- ln[!used]
}

calls_in <- function(txt) unique(sub("^@", "",
    regmatches(txt, gregexpr("@[A-Za-z0-9_]+", txt)) |> unlist()))

# SAVE IS EXCLUDED FROM WHAT COUNTS AS RECORDING, and the exclusion is the
# point. Every wrapper can reach @emlSavePanel, which records that a file was
# written -- so a pattern that counted Save would mark a command as recording
# because the user could save its output, whether or not the WORK that
# produced the output was written down. Measured: the batch module reaches a
# save step and an analysis step, and the first search to find Save reported
# it as covered on the strength of the wrong one.
RECORD_RX <- "@emlRecord(AnalysisStep|DrawStep|Step|Convert)\\b"
records_directly <- function(txt) any(grepl(RECORD_RX, txt))

# A `runScript:` IS AN EDGE IN THIS GRAPH, and leaving it out makes the
# census read the wrong answer with total confidence. Two of the commands
# below reach their work that way -- both doors of the table editor register
# a thin wrapper whose whole body is `runScript: "eml-edit-table.praat"` --
# and the editor in turn hands each committed change to
# scripts/eml-record-edit-step.praat by the same mechanism, because it
# includes nothing. A walk that followed only `@` calls stops at the first
# hop and reports a command that records as one that does not, which is the
# stale entry this file's own KNOWN_SILENT note refuses to tolerate.
#
# The target is a bare filename resolved against the caller's folder, so it
# is matched against the file basenames `toplevel` is keyed by, and a target
# that is not a plugin file is simply an edge that goes nowhere.
runscripts_in <- function(txt) {
    hits <- grep('runScript:[[:space:]]*"', txt, value = TRUE)
    if (!length(hits)) return(character(0))
    unique(basename(sub('^.*runScript:[[:space:]]*"([^"]+)".*$', "\\1", hits)))
}

reaches_record <- function(start_txt) {
    seen <- character(0)
    seen_file <- character(0)
    front <- calls_in(start_txt)
    front_file <- runscripts_in(start_txt)
    if (records_directly(start_txt)) return(TRUE)
    while (length(front) || length(front_file)) {
        if (length(front)) {
            n <- front[1]; front <- front[-1]
            if (n %in% seen) next
            seen <- c(seen, n)
            b <- bodies[[n]]
        } else {
            f <- front_file[1]; front_file <- front_file[-1]
            if (f %in% seen_file) next
            seen_file <- c(seen_file, f)
            b <- toplevel[[f]]
        }
        if (is.null(b)) next
        if (records_directly(b)) return(TRUE)
        front <- c(front, setdiff(calls_in(b), seen))
        front_file <- c(front_file, setdiff(runscripts_in(b), seen_file))
    }
    FALSE
}

# ---------------------------------------------------------------------------
# 3. THE EXEMPTIONS, EACH WITH ITS REASON
# ---------------------------------------------------------------------------
# A command belongs here only when recording it would be WRONG, not when
# recording it has merely not been built. "Not built yet" is a finding.
EXEMPT <- c(
    # The recorder's own controls. A recorder that recorded being started
    # would put its own start into the script it was about to write.
    "scripts/eml-record-start.praat" = "starts recording",
    "scripts/eml-record-save.praat"  = "writes the recording out",
    # The teaching surfaces are NOT listed here, deliberately. Their
    # registration lines are commented out in setup.praat, so they are not
    # commands a user can reach, and an exemption for an unregistered command
    # is a line that outlives the thing it excuses. The check below refuses
    # exactly that.
    "scripts/eml-record-open.praat"  = "opens a saved recording"
)

exempt_named <- names(EXEMPT)
check_true(V, "every exemption names a command that is actually registered",
           all(exempt_named %in% cmd$script) ||
           length(setdiff(exempt_named, cmd$script)) == 0)
stale_ex <- setdiff(exempt_named, cmd$script)
check_true(V,
           sprintf("no exemption names a command that no longer exists%s",
                   if (length(stale_ex))
                       paste0(" -- stale: ", paste(stale_ex, collapse = ", "))
                   else ""),
           length(stale_ex) == 0)

# ---------------------------------------------------------------------------
# 4. THE CENSUS
# ---------------------------------------------------------------------------
silent <- character(0)
recording <- character(0)
for (i in seq_len(nrow(cmd))) {
    s <- cmd$script[i]
    if (s %in% exempt_named) next
    f <- file.path(plug, s)
    txt <- c(read_lines(f), unlist(bodies[calls_in(read_lines(f))]))
    if (reaches_record(read_lines(f))) recording <- c(recording, s)
    else silent <- c(silent, s)
}

check_true(V, sprintf("%d commands reach a record step", length(recording)),
           length(recording) > 0)

# WHAT DOES NOT RECORD, NAMED RATHER THAN TOLERATED SILENTLY.
#
# A check that simply failed here would make the suite red for as long as the
# gap exists, and a suite that is permanently red stops being read -- which
# would cost more than the gap it was complaining about. A check that ignored
# the gap would be worse. So the population is RATCHETED: what is left is
# written down with what it loses, and the check goes
# red the moment the set changes in either direction.
#
# It fails if another appears, which is the whole point -- a new command that
# forgets to record is caught the day it is added, not the day someone
# happens to replay a script and notice something missing.
#
# It also fails when one is closed, and that is deliberate rather than
# annoying: closing one has to come with deleting its line here, so this list
# cannot quietly outlive the defect it describes. A stale exemption is the
# failure mode this file exists to prevent, and it would be ironic to build
# one in.
KNOWN_SILENT <- c(
    # Reports on the data's shape. It changes nothing and produces no result
    # an analysis depends on, which makes it the one most likely to end up
    # EXEMPT with a reason rather than fixed.
    "scripts/eml-check-data.praat"
)

new_silent <- setdiff(silent, KNOWN_SILENT)
fixed_silent <- setdiff(KNOWN_SILENT, silent)

check_true(V,
           sprintf("no command has newly stopped recording%s",
                   if (length(new_silent))
                       paste0(" -- NEW: ", paste(sub("^scripts/", "", new_silent),
                                                 collapse = ", "))
                   else ""),
           length(new_silent) == 0)

check_true(V,
           sprintf("the known-silent list has no entry that now records%s",
                   if (length(fixed_silent))
                       paste0(" -- now recording, delete its line: ",
                              paste(sub("^scripts/", "", fixed_silent),
                                    collapse = ", "))
                   else ""),
           length(fixed_silent) == 0)

check_true(V,
           sprintf("%d command(s) record their work; %d known silent",
                   length(recording), length(silent)),
           length(recording) >= 13)

if (length(new_silent)) {
    cat("\n  A command in this list runs, changes the user's objects or",
        "\n  produces a result, and leaves no trace in a recorded script. The",
        "\n  script it produces is not wrong -- it is silently incomplete,",
        "\n  which is the one defect a reader of that script cannot see.",
        "\n  Either give it a record step, or add it to EXEMPT above WITH THE",
        "\n  REASON recording it would be wrong.\n", sep = "")
}

if (!exists("EML_SUITE")) { eml_report("v107 -- the recording census"); eml_exit() }
