# TODO — remote cleanup: 78 superseded artefact files

**Owner: Ian. Needs one `git push`, or 78 web-UI deletes. Not doable from the
sandbox.** Recorded 14 August 2026.

---

## What

`harness/savepaths/out/` on the remote carries **78 files that nothing reads**.
They are the saved outputs of two earlier runs of `harness/savepaths`, under
their original timestamped names. The current run's evidence is beside them
under stable role-based names (`<leg>.tidy.csv`, `<leg>.report.txt`, …), and
that is what `validate/v48_save_paths.R` reads.

Nothing is broken. The suite passes at 9877/0 and v48 at 170/0 with these
present, because v48 reads the file list out of each leg's
`<leg>.artefacts.tsv` manifest rather than off the directory. The problem is
that the folder shows **two or three timestamps per leg where there was one
press**, which is the stale-evidence failure `v49`/`v47` exist to catch — a
reader would reasonably conclude a save wrote its files under several names.

## Why it could not be done from here

Pushes to this repository go through GitHub's **web upload form**, one
directory at a time. That form can ADD a file at a path and can never remove
one. There is no bulk delete: measured 14 Aug 2026, GitHub's per-file delete
page is one commit per file — navigate, open dialog, confirm — and pending
deletions do **not** accumulate across navigations (tested with a second file
while the first was pending; the editor showed only the one). 78 files is
roughly 310 browser actions.

## The fix, in order of preference

**1. One push.** The local branch already has the deletion commit prepared:

```
git rm $(cat audit/TODO_REMOTE_CLEANUP.filelist)
git commit -m "savepaths/out: drop the superseded timestamped artefact"
git push
```

**2. Or just re-run the harness and push.** `harness/savepaths/run.sh` wipes
`out/` on a full run, so a fresh run leaves ONLY the stable names:

```
bash harness/savepaths/run.sh      # ~12 min, 11 legs
Rscript validate/v48_save_paths.R  # expect 170/170
git add -A && git commit && git push
```

**3. Or 78 web-UI deletes**, at
`https://github.com/embodied-music-lab/EMLPraatTools/delete/main/<path>`.
The full path list is in `audit/TODO_REMOTE_CLEANUP.filelist` beside this file.

## Why it will not happen again

`harness/savepaths/run.sh` now copies each saved file under its ROLE rather
than its timestamp — `<leg>.tidy.csv`, `<leg>.posthoc_tidy.csv`,
`<leg>.report.txt`, `<leg>.results.csv` for a legacy export — so a re-run
OVERWRITES its evidence instead of orphaning a set under new names. The real
stamped filename is still recorded in `<leg>.artefacts.tsv`, so the
one-stamp-per-press check is untouched. Commit `0c5f8a0`.

These 78 are the last of the old naming.

## The count, by leg

- `eml-check-normality` — 2 files
- `eml-compare-groups` — 8 files
- `eml-compare-k-groups` — 12 files
- `eml-compare-kw` — 8 files
- `eml-compare-paired` — 8 files
- `eml-compare-twoway` — 10 files
- `eml-correlate` — 6 files
- `eml-pairwise` — 6 files
- `eml-regress` — 8 files
- `eml-wizard` — 8 files
- `eml-wizard-describe` — 2 files

Total: 78.
