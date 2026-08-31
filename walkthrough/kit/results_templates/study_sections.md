# Study sections — one register for SUMMARY.md's three studies

Added 28 August 2026, alongside the study split (Ian's ruling,
docs/MEMO_TO_FABLE_TIERS_2026-08-28.md). Three bodies of evidence, three
different questions, sharing one verdict. Each section below states its own
question and its own oracle; compare.R fills in only the live counts, at the
point it writes SUMMARY.md, the same way it fills a declared family's count
into the sentence its clause supplies from `reader_sentences.md`. The prose
itself is never built in code.

Keyed by study name (`options`, `sweep`, `nist`), matching matrix.tsv's own
`study` column.

---

## options
The kit's original question, asked over the plugin's own option space: every
lawful combination of test, post hoc, adjustment, variance assumption, group
order and confidence level the plugin's dialogs and wrappers can produce.
Oracle: R's own statistics packages -- rstatix, effectsize, car, afex,
multcomp, nortest, coin, psych -- computed cell for cell in `run_analyses.R`.

## sweep
A different question from the options study, asked over a designed grid of
shapes the demo tables never produce: k in {2, 3, 5}, n per cell from 3 to
200, balanced and 6:1 unbalanced, tie-free through heavily tied,
homoscedastic and 10:1 heteroscedastic. Where the options study asks whether a
printed report is right, this study asks whether the ANOVA, Tukey and
Kruskal-Wallis procedures behind it stay right on shapes those reports never
exercise. Oracle: base R's own `aov`, `TukeyHSD` and `kruskal.test`, computed
in `run_analyses.R` exactly like any other cell -- no new runner
(`validate/v18_sweep_parity.R` carries the grid's original derivation).

## nist
A question the other two studies cannot ask, because both of them compare the
plugin against a second implementation that could share its mistakes: does
the plugin agree with values certified to fifteen significant digits by an
outside body, computed in multiple-precision arithmetic? Oracle: the National
Institute of Standards and Technology's own published constants
(`nist_certified.tsv`), cited by dataset. There is no R oracle for this
study -- `compare.R` compares the plugin's own column against those constants
directly (`validate/v19_nist_strd.R` carries the harder, difficulty-graded
version of this same question).
