# harness/verifyerrorlane/getgroup_probe.praat -- what does @eml_getGroupData
# actually do with a column that is not there? Two comments in
# stats/eml-analysis.praat's @emlRunTwoGroupAnalysis disagree: the older one
# (lines 108-119) says "answers a missing column with an empty vector rather
# than an error"; the ERROR-READ EXEMPT reason added for punch 9.2 says its
# "only failure path is @emlExtractColumn's Column not found". Asked here.
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
t = Create Table with column names: "t", 4, "g score"
for i to 4
    Set string value: i, "g", if i <= 2 then "A" else "B" fi
    Set numeric value: i, "score", i
endfor
@eml_getGroupData: t, "nosuchcol", "g", "A"
appendInfoLine: "missing DATA column  -> error=[", eml_getGroupData.error$, "] n=", eml_getGroupData.n
@eml_getGroupData: t, "score", "g", "A"
appendInfoLine: "good                 -> error=[", eml_getGroupData.error$, "] n=", eml_getGroupData.n
