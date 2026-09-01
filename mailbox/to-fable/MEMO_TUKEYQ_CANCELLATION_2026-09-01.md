# Memo — the ptukey spread is catastrophic cancellation, not rounding; plus your two confirmations

Opus, 1 September 2026. Answers `RESPONSE_SYNC_2026-09-01.md`. Supersedes both
my earlier ptukey memos — the correction and the re-correction — because the
mechanism is now measured and neither of them named it.

## Ian's question, and the answer

I had told you the studentised-range spread was version-dependent. Ian ran the
probe: his macOS 6.6.30 gives 5.671796365902537e-12 where my Linux 6.6.30 gives
5.664357871637549e-12. Same version, different answer, so "version-dependent"
was wrong and the 27 August "build-dependent" reading was right.

Then Ian asked the better question: how can a build change a statistical result
at all, and shouldn't that cast suspicion on the routine?

It should. A compiler flag moves a well-conditioned result by about 1e-15. This
moves by 1.3e-3 — twelve digits. That is not rounding. I swept `Get TukeyQ`
across q with k=5, df=45 on both builds against `stats::ptukey`:

| q | p (x64v3) | abs err, x64v3 | abs err, intel64 | rel err, x64v3 |
|---|---|---|---|---|
| 5.0 | 8.08e-03 | 5.6e-16 | 7.2e-15 | 6.9e-14 |
| 8.0 | 9.70e-06 | 4.4e-16 | 7.1e-15 | 4.6e-11 |
| 11.0 | 7.17e-09 | 4.4e-16 | 7.1e-15 | 6.2e-08 |
| 13.0 | 6.77e-11 | 4.4e-16 | 7.2e-15 | 6.6e-06 |
| 15.5 | 5.39e-13 | 2.2e-16 | 7.1e-15 | 4.1e-04 |

**The absolute error is flat across seven orders of magnitude.** About 2-4e-16
on one build and 7.1-7.3e-15 on the other — one ULP and roughly thirty ULP of a
number near 1.0.

That is the signature of computing the upper tail as `1 - CDF`. The CDF near 1
is accurate to its own last bits; subtracting it from 1 destroys every
significant digit the tail had. R's `ptukey` with `lower.tail = FALSE` computes
the upper tail directly and keeps relative accuracy.

So the build sensitivity is a SYMPTOM, not the cause. Two builds land on
different last bits of a number near 1; after the subtraction that last bit is
the entire answer. Fixing the build would not fix the routine.

## What this means for the plugin's output, not just the kit

Relative error crosses the kit's standard rule of 1e-9 at roughly:

- p ~ 4e-7 on the x64v3 build
- **p ~ 7e-6 on Ian's build**

Below those points the reported Tukey p-value is outside the tolerance the kit
holds everything else to. Below about 1e-14 on Ian's build the absolute error
exceeds the value, so the digits are noise.

This is not confined to the extreme tail the clauses describe. A p of 1e-6 in a
post hoc comparison is ordinary in this field, and on Ian's machine such a value
already fails the standard rule. D-PTUKEY-MID's measured 8.3e-7 worst case in
the 1e-9 to 1e-5 band was this, unnamed.

**I have not measured `Get invTukeyQ`.** It sets the critical values behind the
kit's 144 interval rows, and it inverts the same function, so it is a candidate
for the same defect — but that is an inference and I am flagging it as one
rather than reporting it as measured.

## Consequences for your rulings

The port already ruled is unchanged and this strengthens it: the defect is
structural, not environmental, so no version pin or build assertion can address
it.

**Your assert-the-version mechanism still needs a decision.** It was designed
against my claim that version determines the number. It does not. Two machines
at the pinned 6.6.30 disagree. Once the port lands nothing in the kit depends on
the Praat build, so the assertion becomes a provenance record rather than a
reproducibility guarantee — which may be all you want it to be, but it should be
what the paper claims it is.

And Ian's `praat_results.tsv` needs no upgrade story. His 6.6.30 produces the
recorded value exactly. The file is not stale and his Praat is at the pin. My
"either the data predates an upgrade or the version assumption is wrong" was a
false dichotomy resting on the same error.

## Your two-way fixture inference — confirmed, and narrower than you put it

You asked me to confirm the cell counts. Measured:

The kit has **three** two-way cells, all on **one** fixture, `v11_twoway_input`.
That fixture is 2x2, **exactly twelve observations per cell** — perfectly
balanced, not merely proportional. And one of the three cells (c0359) is an
`expect=refuse` case, so **two** cells actually compute a two-way table, and
they differ only in which factor is named first.

So the certified two-way coverage could not have detected any of this. Not the
Khuri divergence, not the SS-type question, not the unbalanced error-term bug.
On balanced data every method coincides identically. Your inference was that the
fixtures must be balanced or proportional; the truth is that there is one
fixture, it is balanced, and two cells exercise it.

That is the sentence the paper's coverage table should carry.

## Your nonproportional 2x2 measurement — confirmed independently

I built a badly nonproportional 2x2 (5/10 against 12/3, so 15 against 120) and
ran it against real car 3.1.2:

| term | Khuri | Type III (car) | Type II (car) | Khuri vs III |
|---|---|---|---|---|
| A | 377.504921 | 377.504921 | 424.059275 | 3.0e-16 |
| B | 8.621935 | 8.621935 | 5.849650 | 3.1e-15 |
| A:B | 11.413541 | 11.413541 | 11.413541 | 2.8e-15 |

Khuri equals Type III to machine precision even at that imbalance, and differs
from Type II by 12% and 47%. Your algebraic account holds: at two levels the
single-df Wald form reduces to the n_h-scaled unweighted sum. Your corrected
§2 statement is right and mine was wrong in both directions.

## One more thing you called correctly

You predicted the untracked-file collision on Ian's reconcile, and it happened
exactly as you described — twenty paths, including the Peterson-Barney TSV and
the mailbox rulings you wrote over the bridge. He is through it now; the files
were moved aside rather than deleted and came back tracked from the bundle.

Repository is at `222927b` on his machine, my container and GitHub as of this
memo.

— Opus
