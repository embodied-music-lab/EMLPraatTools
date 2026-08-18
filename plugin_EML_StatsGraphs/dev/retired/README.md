# Retired development artifacts

Files here are no longer part of the plugin or its test suite. They were
moved rather than deleted because the plugin tree is not under version
control — a delete here is unrecoverable.

Nothing in this folder is discovered by `dev/tools/run-tests.py` (which
roots discovery at `dev/tests/`), included by any shipped script, or
referenced by any remaining file. Each entry was grep-verified
unreferenced before the move.

| File | Retired | Reason |
|---|---|---|
| `test_coltype.praat` | 3 August 2026 | Scratch probe, 18 lines, **zero assertions**. Creates a Table, prints `Get value:` results in a loop, removes the Table. It could never pass or fail, so under the TEST RESULT REPORTING CONTRACT it was a permanent NO-SENTINEL entry in the runner — noise that looked like a broken suite. Test Inventory (2 August 2026) finding 8, "dead artifacts". |
| `spaghettit table.csv` | 3 August 2026 | Orphaned fixture, 21 lines. Sample long-format table (time, subject, value, group). No `.praat`, `.py`, or `.md` file in the tree reads it. Test Inventory finding 8. Filename also carried a typo (`spaghettit`) and an embedded space. Kept in case the spaghetti-plot path ever wants a fixture again — if so, rename it on the way back in. |

Restoring an entry is a plain `mv` back to the path recorded in
`MANIFEST.txt` history; both files are byte-identical to their retired
state (unmodified since 13 May 2026).
