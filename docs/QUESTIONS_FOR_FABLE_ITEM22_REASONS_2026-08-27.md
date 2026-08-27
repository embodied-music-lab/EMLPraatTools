# Question for Fable — the reason precedence on Mann-Whitney and signed-rank

27 August 2026. One question, raised by the approved item 22 strings.

## What the approved set requires

    normal approximation (ties present)     [Mann-Whitney, signed-rank]
    normal approximation (large sample)     [Mann-Whitney, signed-rank]

Two reasons, distinguished on the printed row.

## What the kernels do today

Measured at `2cd1e55`. Both procedures collapse the decision into one
flag, in `plugin_EML_StatsGraphs/stats/eml-inferential.praat`:

    .useExact = 0
    if .n1 < 50
        if .n2 < 50
            if .hasTies = 0
                .useExact = 1

Mann-Whitney sets its tag at lines 1899 and 1916; signed-rank at 2470 and
2514. Neither records which condition failed.

Two consequences.

**The handoff's "no kernel change" does not hold.** Printing the reason
needs a `.methodReason$` on both procedures, the same field Spearman
already carries.

**The two reasons are not mutually exclusive.** A sample can have ties and
50 or more observations at once. Today that is invisible because both
paths reach the same tag. The moment the reason prints, one of them has to
win, and whichever branch is written first wins silently unless the rule
is stated.

## The question

Which reason prints when both hold?

Spearman's dispatch answers the same question by testing ties first, on
the ground that ties make the exact distribution wrong rather than merely
unreachable. Whether Mann-Whitney and signed-rank inherit that precedence
is yours to say, not mine to copy.

A second form is possible and you may prefer it: one row naming both, for
example `normal approximation (ties present, large sample)`. It is not in
the approved set, so it is raised rather than assumed.

## What is not blocked

Everything else in the handoff builds without this answer: Spearman's row,
Pearson's `t distribution` row, the explanations default, the
`@emlBridgeCorrelation` dispatch fix, the door-census widening, and the
acceptance leg with its red demo.

## Two corrections to the handoff, for the record

**Four insertion sites, not three.** Pearson's row is a fourth, at
`eml-annotation-procedures.praat:6349`. Pearson has no method tag, so its
value is a literal at the report site.

**The explanations default is two lines, not one.**
`eml-output.praat:95` sets `emlShowExplanationsDefault = 1`, and line 114
hardcodes `= 1` again as a fallback when the variable does not exist.
Changing only line 95 leaves the fallback restoring explanations on any
path that reaches it.
