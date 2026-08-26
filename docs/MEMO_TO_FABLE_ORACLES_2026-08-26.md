# Memo to Fable — the oracles for 3.6 to 3.9, and what the code shows

Executing session, 26 August 2026, against `2a5d0a4`. Facts established by
reading the procedures and by driving R 4.3.3. No approach is proposed here;
the sequencing, grouping and validation scope are yours to rule.

## The oracle for every item, named

Ian's constraint: the R side calls what a statistician calls. A hand-rolled R
script is not an oracle, because Josh will not be running one.

    item                        oracle                                    installed
    -----------------------------------------------------------------------------
    .stN                        length() on the arm's vectors             base
    Hedges' g                   effectsize::hedges_g                      yes
    mean difference             t.test()$estimate                         base
    Hodges-Lehmann shift        wilcox.test(conf.int = TRUE)$estimate     base
    3.6 pairwise t interval     t.test(var.equal =, conf.level = 1-a/m)   base
    3.7 RM paired               t.test(paired = TRUE, conf.level = ...)   base
    3.7 RM signed rank          wilcox.test(paired = TRUE, conf.int)      base
    3.8 pairwise Wilcoxon       wilcox.test(conf.int = TRUE, conf.level)  base
    3.9 Scheffe interval        NONE INSTALLED                            no

`t.test` and `wilcox.test` are `stats`, which is what a statistician calls.
Six of the nine need nothing fetched.

## Three facts from the code that bear on the ruling

**1. `effectsize::hedges_g` USES THE EXACT CORRECTION.** Driven on a five-by-five
sample: d = -0.4880935; the approximate J gives -0.4408587; the exact `lgamma`
form gives -0.4406037; `effectsize::hedges_g` returns -0.4406037. So the
package a statistician calls already disagrees with the plugin, and it
disagrees in the direction of the exact form.

**2. Pairwise t offers BOTH Welch and Student, and the two need different
degrees of freedom.** `scripts/eml-pairwise.praat:50` carries an optionmenu
"T test type (pairwise t only)" with Welch first and Student second.
`@emlPairwiseT` refuses any other value. The kit drives 60 cells of each.
Student pools at `n1 + n2 - 2`; Welch uses Welch-Satterthwaite, which
`@emlTTest` already computes as `.df`. An interval built on the wrong `df`
looks plausible.

**The wizard route is Welch-only.** Its options are worded as complete recipes
-- "Pairwise Welch t, Holm (standard)", "Pairwise Welch t, Bonferroni
(conservative)" -- so Student is reachable from the direct dialog and not from
the wizard.

**3. The RM post-hoc parametric branch has no Welch variant, and cannot.**
`@emlRMPostHoc` (`stats/eml-analysis.praat:4625`) calls `@emlTTestPaired` on
the parametric branch and `@emlWilcoxonSignedRank` on the nonparametric one.
Welch's correction addresses unequal variances across two INDEPENDENT samples;
a paired test works on the differences, which is one sample with one variance.
Degrees of freedom are `n - 1`. So 3.7 inherits 3.6's interval SHAPE -- the
Bonferroni gate, the level, the `invStudentQ(0, df)` hang guard -- but not the
Welch/Student split.

## The one gap, and it needs your ruling

**Scheffe has no installed package oracle.** `DescTools::ScheffeTest` and
`agricolae::scheffe.test` both implement it. Neither is packaged for Debian,
and this container cannot reach CRAN.

The kit's Scheffe oracle is therefore our own evaluation of the published
definition through base R's `pf`. That is a closed-form definition rather than
a reimplemented procedure, but it is still our arithmetic, and it is the one
place in the kit where Josh would be right to discount the agreement.

Ian's note on precedent: your sessions have obtained packages without CRAN.
If there is a route to `DescTools` and its dependencies, item 3.9's oracle
stops being ours.

## What is yours to rule

1. The sequencing and grouping of the seven items.
2. Whether the items may be built in parallel, given that every one of them
   touches `stats/eml-inferential.praat`.
3. What validation runs at each step, and what waits for the gate.
4. The Scheffe oracle: fetch a package, or ship with the definition-based
   oracle and disclose it.

— executing session
