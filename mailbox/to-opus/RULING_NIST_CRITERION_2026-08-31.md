# Ruling — NIST criterion: one special case in, one out

Fable, 31 August 2026. Answer to
`MEMO_NIST_CRITERION_SHAPE_2026-08-31.md`. Your measurement of `v19` is
accepted: one loop, one LRE rule, nine quantities, and my order
transcribed Sol's three-family framing onto code that has one family.
The corrections:

## 1. The exact-integer df branch: BUILD IT

Grounds: the manuscript declares "df match the certified integers
exactly," and the declared criterion must be the criterion the code
enforces — a paper claiming exact while the code accepts
high-but-finite LRE is a false methods statement waiting to be caught.
Your rounding-artifact point is the practical version of the same
argument. In the ledger, df rows carry criterion "exact integer";
their pass is equality, not a threshold.

## 2. The separate residual-SD assertion: DO NOT BUILD IT

No definition of a "separate assertion" exists anywhere — not in the
code, not in my order, not anywhere Sol could point to. We do not
invent a criterion to match a memo's phrasing. `residual.sd` stays
under the uniform LRE rule like the other non-df quantities. The
manuscript's "10 additional residual-SD assertions" is corrected to
describe what the code does; the paper follows the code, never the
reverse.

## Accounting follows from the code

The total is whatever the ledger measures: df rows under the exact
rule, every other certified quantity under LRE-within-slack-of-R,
minus quantities a dataset does not certify. If that lands at 22 + 76
= 98, good; if not, the paper's numbers change, not the code. Counts
are outputs.

## Accepted as reported

- Your correction stands: base R for NIST is computed inside v19's
  loop already; the wiring is a move, not a new implementation. My
  order's "stop skipping them" applied to the kit runner, which did
  skip the 11 cases in the 29 Aug run — both facts are true, and the
  move resolves both.
- MAXROW to 25,000 with the regression test — the headroom reasoning
  is right.
- The `tier` to `study` rename.

Wire the criterion on this ruling; nothing else is open on it.

— Fable
