# EML Linear Mixed Models (v0.8) — Static Code & Design Review

**Scope:** `eml-lmm.praat` (4,182 lines), `eml-optimizer.praat` (2,360), `eml-linalg.praat` (319), plus `DESIGN_EML_LINEAR_MIXED_MODELS.md`. Static review only — no R/lme4 runs; correctness reasoned from the code and the documented design invariants, with targeted `praat_barren` parse/trace confirmation of the top findings.
**Date:** 2026-07-22 · **Reviewer:** Claude (Anthropic), for Ian Howell / EML.
**Method:** four parallel focused reads (linalg / optimizer / core estimation / inference), findings cross-checked and the three most severe re-confirmed by direct reading.

---

## Executive summary

**The hard part is right.** The REML/ML profiled-deviance engine matches lme4's modular.R construction exactly (Λ'Z'ZΛ + I, Cholesky, downdated Schur complement `dd = X'X − RZX'RZX`, β/u recovery, profiled σ², ML-vs-REML `n` vs `n−p`, log-det factor of 2). The inference math the handoffs claim parity for is faithfully implemented and matches the R sources on a *static* reading: the numerical Satterthwaite uses lmerTest's `(θ, σ)` un-profiled parameterization with `vcov_varpar = 2·H⁻¹`; Kenward–Roger uses `R_r = (V⁻¹X)'Σ_r(V⁻¹X)` (V⁻¹, not P), the expected-info `0.5·tr(PΣ_rPΣ_s)`, the PhiA second-derivative `QQ − R A R` term, and KR df = variance-parameterized Satterthwaite (not Satterthwaite·eStar); R²'s RE variance sums off-diagonal covariances. Treatment/sum/polynomial contrasts, the triangular solves, and BOBYQA's control flow all check out. This is a genuinely sophisticated, careful build.

**The defects cluster in three places, none in the estimator core:**
1. **Praat descending-`for` traps** — the language's for-loops only increment, so a `for i from N to 1` loop silently runs zero times. Two of these exist, and one **breaks the single most common LMM design (factor interactions)** outright.
2. **Numerical-robustness guards** — a Cholesky pivot guard that admits zero pivots, unchecked factorization-error propagation at two call sites, and an unclamped non-finite objective value the optimizer can't see.
3. **R-parity gaps on less-tested paths** — Helmert contrast scaling, ML-vs-REML profile CI, influence-diagnostic scaling, and boundary/singular df.

Both the CRITICAL and HIGH-1 bugs escaped the 258-assertion suite for the **same reason the earlier plugin bugs did**: no test exercises the affected data shape (no categorical-interaction fit; no ≥2-slope uncorrelated RE).

Counts: **1 Critical, 3 High, 7 Medium, 4 Low.**

---

## CRITICAL

### C1 · Descending `for` loop breaks every factor interaction
**`eml-lmm.praat:834` (`@emlModelMatrix`, fails at `:872`)**

```praat
for .s from .interOrder to 1        ; ← never executes when interOrder ≥ 2
    .compCol'.s' = (.remaining mod .interNCols'.s') + 1
    ...
endfor
...
.ccIdx = .compCol'.s'               ; :872 — reads an unset variable
```

Praat `for` loops only increment, so `for .s from .interOrder to 1` runs **zero** iterations for any interaction order ≥ 2. The mixed-radix decomposition of the interaction column index never runs, `.compCol1/.compCol2/…` are never assigned, and the fit aborts with `Unknown variable: .compCol1` for **any** model whose fixed part contains a factor interaction — e.g. `y ~ Condition * Sex + (1|subject)`, the most common design in this lab's work. (Continuous×continuous interactions don't crash but get a blank column label.) Tell-tale: the *value* loop 20 lines down is correctly written `for .s from 1 to .interOrder` — the author knew the ascending form; this is a transcription slip in the label/decomposition loop. The parse-level tests pass because they never build X, and no fit-level test uses a categorical interaction.

**Fix:** reverse the index inside an ascending loop — `for .sRev from 1 to .interOrder / .s = .interOrder - .sRev + 1 / …` — for both the decomposition and the label-build block (838–853).

---

## HIGH

### H1 · Descending `for` loop corrupts `||` (uncorrelated) random effects with ≥2 slopes
**`eml-lmm.praat:326` (`@emlParseFormula`)**

```praat
.oldN = .reNTerms'.j'
for .k from .oldN to 1               ; ← no-op when oldN ≥ 2
    .reTerm'.j'_'.kp'$ = .reTerm'.j'_'.k'$
endfor
.reTerm'.j'_1$ = "1"
```

Same trap. For a single slope (`oldN=1`) the loop runs once and works — which is why `(x || group)` passes. For `(x + z || group)` the shift is a no-op, so `.reTerm..._1$` is overwritten to `"1"` (destroying the first slope), the top slot is never set, and `@emlRandomEffectsZ` then crashes reading the missing term. Confirmed live: `reTerm1_1` clobbered to `[1]`, `reTerm1_3` unset. (Secondary: the block never checks for an explicit `0`, so `(0 + x || g)` would also wrongly inject an intercept.) **Fix:** reversed-index ascending loop; guard the auto-intercept against an explicit `"0"`.

### H2 · Cholesky pivot guard admits a zero pivot → silent division by zero
**`eml-linalg.praat:62`**

```praat
if .diag < 0                         ; should be <= 0
    .error$ = "Matrix is not positive definite ..."
...
.l## [.j, .j] = sqrt (.diag)         ; sqrt(0) = 0
...
.l## [.i, .j] = (.a## [.i, .j] - .sum) / .l## [.j, .j]   ; :74 — /0 → undefined
```

A positive-*semidefinite*/singular matrix has a zero pivot, which passes `< 0`; `sqrt(0)=0` is stored on the diagonal and line 74 divides by it, producing `undefined` that propagates silently rather than raising the "not PD" error. This is the realistic collinear-X / rank-deficient case (the fixed-effects Schur complement `dd = X'X − RZX'RZX` goes singular whenever X has collinear columns), and a tiny positive rounding pivot also survives and is amplified. **Fix:** `if .diag <= 0` (ideally a small relative tolerance `.diag <= tol·.a##[.j,.j]`).

### H3 · Cholesky return value used without checking `.error$` at two engine call sites
**`eml-lmm.praat:1305` and `:1594`**

```praat
@emlCholesky: .dd##
.rx## = emlCholesky.l##              ; :1305 — no error check
...
@emlCholesky: .rxSq##
.rx## = emlCholesky.l##              ; :1594 — no error check
```

When Cholesky fails (non-PD Schur complement — exactly the H2 case), `.l##` is partially filled/zero and is consumed directly by `solve#`/`transpose##`/`@emlTriangularLogDet`, turning a failed factorization into silent wrong betas / `undefined` deviance. The correct pattern (testing `emlCholesky.error$`) *is* used elsewhere (≈1199–1226) — these two sites just omit it. **Fix:** guard both call sites like the 1199–1226 pattern.

---

## MEDIUM

### M1 · Helmert contrasts scaled `1/j` vs R's integer `contr.helmert` → coefficients won't match lme4
**`eml-lmm.praat:530–535`** — column j is set to `−1/j` (rows ≤ j) / `1` (row j+1); R's `contr.helmert(3)` column 2 is `(−1,−1,2)`, this gives `(−0.5,−0.5,1)`. It's a *valid* orthogonal Helmert basis (same fitted values and variance components), but the fixed-effect coefficients and SEs are rescaled per column, so a tool advertising lme4 parity will silently disagree on `helmert` coefficients. (Treatment/sum/poly were checked and match R.) **Fix:** emit the integer form (`−1` rows 1..j, `j` row j+1, else 0).

### M2 · Optimizer never guards a non-finite (`undefined`) objective
**`eml-optimizer.praat` (post-evaluation sites, e.g. `:2004`) + `eml-lmm.praat:~1264`** — the objective's final `ln(2π·pwrss/n)` returns `undefined` if `pwrss` underflows to 0 (near-saturated fit). The optimizer has no finiteness test, and the wrappers' sentinel is `value >= 1e29`, which is **false** for `undefined` in Praat — so an `undefined` deviance passes straight through, poisons the BOBYQA interpolation model and the `if .f < .fopt` branches, and returns a garbage optimum with `convergence=0` (no error). Rare trigger, silent wrong result. **Fix:** clamp `if .f = undefined or abs(.f)=1/0 → .f = 1e30` after every evaluation (BOBYQA and Nelder–Mead), and guard `pwrss > 0` before the `ln`.

### M3 · Nelder–Mead converges on simplex diameter only; callers ignore the convergence flag
**`eml-optimizer.praat:176` (+ caller sites)** — the only stop test is parameter-space `diam < tol`, with every trial vertex re-projected onto the box. A reflected vertex that clamps onto an active bound can coincide with an existing vertex → degenerate simplex whose diameter never shrinks → the loop burns the full (200–300) `maxEval` and returns a not-converged point, while callers (profile-CI paths) take `xOpt` unconditionally. **Fix:** add a function-spread stop and have callers check `emlNelderMead.convergence`.

### M4 · Profile CI forces ML deviance even for REML fits
**`eml-lmm.praat:2612–2613`** — `emlLMM.useREML` is set to 0 for the whole profile, so a REML-fitted model's profile CIs for the RE SDs / correlation / σ are computed on the ML criterion. `lme4::confint(method="profile")` profiles the criterion the model was *fit* with (REML by default), so the reported CIs diverge from R (typically slightly narrower) for the common REML case. **Fix:** profile the fit's own criterion (use the REML devfun2 when the fit was REML), or document the ML-only behavior.

### M5 · Influence diagnostics mix conditional residuals/leverage with fixed-effect scaling
**`eml-lmm.praat:3935–3962`** — Cook's D and DFBETAS for the fixed effects are built from the **conditional** residual `y − Xβ − ZΛu` (shrunk toward 0 by the RE) and the augmented hat, then normalized by `p` (fixed-effect count). The exact one-step β deletion uses the **marginal** residual `y − Xβ̂` and the marginal fixed-effect hat `X(X'V⁻¹X)⁻¹X'V⁻¹`. As written, DFBETAS are understated and Cook's D mis-scaled, with bias growing in the RE variance. **Fix:** use marginal residuals/leverage for β-targeted diagnostics, or relabel these as conditional-fit influence and normalize by the combined effective df.

### M6 · Numerical Satterthwaite df is anticonservative and silently clamped at boundary/singular fits
**`eml-lmm.praat:2127–2210`** — this is the **default** df feeding every t, p, and Wald CI. At a singular random-slope fit (θ_r ≈ 0, common), `d(covβ)/dθ_r → 0`, dropping that component from the variance-of-variance → df **overestimated (anticonservative)**; the fully degenerate case is clamped to `1e6` (≈ z-test) with **no warning**. KR's variance parameterization degrades gracefully but isn't the default. **Fix:** at/near the boundary fall back to the KR variance-parameterized df (already implemented), or warn and refuse the silent `1e6`.

### M7 · linalg log-det unguarded; symmetry tolerance is fixed-absolute
**`eml-linalg.praat:90` and `:47`** — `emlTriangularLogDet` takes `ln(L_ii)` with no guard for `L_ii ≤ 0` (compounds H2: a slipped-through zero pivot poisons the deviance via `ln(0)=undefined`). Separately, the symmetry check uses a fixed `> 1e-10` absolute tolerance, which can false-reject a legitimately symmetric large-magnitude `Z'Z+I` (rounding in `mul##` accumulation) and is needlessly strict for tiny matrices. **Fix:** guard `L_ii ≤ 0` in the log-det; scale the symmetry tolerance to matrix magnitude (or symmetrize by construction).

---

## LOW

- **L1 · Dead code (~300 lines):** the analytical `@emlSatterthwaiteDF` (`eml-lmm.praat:1650–1966`) is never called — the numerical version feeds `dfBeta#`, and KR recomputes its own inline. Remove or clearly mark as an alternate estimator (Rule 35). It uses a *different* `(θ,σ²)` parameterization, so accidentally wiring it to `dfBeta#` later would silently change the df estimator.
- **L2 · Misleading residual code:** `@emlLMMResiduals` (`~3852`) comments "Pearson = raw/σ" but assigns `.pearson# = raw`, so `.raw#` and `.pearson#` are bit-identical. The value matches lme4's Gaussian/unweighted behavior — fix the comment or drop the redundant field.
- **L3 · Nelder–Mead init perturbation is one-directional** (`eml-optimizer.praat:123–127`): always `+step` then re-projected, so a start coordinate at/near an upper bound collapses the initial simplex in that dimension. Latent (current upper bounds are `1e30`); perturb away from the nearer active bound.
- **L4 · `@emlProfileCI` returns Wald (not profile) CIs for fixed effects** (`~3550`) — consistent with the stated invariant (profiling scoped to σ and RE SD/correlation), and the t-quantile is correct, but a user comparing to R's `confint(method="profile")` will see different β CIs. Document it.

---

## Verified correct (checked, no defect)

- **Profiled deviance (`@emlProfiledDeviance`, 1180–1264):** `A=Λ'Z'ZΛ+I`, `L=chol(A)` (the `+I` guarantees PD, so this Cholesky never fails even at boundary θ), `cu=L⁻¹Λ'Z'y`, `RZX=L⁻¹Λ'Z'X`, `dd=X'X−RZX'RZX`, β from `dd·β=X'y−RZX'cu`, `u=L⁻ᵀ(cu−RZXβ)`, `pwrss=‖y−Xβ−ZΛu‖²+‖u‖²`; ML `log|L|²+n(1+log(2π·pwrss/n))`, REML adds `log|RX|²` and uses `n−p`. Signs, factors, and the n-vs-(n−p) split all correct. β/σ recovery and `vcov(β)=σ²·dd⁻¹` correct. Λ assembly (lower-triangular relative covariance factor, θ on diagonal SD-scale + sub-diagonal) correct.
- **Numerical Satterthwaite** matches lmerTest: `(θ,σ)` free-σ un-profiled REML deviance, symmetric Hessian, `vcov_varpar=2·H⁻¹`, `df=2v²/(g'·vcov_varpar·g)`, and the df is invariant to any constant-factor convention in `covβ`.
- **Kenward–Roger** matches pbkrtest: `R_r` uses V⁻¹ (not P), expected info uses P, the PhiA `QQ−R A R` second-derivative term is present, off-diagonal `SigmaG = Z_rZ_c'+Z_cZ_r'`, and KR df = variance-parameterized Satterthwaite (not ·eStar), non-zero-gradient at θ=0.
- **R²** (RE variance = trace + off-diagonal covariances), **treatment/sum/polynomial contrasts**, **triangular solves** (`emlForwardSolve`/`emlBackSolve` correctly avoid the descending-loop trap via reversed index), **Cholesky solve/inverse**, **BOBYQA control flow** (RHO/DELTA ladders, TR-vs-ALTMOV-vs-model-improvement dispatch, cancellation guard, feasibility re-clamp), **Nelder–Mead coefficients** (1,2,0.5,0.5), and **Praat hygiene** in the reviewed regions (no `+=`/`==`, no reserved-name misuse, `mul##` not elementwise `*`, dot-prefix in procedures) are all correct.

---

## Cross-cutting theme & recommendations

The failure pattern is the same one that ran through the whole plugin audit: **the sophisticated numeric core is right; the failures are (a) Praat-language traps and (b) untested code paths.** Here the trap is specifically the non-incrementing `for` loop — which the Master Prompt already has a house rule about — and it produced the single most severe bug. The suite missed C1/H1 because it never fits a categorical interaction or a ≥2-slope uncorrelated RE, exactly as the earlier missing-data and quartile bugs hid behind happy-path fixtures.

Concrete additions worth making before this ships (Phase 3F/3G):
1. **Grep-lint for `for .* from .* to 1`** (and any descending literal) across the LMM files and the wider plugin — this class of bug is mechanically detectable and has now surfaced repeatedly.
2. **Add fit-level tests for the untested shapes:** a categorical `A*B` interaction, `(x+z||g)`, a rank-deficient X (collinear predictor), and a boundary/singular random-slope fit — the four data shapes that trip C1, H1, H2/H3, and M6.
3. **Wire boundary detection to the KR fallback** for df (M6) and surface a singular-fit warning, so the default df path stops being silently anticonservative at θ≈0.

None of this undermines the core achievement: the REML/Satterthwaite/KR/PhiA/R² mathematics is correctly implemented and, on a static reading, faithful to the R sources it was validated against. Fix order: **C1 → H1/H2/H3 → M1–M7 → Low.**
