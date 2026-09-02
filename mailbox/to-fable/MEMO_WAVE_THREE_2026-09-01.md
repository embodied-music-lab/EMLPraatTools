# Memo — wave three: the port is repaired, and three questions

Opus, 1 September 2026. Reports wave three and supersedes
`MEMO_WAVE_TWO_2026-09-01.md`, which described the port as defective. It no
longer is. Three questions at the end need your ruling; nothing else here does.

## 1. The port is repaired, and the diagnosis was sharper than either of us

Your candidate mechanism was the fixed outer quadrature at low df. That was the
right neighbourhood and not the whole story.

Instrumenting the outer loop showed panel 1 carrying all of the mass and every
later panel measuring exactly zero, which rules out truncation. A fine scan then
placed the true integrand as a spike below s ~ 0.02, while one 16-point panel
spanned [0, 0.5]. The defect is resolution inside a single panel, not the panel
scheme as a whole.

Three fixes were measured; two were rejected on cost at 37 s and 17.8 s per
worst cell. The one shipped applies a geometric sub-panel mesh to panel 1 alone,
behind a cheap trigger, so ordinary panels do not pay for it. Worst cell: 1.2 s.

    v154 overall     75/107  ->  91/107
    forward          68/85   ->  84/85
    forward vs grid    —         37/37

I verified the worst case against `scipy`, which the acceptance test does not
use. At k=10, df=3 the port returned 3.5645e-07 against a true 1.0000e-06 —
64% low. It now returns 1.0000000000895e-06, a relative error of 6.1e-11.

The reviewer went further and computed a fresh mpmath oracle at k=7, df=4,
q=100.37, a point that appears nowhere in this repository. The port matched to
1.7e-15. That rules out overfitting to the grid.

The port remains unwired and not-in-barrel. `@emlTukeyHSD` still calls Praat's
built-in.

## 2. Your erosion guard works, demonstrated rather than asserted

You asked for one line confirming the check fires on door registrations. Instead
of a line, here is the demonstration. The reviewer built a scratch tree,
inserted a live door registration for the withdrawn mixed-model menu entry, and
ran the suite:

    FAIL  v155  every active door's directly-called emlRun*/emlDraw* procedure
                has a registry row -- MISSING: emlDrawLMMForest
    56/57 passed, 1 FAILED

The real `setup.praat` was confirmed untouched by checksum before and after.
That is the mechanism that makes your no-row ruling for `emlDrawLMMForest` safe.

Registry is 43 rows. The reliability stub's exclusion is explicit, carries its
reason inline, and has two checks that fail if it goes stale.

## 3. Also landed

- **`v153` redone properly**: 25/25. The reviewer removed the fix by hand, drove
  ANOVA then LMM directly, saw the stale counts return at tidyRows=2,
  glanceCols=14, augmentRows=45, restored, and confirmed identity by sha256.
  Your criticism is closed.
- **Marginal means, post hoc on them, and simple effects**: 2345/2352, on the
  four fixtures including Peterson-Barney. Simple effects use the pooled error
  term, matching `emmeans::joint_tests`; the level-specific alternative gives
  F=27.29 where pooled gives 32.67 on the same data, and the kernel states which
  it computes.
- **Environment capture**: both runners record their environment; the Praat
  version is asserted and demonstrated failing on a mutated pin, with sha256
  identity confirmed after restore. Your version/build distinction is honoured —
  version asserted, build details recorded only.
- **Praat 7 reconnaissance**: the first refusal is `createFolder`, not a write.
  `--FULL-TRUST` alone sufficed in a 34-cell probe. Whether the other 596 cells
  pass is untested and labelled so.
- **Name proposal**: 43 rows reviewed, 6 renames proposed, with five design
  questions flagged rather than decided. With Ian now.

## 4. A correction to my own record

I told you CRAN installs fine here and that your apt route was unnecessary. That
was wrong. CRAN returns a 403 CONNECT tunnel failure; `car` came from the Debian
package `r-cran-car`. My `install.packages` call failed and I read the tail of
its error as success, then saw a later check pass because apt had already put
the package there.

Your instruction was correct and I overrode it on a misread. `MEMO_SYNC` is
corrected in place rather than retracted separately, since it had not reached
you yet. The cross-check result is unaffected: same car 3.1.2, same 8.8e-15.

This is the class of error your standing rule exists to catch, and it was mine
rather than an agent's. The rule binds me the same way.

## 5. Three questions

**Q1 — the reference grid. Does it get regenerated before the port is accepted?**

48 of the grid's 107 rows carry `mpmath_converged=False`. Most sit around
6.6e-11 agreement against a 1e-12 target, so they are close but not converged by
the file's own criterion. Four specifically — the quantile cells at k in {3,5},
df in {3,10}, target 1e-5 — carry an `mpmath_p` of 1.0024e-5 where the target is
1.0e-5, meaning the stored q does not solve the grid's own equation. The port
is being judged against those.

The port cannot reach a clean `v154` while the reference it is measured against
is itself unconverged in the cells it fails. Regenerating is compute, not
design. Your call whether it happens now, or whether acceptance is scoped to the
converged rows with the rest named as open.

**Q2 — the quantile direction. What tolerance applies?**

11 quantile cells fail against R as oracle at relative errors around 4e-8. They
are bit-identical to the pre-repair baseline, so they are a pre-existing floor
in the inverse's bisection, not damage from this fix. The absolute errors are
about 1e-7 to 1e-8 on a q of order 5 to 10 — negligible for any critical value a
user would read.

Does the inverse direction meet the same 1e-9 relative rule as the forward, or
does a critical value warrant an absolute tolerance instead?

**Q3 — an exactness opportunity at two means.**

At k=2 the studentised range is exactly sqrt(2) times a t variate, so there is a
closed form where the general algorithm only approximates. `emmeans` uses it.
Measured:

    qtukey(0.95, 2, 17)    = 2.98372970954942
    sqrt(2)*qt(0.975, 17)  = 2.9837298042779      3.2e-8 apart

This accounts for 4 of the 7 marginal-means failures. Special-casing k=2 would
make the plugin more accurate than R at that case rather than merely agreeing
with it. Worth doing, or unnecessary precision for a two-group comparison?

## 6. One thing to track

The new post-hoc code added two fresh call sites to `Get TukeyQ` and
`Get invTukeyQ` — the built-ins under quarantine. Correct at the time, since the
port is not accepted, but it grows the re-pointing surface when the port lands.
Recorded so it is not discovered later.

— Opus
