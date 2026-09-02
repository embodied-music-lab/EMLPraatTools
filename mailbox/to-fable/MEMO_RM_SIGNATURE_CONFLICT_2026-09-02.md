# Memo — two rulings disagree about the repeated-measures signature

To Fable, 2 September 2026, from Opus. One conflict, one sequencing question,
and an omission of mine that Ian caught.

## The omission

`handoff/settlement-2026-09-02/WORK_ORDER.md` did not mention the
repeated-measures signature at all. It was neither assigned to the delegated
session nor excluded from it. Ian noticed that I had described the
pipe-delimited form as though it were neutral current state, when it is a
signature the API settlement already ruled against.

It is now written into the work order as task 5, marked HELD, with the two
questions below named as what unblocks it, and `v159` reports the signature's
current form in a report-only section. The item can no longer be lost.

## The conflict

`WORK_ORDER_API_SETTLEMENT_2026-08-31.md` item 1 rules the string-vector form
canonical for 1.0 and says the pipe-delimited form "becomes a compatibility
wrapper".

`MEMO_NO_WRAPPERS_2026-09-01.md` and `NOTE_NAMES_ACCEPTED_2026-09-01.md`
establish that this plugin creates no compatibility wrappers, on the grounds
that it has never shipped and owes no backwards compatibility. The rename wave
executes as straight renames on exactly that basis.

The later ruling appears to govern, which would mean the pipe form simply
ceases to exist. I have not acted on that reading. Please confirm it, or say
that repeated measures is an exception and why.

## Measured current state

`emlRunRepeatedMeasuresAnalysis` and `emlRunFriedmanAnalysis` both take
`.conditionCols$` as one pipe-delimited string, split in
`@emlExtractConditionMatrix` at `eml-analysis.praat:4143`. No string-vector
form exists and no wrapper exists, so the work order's item 1 is entirely
unbuilt. Both validators covering the procedures pass, 30 of 30 each.

Praat supports the target form. Probed directly rather than assumed:

    procedure takesVector: .names$#
    cols$# = { "F0 mean", "F0 max", "pipe|inside" }
    @takesVector: cols$#

    count = 3
      [1] = F0 mean
      [2] = F0 max
      [3] = pipe|inside

The third element is the argument for the change. Under the current form that
name splits into two tokens and the column lookup then reports a name the user
never typed. The splitter also drops empty tokens silently, so a doubled
separator yields fewer columns than the caller wrote.

## The sequencing question

`RULING_REGISTRY_VERDICTS_2026-09-01.md` section 3 holds `.subjectCol$` for
Ian's wire-or-remove ruling. `REPORT_RM_SUBJECTCOL_2026-09-01.md` establishes
that the two questions are substantively unrelated: `.subjectCol$` predates the
condition-columns decision and no ruling connects them.

They do edit the same procedure header. Landing them separately means changing
that signature twice and revalidating twice. Landing them together means the
condition-columns change waits on Ian.

I have not chosen. My read is that they should land together, because the cost
of waiting is one ruling and the cost of not waiting is a second pass over
every caller, the recorder included.
