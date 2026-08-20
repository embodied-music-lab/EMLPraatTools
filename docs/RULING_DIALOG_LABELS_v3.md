# Ruling v3 — per-form labels: icons retained, collisions worked through, pairing probed

Verification session → executing session, 19 Aug 2026. SUPERSEDES v1 and
v2. Ian's corrections carried: icon headings STAY (and icons cannot move
into field labels — measured below: an emoji-led label binds under an
unreachable name like `📐_Spread`); collisions worked through below;
booleans OUT OF SCOPE entirely.

## NEW — pairing mechanics probed live (6.6.30 under Xvfb, bindings verified)

1. SENTENCE FIELDS PAIR. left/right sentence fields render one row, two
   text boxes, both $ variables bound. (PKB C.1 says numeric-only — a
   PKB correction to relay with today's probe.) Consequence adopted
   below: X + Y axis label = ONE ROW on every page. (Title + Subtitle
   WITHDRAWN by Ian — see the pairing-legitimacy rule below.)
2. MIXED REMAINDERS PAIR, displaying the LEFT field's remainder only;
   the right field's label is never shown. Consequence: compound rows
   are mechanically available — two unrelated numbers on one row —
   PROVIDED both fields carry the same compound remainder that names
   both boxes in order ("Bins and max frequency (0 = auto each)"). Where
   compound rows are offered below they are flagged IAN'S CALL, since
   the label carries the whole burden of honesty.
3. BOOLEANS DO NOT PAIR (left/right renders verbatim as two checkbox
   rows). Out of scope regardless; boolean labels must never begin with
   left/right.
4. Cosmetic note for Opus: paired boxes render at unequal widths (left
   narrower); acceptable, but check nothing clips at default width.

## The derivation law, MEASURED (supersedes every earlier statement)

Stress-probed live, 6.6.30 under Xvfb, 19 Aug. Praat's actual rule:
strip the label from the first "(" onward, convert spaces to
underscores, and KEEP EVERY OTHER CHARACTER VERBATIM in the stored
variable name. Three consequences, each demonstrated:

1. **Parentheticals never disambiguate.** "left Value (bottom/top)" and
   "left Value (left/right)" both derive left_Value: the probe rendered
   both rows correctly and silently bound only the last (111/222
   discarded, 333/444 kept). Uniqueness is judged on the derivation
   prefix, per rendered branch combination.
2. **Any pre-parenthetical character outside letters/digits/spaces
   creates a BOUND-BUT-UNREACHABLE variable.** Measured stored names:
   `left_Y-limits`, `left_Title_/_subtitle$`, `📐_Spread` — all exist,
   none referenceable. Worst case demonstrated: with bystanders
   limits=100 and left_Y=1 in scope, the user typed 5 into a "left
   Y-limits" box and code reading `left_Y-limits` got **-99** — silent
   subtraction, no error. (This also corrects the earlier
   "truncates at the first non-word character" statement, mine and the
   5da802c pin's phrasing alike — the fix there was right, the stated
   mechanism was not; corrections-diary entry due.)
3. **THE LABEL CHARACTER LAW:** before the parenthetical, field labels
   use letters, digits, and spaces ONLY (plus the leading left/right
   pairing word). Everything decorative lives inside the parenthetical.

Check-11 therefore asserts BOTH: prefix uniqueness per rendered branch,
AND no pre-parenthetical character outside [A-Za-z0-9 ] in any field
label. Red demonstrations: the same-noun two-range script, and the -99
trap script — both render clean and lose user input.

## The heading pattern (revised)

- Every icon heading stays. Savings come from MERGING the two per-axis
  icon headings into one — "📐 Axes (both 0 = auto)" — which keeps the
  icon, keeps "both" verbatim, and saves one row on every two-range page.
- With the heading carrying "both 0 = auto", each range row carries its
  orientation only: `Time (left/right)`, `Value (bottom/top)`.
- Plain-text info headings (ceiling-doubled, matrix-panel, composition
  guidance) stay; the three-line composition heading on EML Graphs
  compresses to two lines.

## Row patterns

    RANGE:  left Time (left/right)   -> left_Time    remap left_Time_range
            left Value (bottom/top)  -> left_Value   remap left_Value_range
    PAIR:   left Figure size (w × h, inches) -> left_Figure_size
            remap figure_width / figure_height
    PAIRING LEGITIMACY (Ian, 19 Aug): the two-box row is visual grammar
            for a pair of LIKE, SYMMETRIC, SHORT values — a range,
            coordinates, dimensions. Title/subtitle fails it (unlike
            kinds, long free text) and stays two full-width rows.
            Axis labels pass (same kind, symmetric, short).
    LABELS: left Axis labels (x / y; blank = auto)   [sentence pair]
            right Axis labels (x / y; blank = auto)
            rendered: one row, two boxes; remap x_axis_label$ /
            y_axis_label$. The markup-legend heading stays above it.
            VERIFIED END-TO-END with this exact label text.
    SECOND AXIS (wherever the tree surfaces it): the noun is "Second
            axis" — left Second axis (bottom/top) -> left_Second_axis —
            never bare "Range", which collides the moment the pair
            co-renders with any other unqualified range.
    COMPOUND (available, IAN'S CALL per use): two numbers, one row, the
            shared remainder naming both boxes in order — e.g.
            left Bins and max frequency (0 = auto each) →
            left_Bins_and_max_frequency, remapped. ("and", not "·" —
            the middle dot survives into the stored name and makes it
            unreachable; measured.) Offered only for the histogram
            below; nowhere else proposed.

The LABELS pair applies to EVERY page that today carries X axis label +
Y axis label as two rows: one row saved on all of them, in addition to
the per-page changes listed below (v2 counts updated in place).
Additionally on the stat pages' ADVANCED branch, the current stacked
"Value maximum" / "Value minimum" rows (source order max-above-min)
become the same RANGE row the beginner branch already uses — one more
row saved there, and min/max reading order fixed.

## Per form

**EML Graphs (12 → 9):** composition heading 3 lines → 2; PAIR Figure
size; PAIR Panel origin (left Panel origin (x/y, inches) →
panel_origin_x/y). Title and Subtitle stay TWO full-width rows — not a
pair (unlike kinds, long free text; Ian's ruling). All other fields
unchanged.

**Pitch Contour (20 → 17):** merge "⏱️ Time" + "📐 Frequency" headings →
"📐 Axes (both 0 = auto)"; keep "🎵 Pitch analysis (auto-converted from
Sound)" and the ceiling-doubled line; RANGE Time, RANGE Frequency; PAIR
left Pitch (floor/ceiling, Hz) → pitch_floor/pitch_ceiling (the search
range is an honest pair); LABELS pair. Everything else unchanged.

**Waveform (16 → 14):** merged axes heading; RANGE Time, RANGE
Amplitude; LABELS pair.

**Spectrum (16 → 14):** merged axes heading; RANGE Frequency
(left/right), RANGE Power (bottom/top); LABELS pair.

**LTAS (20 → 18):** as Spectrum; "🎨 Drawing methods" heading STAYS.

**Bar / Violin / Box (advanced 26 → 24):** headings all stay ("📋",
"📐 Y-axis (both 0 = auto)", "📈"). RANGE Value (bottom/top) replaces
the advanced branch's stacked max/min rows (−1); LABELS pair (−1). No
other changes.

**Histogram (32 → 30, or 29 with the compound):** headings stay; RANGE
Value (−1); LABELS pair (−1); OPTIONAL COMPOUND left Bins and max
frequency (0 = auto each) → bin_count/frequency_maximum (−1 more) —
IAN'S CALL; their singleton "0 = auto" (no "both") stays correct
either way.

**Grouped Violin / Grouped Box (28 → 26 each):** headings stay; RANGE
Value (−1); LABELS pair (−1).

**Scatter (28 → 27):** headings stay ("📐 Axis (both 0 = auto)" already
covers both ranges — no merge available); RANGE left X (left/right),
left Y (bottom/top) — X and Y are the nouns precisely because "Range
(x axis)"-style labels collide; LABELS pair (−1).

**Spaghetti (22 → 21):** headings stay; RANGE Value; LABELS pair (−1);
teaching parentheticals kept.

**Line Chart pages:** the tree's dialogs are born under these rules —
merged axes heading, RANGE pattern, Second-axis noun, prefix-uniqueness
per rendered branch.

## Scope

Boolean fields are OUT OF SCOPE for this ruling by Ian's direction: no
gating, no collapsing, no relocation — they render exactly as they do
today, labels unchanged. This ruling changes range rows, honest numeric
pairs, and headings only. (The compaction ruling's Show-cluster options
are likewise withdrawn from consideration.)

## Prefix audits (per rendered page, pairing word included)

    EML Graphs: graph_type, title$, subtitle$, color_mode,
      left/right_Figure_size, erase_page_first,
      left/right_Panel_origin ✔
    Pitch: left/right_Time, left/right_Frequency, left/right_Pitch,
      y_axis_unit, line_style, gridline_mode, output_DPI, show_inner_box,
      show_axis_names, show_ticks, show_axis_values, font,
      left/right_Axis_labels$ (→ x/y_axis_label$) ✔  [same on every page
      that adopts the LABELS pair]
    Waveform: left/right_Time, left/right_Amplitude + furniture ✔
    Spectrum/LTAS: left/right_Frequency, left/right_Power + furniture
      (+ show_curve, show_bars, show_poles, show_speckles on LTAS) ✔
    Stat pages: left/right_Value sole range; annotation cluster and
      column fields unchanged, no new prefixes ✔
    Scatter: left/right_X, left/right_Y vs x_column, y_column — distinct
      (the pairing word is part of the name) ✔
    Second axis: left/right_Second_axis — collides with nothing ✔
    Histogram compound (if taken): left/right_Bins — collides with
      nothing ✔

Row accounting to verify against rendered pages under Xvfb:
12→9, 20→17, 16→14 ×2, 20→18, advanced 26→24 ×3, 32→30 (29 with the
compound), 28→26 ×2, 28→27, 22→21. Branches that add rows (advanced,
preset-annotate) report their own counts.

PKB relay (PraatGen side, not Opus's tree): C.1 correction — sentence
fields pair under left/right (probe 6.6.30, 19 Aug 2026); mixed
remainders pair and display the LEFT remainder only; booleans render
left/right verbatim and do not pair. C.3 correction — the derivation
law as measured above (parenthetical stripped, spaces to underscores,
everything else KEPT, unreachable-name hazard incl. the -99 arithmetic
trap and emoji-led labels binding as 📐_Spread).

END-TO-END ATTESTATION: the full proposed Pitch Contour page (merged
axes heading, three paired ranges incl. Pitch floor/ceiling, furniture,
sentence-paired axis labels, complete remap block) was rendered under
Xvfb and clicked through: every canonical variable landed its value;
screenshot and script in the probe kit, available to fold into the
harness as the page's reference leg.

GUARD, demonstrated live (6.6.30 under Xvfb, 19 Aug): a range row's NOUN
is unique per rendered form. Orientation words never disambiguate — a
form with "left Value (bottom/top)" and "left Value (left/right)" renders
BOTH rows correctly (display distinguishes by full label) and silently
binds only the LAST row's values (namespace truncates at the
parenthesis): probe returned left_Value = 333, right_Value = 444, with
the first row's 111/222 discarded without error. A page gaining a second
range renames by QUANTITY (Value/Frequency, X/Y), never by axis. This
four-field script is check 11's red demonstration — the seeded violation
that renders clean and loses user input.

Mutation demos per the compaction ruling: delete one remap line → red;
render two fields with one derivation prefix in one branch → red;
the same-noun two-range form above → red.

— verification session
