# Exhibit — the two-door regression, driven, and its acceptance leg

Verification session → executing session, 20 Aug 2026. Driven live under
Xvfb at current main; screenshots in Ian's hands, scripts available.

## The drive

Table: group A is exactly y = 2x, group B exactly y = 100 − 2x, same
twenty x values each. Per-group truth: slopes ±2, R² = 1. Pooled truth:
slope 0, R² = 0.

- STATS DOOR (Linear regression dialog, Group column = "group"): report
  prints the pooled model to the digit — y = 0.0000x + 50.0000,
  R = 0.0000, R² = 0.0000, F(1,38) = 0.0000, p = 1.000, N = 40. The
  group column is nowhere in the report. (Confirms dead-controls case 2
  exactly as ruled.)
- GRAPHS DOOR (scatter, same group column, regression on): per-group
  statistics — annotation box "A: r = 1.000, p < .001; B: r = −1.000,
  p < .001", two per-group fitted lines (the grouped branch computes
  per-group Pearson/Spearman and OLS/Theil-Sen at draw time).
- COMPOUND: regression door, then Draw on the "Analysis complete"
  pause: the preset hands groupCol$ to the drawing layer, so the user
  reads a pooled no-relationship report and immediately sees a figure
  annotated r = ±1. Each piece honest; the pair incoherent.

## Disposition (no new ruling required)

1. **One acceptance leg ADDED to item 10's matrix:** this exact drive —
   regression door, group column chosen, Draw — must end with the
   figure and the report describing THE SAME model, or the figure
   explicitly stating it draws a different one. The result store is the
   mechanism (the figure consumes the reported result instead of
   recomputing); this scenario becomes one of its validators.
2. **Ledger row now, fixedBy the unification commit.** No interim
   guard — item 10 gates the tag, so nothing ships carrying the
   discord; the row discloses it meanwhile. Same logic as the tree
   defects, by Ian's standing no-interim-fix ruling.
3. **Two report footnotes** (ride the dead-controls/6b work already
   ordered): (a) the direction gloss prints "Direction: negative
   (cases with higher x tend to have lower y)" against a slope of
   exactly 0.0000 and R = 0.0000 — it needs a zero/negligible branch
   ("no linear trend in this sample") instead of inheriting a sign
   from floating-point residue; (b) the case-2 relabel from the
   dead-controls ruling stands unchanged and is the stats door's half
   of this exhibit.

Observed with pleasure during the drive: the scatter's advanced page
already renders the 📊 Analysis / 📐 Axis / 🎨 Layout grouping with
paired range rows — the layout conventions arriving ahead of the formal
package.

— verification session
