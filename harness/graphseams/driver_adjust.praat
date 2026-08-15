# ---------------------------------------------------------------------------
# graphseams/driver_adjust.praat — the adjustment menu, on the arm that reads
#                                  it and on the arm that does not
# ---------------------------------------------------------------------------
# WHAT THIS DRIVE IS FOR. D5 / RULING 1a, 15 August 2026. The "Adjustment
# method" optionmenu was offered on all six annotate-capable column-mapping
# pages and read back at all twelve of their commit sites, and the PARAMETRIC
# arm ignored the value entirely: a Tukey draw is md5-identical under Holm and
# under Bonferroni. The statistics say the code was right to ignore it —
# Tukey's p comes from the studentized range and is already family-wise, so a
# Holm step on top would double-correct — and the ruling says a live-looking
# control that is silently ignored is the wrong way to say so. The field is
# now offered ONLY on the nonparametric arm.
#
# ONE DRIVER, TWO LEGS, ONE DIFFERENCE. $EML_ADJUST_ARM is "parametric" or
# "nonparametric" and nothing else changes: same graph type, same table, same
# columns, same advanced mode, same presets. That is the point — a pair of
# legs that differ in one seeded value is the only arrangement in which the
# dialog's shape can be attributed to that value. Two separately written
# drivers would leave every difference arguable.
#
# THE ARM IS SEEDED THROUGH THE WRAPPER'S OWN PRESET CHANNEL
# (emlGraphsPresetTestType$), not by pressing the Test type menu, because
# pressing it would spend a dialog on the OTHER arm first and the page under
# test would be the second one — which is a different journey and a weaker
# statement.
#
# NOTHING RUNS BEFORE THE HANDOVER. There is no @emlRun* call here: the point
# of this leg is what the FORM does with the field, and an orchestrator
# running first would leave annotCorrectionMethod$ written by something other
# than the page under test, which is exactly the value the receipt below
# reports.
#
# THE RECEIPT IS A FILE, not an Info line. Under --new-send the Info window is
# not stdout, and reading a value back out of a UTF-16 report the panel
# happened to save is a second thing that can go wrong between the measurement
# and the reader.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ---------------------------------------------------------------------------
# The shipped barrel's set, in the barrel's order — eml-lib.praat cannot be
# included from here, because a relative path inside an included file resolves
# against the TOP-LEVEL script's folder. Kept in step by hand, exactly as
# driver.praat and harness/gui_adv/driver.praat do.
include ../stress_cases/_prelude.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-record.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graphs-form.praat

outDir$ = environment$ ("EML_SEAMS_OUT")
if outDir$ = ""
    outDir$ = "."
endif
arm$ = environment$ ("EML_ADJUST_ARM")
if arm$ = ""
    arm$ = "parametric"
endif

table = Read Table from comma-separated file: "fixtures/demo_3groups.csv"
tableId = selected ("Table")
appendInfoLine: "ADJUST begin arm=", arm$, " tableId=", tableId

# Exactly what a stats wrapper sets before it hands over, with the test type
# as the one variable. Three well-separated groups, so the k >= 3 post-hoc
# branch — the branch the adjustment method is about — is the one reached.
emlGraphsPresetType = 7
emlGraphsPresetDataCol$ = "SPL_dB"
emlGraphsPresetGroupCol$ = "voice_type"
emlGraphsPresetTestType$ = arm$
emlGraphsPresetAnnotate = 1

@emlGraphsWorkflow: tableId

# THE RECEIPT. Three values, and each answers a different question:
#
#   adjustOffered          was the field put on the dialog at all. This is the
#                          gate itself, read after the last commit, so it is
#                          the value that decided whether adjustment_method
#                          was read back.
#   annotCorrectionMethod$ what the form is handing the annotation bridge. On
#                          the parametric arm this must still be the file-scope
#                          default, because nothing on that page may write it.
#   annotTestType$         which arm the run actually took. Without it the two
#                          legs above cannot be told apart from a run in which
#                          the preset silently failed to apply, and both legs
#                          would agree for the wrong reason.
writeFileLine: outDir$ + "/ADJUST_" + arm$ + ".txt",
... "arm=", arm$, newline$,
... "adjustOffered=", adjustOffered, newline$,
... "correction=", annotCorrectionMethod$, newline$,
... "testType=", annotTestType$, newline$,
... "annotate=", annotate
appendInfoLine: "ADJUST end"
