# Three questions for Fable — what counts as a number

Executing session, 26 August 2026, against `0659ef9`. The evidence is
`docs/PARSE_PARITY_CENSUS_2026-08-26.md`, written the same day: 123 conversion
sites walked, 39 reading a user data cell, 28 able to publish a silent wrong
value, 22 of those reachable from a registered menu today.

Most of what the census found needs no ruling. A procedure that reads a cell
leniently where `@emlRunDescriptiveAnalysis` reads it strictly is out of step
with an existing canon, and bringing it into line is conformance work. Three
questions are not that. They ask what the canon should say.

---

## 1. Does hex count as a number?

**Measured.** A column of `70.1`, `0x1A`, `75.5`:

```
@emlRequireNumericColumn  error$=[]
@emlAuditColumn           nValid=3  nCoerced=0  note=[]
@emlExtractColumn         n=3  mean=57.199999999999996
bare Get value:           n=3  mean=57.199999999999996
```

`(70.1 + 26 + 75.5)/3`. The strict path accepts it, the audit reports the
column clean, and no disclosure fires.

**Why this one matters more than its frequency suggests.** Both doors agree,
and they agree on a wrong answer. The two-door comparison that caught the
decimal comma cannot catch this class at all: parity checking finds
disagreements, and this is a consensus. Every fix elsewhere in the census
inherits the hole until the canon closes it.

`@eml_classifyCell`'s stated contract is that the cell reads as the number it
looks like. `0x1A` does not look like 26 to anyone entering measurements.
There is a precedent for a carve-out — `30%` is classified coerced rather than
strict — but that was a decision, and this is the same kind.

`1e-999` belongs to the same question: it passes strict and silently
underflows to `0`.

**The question.** Should `0x` (and `1e-999`) be classified coerced, the way
`%` already is — accepted with disclosure rather than silently?

---

## 2. Whole-column veto, or row-wise exclusion with disclosure?

The two layers apply different conventions to the same bad cell, and both are
defensible.

- **Stats layer.** Reads row-wise, excludes the unusable cells, analyses the
  rest, and discloses. One bad cell in a hundred gives 99 rows analysed and a
  note naming the offender.
- **Graphs layer.** `@emlCheckNumericColumn` requires `.nBad = 0` before it
  will call a column numeric, so `@emlDescribeFilterNumericColumns` declines
  to OFFER the column at all.

So a user with one comma decimal in a hundred rows can run the analysis and
cannot draw the figure.

Neither is a defect on its own terms. Having both in one product is the
problem, and it is visible to the user as a capability that appears and
disappears depending on which door they came through.

**Note in the graphs layer's favour:** on the three shapes where the stats
strict path fails — whitespace-only, `0x1A`, `1e999` — the graphs rule is
correct, and it names the offending cell. The draw door is the stricter and
more robust of the two, which is the reverse of what the census expected.

**The question.** Which convention governs? If row-wise with disclosure wins,
the graphs layer relaxes and the exclusion-parity guard covers the difference.
If whole-column veto wins, the stats doors refuse columns they currently
analyse, which is a visible behaviour change and needs its own language.

---

## 3. The scan cap

`@emlCheckNumericColumn` stops scanning at `.maxScanRows = 100000` and
discloses that it capped. The stats layer scans every row.

A column whose only bad cell sits past row 100,000 is therefore clean to the
draw door and unusable to the analysis door. This partly overlaps punch item
7.3.

**The question.** Does the cap stay, and if so does the stats layer adopt the
same cap so the two agree, or does the graphs layer drop it?

---

## What proceeds without a ruling

For completeness, so this document is not read as blocking the rest:

- The whitespace-only crash in the canonical path
  (`stats/eml-extract.praat:895`, `:910`). A cell holding one space raises a
  raw Praat error and takes the whole script down. The procedure's own header
  says a probe handed a cell it cannot read must report `.unreadable`, not
  raise. Fixing it to match its own stated contract is conformance. The survey
  lane already solved this shape locally in `cdac83a`, so the wording exists.
- `@emlRunNormalityAnalysis` reading `"73,4"` as 73 where
  `@emlRunDescriptiveAnalysis` refuses the same cell. Two procedures
  disagreeing about one cell; the strict one is already correct.
- The four reshape sites that poison an intermediate table before the draw
  layer's exclusion-parity guard can see it.
- `@emlRunRegressionAnalysis` and `@emlOLSInfluence`, driven and confirmed
  publishing slope 0.95 where the truth is 1.0.
- `stats/eml-lmm.praat` — six ungated sites, zero calls to any gate. Not
  registered and not a live door, so this is a tripwire: it must not be wired
  up before it is gated.

— executing session
