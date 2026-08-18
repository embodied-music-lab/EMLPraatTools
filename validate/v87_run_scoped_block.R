# ============================================================================
# v87_run_scoped_block.R -- the editable block names its variables by RUN
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULING THIS FILE IMPLEMENTS (author, 17 August 2026):
#
#     "GUI run number two has no knowledge of run number one. The recorder
#      should separate all variables by run number. So even if a field exists
#      in the second run and not the first run, that variable would still end
#      in two."
#
# THE SUFFIX IS THE RUN NUMBER. Not a first-use counter, not a count of
# distinct values, and nothing anywhere compares two literals to decide a
# name. Run 1's variables are unsuffixed, run 2's end in 2, run 3's in 3:
#
#     run 1   data1$   valueCol$    groupCol$    axisYMin    figureFormat$
#     run 2   data2$   valueCol2$   groupCol2$   axisYMin2   figureFormat2$
#
# A RUN is one pass through a GUI form and the save that belongs to it. A
# draw step and the save that follows it are ONE run; a second press of Draw
# or of New is a second run even though it stays inside the same script scope,
# which is why the boundary is a call the form makes rather than something
# read off the buffer's step kinds.
#
# WHY A NEW VALIDATOR AND NOT MORE OF v58. v58's subject is REPLAY FIDELITY:
# a recorded workflow must run headless and come back as the same figure and
# the same files. This file's subject is the NAMING LAW of the block above
# those steps -- which run each variable belongs to -- and it needs sessions
# whose run structure is DECLARED BY THE DRIVER (two passes on two tables,
# three passes, a pass that saves twice) that harness/record does not contain
# and has no reason to. The two do meet at one point and it is deliberate:
# both replay figures byte for byte. v58 replays to prove a figure survives;
# this file replays to prove the naming is LOAD-BEARING -- change one line of
# run 2's block and run 2 moves and run 1 does not.
#
# WHAT IT READS: harness/runblock/out, driven by harness/runblock/run.sh.
#
# ---------------------------------------------------------------------------
# THE SIX THINGS PINNED, AND WHAT A DEFECTIVE TREE WOULD HAVE TO LOOK LIKE TO
# STILL PASS EACH ONE. Written out because this project has been bitten by
# checks that could not fail: a count with a floor, a presence test where the
# value was the point, an assertion a broken tree could still satisfy.
#
#   1. THE LAW, RESTATED OVER THE ARTEFACT ALONE (`suffix is the run`).
#      Every declaration in every block is split into a base and an ending,
#      its run is read out of its own trailing comment, and the ending is
#      required to be exactly what the law says for that run. Nothing in this
#      check consults the expectation table below, so it is a statement about
#      whatever the tree emitted rather than a comparison with a list.
#      TO PASS WHILE BROKEN a tree would have to mis-name a variable AND
#      mis-state the run in the same variable's comment, in the same
#      direction -- at which point the block is internally consistent and the
#      defect is caught by check 2, which knows what the runs actually were.
#
#   2. THE BLOCK IS EXACTLY THIS SET (`census`). Every expected declaration
#      -- name, literal and run -- must be present, and every declaration
#      present must be expected. The expected side is written from the
#      RULING and from what the driver did, not from what the tree emitted.
#      TO PASS WHILE BROKEN a tree would have to emit the right names with
#      the right literals against the right runs, which is the feature.
#      Duplication cannot help it: the check is set equality both ways, so an
#      extra variable fails as loudly as a missing one.
#
#   3. NO STEP READS ANOTHER RUN'S VARIABLES (`step scoping`). Each step's
#      body is tokenised, every declared variable it mentions is looked up,
#      and its run must be the run that step belongs to -- where the step's
#      run comes from the DRIVER, which called @emlRecordNewRun at exactly
#      the points a form would. Each step must also mention at least one
#      declared variable, so a step that lifted nothing cannot pass by being
#      empty.
#      TO PASS WHILE BROKEN a tree would have to keep two runs' slots
#      separate in the steps while merging them in the block, which is the
#      reverse of every defect this replaces.
#
#   4. THE ORDINARY ONE-PASS SESSION IS UNCHANGED (`HEAD baseline`). The same
#      session -- one draw and the save that belongs to it -- is driven twice,
#      once against the tree under test and once against a plugin built by
#      `git archive HEAD`, and the two blocks must be character-identical
#      once the literal "run 1, " is removed and the two trees' own paths are
#      normalised. Alignment padding is part of the comparison.
#      TO PASS WHILE BROKEN a tree would have to leave the single-run block
#      alone, which is exactly what is being asserted. The baseline cannot be
#      redirected by the break rig's EML_RUNBLOCK_SRC, so a sabotage damages
#      one side of this comparison and not the other.
#
#   5. THE EDIT MOVES ONE RUN (`retarget` and `axis edit`). One line of the
#      block is changed -- data2$ in `sametable`, run 1's axisYMax in
#      `axisedit` -- and the figures are re-drawn. The run that was edited
#      must land on an INDEPENDENTLY DRAWN reference, and the run that was
#      not must be byte-identical to what it was. Both directions are
#      required, so "nothing moved" fails as surely as "everything moved".
#      TO PASS WHILE BROKEN the tree would have to give the two runs separate
#      variables. In `axisedit` the two runs were drawn on the SAME typed
#      axis literals, which is precisely the case the old (role, literal) key
#      collapsed.
#
#   6. THE FIGURES AND THE SAVES COME BACK (`replay`). Every draw step is
#      replayed alone into a 300-dpi PNG and compared with `cmp` against the
#      PNG the recording drew -- byte for byte, no threshold. Every save is
#      replayed with its own run and the extensions it wrote are censused, so
#      a save that replayed another save's format choice is visible as a file
#      set rather than as a line of text.
#      TO PASS WHILE BROKEN nothing: a replay that aborts writes no PNG and
#      the comparison reports MISSING, which is not IDENTICAL.
#
# EVERY CASE THE DRIVER RECORDED IS ACCOUNTED FOR by eml_census at the end,
# so a case added to the harness and forgotten here fails rather than passing
# silently.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".",
                     "helpers.R"))
}

OUT <- Sys.getenv("EML_RUNBLOCK_DIR", unset = repo_path("harness", "runblock",
                                                        "out"))
V <- "v87"

# ---------------------------------------------------------------------------
# THE DRIVEN TRANSCRIPT
# ---------------------------------------------------------------------------
tsv_path <- file.path(OUT, "RUNBLOCK.tsv")
have_tsv <- check_true(V, sprintf("the driven transcript exists (%s)",
                                  basename(tsv_path)), file.exists(tsv_path))
if (!have_tsv) {
    eml_report("v87 -- the editable block names its variables by run")
    eml_exit()
    quit(status = 1)
}
TR <- read.delim(tsv_path, stringsAsFactors = FALSE, quote = "")

trv <- function(case, key, default = NA_character_) {
    hit <- TR$value[TR$case == case & TR$key == key]
    if (!length(hit)) default else as.character(hit[1])
}

# ---------------------------------------------------------------------------
# WHAT THE DRIVER DID. This is the ground truth for "which run is this step",
# and it is ground truth because harness/runblock/cases/<case>/body.praat
# marks its boundaries with @emlRecordNewRun at exactly the points a GUI form
# would -- one pass, then the next. It is NOT read back out of the artefact,
# or the artefact could not disagree with it.
# ---------------------------------------------------------------------------
STEP_RUN <- list(
    twotables = c(`1` = 1, `2` = 2),
    onlyrun2  = c(`1` = 1, `2` = 2),
    three     = c(`1` = 1, `2` = 2, `3` = 3),
    single    = c(`1` = 1, `2` = 1),
    sametable = c(`1` = 1, `2` = 2),
    twosaves  = c(`1` = 1, `2` = 1, `3` = 1),
    saveruns  = c(`1` = 1, `2` = 1, `3` = 2, `4` = 2),
    axisedit  = c(`1` = 1, `2` = 2),
    callsite  = c(`1` = 1, `2` = 2)
)
STEP_KIND <- list(
    twotables = c("draw", "draw"),
    onlyrun2  = c("draw", "draw"),
    three     = c("draw", "draw", "draw"),
    single    = c("draw", "save"),
    sametable = c("draw", "draw"),
    twosaves  = c("draw", "save", "save"),
    saveruns  = c("draw", "save", "draw", "save"),
    axisedit  = c("draw", "draw"),
    callsite  = c("draw", "draw")
)

# ---------------------------------------------------------------------------
# WHAT THE BLOCK MUST SAY. The NAMES and the RUNS come from the ruling applied
# to what the driver did; the LITERALS are the fixtures' own column names and
# axis arguments. Written as one row per declaration so that the comparison
# below can be set equality in both directions.
# ---------------------------------------------------------------------------
d <- function(case, name, value, run) data.frame(case = case, name = name,
    value = value, run = run, stringsAsFactors = FALSE)

EXPECT <- do.call(rbind, list(
    # --- two runs, two tables, and the column name "n" in both of them ----
    # The defect being removed: the old key was (role, literal), so one
    # valueCol$ governed a column called "n" in two different tables.
    d("twotables", "data1$",     "Table cityA", 1),
    d("twotables", "data2$",     "Table cityB", 2),
    d("twotables", "groupCol$",  "site",        1),
    d("twotables", "valueCol$",  "n",           1),
    d("twotables", "groupCol2$", "ward",        2),
    d("twotables", "valueCol2$", "n",           2),
    d("twotables", "axisYMin",   "0.0",         1),
    d("twotables", "axisYMin2",  "0.0",         2),

    # --- a run that uses roles the run before it never had ---------------
    # xCol and yCol are FIRST OF THEIR ROLE in the file and still carry the
    # 2, because the suffix says which pass they belong to.
    d("onlyrun2", "data1$",     "Table box", 1),
    d("onlyrun2", "data2$",     "Table sc",  2),
    d("onlyrun2", "groupCol$",  "grp",       1),
    d("onlyrun2", "valueCol$",  "val",       1),
    d("onlyrun2", "xCol2$",     "xx",        2),
    d("onlyrun2", "yCol2$",     "yy",        2),
    d("onlyrun2", "groupCol2$", "cohort",    2),
    d("onlyrun2", "axisYMin",   "0.0",       1),
    d("onlyrun2", "axisYMin2",  "0.0",       2),

    # --- three runs: the numbering continues, it does not toggle ---------
    d("three", "data1$",     "Table t1", 1),
    d("three", "data2$",     "Table t2", 2),
    d("three", "data3$",     "Table t3", 3),
    d("three", "groupCol$",  "site",     1),
    d("three", "valueCol$",  "n",        1),
    d("three", "groupCol2$", "ward",     2),
    d("three", "valueCol2$", "n",        2),
    d("three", "groupCol3$", "block",    3),
    d("three", "valueCol3$", "n",        3),
    d("three", "axisYMin",   "0.0",      1),
    d("three", "axisYMin2",  "0.0",      2),
    d("three", "axisYMin3",  "2",        3),

    # --- one pass: a draw and the save that belongs to it ----------------
    # ONE run, so nothing is suffixed. Compared against HEAD further down.
    d("single", "data1$",        "Table vt", 1),
    d("single", "groupCol$",     "grp",      1),
    d("single", "valueCol$",     "val",      1),
    d("single", "axisYMin",      "0.0",      1),
    d("single", "figureFormat$", "PNG, EPS", 1),

    # --- two runs on ONE table -------------------------------------------
    # data1$ and data2$ both read "Table one". That is the point: the
    # retarget leg edits data2$ and only run 2 moves.
    d("sametable", "data1$",     "Table one", 1),
    d("sametable", "data2$",     "Table one", 2),
    d("sametable", "groupCol$",  "grp",       1),
    d("sametable", "valueCol$",  "val",       1),
    d("sametable", "groupCol2$", "grp",       2),
    d("sametable", "valueCol2$", "other",     2),
    d("sametable", "axisYMin",   "0.0",       1),
    d("sametable", "axisYMin2",  "0.0",       2),

    # --- one pass, two saves, two format answers -------------------------
    # The run has no second number to give, so the second answer is the run
    # number and a letter. Both are run 1.
    d("twosaves", "data1$",          "Table vt", 1),
    d("twosaves", "groupCol$",       "grp",      1),
    d("twosaves", "valueCol$",       "val",      1),
    d("twosaves", "axisYMin",        "0.0",      1),
    d("twosaves", "figureFormat$",   "PNG",      1),
    d("twosaves", "figureFormat1b$", "PNG, PDF", 1),

    # --- two runs that each save, with different formats -----------------
    d("saveruns", "data1$",         "Table sa", 1),
    d("saveruns", "data2$",         "Table sb", 2),
    d("saveruns", "groupCol$",      "grp",      1),
    d("saveruns", "valueCol$",      "val",      1),
    d("saveruns", "groupCol2$",     "grp",      2),
    d("saveruns", "valueCol2$",     "val",      2),
    d("saveruns", "axisYMin",       "0.0",      1),
    d("saveruns", "axisYMin2",      "0.0",      2),
    d("saveruns", "figureFormat$",  "PNG",      1),
    d("saveruns", "figureFormat2$", "PNG, PDF", 2),

    # --- two runs drawn on the SAME typed axis literals ------------------
    # (role, literal) made these one pair. They are two, and the edit leg is
    # what proves it.
    d("axisedit", "data1$",     "Table ax1", 1),
    d("axisedit", "data2$",     "Table ax2", 2),
    d("axisedit", "groupCol$",  "grp",       1),
    d("axisedit", "valueCol$",  "val",       1),
    d("axisedit", "groupCol2$", "grp",       2),
    d("axisedit", "valueCol2$", "val",       2),
    d("axisedit", "axisYMin",   "2",         1),
    d("axisedit", "axisYMin2",  "2",         2),

    # --- the boundary the PLUGIN draws, not the one the driver draws -----
    # This case never calls @emlRecordNewRun. It calls the procedure a menu
    # wrapper runs once per press of Run, twice inside one script scope --
    # a wrapper's `New` button -- and requires two runs to come out of it.
    # Every other case would still pass if the shipped call sites had been
    # left out altogether.
    d("callsite", "data1$",     "Table cityA", 1),
    d("callsite", "data2$",     "Table cityB", 2),
    d("callsite", "groupCol$",  "site",        1),
    d("callsite", "valueCol$",  "n",           1),
    d("callsite", "groupCol2$", "ward",        2),
    d("callsite", "valueCol2$", "n",           2),
    d("callsite", "axisYMin",   "0.0",         1),
    d("callsite", "axisYMin2",  "0.0",         2)
))

# ---------------------------------------------------------------------------
# THE PAGE, ONE SET PER RUN THAT DREW.
#
# "Erase page first" and the panel origin are not arguments of any draw
# procedure -- they are globals the graphs form sets and @emlBeginPanel acts
# on -- so the recorder writes them in front of the draw call and the block
# lifts them by NAME rather than by argument position. Everything after that
# is the rule every other declaration follows: one variable per role per run,
# unsuffixed in run 1.
#
# DERIVED FROM STEP_KIND RATHER THAN TYPED OUT, and that is the point of
# deriving it: the claim being made is "every run that drew has these three
# and no run that only saved has any of them". Typing thirty rows would state
# the same thing in a form where a wrong one reads exactly like a right one.
# STEP_KIND and STEP_RUN are the driver's own account of what each case did,
# and they are already pinned above.
#
# THE VALUES ARE THE DEFAULTS BECAUSE THESE CASES ARE NOT COMPOSITES: every
# runblock fixture draws one figure per pass on a fresh page. That the block
# declares them anyway is the assertion -- a step is only self-contained if it
# states the settings it did not use, or the second figure in a replayed
# script inherits the first one's origin.
EXPECT <- rbind(EXPECT, do.call(rbind, lapply(names(STEP_KIND), function(cs) {
    runs <- sort(unique(STEP_RUN[[cs]][STEP_KIND[[cs]] == "draw"]))
    do.call(rbind, lapply(runs, function(r) {
        sfx <- if (r == 1L) "" else as.character(r)
        rbind(d(cs, paste0("eraseFirst", sfx),   "1", r),
              d(cs, paste0("panelOriginX", sfx), "0", r),
              d(cs, paste0("panelOriginY", sfx), "0", r))
    }))
})))

# ---------------------------------------------------------------------------
# THE CEILING OF EACH AXIS PAIR AND THE NOTE UNDER IT. The maximum is declared
# on its own line whose comment carries no run: it is the continuation of the
# minimum above it, and it is where the pair says what the figure ACTUALLY
# came out at. That note is the reason the pair has to be per run -- a shared
# pair can only quote one run's numbers, and quotes them at the other run's
# figure.
# ---------------------------------------------------------------------------
a <- function(case, name, value, note) data.frame(case = case, name = name,
    value = value, note = note, stringsAsFactors = FALSE)
RES <- "on the recorded data it resolved to "
DRW <- "the figure was drawn on "
EXPECT_MAX <- do.call(rbind, list(
    a("twotables", "axisYMax",  "0.0", paste0(RES, "3.5000 .. 7.0000")),
    a("twotables", "axisYMax2", "0.0", paste0(RES, "9.5000 .. 14.0000")),
    a("onlyrun2",  "axisYMax",  "0.0", paste0(RES, "4.0000 .. 7.0000")),
    a("onlyrun2",  "axisYMax2", "0.0", paste0(RES, "10.0000 .. 40.0000")),
    a("three",     "axisYMax",  "0.0", paste0(RES, "2.5000 .. 5.5000")),
    a("three",     "axisYMax2", "0.0", paste0(RES, "10.0000 .. 14.0000")),
    a("three",     "axisYMax3", "30",  paste0(DRW, "2.0000 .. 30.0000")),
    a("single",    "axisYMax",  "0.0", paste0(RES, "5.5000 .. 9.0000")),
    a("sametable", "axisYMax",  "0.0", paste0(RES, "5.5000 .. 9.0000")),
    a("sametable", "axisYMax2", "0.0", paste0(RES, "13.0000 .. 18.5000")),
    a("twosaves",  "axisYMax",  "0.0", paste0(RES, "5.5000 .. 9.0000")),
    a("saveruns",  "axisYMax",  "0.0", paste0(RES, "5.5000 .. 9.0000")),
    a("saveruns",  "axisYMax2", "0.0", paste0(RES, "15.5000 .. 19.0000")),
    a("axisedit",  "axisYMax",  "30",  paste0(DRW, "2.0000 .. 30.0000")),
    a("axisedit",  "axisYMax2", "30",  paste0(DRW, "2.0000 .. 30.0000")),
    a("callsite",  "axisYMax",  "0.0", paste0(RES, "3.5000 .. 7.0000")),
    a("callsite",  "axisYMax2", "0.0", paste0(RES, "9.5000 .. 14.0000"))
))

CASES <- names(STEP_RUN)

# ---------------------------------------------------------------------------
# PARSING AN EMITTED SCRIPT.
#
# The block is everything above the first step heading; each heading to the
# next is a step. A declaration is `name = value   ; comment`, and a
# declaration is RUN-BEARING when its comment names a run. The axis maximum
# is the one line that is not: it continues the minimum above it.
# ---------------------------------------------------------------------------
parse_emitted <- function(path) {
    if (!file.exists(path)) return(NULL)
    ln <- readLines(path, warn = FALSE)
    hd <- grep("^# --- Step [0-9]+ \\(", ln)
    block <- if (length(hd)) ln[seq_len(hd[1] - 1L)] else ln
    steps <- list()
    if (length(hd)) {
        b <- c(hd, length(ln) + 1L)
        for (i in seq_len(length(hd))) {
            n <- sub("^# --- Step ([0-9]+) .*$", "\\1", ln[b[i]])
            k <- sub("^# --- Step [0-9]+ \\(([a-z]+)\\).*$", "\\1", ln[b[i]])
            steps[[n]] <- list(kind = k, body = ln[b[i]:(b[i + 1L] - 1L)])
        }
    }
    dec <- grep("^[A-Za-z][A-Za-z0-9]*\\$? *= .*   ; ", block, value = TRUE)
    nm  <- sub("^([A-Za-z][A-Za-z0-9]*\\$?) *= .*$", "\\1", dec)
    val <- sub("^[A-Za-z][A-Za-z0-9]*\\$? *= (.*)   ; .*$", "\\1", dec)
    val <- sub('^"(.*)"$', "\\1", val)
    com <- sub("^.*   ; ", "", dec)
    run <- rep(NA_integer_, length(dec))
    hit <- grepl("run [0-9]+,", com)
    run[hit] <- as.integer(sub("^.*run ([0-9]+),.*$", "\\1", com[hit]))
    list(block = block, steps = steps,
         dec = data.frame(name = nm, value = val, comment = com, run = run,
                          line = dec, stringsAsFactors = FALSE))
}

# THE LAW ITSELF, WRITTEN ONCE. `.already` is how many variables of the same
# base the same run has already declared.
run_number <- function(run, already) {
    if (already <= 0) return(as.character(run))
    letter <- if (already <= 25) substr("bcdefghijklmnopqrstuvwxyz",
                                        already, already) else
              paste0("_", already + 1L)
    paste0(run, letter)
}
run_suffix <- function(run, already) {
    if (run == 1 && already == 0) "" else run_number(run, already)
}

EM <- list()
for (cs in CASES) EM[[cs]] <- parse_emitted(file.path(OUT, cs,
                                                      "emitted.praat"))

# ---------------------------------------------------------------------------
# 0a. THE ARTEFACTS DESCRIBE THE RECORDER THAT IS IN THIS TREE
#
# Every block below is a committed file, and a committed file goes on saying
# what it said after the code stops doing it -- which is how a suite ends up
# green over a defect nobody re-drove. run.sh writes the fingerprint of the
# WORKING TREE's eml-record.praat into the transcript; here it is recomputed
# from the file itself. Edit the recorder without re-driving and this check
# fails rather than the rest of the file passing on yesterday's answer.
#
# It is the working tree's copy on both sides on purpose: harness/runblock/
# break.sh damages a COPY, so a break shows up as the naming failing and
# never as a stale rig.
# ---------------------------------------------------------------------------
# Base R has no SHA-256 and the suite installs no packages, so the fingerprint
# is taken with the same program the harness used -- the comparison is between
# two runs of sha256sum rather than between two implementations of a hash.
rec_src <- repo_path("plugin", "stats", "eml-record.praat")
live_sha <- tryCatch(substr(system2("sha256sum", shQuote(rec_src),
                                    stdout = TRUE)[1], 1, 16),
                     error = function(e) "")
check_true(V,
    sprintf("the blocks were driven against this tree's recorder (%s)",
            substr(live_sha, 1, 12)),
    nzchar(live_sha) && identical(trv("meta", "record_sha"), live_sha))

# ---------------------------------------------------------------------------
# 0b. THE TWO BOUNDARY CALL SITES THAT CANNOT BE DRIVEN HEADLESS
#
# `callsite` drives the wrapper boundary -- @emlHandleCommonFields, twice in
# one scope -- so that one is measured. The graphs form's and the wizard's
# pass loops both need dialogs, and a dialog does not return without a
# display, so those two are read off the source instead and the reading is
# labelled as such.
#
# WHAT IS ASSERTED IS NOT PRESENCE. A call to @emlRecordNewRun that sits
# OUTSIDE the pass loop is the exact defect this would have to catch -- it
# would mark the first pass and no other, and every emitted block would come
# back as one run. So the line number of the call is required to fall between
# the loop's own opening and closing lines. A call moved above the loop, or
# deleted, fails; a call anywhere inside it passes, which is the property
# that matters and the only one source can settle.
# ---------------------------------------------------------------------------
PLUGSRC <- Sys.getenv("EML_RUNBLOCK_PLUGIN", unset = repo_path("plugin"))
in_loop <- function(file, open_re, close_re, label) {
    p <- file.path(PLUGSRC, file)
    ln <- if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
    o <- grep(open_re, ln)
    cl <- grep(close_re, ln)
    call <- grep("^\\s*@emlRecordNewRun\\s*$", ln)
    ok <- length(o) == 1L && length(cl) == 1L && length(call) == 1L &&
          call > o && call < cl
    check_true(V, sprintf("%s: the boundary is inside the pass loop (%s)",
                          label,
                          if (ok) sprintf("%d < %d < %d", o[1], call[1], cl[1])
                          else "not one call between one loop"),
               ok)
}
in_loop("graphs/eml-graphs-form.praat", "^repeat$", "^until keepGoing = 0$",
        "the graphs form")
in_loop("scripts/eml-wizard.praat", "^while runAgain = 1$", "^endwhile$",
        "the wizard")

# ---------------------------------------------------------------------------
# 0. THE SESSIONS WERE RECORDED AND REPLAYED WITHOUT AN ABORT
# ---------------------------------------------------------------------------
for (cs in CASES) {
    check_true(V, sprintf("%s: the session recorded a script", cs),
               identical(trv(cs, "recorded"), "1") && !is.null(EM[[cs]]))
    check_true(V, sprintf("%s: nothing aborted while recording", cs),
               identical(trv(cs, "record_aborts"), "0"))
    check_true(V, sprintf("%s: nothing aborted while replaying", cs),
               identical(trv(cs, "replay_aborts"), "0"))
    kinds <- STEP_KIND[[cs]]
    got <- vapply(seq_along(kinds),
                  function(i) trv(cs, sprintf("step%d_kind", i)), "")
    check_true(V, sprintf("%s: it emitted %d steps, %s", cs, length(kinds),
                          paste(kinds, collapse = "/")),
               identical(got, kinds) &&
               is.na(trv(cs, sprintf("step%d_kind", length(kinds) + 1L))) &&
               !is.null(EM[[cs]]) && length(EM[[cs]]$steps) == length(kinds))
}

# ---------------------------------------------------------------------------
# 1. THE SUFFIX IS THE RUN NUMBER -- read off the artefact, nothing else
#
# Split each declared name into base and ending, count how many of that base
# the same run has already declared, and require the ending the law gives.
# `data` is the one base spelled with its number even in run 1, because
# data1$ has always been spelled that way; every other base is bare in run 1.
# ---------------------------------------------------------------------------
for (cs in CASES) {
    D <- EM[[cs]]$dec
    if (is.null(D)) next
    D <- D[!is.na(D$run), , drop = FALSE]
    bare <- sub("\\$$", "", D$name)
    base <- sub("[0-9]+[a-z]?$", "", bare)
    sigil <- ifelse(grepl("\\$$", D$name), "$", "")
    seen <- list()
    ok <- rep(TRUE, nrow(D))
    want <- character(nrow(D))
    for (i in seq_len(nrow(D))) {
        key <- paste0(base[i], "|", D$run[i])
        already <- if (is.null(seen[[key]])) 0L else seen[[key]]
        seen[[key]] <- already + 1L
        end <- if (base[i] == "data") run_number(D$run[i], already) else
                                      run_suffix(D$run[i], already)
        want[i] <- paste0(base[i], end, sigil[i])
        ok[i] <- identical(want[i], D$name[i])
    }
    check_true(V, sprintf("%s: every name ends in its own run (%d decl.)",
                          cs, nrow(D)),
               nrow(D) > 0 && all(ok))
    if (!all(ok)) {
        cat(sprintf("  %s: named %s, the run in its comment wants %s\n",
                    cs, D$name[!ok], want[!ok]))
    }
}

# ---------------------------------------------------------------------------
# 2. THE BLOCK IS EXACTLY THE EXPECTED SET, BOTH WAYS
# ---------------------------------------------------------------------------
for (cs in CASES) {
    D <- EM[[cs]]$dec
    E <- EXPECT[EXPECT$case == cs, , drop = FALSE]
    Dr <- if (is.null(D)) D else D[!is.na(D$run), , drop = FALSE]
    for (i in seq_len(nrow(E))) {
        hit <- if (is.null(Dr)) integer(0) else which(Dr$name == E$name[i])
        check_true(V, sprintf("%s: %s = \"%s\", run %d", cs, E$name[i],
                              E$value[i], E$run[i]),
                   length(hit) == 1L &&
                   identical(Dr$value[hit], E$value[i]) &&
                   isTRUE(Dr$run[hit] == E$run[i]))
    }
    extra <- if (is.null(Dr)) character(0) else setdiff(Dr$name, E$name)
    check_true(V, sprintf("%s: the block declares nothing else (%d run-bearing)",
                          cs, if (is.null(Dr)) 0L else nrow(Dr)),
               length(extra) == 0L)
    if (length(extra)) cat(sprintf("  %s: unexpected declaration %s\n", cs,
                                   extra))

    # The axis ceilings and the note each one carries.
    A <- EXPECT_MAX[EXPECT_MAX$case == cs, , drop = FALSE]
    maxdec <- if (is.null(D)) D else D[grepl("^axisYMax", D$name), ,
                                       drop = FALSE]
    for (i in seq_len(nrow(A))) {
        hit <- if (is.null(maxdec)) integer(0) else
               which(maxdec$name == A$name[i])
        check_true(V, sprintf("%s: %s = %s, note \"%s\"", cs, A$name[i],
                              A$value[i], A$note[i]),
                   length(hit) == 1L &&
                   identical(maxdec$value[hit], A$value[i]) &&
                   identical(maxdec$comment[hit], A$note[i]))
    }
    check_true(V, sprintf("%s: %d axis ceiling(s) and no more", cs, nrow(A)),
               !is.null(maxdec) && nrow(maxdec) == nrow(A))
}

# ---------------------------------------------------------------------------
# 3. EVERY STEP READS ONLY ITS OWN RUN'S VARIABLES
#
# The step's run comes from the DRIVER. Two things are required of every
# step: no variable it mentions belongs to another run, and it mentions at
# least one -- a step that lifted nothing would otherwise pass by silence.
# The declaration comments are checked the same way: a variable that claims
# to govern a step in another run is the same defect seen from the block.
# ---------------------------------------------------------------------------
for (cs in CASES) {
    E <- EM[[cs]]
    if (is.null(E)) next
    D <- E$dec
    # The ceiling line inherits the run of the minimum above it.
    runof <- setNames(D$run, D$name)
    for (i in seq_along(runof)) {
        if (is.na(runof[i]) && i > 1L) runof[i] <- runof[i - 1L]
    }
    want <- STEP_RUN[[cs]]
    for (sn in names(want)) {
        st <- E$steps[[sn]]
        if (is.null(st)) { check_true(V, sprintf("%s: step %s exists", cs, sn),
                                      FALSE); next }
        code <- st$body[!grepl("^\\s*#", st$body)]
        tok <- unlist(regmatches(code,
            gregexpr("[A-Za-z][A-Za-z0-9]*\\$?", code)))
        used <- intersect(unique(tok), names(runof))
        foreign <- used[runof[used] != want[[sn]]]
        check_true(V, sprintf("%s: step %s (run %d) reads only run %d (%s)",
                              cs, sn, want[[sn]], want[[sn]],
                              paste(used, collapse = " ")),
                   length(used) > 0L && length(foreign) == 0L)
        if (length(foreign)) {
            cat(sprintf("  %s: step %s is run %d and reads %s (run %d)\n",
                        cs, sn, want[[sn]], foreign, runof[foreign]))
        }
    }
    # The steps a declaration says it governs must all be in its own run.
    Dr <- D[!is.na(D$run), , drop = FALSE]
    bad <- character(0)
    for (i in seq_len(nrow(Dr))) {
        ss <- unlist(regmatches(Dr$comment[i],
            gregexpr("(?<=step )[0-9]+|(?<=steps )[0-9]+|(?<=, )[0-9]+(?= \\()",
                     Dr$comment[i], perl = TRUE)))
        ss <- ss[ss %in% names(want)]
        if (length(ss) && any(want[ss] != Dr$run[i])) bad <- c(bad, Dr$name[i])
    }
    check_true(V, sprintf("%s: no declaration governs another run's steps", cs),
               length(bad) == 0L)
    if (length(bad)) cat(sprintf("  %s: %s spans runs\n", cs, bad))
}

# ---------------------------------------------------------------------------
# 4. THE ORDINARY ONE-PASS SESSION IS UNCHANGED FROM HEAD
#
# The two blocks are compared as text, padding included, after removing the
# one thing the ruling adds -- the words "run 1, " -- and after normalising
# the two trees' own paths, which differ because they ARE two trees.
# ---------------------------------------------------------------------------
norm_block <- function(path) {
    if (!file.exists(path)) return(NULL)
    ln <- readLines(path, warn = FALSE)
    a <- grep("^# Name your data objects", ln)
    b <- grep("^# \\(Titles and axis labels", ln)
    if (!length(a) || !length(b)) return(NULL)
    seg <- ln[a[1]:(b[1] - 1L)]
    seg <- sub("run 1, step", "step", seg, fixed = TRUE)
    seg
}
new_blk  <- norm_block(file.path(OUT, "single", "emitted.praat"))
head_blk <- norm_block(file.path(OUT, "head_single", "emitted.praat"))
check_true(V, "the HEAD baseline built and recorded its own block",
           identical(trv("head_single", "recorded"), "1") &&
           !is.null(head_blk) &&
           sum(grepl("   ; ", head_blk)) >= 5L)
check_true(V,
    sprintf("single-run block is character-identical to HEAD's (%d lines)",
            if (is.null(new_blk)) 0L else length(new_blk)),
    !is.null(new_blk) && !is.null(head_blk) && identical(new_blk, head_blk))
if (!is.null(new_blk) && !is.null(head_blk) && !identical(new_blk, head_blk)) {
    cat("  HEAD : ", setdiff(head_blk, new_blk), "\n", sep = "\n  ")
    cat("  now  : ", setdiff(new_blk, head_blk), "\n", sep = "\n  ")
}

# ---------------------------------------------------------------------------
# 5. THE EDIT MOVES ONE RUN AND ONE RUN ONLY
# ---------------------------------------------------------------------------
check_true(V, "sametable: the retarget changed exactly one line of the block",
           identical(trv("sametable", "edit_lines_changed"), "1"))
check_true(V, "sametable: run 1 is untouched by the edit to data2$",
           identical(trv("sametable", "edit_run1_vs_orig"), "IDENTICAL"))
check_true(V, "sametable: run 2 is no longer the figure it was",
           identical(trv("sametable", "edit_run2_vs_orig"), "DIFFERS"))
check_true(V, "sametable: run 2 lands on the twin table's own reference",
           identical(trv("sametable", "edit_run2_vs_twin"), "IDENTICAL"))
check_true(V, "sametable: the edited block replayed without an abort",
           identical(trv("sametable", "edit_aborts"), "0"))

check_true(V, "axisedit: the axis edit changed exactly one line of the block",
           identical(trv("axisedit", "edit_lines_changed"), "1"))
check_true(V, "axisedit: run 1 moved when its own ceiling was raised",
           identical(trv("axisedit", "edit_run1_vs_orig"), "DIFFERS"))
check_true(V, "axisedit: run 1 lands on the 2 .. 60 reference",
           identical(trv("axisedit", "edit_run1_vs_wide"), "IDENTICAL"))
check_true(V, "axisedit: run 2 stayed where it was drawn, on the same literals",
           identical(trv("axisedit", "edit_run2_vs_orig"), "IDENTICAL"))
check_true(V, "axisedit: the edited block replayed without an abort",
           identical(trv("axisedit", "edit_aborts"), "0"))

# ---------------------------------------------------------------------------
# 6. THE FIGURES REPLAY BYTE FOR BYTE, AND EACH SAVE WRITES ITS OWN FORMATS
# ---------------------------------------------------------------------------
for (cs in CASES) {
    kinds <- STEP_KIND[[cs]]
    for (i in seq_along(kinds)) {
        if (kinds[i] != "draw") next
        check_true(V, sprintf("%s: step %d replays byte-for-byte", cs, i),
                   identical(trv(cs, sprintf("step%d_replay", i)),
                             "IDENTICAL"))
    }
}
SAVED <- list(
    c("single",   "saved_exts",  "eps,png,txt"),
    c("twosaves", "saved1_exts", "png,txt"),
    c("twosaves", "saved2_exts", "pdf,png,txt"),
    c("saveruns", "saved1_exts", "png,txt"),
    c("saveruns", "saved2_exts", "pdf,png,txt")
)
for (s in SAVED) {
    check_true(V, sprintf("%s: %s wrote %s and nothing else", s[1],
                          sub("_exts$", "", s[2]), s[3]),
               identical(trv(s[1], s[2]), s[3]))
}

# ---------------------------------------------------------------------------
# EVERY CASE THE DRIVER RECORDED IS ASSERTED ON
# ---------------------------------------------------------------------------
present <- setdiff(unique(TR$case), c("head_single", "meta"))
eml_census(V, "cases the runblock harness drove", present, CASES)

# THE GUARD IS NOT DECORATION. eml_exit() calls quit(status = 1) as soon as
# ANY check in the run has failed, so an unguarded call here is a no-op only
# while the whole suite is green and a hard stop the moment it is not. Under
# run_all.R that would end the run at this file -- silently, with a total that
# looks like a complete pass -- and take the scripts after it with it,
# coverage.R among them. The pass that finds green checks measuring nothing
# must not be the first thing a red suite switches off.
if (!exists("EML_SUITE")) {
    eml_report("v87 -- the editable block names its variables by run")
    eml_exit()
}
