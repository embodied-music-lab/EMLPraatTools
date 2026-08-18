# ---------------------------------------------------------------------------
# THE SECOND-AXIS DIALOGS, DRIVEN AS A USER DRIVES THEM.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Calls @emlGraphsWorkflow with a Table id, exactly as a stats wrapper's Draw
# branch does, with the graph type preset to the Line chart. Everything after
# that is the shipped form, dialogs and all.
#
# NO SCREEN COORDINATES ANYWHERE, by harness/gui_e2e's rule: every dialog is
# dismissed with Return, which lands on the plugin's own default button. What
# would otherwise need a click -- ticking "Add second dataset" and choosing a
# column on the follow-up page -- is SEEDED through the form's own persistence
# variables instead, because those are the variables the dialog seeds its
# fields from. So the page that comes up is the page a user sees after a
# previous press, and the harness never has to know where a widget sits.
#
# gui_pause.sh chooses which of the two runs this is with EML_SECOND_COL.
# ---------------------------------------------------------------------------
# The shipped barrel's set, listed here rather than included through it: a
# relative path inside an included file resolves against the TOP-LEVEL
# script's folder, so a barrel cannot be borrowed from another directory.
# Spelled plugin_EML_StatsGraphs, never the compatibility symlink.
include ../../plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ../../plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ../../plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ../../plugin_EML_StatsGraphs/stats/eml-extract.praat
include ../../plugin_EML_StatsGraphs/stats/eml-output.praat
include ../../plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ../../plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ../../plugin_EML_StatsGraphs/stats/eml-record.praat
include ../../plugin_EML_StatsGraphs/stats/eml-analysis.praat
include ../../plugin_EML_StatsGraphs/graphs/eml-graphs-form.praat

@emlInitDrawingDefaults

include data.praat
tableId = selected ("Table")
appendInfoLine: "GUI begin tableId=", tableId

# The type the wrapper asks for: 5 is the Line chart.
emlGraphsPresetType = 5

# The form's own persistence, set to what a previous press would have left:
# long format, the tickbox ticked, and a chosen right-hand column. This is
# what makes the run clickless -- see the header.
prev_tsDataFormat = 2
prev_tsTimeIdx = 1
prev_tsValueIdx = 2
prev_tsGroupIdx = 1
prev_tsSecondAxis = 1
prev_tsSecondStyle = 3
prev_tsSecondLabel$ = "Contact quotient"
secondCol = number (environment$ ("EML_SECOND_COL"))
if secondCol = undefined or secondCol < 1
    secondCol = 5
endif
prev_tsSecondIdx = secondCol
appendInfoLine: "GUI second column index=", secondCol

@emlGraphsWorkflow: tableId
appendInfoLine: "GUI done"

; THE FIGURE THE DIALOGS PRODUCED, saved after the workflow returns rather
; than through the Save panel: this harness is about the pages that lead to
; the figure, and driving a folder chooser as well would be a second harness.
; @emlAssertFullViewport is the plugin's own extent union -- the rectangle the
; Save panel would have written.
guiOut$ = environment$ ("EML_GUI_FIGURE")
if guiOut$ <> ""
    @emlAssertFullViewport
    Save as 300-dpi PNG file: guiOut$
    appendInfoLine: "GUI figure saved to ", guiOut$
endif
