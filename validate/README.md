# Checking the statistics — start here

You need **R, and a Praat at or above 6.6.30 on your PATH.** Tested on R 4.3.3
and Praat 6.6.30. No R packages are installed, loaded, or required.

```bash
git clone https://github.com/embodied-music-lab/EMLPraatTools
cd EMLPraatTools
Rscript validate/run_all.R
```

This page said "R and nothing else" until 16 August 2026, and that was wrong.
Seven validators — v59, v63, v64, v65, v70, v71, v77 — resolve a Praat binary
and drive it, and each of them fails the check *a Praat at or above the
plugin's floor is available* when there is none. Measured on `v59` alone, with
no Praat on PATH, and the suite exits 1:

42 checks all passing becomes 6 checks with 1 FAILED. <!-- count-scope: v59_entry_points.R alone, not this suite's total; reproduce with `PRAAT=/nonexistent Rscript validate/v59_entry_points.R` -->

The **barren** edition is not enough either — it presents no dialogs, and
v59's subject is that every registered menu and action command reaches its
form:

28 of v59's 42 checks fail against `praat6630_linux-x64v3-barren`, and none fail against the full Linux build. <!-- count-scope: v59_entry_points.R alone, not this suite's total -->

`.github/workflows/validate.yml` installs exactly that, and is the shortest
correct answer to "what does this need".

The rest of the old claim holds: no R package outside base is used (v17 uses
`broom` when it happens to be installed, falls back to base R when it is not,
and prints which mode it ran in), and the suite itself makes no network call.

**Expect the summary line to end `0 FAILED`, and expect exit status 0.**

That is the whole thing. If it prints that, every number the plugin printed in
a committed run agrees with what R computes from the same input file.

Nothing on this page tells you how many checks that is, and the omission is
deliberate. The suite prints its own count, and that count rises every time a
validator is added — so a figure copied into a paragraph is a measurement of a
moving thing, and it begins going stale the moment it is typed. On 14 August
2026 an audit found four documents in this repository quoting four different
totals for this one suite, every one of them correct on the day it was written.
Zero failures is different in kind: it is a contract rather than a measurement,
so it cannot come apart with time. It is the only number here.

When you do need the figure — for a report, a release note, a reviewer who
asked — generate it from the run rather than quoting a document:

```bash
Rscript validate/run_all.R | tee /tmp/suite.log
Rscript validate/tools/gen_counts.R /tmp/suite.log
```

---

## What it is actually comparing

Each check pairs **a number the plugin printed** with **a number R computes**.

The printed number is not typed into the script. It is read out of a committed
text file — the Praat Info window, saved verbatim. So a check compares two
things that were produced independently, and either one can be inspected by
hand.

```
evidence/csv/     the input tables the plugin was given
evidence/info/    the Info-window text the plugin produced from them
validate/v*.R     recompute in R, read the printed value, compare
```

Those are real paths in this repository. Nothing is generated at run time and
nothing is fetched.

---

## Check one by hand, in two minutes

Do this once and the rest of the suite is just the same move, repeated for
every printed number in every committed capture.

**1. The input the plugin was given** — `evidence/csv/v09_anova_tukey_input.csv`

```
singer,voice_type,SPL_dB,vibrato_rate_Hz
Singer_1,Soprano,89.67870702901388,5.037382009972681
...
```

**2. What the plugin printed from it** — `evidence/info/v09_anova_tukey_info.txt`

```
  ── ANOVA Table ─────────────────────────────

Source              SS              df    MS              F           p
Between             480.41          2     240.21          14.2687     0.000019
Within              707.05          42    16.83
```

**3. What R says.** Paste this into R:

```r
d <- read.csv("evidence/csv/v09_anova_tukey_input.csv")
summary(aov(SPL_dB ~ voice_type, data = d))
```

```
            Df Sum Sq Mean Sq F value    Pr(>F)
voice_type   2 480.41  240.21  14.269  1.868e-05
```

480.41, 2, 240.21, 14.269. The plugin printed 480.41, 2, 240.21, 14.2687.

**4. Where the suite does that for you** —
`validate/v09_anova_tukey_orchestrator.R` — search it for
`"F (summary line)"`, currently line 84:

```r
check("v09", "F (summary line)",     printed(cap, "F"),           unname(s[["F value"]][1]), tol = 5e-5)
```

`printed(cap, "F")` reads 14.2687 out of the capture. `s[["F value"]][1]` is
R's 14.269. `tol = 5e-5` is half of the last printed decimal place.

---

## What a green run does and does not establish

**Does:** that the values in the committed captures are correct for the
committed inputs, and that the plugin's report is internally consistent —
printed totals equal their printed parts, printed matrices are symmetric or
antisymmetric as their statistic requires, each printed *t* equals its own
printed estimate over its own printed SE.

**Does not:** *prove to you* that the captures came from a real run of Praat.

That distinction matters, so read it carefully. The captures **are** real —
they are the Praat Info window from the live plugin, written to disk with
`info$()` during a GUI-driven session. Nothing here was typed by hand or
reconstructed. But an R script cannot demonstrate that to a stranger: R opens
a text file, and a text file that was fabricated would read identically. The
limit is in the medium, not in the provenance.

What does corroborate it, short of re-driving:

- **Every capture carries Praat's own clock**, printed by the plugin at run
  time — `Wed Aug 5 22:39:02 2026` in `v08`, `22:41:58` in `v09`, `22:42:52`
  in `v10`, `22:47:20` in `v11`. That is a session working down the menu in
  order over about eleven minutes. Someone faking these files would have to
  have faked a plausible clock too. (Two lack a timestamp: `v15`, whose
  report format has no date line, and `v07_r7_axis_info.txt`, which was
  produced headlessly — see below.)
- **The mutation driver** (`validate/mutation/`) corrupts these captures one
  at a time and shows the suite catches it. A suite that passed regardless of
  what the capture said would be validating nothing, real captures or not.

**If you want certainty rather than corroboration**, ask for the plugin,
Praat 6.6.30, and the harness under `harness/`, and re-drive it yourself. The
suite is deliberately separable from all of that so the arithmetic can be
checked without installing anything.

One capture is different and should be named: `v07_r7_axis_info.txt` was
generated on 6 August by calling the plugin's drawing procedures directly
under `praat --run`, with no GUI. That is the shipping plugin code operating
on the committed input, but it is not a session someone clicked through.

---

## Two kinds of evidence, and the limit on each

**`v01`–`v17` check the printed report.** Each is driven on **exactly one
input table**, taken through the real GUI, and every between-groups table is
balanced (3 × 15, 2 × 20, 2 × 2 × 12), complete, and — in the
Kruskal-Wallis/Dunn case — free of ties. That is strong evidence that what a
user *sees* is right, and no evidence at all about shapes the demo tables
never produce. `REGISTRY.md` §"One dataset per test" lists every input with
its shape.

**`v18` checks the procedures underneath**, over a 16-case designed grid:
*k* = 2/3/5, cells from *n* = 3 to *n* = 200, balanced and 6:1 unbalanced,
tie-free through heavily tied, 1:1 and 10:1 variance ratios. Those cases are
generated headlessly by `harness/sweep/tierB_grid.praat` calling the shipping
procedures directly — no GUI, and therefore no click-through provenance. It
covers the unbalanced Tukey-Kramer path and the Kruskal-Wallis tie correction,
neither of which `v01`–`v17` reach.

Neither implies the other, which is why both are here. A correct procedure can
still be printed into the wrong column; a correct report proves nothing about
data the report was never run on.

**`v19` checks against an outside authority.** Everything above ultimately
asks "does R agree?" — and R is a peer implementation, not a referee. `v19`
runs the plugin on NIST Standard Reference Datasets and scores it against
values NIST certified in multiple-precision arithmetic. It reports **correct
significant digits** (log relative error), which is how this kind of result is
conventionally stated, rather than pass/fail.

All eleven ANOVA datasets are run. Correct significant digits on the
between-group sum of squares — the quantity the difficulty grading is built
to stress — against base R on the same file:

```
AtmWtAg   plugin  10.24   base R   9.65
SiRstv    plugin  14.03   base R  12.74
SmLs01    plugin  15.10   base R  15.03
SmLs02    plugin  15.05   base R  14.26
SmLs03    plugin  15.15   base R  13.35
SmLs04    plugin  10.05   base R  10.05
SmLs05    plugin   9.94   base R   9.94
SmLs06    plugin   9.94   base R   9.94
SmLs07    plugin   4.03   base R   4.03
SmLs08    plugin   3.92   base R   3.89
SmLs09    plugin   3.91   base R   2.97
```

Read that column downward before reading it across. **Both implementations
lose digits on the harder sets, together.** The SmLs family increases the
number of constant leading digits in the observations — 1, then 7, then 13 —
while the between-group sum of squares stays near 1.68, so forming it means
cancelling away almost the whole mantissa. Four correct digits at SmLs09 is
what a 64-bit float has left, not a defect.

What the suite therefore asserts is **relative**: the plugin must come within
one significant digit of base R on the same data. That is a question about
this code rather than about IEEE 754. It holds on all eleven, and on five of
them the plugin is ahead.

The `.dat` files are NIST's and are not redistributed here, so a fresh clone
has none and `v19` prints a loud SKIP with the fetch command rather than
silently contributing nothing.

**`v23` is the first check of anything drawn.** It reads the Q-Q plot's own
plotted point pairs and compares them with `qnorm(ppoints(n, a = 3/8))` and
`sort(x)`, so the figure and the Shapiro-Wilk value beside it are bound to the
same numbers. It is no longer the only one: the validators added since read
rendered figures as pixels — a plot frame, a legend's coverage of the data it
names, the ink inside an axis, a bracket caption — and `REGISTRY.md`'s script
table says which does what. Still uncovered, and stated in the sharper form it
needs: the graphs layer runs its own second copy of the statistics behind an
annotated figure, and nothing here recomputes those. The 14 August 2026 audit
did it by hand against scipy and found no disagreement, which is a record and
not a check.

---

## The one thing that is not a check

Some lines print as `ATST` rather than `PASS`. Those are **attestations** —
claims backed by a screenshot or a recorded observation rather than by
anything the script can evaluate. They are excluded from the check count and
from the exit status, and reported on their own line, so that a report of *n*
checks passed means *n* things were tested and nothing was quietly counted
that could not fail. Most of them are in `v07`; `v20` carries one, recording
that its files came from the shipping orchestrator rather than a harness.

---

## If you want more

- **`REGISTRY.md`** — the full record: what each script covers, the
  conventions chosen where statisticians disagree, tolerance reasoning, the
  red-path cases, and an honest coverage statement including what is *not*
  covered. It is long because it is a reference, not a front door.
- **`validate/tools/check_registry_counts.R`** — the enforcement behind the
  rule stated at the top of this page. It reads `README.md`, `START_HERE.md`,
  `REGISTRY.md` and this file, and fails if any of them states a suite total
  other than zero. It does that from the documents alone, in about a second,
  without running the suite and without knowing what the true total is —
  which is the property that matters, because an enforcement that has to know
  the right answer is one more thing that can be out of date. Handed a run's
  log it also checks the run against itself: that the headline agrees with the
  `PASS`/`FAIL` lines it summarises and with the by-script table, and that the
  failure count is zero.
- **`validate/tools/gen_counts.R`** — the other half. Turns a run's log into
  the totals block, stamped with the date, the commit and the R version it was
  measured at. Nothing in this repository stores its output.
- **`validate/oracle/`** and **`validate/mutation/`** — two optional tiers:
  one checks `helpers.R` against scipy/pingouin/scikit-posthocs, the other
  corrupts committed captures to prove the suite notices. Neither is needed
  for the run above.

---

## Running one script on its own

Every script is standalone:

```bash
Rscript validate/v09_anova_tukey_orchestrator.R
```

They can be run from any working directory.

---

## One caution

**The plugin's demo tables are randomly generated on each creation.** Making a
fresh `Three groups (N=45)` table in Praat and re-running will not reproduce
any number here. Every script reads a committed input file for exactly that
reason. Do not substitute freshly generated data.

---

Ian Howell — Embodied Music Lab — GPL-3.0-or-later
