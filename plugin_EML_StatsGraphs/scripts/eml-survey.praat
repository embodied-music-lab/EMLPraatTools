# ============================================================================
# EML Stats & Graphs — Survey subscale report (Stage 2, presentation half)
# ============================================================================
# Module: scripts/eml-survey.praat
# Version: 1.1
# Date: 26 August 2026
#
# V1.1: THE APPROVED STAGE 3 AMENDMENTS. (1) The DRAFT routing sentence
#       (moved to stats/eml-psychometrics.praat's refusal 8) is out of
#       scope for this file; unrelated here. (2) The annotate toggle: the
#       plugin's standard "Annotate results with explanations" boolean,
#       default OFF, following the same auto-naming convention every
#       other menu door's boolean already gets from its own
#       beginPause/endPause form (@eml_survey_annotateOn). Still NO
#       dialog page built here -- Stage 3 adds the control; this file
#       only reads the state a future control will set. Three lines now
#       FOLLOW it (the ordinal-as-interval note, the item-rest gloss, the
#       negative item-rest flag's suggestion); four print ALWAYS
#       (reversed items, exclusions, the placeholder disclosure, KR-20).
#       Both classes are declared once, in @emlSurveyLineRouting, not
#       repeated at each call site.
#
# WHAT THIS FILE IS. Stage 1 (@emlSurveyValidateDeclaration) decides whether
# a survey declaration is sound. Stage 2's computational half
# (@emlSurveyScoreScales, @eml_reverseScoreMatrix, @emlSurveySubscaleDisclosure
# -- stats/eml-psychometrics.praat) turns a sound declaration into raw
# numbers: alpha, its Feldt interval, item-deleted values, respondent
# influence, item-rest/item-total, and complete-case scale scores. THIS file
# is Stage 2's presentation half: it turns those raw numbers into the printed
# report and the CSV export. NO dialog page and NO menu registration live
# here -- Stage 3 (the interactive front end that collects the three file
# paths from a user) waits on Ian's language approval, per the ruling, and
# is not built by this file.
#
# STAGE 3 NOTE -- THE WIDE-FORMAT / DECLARATION-ONLY-MEMBERSHIP CONTRACT.
# The data table Stage 1 validates is wide: one row per respondent, one
# column per question; subscale membership lives only in the items
# declaration's `role` column, never inferred from a data column's name.
# This is stated once, in evidence/csv/lane_survey_declared_SCHEMA.md ("The
# data table: wide format, one row per respondent"). When Stage 3 builds
# its draft-scan page, that page should RENDER this fact from the
# declaration it is showing, not restate or re-derive it -- the SCHEMA.md
# section is the canon.
#
# ----------------------------------------------------------------------------
# THE DOOR BODY IS SEPARABLE FROM THE REPORTING PROCEDURES. HOW.
# ----------------------------------------------------------------------------
#
#   1. THIS FILE HAS NO TOP-LEVEL EXECUTION. Every stats/*.praat module in
#      this plugin is a pure procedure library -- `include`-ing one runs no
#      code, it only makes procedures callable -- and this file keeps that
#      same discipline even though it lives in scripts/ rather than stats/.
#      Nothing here raises a dialog or writes a file merely by being
#      included. That is what makes it safe to include from a harness or a
#      future Stage-3 menu script alike, and safe for validate/'s own probes
#      to include directly, exactly the way they already include
#      stats/eml-psychometrics.praat.
#
#   2. @emlSurveyRunReport IS THE ONLY "DOOR" PROCEDURE -- the one a future
#      Stage-3 dialog, or today's harness, actually calls. It does file I/O
#      (three `Read Table from comma-separated file:` calls) and
#      orchestration (call the validator, stop and echo its refusal if any,
#      otherwise call the scorer, loop the reporting procedures over every
#      subscale, and call the CSV export if a path was given) -- and NOTHING
#      ELSE. It contains no report SENTENCE of its own beyond echoing Stage
#      1's own .error$/.remedy$ verbatim (never new wording) and two banner
#      lines that are pure section punctuation, not a claim about the data.
#
#   3. EVERY REPORT SENTENCE LIVES IN THE REPORTING PROCEDURES BELOW THE
#      DOOR, each one small, named for the one block of the plan it builds
#      (@eml_survey_lineAlpha, @eml_survey_lineReversed, ...), each callable
#      on its own once @emlSurveyValidateDeclaration and @emlSurveyScoreScales
#      have already run on a Table -- which is exactly what
#      validate/v132_survey_report_layer.R does: it drives the real
#      declaration and scorer once per fixture and then calls
#      @emlSurveyBuildSubscaleReport directly, per subscale, without ever
#      going through @emlSurveyRunReport's file-reading door. A check that
#      could only reach the report by also exercising three file reads and a
#      dialog-shaped door would be testing the door, not the report; keeping
#      them separate procedures is what lets it test only the report.
#
#   4. THE CSV EXPORT (@emlSurveyExportCSV) is a THIRD, independent
#      procedure, callable on its own the same way, that goes through the
#      plugin's EXISTING long-format writer (@emlCSVInit / @emlCSVSetTable /
#      @emlCSVTermType / @emlCSVAdd / @emlCSVAddStr / @emlExportStatsCSV,
#      stats/eml-output.praat) rather than a new one. It is not a reporting
#      procedure in the sense of #3 above (it writes a file, not the Info
#      window) and not the door in the sense of #2 (it does no file
#      READING and drives no validation) -- it is its own third thing, and
#      @emlSurveyRunReport calls it only when handed a non-empty export
#      path, exactly as it calls the reporting loop only when the
#      declaration was sound.
#
# WHY THE DOOR READS PATHS, NOT TABLE IDS. @emlSurveyRunReport takes three
# file PATHS and does the `Read Table from comma-separated file:` calls
# itself, rather than taking three already-loaded Table IDs from a caller.
# That is the provenance rule for a recorded script: Praat's script recorder
# transcribes commands verbatim, so a user who records a run of this door
# gets a script whose own text cites both declaration files (and the data
# file) BY PATH, on the two lines that read them -- provenance that a door
# taking bare Table IDs could never leave in a recording, since by the time
# an ID reaches this procedure the command that produced it (and the path
# that command named) is already outside the recorded frame. The same
# reason is why @emlSurveyExportCSV writes the two declaration paths into
# the CSV itself as ordinary rows (fields "items_file" / "scales_file" /
# "data_file") rather than only relying on the recording -- an export opened
# on its own, with no recording alongside it, still names its own inputs.
#
# ----------------------------------------------------------------------------
# Dependencies (a caller `include`s these, in this order, before this file):
#   include eml-core-utilities.praat
#   include eml-extract.praat
#   include eml-inferential.praat
#   include eml-analysis.praat
#   include eml-output.praat
#   include eml-psychometrics.praat
#   include eml-survey.praat
# -- the same modules @emlSurveyScoreScales already needs
# (eml-psychometrics.praat's own header: eml-extract.praat,
# eml-inferential.praat, eml-analysis.praat), plus eml-output.praat for the
# CSV writer this file calls but does not define, plus
# eml-core-utilities.praat, which eml-output.praat's own writer needs in turn
# for @emlGenerateUniquePath (its own header explains why: the non-
# destructive uniquing both export arms share). A production caller inside
# the plugin gets all of this, in the right order, from one line:
#   include eml-lib.praat
#   include ../scripts/eml-survey.praat
#
# PRECONDITION shared by every reporting procedure below (never re-checked
# here, exactly like @emlSurveyScoreScales's own documented precondition):
# the caller has already run @emlSurveyValidateDeclaration on .dataTableId,
# confirmed .refusal = 0, and already run @emlSurveyScoreScales on the same
# .dataTableId. @emlSurveyRunReport (the door) satisfies this itself before
# calling any reporting procedure; a caller that calls a reporting procedure
# directly (as validate/v132 does) owes it the same two calls first.
#
# Part of the EML Stats library (EML Praat Tools).
# License: GPL-3.0-or-later
#
# Provides: @emlSurveyRunReport (the door),
#   @emlSurveyBuildSubscaleReport, @emlSurveyReportSubscale (the reporting
#   procedures' entry points), @emlSurveyExportCSV (the CSV export)
#
# Internal helpers: @emlSurveyReportLanguage (the one DRAFT LANGUAGE block),
#   @eml_survey_annotateOn (the one declaration of the annotate toggle's
#   state), @emlSurveyLineRouting (the one declaration of which lines it
#   gates), @eml_survey_formatPercent, @eml_survey_lineAlpha,
#   @eml_survey_lineItemDeleted, @eml_survey_lineInfluence,
#   @eml_survey_lineN, @eml_survey_lineReversed, @eml_survey_lineType,
#   @eml_survey_lineKR20, @eml_survey_lineItemRest,
#   @eml_survey_lineDisclosure, @eml_survey_lineScore
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — every user-facing sentence below is DRAFT,
#   awaiting Ian's review before Stage 3 wires this into a dialog.
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================


# ============================================================================
# DRAFT LANGUAGE -- awaiting Ian's approval, all of it, exactly like every
# other user-facing sentence @emlSurveyValidateDeclaration itself builds
# (eml-psychometrics.praat's own "DRAFT LANGUAGE" block, above). Every
# fragment below is prose; nothing below this procedure should need to
# change when approved wording drops in -- every call site reads a fragment
# VARIABLE from here, never a literal string of its own. Section LABELS at
# each call site ("Alpha:", "n / exclusions:", ...) are NOT in this block on
# purpose: they are structural navigation aids, the same role "N =" and
# "Mean =" already play in every other report this plugin prints, not a
# substantive claim about the data that needs Ian's sign-off. The
# SENTENCES that follow each label are the thing awaiting approval.
# ============================================================================
procedure emlSurveyReportLanguage
    .msgDeclRefused$ = "The survey declaration was refused, so no subscale "
    ... + "report was built. "

    .msgAlphaOkA$ = "Cronbach's alpha for this subscale is "
    .msgAlphaOkB$ = ", with a "
    .msgAlphaOkC$ = "% Feldt confidence interval of "
    .msgAlphaOkD$ = " to "
    .msgAlphaOkE$ = "."

    .msgItemDelHeader$ = "Alpha if each item were dropped:"
    # V1.10: split into two fragments, joined at the call site with the
    # SUBSCALE'S OWN item count, rather than one literal sentence that
    # assumed the count -- see @eml_survey_lineItemDeleted, below, for why.
    # "3" here is @emlCronbachAlpha's own alpha-if-deleted floor
    # (eml-psychometrics.praat, "if .k >= 3" inside @emlCronbachAlpha) typed
    # as a numeral rather than spelled out, so
    # validate/v132_survey_report_layer.R's parity check can read this
    # fragment and that line with the same regex and assert they still
    # agree, instead of only this file's author trusting they do.
    .msgItemDelNAa$ = "Not computed: alpha-if-item-deleted needs at least "
    ... + "3 items in the subscale; this one has "
    .msgItemDelNAb$ = "."
    .msgItemDelRefused$ = "Not computed: alpha itself did not compute for "
    ... + "this subscale (see Alpha, above)."

    .msgInflHeader$ = "Leave-one-out respondent influence, by the "
    ... + "respondent's original row number in the data table:"
    .msgInflMostA$ = "The most influential respondent is original row "
    .msgInflMostB$ = ", which changes alpha by "
    .msgInflMostC$ = " if removed."
    .msgInflRefusedA$ = "Respondent influence could not be computed for "
    ... + "this subscale: "

    .msgNA$ = "n = "
    .msgNB$ = " complete respondent(s); "
    .msgNC$ = " excluded by listwise deletion."

    .msgReversedNone$ = "No items in this subscale are reverse-scored."
    .msgReversedSomeA$ = "Reverse-scored item(s): "
    .msgReversedSomeB$ = "."

    .msgTypeOrdinal$ = "This subscale's response options are ordinal (an "
    ... + "ordered rating, not a measurement with equal intervals between "
    ... + "steps); the statistics above treat them as interval-scaled "
    ... + "anyway, which is the field's conventional practice but an "
    ... + "assumption worth stating rather than leaving silent."
    .msgTypeContinuous$ = "This subscale's declared type is continuous, so "
    ... + "no ordinal-as-interval assumption is being made for it."

    .msgKR20$ = "This subscale's declared response range spans exactly two "
    ... + "values, so its reliability statistic above is equivalent to "
    ... + "KR-20; the underlying computation is identical to Cronbach's "
    ... + "alpha above, only the name changes."

    .msgItemRestHeader$ = "Item-rest correlation (each item against the "
    ... + "sum of the OTHER items in this subscale):"
    # Stage 3 ruling, item 2: the ALWAYS-print header, used in place of
    # .msgItemRestHeader$ above when the annotate toggle is off -- same
    # section, same per-item values below it, minus the parenthetical
    # GLOSS of what the number means (an EXPLANATION, per
    # @emlSurveyLineRouting's own classification, not a fact).
    .msgItemRestHeaderBare$ = "Item-rest correlation:"
    .msgItemRestFlagA$ = "  [EVIDENCE, not an action: this correlation is "
    ... + "negative, which can indicate a misdeclared reversal for this "
    ... + "item. No change has been made.]"
    .msgItemRestNA$ = "  (not available: this item's column has no "
    ... + "variance, or too few complete respondents, to compute a "
    ... + "correlation)"

    .msgDisclA$ = "In this subscale, "
    .msgDisclB$ = " cell(s), in item(s) "
    .msgDisclC$ = ", held a recognized missing-value placeholder instead "
    ... + "of a response and were treated as missing data, exactly like a "
    ... + "blank cell -- not guessed at. Spelling(s) found: "
    .msgDisclD$ = ". (Full run-wide detail is printed once, above, by the "
    ... + "declaration check.)"

    .msgScoreA$ = "Scale score (the mean of this subscale's reverse-scored "
    ... + "items, complete case): mean = "
    .msgScoreB$ = ", sd = "
    .msgScoreC$ = ", range "
    .msgScoreD$ = " to "
    .msgScoreE$ = ". "
    .msgScoreF$ = " respondent(s) received a score; "
    .msgScoreG$ = " received none."

    .msgCsvOkA$ = "CSV export written to "
    .msgCsvOkB$ = "."
    .msgCsvRenamedA$ = "CSV export requested at "
    .msgCsvRenamedB$ = " already exists; wrote to "
    .msgCsvRenamedC$ = " instead."
    .msgCsvFailEmpty$ = "CSV export was not written: nothing was collected "
    ... + "to write."
    .msgCsvFailWriteA$ = "CSV export to "
    .msgCsvFailWriteB$ = " failed: the file could not be written."
endproc


# ============================================================================
# @eml_survey_annotateOn
# ============================================================================
# THE ONE DECLARATION of the "Annotate results with explanations" toggle's
# EFFECTIVE state (Stage 3 ruling, item 2). Default OFF: the toggle is the
# plugin's standard boolean, the same one every other menu analysis dialog
# carries on its page, following the SAME Praat auto-naming convention
# every one of those already relies on for reading its own booleans back
# (a `beginPause`/`endPause` label becomes a bare global exactly as typed,
# first word lowercased -- verified live against the shipped doors:
# scripts/eml-lmm.praat's "Use REML" is read back as `use_REML`, and
# "Clear Info window" (present on that same door, and on most others in
# scripts/) as `clear_Info_window`; stats/eml-lmm.praat, this lane's
# nearer namesake, is a pure procedure library and raises no dialog of
# its own at all) -- so "Annotate results with
# explanations" becomes `annotate_results_with_explanations`, and THIS
# file builds no dialog page of its own to declare it (per this file's own
# header, and the ruling: Stage 3 adds the control; Stage 2's report layer
# only wires its state). Undefined -- true of every harness/validate probe
# in this lane today, and of any caller reached before Stage 3's dialog
# ever runs once it exists -- is OFF, exactly the boolean's own eventual
# default of 0; only an explicit 1 turns it on. Every call site that needs
# to know calls THIS procedure, never a second `variableExists (...)`
# check of its own, so no two call sites can quietly default the same
# question two different ways.
# ----------------------------------------------------------------------------
procedure eml_survey_annotateOn
    .on = 0
    if variableExists ("annotate_results_with_explanations")
        if annotate_results_with_explanations = 1
            .on = 1
        endif
    endif
endproc


# ============================================================================
# @emlSurveyLineRouting
# ============================================================================
# THE ONE DECLARATION of which report lines the annotate toggle gates
# (Stage 3 ruling, item 2) -- a source-readable registry, not a second,
# separately maintained list inside validate/. Every name below
# corresponds to exactly one line-builder call in
# @emlSurveyBuildSubscaleReport, below; validate/v132_survey_report_layer.R
# reads THIS procedure's FOLLOWS array from source, then separately
# restates the three FOLLOWS names literally (validate/v132, section 8) to
# confirm each one is still present in the array read from source. THAT
# catches a line moved OUT of FOLLOWS into ALWAYS -- the missing name fails
# the restated check -- but NOT the other direction: the ALWAYS array there
# is checked only for being non-empty, never for which names it holds, so
# an ALWAYS line quietly moved into FOLLOWS (or duplicated there without
# removing it from ALWAYS) is caught by nothing in that check, or anywhere
# else in this file.
# THIS DOES NOT MEAN EVERY v132 toggle check is built purely from these
# two arrays, though: telling the bare item-rest header from the glossed
# one apart needs to know what the gloss text SAYS, not just that it is
# classified FOLLOWS, so that one check additionally restates a literal
# fragment of the gloss string (see its own comment in v132, section 8).
#
# THIS PROCEDURE HAS NO PRODUCTION CALLER. It is called from nowhere at
# runtime -- not from @emlSurveyBuildSubscaleReport, not from any
# @eml_survey_line* builder -- only read out of source, as text, by
# validate/v132 above. Each line-builder decides its OWN ALWAYS/FOLLOWS
# membership independently, by calling @eml_survey_annotateOn directly
# (e.g. @eml_survey_lineType, @eml_survey_lineItemRest below); this
# procedure's two arrays are a hand-maintained restatement of what those
# independent decisions add up to, kept only so validate/ has one
# source-readable place to read the classification FROM, never enforced
# at runtime by being called. A line-builder's own gating and this
# registry's say-so can therefore drift apart by hand-editing one and not
# the other; nothing in this file catches that, only validate/v132's own
# comparison against each line-builder's actual behavior does.
#
# ALWAYS (print unconditionally, toggle on or off): each states a FACT
# about what was computed or found in THIS run, never an interpretation of
# it -- reversed items, exclusions (n), the placeholder disclosure, the
# KR-20 note.
#
# FOLLOWS (print only when the toggle is on): each is an EXPLANATION, but
# ONLY TWO OF THE THREE share the rationale "of a fact that already prints
# elsewhere regardless of the toggle" -- the item-rest gloss (the
# item-rest r value itself is not gated: it prints, per item, in the
# ALWAYS header/list above) and the negative item-rest flag's suggestion
# (the sign of r is not gated -- a reader can already see it is negative
# without this line). THE ORDINAL-AS-INTERVAL NOTE DOES NOT: the declared
# type ("ordinal"/"continuous") is read from
# emlSurveyValidateDeclaration.scaleType$[.s] in exactly one place in this
# file, @eml_survey_lineType itself -- the FOLLOWS-only line under
# discussion -- so with the toggle off, the type is not merely explained
# less; it is not printed anywhere in the report at all. Its FOLLOWS
# classification rests on a different footing: it is Ian's own ruling
# (Stage 3 ruling, item 2) that this note is an interpretive caveat about
# treating ordinal data as interval-scaled for alpha's purposes, not a
# raw fact the report owes a reader unconditionally -- not on the
# "already printed elsewhere" reasoning the other two FOLLOWS lines
# actually have.
# ----------------------------------------------------------------------------
procedure emlSurveyLineRouting
    .alwaysCount = 4
    .always$[1] = "reversed items"
    .always$[2] = "exclusions (n)"
    .always$[3] = "placeholder disclosure"
    .always$[4] = "KR-20 note"

    .followsCount = 3
    .follows$[1] = "ordinal-as-interval note"
    .follows$[2] = "item-rest gloss"
    .follows$[3] = "negative item-rest flag suggestion"
endproc


# ============================================================================
# @eml_survey_formatPercent: .frac  ->  .text$
# ============================================================================
# "95" from 0.95, "97.5" from 0.975 -- one decimal place, trimmed back to a
# whole number when the tenths digit is 0, the same trim-a-fixed-string
# idiom @emlReportAlpha (eml-analysis.praat) already uses for the alpha
# level itself. Exists so "the confidence level ... named with that level"
# has one formatting site, not one written out at every call site that
# needs it.
# ----------------------------------------------------------------------------
procedure eml_survey_formatPercent: .frac
    .text$ = fixed$ (.frac * 100, 1)
    if right$ (.text$, 2) = ".0"
        .text$ = left$ (.text$, length (.text$) - 2)
    endif
endproc


# ============================================================================
# @eml_survey_lineAlpha: .s  ->  .line$
# ============================================================================
# "Alpha with the Feldt interval at the level in force, named with that
# level." The level is read from emlSurveyScoreScales.confidence, which
# itself came from @emlReportAlpha and nowhere else (eml-psychometrics.
# praat's own header on @emlSurveyScoreScales) -- never a literal here.
# ----------------------------------------------------------------------------
procedure eml_survey_lineAlpha: .s
    @emlSurveyReportLanguage
    if emlSurveyScoreScales.subAlphaError$[.s] <> ""
        .line$ = emlSurveyScoreScales.subAlphaError$[.s]
    else
        @eml_survey_formatPercent: emlSurveyScoreScales.confidence
        .pct$ = eml_survey_formatPercent.text$
        .line$ = emlSurveyReportLanguage.msgAlphaOkA$
        ... + string$ (emlSurveyScoreScales.subAlpha[.s])
        ... + emlSurveyReportLanguage.msgAlphaOkB$ + .pct$
        ... + emlSurveyReportLanguage.msgAlphaOkC$
        ... + string$ (emlSurveyScoreScales.subCiLow[.s])
        ... + emlSurveyReportLanguage.msgAlphaOkD$
        ... + string$ (emlSurveyScoreScales.subCiHigh[.s])
        ... + emlSurveyReportLanguage.msgAlphaOkE$
    endif
endproc


# ============================================================================
# @eml_survey_lineItemDeleted: .s  ->  .line$
# ============================================================================
# "The item-deleted table." One line per item, or a stated reason there is
# none: the alpha kernel refused (see Alpha, above -- the SAME refusal, not
# repeated a second time), or the subscale is too small for
# alpha-if-deleted to have anything to drop to.
#
# V1.10: "too small" is READ off @emlCronbachAlpha's OWN verdict, not
# re-derived from a restated floor. @emlSurveyScoreScales
# (eml-psychometrics.praat) copies emlCronbachAlpha.alphaIfDeleted# into
# .subAlphaIfDeleted[.s,*] verbatim; that vector is undefined at every
# index precisely when @emlCronbachAlpha's own "if .k >= 3" gate did not
# run (eml-psychometrics.praat), because a subscale that reaches this line
# already passed refusal 3 (k >= 2) and the .subAlphaError$[.s] <> "" arm
# above, so item 1 is undefined here if and only if k = 2 -- the ONLY value
# k >= 2 can hold that is also k < 3. Asking .subK[.s] < 3 directly would
# restate that same "3" a second time with nothing keeping the two in
# sync; asking whether the kernel actually left its own output undefined
# needs no restatement at all. See validate/v129's [alpha-if-deleted floor]
# demo for a seeded subscale that exercises this branch, and
# validate/v132's parity check for the "3" that DOES still have to be
# stated in English, in .msgItemDelNAa$ above.
# ----------------------------------------------------------------------------
procedure eml_survey_lineItemDeleted: .s
    @emlSurveyReportLanguage
    .line$ = emlSurveyReportLanguage.msgItemDelHeader$
    if emlSurveyScoreScales.subAlphaError$[.s] <> ""
        .line$ = .line$ + newline$ + "  "
        ... + emlSurveyReportLanguage.msgItemDelRefused$
    elsif emlSurveyScoreScales.subAlphaIfDeleted[.s, 1] = undefined
        .line$ = .line$ + newline$ + "  "
        ... + emlSurveyReportLanguage.msgItemDelNAa$
        ... + string$ (emlSurveyScoreScales.subK[.s])
        ... + emlSurveyReportLanguage.msgItemDelNAb$
    else
        for .j from 1 to emlSurveyScoreScales.subK[.s]
            .origIdx = emlSurveyScoreScales.subItemOrigIdx[.s, .j]
            .itemName$ = emlSurveyValidateDeclaration.itemName$[.origIdx]
            .line$ = .line$ + newline$ + "  " + .itemName$ + ": "
            ... + string$ (emlSurveyScoreScales.subAlphaIfDeleted[.s, .j])
        endfor
    endif
endproc


# ============================================================================
# @eml_survey_lineInfluence: .s  ->  .line$
# ============================================================================
# "Leave-one-out respondent influence with ORIGINAL row numbers, not
# post-deletion positions." emlSurveyScoreScales.subRowIndex[.s, .r]
# (V1.8, @emlAlphaInfluence's own .rowIndex# passed through unrenamed) is
# already the ORIGINAL row number in the data table -- @emlAlphaInfluence's
# own header states the guarantee ("ORIGINAL row number of surviving
# respondent j") and this line reads that field directly rather than the
# loop position .r, which would be the post-deletion position the ruling
# says not to print.
# ----------------------------------------------------------------------------
procedure eml_survey_lineInfluence: .s
    @emlSurveyReportLanguage
    if emlSurveyScoreScales.subInfluenceError$[.s] <> ""
        .line$ = emlSurveyReportLanguage.msgInflRefusedA$
        ... + emlSurveyScoreScales.subInfluenceError$[.s]
    else
        .line$ = emlSurveyReportLanguage.msgInflHeader$
        for .r from 1 to emlSurveyScoreScales.subN[.s]
            .origRow = emlSurveyScoreScales.subRowIndex[.s, .r]
            .line$ = .line$ + newline$ + "  row " + string$ (.origRow)
            ... + ": alpha without this respondent = "
            ... + string$ (emlSurveyScoreScales.subAlphaWithout[.s, .r])
            ... + ", change = " + string$ (emlSurveyScoreScales.subDelta[.s, .r])
        endfor
        .line$ = .line$ + newline$ + emlSurveyReportLanguage.msgInflMostA$
        ... + string$ (emlSurveyScoreScales.subDeltaMaxRow[.s])
        ... + emlSurveyReportLanguage.msgInflMostB$
        ... + string$ (emlSurveyScoreScales.subDeltaMax[.s])
        ... + emlSurveyReportLanguage.msgInflMostC$
    endif
endproc


# ============================================================================
# @eml_survey_lineN: .s  ->  .line$
# ============================================================================
# "n, and the exclusions from listwise deletion, disclosed." Always
# printable: emlSurveyScoreScales.subN[]/.subNExcluded[] come straight from
# @eml_listwiseComplete inside @emlCronbachAlpha's own call, which runs and
# is disclosed BEFORE that kernel's own k>=2/n>=3 floor is even checked
# (eml-psychometrics.praat: "@eml_listwiseComplete: .data## ... .n =
# eml_listwiseComplete.nKept" precedes the "if .k < 2 ... elsif .n < 3"
# branch) -- so this line is independent of whether Alpha, above, refused.
# ----------------------------------------------------------------------------
procedure eml_survey_lineN: .s
    @emlSurveyReportLanguage
    .line$ = emlSurveyReportLanguage.msgNA$
    ... + string$ (emlSurveyScoreScales.subN[.s])
    ... + emlSurveyReportLanguage.msgNB$
    ... + string$ (emlSurveyScoreScales.subNExcluded[.s])
    ... + emlSurveyReportLanguage.msgNC$
endproc


# ============================================================================
# @eml_survey_lineReversed: .s  ->  .line$
# ============================================================================
# "The reversed items LISTED BY NAME. This prints always, whether or not
# any item is reversed." No `if` around the call site is needed to make
# that true -- both branches below return a non-empty .line$.
# ----------------------------------------------------------------------------
procedure eml_survey_lineReversed: .s
    @emlSurveyReportLanguage
    .listText$ = ""
    .n = 0
    for .j from 1 to emlSurveyScoreScales.subK[.s]
        .origIdx = emlSurveyScoreScales.subItemOrigIdx[.s, .j]
        if emlSurveyValidateDeclaration.itemReversed[.origIdx] = 1
            .n = .n + 1
            if .n > 1
                .listText$ = .listText$ + ", "
            endif
            .listText$ = .listText$
            ... + emlSurveyValidateDeclaration.itemName$[.origIdx]
        endif
    endfor
    if .n = 0
        .line$ = emlSurveyReportLanguage.msgReversedNone$
    else
        .line$ = emlSurveyReportLanguage.msgReversedSomeA$ + .listText$
        ... + emlSurveyReportLanguage.msgReversedSomeB$
    endif
endproc


# ============================================================================
# @eml_survey_lineType: .s  ->  .present, .line$
# ============================================================================
# "The ordinal-as-interval line, selected by the subscale's declared type.
# That type affects this line and nothing computational." Selected purely
# from emlSurveyValidateDeclaration.scaleType$[.s] -- the declared "ordinal"
# / "continuous" keyword refusal 9 already enforces is exactly one of those
# two strings by the time .refusal = 0, so the `else` branch below is
# reached only for "continuous", never a third, unvalidated value.
#
# Stage 3 ruling, item 2: FOLLOWS the annotate toggle (@emlSurveyLineRouting
# above classifies it so) -- an EXPLANATION of the declared type, not the
# type itself (which is not gated: refusal 9 already enforces it exists
# and is legal regardless of this toggle). .present = 0 means print
# nothing for this subscale, the same conditional shape
# @eml_survey_lineKR20 already uses, for the same reason: unlike every
# ALWAYS line in this file, this one may be entirely absent.
# ----------------------------------------------------------------------------
procedure eml_survey_lineType: .s
    @emlSurveyReportLanguage
    @eml_survey_annotateOn
    .present = eml_survey_annotateOn.on
    .line$ = ""
    if .present = 1
        if emlSurveyValidateDeclaration.scaleType$[.s] = "ordinal"
            .line$ = emlSurveyReportLanguage.msgTypeOrdinal$
        else
            .line$ = emlSurveyReportLanguage.msgTypeContinuous$
        endif
    endif
endproc


# ============================================================================
# @eml_survey_lineKR20: .s  ->  .present, .line$
# ============================================================================
# "The KR-20 line when the subscale's declared range spans exactly two
# values and every item's data is within it." Both halves of that condition
# are already emlSurveyScoreScales.subIsKR20[.s] (a plain copy of
# emlSurveyValidateDeclaration.scaleIsKR20[.s], V1.8's own documented
# contract) BY THE TIME this line can run at all: "every item's data is
# within [the declared range]" is refusal 2's own job, checked for every
# subscale before .refusal can read 0, and @emlSurveyBuildSubscaleReport's
# own caller (the door, or validate/v132) never calls this on a declaration
# that has not already cleared .refusal = 0. So the SPAN half is the only
# question this line still has to ask, and it asks it by reading
# .subIsKR20[.s] rather than re-deriving max = min + 1 a second time here.
# .present = 0 means: print nothing for this subscale (unlike every other
# line in this file, this one is conditional).
# ----------------------------------------------------------------------------
procedure eml_survey_lineKR20: .s
    @emlSurveyReportLanguage
    .present = 0
    .line$ = ""
    if emlSurveyScoreScales.subIsKR20[.s] = 1
        .present = 1
        .line$ = emlSurveyReportLanguage.msgKR20$
    endif
endproc


# ============================================================================
# @eml_survey_lineItemRest: .s  ->  .line$
# ============================================================================
# "Item-rest correlation per item, and an evidence flag -- never an action
# -- on any item whose item-rest correlation is strictly below zero."
# emlSurveyScoreScales.subItemFlag[.s, .j] IS that flag (1 exactly when
# .subItemRest[.s, .j] < 0, V1.8's own documented contract) -- this line
# reads it rather than re-testing "< 0" a second time here, so the flag and
# the number it flags can never independently drift.
#
# Stage 3 ruling, item 2: split by @emlSurveyLineRouting's own
# classification. The HEADER and every item's "name: r = value" are
# ALWAYS -- the numbers themselves, never gated -- except the header text
# itself carries a parenthetical GLOSS of what "item-rest" means
# (.msgItemRestHeader$'s "(each item against the sum of the OTHER items in
# this subscale)"), which is an EXPLANATION and FOLLOWS the toggle: off,
# the bare .msgItemRestHeaderBare$ is used instead, same section, same
# values, no gloss. The evidence-flag SUGGESTION (.msgItemRestFlagA$) is
# likewise FOLLOWS-only: the flag's underlying FACT is the signed r value
# itself, printed either way, so a reader loses no fact with the toggle
# off, only the added interpretation.
# ----------------------------------------------------------------------------
procedure eml_survey_lineItemRest: .s
    @emlSurveyReportLanguage
    @eml_survey_annotateOn
    if eml_survey_annotateOn.on = 1
        .line$ = emlSurveyReportLanguage.msgItemRestHeader$
    else
        .line$ = emlSurveyReportLanguage.msgItemRestHeaderBare$
    endif
    for .j from 1 to emlSurveyScoreScales.subK[.s]
        .origIdx = emlSurveyScoreScales.subItemOrigIdx[.s, .j]
        .itemName$ = emlSurveyValidateDeclaration.itemName$[.origIdx]
        .line$ = .line$ + newline$ + "  " + .itemName$ + ": r = "
        if emlSurveyScoreScales.subItemRest[.s, .j] = undefined
            .line$ = .line$ + "n/a" + newline$
            ... + emlSurveyReportLanguage.msgItemRestNA$
        else
            .line$ = .line$ + string$ (emlSurveyScoreScales.subItemRest[.s, .j])
            if emlSurveyScoreScales.subItemFlag[.s, .j] = 1 and eml_survey_annotateOn.on = 1
                .line$ = .line$ + newline$
                ... + emlSurveyReportLanguage.msgItemRestFlagA$
            endif
        endif
    endfor
endproc


# ============================================================================
# @eml_survey_lineDisclosure: .s  ->  .present, .line$
# ============================================================================
# "The placeholder disclosure from the cell ruling, when any placeholder
# was found." Scoped to THIS subscale via @emlSurveySubscaleDisclosure
# (V1.9, eml-psychometrics.praat), never a restatement of the kind-3
# spelling list or a second scan of the whole data table. .present = 0
# (nothing printed) exactly when this subscale's own items carried none --
# the run-wide count can still be > 0 from a DIFFERENT subscale's items,
# which is exactly why the per-subscale scoping exists.
# ----------------------------------------------------------------------------
procedure eml_survey_lineDisclosure: .dataTableId, .s
    @emlSurveyReportLanguage
    @emlSurveySubscaleDisclosure: .dataTableId, .s
    .present = 0
    .line$ = ""
    if emlSurveySubscaleDisclosure.count > 0
        .present = 1
        .itemList$ = ""
        for .q from 1 to emlSurveySubscaleDisclosure.count
            if .q > 1
                .itemList$ = .itemList$ + ", "
            endif
            .itemList$ = .itemList$ + emlSurveySubscaleDisclosure.item$[.q]
        endfor
        .spellList$ = ""
        for .q from 1 to emlSurveySubscaleDisclosure.spellingCount
            if .q > 1
                .spellList$ = .spellList$ + ", "
            endif
            .spellList$ = .spellList$ + """"
            ... + emlSurveySubscaleDisclosure.spelling$[.q] + """"
        endfor
        .line$ = emlSurveyReportLanguage.msgDisclA$
        ... + string$ (emlSurveySubscaleDisclosure.cellCount)
        ... + emlSurveyReportLanguage.msgDisclB$ + .itemList$
        ... + emlSurveyReportLanguage.msgDisclC$ + .spellList$
        ... + emlSurveyReportLanguage.msgDisclD$
    endif
endproc


# ============================================================================
# @eml_survey_lineScore: .s  ->  .line$
# ============================================================================
# "The scale-score disclosure: mean-based, complete-case, with the count of
# respondents who received no score." Always printable, the same way
# @eml_survey_lineN is: emlSurveyScoreScales.subScoredN[]/.subScoredNone[]
# are set unconditionally at the end of the per-subscale loop
# (eml-psychometrics.praat), gated only on nKept >= 1 for the summary
# statistics themselves, a floor well below @emlCronbachAlpha's own n >= 3
# -- so this line can, and must, still print a real scoredNone count even
# for a subscale whose alpha refused.
# ----------------------------------------------------------------------------
procedure eml_survey_lineScore: .s
    @emlSurveyReportLanguage
    .line$ = emlSurveyReportLanguage.msgScoreA$
    ... + string$ (emlSurveyScoreScales.subScoreMean[.s])
    ... + emlSurveyReportLanguage.msgScoreB$
    ... + string$ (emlSurveyScoreScales.subScoreSD[.s])
    ... + emlSurveyReportLanguage.msgScoreC$
    ... + string$ (emlSurveyScoreScales.subScoreMin[.s])
    ... + emlSurveyReportLanguage.msgScoreD$
    ... + string$ (emlSurveyScoreScales.subScoreMax[.s])
    ... + emlSurveyReportLanguage.msgScoreE$
    ... + string$ (emlSurveyScoreScales.subScoredN[.s])
    ... + emlSurveyReportLanguage.msgScoreF$
    ... + string$ (emlSurveyScoreScales.subScoredNone[.s])
    ... + emlSurveyReportLanguage.msgScoreG$
endproc


# ============================================================================
# @emlSurveyBuildSubscaleReport: .dataTableId, .s  ->  .text$
# ============================================================================
# Assembles every promised block for ONE subscale, in the plan's own order,
# into one multi-line ASCII string. Pure: builds and returns text, prints
# nothing itself -- @emlSurveyReportSubscale (below) is the one call site
# that prints. This split is what lets validate/v132 call this procedure
# directly and inspect .text$ (or the tag lines a caller adds around it)
# without capturing an Info window at all, and what lets
# @emlSurveyReportSubscale be the ONLY place a future change to the Info
# window's presentation (colors, indentation, a different border style)
# would need to touch.
#
# STRUCTURAL LABELS (not DRAFT language -- see the block comment above
# @emlSurveyReportLanguage) mark each block so a reader, and a check, can
# find it without depending on the sentence that follows. Every line-
# builder above this procedure is called EXACTLY ONCE per subscale, in
# this one place, with no `goto` and no early return: a subscale whose
# alpha or influence kernel refused still reaches every line below it in
# this list, which is the structural half of "a refusing subscale does not
# suppress the others" -- the OTHER half is emlSurveyScoreScales's own
# per-subscale loop (eml-psychometrics.praat), which runs this same
# sequence again, unconditionally, for every subscale in turn.
# ----------------------------------------------------------------------------
procedure emlSurveyBuildSubscaleReport: .dataTableId, .s
    .name$ = emlSurveyValidateDeclaration.scaleName$[.s]
    .k = emlSurveyScoreScales.subK[.s]

    .text$ = "--- Subscale: " + .name$ + " (" + string$ (.k) + " item(s)) ---"

    @eml_survey_lineAlpha: .s
    .text$ = .text$ + newline$ + "Alpha: " + eml_survey_lineAlpha.line$

    @eml_survey_lineItemDeleted: .s
    .text$ = .text$ + newline$ + eml_survey_lineItemDeleted.line$

    @eml_survey_lineInfluence: .s
    .text$ = .text$ + newline$ + eml_survey_lineInfluence.line$

    @eml_survey_lineN: .s
    .text$ = .text$ + newline$ + "n / exclusions: " + eml_survey_lineN.line$

    @eml_survey_lineReversed: .s
    .text$ = .text$ + newline$ + "Reversed items: " + eml_survey_lineReversed.line$

    @eml_survey_lineType: .s
    if eml_survey_lineType.present = 1
        .text$ = .text$ + newline$ + "Scale type note: " + eml_survey_lineType.line$
    endif

    @eml_survey_lineKR20: .s
    if eml_survey_lineKR20.present = 1
        .text$ = .text$ + newline$ + "KR-20 note: " + eml_survey_lineKR20.line$
    endif

    @eml_survey_lineItemRest: .s
    .text$ = .text$ + newline$ + eml_survey_lineItemRest.line$

    @eml_survey_lineDisclosure: .dataTableId, .s
    if eml_survey_lineDisclosure.present = 1
        .text$ = .text$ + newline$ + "Placeholder disclosure: "
        ... + eml_survey_lineDisclosure.line$
    endif

    @eml_survey_lineScore: .s
    .text$ = .text$ + newline$ + "Scale score: " + eml_survey_lineScore.line$
endproc


# ============================================================================
# @emlSurveyReportSubscale: .dataTableId, .s
# ============================================================================
# Prints ONE subscale's block (@emlSurveyBuildSubscaleReport, above) to the
# Info window. The only procedure in this file that calls appendInfoLine
# for the per-subscale report -- everything above it returns text instead
# of printing, per the separability note at the top of this file.
# ----------------------------------------------------------------------------
procedure emlSurveyReportSubscale: .dataTableId, .s
    @emlSurveyBuildSubscaleReport: .dataTableId, .s
    appendInfoLine: emlSurveyBuildSubscaleReport.text$
    appendInfoLine: ""
endproc


# ============================================================================
# @emlSurveyExportCSV: .dataTableId, .dataPath$, .itemsPath$, .scalesPath$,
#                      .csvPath$
# ============================================================================
# THE CSV EXPORT, THROUGH THE EXISTING LONG-FORMAT WRITER
# (stats/eml-output.praat: @emlCSVInit / @emlCSVSetTable / @emlCSVTermType /
# @emlCSVAdd / @emlCSVAddStr / @emlExportStatsCSV) -- not a new writer. That
# writer's `field` column is free text (no vocabulary check the way the
# broom-shaped tidy/glance/augment writer in eml-result-writer.praat has),
# which is exactly what lets this export add "item_rest" / "item_total"
# without touching eml-output.praat at all.
#
# "It carries item-rest AND uncorrected item-total as raw values" -- both
# are written per item, unconditionally on being defined
# (emlCSVAdd's own "undefined writes nothing" contract), whereas the PRINTED
# report above prints item-rest only. Scale-level context (alpha, its
# interval, n, the scale score summary, is_kr20) and each item's declared
# reversed flag are written alongside, since a raw-value export with no
# context to join it against is not useful on its own -- but item-rest and
# item-total are the two fields the task specifically asks this export to
# carry, and both are written for every item this loop reaches, with no
# `if` around either @emlCSVAdd call beyond the writer's own
# undefined-writes-nothing rule.
#
# PROVENANCE: three rows name the three files this run was driven from, by
# path -- "items_file" / "scales_file" / "data_file" -- so an export opened
# on its own states its own inputs, the other half of the provenance rule
# described at the top of this file (the door reading paths itself is the
# other half, for a RECORDED run).
#
# PRECONDITION: same as every reporting procedure above --
# @emlSurveyValidateDeclaration and @emlSurveyScoreScales have already run
# on .dataTableId.
#
# THE SCALE-LEVEL TERM IS THE IDENTIFIER, NOT THE DISPLAY NAME (Stage 3
# ruling, item 4). A subscale's declared name ("Vocal Health") is a
# DISPLAY name and may hold a space; refusal 17's own message
# (eml-psychometrics.praat) already says so. Where that name has to
# become an identifier rather than a label a reader sees, every space in
# it becomes an underscore ("Vocal_Health"). In this build those
# identifiers are this CSV's `term` VALUES and the file stems the graphs
# form writes; the CSV's header row is a fixed literal and never varies
# by subscale. This CSV's `term` column is
# exactly that kind of identifier -- a downstream reader joins rows on it
# -- so every scale-level row below runs the raw
# emlSurveyValidateDeclaration.scaleName$[.s] through
# @eml_underscoreNormalize (eml-psychometrics.praat) once, into
# .scaleTerm$, and writes THAT as the term. The item-level rows below
# keep using the raw item name as their term: no ruling asked item names
# to be normalized, and unlike a subscale name, nothing in this lane
# builds an item name with a space in it to begin with.
# ----------------------------------------------------------------------------
procedure emlSurveyExportCSV: .dataTableId, .dataPath$, .itemsPath$, .scalesPath$, .csvPath$
    @emlCSVInit
    selectObject: .dataTableId
    .tableName$ = selected$ ("Table")
    @emlCSVSetTable: .tableName$

    .analysis$ = "Survey subscale reliability"

    @emlCSVTermType: "omnibus"
    @emlCSVAdd: .analysis$, "", "confidence_level", emlSurveyScoreScales.confidence
    @emlCSVAddStr: .analysis$, "", "items_file", .itemsPath$
    @emlCSVAddStr: .analysis$, "", "scales_file", .scalesPath$
    @emlCSVAddStr: .analysis$, "", "data_file", .dataPath$

    for .s from 1 to emlSurveyScoreScales.nScales
        .scaleName$ = emlSurveyValidateDeclaration.scaleName$[.s]
        @eml_underscoreNormalize: .scaleName$
        .scaleTerm$ = eml_underscoreNormalize.result$

        @emlCSVTermType: "scale"
        @emlCSVAdd: .analysis$, .scaleTerm$, "alpha", emlSurveyScoreScales.subAlpha[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "ci_low", emlSurveyScoreScales.subCiLow[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "ci_high", emlSurveyScoreScales.subCiHigh[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "n", emlSurveyScoreScales.subN[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "n_excluded", emlSurveyScoreScales.subNExcluded[.s]
        @emlCSVAddStr: .analysis$, .scaleTerm$, "alpha_error", emlSurveyScoreScales.subAlphaError$[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "is_kr20", emlSurveyScoreScales.subIsKR20[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "scored_n", emlSurveyScoreScales.subScoredN[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "scored_none", emlSurveyScoreScales.subScoredNone[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "score_mean", emlSurveyScoreScales.subScoreMean[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "score_sd", emlSurveyScoreScales.subScoreSD[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "score_min", emlSurveyScoreScales.subScoreMin[.s]
        @emlCSVAdd: .analysis$, .scaleTerm$, "score_max", emlSurveyScoreScales.subScoreMax[.s]

        @emlCSVTermType: "item"
        for .j from 1 to emlSurveyScoreScales.subK[.s]
            .origIdx = emlSurveyScoreScales.subItemOrigIdx[.s, .j]
            .itemName$ = emlSurveyValidateDeclaration.itemName$[.origIdx]
            @emlCSVAdd: .analysis$, .itemName$, "item_rest", emlSurveyScoreScales.subItemRest[.s, .j]
            @emlCSVAdd: .analysis$, .itemName$, "item_total", emlSurveyScoreScales.subItemTotal[.s, .j]
            @emlCSVAdd: .analysis$, .itemName$, "alpha_if_deleted", emlSurveyScoreScales.subAlphaIfDeleted[.s, .j]
            @emlCSVAdd: .analysis$, .itemName$, "reversed", emlSurveyValidateDeclaration.itemReversed[.origIdx]
        endfor
    endfor

    @emlExportStatsCSV: .csvPath$
    .success = emlExportStatsCSV.success
    .actualPath$ = emlExportStatsCSV.actualPath$
    .reason$ = emlExportStatsCSV.reason$
endproc


# ============================================================================
# @emlSurveyRunReport: .dataPath$, .itemsPath$, .scalesPath$, .csvExportPath$
# ============================================================================
# THE DOOR BODY. See the block comment at the top of this file for why this
# is the ONLY procedure here that reads a file or drives the validator, and
# why nothing else in this file may grow a second one.
#
# .csvExportPath$ = "" skips the CSV export entirely (report only); any
# other string is passed straight to @emlSurveyExportCSV.
#
# THE EXPORT'S VERDICT IS CONSUMED HERE, NOT DISCARDED. @emlSurveyExportCSV
# faithfully carries .success / .reason$ / .actualPath$ out of
# @emlExportStatsCSV (eml-output.praat), and a caller that reads none of
# them tells the user nothing when the two paths differ or the write fails
# -- standing instruction 3 ("consume a classifier's whole verdict"), which
# applies here just as much as to a refusal kind. @emlExportStatsCSV's
# writer is non-destructive (@emlReportToFile's uniquing walk): a second
# export to the same requested path is never overwritten and never lost,
# but silently landing at "..._1.csv" instead of the requested name, with
# nothing printed, is indistinguishable from data loss to a user who asked
# for one file and did not get it under that name. So this door prints,
# unconditionally whenever an export was attempted (.csvExportPath$ <> ""):
# the actual path written, named explicitly whenever it differs from what
# was requested (msgCsvRenamed*), and the reason when nothing was written
# at all (msgCsvFailEmpty$ / msgCsvFailWrite*, keyed off
# @emlExportStatsCSV's own "empty" / "write" .reason$ values -- see its
# header for what each means). This procedure also returns the verdict as
# its own outputs (.csvAttempted, .csvSuccess, .csvActualPath$,
# .csvReason$) so a future caller other than the Info window -- a test, a
# batch driver -- can act on it without re-parsing printed text.
#
# Leaves the three Table objects it read selected/available in the object
# list on return, exactly like every other menu door in this plugin that
# leaves its result Table for the user to inspect afterward -- this
# procedure does not remove them.
#
# Output (in addition to the printed report):
#   .refusal          - emlSurveyValidateDeclaration.refusal, unchanged
#   .csvAttempted     - 1 if .csvExportPath$ <> "" and the declaration was
#                        not refused (an export is only ever attempted when
#                        there is a report to attach it to), 0 otherwise
#   .csvSuccess       - @emlExportStatsCSV's .success; 0 when .csvAttempted
#                        is 0 too, so a caller need not check both
#   .csvActualPath$   - @emlExportStatsCSV's .actualPath$; "" when
#                        .csvAttempted is 0
#   .csvReason$       - @emlExportStatsCSV's .reason$; "" when .csvAttempted
#                        is 0 or .csvSuccess is 1
# ----------------------------------------------------------------------------
procedure emlSurveyRunReport: .dataPath$, .itemsPath$, .scalesPath$, .csvExportPath$
    @emlSurveyReportLanguage

    .csvAttempted = 0
    .csvSuccess = 0
    .csvActualPath$ = ""
    .csvReason$ = ""

    .dataTableId = Read Table from comma-separated file: .dataPath$
    .scalesTableId = Read Table from comma-separated file: .scalesPath$
    .itemsTableId = Read Table from comma-separated file: .itemsPath$

    @emlSurveyValidateDeclaration: .dataTableId, .scalesTableId, .itemsTableId
    .refusal = emlSurveyValidateDeclaration.refusal

    if .refusal <> 0
        appendInfoLine: emlSurveyReportLanguage.msgDeclRefused$
        appendInfoLine: emlSurveyValidateDeclaration.error$
        if emlSurveyValidateDeclaration.remedy$ <> ""
            appendInfoLine: emlSurveyValidateDeclaration.remedy$
        endif
    else
        @emlSurveyScoreScales: .dataTableId

        appendInfoLine: "==================================================="
        appendInfoLine: "EML Survey Report"
        appendInfoLine: "==================================================="
        for .s from 1 to emlSurveyScoreScales.nScales
            @emlSurveyReportSubscale: .dataTableId, .s
        endfor

        if .csvExportPath$ <> ""
            .csvAttempted = 1
            @emlSurveyExportCSV: .dataTableId, .dataPath$, .itemsPath$,
            ... .scalesPath$, .csvExportPath$
            .csvSuccess = emlSurveyExportCSV.success
            .csvActualPath$ = emlSurveyExportCSV.actualPath$
            .csvReason$ = emlSurveyExportCSV.reason$

            if .csvSuccess = 1
                if .csvActualPath$ = .csvExportPath$
                    appendInfoLine: emlSurveyReportLanguage.msgCsvOkA$
                    ... + .csvActualPath$ + emlSurveyReportLanguage.msgCsvOkB$
                else
                    appendInfoLine: emlSurveyReportLanguage.msgCsvRenamedA$
                    ... + .csvExportPath$
                    ... + emlSurveyReportLanguage.msgCsvRenamedB$
                    ... + .csvActualPath$
                    ... + emlSurveyReportLanguage.msgCsvRenamedC$
                endif
            elsif .csvReason$ = "empty"
                appendInfoLine: emlSurveyReportLanguage.msgCsvFailEmpty$
            else
                appendInfoLine: emlSurveyReportLanguage.msgCsvFailWriteA$
                ... + .csvExportPath$
                ... + emlSurveyReportLanguage.msgCsvFailWriteB$
            endif
        endif
    endif
endproc

# ============================================================================
# END OF MODULE
# ============================================================================
