# ============================================================================
# harness/posthocgate/doors.praat — one door, one Praat run, one report
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHAT THIS DRIVES. Punch list lane 3 rules that a post-hoc the user chose
# always runs — no door gates it on the omnibus p-value. The fixture is built
# to make that ruling visible: on fixture_kgroups.csv the one-way ANOVA gives
# p = .12 and the Kruskal-Wallis p = .17, so every pre-fix gate CLOSED, while
# the largest pair (Soprano vs Alto) is separated enough that a post-hoc has
# something to say. A door that swallowed the post-hoc and a door that ran it
# therefore differ in what they PRINT, not merely in a threshold.
#
# ONE LEG PER PROCESS, chosen by $EML_PHG_LEG, and the report goes to the
# process's stdout. Praat's Info window is the report; a leg per process means
# each captured log is exactly one report with nothing else in it, which is
# what validate/v122_posthoc_never_gated.R reads.
#
# $EML_PHG_ALPHA, when set, is written to emlAlpha before the leg runs. That
# is the alpha in force for report text (@emlReportAlpha), and it is how the
# caution line's LEVEL is driven at .05 and at .01 from one file.
#
# THE BRIDGE LEGS ALSO DUMP THE ANNOTATION ARRAYS. On the graph door the
# post-hoc reaches the user as brackets or as matrix cells, not as prose, so
# "the post-hoc ran" is a claim about annotBracketN / annotMatrixCell$ and is
# asserted there. The dump is inside a procedure because the cell names are
# built by interpolation, which Praat allows in a procedure body only.
#
# Usage (run.sh does this):
#   cd harness/posthocgate
#   EML_PHG_LEG=anova_tukey praat --run doors.praat > out/anova_tukey.txt
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat

Text writing preferences: "UTF-8"

leg$ = environment$ ("EML_PHG_LEG")
if leg$ = ""
    exitScript: "posthocgate: EML_PHG_LEG is not set."
endif

alphaText$ = environment$ ("EML_PHG_ALPHA")
if alphaText$ <> ""
    emlAlpha = number (alphaText$)
endif

; Table order, so the group order on the report is the order in the file and
; the R oracle's factor levels line up with it.
emlGroupSortAlphabetical = 0

appendInfoLine: "== LEG ", leg$, " =="

# ---------------------------------------------------------------------------
# The k-group fixture: ANOVA p = .12, Kruskal-Wallis p = .17.
# ---------------------------------------------------------------------------
procedure loadK
    .id = Read Table from comma-separated file: "fixture_kgroups.csv"
endproc

procedure loadRM
    .id = Read Table from comma-separated file: "fixture_rm.csv"
endproc

# ---------------------------------------------------------------------------
# The SIGNIFICANT-omnibus fixture (v122's hole): ANOVA p = 1.3e-7,
# Kruskal-Wallis p = 1.2e-4. Every leg in this file until now used
# fixture_kgroups.csv, whose omnibus never clears .05 -- so nothing here has
# ever asserted the caution line's ABSENCE, only its presence. A regression
# that printed the caution after every post-hoc, significant omnibus or not,
# would leave v122 green at its old count. This fixture closes that.
# ---------------------------------------------------------------------------
procedure loadKSig
    .id = Read Table from comma-separated file: "fixture_kgroups_sig.csv"
endproc

# ---------------------------------------------------------------------------
# The annotation dump. Names built by interpolation, so: procedure body.
# ---------------------------------------------------------------------------
procedure dumpAnnot: .nGroups
    appendInfoLine: "ANNOT bracketN=", annotBracketN
    appendInfoLine: "ANNOT matrixN=", annotMatrixN
    for .i from 1 to annotBracketN
        appendInfoLine: "ANNOT bracket ", annotBracketI [.i], "-",
        ... annotBracketJ [.i], " p=", annotBracketP [.i],
        ... " label=", annotBracketLabel$ [.i]
    endfor
    for .i from 1 to .nGroups - 1
        for .j from .i + 1 to .nGroups
            if variableExists ("annotMatrixCell'.i'_'.j'$")
                appendInfoLine: "ANNOT cell ", .i, "-", .j, " = ",
                ... annotMatrixCell'.i'_'.j'$
            endif
        endfor
    endfor
endproc

# ---------------------------------------------------------------------------
# Legs
# ---------------------------------------------------------------------------
if leg$ = "anova_tukey"
    @loadK
    @emlRunAnovaAnalysis: loadK.id, "F0_Hz", "voice_type", 1

elsif leg$ = "anova_notukey"
    @loadK
    @emlRunAnovaAnalysis: loadK.id, "F0_Hz", "voice_type", 0

elsif leg$ = "kw_dunn"
    @loadK
    @emlRunKruskalWallisAnalysis: loadK.id, "F0_Hz", "voice_type", 1, "holm"

elsif leg$ = "kw_nodunn"
    @loadK
    @emlRunKruskalWallisAnalysis: loadK.id, "F0_Hz", "voice_type", 0, "holm"

elsif leg$ = "anova_tukey_sig"
    ; v122's closed ratchet: SIGNIFICANT omnibus, post-hoc chosen -> the
    ; post-hoc table still runs (it is never gated either way), but the
    ; caution line must be ABSENT -- printing it here would be false, since
    ; the overall test DID reach significance.
    @loadKSig
    @emlRunAnovaAnalysis: loadKSig.id, "F0_Hz", "voice_type", 1

elsif leg$ = "kw_dunn_sig"
    @loadKSig
    @emlRunKruskalWallisAnalysis: loadKSig.id, "F0_Hz", "voice_type", 1, "holm"

elsif leg$ = "pairwise_scheffe"
    @loadK
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "scheffe", "none"

elsif leg$ = "pairwise_welch_bh"
    @loadK
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "welch", "bh"

elsif leg$ = "wizard_scheffe_dispatch"
    ; The calls the wizard's k-group parametric branch makes, in order, with
    ; the post-hoc row set to Scheffe -- INCLUDING the emlPairwiseFollows
    ; bracket around the omnibus, because that is part of the dispatch and a
    ; leg that dropped it would report a caption the wizard does not print.
    ; This is the ENGINE half of the wizard leg; the GUI half (run.sh) drives
    ; the real dialogs.
    @loadK
    emlPairwiseFollows = 1
    @emlRunAnovaAnalysis: loadK.id, "F0_Hz", "voice_type", 0
    emlPairwiseFollows = 0
    @emlRunPairwiseAnalysis: loadK.id, "F0_Hz", "voice_type", "scheffe", "none"
    if emlRunPairwiseAnalysis.error$ = ""
        @emlPostHocCaution: emlOneWayAnova.p
    endif

elsif leg$ = "rm_posthoc"
    @loadRM
    @emlRunRepeatedMeasuresAnalysis: loadRM.id, "subject",
    ... "quiet|normal|loud", 1, "holm"

elsif leg$ = "friedman_posthoc"
    @loadRM
    @emlRunFriedmanAnalysis: loadRM.id, "subject", "quiet|normal|loud", 1,
    ... "holm"

elsif leg$ = "bridge_kw_matrix"
    @loadK
    @emlClearAnnotations
    annotCorrectionMethod$ = "holm"
    @emlRunAnnotationComparison: loadK.id, "F0_Hz", "voice_type", 0.05,
    ... "p-value", 1, 1, "nonparametric", 3
    appendInfoLine: "BRIDGE error=[", emlRunAnnotationComparison.error$, "]"
    appendInfoLine: "BRIDGE omnibus=[", emlRunAnnotationComparison.omnibus$, "]"
    @dumpAnnot: emlRunAnnotationComparison.nGroups
    @emlReportBridgeStats: loadK.id, "F0_Hz", "voice_type"

elsif leg$ = "bridge_kw_brackets"
    @loadK
    @emlClearAnnotations
    annotCorrectionMethod$ = "holm"
    @emlRunAnnotationComparison: loadK.id, "F0_Hz", "voice_type", 0.05,
    ... "p-value", 1, 1, "nonparametric", 2
    appendInfoLine: "BRIDGE error=[", emlRunAnnotationComparison.error$, "]"
    @dumpAnnot: emlRunAnnotationComparison.nGroups

elsif leg$ = "bridge_anova_brackets"
    @loadK
    @emlClearAnnotations
    @emlRunAnnotationComparison: loadK.id, "F0_Hz", "voice_type", 0.05,
    ... "p-value", 1, 1, "parametric", 2
    appendInfoLine: "BRIDGE error=[", emlRunAnnotationComparison.error$, "]"
    @dumpAnnot: emlRunAnnotationComparison.nGroups

elsif leg$ = "bridge_anova_matrix"
    @loadK
    @emlClearAnnotations
    @emlRunAnnotationComparison: loadK.id, "F0_Hz", "voice_type", 0.05,
    ... "p-value", 1, 1, "parametric", 3
    appendInfoLine: "BRIDGE error=[", emlRunAnnotationComparison.error$, "]"
    @dumpAnnot: emlRunAnnotationComparison.nGroups
    @emlReportBridgeStats: loadK.id, "F0_Hz", "voice_type"

else
    exitScript: "posthocgate: unknown leg '" + leg$ + "'."
endif

appendInfoLine: "== END ", leg$, " =="
