# Return to PraatGen — drawing-defects handoff, plugin-side outcome

**From:** EML Praat Tools plugin working session, 3 August 2026
**To:** PraatGen maintenance (PKB owner)
**Re:** `EML_PLUGIN_HANDOFF_drawing_defects.md`, 3 August 2026
**Plugin tree:** `/root/eml_audit/plugin_EML_Praat_Tools`

Two items are owed back per §6.2 and per the assessment's §4 item 5: a resync
notice and a scope question. Three further findings surfaced during the fix
and are included because they are PKB-side, not plugin-side.

---

## 1. Resync notice (§6.2)

`graphs/eml-draw-procedures.praat` has been fixed in the plugin and the
version bumped. The PKB `.txt` copy is stale.

| | PKB copy | plugin tree (now) |
|---|---|---|
| version | 1.18 | **1.20** |
| lines | — | **4016** |
| md5 | — | **d370f12c0ff65f8c7ffe8dd5dd426cc3** |

Resync `pkb/eml-draw-procedures.txt` from the plugin file verbatim, carrying
the `# Version: 1.20` header, per the §0 sync guarantee.

### What changed in v1.20

All four changes are inside `procedure emlDrawLMMForest`. No other procedure
was touched. No argument list or return variable changed anywhere in the
file, so §6.3 needs no declaration and no registry row moves.

1. **Rule 1.** The bare `Marks bottom: 5, "yes", "yes", "no"` is replaced by
   `@emlDrawAlignedMarksBottom: .xlo, .xhi,`
   `emlSetAdaptiveTheme.targetTicksX, emlSetAdaptiveTheme.useMinorTicks`.
   This was the handoff's Defect A and the diagnosis was correct: the axis is
   a 12 %-buffered computed range, so five bare marks produce four arbitrary
   tick values.

2. **Rule 2 — theme prologue added.** See §2 below; the handoff was wrong
   about this and the correction matters for the PKB text as well as the
   code.

3. **Guard.** `if variableExists ("emlShowTicksX") = 0` → `@emlInitDrawingDefaults`,
   and `colorMode$` defaulted to `"color"` if unset. See §3 — without this the
   handoff's own one-line fix aborts the shipped path.

4. **Rule 34.** Line widths, marker size, tick colour, text colour and the
   series colour now come from `@emlSetAdaptiveTheme` / `@emlSetColorPalette`
   instead of hardcoded constants and bare `Grey` / `Black`; four inlined
   `replace$` calls are replaced by `@emlSanitizeLabel`.

Deliberately **deferred**, and named as such in the file's own history entry:
adopting `@emlDrawTitle`. It would require converting the figure from the
`Select outer viewport` + Praat-auto-margins model to the theme's
inner-viewport model, which is a layout change, not a drawing-rule fix.

### Line-offset explanation for anyone re-reading the handoff

The handoff's line numbers were taken from the PKB copy at v1.18. Against the
tree they run roughly **+390** (v1.18 → v1.19) and a further **+26** (v1.19 →
v1.20, the size of the new history entry at lines 8–26). Concretely:

| item | handoff (v1.18) | tree at v1.19 | tree at v1.20 |
|---|---|---|---|
| `procedure emlDrawLMMForest` | 3493 | 3883 | **3909** |
| bare `Marks bottom:` site | 3551 | 3941 | *(removed)* |
| comment block opens | — | — | 3894 |
| `endproc` | — | 3949 | 4016 |

This is the drift the §0 guarantee exists to make visible, and it worked — the
version header made the mismatch detectable rather than silent.

---

## 2. Correction to the handoff: the font-state claim was wrong

The handoff states:

> "Font state in this procedure is already correct: line 3479 sets
> `Font size: emlSetAdaptiveTheme.bodySize` from the theme… Nothing to do
> there."

Line 3479 in the PKB copy is the **last statement of the preceding
procedure**, `emlDrawGroupedBoxPlot`, immediately before its `endproc`. It is
not inside `emlDrawLMMForest`.

`emlDrawLMMForest` as shipped contained **no `Font size:` at all** and
**never called `@emlSetAdaptiveTheme`**. It was the only one of the 15 draw
procedures in the file without the theme prologue. The figure therefore
inherited whatever ambient font size the Picture window happened to hold —
Praat's default in a clean session, or a leftover from any EML figure drawn
earlier in the same session. Since ambient font size sets the Picture-window
margin widths, and margins set the world→page mapping, the box position, tick
placement and label placement were all non-deterministic across runs.

This is a **third shape of Rule 2 exposure**, distinct from the two the
handoff's §1 describes. Not a mid-panel size change and not a cross-panel
carry-over, but an **unset ambient**. Recommend adding it to the Rule 2
statement in the PKB, because it is invisible to the sweep pattern that finds
the other two: there is no `Font size:` call to find. The detection signal is
the *absence* of the prologue in a procedure that draws margin-dependent
chrome.

### Empirical proof, since the claim is a negative

Two renders of the same forest from a cold Praat process: (a) straight to the
coefficient plot with nothing else drawn; (b) after drawing an unrelated
2.4 × 1.8 in EML figure first.

    v1.19 (pre-fix)   old_a.png  84f9c7573990a0d2cd76cdefdfcbcd47  62947 B
                      old_b.png  ed1e8c56e85b7cc7b37aa1db6bdf6558  48017 B
    v1.20 (fixed)     run_a.png  dd6db65a5bbbc041bf205c769ba9b547
                      run_b.png  dd6db65a5bbbc041bf205c769ba9b547

Pre-fix the two renders differ by ~15 KB of PNG. Post-fix they are
byte-identical. The same test is sensitive enough to catch a regression, so
it is worth keeping as the acceptance test for this procedure.

---

## 3. Correction to the handoff: the proposed one-line fix aborts the shipped path

`@emlDrawAlignedMarksBottom` (`graphs/eml-graph-procedures.praat:1208`) is not
self-contained. Its first line reads two globals and its sixth reads a theme
output:

    if emlShowTicksX = 0 and emlShowAxisValuesX = 0     ; :1209
    Colour: emlSetAdaptiveTheme.tickColor$              ; :1213

`emlShowTicksX` / `emlShowAxisValuesX` are set only by
`@emlInitDrawingDefaults`; `tickColor$` only by `@emlSetAdaptiveTheme`. The
shipping LMM entry path calls neither. `scripts/eml-lmm.praat` includes the
graphs libraries but reaches the plot directly
(`elsif clicked = 2 … @emlWaldCI: 0.95 / @emlDrawLMMForest`). Tree-wide,
`@emlInitDrawingDefaults` had exactly one caller,
`scripts/eml-stats-demo.praat:54`.

Sandbox-verified, isolated snippet (Praat barren, this session):

    if emlShowTicksX = 0 and emlShowAxisValuesX = 0
    →  Error: Unknown variable: « emlShowTicksX        (exit 255)

So applying the handoff's change alone and clicking "Coefficient plot" in a
fresh session **aborts the script**. The defective code had no such
dependency — it rendered, badly. The fix as specified traded a cosmetic defect
for a hard failure.

The plugin now guards with the `variableExists (…) = 0` self-heal idiom
already used inside `@emlSetAdaptiveTheme` itself (`:366`, `:369`) and 20+
times across the graphs files.

### 3A. Whole-procedure re-verification — the abort is earlier and broader

Added 4 August 2026. The snippet test above verified one line in isolation. To
check the claim end to end, the shipped `@emlDrawLMMForest` (v1.20, plugin
lines 3909–4016) was extracted verbatim, its two `variableExists` guard blocks
deleted (6 lines), the procedure renamed `@emlDrawLMMForestNoGuard`, and the
result driven cold — fresh Praat, fresh pref dir, three library includes, the
synthetic LMM state block, nothing else:

    emlShowTicksX defined at entry: 0
    about to call
    →  PRAAT ERROR: Unknown variable: « emlSubtitle$
       eml-graph-procedures.praat:411 — « if emlSubtitle$ <> "" »
       (no "returned OK" marker; process held open by the modal, timeout 124)

The conclusion holds — without the guard the shipped path aborts — but the
failure point named in §3 is not where it actually lands. Execution never
reaches `@emlDrawAlignedMarksBottom` at `:1209`. It dies ~800 lines earlier, in
the **theme prologue**, on a different variable.

`@emlSetAdaptiveTheme` reads four `eml*` globals. It self-heals two of them and
not the other two:

| Global | Read at | Guarded? | Seeded by |
|---|---|---|---|
| `emlPanelOriginX` | `:366` | yes — `variableExists` | `@emlInitDrawingDefaults` |
| `emlPanelOriginY` | `:369` | yes — `variableExists` | `@emlInitDrawingDefaults` |
| `emlSubtitle$` | `:411` | **no** | `@emlInitDrawingDefaults` only |
| `emlFont$` | `:460`, `:461` | **no** | `@emlInitDrawingDefaults` only |

Its header block declares `Arguments:` and a 30-item `Outputs:` list, and no
`Requires:` line at all. The two guards at the top of the procedure therefore
read as a cold-start contract that the rest of the body does not honour, and
the signature discloses neither dependency.

By contrast `eml-draw-procedures.praat` does declare the dependency — 14
procedure headers carry `# Requires: @emlInitDrawingDefaults (or manual global
initialization).` The convention exists; `@emlSetAdaptiveTheme` is outside it.

This does not affect the shipped plugin: `@emlDrawLMMForest`'s guard calls
`@emlInitDrawingDefaults`, which seeds all four, and the cold arm runs clean
(exit 0, PNG byte-identical to the warm arm). It is a live exposure for any
*other* cold caller of `@emlSetAdaptiveTheme` — 53 call sites across five
files, against exactly one tree-wide call to `@emlInitDrawingDefaults`
(`scripts/eml-stats-demo.praat:54`).

**Recommendation for the PKB (revised twice; second revision 4 August 2026,
on the library author's ruling).** The shared-global dependency chain between
these procedures is **intentional architecture, not a defect.** Procedures in
this library call other procedures and read state seeded by
`@emlInitDrawingDefaults`; that is the design, and nothing below asks for it
to change. Retracted accordingly: the earlier recommendation to extend the
`variableExists` self-heal in `@emlSetAdaptiveTheme` to `emlSubtitle$` and
`emlFont$`. Adding self-heals would push the library *toward* per-procedure
independence and away from its own model.

What survives is a **documentation** point, and it is the smaller one. The
initialization contract is real and load-bearing, but `@emlSetAdaptiveTheme`
does not state it: no `Requires:` line, against the convention its own tree
uses 14 times in `eml-draw-procedures.praat`. Add the line. On the same
reasoning the two existing `variableExists` guards at `:366`/`:369` are the
anomaly rather than the missing pair — a caller reading the body could infer
self-sufficiency that the design does not intend. Either drop them or note in
the header that they are incidental.

The 53-call-sites-vs-one-init count below is retained as a **map of the
initialization contract's reach**, not as an exposure metric.

---

## 4. Scope question — Defect B has no target in this plugin

`eml-vibrato-procedures.praat` **does not exist anywhere in the plugin tree.**
There is no `vibrato/` directory; `find . -iname "*vibrato*"` returns nothing.
`graphs/` holds exactly four files: `eml-annotation-procedures.praat`,
`eml-draw-procedures.praat`, `eml-graph-procedures.praat`,
`eml-graphs-form.praat`.

This corroborates the registry work completed in this session, which marks
`vibrato/eml-vibrato-procedures.praat` as NOT PRESENT IN THIS PLUGIN TREE and
retains its 11 rows as a record while excluding them from the 241-procedure
total.

The Defect B analysis may well be correct on its own terms — the quoted
`emlVibratoDrawCoV` block does change ambient size three times inside one
coordinate sequence, and `Text special:` is the right fix pattern. But §6's
instruction ("fix in the plugin, bump the plugin file version") **cannot be
executed**: there is nothing here to edit or version.

**Deferred by the library author, 4 August 2026 — "we cannot worry about
vibrato for notes, for now."** The question below is no longer blocking; it
is recorded so that whoever picks Defect B up later does not have to
re-derive it.

**The open question:** is the PKB copy authoritative, or is the plugin?
Either the vibrato tool was removed from the plugin and the PKB copy is
stale, or it lives in a separate repository that the §0 sync guarantee does
not currently cover. Until that is resolved the PKB is shipping library
source with no corresponding plugin origin — exactly the drift §0 is meant
to prevent.

Do **not** patch the PKB copy in place to close Defect B. That would make the
PKB the origin for that file, which is the failure mode §0 forbids. This
constraint holds whenever the work resumes.

---

## 5. Three further PKB-side findings

### 5.1 Calling a theme-dependent procedure cold hangs the sandbox — exit-124 signature

Retitled 4 August 2026. This entry originally read as a dependency complaint;
the dependency is by design (see §3A). What is worth keeping is the *failure
signature*, which is a sandbox-debugging trap independent of whose fault the
dependency is.

`@emlSetAdaptiveTheme`'s tail executes `'emlFont$'`, which is set **only** by
`@emlInitDrawingDefaults`. Calling `@emlSetAdaptiveTheme` standalone therefore
raises an error. Under `praat --new-send` with Xvfb that error becomes a modal
dialog and the process hangs: **exit 124, empty stderr, no output file, log
truncated at the last line before the call.** That signature is worth adding
to the PKB's sandbox-debugging notes, because it looks like a timeout or a
hung X server and is neither.

This bit the verification harness, not the plugin — the forest's new guard
calls `@emlInitDrawingDefaults` first. But anyone writing a minimal repro that
calls `@emlSetAdaptiveTheme` directly will hit it, and the failure gives no
diagnostic.

### 5.2 Bare `Marks` in a dev wireframe

    dev/tutorial-wireframes-v09.praat:582:  demo Marks left: 4, "yes", "no", "no"

Same defect class as Defect A, Demo-window variant, non-shipping file.
Flagged, not fixed — out of the handoff's scope. Worth noting that the
handoff's §5 sweep and the assessment's independent sweep both covered only
Picture-window `Marks`; the `demo Marks` variant needs its own pattern.

Tree-wide sweep otherwise returns **no live bare `Marks` in library source** —
only comment references at `eml-draw-procedures.praat:9`, `:106`, `:4000`.

### 5.3 The PKB registry copy is stale in at least one row

`EML_PROCEDURE_REGISTRY.md` in project knowledge records
`dev/tests/eml-test-helpers.praat` as **v1.0 — 9 procedures**. The tree has
**v1.2 — 11 procedures** (adds `@emlTestAssertEqualRel` and `@emlTestSkip`).

The reconciled registry produced in this session already carries the correct
row. Its upload is blocked on project-knowledge capacity (1,994,710 / 2,000,000
tokens against a ~9,862-token write), caused by two identical 59-file
reference batches uploaded 2026-06-03T21:31 and 2026-06-04T01:35. That blocker
is pre-existing and separate from this handoff; nothing here changes a
procedure signature, so no registry row moves on account of v1.20.

---

## 6. Summary of what PraatGen owes vs. what the plugin owes

| item | owner | state |
|---|---|---|
| Resync `eml-draw-procedures.txt` to v1.20 | PraatGen | **owed** |
| Answer: is vibrato PKB-authoritative or plugin-authoritative? | PraatGen | deferred by the author, 4 Aug 2026 — see §4 |
| Add "unset ambient" as a third Rule 2 shape | PraatGen | recommended |
| Document the `@emlDrawAlignedMarks*` global deps with `Requires:` lines (they already carry them in `eml-draw-procedures.praat` — this is about the `eml-graph-procedures.praat` copies) | PraatGen | recommended |
| Add a `Requires: @emlInitDrawingDefaults` line to `@emlSetAdaptiveTheme`'s header — documentation only; the dependency itself is by design — see §3A | PraatGen | recommended |
| Add the exit-124 modal-dialog signature to sandbox notes | PraatGen | recommended |
| Registry row `eml-test-helpers.praat` v1.0/9 → v1.2/11 | plugin session | done locally, upload blocked |
| Defect A fix + Rule 2 + Rule 34 pass | plugin | **done, v1.20** |
| `dev/tutorial-wireframes-v09.praat:582` | plugin | flagged, deferred |
