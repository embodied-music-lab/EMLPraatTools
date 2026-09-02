# Gate-inspection protocol — pre-committed before the run (tracker A.10)

Fable, 2 September 2026. This is the bar my inspection will apply to
the authoritative run, written and delivered BEFORE the settlement
wave completes so it cannot bend to results. Opus: commit this file
beside ACCEPTANCE_RULES.md — the same before-the-run discipline, for
the same reason. Changes after this point are amendments on the
record, not silent edits.

## 1. Inputs the run must hand me

A pushed commit SHA with a clean-tree attestation from the run
machine; the raw runner tables (audit/praat_results.tsv,
audit/r_results.tsv), VERDICT.txt, the reconciliation table,
grand_ledger.tsv, validate/RUN_ALL_SUMMARY.tsv, and the environment
capture — all zipped from Ian's machine per the packaging rule
(whole directory, MANIFEST + SHA256SUMS). A missing input is a
send-back, not a workaround.

## 2. What I reproduce independently (author-is-never-verifier)

1. compare.R re-run in my container on the raw tables; verdict
   byte-compared against the run's VERDICT.txt.
2. Every headline count re-derived by MY OWN join over the raw
   tables — comparisons, agreements, per-bucket and per-family
   totals — and the balance identity re-counted two independent
   ways. compare.R agreeing with itself proves nothing; this step is
   the point.
3. grand_ledger.R re-run; TSV byte-compared; every MEASURED row's
   derived_from re-parsed by an independent read; freshness relations
   green (no three-generation file sets).
4. Bounds re-measured from the raw rows: worst relative and absolute
   error per bucket; the declared-family table conforms to the
   acceptance rules (only D-WORDING remains as a both-sides diff
   clause — any other surviving declared row is a finding);
   D-WORDING re-measured, not carried.
5. Registry surface: docs/barrel/Table S2 regenerated from
   REGISTRY.tsv and byte-compared; exactly 42 rows; the exclusion
   entries (LMM, reliability) present and staleness-checked; the
   erosion check demonstrated red on a scratch door registration.
6. Studentized range: v154 re-run grid-only per RULING_PORT_ACCEPTANCE
   — characterization cells labeled and outside the pass tally; the
   two k=10, df=3 cells either passing or carried as NAMED bounds in
   port header + paper; the re-pointing grep (Get TukeyQ /
   Get invTukeyQ nowhere outside the port's file) re-run by me.
7. Error gate: v134 re-run green; EXEMPT_SITES and the ERROR-READ
   EXEMPT source comments agree mechanically; I spot-audit ten
   exemption reasons against the cited source lines.
8. Settlement gate: v159 re-run fully green, §E included; my own
   grep for each retired name as a bare word (excluding mailbox/ and
   audit/, which preserve history by rule) returns nothing.
9. Equivalence records: the bridge unification's before/after probes
   plus its red demo re-run; the RM wide/long equivalence probe plus
   its red demo re-run; the RM long-form R-oracle leg present.
10. NIST: the LRE branch re-computed independently for every
    certified quantity; the 22 df cells by exact integer equality;
    any R_UNAVAILABLE row adjudicated by name before green.
11. Tier B: the verdict derived from the 311 standalone quantities;
    nothing reused from run_29_aug (checked, not assumed).
12. Provenance: version assertion present as a PROVENANCE record with
    build info recorded unasserted, in those words; the run commit
    reachable on origin/main.

## 3. The evidence-anchor standard

Every number destined for the paper traces grand_ledger → backing
file → command. I re-run at least ten anchors end-to-end, chosen by
me at inspection time, not announced in advance. The
claims-to-evidence ledger must show zero GAP rows at inspection; an
AWAITING_RUN row that the run should have filled and did not is a
send-back.

## 4. Failure conditions — send-back, no negotiation

Any unexplained byte difference in a regenerated artifact; any count
that differs under my independent join; any red gate (v134, v154,
v159, compare.R's GREEN conditions, ledger freshness); any surviving
declared clause other than D-WORDING; any "verified" claim without
its re-runnable artifact; any missing input from section 1. A
send-back names the failure and stops the freeze — partial credit is
what this protocol exists to prevent.

## 5. Non-blocking findings

Anything real but not freeze-blocking goes to Opus as named notes
with the memo cited, exactly as the 27 Aug inspection's two notes
did. Cosmetics never block; missing evidence always does.

## 6. Output

One inspection report: per-item PASS/FAIL with my own command outputs
quoted, the ten anchor re-runs listed, findings split
blocking/non-blocking, and a single recommendation line — FREEZE or
SEND-BACK with the named reasons. The 27 Aug certification stands as
its own historical record either way; this inspection judges the new
run only.

— Fable
