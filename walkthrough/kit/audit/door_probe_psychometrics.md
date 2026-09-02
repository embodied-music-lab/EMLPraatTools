# Door probe — stats/eml-psychometrics.praat

Ian Howell — Embodied Music Lab. Measurement only; no file under
`plugin_EML_StatsGraphs/` was edited (verified clean below).

## Classification: NO_DOOR

No menu item registers any procedure from this module. Its absence from
the door chain that `validate/v162_door_chain_population.R` checks is
currently harmless: nothing a user can click reaches it.

Note on scope: the task's pointer to `mailbox/to-opus/RULING_THREE_DOORS_
2026-09-02.md` does not resolve — no file at that path exists anywhere in
the repository (checked with `find`). What exists is `mailbox/to-fable/
MEMO_THREE_DOORS_NOT_ONE_2026-09-02.md` (Opus's memo naming the three
modules, unruled at time of writing) and `RULING_RECORDER_AND_WIRING_
2026-09-02.md`'s "The two-way door" section, both read and used below.
This report proceeds on the task's own restated background, which matches
those two files.

## Step 1 — is there a menu item at all?

```
$ grep -n "Add menu command" plugin_EML_StatsGraphs/setup.praat | grep -i "reliab\|alpha\|psychomet"
(no output)

$ grep -n -i "reliab\|alpha\|psychometric" plugin_EML_StatsGraphs/setup.praat
371:# stats/eml-psychometrics.praat (@emlCronbachAlpha, @emlAlphaInfluence) and
399:emlSetupModule$ [ 7] = "stats/eml-psychometrics.praat"
```

Both hits are the module-table entry (comment + array row) that feeds the
generated user barrel — not an `Add menu command` line. No menu command
anywhere in `setup.praat` names reliability, alpha, or psychometrics.

Searched every door script for a call site:

```
$ grep -rln "emlCronbachAlpha\|emlAlphaInfluence\|emlRunReliabilityAnalysis" plugin_EML_StatsGraphs/scripts/
(no output, exit 1)
```

Searched the whole plugin tree (excluding the dev test suite, which loads
the module directly and is not a menu door):

```
$ grep -rn "emlCronbachAlpha\|emlAlphaInfluence" plugin_EML_StatsGraphs/ | grep -v dev/tests
plugin_EML_StatsGraphs/stats/eml-psychometrics.praat:11:# Provides: @emlCronbachAlpha, @emlAlphaInfluence
plugin_EML_StatsGraphs/stats/eml-psychometrics.praat:80:# @emlCronbachAlpha
... (all remaining hits are the procedure's own definition, its own
     header comment, or REGISTRY.tsv's comment naming it)
```

Every hit is the procedure's own file or documentation. No procedure,
door script, or dialog anywhere in the plugin calls @emlCronbachAlpha or
@emlAlphaInfluence. REGISTRY.tsv states this as policy, not oversight:

```
plugin_EML_StatsGraphs/REGISTRY.tsv:72-75
# Kernels stay INTERNAL even where a sophisticated user could legitimately
# call them (emlCholeskySolveMulti and kin; the survey kernels emlCronbachAlpha,
# emlAlphaInfluence, emlChiSquareIndependence, emlWilsonInterval; the graph
# dialog orchestrators emlGraphsWorkflow / emlGraphsDispatchDraw). A kernel
# enters this file only by a deliberate future decision, never by default.
```

There is a different, already-registered procedure that sounds adjacent —
emlRunReliabilityAnalysis — but it lives in stats/eml-analysis.praat
(a file the door chain already reaches) and is an explicit unimplemented
stub, not a wrapper for the psychometrics kernels:

```
plugin_EML_StatsGraphs/stats/eml-analysis.praat:4059-4062
# v1.2 item 7: unimplemented stub. It has no call sites anywhere in the
# plugin; it exists so the Phase 4 API surface is declared. It returns a
# non-empty .error$ and computes nothing ...
```

Its body sets .error$ = "Not yet implemented -- scheduled for Phase 4."
unconditionally and never calls @emlCronbachAlpha. It was already
adjudicated and exempted in RULING_RECORDER_AND_WIRING_2026-09-02.md
("The reliability string: exempted"), and it is a separate matter from
this module's door.

Conclusion for step 1: no menu item, and no procedure anywhere in the
plugin, calls into stats/eml-psychometrics.praat.

## Step 2 — does the include chain reach it?

Followed scripts/eml-lib.praat's includes transitively by hand:

```
$ grep -n "^ *include " plugin_EML_StatsGraphs/scripts/eml-lib.praat
36:include eml-lib-stats.praat
37:include ../stats/eml-analysis.praat
38:include eml-lib-graphs.praat

$ grep -n "^ *include " plugin_EML_StatsGraphs/scripts/eml-lib-stats.praat
44:include ../stats/eml-core-utilities.praat
45:include ../stats/eml-core-descriptive.praat
46:include ../stats/eml-extract.praat
47:include ../stats/eml-output.praat
48:include ../stats/eml-inferential.praat
49:include ../stats/eml-result-writer.praat
54:include ../stats/eml-record.praat
59:include ../stats/eml-demo-tables.praat

$ grep -n "^ *include " plugin_EML_StatsGraphs/scripts/eml-lib-graphs.praat
33:include ../graphs/eml-graph-procedures.praat
34:include ../graphs/eml-annotation-procedures.praat
60:include ../graphs/eml-draw-procedures.praat
61:include ../graphs/eml-graphs-form.praat
```

None of eml-core-utilities.praat, eml-core-descriptive.praat,
eml-extract.praat, eml-output.praat, eml-inferential.praat,
eml-result-writer.praat, eml-record.praat, eml-demo-tables.praat,
eml-analysis.praat, or the four graphs/ files include anything further
(checked with the same grep, all empty). scripts/eml-lib-lmm.praat (used
by the LMM door) resolves to the same closure plus eml-linalg.praat,
eml-optimizer.praat, and eml-lmm.praat — still no psychometrics.

The chain member that would have to name it is scripts/eml-lib-
stats.praat — the file that already lists every other stats/ module the
door chain carries (eml-core-utilities.praat through
eml-demo-tables.praat). It does not have a line naming
../stats/eml-psychometrics.praat, so the module never enters the closure
scripts/eml-lib.praat resolves.

Confirmed mechanically by the check the ruling ordered:

```
$ Rscript validate/v162_door_chain_population.R 2>&1 | tail -6
PASS  v162    every module setup.praat's table and the door chain must agree on is accounted for by some check  computed=NA  expected TRUE
FAIL  v162    every module setup.praat's table and the door chain must agree on a check reads was actually rendered  computed=NA  expected TRUE
FAIL  v162      phantom module setup.praat's table and the door chain must agree on: stats/eml-anova-kernel.praat, stats/eml-psychometrics.praat, stats/eml-categorical.praat  computed=NA  expected TRUE
------------------------------------------------------------------------------
10 checks, 8 passed, 2 FAILED
```

stats/eml-psychometrics.praat is named in the phantom list, same as the
other two.

## Step 3 — drive the door

Read harness/doorcensus/probe.praat first for shape. Its own header
explains why it, and validate/v90 / v93 (the psychometrics kernel's own
oracle tests), all include the psychometrics kernel directly rather than
going through any menu chain:

```
harness/doorcensus/probe.praat, header:
"This is the same choice v90/v93 made for the psychometrics lane (a
symlinked stats/ tree, no GUI), for the same reason: a dialog rig here
would be harness/correlgroup/run.sh's excise-and-hash machinery six times
over ..."
```

That confirms independently, from the harness's own design notes, that
there is no GUI/menu route to this lane worth driving — the existing kit
already treats psychometrics as kernel-tested-only.

Since step 1 found no menu item and no calling procedure anywhere, there
is no door script to drive as a user would drive one. As a confirmatory
check of what step 2's finding means in practice, I drove the same
mechanism the accepted two-way precedent used
(REPORT_RECORDER_COVERAGE_2026-09-01.md section 4) — call the kernel
through only the door chain — but run entirely from a /tmp scratch copy
of scripts/+stats/+graphs/, never inside the real plugin tree, per this
job's hard rule against editing under plugin_EML_StatsGraphs/:

```
$ MIRROR=/tmp/.../scratchpad/plugin_mirror
$ cp -r plugin_EML_StatsGraphs/scripts "$MIRROR/scripts"
$ cp -r plugin_EML_StatsGraphs/stats  "$MIRROR/stats"
$ cp -r plugin_EML_StatsGraphs/graphs "$MIRROR/graphs"

$ cat "$MIRROR/scripts/_psychometrics_door_probe.praat"
include eml-lib.praat
values## = { {4,3,4,5}, {3,3,3,4}, {4,4,5,5}, {2,3,3,4}, {5,4,4,5} }
@emlCronbachAlpha: values##, 0.95
appendInfoLine: "PSYCH_OK alpha=", emlCronbachAlpha.alpha

$ /usr/local/bin/praat6630 --run "$MIRROR/scripts/_psychometrics_door_probe.praat"
Error: Procedure "emlCronbachAlpha" not found.
Script line 67703 not performed or completed:
<< @emlCronbachAlpha: values##, 0.95 >>
Script ".../_psychometrics_door_probe.praat" not completed.
Praat: script command <".../_psychometrics_door_probe.praat"> not completed.
EXIT=255
```

Same failure text and shape as the two-way ANOVA precedent
(Error: Procedure "emlAnovaKernelTwoWay" not found.). Confirmatory second
probe, adding the missing include, shows the kernel itself is correct and
the only defect is the missing chain link:

```
$ cat "$MIRROR/scripts/_psychometrics_door_probe2.praat"
include eml-lib.praat
include ../stats/eml-psychometrics.praat
values## = { {4,3,4,5}, {3,3,3,4}, {4,4,5,5}, {2,3,3,4}, {5,4,4,5} }
@emlCronbachAlpha: values##, 0.95
appendInfoLine: "PSYCH_OK alpha=", emlCronbachAlpha.alpha

$ /usr/local/bin/praat6630 --run "$MIRROR/scripts/_psychometrics_door_probe2.praat"
PSYCH_OK alpha=0.8888888888888888
EXIT=0
```

What this probe does and does not show. It shows that if something
called @emlCronbachAlpha through the door chain, it would fail exactly
like the two-way crash. It does not show that a user can trigger this
today, because step 1 already established nothing in the plugin — no menu
item, no door script, no other procedure — calls it. There is no click
sequence a user can take that reaches this line. The scratch mirror was
deleted immediately after; git status --short plugin_EML_StatsGraphs/ was
empty before and after this probe (both checked and shown below).

## A path v162 does not model, noted but not classified as RESOLVES_ANYWAY

stats/eml-record.praat (itself reached by the door chain, via
eml-lib-stats.praat) contains a third list — the header text a "Record
script" session writes into an emitted, standalone .praat file so that
file is runnable on its own:

```
plugin_EML_StatsGraphs/stats/eml-record.praat:5033-5040
; The SURVEY kernels -- Cronbach's alpha and its respondent-influence
; jackknife, chi-square with Cramer's V, the Wilson interval. They are in
; the block because this list and setup.praat's generated barrel are the
; same list, pinned against each other by validate/v82 ...
.text$ = .text$ + "include " + .p$ + "/stats/eml-psychometrics.praat" + newline$
```

This is not a live dispatch path: it only ever writes the string
"include .../stats/eml-psychometrics.praat" into a separate file on disk
that a user would have to open and run independently, and only after
choosing "Record script" and performing some other, already-working
analysis — eml-record.praat never itself calls @emlCronbachAlpha. It is a
second instance of the same barrel-generation pattern v162's own header
already distinguishes from the interactive door chain (setup.praat's
table feeds "only the GENERATED user barrel ... not the plugin's OWN menu
doors"). It confirms that a sophisticated user who writes or runs their
own script can reach the psychometrics kernels (as v90/v93 do), which is
exactly what REGISTRY.tsv's policy comment above already says on purpose.
It does not put a menu item behind this module, so it does not change the
classification.

## Evidence that the plugin tree was not touched

```
$ git status --short plugin_EML_StatsGraphs/
(empty, before the probe)

$ rm -rf "$MIRROR"
$ git status --short plugin_EML_StatsGraphs/
(empty, after the probe)

$ ls plugin_EML_StatsGraphs/scripts/_psychometrics*
ls: cannot access '.../scripts/_psychometrics*': No such file or directory
```

## Summary

| Question | Answer |
|---|---|
| Menu item registered? | No -- searched setup.praat and every file under scripts/ |
| Any procedure calls the kernels? | No -- only the kernels' own file, comments, docs, and the dev test suite / v90 / v93 oracle harnesses, none of which are doors |
| Door chain reaches the module? | No -- traced transitively from scripts/eml-lib.praat; confirmed by validate/v162 |
| Crash reproducible today via a real door? | No such door exists to crash |
| Classification | NO_DOOR -- the module's absence from the chain is currently harmless; no user-facing crash exists behind it, unlike the two-way ANOVA case |

What a user would have experienced: nothing different from today's build.
There is no menu path, wizard step, or other door that reaches
stats/eml-psychometrics.praat's procedures, so its exclusion from the
door chain has produced no crash and no silently-broken feature -- only an
internal kernel that stays internal, which REGISTRY.tsv already states is
deliberate policy for these two procedures specifically.
