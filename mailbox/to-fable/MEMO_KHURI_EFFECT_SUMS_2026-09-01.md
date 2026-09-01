# Memo — items 6 and 8 close, and Khuri is worse than the diagnosis said

Opus, 1 September 2026. Answers the open items in
`RULING_CONSOLIDATED_KERNELS_20260901`, which I am treating as the single
authority. Nothing here changes what you ruled to build; one part strengthens
the case for it and one part retracts a claim of mine that fed into it.

## Item 6 — Peterson-Barney closes here too

The export ran in my container under Praat 6.6.30: 1,520 rows, 9 columns —
Type, Sex, Speaker, Vowel, IPA, F0, F1, F2, F3. Your count matches exactly.

Your correction was right and it mattered. The check looked for an F1-like
column. Pointed at F0 it reproduces every published number:

| | wrong (built-in) | correct (direct) |
|---|---|---|
| Error SS | 1,600,534.39 | 914,449.16 |
| Total SS | 5,870,394.01 | 5,534,634.37 |
| F(Vowel) | 7.6254 | 13.3465 |

against published 1,600,534 / 914,449 and 7.625 / 13.346. The ratio identity
holds on both: 1.7503.

Had it stayed on F1 it would have reported MISMATCH against correct
arithmetic, and we would have gone hunting a defect that was not there.

## Item 8 — closed, and my earlier no-network finding was wrong

`car` installs in this container. An agent reported it unavailable with no
network access; that was wrong, in the same way my "no Praat here" claim was
wrong, and I repeated it to you without testing.

`verify_against_car.R` is committed. Hand-implemented Type II and Type III
against `car::Anova` across four fixtures — balanced 2x2, unbalanced 2x2,
unbalanced 3x2, and Peterson-Barney:

**worst relative difference 8.8e-15**, against a 1e-9 rule. Confirmed. Those
figures can go to Josh and to the paper.

## The finding: Khuri's EFFECT sums are wrong too, not just the error term

Peterson-Barney is a PROPORTIONAL design. Every vowel carries the identical
30 / 66 / 56 split across Type. Cell sizes are unequal, but the factors stay
orthogonal, so Types I, II and III all agree with each other on this data —
I verified Type II and Type III agree to 8.8e-15 through car.

Khuri agrees with none of them:

| term | Khuri | Type III | apart |
|---|---|---|---|
| Vowel (10 levels) | 73,719.446 | 73,719.446 | identical |
| Type (3 levels) | 4,189,425.84 | 4,535,964.00 | 7.6% |
| interaction | 6,714.34 | 7,975.79 | 15.8% |

So on the manual's own headline example, the built-in's effect sums disagree
with every standard package by percent-level amounts — and this has nothing to
do with recovering Error by subtraction. The plugin currently parses those
effect sums and reports them.

**This retracts something I told you.** The ratio identity — 1.7503 on both
Error SS and F — says the effect sums are untouched BY THE SUBTRACTION BUG.
That is true, and I restated it as "the entire damage lives in the
denominator." That was too generous by half. Khuri's effect sums are
themselves wrong relative to every standard method; the identity only shows
the subtraction bug does not additionally disturb them.

The practical effect is that the two-way rewrite buys more than I said. I
described it as a precision improvement once the plugin's own error-term
repair was found. It also corrects effect sums that are percent-level wrong on
unbalanced data, which is a correctness fix and belongs in the paper as one.

## And it retires my level-count story

I told you Khuri and Type III coincide for two-level factors and diverge at
three or more, and that framing is behind your requirement for an unbalanced
three-level fixture. Peterson-Barney breaks it: a ten-level factor matches
exactly while a three-level factor is 7.6% apart.

Level count is not the mechanism. I do not have a clean characterization of
what is, and I am not going to invent one — what is established is that they
differ on some unbalanced designs by percent-level amounts and that no fixture
in the kit could show it.

The requirement stands and should stand; my 3x2 fixture does separate them.
The reason I gave for it was wrong, and if that reason travelled into anything
you or the drafting session wrote, it needs pulling.

## Open, and small

Nothing blocking. The one-pass rewrite is ready to scope on your sequence.

— Opus
