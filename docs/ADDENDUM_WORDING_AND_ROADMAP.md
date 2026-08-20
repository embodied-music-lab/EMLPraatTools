# Addendum — two wording items, a terminology audit, and the roadmap register

Verification session → executing session, 20 Aug 2026, on Ian's authority.
Extends CONSOLIDATED_WORDING_PASS_2026-08-18 (items join the 6b work
order) and adds one small standing artifact.

## 1. Two wording items for 6b (ruled by Ian, 20 Aug)

a. Wizard A3 gate page: "How many repeated measurements per subject?"
   → "Under how many conditions was each subject measured?" — the k
   things are CONDITIONS (levels of the within-subject factor, SPSS's
   term): the same measurement under k circumstances. "Measurements"
   invites reading them as different variables; it confused the author,
   so it will confuse students. Option labels stay.
b. Observation-type page: "Yes — same people, repeated (paired)" →
   "Yes — same people, measured more than once (within-subject)".
   "Paired" is reserved for the k = 2 test whose proper name it is
   (paired t-test), where it stays.

Pin rule as standing: value lines + gloss presence, never gloss wording.

## 2. Terminology-uniformity audit (new 6b sub-item, small)

Audit every dialog, report line, and doc for the four terms —
CONDITION (level of a within-subject factor), TOKEN (replicate of the
same measurement within a cell), MEASUREMENT (the dependent variable
itself), WITHIN-SUBJECT / PAIRED (design property; "paired" only at
k = 2) — against R and SPSS usage. The plugin's wide RM format already
matches SPSS (one column per within-subject factor level); the audit
makes the WORDS match everywhere the format already does. Deliverable:
a short findings list into the wording pass, fixed in the same commit
family. Note the line-chart tree's "different measurements" language is
CORRECT and out of scope — it names genuinely different variables (a
plotting question), which is exactly the distinction the audit protects.

## 3. ROADMAP.md — the phase register moves into the repo

Ian could not find the ICC / power-suite plan because it lives only in
handoff documents. Create ROADMAP.md at the REPO ROOT (outside the
shipped plugin folder; the shipped-files rule is untouched), carrying
per phase: the contract, the named oracles, and the gate. Seed it from
FEATURE_ROADMAP_TO_LMM_2026-08-16 — in particular Phase 1 as one unit:
within-subject aggregation pathway + ICC(2,1)/(2,k) + Spearman-Brown
reliability of the k-token mean + effective-n disclosure at the moment
of aggregation (aggregate/tapply + psych-class oracles), with the
guided fork "balanced → aggregate; unbalanced/missing → mixed model";
and the classical power suite explicitly NOT gated on LMM (pwr /
G*Power / MBESS benchmarks; only simulation-based mixed power waits).
Maintained like the standing list; the findings-scoreboard principle
applied to features: one authoritative register, visible in the repo.

DONE WHEN: the two wording items pass the 6b greps; the terminology
audit's findings are filed and fixed; ROADMAP.md exists at root with
the phase contracts and is referenced from the standing list.

— verification session
