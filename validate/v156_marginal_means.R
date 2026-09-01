#!/usr/bin/env Rscript
# ============================================================================
# v156 -- estimated marginal means, post hoc, simple effects, vs real emmeans
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. Section 2 of the consolidated ruling (mailbox/to-opus/
# RULING_CONSOLIDATED_KERNELS_2026-09-01.md) calls for three additions to the
# two-way ANOVA kernel that were named out of scope when the kernel itself
# was accepted (validate/v151_twoway_types.R): estimated marginal means
# (EMMs) with SEs and CIs, post hoc comparisons on those EMMs with a
# selectable adjustment, and simple effects. All three are now in
# plugin_EML_StatsGraphs/stats/eml-anova-kernel.praat
# (@emlAnovaKernelTwoWayEMM, @emlAnovaKernelTwoWayPostHoc,
# @emlAnovaKernelTwoWaySimpleEffects). This file is their oracle check
# against real emmeans -- installed here via
# `apt-get install --no-install-recommends r-cran-emmeans` (1.10.0; CRAN's
# own cloud.r-project.org mirror is blocked by this environment's egress
# policy -- verified: `curl -sS https://cloud.r-project.org/src/contrib/
# PACKAGES` returns a 403 CONNECT-tunnel failure from the agent proxy, not a
# name/DNS problem, and `install.packages("emmeans", repos=
# "https://cloud.r-project.org")` fails the same way; apt's own repos are
# reachable and carry a real, unmodified emmeans build).
#
# THIS IS A KERNEL CHECK, NOT A WIRING CHECK. None of the three procedures
# checked here is called from any menu, dialog, or orchestrator
# (eml-inferential.praat and eml-analysis.praat are untouched by this item).
# The probe below includes only eml-core-descriptive.praat (for @emlMedian/
# @emlShapiroWilk, which @emlAnovaKernelTwoWay itself still calls),
# eml-core-utilities.praat (for @emlSortWithIndex, which @emlHolm and
# @emlBenjaminiHochberg need) eml-inferential.praat (for @emlBonferroni/
# @emlHolm/@emlBenjaminiHochberg, which @emlAnovaKernelTwoWayPostHoc calls
# rather than reimplementing) and eml-anova-kernel.praat itself.
#
# THE ORACLE, for each fixture, with options(contrasts =
# c("contr.sum","contr.poly")) in force (required for a Type III fit; EMMs
# on a saturated two-way cell-means model do not depend on the contrast
# coding, but the fit is built the same way v151 built it, for one shared
# convention across both files):
#   fit  <- lm(y ~ A * B, data)
#   EMM  <- emmeans(fit, ~ A)   and   emmeans(fit, ~ B)   (weights="equal",
#            emmeans' own default -- the UNWEIGHTED marginal mean, matching
#            the kernel's own definition)
#   post hoc -- pairs(EMM, adjust = <method>) for the estimate/SE/statistic/
#            p-value, confint(pairs(EMM, adjust = <method>)) for the
#            interval (bonferroni/tukey/scheffe only -- see COHERENCE below)
#   simple effects -- emmeans::joint_tests(fit, by = <the other factor>)
#
# THE DEFINITIONAL QUESTION THE BRIEF ASKS ABOUT (simple effects'
# denominator): joint_tests(fit, by = ...) on the FULL two-way fit uses the
# POOLED error term from that fit (its own df2 column here is always N - rs,
# the same dfError @emlAnovaKernelTwoWay's headline table uses) -- so this
# is confirmed BELOW to be the same definition the kernel computes, not
# merely assumed. A LEVEL-SPECIFIC alternative (re-estimate the error
# variance from only the rows at that one slice of the other factor, as
# SPSS's "simple effects" dialog offers as a non-default option) is computed
# separately, once, on the fixture where it can differ most (unbal3lvl,
# whose per-cell variances are visibly unequal) and reported as a named
# finding -- not asserted as a defect in either side, per the brief.
#
# THE COHERENCE LAW (this kit's own standing rule, restated in the brief):
# an interval prints only when its coverage matches the correction in
# force. Bonferroni, Tukey and Scheffe define a per-pair (or simultaneous)
# confidence level and get an interval; Holm and Benjamini-Hochberg operate
# step-wise on ranked p-values and define no such level, so the kernel
# leaves .lowCI##/.highCI## undefined for them -- checked below by
# confirming those cells decode as Praat's `undefined`, not merely by
# skipping the comparison.
#
# FIXTURES (the same four v151 uses, per the brief):
#   balanced 2x2        walkthrough/kit/data/v11_twoway_input.csv
#   unbalanced 2x2       walkthrough/kit/data/v11_twoway_unbalanced_input.csv
#   unbalanced 3-level    walkthrough/kit/data/v11_twoway_3level_input.csv
#   Peterson-Barney       walkthrough/kit/data/peterson_barney_1952.tsv
#     (F0 by Vowel x Type, tab-separated; dependent variable F0, NOT F1 --
#      ruling section 6; 10 Vowel levels x 3 Type levels, N = 1520)
#
# STANDARD RULE: relative 1e-9, absolute 1e-12 near zero -- the same
# std_tol/rel_err pair v151 uses, reproduced here verbatim so this file
# reads standalone. The worst relative error actually observed, per
# quantity per fixture, is tracked independently of pass/fail and printed
# in a summary table at the end, per the brief.
#
#     Rscript validate/v156_marginal_means.R
#
# Requires a Praat at or above the plugin's floor (6.6.30); skips (not
# fails) below it, the v144-v148/v151 convention. Requires the `emmeans`
# package; skips with an attestation if unavailable rather than failing
# the whole file.
#
# RESULT, as measured (`EML_PLUGIN_DIR=plugin_EML_StatsGraphs PRAAT=
# /usr/local/bin/praat6630 Rscript validate/v156_marginal_means.R`, this
# environment, emmeans 1.10.0): 2352 checks, 2345 passed, 7 FAILED. All 7
# failures are on the SAME two well-characterised, tiny numerical effects,
# neither of which is an arithmetic defect in the new code -- see the
# comments at "wald_slice_F" (for why simple effects are NOT checked
# against joint_tests' own columns) and at the post-hoc stat/CI checks
# (search "K=2 TUKEY" and "SCHEFFE F NEAR ZERO" below) for the measurements
# that established this:
#   1. unbal2x2, Tukey CI on a k=2 family (4 of the 7): Praat's own
#      Get invTukeyQ:/Get TukeyQ: -- the SAME builtins the plugin's
#      pre-existing, already-accepted @eml_tukeyPairwiseFromGroups uses --
#      compute the studentized range quantile by general numerical
#      integration, which for k=2 differs from the EXACT closed form
#      (q = sqrt(2)*qt) by ~1e-7 absolute in the critical value. Measured:
#      Praat invTukeyQ(0.05,2,17) = 2.983729709549493, matching R's OWN
#      qtukey(0.95,2,17) = 2.983729709549417 to 13 significant figures --
#      but emmeans' confint() uses the exact closed form for k=2
#      specifically (2.983729804277905), which the general algorithm does
#      not reach. Worst observed: relative 3.44e-8 on unbal2x2's Tukey CI.
#   2. petersonbarney, Scheffe F on 3 near-null Vowel contrasts (F in
#      [0.004, 0.03]): the underlying diff and SE each individually match
#      emmeans to ~1e-9 relative (an independently-computed R lm pipeline
#      vs this kernel's direct cell-mean formula), so t = diff/SE carries
#      up to ~2e-9 relative error -- squaring it for F = t^2/(k-1)
#      compounds that to ~4-8e-9, occasionally over the 1e-9 standard
#      tolerance for a contrast whose true effect is essentially zero.
#      Worst observed: relative 6.3e-9.
# Every other quantity checked here -- EMM means/SEs/CIs, Bonferroni/Holm/
# BH/Tukey/Scheffe diffs/SEs/p-values/statistics/CIs at every OTHER k, and
# every simple effect's F/p/df -- is at or below relative 1e-9 (most far
# below, at 1e-11 to 1e-13) on all four fixtures. See the printed
# "worst relative error, quantity x fixture" table for the complete
# per-quantity, per-fixture figures.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v156"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

STD_REL <- 1e-9
STD_ABS <- 1e-12
std_tol <- function(computed) max(STD_ABS, STD_REL * abs(computed))
rel_err <- function(reported, computed) {
    if (!is.finite(reported) || !is.finite(computed)) return(Inf)
    d <- abs(reported - computed)
    if (d <= STD_ABS) return(0)
    d / max(abs(computed), STD_ABS)
}

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin_EML_StatsGraphs")
plug <- normalizePath(plug, mustWork = FALSE)

praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat6630"),
                   Sys.which("praat_barren"), Sys.which("praat"))) {
        if (nzchar(cand) && file.exists(cand)) { praat <- cand; break }
    }
}
pv <- NA_character_
pvnum <- 0
if (nzchar(praat) && file.exists(praat)) {
    pv <- suppressWarnings(system2(praat, "--version", stdout = TRUE,
                                   stderr = TRUE))[1]
    m <- regmatches(pv, regexpr("[0-9]+\\.[0-9]+\\.[0-9]+", pv))
    if (length(m)) {
        p <- as.integer(strsplit(m, ".", fixed = TRUE)[[1]])
        pvnum <- p[1] * 1000 + p[2] * 100 + p[3]
    }
}
canDrive <- pvnum >= 6630

if (!canDrive) {
    cat(paste0("      SKIP: v156 needs Praat >= 6.6.30 to drive the kernel;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    HAVE_EMMEANS <- requireNamespace("emmeans", quietly = TRUE)
    if (!HAVE_EMMEANS) {
        cat("      SKIP: v156 needs the `emmeans` package for its oracle;\n")
        cat("            not installed.\n")
        check_true(V, "the emmeans package is available (required oracle)", FALSE)
    } else {

    suppressPackageStartupMessages(library(emmeans))

    work <- file.path(tempdir(), "v156")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    # -------------------------------------------------------------------
    # THE BATTERY -- same four fixtures, same column names, as v151.
    # -------------------------------------------------------------------
    fixtures <- list(
        bal2x2 = list(path = repo_path("walkthrough", "kit", "data", "v11_twoway_input.csv"),
                      sep = ",", y = "SPL_dB", A = "voice_type", B = "task"),
        unbal2x2 = list(path = repo_path("walkthrough", "kit", "data", "v11_twoway_unbalanced_input.csv"),
                      sep = ",", y = "SPL_dB", A = "voice_type", B = "task"),
        unbal3lvl = list(path = repo_path("walkthrough", "kit", "data", "v11_twoway_3level_input.csv"),
                      sep = ",", y = "SPL_dB", A = "voice_type", B = "task"),
        petersonbarney = list(path = repo_path("walkthrough", "kit", "data", "peterson_barney_1952.tsv"),
                      sep = "\t", y = "F0", A = "Vowel", B = "Type")
    )
    for (tag in names(fixtures)) {
        if (!file.exists(fixtures[[tag]]$path)) {
            stop("v156: fixture not found: ", fixtures[[tag]]$path)
        }
    }

    read_cmd <- function(sep) if (sep == "\t") "Read Table from tab-separated file:"
                               else "Read Table from comma-separated file:"
    read_df <- function(fx) if (fx$sep == "\t") read.delim(fx$path, stringsAsFactors = FALSE)
                             else read.csv(fx$path, stringsAsFactors = FALSE)

    fit_for <- function(fx) {
        d <- read_df(fx)
        d[[fx$A]] <- factor(d[[fx$A]])
        d[[fx$B]] <- factor(d[[fx$B]])
        old <- options(contrasts = c("contr.sum", "contr.poly"))
        on.exit(options(old))
        lm(as.formula(paste(fx$y, "~", fx$A, "*", fx$B)), data = d)
    }

    # ---------------------------------------------------------------------
    # Simple-effects oracle: a from-first-principles Wald quadratic form on
    # the cell means, NOT summary(joint_tests(...)). MEASURED, not assumed:
    # str(joint_tests(fit, by=...)) shows its own $F.ratio column is stored
    # already rounded to 3 significant figures (54.6, 26.2, ...) -- not a
    # print-format artefact, the underlying data.frame cell itself, checked
    # directly via print(jt$F.ratio, digits=15) still showing "54.576
    # 26.197". Comparing the kernel's full-precision output against that
    # rounded column would manufacture ~30 spurious FAILs at the 1e-9
    # standard tolerance having nothing to do with the kernel. This
    # function computes the SAME quantity joint_tests(fit, by=...) computes
    # (confirmed by hand against joint_tests' own -- rounded -- printed
    # values before this fix went in: 32.666908 vs printed "32.667",
    # 56.264564 vs "56.265", matching to the rounded column's own
    # precision) directly from cell means/counts, at full double precision,
    # exactly mirroring @eml_ak2_typeIIIeffect's L (D L') ^-1 form.
    # ---------------------------------------------------------------------
    wald_slice_F <- function(mu, n, msE, dfE) {
        r <- length(mu)
        Cm <- cbind(diag(r - 1), -1)
        Lmu <- as.vector(Cm %*% mu)
        D <- diag(1 / n, nrow = r)
        LDL <- Cm %*% D %*% t(Cm)
        v <- solve(LDL, Lmu)
        SS <- as.numeric(t(Lmu) %*% v)
        Fstat <- (SS / (r - 1)) / msE
        list(ss = SS, F = Fstat, df1 = r - 1,
             p = pf(Fstat, r - 1, dfE, lower.tail = FALSE))
    }
    # simple_effects_wald(d, y, effFactor, byFactor, msE, dfE) -- the effect
    # of effFactor within each level of byFactor, keyed by byFactor's level
    # NAME (so callers match by name, the same convention every other leg
    # of this file uses, rather than assuming R's alphabetical level order
    # lines up with @eml_ak2_gather's first-appearance order).
    simple_effects_wald <- function(d, y, effFactor, byFactor, msE, dfE) {
        cellmean <- tapply(d[[y]], list(d[[effFactor]], d[[byFactor]]), mean)
        celln <- tapply(d[[y]], list(d[[effFactor]], d[[byFactor]]), length)
        setNames(lapply(colnames(cellmean), function(lv)
            wald_slice_F(cellmean[, lv], celln[, lv], msE, dfE)),
            colnames(cellmean))
    }

    ADJ <- c("bonferroni", "holm", "bh", "tukey", "scheffe")
    HAS_CI <- c(bonferroni = TRUE, holm = FALSE, bh = FALSE, tukey = TRUE, scheffe = TRUE)
    EMM_ADJ_NAME <- c(bonferroni = "bonferroni", holm = "holm", bh = "BH",
                       tukey = "tukey", scheffe = "scheffe")

    prelude <- c(
        paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
        paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
        paste0("include ", file.path(plug, "stats", "eml-inferential.praat")),
        paste0("include ", file.path(plug, "stats", "eml-anova-kernel.praat")))

    # -------------------------------------------------------------------
    # ONE PRAAT SCRIPT drives every fixture x every leg. Fixed-point
    # output at 10 decimals, same as v151, well inside a double's
    # precision for every quantity this battery prints.
    # -------------------------------------------------------------------
    build_battery <- function() {
        lines <- c(prelude, "")
        for (tag in names(fixtures)) {
            fx <- fixtures[[tag]]
            lines <- c(lines, sprintf('t_%s = %s "%s"', tag, read_cmd(fx$sep), fx$path))

            # --- EMM ---
            lines <- c(lines,
                sprintf('@emlAnovaKernelTwoWayEMM: t_%s, "%s", "%s", "%s", 0.05',
                        tag, fx$y, fx$A, fx$B),
                sprintf('appendInfoLine: "EMMHDR %s ok=", emlAnovaKernelTwoWayEMM.ok, " err=[", emlAnovaKernelTwoWayEMM.error$, "] r=", emlAnovaKernelTwoWayEMM.r, " s=", emlAnovaKernelTwoWayEMM.s, " dfError=", emlAnovaKernelTwoWayEMM.dfError, " msError=", fixed$ (emlAnovaKernelTwoWayEMM.msError, 10)', tag))
            lines <- c(lines,
                sprintf('for i from 1 to emlAnovaKernelTwoWayEMM.r'),
                sprintf('  appendInfoLine: "EMMA %s level=", i, " name=[", emlAnovaKernelTwoWayEMM.lev1$[i], "] emm=", fixed$ (emlAnovaKernelTwoWayEMM.emmA#[i], 10), " se=", fixed$ (emlAnovaKernelTwoWayEMM.seA#[i], 10), " low=", fixed$ (emlAnovaKernelTwoWayEMM.lowA#[i], 10), " high=", fixed$ (emlAnovaKernelTwoWayEMM.highA#[i], 10)', tag),
                'endfor',
                sprintf('for j from 1 to emlAnovaKernelTwoWayEMM.s'),
                sprintf('  appendInfoLine: "EMMB %s level=", j, " name=[", emlAnovaKernelTwoWayEMM.lev2$[j], "] emm=", fixed$ (emlAnovaKernelTwoWayEMM.emmB#[j], 10), " se=", fixed$ (emlAnovaKernelTwoWayEMM.seB#[j], 10), " low=", fixed$ (emlAnovaKernelTwoWayEMM.lowB#[j], 10), " high=", fixed$ (emlAnovaKernelTwoWayEMM.highB#[j], 10)', tag),
                'endfor')

            # --- simple effects ---
            lines <- c(lines,
                sprintf('@emlAnovaKernelTwoWaySimpleEffects: t_%s, "%s", "%s", "%s"',
                        tag, fx$y, fx$A, fx$B),
                sprintf('appendInfoLine: "SIMHDR %s ok=", emlAnovaKernelTwoWaySimpleEffects.ok, " err=[", emlAnovaKernelTwoWaySimpleEffects.error$, "]"', tag),
                'for b from 1 to emlAnovaKernelTwoWaySimpleEffects.s',
                sprintf('  appendInfoLine: "SIMPLE_A %s level=", b, " name=[", emlAnovaKernelTwoWaySimpleEffects.lev2$[b], "] ss=", fixed$ (emlAnovaKernelTwoWaySimpleEffects.ssAwithinB#[b], 10), " f=", fixed$ (emlAnovaKernelTwoWaySimpleEffects.fAwithinB#[b], 10), " p=", fixed$ (emlAnovaKernelTwoWaySimpleEffects.pAwithinB#[b], 20), " df1=", emlAnovaKernelTwoWaySimpleEffects.dfAwithinB, " df2=", emlAnovaKernelTwoWaySimpleEffects.dfError', tag),
                'endfor',
                'for a from 1 to emlAnovaKernelTwoWaySimpleEffects.r',
                sprintf('  appendInfoLine: "SIMPLE_B %s level=", a, " name=[", emlAnovaKernelTwoWaySimpleEffects.lev1$[a], "] ss=", fixed$ (emlAnovaKernelTwoWaySimpleEffects.ssBwithinA#[a], 10), " f=", fixed$ (emlAnovaKernelTwoWaySimpleEffects.fBwithinA#[a], 10), " p=", fixed$ (emlAnovaKernelTwoWaySimpleEffects.pBwithinA#[a], 20), " df1=", emlAnovaKernelTwoWaySimpleEffects.dfBwithinA, " df2=", emlAnovaKernelTwoWaySimpleEffects.dfError', tag),
                'endfor')

            # --- post hoc, both factors, all 5 methods ---
            for (fsel in c(1, 2)) {
                for (m in ADJ) {
                    lines <- c(lines,
                        sprintf('@emlAnovaKernelTwoWayPostHoc: t_%s, "%s", "%s", "%s", %d, "%s", 0.05',
                                tag, fx$y, fx$A, fx$B, fsel, m),
                        sprintf('appendInfoLine: "PHHDR %s %d %s ok=", emlAnovaKernelTwoWayPostHoc.ok, " err=[", emlAnovaKernelTwoWayPostHoc.error$, "] k=", emlAnovaKernelTwoWayPostHoc.k', tag, fsel, m),
                        sprintf('for pIdx from 1 to emlAnovaKernelTwoWayPostHoc.k - 1'),
                        sprintf('  for qIdx from pIdx + 1 to emlAnovaKernelTwoWayPostHoc.k'),
                        sprintf('    lowStr$ = "undef"'),
                        sprintf('    highStr$ = "undef"'),
                        sprintf('    if emlAnovaKernelTwoWayPostHoc.lowCI##[pIdx, qIdx] <> undefined'),
                        sprintf('      lowStr$ = fixed$ (emlAnovaKernelTwoWayPostHoc.lowCI##[pIdx, qIdx], 10)'),
                        sprintf('      highStr$ = fixed$ (emlAnovaKernelTwoWayPostHoc.highCI##[pIdx, qIdx], 10)'),
                        sprintf('    endif'),
                        sprintf('    appendInfoLine: "PH %s %d %s i=", pIdx, " j=", qIdx, " nameI=[", emlAnovaKernelTwoWayPostHoc.levelName$[pIdx], "] nameJ=[", emlAnovaKernelTwoWayPostHoc.levelName$[qIdx], "] diff=", fixed$ (emlAnovaKernelTwoWayPostHoc.diff##[pIdx, qIdx], 10), " se=", fixed$ (emlAnovaKernelTwoWayPostHoc.se##[pIdx, qIdx], 10), " stat=", fixed$ (emlAnovaKernelTwoWayPostHoc.stat##[pIdx, qIdx], 10), " p=", fixed$ (emlAnovaKernelTwoWayPostHoc.pAdj##[pIdx, qIdx], 20), " low=", lowStr$, " high=", highStr$', tag, fsel, m),
                        sprintf('  endfor'),
                        'endfor')
                }
            }
        }
        probe_path <- file.path(work, "v156-battery.praat")
        writeLines(c('writeInfoLine: "v156"', lines), probe_path)
        probe_path
    }

    drive <- function(probe_path, timeout_s = "240") {
        suppressWarnings(system2("timeout",
            c(timeout_s, "env", "-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
            stdout = TRUE, stderr = TRUE))
    }

    kv_from_bracketed <- function(line, prefix_regex) {
        # Parses "TAG ... key=[bracketed val] key2=val2 key3=[..]" lines --
        # tokens are space-separated EXCEPT inside [...] (names never
        # contain "]"), and every value here is either a bracketed string
        # or a token with no internal space (a number, undef, ok=0/1).
        body <- sub(prefix_regex, "", line)
        toks <- list()
        i <- 1; n <- nchar(body)
        while (i <= n) {
            while (i <= n && substr(body, i, i) == " ") i <- i + 1
            if (i > n) break
            eq <- regexpr("=", substr(body, i, n), fixed = TRUE)
            if (eq < 0) break
            key <- substr(body, i, i + eq - 2)
            i <- i + eq
            if (i <= n && substr(body, i, i) == "[") {
                close <- regexpr("]", substr(body, i, n), fixed = TRUE)
                val <- substr(body, i + 1, i + close - 2)
                i <- i + close
            } else {
                sp <- regexpr(" ", substr(body, i, n), fixed = TRUE)
                if (sp < 0) { val <- substr(body, i, n); i <- n + 1 }
                else { val <- substr(body, i, i + sp - 2); i <- i + sp }
            }
            toks[[key]] <- val
        }
        toks
    }

    probe_path <- build_battery()
    out <- drive(probe_path)
    ran <- !any(grepl("^Error", out))
    check_true(V, "the battery probe ran with no Praat error", ran)
    if (!ran) {
        cat("      v156 battery probe output (tail):\n      ",
            paste(utils::tail(out, 60), collapse = "\n      "), "\n", sep = "")
    } else {

    worst_rel <- data.frame(fixture = character(0), quantity = character(0),
                             worst_rel_err = numeric(0))
    record_worst <- function(fixture, quantity, res) {
        worst_rel <<- rbind(worst_rel, data.frame(
            fixture = fixture, quantity = quantity, worst_rel_err = res))
    }

    for (tag in names(fixtures)) {
        fx <- fixtures[[tag]]
        fit <- fit_for(fx)
        emA <- emmeans(fit, as.formula(paste("~", fx$A)))
        emB <- emmeans(fit, as.formula(paste("~", fx$B)))
        sumA <- summary(emA)
        sumB <- summary(emB)
        levA <- as.character(sumA[[fx$A]])
        levB <- as.character(sumB[[fx$B]])

        # ---------------- EMM ----------------
        emmhdr <- grep(paste0("^EMMHDR ", tag, " "), out, value = TRUE)
        check_true(V, sprintf("[%s] EMMHDR line present", tag), length(emmhdr) == 1)
        if (length(emmhdr) == 1) {
            h <- kv_from_bracketed(emmhdr, paste0("^EMMHDR ", tag, " "))
            check_true(V, sprintf("[%s] EMM ok=1", tag), identical(h$ok, "1"))
            check_true(V, sprintf("[%s] EMM err$ empty", tag), identical(h$err, ""))
        }
        emmaLines <- grep(paste0("^EMMA ", tag, " "), out, value = TRUE)
        for (ln in emmaLines) {
            r <- kv_from_bracketed(ln, paste0("^EMMA ", tag, " "))
            idx <- as.integer(r$level)
            oracleRow <- match(r$name, levA)
            check_true(V, sprintf("[%s] EMMA level %s found in emmeans(~%s)", tag, r$name, fx$A),
                       !is.na(oracleRow))
            if (is.na(oracleRow)) next
            got_emm <- as.numeric(r$emm); got_se <- as.numeric(r$se)
            got_low <- as.numeric(r$low); got_high <- as.numeric(r$high)
            oc_emm <- sumA$emmean[oracleRow]; oc_se <- sumA$SE[oracleRow]
            oc_low <- sumA$lower.CL[oracleRow]; oc_high <- sumA$upper.CL[oracleRow]
            check(V, sprintf("[%s] EMM(%s=%s) mean vs emmeans", tag, fx$A, r$name),
                  got_emm, oc_emm, tol = std_tol(oc_emm))
            record_worst(tag, "EMM_mean", rel_err(got_emm, oc_emm))
            check(V, sprintf("[%s] EMM(%s=%s) SE vs emmeans", tag, fx$A, r$name),
                  got_se, oc_se, tol = std_tol(oc_se))
            record_worst(tag, "EMM_SE", rel_err(got_se, oc_se))
            check(V, sprintf("[%s] EMM(%s=%s) CI lower vs emmeans", tag, fx$A, r$name),
                  got_low, oc_low, tol = std_tol(oc_low))
            record_worst(tag, "EMM_CI", rel_err(got_low, oc_low))
            check(V, sprintf("[%s] EMM(%s=%s) CI upper vs emmeans", tag, fx$A, r$name),
                  got_high, oc_high, tol = std_tol(oc_high))
            record_worst(tag, "EMM_CI", rel_err(got_high, oc_high))
        }
        emmbLines <- grep(paste0("^EMMB ", tag, " "), out, value = TRUE)
        for (ln in emmbLines) {
            r <- kv_from_bracketed(ln, paste0("^EMMB ", tag, " "))
            oracleRow <- match(r$name, levB)
            check_true(V, sprintf("[%s] EMMB level %s found in emmeans(~%s)", tag, r$name, fx$B),
                       !is.na(oracleRow))
            if (is.na(oracleRow)) next
            got_emm <- as.numeric(r$emm); got_se <- as.numeric(r$se)
            got_low <- as.numeric(r$low); got_high <- as.numeric(r$high)
            oc_emm <- sumB$emmean[oracleRow]; oc_se <- sumB$SE[oracleRow]
            oc_low <- sumB$lower.CL[oracleRow]; oc_high <- sumB$upper.CL[oracleRow]
            check(V, sprintf("[%s] EMM(%s=%s) mean vs emmeans", tag, fx$B, r$name),
                  got_emm, oc_emm, tol = std_tol(oc_emm))
            record_worst(tag, "EMM_mean", rel_err(got_emm, oc_emm))
            check(V, sprintf("[%s] EMM(%s=%s) SE vs emmeans", tag, fx$B, r$name),
                  got_se, oc_se, tol = std_tol(oc_se))
            record_worst(tag, "EMM_SE", rel_err(got_se, oc_se))
            check(V, sprintf("[%s] EMM(%s=%s) CI lower vs emmeans", tag, fx$B, r$name),
                  got_low, oc_low, tol = std_tol(oc_low))
            record_worst(tag, "EMM_CI", rel_err(got_low, oc_low))
            check(V, sprintf("[%s] EMM(%s=%s) CI upper vs emmeans", tag, fx$B, r$name),
                  got_high, oc_high, tol = std_tol(oc_high))
            record_worst(tag, "EMM_CI", rel_err(got_high, oc_high))
        }

        # ---------------- simple effects ----------------
        # Full-precision oracle (wald_slice_F/simple_effects_wald above),
        # NOT summary(joint_tests(...)) -- see that function's own header
        # for why. msE/dfE taken from the SAME fitted model `fit` (built
        # above for the EMM oracle), so this is the identical pooled error
        # term joint_tests(fit, by=...) itself would use.
        dOrd <- read_df(fx)
        dOrd[[fx$A]] <- factor(dOrd[[fx$A]]); dOrd[[fx$B]] <- factor(dOrd[[fx$B]])
        msE <- summary(fit)$sigma^2
        dfE <- df.residual(fit)
        simpA <- simple_effects_wald(dOrd, fx$y, fx$A, fx$B, msE, dfE)  # A within each level of B
        simpB <- simple_effects_wald(dOrd, fx$y, fx$B, fx$A, msE, dfE)  # B within each level of A

        simhdr <- grep(paste0("^SIMHDR ", tag, " "), out, value = TRUE)
        check_true(V, sprintf("[%s] SIMHDR line present", tag), length(simhdr) == 1)
        if (length(simhdr) == 1) {
            h <- kv_from_bracketed(simhdr, paste0("^SIMHDR ", tag, " "))
            check_true(V, sprintf("[%s] simple effects ok=1", tag), identical(h$ok, "1"))
        }
        for (ln in grep(paste0("^SIMPLE_A ", tag, " "), out, value = TRUE)) {
            r <- kv_from_bracketed(ln, paste0("^SIMPLE_A ", tag, " "))
            check_true(V, sprintf("[%s] simple effect of %s within %s=%s found (Wald oracle)", tag, fx$A, fx$B, r$name),
                       r$name %in% names(simpA))
            if (!(r$name %in% names(simpA))) next
            oc <- simpA[[r$name]]
            got_f <- as.numeric(r$f); got_p <- as.numeric(r$p)
            check(V, sprintf("[%s] simple effect F: %s within %s=%s", tag, fx$A, fx$B, r$name),
                  got_f, oc$F, tol = std_tol(oc$F))
            record_worst(tag, "simpleEffect_F", rel_err(got_f, oc$F))
            check(V, sprintf("[%s] simple effect p: %s within %s=%s", tag, fx$A, fx$B, r$name),
                  got_p, oc$p, tol = std_tol(oc$p))
            record_worst(tag, "simpleEffect_p", rel_err(got_p, oc$p))
            check_true(V, sprintf("[%s] simple effect df1 (%s within %s=%s)", tag, fx$A, fx$B, r$name),
                       as.integer(r$df1) == oc$df1)
            check_true(V, sprintf("[%s] simple effect df2 (%s within %s=%s)", tag, fx$A, fx$B, r$name),
                       as.integer(r$df2) == dfE)
        }
        for (ln in grep(paste0("^SIMPLE_B ", tag, " "), out, value = TRUE)) {
            r <- kv_from_bracketed(ln, paste0("^SIMPLE_B ", tag, " "))
            check_true(V, sprintf("[%s] simple effect of %s within %s=%s found (Wald oracle)", tag, fx$B, fx$A, r$name),
                       r$name %in% names(simpB))
            if (!(r$name %in% names(simpB))) next
            oc <- simpB[[r$name]]
            got_f <- as.numeric(r$f); got_p <- as.numeric(r$p)
            check(V, sprintf("[%s] simple effect F: %s within %s=%s", tag, fx$B, fx$A, r$name),
                  got_f, oc$F, tol = std_tol(oc$F))
            record_worst(tag, "simpleEffect_F", rel_err(got_f, oc$F))
            check(V, sprintf("[%s] simple effect p: %s within %s=%s", tag, fx$B, fx$A, r$name),
                  got_p, oc$p, tol = std_tol(oc$p))
            record_worst(tag, "simpleEffect_p", rel_err(got_p, oc$p))
        }

        # A once-per-fixture cross-check that this from-first-principles
        # oracle really is the same DEFINITION joint_tests(fit, by=...)
        # uses (not merely "close") -- compared at joint_tests' own
        # (rounded) precision, so a match here confirms the definitions
        # agree even though the two oracles cannot be compared at the
        # 1e-9 standard tolerance.
        jtA <- summary(joint_tests(fit, by = fx$B))
        for (i in seq_len(nrow(jtA))) {
            lv <- as.character(jtA[[fx$B]][i])
            check_true(V, sprintf("[%s] Wald oracle matches joint_tests' own (rounded) F for %s within %s=%s (definition cross-check)",
                                   tag, fx$A, fx$B, lv),
                       abs(simpA[[lv]]$F - jtA$F.ratio[i]) < 5e-3)
        }

        # ---------------- post hoc, both factors, all 5 methods ----------------
        for (fsel in c(1, 2)) {
            emObj <- if (fsel == 1) emA else emB
            levs <- if (fsel == 1) levA else levB
            facName <- if (fsel == 1) fx$A else fx$B
            for (m in ADJ) {
                prs <- pairs(emObj, adjust = EMM_ADJ_NAME[[m]])
                sprs <- summary(prs)
                oc_ci <- if (HAS_CI[[m]]) suppressMessages(summary(confint(prs))) else NULL

                phhdr <- grep(paste0("^PHHDR ", tag, " ", fsel, " ", m, " "), out, value = TRUE)
                check_true(V, sprintf("[%s] PHHDR present (factor %d, %s)", tag, fsel, m),
                           length(phhdr) == 1)
                if (length(phhdr) != 1) next
                h <- kv_from_bracketed(phhdr, paste0("^PHHDR ", tag, " ", fsel, " ", m, " "))
                check_true(V, sprintf("[%s] post hoc ok=1 (factor %d, %s)", tag, fsel, m),
                           identical(h$ok, "1"))

                phLines <- grep(paste0("^PH ", tag, " ", fsel, " ", m, " "), out, value = TRUE)
                for (ln in phLines) {
                    r <- kv_from_bracketed(ln, paste0("^PH ", tag, " ", fsel, " ", m, " "))
                    # contrast label in emmeans is "levI - levJ" for the
                    # first-appearance-ordered pair (pIdx < qIdx); emmeans
                    # itself orders contrasts by ITS OWN level ordering
                    # (alphabetical for a factor), so match by the pair of
                    # names rather than assuming row order lines up.
                    label <- paste(r$nameI, "-", r$nameJ)
                    oracleRow <- which(as.character(sprs$contrast) == label)
                    if (length(oracleRow) == 0) {
                        label2 <- paste(r$nameJ, "-", r$nameI)
                        oracleRow2 <- which(as.character(sprs$contrast) == label2)
                        check_true(V, sprintf("[%s] post hoc pair %s vs %s found (factor %d, %s)",
                                               tag, r$nameI, r$nameJ, fsel, m),
                                   length(oracleRow2) == 1)
                        if (length(oracleRow2) != 1) next
                        oc_diff <- -sprs$estimate[oracleRow2]
                        oc_se <- sprs$SE[oracleRow2]
                        oc_t <- -sprs$t.ratio[oracleRow2]
                        oc_p <- sprs$p.value[oracleRow2]
                        if (!is.null(oc_ci)) {
                            oc_low <- -oc_ci$upper.CL[oracleRow2]
                            oc_high <- -oc_ci$lower.CL[oracleRow2]
                        }
                    } else {
                        check_true(V, sprintf("[%s] post hoc pair %s vs %s found (factor %d, %s)",
                                               tag, r$nameI, r$nameJ, fsel, m),
                                   length(oracleRow) == 1)
                        if (length(oracleRow) != 1) next
                        oc_diff <- sprs$estimate[oracleRow]
                        oc_se <- sprs$SE[oracleRow]
                        oc_t <- sprs$t.ratio[oracleRow]
                        oc_p <- sprs$p.value[oracleRow]
                        if (!is.null(oc_ci)) {
                            oc_low <- oc_ci$lower.CL[oracleRow]
                            oc_high <- oc_ci$upper.CL[oracleRow]
                        }
                    }
                    got_diff <- as.numeric(r$diff); got_se <- as.numeric(r$se)
                    got_stat <- as.numeric(r$stat); got_p <- as.numeric(r$p)

                    check(V, sprintf("[%s] post hoc diff %s-%s (factor %d, %s)", tag, r$nameI, r$nameJ, fsel, m),
                          got_diff, oc_diff, tol = std_tol(oc_diff))
                    record_worst(tag, paste0("postHoc_diff_", m), rel_err(got_diff, oc_diff))
                    check(V, sprintf("[%s] post hoc SE %s-%s (factor %d, %s)", tag, r$nameI, r$nameJ, fsel, m),
                          got_se, oc_se, tol = std_tol(oc_se))
                    record_worst(tag, paste0("postHoc_SE_", m), rel_err(got_se, oc_se))
                    check(V, sprintf("[%s] post hoc p %s-%s (factor %d, %s)", tag, r$nameI, r$nameJ, fsel, m),
                          got_p, oc_p, tol = std_tol(oc_p))
                    record_worst(tag, paste0("postHoc_p_", m), rel_err(got_p, oc_p))
                    # raw t/q/F stat: bonferroni/holm/bh all share the SAME
                    # raw t; emmeans' t.ratio for tukey/scheffe adjust=
                    # is the SAME raw t too (only the p-value/CI differ by
                    # method) -- so .stat## is checked against t.ratio for
                    # bonferroni/holm/bh, and independently reconstructed
                    # for tukey (q = |t|*sqrt(2)) / scheffe (F = t^2/(k-1))
                    # from that same oracle t, rather than against a
                    # second emmeans call.
                    kFac <- length(levs)
                    if (m %in% c("bonferroni", "holm", "bh")) {
                        check(V, sprintf("[%s] post hoc raw t %s-%s (factor %d, %s)", tag, r$nameI, r$nameJ, fsel, m),
                              got_stat, oc_t, tol = std_tol(oc_t))
                        record_worst(tag, paste0("postHoc_stat_", m), rel_err(got_stat, oc_t))
                    } else if (m == "tukey") {
                        oc_q <- abs(oc_t) * sqrt(2)
                        check(V, sprintf("[%s] post hoc Tukey q %s-%s (factor %d)", tag, r$nameI, r$nameJ, fsel),
                              got_stat, oc_q, tol = std_tol(oc_q))
                        record_worst(tag, paste0("postHoc_stat_", m), rel_err(got_stat, oc_q))
                    } else if (m == "scheffe") {
                        # SCHEFFE F NEAR ZERO: a near-null contrast (true
                        # effect ~0) squares two independently-computed
                        # pipelines' ~1e-9-relative diff/SE into F = t^2 /
                        # (k-1), which can push F's own relative error just
                        # over the 1e-9 standard tolerance (observed worst:
                        # petersonbarney, ~6.3e-9) -- see this file's own
                        # header ("RESULT, as measured").
                        oc_fstat <- oc_t^2 / (kFac - 1)
                        check(V, sprintf("[%s] post hoc Scheffe F %s-%s (factor %d)", tag, r$nameI, r$nameJ, fsel),
                              got_stat, oc_fstat, tol = std_tol(oc_fstat))
                        record_worst(tag, paste0("postHoc_stat_", m), rel_err(got_stat, oc_fstat))
                    }

                    if (HAS_CI[[m]]) {
                        # K=2 TUKEY: on a 2-level family (unbal2x2), this
                        # CI is expected to fail the 1e-9 standard tolerance
                        # by up to ~3.4e-8 relative -- see this file's own
                        # header ("RESULT, as measured") for the full
                        # measurement. Praat's Get invTukeyQ:/Get TukeyQ:
                        # match R's OWN qtukey/ptukey almost exactly; the
                        # gap is between that shared GENERAL numerical
                        # algorithm and the EXACT closed form emmeans uses
                        # only for k=2 pairwise Tukey intervals.
                        check_true(V, sprintf("[%s] post hoc interval printed %s-%s (factor %d, %s)", tag, r$nameI, r$nameJ, fsel, m),
                                   r$low != "undef" && r$high != "undef")
                        if (r$low != "undef") {
                            got_low <- as.numeric(r$low); got_high <- as.numeric(r$high)
                            check(V, sprintf("[%s] post hoc CI low %s-%s (factor %d, %s)", tag, r$nameI, r$nameJ, fsel, m),
                                  got_low, oc_low, tol = std_tol(oc_low))
                            record_worst(tag, paste0("postHoc_CI_", m), rel_err(got_low, oc_low))
                            check(V, sprintf("[%s] post hoc CI high %s-%s (factor %d, %s)", tag, r$nameI, r$nameJ, fsel, m),
                                  got_high, oc_high, tol = std_tol(oc_high))
                            record_worst(tag, paste0("postHoc_CI_", m), rel_err(got_high, oc_high))
                        }
                    } else {
                        # COHERENCE LAW: holm/bh define no per-pair level,
                        # so no interval -- confirmed as absent, not merely
                        # unchecked.
                        check_true(V, sprintf("[%s] post hoc interval correctly ABSENT %s-%s (factor %d, %s, no coverage defined)",
                                               tag, r$nameI, r$nameJ, fsel, m),
                                   r$low == "undef" && r$high == "undef")
                    }
                }
            }
        }
    }

    # -----------------------------------------------------------------
    # THE REQUIRED SUMMARY: worst relative error per quantity per fixture.
    # -----------------------------------------------------------------
    if (nrow(worst_rel) > 0) {
        cat("\n      worst relative error, quantity x fixture (standard rule: rel 1e-9, abs 1e-12):\n")
        agg <- aggregate(worst_rel_err ~ fixture + quantity, data = worst_rel, FUN = max)
        agg <- agg[order(agg$fixture, agg$quantity), ]
        for (i in seq_len(nrow(agg))) {
            cat(sprintf("        %-16s %-22s worst rel err = %.3e\n",
                        agg$fixture[i], agg$quantity[i], agg$worst_rel_err[i]))
        }
    }

    }  # ran

    # -------------------------------------------------------------------
    # DEFINITIONAL FINDING (not a pass/fail check): simple effects against
    # a LEVEL-SPECIFIC error term, on unbal3lvl, where cell variances are
    # visibly unequal -- to show plainly how far the pooled-error answer
    # this kernel reports differs from that alternative, per the brief.
    # -------------------------------------------------------------------
    fx3 <- fixtures$unbal3lvl
    d3 <- read_df(fx3)
    cat("\n      DEFINITIONAL FINDING -- simple effect of", fx3$A, "within",
        fx3$B, "= Singing (unbal3lvl), pooled vs level-specific error term:\n")
    subSing <- d3[d3[[fx3$B]] == "Singing", ]
    subSing[[fx3$A]] <- factor(subSing[[fx3$A]])
    fitSing <- lm(as.formula(paste(fx3$y, "~", fx3$A)), data = subSing)
    aovSing <- anova(fitSing)
    fLevelSpecific <- aovSing[fx3$A, "F value"]
    pLevelSpecific <- aovSing[fx3$A, "Pr(>F)"]
    df2LevelSpecific <- aovSing["Residuals", "Df"]
    fitFull3 <- fit_for(fx3)
    jt3 <- summary(joint_tests(fitFull3, by = fx3$B))
    rowSing <- which(as.character(jt3[[fx3$B]]) == "Singing")
    fPooled <- jt3$F.ratio[rowSing]; pPooled <- jt3$p.value[rowSing]
    df2Pooled <- jt3$df2[rowSing]
    cat(sprintf("        pooled error (this kernel, matches joint_tests):    F = %.6f, df2 = %d, p = %.6g\n",
                fPooled, df2Pooled, pPooled))
    cat(sprintf("        level-specific error (one-way ANOVA on Singing only): F = %.6f, df2 = %d, p = %.6g\n",
                fLevelSpecific, df2LevelSpecific, pLevelSpecific))
    cat(sprintf("        difference is real: %s (df2 %d vs %d; the pooled form borrows residual\n",
                if (abs(fPooled - fLevelSpecific) > 1e-6) "YES" else "no", df2Pooled, df2LevelSpecific))
    cat("        variance from every cell in the design, the level-specific form only from\n")
    cat("        the cells at that one slice of task -- they agree only when every cell's\n")
    cat("        variance is equal, which this unbalanced, heteroscedastic-by-construction\n")
    cat("        fixture does not guarantee and does not here provide).\n")
    attest(V, "simple effects: pooled-error (kernel/joint_tests) vs level-specific-error definitional difference, unbal3lvl A-within-B=Singing",
           sprintf("pooled F=%.6f (df2=%d) vs level-specific F=%.6f (df2=%d)",
                   fPooled, df2Pooled, fLevelSpecific, df2LevelSpecific))

    }  # HAVE_EMMEANS
}  # canDrive

if (!exists("EML_SUITE")) {
    eml_report("v156 estimated marginal means / post hoc / simple effects vs real emmeans 1.10.0")
    eml_exit()
}
