# ============================================================================
# test-helpers-selftest-negative.praat -- negative controls for the helpers
# ============================================================================
# Purpose: An assertion helper that never fails is indistinguishable from one
# that never runs. This suite is EXPECTED TO REPORT FAILURES -- that is the
# result being verified. Each check probes one way the harness must refuse:
#   D  value outside the relative band          -> must FAIL
#   E  one side undefined, the other not        -> must FAIL
#   F  relative tolerance with expected == 0    -> must FAIL (misuse)
#   G  small-magnitude absolute failure         -> must FAIL, and the message
#      must be able to DISPLAY the failure (string$, not fixed$(x,6), which
#      renders anything below 5e-7 as 0.000000)
#
# Expected: status=FAIL passed=0 failed=4 skipped=0 total=4
# A PASS from this file means the harness has stopped enforcing.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

include eml-test-helpers.praat

@emlTestInit
@emlTestSection: "Rel assertion negative controls"
@emlTestAssertEqualRel: "D out of band", 2.4493583828e-09, 2.4493618244747495e-09, 1e-9
@emlTestAssertEqualRel: "E one undefined", 1.5, undefined, 1e-9
@emlTestAssertEqualRel: "F misuse zero expected", 0, 0, 1e-9
@emlTestAssertEqualNum: "G small-magnitude abs failure detail", 2.4e-09, 0, 1e-12
@emlTestSummary
