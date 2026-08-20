# Memo to Fable — the four dead controls

From the executing session, 20 August 2026. Ian's direction: this is a design
ruling, not his to answer one control at a time.

A hand-read of all 128 dialogs on 20 August found four controls that are drawn
and read on every pass but silently ignored by the code underneath for some
choice of a neighbouring control. Each is confirmed in the source; line
references are given so nothing here has to be taken on trust.

None of them can produce a wrong number. Every one of them can produce a user
who believes they chose something they did not choose, which is the failure
this plugin has spent the month removing everywhere else.

## The constraint that shapes every answer

Praat's dialogs are STATIC. A page is composed in full before it opens, and
nothing on it can appear, disappear, grey out or change in response to another
control on the same page. This is the same constraint behind the lagging-control
defects: a control whose relevance depends on a sibling cannot react to that
sibling within one press.

So "hide it when it does not apply" is not available as such. What IS available:

- **(a) Leave it, and let the label disclose the condition.** What three of the
  four do today.
- **(b) Remove the control.** The code picks, and the report states what it
  picked.
- **(c) Make the analysis honour it**, so it stops being dead.
- **(d) Re-show the page** when the sibling choice makes it inert, with a small
  box saying so. Costs one press, and only on the press that changed meaning.
  This is the shape used for the category-header guard and now for the
  correlation grouping guard.
- **(e) Move it to a later page**, composed after the deciding choice is known.
  The line-chart tree already works this way, so the pattern exists in the
  plugin and is not a new mechanism.

(d) and (e) are the two that did not exist as options when these controls were
written.

## 1. Histogram display mode

`graphs/eml-graphs-form.praat:7839` offers, whenever advanced mode is on:

    Display mode:  Overlap (transparent) | Faceted (stacked panels)

`graphs/eml-draw-procedures.praat:5809-5811` forces the mode to Overlap
whenever the table has one group or none, because faceting a single group
produces a viewport mismatch between the bars and the garnish.

So on ungrouped data the user picks "Faceted", gets an overlap, and is told
nothing. The condition is not disclosed in the label.

Note this one differs from the other three: whether it is dead depends on the
DATA, not on another control. The choice is made on the same page as the
grouping column, so (d) and (e) both apply; (b) is also clean, since with one
group the two options mean the same thing.

## 2. The regression dialog's group column

`scripts/eml-regress.praat:69` offers a group column, with "(none — overall
only)" as its first option. `:97` reads it. `:108` calls the analysis with
`tableId, respCol$, predCol$` and nothing else. `:145` passes it to the
DRAWING step.

So the group column changes the figure and never touches the regression. A
user who picks a group column gets one overall regression reported and a
figure drawn by group — and the wording "(none — overall only)" positively
implies that choosing a column gives them something other than overall.

This is the one with a real feature behind it: (c) means per-group regression,
which is a genuine addition and belongs on the roadmap rather than in a
defect fix. (b) — moving the control to the drawing step where it already
does its work — is the smaller honest answer.

## 3. The wizard's variance assumption

`scripts/eml-wizard.praat:403` prints "Variance assumption (parametric only):"
and `:406` offers the menu. The value is passed on both calls — `:442`
parametric, `:459` nonparametric — and `stats/eml-analysis.praat` reads it
only inside the parametric branch.

The label discloses the condition, which is why this is the mildest of the
four. But the page that chooses parametric versus nonparametric is EARLIER in
the wizard, so unlike the others this one is already on a later page — which
means (e) is not merely available, it is half-done: the wizard could simply
not compose this row when the earlier page chose nonparametric, at no cost in
presses and with no lagging control, because the deciding choice is already
made and cannot change on this page.

That makes this the one case where a strictly better answer exists with no
trade-off. Worth confirming that reading before it is built.

## 4. The three wrapper labels

    scripts/eml-pairwise.praat:46   Adjustment (t and Wilcoxon only)
    scripts/eml-pairwise.praat:50   T test type (pairwise t only)
    scripts/eml-compare-kw.praat:66 Adjustment (post hoc only)

Each sits beside the control that decides whether it applies — the Test menu
(Pairwise t-test / Pairwise Wilcoxon / Scheffe) in the first two, and a "Run
Dunn post hoc" tickbox in the third. All three are always shown and always
read; the parenthetical is the whole of the disclosure.

These are the ones where the compaction ruling's own reasoning cuts both ways.
The parentheticals are honest and short, and they are also three of the rows
the label sweep is trying to remove from tall pages. If they stay, they stay
by ruling rather than by default.

A fourth option specific to these: the comparison pages replaced test, post-hoc
and correction with ONE list of complete choices ("Kruskal-Wallis + Dunn, Holm
(step-down; more power than Bonferroni)"). The same collapse is available here
— "Pairwise t (Welch), Holm" as a single row — which removes two rows and two
dead controls at once. It is a bigger change than relabelling, and it is the
one that makes these pages read the way a methods section has to read.

## What is being asked

A ruling per control, from: leave and disclose, remove, make it work, re-show
on change, or move to a later page. And, for the three wrapper labels, whether
the one-list collapse already ruled for the comparison pages should extend to
the pairwise and Kruskal-Wallis wrappers.

Ian's standing position for context: ship scope is his, and the open list is
not a release gate. None of these blocks 1.0.0.

— executing session, 20 Aug 2026
