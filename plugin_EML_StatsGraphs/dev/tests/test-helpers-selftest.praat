# ============================================================================
# test-helpers-selftest.praat -- positive controls for the assertion helpers
# ============================================================================
# Purpose: The test harness is itself untested code. Every other suite in this
# plugin is only as trustworthy as @emlTestAssertEqualRel and its siblings.
# This suite exercises the paths that must PASS: an exact match, a value
# inside the relative band, and the both-undefined case. Its negative twin
# (test-helpers-selftest-negative.praat) exercises the paths that must FAIL.
# Neither suite is meaningful without the other.
#
# Expected: status=PASS passed=3 failed=0 skipped=0 total=3
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
@emlTestSection: "Rel assertion behaviour"
@emlTestAssertEqualRel: "A exact match", 2.4493583828e-09, 2.4493583828e-09, 1e-9
@emlTestAssertEqualRel: "B within band", 2.4493583828e-09, 2.4493618244747495e-09, 1e-5
@emlTestAssertEqualRel: "C both undefined", undefined, undefined, 1e-9
@emlTestSummary
