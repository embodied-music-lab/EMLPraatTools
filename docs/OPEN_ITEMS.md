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
(`docs/MEMO_TO_FABLE_unification.md`); the answers are
`docs/RULING_RESULT_STORE.md`.

FIRST PIECE BUILT, 24 Aug: THE DATA KEY. `@emlGroupFingerprint`,
`@emlAnalysisFingerprint` and `@emlFingerprintsAgree` in
`stats/eml-extract.praat` — the ruling's §a per-group-level fingerprint. It
lives in the extraction layer because both sides of the store need it: the
kernels stamp it on a published result, the annotation bridge recomputes it at
draw time. Levels and values come from `@emlCountGroups` and
`@eml_getGroupData`, so the key describes the data as the analysis saw it. The
key is TEXT and is only ever compared as text; nothing about it is a float
comparison.

REBUILT THE SAME DAY, FORMAT `eGF2`. An adversarial pass defeated the first
composition (`eGF1`: n, sum, sum of squares, min, max per level) six times.
Three of the six were one fault — per-level moment aggregates cannot describe
a multiset, and for n >= 5 a continuum of alternative level contents satisfies
five fixed aggregates, so the hole does not close by adding a sixth. The key
now commits to a digest over each level's quantised SORTED value list, which
closes moments, tie structure and rank order together; quantisation moved from
12 to 15 significant digits because nothing is accumulated any more; the label
hash went from one unsalted 31-bit polynomial to two salted ones over
different bases and primes (about 62 bits); and the per-level spelling set is
folded as a sorted SEQUENCE rather than as a linear sum of hashes. Details and
the six fixtures are in `dev/tests/phase2/test-fingerprint.praat` (110 checks;
23 of them, including all six defeats, go red against a scratch revert of
`eGF1`, and the four published acceptance probes stay green in both).

STORED `eGF1` KEYS DO NOT UPGRADE and must not be treated as if they did: the
format tag is part of the compared text, so an `eGF1` key never matches an
`eGF2` key and the analysis re-runs. That is the intended behaviour, not a
migration to be written.

OPEN BY DESIGN, WITH IAN: A TWO-WAY KEY. The sixth defeat was
`@emlTwoWayAnova` — the key describes (value, group) only, and rewriting half
the cells of a second factor moves F(group) and its p across .05 without
touching either column the key names. The fault is in the CALL, not the
arithmetic, so the closure is a door: `@emlAnalysisFingerprint` takes the
analysis's FULL comma-separated column list and REFUSES — no key, stated error
naming the columns — when handed more than it can describe. Whether a two-way
composition gets BUILT (one record per design cell, new format tag) is a scope
call for Ian; the shape is ready for it as another branch of the same
procedure. Until it is built, two-way analyses simply do not get a key.

STILL UNBUILT in this item, and each is a separate piece of work: the store
itself (the single write site, the published names, the §b census of
result-affecting vs display-only settings, the one-line announcement); the
bridge reading the store instead of recomputing; and the two neighbouring
keys the ruling anticipates — a paired/repeated door needs ROW PAIRING in the
key, and the scatter's correlation needs a cross term (sum of x*y), neither
of which any per-column or per-level description of ONE column can supply.
The fingerprint's own header states both, and both should route through
`@emlAnalysisFingerprint` so that the refusal is what happens until they
exist.

TWO THINGS THE 24 AUG VERIFICATION PASS NAMED HERE. There is no pinned
validator for the fingerprint: its mutation legs live in the phase2 suite, not
in `validate/`, so the main suite's count is unmoved by 832 lines of shipped
code and the only evidence for that code is evidence it wrote about itself.
The cheap fix is one `validate/` check that runs the phase2 legs, not more
phase2 legs. And the fingerprint has no shipped caller yet — expected while the
store is unbuilt, and the reason the coverage question is worth settling before
the store lands rather than after.

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

  DONE, all thirteen pages, 24 Aug, as one batched sweep with a single
  photographed re-drive at the end (ruled: the source-level checks stay
  green page by page, the photographed evidence goes stale en bloc). Row
  counts land on the approved targets ±1; the only overshoot is Spaghetti
  at +1. Every page now closes its fields inside a named group, the four
  acoustic pages carry one merged axes heading, and the paired axis-labels
  row exists on every page that has axis labels.

  Two answers the sweep had to measure rather than assume, both now in the
  code: the histogram's value range governs the HORIZONTAL axis
  (`@emlDrawHistogram` assigns `.xMin = .vMin`), so the label that read
  "Value range (bottom/top)" was backwards and now reads "Value
  (left/right)"; and the paired-row idiom is not exclusive to axes — the
  panel origin's x/y inches and the pitch floor/ceiling render the same
  way, which is why v84's axis roster is now derived from the group each
  row sits in rather than from the row's shape.

  Follow-up, small: the line-chart pages take the same grouping in their
  own file set as a separate commit, never as a retrofit against the old
  form.
- **The label character law** (ruling, measured). Before the parenthetical,
  a field label may contain letters, digits and spaces only, plus the
  leading left/right pairing word. Praat strips the label from the first
  "(" onward, turns spaces into underscores, and keeps everything else
  verbatim — so a hyphen, a slash or an emoji makes a variable that is
  bound but unreachable, and code referring to it silently reads
  arithmetic instead. Demonstrated: a field named "left Y-limits" fed -99
  to code that thought it was reading the user's 5.

  BUILT, and both of the wider things the ruling asked for are in
  `validate/v98_field_names.R`: the full character class (letters, digits
  and spaces only before the parenthetical, plus the leading left/right
  pairing word), and uniqueness per RENDERED BRANCH — every field carries
  the branch path it sits on, and a shared name is judged provably-together
  (fails), provably-apart in two branches of one `if` (legal, and it stays
  legal), or cannot-rule-on, which is pinned by name so a new one gets read
  by a person.

  A rendered page also carries rows nothing in the block declares. A
  `beginPause` block is ordinary code, so a procedure called from inside one
  emits its field rows into that dialog: `@emlWrapperCommonFields` is
  declared in `stats/eml-output.praat`, ten wrapper dialogs call it, and
  eleven sites read the `clear_Info_window` it binds. The sweep follows a
  call made inside a block, audits the rows it contributes as rows of the
  calling page, and fails a call it cannot resolve. Measured under Xvfb by
  `harness/labellaw/inject.sh`, which renders
  `validate/fixtures/dialog_labels/inject_collision.praat` and reads the
  collision back out of Praat; demonstrated red against seeded copies of the
  shipped tree via `$EML_DIALOG_SRC`.

  OPEN, AND NOT PART OF THIS ITEM: `validate/v99_form_variable_locality.R`
  reads dialog blocks with a scanner of its own that does not follow a
  procedure call, so the rows a procedure contributes are outside its
  subject too. Whether locality should see them is a question for whoever
  owns v99.
- **The histogram compound row is REFUSED** (Ian, 20 Aug): bin count and top
  frequency are totally different measures, and the paired row is for two
  halves of one quantity. The histogram page takes the other two savings and
  goes 32 to 30, not 29. Nothing else uses the pattern, so it is now unused
  everywhere.
- **Terminology-uniformity audit — done, with six fixes.** The four terms
  now read the same way everywhere: CONDITION (a level of a within-subject
  factor), TOKEN (a replicate within one cell), MEASUREMENT (the dependent
  variable), and WITHIN-SUBJECT / PAIRED (a design property; "paired" only at
  k = 2). What it caught is in the closed section. The line-chart tree's
  "different measurements" wording was confirmed correct and left alone —
  there it names genuinely different variables.
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

(Stored values that could seed a menu out of range are closed -- see below.)

DEAD CONTROLS -- RULED BY FABLE, 20 Aug (`docs/RULING_DEAD_CONTROLS.md`).
One principle governs all of them, and it is house law now: THE PLUGIN MAY
OVERRIDE A USER'S CHOICE, BUT NEVER QUIETLY. Wherever code ignores a control
-- because of the data or because of a sibling control -- it says so at the
moment it happens, in the output the user reads and in the recorded script.

- Histogram display mode: kept, with the condition in the label ("2 or more
  groups") and a line at the override site saying a faceted request on one
  group was drawn overlapped.
- The regression group column: the ruling was REVISED. This is an unfinished
  feature, not a mislabelled control -- the wording promises per-group work
  and the correlation dialog already has the whole pattern. Finish it: per-
  group fits beside the overall one, groups too small named and skipped,
  labelled rows in the export, and the drawn lines then matching the report.
  Ruled into 1.0.
- The wizard's variance assumption and the three wrapper labels: both become
  ONE list of complete choices, the pattern the comparison pages already use
  -- "Parametric -- Welch t (unequal variances)", "Pairwise t (Welch), Holm".
  The dead control disappears by construction, because the sub-choice only
  exists inside the options where it is real.

Sequencing is Fable's: the histogram disclosure and the two collapses ride
the compaction sweep's re-drives; the regression feature lands with the
wording and output work so its report strings are written once.

## Newly ordered, 20 Aug

- **The Tukey family-wise interval ignores the alpha you set.** Found by the
  quantile sweep, not named in the 20 Aug ruling, and the same defect class:
  the ANOVA report's "Tukey HSD Mean Differences (95% family-wise CI)" table
  and the `conf.low` / `conf.high` pair in the Tukey export frame both take
  their critical q from `@emlOneWayAnova`, which passes 0.05 to
  `@emlTukeyHSD` and takes no alpha of its own. Measured: on a three-group
  fixture the whole report is byte-identical at annotAlpha = .05 and .01,
  under a fixed "95%" heading, on a path where the stars beside it do obey
  the user's alpha.

  It is NOT the same fix as the other three. `@emlTukeyHSD` already takes
  `.alpha`; the constant is at the call site inside `@emlOneWayAnova`, whose
  arity is fixed by roughly twenty-five callers across the plugin, the dev
  tests and the harness drivers, and whose `.qCritical` also reaches an
  exported column. That is a scope of its own and needs a ruling on whether
  the level travels as a new argument or as a graphs-layer resolution at the
  reporter.
- **The door-agreement census** (`docs/WORK_ORDER_DOOR_CENSUS.md`). Every
  user intent reachable through more than one door gets one adversarial
  fixture -- built so that divergent mappings produce loudly different
  numbers rather than coincidentally equal ones -- and a leg per door. Each
  leg asserts one of exactly two things: the doors agree to oracle tolerance,
  or they state plainly that they are showing different models. Silent
  disagreement is the only red. Seeded with one already found: the
  correlation dialog reports overall and per-group labelled, the regression
  dialog reports overall only, and the scatter annotation reports per-group
  only.
- **Behaviour is not intent** (standing law). When a control's promise and
  the code's behaviour disagree, the first question is which side is the
  defect. Lowering a label to match the behaviour needs positive evidence
  that the behaviour is the design; without it the finding is an unfinished
  implementation and goes to Ian as scope.

## C. Everything else

### Not started

1. **Recorder state publication.** The form states its complete display
   state once per press; the recorder writes it ahead of each step; a check
   pins seeded == published == emitted.

   ONE CONCRETE INSTANCE, FOUND 24 AUG WHILE READING THE HISTOGRAM DRAW.
   The recorder writes `.displayMode` into the emitted script AFTER the
   one-group path has forced it from 2 (faceted) to 1 (overlap). So a
   session in which the user chose faceting and got one panel records a
   script that says they chose overlap. The replay draws the same picture,
   which is why nothing has gone red: the fidelity claim the recorder makes
   is about the USER'S CHOICES, and this is the draw layer's derived value
   standing in for one. Publication (this item) is the fix — the form
   states what was chosen, not what survived the draw.

   MEASURED, AND THE MEASUREMENT IS NOW IN THE REPO:
   `validate/tools/recorder_census.py`, so this stops being a number in a
   sentence. Of 41 globals the draw layer seeds, 14 are assigned in scripts
   the recorder actually produced and 27 are not; 18 of those 27 are real
   user choices — the font, gridline mode, legend placement, the tick,
   axis-name and axis-value flags, the inner box, the subtitle, the
   annotation style and alpha, the scatter's dot size and formula toggle.
   The rest is bookkeeping.

   The earlier "13 emitted" was measured by asking whether the RECORDER'S
   SOURCE mentions a name, which over-counts: two names it mentions
   (`emlDrawnMinX`, `emlLegendSepActive`) appear in no emitted script. The
   census reads emitted scripts instead. It measures a FLOOR — a setting
   only shows as emitted if some committed recording exercised the figure
   that carries it — and says so.

   WHY THEY ARE MISSING, which decides the fix: a recorded step is a
   procedure CALL with its arguments, so a setting passed as an argument is
   recorded and a setting read from a global is invisible. The plugin's
   display state travels in globals. `@emlRecordAxisRequest` is the
   existing precedent for the answer — the form publishes what the user
   asked for and the recorder prefers it over what the draw resolved.

2. **Four commands leave no trace in a recorded script**, measured by
   `validate/v107_record_census.R` over every command `setup.praat`
   registers: creating a demo table, both doors of the table editor, and
   checking data. Thirteen record their work. The check is a ratchet — red if
   a fifth appears, and red if one is fixed without its line being removed —
   so the gap cannot grow quietly and the list cannot outlive the defect.

   The demo generator is the sharpest of the four: it makes a table out of
   nothing, so a recording taken afterwards describes an analysis of data
   whose origin the script cannot state. The editor is the most dangerous:
   a replay runs the recorded analysis against the table as it stands now,
   and nothing says the numbers were edited in between. Checking data is the
   weakest and may end up exempt with a reason rather than fixed.

3. **Recorder records table creation.** Ruled: creation becomes a recorded
   step, split by source — plugin-created gets its command and a seed,
   file-loaded gets its path, pre-existing states its precondition loudly.
   The recorder has five step kinds and none of them is creation; it has no
   notion of how a table came to exist.

### Red today, and known

Nothing. The suite is green: 15974 checks, 15974 passed, on the 24 Aug
verification pass over the whole tree.

The two entries that stood here are closed. The line-style menu on the second
series went green on 20 Aug and stayed green -- it was listed as red here for
twenty-one commits after it was fixed, which is the argument for reconciling
this file against a run rather than against the last edit. The line-chart
photographs were one commit stale on two digests and were re-driven on 24 Aug.

### Test-coverage gaps

- **The pitch floor and ceiling are now judged by nothing.** Removing them
  from the axis-refusal roster was correct — they set an analysis search
  range, not a plot axis, and they only ever qualified because they render as
  a paired row. But they remain a range a user types, floor above ceiling
  remains nonsense, and after the 24 Aug sweep no check asserts anything about
  their ordering. Whether they want a refusal of their own is scope, not a
  defect.
- **A range pair filed under a non-axis heading escapes the whole suite.**
  Measured 24 Aug against all twenty-five checks that read the graphs form: a
  pair placed under the layout heading leaves the axis roster and nothing
  objects, so it also escapes the max-below-min refusal. Only the transcript
  digests move, and they move for any edit at all. The axis-refusal check's
  header previously claimed the page-composition checks caught this; they do
  not, and the header now names the gap instead.
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
- Two plugin versions installed at once can produce a truncated menu with
  no warning. Nothing tests it.
- The same process-artefact debris is still tracked in three other harnesses:
  axisrefuse and linetree carry their own xvfb.log and wm.log. The
  dialog-height ones are out; these are not.

### Housekeeping

- Line-chart evidence was stale deliberately behind the sweep's single
  re-drive. Discharged 24 Aug: driven on Praat 6.6.30, 765 checks green. The
  line chart's own pages were never touched by the sweep -- 80 widget lines
  identical on each side of the commit -- so only the digests moved.
- **Photographed-dialog evidence — DISCHARGED 24 Aug.** The batching ruling
  held the pictures stale behind one re-drive at the sweep's end. That drive
  ran: axis refusal 78 checks green, line chart 765 green, and the whole suite
  green behind them.

  WHAT THE RE-DRIVE TAUGHT, kept because the next sweep meets it again. The
  harnesses address dialog fields by TAB INDEX, and seven indices moved on the
  box-plot and scatter pages. The reason is not the one this file recorded:
  group headings are comment rows and take no tab stop, so they shift nothing.
  The range rows moving out of the layout group and up under the axis heading
  is what moved them. Anyone re-deriving indices by counting added headings
  gets the wrong answer.

  Each corrected index was measured before anything was driven — a marker typed
  at every position and read back from the variable that received it, with the
  neighbouring positions recorded beside it. A Praat paired row takes one tab
  stop per box, not one per row; that had never been covered and now is.

  The evidence that the indices are right rather than merely different: across
  the re-drive the axis-refusal transcript changed in exactly two lines, the
  code digest and a new line naming the machine. Every refusal message, every
  ink measure and every recorded axis range is byte-identical. A wrong index
  types into another box and the refusal names a different axis or never fires.

## Closed

**Every report interval takes its level from the alpha in force.** The
correlation band was the first; the sweep the ruling ordered found three more
that spell the level as a TAIL PROBABILITY rather than as a z value, which is
why grepping for 1.96 could not see them: the two-group report's CI of the
difference and the regression coefficient table's CI column, both
`invStudentQ (0.025, df)`, and the Feldt interval on Cronbach's alpha,
`invFisherQ (0.025 / 0.975, ...)`. All three were measured ignoring the
control before they were touched -- at annotAlpha = .05 and .01 the three
printed intervals were byte-identical.

The two report sites now resolve the level through one procedure,
`@emlCIAlphaInForce`, so the stars, the error bars and every bracket in that
module read one answer. The Cronbach kernel takes its level as an argument
the way its sibling `@emlWilsonInterval` does, and its outputs are `.ciLow` /
`.ciHigh` rather than names that assert a level the caller chose. Every label
is built by `@emlCILevelLabel`, which renders the percentage without rounding
it to a whole number -- so alpha = .005 reads "99.5%" and .025 reads "97.5%",
where rounding printed "100%" and "98%".

`validate/v109` drives all three live at two alphas against `t.test`,
`confint(lm)` and the published Feldt form, requires each printed label to
name the level it used, requires every bound to move when the alpha does, and
carries one seeded-constant negative control per site. 65 checks. Agreement
with R is exact to the printed precision at .05, .01, .005, .025 and .1.

The rest of the sweep is dispositioned in place, with the reason written at
the site: `@emlDescribe`'s interval, the LMM Wald intervals and the Tukey
call inside `@emlOneWayAnova` keep their constants because the label beside
each states the same level and no dialog offers a control for it -- except
the Tukey one, which is a real finding and is in the open list above.

**The text wrapper keeps "label = value" on one line.** The space before an
equals sign and the space after it are not break candidates in
`@emlWrapText`; the line breaks at the last space that is not part of such a
unit, and when a unit is itself wider than the line the search falls back to
any space and then to a hard break. Every property the callers depend on
holds: breaks land on spaces, no line exceeds the width, and the segments'
word count still sums to the input's, which is what
`@emlDrawAnnotationBlock` needs to carry Picture markup across a break.

The known cost was driven, not assumed. `harness/wraptext/` runs the corpus
through two plugin trees that differ in `@emlWrapText` and nothing else: 39
annotation strings from the omnibus, correlation, regression and disclosure
call sites at every width from 16 to 72 (2223 wraps), and 182 blocks of one
to six of those lines on seven figure sizes (1274 boxes) through
`@emlDrawAnnotationBlock`'s own fit loop. The longest line grows in 0.94% of
wraps, by a median of 3 characters and never past the width, and shrinks in
19.9%. The box takes one extra fit pass on 4 boxes of 1274 — one in 319,
better than the one in 150 the standing list warned of, and never more than
one pass — while 10.6% take fewer. Breaks touching an equals sign, over
those boxes: 1316 to none. The probe is not wired into the suite.

**The replayed save's receipt is read, not just its files.** `harness/vecfig`
drove record and replay and looked only at the disk; the three lines
`@emlRecordReplaySave` prints -- how many files, where, under what base name
-- were the one thing an unattended replay says about itself and nothing
asserted them. The harness now takes them verbatim into `VECFIG.tsv` and
`validate/v86` compares them to that replay's own disk: the count against the
files carrying that base name, the folder against the folder it was pointed
at, and the base name against a base name a file was actually written under.
The comparison is deliberately NOT against the recording's receipt --
`@emlRecordReplaySave` regenerates the stamp rather than replaying it, so two
receipts that agreed would mean the defect that procedure exists to prevent.
Fourteen checks, and two new breaks in `harness/vecfig/break.sh` watched red:
`receipt_stale_stem` (the recorded base name printed instead of the written
one) puts ten red and moves nothing else in the file, `receipt_before_report`
(the report written after the receipt rather than before it) puts the four
count checks red on a save where nothing failed and nothing went missing.


**A bad line in the config file can no longer lock a dialog.** Every menu
setting read from disk is parsed and range-checked in one step, at the line
it is read. A value that is not an option, or a line that is empty or
corrupt, falls back to the default instead of drawing a blank menu the form
then refuses to close -- a dead end that survived restarting, because the bad
value was on disk.

**The exported summary counts conditions, not groups.** A repeated-measures
ANOVA and a Friedman test wrote the number of conditions into the summary
CSV under `n.groups` — the same column every independent-groups test uses.
Anyone reading that file, or a script reading it, was told a
between-subjects design had been run. It reads `n.conditions`.

**"Compare paired..." says what it does.** The menu item read "Compare
paired/repeated...", but the dialog behind it takes exactly two columns and
offers only the paired t-test and Wilcoxon. Anyone with three or more
conditions who followed the word "repeated" landed somewhere that cannot run
their design. The repeated-measures route is the Stats Wizard, and the
reproduction notes recorded with an RM-ANOVA or Friedman result now name it
instead of the two-column dialog they used to point at.

**The wizard stops calling a two-condition design "repeated measures".** Its
plan report described a paired t-test or Wilcoxon as "Two paired / repeated
measures", which reads in a manuscript as a design that was not run. It says
"Two conditions (paired)". The page that chooses between them is titled
"Paired — Choose test", matching the column-selection page beside it.

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
