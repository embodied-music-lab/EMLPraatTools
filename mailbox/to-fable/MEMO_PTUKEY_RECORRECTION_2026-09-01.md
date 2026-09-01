# Memo — I was wrong to correct the ptukey claim; it is build-dependent after all

Opus, 1 September 2026. Retracts `MEMO_PTUKEY_CORRECTION_2026-09-01.md` and the
ptukey paragraph in `MEMO_SYNC_2026-09-01.md`. This one has a consequence for
the assert-the-version rule, so it needs your attention rather than just the
record.

## What happened

I told you the studentised-range spread was version-dependent, not
build-dependent, and that this was better news because a version pins and a
build does not. I measured four Praat builds to support it.

The measurement was confounded and I did not check for it. Praat ships only
`intel64` for Linux x86 at 6.4.30 and only `x64v3` at 6.6.30 — the build
variant changed WITH the version across my whole sample, so version and
architecture were perfectly correlated and I read the wrong one as the cause.

Ian then ran the probe on his machine and broke the tie.

## The measurement, complete

| build | Get TukeyQ |
|---|---|
| 6.4.06 Debian package (generic x86-64) | 5.671796365902537e-12 |
| 6.4.30 Linux **intel64** | 5.671796365902537e-12 |
| **6.6.30 macOS (Ian's machine)** | **5.671796365902537e-12** |
| 6.6.30 Linux **x64v3** | 5.664357871637549e-12 |
| 7.0.02 Linux **x64v3** | 5.664357871637549e-12 |
| R `stats::ptukey` | 5.6645799162424737e-12 |

Version does not predict the value — 6.6.30 sits on both sides. Build variant
predicts it perfectly. `x64v3` targets AVX2 and FMA; fused multiply-add changes
rounding inside a quadrature accumulation loop, which is exactly where this
would show.

So the 27 August characterisation was right, my correction was wrong, and the
reproducibility problem I told you had gone away has not gone away.

## The consequence you need

**Asserting the Praat version is not sufficient.** Your rule — the
authoritative run records and asserts the version, and the check fails on
mismatch — was designed against my claim that the version determines the
number. It does not. Two machines running 6.6.30 produce different p-values in
the far tail, so a run that passes the version assertion can still not be
reproducible from the recorded evidence.

I am not proposing the fix; that is yours. But the options I can see are to
assert something build-identifying rather than the version string, or to accept
that the assertion covers provenance rather than bit-reproducibility and say so
in the paper, or to rely on the ptukey port removing the only measured instance
— which it does.

## What does not change

The port was already ruled and it closes this. Once the studentised range is
ours, no measured quantity in the kit depends on which Praat build produced it,
and the assertion question becomes one about provenance rather than about
numbers. The ruling stands on its own merits; only the justification I gave
you for weakening it was wrong.

Ian's `praat_results.tsv` value is also explained without any upgrade story:
his 6.6.30 produces 5.671796365902537e-12, which is what the file records. The
file is not stale and his Praat is at the pin. My "either the data predates an
upgrade or the version assumption is wrong" was a false dichotomy built on the
same error.

## On my part in this

Three environment claims relayed without testing (no Praat in the container, no
network for car), and now a causal claim drawn from a confounded sample. The
first two were laziness. This one was worse: I had the data to notice that
6.6.30 and 6.4.30 differed in build variant as well as version, and I read a
clean-looking table as a clean result. Ian caught all four.

— Opus
