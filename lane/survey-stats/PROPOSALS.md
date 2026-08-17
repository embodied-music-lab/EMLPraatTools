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

    stats/eml-psychometrics.praat | 203 | 1.0 | EML Stats : Psychometrics
    stats/eml-categorical.praat | 275 | 1.0 | EML Stats : Categorical Data

(Line counts as delivered; recount at merge if the files change.)

## 3. validate/run_all.R registration

Append to the ordered scripts vector, with comments in the house voice:

    "v90_lane_alpha_oracle.R",   # Cronbach's alpha kernel vs psych::alpha:
                                 # alpha, Feldt CI, every alpha-if-deleted,
                                 # listwise disclosure; drives Praat live;
                                 # seeded-defect negative control inside.
                                 # NEEDS r-cran-psych (records a FAIL, not
                                 # a skip, when psych is absent).
    "v91_lane_chisq_oracle.R",   # chi-square independence + Cramér's V vs
                                 # chisq.test, both correction settings,
                                 # warning behaviour, zero-margin refusal;
                                 # drives Praat live; negative control inside.
    "v92_lane_wilson_oracle.R",  # Wilson interval vs prop.test(correct=FALSE)
                                 # incl. x=0 / x=n endpoint pins and two
                                 # Newcombe 1998 print pins; drives Praat
                                 # live; negative control inside.

NOTE: the suite charter says "base R only". v90 breaks that charter by
requiring the psych package, because the brief names psych::alpha as the
record oracle. The merging session should either accept the exception
(v90 degrades to an explicit FAILED check when psych is missing, never a
silent pass) or keep v90 out of run_all.R and run it from the lane runner
only. Flagged, not decided here.

## 4. CI (.github/workflows/validate.yml)

If v90 is registered: add r-cran-psych to the installed packages.

## 5. Eventual menu / export vocabulary — NOTES ONLY, NOT THIS PHASE

Explicitly out of scope for this lane and for the release round; recorded
so the wizard/menu phase does not have to rediscover the surface:

- Menu candidates: "Cronbach's alpha (matrix)...",
  "Chi-square test of independence...", "Wilson CI on a proportion...".
- Tidy-export vocabulary candidates: alpha, alpha_ci95_low,
  alpha_ci95_high, alpha_if_deleted_<item>, n_excluded_listwise;
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
