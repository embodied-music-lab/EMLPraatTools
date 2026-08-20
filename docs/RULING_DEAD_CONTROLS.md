# Ruling — the four dead controls

Verification session → executing session, 20 Aug 2026. All four claims
re-verified at 28ee869 before ruling; one premise failed verification and
changes that ruling (see #3). One principle governs all four, codified
here as house law:

**OVERRIDES ARE NEVER SILENT.** The guess-never-silent rule, extended:
wherever code overrides or ignores a user control — because of the data
or because of a sibling — the override is disclosed at the moment it
happens, in the output the user reads and in the recorded script. The
plugin may override; it may never override quietly. Each control below
gets a ledger row and a driven pin asserting its disclosure line.

## 1. Histogram display mode — LEAVE AND DISCLOSE, actively

The control is real on 2+ groups; only the one-group case deadens it, and
that depends on the data, not the dialog. Ruling: (a) strengthened.
- Label gains the condition: "Display mode (2 or more groups)".
- At the override site (draw-procedures, the nGroups = 1 force), the
  existing disclosure channel states it: "Faceted requested; one group
  found — drawn overlapped." Same line in the recorded script's comment.
(d) rejected — an extra press to report a rare data case is friction
disproportionate to the harm; (b) rejected — the choice is genuine on
grouped data. PIN: drive one-group + Faceted; assert the disclosure line
and the overlap rendering.

## 2. Regression group column — FINISH THE FEATURE (revised 20 Aug,
## superseding the relabel, per Ian and the behavior-is-not-intent rule)

The label's own wording and the correlate dialog's complete per-group
machinery are evidence of intended per-group behavior: this is an
UNFINISHED IMPLEMENTATION, not a labeling defect. Fix: port the
correlate dialog's proven pattern — per-group loop over
@emlLinearRegression, per-group n guard (n >= 4; smaller groups named
and skipped, as correlate names its too-small groups), report = overall
fit first then per-group fits, each labeled; tidy export rows
"(overall)" / "<col> = <level>". The drawn figure's per-group lines then
match per-group fits the report contains, closing the two-door exhibit
for this family at the source. Oracles: R lm per group + overall on a
committed fixture. Do NOT relocate the control; the dialog remains one
of item 10's doors and inherits the store like every other.

## 3. Wizard variance assumption — ONE-LIST COLLAPSE (revised per Ian,
## 20 Aug, superseding leave-as-is)

First, the memo's option (e) premise is FALSE at 28ee869: Test approach
(:400) and Variance assumption (:404-407) are fields of the SAME
beginPause ("Two independent groups — Choose test"); the earlier page
decides paired-vs-independent, and a same-page sibling cannot be
composed against. But the right fix was in this document all along —
the house pattern from #4 and the comparison pages. Collapse the two
menus into ONE list of complete choices:

    Test:  Parametric — Welch t (unequal variances; default)
           Parametric — Student t (pooled variances)
           Nonparametric — Mann-Whitney U

One row saved and the dead control removed BY CONSTRUCTION: the
variance decision exists only inside the options where it is real. The
static-dialog constraint is moot — nothing needs to hide. The wizard's
normality guidance keeps its ruled role by PRESELECTING the recommended
entry (show-both on close calls unchanged); the report-plan strings
follow the chosen entry verbatim. Sweep the wizard's OTHER test-choice
pages for the same shape (any test menu beside a sub-choice menu it
conditions — the paired/RM and k-group branches) and apply the collapse
wherever it fits; report the census of pages touched. The 6b check
stands: a nonparametric report never echoes a variance assumption.

## 4. The three wrapper labels — EXTEND THE ONE-LIST COLLAPSE

The comparison pages already replaced test + post-hoc + correction with
one list of complete choices, by ruling. Extend it to the two wrappers:
- eml-pairwise: one "Comparison" list enumerating the honest complete
  combinations ("Pairwise t (Welch), Holm", "Pairwise Wilcoxon, Holm",
  "Scheffe", ...), replacing Test + Adjustment + T-test-type — two rows
  and two dead controls removed, and the dialog reads the way a methods
  section reads.
- eml-compare-kw: "Kruskal-Wallis" / "Kruskal-Wallis + Dunn, Holm" /
  "... Bonferroni" as one list, replacing the tickbox + adjustment pair.
The complete-choice list is impossible-by-construction applied to
dialogs: no dead combination can be expressed. Option lists stay short
(enumerate before building; if a wrapper's honest combinations exceed
~7, come back).

## 5. The hardcoded 1.96 (added by Ian's direction, 20 Aug) — FIX

Not a dead control but the same disease from the other side: a control
the code half-honors. The correlation confidence interval is a Fisher-z
interval with the 1.96 quantile HARDCODED (eml-annotation-procedures,
the atanh / 1.96 block), so it silently ignores the Alpha the user set —
while the error bars and mean CIs on the same figure are t-based via
invStudentQ and honor it. Set alpha to .01 and one figure carries a 99%
error bar beside a 95% correlation interval, undisclosed. Fix: the
Fisher interval takes its quantile from annotAlpha
(invGaussQ (annotAlpha / 2) — it is correctly a z-interval; only the
constant is wrong). Every other hardcoded-quantile site found in the
same sweep gets the same treatment; grep 1.96 across the tree and
disposition each hit. PIN: oracle against cor.test at two alphas, plus
one driven figure at alpha = .01 asserting the correlation interval
narrows/widens with the setting.

SEQUENCING (all five are 1.0 work, per Ian, 20 Aug): #1 rides the
compaction sweep's redrives; #3's collapse rides the same sweep as #4
(same pattern, same capture regeneration); #2 is a small analysis feature with
its own oracles — land it with the wording/output work so its report
strings are written once under the 6b conventions; #4 rides the
compaction sweep, whose captures regenerate anyway; #5 lands with the
6b output work (it changes report/figure numbers, so its harnesses
redrive once with that family).

Ledger rows for all five (the fixes fixedBy their commits; #3's
row records the verified non-defect disposition). The dead-control
hand-read that found these was worth its hour — note in the census that
it was a HAND read; if a fifth is ever found, the finding class repeats
and a periodic hand-read is cheaper than the static analysis that would
catch "read but unused per branch."

— verification session
