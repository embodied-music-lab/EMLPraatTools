# Memo — the reference grid's forward rows were never solved for q

To Fable, 2 September 2026, from Opus. One finding wider than the
ruling that turned it up, one ordered action taken, one scope
question for you.

## Point 4 closes: the port is fixed, not named

Both k=10, df=3 cells converge. One value changes — the geometric
sub-panel mesh's starting width, 0.005 to 0.0005. Relative error at
those cells falls from 4.0e-03 and 1.0e-02 to about 2.7e-10, then
plateaus, so nothing is gained below that. Cost is not measurable:
3.66 s/pair before, 3.47 s/pair after. No cell regresses; four more
improve that had been invisible because R and scipy both underflow
to zero there.

v154 now reports 121/121 acceptance cells passing, 9 characterization
cells, no failing cell. A.2 closes on your terms.

## Point 5b does not close, and the reason is worse than the symptom

You ordered: try escalating the solve, and if it saturates, relabel
the rows and name a grid floor at df=3.

It does not saturate. The deep target solves — 1e-15 reached to 7.1e-9
relative, at about 375 seconds for the confirming evaluation. So the
relabel branch does not apply.

The reason those rows were wrong is not a numerical floor. It is
this, from `build_srange_reference.py`:

**Forward rows never solve for q at all.** They take
`qGuess = SR.isf(p_target, k, df)` — scipy's own inverse — and record
whatever true probability that q happens to give. The mpmath integral
at that q is correct and converged. The q it was handed is not the q
the row claims.

At df=3 that deep, scipy is catastrophically wrong, so the handed-in
q is wrong by orders of magnitude:

    R  ptukey(5100.22, 10, 3, upper) = 0
    R  ptukey(7916.06, 10, 3, upper) = 0
    scipy sf(5100.22, 10, 3) = 6.17e-11   true 3.67e-10   rel err 0.83
    scipy sf(7916.06, 10, 3) = 9.99e-16   true 9.81e-11   rel err ~1.00

That is why both rows land near 1e-10 whatever they claim to target.

A second defect sits behind it: the file's own root-finder,
`invert_q_for_p`, trusts a cheap interior tier that is itself
under-resolved that far out and falsely reports convergence. Proof:
re-seeding it at its own stalled answer makes it exit immediately
while a full evaluation at that same q disagrees.

## What I have done, and what I have not

DONE, because your point 5b orders it: the two named rows are being
re-solved, with the candidate root verified by a full escalated
evaluation rather than the cheap tier's self-check. Their q values
change substantially — one from 7916 to about 365094 — so those cells
become different cells and v154 re-runs against them.

NOT DONE, because it is wider than any ruling covers: **every forward
row in the grid was built this way, not only the two at df=3.** For
most rows scipy's inverse is accurate enough that the recorded
probability lands near the stated target and nobody noticed. The
labelling is nominal everywhere in the forward half; df=3 is only
where it became visible.

## The question

Do the other forward rows get re-solved too?

Arguments for: the grid is the thing everything else is judged
against, a row that states a target its q does not solve is a
mislabeled reference wherever it sits, and your own words are that
compute is cheap next to that.

Arguments against: the error is small away from df=3, the regenerated
values shift every downstream comparison, and the cost is real —
roughly 350 to 400 seconds per hard cell for the confirming
evaluations.

My read is that they should be, and that the grid's header should
state that forward rows are root-solved rather than seeded, so the
next reader cannot assume what I assumed. But re-generating the
reference under everything is not a thing to do on my own reading of
a ruling written about two rows.
