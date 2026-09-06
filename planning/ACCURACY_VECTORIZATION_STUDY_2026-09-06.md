# Accuracy of replacing interpreter reduction loops with Praat vector functions

The de-loop pass replaces hand-written `for` loops that sum, average, or
multiply data with Praat's built-in vector reductions (`sum`, `mean`, `inner`,
`mul#`, `mul##`). Those built-ins add numbers in a different order than a
left-to-right loop, so their results can differ in the last bit or two. This
study establishes whether that change ever makes a plugin result less accurate.

The short answer: for the pure reductions it never does, and it usually helps.
For sum-of-squares and matrix products the change is a net accuracy gain
measured against NIST's certified values, but it is not bit-identical and not
strictly no-worse for every individual output element. No case moves any value
within a million-fold of the kit's 1e-9 agreement tolerance.

This is the same principle already on record for R's `ptukey`: the target is the
required precision, not bit-for-bit reproduction. Here the plugin's own numbers
improve, so the relevant question is "no worse against a true reference," not
"identical to the version we happen to ship now."

## What the study compares

Each test computes a quantity three ways and scores the two plugin methods
against the reference:

- The **scalar** method is a left-to-right `for` loop — the current plugin code.
- The **vector** method is the Praat built-in — the replacement.
- The **reference** is exact. For the synthetic grid it is a Python `Fraction`
  sum, which is exact because every double is an exact rational. For the NIST
  datasets it is the published certified constant.

Error is reported in ULPs (units in the last place, relative to the value's
magnitude) for the synthetic grid, and in LRE (correct significant digits,
`-log10` of the relative error) against the NIST constants.

## The five measures

The **gate** is the maximum of `error_vector - error_scalar` across every test
point. A gate at or below zero means the vector method is never worse. For
`sum` and `inner` the gate is `+0.000` ULP. For sum-of-squares it is `+5` ULP.
For the matrix products it is `+1128` ULP, discussed under the caveats.

The **size sweep** runs the hardest conditioning (large mean, tiny spread) at
sizes from 10 to 20,000. Scalar sum error climbs with size; vector sum error
stays near zero. That is the pairwise-summation signature, and it is why the
result generalizes past the sizes tested.

The **conditioning sweep** covers well-scaled, wide-dynamic-range, catastrophic
cancellation, mixed-sign, and near-cancellation data, eight random seeds each at
n=2000. Across all 40 points, `sum` and `inner` are never worse, and a
well-scaled sum improves from about 16 ULP of error to 0.4.

The **NIST certified check** scores within-group and between-group sums of
squares on all 11 NIST StRD ANOVA datasets against the published constants.

The **matrix check** scores `mul#` (150x150) and `mul##` (60x60) element by
element against the exact `Fraction` product, four seeds each on well-scaled and
wide-range matrices.

## NIST certified results

The table lists correct significant digits (LRE) for the scalar and vector
methods against the certified value, for the datasets where the two methods
differ. Higher is more accurate; 16 is the double-precision ceiling.

| dataset | within: scalar to vector | between: scalar to vector |
|---|---|---|
| SmLs03 | 13.7 to 15.2 | 12.7 to 15.3 |
| SmLs06 | 10.3 to 10.3 | 6.5 to 9.3 |
| SmLs07 | 4.3 to 4.3 | 2.7 to 3.3 |
| SmLs08 | 4.1 to 4.3 | 2.2 to 3.3 |
| SmLs09 | 1.3 to 4.3 | 0.5 to 3.3 |

Across all 22 comparisons (11 datasets, within and between), the vector method
is more accurate in 14, tied in 7, and less accurate in 1. The single regression
is SmLs02 within-SS, 15.7 against 15.2 digits, where both methods are already
exact to the double-precision limit and the gap is rounding noise.

The hard datasets carry the message. On SmLs09 the scalar loop retains 0.5
correct digits of the between-group sum of squares, meaning it is effectively
wrong; the vector method holds 3.3. On the published accuracy stress cases, the
loop we ship fails and the built-in does not.

## Caveats

Sum-of-squares is not a pure reduction. It feeds a mean into a second reduction,
and on cancellation data the whole two-pass computation is dominated by the
algorithm, not by how the final sum is ordered. The `+5` ULP gate reflects two
of 40 synthetic points where the vector result is a few ULP worse, about 5e-16
relative. Against NIST, the same computation is more accurate, as the table
shows.

Matrix products are the one place where the vector method is not strictly
no-worse per element. Each output entry is its own sum of products, and
reordering that sum is a small win on most entries and a small loss on a few.
The built-in cuts the worst-case error per matrix by roughly half, but 2,450
individual entries across the test set came out a hair farther from truth, by at
most 1,128 ULP, or about 2.5e-13 relative. The matrix as a whole is more
accurate; individual entries carry no guarantee. Nothing here is a defect in
`mul#` or `mul##` — it is what reordering a sum does.

## What this means for the change

Vectorizing the pure reductions — `sum`, `mean`, `inner` — is safe on the
accuracy argument alone. Grade those cells bit-identical: a difference is a bug.

Vectorizing sum-of-squares and matrix products is a net accuracy gain that is
not bit-identical. Grade those cells against a tolerance of 1e-12 relative,
which is a thousand times tighter than the measured reassociation and a million
times inside the 1e-9 science tolerance. A cell that moves within that tripwire
is benign; a cell that moves further gets read by hand.

## Scope

The study covers three scalar reductions (`sum`, `inner`, two-pass
sum-of-squares) across five sizes and five conditioning classes at eight seeds,
two matrix primitives (`mul#`, `mul##`) across two conditioning classes at four
seeds, and all 11 NIST StRD ANOVA datasets against certified constants.

It does not sweep every random seed for the matrix primitives, does not cover
`outer` or cumulative reductions, and does not test complex or extended-range
inputs. The mechanism — pairwise reduction versus naive accumulation — is
consistent across everything measured, so the untested cases are expected to
follow, but they are untested.
