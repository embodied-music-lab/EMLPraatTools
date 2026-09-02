# Builder brief — survey module lane

You are a fresh session building one self-contained lane of the EML
Stats & Graphs Praat plugin. Ian seeds you with two documents: this
brief and `SURVEY_MODULE_PLAN_2026-08-25.md`. The plan is the complete
specification — every design decision is pinned there; if you find one
that is not, stop and route the question to Ian rather than deciding.
Target: usable by Ian's group next week.

## Set up

1. Clone `github.com/embodied-music-lab/EMLPraatTools` and work at its
   head. Create a branch named `survey-module`.
2. Read `CLAUDE.md` at the repo root first — it carries the traps that
   fail silently and the command to clone the PraatGen knowledge base.
   Clone that too, and check it before claiming any Praat limitation.
3. The conformance suite in `validate/` is authoritative. Red means
   stop. Run it before your first commit to know your baseline.
4. Runtime: Praat 6.6.30 barren for oracle driving — praat.org no
   longer serves 6.6.30; use the `praat/praat` GitHub release tag.
   Base R (any recent version; base only, no packages in `validate/`).
   Dialog drives need the full Praat GUI under Xvfb per
   `harness/GUI_HARNESS_RECIPE.md`.

## Boundaries

- Touch only: `plugin_EML_StatsGraphs/scripts/eml-survey.praat` (new),
  additions to `plugin_EML_StatsGraphs/stats/eml-psychometrics.praat`,
  the menu registration in `setup.praat`, new checks in `validate/`,
  new fixtures under `evidence/csv/`, and new harness legs in a new
  `harness/survey/`. Nothing else — no cleanups, no fixes to problems
  you notice elsewhere; report those in your memo instead. Another
  session's inspection diffs your whole bundle, and an unlisted change
  is flagged, not merged.
- Do not modify the validated kernels (`@emlCronbachAlpha`,
  `@emlAlphaInfluence`). You are wiring them, not improving them.
- The plan's language section is not yet approved by Ian. Build Stages 1
  and 2 (schemas, validator, oracles, wiring, report plumbing) fully;
  build no dialog page and no user-facing sentence until Ian's approval
  arrives with the exact wording.
- Every error-producing call you write reads `.error$` before using any
  output — the repo's error-propagation census just found 63 sites that
  don't; add zero.
- If you fan work out to agents, name the model on every task and use
  the cheapest model that does the work well; mechanical wiring and
  check-running go to cheaper models, never the design.

## Order of work, with gates

Follow the plan's five-stage order. Sequence is by dependency, never by
clock — a stage is done when its gate condition holds, however long that
takes. Two bundle gates:

1. **Gate 1:** schemas, validator, and every oracle exist, and every
   check has been demonstrated red against a seeded defect before
   turning green. No wrapper code before this gate. Deliver bundle 1.
2. **Gate 2:** reversal transform, per-subscale routing, and report
   plumbing driven green against the oracles. Deliver bundle 2.

Bundles at the gates let verification run while you continue —
divergence surfaces at the next gate instead of at the end.

## Output

- Git bundles on the `survey-module` branch:
  `git bundle create eml-survey-<gate>.bundle main..survey-module`,
  handed to Ian, who carries them to the verification and executing
  sessions.
- A completion memo per bundle: files touched, check counts, the red
  demos by name, environment versions (`praat --version`, R
  `sessionInfo()`), refusal texts verbatim, and anything you noticed
  outside your lane (reported, not fixed).
- Evidence outside the worktree, per house rule; transcripts carry an
  environment line (pixel evidence is machine-bound).

## What you are not

You do not verify your own lane — the verification session does, against
your bundles, and its acceptance runs the plan's oracles independently.
You do not decide scope — the plan and Ian do. You do not commit to
`main` — the executing session folds your branch after verification.
Your commit messages carry no AI attribution beyond the repo's existing
framework language, and no defect history goes into shipped file
headers (pre-release documentation policy; the audit record keeps the
reasoning).
