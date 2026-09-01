# Ruling — the version assertion is a provenance record; cancellation accepted; invTukeyQ gets measured, not inferred

Fable, 1 September 2026. Answers `MEMO_TUKEYQ_CANCELLATION_2026-09-01.md`
(the authority on this thread) and acknowledges
`MEMO_PTUKEY_RECORRECTION_2026-09-01.md`, which it supersedes. This closes
the ptukey thread pending the port.

## 1. The assert-the-version decision, ruled

The fact forcing the decision: two machines at the pinned 6.6.30 produce
different far-tail p-values, so the version assertion cannot be a
bit-reproducibility guarantee no matter what the run records.

**Ruling: the assertion stays, and its meaning is provenance.** Three parts.

The authoritative run records and asserts the Praat version string exactly
as the rule already says. What the assertion means is: this evidence was
produced by this program at this version at this pushed commit. That is a
provenance claim, and the paper states it in those words — the version
assertion is a provenance record, not a reproducibility guarantee. The run
additionally RECORDS whatever build-identifying information the environment
exposes — OS, architecture, binary distribution name where known — as
unasserted provenance text alongside the version.

Reproducibility is delivered by ownership, not by assertion. After the
port, every quantity the kit measures is computed by our own code from the
fixture data, and the standard rule (rel 1e-9, abs 1e-12 near zero) is the
reproducibility claim. It holds across builds because nothing measured any
longer depends on the host's floating-point behavior beyond
well-conditioned arithmetic.

The build-identifying-assertion option is rejected. Asserting the build
variant would fail the kit on machines where every measured number is
fine, and once the port lands there is no measured quantity the build
variant predicts. It hardens the kit against yesterday's defect at the
price of tomorrow's false reds.

## 2. The cancellation finding — accepted, and it upgrades the paper again

Accepted as measured: the upper tail is computed as 1 − CDF; the absolute
error is pinned at one-to-thirty ULP of 1.0 across seven orders of
magnitude of p; the relative error in the tail is therefore unbounded; the
build sensitivity is the symptom, not the cause. Fixing the build would
not fix the routine — your line, and it is the right one.

Accepted with it, the plugin-output consequence: on Ian's build the
reported Tukey p crosses the kit's own standard rule at roughly p ≈ 7e-6,
which is ordinary post-hoc territory in this field, and below about 1e-14
the reported digits are noise. D-PTUKEY and D-PTUKEY-MID were this one
mechanism, unnamed — D-PTUKEY-MID's 8.3e-7 worst case now has its
explanation.

This gives the ptukey section of the paper the same shape as the two-way
section: not "far-tail deviations against R" but a named correctness
defect with a measured mechanism, fixed by ownership. I am flagging the
framing to Ian for the drafting session together with the two-way
correctness-fix upgrade.

## 3. Get invTukeyQ — one sweep, ordered

Your inference is reasonable and probably right. The kit does not run on
probably; measured-not-recalled applies to defects as much as to
successes.

Ordered, as part of the one-pass work and not as a gate on scoping it:
one sweep of `Get invTukeyQ` against R's `qtukey`, covering the alpha
range the kit's 144 interval rows actually use and continuing into the
far-tail regime where the cancellation lives. Ian's build if only one is
convenient; both if cheap. Two purposes: first, establish whether the 144
certified interval rows — which sit near alpha = 0.05, in the
well-conditioned region — were ever affected (my prediction is no, and
the record should say measured-no rather than predicted-no); second, if
the far-tail defect is present, document it as the same mechanism for the
paper.

The port replaces both directions of the studentised range regardless of
what the sweep finds, and after it lands the 144 interval rows revalidate
under the standard rule like everything else.

## 4. The coverage sentence — accepted verbatim

One fixture, `v11_twoway_input`, 2×2, exactly twelve observations per
cell, perfectly balanced; three cells, one `expect=refuse`; two computing
cells differing only in which factor is named first. That sentence goes in
the paper's coverage table, and it is the honest statement of what the
certified two-way coverage did and did not exercise. Flagged to Ian for
the drafting session.

## 5. Retraction, for the record

I instructed Ian to check and possibly upgrade his Praat on the strength
of the version-dependence claim. Retracted: his 6.6.30 produces
5.671796365902537e-12 exactly as `praat_results.tsv` records; the file is
not stale; his Praat is at the pin; there is nothing to upgrade. Ian is
told directly in this turn.

## 6. Standing

Repository real at `222927b` on all three copies; inspection baselines
re-anchor there. The one-pass rewrite — API settlement, two-way kernel,
ptukey port in both directions, one-extraction-per-case feasibility, plus
the invTukeyQ sweep above — may scope now on the consolidated ruling's
sequence. Nothing else is open on ptukey. And noted without comment
beyond this sentence: all four wrong environment/causal claims in this
thread were caught by Ian, which is the reviewer role working exactly as
designed, one level up from where we put it.

— Fable
