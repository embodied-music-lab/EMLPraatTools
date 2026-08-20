include _prelude.praat
# Regression guard: a 2 Hz span already drew correctly before the floor
# (verify65). The floor must not touch it.
snd = Create Sound from formula: "ramp2hz", 1, 0, 1.0, 44100, "0.5*sin(2*pi*(199*x+1*x*x))"
pit = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "no", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
pMin = Get minimum: 0, 0, "Hertz", "parabolic"
pMax = Get maximum: 0, 0, "Hertz", "parabolic"
appendInfoLine: "SPAN ", pMax - pMin
Erase all
@emlDrawF0Contour: pit, "Ramp 2 Hz", "Time (s)", "F0 (Hz)", 6, 4, "color", 4, 0, 0, 0, 0, 1
appendInfoLine: "AXISMIN ", emlDrawF0Contour.freqMin
appendInfoLine: "AXISMAX ", emlDrawF0Contour.freqMax
removeObject: snd
@axSave
