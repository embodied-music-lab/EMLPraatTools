# Acceptance rules for the kit's authoritative run

Pre-registered 2 September 2026, before the authoritative run named in
tracker item A.8 (`mailbox/to-opus/TRACKER_KIT_AND_1p0.md`). These rules
are the pass criterion. Nothing here may be loosened, tightened, or
reinterpreted after the authoritative run's results exist — a change made
after that point is a new set of rules, not a reading of this one, and
needs its own ruling from Fable.

Apply these rules directly to a results file (`results/reconciliation.tsv`,
`audit/VERDICT.txt`, or `walkthrough/kit/grand_ledger.tsv`) without asking
anyone a question. Where a rule requires a judgment call the source
material does not settle, that call is marked **OPEN** below and is not
this document's to make — see `mailbox/to-fable/REPORT_ACCEPTANCE_AND_FOREST_2026-09-02.md`.

## 1. Two agreement regimes, not one

The kit runs three studies (`matrix.tsv`'s `study` column: `options`,
`sweep`, `nist`). They are scored two different ways:

- **Tier B — `options` + `sweep`.** Every cell has an R oracle. A quantity
  is scored by comparing the plugin's value to R's value directly, under
  the **standard agreement rule** (§2).
- **NIST study.** NIST StRD cells have no R oracle for pass/fail — the
  plugin's value is judged against the published certified constant in
  `nist_certified.tsv` directly. Base R's own value is computed too, but
  only as the yardstick the NIST rule uses (§3), never as the pass/fail
  reference itself. Source: `nist_certified.tsv`'s own header, and
  `mailbox/to-opus/RULING_NIST_CRITERION_2026-08-31.md`.

A quantity is scored under exactly one of these two regimes, decided by
which study its cell belongs to — never by the quantity's name or kind.

## 2. The standard agreement rule (Tier B: `options` + `sweep`)

Source: `walkthrough/kit/compare.R`, the `agree()` function and its
preamble comment (already in force — this section states the rule already
running, it does not introduce a new one); restated in plain language in
`walkthrough/kit/README.md` ("How agreement is decided").

Given a plugin value `a` and an R value `b`, both numeric:

- **Relative form (the default).** They agree when
  `|a − b| / max(|a|, |b|) < 1e-9` — nine significant digits.
- **Absolute form (near zero only).** When `max(|a|, |b|) < 1e-12`, the
  relative form is meaningless (a relative difference between two
  rounding errors carries no information), so the rule switches to
  `|a − b| < 1e-12` instead.
- Text-valued quantities (e.g. `refuse_reason`) agree when the strings are
  byte-identical. They are not compared under the relative/absolute rule
  at all; wording differences between the two implementations are handled
  under §5's `refusal-wording` clause (D-WORDING), never under this rule.

This tolerance is deliberately not a knob. Two independent implementations
of the same formula in IEEE double precision should agree to near machine
precision; anything that does not is a difference worth naming, not a
threshold to widen.

**Declared, tolerance-bounded exceptions.** A small, named list
(`compare.R`'s `DECLARED[]`) may replace this rule for a specific quantity
pattern with a wider, explicitly bounded relative-error clause, each
carrying a measured worst-case and a stated limit above it (e.g.
D-PTUKEY's quadrature-tail clause). **At the authoritative run, the set of
such clauses is expected to be smaller than it is today**:
`mailbox/to-opus/RULING_CONSOLIDATED_KERNELS_2026-09-01.md` §3 orders
D-TWOWAY-PRECISION, D-PTUKEY and D-PTUKEY-MID retired with the two-way and
ptukey rebuilds, with "no interim text rewrite — a clause not in force at
the authoritative run needs no correction." Concretely: if any row at the
authoritative run carries one of those three IDs, or if a `diff`-bucket
`DECLARED` row appears under any ID other than D-WORDING, that is a
**finding to report, not a pass** — it means the pre-run rewrite pass did
not fully land, and this rules file does not authorize silently accepting
it as before. The only tolerance-bounded, both-sides-present divergence
this rule set expects to survive to the authoritative run is D-WORDING
(refusal wording; prose-only, no numeric bound, asserted instead by the
three-way refusal-set-equality check in §5).

## 3. NIST cells and log-relative-error (LRE) treatment

Source: `mailbox/to-opus/RULING_NIST_CRITERION_2026-08-31.md` (the
governing ruling — corrects the shape below) and
`mailbox/to-opus/WORK_ORDER_NIST_UNIFICATION_2026-08-31.md` (the concrete
build order it answers); scoring function `validate/lre.R`, wired into
`compare.R`'s NIST block exactly as `v19_nist_strd.R` already used it — no
reimplementation.

**One family, two branches**, per RULING_NIST_CRITERION §1–2 (this
supersedes any framing of df and non-df quantities as three separate
families, and supersedes any notion of a *separate* residual-SD
assertion — no such thing is defined anywhere, and none is invented here):

- **Degrees of freedom (`df_between`, `df_within`) — exact-integer
  branch.** Pass is `==` against the certified integer. This branch never
  calls `lre()` or the relative-error rule; the wrong criterion is
  unreachable for df by construction, not merely unused by convention.
  22 such checks across the 11 NIST datasets (2 per dataset).
- **Every other certified quantity — LRE branch, `residual_sd` included.**
  `residual_sd` is scored by the exact same rule as `ss_between`,
  `ms_between`, `f`, `ss_within`, `ms_within` and `eta_squared` (the
  `Certified R-Squared` field) — it is simply `sqrt(ms_within)` read
  through the one LRE rule below, never a rule of its own.
  `LRE(computed, certified) = −log10(|computed − certified| / |certified|)`
  (absolute error in place of relative when `certified == 0`; capped at
  17). The plugin's LRE and base R's own LRE (against the same certified
  constant) are both computed; **the plugin passes when its LRE is no more
  than `NIST_SLACK` = 1.0 significant digit below base R's LRE on the same
  quantity** — base R is the yardstick, the certified constant is the
  target, and a raw plugin-vs-certified error ratio is never the pass
  criterion by itself.
  ~76 such checks (11 datasets × up to 7 LRE-scored fields, short of the
  full 77 wherever a dataset's own certificate does not carry a field —
  see §4's out-of-scope rule).

The **22 + 76 = 98** total is the number RULING_NIST_CRITERION and
`v19_nist_strd.R`'s own standalone run both report today. It is **not a
fixed target** — RULING_NIST_CRITERION says so explicitly: "The total is
whatever the ledger measures... If that lands at 22 + 76 = 98, good; if
not, the paper's numbers change, not the code. Counts are outputs." Apply
the branch rule above to whatever `nist_certified.tsv` actually certifies
at run time; do not force the count to 98.

## 4. Pass, fail, and out-of-scope, defined per regime

**Tier B (`options` + `sweep`), per contracted quantity on a driven
cell** (`quantities.tsv` is the contract; a "contracted quantity" is one
its rule expands over the cell — see `quantities.tsv`'s own header):

| Outcome | Condition |
|---|---|
| **PASS** | Both sides reported the quantity (a value, or `<quantity>_undefined` — see §5) and it agrees under §2, OR the difference is covered by a `DECLARED` bound within its stated limit. |
| **FAIL** | Both sides reported the quantity and it disagrees, with no `DECLARED` clause covering the difference (bucket `UNEXPLAINED`), **or** a contracted quantity a side owed is simply absent — no value, no `_undefined` marker (bucket `MISSING_PRAAT`/`MISSING_R` — compare.R: "a missing contracted quantity is a FAILURE... not a one-sided row"), **or** a side reported a quantity `quantities.tsv` assigns to the *other* side alone (bucket `CONTRACT_VIOLATION_*`). |
| **OUT OF SCOPE** | The quantity's contract clause is legitimately one-sided (`quantities.tsv`'s `sides` column is `praat` or `r`, with the reason in `note`) — bucket `CONTRACT_ONLY_PRAAT`/`CONTRACT_ONLY_R`. Also out of scope: a cell neither runner drove at all (both a filtered-run condition and, per §6, disqualifying for the authoritative run itself — it must not happen there). |

**NIST, per certified field on a NIST cell:**

| Outcome | Condition |
|---|---|
| **PASS** | df branch: plugin integer equals the certified integer. LRE branch: plugin LRE ≥ base-R LRE − `NIST_SLACK`. |
| **FAIL** | df branch: integers differ (bucket `NIST_DISAGREE`, status "FAIL (exact-integer df)"). LRE branch: plugin LRE falls short of the base-R-minus-slack floor (bucket `NIST_DISAGREE`, status "FAIL (LRE below base R − SLACK)"). Also FAIL: the field is certified and in scope, but the plugin reported no value at all for it (bucket `NIST_MISSING_PRAAT` — §5 covers this case in full). |
| **OUT OF SCOPE** | `nist_certified.tsv` carries no row for this dataset/field combination — the dataset's own NIST certificate does not publish that quantity (e.g. `AtmWtAg` has no "Standard Deviation" row; `SiRstv` does). `compare.R` skips the field entirely (`next`, before it is added to `nNistExpected`) rather than counting it as missing or undefined. This is the correct reading of "a quantity the dataset does not certify," not a gap in the plugin or the R side. |

**Cell-level refusal**, both studies alike: a cell where matrix.tsv
declares `expect=refuse` is neither pass nor fail on its *values* — it is
scored on whether **both programs actually refused it**, and refusal
wording is explicitly not compared (D-WORDING, §2). See §5's three-way
equality check, which is itself pass/fail at the cell level.

## 5. A cell whose reference is unavailable

"Reference" means different things in the two regimes; both are covered
here so neither is silently guessed at.

- **Tier B, R refuses the whole cell.** R is Tier B's reference. When R
  refuses a cell (bucket `refused`/`skipped` in `audit/r_results.tsv`),
  every contracted quantity that cell owed on the R side is **waived**,
  not scored (compare.R's `nWaived` counter) — a refusal is a complete
  report of "why nothing was computed," not a missing report. The mirror
  case (Praat refuses) waives the Praat side the same way. Waiving is
  conditional on one thing not being silently true: the **refusal itself**
  must pass the three-way set-equality check — declared (`matrix.tsv`'s
  `expect=refuse`), actually-refused-by-Praat, and actually-refused-by-R
  must be the identical set of cells (`compare.R`'s five-way breakdown:
  `missP`, `missR`, `undeclaredP`, `undeclaredR`, `asymRefuse`). Any
  cell in exactly one of those five diagnostic sets fails the run on its
  own, regardless of how many quantities its own comparison waived.
- **NIST, the certified constant is unavailable.** Covered in §4 as OUT
  OF SCOPE: the field is skipped, not scored, not counted toward
  `nNistExpected`. This is a property of what NIST published, not of
  either implementation, and carries no fail.
- **NIST, the plugin's own value is unavailable.** The field IS certified
  (in scope) but the plugin reported nothing for it. This is **FAIL**,
  bucket `NIST_MISSING_PRAAT` — the field was owed and did not arrive,
  same logic as Tier B's `MISSING_PRAAT`, adapted to the NIST ledger
  columns (`digits_praat`/`digits_r` blank, `status = MISSING_PRAAT`).
- **NIST, base R's own value is unavailable on an in-scope, LRE-branch
  field.** **OPEN — not settled by any ruling read for this document.**
  `compare.R`'s current code does not special-case this: if `r_lre` is
  not finite, `minReq` is `NA`, `pass` evaluates `FALSE`, and the row is
  written to `NIST_DISAGREE` under the same status text as a genuine
  LRE shortfall ("FAIL (LRE below base R − SLACK)") — which mislabels the
  reason if it ever fires (the plugin's own LRE could be excellent and
  the row would still read as a plugin failure). Whether this should
  instead be OUT OF SCOPE (no yardstick, no basis to score against),
  a FAIL under a corrected status string, or something else, is not
  decided here. Flagged to Fable in
  `mailbox/to-fable/REPORT_ACCEPTANCE_AND_FOREST_2026-09-02.md`.

## 6. What the Tier B verdict is measured against

The Tier B verdict is **not** measured against a fixed target count.
`mailbox/to-opus/WORK_ORDER_NIST_UNIFICATION_2026-08-31.md` item 5,
verbatim: "Counts are outputs, not inputs. The ledger determines the
Tier B result count (standalone is 311; the paper's 626 gets corrected to
whatever the ledger measures)... No number travels from Sol's memo, the
manuscript, or the 29 Aug console into any generated file." The 311
figure (tracker item A.9) is a **measured expectation from the prior
integrated run**, useful as a sanity check that nothing regressed —
**not** a threshold the authoritative run must clear.

What IS fixed in advance, and is the actual pass/fail gate, is the
qualitative condition `compare.R` already computes and prints as its own
GREEN line — this document adopts that line as the Tier B acceptance
gate verbatim, all of the following simultaneously true:

1. `nUnexplained == 0` — no `UNEXPLAINED`/`UNMATCHED_PRAAT`/`UNMATCHED_R` rows.
2. `nMissing == 0` — no contracted quantity is `MISSING_PRAAT`/`MISSING_R` (§4).
3. `nViolation == 0` — no `CONTRACT_VIOLATION_*` row.
4. `kitFail == 0` — every procedure `matrix.tsv` runs has a `quantities.tsv`
   clause and vice versa, and every procedure's own contracted quantities
   arrived complete (the "standing kit" per-procedure walk).
5. `balances` and `allStudiesBalance` — the balance invariant (`compared +
   documented-absent + tolerance-bounded = total`) holds both overall and
   separately for `options` and `sweep`.
6. `nRefuseSetFail == 0` — the three-way refusal-set equality (§5) holds.
7. `nStaleCells == 0` — no result-file row carries a `cell_id` absent from
   the current `matrix.tsv` (the authoritative run cannot sit on top of a
   stale results file).
8. No `DECLARED` `diff`-bucket row outside D-WORDING survives (§2's
   retirement expectation), and every `DECLARED` bound that IS present is
   `HOLDS`, not `EXCEEDED`.
9. The run is **not** a filtered run (`isFilteredRun == FALSE` — every
   cell `matrix.tsv` declares was actually driven by both runners; a
   partial run cannot be the authoritative one).

The Tier B verdict is GREEN when all nine hold. The count of agreeing
comparisons that GREEN run reports is then the number the paper cites —
measured, never asserted in advance.

## 7. What the NIST verdict is measured against

Analogous, from `compare.R`'s per-study balance block: `nNistBalances`
(every certified, in-scope field either compared or explicitly
`NIST_MISSING_PRAAT` — `nNistCompared + nNistMissingPraat == nNistExpected`)
and `nNistDisagree == 0` (zero `NIST_DISAGREE` rows across both branches).
The 98-check figure is, exactly as in §3, a measured expectation from
`v19_nist_strd.R`'s current standalone run, not an input.

## 8. Preconditions the authoritative run must satisfy before scoring begins

Not part of the numeric criterion above, but a run that fails these was
never eligible to be scored against it:

- **One analysis, one extraction, per case.** `mailbox/to-opus/RULING_ONE_RUN_PER_CASE_2026-08-31.md`
  (rev 2): each analysed case must show one analysis computation and at
  most one extraction pass per group (call-count probe on
  `@eml_getGroupData`), on the harness the ruling defines. Without this,
  NIST-scale cells (18,009 rows) do not complete, and a run that never
  finished is not evidence for or against anything in this document.
- **Praat version asserted, not merely recorded.**
  `mailbox/to-opus/RULING_CONSOLIDATED_KERNELS_2026-09-01.md` §4: the
  authoritative run records AND asserts the Praat version (pinned
  6.6.30), failing outright on a mismatch, because `Get TukeyQ`/ptukey
  answers are measured to move across Praat builds — a run on the wrong
  build is not comparable to this document's tolerances regardless of
  what its numbers say.
- **A pushed commit, on Ian's machine.** `mailbox/to-opus/RULING_CONSOLIDATED_KERNELS_2026-09-01.md`
  §5, §7: provenance discipline — the authoritative run happens on Ian's
  machine at a commit pushed to GitHub, container measurements are
  endorsed for interim work but not as the authoritative run itself.

## 9. Sources cited in this document

- `mailbox/to-opus/RULING_NIST_CRITERION_2026-08-31.md` — the NIST
  criterion's shape: one family, two branches; no separate residual-SD
  assertion; counts are outputs.
- `mailbox/to-opus/RULING_ONE_RUN_PER_CASE_2026-08-31.md` — one
  extraction per case, a precondition for a NIST-scale run to complete.
- `mailbox/to-opus/RULING_CONSOLIDATED_KERNELS_2026-09-01.md` — D-clause
  retirement at the rewrite pass; version assertion as provenance; the
  overall run sequence culminating in the Tier B verdict and Fable's
  inspection.
- `mailbox/to-opus/WORK_ORDER_NIST_UNIFICATION_2026-08-31.md` — the
  concrete build order the NIST ruling answers; "counts are outputs, not
  inputs"; the balance-invariant and grand_ledger requirements.
- `walkthrough/kit/compare.R` — the standard agreement rule already in
  force, the DECLARED[] mechanism, the completeness/contract machinery,
  the refusal-set equality check, the balance invariant, the NIST
  scoring block, and the GREEN line this document adopts as the Tier B
  gate.
- `walkthrough/kit/quantities.tsv` — the per-procedure contract §4 scores
  Tier B completeness against.
- `walkthrough/kit/nist_certified.tsv` — the published NIST StRD
  constants and their per-dataset field coverage, behind §4's
  out-of-scope rule.
- `validate/lre.R` — the LRE function, reused unmodified by `compare.R`.
- `walkthrough/kit/README.md` — the plain-language restatement of §2,
  confirming it as the rule already in force.
