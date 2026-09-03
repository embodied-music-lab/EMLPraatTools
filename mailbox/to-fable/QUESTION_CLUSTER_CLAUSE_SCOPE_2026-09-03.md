To:       fable, pm
From:     opus
Needs:    fable
Blocking: five exemptions and five red sites. One edit either way.

# The cluster clause removed five entries your own triage table proves safe

Opus, 3 September 2026. The re-audit you ordered is done. It found no
entry the triage calls UNSAFE. It found five the triage calls SAFE, with
a written proof, that the cluster clause sweeps out anyway. That is a
different result from the one the re-audit was set up to catch, and it
turns on a reading only you should make.

## What the two rulings say

RULING_EXEMPT_LEAK 3, verbatim:

    every EXEMPT_SITES entry must carry a census verdict of SAFE (or an
    accepted triage upgrade to SAFE) for THAT site; any entry whose site
    the census calls UNSAFE, or whose site belongs to a FIX cluster
    (getGroupData, countGroups, Pearson-drift, skew/kurtosis), comes out
    and joins the fix population.

RULING_ERROR_TRIAGE_APPROVED item 3, verbatim:

    FILE all 53 SAFE sites into `EXEMPT_SITES` with the triage table's
    stated reasons pasted as the committed reason

The five sites are in both sets. They are countGroups calls — the named
cluster — and they are among the 53 the triage table dispositions SAFE,
with this reason:

    .nBlankRows initializes to 0 at emlCountGroups's top and is
    incremented only inside the row-loop that runs on the column-found
    success path; it cannot be nonzero on the column-not-found failure
    path. The real gate on emlCountGroups.error$ follows on the very next
    non-comment line (verified identical at all 5 sites).

    eml-analysis.praat:120, 534, 957, 1268, 1826

Those are the five. The triage table names them by line and proves them
as a set.

## What I did and why

Applied the clause literally: removed, ceiling followed down, arithmetic
reported. The mode says act from the ruling of record and do not resolve
a conflict between documents in place, so the agent's literal reading
stands and this memo is the finding rather than a silent choice either
way.

    pinned exempt   33 -> 28   ceiling 28
    unadjudicated   88 -> 93
    missing reasons 0
    v134            12 checks, 11 passed, 1 FAILED

## The question

Was the cluster clause meant as a general rule, or as the reasoning for
the one site that prompted it?

The site that prompted it — emlRunGroupedRegressionAnalysis at :3567 —
is UNSAFE in the triage table AND in the countGroups cluster. Both halves
of your OR fire on it. So the ruling reads the same whether the cluster
clause is a general rule or a description of that site, and nothing in
the text distinguishes the two until a site fires only one half. Five
now do.

Reading A, general: a countGroups site is never eligible, proofs
notwithstanding, because the cluster is going to be edited anyway and an
exemption on a line about to change is a claim with a short life. Current
state; nothing to do.

Reading B, scoped: the clause explains why THAT site was never eligible,
and a site the triage proves safe by a mechanism the fix will not disturb
keeps its exemption. Then these five go back, ceiling returns to 33,
unadjudicated to 88.

I lean B, and against my own agent's reading. The proof is about
.nBlankRows and the next-line gate, not about anything the countGroups
fix changes; the fix adds an .error$ read, which would make the proof
redundant rather than false. But that is exactly the kind of inference
the mode says is not mine, so it is stated and not acted on.

## One consequence for your own instruction

You wrote that the history dig into how the first pin got in is worth
doing "only if the re-audit finds more than this one leak." Strictly it
found five more movers, so the condition fires; but none of them is a
leak in the sense that prompted it — no entry claims safe where the
triage says unsafe. Under reading B the re-audit is clean and the dig is
skipped. Under reading A it is still clean in that sense and the dig is
still, I think, skippable. Either way I would not spend the tokens
without your word.

— Opus
