# Parse-parity census — every cell→number conversion in `plugin_EML_StatsGraphs/`

## Headline count

| | |
|---|---|
| Conversion sites walked (all shapes, whole tree) | **123** — 28 numeric `Get value:`, 95 `number()` on a variable |
| Of those, reading a **user data cell** (the real population) | **39** |
| — canonical / strict (through `@eml_classifyCell`) | **4** |
| — lenient *by design*, as a hazard counter that discloses | **5** |
| — benign heuristic or deliberate repair | **2** |
| — **can publish a silent wrong value** | **28** |
| — of those 28, reachable from a registered menu today | **22** |

The walk is non-vacuous: 28 members found, each asserted individually below. Separately, **the canonical strict path itself has 2 defects** (§4) — so this is not only a "make the stragglers match the canon" job.

`@emlRequireNumericColumn` has **16 call sites**; 15 pass `.strict = 0` and 1 passes `.strict = 1`. **That divergence is deliberate, documented, and correct** — it is not where the two doors part company.

---

## 1. The gate is not the bug

All 16 sites, with the door each serves:

**`.strict = 0` (15)** — `eml-analysis.praat`: `:171` TwoGroup, `:555` Anova, `:970` KW, `:1295` Pairwise, `:2513`/`:2518` Paired, `:2752`/`:2757` Correlation, `:2921` Descriptive, `:3047`/`:3051` Regression, `:3571` Normality, `:3851` ConditionMatrix. `eml-inferential.praat`: `:4256` PairwiseT, `:4482` PairwiseWilcoxon.

**`.strict = 1` (1)** — `eml-inferential.praat:3250`, `@emlTwoWayAnova`.

The single strict site carries its own justification in-source (`:4250-4256`): it is the only test that feeds the column to Praat's whole-column numericiser, where one bad cell replaces *every* value with an alphabetical rank, so there is no partial answer to give. Every other door reads row-wise and applies the complete-case convention. **This is a correct, deliberate split. Leave it alone.**

I confirmed the gate is not the divergence by driving it: on the fixture, `@emlRequireNumericColumn ... 0` returns `error$ = ""` — the door opens — and `@emlAuditColumn` *already knows everything*:

```
nRows=6 nValid=3 nEmpty=1 nLocale=1 nUnreadable=1
note=[1 cell(s) use a comma where a decimal point belongs (row 4: 73,4).
      Praat reads these as a different number, so they are excluded rather
      than guessed at. ...]
```

The disclosure text exists and is correct. **The defect is that 28 sites never ask for it** — they read the cell again, leniently, downstream of a gate that already opened.

---

## 2. The 28 silent-wrong-value sites

The mechanism is one fact, measured (§3): **`number()` and Table `Get value:` are the same parser.** Identical on all 42 shapes. So both spellings are equally dangerous, and "it uses `Get value:` not `number()`" is not a defence.

### Live and fully exposed — 21

| # | File : line | Door | Malformed cell → |
|---|---|---|---|
| 1 | `stats/eml-analysis.praat:3581, :3597` | `@emlRunNormalityAnalysis` | **silent wrong value** (the reported defect) |
| 2 | `stats/eml-analysis.praat:3060, :3061, :3079, :3080` | `@emlRunRegressionAnalysis` | **silent wrong value** |
| 3 | `stats/eml-analysis.praat:4884` | ANOVA augment (fitted/residual per row) | **silent wrong value** |
| 4 | `stats/eml-inferential.praat:5969, :5970, :5991, :5992, :6021, :6022` | `@emlOLSInfluence` | **silent wrong value** |
| 5 | `scripts/eml-compare-paired.praat:247, :248` | Paired → long reshape, **then drawn** | **silent wrong value** |
| 6 | `scripts/eml-wizard.praat:3040, :3041` | Wizard paired reshape, **then drawn** | **silent wrong value** |
| 7 | `graphs/eml-graph-procedures.praat:8037, :8039` | Time-series melt | **silent wrong value** |
| 8 | `graphs/eml-graph-procedures.praat:8219, :8229` | Long→wide reshape | **silent wrong value** |

### Live, partially protected — 1

`stats/eml-inferential.praat:3416` (`@emlTwoWayAnova`). `.strict = 1` refuses the comma before this line is reached — but **not hex** (§4b), which passes strict and arrives here as a wrong number.

### Not reachable today — 6

`stats/eml-lmm.praat:631, :828, :907, :1146, :1437, :3842`. **Zero calls to any gate or canonical reader in the entire 4,443-line file.** It is the largest single cluster and the least gated. It is also deliberately withdrawn — `setup.praat:80` "Mixed models — NOT REGISTERED", and `:429` keeps it out of the barrel — so it is not a live door. **The finding is a tripwire: this must not be wired up before it is gated.**

### Two confirmations, driven against real repo procedures

**The reported defect, reproduced exactly** on `evidence/csv/rp_r6_parse_conditions_input.csv`:

```
@emlExtractColumn  (Descriptive's reader)  n=3  mean=72.26666666666667
bare Get value:    (Normality, :3581)      n=4  mean=72.45
```

**A second door, independently confirmed.** Fixture `y = 10.5, 11.5, [12,5], 13.5`:

```
gate error$=[]                          <- door opens
audit note=[... row 3: 12,5 ...]        <- the disclosure exists, unused
@emlExtractColumn      n=3              <- canonical: row dropped
@emlOLSInfluence       nValid=4  slope=0.95  intercept=9.5
true data (12.5)       nValid=4  slope=1.00  intercept=9.5
```

`@emlOLSInfluence` publishes **slope 0.95 where the truth is 1.0**, `error$` empty, no disclosure. Same failure mode as normality, different door.

### Note on #5–#8 — these defeat work already done

The draw layer already fixed exclusion parity: `@emlDrawColumnIsClean` (`eml-draw-procedures.praat:442-470`) reads cells through `@eml_readCell` precisely so "the figure and the analysis exclude the same rows," with the measured `1,5 → plotted as 1` case in its header.

These four sites **poison an intermediate table before the draw layer ever sees it.** The reshape reads `"73,4"` leniently and writes `Set numeric value: ... 73`. The draw layer then reads a *clean numeric 73* and has nothing left to catch. The parity guard is intact and bypassed.

---

## 3. Measured `number()` behaviour — Praat 6.6.30

Driven, not reasoned. Each shape in its own process so a raise is recorded rather than fatal. `strict` = `@eml_strictNumericColumn`'s sentinel verdict.

| literal | `number()` | `Get value:` | strict verdict |
|---|---|---|---|
| `70.1` | 70.1 | 70.1 | strict |
| **`73,4`** | **73** | **73** | NOT-strict |
| `1,234` | 1 | 1 | NOT-strict |
| `1.234,5` | 1.234 | 1.234 | NOT-strict |
| `· 72.5 ·` (spaces) | 72.5 | 72.5 | strict |
| `→72.5→` (tabs) | 72.5 | 72.5 | strict |
| `72.5abc` | 72.5 | 72.5 | NOT-strict |
| `abc72.5` | undefined | undefined | NOT-strict |
| `72.5 kg` | 72.5 | 72.5 | NOT-strict |
| `2 3` | 2 | 2 | NOT-strict |
| `1/2` | 1 | 1 | NOT-strict |
| `30%` | 0.3 | 0.3 | **strict** (carve-out catches it) |
| `-` / `+` | undefined | undefined | NOT-strict |
| `` (empty) | undefined | undefined | UNREADABLE |
| **`· `(space only)** | undefined | undefined | **RAISES** |
| `n/a` / `NA` | undefined | undefined | NOT-strict |
| `--undefined--` / `?` | undefined | undefined | UNREADABLE |
| `.5` / `-.5` | undefined | undefined | NOT-strict |
| `5.` | 5 | 5 | strict |
| `1e3` / `1E3` | 1000 | 1000 | strict |
| `1e` / `1e+` | undefined | undefined | NOT-strict |
| **`1e999`** | undefined | undefined | **RAISES** |
| `1e-999` | 0 | 0 | strict (silent underflow) |
| **`0x1A`** | **26** | **26** | **strict** |
| `inf` / `nan` / `undefined` | undefined | undefined | NOT-strict |
| `1.2.3` | 1.2 | 1.2 | NOT-strict |
| `TRUE` / `pi` | undefined | undefined | NOT-strict |
| `007` | 7 | 7 | strict |
| `1_000` | 1 | 1 | NOT-strict |
| `(72.5)` | undefined | undefined | NOT-strict |
| `72.5;` | 72.5 | 72.5 | NOT-strict |
| `2+3` | 2 | 2 | NOT-strict |

**Three results that change the job:**

1. **`number()` ≡ `Get value:`, exactly.** One rule covers both spellings.
2. **`0x1A` → 26 and passes strict.** Widens the census past the comma.
3. **Whitespace-only and `1e999` do not return a value — they raise.**

Leading/trailing whitespace and tabs are handled correctly (trimmed, strict). `30%` is caught only because `@eml_classifyCell` tests `%` *before* strictness (`:1005-1012`) — that carve-out is load-bearing and my measurement confirms why.

---

## 4. Two defects in the canonical strict path itself

Both confirmed by driving the **real** `@emlRequireNumericColumn`, not a replication.

**(a) A whitespace-only cell raises instead of reporting.** Column `70.1 / "·" / 75.5`:

```
Error: Table "eml_numericProbe": the cell in row 2 of column "v" is undefined.
Table "eml_numericProbe": cannot get all numbers in column 1.
« .probe# = Get all numbers in column: .columnName$ »
```

The unreadable scan at `stats/eml-extract.praat:895` tests `""`, `"--undefined--"`, `"?"` — **not whitespace-only**. Execution reaches the un-`nocheck`'d `Get all numbers in column:` at **`stats/eml-extract.praat:910`** and the whole script dies with a raw Praat error. This is exactly the failure the procedure's own header (`:873-887`) says it exists to prevent: *"a probe that is handed a cell it cannot read must report `.unreadable`, not raise, whatever produced the cell."* The rule is written; the scan is one condition short. Same raise for `1e999`.

**(b) Hex passes strict, silently, with no disclosure.** Column `70.1 / 0x1A / 75.5`:

```
@emlRequireNumericColumn  error$=[]
@emlAuditColumn           nValid=3  nCoerced=0  note=[]     <- clean!
@emlExtractColumn         n=3  mean=57.199999999999996
bare Get value:           n=3  mean=57.199999999999996
```

`(70.1 + 26 + 75.5)/3`. **Both doors agree and both are wrong** — so the two-door comparison that caught the comma would never catch this. `@eml_classifyCell`'s contract is *"the cell reads as the number it looks like"*; `0x1A` does not look like 26 to anyone entering measurements. This needs a `%`-style carve-out.

---

## 5. The graphs layer — inverted, and it is the better rule

`@emlCheckNumericColumn` (`graphs/eml-graph-procedures.praat:6412`) uses a **different rule**: a strict-decimal regex (`:6435`) *plus* `number()`, calling a cell "coerced" when `number()` parses what the regex rejects. Driven on the same four cases:

| case | stats layer | graphs layer |
|---|---|---|
| fixture (`n/a`, `73,4`, empty) | 3 rows analysed + disclosure | `isNumeric=0`, column refused |
| **whitespace-only** | **RAISES** | `isNumeric=1`, cell counted blank |
| **`0x1A`** | **strict, accepted, mean 57.2** | `isNumeric=0`, *"first offender row 2 = 0x1A (coerced)"* |
| **`1e999`** | **RAISES** | `isNumeric=0`, flagged non-numeric |

**On all three shapes where the stats strict path fails, the graphs rule is correct.** The draw door is not the lax one here — it is stricter and more robust, and it names the offending cell.

Two real divergences remain, both in the *safe* direction:
- **Whole-column veto.** `.nBad = 0` is required for `isNumeric = 1` (`:6486`), so one `73,4` among 100 good cells makes `@emlDescribeFilterNumericColumns` decline to *offer* the column, where the stats layer analyses 99 rows with disclosure. A refusal, not a wrong number — but the two layers do not apply the same convention.
- **`.maxScanRows = 100000`** (`:6413`) caps the scan; the stats layer scans every row. Disclosed via `[scan capped at ...]`. Note this partly overlaps existing punch item **7.3**.

---

## 6. What I would fix, in order

**First — `stats/eml-extract.praat:895` and `:910`, the whitespace/overflow raise.** Highest severity: a hard crash of the whole script, it is in the canonical path so it is *upstream of every fix below*, and it is a one-condition change to a scan whose own header already states the rule. Trim before the emptiness test, or test the trimmed string.

**Second — the hex carve-out in `@eml_classifyCell`.** Because both doors agree on the wrong answer, no parity check will surface it, and every fix below inherits the hole. Treat `0x` like `%`: classify as kind 4 (coerced) before the strictness test. Consider `1e-999 → 0` at the same time.

**Third — the reported defect, `eml-analysis.praat:3581, :3597`.** Ian's named item. Replace both loops with `@eml_openColumn` + `@eml_readCell` and print `@emlAuditColumn.note$`, exactly as `@emlRunDescriptiveAnalysis` does. Acceptance is already sitting on disk: the fixture must give **n=3, mean 72.2667** through both doors, and the red demonstration is today's 72.45.

**Fourth — the remaining analysis doors: `:3060/:3061/:3079/:3080`, `:4884`, and `@emlOLSInfluence` `:5969`–`:6022`.** Same mechanical substitution. These publish slopes, residuals and Cook's D — numbers a reader cannot sanity-check by eye. Confirmed wrong above (slope 0.95 vs 1.0).

**Fifth — the four reshape sites: `compare-paired:247/:248`, `wizard:3040/:3041`, `graph-procedures:8037/:8039` and `:8219/:8229`.** Lower severity only because the analysis beside the figure is correct once step four lands — but leaving them makes the figure disagree with the analysis again, which is precisely the regression the draw layer's parity work already closed once.

**Sixth — reconcile the two rules.** Decide whether the sentinel probe or the graphs regex is canon. My reading: the graphs regex is the better rule and the sentinel should adopt its carve-outs, *not* the reverse. Do this after 1–5, as one deliberate decision.

**Not now, but do not lose:** `stats/eml-lmm.praat` ×6. Withdrawn from the menu, so no user can reach it. Gate it *when* it is wired up, never after.

### Safe — leave alone (11 sites)

- **Canonical (4):** `eml-extract.praat:1034, :1046, :1111, :1116` — `@eml_readCell` and `@eml_classifyCell`'s recovery arms. `:1111`'s bare `Get value:` is the fast path, correctly guarded by `@eml_openColumn`'s `.clean`.
- **Lenient on purpose (5):** `eml-extract.praat:1053, :1404, :1459, :1482` (`@emlValidateNumericColumn` counts the lenient verdict *against* the strict one — that is its job) and `graph-procedures:6456`.
- **Benign (2):** `eml-extract.praat:2228` (role guess, row 1 only, publishes no value); `scripts/eml-check-data.praat:351` (user-invoked repair, `30% → 30`).
- **Also clear:** all 95 remaining `number()` sites parse *internal* strings — form fields (`eml-graphs-form.praat`), Praat's own Info output (`eml-inferential.praat:2240-2252`), recorder metadata, colour specs, object ids. None touches a user data cell. `eml-record.praat:3952/:4729/:5172` read manufactured recorder tables. `eml-psychometrics`, `eml-categorical`, `eml-optimizer`, `eml-core-descriptive` contain **zero** conversion sites — they take vectors, never tables. And of 14 `Get all numbers in column` occurrences, **13 are comments**; the only live one is the sentinel at `:910`.

---

## 7. Proposed item id

No item in `docs/OPEN_ITEMS.md` or `docs/PUNCH_LIST_DOORS_UNIFICATION_2026-08-25.md` covers this. Per `docs/RULING_FABLE_2026-08-26.md` ("every diff names its item"), I propose a new lane rather than extending Lane 7 — 7.2 and 7.3 already touch `@emlCheckNumericColumn` and may be in flight, and this is 22 sites across 6 files, not a single-door defect:

> **Lane 10 — reader parity (one numeric reader)**
>
> - **10.1 The strict path's own two holes.** `eml-extract.praat:895/:910` must report `.unreadable` for a whitespace-only or overflowing cell instead of raising; `@eml_classifyCell` must classify `0x…` as kind 4. Acceptance: a column with `" "`, one with `1e999`, one with `0x1A` each return a verdict, and the hex column discloses. Red demo: today's raw Praat error, and today's `mean=57.2` with an empty note.
> - **10.2 The normality door.** `eml-analysis.praat:3581/:3597` read through `@eml_openColumn`/`@eml_readCell` and print `@emlAuditColumn.note$`. Acceptance: `rp_r6_parse_conditions_input.csv` gives n=3, mean 72.2667 through both doors. Red demo: today's n=4, mean 72.45.
> - **10.3 The remaining analysis doors.** Regression (`:3060/:3061/:3079/:3080`), ANOVA augment (`:4884`), `@emlOLSInfluence` (`inferential:5969`–`:6022`). Acceptance: the `12,5` fixture yields slope 1.0 with disclosure, or a refusal — never 0.95 in silence.
> - **10.4 The four reshape sites.** `compare-paired:247/:248`, `wizard:3040/:3041`, `graph-procedures:8037/:8039` and `:8219/:8229` read through `@eml_readCell` before writing the intermediate table. Acceptance: extends the existing `harness/disclosure/probe_exclusion_parity.praat` — figure and analysis exclude the same rows *through a reshape*.
> - **10.5 One rule, two layers.** Reconcile `@eml_strictNumericColumn` with `@emlCheckNumericColumn`'s regex; a text check asserts the two agree on a shared shape table, in the `v105` style the house rules name for canon-plus-check.
>
> Tripwire (no work now): `stats/eml-lmm.praat` has zero gates at `:631, :828, :907, :1146, :1437, :3842`. Gate before the menu entry is ever restored.

The measured shape table in §3 is the natural fixture for 10.1 and 10.5, and every acceptance above has its red demonstration available today.

---

**Files of record:** `/home/claude/repo/plugin_EML_StatsGraphs/stats/eml-extract.praat`, `/home/claude/repo/plugin_EML_StatsGraphs/stats/eml-analysis.praat`, `/home/claude/repo/plugin_EML_StatsGraphs/stats/eml-inferential.praat`, `/home/claude/repo/plugin_EML_StatsGraphs/stats/eml-lmm.praat`, `/home/claude/repo/plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat`, `/home/claude/repo/plugin_EML_StatsGraphs/scripts/eml-compare-paired.praat`, `/home/claude/repo/plugin_EML_StatsGraphs/scripts/eml-wizard.praat`.

**Probes used (scratchpad, outside the repo — nothing in the tree was touched):** `/tmp/claude-0/-home-claude/93f3de1f-e6c9-5f61-b1bd-143273ac0781/scratchpad/{shapes.txt,strictone.praat,realdoor.praat,graphdoor.praat,regdoor.praat}`. No file in `/home/claude/repo` was edited, staged, or committed.",
  "workflowProgress": [
    {
      "type": "workflow_phase",
      "index": 1,
      "title": "Census"
    },
    {
      "type": "workflow_agent",
      "index": 1,
      "label": "opus - census:comma-parse",
      "phaseIndex": 1,
      "phaseTitle": "Census",
      "agentId": "a77ddcadf18e60f86",
      "model": "claude-opus-5",
      "state": "done",
      "startedAt": 1787767551633,
      "queuedAt": 1787767550224,
      "attempt": 1,
      "lastToolName": "Bash",
      "lastToolSummary": "sed -n '164,240p' docs/PUNCH_LIST_DOORS_UNIFICATION_2026-08…",
      "promptPreview": "Work in /home/claude/repo. Read CLAUDE.md first; it is binding.

READ-ONLY. DO NOT EDIT ANY FILE. Another agent is building in the plugin tree
right now and an edit from you would collide with it. You are producing a
census, not a fix.

## The defect that started this

evidence/csv/rp_r6_parse_conditions_input.csv holds SPL_soft with six rows:
70.1, 71.2, n/a, "73,4", an empty cell, 75.5. The "73,…",
      "lastProgressAt": 1787768130910,
      "tokens": 127716,
      "toolCalls": 48,
      "durationMs": 579275,
      "resultPreview": "Census complete. Returning findings.

---

# Parse-parity census — every cell→number conversion in `plugin_EML_StatsGraphs/`

## Headline count

| | |
|---|---|
| Conversion sites walked (all shapes, whole tree) | **123** — 28 numeric `Get value:`, 95 `number()` on a variable |
| Of those, reading a **user data cell** (the real population) | **39** |
| — canonical / strict (through `@eml_classifyC…"
    }
  ],
  "totalTokens": 127716,
  "totalToolCalls": 48
}