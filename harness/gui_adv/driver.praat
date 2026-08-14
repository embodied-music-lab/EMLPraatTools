# ---------------------------------------------------------------------------
# ADVANCED-MODE DRIVER. The same handover harness/gui_e2e makes, driven into
# ADVANCED mode by pressing the form's own toggle.
#
# WHAT THIS PROVES THAT READING CANNOT. Two fixes shipped on 13 August 2026
# resting on nothing but my having read the code:
#
#   1. THE ANNOTATION BRIDGE DECLARES. @emlReportBridgeStats opens with
#      @emlCSVInit, which zeroes emlResult_declared -- so it DESTROYS the
#      declaration this driver's own @emlRunTwoGroupAnalysis made, and must
#      then re-declare or the export writes the legacy single file instead of
#      broom frames. The observable is therefore the FILE SET on disk: tidy +
#      glance beside the figure means the bridge declared; one flat .csv means
#      it did not. Nothing else distinguishes them, which is why this needs a
#      drive and not a grep.
#
#      harness/gui_e2e cannot show this. It draws in BEGINNER mode, where the
#      commit forces annotate = 0, so the bridge never runs, @emlCSVInit is
#      never reached, and the driver's own declaration survives untouched --
#      the frames it writes prove the ORCHESTRATOR declared, not the bridge.
#
#   2. THE ANNOTATE PRESET SURVIVES. A wrapper preset never passes through the
#      advanced dialog, so there is no prev_adv_ state to restore, and before
#      13 Aug the request was simply lost: the beginner commit sets
#      annotate = 0, the preset is consumed once before the outer repeat, and
#      nothing wrote it to the stash. The restore branch added an elsif arm
#      reading emlGraphsPresetAnnotate. The observable is the TICKBOX on the
#      advanced dialog, so run.sh photographs it.
#
# WHY THE TOGGLE AND NOT THE CONFIG FILE. config_showAdvanced can be set by
# writing showAdvanced: 1 into eml-graphs-config.txt before launch, and
# harness/walks/gridmode does exactly that. That route would NOT exercise the
# preset restore: the elsif arm lives inside the handler that runs when the
# form toggles TO advanced. Pressing the toggle is both the real user journey
# and the only one that reaches the branch under test.
#
# Setting config_showAdvanced in this file does not work either -- @emlLoadConfig
# re-initialises it to 0 before parsing the file (eml-graphs-form.praat:746).
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
# THE SHIPPED BARREL'S SET, IN THE BARREL'S ORDER. eml-lib.praat cannot be
# included from here -- a relative path inside an included file resolves
# against the TOP-LEVEL script's folder, which is why every harness in this
# tree lists the files individually (eml-lib-stats.praat:13). So the list is
# kept in step with plugin/scripts/eml-lib-stats.praat and eml-lib-graphs.praat
# by hand, and the recorder is included because the shipped plugin includes
# it: a run without it is harness/norecord's job, not this one's.
include ../stress_cases/_prelude.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graphs-form.praat

outDir$ = environment$ ("EML_ADV_OUT")
if outDir$ = ""
    outDir$ = "."
endif

# A table with the shape a two-group comparison produces, and a value column
# whose auto-derived label carries a "%" -- the character that used to vanish
# from the title. The figure this run saves is the evidence for that too.
Create Table with column names: "adv_demo", 0, "group jitter_pct"
for g to 2
    for k to 14
        Append row
        row = Get number of rows
        Set string value: row, "group", "G" + string$ (g)
        Set numeric value: row, "jitter_pct", 0.6 + g * 1.2 + (k mod 5) * 0.15
    endfor
endfor
tableId = selected ("Table")
appendInfoLine: "ADV begin tableId=", tableId

# THE ANALYSIS RUNS FIRST, because that is what the wrapper does and because
# the buffer it fills decides which post-draw dialog the user sees.
# eml-compare-groups.praat calls @emlRunTwoGroupAnalysis and only then offers
# Draw; this driver used to skip straight to the handover. Nothing in
# plugin/graphs/ ever calls @eml_csvAppend, so emlCSV_n was 0 and "Graph
# Complete" came up with THREE buttons instead of four -- no "Exp CSV" at all.
# A harness that arrives at that dialog by a route no user takes is testing a
# variant of it the shipped path does not produce.
selectObject: tableId
@emlRunTwoGroupAnalysis: tableId, "jitter_pct", "group", "parametric", 1
appendInfoLine: "ADV analysis error=[", emlRunTwoGroupAnalysis.error$, "]"
appendInfoLine: "ADV csvRows=", emlCSV_n

# Exactly what eml-compare-groups.praat sets before it hands over.
emlGraphsPresetType = 7
emlGraphsPresetDataCol$ = "jitter_pct"
emlGraphsPresetGroupCol$ = "group"
emlGraphsPresetTestType$ = "parametric"
emlGraphsPresetAnnotate = 1

@emlGraphsWorkflow: tableId

appendInfoLine: "ADV end"
