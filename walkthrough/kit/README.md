# EML Stats & Graphs -- walkthrough kit

This folder is self-contained. Nothing is installed anywhere; nothing else
needs to be cloned. It reproduces seven statistical analyses two ways --
once with the EML Stats & Graphs Praat orchestrators, once with a plain
base-R script -- so you can compare them.

## What you need installed

- **Praat**, from [praat.org](https://www.praat.org) -- no plugin, no
  preferences-directory install. Version 6.6.30 or later (this kit was
  verified on 6.6.30).
- **R**, any recent version, no packages. `Rscript` on your PATH.

## Commands to run

From a terminal, `cd` into this folder and run either or both:

```
praat --run RUN_ME_FIRST.praat
Rscript run_analyses.R
```

Or, without a terminal: open Praat, use **Praat > Open Praat script...**,
choose `RUN_ME_FIRST.praat`, then **Run**. Both ways were tested and both
work; the script finds its own folder either way, so it does not matter
what directory you were in, or what folder Praat itself is running from.

## Where output lands

Both scripts write into `out/`, one report per dataset:

- `praat_<dataset>.txt` -- from Praat, e.g. `praat_v08_twogroup_input.txt`
- `r_<dataset>.txt` -- from R, e.g. `r_v08_twogroup_input.txt`

Six datasets, six pairs of files. (The seventh analysis, Friedman's test,
shares a dataset with the repeated-measures ANOVA, so its numbers are
appended to that same pair of files -- `demo_rm3_input`.) Each report also
prints to its program's own console/Info window as it runs.

## What to compare

Open a matching pair, e.g. `praat_v08_twogroup_input.txt` next to
`r_v08_twogroup_input.txt`. The numbers should agree. Where you will see a
*legitimate* difference in presentation, not a bug -- one line each:

- **APA p floors.** Praat prints `p < .001` once p drops below that
  threshold, alongside the exact value in parentheses; R just prints the
  exact value. Same number, different display convention.
- **Tukey's subtraction order is reversed between the two.** Praat prints
  `Soprano - Mezzo   5.5295  [1.8896, 9.1694]`; R's `TukeyHSD`, which
  `run_analyses.R` calls, prints the same pair as `Mezzo-Soprano  -5.5295
  -9.1694 -1.8896`. Same magnitude, same interval width, opposite sign and
  reversed bounds, because R subtracts row minus reference and Praat
  subtracts the first-named group minus the second. Compare magnitudes and
  read the labels.
- **Rank-biserial sign convention.** The sign follows which group is
  subtracted from which, same principle as Tukey above -- read the label,
  not just the number, before comparing across tools.
- **Dunn's test has no canonical base-R function.** `run_analyses.R`'s
  Dunn implementation is hand-written (rank-sum z with a pooled-rank
  variance correction for ties, Holm-adjusted), following the same formula
  the Praat orchestrator uses. There is no `dunn.test` in base R to defer
  to, so both sides are implementations of the same published formula, not
  one side calling the other as ground truth.
- **Spearman's t and df are an approximation.** Both sides convert
  Spearman's rho to an approximate t-statistic on n-2 df (the standard
  large-sample approximation) rather than using rho's exact permutation
  distribution. Fine for the sample sizes here; would understate
  uncertainty on very small or heavily tied samples.
- **The signed R in regression.** The regression report's "R" is the
  square root of R-squared but signed to match the slope, so a negative
  relationship shows a negative R at a glance -- it is not the unsigned
  multiple-R a stats package prints for models with more than one
  predictor (moot here, since this is simple regression with one
  predictor).

## Three questions for you

1. What dataset would you construct that you think would break this --
   expose a wrong number, not just an ugly one?
2. Where in `run_analyses.R` would you have written the statistics
   differently, and why?
3. If you handed a paper using this kit to a reviewer, what would they
   still not accept about how these numbers were produced or reported?
