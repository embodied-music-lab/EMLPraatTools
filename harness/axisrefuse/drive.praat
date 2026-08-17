# ============================================================================
# harness/axisrefuse/drive.praat — the object and the entry point, and nothing
# else
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# ONE LEG PER PRAAT PROCESS, chosen by $EML_AR_LEG. This file creates the
# object the leg needs, names the graph type the leg is about, and calls
# @emlGraphsWorkflow. Everything after that call is the shipped form: its
# dialogs, its loop, its range validation, its draw. run.sh presses the keys.
#
# WHY IT DOES NOT SET THE RANGES ITSELF. The pair under test has to arrive at
# the validation the way a user's pair arrives — typed into the dialog field
# whose label the refusal quotes. The form's own persistence variables are
# initialised inside @emlGraphsWorkflow, behind its first-call sentinel, so
# there is no seam to write them through from out here even if writing them
# were the right test. run.sh types into the field.
#
# WHAT IT WRITES, AFTER THE WORKFLOW RETURNS: one line per fact, to
# $EML_AR_OUT. The workflow returns only when the user presses Done, so a leg
# whose marker is missing is a leg that hung, and the validator can tell that
# from a leg that finished with the wrong answer.
#
# Env in:  EML_AR_LEG   leg name
#          EML_AR_OUT   TSV to append to
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

@emlInitDrawingDefaults

leg$ = environment$ ("EML_AR_LEG")
out$ = environment$ ("EML_AR_OUT")

procedure emit: .key$, .value$
    if out$ <> ""
        appendFileLine: out$, .key$, tab$, .value$
    endif
endproc

# ---------------------------------------------------------------------------
# THE FIXTURES. Deterministic — a linear congruential stream rather than
# randomGauss, so a leg re-driven tomorrow meets the same numbers and a
# refusal quoted in the validator is the refusal the next run produces.
# ---------------------------------------------------------------------------
procedure arSound
    Create Sound from formula: "arsnd", 1, 0, 1.0, 22050,
    ... "0.4 * sin (2*pi*220*x) + 0.1 * sin (2*pi*440*x)"
    .id = selected ("Sound")
endproc

procedure arTable
    Create Table with column names: "ar", 0, "grp val xval"
    .row = 0
    .rng = 20260817
    for .g from 1 to 3
        for .k from 1 to 12
            .rng = (1103515245 * .rng + 12345) mod 2147483648
            .u = .rng / 2147483648
            .row = .row + 1
            Append row
            Set string value: .row, "grp", "Cohort " + string$ (.g)
            Set numeric value: .row, "val", 200 + .g * 12 + (.u - 0.5) * 14
            Set numeric value: .row, "xval", 100 + .k * 3 + (.u - 0.5) * 4
        endfor
    endfor
    .id = selected ("Table")
endproc

# ---------------------------------------------------------------------------
# THE LEGS. Each names the graph type it is about and hands over. The pair the
# leg is about is typed by run.sh into the page this type opens.
# ---------------------------------------------------------------------------
objId = 0
if leg$ = "pitch_time" or leg$ = "pitch_freq"
    @arSound
    objId = arSound.id
    emlGraphsPresetType = 1
elsif leg$ = "wave_amp"
    @arSound
    objId = arSound.id
    emlGraphsPresetType = 2
elsif leg$ = "spec_power"
    @arSound
    objId = arSound.id
    emlGraphsPresetType = 3
elsif leg$ = "box_value" or leg$ = "box_bound"
    @arTable
    objId = arTable.id
    emlGraphsPresetType = 9
elsif leg$ = "scatter_xy"
    @arTable
    objId = arTable.id
    emlGraphsPresetType = 8
else
    exitScript: "axisrefuse: unknown leg '" + leg$ + "'"
endif

@emit: "leg_object", string$ (objId)
selectObject: objId
@emlGraphsWorkflow: objId

# REACHED ONLY BY PRESSING Done ON THE POST-DRAW DIALOG. A leg that was
# refused and never corrected never gets here, and the absence of this line is
# how the validator tells a hang from a finish.
@emit: "leg_returned", leg$
@emit: "leg_axis", string$ (emlGraphsAxisYReqMin) + ".." +
... string$ (emlGraphsAxisYReqMax)
