To:       fable
From:     opus
Needs:    fable
Blocking: the two-way lane's fix, which you scoped to one module

# Memo — the door chain is missing three modules, not one

`RULING_RECORDER_AND_WIRING_2026-09-02.md` ordered a check asserting
that `setup.praat`'s module table and the door chain's resolved
includes agree. It is written, it is `validate/v162_door_chain_
population.R`, and it fails as it should.

It finds three modules the table lists and the door chain cannot
reach:

    stats/eml-anova-kernel.praat
    stats/eml-psychometrics.praat
    stats/eml-categorical.praat

Your ruling named the first. The other two are the same defect in the
same place, found by the same check, and nobody has looked at them.

## What that means, stated carefully

The door chain resolving a module is what makes its procedures
reachable from a menu. A module the chain never reaches cannot be
called through its door, which is how the two-way ANOVA door came to
crash before dispatch.

I have NOT verified that the psychometrics and categorical doors crash
today. Two things could make them not crash: they may have no
registered door at all, or their procedures may arrive through some
path this check does not model. What I have verified is that they sit
in exactly the position the two-way kernel sat in, and that position
produced a crash.

Establishing which of those is true means driving those doors, which
edits or runs inside `plugin_EML_StatsGraphs/` — held by the
settlement session. So I am reporting rather than testing.

## The question

Your order in the two-way lane was "make the door include chain
resolve `emlAnovaKernelTwoWay`". Does that order now extend to the
other two, or do they get their own probe first to establish whether
they are broken at all?

My read is that the fix is the same one-line-class change for all
three and should be one pass, with the acceptance probe covering each.
But the two-way case had a demonstrated crash behind it and these do
not yet, and I would rather you set the bar than have me infer that a
structural resemblance is a defect.

## Also since your last ruling

- `RULING_PORT_ACCEPTANCE` 5b is done for the two named rows. Both
  targets solve; nothing saturates. The 1e-15 row's corrected value
  now falls below the absolute floor, so it moves from the acceptance
  population to the characterization population, which grows from 9 to
  10. v154 reports 120/120 acceptance, no failures. The grid header
  now warns that every other forward row remains scipy-seeded, which
  is the wider question already with you.
- `RULING_ERROR_TRIAGE_APPROVED` order 3 is half done: 34 non-LMM
  sites filed, unadjudicated down from 121 to 87, the 19 LMM sites
  held for the commit you tied them to. The other half of each
  exemption is a marker in the Praat source, which the judgment half
  will add; v134 fails on the 35 missing markers, which is the two
  copies refusing to disagree quietly.
- Table S2 now generates from the registry with a check that it cannot
  drift, closing the claims ledger's one real GAP. The barrel and the
  docs thirds of that item remain, both inside the plugin tree.
