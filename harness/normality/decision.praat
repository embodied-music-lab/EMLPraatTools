# ============================================================================
# decision.praat -- @emlNormalityRecommendation over the whole grid. D137.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
#     EML_NORMALITY_OUT=harness/normality/out \
#         praat --run harness/normality/decision.praat
#
# case.praat drives the rule through DATA. Data cannot reach all of it.
# Searched on 8 Aug 2026 over ~10^6 candidate samples: no sample with
# |skew| >= 2 or |excess kurtosis| >= 7 survives Shapiro-Wilk at p >= .05
# (the best found was p = .028 at |skew| = 2.02, n = 6; the kurtosis arm was
# worse, p = 2e-4 at |excess kurt| = 7.08, n = 20). So "severe shape, and the
# test declines to reject" -- the single combination that separates the
# retired `skKurtFail or swFail` gate from the canonical hierarchy at the
# SHARED thresholds -- is not reachable from a sample. v15 said the same in
# prose ("no demo table produces one") and left it there.
#
# It is reachable as a DECISION, because @emlNormalityRecommendation is pure:
# it takes five numbers and a string, prints nothing, declares nothing and
# touches no global. So this file calls it directly over a grid that lands
# exactly on every threshold and one step either side of it:
#
#   skewness   -2.5 -2 -1.9 0 1.9 2         emlSkewThreshold = 2
#   kurtosis   -7 0 6.9 7                   emlKurtosisThreshold = 7
#   n          3 50 51                      the large-n override's boundary
#   Shapiro    p = .001, .049, .05, .9      the 5% gate, both sides
#              plus UNUSABLE (error set, p undefined)
#
# 6 x 4 x 3 x 5 = 360 decisions. validate/v32_normality_parity.R recomputes
# every one of them from the hierarchy as STATED in the procedure's header
# comment, not from its branches, so a branch that stops matching its own
# documentation fails here.
#
# THE UNUSABLE ROWS ARE NOT DECORATION. @emlShapiroWilk initialises .p to
# undefined and leaves it there whenever it sets .error$, and Praat does not
# short-circuit `and`, so `.swError$ = "" and .swP < 0.05` would compare
# against undefined on every one of those 72 rows. The procedure guards it
# with a NESTED if for that reason. These rows are what would catch a
# "simplification" back to the flat form.
#
# Output:  decision.csv
#   skewness,kurtosis,n,sw_p,sw_error,recommendation,
#   sw_usable,sw_fail,shape_severe,large_n_override
# sw_p is "NA" on the unusable rows, which read.csv turns into R's own NA.
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
include ../../plugin/graphs/eml-draw-procedures.praat

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_NORMALITY_OUT")
if outDir$ = ""
    outDir$ = "../../harness/normality/out"
endif
createDirectory: outDir$

skew# = {-2.5, -2, -1.9, 0, 1.9, 2}
kurt# = {-7, 0, 6.9, 7}
nVal# = {3, 50, 51}
swP#  = {0.001, 0.049, 0.05, 0.9}

; The error string is @emlShapiroWilk's own, verbatim, so the unusable rows
; carry a message the plugin really produces rather than a placeholder.
swErr$ = "All values identical (zero range)"

out$ = "skewness,kurtosis,n,sw_p,sw_error,recommendation,"
... + "sw_usable,sw_fail,shape_severe,large_n_override" + newline$

procedure row: .sk, .ku, .n, .p, .err$
    @emlNormalityRecommendation: .sk, .ku, .n, .p, .err$
    if .p = undefined
        .pTxt$ = "NA"
    else
        .pTxt$ = string$ (.p)
    endif
    out$ = out$ + string$ (.sk) + "," + string$ (.ku) + ","
    ... + string$ (.n) + "," + .pTxt$ + "," + .err$ + ","
    ... + emlNormalityRecommendation.recommendation$ + ","
    ... + string$ (emlNormalityRecommendation.swUsable) + ","
    ... + string$ (emlNormalityRecommendation.swFail) + ","
    ... + string$ (emlNormalityRecommendation.shapeSevere) + ","
    ... + string$ (emlNormalityRecommendation.largeNOverride) + newline$
endproc

nRows = 0
for iS from 1 to size (skew#)
    for iK from 1 to size (kurt#)
        for iN from 1 to size (nVal#)
            for iP from 1 to size (swP#)
                @row: skew# [iS], kurt# [iK], nVal# [iN], swP# [iP], ""
                nRows += 1
            endfor
            ; Shapiro-Wilk unusable: .p is undefined, exactly as
            ; @emlShapiroWilk leaves it whenever it sets .error$.
            @row: skew# [iS], kurt# [iK], nVal# [iN], undefined, swErr$
            nRows += 1
        endfor
    endfor
endfor

writeFile: outDir$ + "/decision.csv", out$
writeInfoLine: "decision grid written to ", outDir$, "/decision.csv  (",
... nRows, " rows)"
