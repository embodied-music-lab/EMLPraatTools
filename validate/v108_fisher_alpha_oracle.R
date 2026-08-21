# ===========================================================================
# v108 — correlation Fisher-z interval vs R cor.test, at two alphas
# ===========================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. The confidence interval printed beside r in the
# correlation report is a Fisher-z interval: z = atanh(r), se = 1/sqrt(n-3),
# bounds = tanh(z +/- zCrit*se). Its LEVEL is the Alpha the user set on the
# graph dialog (annotAlpha), the same control the t-based error bars and mean
# CIs on the same figure obey. This validator drives the shipped reporter
# @emlReportCorrelationAnalysis (plugin/graphs/eml-annotation-procedures.praat)
# LIVE on one fixed dataset at alpha = .05 and alpha = .01, reads the bracket
# out of the Info text the plugin actually printed, and settles both bounds
# against R's cor.test(conf.level = 1 - alpha), whose interval is the same
# Fisher-z construction.
#
# THE POINT IS THE DIFFERENCE, not either interval alone. A hardcoded
# quantile agrees with cor.test at exactly one alpha and disagrees everywhere
# else, so this run also asserts that the alpha = .01 interval is STRICTLY
# WIDER than the alpha = .05 one at both ends, and that the printed label
# names the level it is (99% / 95%) rather than a fixed string. A reader who
# sees "99% CI for r" beside a 99% error bar is reading one figure; that is
# the disclosure the interval owes.
#
# THE HEADLESS PATH IS DRIVEN TOO. annotAlpha is a graphs-layer global and an
# API or headless caller can reach this reporter without one. The third case
# leaves it unset and asserts the documented 0.05 fallback -- the same
# fallback @emlFormatStars takes -- rather than an error or an undefined
# bracket.
#
# Negative control: a scratch copy of the reporter with the quantile seeded
# back to a hardcoded 1.96 is driven at alpha = .01, and the run asserts its
# bounds DIFFER from the oracle -- which is the whole defect, reproduced on
# demand. Set EML_FISHER_RED=1 to watch the named agreement check go red.
#
# Base R only. No packages. Requires a Praat at or above the plugin's floor.
#
# Registered in validate/run_all.R.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ===========================================================================

V <- "v108"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

red_mode <- nzchar(Sys.getenv("EML_FISHER_RED", unset = ""))

plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
plug <- normalizePath(plug, mustWork = FALSE)

praat <- Sys.getenv("PRAAT", unset = "")
if (!nzchar(praat)) {
    for (cand in c(repo_path("..", "praat"), Sys.which("praat_barren"),
                   Sys.which("praat"))) {
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

# ---------------------------------------------------------------------------
# The fixed dataset. n = 12, r near 0.94 -- far enough from 0 that the
# interval is asymmetric on the r scale, which is what the z transform is for,
# and far enough from 1 that the |r| = 1 guard is not what is being tested.
# ---------------------------------------------------------------------------
X <- c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12)
Y <- c(2, 1, 4, 3, 6, 5, 8, 9, 7, 12, 10, 13)
N <- length(X)

# The oracle pins itself against the closed form before it judges the plugin:
# cor.test's interval must equal tanh(atanh(r) +/- qnorm(1-a/2)/sqrt(n-3)).
fisher_ci <- function(r, n, alpha) {
    z <- atanh(r); se <- 1 / sqrt(n - 3)
    tanh(c(z - qnorm(1 - alpha / 2) * se, z + qnorm(1 - alpha / 2) * se))
}
r_hat <- cor(X, Y)
for (a in c(0.05, 0.01)) {
    ci <- cor.test(X, Y, conf.level = 1 - a)$conf.int
    hand <- fisher_ci(r_hat, N, a)
    check(V, sprintf("oracle vs closed-form Fisher z, alpha=%.2f, lower", a),
          ci[1], hand[1], tol = 1e-12)
    check(V, sprintf("oracle vs closed-form Fisher z, alpha=%.2f, upper", a),
          ci[2], hand[2], tol = 1e-12)
}

if (!canDrive) {
    cat(paste0("      SKIP: v108 needs Praat >= 6.6.30 to drive the reporter;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v108")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    vec <- function(v) paste0("{", paste(format(v, digits = 17), collapse = ", "), "}")

    # Same include set as harness/stress_cases/_prelude.praat, minus the
    # interactive wrapper: the draw and annotation layers are not
    # self-contained, so the stats layer comes along.
    prelude <- function(annot_file) c(
        paste0("include ", file.path(plug, "graphs", "eml-graph-procedures.praat")),
        paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
        paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
        paste0("include ", file.path(plug, "stats", "eml-extract.praat")),
        paste0("include ", file.path(plug, "stats", "eml-output.praat")),
        paste0("include ", file.path(plug, "stats", "eml-inferential.praat")),
        paste0("include ", annot_file),
        paste0("include ", file.path(plug, "graphs", "eml-draw-procedures.praat")))

    # alpha = NA drives the headless path: annotAlpha is never assigned.
    drive <- function(alpha, tag, annot_file = file.path(
                          plug, "graphs", "eml-annotation-procedures.praat")) {
        probe <- file.path(work, paste0("v108-", tag, ".praat"))
        writeLines(c(
            prelude(annot_file),
            "",
            "emlShowExplanations = 0",
            if (is.na(alpha)) "# annotAlpha deliberately unset"
            else sprintf("annotAlpha = %s", format(alpha, digits = 17)),
            sprintf(".x# = %s", vec(X)),
            sprintf(".y# = %s", vec(Y)),
            "@emlPearsonCorrelation: .x#, .y#, 2",
            "@emlCSVInit",
            'writeInfoLine: "v108"',
            sprintf('@emlReportCorrelationAnalysis: "T", "X", "Y", %d, "pearson"', N)),
            probe)
        suppressWarnings(system2("env",
            c("-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe)),
            stdout = TRUE, stderr = TRUE))
    }

    # Read the printed bracket AND the level out of its own label, so the
    # label is evidence rather than decoration.
    parse_ci <- function(out) {
        h <- grep("% CI for r", out, value = TRUE)
        if (!length(h)) return(list(level = NA_real_, lo = NA_real_, hi = NA_real_))
        m <- regmatches(h[1], regexec(
            "([0-9]+)% CI for r\\s+\\[\\s*(-?[0-9.]+),\\s*(-?[0-9.]+)\\]", h[1]))[[1]]
        if (length(m) < 4) return(list(level = NA_real_, lo = NA_real_, hi = NA_real_))
        list(level = as.numeric(m[2]),
             lo = as.numeric(m[3]), hi = as.numeric(m[4]))
    }

    # The report prints 4 decimals, so the tolerance is half a printed unit.
    tolp <- 5e-5

    got <- list()
    for (cs in list(list(a = 0.05, tag = "a05", lvl = 95),
                    list(a = 0.01, tag = "a01", lvl = 99),
                    list(a = NA,   tag = "unset", lvl = 95))) {
        out <- drive(cs$a, cs$tag)
        ci <- parse_ci(out)
        ran <- !any(grepl("^Error", out)) && is.finite(ci$lo)
        check_true(V, sprintf("the %s probe ran and printed an interval", cs$tag), ran)
        if (!ran) {
            cat(sprintf("      v108 %s probe output: %s\n", cs$tag,
                        paste(utils::tail(out, 10), collapse = " / ")))
            next
        }
        got[[cs$tag]] <- ci
        # The effective alpha: the unset case must fall back to 0.05.
        aeff <- if (is.na(cs$a)) 0.05 else cs$a
        oracle <- cor.test(X, Y, conf.level = 1 - aeff)$conf.int
        check(V, sprintf("[%s] printed confidence level", cs$tag),
              ci$level, cs$lvl, tol = 0)
        check(V, sprintf("[%s] Fisher-z lower bound vs cor.test", cs$tag),
              ci$lo, oracle[1], tol = tolp)
        check(V, sprintf("[%s] Fisher-z upper bound vs cor.test", cs$tag),
              ci$hi, oracle[2], tol = tolp)
    }

    # -----------------------------------------------------------------------
    # The control the user set actually moves the interval.
    # -----------------------------------------------------------------------
    if (!is.null(got$a05) && !is.null(got$a01)) {
        check_true(V, "alpha = .01 widens the interval downward",
                   got$a01$lo < got$a05$lo)
        check_true(V, "alpha = .01 widens the interval upward",
                   got$a01$hi > got$a05$hi)
        check_true(V, "the unset path reproduces the alpha = .05 interval",
                   isTRUE(all.equal(unlist(got$unset), unlist(got$a05))))
    }

    # -----------------------------------------------------------------------
    # NEGATIVE CONTROL — the quantile seeded back to a hardcoded 1.96.
    # At alpha = .01 the seeded build prints a 95% interval under a 99%
    # label, which is the defect this validator exists to keep out.
    # -----------------------------------------------------------------------
    src_path <- file.path(plug, "graphs", "eml-annotation-procedures.praat")
    src <- readLines(src_path, warn = FALSE)
    needle <- ".zCrit = invGaussQ (.ciAlpha / 2)"
    hit <- grepl(needle, src, fixed = TRUE)
    check_true(V, "the negative-control seed site exists in source", sum(hit) == 1)
    if (sum(hit) == 1) {
        mut <- file.path(work, "mutant")
        dir.create(mut, showWarnings = FALSE)
        mut_file <- file.path(mut, "eml-annotation-procedures.praat")
        writeLines(sub(needle, ".zCrit = 1.96", src, fixed = TRUE), mut_file)

        oracle99 <- cor.test(X, Y, conf.level = 0.99)$conf.int
        out_mut <- drive(0.01, "mutant", annot_file = mut_file)
        cim <- parse_ci(out_mut)
        check_true(V, "the seeded-defect probe ran", is.finite(cim$lo))
        if (red_mode) {
            cat("      EML_FISHER_RED: running the standard agreement check against\n")
            cat("      the defective build — the next check is EXPECTED to FAIL.\n")
            check(V, "[RED] seeded-1.96 lower bound vs cor.test at .01 (must go red)",
                  cim$lo, oracle99[1], tol = tolp)
        } else {
            check(V, "seeded-1.96 lower bound DIFFERS from the oracle at alpha = .01",
                  cim$lo, oracle99[1], tol = tolp, expect = "differ")
            check(V, "seeded-1.96 upper bound DIFFERS from the oracle at alpha = .01",
                  cim$hi, oracle99[2], tol = tolp, expect = "differ")
            # And it mislabels: a 95% interval printed under a 99% heading.
            check(V, "seeded-1.96 still prints the 99% label over a 95% interval",
                  cim$level, 99, tol = 0)
            if (!is.null(got$a05)) {
                check(V, "seeded-1.96 lower bound equals the alpha = .05 interval",
                      cim$lo, got$a05$lo, tol = tolp)
            }
        }
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v108 correlation Fisher-z interval oracle")
    eml_exit()
}
