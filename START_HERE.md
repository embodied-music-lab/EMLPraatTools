# START HERE — picking up the EML Praat Tools GUI drive

Last updated: 5 August 2026.

This file is for whoever resumes the audit in a fresh session. Read it before
anything else, then `README.md` for layout and `harness/GUI_HARNESS_RECIPE.md`
for the rig.

---

## The standing task, in the author's words

> "install the plugin locally and drive every single path. Start with the menu
> driven option. Look for accuracy, clarity of info window output, and graphing
> paths that result"

Judge in that order: **accuracy** first (is the reported number the right
number, from the right test — verified against Python/scipy, never by
inspection), then **clarity of Info-window output**, then **the graphing paths
that result**.

## Standing constraints — do not relax these

- **`pkill -9 -x praat`. Never `pkill -f praat`** — the `-f` form matches and
  kills the driving shell.
- Delete only `drive/prefs/pid` and `drive/prefs/message` when clearing a stale
  lock. **Do NOT delete the whole pref dir — the installed plugin lives in it.**
- **`Linear mixed model` is out of scope by author ruling.** Menu y=701, and
  the Table action button at y=579. Do not audit it, do not report findings
  against it.
- The author's questions are questions. **Answer in text before reaching for
  tools.**
- Any GitHub PAT is used transiently only — inline in a push URL or via a
  credential helper. It is **never** written into a tracked file, a committed
  `.git/config`, the README, or any artefact placed in the repo. Same rule for
  the SSH key: sandbox-only, never committed.

## What does NOT persist between sessions

Everything outside this repository. Specifically the sandbox itself, the Praat
6.6.30 install, the Xvfb/matchbox/xdotool rig, and the plugin installed under
`drive/prefs/`. Rebuilding costs roughly ten minutes of scripted setup —
`harness/GUI_HARNESS_RECIPE.md` §1–2 is the procedure, and `harness/gui.sh` is
the helper library to re-source.

Nothing that is not committed here survives. Commit early.

---

## Next targets, in priority order

### 1. The three genuine D66 cases (highest value — an open ACCURACY finding)

D66 is the CSV-export failure caused by orchestrators that call the CSV
*init* without ever calling *add row*. On 5 August the prediction that *Compare
paired/repeated* was affected was **refuted by live drive** — it exports a fully
populated row and is cleared. The three orchestrators that remain suspect, and
the only routes that reach them:

| Orchestrator | init site | reached from |
|---|---|---|
| `emlRunPairwiseAnalysis` | 407 | `scripts/eml-pairwise.praat:102`, `scripts/eml-wizard.praat:630/637` |
| `emlRunRepeatedMeasuresAnalysis` | 1420 | `scripts/eml-wizard.praat:1012` **only** |
| `emlRunFriedmanAnalysis` | 1479 | `scripts/eml-wizard.praat:1022` **only** |

So:

- **a.** Drive *Pairwise comparisons* (menu y=727) and press its CSV button.
  This is the first untested D66 case and the cheapest to reach.
- **b.** Drive *Stats Wizard* (menu y=447) into its repeated-measures branch and
  take the CSV.
- **c.** Same wizard, Friedman branch, take the CSV.

A confirmed empty-body CSV on any of these promotes D66 from predicted to
demonstrated. A populated row on all three closes it.

### 2. Finish the interrupted Draw leg

A `Pause: Save Figure` dialog was open when the 5 August session was
interrupted. That instance is gone with the sandbox — re-drive from *Compare
paired/repeated* → Draw. The figure title was left **deliberately empty** to
test whether the plugin supplies a default title (Rule 28A). Inspect the
resulting spaghetti plot itself, which has not yet been looked at.

### 3. Differential probes on wrapper 11

- The `Test` optionmenu: pairwise Wilcoxon, and Tukey.
- `Adjustment` = **Holm**. Holm gives M-A `0.0390` where Bonferroni gives
  `0.0659` — a clean differential that proves the adjustment is actually
  applied rather than labelled.
- In the graphing dialog, `Test type = Nonparametric` is the only path where
  Adjustment is live.

### 4. Remaining in-scope menu wrappers

`EML Graphs` (753), `Batch voice analysis` (779), `Run Stats Demo` (830),
`EML Stats Quick Start` (856), `Stats Wizard` (447).

### 5. Lower priority

- Resolve the graph-type taxonomy candidate: Histogram sits under *Categorical*
  while Bar Chart and Spaghetti sit under *Continuous*.
- Spot-drive two of the nine Table action buttons (x≈1277, y 404–684; skip
  y=579).
- Drive the remaining `emlShowExplanations` branches. The flag defaults to 0 at
  `stats/eml-output.praat:63` and is set to 1 only at
  `graphs/eml-graphs-form.praat:794`, so these are reachable **only** by
  entering through `@emlGraphsWorkflow`.

---

## Known rig bugs to fix while you are in there

- `gui.sh` → `infotext`: called **with** a path argument it prints to stdout,
  exits 1, and writes no file. Use it with no argument and redirect:
  `infotext > out/file.txt`.
- `gui.sh` → `emlmenu`: still uses `windowraise`, which is insufficient under
  matchbox. Every other primitive uses `windowactivate --sync` then
  `windowfocus`. This is a latent flake.

## Known packaging obligation

Finding **P1**: 13 of 21 files in `plugin/scripts/` are mode `0600` in the built
tree, which makes the plugin unreadable for any account other than the
installer's. **Git records only the executable bit**, so this defect cannot be
represented in this repository and will never show in a `git diff`. It has to be
fixed in packaging — `chmod 0644` across the tree before zipping — and verified
on the built artefact. No fresh redistributable build has been cut since S9
(2 August).
