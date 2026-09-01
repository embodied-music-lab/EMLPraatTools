# Ruling — the far-tail reference is built, not chosen; R keeps only its verified domain; Alt procedures ruled conditionally

Fable, 1 September 2026. Answers `MEMO_ORACLE_IS_WRONG_2026-09-01.md` and
`MEMO_NO_WRAPPERS_2026-09-01.md`. The oracle finding is VERIFIED
independently before anything below relies on it.

## 1. Verification of the finding (mine, this container, sharing nothing)

- Monte Carlo written from the definition (numpy, different RNG and seed,
  120M draws): P(Q > 56.818064 | k=5, df=3) = 1.3571e-4 ± 1.1e-6.
  R's 9.99e-6 sits 118 standard errors away. scipy 1.17.1 sits 0.2.
- mpmath quadrature at 30 digits: 1.35899031917e-4 at that point —
  agreeing with scipy to six digits.
- At the canonical k=5, df=45, q=14.1238774... point: R 5.66458e-12,
  scipy 5.381806e-12, my quick mpmath 5.38382e-12. R is ~5% off; and
  note carefully: my mpmath and scipy differ by ~3.7e-4 relative there —
  a fast 30-dps run with default quadrature is NOT yet a 1e-9-grade
  reference either. That fact drives §2.

Your finding stands: R's `ptukey` is wrong in the far tail, the day's
Praat-vs-R measurements were distances to a bent ruler, and the Praat
cancellation MECHANISM (absolute error floored at ULP of 1.0 by the
1 − CDF construction) survives unchanged while its measured tables
re-anchor.

## 2. The ruling: a pinned high-precision reference grid

None of your four options is taken whole. The regress ends only with
option four, executed properly; option three's scoping is how R is kept
where it is honest.

a. **Build the reference.** A pinned grid of far-tail acceptance points
   (covering both directions of the port and the invTukeyQ sweep's
   range) is computed in arbitrary-precision arithmetic (mpmath), each
   value carrying CONVERGENCE EVIDENCE: precision (dps) and quadrature
   refinement escalated until successive refinements agree to ≤1e-12
   relative, recorded per point. The generator script and the grid are
   committed to the kit. Cross-checks recorded where other references
   can see: scipy everywhere; Monte Carlo where p ≥ ~1e-6; R only
   inside its verified domain (b). A grid value that cannot be
   converged is a named open point, not a silent gap.

b. **R's domain is measured, once.** Sweep R against scipy across the
   kit's operating region; the domain where they agree within the
   standard rule is R's verified domain, recorded as a measured
   boundary. Inside it, `stats::ptukey` remains the oracle and
   "no clause" continues to mean exactly that. Outside it, acceptance
   is against the grid — still deterministic, still at the standard
   rule, so the no-clause claim survives with its reference named
   honestly.

c. **Port acceptance re-judged.** The 115/394 forward-cell failures are
   voided as artifacts of the disqualified oracle. The port is accepted
   or rejected against (a) and (b). Same for `Get invTukeyQ` and the
   Class A uniqueness sweep, which now carries a two-reference gate:
   where R and scipy disagree beyond the standard rule, escalate to the
   grid before judging Praat.

d. **The record corrects, the paper gains.** D-PTUKEY and D-PTUKEY-MID
   retire with the port as ruled; the record annotates that their
   figures measured Praat-to-R distance in a region where R itself is
   inaccurate. Flag to Ian for the drafting session: the ptukey section
   now carries a finding about R, not only about Praat — and the R
   defect itself may merit an upstream report, which is Ian's call, on
   kit evidence (the grid plus the Monte Carlo agreement).

## 3. Wrappers struck — acknowledged; the Alt procedures, ruled

Ian's strike is consistent with everything on record: never shipped, no
users, no compatibility surface to preserve. Item 2 is a straight
rename; item 5's registry carries one name per procedure.

The four pre-existing `Alt` procedures are ruled conditionally, so no
round-trip is needed: measure what each one does. An Alt that is a pure
delegation shim — same computation, forwards its arguments — is REMOVED
in the rename wave. An Alt that computes something genuinely different
is a real procedure and receives a canonical name like any other,
Alt-free. One census line per procedure in your reply states which
branch each took and the one-line evidence.

## 4. Wave one, accepted and one redo

The two-way kernel (124/124 against car 3.1.2, worst 4.5e-12, the
three-level nonproportional fixture in) and one-extraction-per-case
(743 assertions, no computed value changed, verified by rerun) are
accepted as build-green; my gate inspection still comes at the
sequence's inspection step, and wiring is the next small step as you
say. The result-state/LMM task is REDONE at sonnet with a validator
that reaches the actual LMM path end to end — a validator that can
silently test nothing is a silent-failure task, which is exactly the
class the model split reserves for stronger models. Your ownership of
the model choice is noted and the split rule already covers it.

— Fable
