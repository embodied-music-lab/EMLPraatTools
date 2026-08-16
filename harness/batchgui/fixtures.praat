# ---------------------------------------------------------------------------
# harness/batchgui/fixtures.praat — the three-take corpus the GUI leg drives
# ---------------------------------------------------------------------------
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THREE FILES, AND EACH ONE IS A DIFFERENT ANSWER FROM THE RANGE GUARD. This is
# not a corpus chosen to be realistic; it is chosen so that the three outcomes
# of APPENDIX_D §7's bounded-range rule are all present in one run and can be
# told apart in one log.
#
#   g1_low    78 Hz.  Clears the 50 Hz filtered-autocorrelation floor by 56%
#                     and sits 4% above the 75 Hz raw-cross-correlation floor.
#                     So the FAC guard must stay SILENT and the RCC guard must
#                     fire — which is the whole reason the two tracks are
#                     guarded separately. A single guard reading the widest
#                     range calls this file clean, and its jitter and shimmer
#                     come off a PointProcess built on a track that could not
#                     look below 75 Hz.
#
#   g2_mid   180 Hz.  Inside every range with room to spare. The control: if
#                     any range warning appears against this file the guard is
#                     firing on something other than proximity.
#
#   g3_high  640 Hz.  Above the 330 Hz cepstral peak search ceiling and above
#                     a stated highest-expected-F0 of 300, so it fires the CPPS
#                     window guard and the stated-value comparison, and it
#                     fires them for two different reasons — the first is a
#                     fixed Maryn parameter that no user setting widens, the
#                     second is about the user's own statement.
#
# 0.6 s EACH, which clears the 0.1 s CPPS minimum with margin: the drive ticks
# all six measures, so the binding constraint is the cepstrogram's.
#
# THREE HARMONICS, NOT A SINE. A pure sine has no harmonic structure for the
# cepstrum to find a peak in, and CPPS on one is not a measurement of anything.
# g3_high carries two because its third would land at 1920 Hz.
#
# WRITTEN TO $EML_BATCHGUI_CORPUS so run.sh owns the path and this file has no
# absolute path in it.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------

corpus$ = environment$ ("EML_BATCHGUI_CORPUS")
if corpus$ = ""
    exitScript: "fixtures: EML_BATCHGUI_CORPUS is not set."
endif

Create Sound from formula: "g1_low", 1, 0, 0.6, 44100,
    ... ~ 0.5*sin(2*pi*78*x) + 0.25*sin(2*pi*156*x) + 0.12*sin(2*pi*234*x)
Save as WAV file: corpus$ + "/g1_low.wav"
Remove

Create Sound from formula: "g2_mid", 1, 0, 0.6, 44100,
    ... ~ 0.5*sin(2*pi*180*x) + 0.25*sin(2*pi*360*x) + 0.12*sin(2*pi*540*x)
Save as WAV file: corpus$ + "/g2_mid.wav"
Remove

Create Sound from formula: "g3_high", 1, 0, 0.6, 44100,
    ... ~ 0.5*sin(2*pi*640*x) + 0.25*sin(2*pi*1280*x)
Save as WAV file: corpus$ + "/g3_high.wav"
Remove

writeInfoLine: "fixtures ok"
