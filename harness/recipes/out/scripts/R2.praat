include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_StatsGraphs/stats/eml-inferential.praat

data = Read Table from comma-separated file: "~/voice_study/pre_post.csv"

@emlExtractPairedColumns: data, "pre", "post"
if emlExtractPairedColumns.error$ <> ""
    exitScript: emlExtractPairedColumns.error$
endif
writeInfoLine: "complete pairs: ", emlExtractPairedColumns.n,
...            "  (dropped: ", emlExtractPairedColumns.nExcludedRows, ")"

@emlTTestPaired: emlExtractPairedColumns.data1#, emlExtractPairedColumns.data2#, 2
appendInfoLine: "paired t = ", fixed$ (emlTTestPaired.t, 4),
...             "  df = ", emlTTestPaired.df,
...             "  p = ", fixed$ (emlTTestPaired.p, 4)

@emlPearsonCorrelation: emlExtractPairedColumns.data1#, emlExtractPairedColumns.data2#, 2
appendInfoLine: "r = ", fixed$ (emlPearsonCorrelation.r, 4),
...             "  p = ", fixed$ (emlPearsonCorrelation.p, 4)
