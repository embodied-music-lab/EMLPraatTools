# ============================================================================
# harness/pitchrefuse/drive.praat — the object and the entry point, and
# nothing else
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# ONE LEG PER PRAAT PROCESS, chosen by $EML_PR_LEG. Both legs this rig knows
# about open the Pitch Contour page from a Sound source, which is the only
# source that renders the pitch floor/ceiling row. This file creates that
# Sound, names the graph type, and calls @emlGraphsWorkflow. Everything after
# that call is the shipped form: its dialogs, its loop, its pitch-range
# refusal, its draw. run.sh presses the keys.
#
# WHY IT DOES NOT SET THE PAIR ITSELF. Same reasoning as
# harness/axisrefuse/drive.praat: the pair under test has to arrive the way a
# user's pair arrives, typed into the field the refusal quotes. run.sh types
# into the field.
#
# Env in:  EML_PR_LEG   leg name
#          EML_PR_OUT   TSV to append to
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
include ../../plugin/graphs/eml-graphs-form.praat

@emlInitializeDrawingDefaults

leg$ = environment$ ("EML_PR_LEG")
out$ = environment$ ("EML_PR_OUT")

procedure emit: .key$, .value$
    if out$ <> ""
        appendFileLine: out$, .key$, tab$, .value$
    endif
endproc

# ---------------------------------------------------------------------------
# THE FIXTURE. Same synthesised tone as axisrefuse's arSound — deterministic,
# and it auto-converts to a Pitch object on entry to the Pitch Contour page,
# which is what puts the floor/ceiling row on screen.
# ---------------------------------------------------------------------------
procedure prSound
    Create Sound from formula: "prsnd", 1, 0, 1.0, 22050,
    ... "0.4 * sin (2*pi*220*x) + 0.1 * sin (2*pi*440*x)"
    .id = selected ("Sound")
endproc

if leg$ = "pitch_range_reversed" or leg$ = "pitch_range_ok"
    @prSound
    objId = prSound.id
    emlGraphsPresetType = 1
else
    exitScript: "pitchrefuse: unknown leg '" + leg$ + "'"
endif

@emit: "leg_object", string$ (objId)
selectObject: objId
@emlGraphsWorkflow: objId

# REACHED ONLY BY PRESSING Done ON THE POST-DRAW DIALOG. A leg refused and
# never corrected never gets here.
@emit: "leg_returned", leg$
