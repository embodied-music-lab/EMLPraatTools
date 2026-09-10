# ============================================================================
# evidence/redrive/rp_r6_describe.praat — re-drive red path R6, the descriptive
# leg, producing evidence/info/rp_r6_describe_info.txt
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# R6 is a numeric measure column carrying one unparseable string ("n/a" in row
# 3 of 5). Describe Table column on SPL_soft is the path that meets it.
#
# WHAT THE COMMITTED CAPTURE HELD, AND WHY IT SHRANK. The hand-taken file of
# 5 August opened with 121 lines that are byte-for-byte
# evidence/info/v15_normality_info.txt — the previous run still sitting in the
# Info window when the describe was driven. That residue is not evidence of
# anything this file's name claims, it is asserted on in its own right by
# v15_normality_orchestrator.R against its own capture, and carrying a second
# copy of it here only created a second thing to go stale. The R6 leg is what
# remains.
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
t = Read Table from comma-separated file: "../csv/rp_r6_describe_input.csv"
Rename: "r6_nonnumeric_in_measure"
@emlRunDescriptiveAnalysis: t, "SPL_soft", "", 0.2

text$ = info$ ()
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
; RE-DRIVEN 9 Sep 2026 under CORRECTION_LEVEL2_IS_A_REFUSAL: row 3's "n/a" is
; a LEVEL 2 cell, so this now refuses the whole column via
; @emlRequireNumericColumn instead of printing "N (valid) 4 / N (excluded) 1"
; -- no report is printed at all. The .ok/.error$/.remedy$ triple is
; appended, exactly what a live GUI run would have handed to
; @emlErrorDialog.
if emlRunDescriptiveAnalysis.error$ <> ""
    text$ = text$ + newline$ + newline$
    ... + "emlRunDescriptiveAnalysis.ok = " + string$ (emlRunDescriptiveAnalysis.ok) + newline$
    ... + "emlRunDescriptiveAnalysis.error$ = """ + emlRunDescriptiveAnalysis.error$ + """" + newline$
    ... + "emlRunDescriptiveAnalysis.remedy$ = """ + emlRunDescriptiveAnalysis.remedy$ + """"
endif
writeFile: "../info/rp_r6_describe_info.txt", text$
