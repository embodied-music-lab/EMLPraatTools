# Open items — EML Stats & Graphs, road to 1.0.0

Kept in the repo on purpose: this file survives session loss. Update it
when an item is opened, changed, or closed. Newest ruling wins.

Last reconciled against the tree: 19 Aug 2026, late.

## A. The unification (largest remaining piece)

Drawing a figure re-runs the analysis instead of receiving its result.
Demonstrated: one Kruskal-Wallis produced two identical reports fifteen
seconds apart, the second from the graph door. The two agreed only because
both happened to use Holm; the graph form offers test type, adjustment
method and alpha independently, so the figure can contradict the report.

Ruled: the graph carries the analysis's settings forward; changing a
result-affecting setting from the graph re-runs and says so in one line in
the Info window; changing nothing re-runs nothing and prints nothing. The
duplicate-report stopgap is rolled into this, not taken separately.

Memo with the design questions is with Fable
(MEMO_TO_FABLE_unification_20260819.md).

## B. Form and dialog work

- The label sweep: headings group, rows carry only what distinguishes them.
  The right-hand axis page is the exemplar and is done. The remaining pages
  are not swept. Do them one page at a time with the locality check run
  between, not in one pass.
- "Erase page first": remembered within a session, default on at session
  start, never written to disk. Ruled, not built.
- Legend placement label should read "(when drawn)".

## B2. The test-type / post-hoc coupling (reported 20 Aug, not started)

On the group-comparison draw pages, the correction menu is BUILT from the
previous run's test type. Praat dialogs are static, so the control's
presence lags the choice by one press:

- Last run parametric, user switches to nonparametric: the correction menu
  was not built, so Dunn runs under whatever correction the previous run
  left behind. Invisible, and the user never chose it.
- Last run nonparametric, user switches to parametric: the menu is shown and
  read, but Tukey ignores it. Confusing rather than wrong.

Six pages share the pattern (bar, violin, box, grouped violin, grouped box,
spaghetti).

Ian's proposal, which removes the dependency rather than patching it: one
dropdown listing every post-hoc, each option naming which test family it
belongs to and what it does. Nothing can then be stale, because there is
only one control.

Strongest form of that: the options are COMPLETE choices, so the omnibus
follows from the post-hoc rather than being asked separately —

    ANOVA, no post-hoc
    ANOVA + Tukey HSD (family-wise; no separate correction)
    Kruskal-Wallis, no post-hoc
    Kruskal-Wallis + Dunn, Holm (step-down; more power than Bonferroni)
    Kruskal-Wallis + Dunn, Bonferroni (most conservative)
    Kruskal-Wallis + Dunn, Benjamini-Hochberg (false discovery rate)

Three controls collapse to one, no mismatch is expressible, and each line
reads the way a methods section has to read.

Ruled 20 Aug: the list carries section headers -- `-- Parametric --`,
`-- Nonparametric --` -- and guards against someone selecting a header and
clicking through.

THE GUARD ALREADY EXISTS AND IS REUSED, not reinvented. The graph-type
menu is built with a parallel array (`filteredMenuToType[]`) in which 0
marks a header; after the dialog the menu index is remapped through it, and
a 0 re-shows the page with a small box saying the item chosen is a category
header. The post-hoc menu gets the same shape: a parallel array mapping
each menu row to its test family, post-hoc and correction, 0 for a header,
and the same re-show on 0.

Interacts with the unification: when an analysis has already run, this
choice should come FROM it rather than be asked again.

## B3. Dialog audit, 20 Aug — what the hand-read found

Every one of the 128 dialogs was opened and read. The claim that the
lagging-control defect existed only on the six comparison pages was WRONG.
Three more instances, plus three classes worth naming.

FIXED IMMEDIATELY (it was in the fix commit itself): the category-header
guard set `clicked = 0` and every page's button dispatch ended in a bare
`else` that WAS the Draw branch — so refusing a header printed the refusal
and then drew the figure anyway, annotated parametric under Holm from the
procedure's declared defaults. The Draw arm is now named explicitly, so a
refused press falls through to the loop and the page re-shows.

STILL OPEN, lagging controls:

- Line chart column-mapping page. Everything deciding which controls exist —
  how many series tickboxes, whether the interval offer appears, the
  observation count printed in a label — is computed from the time column
  chosen on the PREVIOUS pass, and the time column menu is on that same page.
- Correlation dialog. The group-column list is built by excluding the X and Y
  columns as they were on the previous pass, so changing X or Y leaves the
  group list one press out of date.
- Table editor. The Value field is defaulted from the cell selected on the
  previous pass, so changing row or column and typing edits the wrong cell.

STILL OPEN, stored values that can seed a menu out of range:

- Six config keys are read from disk and used as menu defaults with no range
  check. Praat draws a menu whose default exceeds its option count blank and
  then refuses the form — a dead end the user cannot escape, and the bad
  value is on disk so restarting does not clear it. Gridline mode has a
  clamp; these do not.
- Numeric config keys parse to undefined on an empty or corrupt line, and the
  clamps run after the parse rather than on it.
- The table editor's Scope menu is rebuilt from the live table each pass but
  defaults to a remembered index.

STILL OPEN, dead controls (present but inert for some choices):

- Histogram display mode when ungrouped; the regression dialog's group column,
  which the analysis never receives; the wizard's variance assumption on the
  nonparametric path; and the three already-known wrapper labels carrying
  "(t and Wilcoxon only)" and similar.

Also noted: legend placement has the structural protection gridline mode has
(one registry, one seed, one commit, identical option lists) but no validator
pinning the encoding the way v31 pins gridline mode.

## C. Everything else

### Not started

1. **Save offers the data but not the image.** Driving ANOVA to a violin
   plot and clicking Save offered only the data. Ruled: sweep every route
   that draws, and the detected figure's tickbox starts ticked. A patch
   exists but turns an existing check red, because that check pins the
   tickbox line literally; both must land together.
2. **The render-level geometry check.** Parse a saved figure and assert the
   box, the ticks and the plotted extremes land on one rectangle, per figure
   type, plus a mutation demonstration. Designed, not written. This is what
   makes the font-geometry class impossible to reopen.
3. **Recorder state publication.** The form states its complete display
   state once per press; the recorder writes it ahead of each step; a check
   pins seeded == published == emitted. Measured today: 41 settings are
   seeded, 13 are written into recorded scripts, 28 are not — about 22 of
   those are real user choices including annotation style, alpha,
   correlation type, whether the regression line is drawn, the axis
   show/hide flags and the subtitle. Praat cannot unset a variable, so a
   replayed script inherits whatever the session already held rather than
   falling back to a default.
4. **Recorder records table creation.** Ruled: creation becomes a recorded
   step, split by source — plugin-created gets its command and a seed,
   file-loaded gets its path, pre-existing states its precondition loudly.
5. **Pitch parameters canonical everywhere**, including dev tests and the
   code the recorder emits; one procedure owns each parameter set. Shifts a
   reported mean by about 1 Hz on a short token. Ruled: change it, no
   release note.
6. **ASCII fold at the CSV and report file boundary.** One non-ASCII
   character makes Praat rewrite the whole file as UTF-16, which R, pandas
   and Excel cannot read.
7. **Duplicate-filename loop** replaced by the shared unique-path procedure.
8. **The text wrapper breaks "label = value" across lines.** A patch exists;
   it fixes the break but can lengthen the longest line, which in about one
   case in 150 pushes the annotation box into an extra resize pass. Needs
   driving rather than assuming.

### Test-coverage gaps

- No check drives any figure type through the form's own dispatch. This is
  why the scatter crash of 19 Aug reached Ian.
- Ledger rows owed: 19 tracked process files under harness/dialogheight;
  replay receipt lag in the vector-figure harness; two plugin versions can
  produce a truncated menu with no warning.

### Housekeeping

- Line-chart evidence is stale, deliberately: the photographs are what those
  checks read, and the dialog wording is still moving. One re-drive after
  the sweep, not one per change.

## Closed since this file was written

Font geometry root cause found and fixed — Praat converts a viewport using
the margins in effect when it is SELECTED, so the panel viewport now asserts
the body size before selecting; every annotation routine restores the
ambient size, including on early exits; the coefficient plot uses the shared
layout and honours the frame toggle; facet labels stay on their panel. Ian
confirms the scatter symptom is gone.

R-squared appears once per figure. The subtitle no longer persists across
sessions. Stop always stops; recorder messages append instead of clearing
the Info window; the phrase table is cleaned up; recording starts with
nothing selected. Dialog field names are pinned against truncation and
collision, and every dialog is now checked to read the fields it offers —
which caught the histogram's frequency cap being offered but ignored.
