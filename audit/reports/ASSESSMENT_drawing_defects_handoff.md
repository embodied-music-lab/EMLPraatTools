# Assessment — PraatGen handoff "two drawing-rule violations in library source"

> **HISTORICAL RECORD.** This document describes the state of the project on
> the date in its title. It is kept for provenance and is **not** a status
> surface. Do not resume work from it and do not treat its queue, its counts,
> or its instructions as current.
>
> **Current status lives in exactly one place: `audit/FINDINGS_INDEX.md`
> (the rows, not the header prose), with the reasoning in
> `audit/PHASE_ONE_AUDIT_2026-08-06.md`.**

**Reviewed:** 3 August 2026 (session date 2026-08-03)
**Against:** `/root/eml_audit/plugin_EML_Praat_Tools`, working tree
**Handoff under review:** `EML_PLUGIN_HANDOFF_drawing_defects.md`, from the
PraatGen maintenance session, 3 August 2026

Verdict in one line: Defect A is real and is the only bare `Marks` in the
plugin, but the handoff's severity call and its "nothing to do on font
state" are both wrong, and its one-line fix is not safe to apply as
written. Defect B cannot be acted on here at all — the file does not exist
in this plugin.

---

## 1. Defect A — bare `Marks bottom:` in `emlDrawLMMForest`

### Confirmed

The construct is present and it is the **only** bare `Marks` in the entire
plugin tree:

    ./graphs/eml-draw-procedures.praat:3941:    Marks bottom: 5, "yes", "yes", "no"

The handoff's reasoning about why it matters is correct. The x-range is
computed, not chosen:

    .rng = .xmax - .xmin          ; line 3896
    .buf = .rng * 0.12
    .xlo = .xmin - .buf
    .xhi = .xmax + .buf
    Axes: .xlo, .xhi, 0.5, .p + 0.7

A 12% buffer on both ends guarantees the range is an arbitrary real
interval, so `Marks bottom: 5` produces four arbitrary tick values. This is
precisely the case Rule 1 exists for.

The proposed replacement targets a real procedure with the stated
signature:

    graphs/eml-graph-procedures.praat:1208
    procedure emlDrawAlignedMarksBottom: .xMin, .xMax, .targetTicks, .useMinor

and `.xlo` / `.xhi` are the correct locals.

### Coordinates corrected

The handoff's line numbers come from the PKB `.txt` copy at v1.18. The
plugin tree is at v1.19 (`graphs/eml-draw-procedures.praat` header line 7).

| item | handoff | tree (v1.19) |
|---|---|---|
| `procedure emlDrawLMMForest` | 3493 | **3883** |
| `Marks bottom:` site | 3551 | **3941** |
| range derivation | ~3508–3515 | 3896–3903 |
| `Axes:` | 3520 | 3910 |
| `Draw inner box` | 3550 | 3940 |
| `endproc` | — | 3949 |

### DISAGREE — the font-state claim is wrong

> "Font state in this procedure is already correct: line 3479 sets
> `Font size: emlSetAdaptiveTheme.bodySize` from the theme... Nothing to
> do there."

That line is the **last statement of the preceding procedure**,
`emlDrawGroupedBoxPlot` (tree line 3869, immediately before its `endproc`
at 3870). It is not inside `emlDrawLMMForest`.

`emlDrawLMMForest` (3883–3949) contains **no `Font size:` at all** and
**never calls `@emlSetAdaptiveTheme`**. It is the only one of the 15 draw
procedures in the file that skips the theme prologue — the other 14 all
open with `@emlSetAdaptiveTheme: .vpW, .vpH`.

So the forest plot inherits whatever ambient font size the Picture window
happens to hold: Praat's default in a clean session, or a leftover from any
EML figure drawn earlier in the same session (including
`.facetBodySize` from a histogram facet, `eml-draw-procedures.praat:3185`).
Its margins — and therefore its box position, tick placement and label
placement — are non-deterministic across runs. That is a Rule 2 exposure of
a different shape than Defect B's: not a mid-panel change, but an unset
ambient.

### DISAGREE — the proposed fix is unsafe as written

`@emlDrawAlignedMarksBottom` is not self-contained. Its first line reads
two globals, and its sixth reads a theme output:

    if emlShowTicksX = 0 and emlShowAxisValuesX = 0   ; line 1209
    Colour: emlSetAdaptiveTheme.tickColor$            ; line 1213

Those are set by `@emlInitDrawingDefaults`
(`eml-graph-procedures.praat:331, 333`) and `@emlSetAdaptiveTheme`
(`:455`) respectively.

The shipping entry path never calls either. `scripts/eml-lmm.praat` includes
the graphs libraries (lines 33–36) but contains no `@emlInitDrawingDefaults`
and no `@emlSetAdaptiveTheme`; it reaches the plot at line 95 —
`elsif clicked = 2 ... @emlWaldCI: 0.95 / @emlDrawLMMForest`. Tree-wide,
`@emlInitDrawingDefaults` has exactly one caller, `scripts/eml-stats-demo.praat:54`.

Empirically verified in the sandbox (Praat barren, this session):

    if emlShowTicksX = 0 and emlShowAxisValuesX = 0
    →  Error: Unknown variable: « emlShowTicksX      (exit 255)

Consequence: applying the handoff's one-line change and then opening the LMM
tool in a fresh Praat session and clicking "Coefficient plot" **aborts the
script**. The current defective code has no such dependency — it renders,
badly. The fix as specified trades a cosmetic defect for a hard failure on
the plugin's own shipped path.

### Severity, restated

Handoff says "cosmetic-but-visible, no numerical error." Cosmetic is right
for the tick values. But the missing theme prologue means the forest plot
is also the one EML figure whose layout depends on prior session state, and
it bypasses the palette and typography every other figure uses. That is a
consistency defect, not just an aesthetic one.

---

## 2. Defect B — vibrato drawing family

### Not actionable in this plugin

`eml-vibrato-procedures.praat` **does not exist anywhere in the plugin
tree**. There is no `vibrato/` directory; `find . -iname "*vibrato*"`
returns nothing. `graphs/` holds four files only:
`eml-annotation-procedures.praat`, `eml-draw-procedures.praat`,
`eml-graph-procedures.praat`, `eml-graphs-form.praat`.

This corroborates the registry work completed earlier in this session,
which marks `vibrato/eml-vibrato-procedures.praat` as NOT PRESENT IN THIS
PLUGIN TREE and retains its 11 rows as a record while excluding them from
the 241-procedure total.

The handoff diagnosed Defect B against PraatGen's PKB `.txt` copy, which
still ships the file. The analysis may well be correct on its own terms —
the quoted `emlVibratoDrawCoV` block does change ambient size three times
inside one coordinate sequence, and the `Text special:` fix pattern is the
right one. But §6's instruction ("fix in the plugin, bump the plugin file
version") cannot be executed: there is nothing here to edit or version.

This is itself a finding worth returning to PraatGen. Either the vibrato
tool was removed from the plugin and the PKB copy is stale, or it lives in a
separate repository. Until that is resolved, the PKB is shipping library
source that has no corresponding plugin origin — which is exactly the drift
the §0 sync guarantee is meant to prevent.

---

## 3. Handoff sections I agree with without qualification

- **§0** — fix in plugin, never in `pkb/`. Correct, and the reason Defect B
  stalls rather than getting patched locally.
- **§1** — both rule statements, and the insistence that they are separate
  rules with different mechanisms. The 0–87.3 dB worked example is accurate.
- **§4.4** — `pkill -f` matching the invoking shell's own command line.
  Real, and a genuine time-saver.
- **§5** — the five other `Marks` occurrences are correctly classified as
  non-defects. Confirmed independently: the tree-wide sweep over `.praat`
  sources returns only line 3941.
- **§7** — the defect class ("a file states a prohibition, then uses the
  prohibited construct in a block not labelled WRONG") is a good sweep.

---

## 4. What remains to be done

Ordered. Items 1–3 are one unit of work; do not ship 3 without 1.

1. **Add the theme prologue to `emlDrawLMMForest`.**
   `graphs/eml-draw-procedures.praat`, at the top of the procedure body
   (after `.figW` / `.figH` are known, before `Erase all` at 3907):
   call `@emlSetAdaptiveTheme: .figW, .figH` and set
   `Font size: emlSetAdaptiveTheme.bodySize`, matching the pattern used by
   the other 14 draw procedures. Decide at the same time whether
   `@emlInitDrawingDefaults` belongs in `scripts/eml-lmm.praat` or whether
   `emlDrawLMMForest` should guard with `variableExists()` — the
   `emlShow*` globals are not theme outputs and `@emlSetAdaptiveTheme`
   does not set them.

2. **Replace the bare marks call.** Line 3941 becomes
   `@emlDrawAlignedMarksBottom: .xlo, .xhi, 5, 0`. Safe only once item 1
   guarantees the globals exist.

3. **Verify empirically, not by assertion.** Two runs of the LMM tool from a
   cold Praat process: (a) straight to "Coefficient plot" — must not error,
   must produce round-number x labels; (b) after drawing an unrelated EML
   figure first — layout must be identical to (a). The second run is the one
   that catches the ambient-font regression, and neither the handoff nor
   ordinary use would surface it.

4. **Version bump.** `graphs/eml-draw-procedures.praat` v1.19 → v1.20, with
   a one-line entry in the file's own version history naming both changes
   (marks call and theme prologue). No arguments or return variables change,
   so §6.3 needs no declaration.

5. **Return two items to PraatGen**, not one:
   - the resync notice (file + new version) per §6.2;
   - the Defect B scope finding: `eml-vibrato-procedures` is in the PKB but
     not in the plugin. Ask which is authoritative before anyone tries to
     fix it in either place.

6. **Registry note.** §6.2 also asks that `EML_PROCEDURE_REGISTRY.md` be
   updated. It already has been — rewritten and reconciled this session
   (241 documented / 404 total, `reg-reconcile.py` exit 0). The upload to
   project knowledge is blocked on project capacity (1,994,710 / 2,000,000
   tokens; the write needs ~9,862). Nothing in this handoff changes a
   procedure signature, so no registry row moves; the blocker is
   pre-existing and separate.

---

## 5. Not in the handoff, surfaced by the verification

`emlDrawLMMForest` deviates from Rule 34 (procedure-first) more broadly than
the marks call alone. It hardcodes `.figW = 6.5`, the marker size
`Paint circle (mm): "Black", .est, .y, 2.6`, the CI cap half-height `0.13`,
the label offset `0.30`, and calls `Grey` / `Black` directly rather than
drawing colours from the palette. It also inlines its own label
sanitization (four `replace$` calls at 3931–3934) where `@emlSanitizeLabel`
exists.

None of this is in the handoff's scope and none of it is a rendering bug
today. Flagging rather than fixing, per Rule 35's out-of-scope clause — it
is one procedure's worth of work and belongs in its own pass, not folded
into a two-line drawing fix.
