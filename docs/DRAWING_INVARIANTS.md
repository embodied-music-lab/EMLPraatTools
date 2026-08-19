# Drawing invariants

Rules that hold everywhere in the plugin, with the measurement each rests
on. These restate the PraatGen best-practice standard; where this file and
PraatGen differ, PraatGen governs.

## 1. One ambient font size per figure — including at viewport selection

Praat stores a viewport as an OUTER rectangle. `Select inner viewport`
converts the rectangle you give it to outer form using the margins in
effect AT THAT MOMENT, and every later drawing command converts back using
the margins in effect at ITS moment. Margin width is a function of font
size. So if the font size changes between selecting the viewport and
drawing — or between two drawing commands — those commands land on
different rectangles.

### Measured, Praat 6.6.30

Viewport selected as inner 1..5 x 1..4 inches at font size 11, then
`Draw inner box` at three sizes:

| font at draw | box width | vs selection |
|--------------|-----------|--------------|
| 9            | 2540      | 5.8% wider   |
| 11           | 2400      | exact        |
| 16           | 2050      | 14.6% narrower |

About 2.9% per point.

### The defect this produces, reproduced

Draw the data and gridlines at the ambient size, then set the font size and
draw the box — which is what a "assert the size before the box" wrapper
does:

```
Font size: 10
Select inner viewport: 1, 5, 1, 4
Axes: 0, 100, 0, 100
Draw line: ...          ; gridlines and data at size 10
Font size: 11
Draw inner box          ; box at size 11
```

Result: the box is 2.92% narrower and 2.59% shorter than the gridlines. It
sits inside them, and any data line that reaches the top of the gridlines
appears to overshoot the box. This matches the defect reported from a macOS
build at 3.1% and 2.0%.

### The rule

Set `Font size:` to the theme body size ONCE, BEFORE `Select inner
viewport`, and do not change it until every coordinate-dependent command in
the figure is done. Coordinate-dependent means: `Select inner viewport`,
`Select outer viewport`, `Draw inner box`, `One mark`, any `Marks` command,
`Text left/right/top/bottom`, and every `Draw line` / `Paint` that must
register with the axes.

A wrapper that asserts the body size immediately before drawing the box
does NOT make the box safe. It makes the box safe only if the viewport was
also selected at the body size — otherwise the assertion is itself the
thing that moves the box. Assert early, at selection, not late.

Where a different visual size is genuinely needed — titles, annotations,
legend text — use `Text special:`, which takes the size as an argument and
leaves the ambient state alone. Never `Font size:` followed by `Text top:`.

A procedure that changes the ambient font size restores it before
returning, or it does not change it at all.

## 2. Never a bare `Marks left:` or `Marks bottom:`

Bare marks divide the range into arbitrary intervals. Use the EML
nice-number procedures with `One mark`.

## 3. Assert the full viewport before saving

The viewport in effect at save time determines what is captured. For
multi-panel figures use the tracked extent (`@emlExpandDrawnExtent` /
`@emlAssertFullViewport`); single-panel figures assert it too, because the
Picture window may hold residual state.
