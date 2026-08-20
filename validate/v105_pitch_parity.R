# ============================================================================
# v105_pitch_parity.R -- every pitch call in the tree asks Praat the same
#                        question
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT GOES WRONG WITHOUT THIS, and it is not a crash. A Praat pitch command
# takes its algorithm parameters positionally, and every one of them is a
# plausible number. Change "no" to "yes" in the very-accurate slot of one call
# site out of sixteen and Praat raises nothing, the Pitch object has the same
# class, "Get mean" returns a number of the same magnitude, the CSV has the
# same columns, and the figure looks right. What changed is the ANSWER. On a
# 0.22 s synthetic token at ~202 Hz, measured in this container against Praat
# 6.6.30 with the probe that produced the numbers in the next paragraph, very
# accurate ON moves the mean F0 by -0.67 Hz.
#
#     To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no",  ... -> 202.173968
#     To Pitch (filtered autocorrelation): 0, 75, 600, 15, "yes", ... -> 201.508260
#
# Two thirds of a hertz is beneath anyone's notice and above the precision this
# plugin prints. A user who tracks F0 through the graphs form and then batches
# the same corpus gets two means for one recording, both correct-looking, and
# nothing in the suite disagrees. That number goes in a paper.
#
# Commit 5d424aa made the filtered-autocorrelation tail canonical -- procedure
# @emlPitchArgsFAC in graphs/eml-graph-procedures.praat states it once -- and
# corrected the call sites to match. But most call sites still spell the tail
# literally rather than calling the procedure: two in the graphs form, one in
# the batch layer, two in the dev tests, and several in the harness drivers.
# They agree today by hand. A procedure that only one caller calls does not
# prevent drift in the others; it only records what they are supposed to say.
# This file is the thing that would notice.
#
# WHY SOURCE-LEVEL AND NOT A RUN. The failure is that two call sites DISAGREE,
# and no single run can see that -- each one, run on its own, returns a
# perfectly good number. Running them all and comparing means would work only
# where the sites are reachable from a driver and would compare through the
# noise of different fixtures. The text is where the disagreement lives, so the
# text is what is read. What a run adds -- that the argument ORDER matches the
# live signature -- is harness/acoustic's job and validate/v52 reports it.
#
# HOW THIS DIFFERS FROM v52, which also pins pitch parameters. v52 pins the
# batch layer's calls, argument by argument, as literal strings against
# APPENDIX_D: it asks "does eml-batch-process.praat say what canon says". It is
# scoped to that one file on purpose and says nothing about the other fifteen
# sites. This file asks the other question -- "do all sixteen say the SAME
# thing" -- across the whole tree, and it reads the canon out of the procedure
# rather than restating it, so the two files cannot drift into disagreeing
# about what canon is.
#
# COMPARISON IS NUMERIC, NOT TEXTUAL, and that is a measured decision. The
# batch layer writes 0.0 and 0.5 where the graphs layer writes 0 and 0.50. A
# string comparison calls that a difference; Praat does not. Probed here on
# 6.6.30, the two spellings return means that differ by exactly zero -- not
# nearly zero, the same double. So each argument is parsed and compared as a
# number, and a quoted argument as an unquoted string. Otherwise this file
# would land red on a cosmetic difference, and a validator that cries about
# whitespace is one that gets switched off before it catches anything.
#
# THREE FAMILIES, KEPT APART. Praat has several pitch commands and they are not
# variants of one call:
#
#   FAC  To Pitch (filtered autocorrelation)  11 args, tail of 8. Mean F0.
#   RCC  To Pitch (raw cross-correlation)     10 args, tail of 7. The track the
#                                             PointProcess behind jitter and
#                                             shimmer is built on.
#   AC3  To Pitch                              3 args, no tail at all.
#
# Folding them together would be wrong twice over: their tails are different
# LENGTHS, and the three return different numbers off the same sound. Probed
# on the same 0.22 s token: FAC 202.173968, AC3 202.385829, RCC-family
# To Pitch (cc) 203.032082. The bare three-argument form was also measured to
# be exactly To Pitch (ac) -- same double -- which is what it is documented to
# be and is why it is treated as the classic autocorrelation family and not as
# a short FAC.
#
# So each family carries its own canonical tail, asserted within the family,
# and the families are never compared with each other.
#
# THE SPELLINGS ARE NOT ASSUMED. Praat also offers To Pitch (ac), To Pitch
# (cc), To Pitch (shs), To Pitch (SPINET) and To Pitch (filtered
# cross-correlation), none of which appear in this tree today. Rather than
# grep for a list someone believed was complete, section 2 matches EVERY
# occurrence of "To Pitch" in every source file and requires each one to fall
# into an enumerated family. A call written with a spelling nobody here
# anticipated does not slip past unmatched -- it lands in section 2 as an
# unclassified family and turns this file red.
#
# THE CENSUS IS THE POINT OF THE FILE, and section 5 is where it happens.
# Every check above it is scoped to the sites the author enumerated, so a
# SEVENTEENTH call site added next year would be asserted on by nothing and
# every check here would still pass -- which is the exact shape of failure
# eml_census exists for (see its comment in helpers.R). Section 5 compares the
# sites found by scanning against the sites enumerated in SITES below, in both
# directions. Add a pitch call anywhere and this file goes red naming it.
#
# THE SITE KEY IS NOT A LINE NUMBER. A site is identified by file, family and
# its ordinal within that file -- "graphs/eml-graphs-form.praat#FAC2" -- not by
# "line 4300". Line numbers move every time anyone inserts a comment above,
# and a census that goes red on an unrelated edit teaches people to edit the
# census instead of reading it. The line is reported for the human and is not
# what the census turns on.
#
# WHAT IS EXCLUDED, AND WHY IT IS NOT A LOOPHOLE. Paths containing /out/ are
# skipped. Several harnesses copy the whole plugin into their out/ tree as
# scratch working state and some of those copies are committed; they are
# SNAPSHOTS of some past run, not source anyone edits, and holding them to
# today's canon would make this file red every time a harness ran against an
# older build. The exclusion is by path, not by a list of directories, so a new
# harness cannot quietly acquire an exemption -- but it also means a real call
# site must never be put under an out/ directory.
#
# Run:  Rscript validate/v105_pitch_parity.R
# Reads: the .praat source of the tree. Nothing needs to have been driven.
#        $EML_PITCH_ROOT overrides the tree that is read, which is how a
#        deliberately-broken copy is judged.
#
# Base R only. No packages.
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

V <- "v105"

ROOT <- Sys.getenv("EML_PITCH_ROOT", unset = "")
if (!nzchar(ROOT)) ROOT <- repo_path()
ROOT <- normalizePath(ROOT, mustWork = FALSE)

# ---------------------------------------------------------------------------
# join_continuations -- one Praat statement per element, however many lines it
# was written across.
#
# THIS IS NOT COSMETIC. Praat continues a statement with a leading "..." on the
# next line, and the batch layer and every harness driver wrap their pitch
# calls that way because the argument list is too long for one line. Read line
# by line, the batch call looks like "To Pitch (filtered autocorrelation):"
# with no arguments at all, and a check written against that would pass while
# asserting nothing. So the lines are joined FIRST and everything downstream
# sees whole statements.
#
# The line number returned is the line the statement STARTS on, which is the
# one a person opening the file wants.
# ---------------------------------------------------------------------------
join_continuations <- function(lines) {
    out <- character(0); at <- integer(0)
    i <- 1L
    while (i <= length(lines)) {
        cur <- lines[i]; start <- i
        while (i + 1L <= length(lines) && grepl("^\\s*\\.\\.\\.", lines[i + 1L])) {
            cur <- paste0(sub("\\s+$", "", cur), " ",
                          sub("^\\s*\\.\\.\\.\\s*", "", lines[i + 1L]))
            i <- i + 1L
        }
        out <- c(out, cur); at <- c(at, start); i <- i + 1L
    }
    list(text = out, line = at)
}

# ---------------------------------------------------------------------------
# in_string -- for each character position, is it inside a Praat string?
#
# WHY THIS IS NEEDED AT ALL. Two different things in this tree look identical
# to grep. graphs/eml-graph-procedures.praat builds the text of a RECORDED
# script -- 'data = To Pitch (filtered autocorrelation): " + .pitchArgs$' --
# which is a pitch call the plugin EMITS, and it is exactly the place a
# recorded methods section could come to claim parameters the session did not
# use. It must be checked, but it cannot be checked the same way as an executed
# call, because its arguments are a variable and not digits.
#
# harness/acoustic/drive.praat writes '"To Pitch (filtered autocorrelation);"'
# into an evidence file as the NAME of a command it could not run on an old
# Praat. That is not a call at all and must not be checked as one.
#
# Both are inside string literals; what separates them is a colon after the
# command name. Getting that distinction from the character-level quote state
# is the only way that does not amount to guessing from context.
#
# Praat escapes a quote inside a string by doubling it. A doubled quote is
# therefore handled correctly with no special case: the first closes the
# string, the second opens a new one, and the character between them -- there
# is none -- is what a special case would have been for.
# ---------------------------------------------------------------------------
in_string <- function(s) {
    ch <- strsplit(s, "", fixed = TRUE)[[1]]
    inq <- FALSE
    st <- logical(length(ch))
    for (k in seq_along(ch)) {
        st[k] <- inq
        if (ch[k] == '"') { if (inq) st[k] <- TRUE; inq <- !inq }
    }
    st
}

# ---------------------------------------------------------------------------
# split_args -- a Praat argument list into its arguments.
#
# Commas inside a quoted argument and inside a parenthesised one are not
# separators. Neither case occurs in a pitch call today, which is exactly why
# the splitter respects them: the day one does, a naive split on "," would
# silently produce the wrong ARITY, and arity is what tells FAC from RCC here.
# ---------------------------------------------------------------------------
split_args <- function(s) {
    ch <- strsplit(s, "", fixed = TRUE)[[1]]
    inq <- FALSE; depth <- 0L
    parts <- character(0); cur <- character(0)
    for (k in seq_along(ch)) {
        c1 <- ch[k]
        if (c1 == '"') inq <- !inq
        if (!inq && c1 == "(") depth <- depth + 1L
        if (!inq && c1 == ")") depth <- depth - 1L
        if (!inq && depth == 0L && c1 == ",") {
            parts <- c(parts, paste(cur, collapse = "")); cur <- character(0)
        } else {
            cur <- c(cur, c1)
        }
    }
    c(parts, paste(cur, collapse = ""))
}

# ---------------------------------------------------------------------------
# arg_key -- one argument reduced to what Praat will actually make of it.
#
# A numeric argument becomes its value, formatted to 12 significant digits, so
# 0.5 and 0.50 and .5 are one key and 0.09 and 0.9 are two. A quoted argument
# becomes its contents, so "no" and ""no"" -- the doubled form the emitted
# script carries -- are one key. Anything else, a variable name such as
# facPitchTop, is passed through verbatim: the floor and ceiling slots hold
# variables at most call sites and are never compared across sites anyway.
# ---------------------------------------------------------------------------
arg_key <- function(a) {
    a <- trimws(a)
    if (grepl('^"', a)) return(gsub('""', '"', sub('"$', "", sub('^"', "", a))))
    n <- suppressWarnings(as.numeric(a))
    if (!is.na(n)) return(formatC(n, format = "g", digits = 12))
    a
}

# ---------------------------------------------------------------------------
# THE FAMILIES.
#
# `spell` is matched against the text following "To Pitch". `nargs` is the full
# arity and `tail_from` is the first argument that is canon rather than the
# session's -- for FAC and RCC the first three are time step, floor and
# ceiling, and only the time step of those is fixed.
# ---------------------------------------------------------------------------
FAMILY <- list(
    FAC = list(spell = " (filtered autocorrelation)", nargs = 11L, tail_from = 4L),
    RCC = list(spell = " (raw cross-correlation)",    nargs = 10L, tail_from = 4L),
    AC3 = list(spell = "",                            nargs =  3L, tail_from = NA_integer_)
)

# ---------------------------------------------------------------------------
# THE ENUMERATED CALL SITES.
#
# Every pitch call in the tree, by family and by its ordinal within its file.
# `mode` is "exec" for a call the script runs and "emit" for one it writes into
# a recorded script. This list is the census's other side; section 5 compares
# it against what scanning actually finds, both ways.
#
# `note` is for the reader and is not asserted on.
# ---------------------------------------------------------------------------
SITES <- rbind.data.frame(
  # --- the shipped plugin -----------------------------------------------------
  data.frame(key = "plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat#FAC1",
             mode = "exec", note = "@emlGraphsConvertObject, Sound -> Pitch"),
  data.frame(key = "plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat#FAC2",
             mode = "emit", note = "the recorded script for the line above"),
  data.frame(key = "plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat#FAC3",
             mode = "exec", note = "@emlGraphsConvertObject, Spectrum -> Sound -> Pitch"),
  data.frame(key = "plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat#FAC4",
             mode = "emit", note = "the recorded script for the line above"),
  data.frame(key = "plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat#FAC1",
             mode = "exec", note = "pitch range changed in the form, Sound source"),
  data.frame(key = "plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat#FAC2",
             mode = "exec", note = "pitch range changed in the form, Spectrum source"),
  data.frame(key = "plugin_EML_StatsGraphs/scripts/eml-batch-process.praat#FAC1",
             mode = "exec", note = "batch mean F0, APPENDIX_D S1A"),
  data.frame(key = "plugin_EML_StatsGraphs/scripts/eml-batch-process.praat#RCC1",
             mode = "exec", note = "batch voice-quality track, APPENDIX_D S1B"),
  # --- the plugin's own dev tests ---------------------------------------------
  data.frame(key = "plugin_EML_StatsGraphs/dev/tests/eml-integration-test.praat#FAC1",
             mode = "exec", note = "integration test fixture"),
  data.frame(key = "plugin_EML_StatsGraphs/dev/tests/phase1/test-extract.praat#FAC1",
             mode = "exec", note = "phase-1 extract test fixture"),
  # --- harness drivers --------------------------------------------------------
  data.frame(key = "harness/acoustic/drive.praat#FAC1",
             mode = "exec", note = "argument-order evidence for v52"),
  data.frame(key = "harness/acoustic/drive.praat#RCC1",
             mode = "exec", note = "argument-order evidence for v52"),
  data.frame(key = "harness/dispatch/drive.praat#FAC1",
             mode = "exec", note = "a Pitch object to feed the form's dispatch"),
  data.frame(key = "harness/graphaxes/axes_drive.praat#FAC1",
             mode = "exec", note = "steady 200 Hz tone, axis geometry"),
  data.frame(key = "harness/graphaxes/axes_drive.praat#FAC2",
             mode = "exec", note = "2 Hz ramp, axis geometry"),
  data.frame(key = "harness/graphaxes/axes_drive.praat#FAC3",
             mode = "exec", note = "tick precision, axis geometry"),
  data.frame(key = "harness/graphaxes/stereo_drive.praat#FAC1",
             mode = "exec", note = "stereo channel gate"),
  data.frame(key = "harness/graphaxes/cases/repro_ramp2.praat#FAC1",
             mode = "exec", note = "standalone repro of the ramp case"),
  data.frame(key = "harness/graphaxes/cases/repro_steady_pitch.praat#FAC1",
             mode = "exec", note = "standalone repro of the steady case"),
  data.frame(key = "harness/graphaxes/cases/repro_tickprec.praat#FAC1",
             mode = "exec", note = "standalone repro of the tick case"),
  data.frame(key = "harness/boxgeom/data.praat#AC31",
             mode = "exec", note = "a Pitch object for a box-geometry fixture"),
  data.frame(key = "harness/linestyle/data.praat#AC31",
             mode = "exec", note = "a Pitch object for a line-style fixture"),
  data.frame(key = "harness/record_e2e/fixture.praat#AC31",
             mode = "exec", note = "a Pitch object for the recorder fixture"),
  stringsAsFactors = FALSE
)

# ---------------------------------------------------------------------------
# THE SITES THAT DO NOT USE CANON, NAMED ONE BY ONE.
#
# harness/graphaxes drives six filtered-autocorrelation calls with very
# accurate ON where canon has it OFF. Nothing in the tree records that as a
# decision, and it is not obviously one -- the six read like a copy of a call
# somebody wrote before @emlPitchArgsFAC existed.
#
# THIS IS NOT AN EXEMPTION AND IT IS NOT AN EXCUSE. It is a pin, in the sense
# validate/v06 pins D15 and validate/v104 pins the accented-capital fold: the
# divergence is written down here, at the exact slot and the exact value, and
# it is asserted. Three things now go red rather than passing unseen --
# graphaxes changing to some THIRD value, graphaxes being corrected to canon
# (at which point this pin names itself and asks to be deleted), and any site
# not on this list acquiring a divergence of its own. What does not happen is
# the divergence sitting in the tree with nothing in the suite aware of it,
# which is where it was before this file existed.
#
# THE ALLOWANCE IS EMPTY, AND THAT IS THE RULING. On 20 August 2026 Ian ruled
# that a pitch call in this repository aligns with the PraatGen canonical
# standards and with nothing else -- there is no such thing as a fixture that
# is allowed to ask Praat a different question. The seven filtered-
# autocorrelation calls under harness/graphaxes that carried very-accurate ON
# were brought to canon in the same commit as this line.
#
# The list is kept, empty, rather than deleted. It is the shape a future
# exception would have to take, and leaving it visible means a divergence can
# only be introduced by writing one down here, in public, with a key -- never
# by editing a number in a fixture and hoping the parity check reads it as
# ordinary. An empty list is a stronger statement than no list.
# ---------------------------------------------------------------------------
DIVERGENT <- list()
divergence_for <- function(key) {
    for (d in DIVERGENT) if (identical(d$key, key)) return(d)
    NULL
}

# ===========================================================================
# 1. THE CANON, READ OUT OF THE PROCEDURE THAT OWNS IT
# ===========================================================================
# @emlPitchArgsFAC is the one place the filtered-autocorrelation tail is
# stated. Restating it here would create a second place for it to live and a
# second thing to drift, and the whole complaint this file answers is that the
# tail lives in too many places. So the canon is PARSED from the procedure.
#
# The procedure body concatenates string literals around string$ (.floor) and
# string$ (.top). Gluing the quoted pieces together and leaving the variable
# pieces as gaps yields the argument list with slots 2 and 3 empty -- which is
# exactly right, because floor and ceiling are the session's and are the two
# arguments this file must NOT compare across call sites.
proc_path <- file.path(ROOT, "plugin_EML_StatsGraphs", "graphs",
                       "eml-graph-procedures.praat")
check_true(V, "the procedure that owns the FAC tail is present",
           file.exists(proc_path))

canon_fac <- NULL
if (file.exists(proc_path)) {
    pj <- join_continuations(readLines(proc_path, warn = FALSE))
    decl <- grep("^\\s*procedure\\s+emlPitchArgsFAC\\b", pj$text)
    check_true(V, "@emlPitchArgsFAC is declared as a procedure", length(decl) == 1L)
    # THE BODY IS BOUNDED, NOT GREPPED FOR BY NAME. The assignment inside the
    # procedure does not mention the procedure's own name -- it is just
    # `.args$ = ...` -- so searching the whole file for a line carrying both
    # would find nothing and this section would silently parse no canon at all,
    # leaving every FAC comparison below it unrun and the file green. The body
    # runs from the declaration to the first endproc after it.
    asg <- character(0)
    if (length(decl) == 1L) {
        ends <- grep("^\\s*endproc\\b", pj$text)
        ends <- ends[ends > decl]
        if (length(ends) > 0L) {
            body <- seq.int(decl, ends[1])
            asg <- pj$text[intersect(body, grep("\\.args\\$\\s*=", pj$text))]
        }
    }
    check_true(V, "@emlPitchArgsFAC assigns its argument list once",
               length(asg) == 1L)
    if (length(asg) == 1L) {
        # Every double-quoted literal in the assignment, in order, concatenated.
        # A doubled quote inside one of them is Praat's escape and collapses to
        # a single quote, which is how ""no"" arrives here as "no".
        lits <- regmatches(asg, gregexpr('"([^"]|"")*"', asg))[[1]]
        glued <- paste(vapply(lits, function(x)
            gsub('""', '"', substr(x, 2L, nchar(x) - 1L)), ""), collapse = "")
        canon_fac <- vapply(split_args(glued), arg_key, "")
        names(canon_fac) <- NULL
    }
}

check_true(V, "the canonical FAC list has 11 arguments",
           !is.null(canon_fac) && length(canon_fac) == 11L)

# A SECOND WITNESS TO THE CANON ITSELF, and it is here on purpose.
#
# Everything else in this file compares call sites against the procedure. That
# makes the procedure unfalsifiable: edit @emlPitchArgsFAC to say "yes" and
# every parity check still passes, because every site is being measured against
# the thing that moved. Canon moving is a decision, and a decision has to be
# visible. These eight lines are the only place in this file that says what the
# tail IS rather than that the sites agree on it, so a change to the procedure
# lands here, red, naming the slot.
if (!is.null(canon_fac) && length(canon_fac) == 11L) {
    want <- c("0", "", "", "15", "no", "0.03", "0.09", "0.5", "0.055", "0.35", "0.14")
    slots <- c("time step", "floor", "ceiling", "max candidates",
               "very accurate", "silence threshold", "voicing threshold",
               "octave cost", "octave-jump cost", "voiced/unvoiced cost",
               "ceiling multiplier")
    for (k in seq_len(11L)) {
        if (k %in% c(2L, 3L)) next          # the session's, not canon's
        check_true(V, sprintf("canon FAC %s is %s", slots[k], want[k]),
                   identical(canon_fac[k], arg_key(want[k])))
    }
}

# THE CROSS-CORRELATION TAIL HAS NO PROCEDURE, so it is pinned here instead.
#
# It is a separate family with a separate purpose -- the track the PointProcess
# behind jitter and shimmer is built on -- and it is seven arguments where FAC
# has eight. Its two call sites agree with each other today by hand, the same
# way the FAC sites did before 5d424aa, and the same drift is available to
# them. Pinning it here is the weaker half of the fix; the stronger half would
# be an @emlPitchArgsRCC beside @emlPitchArgsFAC, which belongs in
# eml-graph-procedures.praat and not in a validator.
#
# The values are APPENDIX_D S1B, and validate/v52 pins the batch site against
# the same list independently.
canon_rcc <- unname(vapply(c("0", "", "", "15", "no", "0.03", "0.45", "0.01",
                             "0.35", "0.14"), arg_key, ""))
names(canon_rcc) <- NULL

# ===========================================================================
# 2. SCAN THE TREE
# ===========================================================================
praat_files <- list.files(ROOT, pattern = "\\.praat$", recursive = TRUE,
                          full.names = FALSE)
# The plugin/ symlink points at plugin_EML_StatsGraphs/. Following it would
# report every plugin call site twice, under two names, and the census would
# then be a list of duplicates nobody could read.
praat_files <- praat_files[!grepl("(^|/)plugin/", praat_files)]
# See the header on why /out/ is skipped.
praat_files <- praat_files[!grepl("/out/", praat_files, fixed = TRUE)]
praat_files <- sort(praat_files)

check_true(V, "there is Praat source to read", length(praat_files) > 0L)

found <- list()          # key -> list(file, line, family, mode, args, text)
unclassified <- character(0)

for (rel in praat_files) {
    ln <- readLines(file.path(ROOT, rel), warn = FALSE)
    if (!any(grepl("To Pitch", ln, fixed = TRUE))) next
    j <- join_continuations(ln)
    seen <- c(FAC = 0L, RCC = 0L, AC3 = 0L)

    for (idx in seq_along(j$text)) {
        stmt <- j$text[idx]
        if (!grepl("To Pitch", stmt, fixed = TRUE)) next
        if (grepl("^\\s*[#;]", stmt)) next          # a whole-line comment

        st <- in_string(stmt)
        m <- gregexpr("To Pitch", stmt, fixed = TRUE)[[1]]
        for (pos in m) {
            after <- substr(stmt, pos + 8L, nchar(stmt))

            # WHICH FAMILY. The parenthesised spellings are tried before the
            # bare one, because the bare one's pattern is the empty string and
            # would otherwise swallow all of them.
            fam <- NA_character_
            for (nm in c("FAC", "RCC")) {
                if (startsWith(after, FAMILY[[nm]]$spell)) { fam <- nm; break }
            }
            if (is.na(fam) && startsWith(after, ":")) fam <- "AC3"

            rest <- if (!is.na(fam)) sub(paste0("^\\Q", FAMILY[[fam]]$spell, "\\E"),
                                         "", after) else after
            has_args <- grepl("^\\s*:", rest)

            if (is.na(fam)) {
                # Prose mentions "To Pitch" all over this tree -- in comments
                # at the end of a line of code, in help strings. Only something
                # that looks like a CALL, a command name followed by a colon,
                # is a problem; anything else is narration and is left alone.
                if (grepl("^\\s*\\([^)]*\\)\\s*:", after)) {
                    unclassified <- c(unclassified,
                        sprintf("%s:%d %s", rel, j$line[idx],
                                trimws(substr(after, 1L, 48L))))
                }
                next
            }
            if (!has_args) next        # a bare mention of the command's name

            inside <- st[pos]
            arglist <- sub("^\\s*:\\s*", "", rest)

            seen[fam] <- seen[fam] + 1L
            key <- sprintf("%s#%s%d", rel, fam, seen[fam])
            found[[key]] <- list(
                file = rel, line = j$line[idx], family = fam,
                mode = if (inside) "emit" else "exec",
                # unname, because vapply names its result after its input and
                # identical() counts a name as part of the value -- a named
                # "0.5" is not identical to a bare "0.5", and every comparison
                # below would fail on evidence that is entirely correct.
                args = if (inside) NULL
                       else unname(vapply(split_args(arglist), arg_key, "")),
                text = trimws(stmt))
        }
    }
}

check_true(V, "no pitch command uses an unenumerated spelling",
           length(unclassified) == 0L)
if (length(unclassified) > 0L) {
    check_true(V, sprintf("  unclassified: %s",
                          paste(utils::head(unclassified, 4), collapse = " | ")),
               FALSE)
}

# ===========================================================================
# 3. EVERY EXECUTED CALL CARRIES ITS FAMILY'S CANON
# ===========================================================================
# The floor and the ceiling are skipped at every site. They are the session's,
# the user picks them, and the batch layer deliberately runs a lower FAC floor
# than the graphs form -- 50 against 75 -- because it is analysing a corpus and
# not a picture. Asserting them equal would demand a change that is wrong.
#
# Everything else is asserted argument for argument, so a failure names the
# slot rather than saying two long strings differ somewhere.
SLOT_FAC <- c("time step", "floor", "ceiling", "max candidates",
              "very accurate", "silence threshold", "voicing threshold",
              "octave cost", "octave-jump cost", "voiced/unvoiced cost",
              "ceiling multiplier")
SLOT_RCC <- c("time step", "floor", "ceiling", "max candidates",
              "very accurate", "silence threshold", "voicing threshold",
              "octave-jump cost", "voiced/unvoiced cost", "ceiling multiplier")

compare_site <- function(key, site, canon, slots) {
    a <- site$args
    if (!check_true(V, sprintf("%s has %d arguments", key, length(canon)),
                    length(a) == length(canon))) return(invisible(FALSE))
    div <- divergence_for(key)
    for (k in seq_along(canon)) {
        if (k %in% c(2L, 3L)) next
        if (!is.null(div) && identical(div$slot, k)) {
            # The pinned divergence. Asserted AT ITS CURRENT VALUE -- see the
            # comment on DIVERGENT -- so correcting it to canon shows up here
            # rather than nowhere.
            check_true(V, sprintf("%s %s is pinned divergent (%s)",
                                  key, slots[k], div$is),
                       identical(a[k], arg_key(div$is)))
            next
        }
        check_true(V, sprintf("%s %s == canon", key, slots[k]),
                   identical(a[k], canon[k]))
    }
    invisible(TRUE)
}

for (key in names(found)) {
    s <- found[[key]]
    if (s$mode != "exec") next
    if (s$family == "FAC" && !is.null(canon_fac)) compare_site(key, s, canon_fac, SLOT_FAC)
    if (s$family == "RCC") compare_site(key, s, canon_rcc, SLOT_RCC)
    if (s$family == "AC3") {
        # THE BARE FORM CARRIES NO TAIL, and that is the whole assertion.
        # It is here so the spelling cannot become a back door: someone who
        # wanted eight thresholds and wrote them after "To Pitch:" would be
        # writing a call this file has no canon for, and would land red.
        check_true(V, sprintf("%s is the plain 3-argument form", key),
                   length(s$args) == 3L)
        check_true(V, sprintf("%s takes the automatic time step", key),
                   length(s$args) >= 1L && identical(s$args[1], arg_key("0")))
    }
}

# ===========================================================================
# 4. EVERY EMITTED CALL GETS ITS ARGUMENTS FROM THE PROCEDURE
# ===========================================================================
# An emitted call is the text of a recorded script -- what a user pastes into
# Praat six months later to reproduce a figure, and what a methods section gets
# copied from. If it spells the tail literally it is a SECOND copy of canon,
# living in a string, where a reader will never look for it and where drift
# produces a script that claims parameters the session did not use. That is the
# specific failure @emlPitchArgsFAC was written to make impossible, so the only
# acceptable emitted call is one whose arguments come from the procedure.
#
# The check is that the statement concatenates the procedure's output and that
# no literal argument tail follows the command name inside the string.
for (key in names(found)) {
    s <- found[[key]]
    if (s$mode != "emit") next
    check_true(V, sprintf("%s builds its arguments from @emlPitchArgsFAC", key),
               grepl("emlPitchArgsFAC|pitchArgs\\$", s$text))
    # A literal tail would show up as digits immediately after the colon,
    # inside the quotes -- 'To Pitch (filtered autocorrelation): 0, 75, ...'.
    check_true(V, sprintf("%s spells no arguments of its own", key),
               !grepl('To Pitch \\([^)]*\\):\\s*[0-9]', s$text))
}

# ===========================================================================
# 5. THE CENSUS
# ===========================================================================
# Sections 3 and 4 loop over what SCANNING found, so they cannot notice a site
# the author never knew about -- they would simply check it and pass. What is
# missing is a statement about the POPULATION, and that is what SITES is for:
# it is the author's account of the tree, written down, and this section makes
# the two sides disagree out loud.
#
# A site found but not enumerated is a pitch call that entered the tree without
# anyone deciding what tail it should carry. A site enumerated but not found is
# an entry describing a call that has been deleted or renamed, and it is the
# quieter of the two -- the checks above it go on passing while asserting on
# nothing at all.
eml_census(V, "pitch call site", names(found), SITES$key)

# The mode is part of the account too. A site that was an executed call and is
# now an emitted one, or the reverse, is checked by an entirely different
# section, and swapping without saying so would move it out from under the
# checks written for it.
for (i in seq_len(nrow(SITES))) {
    k <- SITES$key[i]
    if (is.null(found[[k]])) next
    check_true(V, sprintf("%s is still a %s call", k, SITES$mode[i]),
               identical(found[[k]]$mode, SITES$mode[i]))
}

# The pinned divergences are censused separately, and in both directions. An
# entry here for a site that has been corrected is the pin outliving the wart:
# section 3 would still be asserting the old value, and the correction would
# show up as a failure that reads as if the correct value were wrong. Naming it
# here says plainly what happened instead.
eml_census(V, "pinned divergence",
           vapply(DIVERGENT, function(d) d$key, ""),
           vapply(DIVERGENT, function(d) d$key, ""))
for (d in DIVERGENT) {
    check_true(V, sprintf("the pinned-divergent site %s still exists", d$key),
               !is.null(found[[d$key]]))
}

# WHAT WAS FOUND, for the person reading the output. Not a check -- attest()
# records evidence that is not a pass or a fail -- but the fastest way to see
# that the scan read the tree it was pointed at.
n_by <- table(vapply(found, function(s) s$family, ""))
attest(V, "pitch call sites found",
       paste(sprintf("%s=%d", names(n_by), as.integer(n_by)), collapse = " "))
attest(V, "tree read", ROOT)

if (!exists("EML_SUITE")) {
    eml_report("v105 every pitch call asks Praat the same question")
    eml_exit()
}
