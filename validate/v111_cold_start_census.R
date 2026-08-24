# ============================================================================
# v111_cold_start_census.R -- every door, opened with nothing selected
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR, and it came from a real crash.
#
# Ian started the wizard with NO table selected, chose Compare, answered that
# the same people were measured more than once, and pressed Continue. Praat
# raised "Unknown variable" over the form he had just answered. Fourteen
# wizard pages print the selected table's name; with nothing selected the
# wizard invents example data, but it invents it at the point the chosen
# branch needs columns, which on that branch is AFTER a page that has already
# printed the name. The page did not render blank -- it ERRORED, over a form
# that looked like it was working.
#
# THE GAP UNDER IT IS WHY THIS IS A CENSUS AND NOT A CASE. Every check in this
# tree that reads a dialog reads it as TEXT, and every harness that DRIVES one
# drives it with a table selected: each rig's first act is to make a fixture.
# So nothing had ever opened any entry point from the state a first-time user
# is actually in. That is not one bug, it is a quadrant -- one whole axis of
# the plugin's state space that no evidence covered -- and the wizard is
# fifteen branches wide inside it.
#
# The question is therefore not "does the branch Ian hit work now?" It is: OF
# EVERY DOOR THIS PLUGIN HAS, what does each one do when it is opened with an
# empty Objects window? The universe is read from setup.praat -- the file
# Praat itself reads to build the menus, through the same walk v107 uses -- so
# a command added tomorrow is in the population tomorrow, without anyone
# remembering to add it here.
#
# WHAT COUNTS AS A DOOR. Twenty scripts are registered in setup.praat. The
# wizard is one of them and is also THIRTEEN-PLUS DOORS WEARING ONE MENU
# ENTRY: its branches reach different pages, in different orders, and Ian's
# crash was branch-ORDER dependent -- it needed Compare, then within-subject,
# then two conditions, in that order. A single wizard leg would have opened
# the front page, seen it render, and reported the wizard fine. So the
# wizard's branches are legs in their own right, and this file treats them as
# entry points.
#
# THE ASSERTION IS EXACTLY TWO THINGS. From an empty Objects window an entry
# point may:
#
#   REFUSE HONESTLY -- the plugin's own refusal dialog, which names what to
#       select and changes nothing; or its own dialog opening because it needs
#       no table at all; or its own sentence in the Info window.
#   PROCEED TO ITS OWN EXAMPLE-DATA PATH -- the wizard's "No table selected"
#       page offering Create Demo, ANSWERED, and the branch carrying on to a
#       page that needs columns. That last part is the whole point: reaching
#       the column page is what proves the branch survives the empty state,
#       and it is exactly where Ian's crash was.
#
# What it may NEVER do is raise a raw Praat error over a form the user has
# just answered. That is the failure this family exists to catch, and
# `state = error` is a FAILURE here rather than a recorded curiosity.
#
# NEITHER MAY THE RIG FAIL SILENTLY. `exited`, `stalled` and `rig_unreachable`
# are the driver saying it never got an answer, and a leg that measured
# nothing must not read as a leg that measured something good. They fail too,
# under their own names, because they need a different fix from a plugin bug.
# This is not hypothetical: the first drive of this family recorded four legs
# as `exited` that a re-drive showed refusing perfectly well, and three
# recorder commands as `exited` that were in fact printing their sentence and
# finishing. Blessing that file would have pinned a rig fault as plugin
# behaviour. See the DEFECTS note at the foot of this file.
#
# IT IS A RATCHET, in v107's shape and for v107's reason. A check that merely
# failed while a gap existed would make the suite permanently red, and a
# permanently red suite stops being read. A check that ignored the gap would
# be worse. So the population is derived, the outcomes are written down, and
# the check goes red the moment the set changes IN EITHER DIRECTION:
#
#   * an entry point with no cold-start leg is RED -- the day it is added,
#     not the day someone happens to open it with an empty Objects window;
#   * an entry whose outcome is listed here as not-yet-ideal and which is now
#     ideal is ALSO RED, so the line cannot outlive the thing it excuses.
#     A stale exemption is the failure mode this file exists to prevent and it
#     would be ironic to build one in.
#
# IT CARRIES ITS OWN REFUTATION, because a VACUOUS PASS is this check's
# characteristic failure. Every assertion below is of the form "for every leg
# in the evidence ..." and every one of them passes, correctly and silently,
# over an empty file -- which is precisely what a driver that could not start
# Praat produces. So section 4 is a resolver gate: it FAILS if the walk
# covered zero entry points, and it REPORTS HOW MANY it covered, so a reader
# can see the number rather than infer it from the absence of complaint. The
# evidence must also cover the whole declared population, because a partial
# file is the same failure wearing a smaller hat: the first drive of this
# family wrote 15 of 35 legs and every per-leg assertion on it passed.
#
# THE RED DEMONSTRATION is harness/coldstart/seed_violation.sh: a COPY of the
# shipped plugin with one wrapper made to touch the selection before its guard
# runs, driven by run.sh unmodified through $EML_COLDSTART_SRC, and read by
# this file unmodified through $EML_COLDSTART_OUT. What goes red is this
# check, not a rehearsal of it.
#
# Base R only. Reads the driver's artefact and the plugin's source; drives
# nothing.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v111"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

# $EML_COLDSTART_SRC points the POPULATION half of this file at a tree other
# than the shipped one -- the same variable run.sh takes for the same reason.
# It is how the ratchet is demonstrated red: a copy of the plugin with one
# extra command registered in setup.praat and no leg written for it, audited
# by this file unmodified. No drive is needed for that one, because the
# population is read from source.
plug  <- Sys.getenv("EML_COLDSTART_SRC", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
setup <- file.path(plug, "setup.praat")
wizsrc <- file.path(plug, "scripts", "eml-wizard.praat")

# $EML_COLDSTART_OUT points this file at a drive other than the shipped one.
# It is how the red demonstration is run, and it is the SAME variable run.sh
# takes, so the seeding script sets one thing and both ends follow it.
outdir <- Sys.getenv("EML_COLDSTART_OUT", unset = "")
if (!nzchar(outdir)) outdir <- repo_path("harness", "coldstart", "out")
tsv    <- file.path(outdir, "COLDSTART.tsv")
legstv <- repo_path("harness", "coldstart", "legs.tsv")

# ---------------------------------------------------------------------------
# 0. THE TWO FILES LOAD
# ---------------------------------------------------------------------------
ok_files <- check_true(V, "the driver's artefact and the leg table are both present",
                       file.exists(tsv) && file.exists(legstv))
if (!ok_files) {
    cat("\n  harness/coldstart/out/COLDSTART.tsv is written by\n",
        "  bash harness/coldstart/run.sh. Without it this file has nothing to\n",
        "  read, and it says so rather than passing over the silence.\n", sep = "")
    if (!exists("EML_SUITE")) { eml_report("v111 -- the cold-start census"); eml_exit() }
}

# The leg table is TAB separated with a comment block on top. Read as text and
# split on tab: read.delim would take the first non-comment line as data and a
# note field carrying an apostrophe would be a quoting problem it solves by
# silently swallowing rows.
legs_raw <- readLines(legstv, warn = FALSE)
legs_raw <- legs_raw[!grepl("^#", legs_raw) & nzchar(legs_raw)]
legs_f   <- strsplit(legs_raw, "\t", fixed = TRUE)
hdr      <- legs_f[[1]]
legs_f   <- legs_f[-1]
fld <- function(row, name) {
    i <- match(name, hdr)
    if (is.na(i) || length(row) < i) "" else row[i]
}
legs <- data.frame(
    leg   = vapply(legs_f, fld, "", "leg"),
    entry = vapply(legs_f, fld, "", "entry"),
    plan  = vapply(legs_f, fld, "", "plan"),
    kind  = vapply(legs_f, fld, "", "kind"),
    note  = vapply(legs_f, fld, "", "note"),
    stringsAsFactors = FALSE
)

ev_raw <- readLines(tsv, warn = FALSE)
ev_raw <- ev_raw[nzchar(ev_raw)][-1]          # drop the header row
ev_f   <- strsplit(ev_raw, "\t", fixed = TRUE)
ev <- data.frame(
    leg   = vapply(ev_f, function(r) if (length(r) >= 1) r[1] else "", ""),
    key   = vapply(ev_f, function(r) if (length(r) >= 2) r[2] else "", ""),
    value = vapply(ev_f, function(r) if (length(r) >= 3) r[3] else "", ""),
    stringsAsFactors = FALSE
)

# `val` is read BY KEY, never by row offset. run.sh emits nine or ten rows per
# leg depending on whether it recorded the display it claimed, and a reader
# that counted rows would silently shift by one the day a key was added --
# which is how the first version of this file's predecessor came to report a
# leg's `state` out of the row above it.
val <- function(lg, k, default = NA_character_) {
    i <- which(ev$leg == lg & ev$key == k)
    if (!length(i)) default else ev$value[i[length(i)]]
}

# AN EMPTY LEG NAME IS A CORRUPT ROW, NOT A LEG. The first drive of this
# family produced a block of rows whose leg name was the empty string -- the
# driver had been handed a blank line and had run Praat against the scripts
# FOLDER rather than a script. Rows like that are named here rather than
# quietly dropped: a reader who sees "34 legs" when the table declares 35 is
# owed the reason.
blank_rows <- sum(!nzchar(ev$leg))
check_true(V,
           sprintf("the artefact carries no rows with an empty leg name%s",
                   if (blank_rows) sprintf(" -- %d such row(s)", blank_rows) else ""),
           blank_rows == 0)

walked <- setdiff(unique(ev$leg), "")

# ---------------------------------------------------------------------------
# 1. THE POPULATION OF ENTRY POINTS, READ FROM THE FILE PRAAT READS
# ---------------------------------------------------------------------------
# eml_setup_commands() is v107's walk, moved into helpers.R when this file
# needed the same universe. Two validators deriving one population separately
# is exactly the drift a census is for.
cmd <- eml_setup_commands(setup)
registered <- sub("^scripts/", "", cmd$script)

entry_legs <- legs[legs$kind == "entry", ]
covered    <- unique(entry_legs$entry)

missing_leg <- setdiff(registered, covered)
check_true(V,
           sprintf("every command setup.praat registers has a cold-start leg%s",
                   if (length(missing_leg))
                       paste0(" -- NO LEG: ", paste(missing_leg, collapse = ", "))
                   else ""),
           length(missing_leg) == 0)

phantom_leg <- setdiff(covered, registered)
check_true(V,
           sprintf("every cold-start leg names a command still registered%s",
                   if (length(phantom_leg))
                       paste0(" -- registered nowhere, delete its line: ",
                              paste(phantom_leg, collapse = ", "))
                   else ""),
           length(phantom_leg) == 0)

check_true(V, sprintf("%d registered commands, %d entry legs",
                      length(registered), nrow(entry_legs)),
           length(registered) >= 15 && nrow(entry_legs) == length(registered))

if (length(missing_leg)) {
    cat("\n  A command in this list is in the menu and has never been opened\n",
        "  from an empty Objects window. That is the state every first-time\n",
        "  user is in. Add a row to harness/coldstart/legs.tsv and drive it.\n",
        sep = "")
}

# ---------------------------------------------------------------------------
# 2. THE WIZARD'S BRANCHES, WHICH ARE ENTRY POINTS TOO
# ---------------------------------------------------------------------------
# THE TOP FORK IS DERIVED, because it is the one part of the wizard's shape
# that is unambiguous in the source: a single `optionmenu: "Research goal"`
# with one `option:` line per destination. If someone adds a seventh goal,
# the count moves and this goes red on the day the goal lands.
#
# WHAT IS NOT DERIVED, AND WHY NOT. Below that fork the wizard's routing is
# ordinary Praat control flow -- aliased variables, `if`/`elsif` chains, one
# branch that reroutes into another goal entirely -- and a parser for it here
# would be a MODEL OF THE WIZARD standing in for the wizard, which is the
# thing harness/coldstart/run.sh refuses to build and the reason its legs
# drive real pages. Two derived facts are used instead, and between them they
# catch what matters:
#
#   * the goal fork's width, against the goals the branch legs declare;
#   * the SET OF PAGE TITLES the branch walk actually reached, ratcheted.
#     A new route under an existing goal takes the user somewhere, and
#     "somewhere" is a page title -- so it shows up here as a title no leg
#     reaches, or as a title that has moved.
wiz <- trimws(readLines(wizsrc, warn = FALSE))
gi  <- grep('^optionmenu:[[:space:]]*"Research goal"', wiz)
n_goals <- 0L
if (length(gi) == 1L) {
    j <- gi + 1L
    while (j <= length(wiz) && grepl("^option:", wiz[j])) {
        n_goals <- n_goals + 1L; j <- j + 1L
    }
}
check_true(V,
           sprintf("the wizard's goal fork is a single menu, read from source (%d options)",
                   n_goals),
           length(gi) == 1L && n_goals > 0L)

branch_legs <- legs[legs$kind == "branch", ]
# The first step of a plan is the goal it picks: "s1=4;-" picks goal 4.
first_goal <- suppressWarnings(as.integer(
    sub("^s1=([0-9]+).*$", "\\1", vapply(strsplit(branch_legs$plan, ";", fixed = TRUE),
                                         function(p) p[1], ""))))
goals_walked <- sort(unique(first_goal[!is.na(first_goal)]))
check_true(V,
           sprintf("every research goal has at least one branch leg (%d of %d)%s",
                   length(goals_walked), n_goals,
                   if (!setequal(goals_walked, seq_len(n_goals)))
                       paste0(" -- uncovered: ",
                              paste(setdiff(seq_len(n_goals), goals_walked),
                                    collapse = ", "))
                   else ""),
           n_goals > 0L && setequal(goals_walked, seq_len(n_goals)))

# THE BRANCH LEGS THEMSELVES, RATCHETED BY NAME -- which is what
# harness/coldstart/legs.tsv says this file ratchets on. A branch added to the
# leg table without a line here is red, and so is a line here whose leg is
# gone: the two lists have to be edited together or the population silently
# stops meaning anything.
KNOWN_BRANCHES <- c(
    "w_indep_two", "w_indep_k", "w_indep_twofactor",
    "w_within_two",                 # Ian's crash, and the reason for all of it
    "w_within_k",
    "w_rel_correlation", "w_rel_regression", "w_rel_categorical",
    "w_rel_cont_cat",               # reroutes into Compare, so it walks two goals
    "w_desc_single", "w_desc_bygroup", "w_desc_normality",
    "w_predict",
    "w_goal_classify", "w_goal_reduce"
)
new_branch  <- setdiff(branch_legs$leg, KNOWN_BRANCHES)
gone_branch <- setdiff(KNOWN_BRANCHES, branch_legs$leg)
check_true(V,
           sprintf("no wizard branch leg is unaccounted for%s",
                   if (length(new_branch))
                       paste0(" -- NEW: ", paste(new_branch, collapse = ", "))
                   else ""),
           length(new_branch) == 0)
check_true(V,
           sprintf("no branch named here has been removed from the leg table%s",
                   if (length(gone_branch))
                       paste0(" -- gone, delete its line: ",
                              paste(gone_branch, collapse = ", "))
                   else ""),
           length(gone_branch) == 0)

# ---------------------------------------------------------------------------
# 3. THE EVIDENCE COVERS THE WHOLE DECLARED POPULATION
# ---------------------------------------------------------------------------
# A PARTIAL ARTEFACT PASSES EVERY PER-LEG ASSERTION BELOW. The first drive of
# this family wrote 15 of 35 legs -- the connection carrying it dropped
# mid-run -- and every "for each leg in the evidence" check on that file was
# green, about a file missing two thirds of the population including the
# branch Ian crashed on. So the artefact is compared against the leg table
# before anything is asserted of its contents.
undriven <- setdiff(legs$leg, walked)
extra    <- setdiff(walked, legs$leg)
check_true(V,
           sprintf("every declared leg is in the artefact (%d of %d)%s",
                   length(intersect(legs$leg, walked)), nrow(legs),
                   if (length(undriven))
                       paste0(" -- NEVER DRIVEN: ",
                              paste(utils::head(undriven, 8), collapse = ", "),
                              if (length(undriven) > 8)
                                  sprintf(" (+%d more)", length(undriven) - 8) else "")
                   else ""),
           length(undriven) == 0)
check_true(V,
           sprintf("the artefact carries no leg the table does not declare%s",
                   if (length(extra))
                       paste0(" -- ", paste(extra, collapse = ", ")) else ""),
           length(extra) == 0)

# THE RIG REACHED PRAAT FOR EVERY LEG. `listening` is run.sh's own answer to
# "did the instance I started take a script from me", and a leg where it is 0
# has measured nothing whatever about the plugin. Asserted separately from the
# verdict so that a rig fault reads as a rig fault.
not_listening <- Filter(function(lg) !identical(val(lg, "listening"), "1"), walked)
check_true(V,
           sprintf("the rig reached a live Praat for every leg%s",
                   if (length(not_listening))
                       paste0(" -- never reached: ",
                              paste(utils::head(not_listening, 8), collapse = ", "))
                   else ""),
           length(not_listening) == 0)

# ---------------------------------------------------------------------------
# 4. THE RESOLVER GATE -- THE REFUTATION OF A VACUOUS PASS
# ---------------------------------------------------------------------------
# Everything in section 5 is "for every leg ...", and every one of those
# passes over an empty file. An empty file is not a hypothetical: it is what a
# driver that cannot find Praat, or cannot start Xvfb, writes. So the number
# of entry points actually walked is asserted to be non-zero AND PRINTED, and
# it is asserted against the population rather than against a constant, so it
# cannot be satisfied by a drive that shrank.
n_entry_walked  <- length(intersect(entry_legs$leg, walked))
n_branch_walked <- length(intersect(branch_legs$leg, walked))
check_true(V,
           sprintf("RESOLVER: the walk covered %d entry points and %d wizard branches",
                   n_entry_walked, n_branch_walked),
           n_entry_walked > 0 && n_branch_walked > 0)
check_true(V,
           sprintf("RESOLVER: %d of %d declared legs carry a recorded verdict",
                   sum(!is.na(vapply(walked, val, "", "state"))), nrow(legs)),
           length(walked) == nrow(legs))

# ---------------------------------------------------------------------------
# 5. THE ASSERTION: REFUSED HONESTLY, OR PROCEEDED TO ITS OWN EXAMPLE DATA
# ---------------------------------------------------------------------------
# run.sh's vocabulary, and which half of the ruling each verdict satisfies:
#
#   refused        the plugin's own refusal dialog       -- refused honestly
#   page           the command's own dialog, no table needed -- refused honestly
#   spoke          a sentence in the Info window, no dialog  -- refused honestly
#   example        the example-data page ANSWERED and the branch carried on
#                                                        -- proceeded
#   example_offer  offered example data, did not take it -- neither; ratcheted
#   error          Praat stopped                         -- THE FAILURE
#   exited/stalled/rig_unreachable                       -- the rig failing
HONEST  <- c("refused", "page", "spoke", "example")
RIGFAIL <- c("exited", "stalled", "rig_unreachable")

state_of <- vapply(walked, val, "", "state")
names(state_of) <- walked

raw_error <- walked[state_of[walked] %in% "error"]
check_true(V,
           sprintf("no entry point raises a raw Praat error from the empty state%s",
                   if (length(raw_error))
                       paste0(" -- ERRORED: ", paste(raw_error, collapse = ", "))
                   else ""),
           length(raw_error) == 0)

# ASKED OF THE LOG AS WELL AS OF THE VERDICT. `state` is run.sh's reading; the
# leg's own log is the thing it read. If a log carries a Praat error that the
# verdict does not mention, the classifier is what is wrong, and either way
# this file must not report green.
logged_error <- Filter(function(lg) {
    p <- file.path(outdir, paste0(lg, ".log"))
    file.exists(p) && any(grepl("PRAAT ERROR MESSAGE", readLines(p, warn = FALSE),
                                fixed = TRUE))
}, walked)
check_true(V,
           sprintf("no leg's log carries a Praat error message%s",
                   if (length(logged_error))
                       paste0(" -- ", paste(logged_error, collapse = ", ")) else ""),
           length(logged_error) == 0)

rig_broke <- walked[state_of[walked] %in% RIGFAIL]
check_true(V,
           sprintf("no leg's verdict is the rig failing rather than the plugin answering%s",
                   if (length(rig_broke))
                       paste0(" -- ",
                              paste(sprintf("%s (%s)", rig_broke, state_of[rig_broke]),
                                    collapse = ", "))
                   else ""),
           length(rig_broke) == 0)

# ---------------------------------------------------------------------------
# 6. THE RATCHET ON WHAT IS NOT YET IDEAL
# ---------------------------------------------------------------------------
# A leg here answers the cold start in a way that is not a failure and is not
# the ideal either. Each line says which leg and why, one line each, and the
# check goes red in BOTH directions: a new one appears, or one of these
# becomes ideal and its line is still here.
KNOWN_NOT_IDEAL <- c(
    # (empty at the time of writing -- every leg reaches one of HONEST.
    #  A line added here must name the leg and the reason on the same line.)
)

not_honest <- walked[!(state_of[walked] %in% HONEST)]
new_not_ideal   <- setdiff(not_honest, KNOWN_NOT_IDEAL)
fixed_not_ideal <- setdiff(KNOWN_NOT_IDEAL, not_honest)

check_true(V,
           sprintf("every entry point either refuses honestly or reaches its own example data%s",
                   if (length(new_not_ideal))
                       paste0(" -- NOT: ",
                              paste(sprintf("%s (%s)", new_not_ideal,
                                            state_of[new_not_ideal]), collapse = ", "))
                   else ""),
           length(new_not_ideal) == 0)
check_true(V,
           sprintf("nothing listed as not-yet-ideal now answers the cold start properly%s",
                   if (length(fixed_not_ideal))
                       paste0(" -- fixed, delete its line: ",
                              paste(fixed_not_ideal, collapse = ", "))
                   else ""),
           length(fixed_not_ideal) == 0)

if (length(new_not_ideal) || length(raw_error)) {
    cat("\n  A leg in this list opened a door the way a first-time user opens\n",
        "  it -- with nothing selected -- and the plugin neither refused it\n",
        "  nor carried it to its own example data. Ian's crash was exactly\n",
        "  this, on w_within_two. Fix the entry point, or, if the outcome is\n",
        "  acceptable, add it to KNOWN_NOT_IDEAL above WITH THE REASON.\n",
        sep = "")
}

# ---------------------------------------------------------------------------
# 7. THE PAGES THE BRANCH WALK REACHED, RATCHETED
# ---------------------------------------------------------------------------
# The second derived half of section 2. Every branch leg records the sequence
# of page titles it saw; the union of those titles is the wizard's reachable
# surface from an empty Objects window. A route added under an existing goal
# takes the user to a page, so it shows up here as a title nothing has walked
# to, or as a title that has moved -- without this file having to model the
# wizard's control flow to find it.
#
# Titles are ASCII-folded before comparison: the wizard's page titles carry em
# dashes, and pinning the bytes would be comparing this file's encoding
# against that file's rather than comparing the pages.
fold <- function(s) gsub("[^ -~]+", "-", s)
trails <- unlist(lapply(intersect(branch_legs$leg, walked), function(lg) {
    tr <- val(lg, "trail", "")
    if (!nzchar(tr)) return(character(0))
    trimws(strsplit(tr, ">", fixed = TRUE)[[1]])
}))
pages_seen <- sort(unique(fold(sub("^Pause:[[:space:]]*", "", trails))))

KNOWN_PAGES <- c(
    "Analysis complete",              # the stubs land here: "Not Yet Available"
    "Compare - Observation type",
    "Compare independent - Design",
    "Correlation - Select columns",
    "Describe - Select column",
    "Describe - What to summarize",
    "Describe by group - Select columns",
    "EML Stats Wizard",               # the front page every branch starts on
    "No table selected",              # the example-data offer -- the cold start
    "Normality check - Select column",
    "Paired - Select columns",        # Ian's crash landed here, or should have
    "Paired / repeated - how many conditions?",
    "Predict - Select columns",
    "Regression - Select columns",
    "Relationship - What type?",
    "Repeated measures - select condition columns",
    "Three+ groups - Select columns",
    "Two groups - Select columns",
    "Two-Factor Design"
)
new_pages  <- setdiff(pages_seen, KNOWN_PAGES)
lost_pages <- setdiff(KNOWN_PAGES, pages_seen)
check_true(V,
           sprintf("the branch walk reaches no page this file does not know about%s",
                   if (length(new_pages))
                       paste0(" -- NEW: ", paste(new_pages, collapse = " | ")) else ""),
           length(new_pages) == 0)
check_true(V,
           sprintf("every page this file knows about is still reached (%d)%s",
                   length(pages_seen),
                   if (length(lost_pages))
                       paste0(" -- NO LONGER REACHED: ",
                              paste(lost_pages, collapse = " | "))
                   else ""),
           length(lost_pages) == 0)

# THE BRANCH IAN CRASHED ON, NAMED. Everything above is a population; this is
# the case, asserted by itself so that a reader can see it pass. The branch
# must reach a column page THROUGH the example-data offer -- reaching the
# offer and stopping is not the claim.
w2_state <- val("w_within_two", "state", "")
w2_trail <- val("w_within_two", "trail", "")
check_true(V,
           sprintf("Compare / within-subject / two conditions survives the empty state (%s)",
                   if (nzchar(w2_state)) w2_state else "not driven"),
           identical(w2_state, "example") &&
           grepl("No table selected", w2_trail, fixed = TRUE) &&
           grepl("Select columns", w2_trail, fixed = TRUE))

# ---------------------------------------------------------------------------
# 8. EVERYTHING THE DRIVER RECORDED IS LOOKED AT BY SOMETHING
# ---------------------------------------------------------------------------
# `present` is every leg the ARTEFACT names; `accounted` is every leg that
# reached the outcome assertion in section 5 -- built from the state vector
# rather than from `walked`, so a leg with rows but no `state` key is an
# orphan here rather than a silent pass.
eml_census(V, "cold-start leg",
           present   = walked,
           accounted = names(state_of)[!is.na(state_of)])
eml_claim(V, "coldstart", walked)

# ---------------------------------------------------------------------------
# DEFECTS FOUND IN THE DRIVER WHILE BUILDING THIS, and fixed in run.sh on
# 24 August 2026. Recorded here because the artefact this file reads is only
# as good as the rig that wrote it, and all three produced CONFIDENT WRONG
# VERDICTS rather than visible failures:
#
#   1. The ping that proves the instance is alive was KILLING IT. `praat
#      --send` raises SIGUSR1 at the pid in its message file, and Praat
#      installs that handler late in start-up; SIGUSR1's default disposition
#      terminates the process. With the instance dead the sender then ran the
#      script itself and wrote the ping file, so the health gate recorded
#      `listening 1` about a corpse. Measured 2 of 3 trials. Fixed by waiting
#      for the Objects window and by requiring the instance we started to
#      still be alive.
#   2. The Objects/Info probe's output was discarded unread. Praat writes
#      UTF-16BE whenever one character falls outside ASCII, and what the probe
#      returns is the plugin's own prose, em dashes included -- so `sed` could
#      not match its section marker and both halves came back empty. The three
#      recorder legs were recorded as `exited` while the probe was
#      successfully returning their banner. Fixed by decoding first.
#   3. Display numbers were computed as :80 + leg index, giving :81..:115 for
#      a 35-leg population -- a range CONTAINING the displays other rigs in
#      this tree use -- and the stale-lock cleanup removed the lock and socket
#      unconditionally. A leg landing on a neighbour's display would have
#      deleted its socket mid-run. Caught with harness/axisrefuse live on :86
#      and leg 6 about to take it. Fixed by claiming displays that have no
#      live server.
# ---------------------------------------------------------------------------

if (!exists("EML_SUITE")) { eml_report("v111 -- the cold-start census"); eml_exit() }
