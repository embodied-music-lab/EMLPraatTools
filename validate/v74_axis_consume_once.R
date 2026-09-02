# ============================================================================
# v74_axis_consume_once.R -- the axis publication is spent when it is read
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# THE RULING THIS FILE IMPLEMENTS (author, ruling A of change order 7, 16
# August 2026): the graphs form's axis publication is to carry a STEP STAMP.
# @emlRecordAxisRequest accepts the published pair only when the stamp equals
# the step being recorded, and reassigns the stamp to 0 the moment it has
# validated it.
#
# THE DEFECT. Praat cannot unset a variable. Ruling 10(b) had the graphs form
# publish the axis range the user asked for -- emlGraphsAxisYReqMin and
# emlGraphsAxisYReqMax -- because two passes inside the form turn AUTO into
# explicit numbers before the draw the recorder records. @emlRecordAxisRequest
# preferred that pair whenever it EXISTED, and in Praat existence is
# permanent. So the first press of Draw in a session armed every recorded draw
# after it: "some form ran earlier this session" was indistinguishable from
# "this draw came from the form", in any menu command, from any file.
#
# graphs/eml-draw-qq.praat:259 is where it shows. That file calls
# @emlDrawScatterPlot with 0, 0, 0, 0 -- its own auto sentinel -- and has no
# dialog of its own. Draw a violin from EML Graphs on a typed 0 .. 100, then
# ask for a Q-Q plot in the same session with a recording running, and the
# Q-Q step's editable block declared axisYMin = 0.0 / axisYMax = 100.0. Edit
# that block to re-run the workflow on a second speaker -- the entire purpose
# the block exists for -- and the Q-Q plot is drawn on a range the first
# figure's dialog chose, silently. The fallback in @emlRecordAxisRequest was
# already correct for that call. It was simply never reached.
#
# WHY THE STAMP AND NOT A CLEARED PAIR, which is the "simplification" this
# file exists to stop somebody making. The pair CANNOT be reset: 0 and 0 IS
# the auto sentinel -- the range a user gets by leaving the dialog alone --
# so "spent" and "the user asked for auto" would be the same two doubles and
# the reader could not tell them apart. The stamp has no such collision: step
# numbers start at 1, so 0 means CONSUMED and nothing else. The consume-once
# state lives in the one variable that can be overwritten with a value meaning
# nothing, because Praat will not let it be removed. Section 1 pins that shape
# in the source; sections 2 to 6 pin the behaviour.
#
# WHAT COULD NOT HAVE CAUGHT THIS, AND WHY. Every item below is a check that
# exists in this tree, is green, and is green on a tree with the defect in it.
#
#   EVERY EXISTING AXIS RIG. harness/formaxis draws ONCE per leg and every
#   draw it makes is a form draw, so the publication is always legitimately
#   live and preferring it is always right. harness/axisspec's rec_form leg
#   publishes the pair by hand and then draws once. harness/record's
#   roundtrip_graph.sh -- the strongest evidence in the tree that a recorded
#   figure replays -- calls @emlDrawViolinPlot directly, so no form runs, the
#   globals never exist, the fallback fires and the round trip is byte-perfect
#   while the defect sits untouched one layer up. The defect needs TWO DRAWS
#   IN ONE PRAAT PROCESS with only the first going through the form, and no
#   rig in this tree performed that sequence. harness/consumeonce does.
#
#   A CHECK FOR THE NAME. A validator that greps the source for
#   "emlGraphsAxisYReqStep" and reports it present passes against a stamp that
#   is published and never read, published and never reset, or compared with
#   the wrong number. All three are repairs somebody would write. Section 1 is
#   deliberately the SMALLEST part of this file, and nothing in it is trusted
#   on its own: every claim it makes is re-made as a driven value below.
#
#   A CHECK ON THE Q-Q FIGURE. The picture is correct on both sides of this
#   fix. The Q-Q plot is drawn on the axis @emlDrawScatterPlot resolves from
#   the data whatever the recorder later writes down, because the leak is in
#   what gets RECORDED, not in what gets drawn. Ink, byte counts, image rows
#   and file sizes are all identical across the repair, so none of them is
#   read here.
#
#   AN AUTO RANGE ON THE FORM LEG. This is the trap that would have made the
#   whole rig unfalsifiable, and it is why every leaking leg types 0 .. 100
#   rather than leaving the dialog alone. If the form leg were on AUTO, the
#   value it leaks and the value the Q-Q plot correctly records would BOTH be
#   0.0, and the leg would be green on a tree with the bug in it.
#
#   COUNTING THE DECLARATIONS IN THE BLOCK. A two-figure leg emits four axis
#   declarations before the repair and four after -- 0/100 and 0.0/0.0 on a
#   fixed tree, 0/100 twice over on a broken one, which the renderer merges
#   into TWO. So the count moves the wrong way: the broken tree has FEWER
#   declarations, and a check that the block is "complete" reads better on the
#   defect. The VALUES are what is read here, with the step each belongs to
#   taken from the declaration's own comment.
#
# THE THREE REPAIRS THIS FILE HAS TO TELL APART, and where each dies:
#
#   THE FIX-SHAPED FIX -- stop preferring the publication at all, keep the
#   fallback. It closes every leak leg and undoes ruling 10(b) in silence.
#   It dies on `stamp_live`, where a correct stamp must still deliver the
#   sentinel over an argument of 150 .. 400, and on the form legs, whose
#   FIRST step must still declare the user's 0 .. 100.
#
#   THE EXISTENCE CHECK -- accept the pair whenever a stamp global exists.
#   The stamp exists on every leg here including the leaking ones, so this
#   passes everything except `stamp_stale`, which publishes a stamp naming a
#   step the draw will never be.
#
#   THE STAMP TAKEN AT PUBLICATION TIME rather than at dispatch. It looks
#   right and it is wrong on the ruling's own headline case: the annotation
#   bridge RECORDS A STEP between the publication and the draw, so on an
#   annotated figure the comparison is step 1 and the figure is step 2. It
#   dies on `bridge_then_qq`, whose emitted file carries an analysis step
#   between the two, and whose violin must still declare the typed 0 .. 100.
#
# WHAT WAS BROKEN, AND WHAT WENT RED. harness/consumeonce/break.sh builds six
# shadow copies of the repository, one deliberate defect each, drives the rig
# in each and runs this file against it. Every one went red, and the count is
# the interesting part -- a break that reds two checks is as much a result as
# one that reds twenty-five, because it says which check is carrying it:
#
#   head_record       21   the reader reverted to HEAD -- THE DEFECT ITSELF.
#                          The headline red reads "the Q-Q figure records its
#                          OWN auto sentinel, not the form's 0 .. 100 (0 /
#                          100)": the Q-Q step declaring the violin's dialog.
#   head_form         25   the form reverted -- no stamp published at all, so
#                          every form figure loses its own user's range
#   exists_only       12   the reader asks whether a stamp exists, not whether
#                          it names this step; the leak comes straight back
#   no_consume         7   the stamp validated and never zeroed. The recorded
#                          ranges stay right on this rig, because the stamp
#                          goes stale on its own once the step number moves --
#                          section 6, which reads the stamp out of the running
#                          process, is the only thing that can see it
#   stamp_at_publish   2   the re-take at dispatch removed. Two reds, and the
#                          behavioural one is the whole argument for the
#                          placement: the annotated figure's declaration comes
#                          out 0 .. 184.8013, the widened ceiling, because the
#                          bridge's analysis step moved the number under it
#   stamp_one_branch  16   the stamp moved inside the first branch of the type
#                          chain, so twelve of thirteen types publish a pair
#                          with no stamp. Section 7 and the source shape are
#                          the only things that go red, which is the honest
#                          size of that claim -- see section 7's own note
#
# Inputs: harness/consumeonce/out/CONSUMEONCE.tsv and the emitted scripts
#         beneath it. $EML_CO_DIR overrides the evidence folder,
#         $EML_CO_GRAPH_SRC and $EML_CO_STATS_SRC the two source folders, so a
#         break test can point this file at a different copy of the tree
#         without touching the working one. A break test that edits the
#         repository and puts it back is one interrupted run away from
#         committing a defect.
#
#   bash harness/consumeonce/consumeonce.sh
#   Rscript validate/v74_axis_consume_once.R
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

ID <- "v74"

gdir <- Sys.getenv("EML_CO_GRAPH_SRC", unset = "")
if (!nzchar(gdir)) gdir <- repo_path(file.path("plugin", "graphs"))
sdir <- Sys.getenv("EML_CO_STATS_SRC", unset = "")
if (!nzchar(sdir)) sdir <- repo_path(file.path("plugin", "stats"))
cdir <- Sys.getenv("EML_CO_DIR", unset = "")
if (!nzchar(cdir)) cdir <- repo_path(file.path("harness", "consumeonce", "out"))

f_form <- file.path(gdir, "eml-graphs-form.praat")
f_rec  <- file.path(sdir, "eml-record.praat")
f_qq   <- file.path(gdir, "eml-draw-qq.praat")

check_true(ID, "the form, the recorder and the Q-Q adapter are all present",
           all(file.exists(c(f_form, f_rec, f_qq))))

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS, AND STRIP WHOLE-LINE COMMENTS BEFORE MATCHING.
#
# Both halves have bitten this repository. Calls in these files are written
# across two and three physical lines with "...", so a line-at-a-time regex
# sees a procedure name with no arguments and an argument list with no
# procedure. And every repair here carries a paragraph above it that names the
# procedures and globals being checked for -- this one names
# emlGraphsAxisYReqStep eleven times in prose -- so an unstripped grep finds
# the wiring present after every line of it has been deleted.
#
# Praat whole-line comment forms are `#`, `;` and `!`.
# ---------------------------------------------------------------------------
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
    norm[!grepl("^#", norm) & !grepl("^;", norm) & !grepl("^!", norm)]
}

code_form <- read_code(f_form)
code_rec  <- read_code(f_rec)
code_qq   <- read_code(f_qq)

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

# The harness TSV, scoped by leg. Keys repeat across legs on purpose -- every
# record leg emits `_blockline` two or four times -- so a flat map would answer
# every one of them with the first.
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

# decl_value / decl_name -- the VALUE and the NAME out of one declaration line
# of the emitted block, taken from the left of the first `;`.
#
# The block writes `axisYMin  = 0.0   ; the y-axis range -- AUTO ...`, and the
# trailing gloss is prose that repeats the number in words. Splitting there is
# what keeps this a check on the DECLARATION and not on the sentence beside
# it: a renderer that wrote `axisYMin = 100  ; ... AUTO ...` would otherwise
# satisfy a grep for "AUTO" and for the wrong number at once.
decl_value <- function(ln) {
    if (is.na(ln) || !nzchar(ln)) return(NA_character_)
    lhs <- sub(";.*$", "", ln)
    if (!grepl("=", lhs, fixed = TRUE)) return(NA_character_)
    trimws(sub("^[^=]*=", "", lhs))
}
decl_name <- function(ln) {
    if (is.na(ln) || !nzchar(ln)) return(NA_character_)
    trimws(sub("=.*$", "", sub(";.*$", "", ln)))
}
# THE STEP A DECLARATION BELONGS TO, out of its own gloss. On a two-figure leg
# this is the only thing in the file that says which FIGURE a range was
# recorded for, and without it "the block contains 0.0 somewhere" would stand
# in for "the Q-Q step recorded the sentinel".
#
# RESOLVING A RECORDED CALL TO THE DECLARATION IT READS, which is the only way
# these checks can be made without a length gate in front of them. On a
# DEFECTIVE tree the two figures record the same range, the renderer merges
# them into ONE pair of variables, and a check written as "the third and
# fourth declarations say 0.0" is not red on that tree -- it is SKIPPED,
# because there is no third declaration. The count moving the wrong way is
# itself a symptom (fewer declarations on the broken tree, not more), so it is
# checked separately; but the value check has to follow the call.
#
# Splitting the call on commas is safe on this rig's own fixtures and nowhere
# else: the titles the drive uses contain none. The two axis arguments are the
# last two before the trailing `annotate` flag.
call_axis_names <- function(call) {
    if (is.na(call) || !nzchar(call)) return(character(0))
    p <- trimws(strsplit(call, ",", fixed = TRUE)[[1]])
    n <- length(p)
    if (n < 3) return(character(0))
    p[c(n - 2L, n - 1L)]
}
decl_steps <- function(ln) {
    if (is.na(ln) || !nzchar(ln)) return(integer(0))
    m <- regmatches(ln, gregexpr("step[s]? [0-9, ()a-z]+$", ln))[[1]]
    if (!length(m)) return(integer(0))
    as.integer(regmatches(m[1], gregexpr("[0-9]+", m[1]))[[1]])
}

co   <- read_legged_tsv(file.path(cdir, "CONSUMEONCE.tsv"))
have <- length(co) > 0
av   <- function(k) if (is.null(co[[k]])) NA_character_ else co[[k]][1]
an   <- function(k) suppressWarnings(as.numeric(av(k)))
avv  <- function(k) if (is.null(co[[k]])) character(0) else co[[k]]
`%or%` <- function(a, b) if (is.na(a) || !nzchar(a)) b else a

# The block declaration of a given variable name, on a given leg.
decl_line_for <- function(leg, nm) {
    if (!length(nm) || is.na(nm)) return(NA_character_)
    bl <- avv(sprintf("%s_blockline", leg))
    if (!length(bl)) return(NA_character_)
    hit <- bl[vapply(bl, function(z) identical(decl_name(z), nm), logical(1))]
    if (!length(hit)) NA_character_ else hit[1]
}

REC_LEGS <- c("form_then_qq", "bridge_then_qq", "form_then_violin",
              "stamp_live", "stamp_stale", "pair_unstamped", "qq_alone")

check_true(ID,
    "the consume-once drive produced evidence (harness/consumeonce/consumeonce.sh)",
    have)
if (have) {
    pv <- av("praat_version")
    check_true(ID, sprintf("and it ran on the supported binary (%s)", pv),
               !is.na(pv) && grepl("^Praat 6\\.6\\.3[0-9]|^Praat [7-9]", pv))
    # EVERY LEG EXITED 0. A Praat script error aborts the script, and a leg
    # that died halfway leaves a TSV whose absent keys read exactly like a
    # value that was measured and came out empty.
    # The exit status is written while the leg marker still names the leg, so
    # it is legged like everything else the drive emitted.
    for (lg in c(REC_LEGS, "stamp_types")) {
        check_true(ID, sprintf("leg %s ran to completion", lg),
                   identical(av(sprintf("%s.%s_exit", lg, lg)), "0"))
    }
    for (lg in REC_LEGS) {
        check_true(ID, sprintf("leg %s emitted a script and flushed one file", lg),
                   identical(av(sprintf("%s_emitted", lg)), "yes") &&
                   identical(av(sprintf("%s.%s_flushed", lg, lg)), "1"))
    }
}

# ===========================================================================
# 1. THE SHAPE IN THE SOURCE
# ===========================================================================
# The smallest section here, and nothing in it is load-bearing on its own:
# every claim it makes is re-made as a driven value below. What it is for is
# the shape a values-only check cannot see -- that the stamp is written ONCE
# below the type chain rather than four times inside it, and that the reader
# zeroes it.

pub  <- proc_body_of(code_form, "emlGraphsPublishAxisRequest")
stmp <- proc_body_of(code_form, "emlGraphsStampAxisRequest")
disp <- proc_body_of(code_form, "emlGraphsDispatchDraw")
head_body <- proc_body_of(code_form, "emlGraphsPreDispatchHeadroom")
leg_body  <- proc_body_of(code_form, "emlGraphsDrawWithLegendRoom")
axreq <- proc_body_of(code_rec, "emlRecordAxisRequest")

check_true(ID, "@emlGraphsStampAxisRequest exists and was found",
           length(stmp) > 0)
# THE STAMP IS WRITTEN ONCE, BELOW THE TYPE CHAIN. The pair is published by a
# four-branch chain because "the y-axis range" is four different dialog pairs;
# the stamp is not type-dependent, so four copies of it would be four chances
# to leave it out of a fifth branch -- and a branch that published a pair with
# no stamp is a graph type that keeps the whole defect while the other twelve
# are repaired, with nothing to see, because the pair it published is right.
check(ID, "every write to the stamp in the form is inside that one procedure",
      cnt(code_form, "^emlGraphsAxisYReqStep ="),
      cnt(stmp, "^emlGraphsAxisYReqStep ="), tol = 0)
check_true(ID,
    "the publication calls it once, after the type chain rather than inside it",
    cnt(pub, "@emlGraphsStampAxisRequest") == 1 &&
    length(pub) > 0 &&
    tail(which(grepl("@emlGraphsStampAxisRequest", pub)), 1) >
        tail(which(grepl("^emlGraphsAxisYReqM(in|ax) =", pub)), 1))
# AND THE DISPATCH RE-TAKES IT. This is the half a source check is actually
# needed for: the values below prove the stamp is right, but only the source
# says WHERE it was taken, and "at publication time" is the plausible wrong
# answer that section 3 exists to kill.
check(ID, "and @emlGraphsDispatchDraw re-takes the stamp before drawing",
      cnt(disp, "@emlGraphsStampAxisRequest"), 1, tol = 0)
check_true(ID, "the stamp is the recorder's next step, and 0 when nothing records",
           has(stmp, "^emlGraphsAxisYReqStep = emlRecordN \\+ 1$") &&
           has(stmp, "^emlGraphsAxisYReqStep = 0$") &&
           has(stmp, "^if emlRecordActive = 1$"))
# NEITHER RESOLVING PASS TOUCHES THE PAIR OR THE STAMP -- v68 owns the pair
# half of this; it is restated here because the stamp is a NEW name and a
# republication from inside either pass would republish the RESOLUTION.
check(ID, "the bracket-headroom pass writes no published global",
      cnt(head_body, "emlGraphsAxisYReq"), 0, tol = 0)
check(ID, "the legend-room pass writes no published global",
      cnt(leg_body, "emlGraphsAxisYReq"), 0, tol = 0)

# THE READER. Compared against emlRecordN + 1 -- which IS the definition of
# "the step being recorded", because @emlRecordStep increments and then
# appends and this procedure runs before it -- and zeroed afterwards.
check_true(ID, "@emlRecordAxisRequest exists and was found", length(axreq) > 0)
check_true(ID,
    "the reader compares the stamp with the step it is about to record",
    has(axreq, "^\\.step = emlRecordN \\+ 1$") &&
    has(axreq, "^if emlGraphsAxisYReqStep = \\.step$"))
check_true(ID, "and zeroes the stamp once it has read it",
           has(axreq, "^emlGraphsAxisYReqStep = 0$"))
check(ID, "the recorder's only write to the stamp is that zeroing",
      cnt(code_rec, "^emlGraphsAxisYReqStep ="), 1, tol = 0)
# THE PAIR IS STILL READ AS A PAIR, and still through nested ifs: Praat does
# not short-circuit `and`, so one condition naming all three globals would
# read emlGraphsAxisYReqMin on a caller that never published it and abort the
# user's draw with "Unknown variable".
check_true(ID, "the pair is still taken as a pair, through nested variableExists",
           has(axreq, "variableExists \\(\"emlGraphsAxisYReqMin\"\\)") &&
           has(axreq, "variableExists \\(\"emlGraphsAxisYReqMax\"\\)") &&
           has(axreq, "variableExists \\(\"emlGraphsAxisYReqStep\"\\)"))
# THE SITE THE DEFECT WAS FOUND AT, pinned so that a Q-Q plot which one day
# grew a dialog of its own cannot leave this file quietly testing nothing.
check_true(ID,
    "the Q-Q adapter still hands @emlDrawScatterPlot its own auto sentinel",
    has(code_qq, "@emlDrawScatterPlot: .*, 0, 0, 0, 0, 0$"))

# ===========================================================================
# 2. THE LEAK, DRIVEN -- A FORM DRAW AND THEN A Q-Q DRAW IN ONE PROCESS
# ===========================================================================
# The scenario in one sentence: EML Graphs, violin, y-range TYPED as 0 .. 100,
# Draw, with a recording running; then Normal Q-Q plot, same session, same
# recording. Two draw steps in one emitted script, and they must not carry the
# same axis.
if (have) {
    check_true(ID,
        sprintf("the form leg typed a range and did not leave it on auto (%s)",
                av("form_then_qq.form_then_qq_dialog")),
        identical(av("form_then_qq.form_then_qq_dialog"), "0..100.0000"))
    check_true(ID, "the Q-Q plot drew rather than refusing",
        identical(av("form_then_qq.form_then_qq_qq_drew"), "1") &&
        identical(av("form_then_qq.form_then_qq_qq_error") %or% "", ""))
    check(ID, "the emitted script carries exactly two steps",
          an("form_then_qq_steps"), 2, tol = 0)
    check_true(ID, "and both of them are draws",
        identical(avv("form_then_qq_stepline"),
                  c("# --- Step 1 (draw) ---", "# --- Step 2 (draw) ---")))

    bl <- avv("form_then_qq_blockline")
    check(ID, "the block declares four axis variables, two per figure",
          length(bl), 4, tol = 0)
    if (length(bl) == 4) {
        # --- the FORM figure, step 1: the user's typed range survives -------
        check_true(ID,
            sprintf("the form figure's declaration belongs to step 1 and reads 0 (%s)",
                    bl[1]),
            identical(decl_name(bl[1]), "axisYMin") &&
            identical(decl_steps(bl[1]), 1L) &&
            identical(suppressWarnings(as.numeric(decl_value(bl[1]))), 0))
        check_true(ID,
            sprintf("and its ceiling is the typed 100, not the auto sentinel (%s)",
                    decl_value(bl[2]) %or% "<absent>"),
            identical(decl_name(bl[2]), "axisYMax") &&
            identical(suppressWarnings(as.numeric(decl_value(bl[2]))), 100))
    }
    # --- the Q-Q figure, step 2: its OWN auto sentinel ----------------------
    # THIS IS THE CHECK THE WHOLE FILE IS FOR, and it is written by FOLLOWING
    # THE RECORDED CALL to the declaration it reads rather than by counting to
    # the third line of the block. On a tree with the defect the Q-Q call
    # reads `axisYMin, axisYMax` -- the form figure's own variables, because
    # the two figures recorded the same range and the renderer merged them --
    # and those declare 0 and 100. The first figure's dialog, on a figure that
    # has no dialog.
    qn <- call_axis_names(av("form_then_qq_scatter_call"))
    check_true(ID,
        sprintf("the recorded Q-Q call names two axis variables from the block (%s)",
                paste(qn, collapse = ", ") %or% "<absent>"),
        length(qn) == 2 && all(grepl("^axisY(Min|Max)[0-9]*$", qn)))
    qmin <- decl_line_for("form_then_qq", qn[1])
    qmax <- decl_line_for("form_then_qq", qn[2])
    check_true(ID,
        sprintf("the declaration the Q-Q call reads belongs to step 2, the Q-Q figure (%s)",
                qmin %or% "<absent>"),
        identical(decl_steps(qmin %or% ""), 2L))
    check_true(ID,
        sprintf("and the Q-Q figure records its OWN auto sentinel, not the form's 0 .. 100 (%s / %s)",
                decl_value(qmin %or% "") %or% "<absent>",
                decl_value(qmax %or% "") %or% "<absent>"),
        identical(decl_value(qmin %or% ""), "0.0") &&
        identical(decl_value(qmax %or% ""), "0.0"))
    check_true(ID,
        "and it says so in words -- AUTO, both 0 -- rather than only in the number",
        grepl("AUTO", qmin %or% "", fixed = TRUE))
    # AND THE VIOLIN'S OWN CALL STILL READS THE TYPED RANGE. Followed the same
    # way, so that a repair which simply stopped preferring the publication --
    # ruling 10(b) undone -- cannot pass this section by making both figures
    # read a sentinel.
    vn <- call_axis_names(paste0("x, ", av("form_then_qq_violin_call"), ", 0"))
    vmin <- decl_line_for("form_then_qq", vn[1])
    vmax <- decl_line_for("form_then_qq", vn[2])
    check_true(ID,
        sprintf("the recorded violin call reads a declaration of the typed 0 .. 100 (%s / %s)",
                decl_value(vmin %or% "") %or% "<absent>",
                decl_value(vmax %or% "") %or% "<absent>"),
        identical(suppressWarnings(as.numeric(decl_value(vmin %or% ""))), 0) &&
        identical(suppressWarnings(as.numeric(decl_value(vmax %or% ""))), 100) &&
        identical(decl_steps(vmin %or% ""), 1L))
}

# ===========================================================================
# 3. THE STAMP NAMES THE RIGHT STEP -- A RECORDED STEP IN BETWEEN
# ===========================================================================
# The plausible wrong repair is to take the stamp where the pair is published.
# It is wrong on the ruling's own headline case: an annotated figure runs
# @emlRunAnnotationComparison first, and the bridge RECORDS A STEP OF ITS OWN,
# so the comparison is step 1 and the figure is step 2. A publication-time
# stamp names step 1, the figure is refused its own user's range, and ruling
# 10(b) is undone by the repair meant to protect it -- with no error, and with
# every leak leg still green.
if (have) {
    check_true(ID,
        sprintf("the annotated leg produced brackets, so the bracket path really runs (%s)",
                av("bridge_then_qq.bridge_then_qq_brackets")),
        is.finite(an("bridge_then_qq.bridge_then_qq_brackets")) &&
        an("bridge_then_qq.bridge_then_qq_brackets") > 0)
    check(ID, "its emitted script carries three steps",
          an("bridge_then_qq_steps"), 3, tol = 0)
    check_true(ID,
        "and the first is an ANALYSIS step, recorded between the publication and the draw",
        identical(avv("bridge_then_qq_stepline"),
                  c("# --- Step 1 (analysis) ---", "# --- Step 2 (draw) ---",
                    "# --- Step 3 (draw) ---")))
    # The two numbers that say the stamp moved: 1 when the pair was published,
    # and the figure recorded as step 2.
    check(ID, "the stamp taken at publication time would have named step 1",
          an("bridge_then_qq.bridge_then_qq_afterpublish_stamp"), 1, tol = 0)
    # AND THE BRACKET PASS RESOLVED THE TYPED RANGE FIRST, so the recorded 100
    # cannot be the variable the draw was handed.
    check_true(ID,
        sprintf("the bracket pass widened the typed ceiling before the draw (%s)",
                av("bridge_then_qq.bridge_then_qq_resolved")),
        !is.na(av("bridge_then_qq.bridge_then_qq_resolved")) &&
        suppressWarnings(as.numeric(
            sub("^.*\\.\\.", "", av("bridge_then_qq.bridge_then_qq_resolved")))) > 100)

    check(ID, "its block declares four axis variables",
          length(avv("bridge_then_qq_blockline")), 4, tol = 0)
    # Followed from the recorded calls, for the reason section 2 gives: on a
    # broken tree the two figures share one declaration and an index-based
    # check is skipped rather than red.
    vn <- call_axis_names(paste0("x, ",
              avv("bridge_then_qq_violin_call")[1] %or% "", ", 0"))
    vmin <- decl_line_for("bridge_then_qq", vn[1])
    vmax <- decl_line_for("bridge_then_qq", vn[2])
    check_true(ID,
        sprintf("the annotated figure is step 2 and still declares the typed 0 .. 100 (%s / %s)",
                decl_value(vmin %or% "") %or% "<absent>",
                decl_value(vmax %or% "") %or% "<absent>"),
        identical(decl_steps(vmin %or% ""), 2L) &&
        identical(suppressWarnings(as.numeric(decl_value(vmin %or% ""))), 0) &&
        identical(suppressWarnings(as.numeric(decl_value(vmax %or% ""))), 100))
    qn <- call_axis_names(avv("bridge_then_qq_scatter_call")[1] %or% "")
    qmin <- decl_line_for("bridge_then_qq", qn[1])
    qmax <- decl_line_for("bridge_then_qq", qn[2])
    check_true(ID,
        sprintf("and the Q-Q figure after it is step 3 with its own sentinel (%s / %s)",
                decl_value(qmin %or% "") %or% "<absent>",
                decl_value(qmax %or% "") %or% "<absent>"),
        identical(decl_steps(qmin %or% ""), 3L) &&
        identical(decl_value(qmin %or% ""), "0.0") &&
        identical(decl_value(qmax %or% ""), "0.0"))
}

# ===========================================================================
# 4. THE LEAK IS NOT ABOUT THE Q-Q PLOT
# ===========================================================================
# The Q-Q plot is where it was found, not where it lives: any draw procedure
# reached without the form inherits the same publication. This leg follows the
# form press with a DIRECT @emlDrawViolinPlot at 150 .. 400 -- the shape of the
# API export, the batch module and every user script -- and 150 .. 400 is
# neither the form's 0 .. 100 nor the auto sentinel, so only a correct fallback
# produces it.
if (have) {
    check(ID, "the second-draw leg emitted two steps",
          an("form_then_violin_steps"), 2, tol = 0)
    check(ID, "and four axis declarations",
          length(avv("form_then_violin_blockline")), 4, tol = 0)
    vc <- avv("form_then_violin_violin_call")
    check(ID, "the emitted script carries both violin calls", length(vc), 2,
          tol = 0)
    v1 <- call_axis_names(paste0("x, ", vc[1] %or% "", ", 0"))
    v2 <- call_axis_names(paste0("x, ", vc[length(vc)] %or% "", ", 0"))
    a1min <- decl_line_for("form_then_violin", v1[1])
    a1max <- decl_line_for("form_then_violin", v1[2])
    a2min <- decl_line_for("form_then_violin", v2[1])
    a2max <- decl_line_for("form_then_violin", v2[2])
    check_true(ID,
        sprintf("the form figure kept its typed 0 .. 100 (%s / %s)",
                decl_value(a1min %or% "") %or% "<absent>",
                decl_value(a1max %or% "") %or% "<absent>"),
        identical(suppressWarnings(as.numeric(decl_value(a1min %or% ""))), 0) &&
        identical(suppressWarnings(as.numeric(decl_value(a1max %or% ""))), 100))
    check_true(ID,
        sprintf("and the formless violin after it recorded its OWN 150 .. 400 (%s / %s)",
                decl_value(a2min %or% "") %or% "<absent>",
                decl_value(a2max %or% "") %or% "<absent>"),
        identical(decl_steps(a2min %or% ""), 2L) &&
        identical(suppressWarnings(as.numeric(decl_value(a2min %or% ""))), 150) &&
        identical(suppressWarnings(as.numeric(decl_value(a2max %or% ""))), 400))
}

# ===========================================================================
# 5. THE THREE CONTROLS -- LIVE, STALE, UNSTAMPED
# ===========================================================================
# Without section 5a this file is satisfied by a recorder that ignores the
# publication entirely, which is ruling 10(b) deleted. Without 5b it is
# satisfied by one that checks the stamp EXISTS. Without 5c the both-or-neither
# half of the ruling is assumed rather than asserted.
if (have) {
    # --- 5a. LIVE: a correct stamp still delivers the sentinel -------------
    check(ID, "the live-stamp control published a stamp for the step it drew",
          an("stamp_live.stamp_live_before_stamp"), 1, tol = 0)
    bl <- avv("stamp_live_blockline")
    check_true(ID,
        sprintf("with a live stamp the recorder prefers the published sentinel over the draw's 150 .. 400 (%s / %s)",
                decl_value(bl[1]) %or% "<absent>",
                decl_value(bl[2]) %or% "<absent>"),
        length(bl) == 2 &&
        identical(decl_value(bl[1]), "0.0") &&
        identical(decl_value(bl[2]), "0.0"))
    check_true(ID,
        "and keeps the resolution as a note beside it rather than throwing it away",
        length(bl) == 2 && grepl("resolved to 150\\.0000 \\.\\. 400\\.0000", bl[2]))

    # --- 5b. STALE: existence is not enough --------------------------------
    check(ID, "the stale-stamp control published a stamp naming a step five ahead",
          an("stamp_stale.stamp_stale_before_stamp"), 5, tol = 0)
    check(ID, "and its draw was recorded as step 1",
          an("stamp_stale.stamp_stale_after_recordn"), 1, tol = 0)
    bl <- avv("stamp_stale_blockline")
    check_true(ID,
        sprintf("a stamp that names another step is refused; the draw's 150 .. 400 survives (%s / %s)",
                decl_value(bl[1]) %or% "<absent>",
                decl_value(bl[2]) %or% "<absent>"),
        length(bl) == 2 &&
        identical(suppressWarnings(as.numeric(decl_value(bl[1]))), 150) &&
        identical(suppressWarnings(as.numeric(decl_value(bl[2]))), 400))

    # --- 5c. UNSTAMPED: both or neither, asserted --------------------------
    # Praat cannot unset a variable, so this leg cannot be built by publishing
    # a stamp and taking it away. It is built by never writing one, which is
    # why it is its own process. It is also the state every tree before this
    # ruling was permanently in.
    check_true(ID, "the unstamped control really has no stamp global at all",
        identical(av("pair_unstamped.pair_unstamped_before_stamp_exists"), "0") &&
        identical(av("pair_unstamped.pair_unstamped_after_stamp_exists"), "0") &&
        identical(av("pair_unstamped.pair_unstamped_before_pair_exists"), "1"))
    bl <- avv("pair_unstamped_blockline")
    check_true(ID,
        sprintf("a pair published with no stamp is read as ABSENT; the draw's range survives (%s / %s)",
                decl_value(bl[1]) %or% "<absent>",
                decl_value(bl[2]) %or% "<absent>"),
        length(bl) == 2 &&
        identical(suppressWarnings(as.numeric(decl_value(bl[1]))), 150) &&
        identical(suppressWarnings(as.numeric(decl_value(bl[2]))), 400))

    # --- 5d. THE BASELINE. A Q-Q plot with no form in the process at all.
    # Without this, "the Q-Q step declares the sentinel" has no control: it
    # could be the sentinel because the leak was closed, or because that is
    # what a Q-Q step declares under every condition including the broken one.
    # On a defective tree this leg is GREEN and section 2 is red, which is what
    # localises the defect to the inheritance rather than to the Q-Q path.
    check_true(ID, "with no form in the process, neither global exists at all",
        identical(av("qq_alone.qq_alone_after_stamp_exists"), "0") &&
        identical(av("qq_alone.qq_alone_after_pair_exists"), "0"))
    bl <- avv("qq_alone_blockline")
    check_true(ID,
        sprintf("and a Q-Q plot on its own records the auto sentinel (%s / %s)",
                decl_value(bl[1]) %or% "<absent>",
                decl_value(bl[2]) %or% "<absent>"),
        length(bl) == 2 &&
        identical(decl_value(bl[1]), "0.0") &&
        identical(decl_value(bl[2]), "0.0"))
}

# ===========================================================================
# 6. CONSUMPTION, READ OFF THE VARIABLE ITSELF
# ===========================================================================
# The emitted blocks above say the right ranges were recorded. This section
# says the mechanism that produced them is the one the ruling names, by
# reading the stamp out of the running process before and after each draw. A
# repair that got the right answers some other way -- and left the stamp armed
# -- would pass sections 2 to 5 and fail here, and it would be one more press
# away from the same defect.
if (have) {
    for (lg in c("form_then_qq", "bridge_then_qq")) {
        check(ID, sprintf("%s: the stamp is armed when the pair is published", lg),
              an(sprintf("%s.%s_afterpublish_stamp", lg, lg)), 1, tol = 0)
        check(ID, sprintf("%s: and spent to 0 by the draw that read it", lg),
              an(sprintf("%s.%s_afterdraw_stamp", lg, lg)), 0, tol = 0)
        check(ID, sprintf("%s: and still 0 after the Q-Q draw", lg),
              an(sprintf("%s.%s_afterqq_stamp", lg, lg)), 0, tol = 0)
        # THE PAIR IS STILL THERE, UNCHANGED, WHICH IS THE POINT. Praat cannot
        # unset it, and it is not zeroed either -- 0/0 is the auto sentinel,
        # so a "cleared" pair would be a published AUTO request. The stamp is
        # what went to 0, and it is the only thing that could.
        check_true(ID,
            sprintf("%s: the published pair is still 0 .. 100 afterwards -- it is the STAMP that was spent", lg),
            identical(av(sprintf("%s.%s_afterqq_pair", lg, lg)), "0..100.0000") &&
            identical(av(sprintf("%s.%s_afterqq_pair_exists", lg, lg)), "1"))
    }
    check(ID, "the stale stamp is zeroed too, so it cannot match by arithmetic later",
          an("stamp_stale.stamp_stale_after_stamp"), 0, tol = 0)
}

# ===========================================================================
# 7. THE STAMP TRAVELS WITH ALL THIRTEEN GRAPH TYPES
# ===========================================================================
# The publication is TYPE-DISPATCHED because "the y-axis range" is not one
# variable in the form: a pitch contour is handed freqMin/freqMax, a waveform
# ampMin/ampMax, a spectrum and an LTAS powerMin/powerMax, and everything from
# the line chart down valueMin/valueMax. What is asserted here is BOTH OR
# NEITHER over that chain: after the publication runs, every one of the
# thirteen types has left a pair AND a live stamp behind, so there is no type
# on which the pair can exist unstamped.
#
# WHAT THIS IS NOT. It is not thirteen leak tests. Because the stamp is
# re-taken in @emlGraphsDispatchDraw, a type whose branch somehow published no
# stamp would still be stamped before it drew, and would still record
# correctly -- the section that would go red is this one and only this one.
# Saying so is the point: the check is on the invariant, and the invariant is
# what stops a fourteenth graph type, or a caller that publishes without
# dispatching, from reintroducing an unstamped pair.
#
# The stamp is zeroed by the drive before each type's publication, so what is
# read back was written by THAT branch and not left over from the previous one
# -- Praat cannot unset a variable, so without that the twelfth type would
# cover for the thirteenth.
if (have) {
    want <- c("11..12", "21..22", "31..32", "31..32", rep("41..42", 9))
    for (t in 1:13) {
        got <- av(sprintf("stamp_types.stamp_types_t%d", t))
        check_true(ID,
            sprintf("graph type %d publishes its own pair AND a live stamp (%s)",
                    t, got %or% "<absent>"),
            identical(got, paste0(want[t], "@1")))
    }
    check(ID, "and the recorder really was running, so a live stamp is not zero",
          an("stamp_types.stamp_types_recordn"), 0, tol = 0)
}

# ===========================================================================
# 8. WHAT THIS FILE FOUND AND DOES NOT OWN
# ===========================================================================
attest(ID,
    "a legend-bearing figure still records TWO draw steps, and both are entitled to the request",
    "@emlGraphsDispatchDraw is called once per legend pass, so the stamp is re-taken for each and both steps carry the user's range -- measured in harness/formaxis/out/legend_auto/emitted.praat, whose block still declares one pair reading 0.0 for 'steps 1 (draw), 2 (draw)'. Whether the discarded first pass should record a step at all is a separate ruling; this repair neither creates nor closes it.")
attest(ID,
    "no figure changed anywhere across this repair",
    "the leak is in what gets RECORDED, not in what gets drawn: @emlDrawScatterPlot resolves the Q-Q plot's axis from the data whichever range the recorder later writes down. harness/formaxis re-driven 16 August 2026 before and after -- all four form legs' emitted blocks are identical, and their four PNGs unchanged. No pixel, byte count or file size in this tree can see this defect, which is why none is read here.")

if (!exists("EML_SUITE")) {
    eml_report("v74 the axis publication is consumed once")
    eml_exit()
}
