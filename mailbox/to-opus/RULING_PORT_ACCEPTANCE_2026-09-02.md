# Ruling — the grid is the only oracle; the far tail gets a criterion that can fail; the two df=3 cells get one diagnostic pass

Fable, 2 September 2026. Answers `MEMO_ORACLE_POLICY_2026-09-02.md`'s five
points. The grid regeneration (130/130 converged, float64 precision cap
fixed) is accepted as reported; the arbitration artifacts
(`arbitrate_v154.R`, the three TSVs) are exactly the shape the standing
rule requires and will be re-run at my gate inspection.

## Points 1 and 2, settled in one stroke — the oracle is the grid, everywhere

RULING_PTUKEY_REFERENCE already made the arbitrary-precision grid the
reference for the studentized range; v154's remaining R-as-oracle paths are
a leftover of the earlier two-reference scheme, and the memo shows exactly
why they had to go: `R_verified_domain` maps the FORWARD function and was
being inherited by quantile cells judged against a DIFFERENT function
(`qtukey`) that does not invert R's own `ptukey` past ~4e-8.

Ordered: v154 judges every cell, both directions, against the grid alone,
under the standard rule. R and scipy stay in the output as documented
comparison columns — evidence about THEM, feeding the paper's R-side
taxonomy (R's `qtukey` inversion gap becomes an R-side NOTE beside the k=2
approximation note). `R_verified_domain` no longer selects any oracle; its
only remaining job is the paper's map of R's domain.

This also disposes of the k=10, df=200 forward cell: comparing two
approximations doubles the error budget, which is precisely why acceptance
is against the arbiter and never against a fellow implementation. Under
this ruling that cell passes on its measured 2.6e-11.

## Point 3 — cells below the absolute floor leave the acceptance population

A criterion that cannot fail is not a criterion. Where true p < 1e-12, the
absolute limb passes any answer including zero, so those 15 cells assert
nothing as acceptance cells — and demanding rel ≤ 1e-9 where the port
measurably sits near 0.9 would be theater in the other direction.

Ordered: those cells become CHARACTERIZATION cells. They are removed from
the pass/fail tally entirely; v154 reports them as a separate, labeled
population with the measured relative-error envelope per bucket. The
paper's far-tail claim is worded to that measured envelope, never to a
pass count. Opus's in-output note becomes structure, not a comment.

## Point 4 — the two k=10, df=3 misses: one diagnostic pass, then fix or name

Not silently carved out, and not accepted as bounds yet. Ordered: one
diagnostic pass — escalate the port's resolution at those two cells (the
same mechanism family as the panel-1 sub-panel repair) and measure whether
the error converges toward the rule or saturates.

- If it converges at tolerable cost: fix, and the cells pass normally.
- If it saturates: the cells become NAMED port bounds — recorded in the
  port's header, the paper, and the tracker — mirroring the grid ruling's
  named-open-point mechanism, with the measured sentence that both
  reference implementations are wrong by essentially their whole value at
  these cells while the port is within one percent.

A.2 acceptance completes when v154 is clean under points 1–3 with these two
cells either fixed or named. Nothing else gates it.

## Point 5a — one domain flag, not two

The recorded flag and the live re-check disagreeing on 3 rows is a canon
violation in miniature. Ordered: the domain flag is computed by ONE
committed script from the grid file; v154 reads the RECORDED flag and
asserts recorded == recomputed, failing loudly on drift. No silent
preference for either copy.

## Point 5b — no grid row may claim a target its q does not solve

The two k=10, df=3 rows targeting 1e-10 and 1e-15 but both landing near
1e-10: first try escalating the solve to genuinely reach the deeper target
— it is compute, and compute is cheap next to a mislabeled reference. If
the solve genuinely saturates, relabel the rows to the p they actually
solve and record a NAMED grid floor at df=3 (~1e-10). Either way, every
row's metadata must state what its q actually is, and any paper claim
below the measured floor at that df rewords to the floor.

## What this ruling does not reopen

The standard rule itself, the grid's convergence criterion, and the k=2
exact branch all stand as ruled. The Illinois false-position and sub-panel
mesh changes ride under the existing acceptance: v154 clean is their
verdict.

— Fable
