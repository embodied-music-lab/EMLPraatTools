# Ruling — dialog layout groups, APPROVED (Ian, 24 Aug)

Verification session → executing session. Ian has approved the eight
rendered mockups and the icon choices. This is the grouping layer that
sits on top of the labels ruling (RULING_DIALOG_LABELS v3) and the
compaction ruling; those two carry the row mechanics and the character
law, this one carries the page structure. The mockup scripts and
reference screenshots ship in this package as worked examples — each
script rendered under Xvfb on 6.6.30 and eyeballed by Ian.

## The rules

1. **No field renders outside a named group.** Every page's field list
   closes inside a group; fields after the last heading silently
   inheriting it was the defect the pitch mockup exposed.
2. **Group order = the order of decisions:** columns → analysis → axes →
   layout. Acoustic pages, which have no column pickers, start at axes.
3. **Icons, final:** 📋 Columns · 📊 Analysis (unified — the stat pages'
   📈 retires) · 📐 axes (with "both 0 = auto" in the heading) · 🖌️
   Drawing methods (LTAS only) · 🎛️ Layout (replacing 🎨 everywhere,
   including the scatter's existing 🎨 Layout). 🎨 retires unused. 🏷️
   stays as the labels sub-heading INSIDE the axis group, directly above
   the paired labels row. 🖼️ Figure and 📄 Page are EML Graphs' own.
4. **🎛️ Layout contents and order:** mark → frame → text → output:
   data-mark toggles first (jitter / mean overlay / show points + dot
   size, per page), Line style where the type strokes, Gridline mode,
   Legend placement, Show inner box, Show axis names, Show ticks, Show
   axis values, Font, Output DPI. Booleans untouched per standing ruling.
   AMENDED 24 Aug: Legend placement sits directly after Gridline mode, as
   the per-page maps below have always said and as the five built pages
   render. This sentence previously placed it between Font and Output DPI
   and was the defect; the maps and the approved mockups govern.
5. **The organization row is paid for:** each page's Layout header costs
   one row and buys the scan; the approved counts below are the ruling.

## Per-page group maps (mock scripts attached; counts = heading+field rows)

- **EML Graphs (→9):** 🖼️ Figure (Graph type, Title, Subtitle, Color
  mode, Figure size pair) · 📄 Page (one-line Erase guidance, Erase page
  first, Panel origin pair). Title/Subtitle stay two full rows. The
  legend advice moves to the pages that carry Legend placement.
- **Pitch Contour (→18):** 📐 Axes (Time, Frequency, Y axis unit, 🏷️ +
  labels pair) · 🎵 Pitch analysis (ceiling-doubled line, Pitch
  floor/ceiling pair) · 🎛️ Layout (Line style, Gridline, box, names,
  ticks, values, Font, DPI).
- **Waveform / Spectrum (→15 each):** 📐 Axes (both ranges, 🏷️+labels) ·
  🎛️ Layout (as pitch, minus Y-unit concerns).
- **LTAS (→19):** as Spectrum + 🖌️ Drawing methods (Show curve, bars,
  poles, speckles) above Layout.
- **Bar / Violin / Box advanced (→25):** 📋 Columns (Value, Error bars
  [bar only], Group column, Group order) · 📊 Analysis (Annotate, Test
  type, Adjustment [conditional], Significance style, Show NS, Show
  effect sizes, Annotation layout, Alpha) · 📐 Y-axis (both 0 = auto)
  (Value range row, 🏷️+labels) · 🎛️ Layout (jitter where present,
  Gridline, box, names, ticks, values, Font, DPI).
- **Histogram advanced (→31):** 📋 Columns · 📊 Histogram (Bin count,
  Frequency maximum, Display mode — compound row REFUSED by Ian, two
  rows stay) · 📊 Analysis ("· comparisons appear as a matrix panel
  below the plot" in the header) · 📐 Value axis · 🎛️ Layout (+Legend
  placement). Value-range orientation follows the axis it actually
  governs — Opus confirms which and the label tells that truth.
- **Grouped Violin / Grouped Box advanced (→27 each):** 📋 Columns
  (Value, Category, Subgroup, Group order) · 📊 Analysis (matrix note in
  header) · 📐 Y-axis · 🎛️ Layout (jitter first, +Legend placement).
- **Scatter advanced (→27):** 📋 Columns (X, Y, Use group, Group, Group
  order) · 📊 Analysis (Correlation method, Regression, Significance
  style) · 📐 Axes (X range, Y range, 🏷️+labels) · 🎛️ Layout (Show data
  points, Dot size, Gridline, Legend placement, box, names, ticks,
  values, Font, DPI).
- **Spaghetti (→21):** 📋 Columns (teaching parentheticals kept) · 📐
  Y-axis · 🎛️ Layout (Show mean overlay, Line style, Gridline, Legend
  placement, box, names, ticks, values, Font, DPI).
- **Line chart pages (→4, →23 advanced / 11 beginner, →7):** the grouping
  lands inside the tree's own file set as a follow-up commit, same rules —
  never a retrofit against the old form. The Right-Hand Axis content keeps
  its ruled rows. TARGETS ADOPTED 24 Aug at the built actuals, provisionally:
  What the lines are 4, Column Mapping 23 advanced and 11 beginner,
  Right-Hand Axis 7. Provisional means the rendered counts are verified
  independently once the commits are on the remote, and a mismatch reopens
  the number rather than the page.

Counts are the approved targets ±1; verify each against the rendered
page under Xvfb and report actuals, per the compaction ruling's
done-when. Remap blocks per the compaction ruling; contributed rows
(v98's resolver output) are part of each page's census — they bind
LAST, so remaps account for them.

## Interactions

- Beginner branches keep their (shorter) structure; the group rules
  apply to whatever rows a branch renders.
- The dead-controls collapses (wizard test list, wrapper Comparison
  lists) land inside 📊 Analysis groups as single rows.
- Harnesses addressing fields by label redrive ONCE with this sweep —
  the standing one-redrive rule.

Worked examples attached: mock_*.praat (rendered mockup scripts) and
the approved screenshots. They are illustrations of the target, not
committed fixtures — the pages' own code is the implementation.

— verification session
