# ============================================================================
# harness/settingspub/settingspub_drive.praat -- the settings that decide the
# numbers reach the recorded script, and a replay obeys them
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS RIG IS FOR.
#
# A recorded step is a procedure CALL WITH ITS ARGUMENTS. A setting the plugin
# passes as an argument is therefore in the record, and a setting the plugin
# reads from a global is not -- and three of the globals the computing layer
# reads decide what the answer IS rather than how it looks:
#
#   annotCorrectionMethod$    the multiple-comparison correction, resolved
#                             inside @emlRunAnnotationComparison, which has no
#                             parameter for it
#   annotAlpha                the level every confidence interval in the
#                             reporters is built at, through @emlCIAlphaInForce
#   emlGroupSortAlphabetical  the order @emlCountGroups puts the levels in,
#                             which decides which level is group 1
#
# GREPPING THE EMITTED SCRIPT FOR THOSE NAMES WOULD PROVE THE NAMES WERE
# WRITTEN, WHICH IS NOT THE CLAIM. The claim is that a replay computes the
# session's numbers. So every leg here RECORDS a session at a stated value,
# EMITS the script, RUNS it in a fresh Praat process, and reports the numbers
# from BOTH sides. Each setting is driven at two values, because a rig that
# drove one could not tell "the replay obeyed the setting" from "the replay
# fell back to a default that happens to equal it".
#
# THE REPLAY RUNS THE EMITTED FILE THROUGH include RATHER THAN runScript:, and
# that is a property of the RIG, not of the product. Both execute the same
# text; runScript: gives the emitted file its own variable space, so the
# answers it computes -- the adjusted p-values in annotBracketP[], the
# resolved correction in annotBracketAdjust$ -- would be unreadable from here
# and the rig could only compare Info text. include shares the scope, so the
# numbers themselves can be read out and compared. The Info report is captured
# as well, from the same run, so nothing rests on the choice.
#
# ONE LEG PER PRAAT PROCESS, chosen by $EML_SP_LEG, for the reason
# harness/stress_graphs.sh gives: a Praat script error aborts the script, so a
# dozen legs in one process report one failure and hide eleven.
#
# $EML_SP_SRC points a leg at a DIFFERENT COPY of the repository, which is how
# validate/v115's break test replays against a library whose capture has been
# removed without touching the working tree.
#
# Env in:  EML_SP_LEG   leg name
#          EML_SP_OUT   TSV to append key/value pairs to
#          EML_SP_AUX   scratch folder for this leg
#          EML_SP_ROOT  the source tree this leg is running out of
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-psychometrics.praat
include ../../plugin/stats/eml-categorical.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/stats/eml-demo-tables.praat

# EVERY FILE THIS DRIVE WRITES IS UTF-8, AND SAYING SO IS NOT OPTIONAL. Praat
# converts a file to UTF-16 the moment a non-ASCII character is written into
# it, and a validator reading a UTF-16 TSV with readLines() sees keys spelled
# "l e g" with NULs between the letters -- which is indistinguishable from a
# harness that never ran.
Text writing preferences: "UTF-8"

@emlInitializeDrawingDefaults

leg$ = environment$ ("EML_SP_LEG")
out$ = environment$ ("EML_SP_OUT")
aux$ = environment$ ("EML_SP_AUX")
spRoot$ = environment$ ("EML_SP_ROOT")
if out$ = ""
    exitScript: "EML_SP_OUT unset."
endif

procedure emit: .key$, .value$
    appendFileLine: out$, .key$, tab$, .value$
endproc

# ---------------------------------------------------------------------------
# THE FIXTURES. Deterministic -- a comparison between two processes cannot be
# built on randomGauss with no seed -- and saved to CSV, because the emitted
# script names its object and the replay has to be able to open one of that
# name holding those numbers.
#
# THE THREE-GROUP FIXTURE IS SEPARATED ENOUGH FOR DUNN TO REJECT AND CLOSE
# ENOUGH FOR THE CORRECTION TO MATTER. If every pair were significant under
# both corrections the two legs would agree by luck, and if none were the
# brackets would be empty; showNS = 1 keeps every pair on the figure either
# way, so the leg reads the adjusted p itself rather than a survival count.
#
# THE TWO-GROUP FIXTURE'S LABELS SORT AGAINST THEIR ORDER OF APPEARANCE:
# "zulu" is the first level in the file and the second in the alphabet. So
# discovery order and alphabetical order name different groups first, and the
# mean difference the report prints changes SIGN between them. Labels that
# sorted the way they appeared would leave the sort leg unable to fail.
# ---------------------------------------------------------------------------
procedure spTable3
    Create Table with column names: "fx", 0, "grp val"
    .row = 0
    .rng = 20260824
    for .g from 1 to 3
        for .k from 1 to 12
            .rng = (1103515245 * .rng + 12345) mod 2147483648
            .u = .rng / 2147483648
            .row = .row + 1
            Append row
            Set string value: .row, "grp", "Cohort " + string$ (.g)
            Set numeric value: .row, "val", 200 + .g * 7 + (.u - 0.5) * 22
        endfor
    endfor
    .id = selected ("Table")
endproc

procedure spTable2
    Create Table with column names: "fx", 0, "grp val"
    .row = 0
    .rng = 20260824
    for .g from 1 to 2
        for .k from 1 to 14
            .rng = (1103515245 * .rng + 12345) mod 2147483648
            .u = .rng / 2147483648
            .row = .row + 1
            Append row
            if .g = 1
                Set string value: .row, "grp", "zulu"
            else
                Set string value: .row, "grp", "alfa"
            endif
            Set numeric value: .row, "val", 200 + .g * 9 + (.u - 0.5) * 12
        endfor
    endfor
    .id = selected ("Table")
endproc

procedure spSaveFixture: .id
    selectObject: .id
    Save as comma-separated file: aux$ + "/fx.csv"
endproc

procedure spRecordBegin
    @emlRecordInit
    emlRecordPluginRoot$ = spRoot$ + "/plugin"
    @emlRecordBegin: aux$
    emlRecordPluginRoot$ = spRoot$ + "/plugin"
    @emlRecordLoadPhrases: spRoot$ + "/plugin/data/eml-record-phrases.csv"
    @emlRecordHeader: "fx", 36, 2, "settings publication"
endproc

# WHAT THE BRIDGE ANSWERED, read off the arrays it fills rather than off the
# figure it would draw. The adjusted p-values ARE the correction's effect, so
# they are what the two correction legs compare.
procedure spEmitBrackets: .prefix$
    @emit: .prefix$ + "_brackets", string$ (annotBracketN)
    @emit: .prefix$ + "_adjust", annotBracketAdjust$
    for .b from 1 to annotBracketN
        @emit: .prefix$ + "_p" + string$ (.b),
        ... fixed$ (annotBracketP[.b], 6)
        @emit: .prefix$ + "_label" + string$ (.b), annotBracketLabel$[.b]
    endfor
endproc

# ===========================================================================
# THE RECORD LEGS
# ===========================================================================
# Each states the three settings outright, runs one computing step, and
# flushes. Stating all three on every leg -- not just the one under test --
# is what makes a leg's emitted script comparable with its sibling's: two
# scripts that differ in one line differ because of the setting, and a leg
# that left the other two to whatever the process happened to hold could not
# say that.
# ===========================================================================
procedure spSettings: .corr$, .alpha, .sort
    annotCorrectionMethod$ = .corr$
    annotAlpha = .alpha
    emlGroupSortAlphabetical = .sort
    @emit: leg$ + "_set_corr", .corr$
    @emit: leg$ + "_set_alpha", string$ (.alpha)
    @emit: leg$ + "_set_sort", string$ (.sort)
endproc

if leg$ = "corr_holm" or leg$ = "corr_bonf"
    corr$ = "holm"
    if leg$ = "corr_bonf"
        corr$ = "bonferroni"
    endif
    @spTable3
    @spSaveFixture: spTable3.id
    @spRecordBegin
    @spSettings: corr$, 0.05, 0
    @emlClearAnnotations
    @emlRunAnnotationComparison: spTable3.id, "val", "grp", 0.05, "p-value",
    ... 1, 0, "nonparametric", 2
    @emit: leg$ + "_bridge_error", emlRunAnnotationComparison.error$
    @emit: leg$ + "_omnibus", emlRunAnnotationComparison.omnibus$
    @spEmitBrackets: leg$ + "_session"
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: leg$ + "_flushed", string$ (emlRecordFlush.written)

elsif leg$ = "alpha_05" or leg$ = "alpha_01" or leg$ = "sort_disc" or leg$ = "sort_alpha"
    alpha = 0.05
    sort = 0
    if leg$ = "alpha_01"
        alpha = 0.01
    endif
    if leg$ = "sort_alpha"
        sort = 1
    endif
    @spTable2
    @spSaveFixture: spTable2.id
    @spRecordBegin
    @spSettings: "holm", alpha, sort
    clearinfo
    @emlRunTwoGroupAnalysis: spTable2.id, "val", "grp", "parametric", 0
    writeFileLine: aux$ + "/session_info.txt", info$ ()
    @emlRecordFlush: aux$ + "/emitted.praat"
    @emit: leg$ + "_flushed", string$ (emlRecordFlush.written)

else
    exitScript: "unknown leg: " + leg$
endif
