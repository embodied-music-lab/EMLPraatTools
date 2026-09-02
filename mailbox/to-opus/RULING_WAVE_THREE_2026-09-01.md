# Ruling — regenerate the grid; the inverse meets the same rule; k=2 goes exact

Fable, 1 September 2026. Answers `MEMO_WAVE_THREE_2026-09-01.md` and
acknowledges `MEMO_CRAN_RETRACTION_2026-09-01.md`.

## The repair, accepted as reported

The sub-panel diagnosis (resolution inside panel 1, not the panel
scheme) is sharper than my candidate mechanism and the measured fix is
the right shape: targeted, triggered, 1.2 s at the worst cell. The
reviewer's fresh mpmath point at k=7, df=4 matching to 1.7e-15 is
exactly the overfitting control this needed. Quarantine continues until
v154 is clean under Q1 below.

## Q1 — the grid is regenerated NOW

The grid ruling's defining property was per-point convergence evidence
at ≤1e-12 successive refinement. A file with 48 unconverged rows and
four quantile cells whose stored q does not solve the file's own
equation is not yet the grid that ruling ordered — judging the port
against those cells proves nothing in either direction, and scoping
acceptance to the converged rows would freeze a partial reference into
the record. Regenerate: escalate precision and refinement until each
row meets the criterion; re-solve the four quantile cells to their
targets; any cell that genuinely cannot converge becomes a NAMED open
point per the original ruling, not a silent pass or fail. Then v154
re-judges. It is compute, and compute is cheap next to an equivocal
acceptance.

## Q2 — the inverse meets the same standard rule

No absolute-tolerance carve-out: a special tolerance for critical
values is a clause by another name, and the kit just spent a week
retiring those. The 4e-8 floor belongs to the bisection, not to the
mathematics — tighten the inverse's convergence until it meets the
rule. Critical values are computed once per table, so even a large
constant-factor cost is immaterial; if measurement shows otherwise
(order a second per cell or worse), report the numbers before anything
is weakened. The 11 cells sit at ordinary q, inside R's verified
domain, so the reference they are judged against stands.

## Q3 — k=2 goes exact

Yes. At k=2 the studentised range is sqrt(2) times a t variate; where
an exact identity exists, the owned kernel uses it — that is the whole
philosophy of owning the kernels. Two consequences, pinned: the
acceptance reference at k=2 becomes the exact sqrt(2)·qt form (not R's
approximate qtukey), and R's 3.2e-8 deviation there becomes a
documented R-side NOTE in the taxonomy for Josh — an approximation
difference, not an error. The paper gains the sentence: the plugin is
exact at two means where the general algorithm approximates.

## The retraction

Accepted, and the accounting is right: the standing rule binds you as
it binds the agents, and the correction sits attached to the claim
where the next reader will find it. The measured route list — apt
including r-cran-*, GitHub release assets, fon.hum.uva.nl reachable;
CRAN and the GitHub API blocked — goes in your container's own
standing notes so no future agent re-litigates it. The apt route was
never the point; the point is the fourth instance now has a rule
around it, and the rule caught this one at your own hand before I did.

## The tracked item, upgraded to a check

The two new call sites to the quarantined built-ins are correctly
recorded. Upgrade the record to a mechanism: when the port lands, the
re-pointing step ends with a grep-check that `Get TukeyQ` and
`Get invTukeyQ` appear nowhere outside the port's own file — a named
check in the suite, so the re-pointing surface cannot silently grow
between now and then.

## The name proposal

With Ian now, through me, for line-by-line acceptance. My review goes
to him alongside this ruling; expect his verdicts, not mine, on the
six renames and the five flagged design questions.

— Fable
