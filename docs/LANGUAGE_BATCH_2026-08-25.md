# Language batch — every new or changed user-facing string, for approval

Verification session, 25 Aug 2026. Revision 5: item 10 re-derived against
the real remote head `3e34b1a` — the direction wording shipped there is
adopted, and the item shrinks to the ordering clause. This batch is
APPROVAL-READY, not certified final: any further push that lands wording
re-derives the affected item, exactly as item 10 was. Revision 4 (final editorial pass:
items 1, 2, 4, 10, 13, 18, 20 tightened — details in each item).
Revision 3. Revision 2 was the
adversarial pass for exaggeration and overgeneralization (items 4, 10, 11,
12, 15 corrected; 17-21 added). Revision 3 is the routing pass: because
explanations are OFF on several paths, every line is now classified either
DISCLOSURE — prints on every path, always, because it states what was or
wasn't computed — or EXPLANATION — prints only where the explanations
routing turns it on. A fact a user needs is never carried by a line the
toggle can remove. This is the one wording pass the punch
list requires before any form changes. Approve as a whole, or amend by item
number. Conventions applied throughout: the label character law (letters,
digits, and spaces before any parenthetical), one-list complete choices,
the terminology rulings (condition, within-subject, paired only at k = 2),
and ASCII in anything that reaches a saved report. Option-row text is not
label-derived, so parentheticals and dashes inside rows are safe.

## 1. Wizard: two-group test menu

Replaces the current five rows. The Both row runs Welch beside
Mann-Whitney, matching the menu door's single Both option and the plugin's
stated safer default.

    -- Parametric --
    Welch t (unequal variances; default)
    Student t (pooled variances)
    -- Nonparametric --
    Mann-Whitney U
    -- Both --
    Welch t and Mann-Whitney U

## 2. Wizard: paired test menu

Replaces the two-option "Test approach" menu with a one-list menu named
"Test".

    -- Parametric --
    Paired t-test
    -- Nonparametric --
    Wilcoxon signed-rank
    -- Both --
    Paired t-test and Wilcoxon signed-rank

## 3. Wizard: correlation test menu

Replaces the two-option "Test approach" menu with a one-list menu named
"Test".

    Pearson r
    Spearman rho
    Both Pearson and Spearman

## 4. Wizard: three-or-more-groups test menu

Replaces the current eight rows. Complete choices, no gating clauses
anywhere, omnibus-only rows added, and the pairwise grid opened to the
same choices the standalone pairwise dialog offers. Every pairwise row
carries a strictness gloss, restoring the caution gradient the old
standard/conservative/liberal labels provided: "(standard)" is the
conventional default, "(conservative)" harder to reach significance,
"(less strict)" easier.

    -- Parametric (one-way ANOVA) --
    ANOVA only, no pairwise tests
    Tukey HSD, all pairs (standard)
    Scheffe, all pairs (conservative)
    Pairwise Welch t, Holm (standard)
    Pairwise Welch t, Bonferroni (conservative)
    Pairwise Welch t, Benjamini-Hochberg (less strict)
    Pairwise Student t, Holm (standard)
    Pairwise Student t, Bonferroni (conservative)
    Pairwise Student t, Benjamini-Hochberg (less strict)
    -- Nonparametric (Kruskal-Wallis) --
    Kruskal-Wallis only, no pairwise tests
    Dunn, Holm (standard)
    Dunn, Bonferroni (conservative)
    Dunn, Benjamini-Hochberg (less strict)

The page paragraph above the menu, replacing the "If the overall test is
significant..." text:

    Pairwise comparisons run when you choose them, and every pairwise
    option adjusts for multiple comparisons. Tukey, Scheffe, Holm, and
    Bonferroni keep the chance of any false positive at or below the
    stated level; Benjamini-Hochberg instead limits the expected share
    of false positives, which is less strict. The overall test and the
    pairwise results are reported together.

(Dialog text, always visible — the explanations toggle does not apply to
dialog pages.)

## 5. Wizard: normality page scope

New menu on the wizard's normality check page, with a group column menu
that applies to the by-group choice.

    Check:
      One column
      All numeric columns
      One column, by group

## 6. Wizard: correlation group column

New menu on the wizard correlation page, wording taken verbatim from the
menu door:

    Group column:
      (none — overall only)
      [column names]

## 7. Wizard: group order

The existing control, added to the wizard's group-based pages verbatim:

    Group order:
      Table order
      Alphabetical

## 8. Wizard: paired figure columns

Taken verbatim from the menu door's paired dialog: the "Subject column"
menu with "(row number)" as its first option, and the optional "Group
column" menu with "(none)".

## 9. Menu dialogs: the explanations toggle

One boolean on every menu analysis dialog, default off:

    Annotate results with explanations

## 10. Direction and ordering line

DISCLOSURE — prints on every path, explanations on or off.

REVISED after the push: the direction half of this item shipped
(`095dddb`) in a better shape than the original draft — the subtraction
is named on the line that carries each signed number ("Mean diff
(C1 − C2)"), with convention notes on the signed matrices, instead of
one summary sentence. That shipped wording is adopted as approved; this
item now covers only the REMAINING half, the ordering clause on grouped
comparison reports:

    Group order: table order (pre, post).

Alphabetical runs print "alphabetical" in place of "table order". The
group list in the parenthesis is emitted in the order in force, from the
same procedure the analysis used — never re-derived by the reporter.

## 11. Cautionary line, non-significant omnibus

EXPLANATION — prints only where explanations are on. The fact itself (the
omnibus p) is in the report on every path, so nothing the reader needs
rides on this line. LEVEL is filled from the alpha in force at print time
— never a literal in the code:

    The overall test did not reach significance at the LEVEL level;
    interpret individual pairwise results with caution.

Rendered at the shipped default: "...at the .05 level..."; with alpha set
to .01: "...at the .01 level...".

## 12. Effect-size matrix caption, post-hoc off

Split by routing, because the second half is a fact the toggle must not
remove. DISCLOSURE, always printed above the matrix:

    No pairwise significance tests were run.

EXPLANATION, joining it where explanations are on:

    Effect sizes estimate the size of each pairwise difference.

## 13. Normality coverage lines

DISCLOSURE — coverage prints on every path; it states what was and wasn't
examined, and the explanations toggle never removes it.

The group-mode summary always states coverage:

    Assessed 2 of 3 groups; Alto (n = 2) too small to test (needs 3).

When coverage is incomplete, the recommendation line reads:

    Recommendation: parametric test is reasonable, based on the groups
    large enough to test.

The standalone checker's column summary, same condition:

    No strong departure in the groups large enough to test (2 of 3
    assessed).

## 14. Plan report values

The wizard plan's Test and Post-hoc fields, matching the new rows. Test:
"Welch t and Mann-Whitney U (both)", "Paired t-test and Wilcoxon
signed-rank (both)", "Pearson r and Spearman rho (both)". Post-hoc:
"None (effect sizes only)", "Tukey HSD, all pairs", "Scheffe, all pairs",
"Pairwise Welch t, Holm" (and the other adjustment/variant pairings named
the same way), "Dunn, Holm, all pairs" (and its variants). No value
contains a gating clause or a strictness gloss — the glosses teach on the
dialog; the plan states what runs.

## 15. Scatter page: relationship scope

The three-way display control from the punch list (lane 8.3), under the
scatter's analysis heading:

    Relationships shown:
      Per group
      Overall
      Both, each line labeled

The interim disclosure line, until the control lands — DISCLOSURE, on the
figure regardless of any toggle:

    This figure shows per-group relationships only.

(The earlier draft added "the overall relationship is in the report" —
false on the graph door, whose recomputed report is also per-group only.
The clause returns only on the correlation-dialog path, where it is true.)

## 16. Reprint notice

The one line above a reprinted report (store lane 1.2) — DISCLOSURE,
always printed; the store's honesty does not depend on a toggle:

    Data changed since this analysis was last run; re-measured.

Items 17-21 are all EXPLANATION-routed: they repair existing explainer
prose, and where explanations are off these lines are absent entirely —
never replaced by a shorter claim. Every number they gloss (p, d, r, W)
prints on every path regardless.

## 17. Existing explainer: the p-value gloss must speak at the alpha in force

`@emlWizardExplainP` hardcodes "the 5% level" and its bands at .001, .01,
.05, and .10. Under the alpha-in-force law, a user who set alpha to .01
still reads "statistically significant at the 5% level" for p = .03 —
wrong on its face. Fix: the gloss takes the level as an argument and its
significance sentence names that level; the "at least this extreme"
conditional-frequency wording is correct and stays. The .05-.10
"not significant, and not almost" band keeps its purpose but is restated
relative to the level in force.

## 18. Existing explainer: Shapiro-Wilk gets a normality gloss, not an effect gloss

The shared p gloss says "if there were truly no effect" — written to be
true for t, F, H, r, and a slope, and it is. It is false for
Shapiro-Wilk, where the null is "the data are normal" and a significant
result means departure, not effect. Normality reports get their own
sentence:

    If the data were truly from a normal distribution, results at least
    this extreme would occur less than PERCENT of the time.

PERCENT follows the same bands as the existing gloss (0.1%, 1%, 5%,
restated at the level in force per item 17).

## 19. Existing explainer: paired effect size is not in pooled units

The Cohen's d gloss says "the group means differ by X pooled standard
deviations." The paired path reports dz, whose unit is the standard
deviation of the differences, not a pooled one. The paired report's gloss
reads:

    The mean difference is [X] standard deviations of the differences.

## 20. Existing explainer: rank-biserial benchmarks are not Cohen's

The rank-biserial gloss labels its 0.1 / 0.3 / 0.5 cutoffs "Cohen's
convention." Those are Cohen's benchmarks for correlation r; rank-biserial
r is a different quantity on a different scale, and attributing the
cutoffs to Cohen overstates their authority. Fix: the exact reading moves
to the front, and the benchmark loses its false attribution:

    Rank-biserial r: the net proportion of cross-group pairs favouring
    one group. MAGNITUDE by common convention for r-family measures,
    read as a rough guide.

## 21. Existing explainer: correlation strength adjectives name their status

The Pearson/Spearman gloss prints "Weak / Moderate / Strong" with no
indication these are conventions. One word fixes it: "Moderate positive
relationship (by common convention; range: -1 to 1)."
