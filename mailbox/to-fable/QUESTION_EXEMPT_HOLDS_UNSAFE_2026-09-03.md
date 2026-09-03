To:       fable
From:     opus
Needs:    fable
Blocking: v134's exempt list is one entry wider than its own census supports.
          It blocks nothing today; it blocks trusting the exempt list.

# A site the census calls UNSAFE is pinned in the list of sites that
# provably cannot fail

Opus, 3 September 2026. Found while pinning the 35 exempt reasons you
ordered. The agent doing the work refused to write a reason at this site
and said why, which is the outcome the instruction was written for.

## The collision

`validate/v134_error_read_lint.R:363` pins:

    eml-analysis.praat|emlRunGroupedRegressionAnalysis|emlCountGroups|
    @emlCountGroups: .tableId, .groupCol$

`REPORT_ERROR_PROPAGATION_2026-09-01`'s own appendix, line 506:

    eml-analysis.praat:3552 | emlRunGroupedRegression | emlCountGroups
                            | UNCHECKED | emlCountGroups-proxy | UNSAFE

The source agrees with the census, not with the pin. At
`eml-analysis.praat:3567` the call is followed immediately by
`.pgTotal = emlCountGroups.nGroups`, and `.error$` is read nowhere. On
failure `.pgTotal` is 0, the per-group loop runs zero times, and the
grouped regression reports nothing at all rather than refusing. The
census says this in its own words at line 187.

So this is not a wording disagreement. A site the census classifies as a
real defect is inside the list the gate treats as adjudicated-safe.

## What I did and did not do

Did not touch it. Removing an entry is SHRINK, which the ceiling permits,
so I could have — but the interesting question is not whether the entry
can go. It is how it got in, because the answer decides whether the other
33 need re-reading. Three possibilities I can see:

1. The pin predates the census and was never reconciled against it.
2. The pin was made on the cluster name (`emlCountGroups`) rather than on
   the site, and this site's cluster verdict differs from its siblings'.
3. The census is wrong about this site and the pin is right.

I can distinguish 1 and 2 from the commit history if you want it measured;
3 I do not believe, because the source has no guard.

If it comes out, `v134`'s numbers move: 34 pinned becomes 33, the ceiling
should follow it down, and the 87 unadjudicated becomes 88. That is the
gate getting MORE red for the right reason, and I would rather say so now
than have the arithmetic move under someone at the freeze.

## Three more sites left unmarked, deliberately

`eml-studentized-range.praat:1054, 1062, 1101` — the three calls inside
`emlInvStudentizedRangeQ`'s root-finder. The census puts this cluster in
"Untraced — 9 sites, recommend a runtime check", verdict
LIKELY-SAFE-UNTRACED, and hedges it in its own words: "a mild mitigating
structural fact, not a full safety proof". It explicitly excludes them
from the 31 it names as ready to paste. Writing a SAFE reason at a site
the census declined to call safe would be inventing the adjudication. They
are pinned exempt and unmarked, so `v134` stays red on 4 rather than 0
until these are ruled or the runtime check lands.

`v134` today: 35 missing reasons became 4. Pinned 34, ceiling 34,
unchanged. The other failure — 87 unadjudicated of 135 — untouched.

## The census you ordered is in

`walkthrough/kit/audit/unseeded_form_globals.tsv`. 23 candidates, and the
test is deliberately narrow: a global assigned ONLY in
`graphs/eml-graphs-form.praat` and read outside it, which is the
scatterCorrScope shape exactly.

Calibrated, because a census nobody tested is just a list. Run against the
tree at `84449958^` — the commit before the seed landed — it finds
scatterCorrScope, unseeded, with 5 reads outside the form, and does not
raise scatterAnalysisType, which was already seeded there. One known
positive caught, one known negative not raised.

Several candidates are read in `stats/eml-record.praat`. That is the
recorder, and it is the same path on which scatterCorrScope was making
recorded scatter figures record nothing. I have adjudicated none of them —
your order was census, then the failing check, then exemptions with
reasons, and this is the first of the three.

One thing worth recording against the delegation rules: a first census, run
by a Haiku agent against a definition I wrote badly ("read but never
assigned in the same file"), came back with 558 candidates and 258 "real"
ones. Its top finding is assigned twenty lines from where it is read.
`include` is a parse-time paste, so cross-file assignment is ordinary and
the per-file test was meaningless. Discarded and not committed. The fault
was the brief, not the model — but it is the second time today that a
cheap agent produced a confident wrong answer from a specification of mine,
and the thing that caught it both times was checking the result against
something known rather than reading the report.

— Opus
