# ============================================================================
# v97_line_tree.R -- the line chart's question tree, walked with a keyboard
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THE PAGE USED TO ASK, AND WHY IT NO LONGER DOES. The line chart's
# first question was "Data format: Wide (multiple columns) / Long (value +
# group)". That is a question about the user's FILE, and the plugin can answer
# it for itself -- it can see which columns are numeric and which name things.
# What it cannot see, and what nothing in the file records, is whether several
# numeric columns are the SAME measurement on different subjects or DIFFERENT
# measurements on one subject. Four singers' F0 and one singer's F0 beside a
# contact quotient are the same table shape and completely different figures:
# one shared vertical axis in the first case, two scales in the second.
#
# AND THE ANSWER IS INDEPENDENT OF THE STORAGE, WHICH IS THE 19 AUGUST
# ADDITION AND THE POINT OF THE WHOLE TREE. "Different measurements" reaches
# the same figure whether the file holds the two side by side or stacked in
# one column beside a column naming what was measured -- which is the shape
# every EML stats tool in this plugin emits. When the table is long the series
# are the LEVELS of the name column: two reach the right-hand axis page, three
# or more meet the refusal three columns meet. Underneath,
# @emlGraphsPivotSeries spreads the levels into a column each before the draw
# call -- the mirror image of the melt, and equally invisible. Section 16.
#
# WHAT SHIPPED. The storage question is gone and the meaning question is in
# its place, on a page of its own; the column page is BUILT FROM THE TABLE --
# one tickbox per numeric column, all ticked, no ceiling, where five hardcoded
# "Series N" menus used to be; the confidence interval is offered only when
# the table actually carries repeated observations, and the offer names how
# many it found; the right-hand axis page is reached only from "different
# measurements, exactly two", so a column cannot be both melted into the left
# side and chosen for the right; and three or more unlike measurements are
# refused toward stacked panels rather than normalised onto one scale.
#
# WHAT CHANGED ON 19 AUGUST 2026, and what in this file moved with it. Four
# edits, and three of them replaced a check here rather than adding one.
#
#   * "Series names come from" is built over the TEXT columns the survey
#     found, and opens on the first of them. It used to be built over EVERY
#     column and seeded from @emlGuessColumnRoles, which on a time/f0/speaker
#     table guessed TIME -- so the page opened proposing to name the series
#     after the horizontal axis, and the repeat scan, keyed on that proposal,
#     counted 8 observations a point where the grouping the user wants has 4.
#     Section 9 USED TO REQUIRE THAT: it asked the first page for "up to 8"
#     and the third for "up to 4" and called the pair the fork. That was a
#     defect being pinned. It now asks that the count match the grouping in
#     force on every presentation, and that 8 appear on none of them; section
#     9B is new and is about the menu itself.
#   * A "Y axis label" field appears on the BEGINNER column page when the
#     figure is several columns of one measurement. Those column names name
#     the subjects, so nothing in the table names the quantity they share and
#     the label cannot compose itself; the advanced page's field was the only
#     place to type it, and beginner is the shipped default. Section 4B is
#     new. Exactly one of the two fields exists at a time -- they derive the
#     same variable name, so two live ones would be a page whose second field
#     silently wins.
#   * The form no longer prints "Repeated observations were found ...;
#     intervals are not offered across two scales." @emlDrawTimeSeries says it
#     now, through @emlDisclose, which is the channel that reaches the figure
#     as well as the Info window. Section 7's check on the form's Info line is
#     replaced by one on the draw layer's disclosure, and the check that
#     required this leg to be pointed at Time Series (with CI) is replaced by
#     one that requires it NOT to be -- that figure has no right-hand axis
#     either, so the advice was wrong on the arm it was being asked for.
#
# ============================================================================
# WHY THIS FILE READS A GUI TRANSCRIPT AND NOT THE FORM'S SOURCE
# ============================================================================
# EVERY CLAIM IN THE PARAGRAPH ABOVE IS ABOUT WHAT A USER SEES AND CAN REACH.
# A source grep can say the code builds a tickbox per numeric column; it
# cannot say Praat executes field declarations inside an open beginPause
# block, that a field built in a loop is readable afterwards through 'name$'
# substitution, or that seven of them fit. Those are facts about 6.6.30, and
# on 18 August 2026 this tree was wrong about one of them in a way no grep
# could have caught: Praat truncates a field's derived variable name at the
# first character that cannot be in an identifier, so `optionmenu: "Right-hand
# axis"` is readable only as `right`, and every "different measurements" draw
# aborted with "Unknown variable: right_hand_axis" the instant Draw was
# pressed. The page looked correct in the source and could not be got past.
#
# So harness/linetree DRIVES THE DIALOGS -- Xvfb, matchbox, xdotool, window
# lookup through _NET_CLIENT_LIST, one Praat process per leg -- photographs
# every page BEFORE it is dismissed, OCRs the photograph, and then reads the
# form's own variables back out of the process that drew. This file asserts on
# those pixels and those variables. Where it does make a statement about
# SHAPE -- that a control does not exist, that a name is spelled one way in
# two files -- it says so and reads the source, which is sections 12 to 14.
#
# THE OCR IS TREATED AS OCR. tesseract on a 12 px GTK label renders "f0" as
# "fo" and "c1" as "cl", and a check that demanded the glyphs be perfect would
# fail on the renderer rather than on the plugin. Every check below that reads
# a photographed label either matches a phrase long enough that no plausible
# misread satisfies it, or states its tolerance in its own text and quotes the
# raw string it matched. The refusals came back clean and are matched on their
# words.
#
# ============================================================================
# WHAT THIS FILE READS
# ============================================================================
#
# harness/linetree/out/LINETREE.tsv -- case / key / value, 15 legs:
#
#   subjects4      4 subject columns, one row per time      dispatch row 1
#   subjects_ci    time/f0/speaker, 4 observations a point  dispatch row 2
#   meas2          time/f0/cq, one row per time             dispatch row 3
#   meas2_rep      time/f0/cq, 3 rows per time              dispatch row 4
#   meas3_refuse   three measurements -> refused, then two
#   none_refuse    every column unticked -> refused, then one
#   seven          seven numeric columns, the ceiling test
#   script_refuse  a right-hand axis asked for by a SCRIPT under
#                  role = subjects, and the same request honoured under
#                  role = measurements -- the only leg with no dialog,
#                  because the tree cannot ask for that figure and the
#                  callers that can have no dialog to ask through
#   long_meas2     time/value/measure, two levels                section 16
#   long_meas3_refuse  three levels -> refused, then one series
#   long_titled    the same numbers as meas2, stored long, titled
#   wide_titled    the same numbers, stored wide, same title
#   rec_subjects4  subjects4 with the recorder running
#   rec_meas2      meas2 with the recorder running
#   rec_long_meas2 long_meas2 with the recorder running
#
# and one non-leg row group, "--pairs--": the file-level comparison of the two
# shapes' figures, written by harness/linetree/pngdiff.py. Section 16.4 is
# what it is for, and it is the claim this whole directory exists to make.
#
#     bash harness/linetree/run.sh     regenerate (a subset drives that
#                                      subset and carries the rest over,
#                                      refusing if the code has moved)
#     bash harness/linetree/break.sh   drive the ten deliberate defects
#
# and the source of the three graph files plus the recorder, for the
# statements that are about shape.
#
# $EML_LT_DIR and $EML_LT_SRC point this file at a different artefact and a
# different tree, which is how a break run scores a patched copy without
# touching the working tree. EML_LT_SRC accepts either a plugin directory or
# a repository root holding one, because harness/linetree/break.sh uses the
# same variable for the root it patches.
#
# THE TRANSCRIPT IS BOUND TO THE CODE THAT PRODUCED IT. Section 1 recomputes
# the sha256 of the three graph files, comments stripped, and requires it to
# equal what the driver recorded. Yesterday's screenshots cannot validate
# today's form, and on this feature that is not a hypothetical either: the
# tree was edited under the driving session mid-run and one leg's figure
# changed title between two drives of the same path.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v97"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

OUT  <- Sys.getenv("EML_LT_DIR", unset = repo_path("harness", "linetree", "out"))
PLUG <- Sys.getenv("EML_LT_SRC", unset = repo_path("plugin_EML_StatsGraphs"))
# break.sh patches a whole REPOSITORY into /tmp and points EML_LT_SRC at it,
# because that is what run.sh's own seam takes. Descend one level rather than
# make the two variables mean different things in two files.
if (dir.exists(file.path(PLUG, "plugin_EML_StatsGraphs"))) {
    PLUG <- file.path(PLUG, "plugin_EML_StatsGraphs")
}
TSVP <- file.path(OUT, "LINETREE.tsv")

# Every leg the harness drives, and every one this file asserts on. The two
# lists are compared at the end (eml_census): a leg the driver renders that
# nothing here reads is silent non-coverage, which is what that census is for.
CASES <- c("subjects4", "subjects_ci", "meas2", "meas2_rep",
           "meas3_refuse", "none_refuse", "seven", "script_refuse",
           # THE TWO RECORDER LEGS, added 19 August 2026. They walk the same
           # dialogs as subjects4 and meas2 -- deliberately the same, so that
           # a difference between a session figure and its replay cannot be a
           # difference in the walk -- with the recorder RUNNING, and they
           # flush the emitted script. Section 15 is about them.
           "rec_subjects4", "rec_meas2",
           # THE FIVE LONG-SHAPE LEGS, added 19 August 2026 with the pivot.
           # A table that stores two measurements stacked in one column means
           # what a table that stores them side by side means, so it has to
           # reach the same page and draw the same figure. Section 16 is about
           # them.
           #   long_meas2        the right-hand axis, reached from a long table
           #   long_meas3_refuse three levels, refused toward stacked panels
           #   long_titled       the same numbers, long, under a typed title
           #   wide_titled       the same numbers, wide, under the same title
           #   rec_long_meas2    long_meas2 with the recorder running
           "long_meas2", "long_meas3_refuse", "long_titled", "wide_titled",
           "rec_long_meas2")

# The nine legs that walked dialogs. script_refuse is not one of them: it
# runs with DISPLAY unset, on purpose.
GUI <- setdiff(CASES, "script_refuse")
# The two legs that recorded, and the leg each one twins. A recorder leg's
# figure must equal its twin's: turning the recorder on is not allowed to
# change the picture, and that statement costs nothing because the plans are
# identical by construction.
# RECLEGS and not REC: REC is this file's path to stats/eml-record.praat,
# assigned forty lines down, and a second REC would be read by whichever
# assignment ran last -- a collision R reports as "subscript out of bounds"
# at the first use and not at the assignment.
RECLEGS <- c("rec_subjects4", "rec_meas2", "rec_long_meas2")
TWIN <- c(rec_subjects4 = "subjects4", rec_meas2 = "meas2",
          rec_long_meas2 = "long_meas2")
# The one leg with repeated observations on a shared scale, named once here
# because sections 4B, 5, 9 and 9B are all about the same walk through it.
CI <- "subjects_ci"

ok_tsv <- check_true(V, "the line-tree harness has been driven",
                     file.exists(TSVP) && file.info(TSVP)$size > 0)
if (!ok_tsv) {
    check_true(V, paste0("LINETREE.tsv is missing or empty",
                         "\n  Run: bash harness/linetree/run.sh"), FALSE)
}

TR <- if (ok_tsv) {
    # quote = "" because the OCR rows carry the refusal's own double quotes
    # around "Erase page first", and read.delim would otherwise eat them --
    # they are part of what section 8 is asking about.
    read.delim(TSVP, header = FALSE, sep = "\t", stringsAsFactors = FALSE,
               quote = "", col.names = c("case", "key", "value"),
               colClasses = "character")
} else {
    data.frame(case = character(0), key = character(0), value = character(0),
               stringsAsFactors = FALSE)
}

# One measurement by name. NA when the driver recorded none, which makes a
# check about a missing measurement fail rather than error.
trv <- function(case, key) {
    hit <- TR$value[TR$case == case & TR$key == key]
    if (length(hit) == 1L) hit else NA_character_
}
trn <- function(case, key) suppressWarnings(as.numeric(trv(case, key)))
# The multi-row keys: every OCR line of a dialog, every line of the Info
# window, every line of text read off the figure.
trall <- function(case, key) TR$value[TR$case == case & TR$key == key]
# Every key a case recorded, in the order the driver wrote them.
trkeys <- function(case) TR$key[TR$case == case]

ltnorm <- function(x) gsub("[[:space:]]+", " ", trimws(x))
shown <- function(case, step) ltnorm(trall(case, paste0("s", step, "_shown")))
# The whole of one dialog as one string, which is how a wrapped sentence is
# asked about: the wrap points are the renderer's business, the words are the
# plugin's.
shown1 <- function(case, step) paste(shown(case, step), collapse = " ")
info   <- function(case) ltnorm(trall(case, "info"))
info1  <- function(case) paste(info(case), collapse = " ")
figtext  <- function(case) ltnorm(trall(case, "fig_figtext"))
figtext1 <- function(case) paste(figtext(case), collapse = " ")
# The per-colour census palette.py wrote: one row per chromatic colour with
# its pixel count.
colcounts <- function(case, prefix = "fig_colour_") {
    k <- TR$key[TR$case == case]
    v <- TR$value[TR$case == case]
    hit <- grepl(paste0("^", prefix), k)
    suppressWarnings(as.numeric(v[hit]))
}
has <- function(hay, needle) isTRUE(grepl(needle, hay, fixed = TRUE))

# The sequence of dialog titles one leg displayed, in order, read off the
# s<n>_title rows rather than restated. A leg that met an unplanned dialog
# recorded it here, and section 3 compares the whole vector.
titles <- function(case) {
    k <- trkeys(case)
    idx <- grep("^s[0-9]+_title$", k)
    if (!length(idx)) return(character(0))
    n <- as.integer(sub("^s([0-9]+)_title$", "\\1", k[idx]))
    v <- TR$value[TR$case == case][idx]
    v[order(n)]
}
wants <- function(case) {
    k <- trkeys(case)
    idx <- grep("^s[0-9]+_want$", k)
    if (!length(idx)) return(character(0))
    n <- as.integer(sub("^s([0-9]+)_want$", "\\1", k[idx]))
    v <- TR$value[TR$case == case][idx]
    v[order(n)]
}

rd <- function(p) if (file.exists(p)) readLines(p, warn = FALSE) else character(0)
FORM  <- file.path(PLUG, "graphs", "eml-graphs-form.praat")
GRAPH <- file.path(PLUG, "graphs", "eml-graph-procedures.praat")
DRAW  <- file.path(PLUG, "graphs", "eml-draw-procedures.praat")
REC   <- file.path(PLUG, "stats",  "eml-record.praat")
form_src <- rd(FORM); graph_src <- rd(GRAPH); draw_src <- rd(DRAW)
rec_src  <- rd(REC)

# ============================================================================
# 1. THE RUN, AND THE TRANSCRIPT'S BINDING TO THE CODE THAT PRODUCED IT
# ============================================================================
# A GUI transcript is a photograph. Nothing in the pixels says which form was
# on screen, so the driver records the sha256 of the three graph files with
# their comments stripped and this section recomputes it. The comment strip is
# harness/release's recipe and its reason is the same: an alarm that fires
# when a paragraph is rewrapped demands a GUI re-drive for a typo and gets
# silenced, and a comment cannot change which page appears.
py <- Sys.which("python3")
HAVE_SHA <- nzchar(Sys.which("sha256sum")) || nzchar(py)
check_true(V, "a sha256 tool is available (the staleness binding needs one)",
           HAVE_SHA)
sha256 <- function(path) {
    if (!file.exists(path)) return(NA_character_)
    if (nzchar(Sys.which("sha256sum"))) {
        o <- suppressWarnings(system2("sha256sum", shQuote(path),
                                      stdout = TRUE, stderr = FALSE))
        if (length(o)) return(sub(" .*$", "", o[1]))
    }
    if (nzchar(py)) {
        o <- suppressWarnings(system2(py, c("-c",
            shQuote("import hashlib,sys;print(hashlib.sha256(open(sys.argv[1],'rb').read()).hexdigest())"),
            shQuote(path)), stdout = TRUE, stderr = FALSE))
        if (length(o)) return(o[1])
    }
    NA_character_
}
code_sha256 <- function(path) {
    if (!file.exists(path)) return(NA_character_)
    src <- readLines(path, warn = FALSE)
    src <- src[!grepl("^[[:space:]]*[#;!]", src)]
    tmp <- tempfile(); on.exit(unlink(tmp))
    writeLines(src, tmp)
    sha256(tmp)
}
for (f in list(list(k = "eml-graphs-form",      p = FORM),
               list(k = "eml-graph-procedures", p = GRAPH),
               list(k = "eml-draw-procedures",  p = DRAW),
               # THE RECORDER IS BOUND TOO, since 19 August. Section 15's
               # claim is that a file stats/eml-record.praat emitted redraws
               # the figure byte for byte; asserting that from a transcript
               # taken against a different recorder is the same staleness the
               # other three refuse.
               list(k = "eml-record",           p = REC))) {
    check_true(V, paste0("the source of ", f$k, ".praat is present"),
               file.exists(f$p))
    check_true(V, paste0("the transcript was taken from THIS ", f$k, ".praat"),
               identical(trv("--run--", paste0("code_sha256_", f$k)),
                         code_sha256(f$p)))
}
check_true(V, "and the recorder's source is present too",
           length(rec_src) > 0)

check_true(V, "driven on Praat 6.6.30",
           has(trv("--run--", "praat_version"), "6.6.30"))
check_true(V, "with a compositor running (a bare Xvfb maps no dialog)",
           identical(trv("--run--", "compositor"), "running"))
# FIFTEEN LEGS, AND NOT NECESSARILY IN ONE INVOCATION.
#
# harness/linetree/run.sh drives a subset when it is given one and carries the
# legs it did not drive over from the transcript already on disk -- refusing to
# do so unless that transcript was taken against byte-identical code, which is
# the same staleness rule the four digests above enforce. A full drive is over
# twenty minutes and some environments will not run one command that long.
#
# SO THE QUESTION THIS ASKS IS ABOUT THE TRANSCRIPT AND NOT ABOUT ONE RUN:
# every leg is in it, and every leg in it was either driven by the invocation
# that wrote it or carried over from code identical to this code. The driver
# writes the two lists separately so that a reader can always tell which was
# which.
lt_legs <- function() {
    req <- strsplit(trv("--run--", "legs_requested"), " +")[[1]]
    car <- trv("--run--", "legs_carried")
    if (is.na(car) || identical(car, "none")) car <- character(0)
    else car <- strsplit(car, " +")[[1]]
    unique(c(req[nzchar(req)], car[nzchar(car)]))
}
check_true(V, "fifteen legs are in the transcript, driven or carried",
           length(lt_legs()) == 15L)
check_true(V, "the invocation that wrote it drove at least one of them",
           isTRUE(trn("--run--", "legs_driven") >= 1))
check_true(V, "and the legs in the transcript are the legs this file reads",
           setequal(lt_legs(), CASES))

# ============================================================================
# 2. EVERY LEG STARTED, RETURNED, AND LEFT A FIGURE
# ============================================================================
# leg_returned is written by the LAST line of the leg's own script, after the
# figure is on disk. A Praat that died inside the tree records leg_started and
# no leg_returned, and a plan that met a dialog it had no step for hangs
# instead of returning -- so this is the statement that the walk completed,
# not merely that a file exists.
for (cs in CASES) {
    check_true(V, paste0("[", cs, "] the leg started"),
               identical(trn(cs, "leg_started"), 1))
    check_true(V, paste0("[", cs, "] and returned by name"),
               identical(trv(cs, "leg_returned"), cs))
    check_true(V, paste0("[", cs, "] wrote a 300-dpi page"),
               identical(trv(cs, "fig_png_px"), "1800x1200"))
    check_true(V, paste0("[", cs, "] with a figure on it, not an empty file"),
               isTRUE(trn(cs, "fig_png_bytes") > 20000))
    check_true(V, paste0("[", cs, "] and the PNG is still beside the transcript"),
               file.exists(file.path(OUT, paste0(cs, ".png"))))
}
# NO TWO WALKS DREW THE SAME FIGURE, WITH ONE DELIBERATE EXCEPTION.
#
# Twelve legs walk without a recorder running, and eleven of their figures are
# distinct: a driver that saved one leg's page twelve times would satisfy
# every check above. The exception is wide_titled, which is the identity
# pair's other half and whose whole subject is that it IS long_titled's file
# -- section 16.4. It is named here rather than allowed to make the count one
# smaller quietly, so that a SECOND accidental collision still fails.
md5s <- vapply(CASES, function(c) trv(c, "fig_png_md5"), character(1))
SOLO <- setdiff(CASES, c(RECLEGS, "wide_titled"))
check_true(V, "the eleven distinct walks are eleven different figures",
           length(unique(md5s[SOLO])) == 11L && !any(is.na(md5s)))
# AND THE TWO RECORDER LEGS ARE NOT A NINTH AND TENTH FIGURE. They drive the
# same plans as subjects4 and meas2 with a recording running, so their pages
# must be byte-identical to their twins'. This is the statement that RECORDING
# DOES NOT CHANGE WHAT IS DRAWN -- the recorder's whole contract at the draw
# layer is to be inert -- and it is free, because the plans are copies.
for (r in RECLEGS) {
    check_true(V, paste0("[", r, "] recording changed nothing: its page is ",
                         "byte-identical to [", TWIN[[r]], "]'s"),
               !is.na(trv(r, "fig_png_md5")) &&
               identical(trv(r, "fig_png_md5"), trv(TWIN[[r]], "fig_png_md5")))
}

for (cs in GUI) {
    # THE PLAN AND THE SCREEN AGREED AT EVERY STEP. s<n>_want is what the plan
    # expected; s<n>_title is what the window manager said was on screen.
    tt <- titles(cs); ww <- wants(cs)
    check_true(V, paste0("[", cs, "] every dialog was the dialog the plan expected"),
               length(tt) > 0 && identical(tt, ww))
    check_true(V, paste0("[", cs, "] the step count matches the dialogs walked"),
               identical(trn(cs, "steps"), as.numeric(length(tt))))
    check_true(V, paste0("[", cs, "] the walk ended at Graph Complete"),
               identical(tail(tt, 1), "Graph Complete"))
    check_true(V, paste0("[", cs, "] no step waited on a window that never came"),
               identical(trn(cs, "wait_seconds"), 0))
    check_true(V, paste0("[", cs, "] and no dialog was left on screen at the end"),
               isTRUE(grepl("^(\\[Praat (Objects|Picture|Info)\\])+$",
                            trv(cs, "windows_at_exit"))))
    check_true(V, paste0("[", cs, "] the display was clear before the leg began"),
               identical(trv(cs, "display_clear"), "yes"))
}
# THE DIALOGLESS LEG IS DIALOGLESS. Its subject is the caller that has no
# dialog, so a leg that had somehow opened one would be testing the wrong
# thing.
check_true(V, "[script_refuse] ran with no dialog at all",
           length(titles("script_refuse")) == 0L)
check_true(V, "[script_refuse] and its Praat exited 0",
           identical(trn("script_refuse", "exit_code"), 0))

# ============================================================================
# 3. THE TREE THE USER WALKED
# ============================================================================
# THE WHOLE SEQUENCE, NOT A MEMBERSHIP TEST. "The right-hand axis page
# appeared" is satisfied by a form that shows it to everybody; what the ruling
# says is which pages appear, in which order, on which table. Each vector
# below is the leg's dialogs from the first press of Draw in the main form to
# the Graph Complete panel, and it is compared whole.
PAGE_A <- "Line Chart -- What the lines are"
PAGE_B <- "Line Chart -- Column Mapping"
PAGE_C <- "Line Chart -- The Right-Hand Axis"
REFUSE <- "Line chart"
WALK <- list(
    # role = subjects: meaning, columns, draw. No right-hand axis is offered
    # and none is reachable.
    subjects4    = c("EML Graphs", PAGE_A, PAGE_B, "Graph Complete"),
    seven        = c("EML Graphs", PAGE_A, PAGE_B, "Graph Complete"),
    # the same three pages with two Advanced round trips in the middle: the
    # column page re-presents ITSELF, which is why the driver waits on a
    # window id rather than on a title.
    subjects_ci  = c("EML Graphs", PAGE_A, PAGE_B, PAGE_B, PAGE_B,
                     "Graph Complete"),
    # role = measurements, exactly two: the right-hand page, and only here.
    meas2        = c("EML Graphs", PAGE_A, PAGE_B, PAGE_C, "Graph Complete"),
    meas2_rep    = c("EML Graphs", PAGE_A, PAGE_B, PAGE_C, "Graph Complete"),
    # three measurements: refused, and handed BACK to the column page rather
    # than dropped out of the form.
    meas3_refuse = c("EML Graphs", PAGE_A, PAGE_B, REFUSE, PAGE_B, PAGE_C,
                     "Graph Complete"),
    # nothing ticked: refused, handed back, and drawn once one is ticked.
    none_refuse  = c("EML Graphs", PAGE_A, PAGE_B, REFUSE, PAGE_B,
                     "Graph Complete"),
    # THE RECORDER LEGS WALK THEIR TWINS' WALKS, restated here rather than
    # copied by reference: if either plan is edited, this is the line that
    # says the comparison in section 15 stopped being like-for-like.
    rec_subjects4 = c("EML Graphs", PAGE_A, PAGE_B, "Graph Complete"),
    rec_meas2     = c("EML Graphs", PAGE_A, PAGE_B, PAGE_C, "Graph Complete"),
    # THE LONG SHAPE WALKS THE SAME PAGES AS THE WIDE ONE, and that is the
    # whole claim of section 16 expressed as a list of window titles. Two
    # measurements stacked in one column reach the right-hand axis page; two
    # measurements in two columns reach it; the walk is indistinguishable.
    long_meas2    = c("EML Graphs", PAGE_A, PAGE_B, PAGE_C, "Graph Complete"),
    long_titled   = c("EML Graphs", PAGE_A, PAGE_B, PAGE_C, "Graph Complete"),
    wide_titled   = c("EML Graphs", PAGE_A, PAGE_B, PAGE_C, "Graph Complete"),
    rec_long_meas2 = c("EML Graphs", PAGE_A, PAGE_B, PAGE_C, "Graph Complete"),
    # three LEVELS: refused, and handed back to a column page that still
    # works -- the level refusal has no tickbox to send the user to, so the
    # page it returns to has to be usable by some other route.
    long_meas3_refuse = c("EML Graphs", PAGE_A, PAGE_B, REFUSE, PAGE_B,
                          "Graph Complete"))
for (cs in names(WALK)) {
    check_true(V, paste0("[", cs, "] walked ", length(WALK[[cs]]),
                         " pages, in this order"),
               identical(titles(cs), WALK[[cs]]))
}
# THE MEANING IS ASKED ONCE PER VISIT, and it is asked before the columns.
for (cs in GUI) {
    tt <- titles(cs)
    check_true(V, paste0("[", cs, "] the meaning question is asked exactly once"),
               sum(tt == PAGE_A) == 1L)
    check_true(V, paste0("[", cs, "] and before the column page"),
               which(tt == PAGE_A)[1] < which(tt == PAGE_B)[1])
}
# THE RIGHT-HAND PAGE IS REACHED FROM ONE PLACE ONLY. Two legs see it; both
# answered "different measurements" and both drew two series. No subjects leg
# sees it, however many series it has -- seven columns do not open it.
for (cs in GUI) {
    saw <- PAGE_C %in% titles(cs)
    want <- identical(trv(cs, "series_role"), "measurements") &&
            identical(trn(cs, "n_series"), 2)
    check_true(V, paste0("[", cs, "] sees the right-hand page iff it is two ",
                         "different measurements (", saw, ")"),
               identical(saw, want))
}

# ============================================================================
# 4. DISPATCH ROW 1 -- SUBJECTS, NO REPEATS: n SERIES ON ONE AXIS
# ============================================================================
# THE THING ONLY THIS ROW PRODUCES is the melt. Several subject columns are
# reshaped into the long pair the draw layer has always taken, and the user is
# never asked about it: value_col becomes "eml_value" and group_col becomes
# "eml_series", two names no fixture in this harness contains. A leg that took
# any other path through the tree cannot report them.
for (cs in c("subjects4", "seven")) {
    check_true(V, paste0("[", cs, "] the columns are the same measurement"),
               identical(trv(cs, "series_role"), "subjects"))
    check_true(V, paste0("[", cs, "] several numeric columns, so a tickbox each"),
               identical(trn(cs, "shape"), 1) && isTRUE(trn(cs, "n_numeric") >= 2))
    check_true(V, paste0("[", cs, "] melted onto one axis (eml_value/eml_series)"),
               identical(trv(cs, "value_col"), "eml_value") &&
               identical(trv(cs, "group_col"), "eml_series"))
    check_true(V, paste0("[", cs, "] with no right-hand axis"),
               identical(trn(cs, "second_axis"), 0) &&
               identical(trv(cs, "right_col"), ""))
    check_true(V, paste0("[", cs, "] no repeated observations in the table"),
               identical(trn(cs, "repeats_found"), 0) &&
               identical(trn(cs, "max_per_point"), 1))
    check_true(V, paste0("[", cs, "] so no interval was drawn"),
               identical(trn(cs, "ci_accepted"), 0))
    # AND THE FIGURE SAYS SO. One hue per series, off the rendered pixels.
    check_true(V, paste0("[", cs, "] the page carries one colour per series (",
                         trv(cs, "fig_chromatic_colours"), ")"),
               identical(trn(cs, "fig_chromatic_colours"), trn(cs, "n_series")))
    # NOT ROW 2's PROCEDURE. @emlDrawTimeSeriesCI names itself in the Info
    # window on every draw, and says what its band is; a row that took its
    # branch would say both here. The header is matched with its colon,
    # because the ordinary disclosure POINTS at the CI figure by name -- "or
    # Time Series (with CI) to show the spread" -- and a match on the bare
    # phrase would call that advice a draw.
    check_true(V, paste0("[", cs, "] drawn by @emlDrawTimeSeries, not the CI one"),
               !has(info1(cs), "Time Series (with CI):") &&
               !has(info1(cs), "band shows the 95% CI"))
}
check_true(V, "[subjects4] four subject columns became four series",
           identical(trn("subjects4", "n_series"), 4) &&
           identical(trv("subjects4", "series_cols"), "S1,S2,S3,S4"))
check_true(V, "[subjects4] against the time column the table names",
           identical(trv("subjects4", "time_col"), "time"))

# ============================================================================
# 4B. THE SHARED AXIS HAS TO BE NAMED, AND ONLY THIS PAGE CAN ASK
# ============================================================================
# WHY THE FIELD EXISTS. Everywhere else in this plugin the y-axis label writes
# itself from the column being drawn -- @emlCapitalizeLabel over
# valueColName$, which is why every other leg in this harness comes back with
# "F0" and never had to be asked. A melted-subjects figure has no such column:
# S1..S4 name the SINGERS, and the quantity they share -- the thing the
# vertical axis measures -- is nowhere in the table. So the form leaves the
# label blank rather than borrowing a subject's name for it, and the label the
# figure needs has to come from the user.
#
# WHAT WAS WRONG WITH THAT. The only place to type it was the ADVANCED page,
# and beginner mode is the shipped default -- run_gui_leg writes
# "showAdvanced: 0" into the preference file on every leg, so these pages are
# the pages a new user meets. A beginner drawing four singers' F0 got an
# unlabelled vertical axis and no control anywhere in front of them that would
# label it. The field is now on the beginner page for exactly that case.
#
# EXACTLY ONE OF THE TWO EXISTS AT A TIME, which is not a tidiness point: both
# are spelled "Y axis label", so both derive the SAME variable, and two live
# fields sharing one derived name is a page whose second field silently wins.
ylab_n <- function(cs, step) sum(grepl("^Y axis label:", shown(cs, step)))
# THE THREE PAGES THAT CARRY IT. Role = subjects and two or more numeric
# columns: the melt is on, so the axis has no name of its own.
YLAB <- list(subjects4 = 3, seven = 3, none_refuse = 3)
for (cs in names(YLAB)) {
    check_true(V, paste0("[", cs, "] the beginner column page asks for the y-axis name"),
               ylab_n(cs, YLAB[[cs]]) == 1L)
    check_true(V, paste0("[", cs, "] and only asks once"),
               ylab_n(cs, YLAB[[cs]]) == 1L &&
               sum(grepl("axis label", shown(cs, YLAB[[cs]]))) == 1L)
}
# WHERE IT SITS ON THE PAGE, which is the fact harness/linetree/run.sh's plans
# depend on: after the last tickbox and before Line style. A field inserted
# ABOVE the tickboxes would move every tog<N> in every plan by one and the
# legs would tick the wrong columns while still walking the planned titles.
for (cs in names(YLAB)) {
    pg <- shown(cs, YLAB[[cs]])
    iy <- grep("^Y axis label:", pg)
    it <- grep("^Series [0-9]+ \\(", pg)
    il <- grep("^Line style:", pg)
    check_true(V, paste0("[", cs, "] below the last tickbox and above Line style"),
               length(iy) == 1L && length(il) == 1L && length(it) > 0 &&
               iy > max(it) && iy < il)
}
# THE PAGES THAT DO NOT. Two different reasons, both exercised: role =
# measurements (each column names its own quantity, so each axis names itself)
# and shape 2 (one numeric column, which HAS a name -- subjects_ci comes back
# with "F0" for exactly that reason).
check_true(V, "[meas2] different measurements name their own axes, so no field",
           ylab_n("meas2", 3) == 0L && ylab_n("meas2_rep", 3) == 0L)
check_true(V, "[meas3_refuse] nor on the page the refusal hands back",
           ylab_n("meas3_refuse", 3) == 0L && ylab_n("meas3_refuse", 5) == 0L)
check_true(V, "[subjects_ci] one numeric column has a name already, so no field",
           ylab_n(CI, 3) == 0L && ylab_n(CI, 5) == 0L)
# AND THE ADVANCED PAGE STILL HAS ITS OWN, EXACTLY ONE. subjects_ci's second
# dialog is that page: the field the beginner page borrows, in the place it
# has always been.
check_true(V, "[subjects_ci] the advanced page carries the field it always did",
           ylab_n(CI, 4) == 1L)
check_true(V, "[subjects_ci] beside the x-axis label, which is advanced-only",
           sum(grepl("X axis label:", shown(CI, 4))) == 1L &&
           !any(grepl("X axis label:", shown(CI, 3))))
# THE LABEL THE FIELD PRODUCES. Blank on the melted legs -- the plugin did not
# invent one from a subject's name -- and composed from the column everywhere
# else. This is the defect the field exists to let the user fix, still visible.
check_true(V, "[subjects4] the melted figure's axis label is left blank, not guessed",
           identical(trv("subjects4", "y_label"), "") &&
           identical(trv("seven", "y_label"), ""))
check_true(V, "while a figure with a named value column still composes its own",
           identical(trv(CI, "y_label"), "F0") &&
           identical(trv("meas2", "y_label"), "F0"))

# THE SOURCE: TWO DECLARATIONS ON THIS PAGE, MUTUALLY EXCLUSIVE.
pg_from <- grep('^\\s*beginPause: "Line Chart -- Column Mapping"\\s*$', form_src)
pg_to   <- grep('^\\s*clicked = endPause: "Go Back", "Quit", tsToggleLabel\\$, "Draw", 4, 1\\s*$',
                form_src)
page_b <- if (length(pg_from) == 1L && length(pg_to) == 1L) {
    form_src[pg_from:pg_to]
} else character(0)
yl <- grep('^\\s*sentence: "Y axis label", tmpYLabel\\$\\s*$', page_b)
check_true(V, "the column page declares the y-axis field exactly twice",
           length(yl) == 2L)
check_true(V, "the first guarded by melted subjects in BEGINNER mode",
           length(yl) == 2L &&
           isTRUE(grepl("^\\s*if tsSeriesRole = 1 and tsNNum >= 2 and config_showAdvanced = 0\\s*$",
                        page_b[yl[1] - 1])))
check_true(V, "the second inside the advanced block, so never both at once",
           length(yl) == 2L &&
           any(grepl("^\\s*if config_showAdvanced\\s*$", page_b[1:yl[2]])) &&
           yl[2] > max(grep("^\\s*if config_showAdvanced\\s*$", page_b[1:yl[2]])))
# AND IT IS READ BACK UNDER THE SAME GUARD IT IS BUILT UNDER. A field built on
# a condition and read on another is a field whose answer is discarded on some
# presses and a "Unknown variable" abort on others.
check_true(V, "and the beginner field is read back under the same condition",
           sum(grepl("^\\s*if tsSeriesRole = 1 and tsNNum >= 2 and config_showAdvanced = 0\\s*$",
                     form_src)) == 2L &&
           any(grepl("^\\s*tmpYLabel\\$ = y_axis_label\\$\\s*$", form_src)))
# THE DERIVED NAME DOES NOT TRUNCATE. "Right-hand axis" derived `right` and
# cost this tree a whole driven session; a label added later is checked before
# it is trusted. Praat truncates at the first character that cannot be in an
# identifier, so a label whose derived name is the WHOLE label is safe -- and
# "Y axis label" is letters and spaces only.
ylab_label <- "Y axis label"
derived <- tolower(gsub(" ", "_", ylab_label))
check_true(V, sprintf("the label \"%s\" derives the whole name \"%s\"",
                      ylab_label, derived),
           isTRUE(grepl("^[A-Za-z][A-Za-z0-9 ]*$", ylab_label)) &&
           isTRUE(grepl("^[A-Za-z][A-Za-z0-9_]*$", derived)))
check_true(V, "which is the name the form reads it back at",
           identical(derived, "y_axis_label") &&
           any(grepl("^\\s*tmpYLabel\\$ = y_axis_label\\$\\s*$", form_src)))

# ============================================================================
# 5. DISPATCH ROW 2 -- SUBJECTS, REPEATS ACCEPTED: MEAN AND INTERVAL
# ============================================================================
# THE THING ONLY THIS ROW PRODUCES is @emlDrawTimeSeriesCI's own report, and
# it is quoted rather than paraphrased: the procedure prints the number of
# groups, the observations per point, and what the band is. No other dispatch
# row prints any of it.
check_true(V, "[subjects_ci] one measurement column and a name column",
           identical(trn(CI, "shape"), 2) &&
           identical(trn(CI, "n_numeric"), 1) &&
           identical(trn(CI, "n_text"), 1))
check_true(V, "[subjects_ci] the series are named by the speaker column",
           identical(trv(CI, "group_col"), "speaker") &&
           identical(trv(CI, "value_col"), "f0"))
check_true(V, "[subjects_ci] repeats were found, four to a point",
           identical(trn(CI, "repeats_found"), 1) &&
           identical(trn(CI, "max_per_point"), 4))
check_true(V, "[subjects_ci] the interval was offered and accepted",
           identical(trn(CI, "ci_offered"), 1) &&
           identical(trn(CI, "ci_accepted"), 1))
check_true(V, "[subjects_ci] the CI procedure drew it and named itself",
           has(info1(CI), "Time Series (with CI): 2 group(s)"))
check_true(V, "[subjects_ci] the band is the 95% CI around the mean",
           has(info1(CI), "Line shows the mean; band shows the 95% CI"))
check_true(V, "[subjects_ci] and it reports the observations per point it used",
           has(info1(CI), paste0("Observations per time point: up to ",
                                 trv(CI, "max_per_point"))))
check_true(V, "[subjects_ci] both speakers are named in the key",
           has(figtext1(CI), "Speaker 1") && has(figtext1(CI), "Speaker 2"))
# THE BANDS ARE ON THE PAGE, AND THEY ARE WHAT SEPARATES THIS ROW FROM ROW 4.
# @emlDrawTimeSeriesCI fills each interval in a lightened variant of its line
# colour, so a CI figure carries chromatic AREAS -- tens of thousands of
# pixels of one colour -- where every other leg in this harness carries only
# strokes and markers. 50000 is a fifth of the way to the largest fill and
# more than double the largest stroke total anywhere else in the transcript.
big <- function(cs, floor = 50000) sum(colcounts(cs) > floor)
check_true(V, sprintf("[subjects_ci] two filled bands, not two strokes (%d colours over 50k px)",
                      big(CI)),
           big(CI) == 2L)
for (cs in setdiff(CASES, CI)) {
    check_true(V, paste0("[", cs, "] carries no filled band"), big(cs) == 0L)
}
check_true(V, "[subjects_ci] and no right-hand axis under role = subjects",
           identical(trn(CI, "second_axis"), 0))

# ============================================================================
# 6. DISPATCH ROW 3 -- TWO MEASUREMENTS, NO REPEATS: THE RIGHT-HAND PAIR
# ============================================================================
# THE THING ONLY THIS ROW PRODUCES is a second vertical scale, and the shape
# of the question that produces it is the point: the two columns are ALREADY
# chosen when the page opens, so the only thing left to ask is which of them
# the right-hand scale belongs to. Choosing one makes the other the left. A
# column drawn twice -- once melted into the left side and once on the right,
# which is D138 -- is not guarded against here, it is unsayable.
for (cs in c("meas2", "meas2_rep")) {
    check_true(V, paste0("[", cs, "] the columns are different measurements"),
               identical(trv(cs, "series_role"), "measurements"))
    check_true(V, paste0("[", cs, "] two of them, f0 and cq"),
               identical(trn(cs, "n_series"), 2) &&
               identical(trv(cs, "series_cols"), "f0,cq"))
    check_true(V, paste0("[", cs, "] a right-hand axis was requested"),
               identical(trn(cs, "second_axis"), 1))
    check_true(V, paste0("[", cs, "] the right-hand column is one of the two"),
               trv(cs, "right_col") %in%
               strsplit(trv(cs, "series_cols"), ",")[[1]])
    check_true(V, paste0("[", cs, "] and the left-hand column is the OTHER one"),
               !identical(trv(cs, "right_col"), trv(cs, "value_col")) &&
               trv(cs, "value_col") %in%
               strsplit(trv(cs, "series_cols"), ",")[[1]])
    check_true(V, paste0("[", cs, "] with no group column, so nothing is melted"),
               identical(trv(cs, "group_col"), ""))
    check_true(V, paste0("[", cs, "] two hues on the page, one per measurement"),
               identical(trn(cs, "fig_chromatic_colours"), 2))
    check_true(V, paste0("[", cs, "] and the right-hand series is tagged on the figure"),
               has(figtext1(cs), "(right axis)"))
}
check_true(V, "[meas2] the table has no repeated observations",
           identical(trn("meas2", "repeats_found"), 0))
check_true(V, "[meas2] so nothing about means is disclosed",
           !has(info1("meas2"), "Repeated observations") &&
           !has(info1("meas2"), "were averaged"))
# THE PAGE ITSELF, AS DISPLAYED. Everything a right-hand axis needs is on it:
# the column, the range on the 0/0 auto sentinel, the name, and that series'
# own pen defaulting to Dashed.
p3 <- shown1("meas2", 4)
check_true(V, "[meas2] the right-hand page asks which column takes the scale",
           has(p3, "Right hand axis"))
check_true(V, "[meas2] and offers the range on the 0 = auto sentinel",
           has(p3, "Right y-axis range (both 0 = auto)") &&
           has(p3, "Right minimum") && has(p3, "Right maximum"))
check_true(V, "[meas2] the axis name, blank = the column name",
           has(p3, "Right axis label (blank = the column name)"))
check_true(V, "[meas2] and that series' own pen, defaulting to Dashed",
           isTRUE(any(grepl("^Right line style: *Dashed", shown("meas2", 4)))))
# THE LABEL HAS NO HYPHEN, AND IT IS NOT A TYPO. Praat truncates a field's
# derived variable name at the first character that cannot be in an
# identifier, so "Right-hand axis" is readable only as `right`: measured on
# 6.6.30 by this harness, where every two-measurement draw aborted with
# "Unknown variable: right_hand_axis" the instant Draw was pressed. The window
# TITLE keeps its hyphen, because a title is not a field -- section 3 pins
# that, and this pins the field.
check_true(V, "[meas2] the page's title keeps its hyphen",
           identical(titles("meas2")[4], PAGE_C))
check_true(V, "[meas2] while the FIELD's label does not carry one",
           !isTRUE(any(grepl("Right-hand axis:", shown("meas2", 4)))))
check_true(V, "the form declares the field without a hyphen",
           any(grepl('optionmenu: "Right hand axis", tsRightPick',
                     form_src, fixed = TRUE)) &&
           !any(grepl('optionmenu: "Right-hand axis"', form_src, fixed = TRUE)))
check_true(V, "and reads it back at the name Praat derives from that label",
           any(grepl("^\\s*tsRightPick = right_hand_axis\\s*$", form_src)))

# ============================================================================
# 7. DISPATCH ROW 4 -- TWO MEASUREMENTS WITH REPEATS: MEANS, NO BANDS
# ============================================================================
# THE THING ONLY THIS ROW PRODUCES is the two-scale disclosure. The table has
# three observations at every time point, so the lines ARE means -- and an
# interval is not offered, because there is no shared scale to draw one on.
# Neither half is a decision the user made, so both are said out loud.
RP <- "meas2_rep"
check_true(V, "[meas2_rep] repeated observations are in the table, three a point",
           identical(trn(RP, "repeats_found"), 1) &&
           identical(trn(RP, "max_per_point"), 3))
check_true(V, "[meas2_rep] and the interval was NOT offered, because two scales",
           identical(trn(RP, "ci_offered"), 0) &&
           identical(trn(RP, "ci_accepted"), 0))
# THE SENTENCE IS ON THE FIGURE'S DISCLOSURE CHANNEL, NOT IN THE FORM'S VOICE.
# REPLACES the check that read "Line chart: Repeated observations were found
# (up to 3 per point); the mean of each point is drawn." off the Info window.
# That line was the DIALOG talking about a figure it had already handed to the
# draw layer, and the draw layer was saying the same thing two lines further
# down in its own words -- one fact, two voices, and only one of them can ever
# reach the picture. @emlDisclose is the channel that goes to both the Info
# window and the on-figure annotation block, so the fact is now stated once,
# where it can be drawn. The form's line is gone and its absence is checked
# below, because a fact stated twice is how it comes back.
d_rp <- grep("^Time series: ", info(RP), value = TRUE)
check_true(V, "[meas2_rep] the mean is disclosed by the draw layer, in its own name",
           length(d_rp) > 0)
check_true(V, "[meas2_rep] which says the lines -- plural, two scales -- are means",
           has(paste(d_rp, collapse = " "), "Lines show the mean per time point."))
check_true(V, "[meas2_rep] and says why there is no interval",
           has(info1(RP), "Intervals are not offered across two scales."))
# ONE SENTENCE, ONE LINE, ONE CHANNEL. Both halves are the same disclosure --
# the fact and its advice -- so they arrive together or the reader gets the
# mean without the reason for the missing band.
check_true(V, "[meas2_rep] both halves on one disclosure line, not two lines",
           any(vapply(d_rp, function(l)
               has(l, "Lines show the mean per time point.") &&
               has(l, "Intervals are not offered across two scales."),
               logical(1))))
# AND THE FORM NO LONGER SAYS IT. The dialog's own sentence is not in the Info
# window under any spelling: not its opening words, not the count it named.
check_true(V, "[meas2_rep] and the form does not say it a second time",
           !has(info1(RP), "Repeated observations were found") &&
           !has(info1(RP), "the mean of each point is drawn"))
check_true(V, "nor is that sentence still in the form's source",
           !any(grepl("Repeated observations were found", form_src, fixed = TRUE)) &&
           !any(grepl("the mean of each point is drawn", form_src, fixed = TRUE)))
# THE TWO-SCALE SENTENCE IS THE DRAW LAYER'S, AND ONLY THE DRAW LAYER'S.
check_true(V, "the two-scale sentence is written once, in the draw layer",
           sum(grepl("Intervals are not offered across two scales.",
                     draw_src, fixed = TRUE)) == 1L &&
           !any(grepl("Intervals are not offered across two scales.",
                      form_src, fixed = TRUE)))
# AND IT IS THE SECOND-AXIS ARM OF THE COLLAPSE DISCLOSURE, not a line that
# fires wherever repeats were found: the arm is chosen on .secondOn.
check_true(V, "and it is the .secondOn arm of the collapse disclosure",
           {
               i <- grep("Intervals are not offered across two scales.",
                         draw_src, fixed = TRUE)
               length(i) == 1L &&
               any(grepl("^\\s*if \\.secondOn = 1\\s*$",
                         draw_src[max(1, i - 6):i]))
           })
check_true(V, "[meas2_rep] the draw layer counts what it averaged",
           has(info1(RP), "16 repeated observation(s) were averaged."))
check_true(V, "[meas2_rep] no band was drawn, so no filled area is on the page",
           big(RP) == 0L)
check_true(V, "[meas2_rep] and the CI procedure never ran",
           !has(info1(RP), "Time Series (with CI):") &&
           !has(info1(RP), "band shows the 95% CI"))
# AND IT DOES NOT POINT AT A FIGURE THAT CANNOT HELP EITHER. REPLACES the
# check that required this leg's Info window to name "Time Series (with CI) to
# show the spread around each mean". That advice is the SINGLE-SCALE arm's,
# and it was wrong here from the day it was written: Time Series (with CI)
# draws no right-hand axis, so a reader who followed it would lose the second
# measurement to get the band. The two-scale arm replaces the advice rather
# than adding to it, and this checks the replacement is a replacement.
check_true(V, "[meas2_rep] and does not send the reader to a figure with one scale",
           !has(info1(RP), "Time Series (with CI) to show the spread around each mean") &&
           !has(info1(RP), "Use Spaghetti Plot to show individual series"))
# THE SINGLE-SCALE ADVICE IS NOT DELETED, ONLY UNSAID HERE. A leg that
# collapses repeats on ONE scale still gets it -- subjects_ci's fixture is the
# one that has repeats and one scale, and it takes the CI procedure instead,
# so this is asked of the source rather than of a transcript that cannot
# carry it.
check_true(V, "while the one-scale arm still names Spaghetti Plot and the CI figure",
           any(grepl("Use Spaghetti Plot to show individual series", draw_src,
                     fixed = TRUE)) &&
           any(grepl("(with CI) to show the spread around each mean.", draw_src,
                     fixed = TRUE)))
# ROWS 3 AND 4 ARE THE SAME REQUEST ON DIFFERENT TABLES. They must differ in
# the disclosure and in nothing about the axis: a repeat scan that quietly
# withdrew the second axis would be a different defect with the same symptom.
check_true(V, "rows 3 and 4 make the same right-hand request",
           identical(trv("meas2", "right_col"), trv(RP, "right_col")) &&
           identical(trn("meas2", "second_axis"), trn(RP, "second_axis")))
check_true(V, "and differ in what they disclose",
           !identical(info1("meas2"), info1(RP)))

# ============================================================================
# 8. THE TWO REFUSALS, IN THE WORDS THE USER IS SHOWN
# ============================================================================
# A REFUSAL IS A SENTENCE, NOT A RETURN CODE, and this section reads the one
# on the screen. Both come back as a pause titled "Line chart" with a single
# OK button, and both are asked for by their WORDS: a refusal that lost its
# count, or its pointer to the machinery that does exist for the job, would
# still refuse and would no longer be worth anything.
#
# THE LAST LINE IS PART OF THE TEST. One long comment: is WRAPPED on screen
# but sized as ONE row, so the button strip is laid out over the overflow and
# the tail of the message is drawn UNDER the OK button. Measured here on 18
# August 2026: the three-measurement refusal displayed two lines and hid the
# third -- the half naming "press Draw again" and the way out. It is wrapped
# by @emlWrapText at 62 now, one comment: per line, and the check below reads
# the last line off the photograph.
r3 <- shown("meas3_refuse", 4); r3s <- paste(r3, collapse = " ")
check_true(V, "[meas3_refuse] the refusal is a pause titled Line chart",
           identical(titles("meas3_refuse")[4], REFUSE))
check_true(V, "[meas3_refuse] with one button, OK",
           identical(tail(r3, 1), "OK"))
check_true(V, "[meas3_refuse] it names how many measurements it found",
           has(r3s, paste0("There are ", trv("meas3_refuse", "n_numeric"),
                           " different measurements here")))
check_true(V, "[meas3_refuse] and that a figure has two vertical axes",
           has(r3s, "a figure has two vertical axes"))
check_true(V, "[meas3_refuse] it points at stacked panels",
           has(r3s, "Draw the extra ones as stacked panels"))
check_true(V, "[meas3_refuse] naming the control that composes a page",
           has(r3s, "\"Erase page first\"") && has(r3s, "set a panel origin"))
check_true(V, "[meas3_refuse] and the press that adds the next panel",
           has(r3s, "press Draw again"))
check_true(V, "[meas3_refuse] the OTHER way out is on screen too -- the last line",
           has(r3s, "or untick columns until two are left."))
check_true(V, "[meas3_refuse] and that last line is above the OK button, not under it",
           identical(r3[length(r3) - 1], "or untick columns until two are left."))
check_true(V, "[meas3_refuse] the refusal drew nothing on the page",
           identical(trn("meas3_refuse", "s4_ink"),
                     trn("meas3_refuse", "ink_empty")))
check_true(V, "[meas3_refuse] and handed the column page back with all three ticked",
           sum(grepl("^Series [0-9]+ \\(", shown("meas3_refuse", 5))) == 3L)
check_true(V, "[meas3_refuse] where unticking one left two, which drew",
           identical(trn("meas3_refuse", "n_series"), 2) &&
           identical(trv("meas3_refuse", "series_cols"), "f0,cq"))
check_true(V, "[meas3_refuse] on the right-hand pair it then reached",
           identical(trn("meas3_refuse", "second_axis"), 1) &&
           has(figtext1("meas3_refuse"), "(right axis)"))

r0 <- shown("none_refuse", 4); r0s <- paste(r0, collapse = " ")
check_true(V, "[none_refuse] the refusal is a pause titled Line chart",
           identical(titles("none_refuse")[4], REFUSE))
check_true(V, "[none_refuse] with one button, OK",
           identical(tail(r0, 1), "OK"))
check_true(V, "[none_refuse] it says nothing is selected and nothing can be drawn",
           has(r0s, "No measurement columns are selected, so there is nothing to draw."))
check_true(V, "[none_refuse] and says what to do about it",
           has(r0s, "Tick at least one column that is not the time axis."))
check_true(V, "[none_refuse] the refusal drew nothing on the page",
           identical(trn("none_refuse", "s4_ink"), trn("none_refuse", "ink_empty")))
check_true(V, "[none_refuse] the column page came back, still offering both columns",
           sum(grepl("^Series [0-9]+ \\(", shown("none_refuse", 5))) == 2L)
check_true(V, "[none_refuse] and one tick drew one series",
           identical(trn("none_refuse", "n_series"), 1) &&
           identical(trn("none_refuse", "fig_chromatic_colours"), 1))
check_true(V, "the two refusals are two different sentences",
           !identical(r3s, r0s))
# NEITHER REFUSAL LOST THE FIGURE. Both legs draw after being handed back,
# which is the whole reason the refusal is a pause inside the loop rather than
# an exit.
for (cs in c("meas3_refuse", "none_refuse")) {
    check_true(V, paste0("[", cs, "] the leg still finished with a figure"),
               isTRUE(trn(cs, "fig_png_bytes") > 20000) &&
               identical(tail(titles(cs), 1), "Graph Complete"))
}

# ============================================================================
# 9. THE REPLICATION FORK, BOTH WAYS
# ============================================================================
# WHETHER A LINE HAS MORE THAN ONE OBSERVATION AT A TIME POINT IS A FACT ABOUT
# THE TABLE, so it is not asked. @emlLineTreeRepeats looks, and the offer
# either appears NAMING THE COUNT IT FOUND or does not appear at all. It is
# never present and inert, which is the failure mode a tickbox has: a user can
# ask for a mean where there is nothing to average, and -- worse the other way
# -- can fail to notice an interval is available.
#
# THE COUNT IN THE LABEL IS THE COUNT UNDER THE GROUPING IN FORCE, and that
# is the whole of what this arm asserts. The fixture has 2 speakers x 4
# observations at each of 6 time points: keyed on time ALONE it has 8 rows a
# point, keyed on (time, speaker) it has 4. Only one of those two numbers is
# the number of observations the interval would be computed from, and which
# one it is depends on the series-name menu -- so the label is read off all
# three photographs of the page, not one.
#
# REPLACES the pair that required the FIRST page to say 8 and the third to say
# 4. That was the old menu's behaviour and it was a defect being pinned rather
# than a rule: the menu was built over every column and seeded from
# @emlGuessColumnRoles, which on time/f0/speaker guessed TIME, so the page
# opened proposing to name the series after the horizontal axis and counted
# the repeats ungrouped. The menu now holds the TEXT columns and opens on the
# first of them, so the scan is keyed on (time, speaker) from the first
# presentation. 8 is not a number this page should ever show, and the check
# below says so of the whole walk rather than of one step.
ci_pages <- c(shown1(CI, 3), shown1(CI, 4), shown1(CI, 5))
ci_label <- paste0("Draw the mean and its interval (up to ",
                   trv(CI, "max_per_point"), " observations per point)")
check_true(V, "[subjects_ci] the interval is offered on the page as it opens",
           has(ci_pages[1], "Draw the mean and its interval"))
check_true(V, sprintf("[subjects_ci] naming the GROUPED count from the first page (%s)",
                      trv(CI, "max_per_point")),
           has(ci_pages[1], ci_label))
check_true(V, "[subjects_ci] and the same count on all three presentations",
           all(vapply(ci_pages, function(pg) has(pg, ci_label), logical(1))))
check_true(V, "[subjects_ci] which is the count the scan reported",
           identical(trn(CI, "max_per_point"), 4))
check_true(V, "[subjects_ci] the count on the label is a real repeat count, not 1",
           isTRUE(trn(CI, "max_per_point") > 1))
# THE UNGROUPED COUNT IS NEVER SHOWN. 8 is what this table has when the key is
# the time column alone, which is what the page would count if the series
# namer were the time column -- so this is the same statement as the menu
# check below, made from the label instead of from the menu.
check_true(V, "[subjects_ci] and the ungrouped count is on no page of the walk",
           !any(vapply(ci_pages, function(pg)
               has(pg, "up to 8 observations per point"), logical(1))))
# THE GROUPING THE LABEL COUNTED IS THE GROUPING THAT DREW. A page that named
# the grouped count and then drew ungrouped would satisfy every check above:
# the label is a promise about the figure, and the figure's own group column
# is what keeps it.
check_true(V, "[subjects_ci] and the column it counted by is the one that grouped the figure",
           identical(trv(CI, "group_col"), "speaker") &&
           isTRUE(grepl("Series names come from:.*speaker", ci_pages[1])))

# ============================================================================
# 9B. THE SERIES-NAME MENU HOLDS THE TEXT COLUMNS, AND NOTHING ELSE
# ============================================================================
# A COLUMN THAT NAMES THE SERIES IS A COLUMN OF NAMES. Offering the whole
# table was not merely untidy -- it put the time column and the measurement
# column in a list of candidate series names, and it seeded the menu from
# @emlGuessColumnRoles, whose answer on this fixture was the TIME column. The
# page opened proposing to name each series after the horizontal axis; the
# repeat scan keyed itself on that proposal and the interval offer counted 8
# where the grouping the user wanted has 4. Nothing refused it, because
# nothing about it is refusable: it is a legal answer to the wrong menu.
#
# WHAT IS MEASURED HERE. The menu is a button showing its selection, not an
# open list, so a photograph cannot enumerate the options. Two statements are
# made instead, and between them they close the defect: the page OPENS on a
# text column (measured, off the pixels), and the option list is built from
# the survey's text columns (read in the source, where the list lives).
menu_line <- grep("Series names come from", shown(CI, 3), value = TRUE)
check_true(V, "[subjects_ci] the page carries the series-name menu",
           length(menu_line) == 1L)
# WHAT THE BUTTON IS DISPLAYING, taken off the photograph: everything after
# the colon, less the drop-down arrow tesseract renders as a stray "v", "V",
# "7" or "Vv", and less the underscore it reads out of the button's bevel.
menu_val <- if (length(menu_line) == 1L) {
    x <- sub("^.*come from:", "", ltnorm(menu_line[1]))
    x <- sub("[[:space:]]*(v|V|Vv|vV|7|¥)[[:space:]]*$", "", x)
    trimws(gsub("[_|]", " ", x))
} else NA_character_
check_true(V, sprintf("[subjects_ci] and it opens on the table's TEXT column (%s)",
                      if (is.na(menu_val)) "<none>" else menu_val),
           identical(menu_val, "speaker"))
# WHICH IS ONE OF THE COLUMNS THE FORM ITSELF COUNTED AS TEXT. n_text is 1 on
# this table, and the value on the button is that one column -- so the menu's
# default is inside the text list rather than merely outside the time column.
check_true(V, "[subjects_ci] and the form counted exactly that many text columns",
           identical(trn(CI, "n_text"), 1) && identical(trn(CI, "n_numeric"), 1))
# THE NUMERIC PAIR IS NOT WHAT IT OPENED ON. "time" is the defect's own
# answer -- the guesser's -- and "f0" is the measurement the page has already
# named in its own comment; neither can name a series.
check_true(V, "[subjects_ci] not the time column the guesser used to seed it",
           !identical(menu_val, "time"))
check_true(V, "[subjects_ci] and not the measurement column either",
           !isTRUE(grepl("^f[0oO]$", menu_val)))
# THE SOURCE OF THE LIST. The options after "(none)" are the survey's TEXT
# columns, iterated over tsNTxt -- not nCols, and not colName$[].
mi <- grep('^\\s*optionmenu: "Series names come from", tsTxtPick\\s*$', form_src)
check_true(V, "the series-name menu is declared exactly once, over tsTxtPick",
           length(mi) == 1L)
menu_block <- if (length(mi) == 1L) form_src[mi:(mi + 3)] else character(0)
check_true(V, "its first option is the one that asks for no grouping at all",
           isTRUE(grepl('option: "\\(none', menu_block[2])))
check_true(V, "and the rest are the text columns the survey found",
           isTRUE(grepl("^\\s*for iT from 1 to tsNTxt\\s*$", menu_block[3])) &&
           isTRUE(grepl("^\\s*option: tsTxtName\\$\\[iT\\]\\s*$", menu_block[4])))
check_true(V, "so no column of the table reaches the menu except through the survey",
           !any(grepl("^\\s*option: colName\\$\\[iT\\]\\s*$", menu_block)) &&
           !any(grepl("^\\s*for iT from 1 to nCols\\s*$", menu_block)))
# AND tsTxtName$[] IS FILLED FROM THE SURVEY'S TEXT COLUMNS, which is where a
# menu "over the text columns" can still be a menu over everything.
check_true(V, "and tsTxtName$[] is filled from @emlLineTreeColumns' text list",
           any(grepl("^\\s*tsTxtName\\$\\[iT\\] = emlLineTreeColumns\\.textName'iT'\\$\\s*$",
                     form_src)) &&
           any(grepl("^\\s*tsNTxt = emlLineTreeColumns\\.nText\\s*$", form_src)))
# THE DEFAULT IS THE FIRST TEXT COLUMN, NOT A GUESS. @emlGuessColumnRoles is
# the guesser this menu used to be seeded from; the line chart's shape-2 page
# does not call it, and the option index it opens on is arithmetic on the text
# list -- 1 is "(none)", so the first text column is 2.
pb_from <- grep('^\\s*beginPause: "Line Chart -- Column Mapping"\\s*$', form_src)
pb_to   <- grep('^\\s*clicked = endPause: "Go Back", "Quit", tsToggleLabel\\$, "Draw", 4, 1\\s*$',
                form_src)
check_true(V, "the column page's beginPause and endPause are each written once",
           length(pb_from) == 1L && length(pb_to) == 1L && pb_to > pb_from)
check_true(V, "the page defaults the namer to the first text column",
           any(grepl("^\\s*tsTxtPick = 2\\s*$", form_src)))
check_true(V, "remembering the user's choice by NAME across visits",
           any(grepl("^\\s*if tsTxtName\\$\\[iT\\] = prev_tsGroupName\\$\\s*$",
                     form_src)) &&
           any(grepl("^\\s*prev_tsGroupName\\$ = tsTxtName\\$\\[tsTxtPick - 1\\]\\s*$",
                     form_src)))
# AND THE DEAD INDEX IS GONE. tsGroupIdx was the by-position memory the name
# memory replaces; left in the file it is a second answer to the same question.
check_true(V, "the by-position memory tsGroupIdx is not in the form any more",
           !any(grepl("tsGroupIdx", form_src, fixed = TRUE)))
# THE REPEAT SCAN IS KEYED ON THE COLUMN THE PAGE IS ABOUT TO OPEN WITH. This
# is the line that ties the menu to the count in the label: the scan takes
# tsTxtName$[tsTxtPick - 1], the same arithmetic the menu's default uses.
check_true(V, "the repeat scan is keyed on the column the page opens with",
           any(grepl("^\\s*tsScanGroup\\$ = tsTxtName\\$\\[tsTxtPick - 1\\]\\s*$",
                     form_src)) &&
           any(grepl("^\\s*@emlLineTreeRepeats: objectId, tsTimeName\\$, tsScanGroup\\$\\s*$",
                     form_src)))

# THE ABSENT ARM. No column page on any other leg carries the field at all --
# not the label, not the phrase, nothing to tick.
for (cs in setdiff(GUI, CI)) {
    pages <- paste(unlist(lapply(seq_len(max(1, length(titles(cs)))),
                                 function(i) shown1(cs, i))), collapse = " ")
    check_true(V, paste0("[", cs, "] no interval field appears anywhere in the walk"),
               !has(pages, "Draw the mean and its interval") &&
               !has(pages, "observations per point"))
    check_true(V, paste0("[", cs, "] and the form agrees it never offered one"),
               identical(trn(cs, "ci_offered"), 0))
}
# THE TWO REASONS TO WITHHOLD IT ARE DIFFERENT, and both are exercised.
# subjects4 has no repeats to draw from; meas2_rep HAS repeats and is refused
# the offer anyway, because its two series are on two scales. A gate that only
# tested for repeats would be green on the first and red on the second.
check_true(V, "[subjects4] withheld because the table has no repeats",
           identical(trn("subjects4", "repeats_found"), 0) &&
           identical(trn("subjects4", "ci_offered"), 0))
check_true(V, "[meas2_rep] withheld although the table HAS repeats",
           identical(trn(RP, "repeats_found"), 1) &&
           identical(trn(RP, "ci_offered"), 0))
# AND NOTHING WAS DRAWN THAT WAS NOT OFFERED.
for (cs in GUI) {
    check_true(V, paste0("[", cs, "] no interval was drawn without being offered"),
               !(identical(trn(cs, "ci_accepted"), 1) &&
                 !identical(trn(cs, "ci_offered"), 1)))
}

# ============================================================================
# 10. NO CEILING
# ============================================================================
# The page this replaces was five hardcoded "Series N" menus, so a seventh
# column was not merely inconvenient -- it could not be named. Seven is the
# fixture because the palette has eight slots: seven series still get seven
# hues, which is what makes "the seventh is on the page" answerable in ink.
sv <- shown("seven", 3)
ticks <- grep("^Series [0-9]+ \\(", sv, value = TRUE)
check_true(V, sprintf("[seven] the column page built seven tickboxes (%d)",
                      length(ticks)),
           length(ticks) == 7L)
check_true(V, "[seven] numbered 1 to 7, in table order",
           identical(as.integer(sub("^Series ([0-9]+) .*$", "\\1", ticks)), 1:7))
check_true(V, "[seven] and the seventh names the seventh column",
           isTRUE(grepl("^Series 7 \\(c7\\)$", ticks[7])))
check_true(V, "[seven] the form read all seven back",
           identical(trn("seven", "n_series"), 7) &&
           identical(trv("seven", "series_cols"), "c1,c2,c3,c4,c5,c6,c7"))
check_true(V, "[seven] seven hues reached the page",
           identical(trn("seven", "fig_chromatic_colours"), 7))
# EVERY ONE OF THEM IS A WHOLE SERIES, not six lines and a stub: the fixture's
# seven bands are the same length, so their pixel counts must agree to within
# a tenth. A form that drew the seventh as a single point would still report
# seven colours.
cc <- colcounts("seven")
check_true(V, sprintf("[seven] and all seven are fully stroked (min/max %.3f)",
                      min(cc) / max(cc)),
           length(cc) == 7L && min(cc) / max(cc) > 0.9)
# THE SEVENTH IS THE TOP BAND. Ten horizontal slices of the page, every one
# of them carrying chromatic ink: a dropped last column empties the top of
# the plot, and the axis maximum moves with it.
check_true(V, "[seven] chromatic ink is in all ten horizontal bands of the page",
           identical(trn("seven", "fig_chromatic_bands_nonempty"), 10))
# THE TICKBOX COUNT FOLLOWS THE TABLE EVERYWHERE, not just on the big one.
TICKS <- list(subjects4 = list(step = 3, n = 4), meas2 = list(step = 3, n = 2),
              meas2_rep = list(step = 3, n = 2),
              meas3_refuse = list(step = 3, n = 3),
              none_refuse = list(step = 3, n = 2), seven = list(step = 3, n = 7))
for (cs in names(TICKS)) {
    check_true(V, paste0("[", cs, "] one tickbox per numeric column (",
                         TICKS[[cs]]$n, ")"),
               sum(grepl("^Series [0-9]+ \\(", shown(cs, TICKS[[cs]]$step))) ==
               TICKS[[cs]]$n &&
               identical(trn(cs, "n_numeric"), as.numeric(TICKS[[cs]]$n)))
}
# AND THE ONE-NUMERIC-COLUMN TABLE GETS NO TICKBOXES AT ALL. Shape 2 names its
# measurement column in a comment and asks who the series are instead.
check_true(V, "[subjects_ci] one numeric column, so no tickboxes and a name menu",
           sum(grepl("^Series [0-9]+ \\(", shown(CI, 3))) == 0L &&
           has(shown1(CI, 3), "Series names come from") &&
           has(shown1(CI, 3), "Measurement column"))

# ============================================================================
# 11. THE KEY
# ============================================================================
# THE RULE (D139): a key appears whenever TWO OR MORE series are on the page,
# however they got there. It used to be a GROUPED-figure key, which meant the
# figure that needs one most did not get one -- an ungrouped series with a
# second measurement on the right-hand axis is two unlabelled lines on two
# scales, which is exactly the ambiguity the "(right axis)" tag exists to
# prevent.
#
# meas2 is that figure: n_series 2, group_col "", second_axis 1. Its key must
# carry two entries and the right-hand one must be tagged.
m2 <- figtext("meas2")
tagged <- grep("right axis", m2, value = TRUE)
check_true(V, "[meas2] the figure carries exactly one right-axis key entry",
           length(tagged) == 1L)
check_true(V, "[meas2] and it names the right-hand column",
           isTRUE(grepl("Cq \\(right axis\\)", tagged[1], ignore.case = TRUE)))
# THE LEFT ENTRY, read off the same photograph. tesseract renders the label
# "f0" as "fo" at this size, so the match is spelled to accept either glyph
# and the raw line is quoted in the check's own text; what is being asked is
# that a SECOND key entry exists beside the tagged one, on a figure with no
# group column.
left <- grep("^[^A-Za-z0-9]*f[0oO][[:space:]]*$", m2, value = TRUE)
check_true(V, sprintf("[meas2] beside a second entry naming the left column (%s)",
                      if (length(left)) left[1] else "<none>"),
           length(left) == 1L)
check_true(V, "[meas2] on a figure with no group column at all",
           identical(trv("meas2", "group_col"), ""))
# THE CONTROL. One series and no second axis: no key, and nothing tagged.
check_true(V, "[none_refuse] one series draws no key",
           length(grep("^[@©®*] ", figtext("none_refuse"))) == 0L)
check_true(V, "[none_refuse] and nothing is tagged as a right-hand axis",
           !has(figtext1("none_refuse"), "right axis"))
# THE SAME PAIR SEEN FROM OUTSIDE THE FORM. script_refuse draws the identical
# request twice, once refused and once honoured; the honoured arm gets the tag
# and the second hue, the refused arm gets neither.
check_true(V, "[script_refuse] the honoured arm's key tags the right-hand series",
           has(paste(ltnorm(trall("script_refuse", "honoured_figtext")),
                     collapse = " "), "(right axis)"))
check_true(V, "[script_refuse] and the refused arm tags nothing",
           !has(figtext1("script_refuse"), "right axis"))
# A GROUPED KEY STILL NAMES ITS GROUPS -- the old behaviour was not traded
# away for the new one.
check_true(V, "[subjects_ci] a grouped figure still carries its group key",
           length(grep("Speaker", figtext(CI))) == 2L)
# THE SOURCE OF THE RULE. The block is not inside the grouped test any more,
# and the tag is one string in one place.
key_at <- grep("^\\s*\\.drawKey = 0\\s*$", draw_src)
check_true(V, "the draw layer decides the key with its own flag", length(key_at) == 1L)
check_true(V, "which a group column turns on",
           any(grepl("^\\s*\\.drawKey = 1\\s*$", draw_src)))
check_true(V, "and a right-hand series turns on as well",
           {
               i <- grep("^\\s*if \\.secondOn = 1\\s*$", draw_src)
               any(vapply(i, function(j)
                   isTRUE(grepl("^\\s*\\.drawKey = 1\\s*$", draw_src[j + 1])),
                   logical(1)))
           })
check_true(V, "the right-hand entry's tag is the author's wording, in one place",
           sum(grepl('" (right axis)"', draw_src, fixed = TRUE)) == 1L)

# ============================================================================
# 12. WHAT THE SERIES MEAN TRAVELS WITH THE FIGURE
# ============================================================================
# The question tree asks the meaning once per press and the drawing layer
# needs it for one decision -- whether a right-hand axis may be honoured -- so
# it travels the way everything else the dialogs decide travels: published in
# full on every press, cleared afterwards, and written into a recorded script.
#
# THE REFUSAL EXISTS FOR THE CALLERS WITH NO DIALOG. No sequence of clicks
# reaches a subjects figure with a second scale, because the right-hand page
# is only reachable from "different measurements" -- section 3 measures that.
# A recorded script edited by hand, the API export or a user's own script CAN
# ask for it, and script_refuse is one of those callers.
SR <- "script_refuse"
check_true(V, "[script_refuse] a subjects figure is refused its right-hand axis",
           identical(trn(SR, "subjects_refused"), 1))
ref <- trv(SR, "subjects_refusal_text")
check_true(V, "[script_refuse] and told that it was refused, out loud",
           has(ref, "a second right-hand y-axis was requested and refused"))
check_true(V, "[script_refuse] with the reason, in the plugin's own words",
           has(ref, "These series are the same measurement on different subjects, so a second scale would say they are not comparable when they are."))
check_true(V, "[script_refuse] and what was drawn instead",
           has(ref, "The figure was drawn with one y-axis."))
check_true(V, "[script_refuse] the refusal is on the Info window, not swallowed",
           has(info1(SR), "requested and refused"))
check_true(V, "[script_refuse] the refused figure still drew, in one colour",
           identical(trn(SR, "fig_chromatic_colours"), 1) &&
           isTRUE(trn(SR, "fig_png_bytes") > 20000))
# THE CONTROL, IN THE SAME PROCESS. Same table, same two columns, same
# request; only the role changes. A gate that refused unconditionally would
# look identical on the first arm and different here.
check_true(V, "[script_refuse] the same request under measurements is honoured",
           identical(trn(SR, "measurements_refused"), 0))
check_true(V, "[script_refuse] and that figure carries the second series",
           identical(trn(SR, "honoured_chromatic_colours"), 2))
check_true(V, "[script_refuse] so the two arms are two different pages",
           !identical(trv(SR, "fig_png_md5"), trv(SR, "honoured_png_md5")) &&
           !is.na(trv(SR, "honoured_png_md5")))
check_true(V, "[script_refuse] both on the same 300-dpi rectangle",
           identical(trv(SR, "honoured_png_px"), trv(SR, "fig_png_px")))

# THE PUBLISH, THE GATE AND THE RESET, in source: three statements about
# where the role is spelled, which no transcript can make.
check_true(V, "the form publishes the role with the pens",
           any(grepl('^\\s*emlSeriesRole\\$ = "measurements"\\s*$', form_src)) &&
           any(grepl('^\\s*emlSeriesRole\\$ = "subjects"\\s*$', form_src)))
pub_from <- grep("^procedure emlGraphsPublishSeriesPens\\s*$", form_src)
pub_end  <- grep("^endproc\\s*$", form_src)
pub <- if (length(pub_from) == 1L) {
    form_src[pub_from:min(pub_end[pub_end > pub_from])]
} else character(0)
check_true(V, "the publish procedure exists exactly once", length(pub_from) == 1L)
check_true(V, "its first statement clears the role",
           identical(trimws(pub[grep("emlSeriesRole\\$", pub)[1]]),
                     'emlSeriesRole$ = ""'))
check_true(V, "and only the line chart sets it",
           any(grepl("^\\s*if graph_type = 5\\s*$", pub)))
res_from <- grep("^procedure emlGraphsResetSeriesPens\\s*$", form_src)
res <- if (length(res_from) == 1L) {
    form_src[res_from:min(pub_end[pub_end > res_from])]
} else character(0)
check_true(V, "the reset takes the role back after the press",
           any(grepl('^\\s*emlSeriesRole\\$ = ""\\s*$', res)))
check_true(V, "@emlSecondAxisGate refuses a right-hand axis under subjects",
           any(grepl('^\\s*if emlSeriesRole\\$ = "subjects"\\s*$', graph_src)))
check_true(V, "through variableExists, so a caller that states no role is not aborted",
           any(grepl('variableExists \\("emlSeriesRole\\$"\\)', graph_src)))
check_true(V, "and the draw layer never writes the role back",
           !any(grepl("^\\s*emlSeriesRole\\$\\s*=", draw_src)))

# THE RECORDER. The role is not an argument of any draw procedure -- it is a
# global the form publishes and the gate reads -- so a recorded call that
# carried every argument faithfully would still replay a figure whose second
# axis was decided by whatever was left in the session.
check_true(V, "the recorder emits emlSeriesRole$ in front of the draw call",
           any(grepl('\\.out\\$ = \\.out\\$ \\+ "emlSeriesRole\\$ = """ \\+ emlSeriesRole\\$',
                     rec_src)))
check_true(V, "through variableExists, for a caller that never published one",
           any(grepl('variableExists \\("emlSeriesRole\\$"\\)', rec_src)))
check_true(V, "and only when it says something",
           any(grepl('^\\s*if emlSeriesRole\\$ <> ""\\s*$', rec_src)))
check_true(V, "the block lifts it to seriesRole$",
           any(grepl('\\.lhs\\$ = "emlSeriesRole\\$"', rec_src)) &&
           any(grepl('^\\s*\\.base\\$ = "seriesRole"\\s*$', rec_src)))
check_true(V, "as a QUOTED literal, because the value is a word and not a number",
           {
               i <- grep('^\\s*\\.base\\$ = "seriesRole"\\s*$', rec_src)
               length(i) == 1L && isTRUE(grepl("^\\s*\\.quoted = 1\\s*$",
                                               rec_src[i + 1]))
           })

# ============================================================================
# 13. THE STORAGE QUESTION IS GONE
# ============================================================================
# NOT "IS NO LONGER ASKED FIRST" -- gone. The old page's five slots and its
# format menu are the ceiling and the wrong question respectively, and either
# one left standing in the file is a control a later edit can wire back up.
GONE <- list(
    list(w = 'the "Data format" menu',        p = 'optionmenu: "Data format"'),
    list(w = 'its Wide option',               p = 'option: "Wide (multiple columns)"'),
    list(w = 'its Long option',               p = 'option: "Long (value + group)"'),
    list(w = 'the variable behind it',        p = "tsDataFormat"),
    list(w = 'the field Praat derived from it', p = "data_format"))
for (g in GONE) {
    check_true(V, paste0(g$w, " is not in the form"),
               !any(grepl(g$p, form_src, fixed = TRUE)))
}
for (k in 1:5) {
    check_true(V, paste0('the hardcoded "Series ', k, '" menu is not in the form'),
               !any(grepl(paste0('optionmenu: "Series ', k, '"'), form_src,
                          fixed = TRUE)))
    check_true(V, paste0("nor the variable tsSeries", k, "Idx it filled"),
               !any(grepl(paste0("tsSeries", k, "Idx"), form_src, fixed = TRUE)))
}
# AND NOT ANYWHERE ELSE IN THE PLUGIN EITHER. The form is where they lived,
# but a slot read from another file is the same ceiling.
plugin_files <- list.files(PLUG, pattern = "\\.praat$", recursive = TRUE,
                           full.names = TRUE)
check_true(V, "the plugin's sources were found to scan",
           length(plugin_files) > 10L)
grep_plugin <- function(pat) {
    any(vapply(plugin_files, function(f)
        any(grepl(pat, readLines(f, warn = FALSE), fixed = TRUE)), logical(1)))
}
check_true(V, "no file in the plugin mentions tsDataFormat",
           !grep_plugin("tsDataFormat"))
check_true(V, "no file in the plugin mentions a numbered series slot",
           !any(vapply(1:5, function(k) grep_plugin(paste0("tsSeries", k, "Idx")),
                       logical(1))))
# THE ONE "Series" MENU LEFT IS THE NAME MENU, and it is a different question.
check_true(V, "the only Series menu left asks where the NAMES come from",
           identical(grep('optionmenu: "Series', form_src, value = TRUE),
                     grep('optionmenu: "Series names come from"', form_src,
                          value = TRUE)))
# AND NO LEG SAW THE OLD QUESTION ON SCREEN, which is the same statement made
# where the user stands.
for (cs in GUI) {
    pages <- paste(unlist(lapply(seq_along(titles(cs)),
                                 function(i) shown1(cs, i))), collapse = " ")
    check_true(V, paste0("[", cs, "] no page asked how the data is stored"),
               !has(pages, "Data format") && !has(pages, "Wide (") &&
               !has(pages, "Long ("))
}

# ============================================================================
# 14. THE PAGES ARE BUILT FROM THE TABLE
# ============================================================================
# The three shapes and the repeat scan are worked out rather than asked, and
# each is one procedure with one caller in the form. These are statements
# about where the code lives; sections 4 to 10 are the statements about what
# it does.
for (p in c("emlLineTreeColumns", "emlLineTreeRepeats")) {
    check_true(V, paste0("@", p, " exists exactly once, in the graph procedures"),
               sum(grepl(paste0("^procedure ", p, ":"), graph_src)) == 1L)
    check_true(V, paste0("and the line chart's page calls it"),
               any(grepl(paste0("@", p, ":"), form_src, fixed = TRUE)))
}
check_true(V, "the column survey excludes the time column at the source",
           any(grepl("^\\s*if \\.thisName\\$ <> \\.timeCol\\$\\s*$", graph_src)))
check_true(V, "and asks one reader what numeric means",
           any(grepl("@emlCheckNumericColumn: \\.tableId, \\.thisName\\$",
                     graph_src)))
check_true(V, "the tickbox loop is bounded by the table, with no numeric cap",
           any(grepl('^\\s*boolean: "Series " \\+ string\\$ \\(iN\\) \\+ " \\(" \\+ tsNumName\\$\\[iN\\] \\+ "\\)", tsTick\\[iN\\]\\s*$',
                     form_src)) &&
           !any(grepl("for iN from 1 to min \\(", form_src)))
check_true(V, "and it is read back through the name Praat derived, in a loop",
           any(grepl('^\\s*tsTickName\\$ = "series_" \\+ string\\$ \\(iN\\)\\s*$',
                     form_src)) &&
           any(grepl("^\\s*tsTick\\[iN\\] = 'tsTickName\\$'\\s*$", form_src)))
check_true(V, "the meaning question is one menu with the ruling's two answers",
           any(grepl('optionmenu: "The other columns hold", tsSeriesRole',
                     form_src, fixed = TRUE)) &&
           any(grepl('option: "The same measurement, on different subjects or groups"',
                     form_src, fixed = TRUE)) &&
           any(grepl('option: "Different measurements, on the same subject"',
                     form_src, fixed = TRUE)))
check_true(V, "read back at the name Praat derives from that label",
           any(grepl("^\\s*tsSeriesRole = the_other_columns_hold\\s*$", form_src)))
check_true(V, "and it comes back on the next visit as the user left it",
           any(grepl("^\\s*tsSeriesRole = prev_tsSeriesRole\\s*$", form_src)) &&
           any(grepl("^\\s*prev_tsSeriesRole = tsSeriesRole\\s*$", form_src)))
# THE MELT IS ONE PROCEDURE, AND SINCE 19 AUGUST IT IS IN THE GRAPH
# PROCEDURES AND NOT IN THE FORM. That is not tidying: a recorded step emits a
# call to it, and the emitted script includes the graph, annotation and draw
# files and NOT eml-graphs-form.praat, so a melt that lived in the form was a
# call no replay could resolve. @emlCleanConvertedTable moved for exactly this
# reason and says so in its own header. Section 15 measures the consequence.
check_true(V, "the melt is one procedure and the user is never asked about it",
           sum(grepl("^procedure emlGraphsMeltSeries:", graph_src)) == 1L)
check_true(V, "and it is NOT in the form, which no emitted script includes",
           !any(grepl("^procedure emlGraphsMeltSeries:", form_src)))
check_true(V, "it takes the ticked columns as a LIST, not out of a dialog global",
           any(grepl("^procedure emlGraphsMeltSeries: .objectId, .timeCol\\$, .cols\\$",
                     graph_src)))
check_true(V, "and the form hands it the list it built from the ticks",
           any(grepl("^\\s*\\.\\.\\. tsSeriesCols\\$\\s*$", form_src)))
check_true(V, "producing the two column names the transcript reports",
           any(grepl('"eml_value"', form_src, fixed = TRUE)) &&
           any(grepl('"eml_series"', form_src, fixed = TRUE)))
# THE REFUSAL IS WRAPPED BY THE PLUGIN'S OWN WRAPPER AT THE WIDTH ITS OTHER
# ERROR DIALOG USES, one comment: per line. This is the fix section 8 measures
# from the other end.
check_true(V, "the refusal is wrapped by @emlWrapText at 62 columns",
           any(grepl("^\\s*@emlWrapText: tsRefuse\\$, 62\\s*$", form_src)))
check_true(V, "and laid out one comment: per line, not one per paragraph",
           any(grepl("^\\s*comment: emlWrapText\\.line\\$ \\[iWrap\\]\\s*$",
                     form_src)))
check_true(V, "@emlWrapText is the plugin's own, shared with @emlErrorDialog",
           any(grepl("^procedure emlWrapText:", rd(file.path(PLUG, "stats",
                                                             "eml-output.praat")))))

# ============================================================================
# 15. THE RECORDER -- WHAT THE EMITTED SCRIPT SAYS, AND WHAT IT DRAWS
# ============================================================================
# THE PART OF THE TREE NOTHING HAD MEASURED. Every leg above is about what the
# form ASKS and what the plugin DRAWS. This one is about what the plugin
# WRITES DOWN: press Start recording, draw one line chart through the dialogs,
# press Stop recording, and you get a Praat script. Nothing had ever run one.
#
# WHAT WAS WRONG, MEASURED ON 19 AUGUST 2026 BEFORE IT WAS FIXED. When the
# figure is several columns of one measurement, the form MELTS them into a
# private three-column Table called eml_melt and hands the draw layer that
# object -- then removes it before the workflow returns. The recorder's
# capture hook is inside the draw procedure, so what it recorded was the melt
# table, and the emitted file's manifest read
#
#     data1$ = "Table eml_melt"   ; run 1, step 1 (draw)
#     selectObject: data1$
#
# naming, as the thing the reader must have open, an object the plugin had
# already deleted. Replaying it produced no figure at all:
#
#     Error: No object with name "Table eml_melt".
#     Script line ... not performed or completed: « selectObject: data1$ »
#
# The two-measurement figure was in better shape -- it keeps the user's own
# Table -- and replayed a picture; it is driven here beside the melt so that
# "the second axis survives a round trip" is measured rather than assumed.
#
# THE FIX, AND WHY IT IS SHAPED LIKE @emlConvertForGraph. The melt is a
# CONVERSION: an object the plugin makes from one the user selected, uses, and
# throws away -- which is exactly what Sound -> Pitch is, and the recorder has
# had a step kind for it since it was written. The form now calls
# @emlRecordConvert at the melt, so the manifest names the user's Table, the
# emitted file carries the melt as step 1, and the draw step is marked derived
# and selects nothing. @emlGraphsMeltSeries moved from eml-graphs-form.praat
# into eml-graph-procedures.praat for the reason @emlCleanConvertedTable is
# already there -- the emitted script includes the graph, annotation and draw
# files and NOT the form -- and it takes the ticked columns as a
# comma-separated LIST instead of reading a dialog's array, so that SPEC
# section 8's seriesCols$ reaches the block by the same route every other
# column name does.
#
# THE CLAIM THIS SECTION MAKES IS A PNG MD5. Two replays are driven per leg:
# the file EXACTLY AS EMITTED, and the same file with the two axis numbers
# typed into the block. The second is byte-identical to the figure the session
# drew. The first is not, and that is ruling 10(b) working as ruled rather
# than a defect -- see 15.6.
emitted_src <- function(leg)
    rd(file.path(OUT, paste0(leg, "_emitted.utf8.praat")))
# block_data is written twice in a melted file (once per step), so the
# single-value reader would return NA for it; every other block_ key is
# unique and trv is right for those.
blockv <- function(leg, name) trv(leg, paste0("block_", name))
calls  <- function(leg) trall(leg, "emitted_call")
steps  <- function(leg) trall(leg, "emitted_step")

# ---- 15.1 the recording happened, and it happened as a user's would -------
for (r in RECLEGS) {
    check_true(V, paste0("[", r, "] the recorder was running when Draw was pressed"),
               identical(trn(r, "rec_begun"), 1))
    # WITHOUT THE PHRASE TABLE every step in the file reads
    # "[MISSING PHRASE: drawstep.intent]", and a leg that measured that would
    # be measuring its own path rather than the user's. @emlRecordInit reads
    # ../data/eml-record-phrases.csv relative to the script that was RUN,
    # which is plugin/scripts for a menu wrapper and harness/linetree here;
    # the driver sets the recorder's own emlRecordPhrasePath$ override.
    check_true(V, paste0("[", r, "] with the phrase registry loaded, as a menu ",
                         "command has it"),
               isTRUE(trn(r, "rec_phrases") > 0))
    check_true(V, paste0("[", r, "] and one file was written at Stop"),
               identical(trn(r, "rec_written"), 1))
    check_true(V, paste0("[", r, "] the emitted script is on disk beside the ",
                         "transcript"),
               file.exists(file.path(OUT, paste0(r, "_emitted.praat"))))
    check_true(V, paste0("[", r, "] and it is a whole script, not a stub"),
               isTRUE(trn(r, "emitted_bytes") > 2000))
    check_true(V, paste0("[", r, "] it opens #!praat, so Praat reads it as a ",
                         "script and not as data"),
               identical(emitted_src(r)[1], "#!praat"))
}
# PRAAT CHOOSES THE ENCODING, AND THE DRIVER SNIFFS RATHER THAN ASSUMES.
# rec_subjects4's auto title carries the plus-or-minus sign of the graph
# type's name, so its file comes back UTF-16; rec_meas2's is plain ASCII. A
# blind iconv on the second emits nothing AND EXITS 0.
check_true(V, "[rec_subjects4] its emitted file is UTF-16 (the title is not ASCII)",
           identical(trv("rec_subjects4", "emitted_encoding"), "utf16"))
check_true(V, "[rec_meas2] and its emitted file is ASCII -- the driver sniffed, not guessed",
           identical(trv("rec_meas2", "emitted_encoding"), "ascii"))

# ---- 15.2 the melt is a step of its own -----------------------------------
# ONE PRESS OF DRAW, TWO STEPS, AND THE ORDER IS THE POINT. The melt has to
# be executed before the figure that reads it, and it has to be a CONVERT so
# that the draw step above it selects nothing and inherits `data`.
check_true(V, "[rec_subjects4] the melted figure emitted two steps",
           length(steps("rec_subjects4")) == 2L)
check_true(V, "[rec_subjects4] the first is a convert -- the melt itself",
           identical(steps("rec_subjects4")[1], "# --- Step 1 (convert) ---"))
check_true(V, "[rec_subjects4] the second is the draw",
           identical(steps("rec_subjects4")[2], "# --- Step 2 (draw) ---"))
check_true(V, "[rec_subjects4] and the recorder counted the same two steps",
           identical(trn("rec_subjects4", "rec_steps"), 2))
# THE TWO-MEASUREMENT FIGURE MELTS NOTHING, so it must NOT grow a convert
# step: its two series are two columns of the user's own Table, one on each
# axis. A recorder that emitted a melt here would be reshaping a table that
# is already the right shape.
check_true(V, "[rec_meas2] the two-scale figure emitted one step",
           length(steps("rec_meas2")) == 1L)
check_true(V, "[rec_meas2] and it is a draw, with no melt to convert",
           identical(steps("rec_meas2")[1], "# --- Step 1 (draw) ---"))

# ---- 15.3 the manifest names the user's Table, not the plugin's ----------
# THIS IS THE DEFECT, STATED AS THE REPAIR. The block is what the reader must
# have open before running the file; naming an object the plugin deleted made
# the whole file unrunnable.
check_true(V, "[rec_subjects4] the block names the table the USER selected",
           identical(blockv("rec_subjects4", "data1$"), '"Table lt_subjects4"'))
check_true(V, "[rec_meas2] and so does the two-scale leg's",
           identical(blockv("rec_meas2", "data1$"), '"Table lt_meas2"'))
for (r in RECLEGS) {
    src <- emitted_src(r)
    check_true(V, paste0("[", r, "] no declaration in the file names eml_melt"),
               !any(grepl("^[A-Za-z][A-Za-z0-9_]*\\$?[[:space:]]*=.*eml_melt", src)))
    check_true(V, paste0("[", r, "] and nothing selects it by name"),
               !any(grepl("selectObject:.*eml_melt", src)))
}
# eml_melt IS STILL IN THE FILE, ONCE, AS PROSE: the convert step's own note
# says what was made. That is the sentence a reader needs; it is not an
# instruction.
check_true(V, "[rec_subjects4] the convert step still SAYS what it made",
           any(grepl("^# Converted Table lt_subjects4 to Table eml_melt\\.$",
                     emitted_src("rec_subjects4"))))

# ---- 15.4 the editable block, by name ------------------------------------
# SPEC section 8 named four fields to record per drawing: seriesRole$,
# seriesCols$, rightColName$ and ciAccepted. Only seriesRole$ had been
# implemented. What is here now, and what is deliberately not, is set out at
# 15.7.
S4 <- list(
    "timeCol$"     = '"time"',
    "seriesCols$"  = '"S1,S2,S3,S4"',
    "valueCol$"    = '"eml_value"',
    "groupCol$"    = '"eml_series"',
    "seriesRole$"  = '"subjects"',
    "axisYMin"     = "0.0",
    "axisYMax"     = "0.0",
    "eraseFirst"   = "1",
    "panelOriginX" = "0",
    "panelOriginY" = "0",
    "lineStyle"    = "1",
    "secondAxisOn" = "0")
for (k in names(S4)) {
    check_true(V, paste0("[rec_subjects4] the block declares ", k, " = ", S4[[k]]),
               identical(blockv("rec_subjects4", k), S4[[k]]))
}
# THE LIST IN THE BLOCK IS THE LIST THE FORM TICKED. Read off the form's own
# variables at the end of the press, not restated here: a block that named
# three of four columns would draw three series on replay and look fine.
check_true(V, "[rec_subjects4] and seriesCols$ is exactly what the form said it drew",
           identical(blockv("rec_subjects4", "seriesCols$"),
                     paste0('"', trv("rec_subjects4", "series_cols"), '"')))
M2 <- list(
    "timeCol$"         = '"time"',
    "valueCol$"        = '"f0"',
    "seriesRole$"      = '"measurements"',
    "secondAxisOn"     = "1",
    "secondAxisCol$"   = '"cq"',
    "secondAxisMin"    = "0",
    "secondAxisMax"    = "0",
    "secondAxisLabel$" = '""',
    "secondAxisStyle"  = "3")
for (k in names(M2)) {
    check_true(V, paste0("[rec_meas2] the block declares ", k, " = ", M2[[k]]),
               identical(blockv("rec_meas2", k), M2[[k]]))
}
check_true(V, "[rec_meas2] and the right-hand column is the one the form chose",
           identical(blockv("rec_meas2", "secondAxisCol$"),
                     paste0('"', trv("rec_meas2", "right_col"), '"')))
# ROLES THE SESSION DID NOT USE ARE NOT DECLARED, which is the block's own
# rule (@emlRecordColumnManifest): a groupCol$ = "" would invite a reader to
# fill it in and change what the figure means. Nothing was melted here, so
# there is no series list and no grouping column.
check_true(V, "[rec_meas2] nothing was melted, so the block has no seriesCols$",
           is.na(blockv("rec_meas2", "seriesCols$")))
check_true(V, "[rec_meas2] and no groupCol$: the left series is one ungrouped line",
           is.na(blockv("rec_meas2", "groupCol$")))

# ---- 15.5 the calls, and their arguments ---------------------------------
# NOTHING BELOW THE BLOCK NAMES A COLUMN. That is the block's promise, and the
# melt is the newest thing it has to keep: both of the melt's literals were
# lifted, so the call reads in variables.
MELT <- "@emlGraphsMeltSeries: data, timeCol$, seriesCols$"
check_true(V, "[rec_subjects4] the melt is emitted as a call, in the block's variables",
           MELT %in% calls("rec_subjects4"))
check_true(V, "[rec_subjects4] and it runs BEFORE the figure that reads it",
           which(calls("rec_subjects4") == MELT)[1] <
           grep("^@emlDrawTimeSeries:", calls("rec_subjects4"))[1])
check_true(V, "[rec_subjects4] the melt's result is what the draw is handed",
           any(grepl("^data = emlGraphsMeltSeries\\.tableId$",
                     emitted_src("rec_subjects4"))))
check_true(V, "[rec_subjects4] the draw call reads the three column variables",
           any(grepl("^@emlDrawTimeSeries: data, .*timeCol\\$, valueCol\\$, groupCol\\$",
                     calls("rec_subjects4"))))
check_true(V, "[rec_meas2] its file carries no melt call at all",
           !any(grepl("^@emlGraphsMeltSeries", calls("rec_meas2"))))
check_true(V, "[rec_meas2] and its draw passes NO grouping column",
           any(grepl('^@emlDrawTimeSeries: data, .*timeCol\\$, valueCol\\$, ""',
                     calls("rec_meas2"))))
# THE PENS AND THE SECOND AXIS ARE PUBLISHED IN FRONT OF THE CALL, because
# they are globals rather than arguments -- @emlRecordCaptureSeriesPens's
# whole reason. seriesRole$ leads that group: @emlSecondAxisGate reads it on
# replay, so a right-hand axis on a subjects figure is refused there as it is
# in the form.
for (r in RECLEGS) {
    src <- emitted_src(r)
    check_true(V, paste0("[", r, "] the step assigns emlSeriesRole$ from the block"),
               any(grepl("^emlSeriesRole\\$ = seriesRole\\$$", src)))
    check_true(V, paste0("[", r, "] and emlSecondAxisOn from the block"),
               any(grepl("^emlSecondAxisOn = secondAxisOn$", src)))
}
check_true(V, "[rec_meas2] the five settings that only matter when the axis is ON are emitted",
           all(vapply(c("Col\\$", "Min", "Max", "Label\\$", "Style"),
                      function(k) any(grepl(paste0("^emlSecondAxis", k,
                                                   " = secondAxis"),
                                            emitted_src("rec_meas2"))),
                      logical(1))))
check_true(V, "[rec_subjects4] and they are absent where it is off",
           !any(grepl("^emlSecondAxisCol\\$ =", emitted_src("rec_subjects4"))))

# ---- 15.6 THE REPLAY ------------------------------------------------------
# BOTH FILES ARE RUN, IN A FRESH PRAAT, AND THE PICTURE IS COMPARED.
#
# The replay is driven with --new-send under the same Xvfb the leg was, and
# not with --run. Measured 19 August 2026: a GUI Praat and a batch Praat
# return slightly different text widths, the legend box is sized from the
# width of its widest entry, and the box's left border therefore lands three
# pixels apart at 300 dpi -- 690 differing pixels between two files that are
# otherwise the same figure. Comparing a GUI session with a batch replay
# measures the renderer; comparing like with like measures the recorder.
for (r in RECLEGS) {
    check_true(V, paste0("[", r, "] the emitted script RAN"),
               identical(trv(r, "replay_verdict"), "OK"))
    check_true(V, paste0("[", r, "] with no error line in its log"),
               identical(trv(r, "replay_error"), ""))
    check_true(V, paste0("[", r, "] and drew a 300-dpi page"),
               identical(trv(r, "replay_png_px"), "1800x1200"))
    check_true(V, paste0("[", r, "] its include block was pointed at this tree"),
               isTRUE(trn(r, "replay_include_rewritten") >= 10))
}
# THE STRONGEST CLAIM AVAILABLE, AND THE ONE THIS SECTION EXISTS FOR: the
# emitted file, with the two axis numbers typed into its own block, redraws
# the figure the session drew, BYTE FOR BYTE. If the melt were missing, the
# columns wrong, the pen or the second axis dropped, or the role not carried,
# the md5 would differ.
for (r in RECLEGS) {
    check_true(V, paste0("[", r, "] THE TUNED REPLAY IS BYTE-IDENTICAL TO THE ",
                         "FIGURE THE SESSION DREW (", trv(r, "fig_png_md5"), ")"),
               !is.na(trv(r, "tuned_png_md5")) &&
               identical(trv(r, "tuned_png_md5"), trv(r, "fig_png_md5")))
    check_true(V, paste0("[", r, "] and it is the emitted file, not a rebuild: ",
                         "the tuned copy differs from it in the axis pair alone"),
               identical(trv(r, "tuned_verdict"), "OK") &&
               identical(trv(r, "tuned_error"), ""))
}
# THE PLAIN REPLAY IS MEASURED TOO, AND IT IS NOT EXPECTED TO MATCH.
#
# The block carries the axis the user ASKED for -- 0 and 0, auto -- so that a
# workflow retargeted at other data gets that data's frame; the resolved range
# is a comment beside it. A legend-bearing figure is drawn TWICE by
# @emlGraphsDrawWithLegendRoom, which measures the legend and redraws on a
# widened axis, and that loop is the form's: an emitted script draws once. So
# the plain replay comes back on the un-widened axis, with the key sitting on
# the data it was moved off. That is ruling 10(b) working as ruled -- the
# block records the range the user ASKED for and names the resolved one beside
# it -- and it is written into the transcript here rather than left for
# someone to discover.
#
# AN EARLIER DRAFT OF THIS PARAGRAPH CITED "harness/record's LEG_LEGEND" as
# recording the same gap for the grouped violin. No such leg exists: grep for
# LEG_LEGEND across this repository returns nothing. The citation is removed
# rather than repaired, because nothing in this tree measures that claim and a
# reference nobody can follow is worse than no reference.
for (r in RECLEGS) {
    check_true(V, paste0("[", r, "] the block asks for an AUTO y-axis, per ruling 10(b)"),
               identical(blockv(r, "axisYMin"), "0.0") &&
               identical(blockv(r, "axisYMax"), "0.0"))
    check_true(V, paste0("[", r, "] so the untouched replay is a different picture ",
                         "-- the legend room the FORM negotiated is not in the file"),
               !identical(trv(r, "replay_png_md5"), trv(r, "fig_png_md5")))
    check_true(V, paste0("[", r, "] and the figure said so in the Info window"),
               any(grepl("legend needs y-axis room", info(r), fixed = TRUE)))
    # THE NOTE BESIDE THE AUTO PAIR IS THE READER'S ONLY RECORD of where the
    # figure sat, and it must name the pass that reached the page rather than
    # the one that was thrown away.
    check_true(V, paste0("[", r, "] the block's note quotes the axis the page ",
                         "was drawn on"),
               any(grepl(paste0("^axisYMax.*resolved to ",
                                sprintf("%.4f", trn(r, "axis_y_min")), " \\.\\. ",
                                sprintf("%.4f", trn(r, "axis_y_max"))),
                         emitted_src(r))))
}

# ---- 15.7 the wiring, read in the source ---------------------------------
# The statements above are about one recording of one table. These are about
# the code that made it, so that a second table cannot take a different route.
check_true(V, "the form records the melt through @emlRecordConvert",
           any(grepl("^\\s*@emlRecordConvert: tsOrigObjectId,\\s*$", form_src)))
# TWO CALL SITES SINCE THE PIVOT LANDED, and the guard is asked of BOTH rather
# than of the one that happens to come first. The melt and the pivot are the
# same shape of thing -- a table the form makes, draws from and removes -- and
# a recorder call left unguarded is a "Unknown variable: emlRecordLoaded" for
# every user who never pressed Start recording.
check_true(V, "guarded like every other recorder call site: loaded, then active",
           {
               i <- grep("^\\s*@emlRecordConvert: tsOrigObjectId,\\s*$", form_src)
               length(i) == 2L &&
               all(vapply(i, function(j)
                   any(grepl('variableExists \\("emlRecordLoaded"\\)',
                             form_src[max(1, j - 12):j])) &&
                   any(grepl("emlRecordActive = 1", form_src[max(1, j - 12):j])),
                   logical(1)))
           })
check_true(V, "and the code it hands over assigns to `data`, which is the contract",
           any(grepl('"data = emlGraphsMeltSeries.tableId"', form_src,
                     fixed = TRUE)))
check_true(V, "the recorder lifts the melt's two literals into the block",
           any(grepl('elsif .proc\\$ = "emlGraphsMeltSeries"', rec_src)) &&
           any(grepl('\\.spec\\$ = "2=timeCol 3=seriesCols"', rec_src)))
check_true(V, "and seriesCols$ has a gloss of its own, so the block reads as prose",
           any(grepl('elsif .base\\$ = "seriesCols"', rec_src)))
check_true(V, "@emlRecordCaptureSeriesPens is what puts emlSeriesRole$ in front of the call",
           any(grepl('\\.out\\$ = \\.out\\$ \\+ "emlSeriesRole\\$ = """', rec_src)))
# THE EMITTED INCLUDE LIST IS WHY THE MELT HAD TO MOVE. Anything the file
# calls must be in one of these; eml-graphs-form.praat is not among them and
# is not going to be -- it is the dialogs.
for (r in RECLEGS) {
    src <- emitted_src(r)
    check_true(V, paste0("[", r, "] the emitted file includes the graph procedures"),
               any(grepl("^include .*graphs/eml-graph-procedures\\.praat$", src)))
    check_true(V, paste0("[", r, "] and does NOT include the form"),
               !any(grepl("eml-graphs-form", src)))
}

# ---- 15.8 what SPEC section 8 asked for, and what was left out -----------
# seriesRole$ was the only one of the four implemented. seriesCols$ is here
# now, because replay cannot rebuild the melt without it.
#
# rightColName$ IS HERE UNDER ANOTHER NAME AND IS NOT ADDED TWICE. The
# second-axis change order already records the right-hand column as
# secondAxisCol$, beside the range, the label and the pen it belongs with; a
# rightColName$ would be a second variable for one column, and the two could
# disagree.
check_true(V, "the right-hand column reaches the block once, as secondAxisCol$",
           identical(blockv("rec_meas2", "secondAxisCol$"), '"cq"') &&
           is.na(blockv("rec_meas2", "rightColName$")))
# ciAccepted IS NOT EMITTED, AND THE REASON IS IN THE CALL. Accepting the
# interval does not set a flag the draw layer reads -- it sends the press to a
# DIFFERENT PROCEDURE, and the emitted step names the procedure. A replay
# therefore already carries the answer; a ciAccepted beside it would be a
# variable a reader could set to 1 with no effect, which is worse than absent.
check_true(V, "the interval is carried by which procedure the step calls, not by a flag",
           any(grepl("^@emlDrawTimeSeries:", calls("rec_subjects4"))) &&
           is.na(blockv("rec_subjects4", "ciAccepted")))
check_true(V, "and the CI figure is a draw step of its own in the draw layer",
           any(grepl('@emlRecordDrawStep: .objectId, "Line chart \\(\\+/-CI\\)"',
                     draw_src)) ||
           any(grepl('@emlRecordDrawStep: .objectId, "Line chart', draw_src)))

# ============================================================================
# ============================================================================
# 16. THE LONG SHAPE REACHES THE RIGHT-HAND AXIS
# ============================================================================
# WHAT THE PAGE DID BEFORE THIS SECTION EXISTED, driven on 19 August 2026 with
# the same fixture and the same keystrokes these legs use: the meaning
# question was answered "different measurements", the column page came up
# saying "Measurement column: value" with a "Series names come from" menu on
# "measure", and pressing Draw went straight to Graph Complete. No right-hand
# axis page, no refusal, and -- with the three-level fixture -- three unlike
# quantities normalised onto one shared scale without a word. That is the
# figure the wide path refuses to draw. The tree had made meaning and storage
# independent everywhere except here.
#
# WHAT THE TREE DOES NOW. When the answer is "different measurements" and the
# table is long -- one numeric column beside a column that names what was
# measured -- the series are the LEVELS of the name column. Two levels reach
# the same right-hand axis page, which asks which LEVEL goes on the right;
# three or more meet the same refusal three columns meet, worded for a page
# with nothing to untick. Underneath, @emlGraphsPivotSeries spreads the levels
# into a column each before the draw call, which is the mirror image of the
# melt and equally invisible to the user.
#
# THE CLAIM THIS SECTION EXISTS FOR IS 16.4.

# ---- 16.1 what the tree concluded, out of the form's own variables --------
# long_meas2 is time / value / measure with two levels. Every row below is a
# variable the FORM set, read after its dispatch: the shape it worked out, the
# arm it took, and the two names it handed the drawing layer.
check_true(V, "[long_meas2] the columns are different measurements",
           identical(trv("long_meas2", "series_role"), "measurements"))
check_true(V, "[long_meas2] one numeric column and one text column: the long shape",
           identical(trn("long_meas2", "shape"), 2) &&
           identical(trn("long_meas2", "n_numeric"), 1) &&
           identical(trn("long_meas2", "n_text"), 1))
check_true(V, "[long_meas2] so the series are LEVELS, not columns",
           identical(trn("long_meas2", "level_mode"), 1))
check_true(V, "[long_meas2] and the level count is what reached the tree: two",
           identical(trn("long_meas2", "n_series"), 2))
check_true(V, "[long_meas2] the two levels are named, in table order",
           identical(trv("long_meas2", "series_cols"), "f0,cq"))
check_true(V, "[long_meas2] the name column and the stacked column are both recorded",
           identical(trv("long_meas2", "level_name_col"), "measure") &&
           identical(trv("long_meas2", "long_value_col"), "value"))
# THE LEVELS BECAME COLUMNS. value_col and right_col are level names here and
# column names on the wide path, and after the pivot there is no difference:
# that is the whole mechanism, stated as two rows.
check_true(V, "[long_meas2] the left-hand series is the level the user did not pick",
           identical(trv("long_meas2", "value_col"), "f0"))
check_true(V, "[long_meas2] the right-hand series is the level they did",
           identical(trv("long_meas2", "right_col"), "cq") &&
           identical(trn("long_meas2", "second_axis"), 1))
# AND NOTHING IS GROUPED. A long table drawn as SUBJECTS keeps its name column
# as the grouping column and gets one shared axis; drawn as MEASUREMENTS it is
# pivoted and the grouping column is gone, because each level is now a column
# of its own. A group column surviving here would mean the pivot did not run.
check_true(V, "[long_meas2] and no grouping column survives the pivot",
           identical(trv("long_meas2", "group_col"), ""))
check_true(V, "[long_meas2] the interval was not offered: two scales, ruling 3",
           identical(trn("long_meas2", "ci_offered"), 0) &&
           identical(trn("long_meas2", "ci_accepted"), 0))

# ---- 16.2 the page the user was shown -------------------------------------
# THE ONE THING A SOURCE GREP CANNOT SAY. Section 3's walk already requires
# these five windows in this order; this reads the pixels of the right-hand
# axis page and requires the two options on it to be the two LEVELS.
RHP <- shown1("long_meas2", 4)
check_true(V, "[long_meas2] the right-hand axis page named the two measurements",
           has(RHP, "Right hand axis") && has(RHP, "different scales"))
# THE COLUMN PAGE ASKED WHICH COLUMN NAMES THE SERIES, and opened on the one
# text column the table has. On this page the answer is not a cosmetic
# grouping: it is where the two series come from.
CP <- shown1("long_meas2", 3)
check_true(V, "[long_meas2] the column page offered the name column, on 'measure'",
           has(CP, "Series names come from") && has(CP, "measure"))
check_true(V, "[long_meas2] and named the one numeric column it found",
           has(CP, "Measurement column: value"))

# ---- 16.3 the figure ------------------------------------------------------
# TWO SERIES ON TWO SCALES, READ OFF THE PAGE. The key's second entry carries
# the right-axis tag, which is the drawing layer's own statement that the two
# lines are on different axes; two chromatic colours is palette.py's count of
# how many series actually reached the paper.
check_true(V, "[long_meas2] the key tags the right-hand series",
           has(figtext1("long_meas2"), "right axis"))
check_true(V, "[long_meas2] two series are on the page, counted by colour",
           identical(trn("long_meas2", "fig_chromatic_colours"), 2))
# THE TITLE NAMES THE USER'S TABLE AND NOT THE PLUGIN'S. objectId IS the pivot
# table by the time the title is composed, so an uncorrected source suffix
# reads "(eml pivot)" -- an internal name in the one line of a figure a reader
# reads first. This is the same repair the melt already carries.
# THE OCR IS TREATED AS OCR, per this file's opening note. tesseract renders
# the "lt" prefix of a 300-dpi figure title as "It" -- lowercase L read as
# capital i -- so the match is on the part of the name no plausible misread
# touches. Raw string on this run: "FO over time (It longmeas2)".
check_true(V, "[long_meas2] the composed title names the table the user selected",
           has(figtext1("long_meas2"), "longmeas2"))
check_true(V, "[long_meas2] and never the table the pivot made",
           !has(figtext1("long_meas2"), "eml pivot") &&
           !has(figtext1("long_meas2"), "eml_pivot"))

# ---- 16.4 THE SAME DATA IN THE TWO SHAPES IS THE SAME FIGURE -------------
# THE CLAIM WORTH PINNING ABOVE ALL THE OTHERS IN THIS FILE.
#
# data_meas2.praat and data_longmeas2.praat hold the same twenty-four time
# points and the same two arithmetic expressions under the same two names, one
# table storing them side by side and one storing them stacked. long_titled
# and wide_titled drive those two tables through the same five dialogs with
# the same keystrokes -- including a TYPED title, so that the one thing the
# two figures may legitimately differ in is taken out of the comparison: a
# composed title ends in the name of the table it came from, and the two
# tables have different names.
#
# THE COMPARISON IS A FILE COMPARISON, done by harness/linetree/pngdiff.py and
# read here as rows. Not a colour census, not an axis pair, not a count of
# strokes: the two PNGs are the same file or they are not.
check_true(V, "[identity] the two shapes were compared as files",
           identical(trv("--pairs--", "titled_a"), "long_titled") &&
           identical(trv("--pairs--", "titled_b"), "wide_titled"))
check_true(V, paste0("THE SAME DATA IN THE TWO SHAPES PRODUCES THE SAME FIGURE, ",
                     "BYTE FOR BYTE (", trv("--pairs--", "titled_diff_md5_a"), ")"),
           identical(trv("--pairs--", "titled_diff_verdict"), "IDENTICAL"))
check_true(V, "[identity] the same md5 on both sides, and the same byte count",
           !is.na(trv("--pairs--", "titled_diff_md5_a")) &&
           identical(trv("--pairs--", "titled_diff_md5_a"),
                     trv("--pairs--", "titled_diff_md5_b")) &&
           identical(trv("--pairs--", "titled_diff_bytes_a"),
                     trv("--pairs--", "titled_diff_bytes_b")))
# AND THE TWO LEGS TOOK DIFFERENT ROUTES TO IT. Identical figures from
# identical code paths would be a tautology; what makes this a statement is
# that one of them pivoted and the other did not.
check_true(V, "[identity] one leg pivoted a long table",
           identical(trn("long_titled", "level_mode"), 1) &&
           identical(trv("long_titled", "long_value_col"), "value"))
check_true(V, "[identity] and the other drew two columns as they stood",
           identical(trn("wide_titled", "level_mode"), 0) &&
           identical(trn("wide_titled", "shape"), 1))
check_true(V, "[identity] both put the same level/column on the right-hand axis",
           identical(trv("long_titled", "right_col"), "cq") &&
           identical(trv("wide_titled", "right_col"), "cq"))
check_true(V, "[identity] and both resolved the left axis to the same pair",
           identical(trv("long_titled", "axis_y_min"),
                     trv("wide_titled", "axis_y_min")) &&
           identical(trv("long_titled", "axis_y_max"),
                     trv("wide_titled", "axis_y_max")))

# ---- 16.4b THE UNTYPED PAIR, AND EXACTLY HOW IT DIFFERS -------------------
# long_meas2 and meas2 are the same two figures with the titles left to
# compose. They CANNOT be byte-identical and it would be a defect if they
# were: each title correctly names the table its figure was drawn from. The
# point of measuring them is to say precisely how far the difference goes --
# because "the two figures differ" is indistinguishable, from a verdict alone,
# from a pivot that dropped a point.
#
# MEASURED: 11463 pixels of 2160000 differ, and every one of them is in rows
# 54 to 97 of 1200 -- forty-four rows, which is the title line. The data area
# is identical.
check_true(V, "[identity] the untitled pair was compared too",
           identical(trv("--pairs--", "auto_a"), "long_meas2") &&
           identical(trv("--pairs--", "auto_b"), "meas2"))
check_true(V, paste0("[identity] it differs, as it must -- each title names its ",
                     "own table (", trv("--pairs--", "auto_diff_pixels"),
                     " pixels of ", trv("--pairs--", "auto_diff_total_px"), ")"),
           identical(trv("--pairs--", "auto_diff_verdict"), "DIFFERS"))
check_true(V, paste0("[identity] AND THE DIFFERENCE IS THE TITLE LINE AND ",
                     "NOTHING ELSE: rows ", trv("--pairs--", "auto_diff_rows"),
                     ", ", trv("--pairs--", "auto_diff_row_count"), " rows of them"),
           identical(trv("--pairs--", "auto_diff_rows"), "54-97 of 1200") &&
           identical(trn("--pairs--", "auto_diff_row_count"), 44))
# EACH NAMES ITS OWN AND NOT THE OTHER'S. "longmeas2" contains "meas2", so
# the discriminating statement is the negative one: the wide leg's title does
# NOT carry the long fixture's name.
check_true(V, "[identity] the two titles are the two table names",
           has(figtext1("long_meas2"), "longmeas2") &&
           has(figtext1("meas2"), "meas2") &&
           !has(figtext1("meas2"), "longmeas2"))
# THE DATA AREA AGREES BY A SECOND, INDEPENDENT MEASURE. The row span above
# says the strokes did not move; this says the axis they were drawn on was
# computed identically, to every digit Praat prints.
check_true(V, "[identity] and the axis pair agrees to the last digit",
           identical(trv("long_meas2", "axis_y_min"), trv("meas2", "axis_y_min")) &&
           identical(trv("long_meas2", "axis_y_max"), trv("meas2", "axis_y_max")))

# ---- 16.5 three levels are refused, in the level page's own words ---------
# THE SAME REFUSAL AS THREE COLUMNS AND NOT THE SAME SENTENCE. A figure has
# two vertical axes however the third measurement is stored, so the count is
# refused identically -- but the wide message ends "untick columns until two
# are left", and this page has one column and no tickboxes. The level message
# has to say where the three came from and what can be done instead.
LR <- shown1("long_meas3_refuse", 4)
check_true(V, "[long_meas3_refuse] three levels put a refusal on screen",
           identical(titles("long_meas3_refuse")[4], REFUSE))
# THE COLUMN NAME IN QUOTES, NOT THE BARE WORD. "measure" is a substring of
# "measurements", so a bare match is satisfied by the COLUMN page's refusal --
# "There are 3 different measurements here" -- which names no column at all.
# Measured: the level_refusal_gone break, which puts exactly that message on
# this page, passed a bare match and fails this one.
check_true(V, "[long_meas3_refuse] which names the column the three came from",
           has(LR, "\"measure\" column") && has(LR, "3 different measurements"))
check_true(V, "[long_meas3_refuse] and says a figure has two vertical axes",
           has(LR, "two vertical axes"))
check_true(V, "[long_meas3_refuse] it names the machinery that does the job",
           has(LR, "stacked panels") && has(LR, "Erase page first") &&
           has(LR, "panel origin"))
check_true(V, "[long_meas3_refuse] the whole message is on screen, not under the button",
           has(LR, "press Draw again") && has(LR, "narrow the table"))
# IT DOES NOT SAY "UNTICK COLUMNS". That advice is unfollowable on this page,
# and a refusal a user cannot act on reads as advice while being none.
check_true(V, "[long_meas3_refuse] and does NOT offer advice this page cannot take",
           !has(LR, "untick columns"))
# NOTHING WAS DRAWN WHILE IT WAS ON SCREEN. The refusal comes before the
# draw, so the Picture window must still hold the leg's own empty baseline.
check_true(V, "[long_meas3_refuse] and nothing was drawn behind it",
           identical(trv("long_meas3_refuse", "s4_ink"),
                     trv("long_meas3_refuse", "ink_empty")))
# THE PAGE IT HANDS BACK IS USABLE. There is no tickbox to change here, so the
# way out is the series-name menu: set it to "(none)" and the one measurement
# column is drawn on its own. A refusal that left the form stuck would pass a
# test that stopped at the message.
check_true(V, "[long_meas3_refuse] the column page it returns to still draws",
           identical(trn("long_meas3_refuse", "n_series"), 1) &&
           identical(trv("long_meas3_refuse", "value_col"), "value"))
check_true(V, "[long_meas3_refuse] as one series, with no right-hand axis",
           identical(trn("long_meas3_refuse", "second_axis"), 0) &&
           identical(trv("long_meas3_refuse", "right_col"), "") &&
           identical(trn("long_meas3_refuse", "level_mode"), 0))
check_true(V, "[long_meas3_refuse] and one colour of ink reached the page",
           identical(trn("long_meas3_refuse", "fig_chromatic_colours"), 1))

# ---- 16.6 the recorder carries the pivot the way it carries the melt ------
# WITHOUT THIS THE EMITTED SCRIPT CANNOT RUN, for the melt's reason exactly:
# the two-column table the figure was drawn from is made by the pass and
# removed by it, so a recorded manifest naming it would name an object nobody
# has. The pivot is recorded as a CONVERT step and the emitted file rebuilds
# it from the user's own column and levels.
check_true(V, "[rec_long_meas2] the long leg emitted two steps",
           length(steps("rec_long_meas2")) == 2L)
check_true(V, "[rec_long_meas2] the first is a convert -- the pivot itself",
           identical(steps("rec_long_meas2")[1], "# --- Step 1 (convert) ---"))
check_true(V, "[rec_long_meas2] the second is the draw",
           identical(steps("rec_long_meas2")[2], "# --- Step 2 (draw) ---"))
check_true(V, "[rec_long_meas2] the manifest names the table the USER selected",
           identical(blockv("rec_long_meas2", "data1$"), '"Table lt_longmeas2"'))
# ALL FOUR LITERALS REACH THE BLOCK, each under a name that says what it is.
PIV <- "@emlGraphsPivotSeries: data, timeCol$, longValueCol$, seriesNameCol$, seriesLevels$"
check_true(V, "[rec_long_meas2] the pivot is emitted as a call, in the block's variables",
           PIV %in% calls("rec_long_meas2"))
check_true(V, "[rec_long_meas2] and it runs BEFORE the figure that reads it",
           which(calls("rec_long_meas2") == PIV)[1] <
           grep("^@emlDrawTimeSeries:", calls("rec_long_meas2"))[1])
check_true(V, "[rec_long_meas2] the pivot's result is what the draw is handed",
           any(grepl("^data = emlGraphsPivotSeries\\.tableId$",
                     emitted_src("rec_long_meas2"))))
check_true(V, "[rec_long_meas2] the block carries the time column",
           identical(blockv("rec_long_meas2", "timeCol$"), '"time"'))
check_true(V, "[rec_long_meas2] the stacked value column, under a name of its own",
           identical(blockv("rec_long_meas2", "longValueCol$"), '"value"'))
check_true(V, "[rec_long_meas2] the column that names the measurements",
           identical(blockv("rec_long_meas2", "seriesNameCol$"), '"measure"'))
check_true(V, "[rec_long_meas2] and the two levels, as one editable list",
           identical(blockv("rec_long_meas2", "seriesLevels$"), '"f0,cq"'))
# THE TWO valueCols ARE TWO VARIABLES. The pivot's is the stacked column and
# the draw's is the level that ended up on the left-hand axis; they are
# different columns of different tables, and a block that gave them one name
# would let a reader retarget one and silently move the other.
check_true(V, "[rec_long_meas2] the draw's value column is separate, and is the left level",
           identical(blockv("rec_long_meas2", "valueCol$"), '"f0"'))
check_true(V, "[rec_long_meas2] the right-hand level reaches the block as secondAxisCol$",
           identical(blockv("rec_long_meas2", "secondAxisCol$"), '"cq"') &&
           identical(blockv("rec_long_meas2", "secondAxisOn"), "1"))
# NOTHING WAS MELTED HERE. The two transforms are mirror images and a file
# carrying both would be reshaping a table twice.
check_true(V, "[rec_long_meas2] and no melt call is in the file",
           !any(grepl("^@emlGraphsMeltSeries", calls("rec_long_meas2"))))
check_true(V, "[rec_meas2] nor does the wide two-scale leg pivot anything",
           !any(grepl("^@emlGraphsPivotSeries", calls("rec_meas2"))))
check_true(V, "[rec_subjects4] nor does the melted leg",
           !any(grepl("^@emlGraphsPivotSeries", calls("rec_subjects4"))))
# THE RECORDED TITLE IS THE USER'S TABLE. The emitted draw call carries the
# title as a literal, so the pivot-source repair is readable in the file as
# well as on the figure.
check_true(V, "[rec_long_meas2] the recorded title names the user's table",
           any(grepl("lt longmeas2", calls("rec_long_meas2"), fixed = TRUE)) &&
           !any(grepl("eml pivot", calls("rec_long_meas2"), fixed = TRUE)))

# ---- 16.7 the wiring, read in the source ---------------------------------
# The statements above are about one table. These are about the code, so that
# a second table cannot take a different route.
#
# THE PIVOT LIVES IN THE GRAPH LIBRARY AND NOT IN THE FORM, and that is the
# same rule the melt was moved for: a procedure a RECORDED step emits a call
# to must be in a file the emitted script includes, and the emitted script
# includes the graph, annotation and draw procedures and NOT the form.
check_true(V, "@emlGraphsPivotSeries is defined once, in the graph library",
           sum(grepl("^procedure emlGraphsPivotSeries:", graph_src)) == 1L)
check_true(V, "and not in the form, which no emitted script includes",
           !any(grepl("^procedure emlGraphsPivotSeries:", form_src)))
check_true(V, "with the signature the form and the emitted call both use",
           any(grepl(paste0("^procedure emlGraphsPivotSeries: \\.objectId, ",
                            "\\.timeCol\\$, \\.valueCol\\$, \\.nameCol\\$, ",
                            "\\.levels\\$"), graph_src)))
# THE FORM CALLS IT, AND ASSIGNS ITS RESULT INTO objectId BEFORE THE DISPATCH.
# A pivot built and not adopted would draw the long table with a level name
# for a column and produce an empty frame.
check_true(V, "the form calls the pivot and adopts its table",
           any(grepl("^\\s*@emlGraphsPivotSeries: objectId,", form_src)) &&
           any(grepl("^\\s*tsPivotTableId = emlGraphsPivotSeries\\.tableId$",
                     form_src)) &&
           any(grepl("^\\s*objectId = tsPivotTableId$", form_src)))
# AND REMOVES IT AFTERWARDS, restoring the user's own object. An intermediate
# left in the Objects window is one the user did not make and cannot explain.
check_true(V, "and removes it after the draw, putting objectId back",
           any(grepl("^\\s*removeObject: tsPivotTableId$", form_src)))
# THE LEVELS ARE COUNTED BY THE PROCEDURE THE DRAWING LAYER COUNTS SERIES
# WITH. A private counter here would be a second opinion about how many
# series the figure has, and the refusal is decided on that number.
check_true(V, "the level count comes from @emlCountGroups, as the draw layer's does",
           any(grepl("^\\s*@emlCountGroups: objectId, tsLevelNameCol\\$$",
                     form_src)) &&
           any(grepl("^\\s*tsNSeries = emlCountGroups\\.nGroups$", form_src)))
# THE REFUSAL IS A BRANCH OF ITS OWN. Sharing the wide message would put
# "untick columns" on a page with no tickboxes.
check_true(V, "the level refusal is its own branch with its own words",
           any(grepl("^\\s*if tsLevelMode = 1 and tsNSeries >= 3$", form_src)) &&
           any(grepl("narrow the table to two measurements", form_src)))
check_true(V, "and the column refusal keeps its own",
           any(grepl("^\\s*elsif tsSeriesRole = 2 and tsNSeries >= 3$", form_src)) &&
           any(grepl("untick columns until two are left", form_src)))
# THE RECORDER'S MAP KNOWS THE PIVOT, with four roles and no collision.
check_true(V, "the recorder's column map carries the pivot's four literals",
           any(grepl('elsif \\.proc\\$ = "emlGraphsPivotSeries"', rec_src)) &&
           any(grepl(paste0('\\.spec\\$ = "2=timeCol 3=longValueCol ',
                            '4=seriesNameCol 5=seriesLevels"'), rec_src)))
check_true(V, "and each of its three new roles has a gloss, so the block reads as prose",
           all(vapply(c("longValueCol", "seriesNameCol", "seriesLevels"),
                      function(b) any(grepl(paste0('\\.base\\$ = "', b, '"'),
                                            rec_src)),
                      logical(1))))
# THE DRAW LAYER WAS NOT TAUGHT ABOUT LEVELS, which is the point of doing this
# as a table transform: @emlDrawTimeSeries takes a left column and a right
# column by name and knows nothing about how they got there.
check_true(V, "and @emlDrawTimeSeries was not taught what a level is",
           !any(grepl("emlGraphsPivotSeries|tsLevelMode", draw_src)))

# ============================================================================
# EVERYTHING THE DRIVER RENDERED IS LOOKED AT
# ============================================================================
# "--run--" is the run header, not a leg: it carries the Praat version, the
# code digests and the leg list, all of which section 1 reads.
# "--pairs--" is the second such header: it carries the file-level comparison
# of the two shapes' figures, which is a statement ABOUT two legs and belongs
# to neither. Section 16.4 reads it.
present <- setdiff(unique(TR$case), c("--run--", "--pairs--"))
eml_census(V, "line-tree legs", present, CASES)

if (!exists("EML_SUITE")) eml_report("v97 -- the line chart's question tree")
