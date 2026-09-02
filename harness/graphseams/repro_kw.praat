# ---------------------------------------------------------------------------
# repro_kw.praat — the significant-Kruskal-Wallis annotated draw, headless
# ---------------------------------------------------------------------------
# Drives the EXACT pair of calls the graphs form makes at its annotation
# bridge (eml-graphs-form.praat, the `graph_type = 7` arm):
#
#     @emlRunAnnotationComparison: ... annotTestType$ = "nonparametric" ...
#     @emlReportBridgeStats:     ...
#
# with a three-group table whose omnibus is significant, which is the branch
# that runs Dunn's test and then reports the pairwise rank-biserial matrix.
#
# The form itself cannot be included here: it calls beginPause: at file scope
# through @emlGraphsWorkflow and there is no display. What is included is the
# same barrel of libraries the form loads, and the two calls are copied from
# the form line for line, so a crash here is the crash the user meets.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
# THE SHIPPED BARREL'S SET, IN THE BARREL'S ORDER (eml-lib.praat), minus
# eml-graphs-form.praat, which calls beginPause: and needs a display.
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat

@emlInitializeDrawingDefaults

out$ = environment$ ("EML_KW_OUT")
if out$ = ""
    out$ = "out"
endif

table = Read Table from comma-separated file: "fixtures/demo_3groups.csv"

# The globals the form sets before the bridge call.
annotCorrectionMethod$ = "holm"
emlGroupSortAlphabetical = 0
emlShowExplanations = 1

@emlClearAnnotations

writeInfoLine: "repro_kw: bridge, nonparametric, k = 3, significant omnibus"

# eml-graphs-form.praat: the Violin arm of the annotation bridge.
@emlRunAnnotationComparison: table, "SPL_dB", "voice_type", 0.05, "p-value", 0, 1,
... "nonparametric", 1
appendInfoLine: "bridge returned, error$ = '" + emlRunAnnotationComparison.error$ + "'"

if emlRunAnnotationComparison.error$ = ""
    @emlReportBridgeStats: table, "SPL_dB", "voice_type"
endif

appendInfoLine: ""
appendInfoLine: "REPRO_REACHED_END"

txt$ = info$ ()
writeFileLine: out$ + "/repro_kw.info.txt", txt$
