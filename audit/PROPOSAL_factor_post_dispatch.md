# Proposal — factor the post-dispatch annotation block to file scope

Written 11 August 2026, for author approval before any edit. Nothing in this
proposal has been applied.

**The ask:** move 100 lines out of `@emlGraphsWorkflow` into a file-scope
procedure so a harness can drive the real code instead of a hand-copy of it.

---

## 1. Why, in one paragraph

`harness/disclosure/probe_formpath.praat` is titled as a reproduction of "the
form's sequence" around the post-dispatch block. It passes
`emlDrawViolinPlot.axisYMin`/`axisYMax` where the form passed
`valueMin`/`valueMax`. It therefore tested a **corrected copy** of the code it
claimed to be testing, and would have gone on passing however wrong the form
became — which is exactly what happened, for however long §2b had been live.
The defect was not found by the probe that exists to find it. It was found by
reading the block while migrating something else.

A hand-transcription is not a test. The repair is to make the block callable.

---

## 2. What makes this cheap, and it is not obvious

**`eml-graphs-form.praat` is already a library.** Measured:

- 193 top-level executable lines, all of them variable and array
  initialisation (`graphTypeName$[7] = "Violin Plot"`, `typeToMenu[13] = 16`,
  and so on). The last is line 621.
- **No `form:` and no `beginPause:` at top level.** The dialogs are all inside
  procedures.
- **`@emlGraphsWorkflow` is never called from within the file.** It is the
  documented single entry point, invoked by the menu wrapper.

So a probe can `include` the form file today, get every procedure defined and
no dialog, and call whatever is at file scope. That is the same property
`@emlGraphsDrawWithLegendRoom` was factored out to exploit — its own header
says it is at file scope "so that the loop and the draw inside it can be
driven by a probe without a dialog."

**Which means `probe_formpath.praat` never needed to transcribe anything.**
The transcription was avoidable when it was written. That is the strongest
argument here: this is not new architecture, it is finishing a pattern the
codebase already established and then stopped applying.

---

## 3. The exact change

### Move

Lines **7325–7424** of `plugin/graphs/eml-graphs-form.praat` — the whole
`if annotate = 1 ... endif`, from `# --- Read axis ranges ---` through the
matrix panel call. 100 lines.

### To

A new procedure placed beside `@emlGraphsDrawWithLegendRoom` (which ends at
2226), before `procedure emlGraphsWorkflow` at 2227:

```praat
# ============================================================================
# @emlGraphsPostDispatchAnnotations
# ============================================================================
# The POST-DISPATCH (ANNOTATE) stage of @emlGraphsWorkflow. Draws brackets,
# the omnibus block, and the comparison matrix panel onto the figure
# @emlGraphsDrawWithLegendRoom has just finished.
#
# At file scope, and no parameters, for the same reason
# @emlGraphsDrawWithLegendRoom is: so a probe can drive THIS code rather than
# a copy of it. harness/disclosure/probe_formpath.praat transcribed this
# block by hand and silently corrected it in the process -- it passed
# axisYMin where the form passed valueMin -- so it tested a version of the
# block that was never shipped and went on passing while the shipped one
# dropped the statistics box off the figure. See §2b.
#
# Reads and writes main-body scope. Praat has no other option here and it is
# not a compromise: a bare name written inside a procedure IS the global of
# that name, so every assignment below behaves exactly as it did inline.
# ============================================================================
procedure emlGraphsPostDispatchAnnotations
    ... the 100 lines, unchanged ...
endproc
```

### Call site

Lines 7325–7424 become:

```praat
    # The whole of it is in @emlGraphsPostDispatchAnnotations, at file scope,
    # so the annotation stage can be driven by a probe without a dialog.
    @emlGraphsPostDispatchAnnotations
```

**No other edit. Not one line of the block's body changes.**

---

## 4. Why it is safe, checked rather than assumed

| risk | check | result |
|---|---|---|
| A procedure-local (`.foo`) inside the block would silently re-namespace | regex for `\.\w+` not preceded by a word character, over the block with comments stripped | **NONE**. Every name in the block is bare. |
| A bare assignment inside a procedure creating a local instead of writing the global | Praat semantics: only a leading dot makes a local | all 10 writes stay global |
| Forward reference | Praat resolves procedure names at CALL time, not parse time | no ordering constraint; placed before the caller anyway for readability |
| Something else in the file writes these globals between dispatch and here | the block is the only writer of `annotX*`, `annotY*`, `annotYRange`, `omnibusCorner$` | unchanged by the move |

### The full scope surface

**Writes (10):** `annotXMin`, `annotXMax`, `annotYMin`, `annotYMax`,
`annotYRange`, `annotBlockN`, `annotBlockLabel$[]`, `annotBlockDraw$[]`,
`annotTextN`, `omnibusCorner$`.

**Reads (16 + accessors):** `annotate`, `graph_type`, `valueMin`, `valueMax`,
`annotBracketN`, `annotMatrixN`, `annotTextN`, `annotTextLabel$[]`,
`annotBlockN`, `dataYMax_forAnnotation`, `matrixPanelHeight`, `figure_width`,
`figure_height`, `matrixGap`, `totalCanvasHeight`, `colorMode$`; plus
`emlDraw{BarChart,ViolinPlot,BoxPlot,GroupedViolin,GroupedBoxPlot}.axis{X,Y}{Min,Max}`
and `emlSetAdaptiveTheme.{annotSize,matrixSize}`.

**Calls:** `@emlDrawAnnotations`, `@emlDrawAnnotationBlock`,
`@emlDrawMatrixPanel`.

That surface is the probe's fixture. It is 16 numbers and a table.

---

## 5. What replaces `probe_formpath.praat`

```praat
include ../../plugin/graphs/eml-graphs-form.praat    ; library, no dialog

; ... build the table, run @emlBridgeGroupComparison for real ...
graph_type = 7
annotate = 1
valueMin = 0
valueMax = 0
Erase all
@emlDrawViolinPlot: tblId, ...
@emlGraphsPostDispatchAnnotations                     ; THE SHIPPED CODE
@emlAssertFullViewport
Save as 300-dpi PNG file: out$
```

The probe can no longer disagree with the form, because there is nothing left
to disagree with. And the existing corner assertions
(`FORMCORNER brackets disclosure=... omnibus=...`) keep working — they read
globals the block writes.

---

## 6. What this then lets the R script assert (v33)

Not proposed for approval here, but it is why the refactor is worth doing
rather than just tidy:

1. **The box is on the figure.** Render the omnibus-only case twice, once
   with `annotBlockN` forced to 0. The two PNGs must DIFFER, and the
   differing pixels must fall inside the plot frame. Before the fix they were
   identical — that is the regression guard §2b currently lacks.
2. **The block never receives a degenerate range.** Assert
   `annotYMax > annotYMin` on every type × (brackets, no brackets) × (auto,
   explicit range). 13 types is overkill; 6, 7, 9, 11, 12 is the surface.
3. **The second latent instance.** Line 7383 still reads
   `annotYRange = valueMax - valueMin`. That is correct *today* only because
   its single consumer is gated on `annotBracketN > 0`, which is exactly when
   the pre-dispatch resolver ran. It is the same hazard as the one just
   fixed, one gate away from being live, and right now the only thing holding
   it is a comment. Once the block is callable, an assertion can hold it
   instead.

---

## 7. What I am NOT proposing

- No change to any of the 100 lines' behaviour.
- No parameterisation of the block. Passing 16 globals in would be a bigger
  edit with more ways to get it wrong, and it buys nothing a probe needs.
- No touching `@emlGraphsWorkflow`'s other stages.
- No deletion of `probe_formpath.praat` in the same change. It should be
  rewritten against the real procedure, but as a separate commit, so the
  before/after of the probe is legible on its own.

---

## 8. Verification before it would be offered as done

Same bar as the last two commits:

- 39/39 stress, 52/52 disclosure, 10/10 determinism **byte-identical**,
  357/357 phase1, 8221/8221 R, both round trips PASS.
- Determinism is the one that matters most: a pure code move must not change
  a single pixel, and that suite is the only thing in the tree that can say
  so without qualification.

---

## Decision needed

Approve, decline, or amend §3's boundaries. If declined, §2b stays fixed —
the fix is already committed and does not depend on this — but every future
check on that block keeps testing a copy.
