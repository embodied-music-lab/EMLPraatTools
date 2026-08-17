#!/usr/bin/env Rscript
# ============================================================================
# evidence_census.R -- what each validator READS, and whether anything under
#                      test RAN, both derived from the validator's own source
#                      rather than from a list
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THIS FILE ASKS TWO QUESTIONS AND KEEPS THEM APART. The first is where the
# evidence came from; the second is whether anything under test executed. They
# were one question here until 17 August 2026, and collapsing them
# misclassified the healthiest validators in the suite. The correction, and
# why it is a correction rather than a refinement, is under THE TWO ROLES OF
# AN ARTEFACT below.
#
# WHY THIS EXISTS. A validator's evidence comes from one of three places, and
# which one it is decides what a green run is entitled to mean:
#
#   SOURCE     it reads the plugin's own source while it runs -- parses a
#              .praat, greps a literal out of it, resolves an include closure.
#              A green check means the CODE IN THIS TREE says so.
#   LIVE       it resolves a Praat binary and drives it inside the run. A green
#              check means the BINARY, given this tree, does so.
#   ARTEFACT   its only inputs are committed files under harness/ or evidence/
#              -- a captured Info window, a RESULTS.tsv, a rendered PNG. A
#              green check means THE FILE STILL SAYS WHAT IT SAID.
#
# Those are not three flavours of the same thing. The third is a statement
# about a file; the first two are statements about the plugin. A committed
# artefact is a WITNESS STATEMENT, NOT A LIVE WITNESS: it records what the
# plugin did on the day somebody drove it, and it goes on recording that
# after the plugin stops doing it. Nothing about reading the statement back
# tells you the witness would still say the same thing.
#
# THREE MEASUREMENTS, TAKEN INDEPENDENTLY, THAT ARE ALL THAT ONE FACT:
#
#   1. validate/tools/redrive_census.sh re-drove all 34 harnesses from source
#      into a scratch tree. Nine reproduced their committed artefacts. Fifteen
#      DIFFERED -- the committed file no longer describes the plugin -- and
#      several of the stale ones were what the suite was quoting to state
#      things about the plugin that had stopped being true.
#   2. validate/v29 asserts 144 renders that no commit in this repository's
#      history has ever been able to produce. The evidence was carried in from
#      elsewhere and the checks reading it were green throughout.
#   3. The findings-ledger backfill reverted plugin/ wholesale and ran 36
#      validators against the reverted tree. Eight rows' pinning validators
#      stayed GREEN under a full source revert. Every one of the eight was
#      pinned by a validator whose only input is a committed harness artefact.
#
# (1) and (3) are the same decoupling seen from opposite ends: the artefact
# drifting away from the code, and the check that reads it failing to notice a
# code change big enough to be a revert.
#
# ────────────────────────────────────────────────────────────────────────────
# THE TWO ROLES OF AN ARTEFACT, WHICH IS THE DISTINCTION THIS FILE WAS MISSING
#
# The question above -- "does this validator read an artefact" -- is not the
# question that decides anything. The question that decides is
#
#         DOES THE VALUE UNDER TEST COME FROM EXECUTION?
#
# They come apart because a committed file can be standing in either of two
# completely different places in a check:
#
#   ARTEFACT AS ORACLE. The validator REGENERATES THE SUBJECT FROM SOURCE
#   inside its own run, and compares what came out against a committed file.
#   The committed file is the EXPECTATION. If the code changes, the thing
#   being measured changes with it, and the comparison goes red. This is the
#   strongest pin shape the project has -- and it touches an artefact.
#
#   ARTEFACT AS SUBJECT. The measured value is READ OUT of the committed file.
#   Nothing executed. The check proves the file still says what it said, which
#   it will go on doing after the code it describes is reverted or deleted.
#
# Only the second is the disease measured three ways below. The first is the
# cure, and the old classification could not tell them apart, because both of
# them read an artefact.
#
# THE CASE THAT PROVES IT: v79_release_artefact.R. It classifies
# SOURCE+ARTEFACT, and it is the artefact half that used to be read as its
# weakness. What v79 actually does is BUILD the release artefact from plugin/
# inside the run, by invoking plugin/dev/tools/build-release.py; unpack the
# resulting zip under `umask 077`; and measure the file modes that land on
# disk -- "the only reading in this tree taken on a tree that unzip created
# rather than one the builder chmodded", in its own header. Its committed
# harness record covers only the three facts that need an X server. Nothing in
# the old vocabulary could distinguish that from a validator that opens a TSV
# and stops. v78 is the same shape: it runs plugin/dev/tools/build-manifest.py
# --check, which RE-RENDERS the manifest from the tree and compares.
#
# SO THERE IS A SECOND COLUMN, `executes`, AND IT IS NOT FOLDED INTO `class`.
# Its vocabulary is chosen to say what ran rather than how the run was scored:
#
#   NO      nothing under test was started. The value under test, if it is in
#           a file, came out of that file.
#   PRAAT   a Praat binary was resolved and driven. The old LIVE, sharpened:
#           LIVE says "a praat was resolved somewhere in this file AND a
#           subprocess was started somewhere in this file"; PRAAT says the
#           praat reached the command line of an actual spawn.
#   TOOL    a program belonging to this tree -- plugin/dev/tools/*.py,
#           harness/*.py, a harness run.sh -- was run.
#   UNKNOWN the file did not parse, so neither answer was taken.
#
# `runs` names the program, so every positive can be checked by hand in one
# look rather than believed.
#
# WHY NOT JUST WIDEN "LIVE". Because LIVE means "drives Praat", and driving
# Praat is ONE WAY of executing, not the definition of it. v79 executes and
# drives no Praat at all; a validator that re-drove a harness's own run.sh
# would execute and drive Praat only at one remove. Widening LIVE would have
# made the label mean two things and left the census still unable to answer
# the question in one place. The column that answers it is its own column.
#
# THE ERROR DIRECTION IS CHOSEN, NOT ACCIDENTAL. Calling a regenerating
# validator artefact-only would disqualify this suite's best allies and push
# the project into "fixing" checks that are already right; calling an
# artefact-only validator regenerating admits one bad pin. The first failure
# is worse, so where the parse tree cannot settle the two roles, this file
# resolves TOWARDS executing: an unrecognised variable in a command slot is
# treated as though it might be an interpreter, and the arguments are read.
# The one shape that can be wrong the other way is named under HOW EXECUTION
# IS DECIDED, below, rather than left to be discovered.
#
# ────────────────────────────────────────────────────────────────────────────
# THIS IS NOT AN ARGUMENT AGAINST ARTEFACT-AS-SUBJECT CHECKS EITHER -- and
# note which role that names: everything in this paragraph is about the
# SUBJECT role, never the oracle one. v03 pinning a printed
# p against R at half a display ULP is real evidence and worth every line of
# it; so is v73's reversal matrix. They are ORACLE AGREEMENTS -- the plugin's
# number against an independent computation -- and they keep their full value.
# What they cannot be is a PIN, because a pin's whole claim is "something would
# notice if this repair were undone", and a check whose subject came out of a
# committed file demonstrably does not notice: measurement (3) is that
# demonstration. A check that REGENERATED that file's subject before comparing
# is a different animal and is not what measurement (3) measured.
#
# SO THE CLASSIFICATION IS MECHANICAL, AND THAT IS THE POINT. A hand-kept list
# of which validators are which is one more thing that can quietly disagree
# with the tree -- which is the disease, not the cure. Everything below is read
# out of the validator sources with R's own parser, so a validator that stops
# reading plugin/ is reclassified by the same edit that stops it.
#
# HOW EACH CLASS IS DECIDED, in full, because a reader who disagrees needs
# something to disagree WITH:
#
#   * Every validator is parsed with parse(). Comments are gone by
#     construction, so a header that talks about plugin/ cannot be mistaken
#     for a file that reads it. (The header of every validator here talks
#     about plugin/.)
#   * A path ROOT is the literal "plugin", "harness" or "evidence" appearing
#     as a component of a string in the argument list of a path-building or
#     file-reading call -- so repo_path("harness", "legend", "out") roots at
#     harness, and so does repo_path(file.path("plugin", ...)).
#   * ROOTS PROPAGATE THROUGH VARIABLES to a fixed point. This is what handles
#     the EML_*_DIR overrides, and handling them is the subtle half. A
#     validator that takes $EML_LEGEND_DIR and falls back to
#     repo_path("harness", "legend", "out") is reading a HARNESS DIRECTORY even
#     though the path it reads is a variable -- the override exists so a break
#     test can plant a defect in a copy, not because the evidence is sometimes
#     something else. The fallback is the declaration of what the variable is
#     for, and it is what this census reads. Env-override variables that never
#     acquire a root are reported in the `unrooted` column rather than passed
#     over: that is the one shape where this file could be wrong in the
#     dangerous direction, so it is named.
#   * A root counts only when it reaches a READING call -- readLines, read.csv,
#     file.exists, source, system2 and the rest of BASE_READERS -- and reader
#     status propagates one step into locally defined helpers, so v55's
#     lines_of(src) counts as the read it is. Building a path and never
#     opening it is not evidence.
#   * LIVE is resolving a Praat binary -- Sys.getenv("PRAAT"), or
#     Sys.which("praat") / Sys.which("praat_barren") -- AND calling system2 or
#     system in the same file. Both halves are required: v78 and v79 shell out
#     to python3 and unzip and drive no Praat, and they are not LIVE.
#
# A validator may be more than one class, and most are. The record is the SET.
#
# HOW EXECUTION IS DECIDED, in the same detail and for the same reason:
#
#   * SPAWNING FOLLOWS LOCAL HELPERS, to a fixed point, exactly as reading
#     does. Every subprocess in v79 is started by its four-line `run(cmd,
#     args)`, and every one in v78 by `run_tool(cmd, args, wd)`; an analysis
#     that knew only system2() would report both files as executing nothing.
#   * THE COMMAND SLOT IS THE DISCRIMINATOR, and it is found by matching
#     arguments to formals rather than by counting. For system2 it is the
#     first argument. For a local helper it is whichever of ITS formals
#     reaches a command slot inside its body -- so `run <- function(cmd,
#     args)` passes its caller's first argument to the command line, while
#     `sha256 <- function(path) system2("sha256sum", path)` passes NOTHING of
#     its caller's there. That is what keeps `sha256(harness/out/menu.png)`
#     from reading as "the harness executed".
#   * A COMMAND THAT IS A BARE TOOL NAME IS CLOSED, and its arguments are not
#     consulted at all: sha256sum, git, unzip and stat do something TO what
#     they are handed, and what they are handed is data. A command that is a
#     WRAPPER (env, bash, python3, timeout, xvfb-run) or a variable is OPEN,
#     and then the arguments are where the program is. `env -u DISPLAY $praat
#     --run x.praat` and `python3 plugin/dev/tools/build-release.py` are found
#     this way; `git ls-files plugin/...` and `sha256sum harness/...` are not.
#   * PRAAT is a praat binary reaching that command slot -- through the
#     variable that holds it, tracked to a fixed point through assignment, so
#     the resolution at line 208 is still a praat at the spawn on line 461.
#   * TOOL is a plugin/ or harness/ ROOT reaching a spawn together with
#     something RUNNABLE: a rooted path in the command slot, or -- when the
#     command is open -- a rooted path plus a script-looking name among the
#     arguments. v78's whole rooting comes through the working directory it
#     hands its helper, which is why a working directory counts as part of
#     what a subprocess runs.
#   * `.praat` IS NOT A SCRIPT NAME HERE. Only Praat runs one, and that is the
#     other arm; several validators hash or lint setup.praat, and counting
#     that as execution would decorate exactly the checks that never run
#     anything.
#   * SCRIPT-NAME TAINT FOLLOWS PATH ARITHMETIC ONLY. This is measured, not
#     stylistic: this analysis is file-scope, `src`, `f`, `p` and `m` are
#     reused as locals in four unrelated helpers of v79, and a taint that
#     propagated through `src <- paste(readLines(recorder), collapse = "\n")`
#     reported v79 as running eml-graph-procedures.praat. A path built out of
#     a path is a path; a value read out of a file is data.
#
# WHERE THIS CAN BE WRONG, stated because the conservative direction has a
# cost and hiding it would be the same failure one level up: a file that hands
# a rooted, script-named path to a subprocess that merely READS it, through a
# command this file cannot resolve, will be reported as executing. That is the
# over-reading the error direction was chosen to accept. It is auditable --
# `runs` names the program, and the whole population of files that spawn
# anything at all is ten -- and it is the direction that cannot disqualify a
# validator that is doing the right thing.
#
# TWO RESIDUAL CLASSES, BOTH DELIBERATE. `NONE` is a validator that reads none
# of the three roots -- v83 is one, its subject being the suite's own findings
# ledger rather than the plugin. `UNKNOWN` is a validator this file could not
# parse. Neither is an error here and neither is swept up into ARTEFACT: they
# are reported as themselves, and v83 refuses a pin that names either, because
# "we could not tell" is not a reason to accept a pin.
#
# USAGE
#   Rscript validate/tools/evidence_census.R            print, rewrite the record
#   Rscript validate/tools/evidence_census.R --check    print, exit 1 on drift
#   Rscript validate/tools/evidence_census.R --quiet    record only, no table
#
# It is also a LIBRARY. validate/v83_pin_definition.R sources this file and
# calls eml_evidence_census() directly, so the meta-check computes the
# classification rather than trusting a file -- the record below is a
# convenience for readers and for diffs, and v83 additionally asserts that it
# reproduces, so this file cannot itself become the stale witness it is about.
#
# Deterministic: no timestamp, no commit hash, no wall clock in the record.
# Two runs on one tree write identical bytes, which is what makes --check mean
# anything. Stock R only, no packages, no network, no Praat.
#
# Overrides, both for break tests:
#   EML_CENSUS_VALIDATE_DIR   classify the validators in this directory
#   EML_CENSUS_RECORD         write/compare the record here
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

# ---------------------------------------------------------------------------
# THE VOCABULARY. Three lists, and each one is a claim that can be wrong, so
# each is stated here where it can be argued with rather than buried in a
# regex halfway down.
# ---------------------------------------------------------------------------

# The three directory roots that decide the class of what was read.
EML_CENSUS_ROOTS <- c(plugin = "SOURCE", harness = "ARTEFACT",
                      evidence = "ARTEFACT")

# Calls that OPEN something. `source` is here because sourcing a file reads
# it; `system2`/`system` because a path handed to a subprocess is read by the
# subprocess; `file.exists` and `dir.exists` because "the driver never ran
# this" is an assertion about the file and several validators make it their
# first check.
EML_CENSUS_READERS <- c(
    "readLines", "read.csv", "read.csv2", "read.delim", "read.delim2",
    "read.table", "readRDS", "readBin", "scan", "source", "file",
    "file.exists", "dir.exists", "list.files", "list.dirs", "file.info",
    "file.size", "file.mtime", "normalizePath", "file.copy", "unzip",
    "system2", "system", "read_input"
)

# ---------------------------------------------------------------------------
# THE EXECUTION VOCABULARY. Three more lists, same rule: stated here, where a
# reader can disagree with them, rather than inside the walk.
# ---------------------------------------------------------------------------

# The calls that START A PROCESS. Local helpers that wrap one are added to
# this set per file, to a fixed point, exactly as reading helpers are.
EML_CENSUS_SPAWNERS <- c("system", "system2")

# COMMANDS THAT RUN THEIR ARGUMENT. This list is the whole discriminator
# between "a tool was run" and "a file was handed to a tool", so it is short
# and it is literal. `env -u DISPLAY praat --run x.praat` runs praat;
# `python3 plugin/dev/tools/build-release.py` runs the builder; `bash
# harness/release/run.sh` runs the harness. By contrast `sha256sum
# harness/out/menu.png` and `git ls-files plugin/...` merely READ a path that
# happens to live under a root, and neither is the subject executing --
# so when the command is one of those, the arguments are not consulted at all.
EML_CENSUS_WRAPPERS <- c(
    "env", "timeout", "nohup", "stdbuf", "xvfb-run", "script",
    "bash", "sh", "dash", "zsh", "ksh",
    "python", "python2", "python3", "Rscript", "perl", "ruby", "node", "make"
)

# What a runnable path looks like. Used only to decide whether a ROOTED path
# reaching a wrapper is a program or a datum: `plugin/dev/tools/build-
# release.py` is a program, `harness/release/out/menu_installed.png` is not.
#
# `.praat` IS DELIBERATELY ABSENT. The only thing that runs a .praat file is
# Praat, and that is the other arm of this question -- so a .praat reaching a
# subprocess here is a file being HASHED, LINTED or COPIED, which several
# validators do to setup.praat, and calling that "the plugin executed" would
# put the label on precisely the checks that never run anything.
EML_CENSUS_SCRIPT_RX <- "\\.(py|sh|bash|pl|rb|js|R)$"

# The calls that BUILD A PATH. Script-literal taint follows a variable only
# through these, and the reason is measured rather than stylistic: in a
# file-scope analysis, names like `src`, `f`, `p` and `m` are reused as locals
# in four unrelated helpers, so a taint that propagated through
# `src <- paste(readLines(recorder), collapse = "\n")` reached every one of
# them and reported v79 as running eml-graph-procedures.praat. A path built
# out of a path is still a path; a value READ OUT of a file is data.
EML_CENSUS_PATHISH <- c("file.path", "paste0", "paste", "sprintf", "repo_path",
                        "shQuote", "normalizePath", "Sys.getenv", "c",
                        "basename", "dirname", "sub", "gsub", "trimws")

# What a Praat binary looks like when it is named as a literal. Deliberately
# anchored on the whole path COMPONENT: repo_path("..", "praat") names one,
# the string "praat_version" (a key in a TSV) does not.
EML_CENSUS_PRAAT_RX <- "^praat(_barren|_nogui)?(\\.exe)?$"

# ---------------------------------------------------------------------------
# AST helpers. Everything is done on the parse tree; nothing is done on text.
# ---------------------------------------------------------------------------
# A child of a call can be the EMPTY SYMBOL -- `x[, 1]` has one, and so does a
# function definition with an argument that has no default. Touching it raises
# "argument is missing", so every descent goes through here.
.eml_kid <- function(e, i) {
    a <- tryCatch(e[[i]], error = function(...) NULL)
    # Merely LOOKING at the empty symbol raises, so the look is guarded too.
    empty <- tryCatch(is.symbol(a) && !nzchar(as.character(a)),
                      error = function(...) TRUE)
    if (isTRUE(empty) || is.null(a)) return(NULL)
    a
}

.eml_walk_calls <- function(e, f) {
    if (is.call(e)) {
        f(e)
        for (i in seq_along(e)) {
            a <- .eml_kid(e, i)
            if (!is.null(a) && (is.call(a) || is.pairlist(a))) .eml_walk_calls(a, f)
        }
    } else if (is.pairlist(e)) {
        for (i in seq_along(e)) {
            a <- .eml_kid(e, i)
            if (!is.null(a) && (is.call(a) || is.pairlist(a))) .eml_walk_calls(a, f)
        }
    }
    invisible(NULL)
}

.eml_fname <- function(cl) {
    h <- cl[[1]]
    if (is.name(h)) as.character(h) else ""
}

# Every root literal anywhere inside an expression. A string is split on "/"
# so a one-piece "harness/legend/out" reads the same as three arguments.
.eml_lit_roots <- function(x) {
    out <- character(0)
    rec <- function(y) {
        if (is.character(y)) {
            for (s in y) {
                p <- strsplit(s, "/", fixed = TRUE)[[1]]
                out <<- c(out, p[p %in% names(EML_CENSUS_ROOTS)])
            }
        } else if (is.call(y) || is.pairlist(y)) {
            for (i in seq_along(y)) {
                a <- .eml_kid(y, i)
                if (!is.null(a)) rec(a)
            }
        }
    }
    rec(x)
    unique(out)
}

# Every string literal inside an expression, split into path components. Used
# by the execution side, which has to ask what a token IS ("build-release.py",
# "env", "praat") and not only which root it sits under.
.eml_lit_parts <- function(x) {
    out <- character(0)
    rec <- function(y) {
        if (is.character(y)) {
            for (s in y) out <<- c(out, strsplit(s, "/", fixed = TRUE)[[1]])
        } else if (is.call(y) || is.pairlist(y)) {
            for (i in seq_along(y)) {
                a <- .eml_kid(y, i)
                if (!is.null(a)) rec(a)
            }
        }
    }
    rec(x)
    unique(out[nzchar(out)])
}

# Does this expression RESOLVE A PRAAT BINARY -- $PRAAT, Sys.which("praat"),
# or a literal path component that is a praat binary's name?
.eml_expr_praat <- function(x) {
    hit <- any(grepl(EML_CENSUS_PRAAT_RX, .eml_lit_parts(x)))
    if (!hit && (is.call(x) || is.pairlist(x))) {
        .eml_walk_calls(x, function(cl) {
            fn <- .eml_fname(cl)
            if (fn %in% c("Sys.getenv", "Sys.which") && length(cl) >= 2L &&
                is.character(cl[[2]]) &&
                (identical(cl[[2]], "PRAAT") ||
                 grepl(EML_CENSUS_PRAAT_RX, cl[[2]]))) hit <<- TRUE
        })
    }
    isTRUE(hit)
}

# Is this expression nothing but path arithmetic? See EML_CENSUS_PATHISH.
.eml_pathish <- function(x) {
    ok <- TRUE
    if (is.call(x) || is.pairlist(x)) {
        .eml_walk_calls(x, function(cl) {
            fn <- .eml_fname(cl)
            if (!nzchar(fn) || !(fn %in% EML_CENSUS_PATHISH)) ok <<- FALSE
        })
    }
    isTRUE(ok)
}

# ARGUMENT MATCHING, because the command slot is the whole discriminator and
# it cannot be found by counting. Named arguments bind first, the rest go
# positionally into what is left, which is R's own rule. Returns the
# expressions bound to `want` and, separately, everything else in the call --
# and "everything else" deliberately includes arguments bound to formals the
# spawn never touches, such as a helper's `wd`: a working directory is part of
# what a subprocess runs, and v78 executes plugin/dev/tools/build-manifest.py
# entirely through one.
.eml_match_args <- function(cl, want, fmls) {
    args <- tryCatch(as.list(cl)[-1], error = function(...) list())
    if (!length(args)) return(list(matched = list(), rest = list()))
    nms <- names(args)
    if (is.null(nms)) nms <- rep("", length(args))
    bound <- rep(NA_character_, length(args))
    for (i in seq_along(args))
        if (nzchar(nms[i]) && nms[i] %in% fmls) bound[i] <- nms[i]
    free <- setdiff(fmls, bound[!is.na(bound)])
    for (i in seq_along(args)) {
        if (!is.na(bound[i]) || nzchar(nms[i]) || !length(free)) next
        bound[i] <- free[1]; free <- free[-1]
    }
    take <- !is.na(bound) & bound %in% want
    list(matched = args[take], rest = args[!take])
}

# The formals of system2()/system(), in order, so that positional matching
# finds the command slot whether it was written system2(praat, "--version")
# or system2(args = a, command = praat).
EML_CENSUS_BASE_FORMALS <- c("command", "args", "stdout", "stderr", "stdin",
                             "input", "env", "wait", "minimized", "invisible",
                             "timeout", "receive.console.signals", "intern",
                             "ignore.stdout", "ignore.stderr")

# Every symbol mentioned inside an expression, so a variable carrying a root
# can be recognised where it is used.
.eml_symbols <- function(x) {
    out <- character(0)
    rec <- function(y) {
        if (is.name(y)) {
            out <<- c(out, as.character(y))
        } else if (is.call(y) || is.pairlist(y)) {
            for (i in seq_along(y)) {
                a <- .eml_kid(y, i)
                if (!is.null(a)) rec(a)
            }
        }
    }
    rec(x)
    unique(out)
}

# ---------------------------------------------------------------------------
# eml_classify_one -- one validator, read off its own parse tree.
#
# Returns a one-row data.frame. `class` is the SET, joined with "+", in the
# fixed order SOURCE, LIVE, ARTEFACT so two runs sort identically.
# ---------------------------------------------------------------------------
eml_classify_one <- function(path) {
    id  <- sub("^(v[0-9]+).*$", "\\1", basename(path))
    row <- function(class, executes = "NO", runs = "", reads = "",
                    unrooted = "", note = "") {
        data.frame(id = id, file = basename(path), class = class,
                   executes = executes, runs = runs,
                   reads = reads, unrooted = unrooted, note = note,
                   stringsAsFactors = FALSE)
    }

    ex <- tryCatch(parse(path, keep.source = FALSE), error = function(e) NULL)
    if (is.null(ex)) {
        # A validator this file cannot parse is NOT quietly dropped and NOT
        # quietly called artefact-only. It is UNKNOWN, which v83 treats as a
        # pin it cannot accept, because an unclassifiable pin is exactly the
        # thing this whole exercise is about not waving through.
        # ...and its EXECUTION answer is UNKNOWN rather than NO. "We could not
        # read the file" is not the same statement as "nothing ran", and a
        # file that cannot be parsed must not be allowed to look like a
        # settled negative on either question.
        return(row("UNKNOWN", executes = "UNKNOWN", note = "does not parse"))
    }

    # -- assignments, so a root can be followed through a variable ----------
    asg <- list(); fdefs <- list(); envvars <- character(0)
    for (e in ex) .eml_walk_calls(e, function(cl) {
        fn <- .eml_fname(cl)
        if (fn %in% c("<-", "=", "<<-") && length(cl) == 3L && is.name(cl[[2]])) {
            v <- as.character(cl[[2]]); rhs <- cl[[3]]
            asg[[length(asg) + 1L]] <<- list(v = v, rhs = rhs)
            if (is.call(rhs) && identical(.eml_fname(rhs), "function")) {
                fdefs[[v]] <<- rhs
            }
            # An EML_* env override anywhere in the right-hand side makes this
            # variable one whose root has to come from its fallback.
            hasenv <- FALSE
            .eml_walk_calls(rhs, function(c2) {
                if (identical(.eml_fname(c2), "Sys.getenv") && length(c2) >= 2L &&
                    is.character(c2[[2]]) && grepl("^EML_", c2[[2]])) hasenv <<- TRUE
            })
            if (hasenv) envvars <<- unique(c(envvars, v))
        }
    })

    # -- reader closure: a local helper that reads is itself a reader -------
    readers <- EML_CENSUS_READERS
    for (round in 1:6) {
        grew <- FALSE
        for (nm in names(fdefs)) {
            if (nm %in% readers) next
            hit <- FALSE
            .eml_walk_calls(fdefs[[nm]], function(c2) {
                if (.eml_fname(c2) %in% readers) hit <<- TRUE
            })
            if (hit) { readers <- c(readers, nm); grew <- TRUE }
        }
        if (!grew) break
    }

    # -- root propagation to a fixed point ---------------------------------
    vroot <- list()
    for (round in 1:20) {
        changed <- FALSE
        for (a in asg) {
            r <- .eml_lit_roots(a$rhs)
            for (s in .eml_symbols(a$rhs)) {
                if (!is.null(vroot[[s]])) r <- c(r, vroot[[s]])
            }
            r   <- unique(r)
            old <- if (is.null(vroot[[a$v]])) character(0) else vroot[[a$v]]
            if (length(setdiff(r, old))) {
                vroot[[a$v]] <- unique(c(old, r)); changed <- TRUE
            }
        }
        if (!changed) break
    }

    # -- what actually reaches a reading call ------------------------------
    reads <- character(0); praat <- FALSE; shells <- FALSE
    for (e in ex) .eml_walk_calls(e, function(cl) {
        fn <- .eml_fname(cl)

        if (identical(fn, "read_input")) reads <<- unique(c(reads, "evidence"))

        # A path BUILT and never opened is not evidence, so roots are
        # harvested only at the reading calls. repo_path("plugin", ...) on a
        # line whose result nothing ever reads contributes nothing here, which
        # is the conservative direction: it can only withhold SOURCE, never
        # invent it.
        if (fn %in% readers) {
            for (i in seq_along(cl)[-1]) {
                a <- .eml_kid(cl, i)
                if (is.null(a)) next
                r <- .eml_lit_roots(a)
                for (s in .eml_symbols(a)) {
                    if (!is.null(vroot[[s]])) r <- c(r, vroot[[s]])
                }
                reads <<- unique(c(reads, r))
            }
        }

        if (identical(fn, "Sys.getenv") && length(cl) >= 2L &&
            is.character(cl[[2]]) && identical(cl[[2]], "PRAAT")) praat <<- TRUE
        if (identical(fn, "Sys.which") && length(cl) >= 2L &&
            is.character(cl[[2]]) && grepl("^praat", cl[[2]])) praat <<- TRUE
        if (fn %in% c("system2", "system")) shells <<- TRUE
    })

    # -- env overrides that never acquired a root --------------------------
    unrooted <- envvars[vapply(envvars, function(v) is.null(vroot[[v]]),
                               logical(1))]

    # =====================================================================
    # THE EXECUTION QUESTION: DID ANYTHING UNDER TEST ACTUALLY RUN?
    #
    # Everything above answers "what did this file READ". Nothing above can
    # tell v79 -- which BUILDS the release artefact from plugin/ inside the
    # run and measures what unzip puts on disk -- from a file that reads a
    # TSV and stops. Both read an artefact. Only one of them made the thing
    # it is measuring. What follows answers the other question, separately,
    # and reports it in its own column.
    # =====================================================================

    # -- two more taints, on the same fixed point as the roots -------------
    # A variable that has held a Praat binary, and a variable that has held
    # something runnable. Both propagate through assignment, so `BUILDER <-
    # file.path(plug, "dev", "tools", "build-release.py")` is still a
    # program at the point where a helper hands it to python3 four hundred
    # lines later.
    vpraat <- character(0); vscript <- list()
    for (round in 1:20) {
        changed <- FALSE
        for (a in asg) {
            p <- .eml_expr_praat(a$rhs) || any(.eml_symbols(a$rhs) %in% vpraat)
            if (p && !(a$v %in% vpraat)) {
                vpraat <- c(vpraat, a$v); changed <- TRUE
            }
            L <- .eml_lit_parts(a$rhs)
            s <- L[grepl(EML_CENSUS_SCRIPT_RX, L)]
            if (.eml_pathish(a$rhs)) {
                for (sym in .eml_symbols(a$rhs))
                    if (!is.null(vscript[[sym]])) s <- c(s, vscript[[sym]])
            }
            s   <- unique(s)
            old <- if (is.null(vscript[[a$v]])) character(0) else vscript[[a$v]]
            if (length(setdiff(s, old))) {
                vscript[[a$v]] <- unique(c(old, s)); changed <- TRUE
            }
        }
        if (!changed) break
    }

    # -- spawner closure: a local helper that spawns is itself a spawner ---
    # v79's `run(cmd, args)` and v78's `run_tool(cmd, args, wd)` are where
    # every subprocess in those files is actually started, so an analysis
    # that only knew system2() would see two files that execute nothing.
    spawners <- EML_CENSUS_SPAWNERS
    for (round in 1:6) {
        grew <- FALSE
        for (nm in names(fdefs)) {
            if (nm %in% spawners) next
            hit <- FALSE
            .eml_walk_calls(fdefs[[nm]], function(c2) {
                if (.eml_fname(c2) %in% spawners) hit <<- TRUE
            })
            if (hit) { spawners <- c(spawners, nm); grew <- TRUE }
        }
        if (!grew) break
    }

    # -- which slot of a spawner is the COMMAND ---------------------------
    # For system2 it is the first argument. For a local helper it is
    # whichever of its FORMALS reaches the command slot inside its body --
    # `run <- function(cmd, args) system2(cmd, args)` puts its first
    # argument on the command line and its second in the argument list, and
    # `sha256 <- function(path) system2("sha256sum", path)` puts NOTHING of
    # its caller's on the command line. That difference is the whole reason
    # hashing a committed PNG does not read as executing it.
    fcmd <- list()
    cmd_slot <- function(cl, fn) {
        if (fn %in% EML_CENSUS_SPAWNERS)
            return(.eml_match_args(cl, "command", EML_CENSUS_BASE_FORMALS))
        fdef <- fdefs[[fn]]
        if (is.null(fdef)) return(list(matched = list(),
                                       rest = tryCatch(as.list(cl)[-1],
                                                       error = function(...) list())))
        fmls <- names(as.list(fdef[[2]]))
        want <- if (is.null(fcmd[[fn]])) character(0) else fcmd[[fn]]$params
        .eml_match_args(cl, want, fmls)
    }
    for (round in 1:4) {
        for (nm in intersect(spawners, names(fdefs))) {
            fdef <- fdefs[[nm]]
            fmls <- names(as.list(fdef[[2]]))
            pr <- character(0); li <- character(0); fr <- character(0)
            .eml_walk_calls(fdef[[3]], function(c2) {
                fn2 <- .eml_fname(c2)
                if (!(fn2 %in% spawners)) return(invisible(NULL))
                for (e in cmd_slot(c2, fn2)$matched) {
                    li <<- c(li, .eml_lit_parts(e))
                    for (s in .eml_symbols(e)) {
                        if (s %in% fmls) pr <<- c(pr, s) else fr <<- c(fr, s)
                    }
                }
            })
            fcmd[[nm]] <- list(params = unique(pr), lits = unique(li),
                               free = unique(fr))
        }
    }

    # -- every spawn site, judged -----------------------------------------
    ex_praat <- FALSE; ex_tool <- FALSE; runs <- character(0)
    roots_of <- function(exprs) {
        r <- character(0)
        for (a in exprs) {
            r <- c(r, .eml_lit_roots(a))
            for (s in .eml_symbols(a)) if (!is.null(vroot[[s]])) r <- c(r, vroot[[s]])
        }
        unique(r)
    }
    praat_in <- function(exprs) {
        for (a in exprs) {
            if (any(grepl(EML_CENSUS_PRAAT_RX, .eml_lit_parts(a)))) return(TRUE)
            if (any(.eml_symbols(a) %in% vpraat)) return(TRUE)
        }
        FALSE
    }
    scripts_in <- function(exprs) {
        out <- character(0)
        for (a in exprs) {
            L <- .eml_lit_parts(a)
            out <- c(out, L[grepl(EML_CENSUS_SCRIPT_RX, L)])
            for (s in .eml_symbols(a))
                if (!is.null(vscript[[s]])) out <- c(out, vscript[[s]])
        }
        unique(out)
    }

    for (e in ex) .eml_walk_calls(e, function(cl) {
        fn <- .eml_fname(cl)
        if (!(fn %in% spawners)) return(invisible(NULL))
        sl <- cmd_slot(cl, fn)
        cmd_exprs <- sl$matched; arg_exprs <- sl$rest
        cmd_lits <- unlist(lapply(cmd_exprs, .eml_lit_parts))
        cmd_syms <- unlist(lapply(cmd_exprs, .eml_symbols))
        if (!(fn %in% EML_CENSUS_SPAWNERS) && !is.null(fcmd[[fn]])) {
            cmd_lits <- c(cmd_lits, fcmd[[fn]]$lits)
            cmd_syms <- c(cmd_syms, fcmd[[fn]]$free)
        }
        cmd_lits <- unique(cmd_lits); cmd_syms <- unique(cmd_syms)

        # IS THE COMMAND OPEN? A command that is a bare literal naming a
        # tool of its own -- sha256sum, git, unzip, stat -- is CLOSED: it
        # does what it does to whatever it is handed, and what it is handed
        # is data. A command that is a wrapper (env, bash, python3), or a
        # variable whose value this file cannot see, is OPEN, and then the
        # arguments are consulted, because that is where the program is.
        # THE OPEN CASE IS THE DELIBERATE OVER-READING: an unrecognised
        # variable in the command slot is treated as though it might be an
        # interpreter, which can only ever move a validator TOWARDS
        # executing. Getting this wrong the other way -- calling a
        # regenerating validator artefact-only -- is the failure this file
        # was rewritten to stop.
        closed <- length(cmd_lits) > 0 &&
                  !any(cmd_lits %in% EML_CENSUS_WRAPPERS) &&
                  !length(cmd_syms)
        open <- !closed

        if (praat_in(cmd_exprs) || any(cmd_syms %in% vpraat) ||
            any(grepl(EML_CENSUS_PRAAT_RX, cmd_lits)) ||
            (open && praat_in(arg_exprs))) {
            ex_praat <<- TRUE
            runs <<- c(runs, "praat")
        }

        cmd_roots <- roots_of(cmd_exprs)
        arg_roots <- roots_of(arg_exprs)
        scr <- scripts_in(c(cmd_exprs, arg_exprs))
        # A ROOTED PATH IN THE COMMAND SLOT is a tool of this tree being
        # run, full stop. A rooted path in the ARGUMENTS counts only when
        # something runnable is also in the call -- otherwise `sha256sum
        # harness/out/menu_installed.png` would read as executing the
        # harness, which is exactly the confusion this column exists to end.
        if (length(cmd_roots)) {
            ex_tool <<- TRUE
            runs <<- c(runs, if (length(scr)) scr else paste0(cmd_roots, "/"))
        } else if (open && length(arg_roots) && length(scr)) {
            ex_tool <<- TRUE
            runs <<- c(runs, scr)
        }
    })

    executes <- paste(c(if (ex_praat) "PRAAT", if (ex_tool) "TOOL"),
                      collapse = "+")
    if (!nzchar(executes)) executes <- "NO"

    cls <- character(0)
    if ("plugin" %in% reads) cls <- c(cls, "SOURCE")
    if (praat && shells)     cls <- c(cls, "LIVE")
    if (any(c("harness", "evidence") %in% reads)) cls <- c(cls, "ARTEFACT")
    if (!length(cls)) cls <- "NONE"

    row(paste(cls, collapse = "+"),
        executes = executes,
        runs = paste(sort(unique(runs)), collapse = ","),
        reads = paste(sort(reads), collapse = ","),
        unrooted = paste(sort(unrooted), collapse = ","))
}

# ---------------------------------------------------------------------------
# eml_evidence_census -- every validator in a directory, sorted by id.
# ---------------------------------------------------------------------------
eml_evidence_census <- function(validate_dir) {
    files <- sort(list.files(validate_dir, pattern = "^v[0-9]+_.*\\.R$",
                             full.names = TRUE))
    if (!length(files)) {
        return(data.frame(id = character(0), file = character(0),
                          class = character(0), executes = character(0),
                          runs = character(0), reads = character(0),
                          unrooted = character(0), note = character(0),
                          stringsAsFactors = FALSE))
    }
    out <- do.call(rbind, lapply(files, eml_classify_one))
    out[order(out$id, out$file), , drop = FALSE]
}

# eml_census_artefact_only -- the ids that read only committed files. KEPT AS
# IT WAS, because it answers the READING question and callers exist. It is no
# longer the disqualifying set: see below.
eml_census_artefact_only <- function(cen) cen$id[cen$class == "ARTEFACT"]

# eml_census_executes -- did anything under test run? The first-class
# question, asked of the column that carries it.
eml_census_executes <- function(executes) {
    !is.na(executes) && nzchar(executes) &&
        !identical(executes, "NO") && !identical(executes, "UNKNOWN")
}

# eml_census_subject_only -- ARTEFACT AS SUBJECT: the ids whose only evidence
# is a committed file AND which ran nothing. This is the disease. v79 reads a
# committed file too and is not in here, because it built the thing it
# measured.
eml_census_subject_only <- function(cen) {
    cen$id[cen$class == "ARTEFACT" &
           !vapply(cen$executes, eml_census_executes, logical(1))]
}

# eml_census_qualifies -- TRUE iff this row may be named as a pin: it reads
# the plugin's source within the run, or it EXECUTES something under test
# within the run. The second clause is the 2026-08-17 correction. It used to
# read "or drives Praat", which is one way of executing and not the only one:
# v79 executes by running plugin/dev/tools/build-release.py and measuring the
# tree that comes out, and under the old wording that structure was invisible.
# Praat-driving is a strict subset of executing, so nothing that qualified
# before stops qualifying now.
eml_census_qualifies <- function(class, executes = "NO") {
    grepl("SOURCE", class, fixed = TRUE) ||
        grepl("LIVE", class, fixed = TRUE) ||
        eml_census_executes(executes)
}

eml_census_write <- function(cen, path) {
    con <- file(path, open = "wt")
    on.exit(close(con))
    writeLines(c(
        "# validate/tools/EVIDENCE_CENSUS.tsv -- GENERATED, do not hand-edit.",
        "# Rscript validate/tools/evidence_census.R   regenerates this file.",
        "# class is the SET of evidence a validator READS, from its own source:",
        "#   SOURCE   reads plugin/ at run time      -- speaks for the code",
        "#   LIVE     drives a Praat binary in-run   -- speaks for the binary",
        "#   ARTEFACT reads harness/ or evidence/    -- speaks for a FILE",
        "#   NONE     reads none of the three         -- a check on the suite",
        "#   UNKNOWN  did not parse",
        "# executes is the separate question -- DID ANYTHING UNDER TEST RUN:",
        "#   NO       nothing under test was started in this run",
        "#   PRAAT    a Praat binary was resolved and driven",
        "#   TOOL     a program out of plugin/ or harness/ was run",
        "#   UNKNOWN  did not parse",
        "# runs names the evidence for that verdict -- the program, by name.",
        "#",
        "# ARTEFACT + executes NO is ARTEFACT AS SUBJECT and does not qualify",
        "# as a ledger pin: the measured value came out of a committed file and",
        "# nothing ran. ARTEFACT with executes PRAAT or TOOL is ARTEFACT AS",
        "# ORACLE -- the subject was regenerated in the run and the committed",
        "# file is the EXPECTATION it was compared against -- and that is one of",
        "# the strongest shapes in this suite, not a weakness. v79 is the worked",
        "# example. See the header of evidence_census.R for the argument, and",
        "# validate/v83_pin_definition.R for the check that enforces it."), con)
    write.table(cen, con, sep = "\t", quote = FALSE, row.names = FALSE,
                col.names = TRUE)
    invisible(path)
}

eml_census_read <- function(path) {
    if (!file.exists(path)) return(NULL)
    tryCatch(read.delim(path, comment.char = "#", stringsAsFactors = FALSE,
                        colClasses = "character", na.strings = character(0)),
             error = function(e) NULL)
}

# ---------------------------------------------------------------------------
# Script mode.
# ---------------------------------------------------------------------------
if (!isTRUE(getOption("eml.census.library"))) {
    .a <- commandArgs(FALSE)
    .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    .this <- if (length(.f)) normalizePath(.f[1]) else ""
    # Sourced as a library (no --file of our own): define and stop here.
    if (nzchar(.this) && identical(basename(.this), "evidence_census.R")) {
        HERE <- dirname(.this)
        VAL  <- dirname(HERE)

        vdir <- Sys.getenv("EML_CENSUS_VALIDATE_DIR", unset = "")
        if (!nzchar(vdir)) vdir <- VAL
        rec  <- Sys.getenv("EML_CENSUS_RECORD", unset = "")
        if (!nzchar(rec)) rec <- file.path(HERE, "EVIDENCE_CENSUS.tsv")

        args  <- commandArgs(trailingOnly = TRUE)
        check <- "--check" %in% args
        quiet <- "--quiet" %in% args

        cen <- eml_evidence_census(vdir)

        if (!quiet) {
            cat("evidence census\n")
            cat("  validators  ", vdir, "\n", sep = "")
            cat("  record      ", rec, "\n\n", sep = "")
            if (nrow(cen)) {
                for (i in seq_len(nrow(cen))) {
                    cat(sprintf("  %-5s %-34s %-16s %-10s %-24s %s\n", cen$id[i],
                                cen$file[i], cen$class[i], cen$executes[i],
                                cen$runs[i], cen$reads[i]))
                }
            } else {
                cat("  (no validators found)\n")
            }
            cat("\n")
            tb <- table(cen$class)
            for (nm in sort(names(tb))) {
                cat(sprintf("  %-16s %d\n", nm, as.integer(tb[[nm]])))
            }
            cat(sprintf("  %-16s %d\n", "TOTAL", nrow(cen)))
            cat("\n  did anything under test run:\n")
            te <- table(cen$executes)
            for (nm in sort(names(te))) {
                cat(sprintf("    %-14s %d\n", nm, as.integer(te[[nm]])))
            }
            so <- eml_census_subject_only(cen)
            or <- cen$id[grepl("ARTEFACT", cen$class, fixed = TRUE) &
                         vapply(cen$executes, eml_census_executes, logical(1))]
            cat("\n  ARTEFACT AS SUBJECT -- reads a committed file and ran\n",
                "  nothing (may not be named as a ledger pin):\n    ",
                if (length(so)) paste(so, collapse = " ") else "none", "\n",
                sep = "")
            cat("\n  ARTEFACT AS ORACLE -- reads a committed file AND\n",
                "  regenerated its subject in the run (a pin, and a strong one):\n    ",
                if (length(or)) paste(or, collapse = " ") else "none", "\n",
                sep = "")
            un <- cen[nzchar(cen$unrooted), , drop = FALSE]
            if (nrow(un)) {
                cat("\n  ENV OVERRIDES WITH NO ROOTED FALLBACK -- classified\n",
                    "  from the rest of the file; read these by hand:\n", sep = "")
                for (i in seq_len(nrow(un))) {
                    cat(sprintf("    %-5s %s\n", un$id[i], un$unrooted[i]))
                }
            }
        }

        if (check) {
            old <- eml_census_read(rec)
            same <- !is.null(old) && identical(dim(old), dim(cen)) &&
                identical(as.character(unlist(old)), as.character(unlist(cen)))
            if (same) {
                cat("\nrecord is current\n")
                quit(status = 0L)
            }
            cat("\nRECORD IS STALE -- regenerate with\n",
                "  Rscript validate/tools/evidence_census.R\n", sep = "")
            quit(status = 1L)
        }

        eml_census_write(cen, rec)
        if (!quiet) cat("\nwrote ", rec, "\n", sep = "")
    }
}
