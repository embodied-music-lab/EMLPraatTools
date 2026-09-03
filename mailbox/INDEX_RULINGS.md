To:       opus, sonnet
From:     fable
Needs:    nothing
Blocking: nothing — reference document, maintained by Fable

# INDEX_RULINGS — every binding ruling, one line each

Maintained by Fable; updated with every new ruling. Precedence: the
ruling FILE beats this index; this index beats any session's
memory. Re-read at the top of every working session and after any
compaction. Superseded rulings are omitted — the mailbox trail
keeps them. Current as of 3 September 2026 (through
RULING_SETTLEMENT_QUESTIONS).

## Scope and sequence

- RULING_SURVEY_FINAL + ADDENDUM_SURVEY_IS_TESTED: the kit's API
  and TEST scope include the survey API (registry rows AND kit
  cells, oracle-compared; "correctly not covered" unavailable for
  survey analysis rows); plugin 1.0 adds the survey doorways
  post-freeze; kit resolves first; ONLY LMM defers past 1.0. Kit
  scope stated once: every built procedure family through its
  public API except LMM.
- RULING_SURVEY_ROWS_ACCEPTED: three signatures FROZEN —
  emlRunReliabilityAnalysis(.tableId,.itemCols$#,.confidence,
  .doInfluence), emlRunCategoricalAnalysis(.tableId,.rowCol$,
  .colCol$,.countCol$,.correction), emlRunProportionAnalysis
  (.tableId,.col$,.successValue$,.countCol$,.confidence).
  .countCol$: empty = raw rows tallied; named = pre-aggregated
  counts. No measure selector — future measures are sibling
  procedures. Registry 42 → 45 as ONE settlement change (S2, gate
  assertion, docs, coverage map together). Kernel cells stay; each
  row's doorway cells owed pre-freeze.
- RULING_SETTLEMENT_QUESTIONS: reliability doorway EXPORTS
  .delta#/.rowIndex# (not printed) when .doInfluence set; k=2
  doorway fixture added and alpha_if_deleted's when-clause worded
  against it; LMM dead block in eml-wizard.praat = documented 4c
  exemption for the freeze (expires when navigation returns or
  block removed; fate decided post-1.0); .countCol$ lives in
  matrix.tsv col_c; absd prints UNSIGNED under any sort order (a
  signed effect size is its own direction-named quantity);
  unseeded-drawing-globals sweep = a check, 1.0 round, not
  blocking freeze.
- Kit target never widens without Ian's explicit word. Sequence:
  settlement → authoritative run → Tier B → inspection
  (INSPECTION_PROTOCOL = the pre-committed A.10 bar) → KIT FREEZE
  → doorway round → plugin 1.0.
- Ian, 2 Sep: NO backward compatibility — the plugin has not
  shipped; retired forms CEASE TO EXIST (no wrappers, no
  compatibility shims).

## Oracles and the kit

- RULING_PORT_ACCEPTANCE: the mpmath grid is the ONLY oracle, both
  directions; R and scipy are documented comparison columns; cells
  with true p < 1e-12 are characterization cells, outside the
  pass/fail tally.
- RULING_GRID_RELABEL_AND_V150: forward grid rows RELABEL to
  actual p (they were scipy-seeded, labels lied) + provenance
  header + tier coverage from actual p; root-solve only empty
  tiers; generator self-check = full evaluation. v150 = the
  R-characterization file, out of the tally.
- v154 state: 120/120 acceptance + 10 characterization, zero
  fails; A.2 CLOSED (mesh 0.0005).
- Paper's final counts come from grand_ledger at the authoritative
  run and nowhere else; the run's commit is backed up to GitHub
  BEFORE the run (tamper-evidence — the one GitHub exception).

## Registry, recorder, doors

- RULING_RECORDER_AND_WIRING: v159 §E = FAILING checks (every row
  reachable or documented unreachable-by-kind; no retired name in
  recorder strings; exemption table); generation-from-registry
  filed post-1.0. Docs/barrel/S2 GENERATED from the registry.
- RULING_V162_INVARIANT: the invariant is menu-registered items'
  transitive modules must be door-reachable; the exemption is
  COMPUTED from setup.praat's menu block, never hand-listed;
  procedure-graph reachability (option 1) is post-1.0.
- RULING_RM_SIGNATURE_ACCEPTED (+ RULING_RM_FORMATS): RM +
  Friedman frozen at .tableId, .format$("wide"/"long"),
  .subjectCol$, .conditionCols$#, .conditionCol$, .valueCol$,
  .doPostHoc, .adjMethod$; both accept wide AND long (one kernel
  via reshape canon; dialog asks format); .subjectCol$ WIRED as
  the long-path subject column; reshape pair also moves to string
  vectors; pipe and comma delimited forms are dead; empty vector
  literal is empty$#(0).

## Errors and robustness

- RULING_ERROR_TRIAGE_APPROVED: fix the 82 in priority order
  (getGroupData ×33 → countGroups ×20 → Pearson drift →
  skew/kurtosis → rest); 6 unsure sites run named checks first;
  53 SAFE filed to EXEMPT_SITES with reasons (LMM sites in the
  SAME commit as the exclusion entry); v134 green before tag.
  Standing: no tag ships over a red gate.

## Census, scope, sources of truth

- RULING_SOURCE_OF_TRUTH: Ian's local main IS the source of truth;
  GitHub is a backup; nobody waits on origin; divergence resolves
  in local's favor; pushing is Ian-only. One exception: the
  pre-run anchor above.
- Census rules: a census of the repository is taken via git
  ls-files (location-independent) at the repository of record,
  never a working-directory walk, never a private clone. Scope
  questions are answered against the census file, never against
  the list that arrived with the question.
- RULING_RENAME_SCOPE (+ THE_OTHER_108): scope by KIND — live code
  and live hand-maintained inputs rename; generated files
  regenerate (never hand-edit); run-output records and preserved
  snapshots/break outputs are untouched; narrative/dated registers
  are out. The exemption set is stated ONCE in one shared scope
  file read by every consumer. Absence-assertion class stays
  NAMED even at zero members.
- RULING_LANDED_MEANS_LANDED: a delivery claim is verified at the
  DESTINATION before it is made.
- Specific ruling beats general default. Acting alone never
  includes resolving ambiguity in the authorizing ruling.

## Mailbox and conduct

- Live mailbox = EMLPraatTools/_mailbox_live/ (git-ignored);
  repo mailbox/ = committed archive. Every file carries
  To:/From:/Needs:/Blocking:; headerless = HELD. Files are never
  edited — superseded by new files; newest file per topic wins.
- PROCEDURE.md's four act-alone / four never-without-Ian
  conditions bind all sessions; "verified" claims carry the
  command and its output.
- ORDER_OPERATING_MODE (3 Sep): decisions come from Fable
  pre-made; session memory is not evidence — state is re-read
  from disk (this index, tracker, PROCEDURE.md, the work order);
  compactions are DECLARED in the next memo's header; every claim
  ships with evidence; Fable audits every couriered wave at the
  bundle before acceptance.

— Fable
