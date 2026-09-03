; ============================================================================
; harness/settings/probe.praat -- does this setting move the RESULT, measured
; ============================================================================
; Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
;
; WHAT THIS IS FOR.
;
; validate/v112_settings_census.R splits every setting the draw-time analysis
; reads into two lists: the ones that change the computed result, and the ones
; that only change how it looks. A label put on a setting by READING the code
; is a guess wearing a confident face. This file measures instead: it runs the
; same analysis on the same table twice, changing exactly one setting between
; the runs, and writes down what came out.
;
; WHAT "THE RESULT" MEANS HERE, stated once so the comparison is not circular.
; Keys written with a `res.` prefix are the analysis result: the group labels
; IN THEIR PUBLISHED ORDER, the omnibus sentence, and each published pair's
; p-value and effect size, keyed by the pair's group NAMES rather than by
; index so that a reordering shows up as a changed value and not as an
; accident of numbering. Keys written with a `dis.` prefix are the drawn
; presentation: the formatted bracket text, how many brackets survived, and
; whether the layout came out as brackets or a matrix.
;
; ABSENCE IS NOT A DIFFERENCE. A setting that SUPPRESSES a pair -- showNS = 0
; drops the non-significant brackets -- makes a res. key vanish rather than
; change. That is suppression of publication, not a different result, and
; RULING_RESULT_STORE.md section (d) removes it outright: the store's single
; write site states the whole result on every run whether or not the figure
; draws all of it. So the reader of this artefact compares only keys PRESENT
; IN BOTH variants. A key present in both with a different value is the result
; moving; a key present in one is the bridge publishing less of it.
;
; ONE-DIRECTIONAL BY CONSTRUCTION. A setting whose res. keys move is PROVED
; result-affecting. A setting whose res. keys hold still on this table is not
; proved display-only -- it is one negative on one dataset. The census treats
; it that way: a moved setting classified as display-only is RED, a still
; setting is evidence and nothing more.
;
; Output: $EML_SETTINGS_OUT (default harness/settings/out/SETTINGS.tsv)
;   setting <TAB> variant <TAB> key <TAB> value
;
; ATTRIBUTION
; Framework: EML PraatGen by Ian Howell
;            Embodied Music Lab -- www.embodiedmusiclab.com
; Code generation: Claude (Anthropic)
; Script author: Ian Howell -- created and verified by this individual
; ============================================================================

; Same include set as harness/stress_cases/_prelude.praat, and relative for
; the same reason: an absolute path here would silently measure another tree's
; plugin and report it as this one's.
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
; eml-result-writer.praat, added 3 September 2026. This list is a THIRD
; hand-maintained copy of the module set -- after setup.praat's barrel table
; and scripts/eml-lib.praat's door chain -- and nothing checks it, so it went
; stale the way the other two did. eml-annotation-procedures.praat below calls
; @emlResultClearExtras in four places; the procedure lives in
; eml-result-writer.praat, which this list never named. The harness died with
; `Error: Procedure "emlResultClearExtras" not found.` before writing anything.
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

@emlInitializeDrawingDefaults

outPath$ = environment$ ("EML_SETTINGS_OUT")
if outPath$ = ""
    outPath$ = "out/SETTINGS.tsv"
endif
writeFileLine: outPath$, "setting", tab$, "variant", tab$, "key", tab$, "value"

; ---------------------------------------------------------------------------
; The two fixtures. Group order is the ENCOUNTER order the plugin discovers,
; and it is deliberately anti-alphabetical: Zebra is met first and Alpha last,
; so a setting that sorts the groups alphabetically has something to change.
; The separations are large and clean so that every pair is significant and no
; verdict in this file turns on a borderline p.
; ---------------------------------------------------------------------------
procedure mkTwo
    Create Table with column names: "twoGrp", 12, "Score Grp"
    .id = selected ("Table")
    .zeb# = { 18, 20, 22, 20, 21, 19 }
    .alp# = { 8, 10, 12, 10, 11, 9 }
    for .i from 1 to 6
        Set numeric value: .i, "Score", .zeb# [.i]
        Set string value: .i, "Grp", "Zebra"
    endfor
    for .i from 1 to 6
        Set numeric value: 6 + .i, "Score", .alp# [.i]
        Set string value: 6 + .i, "Grp", "Alpha"
    endfor
endproc

procedure mkThree
    Create Table with column names: "threeGrp", 18, "Score Grp"
    .id = selected ("Table")
    .zeb# = { 30, 32, 34, 31, 33, 29 }
    .mid# = { 19, 21, 20, 22, 18, 20 }
    .alp# = {  8, 10, 12, 10, 11,  9 }
    for .i from 1 to 6
        Set numeric value: .i, "Score", .zeb# [.i]
        Set string value: .i, "Grp", "Zebra"
        Set numeric value: 6 + .i, "Score", .mid# [.i]
        Set string value: 6 + .i, "Grp", "Mid"
        Set numeric value: 12 + .i, "Score", .alp# [.i]
        Set string value: 12 + .i, "Grp", "Alpha"
    endfor
endproc

; ---------------------------------------------------------------------------
; @runVariant -- one run of the door, written down.
;
; Emits res./dis. rows for one (setting, variant) pair. The bridge's own
; locals are read IMMEDIATELY on return, before anything else runs: Praat
; keeps a procedure's outputs only until that procedure runs again, and
; @emlCountGroups alone is re-entered by four of the tests inside.
; ---------------------------------------------------------------------------
; The borderline fixture. One pair separated just enough to be significant at
; .05 and not at .01, so that a setting which only moves the THRESHOLD has
; something to move. Welch's t on these is about 2.4 on 10 df.
procedure mkBorder
    Create Table with column names: "borderGrp", 12, "Score Grp"
    .id = selected ("Table")
    .zeb# = { 10, 13, 16, 12, 15, 12 }
    .alp# = {  7, 10, 13,  9, 12,  9 }
    for .i from 1 to 6
        Set numeric value: .i, "Score", .zeb# [.i]
        Set string value: .i, "Grp", "Zebra"
        Set numeric value: 6 + .i, "Score", .alp# [.i]
        Set string value: 6 + .i, "Grp", "Alpha"
    endfor
endproc

procedure runVariant: .setting$, .variant$, .tableId, .alpha, .style$, .showNS, .showEffect, .testType$, .layoutMode
    @emlClearAnnotations
    @emlRunAnnotationComparison: .tableId, "Score", "Grp", .alpha, .style$,
    ... .showNS, .showEffect, .testType$, .layoutMode

    .err$ = emlRunAnnotationComparison.error$
    .omni$ = emlRunAnnotationComparison.omnibus$
    .n = emlRunAnnotationComparison.nGroups
    for .i from 1 to .n
        .lab$ [.i] = emlRunAnnotationComparison.gLabel$ [.i]
    endfor
    .bN = annotBracketN
    .mN = annotMatrixN
    for .k from 1 to .bN
        .bI [.k] = annotBracketI [.k]
        .bJ [.k] = annotBracketJ [.k]
        .bP [.k] = annotBracketP [.k]
        .bD [.k] = annotBracketD [.k]
        .bL$ [.k] = annotBracketLabel$ [.k]
    endfor

    @emit: .setting$, .variant$, "res.error", .err$
    @emit: .setting$, .variant$, "res.omnibus", .omni$
    .labels$ = ""
    for .i from 1 to .n
        .labels$ = .labels$ + .lab$ [.i]
        if .i < .n
            .labels$ = .labels$ + "|"
        endif
    endfor
    @emit: .setting$, .variant$, "res.labels", .labels$
    @emitNum: .setting$, .variant$, "res.nGroups", .n

    ; PAIRS ARE KEYED BY GROUP NAME, NOT BY BRACKET INDEX. Sorting the groups
    ; renumbers every bracket, so an index-keyed comparison would report the
    ; whole table as changed and say nothing about which quantity moved. The
    ; names also make the SIGN legible: res.d.Zebra-Alpha and res.d.Alpha-Zebra
    ; are different keys, and the pair that survives in both variants is the
    ; one whose value is being compared.
    for .k from 1 to .bN
        .pair$ = .lab$ [.bI [.k]] + "-" + .lab$ [.bJ [.k]]
        @emitNum: .setting$, .variant$, "res.p." + .pair$, .bP [.k]
        @emitNum: .setting$, .variant$, "res.absd." + .pair$, abs (.bD [.k])
        @emitNum: .setting$, .variant$, "obs.signedd." + .pair$, .bD [.k]
        @emit: .setting$, .variant$, "dis.label." + .pair$, .bL$ [.k]
    endfor
    ; THE MATRIX ARM'S VERDICT. annotMatrixSig is the only place either arm
    ; states, as a number, whether a pair came out significant at the alpha in
    ; force -- the bracket arm expresses the same verdict by leaving the
    ; bracket out, which is an absence and not a value. It is a res. key
    ; because "significant at .05" is a claim the figure makes, not a way of
    ; drawing one.
    for .i from 1 to .n - 1
        for .j from .i + 1 to .n
            if .mN > 0
                .cell$ = annotMatrixCell'.i'_'.j'$
                .sig = annotMatrixSig'.i'_'.j'
                .pr$ = .lab$ [.i] + "-" + .lab$ [.j]
                @emit: .setting$, .variant$, "dis.cell." + .pr$, .cell$
                @emitNum: .setting$, .variant$, "res.sig." + .pr$, .sig
            endif
        endfor
    endfor
    @emit: .setting$, .variant$, "res.posthoc", annotBracketPosthoc$
    @emit: .setting$, .variant$, "res.adjust", annotBracketAdjust$
    @emitNum: .setting$, .variant$, "dis.bracketN", .bN
    @emitNum: .setting$, .variant$, "dis.matrixN", .mN
endproc

procedure emit: .s$, .v$, .k$, .val$
    @emlAsciiFold: .val$
    appendFileLine: outPath$, .s$, tab$, .v$, tab$, .k$, tab$,
    ... emlAsciiFold.result$
endproc

procedure emitNum: .s$, .v$, .k$, .val
    if .val = undefined
        .txt$ = "undefined"
    else
        .txt$ = fixed$ (.val, 6)
    endif
    appendFileLine: outPath$, .s$, tab$, .v$, tab$, .k$, tab$, .txt$
endproc

; ===========================================================================
; THE MEASUREMENTS
; ===========================================================================
@mkTwo
two = mkTwo.id
@mkThree
three = mkThree.id
@mkBorder
border = mkBorder.id

; --- emlGroupSortAlphabetical ---------------------------------------------
; The global with no control of its own. The graphs form sets it from
; config_groupSort; nothing else in the dialog mentions it.
emlGroupSortAlphabetical = 0
@runVariant: "emlGroupSortAlphabetical", "0", two, 0.05, "both", 1, 1,
... "parametric", 2
emlGroupSortAlphabetical = 1
@runVariant: "emlGroupSortAlphabetical", "1", two, 0.05, "both", 1, 1,
... "parametric", 2
emlGroupSortAlphabetical = 0

; --- testType$ -------------------------------------------------------------
@runVariant: "emlRunAnnotationComparison.testType$", "parametric", three, 0.05,
... "p-value", 1, 1, "parametric", 2
@runVariant: "emlRunAnnotationComparison.testType$", "nonparametric", three,
... 0.05, "p-value", 1, 1, "nonparametric", 2

; --- annotCorrectionMethod$ ------------------------------------------------
; Only the nonparametric arm consults it: Tukey's p is already family-wise and
; that arm never reads the method. Measured on the arm that does.
annotCorrectionMethod$ = "holm"
@runVariant: "annotCorrectionMethod$", "holm", three, 0.05, "p-value", 1, 1,
... "nonparametric", 2
annotCorrectionMethod$ = "bonferroni"
@runVariant: "annotCorrectionMethod$", "bonferroni", three, 0.05, "p-value",
... 1, 1, "nonparametric", 2
annotCorrectionMethod$ = "holm"

; --- .alpha ----------------------------------------------------------------
; ON THE BORDERLINE TABLE AND IN MATRIX MODE, both deliberately. Alpha does
; not move a p-value, it moves the VERDICT taken from one, and the verdict is
; only ever written down as a number on the matrix arm (annotMatrixSig); the
; bracket arm states it by omitting the bracket, which this file reads as
; suppression rather than as a value. On a table where every pair is
; overwhelming, alpha has nothing to move and the leg would be a negative that
; means nothing.
;
; annotAlpha is moved WITH .alpha here because that is what the graphs form
; does -- it passes the one dialog value into both channels. The leg below
; separates them on purpose.
annotAlpha = 0.05
@runVariant: "emlRunAnnotationComparison.alpha", "0.05", border, 0.05, "stars",
... 1, 1, "parametric", 3
annotAlpha = 0.01
@runVariant: "emlRunAnnotationComparison.alpha", "0.01", border, 0.01, "stars",
... 1, 1, "parametric", 3
annotAlpha = 0.05

; --- the two alpha channels, observed rather than classified ---------------
; .alpha (the argument) decides annotMatrixSig; annotAlpha (the global)
; decides the star ladder @emlFormatStars applies and the alpha every
; confidence interval in the reporters is built at (@emlCIAlphaInForce).
; The form keeps them equal. Nothing makes them equal. Recorded as obs. rows
; so a reader can see what a caller that sets only one of them gets.
annotAlpha = 0.05
@runVariant: "obs.alphaChannels", "argument 0.01, global 0.05", border, 0.01,
... "stars", 1, 1, "parametric", 3
annotAlpha = 0.05
@runVariant: "obs.alphaChannels", "argument 0.05, global 0.05", border, 0.05,
... "stars", 1, 1, "parametric", 3

; --- .style$ ---------------------------------------------------------------
@runVariant: "emlRunAnnotationComparison.style$", "p-value", three, 0.05,
... "p-value", 1, 1, "parametric", 2
@runVariant: "emlRunAnnotationComparison.style$", "stars", three, 0.05, "stars",
... 1, 1, "parametric", 2

; --- .showNS ---------------------------------------------------------------
; NONPARAMETRIC, so that two of the three pairs are genuinely not significant
; and showNS = 0 has something to suppress. On the parametric table every pair
; is overwhelming and the setting does nothing at all, which would be a
; negative about the table rather than about the setting.
@runVariant: "emlRunAnnotationComparison.showNS", "0", three, 0.05, "p-value",
... 0, 1, "nonparametric", 2
@runVariant: "emlRunAnnotationComparison.showNS", "1", three, 0.05, "p-value",
... 1, 1, "nonparametric", 2

; --- .showEffect -----------------------------------------------------------
@runVariant: "emlRunAnnotationComparison.showEffect", "0", three, 0.05,
... "p-value", 1, 0, "parametric", 2
@runVariant: "emlRunAnnotationComparison.showEffect", "1", three, 0.05,
... "p-value", 1, 1, "parametric", 2

; --- .layoutMode -----------------------------------------------------------
@runVariant: "emlRunAnnotationComparison.layoutMode", "2", three, 0.05,
... "p-value", 1, 1, "parametric", 2
@runVariant: "emlRunAnnotationComparison.layoutMode", "3", three, 0.05,
... "p-value", 1, 1, "parametric", 3

removeObject: two, three, border
appendInfoLine: "settings probe: wrote ", outPath$
