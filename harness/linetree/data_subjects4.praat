# ---------------------------------------------------------------------------
# harness/linetree/data_subjects4.praat
#
# FOUR SUBJECT COLUMNS, ONE ROW PER TIME. The shape the tree calls shape 1
# with role = subjects: four numeric columns beside the time column, no text
# column, and exactly one observation at each time.
#
# THE FOUR SERIES OCCUPY FOUR DISJOINT BANDS -- 100s, 200s, 300s, 400s -- so
# that "four series are on the page" is answerable by looking at the figure
# rather than by trusting the melt. A fixture whose lines crossed would make
# the same claim unfalsifiable at the pixel level.
#
# NO TIME VALUE REPEATS, which is the ABSENT arm of the replication fork: the
# interval field must not appear on this leg's column page.
# ---------------------------------------------------------------------------
Create Table with column names: "lt_subjects4", 0, "time S1 S2 S3 S4"
for i from 1 to 12
    Append row
    r = Get number of rows
    Set numeric value: r, "time", i
    Set numeric value: r, "S1", 100 + i * 3 + (i mod 3) * 2
    Set numeric value: r, "S2", 200 + i * 2 + (i mod 4) * 3
    Set numeric value: r, "S3", 300 + i * 3 - (i mod 3) * 4
    Set numeric value: r, "S4", 400 + i * 2 + (i mod 5) * 2
endfor
ltSubjects4Id = selected ("Table")
