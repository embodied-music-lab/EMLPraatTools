# Memo — the NIST criterion is one rule, not three families

Opus, 31 August 2026. Read before the wiring lands; the work order assumes a
structure `v19_nist_strd.R` does not have.

## What the order assumes

> the 22 between- and within-group df match the certified integers exactly;
> the 76 remaining certified quantities are scored by LRE ...; the 10
> residual-SD assertions are preserved; 98 checks total.

That reads as three families already implemented and needing transfer.

## What the code does

Measured in `validate/v19_nist_strd.R`. One loop, one rule, nine quantities:

    df.between   sumsq.between   meansq.between   statistic
    df.within    sumsq.within    meansq.within
    r.squared    residual.sd

Every one of them is scored the same way:

    plugin_lre <- lre(got(stat), certified)
    r_lre      <- lre(rv[[stat]], certified)
    pass if is.finite(plugin_lre) && plugin_lre >= r_lre - SLACK

There is no exact-integer branch for df and no separate residual-SD
assertion. df passes because an exact match yields infinite LRE, which
clears any threshold. 9 quantities x 11 datasets, less the quantities a
dataset does not certify, is the 98.

## Why it matters for the build

The wiring is not a transfer of three rules. It is a transfer of one rule,
plus new work to add the two special cases you want:

1. df compared as exact integers rather than by LRE. A real change: today a
   df that is wrong by a rounding artifact could still score high enough to
   pass, and an exact-integer test forecloses that.
2. residual SD asserted separately rather than folded into the common LRE
   pass. Also a real change, and I do not know from your order what the
   separate assertion should be.

Confirm both, or say the single existing rule ports as-is and the refinement
waits.

## One thing already true that the order treats as missing

> The R runner computes base-R results for the 11 NIST datasets (stop
> skipping them).

Base R is already computed, inside the same loop:

    s <- summary(aov(value ~ factor(grp), data = d))[[1]]

So this is a move, not a new implementation. The scoring in `validate/lre.R`
is reused untouched, as ordered.

## Status

Nothing wired. Two agents ran on the unblocked prerequisites: the MAXROW
regression test and the `tier` to `study` rename. The cap itself is raised to
25000 in `eml-result-writer.praat`; 18,009 was the requirement and a cap just
above it would fail on the next larger dataset.

Awaiting your answer on the two special cases before the criterion is wired.
