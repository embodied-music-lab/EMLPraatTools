# ============================================================================
# EML Stats : Output Formatting
# ============================================================================
# Module: eml-output.praat
# Version: 2.2
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
# Provides: 55 procedures. THE COUNTING RULE, so the number can be checked
# rather than believed:
#     grep -c "^procedure " plugin/stats/eml-output.praat
# Two of the 55 are private and are named with an underscore after the prefix
# (@eml_csvQuote, @eml_csvAppend); the other 53 are public. By family:
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
#     @emlCSVAddStr, @emlCSVAddDescriptives, @emlExportStatsCSV
#     (this list read "@emlCSVAddRow" until 8 Aug 2026. No such procedure has
#     ever existed anywhere in the plugin —
#     grep -rn "^procedure emlCSVAddRow" plugin/ returns nothing — although
#     the notes under audit/ name it fourteen times, having taken it from
#     here. The export is LONG format: emlCSV_header$ is
#     "table,analysis,term,term_type,field,value", and @emlCSVAdd /
#     @emlCSVAddStr each append ONE such row, i.e. one field of one term.
#     There is no procedure that writes a whole analysis in one call, which
#     is what the name @emlCSVAddRow implied.)
#   Wrapper plumbing — @emlWrapperInit, @emlWrapperExportCSV,
#     @emlWrapperCommonFields, @emlHandleCommonFields
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

    emlCSV_n = 0
    emlCSV_table$ = ""
    emlCSV_termType$ = ""
    emlCSV_nDesc = 0
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
        .tableName$ = selected$ ("Table")
        .converted = 1
        appendInfoLine: "Converted TableOfReal """, .torName$,
        ... """ to Table. Row labels are in column ""row""."
        appendInfoLine: ""

    elsif .nTables = 0 and .nToR = 0 and .nMatrix = 1
        # Matrix selected — convert via TableOfReal → Table
        .matId = selected ("Matrix")
        .matName$ = selected$ ("Matrix")
        selectObject: .matId
        .tempTorId = To TableOfReal
        .tableId = To Table: "row"
        removeObject: .tempTorId
        .tableName$ = selected$ ("Table")
        .converted = 1
        # Check for column name collision with "row"
        selectObject: .tableId
        .checkNCols = Get number of columns
        for .iCheck from 2 to .checkNCols
            .checkLabel$ = Get column label: .iCheck
            if .checkLabel$ = "row"
                Rename column (by number): 1, "OriginalRowLabel"
                .iCheck = .checkNCols
            endif
        endfor
        appendInfoLine: "Converted Matrix """, .matName$,
        ... """ to Table."
        appendInfoLine: ""

    else
        exitScript: "Please select exactly one Table, TableOfReal, "
        ... + "or Matrix object, then run this script again."
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
        exitScript: "Table needs at least " + string$ (.minCols) + " columns."
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
# @emlWrapperExportCSV
# Presents CSV export dialog and saves via @emlExportStatsCSV.
# Call from the post-analysis loop when the user clicks "CSV".
#
# Parameters:
#   .tableName$ — used for default filename
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
    # THE PROPOSED NAME CARRIES A TIMESTAMP. @emlGenerateUniquePath still sits
    # behind every write as the backstop, but a backstop that produces
    # results_1 and results_2 protects the files while losing which run is
    # which. A stamped default cannot collide, sorts chronologically in a file
    # browser, and is editable -- it arrives in the field, so a user who does
    # not want it deletes it.
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
    createFolder: .folder$
    # base_name$, not file_name$ -- the field was renamed and Praat derives
    # the variable from the label, so the readback name moves with it. The
    # label's first character lowercases and every other character keeps its
    # case, which is the rule that made figure_PNG bite on 13 Aug 2026.
    .stem$ = base_name$
    if .stem$ = ""
        @emlFileStamp
        .stem$ = "eml_results_" + emlFileStamp.result$
    endif

    # --- the figure -------------------------------------------------------
    if .offerFigure = 1
        if figure_PNG = 1
            .figPath$ = .folder$ + "/" + .stem$ + ".png"
            if fileReadable (.figPath$)
                @emlGenerateUniquePath: .figPath$
                .figPath$ = emlGenerateUniquePath.result$
            endif
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
                    if fileReadable (.legPath$)
                        @emlGenerateUniquePath: .legPath$
                        .legPath$ = emlGenerateUniquePath.result$
                    endif
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
        beginPause: "Saved"
            comment: "Wrote " + string$ (.nWritten) + " file(s):"
            # ONE comment: PER LINE. `comment:` reserves the height of one
            # line at layout time but draws whatever string it is given, so a
            # string holding newline$ is painted over by the widgets below it.
            .rest$ = .fileList$
            while index (.rest$, newline$) > 0
                .nl = index (.rest$, newline$)
                .one$ = left$ (.rest$, .nl - 1)
                if .one$ <> ""
                    comment: .one$
                endif
                .rest$ = right$ (.rest$, length (.rest$) - .nl)
            endwhile
            if .rest$ <> ""
                comment: .rest$
            endif
        endPause: "OK", 1, 0
    else
        beginPause: "Nothing saved"
            comment: "Nothing was ticked, so nothing was written."
        endPause: "OK", 1, 0
    endif

    label SAVE_PANEL_DONE
endproc

# SUPERSEDED 13 AUG 2026 BY @emlSavePanel, and left in place rather than
# deleted so the decision is yours rather than mine. It has NO CALLERS: the
# nine wrapper CSV buttons and the wizard's now call the panel, which writes
# the report as well as the numbers and shares one folder and one stem across
# every output. Anything that called this again would get the old behaviour --
# numbers only, its own folder memory, its own naming -- which is the divergence
# the panel exists to end.
# ────────────────────────────────────────────────────────────────────────────
# @emlWrapperExportCSV: .tableName$, .analysis$
#
# D39: the folder defaulted to defaultDirectory$, which is the directory of
# the running script — inside the plugin tree. Saving there puts a user's
# results among the plugin's own files, where an update will overwrite or
# lose them. It now remembers the last folder used, seeded from the user's
# home directory, and remembers it across analyses within a session.
#
# D18/D65: the file name was .tableName$ + "_results" for every analysis, so
# two different tests on one table proposed the same name and the second
# silently overwrote the first. The analysis is now part of the proposal.
#
# D105. An earlier version of this comment claimed that "D18's other half —
# the paired wrapper passing its reshaped intermediate, so the name came out
# 'pairedLong_results' — is fixed at the call site." That was wrong twice
# over, and it is corrected here rather than deleted so the same claim is not
# made again:
#   1. The paired wrapper never passed the intermediate. It passes
#      tableName$, taken from @emlWrapperInit, which is the source table the
#      user selected (scripts/eml-compare-paired.praat). The reshaped
#      "pairedLong" Table it builds for the spaghetti plot is never given to
#      this procedure. There was nothing at that call site to fix.
#   2. The "pairedLong_results" default the auditor actually saw does not
#      come from this procedure at all. It comes from the graphs form, which
#      builds its own export default from selected$ ("Table") — whatever
#      Table happens to be selected at that moment, which after the reshape
#      is the intermediate. That is where D18 is live, and it is not fixed by
#      anything in this file.
# Nothing below handles that case. Do not read this procedure as covering it.
procedure emlWrapperExportCSV: .tableName$, .analysis$
    if not variableExists ("emlLastCSVFolder$")
        emlLastCSVFolder$ = homeDirectory$
    endif
    if emlLastCSVFolder$ = ""
        emlLastCSVFolder$ = homeDirectory$
    endif
    .slug$ = replace$ (.analysis$, " ", "_", 0)
    .slug$ = replace$ (.slug$, "/", "-", 0)
    .slug$ = replace$ (.slug$, "'", "", 0)
    .defaultName$ = .tableName$ + "_" + .slug$
    if .slug$ = ""
        .defaultName$ = .tableName$ + "_results"
    endif
    beginPause: "Export Results"
        folder: "Output folder", emlLastCSVFolder$
        word: "File name", .defaultName$
    .clicked = endPause: "Go Back", "Save", 2, 0
    if .clicked = 2
        emlLastCSVFolder$ = output_folder$

        ; ---------------------------------------------------------------
        ; MIGRATION FORK. A path that has been converted to the three-file
        ; broom shape declares its results into the tidy/glance/augment
        ; collectors; @emlResultBegin sets emlResult_declared. A path that
        ; has not still fills the single-file buffer.
        ;
        ; The fork is on the DECLARATION, not on a per-analysis list, so a
        ; path converts by declaring and nothing here has to be edited for
        ; each one. It also means a half-converted path -- declaring but
        ; producing no rows -- reports as an empty export rather than
        ; silently writing the legacy file, which is the failure mode that
        ; let the previous migration be recorded as done.
        ; ---------------------------------------------------------------
        ; THE WRITE ITSELF IS @emlExportResultFiles, shared with the graphs
        ; form's Exp CSV button. It used to be inline here, which is why that
        ; button could not reach it and wrote the legacy file for an analysis
        ; this one wrote three broom-shaped files for.
        @emlExportResultFiles: output_folder$, file_name$
        .nWritten = emlExportResultFiles.nWritten
        .fileList$ = emlExportResultFiles.fileList$
        .skipped$ = emlExportResultFiles.skipped$

        if emlExportResultFiles.declared = 1
            if .nWritten > 0
                beginPause: "Export Complete"
                    comment: "Wrote " + string$ (.nWritten) + " files:"
                    ; ONE comment: PER LINE, not one comment: holding several.
                    ;
                    ; `comment:` reserves the height of ONE line when the
                    ; dialog is laid out, but draws whatever string it is
                    ; given -- so a string containing newline$ overflows its
                    ; slot and the widgets below are painted over it. With
                    ; three files written, the OK button was drawn ON TOP of
                    ; the third path. Seen 11 Aug 2026 by exporting a CSV from
                    ; the menu under Xvfb and looking at the dialog; /root is
                    ; a short folder, and a real user path makes it worse.
                    ;
                    ; A loop is legal here. `form:` cannot contain one --
                    ; "Unknown parameter type inside form" -- but the lines
                    ; between beginPause: and endPause: are executed, which is
                    ; why every wrapper in this plugin uses beginPause:.
                    .listRest$ = .fileList$
                    while index (.listRest$, newline$) > 0
                        .nl = index (.listRest$, newline$)
                        .oneFile$ = left$ (.listRest$, .nl - 1)
                        if .oneFile$ <> ""
                            comment: .oneFile$
                        endif
                        .listRest$ = right$ (.listRest$,
                        ... length (.listRest$) - .nl)
                    endwhile
                    if .listRest$ <> ""
                        comment: .listRest$
                    endif
                endPause: "OK", 1, 0
            else
                beginPause: "Nothing to Export"
                    comment: "This analysis declared a result but produced"
                    comment: "no rows:"
                    comment: .skipped$
                    comment: "Please report this — it is a defect."
                endPause: "OK", 1, 0
            endif
            ; NOT cleared here, deliberately. Clearing after a successful
            ; export meant a SECOND press of CSV in the same analysis fell
            ; through to the legacy single-file path and silently wrote a
            ; different, older-format file. The declaration stays valid for as
            ; long as the analysis it describes is the current one, and
            ; @emlCSVInit -- which every orchestrator calls as its first
            ; statement -- is what makes that true.
            goto WRAPPER_EXPORT_DONE
        endif

        ; LEGACY ARM. @emlExportResultFiles already wrote it; these are only
        ; the dialogs, which differ between the two callers.
        if emlExportResultFiles.success
            beginPause: "Export Complete"
                comment: "Saved to: " + emlExportResultFiles.actualPath$
            endPause: "OK", 1, 0
        elsif emlExportResultFiles.reason$ = "empty"
            # D66: this is not a disk failure and must not read as one.
            beginPause: "Nothing to Export"
                comment: "This analysis produced no exportable rows."
                comment: ""
                comment: "The results are in the Info window; the CSV"
                comment: "buffer for this test is empty. Please report"
                comment: "this — it is a defect, not a setting."
            endPause: "OK", 1, 0
        else
            beginPause: "Export Failed"
                comment: "Could not write CSV file."
            endPause: "OK", 1, 0
        endif
    endif
    label WRAPPER_EXPORT_DONE
endproc


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
# The single error surface for both entry paths.
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
#   .mode$   — "wizard" or "menu". Chooses the guidance and the button that
#              is not Quit, because the two paths can offer genuinely
#              different things.
#
# Returns:
#   .back — 1 if the user chose to continue, 0 if they chose Quit.
#
# Callers must honour .back = 0 by ending cleanly. The dialog itself never
# calls @exitScript; deciding to stop is the caller's job, because only the
# caller knows what needs tearing down.
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

    beginPause: "Cannot run this analysis"
        comment: "⚠  This analysis did not run."
        comment: "─────────────────────────────────────────────────"
        @emlWrapText: .msg$, 62
        for .i from 1 to emlWrapText.nLines
            comment: emlWrapText.line$ [.i]
        endfor
        comment: "─────────────────────────────────────────────────"
        comment: ""

        if .mode$ = "wizard"
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
    .clicked = endPause: "Quit", "Back", 2, 0
    .back = (.clicked = 2)
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
