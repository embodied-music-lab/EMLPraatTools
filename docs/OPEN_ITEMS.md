# Open items — EML Stats & Graphs, road to 1.0.0

Kept in the repo on purpose: this file survives session loss. Update it
when an item is opened, changed, or closed. Newest ruling wins.

Last reconciled against the tree: 20 Aug 2026, afternoon. Every item below
was checked against the code, the checks and the committed evidence rather
than carried forward on trust; seven items that were listed as open turned
out to be built and have moved to the closed section.

The phase register for features beyond 1.0.0 is `ROADMAP.md` at the repo
root. This file is defects and ruled-but-unbuilt work; that one is where
the plugin is going.

## A. The unification (largest remaining piece)

Drawing a figure re-runs the analysis instead of receiving its result.
Confirmed still true: the bridge that draws a group comparison computes the
test itself from its arguments rather than reading a stored result, and no
result store exists anywhere in the plugin.

Ruled: the graph carries the analysis's settings forward; changing a
result-affecting setting from the graph re-runs and says so in one line in
the Info window; changing nothing re-runs nothing and prints nothing. The
duplicate-report stopgap is rolled into this, not taken separately.

Memo with the design questions is with Fable
(`docs/MEMO_TO_FABLE_unification.md`).

## B. Form and dialog work

The ruling arrived 19-20 Aug and the block is lifted:
`docs/RULING_DIALOG_LABELS_v3.md` (supersedes v1 and v2) plus
`docs/ADDENDUM_WORDING_AND_ROADMAP.md`. Both rest on live probes of
Praat 6.6.30 under Xvfb, not on reasoning about Praat.

- **The label sweep, per the ruling.** Headings group; rows carry only what
  distinguishes them. Ranges become one paired row named by QUANTITY, never
  by axis. X and Y axis labels become one sentence-paired row on every page
  that has them. One page at a time, with the locality check run between,
  and the ruling's per-page row counts (12→9, 20→17, and so on) verified
  against the rendered page under Xvfb.

  State as measured: the right-hand axis page is the exemplar and is done.
  Scatter and the single-value-axis stat pages already carry ONE merged
  range heading. Pitch, waveform, spectrum and LTAS still carry two
  per-axis icon headings and need the merge. The paired axis-labels row
  exists NOWHERE yet — all thirteen pages still stack a separate X axis
  label row above a separate Y axis label row.
- **The label character law** (ruling, measured). Before the parenthetical,
  a field label may contain letters, digits and spaces only, plus the
  leading left/right pairing word. Praat strips the label from the first
  "(" onward, turns spaces into underscores, and keeps everything else
  verbatim — so a hyphen, a slash or an emoji makes a variable that is
  bound but unreachable, and code referring to it silently reads
  arithmetic instead. Demonstrated: a field named "left Y-limits" fed -99
  to code that thought it was reading the user's 5.

  The check that must assert this is not the check that exists. The field
  name checker refuses truncation, refuses two fields in the SAME dialog
  block deriving one name, and refuses a hyphen. The ruling requires two
  things wider than that: the full character class (letters, digits and
  spaces only), and uniqueness per RENDERED BRANCH rather than per block —
  the collision that loses user input happens between two rows that only
  co-render on one branch of a conditional page. Both are unbuilt.
- **The histogram compound row is REFUSED** (Ian, 20 Aug): bin count and top
  frequency are totally different measures, and the paired row is for two
  halves of one quantity. The histogram page takes the other two savings and
  goes 32 to 30, not 29. Nothing else uses the pattern, so it is now unused
  everywhere.
- **Terminology-uniformity audit** (new, small, not started). Every dialog,
  report line and doc checked for four terms against R and SPSS usage:
  CONDITION (a level of a within-subject factor), TOKEN (a replicate of the
  same measurement within a cell), MEASUREMENT (the dependent variable
  itself), WITHIN-SUBJECT / PAIRED (a design property; "paired" only at
  k = 2). The line-chart tree's "different measurements" wording is correct
  and out of scope — there it names genuinely different variables.
- Booleans are OUT OF SCOPE by ruling: no gating, no collapsing, no
  relocation, labels unchanged. Title and subtitle stay two full-width
  rows, also by ruling.
- **Legend placement has no encoding validator.** It has the structural
  protection gridline mode has — one registry, one seed, one commit,
  identical option lists, and now a clamp on load — but nothing pins the
  encoding the way the gridline-mode check does. The legend geometry check
  says in its own text that the dialog side is out of its scope.

## B3. Dialog audit, 20 Aug — what the hand-read found

Every one of the 128 dialogs was opened and read. The claim that the
lagging-control defect existed only on the six comparison pages was WRONG.

STILL OPEN, lagging controls:

(The line-chart column-mapping page is closed -- see below.)

STILL OPEN, stored values that can seed a menu out of range:

- Six config keys are read from disk and used as menu defaults with no range
  check: colour mode, output DPI, show axis names, show ticks, show axis
  values, group sort. Praat draws a menu whose default exceeds its option
  count blank and then refuses the form — a dead end the user cannot escape,
  and the bad value is on disk so restarting does not clear it. Gridline mode
  and legend placement both have clamps; these six do not.
- Numeric config keys parse to undefined on an empty or corrupt line, and the
  two clamps that exist run after the whole parse loop rather than on the key.

STILL OPEN, dead controls (present but inert for some choices), all four
confirmed in the code. RULED 20 AUG (Ian) TO BE A FABLE QUESTION, not a
per-control answer from him: the memo is `docs/MEMO_TO_FABLE_dead_controls.md`,
which sets out what each one does today, the five answers available, and why
two of them (re-show on change; compose on a later page) did not exist as
options when these controls were written. Nothing here is built until she
rules.

- Histogram display mode is offered whenever advanced mode is on, and forced
  to a single value whenever the data is ungrouped.
- The regression dialog's group column is built and read, but the analysis is
  called without it; it only seeds the drawing step.
- The wizard's variance assumption is shown on every path and passed on the
  nonparametric call, where nothing reads it.
- Three wrapper labels carry "(t and Wilcoxon only)", "(pairwise t only)" and
  "(post hoc only)" and are always shown and always read regardless of the
  neighbouring choice.

## C. Everything else

### Not started

1. **Recorder state publication.** The form states its complete display
   state once per press; the recorder writes it ahead of each step; a check
   pins seeded == published == emitted. Nothing of this exists: no
   procedure, no check, no harness. The often-quoted "41 seeded, 13
   written, 28 not" has no artefact in the tree behind it — the numbers
   need re-measuring before they are quoted again.
2. **Recorder records table creation.** Ruled: creation becomes a recorded
   step, split by source — plugin-created gets its command and a seed,
   file-loaded gets its path, pre-existing states its precondition loudly.
   The recorder has five step kinds and none of them is creation; it has no
   notion of how a table came to exist.
3. **The text wrapper breaks "label = value" across lines.** The wrapper is
   a plain greedy word wrap with no special case for the equals sign. The
   claim that "a patch exists" could not be substantiated anywhere in the
   tree — treat this as unstarted, and expect the known cost when it is
   built: fixing the break can lengthen the longest line, which in about one
   case in 150 pushes the annotation box into an extra resize pass, so it
   needs driving rather than assuming.

### Red today, and known

- **The line-style check fails on the second series.** "The second series has
  its own Line style menu" is red, and was red before any of today's work --
  invisible until the exit-code hole was closed, because that file reported
  its result and returned success either way. Nobody has yet decided whether
  the menu is missing or the check describes a page that changed.
- **The line-chart dialog photographs are older than the form.** The checks
  that read them are bound to the form's fingerprint, and the config-file
  clamp edits that form, so two of them are red. Nothing in the plugin is
  broken; the pictures are of the previous version. It clears when the
  fifteen-leg photograph run works -- see the line-chart item above, which is
  blocked on the same thing.

### Test-coverage gaps

- The validator index documents the older checks only; roughly a dozen of
  the newest have no entry in it, so "read the index to see what is
  checked" now understates the suite.
- The pitch parameters are pinned equal across every path now, but two call
  sites in the graphs form still spell the parameter tail literally instead
  of calling the procedure that owns it. They agree; they are not joined.
- Seven filtered-autocorrelation calls under harness/graphaxes run with "very
  accurate" ON where canon has it OFF. Test fixtures, not shipped code, so no
  user's number is wrong -- but those fixtures measure something the plugin
  does not do. Reported rather than changed: which way it goes is Ian's.
- Replay receipt lag in the vector-figure harness: the harness drives
  record and replay and checks which files land, but never asserts the save
  receipt a replayed run prints.
- Two plugin versions installed at once can produce a truncated menu with
  no warning. Nothing tests it.
- The same process-artefact debris is still tracked in three other harnesses:
  axisrefuse and linetree carry their own xvfb.log and wm.log. The
  dialog-height ones are out; these are not.

### Housekeeping

- Line-chart evidence is stale, deliberately: the photographs are what those
  checks read, and the dialog wording is still moving. One re-drive after
  the sweep, not one per change. Confirmed still correct — no line-chart
  code has moved since the last re-drive.

## Closed

**The line chart rebuilds its page when the time column moves.** Everything
on that page except the time menu itself -- how many series tickboxes there
are and what they are called, whether the interval offer appears at all, and
the observation count printed inside its label -- is worked out before the
page opens, from the time column it opens with. Choosing a different one and
pressing Draw drew a figure whose page had been answering a different
question. It now says so and rebuilds instead, keeping the ticks by name; one
press, and only on the action that changes what the whole page means. A
sixteenth drive leg walks it under a real X server and reads the box and the
rebuilt page off the photographs; without the guard the walk cannot reach the
box at all.

**A bad line in the config file can no longer lock a dialog.** Thirteen
stored settings are parsed and clamped in one step at the point the line is
read; before, eleven had no range check at all and the two that did tested a
value that could already be undefined, which no comparison catches.

**The table editor's search scope cannot be seeded past the end of the
table**, and **the wizard says conditions and within-subject** rather than
counting "repeated measurements" and calling every within-subject design
"paired" -- the second of which was sending anyone with three or more
conditions to the independent-samples option.

**Three things that worked and were unguarded now have checks**: legend
placement's encoding, the ASCII fold at the file boundary, and the pitch
parameters across every path that uses them.

**Every validator now sets an exit code when run on its own.** Seven printed
their report and returned success whatever the result, so a failing check was
invisible to anything reading exit codes.

**The field-name check reads all 129 dialogs.** It matched a bare `endPause`
to find where a dialog ended, and this tree writes `clicked = endPause:`, so
97 of them were dropped from the population without a word.

**A correlation cannot be grouped by one of the columns it correlates**, and
the dialog is now driven rather than only read. Three cases press its
buttons in order — offer the column, move X onto it, pick it — and assert
that no grouped analysis ran, that the refusal named the column, and that
coming back rebuilt the menu. The pre-guard wrapper turns nine of them red.
The drive answers the shared refusal dialog by replacing that one procedure
in a copy of the tree, with the rest of the file hashed against the shipped
bytes, because a Praat procedure cannot be stubbed by redefining it —
measured: the duplicate warns and the first definition wins.

The list of grouping columns has to be built before the dialog opens, from the X
and Y of the previous pass, while X and Y are chosen on that same page — so
moving X onto a column the list already offered, and then picking it, ran a
correlation of a column against itself split by itself, and reported the
result. That combination is now refused with a sentence saying why, nothing
runs, and coming back rebuilds the list against the columns now chosen. Only
that one combination is refused: nothing else about a column's eligibility
depends on X and Y, so an ordinary change of X or Y still costs no extra
press.

**The render-level geometry check runs.** It reads the frame, the ticks and
the plotted extremes out of a saved figure as numbers and asserts they land
on one rectangle, for all thirteen figure types, with two break tests that
move the font by one point and must turn it red. It was written, passing,
and the one check file the suite runner did not list — so it caught
nothing. The suite now also refuses to run at all if any check file in the
folder is missing from its list, which is the asymmetry that hid this: the
runner asked whether every name was a real file and never whether every
real file was named.

**The comparison control is one dropdown.** Test type, post-hoc and
correction were three controls, and the correction menu was built from the
PREVIOUS run's test type, so a user switching to a nonparametric test got
whatever correction the last run left behind — invisibly, having never
chosen it. They are now a single list of complete choices with
`-- Parametric --` and `-- Nonparametric --` section headers, and the
category-header guard from the graph-type menu is reused on all six pages.
No mismatch is expressible any more. The six pages are bar, violin, box,
histogram, grouped violin and grouped box — spaghetti was named in error in
earlier versions of this file; it has no comparison control at all.

**Save offers the figure.** Every route that draws now detects the drawn
page and starts the figure tickbox ticked, and the check that pins the
tickbox line landed in the same commit.

**Reports and CSVs are ASCII at the file boundary.** One non-ASCII
character used to make Praat rewrite the whole file as UTF-16, which R,
pandas and Excel cannot read. The fold runs on report content and on every
CSV cell. (The recorder log is deliberately outside this, and says so.)

**Duplicate output names go through the shared unique-path procedure**,
which no longer mis-splits a folder whose name contains a dot. Three checks
pin it and two harnesses drive it.

**Pitch analysis uses the canonical parameters on every path**, including
the dev tests and the code the recorder emits. This shifts a reported mean
by about 1 Hz on a short token; ruled, no release note.

**"Erase page first" is remembered while you work** — on at session start,
carried across draws, never written to disk.

**Legend placement says when it applies**: the label reads "(when drawn)",
and the key now has a clamp on load.

**The table editor cannot write one cell's value into another.** Choosing a
different cell and pressing Set without changing the Value box now writes
nothing and shows the chosen cell's real contents instead; typing a value
into a newly chosen cell still writes on the first press. Two drive cases
and eleven checks, with the pre-fix editor demonstrated writing "A1" into
row 3.

**Every figure type is driven through the form's own dispatch**: sixteen
legs, one Praat process each, recorded and unrecorded runs kept separate.
The seam that let a scatter abort reach a user before the suite saw it is
now covered.

**Font geometry root cause found and fixed** — Praat converts a viewport
using the margins in effect when it is SELECTED, so the panel viewport now
asserts the body size before selecting; every annotation routine restores
the ambient size, including on early exits; the coefficient plot uses the
shared layout and honours the frame toggle; facet labels stay on their
panel. Ian confirms the scatter symptom is gone.

**Earlier, and still true.** R-squared appears once per figure. The
subtitle no longer persists across sessions. Stop always stops; recorder
messages append instead of clearing the Info window; the phrase table is
cleaned up; recording starts with nothing selected. Dialog field names are
pinned against truncation and collision, and every dialog is checked to
read the fields it offers — which caught the histogram's frequency cap
being offered but ignored.
