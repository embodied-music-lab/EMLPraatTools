# Registry proposals — survey-stats lane

Everything below is a PROPOSAL for the designated merging session. Nothing
in this lane edits setup.praat, eml-analysis.praat, eml-output.praat,
run_all.R, MANIFEST.txt, or any other existing file. Do not apply any of
this until Ian instructs the merge, after the release round closes.

## 1. Library barrel (plugin/scripts/eml-lib-stats.praat)

Add, after the eml-inferential.praat include (both new modules depend on
nothing, so position only needs to precede any future caller):

    include ../stats/eml-psychometrics.praat
    include ../stats/eml-categorical.praat

## 2. MANIFEST.txt rows

    stats/eml-psychometrics.praat | 355 | 1.0 | EML Stats : Psychometrics
    stats/eml-categorical.praat | 275 | 1.0 | EML Stats : Categorical Data

(Line counts as delivered; recount at merge if the files change.)

## 3. validate/run_all.R registration

Append to the ordered scripts vector, with comments in the house voice:

    "v90_lane_alpha_oracle.R",   # Cronbach's alpha kernel vs a base-R
                                 # oracle (covariance-matrix alpha, Feldt
                                 # CI via qf, leave-one-out drops);
                                 # psych::alpha cross-checks the oracle at
                                 # 1e-12 when installed (v17/broom
                                 # pattern); drives Praat live;
                                 # seeded-defect negative control inside.
    "v91_lane_chisq_oracle.R",   # chi-square independence + Cramér's V vs
                                 # chisq.test, both correction settings,
                                 # warning behaviour, zero-margin refusal;
                                 # drives Praat live; negative control inside.
    "v92_lane_wilson_oracle.R",  # Wilson interval vs prop.test(correct=FALSE)
                                 # incl. x=0 / x=n endpoint pins and two
                                 # Newcombe 1998 print pins; drives Praat
                                 # live; negative control inside.
    "v93_lane_alpha_influence_oracle.R",
                                 # respondent-influence jackknife vs a
                                 # base-R LOO oracle: every leave-one-out
                                 # alpha and delta, the alphaFull =
                                 # @emlCronbachAlpha.alpha equality pin,
                                 # and the original-row mapping pin
                                 # (dominant delta reported as original
                                 # row 17 with exclusions before it);
                                 # base R only by nature; drives Praat
                                 # live; negative control inside.

The base-R-only charter holds for all three: no package outside base is
required (psych is an opportunistic cross-check of the oracle itself,
the v17/broom pattern; the run prints which mode it ran in). See the
RESOLVED section at the bottom.

## 4. CI (.github/workflows/validate.yml)

Optional: adding r-cran-psych to the installed packages turns on v90's
1e-12 cross-check of the base-R oracle. Not required for green.

## 5. Eventual menu / export vocabulary — NOTES ONLY, NOT THIS PHASE

Explicitly out of scope for this lane and for the release round; recorded
so the wizard/menu phase does not have to rediscover the surface:

- Menu candidates: "Cronbach's alpha (matrix)...",
  "Alpha: respondent influence...",
  "Chi-square test of independence...", "Wilson CI on a proportion...".
- Tidy-export vocabulary candidates: alpha, alpha_ci95_low,
  alpha_ci95_high, alpha_if_deleted_<item>, n_excluded_listwise;
  alpha_without_<row>, alpha_delta_<row>, alpha_delta_max,
  alpha_delta_max_row (rows exported under ORIGINAL row numbers);
  chi_square, df, p, cramers_v, min_expected, n_cells_expected_below_5,
  continuity_correction (0/1); wilson_prop, wilson_ci_low, wilson_ci_high,
  confidence_level.
- Display standard at the doors: statistics fixed 4 decimals, p in APA
  via the existing @emlFormatP / @emlInlineP machinery; kernels return
  raw doubles and never print.
- The chi-square door should surface .warning$ verbatim when non-empty
  (smoke-alarm wording is already in the kernel's string).

## 6. Fixture and oracle files this lane added (no action needed)

- evidence/csv/lane_survey_alpha_{clean,revnotrev,2item,missing}.csv
- evidence/csv/lane_survey_chisq_{2x2_balanced,2x2_sparse,3x4,zerocell}.csv
- evidence/csv/lane_survey_wilson_cases.csv
- validate/oracle/lane_survey_oracle_dump.R and its committed output
  lane_survey_oracle_values.csv
- plugin/dev/tests/phase2/{test-psychometrics,test-categorical}.praat and
  verify-survey-lane.R
- lane/survey-stats/run_lane.sh (one-command lane green) and
  lane/survey-stats/evidence/ (green + red transcripts)

## RESOLVED by verification session, 17 Aug (post-delivery)

The v90 psych dependency (decision 9 / the flagged charter conflict) is
RESOLVED: v90's oracle is now computed in base R alone (raw alpha from the
covariance matrix; Feldt CI via qf; alpha-if-deleted from leave-one-out
covariance submatrices), with psych demoted to an opportunistic cross-check
of the oracle itself at 1e-12 when installed — the v17/broom pattern. Both
modes verified: 62/62 with psych present (16 cross-checks, including
alpha and the Feldt CI on the 2-item fixture; only the drop vector skips
cross-checking at k = 2, where psych prints a covariance ratio), 47/47
with psych hidden, red demonstration still exits 1. The base-R port was
independently cross-verified against psych 2.4.1 at exactly 0 difference on
all fixtures and on fresh-seed data. No ruling needed at merge; v90 is now
charter-compliant as-is.

## Style-rule amendment to relay to PraatGen (matrix idioms, measured 17 Aug)

Praat 6.6.30 matrix arithmetic, probed empirically: scalar `m## / x` and
elementwise `a## / b##` DO NOT exist, but elementwise multiplication
(`a## * b##`), elementwise power (`m## ^ p`), abs## and sqrt## all do — so
scalar division is `m## * (1/x)` and elementwise division is
`a## * (b## ^ -1)` (verified numerically). Vectors have true elementwise
division. Two capabilities are absent as OPERATORS on ##/# variables but
present through the object route: min/max reduction and elementwise
comparison. The operators refuse ("Cannot compare (<) a numeric vector
to a number"; "Cannot compute the minimum of a numeric matrix"), but
`Create simple Matrix from values: m##` + `Formula: ~ self < 5` +
`Get sum` / `Get minimum` do both, verified numerically on 6.6.30. The
master prompt's vector-first rule should document the composed
arithmetic idioms AND this operator-vs-object distinction, so absence
of an operator is never again read as absence of the capability. Per
Ian's 17 Aug ruling the categorical kernel demonstrates the arithmetic
idioms itself: the chi-square statistic and the Yates correction are
vectorized, and a small loop remains only for the two diagnostics —
where the object route works but was declined deliberately, to keep
object creation and removal out of a kernel that otherwise touches no
objects.
