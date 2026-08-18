> **Historical record (2026-08-14).** Current finding status lives in `audit/FINDINGS_MACHINE.json`.

# EML Praat Tools — End-to-End Stress-Test Audit & Usability Report

**Session:** Friday 14 August 2026, 5:30 PM – 11:00 PM EDT · **report-only** (no file under `plugin/` touched)
**Build under test:** `plugin/` at repo HEAD (post-14-Aug save-panel work) · Praat 6.6.30 Linux x64, full GUI under Xvfb/matchbox
**Fleet:** 26 agent runs across 4 waves (~3.3M tokens): 5 baseline agents · 12 GUI drive legs on isolated displays · 6 adversarial verifiers · plus orchestration
**Method:** real clicking only (`beginPause:` cannot be scripted — confirmed again); Info-window text captured via `info$()`, never transcribed from pixels; **every printed statistic recomputed independently** in scipy/statsmodels/pingouin/scikit-posthocs from the same input; **every finding below survived a verifier instructed to refute it** on a fresh instance with its own tables. Severity: 1 = data loss · 2 = lost path/session · 3 = user misled · 4 = polish.
**Scope exclusions (standing rulings):** linear mixed models, batch voice analysis, stats demo, quick start, tutorial. Confirmed absent from the registered menu by live screenshot.

---

## 1. Executive verdict

**The statistics engine is correct.** Across roughly 350 dialogs driven and 150+ independently recomputed statistics — descriptives, normality, two-group, paired, one-way/two-way ANOVA, Tukey, Kruskal-Wallis, Dunn under both adjustments, correlation, regression with diagnostics, all wizard branches including repeated measures and Friedman, and the on-figure annotation statistics — **not one printed number disagreed with independent recomputation at printed precision.** Differential probes prove the options are real: Welch ≠ Student, Holm ≠ Bonferroni where the code reads them, Wilcoxon is a genuine signed-rank. The committed R suite re-ran green on this clone (10,063/10,063) and all six repo harness suites passed with zero retries.

**The risk lives at the edges, not the core.** The confirmed defects cluster in four places: the table editor's name-addressed operations (the audit's only severity-1: it can silently destroy the wrong column's data), entry points that die before their dialog opens (Matrix/TableOfReal buttons, the stereo channel path), saves that kill the session on legitimate input (slash in a base name, unwritable folder), and exports/replays that silently drop content (multi-column normality CSV, recorded advanced figures). A second tier misleads rather than breaks: a success modal over a failed analysis, refusal text computed on a silently halved sample, a figure frame that doesn't bound its data.

**The graphing layer's duplicated statistics engine agrees numerically with the wrappers everywhere tested.** Its cost today is the seams — dropped presets, an ignored adjustment menu, config keys written but never read, and one crash that fires exactly when a result is significant. Those seams are one architecture problem (your standing unification ruling), not seven independent bugs. Details in §5.

---

## 2. Accuracy — the first criterion

Zero mismatches at printed precision, everywhere tested:

- **Committed ground truth re-run on this clone:** `validate/run_all.R` → 10,063/10,063 checks, 0 failed, exit 0 (+8 attestations). scipy oracle 25/25, worst |diff| 8.8e-10.
- **Fresh GUI drives, recomputed independently:** describe (16/16 statistics, incl. type-7 quartiles, G1 skew, excess kurtosis, t-based CI; plus a missing-data variant with correct N-excluded disclosure) · normality (Shapiro-Wilk W/p across columns; full-precision CSV agrees to ~1e-11) · two-group (Welch and Student t/df/p as separate verified runs; Mann-Whitney U exact) · paired t + Wilcoxon signed-rank · one-way ANOVA with full SS/MS table + Tukey (q/p vs statsmodels) · Kruskal-Wallis (H/df/p) + Dunn z with **both** Holm and Bonferroni adjusted p verified · two-way ANOVA (SS decomposition verified against statsmodels `anova_lm`) · regression (slope/intercept/SE/t/p/R²/F + cooksd diagnostics) · wizard branches: two-group, k-group, correlation, regression, RM-ANOVA (F, p, GG epsilon incl. the n=2 floor case), Friedman χ²/p · Q-Q plot's Blom-score OLS reference line (exact to 4 dp) · effect sizes: d, dz, Hedges g, η², ε², r.
- **On-figure annotation statistics match both scipy and the wrapper's own printed values** for every bridge arm (violin/box pooled, grouped, histogram, scatter correlation): the two engines agree.
- **Recorded scripts carry correct numbers:** a replayed recording's Welch analysis matched the original to printed precision (the replay's *figure* fidelity is a separate finding, §3).

The only statistically wrong *text* found anywhere: the Mann-Whitney gloss labels U1 "Sum of ranks" (it is not — R1=274 vs printed U1=64 on the verification table; U = R1 − n1(n1+1)/2). The number is right; the teaching sentence is wrong. (§4, G2-2.)

---

## 3. Confirmed findings — data loss and broken paths (severity 1–2)

Every entry: independently re-reproduced by a refute-oriented verifier on a fresh instance. Mechanisms cite file:line at HEAD.

**S1 — Edit Table can silently destroy the wrong column's data.** `NEW-G10-2, verified sev 1.`
With duplicate column labels present, Delete Column honors your *selection* in the UI but deletes the *first label match*. Verifier built id/colA/colB, renamed colB→colA, selected the third menu entry (the B-data column) — the A-data column was deleted, no warning, no undo. Mechanism: the editor is entirely name-addressed — `eml-edit-table.praat:522` passes the optionmenu's label string to Praat's `Remove column:`; the positional index is discarded. Once duplicates exist, the second one is unreachable by **every** editor operation (cell read/set :148/:178, find/replace :287–386) — they all silently hit the first.
**Enabler** (`NEW-G10-1, sev 2`): Rename Column's only validation is non-empty (`:553–559`) — renaming to an existing name silently creates the duplicate state. These two are one fix: uniqueness check on rename + positional addressing (or rename-before-delete) in the editor ops.
**Sibling** (`NEW-G10-3, PARTIAL, sev 2`): Delete Column on a one-column table sails past the guard (`:499` checks `< 1`; Praat forbids 0-column tables, so the correct bound is `<= 1`) into Praat's hard "cannot remove my only column" error: session aborted, an orphaned read-only TableEditor window left open, and Praat's recovery text pointing at a pause window that no longer exists. The originally filed "wedged pause form" clause was refuted — after dismissing, the editor relaunches cleanly.

**S2 — Eleven registered entry points crash before their dialog opens.** `NEW-G12-1, sev 2.`
`setup.praat` registers EML buttons on Matrix (5) and TableOfReal (6), but selecting a Matrix or an unlabeled TableOfReal and pressing any of them dies natively in the coercion path before the dialog appears. The crash also strands temp objects, including a converted Table that *shadows the source object's name* (`NEW-G12-2, sev 3`) — the next thing a user selects may be the wrong object. Either finish the coercion or unregister the types.

**S3 — Stereo channel handling is unreachable.** `NEW-G7-2, sev 2.`
`@emlHandleStereo` / `@emlCheckChannels` / `@emlApplyChannelChoice` (`eml-graph-procedures.praat:3876–3942`) have zero callers in the graphs flow. A stereo Sound draws stacked and converts to Pitch silently; the Mix/Left/Right choice can never appear (the only live copy of that dialog is inline in out-of-scope batch code). For a voice lab where stereo EGG+mic recordings are routine, channel choice is not optional. Wire it or remove the dead procedures.

**S4 — Two saves kill the whole session on legitimate input.**
- Slash in the Save panel's base name (`NEW-G2-1, sev 2`): a user typing `pre/post` gets a raw Praat abort whose recovery text points at a dead window; the completed analysis and its Done/Save/Draw/New loop are gone. Sanitize the base name in the panel (it already owns the naming contract).
- Unwritable target folder (`NEW-G12-5, verifier raised 3→2`): realistic on network shares and locked-down folders; the whole post-analysis cascade dies with raw internals. Validate writability before flush — the panel's `createFolder:` already shows the pattern.

**S5 — Multi-column normality Save silently exports one column.** `NEW-G1-1, sev 2.`
The dialog promises "all 3 numeric columns"; `_report.txt` contains all three; `_tidy.csv` contains **one data row** (the last column) and `_glance.csv` one unidentified row — because the orchestrator calls the CSV init at entry (`eml-analysis.praat:2365`) and the wrapper loops it per column, resetting the collectors each pass. Same init-discipline family as the CSV defect you closed last week (D66), arrived with the new Save button. The one exported row is numerically perfect, which makes the loss harder to notice.
**Same family:** each Draw in one graphs session appends a duplicate result block to the export (`NEW-G8-3, sev 3`) — one analysis presented as nine value-identical rows.

**S6 — Annotated Kruskal-Wallis draw crashes exactly on significance.** `NEW-G9-1, sev 2.`
"Unknown variable: `emlKruskalWallis.rMatrix##`" — fires only when the omnibus is significant (the branch that needs the pairwise matrix), killing the whole graphs session. Effect-size toggle does not gate it. The crash triggers precisely when a user has a result worth annotating.

**S7 — Paired wrapper's New-after-Draw is a dead end.** `NEW-G3-1, sev 2.`
After Draw, "New" reopens the form bound to the *deleted* internal reshape table — it offers Subject/Condition/Value instead of the user's real columns, and Run dead-ends. (Related polish: the reshape table's name `pairedLong` leaks into the spaghetti default title and save stem.)

**S8 — Recorded advanced figures don't replay faithfully.** `NEW-G11-2, sev 2.`
Record an advanced-mode annotated, jittered violin; stop and save; replay the emission: the annotation bracket and jittered points are missing — the emission doesn't carry those advanced settings. The recorder's numbers replay perfectly; its figures are the part that loses work. (Verifier-downgraded sibling: a stale duplicate recording-meta table stamps a later session's emission with the dead session's timestamp — steps all emit correctly, so provenance-only, now sev 3, `NEW-G11-3`.)

---

## 4. Confirmed findings — misleading output (severity 3)

All evidence-audited (files inspected, statistics recomputed from the finders' exports, mechanisms traced); none refuted.

1. **A failed analysis is presented as a success.** Zero-variance paired data: the refusal text is buried inside the report while the modal announces "Analysis complete" and offers Save/Draw/New (`NEW-G12-3`). Contrast with the singleton-group refusal modal, which is the plugin's gold standard (names groups, n, rule, preserves selections) — the inconsistency is the finding.
2. **Refusal text computed on a silently halved sample.** RM/Friedman with incomplete cases: the diagnosis claims "every subject" shows a pattern, but only retained subjects were assessed; nothing discloses the exclusion (`NEW-G6-1`).
3. **Mann-Whitney gloss mislabels U1 as "Sum of ranks"** (`NEW-G2-2`). The rest of the sentence describes U correctly; delete/replace the two words.
4. **ANOVA residual export borrows broom's `.std.resid` name for non-broom values** — leverage term missing; uniform 4.4% understatement on the balanced demo, grows with leverage on unbalanced designs (`NEW-G4-1`; the earlier regression fix didn't cover the ANOVA arm).
5. **User-set axis ranges don't clip:** points outside the range draw outside the frame, over the axis annotation (`NEW-G8-1`); a one-sided range (min only) is silently swapped into (0, min), inverting intent (`NEW-G8-2`); the min>max swap block silently "fixes" reversed entries with no notice (map S13, confirmed live).
6. **Annotation panel can sit on a datum:** the point vanishes under the panel but its dotted ghost bleeds through the annotation text — invisible datum plus garbled label in one figure (`NEW-G8-4`).
7. **Pitch contour on steady phonation** (verifier re-tiered 2→3): a sustained tone draws as a wildly fluctuating contour over a collapsed axis whose integer ticks all read the same value. Discriminating probe located the break: axis floor and tick precision, not the pitch analysis (values are exact). Fix shape: minimum axis span (e.g. ≥2 Hz or semitone-scaled) + tick labels gaining decimals when the span is sub-integer (`NEW-G7-1`).
8. **Check & repair file mode overstates its verdict:** a ragged CSV passes with only a quote warning ("No import problems found") and then Praat's reader refuses the same file outright — row-length consistency isn't checked (`NEW-G10-4`).
9. **The recorder's emitted script claims a portability it doesn't have:** header says home-relative, include block is machine-absolute (`NEW-G11-1`); and stop-and-save onto a missing folder leaks raw internals pointing at a closed window (`NEW-G11-4`).
10. **Raw pre-dialog refusals** (Describe wrapper and validation guards) bypass the plugin's own error dialog and leak Praat stack noise; wording itself accurate, so verifier re-tiered 3→4 (`NEW-G12-4`).

---

## 5. The unification picture (your standing ruling on the graphing door)

Measured this session, in one sentence: **the duplicated graphs statistics engine is numerically faithful and behaviorally leaky.** Every bridge-arm statistic matched scipy and the corresponding wrapper output. But all of these confirmed seams are the duplication showing through:

- The wrapper→Draw journey sets an annotate preset that every beginner-mode Draw commit hard-resets — the default journey draws a significant result *unannotated* (D7, confirmed live).
- The parametric post-hoc arm offers an Adjustment menu the Tukey branch never reads — Holm and Bonferroni draws are pixel-identical (md5-equal) while the Dunn arm honors the same menu (D5, confirmed).
- The KW annotation arm's own recompute path is where the significance-gated crash lives (§3 S6).
- Custom X/Y axis labels and subtitle are persisted to config and never restored — lost within a single session (D1/D2 + subtitle, confirmed).
- Legend placement commits only in advanced mode, so "Separate figure" leaks from an old advanced session into a later beginner save as an unrequested `_legend.png` (D8, confirmed).
- The advanced-settings stash is per-graph-type and dies on a type switch (confirmed).
- The scatter dot-size preset channel is wired end-to-end with no producer (D4, confirmed).

Fixing these piecemeal is possible; the unification (result pass-through when an analysis launched the draw, same machinery for standalone draws, figure states which) retires the whole class plus the future versions of it. Since the engines already agree numerically, unification carries **no risk of changing any number** — this session is effectively the regression baseline for it.

One refutation worth recording: the paired wrapper's literal `"Group"` preset (map candidate D15) is **correct** — it targets the wrapper's own reshaped table, which always has that column.

---

## 6. Usability report

**Worth preserving (measured, not flattery):** the singleton-group refusal modal (names the groups, the n, the rule, keeps your selections on Back); describe's missing-data disclosure ("N excluded 3 · 3 cell(s) empty (row 3 first). Treated as missing data."); the save receipt's honest full-path listing and one-stamp-per-press behavior (verified across legs); the Q-Q methods note (Blom a=3/8, difference from R's qqnorm named); Praat-native responsiveness at 10k rows (describe ~1.9s, Welch ~5.3s); unicode and comma-bearing column names survive pickers, reports, and exports.

**Dialogs and flow.** The scatter advanced dialog is ~1000px tall — the Go Back/Quit/Beginner/Draw row clips off a 1000px display (drove it by keyboard); worth a two-column or split layout. The "Saved" receipt garbles when paths wrap: one line is reserved, several are drawn — five independent sightings, one root cause; one wrap pass (the plugin already has `@emlWrapText`) fixes all. Group column/order dropdowns sit active while "Use group column" is unticked, then discard the value (three graph types). Line Chart's data-format explainer is overlapped by its own optionmenu. Redraw pre-fills the *previous* auto-title, which then survives a graph-type switch.

**Defaults and guesses.** Spaghetti's condition-column guess picked a between-subject factor over the repeated condition on a two-way table; the paired dialog's column-role guess remains the known open risk (D77/D78) — the wizard-side mitigation exists, the menu wrapper's guess is still trusting. Spaghetti also defaults "Use group column" ON with Group=subject, producing a redundant 10-entry legend duplicating the lines.

**Vocabulary and taxonomy.** For a Table, Bar Chart files under the "Continuous" divider while Violin/Box/Histogram sit under "Categorical" — reversed relative to how a voice researcher reads those words (menu dividers, map-confirmed). Range fields order max above min. The report prettifies column names (underscores→spaces), so users grepping their own column names miss; the scatter auto-title drops the parentheses its own axis label keeps. p-values switch between APA 3-dp style and raw 16-digit doubles between blocks.

**Recorder.** Both internal tables sit visibly in the Objects list mid-recording; deleting the buffer silently stops recording — later analyses just never appear in the script, no signal (answered your open question). The start message explains only one of the two tables. The review-copy folder is printed at stop time but documented nowhere else. A recorded save replays *interactively* (the panel reopens), so a recorded workflow containing a save can't run unattended — worth an explicit design decision. Replay generations accrete one timestamp per generation in the base name. Stop-and-save's collision handling (silent `_1`) diverges from the panel's stamp convention — two naming schemes for one plugin.

**Describe Table column** is the only wrapper with no Save button and no Clear-Info field, and it ends with no completion dialog — results appear only if the Info window happens to be visible, and stack under stale content (D12 confirmed; contrast with your "every path reaches the export step" ruling).

---

## 7. Findings against the validation infrastructure and docs (not the plugin)

- **Four documents carry four different stale suite totals** — README 6,486 · validate/README 4,058 (×4 sites) · REGISTRY headline 8,221 · the 14-Aug session report 9,877 — against a live 10,063. The repo's own `check_registry_counts.R` fails on exactly this. One number, one owner, or generate the line.
- `coverage.R` run standalone produces 12 spurious v38 FAILs (passes inside `run_all.R`) — worth a one-line header note or a guard.
- `gui.sh`'s menu-coordinate constants are stale after the 13-Aug menu re-chain: `EML_DEMO` now clicks *Record script* (cost this session a phantom recording before the fleet launched; live-measured table now in `/home/claude/AGENT_BRIEF.md`). `MENU_MAP.md` needs a re-measure pass.
- The savepaths flake (1-in-9) **did not reproduce**: 11/11 legs, no retries, this environment.
- P1 (0600 file modes) is not representable in a git clone — this clone is clean; the check belongs to the packaging step, as already recorded.
- Redpath evidence gaps R1/R2/R5 (never driven post-fix on the exact committed CSVs) and R7 (never GUI-driven) are **now closed** by this session's captures — locations in §9.

## 8. Findings against the PraatGen source of truth (flow back to the generator)

- The forbidden-token list bans `+=`, which is valid Praat 6.6.30 (verified: scalars and vectors) and appears in the SOT's own quoted Praat error text. Drop it (and review `-=`/`*=`//`=`), or scope the rule to generation-time Python-contamination linting. (Your call, confirmed mid-session.)
- Rule 5D's dotted-loop-local caution (`for .e`) is overbroad — measured fine; the hazard is bare `e` only.
- `x <> undefined and x > 0` compound guards measured SAFE on 6.6.30 (undefined comparisons return false); Rule 30's nesting is style, not crash protection — distinct from the real `variableExists(...) and ...` hazard, which remains real and is fully swept from the plugin (zero occurrences).
- Rule 28I second-save concern REFUTED by drive: after a separate-legend save, a second Save press produces a byte-identical full figure — the viewport restore is correct.

## 9. Evidence and reproduction index

All evidence is **sandbox-local and dies with this session**; the companion zip preserves the key artifacts. Layout: `/tmp/aud51–56` (core stats legs) · `/tmp/aud57–62` (graphs/editor/recorder/stress legs) · `/tmp/aud63–67` (verifier re-repros, independent tables) · `/home/claude/fleet/` (fixtures `demo_*.csv`, dedupe map, SOT check, wave logs, this report). Each leg carries `<leg>.log.md` (narrative), `<leg>.verify.md` (recomputation tables), `shots/` (pre-press dialog screenshots), figures, exports, and captured Info text. Redpath closures: r1/r2 wizard RM drives in `/tmp/aud56/out`, r5 diagnosis in `/tmp/aud56/out`, r7 GUI axis figure in `/tmp/aud62/out`. Verifier evidence includes the duplicate-column proof CSVs (`/tmp/aud63/out/v.t1/v.t2*`) and the pitch-axis discriminating probes (`/tmp/aud65/out`).

## 10. Priority recommendation to the managing session

1. **Editor name-addressing family** (S1): uniqueness check on rename + positional addressing; fix the `< 1` guard bound. One mechanism, closes the only severity-1 plus two siblings.
2. **Dead doors** (S2, S3): unregister Matrix/TableOfReal buttons or finish coercion; wire stereo handling or remove it. Dead doors are worse than absent features — they teach users the plugin crashes.
3. **Session-killing saves** (S4): sanitize base name + validate folder writability in the panel. Two small guards, both session-savers.
4. **Export integrity family** (S5 + duplicate blocks): move CSV init out of per-column/per-draw loops — the same init-discipline lesson as last week's export fix, now as a rule: *init once per press, accumulate per loop*. v48's one-arm check could grow a row-count-equals-columns-tested assertion to catch this class permanently.
5. **KW annotated crash** (S6): declare the pairwise matrix on the significant branch; add the significant-KW annotated draw to the harness (it is currently the only crash reachable from a default journey).
6. **Paired New-after-Draw rebind** (S7).
7. **Recorder replay fidelity** (S8) + provenance stamp + include-header truthfulness — the recorder's whole value is trustworthy replay.
8. **Truthfulness batch** (§4): success-modal-over-refusal, reduced-sample refusal wording, U1 gloss, `.std.resid` naming, file-mode verdict wording, range clipping/inversion, pitch-axis floor.
9. **The unification** (§5): retires the seam class structurally; this session's engine-agreement measurements are the free regression baseline.
10. **Polish batch:** the one-line `@emlWrapText` fix for the five-sighting Saved receipt, dialog height, dividers, min/max order, title parens, `pairedLong` leak, p-format consistency, wizard's one pre-v2 page.

*Compiled by the stress-test session · all severities as verified, not as filed · questions the managing session may want answered live are marked in-line above.*
