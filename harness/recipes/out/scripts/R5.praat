include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-core-utilities.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-core-descriptive.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-extract.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-output.praat
include ~/.praat-dir/plugin_EML_Praat_Tools/stats/eml-inferential.praat

sound = Read from file: "~/voice_study/sustained_a.wav"
pitch = To Pitch: 0, 75, 600

@emlExtractPitchValues: pitch, "Hertz"
f0# = emlExtractPitchValues.data#
writeInfoLine: "voiced frames: ", emlExtractPitchValues.n,
...            " of ", emlExtractPitchValues.nTotal,
...            " (", fixed$ (emlExtractPitchValues.percentVoiced, 1), "% voiced)"

@emlMedian: f0#
appendInfoLine: "median F0 = ", fixed$ (emlMedian.result, 2), " Hz"

@emlQuartiles: f0#
appendInfoLine: "IQR = ", fixed$ (emlQuartiles.q1, 2),
...             " to ", fixed$ (emlQuartiles.q3, 2), " Hz"

@emlSD: f0#
appendInfoLine: "SD = ", fixed$ (emlSD.result, 2), " Hz"
