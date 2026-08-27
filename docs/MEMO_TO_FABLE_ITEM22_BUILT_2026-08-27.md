# Memo to Fable — item 22 is built; five questions before the edits

27 August 2026. The build landed and is green: `v147` 1477 of 1477, the new
`v148` 46 of 46, both re-run here rather than taken from the agent's report.
Nothing is committed. No further edits until you answer.

## What is in the tree

Plugin: the reason fields on all three kernels, the cutoff predicate holding
the module's one executable `1290`, four `p method` rows, two footer lines,
the explanations default at both sites, and the `@emlBridgeCorrelation`
dispatch fix.

Validation: `v147`'s dark checks inverted, its door census widened, the new
`v148` carrying the gate-based explanation-class check and its red demo, and
the kit extracting `p method` as a compared quantity.

## 1. An existing dev test contradicts your ruling on purpose

`plugin_EML_StatsGraphs/dev/tests/phase2/test-workflow-verification.praat`
asserts `default emlShowExplanations = 1`. Its changelog, dated 8 August,
says the expectation was moved from 0 to 1 deliberately, with the reason
written beside it "so it is not moved back."

Your scripting-path ruling moves it back. The test now fails, and it fails
for the right reason.

Confirm the supersession, and say what the replacement note should record.
Left as is, the next reader finds a comment instructing them not to change
what we just changed.

## 2. Mann-Whitney now states one fact three times

The report carries, within twenty-five lines:

- `p method` (new, DISCLOSURE, line 5265)
- an explainer reading "P-value computed by normal approximation with
  continuity and tie corrections (used when either group has n >= 50, or
  ties are present)" (existing, EXPLANATION, gated)
- `Method` (existing, line 5290), printing the same bare tag

The new row and the old `Method` row say the same thing under different
labels. The explainer states the branch conditions the new row now
discloses, and it disappears when explanations are off.

Options: retire `Method`; retire the explainer; keep all three. Not decided
here.

## 3. The Spearman collision shape, for your gate inspection

The dispatch short-circuits on ties and never calls the kernel, so it cannot
learn from the kernel whether `n` is also above the cutoff. It now asks the
predicate directly on the ties path and composes
`t approximation (ties present, large sample)` when both hold.

This satisfies ruling 1 and keeps one copy of the constant, but the shape is
mine, not yours. Confirm or replace it.

## 4. Item 13's summary line does not name what it measures

Ian approved items 10 and 12 as worded and stopped at 13, because this line
never says what there is no departure from:

    No strong departure in the groups large enough to test (2 of 3 assessed).

Proposed:

    Assessed 2 of 3 groups; neither showed a strong departure from normality.

Underneath sits a question only you should settle. "Strong departure"
describes a magnitude, and the test reports significance. At large n,
Shapiro-Wilk rejects departures too small to matter, so the phrase can
overstate. The accurate form is "no group's test rejected normality."
Changing it touches every normality line in the plugin, not this one, so it
is raised rather than folded in.

## 5. Three items leave the kit list

Items 14, 15 and 16 are DISCLOSURE class but unreachable by the kit: 14 is
the wizard plan, 15 prints on a scatter figure, 16 prints above a reprinted
report, and the kit runs none of those paths. They belong to the door round.
Confirm.
