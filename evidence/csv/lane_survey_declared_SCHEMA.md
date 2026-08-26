# Survey declaration files

A survey declaration consists of two CSV files that describe a data
table of survey responses: `lane_survey_declared_scales.csv` and
`lane_survey_declared_items.csv`. The dialog writes both files beside
your data. You can also edit them by hand: this is the escape hatch
when a value needs correcting outside the dialog.

If a file's header row is quoted (for example `"scale","min","max"`),
the validator reads it correctly. You don't need to remove the quotes
yourself.

## The data table: wide format, one row per respondent

The data table these two files describe is **wide**: one row per
respondent, one column per question. Every column named in
`lane_survey_declared_items.csv` (`item`) is a column of that table,
read exactly as declared.

Subscale membership -- which columns belong to which subscale -- lives
**only** in `lane_survey_declared_items.csv`'s `role` column. The
validator never infers it from the data table: not from a column's
name, not from a naming convention, not from where a column sits in
the header row. A column named `Q1_Knowledge` is not read as
belonging to a "Knowledge" subscale by virtue of its name; it belongs
to whatever subscale its own declared `role` names, or to none at all
if `role` says `grouping` or `ignore`. This is a deliberate contract,
not an oversight: a data column's name is free text a respondent's
instrument chose, never a fact the validator special-cases on.

*(Stage 3 note: this section is the one place that states the wide-
format / declaration-only-membership contract. Stage 3's draft-scan
page, when built, should render this fact -- one row per respondent,
subscale membership from the declaration only, never inferred from a
column's name -- rather than re-deriving or restating it.)*

## `lane_survey_declared_scales.csv`

This file lists the subscales in your instrument, one row per
subscale.

| Column | Meaning |
| --- | --- |
| `scale` | The subscale's name. |
| `min` | The subscale's printed response minimum. |
| `max` | The subscale's printed response maximum. |
| `type` | The subscale's declared type: `ordinal` or `continuous`. |

### The range is the printed range

`min` and `max` record the response range printed on the instrument,
not the range observed in your data. If every respondent happens to
avoid the top of a 1-5 scale, the observed maximum is 4, but the
declared maximum stays 5. Reverse-scoring computes each reversed
item as `min + max - response`, so a range taken from the data instead
of the instrument corrupts every reversed score without producing an
error.

When `max` equals `min + 1`, the subscale's declared range spans
exactly two values, and the report names the subscale's reliability
statistic KR-20 instead of Cronbach's alpha. The underlying
computation is the same either way; only the name changes.

### Legal values

- `scale` must be non-empty and unique within the file.
- `scale`, underscore-normalized (see below), must also be unique
  within the file: two subscales whose names differ only by a space
  vs. an underscore (`"Vocal Health"` and `"Vocal_Health"`) collide,
  because both produce the same identifier, and the validator refuses
  the declaration rather than silently picking one.
- `min` and `max` must be numeric, with `min` less than `max`.
- `type` must be exactly `ordinal` or `continuous`.

### Display names vs. identifiers

A subscale's `scale` value is its **display name** and may contain
spaces (`"Vocal Health"`). Wherever that name has to become an
**identifier** instead -- a `term` value in an exported CSV, or a file
stem -- every space in it is normalized to an underscore
(`"Vocal_Health"`). The reverse direction (identifier back to display
name, underscore to space) is a separate, already-existing procedure.
Because both directions exist, and a name can arrive already
underscored by a user's own hand, the uniqueness rule above compares
names after normalization, not before.

## `lane_survey_declared_items.csv`

This file lists every column of your data table, one row per column.

| Column | Meaning |
| --- | --- |
| `item` | The column name, exactly as it appears in the data table's header row. |
| `role` | What the column is: a subscale name from `lane_survey_declared_scales.csv`, or the literal value `grouping`, or the literal value `ignore`. |
| `reversed` | Whether the item is reverse-scored: `1` if so, `0` if not. |

### Legal values

- `item` must be non-empty, unique within the file, and must match a
  column header in the data table exactly, including case.
- `role` must be one of: a `scale` value from
  `lane_survey_declared_scales.csv`, `grouping`, or `ignore`.
- `reversed` must be `0` or `1`. A `grouping` or `ignore` row must use
  `0`. Reversal only applies to a scale item.
- If `role` names a subscale, that item's column in the data table
  must hold numeric values. A `grouping` or `ignore` column may hold
  text.

## How the two files relate

Every `role` value that is not `grouping` or `ignore` must name a
`scale` that appears in `lane_survey_declared_scales.csv`. A subscale
needs at least two items with that `role` before its reliability can be
computed.
