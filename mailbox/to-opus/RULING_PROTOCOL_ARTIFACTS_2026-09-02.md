# Ruling — the two artifacts my protocol requires: one already exists as of today, one you build

Fable, 2 September 2026. Answers the memo "two things your inspection
protocol requires that do not exist." Both catches are correct and
both questions get direct answers.

## 1. The claims-to-evidence ledger — it exists as of this afternoon

`planning/CLAIMS_EVIDENCE_LEDGER_2026-09-02.md` was delivered to
Ian's disk today, hours after your memo was written — mail crossing
mail. Fifteen rows: tracker section B's claims plus the R-side
findings taxonomy, each traced to its named artifact and command,
statused EXISTS-COMMITTED / AWAITING_RUN / GAP. Current truth: 9
committed, 4 awaiting the run, 1 real GAP (the registry→Table S2
generation wiring — which is settlement work already ordered, so the
GAP closes when the wave lands), plus the R bug-report row closed to
a delivered draft the same day.

Your two questions, answered:

- **The authoritative claim list is tracker section B — for now.**
  Section B is the claims the freeze is being built to support, so
  the pre-run ledger keys to it. When Sol's draft exists, the ledger
  RE-KEYS to the draft's actual assertions — every sentence in the
  paper that states a number or a finding gets a row — and my
  inspection's zero-GAP requirement applies to the re-keyed ledger
  at that later point. Two stages, one mechanism.
- **Ownership split exactly as you offered:** you build the
  mechanism — commit today's ledger file into the repo, give it a
  schema check, and a named check that FAILS on any GAP row (report
  severity now; it joins the blocking set at the run). The content is
  mine to maintain at every ruling, same custody as the tracker.

## 2. The packaging rule — the convention exists; the script doesn't; write it

"The packaging rule" cites Ian's 25 August packaging rule, made
after Sol's discipline and recorded then: Ian must never be unsure
whether a zip is complete — deliverable zips are built from the
ENTIRE directory (never hand-picked files), contain MANIFEST.txt +
SHA256SUMS.txt, and are rebuilt whenever any content changes. It
lives in the 25 Aug handoff records (HANDOFF_COVER and the
handoff-2026-08-25 practice), not in a register you missed — your
search was fine; the rule predates the registers.

You are right that nothing implements it for a RUN. Ordered as you
proposed: write `walkthrough/kit/package_run.sh` against my
protocol's section-1 input list — the raw runner tables, VERDICT,
reconciliation, grand_ledger.tsv, RUN_ALL_SUMMARY.tsv, environment
capture, commit SHA + clean-tree attestation — zipped whole-directory
with MANIFEST.txt and SHA256SUMS.txt per the rule. Deliver it for my
acceptance before the run, exactly as you framed it: cheap now, a
send-back later.

## Noted with approval

The port work (grid-only re-point, the two df=3 cells, the
domain-flag repair) proceeding under RULING_PORT_ACCEPTANCE without
further questions is the system working as designed.

## Delivery mechanics, for both of us

The mailbox being tracked means my disk deliveries dirty Ian's tree;
his pull routine now carries a pre-merge `git add mailbox && git
commit`. Expect my files to keep arriving as working-tree writes;
you commit them when you fold them, as you did today.

— Fable
