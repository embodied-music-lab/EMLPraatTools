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
# FOUR MORE FROM THE AUTHOR'S RULINGS OF 15 AUGUST, and they are the same
# species again -- three of them leave every number correct and one of them
# leaves the page blank:
#
#   ruling 7   the y-axis NAME and its tick labels drawn into each other, so
#              that "Power (dB)" and "100.10" read as "Powe100.10"
#   ruling 5   Column_k holding SOURCE column k-1, at the two coercion doors
#              that reach @emlCleanConvertedTable
#   ruling 8b  one extracted channel Sound left behind per press of the
#              stereo gate, all of them sharing one name
#   ruling 8c  a Spectrum over a one-bin range drawn as an empty frame --
#              CHASED AND MEASURED HERE, and deliberately not repaired; see
#              the section at the end for what the measurement says and what
#              it is waiting on
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
# 7. FOR RULING 7, EVERY CHECK IN THIS FILE THAT ALREADY EXISTED. The
#    collision is not a number, not a range, not a call site and not a string.
#    @emlTickPrecision was doing exactly what it was built to do -- writing
#    "100.10" where Praat would have written "100.1" -- and the figure got
#    worse, because the sixth character is the one that runs into the axis
#    name. Nothing that reads source, and nothing that reads a measurement
#    emitted by a Praat script, can see two pieces of ink touching. That is
#    why the evidence for ruling 7 is A COLUMN PROFILE OF THE RENDERED PNG:
#    the gap between the axis name's ink and the tick numbers' ink, in pixels,
#    off the page as it will be printed.
#
# 8. FOR RULING 5, A CENSUS OF COLUMN HEADERS -- which is what the plugin's
#    own duplicate-name repair already had, and it was green throughout.
#    "Column_2, Column_3, Column_4" is a perfectly good set of distinct
#    non-empty headers, and so is "Column_1, Column_2, Column_3". A check over
#    names alone cannot tell an off-by-one from a correct mapping, because the
#    off-by-one does not damage the names -- it damages what they POINT AT.
#    The probe's Matrix is therefore filled with col * 100 + row, so that any
#    cell says which source column it came from, and the assertion is about
#    the mapping and not about the headers. Borrowed, deliberately, from
#    validate/v63's §3f: the same defect, the same evidence, at a different
#    door.
#
# 9. FOR RULING 8b, ANY CHECK WHOSE POPULATION IS ONE PRESS -- which is every
#    other stereo check in this file. The first press is flawless. So is the
#    second. What is wrong is what the first left behind for the second, and
#    it is only visible to a leg that presses the gate three times and then
#    WALKS THE OBJECT LIST -- because asking for the object by name is exactly
#    what the defect makes meaningless.
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
#   $EML_SCRIPTS_SRC   directory holding the wrapper scripts. Default
#                      plugin/scripts. Only one check reads it -- that the
#                      describe wrapper still routes its header repair through
#                      the shared procedure -- and that check is the whole
#                      reason ruling 5 is one repair and not two.
#   $EML_AXES_DIR      directory holding AXES.tsv.   Default harness/graphaxes/out
#   $EML_STEREO_DIR    directory holding STEREO.tsv. Default the same.
#
# NOTHING HERE IS VALIDATED UNTIL IT HAS BEEN BROKEN.
#
#     bash harness/graphaxes/break.sh   -> out/BREAKS.tsv
#
# builds a shadow tree in /tmp, damages ONE thing in it, re-drives whichever
# harnesses that damage can reach, and runs this file against it. 64 cases,
# 64 red. They include the gate call sites deleted and commented out, the
# dialog suppressed, the left and right channels swapped, the conversion made
# a no-op, the span floor removed AND set too wide, the tick rule disabled AND
# made unconditional, the frame clip removed AND made over-eager, the
# statistics allowed to leak the clip, the collision scorer bypassed, the
# corrected gloss put back, and each of the three evidence files taken away.
#
# THE TWENTY ADDED FOR THE 15 AUGUST RULINGS ARE PAIRED WHEREVER A FIX HAS
# TWO WAYS TO BE WRONG, which for ruling 7 is the whole difficulty: the axis
# name shift is damaged so that it NEVER fires, and again so that it ALWAYS
# fires. `axisname_shifts_all` is the case that matters, because a shift
# applied to every figure clears both collisions, satisfies any check written
# against the crowded figures alone, and quietly moves all 39 stress figures.
# The label predictor is damaged in the direction that looks like an
# improvement -- modelling Praat's exponent forms instead of declining them --
# which would move violin_hugevalues, a figure that is correct today. And the
# stereo drop is damaged so that the gate KEEPS RUNNING and accumulates, which
# is what the plugin did before the ruling; deleting the call alone kills the
# leg and goes red for want of evidence rather than because three Sounds were
# counted. `clamp_removed` is the one whose red line is not the gap at all:
# the gap gets BIGGER as the name leaves the page, and what catches it is the
# axis name's first ink column arriving at zero -- a name sliced down its
# length by the export.
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
scdir <- Sys.getenv("EML_SCRIPTS_SRC", unset = "")
if (!nzchar(scdir)) scdir <- repo_path(file.path("plugin", "scripts"))

f_graph <- file.path(gdir, "eml-graph-procedures.praat")
f_draw  <- file.path(gdir, "eml-draw-procedures.praat")
f_annot <- file.path(gdir, "eml-annotation-procedures.praat")
f_form  <- file.path(gdir, "eml-graphs-form.praat")
f_desc  <- file.path(scdir, "eml-describe-table.praat")

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
    # the pitch track of a synthesised 200 Hz tone sits on 200 Hz to within a
    # thousandth of a hertz and spans less than a five-thousandth. The
    # verifier's discriminating probe is what established this, and it is
    # re-confirmed here rather than taken on trust.
    #
    # THE TOLERANCES WERE LOOSENED ON 20 AUGUST 2026, and by how much matters
    # less than why. The fixture used to ask Praat for a "very accurate"
    # filtered autocorrelation, which is not what the plugin asks for; on Ian's
    # ruling that a pitch call in this repository follows the PraatGen
    # canonical settings and nothing else, the fixture now asks the same
    # question the plugin does. Canon is the cheaper analysis, so the tone
    # tracks at 200.0004 Hz rather than 200.000004, and the span is 0.00017 Hz
    # rather than 0.0000097.
    #
    # NEITHER NUMBER TOUCHES WHAT THESE TWO CHECKS ARE FOR. They exist to say
    # that the axis anomaly this file documents came from the DRAWING and not
    # from the analysis underneath it -- and the anomaly is a whole hertz wide.
    # Four ten-thousandths of a hertz makes that case exactly as well as four
    # millionths did. The tolerances are set an order of magnitude above the
    # measured values, so ordinary run-to-run variation cannot red them, and
    # anything that could plausibly explain a 1 Hz axis artefact still does.
    check(ID, "a synthesised 200 Hz tone tracks at 200 Hz",
          200, an("steady_data_min"), tol = 1e-2)
    check_true(ID,
        sprintf("its measured span is numerical noise (%s Hz) -- the analysis was never wrong",
                av("steady_data_span")),
        is.finite(an("steady_data_span")) && an("steady_data_span") < 1e-3)

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

# THE VALUE, NOT THE ASSIGNMENT -- NEW-G7-1's pin.
# The line above asks only that something is assigned to the floor, and a
# floor of zero satisfies it while the collapse it prevents comes straight
# back: a sustained tone whose pitch track spans a hundred-thousandth of a
# hertz is drawn as a fluctuating contour over an axis opened to nothing. So
# the NUMBER is read out of the source and required to be positive. Every
# assignment in the file is taken, not the first, because a second one
# further down would decide the draw.
span_floor <- suppressWarnings(as.numeric(sub(
    "^.*\\.spanFloorSemitones\\s*=\\s*([0-9.eE+-]+).*$", "\\1",
    grep("\\.spanFloorSemitones\\s*=\\s*[0-9.eE+-]", code_draw, value = TRUE))))
check_true(ID,
    sprintf("and the floor is a POSITIVE number of semitones, not merely assigned (%s)",
            if (length(span_floor)) paste(span_floor, collapse = ", ") else "no numeric assignment"),
    length(span_floor) > 0 && all(is.finite(span_floor)) && all(span_floor > 0))

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

# PER PRIMITIVE, IN ITS OWN BODY -- NEW-G8-1's pin.
# The count above is file-wide and there are THREE call sites
# (@emlRegisterCollisionPoints, @emlDrawMarker, @emlDrawAlphaDot), so one
# point primitive can stop clipping and `>= 2` still passes. That is the same
# defect the `core_bypassed` break found on the channel gate, and the repair
# is the same: scope the assertion to the body of the procedure that has to
# do the work. Asking as well as ACTING is required -- a primitive that calls
# @emlPointInFrame and then draws the point anyway is the finding verbatim --
# so the refusal arm is asserted beside the call.
for (prim in c("emlDrawMarker", "emlDrawAlphaDot")) {
    pbody <- proc_body(code_graph, prim)
    check_true(ID,
        sprintf("@%s clips in its OWN body: it asks @emlPointInFrame and refuses on inside = 0",
                prim),
        length(pbody) > 0 &&
        any(grepl("@emlPointInFrame:", pbody, fixed = TRUE)) &&
        any(grepl("^if emlPointInFrame\\.inside = 0$", pbody)))
}
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

# ===========================================================================
# 6. THE AXIS NAME AND ITS TICK LABELS -- AUTHOR RULING 7
# ===========================================================================
# "No collision between the y-axis name and its tick labels. The author
# delegates the mechanism; the requirement is no collision."
#
# THE MECHANISM CHOSEN, AND WHY IT IS NOT THE ONE SUGGESTED. The ruling
# proposed widening the plugin's own left margin by a character width. That
# was measured and it does not work: `Text left` anchors the rotated name to
# the INNER FRAME at a distance fixed by the font size, and the frame moves
# with the margin, so the same figure drawn at marginLeft 0.84" and 1.10" has
# the identical three pixels of gap. What is done instead is to declare the
# frame momentarily to start further left, draw the name from Praat's own
# anchor into that declared frame, and put the frame back -- so the name keeps
# Praat's vertical centring, rotation and baseline, and the shift is the only
# thing that changed. @emlDrawAxisNameLeft.
#
# THE THREE FIGURES BELOW ARE THE WHOLE ARGUMENT.
#   margin_st     Praat's own label, six characters, no explicit precision
#   margin_db     the plugin's label, six characters, explicit precision
#   margin_plain  an ordinary axis, which must not move by one pixel
#
# THE THIRD IS THE CHECK. A fix that widened the margin unconditionally would
# satisfy the first two and would change every figure this plugin has ever
# drawn -- so margin_plain asserts a shift of EXACTLY zero and a gap that is
# EXACTLY what it was at HEAD, and all 39 figures of
# harness/stress_graphs.sh were re-rendered and compared byte for byte.
if (have_axes) {
    av <- function(k) if (is.null(ax[[k]])) NA_character_ else ax[[k]]
    an <- function(k) suppressWarnings(as.numeric(av(k)))

    # -- the two collisions, in pixels off the page ------------------------
    # A quarter of a millimetre at 300 dpi is three pixels, and three pixels
    # is what "reads as touching" measured as. The floor asserted here is one
    # third of a character width, which at this figure's 9.36 pt body is
    # about 7 px -- comfortably above the 3 and 4 px measured at HEAD, and
    # comfortably below the 15 and 17 px the fix produces.
    check_true(ID,
        sprintf("a semitone axis reading %s to %s has six-character ticks",
                av("margin_st_axis_min"), av("margin_st_axis_max")),
        is.finite(an("margin_st_widest_label_mm")) &&
        an("margin_st_widest_label_mm") > 0)
    # AND PRAAT WROTE THEM, NOT THE PLUGIN. This is the half of the ruling
    # that a guard hung off .explicit alone would miss entirely: two integer
    # digits and two decimals is four significant digits, so @emlTickPrecision
    # does not engage and Praat's own "-33.08" arrives at six characters by
    # its own route.
    check_true(ID,
        "and Praat wrote them itself -- explicit precision never engaged there",
        identical(av("margin_st_tick_explicit"), "0"))
    check_true(ID,
        sprintf("the semitone axis name clears its ticks (%s px, was 3 at HEAD)",
                av("margin_st_gap_px")),
        is.finite(an("margin_st_gap_px")) && an("margin_st_gap_px") >= 7)
    check_true(ID,
        "an explicit two-decimal dB axis is the other route to six characters",
        identical(av("margin_db_tick_explicit"), "1") &&
        identical(av("margin_db_tick_decimals"), "2"))
    check_true(ID,
        sprintf("and Power (dB) clears \"100.10\" (%s px, was 4 at HEAD)",
                av("margin_db_gap_px")),
        is.finite(an("margin_db_gap_px")) && an("margin_db_gap_px") >= 7)

    # -- THE NARROW CASE, UNTOUCHED ---------------------------------------
    check_true(ID,
        sprintf("an ordinary figure's widest tick label is under six characters (%s mm measured)",
                av("margin_plain_widest_label_mm")),
        identical(av("margin_plain_widest_label_mm"), "0"))
    check_true(ID,
        "so its axis name is not moved at all -- the shift is exactly zero",
        identical(av("margin_plain_shift_inch"), "0"))
    check_true(ID,
        sprintf("and it still has the gap it always had (%s px)",
                av("margin_plain_gap_px")),
        identical(av("margin_plain_gap_px"), "68"))
    # THE TWO THAT DID MOVE, MOVED. Stated as a number rather than implied by
    # the gaps above: a fix that computed a shift and drew nothing, or drew
    # without computing, would leave one of these two disagreeing with the
    # pixels.
    check_true(ID,
        sprintf("the two crowded figures were shifted and the plain one was not (%s / %s / %s inch)",
                av("margin_st_shift_inch"), av("margin_db_shift_inch"),
                av("margin_plain_shift_inch")),
        is.finite(an("margin_st_shift_inch")) && an("margin_st_shift_inch") > 0 &&
        is.finite(an("margin_db_shift_inch")) && an("margin_db_shift_inch") > 0 &&
        an("margin_plain_shift_inch") == 0)
    # AND THE SHIFT IS SMALL. A guard that solved the collision by moving the
    # name an inch would pass every check above and would put the axis name
    # off the figure. Both shifts are millimetres.
    check_true(ID,
        "and both shifts are a few millimetres, not a redesign of the margin",
        an("margin_st_shift_inch") < 0.25 && an("margin_db_shift_inch") < 0.25)

    # -- NOTHING WAS PUSHED OFF THE PAGE ----------------------------------
    # Praat saves the outer viewport @emlAssertFullViewport selects and saves
    # nothing outside it -- measured, by saving a figure from 0.5" whose axis
    # name stood at 0.4" and watching a fifth of the ink disappear. So a shift
    # bigger than the panel's own margin does not merely look odd, it SLICES
    # THE NAME down its length. That is the requirement, and it is unchanged.
    #
    # WHAT STOOD HERE UNTIL 16 AUGUST 2026, AND WHY IT WENT. Four checks, one
    # per leg, each reading the first inked COLUMN of the whole picture and
    # asking for it to be greater than zero.
    #
    #   A POSITIONAL MEASUREMENT THAT ANY INK CAN SATISFY IS NOT A MEASUREMENT
    #   OF THE ELEMENT IT IS WRITTEN ABOUT. "First ink is not column 0" is
    #   answered by the tick numbers, by the frame, by the title -- by whatever
    #   the scan reaches first -- so it passes with the axis name clipped away
    #   entirely, and on that case it reads HEALTHIER than it does on a correct
    #   figure, because what is left starts further RIGHT. It could not see the
    #   element it named. On three of the four legs it was answered by ink that
    #   no shift in this ruling can move at all.
    #
    # THIS IS THE SAME TRAP AND THE SAME REBUILD AS validate/v66 §3 (the seven
    # categorical axis names) and validate/v69 §4 (the bracket caption), whose
    # header states it in full under "A CHECK ANCHORED ON FIRST INK". The
    # repository gets ONE answer to it, not three: what can only be answered by
    # the element is the element's own EXTENT, its POSITION against a known
    # anchor, or its VALUE. Both statements below are measured, neither is a
    # constant chosen here, and no new fixture was needed -- v62 already had
    # the anchor in its own legs.
    #
    # THE ANCHOR. margin_plain takes no shift -- asserted exactly zero above --
    # so its axis name stands where the theme puts it with no repair in play,
    # and its column is the theme's own margin. Its scale is taken from the
    # picture rather than assumed: every 6 x 4 leg here is drawn 6 inches wide,
    # so the width in pixels over 6 is the harness's own resolution, and it is
    # asserted to be the 300 dpi the crop constants in this rig already assume.
    # A rig re-driven at another resolution goes red here rather than quietly
    # rescaling every displacement below it.
    ppi        <- an("margin_plain_width_px") / 6
    anchor_col <- an("margin_plain_name_left_px")
    anchor_run <- an("margin_plain_name_run_px")
    check_true(ID,
        sprintf("the margin figures are the 300 dpi this rig's own crop constants assume (%s px / 6 in)",
                av("margin_plain_width_px")),
        is.finite(ppi) && abs(ppi - 300) < 0.5)
    # AND THE ANCHOR IS THE THEME'S, NOT ONE FIGURE'S ACCIDENT. margin_db and
    # margin_cat are separately driven 6 x 4 figures with the same
    # six-character labels and the same shift, drawn by different procedures --
    # a Spectrum and a categorical violin. If they ever disagree on the column
    # their axis name lands in, the column is a property of one figure rather
    # than of the theme, and every displacement measured from it is
    # meaningless; this says so before the legs below do.
    check_true(ID,
        sprintf("two independently drawn 6 x 4 figures agree where a six-character axis puts its name (%s px and %s px)",
                av("margin_db_name_left_px"), av("margin_cat_name_left_px")),
        is.finite(anchor_col) && anchor_col > 0 &&
        is.finite(an("margin_db_name_left_px")) &&
        an("margin_db_name_left_px") == an("margin_cat_name_left_px"))

    # POSITION, on the three legs the anchor reaches. margin_panel is a 3 x 2
    # figure at a smaller body size, so the 6 x 4 anchor says nothing about it
    # and is not stretched to pretend otherwise -- it is carried by the extent
    # check below, which is what its own break needs.
    #
    # The name must stand exactly the published shift to the LEFT of where an
    # unshifted name stands: 99 px anchor less a 0.1048 in shift at 300 dpi is
    # 31.4 px, measured 32. A shift that never fires puts it back at 99, a
    # shift applied to every figure moves the anchor itself, and a shift big
    # enough to run off the page leaves a fragment further right than the
    # intact name. None is within a pixel and a half of what the plugin says it
    # did. This is also the picture's own answer to the published shift_inch
    # checked above, which until here was only ever compared against itself.
    for (leg in c("margin_st", "margin_db", "margin_plain")) {
        moved_px <- anchor_col - an(paste0(leg, "_name_left_px"))
        want_px  <- an(paste0(leg, "_shift_inch")) * ppi
        check_true(ID,
            sprintf("%s: the axis name stands where the published shift says it should, left of an unmoved name (%s px moved, %s in published = %s px)",
                    leg, format(moved_px), av(paste0(leg, "_shift_inch")),
                    format(round(want_px, 1))),
            is.finite(moved_px) && is.finite(want_px) &&
            moved_px >= 0 && abs(moved_px - want_px) <= 1.5)
    }

    # EXTENT, on all four. The name's own ink run is the width of the rotated
    # glyphs and nothing else's, so a name sliced by the export is narrower
    # than an intact one however far its surviving fragment has moved: on
    # clamp_removed margin_panel ran 17 px against 29 intact, while its GAP
    # grew from 7 px to 13 and its first-ink column was the only thing that
    # noticed.
    #
    # THE FLOOR IS THE CONTROL'S RUN, MEASURED, NOT A NUMBER PICKED HERE, and
    # it is a floor rather than an equality because these four legs do not draw
    # the same axis name -- "Y", "F0 (semitones re 440 Hz)", "Power (dB)" at
    # two body sizes -- and the run of a rotated name is the height of its own
    # glyphs. The control's "Y" is a bare capital with no parenthesis, no
    # ascender and no descender, so it is the NARROWEST intact name in the set
    # and every other leg must clear it: 38, 37, 28 and 29 px against the 28 px
    # floor. A cut name loses far more than that margin, which is what makes
    # the floor worth having and what the break test below shows.
    for (leg in c("margin_st", "margin_db", "margin_plain", "margin_panel")) {
        run_px <- an(paste0(leg, "_name_run_px"))
        left_px <- an(paste0(leg, "_name_left_px"))
        check_true(ID,
            sprintf("%s: the axis name is the whole name, not cut at the image edge (%s px of ink starting at column %s, floor %s px)",
                    leg, av(paste0(leg, "_name_run_px")),
                    av(paste0(leg, "_name_left_px")), av("margin_plain_name_run_px")),
            is.finite(run_px) && is.finite(anchor_run) && anchor_run > 0 &&
            is.finite(left_px) && left_px > 0 && run_px >= anchor_run)
    }
    # -- THE CLAMP, ON A PANEL TOO SMALL TO GIVE THE NAME ROOM -------------
    # A 3 x 2 panel at 7 pt has a hundredth of an inch to give. The shift
    # takes exactly that and stops, so the collision is relieved as far as the
    # panel allows and the figure keeps its size. The alternative -- growing
    # the saved box -- makes a 3 x 2 request into a file that is not 3 x 2,
    # which validate/v32 keeps a pinned inventory of, and is the author's call
    # rather than this procedure's.
    check_true(ID,
        sprintf("a 3 x 2 panel has less room than the labels need, and says so (room %s\", clamped %s)",
                av("margin_panel_room_inch"), av("margin_panel_clamped")),
        identical(av("margin_panel_clamped"), "1"))
    check_true(ID,
        sprintf("and the shift taken is exactly the room there was (%s\" of %s\")",
                av("margin_panel_shift_inch"), av("margin_panel_room_inch")),
        is.finite(an("margin_panel_shift_inch")) &&
        abs(an("margin_panel_shift_inch") - an("margin_panel_room_inch")) < 1e-6)
    # AND THE ORDINARY FIGURES ARE NOWHERE NEAR THE CLAMP, which is what says
    # the trade above is paid only where it has to be.
    check_true(ID,
        sprintf("while a 6 x 4 figure is nowhere near its own limit (%s\" needed of %s\" available)",
                av("margin_db_shift_inch"), av("margin_db_room_inch")),
        identical(av("margin_st_clamped"), "0") &&
        identical(av("margin_db_clamped"), "0") &&
        an("margin_db_shift_inch") < an("margin_db_room_inch") / 2)

    # -- THE PREDICTOR, AGAINST WHAT PRAAT ACTUALLY DRAWS ------------------
    # @emlTickLabelWidth models Praat's automatic mark number where the guard
    # cannot ask for it. The four modelled cases are pinned against the forms
    # measured on 6.6.30, and the two UNMODELLED ones are pinned as empty --
    # because an axis running to 1e9 is labelled "10^9" and a predictor that
    # guessed "1000000000" would shift the axis name on violin_hugevalues,
    # which is a figure that is drawn correctly today.
    check_true(ID, "the label predictor reproduces Praat's own four-digit forms",
        identical(av("ticklabel_auto_neg"), "-33.08") &&
        identical(av("ticklabel_auto_100"), "100") &&
        identical(av("ticklabel_auto_005"), "0.05"))
    check_true(ID, "and takes the plugin's own string when precision is explicit",
        identical(av("ticklabel_explicit"), "100.10") &&
        identical(av("ticklabel_explicit_chars"), "6"))
    check_true(ID,
        "and declines the exponent forms rather than guessing at them",
        identical(av("ticklabel_huge"), "<not modelled>") &&
        identical(av("ticklabel_tiny"), "<not modelled>") &&
        identical(av("ticklabel_huge_mm"), "0") &&
        identical(av("ticklabel_tiny_mm"), "0"))

    # -- THE SAME COLLISION AT A DOOR THIS CHANGE COULD NOT TOUCH ---------
    # AND THE HANDOVER THAT CLOSED IT, which is why this is now an assertion.
    #
    # When this section was written the six categorical draw procedures did
    # not go through @emlDrawAxes at all -- they placed the y-axis name with a
    # bare `Text left` -- and eml-draw-procedures.praat belonged to another
    # agent that turn. So the collision was MEASURED, PRINTED and NOT
    # ASSERTED, on v63 §3e's doctrine: a passing check would have pinned the
    # defect as a contract, and silence is how a finding gets lost between two
    # hands. The printed NOTE named the seven sites and the one-line repair,
    # and warned that the eighth (a panel label, not an axis name) wanted
    # reading before it was changed.
    #
    # It was read, and all seven were repaired the same day. Measured on the
    # same fixture -- a violin of dB values two tenths apart, ticks reading
    # "100.10" against a 10.033 mm label -- the gap went 4 px to 17 px, which
    # is exactly what @emlDrawAxes reaches on the same requirement. The eighth
    # site stayed bare, correctly: it is a facet label in the panel's own
    # margin with no ticks to collide with.
    #
    # The threshold is 7 rather than 17 on purpose. 17 is what this mechanism
    # happens to yield today; the requirement the author gave is "no
    # collision", and pinning the exact number would turn a font-metric change
    # into a red line about nothing. 7 px is comfortably above the 3-4 px that
    # reads as touching and comfortably below what any working fix produces.
    check_true(ID,
        sprintf("the categorical draw paths clear their tick labels too (%s px against a %s mm label)",
                av("margin_cat_gap_px"), av("margin_cat_widest_label_mm")),
        is.finite(an("margin_cat_gap_px")) && an("margin_cat_gap_px") >= 7)
}

check_true(ID, "@emlDrawAxisNameLeft exists and is where the name is placed",
           has(code_graph, "^procedure emlDrawAxisNameLeft:"))
check_true(ID, "the axis orchestrator places the y-axis name through it",
           sum(grepl("@emlDrawAxisNameLeft:", code_graph)) >= 1L)
# AND NO BARE `Text left` SURVIVES IN IT. The guard is worth nothing if the
# orchestrator still draws the name the old way -- which is the shape the first
# version of this change had. Scoped to the procedure body, because
# @emlDrawAxisNameLeft itself contains the bare call by construction.
#
# THERE USED TO BE TWO ORCHESTRATORS. @emlDrawAxesSelective was the second, and
# it had no caller anywhere in the tree while carrying the one live breach of
# PraatGen's font-state invariant in this library: `Font size: titleSize`
# followed by `Text top:`, the pattern the standard prints as WRONG. Dead code
# is where a reader looks for a pattern to copy, so it was removed rather than
# repaired.
for (nm in c("emlDrawAxes")) {
    body <- proc_body(code_graph, nm)
    check_true(ID,
        sprintf("@%s draws no bare Text left of its own", nm),
        length(body) > 0 && !any(grepl("^Text left:", body)))
}
check_true(ID, "the shared marks procedure measures what it drew",
           has(code_graph, "@emlTickLabelWidth:"))
check_true(ID, "and the measurement is seeded before the early exit, not after",
           {
               body <- proc_body(code_graph, "emlDrawAlignedMarksLeft")
               i_seed <- grep("\\.maxWideLabelMM = 0", body)
               i_exit <- grep("goto ALIGNED_LEFT_END", body)
               length(i_seed) >= 1L && length(i_exit) >= 1L &&
                   i_seed[1] < i_exit[1]
           })

# ===========================================================================
# 7. Column_k HOLDS SOURCE COLUMN k -- AUTHOR RULING 5, DOORS 2 AND 3
# ===========================================================================
# `To Table: "row"` puts the manufactured label column in position 1, so a
# header invented from the TABLE position named source column 1 "Column_2" and
# nothing was ever called "Column_1". A user who picks "column 2" out of the
# menu is handed column 1. Every value is real, correctly computed and the
# right length; only the heading is off by one, and nothing in any output
# names a column index.
#
# THE PROBE'S MATRIX IS col * 100 + row, so `value div 100` recovers the
# source column from any cell. Same fixture as validate/v63's, on purpose:
# the two files are checking one repair from two sides and a difference in
# fixtures would be a difference nobody could interpret.
if (have_axes) {
    av <- function(k) if (is.null(ax[[k]])) NA_character_ else ax[[k]]
    an <- function(k) suppressWarnings(as.numeric(av(k)))

    check_true(ID,
        sprintf("the graphs coercion produced a table of %s columns from a 3-column Matrix",
                av("coerce_ncols")),
        identical(av("coerce_ncols"), "4"))
    check_true(ID,
        "position 1 is still the manufactured row-label column, called \"row\"",
        identical(av("coerce_pos1_header"), "row"))
    check_true(ID,
        sprintf("and it holds r1..rn, not bare integers (%s, %s, ...)",
                av("coerce_rowlabel_1"), av("coerce_rowlabel_2")),
        identical(av("coerce_rowlabel_1"), "r1") &&
        identical(av("coerce_rowlabel_2"), "r2") &&
        identical(av("coerce_rowlabel_4"), "r4"))

    # THE MAPPING, WHICH IS THE FINDING. Read the header at each data
    # position, read the cell under it, and ask whether the number in the
    # name is the number of the source column the value came from.
    kmap <- vapply(2:4, function(i) {
        h <- av(sprintf("coerce_pos%d_header", i))
        v <- suppressWarnings(as.numeric(av(sprintf("coerce_pos%d_row1", i))))
        if (is.na(h) || !grepl("^Column_[0-9]+$", h) || !is.finite(v))
            return(NA_integer_)
        as.integer(as.integer(sub("^Column_", "", h)) - (v %/% 100))
    }, integer(1))
    check_true(ID,
        sprintf("every data column got a manufactured header (%s, %s, %s)",
                av("coerce_pos2_header"), av("coerce_pos3_header"),
                av("coerce_pos4_header")),
        !any(is.na(kmap)))
    check_true(ID,
        "Column_k holds SOURCE column k -- the number in the name is the user's, not the table's",
        !any(is.na(kmap)) && all(kmap == 0L))
    # AND IT STARTS AT 1. Said separately because it is the half that
    # "consecutive and distinct" would pass: 2, 3, 4 is consecutive and
    # distinct and is exactly the defect.
    check_true(ID,
        sprintf("the numbering starts at 1, not at the label column (%s)",
                av("coerce_pos2_header")),
        identical(av("coerce_pos2_header"), "Column_1"))
}

check_true(ID, "the header repair numbers by source index, not by table position",
           has(code_graph, "\"Column_\" \\+ string\\$ \\(.iCol - .insertedCols\\)"))
check_true(ID, "and the loop starts after the inserted block, so Column_0 cannot exist",
           has(code_graph, "for .iCol from .insertedCols \\+ 1 to .nCols"))
# ONE REPAIR, TWO DOORS. The describe wrapper does not rename headers itself;
# it calls the shared procedure. If that ever stops being true this file's
# live evidence covers one door and silently stops covering the other, which
# is the failure mode of every check that tests a shared thing at one caller.
check_true(ID, "the describe wrapper is present to be checked",
           file.exists(f_desc))
code_desc <- read_code(f_desc)
check_true(ID,
    "and it routes its header repair through the same procedure (one repair, two doors)",
    has(code_desc, "@emlCleanConvertedTable:"))
check_true(ID,
    "and invents no Column_ name of its own",
    !has(code_desc, "\"Column_\""))

# ===========================================================================
# 8. ONE PRESS, ONE DERIVED SOUND -- AUTHOR RULING 8b
# ===========================================================================
# The stereo gate keeps the extracted channel Sound on purpose: it is what the
# figure is drawn from and what "Draw Another" needs. What it did NOT do was
# collect the one the last press made, so three figures from one recording
# left three Sounds sharing one name -- and `selectObject: "Sound take_ch1"`
# then answers with one of the three with no way to say which. That is the
# duplicate-name mechanism of S1 in the object list rather than in a column
# menu, and ruling 8a fixed the same shape at the stats door.
if (have_stereo) {
    sv <- function(k) if (is.null(st[[k]])) NA_character_ else st[[k]]

    check_true(ID,
        sprintf("the gate was pressed three times on one stereo Sound (%s dialogs answered)",
                sv("gate_repeat_dialogs_answered")),
        identical(sv("gate_repeat_dialogs_answered"), "3"))
    check_true(ID,
        sprintf("after every press there is exactly ONE derived Sound (%s, %s, %s)",
                sv("repeat_press1_derived"), sv("repeat_press2_derived"),
                sv("repeat_press3_derived")),
        identical(sv("repeat_press1_derived"), "1") &&
        identical(sv("repeat_press2_derived"), "1") &&
        identical(sv("repeat_press3_derived"), "1"))
    # AND THE USER'S RECORDING SURVIVED ALL THREE. A cleanup that collected
    # the source would pass the check above and be a far worse defect than
    # the clutter it tidied.
    check_true(ID,
        "and the user's own stereo recording is still there after all three",
        identical(sv("repeat_press1_source_present"), "1") &&
        identical(sv("repeat_press3_source_present"), "1"))
    # THE NAME IS THE PLUGIN'S OWN, and that is what makes the collection
    # safe. A user who extracted the left channel by hand has "take_ch1"; the
    # gate's object is "eml_take_ch1", and only the prefixed name is ever
    # removed.
    check_true(ID,
        sprintf("the derived Sound carries the plugin's own prefix (%s)",
                sv("repeat_press3_result_name")),
        grepl("^eml_", sv("repeat_press3_result_name") %or% ""))
}

check_true(ID, "@emlDropStaleChannelSounds exists",
           has(code_graph, "^procedure emlDropStaleChannelSounds:"))
check_true(ID, "the gate calls it, and the gate is the only caller that needs to",
           {
               body <- proc_body(code_graph, "emlGraphsChannelGate")
               length(body) > 0 &&
                   any(grepl("@emlDropStaleChannelSounds:", body))
           })
check_true(ID, "and the gate names its derived Sound with the eml_ prefix",
           {
               body <- proc_body(code_graph, "emlGraphsChannelGate")
               length(body) > 0 &&
                   any(grepl("Rename: \"eml_\" \\+ selected\\$ \\(\"Sound\"\\)", body))
           })
# IT ONLY EVER REMOVES A PREFIXED NAME. A drop that matched Praat's own
# "<name>_ch1" would delete a channel the user extracted by hand from the
# Objects window -- their work, destroyed to tidy up after a figure.
check_true(ID, "and the drop only ever names an eml_-prefixed object",
           {
               body <- proc_body(code_graph, "emlDropStaleChannelSounds")
               length(body) > 0 &&
                   sum(grepl("\\.cand\\$ = \"eml_\" \\+ .sourceName\\$", body)) == 3L
           })

# ===========================================================================
# 9. THE ONE-BIN SPECTRUM -- AUTHOR RULING 8c, CHASED AND MEASURED
# ===========================================================================
# NOT ASSERTED AS FIXED, AND THE REASON IS ON PURPOSE. The author asked what
# the right behaviour is -- draw the single bin, widen the range, or refuse
# with a message -- and said that if the answer needs him, nothing is to be
# implemented. It needs him. What this section does instead is what v63's §3e
# does for a convention it is not allowed to change: MEASURE, PRINT, and carry
# the routing note in the run itself, because the two things it must not be
# are a passing check (which pins a defect as a contract) or silence (which is
# how a finding gets lost between two hands).
#
# WHAT WAS MEASURED, on 6.6.30, 15 August 2026:
#
#   * The range the auditor filed, 999.4 to 1000.2 Hz over a Spectrum of a
#     1 s tone, contains EXACTLY ONE bin -- bin width 0.6729 Hz.
#   * Praat's `Draw:` needs two bins to draw a line. At one it draws nothing
#     at all, and the plugin's own frame, ticks, gridlines and axis names are
#     drawn regardless, so the page carries a complete and entirely empty
#     figure.
#   * The bin that is not drawn holds 81.9 dB. It is the peak of the tone --
#     the loudest thing in the file. The empty frame is not "no energy here";
#     it is the strongest signal in the recording, rendered as nothing.
#   * The same figure with TWO bins in range draws normally, so the mode is
#     the bin count and not the draw path.
#
# WHY THIS IS NOT A ONE-LINE FIX, which is the part that needs the author:
#
#   DRAW THE SINGLE BIN would need a new drawing vocabulary in a procedure
#   that draws lines -- a stem or a marker -- and a figure whose appearance
#   changes shape at a threshold the reader cannot see.
#   WIDEN THE RANGE contradicts a ruling already implemented in this file:
#   NEW-G8-1 established that a typed range is a VIEWPORT and section 3 above
#   asserts that the drawn frame is the range the user typed and not a
#   widened one. Silently widening here would make that check a lie.
#   REFUSE WITH A MESSAGE is consistent with the disclosure doctrine
#   (@emlDiscloseClipped names what was withheld rather than hiding it), but
#   it means a press of Draw that produces no figure at all, and whether that
#   is right for a singing teacher at a console is a UX call, not a
#   correctness one.
#
# AND IT IS NOT IN THIS CHANGE'S FILES EITHER. @emlDrawSpectrum lives in
# plugin/graphs/eml-draw-procedures.praat, which is not this hand's to edit;
# adding a guard procedure to the library that nothing calls would reproduce
# exactly the defect this file was written for -- see the stereo ruling at the
# top, three correct procedures with zero callers for months.
if (have_axes) {
    av <- function(k) if (is.null(ax[[k]])) NA_character_ else ax[[k]]
    an <- function(k) suppressWarnings(as.numeric(av(k)))

    if (identical(av("onebin_interior_ink"), "0")) {
        cat(paste0(
            "      NOTE v62: THE ONE-BIN SPECTRUM IS STILL AN EMPTY FRAME.\n",
            "            Ruling 8c, chased and measured, NOT repaired -- the\n",
            "            author's own instruction if the answer needs him.\n",
            sprintf("            999.4-1000.2 Hz holds %s bin of %s Hz; the bin\n",
                    av("onebin_bins_in_range"), av("onebin_bin_width")),
            sprintf("            that is not drawn holds %s dB, the peak of the\n",
                    av("onebin_peak_db")),
            "            tone. Two bins in the same range draw normally\n",
            sprintf("            (%s ink pixels against %s).\n",
                    av("twobin_interior_ink"), av("onebin_interior_ink")),
            "            THE CHOICE IS THE AUTHOR'S: draw the bin as a stem,\n",
            "            or refuse with a message naming the bin width. It\n",
            "            cannot be \"widen the range\" -- NEW-G8-1 already ruled\n",
            "            that a typed range is a viewport, and section 3 of\n",
            "            this file asserts the frame is what the user typed.\n",
            "            THE SITE: @emlDrawSpectrum, plugin/graphs/\n",
            "            eml-draw-procedures.praat:1129 (the bare `Draw:`).\n"))
    }
    attest(ID,
           sprintf("the one-bin spectrum was measured: %s bin in range, %s ink pixels inside the frame, %s dB not shown",
                   av("onebin_bins_in_range"), av("onebin_interior_ink"),
                   av("onebin_peak_db")),
           "driven live through @emlDrawSpectrum; not asserted either way -- ruling 8c is with the author")

    # WHAT IS ASSERTED EITHER WAY: that the probe is still a probe. If the
    # range stopped holding one bin, or the two-bin control stopped drawing,
    # the measurement above would be about something else and the note would
    # be misinformation.
    check_true(ID,
        sprintf("the one-bin probe still holds exactly one bin (%s, width %s Hz)",
                av("onebin_bins_in_range"), av("onebin_bin_width")),
        identical(av("onebin_bins_in_range"), "1"))
    check_true(ID,
        sprintf("and the two-bin control still draws (%s ink pixels)",
                av("twobin_interior_ink")),
        identical(av("twobin_bins_in_range"), "2") &&
        is.finite(an("twobin_interior_ink")) && an("twobin_interior_ink") > 100)
    check_true(ID,
        sprintf("and the bin the empty frame hides is the loudest in the file (%s dB)",
                av("onebin_peak_db")),
        is.finite(an("onebin_peak_db")) && an("onebin_peak_db") > 60)
}

if (!exists("EML_SUITE")) {
    eml_report(paste0("v62 graphs axes and channels: the stereo choice is reachable, ",
                      "the axis is readable, the frame clips, the panel moves, ",
                      "the axis name clears its ticks and Column_k is column k"))
    eml_exit()
}
