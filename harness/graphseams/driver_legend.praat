# ---------------------------------------------------------------------------
# graphseams/driver_legend.praat — a beginner save, with an advanced session's
# legend choice already on disk
# ---------------------------------------------------------------------------
# D8. "Legend placement" exists only on the advanced page, so
# @emlCommitLegendPlacement is only ever called from inside an
# `if config_showAdvanced` arm -- and config_legendPlacement, once written,
# persists to eml-graphs-config.txt and is read by the DRAW, in either mode.
# A user who once chose "Separate figure", quit, and came back in beginner
# mode therefore got an unrequested <stem>_legend.png out of the Save panel
# from a dialog that had never mentioned legends.
#
# THE OLD SESSION IS THE CONFIG FILE. run.sh writes `legendPlacement: 4` into
# this leg's pref dir before Praat starts, which is precisely what quitting an
# advanced session with "Separate figure" selected leaves behind -- there is
# no other way for the value to get there, and seeding it is cheaper and more
# exact than driving a whole advanced session to produce it.
#
# A SCATTER WITH GROUPS, because a legend needs something to list: the
# violin/bar/box family registers legendPlacementStyle 0 and draws no legend
# at all, so the leak cannot show on it. The preset raises the page's
# "Use group column" box, which is what the correlate wrapper does.
#
# THE OBSERVABLE IS A FILE THAT SHOULD NOT EXIST. Every other artefact of this
# leg is identical either way, which is the reason it needs a drive: the
# figure itself carries no legend in the broken case either -- the legend was
# parked off-extent for a second file nobody asked for.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
include ../stress_cases/_prelude.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graphs-form.praat

table = Read Table from comma-separated file: "fixtures/demo_2groups.csv"
tableId = selected ("Table")
appendInfoLine: "SEAMS legend begin tableId=", tableId
# config_* do not exist until @emlLoadConfig runs, and that is inside the
# workflow. What was seeded is checked by run.sh against the file it wrote.

emlGraphsPresetType = 8
emlGraphsPresetXCol$ = "jitter_pct"
emlGraphsPresetYCol$ = "F0_Hz"
emlGraphsPresetGroupCol$ = "group"

@emlGraphsWorkflow: tableId

appendInfoLine: "SEAMS legend end"
