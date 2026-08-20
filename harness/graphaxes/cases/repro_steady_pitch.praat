include _prelude.praat
# NEW-G7-1 reproduction: a rock-steady 200 Hz tone drawn as an F0 contour.
snd = Create Sound from formula: "steady200", 1, 0, 1.0, 44100, "0.5*sin(2*pi*200*x)"
pit = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
pMin = Get minimum: 0, 0, "Hertz", "parabolic"
pMax = Get maximum: 0, 0, "Hertz", "parabolic"
appendInfoLine: "PITCHMIN ", pMin
appendInfoLine: "PITCHMAX ", pMax
appendInfoLine: "SPAN ", pMax - pMin
Erase all
@emlDrawF0Contour: pit, "Steady 200 Hz", "Time (s)", "F0 (Hz)", 6, 4, "color", 4, 0, 0, 0, 0, 1
appendInfoLine: "AXISMIN ", emlDrawF0Contour.freqMin
appendInfoLine: "AXISMAX ", emlDrawF0Contour.freqMax
appendInfoLine: "AXISSPAN ", emlDrawF0Contour.freqMax - emlDrawF0Contour.freqMin
removeObject: snd
@axSave
