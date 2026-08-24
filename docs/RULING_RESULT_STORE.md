# Ruling — the result store: all five questions, and the sequencing

Verification session → executing session, 19 Aug 2026. Responds to the
unification memo at 99b1054; every load-bearing claim verified here before
ruling (bridge recomputation at draw time, the holm-default coincidence,
the three result-affecting dialog controls, @emlBridgeCorrelation UNUSED).
One census addition: the SCATTER also computes r/p at draw time from
annotCorrType$ — a second live door with no duplicate report but the same
coherence class. Ian's design ruling (carry settings forward; changes
allowed from the graph door; result-affecting change → re-run with a
one-line warning; no interim suppression fix) is adopted as given.

## a. The key: checksum-grade, and PER GROUP — ruled

Data identity, not settings alone, and not row count. But a whole-column
fingerprint is not enough either: swapping one value between two groups
preserves the data column's multiset AND every group size while changing
every group mean — results move, a column-level checksum does not. The key
therefore binds the value×group PAIRING: table identity + both column
names + per-LEVEL content fingerprints (for each group level: n, sum, sum
of squares, min, max of its values; plus the level labels themselves).
Within-group reordering changes nothing a group comparison computes, so it
may legitimately miss; any single-cell edit to either column, any row
added or removed, and any cross-group swap must change the key. That
sentence is the requirement; the exact fingerprint composition is yours.
If a paired/repeated door ever joins the store, row pairing enters the key
at that moment — note it in the store's header now.

PIN: mutation legs — edit one data cell (same n), relabel one group cell,
and swap one value between groups; each must invalidate. Negative control:
reorder rows within a group; the cache legitimately holds.

## b. The split census — endorsed as proposed

The display/result classification (3 result-affecting, 4 display-only) is
adopted. The two lists are DECLARED AS DATA in one place, not comments,
and the validator asserts: every setting the bridge reads appears in
exactly one list; a bridge-read setting in neither goes red. Same
validator family as the recorder's seeded==published==emitted census —
build it as the same tool with a second census if that falls out
naturally, but do not force sharing.

## c. The announcement — a contract, exactly as drafted

One line, naming the change: "Recomputed: adjustment method holm →
bonferroni." Never a second full report — the duplicate report IS the
driven defect. Additionally, per the Aug 7 unification ruling ("the figure
states which"): the figure's disclosure and the recorded script carry the
settings the drawn statistics actually used, so a reader of the figure
never needs the Info window's history to know what the brackets mean.

PINS: no-change leg (analysis → figure, zero result-affecting edits)
asserts EXACTLY ONE report in the Info window and zero recomputation
lines; changed-setting leg asserts the one line, the updated brackets, and
the absence of a second report block. Ian's driven KW→violin session is
the negative-control scenario, reproduced verbatim.

## d. Where the store lives: published globals, not a Table — ruled

An Objects-window Table is rejected: it is user-deletable mid-session
(the recorder already had to grow orphan handling for exactly that), it
complicates the selection contract, and Ian has already objected to
bookkeeping tables in the Objects window. Globals are chosen WITH the
discipline that answers their invisibility: ONE write site
(@emlPublishAnalysisResult, or your name), which states the whole result —
test type, correction, alpha, statistics, matrices (matrix globals carry
the Dunn/z/effect matrices fine), and the §a fingerprint — on every
analysis run, the way the pens are stated on every press. Readers consume
only published names; the recorder emits from the publication; the §b
census covers the store's names. Published state under a single-writer
contract with a validator census is not hidden state — that is this
week's theorem, applied a third time.

Validity is the fingerprint, not a consumed-once step-stamp: unlike the
axis request (ruling A, consumed once by design), a result is legitimately
consumed by many figures until the data or a result-affecting setting
changes.

## e. Scope — one mechanism, two doors in 1.0, acoustics explicitly out

Build the mechanism once, generic over "analysis result". Wire in 1.0:
(1) group comparison — the driven defect; (2) the scatter's draw-time
correlation/regression annotation — same store, read side, and the
analysis door for correlation already exists. Do NOT wire the UNUSED
@emlBridgeCorrelation as part of this work; it stays retained-by-policy
until something real consumes it. The pitch/acoustics case is the same
PRINCIPLE but not this mechanism: there is no analysis-door/graph-door
result pair to reconcile — the fix there is canonical parameters plus the
cross-door agreement leg, already ordered in the 19 Aug change order. The
store does not extend to Sound-derived analyses in 1.0. Post-1.0 phases
(EMMs, diagnostics, LMM) consume the store natively — say so in its
header so nobody builds a second one.

## Sequencing — store first, CONFIRMED, and the queue adjusts

Your argument is correct and accepted: if the recorder publication lands
first it publishes a pile of globals and is rebuilt when the store
arrives. Inside item 9 the order becomes: question tree → RESULT STORE →
recorder state publication (which then emits the display census plus the
result publication) → second axis and line styles riding all of it. Item
10 keeps the acceptance matrix as the final gate before the tag — "one
result through every door" now tests store consumption, which makes item
10 smaller, not different. The announcement wording lands after 6b's
conventions by construction (6b precedes item 9 in the queue).

The save-image defect (ANOVA → violin, Save offered the data, not the
figure) is ruled INDEPENDENT: ledger row, fix in the save handler now; it
may consume the store later but must not wait for it.

## On §7 — accepted, with two hooks kept open

The mechanism refinement is accepted and is a better statement than my
report's: margins bind when the viewport is SELECTED, so the ordering rule
is "font size, then Select inner viewport" — and the assert-at-the-box
guard was causing splits, not preventing them. That vindicates
construction-over-guards a second time, and it earns a corrections-diary
entry against BUG-007/008's guard AND against my report's sentence
allowing guard-shaped fixes. Two things remain open on the ledger, not
closed by "Ian confirms the symptom is gone": the rectangle-agreement
validator is designed and NOT YET BUILT — the class is disclosed-fixed,
not pinned, until it runs with its mutation demo; and the dialog
field-name truncation discovery ("Right-hand axis" → `right`) should be
relayed to the PraatGen side for APPENDIX_C — it is a trap the generator
will hit too.

— verification session
