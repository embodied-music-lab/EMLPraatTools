# ---------------------------------------------------------------------------
# GUI END-TO-END DRIVER. The workflow a wrapper's Draw branch actually runs.
#
# This is NOT a transcription of eml-compare-groups.praat: it sets the same
# presets that wrapper sets and calls the same entry point with the same
# argument -- lines 155-160 of it -- and everything after @emlGraphsWorkflow
# is the shipped code, dialogs and all.
#
# Driven from run.sh, which owns the display and presses Return at each
# dialog. Return is enough because the plugin's own defaults are the happy
# path: Continue on the main form, Draw on the column mapping, Save on the
# figure. That is why this harness needs no screen coordinates and does not
# break when a dialog is re-laid-out.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------
include ../stress_cases/_prelude.praat
include ../../plugin/graphs/eml-graphs-form.praat

outDir$ = environment$ ("EML_E2E_OUT")
if outDir$ = ""
    outDir$ = "."
endif

# A table with the shape a two-group comparison produces, and a value column
# whose auto-derived label carries a "%" -- the character that used to vanish
# from the title. The figure this run saves is the evidence for that too.
Create Table with column names: "e2e_demo", 0, "group jitter_pct"
for g to 2
    for k to 14
        Append row
        row = Get number of rows
        Set string value: row, "group", "G" + string$ (g)
        Set numeric value: row, "jitter_pct", 0.6 + g * 1.2 + (k mod 5) * 0.15
    endfor
endfor
tableId = selected ("Table")
appendInfoLine: "E2E begin tableId=", tableId

# Exactly what eml-compare-groups.praat sets before it hands over.
emlGraphsPresetType = 7
emlGraphsPresetDataCol$ = "jitter_pct"
emlGraphsPresetGroupCol$ = "group"
emlGraphsPresetTestType$ = "parametric"
emlGraphsPresetAnnotate = 1

@emlGraphsWorkflow: tableId

appendInfoLine: "E2E end"
