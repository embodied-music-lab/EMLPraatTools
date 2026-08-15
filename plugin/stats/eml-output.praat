# ============================================================================
# EML Stats : Output Formatting
# ============================================================================
# Module: eml-output.praat
# Version: 2.4
# v2.4: THE TWO GUARDS THAT KEEP A SAVE FROM KILLING THE SESSION, plus the
#       receipt that could not draw what it was given, plus a probe that
#       assumed instead of classifying. Four defects, all confirmed live at
#       HEAD before a line was changed (audit of 14 Aug 2026, §3 S4 and §6).
#
#       NEW-G2-1, sev 2 -- a "/" in the Base name field reached writeFile:
#         verbatim. Praat stopped the script inside @emlSavePanel, so the
#         receipt never drew, the panel never returned, and the caller's
#         Done | Save | Draw | New loop was gone with the analysis behind it.
#         @eml_saveSafeBaseName now makes the typed name into a file name
#         ONCE, before the collision walk, so every file of one press still
#         shares one base name and one stamp.
#       NEW-G12-5, sev 2 -- an unwritable target folder did the same thing
#         one step later, with "unexpected error 30" for a message, and an
#         unwritable PARENT did it one step earlier on the panel's own bare
#         `createFolder:`. @eml_saveFolderWritable asks both questions once,
#         with `nocheck` so the asking cannot itself abort, and the panel now
#         RETURNS on a no instead of dying on one.
#       SAVED-OVERPRINT, sev 4, five sightings -- the "Saved" receipt reserved
#         one line per comment: and the toolkit drew several when a path was
#         longer than the dialog, so each long path printed its tail over the
#         path below. Every line now goes through @emlWrapText at 62
#         characters, the width measured on 6.6.30 and the one
#         @emlErrorDialog already uses.
#       NEW-G12-1, sev 2 (this file's half) -- author ruling, 15 Aug 2026:
#         "probe should classify column types, never assume numeric."
#         @emlWrapperInit's coercion arms manufacture a "row" column out of
#         row labels that a Matrix never has and a TableOfReal may not have.
#         Praat renders those undefined cells as "?", which is neither of the
#         two forms @eml_strictNumericColumn's scan recognises, so the
#         numericiser behind it raised before the wrapper's dialog opened --
#         on EVERY Matrix, every unlabelled TableOfReal and every partially
#         labelled one. @eml_auditLabelColumn classifies the column and makes
#         it readable; it does not invent default labels, so it composes with
#         whatever the conversion side decides to put there.
# v2.3: @emlWrapperExportCSV DELETED (author ruling, 14 Aug 2026: "We can
#       retire the superseded csv wrapper code if we use it nowhere now").
#       It had no callers in any tree. A tombstone stands where it was,
#       because its folder-seed line is the reason every non-graphing Save
#       button broke on 13 Aug; the seed now sits at file scope above
#       @emlSavePanel.
# v2.2: @emlSavePanel -- one save, one folder, one name. The figure, the
#       result frames and the Info window report are written together under a
#       shared stem. Before this the figure and the CSV were two journeys with
#       two folder memories and two naming rules, and the report could not be
#       saved at all. @emlWrapperExportCSV is superseded and now has no
#       callers.
# v2.1: Both arms of @emlExportResultFiles are now non-destructive. The
#       declared arm could not be until @emlGenerateUniquePath moved to
#       eml-core-utilities.praat -- it lived in the graphs form, which is
#       included after this file. The BASE is uniqued once against the tidy
#       frame and every frame in the set carries the walked suffix, so a set
#       never half-overwrites an older set.
# v2.0: THE MIGRATION FORK IS NOW A PROCEDURE, @emlExportResultFiles, and the
#       graphs form's Exp CSV button goes through it. The fork lived inline in
#       @emlWrapperExportCSV, so the plugin's OTHER export -- the post-draw
#       "Exp CSV" button in eml-graphs-form.praat -- could not reach it and
#       called @emlExportStatsCSV directly. The same analysis therefore wrote
#       three broom-shaped files from the stats menu and one legacy long-format
#       file from the graphs form. v20/v21 enumerate the stats-menu
#       orchestrators, so neither could see a second exporter, and no harness
#       had pressed that button until 13 Aug 2026. Writing only -- the two
#       callers report differently and a shared procedure cannot open a dialog
#       from inside another one.
# v1.9: COMMENTS ONLY — no executable line changed. Five statements that the
#       code under them contradicts, corrected.
#       (1) The Provides list named @emlCSVAddRow. No procedure of that name
#         has ever existed anywhere in the plugin. The list is now the real
#         CSV primitives (@emlCSVInit / @emlCSVSetTable / @emlCSVTermType /
#         @emlCSVAdd / @emlCSVAddStr / @emlCSVAddDescriptives /
#         @emlExportStatsCSV), the rest of the public surface by family, and
#         a counting rule so the whole thing can be checked rather than
#         believed.
#       (2) @emlWrapText's header cited "@comment:", which reads as a
#         procedure call in this file's notation and is not one — `comment:`
#         is a Praat dialog command. It also described @emlErrorDialog as the
#         only consumer; @emlReportNote and, since D124,
#         @emlDrawAnnotationBlock also wrap through it.
#       (3) The D27 provenance note said the CSV self-documents the
#         adjustment "in its `test` column". The long-format schema
#         (emlCSV_header$) has no `test` column; the adjustment is a row
#         whose `field` is "adjustment".
#       (4) An "END OF MODULE" banner sat above @emlReportDescriptiveAnalysis
#         rather than at the end of the module.
#       (5) That procedure's note cited a bare "line 9434" for a
#         "Procedure not found" error. Praat counts that line in the
#         FLATTENED script, after include expansion, so it names no line of
#         any file on disk. Replaced with the anchor and the reason.
# v1.8: Audit fixes (items 8, 9).
#       Item 8 — @emlFormatEffectLabel labelled R-squared values with
#         Cohen's d thresholds. It now recognises "r_squared" (and the
#         aliases "R2" and "r2") and applies Cohen's R-squared benchmarks
#         0.01 / 0.09 / 0.25. The token string "r_squared" is unchanged and
#         still accepted. An unrecognised effect type no longer silently
#         falls back to d thresholds: .label$ is now "" and the new
#         .recognized flag is 0, so callers can detect the condition.
#       Item 9 — @emlFormatP reported "p = 1.000" for any p in
#         [0.9995, 1), overstating the result as an exact 1. Such values now
#         format as "p > .999". p = 1 exactly still formats as "p = 1.000".
# v1.7: @emlWrapperInit accepts Table, TableOfReal, and Matrix objects.
#       Auto-converts TableOfReal/Matrix to Table with Info window notification.
#       Outputs .converted flag for caller awareness.
# Date: 11 May 2026
# v1.6: Renamed emlWizardMode → emlShowExplanations (clearer semantics).
#        Double-tab spacing between value and explanation columns.
# v1.5: Wrapper infrastructure. @emlWrapperInit (Table check + column
#        loading + guess), @emlWrapperExportCSV (shared CSV export dialog).
#        6 wrappers refactored to use shared procedures + repeat/until.
# v1.4: Wizard mode third-column explanations. Global emlShowExplanations flag
#        controls whether @emlReportLine/@emlReportLineString append a
#        tab-separated explanation column. 15 helper procedures for
#        value-anchored interpretations (effect sizes, p-values,
#        correlation strength, df, skewness, kurtosis, etc.).
# v1.3: Info window is now append-only. Removed emlReportFirstRun sentinel.
#        @emlReportHeader never clears — always appends. New @emlClearInfo
#        procedure for explicit clearing via dialog toggle. Timestamp kept.
# v1.2: Accumulating Info window output — sentinel (removed in v1.3).
#        Timestamp added to every report.
#
# Part of the EML Stats library (EML Praat Tools).
# License: GPL-3.0-or-later
#
# Provides: 60 procedures. THE COUNTING RULE, so the number can be checked
# rather than believed:
#     grep -c "^procedure " plugin/stats/eml-output.praat
# Six of the 60 are private and are named with an underscore after the prefix
# (@eml_csvQuote, @eml_csvAppend, @eml_auditLabelColumn,
# @eml_saveSafeBaseName, @eml_saveFolderWritable, @eml_saveReceiptLines);
# the other 54 are public.
#
# THE NUMBER READ 55 AGAINST A FILE OF 56 until 15 August 2026, and the
# counting rule above is what settled it: @emlExportResultFiles had been
# written in v2.0 and never added to the family list below, so the headline
# and the families agreed with each other and neither agreed with the file.
# It is in the CSV export family now. By family:
#
#   Report frame — @emlReportHeader, @emlReportFooter, @emlReportSection,
#     @emlReportLine, @emlReportLineString, @emlReportBlank,
#     @emlReportPWithExact, @emlReportContext, @emlReportNote,
#     @emlReportDescriptiveHeader, @emlReportDescriptiveRow,
#     @emlReportDescriptiveAnalysis, @emlReportAPA, @emlReportToFile,
#     @emlSaveInfoToFile, @emlClearInfo
#   Formatting — @emlFormatP, @emlFormatCI, @emlFormatTestResult,
#     @emlFormatEffectLabel, @emlPadRight, @emlUnderscoreToSpace,
#     @emlWrapText
#   CSV export — @emlCSVInit, @emlCSVSetTable, @emlCSVTermType, @emlCSVAdd,
#     @emlCSVAddStr, @emlCSVAddDescriptives, @emlExportStatsCSV,
#     @emlExportResultFiles
#     (this list read "@emlCSVAddRow" until 8 Aug 2026. No such procedure has
#     ever existed anywhere in the plugin —
#     grep -rn "^procedure emlCSVAddRow" plugin/ returns nothing — although
#     the notes under audit/ name it fourteen times, having taken it from
#     here. The export is LONG format: emlCSV_header$ is
#     "table,analysis,term,term_type,field,value", and @emlCSVAdd /
#     @emlCSVAddStr each append ONE such row, i.e. one field of one term.
#     There is no procedure that writes a whole analysis in one call, which
#     is what the name @emlCSVAddRow implied.)
#   Wrapper plumbing — @emlWrapperInit, @emlWrapperCommonFields,
#     @emlHandleCommonFields, @eml_auditLabelColumn (private)
#   Saving — @emlSavePanel (the one save journey; @emlWrapperExportCSV was in
#     this list until it was deleted on 14 Aug 2026 — see its tombstone),
#     with its two entry guards @eml_saveSafeBaseName and
#     @eml_saveFolderWritable and its receipt builder @eml_saveReceiptLines
#     (all three private; the panel owns the naming contract, so the panel
#     owns the characters, the target check and the receipt's line breaks)
#   Wizard glosses — @emlResetExplanations plus the 17 @emlWizardExplain*
#     helpers (grep -c "^procedure emlWizardExplain")
#   Errors — @emlErrorDialog
#
# All procedures use the "eml" prefix (EML Stats).
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
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
# WIZARD MODE — Third-column explanations
# ============================================================================
# When emlShowExplanations = 1, report procedures append value-anchored
# interpretations as a third column (tab-separated).
# emlWizardExplain$ is set before each @emlReportLine/@emlReportLineString
# call and consumed (cleared) by the procedure.
#
# D42/D102. The default was 0 and no wrapper ever raised it, so glosses were
# absent from every wrapper report while the graph path (which sets the gate
# to 1) had them — the same analysis narrated two different ways depending on
# whether a figure had been drawn earlier in the session. The default is now
# 1: a wrapper report explains itself without the user having to know that a
# gate exists.
#
# THE DEFAULT IS DECLARED ONCE, HERE. @emlResetExplanations restores this
# variable rather than a literal, so the initial value and the restored value
# cannot drift apart — which is exactly how D102 survived: the reset put the
# gate back to a number that was written out a second time by hand.
# ============================================================================
emlShowExplanationsDefault = 1
emlShowExplanations = emlShowExplanationsDefault

# ----------------------------------------------------------------------------
# @emlResetExplanations
# ----------------------------------------------------------------------------
# Put the explanation gate back to its default (emlShowExplanationsDefault).
#
# D102. @emlGraphsWorkflow sets emlShowExplanations = 1 and never resets it, so
# after any Draw every later analysis report in the same session silently
# becomes verbose. Report content was therefore ORDER-DEPENDENT: the same
# analysis produced different text depending on whether a figure had been drawn
# earlier. That also made D42 and D44 intermittent and hard to reproduce.
#
# Any code that raises the gate for its own scope must lower it again through
# this procedure when that scope ends.
# ----------------------------------------------------------------------------
procedure emlResetExplanations
    if not variableExists ("emlShowExplanationsDefault")
        emlShowExplanationsDefault = 1
    endif
    emlShowExplanations = emlShowExplanationsDefault
endproc

# ----------------------------------------------------------------------------
# Distribution-shape thresholds
#
# @emlKurtosis and @emlSkewness both return the EXCESS / sample-corrected
# form: a normal distribution gives 0, not 3. These two constants are the
# flags applied to them, declared here so the shape verdict, the wizard's
# classifier and the sentence the classifier prints cannot drift apart —
# which they had. Before 5 August the gate used 3, the classifier used 1,
# and the printed sentence claimed 3 while the code beside it enforced 1.
#
# THE VALUES ARE 2 AND 7, from West, Finch & Curran (1995), who give
# |skewness| > 2 and |kurtosis| > 7 as indicative of moderate-to-serious
# non-normality. They are explicitly loose guidelines for describing a
# distribution, not a test of it, and that is the only role they have here:
# Shapiro-Wilk decides, and these flag severity. See the interpretation
# block in @emlRunNormalityAnalysis.
#
# They were 1 and 1 earlier on 5 August. That pair had no published source —
# it was carried in from the code it replaced. A threshold that changes what
# the plugin recommends has to be attributable.
#
# To change the house convention, change it here; every consumer reads these.
# Kline's stricter pair for SEM work is 3 and 10.
# ----------------------------------------------------------------------------
emlSkewThreshold = 2
emlKurtosisThreshold = 7
emlWizardExplain$ = ""


# ============================================================================
# UTILITY PROCEDURES
# ============================================================================

procedure emlPadRight: .text$, .targetLength
    # Pad string with trailing spaces to reach targetLength
    # If string is already >= targetLength, return unchanged
    .currentLength = length(.text$)
    if .currentLength >= .targetLength
        .result$ = .text$
    else
        .paddingNeeded = .targetLength - .currentLength
        .padding$ = ""
        .i = 1
        while .i <= .paddingNeeded
            .space$ = " "
            .padding$ = .padding$ + .space$
            .i = .i + 1
        endwhile
        .result$ = .text$ + .padding$
    endif
endproc


procedure emlUnderscoreToSpace: .text$
    # Convert all underscores to spaces
    .underscore$ = "_"
    .space$ = " "
    .result$ = replace$(.text$, .underscore$, .space$, 0)
endproc


# ============================================================================
# REPORT STRUCTURE PROCEDURES (write to Info window)
# ============================================================================

procedure emlClearInfo
    # Explicit Info window clear. Call from dialog handlers when user
    # checks "Clear Info window" toggle — never called automatically.
    writeInfoLine: ""
endproc


# ────────────────────────────────────────────────────────────────────────────
# REPORT PROVENANCE (D27)
#
# The Info window appends. That is deliberate (see @emlClearInfo, and the
# "Clear Info window" toggle, which now persists), but it means one session
# holds several report blocks at once, and until now the only thing telling
# two blocks apart was the timestamp. An audited session produced three
# Kruskal-Wallis blocks whose headers were byte-identical while two of them
# reported different post-hoc p-values, because the adjustment had been
# changed between them. Nothing in the header said so.
#
# Two facts fix that, and both belong in the header rather than buried in the
# body, because the header is what a user scrolling back sees:
#
#   emlReportAnalysis$  WHERE this block came from — the analysis dialog, a
#                       graph Draw, the wizard. Titles do not carry this: the
#                       Run and the Draw of one test print the same title.
#   emlReportAdjust$    the correction or adjustment in force for this block
#                       (holm, bonferroni, bh, Tukey HSD, ...). The CSV
#                       already self-documents this; the Info window did not.
#                       Not in a column of its own, though — this used to say
#                       "its `test` column", and the export has had no such
#                       column since the long-format rewrite. The schema is
#                       emlCSV_header$ further down this file,
#                       "table,analysis,term,term_type,field,value": the
#                       `analysis` cell names the test, and the adjustment
#                       arrives as an ordinary row whose `field` is
#                       "adjustment" (written by the Dunn's reporter in
#                       graphs/eml-annotation-procedures.praat).
#
# Both are optional. A caller sets them with @emlReportContext immediately
# before @emlReportHeader, and the header CONSUMES them — it prints them and
# clears them. That is the whole discipline, and it is what keeps a stale
# adjustment from a previous post-hoc test appearing on the header of a
# report that has no post-hoc at all. Never read these two directly; never
# leave them set.
#
# @emlHandleCommonFields sets the analysis-dialog origin on every Run, so the
# wrapper path is labelled without any wrapper having to opt in. A block with
# no origin line came from somewhere else — today, a graph Draw.
#
# Cost is one line, and only when there is something to say.
# ────────────────────────────────────────────────────────────────────────────
emlReportAnalysis$ = ""
emlReportAdjust$ = ""

# @emlReportContext: .analysis$, .adjustment$
# Declare provenance for the NEXT @emlReportHeader. Either argument may be ""
# to leave that half unstated. Consumed by the header.
procedure emlReportContext: .analysis$, .adjustment$
    emlReportAnalysis$ = .analysis$
    emlReportAdjust$ = .adjustment$
endproc


procedure emlReportHeader: .title$
    # Print report header with double-line borders, timestamp, and — when the
    # caller declared them via @emlReportContext — the originating analysis
    # and the correction in force (D27).
    # Always appends — never clears. Use @emlClearInfo for explicit clearing.
    .border$ = "══════════════════════════════════════════════"
    .indent$ = "  "
    .prefix$ = "EML Stats : "
    .titleLine$ = .indent$ + .prefix$ + .title$
    .timestamp$ = .indent$ + date$ ()

    ; Provenance line. Built only from what the caller actually supplied, so
    ; the header never asserts an origin or an adjustment it does not know.
    .context$ = ""
    .joiner$ = "  ·  "
    if variableExists ("emlReportAnalysis$")
        if emlReportAnalysis$ <> ""
            .context$ = .indent$ + "from: " + emlReportAnalysis$
        endif
    endif
    if variableExists ("emlReportAdjust$")
        if emlReportAdjust$ <> ""
            .adjustPart$ = "adjustment: " + emlReportAdjust$
            if .context$ = ""
                .context$ = .indent$ + .adjustPart$
            else
                .context$ = .context$ + .joiner$ + .adjustPart$
            endif
        endif
    endif

    .sep$ = ""
    appendInfoLine: .sep$
    appendInfoLine: .border$
    appendInfoLine: .titleLine$
    appendInfoLine: .timestamp$
    if .context$ <> ""
        appendInfoLine: .context$
    endif
    appendInfoLine: .border$
    .sep2$ = ""
    appendInfoLine: .sep2$

    ; Consumed. A context declared for this report must not leak onto the
    ; next one — that is how the stale-adjustment version of D27 would come
    ; back, in a subtler form.
    emlReportAnalysis$ = ""
    emlReportAdjust$ = ""
endproc


procedure emlReportFooter
    # Print the estimator conventions, then the closing double-line border.
    #
    # D5. Nothing in the report said which estimators produced the numbers,
    # and these are the exact quantities that differ visibly between packages
    # — a quartile is not one number, and a variance divided by n is not the
    # one divided by n-1. A user pasting Q1 or SD into a paper had no way to
    # say what they had computed. Two lines, on every report, make the output
    # citable.
    #
    # WHAT THESE CLAIM, AND WHERE IT IS ENFORCED. Change the line only when
    # the code below changes:
    #   quartiles   @emlPercentile (eml-core-descriptive.praat) interpolates
    #               with h = (n-1)p/100 + 1, which is R's type 7 / the
    #               default of R's quantile(). @emlQuartiles is a thin caller.
    #   SD/variance @emlVariance and @emlSD use the n-1 denominator (sample,
    #               not population).
    #   rank ties   @emlRankVector assigns the average of the tied positions
    #               and reports the tie-correction sum; the Mann-Whitney and
    #               Kruskal-Wallis paths apply that correction to the normal
    #               approximation, and fall back to it from the exact null
    #               distribution whenever ties are present (as R does).
    .empty$ = ""
    .border$ = "══════════════════════════════════════════════"
    .conv1$ = "  Conventions: quartiles R type 7 · SD & variance n-1"
    .conv2$ = "  · rank tests average tied ranks (tie-corrected)."
    appendInfoLine: .empty$
    appendInfoLine: .conv1$
    appendInfoLine: .conv2$
    appendInfoLine: .border$
endproc


procedure emlReportSection: .title$
    # Print section divider with title
    # Format: ── [title] ──────────────────────────────
    .empty$ = ""
    appendInfoLine: .empty$
    .indent$ = "  "
    .prefix$ = "── "
    .spacer$ = " "
    # Calculate remaining dashes to fill line (target ~46 chars total)
    .usedLength = 2 + 3 + length(.title$) + 1
    .remainingDashes = 46 - .usedLength
    if .remainingDashes < 3
        .remainingDashes = 3
    endif
    .dashes$ = ""
    .i = 1
    while .i <= .remainingDashes
        .dash$ = "─"
        .dashes$ = .dashes$ + .dash$
        .i = .i + 1
    endwhile
    .line$ = .indent$ + .prefix$ + .title$ + .spacer$ + .dashes$
    appendInfoLine: .line$
endproc


procedure emlReportLine: .label$, .value, .decimals
    # Print labeled numeric value with 2-space indent
    # Label padded to 20 characters
    # When emlShowExplanations = 1 and emlWizardExplain$ is set, appends
    # a third tab-separated column with the explanation.
    .indent$ = "  "
    @emlPadRight: .label$, 20
    .paddedLabel$ = emlPadRight.result$
    .formattedValue$ = fixed$(.value, .decimals)
    if emlShowExplanations and emlWizardExplain$ <> ""
        .line$ = .indent$ + .paddedLabel$ + .formattedValue$ + tab$ + tab$ + emlWizardExplain$
        emlWizardExplain$ = ""
    else
        .line$ = .indent$ + .paddedLabel$ + .formattedValue$
    endif
    appendInfoLine: .line$
endproc


procedure emlReportLineString: .label$, .value$
    # Print labeled string value with 2-space indent
    # Label padded to 20 characters
    .indent$ = "  "
    @emlPadRight: .label$, 20
    .paddedLabel$ = emlPadRight.result$
    if emlShowExplanations and emlWizardExplain$ <> ""
        .line$ = .indent$ + .paddedLabel$ + .value$ + tab$ + tab$ + emlWizardExplain$
        emlWizardExplain$ = ""
    else
        .line$ = .indent$ + .paddedLabel$ + .value$
    endif
    appendInfoLine: .line$
endproc


procedure emlReportBlank
    # Print empty line
    .empty$ = ""
    appendInfoLine: .empty$
endproc


# ----------------------------------------------------------------------------
# @emlReportPWithExact: .label$, .pValue
# ----------------------------------------------------------------------------
# Print one p-value row that is BOTH reportable and exact.
#
# D28/D35. The APA rendering floors at .001, so 5.8e-07, 2.1e-13 and 3.0e-04
# all print as "p < .001" — nine orders of magnitude flattened into one
# string, with the real value reachable only from the CSV. The floor is
# correct for a manuscript and useless for reading a result, and the report
# has room for both, so it prints both:
#
#   p                   < .001  (5.8e-07)
#   Kruskal-Wallis      p = .003
#
# The parenthesis appears ONLY when @emlFormatP says the label is inexact
# (.exact$ non-empty), i.e. on the < .001 and > .999 floors. A p of .032 is
# already exact to the printed precision and gets nothing appended.
#
# D9. When the row label already reads "p", the bare form is used so the row
# does not say "p" twice ("p    p < .001"). Any other label — a test name, a
# contrast, "p (adjusted)" — takes the full "p = " form, which is what makes
# the row self-describing away from a column header.
#
# Outputs (for callers that want the same text somewhere else):
#   .value$ — the value column exactly as printed
#   .exact$ — the unrounded value, or "" when the label was already exact
# ----------------------------------------------------------------------------
procedure emlReportPWithExact: .label$, .pValue
    @emlFormatP: .pValue
    .exact$ = emlFormatP.exact$

    ; Does the label already name p? Then do not repeat the "p".
    .trimmed$ = replace_regex$ (.label$, "^\s+|\s+$", "", 0)
    if .trimmed$ = "p" or .trimmed$ = "P"
        .value$ = emlFormatP.bare$
    else
        .value$ = emlFormatP.formatted$
    endif

    if .exact$ <> ""
        .value$ = .value$ + "  (" + .exact$ + ")"
    endif

    @emlReportLineString: .label$, .value$
endproc


# ============================================================================
# FORMATTING PROCEDURES (produce strings, do NOT write to Info window)
# ============================================================================

procedure emlFormatP: .pValue
    # Format p-value according to APA guidelines
    #
    # Outputs:
    #   .formatted$ - the full label, e.g. "p = .032" / "p < .001"
    #   .bare$      - the SAME value with no "p " prefix, e.g. ".032" / "< .001"
    #   .exact$     - the unrounded value in Praat's round-trip form, or "" when
    #                 .formatted$ already shows the number exactly
    #
    # .bare$ exists because ten call sites printed the label twice: they pass
    # "p" as the row label and then print .formatted$, which carries its own
    # "p = " (D9). A column header of "p" over a cell reading "p = .032" is the
    # same defect in table form (D56).
    #
    # .exact$ exists because flooring at .001 flattens real distinctions:
    # 5.8e-07, 2.1e-13 and 3.0e-04 all render "p < .001", nine orders of
    # magnitude reported identically (D35, D28). A caller that has room can
    # print .exact$ beside the floored label instead of choosing between them.
    # Output: .formatted$
    # p < 0.001 -> "p < .001"
    # 0.9995 <= p < 1 -> "p > .999"  (would otherwise round to a false 1.000)
    # p >= 0.001 -> "p = .XXX" (3 decimals, no leading zero)
    # p = 1 exactly -> "p = 1.000"
    # p undefined -> "p = undefined"

    if .pValue = undefined
        .formatted$ = "p = undefined"
    elsif .pValue < 0.001
        .formatted$ = "p < .001"
    elsif .pValue >= 0.9995 and .pValue < 1
        .formatted$ = "p > .999"
    else
        # Format with 3 decimals, remove leading zero
        .rawFormatted$ = fixed$(.pValue, 3)
        # Check if starts with "0." and remove leading zero
        .firstChar$ = left$(.rawFormatted$, 1)
        .zeroChar$ = "0"
        if .firstChar$ = .zeroChar$
            .noLeadingZero$ = right$(.rawFormatted$, length(.rawFormatted$) - 1)
        else
            .noLeadingZero$ = .rawFormatted$
        endif
        .prefix$ = "p = "
        .formatted$ = .prefix$ + .noLeadingZero$
    endif
    # --- derived outputs (see header) ---
    if .pValue = undefined
        .bare$ = "undefined"
        .exact$ = ""
    else
        ; Strip a leading "p " or "p = " from whatever the branches produced,
        ; rather than rebuilding the formatting a second time and risking the
        ; two drifting apart.
        .bare$ = replace_regex$ (.formatted$, "^p\s*=\s*", "", 1)
        .bare$ = replace_regex$ (.bare$, "^p\s*", "", 1)
        if .pValue < 0.001 or (.pValue >= 0.9995 and .pValue < 1)
            .exact$ = string$ (.pValue)
        else
            .exact$ = ""
        endif
    endif

endproc


procedure emlFormatCI: .lower, .upper, .level
    # Format confidence interval string
    # Output: .formatted$
    # level as proportion (0.95 -> "95%"), values to 2 decimals
    # Example: "95% CI [0.22, 1.40]"
    
    .levelPercent = .level * 100
    .levelInt = floor(.levelPercent)
    .levelStr$ = string$(.levelInt)
    .percent$ = "%"
    .ciLabel$ = " CI ["
    .comma$ = ", "
    .bracket$ = "]"
    .lowerStr$ = fixed$(.lower, 2)
    .upperStr$ = fixed$(.upper, 2)
    .formatted$ = .levelStr$ + .percent$ + .ciLabel$ + .lowerStr$ + .comma$ + .upperStr$ + .bracket$
endproc


procedure emlFormatTestResult: .testName$, .statSymbol$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper
    # Format complete test result line
    # Output: .summary$
    # If df2 = 0: single df, e.g., "t(23) = 2.45, p = .021, d = 0.89 [0.32, 1.45]"
    # If df2 > 0: dual df, e.g., "F(2, 27) = 4.85, p = .016, η² = .26"
    # Fractional df: 1 decimal place
    # effectName$ empty: omit effect size
    # ciLower undefined: omit CI brackets
    
    # Format degrees of freedom
    .openParen$ = "("
    .closeParen$ = ")"
    .comma$ = ", "
    .equals$ = " = "
    
    # Check if df1 is fractional (has decimal component)
    .df1Floor = floor(.df1)
    .df1Diff = .df1 - .df1Floor
    if .df1Diff > 0.001
        .df1Str$ = fixed$(.df1, 1)
    else
        .df1Str$ = string$(.df1Floor)
    endif
    
    # Build df string
    if .df2 = 0 or .df2 = undefined
        # Single df
        .dfStr$ = .openParen$ + .df1Str$ + .closeParen$
    else
        # Dual df - check if df2 is fractional
        .df2Floor = floor(.df2)
        .df2Diff = .df2 - .df2Floor
        if .df2Diff > 0.001
            .df2Str$ = fixed$(.df2, 1)
        else
            .df2Str$ = string$(.df2Floor)
        endif
        .dfStr$ = .openParen$ + .df1Str$ + .comma$ + .df2Str$ + .closeParen$
    endif
    
    # Format test statistic (2 decimals)
    .statStr$ = fixed$(.statValue, 2)
    
    # Format p-value
    @emlFormatP: .pValue
    .pStr$ = emlFormatP.formatted$
    
    # Build base result
    .summary$ = .statSymbol$ + .dfStr$ + .equals$ + .statStr$ + .comma$ + .pStr$
    
    # Add effect size if provided
    if .effectName$ <> ""
        .effectStr$ = fixed$(.effectValue, 2)
        .effectPart$ = .comma$ + .effectName$ + .equals$ + .effectStr$
        .summary$ = .summary$ + .effectPart$
        
        # Add CI if provided
        if .ciLower <> undefined and .ciUpper <> undefined
            .ciLowerStr$ = fixed$(.ciLower, 2)
            .ciUpperStr$ = fixed$(.ciUpper, 2)
            .openBracket$ = " ["
            .closeBracket$ = "]"
            .ciPart$ = .openBracket$ + .ciLowerStr$ + .comma$ + .ciUpperStr$ + .closeBracket$
            .summary$ = .summary$ + .ciPart$
        endif
    endif
endproc


procedure emlFormatEffectLabel: .effectValue, .effectType$
    # Return plain-language effect size interpretation
    # Output: .label$      — "" if the effect type is not recognised
    #         .recognized  — 1 if .effectType$ is a known token, else 0
    # Cohen's conventions by effect type

    .absValue = abs(.effectValue)
    .recognized = 1

    # Set thresholds based on effect type (Cohen's conventions)
    # d: negligible < 0.2, small 0.2–0.5, medium 0.5–0.8, large >= 0.8
    # r, w, V: negligible < 0.1, small 0.1–0.3, medium 0.3–0.5, large >= 0.5
    # eta_squared, epsilon2: negligible < 0.01, small 0.01–0.06, medium 0.06–0.14, large >= 0.14
    # r_squared: negligible < 0.01, small 0.01–0.09, medium 0.09–0.25, large >= 0.25
    #   (Cohen 1988: R-squared benchmarks are the squares of the r benchmarks
    #    0.1 / 0.3 / 0.5, so d thresholds mislabel them badly — R-squared = 0.3
    #    is a large effect, not a small one.)
    #
    # D21: an "omega_squared" token was accepted here. Nothing in the plugin
    # computes omega-squared — the token appeared at no call site, in no test
    # and in no validation script — so the branch could not be reached and
    # advertised a capability the library does not have. Removed. If omega²
    # is ever added as an estimator, add the token back beside .eta$: it takes
    # the same 0.01 / 0.06 / 0.14 benchmarks.

    .d$ = "d"
    .r$ = "r"
    .w$ = "w"
    .vUpper$ = "V"
    .eta$ = "eta_squared"
    .eps$ = "epsilon2"
    .epsAlt$ = "epsilon_squared"
    .rSq$ = "r_squared"
    .rSqAlt$ = "R2"
    .rSqAlt2$ = "r2"

    if .effectType$ = .d$
        .negligibleThresh = 0.2
        .mediumThresh = 0.5
        .largeThresh = 0.8
    elsif .effectType$ = .r$ or .effectType$ = .w$ or .effectType$ = .vUpper$
        .negligibleThresh = 0.1
        .mediumThresh = 0.3
        .largeThresh = 0.5
    elsif .effectType$ = .eta$ or .effectType$ = .eps$ or .effectType$ = .epsAlt$
        .negligibleThresh = 0.01
        .mediumThresh = 0.06
        .largeThresh = 0.14
    elsif .effectType$ = .rSq$ or .effectType$ = .rSqAlt$ or .effectType$ = .rSqAlt2$
        .negligibleThresh = 0.01
        .mediumThresh = 0.09
        .largeThresh = 0.25
    else
        # Unknown token: no benchmark exists, so do not invent one.
        .recognized = 0
    endif

    # Determine label (Cohen's conventions)
    if .recognized = 0
        .label$ = ""
    elsif .absValue >= .largeThresh
        .label$ = "large effect"
    elsif .absValue >= .mediumThresh
        .label$ = "medium effect"
    elsif .absValue >= .negligibleThresh
        .label$ = "small effect"
    else
        .label$ = "negligible effect"
    endif
endproc


# ============================================================================
# DESCRIPTIVE TABLE PROCEDURES
# ============================================================================

procedure emlReportDescriptiveHeader
    # Print column header row for descriptive statistics table
    # Columns: Group (14), N (6), Mean (10), SD (10), Median (10)
    .indent$ = "  "
    @emlPadRight: "Group", 14
    .groupCol$ = emlPadRight.result$
    @emlPadRight: "N", 6
    .nCol$ = emlPadRight.result$
    @emlPadRight: "Mean", 10
    .meanCol$ = emlPadRight.result$
    @emlPadRight: "SD", 10
    .sdCol$ = emlPadRight.result$
    @emlPadRight: "Median", 10
    .medianCol$ = emlPadRight.result$
    .headerLine$ = .indent$ + .groupCol$ + .nCol$ + .meanCol$ + .sdCol$ + .medianCol$
    appendInfoLine: .headerLine$
endproc


procedure emlReportDescriptiveRow: .label$, .n, .mean, .sd, .median
    # Print one data row for descriptive statistics table
    # Same column widths as header, 2 decimal places for values
    .indent$ = "  "
    @emlPadRight: .label$, 14
    .groupCol$ = emlPadRight.result$
    
    .nStr$ = string$(.n)
    @emlPadRight: .nStr$, 6
    .nCol$ = emlPadRight.result$
    
    .meanStr$ = fixed$(.mean, 2)
    @emlPadRight: .meanStr$, 10
    .meanCol$ = emlPadRight.result$
    
    .sdStr$ = fixed$(.sd, 2)
    @emlPadRight: .sdStr$, 10
    .sdCol$ = emlPadRight.result$
    
    .medianStr$ = fixed$(.median, 2)
    @emlPadRight: .medianStr$, 10
    .medianCol$ = emlPadRight.result$
    
    .rowLine$ = .indent$ + .groupCol$ + .nCol$ + .meanCol$ + .sdCol$ + .medianCol$
    appendInfoLine: .rowLine$
endproc


# ============================================================================
# APA FORMATTING
# ============================================================================

procedure emlReportAPA: .testType$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper
    # Format complete APA 7th edition result string
    # Output: .formatted$
    # testType$ -> symbol mapping: t->t, F->F, r->r, chi2->χ², U->U, W->W, H->H, z->z
    
    # Map test type to symbol
    .t$ = "t"
    .f$ = "F"
    .rType$ = "r"
    .chi2$ = "chi2"
    .u$ = "U"
    .w$ = "W"
    .h$ = "H"
    .z$ = "z"
    
    if .testType$ = .t$
        .symbol$ = "t"
    elsif .testType$ = .f$
        .symbol$ = "F"
    elsif .testType$ = .rType$
        .symbol$ = "r"
    elsif .testType$ = .chi2$
        .symbol$ = "χ²"
    elsif .testType$ = .u$
        .symbol$ = "U"
    elsif .testType$ = .w$
        .symbol$ = "W"
    elsif .testType$ = .h$
        .symbol$ = "H"
    elsif .testType$ = .z$
        .symbol$ = "z"
    else
        .symbol$ = .testType$
    endif
    
    # Use the test result formatter
    @emlFormatTestResult: .testType$, .symbol$, .statValue, .df1, .df2, .pValue, .effectName$, .effectValue, .ciLower, .ciUpper
    .formatted$ = emlFormatTestResult.summary$
endproc


# ============================================================================
# FILE OUTPUT PROCEDURES
# ============================================================================

procedure emlReportToFile: .filePath$, .content$
    # Write content to file with overwrite protection
    # Output: .success (1/0), .actualPath$
    # If file exists, append ascending integer: results.txt -> results_1.txt
    
    .success = 0
    .actualPath$ = .filePath$
    
    # Check if file exists
    if fileReadable(.filePath$)
        # File exists, need to find available name
        # Extract base name and extension
        .dot$ = "."
        .dotPos = rindex(.filePath$, .dot$)
        
        if .dotPos > 0
            .baseName$ = left$(.filePath$, .dotPos - 1)
            .extension$ = right$(.filePath$, length(.filePath$) - .dotPos + 1)
        else
            .baseName$ = .filePath$
            .extension$ = ""
        endif
        
        # Try incrementing numbers
        .counter = 1
        .found = 0
        while .found = 0 and .counter <= 999
            .underscore$ = "_"
            .counterStr$ = string$(.counter)
            .tryPath$ = .baseName$ + .underscore$ + .counterStr$ + .extension$
            if not fileReadable(.tryPath$)
                .actualPath$ = .tryPath$
                .found = 1
            else
                .counter = .counter + 1
            endif
        endwhile
        
        if .found = 0
            # Could not find available name
            .success = 0
        else
            writeFileLine: .actualPath$, .content$
            .success = 1
        endif
    else
        # File does not exist, write directly
        writeFileLine: .actualPath$, .content$
        .success = 1
    endif
endproc


procedure emlSaveInfoToFile: .filePath$
    # Save current Info window contents to file
    # Output: .success (1/0), .actualPath$
    
    # Capture Info window contents using Praat's special variable
    ; info$ () WITH PARENTHESES. Bare `info$` parses as a string VARIABLE of
    ; that name, which nothing in the plugin ever assigns, so this line was a
    ; hard stop -- proof the procedure has never executed. It was the only
    ; bare info$ in the repository; every other capture site already wrote the
    ; function form. Measured 13 Aug 2026: `nocheck x$ = info$` leaves x$
    ; unset and the next reference of it aborts the script.
    .content$ = info$ ()
    
    # Use the file writer with overwrite protection
    @emlReportToFile: .filePath$, .content$
    .success = emlReportToFile.success
    .actualPath$ = emlReportToFile.actualPath$
endproc


# ============================================================================
# CSV RESULT ACCUMULATION
# ============================================================================
# Shared infrastructure for building CSV export from any entry point.
# Reporters append rows; @emlExportStatsCSV writes the file.

emlCSV_n = 0
# ============================================================================
# CSV EXPORT — tidy long format                              D24 and 13 others
# ============================================================================
# This replaced a fixed 20-column wide schema on 6 August 2026. That schema
# was one header --
#
#   table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,
#   effect_type,effect_label,n1,n2,mean1,sd1,median1,mean2,sd2,median2
#
# -- made to carry the output of every test in the plugin, and it failed in
# fourteen separate findings for three structural reasons:
#
#   1. NO WAY TO SAY "NOT APPLICABLE". Every argument went through fixed$ or
#      string$, so a caller with nothing to report had to pass a number, and
#      every caller passed 0. The one-way omnibus row ended in eight zeros
#      meaning "not applicable", indistinguishable from eight measurements
#      of zero; the doTukey = 0 fallback wrote p = 0.000000, which reads as
#      the most significant result in the file. (D24, and D23/D37/D46/D76.)
#
#   2. SLOTS REUSED FOR UNRELATED QUANTITIES. Regression wrote its slope
#      into mean1, the slope's SE into sd1, the intercept into median1 and R
#      into sd2. Correlation wrote the Y variable into group_col. Paired
#      tests packed two column names into all four level slots. The header
#      said one thing and the file contained another. (D45/D54/D55/D19.)
#
#   3. NOTHING COULD BE ADDED. One df column cannot hold a numerator and a
#      denominator, so F(1,28) exported as df=1.00 and could not be
#      reconstructed; there was nowhere to put SS, MS, a confidence interval
#      or a per-cell n. (D34/D57/D23/D76.)
#
# The long format cannot have any of these problems, which is the point of
# choosing it over widening the wide one. Every value is named where it is
# written, so no slot can be reused; a value you do not have is a row you do
# not write, so no sentinel is needed and none exists; and a new quantity is
# a new field name, not a schema change.
#
#   table,analysis,term,term_type,field,value
#
#   table     -- the source Table's name
#   analysis  -- "One-way ANOVA", "Tukey HSD", "Pearson correlation", ...
#   term      -- what the row is about: a contrast ("Soprano vs Alto"), a
#                factor ("voice_type"), a coefficient ("practice_hrs_wk"), a
#                group ("Alto"), or "" for an omnibus/overall result
#   term_type -- WHICH KIND of thing `term` names. See below.
#   field     -- "F", "df1", "df2", "p", "eta_squared", "estimate", "se",
#                "ci_lower", "n", "mean", "sd", "median", ...
#   value     -- the number, or a string for fields like "method"
#
# WHY term_type IS A COLUMN AND NOT JUST ANOTHER FIELD ROW.
# The first version of this format did not have it, and pivoting the result
# produced a ragged table: a contrast ("Soprano vs Mezzo") and a group
# ("Soprano") both live in `term`, so pivot_wider interleaved q and p_adjusted
# rows with n and mean rows and filled the gaps with NA. Nothing was wrong —
# every row was correct and self-labelled — but the reader had to know to
# filter first, and "you have to know" is a smaller version of the disease
# this format was written to cure. As a field row it would not have helped:
# the whole problem is separating rows BEFORE the pivot, which needs a column.
#
#   omnibus     the analysis as a whole; `term` is ""
#   contrast    a comparison between two levels
#   group       one level's descriptives
#   factor      a term in an ANOVA table (main effect, interaction)
#   coefficient a regression coefficient
#   error       the error line of an ANOVA table
#   total       the total line of an ANOVA table
#   variable    a single measured column (normality, correlation)
#
# So the useful reads are one filter and one pivot:
#   d <- read.csv("x.csv")
#   subset(d, term_type == "contrast") |>
#       tidyr::pivot_wider(names_from = field, values_from = value)
#   subset(d, term_type == "group") |>
#       tidyr::pivot_wider(names_from = field, values_from = value)
#
# Numbers are written with string$, which is Praat's shortest round-trip
# form: 0.002246 stays 0.002246 and 1.06e-14 stays 1.06e-14 rather than
# becoming 0.00000000000001. That also ends the p-value flooring in exports
# (D14's residual) without a separate decision about decimal places.
# ============================================================================

emlCSV_header$ = "table,analysis,term,term_type,field,value"

procedure emlCSVInit
    ; MIGRATION SAFETY. Every orchestrator calls this first, so this is the
    ; one place that can guarantee the three-file declaration flag describes
    ; the analysis about to run rather than a previous one.
    ;
    ; Without it: run ANOVA (declares), then run an unconverted analysis
    ; (does not declare), then export -- emlResult_declared is still 1 and the
    ; export writes the ANOVA's stale tidy/glance/augment under the new
    ; analysis's name. Demonstrated 6 Aug 2026 before this line existed.
    ;
    ; The staged extra frames go with it, for the same reason.
    emlResult_declared = 0
    if variableExists ("emlResult_extraN")
        emlResult_extraN = 0
    endif

    @emlCSVInitRows
endproc


# @emlCSVInitRows
# ────────────────────────────────────────────────────────────────────────────
# THE ROW HALF OF @emlCSVInit, AND NOTHING ELSE. Empties the collector and
# leaves emlResult_declared exactly as it was.
#
# WHO WANTS THIS. A caller that fills the collector but does NOT declare --
# the graphs form's scatter arm is the one there is (NEW-G8-3, 15 Aug 2026:
# nine draws in one session appended nine value-identical blocks to the export
# because nothing on that path ever reset anything). Calling @emlCSVInit there
# would clear the rows and ALSO clear a declaration the scatter cannot replace,
# so a wrapper -> annotated-scatter journey would stop writing tidy and glance
# and drop to the legacy single file: one export defect traded for another.
#
# WHY IT IS A PROCEDURE HERE RATHER THAN FOUR LINES THERE. Two reasons, and the
# second is the load-bearing one. The field list belongs to the file that owns
# the collector, so a fifth field added to it cannot be forgotten at a second
# site. And validate/v46 holds an invariant worth keeping: ONE FILE MAY BRANCH
# ON MIGRATION STATE, and it is this one. The first version of the graphs fix
# saved and restored emlResult_declared across an @emlCSVInit from inside
# eml-graphs-form.praat, which is a second file touching the migration flag --
# v46 went red on it, correctly, and this procedure is what that red line
# asked for.
procedure emlCSVInitRows
    emlCSV_n = 0
    emlCSV_table$ = ""
    emlCSV_termType$ = ""
    emlCSV_nDesc = 0
endproc


# @emlCSVMark / @emlCSVRewind
# ────────────────────────────────────────────────────────────────────────────
# REMEMBER HOW MANY ROWS THERE WERE, AND GO BACK TO IT. For a caller that may
# run a reporting pass it then throws away.
#
# The graphs form is again the one there is: a figure whose legend needs
# y-axis room is drawn TWICE, and the second pass is drawn on an expanded axis
# with the first discarded entirely. The Info window's duplication is
# deliberate and labelled -- Praat cannot un-print a flushed line -- but rows
# that have not been written to a file yet are a different matter, and a figure
# that was never on the page has no business in the export. Measured 15 Aug
# 2026: three presses of a grouped scatter, every key in the exported CSV
# appearing twice, from a run whose presses were already deduped.
#
# NOT A STACK. One mark, because the one caller has one nesting level, and a
# stack nobody pops is a leak with extra steps.
procedure emlCSVMark
    emlCSVMark_have = 0
    if variableExists ("emlCSV_n")
        emlCSVMark_n = emlCSV_n
        emlCSVMark_nDesc = 0
        if variableExists ("emlCSV_nDesc")
            emlCSVMark_nDesc = emlCSV_nDesc
        endif
        emlCSVMark_have = 1
    endif
endproc

procedure emlCSVRewind
    if emlCSVMark_have = 1
        emlCSV_n = emlCSVMark_n
        emlCSV_nDesc = emlCSVMark_nDesc
    endif
endproc


# @emlCSVTermType: .kind$
# Set the kind of thing the following rows' `term` names. Sticky: it applies
# until changed, because the rows for one term are written as a contiguous
# block. Set it once at the top of each block.
procedure emlCSVTermType: .kind$
    emlCSV_termType$ = .kind$
endproc


# @emlCSVSetTable: .table$
# Called once per analysis, before any @emlCSVAdd. Every row carries it.
procedure emlCSVSetTable: .table$
    emlCSV_table$ = .table$
endproc


# @eml_csvQuote: .s$  -- RFC 4180 quoting, so a column label containing a
# comma or a quote cannot silently split a row into two fields. The old
# writer concatenated raw strings and had no protection at all.
procedure eml_csvQuote: .s$
    if index (.s$, ",") > 0 or index (.s$, """") > 0 or index (.s$, newline$) > 0
        .result$ = """" + replace$ (.s$, """", """""", 0) + """"
    else
        .result$ = .s$
    endif
endproc


# @emlCSVAdd: .analysis$, .term$, .field$, .value
# One numeric result. An undefined value writes nothing at all — that is the
# replacement for the zero sentinel, and it is why no sentinel is needed.
procedure emlCSVAdd: .analysis$, .term$, .field$, .value
    if .value <> undefined
        @eml_csvAppend: .analysis$, .term$, .field$, string$ (.value)
    endif
endproc


# @emlCSVAddStr: .analysis$, .term$, .field$, .value$
# One string-valued result (a method name, a direction, an effect label).
# An empty string writes nothing, for the same reason.
procedure emlCSVAddStr: .analysis$, .term$, .field$, .value$
    if .value$ <> ""
        @eml_csvAppend: .analysis$, .term$, .field$, .value$
    endif
endproc


procedure eml_csvAppend: .analysis$, .term$, .field$, .value$
    emlCSV_n = emlCSV_n + 1
    @eml_csvQuote: emlCSV_table$
    .a$ = eml_csvQuote.result$
    @eml_csvQuote: .analysis$
    .b$ = eml_csvQuote.result$
    @eml_csvQuote: .term$
    .c$ = eml_csvQuote.result$
    @eml_csvQuote: emlCSV_termType$
    .t$ = eml_csvQuote.result$
    @eml_csvQuote: .field$
    .d$ = eml_csvQuote.result$
    @eml_csvQuote: .value$
    .e$ = eml_csvQuote.result$
    emlCSV_row$ [emlCSV_n] = .a$ + "," + .b$ + "," + .c$ + "," + .t$ + ","
    ... + .d$ + "," + .e$
endproc


# @emlCSVAddDescriptives: .analysis$, .term$, .n, .mean, .sd, .median
# The group-descriptives block every reporter wants, written as named fields
# so an absent one is absent rather than zero.
procedure emlCSVAddDescriptives: .analysis$, .term$, .n, .mean, .sd, .median
    # Idempotent by (analysis, term). The post-hoc reporters call this from
    # inside their pairwise loop, so a group in k contrasts had its
    # descriptives written k times: with three groups, Soprano's n, mean, sd
    # and median each appeared twice, identical. Harmless to read one row at
    # a time and wrong the moment anyone pivots or aggregates — R warns
    # "multiple rows match" and silently takes the first.
    #
    # Guarded here rather than by restructuring each loop, because the loops
    # differ between the Tukey and Dunn paths and a guard cannot be forgotten
    # by the next reporter that copies the pattern.
    .key$ = .analysis$ + "|" + .term$
    if not variableExists ("emlCSV_nDesc")
        emlCSV_nDesc = 0
    endif
    for .i from 1 to emlCSV_nDesc
        if emlCSV_descKey$ [.i] = .key$
            goto DESC_DONE
        endif
    endfor
    emlCSV_nDesc = emlCSV_nDesc + 1
    emlCSV_descKey$ [emlCSV_nDesc] = .key$

    @emlCSVTermType: "group"
    @emlCSVAdd: .analysis$, .term$, "n", .n
    @emlCSVAdd: .analysis$, .term$, "mean", .mean
    @emlCSVAdd: .analysis$, .term$, "sd", .sd
    @emlCSVAdd: .analysis$, .term$, "median", .median
    label DESC_DONE
endproc

procedure emlExportStatsCSV: .filePath$
    # Write accumulated CSV rows with overwrite protection.
    # Output: .success (1/0), .actualPath$, .reason$
    #
    # D66: an empty buffer used to return .success = 0, and the only caller
    # rendered that as "Could not write CSV file." — a disk-failure message
    # for a file the plugin never attempted to write. Three orchestrators
    # called @emlCSVInit and then never added a row, so their CSV button
    # could not succeed and reported the wrong reason for it. .reason$ now
    # distinguishes the two cases so a caller can say which happened.
    .reason$ = ""
    if emlCSV_n = 0
        .success = 0
        .reason$ = "empty"
        .actualPath$ = .filePath$
    else
        # Build full content
        .content$ = emlCSV_header$
        for .i from 1 to emlCSV_n
            .content$ = .content$ + newline$ + emlCSV_row$[.i]
        endfor
        @emlReportToFile: .filePath$, .content$
        .success = emlReportToFile.success
        .actualPath$ = emlReportToFile.actualPath$
        if .success = 0
            .reason$ = "write"
        endif
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# @emlExportResultFiles: .folder$, .base$
# ────────────────────────────────────────────────────────────────────────────
# THE MIGRATION FORK, IN ONE PLACE. A path that has been converted to the
# three-file broom shape declares into the tidy/glance/augment collectors and
# @emlResultBegin sets emlResult_declared; a path that has not still fills the
# single-file buffer. The fork is on the DECLARATION, not on a per-analysis
# list, so a path converts by declaring and nothing here has to be edited for
# each one.
#
# WHY IT IS A PROCEDURE. It used to live inline inside @emlWrapperExportCSV,
# which meant the graphs form's "Exp CSV" button -- the only other export in
# the plugin -- could not reach it, and called @emlExportStatsCSV directly.
# The same analysis therefore produced three broom-shaped files from the
# wrapper's CSV button and one legacy long-format file from the graphs button.
# Nothing caught it: v20/v21 enumerate the stats-menu orchestrators, and this
# is a second exporter that no harness had ever pressed. Extracted 13 Aug 2026
# so both buttons write through one implementation.
#
# WRITING ONLY -- no dialogs. The two callers report differently (the wrapper
# lists every file it wrote; the graphs form already has its own Export
# Complete / Export Failed pair), and a shared procedure that opened a dialog
# could not be called from inside another one.
#
# BOTH ARMS ARE NON-DESTRUCTIVE. The declared arm could not be, until 13 Aug
# 2026: @emlGenerateUniquePath lived in graphs/eml-graphs-form.praat, which is
# included AFTER this file, so it was unreachable from here and the three-file
# export would silently overwrite a previous one. Moving that procedure to
# stats/eml-core-utilities.praat -- the first include in both barrels -- is
# what closed it. The BASE is uniqued once, against the tidy frame, and every
# frame in the set then shares the walked base, so a set never half-overwrites
# an older set. The legacy arm keeps the uniquing it always had, inside
# @emlReportToFile.
#
# Arguments:
#   .folder$ — destination folder, no trailing separator
#   .base$   — file name stem, no extension
# Outputs:
#   .declared    1 if the analysis declared, 0 if it fell back to legacy
#   .success     1 if at least one file was written
#   .nWritten    how many files
#   .fileList$   newline-separated absolute paths
#   .skipped$    which frames the writer skipped, and why (declared arm)
#   .actualPath$ the single file written (legacy arm)
#   .reason$     "" | "empty" | "write"
# ────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────
# @emlHaveExportableResult -- is there anything for the export step to write?
#
# WHY THIS EXISTS AS A PROCEDURE rather than as three lines at each call site.
# The question "has an analysis produced something exportable" has exactly two
# answers, and they live on two different sides of the broom migration: an
# unconverted analysis fills the legacy buffer (emlCSV_n), a converted one
# declares into the broom collectors (emlResult_declared). Anyone asking the
# question has to know both, and to know that Praat does NOT short-circuit
# `and`, so the read has to be nested or it aborts on the very session the
# guard was written for.
#
# That knowledge belongs to this file and nowhere else. v46 pins exactly that:
# only eml-output.praat may branch on the migration flag, because a second
# reader is a second thing to update on the day the migration finishes -- and
# the way this class of defect actually arrives is that the second reader is
# updated late, or not at all, and disagrees silently. The recorder's replay
# writer needs the answer (it writes the same set of files headlessly, with no
# panel), so it asks rather than re-deriving.
#
# Returns .result = 1 when @emlExportResultFiles would write something.
# ────────────────────────────────────────────────────────────────────────────
procedure emlHaveExportableResult
    .result = 0
    if variableExists ("emlCSV_n")
        if emlCSV_n > 0
            .result = 1
        endif
    endif
    if variableExists ("emlResult_declared")
        if emlResult_declared = 1
            .result = 1
        endif
    endif
endproc

procedure emlExportResultFiles: .folder$, .base$
    .declared = 0
    .success = 0
    .nWritten = 0
    .fileList$ = ""
    .skipped$ = ""
    .actualPath$ = ""
    .reason$ = ""

    # NESTED, NOT `and`. PRAAT DOES NOT SHORT-CIRCUIT: it evaluates BOTH
    # operands before applying the operator, so
    #
    #     if variableExists ("emlResult_declared") and emlResult_declared = 1
    #
    # aborts with "Unknown variable" on the very case the guard was written to
    # survive. Measured 14 Aug 2026 on Praat 6.6.30 -- the same law that made
    # the Kruskal bridge use nested ifs.
    #
    # WHY IT MATTERED HERE AND NOWHERE ELSE. Reached through @emlSavePanel the
    # guard is dead code: the panel only calls this when emlCSV_n > 0 or
    # emlResult_declared = 1, and both imply an orchestrator ran @emlCSVInit,
    # which sets the variable. But this procedure is also the CODE/API export
    # path -- dialog-free, callable from a user's own script -- and there the
    # first call in a fresh session has nothing set. The guard existed because
    # that case is real, and it was the one case the guard could not survive.
    .declared = 0
    if variableExists ("emlResult_declared")
        if emlResult_declared = 1
            .declared = 1
        endif
    endif
    if .declared = 1
        # UNIQUE THE BASE, NOT EACH FILE. A set is tidy + glance + augment +
        # up to two extras, and they have to stay a set: uniquing them
        # independently would put frame 1 of the new export beside frames 2
        # and 3 of the old one under names that read as siblings. The tidy
        # frame is the probe because @emlResultWrite always attempts it, and
        # the walked suffix is then carried by every frame in the set.
        .probe$ = .folder$ + "/" + .base$ + "_tidy.csv"
        if fileReadable (.probe$)
            .n = 1
            while fileReadable (.folder$ + "/" + .base$ + "_" + string$ (.n)
                ... + "_tidy.csv")
                .n = .n + 1
            endwhile
            .base$ = .base$ + "_" + string$ (.n)
        endif
        @emlResultWrite: .folder$, .base$
        .nWritten = emlResultWrite.written
        .fileList$ = emlResultWrite.files$
        .skipped$ = emlResultWrite.skipped$

        # Post-hoc and effect sizes are separate model objects in R and are
        # separate files here. Written only if the analysis declared them,
        # which it signals by leaving a non-empty extras name.
        # ONE LOOP OVER THE LIST. This used to be two copy-pasted blocks,
        # one per named slot, which is where the two-frame ceiling came from.
        for .e to emlResult_extraN
            .pe$ = .folder$ + "/" + .base$ + "_" + emlResult_extra$ [.e]
            ... + "_tidy.csv"
            writeFile: .pe$, emlResult_extraText$ [.e]
            .nWritten = .nWritten + 1
            .fileList$ = .fileList$ + .pe$ + newline$
        endfor

        if .nWritten > 0
            .success = 1
        else
            # A half-converted path -- declaring but producing no rows --
            # reports as an empty export rather than silently writing the
            # legacy file, which is the failure mode that let the previous
            # migration be recorded as done.
            .reason$ = "empty"
        endif
    else
        .actualPath$ = .folder$ + "/" + .base$ + ".csv"
        @emlExportStatsCSV: .actualPath$
        .success = emlExportStatsCSV.success
        .actualPath$ = emlExportStatsCSV.actualPath$
        .reason$ = emlExportStatsCSV.reason$
        if .success
            .nWritten = 1
            .fileList$ = .actualPath$
        endif
    endif
endproc

# ────────────────────────────────────────────────────────────────────────────
# @emlWrapperCommonFields
# Injects shared fields into an open beginPause dialog. Called between
# beginPause: and endPause: in wrapper scripts.
# Verified: Procedure calls inside beginPause inject fields into the
# active dialog (Praat 6.4.62, macOS, 13 April 2026).
#
# Fields:
#   boolean: "Clear Info window", emlLastClearInfo
#
# Variable derivation (available after endPause):
#   clear_Info_window (numeric, 0 or 1)
#
# D74: the section marker was `comment: "--- Options ---"`, the only ASCII
# rule in the plugin and the only labelled one. Every dialog separates its
# zones with the heavy box-drawing rule (see dev/DESIGN_DIALOG_SYSTEM.md,
# "Separator"), and this procedure appears in every wrapper, so the outlier
# was visible everywhere. It now emits that rule.
#
# D52: the toggle was the literal 0, so it reset to unchecked on every
# `New` — the user re-checked "Clear Info window" once per iteration of a
# loop whose whole purpose is iteration. The choice now persists in
# emlLastClearInfo for the rest of the session, the same way
# emlLastCSVFolder$ persists the export folder. @emlHandleCommonFields
# records it, because that is the procedure that already reads the answer.
#
# Usage:
#   beginPause: "My Analysis"
#       # ... wrapper-specific fields ...
#       @emlWrapperCommonFields
#   clicked = endPause: "Quit", "Run", 2, 0
#
#   @emlHandleCommonFields
#
# Group order is NOT included — not all wrappers have group columns.
# Wrappers needing group order add it to their own dialog.
# ────────────────────────────────────────────────────────────────────────────
emlLastClearInfo = 0

procedure emlWrapperCommonFields
    if not variableExists ("emlLastClearInfo")
        emlLastClearInfo = 0
    endif
    comment: ""
    comment: "─────────────────────────────────────"
    boolean: "Clear Info window", emlLastClearInfo
endproc

# ────────────────────────────────────────────────────────────────────────────
# @emlHandleCommonFields
# Post-endPause handler for shared fields. Call immediately after endPause
# return value and variable derivation, before the orchestrator call.
# ────────────────────────────────────────────────────────────────────────────
procedure emlHandleCommonFields
    ; D52: remember the answer so the next trip round the wrapper's repeat
    ; loop (and the next wrapper this session) reopens with it still set.
    emlLastClearInfo = clear_Info_window
    if clear_Info_window
        @emlClearInfo
    endif

    ; D27: this runs once per Run, inside the wrapper's repeat loop, and it
    ; runs before the orchestrator prints anything — so it is the one place
    ; that can stamp the analysis path's origin on the report about to be
    ; written, for every wrapper at once and with no wrapper edited.
    ; @emlWrapperInit would be wrong: it is called once, outside the loop,
    ; and would label only the first of a session's runs.
    ; A wrapper that also knows its adjustment should call @emlReportContext
    ; itself after this, which overwrites both halves.
    @emlReportContext: "analysis dialog", ""
endproc


# ============================================================================
# WRAPPER INFRASTRUCTURE — shared init and post-analysis procedures
# ============================================================================

# ────────────────────────────────────────────────────────────────────────────
# @emlWrapperInit
# Validates Table selection, loads column names, guesses column roles.
# Call at the top of every wrapper script.
#
# Parameters:
#   .minCols — minimum number of columns required (1, 2, or 3)
#
# Outputs:
#   .tableId, .tableName$ — the selected Table
#   .nCols — number of columns
#   .guessDataIdx, .guessGroupIdx, .guessDataIdx2 — from @emlGuessColumnRoles
#
# Usage:
#   @emlWrapperInit: 2
#   tableId = emlWrapperInit.tableId
#   tableName$ = emlWrapperInit.tableName$
# ────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────
# @eml_auditLabelColumn: .tableId, .columnName$        (private)
# ────────────────────────────────────────────────────────────────────────────
# CLASSIFY THE LABEL COLUMN A COERCION MANUFACTURES. It does not assume the
# column holds anything, and it does not invent anything to put in it.
#
# AUTHOR RULING, 15 August 2026: "probe should classify column types, never
# assume numeric."
#
# WHAT IT IS FOR. `To Table: "row"` writes the source object's ROW LABELS into
# a column called "row". A Matrix has none, and a TableOfReal may have none or
# may have some. Praat stores a missing label as an UNDEFINED cell, and
# `Get value:` renders an undefined cell as the one-character string "?" --
# measured on 6.6.30, 15 Aug 2026. That string is not "" and it is not
# "--undefined--", which are the two forms @eml_strictNumericColumn's scan
# recognises, so the scan passed the column as readable and the numericiser
# behind it raised:
#
#     Table "eml_numericProbe": the cell in row 1 of column "row" is
#     undefined. ... cannot get all numbers in column 1.
#
# -- a native abort with an internal temp table's name in it, fired from
# @emlGuessColumnRoles BEFORE the wrapper's dialog ever opened, on every
# Matrix and on every TableOfReal whose row labels are missing or partial.
# Reproduced at HEAD on all three shapes before this procedure was written.
#
# "?" ROUND-TRIPS BACK TO UNDEFINED. `Set string value: r, c$, "?"` stores an
# undefined cell again, which is why the partial-label case died a second way:
# @eml_strictOneCell copies the literal into a one-cell probe table named "v"
# and the same raise came back with "v" in the message instead of "row".
# So the repair cannot be "write the literal back"; it has to be to a string
# Praat will actually keep.
#
# WHAT IT DOES, AND WHAT IT DELIBERATELY DOES NOT DO. Every unlabelled cell
# becomes the EMPTY STRING -- a form every EML classifier already handles, and
# the one @eml_strictNumericColumn was written to treat as unreadable. The
# result is a classification (.strict = 0, .unreadable = 1) instead of an
# abort, which is the whole of the ruling.
#
# It does NOT fill in default row labels, and it does not delete the column.
# Default labels are a naming decision that belongs with the conversion side
# of this work, not here, and this procedure is written so that it composes
# with whatever that decision turns out to be: run against a column that is
# already fully labelled it changes nothing and reports .nUnlabelled = 0, so
# it is idempotent and order-independent. Whoever supplies labels first wins;
# this only guarantees that whatever arrives is READABLE.
#
# Arguments:
#   .tableId     - the converted Table
#   .columnName$ - the label column's name ("row", or whatever the collision
#                  rename left it as)
# Outputs:
#   .nRows, .nLabelled, .nUnlabelled
#   .verdict$    - "labelled", "partial" or "empty"
# ────────────────────────────────────────────────────────────────────────────
procedure eml_auditLabelColumn: .tableId, .columnName$
    .nRows = 0
    .nLabelled = 0
    .nUnlabelled = 0
    .verdict$ = "empty"

    selectObject: .tableId
    .nRows = Get number of rows

    for .r from 1 to .nRows
        selectObject: .tableId
        .cell$ = Get value: .r, .columnName$
        if .cell$ = "" or .cell$ = "?" or .cell$ = "--undefined--"
            .nUnlabelled = .nUnlabelled + 1
            # Only when it is not ALREADY the empty string, so a table that
            # needs nothing is not written to at all.
            if .cell$ <> ""
                Set string value: .r, .columnName$, ""
            endif
        else
            .nLabelled = .nLabelled + 1
        endif
    endfor

    if .nLabelled = 0
        .verdict$ = "empty"
    elsif .nUnlabelled > 0
        .verdict$ = "partial"
    else
        .verdict$ = "labelled"
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# @eml_defaultRowLabels: .tableId, .columnName$        (private)
# ────────────────────────────────────────────────────────────────────────────
# ONE CONVENTION FOR THE MANUFACTURED ROW-LABEL COLUMN, AND THIS IS IT: r1..rn.
#
# The coercion had grown three of them, independently, and a Matrix reached a
# different `row` column depending on which door the user came in by:
#
#     scripts/eml-describe-table.praat    r1 .. rn
#     @emlWrapperInit (here)              empty -- readable, but blank
#     @emlCleanConvertedTable (graphs)    1 .. n
#
# Three behaviours for one column is not three tastes; it is a table whose
# shape depends on the menu item, and two of the three are wrong for the same
# reason: 1..n is a column of bare integers, which every numeric filter in
# this plugin classifies as a measurement and every column picker then offers
# as one, and blank is a column with a name and no content that a user has to
# guess the meaning of. "r1" cannot be mistaken for data in any locale, so the
# label column stays a label column wherever it is read.
#
# COMPOSES WITH THE CLASSIFIER RATHER THAN REPLACING IT. @eml_auditLabelColumn
# runs first and normalises Praat's "?" to the empty string; this fills what is
# still empty. Splitting it that way keeps the classifier's verdict honest --
# it reports what the SOURCE object carried, not what was written afterwards --
# and it is why a partially labelled TableOfReal keeps every label the user
# supplied and gets defaults only in the gaps.
#
# Arguments:
#   .tableId, .columnName$ - the converted Table and its label column
# Outputs:
#   .nDefaulted - how many rows were given a default label
# ────────────────────────────────────────────────────────────────────────────
procedure eml_defaultRowLabels: .tableId, .columnName$
    .nDefaulted = 0
    selectObject: .tableId
    .nRows = Get number of rows
    for .r from 1 to .nRows
        selectObject: .tableId
        .cell$ = Get value: .r, .columnName$
        if .cell$ = "" or .cell$ = "?" or .cell$ = "--undefined--"
            Set string value: .r, .columnName$, "r" + string$ (.r)
            .nDefaulted = .nDefaulted + 1
        endif
    endfor
endproc


# ────────────────────────────────────────────────────────────────────────────
# @eml_nameUnlabelledColumns: .tableId        (private)
# ────────────────────────────────────────────────────────────────────────────
# A MATRIX HAS NO COLUMN NAMES EITHER, and `To Table: "row"` writes the literal
# "?" as the header of every one of them. So a three-column Matrix arrived at
# Compare groups, Correlate and Regression with a column menu reading
#
#     row, ?, ?, ?
#
# -- three identically named columns, verified live on 15 August 2026. That is
# the severity-1 duplicate-label mechanism (S1) arriving by the coercion route
# rather than by the editor's: every name-addressed read in this plugin is
# `Get value: row, name$`, Praat returns the FIRST column of that name, and the
# second and third are unreachable. Picking "?" number 2 out of the menu does
# not fail -- it silently analyses column 2's data under column 3's heading,
# and the user has no way to see it. Nothing in an output names a column index.
#
# @emlCleanConvertedTable in the graphs layer has performed this rename since
# 12 August; the stats coercion never did. Same rule here, and by column
# INDEX, so the invented name says which column it is.
#
# Arguments:
#   .tableId - the converted Table
# Outputs:
#   .nNamed - how many headers were invented
# ────────────────────────────────────────────────────────────────────────────
procedure eml_nameUnlabelledColumns: .tableId
    .nNamed = 0
    selectObject: .tableId
    .nCols = Get number of columns
    for .c from 1 to .nCols
        selectObject: .tableId
        .lab$ = Get column label: .c
        if .lab$ = "?" or .lab$ = ""
            Rename column (by number): .c, "Column_" + string$ (.c)
            .nNamed = .nNamed + 1
        endif
    endfor
endproc


procedure emlWrapperInit: .minCols
    .nTables = numberOfSelected ("Table")
    .nToR = numberOfSelected ("TableOfReal")
    .nMatrix = numberOfSelected ("Matrix")
    .converted = 0

    if .nTables = 1
        # Table selected — use directly
        .tableId = selected ("Table")
        .tableName$ = selected$ ("Table")

    elsif .nTables = 0 and .nToR = 1
        # TableOfReal selected — auto-convert to Table
        .torId = selected ("TableOfReal")
        .torName$ = selected$ ("TableOfReal")
        selectObject: .torId
        .tableId = To Table: "row"
        # NAME IT ON THE LINE AFTER THE CONVERSION, NOT IN A CLEANUP HANDLER
        # (NEW-G12-2). `To Table:` gives the new Table the source object's
        # name, so until this line runs the object list holds "Table srcobj"
        # beside "TableOfReal srcobj" and a native error anywhere below --
        # and the whole reason this procedure has guards is that there are
        # errors below -- strands the pair with no cleanup ever running. The
        # user's next selection is then a coin flip between their data and a
        # temporary. At creation is the only placement that survives the
        # crash it exists for; a handler at the bottom is the placement that
        # is skipped by exactly the event it is written for.
        selectObject: .tableId
        Rename: "eml_converted_" + .torName$
        .tableName$ = selected$ ("Table")
        .converted = 1
        # CLASSIFY THE LABEL COLUMN BEFORE ANY PROBE READS IT, and say what
        # was found rather than claiming labels are there. The old line said
        # "Row labels are in column ""row""" unconditionally, which was a
        # false statement on an unlabelled TableOfReal and the crash that
        # followed was the user's first hint.
        @eml_auditLabelColumn: .tableId, "row"
        # THEN GIVE THE GAPS A DEFAULT, r1..rn -- the one convention, shared
        # with scripts/eml-describe-table.praat. The classifier's verdict is
        # taken FIRST so it still reports what the source object carried.
        @eml_defaultRowLabels: .tableId, "row"
        # AND THE HEADERS, ON THIS ARM TOO. Measured on 6.6.30, 15 Aug 2026:
        # a TableOfReal carries column labels only if something set them, and
        # `To TableOfReal` from a Matrix sets none -- so an unlabelled
        # TableOfReal converts to `row, ?, ?, ?` exactly as a Matrix does, and
        # the duplicate-name hazard is not Matrix-only. The audit reported it
        # against the Matrix route because that is the route that was driven.
        @eml_nameUnlabelledColumns: .tableId
        if eml_auditLabelColumn.verdict$ = "labelled"
            appendInfoLine: "Converted TableOfReal """, .torName$,
            ... """ to Table """, .tableName$, """. Row labels are in "
            ... + "column ""row""."
        elsif eml_auditLabelColumn.verdict$ = "partial"
            appendInfoLine: "Converted TableOfReal """, .torName$,
            ... """ to Table """, .tableName$, """. Row labels are in "
            ... + "column ""row""; ",
            ... eml_auditLabelColumn.nUnlabelled, " of ",
            ... eml_auditLabelColumn.nRows, " row(s) had none and were "
            ... + "given default labels r1..r", eml_auditLabelColumn.nRows,
            ... "."
        else
            appendInfoLine: "Converted TableOfReal """, .torName$,
            ... """ to Table """, .tableName$, """. It had no row labels, "
            ... + "so column ""row"" holds default labels r1..r",
            ... eml_auditLabelColumn.nRows, "."
        endif
        if eml_nameUnlabelledColumns.nNamed > 0
            appendInfoLine: "It carried no column labels either, so ",
            ... eml_nameUnlabelledColumns.nNamed, " column(s) were named "
            ... + "Column_<n> by position."
        endif
        appendInfoLine: ""

    elsif .nTables = 0 and .nToR = 0 and .nMatrix = 1
        # Matrix selected — convert via TableOfReal → Table
        .matId = selected ("Matrix")
        .matName$ = selected$ ("Matrix")
        selectObject: .matId
        .tempTorId = To TableOfReal
        .tableId = To Table: "row"
        removeObject: .tempTorId
        # NAMED AT CREATION, for the reason given in the TableOfReal arm
        # above (NEW-G12-2). A Matrix reaches here through a TableOfReal that
        # is removed on this side of the conversion, so between these two
        # lines the object list holds "Table srcobj" beside "Matrix srcobj".
        selectObject: .tableId
        Rename: "eml_converted_" + .matName$
        .tableName$ = selected$ ("Table")
        .converted = 1
        # Check for column name collision with "row"
        .labelCol$ = "row"
        selectObject: .tableId
        .checkNCols = Get number of columns
        for .iCheck from 2 to .checkNCols
            .checkLabel$ = Get column label: .iCheck
            if .checkLabel$ = "row"
                Rename column (by number): 1, "OriginalRowLabel"
                .labelCol$ = "OriginalRowLabel"
                .iCheck = .checkNCols
            endif
        endfor
        # A MATRIX HAS NO ROW LABELS AT ALL, so this column is always empty
        # and always undefined -- which is the shape that aborted every
        # Matrix-selected wrapper before its dialog opened. Classified, and
        # made readable, by the column's REAL name: the collision rename above
        # can have moved it, and auditing "row" after that rename would audit
        # the user's own data column instead.
        @eml_auditLabelColumn: .tableId, .labelCol$
        # THEN THE DEFAULTS, r1..rn, on the type that never has any.
        @eml_defaultRowLabels: .tableId, .labelCol$
        # AND THE COLUMN HEADERS, which a Matrix has none of either: without
        # this the dialog's column menu reads "row, ?, ?, ?" and the second
        # and third "?" address the first one's data. See
        # @eml_nameUnlabelledColumns.
        @eml_nameUnlabelledColumns: .tableId
        appendInfoLine: "Converted Matrix """, .matName$,
        ... """ to Table """, .tableName$, """. A Matrix carries no row or "
        ... + "column labels, so column """, .labelCol$,
        ... """ holds default labels r1..r", eml_auditLabelColumn.nRows,
        ... ", and ", eml_nameUnlabelledColumns.nNamed,
        ... " unnamed column(s) were named Column_<n> by position."
        appendInfoLine: ""

    else
        # THE PLUGIN'S OWN SURFACE, not Praat's. This was a raw exitScript
        # with a message, which Praat renders as its own error window with
        # "Script exited. ... Command ... not executed." underneath — the
        # interpreter's stack shown to a user whose only mistake was
        # selecting two objects instead of one. The remedy names what to
        # select, which is what "entry" mode is for.
        @emlErrorDialog: "This tool works on one table at a time, and the "
        ... + "Objects window currently has " + string$ (.nTables + .nToR
        ... + .nMatrix) + " suitable object(s) selected.",
        ... "one Table|one TableOfReal|one Matrix", "entry"
        exitScript: ""
    endif

    ; Praat's CSV reader strips quotes from data cells but leaves them on
    ; header cells, so a table exported by R's write.csv() (which quotes
    ; headers by default) arrives with columns literally named `"value"` and
    ; every lookup fails with "Data column not found". Repaired here, at the
    ; single point every wrapper enters through, and announced rather than
    ; done silently -- the user's object is being modified.
    @emlStripHeaderQuotes: .tableId
    if emlStripHeaderQuotes.nStripped > 0
        appendInfoLine: "Removed surrounding quotes from ",
        ... emlStripHeaderQuotes.nStripped, " column name(s):"
        appendInfo: emlStripHeaderQuotes.report$
        appendInfoLine: "(Praat keeps quotes on headers but not on cells. "
        ... + "The table object has been corrected.)"
        appendInfoLine: ""
    endif

    @emlTableColumnNames: .tableId
    .nCols = emlTableColumnNames.nCols
    if .nCols < .minCols
        # SAME SURFACE, AND NOW IT SAYS WHAT IT FOUND. The old line named the
        # requirement and not the table, so a user with a one-column table
        # read "Table needs at least 2 columns." and had no way to tell
        # whether the plugin had misread their file or they had selected the
        # wrong object. No remedy is offered: no other EML tool would help,
        # and inviting a menu walk that also refuses is worse than silence.
        @emlErrorDialog: "This tool needs at least " + string$ (.minCols)
        ... + " column(s), and """ + .tableName$ + """ has " + string$ (.nCols)
        ... + ".", "", "entry"
        exitScript: ""
    endif

    @emlGuessColumnRoles: .tableId
    .guessDataIdx = emlGuessColumnRoles.dataIdx
    .guessGroupIdx = emlGuessColumnRoles.groupIdx
    .guessDataIdx2 = emlGuessColumnRoles.dataIdx2

    # Say up front which cells will be excluded and why. @emlAuditColumn has
    # classified them correctly since the C96 work, but its note reached the
    # user on one path only, so on every other wrapper a column of "1,5" was
    # quietly dropped and the only symptom was a smaller n than expected.
    @emlCheckDataScheme: .tableId
    .dataCheck$ = emlCheckDataScheme.report$
    if .dataCheck$ <> ""
        appendInfoLine: ""
        appendInfoLine: .dataCheck$
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# THE PANEL'S REMEMBERED FOLDER, SEEDED AT LOAD.
# ────────────────────────────────────────────────────────────────────────────
# emlLastCSVFolder$ is the folder every non-graphing save proposes: the nine
# stats wrappers and the wizard all pass it to @emlSavePanel and all write the
# panel's answer back into it, so it carries the user's choice from one
# analysis to the next within a session.
#
# IT WAS SEEDED NOWHERE. Until 14 August 2026 the only thing that gave it a
# value was @emlWrapperExportCSV, which did it on its own first line:
#
#     if not variableExists ("emlLastCSVFolder$")
#         emlLastCSVFolder$ = homeDirectory$
#     endif
#
# When the save panel replaced that procedure at all ten call sites, the seed
# went with the procedure -- it lived INSIDE the thing being superseded. Praat
# evaluates a procedure's arguments before entering it, so
#
#     @emlSavePanel: 0, tableName$ + "_two-group", emlLastCSVFolder$
#
# aborted with "Unknown variable: emlLastCSVFolder$" BEFORE the panel ran.
# Every wrapper and the wizard died on the FIRST press of Save in a session,
# and the analysis the user had just run died with them.
#
# WHY NOTHING CAUGHT IT, which is the part worth keeping. v46 is a static
# call-site check and it passed: the call site is there, it names the panel,
# the superseded procedure has no callers -- every claim v46 makes was true.
# A static check can see that a call exists; it cannot see that an ARGUMENT is
# unbound. harness/wrappers runs each wrapper headless and asks only whether
# it parses, and this parses. Nothing had ever pressed the Save button on any
# of the ten non-graphing paths, so the first line of the panel's contract was
# never executed. harness/savepaths exists because of this, and found it on
# its first press.
#
# SEEDED HERE, ONCE, rather than in ten wrappers: this file defines the panel,
# so it owns the panel's state, and a top-level line in an included file runs
# when the barrel loads (the same mechanism as emlCSV_n above). The
# variableExists guard keeps a value a caller set deliberately.
if not variableExists ("emlLastCSVFolder$")
    emlLastCSVFolder$ = homeDirectory$
endif
if emlLastCSVFolder$ = ""
    emlLastCSVFolder$ = homeDirectory$
endif

# ────────────────────────────────────────────────────────────────────────────
# @eml_saveSafeBaseName: .raw$        (private)
# ────────────────────────────────────────────────────────────────────────────
# THE PANEL OWNS THE NAMING CONTRACT, so it owns the characters too.
#
# WHAT IT COST TO LEARN. A user who types `pre/post` into the Base name field
# after a completed analysis gets, at 6.6.30:
#
#     Error: Cannot create file "<folder>/pre/post_..._tidy.csv".
#     Hint: one of the folders in this file path does not exist.
#
# and the script stops there. That is inside @emlSavePanel, so the "Saved"
# receipt never draws, the panel never returns, and the caller's
# Done | Save | Draw | New loop -- which is a `repeat ... until` around the
# panel -- never runs again. The completed analysis and every way back to it
# are gone, and Praat's recovery text names a window that no longer exists.
# Reproduced at HEAD, 15 Aug 2026, before this procedure was written.
#
# WHICH CHARACTERS, MEASURED RATHER THAN GUESSED. On this Linux sandbox at
# 6.6.30, writeFile: was driven once per candidate character across 33 of
# them: only "/" is refused. That is the FILESYSTEM's answer, not the
# plugin's, and it is the answer on exactly one of the three platforms this
# plugin ships to. The set below is the union of what any supported platform
# refuses, because a base name is a thing users carry between machines:
#
#     /   POSIX and macOS path separator; refused here, measured
#     \   Windows path separator
#     :   Windows reserved; the classic Mac OS separator, which Finder still
#         renders as "/" -- so a name with ":" reads back as a different name
#     * ? < > |   refused by every Windows filesystem
#     "   refused by Windows AND unsafe here for a second reason: the panel
#         emits `@emlSavePanel: 0, "<stem>", outputFolder$` into a RECORDED
#         script, and a quote inside the stem closes that string early. A
#         recorded workflow would replay into a parse error.
#
# Praat's `word:` field refuses a SPACE itself -- measured: it raises
# "should be a single ink-word and cannot contain a space", keeps the dialog
# up and lets the user correct it -- so spaces need no handling here.
#
# APPENDIX E DOES NOT APPLY. %, #, ^ and _ are Praat's style toggles in
# PICTURE-window text. `comment:` in a pause form is a GTK label and renders
# all four literally -- driven and screenshotted on 6.6.30, 15 Aug 2026 --
# and the plugin's own suffixes (_tidy.csv, _glance.csv) are made of "_", so
# escaping them here would corrupt every file name the panel writes.
#
# SANITISE SILENTLY, THEN DISCLOSE -- and the choice is made against this
# panel's existing behaviour rather than in the abstract. The panel already
# repairs quietly and shows the result: it CREATES a folder the user typed
# but does not have, it SUBSTITUTES "eml_results_<stamp>" for an empty name,
# and it WALKS the stem to _1 when the name is taken. None of the three asks
# first, and all three are visible afterwards because the receipt lists the
# full absolute path of every file written. A refusal, by contrast, would
# have to re-open the dialog, and re-opening it is where the one-stamp rule
# is easiest to break -- a second @emlFileStamp would put two seconds on one
# analysis. It would also answer a user who has just finished an analysis
# with a "no" at the last step, which is the shape of failure this whole fix
# exists to remove. The receipt says what the name became when it changed, so
# nothing is hidden.
#
# THE STAMP IS UNTOUCHED. Sanitising happens ONCE, on the stem, before the
# collision walk and before any write, so every file of one press still
# carries one base name and one stamp -- the author's condition of 14 Aug
# 2026.
#
# Outputs: .result$ (the safe name), .changed (1 if anything was replaced)
# ────────────────────────────────────────────────────────────────────────────
procedure eml_saveSafeBaseName: .raw$
    .result$ = .raw$
    # One pass per character, replacing with "-". NOT "_": the panel tells
    # files apart by underscore-led suffixes, so turning "pre/post" into
    # "pre_post" would hand back a name that reads as if it already carried
    # one of them.
    .result$ = replace$ (.result$, "/", "-", 0)
    .result$ = replace$ (.result$, "\", "-", 0)
    .result$ = replace$ (.result$, ":", "-", 0)
    .result$ = replace$ (.result$, "*", "-", 0)
    .result$ = replace$ (.result$, "?", "-", 0)
    .result$ = replace$ (.result$, "<", "-", 0)
    .result$ = replace$ (.result$, ">", "-", 0)
    .result$ = replace$ (.result$, "|", "-", 0)
    .result$ = replace$ (.result$, """", "-", 0)

    # LEADING AND TRAILING DOTS AND SPACES. A name that begins with "." is
    # hidden on every POSIX desktop -- the user's results would be written
    # correctly and be invisible in their file browser -- and Windows silently
    # strips a trailing "." or " ", which would make the saved name differ
    # from the one the receipt printed.
    while startsWith (.result$, ".") or startsWith (.result$, " ")
        .result$ = right$ (.result$, length (.result$) - 1)
    endwhile
    while endsWith (.result$, ".") or endsWith (.result$, " ")
        .result$ = left$ (.result$, length (.result$) - 1)
    endwhile

    .changed = 0
    if .result$ <> .raw$
        .changed = 1
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# @eml_saveFolderWritable: .folder$        (private)
# ────────────────────────────────────────────────────────────────────────────
# CAN THIS FOLDER BE WRITTEN TO? Asked before the flush, not discovered
# during it.
#
# WHAT IT COST TO LEARN. Point the panel at a folder that exists and cannot
# be written -- a read-only network share, a locked-down departmental drive,
# a mount that went read-only under you -- and 6.6.30 answers, mid-save:
#
#     Error: Cannot create file "<folder>/<stem>_tidy.csv".
#     Not-so-useful hint: unexpected error 30.
#
# Praat's own words. The script stops inside @emlSavePanel exactly as the
# slash case does, and takes the receipt, the panel's return, and the
# caller's post-analysis loop with it. Reproduced at HEAD on a read-only
# tmpfs, 15 Aug 2026. A folder that does not exist under an unwritable parent
# fails one line EARLIER, on the panel's own `createFolder:` -- "Cannot create
# folder" -- so the guard has to cover the creation too, not just the write.
#
# WHY A PROBE FILE AND NOT A PREDICATE. Praat has no try/catch, and
# folderExists() answers about READING. The only honest question is whether a
# write lands, so one is performed and then removed. `nocheck` is what makes
# that safe: measured on 6.6.30, `nocheck writeFile:` on an unwritable path
# leaves the script running, and fileReadable() afterwards is the answer.
# The same prefix goes on createFolder:, which raises on its own.
#
# THE PROBE FILE CARRIES THE STAMP, so it cannot collide with a user's file
# and cannot survive as litter under a name anyone would keep.
#
# Arguments: .folder$ the target, .stamp$ the press's timestamp
# Outputs:   .ok (1 = a write landed and was cleaned up)
#            .reason$ (empty when .ok = 1)
# ────────────────────────────────────────────────────────────────────────────
procedure eml_saveFolderWritable: .folder$, .stamp$
    .ok = 0
    .reason$ = ""

    if .folder$ = ""
        .reason$ = "No folder was given."
        goto FOLDER_PROBE_DONE
    endif

    if not folderExists (.folder$)
        nocheck createFolder: .folder$
    endif
    if not folderExists (.folder$)
        .reason$ = "That folder does not exist and could not be created."
        goto FOLDER_PROBE_DONE
    endif

    .probe$ = .folder$ + "/eml_write_test_" + .stamp$ + ".tmp"
    nocheck deleteFile: .probe$
    nocheck writeFile: .probe$, "eml"
    if fileReadable (.probe$)
        .ok = 1
        nocheck deleteFile: .probe$
    else
        .reason$ = "That folder cannot be written to."
    endif

    label FOLDER_PROBE_DONE
endproc


# ────────────────────────────────────────────────────────────────────────────
# @eml_saveReceiptLines: .fileList$, .note$        (private)
# ────────────────────────────────────────────────────────────────────────────
# EVERY LINE THE "Saved" RECEIPT WILL DRAW, worked out before any of it is
# drawn. Sets .nLines and .line$ [1 .. .nLines].
#
# THE DEFECT THIS EXISTS FOR. `comment:` RESERVES the height of one line at
# layout time and DRAWS whatever string it is handed. The panel already knew
# half of that -- it split .fileList$ on newline$ so a multi-line string could
# not be painted over -- but a single line LONGER THAN THE DIALOG is wrapped
# by the toolkit into two or three drawn lines inside that one line's height,
# so each long path printed its tail over the path below it. Five independent
# sightings in the audit of 14 August 2026, one cause; its receipt shows three
# paths in five lines of overlapping ink.
#
# THE BUDGET IS 62 CHARACTERS, measured rather than chosen. A pause form was
# driven on 6.6.30 under Xvfb on 15 Aug 2026 with comments of 55 to 68
# characters and photographed: 65 draws on one line, 66 wraps. 62 is the width
# @emlErrorDialog already wraps its dialog text to, so the panel and the error
# surface break in the same place, and the three characters of margin cover a
# different font on macOS or Windows.
#
# A PATH HAS NO SPACES, so @emlWrapText hard-breaks it at exactly 62
# characters. That is deliberate: nothing is inserted and nothing is elided,
# so the drawn lines still concatenate back to the path the user can paste.
# §6 of the audit called the receipt's honest full-path listing worth
# preserving, and it is preserved rather than shortened.
#
# SEPARATED FROM THE DRAWING so it can be checked without a screen.
# Building the lines inside `beginPause` is what let this ship: the only way
# to see the fault was to photograph a dialog. harness/savepaths' guards drive
# calls this procedure directly and validate/v56_save_guards.R reads its
# output, so the line lengths are now a number in a file.
#
# Arguments:
#   .fileList$  newline-separated absolute paths, as @emlSavePanel builds it
#   .note$      an extra note to append after a blank line, or "" for none
# ────────────────────────────────────────────────────────────────────────────
procedure eml_saveReceiptLines: .fileList$, .note$
    .nLines = 0
    .rest$ = .fileList$
    while index (.rest$, newline$) > 0
        .nl = index (.rest$, newline$)
        .one$ = left$ (.rest$, .nl - 1)
        if .one$ <> ""
            @emlWrapText: .one$, 62
            for .wl from 1 to emlWrapText.nLines
                .nLines = .nLines + 1
                .line$ [.nLines] = emlWrapText.line$ [.wl]
            endfor
        endif
        .rest$ = right$ (.rest$, length (.rest$) - .nl)
    endwhile
    if .rest$ <> ""
        @emlWrapText: .rest$, 62
        for .wl from 1 to emlWrapText.nLines
            .nLines = .nLines + 1
            .line$ [.nLines] = emlWrapText.line$ [.wl]
        endfor
    endif

    # WHAT THE NAME BECAME, when it is not what was typed. The sanitiser is
    # silent by design -- see @eml_saveSafeBaseName -- but silent is not the
    # same as hidden, and the receipt is the panel's disclosure surface for
    # exactly this.
    if .note$ <> ""
        .nLines = .nLines + 1
        .line$ [.nLines] = ""
        @emlWrapText: .note$, 62
        for .wl from 1 to emlWrapText.nLines
            .nLines = .nLines + 1
            .line$ [.nLines] = emlWrapText.line$ [.wl]
        endfor
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# @emlSavePanel: .offerFigure, .stem$, .folder$
# ────────────────────────────────────────────────────────────────────────────
# ONE SAVE, ONE FOLDER, ONE NAME. Everything an analysis produces — the
# figure, the numbers, the report — written in a single action under a shared
# stem, so a study's outputs arrive as a set instead of three files the user
# has to keep together by hand.
#
# WHY A PANEL AND NOT THREE BUTTONS. Author ruling, 13 August 2026: the saves
# must be on the dialog, not hidden in a menu. Three separate buttons would
# satisfy that, and a panel does it better for a reason that is about the
# files rather than the widgets: before this, the figure, the CSV and the
# recorded script each remembered a DIFFERENT folder (config_lastPNGFolder$,
# config_lastCSVFolder$, and the record-save default) and each derived its own
# name. One analysis scattered its outputs across three places under three
# naming conventions. A single folder and stem is the fix, and that is only
# expressible if the three are chosen together.
#
# SAVING THE REPORT DID NOT EXIST AT ALL before this. The plugin tells users
# their results are in the Info window -- "The results are in the Info window;
# the CSV buffer for this test is empty" -- and gave them no way to keep it.
# @emlSaveInfoToFile has been in the tree since before the repo's own history
# and was called by nothing; it was also broken (a bare `info$`, fixed 13 Aug
# 2026), which is the proof it had never run.
#
# THE FIGURE BRANCH IS REACHED ONLY WHEN THE CALLER SAYS THERE IS ONE.
# .offerFigure = 1 comes from the graphs form, where a figure has just been
# drawn and the graphs layer is loaded; the stats wrappers pass 0, because at
# the end of an analysis there is nothing drawn yet. That gate is also what
# makes it safe for this stats-layer procedure to call @emlAssertFullViewport:
# the call sits inside the branch, and Praat only resolves a procedure name
# when the call actually executes. A stats-only script -- eml-lib-stats.praat
# without the graphs barrel -- can therefore still use this panel.
#
# Arguments:
#   .offerFigure  1 to offer the figure, 0 when nothing is drawn
#   .stem$        default file name, no extension
#   .folder$      default folder
# Outputs:
#   .cancelled    1 if the user backed out
#   .nWritten     how many files were written
#   .fileList$    newline-separated absolute paths
#   .folder$      the folder actually used (for the caller to remember)
#   .stem$        the stem actually used
# ────────────────────────────────────────────────────────────────────────────
procedure emlSavePanel: .offerFigure, .stem$, .folder$
    .cancelled = 0
    .nWritten = 0
    .fileList$ = ""

    # IS THERE ANYTHING TO EXPORT? Both halves count: a converted analysis
    # declares into the broom collectors, an unconverted one fills the legacy
    # buffer, and @emlExportResultFiles forks between them. Offering a CSV
    # tickbox with neither would lead only to "Nothing to Export".
    .haveCSV = 0
    if variableExists ("emlCSV_n")
        if emlCSV_n > 0
            .haveCSV = 1
        endif
    endif
    if variableExists ("emlResult_declared")
        if emlResult_declared = 1
            .haveCSV = 1
        endif
    endif

    # THE FIELD VARIABLE NAME LOWERCASES ONLY THE FIRST CHARACTER, and keeps
    # every other character's case: `boolean: "Figure PNG"` is read back as
    # figure_PNG, not figure_png. Got wrong on the first drive of this panel
    # (13 Aug 2026) -- Praat answered "Unknown variable: figure_png" and the
    # save silently did nothing, which is the failure a tickbox panel is most
    # able to hide.
    # A BASE NAME, NOT A FILE NAME. One press writes several files and they
    # are told apart by a suffix this procedure appends, so calling the field
    # "File name" described what the user typed and not what they got --
    # someone typing "results.csv" into it would have got results.csv_tidy.csv
    # and had no way to know why. The comment lines below say what the
    # suffixes are, because the panel is the only place the naming scheme is
    # ever visible.
    #
    # THE PROPOSED NAME CARRIES A TIMESTAMP, and there is exactly ONE call to
    # @emlFileStamp per press, here, before the dialog. Every file this save
    # writes takes its name from the field this seeds, so they all carry the
    # same stamp to the second -- which is the author's condition, 14 Aug 2026,
    # and the whole point of stamping rather than numbering. A stamp taken
    # per-file would put two different seconds on one analysis whenever a write
    # straddled a tick.
    #
    # The uniquing backstop still exists but it now runs ONCE on the stem (see
    # below), not once per file. A backstop that produces results_1 and
    # results_2 protects the files while losing which run is which; a stamped
    # default sorts chronologically in a file browser and is editable, because
    # it arrives in the field where a user who does not want it deletes it.
    @emlFileStamp
    .proposed$ = .stem$ + "_" + emlFileStamp.result$

    beginPause: "Save"
        comment: "Everything ticked is written to one folder, sharing one"
        comment: "base name. Each output adds its own suffix:"
        if .haveCSV = 1
            comment: "    _tidy.csv, _glance.csv — and _augment.csv,"
            comment: "    _posthoc_tidy.csv, _effectsize_tidy.csv when the"
            comment: "    analysis produces them"
        endif
        comment: "    _report.txt — the Info window"
        if .offerFigure = 1
            comment: "    .png — the figure, and _legend.png beside it when"
            comment: "    the legend was placed outside the frame"
        endif
        comment: ""
        if .offerFigure = 1
            boolean: "Figure PNG", 1
        endif
        if .haveCSV = 1
            boolean: "Results CSV", 1
        else
            comment: "(No results to export — this analysis produced no rows.)"
        endif
        boolean: "Report from the Info window", 1
        folder: "Folder", .folder$
        word: "Base name", .proposed$
    .clicked = endPause: "Cancel", "Save", 2, 1

    if .clicked = 1
        .cancelled = 1
        goto SAVE_PANEL_DONE
    endif

    .folder$ = folder$
    while endsWith (.folder$, "/")
        .folder$ = left$ (.folder$, length (.folder$) - 1)
    endwhile

    # THE FOLDER IS MADE, NOT ASSUMED. `folder:` is a freely editable text
    # view with a Browse button beside it, so the user can type a path that
    # does not exist yet -- and typing one is the natural thing to do when you
    # want this study's outputs in their own folder. Without this line the
    # save dies on the first writeFile: with Praat's own error, which reads
    # "Cannot create file <path>. Hint: this is a folder, not a file" and
    # names neither the real cause nor the folder.
    #
    # It also removes a race that made harness/savepaths flaky on 14 Aug 2026:
    # the folder and stem handed to the writer were correct on every run,
    # instrumented and read back, yet one leg in five failed at the first
    # write. createFolder: on an existing folder is a no-op, so this costs
    # nothing and closes both.
    # ── THE TARGET IS PROVED WRITABLE BEFORE ANYTHING IS WRITTEN ──────────
    #
    # `createFolder:` used to sit bare on this line, and it is the FIRST
    # thing in the panel that can raise: under an unwritable parent it
    # answers "Cannot create folder" and stops the script inside the
    # procedure, so the receipt never draws and the caller's
    # Done | Save | Draw | New loop never runs again. An existing folder that
    # cannot be written survives this line and kills the save one step later,
    # at the first writeFile:, with "unexpected error 30".
    #
    # Both are now one question asked once, with `nocheck` so the asking
    # cannot itself abort, and the panel RETURNS on a no. Returning is what
    # keeps the session: the caller's loop comes back round, the analysis is
    # still there, and the user presses Save again with a different folder.
    # .cancelled is the existing way to say "no files, no error" and it is
    # reused rather than joined by a second flag.
    @eml_saveFolderWritable: .folder$, emlFileStamp.result$
    if eml_saveFolderWritable.ok = 0
        beginPause: "Cannot save there"
            @emlWrapText: eml_saveFolderWritable.reason$, 62
            for .wl from 1 to emlWrapText.nLines
                comment: emlWrapText.line$ [.wl]
            endfor
            comment: ""
            @emlWrapText: .folder$, 62
            for .wl from 1 to emlWrapText.nLines
                comment: emlWrapText.line$ [.wl]
            endfor
            comment: ""
            @emlWrapText: "Nothing has been written. Press Save again and "
            ... + "choose a folder you can write to -- your analysis is "
            ... + "still here.", 62
            for .wl from 1 to emlWrapText.nLines
                comment: emlWrapText.line$ [.wl]
            endfor
        endPause: "OK", 1, 0
        .cancelled = 1
        goto SAVE_PANEL_DONE
    endif

    # base_name$, not file_name$ -- the field was renamed and Praat derives
    # the variable from the label, so the readback name moves with it. The
    # label's first character lowercases and every other character keeps its
    # case, which is the rule that made figure_PNG bite on 13 Aug 2026.
    .stem$ = base_name$
    if .stem$ = ""
        @emlFileStamp
        .stem$ = "eml_results_" + emlFileStamp.result$
    endif

    # ── THE TYPED NAME IS MADE INTO A FILE NAME, ONCE ─────────────────────
    #
    # BEFORE the collision walk below and before every write, so all the
    # names one press produces are derived from the same safe stem and the
    # one-stamp-one-name contract is untouched. `pre/post` used to reach
    # writeFile: verbatim and stop the session there.
    #
    # The empty-name substitution above runs FIRST and is not re-checked
    # after: its own value contains nothing to sanitise, and a name that
    # sanitises down to nothing (a user typing "///") is caught below.
    .typed$ = .stem$
    @eml_saveSafeBaseName: .typed$
    .stem$ = eml_saveSafeBaseName.result$
    .nameAdjusted = eml_saveSafeBaseName.changed
    if .stem$ = ""
        .stem$ = "eml_results_" + emlFileStamp.result$
        .nameAdjusted = 1
    endif

    # ── ONE COLLISION DECISION, MADE ONCE, BEFORE ANYTHING IS WRITTEN ──────
    #
    # AUTHOR RULING, 14 August 2026: every file saved in one press must carry
    # exactly the same stamp -- and by extension exactly the same base name.
    # That is not a preference, it is what makes the outputs of one analysis a
    # set rather than a pile.
    #
    # Before this block the panel had THREE DIFFERENT COLLISION BEHAVIOURS
    # inside one save, and they disagreed:
    #
    #   the figure   @emlGenerateUniquePath on the .png, giving <stem>_1.png
    #   the legend   @emlGenerateUniquePath again, independently
    #   the frames   @emlExportResultFiles uniques the BASE, <stem>_1_tidy.csv
    #   the report   no check at all -- it overwrote
    #
    # So a second save under a name already used produced <stem>_1.png beside
    # <stem>_1_tidy.csv beside a <stem>_report.txt that had just destroyed the
    # first run's report. Three names and a silent loss, from one press.
    #
    # The stamp makes a collision very unlikely and does not make it
    # impossible: two saves inside the same second collide, and so does any
    # user who deletes the stamp and reuses a name -- which the field exists to
    # let them do.
    #
    # SO THE STEM IS UNIQUED, NOT THE FILES. The candidate set is every name
    # the panel COULD write under this stem, tested whether or not its box is
    # ticked: a stem that is free only because the user happened to untick the
    # figure would give two different base names for the same analysis
    # depending on which boxes were pressed. Once a free stem is found nothing
    # downstream needs to check again -- @emlExportResultFiles' own probe
    # becomes a no-op because <stem>_tidy.csv is known not to exist.
    .try$ = .stem$
    .n = 0
    label STEM_FREE
    .taken = 0
    if fileReadable (.folder$ + "/" + .try$ + ".png")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + "_legend.png")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + "_tidy.csv")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + "_glance.csv")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + ".csv")
        .taken = 1
    endif
    if fileReadable (.folder$ + "/" + .try$ + "_report.txt")
        .taken = 1
    endif
    if .taken = 1
        .n = .n + 1
        .try$ = .stem$ + "_" + string$ (.n)
        goto STEM_FREE
    endif
    .stem$ = .try$

    # --- the figure -------------------------------------------------------
    if .offerFigure = 1
        if figure_PNG = 1
            # NO PER-FILE UNIQUING. The stem was made free above, against
            # every name this panel can write, so a check here could only
            # ever disagree with the one the frames and the report use --
            # which is how one press used to produce <stem>_1.png beside
            # <stem>_1_tidy.csv beside an overwritten <stem>_report.txt.
            .figPath$ = .folder$ + "/" + .stem$ + ".png"
            @emlAssertFullViewport
            if output_DPI = 1
                Save as 300-dpi PNG file: .figPath$
            else
                Save as 600-dpi PNG file: .figPath$
            endif
            .nWritten = .nWritten + 1
            .fileList$ = .fileList$ + .figPath$ + newline$

            # THE LEGEND IS A SECOND FILE when it was placed outside the
            # frame (D136) -- the figure is not complete without it, so it
            # goes wherever the figure goes and shares its stem.
            if variableExists ("emlLegendSepActive")
                if emlLegendSepActive = 1
                    .legPath$ = .folder$ + "/" + .stem$ + "_legend.png"
                    # The legend is saved by narrowing the viewport to the
                    # coordinates the draw stored, writing, and then putting
                    # the figure's extent back -- otherwise a second Save from
                    # this same dialog writes the legend again instead of the
                    # figure.
                    Select outer viewport: emlLegendSepX0, emlLegendSepX1,
                    ... emlLegendSepY0, emlLegendSepY1
                    if output_DPI = 1
                        Save as 300-dpi PNG file: .legPath$
                    else
                        Save as 600-dpi PNG file: .legPath$
                    endif
                    @emlAssertFullViewport
                    .nWritten = .nWritten + 1
                    .fileList$ = .fileList$ + .legPath$ + newline$
                endif
            endif
        endif
    endif

    # --- the numbers ------------------------------------------------------
    if .haveCSV = 1
        if results_CSV = 1
            @emlExportResultFiles: .folder$, .stem$
            .nWritten = .nWritten + emlExportResultFiles.nWritten
            .fileList$ = .fileList$ + emlExportResultFiles.fileList$
            if right$ (.fileList$, 1) <> newline$
                .fileList$ = .fileList$ + newline$
            endif
        endif
    endif

    # --- the report -------------------------------------------------------
    # info$ () is the WHOLE Info window, which is what the author asked for:
    # the window is append-only by design, so what it holds is the session's
    # transcript rather than one report, and that is the honest thing to keep.
    if report_from_the_Info_window = 1
        .txtPath$ = .folder$ + "/" + .stem$ + "_report.txt"
        @emlSaveInfoToFile: .txtPath$
        if emlSaveInfoToFile.success = 1
            .nWritten = .nWritten + 1
            .fileList$ = .fileList$ + emlSaveInfoToFile.actualPath$ + newline$
        endif
    endif

    # --- record it --------------------------------------------------------
    # THE SAVE IS PART OF THE WORKFLOW, so a recorded script that leaves it
    # out reproduces a screen rather than a study. The folder is emitted as a
    # VARIABLE so the script survives being sent to a colleague -- the same
    # reasoning that made emlRecordPluginRoot$ home-relative.
    if .nWritten > 0
        if variableExists ("emlRecordLoaded")
            @emlRecordStep: "save",
            ... "Save the outputs of this analysis",
            ... "Every output shares one folder and one name, so they stay a set.",
            ... "outputFolder$ = " + """" + .folder$ + """" + newline$
            ... + "@emlSavePanel: " + string$ (.offerFigure) + ", "
            ... + """" + .stem$ + """, outputFolder$",
            ... "In the GUI: the Save button on the post-analysis or post-draw dialog."
        endif
    endif

    # --- say what happened ------------------------------------------------
    if .nWritten > 0
        # THE RECEIPT'S LINES ARE BUILT BEFORE THEY ARE DRAWN, by
        # @eml_saveReceiptLines, so that the thing that decides how many lines
        # there are can be driven without a screen. Building and drawing in
        # one loop is what let the overprint ship: the only way to see it was
        # to photograph a dialog, and nothing photographs dialogs on the way
        # to a commit.
        .adjustedNote$ = ""
        if .nameAdjusted = 1
            .adjustedNote$ = "The base name was adjusted to """ + .stem$
            ... + """ -- a file name cannot contain / \ : * ? "" < > |."
        endif
        @eml_saveReceiptLines: .fileList$, .adjustedNote$
        beginPause: "Saved"
            comment: "Wrote " + string$ (.nWritten) + " file(s):"
            for .rl from 1 to eml_saveReceiptLines.nLines
                comment: eml_saveReceiptLines.line$ [.rl]
            endfor
        endPause: "OK", 1, 0
    else
        beginPause: "Nothing saved"
            comment: "Nothing was ticked, so nothing was written."
        endPause: "OK", 1, 0
    endif

    label SAVE_PANEL_DONE
endproc

# ────────────────────────────────────────────────────────────────────────────
# @emlWrapperExportCSV -- RETIRED 14 August 2026 by author ruling, and deleted
# here. It was the shared CSV export dialog behind the stats wrappers' and the
# wizard's "CSV" button: numbers only, its own folder memory, its own naming.
# @emlSavePanel superseded it at every one of those call sites on 13 Aug 2026.
#
# THE ONE FACT WORTH KEEPING. Its first lines were the only thing that ever
# seeded emlLastCSVFolder$, and when the panel took the call sites the seed
# went with it -- it lived INSIDE the procedure being superseded. Praat
# evaluates a procedure's arguments before entering it, so every
# `@emlSavePanel: ..., emlLastCSVFolder$` died on "Unknown variable" BEFORE
# the panel ran: all nine non-graphing Save buttons of that day, on the first
# press of Save in a session. The seed now lives at file scope above
# @emlSavePanel ("THE PANEL'S REMEMBERED FOLDER, SEEDED AT LOAD"). Keep it at
# file scope; folding it back inside a procedure reproduces the outage.
# ────────────────────────────────────────────────────────────────────────────


# ============================================================================
# WIZARD EXPLANATION HELPERS
# ============================================================================
# Value-anchored interpretation generators for wizard mode third column.
# Each procedure sets emlWizardExplain$ which is consumed by the next
# @emlReportLine or @emlReportLineString call.
# ============================================================================

procedure emlWizardExplainP: .p
    # Generate p-value interpretation anchored to actual value
    if .p < 0.001
        emlWizardExplain$ = "Statistically significant: <0.1% probability due to chance"
    elsif .p < 0.01
        emlWizardExplain$ = "Statistically significant: <1% probability due to chance"
    elsif .p < 0.05
        emlWizardExplain$ = "Statistically significant at the 5% level"
    elsif .p < 0.10
        emlWizardExplain$ = "Approaching significance (p < .10) — interpret with caution"
    else
        emlWizardExplain$ = "Not statistically significant at the 5% level"
    endif
endproc

procedure emlWizardExplainEffectD: .d
    # Cohen's d interpretation
    .absD = abs (.d)
    if .absD < 0.2
        .mag$ = "negligible"
    elsif .absD < 0.5
        .mag$ = "small"
    elsif .absD < 0.8
        .mag$ = "medium"
    else
        .mag$ = "large"
    endif
    emlWizardExplain$ = "Effect size: " + .mag$ + " (>0.8 = large). Groups differ by "
    ... + fixed$ (.absD, 1) + " pooled standard deviations"
endproc

procedure emlWizardExplainEffectG: .g
    # Hedges' g interpretation (bias-corrected Cohen's d)
    .absG = abs (.g)
    if .absG < 0.2
        .mag$ = "negligible"
    elsif .absG < 0.5
        .mag$ = "small"
    elsif .absG < 0.8
        .mag$ = "medium"
    else
        .mag$ = "large"
    endif
    emlWizardExplain$ = "Bias-corrected d (better for small samples). "
    ... + .mag$ + " effect"
endproc

procedure emlWizardExplainEffectR: .r
    # Rank-biserial r or matched-pairs r interpretation
    .absR = abs (.r)
    if .absR < 0.1
        .mag$ = "negligible"
    elsif .absR < 0.3
        .mag$ = "small"
    elsif .absR < 0.5
        .mag$ = "medium"
    else
        .mag$ = "large"
    endif
    emlWizardExplain$ = "Effect size: " + .mag$ + " (>0.5 = large). Rank-biserial correlation"
endproc

procedure emlWizardExplainEffectEta2: .eta2
    # Eta-squared interpretation
    if .eta2 < 0.01
        .mag$ = "negligible"
    elsif .eta2 < 0.06
        .mag$ = "small"
    elsif .eta2 < 0.14
        .mag$ = "medium"
    else
        .mag$ = "large"
    endif
    .pct = .eta2 * 100
    emlWizardExplain$ = "Effect size: " + .mag$ + " (>0.14 = large). "
    ... + fixed$ (.pct, 0) + "% of variance explained by group membership"
endproc

procedure emlWizardExplainCorrelation: .r
    # Pearson/Spearman correlation strength
    .absR = abs (.r)
    if .absR < 0.1
        .str$ = "Negligible"
    elsif .absR < 0.3
        .str$ = "Weak"
    elsif .absR < 0.5
        .str$ = "Moderate"
    elsif .absR < 0.7
        .str$ = "Strong"
    else
        .str$ = "Very strong"
    endif
    if .r >= 0
        .dir$ = "positive"
    else
        .dir$ = "negative"
    endif
    emlWizardExplain$ = .str$ + " " + .dir$ + " relationship (range: -1 to 1)"
endproc

procedure emlWizardExplainR2: .r2
    # R-squared interpretation
    .pct = .r2 * 100
    emlWizardExplain$ = fixed$ (.pct, 0) + "% of variance in Y is explained by X"
endproc

procedure emlWizardExplainT: .t
    # t-statistic interpretation (signal-to-noise)
    .absT = abs (.t)
    emlWizardExplain$ = "Signal-to-noise: " + fixed$ (.absT, 1)
    ... + "x larger than expected from sampling noise"
endproc

procedure emlWizardExplainF: .f
    # F-statistic interpretation
    emlWizardExplain$ = "Ratio of between-group to within-group variance: groups differ "
    ... + fixed$ (.f, 1) + "x more than expected by chance"
endproc

procedure emlWizardExplainDfBetween: .df, .nGroups
    # df (between) for ANOVA
    emlWizardExplain$ = "Number of groups (" + string$ (.nGroups)
    ... + ") minus 1. Counts independent group comparisons."
endproc

procedure emlWizardExplainDfWithin: .df, .nTotal, .nGroups
    # df (within) for ANOVA
    emlWizardExplain$ = "Total observations (" + string$ (.nTotal)
    ... + ") minus groups (" + string$ (.nGroups)
    ... + "). Within-group evidence for estimating noise."
endproc

procedure emlWizardExplainDfTTest: .df, .method$
    # df for t-test
    if .method$ = "Welch"
        emlWizardExplain$ = "Welch-adjusted for unequal variances. More df = more reliable."
    else
        emlWizardExplain$ = "N minus 2. Controls how much evidence the test has."
    endif
endproc

procedure emlWizardExplainDfPaired: .df, .nPairs
    # df for paired t-test
    emlWizardExplain$ = "Number of pairs (" + string$ (.nPairs)
    ... + ") minus 1. Independent difference scores."
endproc

procedure emlWizardExplainDfCorrelation: .df, .n
    # df for correlation
    emlWizardExplain$ = "Observations (" + string$ (.n)
    ... + ") minus 2. Two parameters (slope, intercept) estimated."
endproc

procedure emlWizardExplainNormW: .w
    # Shapiro-Wilk W interpretation
    emlWizardExplain$ = "Closer to 1 = more normal (range: 0 to 1)"
endproc

procedure emlWizardExplainSkewness: .skew
    .absSkew = abs (.skew)
    if .absSkew < 0.5
        .desc$ = "Approximately symmetric"
    elsif .absSkew < 1
        if .skew > 0
            .desc$ = "Slight right skew"
        else
            .desc$ = "Slight left skew"
        endif
    else
        if .skew > 0
            .desc$ = "Substantial right skew"
        else
            .desc$ = "Substantial left skew"
        endif
    endif
    emlWizardExplain$ = .desc$ + " (|skew| < "
    ... + fixed$ (emlSkewThreshold, 0) + " is typically acceptable)"
endproc

procedure emlWizardExplainKurtosis: .kurt
    # @emlKurtosis already returns EXCESS kurtosis (normal = 0, verified vs
    # scipy bias=False). Do NOT subtract 3 again — that double-correction
    # labelled normal data (excess ~ 0) as excess ~ -3 => "platykurtic". (M1)
    .excess = .kurt
    if abs (.excess) < emlKurtosisThreshold
        .desc$ = "Near-normal peakedness"
    elsif .excess > 0
        .desc$ = "Heavy-tailed (leptokurtic)"
    else
        .desc$ = "Light-tailed (platykurtic)"
    endif
    emlWizardExplain$ = .desc$ + " (0 = normal; |excess| < "
    ... + fixed$ (emlKurtosisThreshold, 0) + " treated as typical)"
endproc


# ============================================================================
# ERROR PRESENTATION  (finding D93)
# ============================================================================
# An analysis that cannot run is not a crash and must not be presented as
# one. Two things were wrong before 5 August 2026.
#
#   1. The twelve menu wrappers showed the raw error string in a bare
#      @pauseScript, whose only button is Continue. The user was returned to
#      the entry form for a test the error had just told them was the wrong
#      test — and that form's only other button is Quit.
#
#   2. The Stats Wizard was worse: every analysis error called @exitScript,
#      which tore down the whole wizard including every answer the user had
#      given on the way in.
#
# The author's ruling of 5 August 2026 fixes each path in the way that suits
# it, and explicitly does NOT restructure how a test is chosen from the menu:
#
#   * Wizard path — the wizard owns a full goto/label back-chain, so an
#     error returns the user into that chain rather than ending the script.
#   * Menu path — the menu selection IS the navigation, and a running script
#     cannot reopen a Praat menu. So the dialog cannot offer to take the
#     user to another tool; what it can do is say plainly that a different
#     tool is needed, name it, and give the menu path to reach it.
# ============================================================================


# ────────────────────────────────────────────────────────────────────────────
# @emlWrapText: .s$, .width
#
# Greedy word wrap. Written for @emlErrorDialog: Praat's `comment:` field in a
# pause dialog does not wrap, and orchestrator error strings run well past any
# sensible dialog width, so they are broken up here. (This used to be written
# "@comment:", which reads as a procedure call in this file's own notation and
# is not one — `comment:` is a Praat dialog command, not an EML procedure.)
#
# It is no longer only the dialog's. @emlReportNote wraps to the report's
# 68-column body through this, and since D124 @emlDrawAnnotationBlock
# (graphs/eml-annotation-procedures.praat) wraps annotation lines through it
# to a character budget converted from the plotting frame. So .width is a
# CHARACTER count and every caller owns the conversion from whatever units it
# actually cares about; do not add a unit assumption here.
#
# Sets: .nLines, .line$ [1 .. .nLines]
# ────────────────────────────────────────────────────────────────────────────
procedure emlWrapText: .s$, .width
    .nLines = 0
    .rest$ = .s$
    while length (.rest$) > 0
        if length (.rest$) <= .width
            .nLines += 1
            .line$ [.nLines] = .rest$
            .rest$ = ""
        else
            # Last space at or immediately after the width limit. Breaking at
            # .width + 1 is correct: a space in that position means the word
            # ends exactly on the limit.
            .cut = 0
            for .i from 1 to .width + 1
                if mid$ (.rest$, .i, 1) = " "
                    .cut = .i
                endif
            endfor
            if .cut = 0
                # A single token longer than the line. Hard-break it rather
                # than emit an over-long line: column names can be arbitrary.
                .nLines += 1
                .line$ [.nLines] = left$ (.rest$, .width)
                .rest$ = mid$ (.rest$, .width + 1, length (.rest$))
            else
                .nLines += 1
                .line$ [.nLines] = left$ (.rest$, .cut - 1)
                .rest$ = mid$ (.rest$, .cut + 1, length (.rest$))
            endif
        endif
    endwhile
    if .nLines = 0
        .nLines = 1
        .line$ [1] = ""
    endif
endproc


# ────────────────────────────────────────────────────────────────────────────
# @emlReportNote: .s$
#
# Wrap a note to the report's 68-column body width and print it indented, in
# the two-space report frame. This is the pattern every caller of
# @emlWrapText was writing out by hand -- wrap, then loop over .line$ [] with
# a literal "  " -- so the loop lives here once instead of at each site.
#
# @emlWrapText itself stays public: a caller that needs a different width, or
# the lines without printing them, still uses it directly.
# ────────────────────────────────────────────────────────────────────────────
procedure emlReportNote: .s$
    @emlWrapText: .s$, 68
    for .nl from 1 to emlWrapText.nLines
        appendInfoLine: "  ", emlWrapText.line$ [.nl]
    endfor
endproc


# ────────────────────────────────────────────────────────────────────────────
# @emlErrorDialog: .msg$, .remedy$, .mode$
#
# The single error surface for both entry paths, and since 15 August 2026 for
# the refusals that happen BEFORE either path has a form to return to.
#
# Parameters:
#   .msg$    — the orchestrator's error string, shown verbatim and wrapped.
#   .remedy$ — the exact "New > EML Tools >" item that WOULD work on this
#              table, or "" when no other tool would help (a data problem
#              rather than a wrong-test problem). The distinction matters:
#              telling someone to re-navigate the menu when all they need is
#              a different column selection is worse than saying nothing.
#              Several items may be offered, separated by "|", for the case
#              where the parametric and nonparametric routes are both open;
#              naming only one of them would quietly steer the choice.
#   .mode$   — "wizard", "menu" or "entry". Chooses the guidance and the
#              button that is not Quit, because the three cases can offer
#              genuinely different things.
#
# Returns:
#   .back — 1 if the user chose to continue, 0 if they chose Quit. Always 0
#           in "entry" mode, which has nothing to go back to.
#
# Callers must honour .back = 0 by ending cleanly. The dialog itself never
# calls @exitScript; deciding to stop is the caller's job, because only the
# caller knows what needs tearing down.
#
# ────────────────────────────────────────────────────────────────────────────
# "entry" MODE, AND THE SENTENCE THAT MADE IT NECESSARY (15 August 2026)
# ────────────────────────────────────────────────────────────────────────────
# The refusals a wrapper makes BEFORE its dialog opens — the wrong selection,
# a table with too few columns, a table with no numeric column at all — were
# raw `exitScript: "..."`, which Praat presents as its OWN error window with
#
#     Script exited. Script ... not completed.
#     Command ... not executed.
#
# underneath: interpreter stack in place of a refusal this plugin has a
# dialog for, and the one moment a new user is most likely to be wrong about
# what to select is the moment they get the least help.
#
# THEY COULD NOT SIMPLY BE POINTED AT "menu" MODE. With an empty remedy that
# branch ends
#
#     "If a different test is needed, click Quit, then pick it from the
#      Objects window under New > EML Tools >"
#
# which is right for a test that ran and could not fit the data, and wrong
# for a refusal about the SELECTION: no different test would help, because
# no test has been reached. It also offers Back — and there is nothing behind
# it. The mode exists so the remedy-aware wording can be added without
# touching the two branches that are already correct for their own cases;
# rewording the shared empty-remedy branch would have made it vaguer for the
# path it was written for in order to serve a path it was never written for.
#
# It carries ONE button, because there is exactly one thing to do: read it,
# close it, fix the selection, run the command again. A running Praat script
# cannot change the object selection on the user's behalf, and offering a
# Back that can only re-refuse is worse than offering nothing.
# ────────────────────────────────────────────────────────────────────────────
procedure emlErrorDialog: .msg$, .remedy$, .mode$
    # Split the remedy on "|" up front: it is needed in two places below and
    # form-building code should not be doing string surgery inline.
    .nRemedy = 0
    .rest$ = .remedy$
    while .rest$ <> ""
        .bar = index (.rest$, "|")
        .nRemedy += 1
        if .bar = 0
            .remLine$ [.nRemedy] = .rest$
            .rest$ = ""
        else
            .remLine$ [.nRemedy] = left$ (.rest$, .bar - 1)
            .rest$ = mid$ (.rest$, .bar + 1, length (.rest$))
        endif
    endwhile

    # The title and the headline are computed rather than literal, because an
    # entry refusal is not an analysis that did not run — nothing has been
    # asked of the data yet, and a window headed "Cannot run this analysis"
    # over the sentence "Please select exactly one Table" tells the user the
    # analysis failed when what happened is that it never started.
    .title$ = "Cannot run this analysis"
    .headline$ = "⚠  This analysis did not run."
    if .mode$ = "entry"
        .title$ = "Cannot start this tool"
        .headline$ = "⚠  This tool did not start."
    endif

    beginPause: .title$
        comment: .headline$
        comment: "─────────────────────────────────────────────────"
        @emlWrapText: .msg$, 62
        for .i from 1 to emlWrapText.nLines
            comment: emlWrapText.line$ [.i]
        endfor
        comment: "─────────────────────────────────────────────────"
        comment: ""

        if .mode$ = "entry"
            # REMEDY-AWARE, AND THE REMEDY HERE IS ABOUT THE OBJECT LIST, not
            # about which test to run. The remedy string on this mode names
            # what to select — not a menu entry — so the sentence that follows
            # it says "select", not "pick another test".
            comment: "Nothing has been changed."
            if .nRemedy > 0
                comment: ""
                if .nRemedy = 1
                    comment: "What this tool needs:"
                else
                    comment: "What this tool needs — either of:"
                endif
                for .i from 1 to .nRemedy
                    comment: "        " + .remLine$ [.i]
                endfor
                comment: ""
                comment: "Click OK, select that in the Objects window, then"
                comment: "run this command again."
            else
                comment: ""
                comment: "Click OK, adjust the selection in the Objects"
                comment: "window, then run this command again."
            endif

        elsif .mode$ = "wizard"
            comment: "Nothing has been lost. Click Back to return to the"
            comment: "wizard and choose again."
            if .nRemedy > 0
                comment: ""
                if .nRemedy = 1
                    comment: "What fits this table:"
                else
                    comment: "What fits this table — either of:"
                endif
                for .i from 1 to .nRemedy
                    comment: "        " + .remLine$ [.i]
                endfor
            endif

        else
            if .nRemedy > 0
                if .nRemedy = 1
                    comment: "This table needs a different test. The one that"
                    comment: "fits it is:"
                else
                    comment: "This table needs a different test. Either of"
                    comment: "these fits it:"
                endif
                comment: ""
                for .i from 1 to .nRemedy
                    comment: "        " + .remLine$ [.i]
                endfor
                comment: ""
                comment: "A running script cannot open a Praat menu, so this"
                comment: "dialog cannot take you there. To switch tests:"
                comment: ""
                comment: "        1.  Click Quit below."
                comment: "        2.  In the Objects window choose"
                comment: "             New  >  EML Tools  >  and then the"
                comment: "             entry named above."
                comment: ""
                comment: "Or click Back to change your column choices and try"
                comment: "this test again."
            else
                comment: "Your selections are kept. Click Back to adjust them"
                comment: "and run again."
                comment: ""
                comment: "If a different test is needed, click Quit, then pick"
                comment: "it from the Objects window under"
                comment: "             New  >  EML Tools  >"
            endif
        endif
    # ONE BUTTON ON THE ENTRY REFUSAL. There is nothing behind it to go back
    # to — the wrapper has not built a form yet — and a Back that can only
    # re-refuse is a loop with no exit that is not Quit.
    if .mode$ = "entry"
        .clicked = endPause: "OK", 1, 0
        .back = 0
    else
        .clicked = endPause: "Quit", "Back", 2, 0
        .back = (.clicked = 2)
    endif
endproc


# ============================================================================
# END OF ERROR PRESENTATION
# ============================================================================
# (This banner read "END OF MODULE" and had one procedure after it, which is
# a section pointer that contradicts the file under it. The module ends at
# the bottom of @emlReportDescriptiveAnalysis, below.)


# ============================================================================
# @emlReportDescriptiveAnalysis
#
# Lives here, in the output module, and not in eml-analysis.praat, because
# scripts/eml-describe-table.praat calls it and includes only
# eml-lib-stats.praat, which does not pull in the analysis module. (The other
# caller, @emlRunDescriptiveAnalysis in eml-analysis.praat, gets it either
# way.) Moving it here was forced by driving the wrapper: the parse check
# passed and the menu item raised "Procedure not found" the moment Run was
# clicked, because Praat resolves a procedure name when it is CALLED, not
# when the script is parsed. The error's line number is no use as a citation
# — it counts lines in the flattened script, after every `include` has been
# pasted in, so it names no line of any file on disk. harness/check_includes.py
# was written after this to find the class statically; the note above
# @emlRunLMMAnalysis's old home in eml-analysis.praat describes the same trap.
# A reporting procedure belongs with the reporting procedures anyway.
# ============================================================================

procedure emlReportDescriptiveAnalysis: .tableName$, .dataCol$, .nValid,
... .nUndefined, .parseNote$
    .displayColumn$ = replace$ (.dataCol$, "_", " ", 0)
    .displayTable$ = replace$ (.tableName$, "_", " ", 0)

    @emlReportHeader: "Descriptive Statistics"

    @emlReportLineString: "Table", .displayTable$
    @emlReportLineString: "Column", .displayColumn$
    @emlReportLine: "N (valid)", .nValid, 0
    if .nUndefined > 0
        @emlReportLine: "N (excluded)", .nUndefined, 0
        if .parseNote$ <> ""
            @emlWrapText: .parseNote$, 62
            for .pl from 1 to emlWrapText.nLines
                appendInfoLine: "  ", emlWrapText.line$ [.pl]
            endfor
        endif
    endif

    @emlReportBlank
    @emlReportSection: "Central Tendency"
    @emlReportLine: "Mean", emlDescribe.mean, 4
    @emlReportLine: "Median", emlDescribe.median, 4
    @emlReportLine: "SEM", emlDescribe.sem, 4

    @emlReportBlank
    @emlReportSection: "Dispersion"
    @emlReportLine: "SD", emlDescribe.sd, 4
    @emlReportLine: "Variance", emlDescribe.variance, 4
    @emlReportLine: "Range", emlDescribe.range, 4
    @emlReportLine: "Min", emlDescribe.min, 4
    @emlReportLine: "Max", emlDescribe.max, 4

    @emlReportBlank
    @emlReportSection: "Quartiles"
    @emlReportLine: "Q1", emlDescribe.q1, 4
    @emlReportLine: "Q2 (Median)", emlDescribe.median, 4
    @emlReportLine: "Q3", emlDescribe.q3, 4
    @emlReportLine: "IQR", emlDescribe.iqr, 4

    @emlReportBlank
    @emlReportSection: "Distribution Shape"
    @emlReportLine: "Skewness", emlDescribe.skewness, 4
    @emlReportLine: "Kurtosis (excess)", emlDescribe.kurtosis, 4

    @emlReportBlank
    @emlReportSection: "95% Confidence Interval"
    @emlReportLine: "Lower", emlDescribe.ci95Lower, 4
    @emlReportLine: "Upper", emlDescribe.ci95Upper, 4

    @emlReportFooter
endproc
