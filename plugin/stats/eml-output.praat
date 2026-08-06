# ============================================================================
# EML Stats : Output Formatting
# ============================================================================
# Module: eml-output.praat
# Version: 1.8
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
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# License: Creative Commons Share-Alike
#
# Provides: @emlReportHeader, @emlReportFooter, @emlReportSection,
#   @emlReportLine, @emlReportLineString, @emlReportBlank,
#   @emlFormatP, @emlFormatCI, @emlFormatTestResult,
#   @emlReportDescriptiveRow, @emlReportDescriptiveHeader,
#   @emlReportAPA, @emlReportToFile, @emlFormatEffectLabel,
#   @emlPadRight, @emlUnderscoreToSpace, @emlSaveInfoToFile,
#   @emlCSVInit, @emlCSVAddRow, @emlExportStatsCSV, @emlClearInfo,
#   @emlReportPWithExact, @emlResetExplanations
#
# All procedures use the "eml" prefix (EML Stats).
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


procedure emlReportHeader: .title$
    # Print report header with double-line borders and timestamp.
    # Always appends — never clears. Use @emlClearInfo for explicit clearing.
    .border$ = "══════════════════════════════════════════════"
    .indent$ = "  "
    .prefix$ = "EML Stats : "
    .titleLine$ = .indent$ + .prefix$ + .title$
    .timestamp$ = .indent$ + date$ ()
    .sep$ = ""
    appendInfoLine: .sep$
    appendInfoLine: .border$
    appendInfoLine: .titleLine$
    appendInfoLine: .timestamp$
    appendInfoLine: .border$
    .sep2$ = ""
    appendInfoLine: .sep2$
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
    # eta_squared, omega_squared: negligible < 0.01, small 0.01–0.06, medium 0.06–0.14, large >= 0.14
    # r_squared: negligible < 0.01, small 0.01–0.09, medium 0.09–0.25, large >= 0.25
    #   (Cohen 1988: R-squared benchmarks are the squares of the r benchmarks
    #    0.1 / 0.3 / 0.5, so d thresholds mislabel them badly — R-squared = 0.3
    #    is a large effect, not a small one.)

    .d$ = "d"
    .r$ = "r"
    .w$ = "w"
    .vUpper$ = "V"
    .eta$ = "eta_squared"
    .omega$ = "omega_squared"
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
    elsif .effectType$ = .eta$ or .effectType$ = .omega$ or .effectType$ = .eps$ or .effectType$ = .epsAlt$
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
    .content$ = info$
    
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
    if variableExists ("emlResult_extra1$")
        emlResult_extra1$ = ""
        emlResult_extra2$ = ""
        emlResult_extra1Text$ = ""
        emlResult_extra2Text$ = ""
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
# D18's other half — the paired wrapper passing its reshaped intermediate, so
# the name came out "pairedLong_results" — is fixed at the call site.
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
        if variableExists ("emlResult_declared") and emlResult_declared = 1
            @emlResultWrite: output_folder$, file_name$
            .nWritten = emlResultWrite.written
            .fileList$ = emlResultWrite.files$
            .skipped$ = emlResultWrite.skipped$

            ; Post-hoc and effect sizes are separate model objects in R and
            ; are separate files here. Written only if the analysis declared
            ; them, which it signals by leaving a non-empty extras name.
            if emlResult_extra1$ <> ""
                .p1$ = output_folder$ + "/" + file_name$ + "_"
                ... + emlResult_extra1$ + "_tidy.csv"
                writeFile: .p1$, emlResult_extra1Text$
                .nWritten = .nWritten + 1
                .fileList$ = .fileList$ + .p1$ + newline$
            endif
            if emlResult_extra2$ <> ""
                .p2$ = output_folder$ + "/" + file_name$ + "_"
                ... + emlResult_extra2$ + "_tidy.csv"
                writeFile: .p2$, emlResult_extra2Text$
                .nWritten = .nWritten + 1
                .fileList$ = .fileList$ + .p2$ + newline$
            endif

            if .nWritten > 0
                beginPause: "Export Complete"
                    comment: "Wrote " + string$ (.nWritten) + " files:"
                    comment: .fileList$
                endPause: "OK", 1, 0
            else
                beginPause: "Nothing to Export"
                    comment: "This analysis declared a result but produced"
                    comment: "no rows:"
                    comment: .skipped$
                    comment: "Please report this — it is a defect."
                endPause: "OK", 1, 0
            endif
            emlResult_declared = 0
            goto WRAPPER_EXPORT_DONE
        endif

        .csvPath$ = output_folder$ + "/" + file_name$ + ".csv"
        @emlExportStatsCSV: .csvPath$
        if emlExportStatsCSV.success
            beginPause: "Export Complete"
                comment: "Saved to: " + emlExportStatsCSV.actualPath$
            endPause: "OK", 1, 0
        elsif emlExportStatsCSV.reason$ = "empty"
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
# Greedy word wrap. @comment: does not wrap, and orchestrator error strings
# run well past any sensible dialog width, so they are broken up here.
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
# END OF MODULE
# ============================================================================


# ============================================================================
# @emlReportDescriptiveAnalysis
#
# Lives here, in the output module, and not in eml-analysis.praat, because
# scripts/eml-describe-table.praat calls it and does not include the analysis
# module. Moving it here was forced by driving the wrapper: the parse check
# passed and the menu item raised "Procedure not found" at line 9434 the
# moment Run was clicked. A reporting procedure belongs with the reporting
# procedures anyway.
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
