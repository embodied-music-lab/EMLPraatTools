# ============================================================================
# v67_axis_and_spectrum.R -- two author rulings of 16 August 2026, both about
# a figure that says nothing and raises nothing
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. Two findings, one in the draw layer and one in the
# recorder, that have nothing in common except that both of them are SILENT
# and both of them end with a user looking at a picture that is not a record
# of their data.
#
#   RULING A -- "DRAW WHAT YOU CAN." THE ONE-BIN SPECTRUM.
#
#   A Spectrum drawn over a frequency window containing exactly ONE bin
#   rendered a titled, labelled, gridded, tick-marked frame with ZERO ink
#   inside it, and the bin that was not drawn held the peak of the tone.
#   Praat's Spectrum `Draw:` joins bin points with line SEGMENTS, and one
#   point is no segment: the peak lands on the axis and not on the paper. Two
#   bins draw normally, which is the control that says the finding is about
#   the COUNT and not about the range.
#
#   HOW REACHABLE IT IS is the half the first measurement understated, and it
#   is the reason the fixtures in this file are short. Praat's bin width is
#   1/duration after the zero-pad, so the window that triggers this scales
#   with how SHORT the recording is:
#
#       1.4861 s tone   0.336 Hz bins   needs a 0.2 Hz zoom     -- a curiosity
#       0.15 s token    5.383 Hz bins   ANY zoom under 10.7 Hz  -- routine
#
#   Measured at HEAD on 6.6.30, 16 August 2026: a 1 kHz tone in a 0.15 s
#   token drawn over 998..1002 Hz put ONE bin in range -- bin 187, 1001.294
#   Hz, holding 80.34 dB, the peak -- and drew a 48,870-byte PNG with zero ink
#   inside its frame. Short tokens are what phonetics is made of. The author's
#   ruling is DRAW WHAT YOU CAN: a single in-range bin is now a stem to the
#   frame floor. ZERO bins in range stays empty, because there is genuinely
#   nothing to draw.
#
#   RULING B (10b) -- THE RECORDED AXIS, IN THE EDITABLE BLOCK.
#
#   The author's words: "the record process should note if it was auto and
#   offer 0.0 to 0.0 as the range in the editable top block of variables."
#
#   Ruling 10(a) had already settled that the recorded CALL must carry the
#   user's choice rather than the resolution -- (0, 0) is the sentinel the
#   dialog names on its own face, not a range. What it left behind was two
#   bare literals sitting in a draw step, under a block whose own sentence
#   promised that "nothing below this block names an object or a column". The
#   axis was the third thing a user retargeting a workflow has to change and
#   the only one still buried in the body.
#
# WHAT THE FAILURES LOOK LIKE, because neither of them raises.
#
#   THE ONE-BIN SPECTRUM PRODUCES A FILE, and a large one: 48,870 bytes,
#   because a figure with a frame, ticks, two axis names and a title is a big
#   PNG whether or not anything was plotted inside it. Every check that asks
#   "did it draw" says yes. This file asks how much ink is INSIDE THE FRAME,
#   and records the byte counts beside it as the trap they are.
#
#   THE UNLIFTED AXIS PRODUCES A CORRECT, RUNNABLE SCRIPT. Replay it on the
#   same data and it reproduces the figure exactly -- that is ruling 10(a)
#   working. What it does not do is let anybody CHANGE the axis without
#   hunting the steps, which is the thing the block exists to abolish, and the
#   block was making a promise about that in its own text.
#
# WHAT COULD NOT HAVE CAUGHT ANY OF IT, AND WHY.
#
#   - v66_draw_layer.R, WHICH FOUND THE ONE-BIN SPECTRUM AND COULD NOT REPAIR
#     IT. Its section 8 is the model this file is built on and is worth being
#     exact about: it drove the defect live, printed the bin count, the peak
#     dB and the zero ink as a NOTE, and asserted no remedy -- because the
#     choice between a stem, a marker and a refusal is the author's and not a
#     validator's. It also drove it on the LONG fixture, where a 0.2 Hz zoom
#     reads as a laboratory curiosity rather than as something a user does.
#     This file is the other half: the ruling has been made, so the remedy is
#     asserted, and the fixture is a 0.15 s token where a four-hertz zoom is
#     an ordinary request.
#
#   - v58_recorder_replay.R AND harness/record. They prove an emitted script
#     RUNS, that a same-data replay reproduces its figure, and -- section 8 --
#     that the block's COLUMN half is load-bearing, by editing it and running
#     the file. Every one of those was green over ruling B, and section 8 is
#     precisely why: it edits five column declarations because five column
#     declarations were all the block had. A validator that edits what is
#     there cannot notice what is missing.
#
#   - v27_empty_frames.R, which calls a figure blank when it has no CHROMATIC
#     ink. That is the right verdict for the one-bin spectrum and it never
#     sees it: v27's population is harness/stress_cases, which draws violins,
#     boxes, bars and histograms from tables. There is no Spectrum in it, and
#     a case that zooms a spectrum to four hertz is not a stress case anybody
#     would have thought to write before the finding existed.
#
#   - THE NUMERIC VALIDATORS, v01 through v19. Neither defect computes a wrong
#     number. The one-bin spectrum's bin holds exactly the dB it should; the
#     unlifted axis records exactly the range it was given. A validator that
#     recomputes statistics has nothing to disagree with, in either direction.
#
#   - A GOLDEN-FILE DIFF, and this one is worth saying twice. Both defects
#     were already sitting in committed evidence: harness/drawlayer/out
#     carried the empty one-bin PNG and harness/record/out carried an emitted
#     script whose violin step read `..., 0, 0`. A diff says "this changed";
#     it cannot say "this was always wrong".
#
#   - AND A CHECK ON THE EMITTED FILE'S TEXT, which is how ruling B could be
#     "verified" without being true. A renderer that gathers every axis into a
#     perfect block and leaves the steps below reading their own literals
#     passes every static assertion anybody would think to write -- the
#     variables are there, spelled right, with the right values -- and is
#     worth exactly nothing, because editing them changes nothing. Section 4
#     therefore does not grep the block. It EDITS the block, on two lines, and
#     runs the file.
#
# THE FOUR TRAPS THIS FILE IS BUILT AROUND, each of which cost a sibling a
# revision this week:
#
#   A CHECK THAT COULD ONLY PASS. Every assertion here is anchored to a number
#   measured on BOTH trees. The 0 ink and the 1,490; the 48,870 bytes either
#   way; the block with two axis lines and the block with none; the replay at
#   140..320 and the replay at 120..500. A check whose "fail" side was never
#   observed is not in this file, and section 4 asserts BOTH directions of the
#   same comparison -- the edited replay must match a native draw at the
#   edited axis AND must NOT match the figure that was recorded. One of those
#   alone is satisfied by a replay that ignores its arguments entirely.
#
#   A CHECK THAT MATCHES THE COMMENT EXPLAINING THE FIX. Every static check
#   here reads code with comments STRIPPED. Both files carry long prose that
#   names the very procedures being checked for -- "@emlRecordAxisRequest"
#   appears in eight comment paragraphs and "Draw what you can" in two -- so
#   an unstripped grep would find the repair in the paragraph describing it
#   and call the wiring present after the call site was deleted. The break
#   `stem_branch_unreachable` is exactly that shape: every word of the prose
#   and every line of the stem code left in place, and one comparison changed
#   so the branch never runs.
#
#   A SIZE THRESHOLD. The empty one-bin spectrum weighs 48,870 bytes and the
#   drawn one 48,531 -- the empty one is the LARGER of the two, because an
#   empty PNG of a frame compresses differently from one with a hairline in
#   it. A threshold of 20 KB passes both; a threshold that tried to separate
#   them would have to say the bigger file is the broken one. Section 2
#   asserts ink inside the frame and records both byte counts beside it.
#
#   A CHECK ANCHORED ON FIRST-INK POSITION. v66 was bitten by this on the
#   axis-name ruling: a clipped element's first ink moves the WRONG WAY. The
#   equivalent trap here is the stem's TOP ROW, which is the whole of its
#   value: a stem drawn to the full height of the frame has a smaller top row
#   than a correct one, and a stem drawn at the naive dB is 96 rows lower.
#   Neither is caught by "there is ink". So the top row is compared against a
#   RULER TAKEN FROM PRAAT ITSELF -- the row where Praat's own `Draw:` puts
#   the same bin's vertex in the two-bin figure -- and the stem's foot and its
#   column are checked separately, because a mark can be right in one of the
#   three and wrong in the other two.
#
# WHAT THIS FILE DOES NOT TEST, SAID PLAINLY RATHER THAN LEFT TO BE FOUND.
# The graphs form's half of the axis contract -- publishing
# emlGraphsAxisYReqMin / emlGraphsAxisYReqMax where the user's values are
# first read, and not overwriting them in the bracket-headroom or legend-room
# passes -- belongs to plugin/graphs/eml-graphs-form.praat, which is another
# hand's file this week. Section 5 tests THIS side of that contract: that the
# recorder prefers the globals when they exist and falls back to its arguments
# when they do not. The `rec_form` leg publishes the globals itself, which
# proves the preference and does not prove the form sets them. That is stated
# here, in the harness, and in the report, rather than implied by a green tick.
#
# NOTHING HERE IS VALIDATED UNTIL IT HAS BEEN BROKEN. Every check in this file
# was shown RED against a deliberately broken COPY of the tree, driven through
# $EML_AS_SRC and read through $EML_AXIS_DRAW_SRC, $EML_AXIS_REC_SRC and
# $EML_AXISSPEC_DIR without touching the working tree. The breaks and their
# results are listed in harness/axisspec/break.sh and recorded in
# harness/axisspec/out/BREAKS.tsv.
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

ID <- "v67"

`%or%` <- function(a, b) if (is.null(a) || length(a) == 0L || is.na(a)) b else a

gdir <- Sys.getenv("EML_AXIS_DRAW_SRC", unset = "")
if (!nzchar(gdir)) gdir <- repo_path(file.path("plugin", "graphs"))
rdir <- Sys.getenv("EML_AXIS_REC_SRC", unset = "")
if (!nzchar(rdir)) rdir <- repo_path(file.path("plugin", "stats"))
adir <- Sys.getenv("EML_AXISSPEC_DIR", unset = "")
if (!nzchar(adir)) adir <- repo_path(file.path("harness", "axisspec", "out"))

f_draw <- file.path(gdir, "eml-draw-procedures.praat")
f_rec  <- file.path(rdir, "eml-record.praat")

check_true(ID, "the two files this change touches are present",
           all(file.exists(c(f_draw, f_rec))))

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS, AND STRIP COMMENTS BEFORE MATCHING.
# ---------------------------------------------------------------------------
# Both halves have bitten this repository, and both bite here. Every recorded
# call template in the draw file is written across five or six physical lines
# with "...", so a line-at-a-time regex sees a procedure name with no
# arguments and an argument list with no procedure. And both files carry long
# prose that names the procedures being checked for, so an unstripped grep
# would find "@emlRecordAxisRequest" in the paragraph explaining it and call
# the wiring present after every call site was deleted.
read_code <- function(path) {
    if (!file.exists(path)) return(character(0))
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
    norm[!grepl("^#", norm) & !grepl("^;", norm)]
}

code_draw <- read_code(f_draw)
code_rec  <- read_code(f_rec)

has <- function(code, pattern) any(grepl(pattern, code))
cnt <- function(code, pattern) sum(grepl(pattern, code))

proc_body_of <- function(code, name) {
    i <- grep(sprintf("^procedure %s(:|$)", name), code)
    if (!length(i)) return(character(0))
    j <- grep("^endproc\\b", code)
    j <- j[j > i[1]]
    if (!length(j)) return(character(0))
    code[(i[1] + 1L):(j[1] - 1L)]
}

# ---------------------------------------------------------------------------
# The harness TSV, scoped by leg, and a MULTI-VALUED reader beside it.
# ---------------------------------------------------------------------------
# Keys repeat across legs on purpose -- five record legs each publish
# `_blockline` -- so a flat name->value map would silently answer every one of
# them with the first. Rows are filed under the last `leg` marker seen; the
# shell writes `leg --shell--` before its own rows. The dbcheck leg publishes
# the same six keys five times, once per bin width, and those are read as a
# VECTOR: a check that looked only at the first would be satisfied by a dB
# conversion that happens to be right at one bin width, which is exactly what
# a wrong constant factor looks like.
read_legged_tsv <- function(path) {
    if (!file.exists(path)) return(list())
    x <- readLines(path, warn = FALSE)
    x <- x[nzchar(x)]
    out <- list(); leg <- ""
    for (ln in x) {
        p <- strsplit(ln, "\t", fixed = TRUE)[[1]]
        if (length(p) < 2L) next
        k <- p[1]; v <- paste(p[-1], collapse = "\t")
        if (identical(k, "leg")) { leg <- v; next }
        key <- if (nzchar(leg) && !identical(leg, "--shell--"))
                   paste0(leg, ".", k) else k
        if (is.null(out[[key]])) out[[key]] <- v
        else out[[key]] <- c(out[[key]], v)
    }
    out
}

as_ <- read_legged_tsv(file.path(adir, "AXISSPEC.tsv"))
have <- length(as_) > 0
av  <- function(k) if (is.null(as_[[k]])) NA_character_ else as_[[k]][1]
an  <- function(k) suppressWarnings(as.numeric(av(k)))
avv <- function(k) if (is.null(as_[[k]])) character(0) else as_[[k]]
anv <- function(k) suppressWarnings(as.numeric(avv(k)))

check_true(ID, "the axis/spectrum drive produced evidence (harness/axisspec/axisspec.sh)",
           have)
if (have) {
    check_true(ID,
        sprintf("and it ran on the supported binary (%s)", av("praat_version")),
        grepl("^Praat 6\\.6\\.3[0-9]|^Praat [7-9]", av("praat_version") %or% ""))
}

# ===========================================================================
# 1. THE CODE ITSELF
# ===========================================================================

# ---------------------------------------------------------------------------
# 1a. RULING A -- THE BRANCH, AND WHAT IT IS ALLOWED TO ASSUME
# ---------------------------------------------------------------------------
# Scoped to @emlDrawSpectrum's own body throughout. `Draw:` appears three more
# times in this file -- twice in @emlDrawLTAS, which draws an Ltas and not a
# Spectrum -- so an unscoped count would be satisfied by the wrong procedure.
sp <- proc_body_of(code_draw, "emlDrawSpectrum")
check_true(ID, "@emlDrawSpectrum exists and was found", length(sp) > 0)

# THE COUNT IS TAKEN FROM THE OBJECT, not from the width of the window. A
# repair that divided (freqMax - freqMin) by an assumed bin width would be
# right on this fixture and wrong on every zero-padded one, and Praat pads to
# a power of two on nearly all of them.
check_true(ID,
    "the draw asks the Spectrum how many bins are in the window",
    has(sp, "Get bin number from frequency: \\.freqMin") &&
    has(sp, "Get bin number from frequency: \\.freqMax") &&
    has(sp, "\\.binsInRange = \\.binHi - \\.binLo \\+ 1"))
# AND CLAMPS TO THE OBJECT'S OWN RANGE. A window starting below 0 Hz or
# ending past Nyquist otherwise asks for a bin that does not exist, which is
# an abort in the middle of a figure.
check_true(ID,
    "and clamps the bin range to the bins the Spectrum actually has",
    has(sp, "\\.nBins = Get number of bins") &&
    has(sp, "if \\.binLo < 1") &&
    has(sp, "if \\.binHi > \\.nBins"))

# THREE ARMS, AND THE THIRD ONE IS THE RULING'S OTHER HALF. Two-or-more bins
# is Praat's own `Draw:` untouched -- this is not a rewrite of the spectrum
# renderer and must not become one. One bin is the stem. Zero bins draws
# nothing, and there is no `else` for it to fall into.
check_true(ID,
    "two or more bins in range still go through Praat's own Draw:",
    has(sp, "^if \\.binsInRange >= 2$") &&
    has(sp, "^Draw: \\.freqMin, \\.freqMax, \\.powerMin, \\.powerMax, \"no\"$"))
check_true(ID,
    "exactly one bin is drawn as a mark that needs no second point",
    has(sp, "^elsif \\.binsInRange = 1$") &&
    has(sp, "^Draw line: \\.binFreq, \\.powerMin, \\.binFreq, \\.binDb$"))
# The scan is over the CHAIN and not over the procedure: @emlDrawSpectrum has
# two other if/else blocks above this one, resolving the auto frequency and
# power ranges, so a bare `!has(sp, "^else$")` would be answering about the
# wrong statement -- and would answer FALSE on a perfectly correct file, which
# is the shape of a check that gets "fixed" by weakening it.
chain_has_else <- function(body) {
    i <- grep("^if \\.binsInRange >= 2$", body)
    if (!length(i)) return(NA)
    depth <- 1L; j <- i[1] + 1L
    while (j <= length(body) && depth > 0L) {
        ln <- body[j]
        if (grepl("^if ", ln)) depth <- depth + 1L
        else if (grepl("^endif$", ln)) depth <- depth - 1L
        else if (depth == 1L && grepl("^else$", ln)) return(TRUE)
        j <- j + 1L
    }
    FALSE
}
check_true(ID,
    "and zero bins in range draws nothing at all -- the chain has no else arm",
    identical(chain_has_else(sp), FALSE))

# THE dB IS THE SPECTRAL DENSITY, WHICH IS WHAT PRAAT DRAWS. The naive power
# formula is 10*log10 of twice the bin width too low -- 10.32 dB on the short
# fixture, 96 image rows -- and produces a stem of exactly the right shape at
# the wrong height, which is worse than no stem because it looks measured.
check_true(ID,
    "the stem's height uses the bin-width factor Praat's own Draw: uses",
    has(sp, "\\.binDb = 10 \\* log10 \\(2 \\* \\.binWidth \\* \\.binPower / 4e-10\\)") &&
    has(sp, "\\.binWidth = Get bin width"))
# THE STEM IS AT THE BIN, NOT AT THE MIDDLE OF THE WINDOW. The wrong
# implementation is simpler than the right one -- it needs no bin query at all
# -- and on this fixture the two are 420 px apart.
check_true(ID,
    "and it stands at the bin's own frequency",
    has(sp, "\\.binFreq = Get frequency from bin number: \\.binLo"))
# CLIPPED AT THE TOP THE WAY THE CURVE IS, AND REFUSED AT THE BOTTOM. "Draw
# what you can" is not "draw something regardless": a bin below the axis floor
# is a point off the paper and Praat does not plot it either.
check_true(ID,
    "the stem is clipped at the axis ceiling",
    has(sp, "if \\.binDb > \\.powerMax"))
check_true(ID,
    "and refused when the bin falls below the axis floor",
    has(sp, "if \\.binDb > \\.powerMin"))
# THE VERDICT IS PUBLISHED, so that a harness can ask what the draw decided
# rather than infer it from pixels. A leg whose figure is empty and whose
# oneBinDrawn is 1 is a different finding from one where both agree.
check_true(ID,
    "the draw publishes what it decided, for a rig to read back",
    has(sp, "\\.oneBinDrawn = 0") && has(sp, "\\.oneBinDrawn = 1"))

# ---------------------------------------------------------------------------
# 1b. RULING B -- THE AXIS MAP, CENSUSED IN BOTH DIRECTIONS
# ---------------------------------------------------------------------------
# @emlRecordColumnSpec is a hand-maintained table of which arguments of which
# procedure carry an axis range. It is the right place for it -- one table
# beats fourteen call sites each deciding for itself -- and the price is that
# it can fall behind the signatures it does not own. A draw procedure that
# starts recording without an entry here lifts nothing, and its emitted script
# keeps the literals under a block that promises otherwise: the original
# defect, returning one figure type at a time. This is v58 section 8's lesson
# applied to the second table, and it is why the census runs BOTH ways -- a
# misspelled key never matches, lifts nothing, and is invisible.
axis_spec_lines <- grep('^(els)?if \\.axisProc\\$ = "', code_rec, value = TRUE)
axis_map <- sub('.*\\.axisProc\\$ = "([^"]*)".*', "\\1", axis_spec_lines)
axis_map <- sort(unique(axis_map))

# The recorded call TEMPLATES, out of the draw file: every string that emits
# `@emlDrawSomething: data`. Continuations are already folded, which is not
# tidiness -- the violin's template is six physical lines and the procedure
# name is on the first.
# THE CHARACTER CLASS INCLUDES DIGITS AND THE LOOKAHEAD STOPS AT `data`, not
# at `data"`. @emlDrawF0Contour has a digit in its name, and @emlRecordViolin
# builds its template as `"@emlDrawViolinPlot: data, """ + .title$`, so the two
# obvious spellings of this regex miss exactly those two procedures -- and a
# census that silently drops the two it is meant to police reads, from the
# outside, identical to one that passes. Both were dropped on the first run of
# this file and the count check below is what said so.
tmpl <- code_draw[grepl('"@emlDraw[A-Za-z0-9]+: data', code_draw)]
tmpl_procs <- sort(unique(unlist(regmatches(tmpl,
    gregexpr('(?<=")@emlDraw[A-Za-z0-9]+(?=: data)', tmpl, perl = TRUE)))))
tmpl_procs <- sub("^@", "", tmpl_procs)

check_true(ID,
    sprintf("every draw procedure that records a call is found (%d)",
            length(tmpl_procs)),
    length(tmpl_procs) >= 13)
missing_axis <- setdiff(tmpl_procs, axis_map)
dead_axis    <- setdiff(axis_map, tmpl_procs)
check_true(ID,
    sprintf("every recorded draw call has an axis-map entry (%d mapped)",
            length(axis_map)),
    length(missing_axis) == 0)
if (length(missing_axis)) {
    check_true(ID, paste("unmapped:", paste(missing_axis, collapse = ", ")),
               FALSE)
}
check_true(ID,
    sprintf("and every axis-map entry names a call that exists (%s)",
            if (length(dead_axis)) paste(dead_axis, collapse = ", ") else "none dead"),
    length(dead_axis) == 0)

# THE SLOT NUMBERS ARE CHECKED AGAINST THE SIGNATURES THEY DESCRIBE, which is
# the half a name census cannot reach. An entry that names the right procedure
# and points at argument 12 instead of 11 lifts the value column into an axis
# variable, and the emitted script then either aborts or draws the wrong
# figure. The signature is read from the draw file and counted, `data` being
# argument 1 exactly as the map's own header says.
sig_of <- function(nm) {
    ln <- grep(sprintf("^procedure %s:", nm), code_draw, value = TRUE)
    if (!length(ln)) return(character(0))
    args <- strsplit(sub(sprintf("^procedure %s: *", nm), "", ln[1]), ",")[[1]]
    trimws(args)
}
# What the map says, as (proc -> min slot, max slot).
map_slots <- list()
for (ln in axis_spec_lines) {
    nm <- sub('.*\\.axisProc\\$ = "([^"]*)".*', "\\1", ln)
    i <- match(ln, code_rec)
    # The assignment is the next non-comment statement in the folded code.
    j <- i + 1L
    while (j <= length(code_rec) && !grepl("^\\.axisSpec\\$ = ", code_rec[j])) j <- j + 1L
    if (j <= length(code_rec)) {
        v <- sub('^\\.axisSpec\\$ = "([^"]*)".*', "\\1", code_rec[j])
        p <- strsplit(v, " ")[[1]]
        if (length(p) == 3L) map_slots[[nm]] <- p
    }
}
check_true(ID,
    sprintf("every axis-map entry carries a min slot, a max slot and a role (%d)",
            length(map_slots)),
    length(map_slots) == length(axis_map) && length(map_slots) >= 13)
bad_slots <- character(0)
for (nm in names(map_slots)) {
    s <- sig_of(nm)
    if (!length(s)) { bad_slots <- c(bad_slots, paste0(nm, ":nosig")); next }
    lo <- suppressWarnings(as.integer(map_slots[[nm]][1]))
    hi <- suppressWarnings(as.integer(map_slots[[nm]][2]))
    # The slot names must be a min/max PAIR and must be adjacent: every axis
    # range in this library is written (min, max) side by side, and an entry
    # that straddles some other argument is a transcription error rather than
    # a design.
    okpair <- !is.na(lo) && !is.na(hi) && hi == lo + 1L &&
              lo >= 1L && hi <= length(s) &&
              grepl("M(in|ax)$", s[lo]) && grepl("M(in|ax)$", s[hi]) &&
              grepl("Min$", s[lo]) && grepl("Max$", s[hi])
    if (!okpair) bad_slots <- c(bad_slots,
        sprintf("%s:%s(%s,%s)", nm, paste(map_slots[[nm]][1:2], collapse = "-"),
                s[lo] %or% "?", s[hi] %or% "?"))
}
check_true(ID,
    sprintf("and every one of them points at an adjacent Min/Max pair in that procedure's own signature (%s)",
            if (length(bad_slots)) paste(bad_slots, collapse = "; ") else "all 14 agree"),
    length(bad_slots) == 0)
# THE HISTOGRAM IS THE ONE THAT IS NOT A Y AXIS, and it is pinned so that a
# later tidy-up does not "finish the job" by renaming it. Its dialog says
# "Value maximum / Value minimum" and those bound the axis it draws
# HORIZONTALLY; its vertical axis is a count with a single frequency maximum
# over a hard floor of zero, which is not a pair and has no (0,0) sentinel.
check_true(ID,
    "the histogram's pair is named for the axis it really bounds, not for a letter",
    identical(map_slots[["emlDrawHistogram"]], c("13", "14", "axisValue")))
check_true(ID,
    sprintf("and every other draw type's pair is the y-axis (%d of them)",
            sum(vapply(map_slots, function(p) identical(p[3], "axisY"), TRUE))),
    sum(vapply(map_slots, function(p) identical(p[3], "axisY"), TRUE)) ==
        length(map_slots) - 1L)

# ---------------------------------------------------------------------------
# 1c. THE NUMERIC LIFT, AND THE ONE THING IT MUST NOT COPY
# ---------------------------------------------------------------------------
ql <- proc_body_of(code_rec, "emlRecordQuotedLiteral")
check_true(ID, "@emlRecordQuotedLiteral grew a numeric path",
           length(ql) > 0 && any(grepl("\\.isNum = 1", ql)))
# THE GUARD IS THE POINT, not the extraction -- same doctrine as the quoted
# path. Anything that is not unambiguously one number is left where it was
# recorded, because a literal left un-lifted is a blemish and a mangled call
# is a broken script.
check_true(ID,
    "and it refuses anything that is not one plain number",
    any(grepl("\\.bad = 1", ql)) &&
    any(grepl("if \\.bad = 0 and \\.digits > 0 and \\.dots < 2", ql)))

cm <- proc_body_of(code_rec, "emlRecordColumnManifest")
check_true(ID, "@emlRecordColumnManifest exists and was found", length(cm) > 0)
# ZERO IS NOT ABSENT. The column path skips a literal of "" because a role the
# session did not use has no business in the block. Copying that guard onto
# the axis path would skip (0, 0) -- which is the one value ruling B exists to
# preserve -- and would put the resolved numbers back in the step. The check
# is that the axis lift is guarded on `.aIsNum = 1` and on nothing else.
check_true(ID,
    "the axis lift is guarded on 'is a number' and not on 'is non-empty'",
    any(grepl("^if \\.aIsNum = 1$", cm)) &&
    !any(grepl("\\.aMinLit\\$ <> \"\"", cm)))
# BOTH SLOTS OR NEITHER. A half-lifted range leaves the block able to move one
# end of an axis and not the other.
check_true(ID,
    "and both ends of the range are lifted together or not at all",
    any(grepl("\\.aIsNum = \\.aIsNum \\* emlRecordQuotedLiteral\\.isNum", cm)))
# THE PAIR IS THE UNIT OF IDENTITY. Matching on the minimum alone would share
# one axisYMin between a figure on AUTO and a figure whose floor is zero.
check_true(ID,
    "a pair is matched on BOTH its ends before it is shared between steps",
    any(grepl("if \\.axMinLit\\$\\[\\.k\\] = \\.aMinOut\\$", cm)) &&
    any(grepl("if \\.axMaxLit\\$\\[\\.k\\] = \\.aMaxOut\\$", cm)))
# AND THE SENTINEL IS WRITTEN THE WAY THE AUTHOR ASKED FOR IT.
check_true(ID,
    "an auto range is written 0.0, which is the ruling's own spelling",
    any(grepl("^\\.aMinOut\\$ = \"0\\.0\"$", cm)) &&
    any(grepl("^\\.aMaxOut\\$ = \"0\\.0\"$", cm)))

# ---------------------------------------------------------------------------
# 1d. THE INTERFACE CONTRACT, ON THIS SIDE OF IT
# ---------------------------------------------------------------------------
ar <- proc_body_of(code_rec, "emlRecordAxisRequest")
check_true(ID, "@emlRecordAxisRequest exists", length(ar) > 0)
check_true(ID,
    "it prefers the form's untouched request when the form published one",
    any(grepl("variableExists \\(\"emlGraphsAxisYReqMin\"\\)", ar)) &&
    any(grepl("variableExists \\(\"emlGraphsAxisYReqMax\"\\)", ar)) &&
    any(grepl("^\\.min = emlGraphsAxisYReqMin$", ar)))
# THE FALLBACK IS NOT A COURTESY. Nothing outside the graphs form sets those
# globals -- the API export, the batch module, every harness in this tree and
# any user script calling a draw procedure directly -- and for every one of
# them the argument IS the request. A version without the guard aborts on all
# of them.
check_true(ID,
    "and falls back to its own arguments when no form ran",
    any(grepl("^\\.min = \\.fbMin$", ar)) &&
    any(grepl("^\\.max = \\.fbMax$", ar)))
# BOTH OR NEITHER: a caller that published only one global would otherwise get
# a minimum from the form and a maximum from the draw, and the (0,0) sentinel
# cannot survive that.
check_true(ID,
    "and reads the two globals as a pair, never one of them",
    any(grepl("variableExists \\(\"emlGraphsAxisYReqMax\"\\)", ar)) &&
    sum(grepl("^\\.fromForm = 1$", ar)) == 1L)

# EVERY RECORDER IS WIRED, AND THE COUNT IS THE CHECK. Thirteen draw
# procedures record through @emlRecordDrawStep and the violin has its own
# recorder; a repair that wired twelve of fourteen leaves two figure types
# quietly recording the form's resolution as though the user had typed it.
n_tmpl <- length(tmpl_procs)
check_true(ID,
    sprintf("every recorder asks for the user's request (%d calls, %d templates)",
            cnt(code_draw, "^@emlRecordAxisRequest:"), n_tmpl),
    cnt(code_draw, "^@emlRecordAxisRequest:") == n_tmpl)
check_true(ID,
    sprintf("and every recorder files the resolved axis beside it (%d calls)",
            cnt(code_draw, "^@emlRecordAxisNote:")),
    cnt(code_draw, "^@emlRecordAxisNote:") == n_tmpl)
# AND THE REQUEST IS ACTUALLY USED. A call whose result is discarded compiles,
# runs, and satisfies the two counts above.
check_true(ID,
    sprintf("and none of them throws the answer away (%d read .min, %d read .max)",
            cnt(code_draw, "= emlRecordAxisRequest\\.min"),
            cnt(code_draw, "= emlRecordAxisRequest\\.max")),
    cnt(code_draw, "= emlRecordAxisRequest\\.min") == n_tmpl &&
    cnt(code_draw, "= emlRecordAxisRequest\\.max") == n_tmpl)

# THE BLOCK'S OWN SENTENCE HAD TO GROW WITH THE PROMISE. It said "nothing
# below this block names an object or a column" while every draw step below it
# carried its axis as two bare literals. A block that tells the truth about
# two of three things is the shape of the original defect.
# The promise is EMITTED AS TWO LINES, so a grep for one source line can be
# satisfied while the sentence a reader actually sees has lost the axis. Join
# the emitted literals and read the sentence, not the source layout.
promise_lit <- function(code, start) {
    ln <- grep(paste0('\\+ "# ', start), code, value = TRUE)
    if (!length(ln)) return("")
    sub('.*\\+ "#([^"]*)".*', "\\1", ln[1])
}
promise_txt <- paste0(promise_lit(code_rec, "nothing below this block"),
                      promise_lit(code_rec, "range or"))
check_true(ID,
    "the block's promise now covers the axis range as well",
    grepl("an axis range", promise_txt, fixed = TRUE))

# ===========================================================================
# 2. RULING A, DRIVEN: ONE BIN, TWO BINS, NO BINS, AND ONE BELOW THE FLOOR
# ===========================================================================
if (have) {
    # THE FIXTURE IS WHAT IT CLAIMS TO BE. An empty frame proves nothing if
    # the window secretly held no bins, and a drawn one proves nothing if it
    # held three.
    check_true(ID,
        sprintf("the short fixture really is a one-bin window (%s bins at %s Hz per bin, window %s..%s)",
                av("onebin.onebin_bins_in_range"), av("onebin.onebin_bin_width"),
                av("onebin.onebin_window_lo"), av("onebin.onebin_window_hi")),
        identical(av("onebin.onebin_bins_in_range"), "1"))
    check_true(ID,
        sprintf("and the bin it holds is the peak of the tone (%s dB at %s Hz)",
                av("onebin.onebin_peak_db"), av("onebin.onebin_peak_freq")),
        is.finite(an("onebin.onebin_peak_db")) &&
        an("onebin.onebin_peak_db") > 60)
    # THE SHORTNESS IS THE FINDING. A bin width this wide is what makes an
    # ordinary four-hertz zoom reach the defect; if the fixture drifts long,
    # this file quietly goes back to testing a curiosity.
    check_true(ID,
        sprintf("the fixture is a SHORT token, so an ordinary zoom reaches it (%s Hz bins; %s Hz of window)",
                av("onebin.onebin_bin_width"),
                format(an("onebin.onebin_window_hi") - an("onebin.onebin_window_lo"))),
        is.finite(an("onebin.onebin_bin_width")) &&
        an("onebin.onebin_bin_width") > 3 &&
        (an("onebin.onebin_window_hi") - an("onebin.onebin_window_lo")) >= 3)
    check_true(ID,
        sprintf("the draw agrees with the probe about how many bins it had (%s)",
                av("onebin.onebin_proc_bins_in_range")),
        identical(av("onebin.onebin_proc_bins_in_range"),
                  av("onebin.onebin_bins_in_range")))
    check_true(ID, "and it took the one-bin branch",
        identical(av("onebin.onebin_drawn_one_bin"), "1"))

    # INK INSIDE THE FRAME, WHICH IS THE MEASUREMENT THE FILE SIZE IS NOT.
    check_true(ID,
        sprintf("the one-bin spectrum now has ink inside its frame (%s; it was 0 at HEAD)",
                av("onebin_interior_ink")),
        is.finite(an("onebin_interior_ink")) && an("onebin_interior_ink") > 100)
    check_true(ID,
        sprintf("while the two-bin control still draws normally (%s ink)",
                av("twobin_interior_ink")),
        is.finite(an("twobin_interior_ink")) && an("twobin_interior_ink") > 100)
    check_true(ID, "and the two-bin control did NOT take the one-bin branch",
        identical(av("twobin.twobin_drawn_one_bin"), "0"))

    # ZERO BINS STAYS EMPTY, WHICH IS THE OTHER HALF OF THE RULING AND THE
    # ONE A "make it draw something" repair fails.
    check_true(ID,
        sprintf("a window holding NO bin really holds none (%s)",
                av("zerobin.zerobin_bins_in_range")),
        identical(av("zerobin.zerobin_bins_in_range"), "0"))
    check_true(ID,
        sprintf("and it is left empty, because there is nothing to draw (%s ink)",
                av("zerobin_interior_ink")),
        identical(av("zerobin_interior_ink"), "0"))

    # ONE BIN, BELOW THE FLOOR THE USER ASKED FOR. "Draw what you can" is not
    # "draw something regardless"; a point off the paper is not plotted, and a
    # stem pinned to the floor whatever the data said would be a figure that
    # lies in exactly the direction the original defect did.
    check_true(ID,
        sprintf("a lone bin under the axis floor is one bin (%s) and is under it (%s dB against a floor of %s)",
                av("onebin_below.below_bins_in_range"),
                av("onebin_below.below_peak_db"), av("onebin_below.below_floor")),
        identical(av("onebin_below.below_bins_in_range"), "1") &&
        is.finite(an("onebin_below.below_peak_db")) &&
        an("onebin_below.below_peak_db") < an("onebin_below.below_floor"))
    check_true(ID,
        sprintf("and it is refused rather than pinned to the floor (%s ink, drawn=%s)",
                av("onebin_below_interior_ink"), av("onebin_below.below_drawn_one_bin")),
        identical(av("onebin_below_interior_ink"), "0") &&
        identical(av("onebin_below.below_drawn_one_bin"), "0"))

    # THE AUDITOR'S OWN FIXTURE, so that the long token and the short one are
    # shown to be the same finding at two durations rather than two findings.
    check_true(ID,
        sprintf("the long 1.49 s fixture is the same finding at a different bin width (%s Hz, %s bin)",
                av("onebin_long.long_bin_width"), av("onebin_long.long_bins_in_range")),
        identical(av("onebin_long.long_bins_in_range"), "1") &&
        is.finite(an("onebin_long.long_bin_width")) &&
        an("onebin_long.long_bin_width") < 1)
    check_true(ID,
        sprintf("and it draws now too (%s ink)", av("onebin_long_interior_ink")),
        is.finite(an("onebin_long_interior_ink")) &&
        an("onebin_long_interior_ink") > 100)

    # ---- THE MARK ITSELF: HEIGHT, FOOT AND COLUMN, EACH SEPARATELY --------
    #
    # THE RULER IS PRAAT'S OWN OUTPUT AND NOT AN ASSUMED GEOMETRY. Bin 187 is
    # in the one-bin window and in the two-bin window and is the peak of both.
    # In the two-bin figure Praat's `Draw:` puts a polyline vertex at that
    # bin's value; in the one-bin figure this plugin puts the tip of a stem
    # there. Same figure size, same y-range, so the two land on the same image
    # ROW if and only if the dB conversion is Praat's. Measured 16 Aug 2026:
    # 174 and 175, one row apart, which is 0.107 dB on this axis. The naive
    # power formula would put the tip 96 rows lower.
    check_true(ID,
        sprintf("the stem's tip is where Praat's own Draw: puts the same bin (%s against %s)",
                av("onebin_top_row"), av("twobin_top_row")),
        is.finite(an("onebin_top_row")) && is.finite(an("twobin_top_row")) &&
        abs(an("onebin_top_row") - an("twobin_top_row")) <= 3)
    # THE FOOT, WHICH IS A SEPARATE CLAIM. A mark can be at the right height
    # and be a floating dash. The stem runs to the frame floor, so its lowest
    # ink is within a line's width of the bottom of the interior crop (920 px
    # tall). A dot at the bin's value has a bottom row equal to its top row,
    # and passes the height check on its own.
    check_true(ID,
        sprintf("and it is a stem to the frame floor, not a floating mark (foot at row %s of 920)",
                av("onebin_bottom_row")),
        is.finite(an("onebin_bottom_row")) && an("onebin_bottom_row") >= 910)
    # THE COLUMN. A stem at the middle of the WINDOW needs no bin query at
    # all, is the obvious wrong implementation, and passes both checks above.
    # The expected column is calibrated from the two-bin figure -- Praat's own
    # polyline endpoints ARE bins 186 and 187 -- so no panel geometry is
    # assumed anywhere in this file.
    if (all(is.finite(c(an("twobin_col_first"), an("twobin_col_last"),
                        an("onebin_col_first"), an("onebin_col_last"))))) {
        b186 <- 995.9110; b187 <- 1001.2939
        f186 <- (b186 - an("twobin.twobin_window_lo")) /
                (an("twobin.twobin_window_hi") - an("twobin.twobin_window_lo"))
        f187 <- (b187 - an("twobin.twobin_window_lo")) /
                (an("twobin.twobin_window_hi") - an("twobin.twobin_window_lo"))
        kx <- (an("twobin_col_last") - an("twobin_col_first")) / (f187 - f186)
        ax <- an("twobin_col_first") - kx * f186
        f1 <- (b187 - an("onebin.onebin_window_lo")) /
              (an("onebin.onebin_window_hi") - an("onebin.onebin_window_lo"))
        want <- ax + kx * f1
        got  <- (an("onebin_col_first") + an("onebin_col_last")) / 2
        centre <- ax + kx * 0.5
        check_true(ID,
            sprintf("the stem stands at the BIN's frequency (column %.0f, wanted %.0f; the window's middle is %.0f)",
                    got, want, centre),
            abs(got - want) <= 4)
        check_true(ID,
            sprintf("and the two are far enough apart for that to mean something (%.0f px)",
                    abs(want - centre)),
            abs(want - centre) > 100)
        check_true(ID,
            sprintf("and the mark is one line wide, which is what makes it a stem (%.0f px)",
                    an("onebin_col_last") - an("onebin_col_first") + 1),
            (an("onebin_col_last") - an("onebin_col_first") + 1) <= 8)
    } else {
        check_true(ID, "the stem's column was measurable", FALSE)
    }

    # ---- THE dB CONVERSION, AGAINST PRAAT'S OWN, AT FIVE BIN WIDTHS ------
    # EXACT, not a tolerance: these are the same number computed two ways.
    # Five widths, because a wrong constant factor is right at one of them.
    d_delta <- anv("dbcheck.db_delta")
    d_gap   <- anv("dbcheck.db_naive_gap")
    check_true(ID,
        sprintf("the dB conversion was checked at %d different bin widths",
                length(d_delta)),
        length(d_delta) >= 5)
    # THE TOLERANCE IS 1e-9 AND IT IS NOT A HEDGE. Both sides are computed in
    # double precision from the same two floats, so any residual is last-bit --
    # and it is VISIBLE at all only because `fixed$` escalates: asked for nine
    # decimals it printed a 1e-14 residual to fourteen. Nine decimals is the
    # print precision, and what is being ruled out is a 7-to-13 dB error, so
    # this is eleven orders of magnitude of margin on either side.
    check_true(ID,
        sprintf("and agrees with Praat's own To Ltas (1-to-1) at every one (max |delta| %s)",
                if (length(d_delta)) format(max(abs(d_delta))) else "n/a"),
        length(d_delta) >= 5 && all(is.finite(d_delta)) &&
        max(abs(d_delta)) < 1e-9)
    # AND THE NAIVE FORMULA IS NOT A NEAR MISS -- it is a real gap that varies
    # with bin width, which is what makes it a fix-shaped fix rather than a
    # rounding difference.
    check_true(ID,
        sprintf("while the naive power formula is wrong by a bin-width-dependent margin (%s dB)",
                if (length(d_gap)) paste(format(round(d_gap, 2)), collapse = ", ") else "n/a"),
        length(d_gap) >= 5 && all(d_gap > 5) && length(unique(round(d_gap, 3))) > 1)

    # THE TRAP, SAID AS TWO NUMBERS. The empty frame is the BIGGER file.
    attest(ID,
        sprintf("the empty one-bin frame weighed 48,870 bytes at HEAD and the drawn one weighs %s -- a size threshold cannot separate them, and would call the bigger file the good one",
                av("onebin_bytes")),
        "measured 16 August 2026 on 6.6.30, short fixture, 998..1002 Hz")
}

# ===========================================================================
# 3. RULING B, DRIVEN: WHAT THE EMITTED BLOCK SAYS
# ===========================================================================
# Read out of the file a user would run, not out of a variable inside the
# process that wrote it.
blockline <- function(leg, want) {
    ls <- avv(paste0(leg, "_blockline"))
    ls[grepl(want, ls)]
}
if (have) {
    check_true(ID, "the auto session emitted a script",
               identical(av("rec_auto_emitted"), "yes"))
    # THE SENTINEL IS IN THE BLOCK, IN THE AUTHOR'S OWN SPELLING.
    amin <- blockline("rec_auto", "^axisYMin ")
    amax <- blockline("rec_auto", "^axisYMax ")
    check_true(ID,
        sprintf("the block carries the axis minimum as the auto sentinel (%s)",
                amin[1] %or% "<absent>"),
        length(amin) == 1L && grepl("^axisYMin +ean?= 0\\.0|^axisYMin += 0\\.0", amin[1]))
    check_true(ID,
        sprintf("and the axis maximum (%s)", amax[1] %or% "<absent>"),
        length(amax) == 1L && grepl("^axisYMax += 0\\.0", amax[1]))
    # AND IT SAYS IT IS AUTO, which is the first clause of the ruling.
    check_true(ID, "and the block SAYS the axis was automatic",
        length(amin) == 1L && grepl("AUTO", amin[1]))
    # AND WHAT IT RESOLVED TO, which is the second clause. Without this a user
    # who opens the file has no way to know what to type instead except to run
    # it and look.
    check_true(ID,
        sprintf("and what it resolved to on the recorded data (%s; the draw resolved %s .. %s)",
                sub("^.*resolved to ", "", amax[1] %or% ""),
                av("rec_auto.rec_auto_resolved_min"),
                av("rec_auto.rec_auto_resolved_max")),
        length(amax) == 1L &&
        grepl(sprintf("resolved to %s \\.\\. %s$",
                      av("rec_auto.rec_auto_resolved_min"),
                      av("rec_auto.rec_auto_resolved_max")), amax[1]))
    # THE STEP READS THE BLOCK. This is the half that makes the two lines
    # above worth anything at all, and section 4 is the half that makes THIS
    # one worth anything.
    check_true(ID,
        sprintf("and the draw step reads them rather than its own literals (%s)",
                av("rec_auto_violin_call")),
        identical(trimws(av("rec_auto_violin_call") %or% ""),
                  "axisYMin, axisYMax"))
    check_true(ID, "and the block's own sentence covers the axis",
        identical(av("rec_auto_block_promise"), "1"))

    # THE MIRROR: A RANGE THE USER TYPED IS RECORDED AS THE NUMBERS THEY
    # TYPED. A repair that hardcoded the sentinel would satisfy every check
    # above and would throw away every axis anybody ever set.
    nmin <- blockline("rec_noform", "^axisYMin ")
    nmax <- blockline("rec_noform", "^axisYMax ")
    check_true(ID,
        sprintf("an explicit range is carried as the numbers the user typed (%s / %s)",
                nmin[1] %or% "<absent>", nmax[1] %or% "<absent>"),
        length(nmin) == 1L && grepl("^axisYMin += 150 ", nmin[1]) &&
        length(nmax) == 1L && grepl("^axisYMax += 400 ", nmax[1]))
    check_true(ID, "and it is NOT labelled automatic",
        length(nmin) == 1L && !grepl("AUTO", nmin[1]) &&
        grepl("as typed", nmin[1]))
    check_true(ID,
        sprintf("and the draw honoured it rather than resolving from the data (%s .. %s)",
                av("rec_noform.rec_noform_resolved_min"),
                av("rec_noform.rec_noform_resolved_max")),
        identical(av("rec_noform.rec_noform_resolved_min"), "150.0000") &&
        identical(av("rec_noform.rec_noform_resolved_max"), "400.0000"))

    # TWO DRAW TYPES IN ONE SESSION, one auto and one typed, so that the block
    # has to carry both kinds at once. The spectrum also proves the lift is
    # not keyed on ruling 9's COLUMN map: a spectrum draws an object whole and
    # names no column, so a lift that walked the column table would skip every
    # acoustic figure in the library.
    check_true(ID,
        sprintf("a session with two figure kinds declares two pairs (%d lines)",
                length(avv("rec_two_blockline"))),
        length(avv("rec_two_blockline")) == 4L)
    check_true(ID,
        sprintf("and the SPECTRUM's power range is lifted too, though it names no column (%s)",
                av("rec_two_spectrum_call")),
        grepl("axisYMin2, axisYMax2$", trimws(av("rec_two_spectrum_call") %or% "")))
    t2min <- blockline("rec_two", "^axisYMin2 ")
    check_true(ID,
        sprintf("as the numbers it was given, in its own second pair (%s)",
                t2min[1] %or% "<absent>"),
        length(t2min) == 1L && grepl("^axisYMin2 += 20 ", t2min[1]))

    # ---- THE PAIR RULE, WHICH IS THE ONE PLACE THIS DIFFERS FROM RULING 9's
    # COLUMNS. Three figures: a violin on AUTO (0, 0), a box with a typed
    # floor of zero (0, 120), and a bar chart with the same floor and a
    # different ceiling (0, 300). A lift that takes each NUMBER as its own
    # variable sees "0" in the axisYMin role three times; it keeps the auto
    # one apart by accident, because 0.0 and 0 are different strings, and then
    # SHARES one axisYMin2 between the box and the bar -- which makes the
    # bar's call read the box's maximum and redraws the bar at 0..120 without
    # anybody asking.
    #
    # THE THIRD FIGURE IS WHY THIS IS A TEST. With only the auto and one typed
    # range the two minima are "0.0" and "0" and even a per-number lift keeps
    # them apart, so the check would be green on the defect. The shape that
    # shows it is two TYPED ranges agreeing at one end, which is also the
    # commonest thing anybody does: every bar chart in the world has a floor
    # of zero.
    check_true(ID,
        sprintf("three ranges that agree at one end get three separate pairs (%d declarations)",
                length(avv("rec_pairs_blockline"))),
        length(avv("rec_pairs_blockline")) == 6L)
    pmin1 <- blockline("rec_pairs", "^axisYMin ")
    pmin2 <- blockline("rec_pairs", "^axisYMin2 ")
    pmin3 <- blockline("rec_pairs", "^axisYMin3 ")
    check_true(ID,
        sprintf("the auto one is the sentinel (%s)", pmin1[1] %or% "<absent>"),
        length(pmin1) == 1L && grepl("= 0\\.0 ", pmin1[1]) &&
        grepl("AUTO", pmin1[1]))
    check_true(ID,
        sprintf("and the typed floor of zero is a SECOND variable, not the same one (%s)",
                pmin2[1] %or% "<absent>"),
        length(pmin2) == 1L && grepl("^axisYMin2 += 0 ", pmin2[1]) &&
        !grepl("AUTO", pmin2[1]))
    check_true(ID,
        sprintf("and a second typed range sharing that floor is a THIRD, not a reuse (%s)",
                pmin3[1] %or% "<absent>"),
        length(pmin3) == 1L && grepl("^axisYMin3 += 0 ", pmin3[1]))
    check_true(ID,
        sprintf("and the three steps read the three different pairs (%s | %s | %s)",
                av("rec_pairs_violin_call"), av("rec_pairs_box_call"),
                av("rec_pairs_bar_call")),
        identical(trimws(av("rec_pairs_violin_call") %or% ""),
                  "axisYMin, axisYMax") &&
        identical(trimws(av("rec_pairs_box_call") %or% ""),
                  "axisYMin2, axisYMax2") &&
        identical(trimws(av("rec_pairs_bar_call") %or% ""),
                  "axisYMin3, axisYMax3"))
}

# ===========================================================================
# 4. THE DRIVE -- THE BLOCK IS LOAD-BEARING, WHICH NO GREP CAN SAY
# ===========================================================================
# A renderer that gathers every axis into a perfect block and leaves the steps
# below reading their own literals passes every check in section 3 and is
# worth exactly nothing. So the block is edited on two lines -- 0.0/0.0 to
# 120/500 -- nothing else in the file is touched, and the file is RUN.
#
# BOTH DIRECTIONS OF THE COMPARISON ARE ASSERTED. The edited replay must be
# the figure a native draw produces at 120..500, byte for byte, AND must NOT
# be the figure that was recorded. A check on the first alone is satisfied by
# any replay that happens to draw something; a check on the second alone is
# satisfied by a replay that is broken in any way whatsoever.
if (have) {
    check_true(ID,
        sprintf("the retarget edited exactly the two axis declarations (%s)",
                av("edit_lines_changed")),
        identical(av("edit_lines_changed"), "2"))
    check_true(ID,
        sprintf("and edited nothing below the block (%s lines)",
                av("edit_below_block")),
        identical(av("edit_below_block"), "0"))
    check_true(ID,
        sprintf("the edited file drew on the axis the block now names (%s .. %s; native draw says %s .. %s)",
                av("replay_edited_min"), av("replay_edited_max"),
                av("native_edited.native_edited_min"),
                av("native_edited.native_edited_max")),
        is.finite(an("replay_edited_min")) &&
        abs(an("replay_edited_min") - an("native_edited.native_edited_min")) < 1e-6 &&
        abs(an("replay_edited_max") - an("native_edited.native_edited_max")) < 1e-6)
    check_true(ID,
        "and the figure it drew is the figure a native draw produces there, byte for byte",
        identical(av("edited_matches_native"), "yes"))
    check_true(ID,
        "while NOT being the figure that was recorded -- which is what says the edit did the work",
        identical(av("edited_matches_recorded"), "no"))
    check_true(ID,
        sprintf("and there is ink inside both frames, so neither comparison is between two empty ones (%s and %s)",
                av("replay_edited_interior_ink"), av("rec_auto_interior_ink")),
        is.finite(an("replay_edited_interior_ink")) &&
        an("replay_edited_interior_ink") > 100 &&
        is.finite(an("rec_auto_interior_ink")) &&
        an("rec_auto_interior_ink") > 100)

    # ---- v58's STANDING CONTRACT, RE-ASSERTED HERE BECAUSE THIS CHANGE
    # COULD HAVE BROKEN IT AND NOTHING ELSE WOULD HAVE NOTICED. An UNEDITED
    # replay must still reproduce its original figure and its original numbers
    # exactly on unchanged data. This is also what stops section 4 being
    # satisfied by a replay that ignores its arguments entirely.
    check_true(ID,
        sprintf("an unedited replay still resolves the axis it recorded (%s .. %s)",
                av("replay_same_min"), av("replay_same_max")),
        identical(av("replay_same_min"), av("rec_auto.rec_auto_resolved_min")) &&
        identical(av("replay_same_max"), av("rec_auto.rec_auto_resolved_max")))
    check_true(ID,
        "and reproduces the recorded figure byte for byte on unchanged data",
        identical(av("same_matches_recorded"), "yes"))
    # AND THE RECORDED FIGURE IS ITSELF A NATIVE AUTO DRAW, which is the
    # control that says the recording did not change what was drawn.
    check_true(ID,
        "and a native auto draw of the same data is that same figure",
        identical(av("native_auto_matches_recorded"), "yes"))
}

# ===========================================================================
# 5. THE INTERFACE CONTRACT, ON THE SIDE THIS FILE OWNS
# ===========================================================================
# The `rec_form` leg publishes emlGraphsAxisYReqMin / emlGraphsAxisYReqMax
# itself and calls the draw with the RESOLVED numbers, which is exactly what
# the graphs form's bracket-headroom and legend-room passes do. What that
# proves is the preference. It does not prove the form sets them: that half
# lives in plugin/graphs/eml-graphs-form.praat, which is another hand's file
# this week, and saying so here is cheaper than a green tick somebody later
# reads as coverage it never had.
if (have) {
    fmin <- blockline("rec_form", "^axisYMin ")
    fmax <- blockline("rec_form", "^axisYMax ")
    check_true(ID,
        sprintf("with the form's request published, an already-resolved draw still records AUTO (%s)",
                fmin[1] %or% "<absent>"),
        length(fmin) == 1L && grepl("= 0\\.0 ", fmin[1]) && grepl("AUTO", fmin[1]))
    # AND THE RESOLVED NUMBERS ARE NOT LOST -- they are the note, which is
    # where a record of what happened belongs. 190..290 is what the draw was
    # given; 0.0/0.0 is what the user asked for. Both are in the file.
    check_true(ID,
        sprintf("and the numbers the form had already resolved are kept as the note (%s)",
                sub("^.*resolved to ", "", fmax[1] %or% "")),
        length(fmax) == 1L && grepl("resolved to 190\\.0000 \\.\\. 290\\.0000$", fmax[1]))
    check_true(ID,
        sprintf("and the step reads the block (%s)", av("rec_form_violin_call")),
        identical(trimws(av("rec_form_violin_call") %or% ""),
                  "axisYMin, axisYMax"))
    # THE FALLBACK, DRIVEN. rec_noform runs with no globals in scope at all --
    # the shape of every headless and API caller in this tree -- and its typed
    # range survives. A recorder that required the globals aborts this leg.
    check_true(ID,
        "and with no form in the picture at all, the recorder still works from its arguments",
        identical(av("rec_noform_emitted"), "yes") &&
        identical(av("rec_noform.rec_noform_flushed"), "1"))
    attest(ID,
        "the graphs form's half of the axis contract -- publishing emlGraphsAxisYReqMin/Max where the user's values are first read, unwritten by the headroom and legend passes -- is NOT tested here",
        "plugin/graphs/eml-graphs-form.praat is another hand's file; rec_form publishes the globals itself, which proves the preference and not the publication")
}

# ===========================================================================
# 6. THE SAME MECHANISM AT A SECOND SITE. MEASURED, PRINTED, NOT REPAIRED.
# ===========================================================================
# The doctrine is validate/v63 section 3e's and validate/v66 section 8's, and
# it is the reason this section asserts facts and no remedy: the two things it
# must not be are a PASSING CHECK, which would pin a defect as a contract, or
# SILENCE, which is how a finding gets lost between two hands.
#
# @emlDrawLTAS's Curve mode is `Draw: ..., "Curve"` on an Ltas, which joins
# bin points with segments exactly as the Spectrum's `Draw:` does. A one-bin
# window is an empty frame there too. It is MORE reachable than the
# spectrum's, not less: an Ltas's bin width is the BANDWIDTH the caller chose
# -- 100 Hz on the graphs form's own default -- so a hundred-hertz window
# does it, at any recording length. Curve is also the mode @emlDrawLTAS falls
# back to when the caller enables none of the four.
#
# WHY THE REMEDY IS NOT OBVIOUS AND SO IS NOT TAKEN HERE. The same figure's
# BARS mode draws that single bin without complaint, which is both the control
# that says this is the segment mechanism and the reason "draw what you can"
# is ambiguous at this site: it might mean a stem, and it might mean falling
# back to the mode that already works. Ruling A named @emlDrawSpectrum. This
# is a second site, found while repairing the first.
#
#   SITE: @emlDrawLTAS, plugin/graphs/eml-draw-procedures.praat, the
#         `Draw: .freqMin, .freqMax, .powerMin, .powerMax, "no", "Curve"` line.
if (have) {
    check_true(ID,
        sprintf("the LTAS probe really does put one bin in the window (%s bins at %s Hz per bin)",
                av("ltas_curve.ltas_curve_bins_in_range"),
                av("ltas_curve.ltas_curve_bin_width")),
        identical(av("ltas_curve.ltas_curve_bins_in_range"), "1"))
    check_true(ID,
        sprintf("and that bin holds a real level (%s dB)",
                av("ltas_curve.ltas_curve_bin_db")),
        is.finite(an("ltas_curve.ltas_curve_bin_db")) &&
        an("ltas_curve.ltas_curve_bin_db") > 20)
    check_true(ID,
        sprintf("while the same bin in Bars mode draws normally (%s ink) -- so this is the segment mechanism and not the data",
                av("ltas_bars_interior_ink")),
        is.finite(an("ltas_bars_interior_ink")) &&
        an("ltas_bars_interior_ink") > 100)
    if (identical(av("ltas_curve_interior_ink"), "0")) {
        cat(paste0(
            "      NOTE v67: THE ONE-BIN LTAS CURVE IS STILL AN EMPTY FRAME.\n",
            sprintf("            %s bin in range at %s Hz per bin, holding %s dB.\n",
                    av("ltas_curve.ltas_curve_bins_in_range"),
                    av("ltas_curve.ltas_curve_bin_width"),
                    av("ltas_curve.ltas_curve_bin_db")),
            sprintf("            Interior ink %s against %s for the same bin in\n",
                    av("ltas_curve_interior_ink"), av("ltas_bars_interior_ink")),
            sprintf("            BARS mode, and the empty figure still weighs %s\n",
                    av("ltas_curve_bytes")),
            "            bytes -- so nothing that thresholds on size sees it.\n",
            "            An Ltas bin width is the BANDWIDTH the caller chose,\n",
            "            100 Hz by default, so a hundred-hertz window reaches\n",
            "            this at any recording length. Curve is also the mode\n",
            "            @emlDrawLTAS falls back to when nothing is enabled.\n",
            "            SITE: @emlDrawLTAS, plugin/graphs/\n",
            "            eml-draw-procedures.praat, the `\"Curve\"` Draw: line.\n",
            "            AWAITING A RULING: a stem, as ruling A gave the\n",
            "            Spectrum, or a fall-back to Bars, which already draws\n",
            "            this case. Not asserted either way here.\n"))
    }
    attest(ID,
        sprintf("the one-bin LTAS Curve was measured: %s bin, %s dB, %s ink inside the frame against %s for Bars, %s bytes",
                av("ltas_curve.ltas_curve_bins_in_range"),
                av("ltas_curve.ltas_curve_bin_db"),
                av("ltas_curve_interior_ink"), av("ltas_bars_interior_ink"),
                av("ltas_curve_bytes")),
        "driven live through @emlDrawLTAS; not asserted either way -- ruling A named @emlDrawSpectrum, and the remedy at this site is the author's call")
}

# ===========================================================================
# 7. WHAT MOVED, AND WHAT DID NOT
# ===========================================================================
# The two-bin path is Praat's own `Draw:` with a count in front of it, so no
# figure in this repository that draws a spectrum over two or more bins can
# have changed -- and none did: all 39 harness/stress_cases figures are
# byte-identical across this change, re-driven 16 August 2026. Recorded
# without a check because the check belongs to v36 and v27, which own that
# artefact and read it every run.
attest(ID,
    "all 39 stress figures are byte-identical across this change",
    "re-driven through harness/stress_graphs.sh, 16 August 2026; the >= 2 bin arm is Praat's own Draw: unchanged")
# AND ONE THING THAT DID MOVE, ON PURPOSE, IN SOMEBODY ELSE'S VALIDATOR.
attest(ID,
    "validate/v66 sections 2's two `recorded_axis_args` checks now read `axisYMin, axisYMax` where they expect `0, 0` and `150, 400`",
    "superseded by ruling 10(b): the emitted call reads the block by design. harness/drawlayer/drawlayer.sh:95 and :150 read the literal out of the emitted violin call; they need to follow it through the block. Not this file's to edit.")

if (!exists("EML_SUITE")) {
    eml_report("v67 the recorded axis, and the one-bin spectrum")
    eml_exit()
}
