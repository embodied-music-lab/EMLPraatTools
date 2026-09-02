# Start here — the settlement session

You are running the mechanical part of the pre-run settlement wave for the
EML Stats & Graphs Praat plugin. Read this file, then `WORK_ORDER.md`, then
`VERIFY.md`. Do the work. Write your report into `out/`.

## What you own, and what you must not touch

You own `plugin_EML_StatsGraphs/` for the duration of this task. No other
session edits it while you work.

Do not edit any of these:

- `mailbox/` — the ruling record. Superseded files stay as written and are
  never edited, including when they mention a name you are retiring.
- `audit/` — a historical record, same rule.
- Any directory named `out/`, `replay_out/`, `stress_out/` or `qq_out/`
  under `harness/` — 27 of them contain retired names. Those are generated.
  Regenerating them is in scope; editing them by hand is not, because a
  hand-edited artifact hides the failure it was built to reveal.
- `walkthrough/kit/reference/` — the arbitrary-precision reference grid.

## Sync before you start

The local clone is behind the work. If you begin without syncing, you will
rename files that have since changed and produce conflicts that look like
your own errors.

If Ian has already pushed, pull:

```bash
cd ~/EMLPraatTools
git pull --ff-only origin main
git log --oneline -3
```

If he has not, fetch the bundle he placed beside the repository. Merge
`FETCH_HEAD` rather than a named remote ref: a bundle fetch always records
`FETCH_HEAD`, and on 2 September a merge against an assumed ref name silently
did nothing while the fetch itself had succeeded.

```bash
cd ~/EMLPraatTools
git fetch ~/EMLPraatTools/eml-settlement-handoff.bundle 'refs/heads/*:refs/remotes/bundle/*'
git merge --ff-only FETCH_HEAD
git log --oneline -3
```

Either way, the top commit should be the one that adds this directory,
`handoff: settlement session packet`.

If the merge is not a fast-forward, stop and report it. Do not force it.

## Prove where you started

Record the commit you began from, and put it at the top of your report:

```bash
git rev-parse HEAD
Rscript validate/v159_settlement_gate.R 2>&1 | tail -5
```

The gate should read 24 checks, 1 passed, 23 failed before you change
anything. If it reads anything else, the work has moved and you should say
so before proceeding.

## The standing rules that apply to you

- Nothing is hardcoded. A rule is stated once and a check asserts that the
  copies agree.
- Search before you write. This tree is large and most problems in it were
  solved once already. Grep before adding any procedure or helper.
- A claim you describe as verified carries its verification artifact: the
  exact command and its actual output. A number you did not produce by
  running something is not a measurement.
- Praat has no try/catch, `e` is a reserved name, procedure locals written
  `.x` are namespaced globals that persist between calls, object commands
  cannot be inlined into argument lists, and `include` is a parse-time paste.
- Do not push. Commit your work and report the commit hashes.

## When you finish

Write `out/REPORT.md`. Say what you changed, quote the gate's output before
and after, and name anything you could not complete. Then stop. Do not start
the outcome-contract work or the annotation-bridge work; both are excluded
and are explained in `WORK_ORDER.md`.
