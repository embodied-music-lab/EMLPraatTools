# SS-type door — landed now, and what's deferred

Landed (commit a0062081, bundle 030): the two-way ANOVA public entry point,
`emlRunTwoWayAnalysis`, and its wrapper `emlTwoWayAnova` take an `.ssType`
argument and pass it to the kernel, which already computes Type I, II, and III.
Type III is the default. The registry signature and description carry the new
argument, the recorded call replays the selected type, and the full kit is
bit-identical to the baseline (Type III path unchanged).

Scope this phase, per Ian (6 Sep, ~9:30 PM ET): the kit and the public API only.
The wizard, the menu form, and drawing paths are a later phase. The items below
are logged for that phase.

## Deferred

- **Per-type kit coverage.** The kit exercises the two-way public route at Type
  III only. Type I and II need test cells: a way to name the type per cell in
  `walkthrough/kit/matrix.tsv` (the current schema has `col_a`/`col_b`/`col_c`
  and no type field), the runner reading it (empty defaults to III), and R
  oracle values for Type I and II sums of squares in the R comparison. The
  kernel's I/II math is already validated at the kernel level; this adds the
  public-route coverage.

- **Menu and wizard selection UI.** `scripts/eml-compare-twoway.praat` (the menu
  form) and `scripts/eml-wizard.praat` pass Type III as a keep-alive today. They
  need an SS-type optionmenu (default III) so a user can choose the type, plus
  the selected-type naming in the report. This is the "menu/wizard path" Ian
  deferred.

- **Dev tests.** `dev/tests/phase2/test-inferential-batch6.praat` and
  `dev/tests/phase2/test-fingerprint.praat` call `@emlTwoWayAnova` directly with
  four arguments. They need the fifth (a type) added. These files are outside
  the shipped barrel, so they do not affect the plugin load or the kit.

- **Table S2, the settlement gate, and the coverage map.** The registry row now
  carries the widened signature. RULING_SS_TYPE_CONTROL treats the signature
  widening as one change with the generated Table S2, the registry gate, the
  docs, and the coverage map. Regenerate and re-verify those against the updated
  registry row.
