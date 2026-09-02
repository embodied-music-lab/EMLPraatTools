# Report — `emlRunRepeatedMeasuresAnalysis`'s `.subjectCol$` parameter

Opus, 2 September 2026. Ordered by RULING_REGISTRY_VERDICTS_2026-09-01.md
§3 ("report before decision"). Code-level report only — no code touched.
Same finding, same evidence, applies to `emlRunFriedmanAnalysis`, which
carries the identical parameter for the identical reason; both are covered
below and I say so once rather than doubling every section.

## (a) What the RM procedure actually uses to identify subjects

Row position. The procedure reads wide-format data — one row per subject,
one column per condition — and never opens `.subjectCol$` to find a column,
a value, or anything else.

Evidence — the whole of `.subjectCol$`'s appearances inside the procedure
body (`plugin_EML_StatsGraphs/stats/eml-analysis.praat`, lines 4572-4786,
via `grep -n "subjectCol" plugin_EML_StatsGraphs/stats/eml-analysis.praat`):

```
4572:procedure emlRunRepeatedMeasuresAnalysis: .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$
4778:        ... .conditionCols$ + ", subject " + .subjectCol$,
4780:        ... "@emlRunRepeatedMeasuresAnalysis: data, """ + .subjectCol$ + """, """ + .conditionCols$ + """, " + string$ (.doPostHoc) + ", """ + .adjMethod$ + """",
```

Line 4572 is the declaration. Lines 4778 and 4780 are both inside the
recorder hook at the end of the procedure (`if variableExists
("emlRecordLoaded") ... @emlRecordAnalysisStep: ...`): 4778 builds the
human-readable step description, 4780 rebuilds the replay call string. That
is the entire read-set — `.subjectCol$` is echoed into text twice and used
for nothing that touches the computation.

The actual data path is `@emlExtractConditionMatrix: .tableId,
.conditionCols$` (line 4587), which takes only the table and the
pipe-delimited condition-column list:

```
4140:# Input:  .tableId, .conditionCols$  ("|"-delimited column names)
4143:procedure emlExtractConditionMatrix: .tableId, .conditionCols$
```

It builds an `n x k` matrix by reading `.tableId`'s rows in order — the
row index *is* the subject index — and never receives or consults
`.subjectCol$`. `@emlRMAnovaTest`, which runs the omnibus test, is called as
`@emlRMAnovaTest: .data##, .n, .k` (line 4600) — again no subject argument.
Friedman is structurally identical: `emlRunFriedmanAnalysis` (line 4795)
calls the same `@emlExtractConditionMatrix` and never opens its own
`.subjectCol$` outside its own recorder-hook echo (lines 4933, 4935).

The code itself says this in so many words, in a comment placed directly
above the declaration (lines 4565-4571):

```
# v1.2 item 7: .subjectCol$ is RESERVED and deliberately unread. The data are
# in wide format -- one row per subject, one column per condition -- so the row
# index already identifies the subject and no subject column is required.
# The parameter is retained because callers pass arguments positionally;
# removing it would silently shift .conditionCols$, .doPostHoc and
# .adjMethod$ at every call site. It is kept for a future long-format path.
```

(Friedman's version at 4791-4794 makes the same claim, "for the same
reason.") I traced the code independently rather than taking the comment's
word for it; the trace and the comment agree.

## (b) Who passes `.subjectCol$`, and with what value

Every call site in the tree passes the literal empty string `""`. I found
four call sites outside the two `emlRun*` definitions themselves (searched
`plugin_EML_StatsGraphs/scripts/`, `eml-record.praat`,
`walkthrough/kit/RUN_ME_FIRST.praat`, `walkthrough/kit/matrix.tsv`):

- **Wizard** -- `plugin_EML_StatsGraphs/scripts/eml-wizard.praat`, the only
  interactive door onto these two procedures (no menu-door call site
  exists; confirmed by
  `grep -rn "emlRunRepeatedMeasuresAnalysis\|emlRunFriedmanAnalysis" plugin_EML_StatsGraphs/scripts/*.praat`
  returning only this file):
  ```
  1465:            @emlRunRepeatedMeasuresAnalysis: tableId, "", condList$,
  1466:            ... pairwise_post_hoc, adjustment$
  ...
  1481:            @emlRunFriedmanAnalysis: tableId, "", condList$,
  1482:            ... pairwise_post_hoc, adjustment$
  ```
  Second positional argument is `""` in both calls. The wizard never asks
  the user for a subject-column name anywhere in its repeated-measures
  page.

- **Recorder** (`plugin_EML_StatsGraphs/stats/eml-record.praat`) does not
  *call* either procedure -- it only builds the replay script text and the
  human-readable step gloss for the call the wizard already made. Two
  relevant spots:
  - `emlRecordAnalysisStep`'s column-of-interest spec table, used to let a
    user retarget a recorded step by editing a named argument:
    ```
    3262:    elsif .proc$ = "emlRunRepeatedMeasuresAnalysis"
    3263:        .spec$ = "2=subjectCol 3=conditionCols"
    3264:    elsif .proc$ = "emlRunFriedmanAnalysis"
    3265:        .spec$ = "2=subjectCol 3=conditionCols"
    ```
    This registers argument position 2 as a column-name argument named
    `subjectCol` -- purely for the recorder's own editing/glossing UI (see
    the `subjectCol` -> `"the subject identifier"` gloss at line ~3588). It
    does not cause `.subjectCol$` to be read by the analysis; it causes the
    recorder to *describe* position 2 as a subject column to a user editing
    a recorded script.
  - The reliability procedure (`emlRunReliabilityAnalysis`, a genuinely
    unimplemented stub -- `.error$ = "Not yet implemented..."` -- see (d))
    shares the same `.spec$` shape at lines 3260-3261, which is presumably
    why the recorder's table treats all three the same way regardless of
    whether the analysis actually reads the argument.

- **Kit runner** (`walkthrough/kit/RUN_ME_FIRST.praat`) -- the kit's
  harness calls both procedures directly, also with `""`:
  ```
  1490:            @emlRunRepeatedMeasuresAnalysis: .tableId, "", .colA$,
  1491:            ... .doPostHoc, .adjust$
  ...
  1494:            @emlRunFriedmanAnalysis: .tableId, "", .colA$, .doPostHoc,
  1495:            ... .adjMethod$
  ```

- **`walkthrough/kit/matrix.tsv`** carries no subject-column field at all.
  Its RM/Friedman rows (e.g. `c0528`, `c0548`) put the condition list in the
  column-A field and leave the columns between it and `doPostHoc` blank --
  there is no cell in the matrix format that maps to `.subjectCol$`;
  `RUN_ME_FIRST.praat` supplies the `""` itself rather than reading a value
  from the matrix.

So: no caller anywhere in the tree -- wizard, kit, or any harness copy of
either -- ever passes anything but `""`. Nothing supplies a real column
name today.

## (c) What would change if a caller supplied a real column name

Nothing, and the mechanism is worth stating precisely because "nothing
happens" has two different causes and this is the boring one: the
parameter is read nowhere, not read-and-discarded.

Trace: `.subjectCol$` enters the procedure as a local (line 4572), and the
only two lines that ever look at it again are the recorder-hook lines 4778
and 4780 quoted in (a). Both are string concatenation into human-facing
text (the step's one-line gloss, and the replay-call string a user would
paste back in). Passing `"participant_id"` instead of `""` would:

- change the words in `emlRecordAnalysisStep`'s logged step description
  from `"soft|medium|loud, subject "` to `"soft|medium|loud, subject
  participant_id"` (cosmetic, in the Info/record log only), and
- change the replay-call string that gets written back out to
  `@emlRunRepeatedMeasuresAnalysis: data, "participant_id", ...` (which,
  fed back through the same procedure, hits the identical dead read and
  changes nothing further),

and stop there. It would not affect `@emlExtractConditionMatrix`, `n`,
`k`, the data matrix, `@emlRMAnovaTest`, the F-statistic, degrees of
freedom, Greenhouse-Geisser epsilon, the post-hoc pairs, the CSV/tidy
export, or any refusal/guard condition. None of those touch
`.subjectCol$` at any point in the trace in (a). I did not run a
before/after comparison on live data for this report (an actual value has
never been passed anywhere in the tree, so there is no recorded run to
diff against) -- the "nothing changes" claim rests on the static trace
above, which is exhaustive for this parameter (every line in the procedure
body that mentions `.subjectCol$` is quoted in (a) and (c); there are no
others), not on an executed comparison. If Ian wants that run performed
before ruling, it is one wizard pass with a real value typed into a
throwaway copy of the RM call -- cheap, but out of scope for a report
ordered to change no code.

The one place a real value *would* matter is the recorder's `.spec$`
table (b): if a user hand-edits a recorded RM step and retypes the
`subjectCol=` argument to some other string, the recorder will splice that
string into the replayed call's position 2 -- and the replayed call will
hit the same dead read. So even there, a caller-supplied value changes the
generated text, never the analysis.

## (d) History

The tree shows origin and one deliberate documentation event, but not an
earlier design the parameter might be a remnant of -- this repository's
first commit already has it as part of an unimplemented stub.

**Origin, before any RM implementation existed.** The repo's first commit
carrying this file, `9aea1b2` ("plugin: 2026-07-22 pre-audit state (69
files)"), has all three of `emlRunReliabilityAnalysis`,
`emlRunRepeatedMeasuresAnalysis` and `emlRunFriedmanAnalysis` as stubs, and
the five-parameter RM/Friedman signature -- `.tableId, .subjectCol$,
.conditionCols$, .doPostHoc, .adjMethod$` -- is already exactly what it is
today:

```
$ git show 9aea1b2:plugin/stats/eml-analysis.praat | sed -n '901,911p'
procedure emlRunReliabilityAnalysis: .tableId, .subjectCol$, .raterCols$, .measure$, .scale$
    .error$ = "Not yet implemented -- scheduled for Phase 4."
endproc

procedure emlRunRepeatedMeasuresAnalysis: .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$
    .error$ = "Not yet implemented -- scheduled for Phase 4."
endproc

procedure emlRunFriedmanAnalysis: .tableId, .subjectCol$, .conditionCols$, .doPostHoc, .adjMethod$
    .error$ = "Not yet implemented -- scheduled for Phase 4."
endproc
```

`git log --all --oneline --reverse -S"subjectCol\$" -- '*eml-analysis.praat'`
returns `9aea1b2` as the earliest hit of any kind, confirming the parameter
did not enter in a later commit -- it was there from this repository's
beginning, before RM-ANOVA had a body at all. This repo has no earlier
history to inspect (`9aea1b2` is an initial bulk-import commit, "69
files"), so the tree cannot show whatever design decision, if any, first
put `.subjectCol$` in that stub signature. That is a real limit on this
report, not a finding -- I can't rule out a pre-repo long-format design,
only say the tree doesn't show one.

**Implementation, still with the parameter present and already unread.**
`934e2ed` ("plugin: 2026-08-04 current state (103 files)") is where RM-ANOVA
and Friedman got real bodies (the stub `.error$` lines are gone, replaced
by the current implementation), and it is also the commit that first adds
the "RESERVED and deliberately unread" comments -- confirmed by counting
occurrences of that phrase across the chain from the stub to today
(`4f81395`, the commit just before it, has 0; `934e2ed` has 3, one for
`emlRunNormalityAnalysis.testType$` and one each for RM and Friedman's
`.subjectCol$`). The same commit's changelog block states this was a
documentation act, not a design change:

```
$ git show 934e2ed:plugin/stats/eml-analysis.praat | sed -n '45,54p'
#   item 7 -- Documented the reserved-but-unread parameters
#            (emlRunNormalityAnalysis.testType$,
#            emlRunRepeatedMeasuresAnalysis.subjectCol$,
#            emlRunFriedmanAnalysis.subjectCol$) and the unimplemented
#            emlRunReliabilityAnalysis stub. Parameter lists are unchanged
#            because callers pass arguments positionally.
```

(Same text survives to today in `plugin_EML_StatsGraphs/dev/HISTORY_LEDGER.md`
lines 3296-3299 and 6067-6070.) So "v1.2 item 7" is not the moment the
parameter was added, and not a moment anything was wired or removed -- it
is the moment someone found the already-existing dead parameter (present
since the stub) and wrote down that it's dead, explicitly declining to
remove it for the positional-argument reason quoted in (a).

**Is it a remnant of the recent string-vector decision?** No -- and the
dates rule it out on their own. The order's own hypothesis (d) names "a
parameter added for a signature settled in the RM string-vector decision."
That decision is `WORK_ORDER_API_SETTLEMENT_2026-08-31.md` item 1: "the
string-vector repeated-measures signature ships in 1.0 as canonical form;
the pipe-delimited form becomes a compatibility wrapper" (superseding
`RULING_RM_SIGNATURE_FREEZE_2026-08-31.md`, both dated 31 August 2026).
`.subjectCol$` predates that decision by four weeks (stub: 22 July;
implemented with the dead-parameter comment already attached: 4 August).
And that decision, read in full, is about `.conditionCols$` -- whether the
condition-column list is a pipe-delimited string or a true Praat
string-vector -- never `.subjectCol$`. `mailbox/to-opus/TRACKER_KIT_AND_1p0.md`
lists "string-vector RM as canonical with pipe-delimited wrapper ...
UNMEASURED" as a separate, still-not-started line from "RM `.subjectCol$`:
code-level report to Ian, then wire-or-remove," which is this line item.
And in the tree today `@emlExtractConditionMatrix` still takes
`.conditionCols$` as `"|"`-delimited
(`plugin_EML_StatsGraphs/stats/eml-analysis.praat` line 4140:
`# Input:  .tableId, .conditionCols$  ("|"-delimited column names)`) --
the string-vector form hasn't landed, so there's no signature change here
for `.subjectCol$` to be a remnant *or* an anticipation of.

Net: the tree shows a parameter present from the very first commit, in an
unimplemented stub, kept unread through implementation, and explicitly
documented as reserved-and-unused five weeks before the unrelated
condition-column vector-format decision existed. It is not tied to that
decision in either direction. What it *was* originally for -- the
comment's own guess, "kept for a future long-format path" -- is not
something the tree can confirm; that line appears only as of the
`934e2ed` documentation commit, alongside the dead-parameter finding
itself, not as a decision recorded anywhere earlier.

## Summary for the ruling

- Subjects are identified by row position today, unconditionally, in both
  RM-ANOVA and Friedman. No column is or can be used.
- Every call site in the tree (wizard, kit runner) passes `""`; nothing
  passes a real value. The recorder describes position 2 as a
  `subjectCol` for its own edit/replay UI but does not cause it to be
  read.
- Supplying a real value would change only two lines of generated text
  (a log line and a replay string) and nothing about the computation, per
  a full static trace of every line touching `.subjectCol$` -- not
  confirmed by an executed before/after run.
- The parameter is original to the stub (repo's first commit, before RM
  had a body), was left in through implementation, and was explicitly
  flagged as reserved-and-unread in a documentation-only change five weeks
  before the unrelated pipe-delimited/string-vector decision on
  `.conditionCols$` -- which is still unimplemented and has never
  mentioned `.subjectCol$`. This is not a remnant of that decision.
