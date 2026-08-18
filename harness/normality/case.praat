# ============================================================================
# case.praat -- ONE normality case, driven through the shipping paths. D137.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Until 8 August 2026 the plugin carried THREE hand-maintained copies of its
# normality decision rule and they did not agree. The third copy -- the
# per-group branch of scripts/eml-check-normality.praat -- still tested
# hard-coded thresholds of 1 and 3 against shared constants of 2 and 7, and
# still used the retired `skKurtFail or swFail` gate, so ONE wrapper gave two
# different answers for the same numbers depending on whether the user had
# picked a grouping column. All three now call @emlNormalityRecommendation
# (stats/eml-analysis.praat). This harness is the evidence for that.
#
#     EML_NORM_CASE=<case> EML_NORMALITY_OUT=harness/normality/out \
#         praat --run harness/normality/case.praat
#
# ONE PROCESS PER CASE, the same rule as harness/disclosure/run.sh: a Praat
# script error aborts the whole script, so a shared process would let one
# degenerate case erase the verdict on every case after it. The red path here
# is half the file, so that is not a hypothetical.
#
# TWO OF THE THREE CALL SITES ARE REACHED HERE, both by their shipping name:
#
#   analysis   @emlRunNormalityAnalysis (stats/eml-analysis.praat) on a Table
#              -- the orchestrator the "Check normality" menu item calls in
#              its OVERALL branch, and the one the wizard's analysis step
#              reaches.
#   wizard     @wizardNormDiag (scripts/eml-wizard.praat) on a vector -- the
#              wizard's own normality diagnosis. Reached by including the
#              SHIPPING wizard file and jumping over its top-level body; see
#              the note at the include below. No copy of the procedure is
#              made anywhere, because a copy is the defect.
#
#   THE THIRD SITE, the per-group branch of eml-check-normality.praat, is
#   inline in an interactive wrapper: its first statement is `beginPause:`,
#   which hard-crashes under `praat --run` (Trace/breakpoint trap, exit 133 --
#   confirmed again 8 Aug 2026 on Praat 6.4.06, with and without DISPLAY set,
#   because --run never opens a display connection). It is driven through the
#   GUI instead, by pergroup.sh beside this file, over the same
#   out/data/<case>.csv tables this driver writes. That is why the data is
#   saved rather than regenerated: the two halves must see the same numbers
#   to the last bit, and a formula evaluated twice is not a guarantee of that.
#
# NOTHING IS COMPARED HERE. Every case writes the Info window verbatim and
# the raw statistics in long form. NO VALIDATOR READS THEM -- see run.sh. A
# reader who wants them recomputed
# the hierarchy in base R from its stated rules and asserts the printed
# verdicts against that. The two halves share no code, so they cannot agree
# by sharing a mistake.
#
# Output (all under $EML_NORMALITY_OUT):
#   data/<case>.csv               the table, as the GUI half will read it
#   info/<case>_analysis.txt      Info window after @emlRunNormalityAnalysis
#   info/<case>_wizard.txt        Info window after @wizardNormDiag
#   rows/<case>_manifest.csv      case,n_rows,kind          (no header)
#   rows/<case>_results.csv       case,site,statistic,value (no header)
#   rows/<case>_refusals.tsv      case<TAB>site<TAB>message (no header)
# run.sh concatenates the rows/ fragments into out/manifest.csv,
# out/results.csv and out/refusals.tsv with headers.
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
# @emlReportNormalityAnalysis -- the procedure that PRINTS the report, and so
# the procedure that decides what a user sees -- lives in the annotation
# layer, not the stats layer. Same include set as harness/coltype.
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

# ── Reaching the shipping @wizardNormDiag ──────────────────────────────────
#
# eml-wizard.praat is a top-level script, not a library: its executable body
# starts at `emlShowExplanations = 1` and runs straight into a `beginPause:`.
# Including it plainly would run the wizard. The `goto` jumps over the body;
# Praat resolves `@name` by scanning the whole script text for
# `procedure name`, so every procedure the file defines stays callable from
# after the label. Verified 8 Aug 2026.
#
# The file's own `include eml-lib-lmm.praat` resolves against the TOP-LEVEL
# script's folder -- this one -- and is answered by the deliberate stub
# beside this file. Read its header before touching either.
#
# This is the alternative to transcribing @wizardNormDiag into the harness.
# A transcription would pass every check in v32 on the day someone reverted
# the wizard to its own copy of the rule, which is the exact failure this
# harness exists to make impossible.
goto NORMALITY_DRIVER
include ../../plugin/scripts/eml-wizard.praat
label NORMALITY_DRIVER

Text writing preferences: "UTF-8"

outDir$ = environment$ ("EML_NORMALITY_OUT")
if outDir$ = ""
    outDir$ = "../../harness/normality/out"
endif
createDirectory: outDir$
createDirectory: outDir$ + "/data"
createDirectory: outDir$ + "/info"
createDirectory: outDir$ + "/rows"

case$ = environment$ ("EML_NORM_CASE")
if case$ = ""
    case$ = "g01_normal"
endif

; Alphabetical group order, so the plugin's group index matches the order R
; gets from factor(). Same reason as harness/coltype and harness/colmissing.
emlGroupSortAlphabetical = 1

results$ = ""
refusals$ = ""

# ---------------------------------------------------------------------------
# @emit / @refuse -- the contract harness/coltype and harness/colmissing use.
#   string$(), not fixed$(): fixed$ counts DECIMAL PLACES and would throw away
#   most of the mantissa of a small p. "NA" for undefined, which read.csv
#   turns into R's own NA.
# ---------------------------------------------------------------------------
procedure emit: .site$, .stat$, .value
    if .value = undefined
        .txt$ = "NA"
    else
        .txt$ = string$ (.value)
    endif
    results$ = results$ + case$ + "," + .site$ + "," + .stat$ + ","
    ... + .txt$ + newline$
endproc

procedure refuse: .site$, .message$
    results$ = results$ + case$ + "," + .site$ + ",refused,1" + newline$
    refusals$ = refusals$ + case$ + tab$ + .site$ + tab$ + .message$
    ... + newline$
endproc

# ---------------------------------------------------------------------------
# @buildTable: .case$
#
# Every table has the same two columns, so the GUI half can drive any case
# without knowing which:
#
#   grp   a STRING column. "All" in every row except p01_groups, so that
#         check-normality's per-group mode sees ONE group holding every row
#         and therefore analyses the SAME NUMBERS its overall mode analyses.
#         That identity is what makes "the two modes agree" a statement about
#         the rule rather than about two different samples.
#   y     the measurement column.
#
# The green vectors were SEARCHED FOR, not sampled and kept: each one sits in
# a named region of the hierarchy, and the R side asserts that it really does
# before it asserts anything about the verdict (the v15 pattern -- a case that
# has drifted out of its region tests nothing and must say so).
#
#   g01_normal      n=24  near-normal                      SW does not reject
#   g02_largen      n=60  SW rejects, shape within limits  LARGE-N OVERRIDE
#   g03_severe      n=60  SW rejects, |skew| > 2           nonparametric
#   g04_reject30    n=30  SW rejects, shape within limits  nonparametric
#                         -- g02 with n <= 50; the override's other side
#   g05_severe12    n=12  SW rejects, |skew| > 2           nonparametric
#   g06_min3        n=3   exactly Shapiro-Wilk's floor
#
#   d01_skew        n=18  |skew| 1.2, SW p = .13    THE D137 REGION, skew arm
#   d02_kurt        n=10  |excess kurt| 3.5, SW p = .11   ditto, kurtosis arm
#
#     d01 and d02 are the load-bearing cases. Both sit where the RETIRED
#     per-group rule (|skew| >= 1 or |excess kurt| >= 3, OR-ed with the
#     Shapiro-Wilk verdict) and the canonical hierarchy give DIFFERENT
#     answers: nonparametric under the old copy, parametric under the rule
#     the plugin now has one of. Neither trips the shared thresholds of 2 and
#     7, and neither is rejected by Shapiro-Wilk, so nothing else about the
#     report changes -- only the recommendation.
#
#   p01_groups      three groups: A = d01's numbers, B = 12 near-normal,
#                   C = two values. C exercises per-group mode's own red
#                   path, "skipped (n < 3)", beside two groups that run.
#
#   r01_blank       12 rows, y empty in every one
#   r02_single      one row
#   r03_identical   10 rows, all 7.5             zero variance / zero range
#   r04_n2          two rows                     below Shapiro-Wilk's floor
#   r05_swceil      5001 rows, shape within limits    above the CEILING
#   r06_text        12 rows of text cells
#   r07_swceil_sev  5001 rows, |skew| = 12       above the ceiling, severe
#
#     r05 and r07 are the only two cases in this file that reach the
#     "Shapiro-Wilk unusable, so shape decides" branch on data a user could
#     actually have, and they reach it in OPPOSITE directions. Confirmed by
#     search on 8 Aug 2026: no sample with |skew| >= 2 or |excess kurt| >= 7
#     survives Shapiro-Wilk at p >= .05 (best found over ~10^6 candidates:
#     p = .028 at |skew| = 2.02, n = 6), so severe shape and a non-rejecting
#     Shapiro-Wilk cannot be produced together at the shared thresholds while
#     the test is usable. decision.praat covers that combination as a
#     decision, since data cannot.
#
# The 5001-row columns are generated from a closed form rather than sampled:
# nothing here may depend on a random seed, and Praat's generators are not
# seedable from a script.
# ---------------------------------------------------------------------------
procedure buildTable: .case$
    .kind$ = "green"

    if .case$ = "g01_normal"
        .y# = {51.6, 60.5, 50.2, 47.3, 50.5, 39.2, 46.8, 47.2, 54, 38.5,
        ... 53.3, 51.9, 31.6, 64.1, 50.8, 59.4, 53.5, 36.8, 40, 46.9,
        ... 42.7, 51, 38.4, 43.1}
    elsif .case$ = "g02_largen"
        .y# = {34.4, 19, 18.5, 17.1, 13.6, 16, 15.7, 27.2, 24, 17.2,
        ... 27.8, 21.7, 18.7, 43.3, 27.7, 12.6, 15.2, 35.6, 13.9, 15.9,
        ... 22, 20.9, 24.5, 28.2, 16.2, 33.6, 30.4, 16.9, 13.5, 15.3,
        ... 10.4, 33.5, 20.5, 18.4, 26.1, 14.8, 8.5, 27.4, 17.5, 20,
        ... 26, 57, 21.3, 27.1, 18.2, 22.2, 17, 20.4, 27.9, 21.8,
        ... 15.8, 19.5, 37.2, 16.7, 19.2, 17.7, 28.5, 17.6, 22.3, 13.1}
    elsif .case$ = "g03_severe"
        .y# = {35.4, 10.9, 29.4, 27.4, 16.9, 3.5, 10.8, 12.7, 4.4, 18.8,
        ... 134.2, 18.1, 14.7, 17.9, 92.7, 11.2, 86.5, 13.1, 24.3, 8.9,
        ... 9.5, 35.5, 9.4, 20.2, 28.5, 24.1, 21, 14.9, 14.3, 20.3,
        ... 11.4, 31.1, 44.4, 31.4, 59.1, 54.1, 41.4, 22.6, 41.8, 16.8,
        ... 5.5, 29.5, 44.1, 4, 12.9, 30.8, 47.7, 28.1, 38.4, 13.4,
        ... 16, 5.7, 35.9, 22.8, 23.3, 22.9, 21.7, 21.6, 14.5, 9.3}
    elsif .case$ = "g04_reject30"
        .y# = {25.7, 17.5, 22.4, 36.3, 20.8, 17.2, 27.5, 20.4, 20.6, 19.1,
        ... 25.1, 26.5, 28.2, 34.7, 17.1, 14.5, 43.7, 20, 22, 19.2,
        ... 15.3, 13.9, 16.5, 19, 14.1, 26, 28.9, 15.9, 14.6, 25}
    elsif .case$ = "g05_severe12"
        .y# = {5.6, 103.3, 20.3, 7.2, 25.8, 52.4, 10.8, 31.7, 9.9, 14.1,
        ... 19.6, 14.9}
    elsif .case$ = "g06_min3"
        .y# = {10.2, 12.7, 17.4}
    elsif .case$ = "d01_skew"
        .y# = {13.2, 23.9, 29.6, 37.3, 29.2, 13.1, 21.3, 18.9, 24.6, 17.4,
        ... 9.4, 15.2, 25.3, 49.1, 30.3, 19.6, 18.3, 17.1}
    elsif .case$ = "d02_kurt"
        .y# = {54.5, 68.7, 54, 52.9, 47.6, 51.8, 30.9, 57.3, 50.5, 50.6}
    elsif .case$ = "p01_groups"
        .y# = {13.2, 23.9, 29.6, 37.3, 29.2, 13.1, 21.3, 18.9, 24.6, 17.4,
        ... 9.4, 15.2, 25.3, 49.1, 30.3, 19.6, 18.3, 17.1,
        ... 51.6, 60.5, 50.2, 47.3, 50.5, 39.2, 46.8, 47.2, 54, 38.5,
        ... 53.3, 51.9,
        ... 71.4, 73.8}
    elsif .case$ = "r02_single"
        .kind$ = "red"
        .y# = {42.5}
    elsif .case$ = "r03_identical"
        .kind$ = "red"
        .y# = {7.5, 7.5, 7.5, 7.5, 7.5, 7.5, 7.5, 7.5, 7.5, 7.5}
    elsif .case$ = "r04_n2"
        .kind$ = "red"
        .y# = {3.5, 9.25}
    else
        ; The remaining cases have no literal vector: blank, text, and the
        ; two 5001-row columns, which are generated below.
        .kind$ = "red"
        .y# = zero# (1)
    endif

    if .case$ = "r01_blank" or .case$ = "r06_text"
        .n = 12
    elsif .case$ = "r05_swceil" or .case$ = "r07_swceil_sev"
        .n = 5001
    else
        .n = size (.y#)
    endif

    .tid = Create Table with column names: "norm_" + .case$, .n, "grp y"

    for .i from 1 to .n
        selectObject: .tid

        ; The grouping column. One group named "All" everywhere except
        ; p01_groups, so per-group mode and overall mode see identical data.
        if .case$ = "p01_groups"
            if .i <= 18
                Set string value: .i, "grp", "A_skewed"
            elsif .i <= 30
                Set string value: .i, "grp", "B_normal"
            else
                Set string value: .i, "grp", "C_tiny"
            endif
        else
            Set string value: .i, "grp", "All"
        endif

        ; The measurement column.
        if .case$ = "r01_blank"
            Set string value: .i, "y", ""
        elsif .case$ = "r06_text"
            Set string value: .i, "y", "Singer_" + string$ (.i)
        elsif .case$ = "r05_swceil"
            Set numeric value: .i, "y",
            ... 50 + 12 * sin (.i * 1.7) + 5 * cos (.i * 0.31)
        elsif .case$ = "r07_swceil_sev"
            if .i mod 151 = 0
                Set numeric value: .i, "y", 260 + 4 * cos (.i)
            else
                Set numeric value: .i, "y", 10 + 2 * sin (.i * 0.9)
            endif
        else
            Set numeric value: .i, "y", .y# [.i]
        endif
    endfor
endproc

@buildTable: case$
tid = buildTable.tid
nRows = buildTable.n
kind$ = buildTable.kind$

selectObject: tid
Save as comma-separated file: outDir$ + "/data/" + case$ + ".csv"

manifest$ = case$ + "," + string$ (nRows) + "," + kind$ + newline$

# ---------------------------------------------------------------------------
# SITE 1 -- @emlRunNormalityAnalysis on the Table.
#
# The Info window is cleared before the call and written out verbatim after
# it, so what the validator reads is what the user is left looking at. Its
# LENGTH is emitted too: "refused and printed nothing" and "refused beside a
# full result table" are different facts, and a message-only check cannot
# tell them apart. That distinction is what D113 turned on.
# ---------------------------------------------------------------------------
selectObject: tid
clearinfo
@emlRunNormalityAnalysis: tid, "y", "both"
analysisOut$ = info$ ()
writeFile: outDir$ + "/info/" + case$ + "_analysis.txt", analysisOut$

if emlRunNormalityAnalysis.error$ <> ""
    @refuse: "analysis", emlRunNormalityAnalysis.error$
else
    @emit: "analysis", "n", emlRunNormalityAnalysis.nValid
    @emit: "analysis", "n.excluded", emlRunNormalityAnalysis.nUndefined
    @emit: "analysis", "mean", emlRunNormalityAnalysis.mean
    @emit: "analysis", "sd", emlRunNormalityAnalysis.sd
    @emit: "analysis", "median", emlRunNormalityAnalysis.median
    @emit: "analysis", "skewness", emlRunNormalityAnalysis.skewness
    @emit: "analysis", "kurtosis", emlRunNormalityAnalysis.kurtosis
    @emit: "analysis", "statistic", emlRunNormalityAnalysis.swW
    @emit: "analysis", "p.value", emlRunNormalityAnalysis.swP
    @emit: "analysis", "sw.usable", emlRunNormalityAnalysis.swUsable
    if emlRunNormalityAnalysis.swError$ <> ""
        @refuse: "analysis.shapiro", emlRunNormalityAnalysis.swError$
    endif
endif
@emit: "analysis", "output.chars", length (analysisOut$)

# ---------------------------------------------------------------------------
# SITE 2 -- @wizardNormDiag on a vector.
#
# The wizard is handed a vector, never a Table: one group's values, or a
# column of paired differences. The column is read here the way every
# row-wise reader in the plugin reads one -- `Get value:`, undefined dropped
# -- so the vector the wizard sees is the vector the orchestrator saw.
#
# A vector of length 0 cannot be constructed in Praat, so a column with no
# defined values is recorded as a DRIVER skip rather than silently omitted.
# The prefix says which side declined; a bare absence would read as the
# plugin having declined.
# ---------------------------------------------------------------------------
nValid = 0
for iRow from 1 to nRows
    selectObject: tid
    v = Get value: iRow, "y"
    if v <> undefined
        nValid += 1
    endif
endfor
@emit: "wizard", "n.available", nValid

if nValid < 1
    clearinfo
    writeFile: outDir$ + "/info/" + case$ + "_wizard.txt", ""
    @refuse: "wizard", "DRIVER SKIP: column holds no defined values, and a"
    ... + " zero-length vector cannot be constructed"
else
    vec# = zero# (nValid)
    idx = 0
    for iRow from 1 to nRows
        selectObject: tid
        v = Get value: iRow, "y"
        if v <> undefined
            idx += 1
            vec# [idx] = v
        endif
    endfor

    clearinfo
    @wizardNormDiag: vec#, "y"
    wizardOut$ = info$ ()
    writeFile: outDir$ + "/info/" + case$ + "_wizard.txt", wizardOut$

    ; The wizard's own 1/2 encoding, emitted beside the printed verdict so
    ; the validator can assert that the wording the user reads and the code
    ; the wizard branches on cannot disagree.
    @emit: "wizard", "n", wizardNormDiag.n
    @emit: "wizard", "skewness", wizardNormDiag.sk
    @emit: "wizard", "kurtosis", wizardNormDiag.ku
    @emit: "wizard", "recommendation.code", wizardNormDiag.recommendation
    @emit: "wizard", "output.chars", length (wizardOut$)
endif

selectObject: tid
Remove

writeFileLine: outDir$ + "/rows/" + case$ + "_manifest.csv", manifest$
writeFileLine: outDir$ + "/rows/" + case$ + "_results.csv", results$
writeFileLine: outDir$ + "/rows/" + case$ + "_refusals.tsv", refusals$

writeInfoLine: "CASE ", case$, " rows=", nRows, " nValid=", nValid
