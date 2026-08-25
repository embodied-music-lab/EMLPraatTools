# ============================================================================
# EML Stats : Test Suite — the result store's data key
# ============================================================================
# Tests: @emlDataFingerprint, @emlFingerprintsAgree, @eml_fpMix,
#        @emlGroupFingerprint, @emlAnalysisFingerprint, @eml_fpCompose
# Version: 2.1
# Date: 24 August 2026
#
# Uses shared test helpers (eml-test-helpers.praat).
#
# WHAT THIS SUITE IS FOR
#
# The result store lets a figure receive the analysis's result instead of
# re-running the analysis at draw time (docs/RULING_RESULT_STORE.md). A stored
# result is valid until a result-affecting setting changes or THE DATA
# CHANGES, and the data key is how the second half is decided.
#
# THE KEY HAS TWO TERMS AND THIS SUITE TESTS BOTH. Content: every cell of the
# table, so an edit to a column nobody declared still invalidates. Scope: the
# column names the caller declared, so two analyses of one unmodified table
# get two different keys. Dropping either term is a defect with a section of
# its own below — Defeat 8 for content, Defeat 9 for scope.
#
# AND THE KEY IS NOT THE WHOLE VALIDITY TEST. The last section but two
# measures two settings that move a printed number on a byte-identical key.
# That is a boundary, not a gap: it says what a store carries beside the key.
#
# ============================================================================
# READ THIS BEFORE "FIXING" ANY EXPECTATION IN THIS FILE
# ============================================================================
# TWO LEGS OF THIS SUITE ASSERT THE OPPOSITE OF WHAT THEY ONCE ASSERTED, AND
# THAT INVERSION IS DELIBERATE. A row reorder WITHIN a group, and the rename
# of a subject in an identity column, both MOVE the key. Earlier builds
# required both to HOLD it, and the sections below say so where they invert.
#
# AUTHOR RULING, Ian Howell, 24 August 2026:
#
#   "Since the result of 'somehow this data changed' is to safely rerun the
#    tests, I am fine with 'any change to the data including reordering of
#    rows' forces the mismatch error and redoing of the stats. Otherwise
#    rebuild as you see fit. Agreed we don't round away machine precision."
#
# The rationale for the old hold-on-reorder requirement was that reordering
# rows changes no result, so invalidating on it would make the store useless.
# THAT RATIONALE IS FALSE, and an adversarial pass proved it. Group order
# comes from DISCOVERY ORDER under the shipped default
# (emlGroupSortAlphabetical = 0, set in stats/eml-extract.praat from
# config_groupSort in graphs/eml-graphs-form.praat), so moving one group's
# rows above another's flips the sign of t, of Cohen's d, of rank-biserial r
# and of every Tukey mean difference, and inverts the comparison names. The
# hold-on-reorder requirement was not merely expensive. It was wrong.
#
# So: a reorder leg that goes RED here is this suite working. Do not restore
# the old expectation without a new ruling that overturns the one quoted
# above.
#
# THE RULING RELAXES ONE CLAUSE OF §a AND LEAVES THE REST STANDING. §a
# requires table identity plus BOTH COLUMN NAMES plus content; the 24 August
# ruling speaks only to row reordering and says nothing about the column
# names. So the scope legs below are not up for the same re-reading: closing
# an under-declaration hole is a reason to ADD whole-table coverage, never a
# reason to remove the declared scope. Both are required, and a leg asserting
# either is asserting §a.
#
# ============================================================================
# FIVE FORMATS HAVE WORN THESE PROBES
# ============================================================================
#   eGF1  per-level moment aggregates (n, sum, sum of squares, min, max)
#   eGF2  a digest of each level's quantised, SORTED value list
#   eDF1  a digest of the whole SORTED ROW LIST, over the columns an analysis
#         declared it read
#   eTF1  a digest of the WHOLE TABLE, every cell, in table order, at the
#         precision the table itself holds, and no column declaration at all
#   eTF2  the same whole-table digest, followed by a digest of the DECLARED
#         SCOPE — the column names the caller handed in, folded verbatim
#
# THE DEFEATS. Three adversarial passes broke eGF1 six times, eGF2 once and
# eDF1 twice. Every one of those fixtures is a section below and every one of
# them must now go GREEN. They are kept because a fixture that once defeated a
# key is the only kind of evidence that a later key is not merely differently
# blind.
#
#   Defeat 1   a compensating interior edit (five aggregates held exactly)
#   Defeat 1b  the same trick on one-decimal measurement data
#   Defeat 2   a whole-level label swap between aggregate-matched levels
#   Defeat 3   a label hash collision found by birthday search
#   Defeat 4   a tie perturbation of a couple of ulps, invisible to a
#              15-digit quantum, that moves Kruskal-Wallis across .05
#   Defeat 5   a second grouping factor the key did not describe
#   Defeat 6   a per-level spelling SET folded as a linear sum
#   Defeat 7   the digest's text-to-number step was two polynomial hashes, so
#              for equal-length strings the digest DIFFERENCE was a fixed
#              linear form in the character differences and the salt
#              cancelled; lattice reduction found a colliding pattern in under
#              a second, inside the digit alphabet, on the key's own numeric
#              text
#   Defeat 8   a caller that named fewer columns than its analysis read got a
#              key that looked complete
#   Defeat 9   a key built from content alone could not tell two analyses of
#              ONE unmodified table apart: three group comparisons over one
#              four-column table, one of them across .05, all sharing a key
#
# WHAT eTF2 DOES ABOUT THEM, in one line each: 1, 1b, 2, 4, 6 close because
# every cell is in the key as its own text, at the table's own precision, with
# nothing summarised and nothing quantised. 5 and 8 close because the CONTENT
# term describes the whole table, so an undeclared column is in the key
# whether or not anybody names it. 9 closes because the SCOPE term carries the
# column names the caller declared, so one table analysed two ways is two
# keys. 3 and 7 close because the mixing step is not a polynomial — see THE
# MIXING STEP.
#
# THE TWO TERMS ARE INDEPENDENT AND BOTH ARE LOAD-BEARING. Content without
# scope is Defeat 9; scope without content is Defeat 8. Every leg below that
# asserts an undeclared column moves a scoped key is guarding the first
# against being dropped in service of the second.
#
# NO ORACLE, AND WHY NONE IS NEEDED. There is no external authority on a
# fingerprint: the key is an internal identity, and what has to be true of it
# is not a value but a set of RELATIONS between keys — same data, same key;
# changed data, changed key. So every assertion here compares two keys the
# suite computed, and no literal key is written down. A literal would also pin
# the format, which is deliberately free to change behind its version tag.
#
# The library numbers this file does read — Kruskal-Wallis p, two-way F,
# Pearson r, a paired t — are read only to show that the RESULT moves across a
# mutation the key is being asked to catch. They are oracled in their own
# suites; here they are the premise, not the subject.
#
# This is why the suite is absent from dev/tests/REFERENCE_PROVENANCE.md and
# has no companion generator.
#
# THE MUTANT AND ITS CONTROL MUST SHARE A TABLE NAME. The key carries the
# table's name, so a mutation fixture built as a separately named table goes
# green on the name alone. Every fixture below names its table for the case
# and not for the mutation; only its contents differ.
#
# AND THE NAME IN THE KEY IS PRAAT'S, NOT THE ONE ASKED FOR. Praat rewrites a
# name it will not hold — "a b" becomes "a_b", "data|1" becomes "data_1" — so
# two fixtures a reader believes are named apart can carry one name term, and
# a mutation leg built on that difference pins nothing while passing. The
# section "Praat rewrites the name the key carries" measures the rewriting
# and the trap. Check the name the object ENDED UP WITH, with
# selected$ ("Table").
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy.
# ============================================================================

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-core-descriptive.praat
include ../../../stats/eml-extract.praat
include ../../../stats/eml-output.praat
include ../../../stats/eml-inferential.praat
include ../eml-test-helpers.praat

@emlTestInit

random_initializeWithSeedUnsafelyButPredictably: 20260824


# ============================================================================
# FIXTURES
# ============================================================================
# Nine rows, three levels, three values each. Every mutant is a fresh build of
# this table with one thing done to it, and every build carries the same name.
# ============================================================================

procedure fpFixture
    .id = Create Table with column names: "fp_case", 9, { "grp", "val" }
    Set string value: 1, "grp", "A"
    Set numeric value: 1, "val", 10.5
    Set string value: 2, "grp", "B"
    Set numeric value: 2, "val", 20.25
    Set string value: 3, "grp", "A"
    Set numeric value: 3, "val", 11.75
    Set string value: 4, "grp", "C"
    Set numeric value: 4, "val", 30.125
    Set string value: 5, "grp", "B"
    Set numeric value: 5, "val", 21.5
    Set string value: 6, "grp", "A"
    Set numeric value: 6, "val", 12
    Set string value: 7, "grp", "C"
    Set numeric value: 7, "val", 31.25
    Set string value: 8, "grp", "B"
    Set numeric value: 8, "val", 22.75
    Set string value: 9, "grp", "C"
    Set numeric value: 9, "val", 32.5
endproc

procedure fpKey: .id
    @emlDataFingerprint: .id
    .key$ = emlDataFingerprint.result$
    .error$ = emlDataFingerprint.error$
endproc

@fpFixture
control = fpFixture.id
@fpKey: control
controlKey$ = fpKey.key$


# ============================================================================
@emlTestSection: "The key was computed at all"
# ============================================================================

@emlTestAssertTrue: "the control key is non-empty", controlKey$ <> ""
@emlTestAssertEqualStr: "the control reports no error", "", fpKey.error$
@emlTestAssertEqualNum: "nine rows", 9, emlDataFingerprint.nRows, 0
@emlTestAssertEqualNum: "two columns", 2, emlDataFingerprint.nCols, 0
@emlTestAssertEqualStr: "and it covers both of them, in table order",
... "grp,val", emlDataFingerprint.covers$
@emlTestAssertContains: "the key names its format version", controlKey$, "eTF2"
@emlTestAssertTrue: "the key is short enough to store",
... length (controlKey$) < 120

@fpFixture
twin = fpFixture.id
@fpKey: twin
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "an identical rebuild agrees",
... emlFingerprintsAgree.same = 1


# ============================================================================
@emlTestSection: "Probe 1 — a value swapped BETWEEN groups"
# ============================================================================
# The value column's multiset and both group sizes are unchanged; every group
# mean moves. This is the probe a column-level checksum fails, and the column
# aggregates are asserted identical across the mutation so that the failure of
# a cheaper key is a measurement here rather than a claim.
# ============================================================================

@fpFixture
swapped = fpFixture.id
selectObject: swapped
Set numeric value: 1, "val", 30.125
Set numeric value: 4, "val", 10.5

@emlExtractColumn: control, "val"
ctrlVal# = emlExtractColumn.data#
@emlExtractColumn: swapped, "val"
swapVal# = emlExtractColumn.data#

@emlTestAssertEqualNum: "the column count is unchanged",
... size (ctrlVal#), size (swapVal#), 0
@emlTestAssertEqualNum: "the column sum is unchanged",
... sum (ctrlVal#), sum (swapVal#), 1e-12
@emlTestAssertEqualNum: "the column sum of squares is unchanged",
... sum (ctrlVal# * ctrlVal#), sum (swapVal# * swapVal#), 1e-9
@emlTestAssertEqualNum: "the column minimum is unchanged",
... min (ctrlVal#), min (swapVal#), 0
@emlTestAssertEqualNum: "the column maximum is unchanged",
... max (ctrlVal#), max (swapVal#), 0

@fpKey: swapped
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a cross-group swap invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Probe 2 — one data cell edited, row count constant"
# ============================================================================

@fpFixture
edited = fpFixture.id
selectObject: edited
Set numeric value: 5, "val", 21.6

@fpKey: edited
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a single-cell edit invalidates the key",
... emlFingerprintsAgree.same = 0

selectObject: edited
rowsNow = Get number of rows
@emlTestAssertEqualNum: "the edit did not change the row count", 9, rowsNow, 0


# ============================================================================
@emlTestSection: "Probe 3 — one group cell relabelled"
# ============================================================================

@fpFixture
moved = fpFixture.id
selectObject: moved
Set string value: 5, "grp", "C"
@fpKey: moved
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "moving one row to another level invalidates the key",
... emlFingerprintsAgree.same = 0

@fpFixture
labelSwap = fpFixture.id
selectObject: labelSwap
Set string value: 1, "grp", "B"
Set string value: 2, "grp", "A"
@fpKey: labelSwap
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "two labels exchanged between rows invalidates the key",
... emlFingerprintsAgree.same = 0

@fpFixture
renamed = fpFixture.id
selectObject: renamed
for r from 1 to 9
    lab$ = Get value: r, "grp"
    if lab$ = "A"
        Set string value: r, "grp", "Alpha"
    endif
endfor
@fpKey: renamed
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a whole level renamed invalidates the key",
... emlFingerprintsAgree.same = 0

@fpFixture
respelled = fpFixture.id
selectObject: respelled
Set string value: 1, "grp", "a"
@fpKey: respelled
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a case-only relabel invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Probe 4 — rows reordered WITHIN a level (INVERTED: moves)"
# ============================================================================
# THIS EXPECTATION IS THE OPPOSITE OF THE ONE THE FIRST THREE FORMATS CARRIED,
# AND THE INVERSION IS RULED, NOT ACCIDENTAL. See READ THIS BEFORE "FIXING"
# ANY EXPECTATION at the top of this file for Ian's ruling of 24 August 2026
# in his own words, and for the reason the old rationale was false: group
# order comes from discovery order under the shipped default, so a reorder
# CAN flip the sign of t, of Cohen's d and of every Tukey mean difference.
#
# A reorder now costs a re-run of the analysis. A re-run is always correct. A
# held key that should have moved is a figure quoting a number computed from
# other data, and the two are not comparable.
# ============================================================================

@fpFixture
reordered = fpFixture.id
selectObject: reordered
; the three A rows rotated among themselves; nothing else touched
Set numeric value: 1, "val", 11.75
Set numeric value: 3, "val", 12
Set numeric value: 6, "val", 10.5

@emlExtractColumn: reordered, "val"
reoVal# = emlExtractColumn.data#
@emlTestAssertEqualNum: "the reorder is a permutation: same sum",
... sum (ctrlVal#), sum (reoVal#), 1e-12
@emlTestAssertEqualNum: "and the same sum of squares",
... sum (ctrlVal# * ctrlVal#), sum (reoVal# * reoVal#), 1e-9

@fpKey: reordered
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a within-level reorder INVALIDATES the key (ruled 24 Aug)",
... emlFingerprintsAgree.same = 0

; The pair that cancels under any sum: two values exchanged inside one level.
@fpFixture
hostile1 = fpFixture.id
@fpFixture
hostile2 = fpFixture.id
selectObject: hostile2
Set numeric value: 1, "val", 12
Set numeric value: 6, "val", 10.5
@fpKey: hostile1
h1Key$ = fpKey.key$
@fpKey: hostile2
@emlFingerprintsAgree: h1Key$, fpKey.key$
@emlTestAssertTrue: "and so does a reorder of cancelling values",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "A whole-table row reorder (INVERTED: moves)"
# ============================================================================
# The same claim over the whole table at once: the rows are the same rows,
# presented in another order. Under eDF1 this had to HOLD; under the ruling
# quoted at the top of this file it moves, and the reason it must is in that
# same passage — a reorder of whole groups is a reorder of rows, and it flips
# the sign of every directional statistic the plugin prints.
# ============================================================================

shuffled = Create Table with column names: "fp_case", 9, { "grp", "val" }
shufG$# = { "C", "A", "B", "C", "A", "B", "C", "A", "B" }
shufV# = { 32.5, 12, 21.5, 30.125, 10.5, 22.75, 31.25, 11.75, 20.25 }
for i from 1 to 9
    Set string value: i, "grp", shufG$# [i]
    Set numeric value: i, "val", shufV# [i]
endfor
@fpKey: shuffled
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "the same rows in another order INVALIDATE the key",
... emlFingerprintsAgree.same = 0

; And the case the ruling is actually about: two whole groups exchanged in
; position, which is what a user's spreadsheet sort does.
blockSwap = Create Table with column names: "fp_case", 9, { "grp", "val" }
bsG$# = { "B", "B", "B", "A", "A", "A", "C", "C", "C" }
bsV# = { 20.25, 21.5, 22.75, 10.5, 11.75, 12, 30.125, 31.25, 32.5 }
for i from 1 to 9
    Set string value: i, "grp", bsG$# [i]
    Set numeric value: i, "val", bsV# [i]
endfor
@fpKey: blockSwap
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "two whole groups exchanged in position invalidate it too",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Rows added and removed"
# ============================================================================

@fpFixture
grown = fpFixture.id
selectObject: grown
Append row
Set string value: 10, "grp", "A"
Set numeric value: 10, "val", 13.25
@fpKey: grown
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a row added invalidates the key",
... emlFingerprintsAgree.same = 0

@fpFixture
shrunk = fpFixture.id
selectObject: shrunk
Remove row: 9
@fpKey: shrunk
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a row removed invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "The whole table is the key — including what nobody read"
# ============================================================================
# THIS IS THE DELIBERATE COST OF THE WHOLE-TABLE KEY, AND THE THING IT BUYS.
#
# The cost: a column no analysis reads is in the key, so correcting a typo in
# a notes column re-runs the analysis. The buy: UNDER-DECLARATION STOPS BEING
# EXPRESSIBLE. A key scoped to a declared column list cannot tell an unread
# column from an unnamed one — nothing in a Table records which columns an
# analysis touched — so such a key can describe less than the result rests on
# and hold while the data under that result is rewritten. That was Defeat 8,
# and it lived in the CALL, where no composition could reach it.
# ============================================================================

@fpFixture
withNotes = fpFixture.id
selectObject: withNotes
Append column: "notes"
for r from 1 to 9
    Set string value: r, "notes", "clean"
endfor
@fpKey: withNotes
notesKey$ = fpKey.key$
@emlFingerprintsAgree: controlKey$, notesKey$
@emlTestAssertTrue: "adding a column the analysis never reads invalidates the key",
... emlFingerprintsAgree.same = 0
@emlTestAssertEqualStr: "and the key says it covers that column too",
... "grp,val,notes", emlDataFingerprint.covers$

selectObject: withNotes
Set string value: 4, "notes", "recheck"
@fpKey: withNotes
@emlFingerprintsAgree: notesKey$, fpKey.key$
@emlTestAssertTrue: "one cell of that unread column invalidates it as well",
... emlFingerprintsAgree.same = 0

; A column RENAMED, with every cell untouched.
@fpFixture
colRenamed = fpFixture.id
selectObject: colRenamed
Set column label (index): 2, "value"
@fpKey: colRenamed
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "renaming a column invalidates the key",
... emlFingerprintsAgree.same = 0

; The COLUMN ORDER, with every cell and every name untouched.
colReordered = Create Table with column names: "fp_case", 9, { "val", "grp" }
selectObject: control
for r from 1 to 9
    selectObject: control
    g$ = Get value: r, "grp"
    v$ = Get value: r, "val"
    selectObject: colReordered
    Set string value: r, "grp", g$
    Set string value: r, "val", v$
endfor
@fpKey: colReordered
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "the same columns in another order invalidate the key",
... emlFingerprintsAgree.same = 0

; The TABLE'S NAME, with everything else untouched. This is the leg that
; catches a mutation fixture built under a different name.
@fpFixture
renamedTable = fpFixture.id
selectObject: renamedTable
Rename: "fp_case_other"
@fpKey: renamedTable
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "renaming the table invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Two columns with the same name are two columns"
# ============================================================================
# Praat's "Get value:" resolves a column by LABEL and returns the FIRST column
# carrying it, so a reader that addresses cells by name reads one of a
# duplicated pair twice and never reads the other — and an edit in the column
# it never reads moves no key. @emlDataFingerprint copies the table and
# renames its columns BY POSITION before reading a single cell, so every read
# is positional and no label needs resolving.
# ============================================================================

dupA = Create Table with column names: "fp_dup", 3, { "v", "w" }
for r from 1 to 3
    Set numeric value: r, "v", r
    Set numeric value: r, "w", 100 + r
endfor
Set column label (index): 2, "v"
l1$ = Get column label: 1
l2$ = Get column label: 2
@emlTestAssertEqualStr: "the fixture really does carry the label twice",
... l1$, l2$
probe$ = Get value: 2, "v"
@emlTestAssertEqualStr: "and Praat's own lookup reads only the first",
... "2", probe$
@fpKey: dupA
dupKey$ = fpKey.key$
@emlTestAssertEqualStr: "the key covers both columns under that one name",
... "v,v", emlDataFingerprint.covers$

; Edit the SECOND column of the pair — the one a name-based reader cannot see.
dupB = Create Table with column names: "fp_dup", 3, { "v", "w" }
for r from 1 to 3
    Set numeric value: r, "v", r
    Set numeric value: r, "w", 100 + r
endfor
Set numeric value: 2, "w", 999
Set column label (index): 2, "v"
@fpKey: dupB
@emlFingerprintsAgree: dupKey$, fpKey.key$
@emlTestAssertTrue: "an edit in the second of two identically named columns invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "A column really named num:v is a column named num:v"
# ============================================================================
# A declaration list that carried role prefixes had to strip "num:", "lab:"
# and "id:" from an item, so a table with a real column called "num:v" beside
# a real column called "v" resolved the first to the second and issued a
# bit-identical key for two different readings. NOTHING PARSES A NAME HERE:
# the key takes no column list, so there is no prefix to strip and no name to
# resolve. Both columns are in the key because every column is.
# ============================================================================

procedure fpColon: .variant
    .id = Create Table with column names: "fp_colon", 3, { "v", "z" }
    Set column label (index): 2, "num:v"
    for .r from 1 to 3
        Set numeric value: .r, "v", .r
        Set numeric value: .r, "num:v", 10 * .r
    endfor
    if .variant = 1
        Set numeric value: 2, "num:v", 25
    elsif .variant = 2
        Set numeric value: 2, "v", 7
    endif
endproc

@fpColon: 0
colonCtrl = fpColon.id
@fpKey: colonCtrl
colonKey$ = fpKey.key$
@emlTestAssertEqualStr: "both columns are covered, spelled as the table spells them",
... "v,num:v", emlDataFingerprint.covers$

@fpColon: 1
@fpKey: fpColon.id
@emlFingerprintsAgree: colonKey$, fpKey.key$
@emlTestAssertTrue: "an edit in the column named num:v invalidates the key",
... emlFingerprintsAgree.same = 0

@fpColon: 2
@fpKey: fpColon.id
@emlFingerprintsAgree: colonKey$, fpKey.key$
@emlTestAssertTrue: "and so does an edit in the column named v",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "The declared scope is in the key"
# ============================================================================
# The key carries two terms: the whole table's content, and the scope the
# caller declared. This section is about the second term. @emlGroupFingerprint
# folds the two column names it is handed; @emlAnalysisFingerprint folds the
# one list string it is handed; @emlDataFingerprint folds no scope at all and
# is the door for a caller that keys the table without naming an analysis.
#
# NOTHING PARSES THE DECLARATION. The scope is folded as the caller wrote it,
# in the order written, with each item's length folded after its characters.
# So every list defect closes by never arising rather than by repair: an empty
# item cannot be silently dropped, a role prefix cannot be stripped off a real
# column name, and a name that is not a column is not resolved and not
# refused — it is text, it folds, and only the same text matches it.
#
# THE ITEM COUNT IS FOLDED BEFORE THE ITEMS, which is what keeps the three
# doors apart on one table: no scope, one item and two items are three folds.
# ============================================================================

@emlGroupFingerprint: control, "val", "grp"
scopedKey$ = emlGroupFingerprint.result$
scopedScope$ = emlGroupFingerprint.scope$
scopedN = emlGroupFingerprint.nScope
scopedCovers$ = emlGroupFingerprint.covers$
@emlFingerprintsAgree: controlKey$, scopedKey$
@emlTestAssertTrue: "a scoped key is not the unscoped key",
... emlFingerprintsAgree.same = 0
@emlTestAssertEqualNum: "the two-column door declares two scope items",
... 2, scopedN, 0
@emlTestAssertContains: "and the key says so in the clear", scopedKey$, "|s=2"
@emlTestAssertContains: "under the new format tag", scopedKey$, "eTF2"
@emlTestAssertEqualStr: "it still covers every column of the table",
... "grp,val", scopedCovers$
@emlTestAssertEqualStr: "and reads its scope back for a human",
... "val ~ grp", scopedScope$

; The property the store rests on: same arguments, same key.
@emlGroupFingerprint: control, "val", "grp"
@emlFingerprintsAgree: scopedKey$, emlGroupFingerprint.result$
@emlTestAssertTrue: "two calls with the same arguments agree",
... emlFingerprintsAgree.same = 1

; Order is part of the declaration, so it is part of the key.
@emlGroupFingerprint: control, "grp", "val"
@emlFingerprintsAgree: scopedKey$, emlGroupFingerprint.result$
@emlTestAssertTrue: "the same two columns in the other order do not agree",
... emlFingerprintsAgree.same = 0

; A name that is not a column of the table is not resolved and not refused.
; It is its own scope: distinguishable from every other, equal to itself.
@emlGroupFingerprint: control, "no_such_column", "nor_this_one"
ghostScope$ = emlGroupFingerprint.result$
@emlTestAssertTrue: "naming columns that do not exist still yields a key",
... ghostScope$ <> ""
@emlTestAssertEqualStr: "with no error", "", emlGroupFingerprint.error$
@emlFingerprintsAgree: scopedKey$, ghostScope$
@emlTestAssertTrue: "and does not agree with the real declaration",
... emlFingerprintsAgree.same = 0
@emlFingerprintsAgree: controlKey$, ghostScope$
@emlTestAssertTrue: "nor with the unscoped key",
... emlFingerprintsAgree.same = 0
@emlGroupFingerprint: control, "no_such_column", "nor_this_one"
@emlFingerprintsAgree: ghostScope$, emlGroupFingerprint.result$
@emlTestAssertTrue: "a typo matches only the same typo",
... emlFingerprintsAgree.same = 1

; One real name and one that is not: still a scope of its own.
@emlGroupFingerprint: control, "val", "no_such_column"
@emlFingerprintsAgree: scopedKey$, emlGroupFingerprint.result$
@emlTestAssertTrue: "half a real declaration is not the real declaration",
... emlFingerprintsAgree.same = 0

; ---- the list door -------------------------------------------------------
@emlAnalysisFingerprint: control, "val,grp"
listKey$ = emlAnalysisFingerprint.result$
@emlTestAssertEqualNum: "the list door declares one scope item",
... 1, emlAnalysisFingerprint.nScope, 0
@emlTestAssertContains: "and says so in the clear", listKey$, "|s=1"
@emlTestAssertEqualStr: "reading the list back as written",
... "val,grp", emlAnalysisFingerprint.scope$
@emlFingerprintsAgree: controlKey$, listKey$
@emlTestAssertTrue: "a declared list is not the unscoped key",
... emlFingerprintsAgree.same = 0
@emlFingerprintsAgree: scopedKey$, listKey$
@emlTestAssertTrue: "and a list of two names is not a pair of two names",
... emlFingerprintsAgree.same = 0

@emlAnalysisFingerprint: control, "val,,grp"
@emlFingerprintsAgree: listKey$, emlAnalysisFingerprint.result$
@emlTestAssertTrue: "an empty item is not dropped, so it moves the key",
... emlFingerprintsAgree.same = 0

@emlAnalysisFingerprint: control, "grp,val"
@emlFingerprintsAgree: listKey$, emlAnalysisFingerprint.result$
@emlTestAssertTrue: "a list in the other order moves it too",
... emlFingerprintsAgree.same = 0

@emlAnalysisFingerprint: control, "num:val,lab:grp"
@emlFingerprintsAgree: listKey$, emlAnalysisFingerprint.result$
@emlTestAssertTrue: "no role prefix is stripped off a name",
... emlFingerprintsAgree.same = 0

@emlAnalysisFingerprint: control, "val,grp,num:age,id:subj,id:item"
@emlFingerprintsAgree: listKey$, emlAnalysisFingerprint.result$
@emlTestAssertTrue: "two identity columns are not refused; they are more text",
... emlFingerprintsAgree.same = 0

@emlAnalysisFingerprint: control, ""
emptyList$ = emlAnalysisFingerprint.result$
@emlTestAssertTrue: "an empty list is still a declaration and yields a key",
... emptyList$ <> ""
@emlFingerprintsAgree: controlKey$, emptyList$
@emlTestAssertTrue: "and declaring nothing is not the same as declaring no scope",
... emlFingerprintsAgree.same = 0

; ---- and the unscoped door is still served -------------------------------
@emlDataFingerprint: control
@emlTestAssertEqualNum: "the unscoped door declares no scope items",
... 0, emlDataFingerprint.nScope, 0
@emlTestAssertContains: "and says so in the clear",
... emlDataFingerprint.result$, "|s=0"
@emlTestAssertEqualStr: "with an empty scope to read back",
... "", emlDataFingerprint.scope$
@emlFingerprintsAgree: controlKey$, emlDataFingerprint.result$
@emlTestAssertTrue: "and it is stable across calls",
... emlFingerprintsAgree.same = 1


# ============================================================================
@emlTestSection: "Defeat 9 — two analyses of ONE unmodified table"
# ============================================================================
# THE FIXTURE IS NEVER TOUCHED. One table, four columns, two of which can be
# read as values and two of which can be read as factors. Three group
# comparisons over it disagree, and one of them crosses .05:
#
#   KW(val  ~ grp )   p = 0.670320
#   KW(val2 ~ grp )   p = 0.021128
#   KW(val2 ~ grp2)   p = 0.953497
#
# A key built from CONTENT ALONE is one key for all three, because the content
# is one content. A store keying on it serves the result of one comparison to
# a figure drawing another — p = 0.670 annotated on a comparison whose p is
# 0.021 — and its validity check reports the data unchanged, which is true and
# is not the question that was asked.
#
# The declared scope is what closes it, and the whole-table content is what
# keeps Defeat 8 closed at the same time. THE LAST TWO LEGS OF THIS SECTION
# ARE THE PAIR: two scopes on unchanged content do not agree, and unchanged
# scope on changed content does not agree either.
# ============================================================================

procedure fpTwoAnalyses
    .id = Create Table with column names: "fp_two_analyses", 9,
    ... { "grp", "grp2", "val", "val2" }
    .g$# = { "A", "B", "C", "A", "B", "C", "A", "B", "C" }
    .g2$# = { "P", "P", "P", "Q", "Q", "Q", "R", "R", "R" }
    .v# = { 1, 2, 3, 4, 5, 6, 7, 8, 9 }
    .v2# = { 1, 2, 30, 1, 2, 31, 1, 2, 32 }
    for .i from 1 to 9
        Set string value: .i, "grp", .g$# [.i]
        Set string value: .i, "grp2", .g2$# [.i]
        Set numeric value: .i, "val", .v# [.i]
        Set numeric value: .i, "val2", .v2# [.i]
    endfor
endproc

@fpTwoAnalyses
twoAn = fpTwoAnalyses.id

; The premise, measured: three comparisons of one table, three answers.
@emlKruskalWallis: twoAn, "val", "grp"
taP1 = emlKruskalWallis.p
@emlKruskalWallis: twoAn, "val2", "grp"
taP2 = emlKruskalWallis.p
@emlKruskalWallis: twoAn, "val2", "grp2"
taP3 = emlKruskalWallis.p
@emlTestAssertTrue: "KW(val ~ grp) is above .05", taP1 > 0.05
@emlTestAssertTrue: "KW(val2 ~ grp) is below .05", taP2 < 0.05
@emlTestAssertTrue: "so the two analyses fall on opposite sides of .05",
... taP1 > 0.05 and taP2 < 0.05
@emlTestAssertTrue: "and KW(val2 ~ grp2) is above .95", taP3 > 0.95

; And the table is the same table throughout: the content term cannot tell
; the three apart, which is why the content term is not the whole key.
@fpKey: twoAn
twoAnContent$ = fpKey.key$
@emlTestAssertTrue: "the content key is the same before and after all three",
... twoAnContent$ <> ""

; --- THE DEFECT LEG: two scopes, one unmodified table ---------------------
@emlGroupFingerprint: twoAn, "val", "grp"
taKey1$ = emlGroupFingerprint.result$
@emlGroupFingerprint: twoAn, "val2", "grp2"
taKey2$ = emlGroupFingerprint.result$
@emlFingerprintsAgree: taKey1$, taKey2$
@emlTestAssertTrue: "two analyses of one unmodified table get DIFFERENT keys",
... emlFingerprintsAgree.same = 0

@emlGroupFingerprint: twoAn, "val2", "grp"
@emlFingerprintsAgree: taKey1$, emlGroupFingerprint.result$
@emlTestAssertTrue: "changing only the value column changes the key",
... emlFingerprintsAgree.same = 0

@emlGroupFingerprint: twoAn, "val", "grp2"
@emlFingerprintsAgree: taKey1$, emlGroupFingerprint.result$
@emlTestAssertTrue: "changing only the grouping column changes the key",
... emlFingerprintsAgree.same = 0

; And the same declaration on the same table is still one key, or the store
; would never hit at all.
@emlGroupFingerprint: twoAn, "val", "grp"
@emlFingerprintsAgree: taKey1$, emlGroupFingerprint.result$
@emlTestAssertTrue: "while the same declaration agrees with itself",
... emlFingerprintsAgree.same = 1

; --- THE UNDECLARED-COLUMN LEG: Defeat 8 stays closed ---------------------
; The caller declares val and grp. The edit is in val2, which it never names,
; and which its own analysis never reads. The key moves anyway, because the
; content term is the whole table.
@fpTwoAnalyses
twoAnEdit = fpTwoAnalyses.id
selectObject: twoAnEdit
Set numeric value: 3, "val2", 30.5

@emlKruskalWallis: twoAnEdit, "val", "grp"
@emlTestAssertEqualNum: "the edit moves no number the declared analysis prints",
... taP1, emlKruskalWallis.p, 1e-12

@emlGroupFingerprint: twoAnEdit, "val", "grp"
@emlFingerprintsAgree: taKey1$, emlGroupFingerprint.result$
@emlTestAssertTrue: "an edit to a column NO caller named still invalidates the key",
... emlFingerprintsAgree.same = 0

; Every key on that table moves, not just the one whose door saw the edit.
@emlGroupFingerprint: twoAnEdit, "val2", "grp2"
@emlFingerprintsAgree: taKey2$, emlGroupFingerprint.result$
@emlTestAssertTrue: "and it invalidates the other analysis's key too",
... emlFingerprintsAgree.same = 0
@emlAnalysisFingerprint: twoAnEdit, "val,grp"
listBefore$ = emlAnalysisFingerprint.result$
@emlAnalysisFingerprint: twoAn, "val,grp"
@emlFingerprintsAgree: listBefore$, emlAnalysisFingerprint.result$
@emlTestAssertTrue: "the list door sees the undeclared edit as well",
... emlFingerprintsAgree.same = 0
@fpKey: twoAnEdit
@emlFingerprintsAgree: twoAnContent$, fpKey.key$
@emlTestAssertTrue: "and so does the unscoped key",
... emlFingerprintsAgree.same = 0




# ============================================================================
@emlTestSection: "How a number reaches the key (measured on this Praat)"
# ============================================================================
# EVERY CELL IS READ AS TEXT AND ENTERS THE KEY AS THAT TEXT. No number is
# formatted, rounded or quantised anywhere in the module, so there is no
# quantum to sit in the wrong place and no exponent to underflow.
#
# THAT IS ONLY SAFE IF THE TEXT IS A FAITHFUL NAME FOR THE DOUBLE, so the
# checks below measure it on the Praat actually running this suite rather
# than trusting a statement about Praat. Ian's ruling: "Agreed we don't round
# away machine precision."
# ============================================================================

numT = Create Table with column names: "fp_num", 1, { "v" }

; --- the text re-parses to the same double, over a random sweep ------------
lossy = 0
for i from 1 to 2000
    x = randomGauss (0, 1) * 10 ^ randomInteger (-30, 30)
    selectObject: numT
    Set numeric value: 1, "v", x
    s$ = Get value: 1, "v"
    if number (s$) <> x
        lossy = lossy + 1
    endif
endfor
@emlTestAssertEqualNum: "2000 random doubles all re-parse from their cell text",
... 0, lossy, 0

; --- Praat's own statistics read that same text ----------------------------
selectObject: numT
Set numeric value: 1, "v", 0.1 + 0.2
m = Get mean: "v"
s$ = Get value: 1, "v"
@emlTestAssertTrue: "a cell's text is what Praat's own statistic reads",
... m = number (s$)
@emlTestAssertEqualStr: "and 0.1 + 0.2 is stored as itself, not as 0.3",
... "0.30000000000000004", s$

; --- neighbouring doubles get different texts ------------------------------
same1 = 0
same225 = 0
for i from 1 to 500
    x = randomUniform (100, 1000)
    u = 2 ^ (floor (log2 (x)) - 52)
    selectObject: numT
    Set numeric value: 1, "v", x
    a$ = Get value: 1, "v"
    Set numeric value: 1, "v", x + u
    b$ = Get value: 1, "v"
    if a$ = b$
        same1 = same1 + 1
    endif
    Set numeric value: 1, "v", x + 2.25 * u
    c$ = Get value: 1, "v"
    if a$ = c$
        same225 = same225 + 1
    endif
endfor
@emlTestAssertEqualNum: "500 pairs one ulp apart get 500 different cell texts",
... 0, same1, 0
@emlTestAssertEqualNum: "and 500 pairs 2.25 ulps apart do too",
... 0, same225, 0

; --- the subnormal edge, where a formatted exponent would underflow --------
selectObject: numT
Set numeric value: 1, "v", 5e-324
sub1$ = Get value: 1, "v"
Set numeric value: 1, "v", 1e-323
sub2$ = Get value: 1, "v"
Set numeric value: 1, "v", 1.5e-323
sub3$ = Get value: 1, "v"
@emlTestAssertTrue: "three consecutive subnormals get three different texts",
... sub1$ <> sub2$ and sub2$ <> sub3$ and sub1$ <> sub3$
@emlTestAssertEqualNum: "the smallest subnormal survives its cell",
... 5e-324, number (sub1$), 0
@emlTestAssertTrue: "and none of them renders as undefined",
... sub1$ <> "--undefined--"

; --- and they move the key, which is the point -----------------------------
subA = Create Table with column names: "fp_sub", 1, { "v" }
Set numeric value: 1, "v", 5e-324
@fpKey: subA
subKey$ = fpKey.key$
subB = Create Table with column names: "fp_sub", 1, { "v" }
Set numeric value: 1, "v", 1e-323
@fpKey: subB
@emlFingerprintsAgree: subKey$, fpKey.key$
@emlTestAssertTrue: "two adjacent subnormals are two different keys",
... emlFingerprintsAgree.same = 0

; --- THE NON-FINITE CORNER IS ONE STATE, NOT THREE -------------------------
; A three-way ambiguity between +inf, -inf and undefined would need a Praat
; number that can BE an infinity. It cannot: every overflow route tests equal
; to `undefined` at the point of arithmetic, before any Table is involved. So
; the cell text "--undefined--" names one reachable state, the key sees that
; state as that text, and there is no pair of distinguishable cells sharing a
; key here.
overflowHi = 1e308 * 10
overflowLo = -1e308 * 10
overflowSum = 1e308 + 1e308
overflowExp = exp (1000)
@emlTestAssertTrue: "1e308 * 10 is already undefined as a NUMBER",
... overflowHi = undefined
@emlTestAssertTrue: "and so is -1e308 * 10", overflowLo = undefined
@emlTestAssertTrue: "and 1e308 + 1e308", overflowSum = undefined
@emlTestAssertTrue: "and exp (1000)", overflowExp = undefined
@emlTestAssertTrue: "no overflow result exceeds the largest finite double",
... not (overflowHi > 1e308)

selectObject: numT
Set numeric value: 1, "v", 1e308 * 10
posInf$ = Get value: 1, "v"
Set numeric value: 1, "v", -1e308 * 10
negInf$ = Get value: 1, "v"
Set numeric value: 1, "v", undefined
undef$ = Get value: 1, "v"
@emlTestAssertEqualStr: "so an overflowed cell holds the undefined text",
... "--undefined--", posInf$
@emlTestAssertEqualStr: "from either direction", posInf$, negInf$
@emlTestAssertEqualStr: "and it is the same state undefined reaches",
... posInf$, undef$
Set numeric value: 1, "v", 1e308
finiteMax$ = Get value: 1, "v"
@emlTestAssertEqualStr: "while the largest finite double keeps its own text",
... "1e+308", finiteMax$


# ============================================================================
@emlTestSection: "The mixing step (@eml_fpMix)"
# ============================================================================
# Defeat 7. The text-to-number step of every earlier format was a running
# polynomial, h = (h * B + c) mod M, one or two of them in parallel, each
# started from a salt. For two strings OF EQUAL LENGTH the DIFFERENCE of the
# resulting digests is then a fixed linear form in the character differences,
# whose coefficients depend only on position — and the salt contributes the
# same term to both strings, so it cancels. A difference pattern that collides
# once therefore collides always, under every salt, and lattice reduction
# finds one in under a second. Applied to the key's own numeric text it needed
# digit changes of at most 7, inside the digit alphabet: one cell moved from
# 8455843.16466246 to 144.315683422652 for a bit-identical key while ANOVA's p
# went .3559 to .00039.
#
# MORE PARALLEL POLYNOMIALS DO NOT HELP: each is one more linear constraint,
# and lattice reduction consumes them. The fix is to remove the fixed
# coefficients. @eml_fpMix draws every multiplier from the state itself and
# adds a quadratic term in the state each step, so there is no fixed linear
# form to solve for.
#
# The section below measures that difference, against a plain polynomial built
# here for the comparison.
# ============================================================================

; A plain polynomial, the shape of every earlier text step, for contrast only.
procedure fpPoly: .h, .s$
    for .i from 1 to length (.s$)
        .h = (.h * 1000003 + unicode (mid$ (.s$, .i, 1)) + 7) mod 2147483647
    endfor
endproc

procedure fpMixOf: .s$
    @eml_fpMix: 1948287391, 1103515245, 1571394749, .s$
    .h1 = eml_fpMix.h1
    .h2 = eml_fpMix.h2
    .h3 = eml_fpMix.h3
endproc

; --- it is a function, and it is not constant ------------------------------
@fpMixOf: "8455843.16466246"
mixA1 = fpMixOf.h1
mixA2 = fpMixOf.h2
mixA3 = fpMixOf.h3
@fpMixOf: "8455843.16466246"
@emlTestAssertEqualNum: "the same string mixes to the same first word",
... mixA1, fpMixOf.h1, 0
@emlTestAssertEqualNum: "the same second word", mixA2, fpMixOf.h2, 0
@emlTestAssertEqualNum: "the same third word", mixA3, fpMixOf.h3, 0
@fpMixOf: "144.315683422652"
@emlTestAssertTrue: "the pair that collided under the old step does not now",
... fpMixOf.h1 <> mixA1 or fpMixOf.h2 <> mixA2 or fpMixOf.h3 <> mixA3
@fpMixOf: ""
@emlTestAssertTrue: "the empty string does not mix to zero",
... fpMixOf.h1 <> 0 and fpMixOf.h2 <> 0 and fpMixOf.h3 <> 0

; --- a sequence of strings cannot be re-cut --------------------------------
@eml_fpMix: 1948287391, 1103515245, 1571394749, "ab"
@eml_fpMix: eml_fpMix.h1, eml_fpMix.h2, eml_fpMix.h3, "c"
cutA1 = eml_fpMix.h1
cutA2 = eml_fpMix.h2
cutA3 = eml_fpMix.h3
@eml_fpMix: 1948287391, 1103515245, 1571394749, "a"
@eml_fpMix: eml_fpMix.h1, eml_fpMix.h2, eml_fpMix.h3, "bc"
@emlTestAssertTrue: "ab then c does not mix like a then bc",
... eml_fpMix.h1 <> cutA1 or eml_fpMix.h2 <> cutA2 or eml_fpMix.h3 <> cutA3
@eml_fpMix: 1948287391, 1103515245, 1571394749, "abc"
@emlTestAssertTrue: "and neither does abc in one piece",
... eml_fpMix.h1 <> cutA1 or eml_fpMix.h2 <> cutA2 or eml_fpMix.h3 <> cutA3

; --- THE LINEARITY MEASUREMENT ---------------------------------------------
; One fixed difference pattern is applied to 40 random equal-length strings.
; Under a plain polynomial every one of the 40 digest differences is the SAME
; number; under @eml_fpMix they are 40 different triples. That is the whole of
# why lattice reduction no longer applies.
nBase = 40
polyDistinct = 0
mixDistinct = 0
for b from 1 to nBase
    ; Digits 0 to 7 only, so that "+2 in the digit alphabet" is a constant
    ; character delta of +2 and never wraps. A wrapping delta would be two
    ; different patterns wearing one name, and a plain polynomial would then
    ; give two differences rather than one — which is the measurement being
    ; made here, not an artefact to tolerate.
    s$ = ""
    for k from 1 to 10
        s$ = s$ + mid$ ("01234567", randomInteger (1, 8), 1)
    endfor
    t$ = left$ (s$, 2)
    ... + unicode$ (unicode (mid$ (s$, 3, 1)) + 2)
    ... + right$ (s$, 7)
    @fpPoly: 1, s$
    p1 = fpPoly.h
    @fpPoly: 1, t$
    polyDiff[b] = (fpPoly.h - p1) mod 2147483647
    @fpMixOf: s$
    m1 = fpMixOf.h1
    m2 = fpMixOf.h2
    m3 = fpMixOf.h3
    @fpMixOf: t$
    mixD1[b] = (fpMixOf.h1 - m1) mod 2147483647
    mixD2[b] = (fpMixOf.h2 - m2) mod 2147483629
    mixD3[b] = (fpMixOf.h3 - m3) mod 2147483587
endfor
for b from 1 to nBase
    pSeen = 0
    mSeen = 0
    for c from 1 to b - 1
        if polyDiff[c] = polyDiff[b]
            pSeen = 1
        endif
        if mixD1[c] = mixD1[b] and mixD2[c] = mixD2[b]
            if mixD3[c] = mixD3[b]
                mSeen = 1
            endif
        endif
    endfor
    if pSeen = 0
        polyDistinct = polyDistinct + 1
    endif
    if mSeen = 0
        mixDistinct = mixDistinct + 1
    endif
endfor
@emlTestAssertEqualNum: "a plain polynomial gives ONE difference for 40 bases",
... 1, polyDistinct, 0
@emlTestAssertEqualNum: "@eml_fpMix gives 40 different ones",
... nBase, mixDistinct, 0

; --- avalanche -------------------------------------------------------------
; One digit of a numeric cell text changed; count how many of the 93 state
; bits move. A mixing step worth having flips about half of them.
procedure fpBits: .a, .b
    .n = 0
    for .k from 0 to 30
        if (floor (.a / 2 ^ .k) mod 2) <> (floor (.b / 2 ^ .k) mod 2)
            .n = .n + 1
        endif
    endfor
endproc

avaSum = 0
avaN = 0
avaMin = 93
base$ = "8455843.16466246"
for pos from 1 to 16
    ch$ = mid$ (base$, pos, 1)
    if index ("0123456789", ch$) > 0
        for d from 0 to 9
            new$ = mid$ ("0123456789", d + 1, 1)
            if new$ <> ch$
                var$ = left$ (base$, pos - 1) + new$
                ... + right$ (base$, 16 - pos)
                @fpMixOf: base$
                bb1 = fpMixOf.h1
                bb2 = fpMixOf.h2
                bb3 = fpMixOf.h3
                @fpMixOf: var$
                @fpBits: bb1, fpMixOf.h1
                flip = fpBits.n
                @fpBits: bb2, fpMixOf.h2
                flip = flip + fpBits.n
                @fpBits: bb3, fpMixOf.h3
                flip = flip + fpBits.n
                avaSum = avaSum + flip
                avaN = avaN + 1
                if flip < avaMin
                    avaMin = flip
                endif
            endif
        endfor
    endif
endfor
avaMean = avaSum / avaN
@emlTestAssertTrue: "every single-digit change moves at least a quarter of the bits",
... avaMin > 23
@emlTestAssertTrue: "and on average about half of the 93",
... avaMean > 40 and avaMean < 53

; --- the exact-integer limit ----------------------------------------------
; Every intermediate in @eml_fpMix must stay inside the 2^53 a double holds
; exactly, or the arithmetic silently stops being the arithmetic written down.
; The bounds are asserted here as arithmetic rather than trusted as a comment.
@emlTestAssertTrue: "the largest product in the first word is inside 2^53",
... 2147483647 * (262147 + 131070) < 2 ^ 53
@emlTestAssertTrue: "and in the second", 2147483629 * (131101 + 65520) < 2 ^ 53
@emlTestAssertTrue: "and in the third", 2147483587 * (65537 + 32748) < 2 ^ 53
@emlTestAssertTrue: "the quadratic term is inside a 31-bit word",
... 46336 * 46336 < 2 ^ 31
@emlTestAssertTrue: "the cross term is inside 2^53", 1000002 * 4092 < 2 ^ 53
@emlTestAssertTrue: "every code point enters the first word injectively",
... 1114111 * 1031 < 2147483647
@emlTestAssertTrue: "the second", 1114111 * 1033 < 2147483629
@emlTestAssertTrue: "and the third", 1114111 * 1039 < 2147483587
@emlTestAssertEqualNum: "and Praat's arithmetic is exact at that magnitude",
... 1, 8449000000000000 + 1 - 8449000000000000, 0


# ============================================================================
@emlTestSection: "The step is not one-to-one"
# ============================================================================
# The shipped header states this; these legs measure it, because a claim in a
# comment that nothing asserts is exactly the defect this tree has spent the
# week removing — the axis check's header claimed a defence in depth that was
# never built, and it took a measurement to find out.
#
# HOLD h2 AND h3 FIXED and write h1 = 46337 * u + r, with r = h1 mod 46337
# and K = h2 mod 46337. The first word's update is then
#
#     h1' = (46337 * m1) * u + (m1 + K) * r + 1031 * c + 1   mod 2147483647
#
# — affine in the two coordinates (u, r) — and the second and third words
# reach h1 only through h1'. The character term 1031 * c is the same for
# every h1, so WHICH h1 differences merge depends on h2 and h3 alone and not
# on the character, and the length terminator has the same shape, so it
# merges them too.
#
# THE STATES BELOW share h2 = 1554331573 and h3 = 1375090233, under which the
# merging difference is 24928653. They merge under ANY string, the empty
# string included, and never separate again. They were found by inverting the
# step: h2 and h3 come back by one modular inverse each and h1 by a
# 46337-value scan of r, so the whole fibre over an output triple is
# enumerable in milliseconds, and the sets below are that enumeration.
#
# TWO WHOLE SETS ARE FOLDED, NOT A SAMPLE OF ONE. The set beginning at
# h1 = 510355490 holds 66 states and the set beginning at h1 = 45710 holds
# 71, and every member of each is folded here. The sizes are exact, not
# lower bounds: a progression ends where r = h1 mod 46337 would leave its
# range, so the state one step off the end is a legal h1 that does NOT
# merge, and both ends of both sets are checked — one end by the step
# leaving the modulus, the other by folding the neighbour and finding it
# apart. That is what makes 66 and 71 assertions rather than the largest
# number a search happened to reach.
#
# AND IT COSTS NOTHING, WHICH THE CONTROL LEGS MEASURE. Move h2 by one, or h3
# by one, or h1 one off the progression, and the merge is gone. Two states
# merge only by agreeing on h2 and h3 EXACTLY — 62 bits — while differing in
# h1 by one of about two amounts out of 2^31, which is about 2^-92 for a
# pair: no better than the birthday bound the digest already carries. The
# separation is carried by the multi-step nonlinearity measured above, not by
# any one step being one-to-one.
# ============================================================================

colH2 = 1554331573
colH3 = 1375090233
colA = 510355490
colB = 535284143
colC = 560212796

@emlTestAssertTrue: "the three collapsing states are three different states",
... colA <> colB and colB <> colC and colA <> colC
@emlTestAssertEqualNum: "their h1 values are an arithmetic progression",
... colB - colA, colC - colB, 0
@emlTestAssertEqualNum: "of step 24928653", 24928653, colB - colA, 0
@emlTestAssertTrue: "and all three are inside the first word's modulus",
... colA > 0 and colC < 2147483647

; --- they fold to one triple, in the shipped procedure ----------------------
@eml_fpMix: colA, colH2, colH3, "A"
colA1 = eml_fpMix.h1
colA2 = eml_fpMix.h2
colA3 = eml_fpMix.h3
@eml_fpMix: colB, colH2, colH3, "A"
colB1 = eml_fpMix.h1
colB2 = eml_fpMix.h2
colB3 = eml_fpMix.h3
@eml_fpMix: colC, colH2, colH3, "A"
colC1 = eml_fpMix.h1
colC2 = eml_fpMix.h2
colC3 = eml_fpMix.h3

@emlTestAssertEqualNum: "the first two agree in the first word", colA1, colB1, 0
@emlTestAssertEqualNum: "and in the second", colA2, colB2, 0
@emlTestAssertEqualNum: "and in the third", colA3, colB3, 0
@emlTestAssertEqualNum: "the third state joins them in the first word",
... colA1, colC1, 0
@emlTestAssertEqualNum: "and in the second", colA2, colC2, 0
@emlTestAssertEqualNum: "and in the third", colA3, colC3, 0

; --- and under any string, not just under "A" -------------------------------
nColStr = 6
colStr$[1] = ""
colStr$[2] = "A"
colStr$[3] = "zz"
colStr$[4] = "0.1"
colStr$[5] = "level3"
colStr$[6] = "12345678901234567"
colMerged = 0
for cs from 1 to nColStr
    @eml_fpMix: colA, colH2, colH3, colStr$[cs]
    colX1 = eml_fpMix.h1
    colX2 = eml_fpMix.h2
    colX3 = eml_fpMix.h3
    @eml_fpMix: colB, colH2, colH3, colStr$[cs]
    if eml_fpMix.h1 = colX1 and eml_fpMix.h2 = colX2
        if eml_fpMix.h3 = colX3
            colMerged = colMerged + 1
        endif
    endif
endfor
@emlTestAssertEqualNum: "the pair merges under all six strings, the empty one included",
... nColStr, colMerged, 0

; --- merged once is merged for good -----------------------------------------
@eml_fpMix: colA, colH2, colH3, "A"
@eml_fpMix: eml_fpMix.h1, eml_fpMix.h2, eml_fpMix.h3, "and then some more text"
colDeep1 = eml_fpMix.h1
colDeep2 = eml_fpMix.h2
colDeep3 = eml_fpMix.h3
@eml_fpMix: colB, colH2, colH3, "A"
@eml_fpMix: eml_fpMix.h1, eml_fpMix.h2, eml_fpMix.h3, "and then some more text"
@emlTestAssertTrue: "a second fold does not separate them again",
... eml_fpMix.h1 = colDeep1 and eml_fpMix.h2 = colDeep2
... and eml_fpMix.h3 = colDeep3

; --- and it costs nothing, because the merge is that brittle ----------------
@eml_fpMix: colA + 1, colH2, colH3, "A"
colOff1 = eml_fpMix.h1
colOff2 = eml_fpMix.h2
colOff3 = eml_fpMix.h3
@emlTestAssertTrue: "an h1 one off the progression does not merge",
... colOff1 <> colA1 or colOff2 <> colA2 or colOff3 <> colA3

@eml_fpMix: colA, colH2 + 1, colH3, "A"
colH2a1 = eml_fpMix.h1
colH2a2 = eml_fpMix.h2
colH2a3 = eml_fpMix.h3
@eml_fpMix: colB, colH2 + 1, colH3, "A"
@emlTestAssertTrue: "h2 one out and the merge is gone",
... eml_fpMix.h1 <> colH2a1 or eml_fpMix.h2 <> colH2a2
... or eml_fpMix.h3 <> colH2a3

@eml_fpMix: colA, colH2, colH3 + 1, "A"
colH3a1 = eml_fpMix.h1
colH3a2 = eml_fpMix.h2
colH3a3 = eml_fpMix.h3
@eml_fpMix: colB, colH2, colH3 + 1, "A"
@emlTestAssertTrue: "h3 one out and the merge is gone",
... eml_fpMix.h1 <> colH3a1 or eml_fpMix.h2 <> colH3a2
... or eml_fpMix.h3 <> colH3a3

; --- the affine form the header writes down is the shipped expression -------
; h1' = (46337 * m1) * u + (m1 + K) * r + 1031 * c + 1, evaluated against the
; shipped step for 240 state-and-character combinations. Every intermediate
; here is kept inside 2^53 the same way the shipped one is: the affine terms
; are reduced modulo 2147483647 before they are added.
affineOk = 0
affineN = 0
for ai from 1 to 240
    aH1 = randomInteger (0, 2147483646)
    aH2 = randomInteger (0, 2147483628)
    aH3 = randomInteger (0, 2147483586)
    aC = randomInteger (32, 1114111)
    aM1 = 262147 + (aH3 mod 131071)
    aK = aH2 mod 46337
    aU = floor (aH1 / 46337)
    aR = aH1 mod 46337
    aShipped = (aH1 * aM1 + (aH1 mod 46337) * (aH2 mod 46337) + aC * 1031 + 1)
    ... mod 2147483647
    aAffine = (((46337 * aM1) mod 2147483647) * aU) mod 2147483647
    aAffine = (aAffine + ((aM1 + aK) mod 2147483647) * aR) mod 2147483647
    aAffine = (aAffine + aC * 1031 + 1) mod 2147483647
    affineN = affineN + 1
    if aAffine = aShipped
        affineOk = affineOk + 1
    endif
endfor
@emlTestAssertEqualNum: "the affine form matches the shipped first-word update, 240 times",
... affineN, affineOk, 0


; --- the whole set, member by member, and its size is exact -----------------
; The set beginning at colA. Every member is generated from the first by
; repeated addition of the step, so the progression itself is asserted and
; not transcribed.
colStep = 24928653
colSetA = 510355490
colSetAn = 66
@eml_fpMix: colSetA, colH2, colH3, "A"
colSetA1 = eml_fpMix.h1
colSetA2 = eml_fpMix.h2
colSetA3 = eml_fpMix.h3
colSetAmerged = 0
colSetAlast = colSetA
for cm from 1 to colSetAn
    colState = colSetA + (cm - 1) * colStep
    colSetAlast = colState
    @eml_fpMix: colState, colH2, colH3, "A"
    if eml_fpMix.h1 = colSetA1 and eml_fpMix.h2 = colSetA2
        if eml_fpMix.h3 = colSetA3
            colSetAmerged = colSetAmerged + 1
        endif
    endif
endfor
@emlTestAssertEqualNum: "all 66 members of the first set fold to one triple",
... colSetAn, colSetAmerged, 0
@emlTestAssertTrue: "and all 66 are legal first words",
... colSetA > 0 and colSetAlast < 2147483647
@emlTestAssertTrue: "the set ends where the next step leaves the modulus",
... colSetAlast + colStep > 2147483646

; The other end is a legal h1, and it does not merge. Without this leg 66 is
; a lower bound; with it, 66 is the size.
@eml_fpMix: colSetA - colStep, colH2, colH3, "A"
@emlTestAssertTrue: "and the legal state one step below the set does not join it",
... eml_fpMix.h1 <> colSetA1 or eml_fpMix.h2 <> colSetA2
... or eml_fpMix.h3 <> colSetA3

; The set beginning at colSetB, which is longer and runs the other way: its
; lower end falls off the bottom of the modulus and its upper neighbour is a
; legal h1 that stays apart.
colSetB = 45710
colSetBn = 71
@eml_fpMix: colSetB, colH2, colH3, "A"
colSetB1 = eml_fpMix.h1
colSetB2 = eml_fpMix.h2
colSetB3 = eml_fpMix.h3
colSetBmerged = 0
colSetBlast = colSetB
for cm from 1 to colSetBn
    colState = colSetB + (cm - 1) * colStep
    colSetBlast = colState
    @eml_fpMix: colState, colH2, colH3, "A"
    if eml_fpMix.h1 = colSetB1 and eml_fpMix.h2 = colSetB2
        if eml_fpMix.h3 = colSetB3
            colSetBmerged = colSetBmerged + 1
        endif
    endif
endfor
@emlTestAssertEqualNum: "all 71 members of the second set fold to one triple",
... colSetBn, colSetBmerged, 0
@emlTestAssertTrue: "and all 71 are legal first words",
... colSetB >= 0 and colSetBlast < 2147483647
@emlTestAssertTrue: "the set starts where the step before it goes negative",
... colSetB - colStep < 0

@eml_fpMix: colSetBlast + colStep, colH2, colH3, "A"
@emlTestAssertTrue: "and the legal state one step above the set does not join it",
... eml_fpMix.h1 <> colSetB1 or eml_fpMix.h2 <> colSetB2
... or eml_fpMix.h3 <> colSetB3
@emlTestAssertTrue: "which is a legal first word",
... colSetBlast + colStep < 2147483647

; The two sets are different sets: they share h2, h3 and the step, and land
; on different triples.
@emlTestAssertTrue: "the two sets fold to two different triples",
... colSetA1 <> colSetB1 or colSetA2 <> colSetB2 or colSetA3 <> colSetB3

; And the three states the section opens with are members of the first set.
@emlTestAssertTrue: "the three states above are members of the first set",
... colA = colSetA and colB = colSetA + colStep
... and colC = colSetA + 2 * colStep


# ============================================================================
@emlTestSection: "The length terminator sees length mod 1000003"
# ============================================================================
# Every length term in @eml_fpMix's terminator is written (.n mod 1000003),
# so two pieces whose lengths differ by exactly 1000003 terminate identically.
#
# THERE IS NO END-TO-END DEMONSTRATION OF THIS, AND THAT IS THE POINT. Two
# real strings whose lengths differ by 1000003 differ by a million CHARACTER
# steps as well, so their digests part company for a reason that has nothing
# to do with the terminator. The property belongs to the terminator alone and
# has to be measured on the terminator alone, which means handing it a length
# the string does not have — and @eml_fpMix takes its length from the string.
#
# SO THE TERMINATOR IS REPRODUCED HERE, in @fpMixN, whose length comes from a
# parameter. THE COPY IS TIED TO THE SHIPPED PROCEDURE BY THE FIRST GROUP OF
# LEGS: called with the string's own length it must agree with @eml_fpMix
# word for word, over eight strings and three starting states. Change the
# shipped arithmetic and those legs go red, which is the instruction to
# update this copy — after which the congruence legs measure the arithmetic
# that is actually shipped and not the arithmetic that once was.
#
# WHAT THE CONGRUENCE BUYS AND WHAT IT DOES NOT is in the shipped header. In
# one line: a cell, a column label, a table name and a scope item are all far
# shorter than 1000003 characters, so inside that range the length term IS
# the length and the re-cut guarantee holds; total length is carried exactly
# and separately by the key's n= field, which is not reduced by anything.
# ============================================================================

procedure fpMixN: .h1, .h2, .h3, .s$, .nOverride
    for .i from 1 to length (.s$)
        .c = unicode (mid$ (.s$, .i, 1))
        .q = (.h1 mod 46337) * (.h2 mod 46337)
        .m1 = 262147 + (.h3 mod 131071)
        .h1 = (.h1 * .m1 + .q + .c * 1031 + 1) mod 2147483647
        .m2 = 131101 + (.h1 mod 65521)
        .h2 = (.h2 * .m2 + (.h1 mod 1000003) + .c * 1033 + 3) mod 2147483629
        .m3 = 65537 + (.h2 mod 32749)
        .h3 = (.h3 * .m3 + (.h2 mod 1000003) * (.h1 mod 4093) + .c * 1039 + 5)
        ... mod 2147483587
    endfor

    .q = (.h1 mod 46337) * (.h2 mod 46337)
    .m1 = 262147 + (.h3 mod 131071)
    .h1 = (.h1 * .m1 + .q + (.nOverride mod 1000003) * 1031 + 7) mod 2147483647

    .m2 = 131101 + (.h1 mod 65521)
    .h2 = (.h2 * .m2 + (.h1 mod 1000003) + (.nOverride mod 1000003) * 1033 + 11)
    ... mod 2147483629

    .m3 = 65537 + (.h2 mod 32749)
    .h3 = (.h3 * .m3 + (.h2 mod 1000003) * (.h1 mod 4093)
    ... + (.nOverride mod 1000003) * 1039 + 13) mod 2147483587
endproc

; How many times one string occurs inside another. Used to hold a constant
; that appears in this file and in the shipped one to a single value.
procedure fpCount: .haystack$, .needle$
    .n = 0
    .at = index (.haystack$, .needle$)
    while .at > 0
        .n = .n + 1
        .haystack$ = right$ (.haystack$, length (.haystack$) - .at
        ... - length (.needle$) + 1)
        .at = index (.haystack$, .needle$)
    endwhile
endproc

; --- the copy is the shipped arithmetic -------------------------------------
nTermStr = 8
termStr$[1] = ""
termStr$[2] = "A"
termStr$[3] = "eTF2"
termStr$[4] = "0.30000000000000004"
termStr$[5] = "--undefined--"
termStr$[6] = "a|b~c,d"
termStr$[7] = "The quick brown fox jumps over the lazy dog"
termStr$[8] = "level3"
nTermState = 3
termS1[1] = 1948287391
termS2[1] = 1103515245
termS3[1] = 1571394749
termS1[2] = 7
termS2[2] = 11
termS3[2] = 13
termS1[3] = 2147483646
termS2[3] = 2147483628
termS3[3] = 2147483586

termAgree = 0
termTried = 0
for ts from 1 to nTermState
    for tk from 1 to nTermStr
        @eml_fpMix: termS1[ts], termS2[ts], termS3[ts], termStr$[tk]
        termRef1 = eml_fpMix.h1
        termRef2 = eml_fpMix.h2
        termRef3 = eml_fpMix.h3
        @fpMixN: termS1[ts], termS2[ts], termS3[ts], termStr$[tk],
        ... length (termStr$[tk])
        termTried = termTried + 1
        if fpMixN.h1 = termRef1 and fpMixN.h2 = termRef2
            if fpMixN.h3 = termRef3
                termAgree = termAgree + 1
            endif
        endif
    endfor
endfor
@emlTestAssertEqualNum: "the local copy is @eml_fpMix, over 24 string-and-state pairs",
... termTried, termAgree, 0
@emlTestAssertEqualNum: "and 24 pairs were actually tried", 24, termTried, 0

; --- the congruence ----------------------------------------------------------
nTermLen = 6
termLen[1] = 0
termLen[2] = 1
termLen[3] = 5
termLen[4] = 17
termLen[5] = 1000002
termLen[6] = 999999
termCongruent = 0
termSeparated = 0
for tl from 1 to nTermLen
    @fpMixN: 123456789, 987654321, 555555555, "cell", termLen[tl]
    termC1 = fpMixN.h1
    termC2 = fpMixN.h2
    termC3 = fpMixN.h3
    @fpMixN: 123456789, 987654321, 555555555, "cell", termLen[tl] + 1000003
    if fpMixN.h1 = termC1 and fpMixN.h2 = termC2
        if fpMixN.h3 = termC3
            termCongruent = termCongruent + 1
        endif
    endif
    @fpMixN: 123456789, 987654321, 555555555, "cell", termLen[tl] + 1
    if fpMixN.h1 <> termC1 or fpMixN.h2 <> termC2 or fpMixN.h3 <> termC3
        termSeparated = termSeparated + 1
    endif
endfor
@emlTestAssertEqualNum: "a length and that length plus 1000003 terminate identically",
... nTermLen, termCongruent, 0
@emlTestAssertEqualNum: "while a length and that length plus one do not",
... nTermLen, termSeparated, 0

; Twice the modulus lands in the same place, so it is the modulus and not one
; coincidence at 1000003.
@fpMixN: 123456789, 987654321, 555555555, "cell", 5
term2a1 = fpMixN.h1
term2a2 = fpMixN.h2
term2a3 = fpMixN.h3
@fpMixN: 123456789, 987654321, 555555555, "cell", 5 + 2 * 1000003
@emlTestAssertTrue: "and so does that length plus twice 1000003",
... fpMixN.h1 = term2a1 and fpMixN.h2 = term2a2 and fpMixN.h3 = term2a3

; The range the module actually meets is separated exactly: no two lengths a
; cell, a label, a name or a scope item can carry are congruent without being
; equal, because 1000003 is larger than any of them.
@emlTestAssertTrue: "and every length this module can meet is under the modulus",
... 1000003 > 1000000

; --- and the copy's modulus is the SHIPPED modulus ---------------------------
; The behavioural legs above cannot see this one. Every string this suite can
; afford to fold is far shorter than 1000003 characters, and below that a
; length reduced modulo 1000003 and a length reduced modulo any other large
; number are the same length — so the shipped constant could be changed and
; every leg above would still pass. Confirmed by mutation: replacing the
; shipped 1000003 with 999983 leaves all of them green.
;
; A LONG ENOUGH STRING WOULD CLOSE IT AND IS NOT AFFORDABLE. Building and
; folding a 1000003-character string in Praat runs past ten minutes, against
; a suite that finishes in under three seconds.
;
; SO THE CONSTANT IS CHECKED AS TEXT, which is this repo's standing answer to
; a canon that has to exist in two places (v105 is the model). Two assertions,
; because they fail in different ways: the equality catches a code constant
; edited away from the comment beside it, and the three exact expressions
; catch a code constant and its comment edited together.
fpSrc$ = readFile$ ("../../../stats/eml-extract.praat")
@emlTestAssertTrue: "the shipped source was read", length (fpSrc$) > 100000
@emlTestAssertTrue: "and it is the file that defines @eml_fpMix",
... index (fpSrc$, "procedure eml_fpMix:") > 0

@fpCount: fpSrc$, "(.n mod "
termAny = fpCount.n
@fpCount: fpSrc$, "(.n mod 1000003)"
termThis = fpCount.n
@emlTestAssertTrue: "the shipped file reduces a folded length somewhere",
... termAny >= 3
@emlTestAssertEqualNum: "and every place it does reduces modulo 1000003",
... termAny, termThis, 0
@emlTestAssertTrue: "the first word's length term is the one measured here",
... index (fpSrc$, "(.n mod 1000003) * 1031 + 7") > 0
@emlTestAssertTrue: "and the second word's",
... index (fpSrc$, "(.n mod 1000003) * 1033 + 11") > 0
@emlTestAssertTrue: "and the third word's",
... index (fpSrc$, "(.n mod 1000003) * 1039 + 13") > 0



# ============================================================================
@emlTestSection: "Defeat 1 — a compensating interior edit"
# ============================================================================
# Three cells inside ONE level are rewritten, all strictly between that
# level's min and max, chosen so that n, sum, sum of squares, min and max are
# all held EXACTLY. Those five numbers were the whole of eGF1's description of
# a level, so its key was byte-identical across this edit — while
# Kruskal-Wallis p moved .0437 -> .1013 across .05, Dunn's adjusted p moved
# .0400 -> .1209, the level's median moved 600 -> 490 and its skewness
# flipped sign.
#
# THIS IS STRUCTURAL, NOT A COLLISION. Five fixed aggregates constrain four
# numbers on n - 2 interior values, so for n >= 5 a CONTINUUM of alternative
# level contents satisfies them; levels of n <= 4 are provably safe and no
# others are. Adding a sixth moment moves the threshold and closes nothing.
# Committing to the cells closes all of it at once.
# ============================================================================

procedure fpLevel: .id, .lab$
    @eml_getGroupData: .id, "val", "grp", .lab$
    .v# = sort# (eml_getGroupData.data#)
    .n = size (.v#)
    .sum = sum (.v#)
    .sq = sum (.v# * .v#)
    .lo = .v# [1]
    .hi = .v# [.n]
    @emlMedian: .v#
    .median = emlMedian.result
endproc

procedure fpMoment: .variant
    .id = Create Table with column names: "fp_moment", 15, { "grp", "val" }
    .a# = { 340, 350, 600, 610, 690 }
    if .variant = 1
        .a# = { 340, 390, 490, 680, 690 }
    endif
    .b# = { 430, 620, 630, 650, 670 }
    .c# = { 300, 310, 320, 520, 550 }
    for .i from 1 to 5
        Set string value: .i, "grp", "aa"
        Set numeric value: .i, "val", .a# [.i]
        Set string value: 5 + .i, "grp", "bb"
        Set numeric value: 5 + .i, "val", .b# [.i]
        Set string value: 10 + .i, "grp", "cc"
        Set numeric value: 10 + .i, "val", .c# [.i]
    endfor
endproc

@fpMoment: 0
momentCtrl = fpMoment.id
@fpKey: momentCtrl
momentCtrlKey$ = fpKey.key$
@fpLevel: momentCtrl, "aa"
mcN = fpLevel.n
mcSum = fpLevel.sum
mcSq = fpLevel.sq
mcLo = fpLevel.lo
mcHi = fpLevel.hi
mcMed = fpLevel.median
@emlKruskalWallis: momentCtrl, "val", "grp"
mcP = emlKruskalWallis.p

@fpMoment: 1
momentMut = fpMoment.id
@fpLevel: momentMut, "aa"
mmMed = fpLevel.median
@emlKruskalWallis: momentMut, "val", "grp"
mmP = emlKruskalWallis.p

; Every number eGF1 recorded about this level is unchanged. Asserted, so the
; blindness of that composition is measured here rather than claimed.
@emlTestAssertEqualNum: "the level's n is unchanged", mcN, fpLevel.n, 0
@emlTestAssertEqualNum: "the level's sum is unchanged", mcSum, fpLevel.sum, 0
@emlTestAssertEqualNum: "the level's sum of squares is unchanged",
... mcSq, fpLevel.sq, 0
@emlTestAssertEqualNum: "the level's minimum is unchanged", mcLo, fpLevel.lo, 0
@emlTestAssertEqualNum: "the level's maximum is unchanged", mcHi, fpLevel.hi, 0

; And the result the store would have reused is not the same result.
@emlTestAssertEqualNum: "the control level's median is 600", 600, mcMed, 0
@emlTestAssertEqualNum: "the edited level's median is 490", 490, mmMed, 0
@emlTestAssertTrue: "Kruskal-Wallis p is below .05 before the edit", mcP < 0.05
@emlTestAssertTrue: "and above .05 after it", mmP > 0.05

@fpKey: momentMut
@emlFingerprintsAgree: momentCtrlKey$, fpKey.key$
@emlTestAssertTrue: "a compensating interior edit invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Defeat 1b — the same trick on one-decimal measurement data"
# ============================================================================
# The moment manifold is not an artefact of round numbers. Three cells of one
# level of eight one-decimal F1 values are rewritten inside the level's range;
# the five aggregates survive to within the width of the data, and eGF1's key
# was byte-identical.
# ============================================================================

procedure fpFormant: .variant
    .id = Create Table with column names: "fp_formant", 24, { "grp", "val" }
    .a# = { 512.3, 528.7, 544.1, 559.8, 571.2, 588.6, 601.4, 619.9 }
    if .variant = 1
        .a# = { 512.3, 528.7, 548.1, 553.2, 573.8, 588.6, 601.4, 619.9 }
    endif
    .b# = { 505.6, 533.4, 546.9, 551.7, 557.3, 566.2, 578.9, 594.5 }
    .c# = { 520.1, 536.8, 549.4, 555.5, 561.9, 570.3, 583.7, 611.2 }
    for .i from 1 to 8
        Set string value: .i, "grp", "voiced"
        Set numeric value: .i, "val", .a# [.i]
        Set string value: 8 + .i, "grp", "voiceless"
        Set numeric value: 8 + .i, "val", .b# [.i]
        Set string value: 16 + .i, "grp", "whispered"
        Set numeric value: 16 + .i, "val", .c# [.i]
    endfor
endproc

@fpFormant: 0
formantCtrl = fpFormant.id
@fpKey: formantCtrl
formantCtrlKey$ = fpKey.key$
@fpLevel: formantCtrl, "voiced"
fcSum = fpLevel.sum
fcLo = fpLevel.lo
fcHi = fpLevel.hi

@fpFormant: 1
formantMut = fpFormant.id
@fpLevel: formantMut, "voiced"
@emlTestAssertEqualNum: "the formant level's sum is unchanged",
... fcSum, fpLevel.sum, 1e-9
@emlTestAssertEqualNum: "the formant level's range is unchanged",
... fcHi - fcLo, fpLevel.hi - fpLevel.lo, 1e-9
@fpKey: formantMut
@emlFingerprintsAgree: formantCtrlKey$, fpKey.key$
@emlTestAssertTrue: "the same trick on one-decimal data invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Defeat 2 — a whole-level LABEL SWAP"
# ============================================================================
# Two levels are built aggregate-matched — equal n, sum, sum of squares, min
# and max, different contents — and then their labels are exchanged. Ten of
# fifteen group cells are rewritten and the two level records simply trade
# places in the canonical sort, so eGF1's key held while Dunn's z values
# swapped between the levels.
#
# It is the same fault as Defeat 1 seen from outside: two levels can only be
# interchangeable to a key that cannot tell their contents apart.
# ============================================================================

procedure fpSwapLevels: .swap
    .id = Create Table with column names: "fp_swaplevels", 15, { "grp", "val" }
    .aa$ = "aa"
    .bb$ = "bb"
    if .swap = 1
        .aa$ = "bb"
        .bb$ = "aa"
    endif
    .v1# = { 340, 350, 600, 610, 690 }
    .v2# = { 340, 390, 490, 680, 690 }
    .v3# = { 430, 620, 630, 650, 670 }
    for .i from 1 to 5
        Set string value: .i, "grp", .aa$
        Set numeric value: .i, "val", .v1# [.i]
        Set string value: 5 + .i, "grp", .bb$
        Set numeric value: 5 + .i, "val", .v2# [.i]
        Set string value: 10 + .i, "grp", "cc"
        Set numeric value: 10 + .i, "val", .v3# [.i]
    endfor
endproc

@fpSwapLevels: 0
swapLevelCtrl = fpSwapLevels.id
@fpKey: swapLevelCtrl
swapLevelKey$ = fpKey.key$

; The two levels really are aggregate-matched — that is the premise, and it is
; asserted rather than asserted-in-a-comment.
@fpLevel: swapLevelCtrl, "aa"
saN = fpLevel.n
saSum = fpLevel.sum
saSq = fpLevel.sq
saLo = fpLevel.lo
saHi = fpLevel.hi
@fpLevel: swapLevelCtrl, "bb"
@emlTestAssertEqualNum: "the two levels have the same n", saN, fpLevel.n, 0
@emlTestAssertEqualNum: "the same sum", saSum, fpLevel.sum, 0
@emlTestAssertEqualNum: "the same sum of squares", saSq, fpLevel.sq, 0
@emlTestAssertEqualNum: "the same minimum", saLo, fpLevel.lo, 0
@emlTestAssertEqualNum: "the same maximum", saHi, fpLevel.hi, 0
@emlTestAssertTrue: "and different contents", saSum <> 0

@fpSwapLevels: 1
swapLevelMut = fpSwapLevels.id
@fpKey: swapLevelMut
@emlFingerprintsAgree: swapLevelKey$, fpKey.key$
@emlTestAssertTrue: "exchanging two whole levels' labels invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Defeat 3 — a label hash collision"
# ============================================================================
# eGF1's label hash was a single unsalted degree-L polynomial modulo 2^31 - 1.
# A four-million-sample birthday search found "y409n_" and "5kxgwq" in
# seconds; both hashed to 6_2026794253, so a whole level could be renamed with
# the key unmoved and a reused result would print level names that are not in
# the table.
#
# The published pair is kept as a fixture because a pair that once defeated a
# key is the only kind of evidence that a later key is not differently blind.
# ============================================================================

@fpMixOf: "y409n_"
colA1 = fpMixOf.h1
colA2 = fpMixOf.h2
colA3 = fpMixOf.h3
@fpMixOf: "5kxgwq"
@emlTestAssertTrue: "the published collision pair does not collide here",
... fpMixOf.h1 <> colA1 or fpMixOf.h2 <> colA2 or fpMixOf.h3 <> colA3
@emlTestAssertTrue: "and not in the first word", fpMixOf.h1 <> colA1
@emlTestAssertTrue: "nor in the second", fpMixOf.h2 <> colA2
@emlTestAssertTrue: "nor in the third", fpMixOf.h3 <> colA3

procedure fpCollide: .rename
    .id = Create Table with column names: "fp_collide", 15, { "grp", "val" }
    .g3$ = "y409n_"
    if .rename = 1
        .g3$ = "5kxgwq"
    endif
    .v1# = { 340, 350, 600, 610, 690 }
    .v2# = { 430, 620, 630, 650, 670 }
    .v3# = { 300, 310, 320, 520, 550 }
    for .i from 1 to 5
        Set string value: .i, "grp", "0aa"
        Set numeric value: .i, "val", .v1# [.i]
        Set string value: 5 + .i, "grp", "1bb"
        Set numeric value: 5 + .i, "val", .v2# [.i]
        Set string value: 10 + .i, "grp", .g3$
        Set numeric value: 10 + .i, "val", .v3# [.i]
    endfor
endproc

@fpCollide: 0
collideCtrl = fpCollide.id
@fpKey: collideCtrl
collideKey$ = fpKey.key$
@fpCollide: 1
collideMut = fpCollide.id
@fpKey: collideMut
@emlFingerprintsAgree: collideKey$, fpKey.key$
@emlTestAssertTrue: "a level renamed onto the old collision invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Defeat 4 — a tie perturbation of one ulp"
# ============================================================================
# The defeat that was reported against eDF1 nudged a level by 2.25 ulps. THAT
# EXACT SIZE CANNOT BE REPRODUCED AND DOES NOT NEED TO BE: within one binade
# the doubles are spaced exactly one ulp apart, so an offset of 2.25 ulps
# rounds to 2 and the fixture would silently be measuring something else.
# Measured on this Praat: 300 + 2.25 * ulp(300) minus 300, divided by
# ulp(300), is 2. The fixture therefore uses ONE ULP, the smallest change a
# double can express, which is strictly harder to see than 2.25 and makes the
# same point more sharply.
#
# One ulp at this magnitude is a relative change of 1.42e-16 — BELOW eDF1's
# 15-significant-digit quantum and therefore invisible to it. That quantum was
# a bucket five to ninety times wider than a double's own ulp, and this is what
# fell into it: every TIE between the nudged level and its neighbours breaks,
# and Kruskal-Wallis is a tie-corrected rank test, discontinuous at ties.
#
# Ian's ruling: "Agreed we don't round away machine precision." eTF2 has no
# quantum at all. The cell's text is the cell, and 400 and 400.00000000000013
# are two different texts.
#
# Reachable without malice: any recomputation of the column — a unit conversion
# out and back, a resampled measurement, a spreadsheet round trip — can land
# there.
# ============================================================================

procedure fpTies: .nudge
    .id = Create Table with column names: "fp_ties", 18, { "grp", "val" }
    .v1# = { 360, 380, 400, 400, 400, 400 }
    .v2# = { 300, 400, 400, 400, 400, 400 }
    .v3# = { 300, 300, 360, 400, 400, 400 }
    for .i from 1 to 6
        Set string value: .i, "grp", "aa"
        Set numeric value: .i, "val", .v1# [.i]
        Set string value: 6 + .i, "grp", "bb"
        if .nudge = 0
            Set numeric value: 6 + .i, "val", .v2# [.i]
        else
            ; exactly one ulp at this magnitude, and no more
            Set numeric value: 6 + .i, "val",
            ... .v2# [.i] + 2 ^ (floor (log2 (.v2# [.i])) - 52)
        endif
        Set string value: 12 + .i, "grp", "cc"
        Set numeric value: 12 + .i, "val", .v3# [.i]
    endfor
endproc

@fpTies: 0
tieCtrl = fpTies.id
@fpKey: tieCtrl
tieKey$ = fpKey.key$
selectObject: tieCtrl
tieCtrlCell$ = Get value: 7, "val"
@emlKruskalWallis: tieCtrl, "val", "grp"
tcP = emlKruskalWallis.p

@fpTies: 1
tieMut = fpTies.id
selectObject: tieMut
tieMutCell$ = Get value: 7, "val"
@emlKruskalWallis: tieMut, "val", "grp"
tmP = emlKruskalWallis.p

; The nudge really is one ulp and really is below a 15-digit quantum.
tieUlp = 2 ^ (floor (log2 (300)) - 52)
@emlTestAssertEqualNum: "the nudge is one ulp exactly",
... 1, (number (tieMutCell$) - number (tieCtrlCell$)) / tieUlp, 1e-9
@emlTestAssertEqualNum: "and 2.25 ulps is not a thing a double can be nudged by",
... 2, (300 + 2.25 * tieUlp - 300) / tieUlp, 1e-9
@emlTestAssertTrue: "one ulp is a relative change below one part in 1e15",
... abs (number (tieMutCell$) - number (tieCtrlCell$)) / 300 < 1e-15

; The cell text moves, which is the whole mechanism.
@emlTestAssertTrue: "and it still gives the cell a different text",
... tieCtrlCell$ <> tieMutCell$

; And the rank test, which reads ties and not sums, moves across .05.
@emlTestAssertTrue: "Kruskal-Wallis p is above .05 with the ties intact",
... tcP > 0.05
@emlTestAssertTrue: "and below .05 once they are broken", tmP < 0.05

@fpKey: tieMut
@emlFingerprintsAgree: tieKey$, fpKey.key$
@emlTestAssertTrue: "a one-ulp tie perturbation invalidates the key",
... emlFingerprintsAgree.same = 0

; Multiplicity itself, stated on its own: two tables of equal n over the same
; two distinct values, differing only in how many of each sit in each level.
tieMultA = Create Table with column names: "fp_mult", 4, { "grp", "val" }
Set string value: 1, "grp", "aa"
Set numeric value: 1, "val", 1
Set string value: 2, "grp", "aa"
Set numeric value: 2, "val", 1
Set string value: 3, "grp", "bb"
Set numeric value: 3, "val", 2
Set string value: 4, "grp", "bb"
Set numeric value: 4, "val", 2
@fpKey: tieMultA
multKey$ = fpKey.key$
tieMultB = Create Table with column names: "fp_mult", 4, { "grp", "val" }
Set string value: 1, "grp", "aa"
Set numeric value: 1, "val", 1
Set string value: 2, "grp", "aa"
Set numeric value: 2, "val", 2
Set string value: 3, "grp", "bb"
Set numeric value: 3, "val", 1
Set string value: 4, "grp", "bb"
Set numeric value: 4, "val", 2
@fpKey: tieMultB
@emlFingerprintsAgree: multKey$, fpKey.key$
@emlTestAssertTrue: "a level's tie multiplicity is part of the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Defeat 5 — a second grouping factor"
# ============================================================================
# @emlTwoWayAnova reads a value column and TWO factors. Against a key that
# described one value column split by ONE group column, rewriting six of twelve
# cells of the second factor moved F(group) from 7.564 to 2.687 and its p from
# .0229 to .1468 with the key unmoved.
#
# THE FAULT WAS NEVER IN THE ARITHMETIC. It was that a key describing two
# columns was handed to an analysis that read three. A whole-table key has no
# such shape to be wrong about: the second factor is in the key because every
# column is, and the two-column WRAPPER moves as well, because it describes the
# whole table too.
# ============================================================================

procedure fpTwoFactor: .variant
    .id = Create Table with column names: "fp_twofactor", 12,
    ... { "grp", "sex", "val" }
    .v# = { 340, 350, 600, 610, 430, 620, 630, 650, 300, 310, 320, 520 }
    for .i from 1 to 12
        Set numeric value: .i, "val", .v# [.i]
        if .i <= 4
            Set string value: .i, "grp", "aa"
        elsif .i <= 8
            Set string value: .i, "grp", "bb"
        else
            Set string value: .i, "grp", "cc"
        endif
    endfor
    if .variant = 0
        .s$# = { "f", "f", "m", "m", "f", "f", "m", "m", "f", "f", "m", "m" }
    else
        .s$# = { "f", "m", "f", "m", "m", "f", "m", "f", "m", "m", "f", "f" }
    endif
    for .i from 1 to 12
        Set string value: .i, "sex", .s$# [.i]
    endfor
endproc

@fpTwoFactor: 0
twoCtrl = fpTwoFactor.id
@fpKey: twoCtrl
twoKey$ = fpKey.key$
@emlTwoWayAnova: twoCtrl, "val", "grp", "sex"
twoCtrlF = emlTwoWayAnova.fA
twoCtrlP = emlTwoWayAnova.pA

@fpTwoFactor: 1
twoMut = fpTwoFactor.id
@emlTwoWayAnova: twoMut, "val", "grp", "sex"
@emlTestAssertTrue: "F(group) moves when the second factor is rewritten",
... abs (twoCtrlF - emlTwoWayAnova.fA) > 1
@emlTestAssertTrue: "and its p crosses .05",
... twoCtrlP < 0.05 and emlTwoWayAnova.pA > 0.05

@fpKey: twoMut
@emlFingerprintsAgree: twoKey$, fpKey.key$
@emlTestAssertTrue: "rewriting half the second factor's cells invalidates the key",
... emlFingerprintsAgree.same = 0

; And the two-column wrapper sees it too, because it describes the whole table.
@emlGroupFingerprint: twoCtrl, "val", "grp"
wrapCtrl$ = emlGroupFingerprint.result$
@emlGroupFingerprint: twoMut, "val", "grp"
@emlFingerprintsAgree: wrapCtrl$, emlGroupFingerprint.result$
@emlTestAssertTrue: "the two-column wrapper invalidates on it as well",
... emlFingerprintsAgree.same = 0
@emlTestAssertEqualStr: "because it covers all three columns whatever it is told",
... "grp,sex,val", emlGroupFingerprint.covers$


# ============================================================================
@emlTestSection: "Defeat 6 — the spelling set was not a set"
# ============================================================================
# An earlier key carried, per level, the count plus a LINEAR SUM of its raw
# spellings' hashes. A sum is the wrong shape for a set: {aa, AA} and {Aa, aA}
# summed identically, so the key held while the level's DISPLAYED label — the
# first spelling encountered — changed from "aa" to "Aa", and a reused result
# printed a level name that is not what the figure would draw.
#
# Nothing here folds a spelling set, because nothing here normalises a label.
# The cell text is the key, so a respelling is an edit like any other.
# ============================================================================

procedure fpSpelling: .variant
    .id = Create Table with column names: "fp_spelling", 9, { "grp", "val" }
    .v# = { 340, 350, 600, 430, 620, 630, 300, 310, 320 }
    for .i from 1 to 9
        Set numeric value: .i, "val", .v# [.i]
    endfor
    if .variant = 0
        Set string value: 1, "grp", "aa"
        Set string value: 2, "grp", "AA"
        Set string value: 3, "grp", "aa"
    elsif .variant = 1
        Set string value: 1, "grp", "Aa"
        Set string value: 2, "grp", "aA"
        Set string value: 3, "grp", "Aa"
    else
        ; the SAME set of spellings, in another order of appearance: the
        ; displayed level label moves from "aa" to "AA" and nothing else does
        Set string value: 1, "grp", "AA"
        Set string value: 2, "grp", "aa"
        Set string value: 3, "grp", "aa"
    endif
    for .i from 4 to 6
        Set string value: .i, "grp", "bb"
    endfor
    for .i from 7 to 9
        Set string value: .i, "grp", "cc"
    endfor
endproc

@fpSpelling: 0
spellCtrl = fpSpelling.id
@fpKey: spellCtrl
spellKey$ = fpKey.key$
@emlCountGroups: spellCtrl, "grp"
spellCtrlLabel$ = emlCountGroups.groupLabel$[1]

@fpSpelling: 1
spellMut = fpSpelling.id
@emlCountGroups: spellMut, "grp"
@emlTestAssertEqualStr: "the control level prints as aa", "aa", spellCtrlLabel$
@emlTestAssertEqualStr: "the mutant level prints as Aa",
... "Aa", emlCountGroups.groupLabel$[1]
@fpKey: spellMut
@emlFingerprintsAgree: spellKey$, fpKey.key$
@emlTestAssertTrue: "a spelling set that sums the same still invalidates the key",
... emlFingerprintsAgree.same = 0

@fpSpelling: 2
spellOrder = fpSpelling.id
@emlCountGroups: spellOrder, "grp"
@emlTestAssertEqualStr: "the reordered spellings print as AA",
... "AA", emlCountGroups.groupLabel$[1]
@fpKey: spellOrder
@emlFingerprintsAgree: spellKey$, fpKey.key$
@emlTestAssertTrue: "and the same set in another order invalidates it too",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "A correlation: two measurement columns, no grouping column"
# ============================================================================
# x and y are bound row-wise and nothing groups them. Exchange two y values
# BETWEEN ROWS and both columns still hold exactly the numbers they held —
# same count, same sum, same sum of squares, same min, same max, in BOTH
# columns — while r moves. Only the pairing changed, and the pairing is the
# whole of what a correlation reads.
# ============================================================================

procedure fpCorr: .variant
    .id = Create Table with column names: "fp_corr", 6, { "x", "y" }
    .x# = { 1, 2, 3, 4, 5, 6 }
    .y# = { 2.1, 3.9, 6.2, 7.8, 10.1, 12.2 }
    if .variant = 1
        .y# = { 12.2, 3.9, 6.2, 7.8, 10.1, 2.1 }
    endif
    for .i from 1 to 6
        Set numeric value: .i, "x", .x# [.i]
        Set numeric value: .i, "y", .y# [.i]
    endfor
endproc

@fpCorr: 0
corrCtrl = fpCorr.id
@emlExtractColumn: corrCtrl, "x"
corrX# = emlExtractColumn.data#
@emlExtractColumn: corrCtrl, "y"
corrY# = emlExtractColumn.data#
@emlPearsonCorrelation: corrX#, corrY#, 2
corrCtrlR = emlPearsonCorrelation.r
@fpKey: corrCtrl
corrKey$ = fpKey.key$
@emlTestAssertTrue: "a table with no grouping column at all yields a key",
... corrKey$ <> ""

@fpCorr: 1
corrMut = fpCorr.id
@emlExtractColumn: corrMut, "y"
corrY2# = emlExtractColumn.data#
@emlPearsonCorrelation: corrX#, corrY2#, 2

; The premise, measured: y holds the same numbers, so every summary of the
; column on its own is unchanged.
@emlTestAssertEqualNum: "y keeps its count", size (corrY#), size (corrY2#), 0
@emlTestAssertEqualNum: "y keeps its sum", sum (corrY#), sum (corrY2#), 1e-12
@emlTestAssertEqualNum: "y keeps its sum of squares",
... sum (corrY# * corrY#), sum (corrY2# * corrY2#), 1e-12
@emlTestAssertEqualNum: "y keeps its minimum", min (corrY#), min (corrY2#), 0
@emlTestAssertEqualNum: "y keeps its maximum", max (corrY#), max (corrY2#), 0

; And r does not.
@emlTestAssertTrue: "r is above .99 before the exchange", corrCtrlR > 0.99
@emlTestAssertTrue: "and below .3 after it", emlPearsonCorrelation.r < 0.3

@fpKey: corrMut
@emlFingerprintsAgree: corrKey$, fpKey.key$
@emlTestAssertTrue: "exchanging two y values between rows invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "A covariate"
# ============================================================================
# An analysis of covariance reads a third column as a NUMBER rather than as a
# factor. One cell of it moves the adjusted means; the key must move with it,
# and it does whether or not anyone says the column is there.
# ============================================================================

procedure fpCovar: .variant
    .id = Create Table with column names: "fp_covar", 9,
    ... { "grp", "val", "age" }
    .g$# = { "a", "a", "a", "b", "b", "b", "c", "c", "c" }
    .v# = { 10.5, 11.75, 12, 20.25, 21.5, 22.75, 30.125, 31.25, 32.5 }
    .a# = { 21, 34, 27, 45, 39, 52, 22, 61, 30 }
    if .variant = 1
        .a# = { 21, 34, 27, 45, 39, 52, 22, 61, 31 }
    endif
    for .i from 1 to 9
        Set string value: .i, "grp", .g$# [.i]
        Set numeric value: .i, "val", .v# [.i]
        Set numeric value: .i, "age", .a# [.i]
    endfor
endproc

@fpCovar: 0
covarCtrl = fpCovar.id
@fpKey: covarCtrl
covarKey$ = fpKey.key$
@emlTestAssertTrue: "a table carrying a covariate yields a key", covarKey$ <> ""
@emlTestAssertEqualStr: "covering all three columns",
... "grp,val,age", emlDataFingerprint.covers$

@fpCovar: 1
covarMut = fpCovar.id
@fpKey: covarMut
@emlFingerprintsAgree: covarKey$, fpKey.key$
@emlTestAssertTrue: "one cell of the covariate invalidates the key",
... emlFingerprintsAgree.same = 0

; And the two-column wrapper — the door a one-way analysis would reach for —
; sees it too. Under a declared-column key it did not, and that was Defeat 8.
@emlGroupFingerprint: covarCtrl, "val", "grp"
covarWrap$ = emlGroupFingerprint.result$
@emlGroupFingerprint: covarMut, "val", "grp"
@emlFingerprintsAgree: covarWrap$, emlGroupFingerprint.result$
@emlTestAssertTrue: "a caller that never mentions the covariate still sees it move",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Repeated measures (subject rename INVERTED: moves)"
# ============================================================================
# Four subjects measured twice. THE RENAME LEG IS THE SECOND INVERSION IN THIS
# FILE. Earlier formats replaced an identity column's values with a canonical
# name derived from the block of rows they gathered, so that renaming a subject
# held the cache; the machinery for that — block digests, and a refusal of two
# crossed identity columns — is gone.
#
# Under the ruling quoted at the top of this file, a rename is a change to the
# data and re-runs the analysis. That is a real cost: tidying a spreadsheet's
# subject codes re-runs everything. It buys the deletion of the only part of
# the construction that had to reason about what a column MEANT, and with it
# the refusal that stopped a crossed subjects-by-items design being keyed at
# all.
#
# Re-pairing, reordering and editing all move the key as well, and they were
# always supposed to.
# ============================================================================

procedure fpRepeated: .variant
    .id = Create Table with column names: "fp_repeated", 8,
    ... { "subj", "cond", "val" }
    .s$# = { "s1", "s1", "s2", "s2", "s3", "s3", "s4", "s4" }
    .c$# = { "pre", "post", "pre", "post", "pre", "post", "pre", "post" }
    .v# = { 10, 15, 12, 18, 14, 17, 11, 20 }
    if .variant = 1
        ; one subject renamed, everywhere it appears
        .s$# = { "s1", "s1", "volunteer_two", "volunteer_two",
        ... "s3", "s3", "s4", "s4" }
    elsif .variant = 2
        ; the same cells, RE-PAIRED: s1's and s4's post values exchanged
        .v# = { 10, 20, 12, 18, 14, 17, 11, 15 }
    elsif .variant = 3
        ; the same rows, presented in another order
        .s$# = { "s4", "s2", "s1", "s3", "s2", "s4", "s3", "s1" }
        .c$# = { "post", "pre", "post", "post", "post", "pre", "pre", "pre" }
        .v# = { 20, 12, 15, 17, 18, 11, 14, 10 }
    endif
    for .i from 1 to 8
        Set string value: .i, "subj", .s$# [.i]
        Set string value: .i, "cond", .c$# [.i]
        Set numeric value: .i, "val", .v# [.i]
    endfor
endproc

@fpRepeated: 0
rmCtrl = fpRepeated.id
@fpKey: rmCtrl
rmKey$ = fpKey.key$
@emlTestAssertTrue: "a repeated-measures table yields a key", rmKey$ <> ""

@eml_getGroupData: rmCtrl, "val", "cond", "pre"
rmPre# = eml_getGroupData.data#
@eml_getGroupData: rmCtrl, "val", "cond", "post"
rmPost# = eml_getGroupData.data#
@emlTTestPaired: rmPre#, rmPost#, 2
rmCtrlT = emlTTestPaired.t

; --- a subject renamed: no number moves, and the key moves anyway ----------
@fpRepeated: 1
rmRenamed = fpRepeated.id
@eml_getGroupData: rmRenamed, "val", "cond", "pre"
renPre# = eml_getGroupData.data#
@eml_getGroupData: rmRenamed, "val", "cond", "post"
renPost# = eml_getGroupData.data#
@emlTTestPaired: renPre#, renPost#, 2
@emlTestAssertEqualNum: "renaming a subject moves no number",
... rmCtrlT, emlTTestPaired.t, 1e-12
@fpKey: rmRenamed
@emlFingerprintsAgree: rmKey$, fpKey.key$
@emlTestAssertTrue: "and INVALIDATES the key anyway (ruled 24 Aug; costs a re-run)",
... emlFingerprintsAgree.same = 0

; --- the rows re-paired: every difference moves ---------------------------
@fpRepeated: 2
rmRepaired = fpRepeated.id
@eml_getGroupData: rmRepaired, "val", "cond", "pre"
repPre# = eml_getGroupData.data#
@eml_getGroupData: rmRepaired, "val", "cond", "post"
repPost# = eml_getGroupData.data#

; The premise, measured: each condition holds exactly the numbers it held.
@emlTestAssertEqualNum: "the pre condition is unchanged",
... sum (rmPre#), sum (repPre#), 1e-12
@emlTestAssertEqualNum: "the post condition keeps its sum",
... sum (rmPost#), sum (repPost#), 1e-12
@emlTestAssertEqualNum: "and its sum of squares",
... sum (rmPost# * rmPost#), sum (repPost# * repPost#), 1e-12
@emlTestAssertEqualNum: "and its minimum", min (rmPost#), min (repPost#), 0
@emlTestAssertEqualNum: "and its maximum", max (rmPost#), max (repPost#), 0

@emlTTestPaired: repPre#, repPost#, 2
@emlTestAssertTrue: "and the paired t moves anyway",
... abs (rmCtrlT - emlTTestPaired.t) > 0.5

@fpKey: rmRepaired
@emlFingerprintsAgree: rmKey$, fpKey.key$
@emlTestAssertTrue: "re-pairing which rows belong together invalidates the key",
... emlFingerprintsAgree.same = 0

; --- the rows reordered (INVERTED: moves) ---------------------------------
@fpRepeated: 3
rmReordered = fpRepeated.id
@fpKey: rmReordered
@emlFingerprintsAgree: rmKey$, fpKey.key$
@emlTestAssertTrue: "reordering the rows of a paired table INVALIDATES the key",
... emlFingerprintsAgree.same = 0

; --- an edit inside one subject -------------------------------------------
@fpRepeated: 0
rmEdited = fpRepeated.id
selectObject: rmEdited
Set numeric value: 4, "val", 18.5
@fpKey: rmEdited
@emlFingerprintsAgree: rmKey$, fpKey.key$
@emlTestAssertTrue: "one cell edited inside a subject invalidates the key",
... emlFingerprintsAgree.same = 0

; --- two rows exchange their CONDITION -------------------------------------
@fpRepeated: 0
rmCondSwap = fpRepeated.id
selectObject: rmCondSwap
Set string value: 1, "cond", "post"
Set string value: 2, "cond", "pre"
@fpKey: rmCondSwap
@emlFingerprintsAgree: rmKey$, fpKey.key$
@emlTestAssertTrue: "exchanging two condition labels invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "A level no analysis can use, and the content of a dropped row"
# ============================================================================
# @emlCountGroups reads a grouping column ON ITS OWN: a row whose value cell
# the analysis cannot use still contributes its level, and k is df in every
# test that has one. A key built from the rows an analysis KEEPS therefore
# needed a separate level census to see a level carried entirely by rows it
# drops, and needed one again to see the content of a dropped cell.
#
# Neither structure exists here. Every cell is in the key as its literal text,
# whether an analysis can use it or not, so all three coverage cases close by
# construction: a level carried only by unusable rows, the CONTENT of an
# excluded cell, and the displayed spelling of a level.
# ============================================================================

procedure fpGhost: .variant
    .id = Create Table with column names: "fp_ghost", 5, { "grp", "val" }
    .g$# = { "a", "a", "b", "b", "c" }
    if .variant = 1
        ; the unusable row moves to another level: k drops from 3 to 2
        .g$# = { "a", "a", "b", "b", "b" }
    elsif .variant = 2
        ; the unusable row moves between two levels that both survive:
        ; k is unchanged and only the level's row count moves
        .g$# = { "a", "a", "a", "b", "c" }
    endif
    for .i from 1 to 5
        Set string value: .i, "grp", .g$# [.i]
    endfor
    Set numeric value: 1, "val", 10
    Set numeric value: 2, "val", 11
    Set numeric value: 3, "val", 20
    Set numeric value: 4, "val", 21
    Set string value: 5, "val", "n/a"
    if .variant = 3
        ; the SAME row is still unusable, and says something else
        Set string value: 5, "val", "N/A"
    elsif .variant = 4
        Set string value: 5, "val", "missing"
    endif
endproc

@fpGhost: 0
ghostCtrl = fpGhost.id
@fpKey: ghostCtrl
ghostKey$ = fpKey.key$
@emlCountGroups: ghostCtrl, "grp"
@emlTestAssertEqualNum: "three levels, one of them carrying no usable value",
... 3, emlCountGroups.nGroups, 0

@fpGhost: 1
ghostGone = fpGhost.id
@emlCountGroups: ghostGone, "grp"
@emlTestAssertEqualNum: "the level is gone", 2, emlCountGroups.nGroups, 0
@fpKey: ghostGone
@emlFingerprintsAgree: ghostKey$, fpKey.key$
@emlTestAssertTrue: "a level vanishing invalidates the key, though no usable row moved",
... emlFingerprintsAgree.same = 0

@fpGhost: 2
ghostMoved = fpGhost.id
@emlCountGroups: ghostMoved, "grp"
@emlTestAssertEqualNum: "k is unchanged this time", 3, emlCountGroups.nGroups, 0
@fpKey: ghostMoved
@emlFingerprintsAgree: ghostKey$, fpKey.key$
@emlTestAssertTrue: "and an unusable row changing level still invalidates it",
... emlFingerprintsAgree.same = 0

; THE CONTENT OF AN EXCLUDED CELL. The row is unusable before and after, so
; every analysis in the plugin drops it either way and no number moves. The
; cell's TEXT moves, so the key moves.
@fpGhost: 3
ghostCase = fpGhost.id
@fpKey: ghostCase
@emlFingerprintsAgree: ghostKey$, fpKey.key$
@emlTestAssertTrue: "n/a rewritten as N/A invalidates the key",
... emlFingerprintsAgree.same = 0

@fpGhost: 4
ghostWord = fpGhost.id
@fpKey: ghostWord
@emlFingerprintsAgree: ghostKey$, fpKey.key$
@emlTestAssertTrue: "and so does n/a rewritten as missing",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "What the key does NOT decide — the settings"
# ============================================================================
# THE KEY IS NOT THE WHOLE VALIDITY TEST. It reads the Table and the caller's
# declaration and nothing else, so no setting is an input to it and no setting
# can move it. The settings move printed numbers all the same, and this
# section measures two of them on a BYTE-IDENTICAL key so that the boundary is
# a measurement here and not an assurance.
#
# A store that checks the key alone has checked the data and the declared
# scope. It has not checked the test type, the correction method, alpha, or
# the group sort order, and it must carry all four itself.
#
# GROUP SORT ORDER IS THE ONE TO WATCH. It is a global with no dialog of its
# own — set from `config_groupSort` in graphs/eml-graphs-form.praat — so it is
# not among the three result-affecting dialog controls the ruling's settings
# census enumerates, and a census built by walking dialog controls will not
# find it.
# ============================================================================

sortWas = emlGroupSortAlphabetical
emlGroupSortAlphabetical = 0
@fpKey: control
sortOffKey$ = fpKey.key$
emlGroupSortAlphabetical = 1
@fpKey: control
@emlFingerprintsAgree: sortOffKey$, fpKey.key$
@emlTestAssertTrue: "the group display setting does not move the key",
... emlFingerprintsAgree.same = 1
emlGroupSortAlphabetical = sortWas

; --- the correction method, on a byte-identical key ------------------------
setT = Create Table with column names: "fp_settings", 9, { "grp", "val" }
setG$# = { "A", "B", "C", "A", "B", "C", "A", "B", "C" }
setV# = { 1, 2, 30, 1, 2, 31, 1, 2, 32 }
for i from 1 to 9
    Set string value: i, "grp", setG$# [i]
    Set numeric value: i, "val", setV# [i]
endfor
@emlGroupFingerprint: setT, "val", "grp"
setKeyBefore$ = emlGroupFingerprint.result$

@emlDunnTest: setT, "val", "grp", "holm"
dunnHolm = emlDunnTest.adjustedP# [1]
@emlDunnTest: setT, "val", "grp", "bonferroni"
dunnBonf = emlDunnTest.adjustedP# [1]
@emlGroupFingerprint: setT, "val", "grp"
@emlFingerprintsAgree: setKeyBefore$, emlGroupFingerprint.result$
@emlTestAssertTrue: "the key is byte-identical across the two corrections",
... emlFingerprintsAgree.same = 1
@emlTestAssertTrue: "and the adjusted p is not: holm differs from bonferroni",
... abs (dunnHolm - dunnBonf) > 0.1
@emlTestAssertTrue: "holm is the smaller of the two", dunnHolm < dunnBonf

; --- the group sort order, on a byte-identical key -------------------------
; It flips the SIGN of a mean difference and the ORDER of the names on the
; bracket, so a stored result read back under the other setting is drawn with
; the comparison reversed and relabelled.
sortT = Create Table with column names: "fp_sortcase", 6, { "g", "v" }
sortG$# = { "Zebra", "Zebra", "Zebra", "Alpha", "Alpha", "Alpha" }
sortV# = { 10, 12, 14, 1, 2, 3 }
for i from 1 to 6
    Set string value: i, "g", sortG$# [i]
    Set numeric value: i, "v", sortV# [i]
endfor
@emlGroupFingerprint: sortT, "v", "g"
sortKeyBefore$ = emlGroupFingerprint.result$

sortWas = emlGroupSortAlphabetical
emlGroupSortAlphabetical = 0
@emlTukeyHSD: sortT, "v", "g", 0.05
discFirst$ = emlTukeyHSD.groupName$ [1]
discSecond$ = emlTukeyHSD.groupName$ [2]
discDiff = emlTukeyHSD.meanDiff## [1, 2]
emlGroupSortAlphabetical = 1
@emlTukeyHSD: sortT, "v", "g", 0.05
alphaFirst$ = emlTukeyHSD.groupName$ [1]
alphaSecond$ = emlTukeyHSD.groupName$ [2]
alphaDiff = emlTukeyHSD.meanDiff## [1, 2]
emlGroupSortAlphabetical = sortWas

@emlGroupFingerprint: sortT, "v", "g"
@emlFingerprintsAgree: sortKeyBefore$, emlGroupFingerprint.result$
@emlTestAssertTrue: "the key is byte-identical across the two sort orders",
... emlFingerprintsAgree.same = 1
@emlTestAssertEqualStr: "discovery order names Zebra first", "Zebra", discFirst$
@emlTestAssertEqualStr: "and Alpha second", "Alpha", discSecond$
@emlTestAssertEqualStr: "alphabetical names Alpha first", "Alpha", alphaFirst$
@emlTestAssertEqualStr: "and Zebra second", "Zebra", alphaSecond$
@emlTestAssertEqualNum: "the comparison is +10 one way", 10, discDiff, 1e-9
@emlTestAssertEqualNum: "and -10 the other", -10, alphaDiff, 1e-9
@emlTestAssertTrue: "so a setting with no dialog flips the sign on a key that did not move",
... discDiff * alphaDiff < 0


# ============================================================================
@emlTestSection: "A key that is not a key never agrees"
# ============================================================================

@emlDataFingerprint: 0
@emlTestAssertEqualStr: "no table yields no key",
... "", emlDataFingerprint.result$
@emlTestAssertTrue: "and says why", emlDataFingerprint.error$ <> ""
@emlTestAssertContains: "naming what was missing",
... emlDataFingerprint.error$, "Table"

@emlGroupFingerprint: 0, "val", "grp"
@emlTestAssertEqualStr: "the wrapper refuses on the same grounds",
... "", emlGroupFingerprint.result$
@emlAnalysisFingerprint: 0, "val,grp"
@emlTestAssertEqualStr: "and so does the list wrapper",
... "", emlAnalysisFingerprint.result$

@emlFingerprintsAgree: "", controlKey$
@emlTestAssertTrue: "an empty key never agrees with a real one",
... emlFingerprintsAgree.same = 0
@emlFingerprintsAgree: controlKey$, ""
@emlTestAssertTrue: "and never in the other direction either",
... emlFingerprintsAgree.same = 0
@emlFingerprintsAgree: "", ""
@emlTestAssertTrue: "two unknowns are not a match",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "The key is text, and survives being text"
# ============================================================================
# The key crosses file boundaries: a stored result is written to disk and the
# recorder writes a key into an emitted script. It must come back the same
# string, and it must never be re-parsed as a number.
# ============================================================================

keyFile$ = "fp_key_roundtrip.txt"
deleteFile: keyFile$
writeFileLine: keyFile$, controlKey$
readBack$ = readFile$ (keyFile$)
readBack$ = replace$ (readBack$, newline$, "", 0)
deleteFile: keyFile$
@emlFingerprintsAgree: controlKey$, readBack$
@emlTestAssertTrue: "the key survives a write and a read",
... emlFingerprintsAgree.same = 1

; The key is ASCII whatever the table holds, because every piece of text
; reaches it through the mixer and never as its own characters.
hostileTable = Create Table with column names: "fp_hostile", 3, { "grp", "val" }
Set string value: 1, "grp", "a|b=c_d"
Set numeric value: 1, "val", 1
Set string value: 2, "grp", "eTF2|r=9|s=2"
Set numeric value: 2, "val", 2
Set string value: 3, "grp", "n" + string$ (33) + "aive"
Set numeric value: 3, "val", 3
@fpKey: hostileTable
hostileKey$ = fpKey.key$
@emlTestAssertTrue: "a separator-bearing cell still yields a key",
... hostileKey$ <> ""
nBars = 0
for i from 1 to length (hostileKey$)
    if mid$ (hostileKey$, i, 1) = "|"
        nBars = nBars + 1
    endif
endfor
@emlTestAssertEqualNum: "and cannot forge a record boundary", 5, nBars, 0

; A table saved and reloaded is the same table, so it is the same key.
tableFile$ = "fp_table_roundtrip.Table"
deleteFile: tableFile$
selectObject: control
Save as text file: tableFile$
reloaded = Read from file: tableFile$
Rename: "fp_case"
deleteFile: tableFile$
@fpKey: reloaded
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "the table saved and reloaded keeps its key",
... emlFingerprintsAgree.same = 1


# ============================================================================
@emlTestSection: "Praat rewrites the name the key carries"
# ============================================================================
# The key's first content term after the format tag is the table's NAME, and
# @eml_fpCompose reads it with selected$ ("Table") — the name the object ended
# up with, not the string the caller handed to the create command. Praat will
# not hold a name containing a space, a bar, a comma or a slash, and replaces
# each with an underscore.
#
# THAT IS THE TRAP THE FIXTURE RULE AT THE TOP OF THIS FILE EXISTS FOR, SEEN
# FROM THE OTHER SIDE. The rule says a mutant and its control must share a
# table name, because a fixture named apart moves the key on the name alone
# and goes green without testing anything. The rewriting supplies the mirror
# image: a fixture named "data|1" against a control named "data_1" IS named
# alike, whatever its author intended, so a leg that expects those two keys to
# differ is asserting something the arithmetic cannot deliver — green for the
# wrong reason in one direction, red for the wrong reason in the other.
#
# The rewriting is Praat's and not this module's, so it is measured here
# rather than assumed.
# ============================================================================

procedure fpNamed: .asked$
    .id = Create Table with column names: .asked$, 2, { "grp", "val" }
    Set string value: 1, "grp", "A"
    Set numeric value: 1, "val", 1
    Set string value: 2, "grp", "B"
    Set numeric value: 2, "val", 2
    selectObject: .id
    .got$ = selected$ ("Table")
endproc

; --- what Praat does to a name ----------------------------------------------
@fpNamed: "a b"
nameSpace = fpNamed.id
@emlTestAssertEqualStr: "a space in a table name becomes an underscore",
... "a_b", fpNamed.got$

@fpNamed: "data|1"
nameBar = fpNamed.id
@emlTestAssertEqualStr: "and a bar becomes an underscore",
... "data_1", fpNamed.got$

@fpNamed: "val,grp"
nameComma = fpNamed.id
@emlTestAssertEqualStr: "and a comma", "val_grp", fpNamed.got$

@fpNamed: "x/y"
nameSlash = fpNamed.id
@emlTestAssertEqualStr: "and a slash", "x_y", fpNamed.got$

@fpNamed: "x-y"
nameDash = fpNamed.id
@emlTestAssertEqualStr: "while a hyphen survives", "x-y", fpNamed.got$

; --- and what that does to the key ------------------------------------------
; Same content, two names that differ only in a character Praat rewrites: one
; name term, one key. This is the leg a fixture author has to know about.
@fpNamed: "data_1"
nameUnderscore = fpNamed.id
@fpKey: nameBar
nameBarKey$ = fpKey.key$
@fpKey: nameUnderscore
nameUnderscoreKey$ = fpKey.key$
@emlFingerprintsAgree: nameBarKey$, nameUnderscoreKey$
@emlTestAssertTrue: "two tables asked for ""data|1"" and ""data_1"" share one key",
... emlFingerprintsAgree.same = 1

; A name that differs after the rewriting does move the key, so the term is
; carried and the leg above is about the rewriting and not about the name
; being ignored.
@fpNamed: "data_2"
nameOther = fpNamed.id
@fpKey: nameOther
@emlFingerprintsAgree: nameBarKey$, fpKey.key$
@emlTestAssertTrue: "a name that differs after the rewriting does move the key",
... emlFingerprintsAgree.same = 0

; The name the caller asked for is not what the key saw, which is the whole
; point: a fixture author comparing asked-for names compares the wrong thing.
selectObject: nameBar
@emlTestAssertTrue: "the name asked for is not the name the key carried",
... selected$ ("Table") <> "data|1"

removeObject: nameSpace, nameBar, nameComma, nameSlash, nameDash,
... nameUnderscore, nameOther


# ============================================================================
@emlTestSection: "The format tag keeps older keys out"
# ============================================================================
# eGF1, eGF2, eDF1 and eTF1 keys exist in the wild — in any stored result
# written under an earlier composition. None of them may compare equal to an
# eTF2 key, and the tag is what makes that true by construction rather than by
# luck. eTF1 is the closest of the four and the one that matters most: it
# digests the same cells in the same order and differs only in that it folds
# no scope, so a text comparison that ignored the tag could plausibly be asked
# to treat the two as one. Their compositions differ, so a stored key under
# any older tag re-runs its analysis; that is the intended behaviour and not a
# migration to be written.
# ============================================================================

@emlTestAssertContains: "the key is tagged eTF2", controlKey$, "eTF2"
for tag from 1 to 4
    oldTag$ = "eDF1"
    if tag = 2
        oldTag$ = "eGF2"
    elsif tag = 3
        oldTag$ = "eGF1"
    elsif tag = 4
        oldTag$ = "eTF1"
    endif
    oldShape$ = replace$ (controlKey$, "eTF2", oldTag$, 1)
    @emlFingerprintsAgree: controlKey$, oldShape$
    @emlTestAssertTrue: "the same key under the " + oldTag$
    ... + " tag does not agree", emlFingerprintsAgree.same = 0
endfor


# ============================================================================
@emlTestSection: "Cost, and that it is linear"
# ============================================================================
# The work is one C-level table copy, one rename per column, one cell read per
# cell, and one pass over the characters of the table's text. Nothing sorts
# and nothing is quadratic: measured on Praat 6.6.30 at 100, 1000, 2000, 4000
# and 8000 rows, each doubling of the rows doubles the time — 1000 x 3 in
# 0.43 s, 2000 x 3 in 0.90 s, 8000 x 3 in 3.26 s.
#
# THE BOUNDS BELOW ARE LOOSE ON PURPOSE, by more than a factor of five against
# those figures, because a slow machine must not turn this suite red. What
# they catch is a rebuild that reintroduces a sort or any other quadratic,
# which would not be a factor of five out — it would be a factor of hundreds.
# ============================================================================

perf1 = Create Table with column names: "fp_perf", 1000, { "v", "grp", "sub" }
for r from 1 to 1000
    Set numeric value: r, "v", randomGauss (500, 60)
    Set string value: r, "grp", "level" + string$ (r mod 4)
    Set string value: r, "sub", "s" + string$ (r mod 20)
endfor
stopwatch
@fpKey: perf1
t1000 = stopwatch
@emlTestAssertTrue: "1000 rows x 3 columns key in under 5 s", t1000 < 5

perf2 = Create Table with column names: "fp_perf", 2000, { "v", "grp", "sub" }
for r from 1 to 2000
    Set numeric value: r, "v", randomGauss (500, 60)
    Set string value: r, "grp", "level" + string$ (r mod 4)
    Set string value: r, "sub", "s" + string$ (r mod 20)
endfor
stopwatch
@fpKey: perf2
t2000 = stopwatch
@emlTestAssertTrue: "2000 rows x 3 columns key in under 10 s", t2000 < 10
@emlTestAssertTrue: "and doubling the rows does not more than treble the time",
... t2000 < 3 * t1000 + 0.5


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSummary
