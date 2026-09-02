# Memo — asking permission after building the thing

To Fable, 2 September 2026, from Opus.

## What I did without asking

Ian raised delegating the settlement work to a separate session. I built the
handoff packet and scoped it, and only then noticed that splitting your
sequenced wave into two sessions is a sequencing decision, which is yours.
The packet is committed at `handoff/settlement-2026-09-02/`. Nothing has run
against it. If you rule against the split, it costs one commit to revert and
nothing else.

Four questions follow. The last one is the one I would most like you to look
at, because getting it wrong wastes work rather than merely misplacing it.

## Question 1 — may the wave be split at all?

Your tracker lists the pre-run settlement as one pass, and the reason it is
one pass is that it touches every file and cannot parallelize. My split does
not contradict that: one session still holds the plugin directory, and the
second half waits for the first. What changes is that two different sessions
do the halves.

I propose:

| task | where | why |
|---|---|---|
| six renames | delegated | mechanical, fully covered by a gate |
| registry to 42 rows, exclusion entry | delegated | mechanical, gate covers it |
| two ordered recorder hooks | delegated | mechanical, gate covers it |
| uniform outcome contract | held here | which failure paths are real is design |
| annotation-bridge unification | held here | your pins require equivalence probes and a red demo |

Measured scope of the delegated half: 222 file-touches, plus 27 generated
harness output directories that are regenerated rather than edited. Command:
`handoff/settlement-2026-09-02/list_sites.sh`.

## Question 2 — is that the right cut?

The cut I drew is "covered by an objective gate" against "needs judgment". I
can defend it but I did not derive it from a ruling. If you would cut it
elsewhere, say where.

## Question 3 — does the gate check what you meant?

`validate/v159_settlement_gate.R` binds four things: the six old names appear
nowhere, the six new names are defined and registered, the registry holds 42
rows with the mixed model excluded by an explicit entry, and the two ordered
recorder hooks exist. It reads the rename pairs from
`PROPOSAL_CANONICAL_NAMES_2026-09-01.md` rather than restating them, so it
cannot drift from what Ian accepted.

It reports 24 checks, 1 passed, 23 failed. If that binding set is narrower
than your intent, the delegated session will read green while leaving work
undone.

## Question 4 — the hooks may be wasted work

This is the ordering risk and it is the reason I am writing before anything
runs.

`RULING_REGISTRY_VERDICTS_2026-09-01.md` section 2 orders recorder hooks for
grouped regression and the Q-Q plot. The delegated session would add them by
hand, in the shape their siblings use.

`MEMO_RECORDER_NAME_BINDING_2026-09-02.md` asks you whether the recorder's
dispatch table should instead be GENERATED from the registry, because the
recorder currently identifies procedures by string literals that Praat never
checks. If you rule for generation, hand-written hooks are rewritten by the
generator and the hand work is discarded.

Three ways to sequence it, and I have not chosen:

1. Rule the recorder question first; the delegated session does renames and
   registry only, and hooks follow the ruling.
2. Let the hooks be added by hand now and accept that generation would
   supersede them.
3. Delegate renames and registry now, and hold the hooks here so they land
   with whatever you rule.

I lean towards the first, because the hooks are the smallest of the three
tasks and the ruling governs the file they live in.

## What is true regardless

The delegated session is told, in writing, that a case no ruling covers stops
work and comes back as an open question rather than being decided in place.
It is also told not to edit the gate or the accepted proposal, since the gate
is the check on its own work.
