# EML Stats Tutorial — Page Layout Wireframes
# Date: 31 March 2026
# Status: Design review
#
# All coordinates in Demo window units (0–100, origin bottom-left)
# Font sizes in Praat points (scale with nothing — fixed on screen)
# Colors reference the palette from SCAFFOLD_STATS_TUTORIAL.md §3.3

# ============================================================================
# GLOBAL LAYOUT CONSTANTS
# ============================================================================
#
# These define the persistent regions across ALL page types.
#
#   ┌────────────────────────────────────────────────────┐ 100
#   │  PROGRESS BAR (thin line, top edge)                │ 97–100
#   ├────────────────────────────────────────────────────┤
#   │  HEADER ZONE (module title, part label)            │ 88–97
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │                                                    │
#   │           CONTENT ZONE (variable)                  │ 8–88
#   │                                                    │
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  NAVIGATION BAR (hints, page counter)              │ 0–8
#   └────────────────────────────────────────────────────┘ 0
#
# Horizontal margins: 5 units on each side (content lives in 5–95)

headerTop = 97
headerBottom = 88
contentTop = 88
contentBottom = 8
navTop = 8
navBottom = 0
marginLeft = 5
marginRight = 95
progressY = 98.5


# ============================================================================
# LAYOUT TYPE A: TITLE CARD
# ============================================================================
#
# Used for: Module title pages, Part title pages
# Content: Centered part label + module title, no scrolling
#
#   ┌────────────────────────────────────────────────────┐
#   │ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱  (progress)                │
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │                                                    │
#   │          PART 1: YOUR DATA                         │  62 (small, dim)
#   │                                                    │
#   │        What Is Data?                               │  52 (large, white)
#   │                                                    │
#   │    ─── decorative rule ───                         │  44
#   │                                                    │
#   │     A short subtitle or tagline                    │  38 (body, cream)
#   │                                                    │
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  → or click to begin                               │
#   └────────────────────────────────────────────────────┘
#
# Font sizes: Part label = 14pt, Module title = 24pt,
#             Subtitle = 12pt, Nav hint = 10pt
# All text: demo Text: x, "centre", y, "half", text$
# Decorative rule: demo Draw line: 30, 70, 44, 44 (gray)


# ============================================================================
# LAYOUT TYPE B: TEXT-ONLY PAGE
# ============================================================================
#
# Used for: Explanatory text, key idea recaps, scenarios
# Content: Wrapped text body, optional highlight terms
#
#   ┌────────────────────────────────────────────────────┐
#   │ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱                             │
#   ├────────────────────────────────────────────────────┤
#   │  Module 1: What Is Data?             [1/7]        │
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │  PAGE HEADING (optional, 16pt white)               │ 82
#   │                                                    │
#   │  Body text wraps within the content zone.          │ 74
#   │  Each paragraph is a separate Rectangle text       │
#   │  (wrap & truncate) call within a defined           │
#   │  sub-rectangle.                                    │
#   │                                                    │
#   │  HIGHLIGHTED TERMS appear in gold.                 │ 50
#   │  Terms are drawn with a separate Text: call        │
#   │  in the highlight color after the body text.       │
#   │                                                    │
#   │  Line spacing: ~4 units between paragraphs.        │ 36
#   │  Text region: x = 10–90, y = contentBottom+4       │
#   │  to heading baseline.                              │
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  ← back    [1/7]    → or click to continue        │
#   └────────────────────────────────────────────────────┘
#
# Text rendering strategy:
#   - FIRST TRY: demo Rectangle text (wrap & truncate):
#     fromX, toX, fromY, toY — if text parameter exists
#   - FALLBACK: Manual word-wrap procedure (@tutWrapText):
#     Split text on spaces, measure with
#     demo Text width (world coordinates): per word,
#     accumulate until line exceeds available width,
#     draw line, advance Y, repeat.
#   - Highlight terms: Overlay with demo Colour: gold$
#     and demo Text: at exact position of the term.
#     (Requires knowing x-offset of term within line —
#     complex; alternative is per-sentence coloring.)
#
# Simpler highlight approach: Entire sentences containing
# new terms drawn in highlight color. Body sentences in cream.


# ============================================================================
# LAYOUT TYPE C: TEXT + IMAGE (SIDE BY SIDE)
# ============================================================================
#
# Used for: Explanatory text with a graph or diagram beside it
# Content: Text on left, image on right (or vice versa)
#
#   ┌────────────────────────────────────────────────────┐
#   │ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱                             │
#   ├────────────────────────────────────────────────────┤
#   │  Module 3: Describing Your Data      [4/10]       │
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │  ┌─────────────┐  ┌──────────────────────┐        │
#   │  │             │  │                      │        │
#   │  │  TEXT AREA   │  │    IMAGE AREA        │        │
#   │  │  (wrapped)   │  │  (precomputed PNG    │        │
#   │  │             │  │   via Insert picture  │        │
#   │  │  x: 8–45    │  │   from file:)        │        │
#   │  │             │  │                      │        │
#   │  │             │  │  x: 50–95            │        │
#   │  │             │  │  y: 12–82            │        │
#   │  └─────────────┘  └──────────────────────┘        │
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  ← back    [4/10]    →                            │
#   └────────────────────────────────────────────────────┘
#
# Image insertion pattern:
#   imgPath$ = tutorialDir$ + "/images/mod3_boxplot.png"
#   demo Select inner viewport: ... (map to image area)
#   demo Insert picture from file: imgPath$, 0, 0, 0, 0
#   demo Select inner viewport: 0, 100, 0, 100
#   demo Axes: 0, 100, 0, 100
#   # ^ CRITICAL: restore axes after image insertion
#
# Text/image split can be flipped (image left, text right)
# by swapping the x-ranges. Convention: text on the side
# where the reader's eye starts (left in LTR languages).


# ============================================================================
# LAYOUT TYPE D: FULL-WIDTH IMAGE WITH CAPTION
# ============================================================================
#
# Used for: Full graph displays, the gallery, scatter plots
# Content: Large image centered, caption text below
#
#   ┌────────────────────────────────────────────────────┐
#   │ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱                             │
#   ├────────────────────────────────────────────────────┤
#   │  Module 10: Graph Gallery            [2/7]        │
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │  ┌──────────────────────────────────────────┐     │
#   │  │                                          │     │
#   │  │          FULL-WIDTH IMAGE                │     │
#   │  │     (precomputed via EML Graphs)          │     │
#   │  │                                          │     │
#   │  │     x: 10–90   y: 28–84                  │     │
#   │  │                                          │     │
#   │  └──────────────────────────────────────────┘     │
#   │                                                    │
#   │  Caption text (12pt, cream, centered or left)     │  18
#   │  One or two lines describing the graph.           │  13
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  ← back    [2/7]    →                            │
#   └────────────────────────────────────────────────────┘
#
# Aspect ratio preservation:
#   EML Graphs figures are 6×4 inches (3:2).
#   Image area on screen: 80 units wide × 56 units tall.
#   At 100×100 canvas ≈ 12×12 inches: 9.6" × 6.7" — larger
#   than the source. PNG at 300 DPI (1800×1200 px) is sufficient.
#
#   If source aspect ratio differs, compute:
#     imgW = 80
#     imgH = imgW * (sourceH / sourceW)
#     if imgH > maxH
#       imgH = maxH
#       imgW = imgH * (sourceW / sourceH)
#     endif
#   Center within available area.


# ============================================================================
# LAYOUT TYPE E: MULTI-IMAGE COMPARISON
# ============================================================================
#
# Used for: Side-by-side graphs, positive/negative/none correlation,
#           shape comparisons (symmetric/skewed), graph gallery groups
# Content: 2–4 images in a row with labels
#
#   ┌────────────────────────────────────────────────────┐
#   │ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱                             │
#   ├────────────────────────────────────────────────────┤
#   │  Module 7: Do These Move Together?   [3/7]        │
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │  ┌────────┐  ┌────────┐  ┌────────┐              │
#   │  │ IMG 1  │  │ IMG 2  │  │ IMG 3  │              │
#   │  │        │  │        │  │        │              │
#   │  │Positive│  │Negative│  │  None  │              │
#   │  │ r=0.8  │  │ r=-0.7 │  │ r=0.0  │              │
#   │  └────────┘  └────────┘  └────────┘              │
#   │   Label 1     Label 2     Label 3                 │
#   │                                                    │
#   │  Body text below images.                          │
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  ← back    [3/7]    →                            │
#   └────────────────────────────────────────────────────┘
#
# Grid layout for N images:
#   gap = 3 units between images
#   totalGap = (N-1) * gap
#   availableW = 80 (marginLeft to marginRight - 2*5 padding)
#   imgW = (availableW - totalGap) / N
#   For N=3: imgW ≈ 24.7 units each
#   imgH = imgW * 0.67 (3:2 aspect, adjustable)
#
# Labels: centered below each image, 10pt cream


# ============================================================================
# LAYOUT TYPE F: INTERACTIVE CHOICE
# ============================================================================
#
# Used for: Decision tree nodes (Module 9), yes/no questions,
#           quiz-style interactions
# Content: Question text + clickable button rectangles
#
#   ┌────────────────────────────────────────────────────┐
#   │ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱                             │
#   ├────────────────────────────────────────────────────┤
#   │  Module 9: Choosing the Right Test   [3/8]        │
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │  Question text (16pt, white, centered)             │ 72
#   │                                                    │
#   │         How many groups?                           │ 64
#   │                                                    │
#   │  ┌──────────────────┐ ┌──────────────────┐        │
#   │  │                  │ │                  │        │
#   │  │     Two           │ │  Three or more   │        │
#   │  │                  │ │                  │        │
#   │  └──────────────────┘ └──────────────────┘        │
#   │   x: 15–48, y: 38–52   x: 52–85, y: 38–52        │
#   │                                                    │
#   │  (optional: body text below buttons)               │ 28
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  ← back    [3/8]    →                            │
#   └────────────────────────────────────────────────────┘
#
# Button rendering:
#   demo Paint rounded rectangle: buttonFill$, x1, x2, y1, y2
#   demo Colour: "White"
#   demo Text: midX, "centre", midY, "half", label$
#   # OR: demo Rectangle text (maximal fit): x1, x2, ..., y1, y2, ...
#   #   ^ if text parameter confirmed
#
# Button detection:
#   demo Axes: 0, 100, 0, 100
#   demoWaitForInput ()
#   if demoClicked ()
#     if demoClickedIn (15, 48, 38, 52)
#       # Button 1 clicked
#     elsif demoClickedIn (52, 85, 38, 52)
#       # Button 2 clicked
#     endif
#   endif
#
# Hover state: NOT POSSIBLE in Praat Demo window.
# (No continuous mouse tracking — only click events.)
# Button appearance is static. Active button can be
# redrawn in a different color after click as feedback.
#
# Vertical button stack (for 3–4 options):
#   Same x range for all buttons (20–80),
#   stacked vertically with 3-unit gaps.
#   Button heights: 10 units each.


# ============================================================================
# LAYOUT TYPE G: ANIMATED DOT PLOT / SCATTER
# ============================================================================
#
# Used for: Building data visualizations point by point
# Content: Drawing area with live-drawn data points
#
#   ┌────────────────────────────────────────────────────┐
#   │ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱                             │
#   ├────────────────────────────────────────────────────┤
#   │  Module 2: Looking at Your Data      [3/8]        │
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │  ┌──────────────────────────────────────────┐     │
#   │  │                                          │     │
#   │  │     DRAWING AREA                         │     │
#   │  │     (demo Axes: set to data range)       │     │
#   │  │                                          │     │
#   │  │     Points drawn with demo Paint circle  │     │
#   │  │     One per animation frame               │     │
#   │  │     sleep(0.08) between frames            │     │
#   │  │                                          │     │
#   │  │     x: 15–85   y: 20–82                  │     │
#   │  │     (inner viewport maps to data coords)  │     │
#   │  │                                          │     │
#   │  └──────────────────────────────────────────┘     │
#   │                                                    │
#   │  Annotation text (appears after animation)        │  14
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  → or click when ready                            │
#   └────────────────────────────────────────────────────┘
#
# Drawing area uses a sub-viewport:
#   .vpScale = 12 / 100
#   .vpLeft = 15 * .vpScale    # = 1.8"
#   .vpRight = 85 * .vpScale   # = 10.2"
#   .vpTop = (100 - 82) * .vpScale   # = 2.16" (y inverted)
#   .vpBottom = (100 - 20) * .vpScale # = 9.6"
#   demo Select inner viewport: .vpLeft, .vpRight, .vpTop, .vpBottom
#   demo Axes: dataXMin, dataXMax, dataYMin, dataYMax
#
# Animation pattern (no input polling during animation):
#   for i from 1 to nPoints
#     demo Paint circle: color$, x#[i], y#[i], radius
#     demoShow ()
#     sleep (0.08)
#   endfor
#   # Restore full-canvas coordinates before input wait
#   demo Select inner viewport: 0, 100, 0, 100
#   demo Axes: 0, 100, 0, 100
#   demoWaitForInput ()
#
# Overlay annotations (mean line, IQR box, etc.):
#   Drawn after animation completes, in the same viewport.
#   Text labels use demo Text: in data coordinates.


# ============================================================================
# LAYOUT TYPE H: SUMMARY / RECAP
# ============================================================================
#
# Used for: Key ideas at end of each module, reference tables
# Content: Bulleted list or table with compact entries
#
#   ┌────────────────────────────────────────────────────┐
#   │ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱                             │
#   ├────────────────────────────────────────────────────┤
#   │  Module 4: Are These Groups Different? [9/9]      │
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │  KEY IDEAS                              (16pt)     │ 82
#   │  ─────────                                        │ 80
#   │                                                    │
#   │  •  t-test: signal / noise ratio        (12pt)    │ 74
#   │     for two independent groups                     │ 70
#   │                                                    │
#   │  •  p-value: probability of seeing      (12pt)    │ 64
#   │     this result if no real difference              │ 60
#   │                                                    │
#   │  •  Cohen's d: how big the difference   (12pt)    │ 54
#   │     is in SD units                                 │ 50
#   │                                                    │
#   │  •  Parametric (t-test) vs. nonparam.   (12pt)    │ 44
#   │     (Mann-Whitney U)                              │ 40
#   │                                                    │
#   │  •  Always report BOTH p-value          (12pt)    │ 34
#   │     and effect size                               │ 30
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  ← back    [9/9]    → next module                 │
#   └────────────────────────────────────────────────────┘
#
# Bullet rendering:
#   Bullet character: "•" (Unicode 2022, safe in Praat)
#   demo Text: 10, "left", bulletY, "top", "•"
#   demo Text: 14, "left", bulletY, "top", mainText$
#   demo Text: 14, "left", bulletY - 4, "top", subText$
#   # Or use Rectangle text (wrap & truncate) for each item
#
# Table rendering (for Module 10 reference table):
#   Draw gridlines with demo Draw line:
#   Fill cells with demo Text: at computed positions
#   Header row in bold (demo Text special: with ##)
#   Alternating row backgrounds with
#   demo Paint rectangle: in subtle shade difference


# ============================================================================
# LAYOUT TYPE I: HOME SCREEN (MODULE SELECTOR)
# ============================================================================
#
# Used for: Tutorial entry point, module jumping
# Content: Grid of module cards, clickable
#
#   ┌────────────────────────────────────────────────────┐
#   │                                                    │
#   │         EML STATS TUTORIAL                         │ 90 (24pt)
#   │         Interactive Statistics Guide               │ 84 (12pt)
#   │                                                    │
#   │  ┌─ PART 1: YOUR DATA ──────────────────────────┐ │
#   │  │ ┌──────────┐ ┌──────────┐ ┌──────────┐      │ │
#   │  │ │  1. What │ │  2. Look │ │ 3. Desc. │      │ │
#   │  │ │  Is Data │ │  at Data │ │  Stats   │      │ │
#   │  │ │   ✓      │ │          │ │          │      │ │
#   │  │ └──────────┘ └──────────┘ └──────────┘      │ │
#   │  └──────────────────────────────────────────────┘ │
#   │  ┌─ PART 2: ASKING QUESTIONS ────────────────────┐│
#   │  │ ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌───┐││
#   │  │ │ 4. Two  │ │ 5. Pair │ │ 6. Multi │ │ 7 │││
#   │  │ │ Groups  │ │  Pre/Pos│ │  Groups  │ │Cor│││
#   │  │ └──────────┘ └──────────┘ └──────────┘ └───┘││
#   │  └──────────────────────────────────────────────┘ │
#   │  ┌─ PART 3: THE FULL PICTURE ────────────────────┐│
#   │  │ ┌──────────┐ ┌──────────┐ ┌──────────┐      ││
#   │  │ │ 8. Time │ │ 9. Which │ │ 10. The  │      ││
#   │  │ │ Series  │ │  Test?   │ │ Gallery  │      ││
#   │  │ └──────────┘ └──────────┘ └──────────┘      ││
#   │  └──────────────────────────────────────────────┘ │
#   │                                                    │
#   │  Click a module to begin. ESC to exit.            │
#   └────────────────────────────────────────────────────┘
#
# Module card layout:
#   3 or 4 cards per row within the part group.
#   Card size: ~24×14 units (adjustable based on count)
#   Part group: labeled header bar + cards
#   Completed modules show ✓ (if progress persistence is ON)
#
# Card rendering:
#   demo Paint rounded rectangle: cardFill$, x1, x2, y1, y2
#   demo Draw rounded rectangle: x1, x2, y1, y2
#   demo Rectangle text (maximal fit): x1, x2, ..., y1, y2, ...
#     # or manual centering with demo Text:
#
# Click detection: demoClickedIn() per card.
# ESC detection: demoKey$() = escape character.


# ============================================================================
# LAYOUT TYPE J: FLOWCHART / DECISION TREE
# ============================================================================
#
# Used for: Module 9 decision tree visualization
# Content: Nodes connected by lines, progressively revealed
#
#   ┌────────────────────────────────────────────────────┐
#   │ ▰▰▰▰▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱▱                             │
#   ├────────────────────────────────────────────────────┤
#   │  Module 9: Choosing the Right Test   [7/9]        │
#   ├────────────────────────────────────────────────────┤
#   │                                                    │
#   │              ┌──────────────┐                     │
#   │              │  What's your │                     │ 76
#   │              │  question?   │                     │
#   │              └──────┬───────┘                     │
#   │           ┌─────────┼─────────┐                   │
#   │     ┌─────┴───┐  ┌──┴──┐  ┌──┴──────┐           │
#   │     │Describe │  │Comp.│  │Relation.│           │ 56
#   │     └─────────┘  └──┬──┘  └─────────┘           │
#   │                 ┌────┼────┐                       │
#   │           ┌─────┴──┐ └──┌─┴────────┐             │
#   │           │2 groups│    │3+ groups │             │ 38
#   │           └────┬───┘    └──────────┘             │
#   │           ┌────┼────┐                             │
#   │     ┌─────┴──┐ └──┌─┴────────┐                   │
#   │     │Indep.  │    │ Paired   │                   │ 20
#   │     │t / MWU │    │ t / Wil. │                   │
#   │     └────────┘    └──────────┘                   │
#   │                                                    │
#   ├────────────────────────────────────────────────────┤
#   │  ← back    [7/9]    →                            │
#   └────────────────────────────────────────────────────┘
#
# Node rendering:
#   demo Paint rounded rectangle: nodeFill$, x1, x2, y1, y2
#   demo Draw rounded rectangle: x1, x2, y1, y2
#   demo Rectangle text (maximal fit): x1, x2, ..., y1, y2, ...
#
# Connectors:
#   demo Draw line: parentMidX, parentY1, childMidX, childY2
#   # Line from bottom of parent to top of child
#
# Progressive reveal:
#   Each click reveals the next level of the tree.
#   Previously revealed nodes remain visible.
#   Active level highlighted, prior levels dimmed.
#
# Alternative: Pre-render entire tree as PNG in Picture
# window and show as image. Loses progressive reveal but
# avoids complex live drawing. Hybrid: pre-render tree,
# overlay highlight rectangles at active level.


# ============================================================================
# COMPONENT SPECIFICATIONS
# ============================================================================

# --- PROGRESS BAR ---
# Thin horizontal line at y=98.5
# Filled portion = (globalPageIndex / totalPages) * 90 + 5
# Background: dark gray. Fill: gold.
# demo Paint rectangle: bgColor$, 5, 95, 98, 99
# demo Paint rectangle: fillColor$, 5, fillX, 98, 99

# --- HEADER ZONE ---
# Left: Module title (14pt, white)
# Right: Page counter "[n/N]" (10pt, dim gray)
# Separator: thin line at y=88 (subtle gray)
# demo Text: 5, "left", 92, "half", moduleTitle$
# demo Text: 95, "right", 92, "half", pageCounter$
# demo Colour: axisColor$
# demo Draw line: 5, 95, 88, 88

# --- NAVIGATION BAR ---
# Left: "← back" (10pt, dim, only if page > 1)
# Center: page counter or empty
# Right: "→ or click" (10pt, dim)
# demo Text: 5, "left", 4, "half", "← back"
# demo Text: 50, "centre", 4, "half", ""
# demo Text: 95, "right", 4, "half", "→ or click"
# Separator: thin line at y=8

# --- BUTTONS ---
# Rounded rectangles with centered text.
# Size: minimum 28×10 units for comfortable clicking.
# Fill: buttonFill$ (muted blue). Border: 1px lighter.
# Text: white, 12pt, centered.
# After click: brief flash in buttonActive$ color,
# then proceed.
#
# Click feedback pattern:
#   demo Paint rounded rectangle: activeColor$, x1, x2, y1, y2
#   demo Colour: "White"
#   demo Text: midX, "centre", midY, "half", label$
#   demoShow ()
#   sleep (0.15)
#   # Then proceed to next page


# ============================================================================
# RESPONSIVE BEHAVIOR NOTES
# ============================================================================
#
# The Demo window uses percentage-based coordinates (0–100).
# When the user resizes the window, ALL drawn content scales
# proportionally — rectangles, lines, circles all resize.
#
# EXCEPTION: Font sizes are in absolute points. A 12pt font
# is 12pt regardless of window size. This means:
#   - In a larger window, text appears smaller relative to
#     the surrounding graphics
#   - In a smaller window, text may overflow its container
#
# DESIGN STRATEGY:
#   1. Design for default window (1344×756 px)
#   2. Use font sizes that leave comfortable margins at default
#   3. For text containers (buttons, body text), use
#      Rectangle text commands which auto-fit
#   4. Accept that full-screen mode will have proportionally
#      more whitespace around text — this is fine and actually
#      improves readability at presentation distance
#   5. Do NOT try to detect window size or adjust font
#      dynamically — Praat provides no window size query
#
# IMAGE SCALING:
#   Insert picture from file: scales the image to fill the
#   specified viewport region. At larger window sizes, the
#   image is stretched (potentially losing quality). Solution:
#   render source PNGs at 600 DPI so they look sharp even at
#   full-screen/projector resolution.
#
# CRITICAL CONSTRAINT:
#   There is NO way to query the Demo window's current pixel
#   dimensions from a script. We design for the default size
#   and accept graceful degradation at other sizes.


# ============================================================================
# PRE-COMPUTED IMAGE PIPELINE
# ============================================================================
#
# Strategy: Render all tutorial graphs in the Picture window
# using EML Graphs procedures, save as high-res PNGs, then
# display in Demo window via demo Insert picture from file:.
#
# Pipeline (runs once at tutorial startup or ships pre-built):
#
#   1. For each figure needed:
#      a. Create synthetic data (same seed for reproducibility)
#      b. Build Table
#      c. Call EML Graphs draw procedures in Picture window
#      d. Save as 600-dpi PNG file: tutImgDir$ + "/figName.png"
#      e. Erase all (Picture window)
#
#   2. Store PNGs in plugin_EML_Praat_Tools/tutorial/images/
#
#   3. In Demo window, display with:
#      demo Select inner viewport: vpL, vpR, vpT, vpB
#      demo Insert picture from file: imgPath$, 0, 0, 0, 0
#      demo Select inner viewport: 0, 100, 0, 100
#      demo Axes: 0, 100, 0, 100
#
# Advantages:
#   - Figures look identical to plugin output
#   - No y-axis inversion issues (images are pre-rendered)
#   - No need to reimplement EML Graphs for Demo window
#   - Can include complex graph types (violin KDE, spectrum)
#
# Disadvantages:
#   - Images are static — no animation within a pre-rendered graph
#   - File size: 14 figures × ~200KB each ≈ 2.8 MB
#   - Must ship with the plugin or generate at first run
#
# For animated elements (dot-by-dot scatter, morphing histogram):
#   Use live demo drawing commands, not pre-rendered images.
#   These are simpler geometries (circles, rectangles, lines)
#   that don't need EML Graphs procedures.
#
# HYBRID APPROACH (recommended):
#   - Pre-render: completed graphs, gallery items, complex plots
#   - Live-draw: data points appearing one by one, mean lines
#     sweeping in, box plot components building up, connecting
#     lines between paired data points


# ============================================================================
# EMPIRICAL VERIFICATION NEEDED
# ============================================================================
#
# Before implementation, these items need testing in Praat:
#
# 1. Rectangle text (maximal fit): syntax and text parameter
#    - Does it use a text$ parameter not shown in the catalogue?
#    - Does it read from a prior Text: call?
#    - Test: demo Rectangle text (maximal fit): 10, 90, 0.1, 0.5,
#      20, 80, 0.18, 0.25
#    - What text appears? How is text supplied?
#
# 2. Rectangle text (wrap & truncate): same questions
#    - Test: demo Rectangle text (wrap & truncate): 10, 90, 20, 80
#    - Does it wrap the most recently set text?
#    - Does it accept a text$ parameter?
#
# 3. demo Insert picture from file: aspect ratio behavior
#    - Does it preserve aspect ratio or stretch to fill?
#    - Test with a 3:2 image in a 1:1 viewport
#
# 4. demo Insert picture from file: axes corruption
#    - Confirmed in Picture window. Verify same behavior in Demo.
#    - Test: draw text before and after image insertion
#
# 5. Font metric contamination across pages
#    - Three-line reset is known necessary. Verify it's sufficient
#      for page transitions with mixed font sizes.
#
# 6. Maximum practical image count
#    - Gallery module may display 14+ images. Memory/performance?
#    - Test: insert 20 PNGs in sequence with selective repaints.
