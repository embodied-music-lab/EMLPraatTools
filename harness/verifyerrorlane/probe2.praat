# harness/verifyerrorlane/probe2.praat -- the same question at the REAL doors.
# See probe.praat's header. This file drives ORCHESTRATORS (the entry points a
# menu door and the graphs bridge actually call), never a reporter directly.
include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat
include ../../plugin/stats/eml-result-writer.praat
include ../../plugin/stats/eml-analysis.praat
include ../../plugin/graphs/eml-graph-procedures.praat
include ../../plugin/graphs/eml-annotation-procedures.praat
include ../../plugin/graphs/eml-draw-procedures.praat
Text writing preferences: "UTF-8"
which$ = environment$ ("EML_VERIFYERR_CASE")
clearinfo

tThree = Create Table with column names: "three", 12, "g score"
for i to 12
    if i <= 4
        Set string value: i, "g", "A"
        Set numeric value: i, "score", 10 + i
    elsif i <= 8
        Set string value: i, "g", "B"
        Set numeric value: i, "score", 20 + i
    else
        Set string value: i, "g", "C"
        Set numeric value: i, "score", 30 + i
    endif
endfor
tBad = Create Table with column names: "bad", 12, "g score"
for i to 12
    if i <= 4
        Set string value: i, "g", "A"
        Set numeric value: i, "score", 10 + i
    elsif i <= 8
        Set string value: i, "g", "B"
        Set numeric value: i, "score", 20 + i
    else
        Set string value: i, "g", "C"
        Set numeric value: i, "score", 30 + i
    endif
endfor
Set string value: 3, "score", "n/a"

if which$ = "anova_missing"
    @emlRunAnovaAnalysis: tThree, "nosuchcol", "g", 0
    appendInfoLine: "error=[", emlRunAnovaAnalysis.error$, "]"
elsif which$ = "anova_nonnumeric"
    @emlRunAnovaAnalysis: tBad, "score", "g", 0
    appendInfoLine: "error=[", emlRunAnovaAnalysis.error$, "]"
elsif which$ = "kw_missing"
    @emlRunKruskalWallisAnalysis: tThree, "nosuchcol", "g", 0, "holm"
    appendInfoLine: "error=[", emlRunKruskalWallisAnalysis.error$, "]"
elsif which$ = "kw_groupmissing"
    @emlRunKruskalWallisAnalysis: tThree, "score", "nosuchgroup", 0, "holm"
    appendInfoLine: "error=[", emlRunKruskalWallisAnalysis.error$, "]"
elsif which$ = "audit_nonnumeric"
    @emlRequireNumericColumn: tBad, "Data column", "score", 0
    appendInfoLine: "strict=0 error=[", emlRequireNumericColumn.error$, "]"
    @emlRequireNumericColumn: tBad, "Data column", "score", 1
    appendInfoLine: "strict=1 error=[", emlRequireNumericColumn.error$, "]"
elsif which$ = "bridge_missing"
    @emlRunAnnotationComparison: tThree, "nosuchcol", "g", 0.05, "brackets", 0, 1, "parametric", 1
    appendInfoLine: "bridge error=[", emlRunAnnotationComparison.error$, "]"
endif
if which$ = "bridge_nonnumeric"
    @emlRunAnnotationComparison: tBad, "score", "g", 0.05, "brackets", 0, 1, "parametric", 1
    appendInfoLine: "bridge error=[", emlRunAnnotationComparison.error$, "]"
    appendInfoLine: "bridge n=", emlRunAnnotationComparison.nGroups
endif
