# ============================================================================
# evidence/redrive/kit_cleandata_named_doors.praat — drive the level-1 and
# level-2 data-cleaning fixtures for the four named doors (two-group, ANOVA,
# correlation, regression), producing one capture per case under
# evidence/info/kit_cleandata_{l1,l2}_{door}_info.txt.
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# BUILT 8 September 2026 for the data-cleaning wave
# (RULING_DATA_CLEANING_POLICY / RULING_DATA_CLEANING_TWO_ITEMS). Each door
# gets two inputs:
#
#   kit_cleandata_l1_<door>_input.csv — one cell with a single decimal comma
#     (e.g. "12,5"), the ONLY comma in its column, so @emlCommaColumnMode
#     reads it unambiguously as mode 1 and @eml_cleanVerdict repairs it on
#     the fly. LEVEL 1: the row is analysed, not dropped.
#
#   kit_cleandata_l2_<door>_input.csv — the identical table with that one
#     cell replaced by "??", which is not a number in any locale. LEVEL 2:
#     the row is excluded under the existing complete-case convention, and
#     the orchestrator's own exclusion note names the count.
#
# Each orchestrator procedure is called directly (none of the four uses
# beginPause:, so this runs under `praat --run` with no X server), which is
# the same approach evidence/redrive/rp_r6_describe.praat and
# evidence/redrive/rp_r6_parse_conditions.praat use for the descriptive door.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-psychometrics.praat
include ../../plugin/stats/eml-studentized-range.praat
include ../../plugin/stats/eml-anova-kernel.praat
include ../../plugin/stats/eml-wilcoxon-interval.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-categorical.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/stats/eml-analysis.praat

Text writing preferences: "UTF-8"
emlShowExplanations = 0
emlWizardExplain$ = ""

procedure driveOne: .csv$, .out$, .kind$
    writeInfo: ""
    t = Read Table from comma-separated file: .csv$
    if .kind$ = "twogroup"
        @emlRunTwoGroupAnalysis: t, "value", "group", "both", 0
    elsif .kind$ = "anova"
        @emlRunAnovaAnalysis: t, "value", "group", 1
    elsif .kind$ = "correlation"
        @emlRunCorrelationAnalysis: t, "x", "y", "both"
    elsif .kind$ = "regression"
        @emlRunRegressionAnalysis: t, "dep", "pred"
    endif
    text$ = info$ ()
    if left$ (text$, 1) = newline$
        text$ = right$ (text$, length (text$) - 1)
    endif
    writeFile: .out$, text$
    removeObject: t
endproc

@driveOne: "../csv/kit_cleandata_l1_twogroup_input.csv",
... "../info/kit_cleandata_l1_twogroup_info.txt", "twogroup"
@driveOne: "../csv/kit_cleandata_l2_twogroup_input.csv",
... "../info/kit_cleandata_l2_twogroup_info.txt", "twogroup"

@driveOne: "../csv/kit_cleandata_l1_anova_input.csv",
... "../info/kit_cleandata_l1_anova_info.txt", "anova"
@driveOne: "../csv/kit_cleandata_l2_anova_input.csv",
... "../info/kit_cleandata_l2_anova_info.txt", "anova"

@driveOne: "../csv/kit_cleandata_l1_correlation_input.csv",
... "../info/kit_cleandata_l1_correlation_info.txt", "correlation"
@driveOne: "../csv/kit_cleandata_l2_correlation_input.csv",
... "../info/kit_cleandata_l2_correlation_info.txt", "correlation"

@driveOne: "../csv/kit_cleandata_l1_regression_input.csv",
... "../info/kit_cleandata_l1_regression_info.txt", "regression"
@driveOne: "../csv/kit_cleandata_l2_regression_input.csv",
... "../info/kit_cleandata_l2_regression_info.txt", "regression"

appendInfoLine: "kit_cleandata_named_doors: done"
