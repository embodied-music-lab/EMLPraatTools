# The 42 → 45 settlement change — every site, measured off disk

Opus, 3 September 2026. RULING_SURVEY_ROWS_ACCEPTED_2026-09-03 orders
registry membership, Table S2, the gate assertion, docs generation and
the coverage map to move together as ONE change, not piecemeal. This
file is the list of what "together" actually means, found by grep rather
than recalled, so the change can be made in one pass and audited in one
read.

Nothing here is done yet. The three doorways must exist first;
reliability does, categorical and proportion are being built.

## Hand-edited sites

    plugin_EML_StatsGraphs/REGISTRY.tsv
        three data rows added; header comment "42 rows" → 45.

    validate/v155_public_registry.R
        RUN_EXCLUSIONS: DELETE the emlRunReliabilityAnalysis entry. Its
        stated reason — "unconditionally sets .error$ and computes
        nothing; has no real call site anywhere in the plugin" — became
        false when the doorway was built. Leaving it would exempt a
        working public procedure from the erosion check on grounds the
        tree contradicts. The emlRunLMMAnalysis entry stays.

    validate/v159_settlement_gate.R
        line 25 (header), lines 202-203: 42 → 45, both the section
        banner and the assertion.

    walkthrough/kit/INSPECTION_PROTOCOL.md
        line 38: "exactly 42 rows" → 45. Same line's parenthetical
        "the exclusion entries (LMM, reliability)" drops reliability.

    walkthrough/kit/build_table_s2.py
        docstring and the emitted header comment (~line 106) narrate
        43-then-42. Rewrite to the settled state. The script asserts no
        count, so nothing breaks if this is missed — which is exactly
        why it would be missed.

    validate/recorder_coverage.tsv
        the emlRunReliabilityAnalysis row is EXEMPT with the same
        now-false stub reason. It flips to a real emitting site:
        eml-analysis.praat's guarded @emlRecordAnalysisStep, which emits
        a replayable "@emlRunReliabilityAnalysis: data, {...}, ..." call.
        Two rows added for the categorical and proportion doorways.

    validate/run_all.R
        line ~2009 comment narrates 42.

## Generated, so regenerate and commit the output

    walkthrough/kit/table_s2.tsv        build_table_s2.py
    walkthrough/kit/coverage_map.tsv    build_coverage_map.py
    walkthrough/kit/grand_ledger.tsv    grand_ledger.R

Neither v161 nor the coverage map hardcodes a count — v161 compares
registry rows to Table S2 rows and prints which state the tree is in.
That is the design working: the generated side follows without an edit.

## Kit coverage owed before the freeze

Per the ruling, kernel cells stay untouched (alpha 22, influence 8,
chi-square 8, Wilson 27) and each new row gains DOORWAY cells,
oracle-compared:

  - reliability: at least one missing-data case, so the listwise-
    deletion disclosure is exercised through the door;
  - categorical: one low-expected-count case and one pre-aggregated
    .countCol$ case;
  - proportion: at least one raw case and one pre-aggregated case.

"Correctly not covered" is unavailable for these three rows.

## Order

Doorways land → registry change in one commit → regenerate → gates.
The gate assertion and REGISTRY.tsv must move in the SAME commit or the
gate is red between them.
