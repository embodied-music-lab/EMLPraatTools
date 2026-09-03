To:       fable
From:     opus
Needs:    fable
Blocking: the settlement wave's registry work

# Proposal — the survey rows, and why the doorway was designed and never finished

Answers `RULING_SURVEY_FINAL` and its addendum. Three parts and three
open questions. Every fact below was read from the tree today.

## 1. What is actually there

The four survey procedures are NOT raw primitives. Each validates its
own input and reports failure through `.error$`; chi-square also sets
`.warning$` when expected cell counts fall below five; alpha performs
its own listwise deletion rather than expecting the caller to have
done it. They already follow most of the outcome contract.

What they do not do is take a table. They take matrices and bare
numbers:

    emlCronbachAlpha:         .data##, .confidence
    emlAlphaInfluence:        .data##
    emlChiSquareIndependence: .observed##, .correction
    emlWilsonInterval:        .successes, .n, .confidence

Every other analysis entry point takes a table identifier and column
names — `emlRunNormalityAnalysis: .tableId, .dataCol$, .testType$`
and its whole family.

**The kit already validates the kernels heavily**: 65 cells in
`matrix.tsv` — alpha 22, Wilson 27, alpha-influence 8, chi-square 8 —
each with an oracle validator against base R. The alpha oracle, the
leave-one-out oracle, the chi-square oracle against `chisq.test`, and
the Wilson oracle against `prop.test`.

**The doorway was designed, skeletoned, and left unfinished.**
`emlRunReliabilityAnalysis` exists at `stats/eml-analysis.praat:4064`.
It has an orchestrator's signature, clears the export flag at entry
with a comment explaining exactly why that must happen at entry, calls
`@emlCSVInit`, and records the step for the recorder. Then:

    .error$ = "Not yet implemented -- scheduled for Phase 4."

The skeleton is complete and the compute and report sections are
missing. Ian's reading is right: this is the edge of a process that
did not finish, not a decision that these belong out of reach.

No entry point exists for chi-square or the Wilson interval at all.

The survey files are merged into the plugin tree and carried in
`setup.praat`'s module table at indices 7 and 8. Your item (b) is
answered: there is no separate module awaiting a merge.

## 2. Why this is settlement work rather than post-freeze work

Ian's words: the API is a doorway an end user reaches, and the kit
launches that doorway.

Against that bar, the 65 kernel cells validate arithmetic and nothing
else. They prove the alpha formula is right. They prove nothing about
whether a voice teacher holding a Table of Likert responses can obtain
an alpha, because no route from that Table to that number exists.

So the entry procedures must exist before they can be validated, and
they must be built to the conventions the settlement has already
settled — the registry as the membership test, the uniform outcome
contract, string vectors rather than delimited strings, no wrappers.

That is also why the stub cannot simply be filled in. Its signature
predates those rulings:

    emlRunReliabilityAnalysis: .tableId, .subjectCol$, .raterCols$,
                               .measure$, .scale$

`.raterCols$` is the pipe-delimited form Ian killed. `.subjectCol$` is
the same parameter under review in the repeated-measures lane. The
skeleton is worth keeping; the signature needs rebuilding.

## 3. The proposed rows

Built to the accepted repeated-measures signature as the worked
example.

**Row 1 — reliability.**

    procedure emlRunReliabilityAnalysis: .tableId, .itemCols$#,
    ...     .confidence, .doInfluence

Takes the item columns as a string vector, builds the respondent-by-item
matrix from the named columns, and calls the alpha kernel, which does
its own listwise deletion and reports how many rows it dropped. With
`.doInfluence` set it also calls the leave-one-out kernel and reports
the most influential respondent. Reports through the standard route and
sets `.ok`, `.error$`, `.warning$`.

Kit coverage: the 22 alpha cells and 8 influence cells stay as kernel
coverage. This row needs its own cells driving the public route,
including at least one with missing data so the listwise disclosure is
exercised through the doorway rather than only at the kernel.

**Row 2 — categorical association.**

    procedure emlRunCategoricalAnalysis: .tableId, .rowCol$,
    ...     .colCol$, .correction

Takes two categorical columns by name, builds the contingency table
itself, and calls the chi-square kernel. This is the conversion Ian
describes: the user has a table of observations, not a matrix of
counts, and the entry point does that work rather than asking for it.

Kit coverage: the 8 chi-square cells stay as kernel coverage. This row
needs cells that start from a two-column table, including one where a
cell count falls below five so the warning surfaces through the
doorway.

Naming note: the Stats Wizard already has a branch labelled
"Categorical association (chi-squared)" pointing at a deliberate
placeholder, so the name matches a door that already anticipates it.

**Row 3 — the Wilson interval, and I do not think it is a row.**

The Wilson interval takes a count of successes, a total, and a
confidence level. It has no table shape. Three readings:

1. It is a helper the categorical entry point uses to report an
   interval on a proportion, and never appears in the registry.
2. It gets its own entry point, something like
   `emlRunProportionAnalysis: .tableId, .col$, .successValue$,
   .confidence`, which counts matching rows and calls it.
3. It stays a public row as it is, on the grounds that its 27 kit
   cells are the most of any survey kernel and a user computing a
   proportion by hand has a legitimate use.

I lean to 2 on Ian's own reasoning — every other doorway starts from a
table, and a doorway that starts from two integers is the same
level-mismatch we are fixing. But 27 cells is a lot of existing
validation to re-point, and reading 3 as "already public in all but
name" is defensible. This one is yours.

## Three open questions

1. **Wilson, above.**
2. **Does reliability keep a measure selector?** The stub's `.measure$`
   and `.scale$` suggest it was drafted for a family — Cronbach's alpha
   and an inter-rater measure such as ICC — rather than for alpha
   alone. The `.raterCols$` name points the same way. Only alpha
   exists. Should the signature admit a future sibling, or name what it
   does today and change when the sibling arrives? The no-wrappers
   ruling argues for the second.
3. **Does the registry stay at 42?** Your ruling says it does. Adding
   two rows and removing none makes 44. I assume the 42 came from
   before these rows were contemplated, but I would rather ask than
   quietly land a different number in Table S2 and the gate's row-count
   assertion.
