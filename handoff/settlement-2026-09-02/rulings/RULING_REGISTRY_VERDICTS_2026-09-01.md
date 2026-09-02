# Ruling — Ian's verdicts on the five flags; bridge unification joins the pre-run wave; punch-list intersection ordered

Fable, 1 September 2026. Relays Ian's decisions on
`PROPOSAL_CANONICAL_NAMES_2026-09-01.md`'s flagged questions, with the
resulting orders. The SIX RENAMES ARE NOT YET ACCEPTED — Ian has the
proposal and has ruled only on the design flags; do not execute any
rename until his line-by-line acceptance arrives.

## 1. emlRunLMMAnalysis — post-1.0 (Ian's ruling)

The row comes OUT of the registry for 1.0, same mechanism as the
reliability stub: an explicit, documented exclusion-list entry —
"implemented and validated; menu and wizard doors withdrawn; public
post-1.0" — with checks that fail if the entry goes stale. Table S2
stays at 42 rows. The erosion check's `emlRun*` pattern is satisfied
by the exclusion entry exactly as for the stub.

## 2. Recorder hooks — fix two, and census the rest (Ian's ruling)

`emlRunGroupedRegression` and `emlDrawQQPlot` get recorder hooks —
Ian judges both oversights. And Ian orders a thorough second look:
a MEASURED recorder-coverage census over every registry row — for
each row, does the recorder emit a replayable call for the
corresponding interactive path, demonstrated (one recorded session
per row class, or a code-level trace with the emitting site named),
not asserted. The census either confirms these two were the only
gaps or names the others; any others found are fixed in the same
pass. Census result comes back with the emitting site per row.

## 3. emlRunRepeatedMeasuresAnalysis .subjectCol$ — report before decision

Ian wants the factual story before ruling — his words: "I can't
imagine we built something we didn't mean to use, but maybe."
Ordered: a code-level report, not a fix — (a) what the RM procedure
ACTUALLY uses today to identify subjects; (b) who passes
`.subjectCol$` and with what values (doors, wizard, recorder, kit);
(c) what would change if a caller supplied a real column name; (d)
the history if it is visible in the tree (a parameter added for a
signature settled in the RM string-vector decision, or a remnant).
No behavior change until Ian sees the report and rules wire-or-remove.

## 4. The annotation bridge — unified BEFORE the authoritative run (Ian's ruling)

Ian: "We absolutely need to fix that." The duplication is resolved by
making the bridge CALL the Family A dispatch rather than carrying its
own implementation of the same four tests. Sequencing rationale,
which is Ian's own settlement principle: the bridge is public
surface; freezing a validation record over a second implementation we
intend to replace immediately after is exactly what the API
settlement exists to prevent. So the unification joins the pre-run
settlement/rename wave, under these pins:

- behavior-preserving: an equivalence probe per test route (bridge
  result ≡ Family A result on the same data, at the standard rule)
  BEFORE and AFTER the change, plus one red demo showing the probe
  can fail;
- the bridge keeps its public name and signature (whatever Ian
  accepts in the rename pass); only its inside changes;
- the kit's canonical-route coverage picks up the unified path.

## 5. The original punch list — intersection with the kit, measured

Ian's suspicion is that items 7, 8 and higher of the doors/unification
punch list (`PUNCH_LIST_DOORS_UNIFICATION_2026-08-25.md`) have not
been revisited, and his sequencing rule is: the unification round
itself waits until the kit completes, BUT nothing the kit's own waves
touch should be deferred if the unification round would need it.

Ordered: read the punch list against the settlement/rename/outcome-
contract wave plans and produce the INTERSECTION — every punch item
that touches surface the pre-run waves already modify (files, public
rows, door registrations, shared procedures like the filed
range-refusal extraction 8.5). For each: item, what wave touches the
same surface, and a one-line recommendation (fold into the wave now
vs. genuinely separable post-kit). The intersection comes to me for
ruling; nothing from the punch list executes on this order alone.

## Standing

Port acceptance continues on RULING_WAVE_THREE's terms (grid
regeneration first). The rename wave holds for Ian's acceptance of
the six proposed names.

— Fable
