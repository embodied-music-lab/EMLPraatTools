# Ruling — dialog compaction by label/variable decoupling

Verification session → executing session, 19 Aug 2026, on Ian's authority.
Ian's ruling: reclaiming vertical space in the draw-path dialogs is
sanctioned work, and a variable REMAP after each form is the sanctioned
mechanism — labels are chosen for UI economy, and a remap block
immediately after endPause copies each derived name to the canonical
variable the code reads. This REVERSES the verification session's earlier
"no label sweep" recommendation, correctly: that recommendation's ripple
objection (renames cascading into commit sites, prev_ mirrors, recorded
scripts, harness pins) dissolves under decoupling, because the canonical
names never change. Labels become presentation; variables stay API.

## The mechanism

1. Every dialog page ends with its REMAP BLOCK, directly after endPause,
   before any commit logic: one assignment per field whose label-derived
   name differs from its canonical name. Nothing downstream of the remap
   ever reads a label-derived name.
2. Canonical names are FROZEN. Compaction changes labels and remaps; it
   never changes what the commit sites, the recorder, the result store,
   or the harnesses read.
3. Derived-name distinctness is still required PER RENDERED BRANCH
   COMBINATION (the constraint Praat imposes), not per flat page listing
   — the field inventory flattens branches, and both "duplicates" it
   flagged (the Annotate elsif pair, the line chart's two Y-label
   branches) are verified-deliberate branch alternatives sharing a name.

## The toolbox (verified against PKB APPENDIX_C §C.1 and this week's probes)

- **Row pairing:** the left/right prefix puts two boxes on one row for
  ANY numeric type (real/positive/integer/natural), showing the label
  remainder once. Sanctioned beyond ranges for any HONEST pair:
  `left Figure size (w × h, in)` / `right Figure size` → one row, remap
  to figure_width/figure_height; same for panel origin x/y; candidates
  like bin count + frequency max only where the shared label reads as a
  true pair — no smuggling two unrelated settings under one noun. Trap
  on record: a label of exactly "left" or "right" shadows Praat's
  predefined constants; the remainder is never empty.
- **Range labels shed their redundant suffix:** "left Time range
  (left/right)" becomes "left Time (s)" — the two-box rendering already
  states the pairing, the heading states "0 = auto". Rows unchanged,
  label column narrower, headings shorter.
- **Heading economy:** one axes heading per page ("📐 Axes — every range:
  0 = auto") replaces the per-axis pair of headings. The markup legend
  comment appears only on pages with visible label fields (already
  mostly true — verify per page).
- **Booleans do not pair.** The four-row Show cluster has three options,
  IAN TO PICK ONE: (a) gate it behind the existing Advanced toggle where
  it is not already; (b) collapse to a single "Frame" optionmenu of
  presets (Full / No box / Ticks only / Bare), remapped to the four
  canonical flags — the one proposal here that changes interaction
  semantics, so it is flagged rather than ruled; (c) leave the four
  rows. Everything else in this ruling is decided.

## The validator (extends conformance check 11 — this is the pin)

Per page, per rendered branch combination: (1) derived names distinct;
(2) every derived name is either already canonical or consumed by EXACTLY
ONE remap assignment; (3) every canonical name the page's commit logic
reads is produced by exactly one of {field, remap, deliberate branch
share}. The field inventory becomes this check's fixture, committed AS A
GENERATED ARTIFACT with its generator and regenerated when pages change —
hand-maintained inventories drift exactly like the recorder's
hand-maintained capture lists did. Mutation demonstrations: delete one
remap line → red; render two same-named fields in one branch → red.

## Sequencing

The question-tree pages are BORN compact — the tree rebuild implements
this ruling natively rather than being compacted afterward. Every other
page is compacted inside the graphing round, in the same commit as work
already touching it where possible; gui_e2e-class harnesses that address
fields by label redrive ONCE, with the page's other item-9 changes.

DONE WHEN: per-page row counts (fields + headings) are reported
before/after; each compacted page's rendered height is confirmed
unclipped under the Xvfb drive at default window size; the check-11
extension is green with its mutation demos recorded; and one recorded
workflow driven through a compacted page replays byte-identically —
demonstrating the decoupling held and no canonical name moved.

— verification session
