# ============================================================================
# evidence/redrive/wizard_rm3.praat — re-drive the two wizard repeated-measures
# legs that produce evidence/info/wizard_rm3_rmanova_and_friedman.txt
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# WHY THIS EXISTS. The committed capture was taken by hand from the Info
# window on 6 August 2026 and there was no way to take it again. When
# @emlFormatP grew an exact tail and RULING 6 routed the wizard's numbers
# through @eml_fixed, the capture went stale in SHAPE while every value in it
# stayed right — the worst kind of stale, because v03 and v04 kept passing on
# tokens the plugin had stopped printing in that position. A capture that
# cannot be retaken is an oracle nobody can audit.
#
# WHAT IS DRIVEN, AND WHY IT IS THE WIZARD'S OWN CODE. The two calls below are
# the wizard's, not a re-implementation: plugin/scripts/eml-wizard.praat lines
# 1246-1250 (parametric leg) and 1262-1266 (nonparametric leg). The plan
# banner is @wizardReportPlan itself, lifted out of eml-wizard.praat by
# run.sh at drive time — eml-wizard.praat cannot be included, because its top
# level is the wizard's own beginPause loop and beginPause hard-crashes under
# --run (harness/GUI_HARNESS_RECIPE.md §0). Extracting the PROCEDURES section
# mechanically, every time, is the difference between driving the shipping
# wizard and driving a copy of it that can drift.
#
# The one thing this does not reproduce is the click path — the wizard's
# dialogs choose the arguments, and here they are transcribed. The arguments
# are therefore the part to re-read against eml-wizard.praat whenever that
# file's repeated-measures branch changes.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include wizard_procs.generated.praat

Text writing preferences: "UTF-8"

# The wizard sets this at load; @emlReportLineString reads it.
emlShowExplanations = 1
emlWizardExplain$ = ""

t = Read Table from comma-separated file: "../csv/demo_rm3_input.csv"
Rename: "demo_rm3"
tableId = t
tableName$ = "demo_rm3"
displayTable$ = replace$ (tableName$, "_", " ", 0)
condList$ = "SPL_soft|SPL_medium|SPL_loud|"
pairwise_post_hoc = 1
adjustment$ = "holm"

writeInfo: ""

# --- parametric leg: eml-wizard.praat:1246 ---------------------------------
@wizardReportPlan: "Repeated measures (k conditions)",
... "n/a", "RM-ANOVA (Greenhouse-Geisser)",
... "n/a", condList$, "", "", displayTable$
selectObject: tableId
@emlRunRepeatedMeasuresAnalysis: tableId, "", condList$,
... pairwise_post_hoc, adjustment$

# --- nonparametric leg: eml-wizard.praat:1262 ------------------------------
@wizardReportPlan: "Repeated measures (k conditions)",
... "n/a", "Friedman test",
... "n/a", condList$, "", "", displayTable$
selectObject: tableId
@emlRunFriedmanAnalysis: tableId, "", condList$,
... pairwise_post_hoc, adjustment$

# @wizardReportPlan opens with a blank line, which in the GUI separates the
# plan from whatever the Info window already held. Here the window was cleared
# a line earlier, so that separator is a leading empty line with nothing above
# it. Dropped, so the artefact begins where the report begins — the same shape
# the hand-taken capture had.
text$ = info$ ()
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
writeFile: "../info/wizard_rm3_rmanova_and_friedman.txt", text$
