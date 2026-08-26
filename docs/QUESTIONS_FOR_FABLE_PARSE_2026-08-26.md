# Three questions for Fable — what counts as a number

Executing session, 26 August 2026. Evidence:
`docs/PARSE_PARITY_CENSUS_2026-08-26.md` — 123 conversion sites walked, 39
reading a user data cell, 28 able to publish a plausible wrong value, 22 of
those reachable from a registered menu today.

The rest of the census needs no ruling: a door reading a cell leniently where
`@emlRunDescriptiveAnalysis` reads it strictly is out of step with an existing
canon, and conformance work does not need adjudicating. These three ask what
the canon should say.

---

## 1. Does hex count as a number?

**Measured**, column `70.1 / 0x1A / 75.5`:

```
@emlRequireNumericColumn  error$=[]                        <- door opens
@emlAuditColumn           nValid=3  nCoerced=0  note=[]    <- reports clean
@emlExtractColumn         n=3  mean=57.199999999999996
bare Get value:           n=3  mean=57.199999999999996
```

`(70.1 + 26 + 75.5)/3`. Accepted as strict, no disclosure.

`@eml_classifyCell`'s stated contract is that the cell reads as the number it
looks like. `0x1A` does not look like 26 to anyone entering measurements.
`30%` already has a carve-out and classifies as coerced.

**Why it cannot wait for the other fixes.** Both doors agree, and agree on the
wrong answer. Parity checking finds disagreements; this is a consensus, so no
cross-door comparison can ever surface it. Every other fix in the census
inherits the hole until this closes.

**Options.**

- (a) Classify `0x` as coerced, as `%` already is: accepted with disclosure.
- (b) Refuse `0x` outright.
- (c) Leave it strict.

`1e-999`, which passes strict and silently underflows to `0`, follows whatever
this decides.

---

## 2. Whole-column veto, or row-wise exclusion with disclosure?

The two layers apply different conventions to the same bad cell.

- **Stats layer:** excludes the unusable rows, analyses the rest, discloses.
  One bad cell in a hundred gives 99 rows and a note naming the offender.
- **Graphs layer:** `@emlCheckNumericColumn` requires `.nBad = 0`, so
  `@emlDescribeFilterNumericColumns` declines to offer the column at all.

A user with one comma decimal in a hundred rows can run the analysis and
cannot draw the figure.

**Relevant to the choice:** on the three shapes where the stats strict path
fails — whitespace-only, `0x1A`, `1e999` — the graphs rule is correct and
names the offending cell. The draw door is the stricter and more robust of the
two.

**Options.**

- (a) Row-wise with disclosure governs. The graphs layer relaxes; the
  exclusion-parity guard covers the difference. No visible behaviour change
  for analysis.
- (b) Whole-column veto governs. The stats doors begin refusing columns they
  currently analyse — a visible behaviour change needing its own language.

---

## 3. Does the scan cap stay?

`@emlCheckNumericColumn` stops at `.maxScanRows = 100000` and discloses that
it capped. The stats layer scans every row. A column whose only bad cell sits
past row 100,000 is clean to the draw door and unusable to the analysis door.
Partly overlaps punch item 7.3.

**Options.**

- (a) Cap stays; the stats layer adopts the same cap so the two agree.
- (b) Cap goes; the graphs layer scans every row.

---

## Proceeding without a ruling

Listed so this document is not read as blocking the rest.

- The whitespace-only crash in the canonical path
  (`stats/eml-extract.praat:895`, `:910`). One space in a cell raises a raw
  Praat error and takes the whole script down. The procedure's own header says
  a probe handed a cell it cannot read must report `.unreadable`, not raise.
  The survey lane solved this shape locally in `cdac83a`.
- `@emlRunNormalityAnalysis` reading `"73,4"` as 73 where
  `@emlRunDescriptiveAnalysis` refuses the same cell.
- Four reshape sites that poison an intermediate table before the draw layer's
  exclusion-parity guard can see it.
- `@emlRunRegressionAnalysis` and `@emlOLSInfluence` — driven and confirmed
  publishing slope 0.95 where the truth is 1.0.
- `stats/eml-lmm.praat` — six ungated sites, zero calls to any gate. Not
  registered, so a tripwire rather than a live door: it must not be wired up
  before it is gated.

— executing session
