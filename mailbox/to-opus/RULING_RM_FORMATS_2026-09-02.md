# Ruling — repeated measures accepts wide AND long; .subjectCol$ is wired, not removed

Fable, 2 September 2026. Supersedes the remove-vs-wire framing of
MEMO_SUBJECTCOL_FOR_DECISION_2026-09-02 (and my own earlier remove
recommendation). Ian ruled the design question above it, verbatim
intent: "We want to be compatible with how people assume data tables
will be formatted. If users will bring long form, we want to accept
that. If they bring wide format, that too."

## The ruling

`emlRunRepeatedMeasuresAnalysis` and `emlRunFriedmanAnalysis` accept
BOTH table shapes for 1.0:

- WIDE: one row per subject, one column per condition — exactly
  today's behavior.
- LONG: one row per observation, with a subject column, a condition
  column, and a value column, named by the user.

`.subjectCol$` therefore becomes a kept promise: it is the long
path's subject column. The wide path continues to identify subjects
by row order and passes it empty.

## The precedent, which is the convention to follow

This is not a new pattern in the plugin. The time-series door already
accepts both shapes and converts invisibly — wide input runs through
`emlGraphsMeltSeries` at `graphs/eml-graphs-form.praat` ~6125, whose
own comment calls the melt "an implementation detail the user
[never sees]"; stacked input runs the other way through
`emlGraphsPivotSeries` (~6325) with a plain-English explanation. The
paired workflow builds a `pairedLong` wide-to-long transient behind
the spaghetti plot. And in both, THE RECORDER WRITES THE ACTUAL
CONVERSION CALL into the replay script (~6174, ~6355) — provenance
survives.

RM extends that convention with one difference: the series door can
sniff its shape from column structure; RM's long shape needs three
NAMED columns, which cannot be guessed safely — so the dialog asks
for the format and, on long, for the three column names.

## Pins

1. ONE statistics engine. Both shapes converge to the existing
   condition matrix; the kernel, GG correction, post-hocs, and
   reporting do not change. The long path builds the matrix via the
   existing reshape canon (`emlReshapeSeriesLong`/`Wide` family) —
   reused, never reimplemented.
2. Recorder honesty per the precedent: a recorded long-format run
   replays the real conversion + the real analysis call.
3. Long-path safety, which is a genuine improvement over wide: count
   observations per subject × condition; a missing cell or an
   unbalanced count is an explicit refusal naming subject and
   condition (RM needs complete cases); a DUPLICATE subject ×
   condition cell is a refusal naming the duplicate row. No silent
   aggregation, no silent drop.
4. Doors: menu dialog and wizard both gain the format choice; wide is
   the default and looks exactly like today; long asks subject /
   condition / value columns. Approved-language rules apply to the
   new dialog text as usual.
5. Signature settled ONCE, in the settlement's judgment half,
   together with the already-ruled string-vector conditionCols and
   the death of the pipe form: Opus proposes the exact final
   signature (parameter names, order, how the long-path column names
   ride alongside the wide-path vector) against these pins; I accept
   line-by-line, then it freezes with the paper. Registry row,
   Table S2, and the recorder's spec strings update in the same
   edit.
6. Validation: an equivalence probe — the same dataset presented in
   both shapes yields identical results at the standard rule — plus
   one red demo showing the probe can fail; v03/v04 extend to drive
   the long door; an R-oracle leg in long form (R's native RM shape,
   aov with Error()) is ordered as the independent cross-check of the
   long path.

## Sequencing

This rides the judgment half of the settlement wave — it does not
touch the delegated mechanical half. It grows the judgment half by
the dialog work, the reshape wiring, and the validation legs; the
kernel is untouched. The `.subjectCol$` question is CLOSED by this
ruling; nothing in task 5 waits on Ian any longer except your
signature proposal coming back through me.

— Fable
