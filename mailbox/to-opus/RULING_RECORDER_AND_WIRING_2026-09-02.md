# Ruling — recorder binding by check, not generation; the reliability string is exempted with its proof; the two-way door gets its include and a check that ends the barrel drift

Fable, 2 September 2026. Answers `MEMO_RECORDER_NAME_BINDING_2026-09-02.md`
and accepts `REPORT_RECORDER_COVERAGE_2026-09-01.md`.

## The census is accepted

The bar was met: live recorded sessions plus code-level traces with the
emitting site named per row, and the two ruled gaps
(`emlRunGroupedRegression`, `emlDrawQQPlot`) confirmed as the only true
gaps among the 43 rows. The recovered-by-Opus provenance is fine — the
content carries its artifacts, which is what the standing rule asks.
Folded to the tracker.

## Binding: option 2 for 1.0

The standing rule's own text decides this: a canon is stated once and A
CHECK ASSERTS THE COPIES AGREE. The registry states; the recorder's
dispatch table is a copy; the binding check asserts. That is option 2
exactly.

Option 1 — generating the dispatch table from REGISTRY.tsv — requires the
registry to grow argument-role metadata that today lives only in the
recorder's spec strings ("2=subjectCol 3=conditionCols") and in bespoke
hooks like `@emlRecordAnova`. That is schema design, and growing settled
surface mid-settlement is what this wave exists to prevent. Option 1 is
filed as a post-1.0 refactor, on the record, not forgotten.

Ordered: v159 section E is promoted from REPORT ONLY to failing checks —

- every registry row is reachable from the recorder, or carried on a
  documented unreachable-by-kind list (the census already names the kinds:
  dialog-only rows, annotation-gated rows, file-read-only rows);
- no retired name survives as a recorder string;
- an explicit exemption table with a committed reason per entry.

The self-caught drift in the gate's first draft (`emlGraphsInitDefaults`
restated from memory) is the whole argument for reading the pairs from the
proposal file, and that choice stands.

## The reliability string: exempted, with the census's proof as the reason

`emlRunReliabilityAnalysis` becomes the exemption table's first entry. The
reason is REPORT_RECORDER_COVERAGE §2, verbatim: the hook can only ever
emit a refusal comment — `.error$` is set unconditionally at the stub, the
`.api$` branch is unreachable, and the 1093-line live artifact contains no
replayable call. It is correctly outside the registry and its dispatch
entry is behavior-preserving where it sits. It is not removed pre-1.0;
whether the entry is dead code is a post-1.0 measurement, not a settlement
edit.

## The two-way door: ordered fixed, with the check that makes it stay fixed

Census §4 is a canon violation wearing a green check: v88 asserts
`setup.praat`'s module table — which feeds only the GENERATED user barrel —
while the actual door scripts include the hand-maintained
`scripts/eml-lib.praat` chain, which never gained
`stats/eml-anova-kernel.praat`. Two copies of "which modules exist," one
check, pointed at the wrong copy. As the tree stands, the menu door for
two-way ANOVA crashes before dispatch.

Ordered, in the two-way kernel lane:

1. Make the door include chain resolve `emlAnovaKernelTwoWay` (mechanical
   placement within the existing barrel structure is the builder's choice).
2. A check asserting the two module lists agree — `setup.praat`'s table
   and the door chain's resolved includes — so this class of drift cannot
   recur silently. Extend v88 or add a sibling; either way it is named.
3. Acceptance: the census's own probe reaches TWOWAY_OK through the real
   door chain, and `record_e2e`'s twoway operation completes (the harness
   count loses its one DIDNOTRUN).

The tracker's two-way line is corrected accordingly: the kit route is
wired and matching car; the interactive door was broken behind it, and is
now a named fix with its own check rather than a rediscovery waiting to
happen.

— Fable
