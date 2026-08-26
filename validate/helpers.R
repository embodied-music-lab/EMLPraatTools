# ============================================================================
# EML Stats & Graphs — validation helpers
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# Base R only. No packages are loaded and none need installing. Every
# statistic the plugin reports is recomputed here from first principles or
# from base `stats`, so an independent reviewer can run this suite against a
# stock R installation with no network access.
# ============================================================================

EML_RESULTS <- new.env(parent = emptyenv())
EML_RESULTS$rows <- list()

# ---------------------------------------------------------------------------
# repo_path — resolve a path relative to the repository root, regardless of
# the working directory the suite is launched from.
# ---------------------------------------------------------------------------
repo_path <- function(...) {
    here <- Sys.getenv("EML_VALIDATE_DIR", unset = NA)
    if (is.na(here)) {
        args <- commandArgs(trailingOnly = FALSE)
        f <- sub("^--file=", "", args[grep("^--file=", args)])
        here <- if (length(f)) dirname(normalizePath(f)) else getwd()
    }
    root <- dirname(here)
    file.path(root, ...)
}

read_input <- function(name) {
    p <- repo_path("evidence", "csv", name)
    if (!file.exists(p)) stop("input not found: ", p)
    read.csv(p, stringsAsFactors = FALSE)
}

# ---------------------------------------------------------------------------
# check — record one comparison between a value the plugin PRINTED and the
# value R computes.
#
#   id        finding or wrapper this belongs to
#   what      human description of the quantity
#   reported  the value the plugin printed, transcribed from the Info window
#   computed  what R computes here
#   tol       absolute tolerance; default follows the printed precision
#   expect    "match"  — these must agree; disagreement is a FAILURE
#             "differ" — these must NOT agree; agreement is a FAILURE.
#                        Used to pin a known defect (see D15).
# ---------------------------------------------------------------------------
check <- function(id, what, reported, computed, tol = 5e-4, expect = "match") {
    # V7, 6 Aug 2026. `agree` is FALSE whenever either side is non-finite, so
    # the old `!agree` made expect="differ" PASS on NaN or Inf: a distinctness
    # guard would have been satisfied by a degenerate computation rather than
    # by a genuine difference. check(NaN, 5, expect="differ") passed.
    # Both branches now require both values to be finite first.
    finite_both <- is.finite(reported) && is.finite(computed)
    agree <- finite_both && abs(reported - computed) <= tol
    pass <- if (expect == "match") agree else (finite_both && !agree)
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = what, reported = reported, computed = computed,
        tol = tol, expect = expect, pass = pass, stringsAsFactors = FALSE
    )
    invisible(pass)
}

# check_below — the plugin floors small p-values to the string "< .001".
# All that can be validated is that R's value is genuinely below .001.
check_below <- function(id, what, threshold, computed) {
    pass <- is.finite(computed) && computed < threshold
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = what, reported = NA_real_, computed = computed,
        tol = threshold, expect = paste0("< ", threshold), pass = pass,
        stringsAsFactors = FALSE
    )
    invisible(pass)
}

# check_true — a non-numeric assertion (a behaviour, a count, a condition).
check_true <- function(id, what, condition) {
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = what, reported = NA_real_, computed = NA_real_,
        tol = NA_real_, expect = "TRUE", pass = isTRUE(condition),
        stringsAsFactors = FALSE
    )
    invisible(isTRUE(condition))
}

# ---------------------------------------------------------------------------
# eml_census — EVERYTHING THE DRIVER RENDERED IS LOOKED AT BY SOMETHING.
#
# WHY THIS EXISTS, and it is not a hypothetical. On 11 August 2026 block 7 was
# added to harness/legend/run.sh: twenty new figures, rendered, measured and
# written to RESULTS.tsv. Every assertion written for them passed on the first
# run, and every pre-existing assertion passed too. The suite would have gone
# green with twenty figures that no INVENTORY had been told existed. One line
# in v32 -- a sum of the block sizes against the row count of the file --
# disagreed, and it was the only thing in the tree that could have.
#
# The failure it guards is SILENT NON-COVERAGE, and it is a different animal
# from a wrong answer. Every other check in a validator asks "is this value
# right"; each one is scoped to a subset the author named. Add a population
# nothing named and all of them keep passing, correctly, because none of them
# was ever making a claim about anything outside itself. No number of
# per-subset checks adds up to a statement about the whole file.
#
# THE ARGUMENT IS SET-BASED, NOT A COUNT. Two counts can agree by coincidence
# -- one case dropped and one added is a wash -- and a count cannot say WHICH
# case fell through. So both sides are vectors of case identifiers, and the
# failure names the orphans.
#
#   id         the validator id, as everywhere else
#   what       what the population is, for the report line
#   present    every case identifier the ARTEFACT contains. Read off the file
#              the driver wrote -- never re-derived from the same list the
#              checks were built from, or the two sides cannot disagree.
#   accounted  every case identifier some check in this file asserts on
#
# A case may be accounted for more than once; overlap is fine and is not what
# this is about. What is not fine is a case in `present` and in nothing else.
#
# The reverse direction is checked too: an identifier the validator asserts on
# that the artefact does not contain means the checks are reading a case that
# was never rendered, which passes vacuously today and is the other way a
# suite quietly stops testing what it claims to.
# ---------------------------------------------------------------------------
eml_census <- function(id, what, present, accounted) {
    present   <- unique(as.character(present))
    accounted <- unique(as.character(accounted))
    orphan    <- setdiff(present, accounted)
    phantom   <- setdiff(accounted, present)

    ok <- check_true(id, sprintf("every %s is accounted for by some check", what),
                     length(orphan) == 0)
    if (length(orphan) > 0) {
        check_true(id, sprintf("  orphaned %s: %s", what,
                               paste(utils::head(orphan, 8), collapse = ", ")),
                   FALSE)
    }
    ok2 <- check_true(id, sprintf("every %s a check reads was actually rendered", what),
                      length(phantom) == 0)
    if (length(phantom) > 0) {
        check_true(id, sprintf("  phantom %s: %s", what,
                               paste(utils::head(phantom, 8), collapse = ", ")),
                   FALSE)
    }
    invisible(ok && ok2)
}

# ---------------------------------------------------------------------------
# eml_claim — WHICH VALIDATOR COVERS WHICH CASES, recorded as the suite runs.
#
# eml_census answers "does THIS file look at everything in the artefact". That
# is the wrong unit for most of this tree, and §19 of the audit says why: most
# validators are scoped to a subset ON PURPOSE. v27 reads the 39-row stress
# artefact and asserts on the ten empty_* cases because empty frames are what
# it is about. Demanding it account for all 39 would demand assertions it is
# not for -- and would have hidden §17 behind a green check instead of
# surfacing it. 29 cases were rendered, measured, committed, and looked at by
# nothing, and no per-file check could say so.
#
# The coverage question is therefore per ARTEFACT, across every validator that
# reads it: for each thing a driver renders, is there SOME authored check that
# names it?
#
# Answering it needs a map, and a hand-maintained map drifts -- it would be
# one more list that can disagree with reality, which is the failure this is
# supposed to catch. So the map is not written down. Each validator records
# what it claims WHILE IT RUNS, into this accumulator, and the coverage pass
# at the end of run_all.R compares the union of the claims against the
# population it reads off disk itself. A validator that stops asserting on a
# case stops claiming it in the same edit, because the claim is made from the
# same vector the checks loop over.
#
#   id        the validator id
#   artefact  a stable key for the rendered population, e.g. "stress_out"
#   cases     the case identifiers this validator asserts on
#
# Claims are additive and may overlap: two validators covering the same case
# is fine and common (v27 and v36 share the ten empty frames). What is not
# fine is a case no claim mentions.
# ---------------------------------------------------------------------------
EML_COVERAGE <- new.env(parent = emptyenv())
EML_COVERAGE$claims <- list()

eml_claim <- function(id, artefact, cases) {
    cases <- unique(as.character(cases))
    cases <- cases[!is.na(cases) & nzchar(cases)]
    EML_COVERAGE$claims[[length(EML_COVERAGE$claims) + 1L]] <-
        list(id = id, artefact = artefact, cases = cases)
    invisible(length(cases))
}

# eml_claimed — every case some validator claimed for one artefact.
eml_claimed <- function(artefact) {
    cl <- Filter(function(x) identical(x$artefact, artefact),
                 EML_COVERAGE$claims)
    unique(unlist(lapply(cl, function(x) x$cases)))
}

# eml_claimants — which validators claimed anything for one artefact. Reported
# so that "covered" can be read as "covered BY WHAT" rather than taken on
# trust, and so an artefact that lost its only reader is visible.
eml_claimants <- function(artefact) {
    cl <- Filter(function(x) identical(x$artefact, artefact),
                 EML_COVERAGE$claims)
    unique(vapply(cl, function(x) x$id, character(1)))
}

# @attest — a claim backed by a screenshot or a recorded observation, not by
# anything this script can evaluate.
#
# V8, 6 Aug 2026. These were written as check_true(id, what, TRUE): honest in
# their prose, but structurally identical to a real check and counted in the
# totals, so five of the suite's checks could never fail and a reviewer
# reading "446 checks, 445 passed" was told something slightly untrue about
# what had been verified. They are now a separate class, printed as ATTEST,
# excluded from the check counts and from the exit status.
#
# An attestation is not worthless -- it records what was observed and points
# at the artefact -- but it is evidence, not a test, and the report now says
# which it is.
attest <- function(id, what, evidence = "") {
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = what, reported = NA_real_, computed = NA_real_,
        tol = NA_real_, expect = "attested", pass = TRUE,
        stringsAsFactors = FALSE
    )
    invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Statistics the plugin reports that base R does not provide directly.
# Implemented from the standard definitions so the suite stays dependency-free.
# ---------------------------------------------------------------------------

# Cohen's d for two independent samples, pooled SD (the classic definition).
cohens_d <- function(a, b) {
    na <- length(a); nb <- length(b)
    sp <- sqrt(((na - 1) * var(a) + (nb - 1) * var(b)) / (na + nb - 2))
    (mean(a) - mean(b)) / sp
}

# Cohen's d_z for a paired design: mean difference over SD of differences.
cohens_dz <- function(a, b) {
    d <- a - b
    mean(d) / sd(d)
}

# r derived from a t statistic: r = t / sqrt(t^2 + df).
r_from_t <- function(t, df) t / sqrt(t^2 + df)

# Matched-pairs rank-biserial correlation for the Wilcoxon signed-rank test.
# r = 1 - 2W / (n(n+1)/2), with W the sum of ranks of the negative
# differences as returned by wilcox.test's V statistic convention.
rank_biserial_paired <- function(a, b) {
    d <- a - b
    d <- d[d != 0]
    n <- length(d)
    V <- suppressWarnings(unname(wilcox.test(a, b, paired = TRUE)$statistic))
    1 - 2 * (n * (n + 1) / 2 - V) / (n * (n + 1) / 2)
}

# One-way repeated-measures ANOVA on a subjects x conditions matrix,
# with the Greenhouse-Geisser epsilon.
rm_anova <- function(Y) {
    n <- nrow(Y); k <- ncol(Y)
    gm <- mean(Y)
    subj_m <- rowMeans(Y); cond_m <- colMeans(Y)
    ss_cond <- n * sum((cond_m - gm)^2)
    ss_subj <- k * sum((subj_m - gm)^2)
    ss_tot  <- sum((Y - gm)^2)
    ss_err  <- ss_tot - ss_cond - ss_subj
    df_c <- k - 1; df_e <- (k - 1) * (n - 1)
    ms_c <- ss_cond / df_c; ms_e <- ss_err / df_e
    f <- ms_c / ms_e
    p <- pf(f, df_c, df_e, lower.tail = FALSE)

    S  <- cov(Y)
    sb <- mean(S); rm_ <- rowMeans(S)
    num <- k^2 * (mean(diag(S)) - sb)^2
    den <- (k - 1) * (sum(S^2) - 2 * k * sum(rm_^2) + k^2 * sb^2)
    gg  <- num / den

    list(F = f, df1 = df_c, df2 = df_e, p = p, gg = gg,
         p_gg = pf(f, df_c * gg, df_e * gg, lower.tail = FALSE),
         partial_eta2 = ss_cond / (ss_cond + ss_err),
         means = cond_m, n = n, k = k)
}

# Kendall's W from the Friedman chi-square.
kendalls_w <- function(chisq, n, k) chisq / (n * (k - 1))

# ---------------------------------------------------------------------------
# Reporting
# ---------------------------------------------------------------------------
eml_report <- function(title) {
    df <- do.call(rbind, EML_RESULTS$rows)
    if (is.null(df)) { cat("no checks recorded\n"); return(invisible(NULL)) }
    cat("\n", strrep("=", 78), "\n", title, "\n", strrep("=", 78), "\n", sep = "")

    # QUIET BY DEFAULT. A passing assertion's text is only useful once it stops
    # passing, and printing every one of them costs the reader far more than it
    # informs: on 26 August four validators emitted 2,107 lines, of which 2,079
    # were PASS. Failures and attestations always print, in full. Set
    # EML_VERBOSE=1 to see the passing lines too.
    .emlVerbose <- nzchar(Sys.getenv("EML_VERBOSE"))
    .emlAnyFail <- any(!df$pass[df$expect != "attested"])
    .emlShowAll <- .emlVerbose || .emlAnyFail

    for (i in seq_len(nrow(df))) {
        r <- df[i, ]
        if (!.emlShowAll && r$pass && !identical(r$expect, "attested")) next
        mark <- if (identical(r$expect, "attested")) {
            "ATST"
        } else if (r$pass) "PASS" else "FAIL"
        val <- if (is.na(r$reported)) {
            sprintf("computed=%.10g  expected %s", r$computed, r$expect)
        } else {
            sprintf("reported=%.10g  computed=%.10g  (%s, tol %g)",
                    r$reported, r$computed, r$expect, r$tol)
        }
        cat(sprintf("%-4s  %-6s  %-46s  %s\n", mark, r$id, r$quantity, val))
    }
    att <- df$expect == "attested"
    chk <- df[!att, , drop = FALSE]
    n_fail <- sum(!chk$pass)
    cat(strrep("-", 78), "\n")
    cat(sprintf("%d checks, %d passed, %d FAILED\n",
                nrow(chk), sum(chk$pass), n_fail))
    if (any(att)) {
        cat(sprintf("%d attestation(s) recorded, not counted as checks\n",
                    sum(att)))
    }
    invisible(df)
}

eml_exit <- function() {
    df <- do.call(rbind, EML_RESULTS$rows)
    if (!is.null(df)) {
        chk <- df[df$expect != "attested", , drop = FALSE]
        if (any(!chk$pass)) quit(status = 1)
    }
    invisible(NULL)
}


# ============================================================================
# Additions for the orchestrator suites (v08-v15), 5 August 2026
#
# Everything below is implemented from its standard definition because base
# R has no direct function for it. That is deliberate: the suite must run on
# a stock R install. It also means these definitions are themselves open to
# challenge, which is the point — see "For an independent reviewer" in
# REGISTRY.md.
# ============================================================================

# Skewness and excess kurtosis, in the SAMPLE-CORRECTED (unbiased) forms.
#
# These are the G1 and G2 of SPSS, SAS and Excel, and they are what the
# plugin computes — read off @emlSkewness and @emlKurtosis in
# stats/eml-core-descriptive.praat, not inferred from agreement:
#
#     z_i = (x_i - xbar) / s          with s the SAMPLE SD (n - 1)
#     G1  = n / ((n-1)(n-2)) * sum z^3
#     G2  = n(n+1) / ((n-1)(n-2)(n-3)) * sum z^4
#           - 3(n-1)^2 / ((n-2)(n-3))
#
# Three distinct conventions get called "skewness" and "kurtosis" and they
# do not agree:
#   * the population moments g1 and g2, which R's own examples often use;
#   * these sample-corrected G1 and G2;
#   * Pearson's b2 for kurtosis, which is G2 + 3 and makes a normal
#     distribution read 3 rather than 0.
# On the n = 45 column in v14 the first two differ in the second decimal
# (g1 = -0.0392 against G1 = -0.0406; g2 = -0.0052 against G2 = 0.1404),
# which is inside the printed precision. A suite that left the convention
# implicit would be asserting nothing.
#
# G2 is an EXCESS form: a normal distribution gives 0, not 3. That is what
# the plugin's "Kurtosis (excess)" label claims, and v14 checks the claim.
excess_kurtosis <- function(x) {
    n <- length(x); z <- (x - mean(x)) / sd(x)
    n * (n + 1) / ((n - 1) * (n - 2) * (n - 3)) * sum(z^4) -
        3 * (n - 1)^2 / ((n - 2) * (n - 3))
}

skewness_g1 <- function(x) {
    n <- length(x); z <- (x - mean(x)) / sd(x)
    n / ((n - 1) * (n - 2)) * sum(z^3)
}

# Dunn's post-hoc test following the Kruskal-Wallis H test.
#
# z_ij = (Rbar_i - Rbar_j) / sqrt( ((N(N+1)/12) - T) * (1/n_i + 1/n_j) )
#
# with Rbar the mean rank of a group and T the tie correction
# sum(t^3 - t) / (12(N-1)) over tied groups. Two-sided p from the normal.
# This is Dunn (1964) as implemented by scikit-posthocs' posthoc_dunn.
dunn_test <- function(x, g) {
    ok <- !is.na(x) & !is.na(g)
    x <- x[ok]; g <- factor(g[ok])
    N <- length(x); r <- rank(x)
    tie <- table(r)
    Tc <- sum(tie^3 - tie) / (12 * (N - 1))
    lv <- levels(g)
    Rbar <- tapply(r, g, mean); n <- tapply(r, g, length)
    z <- matrix(NA_real_, length(lv), length(lv), dimnames = list(lv, lv))
    p <- z
    for (i in seq_along(lv)) for (j in seq_along(lv)) {
        if (i == j) next
        se <- sqrt((N * (N + 1) / 12 - Tc) * (1 / n[i] + 1 / n[j]))
        z[i, j] <- (Rbar[i] - Rbar[j]) / se
        p[i, j] <- 2 * pnorm(-abs(z[i, j]))
    }
    list(z = z, p = p, meanrank = Rbar, n = n, levels = lv)
}

# Rank-biserial r for two INDEPENDENT groups, from the Mann-Whitney U:
#
#     r = (U1 - U2) / (n1 * n2)
#
# equivalently 2*U1/(n1*n2) - 1. This is the DIRECTED (common-language)
# form: r is positive when group 1 tends to exceed group 2 and negative when
# it does not, so its sign agrees with the sign of Cohen's d on the same
# pair. The competing convention 1 - 2*U1/(n1*n2) is also in the literature
# and gives the opposite sign; a reviewer who prefers it will see every
# rank-biserial value in v08 and v10 flip, and nothing else change.
#
# The convention matters more than it looks. Sign is the only part of an
# effect size a wrapper can get wrong while every magnitude stays right,
# which is why v08 also asserts that the sign tracks the mean difference
# rather than only asserting the number.
rank_biserial_indep <- function(a, b) {
    U1 <- suppressWarnings(unname(wilcox.test(a, b)$statistic))
    U2 <- length(a) * length(b) - U1
    (U1 - U2) / (length(a) * length(b))
}

# Epsilon-squared for Kruskal-Wallis: eps2 = H / ((N^2 - 1)/(N + 1)).
epsilon_squared <- function(H, N) H / ((N^2 - 1) / (N + 1))

# Holm step-down adjustment over a vector of raw p-values, written out
# rather than using p.adjust so the monotonicity constraint is visible.
holm_adjust <- function(p) {
    m <- length(p); o <- order(p); adj <- numeric(m); run <- 0
    for (i in seq_len(m)) {
        run <- max(run, (m - i + 1) * p[o[i]])
        adj[o[i]] <- min(1, run)
    }
    adj
}

# Partial eta-squared for a term in a factorial ANOVA:
#   SS_effect / (SS_effect + SS_error).
partial_eta2 <- function(ss_effect, ss_error) ss_effect / (ss_effect + ss_error)


# ============================================================================
# READING WHAT THE PLUGIN ACTUALLY PRINTED
#
# Everything above compares a number the plugin produced against a number R
# computes. Until 5 August the plugin's number reached the comparison as a
# LITERAL, typed into the script by hand from an Info-window capture. That
# put an unwitnessed step in the middle of the chain:
#
#   Praat prints X -> [transcription] -> literal in the script -> R -> compare
#
# A reviewer running this suite verified the right-hand half only. If a
# literal had been copied from R's own output instead of from Praat's, every
# check would pass and the suite would validate nothing — which is precisely
# the failure that plugin/dev/tests/REFERENCE_PROVENANCE.md exists to prevent
# on the other side ("never from the library's own output. That rule is what
# makes the suites a test of the library rather than a photograph").
#
# The functions below remove the step. @printed reads the value out of the
# committed capture, so a green run means: what the capture says Praat
# printed agrees with base R. The one remaining act of trust is that the
# capture came from a real run, and only re-running Praat settles that.
#
# They FAIL LOUDLY on a label that is ABSENT, on an occurrence past the last
# match, and on a value that does not parse as a number. A capture that drifts
# out of step with the script breaks the suite rather than quietly stopping
# testing anything.
#
# They do NOT fail on an AMBIGUOUS label. Several matches resolve to the
# first, silently. Until 6 August 2026 this comment claimed otherwise, and so
# did REGISTRY; both were wrong, and the ambiguity is real in the committed
# captures (see .cap_fields). A caller that depends on a label matching
# exactly once, or exactly n times, must say so with expect_hits.
# ============================================================================

capture <- function(name) {
    p <- repo_path("evidence", "info", name)
    if (!file.exists(p)) stop("capture not found: ", p)
    structure(list(lines = readLines(p, warn = FALSE), name = name),
              class = "eml_capture")
}

# Internal: the raw text to the right of a label, as whitespace-separated
# fields. Praat pads labels and separates columns with runs of spaces, so
# two-or-more spaces is the field separator and a single space inside a
# label ("Mean difference", "Q2 (Median)") is preserved.
.cap_fields <- function(cap, label, occurrence = 1L, expect_hits = NULL) {
    stopifnot(inherits(cap, "eml_capture"))
    # Matched WITHOUT a regex on the label. Praat labels contain characters
    # that are regex metacharacters — "Cohen's d", "Q2 (Median)",
    # "F(1,23)", "voice type x task" — and escaping them portably is more
    # fragile than not needing to.
    lt   <- trimws(cap$lines)
    hits <- which(startsWith(lt, label) &
                  substr(lt, nchar(label) + 1L, nchar(label) + 2L) == "  ")
    if (!length(hits)) {
        stop(sprintf("label '%s' not found in capture %s", label, cap$name))
    }
    if (occurrence > length(hits)) {
        stop(sprintf("label '%s' occurs %d time(s) in %s; occurrence %d requested",
                     label, length(hits), cap$name, occurrence))
    }
    # V4, 6 Aug 2026. This function halts on an ABSENT label and on an
    # occurrence past the end, but a label matching several lines resolved
    # silently to the first -- while helpers.R and REGISTRY both claimed an
    # ambiguous label halts the suite. It does not, and it never did.
    #
    # It matters here more than it looks. In the committed captures "Soprano"
    # matches 5 lines in v09 and 7 in v10 (the descriptives row, plus the
    # header and body rows of two matrices), and "voice type" and "task" match
    # 2 each in v11. Those reads are correct today only because block order is
    # stable -- exactly the fragility printed_cell was written to remove, and
    # it was applied to the matrices but not to the descriptives above them.
    #
    # expect_hits lets a caller state how many lines it believes the label
    # matches, and turns a wrong belief into a halt. It is opt-in because
    # making ambiguity fatal everywhere would break correct call sites that
    # simply never said what they were relying on.
    if (!is.null(expect_hits) && length(hits) != expect_hits) {
        stop(sprintf(
            "label '%s' matches %d line(s) in %s; %d expected. Capture layout has changed, or the label is more ambiguous than the call site believed.",
            label, length(hits), cap$name, expect_hits))
    }
    rest <- substring(lt[hits[occurrence]], nchar(label) + 1L)
    trimws(strsplit(trimws(rest), "[ \t]{2,}")[[1]])
}

# printed — the NUMBER the plugin printed against `label`.
#
#   field       which column, for table and matrix rows. Field 1 is the
#               first value after the label.
#   occurrence  which instance, when a label repeats (three "N" lines in
#               the normality report, one per column).
printed <- function(cap, label, field = 1L, occurrence = 1L,
                    expect_hits = NULL) {
    f <- .cap_fields(cap, label, occurrence, expect_hits)
    if (field > length(f)) {
        stop(sprintf("label '%s' in %s has %d field(s); field %d requested",
                     label, cap$name, length(f), field))
    }
    raw <- f[field]
    v <- suppressWarnings(as.numeric(raw))
    if (is.na(v)) {
        stop(sprintf("value '%s' for label '%s' in %s is not numeric — use printed_str()",
                     raw, label, cap$name))
    }
    v
}

# printed_str — the raw TEXT, for the values that are deliberately not
# numbers: "p < .001", "exact", "large effect", "---".
printed_str <- function(cap, label, field = 1L, occurrence = 1L,
                        expect_hits = NULL) {
    f <- .cap_fields(cap, label, occurrence, expect_hits)
    if (field > length(f)) {
        stop(sprintf("label '%s' in %s has %d field(s); field %d requested",
                     label, cap$name, length(f), field))
    }
    f[field]
}

# check_floored — the plugin floors small p-values to the string "< .001".
# Asserts BOTH that the capture really says that and that R agrees it is
# below the threshold. The old check_below() only did the second half, so it
# could not tell a floored p from a p the script's author had assumed was
# floored.
check_floored <- function(id, what, cap, label, computed,
                          field = 1L, occurrence = 1L, threshold = 0.001) {
    s <- printed_str(cap, label, field, occurrence)
    # V12, 6 Aug 2026. The old pattern "<\\s*\\.?0*\\.?001" also matched
    # "< .0001": with \\.? taking the point and 0* taking a single zero, the
    # literal 001 then matched the tail. So "the capture really says < .001"
    # was asserted more loosely than its comment claimed. Anchored to the two
    # spellings that are actually meant, and nothing else. Anchored at the END
    # rather than the start, because the field carries its own label: the
    # string read here is "p < .001", not "< .001".
    says <- grepl("(^|\\s)<\\s*0?\\.001$", trimws(s))
    pass <- says && is.finite(computed) && computed < threshold
    EML_RESULTS$rows[[length(EML_RESULTS$rows) + 1L]] <- data.frame(
        id = id, quantity = paste0(what, " [capture says '", s, "']"),
        reported = NA_real_, computed = computed, tol = threshold,
        expect = paste0("< ", threshold), pass = pass, stringsAsFactors = FALSE
    )
    invisible(pass)
}


# printed_cell — one cell of a printed MATRIX, addressed by section, row
# name and column name rather than by position.
#
# The post-hoc matrices are where a transposition or an off-by-one would do
# the most damage and be hardest to see: every value present, every value
# correct, in the wrong place. Addressing a cell positionally would make the
# check blind to exactly that. This resolves the column from the matrix's
# own printed header, so a transposed matrix fails.
#
# It also sidesteps a real hazard: in the ANOVA capture the string "Soprano"
# begins five different lines — a descriptives row, and the header and body
# rows of two separate matrices — so occurrence counting is fragile there.
printed_cell <- function(cap, section, row, col, as_string = FALSE) {
    stopifnot(inherits(cap, "eml_capture"))
    lt <- trimws(cap$lines)
    sec <- grep(section, cap$lines, fixed = TRUE)
    if (!length(sec)) {
        stop(sprintf("section '%s' not found in capture %s", section, cap$name))
    }
    start <- sec[1] + 1L
    hdr <- NA_integer_; cols <- character(0)
    for (i in seq(start, length(lt))) {
        if (!nzchar(lt[i])) next
        f <- trimws(strsplit(lt[i], "[ \t]{2,}")[[1]])
        if (col %in% f) { hdr <- i; cols <- f; break }
        if (grepl("^──", lt[i])) break          # ran into the next section
    }
    if (is.na(hdr)) {
        stop(sprintf("column '%s' not found in the header of section '%s' (%s)",
                     col, section, cap$name))
    }
    ci <- which(cols == col)[1]
    for (i in seq(hdr + 1L, length(lt))) {
        if (grepl("^──", lt[i]) || grepl("^═", lt[i])) break
        if (!startsWith(lt[i], row)) next
        if (substr(lt[i], nchar(row) + 1L, nchar(row) + 2L) != "  ") next
        f <- trimws(strsplit(trimws(substring(lt[i], nchar(row) + 1L)),
                             "[ \t]{2,}")[[1]])
        if (ci > length(f)) {
            stop(sprintf("row '%s' in section '%s' has %d cell(s); column '%s' is #%d",
                         row, section, length(f), col, ci))
        }
        raw <- f[ci]
        if (as_string) return(raw)
        v <- suppressWarnings(as.numeric(raw))
        if (is.na(v)) {
            stop(sprintf("cell [%s, %s] in '%s' is '%s', not numeric — use as_string",
                         row, col, section, raw))
        }
        return(v)
    }
    stop(sprintf("row '%s' not found in section '%s' of %s", row, section, cap$name))
}


# printed_eq — for the Stats Wizard's report format, which is not the
# column format the rest of the plugin uses. The wizard writes
#
#     SPL_soft mean = 72.4646
#     F(2, 38) = 583.1232, p = 0.00000000000000000000000000003
#     SPL_soft vs SPL_medium: p(raw) = 0.000002, p(adj) = 0.000006
#
# so a value is whatever follows an "=" rather than whatever sits in the
# next whitespace-delimited column. @printed cannot read these and correctly
# refuses to; this reads them.
#
#   key         text identifying the line, matched literally
#   which       which "= value" on that line (1 = the first)
#   occurrence  which matching line, when the key repeats — the post-hoc
#               pair labels appear once under RM-ANOVA and again under
#               Friedman in the same capture
# printed_eq_str — the same read as printed_eq, but returning the LITERAL
# text rather than the parsed number.
#
# Added 6 Aug 2026 for V6. A tolerance can only be principled if it is derived
# from how many decimals were actually printed, and that information is
# destroyed by as.numeric(). This is the one place that needs the string, so
# it shares printed_eq's locating logic and stops short of the conversion.
printed_eq_str <- function(cap, key, which = 1L, occurrence = 1L) {
    stopifnot(inherits(cap, "eml_capture"))
    hits <- grep(key, cap$lines, fixed = TRUE)
    if (!length(hits)) {
        stop(sprintf("key '%s' not found in capture %s", key, cap$name))
    }
    if (occurrence > length(hits)) {
        stop(sprintf("key '%s' occurs %d time(s) in %s; occurrence %d requested",
                     key, length(hits), cap$name, occurrence))
    }
    ln <- cap$lines[hits[occurrence]]
    m  <- regmatches(ln, gregexpr("=\\s*(-?[0-9]+\\.?[0-9]*(e[-+]?[0-9]+)?)",
                                  ln, perl = TRUE))[[1]]
    if (!length(m)) {
        stop(sprintf("no '= value' found on the line for key '%s' in %s:\n  %s",
                     key, cap$name, trimws(ln)))
    }
    if (which > length(m)) {
        stop(sprintf("line for key '%s' in %s has %d '= value' pair(s); %d requested",
                     key, cap$name, length(m), which))
    }
    sub("^=\\s*", "", m[which])
}

printed_eq <- function(cap, key, which = 1L, occurrence = 1L) {
    stopifnot(inherits(cap, "eml_capture"))
    hits <- grep(key, cap$lines, fixed = TRUE)
    if (!length(hits)) {
        stop(sprintf("key '%s' not found in capture %s", key, cap$name))
    }
    if (occurrence > length(hits)) {
        stop(sprintf("key '%s' occurs %d time(s) in %s; occurrence %d requested",
                     key, length(hits), cap$name, occurrence))
    }
    ln <- cap$lines[hits[occurrence]]
    m  <- regmatches(ln, gregexpr("=\\s*(-?[0-9]+\\.?[0-9]*(e[-+]?[0-9]+)?)",
                                  ln, perl = TRUE))[[1]]
    if (!length(m)) {
        stop(sprintf("no '= value' found on the line for key '%s' in %s:\n  %s",
                     key, cap$name, trimws(ln)))
    }
    if (which > length(m)) {
        stop(sprintf("line for key '%s' in %s has %d '= value' pair(s); %d requested",
                     key, cap$name, length(m), which))
    }
    v <- suppressWarnings(as.numeric(sub("^=\\s*", "", m[which])))
    if (is.na(v)) {
        stop(sprintf("value '%s' for key '%s' in %s is not numeric",
                     m[which], key, cap$name))
    }
    v
}

# ---------------------------------------------------------------------------
# eml_setup_commands — THE MENU, READ FROM THE FILE PRAAT READS
#
# setup.praat is what Praat itself reads to build the menus, so it is the only
# honest answer to "which commands does this plugin have". A hand-kept list
# beside it is a second copy that can disagree, and the disagreement is silent:
# a command added tomorrow is simply absent from every check that reads the
# copy, and every one of them stays green.
#
# THIS LIVES HERE BECAUSE TWO VALIDATORS NEED THE SAME UNIVERSE. v107 asks, of
# every registered command, whether it records; v111 asks, of every registered
# command, whether anything has ever opened it from an empty Objects window.
# Two questions, one population — and if each file derived the population for
# itself, the two could drift apart while both passed. The canon is stated
# once, here, and both read it. (CLAUDE.md: state the canon once in a
# procedure; a copy that can disagree is the defect.)
#
# A registration line ends with the script it runs, in quotes. Lines whose
# script is "" are STRUCTURE — the cascade itself, and the "-- eml describe --"
# separators — and are not commands a user can invoke, so they are dropped.
# The same script may be registered against several object types (the table
# editor's two doors, Describe on Table / TableOfReal / Matrix); the caller
# almost always wants the FILES, so duplicates are collapsed and the raw
# registration count is kept as an attribute for the callers that report it.
#
#   setup_path   path to setup.praat
#   ->           data.frame(label, script), one row per distinct script,
#                in registration order, with attr "registrations" = the number
#                of runnable registration lines before de-duplication.
# ---------------------------------------------------------------------------
eml_setup_commands <- function(setup_path) {
    if (!file.exists(setup_path)) stop("setup.praat not found: ", setup_path)
    sl <- readLines(setup_path, warn = FALSE)
    reg <- grep('^Add (menu|action) command', sl, value = TRUE)

    quoted <- function(s) regmatches(s, gregexpr('"[^"]*"', s))[[1]]
    lastq <- function(s) {
        txt <- quoted(s)
        if (!length(txt)) return("")
        gsub('"', "", txt[length(txt)])
    }
    # The third quoted field is the label the user sees. Fewer than three and
    # the line is not a command registration in the shape this reads.
    label_of <- function(s) {
        txt <- quoted(s)
        if (length(txt) >= 3) gsub('"', "", txt[3]) else ""
    }

    scripts <- vapply(reg, lastq, "")
    labels  <- vapply(reg, label_of, "")
    runnable <- nzchar(scripts)

    cmd <- data.frame(label = labels[runnable], script = scripts[runnable],
                      stringsAsFactors = FALSE)
    rownames(cmd) <- NULL
    cmd <- cmd[!duplicated(cmd$script), , drop = FALSE]
    rownames(cmd) <- NULL
    attr(cmd, "registrations") <- sum(runnable)
    cmd
}
