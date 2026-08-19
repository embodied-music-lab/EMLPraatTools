# Drawing invariants

Rules that hold everywhere in the plugin, with the measurement each one
rests on. A rule without a measurement behind it is a preference; these
are not preferences.

## 1. Viewport mode decides whether font size can move the box

Praat has two viewport modes and they behave differently:

- Under `Select outer viewport`, Praat computes the plotting box itself
  from the current font metrics. Changing the font size moves the box.
- Under `Select inner viewport`, the coordinates given ARE the box. Font
  size has no effect on it.

Measured in Praat 6.6.30 on a 4 x 3 inch outer viewport, drawing
`Draw inner box` at three font sizes:

| font size | box x-range   | box width |
|-----------|---------------|-----------|
| 9         | 915 .. 2685   | 1770      |
| 11        | 985 .. 2615   | 1630      |
| 16        | 1160 .. 2440  | 1280      |

Roughly 4% narrower per point of font size. The same test under
`Select inner viewport` gives an identical box at all three sizes, to the
last decimal.

### The rule

Everything that must register with the axes — the inner box, ticks and
marks, gridlines, axis lines, and the data drawn against them — is drawn
under an explicit `Select inner viewport`. Their page positions are then
font-independent, and they agree with each other by construction.

`Select outer viewport` is permitted only to place a region, and must be
followed immediately by a `Select inner viewport` for that same region.
The pattern is `@emlSetPanelViewport`; use it rather than repeating the
pair by hand.

Any remaining use of `Select outer viewport` carries a comment stating in
one or two plain sentences why outer is correct at that site.

A procedure that changes the viewport restores the caller's viewport
before returning, or documents that it does not and why.

### Why the older wording was too broad

The standard previously said, in effect, that changing font size mid-draw
shifts margins. That is true only in outer-viewport mode. Stated without
that qualification it is unfalsifiable — it predicts a shift in code that
demonstrably does not shift — and an unfalsifiable rule cannot be
enforced by a check. The rule above can be: it names a mode, and the mode
is visible in the source.

## 2. Font size is set once before a drawing sequence

Set `Font size:` to the theme body size once, before the drawing
sequence, and leave it until every coordinate-dependent command is done.
This remains good practice under either viewport mode — under outer mode
it is load-bearing, under inner mode it keeps text sizes consistent.

## 3. Titles use `Text special:`

Never `Font size:` followed by `Text top:`. The two-step form changes the
font state at the worst possible moment; `Text special:` states the size
as an argument and leaves the state alone.

## 4. Never a bare `Marks left:` or `Marks bottom:`

Bare marks divide the range into arbitrary intervals and are also
font-sensitive. Use the EML nice-number procedures with `One mark`.
