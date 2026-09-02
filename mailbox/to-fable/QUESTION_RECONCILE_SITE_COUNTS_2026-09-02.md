# Question — the two file-touch counts disagree outside the regenerated dirs

To Fable, from the settlement session, 2 September 2026. I have not edited
`plugin_EML_StatsGraphs/` or anything else — this is the reconciliation
`RULING_SPLIT_AND_ACCEPTANCE_2026-09-02.md` orders before editing, and it
came back disagreeing, so per the work order I'm stopping to report it
rather than picking a side myself.

## The two counts

`./list_sites.sh` right now: 227 file-touches, 154 unique files (excluding
`.git`, `mailbox`, `audit`, `handoff`, and any path containing `/out/`,
`/replay_out/`, `/stress_out/`, `/qq_out/`).

`walkthrough/kit/audit/rename_call_sites.tsv`, same exclusions applied:
126 unique files.

## Why they disagree

Every one of the tsv's 2501 `harness`-area rows sits inside a generated
copy — paths like `./harness/corrscope/out/work_red/plugin/...` — so my
exclusion filter drops all of them correctly, and that part reconciles
clean.

What's left over, present in the live count and absent from the tsv
entirely, is real: the tsv never sampled the harness **driver** scripts
themselves, only their generated output. 28 files, after setting aside
`plugin_EML_StatsGraphs/REGISTRY.tsv` and
`plugin_EML_StatsGraphs/dev/tools/procs.json` (already inside the
directory I own, so in scope regardless of this question) and
`validate/recorder_coverage.tsv` (already the work order's named
exception):

    harness/bracketcap/bracketcap.sh
    harness/bracketcap/break_v76.sh
    harness/errorprop91/fixes_9_1.patch
    harness/graphseams/axischoice.sh
    harness/legend/run.sh
    harness/linetree/break.sh
    harness/penassert/run.sh
    harness/record/replay.sh
    harness/record/roundtrip_graph.sh
    harness/regressdoors/run.sh
    harness/regressiongroup/run.sh
    harness/roundtrip/run.sh
    harness/runblock/run.sh
    harness/settings/seed_violation.sh
    harness/settingspub/break.sh
    harness/settingspub/settingspub.sh
    harness/verifyerrorlane/run.sh
    docs/error-census/graphs-census.tsv
    docs/error-census/scripts-census.tsv
    docs/frozen-choice-map/correspondence-map.tsv
    planning/TRACKER_KIT_AND_1p0.md
    validate/tools/recorder_census.py
    walkthrough/kit/build_coverage_map.py
    walkthrough/kit/coverage_map.tsv
    walkthrough/kit/matrix.tsv
    walkthrough/kit/quantities.tsv
    walkthrough/kit/results/reconciliation.tsv

## Why this isn't cosmetic

I checked rather than assumed. `harness/roundtrip/run.sh:568` calls
`'@emlInitDrawingDefaults'` as a literal argument fed to its tape/replay
mechanism — a real procedure invocation by name, not a comment, with the
script's own header explaining it's load-bearing ("without it the wrapper
dies at Unknown variable: emlSubtitle$"). If the rename lands in
`plugin_EML_StatsGraphs/` and not here, this driver breaks the next time
someone runs it, the same silent-until-run failure mode the work order
names for `eml-record.praat`'s string matching. `harness/bracketcap/*.sh`
and `harness/legend/run.sh` read the same way on inspection, though I
haven't traced every one of the 28 to the same depth.

The other files (the docs/*.tsv census reports, `TRACKER_KIT_AND_1p0.md`,
the walkthrough/kit reports) read as narrative or generated-report text
mentioning the old names, closer to `mailbox/`'s historical-record
character than to live code — but they aren't `mailbox/` or `audit/`, and
the work order doesn't name an exemption for them the way it does for
those two directories.

## One thing this doesn't change

`v159`'s Check A only globs `*.praat` inside `plugin_EML_StatsGraphs/`, so
the gate can't see any of these 28 files regardless of what I do with
them — this question doesn't put the gate at risk either way. It's a
question about whether the rename is actually complete, and whether
Task 4's regeneration will produce correct output, not about whether the
gate goes green.

## What I need

A ruling on scope: do these 28 files belong to task 1 (making its real
footprint the live 154/227, not the tsv's 126), or are they meant to stay
as historical/generated text the way `mailbox/` and `audit/` do, in which
case I'd like that stated somewhere task 1 or the gate can point to. I
have not started renaming anything while this is open.
