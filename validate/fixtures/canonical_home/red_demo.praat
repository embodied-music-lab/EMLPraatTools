# ============================================================================
# validate/fixtures/canonical_home/red_demo.praat
# ============================================================================
# NOT PART OF THE PLUGIN. Read by validate/v169_canonical_home.R's own
# self-test only -- never by the tree scan, and never included by any
# plugin_EML_StatsGraphs/**/*.praat file.
#
# WHY THIS EXISTS. A CANONICAL-HOME check that never fires is
# indistinguishable, from its own output, from one that is silently broken:
# both print "0 violations". This fixture is the red demo -- a deliberately
# planted bypass, in a file and outside any procedure the helper_homes.tsv
# allowlist recognises, so the self-test can assert the checker actually
# flags it. If a future edit to the scan engine (a typo in the comment
# stripper, a proc-scope regex that swallows too much) ever stops catching
# this line, the self-test goes red and says so, rather than the whole
# validator quietly stopping being a check at all.
#
# THE PLANTED LINE below is bare `fixed$ (x, 4)` -- exactly the bypass
# AUDIT_PROCEDURES_2026-09-08 §4 documents against @eml_fixed
# (stats/eml-output.praat:627) -- sitting at TOP LEVEL, in a file that is
# neither stats/eml-output.praat, nor any of the three allowed procedures
# (@eml_fixed, @emlReportAlpha, @emlMeasureMatrixLayout). It must be flagged.
# ============================================================================

procedure red_demo_not_a_real_procedure: x
    .notReal$ = fixed$ (x, 4)
endproc
