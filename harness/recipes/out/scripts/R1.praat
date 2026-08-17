include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-inferential.praat

data = Read Table from comma-separated file: "~/voice_study/spl_by_group.csv"

# Table rows -> two named vectors
@emlExtractGroupVectors: data, "spl", "group", "soprano", "mezzo"
if emlExtractGroupVectors.error$ <> ""
    exitScript: emlExtractGroupVectors.error$
endif
v1# = emlExtractGroupVectors.group1#
v2# = emlExtractGroupVectors.group2#
writeInfoLine: "n soprano = ", emlExtractGroupVectors.n1,
...            "  n mezzo = ", emlExtractGroupVectors.n2,
...            "  excluded = ", emlExtractGroupVectors.nExcluded

# Welch t-test, two-sided
@emlTTest: v1#, v2#, 2, 0
appendInfoLine: "t = ", fixed$ (emlTTest.t, 4),
...             "  df = ", fixed$ (emlTTest.df, 2),
...             "  p = ", fixed$ (emlTTest.p, 4)

# Directional hypothesis, stated in words
@emlTTestAlt: v1#, v2#, "less", 0
appendInfoLine: "H1 soprano < mezzo: p = ", fixed$ (emlTTestAlt.p, 4)

# Effect size
@emlCohenD: v1#, v2#
appendInfoLine: "d = ", fixed$ (emlCohenD.d, 4),
...             "  (Hedges' g = ", fixed$ (emlCohenD.g, 4), ")"
