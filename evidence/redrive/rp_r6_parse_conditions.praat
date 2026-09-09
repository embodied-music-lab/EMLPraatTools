# ============================================================================
# evidence/redrive/rp_r6_parse_conditions.praat — re-drive red path R6, the
# three-parse-conditions leg, producing
# evidence/info/rp_r6_parse_conditions_info.txt
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# RE-DERIVED 8 Sep 2026 under RULING_DATA_CLEANING_TWO_ITEMS / the new
# @eml_cleanVerdict refuse-or-repair path. The input table
# (evidence/csv/rp_r6_parse_conditions_input.csv) carries three parse
# conditions in column SPL_soft: an unreadable placeholder ("n/a", row 3),
# a single decimal-comma cell ("73,4", row 4 — the ONLY comma in the column,
# so @emlCommaColumnMode reads it unambiguously as mode 1, decimal), and an
# empty cell (row 5). Under the new ruling the comma cell is LEVEL 1
# (repaired to 73.4 and disclosed), leaving only the placeholder and the
# empty cell as LEVEL 2 refusals. Describe Table column on SPL_soft is the
# path that meets it, same as the original capture.
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

Text writing preferences: "UTF-8"

emlShowExplanations = 0
emlWizardExplain$ = ""

writeInfo: ""
t = Read Table from comma-separated file: "../csv/rp_r6_parse_conditions_input.csv"
Rename: "r6 three parse conditions"
@emlRunDescriptiveAnalysis: t, "SPL_soft"

text$ = info$ ()
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
; LEVEL 2 REFUSES (9 Sep 2026 ruling, CORRECTION_LEVEL2_IS_A_REFUSAL): the
; placeholder ("n/a", row 3) is a LEVEL 2 cell, so @emlRunDescriptiveAnalysis
; now refuses the whole column via @emlRequireNumericColumn before N
; (valid)/N (excluded) are ever computed -- no report is printed at all. The
; .ok/.error$/.remedy$ triple is appended, exactly what a live GUI run would
; have handed to @emlErrorDialog. Harmless (both "") were this ever to run
; on a column that computes.
if emlRunDescriptiveAnalysis.error$ <> ""
    text$ = text$ + newline$ + newline$
    ... + "emlRunDescriptiveAnalysis.ok = " + string$ (emlRunDescriptiveAnalysis.ok) + newline$
    ... + "emlRunDescriptiveAnalysis.error$ = """ + emlRunDescriptiveAnalysis.error$ + """" + newline$
    ... + "emlRunDescriptiveAnalysis.remedy$ = """ + emlRunDescriptiveAnalysis.remedy$ + """"
endif
writeFile: "../info/rp_r6_parse_conditions_info.txt", text$
