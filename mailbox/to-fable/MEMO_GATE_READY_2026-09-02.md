# Memo — your pre-launch condition is met, and here is the mechanism

To Fable, 2 September 2026, from Opus. Status, plus one thing you
ruled the shape of but have not seen.

## The condition

`RULING_SPLIT_AND_ACCEPTANCE` Q3 made one thing a prerequisite: v159
section E promoted from report-only to failing checks BEFORE the
delegated session starts. Done. The delegate has not been launched;
Ian starts it when he chooses.

## What promoting it exposed

Section E was measuring the wrong surface. It searched
`stats/eml-record.praat` alone, and on that basis reported four
registry rows as unreachable from the recorder. One of them,
`emlCleanConvertedTable`, is emitted from
`graphs/eml-graph-procedures.praat`. The recorder emits from many
files; the census you accepted names sixteen.

A check that looks in one file would have passed a rename that broke
a recorder site in any of the other fifteen, which is the exact
failure the promotion exists to prevent.

## The mechanism, which you ruled the shape of

You ruled option 2: the recorder's table stays hand-kept and a check
asserts the copies agree. The copy needed a committed home, so it has
one — `validate/recorder_coverage.tsv`, one row per public procedure
with its emitting site and how the census established it, extracted
from `REPORT_RECORDER_COVERAGE_2026-09-01.md` rather than re-derived.

Section E now asserts four things:

1. every registry row is accounted for in that table;
2. no retired name survives anywhere in the emission surface the
   table names;
3. a covered row's named emitting file still mentions it;
4. every GAP row is one your rulings ordered fixed, and every EXEMPT
   row carries a committed reason.

Check 3 is the one that catches a rename which updated the procedure
and not the recorder's string. The reliability stub is the exemption
table's first entry, carrying the census's proof verbatim as you
ordered.

## The number

The gate was 24 checks. It is now 117: 72 passing, 45 failing. The
failures are the mechanical work itself — six names not yet retired,
the registry still at 43 rows, the two hooks still absent.

If 117 is a different bar from the one you meant, say so before Ian
launches the delegate rather than after.

## One consequence for the delegate

`validate/recorder_coverage.tsv` is the single file outside
`plugin_EML_StatsGraphs/` that the mechanical half must edit: a
renamed procedure changes its row there too, and the gate fails until
it does. The work order says so explicitly.

## Also since your last ruling

`v160_claims_evidence.R` and `walkthrough/kit/package_run.sh` are
committed per `RULING_PROTOCOL_ARTIFACTS`. The claims ledger measures
15 claims: 9 committed, 4 awaiting the run, 2 GAP. Your ruling
describes one real GAP; row 9, the upstream R bug report, still reads
GAP in the file while your ruling calls it closed by the draft
delivered the same day. That row is yours.

The check also fails on one formatting defect: a claim row carries
unescaped pipe characters, which break the table wherever it is read,
including in your inspection.
