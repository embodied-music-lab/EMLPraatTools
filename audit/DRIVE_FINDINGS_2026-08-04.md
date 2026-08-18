> **Historical record (2026-08-04).** Current finding status lives in `audit/FINDINGS_MACHINE.json`.

# End-to-end path drive — EML Praat Tools plugin

Date: 4 August 2026. Praat 6.6.30, Xvfb :99 1400x1000x24, matchbox WM.
Plugin installed at `/home/claude/drive/prefs/plugin_EML_Praat_Tools`
(copy of `/root/eml_audit/plugin_EML_Praat_Tools`). Loads cleanly at startup.

Task: drive every plugin path through its real entry point, menu-driven first.
Evaluation criteria, in the author's order: **accuracy**, **clarity of Info
window output**, **graphing paths that result**.

Method: GUI driving under Xvfb + matchbox. Harness recipe in
`GUI_HARNESS_RECIPE.md`; helpers in `drive/gui.sh`; menu map in `MENU_MAP.md`.
No headless route exists — `beginPause:` hard-crashes under `praat --run`
(SIGTRAP, exit 133), and every EML wrapper uses `beginPause:`, not `form:`.

Finding classes used below: **ACCURACY** (output is wrong or misleading about
the data/statistics), **CLARITY** (output is correct but harder to act on than
it should be), **PACKAGING** (install/distribution defect), **NOT A DEFECT**
(observation investigated and cleared — recorded so it is not re-raised).

---

## Progress ledger

| Surface | Entries | Driven |
|---|---|---|
| `New → EML Tools` menu | 17 (16 in scope; LMM tabled) | **11** — Create Demo Table (6/7 types), Describe Table column, Check normality, Compare two groups, Compare paired/repeated, Compare k groups (ANOVA), Compare k groups (KW), Compare two-way ANOVA, Correlate two columns, Linear regression, Pairwise comparisons |
| Table action buttons | 9 (8 in scope) | 0 — coordinates mapped |
| TableEditor `Edit` menu | 1 | 0 |
| Sound / Pitch / Spectrum / Ltas → `EML Graphs...` | 4 | 0 |
| TableOfReal action buttons | 6 | 0 |
| Matrix action buttons | 5 | 0 |

`Linear mixed model...` (menu y=701; Table button y=579) is **out of scope** —
the LMM module is tabled by author ruling. Noted, not audited.

---

## Path 1 — `New → EML Tools → Create Demo Table...`

Script: `scripts/eml-create-demo.praat` v2.0 (11 May 2026).
Menu coordinate: `emlmenu 805`.

### Dialog render map (confirmed on two separate invocations)

Under matchbox the Pause dialog carries a titlebar that `xdotool
getwindowgeometry` does **not** account for. All coordinates below are read
directly off a root screenshot, which is the only reliable source.

| Element | Root coords |
|---|---|
| Titlebar `Pause: Create Demo Table` | y ≈ 387 |
| Close box ✖ | (1010, 388) |
| Dialog body | x ≈ 377–1022, y ≈ 377–620 |
| `Select the type of demo data to generate.` | (402, 431) |
| `Each table is designed for a specific analysis path.` | (402, 468) |
| Label `Demo type:` (right-aligned, ends) | x ≈ 638, y = 535 |
| Combo box | x ≈ 645–1017, y = 535; click target **(830, 535)** |
| Button `Undo` | (436, 581) |
| Button `Quit` | (604, 581) |
| Button **`Create`** | **(793, 581)** — verified working twice |

Source contract: `clicked = endPause: "Quit", "Create", 2, 0`. `Undo` is
Praat's native pause-window revert, not plugin-authored.

Drive sequence: `emlmenu 805` → `optsel 830 535 <n>` → `click 793 581` →
`infoshot demo<n>_info`.

### Demo type 1 — `demo_2groups`

Info window, verbatim:

```
Created demo Table: demo_2groups

Two-group comparison (Control vs Patient).
  Try: Compare groups → Independent → Two groups
  Data column: jitter_pct or F0_Hz
  Group column: group

Select the Table and use the EML Tools menu or Wizard.
```

**Accuracy: correct.** Table name, group labels (Control / Patient), N=40, and
column names `subject group F0_Hz jitter_pct` all match the `demo_type = 1`
branch of `eml-create-demo.praat`.

### Demo type 2 — `demo_3groups`

Info window, verbatim:

```
Created demo Table: demo_3groups

Three-group comparison (Soprano / Mezzo / Alto).
  Try: Compare groups → Independent → Three or more
  Data column: SPL_dB or vibrato_rate_Hz
  Group column: voice_type

Select the Table and use the EML Tools menu or Wizard.
```

**Accuracy: correct.** Table name, the three voice types, and the column names
`singer voice_type SPL_dB vibrato_rate_Hz` (N=45, 3×15) all match the
`demo_type = 2` branch.

### Finding D1 — CLARITY (low) — `Try:` line paraphrases the Wizard's labels

Applies to both demo types observed so far; likely to all seven.

The guidance line is written as a navigation path but does not quote the
labels the user will actually see:

| Info text | Actual Wizard label |
|---|---|
| `Compare groups` | `⚖️ Compare groups or conditions` (Q1 `Research goal`) |
| `Independent` | `No — different groups (independent)` (A1 `Observation type`) |
| `Two groups` | `Two groups` (A2 `Group design`) — matches literally |
| `Three or more` | `Three or more groups` (A2 `Group design`) |

For type 1 the third element matches; for type 2 it is abbreviated. The first
two elements are paraphrases in both cases.

Secondary: the line names only the Wizard route. For a user already sitting in
`New → EML Tools`, the shorter routes are the direct entries — `Compare two
groups...` (type 1) or `Compare k groups (ANOVA)...` / `Compare k groups
(Kruskal-Wallis)...` (type 2). Those are not mentioned.

Not an accuracy defect: the path described does reach the right analysis. It
is a discoverability cost, and the fix is a text edit in
`eml-create-demo.praat`'s `description$` assignments.

### Finding D2 — NOT A DEFECT — dismissed Pause windows persist in the X window list

`xdotool search --name "^Pause:"` returns ids for dialogs that were dismissed
several steps earlier. Investigated with `xwininfo -id <id>`:
`Map State: IsUnMapped`. Praat retains dismissed Pause windows as unmapped X
windows; this is normal GTK/Praat retention, invisible to the user.

Consequence for the harness, not for the plugin: any window lookup must filter
on `IsViewable`. `drive/gui.sh`'s `pausewin` helper does this.

### Note — demo data are unseeded

`eml-create-demo.praat` generates values with `randomGauss` and sets no seed.
Every invocation produces different numbers. Any accuracy finding derived from
a demo table's *values* is therefore not reproducible by re-running the demo —
such a finding must record the observed values inline.

---

## Finding P1 — PACKAGING (medium) — 13 of 21 files in `scripts/` are mode 0600

`ls -l /root/eml_audit/plugin_EML_Praat_Tools/scripts/`:

| Mode | Files |
|---|---|
| 0644 | eml-batch-process, eml-check-normality, eml-create-demo, eml-describe-table, eml-graphs, eml-lmm, eml-quick-start, eml-regress (8) |
| **0600** | eml-compare-groups, eml-compare-k-groups, eml-compare-kw, eml-compare-paired, eml-compare-twoway, eml-correlate, eml-edit-table-editor, eml-edit-table-launch, eml-edit-table, eml-pairwise, eml-stats-demo, eml-tutorial, eml-wizard (13) |

(13 at 0600 by the current listing; the earlier tally of 12 excluded the
unregistered `eml-tutorial.praat`, which is dead but still shipped.)

Owner-only permissions survive `tar`/`zip` archives. A user who unpacks the
plugin under one account and runs Praat under another — or any multi-user or
lab-shared install — gets a plugin whose menu entries are registered but whose
scripts cannot be read. The failure would surface as a Praat error at click
time, not at install time, which makes it hard to diagnose.

Fix is one line at package time: `chmod 644` across the tree, or a `chmod` step
in `dev/tools/` packaging. Worth adding to the build so it cannot regress.

---

## Harness facts established (see GUI_HARNESS_RECIPE.md for the full recipe)

- `optsel` (click combo → `Home` → `Down`×(n−1) → `Return`) is **verified**
  against a real Praat GTK option menu: `optsel 830 535 2` moved the Demo type
  combo from option 1 to option 2 and the resulting table confirmed it.
- `objshot` and `infoshot` correctly raise and capture their windows after a
  dialog closes.
- Never compute click coordinates from `xdotool getwindowgeometry` — matchbox
  draws a dialog titlebar the reported geometry excludes. Read a screenshot.
- Praat submenus do not open on hover or click under matchbox. Press `Right`.

---

## Screenshots

`/home/claude/drive/out/shots/`: `state0.png`, `demo_dlg.png`,
`demo_dlg_win.png`, `demo1_after.png`, `demo1_info.png`, `demo_dlg2.png`,
`demo_opt2.png`, `demo2_after.png`, `demo2_info.png`.

### Demo type 3 — `demo_paired`

Info window, verbatim:

```
Created demo Table: demo_paired

Paired pre/post therapy comparison.
  Try: Compare groups → Paired / repeated
  Column 1: jitter_pre (or HNR_pre)
  Column 2: jitter_post (or HNR_post)

Select the Table and use the EML Tools menu or Wizard.
```

**Accuracy: correct.** Matches the `demo_type = 3` branch: table `demo_paired`,
20 rows, columns `subject jitter_pre jitter_post HNR_pre HNR_post`.

### Demo type 4 — `demo_correlation`

```
Created demo Table: demo_correlation

Bivariate relationship (speaking F0 vs singing F0).
  Try: Examine a relationship → Correlation
  Column X: speaking_F0_Hz
  Column Y: singing_F0_Hz

Select the Table and use the EML Tools menu or Wizard.
```

**Accuracy: correct.** Matches `demo_type = 4`: 30 rows, columns
`speaker speaking_F0_Hz singing_F0_Hz age_years`. The Info text names only the
two correlated columns; `age_years` exists in the table but is not mentioned.
Not a defect — it is not part of the suggested analysis.

### Demo type 5 — `demo_regression`

```
Created demo Table: demo_regression

Predictor → outcome relationship.
  Try: Predict an outcome (or Examine → Regression)
  Predictor (X): practice_hrs_wk
  Response (Y): vibrato_regularity_pct

Select the Table and use the EML Tools menu or Wizard.
```

**Accuracy: correct.** Matches `demo_type = 5`: 25 rows, columns
`singer practice_hrs_wk vibrato_regularity_pct experience_yrs`.

### Demo type 6 — `demo_twoway`

```
Created demo Table: demo_twoway

Two-factor design (voice_type × task).
  Try: Compare groups → Independent → Two-factor design
  Data column: SPL_dB
  Factor 1: voice_type
  Factor 2: task
  Note: contains an interaction effect

Select the Table and use the EML Tools menu or Wizard.
```

**Accuracy: correct.** Matches `demo_type = 6`: 48 rows built as
2 voice types × 2 tasks × 12 subjects, columns
`subject voice_type task SPL_dB`. The interaction note is a useful addition —
it tells the user what the data were built to demonstrate. **No other demo
type carries an equivalent "what this data shows" line**; see D3.

### Demo type 7 — NOT DRIVEN

Type 7 (`demo_normality`, 40 rows, columns `subject F0_Hz shimmer_pct
jitter_pct` per source) was not driven before the session was checkpointed.
Drive sequence to complete it: `emlmenu 805` → `optsel 830 535 7` →
`click 793 581` → `infoshot demo7_info`.

### Finding D1 — status update

D1 (the `Try:` line paraphrases rather than quotes the Wizard's labels) is
**confirmed to generalize** across all six demo types driven. Every one names a
navigation path in abbreviated form:

| Info text | Actual Wizard label |
|---|---|
| `Compare groups` | `⚖️ Compare groups or conditions` |
| `Independent` | `No — different groups (independent)` |
| `Paired / repeated` | paired/repeated option on A1 |
| `Examine a relationship` | Q1 goal, abbreviated |
| `Predict an outcome` | Q1 goal, abbreviated |
| `Two-factor design` | A2 `Group design` |

Type 5 is the one case where the line offers two routes
(`Predict an outcome (or Examine → Regression)`). The fix remains a text edit
to the `description$` assignments in `eml-create-demo.praat`.

### Finding D3 — CLARITY (low) — only type 6 states what the data demonstrate

`demo_twoway` ends its guidance with `Note: contains an interaction effect`.
That single line is the most useful sentence in any of the six Info outputs —
it tells the user what result to expect, which is what makes a demo table
pedagogically useful rather than merely well-formed. No other type has one,
though several are built with a known effect (type 3 has a pre/post shift,
type 4 and 5 have built-in correlations of known sign).

Suggested fix: give every branch a `Note:` line stating the effect the
generator built in. Cheap, and it turns the demo tables into a teaching
sequence rather than seven anonymous data sets.

---

## Checksum verification — 2026-08-05

Four-way md5 comparison run to establish the restore point.

| Comparison | Result |
|---|---|
| `/root/eml_audit/plugin_EML_Praat_Tools` vs installed copy at `/home/claude/drive/prefs/plugin_EML_Praat_Tools` | **byte-identical** (104 files) — the drive is exercising the audit tree, not a stale copy |
| audit tree vs `plugin_EML_Praat_Tools/` inside `EML_backup_2026-08-05.zip` | **byte-identical** (104 files) — backup is a valid restore point |
| audit tree, files with mtime >= 2026-08-05 | **none** — no plugin file was touched this session; the drive was read-only against plugin code, now proven rather than inferred |
| audit tree vs `EML_Praat_Tools_S9_FIXED_2026-08-02.zip` | **NOT identical** — S9 is stale by design (see below) |

**S9 zip is superseded.** It has 74 files; the audit tree has 104. The delta is
Aug 3–4 work committed after S9 was packaged:

- Runtime files changed: `stats/eml-inferential.praat` (2026-08-03 01:20),
  `graphs/eml-draw-procedures.praat` (2026-08-03 23:13), `MANIFEST.txt`.
- New dev material: `dev/tools/` (16 files — build-manifest, registry
  reconcilers, relerr conversion, vacuity + degenerate-input scanners,
  Theil–Sen margin builders), Theil–Sen tests and refs
  (`test-theilsen.praat`, `theilsen_scipy_refs.py`, `theilsen_margin_rows.json`),
  repeated-measures tests and refs (`test-repeated-measures.praat`,
  `repeatedmeasures_refs.py`, `verify-repeated-measures.R`),
  `test-helpers-selftest{,-negative}.praat`, `REFERENCE_PROVENANCE.md`,
  `verify-inferential-batch7-dunn.py`, `regression_scipy_refs.py`.
- Two files relocated, not lost: `dev/tests/phase2/test_coltype.praat` and
  `dev/tests/tables/spaghettit table.csv` now live under `dev/retired/`
  (md5 unchanged for the CSV: `3b003ade…`).

**Consequence:** `EML_Praat_Tools_S9_FIXED_2026-08-02.zip` must NOT be used as
the restore point — restoring from it would silently roll back the Theil–Sen
and repeated-measures work and the 3 Aug inferential/draw fixes. The restore
point is `EML_backup_2026-08-05.zip`. No redistributable build has been cut
since S9; one is owed before release.

---

## Demo type 7 — `demo_normality` — DRIVEN 2026-08-05 — ACCURATE

Info window (verbatim, via `info$()` dump — exact characters, not transcribed):

```
Created demo Table: demo_normality

Data with different distributional shapes.
  Try: Describe or summarize → Check normality
  F0_Hz: approximately normal
  shimmer_pct: right-skewed (try nonparametric)
  jitter_pct: mildly skewed

Select the Table and use the EML Tools menu or Wizard.
```

Objects window after: `1  Table demo_normality` (single object, no leftovers).

Verified against `scripts/eml-create-demo.praat`, `elsif demo_type = 7`:
40 rows, columns `subject F0_Hz shimmer_pct jitter_pct`; `F0_Hz` =
`randomGauss (180, 30)` (normal), `shimmer_pct` = `exp (randomGauss (0.7, 0.5))`
(lognormal → right-skewed), `jitter_pct` = `max (0.05, randomGauss (1.2, 0.6))`
(Gaussian with a floor → mild left-truncation). The description string matches
the rendered output character for character, and each distributional claim
matches its generator. **No defect.**

All 7 demo types are now driven. Ledger row 1 (`Create Demo Table`) is complete.

### Finding D3 — REVISED (was: "only demo_twoway states the built-in effect")

Original wording was too strong. Corrected scope: types **6** (`Note: contains
an interaction effect`) and **7** (three per-column distribution notes) both
disclose what the synthetic data were constructed to contain. Types **1–5** do
not. The finding stands but applies to five branches, not six: a learner running
`demo_paired` cannot tell whether a significant result is the fixture working as
designed or an artefact. Suggested fix unchanged — one `Note:` line per branch
in `description$`.

### Finding D1 — holds for type 7

`Try: Describe or summarize → Check normality`. "Describe or summarize" is not
a menu label; the actual entries are `Describe Table column` and
`Check normality`. Second half quotes correctly, first half paraphrases —
the same split seen in types 1–6.

---

## Wrapper 2/17 — `Describe Table column` — DRIVEN 2026-08-05 — **ACCURATE**

Menu y=473. Dialog `Pause: Describe Table Column` 524x152 at 0,0.
Fields: one `optionmenu` Column (populated by `@emlTableColumnNames`, showed
`F0_Hz` correctly). Buttons: Undo (56,116) / Quit (223,116) / Run (413,116).
`endPause: "Quit", "Run", 2, 0` — trailing 0 per Appendix F §S0. ✓

Input: `demo_normality`, column `F0_Hz`, n=40 (unseeded `randomGauss (180, 30)`).

### Verbatim Info window output (via `info$ ()` dump)

```
══════════════════════════════════════════════
  EML Stats : Descriptive Statistics
  Wed Aug  5 12:17:11 2026
══════════════════════════════════════════════

  Table               demo normality
  Column              F0 Hz
  N (valid)           40

  ── Central Tendency ────────────────────────
  Mean                182.7905
  Median              179.0535
  SEM                 4.9057

  ── Dispersion ──────────────────────────────
  SD                  31.0266
  Variance            962.6472
  Range               114.5782
  Min                 121.7456
  Max                 236.3238

  ── Quartiles ───────────────────────────────
  Q1                  162.0658
  Q2 (Median)         179.0535
  Q3                  207.6302
  IQR                 45.5644

  ── Distribution Shape ──────────────────────
  Skewness            0.0275
  Kurtosis            -0.8188

  ── 95% Confidence Interval ─────────────────
  Lower               172.8677
  Upper               192.7133

══════════════════════════════════════════════
```

### ACCURACY — verified, 18/18 values

The 40 `F0_Hz` values were dumped from the live Table and recomputed
independently in Python. Every reported figure matches to the printed
4-decimal precision:

| Measure | Plugin | Independent | Match |
|---|---|---|---|
| Mean | 182.7905 | 182.7905 | ✓ |
| Median | 179.0535 | 179.0535 | ✓ |
| SEM | 4.9057 | 4.9057 | ✓ |
| SD | 31.0266 | 31.0266 (n−1) | ✓ |
| Variance | 962.6472 | 962.6472 (n−1) | ✓ |
| Range / Min / Max | 114.5782 / 121.7456 / 236.3238 | identical | ✓ |
| Q1 / Q3 / IQR | 162.0658 / 207.6302 / 45.5644 | type-7 linear interp. | ✓ |
| Skewness | 0.0275 | G1 = 0.0275 (adjusted) | ✓ |
| Kurtosis | −0.8188 | G2 = −0.8188 (adjusted excess) | ✓ |
| 95% CI | 172.8677 – 192.7133 | m ± t(39,.975)·SEM | ✓ |

Estimator conventions identified empirically: **SD/variance use n−1**;
**quartiles use type-7 linear interpolation** (R/numpy default — NOT
Tukey hinges, which would give 160.9348 / 207.9760); **skewness and
kurtosis use the sample-adjusted G1/G2 forms** (SPSS/Excel convention —
NOT the population g1/g2 forms, which would give 0.0265 / −0.8663);
**CI uses the t distribution with n−1 df**, not z. All four are the
defensible choices for a research tool. No accuracy defect.

### GRAPHING — none offered

`endPause` presents only Quit/Run; there is no completion dialog and
therefore no `Draw` path. A single-column descriptive summary is the
one place a histogram or box plot would be most expected. Deferred
judgment: `Check normality` (next wrapper) may cover this need — if it
draws a histogram/QQ for the same column, the absence here is a
reasonable division of labour, not a gap. **Revisit after wrapper 3.**

### Findings

**D4 — CLARITY (medium).** The report line reads `Kurtosis`, but the
value is **excess** kurtosis (normal = 0, not 3). The plugin's own
`emlDescribe.summary$` in `stats/eml-core-descriptive.praat:655` labels
the identical quantity `"Kurtosis (excess):"` — so the distinction was
recognised and then dropped on the path that users actually see. A
reader who takes −0.8188 as Pearson kurtosis will misreport it by 3.
Fix: `@emlReportLine: "Kurtosis (excess)", ...` in
`scripts/eml-describe-table.praat:151`.

**D5 — CLARITY (low).** No estimator conventions are disclosed anywhere
in the report. Skewness/kurtosis adjusted-vs-population and the
quartile method are exactly the values a user will paste into a paper,
and they differ visibly between packages (see table above: 0.0275 vs
0.0265; 162.07 vs 160.93). One footer line — e.g. `SD/variance n−1 ·
quartiles type 7 · skew/kurtosis G1/G2 · CI t(n−1)` — makes the output
citable. Applies to `@emlReportFooter` and therefore to every stats
wrapper, not just this one.

**D6 — CLARITY (medium).** Identifiers are underscore-stripped for
display: `demo_normality` → `demo normality`, `F0_Hz` → `F0 Hz`
(`eml-describe-table.praat:114–115`). Underscore→space conversion is a
**Picture window** rule — `_` is a subscript toggle in Praat's text
renderer (Rule 28B, Appendix E). The Info window renders plain text and
has no such toggle, so the conversion buys nothing and costs the
round-trippable name: a user cannot copy `F0 Hz` back into a script or
match it against the Table. Fix: report `tableName$` / `dataColumn$`
verbatim in Info window output; keep `replace$` only for text bound for
`Text top:` / `Text left:` / `Draw` paths.

**D7 — PACKAGING / Rule 35 (low).** `emlDescribe.summary$` is assembled
on every call (16 string concatenations) and consumed nowhere in
production — the only reference outside its own file is a
non-emptiness assertion in `dev/tests/phase1/test-core-descriptive.praat:530`.
It is also the source of the D4 label divergence. Either delete it, or
make the wrappers render it so the two labellings cannot drift again.

### NOT A DEFECT

Info window **appends** rather than clears. This is deliberate and
documented: `emlReportHeader` carries the comment *"Always appends —
never clears. Use @emlClearInfo for explicit clearing"*
(`stats/eml-output.praat:110–113`), and `@emlClearInfo` exists for the
user-facing toggle. The accumulating session log is the intended
behaviour; the earlier `OBJECTS` block visible above the report was my
own harness output, not wrapper leakage.

---

## Wrapper 3/17 — `Check normality` — DRIVEN 2026-08-05 — **ACCURATE**

Menu y=498. Dialog `Pause: Check Normality` 524x395 at 0,0.
Fields: informational header, a bulleted preview of the 3 numeric columns
it will test, optional `Group column:` optionmenu (default
`(none — overall only)`), and a `Clear Info window` checkbox (278,313) —
the user-facing control that `@emlClearInfo` was built for. Buttons Undo
(56,359) / Quit (223,359) / Run (413,359). `endPause: "Quit", "Run", 2, 0`. ✓

Input: `demo_normality`, all 3 numeric columns, overall (no grouping),
Clear Info window ticked.

### ACCURACY — verified against scipy, 3/3 columns

Shapiro–Wilk is implemented in pure Praat. All three columns were dumped
from the live Table and re-tested with `scipy.stats.shapiro` (Royston's
AS R94):

| Column | Plugin W | scipy W | Plugin p | scipy p |
|---|---|---|---|---|
| `F0_Hz` | 0.9724 | 0.9724 | p = .428 | 0.4282 |
| `shimmer_pct` | 0.8760 | 0.8760 | p < .001 | 0.0004 |
| `jitter_pct` | 0.9638 | 0.9638 | p = .225 | 0.2251 |

Exact to 4 decimals on every W and p. Descriptives (mean/SD/median) also
match independently recomputed values on all three columns. The
directional verdicts are right, the per-column recommendations are right,
and the roll-up (`Parametric OK: 2 / Nonparametric rec: 1 / Mixed results`)
is right. This is the strongest single piece of evidence so far that the
statistical core is trustworthy — a hand-rolled Shapiro–Wilk agreeing
with scipy to 4 dp is not something that happens by accident.

Behavioural note: the demo data cooperated exactly as
`eml-create-demo.praat` type 7 advertises — `F0_Hz` normal,
`shimmer_pct` right-skewed and rejected, `jitter_pct` mildly skewed and
not rejected.

### GRAPHING — none offered; **this is now a gap**

Completion dialog is `endPause: "Done", "New", 2, 0` — *"Results are in
the Info window."* with Done / New only. **No `Draw`.**

Wrapper 2 (`Describe Table column`) also offered no graph, and I deferred
judgment there pending this wrapper. That deferral now resolves against
the plugin: **neither of the two distribution-inspection wrappers can
draw a histogram, density, box plot, or Q–Q plot.** Normality assessment
is the single place in the whole tool where a picture carries information
the numbers cannot — Shapiro–Wilk at n=40 is underpowered against exactly
the mild departures a Q–Q plot makes obvious, and the plugin's own
verdict line ("Does not reject normality") is the one most likely to be
over-read. `EML Graphs` exists as a separate menu entry, so the capability
is in the codebase; the connection from the verdict to the picture is
what's missing. Logged as **D8** below.

### Findings

**D8 — GRAPHING (high).** Add a `Draw` button to the `Check normality`
completion dialog (`eml-check-normality.praat:219`, currently
`endPause: "Done", "New", 2, 0` → `"Done", "Draw", "New", 3, 0`)
producing a Q–Q plot plus histogram-with-normal-overlay for the tested
column(s). Same for `Describe Table column`. This is the highest-value
graphing gap found so far because it is where the numeric verdict is
least self-sufficient.

**D9 — CLARITY (high, systemic, one-line fix).** The p-value row prints
its label twice:

```
  p                   p = .428
```

`@emlFormatP` returns an APA *inline* string that already carries its own
`"p "` prefix (`stats/eml-output.praat:210–239` — by design, documented in
its header comment). Passing that string to
`@emlReportLineString: "p", ...` puts the prefix in the value column next
to a `p` label. This is **not** a one-off: there are **10 occurrences** of
`emlReportLineString: "p"` in `graphs/eml-annotation-procedures.praat`
(lines 2598, 2647, 2752, 2992, 3267, 3303, 3390, 3518, 3613, 3660), i.e.
essentially every inferential wrapper in the plugin prints `p   p = .xxx`.
Cleanest fix: add a bare output to `@emlFormatP` (`.bare$` = `".428"` /
`"< .001"`) and use it in the two-column report path, keeping
`.formatted$` for inline prose. One procedure change, 10 sites corrected.

**D10 — ACCURACY-adjacent (medium-high). Kurtosis threshold is very
likely off by 3.** `emlReportNormalityAnalysis`
(`graphs/eml-annotation-procedures.praat:3491–3501`) flags shape with:

```praat
if abs (...skewness) >= 1      → "outside typical limits (|skew| < 1)"
if abs (...kurtosis) >= 3      → "outside typical limits (|kurt| < 3)"
```

The value being tested is `@emlKurtosis`, which returns **excess** (G2)
kurtosis — verified empirically in wrapper 2 (−0.8188 = G2, not the
Pearson 2.1812). For excess kurtosis, normal = 0 and the conventional
screening rule is |G2| > 2 (or Kline's > 10 for severe). A threshold of
**3** is precisely the number one uses against *Pearson* kurtosis, where
normal = 3 — and applied to excess kurtosis it silently widens the
"typical" band to include genuinely heavy-tailed data: a column with
G2 = 2.9 (visibly leptokurtic) is reported *within typical limits*. The
skewness threshold (|g| ≥ 1) is a recognised rule; |excess kurt| ≥ 3 is
not a recognised pairing with it. Recommend `>= 2`, and state the
criterion in both branches (currently the criterion is printed only when
the test *fails*, so a passing reader never learns what was checked).
This finding is bound to **D4** — both trace to `Kurtosis` being reported
and reasoned about without the word "excess".

**D6 — CONFIRMED PLUGIN-WIDE, and now self-inconsistent.** The dialog
header reads `Table: demo normality` (underscore stripped) while the
column list immediately below it reads `F0_Hz`, `shimmer_pct`,
`jitter_pct` (underscores intact) — the same dialog displays both
conventions four lines apart. The report body then strips again
(`Column   shimmer pct`). The stripping is centralised in
`@emlUnderscoreToSpace` (called at
`eml-annotation-procedures.praat:3458–3461`), so scoping it to
Picture-window-bound text is a single-procedure change.

**D11 — CLARITY (low).** `"→ Skewness outside typical limits (|skew| < 1)"`
reads as an assertion of `|skew| < 1` at the moment it is announcing the
opposite. Phrase the parenthetical as a stated criterion —
`(criterion: |skew| < 1)` — and print it on the passing branch too.

### Not investigated this pass

`emlShowExplanations` was off, so the `Why:` / `@emlWizardExplain*`
narration branches (7 call sites in this procedure alone) did not render.
Those are the novice-facing path and need their own drive — noted for the
`EML Stats Quick Start` wrapper, which is the likely place the toggle is set.

---

## Wrapper 4/17 — `Compare two groups…` (menu y=524)

Driven twice against `demo_2groups` (40 rows, 20 Control / 20 Patient),
once on `jitter_pct` and once on `F0_Hz`, each time all the way through
the graphing chain the completion dialog offers:

    Compare Two Groups → Analysis complete (Done | CSV | Draw | New)
      → Draw → EML Graphs (type/title/subtitle/colour/size)
        → Violin Plot — Column Mapping (Undo | Go Back | Quit | Advanced | Draw)
          → Draw → Graph Complete (Done | Save | Exp CSV | Redraw)

`Done` on Graph Complete returns to the *Analysis complete* dialog rather
than exiting — the caller is correctly re-entered, so the user can take
`CSV` after drawing. Good behaviour, worth keeping.

### Verdict: ACCURACY — exact

Both runs reproduce independently. `F0_Hz` run, plugin output against
`scipy.stats` on the 40 dumped rows:

| Quantity | Plugin | scipy / numpy |
|---|---|---|
| Control n / mean / SD / median | 20 / 122.95 / 13.02 / 126.28 | 20 / 122.9535 / 13.0192 / 126.2812 |
| Patient n / mean / SD / median | 20 / 148.72 / 20.29 / 145.43 | 20 / 148.7164 / 20.2904 / 145.4281 |
| Welch t | −4.779 | −4.7791 |
| Welch df | 32.4 | 32.3774 |
| p | p < .001 | 3.678e−05 |
| Mean difference | −25.7629 | −25.7629 |
| Cohen's d | −1.511 | −1.5113 |
| Hedges' g | −1.481 | −1.4813 |

The `jitter_pct` run matched equally (t −9.495 vs −9.4948, df 29.1 vs
29.0615, d −3.003, g −2.943, p 2.07e−10). Hedges' correction uses
J = 1 − 3/(4N − 9) = 0.98013 at N = 40, which is the standard form.
Welch as the *default* two-sample test is good practice and is the right
call for a plugin aimed at unequal-variance clinical group data.

### G1 — GRAPHING (high). `roundTo = 10` is a hardcoded magic number in every `@emlComputeAxisRange` call.

`@emlComputeAxisRange` (`graphs/eml-graph-procedures.praat:765–817`) takes
`.roundTo` as a caller-supplied grid quantum and snaps the axis with
`floor(rawMin/.roundTo)*.roundTo` / `ceiling(rawMax/.roundTo)*.roundTo`.
Roughly 20 call sites pass the literal `10`.

That literal is correct only for data on the order of tens to hundreds —
F0 in Hz, intensity in dB, duration in ms. For any measure living on a
0–10 scale (jitter %, shimmer %, proportions, semitone deviations, HNR in
some ranges) it quantises the axis to a decade grid the data never
approaches. The `jitter_pct` violin — data spanning **0.10 to 3.60** —
was drawn on a y-axis of **−10 to +10**, a 2.5× overshoot that squashed
both violins into a thin central band and made the between-group
separation, which is enormous (d = −3.0), read as visually negligible.

Confirmed scale-bound, not total: the same wrapper on `F0_Hz`
(103.66–189.41) drew **80–220**, which is well proportioned. The failure
is a function of data magnitude only.

`@emlComputeNiceStep` already exists in the codebase and is the obvious
supplier. Recommend deriving `roundTo` from the magnitude of the buffered
range rather than pinning it. Note that `roundTo <= 0` is currently the
`badInput` sentinel, so an "auto" mode needs a new sentinel path (or a
distinct `@emlComputeAxisRangeAuto`) rather than overloading 0.

### G2 — GRAPHING (high). The KDE pre-expansion overwrites `.globalMin` in place, defeating the non-negative guard.

`@emlDrawViolinPlot` (`graphs/eml-draw-procedures.praat:1930`, defect at
**2033–2034**) widens the range by the largest per-group Silverman
bandwidth so violin tails do not collide with the axis edge — a sound
intention:

    .globalMin = .globalMin - .maxBW
    .globalMax = .globalMax + .maxBW
    @emlComputeAxisRange: .globalMin, .globalMax, 10, 0

The assignment is in place, so the true data minimum is destroyed before
`@emlComputeAxisRange` ever sees it. That matters because the procedure's
own protection is written as:

    if .dataMin >= 0 and .axisMin < 0
        .axisMin = 0
    endif

`.dataMin` is now the *bandwidth-inflated* minimum. For `jitter_pct`:
maxBW = max(0.1480, 0.2764) = 0.2764, so `.dataMin` arrives as
0.10 − 0.2764 = **−0.1764**; the guard tests `−0.1764 >= 0`, fails, and
never fires. Full arithmetic, which reproduces the rendered axis exactly:

    range  = 3.6047 − (−0.1764)      = 3.7811 … + tail  → 4.0575
    buffer = 0.40575
    rawMin = −0.5822 → floor(−0.05822) × 10 = −10
    rawMax =  4.2869 → ceiling(0.42869) × 10 =  10

This violates Rule 28F outright — *"For non-negative data, do not let
axisMin go below 0"* — and it does so on a quantity that is not merely
non-negative by luck: `scripts/eml-create-demo.praat:47` generates
`jitter_pct` as `max (0.1, randomGauss (0.8, 0.3))`, an explicit floor.
Percent jitter cannot be negative, and a figure whose axis says it can be
is wrong in a way a reviewer will notice.

Fix: preserve the true extreme before the expansion and clamp after —

    .dataTrueMin = .globalMin
    ... expansion ...
    @emlComputeAxisRange: .globalMin, .globalMax, <auto>, 0
    .autoYMin = emlComputeAxisRange.axisMin
    if .dataTrueMin >= 0 and .autoYMin < 0
        .autoYMin = 0
    endif

G1 and G2 compound: G2 alone would have produced a small negative
excursion; `roundTo = 10` magnifies it to a full decade. Either fix alone
improves the figure; both are needed for it to be right.

### G3 — GRAPHING (low). Axis labels lose their unit convention to the underscore rule.

The y-label rendered as `F0 Hz` and, in the jitter run, `Jitter pct` —
`@emlUnderscoreToSpace` applied to a column identifier. Rule 28C asks for
`Frequency (Hz)`, `Jitter (%)`. Auto-deriving a label from a column name
cannot always recover the unit, but the common trailing-token cases
(`_Hz`, `_pct`, `_dB`, `_ms`, `_s`, `_semitones`) are worth a lookup that
emits `F0 (Hz)` / `Jitter (%)`, falling back to the current behaviour
otherwise. Note `%` must then go through `@emlSanitizeLabel` (Rule 28J).

### D6 — reconfirmed, and sharper here than in wrapper 3

The `Compare Two Groups` dialog header shows `Table: demo_2groups` with
the underscore **intact**; the Info window four lines later prints
`Table   demo 2groups` and `Data column   F0 Hz`, stripped. Same session,
same identifiers, two conventions. Underscore→space is a *Picture window*
convention (Rule 28B) and it has leaked into plain-text reporting, where
it silently renames the user's data. Scoping `@emlUnderscoreToSpace` to
drawing-bound text remains a single-procedure change.

### D9 — reconfirmed

The report again prints `p                   p < .001` — label emitted by
the caller, second `"p "` already carried inside
`@emlFormatP.formatted$`. Ten sites listed under D9 in the wrapper 3
section; this wrapper is an eleventh consumer of the same procedure, so
the fix belongs in `@emlFormatP` (drop the prefix, let callers label),
not in the call sites.

### D12 — CLARITY (medium). No CI on the mean difference.

The report gives `Mean difference   −25.7629` bare. The `Describe Table
column` wrapper *does* print a 95% CI, so the convention exists in the
plugin and is simply absent from the comparison that most needs it. For a
Welch test the interval is `diff ± t(α/2, df_welch) · SE_diff`, and all
three inputs are already computed at that point in the procedure. Effect
sizes get no interval either; a CI on Hedges' g is a larger job and can
wait, but the mean-difference CI is essentially free.

### D13 — CLARITY (medium). Subtraction direction is never stated.

`Mean difference   −25.7629` does not say which group was subtracted from
which. The dialog *has* a `Group order` field (`Table order` /
alphabetical), so the direction is a user-controlled quantity that the
report then declines to echo. A reader cannot tell whether Patients are
25.76 Hz higher or lower without inferring it from the group means table.
Recommend `Mean difference (Control − Patient)   −25.7629`, built from the
same ordered group labels the table above already prints.

### D14 — CLARITY (low). p is floored at .001 with no exact value anywhere.

Both runs printed `p < .001` for p values of 3.7e−05 and 2.1e−10 — four
and nine orders of magnitude apart, reported identically. `p < .001` is
APA-acceptable prose, but the exact value should be recoverable; the
natural home is the `CSV` export from the same dialog. Worth checking
whether the CSV carries full precision (not yet driven) and, if not,
adding it there rather than cluttering the Info window.

### Not a defect — checked and cleared

- **Figure title.** An initial run drew no title and I nearly logged it.
  The cause was the harness: under matchbox, `xdotool windowraise` is not
  enough to make a GTK entry accept keystrokes — the click sets the caret
  but the field receives no key events and the dialog proceeds with the
  empty default. With `xdotool windowfocus` added (`typein` in `gui.sh`),
  `Title` and `Subtitle` both render correctly, centred above the plot in
  the expected hierarchy. **No plugin defect.** The general lesson: an
  empty-looking field after typing is a harness failure until a
  post-typing screenshot proves otherwise.
- **Legend.** Absent, correctly — one series, categorical x-axis already
  labelled `Control` / `Patient`. Rule 28D not triggered.
- **Welch default.** Correct choice, not a finding.

---

## Wrapper 5/17 — `Compare paired/repeated` (menu y = 549)

**Dialog:** "Compare Paired Observations" (524x435).
Fields: Column 1 (385,107), Column 2 (385,139), Test (385,171),
Subject column (385,267), Group column (385,299),
Clear Info window (278,353). Buttons: Undo 56,399 / Quit 223,399 /
Run 413,399.

**Driven with:** Table `demo_paired`, Column 1 = `jitter_pre`,
Column 2 = `jitter_post`, Test = `Paired t-test`, Clear Info checked.

### Info report as emitted (verbatim)

```
  EML Stats : Paired Comparison
  Table               demo paired
  Column 1            jitter pre
  Column 2            jitter post
  N (pairs)           20

  jitter pre: Mean = 2.256, SD = 0.826, Median = 2.468
  jitter post: Mean = 1.435, SD = 0.851, Median = 1.627

  ── Paired t-test ───────────────────────────
  t                   11.117
  df                  19
  p                   p < .001
  Mean difference     0.8208
  SD of differences   0.3302

  ── Effect Size ─────────────────────────────
  Matched-pairs r     1.000
  Magnitude           large effect
```

### ACCURACY — test statistics exact

Verified against scipy on `dump_demo_paired.csv` (full precision):

| Quantity | Plugin | Reference | Verdict |
|---|---|---|---|
| t | 11.117 | 11.1172 | exact |
| df | 19 | 19 | exact |
| Mean difference | 0.8208 | 0.8208 | exact |
| SD of differences | 0.3302 | 0.3302 | exact |
| jitter_pre mean / SD / median | 2.256 / 0.826 / 2.468 | 2.2558 / 0.8262 / 2.4679 | exact |
| jitter_post mean / SD / median | 1.435 / 0.851 / 1.627 | 1.4351 / 0.8509 / 1.6275 | exact |

The paired t-test itself is correct in every printed digit.

### D15 — ACCURACY, HIGH — nonparametric effect size reported under the parametric test

`Matched-pairs r 1.000` is **not** an effect size for the paired
t-test. It is the matched-pairs rank-biserial correlation (Kerby
2014), which the library's own docstring identifies as belonging to a
different test — `stats/eml-inferential.praat:1311`:

```
# Matched-pairs rank-biserial correlation: effect size for the Wilcoxon
# signed-rank test.
```

The arithmetic is correct. `@emlMatchedPairsR` computes
`r = (T+ - T-) / sMax` after running `@emlWilcoxonSignedRank`
internally. All 20 `jitter_pre - jitter_post` differences are
positive (min 0.2991, max 1.3303, zero negatives, zero ties), so
`T- = 0`, `T+ = sMax`, and `r = 1.000` exactly. The defect is not in
the computation — it is that this statistic is printed as *the*
effect size in the **Paired t-test** block.

Source: `graphs/eml-annotation-procedures.praat`. The identical
`emlMatchedPairsR.r` is emitted in both branches — line 3621 inside
`if .testType$ = "parametric" or .testType$ = "both"` under the
heading `Effect Size`, and line 3669 inside the nonparametric branch
under the heading `Nonparametric Effect Size`. Only the second is
correct.

**Why this is worse than a label mismatch.** Rank-biserial r
saturates at ±1.000 whenever every difference shares a sign — the
normal situation in a pre/post design with a real effect. It
therefore carries no magnitude information in exactly the case a
researcher cares about. Demonstration, two synthetic all-positive
difference sets:

| Data | mean diff | SD diff | Cohen's dz | Kerby r |
|---|---|---|---|---|
| A (tiny, consistent) | 0.0195 | 0.0059 | 3.296 | **1.000** |
| B (huge) | 5.9500 | 0.5916 | 10.057 | **1.000** |
| demo_paired | 0.8208 | 0.3302 | 2.486 | **1.000** |

Three effects spanning dz 2.5 to 10.1 all report "1.000 — large
effect". The number is at ceiling and cannot discriminate.

**Expected value.** For a paired t-test the conventional effect size
is Cohen's dz = meanDiff / sdDiff = 0.8208 / 0.3302 = **2.486**.
Both operands are already in hand at the report site — they are
printed on the two lines immediately above. Alternatives if
preferred: d_av = 0.9788 (averaged SDs, Lakens 2013), or
r_effect = sqrt(t²/(t²+df)) = 0.9310. The Pearson correlation
between conditions is 0.9229, which is also not what is printed.

**Not a missing capability, and not simply mis-wired.** `@emlCohenD`
exists but takes independent samples (`.v1#, .v2#`, line 325). Grep
across the whole plugin returns no `dz` and no paired-d procedure —
so the parametric paired effect size is genuinely absent from the
library, and the rank-based one appears to have been substituted to
fill the gap.

**Contaminates the CSV export too.** The Paired t-test CSV row at
`eml-annotation-procedures.praat:3626-3631` writes
`emlMatchedPairsR.r` with the literal effect-size-name field
`"matched-pairs r"`. Downstream analysis inherits the wrong
statistic, correctly named but wrong for the test it sits beside.

**Suggested fix:** add `@emlCohenDz` (or extend `@emlTTestPaired`
with `.dz = .meanDiff / .sdDiff`), report it in the parametric
branch as `Cohen's dz`, and leave `Matched-pairs r` to the
nonparametric branch alone. `@emlFormatEffectLabel` is called with
`"r"` as the scale hint at line 3618; the parametric branch would
need `"d"`.

**Live-GUI reconfirmation, 5 Aug (`demo_paired`, jitter_pre vs
jitter_post, n=20).** Driven through the real dialog with `Clear Info`
ticked. Info reports `t 11.065 / df 19 / p < .001 / Mean difference
0.9437 / SD of differences 0.3814`, then under a bare `── Effect Size ──`
heading: `Matched-pairs r 1.000 / Magnitude large effect`. Every
parametric number is correct against scipy (t = 11.0648, p = 1.01e-09,
and all six descriptives match to the printed precision) — **the
arithmetic is sound; only the effect size is the wrong statistic.**
scipy on the exported data: R+ = 210.0, R− = 0.0, 20 of 20 pairs
decreased, so the rank-biserial is exactly 1.0000. The parametric
companions would have been d_z = 2.4742 or r-from-t = 0.9304.

This is the degenerate case the finding predicts: because rank-biserial
depends only on the *signs* and rank order of the differences, **any
dataset in which all pairs move the same direction returns exactly
1.000 / "large effect"** — a shift of 0.0001 units scores identically to
one of 10 SDs. The heading compounds it: the nonparametric branch
(~3662) labels the identical value `Nonparametric Effect Size`, so the
one place the label would disambiguate is the one place it is dropped.

The exported CSV row confirms the contamination clause verbatim:
`effect_size = 1.0000`, `effect_type = matched-pairs r`, alongside
`test = Paired t-test`. Notably the CSV is the *more* honest artefact —
it names the effect type where the Info window does not, and it
preserves `demo_paired` / `jitter_pre` where the Info window strips the
underscores (D6).

Evidence: `out/w5_run_info.txt`, `out/csv/demo_paired_results.csv`,
shots `w5d`–`w5h`.

### D9 reconfirmed

`p   p < .001` — the doubled label again, this time at
`eml-annotation-procedures.praat:3613`. Consistent with the 10-site
systemic finding logged under D9.

### D6 reconfirmed

`demo paired`, `jitter pre`, `jitter post` — identifiers
underscore-stripped for display, so the Info window names do not
match the actual Table and column names the user must type
elsewhere.

### D14 reconfirmed

`p < .001` for an actual p of 9.31e-10. The floor hides nine orders
of magnitude here — a more extreme instance than the 3.7e-05 case
logged under D14 in wrapper 4.

### Graphing path — `Draw` from the completion dialog

The completion dialog offers **Done / CSV / Draw / New**. `Draw` opens
EML Graphs with **Graph type pre-selected to `Spaghetti Plot`** — the
correct type for paired data, chosen without asking. Good behaviour;
worth preserving.

**Wide→long reshape is automatic and correct.** The column-mapping
dialog offers only `Subject`, `Condition`, `Value`, which do not exist
in `demo_paired` (columns: `subject`, `jitter_pre`, `jitter_post`,
`HNR_pre`, `HNR_post`). This looked like a hardcoded-placeholder
defect. It is not: the Objects list shows the wrapper silently created
`24. Table pairedLong` and selected it, and the dropdown correctly
lists *that* table's columns. Defaults are pre-filled correctly
(Value / Condition / Subject) and `Show mean overlay` is on by
default. **Not a defect** — logged because the false-positive reading
is the obvious one.

The plot rendered with title, per-subject light lines, a heavy mean
overlay, gridlines, and no legend (correctly — one series).

### G1 UPGRADED — GRAPHING, HIGH — hardcoded `roundTo = 10` is systemic, and the fix already exists in-tree

Previously logged against the violin plot. It reproduces identically
on the spaghetti plot, and a full sweep of call sites shows it is not
type-specific:

```
eml-draw-procedures.praat:225   ... , 10, 0     pitch
eml-draw-procedures.praat:715   ... , 10, 0
eml-draw-procedures.praat:1052  ... , 10, 0
eml-draw-procedures.praat:1317  ... , 10, 0     <- spaghetti
eml-draw-procedures.praat:1702  ... , 10, 0     bar
eml-draw-procedures.praat:2035  ... , 10, 0     <- violin (G1 original)
eml-draw-procedures.praat:2896  ... , 10, 0
eml-draw-procedures.praat:3551  ... , 10, 0
eml-draw-procedures.praat:3776  ... , 10, 0
eml-graphs-form.praat:5428      ... , 10, 0
eml-graphs-form.praat:5432      ... , 10, 0
```

Eleven sites pass the literal `10`. Verified on screen: jitter data
spanning 0.1000–3.4128 drew a y-axis of **0 to 10**, so the data
occupies **33.1%** of the plot height and is crushed into the bottom
third.

**The correct implementation is already written, in the scatter path
only** — `eml-draw-procedures.praat:2240-2258`:

```praat
# Adaptive rounding grid: derive roundTo from a nice step over the data
# range (the same nice-number logic the gridlines use) so fractional data
# (proportions, reaction times, jitter %) is not snapped to the integer grid.
@emlComputeNiceStep: .dataYMax - .dataYMin, emlSetAdaptiveTheme.targetTicksY
.yRoundTo = emlComputeNiceStep.step
@emlComputeAxisRange: .dataYMin, .dataYMax, .yRoundTo, 0
```

The comment names this exact bug and even names *jitter %* as the
motivating case. So this is not an unrecognised defect — it is a fix
that was authored and then not propagated to the other eleven call
sites. Applying the same three lines to the spaghetti data gives
roundTo = 0.5, axis 0–4, and **82.8%** occupancy.

This raises G1's priority: it is a one-pattern change with a
worked reference implementation in the same file, affecting nearly
every graph type the plugin produces.

### G4 — GRAPHING, MEDIUM — reshaped y-axis label degrades to the literal "Value"

The y-axis reads **`Value`** and the x-axis reads **`Condition`**.
These are the reshaped `pairedLong` column names, passed straight
through to the axis labels. The plot therefore does not say what is
plotted — a reader sees "Value" where "Jitter (%)" belongs.

The information is available: the wrapper knew the source columns
(`jitter_pre`, `jitter_post`) because it analysed them, and it built
`pairedLong` itself. The x-axis tick labels do carry `jitter pre` /
`jitter post`, so the measure name survives into the tick text but
not into the axis title.

Compounds with **G3** (Rule 28C unit convention): even corrected to
the source name it would read `jitter pct`, not `Jitter (%)`.

### D6 reconfirmed in graphics

Tick labels read `jitter pre` / `jitter post` — the underscore
stripping follows the data into the Picture window, so the plotted
labels do not match the column names in the Table.

---

## Wrapper 5/17 — Compare paired/repeated — Part 3: export, Advanced panel, cleanup

Paths driven in this pass: `Graph Complete → Exp CSV → Save` (twice, same
filename, to probe Rule 27); `Graph Complete → Redraw → Continue → Advanced`;
`Advanced → Draw` (twice, to A/B the y-range and the escaping advice);
`Graph Complete → Done → Analysis complete → Done`. All previously
unexercised.

### Exported CSV — verbatim

`Exp CSV` on the Graph Complete dialog exports the **statistics**, not the
plotted data — i.e. it is the same export the Analysis-complete dialog's
`CSV` button produces. File written to `/root/pairedLong_results.csv`,
`file -b` reports `CSV ASCII text` (no UTF-16 trap here):

```
table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,effect_type,effect_label,n1,n2,mean1,sd1,median1,mean2,sd2,median2
demo_paired,jitter_pre,jitter_post,jitter_pre,jitter_post,Paired t-test,11.117232,19.00,0.0000000009,1.0000,matched-pairs r,,20,20,2.2558,0.8262,2.4679,1.4351,0.8509,1.6275
```

Header emitted at `stats/eml-output.praat:570`; row writer
`procedure emlCSVAddRow: .table$, .dataCol$, .groupCol$, .g1$, .g2$, .test$,
.stat, .df, .p, .es, .esType$, .esLabel$, .n1, .n2, ...` at
`stats/eml-output.praat:576`. 18 call sites across the library.

### D14 — RESOLVED, downgrade to LOW (display-only)

The Info window prints `p    p < .001`, which raised the concern that
precision was being lost at the floor. **It is not.** The CSV carries
`0.0000000009`, and scipy gives the true two-tailed p as `9.3112e-10`, so
the exported value is exact to the `fixed$(p, 10)` format. D14 therefore
describes an Info-window presentation choice, not data loss, and the
downstream artefact is sound.

Residual, LOW: the fixed-10 format floors any p below `5e-11` to
`0.0000000000` in the CSV. Scientific notation would be the robust choice
for the export column.

### D15 — CONFIRMED contaminating the export

Predicted from source reading in Part 1; now observed in the artefact.
The row for a **Paired t-test** carries `effect_size = 1.0000` with
`effect_type = matched-pairs r`. The rank-biserial correlation is not only
mislabelled in the Info window, it is the value a downstream consumer of the
CSV will read as *the* effect size for a parametric paired test. Call site
`graphs/eml-annotation-procedures.praat:3628`. Severity stands at HIGH.

### D16 — CLARITY, HIGH — the dialog's own escaping instructions are wrong, and fail silently

The Advanced column-mapping panel carries this help line directly above the
axis-label fields:

```
Formatting: %italic · #bold · ^super · _sub · \_% prints % (e.g. %F_0)
```

Source, verbatim and identical at **13 sites** in `graphs/eml-graphs-form.praat`
(lines 1442, 1641, 1792, 1956, 2286, 2678, 3030, 3441, 3824, 4158, 4499,
4818, 5153).

`\_%` does not print a percent sign. Typed into the Y-axis label field
exactly as instructed — `Jitter (\_%)` — the rendered axis reads:

```
Jitter ( )
```

Both characters vanish. No error, no warning; the label simply loses
content. Re-drawn with the canonical Praat trigraph `\% ` (backslash,
percent, **space**) — `Jitter (\% )` — the axis renders correctly as
`Jitter (%)`.

The library's own sanitizer already uses the correct form. From
`graphs/eml-graph-procedures.praat`:

```praat
procedure emlSanitizeLabel: .raw$
    .result$ = replace$ (.raw$, "_", " ", 0)
    # Order matters: % first because \% contains no other specials
    .result$ = replace$ (.result$, "%", "\% ", 0)
    .result$ = replace$ (.result$, "#", "\# ", 0)
    .result$ = replace$ (.result$, "^", "\^ ", 0)
endproc
```

So the user-facing instruction contradicts the implementation sitting one
file away. This is a one-string fix replicated 13 times; suggested
replacement text: `\% prints % (note the trailing space)`. Because the
failure is silent and the affected field is a published-figure axis label,
severity is HIGH despite the triviality of the fix.

Escaping this trap is also what makes the *rest* of the Advanced panel
usable — see G4 below.

### D17 — PACKAGING, MEDIUM — `effect_label` column populated inconsistently across analyses

The CSV schema reserves an `effect_label` column for the human-readable
magnitude ("large effect"). The Info window computes and prints it via
`@emlFormatEffectLabel`, but the paired branch passes a hardcoded `""` into
the CSV row:

```praat
... emlMatchedPairsR.r, "matched-pairs r", "",     ; line 3628 — esLabel dropped
```

so the exported column is empty (visible as the `,,` in the row above).

This is not uniform. Independent-groups (2622), nonparametric two-group
(2689), and Kruskal–Wallis (3004) all pass `emlFormatEffectLabel.label$`
correctly. The sites that drop it are 3272 and 3308 (Pearson, Spearman),
3556 (normality), **3628 and 3682 (paired, both branches)**, and 3784/3790/3796
(two-way ANOVA). Eight of eighteen. A consumer joining these exports gets a
column that is populated for some tests and blank for others with no
indication why.

### D18 — CLARITY, LOW-MEDIUM — default export filename names an internal artefact

The Export Results dialog pre-fills `File name: pairedLong_results`. The
row *inside* the file correctly records `table = demo_paired`. `pairedLong`
is the wide→long reshape the wrapper builds for the spaghetti plot; the user
never created it, never named it, and (per P3 below) never sees it again
after the workflow ends. Naming the deliverable after a transient
intermediate makes a directory of exports hard to reconcile with the tables
that produced them. The filename should derive from the same source-table
name the CSV body already carries.

### D19 — CLARITY, LOW — paired results shoehorned into the two-group CSV schema

For a paired test the schema's `data_col` / `group_col` / `group1` /
`group2` are not data and group — they are column 1 and column 2, written
twice (`jitter_pre,jitter_post,jitter_pre,jitter_post`). Similarly `n1` and
`n2` are both 20, which is the same 20 subjects rather than two samples.
Nothing is wrong numerically, but a reader of the file cannot distinguish a
paired design from an independent-groups design with equal n without parsing
the `test` string. Cosmetic companion: `df` exports as `19.00`.

### G1 — UPGRADE: empirical A/B confirms the auto y-range materially degrades the figure

Part 2 established the defect by source reading (11 call sites passing a
literal `roundTo = 10`, with the correct adaptive `@emlComputeNiceStep`
pattern already implemented at the scatter sites and commented with this
exact bug, naming "jitter %"). The Advanced panel allows a direct
side-by-side on identical data:

| | y-axis | gridlines | data occupancy |
|---|---|---|---|
| Auto (`roundTo = 10`) | 0 – 10 | 2, 4, 6, 8, 10 | 33.1% |
| Manual (max 3.5) | 0 – 3.5 | 0.5 steps | 82.8% |

In the auto rendering the twenty subject traces are compressed into the
bottom third and individual crossings are not resolvable; at 0–3.5 the same
traces are legible and the mean overlay separates cleanly from them. This is
the plot a user gets by default from the Draw button after running the
analysis, so the degraded version is the one that will reach figures.
Priority stands at HIGH; the fix is to reuse the scatter path's adaptive
pattern at the other 11 sites.

### G4 — SOFTENED to MEDIUM-LOW: an override exists, but only in Advanced

The generic `Value` / `Condition` axis labels can be overridden — the
Advanced panel exposes `X axis label` and `Y axis label` with the annotation
"blank = auto from column". The defect is therefore the *default*, not a
missing capability: the wrapper passes the reshaped long-format column names
straight to the axis titles, so the out-of-the-box figure does not state
what is plotted. Compounds with D16, since the obvious fix a user reaches
for — adding a unit like `(%)` — is exactly the case the dialog's own help
text gets wrong.

### Not a defect — three behaviours worth preserving

**P1 — Rule 27 (`@emlGenerateUniquePath`) verified empirically.** Exported
twice to the identical path. The first file was left byte-identical
(`md5 1e8643df59a43686dad31feb216d20d5`, mtime unchanged); the second was
written as `pairedLong_results_1.csv`; and the confirmation dialog reported
the **actual** path used, not the requested one — `Saved to:
/root/pairedLong_results_1.csv`. Silent overwrite is impossible and the
user is told what actually happened. This is the behaviour Rule 27 asks for,
implemented correctly.

**P2 — Loop repopulation (Appendix F) works, including the Advanced flag.**
`Redraw` reopens the EML Graphs dialog with graph type, title
("Jitter pre vs post"), colour mode, and figure dimensions all retained;
`Continue` then reopens the column mapping **already in Advanced mode**
(height 775 rather than 337) with the previously entered y-maximum and axis
label preserved. Iterating on a figure does not mean retyping it.

**P3 — the reshape intermediate is cleaned up.** `Table pairedLong`
(object 24), created silently by the wrapper for the spaghetti plot, is
removed when the workflow completes. Objects list after `Done`:

```
1  Table demo_normality
2  Table demo_2groups
19 Table demo_paired
20 Table demo_3groups
21 Table demo_correlation
22 Table demo_regression
23 Table demo_twoway
```

No litter, and no pre-existing object removed (Rule 4B satisfied). The ID
gap at 3–18 accounts for earlier intermediates likewise cleaned.

### Wrapper 5 — remaining unexercised path

The `Compare Paired Observations` Column 1 / Column 2 optionmenus offer the
string column `subject` despite the dialog instructing "Select two numeric
columns with paired data (same N)". Selecting it was not attempted in this
pass and remains open.

---

## Wrapper 6 of 17 — `Compare k groups (ANOVA)` on `demo_3groups`

Driven end to end through all three legs the wrapper offers: **statistics →
Draw → Exp CSV**. Data column `SPL_dB`, group column `voice_type`,
Tukey HSD checkbox on, group order default. Info captured with `info$()`
to disk, not screenshotted.

### Info window, verbatim

```
══════════════════════════════════════════════
  EML Stats : One-Way ANOVA
  Wed Aug  5 13:08:19 2026
══════════════════════════════════════════════

  Table               demo 3groups
  Data column         SPL dB
  Group column        voice type
  Groups              3


  ── ANOVA Table ─────────────────────────────

Source              SS              df    MS              F           p
Between             335.03          2     167.52          7.0767      0.002246
Within              994.21          42    23.67           
Total               1329.24         44    

  F                   7.0767
  p                   p = .002
  Effect size         eta-squared = 0.2520


  ── Group Descriptives ──────────────────────
  Group         N     Mean      SD        Median    
  Soprano       15    91.44     5.18      91.60     
  Mezzo         15    89.11     5.94      87.71     
  Alto          15    84.85     2.98      84.32     


  ── Tukey HSD Pairwise Comparisons (p-values) ───

              Soprano     Mezzo       Alto        
Soprano       ---         0.3942      0.0017      
Mezzo         0.3942      ---         0.0542      
Alto          0.0017      0.0542      ---         


  ── Pairwise Effect Sizes (Cohen's d) ───────

              Soprano     Mezzo       Alto        
Soprano       ---         0.419       1.560       
Mezzo         -0.419      ---         0.905       
Alto          -1.560      -0.905      ---         

══════════════════════════════════════════════
```

### Accuracy — clean pass, Info *and* CSV

Every reported number was verified against scipy/statsmodels computed from
the ASCII column dump (`dump_demo_3groups.csv`, 45 rows, 15 per group).

| Quantity | Plugin | Ground truth |
|---|---|---|
| SS between / within / total | 335.03 / 994.21 / 1329.24 | identical |
| df | 2 / 42 / 44 | identical |
| MS between / within | 167.52 / 23.67 | 167.5157 / 23.6716 |
| F | 7.0767 | 7.076697 |
| p | 0.002246 | 0.00224563 |
| eta² | 0.2520 | 0.252004 |
| Group means | 91.44 / 89.11 / 84.85 | 91.4438 / 89.1053 / 84.8522 |
| Group SDs | 5.18 / 5.94 / 2.98 | 5.1800 / 5.9437 / 2.9756 |
| Group medians | 91.60 / 87.71 / 84.32 | 91.5985 / 87.7142 / 84.3157 |
| Tukey p (Sop×Mez, Sop×Alt, Mez×Alt) | 0.3942 / 0.0017 / 0.0542 | 0.395666 / 0.001708 / 0.054186 |
| Cohen's d | 0.419 / 1.560 / 0.905 | 0.41946 / 1.56050 / 0.90494 |

The CSV export was verified independently and to more digits: the Tukey **q
statistics** match to six decimals (1.861486 / 5.247135 / 3.385649, agreeing
with both `Δ/sqrt(MSW/2·(1/n₁+1/n₂))` and `Δ/sqrt(MSW/n)` — identical for
equal n), and the Tukey p-values agree with `statsmodels.psturng` to within
that function's known interpolation error. Effect-magnitude labels are also
correct against the plugin's own thresholds (eta² 0.2520 ≥ 0.14 → "large
effect"; d 0.4195 ∈ [0.2, 0.5) → "small effect"; d ≥ 0.8 → "large effect").

The d matrix's sign convention is coherent: the upper triangle reads
row-minus-column, the lower triangle is its negation, so the sign tells the
reader the direction. This is the disclosure D13 found *missing* on the
two-group path — the k-group path does it right.

### D20 — ACCURACY (high): no variance-homogeneity check anywhere, and the plugin's own demo data violates the assumption

`grep -iE 'levene|bartlett|brown.forsythe|games.howell|homogene'` across the
whole plugin returns nothing. Welch appears only on the **two-group** path
(`stats/eml-inferential.praat:106–190`, and `@emlPairwiseT` at 3325+, where
it is correctly the default). For k ≥ 3 the wrapper runs Fisher's one-way
ANOVA unconditionally, with pooled-MSW Tukey HSD behind it, and never tests
or mentions the equal-variance assumption that both procedures rest on.

This is not hypothetical. The shipped demo table trips it:

```
Bartlett      W = 6.2099   p = 0.0448
Levene (mean) W = 3.6264   p = 0.0353
Levene (med)  W = 2.9594   p = 0.0628
SD ratio      5.9437 / 2.9756 = 2.00
```

Welch's ANOVA on the same data gives **F(2, 25.41) = 10.09, p = .000595**
against the reported **F(2, 42) = 7.08, p = .00225** — same conclusion at
α = .05 here, so no reversal in this dataset, but a materially different
F, df, and p. With unequal n the divergence would be larger and the sign of
the difference unpredictable.

Two things are wrong at once. The Info window presents the descriptives
table with the group SDs **right there** (5.18 / 5.94 / 2.98) and says
nothing about them; and the library already knows how to do the robust
thing on the two-group path but does not carry it forward. Minimum fix:
compute Levene (median-centred, the robust default) alongside the ANOVA and
print it in the header block. Better fix: route to Welch's ANOVA +
Games–Howell when it fails, mirroring the two-group path's existing
Welch-by-default posture. Either way the current behaviour — silent Fisher
ANOVA on heteroscedastic data — is the one outcome that should not ship.

Note this is a *methodological* decision in the Step 1B sense, so the fix
should surface it to the user rather than switching silently.

### D21 — CLARITY (medium): omega² is never computed, though the library already knows how to classify it

`stats/eml-output.praat:342–368` classifies magnitudes for `eta_squared`,
`omega_squared`, and epsilon — all three branches exist. Only eta² is ever
produced. For this dataset eta² = 0.2520 against omega² = 0.2126: eta² is
the biased estimator and overstates by ~16% relative at n = 45, k = 3, and
the gap widens as n shrinks. Since the classification code is already
written, reporting both is a few lines, and reporting omega² alongside eta²
is the standard recommendation for one-way designs.

### D22 — CLARITY (medium): the Tukey table reports p-values only

The pairwise block gives p and (separately) d, but never the **mean
difference** or its **confidence interval** — the quantities a reader
actually needs to state a result. The CSV carries `mean1`/`mean2` so the
difference is recoverable by hand, but the Info window is where the user
reads the result, and there it is absent. This is D12 (no CI on the mean
difference, two-group path) recurring on the k-group path, and it is worse
here because there are three differences to reconstruct rather than one.

The q statistic is likewise present in the CSV (`statistic` column) but
never shown in the Info window, so the Tukey table cannot be checked or
reported in APA form from what is displayed.

### D23 — PACKAGING (medium): the omnibus CSV row carries only the numerator df

`graphs/eml-annotation-procedures.praat:2763` passes
`emlOneWayAnova.dfBetween` into the single `df` column. The exported row
reads `df = 2.00` while the Info window reports F(2, 42). The denominator df
is recoverable only by inference from the Tukey rows' `42.00` — which works
here only because Tukey was requested. With the Tukey checkbox off, the
export loses the error df entirely and the F statistic in the CSV becomes
uninterpretable.

The single-`df` column is a schema limitation, but the omnibus row could
carry `df2` in a spare field, or the schema could gain `df1`/`df2`.

### D24 — PACKAGING (high): zero is used as the not-applicable sentinel in CSV exports

`@emlCSVAddRow` (`stats/eml-output.praat`) has **no NA sentinel**. Every
numeric argument goes through `fixed$` or `string$` unconditionally, so a
caller that has nothing to report must pass a number, and every caller
passes `0`.

Line 2765 (omnibus row) passes literal `0` for `n1, n2, mean1, sd1,
median1, mean2, sd2, median2`. Line 2943 (the `doTukey = 0` fallback)
passes `0, 0, 0` for `stat, df, p`. The result in the delivered file:

```
demo_3groups,SPL_dB,voice_type,omnibus,omnibus,One-way ANOVA,7.076697,2.00,0.002246,0.2520,eta-squared,large effect,0,0,0,0,0,0,0,0
```

Eight trailing zeros that mean "not applicable" are indistinguishable from
eight genuine zero measurements. Any downstream consumer that reads this
into R or pandas and takes a column mean, filters `n1 > 0`, or plots
`mean1` will silently include the omnibus row. Worse, the `doTukey = 0`
branch writes `p = 0.000000`, which reads as the most significant result in
the file.

This is the D19 shoehorning pattern in its damaging form: D19 was about
paired results being squeezed into a two-group schema, which is untidy;
this is about a sentinel collision that produces wrong numbers downstream.
Fix: emit `NA` (or empty) for inapplicable fields. `@emlCSVAddRow` would
need string-typed passthrough or a parallel "field present" mask; the
cheapest version is a sentinel constant checked in the formatter.

### D25 — CLARITY (medium): the "Adjustment method" control is inert on the parametric k-group path

This one was chased as a suspected accuracy defect and resolved as **correct
behaviour behind a misleading control** — logging the control, not the
statistics.

The question was whether the annotated figure's p-values came from Tukey or
from the Holm correction the graphs form advertises. Soprano×Alto cannot
discriminate (Tukey 0.001710 and Holm 0.001806 both round to `.002`).
Mezzo×Alto does:

```
raw t p : Sop-Mez 0.195222   Sop-Alt 0.000602   Mez-Alt 0.021207
holm    : Sop-Mez 0.195222   Sop-Alt 0.001806   Mez-Alt 0.042415
tukey   : Sop-Mez 0.394219   Sop-Alt 0.001710   Mez-Alt 0.054187
```

Holm calls Mezzo×Alto significant (.042); Tukey does not (.054). The
rendered figure annotated **only** Soprano×Alto with "Show nonsignificant"
off, so Mezzo×Alto was treated as nonsignificant ⇒ the annotation used
Tukey. The caption is honest and the numbers are right.

The source explains why, and that is the finding.
`annotCorrectionMethod$` is documented at
`graphs/eml-annotation-procedures.praat:304` as "p-value correction for
**Dunn's test**", and its sole consumption site is the *nonparametric*
branch of `@emlBridgeGroupComparison` (1796–1810). But the "Adjustment
method" optionmenu (`@emlAdjustMethodName`,
`graphs/eml-graphs-form.praat:755–777`) is declared at **7** annotate-capable
column-mapping dialogs and presented **unconditionally**. A user who sets it
to Bonferroni, runs a parametric k-group comparison, and receives
Tukey-corrected annotations has been misled by a live-looking control that
did nothing.

Fix: gray the control out when Test type = parametric and k ≥ 3, or rename
it "Adjustment method (nonparametric post-hoc only)". The former is better
— the label change still leaves the user to work out when their own analysis
is nonparametric.

### D17 — REFINED, and refined *against* the prediction that motivated this leg

The prediction going in was that the ANOVA export would drop `effect_label`,
as the paired export does. It does not. Both `@emlCSVAddRow` call sites on
this path (2761 omnibus, 2853 Tukey) call `@emlFormatEffectLabel` first, so
every row in `demo_3groups_results.csv` carries a populated label:

```
...,0.2520,eta-squared,large effect,...
...,0.4195,Cohen's d,small effect,...
...,1.5605,Cohen's d,large effect,...
...,0.9049,Cohen's d,large effect,...
```

Contrast the wrapper-5 paired export, whose `effect_label` field is empty:

```
demo_paired,jitter_pre,jitter_post,...,1.0000,matched-pairs r,,20,20,...
```

D17 is therefore **a per-call-site omission at 8 of 18 sites, not a systemic
export defect**, and the ANOVA family is on the correct side of the split.
Downgrading the severity accordingly, but the fix is unchanged: the label
computation should live inside `@emlCSVAddRow` rather than being each
caller's responsibility, which is exactly the DRY defect (Rule 35) that
produced the split in the first place.

### D18 — SCOPED DOWN to the paired path only

The Export Results dialog pre-filled `demo_3groups_results` — correctly
derived from the source table name. D18 (filename pre-filled from a
transient intermediate) is specific to the paired reshape path, which routes
through the `pairedLong` intermediate. Not a general defect of the export
dialog.

### D14 — residual `fixed$` risk FALSIFIED, plus one new latent hazard

D14 noted the Info window floors small p to `p < .001` while the CSV carries
the exact value, and flagged a residual worry that `fixed$(.p, 6)` in
`@emlCSVAddRow` might itself floor a very small p to `0.000000`. Tested
empirically (`praat --pref-dir=…/prefs_batch --run`):

```
fixed$ (9e-10, 6)      = 0.0000000009
fixed$ (1e-15, 6)      = 0.000000000000001
fixed$ (0, 6)          = 0
fixed$ (4e-11, 10)     = 0.00000000004
fixed$ (undefined, 2)  = --undefined--
fixed$ (-0.0000001, 4) = -0.0000001
```

Praat's `fixed$` **guarantees at least one significant digit** and never
floors a nonzero value to zero — the digit count is a minimum, not a
maximum. The CSV always carries full-resolution p. D14 reduces to a note:
only the Info window floors, via `@emlFormatP`, which is a deliberate
reporting convention.

Two incidental results worth recording as Praat idioms:

- `fixed$ (0, 6)` yields `0`, not `0.000000` — so a genuine zero and a
  padded not-applicable zero (D24) are *also* visually distinguishable in
  the raw file, which is faint consolation but does confirm D24's zeros are
  real zeros passed as literals rather than formatting artefacts.
- `fixed$ (undefined, 2)` yields the literal string `--undefined--`. Since
  `@emlCSVAddRow` formats unconditionally, any statistic that comes back
  undefined would be injected verbatim into a CSV cell, breaking the file's
  numeric typing for that column with no warning. Latent, not yet observed
  — but it is the same root cause as D24 and the same fix closes both.

### Recurrences confirmed on this wrapper

- **D6** — identifiers underscore-stripped for display: the header block
  reads `demo 3groups`, `SPL dB`, `voice type` for objects actually named
  `demo_3groups`, `SPL_dB`, `voice_type`. A user copying these into a script
  gets three broken names.
- **D9** — the p row prints its label twice: `p    p = .002`. The systemic
  `@emlFormatP.formatted$` prefix defect, here at call site 2752.
- **D16b** — the Advanced panel's own formatting help line still renders its
  underscores as spaces in `comment:`.

### Graphing

Box plot rendered from the Draw button, annotated with the Tukey
significance bracket for Soprano×Alto only. **G1** recurs — the wrapper
passes literal `roundTo = 10` to `@emlComputeAxisRange`, giving an axis that
the data occupies only ~53% of. **P2** recurs and works: `Redraw` reopened
the EML Graphs dialog with type, title, colour mode and dimensions retained,
and the column mapping reopened in sticky Advanced mode.

### Not a defect

**P4 — the graph-type menu's divider entries are guarded.** Selecting
`--- Categorical ---` produces "The item you selected is a category header."
rather than an obscure failure. Correct, and worth preserving.

### Deferred candidate — graph-type taxonomy

The dropdown splits into `--- Categorical ---` (Violin, Grouped Violin, Box,
Grouped Box, **Histogram**) and `--- Continuous ---` (**Bar Chart**,
Scatter, Line ±CI, **Spaghetti**). Histogram under Categorical and Bar Chart
under Continuous both look inverted on the usual reading, but the split may
be describing the *x-axis variable type* rather than the plot family, in
which case it is right. Holding until the Bar Chart column-mapping dialog is
driven, which will settle what the two headings mean.

---

## Wrapper 7 of 17 — `Compare k groups (Kruskal-Wallis)` on `demo_3groups`

Driven end to end: Run → Draw (Holm) → Redraw (Bonferroni) → Exp CSV → Done.
The two Draw legs were deliberately structured as an A/B differential — the
only control changed between them was `Adjustment method` — in order to
settle D25 from the opposite direction.

### Info window, verbatim

```
══════════════════════════════════════════════
  EML Stats : Kruskal-Wallis H Test
  Wed Aug  5 13:28:09 2026
══════════════════════════════════════════════

  Table               demo 3groups
  Data column         SPL dB
  Group column        voice type
  Groups              3
  Total N             45

  ── Omnibus Test ────────────────────────────
  H                   11.9745
  df                  2
  p                   p = .003
  Epsilon-squared     0.2721
  Effect magnitude    large effect

  ── Group Mean Ranks ────────────────────────

Group         N     Mean Rank
Soprano       15    30.47
Mezzo         15    24.47
Alto          15    14.07

  ── Dunn's Post-Hoc (adjusted p, holm) ──────

            Soprano     Mezzo       Alto
Soprano     ---         0.2109      0.0019
Mezzo       0.2109      ---         0.0602
Alto        0.0019      0.0602      ---

  ── Dunn's z-statistics ─────────────────────

            Soprano     Mezzo       Alto
Soprano     ---         1.251       3.420
Mezzo       -1.251      ---         2.169
Alto        -3.420      -2.169      ---

  ── Pairwise Effect Sizes (rank-biserial r) ───

            Soprano     Mezzo       Alto
Soprano     ---         0.244       0.751
Mezzo       -0.244      ---         0.440
Alto        -0.751      -0.440      ---

══════════════════════════════════════════════
```

### Exported CSV, verbatim (`demo_3groups_results_1.csv`, graph-path export)

```
table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,effect_type,effect_label,n1,n2,mean1,sd1,median1,mean2,sd2,median2
demo_3groups,SPL_dB,voice_type,omnibus,omnibus,Kruskal-Wallis,11.974493,2.00,0.002511,0.2721,epsilon-squared,large effect,0,0,0,0,0,0,0,0
demo_3groups,SPL_dB,voice_type,Soprano,Mezzo,Dunn (bonferroni),1.251086,0,0.632709,0.2444,rank-biserial r,small effect,15,15,91.4438,5.1800,91.5985,89.1053,5.9437,87.7142
demo_3groups,SPL_dB,voice_type,Soprano,Alto,Dunn (bonferroni),3.419636,0,0.001881,0.7511,rank-biserial r,large effect,15,15,91.4438,5.1800,91.5985,84.8522,2.9756,84.3157
demo_3groups,SPL_dB,voice_type,Mezzo,Alto,Dunn (bonferroni),2.168550,0,0.090351,0.4400,rank-biserial r,medium effect,15,15,89.1053,5.9437,87.7142,84.8522,2.9756,84.3157
```

### Accuracy — clean pass, every reported number

Ground truth computed in scipy from an ASCII dump of the table
(`dump_demo_3groups.csv`), independently of the plugin, before any
comparison was made.

| Quantity | Plugin | scipy ground truth | Verdict |
|---|---|---|---|
| H | 11.9745 / 11.974493 | 11.974492753623196 | exact |
| omnibus p | 0.002511 (CSV) | 0.002510567698247169 | exact |
| ε² | 0.2721 | 0.27214756 = H/(N−1) | exact |
| mean rank Soprano | 30.47 | 30.4667 | exact |
| mean rank Mezzo | 24.47 | 24.4667 | exact |
| mean rank Alto | 14.07 | 14.0667 | exact |
| Dunn z S–M | 1.251086 | 1.2511 | exact |
| Dunn z S–A | 3.419636 | 3.4196 | exact |
| Dunn z M–A | 2.168550 | 2.1685 | exact |
| Holm p (Info, blocks 1–2) | .2109 / .0019 / .0602 | .210903 / .001881 / .060234 | exact |
| Bonferroni p (Info block 3, figure, CSV) | .6327 / .0019 / .0904 | .632709 / .001881 / .090351 | exact |
| rank-biserial r | 0.244 / 0.751 / 0.440 | 0.2444 / 0.7511 / 0.4400 | exact |
| medians | 91.5985 / 87.7142 / 84.3157 | same | exact |

Three points worth recording as *correct choices*, not merely correct
arithmetic:

- **ε² uses the Tomczak & Tomczak formula H/(N−1) = 0.27215**, not the
  competing (H−k+1)/(N−k) = 0.23749. Both appear in the literature; the
  plugin picked one and applied it consistently. The magnitude label
  ("large effect", ε² > .14) is correct under the formula actually used.
- **Rank-biserial r is the U-based form**, matching 0.2444/0.7511/0.4400
  exactly — not the z/√N or z/√(n₁+n₂) approximations, which would have
  given visibly different values. Effect labels (small/medium/large at
  .1/.3/.5) are correct.
- **The z and r matrices use a coherent sign convention** — upper triangle
  row-minus-column, lower triangle its negation — the same good practice
  observed on the ANOVA path.

### Graphing accuracy — verified twice, against two different ground truths

Both violin figures were checked against pre-computed values. Inner boxes
matched the IQR of all three groups exactly and medians matched. The Holm
draw annotated `.211 / .002 / .060`; the Bonferroni draw annotated
`.633 / .002 / .090`. Both exact.

### D25 — CONFIRMED from the opposite direction, and the prediction held

D25 logged the `Adjustment method` optionmenu as inert on the parametric /
Tukey path, and predicted it would be live on the nonparametric / Dunn path
because `annotCorrectionMethod$` is documented as the correction "for Dunn's
test" and its sole consumption site is the nonparametric branch of
`@emlBridgeGroupComparison` (`eml-annotation-procedures.praat:1796–1810`).

The A/B drive confirms it. Changing Holm → Bonferroni and nothing else
changed the annotated p-values (`.211/.060` → `.633/.090`) *and* the caption
sub-line (`Dunn's test (holm)` → `Dunn's test (bonferroni)`).

The A/B had to be set up deliberately: with **Show nonsignificant** off, the
two methods annotate identically here, because only Soprano×Alto crosses α
and its adjusted p is 0.001881 under both. The checkbox had to be ticked
first for the control's effect to be observable at all. Worth remembering as
a harness lesson — an inert-looking control may simply have no visible
consequence under the current display settings.

D25 therefore stands as written, and is now scoped precisely: the control is
correct and live on the nonparametric path, and is displayed but has no
effect on the parametric path. The defect is that it is shown unconditionally.

### D26 — CLARITY, HIGH — the KW wrapper exposes no post-hoc control whatsoever

`scripts/eml-compare-kw.praat:64` calls

```praat
@emlRunKWAnalysis: tableId, dataCol$, groupCol$, 1, "holm"
```

with both post-hoc arguments hardcoded. The procedure signature is
`emlRunKWAnalysis: .tableId, .dataCol$, .groupCol$, .doDunn, .adjMethod$`
(`stats/eml-analysis.praat:292`) and `@emlDunnTest` accepts
bonferroni / holm / bh — the capability is fully built and validated
(`eml-analysis.praat:1512–1524` even falls back to holm with a warning on an
unrecognised method). Nothing is wired to a control.

This is asymmetric with the sibling wrapper. `eml-compare-k-groups.praat`
(ANOVA) has:

```
45:        boolean: "Tukey HSD post hoc", 1
69:    @emlRunAnovaAnalysis: tableId, dataCol$, groupCol$, doTukey
```

So on the parametric path the user can suppress the post-hoc; on the
nonparametric path they cannot suppress Dunn, and cannot change its
correction, from the analysis dialog. They *can* change it from the graph
dialog — which produces D27.

Fix is two form fields and two variables; the plumbing behind them already
exists and is already tested.

### D27 — CLARITY, HIGH — the Info window silently accumulates duplicate reports that can disagree with each other

Each `Draw` re-runs the entire analysis and appends a complete report block
to the Info window. One session produced three blocks:

| Block | Lines | Timestamp | Correction | Origin |
|---|---|---|---|---|
| 1 | 3–54 | 13:28:09 | holm | Run (analysis path) |
| 2 | 56–108 | 13:30:29 | holm | first Draw — byte-identical to block 1 |
| 3 | 110–162 | 13:31:42 | bonferroni | Redraw with Adjustment method changed |

Three compounding problems:

1. **The blocks are indistinguishable by header.** All three read
   `EML Stats : Kruskal-Wallis H Test`. Nothing says which came from the
   analysis and which from a graph, and nothing flags that block 2 is a
   redundant duplicate.
2. **Blocks 1 and 3 report different post-hoc p-values for the same data**
   (.2109/.0019/.0602 vs .6327/.0019/.0904) with no marker of which is
   authoritative. A user who scrolls up gets holm; the delivered figure and
   the delivered CSV both carry bonferroni. Because of D26 the user cannot
   even reconcile them from the analysis dialog — the holm in block 1 is not
   a choice they made.
3. **The wrapper's `Clear Info window` checkbox applies only at Run**, so
   the accumulation is unbounded across a Draw/Redraw session.

Credit where due: **the CSV is self-documenting where the Info window is
not.** The `test` column reads `Dunn (bonferroni)` on every pairwise row, so
the exported file cannot be misread. The fix for the Info window is the same
one line of discipline — put the correction in the block header, and mark
graph-path reruns as such.

### D28 — CLARITY, MEDIUM — the KW omnibus p never reaches full precision in the Info window

The Info window shows only `p    p = .003`. The full value 0.002511 exists —
it is in the CSV — but no Info window path prints it. This is *worse* than
the ANOVA path, which at least carried 0.002246 in its ANOVA table row.
A reader working from the Info window alone cannot report the exact p, and
the APA-style threshold rendering hides the difference between p = .0025 and
p = .0034.

(The doubled `p    p = .003` label is D9, recurring here.)

### D29 — GRAPHING, MEDIUM-LOW — the caption renders epsilon-squared as "e2"

The figure caption reads:

```
Kruskal-Wallis: H(2) = 11.97, p = .003, e2 = 0.272
```

`e2` is not standard notation for ε². Appendix E gives the escape mechanism
for Greek and superscripts in Picture window text, so this is renderable —
`\ep` + `\^ 2` or a plain `eps^2`. As written it reads as an unexplained
abbreviation, and in a figure destined for publication it is wrong.

The same caption also does not carry the full-precision p, so D28 propagates
into the figure.

### D30 — GRAPHING, LOW — caption sub-line is low-contrast grey on white

The `Dunn's test (holm)` / `Dunn's test (bonferroni)` sub-line under the main
caption is drawn in a light grey that is legible on screen at 300 dpi but
degrades badly in greyscale print and on projection. Given that this
sub-line is the *only* place in the figure that discloses which correction
produced the annotated p-values (see D27), it is the wrong element to make
faint.

### D31 — RESOLVED as designed, downgrade to LOW — violin KDE tails extend exactly one bandwidth past the data

| Group | Drawn extent | Observed min–max |
|---|---|---|
| Soprano | 80.2 – 104.0 | 82.74 – 101.35 |
| Mezzo | 78.4 – 105.3 | 81.53 – 102.28 |
| Alto | 79.5 – 92.6 | 81.01 – 91.06 |

The candidate is resolved by reading the source. `eml-draw-procedures.praat`
2011–2030 extends the range by the largest per-group Silverman bandwidth,
h = 0.9·SD·n^(−0.2), with the stated intent that "violin tails do not hit the
axis edge." The arithmetic confirms the overshoot is exactly that quantity:

| Group | Silverman h | observed low overshoot | high overshoot |
|---|---|---|---|
| Soprano | 2.712 | 2.54 | 2.65 |
| Mezzo | 3.112 | 3.13 | 3.02 |
| Alto | 1.558 | 1.51 | 1.54 |

So this is deliberate, correctly implemented, and matches seaborn's default
(`cut=2`). It does *not* match ggplot2's `geom_violin` default (`trim=TRUE`),
which clips at the data range — so a reader coming from R will find the EML
violins unfamiliar. No trim control is exposed anywhere in the dialog.

Downgraded to LOW and reframed: not a defect, but the untrimmed default draws
density where no observation exists (up to 3.1 dB here), and for a
clinical/pedagogical audience reading dB SPL that is a real misreading risk.
Recommend a `boolean: "Trim violins to data range"` in the Advanced panel.
Not urgent.

### D24 — CONFIRMED recurring: zero as the not-applicable sentinel

The three Dunn rows carry `df,0`. Dunn's test is a z-test — it has no
degrees of freedom. Zero is not a missing-value marker, and a reader or a
downstream parser will take it as df = 0. Same root cause as D24 on the
ANOVA path, same fix.

### D23 — SCOPED DOWN to the ANOVA path

D23 logged the omnibus CSV row as carrying only the numerator df. On the KW
row, `df,2.00` is simply **correct** — Kruskal-Wallis has a single df (k−1 = 2)
and there is no denominator to omit. D23 is specific to the F-test schema
and should be narrowed to the ANOVA/Tukey wrapper.

### Rule 27 — VERIFIED COMPLIANT (not a defect, worth preserving)

The export dialog pre-filled `demo_3groups_results`, which was already in use
from the wrapper-6 ANOVA export. Saving wrote **`demo_3groups_results_1.csv`**
and left the existing file untouched (mtime and md5 both unchanged). The
`@emlGenerateUniquePath` last-line-of-defence is working as specified. This
was tested deliberately by re-using the colliding default rather than
renaming around it.

The default filename also derived correctly from the source table name — D18
remains scoped to the paired-reshape path only.

### D19 — extended to the nonparametric schema

The CSV reports `mean1,sd1,median1,mean2,sd2,median2` for a rank-based test.
Median is the appropriate descriptive here and it is present and correct, but
it is accompanied by mean and SD (parametric descriptives) and *not* by IQR,
which is what a KW result would normally be reported with. The fixed shared
column schema is a defensible tradeoff, but the omission of IQR alongside the
inclusion of SD is the wrong side of that tradeoff for this test.

### Recurrences confirmed on this wrapper

- **D6** — `demo 3groups`, `SPL dB`, `voice type` in the Info header for
  objects actually named `demo_3groups`, `SPL_dB`, `voice_type`.
- **D9** — `p    p = .003`, the doubled `@emlFormatP.formatted$` label.
- **D16b, sharpened** — the Column Mapping `Formatting:` help line renders as

  ```
  %italic · #bold · ^super ·  sub · \ % prints % (e.g. %F 0)
  ```

  The `\_ ` subscript escape is swallowed entirely (leaving a blank before
  "sub") and the worked example `%F_0` renders as `%F 0`. The line whose sole
  purpose is to teach escape syntax is itself broken by the exact bug it is
  teaching around — which makes this the highest-value single instance of
  D16b found so far.

---

## Wrapper 8 of 17 — `Compare two-way ANOVA` (menu y = 624) on `demo_twoway`

**All three legs driven:** Run → CSV export → Draw → Exp CSV. Every dialog
closed cleanly; `needclear` clean at end.

Dialog sequence and coordinates (all pause windows origin 0,0):

| Window | Size | Controls used |
|---|---|---|
| `Two-Way ANOVA` | 524x270 | Data column (384,68); Factor 1 (384,100); Factor 2 (384,132); Clear Info window (277,187); **Run (413,234)** |
| `Analysis complete` | 524x113 | Done 179, CSV 275, Draw 365, New 460 — all y=78 |
| `Export Results` | 524x218 | Output folder text (250,57); File name (385,131); **Save (413,182)** |
| `Export Complete` | 524x113 | Done (179,78) |
| `EML Graphs` | 524x288 | Graph type (384,27) … **Continue (414,251)** |
| `Grouped Violin -- Column Mapping` | 524x940 | Value (384,63); **Category (384,95)**; **Subgroup (384,127)**; Group order (384,159); **Annotate (279,191)**; … **Draw (461,904)** |
| `Graph Complete` | 524x150 | Done 179, Save 273, **Exp CSV 370**, **Redraw 462** — all y=115 |

All three optionmenus (Data column, Factor 1, Factor 2) auto-guessed correctly
on first open: `SPL_dB`, `voice_type`, `task`. No mis-selection, no string
column offered where a numeric was required.

### Ground truth (statsmodels 0.14 / scipy, sum-coded so Type I = II = III)

```
voice          SS=276.979589  df=1  F=34.110425   p=5.788464e-07  partial_eta2=0.4367
task           SS=874.266761  df=1  F=107.667178  p=2.112098e-13  partial_eta2=0.7099
voice:task     SS=125.003106  df=1  F=15.394308   p=3.024778e-04  partial_eta2=0.2592
Residual       SS=357.283791  df=44 MS=8.120086
Total          SS=1633.533247 df=47

cell means (n=12 each):
  Alto/Speech      87.187696 (sd 3.593138)   Alto/Singing     92.495717 (sd 2.796032)
  Soprano/Speech   88.764505 (sd 2.077179)   Soprano/Singing 100.527578 (sd 2.727129)
Levene (median) W=0.5539 p=0.6483 ; Shapiro on residuals W=0.9731 p=0.3336
```

### Info window, verbatim

(The leading `selected 23 Table demo_twoway` line in `tw_info.txt` is harness
noise from `pick`, not plugin output.)

```
══════════════════════════════════════════════
  EML Stats : Two-Way ANOVA
  Wed Aug  5 13:39:57 2026
══════════════════════════════════════════════

  Table               demo twoway
  Data column         SPL dB
  Factor 1            voice type
  Factor 2            task


  ── ANOVA Table ─────────────────────────────

Source              SS              df    MS              F           p
voice type          276.98          1     276.98          34.1104     p < .001
task                874.27          1     874.27          107.6672    p < .001
voice type x task   125.00          1     125.00          15.3943     p < .001
Error               357.28          44    8.12            
Total               1633.53         47    


  ── Effect Sizes (partial eta-squared) ──────
  voice type          0.4367
  task                0.7099
  voice type x task   0.2592

══════════════════════════════════════════════
```

### Accuracy — the analysis leg is a clean pass

| Quantity | Plugin | Ground truth | |
|---|---|---|---|
| SS voice | 276.98 | 276.979589 | ✓ |
| SS task | 874.27 | 874.266761 | ✓ |
| SS interaction | 125.00 | 125.003106 | ✓ |
| SS error | 357.28 | 357.283791 | ✓ |
| SS total | 1633.53 | 1633.533247 | ✓ |
| df | 1 / 1 / 1 / 44 / 47 | same | ✓ |
| MS | 276.98 / 874.27 / 125.00 / 8.12 | 8.120086 for error | ✓ |
| F | 34.1104 / 107.6672 / 15.3943 | 34.110425 / 107.667178 / 15.394308 | ✓ |
| partial η² | 0.4367 / 0.7099 / 0.2592 | same | ✓ |

The effect sizes are correctly **partial** η², not plain η² (which would be
0.1696 / 0.5352 / 0.0765), and the section header says "partial eta-squared"
explicitly. This is the correct default for a factorial design and it is
labelled honestly. Nothing in the ANOVA table is wrong.

### Exports, verbatim

Analysis leg → `demo_twoway_results.csv` (554 B, ASCII):

```
table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,effect_type,effect_label,n1,n2,mean1,sd1,median1,mean2,sd2,median2
demo_twoway,SPL_dB,voice_type,main effect,voice_type,Two-way ANOVA,34.110425,1.00,0.0000006,0.4367,partial eta-squared,,0,0,0,0,0,0,0,0
demo_twoway,SPL_dB,task,main effect,task,Two-way ANOVA,107.667178,1.00,0.0000000000002,0.7099,partial eta-squared,,0,0,0,0,0,0,0,0
demo_twoway,SPL_dB,voice_type_x_task,interaction,voice_type_x_task,Two-way ANOVA,15.394308,1.00,0.000302,0.2592,partial eta-squared,,0,0,0,0,0,0,0,0
```

Graph leg → `demo_twoway_results_1.csv` (293 B, ASCII). **Rule 27 uniqueness
re-verified by deliberate collision**: the default filename `demo_twoway_results`
was re-used unchanged, the plugin appended `_1`, and the original file was left
byte-identical.

```
table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,effect_type,effect_label,n1,n2,mean1,sd1,median1,mean2,sd2,median2
demo_twoway,SPL_dB,task,Speech,Singing,Welch,-7.277861,37.92,0.00000001,-2.1009,Cohen's d,large effect,24,24,87.9761,2.9811,87.9854,96.5116,4.9117,95.8455
```

---

### D32 — GRAPHING / ACCURACY (**high**) — the graph preset bridge cannot carry a second factor, so the default figure silently drops it

`scripts/eml-compare-twoway.praat:92–94` hands the graph engine a preset:

```praat
emlGraphsPresetType = 11
emlGraphsPresetGroupCol$ = factor1$
emlGraphsPresetDataCol$ = dataCol$
```

`factor2$` is never assigned to anything. There is no subgroup preset variable
in the bridge at all — the declared set at `graphs/eml-graphs-form.praat:117–119`
is only type / dataCol / groupCol.

Downstream, the Grouped Violin preset branch (`eml-graphs-form.praat:4363–4381`)
resolves `gvCatIdx` and `gvValueIdx` from the preset and **never touches
`gvSubIdx`**, which therefore keeps its initializer:

```praat
gvCatIdx = 1
gvSubIdx = min (2, nCols)
gvValueIdx = min (3, nCols)
```

On `demo_twoway` (`subject, voice_type, task, SPL_dB`) that is column 2 =
`voice_type` — the same column the preset just assigned to Category. The
Column Mapping dialog opens with **Category and Subgroup set to the same
column**, and the heuristic fallback in the `else` branch (4390–4400) cannot
rescue it because it keys on the literal strings "song"/"category" and
"platform"/"group"/"condition", none of which match `voice_type` or `task`.

Consequence, captured in `pic_tw_default.png`: the out-of-box figure is a
**two-violin single-factor plot** (Soprano, Alto) with `task` absent entirely.
No error, no warning. The dropped factor is the one with the *largest* effect
(F = 107.67, partial η² = .71) and half of a significant interaction. The
legend redundantly repeats the two x-axis tick labels, and the Soprano violin
is visibly bimodal — that bimodality *is* the suppressed task effect showing
through, unexplained and unlabelled.

The failure is also fragile rather than merely wrong: `min (2, nCols)` is a
column-order accident. Had `subject` sorted second, Subgroup would have
resolved to a 48-level identifier column.

**A/B differential drive proves the renderer is innocent.** Re-running the
identical path with only Subgroup changed by hand to `task` produced
`pic_tw_grouped.png` — four violins correctly paired under Soprano and Alto,
legend Speech/Singing, and geometry matching all four cell medians (87.21 /
92.74 / 89.48 / 101.22). The defect is entirely in the bridge.

**Proposed fix:** declare `emlGraphsPresetSubgroupCol$ = ""` alongside its
siblings at `eml-graphs-form.praat:119`; clear it wherever the other two are
cleared (2534/2535, 2896/2897, 3238, 3693/3694, 4026/4027, 4380/4381,
4699/4700, 5023, 5807–5809); consume it in the type-11 branch to set
`gvSubIdx`; and set it from `factor2$` at `eml-compare-twoway.praat:94`.

### D33 — ACCURACY / CLARITY (**high**) — Draw annotates a two-way design with a two-group Welch t on one marginal

With Annotate ticked, the corrected four-cell figure carries the caption:

```
Welch t: t(37.9) = -7.28, p < .001, d = -2.10 (pooled)
```

with a grey sub-line reading `Welch t-test` and a 2×2 significance matrix.

The numbers are exact — verified t = -7.277861, df = 37.920318,
d = -2.100938 for `task` pooled across `voice_type`. The *test* is the
problem. It collapses one factor of a factorial design, ignores the other main
effect, and ignores a significant interaction (p = .0003) that specifically
means the task effect is not constant across voice type. The source comment at
`eml-graphs-form.praat:5359` confirms this is deliberate:

```praat
# Grouped Violin: compare sub-groups (pooled across categories)
```

That is a defensible default for a Grouped Violin reached from the graphs menu.
It is not defensible for a Grouped Violin reached from the *two-way ANOVA*
wrapper, where the user has just been shown an interaction term.

Three compounding effects:

1. The annotation appends a full `EML Stats : Two-Group Comparison` block to
   the Info window, **below** the ANOVA table, with the complete `Why:` /
   signal-to-noise narration — so the pooled t is the *last* and most
   verbosely explained thing in the transcript.
2. `Exp CSV` writes a row with `test = Welch, group_col = task` into
   `demo_twoway_results_1.csv` — a filename one character from the ANOVA
   export sitting beside it.
3. A user who ran a two-way ANOVA, clicked Draw, clicked Exp CSV and shipped
   the folder has a Welch t masquerading as their factorial result.

Minimum fix: when the preset type is 11 *and* a second factor was supplied,
either suppress the annotation or label it explicitly as a marginal
comparison. Better: annotate with the ANOVA result already in hand.

### D34 — CLARITY (**high-medium**) — the ANOVA CSV omits SS, MS, and residual df

The export carries `statistic` (F) and `df`, but `df` holds the **numerator**
df only, as `1.00`. There is no denominator df, no SS column, no MS column,
and no Error or Total row. `F(1,44) = 34.11` — the minimum reportable form —
**cannot be constructed from the export**. Neither can the ANOVA table be
reconstructed, nor any alternative effect size recomputed.

The Info window has all of it. The CSV, which is what actually travels into a
manuscript, has none of it.

### D14 — REOPENED, and corrected — `fixed$` guarantees a *minimum* of one significant digit, not the requested precision

D14 was recorded FALSIFIED on the grounds that `fixed$` never floors a nonzero
value to zero. That is true but incomplete. Praat's `fixed$` guarantees **at
least one significant digit**, so the digit count is a floor on significance,
not a cap on width. The exported p-values are the proof:

| True p | `fixed$(p,6)` | significant digits |
|---|---|---|
| 5.788464e-07 | `0.0000006` | 1 |
| 2.112098e-13 | `0.0000000000002` | 1 |
| 3.024778e-04 | `0.000302` | 3 |

The first two are single-significant-digit renderings, and the second is
fourteen characters wide from a six-decimal request. Nothing is lost to zero,
but below 1e-6 the exported p is not the p that was computed. Scientific
notation is the correct format for this column.

### D35 — CLARITY (**high-medium**) — worst instance of the D28 family: nine orders of magnitude flattened to one string

All three Info-window p-values render as the identical string `p < .001`:

```
voice type          ...  34.1104     p < .001      (true p = 5.79e-07)
task                ...  107.6672    p < .001      (true p = 2.11e-13)
voice type x task   ...  15.3943     p < .001      (true p = 3.02e-04)
```

The three effects span **nine orders of magnitude** of evidence and are
presented as indistinguishable — in the one table in the whole plugin where
relative effect strength across rows is the point of reading it. Elsewhere D28
costs the user resolution on a single number; here it costs the entire
comparative structure of the result.

### D36 — CLARITY (**medium-high**) — no cell means and no marginal means, despite a significant interaction

The block reports SS/df/MS/F/p and partial η² and stops. There is no cell-means
table, no marginal means, no SDs, no plot of the interaction. A significant
interaction (p = .0003) is **uninterpretable without cell means** — it says the
factors are not additive but not in which direction. The user cannot tell from
this output that the task effect is +11.8 dB in sopranos and +5.3 dB in altos.

The one-way path (wrapper 6) reports per-group descriptives. The two-way path,
which needs them more, reports none.

### D37 — CLARITY (**medium**) — no N reported anywhere in the two-way block

No per-cell n, no per-level n, no total N. Wrapper 6 reported `Total N 45`; the
two-group block that the *graph* path appends reports N 24 / 24. So the same
Info transcript contains a section that reports N and a section that does not,
for the same table. Internally inconsistent as well as incomplete.

### D38 — CLARITY (**medium**) — no simple effects, no post-hoc, and no caution that the interaction qualifies the main effects

With a significant interaction the conventional next step is simple effects
(task within each voice type, or voice type within each task). The plugin
offers none, and — more importantly — does not warn that the two main-effect
rows above it should now be read with caution. Wrappers 6 and 7 both offer
pairwise follow-ups. Wrapper 8, where follow-up is most needed, offers nothing.

### D39 — PACKAGING (**medium**) — stats exports default into the plugin's own install directory

The `Export Results` dialog pre-filled Output folder as:

```
/home/claude/drive/prefs/plugin_EML_Praat_Tools/scripts
```

Source: `stats/eml-output.praat:757` and `scripts/eml-wizard.praat:1612` both
use `folder: "Output folder", defaultDirectory$`. `defaultDirectory$` is
Praat's built-in for the *running script's* directory — i.e. inside the
plugin. User data lands in the plugin tree and is at risk on reinstall or
upgrade, and is invisible where the user would look for it.

The graphs module already does this correctly and should be copied:

```
:434  config_lastCSVFolder$ = homeDirectory$ + "/Desktop"
:437  config_lastCSVFolder$ = homeDirectory$          (fallback)
:5743 folder: "Output folder", config_lastCSVFolder$
:5757 config_lastCSVFolder$ = output_folder$          (persists last used)
```

So the same plugin has a good pattern and a bad pattern for the same problem,
split by module. Two call sites to change.

### D40 — GRAPHING (**medium**) — no interaction plot among the 14 graph types

The registry at `eml-graphs-form.praat:139–152` (`nGraphTypes = 14`) offers
Pitch Contour, Waveform, Spectrum, LTAS, Line Chart (±CI), Bar Chart, Violin
Plot, Scatter Plot, Box Plot, Histogram, Grouped Violin, Grouped Box Plot,
Time Series (with CI), Spaghetti Plot.

The canonical companion figure for a two-way ANOVA — means ± CI with factor 1
on x and factor 2 as connected lines, where non-parallel lines *are* the
interaction — does not exist. `Line Chart (±CI)` is the nearest existing type
and could plausibly gain a subgroup mapping rather than requiring a 15th type.

### D41 — CLARITY (**low-medium**) — no effect-magnitude labels, inconsistent with wrappers 6 and 7

The two-way block gives bare partial η² values with no small/medium/large
gloss. Wrapper 6 (ANOVA) and wrapper 7 (Kruskal-Wallis) both provide magnitude
labels. The CSV's `effect_label` column is likewise **blank on all three rows**
— D17 recurring, and confirming the previously predicted line numbers
3784 / 3790 / 3796 in `eml-inferential.praat`.

### D42 — CLARITY (**low-medium**) — explanation narration is asymmetric within a single transcript

`emlShowExplanations` is on: the graph-path two-group block carries the full
`Why:` line, signal-to-noise gloss, df interpretation, p interpretation, and
effect-size interpretation. The two-way ANOVA block immediately above it
carries **none** — no `Why:`, no F gloss, no partial-η² gloss. The user is
given a tutorial on the test they did not ask for and silence on the one they
did.

### D43 — GRAPHING (**low**) — no auto-title, against Rule 28A

The `EML Graphs` dialog opens with Title and Subtitle blank and no title is
rendered on either figure. Every input needed to compose one is in hand
(`demo_twoway`, `SPL_dB`, `voice_type`, `task`). Wrapper 6 has the same gap;
this is the second instance.

---

### Recurrences confirmed on this wrapper

- **D6** — `demo twoway`, `SPL dB`, `voice type`, `task` in the Info header
  for objects actually named `demo_twoway`, `SPL_dB`, `voice_type`. Also
  `voice type x task` for the interaction term.
- **D6 — positively falsified for dialogs.** The `Two-Way ANOVA` dialog header
  renders `Table: demo_twoway` with the underscore **intact**. D6 is therefore
  confined to Info-window and Picture-window text formatting, not to pause
  dialogs. This narrows the fix surface.
- **D9** — `p` repeated in the p column (`p    p < .001`).
- **D16b** — the corrupted `Formatting:` help line, unchanged, in the Grouped
  Violin Column Mapping dialog.
- **D17** — `effect_label` blank on all three CSV rows.
- **D20** — no homogeneity-of-variance check offered or reported. This dataset
  happens to pass (Levene p = .648, Shapiro on residuals p = .334), so the
  omission costs nothing here, but nothing in the output tells the user that.
- **D23** — df rendered `1.00` in the CSV for an integer df.
- **D24** — zero-as-NA sentinel across `n1,n2,mean1,sd1,median1,mean2,sd2,median2`
  on all three ANOVA rows.
- **D18 — does not recur.** The default filename derived correctly as
  `demo_twoway_results`. D18 stays scoped to the paired-reshape path.

### Schema note

On the three ANOVA rows, `group2` duplicates `group_col` exactly, and `group1`
carries a *row type* (`main effect` / `main effect` / `interaction`) rather
than a group label. The shared column schema is being bent to carry
row-taxonomy metadata it was not designed for; a `row_type` column would be
the honest fix, and would also let a consumer distinguish these rows from the
Welch row that the graph leg writes into an adjacent file.

---

## Path 9 — `New → EML Tools → Correlate two columns...` (menu y=650)

Wrapper: `scripts/eml-correlate.praat` v3.3 (11 May 2026), 174 lines.
Table: `demo_correlation` (object 21). Columns: `speaker`(1),
`speaking_F0_Hz`(2), `singing_F0_Hz`(3), `age_years`(4); N = 30.

### Dialog / coordinate map

| Window | Size | Controls |
|---|---|---|
| `Correlate Two Columns` | 524x339 | Column X (384,70) · Column Y (384,102) · Group column (384,171) · Test (384,204) · Clear Info window (277,257) · buttons y=303: Undo 56, Quit 224, **Run 413** |
| `Analysis complete` | 524x113 | y≈78: **Done 179, CSV 275, Draw 365, New 460** |
| `Export Results` | 524x218 | folder area (250,57) · Browse (452,27) · File name (388,132) · buttons y=182: Undo 56, Go Back 224, **Save 414** |
| `Export Complete` | 524x113 | Done (179,78) |
| `EML Graphs` | 524x288 | Graph type (384,27) · Title (384,66) · Subtitle (384,98) · Color mode (384,131) · width (384,169) · height (384,207) · buttons y=252: Undo 56, Quit 224, **Continue 414** |
| `Scatter Plot -- Column Mapping` | 524x1033 | buttons y=995: Undo 56, Go Back 182, Quit 273, Beginner 371, **Draw 461** |
| `Graph Complete` | 524x150 | Done (179,115) |

The `Test` optionmenu is exactly three items (`eml-correlate.praat:61–64`):
Pearson r / Spearman rho / Both. **There is no Kendall branch** — a prior
session's assumption that option 3 was Kendall tau was wrong and is corrected
here.

### Ground truth (scipy, n = 30)

```
pearson  r   = 0.9034648447892789   t = 11.152573500753283  df = 28
             p = 8.214741835137006e-12   r2 = 0.8162487257701159
             Fisher 95% CI = [0.805319546134667, 0.9534085636382932]
spearman rho = 0.9150166852057842   p = 1.4837801214418103e-12
slope = 2.118033404437952   intercept = -2.753163480357671
shapiro speaking_F0_Hz: W = 0.93084 p = 0.05170   <-- borderline
shapiro singing_F0_Hz:  W = 0.97549 p = 0.69726
```

### Accuracy — exact on every path

| Reported | Value | Truth | Verdict |
|---|---|---|---|
| Pearson r | 0.9035 | 0.9034648 | exact to 4 dp |
| Pearson t | 11.153 | 11.152574 | exact to 3 dp |
| df | 28 | 28 | exact |
| N | 30 | 30 | exact |
| Spearman rho | 0.9150 | 0.9150167 | exact to 4 dp |
| Spearman t | 12.002 | 12.0022 (rho·√(df/(1−rho²))) | exact to 3 dp |
| Graph annotation R² | 0.816 | 0.8162487 | exact to 3 dp |
| CSV p | 0.000000000008 | 8.2147e-12 | correct, and **not** floored |

Column auto-guess correctly skipped the string column `speaker` and proposed
indices 2 and 3. The `colX$ = colY$` collision is guarded
(`eml-correlate.praat:86–87`, `pauseScript`). The n<3 group guard fires
correctly. All four accuracy criteria pass.

### Verbatim Info output — Pearson (default)

```
══════════════════════════════════════════════
  EML Stats : Correlation Analysis
  Wed Aug  5 14:04:59 2026
══════════════════════════════════════════════

  Table               demo correlation
  Column X            speaking F0 Hz
  Column Y            singing F0 Hz
  N                   30


  ── Pearson Correlation ─────────────────────
  r                   0.9035
  t                   11.153
  df                  28
  p                   p < .001

══════════════════════════════════════════════
```

### Verbatim Info output — Spearman

```
  ── Spearman Correlation ────────────────────
  rho                 0.9150
  t                   12.002
  df                  28
  p                   p < .001
```

`Both` emits the Pearson block followed by the Spearman block inside one
`═══`-framed report. Correct.

### Verbatim CSV export

```
table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,effect_type,effect_label,n1,n2,mean1,sd1,median1,mean2,sd2,median2
demo_correlation,speaking_F0_Hz,singing_F0_Hz,,,Pearson,0.903465,28.00,0.000000000008,0.9035,r,,30,30,0,0,0,0,0,0
```

Filename derived correctly as `demo_correlation_results.csv` — **D18 does not
recur here**; that finding stays scoped to the paired-reshape path.

---

### D44 — CLARITY — R² is gated behind `emlShowExplanations`, so the Info window omits it while the figure annotation displays it

`emlReportCorrelationAnalysis` (`graphs/eml-annotation-procedures.praat:3251–3255`)
computes and prints R² **only inside the explanations gate**:

```praat
@emlReportLine: "r", emlPearsonCorrelation.r, 4
if emlShowExplanations
    .r2 = emlPearsonCorrelation.r * emlPearsonCorrelation.r
    @emlWizardExplainR2: .r2
    @emlReportLine: "R-squared", .r2, 4
endif
```

`emlShowExplanations` defaults to `0` (`stats/eml-output.praat:63`) and is set
to `1` in exactly one place in the plugin — inside `@emlGraphsWorkflow`
(`graphs/eml-graphs-form.praat:794`). The analysis path never turns it on.

Consequence: the Info window reports r, t, df, p and stops. The scatter figure
produced from the *same run* is annotated `r = 0.903, R² = 0.816, p < .001`.
One analysis, two different answers about what a correlation report contains.

R² is a statistic, not an explanation. Explanations are prose that helps a
novice interpret a number; R² *is* a number, and it is the number most
correlation write-ups actually quote. It is misclassified. Fix: move the
computation and the `@emlReportLine` out of the gate, leave only
`@emlWizardExplainR2` inside it.

### D45 — ACCURACY (schema) — the CSV writes the Y variable into the `group_col` slot

`eml-annotation-procedures.praat:3268–3269`:

```praat
@emlCSVAddRow: .tableName$, .colX$, .colY$,
... "", "", "Pearson",
```

The row schema is `table,data_col,group_col,group1,group2,test,…`. The third
positional argument is `group_col`, and the wrapper passes `colY$` into it. The
exported row therefore reads `data_col=speaking_F0_Hz,
group_col=singing_F0_Hz`.

A downstream consumer — including EML Graphs' own CSV-reading paths — that
reads `group_col` expecting a grouping factor gets a continuous variable. It is
not a display bug: the file on disk is wrong about what its own columns mean.
A correlation needs an `x_col`/`y_col` pair; the shared schema has no such slot
and is being bent to fit. Same structural problem as D32/two-way (the schema
carrying row-taxonomy metadata) — this is the second wrapper to bend it.

### D46 — ACCURACY (schema) — CSV descriptives hardcoded to six literal zeros

Line 3273 of the same call:

```praat
... .n, .n, 0, 0, 0, 0, 0, 0
```

`mean1,sd1,median1,mean2,sd2,median2` are all written as literal `0` even
though both variables' means, SDs, and medians are well-defined, meaningful,
and already available in the Table. Exported row:

```
…,30,30,0,0,0,0,0,0
```

This is the worst instance so far of the zero-as-NA family (D24). In every
prior case the zero stood in for a quantity that was genuinely undefined for
that test; here the quantities exist and are simply not fetched. A consumer
computing across exported rows will average real means with zeros.

### D47 — CLARITY — the `Group column` optionmenu is unfiltered and offers the correlated columns as grouping factors

`eml-correlate.praat:56–60`:

```praat
optionmenu: "Group column", 1
    option: "(none — overall only)"
for iCol from 1 to nCols
    option: emlTableColumnNames.name$ [iCol]
endfor
```

Every column is offered, including `speaking_F0_Hz` and `singing_F0_Hz` — the
two continuous variables currently selected as X and Y. Grouping a correlation
by one of its own variables is never a meaningful operation; grouping by any
30-distinct-value continuous column produces 30 singleton groups. Same class as
the string-column offer in `Compare Paired Observations`. A grouping menu
should offer only columns with a plausible number of distinct levels, and
should exclude the two columns already bound to X and Y.

### D48 — CLARITY — per-group results print *after* the report's closing rule, with no summary and no terminator

The wrapper runs `@emlRunCorrelationAnalysis` first — which emits its own
closing `═══` rule — and only then enters the per-group loop
(`eml-correlate.praat:102–136`). The Info window therefore shows a complete,
visually closed report, followed by 60 more lines outside the frame that simply
stop mid-air:

```
  p                   p < .001

══════════════════════════════════════════════

  Spk1: Skipped (n < 3)

  Spk2: Skipped (n < 3)
…
  Spk30: Skipped (n < 3)
```

There is no per-group section header, no closing rule after the group block,
and no summary line. The report's own typography tells the reader the output
ended two-thirds of the way through it.

### D49 — CLARITY — 30 identical skip lines, each preceded by a blank line

`eml-correlate.praat:131–133`:

```praat
else
    appendInfoLine: ""
    appendInfoLine: "  " + .gDisplay$ + ": Skipped (n < 3)"
endif
```

Every skipped group costs two lines. With `speaker` selected that is 60 lines
of the Info window saying nothing that one line could not: `30 groups skipped
(n < 3): Spk1–Spk30`. On a real dataset with many small groups this buries the
overall result that *is* present above it. Accumulate skipped names and emit
one summary line after the loop.

### D50 — CLARITY — no confidence interval on r

The report gives r, t, df, p. It does not give a CI, though the Fisher z
interval is three lines of arithmetic from values already in hand
(here: 95% CI [0.8053, 0.9534]). Every reporting standard that asks for an
effect size asks for its interval alongside; the plugin reports the point
estimate only. Same omission as the effect-size CIs noted in the two-group and
ANOVA paths — this is now consistent enough across wrappers to be an
architectural gap rather than a per-wrapper oversight.

### D51 — GRAPHING — `Regression: None` is the default on a scatter launched from a correlation, while the same figure annotates R²

The preset bridge (`eml-correlate.praat:149–165`) sets six globals:

```praat
elsif clicked = 3
    if testChoice = 2
        emlGraphsPresetCorrType$ = "spearman"
    elsif testChoice = 3
        emlGraphsPresetCorrType$ = "both"
    else
        emlGraphsPresetCorrType$ = "pearson"
    endif
    emlGraphsPresetType = 8
    emlGraphsPresetXCol$ = colX$
    emlGraphsPresetYCol$ = colY$
    emlGraphsPresetAnnotate = 1
    emlGraphsPresetAnalysisType = 1
    if hasGroupCol
        emlGraphsPresetGroupCol$ = groupCol$
    endif
    @emlGraphsWorkflow: tableId
```

No regression preset is ever set, so the Column Mapping dialog opens with
`Regression: None`. The resulting figure carries the annotation
`r = 0.903, R² = 0.816, p < .001` over a bare point cloud: the goodness-of-fit
statistic for a line that is not drawn. R² has no visual referent in the
figure. A scatter reached from the correlation wrapper should default to
`Regression: Linear`.

### D52 — CLARITY — no loop repopulation; `New` resets every control to literal defaults

`beginPause:` at `eml-correlate.praat:44` uses literal defaults
(`optionmenu: "Test", 1`, `boolean: "Clear Info window", 0`) rather than
variables carrying the previous iteration's choices. Confirmed twice by
observation: after a Spearman run, `New` reopens with Test back on Pearson;
after checking `Clear Info window`, `New` reopens with it unchecked. Only
Column X/Y survive, and only because they are seeded from
`emlWrapperInit.guessDataIdx`, not from the user's last choice. This is the
Appendix F §S2C loop-repopulation requirement, unimplemented — and it is the
`New` button that makes it matter, since that button exists precisely to
support iteration.

### D53 — CLARITY — no assumption guidance, in the one wrapper that offers the nonparametric alternative in the same dialog

The dialog offers Pearson / Spearman / Both and gives the user nothing to
choose between them with — no normality check, no note that Spearman is the
rank-based alternative, no flag when the data are skewed. `demo_correlation` is
a pointed case: `speaking_F0_Hz` has Shapiro p = 0.0517, sitting exactly on the
conventional threshold. A user has to already know the answer to use the menu
correctly. D20 family, but sharper here than elsewhere, because the remedy is
one dropdown away in the same dialog.

---

### Recurrences confirmed on this path

| ID | Evidence |
|---|---|
| D6 | Info header shows `demo correlation` / `speaking F0 Hz`, while the *dialog* header shows `Table: demo_correlation` with the underscore intact. Third confirmation that D6 is confined to Info/Picture display text, not a global mangling. |
| D9 / D28 | `p < .001` printed for p = 8.21e-12. |
| D16b | Scatter mapping dialog help line renders `Formatting: %italic · #bold · ^super · sub · \ % prints % (e.g. %F 0)` — `_sub` and `%F_0` both mangled. |
| D39 | Export folder pre-filled `/home/claude/drive/prefs/plugin_EML_Praat_Tools/scripts` — the plugin install directory. |
| D17 / D41 | `effect_label` written blank. |
| D42 | No `Why:` narration on any analysis-path block. **Now root-caused**: `emlShowExplanations` is only ever set inside `@emlGraphsWorkflow` (`eml-graphs-form.praat:794`), so the asymmetry is structural, not per-wrapper. |
| D43 | Figure has no auto-generated title (Rule 28A). |

### Passes — recorded explicitly

- **The n<3 group guard is correct.** It fires, it names the group, it does not
  attempt the test.
- **`colX$ = colY$` is guarded** (`eml-correlate.praat:86–87`) with a clear
  `pauseScript` message.
- **Filename derivation is correct** — `demo_correlation_results.csv`.
- **The CSV writes p at full precision** (`0.000000000008`), not the `< .001`
  display floor. The floor is a display-layer problem only.
- **The scatter preset bridge is complete and correct** — type 8, XCol, YCol,
  CorrType, Annotate, AnalysisType, and GroupCol when present. This matters
  beyond this path: it is a working example of a wrapper handing a full column
  binding to EML Graphs, which **strengthens D32**. The two-way wrapper's
  dropped `factor2` is an oversight in that wrapper, not a limitation of the
  preset mechanism.

---

## Wrapper 10 / 17 — `Linear regression` (menu y = 675)

**Table:** `demo_regression` (object 22) — 25 rows, 4 columns:
`singer` (string, 1), `practice_hrs_wk` (2), `vibrato_regularity_pct` (3),
`experience_yrs` (4). Dumped to `out/dump_demo_regression.csv`.

**Source:** `scripts/eml-regress.praat`, 115 lines, v2.1 (11 May 2026).
Header purpose line: *"OLS simple linear regression (slope, intercept, R², SE,
F, p) with Theil-Sen robust alternative."*

### Dialog / coordinate map (origin 0,0)

| Dialog | Size | Controls | Buttons |
|---|---|---|---|
| `Simple Linear Regression` | 524x440 | Predictor column (384,203); Response column (384,236); Group column (384,304); Clear Info window (277,358) | y=404: Undo 56, Quit 224, **Run 413** |
| `Analysis complete` | 524x113 | — | y≈78: **Done 179, CSV 275, Draw 365, New 460** |
| `Export Results` | 524x218 | folder text area (250,57); Browse (452,27); File name (388,132) | y=182: Undo 56, Go Back 224, **Save 414** |
| `Export Complete` | 524x113 | — | Done 179,78 |
| `EML Graphs` | 524x288 | Graph type (384,27); Title (384,66); Subtitle (384,98); Color mode (384,131); width (384,169); height (384,207) | y=252: Undo 56, Quit 224, **Continue 414** |
| `Scatter Plot -- Column Mapping` | 524x1033 | X (384,63); Y (384,96); Use group column (277,127); Group column (384,160); Group order (384,192); Correlation method (384,268); **Regression (384,300)**; Significance style (384,332); Show data points (277,363); Dot size (384,396) | y=995: Undo 56, Go Back 182, Quit 273, Beginner 371, **Draw 461** |
| `Graph Complete` | 524x150 | — | Done 179,115 |

### Ground truth (Python/scipy, n = 25) — Rule 32

```
slope            = 3.3135438235      intercept        = 38.2524521357
r                = 0.9365062796      r2               = 0.8770440117
p                = 5.950627e-12      slope stderr     = 0.2586979275
intercept stderr = 3.1931788351      t (slope)        = 12.8085441400   df = 23
SSR = 5911.049980  SSE = 828.691585  SST = 6739.741565  F = 164.058803
residual SE      = 6.0025052210
shapiro residuals            W=0.967864  p=0.591511
shapiro practice_hrs_wk      W=0.969442  p=0.630950
shapiro vibrato_regularity_pct W=0.928016 p=0.078216   max = 100.000000 (ceiling in demo data)
pearson practice~experience  r=0.7859338034  p=3.22e-06
pearson vibrato~experience   r=0.7039713062  p=8.60e-05
```

### Info window — verbatim (`out/reg_default_info.txt`)

```
══════════════════════════════════════════════
  EML Stats : Simple Linear Regression
  Wed Aug  5 14:11:27 2026
══════════════════════════════════════════════

  Table               demo regression
  Response (Y)        vibrato regularity pct
  Predictor (X)       practice hrs wk
  N                   25

  ── Model ───────────────────────────────────
  Equation            y = 3.3135x + 38.2525
  R                   0.9365
  R-squared           0.8770
  Adj. R-squared      0.8717
  Residual SE         6.0025

  ── Overall Model Test (F) ──────────────────
  F(1,23)             164.0588
  p                   p < .001

  ── Coefficients ────────────────────────────

                    Estimate      SE            t             p
Intercept           38.2525       3.1932        11.979        p < .001
practice hrs wk     3.3135        0.2587        12.809        p < .001

  Direction: positive (vibrato regularity pct increases as practice hrs wk increases)
  Variance explained  large effect

══════════════════════════════════════════════
```

`cat -A` confirms the coefficients block sits flush-left at column 0 while
every other block in the report is indented 2 spaces, and that the header row
has no label above the term column.

### Accuracy — exact on every reported value

| Reported | Value | Truth | ✓ |
|---|---|---|---|
| slope | 3.3135 | 3.3135438 | ✓ |
| intercept | 38.2525 | 38.2524521 | ✓ |
| R | 0.9365 | 0.9365063 | ✓ |
| R-squared | 0.8770 | 0.8770440 | ✓ |
| Adj. R-squared | 0.8717 | 0.871698 | ✓ |
| Residual SE | 6.0025 | 6.0025052 | ✓ |
| F(1,23) | 164.0588 | 164.058803 | ✓ |
| intercept SE / t | 3.1932 / 11.979 | 3.1931788 / 11.9794 | ✓ |
| slope SE / t | 0.2587 / 12.809 | 0.2586979 / 12.8085 | ✓ |
| CSV statistic | 164.058803 | 164.058803 | ✓ |
| CSV p | 0.000000000006 | 5.95e-12 | ✓ (not floored) |

**This is the most complete and the most accurate report of any wrapper
audited so far.** Every number in the Info window and in the CSV matches
scipy. The findings below are therefore entirely clarity, schema, and
graphing — not computation.

### CSV — verbatim (`out/demo_regression_results.csv`, 331 bytes, ASCII)

```
table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,effect_type,effect_label,n1,n2,mean1,sd1,median1,mean2,sd2,median2
demo_regression,vibrato_regularity_pct,practice_hrs_wk,regression,regression,OLS linear,164.058803,23.00,0.000000000006,0.8770,R-squared,large effect,25,0,3.3135,0.2587,38.2525,3.1932,0.9365,0
```

### Findings

**D54 — ACCURACY (schema) — CSV descriptive columns are repurposed as an
ad-hoc coefficient carrier, with nothing in the file signalling it.**
The six descriptive slots carry, in order: `mean1=3.3135` (slope),
`sd1=0.2587` (slope SE), `median1=38.2525` (intercept), `mean2=3.1932`
(intercept SE), `sd2=0.9365` (R), `median2=0` (unused). This is strictly
worse than D46's six literal zeros: there the columns were empty and
obviously so; here they are populated with quantities that have nothing to do
with their names, and a downstream consumer stacking exported rows and
averaging `mean1` would silently average slopes together with group means.
The row is self-describing only in `test` (`OLS linear`) — a consumer would
have to hardcode a per-test reinterpretation of the descriptive block to read
this file correctly. Either add named coefficient columns or leave the
descriptive block empty.

**D55 — ACCURACY (schema) — `group1` and `group2` both carry the sentinel
string `regression`.** These slots name the two levels being contrasted.
There are no levels in a regression, so the wrapper writes a literal test-name
sentinel into both. Combined with D45's recurrence below, three of the four
identity columns in this row (`group_col`, `group1`, `group2`) contain
something other than what their names denote.

**D56 — CLARITY — the coefficients table breaks the report's own layout
contract.** Every other block is indented 2 spaces; the coefficients block is
flush-left at column 0, so it reads as though it has escaped the report frame.
The header row (`Estimate  SE  t  p`) has no label above the term column, so
the leftmost column is unnamed. And the `p` column mixes a numeric-aligned
header with the string `p < .001` in both cells — a column whose values are
never numbers under this data. Fix: indent to match, label the term column
(`Term`), and either print numeric p or head the column `p (2-tailed)` and
right-align the strings.

**D57 — CLARITY — no confidence interval on slope or intercept, despite both
standard errors being computed and printed.** The 95% CI is one `t` quantile
away from data already on screen (slope: 3.3135 ± 2.0687 × 0.2587 =
[2.7784, 3.8487]). A regression report that gives SE but not CI hands the
reader an interval they must finish by hand. Same family as D50 (no CI on r).

**D58 — CLARITY — no residual diagnostics in the one wrapper whose entire
purpose is OLS.** No normality-of-residuals test, no homoscedasticity check,
no influential-point or leverage flag, no Durbin-Watson. The residuals here
are in fact clean (Shapiro W = 0.9679, p = 0.5915), which is precisely why
their absence is invisible to a user on demo data and dangerous on real data.
The plugin already runs Shapiro-Wilk elsewhere (`Check normality`), so the
machinery exists. Same family as D20.

**D59 — CLARITY — `Y = slope x X + intercept` uses the letter `x` as the
multiplication sign immediately adjacent to the variable `X`**
(`eml-regress.praat:42`). In a dialog whose next control is literally labelled
`Predictor column (X)`, the string `slope x X` invites the reading "slope times
x times X". Use `·` or `*`, or write `Y = b₁X + b₀`. The same collision recurs
in the Info window's `Equation  y = 3.3135x + 38.2525`, where `x` is doing
duty as the predictor name and the report elsewhere calls that variable
`practice hrs wk`.

**D60 — GRAPHING — the scatter's Y axis runs 40–110 on a variable named
`_pct` whose data ceiling is exactly 100.** Rule 28E requires percentage
scales to use the full 0–100 (or 0–1) range; the wrapper instead applied Rule
28F's generic ±10% buffer to the data extremes, producing an axis that
extends 10 points past a physically impossible value while cropping the
bottom 40 points of the actual scale. The `_pct` suffix and the exact-100.0
maximum are both available at draw time. A percentage-aware branch in the axis
computation would resolve this and D-class recurrences in every future
percentage plot.

**D61 — CLARITY — the wrapper's documented "Theil-Sen robust alternative" is
unreachable from the wrapper, and the `Regression: Both` control does not mean
what it appears to mean here.** Two separate problems, resolved by source
reading rather than by the queued A/B drive:

1. `eml-regress.praat:5` states the purpose as *"OLS simple linear regression
   … with Theil-Sen robust alternative."* The script never calls
   `@emlTheilSen`. The estimator does exist and is well tested
   (`stats/eml-inferential.praat:3999`, 47-check suite at
   `dev/tests/phase2/test-theilsen.praat`, scipy-referenced), but the only
   path that reaches it is in the draw layer
   (`graphs/eml-draw-procedures.praat:2419–2431`), which selects Theil-Sen
   **only** when `annotCorrType$ = "spearman"` **and** `.reportedOLS = 0`.
   Entering through this wrapper sets `emlGraphsPresetCorrType$ = "pearson"`
   and reports OLS, so both conditions fail by construction. The wrapper
   offers no estimator control of any kind. A user reading the header is
   promised a robust alternative that the dialog cannot deliver.
2. The `Regression` optionmenu reads **None / Regression line / Formula /
   Both** (`graphs/eml-graphs-form.praat:3390–3394`), where `Both` means
   *line and formula* (`regression = 2 or 4` → line;
   `regression = 3 or 4` → formula, lines 3578–3586) — **not** two
   estimators. In a scatter launched from a regression wrapper whose header
   advertises a second estimator, `Both` is the worst available label: the
   figure it produces (one maroon line + one `OLS: y = …` annotation) is in
   fact correct, but is indistinguishable from a figure that silently dropped
   a second fit. Rename to `Line + formula`, or scope the label.

**The queued A/B drive is cancelled** — the source resolves it, and the
observed figure is confirmed correct for the selected option.

**D62 — CLARITY — `Variance explained  large effect` formats a benchmark
verdict as a label/value measurement pair.** It sits in the same
two-column layout as `R-squared  0.8770` and `Residual SE  6.0025`, so a
qualitative Cohen-style label is presented with the visual authority of a
computed statistic. Elsewhere the report correctly narrates in prose
(`Direction: positive (…)`). Either narrate this too, or label it
`Effect size benchmark`.

### Recurrences

| Prior ID | Recurs here as |
|---|---|
| D9 / D28 | `p < .001` floor appears **three times in one report**, including twice inside a table column headed `p`. Sharpest instance yet: the CSV proves full precision is available (`0.000000000006`). |
| D23 | `df=23.00` — two decimals on an integer degrees-of-freedom. |
| D24 | `n2=0` — zero standing in for not-applicable. |
| D43 | Figure has no auto-generated title. |
| D45 | `group_col=practice_hrs_wk` — the predictor written into the grouping slot. Second wrapper with this schema error. |
| D47 | `Group column` optionmenu unfiltered (`eml-regress.praat:53–57`) — offers the predictor and response themselves as grouping factors. |
| D52 | No loop repopulation (`eml-regress.praat:37`) — `New` resets every control to guess/literal defaults. |

### Passes — recorded explicitly

- **Column auto-guess is correct.** `@emlWrapperInit: 2` picked predictor 2
  and response 3, skipping the string column `singer` — the exact failure mode
  that made `optsel` misfire earlier in this audit.
- **`predCol$ = respCol$` is guarded** (`eml-regress.praat:77–78`) with a
  clear `pauseScript`.
- **Filename derivation is correct** — `demo_regression_results.csv`.
- **`effect_label=large effect` is populated**, in direct contrast with the
  blank of D17/D41. The blank is per-wrapper, not architectural.
- **`endPause` carries the trailing 0** (`eml-regress.praat:89`), S0-compliant.
- **The Draw preset bridge is complete — including the regression preset.**
  `eml-regress.praat:96–106` sets type 8, XCol, YCol, CorrType, Annotate,
  AnalysisType, GroupCol, **and `emlGraphsPresetRegressionLine = 1`**. That
  last line is exactly what `eml-correlate.praat:149–165` omits, which
  **confirms D51 as a wrapper-9 omission rather than a limitation of the
  preset mechanism.** Two wrappers now demonstrate that the bridge carries
  whatever a wrapper chooses to hand it (cf. D32).
- **Every computed value matches scipy**, including the F statistic to six
  decimals and p to full float precision in the CSV.
- **Reported estimator and drawn estimator are forced identical.**
  `graphs/eml-draw-procedures.praat:2414–2427` carries an explicit v1.19 fix:
  when the OLS report has already been emitted (`.reportedOLS = 1`), the drawn
  line is OLS even if the correlation type would otherwise route to Theil-Sen.
  This is exactly the Info-window/figure coherence failure this audit has been
  looking for elsewhere, already found and fixed by the author. Recorded as a
  pass, and as the counter-example to D42/D44's gating pattern: the codebase
  does sometimes keep the two output surfaces in sync deliberately.

---

## Wrapper 11/17 — `Pairwise comparisons` (menu y=727)

Table: `demo_3groups` (object 20), `SPL_dB` by `voice_type`, n=15/group.
Three legs driven: **default analysis**, **CSV**, **Draw** (violin +
annotation matrix) **and the Draw path's own CSV export**.

Ground truth (scipy, Rule 32), retained for every claim below:

```
Soprano n=15 mean=91.443778 sd=5.180019 median=91.598494
Mezzo   n=15 mean=89.105330 sd=5.943727 median=87.714222
Alto    n=15 mean=84.852190 sd=2.975599 median=84.315664
ANOVA  F=7.076697  p=2.2456335001e-03  df (2, 42)
Welch t  S-M p=2.6056811390e-01   S-A p=3.0080262689e-04   M-A p=2.1958703915e-02
  x3 (Bonferroni)  0.7817043417      0.00090240788067        0.065876111745
Tukey    S-M p=3.9421875874e-01   S-A p=1.7103444152e-03   M-A p=5.4187394797e-02
  q = meandiff/sqrt(MSE/n), MSE=23.672, SE=1.2562 -> 1.861486 / 5.247135 / 3.385649
Cohen's d  S-M 0.419455   S-A 1.560455   M-A 0.904902
```

### D63 — ACCURACY — The figure and the exported CSV report a **different test family** than the analysis that launched them, with no disclosure on any screen

The Info window, at 14:19:55, headed itself:

```
  EML Stats : Pairwise Welch t-test (bonferroni adjustment)
              Soprano     Mezzo       Alto
Soprano       ---         0.7817      < .001
```

`Draw` was then taken from that same `Analysis complete` dialog. The figure
it produced annotates:

```
One-way ANOVA: F(2, 42) = 7.08, p = .002
               Tukey HSD
            Soprano   Mezzo    Alto
Soprano       -         -      .002
```

Same table, same columns, same session, consecutive screens — **two different
tests and two different numbers for the same Soprano–Alto comparison.**
Arithmetic identifies which is which and rules out rounding as the
explanation: Tukey S–A = 1.7103444152e-03 renders `.002`; Welch×Bonferroni
S–A = 9.0240788067e-04 and pooled×Bonferroni = 6.0312018609e-04 would both
render `< .001`. The figure is Tukey. The Info window is Welch/Bonferroni.
Both are internally correct; neither says so.

The exported CSV (below, D65) makes it worse — it writes the string
`Tukey HSD` into a `test` column of a file the user believes holds their
pairwise Welch results.

**Root cause, established from source without a second drive.** The bridge
procedure has no adjustment parameter at all
(`graphs/eml-annotation-procedures.praat:1773`):

```praat
procedure emlBridgeGroupComparison: .tableId, .dataCol$, .factorCol$,
... .alpha, .style$, .showNS, .showEffect, .testType$, .layoutMode
```

and its parametric k≥3 branch hardcodes the test (lines 2149–2173):

```praat
else
    # --- One-way ANOVA + Tukey HSD ---
    @emlOneWayAnova: .tableId, .dataCol$, .factorCol$, 1
    ...
    annotMatrixPosthoc$ = "Tukey HSD"
```

The bridge is therefore incapable of drawing what the pairwise wrapper
computed. It does not read the wrapper's result at all; it recomputes from
the table under its own fixed method. Fix is one of: pass the analysis
result through the preset bridge (the mechanism already exists — see the
regression preset at `eml-regress.praat:96–106`, which hands over eight
settings including `emlGraphsPresetRegressionLine`), or, at minimum, label
the figure with the test it actually ran *and* warn when it differs from the
report on screen.

### D64 — ACCURACY — The `Adjustment method` optionmenu on the graphing dialog is **inert** whenever `Test type = Parametric` and k ≥ 3

The `Violin Plot -- Column Mapping` dialog presents `Adjustment method:
Bonferroni` at full prominence, immediately under `Test type`, with no
caveat. It has no effect on the parametric path.

`.correction$` is resolved at `eml-annotation-procedures.praat:1800/1803`
and consumed at exactly two sites, **both inside the nonparametric branch**:

```praat
2001:  @emlDunnTest: .tableId, .dataCol$, .factorCol$, .correction$
2010:  annotMatrixPosthoc$ = "Dunn's test (" + .correction$ + ")"
```

`grep -n "adjMethod"` on the file returns zero hits. All four call sites
(`eml-graphs-form.praat:5352, 5360, 5370, 5378`) pass nine arguments, none
of them an adjustment method.

Note the internal inconsistency: the *analysis* wrapper's dialog does scope
this control honestly — `Adjustment (t and Wilcoxon only):`. The *graphing*
dialog offers the same restricted control with the caveat removed. The
correct behaviour is to grey the control out when the selected test type
cannot use it; the minimum acceptable behaviour is to restore the caveat.

### D65 — ACCURACY — The Draw path's CSV export is **byte-identical to a different wrapper's export**, and claims the same default filename

`Exp CSV` on `Graph Complete` → `Export Results` → `Save` wrote
`demo_3groups_results_2.csv`. `diff` against
`demo_3groups_results.csv` — written 80 minutes earlier by **wrapper 6,
`Compare k groups (ANOVA)`** — reports the files identical:

```
table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,...
demo_3groups,SPL_dB,voice_type,omnibus,omnibus,One-way ANOVA,7.076697,2.00,0.002246,0.2520,eta-squared,large effect,0,0,...
demo_3groups,SPL_dB,voice_type,Soprano,Mezzo,Tukey HSD,1.861486,42.00,0.394219,0.4195,Cohen's d,small effect,15,15,91.4438,...
demo_3groups,SPL_dB,voice_type,Soprano,Alto,Tukey HSD,5.247135,42.00,0.001710,1.5605,Cohen's d,large effect,15,15,91.4438,...
demo_3groups,SPL_dB,voice_type,Mezzo,Alto,Tukey HSD,3.385649,42.00,0.054187,0.9049,Cohen's d,large effect,15,15,89.1053,...
```

Two consequences compound. First, this is D63 reaching the filesystem: a
user who runs *Pairwise comparisons*, draws, and exports receives a file of
ANOVA/Tukey results. Second, because the default filename is derived from
the **table** and not the analysis (D39 family), the folder now holds
`demo_3groups_results.csv`, `_1.csv`, `_2.csv` — three files from three
different wrappers, distinguishable only by opening them, and two of which
are the same bytes. The `@emlReportToFile` uniquifier is doing its job
correctly; the filename it is uniquifying carries no analysis identity.

Suggested key: `<table>_<analysis>_results` (e.g.
`demo_3groups_pairwiseWelch_results`).

### D66 — ACCURACY — `CSV` on the analysis-side `Analysis complete` dialog **cannot ever succeed**, and its failure message blames the filesystem

Recorded from the CSV leg. `CSV` yields `Export Failed` /
"Could not write CSV file." No write is attempted:
`emlExportStatsCSV` short-circuits `.success = 0` when `emlCSV_n = 0`
(`stats/eml-output.praat:604`) before touching disk, and
`emlWrapperExportCSV` (754–773) renders that as a filesystem error.

The rows are never added. `stats/eml-analysis.praat` contains **11
`@emlCSVInit` calls and zero `@emlCSVAddRow` calls** (init sites 207, 278,
346, 407, 680, 742, 829, 1012, 1116, 1420, 1479). All 20 `AddRow` sites live
in `graphs/eml-annotation-procedures.praat` — which is precisely why the
Draw-path export in D65 succeeded while this one failed. **Same button
label, same dialog idiom, one works and one is structurally incapable of
working.**

**Blast radius — corrected 5 Aug after drive-verification.** The earlier
prediction named the wrong wrapper. *Compare paired/repeated* **exports
correctly**: it dispatches `@emlRunPairedAnalysis`
(`scripts/eml-compare-paired.praat:107`), which is not one of the
init-without-add orchestrators, and whose reporter
`emlReportPairedComparison` (`graphs/eml-annotation-procedures.praat:3626`)
does call `@emlCSVAddRow`. Driven end to end on `demo_paired`, its `CSV`
button opened `Export Results` and wrote a fully populated 310-byte row. It
is also 2-condition-only (Test offers just Paired t-test / Wilcoxon / Both),
so it cannot reach RM-ANOVA or Friedman at all.

Call-site grep establishes the real radius:

| Orchestrator | init site | reached from |
|---|---|---|
| `emlRunPairwiseAnalysis` | 407 | `scripts/eml-pairwise.praat:102`, `scripts/eml-wizard.praat:630/637` |
| `emlRunRepeatedMeasuresAnalysis` | 1420 | `scripts/eml-wizard.praat:1012` **only** |
| `emlRunFriedmanAnalysis` | 1479 | `scripts/eml-wizard.praat:1022` **only** |

So the affected surface is the **Pairwise comparisons** wrapper (menu y=727)
and the **Stats Wizard's** repeated-measures and Friedman branches — the
latter two reachable from nowhere but the wizard. Those three are queued for
drive-verification; *Compare paired/repeated* is cleared.

Minimum fix: make the message truthful ("No exportable rows were produced by
this analysis"). Real fix: add the `AddRow` calls, or route the wrapper's
CSV button through the same reporters the graphing path uses.

### D67 — CLARITY — Cohen's d is printed for every pair; n, means and SDs for the groups are printed nowhere

The report gives a 3×3 d matrix but never states that each group has n=15,
never gives a group mean, and never gives a group SD. The reader is handed
the effect size and denied every input to it. The CSV proves the plugin has
all of it in hand (`n1,n2,mean1,sd1,median1,mean2,sd2,median2` are populated
columns) — the Info window simply declines to show it.

### D68 — CLARITY — No test statistic and no degrees of freedom

`Pairwise Welch t-test` reports p and d only. There is no t and no df — for
Welch, df is the informative part (it is fractional and differs per pair),
and its absence makes the result unreproducible from the report. Contrast
wrapper 9, which reports `r`, `t`, `df`, `p` for a single correlation.

### D69 — CLARITY — The raw p is never shown

Only the adjusted value appears, under the heading `Adjusted p-values`. Since
the adjustment method is itself named only in the report title (lowercase —
D75), and since three pairwise comparisons at Bonferroni is a ×3 the reader
must reverse mentally, showing both columns costs one column and removes all
ambiguity.

### D70 — CLARITY — No significance marking and no alpha anywhere in the report

Neither matrix marks significance, and the report never states the alpha in
force. The dialog collected `Alpha 0.05`; the output does not echo it. The
reader is left to threshold `0.0659` by eye against a criterion they have to
remember. (The figure has the mirror-image problem — it shades by
significance but never states the alpha either: D72.)

### D71 — CLARITY — Two adjacent matrices use opposite symmetry conventions, unexplained

```
  ── Adjusted p-values ──          ── Cohen's d (effect sizes) ──
Soprano  ---   0.7817  < .001    Soprano  ---    0.419   1.560
Mezzo  0.7817  ---     0.0659    Mezzo   -0.419  ---     0.905
Alto   < .001  0.0659  ---       Alto    -1.560  -0.905  ---
```

The p matrix is symmetric; the d matrix is antisymmetric, because d carries
the direction of the difference. This is correct and is the right choice —
but nothing on screen says the sign encodes direction, or which direction
(row-minus-column). A reader scanning both matrices in the same visual idiom
will read `-1.560` as a negative effect size.

### D72 — GRAPHING — The annotation matrix encodes four states in colour and glyph, and legends none of them

The figure's matrix uses: **blue shading** = significant, **grey shading** =
tested and not significant, **white / blank lower triangle** = not shown, and
two visually distinct dashes on and off the diagonal. At 250% magnification
the diagonal dash (light grey, short) is distinguishable from the
nonsignificant dash (dark, longer em-dash); **at the figure's delivered
scale they read as the same glyph.** So "self-comparison, not applicable"
and "tested, not significant" are rendered indistinguishably, and the alpha
that drives the shading is never stated.

Rule 28D/G. Either add a two-line key under the matrix, or use `n.s.` for
tested-nonsignificant and leave the diagonal empty.

### D73 — GRAPHING — Auto-derived axis label drops the unit parenthesis

Column `SPL_dB` → axis label `SPL dB`. Rule 28B (underscore→space) is
satisfied; Rule 28C (units in parentheses) is not. The plugin already knows
the convention — hand-written labels elsewhere in the codebase use
`Frequency (Hz)`. A trailing-token heuristic (`_dB`, `_Hz`, `_s`, `_ms`,
`_pct`) would cover the common cases; anything unrecognised falls through to
current behaviour.

### D74 — CLARITY — Dialog section rule is `--- Options ---` where every other wrapper uses the box-drawing rule

`emlWrapperCommonFields` (`stats/eml-output.praat:643–646`) emits
`comment: "--- Options ---"`. Every report body in the plugin uses
`── Section ──`. One shared procedure is the outlier; the fix is one line
and lands everywhere at once.

### D75 — CLARITY — Report header casing does not match the control that set it

Header: `Pairwise Welch t-test (bonferroni adjustment)`. The optionmenu the
user selected reads `Bonferroni`. `@emlAdjustMethodName` should return the
display casing, or the header should title-case what it interpolates.

### D76 — CLARITY — The CSV omnibus row carries only `dfBetween`; `dfWithin` is dropped

`One-way ANOVA,7.076697,2.00,0.002246` — a single `df` column holding `2.00`.
`dfWithin = 42` appears only in the per-pair Tukey rows (`42.00`). F cannot
be re-tested from the omnibus row alone. A `df2` column, or `df` as `2, 42`,
resolves it.

### Recurrences

| Prior ID | Recurs here as |
|---|---|
| D9 / D28 | **Sharpest instance in the audit.** Info prints `< .001` for a Welch×Bonferroni p of **0.00090241** — a value that clears the floor by 10%. The figure prints the corresponding Tukey p as `.002`, so the two surfaces disagree partly *because* one of them was floored. |
| D23 | `df=2.00`, `df=42.00` — two decimals on integer degrees of freedom, in the CSV. |
| D24 | Omnibus CSV row writes `n1=0,n2=0,mean1=0,sd1=0,median1=0,…` — zero standing in for not-applicable, in eight columns. |
| D39 | `Export Results` folder defaulted to the last-used path this time (`/home/claude/drive/out`) rather than the plugin directory — the persistence works. The **filename** default (`<table>_results`) is the surviving half of D39; see D65. |
| D43 | Figure has no title. The `EML Graphs` dialog's `Title` field arrived **blank** despite the launch context knowing the table, both columns, and the test. |

### Passes — recorded explicitly

- **Column auto-guess is correct in both dialogs.** The analysis wrapper and
  the graphing column-mapping dialog independently bound `SPL_dB` → Value and
  `voice_type` → Group, skipping the string column. No misfire.
- **Every reported number is exact.** Info matrix (all six off-diagonal
  cells), figure annotation (`F(2, 42) = 7.08`, `p = .002`, `.002`), violin
  medians (91.6 / 87.7 / 84.3 vs scipy 91.598494 / 87.714222 / 84.315664),
  and all 76 CSV fields verified against scipy. Nothing is wrong; things are
  *inconsistent* (D63), which is a different and more dangerous failure.
- **The `T test type` control is demonstrably live.** M–A = `0.0659`
  = Welch×3 (0.0658761), not pooled×3 (0.0585062). Verified from a single
  run's values without an A/B drive.
- **Tukey `statistic` is the canonical studentized range `q`.** The plugin
  reports 1.861486 / 5.247135 / 3.385649 = meandiff/sqrt(MSE/n); scipy's
  `TukeyHSDResult.statistic` is parameterised as the *mean difference*. The
  plugin is right and scipy's field name is the trap — **do not flag this.**
- **Effect-size labels are effect-type-aware.** `eta-squared 0.2520 → large`
  (Cohen .01/.06/.14) and `Cohen's d 0.4195 → small` (Cohen .2/.5/.8) are
  both correct under their own conventions. The label logic is not a single
  hardcoded threshold ladder.
- **Violin y-axis is Rule 28E/F compliant** — 70–110 against data spanning
  78.4–105.3, round marks, generous buffer, no collisions.
- **`@emlReportToFile` uniquification is sound** — `_1`, `_2` ascending,
  `fileReadable`-guarded, nothing overwritten. Rule 27 satisfied at the
  mechanism level; the defect in D65 is upstream, in the name it is handed.
- **The graph-path CSV export works end-to-end** — Browse/Save dialog,
  folder persistence, uniquified write, well-formed 20-column output. This is
  the working half of the contrast that makes D66 a defect rather than a
  missing feature.

---

## Wrapper 5 re-drive — root-cause of the bad paired defaults (`@emlGuessColumnRoles`)

**Context.** `Compare Paired Observations` opened on the plugin's own `demo_paired`
table with **Column 1 = `jitter_pre`, Column 2 = `HNR_pre`** — i.e. the default
offered by the plugin is a paired t-test of jitter against harmonics-to-noise
ratio. `demo_paired` columns are `1 subject · 2 jitter_pre · 3 jitter_post ·
4 HNR_pre · 5 HNR_post`, so the obviously-correct default is 2 vs 3.

**Empirical confirmation (direct procedure probe).** A probe script was written
into the *installed* plugin's `scripts/` directory (so the relative
`include ../stats/...` paths resolve), then delivered with `--send`:

```praat
include ../stats/eml-core-utilities.praat
include ../stats/eml-core-descriptive.praat
include ../stats/eml-extract.praat
selectObject: 19
@emlGuessColumnRoles: 19
writeInfoLine: "dataIdx    ", emlGuessColumnRoles.dataIdx
appendInfoLine: "dataIdx2   ", emlGuessColumnRoles.dataIdx2
appendInfoLine: "groupIdx   ", emlGuessColumnRoles.groupIdx
appendInfoLine: "subjectIdx ", emlGuessColumnRoles.subjectIdx
appendInfoLine: "timeIdx    ", emlGuessColumnRoles.timeIdx
```

Output:

```
dataIdx    2
dataIdx2   4
groupIdx   1
subjectIdx 1
timeIdx    3
```

This matches the hand-trace exactly. (Probe file deleted from the installed
plugin afterwards — it must never reach a build.)

**Hand-trace.** Keyword scores: `subject` sS=10; `jitter_pre` dS=10 / tS=6;
`jitter_post` dS=10 / tS=6; `HNR_pre` dS=8 / tS=6; `HNR_post` dS=8 / tS=6.
Greedy assignment: R1 `subject`→subject (10, first max wins on strict `>`);
R2 `jitter_pre`→data (10); R3 — data and subject are done and every group
score is 0, so the best remaining cell is `jitter_post`→**time** (6), which
sets `taken[3]=1`; R4 finds nothing. The secondary-data scan then *skips*
`jitter_post` because it is `taken`, and falls through to `HNR_pre` (dS=8).

---

### Finding D77 — ACCURACY (high) — the `pre|post` keyword makes the *time* role steal the second member of a paired pair

`stats/eml-extract.praat`, `procedure emlGuessColumnRoles` (line 1545), PASS 1:

```praat
# Weight 6: short temporal keywords (boundary-checked)
@eml_kwScan: .cn$, "pre|post|rep|day|week|time|date|take"
if eml_kwScan.hit = 1 and .tS[.col] < 6
    .tS[.col] = 6
endif
```

and the secondary-data scan later in the same procedure:

```praat
# ── Secondary data column (paired/correlation) ───────────────────
.bestD2 = 0
for .col from 1 to .nCols
    if .taken[.col] = 0 and .dS[.col] > .bestD2
        .bestD2 = .dS[.col]
        .dataIdx2 = .col
    endif
endfor
```

The very token that identifies a column as the second half of a pre/post pair
(`post`) is what assigns it to the *time* role, marks it `taken`, and thereby
excludes it from `dataIdx2`. The time role is **never consumed** by
`eml-compare-paired.praat`, so the assignment buys nothing and costs the
correct default.

Severity is driven by plausibility of the wrong answer: a jitter-vs-HNR paired
t-test computes cleanly, returns a large t and a tiny p, and looks like a
result. Nothing in the Info window or the figure signals that the two columns
are different measures.

**Blast radius — all three consumers of `guessDataIdx2`:**

| Consumer | Line | Field defaulted |
|---|---|---|
| `scripts/eml-compare-paired.praat` | 28 | `Column 2` |
| `scripts/eml-correlate.praat` | 37 | `guessYIdx` |
| `scripts/eml-regress.praat` | 30 | `guessRespIdx` |

Exposed to wrappers at `stats/eml-output.praat:743`
(`.guessDataIdx2 = emlGuessColumnRoles.dataIdx2`), documented at
`stats/eml-output.praat:675`.

**Suggested fix.** Do not let the time role consume a column that also carries a
high data score, or run the secondary-data scan *before* the time role is
assigned, or exclude time-role columns from `taken[]` for the purposes of the
`dataIdx2` scan only. The narrowest change with the least blast radius is the
last: scan for `dataIdx2` over `.taken[.col] = 0 or .col = .timeIdx`.

---

### Finding D78 — ACCURACY (medium) — `groupIdx` and `subjectIdx` resolve to the same column

The probe returns `groupIdx 1` and `subjectIdx 1` — column 1 (`subject`) holds
two roles simultaneously. The cause is the end-of-procedure fallback, which
assigns `groupIdx` **without consulting `taken[]`**:

```praat
elsif .groupIdx = 0
    # Data found but no group — first column != dataIdx
    for .col from 1 to .nCols
        if .col <> .dataIdx and .groupIdx = 0
            .groupIdx = .col
        endif
    endfor
```

The guard is `.col <> .dataIdx` only. Every other role — subject, time,
secondary data — is invisible to it.

The consequence surfaces wherever `guessGroupIdx` feeds a group-column default
on a repeated-measures table: `Compare two groups` on `demo_paired` would
default its grouping variable to the subject id, i.e. 20 groups of n = 1. That
path errors or produces degenerate output rather than a plausible-but-wrong
number, which is why this is medium and D77 is high.

**Suggested fix.** Add `and .taken[.col] = 0` to the fallback's condition, and
mark `groupIdx` as `taken` when it is assigned.

---

## Session 5 Aug — Compare paired/repeated, Draw leg

### D79 — CLARITY — the dialog line documenting the subscript marker is the one line where the marker is eaten by the toolkit

`graphs/eml-graphs-form.praat` emits this `comment:` at **13 sites**
(1442, 1641, 1792, 1956, 2286, …):

```praat
comment: "Formatting: %italic · #bold · ^super · _sub · \_% prints % (e.g. %F_0)"
```

Rendered on Linux/GTK it reads:

> Formatting: %italic · #bold · ^super · ̲sub · \ % prints % (e.g. %F 0)

Every literal `_` is consumed. GTK treats `_` in a label as a mnemonic
accelerator: `_s` underlines the `s` and removes the underscore. So
`_sub` loses its `_`, and the worked example `%F_0` — the whole point of
which is to show a subscript — renders as `%F 0`. The user is told to type
a character that the instruction itself cannot display.

Screenshot `x4c.png` (800% magnification) shows the mnemonic underline
strokes where the underscores were.

**Platform scope, stated honestly.** This is observed on Linux/GTK. Praat
on macOS uses Cocoa, where label mnemonics do not apply, so the author has
almost certainly never seen it — the line probably renders correctly on his
machine. It should be verified on Windows before the fix is scoped.

**Fix.** In GTK a literal underscore in a label is written `__`. Rather
than depend on that surviving Praat's own string handling across three
toolkits, the safer fix is to not put a bare `_` in a `comment:` at all —
reword to name the character, e.g. `underscore-sub`, and move the worked
example into the manual or a Picture-window caption where Praat's own
renderer is in charge. Whatever is chosen has to be applied at all 13
sites, not one.

### D80 — NOT A DEFECT — the Draw leg's wide-to-long conversion is correct

Recorded because it looked wrong and is not, so a later reader does not
re-open it.

*Compare paired/repeated* runs on a **wide** table (`demo_paired`:
`subject`, `jitter_pre`, `jitter_post`). Its `Draw` button pre-selects
`Spaghetti Plot` — correct routing for a paired design — and then opens
`Spaghetti Plot -- Column Mapping`, which asks for **long**-format columns:
Value (Y), Condition (X), Subject (participant ID). At first read that is
a format mismatch: those columns do not exist in `demo_paired`.

They do exist. Opening the `Value column` dropdown shows exactly three
options — `Subject`, `Condition`, `Value` — so the plugin has already
reshaped the wide table into a long one behind the dialog, and the three
roles are pre-assigned correctly (Value→Y, Condition→X, Subject→ID). The
reshape is silent and correct. `Use group column` is unchecked by default,
so the `Group column: Subject` default underneath it is inert.

Evidence: `x3.png` (graph-type dialog, Spaghetti Plot pre-selected),
`x4a.png`/`x4b.png` (column mapping), `x5.png` (dropdown contents).

### D81 — NOT A DEFECT — `Export Complete` reports the destination path in full

`Saved to: /home/claude/drive/out/csv/demo_paired_results.csv`, with the
underscores intact. Contrast D6 (Info-window display text strips them) and
D39 (the export folder *defaults* into the plugin install directory). The
confirmation dialog itself is exemplary: it names the artefact and where it
went, which is what makes D39 recoverable — the user can at least see where
the file landed.

---

---

## Drive continued — 5 August 2026, second session

Rig rebuilt on Praat 6.6.30 (June 30 2026), Xvfb :99 1400x1000x24,
matchbox-window-manager, xcompmgr, xdotool. Menu geometry re-derived from a
live screenshot and found unchanged from `harness/MENU_MAP.md`.

### D66 — PROMOTED from predicted to DEMONSTRATED on `emlRunPairwiseAnalysis`

**Route.** Objects → New → EML Tools → *Create Demo Table…* →
`Three groups (N=45) — ANOVA / Kruskal-Wallis` → `demo_3groups`
(`singer`, `voice_type`, `SPL_dB`, `vibrato_rate_Hz`, 15 per group).
Then *Pairwise comparisons…* (menu y=727) with the dialog's own defaults:
Data column `SPL_dB`, Group column `voice_type`, Test `Pairwise t-test`,
Adjustment `Bonferroni`, T test type `Welch`, Group order `Table order`.

**Accuracy of the analysis itself: correct.** Verified against
scipy `ttest_ind(equal_var=False)` with Bonferroni across the three pairs,
and Cohen's *d* on the pooled SD:

| pair | scipy t | scipy p (Bonferroni) | plugin p | scipy d | plugin d |
|---|---|---|---|---|---|
| Soprano–Mezzo | 4.8854 | 0.0001 | `< .001` | 1.784 | 1.784 |
| Soprano–Alto | 5.7072 | 0.0000 | `< .001` | 2.084 | 2.084 |
| Mezzo–Alto | 1.6047 | 0.3622 | `0.3622` | 0.586 | 0.586 |

Transcript: `evidence/info/pairwise_3groups_welch_bonferroni.txt`.

**The CSV export fails.** Pressing `CSV` on the `Analysis complete` dialog
opens `Export Results` (folder defaulted to
`…/plugin_EML_Praat_Tools/scripts`, filename `demo_3groups_results` — the
D39 default-into-the-install-tree behaviour). Pressing `Save` produces
`Export Failed` — *"Could not write CSV file."* No file is created.

**The filesystem is not the cause, and this was tested rather than
assumed.** The target folder is writable by the shell (`touch` succeeds) and
by Praat itself — `writeFileLine:` into that exact directory succeeded and
`fileReadable ()` returned 1 immediately afterwards. The directory is fine.

The cause is `emlCSV_n = 0`. `@emlRunPairwiseAnalysis` calls `@emlCSVInit`
(`stats/eml-analysis.praat:407`) and never reaches an `@emlCSVAddRow`.
`@emlExportStatsCSV` (`stats/eml-output.praat:601`) short-circuits on
`emlCSV_n = 0`, sets `.success = 0` and returns **without touching the
filesystem at all**; `@emlWrapperExportCSV` (`stats/eml-output.praat:769`)
then reports the failure as a write error.

This is the first *demonstrated* D66 instance. *Compare paired/repeated* was
cleared earlier the same day by live drive, so the finding now rests on
evidence at both ends rather than on call-graph inference.

**Structural note, wider than the three named orchestrators.** Every
`@emlCSVAddRow` call site in the plugin — all 21 of them — lives in
`graphs/eml-annotation-procedures.praat`. `stats/eml-analysis.praat`
contains eleven `@emlCSVInit` calls and zero `@emlCSVAddRow`. CSV row
construction therefore exists only on the graphs/annotation side, and any
analysis path that completes without routing through an annotation reporter
exports an empty body by construction. The three orchestrators named in the
5 August handoff are instances of that shape, not the boundary of it.

**Two defects, not one.** They should be fixed separately:

1. The rows are never built for these paths. That is the substantive bug.
2. A no-data condition is reported to the user as a filesystem write
   failure. Even after (1) is fixed, `@emlWrapperExportCSV` cannot
   distinguish "nothing to export" from "the disk refused the write", and
   the message it chooses sends the user to check permissions on a folder
   that is working correctly. `@emlExportStatsCSV` should return a distinct
   status for `emlCSV_n = 0` and the caller should say so.

Evidence: `evidence/shots/d66_pairwise_dialog.png`,
`d66_pairwise_complete.png`, `d66_pairwise_export_dialog.png`,
`d66_pairwise_export_failed.png`; input table
`evidence/csv/demo_3groups_input.csv`.

### Priority 1 concluded — the wizard's two repeated-measures orchestrators

**Route.** A wide table `demo_rm3` (`singer`, `SPL_soft`, `SPL_medium`,
`SPL_loud`; 20 subjects) was generated with a fixed seed and loaded from CSV,
because no built-in demo table offers three repeated conditions — the
`Paired measures` demo has two, and the RM branch requires three. Generator
and data: `evidence/csv/demo_rm3_input.csv`. Then *Stats Wizard* (menu
y=447) → *Compare groups or conditions* → *Yes — same people, repeated
(paired)* → *Three or more (RM-ANOVA / Friedman)*.

**The predicted test could not be run, because the button does not exist.**
The handoff called for driving each branch and pressing its CSV button. For
repeated measures there is no CSV button. The `Analysis complete` dialog
offers **Done** and **New** only — no CSV, no Draw — on both the RM-ANOVA
and the Friedman branch.

`eml-wizard.praat:1580` gates the four-button dialog (`Done`, `CSV`, `Draw`,
`New`) on the single flag `wizCanDraw`. `eml-wizard.praat:1030` sets
`wizCanDraw = 0` for the whole repeated-measures block. So the `@emlCSVInit`
calls at `stats/eml-analysis.praat:1420` and `:1479`, and the one at
`eml-wizard.praat:1574`, initialise an accumulator that no user action can
reach.

D66 therefore resolves differently across the three orchestrators:

| Orchestrator | Result |
|---|---|
| `emlRunPairwiseAnalysis` | **D66 confirmed** — CSV button present, export fails on `emlCSV_n = 0` |
| `emlRunRepeatedMeasuresAnalysis` | **No CSV route exists** — see D87 |
| `emlRunFriedmanAnalysis` | **No CSV route exists** — see D87 |

**Accuracy of both branches: correct.** Verified against scipy.

| quantity | scipy | plugin |
|---|---|---|
| RM-ANOVA *F*(2,38) | 583.1232 | 583.1232 |
| Greenhouse-Geisser ε | 0.8486 | 0.8486 |
| condition means | 72.465 / 83.355 / 94.129 | 72.4646 / 83.3546 / 94.1294 |
| post-hoc raw *p* (soft–medium) | 1.5384e-12 | 0.000000000002 |
| post-hoc raw *p* (soft–loud) | 1.0687e-20 | 0.00000000000000000001 |
| post-hoc raw *p* (medium–loud) | 5.4312e-12 | 0.000000000005 |
| Friedman χ²(2) | 40.0000 | 40.0000 |
| Friedman *p* | 2.0611e-09 | 0.000000002 |
| Wilcoxon post-hoc raw *p* (all pairs) | 1.9073e-06 | 0.000002 |

Holm adjustment is applied correctly in both branches, including the tied
case: all three Friedman post-hoc raw *p* are identical, and Holm's
monotonicity constraint correctly gives all three the same adjusted value
(3 × 1.9073e-06 = 5.72e-06, shown as `0.000006`).

Transcript: `evidence/info/wizard_rm3_rmanova_and_friedman.txt`.

### D82 — ACCURACY (high) — RM condition slots default to fixed column positions, ignoring type

`Condition 1`, `Condition 2` and `Condition 3` are hard-coded to option
indices 2, 3 and 4 (`eml-wizard.praat`, the `Repeated measures — select
condition columns` form), which is table columns 1, 2 and 3 in order.
Nothing consults `@emlGuessColumnRoles`, and nothing filters for numeric
columns.

The previous page's own help text says *"Each condition is its own column;
each row is one subject measured under every condition (wide format)."* A
wide table of that shape normally carries a subject identifier in column 1.
On `demo_rm3` the defaults therefore select `singer` — the ID column — as
`Condition 1`, and drop `SPL_loud`, the third real condition, entirely.

The user who accepts the defaults on a correctly-shaped table gets a wrong
analysis specification. This is the same failure family as D77/D78 but a
separate site: those concern `@emlGuessColumnRoles` guessing badly, this
concerns a form that never asks it.

Evidence: `evidence/shots/d82_rm_condition_defaults.png`.

### D83 — CLARITY (high) — the resulting failure blames the user's data, and discards the session

Running with those defaults produces:

> Need at least 2 complete-case subjects (rows with all conditions present).

The data has 20 complete cases. The message is a consequence of
`Condition 1` being a string column, so every row reads as missing on that
condition. The user is told their data is incomplete when it is not, and is
given no indication that the dialog's own default is at fault.

The wizard then **exits** (`Script exited`), discarding the research-goal,
observation-type and condition-count choices made on the three preceding
pages. Recovering means re-entering the entire wizard from the menu.

Two fixes, independent of D82: validate that every chosen condition column
is numeric *before* running and say which one is not; and return to the
form rather than exiting.

Evidence: `evidence/shots/d83_rm_complete_case_error.png`.

### D84 — CLARITY (low) — label collision on the condition-count page

On *Paired / repeated — how many conditions?* the comment line
`"How many repeated measurements per subject?"` is overlapped by the
`Conditions:` optionmenu row; the trailing words are occluded and unreadable.
The two are adjacent in the `beginPause:` block with a single empty
`comment:` between them, which is evidently not enough vertical space under
GTK.

Evidence: `evidence/shots/d84_ncond_label_collision.png`.

### D85 — CLARITY (high) — p-values render as long decimal strings

The RM-ANOVA branch prints:

```
F(2, 38) = 583.1232, p = 0.00000000000000000000000000003
Greenhouse-Geisser epsilon = 0.8486, GG-corrected p = 0.0000000000000000000000004
```

Twenty-nine and twenty-five decimal places respectively. These are not
readable, cannot be checked at a glance, and cannot be transcribed into a
manuscript.

The same plugin already does this correctly elsewhere: the *Pairwise
comparisons* wrapper prints `< .001` in the same situation. The convention
exists; the wizard's repeated-measures reporter does not use it. All the
post-hoc lines have the same problem.

Evidence: `evidence/shots/d85_rm_pvalue_rendering.png`.

### D86 — ACCURACY (medium) — no effect size for either repeated-measures test

RM-ANOVA reports *F*, *p*, and Greenhouse-Geisser ε, and no effect size —
no partial η², no generalised η². Friedman reports χ² and *p*, and no
Kendall's *W*. The post-hoc lines report *p* only, with no paired Cohen's
*d* or matched-pairs rank-biserial correlation.

The *Pairwise comparisons* wrapper reports Cohen's *d* for every pair, so
the plugin is internally inconsistent about whether an effect size
accompanies a test. For `demo_rm3` the values are partial η² = 0.968 and
Kendall's *W* = 1.000.

### D87 — CLARITY (high) — CSV export and Draw are gated by one flag

`eml-wizard.praat:1580` chooses between a four-button completion dialog
(`Done`, `CSV`, `Draw`, `New`) and a two-button one (`Done`, `New`) on the
single flag `wizCanDraw`. There is no separate flag for export.

Any design the wizard cannot graph therefore also cannot be exported, for no
reason connected to export. Repeated measures is such a design
(`wizCanDraw = 0` at `:1030`), so both RM-ANOVA and Friedman results are
trapped in the Info window: no CSV, no figure, and no indication that export
was ever an option.

This is the root cause of the missing CSV route above. Splitting the flag —
`wizCanDraw` and `wizCanExport`, set independently — restores export to
every branch that produces numbers, which is all of them.

Evidence: `evidence/shots/d87_friedman_no_csv_button.png`.

### Rig note — `curpause` and its dependants are unreliable

`gui.sh` → `curpause` finds the live dialog by `xdotool search --name
"^Pause"` filtered to `IsViewable`. Under this rig that fails in two ways at
once. Praat leaves every dismissed pause window in the X tree as an
unmapped window with its old name, so the search returns a growing list of
dead entries; and the live dialog is frequently absent from the search
results altogether while plainly visible on screen and accepting clicks at
its screen coordinates.

`pgeom` and `needclear` inherit the fault. Screenshot-derived absolute
coordinates worked throughout and are the reliable route; the window-search
primitives should be treated as advisory only.

A modal Praat *error* window, by contrast, does grab input and will silently
swallow every subsequent click. When a click appears to do nothing, take a
screenshot before retrying.

### Priority 2 — the interrupted Draw leg, completed

**Route.** *Create Demo Table…* → `Paired measures (N=20)` → `demo_paired`.
*Compare paired/repeated…* (menu y=549) → Column 1 `jitter_pre`,
Column 2 `jitter_post`, Paired t-test → Run → **Draw** → graph type left at
its pre-selected `Spaghetti Plot`, **Title left deliberately empty** →
Continue → column mapping accepted as pre-assigned → Draw.

Figure: `evidence/figures/d88_spaghetti_axis_0to10.png`.

**D77 reconfirmed on entry, with this table.** The wrapper opens with
Column 1 = `jitter_pre` and Column 2 = `HNR_pre` — two *different measures*
at the same timepoint, rather than two timepoints of one measure. Accepting
the defaults compares jitter against HNR. This is the D77 failure exactly as
described, now witnessed on `demo_paired` at the first dialog.

Separately, the `Column 1` and `Column 2` optionmenus are unfiltered: the
dialog's own instruction reads *"Select two numeric columns with paired data
(same N)"* and the menus offer `subject`, a string column, as option 1.
Same family as D47.

**Accuracy of the paired t-test: correct except the effect size.** Against
scipy `ttest_rel`:

| quantity | scipy | plugin |
|---|---|---|
| *t* | 7.726 | 7.726 |
| df | 19 | 19 |
| pre mean / SD / median | 2.696 / 0.823 / 2.683 | 2.696 / 0.823 / 2.683 |
| post mean / SD / median | 1.967 / 0.917 / 2.280 | 1.967 / 0.917 / 2.280 |
| mean difference | 0.7285 | 0.7285 |
| SD of differences | 0.4217 | 0.4217 |

### D15 — reconfirmed with a numeric demonstration

The report prints `Matched-pairs r 0.971` under the heading **Paired
t-test**. That number is not the *t*-derived correlation. It is the
matched-pairs rank-biserial correlation of the **Wilcoxon signed-rank**
test:

- Wilcoxon rank-biserial on this data: **0.971** — the printed value.
- *r* from the paired *t*: r = t/√(t² + df) = 7.726/√(7.726² + 19) =
  **0.871**.

The two differ by 0.1 and both look plausible, so nothing on screen reveals
the substitution. No Cohen's *d*z is reported either; for this data it is
1.728. D15 previously rested on reading the source; it now rests on two
numbers that disagree.

### D88 — GRAPHING (high) — `roundTo = 10` is hard-coded at 12 of 17 axis-range call sites

The spaghetti plot of `jitter_pre` → `jitter_post` is drawn on a **0–10**
y-axis for data spanning **0.528 to 4.191**. The traces occupy the bottom
**37%** of the panel; the top 5.8 units are empty.

The arithmetic, from `@emlComputeAxisRange`
(`graphs/eml-graph-procedures.praat:765`) with the `.roundTo = 10` passed by
`@emlDrawSpaghettiPlot` (`graphs/eml-draw-procedures.praat:1317`):

```
range  = 4.191 - 0.528 = 3.663
buffer = 0.366
rawMin = 0.161      rawMax = 4.557
axisMin = floor (0.161 / 10) * 10 = 0
axisMax = ceiling (4.557 / 10) * 10 = 10
```

`.roundTo` is the rounding granularity of the axis, and passing a literal
`10` fixes that granularity at ten units regardless of the data's magnitude.
Any measure whose full range is small relative to 10 is compressed into the
bottom of the panel. That is not an edge case in this field: jitter %,
shimmer %, contact quotient, most ratios and proportions, and any normalised
measure all fall inside it. With `.roundTo = 1` the same data yields a 0–5
axis and fills the panel.

**The literal `10` appears at 12 of the 17 `@emlComputeAxisRange` call
sites**, covering spaghetti, box, violin, bar, and time-series paths
(`eml-draw-procedures.praat:225, 240, 715, 1052, 1317, 1702, 2035, 2896,
3551, 3776` and `eml-graphs-form.praat:5428, 5432`). Two sites pass `5`, one
passes `0.05`.

**The fix already exists in this repository and was not propagated.** The
scatter path (`eml-draw-procedures.praat:2244` and `:2258`) derives its
granularity from the data:

```praat
@emlComputeNiceStep: .dataYMax - .dataYMin, emlSetAdaptiveTheme.targetTicksY
.yRoundTo = emlComputeNiceStep.step
@emlComputeAxisRange: .dataYMin, .dataYMax, .yRoundTo, 0
```

carrying the comment *"so fractional data (proportions, reaction times,
jitter %) is not snapped to the integer grid."* The problem was identified
and solved at one site. The remaining sites need the same two lines.

### D89 — GRAPHING (medium) — no default title is supplied, against Rule 28A

The `Title` field was left empty deliberately. The figure is drawn with no
title at all — not a derived one, not a placeholder. The plugin knows the
table name, both column names, the test that was run and its *p*; none of it
reaches the figure. A reader given the PNG alone cannot tell what was
measured or on what.

This is the same defect as D43, now confirmed on the paired/spaghetti path,
which means it is a property of the shared graphing form rather than of one
graph type.

### D90 — GRAPHING (medium) — axis labels carry the reshape's role names, not the measure

The y-axis reads **`Value`** and the x-axis **`Condition`**. Those are the
internal role names produced by the wide→long reshape recorded in D80, not
anything about the data. The tick labels underneath do carry the real
column names (`jitter pre`, `jitter post`), so the information is present in
the figure and simply not used for the axis label.

The y-axis is the one that matters: it is the only place the measured
quantity and its unit could appear, and it says `Value`. The column names
are available at the call site — `.valueCol$` is a parameter of
`@emlDrawSpaghettiPlot`.

(Underscores are stripped in the tick labels — `jitter pre` — which is the
D6 family again.)

### The graphs-side CSV export works, and its defaults differ from the analysis side

Pressing `Exp CSV` on the *Graph Complete* dialog after the spaghetti plot
produced a fully populated single-row file. This is the contrast case for
D66: the same plugin, a different entry point, and the row-building
reporters in `graphs/eml-annotation-procedures.praat` do get called.

```
table,data_col,group_col,group1,group2,test,statistic,df,p,effect_size,effect_type,...
demo_paired,jitter_pre,jitter_post,jitter_pre,jitter_post,Paired t-test,7.725968,19.00,0.0000003,0.9714,matched-pairs r,,20,20,...
```

Full file: `evidence/csv/pairedLong_results_5aug.csv`.

Four things this export shows:

- **The CSV carries full *p* precision where the Info window does not.**
  `0.0000003` against the Info window's `p < .001` for the same test. The
  D14 floor is a display-layer choice, not a computation limit.
- **D15 propagates into the export, and the export is honest about it.**
  `effect_size = 0.9714` with `effect_type = matched-pairs r`, under
  `test = Paired t-test`. The CSV names the quantity correctly; the Info
  window's `Matched-pairs r` heading under a parametric test is where the
  mislabelling bites.
- **D17 confirmed:** `effect_label` is empty on this path.
- **D18 confirmed, and D39 does not apply here.** The default filename is
  `pairedLong_results` — naming `pairedLong`, the internal reshape artefact,
  rather than `demo_paired`. But the default *folder* is `/root`, not the
  plugin install directory. The two CSV entry points disagree about where
  exports belong; neither default is right, and they are wrong differently.

### Priority 3 — the adjustment is applied, not merely labelled

Same table, same data, same test, one control changed. *Pairwise
comparisons* on a fresh `demo_3groups`, Welch, table order; run once with
`Adjustment = Bonferroni`, then reopened via `New` and run again with
`Adjustment = Holm`.

| pair | raw *p* | Bonferroni (scipy) | plugin | Holm (scipy) | plugin |
|---|---|---|---|---|---|
| Soprano–Mezzo | 0.01758 | 0.0527 | `0.0527` | 0.0228 | `0.0228` |
| Soprano–Alto | 3.678e-06 | 0.0000 | `< .001` | 0.0000 | `< .001` |
| Mezzo–Alto | 0.01140 | 0.0342 | `0.0342` | 0.0228 | `0.0228` |

Cohen's *d* matched at 0.924, 2.100 and 0.990.

This run is a stronger differential than the one the handoff anticipated,
because it crosses the conventional threshold: under Bonferroni the
Soprano–Mezzo contrast is **not** significant at .05 (0.0527), and under Holm
it **is** (0.0228). A cosmetic relabelling could not produce that. Holm's
monotonicity constraint also correctly pulls Mezzo–Alto up to the same
0.0228 rather than leaving it at its own step value, which is the detail a
naive step-down implementation gets wrong.

`Adjustment` on this wrapper is genuine. Note the label —
`Adjustment (t and Wilcoxon only)` — is accurate: D25 records that the
control is inert on the parametric k-group path, and the wrapper says so.

Input data: `evidence/csv/demo_3groups_b_input.csv`.

### Rig fix — use `xdotool getactivewindow`, not `search --name`

The window-search problem recorded above has a clean solution.
`xdotool getactivewindow` returns the live pause dialog reliably, including
every case where `xdotool search --name "^Pause"` returned only dead
unmapped windows. It also gives the id needed for `windowactivate --sync` +
`windowfocus` before typing into a GTK entry, which is how the *Output
folder* field was successfully retyped on the graphs-side export.

`gui.sh` → `curpause` should be redefined in terms of `getactivewindow`, and
`pgeom` and `needclear` will then work again.

### D91 — GRAPHING (medium) — the histogram frequency axis cannot be made data-derived without changing `@emlDrawAxes`

Opened while propagating the D88 fix to the remaining hard-coded call sites.
**This is a finding about an attempted fix that was backed out, and the
evidence is a figure the plugin does not currently produce.**

Fifteen of the seventeen `@emlComputeAxisRange` call sites now derive their
granularity from the data. Two do not: the histogram's frequency axis
(`@emlDrawHistogram`, ungrouped and faceted branches) still passes a literal
`5`.

**Why the obvious fix does not work.** Frequency is a count, so an integral
grid is required. Deriving `roundTo` from the data and flooring it at 1
gives correct axis *bounds* — on a 10-value contact-quotient histogram with a
maximum bin count of 3, the axis tightens from 0–5 to 0–4, which is the
improvement D88 predicts. But the *tick step* is not computed from `roundTo`.
It is derived downstream from `(range / targetTicks)`, and with the tighter
range that quotient falls below 1, so the axis is labelled in halves:
`0, 0.5, 1, 1.5 …` on a scale of counts.

Evidence: `evidence/figures/d91_histogram_fractional_counts.png`, produced by
driving the histogram with the adaptive change in place. Compare the current
behaviour, which is correct: 0–5 with integer ticks.

**A second attempt also failed.** Capping the tick target at the axis maximum
(so `range / targetTicks` cannot fall below 1) was applied to the gridline
calls in both histogram branches and re-driven. The gridlines changed; the
numeric labels did not. The labels come from `@emlDrawAxes`, which takes no
tick argument and is shared by every graph type in the plugin.

**What the real fix requires.** `@emlDrawAxes` needs to accept a tick
constraint — either an explicit step or a minimum step — so a caller can
declare "this axis is integral". That is a signature change on a procedure
every draw path calls, and it is not safe to make as part of a graphing fix
verified on one graph type.

Until then the two histogram sites keep their literal `5`. It is a
hard-coded value, but on a count axis an integral granularity is correct by
construction, which is not true of the twelve continuous-measure sites D88
covers. The cost is a frequency axis that can overshoot by up to four counts.


### D91 — RESOLVED — the count-axis constraint, and two failures on the way

Closed 5 August. The histogram frequency axis now derives its range from the
data like every other axis, and its ticks stay on whole counts.

**The mechanism.** `emlYAxisMinStep`, a global declared in
`@emlInitDrawingDefaults` and guarded in `@emlSetAdaptiveTheme`. Zero means
unconstrained. `@emlDrawHistogram` sets it to 1 immediately after its theme
call and releases it before returning. Four procedures honour it — the ones
that turn a range into a step:

- `@emlDrawGridlines` (y only; x is untouched)
- `@emlDrawHorizontalGridlines`
- `@emlDrawAlignedMarksLeft` — the one that writes the numbers
- `@emlDrawAlignedMarksRight` — its mirror on faceted panels

A global rather than a parameter because the constraint has to reach axis
bounds, gridlines and tick labels alike; threading it through would have
changed the signature of five procedures across roughly thirty call sites.
The plugin already carries cross-cutting display state this way
(`emlShowAxisNameX`, `emlShowTicksY`, `annotAlpha`).

**Two failures on the way, both found by driving rather than reading.**

1. **The reset was in the wrong place.** `emlYAxisMinStep = 0` was placed at
   the top of `@emlSetAdaptiveTheme`, on the assumption that every draw
   procedure calls it first. They do — but `@emlDrawAxes` calls it *again*,
   partway through the figure, and so cleared the constraint immediately
   before the tick marks were drawn. The figure came out unchanged and the
   cause was invisible in the diff.

2. **The global could be undefined.** Once the reset was scoped to the
   histogram, every *other* figure aborted with
   `Unknown variable: emlYAxisMinStep` — a draw procedure can be entered
   without `@emlInitDrawingDefaults` having run, and Praat aborts at the
   first comparison against an undefined global. This would have broken every
   continuous figure in a fresh session, and it was caught by the leakage
   test rather than by the change itself. Fixed with the same
   `variableExists` guard `@emlSetAdaptiveTheme` already uses for
   `emlPanelOriginX`.

Both hazards are now commented at the site, because neither is visible from
the code alone.

**Verified — three drives, on the same rig, in one session:**

| Test | Expected | Result |
|---|---|---|
| Histogram, max bin count 3 | integral ticks, range from data | 0–4, ticks 0 1 2 3 4 |
| Histogram, max bin count 5 | same, x-axis unaffected | 0–6 integral; x reads 1.5, 2, 2.5 … |
| Continuous figure first in a fresh session | no crash, fractional ticks | 0.05 st ticks, drew clean |
| Continuous figure immediately after a histogram | no leakage | identical to the fresh-session figure |

The count axis is now **better than before the D88 work**, not merely
restored: the old literal `5` gave 0–5 for a maximum count of 3, and the
derived range gives 0–4.

Figures: `evidence/figures/d91_FIXED_histogram_integer_ticks.png`,
`d91_FIXED_histogram_larger_counts.png`,
`d91_leakcheck_continuous_after_histogram.png`. The failure case remains at
`d91_histogram_fractional_counts.png`.

**All 16 axis-range call sites now derive their granularity from the data.**

### D92 — GRAPHING (high) — RESOLVED — the annotated path pinned violin and box axes to zero

Found while verifying that annotation headroom, rather than a minimum span,
supplies the extra y-axis room a figure needs.

**The same violin plot got two different axes depending on whether it was
annotated.** Unannotated, `@emlDrawViolinPlot` derives both bounds from the
data: SPL spanning 75.6–99.3 dB drew on 70–105. Annotated with significance
brackets, the axis became **0–170**, and the data occupied about 14% of the
panel.

The cause was in `graphs/eml-graphs-form.praat`, in the auto-range branch of
`@emlGraphsWorkflow` that runs only when brackets are drawn:

```praat
@emlComputeAxisRange: 0, visibleDataMax, .axisRoundTo, 0
valueMax = emlComputeAxisRange.axisMax
```

A literal `0` as the data minimum, and `valueMin` never assigned — so it kept
the sentinel 0 from the auto-range test above. Bar charts were already
correct here: the `graph_type = 6` branch passes `emlBarData_visibleMin`.
Violin and box fell to the `elsif`, which had no minimum to pass.

The interaction with headroom made it worse rather than merely wasteful.
`@emlComputeAnnotationHeadroom` scales its expansion by `yDataRange`, so a
range inflated from 30 dB to 100 dB by the zero floor produced roughly three
times the headroom actually needed, and the axis ran to 170 for data topping
out at 99.

**Fixed** by tracking `visibleDataMin` alongside `visibleDataMax` and passing
it. `@emlComputeAxisRange`'s own non-negative guard still holds the floor at
0 for data that does not go below it, so nothing that legitimately starts at
zero moves.

| Figure | Before | After |
|---|---|---|
| Annotated violin, SPL 75.6–99.3 dB, three brackets | 0 – 170 | **75 – 110** |
| Same data, unannotated | 70 – 105 | 70 – 105 (unchanged) |
| Annotated bar chart, same data | 0 – 170 | 0 – 170 (unchanged — correct) |

The bar chart is the control: bars emanate from the origin, so its floor
must stay at zero, and it does.

This closes the loop on the F0 minimum-span removal. The author's rule —
the data sets the range, and whatever is drawn on the figure supplies any
extension — now holds on the annotated path too. Brackets sit at 100–106 on
a 75–110 axis, which is headroom doing the work a minimum span used to do
badly.

Figures: `evidence/figures/d92_annotated_violin_zero_floored.png` (before),
`d92_FIXED_annotated_violin_headroom.png` (after),
`d92_regression_bar_keeps_zero_floor.png` (control).

### D4 — RESOLVED — kurtosis labels now say what they report

The computation was never wrong. `@emlKurtosis`
(`stats/eml-core-descriptive.praat:332`) computes the sample **excess**
kurtosis with the standard bias correction — Fisher's *g*₂, the estimator R's
`e1071::kurtosis(type=2)`, SPSS and Excel's `KURT` return, normal = 0 — and
its own header says so.

Five sites displayed it; three dropped the qualifier, and those three were
the wrappers a user actually reaches:

| Site | Was | Now |
|---|---|---|
| `stats/eml-analysis.praat:927` | `Kurtosis (excess)` | unchanged |
| `stats/eml-core-descriptive.praat:656` | `Kurtosis (excess)` | unchanged (dead code — D7) |
| `scripts/eml-describe-table.praat:151` | `Kurtosis` | `Kurtosis (excess)` |
| `scripts/eml-check-normality.praat:151` | `Kurtosis = ` | `Kurtosis (excess) = ` |
| `scripts/eml-wizard.praat:1768` | `Kurtosis:` | `Kurtosis (excess):` |

A reader who expects raw kurtosis sees `-0.56` where they would expect
`2.44` and concludes the distribution is markedly platykurtic when it is
close to normal.

Verified by drive — *Describe Table column* on `demo_3groups`, `SPL_dB`:

```
  ── Distribution Shape ──────────────────────
  Skewness            -0.2691
  Kurtosis (excess)   -0.5555
```

### D10 — still open, and worse than filed: three thresholds, two of them contradicting each other in one string

The threshold question is not one disagreement but three, and the plugin
argues with itself inside a single output line.

| Site | Threshold | Used for |
|---|---|---|
| `stats/eml-analysis.praat:1091` | `abs (.kurtosis) >= 3` | the shape flag that routes parametric vs nonparametric |
| `stats/eml-output.praat:966` | `abs (.excess) < 1` | classifying "Near-normal peakedness" in the wizard |
| `stats/eml-output.praat:974` | the string *"\|excess\| < 3 is typical threshold"* | told to the user, in the same procedure |

`@emlWizardExplainKurtosis` therefore classifies an excess kurtosis of 2 as
**"Heavy-tailed (leptokurtic)"** while the sentence printed beside that
verdict tells the reader values below 3 are typical. Both halves come from
the same six lines of code.

The classifier's `1` is the conventional companion to the `|skew| >= 1` gate
the shape flag already uses. The `3` appearing twice looks like a rule of
thumb written for the **raw** scale, where normal = 3, applied to the excess
scale — which is the "off by 3" the finding originally alleged, now located.

This is a judgement call about which convention the plugin should teach, not
a defect with one correct answer, so it is left for an author ruling rather
than changed. The three sites must end up agreeing whichever way it goes.

Note the procedure carries a comment recording an earlier bug (M1) in which
excess kurtosis was corrected a second time, labelling normal data as
`excess ≈ -3`. The area has a history of scale confusion.

### D15 — RESOLVED — each paired test now reports its own effect size

Author ruling, 5 August: match the effect size to the test, and show both
when the user asks for both.

The plugin computed the matched-pairs rank-biserial correlation
unconditionally — `@emlMatchedPairsR` sat outside the `if .testType$`
branches at `stats/eml-analysis.praat:740` — and the paired-t report block
printed it under the heading **Effect Size**, directly beneath *t*, df and
*p* from a test it had nothing to do with. No note in the repository, the
PKB, or the fix notes records that placement as a decision; the file is
present in the earliest committed snapshot, so it predates the repository.

**What changed.**

- New `@emlCohenDz` (`stats/eml-inferential.praat`): *d*z = mean(v1−v2) /
  sd(v1−v2), the standardised mean difference built from the same standard
  deviation the paired *t* is built from, plus the correlation form
  *r* = *t* / √(*t*² + df) for callers who prefer an *r* scale.
- `@emlRunPairedAnalysis` now calls `@emlCohenDz` on the parametric branch
  and `@emlMatchedPairsR` on the nonparametric branch, each inside its own
  `if`.
- The paired-t report block prints Cohen's *d*z and *r* (from *t*). The
  Wilcoxon block already printed matched-pairs *r* under its own
  **Nonparametric Effect Size** heading and is unchanged — it was correct
  all along.
- The CSV row for a parametric run carries `Cohen's dz` in `effect_type`
  instead of `matched-pairs r`.

**Why the substitution was invisible.** Both statistics land on a 0–1
correlation-like scale and both read "large effect". They differ in what
they use: *r* from *t* uses the magnitudes of the change, matched-pairs *r*
uses only the ranks. On `demo_paired`, nineteen of twenty subjects moved the
same direction, so the rank statistic sits near ceiling at 0.971 while the
magnitude statistic is 0.871. Consistent direction with variable size is
exactly the case that separates them, and it is common in pre/post voice
data.

**Verified by drive.** Parametric run:

```
  ── Effect Size ─────────────────────────────
  Cohen's dz          1.728
  r (from t)          0.871
  Magnitude           large effect
```

Both-tests run adds, under its own heading:

```
  ── Nonparametric Effect Size ───────────────
  Matched-pairs r     0.971
```

Every value matches R: *d*z 1.728, *r* from *t* 0.871, matched-pairs *r*
0.971.

**`validate/v06` has been rewritten.** It was written to pass while the
defect existed and fail once fixed, which is what happened. It now asserts
the corrected behaviour and carries a regression guard: the two effect sizes
must remain numerically distinct, so a future change that routes the rank
statistic back under the parametric heading fails the suite.

### D93 — CLARITY (high) — error recovery in the analysis wrappers discards the user's input, and the dialog does not say where its buttons go

Raised by the author from ordinary use: paths that error for good reasons —
choosing *Compare two groups* on a table whose group column has three —
appear to offer no way back, only a quit.

**Driven to see what actually happens.** *Compare two groups* on
`demo_3groups`, `Group column = voice_type` (three levels), with `Test` set
deliberately to **Mann-Whitney U** rather than the default:

1. `Run` produces a correct and genuinely helpful message —
   *"Group column "voice_type" has 3 groups. Use Compare k Groups for more
   than 2."*
2. It is delivered by Praat's generic `pauseScript:`, so the window is
   titled **"Pause: stop or continue"** and the buttons are **Stop** and
   **Continue**. Neither label says what it will do. *Continue* sounds like
   "run anyway"; it actually means "return to the form".
3. Choosing *Continue* **does** return to the form — the wrapper is not a
   dead end, and the author's reading of it as quit-only is a fair reading of
   those two buttons.
4. **The form returns with every field reset.** `Test` is back to
   `Welch t-test`. The deliberate choice is gone.

Losing the input is the worse half. A user who set four fields, mis-set one,
and pressed Run has to set all four again — and nothing warned them that
would happen.

**The reset is systematic, not incidental.** In nine of the ten wrappers with
a retry loop, the optionmenu defaults are computed **before** `repeat`, so
each pass rebuilds the form from the original column guesses rather than from
what the user chose:

| Wrapper | `repeat` at | defaults computed at |
|---|---|---|
| `eml-compare-groups.praat` | 45 | 36 |
| `eml-compare-k-groups.praat` | 33 | 26 |
| `eml-compare-paired.praat` | 34 | 24 |
| `eml-correlate.praat` | 43 | 33 |
| `eml-regress.praat` | 36 | 26 |
| `eml-pairwise.praat` | 34 | 27 |
| `eml-compare-kw.praat` | 32 | 25 |
| `eml-compare-twoway.praat` | 41 | 28 |
| `eml-check-normality.praat` | 62 | 35 |

`eml-describe-table.praat` has no retry loop at all.

**No entry form in any of the twelve analysis wrappers offers a Back
button.** Every one ends `endPause: "Quit", "Run", 2, 0`.

**The plugin already knows how to do this.** Two of its components get it
right:

- `eml-wizard.praat` — every page: `"Quit", "Back", "Continue"` or
  `"Quit", "Back", "Run"`. Thirteen pages, Back on all of them.
- `eml-edit-table.praat` — every sub-dialog: `"Go Back", <action>`. Add
  Column, Insert Row, Delete Row, Rename Column, Find/Replace, Table
  Structure, all of them.

So the convention exists and is applied consistently in the two places a
user is most likely to be navigating, and not at all in the twelve places a
user is most likely to hit a validation error.

**What a fix requires, and it is two separate things:**

1. **Persist the user's choices across a retry.** Hold each field in a
   variable seeded from the guess on first entry and from the previous
   answer thereafter, and use those as the optionmenu defaults. Without this,
   a Back button returns you to a blank slate and is barely worth having.
2. **Replace the generic `pauseScript:` with a real dialog** whose buttons
   name their destination — *Change settings* / *Quit* rather than
   *Continue* / *Stop*. `pauseScript:` cannot be relabelled; it needs a
   `beginPause`/`endPause` pair.

Evidence: `evidence/shots/d93_generic_stop_or_continue.png`,
`d93_form_returns_with_choices_lost.png`.


### D93 — CORRECTED and widened — the wrapper entry forms are leaves with no way up

The first statement of D93 (above) described the error dialog's button labels
and the loss of field values on retry. Both are real, and neither is the
defect the author raised. Corrected here on his reading, which is the right
one.

**The menu selection is the navigation.** By the time the *Compare Two
Groups* form is on screen the user has already committed to that test — they
are one level down. So when the analysis fails with *"Group column
'voice_type' has 3 groups. Use Compare k Groups for more than 2"*, returning
to that form does not help: **Compare k Groups is not reachable from it.**
The only exit is `Quit`, which drops the user out to the Objects window to
re-navigate `New > EML Tools >` from the start.

The form is a leaf. Its two buttons are "run this particular test" and "leave
entirely". There is no third option, and the error has just told the user
that the first one is impossible.

That is why the previous framing was wrong. A back button on the *error*
popup returns you to a form you already cannot use. **The button belongs on
the wrapper's own entry form**, and it has to go up a level, not back a step.

**Why "up" needs building rather than wiring.** Each of the twelve wrappers
is registered as its own `Add menu command` in `setup.praat` and entered
directly from the submenu. The level above any wrapper form is therefore the
Praat menu itself, and a running script cannot re-open a Praat menu. So the
destination has to be something the plugin provides.

**The enabling fact:** `runScript:` from one plugin script to another already
works and is already used — `scripts/eml-edit-table-launch.praat:37` and
`eml-edit-table-editor.praat:24` both hand off that way. A wrapper can
therefore transfer control to another wrapper.

**Proposed shape, for author ruling before any code is written:**

1. **A tool chooser** — a small new script presenting the same list the
   `EML Tools` submenu presents, which `runScript:`s the selection. This is
   the missing level: it is what the submenu *is*, expressed as a dialog a
   script can return to.
2. **Every wrapper entry form gains `Back`**, which calls the chooser. Twelve
   one-line changes once the chooser exists. This satisfies the general rule
   — there is always a way back — regardless of whether an error occurred.
3. **Errors that name a remedy pre-select it.** The three-groups message
   already says "use Compare k Groups"; arriving at the chooser with that
   entry pre-selected turns a dead end into one keystroke.

The alternative destination considered and not recommended: sending `Back` to
the Stats Wizard. The wizard's first page is a research-goal chooser and is
superficially "up", but a user who picked a specific test from the menu did
not come from the wizard, so it is a lateral move into a different interaction
model rather than a step back.

**Still true from the first statement, and still worth fixing alongside:** the
retry loop rebuilds the form from the original column guesses rather than the
user's answers, so any return to the form — however it is reached — discards
what they set. A `Back` button that leads to a blank form is worth much less
than one that does not.


---

### D93 — RESOLVED — author ruling of 5 August 2026, implemented and driven

The corrected statement above ended with a proposed tool chooser awaiting
author ruling. **The ruling rejects that shape**, and is right to: it would
have restructured how a test is chosen from the menu in order to fix an error
message.

> "So if somebody comes from the wizard path, what makes the most sense is to
> go back to the wizard chooser. I do not wanna change the structure of how
> measurements are chosen from the new menu. in that case, when somebody gets
> there from the menu path, the only option may be for the window that pops up
> to give a little bit more information. basically, that the user needs to
> manually go back to the new menu and choose the correct test."

Two entry paths, two different fixes, no new navigation layer.

#### What the drive found that the source reading had not

Driving the wizard turned up a defect worse than the one D93 was filed for.
**Every analysis error in the Stats Wizard called `exitScript:`** — 13 sites.
An error four pages in did not return the user anywhere; it destroyed the
whole wizard, including every answer given on the way. Six further sites
ended the wizard on a *correctable* mistake ("Please select two different
columns"). None of this is visible from the wrapper scripts, which is where
D93 was filed from.

So the wizard, which owns a complete `goto`/`label` back-chain and was the
one path with somewhere to go, was the path that used it least.

#### What was changed

**One error surface, `@emlErrorDialog`** (`stats/eml-output.praat`), with a
`.mode$` of `"wizard"` or `"menu"`, because the two paths can honestly offer
different things. It takes the orchestrator's message, word-wraps it
(`@emlWrapText` — `comment:` does not wrap and these strings run long), and
adds guidance. It never calls `exitScript:` itself; it returns `.back` and
the caller decides, because only the caller knows what needs tearing down.

**Menu path — 14 sites across 9 wrappers.** The dialog now states that the
test cannot run, and when another EML tool would work it names that tool and
gives the literal menu route to it, saying plainly that a running script
cannot open a Praat menu. Buttons are `Quit` and `Back`, and `Quit` now
actually quits — the old `pauseScript:` had a single `Continue` that dropped
the user back onto the form regardless.

**Wizard path — 19 sites.** All 13 `exitScript:` calls on analysis error, and
6 on correctable selection mistakes, now present the same dialog and `goto`
the branch's column-selection page. The wizard survives; every earlier answer
is intact; the existing `Back` chain reaches the goal chooser from there.
The three bare `pauseScript:` guards that were *already* returning correctly
were converted too, for one surface rather than three.

**Remedies are structural, not parsed out of message text.** Every
orchestrator now carries a `.remedy$` alongside `.error$`, empty by default.
Only one case currently sets it — three-or-more groups given to the two-group
test — and it names *both* the ANOVA and the Kruskal-Wallis entries, since
naming one would quietly steer the parametric/nonparametric choice. Errors
that no other tool would fix (a data problem, a wrong column) deliberately
leave it empty and say "adjust your selections and run again" instead.
Telling someone to re-navigate the menu when a column change would do is
worse than saying nothing.

**Form state now survives the return trip.** This was the other half of the
first D93 statement and it is what makes `Back` worth having. Nine of ten
wrappers seeded their menus from `@emlGuessColumnRoles` on every iteration of
the `repeat` loop, so any return rebuilt the form from the original guess.
New `@emlColumnIndex` / `@emlKeepChoice` (`stats/eml-extract.praat`) map the
chosen column *name* back to its index; non-column menus (test, adjustment,
group order, Tukey) carry seed variables of their own. A column renamed
between runs degrades to the guess rather than to index 0, which Praat
rejects.

#### Driven, not reasoned

Praat 6.6.30, Xvfb :99, real clicks.

| Path | Observed |
|---|---|
| Menu, `Compare two groups` on `demo_3groups` | Dialog names both k-group entries and the menu route. `evidence/shots/d93_menu_error_dialog.png` |
| Menu, `Back` from that dialog | Form returns with `vibrato_rate_Hz` / `Both parametric and nonparametric` / `Alphabetical` — all three deliberately changed before Run. `d93_menu_form_state_kept.png` |
| Menu, `Quit` from that dialog | Script ends; no live pause window remains |
| Wizard, two-group branch on a 3-group column | Guard dialog names the Design-page choice that fits. `d93_wizard_guard_dialog.png` |
| Wizard, analysis error (red-path R4) | *Each group needs at least 2 observations. Group "Soprano": n=6, group "Alto": n=1* — wizard alive. `d93_wizard_analysis_error_R4.png` |
| Wizard, `Back` from that error | Returns to *Two groups — Select columns*, wizard intact. `d93_wizard_back_returns.png` |

The R4 row is also the **first red-path case driven through the plugin**.
`validate/redpath/r4_singleton_group.csv` was loaded unchanged; the required
behaviour was "refuse, naming the group and its n", and that is what the
plugin does. `v07`'s R4 `PENDING DRIVE` marker is replaced with the observed
assertion; six remain.

#### Not claimed

`Linear mixed model` received the same mechanical change for a single error
surface across the plugin, and was **not driven** — it remains out of scope
by author ruling. The two-way, correlation, regression, Kruskal-Wallis and
pairwise wrappers were parse-checked and their code paths are identical to
the two that were driven, but they were not individually exercised.


---

## Orchestrator validation drive — 5 August 2026

The author challenged the phrase "eight untested analysis wrappers", and was
right to. It was wrong, and the correction matters more than the wording.

**The statistics are externally validated.** `stats/eml-inferential.praat` is
28 of 28 procedures under an external R or scipy oracle at 442 passing
checks; descriptives are asserted against closed-form analytic values. That
was measured properly in `audit/reports/CORRECTION_coverage_2026-08-04.md`.

What had never been tested is `stats/eml-analysis.praat` — fourteen
orchestrators that do no arithmetic, but read the Table, choose which
already-validated primitive to call from the form's menus, hand it arguments,
and assemble the printed report. Zero had a direct oracle. Seven were touched
by `test-workflow-verification.praat`, which checks that report procedures
emit the expected *markers* — headings, spacing — not that the right value
lands under the right one.

That layer is where D15 lived: two individually-correct effect sizes, one
printed under the other's heading. A primitive-level suite cannot reach it.

Eight orchestrators were driven through their real GUI and given an R script
each: `validate/v08`–`v15`, 237 new checks, all passing. With the four
already covered by v01–v06 that is twelve of fourteen; the remaining two are
LMM (tabled) and reliability (a stub).

The scripts do not only re-check magnitudes. Each asserts the properties a
wrapper can break while every number stays individually right: that a
post-hoc matrix is antisymmetric, that a *t* equals its own estimate over its
own SE, that the sign of a rank effect size tracks the mean difference, that
partial eta-squared is SS/(SS+SS_error) and not SS/SS_total, that reversing
predictor and response changes the slope but not R².

### D94 — `exitScript` without a colon; Quit raises a Praat error

Found by clicking Quit on *Describe Table column*. Praat parses a bare
`exitScript` as a variable reference and raises

    Unknown variable: « exitScript »
    This happened after you clicked "Quit" in the pause form.

Three sites: `eml-describe-table.praat:89` and `eml-batch-process.praat:112`
and `:183`. The script does terminate, so the effect is an alarming error
dialog on a normal Quit rather than a dead end. **FIXED** — all three now
`exitScript: ""`. No other bare command usages exist in the plugin.

### D95 — three shape-threshold sites disagreed with each other

The normality report printed `Kurtosis` with no `(excess)` — the site D4's
relabelling missed — and judged it against hard-coded 1 and 3, while
`@emlRunNormalityAnalysis`'s own recommendation gate beside it read
`emlSkewThreshold` and `emlKurtosisThreshold`, both 1. With G2 between 1 and
3 the same report would print "Kurtosis within typical limits" on one line
and recommend a nonparametric test on the next. The wizard's
`@wizardNormCheck` had a third copy, also 1 and 3, and printed a sentence
claiming 3 while enforcing 1.

**FIXED** — `eml-annotation-procedures.praat`, `eml-wizard.praat` and
`eml-output.praat` now read the constants at every site, and the printed
sentence interpolates them rather than restating a literal. Re-driven after
the fix; `validate/v15` asserts the verdicts against the constants, so
changing the house convention and re-running is a coherent operation.

### The red path, driven

Six of seven cases loaded into Praat unchanged and taken through a wrapper.
Two behave as required (R3 refuses on zero variance and names it; R4 refuses
and names the group and its n). Four new findings follow. Full verdict table
in `validate/REGISTRY.md`.

### D96 — "undefined" is one bucket holding three different conditions

**Corrected the same day, on the author's challenge.** This was first written
as "a non-numeric cell silently costs a row, and nothing says so". That is
false. I read the capture from its tail and missed the header, which says:

    Column              SPL soft
    N (valid)           4
    N (undefined)       1

The plugin reports the count, and follows the complete-case convention set on
21 July (`plugin/FIX_NOTES.md`, audit item C1/C2): analyse the rows that
parse, state how many were excluded. Nothing is silent, and the severity
claim that rested on silence is withdrawn.

**The real defect is narrower and is the one the author named.** `Get value:`
returns `undefined` for three conditions that a user needs to tell apart:

1. **an empty cell** — missing data; the C1/C2 convention is correct for it;
2. **an unparseable string** — a type error, meaning this column is not a
   measure at all, which is the D82 family arriving by a different route;
3. **a decimal comma** — `1,5` written by anyone working in a European
   locale. This is *recoverable data being discarded*. The user has the
   number; the plugin throws it away and calls the row missing.

Nothing downstream can distinguish them, because the distinction is destroyed
at `Get value:`. The report names neither the row nor the offending value, so
a user cannot tell a genuine gap in their data from a locale mismatch.

**The convention this needs to satisfy is already written down** and is not a
new decision: complete-case, with the exclusion stated. What is missing is
the classification underneath it, applied identically to rows and to columns.
That requires a shared parse helper at the extraction layer — there are ten
entry points in `stats/eml-extract.praat` — which classifies each cell as
numeric, empty, locale-decimal, or non-numeric, and a report line that names
the column and the count per class. Severity: **medium**, not high.

### D97 — RM-ANOVA omnibus does not check for a zero error term

R1's four complete cases are exactly linear: every subject has
medium = soft + 10 and loud = soft + 20, so the subject × condition residual
is identically zero and the error SS is 0. Verified in R: `max |residual|`
is 0 exactly. The plugin printed

    F(2, 6) = 21110623253299200.0000, p = 0.000000000000000000000000000000000000000000000003

The value is a floating-point artefact of dividing by a zero error term. The
same run's **post-hoc caught the identical condition and refused** on all
three pairs, naming it: "All differences are identical (zero variance)". So
the check exists in the module and the omnibus does not call it.

The 48-place p-value is D85 (repeated-measures p-values bypassing the
plugin's own `< .001` convention), confirmed still present.

### D98 — a two-subject design produces a full result with no caveat

R2, n = 2 subjects and k = 3. df error = 2. The plugin computed F(2, 2) =
441.0000, p = 0.0023, GG-corrected p = 0.0303 and three post-hoc p-values,
with no comment of any kind. It does print "Subjects (complete cases) n = 2",
which is honest as far as it goes, but nothing marks the result as
uninterpretable.

The Greenhouse-Geisser epsilon is the tell and the plugin has it in hand as
it prints: 0.5000 is exactly the lower bound 1/(k−1), which is forced
whenever n = 2. An epsilon pinned to its floor means the design has no
information left to correct.

### D99 — refusal names one group, not the diagnosis

R5, a grouping column unique per row. The plugin refuses before computing
anything, which is the half that matters. But it names only the first
offending group:

    emlOneWayAnova: group "G01" has fewer than 2 observations

Six singleton groups therefore take six attempts to diagnose. The statement
that would end it in one — six groups for six rows, so this column is an
identifier and not a grouping — is never made, though `@emlCountGroups` has
both numbers. The message also leaks the internal procedure name into
user-facing text.

### Regression introduced and fixed in the same session

The D93 state-preservation patch put `selSubjectIdx = guessSubjectIdx + 1`
before `guessSubjectIdx` was assigned, which was inside the loop. *Compare
paired/repeated* raised `Unknown variable: guessSubjectIdx` and would not
open at all. Found by driving, not by the parse check — which passed, because
with no Table selected the script exits at `@emlWrapperInit` before reaching
the line. **FIXED** by hoisting the assignment; a static check across all
eight patched wrappers confirms no other seed references a later-assigned
variable.

---

## 6 August 2026 — D96 to D99 fixed, and two defects the fixes exposed

Every fix below was driven through the GUI afterwards, not merely written.
Captures are in `evidence/info/rp_r1_rmanova_info.txt`,
`rp_r2_rmanova_info.txt`, `rp_r6_parse_conditions_info.txt`; the two refusals
are modal dialogs rather than Info-window text, so they are evidenced by
`evidence/shots/d97_r1_zero_error_term_refused.png` and
`d99_r5_refusal_names_diagnosis.png`. `validate/v07` now asserts the fixed
behaviour from those captures instead of recording the defects.

### D99 — FIXED. The refusal states the diagnosis

`@emlOneWayAnova` now sizes every group before it raises, so it can say what
is actually wrong instead of naming the first offender:

    Group column "singer_id" has 6 groups for 6 rows - one per row.
    This is an identifier column, not a grouping column.

Where the shape is not one-per-row it names the offenders together, capped at
five with an "and N more" tail. The `emlOneWayAnova:` prefix is gone from
every user-facing string in that procedure, along with `emlOneWayAnova
(Tukey):`.

### D97 — FIXED. The omnibus refuses a zero error term

`@emlRMAnovaTest` gains `.error$` and refuses before dividing. **The floor
has to be relative.** An exactly-linear design leaves `ssErr` at about 1e-16
of `ssTot`, not at 0, so a test for equality with zero does not fire — which
is precisely why the old code produced a finite-looking
`F(2, 6) = 21110623253299200.0000` rather than an obvious `undefined`. The
test is `ssErr <= 1e-10 * ssTot`, plus a separate branch for `ssTot = 0`.

The two skipped checks in `dev/tests/phase2/test-repeated-measures.praat`
(RM_D and RM_F, "not asserted until the author rules") are now assertions:
the suite went from 96 checks with 6 skips to 102 with 4.

### D98 — FIXED. A design with no information left says so

Computed and printed, with a caution directly under the line it qualifies:

    Greenhouse-Geisser epsilon = 0.5000, GG-corrected p = 0.0602
    Caution: n = 2 subjects. Greenhouse-Geisser epsilon is forced to its
    lower bound 0.5000 for any data at this n, so the sphericity
    correction carries no information. ...

Placement is asserted in v07, not left to chance: a caution printed at the
foot of the report reads as being about the post-hoc table above it.

A second branch fires whenever epsilon lands on the bound at any n, which is
the maximum possible departure from sphericity.

### D96 — FIXED. One classifier, used by every extraction path

`@eml_classifyCell` sorts a cell into five kinds — numeric, empty, decimal
comma, unreadable text, and coerced-to-something-else — and `@emlAuditColumn`
turns the counts into sentences that name the row and the value. Driven
output:

    N (valid)           3
    N (excluded)        3
    1 cell(s) use a comma where a decimal point belongs (row 4: 73,4). ...
    1 cell(s) are not numeric in any locale (row 3: n/a). This is a type
    error, not missing data. 1 cell(s) are empty (row 5 first). ...

**This changed a result, and that was the point.** `Get value:` returns 1 for
`"1,5"`, so before this the comma cell was not dropped — it entered the mean
as a different number, with nothing in the report to say so. It is now
excluded and named. The value is not guessed at: `1,234` is 1.234 to a
European reader and 1234 to an American one, and the plugin has no basis to
choose. Two kinds found while building it and worth naming separately:

- **`30%` is strictly numeric to Praat** and returns 0.3. The strict verdict
  is true and useless there, so a percent sign is now checked before it.
- **`.5` is not numeric to Praat at all.** Calling that "not numeric in any
  locale" would be false, so it is its own kind with its own one-character
  remedy.

Every extraction entry point reads through `@eml_readCell`: the column-wise
readers and the row-wise ones (paired columns, the condition matrix). That
was the author's requirement — rows and columns handled identically — and it
was not true before. A per-column fast path skips the classifier entirely
when the column numericises strictly and holds no empty cell.

### D100 — a wrapper called a procedure it does not include

`scripts/eml-describe-table.praat` held a second copy of the descriptive
report body, line for line identical to `@emlReportDescriptiveAnalysis`. The
D96 work needed the same change in both, so the duplicate was replaced with a
call. The wrapper does not include `stats/eml-analysis.praat`, where that
procedure lived.

**Praat resolves a procedure name when it is CALLED, not when the file is
parsed.** The parse check passed. The menu item opened normally. The failure
came the instant Run was clicked:

    Procedure "emlReportDescriptiveAnalysis" not found.
    Script line 9434 not performed or completed

Fixed by moving the procedure to `stats/eml-output.praat`, which the wrapper
does include and which is where a reporting procedure belongs.

`harness/check_includes.py` was written in response: it resolves each entry
script's include closure and reports any `@call` that nothing in that closure
defines. It runs in under a second with no display.

### D101 — nine wrappers carried four unresolvable calls each

Found immediately by that checker. `@emlRunLMMAnalysis` lived in
`stats/eml-analysis.praat`, which every wrapper includes; the engine it calls
(`@emlLMM`, `@emlLMMSummary`, `@emlJohnsonR2`, `@emlWaldCI`) is in
`stats/eml-lmm.praat`, which no wrapper includes. Same latency as D100 and
the same invisibility to a parse check.

Fixed by moving the orchestrator to the foot of `stats/eml-lmm.praat`, beside
its engine. Including that module now gets both, including neither gets
neither, and there is no third state. The checker is clean.

---

## Open questions for the author

1. **`Development: Claude (Anthropic)` appears in 35 file headers.** The
   standing instruction is that Ian Howell is the only person or entity ever
   cited as author. These lines predate this session and were not touched.
   Removing them is a 35-file edit and is the author's call, not mine.

2. ~~**LMM is off the menu but still reachable through the Stats Wizard.**~~
   **RULED 6 August: disconnect it from end users, including the wizard, and
   delete nothing.** Done. The wizard's "Predict — model type" page was the
   last user-reachable route into the mixed-model formula page; with mixed
   models gone it had one live choice left, so goal 4 now goes straight to
   the regression columns. The page is kept verbatim in a comment block with
   restore instructions.

   The formula page itself is left live but unreachable rather than
   commented out. Two reasons, and the second is the one that matters: a
   fifty-line block reinstated by uncommenting is a fresh chance to
   introduce a bug, and while the code still parses,
   `harness/check_includes.py` keeps verifying that its four calls into
   `stats/eml-lmm.praat` resolve. That is the check which caught D101, and
   it only works on code that is still there to check. The cost is that
   `eml-lmm.praat` is still parsed on every wizard launch — dead weight, not
   a user surface. If that load time is worth reclaiming, the include and
   the block come out **together**; one without the other is precisely the
   mistake D101 was.

   The regression path was re-driven afterwards and every printed value
   still matches R: slope 2.1020, intercept 56.2347, R 0.9966, F(1,6)
   871.9726, both coefficient SEs and t statistics to the printed digit.

3. **Friedman on all-tied data.** `dev/tests/phase2/test-repeated-measures.praat`
   still skips RM_D's chi-square and p: the library returns p = 1 where scipy
   returns nan.

   Reading the code settles where the difference comes from. The tie
   correction is `c = 1 - sum(t^3 - t) / (n(k^3 - k))`. When every value
   ties within every subject, `t = k` in every row, the numerator equals the
   denominator, and `c` is exactly 0. scipy divides by it and returns nan;
   `@emlFriedmanTest` has a guard — `if .c <= 0 then .c = 1` — which
   substitutes 1 and yields chi-square 0, p = 1.

   **This is not the D97 situation.** There the printed F was arithmetic
   noise from a division by zero: a garbage number wearing four decimal
   places. Here chi-square = 0 is arguably the correct statistic — with all
   ranks tied there genuinely is no rank difference to detect. Refusing
   outright looks too strong. The D98 treatment fits better: compute it,
   print it, and say plainly that an input with no variance has nothing in
   it to test, so that p = 1 is not read as evidence of no effect.

   Still the author's call, and the guard at `.c <= 0` should be part of the
   decision — it is currently silent about having fired.

4. **`Kurtosis (excess) --undefined--`.** Excess kurtosis needs n >= 4, so on
   the three-valid-row R6 table the descriptive report prints the literal
   `--undefined--`. Correct, and ugly. A short "n < 4" note would read better.
