# Ruling — owned kernels: scope, SS types, outputs, sequence

Fable, 1 September 2026. Answers `MEMO_KERNEL_SET`,
`MEMO_TWOWAY_RED_DEMO`, and `MEMO_OWN_THE_KERNELS` (all 31 Aug)
together. SUPERSEDES `WORK_ORDER_TWOWAY_KERNEL_2026-08-31.md`,
which is withdrawn as written — its Khuri-direct kernel is the one
method we now do not implement. The red demo stands as the
measurement record; your finding that my order's revalidation rule
and its kernel spec cannot both hold against a Type II oracle on a
three-level factor is accepted, and the defect was mine — I
specified Khuri from the design thread without checking
oracle-hypothesis alignment. The kit's 2x2-only two-way fixtures
could never have caught it; that gap closes below.

## 1. Scope boundary, ruled

Ian's "let go of Praat's internals" splits at the line between
analysis commands and math primitives.

- ANALYSIS COMMANDS: zero use. No Praat statistical Report or
  analysis command is called anywhere in the plugin, ever. Nothing
  crosses a text representation.
- MATH PRIMITIVES (distribution functions and numeric builtins):
  keep where two conditions hold — continuously measured agreement
  with R at the standard rule (the kit's 10,841 comparisons ARE
  that measurement, renewed every run), and no build dependence.
  Praat's F, t, and chi-square functions stay on these grounds.
  `ptukey` fails the second condition (your cross-build
  measurement) and is replaced. The Wilcoxon location estimate and
  the alpha edge cases are replaced as measured divergences:
  Hodges-Lehmann as the median of pairwise averages; alpha edges
  as our stated definitions with exact oracles.

This is my reading of Ian's instruction, stated to him in one line
for veto. Your evidence-bounded proposal is adopted with the
build-dependence criterion added.

## 2. Sums of squares, ruled

Compute Types I, II, and III ourselves; DEFAULT TYPE III; the
output always names the type that produced the table. Your ruling
request from the red-demo memo is withdrawn as you proposed —
there is nothing to choose when we offer all three.

Implementation fact, measured in this container at 6.6.30:
`inv##` does not exist; `solve#` DOES and returns correct results
(probe: solve#({{4,7},{2,6}}, {1,0}) = (0.6, -0.2)). Build the
Type III Wald form on linear solves, never an explicit inverse —
this is also the numerically preferable shape. Your Gauss-Jordan
fallback is unnecessary.

Oracles: Type III leg = `car::Anova(fit, type = 3)` under
`contr.sum`; Type II leg = the existing oracle; Type I leg =
`anova()`. All at the standard rule, no clause.

The kit gains at least one unbalanced fixture with a three-level
factor. Without it the validation is silent on the only case where
the methods differ — your finding, adopted as a requirement.

## 3. The 1.0 output set, ruled

The full union list ships in 1.0: the table with selectable SS
type; partial eta squared, eta squared, and omega squared;
Levene's test; Shapiro-Wilk on residuals; an explicit balance
statement; estimated marginal means with standard errors and
confidence intervals; post hoc comparisons on the marginal means
through the existing machinery; and simple effects. Grounds:
Ian's instruction is "match them completely," and his standing
rule is that we do not publish an incomplete procedure set.
Estimated marginal means are not separable from Type III — they
are the quantities Type III tests, your own memo's argument. Any
trim is Ian's call alone; I am surfacing your cost statement to
him unedited, and your scope-and-price-at-actuals practice is
accepted.

## 4. Sequence, adopted, and the kernel-set questions dissolved

Your proposed order replaces mine:

refusal-set equality (done) → this ruling → API settlement with
the owned kernels written into the same pass (outcome contract
written once, into final shape) → kit re-pointed at the canonical
route → grand_ledger → full three-study run at a pushed commit →
Tier B count verdict → my inspection → frozen-release candidate.

The kernel-set memo's request — rule that the divergence clauses
will not change after the run — now holds by construction: the
divergent kernels are replaced BEFORE the run, and everything
that survives is frozen by the existing rule that nothing first
appears after it. Your clause table (everything retires except
D-WORDING) is adopted as the target state.

Build assertion, ruled: the authoritative run records the Praat
build AND the kit asserts it — a check that fails on mismatch, so
the evidence is self-attesting rather than merely annotated. This
survives the ptukey replacement because the run's provability
argument needs it regardless.

## 5. Open items, ordered

- `RUN_ME_PETERSON_BARNEY_EXPORT.praat`: Ian runs it once; the
  canonical check scores itself against the published numbers.
- The hand-implemented Type II/III figures are cross-checked
  against real `car` on Ian's machine before any of them reaches
  the paper or Josh. Until then they are working evidence only.
- The false comments at eml-inferential.praat:5064 and :5337 are
  corrected now; the code they describe is going away, and a
  false claim does not wait for its file to die.

## 6. Paper framing — flagged, not ruled

Wrapper-to-implementation is a coauthor-level framing question
for Ian and the drafting session, not mine. Two facts for that
conversation: the manuscript already states the plugin "does not
merely expose native commands," and one-way ANOVA is already a
direct implementation — the shift is smaller than the memo
fears. The kit-side claim becomes stronger and simpler: the
implementation computes stated definitions and agrees with R at
the standard rule, with the declared-clause set near zero. It is
settled before the authoritative run.

— Fable
