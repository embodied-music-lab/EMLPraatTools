# Memo to Fable — presentation work order: verified, one collision, three questions

27 August 2026. The two example files arrived. Everything below is measured
against the live 624-cell run, not against the examples.

## Verified against the run

`exceptions.tsv` is 34 rows with the six ordered columns, and the live run
produces exactly 34 declared rows carrying a numeric value on both sides.
The families match:

| Rows | Family | Clause |
|---|---|---|
| 18 | two-way ANOVA precision | `D-TWOWAY-PRECISION` |
| 14 | Tukey adjusted p | `D-PTUKEY` (4) + `D-PTUKEY-MID` (10) |
| 2 | leave-one-out alpha | `D-ALPHADROP` |

`SUMMARY.md`'s headline figures also match: 624 analyses, 17 procedures,
10,841 comparisons, 10,792 agreeing, 49 exceptions. The alpha sentence
checks out too -- the two deltas differ by exactly 1/3, consistent with
alphas of -8/3 and -3.0.

## The collision

The order keeps `VERDICT.txt` in `results/` and says only its `AGREE` label
needs fixing. It also orders a guard that fails any file under `results/`
containing internal vocabulary.

`VERDICT.txt` cannot pass that guard. Measured on the current file: **15 of
its 79 lines** carry blocklisted terms -- nine clause ids, three `DECLARED`,
two `quantities.tsv`, two `CONTRACT`. The file is written in the working
paper's voice, because until today it was the working paper's own output.

Three ways out, none of them mine to pick:

1. **Rewrite it** in the summary's register. New person-facing prose, which
   the approved example does not cover.
2. **Move it to `audit/`.** `SUMMARY.md` now does the job `VERDICT.txt` was
   doing, and the verdict file's real audience is whoever checks the working
   record.
3. **Exempt it** from the guard. Cheapest, and it puts a hole in the one
   check that keeps the vocabulary out.

My read is (2), because the summary supersedes it for a reader. That is a
guess, and today has been a poor day for my guesses about your rulings.

## Three questions

**1. The refusal number in the approved example is stale.** `SUMMARY.md`
says both programs refuse the same 24 analyses. The 624-cell run refuses 20
on each side; 24 was the count before the parse fixture's six cells left.
The order already makes this a filled placeholder, so nothing breaks -- but
confirm the sentence is meant to be generated, not fixed prose.

**2. Template sections do not map one-to-one onto clauses.** The summary
groups `D-PTUKEY` and `D-PTUKEY-MID` into one "Tukey's adjusted p-values"
section with a combined count. Your rule is that a new declared family with
no template section is a hard error. That needs a declared mapping from
clause id to section, so two clauses can share a section deliberately while
an unmapped clause still fails loudly. Confirm the mapping lives in the
template file, keyed by clause id.

**3. `c0561`'s note is person-facing prose.** The order lists it as already
ruled, but the sentence itself does not exist yet. `chi_square` and `p` on
that cell are `CONTRACT_UNDEFINED` -- the contract expects both sides and
neither reports. Send the sentence, or tell me to draft it for your approval.

## Status

Nothing is being built. The mechanical parts are ready to go on Ian's word:
the `out/` to `audit/` rename with its README, the three-step instruction
update, and the `AGREE` label stating both legs. Generation and the two
guards are staffed but unlaunched.
