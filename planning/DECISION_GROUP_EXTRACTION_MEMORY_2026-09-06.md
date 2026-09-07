# Decision: group-extraction memory

## What needs deciding

The ANOVA group pull is the memory driver in the kit. One design choice sets
whether it stays that way. This needs a ruling because the fix is a wide change
to shared extraction code where a wrong move produces wrong statistics that
still look right.

## The evidence

The kit peaks at 1,963 MB, on the run of large NIST cells (SmLs03, SmLs06,
SmLs09 are each 18,009 rows in 9 groups). Measured on SmLs03, extracting all
nine groups three times over:

- Current path: 526 MB peak.
- Single-pass scatter, no per-group tables: 93 MB peak, group vectors
  bit-identical (same sums, same counts).

The driver is `eml_getGroupData`. For each group it builds a temporary subset
table with `Extract rows where`, reads one column out of it, and frees it.
Praat stores table cells as strings, so each subset clones thousands of string
cells, and the freed memory is not returned to the operating system during the
run. Column count barely matters: SmLs has two columns and still costs 526 MB,
so the overhead scales with rows.

## Options

### A. Single-pass scatter (largest win, widest change)

Read the data and group columns once as vectors, then partition into per-group
vectors in one pass by group index. No subset tables. Measured 526 MB down to
93 MB, bit-identical on clean numeric labels.

`eml_getGroupData` feeds every group-based kernel — one-way ANOVA,
Kruskal-Wallis, Brown-Forsythe, Games-Howell, and more — so this change touches
all of them at once. The scatter has to reproduce two behaviors the current
path gets from shared code: normalized text-label matching (`eml_normalizeLabel`)
and the per-cell handling of dirty or missing data cells (`emlExtractColumn`).
The safe form is probe-and-branch: fast scatter when the data column is strictly
numeric and the labels are clean, per-cell fallback otherwise. Sign-off is a
full-kit bit-identical check against the current extraction.

### B. Scatter the ANOVA path only (isolated win)

Add a bulk extractor that returns all group vectors in one pass, and route only
the one-way ANOVA kernel through it. The other callers stay on the current path.
The memory win lands where it balloons, and the blast radius shrinks to one
kernel. Two extraction paths then coexist and have to be kept in agreement, and
the same label and dirty-cell handling still has to match.

### C. Narrow the subset table

Rejected by measurement. The subset overhead scales with rows, and SmLs is
already two columns, so a narrower work table does not move the 526 MB.

### D. Do nothing

The reporter cache-reuse already removed the out-of-memory failure, so the run
completes. Peak stays near 1,963 MB and grows with row count. This holds only
while the headroom is there and the datasets stay this size.

## Recommendation

A or B. A gives the cleaner end state. B reaches the win with less risk. Both
need the full-kit bit-identical sign-off before landing. The rest of the
de-loop cleanup — the loop lint, the writers, the graphs — is low value and can
wait behind this.

## What this does not change

The kernel de-loop already landed and passed the golden gate (12,042 of 12,042
rows bit-identical). This decision is only about the group-extraction path and
its memory, not about any value the plugin reports.
