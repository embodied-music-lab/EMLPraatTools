# Complete Handoff Package for Opus — EML Praat Tools Audit & Implementation Spec

## Executive Summary

Independent stress-test audit completed 16 Aug 2026 at HEAD (commit 5ecb037). Suite: 11,786 / 11,786, 0 failed, exit 0. Findings verified through independent re-reproduction against Praat 6.6.30. All three open design questions resolved via author rulings. One critical numeric defect identified (one-tailed p in scripting API). Implementation spec fully documented below. No further investigation pending.

---

## Verified Findings: Complete Inventory

### Severity 1 (data loss)
**Edit Table duplicate columns → delete wrong column.**
- **Root cause:** Delete Column accepts names; when two columns share a name, delete hits the FIRST match regardless of which duplicate you selected.
- **Impact:** Silent loss of the wrong column's data.
- **Fix:** Rename-to-sentinel shim in the delete path (before the deletion, reassign the duplicate to a temp name so position-based delete selects the right one). Or: refactor delete to use internal column index, not name lookup.

### Severity 2 (lost path / session-killer, 10 findings)

1. **Normality Save exports only last column when multi-column input.**
   - Root: CSVInit called in the loop body; each iteration overwrites the file.
   - Fix: Initialize CSV once before loop, append per column.

2. **Slash in base name aborts session.**
   - Root: Praat's file path constructor treats `/` as separator; illegal in filename.
   - Fix: Sanitize base name (strip/replace illegal chars) before Save dialog or file write.

3. **Paired "New" after Draw rebinds to deleted reshape table.**
   - Root: New uses stale reference; the reshape table was deleted between Draw and New.
   - Fix: Keep the reshape table (or store its data into a fresh table that persists) so New has a valid source.

4. **Annotated Kruskal-Wallis draw crashes when omnibus is significant.**
   - Mechanism: "Unknown variable: emlKruskalWallis.rMatrix##" when effect-size toggle or annotation bridge runs.
   - Fix: Initialize `.rMatrix##` before the annotation bridge attempts to read it. Verify exact init location by tracing the bridge logic.

5. **Matrix / unlabeled TableOfReal action buttons crash before dialog opens.**
   - Root cause: Conversion Matrix→TableOfReal→Table succeeds; the crash is downstream. Unlabeled row labels yield an all-undefined `row` column. The wrapper's numeric probe (`Get all numbers in column:`) dies on it.
   - Fix: Default row labels (r1, r2, …, rn) at conversion time OR skip/classify the label column in the probe (type-safe column classification instead of assuming numeric). Also: route eml-describe-table.praat:36 (Table-only refusal) through the same coercion as other wrappers so Matrix paths don't take the early exit.

6. **Stereo channel handling unreachable from EML Graphs.**
   - Mechanism: @emlHandleStereo/@emlCheckChannels/@emlApplyChannelChoice exist (eml-graph-procedures.praat:3876–3942) with zero callers in the menu flow. Only inline copy in tabled batch script.
   - Fix: Wire the existing procedures into the EML Graphs flow for Sound input (and any derived-object path where channel choice matters, e.g., before To Pitch).

7. **Recorded advanced-mode figure replays WITHOUT annotation bracket and jittered points.**
   - Root: Emission incomplete; annotation and jitter calls not recorded in the step collector.
   - Fix: Verify the annotation/jitter calls are within the record/rewind block (see ruling B below).

8. **Stale recording-meta table corrupts provenance in later sessions.**
   - Root: Duplicate or stale metadata table with wrong timestamp; emitted script uses that timestamp.
   - Fix: Audit the metadata table lifecycle (when created, when cleared, when referenced). Ensure each session's metadata is fresh or properly scoped.

9. **Delete Column on one-column table bypasses guard.**
   - Root: Guard condition not met or guard logic incorrect.
   - Fix: Verify guard is checked BEFORE delete attempt; if table has 1 column, refuse with user message.

10. **Recorded Save steps accrete one timestamp per generation.**
    - Root: Timestamp regeneration not happening at replay; old stamp remains in emitted script.
    - Fix: Implement change order 10 (axis ranges into editable block with consume-once semantics) including timestamp regeneration at replay time.

### Severity 3 (user misled, 14 findings)
[Mechanism and fix guidance for each provided in the audit report sections §4–6. Key examples:]

- **One-bin Spectrum renders empty frame (zero ink).** Root: dB conversion 10.32 dB low (density vs power scaling). Fix: verified fix in batch two.
- **Recorded auto axis offers `0.0 to 0.0` in editable block.** Root: form destroys evidence before recorder sees it. Fix: publish untouched request (ruling A, change order 10).
- **Pitch Contour y-axis collapses on near-constant F0.** Root: ten identical ticks, steady tone draws as fluctuation. Fix: detect degenerate case; auto-expand axis or warn user.
- **Points outside user-set axis range draw unclipped outside frame.** Root: clipping logic missing or incorrect. Fix: apply clip region before point rendering.
- **D1/D2 custom axis labels lost within session.** Root: stash lost on graph-type switch. Fix: persist stash across type changes or re-derive from user input.
- **D11 group dropdowns active while unchecked.** Root: UI logic ties enable state to wrong control. Fix: group dropdown enable ← `groupCheck` state.
- **U1 mislabel "Sum of ranks" for Mann-Whitney.** Root: label string wrong. Fix: update label to match the statistic (e.g., "U-statistic" or "Sum of ranks (U)").
- **ANOVA augment `.std.resid` mislabel.** Root: label string wrong. Fix: verify correct statistic name and update label.
- **Tukey annotation arm accepts Adjustment field but ignores it.** Root: field offered (UI suggests it's live), but its value never read. Fix: per ruling 1 below, DISABLE/REMOVE the field on the parametric arm; have the annotated figure state that Tukey carries its own family-wise control.
- **Beginner Save emits unrequested `_legend.png` from earlier advanced session.** Root: legend file from prior session persists in Save state. Fix: clear Save-state legend file path on mode switch or entry.
- **Zero-variance paired refusal buried in report; modal says "Analysis complete".** Root: error message does not reach the dialog; modal still shown. Fix: check error condition BEFORE showing "Analysis complete" modal, or suppress modal on error.
- **Raw Praat stack noise leaks on pre-dialog validation.** Root: validation failure not caught; Praat error output shown. Fix: wrap validation in error-catch block; emit user-readable message instead.
- **Unwritable-folder saves leak raw Praat internals.** Root: file write error not caught. Fix: wrap Save in try-catch; emit "Could not write to [path]. Check folder permissions" instead of raw Praat error.
- **RM-ANOVA warning string printed AND exported; formatting would silently edit exported value.** Root: one string, two destinations with opposite rules. Fix: maintain byte-unchanged exported string; format only the printed version (per ruling 5 in LETTER_TO_OPUS).

---

## Author Rulings — All Resolved (Implement These)

### Ruling 1: Adjustment field on Tukey arm
**Status:** ACCEPTED (author confirmed 15 Aug).
- **Action:** Disable/remove the Adjustment field on the parametric arm (Tukey is already family-wise; stacking Holm/Bonferroni would double-correct).
- **Also:** Have the annotated figure state that Tukey carries its own family-wise control.
- **Note:** The Dunn arm keeps the menu and honors it (verified: Holm ≠ Bonferroni there, both match scipy).

### Ruling 2: Version floor — two contracts, not a discrepancy
**Status:** ACCEPTED (author confirmed 15 Aug).
- **Action:** Leave both numbers unchanged; do NOT conflate.
- **The plugin's floor is 6.6.30** and it is FINE to refuse below it. The validation evidence exists only at 6.6.30; a warn-and-continue plugin would print unvalidated numbers under a validated banner.
- **PraatGen has its own lower measured floor (6.4.39)** governed by its own §S15A warn-don't-refuse rule for generated scripts. Different artifacts, different contracts.
- **Doc guidance:** If any doc implies the plugin should follow §S15A, correct it to state the distinction instead.

### Ruling 3: Skewness and kurtosis into the tidy vocabulary
**Status:** ACCEPTED (author confirmed 15 Aug).
- **Action:** Add skewness and kurtosis to the tidy export vocabulary.
- **Why:** They already ship in the glance vocabulary under "our own additions." This removes the asymmetry: single-column exports them, multi-column loses them.

### Ruling 4: Recorder buffer deletion — no per-step signal
**Status:** ACCEPTED (author confirmed 15 Aug).
- **Action:** Rename the buffer to something that reads as load-bearing; keep the corrected Stop-command message ("recording ended when its buffer was removed").
- **No additional per-step signal required.**

### Ruling 5: y-axis margin when ticks exceed 5 characters
**Status:** DELEGATED (author delegate the mechanism; requirement is no collision).
- **Measured constraint:** Praat's left-margin allocation is FIXED (~100 px ≈ 5.2 digit-widths). Rotated axis name renders in same band regardless of tick width; ticks are right-aligned to frame.
  - Five-character ticks leave ~¼ digit gap.
  - Six-character ticks are the failure edge: semitone axes with negatives ("−32.98") read as touching; explicit 2-decimal dB axis genuinely touches ("Power (dB)" against "100.10").
- **Implement:** When explicit precision engages OR the widest rendered tick label exceeds 5 characters, widen the plugin's left viewport margin by one character-width before drawing. Implement in @emlTickPrecision or @emlDrawAxes.

---

## P0 Priority — One-Tailed p Defect in Scripting API

**Status:** CONFIRMED, ranked first (Sol 5.6 evaluation + author endorsement).

**Empirical proof:** group1=[8..12], group2=[10..18] → t=−2.5298, tails=1, p=0.0227; groups REVERSED → t=+2.5298, tails=1, p=0.0227 (same). A fixed-direction test must give .0227/.9773.

**Root cause:** eml-inferential.praat computes `.p = studentQ(abs(.t), .df)` for tails=1. This computes the smaller tail of the absolute statistic, NOT a fixed-direction hypothesis test. Same pattern in paired t and Pearson/Spearman kernel.

**Scope:** Every REGISTERED menu path passes tails=2 (eml-analysis.praat:243, 1796, 3633), so shipping menus are unaffected. The scripting API contract is wrong.

**In-house model:** MW/Wilcoxon already implement true fixed alternatives (matching R's wilcox.test). Use them as the reference.

**Implementation spec (exact):**
1. Replace numeric `tails=1` with explicit two-sided/greater/less parameter (deprecate the old numeric flag).
2. Derive tail from the SIGNED statistic:
   - If t > 0 and test is "greater", p = tail_right
   - If t > 0 and test is "less", p = 1 − tail_right (or equivalently, tail_left)
   - If t < 0, reverse the above
3. For perfect effects in wrong direction, p = 1.
4. Apply sign-reversal regression test matrix across Welch/Student/paired/Pearson/Spearman to verify fix.

---

## Change Orders — Complete Implementation Spec

### Change Order 1: Matrix/TableOfReal converted-column naming (source-index, not table-position)
**Status:** VERIFIED.
- **Current state:** Column 1 is named `row` (correct, holds r1..rn labels). DATA columns to its right are numbered by TABLE position, so source matrix column k is labeled `Column_{k+1}`.
- **User symptom:** Asking for "column 2 of my matrix" and picking `Column_2` gives matrix column 1's data.
- **Fix:** Number DATA columns by SOURCE index. `Column_k` holds matrix column k.
- **Evidence:** leg2_converted_mx.csv — Column_2 currently holds source column 1.

### Change Order 2: Numeric display standard — one rule, sweep for leaks
**Status:** VERIFIED.
- **House standard confirmed:** Statistics at fixed 4 decimals, p in APA style (matches SPSS, JASP/jamovi, R peer practice).
- **Rule:** NO raw double ever reaches the Info window. Full precision belongs to CSV export only.
- **Known leaks to fix:**
  - Skewness in converted-matrix Describe path prints `−0.0000000000000001` (leg2_mx_describe.info.txt).
  - Wizard's p-lines print raw 16-digit double after "< .001" (audit finding NEW-G5-2).
- **Action:** Fix both leaks, then sweep for siblings behind the same bypass.

### Change Order 3: Y-axis margin vs 4-significant-digit ticks
(See Ruling 5 above for full spec.)

### Change Order 4: Housekeeping — matrix/stereo/spectrum accumulation
**Status:** VERIFIED (sev-4, batch at will).
- **Each door press on same Matrix/TableOfReal:** Creates a fresh `eml_converted_*` Table (accumulates per press).
- **Each stereo draw:** Leaves extracted channel Sound (accumulates per press).
- **Action:** Reuse tables/sounds across presses, or clean up after each session.
- **1-bin Spectrum:** Renders empty frame with axis furniture only. Was unchased in audit; fix confirmed in batch two.

### Change Order 5: Recorder — lift column names into editable header block
**Status:** VERIFIED (author ruling 9, LETTER_TO_OPUS).
- **Current state:** Emitted script gathers only object names (`data1$ = "Table vt"`). Column names stay hard-coded literals at each call site (`@emlBridgeGroupComparison: data, "val", "grp", ...`).
- **User problem:** Retargeting to a same-shape table with different headers means hunting literals through the steps.
- **Fix:** Gather column names into the editable header block:
  ```
  valueCol$ = "val"
  groupCol$ = "grp"
  ```
  One variable per distinct role the recording used. Have the steps reference the variables.
- **Contract extension:** The block's existing promise ("nothing below this block names an object") extends to: nothing below this block names a column.
- **Evidence:** harness/record/replay_out/adv_emitted.praat lines 53–62.

### Change Order 6: Recorder — record the user's axis CHOICE (auto vs explicit range)
**Status:** VERIFIED (author ruling 10, LETTER_TO_OPUS, change order 10).
- **Current state:** Emission bakes RESOLVED axis range into draw call as numeric literals (`@emlDrawViolinPlot: ... 1.554964, 4.416270` — "Axis resolved to 1.5550 .. 4.4163") even when the user left the axis on auto.
- **User problem:** On retargeted data, statistics recompute honestly but frame stays frozen at original data's range (clipped or swimming).
- **Two-part fix:**
  - **(a) When user chose AUTO:** Emit auto. Let the draw resolve the range from the data at replay time.
  - **(b) When user set explicit range:** Emit as variables IN the editable header block (`axisYMin = 6`, etc.), referenced by the draw call. So one place a user edits for new data is still the top block.
- **Test requirement:** Replay comparison harness needs two legs:
  - Same-data leg: byte-identical figure when data is unchanged.
  - Retargeted leg: figure rescales under auto; explicit ranges apply to new data.
- **See also:** Ruling A below for session-scoped axis publication escape (consume-once via step-stamp).

### Change Order 7: Recorder — consume-once semantics for axis publication (step-stamp implementation)
**Status:** VERIFIED (author ruling A, SOL_EVAL_RESPONSE).
- **Problem:** Praat cannot unset a variable. Once the form publishes the axis request, it lives for the process. Example: `eml-draw-qq.praat:259` calls `@emlDrawScatterPlot` with `0, 0, 0, 0` and no form; after an EML Graphs draw at 0–100 in the same session, a recorded Q-Q step would carry 0–100 instead of its own 0/0 (auto).
- **Root cause:** @emlRecordAxisRequest prefers the form globals whenever they EXIST. Existence is permanent in Praat. The code uses existence as a proxy for "this draw came from the form"—which is wrong; it just means "some form ran earlier this session." Fallback logic already works correctly for formless draws (it accepts the draw's own arguments).
- **Solution: Step-stamp (preferred by author).**
  - Form publishes pair (e.g., `valueMin`, `valueMax`) + current recorder step number.
  - Recorder reads the pair only when the stamp matches the step being recorded.
  - Recorder immediately reassigns the stamp to 0 after validation.
  - The stamp can be safely reset (unlike the pair itself, where 0/0 is the auto sentinel).
- **Alternative: Validity flag** (simpler but less generalizable).
  - Form sets `requestLive = 1` at publication.
  - Recorder reads the pair only when `live = 1`, then reassigns `live = 0`.
  - Same outcome, less future-proof.
- **Both-or-neither:** The pair and the companion signal (stamp or flag) must both succeed or both fail. Do not publish one without the other.
- **Implementation files:** @emlRecordAxisRequest (eml-record.praat:1690–1750) and form publication callsites.

### Change Order 8: Recorder — legend two-pass records two draw steps (add mark/rewind)
**Status:** VERIFIED (author ruling B, SOL_EVAL_RESPONSE).
- **Problem:** @emlGraphsDrawWithLegendRoom rewinds the CSV collector between passes but there is no `emlRecordMark` / `emlRecordRewind`, so the emitted script says `steps 1 (draw), 2 (draw)`. The resolved-range note names the discarded first pass (195..235) while the figure was drawn at 195..275.
- **Fix:** Add the record mark/rewind so one user action emits ONE draw step carrying the FINAL resolved range.
- **Same principle as:** Duplicate-export defect already fixed (NEW-G8-3).
- **Test:** Replay must be byte-identical on same data.

### Change Order 9: Recorder — two-group bracket figures name their test (set annotTextN)
**Status:** VERIFIED (author ruling C, SOL_EVAL_RESPONSE).
- **Problem:** Two-group arms of @emlBridgeGroupComparison compose an omnibus string but neither sets `annotTextN`. Only the k≥3 arms do. So the form has no line to route into the corner box. Whole-figure OCR finds bracket + `***, d = −6.08` but no test name.
- **Fix:** Set annotTextN on the two-group arms, exactly as the k≥3 arms do after ruling 11.
- **Invariant:** "Every bracket-bearing figure names its test" with no two-group special case.
- **Note:** The two-group line claims no adjustment, which is honest for a single comparison.

### Change Order 10: Rename/refactor dead and stale code (low priority)
**Status:** DOCUMENTED (no ruling yet; batch at will).
- **D:** @emlCheckPlausibility (eml-graph-procedures.praat:4823) is dead code. Three `fixed$` calls, zero callers. Either wire it or retire it; v68 pins the count at 0, so wiring it up turns v68 red until someone argues for it.
- **E:** v66 carries the first-ink trap at :633–636 and :547–549 (asserts `first_ink_px > 0`). Measurement moves the wrong way for clipped elements. Same trap found and rebuilt elsewhere this week.
- **F:** validate/REGISTRY.md narrative stops at v38. Thirty-four validators (v39–v72) absent from "the full reference: what every script covers." Documentation debt, not a defect, but larger than it looks. Do not close by appending one line for v72.
- **G:** harness/walks/gridmode committed evidence does not reproduce. Two problems stacked: (a) GEOM=1400x1600x24 required (at rig default 1280x900, Scatter form runs off-screen; `gbtn` finds zero buttons); (b) wrong controls set (gridlineMode: 1 where SCAT_ITEM=4 intends 4, outputDPI moved 1→2). Same class as menu-coordinate drift. Exits 0 while reporting success. Committed evidence left untouched so finding stays visible. Recommend same remedy that fixed menus: anchors proved by screenshot at run time, or rendered-state assertion after setting each control.

---

## Open Design Questions Resolved

### Question A: Axis publication escapes the form (session-scoped)
**Ruling:** STEP-STAMP implementation (author preferred, LETTER_TO_OPUS ruling A; SOL_EVAL_RESPONSE ruling A).
- **See Change Order 7 above for full spec.**

### Question B: Legend two-pass records two draw steps
**Ruling:** Add record mark/rewind so one user action = one emitted step (LETTER_TO_OPUS ruling B; SOL_EVAL_RESPONSE ruling B).
- **See Change Order 8 above for full spec.**

### Question C: Two-group bracket figure names no test
**Ruling:** Set annotTextN on the two-group arms (LETTER_TO_OPUS ruling C; SOL_EVAL_RESPONSE ruling C).
- **See Change Order 9 above for full spec.**

---

## The Unification (Pending, Last Priority)

**Status:** Deferred by author until plugin work settles. Ruled to be the last thing done.

**Scope:** Graphing-door statistics currently use a separate orchestration path. When an analysis launches a draw (Graphs menu), pass results through shared machinery. The figure must state which path was taken.

**Current state:** Both engines already agree numerically (verified via audit engine-agreement measurements).

**Risk:** Zero risk of changing a number. The audit's engine-agreement measurements are its free regression baseline.

**Timing:** Implement after all other changes land (P0 through change orders 1–9 are complete and verified).

---

## Work Queue & Priority Order

1. **P0: One-tailed p defect in scripting API** (P0-1)
   - Explicit parameter, signed-statistic tail, sign-reversal matrix.

2. **P0-2: "One result through every door" unification acceptance test**
   - Adopt as the unification's acceptance criterion, not a separate project.

3. **P0-3: Built-artifact install smoke test**
   - Linux coverable in sandbox; macOS/Windows need real machines.

4. **P0-4: CI gates**
   - Automate the suite run on each commit.

5. **P1: Cross-platform render comparison and CSV round-trip fuzzing**
   - Real and new; interaction follow-up and performance envelope already tracked (D38/D40; 10k-row timings measured in audit).

6. **Change Orders 1–9** (in recommended order):
   - 1. Matrix column naming (source-index)
   - 2. Numeric display sweep (no raw doubles to Info window)
   - 3. Y-axis margin guard (tick > 5 chars)
   - 4. Housekeeping (accumulation cleanup)
   - 5. Recorder column names to editable block
   - 6. Recorder axis CHOICE (auto vs explicit)
   - 7. Recorder consume-once (step-stamp or flag)
   - 8. Legend two-pass (mark/rewind)
   - 9. Two-group bracket names test (annotTextN)

7. **Change Order 10** (low priority, batch at will):
   - D: Dead code decision (wire @emlCheckPlausibility or retire)
   - E: First-ink trap rebuild
   - F: REGISTRY.md narrative debt
   - G: Gridmode re-measure or assertion

8. **The Unification** (last, after all above)
   - Graphing-door statistics through shared machinery.

---

## Reference Files for Implementation

All files are included in this delivery:

- **FINDINGS_MACHINE.json** — 41-row machine-readable checklist (27 NEW-* verified, 10 confirmed-live, 2 closed, 2 refuted). Use as the work queue.
- **EML_AUDIT_REPORT_2026-08-14.md** — Full audit report (§1 baseline, §2–6 findings detail, §7 priority queue, §8 evidence index, §9 methodology, §10 recommendations).
- **AUTHOR_RULINGS_ADDENDUM_2026-08-14.md** — Three initial rulings (14 Aug) — Matrix/TableOfReal, stereo channel, recorder replay non-interactive.
- **LETTER_TO_OPUS_2026-08-15.md** — Formal letter with 5 rulings and 10 change orders (author confirmed 15 Aug).
- **SOL_EVAL_RESPONSE_2026-08-16.md** — Verification of Sol 5.6 external critique + 3 open rulings (16 Aug).
- **AUDIT_RESPONSE_STATUS_20260815.md** — Batch-one and batch-two rulings with closure evidence (status checklist).
- **dashboard.html** — Visual stress-test status (waves 1–4, findings table, verifier verdicts).

---

## Next Steps for Opus

1. **Verify understanding:** Re-read rulings 1–5 and change orders 1–9. Confirm P0 one-tailed defect implementation path.
2. **Implement in priority order:** P0, then change orders 1–9 (sequencing flexible within that range).
3. **Test:** Use the engine-agreement measurements from the audit as regression baseline for the unification.
4. **Verify:** For each change order, confirm the fix against the evidence cited in LETTER_TO_OPUS and SOL_EVAL_RESPONSE.
5. **Re-run suite:** 11,786 suite should still pass 11,786 / 11,786 after all changes (zero introduced regressions).
6. **Schedule unification:** Begin after all plugin fixes land and audit compliance is verified.

---

**End of handoff. All questions resolved. Ready for implementation.**
