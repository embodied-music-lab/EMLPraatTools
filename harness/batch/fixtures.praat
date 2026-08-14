# ============================================================================
# harness/batch/fixtures.praat -- the corpora the batch drive is run over
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# EVERY INPUT HAS A GROUND TRUTH, and that is the whole design. A batch flow
# fails quietly: the loop can pair row 3 with file 4, the TextGrid branch can
# extract nothing and measure the whole file, a measure can be written into the
# neighbouring column, and in every one of those cases the CSV still has the
# right shape and every cell still holds a plausible number. Nothing about the
# artefact says which file a row describes -- unless the row's VALUE says so.
#
# So each Sound here is a periodic complex at an F0 nothing else in its corpus
# shares, and the stem is the only other thing that names it. A row whose stem
# and whose F0 disagree is a mis-wired loop, and it is visible at a glance.
#
# NOTHING HERE IS RANDOM. Praat's randomGauss would give a fresh corpus on
# every run and an evidence file that differs from itself, so the jitter and
# shimmer fixtures are built by deterministic modulation instead: a phase
# modulation at F0/2 lengthens and shortens alternate periods, an amplitude
# switch at F0/2 makes alternate periods loud and quiet. Both were scanned on
# Praat 6.6.30, 14 August 2026, and the index chosen so that ONE measure goes
# out of its APPENDIX_D band and the others stay inside it.
#
# THE BASE FOLDER ARRIVES IN AN ENVIRONMENT VARIABLE, not as a relative path.
# Relative paths in a .praat file rebase against THAT FILE's folder, which is
# how harness/acoustic/drive.praat came to write into its own directory. This
# script is run from a scratch tree it must not be inside, so the tree is named
# absolutely by run.sh.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

work$ = environment$ ("EML_BATCH_WORK")
if work$ = ""
    exitScript: "EML_BATCH_WORK is not set. run.sh sets it; this script "
        ... + "will not guess a folder to write a corpus into."
endif

# A four-harmonic complex at a named F0. The harmonic stack is what
# harness/acoustic/drive.praat uses, so the two harnesses are looking at the
# same kind of signal and a difference between them is about the flow.
procedure mkTone: .path$, .f0, .dur
    Create Sound from formula: "t", 1, 0, .dur, 44100,
        ... "0.5*sin(2*pi*" + string$ (.f0) + "*x)"
        ... + " + 0.3*sin(2*pi*" + string$ (2 * .f0) + "*x)"
        ... + " + 0.2*sin(2*pi*" + string$ (3 * .f0) + "*x)"
        ... + " + 0.1*sin(2*pi*" + string$ (4 * .f0) + "*x)"
    Save as WAV file: .path$
    Remove
endproc

# ---------------------------------------------------------------------------
# A -- THE FILE LOOP. Five files, five F0s, and the two orders disagree.
# ---------------------------------------------------------------------------
# WRITTEN OUT OF ALPHABETICAL ORDER ON PURPOSE. charlie, echo, alpha, delta,
# bravo go onto the disk in that sequence; the rows must come back alpha,
# bravo, charlie, delta, echo, with 100, 140, 180, 220, 260 Hz beside them. A
# loop that returned creation order would give 180, 260, 100, 220, 140 against
# the same five stems and every other property of the CSV would be perfect.
createFolder: work$ + "/A_in"
@mkTone: work$ + "/A_in/charlie.wav", 180, 2.0
@mkTone: work$ + "/A_in/echo.wav", 260, 2.0
@mkTone: work$ + "/A_in/alpha.wav", 100, 2.0
@mkTone: work$ + "/A_in/delta.wav", 220, 2.0
@mkTone: work$ + "/A_in/bravo.wav", 140, 2.0

# ---------------------------------------------------------------------------
# B -- THE FOUR WAYS A FILE CAN REFUSE TO BE ANALYSED
# ---------------------------------------------------------------------------
# Two good files, one at each end, because the claim under test is not only
# "the bad file is reported" but "the good files still get their rows". A run
# that aborts on b02 loses b04 and b05 as well, and until 14 August 2026 that
# is exactly what happened -- with no CSV written at all.
#
# b03 is a TextGrid saved under a .wav name: it READS perfectly well and is
# simply not a Sound. It is here because it is the one failure that a bare
# "did the read throw" test misses -- Praat is happy, and the script would go
# on to ask a TextGrid for its number of channels.
createFolder: work$ + "/B_in"
@mkTone: work$ + "/B_in/b01_good.wav", 120, 2.0
@mkTone: work$ + "/B_in/b05_good.wav", 200, 2.0
Create TextGrid: 0, 1, "notasound", ""
Save as text file: work$ + "/B_in/b03_wrongtype.wav"
Remove
# 0.02 s: shorter than every analysis window in APPENDIX_D. Before 14 Aug 2026
# this produced "pitch floor must not be less than 300 Hz" and ended the run.
@mkTone: work$ + "/B_in/b04_short.wav", 120, 0.02
# b02 (zero length) and the corrupt bytes are made by run.sh -- Praat cannot
# write a file with no content.

# ---------------------------------------------------------------------------
# C -- THE TEXTGRID-CONSTRAINED PATH
# ---------------------------------------------------------------------------
# THE PROOF THAT THE CONSTRAINT IS APPLIED IS A DIFFERENCE, so every sound here
# changes F0 partway through and the labelled interval covers only one part of
# it. c1 is 130 Hz for a second and then 260 Hz for a second, and only the
# second half is labelled V: unconstrained it must read near the middle of the
# two, constrained it must read 260. A branch that built the interval list and
# then analysed the whole file would return the same number twice, which is a
# thing no count of rows or columns can see.
#
# c2 carries TWO labelled intervals at two more F0s, so the segment loop has to
# produce two rows for one file, each with its own interval bounds.
#
# c3 has no TextGrid at all.
createFolder: work$ + "/C_in"
createFolder: work$ + "/C_tg"

Create Sound from formula: "c1", 1, 0, 2.0, 44100,
    ... "if x < 1.0 then 0.5*sin(2*pi*130*x) + 0.25*sin(2*pi*260*x)"
    ... + " else 0.5*sin(2*pi*260*x) + 0.25*sin(2*pi*520*x) fi"
Save as WAV file: work$ + "/C_in/c1_split.wav"
Remove
Create TextGrid: 0, 2.0, "phon", ""
Insert boundary: 1, 1.0
Set interval text: 1, 2, "V"
Save as text file: work$ + "/C_tg/c1_split.TextGrid"
Remove

Create Sound from formula: "c2", 1, 0, 1.8, 44100,
    ... "if x < 0.6 then 0.5*sin(2*pi*110*x) + 0.25*sin(2*pi*220*x)"
    ... + " else if x < 1.2 then 0.5*sin(2*pi*220*x) + 0.25*sin(2*pi*440*x)"
    ... + " else 0.5*sin(2*pi*330*x) + 0.25*sin(2*pi*660*x) fi fi"
Save as WAV file: work$ + "/C_in/c2_three.wav"
Remove
Create TextGrid: 0, 1.8, "phon", ""
Insert boundary: 1, 0.6
Insert boundary: 1, 1.2
Set interval text: 1, 2, "V"
Set interval text: 1, 3, "V"
Save as text file: work$ + "/C_tg/c2_three.TextGrid"
Remove

@mkTone: work$ + "/C_in/c3_nogrid.wav", 150, 2.0

# ---------------------------------------------------------------------------
# D -- ENOUGH FILES THAT A MID-RUN STOP HAS SOMEWHERE TO LAND
# ---------------------------------------------------------------------------
# Twelve, all six measures, so the run takes long enough for the sentinel to be
# flipped while it is still going and long enough that "it stopped early" is
# unambiguous rather than a photo finish. Each F0 is distinct so the rows that
# DID get written can still be checked against their stems.
createFolder: work$ + "/D_in"
for i from 1 to 12
    @mkTone: work$ + "/D_in/d" + right$ ("0" + string$ (i), 2) + ".wav",
        ... 90 + 10 * i, 2.0
endfor

# ---------------------------------------------------------------------------
# E -- ONE FILE, FOR THE OUTPUT FOLDER THAT DOES NOT EXIST YET
# ---------------------------------------------------------------------------
createFolder: work$ + "/E_in"
@mkTone: work$ + "/E_in/e1.wav", 175, 2.0

# ---------------------------------------------------------------------------
# F -- ONE SIGNAL PER MEASURE, EACH OUTSIDE ITS APPENDIX_D §7 BAND
# ---------------------------------------------------------------------------
# Measured values, Praat 6.6.30, 14 August 2026, with the module's own
# canonical parameter sets. Each is a NON-BLOCKING warning: §7 says warn, never
# exitScript, and the run must reach COMPLETE with six rows in the CSV.
createFolder: work$ + "/F_in"

# f1: 1400 Hz. Above the 1000 Hz top of the F0 band. Needs the run's
#     highest_expected_F0 raised to 900 so facPitchTop (1800) can see it at
#     all -- an F0 the tracker cannot reach comes back undefined, which is a
#     different warning and would not test this one.
Create Sound from formula: "f1", 1, 0, 2.0, 44100, "0.5*sin(2*pi*1400*x)"
Save as WAV file: work$ + "/F_in/f1_f0high.wav"
Remove

# f2: the same 120 Hz tone at 1/5000 of the amplitude. Mean intensity 10.97 dB,
#     below the 20 dB floor of the intensity band. Everything else about it is
#     ordinary, which is the point -- a quiet take is a real thing to find in a
#     corpus and it must not stop the batch.
Create Sound from formula: "f2", 1, 0, 2.0, 44100, "0.0001*sin(2*pi*120*x)"
Save as WAV file: work$ + "/F_in/f2_quiet.wav"
Remove

# f3: phase modulation at F0/2, index 0.25 -- alternate periods long and short.
#     Jitter (local) 0.0775, above the 0.05 band; shimmer 0.0199, inside its
#     own. Scanned over index 0.05..0.30 to find one that trips exactly one.
Create Sound from formula: "f3", 1, 0, 2.0, 44100,
    ... "0.5*sin(2*pi*120*x + 0.25*sin(2*pi*60*x))"
Save as WAV file: work$ + "/F_in/f3_jitter.wav"
Remove

# f4: alternate periods at 0.5 and 0.35 amplitude. Shimmer (local) 0.3763,
#     above the 0.15 band; jitter 0.0140, inside its own. The switch happens at
#     a zero crossing of the carrier, so there is no step discontinuity for the
#     pitch tracker to trip over.
Create Sound from formula: "f4", 1, 0, 2.0, 44100,
    ... "(if (floor(x*120) mod 2) = 0 then 0.5 else 0.35 fi) * sin(2*pi*120*x)"
Save as WAV file: work$ + "/F_in/f4_shimmer.wav"
Remove

# f5: a bare sine. HNR 96.03 dB, far above the 40 dB top of the HNR band --
#     there is no noise for the harmonics to be measured against. Worth saying
#     plainly: on synthetic material the HNR band warns almost always, which is
#     a property of the band and not a defect. f5 is here so that the HNR
#     warning has a file whose ONLY out-of-band measure is HNR.
Create Sound from formula: "f5", 1, 0, 2.0, 44100, "0.5*sin(2*pi*120*x)"
Save as WAV file: work$ + "/F_in/f5_hnr.wav"
Remove

# f6: a 150 Hz square wave. CPPS 30.18 dB, above the 25 dB top of the CPPS
#     band -- an infinitely sharp harmonic stack gives a cepstral peak no voice
#     produces. Chosen by scanning square and click trains at 60..330 Hz.
#
#     150 Hz AND NOT THE 60 Hz THAT SCORED HIGHEST, which is worth writing down
#     because it is a fact about the module's own parameters. S1B's raw
#     cross-correlation floor is 75 Hz, so a 60 Hz fundamental has no voiced
#     frame to build a PointProcess from and jitter, shimmer and HNR all come
#     back undefined -- three more warnings, of a different kind, on the one
#     file whose job is to test the CPPS band alone.
Create Sound from formula: "f6", 1, 0, 2.0, 44100,
    ... "if sin(2*pi*150*x) > 0 then 0.5 else -0.5 fi"
Save as WAV file: work$ + "/F_in/f6_cpps.wav"
Remove

writeInfoLine: "FIXTURES OK"
