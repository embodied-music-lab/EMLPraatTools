# ---------------------------------------------------------------------------
# graphseams/driver_scatter.praat — three draws, one analysis
# ---------------------------------------------------------------------------
# NEW-G8-3. Nine Draws in one graphs session put nine value-identical blocks
# in the exported results CSV -- 18 rows after the first save, 162 after the
# ninth -- because the scatter's reporters append to the CSV collector and
# nothing on that path ever reset it. This drive presses Draw THREE times in
# one session and exports once; the row count is the whole experiment, and
# three times a block is as unambiguous as nine.
#
# NO WRAPPER ANALYSIS RUNS FIRST, and that is deliberate. A declared analysis
# in the buffer sends the export down the three-file broom arm, where the
# scatter's own rows are not written at all and the defect is invisible. A
# standalone graphs session leaves emlResult_declared at 0, the export takes
# the legacy single-file arm, and the file on disk is exactly the collector.
# That is also the journey the audit measured.
#
# THE PRESETS are eml-correlate.praat's Draw branch: type 8, the two columns,
# and an analysis type, which is what makes the advanced page come up with
# "Correlation method" already set to Pearson rather than None -- and a
# scatter with Correlation = None reports nothing and would count zero rows
# whether the collector had been reset or not.
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
appendInfoLine: "SEAMS scatter begin tableId=", tableId
appendInfoLine: "SEAMS csvRows at entry=", emlCSV_n

emlGraphsPresetType = 8
emlGraphsPresetXCol$ = "jitter_pct"
emlGraphsPresetYCol$ = "F0_Hz"
emlGraphsPresetGroupCol$ = "group"
emlGraphsPresetAnalysisType = 1
emlGraphsPresetCorrType$ = "pearson"

@emlGraphsWorkflow: tableId

appendInfoLine: "SEAMS scatter end csvRows=", emlCSV_n
