# Survey module — build plan

Verification session, 25 Aug 2026. Target: usable by Ian's group next
week. This is a wrapper-and-declaration build on kernels that are already
validated — `@emlCronbachAlpha` (alpha, Feldt interval, alpha-if-item-
deleted) and `@emlAlphaInfluence` (leave-one-out respondent influence
with original-row mapping) passed a 154-of-154 reconciliation against
base R on 25 Aug, including a reversed-item fixture. No new statistics
are computed; everything below is declaration, routing, reporting, and
checks.

## Scope — question types processed

Likert-type ordinal items (full alpha family, reverse-scoring, subscales);
continuous rating items (same); numeric self-report items (as scale items
here, as outcomes through the existing suite); binary items (alpha
reduces to KR-20 and the report names it; single binary questions get
Wilson-interval proportions); unordered categorical questions (chi-square
with Cramér's V between two of them; per-option Wilson proportions);
demographic and grouping questions (declared as grouping, feeding scale
scores to the existing comparison doors).

Not processed, stated in the docs: free-text responses; rank-order
questions — every respondent's ranks sum to the same constant, so the
scale total has zero variance and reliability is undefined for it by
mathematics (the module routes the agreement question to the existing
Friedman door instead); check-all-that-apply as a unit (each option can
be declared as its own binary item); polychoric ("true ordinal") alpha —
new kernel, new oracle, out of scope by name. Ordinal items are treated
as interval for alpha, which is standard practice, and the report
carries one line saying so.

## The declaration

Two small CSVs, written by the dialog, editable by hand as the escape
hatch, reused across semesters:

- `survey_scales.csv` — one row per subscale: name, response minimum,
  response maximum, type (ordinal or continuous). The range belongs to
  the SUBSCALE and is the instrument's printed range, never the observed
  one — reverse-scoring uses min + max − x, and an inferred endpoint
  corrupts silently the moment nobody used it.
- `survey_items.csv` — one row per data column: name, role (a subscale
  name, "grouping", or "ignore"), reversed (0/1).

## The dialog flow (primary surface)

1. **Draft scan.** With the data table selected (one row per respondent,
   one column per question), the scan derives a guess per column:
   few-valued integers → ordinal item; many-valued numeric → continuous
   item; two-valued → binary item; repeating text → grouping; unique
   text → ignore. Guesses seed the dialogs; they are never acted on
   silently.
2. **Scales page.** Subscale names (or "one scale") and each subscale's
   response range, seeded with the observed range as the guess for the
   user to correct to the printed endpoints.
3. **Item pages.** One row per question: a role dropdown (subscale
   names, grouping, ignore; seeded from the scan) and a reversed
   checkbox (seeded off). Praat allows no reactive reveal and has a page
   height budget, so items page in chunks (about ten per page), the
   repeated-measures picker's pattern. All labels obey the character
   law; the pages get group headings per the layout ruling.
4. **Write and run.** The dialog writes both CSVs beside the data, then
   runs. A later run with the same instrument seeds from the existing
   CSVs instead of from guesses.

## The validator (before any number)

Refusals, each with the teaching-message contract and a red demo: an
item naming a column the table lacks; a data value outside its
subscale's declared range (named by respondent row and item — a typo or
a wrong declaration, and the plugin cannot know which); a subscale with
fewer than two items; a reversed flag on a grouping or ignored column;
a scales file and items file that disagree on subscale names.

## The report (per subscale)

Alpha with the Feldt interval at the level in force; the item-deleted
table; leave-one-out respondent influence with ORIGINAL row numbers;
n and exclusions from listwise deletion, disclosed; the reversed items
LISTED by name (disclosure — prints always); the ordinal-as-interval
line (disclosure); KR-20 named when every item in the subscale is
binary; and an evidence flag, never an action: any item whose item-total
correlation is negative is marked as a candidate misdeclared reversal.
Grouping columns then feed scale scores to the existing comparison
doors. CSV export through the existing writers; the recorded script
cites both declaration files by path (provenance rule).

## Oracles and checks, before dialogs print anything

Extend the committed lane oracles: reversal against base-R with the
declared keys (cross-checked against `psych::alpha` keys=), per-subscale
runs, the KR-20 binary case, translation invariance retained, and the
existing reversed-item fixture promoted to a driven leg. Red demos: each
validator refusal seeded. Corrected 26 Aug (builder's finding, verified):
alpha and its companions are INVARIANT to the declared endpoints, because
reversal shifts a reversed item by a constant — a wrong declared range
does NOT change alpha. The declared range reaches results through the
range refusals and through subscale scale scores (means), so the
declared-range red demo guards committed scale-score values instead. Dialog drive legs
under the display harness for the chunked pages, including Back with
values preserved (the flow-invariant check applies from birth).

## Build order — five gated stages, sequenced by dependency

Stage 1: schemas, validator, and every oracle red-demonstrated — no
wrapper code exists until the checks that would catch it do. Stage 2:
the reversal transform, per-subscale routing, and the report, driven
green against the oracles; entry condition is Stage 1's bundle. Stage 3:
the draft scan and the dialogs; entry condition is Ian's approval of the
language section. Stage 4: display-harness drive legs, recording, and
the refusal sweep. Stage 5: independent verification of the whole lane,
then Ian's dry run on real course data. Stages 1-2 and the language
approval are independent, so Stage 3's entry condition can be met while
Stages 1-2 run.

Roles, per the author-is-never-verifier law: this session builds (design
and language by the session itself; mechanical wiring fanned to cheaper
models through workflows, model named per task); verification of the
whole lane runs independently — the executing session or a dedicated
verifier that did not write the code. The lane's files
(`scripts/eml-survey.praat`, additions to `stats/eml-psychometrics.praat`,
new `validate/` checks) are disjoint from every door-round lane, so
nothing here touches the punch list.

## Survey templates (added 26 Aug, Ian's direction)

Shipped declaration templates for common instruments, so a user running a
standard survey skips the declaration and only confirms the column
mapping. A template is a pre-built pair of declaration files under
`plugin_EML_StatsGraphs/survey_templates/<instrument>/` carrying the
instrument's structure: item count and canonical item names, subscale
membership, response range, and reverse-scoring flags. Templates carry
structure and scoring only — never item text, which stays with the
instrument's publisher.

Mechanism, reusing the existing flow: the scales page gains one
optionmenu, "Start from" (blank, or an installed template). Loading a
template pre-fills the subscales, ranges, and reversal flags; the item
pages then serve as the column-mapping step, with each template item's
role seeded by name-match against the table's columns and every match
confirmable in the same dropdowns. No new page kind.

Verification standard, because a wrong reversal flag in a shipped
template is a wrong number for every user of that instrument: each
template cites the scoring publication it was built from, its key is
verified against that source by a person (not from anyone's memory),
and a committed check pins each template file by checksum so a template
cannot drift from its verified key silently. Templates ship in a
separate stage after the core dry run, so they extend the module without
gating it.

Candidate instruments, for Ian to prune or extend (voice and singing
first): VHI-30 and VHI-10, SVHI-36 and SVHI-10, VFI, EASE, V-RQOL, and
one generic single-scale Likert template. Reversal keys come from each
instrument's scoring publication during the template stage.

## Pinned details — no builder or verifier judgment remains

- **Draft-scan guess rules, exact:** integer-valued column with 10 or
  fewer distinct values → ordinal item; numeric with more → continuous
  item; numeric with exactly two values → binary item; text with
  repeats → grouping; text unique per row → ignore. These seed
  dropdowns only; nothing acts on a guess.
- **Items per dialog page:** as many as the dialog-height harness
  measures to fit, not a chosen number.
- **Misdeclaration flag threshold:** item-total correlation strictly
  below zero flags; no epsilon, no action.
- **One subscale failing does not kill the run:** a subscale whose
  kernel refuses (for example, fewer than 3 complete respondents)
  prints that refusal verbatim in its own report block, and the other
  subscales still run. Refusals are results.
- **Scale scores, for the grouping hand-off:** a respondent's subscale
  score is the MEAN of that subscale's items after reverse-scoring,
  complete-case (a respondent missing any item in the subscale gets no
  score for it, counted and disclosed) — mean rather than sum so scores
  are comparable across subscales of different lengths, complete-case
  to match alpha's listwise convention. Disclosed in the report.
  [Recommendation adopted; Ian can veto.]
- **This build's surface is the reliability command.** Categorical and
  grouping questions are declared and validated now; their analyses
  (chi-square association, Wilson proportions, scale-score comparisons)
  run through the existing doors by hand for now. A survey-association
  dialog is a later addition, named here so its absence is a decision.
- **The ordinal/continuous type affects one line.** It selects the
  disclosure sentence and nothing computational; no builder invents a
  difference.
- **KR-20 naming condition:** the line prints when the subscale's
  declared range spans exactly two values (max = min + 1) and every
  item's data is within it.
- **The verifier is a dedicated fresh session or agent,** not the
  executing session (which carries the door round) and not this session
  (which is the author).

## Language (needs Ian's approval before the dialogs are built)

Menu command: "Survey reliability...". Draft command: "Draft survey
declaration...". Scales page fields: "Subscale names" (sentence fields),
paired range row per subscale named by quantity: "Response range
(left/right)". Item row fields: "QUESTIONNAME" (comment) with "Role"
dropdown and "Reverse scored" boolean. Report lines: "Reverse-scored
items: Q3, Q7 (scored as min + max − response)." / "Ordinal items are
treated as interval for alpha; this is standard practice for summed
scales." / "Item-total correlation for Q5 is negative — check whether
this item should be declared reverse-scored." / KR-20 line: "All items
in this subscale are binary; alpha here is the Kuder-Richardson formula
(KR-20)." Refusal wording follows the teaching-message contract and is
drafted with the build, red demos first.
