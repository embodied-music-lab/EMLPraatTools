# ===========================================================================
# ONE-RUN PROBE -- open in Praat, press Run. Nothing is modified.
#
# Answers the question blocking the kernel scope decision: does this Praat
# build give scripts the matrix operations that an exact Type III sum of
# squares needs?
#
# HOW TO READ A FAILURE. Praat has no try/catch, so a missing function stops
# the script. Each test writes its name to probe_results.txt BEFORE running.
# If the script halts, the last line in that file names the call this build
# does not have -- that IS the answer, not a problem. Send the file either
# way, and the Info window text if the script stopped early.
# ===========================================================================

out$ = "probe_results.txt"

writeFileLine: out$, "EML capability probe"
appendFileLine: out$, "Praat version: ", praatVersion$
appendFileLine: out$, "Date: ", date$ ()
appendFileLine: out$, ""

appendFileLine: out$, "TEST 1  zero## -- build a 3x3"
a## = zero## (3, 3)
a## [1,1] = 4
a## [1,2] = 1
a## [1,3] = 0
a## [2,1] = 1
a## [2,2] = 3
a## [2,3] = 1
a## [3,1] = 0
a## [3,2] = 1
a## [3,3] = 2
appendFileLine: out$, "        PASS"

appendFileLine: out$, "TEST 2  transpose##"
t## = transpose## (a##)
appendFileLine: out$, "        PASS"

appendFileLine: out$, "TEST 3  mul## -- matrix product"
p## = mul## (a##, t##)
appendFileLine: out$, "        PASS, p[1,1] = ", p## [1,1], " (expect 17)"

appendFileLine: out$, "TEST 4  inverse## -- THE ONE THAT MATTERS FOR TYPE III"
inv## = inverse## (a##)
appendFileLine: out$, "        PASS, inv[1,1] = ", inv## [1,1]
chk## = mul## (a##, inv##)
appendFileLine: out$, "        A*inv should be the identity:"
appendFileLine: out$, "        [1,1] = ", chk## [1,1], "   [1,2] = ", chk## [1,2], "   [1,3] = ", chk## [1,3]
appendFileLine: out$, "        [2,1] = ", chk## [2,1], "   [2,2] = ", chk## [2,2], "   [2,3] = ", chk## [2,3]

appendFileLine: out$, "TEST 5  solve# -- solve A x = y without forming an inverse"
y# = {5, 5, 3}
x# = solve# (a##, y#)
appendFileLine: out$, "        PASS, x = ", x# [1], " ", x# [2], " ", x# [3]

appendFileLine: out$, ""
appendFileLine: out$, "ALL TESTS PASSED."
appendFileLine: out$, "Type III is a direct computation on this build -- no hand-rolled solver needed."

writeInfoLine: "Probe finished. Results written beside the script as probe_results.txt"
