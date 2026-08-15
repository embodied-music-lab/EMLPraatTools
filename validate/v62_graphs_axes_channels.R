# ============================================================================
# v62_graphs_axes_channels.R -- the axis a figure is drawn on, and the channel
#                               it is drawn from
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS FILE IS FOR. Five findings from the external audit of 14 August
# 2026, all of them in the graphs layer, all of them the same species: the
# NUMBERS WERE RIGHT AND THE FIGURE WAS WRONG. Not one of them changes a
# statistic. Every one of them changes what a reader takes away from the page,
# which for an instrument whose audience is singing teachers is the same thing
# as being wrong.
#
#   NEW-G7-2 / the author's ruling  the stereo channel choice was unreachable
#   NEW-G7-1  a sustained note drawn as chaos over a collapsed axis
#   NEW-G8-1  points outside a typed axis range drawn OUTSIDE the frame
#   NEW-G8-2  a one-sided range silently inverted, with no notice
#   NEW-G8-4  the annotation panel sitting on top of a datum
#   NEW-G2-2  the Mann-Whitney gloss naming the wrong statistic
#
# ---------------------------------------------------------------------------
# THE STEREO RULING, AND WHY EXISTENCE IS NOT THE CHECK
# ---------------------------------------------------------------------------
# The author's ruling of 14 August 2026, verbatim: "Stereo channel handling:
# ABSOLUTELY NECESSARY -- wire it. The Mix-to-mono / Left / Right choice must
# be reachable when an audio object is stereo. @emlHandleStereo /
# @emlCheckChannels / @emlApplyChannelChoice exist ... with zero callers."
#
# Those three procedures had been in the library since v3.18. They were
# correct. They were documented. Nothing called them, in either direction, for
# months -- and any check of the form "the stereo procedures are present" would
# have been GREEN throughout, because the thing it asserted was true the whole
# time and meant nothing. That is the specific failure mode this file is built
# not to repeat, so the stereo evidence here is a DIALOG ON A DISPLAY: a
# window either appears in front of a stereo Sound on its way to a figure, or
# it does not. harness/graphaxes/stereo.sh drives it under Xvfb, records the
# window's title and whether it was seen, and answers it.
#
# THE NUMBER THAT MAKES IT MATTER. The fixture is 220 Hz in the left channel
# and 330 Hz in the right. Handed to To Pitch as-is, Praat mixes it down and
# returns a contour at 110.0000 Hz -- the fundamental of the mixture, a
# frequency present in NEITHER channel and in nothing anybody sang. Driven
# through the gate with "Left channel only" chosen, the same fixture returns
# 220.0000. The check that those two differ is the whole finding in one line:
# before this work a stereo recording produced a plausible, publishable,
# entirely wrong pitch track and said nothing.
#
# ---------------------------------------------------------------------------
# WHAT COULD NOT HAVE CAUGHT ANY OF THIS, AND WHY
# ---------------------------------------------------------------------------
# 1. THE R SUITE. Eight thousand checks recompute what the plugin PRINTS.
#    Every number in every one of these six findings was already correct --
#    the audit re-derived the graphs layer against scipy and found no
#    disagreement anywhere. A suite that compares printed numbers to computed
#    numbers is structurally incapable of seeing a figure that draws the right
#    number in the wrong place, on an axis whose six ticks all read "200", or
#    under a panel that hides it.
#
# 2. THE STRESS RENDERER. harness/stress_graphs.sh renders 39 figures and
#    asks whether each is non-blank and chromatic. The collapsed-axis pitch
#    contour is vividly non-blank. So is a scatter with five dots painted in
#    the margin. So is an annotation panel sitting on a point. All three pass.
#
# 3. THE WRAPPER PARSE GATE. harness/wrappers/run.sh proves 29 entry points
#    parse. An unreached procedure parses perfectly.
#
# 4. A STATIC CALL-SITE GREP -- the obvious check, and the one that would have
#    been wrong for the longest. See the ruling above.
#
# 5. THE GUI HARNESSES. gui_e2e and gui_adv drive the graphs form, and they
#    drive it on TABLES. No harness in this tree had ever handed the form a
#    stereo Sound, because the fixtures are mono. The audit found it by
#    loading stereoA.wav by hand.
#
# 6. A HUMAN LOOKING AT THE FIGURE, for the axis in particular. It is worth
#    saying plainly: the collapsed-axis contour LOOKS like data. It has
#    structure, excursions and a plausible range of tick numbers. Only reading
#    the six identical labels reveals that the entire vertical extent of the
#    frame is one part in ten thousand of a hertz. The audit's own first pass
#    tiered it severity 2; the verifier re-tiered it to 3 after measuring the
#    span.
#
# ---------------------------------------------------------------------------
# EVIDENCE, AND THE OVERRIDES THAT LET IT BE BROKEN ON PURPOSE
# ---------------------------------------------------------------------------
#     bash harness/graphaxes/axes.sh        -> out/AXES.tsv    (no display)
#     bash harness/graphaxes/stereo.sh      -> out/STEREO.tsv  (Xvfb)
#     Rscript validate/v62_graphs_axes_channels.R
#
#   $EML_GRAPHS_SRC    directory holding the graphs .praat files under test.
#                      Default plugin/graphs. Point it at a deliberately
#                      damaged copy and every static check here goes RED.
#   $EML_AXES_DIR      directory holding AXES.tsv.   Default harness/graphaxes/out
#   $EML_STEREO_DIR    directory holding STEREO.tsv. Default the same.
#
# NOTHING HERE IS VALIDATED UNTIL IT HAS BEEN BROKEN.
#
#     bash harness/graphaxes/break.sh   -> out/BREAKS.tsv
#
# builds a shadow tree in /tmp, damages ONE thing in it, re-drives whichever
# harnesses that damage can reach, and runs this file against it. 44 cases,
# 44 red. They include the gate call sites deleted and commented out, the
# dialog suppressed, the left and right channels swapped, the conversion made
# a no-op, the span floor removed AND set too wide, the tick rule disabled AND
# made unconditional, the frame clip removed AND made over-eager, the
# statistics allowed to leak the clip, the collision scorer bypassed, the
# corrected gloss put back, and each of the three evidence files taken away.
#
# TWO OF THOSE CASES ARE THE POINT OF THE EXERCISE.
#   * `gate_form_comment_only` COMMENTS OUT the form's call rather than
#     deleting it. The first version of that check read the whole file and
#     passed, because the paragraph EXPLAINING the call site contains its
#     name. Comments are now stripped before matching.
#   * `core_bypassed` deletes the core call from the gate's body only. The
#     first version of that check searched the whole file and passed, because
#     @emlHandleStereo calls the core from its own body. It is now scoped to
#     the gate's procedure body.
# Both checks were green, and both were worthless, until a break test said so.
#
# FIVE CHECKS HERE HAVE NEVER BEEN RED, and it is worth saying which and why
# rather than implying otherwise. Two are arithmetic done in R on the audit's
# own published numbers (U = R1 - n1(n1+1)/2 = 64 against R1 = 274) -- they
# anchor the finding and cannot be broken by damaging the plugin, because the
# plugin is not what computes them. Three are GUARDS ON THE FIXTURE, not
# assertions about the product: that a synthesised 200 Hz tone really does
# track at 200 Hz, that its span really is numerical noise, and that the 2 Hz
# ramp really does sit above the floor. If any of those three ever fails, the
# probe has stopped probing and the checks that depend on it mean nothing --
# which is exactly what they are there to say.
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

ID <- "v62"

# Base R only, and base R below 4.4 has no %||%. Defined here rather than
# assumed, because a validator that fails to LOAD on a reviewer's R is worse
# than one that fails a check.
`%or%` <- function(a, b) if (is.null(a) || length(a) == 0L || is.na(a)) b else a

gdir <- Sys.getenv("EML_GRAPHS_SRC", unset = "")
if (!nzchar(gdir)) gdir <- repo_path(file.path("plugin", "graphs"))
axdir <- Sys.getenv("EML_AXES_DIR", unset = "")
if (!nzchar(axdir)) axdir <- repo_path(file.path("harness", "graphaxes", "out"))
stdir <- Sys.getenv("EML_STEREO_DIR", unset = "")
if (!nzchar(stdir)) stdir <- repo_path(file.path("harness", "graphaxes", "out"))

f_graph <- file.path(gdir, "eml-graph-procedures.praat")
f_draw  <- file.path(gdir, "eml-draw-procedures.praat")
f_annot <- file.path(gdir, "eml-annotation-procedures.praat")
f_form  <- file.path(gdir, "eml-graphs-form.praat")

# ---------------------------------------------------------------------------
# JOIN PRAAT CONTINUATIONS, AND STRIP COMMENTS BEFORE MATCHING.
# ---------------------------------------------------------------------------
# Both halves matter and both have bitten this repository. A call written
# across two lines with "..." is invisible to a line-at-a-time regex, which is
# the shape of a check that passes while proving nothing. And every one of
# these files carries long prose comments that NAME the procedures being
# checked for -- so a grep that does not strip comments would find
# "@emlGraphsChannelGate" in the paragraph explaining why it exists and call
# the wiring present after the call site had been deleted. That is not a
# hypothetical: this file's own break test for the form call site passed on
# the first attempt for exactly that reason.
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
    # Praat comments open with #, ; or the bare word "comment" is NOT a
    # comment -- it is a dialog widget, and it must survive.
    norm[!grepl("^#", norm) & !grepl("^;", norm)]
}

code_graph <- read_code(f_graph)
code_draw  <- read_code(f_draw)
code_annot <- read_code(f_annot)
code_form  <- read_code(f_form)

has <- function(code, pattern) any(grepl(pattern, code, fixed = FALSE))

check_true(ID, "the four graphs sources are present",
           all(file.exists(c(f_graph, f_draw, f_annot, f_form))))

read_tsv_map <- function(path) {
    if (!file.exists(path)) return(list())
    x <- readLines(path, warn = FALSE)
    x <- x[nzchar(x)]
    parts <- strsplit(x, "\t", fixed = TRUE)
    parts <- parts[vapply(parts, length, 1L) >= 2L]
    setNames(lapply(parts, function(p) paste(p[-1], collapse = "\t")),
             vapply(parts, `[`, "", 1L))
}

# ===========================================================================
# 1. STEREO -- REACHABILITY, NOT EXISTENCE
# ===========================================================================
st <- read_tsv_map(file.path(stdir, "STEREO.tsv"))
have_stereo <- length(st) > 0

check_true(ID, "the stereo drive produced evidence (harness/graphaxes/stereo.sh)",
           have_stereo)

if (have_stereo) {
    sv <- function(k) if (is.null(st[[k]])) NA_character_ else st[[k]]
    sn <- function(k) suppressWarnings(as.numeric(sv(k)))

    # -- the dialog appears on the direct Sound path (the waveform) ----------
    check_true(ID,
        sprintf("a stereo Sound bound for a WAVEFORM raises the channel dialog (title %s)",
                dQuote(sv("gate_waveform_dialog_title"))),
        identical(sv("gate_waveform_dialog_seen"), "1") &&
        grepl("Stereo Sound", sv("gate_waveform_dialog_title") %or% ""))

    # -- and on the derived path, which is the ruling's parenthesis ----------
    check_true(ID,
        "a stereo Sound bound for a PITCH TRACK raises it too, BEFORE To Pitch",
        identical(sv("gate_pitch_dialog_seen"), "1") &&
        grepl("Stereo Sound", sv("gate_pitch_dialog_title") %or% ""))

    # -- and a mono recording is not interrupted ----------------------------
    # Given the same wait as the legs that do raise one, so "no dialog" cannot
    # mean "not yet".
    check_true(ID,
        "a MONO Sound raises no dialog at all -- the ordinary recording is untouched",
        identical(sv("mono_silent_dialog_seen"), "0") &&
        identical(sv("pitch_created"), "1"))

    # -- what the choice did ------------------------------------------------
    check_true(ID,
        sprintf("the choice was applied: %s -> %s, %s channel(s)",
                sv("choice"), sv("result_name"), sv("result_channels")),
        identical(sv("was_converted"), "1") &&
        identical(sv("result_channels"), "1"))

    # THE USER'S OBJECT SURVIVES. @emlApplyChannelChoice removes the original
    # by default, which is right for a batch and wrong for a session where the
    # Sound is what the user selected and will want for the next figure.
    check_true(ID,
        "the user's own stereo Sound is still in the Objects window afterwards",
        identical(sv("original_still_present"), "2"))

    # -- THE NUMBER. The clincher, and the reason the ruling exists. --------
    check(ID, "ungated, a 220/330 stereo pair yields the mixdown F0 (present in neither channel)",
          110, sn("ungated_mean_f0"), tol = 0.5)
    check(ID, "driven through the gate with Left chosen, the same pair yields 220 Hz",
          220, sn("pitch_mean"), tol = 0.5)
    check_true(ID,
        sprintf(paste0("the gated and ungated pitch tracks DIFFER (%s vs %s Hz) -- ",
                       "which is what an unreachable dialog was costing"),
                sv("pitch_mean"), sv("ungated_mean_f0")),
        is.finite(sn("pitch_mean")) && is.finite(sn("ungated_mean_f0")) &&
        abs(sn("pitch_mean") - sn("ungated_mean_f0")) > 50)

    # -- the three arms of the ruling, each with its own F0 -----------------
    check_true(ID, "the dialog's three options are Mix to mono / Left / Right",
        identical(sv("choice_1_label"), "Mix to mono") &&
        identical(sv("choice_2_label"), "Left channel only") &&
        identical(sv("choice_3_label"), "Right channel only"))
    check(ID, "Mix to mono gives the mixture's F0",   110, sn("choice_1_mean_f0"), tol = 0.5)
    check(ID, "Left channel only gives the left F0",  220, sn("choice_2_mean_f0"), tol = 0.5)
    check(ID, "Right channel only gives the right F0", 330, sn("choice_3_mean_f0"), tol = 0.5)
    check_true(ID, "every arm returns a single-channel Sound",
        identical(sv("choice_1_channels"), "1") &&
        identical(sv("choice_2_channels"), "1") &&
        identical(sv("choice_3_channels"), "1"))
}

# -- the call sites, named. Belt and braces to the drive above: the drive
# proves a dialog appears, these say WHERE from, so a future reader can find
# the wiring without re-running Xvfb.
check_true(ID, "the graphs form gates the acquired object (eml-graphs-form.praat)",
           has(code_form, "@emlGraphsChannelGate"))
# AND IT IS IN THE LIVE FLOW. A call that parses is not a call that runs: the
# same string sitting in a procedure nobody invokes, or above the acquire loop
# where the object does not exist yet, would satisfy the grep above and gate
# nothing. Its position relative to the loop's own closing line is what says
# it is on the path every figure takes.
i_acq  <- grep("^until acquireDone = 1$", code_form)
i_gate <- grep("@emlGraphsChannelGate", code_form)
check_true(ID,
    "and the call sits AFTER the acquire loop closes, on the path every figure takes",
    length(i_acq) == 1L && length(i_gate) >= 1L && any(i_gate > i_acq[1]))
check_true(ID, "the conversion procedure gates before To Pitch / Spectrum / Ltas",
           has(code_graph, "@emlGraphsChannelGate: \\.sourceId, \"pitch track\"") &&
           has(code_graph, "@emlGraphsChannelGate: \\.sourceId, \"spectrum\"") &&
           has(code_graph, "@emlGraphsChannelGate: \\.sourceId, \"long-term"))
# THE GATE REACHES THE SHIPPED CORE, and this is scoped to the gate's own
# body rather than to the file. A whole-file grep for the core call was the
# first version of this check and it was WORTHLESS: @emlHandleStereo calls
# @emlApplyChannelChoice too, from its own body, so deleting the call out of
# the gate left the file-wide match intact and the check green. Found by the
# break case `core_bypassed`, which is exactly what break cases are for.
proc_body <- function(code, name) {
    st <- grep(paste0("^procedure ", name, "\\b"), code)
    if (!length(st)) return(character(0))
    en <- grep("^endproc$", code)
    en <- en[en > st[1]]
    if (!length(en)) return(character(0))
    code[st[1]:en[1]]
}
gate_body <- proc_body(code_graph, "emlGraphsChannelGate")
check_true(ID, "the gate's own body reaches the shipped mechanical core, not a private copy",
           length(gate_body) > 0 &&
           any(grepl("@emlApplyChannelChoice: \\.soundId, channel_handling", gate_body)))
check_true(ID, "and it asks for the non-destructive mode before doing so",
           length(gate_body) > 0 &&
           any(grepl("emlChannelKeepOriginal = 1", gate_body)))
check_true(ID, "the dialog it raises offers exactly the three options the ruling names",
           length(gate_body) > 0 &&
           any(grepl("option: \"Mix to mono\"", gate_body, fixed = TRUE)) &&
           any(grepl("option: \"Left channel only\"", gate_body, fixed = TRUE)) &&
           any(grepl("option: \"Right channel only\"", gate_body, fixed = TRUE)))

# ===========================================================================
# 2. THE AXIS -- NEW-G7-1
# ===========================================================================
ax <- read_tsv_map(file.path(axdir, "AXES.tsv"))
have_axes <- length(ax) > 0
check_true(ID, "the axis drive produced evidence (harness/graphaxes/axes.sh)",
           have_axes)

if (have_axes) {
    av <- function(k) if (is.null(ax[[k]])) NA_character_ else ax[[k]]
    an <- function(k) suppressWarnings(as.numeric(av(k)))

    check_true(ID,
        sprintf("the axis evidence was measured on the target Praat (%s)", av("praat_version")),
        grepl("6\\.6\\.30|6\\.[7-9]|[7-9]\\.", av("praat_version") %or% ""))

    # THE DATA ARE EXACT AND WERE NEVER THE PROBLEM. Say so with a number:
    # the pitch track of a synthesised 200 Hz tone spans a hundred-thousandth
    # of a hertz. The verifier's discriminating probe is what established
    # this, and it is re-confirmed here rather than taken on trust.
    check(ID, "a synthesised 200 Hz tone tracks at 200 Hz",
          200, an("steady_data_min"), tol = 1e-4)
    check_true(ID,
        sprintf("its measured span is numerical noise (%s Hz) -- the analysis was never wrong",
                av("steady_data_span")),
        is.finite(an("steady_data_span")) && an("steady_data_span") < 1e-4)

    # THE FLOOR. A tenth of a semitone at 200 Hz is 1.16 Hz; the axis is then
    # rounded out to nice ticks. Anything at or under a hertz means the floor
    # is not there, and every tick label collapses to "200" again.
    check_true(ID,
        sprintf("the drawn axis is opened to a readable width (%s Hz, from %s)",
                av("steady_axis_span"), av("steady_data_span")),
        is.finite(an("steady_axis_span")) && an("steady_axis_span") >= 1.0)
    # AND IT IS STILL CENTRED ON THE DATA. A floor that widened to 75-500 Hz
    # would also pass the test above and would hide the very steadiness the
    # figure is about.
    check_true(ID,
        sprintf("and still tight around the note (%s to %s Hz)",
                av("steady_axis_min"), av("steady_axis_max")),
        is.finite(an("steady_axis_span")) && an("steady_axis_span") <= 10 &&
        an("steady_axis_min") < 200 && an("steady_axis_max") > 200)

    # THE REGRESSION GUARD. The verifier established that a 2 Hz span ALREADY
    # drew correctly, on 198.5 to 201.5. A floor that moved this figure would
    # be a fix that broke a working one, and a floor set at twenty cents
    # instead of ten did exactly that when first tried.
    check(ID, "a genuine 2 Hz ramp keeps the axis it already had (min)",
          198.5, an("ramp2_axis_min"), tol = 1e-6)
    check(ID, "a genuine 2 Hz ramp keeps the axis it already had (max)",
          201.5, an("ramp2_axis_max"), tol = 1e-6)
    check_true(ID,
        sprintf("and that ramp's span (%s Hz) is above the floor, so it was left alone",
                av("ramp2_data_span")),
        is.finite(an("ramp2_data_span")) && an("ramp2_data_span") > 1.16)

    # TICK PRECISION. Praat's own mark number carries four significant digits
    # and rounds the rest away -- measured on 6.6.30: 200.05 prints "200.1",
    # 200.01 prints "200", 199.95 prints "199.9". The plugin takes over the
    # formatting only when four digits are not enough, so ordinary axes are
    # drawn exactly as they always were.
    check_true(ID, "an ordinary 0-100 axis is still left to Praat to label",
               identical(av("tick_ordinary_explicit"), "0"))
    check_true(ID, "so is an ordinary 75-500 Hz pitch axis",
               identical(av("tick_pitch_explicit"), "0"))
    check_true(ID, "so is a 0-1 second time axis",
               identical(av("tick_time_explicit"), "0"))
    check_true(ID,
        "a 199.98-200.02 axis is NOT -- four significant digits cannot label it",
        identical(av("tick_narrow_explicit"), "1"))
    check_true(ID,
        sprintf("and the plugin writes distinct labels for it (%s / %s / %s)",
                av("tick_narrow_label_a"), av("tick_narrow_label_b"),
                av("tick_narrow_label_c")),
        length(unique(c(av("tick_narrow_label_a"), av("tick_narrow_label_b"),
                        av("tick_narrow_label_c")))) == 3L)
}

check_true(ID, "@emlTickPrecision exists in the library",
           has(code_graph, "^procedure emlTickPrecision"))
check_true(ID, "and all three aligned-mark procedures consult it",
           sum(grepl("@emlTickPrecision:", code_graph)) >= 3L)
check_true(ID, "the F0 contour carries a minimum-span floor in semitones",
           has(code_draw, "\\.spanFloorSemitones ="))

# ===========================================================================
# 3. CLIPPING AND THE ONE-SIDED RANGE -- NEW-G8-1, NEW-G8-2
# ===========================================================================
if (have_axes) {
    av <- function(k) if (is.null(ax[[k]])) NA_character_ else ax[[k]]
    an <- function(k) suppressWarnings(as.numeric(av(k)))

    check_true(ID, "on an automatic axis nothing is withheld -- the clip is not a filter",
               identical(av("clip_auto_outside"), "0"))
    check_true(ID,
        sprintf("a typed range of 100-300 over data running 90-322 withholds %s point(s)",
                av("clip_set_outside")),
        identical(av("clip_set_outside"), "5"))
    check_true(ID, "the drawn frame is the range the user typed, not a widened one",
        identical(av("clip_set_axis_min"), "100.000") &&
        identical(av("clip_set_axis_max"), "300.000"))

    # THE LINE THAT MUST NOT MOVE. A range is a VIEWPORT. If clipping the
    # picture also changed the correlation, this whole fix would be a far
    # worse defect than the one it repairs -- so the two draws' r values are
    # compared to ten decimals, and n to the row.
    check(ID, "the correlation is IDENTICAL on the clipped draw",
          an("clip_auto_r"), an("clip_set_r"), tol = 1e-10)
    check_true(ID, "and so is n -- every valid row is still in the statistics",
        identical(av("clip_auto_n"), av("clip_set_n")) &&
        identical(av("clip_set_n"), "30"))

    # NEW-G8-2. The form's range block turns a lone minimum into (0, minimum)
    # before any draw procedure sees it, so the inversion cannot be undone
    # here. What CAN be done, and is, is refuse to let its consequence pass
    # unremarked: the withheld count and the range in force are both stated.
    check_true(ID, "the withholding is disclosed rather than silent",
               is.finite(an("clip_disclosed_n")) && an("clip_disclosed_n") >= 1)
}

check_true(ID, "the frame is published for the primitives to clip against",
           has(code_graph, "emlFrameKnown = 1"))
check_true(ID, "both point primitives consult it",
           sum(grepl("@emlPointInFrame:", code_graph)) >= 2L)
check_true(ID, "and the disclosure names the range in force AND the floor/ceiling trap",
           has(code_draw, "^procedure emlDiscloseClipped") &&
           has(code_draw, "Range in force") &&
           has(code_draw, "a minimum on its own is read as a maximum"))

# ===========================================================================
# 4. THE ANNOTATION PANEL ON A DATUM -- NEW-G8-4
# ===========================================================================
if (have_axes) {
    av <- function(k) if (is.null(ax[[k]])) NA_character_ else ax[[k]]
    an <- function(k) suppressWarnings(as.numeric(av(k)))

    # The probe is built so the two scorers must disagree. If they agree, the
    # probe has stopped probing and the check below is worthless -- so that is
    # asserted first, before the result is believed.
    check_true(ID,
        sprintf("the probe still separates the two scorers (quadrant %s, rectangle %s)",
                av("collide_quadrant_corner"), av("collide_box_corner")),
        !identical(av("collide_quadrant_corner"), av("collide_box_corner")))
    check_true(ID,
        sprintf("the quadrant winner (%s) has a datum under the panel: %s point(s)",
                av("collide_quadrant_corner"), av("collide_hits_top_left")),
        identical(av("collide_quadrant_corner"), "top-left") &&
        identical(av("collide_hits_top_left"), "1"))
    check_true(ID,
        sprintf("the corner actually used (%s) covers nothing",
                av("collide_box_corner")),
        identical(av("collide_box_collisions"), "0"))
    # Only DRAWN points may be counted. A point withheld by the frame clip is
    # not on the page and cannot be hidden by a box.
    check_true(ID, "all 23 drawn points were registered for the collision test",
               identical(av("collide_registered"), "23"))
}

check_true(ID, "@emlPlaceAnnotationBox exists and measures before it places",
           has(code_annot, "^procedure emlPlaceAnnotationBox") &&
           has(code_annot, "emlAnnotBlockMeasureOnly = 1"))
check_true(ID, "both scatter paths place the panel through it",
           sum(grepl("@emlPlaceAnnotationBox:", code_draw)) >= 2L)
check_true(ID, "and an unavoidable overlap is named rather than drawn in silence",
           has(code_draw, "the annotation panel covers"))

# ===========================================================================
# 5. THE MANN-WHITNEY GLOSS -- NEW-G2-2
# ===========================================================================
# THE NUMBER WAS NEVER WRONG. On the audit's verification table the rank sum
# R1 = 274 and the printed U1 = 64, and U = R1 - n1(n1+1)/2 with n1 = 20:
# 274 - 210 = 64. Recomputed here so the finding is anchored to arithmetic
# rather than to an assertion -- what was wrong was the sentence beside it.
n1_audit <- 20
R1_audit <- 274
check(ID, "U1 = R1 - n1(n1+1)/2 recovers the printed U on the audit's table",
      64, R1_audit - n1_audit * (n1_audit + 1) / 2, tol = 0)
check_true(ID,
    "so U (64) and the rank sum (274) are different numbers -- the gloss named the wrong one",
    (R1_audit - n1_audit * (n1_audit + 1) / 2) != R1_audit)

mwu_line <- grep("emlWizardExplain\\$ = \"U:", code_annot, value = TRUE)
check_true(ID, "the Mann-Whitney gloss no longer opens \"Sum of ranks\"",
           length(mwu_line) == 1L &&
           !grepl("Sum of ranks", mwu_line[1]))
check_true(ID, "and it now says what U counts: pairs, out of n1 x n2",
           length(mwu_line) == 1L &&
           grepl("n1 x n2 possible pairs", mwu_line[1], fixed = TRUE))

# THE TWO THAT WERE ALREADY RIGHT, AND MUST STAY. @emlWilcoxonSignedRank ranks
# the absolute differences and sums the ranks of the positive ones for T+ and
# the negative ones for T-. No n(n+1)/2 is subtracted, as it is for U -- the
# signed-rank statistic IS a rank sum, so "Sum of ranks for positive
# differences" is the correct name. Correcting a gloss that was already right
# would be its own defect, so this file pins them where they are.
check_true(ID, "the Wilcoxon T+ gloss is left as it was -- T+ genuinely IS a rank sum",
           has(code_annot, "Sum of ranks for positive differences"))
check_true(ID, "and so is the T- gloss",
           has(code_annot, "Sum of ranks for negative differences"))

if (!exists("EML_SUITE")) {
    eml_report(paste0("v62 graphs axes and channels: the stereo choice is reachable, ",
                      "the axis is readable, the frame clips, the panel moves"))
    eml_exit()
}
