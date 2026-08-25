# Error-propagation census — results and triage

Verification session, 25 Aug 2026, against head `3e34b1a`. Run as a
workflow: one Sonnet agent per module classifying every call site with
quoted evidence, a Haiku merge. Full row-level data (252 rows) ships
beside this file in `error-census/` — producer, call site, verdict,
evidence per row. I spot-checked two of the sharpest claims against the
source myself before writing this; both confirmed.

## Headline

182 error-producing procedures, 247 call sites. Verdicts: 129 raise the
error properly, 22 swallow it but print a visible line, 19 swallow it
silently, 44 never check it at all, 33 provably cannot fail on their
path. So roughly one call site in four handles failure wrongly — and the
wrongness is not random; it follows the architecture.

## The systemic finding: checking by proxy

The dominant pattern (15 of the 20 unchecked sites in scripts/) is
checking failure by proxy: the caller gates on a derived count
(`.n >= 3`, `.nGroups <> 2`) instead of reading `.error$`. The producers
zero their numeric outputs on error, so a real failure — bad column
name, non-numeric cell — gets misclassified as "too few observations" or
"0 groups" and printed with a wrong, generic reason while the actual
error text is discarded. The wizard shows both extremes in one file: the
same helper is raised properly on three pages and proxy-gated on five.

## Individually serious, confirmed by my own read

- **A guard that passes a missing column.**
  `emlRequireNumericColumn` (`stats/eml-inferential.praat:3042-3078`)
  wraps its whole body in `if emlAuditColumn.error$ = ""` with no else:
  when the column does not exist, its own `.error$` is never set and the
  REQUIRE gate reports success. In shipped chains the miss is usually
  shadowed by a prior `@emlRequireColumnPresent` call, but the gate's
  own contract is broken, and any future caller that trusts its name
  inherits the hole. Confirmed at source.
- **Silent zero-fills in effect-size matrices.** On a Cohen's d or
  rank-biserial computation failure, the matrix cell keeps its `zero##`
  default (`eml-analysis.praat:369, :652` and two siblings) — a failed
  computation is indistinguishable from a true zero effect, in a matrix
  a user reads. This is the wrong-number class, not the missing-note
  class.
- **Shapiro-Wilk printed as undefined.** The standalone checker prints
  `W` and `p` unconditionally; when the test errors (zero range), the
  undefined values print instead of the error text the producer supplied.
- **"Both" mode drops a single-test failure.** In pairwise "both" mode a
  parametric-arm failure is disclosed only if the nonparametric arm also
  failed (`eml-analysis.praat:1729, :1735`); the two-group analog
  discloses correctly — drift between siblings.
- **Post-hoc skip reasons captured and never shown.** Three pairwise
  producers output `.skipReason$` for pairs they skip; the caller never
  reads it, while the RM/Friedman path prints its equivalent. Same
  drift-between-siblings signature.

## Out of scope or low priority

The mixed-model findings (optimizer errors converted to penalty values,
one captured error never read) sit in code that is tabled and menu-
unreachable by ruling — filed, not queued. The p-adjustment trio's
twelve unchecked sites need one determination: whether those procedures
can fail on already-validated input; if not, they are NOT-APPLICABLE
and should say so at the call sites. One producer (`emlBridgeCorrelation`)
is marked unused with zero call sites — a deletion candidate for the
reachability checker.

## Disposition — ruled by Ian, 25 Aug

Nothing known-wrong ships. All 63 mishandling sites are fixed before the
1.0 tag: the four confirmed user-facing items by hand first, then the
error-read lint, then the sweep to zero — every site fixed or
adjudicated provably-safe with its reason committed at the site. The
mixed-model sites are adjudicated to Phase 4 by the tabling ruling, with
that reason stated, not left as errors. Punch list lane 9 carries the
work order; the tag is not cut while the lint shows red.

The census TSVs are the working record; the lint supersedes them as the
living guarantee once built.
