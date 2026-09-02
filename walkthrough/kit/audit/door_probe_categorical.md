# Door probe — stats/eml-categorical.praat

Ian Howell — Embodied Music Lab. Measurement only; no file under
`plugin_EML_StatsGraphs/` was edited (verified clean below).

## Classification: NO_DOOR

No menu item registers any procedure from this module. Its absence from
the door chain that `validate/v162_door_chain_population.R` checks is
currently harmless: nothing a user can click reaches it.

Note on scope, same as the psychometrics probe: the task's pointer to
`mailbox/to-opus/RULING_THREE_DOORS_2026-09-02.md` does not resolve — no
file at that path exists anywhere in the repository (checked with
`find`). What exists is `mailbox/to-fable/MEMO_THREE_DOORS_NOT_ONE_
2026-09-02.md` (Opus's memo naming the three modules, unruled at time of
writing) and `RULING_RECORDER_AND_WIRING_2026-09-02.md`'s "The two-way
door" section, both read and used below. This report proceeds on the
task's own restated background, which matches those two files, and
follows the shape of `walkthrough/kit/audit/door_probe_psychometrics.md`.

## Step 1 — is there a menu item at all?

```
$ grep -n -i "chi.square\|wilson\|categorical" plugin_EML_StatsGraphs/setup.praat
372:# stats/eml-categorical.praat (@emlChiSquareIndependence, @emlWilsonInterval)
400:emlSetupModule$ [ 8] = "stats/eml-categorical.praat"
```

Both hits are the module-table entry (comment + array row) that feeds the
generated user barrel — not an `Add menu command` line. No menu command
anywhere in `setup.praat` names chi-square, Wilson, or categorical.

Searched every door script for a call site:

```
$ grep -rln "emlChiSquareIndependence\|emlWilsonInterval" plugin_EML_StatsGraphs/scripts/
(no output, exit 1)
```

Searched the whole plugin tree (excluding the dev test suite, which loads
the module directly and is not a menu door):

```
$ grep -rn "emlChiSquareIndependence\|emlWilsonInterval" plugin_EML_StatsGraphs/ | grep -v dev/tests
plugin_EML_StatsGraphs/stats/eml-categorical.praat:11:# Provides: @emlChiSquareIndependence, @emlWilsonInterval
plugin_EML_StatsGraphs/stats/eml-categorical.praat:40:# @emlChiSquareIndependence
plugin_EML_StatsGraphs/stats/eml-categorical.praat:82:#   @emlChiSquareIndependence: counts##, 1
plugin_EML_StatsGraphs/stats/eml-categorical.praat:83:#   chiSq = emlChiSquareIndependence.chiSq
plugin_EML_StatsGraphs/stats/eml-categorical.praat:84:#   v = emlChiSquareIndependence.cramersV
plugin_EML_StatsGraphs/stats/eml-categorical.praat:94:procedure emlChiSquareIndependence: .observed##, .correction
plugin_EML_StatsGraphs/stats/eml-categorical.praat:207:# @emlWilsonInterval
plugin_EML_StatsGraphs/stats/eml-categorical.praat:229:#   @emlWilsonInterval: 17, 20, 0.95
plugin_EML_StatsGraphs/stats/eml-categorical.praat:230:#   low = emlWilsonInterval.ciLow
plugin_EML_StatsGraphs/stats/eml-categorical.praat:236:procedure emlWilsonInterval: .successes, .n, .confidence
plugin_EML_StatsGraphs/stats/eml-psychometrics.praat:93:# sibling @emlWilsonInterval take theirs. A caller working at alpha = .01
plugin_EML_StatsGraphs/REGISTRY.tsv:74:# emlAlphaInfluence, emlChiSquareIndependence, emlWilsonInterval; the graph
plugin_EML_StatsGraphs/setup.praat:372:# stats/eml-categorical.praat (@emlChiSquareIndependence, @emlWilsonInterval)
```

Every hit is the procedure's own file (definition, header comment, docstring
example) or documentation. No procedure, door script, or dialog anywhere in
the plugin calls @emlChiSquareIndependence or @emlWilsonInterval. REGISTRY.tsv
states this as policy, not oversight — the same comment block that exempts
the psychometrics survey kernels names these two by name too:

```
plugin_EML_StatsGraphs/REGISTRY.tsv:72-75
# Kernels stay INTERNAL even where a sophisticated user could legitimately
# call them (emlCholeskySolveMulti and kin; the survey kernels emlCronbachAlpha,
# emlAlphaInfluence, emlChiSquareIndependence, emlWilsonInterval; the graph
# dialog orchestrators emlGraphsWorkflow / emlGraphsDispatchDraw). A kernel
# enters this file only by a deliberate future decision, never by default.
```

### A near-miss worth recording: the wizard's "Categorical association" branch

A broader sweep for the words "chi-square" and "wilson" (not just the
procedure names) turns up a real, registered menu path that sounds like it
should lead here and does not:

```
$ grep -rn -i "chi.square\|wilson" plugin_EML_StatsGraphs/scripts/ plugin_EML_StatsGraphs/graphs/
plugin_EML_StatsGraphs/scripts/eml-wizard.praat:1694:        @wizardStub: "Categorical association (chi-squared)",
plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat:6016:        ... + "chi-squared approximation, which improves as the groups grow"
plugin_EML_StatsGraphs/graphs/eml-annotation-procedures.praat:6021:        ... + ") minus 1. Controls the chi-squared reference distribution."
```

`eml-wizard.praat` is a genuine door: `setup.praat` registers "Stats
Wizard..." three times (lines 60, 251, 310) pointing straight at it. Inside
the wizard, choosing the "categorical-by-categorical" relationship
(`relType = 3`) hits:

```
plugin_EML_StatsGraphs/scripts/eml-wizard.praat:1693-1696
    elsif relType = 3
        @wizardStub: "Categorical association (chi-squared)",
        ... "planned"
        goto WIZ_WHAT_NEXT
```

`@wizardStub` is a deliberate placeholder, not a bridge into the kernel:

```
plugin_EML_StatsGraphs/scripts/eml-wizard.praat:4518-4526
procedure wizardStub: .analysis$, .batch$
    appendInfoLine: "── Not Yet Available ──"
    appendInfoLine: ""
    appendInfoLine: "  ", .analysis$, " is planned for a future update."
    appendInfoLine: ""
    appendInfoLine: "  In the meantime, you can use the named tools"
    appendInfoLine: "  in the EML Stats & Graphs menu for available analyses."
    appendInfoLine: ""
endproc
```

It never calls @emlChiSquareIndependence or @emlWilsonInterval — it prints
a fixed "planned for a future update" message and returns the user to the
wizard's own routing (`goto WIZ_WHAT_NEXT`). This is the same shape as the
already-adjudicated `emlRunReliabilityAnalysis` stub (RULING_RECORDER_AND_
WIRING_2026-09-02.md, "The reliability string: exempted") — a named,
working "not yet implemented" dead end, not a crash and not a live call
into the withheld module. It does not change the classification: a user
choosing this wizard branch gets a clean message, not a crash and not
chi-square output.

`eml-wizard.praat` itself only `include`s `eml-lib-lmm.praat` and
`../graphs/eml-draw-qq.praat` (checked below in step 2) — neither of which
resolves `../stats/eml-categorical.praat` — so even setting the stub aside,
the wizard's own include closure cannot reach this module either.

Conclusion for step 1: no menu item, and no procedure anywhere in the
plugin (including the one wizard branch whose label mentions chi-squared),
calls into stats/eml-categorical.praat.

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

Checked every leaf for further includes (all empty — none go deeper):
eml-core-utilities.praat, eml-core-descriptive.praat, eml-extract.praat,
eml-output.praat, eml-inferential.praat, eml-result-writer.praat,
eml-record.praat, eml-demo-tables.praat, eml-analysis.praat, and the four
graphs/ files. The other door-chain member, scripts/eml-lib-lmm.praat
(used by the wizard and the LMM door), resolves to
`eml-lib-stats.praat` + `eml-linalg.praat` + `eml-optimizer.praat` +
`eml-lmm.praat` + `eml-analysis.praat` + `eml-lib-graphs.praat` — still no
categorical:

```
$ grep -n "^ *include " plugin_EML_StatsGraphs/scripts/eml-lib-lmm.praat
35:include eml-lib-stats.praat
36:include ../stats/eml-linalg.praat
37:include ../stats/eml-optimizer.praat
38:include ../stats/eml-lmm.praat
39:include ../stats/eml-analysis.praat
40:include eml-lib-graphs.praat
```

The chain member that would have to name it is scripts/eml-lib-
stats.praat — the file that already lists every other stats/ module the
door chain carries (eml-core-utilities.praat through eml-demo-
tables.praat). It does not have a line naming
../stats/eml-categorical.praat, so the module never enters the closure
either scripts/eml-lib.praat or scripts/eml-lib-lmm.praat resolves.

Confirmed mechanically by the check the ruling ordered:

```
$ Rscript validate/v162_door_chain_population.R 2>&1 | tail -6
PASS  v162    every module setup.praat's table and the door chain must agree on is accounted for by some check  computed=NA  expected TRUE
FAIL  v162    every module setup.praat's table and the door chain must agree on a check reads was actually rendered  computed=NA  expected TRUE
FAIL  v162      phantom module setup.praat's table and the door chain must agree on: stats/eml-anova-kernel.praat, stats/eml-psychometrics.praat, stats/eml-categorical.praat  computed=NA  expected TRUE
------------------------------------------------------------------------------
10 checks, 8 passed, 2 FAILED
```

stats/eml-categorical.praat is named in the phantom list, alongside the
other two.

## Step 3 — drive the door

Since step 1 found no menu item, no calling procedure, and the one wizard
branch whose label mentions "chi-squared" is a stub that never calls the
kernel, there is no door script to drive as a user would drive one. As a
confirmatory check of what step 2's finding means in practice, I drove the
same mechanism the accepted two-way precedent and the psychometrics probe
used — call the kernel through only the door chain — run entirely from a
`/tmp` scratch copy of scripts/+stats/+graphs/, never inside the real
plugin tree, per this job's hard rule against editing under
`plugin_EML_StatsGraphs/`:

```
$ MIRROR=/tmp/.../scratchpad/plugin_mirror_cat
$ cp -r plugin_EML_StatsGraphs/scripts "$MIRROR/scripts"
$ cp -r plugin_EML_StatsGraphs/stats  "$MIRROR/stats"
$ cp -r plugin_EML_StatsGraphs/graphs "$MIRROR/graphs"

$ cat "$MIRROR/scripts/_categorical_door_probe.praat"
include eml-lib.praat
observed## = { {10, 20}, {15, 25} }
@emlChiSquareIndependence: observed##, 1
appendInfoLine: "CAT_OK chiSq=", emlChiSquareIndependence.chiSq

$ /usr/local/bin/praat6630 --run "$MIRROR/scripts/_categorical_door_probe.praat"
Error: Procedure "emlChiSquareIndependence" not found.
Script line 67696 not performed or completed:
<< @emlChiSquareIndependence: observed##, 1 >>
Script ".../_categorical_door_probe.praat" not completed.
Praat: script command <".../_categorical_door_probe.praat"> not completed.
EXIT=255
```

Same failure text and shape as the two-way ANOVA precedent
(`Error: Procedure "emlAnovaKernelTwoWay" not found.`) and the
psychometrics probe (`Error: Procedure "emlCronbachAlpha" not found.`).
Confirmatory second probe, adding the missing include, shows the kernel
itself is correct and the only defect is the missing chain link:

```
$ cat "$MIRROR/scripts/_categorical_door_probe2.praat"
include eml-lib.praat
include ../stats/eml-categorical.praat
observed## = { {10, 20}, {15, 25} }
@emlChiSquareIndependence: observed##, 1
appendInfoLine: "CAT_OK chiSq=", emlChiSquareIndependence.chiSq

$ /usr/local/bin/praat6630 --run "$MIRROR/scripts/_categorical_door_probe2.praat"
CAT_OK chiSq=0.011666666666666648
EXIT=0
```

What this probe does and does not show. It shows that if something called
@emlChiSquareIndependence through the door chain, it would fail exactly
like the two-way crash. It does not show that a user can trigger this
today, because step 1 already established nothing in the plugin — no menu
item, no door script, no other procedure, and not even the one wizard
branch that names "chi-squared" in its label — calls it. There is no click
sequence a user can take that reaches this line. The scratch mirror was
deleted immediately after; git status --short plugin_EML_StatsGraphs/ was
empty before and after this probe (both checked and shown below).

## A path v162 does not model, noted but not classified as RESOLVES_ANYWAY

stats/eml-record.praat (itself reached by the door chain, via
eml-lib-stats.praat) contains a third list — the header text a "Record
script" session writes into an emitted, standalone .praat file so that
file is runnable on its own. eml-categorical.praat sits in the same block
as eml-psychometrics.praat, one line below it:

```
plugin_EML_StatsGraphs/stats/eml-record.praat:5033-5043
    ; The SURVEY kernels -- Cronbach's alpha and its respondent-influence
    ; jackknife, chi-square with Cramer's V, the Wilson interval. They are in
    ; the block because this list and setup.praat's generated barrel are the
    ; same list, pinned against each other by validate/v82: a module a user can
    ; load from the barrel and cannot load from a recorded script would make an
    ; emitted file that runs on one machine and not on the next edit of it.
    .text$ = .text$ + "include " + .p$ + "/stats/eml-psychometrics.praat" + newline$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-categorical.praat" + newline$
    .text$ = .text$ + "include " + .p$ + "/stats/eml-result-writer.praat" ...
```

This is not a live dispatch path: it only ever writes the string
"include .../stats/eml-categorical.praat" into a separate file on disk that
a user would have to open and run independently, and only after choosing
"Record script" and performing some other, already-working analysis --
eml-record.praat never itself calls @emlChiSquareIndependence or
@emlWilsonInterval. It is the same instance of the barrel-generation
pattern found for eml-psychometrics.praat, which v162's own header already
distinguishes from the interactive door chain (setup.praat's table feeds
"only the GENERATED user barrel ... not the plugin's OWN menu doors"). It
confirms that a sophisticated user who writes or runs their own script can
reach the categorical kernels, which is exactly what REGISTRY.tsv's policy
comment already says on purpose. It does not put a menu item behind this
module, so it does not change the classification.

## Evidence that the plugin tree was not touched

```
$ git status --short plugin_EML_StatsGraphs/
(empty, before the probe)

$ rm -rf "$MIRROR"
$ git status --short plugin_EML_StatsGraphs/
(empty, after the probe)

$ ls plugin_EML_StatsGraphs/scripts/_categorical*
ls: cannot access '.../scripts/_categorical*': No such file or directory
```

## Summary

| Question | Answer |
|---|---|
| Menu item registered? | No -- searched setup.praat and every file under scripts/, including the wizard's own routing |
| Any procedure calls the kernels? | No -- only the kernels' own file, comments, docs, and the dev test suite, none of which are doors |
| Near-miss? | Yes -- the Stats Wizard's "categorical association (chi-squared)" branch is a registered door, but it is a deliberate `wizardStub` placeholder that prints "planned for a future update" and never calls @emlChiSquareIndependence or @emlWilsonInterval, and its own include closure (eml-lib-lmm.praat) does not reach eml-categorical.praat either |
| Door chain reaches the module? | No -- traced transitively from scripts/eml-lib.praat and scripts/eml-lib-lmm.praat; confirmed by validate/v162 |
| Crash reproducible today via a real door? | No such door exists to crash |
| Classification | NO_DOOR -- the module's absence from the chain is currently harmless; no user-facing crash exists behind it, unlike the two-way ANOVA case |

What a user would have experienced: nothing different from today's build.
There is no menu path, wizard step, or other door that reaches
stats/eml-categorical.praat's procedures. A user working through the Stats
Wizard and picking the categorical-by-categorical relationship sees a
plain "planned for a future update" message, not a crash and not
chi-square output -- so this module's exclusion from the door chain has
produced no crash and no silently-broken feature. It is an internal kernel
that stays internal, which REGISTRY.tsv already states is deliberate
policy for these two procedures specifically.
