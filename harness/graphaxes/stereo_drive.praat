# ============================================================================
# harness/graphaxes/stereo_drive.praat — the stereo gate, driven
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# One leg per run, chosen by $EML_STEREO_LEG, because a Praat script error
# aborts the script: three legs in one process report one failure and hide the
# other two. Results are appended to $EML_STEREO_OUT as key<TAB>value.
#
# THE FIXTURE is the verifier's: 220 Hz in the left channel, 330 Hz in the
# right. It is chosen so that the WRONG answer is unmistakable. Praat's silent
# mixdown of those two produces a signal whose fundamental is 110 Hz — the
# greatest common divisor of the two components, an F0 that is in neither
# channel and that nobody sang. A pitch track near 110 is the defect; a pitch
# track near 220 or 330 is a channel the user chose.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================

include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

@emlInitDrawingDefaults

leg$ = environment$ ("EML_STEREO_LEG")
out$ = environment$ ("EML_STEREO_OUT")
if out$ = ""
    exitScript: "EML_STEREO_OUT unset."
endif

procedure emit: .key$, .value$
    appendFileLine: out$, .key$, tab$, .value$
endproc

procedure makeStereo
    .id = Create Sound from formula: "stereoTone", 2, 0, 1.0, 44100,
    ... "if row = 1 then 0.4*sin(2*pi*220*x) else 0.4*sin(2*pi*330*x) fi"
endproc

procedure makeMono
    .id = Create Sound from formula: "monoTone", 1, 0, 1.0, 44100,
    ... "0.4*sin(2*pi*220*x)"
endproc

# Mean F0 of a Sound, through the plugin's own canonical pitch call.
procedure meanF0: .soundId
    selectObject: .soundId
    .pit = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "yes",
    ... 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
    .f0 = Get mean: 0, 0, "Hertz"
    removeObject: .pit
endproc

@emit: "leg", leg$

# ---------------------------------------------------------------------------
# GATE_WAVEFORM — a stereo Sound about to be drawn as a waveform.
# The driver answers the dialog; this leg records what came back.
# ---------------------------------------------------------------------------
if leg$ = "gate_waveform"
    @makeStereo
    snd = makeStereo.id
    @emit: "source_channels", string$ (2)
    @emlGraphsChannelGate: snd, "waveform"
    result = emlGraphsChannelGate.resultId
    @emit: "was_converted", string$ (emlGraphsChannelGate.wasConverted)
    @emit: "choice", emlGraphsChannelGate.choice$
    selectObject: result
    resultName$ = selected$ ("Sound")
    resultCh = Get number of channels
    @emit: "result_name", resultName$
    @emit: "result_channels", string$ (resultCh)
    # The user's own object must still be there. Deleting what they selected
    # in order to draw a graph is not a trade this flow may make.
    selectObject: snd
    origCh = Get number of channels
    @emit: "original_still_present", string$ (origCh)

# ---------------------------------------------------------------------------
# GATE_PITCH — the ruling's parenthesis. A stereo Sound handed to the shipped
# conversion procedure on its way to a pitch contour.
# ---------------------------------------------------------------------------
elsif leg$ = "gate_pitch"
    @makeStereo
    snd = makeStereo.id
    selectObject: snd
    @emlConvertForGraph: snd, "Pitch", 75, 600
    pit = emlConvertForGraph.result
    @emit: "pitch_created", string$ (pit > 0)
    if pit > 0
        selectObject: pit
        pMean = Get mean: 0, 0, "Hertz"
        @emit: "pitch_mean", fixed$ (pMean, 4)
    endif

# ---------------------------------------------------------------------------
# MONO_SILENT — the same call on a mono Sound must ask NOTHING. A gate that
# interrupts every ordinary recording would be its own defect.
# ---------------------------------------------------------------------------
elsif leg$ = "mono_silent"
    @makeMono
    snd = makeMono.id
    selectObject: snd
    @emlConvertForGraph: snd, "Pitch", 75, 600
    pit = emlConvertForGraph.result
    @emit: "pitch_created", string$ (pit > 0)
    if pit > 0
        selectObject: pit
        pMean = Get mean: 0, 0, "Hertz"
        @emit: "pitch_mean", fixed$ (pMean, 4)
    endif

# ---------------------------------------------------------------------------
# UNGATED — what the plugin did before this work, pinned as a number. No
# dialog, no choice: the stereo Sound goes straight into To Pitch and Praat
# mixes it down on its own.
# ---------------------------------------------------------------------------
elsif leg$ = "ungated"
    @makeStereo
    snd = makeStereo.id
    @meanF0: snd
    @emit: "ungated_mean_f0", fixed$ (meanF0.f0, 4)

# ---------------------------------------------------------------------------
# CHOICES — the three arms of the ruling, applied mechanically with no UI, so
# that the F0 each one produces is on the record next to the ungated one.
# ---------------------------------------------------------------------------
elsif leg$ = "choices"
    for c from 1 to 3
        @makeStereo
        snd = makeStereo.id
        emlChannelKeepOriginal = 1
        @emlApplyChannelChoice: snd, c
        emlChannelKeepOriginal = 0
        got = emlApplyChannelChoice.resultId
        @emit: "choice_" + string$ (c) + "_label",
        ... emlApplyChannelChoice.choice$
        selectObject: got
        gotCh = Get number of channels
        @emit: "choice_" + string$ (c) + "_channels", string$ (gotCh)
        @meanF0: got
        @emit: "choice_" + string$ (c) + "_mean_f0", fixed$ (meanF0.f0, 4)
        select all
        Remove
    endfor

else
    @emit: "error", "unknown leg"
endif

@emit: "completed", "1"

# THE GUI LEGS RUN UNDER --new-send, which starts the WINDOWED build and
# leaves it running when the script ends. Quitting from the script itself is
# what makes a leg terminate on its own rather than be killed on a timeout,
# and a leg that had to be killed cannot be told from one that hung.
if leg$ = "gate_waveform" or leg$ = "gate_pitch" or leg$ = "mono_silent"
    Quit
endif
