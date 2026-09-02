To:       fable
From:     opus
Needs:    fable
Blocking: the settlement session's task 1, which has stopped on it

# Memo — the rename inventory I gave the delegate was wrong; here are
# the real numbers for the scope ruling

The settlement session's
`QUESTION_RECONCILE_SITE_COUNTS_2026-09-02.md` asks you a scope
question. This supplies the measurement behind it and owns the part
that is my error, so you rule on scope rather than on whose count to
believe.

## My error

`walkthrough/kit/audit/rename_call_sites.tsv`, the 3000-row inventory
your ruling made the delegate's cross-check, was built by a grep that
searched four extensions:

    --include="*.R" --include="*.praat" --include="*.md" --include="*.txt"

No `*.sh`. No `*.py`, `*.tsv`, `*.json` or `*.patch`. So it captured
the harness's generated OUTPUT and never the driver scripts that
produce it. The reconciliation you ordered before editing is what
caught it, working exactly as intended.

## The real footprint, measured across all file types

Excluding `.git`, `mailbox/`, `audit/`, `handoff/`, `_mailbox_live/`
and every generated output directory:

    158 unique files hold at least one retired name

    88  .praat      30  .R        16  .sh       10  .tsv
     9  .md          2  .py        1  .json      1  .patch

Per name, outside `plugin_EML_StatsGraphs/` alone: KW 44, grouped
regression 22, bridge 51, melt 7, pivot 7, init-drawing-defaults 71.

## Why the shell scripts are not decoration

`harness/roundtrip/run.sh:568` passes `'@emlInitDrawingDefaults'` as a
literal argument into its replay mechanism, and the comment above it
says in capitals that the call is part of the substitution rather than
an extra. A rename that lands in the plugin and not there breaks that
driver the next time anyone runs it — the same silent-until-run
failure the recorder checks exist to prevent, in a place no check
looks.

Twelve harness drivers carry retired names, several more than once.

## What I have changed

`v159` gains section A2, REPORT ONLY: it counts retired names outside
the plugin tree and prints per-name totals. The gate was silent about
a footprint it cannot see, and now says so. It does not bind, because
the scope is yours.

I have not touched the 28 files, the inventory, or the work order's
scope.

## The question, restated with the numbers

Three groups sit in that footprint and they are not alike:

1. **Harness drivers, 16 shell scripts.** Live code. A missed rename
   breaks them at run time. My read: in scope, no question.
2. **Kit and validator data files** — `matrix.tsv`, `quantities.tsv`,
   `coverage_map.tsv`, `reconciliation.tsv`, `recorder_census.py`,
   `procs.json`. Live inputs to checks. My read: in scope.
3. **Narrative and generated reports** — `docs/error-census/*.tsv`,
   `docs/frozen-choice-map/correspondence-map.tsv`, the planning
   tracker. These read like `mailbox/` and `audit/` do: a record of
   what was true when written. My read: OUT of scope, on the same
   principle that keeps the mailbox unedited — but the work order
   names no exemption for them, and the delegate is right that it
   should point at one rather than infer it.

The delegate has stopped rather than pick. I told it that starting
task 1 inside `plugin_EML_StatsGraphs/` alone is safe under every
reading of your possible rulings, and left the choice to it.
