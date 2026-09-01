# Memo — the designated ptukey oracle is measurably wrong, and it breaks §2 of the consolidated ruling

Opus, 1 September 2026. Reports wave one. One finding needs your ruling before
the port can be accepted or rejected, because the criterion you set cannot be
applied as written.

## The problem in one line

You ruled: "Oracle: `stats::ptukey` at the standard rule, mid and far tail, no
clause." Against that oracle the port fails 115 of 394 forward cells. The
oracle is what is wrong.

## The evidence, from three sources that share no code with the port

| k=5, df=3, q=56.818064 | value |
|---|---|
| Monte Carlo, 40M draws (mine) | 1.3417e-04 ± 1.8e-06 |
| Monte Carlo, 200M draws (the review agent's, separately written) | 1.355e-04 ± 8e-07 |
| scipy 1.17.1 `studentized_range.sf` | 1.3590e-04 |
| the port | 1.357e-04 |
| **R `stats::ptukey`** | **9.99e-06** |

R is thirteen times low, roughly seventy standard errors from the simulation,
at p ≈ 1.4e-4. That is not an extreme tail — it is a value a reader would see
printed in a post hoc table.

Monte Carlo assumes nothing. It draws k standard normals, takes the range,
divides by an independent chi scale, and counts. It shares no quadrature, no
algorithm, and no author with either the port or scipy. Two independent
simulations and one independent implementation all agree with the port.

The build sensitivity is not the mechanism here. Both Praat builds and R sit
together on the wrong side; scipy, both simulations and the port sit on the
other.

## The part that reframes the whole thread

At k=5, df=45, q=14.123877432410683 — the value this entire ptukey thread has
treated as ground truth:

- scipy: 5.381806e-12
- R: 5.664580e-12
- Praat x64v3: 5.664358e-12
- Praat intel64 and Ian's Mac: 5.671796e-12

**R's error at that point is about 5%. The Praat build difference we spent the
day characterising is 0.13%.** We were measuring a real defect against a ruler
that is bent in the same region, and the bend is forty times larger than the
thing being measured.

Praat's cancellation defect is still real — the flat absolute error is measured
and its mechanism is understood. What is no longer true is that R was the
correct answer it deviated from.

## What this breaks, beyond the port

Every far-tail Tukey comparison the kit has ever made used R's `ptukey` as the
reference. D-PTUKEY and D-PTUKEY-MID document a disagreement between Praat and
R in a region where R itself is unreliable. Their measured worst cases —
1.27e-3 and 8.3e-7 — are distances between two wrong numbers, not error
magnitudes. The clauses retire with the port anyway, so nothing needs
rewriting, but the record should not carry those figures as if they measured
accuracy.

## What I am not deciding

The oracle question is yours. The options I can see, without recommending one:

- **scipy as the oracle.** It agrees with both simulations everywhere tested.
  It would make the kit depend on Python as well as R, and scipy's own far-tail
  accuracy is established here only by Monte Carlo agreement, not independently.
- **Monte Carlo as a supplementary oracle in the far tail**, with R retained
  where it is verified accurate. Honest, but a stochastic oracle cannot support
  a 1e-9 rule — it would need its own tolerance, which is a clause by another
  name.
- **Scope the no-clause claim** to the region where R is verified accurate and
  name a different reference beyond it. This is the option that keeps the
  standard rule meaningful, at the cost of admitting the oracle has a domain.
- **Establish the truth independently** — a high-precision computation in
  arbitrary-precision arithmetic — and use that as the reference for the port's
  acceptance. Slowest, and the only one that ends the regress rather than
  moving it.

I have not touched the clauses, the ruling, or the port's acceptance status.

## Wave one, otherwise

Verified by a review agent that re-ran every validator itself rather than
trusting the reports, and confirmed no agent edited a file outside its boundary.

- **Two-way kernel**: 124/124 against real `car` 3.1.2, worst relative error
  4.5e-12, on four fixtures including the new unbalanced three-level one. Type
  III via `solve#` with D never materialised; Total about the
  observation-weighted grand mean.
- **One extraction per case**: exactly one `@eml_getGroupData` call per group
  where the pairwise loops previously re-extracted both groups every iteration.
  743 assertions across the phase2 suite, zero failures, no computed value
  changed — verified by rerun, not asserted.
- **Neither kernel is wired in.** That was deliberate, to keep the parallelism
  safe, and it is the next small step.

## One weak result, reported rather than buried

The result-state and LMM work went to a haiku agent and it is the one piece I
would redo. Its validator never calls the LMM path it claims to test — it calls
a clear procedure and checks that things were cleared. The review built the
real end-to-end reproduction and found the fix does clear genuine stale state,
but that a pre-existing guard already prevented the symptom the report
described. Sound defensive hardening; an overstated report; a validator testing
nothing reachable. My model choice was wrong for that task.

— Opus
