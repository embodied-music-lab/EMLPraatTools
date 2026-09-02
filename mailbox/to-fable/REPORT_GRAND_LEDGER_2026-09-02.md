# Report: grand_ledger built (tracker item A.7)

From: Opus subagent, 2 September 2026.
Files: `walkthrough/kit/grand_ledger.R` (389 lines), `walkthrough/kit/grand_ledger.tsv` (16 lines, generated).

## What I built

`walkthrough/kit/grand_ledger.R` reads the kit's own declaration and output
files and writes `walkthrough/kit/grand_ledger.tsv`, one row per reported
quantity, with columns `quantity_name`, `value`, `unit`, `derived_from`,
`as_of`, `status`, and `note`. No number in it is typed in by hand — every
row's `derived_from` names the file and the exact parse rule that produced
its value, and most of those parses reuse `compare.R`'s own read idioms
(`read.delim` with `comment.char = "#"` over `matrix.tsv`; the hand-stripped
`#`-preamble over `quantities.tsv`, for the same reason `compare.R` does it
by hand — Praat matrix names in the source column end `##`, which
`comment.char` would truncate mid-line).

It treats two kinds of input differently, on purpose:

- **Hard-required declaration files** — `matrix.tsv`, `quantities.tsv`, the
  plugin's `REGISTRY.tsv`, and the `validate/` suite's script files. A
  working checkout of the kit always has these, run or no run. If one is
  missing, the script writes **no ledger at all** and exits 1, naming the
  exact path. I tested this: with `matrix.tsv` moved aside, the script
  printed `MISSING walkthrough/kit/matrix.tsv (looked at
  /home/claude/repo/walkthrough/kit/matrix.tsv)` and exited 1, and
  `grand_ledger.tsv` from the prior run was left untouched (not overwritten
  with a partial file). I restored `matrix.tsv` afterward and diffed it
  against a backup to confirm it came back byte-identical.

- **Run-dependent output files** — the two runner tables
  (`audit/praat_results.tsv`, `audit/r_results.tsv`), `compare.R`'s own
  `audit/VERDICT.txt`, and a captured pass/fail summary of
  `validate/run_all.R`. These are the authoritative run's own outputs
  (tracker item A.8: "run NOT RUN"). Their absence is the *expected*
  pre-run state, not a broken checkout, so it does not abort the script.
  Each quantity that depends on one of these gets a row with `value` = `NA`
  (never a silent `0`), `status` = `AWAITING_RUN`, and a `note` that names
  exactly which file is missing or which file is older than which.

Freshness for the second group is checked by file modification time, the
same signal `compare.R` already uses internally for its own stale-cell_id
check: a runner table older than the declaration it should have run
against, or a `compare.R` output older than either runner table, counts as
stale even though the file exists.

## What I measured, and the commands

**Declaration-level counts (recomputed live, available right now):**

```
$ Rscript -e '
mx <- read.delim("matrix.tsv", sep="\t", comment.char="#", colClasses="character", quote="")
cat("nrow(mx) =", nrow(mx), "\n")
cat("unique procedures =", length(unique(mx$procedure)), "\n")
qtLines <- readLines("quantities.tsv", warn=FALSE)
QT <- read.delim(text = qtLines[!startsWith(qtLines, "#")], sep="\t", colClasses="character", quote="", comment.char="")
cat("nrow(QT) =", nrow(QT), "\n")'
nrow(mx) = 669
unique procedures = 17
nrow(QT) = 234
```

- `n_public_procedures = 43` — `plugin_EML_StatsGraphs/REGISTRY.tsv` data
  rows (read-only per this job's rules; I did not touch the file).
- `n_numerically_validated_procedures = 17` — distinct `procedure` values
  in `matrix.tsv`.
- `n_validation_cells = 669` — `matrix.tsv` data row count, broken down as
  `n_validation_cells_options = 626`, `_sweep = 32`, `_nist = 11`.
- `n_contract_clauses = 234` — `quantities.tsv` data row count.
- `n_validators_total = 151` — file count of `validate/v*.R` (confirmed by
  `ls validate/v*.R | wc -l` → `151`). `validate/README.md`'s own prose
  calls each such script a "validator."

**A concrete, dated staleness finding**, from the freshness check itself:

```
$ Rscript walkthrough/kit/grand_ledger.R
...
grand_ledger.R: run-dependent inputs are NOT fresh -- reasons:
  - audit/praat_results.tsv (mtime 2026-08-31 11:23:44 +0000) is OLDER than
    matrix.tsv (mtime 2026-09-01 16:29:52 +0000) -- this runner has not
    been re-driven since the declaration changed
  - matrix.tsv (mtime 2026-09-01 16:29:52 +0000) is NEWER than
    audit/VERDICT.txt (mtime 2026-08-31 13:54:36 +0000) -- compare.R has
    not been re-run since
  - audit/r_results.tsv (mtime 2026-09-01 22:57:29 +0000) is NEWER than
    audit/VERDICT.txt (mtime 2026-08-31 13:54:36 +0000) -- compare.R has
    not been re-run since
...
grand_ledger.R: 8 row(s) MEASURED, 7 row(s) AWAITING_RUN.
grand_ledger.R: ledger written, but INCOMPLETE ...  Exiting 2.
```

This is not a hypothetical: `matrix.tsv` gained two rows since the last
comparison run (`nrow(mx)` is 669 now; `audit/VERDICT.txt` still says
"cells declared in matrix.tsv : 667"), and `audit/r_results.tsv` was
regenerated on 1 September — after `audit/praat_results.tsv` (31 August)
and after `results/reconciliation.tsv`/`audit/VERDICT.txt` (also 31
August). The three files that `compare.R` needs together — the two
runner tables and its own verdict — are currently from three different
generations of the kit, not one coherent run. Citing `audit/VERDICT.txt`'s
10841/10792 numbers right now would be citing a comparison of a Praat
table that predates the current `matrix.tsv` against an R table built
after it, joined by a verdict file older than both.

**I confirmed the parser itself is correct** by copying the kit to an
isolated scratch directory, touching the run-output files to be internally
consistent and newer than the declarations (simulating a fresh post-run
state), and re-running the unmodified script there:

```
grand_ledger.R: run-dependent inputs ARE fresh relative to the current declarations.
...
n_comparisons                     10841  MEASURED
n_comparisons_agree               10792  MEASURED
n_comparisons_contract_one_sided   1725  MEASURED
n_comparisons_declared              316  MEASURED
n_comparisons_unexplained            32  MEASURED
kit_verdict                   NOT GREEN  MEASURED
```

These match `audit/VERDICT.txt`'s printed numbers exactly, confirming the
parse is right and that the script will switch these rows from
`AWAITING_RUN` to `MEASURED` on its own, unedited, once the authoritative
run leaves fresh, mutually consistent files behind. That test ran in
`/tmp`, not against the real kit files, and I deleted the scratch copy
afterward — nothing under `walkthrough/kit/` or `plugin_EML_StatsGraphs/`
was touched by it.

## What it currently cannot emit, and why

- **`n_comparisons`, `n_comparisons_agree`, `n_comparisons_contract_one_sided`,
  `n_comparisons_declared`, `n_comparisons_unexplained`, `kit_verdict`** —
  `status = AWAITING_RUN`. The backing file, `audit/VERDICT.txt`, exists
  but is stale relative to both `matrix.tsv` and `audit/r_results.tsv` (see
  above). Producing these requires re-driving both runners against the
  current `matrix.tsv` and re-running `compare.R` — which is exactly the
  authoritative run tracker item A.8 describes, not something this ledger
  should substitute for by reading a number that no longer matches the
  declaration it is supposed to summarize.

- **`n_validators_passing`** — `status = AWAITING_RUN`, unconditionally,
  regardless of the freshness check above. No captured pass/fail summary
  of `Rscript validate/run_all.R` exists anywhere in the repository. I
  looked for one specifically (`find` for manifest/result/log-shaped
  files, and a targeted search for anything from a full `run_all.R`
  execution) and found exactly one candidate,
  `harness/suiteguard/out/break_control.run_all.log` — a fixture for
  testing the suiteguard harness itself, dated 20 August 2026, covering
  91 scripts run from a `/tmp` copy. `validate/` currently holds 151
  scripts, so that log is 60 scripts short of the current suite and I did
  not use it. `grand_ledger.R` looks for `validate/RUN_ALL_SUMMARY.tsv`
  (a path I chose as the convention, documented in the script's comments)
  and reports the row as awaiting a run when that file is absent, which it
  is. **`validate/run_all.R` does not currently write such a file at
  all** — that's a gap someone needs to close before this row can ever go
  green, and it's outside my mandate to edit anything, including
  `validate/`, so I'm naming it here rather than building it.

  I did not attempt to run the full 151-script `validate/` suite myself:
  several validators drive an actual Praat process, the suite has no
  existing runtime measurement I could find to budget against, and running
  it was not part of this job's file list. That is a real gap, not a
  worked-around one — see the placeholder list below.

## Paper counts that are still placeholders because nothing produces them yet

These are exactly the quantities the tracker (`mailbox/to-opus/
TRACKER_KIT_AND_1p0.md`, sections A and C) says the paper's final counts
must come from `grand_ledger` "at the authoritative run and nowhere else,"
and which this pre-run ledger marks `AWAITING_RUN`:

1. Number of quantity comparisons made (last stale figure: 10841).
2. Number of comparisons that agree (last stale figure: 10792).
3. Number of comparisons resolved by the CONTRACT bucket (last stale
   figure: 1725) and by the DECLARED bucket (last stale figure: 316).
4. Number of unexplained comparisons (last stale figure: 32 — tracker item
   A.4, the Class A far-tail cancellation sweep, bears on this bucket.
   CORRECTED 2 Sept: this line called A.4 "still UNMEASURED"; A.4 is DONE
   and was folded to the tracker on 2 September, reported in
   MEMO_STATUS_A4_2026-09-01.md).
5. The kit's overall verdict line, GREEN vs. NOT GREEN.
6. Number of `validate/` validators that pass, out of 151 total — no
   captured run of the suite exists at all, stale or otherwise.

None of the "last stale figures" above appear in `grand_ledger.tsv` — I'm
naming them here only so you can see what is currently NOT being carried
forward as if it were current. The ledger's own rows for these six
quantities carry `NA`, `AWAITING_RUN`, and a note stating exactly what
would need to happen first.

Everything else the tracker lists as prerequisite to the authoritative run
— the quarantined port (A.2), the invTukeyQ replacement (A.3), the
outcome-contract and renaming work under A.5, the recorder-coverage
census, item A.6's re-pointing check — is unaffected by this ledger and
still stands as the tracker describes it. Building `grand_ledger` doesn't
close any of those; it just guarantees that once they're closed and A.8's
run happens, there is exactly one script that turns the result into the
paper's numbers, and it will refuse to print a number it can't back with a
file.

## Files

- `walkthrough/kit/grand_ledger.R` — 389 lines.
- `walkthrough/kit/grand_ledger.tsv` — 16 lines (1 header + 15 quantity
  rows), generated by the script above; regenerate with `Rscript
  walkthrough/kit/grand_ledger.R` from `walkthrough/kit/`. Current exit
  status: **2** (ledger written, incomplete — 8 rows MEASURED, 7 rows
  AWAITING_RUN). Exit 1 means a hard-required input is missing and no
  ledger was written; exit 0 will mean every at-minimum quantity is
  MEASURED and fresh — expected only after the authoritative run.

Nothing under `plugin_EML_StatsGraphs/` was read for anything other than
`REGISTRY.tsv`, and nothing under it was edited.
