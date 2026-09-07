To:       opus, sonnet, fable
From:     ian (ruling), recorded by opus per ORDER_FIVE_ITEMS_2026-09-06 item 2
Needs:    fable — add to the next rulings index
Blocking: nothing; this records a ruling already in force in the tree
Topic:    studentized-range grading tolerance

# Ruling — studentized-range family graded at required precision

Ian's ruling of 5 September 2026: the Tukey / studentized-range measures are
graded against R at the precision the reference actually supports, not at a
fixed 1e-9. The family threshold is `SR_REL = 1e-5`, with `SR_P_FLOOR = 1e-6`
for reportable p-significance. Required precision, not maximum precision, is the
standard.

This ruling lived only in the message of commit `eb146299` until now. It is
recorded here verbatim, per the PM's order.

## Supersedes

This ruling supersedes, for the studentized-range family:

- RULING_TUKEY_TOLERANCE_ATTRIBUTION (the per-cell solver-attribution probe),
- RULING_TUKEY_P_CELLS (the p-cell classification halves),
- RULING_ONE_RULE_ONE_ORACLE's grading clause (grade against exact truth at
  max(1e-12, 1e-9·|true|)), for this family only, and
- the characterization-split treatment that pushed the Tukey p, Tukey CI, and
  Scheffé F cells out of the pass/fail tally.

The Tukey p, Tukey CI, and Scheffé F now grade against R at `SR_REL` and pass.
The port-vs-arbitrary-precision demonstration (v154, port vs mpmath) stays
RECORDED, not graded — it attests to the port's quality, it is not a yardstick
imposed on the family.

## Recorded verbatim — commit eb146299 message

> studentized-range family: grade against the reference at required precision, not an arbitrary 1e-9
>
> Howell ruling 2026-09-05: the Tukey/studentized-range measures are graded
> against R (ptukey/qtukey) at the precision the reference actually supports,
> NOT at a fixed 1e-9. R's Copenhaver-Holland integration carries ~1e-4
> abs.tol; at the real operating point (Peterson-Barney k=10, df=1490) its
> error moves a bound by ~0.43 microhertz -- scientifically invisible.
> Required precision, not maximum precision, is the standard. Measured
> plugin-vs-reference agreement across the family is ~1e-5 or better, so
> SR_REL=1e-5 is the family threshold.
>
> This unwinds the earlier characterization-split treatment (which pushed
> these cells out of the tally rather than grading them): the Tukey p, Tukey
> CI, and Scheffe F now grade against the reference at SR_REL and pass.
>
> v156: Tukey p/CI and Scheffe F moved from characterize() back to check()
> at the srange tolerance (SR_REL, with SR_P_FLOOR=1e-6 for reportable
> p-significance). 2304/2304 pass, 48 below-floor.
>
> v150: the port-vs-quadrature ACCEPTANCE now grades at SR_REL. The two
> extreme-corner cells (k=5 df=3 ~5.8e-7; k=8 df=3 ~3.8e-8) exceed 1e-9 but
> pass at SR_REL. 5/5 acceptance, no failures.
>
> RECORDED, not graded: v154 (port vs mpmath arbitrary-precision, 123/123)
> stands as the demonstration that in edge cases unlikely in real data --
> far-tail df=3 -- the Praat port approaches the exact mathematical limit
> MORE closely than R or a double-precision python quadrature does. That is
> an attestation of the port's quality, not a yardstick imposed on the family.

— recorded by opus, 6 Sep 2026
