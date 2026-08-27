# Questions for Fable — everything item 22 needs before one build

27 August 2026. Supersedes `QUESTIONS_FOR_FABLE_ITEM22_REASONS_2026-08-27.md`,
which contains an error corrected below.

Nothing is being built until you answer. The blocked and unblocked parts
touch the same file, the same report sites, and the same validators, so one
agent run costs less than two. Please answer all four questions together.

## Correction to the earlier memo

The earlier memo said signed-rank sets its method tag at lines 2470 and
2514. That is wrong. Those lines are in `@emlHodgesLehmannTwoSample`.
Signed-rank sets its tag at 2903 and 2927.

## The branch conditions, measured

Five procedures carry a method tag, not three. All line numbers are in
`plugin_EML_StatsGraphs/stats/eml-inferential.praat` at `2cd1e55`.

| Procedure | Line | Exact requires | Reasons to distinguish |
|---|---|---|---|
| `@emlMannWhitneyU` | 1822 | `n1 < 50`, `n2 < 50`, no ties | ties, large sample |
| `@emlWilcoxonSignedRank` | 2801 | `nNonzero < 50`, no ties, `nZero = 0` | ties, large sample, zero differences |
| `@emlSpearmanCorrelationDispatch` | 1499 | no ties, `n <= 1290` | ties, large sample |
| `@emlHodgesLehmannTwoSample` | 2397 | `n1 < 50`, `n2 < 50`, no ties | deferred by your ruling |
| `@emlHodgesLehmannPaired` | 3243 | as paired | deferred by your ruling |

The 50 thresholds are R's, not ours. `stats:::wilcox.test.default` uses
`exact <- (n.x < 50) && (n.y < 50)` for the two-sample case and
`exact <- (n < 50)` for the paired case. Verified against the running R.

## 1. Which reason prints when more than one applies

A sample can have ties and 50 or more observations at once. Today that is
invisible, because every failing condition reaches the same tag. Once the
reason prints, one has to win, and whichever branch is written first wins
silently unless you state the rule.

Spearman's dispatch tests ties first, on the ground that ties make the
exact distribution wrong rather than merely unreachable. Whether the other
procedures inherit that precedence is yours to say.

A second form is possible: one row naming every condition that applied,
such as `normal approximation (ties present, large sample)`. It is not in
the approved set, so it is raised rather than assumed.

## 2. Signed-rank has a third reason

`@emlWilcoxonSignedRank` also refuses the exact branch when any difference
is exactly zero, matching R. The approved set has no string for it.

Options: a third value, for example
`normal approximation (zero differences)`; folding it into an existing
value; or leaving zero differences undisclosed and saying so.

## 3. "Large sample" carries two different meanings

The same phrase covers `n >= 50` in the rank tests and `n >= 1291` in
Spearman. Both are documented implementation limits, and both are R's. A
reader comparing two reports sees one phrase standing for thresholds that
differ by a factor of 26.

Confirm the shared phrase, or name the thresholds differently.

## 4. The canonical classifier does not exist

Your acceptance leg says a default kit drive produces zero
explanation-class lines, "machine-checked by the canonical classifier."
There is no such classifier in `validate/` or `walkthrough/kit/`. Searched
for a shared definition of an explanation-class line; none is defined
anywhere.

A pattern match on `Why:` and known gloss text would be a classifier that
drifts the moment a gloss is reworded.

Proposed instead, for your confirmation: define an explanation-class line
as any line emitted from a site guarded by `emlShowExplanations`, and
derive the check from the gate rather than from the text. The gate is
already the plugin's own definition of the category, so the classifier
cannot disagree with the code it checks.

## What does not need an answer

These are ruled and will be built as specified: Spearman's row, Pearson's
`t distribution` row, the explanations default at both sites
(`eml-output.praat:95` and the fallback at line 114), the
`@emlBridgeCorrelation` dispatch fix, the door-census widening, and the red
demo raising the flag to show the lines return.
