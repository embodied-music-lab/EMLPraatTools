# Lane report — survey core statistics (Lane B)

Fable 5 cowork session, 17 August 2026, on Ian's brief of the same date.
Branch: lane/survey-core-stats (new files only; no existing file touched;
not pushed to main).

## What was built

Two kernel modules under plugin/stats/, in the house style, raw values
out, nothing printed, .error$ always present, validation before
computation:

- eml-psychometrics.praat — @emlCronbachAlpha. Input is one matrix
  (rows = respondents, columns = items). Outputs alpha, the Feldt 95%
  CI, k, n, .nExcluded (listwise deletion, disclosed), the
  alpha-if-deleted vector, .error$.
- eml-categorical.praat — @emlChiSquareIndependence (matrix of counts;
  outputs chiSq, df, p, Cramér's V, minExpected, nCellsBelow5,
  .warning$, .error$) and @emlWilsonInterval (successes, n, confidence;
  outputs propHat, ciLow, ciHigh, .error$).

Dev tests (67 checks), a literal-verification companion, three live
Praat-vs-R validators (165 checks), committed fixtures, a committed
oracle dump, and a one-command lane runner. Everything greens on Praat
6.6.30 barren:

    lane/survey-stats/run_lane.sh
    -> dev tests 20 + 47 PASS; literals ALL VERIFIED;
       v90 48/48, v91 68/68, v92 49/49; three RED demonstrations
       each exit 1 as required.

## Oracle agreement figures

- Alpha: agrees with R psych::alpha at 1e-10 on alpha and on every
  alpha-if-deleted value, and at 1e-8 on both Feldt bounds (the looser
  tolerance covers Praat's invFisherQ vs R's qf; observed agreement was
  10 decimals on every fixture). Fixtures: clean 5-item (alpha .8493),
  the same scale with an unreversed reverse-scored item (alpha falls to
  -.1410 — the brief's directional pin holds), 2-item edge, and a
  missing-cells fixture (3 rows excluded, disclosed, values match psych
  on the complete rows).
- Chi-square: agrees with R chisq.test at 1e-10 on statistic, df, p for
  all four tables with correction both on and off; Cramér's V, smallest
  expected count and the below-5 cell count agree at 1e-10; the warning
  fires exactly when R's expected matrix has a cell below 5.
- Wilson: agrees with R prop.test(correct = FALSE) at 1e-10 on both
  bounds across all nine cases, including x = 0 and x = n, where the
  interval is asserted to keep positive width (the Wald failure mode).
  The oracle itself is pinned against two printed values from Newcombe
  (1998), Table I.

## Negative controls (each validator can go red)

Each v-script seeds a deliberate defect into a scratch copy of the
kernel under tempdir(), drives Praat on it live, and (green mode)
asserts the defective value DIFFERS from the oracle; run_lane.sh also
re-runs each with EML_LANE_RED=1, which pits the standard named
agreement check against the defective build and requires exit 1.
Transcripts are committed under lane/survey-stats/evidence/.

- v90: variance denominator n for n - 1 -> alpha .8660 vs oracle .8493, red.
- v91: Cramér's V denominator min(r,c) for min(r,c) - 1 -> V .1723 vs
  .2110, red.
- v92: one-sided z for two-sided -> lower bound .3274 vs .2993, red.

All pins read source or drive Praat live; no check has a committed
artefact as its only input.

## Decisions taken

1. File split: two files, as the brief suggested — alpha is
  psychometrics, chi-square and Wilson are categorical. Headers stay
  clean and the future signal/categorical growth paths stay separate.
2. Signatures: both table-shaped inputs are matrix## (respondents x
  items; r x c counts). That is the cleanest kernel signature in Praat;
  Praat-Table wrappers belong to the door/orchestrator phase and are
  listed in PROPOSALS.md as vocabulary notes only.
3. Continuity correction: explicit 0/1 parameter, live only on 2 x 2,
  accepted-and-ignored above 2 x 2 (exactly R's behaviour). The header
  tells callers to pass 1 to match R's default, since Praat procedures
  cannot default an argument. Both settings are oracled on every table.
4. Cramér's V comes from the UNCORRECTED statistic always — the
  standard (DescTools) definition; the correction adjusts the test, not
  the effect size. Documented in the header, oracled both ways.
5. Alpha-if-deleted at k = 2 returns undefined, diverging from
  psych: psych prints a covariance ratio (C[1,2]/C[2,2]) there, which
  is not an alpha — a one-item scale has none. The header says so; v90
  asserts the undefined.
6. Zero row/column margins in the contingency table are refused with a
  message. R returns NaN there; house rule is refuse rather than
  compute nonsense.
7. Wilson endpoints are pinned exactly: at x = 0 the lower bound is set
  to 0 and at x = n the upper to 1 (the algebra cancels exactly; the
  pin removes ~1e-17 floating-point residue that would otherwise leak a
  bound of -3e-17).
8. Oracle substitutions forced by the sandbox (CRAN unreachable; only
  apt packages installable): psych came from r-cran-psych 2.4.1;
  DescTools and binom are not packaged, so Cramér's V is hand-computed
  in the validators from chisq.test's uncorrected statistic (the brief
  allows "DescTools/hand-computed") and Wilson uses base R's
  prop.test(correct = FALSE), whose CI is the Wilson score interval —
  the same numbers binom::binom.confint(method = "wilson") returns —
  plus the two Newcombe print pins. Praat floor met exactly: 6.6.30
  barren (praat6630_linux-x64v3-barren from the praat.github.io
  releases; the praat/praat repo API is egress-blocked, as the
  2026-08-05 handoff already recorded).
9. v90 needs the psych package, which breaks the validate/ suite's
  base-R-only charter. Left unregistered (as the brief requires anyway)
  and flagged in PROPOSALS.md for the merging session to rule on.

## Surprises, stated plainly

- Praat 6.6.30 has no elementwise matrix division and no min/abs over a
  matrix: m## / n and m## / m## are both errors. The chi-square kernel
  therefore does its per-cell work (min expected, below-5 count, the
  statistic, Yates) in one small loop rather than the vectorized form
  the style rules prefer; expected counts still come from outer## and
  scalar multiplication. Noted here because the master prompt's
  vector-first rule reads as if those idioms existed.
- psych's 2-item alpha.drop quirk (decision 5) was the only oracle
  disagreement of any kind in the lane.
- The unreversed-item fixture drops alpha from .85 to -.14 — negative,
  not merely lower. Good teaching number; kept.

## Post-delivery round, 17 Aug (verification relay, Ian's rulings)

1. Correction accepted, and my earlier claim narrowed: the surprises
  section above said the vectorized form was unavailable. The `/`
  operator on matrices is indeed absent, but the composed idioms exist
  and I re-probed them here on 6.6.30 before using them: elementwise
  division as a## * (b## ^ -1), abs## over a matrix, the non-negative
  clamp as (x + abs##(x)) * 0.5 — all confirmed numerically. My own
  follow-up probe added: row# (m##, i) works and min () reduces a
  vector. On comparison I initially over-claimed the same way: the
  comparison OPERATORS refuse vector/matrix variables in script
  expressions ("Cannot compare (<) a numeric vector to a number",
  Praat's own message), but the capability exists through the object
  route — Create simple Matrix from values:, Formula: ~ self < 5,
  Get sum / Get minimum — probed and confirmed numerically on 6.6.30.
  The kernel keeps its minimal loop per Ian's ruling (the object route
  would put object creation and removal inside a kernel that currently
  touches none), but the record here states the idiom accurately.
2. Chi-square kernel vectorized per Ian's ruling: the statistic is now
  sum (dev## * dev## * (expected## ^ -1)) and Yates is the abs##/clamp
  form; the only remaining loop covers the two diagnostics Praat has
  no reduction for (smallest expected count — reduced per-row through
  row#/min — and the below-5 cell count), with the probe cited in a
  comment. Validators and dev tests were not touched and stayed green
  identically (47 dev checks, v91 68/68, red demonstration exit 1) —
  the pins held through the rewrite, which is what they are for.
3. v90 base-R oracle patch adopted as my own commit, with amendments:
  fixture-labelled cross-check names; alpha and the Feldt CI now
  cross-check against psych at every k including the 2-item fixture
  (only the alpha-if-deleted vector skips at k = 2, where psych prints
  a covariance ratio); the direction pin reuses the loop's oracle so
  no cross-check is emitted twice. Verified on this side: 62/62 with
  psych installed, 47/47 with psych hidden via an empty R_LIBS, red
  demonstration exits 1. Decision 9's charter flag is resolved;
  PROPOSALS.md sections 3, 4 and the resolution note updated.
4. Evidence transcripts under lane/survey-stats/evidence/ were
  regenerated by this session's own runner (the relayed commit carried
  the verifier's transcripts; author-of-record runs replace them).

## What was NOT done, per the brief

No menu registration, no orchestrator or export wiring, no run_all.R
edit, no MANIFEST edit, no scale-scoring/reverse-coding workflow, no
omega, no proration. Registry lines live in PROPOSALS.md only.
