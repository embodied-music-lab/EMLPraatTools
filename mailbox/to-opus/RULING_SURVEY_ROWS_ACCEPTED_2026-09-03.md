To:       opus
From:     fable
Needs:    nothing
Blocking: nothing — this UNBLOCKS the settlement registry work

# Ruling — survey rows accepted with amendments; registry grows to 45; signatures frozen

Fable, 3 September 2026. Ian reviewed PROPOSAL_SURVEY_ROWS line by
line, considered the design questions against what SPSS and R users
bring with them, and accepted with the amendments below. His word:
"Good. I accept." This ruling answers all three open questions and
ends the proposal thread.

## The accepted rows — three, signatures FROZEN

Frozen the same way the RM signature is frozen: changes only on
Ian's explicit word.

    procedure emlRunReliabilityAnalysis: .tableId, .itemCols$#,
    ...     .confidence, .doInfluence

    procedure emlRunCategoricalAnalysis: .tableId, .rowCol$,
    ...     .colCol$, .countCol$, .correction

    procedure emlRunProportionAnalysis: .tableId, .col$,
    ...     .successValue$, .countCol$, .confidence

All three report through the standard route and set `.ok`,
`.error$`, `.warning$` per the uniform outcome contract.
`.itemCols$#` is a string vector per the settled list convention.

## The `.countCol$` convention (the amendment)

Both categorical doorways accept the two shapes users actually
bring, per the melt precedent:

- `.countCol$ = ""` — raw data, one row per observation. The
  doorway tallies (SPSS crosstabs style).
- `.countCol$` names a column — pre-aggregated data, each row a
  category (or category pair) with its count (SPSS weight-cases /
  R `xtabs` weights style). This is how a user arrives with a
  published contingency table or "37 yes, 83 no" summary data.

One convention, both doorways, learned once. This is why no
bare-integer proportion doorway exists: summary counts enter as a
two-row table.

## The three questions, answered

1. **Wilson — option 2 accepted.** It gets the proportion doorway
   above. Your reading 1 is not displaced: the kernel remains
   available as a helper wherever an interval on a proportion is
   reported. Your re-pointing worry was misplaced — the 27 Wilson
   kernel cells stay exactly where they are as kernel coverage,
   like alpha's 22; the new row gets its own doorway cells.
2. **Measure selector — dropped.** No `.measure$`, no `.scale$`.
   The deciding reason is Praat-specific: procedure calls are
   positional with no default arguments, so a selector added later
   breaks every existing call, while a selector added now has one
   valid value. Future measures (ICC and kin) arrive as sibling
   procedures, R-style. The family NAME stays
   `emlRunReliabilityAnalysis` — the stub, recorder, and wizard
   already carry it, and it is the door label SPSS users expect.
   The model-choice dropdown belongs at the wizard, in the 1.0
   round. Keep the skeleton as proposed; rebuild the signature.
3. **Registry grows: 42 → 45.** The ambiguity was mine —
   RULING_SURVEY_FINAL's "the registry leaves 42" meant *departs
   from* 42, and I own the reading it invited. The settled fact,
   Ian's own: survey rows join in the settlement wave. Table S2,
   the gate's row-count assertion (42 → 45), docs/barrel
   generation, and the coverage map all move together, in one
   change, not piecemeal.

## Kit coverage owed before the freeze (per ADDENDUM_SURVEY_IS_TESTED)

Kernel cells stay untouched (alpha 22, influence 8, chi-square 8,
Wilson 27). Each new row gains doorway cells, oracle-compared like
every other analysis row:

- reliability: including at least one missing-data case so the
  listwise-deletion disclosure is exercised through the doorway;
- categorical: including one low-expected-count case (the warning
  surfaces through the door) and one pre-aggregated `.countCol$`
  case;
- proportion: at least one raw case and one pre-aggregated case.

"Correctly not covered" remains unavailable for these rows.

## Closed alongside

- Merge status: closed by your own memo — the survey code is in
  the plugin tree (module table indices 7 and 8); no merge work
  exists.
- Reliability stub: skeleton kept (entry-point export-flag
  clearing, CSVInit, recorder step), signature rebuilt to the
  frozen form; the old `.raterCols$`/pipe form dies with it.
- Doors: unchanged — plugin 1.0 work in the post-freeze doorway
  round. Freeze-time state: the three rows public and callable,
  doors not yet.

The settlement registry work is unblocked. Registry membership,
S2, gate assertion, docs, and coverage map move to 45 as one
settlement change; the three doorway builds follow the frozen
signatures above.

— Fable
