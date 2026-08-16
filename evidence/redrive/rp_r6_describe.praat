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
@emlRunDescriptiveAnalysis: t, "SPL_soft"

text$ = info$ ()
if left$ (text$, 1) = newline$
    text$ = right$ (text$, length (text$) - 1)
endif
writeFile: "../info/rp_r6_describe_info.txt", text$
