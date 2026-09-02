# Ruling — punch-list fold-ins; the "8.5" citation was my error; the error sweep is NOT DONE and sequences with the outcome contract

Fable, 2 September 2026. Answers `REPORT_PUNCHLIST_INTERSECTION_2026-09-01.md`
and `REPORT_ERROR_PROPAGATION_2026-09-01.md`. Both reports are accepted:
measured, artifact-carrying, and in the punch report's case correcting
Ian's suspicion in both directions (right about parts of Lanes 8–9, wrong
about Lane 7, which was built and green the day the list was written).

## Fold-ins ordered

- **8.1 leg1 and 8.4's undisclosed Dunn literal → bridge unification
  (wave item c).** Do not patch the bridge's Tukey-only arm or its
  hardcoded `holm` separately: both literals live in code item (c)
  deletes, and patching code about to be deleted would make the
  equivalence probe compare against a hand-patched intermediate instead of
  Family A's real behavior. v127 and v116 re-run as part of item (c)'s
  acceptance; expected v116 outcome 7/7 disclosed.
- **9.x error sites in wave-surface files → sequenced with the outcome
  contract.** The 68 lint sites in the six files the wave already edits
  are close to a prerequisite for a coherent `.ok`/`.error$`/`.warning$`
  contract, not an independent task; one editing pass per file, not two.
  The ~53 non-wave-surface sites proceed in parallel, before the tag.
- **All `eml-lmm.praat` lint sites → EXEMPT_SITES in the same commit as
  the registry exclusion entry (wave item e),** with the withdrawn-doors
  reason. That makes punch item 9.4's "filed" claim true against the
  measured tree, which today it is not.
- **Separable, no action:** 7.1–7.3 (built; 7.1 gets a grep after the
  rename, not a rebuild), 8.2 (blocked on the store, not the wave), 8.3
  (built; refresh v127's stale header comment when convenient).
- **8.1 leg4 (spaghetti prints no inferential statistic — silent
  disagreement with the paired door):** stays post-kit, as it touches
  none of the wave's surface — but it is upgraded from punch-list
  obscurity to a named tracker line so it cannot be lost. Its fix is the
  unification round's business.

## "8.5" — my citation, my error

RULING_REGISTRY_VERDICTS §5 cited "the filed range-refusal extraction
8.5." Measured: Lane 8 stops at 8.4 and no such item exists. The number
was mine and it was wrong. The thing I had in mind is the shared
range-refusal extraction pair the report located
(`emlGraphsAxisPairRefusal` / `emlGraphsPitchRangeRefusal`, the latter
filed in OPEN_ITEMS as a coverage gap) — which, as measured, lives
entirely outside the wave's surface. The citation is struck; no order
rode on it and none does now.

## The error sweep: tracker D moves from UNMEASURED to NOT DONE

The census is the measurement Ian's ruling required, and it does not
flatter us: 135 raw violations (121 unique keys), `EXEMPT_SITES` empty,
gate red. The tracker's "63 sites" line is corrected on the record: 63 was
the 25 Aug census's SWALLOWED-SILENT + UNCHECKED count at commit 3e34b1a;
29 commits and +13k lines later, v134's stricter mechanical population
finds 121, and the two numbers are not comparable at line grain. That is
definitional drift plus real growth, recorded as such — not a regression
claim and not an excuse.

Ordered on the census's classification:

- The **31 SAFE adjudications are pre-approved** for EXEMPT_SITES with the
  census's per-cluster reasoning pasted as the committed reason and an
  ERROR-READ EXEMPT comment at each site, exactly as v134 expects.
- The **9 untraced sites get the runtime checks the census itself
  specifies** (the two-way constant-residual run, the wizard picker
  click-through, the bridge empty-table probe, and a fresh v134 run
  against the port file after its current edits land). Cheap, named,
  and each closes with either an exemption entry or a defect.
- The **76 UNSAFE sites are the sweep's fix population**, sequenced per
  the fold-in above. Priority order: the `eml_getGroupData` proxy cluster
  first (33 sites; it is the core inferential engine, and one bad cell in
  a data column currently discards its own diagnosis), then the confirmed
  Pearson/Spearman sibling-drift bug at `eml-analysis.praat:3126` (a
  one-line fix with a known-good sibling two lines away), then the
  skew/kurtosis cluster (an incalculable kurtosis silently reading as
  "not severe" feeds a real recommendation).
- The demo-script sites ride the same pass at lowest priority; "sets a
  bad example" is still a defect in a teaching plugin.

Ian's ruling stands: the tag does not ship over a red error gate. The
sweep to zero — fixes plus committed adjudications — is pre-tag work, and
v134 going green IS its acceptance.

— Fable
