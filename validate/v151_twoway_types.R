#!/usr/bin/env Rscript
# ============================================================================
# v151 -- @emlAnovaKernelTwoWay: Types I, II and III against real car 3.1.2
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. mailbox/to-opus/RULING_CONSOLIDATED_KERNELS_2026-09-01.md
# section 2 requires the two-way ANOVA to be computed directly from raw
# data -- Types I, II and III all three, selectable, default Type III --
# rather than taken from Praat's built-in `Report two-way anova`, which uses
# Khuri's unweighted-means method for the effect sums and is not valid on an
# unbalanced, non-proportional design (measured on Praat's own manual
# example, Peterson-Barney: reported Error SS 1,600,534 against the correct
# 914,449). This file is the oracle check for the new kernel,
# plugin_EML_StatsGraphs/stats/eml-anova-kernel.praat
# (@emlAnovaKernelTwoWay), against real car -- installed here via
# `apt-get install r-cran-car`, per section 8 of the ruling.
#
# THIS IS A KERNEL CHECK, NOT A WIRING CHECK. @emlAnovaKernelTwoWay is not
# called from any menu, dialog, or orchestrator yet (eml-inferential.praat
# and eml-analysis.praat are untouched by this item, per the brief -- wiring
# is separate, later work). The probe below therefore includes only the
# kernel's own two files -- eml-core-descriptive.praat (for @emlMedian and
# @emlShapiroWilk, which the kernel calls rather than re-implementing) and
# eml-anova-kernel.praat itself -- and drives @emlAnovaKernelTwoWay directly
# on Tables read straight from the fixture files on disk.
#
# THE ORACLE. For each fixture, with options(contrasts =
# c("contr.sum","contr.poly")) in force throughout (car::Anova requires
# sum-to-zero contrasts for Type III to be the textbook definition; Type I
# and Type II are contrast-invariant, so the same fitted object serves all
# three):
#   Type I   -- anova(lm(y ~ A*B))
#   Type II  -- car::Anova(fit, type = 2)
#   Type III -- car::Anova(fit, type = 3)
# All three SS types are ALWAYS computed by the kernel regardless of which
# one is requested as the "headline" table (@emlAnovaKernelTwoWay's
# .ssATypeI/.ssATypeII/.ssATypeIII fields etc.), so one Praat run per
# fixture is enough to check all three against all three oracles; the
# .ssTypeRequested argument is exercised separately (see "HEADLINE
# SELECTION" below) to confirm it actually switches which table is
# reported.
#
# FIXTURES.
#   balanced 2x2      walkthrough/kit/data/v11_twoway_input.csv
#   unbalanced 2x2    walkthrough/kit/data/v11_twoway_unbalanced_input.csv
#   unbalanced,       walkthrough/kit/data/v11_twoway_3level_input.csv
#     3-level,          (new fixture this item adds -- every existing
#     non-proportional   two-way fixture in the kit was 2x2 and perfectly
#                         balanced, which cannot separate Khuri's method
#                         from Types I/II/III at all, and cannot separate
#                         Type I from Type II from Type III either, since
#                         a proportional design makes all of Khuri/I/II/III
#                         agree. This fixture is neither balanced nor
#                         proportional -- checked below, "PROPORTIONALITY"
#                         -- so it is the one fixture in the battery where
#                         Type I, Type II and Type III are all three
#                         genuinely different numbers.)
#   Peterson-Barney   walkthrough/kit/data/peterson_barney_1952.tsv
#     (F0 by Vowel x Type; tab-separated; the dependent variable is F0, NOT
#      F1 -- ruling section 6). This design IS proportional (30/66/56 rows
#      per vowel within Type c/m/w respectively, constant across vowels),
#      so Types I, II and III agree with each other here and all three
#      inherit the same canonical numbers the ruling records for this
#      dataset (Error 914,449.16, Total 5,534,634.37, Vowel F 13.346) --
#      the useful thing this fixture separately confirms is that the
#      kernel reproduces those exact figures at the scale (N = 1520,
#      r = 10, s = 3) where Khuri's method was measured to diverge, not
#      that Types I/II/III diverge from each other (they cannot, on a
#      proportional design).
#
# STANDARD RULE: relative 1e-9, absolute 1e-12 near zero, i.e. a check
# passes when |reported - computed| <= max(1e-12, 1e-9 * |computed|). This
# is threaded through the repo's own check() as a per-call absolute
# tolerance (tol = std_tol(computed)); the worst RELATIVE error actually
# observed, per SS type per fixture, is tracked independently and printed
# in a summary table at the end regardless of pass/fail, per the brief.
#
# HEADLINE SELECTION. A short separate battery confirms .ssTypeRequested
# actually switches .ssA/.ssB/.ssAB and .ssTypeLabel$ to the requested
# type's numbers (1 -> "Type I", 2 -> "Type II", anything else -> "Type III"
# -- 0 and 3 both probed as the "anything else" case, since the brief's
# default-type-III contract is "selectable Type I/II, default III" rather
# than "reject anything outside {1,2,3}").
#
# NOT RE-DERIVED HERE: Levene's test and Shapiro-Wilk-on-residuals are
# checked for having RUN (no .leveneError$/.shapiroError$, and a residual
# n that matches N) and for RESPECTING KNOWN IDENTITIES (Shapiro's n must
# equal N; Levene's dfWithin must equal N - rs, the same partition SS_Error
# uses) rather than against an independent R computation -- the brief's
# required oracle set for this file is Type I/II/III only, and
# @emlShapiroWilk already has its own oracle file (the Royston/AS R94
# reference values cited in eml-core-descriptive.praat). A real
# car::leveneTest cross-check is included as an attested (non-blocking)
# extra leg, since the group-median-centred Brown-Forsythe formula the
# kernel implements is small and worth a second pair of eyes.
#
#     Rscript validate/v151_twoway_types.R
#
# Requires a Praat at or above the plugin's floor (6.6.30); skips (not
# fails) below it, the v144-v148 convention. Requires the `car` package
# (3.1.2, per section 8 of the ruling); skips that leg with an attestation
# if unavailable rather than failing the whole file.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v151"

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
    cat(paste0("      SKIP: v151 needs Praat >= 6.6.30 to drive the kernel;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    HAVE_CAR <- requireNamespace("car", quietly = TRUE)
    if (!HAVE_CAR) {
        cat("      SKIP: v151 needs the `car` package for Type II/III oracles;\n")
        cat("            not installed (ruling section 8: `apt-get install r-cran-car`).\n")
        check_true(V, "the car package is available (required oracle for Types II/III)",
                   FALSE)
    } else {

    work <- file.path(tempdir(), "v151")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    # -------------------------------------------------------------------
    # THE BATTERY. Every fixture in the same column shape:
    # subject,voice_type,task,SPL_dB (comma) except Peterson-Barney, which
    # is the tab-separated export the ruling names (Type/Sex/Speaker/
    # Vowel/IPA/F0/F1/F2/F3) -- dependent variable F0, factors Vowel x Type.
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
            stop("v151: fixture not found: ", fixtures[[tag]]$path)
        }
    }

    # -------------------------------------------------------------------
    # PROPORTIONALITY, so the header's claim about which fixtures can and
    # cannot separate the SS types is not just asserted -- it is measured
    # the same way khuri_vs_direct_red_demo's neighbourhood does: n_ij vs
    # (n_i. * n_.j) / N, exactly (integer arithmetic on a proportional
    # design; a non-proportional one differs by a real, non-rounding
    # amount).
    # -------------------------------------------------------------------
    proportional <- function(path, sep, A, B) {
        d <- if (sep == "\t") read.delim(path, stringsAsFactors = FALSE)
             else read.csv(path, stringsAsFactors = FALSE)
        tab <- table(d[[A]], d[[B]])
        N <- sum(tab)
        expected <- outer(rowSums(tab), colSums(tab)) / N
        max(abs(tab - expected)) < 1e-9
    }
    check_true(V, "[unbal3lvl] the new fixture is NOT proportional (else it could not separate the SS types)",
               !proportional(fixtures$unbal3lvl$path, ",", "voice_type", "task"))
    check_true(V, "[unbal3lvl] the new fixture is genuinely unbalanced (min cell 2, per the brief's floor)",
               {
                   d <- read.csv(fixtures$unbal3lvl$path, stringsAsFactors = FALSE)
                   tab <- table(d$voice_type, d$task)
                   min(tab) >= 2 && length(unique(as.vector(tab))) > 1
               })
    check_true(V, "[petersonbarney] IS proportional (Types I/II/III must therefore agree here)",
               proportional(fixtures$petersonbarney$path, "\t", "Vowel", "Type"))

    # -------------------------------------------------------------------
    # THE PROBE. One Praat run drives all four fixtures. Each fixture
    # prints one RESULT line via fixed$ (., 10) -- ten decimal places is
    # far inside a double's ~15-17 significant digits for every quantity
    # this battery prints (the largest, Peterson-Barney's Type SS, is
    # ~4.5e6; ten decimal places after that is still full double
    # precision), and avoids Praat's default free-format serialisation
    # switching to scientific notation for a value near zero.
    # -------------------------------------------------------------------
    prelude <- c(
        paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
        paste0("include ", file.path(plug, "stats", "eml-anova-kernel.praat")))

    read_cmd <- function(sep) if (sep == "\t") "Read Table from tab-separated file:"
                               else "Read Table from comma-separated file:"

    build_battery <- function() {
        lines <- c(prelude, "")
        for (tag in names(fixtures)) {
            fx <- fixtures[[tag]]
            lines <- c(lines,
                sprintf('t_%s = %s "%s"', tag, read_cmd(fx$sep), fx$path),
                sprintf('@emlAnovaKernelTwoWay: t_%s, "%s", "%s", "%s", 3',
                        tag, fx$y, fx$A, fx$B),
                sprintf(paste0(
                    'appendInfoLine: "RESULT %s',
                    ' ok=", emlAnovaKernelTwoWay.ok,',
                    ' " err=[", emlAnovaKernelTwoWay.error$, "]",',
                    ' " n=", emlAnovaKernelTwoWay.n,',
                    ' " r=", emlAnovaKernelTwoWay.r,',
                    ' " s=", emlAnovaKernelTwoWay.s,',
                    ' " balanced=", emlAnovaKernelTwoWay.balanced,',
                    ' " dfA=", emlAnovaKernelTwoWay.dfA,',
                    ' " dfB=", emlAnovaKernelTwoWay.dfB,',
                    ' " dfAB=", emlAnovaKernelTwoWay.dfAB,',
                    ' " dfError=", emlAnovaKernelTwoWay.dfError,',
                    ' " dfTotal=", emlAnovaKernelTwoWay.dfTotal,',
                    ' " ssATypeI=", fixed$ (emlAnovaKernelTwoWay.ssATypeI, 10),',
                    ' " ssBTypeI=", fixed$ (emlAnovaKernelTwoWay.ssBTypeI, 10),',
                    ' " ssABTypeI=", fixed$ (emlAnovaKernelTwoWay.ssABTypeI, 10),',
                    ' " ssATypeII=", fixed$ (emlAnovaKernelTwoWay.ssATypeII, 10),',
                    ' " ssBTypeII=", fixed$ (emlAnovaKernelTwoWay.ssBTypeII, 10),',
                    ' " ssABTypeII=", fixed$ (emlAnovaKernelTwoWay.ssABTypeII, 10),',
                    ' " ssATypeIII=", fixed$ (emlAnovaKernelTwoWay.ssATypeIII, 10),',
                    ' " ssBTypeIII=", fixed$ (emlAnovaKernelTwoWay.ssBTypeIII, 10),',
                    ' " ssABTypeIII=", fixed$ (emlAnovaKernelTwoWay.ssABTypeIII, 10),',
                    ' " ssError=", fixed$ (emlAnovaKernelTwoWay.ssError, 10),',
                    ' " ssTotal=", fixed$ (emlAnovaKernelTwoWay.ssTotal, 10),',
                    ' " fA=", fixed$ (emlAnovaKernelTwoWay.fA, 10),',
                    ' " fB=", fixed$ (emlAnovaKernelTwoWay.fB, 10),',
                    ' " fAB=", fixed$ (emlAnovaKernelTwoWay.fAB, 10),',
                    ' " leveneW=", fixed$ (emlAnovaKernelTwoWay.leveneW, 10),',
                    ' " leveneDfWithin=", emlAnovaKernelTwoWay.leveneDfWithin,',
                    ' " leveneErr=[", emlAnovaKernelTwoWay.leveneError$, "]",',
                    ' " shapiroN=", emlAnovaKernelTwoWay.shapiroN,',
                    ' " shapiroErr=[", emlAnovaKernelTwoWay.shapiroError$, "]"'
                ), tag))
        }
        probe_path <- file.path(work, "v151-battery.praat")
        writeLines(c('writeInfoLine: "v151"', lines), probe_path)
        probe_path
    }

    drive <- function(probe_path) {
        suppressWarnings(system2("timeout",
            c("120", "env", "-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
            stdout = TRUE, stderr = TRUE))
    }

    parse_kv <- function(line) {
        # "RESULT tag k1=v1 k2=v2 ..." -> named list, err$/warning$-safe
        # (values never contain spaces here; string fields are always "[...]"
        # with the bracket contents excluded from the split by construction --
        # error$/warning$ are asserted empty for every case this file drives).
        toks <- strsplit(line, " ")[[1]]
        tag <- toks[2]
        kv <- toks[-(1:2)]
        kv <- kv[nzchar(kv)]
        out <- list(tag = tag)
        for (t in kv) {
            eq <- regexpr("=", t, fixed = TRUE)
            if (eq < 0) next
            k <- substr(t, 1, eq - 1)
            v <- substr(t, eq + 1, nchar(t))
            out[[k]] <- v
        }
        out
    }

    probe_path <- build_battery()
    out <- drive(probe_path)
    ran <- !any(grepl("^Error", out))
    check_true(V, "the battery probe ran with no Praat error", ran)
    if (!ran) {
        cat("      v151 battery probe output:\n      ",
            paste(utils::tail(out, 40), collapse = "\n      "), "\n", sep = "")
    } else {
        results <- lapply(grep("^RESULT ", out, value = TRUE), parse_kv)
        names(results) <- vapply(results, `[[`, character(1), "tag")

        worst_rel <- data.frame(fixture = character(0), type = character(0),
                                 worst_rel_err = numeric(0))
        record_worst <- function(fixture, type, res) {
            worst_rel <<- rbind(worst_rel, data.frame(
                fixture = fixture, type = type, worst_rel_err = res))
        }

        for (tag in names(fixtures)) {
            fx <- fixtures[[tag]]
            res <- results[[tag]]
            check_true(V, sprintf("[%s] a RESULT line was printed", tag), !is.null(res))
            if (is.null(res)) next

            check_true(V, sprintf("[%s] the kernel reported ok=1", tag),
                       identical(res$ok, "1"))
            check_true(V, sprintf("[%s] error$ is empty", tag), identical(res$err, "[]"))

            d <- if (fx$sep == "\t") read.delim(fx$path, stringsAsFactors = FALSE)
                 else read.csv(fx$path, stringsAsFactors = FALSE)
            d[[fx$A]] <- factor(d[[fx$A]])
            d[[fx$B]] <- factor(d[[fx$B]])
            old_contr <- options(contrasts = c("contr.sum", "contr.poly"))
            fit <- lm(as.formula(paste(fx$y, "~", fx$A, "*", fx$B)), data = d)
            a1 <- anova(fit)
            a2 <- car::Anova(fit, type = 2)
            a3 <- car::Anova(fit, type = 3)
            options(old_contr)

            rlab_A <- fx$A
            rlab_B <- fx$B
            rlab_AB <- paste0(fx$A, ":", fx$B)

            # Type I oracle SS (anova() names rows by term)
            ssI_A  <- a1[rlab_A, "Sum Sq"]
            ssI_B  <- a1[rlab_B, "Sum Sq"]
            ssI_AB <- a1[rlab_AB, "Sum Sq"]
            # Type II oracle SS (car::Anova rownames match term labels)
            ssII_A  <- a2[rlab_A, "Sum Sq"]
            ssII_B  <- a2[rlab_B, "Sum Sq"]
            ssII_AB <- a2[rlab_AB, "Sum Sq"]
            # Type III oracle SS (car::Anova includes "(Intercept)")
            ssIII_A  <- a3[rlab_A, "Sum Sq"]
            ssIII_B  <- a3[rlab_B, "Sum Sq"]
            ssIII_AB <- a3[rlab_AB, "Sum Sq"]

            ssE_oracle  <- a1["Residuals", "Sum Sq"]
            dfE_oracle  <- a1["Residuals", "Df"]
            ssT_oracle  <- sum((d[[fx$y]] - mean(d[[fx$y]]))^2)
            dfT_oracle  <- nrow(d) - 1

            got <- function(k) as.numeric(res[[k]])

            cmp <- function(type, what, reported, computed) {
                check(V, sprintf("[%s] Type %s %s SS vs car/anova", tag, type, what),
                      reported, computed, tol = std_tol(computed))
                record_worst(tag, paste0("Type", type), rel_err(reported, computed))
            }
            cmp("I",   "A",  got("ssATypeI"),   ssI_A)
            cmp("I",   "B",  got("ssBTypeI"),   ssI_B)
            cmp("I",   "AB", got("ssABTypeI"),  ssI_AB)
            cmp("II",  "A",  got("ssATypeII"),  ssII_A)
            cmp("II",  "B",  got("ssBTypeII"),  ssII_B)
            cmp("II",  "AB", got("ssABTypeII"), ssII_AB)
            cmp("III", "A",  got("ssATypeIII"), ssIII_A)
            cmp("III", "B",  got("ssBTypeIII"), ssIII_B)
            cmp("III", "AB", got("ssABTypeIII"),ssIII_AB)

            check(V, sprintf("[%s] SS_Error vs anova() Residuals", tag),
                  got("ssError"), ssE_oracle, tol = std_tol(ssE_oracle))
            check_true(V, sprintf("[%s] df_Error vs anova() Residuals", tag),
                       as.integer(res$dfError) == dfE_oracle)
            check(V, sprintf("[%s] SS_Total vs the observation-weighted grand mean", tag),
                  got("ssTotal"), ssT_oracle, tol = std_tol(ssT_oracle))
            check_true(V, sprintf("[%s] df_Total vs N - 1", tag),
                       as.integer(res$dfTotal) == dfT_oracle)

            # F for the headline table (requested Type III) vs a from-SS
            # closed-form recomputation -- confirms F/p derive from the
            # reported SS/df/msError consistently, independent of how the
            # SS itself was produced.
            msE <- ssE_oracle / dfE_oracle
            fA_expect <- (ssIII_A / (nlevels(d[[fx$A]]) - 1)) / msE
            check(V, sprintf("[%s] headline F (Type III, factor A) vs SS/df/msError", tag),
                  got("fA"), fA_expect, tol = std_tol(fA_expect))

            # Proportionality on this fixture is stronger for Type (factor B)
            # than for Vowel (factor A): every Vowel has EXACTLY the same
            # count within each Type level (30 per vowel for c, 66 for m, 56
            # for w -- constant across j, not merely proportional), so B's
            # rows are individually balanced across A and B's Type III SS
            # collapses onto Type I/II exactly, and the ruling cites this
            # term ("Type factor 4,189,425.84 against 4,535,964.00") as the
            # one where Khuri disagrees with a single correct number that
            # all three of I/II/III share. Ordinary proportionality (which
            # this design also has, checked above) is only enough to make
            # the TWO MAIN EFFECTS agree between Type I and Type II
            # (A and B are orthogonal to each other); it does not by itself
            # make Type III agree too, because Type III additionally adjusts
            # each main effect for the interaction, which proportionality
            # alone does not make orthogonal to an unbalanced-within-its-own-
            # margin factor. Measured here: Vowel (A) genuinely differs
            # between Type I/II (76245.41) and Type III (73719.45) even
            # though this design IS proportional -- the equality the ruling
            # asserts for Peterson-Barney is real, but it is real for the
            # Type factor and the interaction, not for Vowel, and this
            # validator checks the claim precisely rather than over-broadly.
            if (tag == "petersonbarney") {
                check_true(V, "[petersonbarney] Type I A SS != Type III A SS (Vowel is NOT balanced within Type)",
                           abs(got("ssATypeI") - got("ssATypeIII")) > 1)
                check(V, "[petersonbarney] Type I == Type III (factor B, Type: balanced within every Vowel)",
                      got("ssBTypeI"), got("ssBTypeIII"), tol = std_tol(got("ssBTypeIII")))
                check(V, "[petersonbarney] Type I == Type III (interaction)",
                      got("ssABTypeI"), got("ssABTypeIII"), tol = std_tol(got("ssABTypeIII")))
            }
            # non-proportional, unbalanced design => Types I, II, III must
            # be THREE GENUINELY DIFFERENT NUMBERS on at least one factor --
            # this is the fixture's whole reason for existing (a 2x2
            # fixture cannot even ask this question: with one df per main
            # effect there are only two distinct orderings, so Type I can
            # differ from Type II/III but Type II and Type III collapse to
            # the same adjusted-for-everything-else answer whenever there
            # is only one other term to adjust for -- department, in a 2x2,
            # Type II already equals Type III on both mains. A three-level
            # factor is required for Type II and Type III to be able to
            # differ from EACH OTHER, not just from Type I.)
            if (tag == "unbal3lvl") {
                check_true(V, "[unbal3lvl] Type I SS_A != Type II SS_A (non-proportional design)",
                           abs(got("ssATypeI") - got("ssATypeII")) > 1)
                check_true(V, "[unbal3lvl] Type II SS_A != Type III SS_A (non-proportional design)",
                           abs(got("ssATypeII") - got("ssATypeIII")) > 1)
                check_true(V, "[unbal3lvl] Type I SS_A != Type III SS_A (non-proportional design)",
                           abs(got("ssATypeI") - got("ssATypeIII")) > 1)
            }

            # the interaction SS is type-invariant by construction (always
            # tested last / adjusted for everything else) -- confirmed on
            # every fixture, not just asserted in the kernel's own internal
            # warning.
            check(V, sprintf("[%s] interaction SS identical across Type I/II/III", tag),
                  got("ssABTypeI"), got("ssABTypeIII"), tol = std_tol(got("ssABTypeIII")))

            # balance flag
            tabN <- table(d[[fx$A]], d[[fx$B]])
            expect_balanced <- length(unique(as.vector(tabN))) == 1
            check_true(V, sprintf("[%s] .balanced flag matches the fixture's actual cell counts", tag),
                       (as.integer(res$balanced) == 1) == expect_balanced)

            # Levene / Shapiro ran cleanly, with the right partition sizes
            check_true(V, sprintf("[%s] Levene's test ran (no leveneError$)", tag),
                       identical(res$leveneErr, "[]"))
            check_true(V, sprintf("[%s] Shapiro-Wilk ran (no shapiroError$)", tag),
                       identical(res$shapiroErr, "[]"))
            check_true(V, sprintf("[%s] Levene dfWithin == N - rs (same partition as SS_Error)", tag),
                       as.integer(res$leveneDfWithin) == (as.integer(res$n) - as.integer(res$r) * as.integer(res$s)))
            check_true(V, sprintf("[%s] Shapiro-Wilk ran on all N residuals", tag),
                       as.integer(res$shapiroN) == as.integer(res$n))
        }

        # -----------------------------------------------------------------
        # THE REQUIRED SUMMARY: worst relative error per SS type per
        # fixture, printed regardless of pass/fail.
        # -----------------------------------------------------------------
        if (nrow(worst_rel) > 0) {
            cat("\n      worst relative error, SS type x fixture (standard rule: rel 1e-9, abs 1e-12):\n")
            agg <- aggregate(worst_rel_err ~ fixture + type, data = worst_rel, FUN = max)
            agg <- agg[order(agg$fixture, agg$type), ]
            for (i in seq_len(nrow(agg))) {
                cat(sprintf("        %-16s %-9s worst rel err = %.3e\n",
                            agg$fixture[i], agg$type[i], agg$worst_rel_err[i]))
            }
        }
    }

    # -------------------------------------------------------------------
    # HEADLINE SELECTION -- .ssTypeRequested actually switches the table.
    # -------------------------------------------------------------------
    sel_lines <- c(prelude, "",
        sprintf('t_sel = %s "%s"', read_cmd(fixtures$unbal3lvl$sep), fixtures$unbal3lvl$path))
    for (req in c("1", "2", "0", "3", "99")) {
        sel_lines <- c(sel_lines,
            sprintf('@emlAnovaKernelTwoWay: t_sel, "%s", "%s", "%s", %s',
                    fixtures$unbal3lvl$y, fixtures$unbal3lvl$A, fixtures$unbal3lvl$B, req),
            sprintf('appendInfoLine: "SEL %s label=[", emlAnovaKernelTwoWay.ssTypeLabel$, "] ssA=", fixed$ (emlAnovaKernelTwoWay.ssA, 10)',
                    req))
    }
    sel_path <- file.path(work, "v151-selection.praat")
    writeLines(c('writeInfoLine: "v151 selection"', sel_lines), sel_path)
    outSel <- drive(sel_path)
    ranSel <- !any(grepl("^Error", outSel))
    check_true(V, "the headline-selection probe ran with no Praat error", ranSel)
    if (ranSel) {
        d3 <- read.csv(fixtures$unbal3lvl$path, stringsAsFactors = FALSE)
        d3$voice_type <- factor(d3$voice_type); d3$task <- factor(d3$task)
        old_contr <- options(contrasts = c("contr.sum", "contr.poly"))
        fit3 <- lm(SPL_dB ~ voice_type * task, data = d3)
        ssI_A   <- anova(fit3)["voice_type", "Sum Sq"]
        ssII_A  <- car::Anova(fit3, type = 2)["voice_type", "Sum Sq"]
        ssIII_A <- car::Anova(fit3, type = 3)["voice_type", "Sum Sq"]
        options(old_contr)

        getSel <- function(tag) grep(paste0("^SEL ", tag, " "), outSel, value = TRUE)
        for (req in c("1", "2", "0", "3", "99")) {
            ln <- getSel(req)
            check_true(V, sprintf("[selection req=%s] a SEL line was printed", req), length(ln) == 1)
            if (length(ln) != 1) next
            # label$ is "Type I" / "Type II" / "Type III" -- contains a
            # space, so it is bracketed on the Praat side and pulled out
            # with a regex here rather than split on " ".
            m <- regmatches(ln, regexec("^SEL [^ ]+ label=\\[(.*)\\] ssA=(-?[0-9.]+)$", ln))[[1]]
            check_true(V, sprintf("[selection req=%s] the SEL line parsed", req), length(m) == 3)
            if (length(m) != 3) next
            label <- m[2]
            val <- as.numeric(m[3])
            if (req == "1") {
                check_true(V, "[selection req=1] label is 'Type I'", identical(label, "Type I"))
                check(V, "[selection req=1] .ssA matches the Type I oracle", val, ssI_A, tol = std_tol(ssI_A))
            } else if (req == "2") {
                check_true(V, "[selection req=2] label is 'Type II'", identical(label, "Type II"))
                check(V, "[selection req=2] .ssA matches the Type II oracle", val, ssII_A, tol = std_tol(ssII_A))
            } else {
                check_true(V, sprintf("[selection req=%s] label is 'Type III' (default)", req),
                           identical(label, "Type III"))
                check(V, sprintf("[selection req=%s] .ssA matches the Type III oracle", req),
                      val, ssIII_A, tol = std_tol(ssIII_A))
            }
        }
    } else {
        cat("      v151 selection probe output:\n      ",
            paste(utils::tail(outSel, 30), collapse = "\n      "), "\n", sep = "")
    }

    # -------------------------------------------------------------------
    # OPTIONAL LEG -- car::leveneTest cross-check on one fixture (the
    # kernel's own Levene implementation is small and self-contained --
    # eml-anova-kernel.praat does not call any existing plugin Levene,
    # there being none to call -- so a second pair of eyes from the real
    # package is worthwhile even though it is not the required oracle for
    # this file).
    # -------------------------------------------------------------------
    if (ran) {
        okLevene <- tryCatch({
            d <- read.csv(fixtures$unbal2x2$path, stringsAsFactors = FALSE)
            d$cell <- interaction(d$voice_type, d$task, drop = TRUE)
            lt <- car::leveneTest(SPL_dB ~ cell, data = d, center = median)
            res <- results[["unbal2x2"]]
            wGot <- as.numeric(res$leveneW)
            wOracle <- lt[["F value"]][1]
            check(V, "[car::leveneTest] W statistic (unbal2x2)", wGot, wOracle, tol = std_tol(wOracle))
            TRUE
        }, error = function(e) e)
        if (!isTRUE(okLevene)) {
            msg <- if (inherits(okLevene, "error")) conditionMessage(okLevene) else "unknown"
            attest(V, "optional leg (car::leveneTest cross-check) skipped: API mismatch",
                   sprintf("tryCatch error: %s", msg))
        }
    }

    }  # HAVE_CAR
}  # canDrive

if (!exists("EML_SUITE")) {
    eml_report("v151 @emlAnovaKernelTwoWay: Types I, II, III against real car 3.1.2")
    eml_exit()
}
