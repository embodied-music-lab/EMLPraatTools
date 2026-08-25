# EML Stats & Graphs — Dialog Design System
# ============================================================
# The wizard's purpose is PEDAGOGICAL. Every dialog teaches
# the user what a test does, when to use it, and what the
# results mean. The design system serves that mission.
#
# Design goal: make teaching content clearer and more
# visually structured — never shorter for brevity's sake.
#
# Date: 11 May 2026 (v2 — emoji + zone formatting)
# ============================================================


## Core Principle

The wizard is a guided learning experience for voice clinicians,
students, and educators who may be encountering these tests for
the first time. Explanatory text is the product, not overhead.

The design system adds visual structure TO the teaching content.
It never removes teaching content to achieve visual cleanliness.


## Constraints

Praat `comment:` fields in `beginPause`:
- Plain text only — no bold, italic, or font control
- One line per `comment:` call
- Dialog width adjusts to longest line (dynamic, not fixed)
- Unicode works: ─ ═ │ ├ └ → • ▸
- **Color emoji work**: ✅ ❌ ⚠️ ℹ️ ⚖️ 📈 📊 🎯 📋 🔗 🔍
  (Verified GTK 11 May 2026; macOS Cocoa renders larger/richer)
- `Font size:` has NO effect on dialog text (OS widget font)
- Emoji render inside `option:` labels in optionmenus


## Zone Structure

Every dialog has 2–4 functional zones, separated by visual
markers. The user's eye should move top-to-bottom through
distinct regions, not scan a wall of text.

### Zone types

| Zone | Purpose | Marker |
|------|---------|--------|
| Context | What data are we working with? | 📋 + `─────` rule below |
| Menu | What are the options? | Emoji-prefixed items |
| Action | What does the user do? | `─────` rule above field |
| Teaching | What does this mean? | `· · · ·` dotted break + ℹ️ |
| Verdict | What did the analysis find? | ✅ ❌ ⚠️ prefix |

### Separator hierarchy

| Separator | Weight | Use |
|-----------|--------|-----|
| `─────────────────────────────────────` | Heavy | Between major zones (context/menu, menu/action) |
| `· · · · · · · · · · · · · · · · · · · · ·` | Light | Before teaching content (below the fold) |
| blank `comment: ""` | Minimal | Between items within a zone |
| `══════════════════════════════════════` | **Retired** | Do not use (old style) |

### Context zone (all dialogs)

    comment: "📋 Table: " + displayTable$
    comment: "     [metadata line if needed]"
    comment: "─────────────────────────────────────"

Always first. Always labeled with "Table:" — never bare name.
Second line (indented) for metadata: column/row counts, column
names being analyzed, factor descriptions.


## Emoji Vocabulary

### Navigation emoji (category markers)

| Emoji | Category | Rationale |
|-------|----------|-----------|
| ⚖️ | Compare | Balance/scale — weighing groups |
| 📈 | Relationship | Trend line — correlation, covariance |
| 📊 | Describe | Bar chart — summary statistics |
| 🎯 | Predict | Target — prediction, regression |
| 🔗 | Correlation | Link — two things connected |
| 🔍 | Examine/inspect | Magnifier — looking at data |
| ↩️ | Redirect | Return arrow — "this is actually Compare" |

These echo inside `option:` labels in the dropdown:

    optionmenu: "Goal", 1
        option: "⚖️ Compare groups or conditions"
        option: "📈 Examine a relationship"
        option: "📊 Describe or summarize"
        option: "🎯 Predict an outcome"

### Status emoji (verdicts and markers)

| Emoji | Meaning | Use |
|-------|---------|-----|
| ✅ | Pass / safe | Normality reasonable |
| ❌ | Fail / caution | Normality not supported |
| ⚠️ | Warning | Small sample, borderline, edge case |
| ℹ️ | Information | Teaching content marker |
| 📋 | Table/data context | Context zone prefix |

### Emoji not used

No arbitrary colored circles (🔵 🟢 etc.) — every emoji must
map to what the category DOES, not just provide color.


## Pattern Catalog

### 1. Navigation dialog (question-first)

    comment: "📋 Table: " + displayTable$
    comment: "     " + string$(nCols) + " columns · " + string$(nRows) + " rows"
    comment: "─────────────────────────────────────"
    comment: ""
    comment: "⚖️ [Research question phrased as user's question]"
    comment: "     → [Category name]"
    comment: ""
    comment: "📈 [Next question]"
    comment: "     → [Category name]"
    [...]
    comment: ""
    comment: "─────────────────────────────────────"
    optionmenu: "Goal", prevGoal
        option: "⚖️ [Category]"
        option: "📈 [Category]"

**Key principle:** The researcher's question is the heading.
The category name is a quiet → signpost below it. Questions
use the user's language ("Are my groups different?"), not
statistical language ("Test for significant differences").

### 2. Binary fork (one-question dialog)

    comment: "Were the same people measured more than once?"
    comment: ""
    optionmenu: "Observation type", 1
        option: "No — different groups"
        option: "Yes — same people, repeated"

No emoji needed. The question IS the interface. Option labels
answer in plain language. Three lines total.

### 3. Column selection (fields-first)

    comment: "📋 Table: " + displayTable$
    comment: "─────────────────────────────────────"
    comment: ""
    optionmenu: "Measurement", dataDefault
        [columns]
    optionmenu: "Grouping variable", groupDefault
        [columns]
    comment: ""
    boolean: "Check normality first", prevCheckNorm
    comment: ""
    comment: "· · · · · · · · · · · · · · · · · · · · ·"
    comment: ""
    comment: "ℹ️ [Teaching content — as much as needed]"
    comment: "     [continuation lines indented]"

**Key principle:** Action at top, teaching below the fold.
Expert user never reads past the fields. Learner finds
the explanation waiting after the action.

**Exception:** When the teaching content is needed to
understand the fields (e.g., regression X/Y concept),
keep teaching above the fields.

### 4. Test selection with verdict

    comment: "📋 Table: " + displayTable$
    comment: "     " + dataCol$ + " · by " + groupCol$
    comment: "─────────────────────────────────────"
    comment: ""
    comment: "[✅/❌/⚠️] [Verdict headline]"
    comment: "     [Consequence / recommendation]"
    comment: "     (See Info window for [details].)"
    comment: ""
    comment: "· · · · · · · · · · · · · · · · · · · · ·"
    comment: ""
    comment: "[Test name A] — [specific test]"
    comment: "[What it does differently, one line]"
    comment: ""
    comment: "[Test name B] — [specific test]"
    comment: "[What it does differently, one line]"
    comment: ""
    comment: "─────────────────────────────────────"
    optionmenu: "Test", normDefault
        option: "[Test A]"
        option: "[Test B]"

**Verdict states:**

    ✅ Normality looks reasonable
         A parametric test should be safe here.

    ❌ Normality not supported
         Consider nonparametric, or check Info window —
         if p is close to 0.05, parametric tests are
         often still robust with N > 20.

    ⚠️ Small sample (N < 10 per group)
         Shapiro-Wilk may lack power. Consider
         nonparametric to be safe.

### 5. Post-analysis

    comment: "📊 Results are in the Info window."

Minimal. The Info window explanations (emlShowExplanations)
are the real teaching moment.

### 6. Compact wrapper (non-wizard)

    comment: "📋 Table: " + tableName$
    comment: "─────────────────────────────────────"
    [fields only, no teaching content]

Wrappers are for users who know what test they want.
Same context zone, no menu or teaching zones.


## What NOT to Do

- Don't cut teaching text for visual economy
- Don't use tree notation (├── └──) — retired
- Don't use ══════ separators — retired
- Don't use arbitrary colored circles as category markers
- Don't assume the user knows what normality, parametric,
  p-values, or effect sizes mean
- Don't sacrifice clarity for consistency — if one dialog
  needs more explanation than another, it gets more
- Don't add visual elements that don't serve comprehension
- Don't put teaching content above fields unless the user
  needs it to understand the fields


## Rollout Status

Applied:
  [x] Design system v2 defined (11 May 2026)
  [x] Approach 3 selected (emoji echo in dropdowns)
  [x] Color emoji verified on GTK and macOS
  [x] Font size independence verified empirically
  [x] Context bar format: 📋 Table: name + ───── rule

Remaining:
  [ ] Main wizard navigation dialog
  [ ] Compare — observation type
  [ ] Compare — group design
  [ ] All column selection dialogs (6+)
  [ ] All test selection dialogs (4)
  [ ] Relationship navigation
  [ ] Describe navigation
  [ ] Predict column selection
  [ ] Two-factor design
  [ ] Post-analysis dialogs
  [ ] Export dialogs
  [ ] No Table dialog
  [ ] Context bar on wrapper dialogs (separate scope)
