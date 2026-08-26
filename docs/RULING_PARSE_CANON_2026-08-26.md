# Ruling — the parse canon: punch items 7.4, 7.5, 7.6

Fable, 26 August 2026, answering
`docs/QUESTIONS_FOR_FABLE_PARSE_2026-08-26.md` against the census at
`docs/PARSE_PARITY_CENSUS_2026-08-26.md`. REV 3 of the punch list carries
these items. Every diff names its item.

## Two classes, and they are not the same law

The ruling turns on a distinction the census did not draw:

**MISSING class** — empty, undefined, kind-3 placeholders. The cell is absent.
**ERROR class** — decimal comma, hex, out-of-range, whitespace-only,
unparseable text. The cell is present and wrong.

Missing is excluded. Error is refused. They do not share a code path and they
do not share language.

## 7.4 — hex and out-of-range are ERROR class, not coerced

Coerced is for RECOVERABLE HUMAN FORMATTING, which is what `%` is. `0x1A` is
not that: it is a PARSER ARTEFACT, not a reading of intent. And `1e-999` /
`1e999` are legitimate forms whose values cannot be represented — substituting
`0` or `inf` is a wrong number, not a lenient reading.

All refuse at first find, name the cell, and route to Check & repair.

**Record the census's own insight in the classifier's header**: parity cannot
catch consensus errors. Two doors agreeing on a wrong answer is invisible to
any cross-door comparison. So the contract is stated as:

> the cell reads as the number it looks like, TO A PERSON.

## 7.5 — the survey lane's cell ruling is the general law, every door

**MISSING class** — row-wise exclusion, with an ALWAYS-PRINTED disclosure.
The graphs layer relaxes its whole-column veto for this class; the
exclusion-parity guard covers the difference.

**ERROR class** — refuse at first find, name THAT ONE CELL, and route with the
approved sentence, verbatim:

> Run EML Stats & Graphs > Check & repair data, which lists and repairs all
> cells with error, then rerun.

The stats doors' behaviour change is DELIBERATE and uses that language.

**Check & repair remains the only full-inventory scan.** No other door
enumerates every bad cell; every other door names the first one and stops.

## 7.6 — the scan cap leaves the correctness path

Read-time classification is AUTHORITATIVE and scans EVERY CONSUMED ROW, in
both layers, with no cap.

The offer-time column filter may keep `.maxScanRows` as a DISCLOSED LATENCY
HEURISTIC ONLY. A capped miss then lands on the read-time refusal instead of
on a wrong figure.

Subsumes the punch item 7.3 overlap.

## The conformance list is endorsed, with one amendment

The "proceeds without ruling" list stands as conformance work.

**Amendment:** the `eml-lmm.praat` tripwire becomes A COMMITTED CHECK, not a
memo line. It goes red if `eml-lmm.praat` gains a registration while its
conversion sites remain ungated.

---

# Implementation note on 7.5 / 7.6 — the cap is REMOVED, not demoted

Fable with Ian, 26 August. The scan cap is not kept as a hint: it goes
entirely, because the latency reason for it dissolves.

## The fast path

Column classification runs at C speed through Praat's native regex row
extraction. One extraction of the column against the strict-number pattern:

- match count equals row count → the column is clean. Done, one native pass,
  regardless of table size.
- counts disagree → run the further native extractions per class (placeholder
  list, coerced patterns). Whatever matches none of them is the ERROR class,
  and extracting the non-matching rows hands you the offending cells for the
  refusal or disclosure without any script-level walk.

## Two approaches considered and REJECTED — recorded so they do not come back

**Sort-and-check-extremes** and **pull-to-matrix-and-catch.** Both are
PARSE-BASED, and the census's dangerous cells all parse — `0x1A` to 26,
`73,4` to 73, `1e-999` to 0 — so both certify the consensus-error class clean.

The matrix variant additionally has no clean failure mode: Praat has no error
catching, `nocheck` plus did-the-object-appear yields "failed somewhere" with
no cell name, and the refusal contract requires the name.

**Classification is a property of the cell's TEXT. Only text matching can
measure it.**

## Confirmed against PraatGen and by driving Praat 6.6.30

The command is `Extract rows where column (text): <column$>, <criterion$>,
<text$>`, catalogued in `pkb/COMMANDS_Table.txt:110`. Criterion `"matches
(regex)"` is accepted. Driven on a column of `70.1 / 0x1A / 73,4 / 75.5`
against `^-?[0-9]+(\.[0-9]+)?$`: **matched 2 of 4**, as required.

**Two constraints the implementation must carry:**

1. **THERE IS NO NEGATED REGEX CRITERION.** `"does not match (regex)"`,
   `"doesn't match (regex)"` and `"not matches (regex)"` are all rejected by
   the option parser. Negate INSIDE the pattern instead: Praat's regex engine
   DOES support negative lookahead, driven and confirmed —
   `^(?!-?[0-9]+(\.[0-9]+)?$).*$` returns exactly the offending rows.

2. **EXTRACTION RENUMBERS THE ROWS, so the original row number is lost** — the
   offender that was row 2 comes back as row 1 of the extract. The refusal
   contract requires naming the cell, which means the row. Carry an index
   column into the extraction: with a numeric `idx` column set before
   extracting, the driven result names original rows 2, 3 and 5 correctly.

## Consequences

`.maxScanRows` goes ENTIRELY. Offer-time filtering and read-time
classification both run the native fast path, so the two doors cannot disagree
about a cell past any row number.

The strict / coerced / placeholder regex patterns become COMMITTED FIXTURES
SHARED BY BOTH LAYERS — one definition, not two spellings. The frozen-choice
lesson applied to patterns.

**Acceptance.** A clean 100k+-row column classifies in one native pass through
both doors. A bad cell past the old cap refuses identically through both
doors, named.

**Red demonstration.** The current draw-door pass on a bad cell at row 100,001.

---

# Amendment — item 7.7, and the corrections to the note above

Fable, 26 August, accepting both drive findings and amending rather than
annotating.

**Negation inside the pattern: adopted** as driven.

**Index column: adopted, WITH A CONSTRAINT.** It rides on a WORKING COPY of
the table. It is NEVER added to the user's table. No mutation of user data,
ever — the fingerprint treats any change as a data change, so writing a column
into the user's table would invalidate a stored result as a side effect of
reading it.

**The demo pattern in the note above is NOT the fixture.**
`^(?!-?[0-9]+(\.[0-9]+)?$).*$` was written to prove negation works, and it is
wrong as a specification: it rejects strict-legitimate forms. The committed
patterns DERIVE FROM `@eml_classifyCell`'S CONTRACT, not from that
demonstration.

Driven on Praat 6.6.30 against the three forms named:

    1e5     -> 100000    strict-legitimate; the demo pattern rejects it
    +3      -> 3         strict-legitimate; the demo pattern rejects it
    1E5     -> 100000    strict-legitimate
    +3.25   -> 3.25      strict-legitimate
    5.      -> 5         strict-legitimate
    .5      -> undefined  SEE BELOW
    -.5     -> undefined  SEE BELOW

**Open on `.5` and `-.5`.** The amendment names `.5` as strict-legitimate.
Measured, Praat's `number()` returns UNDEFINED for it — the value cannot be
read at all, so it cannot be classified strict on the current contract. Under
the two-class law it is present and wrong, which puts it in the ERROR class
alongside unparseable text. A person writing `.5` means one half; Praat cannot
read it. Recorded as a question rather than assumed either way.

## 7.7 — the shared classification fixture

Born from the drive findings, and the reason it is necessary: THE REGEX FAST
PATH AND THE SCRIPT CLASSIFIER ARE TWO IMPLEMENTATIONS OF ONE CLASSIFICATION,
and they cannot share a definition across languages.

So they answer to a SHARED COMMITTED FIXTURE instead: one file of cell texts
covering every class —

- strict forms, INCLUDING scientific notation and signed values
- each coerced form
- each kind-3 placeholder spelling
- empty
- whitespace-only
- hex
- `1e-999` and `1e999`
- unparseable text

— driven through BOTH paths, RED ON ANY DISAGREEMENT.

**The fixture is the contract.** Extend it in the SAME COMMIT as any pattern
change or classifier change.

**Red demonstration:** seed one spelling into exactly one of the two
implementations.

Files as 7.7 in REV 3.
