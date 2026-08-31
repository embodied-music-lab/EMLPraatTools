# Memo — answering the kernel-set assumption, and one risk it does not cover

Opus, 31 August 2026. Replies to the stated assumption in
`WORK_ORDER_API_SETTLEMENT_2026-08-31.md`.

## The direct answer

I know of no planned kernel math change beyond the two-way kernel. I
checked rather than recalled: there is no TODO, FIXME, or deferral
comment anywhere in `plugin_EML_StatsGraphs/stats/*.praat`. Nothing in
the source announces future math.

So on the narrow question — is the kernel set settled once two-way
lands — I have nothing to add to your list.

## What I would not let the assumption cover

Three of the seven live clauses in `compare.R` exist because a Praat
kernel disagrees with R's. They are documented divergences, not
defects, and none is scheduled to change. But each is a kernel change
waiting for someone to decide it is one:

- **D-WILCOXEST** (261 rows, the largest clause): Praat's Wilcoxon
  location estimate against R's Hodges-Lehmann.
- **D-PTUKEY** and **D-PTUKEY-MID**: Praat's studentized-range
  quadrature against R's `ptukey`.
- **D-ALPHA2ITEM** and **D-ALPHADROP**: Cronbach alpha edge behaviour
  at two items and under leave-one-out.

If any of these gets "fixed" after the authoritative run, the run
validated behaviour the release does not have. Your own rule — nothing
may first appear after the run — applies to them whether or not anyone
currently intends to touch them. I am not proposing we change them. I
am asking you to rule that we will not, so the clause text can say so.

## The risk the settlement does not reach

**D-PTUKEY is build-dependent, so it can change with no commit at
all.** Measured on the same input:

- this container's Praat: 5.66435787e-12
- Ian's machine: 5.671796365902537e-12
- R's `ptukey`: 5.6645799162424737e-12

The studentized-range statistic `q` is bit-identical across both
machines at 14.123877432410683. Only the tail integration differs. Two
Praat builds, one plugin commit, different p-values.

This matters for the frozen release specifically. "The rules were
defined before the run" is provable from commit history. "The plugin
produces these numbers" is not provable from commit history alone,
because the Praat build is an input the repo does not pin. The
authoritative run must therefore record the Praat build, which your
two-way order already requires, and the D-PTUKEY bound must be wide
enough to hold across builds rather than tuned to whichever machine
ran last. Its current ceiling is 5e-3 relative below 1e-9, which the
observed spread clears by a wide margin — but that margin is currently
an accident, not a stated tolerance.

**Question for you:** should the clause say explicitly that its bound
covers cross-build variation in Praat's quadrature, and should the kit
assert the recorded build rather than merely print it?

— Opus
