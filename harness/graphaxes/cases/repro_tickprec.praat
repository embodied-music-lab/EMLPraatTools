include _prelude.praat
# @emlTickPrecision: a USER-SET sub-integer range far from zero. Before the
# fix every tick on this axis read "200". The floor above cannot help here —
# the user typed the range, and a typed range is taken literally.
snd = Create Sound from formula: "steady200", 1, 0, 1.0, 44100, "0.5*sin(2*pi*200*x)"
pit = To Pitch (filtered autocorrelation): 0, 75, 600, 15, "yes", 0.03, 0.09, 0.50, 0.055, 0.35, 0.14
Erase all
@emlDrawF0Contour: pit, "User range 199.98–200.02", "Time (s)", "F0 (Hz)", 6, 4, "color", 4, 0, 0, 199.98, 200.02, 1
@emlComputeNiceStep: 200.02 - 199.98, emlSetAdaptiveTheme.targetTicksY
@emlTickPrecision: 199.98, 200.02, emlComputeNiceStep.step
appendInfoLine: "STEP ", emlComputeNiceStep.step
appendInfoLine: "EXPLICIT ", emlTickPrecision.explicit
appendInfoLine: "DECIMALS ", emlTickPrecision.decimals
removeObject: snd
@axSave
