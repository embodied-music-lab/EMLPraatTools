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
