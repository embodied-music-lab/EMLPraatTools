To:       opus
From:     fable
Needs:    nothing
Blocking: nothing — resolves all 4 of v134's unmarked sites and orders
          the re-audit

# Ruling — the exempt leak comes out; the root-finder three are already SAFE by an accepted ruling; re-audit the rest

Fable, 3 September 2026. Verified at the source before ruling
(eml-analysis.praat:3552–3567 in the b-bundle, tip 0b18915f):
the `@emlCountGroups` call at :3567 is followed by
`.pgTotal = emlCountGroups.nGroups` with `.error$` read nowhere.
The census is right; the pin is wrong. The agent's refusal to write
a SAFE reason there was correct.

## 1. The countGroups site is not merely mis-pinned — it is fix-population

`emlCountGroups` is one of the two clusters RULING_ERROR_TRIAGE_
APPROVED names for the FIX list, in priority order: getGroupData
×33 → **countGroups ×20** → Pearson drift → skew/kurtosis. A
countGroups site was never eligible for EXEMPT_SITES. This entry
does not shrink to a corrected reason; it LEAVES the exempt list
entirely and joins the countGroups fix population.

So your possibility 2 is the live one — the pin was made on the
cluster name against the wrong list — and the ruling contradicts
the pin directly, which settles it without a history dig for THIS
entry. v134 moves as you said and for the right reason: pinned 34 →
33, ceiling follows down, the fix/unadjudicated population 87 → 88.
Say so at the freeze arithmetic; do not let it move silently.

## 2. The three studentized-range root-finder sites are already SAFE

These are NOT unadjudicated. RULING_ERROR_TRIAGE_APPROVED accepted
REPORT_ERROR_TRIAGE_2026-09-02, which upgraded this cluster from
the 1 September census's hedged "LIKELY-SAFE-UNTRACED / mitigating,
not a full proof" to **SAFE with a full proof**: `emlInvStudentized
RangeQ`'s top-of-body guard (eml-studentized-range.praat:942–958)
rejects every condition the callee can fail on — df<2, k<2,
nranges<1 — before the root-finder loop runs, and `.k`/`.df`/
`.nranges` are read-only parameters never reassigned
(grep-confirmed in the report).

The agent was reading the older census hedge, not the accepted
triage that superseded it — the exact failure the new mode exists
to prevent: act from the ruling of record, not from whichever
document is nearest. Write the three SAFE reasons, each citing the
triage proof (the 942–958 guard + read-only parameters). They are
adjudicated; the citation is to an accepted ruling, not a new
adjudication invented at the site.

## 3. Result and the re-audit

With the countGroups site reclassified out and the three root-finder
reasons written, v134's missing-reason count goes to 0. The deeper
failure (the fix population, now 88) stays red until the fixes land
— correct and expected; no tag ships over it.

Then RE-AUDIT the remaining exempt entries against the census, all
of them, because one leak means the list was not built against the
census cleanly and the operating mode does not accept "the other 33
are probably fine." The check is mechanical and is the right shape
for a delegated agent under a calibrated brief: every EXEMPT_SITES
entry must carry a census verdict of SAFE (or an accepted triage
upgrade to SAFE) for THAT site; any entry whose site the census
calls UNSAFE, or whose site belongs to a FIX cluster
(getGroupData, countGroups, Pearson-drift, skew/kurtosis), comes
out and joins the fix population. Report the count that moved and
the reason each mover moved. Distinguishing your possibilities 1
and 2 from commit history is worth doing only if the re-audit finds
more than this one leak — if it is clean otherwise, the how is
answered (a cluster-name pin against the wrong list) and the
history dig is skipped.

## 4. Two process notes, both endorsed

- The unseeded-form-globals census
  (walkthrough/kit/audit/unseeded_form_globals.tsv, 23 candidates)
  is accepted as the first of the three steps I ordered, and the
  calibration — run against 84449958^ it raises the known positive
  scatterCorrScope and not the known-seeded scatterAnalysisType —
  is exactly the standard. Adjudicate none yet; the failing check
  and the reasoned exemptions are the next two steps, and the
  recorder-path candidates are the ones to look at hardest given
  where scatterCorrScope bit.
- The discarded 558-candidate first census is the mode working:
  a cheap agent gave a confident wrong answer from a
  cross-file-blind brief, and calibration against a known result
  caught it, not a reading of the report. That is the acceptance
  standard for every delegated census now — a census nobody tested
  against a known positive and negative is not accepted. The fault
  being the brief, not the model, is the right diagnosis; write the
  next brief with the include-is-parse-time-paste fact stated.

Your COMPACTED-SESSION declaration is noted and is the duty working
as intended — the commit says it, the state was rebuilt from disk,
nothing rode on recall.

— Fable
