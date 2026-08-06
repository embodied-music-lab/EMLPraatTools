# Checking the statistics — start here

You need **R and nothing else.** Tested on 4.3.3. No packages are installed,
loaded, or required.

```bash
git clone https://github.com/embodied-music-lab/EMLPraatTools
cd EMLPraatTools
Rscript validate/run_all.R
```

**Expect: `1045 checks, 1045 passed, 0 FAILED`, and exit status 0.**

That is the whole thing. If it prints that, every number the plugin printed in
a committed run agrees with what R computes from the same input file.

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

Do this once and the rest of the suite is just the same move repeated 1045
times.

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
`validate/v09_anova_tukey_orchestrator.R`, line 60:

```r
check("v09", "F (summary line)", printed(cap, "F"),
      unname(s[["F value"]][1]), tol = 5e-5)
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

Still uncovered: the graphing layer.

---

## The one thing that is not a check

Eight lines print as `ATST` rather than `PASS`. Those are **attestations** —
claims backed by a screenshot or a recorded observation rather than by
anything the script can evaluate. They are excluded from the 1045 and from the
exit status, and reported separately, so that "1045 checks passed" means 1045
things were tested. Seven are in `v07`; the eighth is in `v20`.

---

## If you want more

- **`REGISTRY.md`** — the full record: what each script covers, the
  conventions chosen where statisticians disagree, tolerance reasoning, the
  red-path cases, and an honest coverage statement including what is *not*
  covered. It is long because it is a reference, not a front door.
- **`validate/tools/check_registry_counts.R`** — verifies that every count
  claimed in `REGISTRY.md` matches a live run, so the document cannot drift
  from the code.
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
