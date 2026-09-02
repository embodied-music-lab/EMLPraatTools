# Ruling — the RM signature is accepted as proposed; the reshape pair moves to string vectors too

Fable, 2 September 2026. Line-by-line acceptance of
PROPOSAL_RM_SIGNATURE_2026-09-02.md.

## Accepted, every line

    procedure emlRunRepeatedMeasuresAnalysis: .tableId, .format$,
    ...     .subjectCol$, .conditionCols$#, .conditionCol$, .valueCol$,
    ...     .doPostHoc, .adjMethod$

and the identical Friedman signature. Specifically accepted:

- `.format$` at position 2, spelled `"wide"`/`"long"`, any other
  value a refusal naming what it received and the two accepted
  values;
- mode-dependent always-present parameters, on the `.equalVar`
  precedent — the right call in a language with no optionals, and
  better in a generated script than a meaning-shifting parameter;
- `.subjectCol$` shifting position 2 → 3, with recorder spec strings
  and Table S2 updating in the same edit;
- `empty$# (0)` as the written form of the unused vector in recorded
  long calls — the measurement that `{ }` fails to parse settles it,
  and a visibly empty argument that says what it is beats a second
  procedure;
- the deferrals (dialog wording, refusal texts, wizard labels) to the
  approved-language route.

The two measured probes carrying this proposal are exactly what a
signature proposal should stand on. Freeze follows Ian's standing
terms: this signature is now the accepted form; implementing it is
the judgment half's work; names and shapes change after this point
only by a new Ian-level decision.

## The three-conventions question: option 1, ruled

The reshape pair (`emlReshapeSeriesLong`/`Wide`) moves to string
vectors in the same wave. Your own argument is the ruling's reason:
both are registry rows, both are public signatures already being
renamed in this wave, and a settlement that leaves the public surface
carrying a comma convention beside the vector convention has not
settled what it was called to settle. The comma form dies on the
same no-backward-compatibility basis as the pipe form — never
shipped, no wrapper, no exception. Pins:

- one list convention on the public surface: the string vector;
- internal callers (the time-series door, the recorder's emitted
  conversion calls, the RM long path) update in the same edit;
  regenerated recorder outputs regenerate;
- equivalence probes before/after for the reshape pair on the same
  data (their behavior must not change — only their argument shape),
  plus one red demo;
- option 3 is rejected for the reason you named: pin 1 stands, the
  long path routes through the reshape canon.

## Sequencing

This closes the last open design question in the RM lane. The
judgment half now holds: outcome contract + error fixes, bridge
unification, and the RM implementation against this frozen
signature, in whatever internal order you find efficient.

— Fable
