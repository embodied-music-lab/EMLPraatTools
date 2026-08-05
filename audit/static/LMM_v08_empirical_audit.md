# EML LMM (v0.8) — Empirical Differential-Testing Audit (Praat vs R)

**Date:** 2026-07-22 · **Auditor:** Claude (Anthropic), for Ian Howell / EML.
**Method:** the actual `eml-lmm` engine driven end-to-end in Praat 6.6.30 (barren), every output metric compared numerically against an **independently written** reference in R — lme4 1.1.35.1, lmerTest 3.1.3, pbkrtest 0.5.2 (installed here, not the delivery's own R scripts). Reusable harness: a Praat driver + an R reference + a per-metric tolerance comparator. Datasets: the delivery's 5 crossval sets **plus 4 generated here from fresh seeds** to guard against "tuned-to-pass," plus fit-path bug confirmations.

This complements the static review. Where the static pass could only say "no error found on a read," this pass answers "does the running engine reproduce lme4/lmerTest/pbkrtest?" — the check my adversarial critique said was missing.

---

## Headline

**The estimation + inference core is empirically correct.** Across 9 datasets and ~18–25 metrics each — fixed effects β, standard errors, residual σ, variance-component θ, Satterthwaite df, Kenward–Roger df, p-values, t-based Wald CIs, and marginal/conditional R² — Praat matches R to between **1e-8 and 9e-5 relative error**. This holds on the delivery's datasets *and* on independent datasets, for random intercepts, correlated random slopes (both signs of ρ), few-group and large-N designs, singular/boundary fits, and multi-level categorical fixed effects. The delivery's "full lme4/lmerTest/pbkrtest parity" claim is **corroborated by independent execution** — with **one exception surfaced by validating the reference itself: the R² for random-slope models is wrong by up to ~0.11 because the R *reference* uses a non-canonical formula and Praat faithfully reproduces it (see the Addendum).**

The two confirmed bugs are the Praat descending-loop defects from the static review — **verified here by crashing the real fit path**, not by reasoning. And one new practical limit surfaced: the dense-matrix Kenward–Roger path does not scale to N=2000.

## Parity results (ran both engines)

| Dataset | Structure | N | Groups | Verdict | Worst rel. err |
|---|---|---|---|---|---|
| D1 | `(1|g)` | 30 | 5 | **PASS** | 1e-8 |
| D2 | `(1|g)`, 2 fixed | 120 | 12 | **PASS** | 8e-8 |
| D3 | `(1+x|g)`, ρ<0 | 200 | 20 | **PASS** | 3.5e-5 |
| D4 | `(1|g)`, **singular** | 150 | 15 | **PASS** | 3.4e-8 (θ=0 vs 3.4e-8, both boundary) |
| D5 | `(1+x1|g)` | 2000 | 50 | **PASS (core)** | 1.6e-5; KR/R² did not finish (perf) |
| S1* | `(1|g)` | 120 | 8 | **PASS** | 3e-8 |
| S2* | `(1+x|g)`, **ρ>0** | 240 | 12 | **PASS** | 8.9e-5 |
| S3* | `(1|g)`, 4 groups | 48 | 4 | **PASS** | 5.8e-7 |
| S4* | 3-level categorical fixed effect | 120 | 10 | **PASS** | 2e-7 |

`*` = generated here from fresh seeds, independent of the delivery. Metrics per row: β, SE, σ, θ, Satterthwaite df, KR df, p, Wald CI (both bounds), R²m, R²c.

## Bugs confirmed on the real fit path

- **C1 (categorical interaction).** `y ~ A * B + (1|group)` on real data aborts inside `@emlModelMatrix` (`Get value: .row, .colName$` with a blank column name — the downstream consequence of the no-op descending loop at line 834). Confirmed crash.
- **H1 (≥2-slope `||`).** `y ~ x1 + x2 + (x1 + x2 || group)` aborts at the unset `emlParseFormula.reTerm..._k$` (from the no-op loop at line 326). **Controlled contrast:** the single-slope `y ~ x1 + (x1 || group)` on the same data fits cleanly (converged, N=216) — so the bug bites only at ≥2 slopes, exactly as predicted.

## Corrections to my own earlier findings (this run changed them)

- **M6 (boundary/singular df) — softened to near-refuted.** I worried the default Satterthwaite df was silently anticonservative at θ≈0. At the singular fit (D4) Praat's Satterthwaite **and** KR df both match R; the fit converges to the boundary and every downstream metric agrees. No anticonservative df manifested. (A pathological case might still exist, but the representative singular fit is fine.)
- **Wald-CI "discrepancy" — resolved, not a bug.** My first pass flagged Praat's Wald CI as off; that was *my* reference error — I compared against R's z-based `confint(method="Wald")`. Praat computes `β ± t(Satterthwaite df)·se`, which is the correct t-based interval and matches R's `qt`-based CI to ≤1e-4 across all datasets. Praat's choice is arguably better than lme4's default z interval.
- **General over-caution corrected.** My static "verified correct = only unfalsified on a read" caveat can now be upgraded for the tested surface: the core is **falsifiable and passed** against an independent implementation on independent data.

## New finding — scalability of the Kenward–Roger / R² path

At **N=2000** the fit and Satterthwaite df completed and matched R (1.6e-5), but `@emlKenwardRoger` did not finish in ~6+ minutes: it forms and inverts the dense N×N marginal covariance `V` (O(N³) ≈ 8×10⁹ ops at N=2000) and computes traces over it. This is a real practical ceiling — the KR SE/df and the R² (which also touches V) are unusable at large N without a sparse or Woodbury reformulation. Consistent with the delivery's own note ("Profile CI ~52 s for N=120; slow for N>500"). **Not a correctness defect** — a performance one — but it bounds where KR inference is usable.

## Honest scope limits of this pass

- **Profile CIs not batch-tested** (slow ~52 s each; the delivery flags the Sv-scale as 2×2-only). A targeted profile-CI check on a small dataset remains worthwhile.
- **Contrast codings:** only treatment coding exercised (S4). The static review's Helmert-scaling finding (M1) was **not** re-tested empirically — worth a direct check, since I predict it will *diverge* from R.
- **Parser edge cases** beyond interaction/`||`: `/` nesting, `^n`, `poly()`, `factor()` not driven through the fit path.
- **LMM only.** The main plugin's classical stats (t/ANOVA/MW/KW/correlation/regression) were validated earlier against scipy in isolation but not through this end-to-end harness; the same harness pattern extends to them vs scipy and is the natural next pass.

## Bottom line

Running the engine confirms what the static read could only suspect: **the hard mathematics (REML, Satterthwaite, Kenward–Roger) is correct and reproduces the *canonical* R reference on independent data.** The exception is **R²**, where validating the reference showed the formula itself is non-canonical for random slopes (Praat matches it, so Praat is wrong there too, by up to ~0.11). The other defects are the two Praat descending-loop bugs (crash-confirmed on real fits), the Cholesky-guard gaps from the static pass, and a large-N performance ceiling on the KR path. Fix order: **C1 → H1 → the Cholesky guards → the R² `mean(diag(ZΣZ'))` correction → the parity-affecting parser/contrast items (Helmert) → the KR scalability reformulation** for large N.

---

# Addendum — validating the R reference itself (not just Praat vs reference)

Parity is only meaningful if the reference is right. Ran the delivery's **own** R scripts (no re-authoring) and validated their computations against canonical packages.

**Which reference quantities are canonical (package functions) — parity to these is trustworthy:**
β, SE, σ, θ (`lmer`), Satterthwaite df (`lmerTest ddf="Satterthwaite"`), Kenward–Roger df (`pbkrtest ddf="Kenward-Roger"`), profile CIs (`confint(method="profile")`), Cook's D / hat values (`cooks.distance`/`hatvalues`). Praat's confirmed parity to these stands.

**Which are hand-rolled — one is wrong:**

**R² is not canonical Nakagawa for random-slope models.** The reference computes the random-effect variance as `sum(VarCorr$vcov[grp!="Residual"])` (= τ₀²+τ₀₁+τ₁²). The canonical Nakagawa RE variance (as in `performance::r2_nakagawa` / MuMIn) is `mean(diag(ZΣZ'))` (= τ₀² + 2τ₀₁·mean(x) + τ₁²·mean(x²)). These are equal for random *intercepts* and differ for *slopes*. Confirmed against `performance::r2_nakagawa` 0.15.x:

| Dataset | Structure | canonical R²m | author = Praat R²m | error |
|---|---|---|---|---|
| D1 | `(1\|g)` | 0.80161 | 0.80161 | 0.0000 ✓ |
| D3 | `(1+x\|g)` | **0.30331** | **0.41574** | **+0.1124** |
| D5 | `(1+x1\|g)` | 0.53996 | 0.53689 | −0.0031 |
| S2 | `(1+x\|g)` | **0.69699** | **0.64604** | **−0.0510** |

So Praat's marginal R² for random-slope models is **wrong by up to ~0.11**, not because of a Praat bug but because it faithfully reproduces a non-canonical R reference. Critically, v0.8's "Fix 2" *introduced* this: it replaced Praat's earlier BLUP-based `var(Z·b)` with `sum(VarCorr)` specifically to match this reference — moving it onto the flawed formula. (D5 happens to be close only because its slope predictor is near mean 0 / variance 1, making the two formulas coincide numerically.) Conditional R² is affected too (D3: canonical R²c = 0.9316).

**Fix:** in both `@emlJohnsonR2` and the R reference, compute the RE variance as `mean(diag(ZΣZ'))` (equivalently, the mean over observations of the model-implied random-effect variance), not the sum of variance components. This makes R²m/R²c match `performance::r2_nakagawa` for all RE structures. This supersedes v0.8 "Fix 2."

**DFBETAS reference is hand-rolled and unvalidated.** `validate-phase3d-dfbetas.R` computes `dfbeta_i = vcov_beta·x_i·r_i/((1−h_i)·σ²)` by hand — never checked against a canonical LMM-influence package (`influence.ME`, `car`). Combined with the static review's M5 (Praat's influence uses conditional residuals with fixed-effect scaling), the influence/DFBETAS "parity" rests on an unvalidated reference and needs a canonical cross-check before it can be trusted.

**Net:** validating the reference (rather than trusting it) upgrades the audit — the core estimation/df/CI parity is confirmed against *canonical* references and is genuinely correct, but the R² "parity" was against a flawed hand-rolled formula, so **Praat's random-slope R² is wrong (up to 0.11)** and the DFBETAS reference is unverified. This is the class of error that Praat-vs-reference testing structurally cannot catch when both sides share the flawed formula — only validating the reference exposes it.
