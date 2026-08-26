# ============================================================================
# v66_draw_layer.R -- four rulings that all land in the same three files
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. On 15 August 2026 four separate findings turned out to
# live in plugin/graphs/eml-draw-procedures.praat,
# plugin/graphs/eml-annotation-procedures.praat and
# plugin/scripts/eml-check-normality.praat -- the layer that turns a table into
# a picture and a picture into a paragraph. They have nothing in common except
# their address, and every one of them is silent:
#
#   RULING 10(a)  A violin recorded with the dialog's "both 0 = auto" axis
#                 replayed with the axis FROZEN at the numbers the first run
#                 resolved. Re-run on retargeted data -- the whole point of a
#                 recorded workflow -- every violin fell outside the window and
#                 the replay drew a fully furnished, completely EMPTY frame.
#                 Box, ticks, group names, title, both axis names, 43 KB of
#                 PNG, no data. Nothing warned.
#
#   RULING 7      Seven categorical draw procedures place the y-axis name with
#                 a bare `Text left`. Measured at FOUR PIXELS of white at
#                 300 dpi between "Power (dB)" and a tick reading "100.10" --
#                 the author's own second case, reproduced through six of the
#                 seven before anything was changed.
#
#   RULING 1b     The graphs form no longer offers an adjustment menu on the
#                 parametric arm, because Tukey's p is already family-wise.
#                 The figure outlives the dialog and said nothing about it.
#
#   RULING 6      Sixty-nine raw `fixed$` calls reaching the Info window from
#                 the annotation reporters, and four more from the normality
#                 wrapper's per-group branch.
#
# WHAT THE FAILURES LOOK LIKE, because none of them raises.
#
#   The frozen axis produces a FILE. A large one -- 43 KB, because a figure
#   with a frame, ticks, labels and a title is a large PNG whether or not
#   anything was plotted inside it. Every check that asks "did it draw" says
#   yes. §2 asks how much ink is inside the frame instead, and the size is
#   recorded beside it as the trap it is.
#
#   The collision produces a FIGURE, and a correct one everywhere except a
#   quarter of a millimetre of the left margin, where "Power (dB)" reads as
#   "Powe100.10". No truncation, no overprint, no warning: the mode is gap
#   exhaustion, and it is invisible to anything that does not count pixels.
#
#   The missing disclosure produces a CORRECT figure with a true subtitle that
#   is one clause short.
#
#   The raw doubles produce CORRECT NUMBERS. A Tukey difference of two
#   identical means IS zero; a two-way SS over values that cancel IS 1.6e-15.
#   What was wrong was their width: a bare "0" against a column of
#   "[-3.0871, 3.0871]", and
#
#       f1        0.000000000000001     0.000000000000002.0000      .176
#
#   -- seventeen decimals in a column padded for sixteen characters, so the SS
#   cell ran into the MS cell and the MS cell into the F cell.
#
# WHAT COULD NOT HAVE CAUGHT ANY OF IT, AND WHY.
#
#   - THE NUMERIC VALIDATORS, v01 through v19 and the sweep. They recompute
#     every statistic in R and compare against the printed value through
#     as.numeric(). "0" and "0.0000" are the same number to every one of them,
#     and so are "1.6e-15" and "0.00". A validator that PARSES before it
#     compares cannot see a width -- that is not a gap in those files, it is
#     what they are for, and they were green across this change in both
#     directions. They are equally blind to ruling 10(a): the frozen replay
#     computes nothing, so there is no number for them to disagree with.
#
#   - v27_empty_frames.R, WHICH IS THE CLOSEST THING TO A PREDECESSOR and is
#     worth being precise about. It renders harness/stress_cases through
#     harness/stress_graphs.sh and calls a figure blank when it has no
#     CHROMATIC ink -- exactly the verdict ruling 10(a)'s frozen violin
#     deserves. It never sees it, for two reasons that are both structural.
#     The stress cases pass explicit axis bounds or ordinary data, so none of
#     them is a REPLAY of a recorded call at all; and v27's blank verdict is
#     scored against a same-family baseline case (empty_violin), which makes
#     it a check on the DRAW path and not on the record path. A figure that is
#     blank because its axis was frozen by a recorder is not in its universe.
#
#   - v58_recorder_replay.R AND harness/record. They prove that an emitted
#     script RUNS and that a same-data replay reproduces the recorded figure.
#     Both were green over the defect, and the second one is why: on the data
#     it was recorded from, a frozen axis and an auto axis resolve to the same
#     numbers and the two figures are byte-identical. The defect exists only
#     under RETARGETING, which is the case a round-trip harness by definition
#     does not run. §2 runs both arms on purpose, and the same-data arm is
#     what stops this file being satisfied by a replay that ignores its
#     arguments entirely.
#
#   - v62_graphs_axes_channels.R, which found the collision and could not
#     repair it. It owns @emlDrawAxes' side of ruling 7 and it MEASURED the
#     categorical side at 4 px, printed it as a NOTE, and asserted nothing --
#     because plugin/graphs/eml-draw-procedures.praat was another hand's file
#     that turn. Its note names all seven sites. This file is the other half,
#     and it asserts what that note could only report.
#
#   - v65_display_standard.R AND v64. They own ruling 6 in
#     scripts/eml-wizard.praat and stats/eml-analysis.praat, and v64 pins
#     @eml_fixed itself and its case grid. Neither reads
#     graphs/eml-annotation-procedures.praat, which holds the ANOVA, Tukey,
#     Kruskal-Wallis, Dunn, two-way, paired, regression and correlation
#     REPORTERS -- and therefore most of the plugin's printed tables. The
#     formatter was closed and the largest set of its callers was not.
#
#   - A GOLDEN-FILE DIFF. It says "this changed"; it cannot say "this was
#     always wrong". The leak was already sitting in committed evidence when
#     this was written.
#
# THE FIGURE/INFO BOUNDARY RUNS THROUGH THE MIDDLE OF ONE FILE, and getting it
# wrong in either direction is a defect. eml-annotation-procedures.praat builds
# text that is DRAWN ON A PICTURE (an omnibus line, a bracket label, a matrix
# cell, the star key) and text that is PRINTED IN THE INFO WINDOW, out of the
# same fixed$ and in the same idiom. Ruling 6 names the second. The first is
# laid out against its own measured width -- @emlMeasureMatrixLayout measures
# the very strings @emlDrawMatrixPanel then draws -- so re-formatting it is a
# LAYOUT change, and a sweep that "fixed" every fixed$ in the file would move
# figures nobody asked to move. §1c asserts BOTH sides: the printed ones are
# all routed, and the drawn ones all survive, counted.
#
# THE THREE TRAPS THIS FILE IS BUILT AROUND, each of which cost a sibling a
# revision this round:
#
#   A CHECK THAT COULD ONLY PASS. Every assertion here is anchored to a
#   measurement that was taken on BOTH trees. The 4 px and the 17 px, the
#   frozen 160..340 and the resolved 900..1800, the empty frame's 0 ink and
#   the drawn frame's 6794 -- all of them were read off a HEAD-equivalent copy
#   before the repair and off the repaired tree after it. A check whose "fail"
#   side was never observed is not in this file.
#
#   A CHECK THAT MATCHES THE COMMENT EXPLAINING THE FIX. Every static check
#   reads code with comments STRIPPED. These three files carry long prose that
#   names the very procedures being checked for -- "@emlDrawAxisNameLeft"
#   appears in six comment paragraphs -- so an unstripped grep would find the
#   repair in the paragraph describing it and call the wiring present after
#   the call site was deleted.
#
#   A SIZE THRESHOLD. A 43 KB empty violin and a 53 KB empty spectrum both
#   sail through "the file is bigger than nothing". §2 asserts INK INSIDE THE
#   FRAME and records the byte counts beside it so the trap is on the record.
#
# NOTHING HERE IS VALIDATED UNTIL IT HAS BEEN BROKEN. Every check in this file
# was shown RED against a deliberately broken COPY of the tree, driven through
# $EML_DL_SRC and $EML_DRAW_SRC without touching the working tree. The breaks
# and their results are listed in harness/drawlayer/break.sh.
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

ID <- "v66"

`%or%` <- function(a, b) if (is.null(a) || length(a) == 0L || is.na(a)) b else a

gdir <- Sys.getenv("EML_DRAW_SRC", unset = "")
if (!nzchar(gdir)) gdir <- repo_path(file.path("plugin", "graphs"))
sdir <- Sys.getenv("EML_DRAWSCRIPTS_SRC", unset = "")
if (!nzchar(sdir)) sdir <- repo_path(file.path("plugin", "scripts"))
ddir <- Sys.getenv("EML_DRAWLAYER_DIR", unset = "")
if (!nzchar(ddir)) ddir <- repo_path(file.path("harness", "drawlayer", "out"))

f_draw   <- file.path(gdir, "eml-draw-procedures.praat")
f_annot  <- file.path(gdir, "eml-annotation-procedures.praat")
f_graph  <- file.path(gdir, "eml-graph-procedures.praat")
f_norm   <- file.path(sdir, "eml-check-normality.praat")

check_true(ID, "the three files this change touches are present",
           all(file.exists(c(f_draw, f_annot, f_norm))))

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS, AND STRIP COMMENTS BEFORE MATCHING.
# ---------------------------------------------------------------------------
# Both halves have bitten this repository. A call written across two lines with
# "..." is invisible to a line-at-a-time regex, which is the shape of a check
# that passes while proving nothing -- and every repair in this change is
# written across two lines. Comments are stripped for the reason given at the
# head of this file: these are heavily annotated sources and the annotation
# names what it explains.
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

code_draw  <- read_code(f_draw)
code_annot <- read_code(f_annot)
code_graph <- read_code(f_graph)
code_norm  <- read_code(f_norm)

has <- function(code, pattern) any(grepl(pattern, code))
cnt <- function(code, pattern) sum(grepl(pattern, code))

# The body of one procedure, comments already stripped. Used where a check
# would otherwise be satisfied by a line in a DIFFERENT procedure of the same
# file -- which is most of them here, since these files hold dozens.
proc_body_of <- function(code, name) {
    i <- grep(sprintf("^procedure %s(:|$)", name), code)
    if (!length(i)) return(character(0))
    j <- grep("^endproc\\b", code)
    j <- j[j > i[1]]
    if (!length(j)) return(character(0))
    code[(i[1] + 1L):(j[1] - 1L)]
}

# ---------------------------------------------------------------------------
# The harness TSV, scoped by leg. Keys repeat across legs on purpose -- eight
# legs each publish "shift_inch" -- so a flat name->value map would silently
# answer every one of them with the first. Rows are filed under the last `leg`
# marker seen; the shell writes `leg --shell--` before its own rows.
# ---------------------------------------------------------------------------
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
        # A leg that publishes the same key twice is a harness fault, not a
        # finding; keep the first and let the count checks notice.
        if (is.null(out[[key]])) out[[key]] <- v
        else out[[key]] <- c(out[[key]], v)
    }
    out
}

dl <- read_legged_tsv(file.path(ddir, "DRAWLAYER.tsv"))
have_dl <- length(dl) > 0
dv <- function(k) if (is.null(dl[[k]])) NA_character_ else dl[[k]][1]
dn <- function(k) suppressWarnings(as.numeric(dv(k)))

check_true(ID, "the draw-layer drive produced evidence (harness/drawlayer/drawlayer.sh)",
           have_dl)
if (have_dl) {
    check_true(ID,
        sprintf("and it ran on the supported binary (%s)", dv("praat_version")),
        grepl("^Praat 6\\.6\\.3[0-9]|^Praat [7-9]", dv("praat_version") %or% ""))
}

# ===========================================================================
# 1. THE CODE ITSELF
# ===========================================================================

# ---------------------------------------------------------------------------
# 1a. RULING 10(a) -- THE RECORDER PASSES THE SENTINEL, NOT THE RESOLUTION
# ---------------------------------------------------------------------------
# The signal for "the user chose auto" is the (0, 0) the dialog names on its
# own face, and it arrives at every recorder as .vMin/.vMax. Bar, box, scatter
# and histogram all build their recorded call from string$ (.vMin); the violin
# alone substituted the resolved numbers. The static check is scoped to
# @emlRecordViolin's own body, because `fixed$ (emlDrawViolinPlot.yMin` still
# appears three lines further down -- in the RESULT NOTE, which is where the
# resolved numbers belong and where this file requires them to stay.
rv <- proc_body_of(code_draw, "emlRecordViolin")
check_true(ID, "@emlRecordViolin exists and was found",
           length(rv) > 0)
# The recorded CALL. Split from the note by which statement it lands in:
# .code$ is the call, @emlRecordResult is the note.
rv_code <- rv[grepl("^\\.code\\$ =", rv)]
check_true(ID,
    "the recorded violin call passes the axis arguments through as given",
    length(rv_code) == 1L &&
    grepl("string\\$ \\(\\.vMin\\)", rv_code) &&
    grepl("string\\$ \\(\\.vMax\\)", rv_code))
check_true(ID,
    "and does NOT substitute the resolved axis for them",
    length(rv_code) == 1L &&
    !grepl("emlDrawViolinPlot\\.yM(in|ax)", rv_code))
# THE OTHER HALF, AND IT IS NOT DECORATION. A repair that dropped the resolved
# numbers altogether would pass the two checks above and would lose the record
# of what the axis actually was -- which is the thing the line it replaced was
# right about.
rv_note <- rv[grepl("emlRecordResult", rv)]
# READ FROM THE WHOLE BODY, NOT FROM THE CALL LINE. The note is composed
# before it is passed, because it carries an extra clause on the auto arm --
# see below -- so the numbers are in the lines that BUILD it and the call
# line names the variable that holds it. Requiring them on the call line
# would report a note that says more as a note that says nothing.
rv_build <- rv[grepl("axisNote\\$", rv) | grepl("emlRecordResult", rv)]
check_true(ID,
    "the resolved axis survives in the record's own result note",
    length(rv_note) == 1L &&
    any(grepl("emlDrawViolinPlot\\.yMin", rv_build)) &&
    any(grepl("emlDrawViolinPlot\\.yMax", rv_build)))
# AND THE NOTE SAYS WHICH OF THE TWO IT IS. A range worked out from the data
# describes the recording; it does not bind a replay, which resolves the axis
# again against whatever table it is pointed at. The clause is on the auto arm
# only: a range the user typed is the same range on every table, and there the
# note IS binding. Both halves are asserted, because a clause added to every
# arm would be as wrong as a clause added to none.
rv_auto <- rv[grepl("auto adapts to other data", rv, fixed = TRUE)]
check_true(ID,
    "and an auto range is marked as descriptive, not as a promise",
    length(rv_auto) == 1L)
check_true(ID,
    "and the clause is guarded by the auto sentinel, so a typed range keeps its word",
    any(grepl("if \\.vMin = 0 and \\.vMax = 0", rv)))
# AND THE SIBLING RECORDERS STILL AGREE WITH IT. If a later change "tidied"
# them the other way, the violin would be right and alone.
for (nm in c("emlRecordBar", "emlRecordBox", "emlRecordScatter")) {
    b <- proc_body_of(code_draw, nm)
    if (length(b)) {
        cc <- b[grepl("^\\.code\\$ =", b)]
        check_true(ID,
            sprintf("@%s passes its axis arguments through the same way", nm),
            length(cc) == 1L && grepl("string\\$ \\(\\.vMin\\)", cc))
    }
}

# ---------------------------------------------------------------------------
# 1b. RULING 7 -- SEVEN SITES, AND THE EIGHTH THAT MUST NOT MOVE
# ---------------------------------------------------------------------------
# @emlDrawAxisNameLeft belongs to eml-graph-procedures.praat, which is not this
# change's file; its existence is asserted here because seven call sites that
# point at nothing are worse than seven bare `Text left`s -- they are seven
# dead figures.
check_true(ID, "@emlDrawAxisNameLeft exists to be called",
           has(code_graph, "^procedure emlDrawAxisNameLeft:"))
check_true(ID,
    sprintf("all seven categorical draw paths place the y-axis name through it (%d)",
            cnt(code_draw, "@emlDrawAxisNameLeft:")),
    cnt(code_draw, "@emlDrawAxisNameLeft:") == 7L)
# AND NOT ONE BARE `Text left` OF AN AXIS NAME SURVIVES. This is the check
# that a partial repair fails: six of seven leaves the file with a call count
# that looks healthy and one procedure still colliding.
check_true(ID,
    "and no draw procedure still writes the axis name with a bare Text left",
    cnt(code_draw, "^Text left: \"yes\", \\.yLabel\\$") == 0L)
# THE EIGHTH SITE IS A PANEL LABEL AND IT IS NOT AN AXIS NAME. It names the
# GROUP a facet holds, it is truncated by its own binary search against the
# panel height, and it is drawn in the panel's margin rather than the figure's.
# Routing it through a procedure that shifts the frame would move a label that
# has no tick numbers to collide with. Pinned so a future sweep for "bare Text
# left" does not take it as the last one it missed.
check_true(ID,
    "the faceted PANEL label is still drawn bare, which is correct",
    cnt(code_draw, "^Text left: \"yes\", \\.panelLabel\\$") == 1L)
# EVERY CALL CARRIES A MEASUREMENT AND A WINDOW. A call that passed 0 for the
# label width would compile, run, shift nothing and pass the count above.
check_true(ID,
    "every call passes the measured tick-label width, not a constant",
    cnt(code_draw,
        "@emlDrawAxisNameLeft: .*emlDrawAlignedMarksLeft\\.maxWideLabelMM") == 7L)

# ---------------------------------------------------------------------------
# 1c. RULING 6 -- THE CENSUS, ON BOTH SIDES OF THE BOUNDARY
# ---------------------------------------------------------------------------
# A statement here is one logical Praat statement: continuations are already
# joined, so a five-line appendInfoLine is one element.
info_stmts <- function(code) {
    code[grepl("^appendInfoLine\\b", code) |
         grepl("^appendInfo\\b", code) |
         grepl("^writeInfoLine\\b", code) |
         grepl("^@emlReportLine", code) |
         grepl("^emlWizardExplain\\$ =", code)]
}
raw_fixed <- function(x) grepl("fixed\\$ \\(", x)

# THE PRINTED SIDE. Not one raw fixed$ left in anything that reaches the Info
# window, in either file.
check_true(ID,
    sprintf("no Info-window statement in the annotation reporters still calls fixed$ (%d found)",
            sum(raw_fixed(info_stmts(code_annot)))),
    sum(raw_fixed(info_stmts(code_annot))) == 0L)
check_true(ID,
    sprintf("nor in the normality wrapper's per-group branch (%d found)",
            sum(raw_fixed(info_stmts(code_norm)))),
    sum(raw_fixed(info_stmts(code_norm))) == 0L)
# AND THEY GO THROUGH THE SHARED FORMATTER RATHER THAN A LOCAL ONE. A second
# implementation of the rounding would satisfy every width check in §5 and
# would be a second thing to keep right.
check_true(ID, "the annotation reporters call the shared formatter",
           cnt(code_annot, "@eml_fixed:") >= 60L)
# A FLOOR, NOT AN EXACT COUNT. What this asserts is that the wrapper routes
# its numbers through the shared formatter; the raw-fixed$ check above is what
# asserts none escape. An equality here makes the count itself the contract,
# so printing one more honest number -- a threshold beside the reading that
# was made against it -- reads as a regression. The property is "uses the
# shared formatter", and a floor states it without freezing the line count.
check_true(ID,
           sprintf("the normality wrapper calls it too (%d call(s))",
                   cnt(code_norm, "@eml_fixed:")),
           cnt(code_norm, "@eml_fixed:") >= 3L)
for (nm in c("eml_fixed", "emlFixed", "eml_fixed4")) {
    check_true(ID,
        sprintf("and neither file defines its own @%s", nm),
        !has(code_annot, sprintf("^procedure %s(:|$)", nm)) &&
        !has(code_norm,  sprintf("^procedure %s(:|$)", nm)))
}
# THE p IS THE OTHER CLAUSE OF THE SAME RULING. The per-group Shapiro-Wilk line
# printed "p = 0.00000000001" from a call that asked for four decimals; it goes
# through @emlFormatP now, like every other p in the plugin.
check_true(ID, "the per-group Shapiro-Wilk p is rendered in APA style",
           has(code_norm, "@emlFormatP: \\.swP") &&
           has(code_norm, "emlFormatP\\.formatted\\$"))

# THE DRAWN SIDE, WHICH MUST NOT HAVE BEEN SWEPT. This is the check that a
# global search-and-replace fails. Figure text is laid out against its own
# measured width, and @emlMeasureMatrixLayout measures the very strings
# @emlDrawMatrixPanel draws -- so routing them through a formatter that widens
# "0" to "0.0000" is a layout change to figures nobody asked to move.
# @emlBridgeOmnibusLine and @emlBridgeRenderAnnotations JOINED THIS LIST when
# the result store's read side landed. They are not new figure text: they are
# the figure text the four arms of @emlBridgeGroupComparison used to build
# inline, lifted into one procedure so that a figure drawn from a STORED
# result and the same figure drawn from a re-run are the same characters. The
# sweep rule follows the text, not the procedure it happens to sit in -- so
# the omnibus sentence and the bracket labels are still measured here, and are
# still forbidden from going through the Info formatter below.
drawn_procs <- c("emlFormatStars", "emlFormatAnnotLabel", "emlMeasureMatrixLayout",
                 "emlDrawMatrixPanel", "emlBridgeGroupComparison",
                 "emlBridgeOmnibusLine", "emlBridgeRenderAnnotations",
                 "emlBridgeCorrelation")
drawn_fixed <- sum(vapply(drawn_procs, function(nm)
    sum(raw_fixed(proc_body_of(code_annot, nm))), 0L))
check_true(ID,
    sprintf("the figure-text procedures still format with fixed$ and were not swept (%d calls)",
            drawn_fixed),
    drawn_fixed >= 15L)
for (nm in drawn_procs) {
    b <- proc_body_of(code_annot, nm)
    check_true(ID,
        sprintf("@%s draws its own text and does not call the Info formatter", nm),
        length(b) > 0 && !any(grepl("@eml_fixed:", b)))
}

# ---------------------------------------------------------------------------
# 1d. RULING 1b -- TWO ARMS, TWO CLAIMS
# ---------------------------------------------------------------------------
# The parametric string must state the family-wise property; the nonparametric
# one must still NAME the correction the user picked, because that arm still
# has a menu and still honours it. One claim covering both would be false on
# one of them whichever way it was written.
tuk <- grep("^annotMatrixPosthoc\\$ = \"Tukey", code_annot, value = TRUE)
dun <- grep("^annotMatrixPosthoc\\$ = \"Dunn", code_annot, value = TRUE)
check_true(ID, "the figure's post-hoc disclosure names Tukey on the parametric arm",
           length(tuk) == 1L)
check_true(ID,
    sprintf("and states that it carries its own family-wise control (%s)",
            trimws(sub("^annotMatrixPosthoc\\$ = ", "", tuk[1] %or% ""))),
    length(tuk) == 1L && grepl("family-wise", tuk[1]))
check_true(ID,
    "while the Dunn arm still names the correction it was given, not a claim about it",
    length(dun) == 1L && grepl("\\.correction\\$", dun[1]) &&
    !grepl("family-wise", dun[1]))

# ===========================================================================
# 2. RULING 10(a), DRIVEN: RECORD, THEN REPLAY TWICE
# ===========================================================================
# The two arms are the whole argument. RETARGETED, the replay must resolve the
# new data's axis and match a native draw byte for byte. ON THE SAME DATA, it
# must still reproduce the figure that was recorded -- which is what stops this
# file being satisfied by a replay that ignores its axis arguments entirely.
#
# SUPERSEDED, 16 AUGUST 2026 — RULING 10(b) MOVED THE NUMBER, NOT THE CLAIM.
# This section was written when the axis lived in the draw call, and it asked
# the call for the literal "0, 0" on the auto arm and "150, 400" on the
# explicit one. Ruling 10(b) put axisYMin and axisYMax in the editable header
# block at the top of the emitted script -- beside the object and column names,
# where somebody retargeting a recorded workflow will look for them -- and left
# the call REFERENCING them. Both literal assertions therefore went red against
# a file that is more correct than the one they were written for, which is a
# superseded check and not a regression.
#
# WHAT REPLACES THEM IS STRICTLY STRONGER, and the reason is worth stating
# because "we moved the check to where the number went" is the shape a weakened
# check also takes. The value is followed THROUGH the block in two steps: the
# call's axis slots must be the two variable names, and the block those names
# resolve to must hold the right number. The old single assertion could not
# distinguish a block that declares the sentinel from a step that ignores it --
# it never saw the block at all. This pair catches both halves separately: a
# block seeded with the RESOLUTION (160 .. 340) instead of the request fails
# the value check while the reference check still passes, and a step that
# reverted to carrying its own literal fails the reference check while the
# block stays correct.
#
# WHAT COULD NOT HAVE CAUGHT IT, and did not. Every static check in §1a reads
# @emlRecordViolin's `.code$ =` line and is satisfied by string$ (.vMin) being
# in it -- which it still is, because the recorder writes the BLOCK from those
# arguments now instead of the call. Nothing in the source says which of the
# two spellings reaches the emitted file. Only reading the emitted script does,
# and only reading BOTH of its halves says the two spellings agree.
if (have_dl) {
    # THE COMMENT TRAP, NAMED. The block's declaration carries its own prose --
    # "; the y-axis range -- AUTO (both 0 = computed from the data)" -- and that
    # sentence contains an equals sign and a zero. The harness cuts at the
    # semicolon before it takes the value (harness/drawlayer/drawlayer.sh,
    # block_value), so what is asserted below is the declaration and never the
    # sentence explaining it.
    check_true(ID,
        sprintf("the recorded call READS the block's axis variables rather than a literal (%s)",
                dv("recorded_axis_args")),
        identical(trimws(dv("recorded_axis_args") %or% ""), "axisYMin, axisYMax"))
    check_true(ID,
        sprintf("and the block declares the auto sentinel, not the resolution (%s, %s)",
                dv("recorded_axis_block_min"), dv("recorded_axis_block_max")),
        is.finite(dn("recorded_axis_block_min")) &&
        is.finite(dn("recorded_axis_block_max")) &&
        dn("recorded_axis_block_min") == 0 &&
        dn("recorded_axis_block_max") == 0)
    check_true(ID,
        sprintf("and the resolved axis is in the note beside it (%s)",
                dv("recorded_result_note")),
        grepl("^Axis resolved to [0-9.]+ \\.\\. [0-9.]+ over [0-9]+ groups\\.$",
              dv("recorded_result_note") %or% ""))

    # THE MIRROR. A repair that hardcoded the sentinel would satisfy every
    # check on the auto arm above and would throw away every axis a user ever
    # typed. It is also the mirror of the fix-shaped fix on this side: a block
    # that always declares 0 has the right SHAPE at every site and is wrong at
    # every site where the user typed something, and only a value check on an
    # arm whose value is not zero can tell the two apart.
    check_true(ID,
        sprintf("an EXPLICIT axis is carried the same way, through the block (%s)",
                dv("recorded_axis_args_explicit")),
        identical(trimws(dv("recorded_axis_args_explicit") %or% ""),
                  "axisYMin, axisYMax"))
    check_true(ID,
        sprintf("and the block holds the numbers the user typed (%s, %s)",
                dv("recorded_axis_block_min_explicit"),
                dv("recorded_axis_block_max_explicit")),
        is.finite(dn("recorded_axis_block_min_explicit")) &&
        is.finite(dn("recorded_axis_block_max_explicit")) &&
        dn("recorded_axis_block_min_explicit") == 150 &&
        dn("recorded_axis_block_max_explicit") == 400)
    check_true(ID,
        "and the draw honoured it rather than resolving from the data",
        identical(dv("axis_record_explicit.explicit_resolved_min"), "150.0000") &&
        identical(dv("axis_record_explicit.explicit_resolved_max"), "400.0000"))

    # THE RETARGETED ARM. At HEAD this replay resolved 160..340 over data
    # running 900..1800 and drew a frame with nothing in it.
    check_true(ID,
        sprintf("a retargeted replay resolves the NEW data's axis (%s .. %s; native draw says %s .. %s)",
                dv("replay_wide_min"), dv("replay_wide_max"),
                dv("axis_native_wide.native_wide_min"),
                dv("axis_native_wide.native_wide_max")),
        is.finite(dn("replay_wide_min")) &&
        abs(dn("replay_wide_min") - dn("axis_native_wide.native_wide_min")) < 1e-6 &&
        abs(dn("replay_wide_max") - dn("axis_native_wide.native_wide_max")) < 1e-6)
    check_true(ID,
        "and the retargeted replay is the figure a native draw produces, byte for byte",
        identical(dv("replay_wide_matches_native"), "yes"))
    # THE SAME-DATA ARM.
    check_true(ID,
        sprintf("while a same-data replay still reproduces the recorded figure exactly (%s .. %s)",
                dv("replay_same_min"), dv("replay_same_max")),
        identical(dv("replay_same_matches_record"), "yes") &&
        identical(dv("replay_same_min"), dv("axis_record.record_resolved_min")) &&
        identical(dv("replay_same_max"), dv("axis_record.record_resolved_max")))

    # INK INSIDE THE FRAME, WHICH IS THE MEASUREMENT THE FILE SIZE IS NOT.
    # At HEAD the retargeted replay measured 0 with 43 KB of PNG.
    check_true(ID,
        sprintf("the retargeted replay has data inside its frame (%s ink; the frozen one measured 0 at %s bytes)",
                dv("replay_wide_interior_ink"), dv("replay_wide_bytes")),
        is.finite(dn("replay_wide_interior_ink")) &&
        dn("replay_wide_interior_ink") > 100)
    check_true(ID,
        "and so does the same-data replay",
        is.finite(dn("replay_same_interior_ink")) &&
        dn("replay_same_interior_ink") > 100)
    # THE TRAP, SAID AS A NUMBER. A threshold on file size passes an empty
    # figure, because a frame with ticks, names and a title is a large PNG.
    attest(ID,
        sprintf("a fully furnished empty frame weighs %s bytes -- a size threshold would pass it",
                dv("replay_wide_bytes")),
        "measured on the frozen-axis replay at HEAD, 15 August 2026: 43,297 bytes, 0 ink inside the frame")
}

# ===========================================================================
# 3. RULING 7, DRIVEN: SEVEN PROCEDURES, ONE NARROW dB AXIS
# ===========================================================================
# Six of the seven draw a y-axis whose tick labels reach six characters on this
# fixture, and all six measured 4 px of gap at HEAD. The floor asserted is 7 px
# -- one third of a character width at this figure's body size -- which is
# comfortably above the 4 measured before and comfortably below the 17 measured
# after, and is the SAME floor validate/v62 holds @emlDrawAxes to. Two rigs
# measuring one requirement against two different floors would produce a pair
# of numbers nobody could compare.
six <- c("name_violin", "name_box", "name_bar",
         "name_gviolin", "name_gbox", "name_spaghetti")

# THE ANCHOR THE CLIPPING CHECK IS MEASURED AGAINST, AND WHY THERE HAS TO BE
# ONE. See the paragraph at the check itself: "first ink is not column 0"
# cannot say anything about the axis name, because any ink at all answers it.
# What can is the name's own extent and the name's own position, and both of
# those are comparisons -- they need a name that is known not to have moved.
#
# THE UNSHIFTED LEGS SUPPLY IT. name_plain and name_hist both publish
# shift_inch = 0 (asserted below, at the control and the seventh site), so
# their axis name stands where the theme puts it with no repair in play. Both
# put their leftmost ink in the same column, which is what says the column is
# the theme's margin and not a property of one figure's data -- and it is the
# guard on the anchor: if those two ever disagree, every displacement measured
# from them is meaningless and this check says so before the six do.
#
# THE SCALE IS TAKEN FROM THE EVIDENCE, NOT ASSUMED. The published shift is in
# inches and the measurement is in pixels, so one number has to bridge them.
# The post-hoc leg is the only one whose pixel width is recorded (1800 px) and
# every leg in this harness is drawn 6 inches wide -- the drive script passes
# 6, 4 to all of them -- so the ratio is the harness's own resolution. It is
# asserted to be the 300 dpi drawlayer.sh's crop constants already assume
# (1280x920+260+125 out of a 6x4 is a 300 dpi crop and nothing else), so a
# harness re-driven at another resolution turns this red rather than quietly
# rescaling every displacement below it.
if (have_dl) {
    px_per_inch <- dn("posthoc_tukey_width_px") / 6
    anchor_col  <- dn("name_plain_first_ink_px")
    anchor_run  <- dn("name_plain_name_run_px")
    check_true(ID,
        sprintf("the two legs that take no shift agree on where an unmoved axis name stands (%s px and %s px)",
                dv("name_plain_first_ink_px"), dv("name_hist_first_ink_px")),
        is.finite(anchor_col) && anchor_col > 0 &&
        is.finite(dn("name_hist_first_ink_px")) &&
        anchor_col == dn("name_hist_first_ink_px"))
    check_true(ID,
        sprintf("and the pictures are the 300 dpi the harness's own crop constants assume (%s px / 6 in)",
                dv("posthoc_tukey_width_px")),
        is.finite(px_per_inch) && abs(px_per_inch - 300) < 0.5)
    for (leg in six) {
        check_true(ID,
            sprintf("%s: the fixture really does put six-character labels on the axis (%s mm)",
                    leg, dv(paste0(leg, ".widest_label_mm"))),
            is.finite(dn(paste0(leg, ".widest_label_mm"))) &&
            dn(paste0(leg, ".widest_label_mm")) > 0)
        check_true(ID,
            sprintf("%s: the axis name clears its ticks (%s px, was 4 at HEAD)",
                    leg, dv(paste0(leg, "_gap_px"))),
            is.finite(dn(paste0(leg, "_gap_px"))) &&
            dn(paste0(leg, "_gap_px")) >= 7)
        check_true(ID,
            sprintf("%s: and it was MOVED to get there, by a few millimetres (%s inch of %s available)",
                    leg, dv(paste0(leg, ".shift_inch")),
                    dv(paste0(leg, ".room_inch"))),
            is.finite(dn(paste0(leg, ".shift_inch"))) &&
            dn(paste0(leg, ".shift_inch")) > 0 &&
            dn(paste0(leg, ".shift_inch")) < 0.25 &&
            identical(dv(paste0(leg, ".clamped")), "0"))
        # NOTHING WAS PUSHED OFF THE PAGE, and the obvious form of this check
        # is worse than not enough -- it moves the WRONG WAY. Praat saves the
        # outer viewport @emlAssertFullViewport selects and nothing outside it,
        # so a name shifted past the panel edge is cut; but with the shift
        # unclamped and ten times too big the name is not sliced down its
        # length, it is clipped away almost entirely, and the fragment left
        # behind starts FURTHER RIGHT than the intact name did (67 px -> 121).
        #
        # THE PRINCIPLE, SAID ONCE FOR BOTH SITES IN THIS FILE THAT HAD IT.
        # A positional measurement that ANY ink can satisfy is not a
        # measurement of the element it is written about. "First ink is not
        # column 0" is answered by the tick labels, by the frame, by the
        # title -- by whatever the scan reaches first -- so it passes with the
        # axis name clipped away entirely, and on the defect it was written
        # for it reads HEALTHIER than it does on a correct figure. What can
        # only be answered by the element is the element's own extent, its
        # position against a known anchor, or its value. This check is the
        # first two, and validate/v69 §4 is the same rebuild on the bracket
        # caption -- one answer to this in the repository, not two.
        #
        #   EXTENT. The name's own ink run, which is the width of the
        #   rotated glyphs and nothing else's: 37 px intact, 10 px when the
        #   over-shift clipped it. It is held to the unmoved control's run
        #   rather than to a floor picked here, so the number is measured and
        #   not invented.
        #
        #   POSITION. The name must stand exactly the published shift to the
        #   LEFT of where an unshifted name stands -- 99 px anchor minus a
        #   0.1048 in shift at 300 dpi is 31.4 px, measured 32. A shift that
        #   never fires puts it at 99, a shift ten times too big puts the
        #   fragment at 121, and neither is within a pixel and a half of what
        #   the plugin says it did. This is also the picture's own answer to
        #   the published shift_inch checked above, which until here was only
        #   ever compared against itself.
        run_px   <- dn(paste0(leg, "_name_run_px"))
        moved_px <- anchor_col - dn(paste0(leg, "_first_ink_px"))
        want_px  <- dn(paste0(leg, ".shift_inch")) * px_per_inch
        check_true(ID,
            sprintf("%s: the axis name is the whole name -- its ink run is the unmoved control's, to the pixel (%s px vs %s px)",
                    leg, dv(paste0(leg, "_name_run_px")),
                    dv("name_plain_name_run_px")),
            is.finite(run_px) && is.finite(anchor_run) &&
            abs(run_px - anchor_run) <= 1)
        check_true(ID,
            sprintf("%s: and it stands where the published shift says it should, left of an unmoved name (%s px moved, %s in published = %s px)",
                    leg, format(moved_px), dv(paste0(leg, ".shift_inch")),
                    format(round(want_px, 1))),
            is.finite(moved_px) && is.finite(want_px) &&
            moved_px > 0 && abs(moved_px - want_px) <= 1.5)
    }

    # THE SEVENTH SITE. A faceted histogram's y-axis is a COUNT, so its labels
    # reach six characters only past a hundred thousand observations; driven
    # here through the dialog's own y-max field instead. The verdict is that
    # the site is WIRED and provably neutral: the shift keys exist at all only
    # because @emlDrawAxisNameLeft ran (nothing else on the faceted path calls
    # it, so on a tree with the bare `Text left` the leg aborts before
    # publishing them), and the shift it took is zero because no label was
    # wide. That pairing is what separates "the guard did nothing because
    # nothing was needed" from "the guard is not there".
    check_true(ID,
        "the faceted histogram reaches @emlDrawAxisNameLeft at all",
        !is.na(dv("name_hist.shift_inch")))
    check_true(ID,
        sprintf("and takes no shift there, because a count axis has no six-character label (%s mm)",
                dv("name_hist.widest_label_mm")),
        identical(dv("name_hist.widest_label_mm"), "0") &&
        identical(dv("name_hist.shift_inch"), "0"))

    # THE CONTROL, AND IT IS THE POINT OF THE WHOLE SECTION. An ordinary
    # figure must not move by one pixel. A repair that widened the margin
    # unconditionally would satisfy every check above and change every figure
    # the plugin has ever drawn. 37 px is what this figure measured at HEAD,
    # measured again after, on a HEAD-equivalent copy of the tree.
    check_true(ID,
        sprintf("an ordinary figure's widest label is under six characters (%s mm)",
                dv("name_plain.widest_label_mm")),
        identical(dv("name_plain.widest_label_mm"), "0"))
    check_true(ID,
        "so its axis name is not moved at all -- the shift is exactly zero",
        identical(dv("name_plain.shift_inch"), "0"))
    check_true(ID,
        sprintf("and it still has the gap it always had (%s px, and 37 at HEAD)",
                dv("name_plain_gap_px")),
        identical(dv("name_plain_gap_px"), "37"))
}
# AND THE WHOLE STRESS INVENTORY IS UNMOVED. All 39 figures of
# harness/stress_graphs.sh were re-rendered on a HEAD-equivalent copy and on
# the repaired tree, 15 August 2026: 39 of 39 byte-identical, and the ten
# BLANK_FRAME_ABS verdicts unchanged. None of them carries a six-character
# tick label, which is exactly why they did not move.
attest(ID,
       "all 39 stress figures are byte-identical across this change",
       "harness/stress_graphs.sh run on a HEAD-equivalent tree and on the repaired tree, 15 Aug 2026: 39/39 identical, verdicts 29 OK + 10 BLANK_FRAME_ABS on both")

# ===========================================================================
# 4. RULING 1b, DRIVEN: WHAT THE FIGURE ACTUALLY SAYS
# ===========================================================================
if (have_dl) {
    check_true(ID,
        sprintf("the parametric figure says Tukey carries its own control (%s)",
                dv("posthoc_tukey.posthoc_label")),
        grepl("^Tukey HSD\\b", dv("posthoc_tukey.posthoc_label") %or% "") &&
        grepl("family-wise", dv("posthoc_tukey.posthoc_label") %or% ""))
    check_true(ID,
        sprintf("the nonparametric figure names its correction instead (%s)",
                dv("posthoc_dunn.posthoc_label")),
        grepl("^Dunn's test \\(holm\\)$", dv("posthoc_dunn.posthoc_label") %or% ""))
    check_true(ID,
        "and the two arms do not make the same claim",
        !identical(dv("posthoc_tukey.posthoc_label"),
                   dv("posthoc_dunn.posthoc_label")) &&
        !grepl("family-wise", dv("posthoc_dunn.posthoc_label") %or% ""))
    # THE SUB-LINE IS THE FIGURE'S ONLY DISCLOSURE OF THE CORRECTION, so it has
    # to reach the reader as well as be true. A subtitle that is correct and
    # wider than the canvas is not a disclosure. Its VALUE is asserted here;
    # that it fits, and that it fits on the page and not merely in the number
    # the plugin reported, is asserted below on both arms.
    check_true(ID,
        sprintf("and it is the whole sub-line, correction and legend together (%s)",
                dv("posthoc_tukey.posthoc_subtitle")),
        grepl("family-wise", dv("posthoc_tukey.posthoc_subtitle") %or% "") &&
        grepl("Upper: adjusted p", dv("posthoc_tukey.posthoc_subtitle") %or% ""))
    # AND IT REACHED THE PAGE, MEASURED ON THE SUB-LINE RATHER THAN ON
    # WHATEVER INK THE SCAN MEETS FIRST.
    #
    # What stood here read the first inked COLUMN of the whole picture and
    # asked for it to be greater than zero. That is the same defect as the
    # axis-name site above, in its other form: a positional measurement that
    # ANY ink can satisfy is not a measurement of the element it is written
    # about. The leftmost ink in these figures is the violin's y-axis name at
    # column 99, and it is there whatever the sub-line does -- so the check
    # passed with the disclosure absent entirely, and a sub-line that grew
    # until it overhung the plot furniture moved that column not at all,
    # because the sub-line is CENTRED and grows from the middle outwards.
    # Only the one case where it grew past the canvas edge and was clipped
    # ever reached column 0, and that case was already red on the millimetre
    # check above. The measurement was carrying no weight of its own.
    #
    # THE REPLACEMENT IS TWO STATEMENTS, NEITHER OF THEM ABOUT A FIRST PIXEL,
    # and it is the shape validate/v69 §4 settled on for the bracket caption:
    # measure both edges of the ink, and hold them to a clearance the figure
    # itself supplies.
    #
    #   THE INK BOX, BOTH SIDES. The figure's ink must stop short of both
    #   canvas edges by the margin an unshifted axis name stands in -- the 99
    #   px anchor §3 measured on two independent unshifted legs, not a
    #   constant chosen here. A bound on the EXTENT of all the ink is a
    #   statement about every element inside it, the sub-line included, in a
    #   way that the position of the first pixel is not: further ink can only
    #   push the box outwards, never pull it in.
    #
    #   THE SUB-LINE'S OWN FOOTPRINT. @emlDrawMatrixPanel centres it, so its
    #   measured width and the canvas width fix where its ends are: half the
    #   difference on each side. Laid out that way it must fall inside the ink
    #   the figure actually has. The scale is the picture's own width against
    #   the canvas the plugin measured against (1800 px / 152.40 mm), so no
    #   dpi is assumed. Tukey's 96.18 mm puts its ends at 332 and 1468 px
    #   inside ink running 99 .. 1548; the 235.54 mm of the overflow break
    #   puts them at -490 and 2290.
    #
    # Both arms, and both arms' published fit -- until here only the Tukey
    # arm's sub-line was measured against the canvas at all.
    ppm       <- dn("posthoc_tukey_width_px") / dn("posthoc_tukey.posthoc_canvas_mm")
    margin_px <- dn("name_plain_first_ink_px")
    for (leg in c("posthoc_tukey", "posthoc_dunn")) {
        il <- dn(paste0(leg, "_first_ink_px"))
        ir <- dn(paste0(leg, "_last_ink_px"))
        iw <- dn(paste0(leg, "_width_px"))
        sub_mm <- dn(paste0(leg, ".posthoc_subtitle_mm"))
        can_mm <- dn(paste0(leg, ".posthoc_canvas_mm"))
        check_true(ID,
            sprintf("%s: the sub-line fits the canvas it was measured against (%s mm of %s mm)",
                    leg, dv(paste0(leg, ".posthoc_subtitle_mm")),
                    dv(paste0(leg, ".posthoc_canvas_mm"))),
            is.finite(sub_mm) && is.finite(can_mm) && sub_mm < can_mm)
        check_true(ID,
            sprintf("%s: the figure's ink stops short of BOTH edges by the margin an unmoved axis name stands in (%s .. %s of %s px, margin %s)",
                    leg, dv(paste0(leg, "_first_ink_px")),
                    dv(paste0(leg, "_last_ink_px")),
                    dv(paste0(leg, "_width_px")),
                    dv("name_plain_first_ink_px")),
            is.finite(il) && is.finite(ir) && is.finite(iw) &&
            is.finite(margin_px) && margin_px > 0 &&
            il >= margin_px && ir <= iw - margin_px)
        sub_left  <- (can_mm - sub_mm) / 2 * ppm
        sub_right <- iw - sub_left
        check_true(ID,
            sprintf("%s: and the sub-line's own footprint lies inside that ink, centred as it is drawn (%s .. %s px)",
                    leg, format(round(sub_left)), format(round(sub_right))),
            is.finite(sub_left) && is.finite(sub_right) &&
            is.finite(ppm) && ppm > 0 &&
            sub_left >= il && sub_right <= ir)
    }
}

# ===========================================================================
# 5. RULING 6, DRIVEN: THE WIDTH OF WHAT WAS PRINTED
# ===========================================================================
# Three transcripts, each of which is a shape fixed$ answers wrongly in a
# different way: exact zeros, values a few ulps from zero, and a p far past the
# APA floor.
tx <- function(name) {
    p <- file.path(ddir, paste0("info_", name, ".txt"))
    if (!file.exists(p)) return(character(0))
    readLines(p, warn = FALSE, encoding = "UTF-8")
}
t_deg  <- tx("degenerate")
t_tiny <- tx("tiny")
t_real <- tx("real")
t_norm <- tx("normality")

check_true(ID, "the four Info transcripts were captured",
           length(t_deg) > 0 && length(t_tiny) > 0 &&
           length(t_real) > 0 && length(t_norm) > 0)

# A REPORT LINE IS A LINE OF THE TRANSCRIPT THAT CARRIES A NUMBER, minus the
# ones that are allowed to carry full precision by name: the exact p that
# @emlReportPWithExact prints in parentheses beside the floored label, which
# exists precisely so that flooring at .001 does not flatten nine orders of
# magnitude. Excluding it is not a loophole -- §7 asserts that it is still
# there and still unrounded.
report_lines <- function(txt) {
    keep <- grepl("[0-9]", txt) & !grepl("\\(\\s*[0-9.eE+-]+\\s*\\)", txt) &
            !grepl("^\\s*(Sat|Sun|Mon|Tue|Wed|Thu|Fri)", txt)
    txt[keep]
}
# THE ESCAPE, AS A PATTERN: more than four digits after a decimal point.
too_wide <- function(txt) {
    ll <- report_lines(txt)
    ll[grepl("[0-9]\\.[0-9]{5,}", ll)]
}
tx_by_name <- list(degenerate = t_deg, tiny = t_tiny,
                   real = t_real, normality = t_norm)
for (nm in names(tx_by_name)) {
    bad <- too_wide(tx_by_name[[nm]])
    check_true(ID,
        sprintf("the %s report prints nothing wider than four decimals (%d offending line(s))",
                nm, length(bad)),
        length(bad) == 0L)
}

# THE BARE ZERO, WHICH IS THE SAME DEFECT WITH THE OPPOSITE SIGN. An exact zero
# printed "0" against a column of "[-3.0871, 3.0871]" -- the one number a
# reader most wants to recognise at a glance was the one that did not line up.
# Asserted on the two tables it was reported from rather than on the whole
# transcript, because "N 10" and "Groups 3" are integers and belong bare.
# THE BLOCK, NOT THE FILE. Every one of these transcripts holds several
# matrices whose rows all begin "G1", so a grep over the whole capture answers
# a question about the Tukey table with a row of the Cohen's d one -- which is
# how the first draft of this section passed while reading the wrong cells.
block_after <- function(txt, heading, n = 10L) {
    i <- grep(heading, txt, fixed = TRUE)
    if (!length(i)) return(character(0))
    j <- seq(i[1] + 1L, min(i[1] + n, length(txt)))
    txt[j]
}
dz <- block_after(t_deg, "Tukey HSD Mean Differences", 8L)
dz <- dz[grepl("^G[0-9] . G[0-9]", dz)]
check_true(ID,
    sprintf("a Tukey difference of two identical means prints at full width, not as a bare 0 (%s)",
            trimws(dz[1] %or% "<no rows>")),
    length(dz) == 3L && all(grepl("\\s0\\.0000\\s", dz)))
# AND THE COHEN'S d MATRIX BESIDE IT, which is a separate cell writer -- a
# break test reverts each of them on its own to prove the two are independent.
dmat <- block_after(t_deg, "Pairwise Effect Sizes (Cohen's d)", 8L)
dmat <- dmat[grepl("^G[0-9]\\s+(---|[-0-9])", dmat)]
check_true(ID,
    sprintf("and so does a Cohen's d of no difference (%s)",
            trimws(dmat[1] %or% "<no rows>")),
    length(dmat) == 3L && all(grepl("\\s0\\.000\\s", dmat)) &&
    !any(grepl("\\s0\\s{2,}", dmat)))

# THE TWO-WAY TABLE, WHICH IS WHERE THE WIDTH BECAME AN ALIGNMENT FAULT. Every
# column is padded to a fixed width, so a seventeen-decimal SS did not merely
# look wrong -- it ran into the next column. The check is that the header's
# column starts still line up with the data's.
tw_head <- grep("^Source\\s+SS\\s+df\\s+MS\\s+F\\s+p", t_tiny)
check_true(ID, "the two-way ANOVA table was printed", length(tw_head) == 1L)
if (length(tw_head) == 1L) {
    rows <- t_tiny[seq(tw_head + 1L, min(tw_head + 5L, length(t_tiny)))]
    rows <- rows[nzchar(trimws(rows))]
    # The SS column starts at character 21 in the header; every data row must
    # put its second field there too. At HEAD the f1 row read
    # "0.000000000000001     0.000000000000002.0000" -- one field where the
    # table has three.
    fields <- lapply(rows, function(r) strsplit(trimws(r), "\\s{2,}")[[1]])
    check_true(ID,
        sprintf("and its rows still have their columns (%s)",
                paste(vapply(fields, length, 0L), collapse = "/")),
        length(fields) >= 4L &&
        all(vapply(fields[1:3], length, 0L) >= 6L))
    check_true(ID,
        "and no cell in it has run into its neighbour",
        !any(grepl("[0-9]\\.[0-9]+\\.[0-9]", rows)))
}

# THE SHARED NORMALITY REPORTER, which lives in the annotation file and prints
# the criterion thresholds as well as the statistics.
sk <- grep("^  Skewness\\s+-?[0-9]", t_norm, value = TRUE)
check_true(ID,
    sprintf("a symmetric column's skewness prints at four decimals, not seventeen (%s)",
            trimws(sk[1] %or% "<none>")),
    length(sk) == 2L && !any(grepl("[0-9]\\.[0-9]{5,}", sk)) &&
    grepl("\\s0\\.0000\\s*($|\\t)", sk[1]))
cr <- grep("criterion:", t_norm, value = TRUE)
check_true(ID,
    sprintf("and the criterion it is judged against prints as a whole number (%s)",
            trimws(cr[1] %or% "<none>")),
    length(cr) >= 2L && all(grepl("< [0-9]+\\)$", cr)))

# ---------------------------------------------------------------------------
# 5b. THE PER-GROUP BRANCH OF THE NORMALITY WRAPPER -- THE GUI LEG
# ---------------------------------------------------------------------------
# Ruling 6's fourth site, and the only one in this change that cannot be
# reached from `praat --run`: it is inline in a script whose first statement is
# `beginPause:`. harness/drawlayer/pergroup_gui.sh drives it on rig instance 7
# and captures the Info window verbatim. The section is SKIPPED, loudly, rather
# than passed by default when no capture is present -- a validator that treats
# a missing GUI capture as agreement is the failure mode harness/normality's
# own header warns about.
t_pg <- tx("pergroup")
if (!length(t_pg)) {
    cat(paste0(
        "      SKIP v66: no per-group capture. Ruling 6's fourth site is the\n",
        "            PER-GROUP branch of plugin/scripts/eml-check-normality.praat,\n",
        "            which needs an X server. Run:\n",
        "              bash harness/drawlayer/pergroup_gui.sh\n"))
} else {
    pg <- grep("^\\s+W = ", t_pg, value = TRUE)
    check_true(ID,
        sprintf("the per-group branch was driven and reported both groups (%d)",
                length(pg)),
        length(pg) == 2L)
    check_true(ID,
        sprintf("its Shapiro-Wilk W prints at four decimals and its p in APA style (%s)",
                trimws(pg[1] %or% "<none>")),
        length(pg) == 2L && all(grepl("W = [0-9]\\.[0-9]{4}\\s", pg)) &&
        all(grepl("p [<>=] \\.[0-9]{3}$", trimws(pg))))
    pgs <- grep("^\\s+Skewness = ", t_pg, value = TRUE)
    check_true(ID,
        sprintf("and a symmetric group's skewness is 0.000, not seventeen decimals of noise (%s)",
                trimws(pgs[1] %or% "<none>")),
        length(pgs) == 2L && !any(grepl("[0-9]\\.[0-9]{4,}", pgs)) &&
        grepl("Skewness = 0\\.000\\s", pgs[1]))
    # AND THE READING UNDERNEATH STILL DISCRIMINATES, which is what says a
    # display repair did not become a decision repair. The rule reads the raw
    # .skew, .kurt and Shapiro-Wilk p, never these strings.
    #
    # WHAT IS PINNED HERE IS THE DISCRIMINATION, NOT THE SENTENCE. The two
    # groups in this fixture are built to land on opposite sides of the rule
    # -- "sym" is symmetric, "skw" is skewed past the threshold -- so the
    # assertion is that the wrapper says something DIFFERENT about them, and
    # that the flagged one is the skewed one. Pinning the verdict's exact
    # wording would make the wording unfixable, and this wrapper's wording is
    # deliberately evidence-scoped rather than a recommendation: it reports a
    # departure, it does not name a family of tests, because nothing on that
    # screen knows what analysis the user intends.
    # Located by an ASCII substring. The line begins with an arrow glyph, and
    # grepping a multi-byte literal aborts the run outright when the suite is
    # started in a non-UTF-8 locale -- "unable to translate to a wide string",
    # which ends the validator rather than failing a check.
    arrows <- trimws(grep("thresholds: Shapiro-Wilk", t_pg,
                          value = TRUE, fixed = TRUE, useBytes = TRUE))
    check_true(ID,
        sprintf("the per-group branch prints one reading per tested group (%d found)",
                length(arrows)),
        length(arrows) == 2L)
    check_true(ID,
        "and it reaches DIFFERENT readings for the symmetric and the skewed group",
        length(arrows) == 2L && !identical(arrows[1], arrows[2]))
    check_true(ID,
        "and the skewed group is the one flagged for a strong departure",
        length(arrows) == 2L &&
        !grepl("Strong departure", arrows[1]) &&
        grepl("Strong departure", arrows[2]))
    # The thresholds it read against are on the line, so a reader can check
    # the printed skewness against them without leaving the report.
    check_true(ID,
        "and each reading shows the thresholds it was made against",
        length(arrows) == 2L &&
        all(grepl("Shapiro-Wilk p < .05", arrows, fixed = TRUE)) &&
        all(grepl("|skew| >= 2", arrows, fixed = TRUE)))
}

# ===========================================================================
# 6. THE FIX-SHAPED FIX: THE NUMBERS ARE STILL THE NUMBERS
# ===========================================================================
# The cheapest way to pass every width check in §5 is a formatter that returns
# a zero of the right shape for everything. "0.0000" in every cell satisfies
# "exactly four decimals", satisfies "no bare zero", and is catastrophically
# wrong. So the same reports are driven over WELL SEPARATED groups and a real
# linear relationship, and the printed numbers are compared against values
# recomputed here in base R from the same fixture.
#
# THE FIXTURE IS RESTATED RATHER THAN READ. A validator that recomputed from a
# file the harness wrote would agree with the harness about a fixture that was
# wrong; this one builds the same rows from the same arithmetic the drive uses.
g   <- rep(1:3, each = 10)
k   <- rep(1:10, times = 3)
val <- 10 + g * 4.5 + (k %% 5) * 0.7
xx  <- seq_len(30)
yy  <- 3.25 + 1.7 * xx + (k %% 3) * 0.4

grand <- mean(val)
gm    <- tapply(val, g, mean)
ssb   <- sum(10 * (gm - grand)^2)
ssw   <- sum((val - gm[as.character(g)])^2)
fstat <- (ssb / 2) / (ssw / 27)
eta2  <- ssb / (ssb + ssw)

num_after <- function(txt, label, n = 1L) {
    ln <- grep(label, txt, value = TRUE)
    if (!length(ln)) return(NA_real_)
    m <- regmatches(ln[1], gregexpr("-?[0-9]+\\.[0-9]+", ln[1]))[[1]]
    if (length(m) < n) return(NA_real_)
    as.numeric(m[n])
}

if (length(t_real)) {
    check(ID, "the printed one-way F is the F the data has",
          num_after(t_real, "^  F  "), fstat, tol = 5e-4)
    check(ID, "and the printed eta-squared is the eta-squared",
          num_after(t_real, "Effect size\\s+eta-squared"), eta2, tol = 5e-4)
    check(ID, "and the between-groups SS in the table is the real SS",
          num_after(t_real, "^Between"), ssb, tol = 5e-3)
    check(ID, "and the within-groups SS too",
          num_after(t_real, "^Within"), ssw, tol = 5e-3)
    # THE GROUP DESCRIPTIVES, which a clamp-to-zero formatter would flatten
    # into three identical rows of 0.00.
    # The descriptives row is "G1  10  15.90  1.04  15.90": N first and bare,
    # then the mean. The mean is the first field with a decimal point, which
    # is what distinguishes it from the count beside it.
    gd <- block_after(t_real, "Group Descriptives", 6L)
    gd <- gd[grepl("^\\s*G[0-9]\\s+[0-9]", gd)]
    for (i in 1:3) {
        check(ID, sprintf("group G%d's printed mean is its mean", i),
              if (length(gd) >= i)
                  as.numeric(regmatches(gd[i],
                      gregexpr("-?[0-9]+\\.[0-9]+", gd[i]))[[1]][1])
              else NA_real_,
              as.numeric(gm[i]), tol = 5e-3)
    }
    # THE TUKEY DIFFERENCES, signed, which is the column the bare zero came
    # from -- so this is the same cell writer checked for value rather than
    # for width.
    check(ID, "the printed G1 - G2 mean difference is the real difference",
          num_after(t_real, "^G1 . G2"), as.numeric(gm[1] - gm[2]), tol = 5e-4)
    check(ID, "and G1 - G3",
          num_after(t_real, "^G1 . G3"), as.numeric(gm[1] - gm[3]), tol = 5e-4)

    # THE REGRESSION, a different reporter and a different table shape.
    fit <- lm(yy ~ xx)
    check(ID, "the printed intercept is the OLS intercept",
          num_after(t_real, "^  \\(Intercept\\)"),
          unname(coef(fit)[1]), tol = 5e-4)
    check(ID, "the printed slope is the OLS slope",
          num_after(t_real, "^  x\\s"), unname(coef(fit)[2]), tol = 5e-4)
    check(ID, "and the printed R-squared is the real R-squared",
          num_after(t_real, "Variance explained"),
          summary(fit)$r.squared, tol = 5e-4)
    # THE CORRELATION CI, the last of the reporters that had a raw fixed$.
    check(ID, "the printed Pearson r is the real r",
          num_after(t_real, "^  r\\s"), cor(xx, yy), tol = 5e-4)
}

# ===========================================================================
# 7. THE OTHER FIX-SHAPED FIX: THE EXPORT STILL CARRIES FULL PRECISION
# ===========================================================================
# The ruling puts full precision in the CSV, which is the artefact a reader is
# meant to compute from. A repair that satisfied §5 by rounding the DATA would
# leave the report looking right and the export quietly ruined -- and §6 would
# not catch it, because §6's tolerances are looser than four decimals. The rows
# below come from the SAME run as the transcript, dumped after each
# orchestrator because @emlCSVInit resets the buffer at every one.
csv_all <- unlist(dl[grepl("(^|\\.)csv_", names(dl))], use.names = FALSE)
check_true(ID, "the export rows were captured beside the report",
           length(csv_all) > 20L)
if (length(csv_all) > 20L) {
    csv_val <- function(pat) {
        r <- grep(pat, csv_all, value = TRUE)
        if (!length(r)) return(NA_character_)
        sub("^.*,", "", r[1])
    }
    long_enough <- function(s) {
        d <- sub("^[^.]*\\.", "", s %or% "")
        nchar(d) > 6L
    }
    # Field names read off the export, not guessed: a regression coefficient is
    # written as `<term>,coefficient,estimate`, so "slope" is not a field name
    # anywhere in this file.
    for (field in c("eta_squared", "cohens_d", "r_squared",
                    "x,coefficient,estimate")) {
        v <- csv_val(paste0(",", field, ","))
        check_true(ID,
            sprintf("the CSV still carries %s to full precision (%s)", field,
                    v %or% "<absent>"),
            !is.na(v) && long_enough(v))
    }
    # AND THE REPORT DOES NOT. Both halves, or "full precision everywhere"
    # would pass this section and fail the ruling.
    check_true(ID,
        "while the report's own eta-squared is four decimals",
        grepl("eta-squared = [0-9]\\.[0-9]{4}(\\s|$)",
              paste(grep("Effect size", t_real, value = TRUE), collapse = " ")))
    # THE EXACT p BESIDE THE FLOORED LABEL, which §5 excluded by name and
    # which has to still be there.
    check_true(ID,
        "and the exact p is still printed beside the floored one",
        any(grepl("p\\s+< \\.001\\s+\\([0-9.eE+-]+\\)", t_real)))
}

# ===========================================================================
# 8. RULING 8c -- THE ONE-BIN SPECTRUM, WHICH THIS FILE FOUND AND MEASURED
# ===========================================================================
# A Spectrum drawn over a frequency range containing ONE bin rendered an empty
# frame with axis furniture only. Praat's Spectrum `Draw:` joins bin points
# with line segments, and one point is no segment -- so the bin holding the
# peak of the tone was on the axis and not on the paper. Two bins in range draw
# normally, which is the control that says the finding is about the count and
# not about the range. Widening the range is ruled out by NEW-G8-1.
#
# THE AUTHOR RULED ON 16 AUGUST 2026: draw what you can, as a stem to the frame
# floor, and refuse a bin that falls below the axis floor rather than drawing
# it off the paper. The REPAIR is pinned in validate/v67, which owns the
# spectrum's axis surface and measures the stem's height in pixels against
# Praat's own vertex. What stays here is what this file found -- the fixture,
# the count and the control -- because a finding that moves to another file
# leaves nothing behind saying how it was reached.
if (have_dl) {
    check_true(ID,
        sprintf("the one-bin probe really does put one bin in range (bin width %s Hz)",
                dv("onebin.onebin_bin_width")),
        identical(dv("onebin.onebin_bins_in_range"), "1"))
    check_true(ID,
        sprintf("and that bin is the peak of the tone (%s dB)",
                dv("onebin.onebin_peak_db")),
        is.finite(dn("onebin.onebin_peak_db")) &&
        dn("onebin.onebin_peak_db") > 60)
    check_true(ID,
        sprintf("while the two-bin control draws normally (%s ink)",
                dv("twobin_interior_ink")),
        is.finite(dn("twobin_interior_ink")) &&
        dn("twobin_interior_ink") > 100)
    check_true(ID,
        sprintf("and the one-bin spectrum now has ink inside its frame too (%s)",
                dv("onebin_interior_ink")),
        is.finite(dn("onebin_interior_ink")) &&
        dn("onebin_interior_ink") > 100)
    attest(ID,
           sprintf("the one-bin spectrum was measured: %s bin, %s dB, %s ink inside the frame, %s bytes",
                   dv("onebin.onebin_bins_in_range"), dv("onebin.onebin_peak_db"),
                   dv("onebin_interior_ink"), dv("onebin_bytes")),
           "driven live through @emlDrawSpectrum; the stem's HEIGHT is pinned in validate/v67")
}

# ===========================================================================
# 8b. THE SAME DEFECT AT THE SECOND SITE -- THE ONE-BIN LTAS CURVE
# ===========================================================================
# WHY THIS SECTION EXISTS. §8's finding was not one procedure's accident. The
# Ltas "Curve" style draws with the same idiom -- join the bins whose centres
# fall inside the window with line segments -- and one point is no segment
# there either. On 16 August 2026 it was measured: one bin at 100 Hz per bin
# holding 66.95 dB, ZERO ink inside a fully furnished frame, while the SAME bin
# drawn in "Bars" style put 3,839 pixels on the page.
#
# AND IT IS MORE REACHABLE THAN THE SPECTRUM'S, which is the part that made it
# worth chasing rather than filing. A Spectrum's bin width is 1/duration, so
# the window that triggers §8 shrinks as the recording lengthens and a long
# recording is safe. An Ltas bin width is the bandwidth the CALLER chose -- 100
# Hz, the form's own default -- so a 100 Hz window does it at any recording
# length whatever. And "Curve" is the style @emlDrawLTAS installs when the
# caller enables none of the four, so it is what a user gets without asking
# for it.
#
# WHAT THE FAILURE LOOKS LIKE. A FILE, and a large one -- 46 KB with the grid
# off and more with it on -- carrying a box, ticks, both axis names and a
# title, and nothing else. There is no error, no warning and no empty-looking
# output; the figure looks like a figure of a quiet band. The only thing wrong
# with it is that the band was not quiet.
#
# WHAT COULD NOT HAVE CAUGHT IT, and why, because this is a family of checks
# that all say yes:
#
#   ANYTHING THRESHOLDING ON FILE SIZE. 46,360 bytes for the empty frame here
#   and 46,129 for the bar figure that is CORRECT -- the empty one is the
#   LARGER file of the two. A 20 KB floor waves both through and would have
#   waved through §2's 52 KB empty violin as well.
#
#   ANYTHING COUNTING DRAW CALLS. The procedure issued its `Draw:` exactly as
#   it always had. Praat executed it and returned success. There is no missing
#   call, no exception and no degenerate argument -- the call is right and the
#   renderer has nothing to join.
#
#   ANY INK COUNT ON ITS OWN, which is the trap this section is built around.
#   "There is ink inside the frame" is satisfied by a stem run to the top of
#   the panel, which is the fix-shaped fix for an empty-figure finding: the
#   right mark at a value nobody chose. So the height is measured too, and it
#   is measured RELATIVELY -- the top row of the stem against the top row of
#   Praat's own bar for the same bin -- so that it needs no theme constant, no
#   axis arithmetic and no assumption about where the panel starts.
#
#   AND NOT FIRST-INK POSITION, which is §3's ruler and is the wrong one here.
#   First ink moves the wrong way when the thing being caught is a mark that
#   was clipped away: §3 records that an axis name shifted ten times too far
#   came back starting FURTHER RIGHT than the intact one. A bounding box taken
#   inside the frame has no such reversal.
if (have_dl) {
    # --- THE SOURCE. The comments are stripped by read_code before any of this
    # matches, so what is asserted below is the branch and never the paragraph
    # explaining the branch.
    lt <- proc_body_of(code_draw, "emlDrawLTAS")
    check_true(ID, "@emlDrawLTAS exists and was found",
               length(lt) > 0)
    check_true(ID,
        "the Ltas Curve style counts the bins in the window before it draws",
        any(grepl("^\\.curveBins = \\.curveHi - \\.curveLo \\+ 1$", lt)))
    check_true(ID,
        "and Praat's own Curve is reached only with at least two of them",
        any(grepl("^if \\.curveBins >= 2$", lt)) &&
        sum(grepl('^Draw: .*"Curve"$', lt)) == 1L)
    check_true(ID,
        "while a single bin is drawn as a stem the renderer cannot refuse",
        any(grepl("^elsif \\.curveBins = 1$", lt)) &&
        any(grepl("^Draw line: \\.curveFreq, \\.powerMin, \\.curveFreq, \\.curveVal$",
                  lt)))
    # THE ALTERNATIVE REMEDY, RULED OUT AND PINNED SO IT STAYS RULED OUT.
    # Falling the one-bin Curve back to Praat's "Bars" style would also put ink
    # on the page and would be wrong here for a reason peculiar to this
    # procedure: Bars is one of FOUR independent checkboxes on the form, drawn
    # from the same palette sequence in a different colour. A Curve that turned
    # into Bars would hand a user who switched Bars off the layer they switched
    # off, and would hand a user who switched both on the same bin twice, in
    # two colours, one filled rectangle over another. Exactly one `Draw:` in
    # this procedure may name "Bars", and it is the Bars layer's own.
    check_true(ID,
        "and the Curve style does not quietly become the Bars style, which is a separate setting here",
        sum(grepl('^Draw: .*"Bars"$', lt)) == 1L)

    # --- THE FIXTURE. Asserted rather than assumed: a probe that stopped being
    # a one-bin probe would turn every measurement below green for the wrong
    # reason, which is what break_onebin_probe_wrong exists to demonstrate on
    # §8's side of the same argument.
    check_true(ID,
        sprintf("the Ltas probe puts one bin in the window at the caller's own bandwidth (%s Hz per bin)",
                dv("ltas_onebin.ltas_onebin_bin_width")),
        identical(dv("ltas_onebin.ltas_onebin_bins_in_range"), "1") &&
        is.finite(dn("ltas_onebin.ltas_onebin_bin_width")) &&
        dn("ltas_onebin.ltas_onebin_bin_width") == 100)
    check_true(ID,
        sprintf("and that bin holds the tone, not silence (%s dB)",
                dv("ltas_onebin.ltas_onebin_peak_db")),
        is.finite(dn("ltas_onebin.ltas_onebin_peak_db")) &&
        dn("ltas_onebin.ltas_onebin_peak_db") > 60)

    # --- WHICH BRANCH RAN, taken from the procedure and not inferred from the
    # picture. An ink count cannot tell a stem from a bar from a curve.
    check_true(ID,
        sprintf("the one-bin figure went through the stem branch (%s bin, stem %s)",
                dv("ltas_onebin.ltas_onebin_curve_bins"),
                dv("ltas_onebin.ltas_onebin_curve_stem")),
        identical(dv("ltas_onebin.ltas_onebin_curve_bins"), "1") &&
        identical(dv("ltas_onebin.ltas_onebin_curve_stem"), "1"))
    check_true(ID,
        sprintf("and the two-bin control did NOT -- it is Praat's own Curve (%s bins, stem %s)",
                dv("ltas_twobin.ltas_twobin_curve_bins"),
                dv("ltas_twobin.ltas_twobin_curve_stem")),
        identical(dv("ltas_twobin.ltas_twobin_curve_bins"), "2") &&
        identical(dv("ltas_twobin.ltas_twobin_curve_stem"), "0"))

    # --- THE PICTURES.
    check_true(ID,
        sprintf("the one-bin Ltas Curve has data inside its frame (%s ink; at HEAD it measured 0)",
                dv("ltas_onebin_interior_ink")),
        is.finite(dn("ltas_onebin_interior_ink")) &&
        dn("ltas_onebin_interior_ink") > 100)
    check_true(ID,
        sprintf("the two-bin control still draws, unchanged (%s ink)",
                dv("ltas_twobin_interior_ink")),
        is.finite(dn("ltas_twobin_interior_ink")) &&
        dn("ltas_twobin_interior_ink") > 100)
    check_true(ID,
        sprintf("and the SAME bin in Bars style always could, which is what makes it a defect and not a limit (%s ink)",
                dv("ltas_onebin_bars_interior_ink")),
        is.finite(dn("ltas_onebin_bars_interior_ink")) &&
        dn("ltas_onebin_bars_interior_ink") > 100)

    # --- THE VALUE, WHICH IS THE CHECK THE INK COUNT IS NOT.
    # Both boxes are WxH+X+Y against the same interior crop of two figures of
    # the same bin on the same axis with the grid off. Praat's bar is a
    # horizontal segment a few rows thick at the bin's value; the stem is a
    # vertical line from the frame floor to it. The stem's TOP ROW must fall
    # inside the rows the bar occupies -- not near them, inside them. A stem
    # clamped to the top of the panel, or to the floor, or drawn at a hard-
    # coded height fails this while passing every ink count above.
    parse_box <- function(s) {
        m <- regmatches(s, regexec("^([0-9]+)x([0-9]+)\\+([0-9-]+)\\+([0-9-]+)$",
                                   s %or% ""))[[1]]
        if (length(m) != 5L) return(NULL)
        as.integer(m[-1])
    }
    b_stem <- parse_box(dv("ltas_onebin_interior_box"))
    b_bar  <- parse_box(dv("ltas_onebin_bars_interior_box"))
    check_true(ID,
        sprintf("both figures of the bin produced a measurable box (stem %s, bar %s)",
                dv("ltas_onebin_interior_box"), dv("ltas_onebin_bars_interior_box")),
        !is.null(b_stem) && !is.null(b_bar) &&
        b_stem[2] > 0 && b_bar[2] > 0)
    check_true(ID,
        sprintf("and the stem tops out on a row Praat's own bar for the same bin occupies (stem row %s; bar rows %s..%s)",
                if (is.null(b_stem)) NA else b_stem[4],
                if (is.null(b_bar)) NA else b_bar[4],
                if (is.null(b_bar)) NA else b_bar[4] + b_bar[2] - 1L),
        !is.null(b_stem) && !is.null(b_bar) &&
        b_stem[4] >= b_bar[4] && b_stem[4] <= b_bar[4] + b_bar[2] - 1L)
    check_true(ID,
        sprintf("and it runs DOWN to the frame floor rather than being a mark of its own (%s px tall in a %s px interior)",
                if (is.null(b_stem)) NA else b_stem[2], 920L),
        !is.null(b_stem) && !is.null(b_bar) &&
        b_stem[4] + b_stem[2] >= 918L)

    # THE TRAP, SAID AS A NUMBER, the same way §2 says it.
    attest(ID,
        sprintf("the empty one-bin Ltas weighed 46,360 bytes and the CORRECT bar figure %s -- the empty file was the bigger one",
                dv("ltas_onebin_bars_bytes")),
        "measured 16 Aug 2026 on Praat 6.6.30; a size threshold cannot separate them in either direction")
}

if (!exists("EML_SUITE")) {
    eml_report("v66 draw layer: the recorded axis, the axis name, the disclosure and the width")
    eml_exit()
}
