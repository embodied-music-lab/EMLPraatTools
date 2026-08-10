# ============================================================================
# D93 walk 2 — WIZARD path, analysis error at a FORMER exitScript: site
# ============================================================================
# eml-wizard.praat:448 / :465 — before commit 438cdb1 both read
#   exitScript: emlRunTwoGroupAnalysis.error$
# so an analysis error four pages in destroyed the wizard.
#
# Data: validate/redpath/r4_singleton_group.csv — Soprano n=6, Alto n=1, so
# the two-group orchestrator refuses on group size, not on group count.
#
# Claim under test: 1 (wizard errors return into the wizard).
# ============================================================================

tid = Read Table from comma-separated file:
... "../../../validate/redpath/r4_singleton_group.csv"
selectObject: tid
runScript: preferencesDirectory$
... + "/plugin_EML_Praat_Tools/scripts/eml-wizard.praat"
