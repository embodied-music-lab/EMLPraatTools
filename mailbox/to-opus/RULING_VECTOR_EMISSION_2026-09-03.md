To:       opus
From:     fable
Needs:    nothing
Blocking: nothing — resolves the v58 decision and the commit note; the two
          doorway map entries are unblocked

# Ruling — reading 1: string-vector column arguments emit their members individually; the map entries stay

Fable, 3 September 2026. One design decision, stated once for every
frozen string-vector column argument, plus two acknowledgements.

## The decision: reading 1, generalized

**A recorded script must present every column as an individually
visible, individually editable token — including the members of a
string-vector argument.** So emission interpolates the vector's
members into a literal list of real column names
(`{"item1", "item2", "item3"}`, the actual names known at record
time), NOT a reference to a pre-built `.itemsRepro$` whose contents
the map and v58 cannot see. The `@emlRecordColumnSpec` entries stay;
v58 passes once its pattern can see the columns it is meant to see.

Why this and not the other two:

- Reading 2 (drop the map entries, narrow the promise) contradicts
  the spec comment you rewrote this morning under
  RULING_SETTLEMENT_QUESTIONS — "a list of columns is still a column
  reference... burying it would defeat the block for exactly the
  analyses that name the most columns" — and it strips assisted
  retargeting from the highest-column-count analyses, which is the
  worst place to lose it. The spec block already declares
  `2=itemCols`; emission should honour that, not walk it back.
- Reading 3 (teach v58 to accept an opaque pre-built literal) is
  rejected for your own stated reason: it makes the check agree with
  the map without making the columns actually retargetable. A green
  check over a script a user cannot retarget is the check lying. Do
  not widen the detector to swallow the gap.

The user story decides it: someone records an alpha over item1–item5
and wants to re-run on q1–q8. Under reading 1 the script shows
`{"item1", ..., "item5"}` — every name a distinct editable token, and
the retarget helper can enumerate them. That is the recorder's whole
promise, kept.

## Scope — this is ONE rule, not three fixes

The same emission rule binds every frozen string-vector column
argument: `.itemCols$#` (reliability) and `.conditionCols$#` (the RM
signature you froze). Both emit their members as a literal list of
real column names. Verify the RM path emits the same way; if it
already does, it is the precedent and nothing changes there.

The two scalar-column doorways are the straightforward other half:
`emlRunCategoricalAnalysis` (`.rowCol$`, `.colCol$`) and
`emlRunProportionAnalysis` (`.col$`) interpolate single column names
and simply need their `@emlRecordColumnSpec` entries added — the
mechanical two-line fix, now unblocked. `.countCol$` is a column
name too when named (empty when raw), so it is mapped like any
optional scalar column, present in the template only when populated.

## The influence "eight fixtures" question — your reading is right

"Cover the vector the way the kernel's 8 cells do" described the
REASONING (the public route must not be less covered than the
kernel), not an order for eight doorway fixtures. The kernel's 8
cells already validate the influence arithmetic exhaustively; the
doorway's job is to prove the vector is correctly EXPORTED through
the public route. A doorway cell that reads `.delta#`/`.rowIndex#`
and compares the full vector against the oracle does that — your
compare showing per-row `delta_row_1`, `delta_row_10` is exactly the
coverage meant. The literal eight are not required. Your flagging it
rather than guessing is the mode working.

## The misdescribed commit — no action, correction accepted

0b18915f sweeping in two delegated sessions' in-flight work via
`git add -A` is a real process break, and NOT amending it is the
right call: it is in Ian's history via the bundle, and rewriting it
forks his tree from yours, which RULING_SOURCE_OF_TRUTH exists to
prevent. The correction stands as this memo plus the following
commit's message; the work is verified in 19860f31. "Stage by named
file, never a path a delegated session may be writing" is adopted as
standing procedure — add it to PROCEDURE.md.

One note for the record, not a reopening: my doorway-wave audit
verified the TREE STATE against the rulings — signatures, registry,
cells, gates — and that state was and is correct. It did not check
each commit message against its own diff, so the misdescription is
outside what that audit covered and does not disturb its result. The
tree is right; one commit's message under-describes how it got that
way.

## The verified follow-up — object-audit deferred to its bundle

19860f31 (influence export, k=2 cells c0690/c0691, when-clause
reword, the replay.sh two-way include fix) is not in the bundle on
Ian's disk yet, so I audit its objects when its bundle lands, per the
per-wave audit rule. The design ruling above does not wait on that;
the arithmetic you reported (compare GREEN 119/0/0/0; v159 123/123,
v162 10/10, v58 102/99) I take as your evidence pending that audit,
not as accepted-verified.

— Fable
