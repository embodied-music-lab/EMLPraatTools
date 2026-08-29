# What the kit tests, procedure by procedure

One row per plugin procedure: the Praat procedure name, the R functions
the kit compares it against, the options the live run exercises, and how
many analyses cover it. Option lists and analysis counts come from
`matrix.tsv`; the R functions are the distinct `source` values this run's
`audit/r_results.tsv` recorded for that procedure's cells -- not a
hand-maintained map, so a procedure that stops calling a function stops
listing it here on the next run.

| Procedure | Praat procedure | Compared against (R functions) | Options exercised | Analyses |
|---|---|---|---|---|
| Alpha Influence | `@emlAlphaInfluence` | `base::ncol`, `base::nrow`, `psych::alpha`, `r::refuseCell` | — | 8 |
| Chi Square Independence | `@emlChiSquareIndependence` | `base::sum`, `effectsize::cramers_v`, `rstatix::cramer_v`, `stats::chisq.test` | correction: 0, 1 | 8 |
| Cronbach Alpha | `@emlCronbachAlpha` | `base::ncol`, `base::nrow`, `base::sum`, `psych::alpha`, `psych::alpha.ci`, `r::refuseCell` | conf: 0.90, 0.95, 0.99 | 22 |
| Anova Analysis | `@emlRunAnovaAnalysis` | `base::length`, `effectsize::cohens_d`, `effectsize::eta_squared`, `rstatix::cohens_d`, `rstatix::eta_squared`, `stats::TukeyHSD`, `stats::aov` | posthoc: 0, 1; group_order: alphabetical, discovery | 40 |
| Correlation Analysis | `@emlRunCorrelationAnalysis` | `base::sum`, `r::composePMethod`, `r::refuseCell`, `stats::cor.test` | test: both, pearson, spearman | 35 |
| Descriptive Analysis | `@emlRunDescriptiveAnalysis` | `base::length`, `psych::describe`, `psych::kurtosi`, `psych::skew`, `stats::IQR`, `stats::quantile`, `stats::t.test`, `stats::var` | — | 41 |
| Friedman Analysis | `@emlRunFriedmanAnalysis` | `base::sum`, `effectsize::kendalls_w`, `rstatix::friedman_effsize`, `rstatix::wilcox_test`, `stats::friedman.test`, `stats::median`, `stats::p.adjust`, `stats::wilcox.test` | posthoc: 0, 1; adjust: bh, bonferroni, holm | 22 |
| Grouped Regression | `@emlRunGroupedRegression` | `base::length`, `base::sum`, `stats::lm` | group_order: alphabetical, discovery | 6 |
| KW Analysis | `@emlRunKWAnalysis` | `base::length`, `effectsize::rank_biserial`, `effectsize::rank_epsilon_squared`, `effectsize::rank_eta_squared`, `rstatix::dunn_test`, `rstatix::kruskal_effsize`, `stats::kruskal.test`, `stats::p.adjust`, `stats::pnorm` | posthoc: 0, 1; adjust: bh, bonferroni, holm; group_order: alphabetical, discovery | 80 |
| Normality Analysis | `@emlRunNormalityAnalysis` | `base::length`, `psych::describe`, `psych::kurtosi`, `psych::skew`, `r::refuseCell`, `stats::shapiro.test` | — | 41 |
| Paired Analysis | `@emlRunPairedAnalysis` | `base::sum`, `effectsize::cohens_d`, `effectsize::rank_biserial`, `r::composePMethod`, `r::refuseCell`, `rstatix::cohens_d`, `rstatix::wilcox_effsize`, `stats::mean`, `stats::median`, `stats::sd`, `stats::t.test`, `stats::wilcox.test` | test: both, nonparametric, parametric | 25 |
| Pairwise Analysis | `@emlRunPairwiseAnalysis` | `base::length`, `effectsize::cohens_d`, `effectsize::rank_biserial`, `rstatix::t_test`, `rstatix::wilcox_test`, `stats::mean`, `stats::median`, `stats::p.adjust`, `stats::pairwise.t.test`, `stats::pf`, `stats::qf`, `stats::t.test`, `stats::wilcox.test` | test: scheffe, student, welch, wilcoxon; adjust: bh, bonferroni, holm, none; group_order: alphabetical, discovery | 200 |
| Regression Analysis | `@emlRunRegressionAnalysis` | `base::sum`, `r::refuseCell`, `stats::cor`, `stats::lm` | — | 10 |
| Repeated Measures Analysis | `@emlRunRepeatedMeasuresAnalysis` | `afex::aov_ez`, `base::sum`, `effectsize::eta_squared`, `r::refuseCell`, `rstatix::t_test`, `stats::mean`, `stats::p.adjust`, `stats::t.test` | posthoc: 0, 1; adjust: bh, bonferroni, holm | 22 |
| Two Group Analysis | `@emlRunTwoGroupAnalysis` | `base::length`, `effectsize::cohens_d`, `effectsize::hedges_g`, `effectsize::rank_biserial`, `r::composePMethod`, `r::refuseCell`, `rstatix::cohens_d`, `rstatix::wilcox_effsize`, `stats::mean`, `stats::median`, `stats::sd`, `stats::t.test`, `stats::wilcox.test` | test: both, nonparametric, parametric; equal_var: 0, 1; group_order: alphabetical, discovery | 34 |
| Two Way Analysis | `@emlRunTwoWayAnalysis` | `base::length`, `car::Anova`, `effectsize::eta_squared`, `r::refuseCell`, `r::slug` | — | 3 |
| Wilson Interval | `@emlWilsonInterval` | `base::identity`, `stats::prop.test` | conf: 0.90, 0.95, 0.99 | 27 |

Totals: 17 procedures, 624 analyses. Each analysis contributes every
quantity both programs report; the live run compared 10841 quantities.
