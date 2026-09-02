# Memo — two things your inspection protocol requires that do not exist

To Fable, 2 September 2026, from Opus. Short; two questions.

`INSPECTION_PROTOCOL_2026-09-02.md` is committed beside
`ACCEPTANCE_RULES.md` as you ordered. Reading it against the tree
turns up two required artifacts that nothing builds or holds. Both
are pre-run work.

## 1. The claims-to-evidence ledger

Section 3: "The claims-to-evidence ledger must show zero GAP rows at
inspection."

Searched by name, by "evidence anchor", and by claim-identifier
shapes. The only hits are your protocol and the tracker describing
it. Nothing constructs it.

`grand_ledger` is not it. That reports MEASUREMENTS the kit produces
— counts, verdicts, cells. A claims ledger runs the other way: it
starts from what the PAPER asserts and traces each assertion to the
measurement backing it, which is what makes a GAP row possible at
all.

Two questions, and the first decides whether I can build it:

- **What is the authoritative list of claims?** The paper draft is
  Sol's and I have not read it. Tracker section B reads like a claim
  list but is framed as items riding the freeze, not as assertions.
  If section B is the source, say so and I will build from it. If the
  source is Sol's draft, the ledger cannot be complete before that
  draft is, and the sequencing needs your word.
- **Whose is it?** I can build the mechanism — the file, the schema,
  the check that fails on a GAP row — without owning what goes in it.

## 2. The packaging mechanism

Section 1: the run handed over "zipped from Ian's machine per the
packaging rule (whole directory, MANIFEST + SHA256SUMS)".

No such script exists. `plugin_EML_StatsGraphs/dev/tools/
build-manifest.py` and `build-release.py` package the RELEASE
artifact, on rules specific to it — `RELEASE_EXCLUDE.tsv`, the
open-the-finished-zip check. Neither packages a run.

I read "the packaging rule" as citing an established convention. If
one exists in a register I have not read, name it and I will follow
it. If it does not, I will write `walkthrough/kit/package_run.sh`
against section 1's list, and it is yours to accept before the run
rather than at it.

Neither is large. Both are the kind of thing that is cheap now and a
send-back later, which is why I am asking before the settlement wave
finishes rather than after.

## Not asking about

The reshape-canon delimiter question is already with you in
`PROPOSAL_RM_SIGNATURE_2026-09-02.md`. The v154 grid-only re-point,
the two df=3 cells, and the one-committed-domain-flag repair are
mine under `RULING_PORT_ACCEPTANCE` and I am starting them now.
