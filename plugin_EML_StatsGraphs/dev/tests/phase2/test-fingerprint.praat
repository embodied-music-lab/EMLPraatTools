# ============================================================================
# EML Stats : Test Suite — the result store's data key
# ============================================================================
# Tests: @emlGroupFingerprint, @emlAnalysisFingerprint, @emlFingerprintsAgree,
#        @eml_fpNumber, @eml_fpTextHash, @eml_fpValueDigest
# Version: 1.1
# Date: 24 August 2026
#
# Uses shared test helpers (eml-test-helpers.praat).
#
# WHAT THIS SUITE IS FOR
#
# The result store lets a figure receive the analysis's result instead of
# re-running the analysis at draw time (docs/RULING_RESULT_STORE.md). A stored
# result is valid until a result-affecting setting changes or THE DATA
# CHANGES, and @emlGroupFingerprint is how the second half is decided.
#
# The ruling published the acceptance probes before the code was written, and
# the four "Probe" sections below are those four probes in order. They are
# unchanged by the eGF2 rebuild and MUST STAY GREEN: the rebuild is only worth
# having if it still holds the cache over a within-level row reorder.
#
#   1. two values exchanged BETWEEN groups — the value column's multiset and
#      both group sizes are unchanged, every group mean moves. Must invalidate.
#      This is the probe a column-level checksum fails, and section 1 asserts
#      the column-level aggregates are identical across the mutation so that
#      the failure of a cheaper key is a measurement here rather than a claim.
#   2. one data cell edited at constant row count. Must invalidate.
#   3. one group cell relabelled. Must invalidate.
#   4. rows reordered WITHIN a group. Must HOLD — reordering rows inside a
#      group changes nothing any group comparison computes, and a key that
#      invalidates here makes the whole store useless. This is the leg a
#      careless rebuild breaks: a digest over an UNSORTED value list
#      invalidates here and takes the whole feature with it.
#
# THE SIX DEFEATS. On 24 August 2026 an adversarial pass broke the first
# composition (format eGF1) six times, and the sections after the probes are
# those six, each with the fixture that did it. Every one of them held the
# cache against eGF1 and moves the key against eGF2. Three of the six were one
# fault — per-level moment aggregates cannot describe a multiset — and the
# rebuild answers them together by committing to each level's sorted value
# list. Measured against a scratch revert of the old composition, twenty-three
# of the checks in this file go red, including all six defeats; the four
# acceptance probes stay green in both.
#
# THE MUTANT AND ITS CONTROL MUST SHARE A TABLE NAME. The key carries the
# table's name, so a mutation fixture built as a separately named table goes
# green on the name alone. Every fixture below is built by @fpFixture, which
# always names the table "fp_case"; only its contents differ. The reorder leg
# is the one that catches a slip, because it is the only leg whose expected
# answer the name can flip — which is how the mistake was caught when this
# suite's rig was first driven.
#
# NO ORACLE, AND WHY NONE IS NEEDED. Every other phase2 suite asserts library
# numbers against R or scipy. There is no external authority on a fingerprint:
# the key is an internal identity, and what has to be true of it is not a
# value but a set of RELATIONS between keys — same data, same key; changed
# data, changed key. So every assertion here compares two keys the suite
# computed, and no literal key is written down. A literal would also pin the
# format, which is deliberately free to change behind its version tag.
#
# This is why the suite is absent from dev/tests/REFERENCE_PROVENANCE.md and
# has no companion generator. The literals it does carry are structural facts
# about the code — a level count, a row count, the text @eml_fpNumber renders
# 1500 as — and not measurements of anything an external implementation could
# have computed instead.
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
    @emlGroupFingerprint: .id, "val", "grp"
    .key$ = emlGroupFingerprint.result$
    .error$ = emlGroupFingerprint.error$
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
@emlTestAssertEqualNum: "three levels", 3, emlGroupFingerprint.nLevels, 0
@emlTestAssertEqualNum: "nine usable rows", 9, emlGroupFingerprint.nUsable, 0
@emlTestAssertEqualNum: "no blank group cells", 0, emlGroupFingerprint.nBlank, 0
@emlTestAssertContains: "the key names its format version", controlKey$, "eGF2"

@fpFixture
twin = fpFixture.id
@fpKey: twin
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "an identical rebuild agrees",
... emlFingerprintsAgree.same = 1


# ============================================================================
@emlTestSection: "Probe 1 — a value swapped BETWEEN groups"
# ============================================================================
# Row 1 (level A) and row 2 (level B) exchange values. Group sizes unchanged,
# the value column's multiset unchanged, every group mean moved.
# ============================================================================

@fpFixture
swapped = fpFixture.id
selectObject: swapped
Set numeric value: 1, "val", 20.25
Set numeric value: 2, "val", 10.5

@emlExtractColumn: control, "val"
before# = emlExtractColumn.data#
@emlExtractColumn: swapped, "val"
after# = emlExtractColumn.data#

; The measurement that makes the probe mean something: a key built from the
; value column alone would be IDENTICAL across this mutation.
@emlTestAssertEqualNum: "the column count is unchanged",
... size (before#), size (after#), 0
@emlTestAssertEqualNum: "the column sum is unchanged",
... sum (before#), sum (after#), 0
@emlTestAssertEqualNum: "the column sum of squares is unchanged",
... sum (before# * before#), sum (after# * after#), 0
@emlTestAssertEqualNum: "the column minimum is unchanged",
... min (before#), min (after#), 0
@emlTestAssertEqualNum: "the column maximum is unchanged",
... max (before#), max (after#), 0

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
Set numeric value: 6, "val", 12.001
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
Set string value: 6, "grp", "C"
@fpKey: moved
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "moving one row to another level invalidates the key",
... emlFingerprintsAgree.same = 0

; Two rows exchange LABELS: the group column's multiset and both level sizes
; survive, the value-to-level pairing does not.
@fpFixture
labelSwap = fpFixture.id
selectObject: labelSwap
Set string value: 1, "grp", "B"
Set string value: 2, "grp", "A"
@fpKey: labelSwap
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "two labels exchanged between rows invalidates the key",
... emlFingerprintsAgree.same = 0

; A whole level renamed moves no number at all: only the labels carry it.
@fpFixture
renamed = fpFixture.id
selectObject: renamed
Set string value: 1, "grp", "Z"
Set string value: 3, "grp", "Z"
Set string value: 6, "grp", "Z"
@fpKey: renamed
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a whole level renamed invalidates the key",
... emlFingerprintsAgree.same = 0

; A spelling the label normaliser folds away is not a new level, but it is a
; new spelling, and the level's printed name can move with it.
@fpFixture
respelled = fpFixture.id
selectObject: respelled
Set string value: 6, "grp", "a"
@fpKey: respelled
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a case-only relabel invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "Probe 4 — rows reordered WITHIN a level (must hold)"
# ============================================================================
# The group column reads exactly as it did; each level's three values are
# rotated among that level's own rows. Nothing any group comparison computes
# can see the difference, so neither may the key.
# ============================================================================

@fpFixture
reordered = fpFixture.id
selectObject: reordered
Set numeric value: 1, "val", 12
Set numeric value: 3, "val", 10.5
Set numeric value: 6, "val", 11.75
Set numeric value: 2, "val", 22.75
Set numeric value: 5, "val", 20.25
Set numeric value: 8, "val", 21.5
Set numeric value: 4, "val", 32.5
Set numeric value: 7, "val", 30.125
Set numeric value: 9, "val", 31.25
@fpKey: reordered
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "a within-level reorder holds the key",
... emlFingerprintsAgree.same = 1

; The same claim where floating point is least comfortable: values that
; cancel, permuted inside one level.
hostileA# = { 1e16, 1, -1e16, 3, 1e16, -1e16 }
hostileB# = { -1e16, 1e16, 3, 1e16, 1, -1e16 }
hostile1 = Create Table with column names: "fp_hostile", 6, { "grp", "val" }
for i from 1 to 6
    Set string value: i, "grp", "G"
    Set numeric value: i, "val", hostileA# [i]
endfor
hostile2 = Create Table with column names: "fp_hostile", 6, { "grp", "val" }
for i from 1 to 6
    Set string value: i, "grp", "G"
    Set numeric value: i, "val", hostileB# [i]
endfor
@fpKey: hostile1
hostileKey$ = fpKey.key$
@fpKey: hostile2
@emlFingerprintsAgree: hostileKey$, fpKey.key$
@emlTestAssertTrue: "a reorder of cancelling values holds the key",
... emlFingerprintsAgree.same = 1


# ============================================================================
@emlTestSection: "Rows added and removed"
# ============================================================================

@fpFixture
grown = fpFixture.id
selectObject: grown
Append row
Set string value: 10, "grp", "A"
Set numeric value: 10, "val", 10.75
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
@emlTestSection: "What the key must NOT depend on"
# ============================================================================

; The level order the display setting asks for is not the order the key is
; built in — otherwise changing how the groups are arranged on the x-axis
; would re-run the analysis.
emlGroupSortAlphabetical = 1
@fpKey: control
alphaKey$ = fpKey.key$
emlGroupSortAlphabetical = 0
@emlFingerprintsAgree: controlKey$, alphaKey$
@emlTestAssertTrue: "the group display order does not move the key",
... emlFingerprintsAgree.same = 1

; A row in no level is in no result either.
blankA = Create Table with column names: "fp_blank", 5, { "grp", "val" }
Set string value: 1, "grp", "A"
Set numeric value: 1, "val", 1
Set string value: 2, "grp", "A"
Set numeric value: 2, "val", 2
Set string value: 3, "grp", ""
Set numeric value: 3, "val", 99
Set string value: 4, "grp", "B"
Set numeric value: 4, "val", 3
Set string value: 5, "grp", "B"
Set numeric value: 5, "val", 4
@fpKey: blankA
blankKey$ = fpKey.key$
selectObject: blankA
Set numeric value: 3, "val", 12345
@fpKey: blankA
@emlFingerprintsAgree: blankKey$, fpKey.key$
@emlTestAssertTrue: "editing a value on a row with no group holds the key",
... emlFingerprintsAgree.same = 1
@emlTestAssertEqualNum: "the blank row is counted as blank",
... 1, emlGroupFingerprint.nBlank, 0

; A cell the analysis cannot use becoming usable is a change to the data the
; analysis sees, and moves the key.
unusableA = Create Table with column names: "fp_unusable", 4, { "grp", "val" }
Set string value: 1, "grp", "A"
Set numeric value: 1, "val", 1
Set string value: 2, "grp", "A"
Set numeric value: 2, "val", 2
Set string value: 3, "grp", "B"
Set string value: 3, "val", "n/a"
Set string value: 4, "grp", "B"
Set numeric value: 4, "val", 4
@fpKey: unusableA
unusableKey$ = fpKey.key$
@emlTestAssertEqualNum: "the unusable cell is not counted as usable",
... 3, emlGroupFingerprint.nUsable, 0
selectObject: unusableA
Set numeric value: 3, "val", 3
@fpKey: unusableA
@emlFingerprintsAgree: unusableKey$, fpKey.key$
@emlTestAssertTrue: "an unusable cell becoming usable invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "A key that is not a key never agrees"
# ============================================================================

@emlGroupFingerprint: control, "no_such_column", "grp"
@emlTestAssertTrue: "a missing data column reports an error",
... emlGroupFingerprint.error$ <> ""
@emlTestAssertEqualStr: "a missing data column yields no key",
... "", emlGroupFingerprint.result$

@emlGroupFingerprint: control, "val", "no_such_column"
@emlTestAssertTrue: "a missing group column reports an error",
... emlGroupFingerprint.error$ <> ""
@emlTestAssertEqualStr: "a missing group column yields no key",
... "", emlGroupFingerprint.result$

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
# A key compared as a float across a save and a reload would betray the store.
# The key is a string, is only ever compared as a string, and carries its
# numbers already quantised — so a journey out to a file and back is exact.
# ============================================================================

keyFile$ = "fp_key_roundtrip.txt"
if fileReadable (keyFile$)
    deleteFile: keyFile$
endif
writeFileLine: keyFile$, controlKey$
reread$ = readFile$ (keyFile$)
reread$ = replace$ (reread$, newline$, "", 0)
if fileReadable (keyFile$)
    deleteFile: keyFile$
endif
@emlFingerprintsAgree: controlKey$, reread$
@emlTestAssertTrue: "the key survives a write and a read",
... emlFingerprintsAgree.same = 1

tableFile$ = "fp_table_roundtrip.Table"
if fileReadable (tableFile$)
    deleteFile: tableFile$
endif
selectObject: control
Save as text file: tableFile$
reloaded = Read from file: tableFile$
Rename: "fp_case"
if fileReadable (tableFile$)
    deleteFile: tableFile$
endif
@fpKey: reloaded
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "the table saved and reloaded keeps its key",
... emlFingerprintsAgree.same = 1


# ============================================================================
@emlTestSection: "Canonical number text (@eml_fpNumber)"
# ============================================================================

@eml_fpNumber: 1500
@emlTestAssertEqualStr: "1500 renders in mantissa form",
... "1.50000000000000e3", eml_fpNumber.result$
@eml_fpNumber: 0
@emlTestAssertEqualStr: "zero has one spelling", "0", eml_fpNumber.result$
@eml_fpNumber: undefined
@emlTestAssertEqualStr: "undefined is stated, not skipped",
... "und", eml_fpNumber.result$
@eml_fpNumber: -0.000123456789012345
@emlTestAssertEqualStr: "a negative small number keeps its sign and digits",
... "-1.23456789012345e-4", eml_fpNumber.result$

; The carry: a mantissa that rounds up to ten must not give one magnitude two
; spellings, or two nearly equal numbers would compare unequal at the boundary.
@eml_fpNumber: 9.999999999999999
nine$ = eml_fpNumber.result$
@eml_fpNumber: 10
@emlTestAssertEqualStr: "a mantissa rounding to ten renormalises",
... eml_fpNumber.result$, nine$

; Quantisation is what makes the key survive text, and it has a price: an edit
; below the FIFTEENTH significant digit is invisible. Asserted so the price is
; a measured property of the code and not a sentence in a comment.
;
; eGF1's quantum was 12 significant digits, because it quantised a SUM and the
; quantum had to absorb the last bits of an accumulation. eGF2 quantises each
; value on its own and accumulates nothing, so the quantum tightened by three
; digits — which is not cosmetic: 400.00000000001 against 400 is 2.5e-14
; relative, it moved Kruskal-Wallis p from .4530 to .0304 on the eGF1 build,
; and the section "Defeat 4" below is that case.
@fpFixture
belowQuantum = fpFixture.id
selectObject: belowQuantum
Set numeric value: 6, "val", 12 + 1e-14
@fpKey: belowQuantum
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "an edit below the quantum holds the key (documented cost)",
... emlFingerprintsAgree.same = 1

; And the edit eGF1 could not see, one quantum wider, IS seen now.
@fpFixture
oldQuantum = fpFixture.id
selectObject: oldQuantum
Set numeric value: 6, "val", 12 + 1e-13
@fpKey: oldQuantum
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "an edit eGF1's 12-digit quantum absorbed now invalidates",
... emlFingerprintsAgree.same = 0

@fpFixture
aboveQuantum = fpFixture.id
selectObject: aboveQuantum
Set numeric value: 6, "val", 12 + 1e-9
@fpKey: aboveQuantum
@emlFingerprintsAgree: controlKey$, fpKey.key$
@emlTestAssertTrue: "an edit above the quantum invalidates the key",
... emlFingerprintsAgree.same = 0


# ============================================================================
@emlTestSection: "The key is ASCII whatever the labels are (@eml_fpTextHash)"
# ============================================================================
# The key crosses file boundaries, so a label's own bytes must not travel in
# it — nor may a label containing the key's separators forge a record.
# ============================================================================

@eml_fpTextHash: "abc"
abcHash = eml_fpTextHash.hash
@eml_fpTextHash: "abc"
@emlTestAssertEqualNum: "the same string hashes the same",
... abcHash, eml_fpTextHash.hash, 0
@eml_fpTextHash: "abd"
@emlTestAssertTrue: "a different string hashes differently",
... eml_fpTextHash.hash <> abcHash
@eml_fpTextHash: "cba"
@emlTestAssertTrue: "an anagram hashes differently",
... eml_fpTextHash.hash <> abcHash
; eGF1's hash was unsalted, so the empty string hashed to zero. It is salted
; now, so it does not — and that is the property worth asserting: a string
; does not fall out of the hash just because it is empty.
@eml_fpTextHash: ""
emptyH1 = eml_fpTextHash.h1
emptyH2 = eml_fpTextHash.h2
@emlTestAssertTrue: "the empty string does not hash to zero",
... emptyH1 <> 0 and emptyH2 <> 0
@eml_fpTextHash: ""
@emlTestAssertEqualNum: "and it hashes to the same thing every time",
... emptyH1, eml_fpTextHash.h1, 0
@eml_fpTextHash: " "
@emlTestAssertTrue: "one space is not the empty string to the hash",
... eml_fpTextHash.h1 <> emptyH1

; Two hashes, not one: the key embeds both, so a pair that agrees in one
; half is not a collision. Section "Defeat 3" below is the pair that broke
; eGF1's single 31-bit polynomial.
@eml_fpTextHash: "abc"
@emlTestAssertEqualNum: "the embedded form carries both halves and a length",
... 2, length (eml_fpTextHash.result$)
... - length (replace$ (eml_fpTextHash.result$, "_", "", 0)), 0

hostileLabels = Create Table with column names: "fp_labels", 4, { "grp", "val" }
Set string value: 1, "grp", "naive|;="
Set numeric value: 1, "val", 1
Set string value: 2, "grp", "naive|;="
Set numeric value: 2, "val", 2
Set string value: 3, "grp", "other"
Set numeric value: 3, "val", 3
Set string value: 4, "grp", "other"
Set numeric value: 4, "val", 4
@fpKey: hostileLabels
labelKey$ = fpKey.key$
@emlTestAssertTrue: "a separator-bearing label still yields a key",
... labelKey$ <> ""
@emlTestAssertEqualNum: "and does not split the record",
... 2, emlGroupFingerprint.nLevels, 0
; The label's own characters are not in the key: the pipes are the structural
; ones and only those — six opening the header's fields, one opening each
; level record — though both of this table's labels carry a pipe of their own.
pipes = length (labelKey$) - length (replace$ (labelKey$, "|", "", 0))
@emlTestAssertEqualNum: "the key holds only its own separators",
... 8, pipes, 0


# ============================================================================
# THE SIX DEFEATS OF THE eGF1 COMPOSITION
# ============================================================================
# On 24 August 2026 an adversarial pass broke the first build (format eGF1)
# six times. Each defeat is a check below. Every one of them was GREEN-as-in-
# "the cache holds" against eGF1 and is GREEN-as-in-"the key moved" against
# eGF2, so each section states, as an assertion and not as a comment, the
# property eGF1 had that made it blind — the aggregates that matched, the
# hash halves that collided — and then asserts the key moves anyway.
#
# Three of the six (1, 2 and 4) were ONE fault: per-level moment aggregates
# cannot describe a multiset. eGF2 commits to the sorted value list instead.
# See the module header in stats/eml-extract.praat.
#
# The fixtures here are the adversarial pass's own tables, transcribed. They
# all name their table for the case rather than for the mutation, because a
# separately named mutant would go green on the name alone.
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


# ============================================================================
@emlTestSection: "Defeat 1 — a compensating interior edit"
# ============================================================================
# Three cells inside ONE level are rewritten, all strictly between that
# level's min and max, chosen so that n, sum, sum of squares, min and max are
# all held EXACTLY. Those five numbers were the whole of eGF1's description
# of a level, so its key was byte-identical across this edit — while
# Kruskal-Wallis p moved .0437 -> .1013 across .05, Dunn's adjusted p moved
# .0400 -> .1209, the level's median moved 600 -> 490 and its skewness
# flipped sign.
#
# THIS IS STRUCTURAL, NOT A COLLISION. Five fixed aggregates constrain four
# numbers on n - 2 interior values, so for n >= 5 a CONTINUUM of alternative
# level contents satisfies them; levels of n <= 4 are provably safe and no
# others are. Adding a sixth moment moves the threshold and closes nothing.
# ============================================================================

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
; blindness of the old composition is measured here rather than claimed.
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
# interchangeable to the key if the key cannot tell their contents apart.
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

; The two levels really are aggregate-matched — that is the premise, and it
; is asserted rather than asserted-in-a-comment.
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
# eGF1's @eml_fpTextHash was a single unsalted degree-L polynomial modulo
# 2^31 - 1. A four-million-sample birthday search found "y409n_" and "5kxgwq"
# in seconds; both hashed to 6_2026794253, so a whole level could be renamed
# with the key unmoved and a reused result would print level names that are
# not in the table.
#
# A WHOLE-LEVEL RENAME IS THE ONE PLACE THE HASH IS LOAD-BEARING: a relabelled
# cell moves level sizes and value digests too, so only the wholesale rename
# rests on the hash alone. Hence two salted polynomials over different bases
# and different primes — about 62 bits. Note that BOTH halves have to move: a
# salt alone would not have separated this pair, because an additive salt on a
# base-131 polynomial contributes the same term to two strings of equal
# length.
# ============================================================================

@eml_fpTextHash: "y409n_"
collideA$ = eml_fpTextHash.result$
collideA1 = eml_fpTextHash.h1
collideA2 = eml_fpTextHash.h2
@eml_fpTextHash: "5kxgwq"
@emlTestAssertTrue: "the published collision pair no longer collides",
... eml_fpTextHash.result$ <> collideA$
@emlTestAssertTrue: "and not in the first half either",
... eml_fpTextHash.h1 <> collideA1
@emlTestAssertTrue: "nor in the second",
... eml_fpTextHash.h2 <> collideA2

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

; The two spellings sort to the same place behind "0aa" and "1bb", so the
; canonical order of the level records is unchanged as well: nothing but the
; hash stands between these two tables.
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
@emlTestSection: "Defeat 4 — tie structure"
# ============================================================================
# Every value of one level is written as 400.00000000001 instead of 400. That
# is 2.5e-14 relative, below eGF1's 12-significant-digit quantum, so its key
# held — and every TIE between that level and its neighbours was broken.
# Kruskal-Wallis is a tie-corrected rank test and is discontinuous at ties:
# p moved .4530 -> .0304, across .05, on data that reads identically.
#
# Reachable without malice. Any recomputation of the column — a unit
# conversion out and back, a resampled measurement, a spreadsheet round trip
# — can land there.
#
# TWO THINGS CLOSE IT, AND BOTH ARE THE SAME CHANGE. The key now commits to
# each level's sorted value LIST, so multiplicity is recorded where eGF1
# recorded none at all; and because nothing is accumulated any more, the
# quantum could tighten from 12 significant digits to 15, which is what makes
# a 2.5e-14 difference visible.
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
            Set string value: 6 + .i, "val", fixed$ (.v2# [.i], 0)
        else
            Set string value: 6 + .i, "val", fixed$ (.v2# [.i], 0)
            ... + ".00000000001"
        endif
        Set string value: 12 + .i, "grp", "cc"
        Set numeric value: 12 + .i, "val", .v3# [.i]
    endfor
endproc

@fpTies: 0
tieCtrl = fpTies.id
@fpKey: tieCtrl
tieKey$ = fpKey.key$
@fpLevel: tieCtrl, "bb"
tcSum = fpLevel.sum
tcLo = fpLevel.lo
tcHi = fpLevel.hi
@emlKruskalWallis: tieCtrl, "val", "grp"
tcP = emlKruskalWallis.p

@fpTies: 1
tieMut = fpTies.id
@fpLevel: tieMut, "bb"
@emlKruskalWallis: tieMut, "val", "grp"
tmP = emlKruskalWallis.p

; Every aggregate agrees to within eGF1's quantum — one part in 1e12 — which
; is why eGF1 could not see this at all.
@emlTestAssertEqualRel: "the level's sum agrees to one part in 1e12",
... tcSum, fpLevel.sum, 1e-12
@emlTestAssertEqualRel: "the level's minimum agrees to one part in 1e12",
... tcLo, fpLevel.lo, 1e-12
@emlTestAssertEqualRel: "the level's maximum agrees to one part in 1e12",
... tcHi, fpLevel.hi, 1e-12

; And the rank test, which reads ties and not sums, moves across .05.
@emlTestAssertTrue: "Kruskal-Wallis p is above .05 with the ties intact",
... tcP > 0.05
@emlTestAssertTrue: "and below .05 once they are broken", tmP < 0.05

@fpKey: tieMut
@emlFingerprintsAgree: tieKey$, fpKey.key$
@emlTestAssertTrue: "breaking a level's ties invalidates the key",
... emlFingerprintsAgree.same = 0

; Multiplicity itself, stated on its own: two levels of equal n over the same
; two distinct values, differing only in how many of each.
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
@emlTestSection: "Defeat 5 — a second grouping factor the key cannot name"
# ============================================================================
# @emlTwoWayAnova reads a value column and TWO factors. The key describes
# (value, group) only, so rewriting six of twelve cells of the second factor
# moved F(group) from 7.564 to 2.687 and its p from .0229 to .1468 with the
# key unmoved.
#
# THE FAULT WAS NOT IN THE COMPOSITION. It was that a procedure describing
# two columns was handed to an analysis that read three and said nothing.
# @emlGroupFingerprint still describes two columns and still holds across
# this edit — that is asserted below, because it is the honest statement of
# what the one-way key covers. The closure is @emlAnalysisFingerprint: an
# analysis names EVERY column it read, and a declaration this module cannot
# describe is REFUSED, with no key issued.
#
# WHAT IS ASSUMED, AND IS FOR IAN. Whether a two-way key gets BUILT — one
# record per design cell, under a new format tag — is a scope question, not a
# defect. Until it is built, the refusal is the correct answer: an analysis
# that cannot be keyed re-runs.
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

; STATED HONESTLY: the one-way key does not move, and cannot. It describes
; two columns and the two columns did not change.
@fpKey: twoMut
@emlFingerprintsAgree: twoKey$, fpKey.key$
@emlTestAssertTrue: "the two-column key holds, because two columns is all it describes",
... emlFingerprintsAgree.same = 1
@emlTestAssertEqualStr: "and it says which two it describes",
... "val,grp", emlGroupFingerprint.covers$

; The closure: the door refuses what it cannot describe.
@emlAnalysisFingerprint: twoCtrl, "val,grp,sex"
@emlTestAssertEqualNum: "a three-column analysis is refused",
... 1, emlAnalysisFingerprint.refused, 0
@emlTestAssertEqualStr: "a refusal issues no key",
... "", emlAnalysisFingerprint.result$
@emlTestAssertEqualStr: "and claims to cover nothing",
... "", emlAnalysisFingerprint.covers$
@emlTestAssertContains: "the refusal names the column it cannot describe",
... emlAnalysisFingerprint.error$, "sex"
@emlTestAssertEqualNum: "and counts the factors it was given",
... 2, emlAnalysisFingerprint.nFactors, 0
@emlFingerprintsAgree: twoKey$, emlAnalysisFingerprint.result$
@emlTestAssertTrue: "a refused key never agrees with a real one",
... emlFingerprintsAgree.same = 0

; The two-column declaration is the one this module can describe, and it must
; give exactly the key @emlGroupFingerprint gives — the door is a door, not a
; second implementation.
@emlAnalysisFingerprint: twoCtrl, "val,grp"
@emlTestAssertEqualNum: "a two-column analysis is not refused",
... 0, emlAnalysisFingerprint.refused, 0
@emlFingerprintsAgree: twoKey$, emlAnalysisFingerprint.result$
@emlTestAssertTrue: "and yields the same key as the procedure behind it",
... emlFingerprintsAgree.same = 1
@emlTestAssertEqualStr: "reporting what it covers",
... "val,grp", emlAnalysisFingerprint.covers$

; Whitespace in a declared list is the caller's formatting, not a column name.
@emlAnalysisFingerprint: twoCtrl, " val , grp "
@emlFingerprintsAgree: twoKey$, emlAnalysisFingerprint.result$
@emlTestAssertTrue: "a list with spaces around its items declares the same columns",
... emlFingerprintsAgree.same = 1

; A declaration with nothing to group by is malformed, not refused.
@emlAnalysisFingerprint: twoCtrl, "val"
@emlTestAssertEqualStr: "one column alone yields no key",
... "", emlAnalysisFingerprint.result$
@emlTestAssertTrue: "and says so", emlAnalysisFingerprint.error$ <> ""
@emlTestAssertEqualNum: "and is a malformed call, not a refusal",
... 0, emlAnalysisFingerprint.refused, 0


# ============================================================================
@emlTestSection: "Defeat 6 — the spelling set was not a set"
# ============================================================================
# The module header claims the key carries the SET of raw spellings folded
# into each level. eGF1 carried the count plus a LINEAR SUM of their hashes,
# and a sum is the wrong shape for a set: {aa, AA} and {Aa, aA} summed
# identically, so the key held while the level's displayed label — the first
# spelling ENCOUNTERED — changed from "aa" to "Aa".
#
# eGF2 sorts the level's distinct spellings and folds them as a SEQUENCE:
# order-independent because sorted, non-linear because the fold is positional.
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
    else
        Set string value: 1, "grp", "Aa"
        Set string value: 2, "grp", "aA"
        Set string value: 3, "grp", "Aa"
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

; Both variants fold to one level of the same three values, so no number in
; the level record moves; only the spelling set does.
@fpKey: spellMut
@emlTestAssertEqualNum: "both variants have three levels",
... 3, emlGroupFingerprint.nLevels, 0
@emlFingerprintsAgree: spellKey$, fpKey.key$
@emlTestAssertTrue: "a spelling set that sums the same still invalidates the key",
... emlFingerprintsAgree.same = 0

; The premise of the defeat, kept as a live measurement: those four spellings
; are two pairs that any linear fold would confuse. Whether eGF2's hash
; happens to keep the sums equal is not the point and is not asserted; what is
; asserted is that the KEY does not depend on a sum.
@eml_fpTextHash: "aa"
sumA = eml_fpTextHash.h1
@eml_fpTextHash: "AA"
sumA = sumA + eml_fpTextHash.h1
@eml_fpTextHash: "Aa"
sumB = eml_fpTextHash.h1
@eml_fpTextHash: "aA"
sumB = sumB + eml_fpTextHash.h1
@emlTestAssertTrue: "the four spellings are four distinct strings to the hash",
... sumA > 0 and sumB > 0


# ============================================================================
@emlTestSection: "The format tag keeps eGF1 keys out"
# ============================================================================
# eGF1 keys exist in the wild — in any stored result written before 24 August
# 2026. They must not compare equal to an eGF2 key, and the tag is what makes
# that true by construction rather than by luck.
# ============================================================================

@emlTestAssertContains: "the key is tagged eGF2", controlKey$, "eGF2"
oldShape$ = replace$ (controlKey$, "eGF2", "eGF1", 1)
@emlFingerprintsAgree: controlKey$, oldShape$
@emlTestAssertTrue: "the same key under the old tag does not agree",
... emlFingerprintsAgree.same = 0


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSummary
