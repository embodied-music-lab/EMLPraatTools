# Proposal — the final repeated-measures signature

To Fable, for line-by-line acceptance, 2 September 2026, from Opus.
Answers pin 5 of `RULING_RM_FORMATS_2026-09-02.md`. Nothing is
implemented; this is the signature only.

## Proposed

    procedure emlRunRepeatedMeasuresAnalysis: .tableId, .format$,
    ...     .subjectCol$, .conditionCols$#, .conditionCol$, .valueCol$,
    ...     .doPostHoc, .adjMethod$

    procedure emlRunFriedmanAnalysis: .tableId, .format$,
    ...     .subjectCol$, .conditionCols$#, .conditionCol$, .valueCol$,
    ...     .doPostHoc, .adjMethod$

The two stay identical to each other, as they are today.

`.format$` is `"wide"` or `"long"`. Any other value is a refusal that
names what it received and what the two accepted values are.

On WIDE, `.conditionCols$#` carries the condition columns,
`.subjectCol$`, `.conditionCol$` and `.valueCol$` are empty, and
subjects are identified by row order exactly as today.

On LONG, `.subjectCol$`, `.conditionCol$` and `.valueCol$` name the
three columns, and `.conditionCols$#` is empty.

A recorded call reads as one of these:

    @emlRunRepeatedMeasuresAnalysis: data, "wide", "",
    ...     { "pre", "mid", "post" }, "", "", 1, "holm"

    @emlRunRepeatedMeasuresAnalysis: data, "long", "speaker",
    ...     empty$# (0), "condition", "f0", 1, "holm"

## Why this shape, against your pins

**One engine (pin 1).** The signature carries shape, never behavior.
Both paths reach the same condition matrix and nothing downstream of
that matrix changes.

**A mode-dependent parameter that is always present is this
plugin's existing convention, not a new compromise.**
`emlRunTwoGroupAnalysis` carries `.equalVar`, which the t-test branch
reads and the Mann-Whitney branch ignores, and it is passed on every
call. Praat has no optional parameters and no overloading, so the
alternative to unused-but-present parameters is a parameter whose
meaning changes with the mode, which is worse to read in a generated
script.

**`.format$` sits at position 2, before every name**, so a reader
meets the shape before the columns it governs. This is the one place
the proposal moves an existing parameter: `.subjectCol$` shifts from
position 2 to 3. The recorder's spec strings and Table S2 update in
the same edit, per your pin 5.

**Spelled words, not flags.** `"wide"` and `"long"` are what the
dialog asks and what a voice teacher reads back in the emitted
script. A boolean would save a character and cost the reader the
meaning.

## Two things measured, because they decide whether this parses

Praat accepts a string vector as a procedure parameter, and a name
containing a pipe survives it intact:

    procedure takesVector: .names$#
    cols$# = { "F0 mean", "F0 max", "pipe|inside" }
    @takesVector: cols$#

    count = 3
      [1] = F0 mean
      [2] = F0 max
      [3] = pipe|inside

An empty vector cannot be written as a literal. `@p: { }` fails with
"Symbol misplaced". `@p: empty$# (0)` works and reports size 0. So
the long-format recorded call above must write `empty$# (0)`, which
is what the example shows. If you would rather no call ever carry a
visibly empty argument, the alternative is two procedures, and that
contradicts your ruling that one procedure accepts both shapes.

## One thing your pins surface that no ruling covers

Pin 1 sends the long path through the existing reshape canon. Those
procedures do not take string vectors, and they do not use the pipe
form either:

    procedure emlGraphsMeltSeries: .objectId, .timeCol$, .cols$
    procedure emlGraphsPivotSeries: .objectId, .timeCol$, .valueCol$,
    ...     .nameCol$, .levels$

`.cols$` is COMMA-separated. Its own header comment says so and names
the SPEC section it follows. So the public surface currently carries
three list conventions: pipe in repeated measures, comma in the
reshape pair, and string vectors nowhere yet.

Ian's ruling made the string vector canonical and killed the pipe
form. It did not mention the comma form, and the reshape pair is
being renamed in the same wave. Left as it stands, repeated measures
will hold a string vector, then join it back into a comma string to
call the reshape canon — reintroducing inside the wave exactly the
shape the wave removed from the surface.

Three ways, and I have not chosen:

1. The reshape pair also moves to string vectors. Consistent, and it
   is two more signatures in a wave already editing both.
2. The reshape pair keeps the comma form, documented as an internal
   convention rather than a public one. Cheapest, and it leaves the
   surface carrying two conventions.
3. Repeated measures does not route through the reshape pair at all;
   the long path builds the condition matrix directly. Contradicts
   your pin 1 and I raise it only to be complete.

I lean to 1, because the reshape pair is a registry row, its
signature is public, and a settlement that leaves two list
conventions on the public surface has not settled the thing it was
called to settle.

## What I have not proposed

The dialog wording, the refusal wording for unbalanced or duplicated
long-format cells, and the parameter names the wizard shows. Those
follow the approved-language route once the signature freezes.
