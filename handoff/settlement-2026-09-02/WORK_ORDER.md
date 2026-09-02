# Work order — the mechanical settlement

Every task below carries a ruling. The ruling files are in `rulings/` beside
this one. Read the ruling before doing the task it governs.

## Task 1 — rename six public procedures

Ruling: `rulings/NOTE_NAMES_ACCEPTED_2026-09-01.md` accepts
`rulings/PROPOSAL_CANONICAL_NAMES_2026-09-01.md` as written and clears the
rename wave to execute. `rulings/MEMO_NO_WRAPPERS_2026-09-01.md` records why
no compatibility wrapper is created: the plugin has never shipped and there
are no users.

The six pairs, read from the proposal:

| retire | adopt |
|---|---|
| `emlRunKWAnalysis` | `emlRunKruskalWallisAnalysis` |
| `emlRunGroupedRegression` | `emlRunGroupedRegressionAnalysis` |
| `emlBridgeGroupComparison` | `emlRunAnnotationComparison` |
| `emlGraphsMeltSeries` | `emlReshapeSeriesLong` |
| `emlGraphsPivotSeries` | `emlReshapeSeriesWide` |
| `emlInitDrawingDefaults` | `emlInitializeDrawingDefaults` |

This is a straight rename. The old name stops existing. Do not add a wrapper,
an alias, or a deprecation shim.

Measured scope as of 2 September: 222 file-touches outside the excluded
directories. `./list_sites.sh` prints the current list.

RECONCILE TWO COUNTS BEFORE YOU EDIT, ordered by
`rulings/RULING_SPLIT_AND_ACCEPTANCE_2026-09-02.md`.
`walkthrough/kit/audit/rename_call_sites.tsv` holds a 3000-row line-level
inventory of the same six names. The two numbers differ because one counts
files outside the excluded directories and the other counts lines everywhere,
and about 83 percent of the 3000 is regenerated harness output that task 4
handles by regeneration. Check the two against each other. If they disagree
anywhere outside the regenerated directories, stop and report it rather than
editing.

YOU ALSO UPDATE `validate/recorder_coverage.tsv`. It names, per public
procedure, the site that emits it into a recorded script. A renamed procedure
changes its row there too, and the gate fails until it does. That file is the
one thing outside `plugin_EML_StatsGraphs/` this task changes.

### Where the rename is silent, and why this task is not trivial

Praat resolves a procedure name at call time and never checks a name that
appears inside a string. `plugin_EML_StatsGraphs/stats/eml-record.praat`, the
script recorder, decides what to emit by comparing a string against a
literal, in a chain of the form `if .proc$ = "emlRunKWAnalysis"`.

Four of the six retired names appear as such literals. Miss one and nothing
errors: not at build time, not while recording. The recorder simply stops
matching, and the generated user script loses a step or carries a call to a
procedure that no longer exists. It fails in a user's hands, months later.

Grep for each retired name as a bare word, not as a call. Check the result
against `./list_sites.sh`.

## Task 2 — registry to 42 rows, mixed model excluded by entry

Ruling: `rulings/RULING_REGISTRY_VERDICTS_2026-09-01.md` section 1.

`emlRunLMMAnalysis` comes out of `plugin_EML_StatsGraphs/REGISTRY.tsv` for
1.0. The mixed model is a post-1.0 procedure: implemented and validated, menu
and wizard doors withdrawn, public after 1.0. The registry ends at 42 data
rows.

It is not deleted silently. The exclusion is recorded in the `RUN_EXCLUSIONS`
list in `validate/v155_public_registry.R`, with a stated reason, in the same
form `emlRunReliabilityAnalysis` already uses there. That list is what the
erosion check consults: every `emlRun*` procedure in the tree must have a
registry row unless this list names it. Remove the registry row without adding
the list entry and v155 fails, which is the design working.

Do NOT put the procedure name in `RELEASE_EXCLUDE.tsv`. That file names FILE
PATHS the release zip drops, and its own header states that an entry matching
no path is a build failure. A procedure name there would break the build.

Read the reliability stub's existing entry first and match its shape.

## Task 3 — two recorder hooks

Ruling: `rulings/RULING_REGISTRY_VERDICTS_2026-09-01.md` section 2.

`emlRunGroupedRegressionAnalysis` (renamed in task 1) and `emlDrawQQPlot`
have no recorder hook. Both are judged oversights. Add a hook for each, in
the same shape their sibling procedures use.

The measured recorder census is at
`mailbox/to-fable/REPORT_RECORDER_COVERAGE_2026-09-01.md`. Read it before
you start; it names the emitting site per row.

Two things you will find, which are context and not your task:
`emlRunReliabilityAnalysis` is still in the recorder's dispatch chain after
being pulled from the registry, and the recorder harness records
`twoway ... DIDNOTRUN`. Report both. Do not fix either — the first waits on
a ruling and the second belongs to the two-way kernel lane.

## Task 4 — regenerate what the rename invalidated

27 generated output directories under `harness/` contain retired names.
Regenerate them by running their own `run.sh`; do not edit them.

Run at minimum `harness/record_e2e/run.sh` and report its operation count.
Before your change it reports 37 of 38 operations recording, with `twoway`
failing. If your change alters that count in any direction other than the
two new hooks, stop and report it.

## Task 5 — the repeated-measures signature, HELD

Ruling: `rulings/WORK_ORDER_API_SETTLEMENT_2026-08-31.md` item 1.

This task is real, it is decided, and you must NOT start it. It is written
here so that it cannot be forgotten, and so that you recognise it if you meet
it while doing tasks 1 through 4.

`emlRunRepeatedMeasuresAnalysis` and `emlRunFriedmanAnalysis` receive their
condition columns as one pipe-delimited string, `.conditionCols$`, split
inside `@emlExtractConditionMatrix`. Item 1 of the API settlement rules that
a string vector is the canonical form for 1.0. The pipe-delimited string is a
signature already ruled against.

RULED by Ian, 2 September: there is no backward compatibility requirement,
because the plugin has never shipped. The pipe-delimited form does NOT become
a compatibility wrapper. It stops existing, exactly as the six retired names
in task 1 do. The work order's "becomes a compatibility wrapper" clause is
superseded.

One thing remains open, and it is a sequencing call, not a design question:

`.subjectCol$` sits in the same procedure header and is awaiting Ian's
wire-or-remove ruling (`rulings/RULING_REGISTRY_VERDICTS_2026-09-01.md`
section 3). Changing the condition columns without it means editing that
signature twice and revalidating every caller twice, the recorder included.
Until Ian rules, this task stays held.

If a task above leads you into this signature, stop and report it.

## Explicitly out of scope

Do not start either of these. Both are ruled, and both need judgment that
this work order does not carry.

**The uniform outcome contract.** Every public procedure is to set `.ok`,
`.error$` and `.warning$`. Today 40 sites set `.ok`, 726 set `.error$` and 56
set `.warning$`. Deciding which failure paths are real is design work.

**The annotation-bridge unification.** `rulings/RULING_REGISTRY_VERDICTS_2026-09-01.md`
section 4 requires equivalence probes before and after the change plus a red
demonstration that the probe can fail. That is design work with pins.

If either looks necessary to finish a task above, stop and report it rather
than starting it.

## If you hit a case no ruling covers

Stop and write it into `out/REPORT.md` as an open question. Do not decide it.
Design questions go to Fable through Ian, never adjudicated in place.
