# Memo to Fable — the 19 locale rows do not close

27 August 2026. Your ruling expects the normality conformance fix to make the
fixture compare as both-exclude. It doesn't. R includes the cell, and R is
right to.

## What the fix changed

`@emlRunNormalityAnalysis` read each row with Praat's `Get value:`, which
coerces a cell instead of classifying it. The cell `73,4` came back as 73,
and the plugin reported 73 as data. The procedure now calls
`@emlExtractColumn`, the same extractor `@emlRunDescriptiveAnalysis` uses.

Measured on a four-row fixture whose last cell is `73,4`: both procedures
report `n = 3`. Before the change, normality reported `n = 4`.

That closes a contradiction inside the plugin. It does not close the
disagreement with R.

## What R does

`walkthrough/kit/run_analyses.R:168` converts `73,4` to `73.4` and includes
it. Nobody has changed that file's parsing; its last three commits are the
interval wiring, Scheffe, and the `p method` quantity.

So the fixture compares as plugin-excludes against R-includes, at `n = 3`
against `n = 4`. The 19 rows stand.

## Why R is the correct side

A single comma between digits is a decimal separator. R reads 73.4, which is
the value in the cell. The plugin refuses the cell entirely.

The plugin's refusal is defensible as a conservative contract while the parse
canon is paused, but it is not the same answer, and it is not the better one.

## The two ways to close the rows

**Teach the plugin to read 73.4.** That is the parse canon, which Ian paused.
It closes the rows by making the plugin correct.

**Teach R to exclude the cell.** That closes the rows by making the oracle
agree with the implementation it exists to check. This is the mirror failure,
adjudicated three times, and it is not on the table.

## Recommendation

Keep the clause and reword it. The existing text describes a defect that is
now half-fixed: it says two procedures disagree with each other and neither
reads 73.4. The first half is no longer true.

Proposed reason text:

> The plugin excludes a comma-decimal cell and discloses the exclusion; R
> reads it as 73.4 and includes it. Both plugin procedures now agree with
> each other, so the disagreement is with R alone, and R holds the correct
> reading. The clause stands until the parse canon lands.

The rows remain residue with a written reason, which is what the balance
invariant requires. They are not a failure of the run.
