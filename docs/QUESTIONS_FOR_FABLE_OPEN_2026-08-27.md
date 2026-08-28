# Open questions for Fable — all of them, in one file

27 August 2026. Nothing is being built. Five questions, each with the
measurement behind it. The last one is Ian's proposal and it changes the
shape of two of the others.

## 1. The vocabulary wordlist catches two of eight

Measured against the eight distinct reason texts in your worked
`disagreements_all.tsv`: the wordlist flags two, because they contain
`D-PTUKEY` and `vmax`. It passes these, which are working-paper voice by any
reading:

    DOCUMENTED ABSENCE, R-side, under the definition-over-implementation rule...
    PRECISION CEILING, NOT A DISAGREEMENT. @emlRunTwoWayAnalysis does not compute...

A guard that catches clause ids but not `@emlRunTwoWayAnalysis` or
`definition-over-implementation` will pass most of what it exists to stop.

Widen the list, or accept that it guards the narrow case and the register is
enforced by review?

## 2. `coverage.md` has no generator, and the fixture can drift

`compare.R` does not generate `coverage.md` and never has. The only two
matches for "coverage" in that file are the words "coverage gap" inside two
clause reasons. Nothing in the kit writes it. You wrote it by hand.

That matters because the contract says the procedure-to-R-function map is a
committed fixture -- a second hand-maintained list beside the code. The
document already shows what drift looks like: the descriptive row omits
`lm`, which the handler does call for the trend line.

Fixture that can drift, or derivation from `run_analyses.R` that cannot?
Derivation has a real limit: the runner carries thirteen section headers for
seventeen procedures -- Cronbach, alpha influence, chi-square and Wilson
share one survey-lane section -- so a derived table is coarser than yours.

Ian's proposal in question 5 dissolves this.

## 3. The `lm` correction

`coverage.md`'s descriptive row lists `psych::describe` and `stats::t.test`.
The handler also calls `lm`. An earlier copy of the document had
`stats::lm (trend)` and this one dropped it. Per your rule I have not edited
the file.

## 4. Contract clauses have no clause id to key by

Your mapping is keyed by clause id. That works for the seven declared
clauses. Every contract row carries the single id `CONTRACT`, and those are
1,539 of 1,855 rows.

I keyed them by the `procedure` and `quantity` pattern that identifies them
in `quantities.tsv` -- the contract's own identity. Recorded in
`results_templates/reader_sentences.md`. Confirm or replace.

## 5. Ian's proposal: each side names what produced each value

Rather than maintain a map from procedure to R function, have both runners
emit the provenance of every value they write, and derive coverage from the
run.

Measured, current state:

| Side | `source` column today |
|---|---|
| Praat | the constant `praat`, on all 10,797 rows -- no provenance at all |
| R | package only: `stats`, `rstatix`, `effectsize`, `psych`, `afex`, `car`, `r` -- 7 values, no function |

So the R side is already halfway there and the Praat side has nothing.

**What it buys.** `coverage.md` becomes a report of what actually ran rather
than a claim about it, and it cannot drift, because a procedure that stopped
calling a function would stop emitting it. It also answers a question the
kit cannot answer today: for any single number in either table, which code
produced it.

**What it costs.** 224 emit sites on the Praat side and 193 on the R side.
Every one takes a new argument. That is mechanical but it is not small, and
it touches the two files the whole kit rests on.

**A cheaper middle.** Take the R side from package to function -- one
argument already exists there, it only needs a finer value -- and leave the
Praat side naming its procedure rather than its internal helper. That gives
the derived coverage table without 224 Praat edits.

Ian's instinct is that this is better than any map, and the drift in
question 3 is the argument for it.

## Status

Nothing built, nothing staffed. The reader sentences are drafted and
committed. Agents wait on Ian's go and on answers to 1, 2 and 5.
