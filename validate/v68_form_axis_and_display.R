# ============================================================================
# v68_form_axis_and_display.R -- the graphs form's half of Ruling 10(b), and
# the Info window's half of the fixed$ ruling
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. Two author rulings of 16 August 2026 land on the same
# two files, and they fail in opposite ways: one of them silently changes a
# number a user will edit, and the other one silently changes nothing at all
# and still has to be done.
#
#   RULING A (10b, FORM HALF) -- PUBLISH THE UNTOUCHED AXIS REQUEST.
#
#   The author's words: "the record process should note if it was auto and
#   offer 0.0 to 0.0 as the range in the editable top block of variables."
#   Ruling 10(a) had already settled that the recorded CALL carries the
#   user's choice rather than the resolution -- (0, 0) is the sentinel the
#   dialog names on its own face, "both 0 = auto", and not a range.
#
#   The recorder side of that was finished and is validated by v67. It could
#   not be finished, because graphs/eml-graphs-form.praat DESTROYS THE
#   EVIDENCE BEFORE THE RECORDER CAN SEE IT, on two paths, both of which run
#   before the draw that gets recorded:
#
#     the bracket path, which on an annotated bar, violin or box plot with at
#     least one bracket resolves (0, 0) into the data's extent and then widens
#     the ceiling for the brackets, writing both back into valueMin/valueMax;
#
#     the legend path, which draws once, measures the legend, writes the
#     widened extent back into the same two variables and DRAWS AGAIN -- and
#     the second draw is the one the recorder records.
#
#   So the form now publishes the request as two globals,
#   emlGraphsAxisYReqMin and emlGraphsAxisYReqMax, set once where the range
#   validation has just finished with the user's own numbers, and neither pass
#   writes them again. @emlRecordAxisRequest prefers them when BOTH exist and
#   falls back to the draw's own arguments otherwise.
#
#   RULING B -- NO RAW DOUBLE REACHES THE INFO WINDOW, IN ACTIVE PATHS.
#
#   The author's words: "anything in an active process needs fixed". fixed$
#   is not a fixed-precision formatter: it prints
#   max (precision, -floor (log10 |v|)) decimals and returns a bare "0" for
#   exact zero. @eml_fixed in stats/eml-output.praat is the one formatter.
#
# WHAT THE FAILURES LOOK LIKE, because neither of them raises.
#
#   RULING A PRODUCES A CORRECT, RUNNABLE SCRIPT WITH A WRONG NUMBER IN THE
#   ONE PLACE THE USER IS INVITED TO EDIT. Measured at HEAD on 6.6.30, 16
#   August 2026, driving an annotated violin on four cohorts with the y-range
#   left on auto: the dialog held (0, 0), the bracket path resolved it to
#   195.0000 .. 268.9205, and the emitted block declared
#
#       axisYMin  = 195.0000
#       axisYMax  = 268.9205
#
#   Replay that on the same data and it reproduces the figure exactly -- that
#   is ruling 10(a) working, and it is why every replay test in this tree was
#   green over the defect. Point it at a second speaker, which is the entire
#   purpose the block exists for, and the figure is drawn on the FIRST
#   speaker's axis. Nothing errors. The figure looks like a figure.
#
#   RULING B PRODUCES NOTHING AT ALL TODAY, AND SECTION 5 SAYS SO IN THE
#   NUMBERS RATHER THAN GLOSSING OVER IT. The active site in
#   eml-graph-procedures.praat is @emlDrawLegendPanel's ellipsis NOTE, whose
#   two numbers are a panel width in inches at two decimals and a font size in
#   points at one. fixed$ diverges from a true fixed-precision formatter only
#   below 10^-precision, and a legend panel narrower than 0.052 in does not
#   reach that sentence at all -- swept, and recorded here as a measurement.
#   The change is therefore a UNIFORMITY change: it closes an escape hatch on
#   an active path so that no later edit to the sentence can introduce a
#   magnitude where fixed$ lies. A validator that pretended otherwise would be
#   inventing a failure, so this one asserts the formatter at the site, the
#   byte-identity of the notes, and the measured size of the domain.
#
# WHAT COULD NOT HAVE CAUGHT RULING A, AND WHY.
#
#   - THE RECORDER'S OWN TESTS, v67 AND harness/axisspec. They are the other
#     half of the same contract and they are thorough: the (0, 0) sentinel,
#     the pair rule, the fallback, the block promise, an edited block re-run.
#     Every one of them is green over this defect, and the reason is
#     structural rather than an oversight -- harness/axisspec cannot run the
#     form, says so in its own header, and publishes the two globals BY HAND
#     to test its own side. On every path it can drive, the argument IS the
#     request, so the fallback and the publication agree and nothing can
#     disagree with anything.
#
#   - harness/record/roundtrip_graph.sh, WHICH IS THE STRONGEST REPLAY
#     EVIDENCE IN THE TREE. It records a violin, emits the script, runs it in
#     a fresh process and compares the PNGs byte for byte. It calls
#     @emlDrawViolinPlot directly -- no form, no globals, the fallback fires --
#     so it is byte-perfect across this change and was byte-perfect over the
#     defect. A round trip proves an emitted script reproduces the figure it
#     came from; it says nothing about whether the numbers in it are the
#     user's.
#
#   - ANY PNG COMPARISON, of any figure, at any tolerance. The resolved range
#     is what the figure was legitimately drawn on. Both trees draw the same
#     picture, and that is not a coincidence to be tightened away: it is the
#     defect's defining property.
#
#   - A CHECK ON THE WIDTH OR THE FORMAT OF THE BLOCK'S NUMBERS, which is the
#     shape this defect invites. "0.0" and "195.0000" are both well-formed
#     fixed strings; so is the zero a fix-shaped fix would produce by clamping
#     every published number to a zero of the right width, and that fix would
#     satisfy every format assertion anybody would think to write while
#     throwing away the range of every user who typed one. Sections 3 and 4
#     therefore assert the VALUE in both directions -- 0.0 where the user
#     chose auto, 150 and 400 where the user typed them, on the same two paths
#     in the same run.
#
#   - A GOLDEN-FILE DIFF. harness/record/graph_out/emitted.praat was already
#     in the repository carrying a violin recorded with (0, 0), because that
#     leg has no form in it. A diff says "this changed"; it cannot say "this
#     was always wrong".
#
#   - AND A PROBE THAT TRANSCRIBES THE FORM'S SEQUENCE, which is the trap this
#     file's harness is built to avoid and which this repository has already
#     paid for once. harness/disclosure/probe_formpath.praat called itself a
#     reproduction of the form's annotation stage, transcribed it by hand, and
#     passed emlDrawViolinPlot.axisYMin where the form passed valueMin -- so it
#     tested a CORRECTED copy of the block and would have gone on passing
#     however wrong the shipped one became. It did, while an omnibus box was
#     clipped off the figure entirely. The bracket path is one of the two
#     sites that destroys the request, so any check of ruling A has to run it;
#     a hand-written copy of those ninety lines would be measuring itself. It
#     is now @emlGraphsPreDispatchHeadroom, a file-scope procedure lifted out
#     verbatim, and harness/formaxis calls the shipped one.
#
# THE FOUR TRAPS THAT COST SIBLINGS A REVISION THIS WEEK, and where each is
# answered here.
#
#   A CHECK THAT COULD ONLY PASS. Every assertion below is anchored to a
#   number observed on BOTH trees: the block reading 195.0000 and the block
#   reading 0.0; the published pair at 150/400 while the draw ran to 612.0032;
#   the two globals absent on the no-form leg and present on every form leg;
#   the ellipsis note identical on both sides. break.sh drives nineteen
#   deliberate defects; which checks that reds, and which it no longer reds
#   now that the repairs are committed, is accounted for below rather than
#   summarised.
#
#   A CHECK THAT MATCHED THE COMMENT RATHER THAN THE FIX. Both the harness and
#   this file strip whole-line Praat comments before matching anything, and
#   they have to: the house style puts a long paragraph above every repair and
#   those paragraphs name every procedure being checked for. break.sh's
#   `prose_only` shadow reverts the code and leaves the paragraph, and the
#   static section goes red on it.
#
#   A SIZE THRESHOLD. There is none here. Nothing in this file asks how big a
#   file or a figure is; the two record legs are read for the VALUE of their
#   axis declarations, out of the block a user would edit, delimited at the
#   first blank line so a later step's code cannot be mistaken for one.
#
#   AN ANCHOR THAT MOVES THE WRONG WAY. No pixel geometry is read here at all.
#
# WHAT WAS BROKEN, AND WHAT WENT RED. harness/formaxis/break.sh builds nineteen
# shadow copies of the repository, one deliberate defect each, drives the rig
# in each and runs this file against it. Every one went red, and the count is
# the interesting part -- a break that reds one check is as much a result as a
# break that reds sixty, because it says which check is carrying it:
#
# The counts below are the 16 AUGUST 2026 RE-RUN of all nineteen, against 99
# checks. out/BREAKS.tsv IS THE RECORD; the out/break_<name>.v68.log
# transcripts beside it are working files and are gitignored, because
# formaxis.sh opens with `rm -f "$OUT"/*.log` -- so the next ordinary drive of
# the rig deletes them, and a re-run of break.sh puts them back. Both runs on
# 16 August produced this table to the number:
#
#   head_form            6   the form reverted to HEAD -- the defect itself
#   head_graph           4   the graphs file reverted to HEAD
#   prose_only           4   the fixed$ site restored, the paragraph left
#   clamp_zero          24   the fix-shaped fix: both numbers clamped to 0
#   partial_min         33   the minimum published and not the maximum
#   pub_goto            37   a goto at the top of the publication
#   publish_late         1   published after the pass that resolves the axis
#   republish           10   republished inside the bracket pass
#   republish_legend    11   republished inside the legend pass
#   publish_at_load      4   published at file scope, so it escapes the form
#   wrong_pair           2   the waveform publishes valueMin, not ampMin
#   headroom_stub        5   the bracket pass emptied, sequence still runs
#   precision_one        2   @eml_fixed at the right site, wrong precision
#   form_fixed_back      1   one of the form's Info sites back on fixed$
#   second_formatter     6   a duplicate eml_fixed local to the graphs file
#   emlfixed_neutered    4   @eml_fixed reduced to a fixed$ pass-through
#   plausibility_readded 4   the retired procedure pasted back at its tombstone
#   legendroom_stub      3   the legend pass stops widening the axis
#   legendroom_twice     1   a second call site under the ordering check
#
# 75 of the 99 went red in that run. The table above USED TO READ head_form 64
# and the accounting used to read 89 of 98, and the drop is worth naming
# because it looks like a regression and is not one: THE REPAIRS THIS FILE
# CHECKS ARE NOW IN HEAD (@emlGraphsPublishAxisRequest is in HEAD's
# eml-graphs-form.praat, which writes emlGraphsAxisYReqMin at all five sites;
# HEAD's eml-graph-procedures.praat already routes the ellipsis note through
# @eml_fixed twice). `revert to HEAD` therefore no longer removes them -- it
# removes only what is still uncommitted -- so head_form, head_graph and
# prose_only are weak shadows now and will stay weak. Their strong run is the
# recorded one; a future revision that wants that reach back has to shadow the
# repair itself, the way partial_min and pub_goto do, not the commit.
#
# WHAT THE 24 ARE. Fourteen of them are structural checks that only the
# pre-commit head_form ever reached -- the publication exists, is called once,
# is called before the legend pass, the emitted block declares two axes and
# the draw step reads them. The other ten are the ones no source defect can
# reach at all, and they are named rather than glossed over, because a check
# nobody can break is a check nobody should trust without knowing why:
#
#   THREE ARE RIG GUARDS -- the files exist, the drive produced evidence, the
#   binary is at or above 6.6.30. Their red side is a broken harness, which is
#   what they are for; there is no source defect that reaches them.
#
#   SIX ARE FIXTURE GUARDS -- the auto leg's dialog held 0 and its bridge
#   produced brackets, the legend leg drew twice, the typed leg's floor was
#   150, the narrow panel measured 0.052 in and did clamp. They assert that
#   the drive set up what it claims to have set up, so that the value checks
#   beside them are about the plugin and not about the fixture.
#
#   ONE IS A POSITIVE CONTROL. "at the magnitudes this note actually prints,
#   they agree" cannot go red under a formatter break precisely because it is
#   the row that says nothing moved.
#
# The second positive control this list used to carry is gone with its
# subject: @emlCheckPlausibility's three fixed$ calls were PINNED at three
# while the dead body existed, and on 16 August 2026 the author retired the
# body. §5a-bis says what replaced that pin and why the replacement is not
# also unbreakable -- plausibility_readded is the break that reds it.
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

ID <- "v68"

# ---------------------------------------------------------------------------
# WHERE THE SOURCE AND THE EVIDENCE COME FROM.
#
# Three env overrides, because a break test must be able to point this file at
# a DIFFERENT COPY of the tree without touching the working one. A break test
# that edits the repository and puts it back is one interrupted run away from
# committing a defect.
# ---------------------------------------------------------------------------
gdir <- Sys.getenv("EML_FA_GRAPH_SRC", unset = "")
if (!nzchar(gdir)) gdir <- repo_path(file.path("plugin", "graphs"))
sdir <- Sys.getenv("EML_FA_STATS_SRC", unset = "")
if (!nzchar(sdir)) sdir <- repo_path(file.path("plugin", "stats"))
fdir <- Sys.getenv("EML_FA_DIR", unset = "")
if (!nzchar(fdir)) fdir <- repo_path(file.path("harness", "formaxis", "out"))

f_form  <- file.path(gdir, "eml-graphs-form.praat")
f_graph <- file.path(gdir, "eml-graph-procedures.praat")
f_out   <- file.path(sdir, "eml-output.praat")

check_true(ID, "the two owned files and the shared formatter are present",
           all(file.exists(c(f_form, f_graph, f_out))))

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS, AND STRIP WHOLE-LINE COMMENTS BEFORE MATCHING.
#
# Both halves have bitten this repository. Calls in these files are written
# across two and three physical lines with "...", so a line-at-a-time regex
# sees a procedure name with no arguments and an argument list with no
# procedure. And every repair here carries a paragraph above it that names the
# procedures involved, so an unstripped grep finds @emlGraphsPublishAxisRequest
# in the prose explaining it and calls the wiring present after every call site
# has been deleted.
#
# Praat whole-line comment forms are `#`, `;` and `!`. A trailing `; ...` on a
# code line is left alone: stripping it would need to know about string
# literals, and every pattern below is anchored at the start of a statement.
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

code_form  <- read_code(f_form)
code_graph <- read_code(f_graph)
code_out   <- read_code(f_out)

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

# The harness TSV, scoped by leg. Keys repeat across legs on purpose -- five
# record legs each publish `_blockline` twice -- so a flat map would answer
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

# decl_value -- the VALUE out of one declaration line of the emitted block.
#
# The block writes `axisYMin  = 0.0   ; the y-axis range -- AUTO ...`, and the
# trailing gloss is prose that repeats the number in words. Splitting on the
# first `;` and taking what is left of it is what keeps this a check on the
# DECLARATION rather than on the sentence beside it -- a renderer that wrote
# `axisYMin = 195.0000  ; ... AUTO ...` would otherwise satisfy a grep for
# "AUTO" and for "0.0" at once.
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

fa   <- read_legged_tsv(file.path(fdir, "FORMAXIS.tsv"))
have <- length(fa) > 0
av   <- function(k) if (is.null(fa[[k]])) NA_character_ else fa[[k]][1]
an   <- function(k) suppressWarnings(as.numeric(av(k)))
avv  <- function(k) if (is.null(fa[[k]])) character(0) else fa[[k]]

check_true(ID, "the form-axis drive produced evidence (harness/formaxis/formaxis.sh)",
           have)
if (have) {
    pv <- av("praat_version")
    check_true(ID, sprintf("and it ran on the supported binary (%s)", pv),
               !is.na(pv) && grepl("^Praat 6\\.6\\.3[0-9]|^Praat [7-9]", pv))
}

# ===========================================================================
# 1. RULING A -- THE CODE
# ===========================================================================

# ---------------------------------------------------------------------------
# 1a. THE PUBLICATION IS ONE PROCEDURE WITH ONE CALL SITE.
#
# Both-or-neither is the contract @emlRecordAxisRequest reads by: it requires
# variableExists on BOTH names before it prefers either, so a path that
# published a minimum and not a maximum would hand the recorder a floor from
# the dialog and a ceiling from the resolved draw -- a range nobody asked for,
# and one the (0, 0) sentinel cannot survive. Publishing from the ten places
# the dialog values are read would make that an invariant to audit rather than
# one to read, so the shape is asserted here and not only the behaviour.
# ---------------------------------------------------------------------------
pub <- proc_body_of(code_form, "emlGraphsPublishAxisRequest")
check_true(ID, "@emlGraphsPublishAxisRequest exists and was found",
           length(pub) > 0)
check(ID, "it is called from exactly one place in the form",
      cnt(code_form, "@emlGraphsPublishAxisRequest"), 1, tol = 0)
# Every write to either global is inside that procedure: the counts over the
# whole file and over the procedure body agree.
check(ID, "every write to emlGraphsAxisYReqMin is inside it",
      cnt(code_form, "^emlGraphsAxisYReqMin ="), cnt(pub, "^emlGraphsAxisYReqMin ="),
      tol = 0)
check(ID, "every write to emlGraphsAxisYReqMax is inside it",
      cnt(code_form, "^emlGraphsAxisYReqMax ="), cnt(pub, "^emlGraphsAxisYReqMax ="),
      tol = 0)
# Four branches, four pairs, both names written on every one. A branch that
# set only the minimum is the partial publication the contract forbids, and it
# would still leave the file with a plausible-looking procedure.
check(ID, "four branches write the minimum",
      cnt(pub, "^emlGraphsAxisYReqMin ="), 4, tol = 0)
check(ID, "and the same four write the maximum",
      cnt(pub, "^emlGraphsAxisYReqMax ="), 4, tol = 0)
check_true(ID, "the procedure has no goto and no early exit that could skip one",
           !has(pub, "^goto ") && !has(pub, "^exitScript"))
# THE MAP ITSELF, read out of the source rather than inferred from the drive,
# because the drive can only show that some map was applied.
check_true(ID,
    "the map reads the pair each graph type's draw is actually given",
    has(pub, "^if graph_type = 1$") &&
    has(pub, "^emlGraphsAxisYReqMin = freqMin$") &&
    has(pub, "^elsif graph_type = 2$") &&
    has(pub, "^emlGraphsAxisYReqMin = ampMin$") &&
    has(pub, "^elsif graph_type = 3 or graph_type = 4$") &&
    has(pub, "^emlGraphsAxisYReqMin = powerMin$") &&
    has(pub, "^else$") &&
    has(pub, "^emlGraphsAxisYReqMin = valueMin$"))

# ---------------------------------------------------------------------------
# 1b. THE ORDER. The publication must precede BOTH conversion sites.
#
# Taken from line numbers in the comment-stripped file, because both call
# sites are unique names and a publication placed after either pass would
# publish the answer. This is the one thing a values-only check cannot see:
# on the auto legs a publication taken after the headroom would still read
# (0, 0) on a type the headroom does not touch, and the check would pass.
# ---------------------------------------------------------------------------
if (have) {
    # The three line numbers are the LAST match for each name, so each name has
    # to have exactly one call site for that to be the call site rather than
    # the last of several. Asserted before the order is read off them.
    check(ID, "the bracket-headroom pass has exactly one call site",
          an("code_headroom_calls"), 1, tol = 0)
    check(ID, "the legend-room pass has exactly one call site",
          an("code_legendroom_calls"), 1, tol = 0)
    lp <- an("line_publish_call")
    lh <- an("line_headroom_call")
    ll <- an("line_legendroom_call")
    check_true(ID, "the publication is written before the bracket-headroom pass",
               is.finite(lp) && is.finite(lh) && lp < lh)
    check_true(ID, "and before the legend-room pass",
               is.finite(lp) && is.finite(ll) && lp < ll)
}

# ---------------------------------------------------------------------------
# 1c. NEITHER PASS WRITES THE GLOBALS, read out of the two pass bodies.
# ---------------------------------------------------------------------------
head_body <- proc_body_of(code_form, "emlGraphsPreDispatchHeadroom")
leg_body  <- proc_body_of(code_form, "emlGraphsDrawWithLegendRoom")
check_true(ID, "the bracket-headroom pass is a procedure that can be driven",
           length(head_body) > 0)
check_true(ID, "and it still resolves auto into the data's extent",
           has(head_body, "^if valueMin = 0 and valueMax = 0$") &&
           has(head_body, "^valueMin = emlComputeAxisRange.axisMin$") &&
           has(head_body, "valueMax = valueMax \\+ emlComputeAnnotationHeadroom.headroom"))
check(ID, "the bracket-headroom pass writes neither published global",
      cnt(head_body, "emlGraphsAxisYReq"), 0, tol = 0)
check_true(ID, "the legend-room pass still writes the widened axis back",
           has(leg_body, "^valueMin = emlLegendHeadroomAfterDraw.yMin$") &&
           has(leg_body, "^valueMax = emlLegendHeadroomAfterDraw.yMax$"))
check(ID, "the legend-room pass writes neither published global",
      cnt(leg_body, "emlGraphsAxisYReq"), 0, tol = 0)

# ===========================================================================
# 2. RULING A -- THE PUBLICATION SURVIVES BOTH PASSES, DRIVEN
# ===========================================================================
# Four legs, and the two typed ones are what make this a test rather than an
# illustration. A "fix" that clamped every published number to 0.0 passes
# every auto leg and every format check in the file; it cannot pass a typed
# leg, because the typed leg asks what the user's own range came out as.
if (have) {
    # --- the bracket path, auto ---------------------------------------------
    check(ID, "bracket path, auto: the dialog held 0",
          an("bracket_auto.bracket_auto_dialog_min"), 0, tol = 0)
    check_true(ID, "bracket path, auto: the bridge produced brackets, so the resolver runs",
               an("bracket_auto.bracket_auto_brackets") > 0)
    check(ID, "bracket path, auto: the pass resolved the axis to 195.0000",
          an("bracket_auto.bracket_auto_resolved_min"), 195, tol = 1e-4)
    check(ID, "bracket path, auto: and widened the ceiling to 268.9205",
          an("bracket_auto.bracket_auto_resolved_max"), 268.9205, tol = 1e-4)
    check(ID, "bracket path, auto: the published minimum is still 0 after it",
          an("bracket_auto.bracket_auto_afterheadroom_pub_min"), 0, tol = 0)
    check(ID, "bracket path, auto: the published maximum is still 0 after it",
          an("bracket_auto.bracket_auto_afterheadroom_pub_max"), 0, tol = 0)
    check(ID, "bracket path, auto: and still 0 after the annotation stage",
          an("bracket_auto.bracket_auto_afterannot_pub_max"), 0, tol = 0)
    check(ID, "bracket path, auto: the figure was drawn on the resolved ceiling",
          an("bracket_auto.bracket_auto_axis_max"), 268.9205, tol = 1e-4)

    # --- the bracket path, typed --------------------------------------------
    check(ID, "bracket path, typed: the user typed a floor of 150",
          an("bracket_typed.bracket_typed_dialog_min"), 150, tol = 0)
    check(ID, "bracket path, typed: the pass widened the ceiling to 612.0032",
          an("bracket_typed.bracket_typed_resolved_max"), 612.0032, tol = 1e-4)
    check(ID, "bracket path, typed: the published floor is the typed 150, not 0",
          an("bracket_typed.bracket_typed_afterheadroom_pub_min"), 150, tol = 0)
    check(ID, "bracket path, typed: the published ceiling is the typed 400, not 612",
          an("bracket_typed.bracket_typed_afterheadroom_pub_max"), 400, tol = 0)

    # --- the legend path, auto ----------------------------------------------
    check(ID, "legend path, auto: the figure was drawn twice",
          an("legend_auto.legend_auto_passes"), 2, tol = 0)
    check(ID, "legend path, auto: the pass widened the ceiling to 275.0000",
          an("legend_auto.legend_auto_resolved_max"), 275, tol = 1e-4)
    check(ID, "legend path, auto: the published minimum is still 0 after it",
          an("legend_auto.legend_auto_afterlegend_pub_min"), 0, tol = 0)
    check(ID, "legend path, auto: the published maximum is still 0 after it",
          an("legend_auto.legend_auto_afterlegend_pub_max"), 0, tol = 0)

    # --- the legend path, typed ---------------------------------------------
    # The legend takes room BELOW here, so the typed floor of 100 becomes -100
    # in the draw. Same defect, opposite direction, and a check anchored only
    # on the ceiling would miss it.
    check(ID, "legend path, typed: the pass dropped the floor to -100.0000",
          an("legend_typed.legend_typed_resolved_min"), -100, tol = 1e-4)
    check(ID, "legend path, typed: the published floor is the typed 100, not -100",
          an("legend_typed.legend_typed_afterlegend_pub_min"), 100, tol = 0)
    check(ID, "legend path, typed: the published ceiling is the typed 300",
          an("legend_typed.legend_typed_afterlegend_pub_max"), 300, tol = 0)

    # --- both or neither, on every form leg ---------------------------------
    for (lg in c("bracket_auto", "bracket_typed", "legend_auto", "legend_typed")) {
        st <- if (lg %in% c("bracket_auto", "bracket_typed")) "afterheadroom"
              else "afterlegend"
        check_true(ID, sprintf("%s: both globals exist, never one of them", lg),
                   identical(av(sprintf("%s.%s_%s_pub_hasmin", lg, lg, st)), "1") &&
                   identical(av(sprintf("%s.%s_%s_pub_hasmax", lg, lg, st)), "1"))
    }

    # --- the type-to-pair map, driven ---------------------------------------
    # Every dialog pair is set to a different recognisable value, so a
    # publication that read the wrong pair cannot coincide with the right
    # answer. freq 11..12, amp 21..22, power 31..32, value 41..42.
    want_pairs <- c("11..12", "21..22", "31..32", "31..32",
                    rep("41..42", 9))
    for (t in 1:13) {
        check_true(ID,
            sprintf("graph type %d publishes the pair its draw is given (%s)",
                    t, want_pairs[t]),
            identical(av(sprintf("pairs.pairs_t%d", t)), want_pairs[t]))
    }
}

# ===========================================================================
# 3. RULING A -- WHAT THE EMITTED BLOCK SAYS
# ===========================================================================
# Read out of the file a user would run, out of the block a user would edit,
# delimited at the first blank line after its own heading so a later step's
# code can never be mistaken for a declaration. This is the assertion the
# ruling is actually about.
if (have) {
    for (lg in c("bracket_auto", "legend_auto")) {
        bl <- avv(sprintf("%s_blockline", lg))
        check(ID, sprintf("%s: the block declares two axis variables", lg),
              length(bl), 2, tol = 0)
        check_true(ID,
            sprintf("%s: the declaration is named axisYMin / axisYMax", lg),
            length(bl) >= 2 &&
            identical(decl_name(bl[1]), "axisYMin") &&
            identical(decl_name(bl[2]), "axisYMax"))
        check_true(ID,
            sprintf("%s: the recorded minimum is the auto sentinel 0.0, not the resolution", lg),
            length(bl) >= 1 && identical(decl_value(bl[1]), "0.0"))
        check_true(ID,
            sprintf("%s: the recorded maximum is the auto sentinel 0.0", lg),
            length(bl) >= 2 && identical(decl_value(bl[2]), "0.0"))
        check_true(ID,
            sprintf("%s: and the block says so in words -- AUTO, both 0", lg),
            identical(av(sprintf("%s_auto_marked", lg)), "1"))
        # RULING 10(b)'s SECOND HALF: the resolution is kept as a note beside
        # the sentinel rather than thrown away, so the reader knows what it
        # came out as on the recorded data.
        rn <- av(sprintf("%s_resolved_note", lg))
        check_true(ID,
            sprintf("%s: the resolved range is kept as a note beside it", lg),
            !is.na(rn) && grepl("resolved to [0-9]", rn))
        # And the step below reads the block rather than a literal of its own,
        # which is what makes the declaration load-bearing instead of
        # decorative -- the half-done lift that passes every static check.
        call_key <- if (lg == "bracket_auto") "violin_call" else "gviolin_call"
        check_true(ID,
            sprintf("%s: the draw step reads the block, not its own literals", lg),
            identical(av(sprintf("%s_%s", lg, call_key)), "axisYMin, axisYMax"))
    }

    # THE VALUE CHECK, and the reason a format check is not enough. A typed
    # range must come out as the typed numbers -- not as 0.0, which is what a
    # publication clamped to the sentinel would produce, and not as the
    # widened ceiling, which is what no publication at all produces.
    typed <- list(bracket_typed = c("150", "400"),
                  legend_typed  = c("100", "300"))
    for (lg in names(typed)) {
        bl <- avv(sprintf("%s_blockline", lg))
        check_true(ID, sprintf("%s: the block carries the typed floor %s",
                               lg, typed[[lg]][1]),
                   length(bl) >= 1 && identical(decl_value(bl[1]), typed[[lg]][1]))
        check_true(ID, sprintf("%s: the block carries the typed ceiling %s, not the widened one",
                               lg, typed[[lg]][2]),
                   length(bl) >= 2 && identical(decl_value(bl[2]), typed[[lg]][2]))
        check_true(ID, sprintf("%s: and it is NOT marked auto", lg),
                   identical(av(sprintf("%s_auto_marked", lg)), "0"))
    }
}

# ===========================================================================
# 4. RULING A -- THE FALLBACK, WHICH IS HALF THE CONTRACT
# ===========================================================================
# No form ran. The form FILE is included and every one of its procedures is
# defined, so this is not a test of whether the file was loaded -- it is a
# test of whether the globals exist, which is the only thing
# @emlRecordAxisRequest looks at. The API export, the batch module, the Q-Q
# path in graphs/eml-draw-qq.praat and every harness in this tree reach the
# recorder exactly like this, and for all of them the argument IS the request.
if (have) {
    check_true(ID, "no form: neither global exists before the draw",
               identical(av("noform.noform_before_pub_hasmin"), "0") &&
               identical(av("noform.noform_before_pub_hasmax"), "0"))
    check_true(ID, "no form: and none is invented by the draw itself",
               identical(av("noform.noform_after_pub_hasmin"), "0") &&
               identical(av("noform.noform_after_pub_hasmax"), "0"))
    bl <- avv("noform_blockline")
    check_true(ID, "no form: the block carries the caller's own 150",
               length(bl) >= 1 && identical(decl_value(bl[1]), "150"))
    check_true(ID, "no form: and the caller's own 400, not 0",
               length(bl) >= 2 && identical(decl_value(bl[2]), "400"))
    check_true(ID, "no form: it is not marked auto",
               identical(av("noform_auto_marked"), "0"))
}

# ===========================================================================
# 5. RULING B -- WHICH SITES ARE ACTIVE, AND WHAT CHANGED AT THEM
# ===========================================================================

# ---------------------------------------------------------------------------
# 5a. CLASSIFICATION BY DESTINATION, NOT BY PROCEDURE NAME.
#
# eml-graph-procedures.praat carries fixed$ on fifteen code lines and exactly
# ONE of them addresses the Info window. It was eighteen and two until 16
# August 2026; §5a-bis below is the three that went and why. The rest are a
# different surface entirely and the ruling does not reach them:
#
#   COLOUR SPECIFICATIONS. "{" + fixed$ (r, 2) + ", " ... -- the greyscale
#   ramp in @emlSetColorPalette and the blend in the lighten helper. These are
#   arguments to Praat's own `Colour:`, not text, and re-rounding them would
#   move rendered pixels. Left alone deliberately.
#
#   AXIS TICK LABELS. `One mark left/right/bottom: ..., fixed$ (pos, dec)` --
#   drawn onto the picture, which the author's ruling excludes, and
#   @emlTickLabelWidth's two, which build the same string only to hand it to
#   `Text width (mm)`. Changing either would move a measurement and therefore
#   a layout, which is not a printed format.
#
#   THE INFO WINDOW. @emlDrawLegendPanel's ellipsis NOTE, and nothing else:
#   active, because every draw with a legend reaches it through @emlDrawLegend,
#   and EML Graphs... is registered on Objects > New and on seven action lists.
#
# eml-graphs-form.praat has none left: its two Info-window sites went through
# @eml_fixed in the 15 August sweep, and the count below is the guard that
# says so rather than the paragraph that claims it.
# ---------------------------------------------------------------------------
if (have) {
    check(ID, "the form reaches the Info window through fixed$ nowhere",
          an("code_form_fixed"), 0, tol = 0)
    check(ID, "eml-graph-procedures.praat still carries 15 fixed$ code lines",
          an("code_graph_fixed"), 15, tol = 0)
    check(ID, "the active ellipsis NOTE calls fixed$ zero times",
          an("code_clamp_fixed"), 0, tol = 0)
    check(ID, "and formats both of its numbers through @eml_fixed",
          an("code_clamp_emlfixed"), 2, tol = 0)
}

# ---------------------------------------------------------------------------
# 5a-bis. THE THREE fixed$ CALLS THAT LEFT, AND THE PIN THAT DID NOT.
#
# Until 16 August 2026 the second Info-window site was @emlCheckPlausibility,
# and this file pinned it in the only honest place: on the CALLER COUNT. It
# was out of the ruling's scope because it had none -- a body with three raw
# fixed$ calls that no line of the plugin could reach -- so the pin said "the
# moment anything calls this, its three fixed$ calls are on an active path and
# the ruling reaches them", and break.sh's `plausibility_wired` shadow drove
# exactly that.
#
# THE AUTHOR RETIRED THE PROCEDURE INSTEAD OF WIRING IT (16 August 2026, and a
# tombstone stands where the body was). That deletion RETIRES THE OLD PIN TOO,
# and this is the part worth saying out loud: "no caller" is trivially true of
# a procedure that does not exist, so leaving the old check here would have
# left a line that reads like a guard and can no longer fail for any reason
# anyone cares about. A pin that dies with the thing it guarded is not a pin.
#
# SO THE PIN IS TURNED AROUND ONTO THE RE-INTRODUCTION. What the deletion
# actually risks is somebody finding the body in git history, reading it as a
# feature that went missing, and pasting it back -- with its three raw fixed$
# calls, which the 15 August ruling forbids on any active path. Both checks
# below go red on that tree, and break.sh's `plausibility_readded` shadow is
# that tree exactly: the v3.31 body restored verbatim at the tombstone, no
# caller added, nothing else touched.
#
# TWO CHECKS, TWO REACHES, AND NEITHER SUBSUMES THE OTHER.
#
#   THE LIVE SOURCE, read straight off eml-graph-procedures.praat by this
#   file, with comments already stripped by read_code -- so the tombstone that
#   explains the retirement cannot answer a grep for the retirement. It is
#   OUTSIDE the `have` gate on purpose: the absence of a procedure is a fact
#   about the tree, not about whether the Praat rig ran, and this check is the
#   one that still speaks when the harness has not.
#
#   THE HARNESS COUNTS, read across the WHOLE plugin rather than this one
#   file, which is the reach this file cannot get on its own: code_..._defs
#   is `procedure emlCheckPlausibility` declarations anywhere under plugin/,
#   and code_..._callers is non-comment mentions of the name anywhere under
#   plugin/. A re-introduction into some other graphs file is invisible to the
#   check above and red here.
# ---------------------------------------------------------------------------
check_true(ID, "@emlCheckPlausibility is gone from eml-graph-procedures.praat (retired 16 Aug 2026, zero callers)",
           cnt(code_graph, "^procedure emlCheckPlausibility(:|$)") == 0)
if (have) {
    check(ID, "no file in the plugin declares it either",
          an("code_plausibility_defs"), 0, tol = 0)
    check(ID, "and its name appears on no code line in the plugin, call or otherwise",
          an("code_plausibility_callers"), 0, tol = 0)
}
# The formatter is the shared one, and there is not a second copy in either
# owned file. A local re-implementation would satisfy every check above.
check_true(ID, "@eml_fixed is defined once, in stats/eml-output.praat",
           cnt(code_out, "^procedure eml_fixed:") == 1 &&
           cnt(code_form, "^procedure eml_fixed:") == 0 &&
           cnt(code_graph, "^procedure eml_fixed:") == 0)
# HOISTED, because Praat cannot nest a procedure call in an expression. A
# repair that wrote `@eml_fixed` inside the appendInfoLine would not parse; one
# that read eml_fixed.result$ twice after two calls would print the second
# value twice. Both temporaries are read, in order.
clamp_lines <- code_graph[grep("does not fit a ", code_graph)]
check_true(ID, "the note's two numbers come from two separate temporaries",
           length(clamp_lines) == 1 &&
           grepl("\\.panelStr\\$", clamp_lines[1]) &&
           grepl("\\.fontStr\\$", clamp_lines[1]))

# ---------------------------------------------------------------------------
# 5b. WHAT THE CHANGE DID TO THE PRINTED NUMBERS, WHICH IS NOTHING.
#
# The two notes are asserted verbatim, at the widest panel this sentence is
# printed on and at the NARROWEST one it can be printed on at all. The lower
# bound is the honest measurement of the ruling's domain: below 0.052 in,
# @emlMeasureLegendPanel reports capacity 0 and prints nothing, so no input
# reaches the region where fixed$ and @eml_fixed disagree. Asserting the exact
# strings is what turns a precision change into a red line -- @eml_fixed at
# one decimal instead of two prints "0.1 inch panel" and "4.0 inch panel", and
# break.sh drives exactly that.
# ---------------------------------------------------------------------------
NOTE_TAIL <- paste0(" pt. Widen the figure, shorten the labels, or set Legend",
                    " placement to Right of plot or Separate figure.")
if (have) {
    check_true(ID, "the ellipsis note at the 6 x 4 panel is unchanged, to the digit",
        identical(av("clamp_real_note"),
                  paste0("NOTE: legend labels were shortened with an ellipsis",
                         " — the widest one does not fit a 4.04 inch panel",
                         " at 8.3 pt.",
                         " Widen the figure, shorten the labels, or set Legend",
                         " placement to Right of plot or Separate figure.")))
    check_true(ID, "and at the narrowest panel that can print it at all",
        identical(av("clamp_min_note"),
                  paste0("NOTE: legend labels were shortened with an ellipsis",
                         " — the widest one does not fit a 0.05 inch panel",
                         " at 8.0 pt.",
                         " Widen the figure, shorten the labels, or set Legend",
                         " placement to Right of plot or Separate figure.")))
    check(ID, "the narrowest clamping panel measured 0.052 in",
          an("clamp_min.clamp_min_panelw"), 0.052, tol = 1e-6)
    check_true(ID, "and it did clamp, so the note is a real one",
               identical(av("clamp_min.clamp_min_clamped"), "1") &&
               identical(av("clamp_real.clamp_real_clamped"), "1"))
}

# ---------------------------------------------------------------------------
# 5c. WHERE THE TWO FORMATTERS DO PART COMPANY.
#
# A measurement of Praat's built-in, kept beside the ruling so the claim in
# @emlDrawLegendPanel's comment is a recorded fact. Each row is
# value|fixed$(value,d)|@eml_fixed(value,d). The rows are the argument for the
# ruling and the reason the domain measurement above is not an excuse: the
# moment this sentence prints a number below 0.01, fixed$ starts lying.
# ---------------------------------------------------------------------------
if (have) {
    fmt <- function(k) av(paste0("formatter.", k))
    check_true(ID, "fixed$ returns a bare \"0\" for exact zero; @eml_fixed returns 0.00",
               identical(fmt("fmt2_1"), "0|0|0.00"))
    check_true(ID, "fixed$ escalates 0.004 to three decimals; @eml_fixed holds two",
               identical(fmt("fmt2_2"), "0.004000|0.004|0.00"))
    check_true(ID, "and 0.001 to three; @eml_fixed holds two",
               identical(fmt("fmt2_3"), "0.001000|0.001|0.00"))
    check_true(ID, "a negative zero prints as 0.00, never as -0.00",
               identical(fmt("fmt2_8"), "-0.0000000001|-0.0000000001|0.00"))
    check_true(ID, "and at the magnitudes this note actually prints, they agree",
               identical(fmt("fmt2_6"), "4.042600|4.04|4.04") &&
               identical(fmt("fmt1_7"), "8.300000|8.3|8.3"))
}

# ===========================================================================
# 6. WHAT MOVED, AND WHAT DID NOT
# ===========================================================================
attest(ID,
    "harness/record/roundtrip_graph.sh: leg1.png, leg2.png and the mirror are byte-identical across this change",
    "driven 16 August 2026 in two shadow trees differing only in these two files -- the current tree, and the same tree with both reverted to HEAD. The emitted script differs on eleven lines, all of them the shadow's own include root, and on nothing else. That rig calls @emlDrawViolinPlot directly, so no form runs, neither global exists and the fallback fires.")
attest(ID,
    "harness/legend: all 229 PNGs and 220 of 225 logs are byte-identical across this change",
    "same two-shadow method, 16 August 2026. The five that differ are sw_t13_p1..p5, and the whole of each difference is the wall-clock stamp the case prints; the six *_wide logs that carry the ellipsis note are identical to the byte. RESULTS.tsv is identical.")
attest(ID,
    "@emlGraphsPreDispatchHeadroom is a verbatim lift out of @emlGraphsWorkflow",
    "the section had its own banner, the banner is still at the call site, and its two locals -- .axisIsPct and .axisRoundTo -- were read nowhere outside the moved block; done so that a check of the bracket path runs the shipped code instead of a transcription of it")

# --- THINGS THIS FILE FOUND AND DOES NOT OWN -------------------------------
attest(ID,
    "validate/run_all.R does not yet source this file",
    "the suite's script list ends at v66_draw_layer.R (validate/run_all.R:509); v67 and v68 both need adding. Not this file's to edit.")
attest(ID,
    "the Q-Q leak this file raised is CLOSED, and is pinned by validate/v74 rather than here",
    "author ruling A, change order 7: the pair is published with a STEP STAMP (@emlGraphsStampAxisRequest), and @emlRecordAxisRequest accepts the pair only when the stamp equals the step being recorded and zeroes the stamp on the way out. The stamp carries the state because the PAIR cannot -- 0/0 is the auto sentinel, so a reset pair is indistinguishable from an auto request. The leg that drives it is a form draw at 0..100 followed by a formless Q-Q draw in the SAME process; nothing in this file's rig can reach it, because harness/formaxis has no Q-Q leg and its every draw is a form draw.")
attest(ID,
    "validate/v32's source check on @emlExpandDrawnExtent callers is red, and not from here",
    "it names eml-annotation-procedures.praat @emlDrawBracketCaption and @emlDrawMatrixPanel; that file went from 2 @emlExpandDrawnExtent call sites at HEAD to 5 in the working tree, and neither owned file changed its count (16 both sides). Somebody else's pin to update.")
attest(ID,
    "the two-draw-steps defect this file raised is CLOSED, and is pinned by validate/v75 rather than here",
    "author ruling B, change order 8: stats/eml-record.praat now has @emlRecordMark / @emlRecordRewind -- the twin of @emlCSVMark / @emlCSVRewind, and as ignorant of legends -- and @emlGraphsDrawWithLegendRoom takes the mark before its loop and rewinds at the top of each pass, above the dispatch so the axis stamp is re-armed. This file's own rig shows the result: harness/formaxis/out/legend_auto/emitted.praat declares 'step 1 (draw)' where it said 'steps 1 (draw), 2 (draw)', and its note reads 195.0000 .. 275.0000 where it said 235.0000. Nothing in this file's rig can prove the note in BYTES, because formaxis records but never replays; harness/record/replay.sh's LEGEND leg edits the block to the note's own two numbers and gets a figure byte-identical to the one the recording drew.")

if (!exists("EML_SUITE")) {
    eml_report("v68 the form's axis request, and the Info window's formatter")
    eml_exit()
}
