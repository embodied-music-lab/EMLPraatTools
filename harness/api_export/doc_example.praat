# ---------------------------------------------------------------------------
# doc_example.praat -- the example script in plugin/docs/API_EXPORT.md, verbatim.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY IT LIVES IN THE HARNESS AND NOT ONLY IN THE PROSE. A documented example
# that nobody runs is a guess about an API, and this repository has already
# shipped two of those. run.sh drives this file as its own `praat --run`, from
# a folder OUTSIDE the plugin -- which is where a user's script lives and is
# the one place a barrel include does not work.
#
# THE TWO SUBSTITUTIONS run.sh MAKES, and nothing else:
#
#   ~/.praat-dir/plugin_EML_StatsGraphs  ->  the plugin folder in this repo
#   __EML_DATA__                         ->  evidence/csv/demo_3groups_input.csv
#   __EML_OUT__                          ->  the harness output folder
#
# The first is the "edit this block and nothing else" the recorder's emitted
# scripts already tell a user to make when their plugin is somewhere else. The
# other two are the two things a real user types for themselves. The BODY --
# every line below the include block -- is byte-identical to the document, and
# validate/v50 checks that it still is.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-result-writer.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-record.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/graphs/eml-draw-procedures.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-analysis.praat

# --- BEGIN DOCUMENTED BODY ---
# Where the numbers come from, and where the files go.
inputFile$  = "__EML_DATA__"
outputFolder$ = "__EML_OUT__"
baseName$   = "anova_by_voice_type"

# THE FOLDER IS YOURS TO MAKE. The Save dialog calls createFolder: on whatever
# you typed into it; @emlExportResultFiles does not, and Praat stops the whole
# script on the first write into a folder that is not there.
createFolder: outputFolder$

# One Table, read the way Praat reads any CSV.
data = Read Table from comma-separated file: inputFile$

# The analysis. This one DECLARES, so the export below writes broom frames.
@emlRunAnovaAnalysis: data, "SPL_dB", "voice_type", 1

# The export. No dialog, no questions: a folder and a base name.
@emlExportResultFiles: outputFolder$, baseName$

# What it did. Read these rather than assuming -- an analysis that declared
# nothing and an analysis that failed both come back with nWritten = 0, and
# .reason$ is what tells them apart.
appendInfoLine: "declared : ", emlExportResultFiles.declared
appendInfoLine: "success  : ", emlExportResultFiles.success
appendInfoLine: "written  : ", emlExportResultFiles.nWritten
appendInfoLine: "reason   : ", emlExportResultFiles.reason$
if emlExportResultFiles.declared = 1
    appendInfoLine: "frames written:"
    appendInfoLine: emlExportResultFiles.fileList$
    if emlExportResultFiles.skipped$ <> ""
        appendInfoLine: "frames skipped, and why:"
        appendInfoLine: emlExportResultFiles.skipped$
    endif
else
    appendInfoLine: "one long-format file: ", emlExportResultFiles.actualPath$
endif
# --- END DOCUMENTED BODY ---

appendInfoLine: "APIEXPORT DONE leg=example"
