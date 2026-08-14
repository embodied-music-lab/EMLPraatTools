# ============================================================================
# harness/acoustic/drive.praat -- do the shipped acoustic calls RUN?
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS NOT. It is not a check on Praat's DSP. Praat validates its own
# algorithms; we take its pitch tracker and its cepstrum as given. Author
# ruling, 14 Aug 2026.
#
# WHAT IT IS. The part that is ours is the CALL: the right command, the right
# arity, the right argument ORDER, the canonical parameter set. Argument order
# is the failure worth spending a harness on, because Praat's positional forms
# accept a number wherever a number is expected. A ceiling supplied in the
# max-candidates slot does not error. It silently becomes 15 candidates and a
# 600-candidate ceiling, and the measure comes back plausible and wrong.
# Running the call is the only way to learn that the signature is what the
# source assumes it is.
#
# THE SIGNAL is a 120 Hz periodic complex with four harmonics: F0 known
# exactly, no perturbation, no added noise. Every measure therefore has a value
# it must be near -- and a chain that mis-parses its arguments lands outside it.
#
# VERSION. The plugin targets Praat 6.6.30 (setup.praat:45-59 enforces it).
# Two commands do not exist below that version at all:
#
#     To Pitch (filtered autocorrelation)   -- 6.4.06 reports "not available"
#     To Pitch (raw cross-correlation)      -- 6.4.06 reports "not available"
#
# They are the 6.6-era names, and jitter and shimmer sit downstream of the
# second one. On a sandbox below the target those four are recorded as UNRUN,
# with the version that could not run them, rather than skipped in silence. A
# harness that quietly tests three things and reports success for seven is
# worse than no harness. v52 pins all seven parameter lists statically either
# way; only the argument-ORDER evidence is version-gated.
#
# 14 Aug 2026: 6.6.30 was installed and all seven now run. The gate stays --
# it costs nothing when the version is right, and it is the only thing standing
# between an old sandbox and a green report over four calls that never
# executed. MEASURES.tsv carries praat_version so the evidence can never be
# read as stronger than the build that produced it.
#
#     praat --run harness/acoustic/drive.praat
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

out$ = "out/MEASURES.tsv"
deleteFile: out$

appendFileLine: out$, "praat_version" + tab$ + praatVersion$
appendFileLine: out$, "at_target_version" + tab$
    ... + string$ (praatVersion >= 6630)

snd = Create Sound from formula: "probe", 1, 0, 2.0, 44100,
    ... "0.5*sin(2*pi*120*x) + 0.3*sin(2*pi*240*x)
    ... + 0.2*sin(2*pi*360*x) + 0.1*sin(2*pi*480*x)"

# ---------------------------------------------------------------------------
# THE TWO PITCH CHAINS, and everything downstream of the second one
# ---------------------------------------------------------------------------
if praatVersion >= 6630

    # --- S1A: mean F0, filtered autocorrelation. 11 positional arguments. ---
    selectObject: snd
    fac = noprogress To Pitch (filtered autocorrelation):
        ... 0.0, 50, 800, 15, "no", 0.03, 0.09,
        ... 0.5, 0.055, 0.35, 0.14
    selectObject: fac
    f0 = Get mean: 0, 0, "Hertz"
    appendFileLine: out$, "meanF0" + tab$ + fixed$ (f0, 4)

    # --- S1B: pitch for voice quality, raw cross-correlation. 10 arguments. -
    # THE CEILING SITS THIRD HERE. If this signature still placed the ceiling
    # last, this call would set max-candidates to 600 and the ceiling to 0.14,
    # and it would not error -- it would return a number.
    selectObject: snd
    rcc = noprogress To Pitch (raw cross-correlation):
        ... 0.0, 75, 600, 15, "no", 0.03,
        ... 0.45, 0.01, 0.35, 0.14
    selectObject: rcc
    f0rcc = Get mean: 0, 0, "Hertz"
    appendFileLine: out$, "meanF0_rcc" + tab$ + fixed$ (f0rcc, 4)

    # --- S3A: PointProcess from Sound + Pitch -------------------------------
    selectObject: snd
    plusObject: rcc
    pp = noprogress To PointProcess (cc)

    # --- S3B: jitter --------------------------------------------------------
    selectObject: pp
    jit = Get jitter (local): 0, 0, 0.0001, 0.02, 1.3
    appendFileLine: out$, "jitter_local" + tab$ + fixed$ (jit, 6)

    # --- S3C: shimmer. Needs PointProcess AND Sound selected together. ------
    selectObject: pp
    plusObject: snd
    shim = Get shimmer (local): 0, 0, 0.0001, 0.02, 1.3, 1.6
    appendFileLine: out$, "shimmer_local" + tab$ + fixed$ (shim, 6)

    appendFileLine: out$, "pitch_chains_ran" + tab$ + "1"
else
    appendFileLine: out$, "pitch_chains_ran" + tab$ + "0"
    appendFileLine: out$, "unrun_commands" + tab$
        ... + "To Pitch (filtered autocorrelation);"
        ... + "To Pitch (raw cross-correlation);"
        ... + "Get jitter (local);Get shimmer (local)"
endif

# ---------------------------------------------------------------------------
# THE THREE THAT RUN AT ANY VERSION
# ---------------------------------------------------------------------------

# --- S6: mean intensity ------------------------------------------------------
selectObject: snd
intId = noprogress To Intensity: 100, 0.0, "yes"
selectObject: intId
intv = Get mean: 0, 0, "dB"
appendFileLine: out$, "mean_intensity" + tab$ + fixed$ (intv, 4)

# --- S2A: HNR ----------------------------------------------------------------
selectObject: snd
harm = noprogress To Harmonicity (cc): 0.01, 75, 0.1, 1.0
selectObject: harm
hnr = Get mean: 0, 0
appendFileLine: out$, "hnr" + tab$ + fixed$ (hnr, 4)

# --- S5: CPPS, Maryn et al. parameter set ------------------------------------
selectObject: snd
cep = noprogress To PowerCepstrogram: 60, 0.002, 5000, 50
selectObject: cep
cpps = Get CPPS: "no", 0.01, 0.001, 60, 330, 0.05,
    ... "parabolic", 0.001, 0, "Straight", "Robust"
appendFileLine: out$, "cpps" + tab$ + fixed$ (cpps, 4)

appendFileLine: out$, "completed" + tab$ + "1"
writeInfoLine: "acoustic drive complete"
