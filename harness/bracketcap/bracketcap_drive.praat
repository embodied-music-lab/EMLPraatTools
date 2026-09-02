# ============================================================================
# harness/bracketcap/bracketcap_drive.praat — does the bracket layout say what
#                                             produced the p-values on it?
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# One leg per process (see bracketcap.sh), because a Praat script error aborts
# the script: seven legs in one process report one failure and hide six.
#
# THIS DRIVE CALLS THE SHIPPED FORM, IT DOES NOT TRANSCRIBE IT, and that is
# the same lesson harness/disclosure/probe_formpath.praat is a rewrite of. The
# annotation caption is rendered from inside @emlDrawAnnotations, which the
# graphs form calls from @emlGraphsPostDispatchAnnotations — so this file sets
# up the globals the earlier stages of the form would have produced (that is
# fixture) and then calls @emlGraphsPostDispatchAnnotations (that is the code
# under test). A hand-copied post-dispatch block would exercise a corrected
# copy of the form and pass while the shipped one did nothing.
#
# EVERY NUMBER IS EMITTED AS key<TAB>value TO $EML_BC_OUT, AND THE PICTURE IS
# SAVED ANYWAY. The emitted values say what the plugin BELIEVES it drew —
# which line, at what size, how wide against how much room. They cannot say
# whether the words are in the file: a caption measured as fitting and then
# cropped off the export by an extent tracker that was never told about the
# band emits exactly the same numbers as one that is there. bracketcap.sh
# reads the words back off the PNG with tesseract, and validate/v69 asserts on
# both. Neither half is sufficient and the file says so in its own header.
#
# NO DISPLAY IS BOUND AND NONE IS NEEDED. Nothing on this path calls
# beginPause:; bracketcap.sh unsets DISPLAY for every leg rather than merely
# ignoring it, so an X server appearing or disappearing cannot change a
# verdict.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ============================================================================

; Relative, and it resolves against the TOP-LEVEL script's folder — this
; file's own folder, two levels below the repository root, the same depth as
; harness/stress_cases/. An absolute path here would mean a shadow copy of the
; repository silently tested the ORIGINAL tree, which is the defect
; harness/_env.sh exists to describe. The break tests below depend on this
; being relative: they run a COPY of the tree.
include ../stress_cases/_prelude.praat
; The form, for @emlGraphsPostDispatchAnnotations. The prelude leaves it out
; on purpose — it is the interactive wrapper — but here it IS the thing under
; test. It is includable because it is a library: top-level code is array
; initialisation only, there is no form: or beginPause: at top level, and
; @emlGraphsWorkflow is never called from within it.
include ../../plugin/graphs/eml-graphs-form.praat

; Praat converts a file to UTF-16 the moment a non-ASCII character is written
; into it unless told otherwise, and the caption this drive emits contains an
; em-dash. Measured on harness/drawlayer 15 August 2026: half the TSV came
; back UTF-16 and every key in it read as "l e g" with NULs between the
; letters, which a validator cannot tell from a harness that never ran.
Text writing preferences: "UTF-8"

leg$ = environment$ ("EML_BC_LEG")
out$ = environment$ ("EML_BC_OUT")
pic$ = environment$ ("EML_BC_PIC")
if out$ = ""
    exitScript: "EML_BC_OUT unset."
endif
if leg$ = ""
    exitScript: "EML_BC_LEG unset."
endif

procedure emit: .key$, .value$
    appendFileLine: out$, .key$, tab$, .value$
endproc

# ---------------------------------------------------------------------------
# THE FIXTURE IS DETERMINISTIC AND IT IS NOT randomGauss.
#
# Two legs differ only in the correction the user picked, and the whole point
# of that pair is that the caption changes and nothing else does. An unseeded
# generator makes that comparison meaningless. A linear congruential sequence
# written out in Praat is reproducible across processes, across machines and
# across Praat versions, which none of Praat's own generators promises.
#
# .sep is the between-group separation. The significant legs need an omnibus
# under alpha, because the bracket path is only reached when the omnibus
# rejects — that is not a convenience of the fixture, it is the shipped gate.
# The ns leg sets .sep to zero for the same reason, from the same builder.
# ---------------------------------------------------------------------------
procedure fixture: .name$, .nGroups, .sep
    .t = Create Table with column names: .name$, 0, "grp val"
    .st = 20260816
    .r = 0
    for .g from 1 to .nGroups
        for .k from 1 to 12
            .st = (1103515245 * .st + 12345) mod 2147483648
            .r = .r + 1
            Append row
            Set string value: .r, "grp", "Cohort " + string$ (.g)
            Set numeric value: .r, "val",
            ... 100 + .g * .sep + (.st / 2147483648 - 0.5) * 4
        endfor
    endfor
    .id = .t
endproc

# ---------------------------------------------------------------------------
# @formScope — the form-scope globals @emlGraphsPostDispatchAnnotations reads
# and does not set for itself. Supplying these is FIXTURE; everything from
# @emlGraphsPostDispatchAnnotations onward is shipped code, unmodified.
#
# matrixPanelHeight is zero on every leg here on purpose: the matrix panel is
# the layout that ALREADY discloses, and this file is about the one that did
# not. A leg that drew a panel would be testing ruling 1b again, which
# validate/v66 owns.
# ---------------------------------------------------------------------------
procedure formScope: .w, .h
    annotate = 1
    graph_type = 7
    annotMatrixN = 0
    matrixPanelHeight = 0
    matrixGap = 0
    figure_width = .w
    figure_height = .h
    totalCanvasHeight = .h
    colorMode$ = "color"
endproc

# ---------------------------------------------------------------------------
# @drawLikeTheForm — the stage before the one under test, built out of the
# form's own procedures rather than out of a copy of their arithmetic.
#
# The pre-dispatch stage resolves the y-range and buys headroom for the
# brackets. Skipping it draws the brackets across the title, which would read
# as a defect in the artefact rather than as a gap in the fixture. Two draws,
# and the first is thrown away, for the reason @emlGraphsDrawWithLegendRoom
# gives at length: the theme constants these procedures need (targetTicksY,
# annotSize) do not exist until a figure has been drawn once.
# ---------------------------------------------------------------------------
procedure drawLikeTheForm: .tbl, .title$, .w, .h
    Erase all
    @emlDrawViolinPlot: .tbl, .title$, "Cohort", "Power (dB)", .w, .h,
    ... "color", 1, "grp", "val", 0, 0
    @emlGraphsColumnExtent: .tbl, "val"
    .visMax = emlGraphsColumnExtent.max
    .visMin = emlGraphsColumnExtent.min
    @emlComputeNiceStep: .visMax - .visMin, emlSetAdaptiveTheme.targetTicksY
    @emlComputeAxisRange: .visMin, .visMax, emlComputeNiceStep.step, 0
    valueMin = emlComputeAxisRange.axisMin
    valueMax = emlComputeAxisRange.axisMax
    if annotBracketN > 0
        @emlComputeAnnotationHeadroom: valueMax - valueMin,
        ... emlSetAdaptiveTheme.annotSize, 0, ""
        valueMax = valueMax + emlComputeAnnotationHeadroom.headroom
    endif
    dataYMax_forAnnotation = .visMax
    Erase all
    ; The first pass's disclosures are thrown away with the first pass.
    ; @emlDiscloseBegin appends from the running annotBlockN rather than
    ; resetting it, so without this every line in the corner box appears
    ; twice — which is what the form itself does through legendRoomBlockN.
    annotBlockN = 0
    @emlDrawViolinPlot: .tbl, .title$, "Cohort", "Power (dB)", .w, .h,
    ... "color", 1, "grp", "val", valueMin, valueMax
endproc

# ---------------------------------------------------------------------------
# @runLeg — bridge, form post-dispatch, emit, save.
#
# .layout is passed straight to @emlRunAnnotationComparison: 2 forces brackets,
# which is what every leg here wants. Forcing rather than relying on the k<=2
# auto rule is deliberate — the defect is in the BRACKET layout and the
# ruling is about bracket figures, and a user can select "Brackets" from the
# form's layout menu at any k.
# ---------------------------------------------------------------------------
procedure runLeg: .tbl, .title$, .w, .h, .test$, .layout, .correction$
    @emlClearAnnotations
    @formScope: .w, .h
    if .correction$ <> ""
        annotCorrectionMethod$ = .correction$
    endif
    @emlRunAnnotationComparison: .tbl, "val", "grp", 0.05, "stars", 0, 1,
    ... .test$, .layout
    @emit: "bridge_error", emlRunAnnotationComparison.error$
    @emit: "bracket_n", string$ (annotBracketN)
    @emit: "matrix_n", string$ (annotMatrixN)
    ; The two halves as the BRIDGE left them, before anything draws. Emitted
    ; separately from what was drawn so a caption that is composed correctly
    ; and then rendered as something else is visible as a disagreement rather
    ; than as one string that happens to be wrong.
    ;
    ; GUARDED, AND THE GUARD IS LOAD-BEARING. This drive has to be runnable
    ; against a tree that does not have the fix — that is what the before/after
    ; reproduction is, and it is what half the breaks in break.sh do, since
    ; deleting the globals is one of the ways the disclosure can be lost. An
    ; unguarded read aborts the leg at this line, no PNG is written, and every
    ; verdict downstream reads NO_FIGURE: a defect that removes the caption
    ; would be indistinguishable from a harness that crashed.
    if variableExists ("annotBracketPosthoc$")
        @emit: "posthoc", annotBracketPosthoc$
    else
        @emit: "posthoc", ""
    endif
    if variableExists ("annotBracketAdjust$")
        @emit: "adjust", annotBracketAdjust$
    else
        @emit: "adjust", ""
    endif
    ; THE CORNER-BOX LINE AS THE BRIDGE LEFT IT, AND IT HAS TO BE READ HERE
    ; RATHER THAN AFTER THE DRAW. @emlGraphsPostDispatchAnnotations CONSUMES
    ; annotTextN -- it moves the line into annotBlockLabel$[] and sets
    ; annotTextN = 0 so the box is not drawn twice -- so a read taken after
    ; the post-dispatch stage reports zero on every leg and cannot tell a
    ; bridge that set nothing from a form that routed it correctly.
    ;
    ; AUTHOR RULING C, 16 August 2026, is what this pair is for: every arm of
    ; @emlRunAnnotationComparison that can produce a bracket names its test, and
    ; validate/v76 pins the string composed HERE against the words tesseract
    ; reads off the figure. Two-group figures set neither of these before
    ; ruling C, which is why the label is guarded on the count: the drive has
    ; to survive being pointed at a tree that does not have the fix, or the
    ; break rig cannot tell a defect from a crashed harness.
    @emit: "text_n", string$ (annotTextN)
    if annotTextN > 0
        @emit: "text_label", annotTextLabel$[1]
        @emit: "text_anchor", annotTextAnchor$[1]
    else
        @emit: "text_label", ""
        @emit: "text_anchor", ""
    endif
    ; The bridge runs FIRST, as the form runs it, so the pre-dispatch stage
    ; below can buy the brackets their headroom on the same pass that resolves
    ; the axis. Drawing first and bridging afterwards would put the brackets
    ; across the title.
    @drawLikeTheForm: .tbl, .title$, .w, .h
    @emlGraphsPostDispatchAnnotations
    ; NOT-RUN AND RAN-AND-DREW-NOTHING ARE DIFFERENT VERDICTS AND ARE EMITTED
    ; AS DIFFERENT VALUES. @emlDrawAnnotations is only entered when there are
    ; brackets, so on the ns_omnibus leg @emlDrawBracketCaption never runs at
    ; all and its outputs do not exist — reading them would abort the leg with
    ; "Unknown variable" and lose every key after it. cap_ran = 0 says the
    ; procedure was never reached; cap_ran = 1 with cap_drawn = 0 says it ran
    ; and correctly decided there was nothing to say. A validator that could
    ; not tell those apart would accept a silent abort as a passing NS figure.
    if variableExists ("emlDrawBracketCaption.drawn")
        @emit: "cap_ran", "1"
        @emit: "cap_drawn", string$ (emlDrawBracketCaption.drawn)
        @emit: "cap_lines", string$ (emlDrawBracketCaption.lines)
        @emit: "cap_size_pt", fixed$ (emlDrawBracketCaption.size, 3)
        @emit: "cap_width_mm", fixed$ (emlDrawBracketCaption.widthMM, 3)
        @emit: "cap_avail_mm", fixed$ (emlDrawBracketCaption.availMM, 3)
        @emit: "cap_line1", emlDrawBracketCaption.text1$
        @emit: "cap_line2", emlDrawBracketCaption.text2$
        @emit: "cap_top_in", fixed$ (emlDrawBracketCaption.top, 5)
        @emit: "cap_bottom_in", fixed$ (emlDrawBracketCaption.bottom, 5)
    else
        @emit: "cap_ran", "0"
        @emit: "cap_drawn", "0"
        @emit: "cap_lines", "0"
        @emit: "cap_size_pt", "0.000"
        @emit: "cap_width_mm", "0.000"
        @emit: "cap_avail_mm", "0.000"
        @emit: "cap_line1", ""
        @emit: "cap_line2", ""
        @emit: "cap_top_in", "0.00000"
        @emit: "cap_bottom_in", "0.00000"
    endif
    ; The saved image is the extent box, not the figure box, and the crop
    ; arithmetic in bracketcap.sh needs both corners of it in inches. Read off
    ; the tracker the export itself reads.
    @emit: "extent_min_x_in", fixed$ (emlDrawnMinX, 5)
    @emit: "extent_max_x_in", fixed$ (emlDrawnMaxX, 5)
    @emit: "extent_min_y_in", fixed$ (emlDrawnMinY, 5)
    @emit: "extent_max_y_in", fixed$ (emlDrawnMaxY, 5)
    @emit: "figure_h_in", fixed$ (.h, 5)
    @emit: "figure_w_in", fixed$ (.w, 5)
    if pic$ <> ""
        select all
        .nSel = numberOfSelected ()
        if .nSel > 0
            Remove
        endif
        @emlAssertFullViewport
        Save as 300-dpi PNG file: pic$
    endif
endproc

@emlInitializeDrawingDefaults
@emlClearAnnotations

# ===========================================================================
# THE LEGS
# ===========================================================================
# tukey / dunn_holm     the two arms of the ruling, same data, same layout,
#                       same size. Everything about these two figures is the
#                       same except the test and what the caption says.
# dunn_bonferroni / bh  the same nonparametric arm with the OTHER two
#                       corrections the form offers. These are the value
#                       check: a caption hardcoded to "holm" satisfies every
#                       assertion about shape, width, placement and presence,
#                       and is wrong on two thirds of the menu.
# narrow                a 3.2 x 2.6 figure, where the caption does not fit at
#                       the annotation size. Exercises the shrink and the
#                       two-line break, and is the leg the clipping assertion
#                       is for.
# welch_two / mw_two    two groups, the two arms of AUTHOR RULING C. Until
#                       16 August 2026 welch_two existed to prove that NO
#                       caption was correct on a two-group figure, and it was
#                       the leg that measured the defect ruling C closes: the
#                       whole-figure OCR in welch_two.fig.ocr carried a
#                       bracket, "***" and a Cohen's d, and no test name
#                       anywhere. Ruling C makes both arms name their test,
#                       and mw_two is here because a repair applied to one
#                       arm is the shape this file has caught before — see
#                       the one_arm_only break in break.sh. Same data, same
#                       layout, same size; the test is the only difference,
#                       and the two captions must not be the same sentence.
#                       mw_two passes a correction token the arm must NOT
#                       report: one comparison was made, nothing was
#                       adjusted, and "holm" must not appear on the figure
#                       merely because the form's menu had a value in it.
# ns_omnibus            four groups with no separation. The omnibus does not
#                       reject, no post-hoc runs, no brackets are drawn, and
#                       no caption may appear — a figure with no p-values on
#                       it must not carry a sentence about how they were
#                       corrected.
# ---------------------------------------------------------------------------
if leg$ = "tukey"
    @fixture: "bc", 4, 6
    @runLeg: fixture.id, "Bracket caption, Tukey", 6, 4, "parametric", 2, ""

elsif leg$ = "dunn_holm"
    @fixture: "bc", 4, 6
    @runLeg: fixture.id, "Bracket caption, Dunn", 6, 4, "nonparametric", 2,
    ... "holm"

elsif leg$ = "dunn_bonferroni"
    @fixture: "bc", 4, 6
    @runLeg: fixture.id, "Bracket caption, Dunn", 6, 4, "nonparametric", 2,
    ... "bonferroni"

elsif leg$ = "dunn_bh"
    @fixture: "bc", 4, 6
    @runLeg: fixture.id, "Bracket caption, Dunn", 6, 4, "nonparametric", 2,
    ... "bh"

elsif leg$ = "narrow"
    @fixture: "bc", 4, 6
    @runLeg: fixture.id, "Narrow", 3.2, 2.6, "nonparametric", 2, "bonferroni"

elsif leg$ = "welch_two"
    @fixture: "bc", 2, 6
    @runLeg: fixture.id, "Two groups", 6, 4, "parametric", 2, ""

elsif leg$ = "mw_two"
    @fixture: "bc", 2, 6
    @runLeg: fixture.id, "Two groups", 6, 4, "nonparametric", 2, "holm"

elsif leg$ = "ns_omnibus"
    @fixture: "bc", 4, 0
    @runLeg: fixture.id, "No separation", 6, 4, "parametric", 2, ""

else
    exitScript: "unknown leg: " + leg$
endif

appendInfoLine: "LEG ", leg$, " done"
