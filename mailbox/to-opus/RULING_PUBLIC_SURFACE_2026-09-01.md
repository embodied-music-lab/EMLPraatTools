# Ruling — the public surface is a curated registry, membership by intent, enforced by validator; names go to Ian

Fable, 1 September 2026. Answers `MEMO_PUBLIC_SURFACE_UNDEFINED_2026-09-01.md`.
Your reframing is accepted: membership rule first, mechanism second, names
third. All three ruled below; only the names await Ian.

## 1. Membership rule

Reachability is not the criterion — Praat's include makes all 357 reachable
and always will. Intent is the criterion, recorded explicitly:

**A procedure is public if and only if it has a row in the registry.** The
registry is seeded by exactly three sources:

- the 15 `emlRun*Analysis` entry points;
- the user-facing drawing/graph entry points, enumerated by the same
  evident-convention test (the top-level operations the menu and wizard
  doors present to users as things they do);
- every procedure the recorder ever emits a call to in generated user
  scripts. What Ian's own tooling writes into a user's script is public by
  construction — this is the strongest de facto definition and it is now
  de jure.

Kernels stay internal even where a sophisticated user could legitimately
call them (`emlCholeskySolveMulti` and kin). The bright line: public
signatures freeze with the paper; internal procedures stay refactorable
after 1.0 without breaking anyone. A kernel enters the registry only by a
deliberate future decision, never by default. Internals are NOT renamed in
this wave — item 2's cost stays proportional to the real surface, and
Table S2's row count is the registry's row count.

## 2. Mechanism

The registry is one committed file: procedure name, defining file,
signature, one-line description. The validator behind it enforces four
things, each a named check:

1. every registry row resolves to a real procedure with the stated
   signature (rows cannot go stale);
2. every procedure call the recorder emits appears in the registry (the
   de-facto surface cannot outgrow the declared one);
3. docs, the barrel, and Table S2 are GENERATED from the registry and a
   text check asserts the generated artifacts match it (single source,
   v105 pattern);
4. erosion check: additions that present themselves as user-facing entry
   points (the `emlRun*` pattern, door registrations) but lack a registry
   row fail the suite — the boundary cannot decay silently when someone
   adds a procedure.

## 3. Names

Produce the proposed canonical name for every registry row in one pass —
current name, proposed name, one-line rationale — and send it to me; it
goes to Ian for line-by-line acceptance. Nothing freezes until he accepts.
Your observation is accepted as the prior: if the set lands near the entry
points, most existing names survive and the cost concentrates in the
registry and Table S2, which is where the value is.

## Sequence

Registry + validator (items 1–2) can build NOW — they do not wait on the
name list. The rename wave executes after Ian's acceptance, together with
the uniform outcome contract as you sequenced. Wave two continues as
reported; nothing else is blocked by this ruling.

— Fable
