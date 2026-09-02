# Error-propagation triage — a decision table for Ian

Opus — 2 September 2026. Builds on `REPORT_ERROR_PROPAGATION_2026-09-01.md`
(the census agent, 1 Sept — CORRECTED 2 Sept: this line previously credited
that report to Fable, which is wrong; Fable rules, she does not author our
census reports, and provenance must not drift even in courtesy) and answers
the same tracker section D lane. Every number
below is the direct output of a command run against current HEAD
`cd7c5fa` — `plugin_EML_StatsGraphs/` itself is unchanged since commit
`9450ba1`, which is the tree `validate/v134_error_read_lint.R` was run
against (`git diff --stat 9450ba1..HEAD -- plugin_EML_StatsGraphs/`
prints nothing). No plugin file was edited to produce this report.

## What this report is

The 1 September census measured and classified. This one turns that
classification into a decision table: `walkthrough/kit/audit/error_site_triage.tsv`,
one row per violating call site, each with a `FIX` or `SAFE` verdict and
the specific reason. Where the 1 September report used a five-way
verdict (SAFE / UNSAFE / untraced / out-of-scope / mechanically-OK), this
table collapses to the two values Ian actually has to rule on, and every
`SAFE` row states the mechanism that makes a bad value provably unable to
reach output there — never "looks fine."

## The linter's real output today

```
$ cd validate && Rscript v134_error_read_lint.R
v134: population 1 -- 111 procedures error-producing (of 688 procedures indexed).
v134: population 2 -- 355 call sites to a producer; 296 of those go on to use a
v134: numeric output of that call, and are the ones this check audits.
v134:   NO-OUTPUT-USED     59
v134:   OK                 161
v134:   UNCHECKED          112
v134:   USED-BEFORE-CHECK  23

v134: 121 site(s) redden the lint today (unadjudicated, of 296 audited call sites; 0 pinned exempt).
...
FAIL  v134    every violating call site is either fixed or in the adjudicated exempt set (121 unadjudicated of 135 violating)
------------------------------------------------------------------------------
12 checks, 11 passed, 1 FAILED
```

Full transcript: `/tmp/claude-0/-home-claude/93f3de1f-e6c9-5f61-b1bd-143273ac0781/scratchpad/v134_output.txt`
(this session's scratchpad; ask if you need the file moved somewhere durable).

135 raw violating call sites, 121 unique `(file, procedure, callee, call
text)` keys (v134's own dedup — several sites share a key when two nearly
identical calls a few lines apart carry the same argument text).
`EXEMPT_SITES` in the shipped script is still empty. These counts are
identical to the 1 September census's own numbers except for population 1
(111 vs 110 procedures, 688 vs 684 indexed) — one commit landed between
the two runs (`8745d13`, "reference grid: fix float64 precision cap") that
added a new error-producing procedure without changing which of the 135
call sites violate. The 135/121/gate-red figures did not move.

## The triage table

`walkthrough/kit/audit/error_site_triage.tsv` — 135 data rows (136 with
header), one per violating call site:

```
$ wc -l walkthrough/kit/audit/error_site_triage.tsv
136 walkthrough/kit/audit/error_site_triage.tsv
$ tail -n +2 walkthrough/kit/audit/error_site_triage.tsv | cut -f5 | sort | uniq -c
     82 FIX
     53 SAFE
$ tail -n +2 walkthrough/kit/audit/error_site_triage.tsv | cut -f4 | sort | uniq -c
    112 unchecked
     23 used-before-check
```

Columns: `file`, `line`, `procedure_called` (the producer, i.e. v134's
`callee`), `violation_kind` (`unchecked` / `used-before-check`),
`proposed_disposition` (`FIX` / `SAFE`), `reason`. Every `file` value is
the plugin-relative path — `stats/eml-lmm.praat` is spelled with its
directory because `eml-lmm.praat` is a duplicate basename (a second,
much smaller file of the same name exists under `scripts/`; all 19
violating LMM sites are in the `stats/` one, confirmed by line count and
by reading the cited lines).

**82 sites are proposed FIX. 53 are proposed SAFE**, each with the actual
mechanism that blocks a bad value, not a description of what the code is
supposed to do. Every site I was not certain about is FIX — per this
task's own instruction, a needless fix costs little and a missed one
costs a wrong number in a paper. This is why FIX (82) is larger than the
1 September census's UNSAFE bucket (76) alone: it also absorbs the
9-site untraced group's non-studentized-range members (6 of 9 — see
below) and the low-severity/demo-script sites that were real defects
under a different name.

## The reasoning pattern behind the 53 SAFE sites

Every SAFE verdict falls into one of five mechanical shapes, verified by
reading the cited source lines at current HEAD (not inherited without
re-checking):

1. **A cheap proxy that moves in lockstep with `.error$`.** `.degenerate`
   in `emlRMAnovaTest` (1 site) and `.drew` in `emlDrawQQPlot` (2 sites)
   are set together with `.error$` on every branch — gating on the proxy
   is gating on `.error$` under another name.
2. **A field that is provably zero, not stale, on the failure path.**
   `emlCountGroups.nBlankRows` (5 sites) is initialized to 0 and only
   incremented inside the success-path row loop — it cannot carry a
   wrong nonzero value out of a failure.
3. **A failure mode structurally unreachable at that call.** The
   p-adjustment trio (15 sites: `emlBonferroni`/`emlHolm`/
   `emlBenjaminiHochberg`) can only fail on an empty input vector, which
   never happens at these 15 calls because the caller has already built
   at least one pairwise entry by the time it calls in; the other
   failure mode (all-undefined input) already yields the same
   all-undefined output a manual check would produce.
   `emlAuditColumn` (2 sites) and the studentized-range root-finder
   (3 sites) are the same shape one level deeper: an earlier line in the
   *same* procedure has already ruled out the one condition the callee
   can fail on.
4. **Pure pass-through wrappers.** `eml_fpCompose`'s three callers
   (3 sites) copy every field, `.error$` included, into their own
   identically named fields; nothing at the flagged line computes or
   displays a value, it only relays.
5. **A check performed elsewhere in the same output chain.** Three of
   four Shapiro-Wilk sites gate the actual printed W/p value two lines
   after the flagged read (`stats/eml-analysis.praat:3997`) and pass
   `.error$` on into a second procedure's own nested gate — a
   text-order scanner can't see a check one hop away or one procedure
   down; a direct read does.
6. **The call site is unreachable from any door in the shipped 1.0
   surface.** All 19 LMM-module sites: the wizard's only entry point,
   `label D_LMM_FORMULA` in `scripts/eml-wizard.praat`, has no live
   `goto` reaching it any more (the only remaining `goto
   D_LMM_FORMULA` is the block's own error-dialog Back-button loop; the
   real entry is commented out at line 2666; the file's own comments say
   outright the label "has no user-reachable entry"), and no caller
   outside `stats/eml-lmm.praat` reaches these procedures by any other
   path. A bad value here cannot reach a user, because the code never
   runs. This matches Ian's ruling on `emlRunLMMAnalysis`
   (`mailbox/to-opus/RULING_REGISTRY_VERDICTS_2026-09-01.md` §1: "menu
   and wizard doors withdrawn").

None of the six is "the code looks careful" — each is a specific,
re-checkable fact about a specific line.

### Two corrections to the 1 September census, found while re-verifying it

- **`stats/eml-analysis.praat:4199` (`emlAuditColumn`)**: the 1 September
  report attributed the site's safety to the `@eml_openColumn` call
  immediately above it. Reading `eml_openColumn`
  (`stats/eml-extract.praat:1069-1085`) shows it does not check column
  existence at all — it only classifies whether a column is numerically
  "clean" for a fast-path read, and has no `.error$` output. The actual
  guard is an explicit `Get column index:` / `.ci = 0` check a few lines
  earlier in the *same enclosing procedure*
  (`stats/eml-analysis.praat:4166-4170`, inside
  `emlExtractConditionMatrix`). The SAFE verdict is unchanged; the
  mechanism cited for it was wrong.
- **Studentized-range root-finder (3 sites)**: the 1 September report
  correctly flagged this file as under concurrent edit and asked for a
  re-run before relying on it. On this re-run the three call sites moved
  from lines 827/834/850 to 1020/1028/1067 (same file, same shape,
  content confirmed unchanged — the file's own diff against `9450ba1` is
  empty). More importantly, `emlInvStudentizedRangeQ`'s own top-of-body
  guard (`stats/eml-studentized-range.praat:942-958`) rejects every
  condition `emlStudentizedRangeQ` can fail on (`df<2`, `k<2`,
  `nranges<1`) before the root-finder loop runs, and `.k`/`.df`/
  `.nranges` are read-only parameters never reassigned in the body
  (grep-confirmed: zero reassignments). That is a full proof, not the
  "mitigating, not full proof" the 1 September report gave it — moved
  from *untraced* to *SAFE*.

The LMM cluster is likewise upgraded from the 1 September report's
separate "out of scope" bucket into SAFE, on the reasoning above — this
task's table has only two dispositions, and unreachable code is exactly
the FIX/SAFE question's SAFE case: it cannot propagate a bad value
because it cannot run at all in the shipped surface.

### The 6 sites still marked FIX for "not sure," not "confirmed unsafe"

Three of the 1 September census's 9 untraced sites (two-way ANOVA
assumption checks, 2 sites; wizard's `emlExtractColumn` in the normality
page, 3 sites; `emlExtractGroupVectors`, 1 site) still could not be
closed by reading in the time this pass had — each needs either a trace
into a caller this task did not follow, or a runtime click-through. Per
the instruction to mark FIX rather than guess, they're FIX in the table,
with the specific open question stated in each row's reason so the next
pass does not have to re-derive it.

## Reconciling 63 (25 Aug) vs. 121/135 (this table)

The tracker's line reads "63 sites fixed or adjudicated-safe." That
number comes from `docs/ERROR_CENSUS_2026-08-25.md` +
`docs/error-census/*.tsv`, measured against commit `3e34b1a` (24 Aug):
`19 SWALLOWED-SILENT + 44 UNCHECKED = 63` — the verdicts where the real
error text never reaches the user at all. It is not the number this
table, or the linter, produces today, and it never will be again,
for two independent reasons:

1. **Different code.** 29+ commits have touched `plugin_EML_StatsGraphs/`
   between `3e34b1a` and today's `9450ba1` (six-rename wave, two-way
   kernel rewrite, fingerprint/result-store work, the LMM module
   landing, the studentized-range port). File:line references from
   25 August do not resolve to the same code any more; this table does
   not attempt a line-level reconciliation against the old 63, because
   there is no longer a stable line to reconcile to.
2. **Different rule, on purpose.** The 25 August census was a 249-row
   human read across every module (182 producers, 247 call sites,
   sampled and judged by a person). `v134` derives its own two
   populations mechanically from the tree, every run, on the specific
   rule that a check on any field OTHER than `.error$` does not count as
   a check — the exact "checking by proxy" pattern the 25 August census
   named as its headline finding. Measured today: 111 producers (vs. 182
   by human judgment) and 296 audited call sites, of which 135 violate
   (121 unique keys). The gap between 111 and 182 is a stricter
   definition finding fewer producers, not a smaller problem — the
   script's own header calls this out and gates only on a floor (>=50),
   not on matching the census.

So: **the tracker's "63... fixed or adjudicated-safe" does not hold
against the current tree.** As measured today, 4 hand fixes from 26
August did land (three re-confirmed by the 1 September census report by
reading the current lines; the fourth not re-located, flagged for a
follow-up read), the lint exists and runs, and it is red: 121
unadjudicated sites, 0 pinned exempt. This table narrows that 121 (135
raw) into a number Ian can actually rule on in one pass: **82 need a
code fix, 53 can be adjudicated safe on the stated mechanism** — each
SAFE row's reason is written to paste directly into `EXEMPT_SITES` and
an `ERROR-READ EXEMPT` source comment, exactly as `v134` already expects
(both must agree per the script's own design — see its header). No
`EXEMPT_SITES` entry or source marker was added in this pass;
`plugin_EML_StatsGraphs/` was not touched, per this task's hard
boundary.

## What was not done here

- The 82 FIX sites are not fixed. `eml_getGroupData`/
  `eml_getGroupPairedData`-proxy (33 sites, verified:
  `awk -F'\t' '$3=="eml_getGroupData" || $3=="eml_getGroupPairedData"'
  walkthrough/kit/audit/error_site_triage.tsv | wc -l` -> 33) and
  `emlCountGroups`-proxy (20 sites) are the two highest-value
  targets — both sit in the core inferential engine
  (`stats/eml-inferential.praat`'s Tukey/OneWay/KW/Dunn/Pairwise/
  Scheffe/Brown-Forsythe/Welch/Games-Howell kernels), not a peripheral
  script.
- The 6 not-sure sites were not traced further; each row names what
  would close it (a caller trace, or a runtime click-through).
- `EXEMPT_SITES` was not populated and no `ERROR-READ EXEMPT` marker was
  added — that edit is inside `plugin_EML_StatsGraphs/` / `validate/`,
  which this task's boundary reserves for the serial pass that owns
  that tree. This report is the input to that pass, not the pass
  itself.

## Files

- `walkthrough/kit/audit/error_site_triage.tsv` — 135 rows, the decision
  table.
- This report.
