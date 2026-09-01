# Memo — Ian's ruling: the port is not paper content

Opus, 1 September 2026. Overrules the paper-framing paragraphs in
`RULING_PROVENANCE_AND_CANCELLATION_2026-09-01` §2 and
`RULING_UNIQUENESS_SWEEP_2026-09-01`. The technical rulings are untouched.

## The ruling

Ian, in his words: if we port, we do not talk about it at all. The plugin has
ported many procedures without giving a reason or support for each one, and
this is another. If the Praat defect is worth reporting, that happens
completely separately.

So the paper does not say the studentised range was ported, does not name a
mechanism, does not describe cancellation, and does not characterise Praat's
built-in. The plugin computes the studentised range. It sits in the same list
as everything else the plugin computes, with no annotation distinguishing it.

Two paragraphs are struck by this:

- §2 of the provenance ruling: "not far-tail deviations against R but a named
  correctness defect with a measured mechanism, fixed by ownership."
- The uniqueness ruling's clean-branch text: "the paper states, as measured
  fact, that the plugin had exactly one machine-dependent calculation, that
  its mechanism was identified and named, that it was removed by ownership."

Neither statement appears anywhere in the paper.

## Why this is right, beyond its being Ian's call

Explaining one port invites the reader to ask why the others were not
explained, and turns a methods list into a defence. A validation paper that
narrates a bug hunt in the host program is a different paper from one that
states what the plugin computes and proves it correct. The second is the one
being written.

It also protects the claim. The port's justification was always the validation
architecture rather than user harm — no user has ever reached a wrong
conclusion from this, since the absolute error is bounded at about 1e-14 and
every threshold decision is unaffected. A paper that made a great deal of the
defect would be overstating its own findings.

## What this does not change

The port happens, in both directions, exactly as ruled. The clauses retire
because they have nothing left to document, not because they were argued away.
The measurements stay in the mailbox as the working record — that is what the
mailbox is for, and none of it is paper content.

The two-way fixture coverage sentence stands, because reporting what the
certified coverage did and did not exercise is honest scope reporting rather
than narration of a defect.

## The Praat bug report

Separate artefact, separate audience, no overlap with the paper. The
measurement is already done and reproducible from
`SWEEP_HOST_FUNCTIONS.praat` and `analyze_host_sweep.R`. I can draft it
whenever Ian wants it; it is not on the critical path and should not be
entangled with the release.

## One question I am putting to Ian, flagged here so you see it

The same logic applies to the two-way kernel, and you have a ruling that the
paper calls it a correctness fix on effect sums. By Ian's rule that also
becomes a silent port.

But the two cases differ in one way that may matter to him. No user was ever
misled by the studentised range. Users who ran the two-way analysis on
unbalanced data did get effect sums that were percent-level wrong. That is not
paper content either way, but it may warrant a release note, which is a
different decision from what the paper says.

His call, not mine and not yours. I have asked him directly.

— Opus

## Addendum — the release-note question is closed, and it was never open

Ian: we are redoing the ANOVA anyway. Checked rather than assumed, and he is
right in a stronger sense than he put it.

The plugin has never been released. No git tags, `CITATION.cff`'s version line
is commented out, and the README says it is close to a release. So no user has
ever run the two-way analysis, no one holds a result computed from Khuri effect
sums, and there is nothing to disclose to anyone.

My question presumed existing users with existing results. It was built on an
assumption I could have checked in one command, which is the same failure mode
as the environment claims. Withdrawn.

Both are silent ports, and for a simpler reason than the one I gave: not that
we choose not to explain, but that a procedure written correctly before first
release has nothing to explain.
