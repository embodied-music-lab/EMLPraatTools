# Work order 3.10 — exact-method Spearman p

Fable, 27 August 2026. **Fully pinned; delegate as written. A case this order
does not cover comes back to Fable through Ian — it is not decided in place.**

## Why

The plugin computes only the asymptotic Spearman p — rho to t to the t
distribution. **The bare run measured the cost.** At rho = −0.979, n = 25, the
asymptotic p is 1.9e-17 where R's default method gives 6.3e-7, and one residue
cell shows the two methods straddling a plausible alpha: 0.0035 against
0.0042.

The two sides' asymptotic values already agree. **The plugin is headlining the
weaker of two answers.** House convention is exact where feasible, and the
rank tests already follow it.

## Kernel

New procedure **`@emlSpearmanExactP`** in `stats/eml-inferential.praat`: a port
of the algorithm R itself uses — **AS 89 (Best & Roberts 1975; R's `prho` C
routine)** — including its internal branching, so the plugin's p EQUALS R's
default p rather than approximating it.

**Port the routine, do not paraphrase it. Do not modify the existing rho
computation.**

## Branch law, copied from R's own

- **Ties present** → the existing t-approximation, disclosed.
- **No ties** → AS 89, disclosed.

The one-tailed variants — the scripting-only Alt family — select the tail
INSIDE the same method. No separate code path.

## One computation site

Every door that produces a Spearman p routes through this one kernel: the
correlation orchestrator, the per-group correlation, and the scatter's
draw-time annotation. **No second copy anywhere; the door-agreement machinery
verifies it.**

## Report

One p per test, **method named on its line** — "exact method (AS 89)" or
"t approximation (ties present)" — the same pattern the Mann-Whitney p already
uses. **The asymptotic value stops being the headline and is not printed as a
second line.**

Both sentences go to the language batch for Ian's en-bloc approval. Plumbing
and checks build now; the strings print on approval.

## Oracle and checks

- **Kit:** compare to R's default p, which the runner already emits raw.
- **New validate check:** a grid of n from 5 to 50, rho spanning −1 to +1
  INCLUDING BOTH BOUNDARY CELLS (rho = ±1), with and without ties, against
  `cor.test`.
- **Red demonstrations:** an asymptotic p printed on an exact-eligible cell; a
  ties case that fails to fall back to the t-approximation; the rho = 1
  boundary cell compared against the wrong method.
- **Kit scoping per the standing rule:** this item drives its own rows plus
  canaries. The full kit runs at the gate.

## Consequences

- Affected transcripts and baselines re-drive in the standing end-of-round
  batch, **not per commit**.
- **The method is data-determined**, like the Mann-Whitney branch. It is not a
  user setting, so the stored-result identity list is untouched.
- **Boundary task, report only:** confirm the plugin offers no Kendall
  correlation. If one exists it gets its own item; nothing about it rides on
  this one.

## Delegation tiers

- AS 89 port → strongest agent.
- Wiring the call sites and the report line → cheap model.
- Grid driving and re-baselines → cheapest.
- **Model named in every task label**, per the standing rule.
