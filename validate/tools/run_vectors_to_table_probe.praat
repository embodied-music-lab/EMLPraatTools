# ============================================================================
# validate/tools/run_vectors_to_table_probe.praat
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# Top-level wrapper for the @emlVectorsToTable kit fixture probe: includes
# the module under test, the fixture builder, and the probe driver, in that
# fixed order (`include` is parse-time and must be a top-level statement --
# see validate/vectors_to_table_fixtures_probe.praat's own note), then runs
# it. Run from the repository root:
#
#   /usr/local/bin/praat6630 --run validate/tools/run_vectors_to_table_probe.praat
#
# Regenerates validate/vectors_to_table_oracle.tsv. A later run whose output
# disagrees with the committed oracle is the thing to investigate -- this
# wrapper does not decide which side is right.
# ============================================================================

include ../../plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ../fixtures/vectors_to_table/vectors_to_table_fixtures.praat
include ../vectors_to_table_fixtures_probe.praat

@vttp_runProbe: "../vectors_to_table_oracle.tsv"
appendInfoLine: "run_vectors_to_table_probe: wrote validate/vectors_to_table_oracle.tsv"
