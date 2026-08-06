# Response to the FABL-5 audit of `validate/`

Ian Howell — Embodied Music Lab — 6 August 2026

Thank you for this. It is the most useful thing anyone has done to that suite,
and three of the findings were live rather than theoretical.

Ten findings accepted and fixed. Two do not survive checking, and one of those
would have made the document worse if applied. One more is right in substance
and off by one in count. Details below, in your numbering.

Suite after the work: **454 checks, all passing, 6 attestations reported
separately, exit 0.** It was 446/445/1 when you audited it. The arithmetic of
that change is in §4.

---

## 1. Disputed

### V2 — REGISTRY's `F(2, 2) = 111` is correct; 441 is a different drive

You report that the R2 verdict row states 111, that the script's literal is
441, and that "the 111 appears nowhere else."

The 111 is in `evidence/info/rp_r2_rmanova_info.txt` — the file your own V3
cites as the 6 August re-drive. Its header block reads:

```
Subjects (complete cases) n = 2, conditions k = 3
F(2, 2) = 111.0000, p = 0.0089
Greenhouse-Geisser epsilon = 0.5000, GG-corrected p = 0.0602
```

R reproduces it from the committed re-drive input
(`evidence/csv/rp_r2_rmanova_input.csv`, rows 10/14/21 and 12/17/22):

```
cond       2    111    55.5     111 0.00893
```

And R reproduces 441 from the table `v07` constructs internally (70/72, 80/83,
90/94). Both numbers are right for their own data. Applying your proposed fix
would have replaced a figure traceable to committed evidence with one that is
not.

**What you half-found, and it is worth more than the finding as written.** The
R2 case was re-driven on a *different table*, and neither document said so, so
the verdict row narrated the 5 August defect while quoting the 6 August
number. That is a genuine confusion and it is now fixed: the row separates the
two drives, gives both sets of numbers, and states that the before/after is on
*behaviour*, not on numbers. A reader can no longer take it for a single
continuous case.

### V3 — the inventory is not short by three; it is mis-described

`v07` contains exactly three literals compared against R — `441.0000`,
`0.0023`, `0.5000`, at lines 249–251 — and those *are* the three the inventory
counts. There is no fourth, fifth or sixth in that file; a `grep` for compared
literals returns those three and nothing else.

What was wrong is the label. Calling them "three constructed properties of the
red-path tables" implies they describe the input. They do not: they are
transcribed plugin *output* from a drive whose capture was never committed.

So your substantive concern is correct and important — it is exactly the
unwitnessed-transcription class the section claims to have eliminated — while
the count is not. The inventory now names all three individually, states that
provenance, and says plainly that a reviewer cannot verify from this
repository that the plugin ever printed them. R reproducing all three is what
makes the arithmetic safe, and that is now stated as the limit of what they
establish.

### V8 — right, but five, not six

R1 ×2, R3, R5 ×1, R6 ×1. R5 has one such check, not two.

The substance stands and is fixed: they are a distinct `attest()` class now,
printed as `ATST`, excluded from the check totals and from the exit status. An
attestation still records what was observed and points at the artefact — that
is worth keeping — but the report no longer counts it as something that was
tested.

---

## 2. Accepted and fixed

### V1 — stale counts

Corrected, and the "Running it" framing with it. Also corrected the 442 figure
further down, which you did not flag and which was stale for the same reason.

### V4 — ambiguous labels do not halt, and the ambiguity is real

Fully confirmed, including your hit counts: `Soprano` matches 5 lines in the
v09 capture and 7 in v10; `voice type` and `task` match 2 each in v11.

Both your option (b) and your option (c) are implemented. `.cap_fields`,
`printed` and `printed_str` take an `expect_hits` argument that turns a wrong
belief into a halt, and 28 reads across v09, v10 and v11 are pinned with the
counts they depend on. Verified by asserting `expect_hits = 1` on `Soprano`
and confirming the halt:

```
label 'Soprano' matches 5 line(s) in v09_anova_tukey_info.txt; 1 expected.
```

The claims in `helpers.R` and REGISTRY are corrected to say what the harness
actually guarantees. I did not make ambiguity fatal by default: that would
break call sites that are correct but silent, and the pinned-belief form gives
the same protection where it is load-bearing.

### V5 — the floored-zero hole

This was the one that mattered. Confirmed exactly as you describe: with
`tol = 1e-28` against `p = 3.036e-29`, a plugin that floored the p to zero
passed. Tightened to half a display ULP — `5e-30` for the 29-decimal line,
`5e-26` for the 25-decimal one — and backed by explicit `p > 0` checks beside
them, so the guard does not depend on the tolerance being right.

### V6 — the 50% window

Accepted. Replaced with your bound, `0.5 * 10^-decimals`, with the decimal
count read from the capture string. That needed a new `printed_eq_str` helper,
since `printed_eq` destroys the information by converting to numeric.

### V7 — `expect = "differ"` on non-finite input

Confirmed; both branches now require finiteness first. One case you did not
name behaves the same way and is also fixed: `check(Inf, Inf, expect="differ")`
passed — two identical infinities reported as differing.

### V9 — the string-literal zero scan

Confirmed and fixed with your `as.numeric` filter.

### V11 — the wrong escape clause

Confirmed and dropped. Your reading of the rule is right: the large-n override
applies only when SW rejects, so it can never license overruling an SW that
did not.

### V12 — the over-matching regex

Confirmed: `.0001` matches, by `\.?` taking the point and `0*` taking a single
zero. One correction to the fix — the field carries its own label, so the
string being tested is `p < .001`, not `< .001`, and an anchor at the start
fails. Re-anchored at the tail: `(^|\s)<\s*0?\.001$`.

### Section C — the v02 premise

Adopted. Asserted from the capture headers rather than by diffing input files,
since the headers are what the comparison actually reads: both runs must
report the same Table, data column, group column, group count and pair count,
and must differ in the adjustment named. Six checks.

---

## 3. V10 — accepted diagnosis, rejected prescription, and a correction to
## both of us

Your diagnosis is right: the exported zero is the t-approximation at its
boundary, not a probability, and calling it "a true zero" was wrong. That
label is gone.

Your prescription — export the exact p, or a documented floor marker — does
not match R, and neither did my first answer to my own author, which was that
"R prints `< 2.2e-16` rather than 0". That is `print.htest`'s **display**. The
stored value is exactly zero:

```r
cor.test(1:12, 1:12, method = "spearman")$p.value   # 0
identical(cor.test(1:12, 1:12, method="spearman")$p.value, 0)   # TRUE
cor.test(1:12, 1:12, method = "pearson")$p.value    # 0
```

R computes an exact permutation p only for small n — at n = 6 it returns
`2/6! = 0.002778` — and switches to the approximation above that. At n = 12,
which is the committed case, R returns 0.

So the plugin is at parity with R and there is nothing to fix in it. The
exemption stands on its merits rather than as a tolerated defect, and a second
check now pins it to the `|rho| = 1` condition so it cannot silently widen to
cover a zero arriving some other way.

One small thing in your write-up: "the exact permutation p for n = 12 is
2/12! ≈ 2.09e-9". `2/12!` is 4.175e-9; 2.088e-9 is `1/12!`. The fraction and
the decimal disagree by a factor of two — presumably one-sided versus
two-sided.

---

## 4. R7, and the arithmetic of the new count

You correctly recorded R7 as the suite's one designed failure. It is closed.

R7 was described in `v07` for a month as "an axis case, judged from a figure,
[which] belongs with the graphing work rather than in an R suite". That premise
was simply wrong, and it took building an unrelated graph harness to notice:
**the draw procedures call no `beginPause:`**, so they run under `praat --run`
with no X server at all. An axis is a number. It never needed a figure.

`harness/broom_cases/r7_axis_drive.praat` reshapes the exact red-path table to
long form, renders it with `@emlDrawSpaghettiPlot`, and writes the axis the
plot actually used:

```
axis min            0.380000
axis max            0.580000
data min            0.401000
data max            0.548000
data fraction       0.735000
```

The data occupies **73.5%** of the panel. Under the `roundTo = 10` behaviour
D88 fixed it would have been 0–10, i.e. 1.5%. Seven checks read that capture,
including one asserting the axis is not the 0–10 grid and one requiring the
data to occupy more than half the panel. Figure at
`evidence/figures/r7_small_range_axis.png`.

The count moved four times, which is why 446 became 454:

| | Δ | |
|---|---|---|
| baseline you audited | 446 | |
| V8 — attestations leave the tally | −5 | |
| V5 — two positivity checks added | +2 | |
| V10 — the `\|rho\| = 1` pin | +1 | |
| Section C — v02 premise asserted | +6 | |
| R7 — driven | +7, −1 placeholder | |
| **now** | **454** | all passing, exit 0 |

---

## 5. What I did not do

- **R7's attestation.** One `attest()` remains on R7 recording that it was
  driven and pointing at the figure. The seven real checks carry the weight;
  the attestation is provenance.
- **Making `expect_hits` mandatory.** See V4.
- **Changing the plugin under a validation commit.** The Spearman question
  turned out not to need it. Had it needed it, the change would have gone in
  its own commit against the plugin, not folded into the suite.

Two things in your section C I would flag back as worth a second look, since
you verified them and I am relying on that: the claim that every nonstandard
statistic agrees with an independent oracle to ≤ 1e-10, and the mutation
tests. Neither is something this repository can demonstrate on its own — there
is no Python in the validation path and no mutation harness committed. If you
can hand back the oracle script and the mutation driver, they belong in
`validate/` alongside the rest, and the suite would be materially stronger for
having them run in CI rather than existing as a claim in a report.
