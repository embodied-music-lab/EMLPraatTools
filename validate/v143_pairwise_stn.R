# ============================================================================
# v143 — @emlRunPairwiseAnalysis's .stN is assigned, and it is the total
# complete-case N the analysis consumed
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. docs/WORK_ORDER_INTERVALS_2026-08-26.md pins .stN in
# @emlRunPairwiseAnalysis (plugin/stats/eml-analysis.praat) as "the total
# complete-case N the analysis consumed: the per-pair sum of the two group
# n's where the arm is per-pair, and the Scheffe arm's existing .totalN
# where it is design-wide." Before this commit .stN is initialised to
# undefined at entry and never assigned in any of the four arms -- welch,
# student, wilcoxon, scheffe -- so the published emlStoreN prints
# "--undefined--" for every pairwise run. THE CURRENT UNDEFINED IS THE
# STANDING RED DEMONSTRATION; nothing here needs to be seeded.
#
# THE ORACLE. R's own reading of "the total complete-case N" for this family
# (walkthrough/kit/run_analyses.R's process_pairwise) is length(x) after
# dropping rows with a blank group cell or a non-numeric value cell -- i.e.
# the SUM, across every group the analysis used, of that group's own
# complete-case count. This file recomputes that sum by hand from the same
# fixture and settles emlStoreN against it -- "the kit's 400 rows against
# length() sums", at kit-discipline scale: two canary fixtures, not the kit.
#
# THE DRIVE. A standalone Praat probe (written to a temp file, not checked
# in) includes the shipped stats tree, builds two small tables by hand, runs
# @emlRunPairwiseAnalysis once per arm x table, and prints emlStoreN. No
# report text, no matrix cell, is read here -- only the one store field the
# work order pins.
#
# Base R only. No packages. Requires a Praat at or above the plugin's floor;
# skips (not fails) below it, the same convention v108 uses.
#
# Registered in validate/run_all.R.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v143"

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

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

if (!canDrive) {
    cat(paste0("      SKIP: v143 needs Praat >= 6.6.30 to drive the orchestrator;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v143")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    # -------------------------------------------------------------------
    # Two fixtures, built here and echoed into the Praat probe as literal
    # `Append row` / `Set ... value` calls so R and Praat read the exact
    # same numbers.
    #
    #   "clean"    -- 3 groups of 4, no missing cells. total N = 12.
    #   "gappy"    -- same shape, but one Mid cell is blank (missing group)
    #                 and one Alpha cell is non-numeric text (missing
    #                 value) -- the two ways a row fails complete-case.
    #                 total N = 10, which is what tells apart "assigned
    #                 the group count" from "assigned the complete-case
    #                 count".
    # -------------------------------------------------------------------
    clean <- data.frame(
        value = c(10.1, 10.4, 10.9, 11.2,  7.1, 7.6, 8.0, 8.4,  4.2, 4.8, 5.1, 5.6),
        group = c(rep("Zebra", 4), rep("Mid", 4), rep("Alpha", 4)),
        stringsAsFactors = FALSE)

    gappy <- data.frame(
        value = c("10.1", "10.4", "10.9", "11.2",
                  "7.1", "7.6", "8.0", "8.4",
                  "4.2", "4.8", "5.1", "abc"),
        group = c("Zebra", "Zebra", "Zebra", "Zebra",
                  "Mid", "Mid", "", "Mid",
                  "Alpha", "Alpha", "Alpha", "Alpha"),
        stringsAsFactors = FALSE)

    # The oracle: the same complete-case rule run_analyses.R's
    # prepGroupedData applies -- drop a blank group cell, then drop a
    # non-numeric/missing value cell -- summed over every surviving row.
    oracle_n <- function(df) {
        v <- suppressWarnings(as.numeric(df$value))
        g <- df$group
        keep <- !is.na(g) & nzchar(g) & !is.na(v)
        sum(keep)
    }
    n_clean <- oracle_n(clean)   # 12
    n_gappy <- oracle_n(gappy)   # 10
    check(V, "oracle: clean fixture's complete-case N", n_clean, 12, tol = 0)
    check(V, "oracle: gappy fixture's complete-case N", n_gappy, 10, tol = 0)

    praat_rows <- function(df) {
        vapply(seq_len(nrow(df)), function(i) sprintf(
            '  Append row\n  .r = Get number of rows\n  Set string value: .r, "value", "%s"\n  Set string value: .r, "group", "%s"',
            df$value[i], df$group[i]), character(1))
    }

    prelude <- c(
        paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
        paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
        paste0("include ", file.path(plug, "stats", "eml-extract.praat")),
        paste0("include ", file.path(plug, "stats", "eml-output.praat")),
        paste0("include ", file.path(plug, "stats", "eml-inferential.praat")),
        paste0("include ", file.path(plug, "stats", "eml-result-writer.praat")),
        paste0("include ", file.path(plug, "graphs", "eml-graph-procedures.praat")),
        paste0("include ", file.path(plug, "graphs", "eml-annotation-procedures.praat")),
        paste0("include ", file.path(plug, "stats", "eml-analysis.praat")))

    build_table <- function(name, df) c(
        sprintf('procedure build%s', name),
        sprintf('  .id = Create Table with column names: "%s", 0, "value group"', name),
        praat_rows(df),
        sprintf('  %s_id = .id', name),
        "endproc")

    arms <- list(
        list(tag = "welch",   test = "welch",   adj = "holm"),
        list(tag = "student", test = "student", adj = "holm"),
        list(tag = "wilcox",  test = "wilcoxon", adj = "bh"),
        list(tag = "scheffe", test = "scheffe", adj = "holm"))

    fixtures <- list(list(tag = "clean", df = clean, n = n_clean),
                      list(tag = "gappy", df = gappy, n = n_gappy))

    probe_lines <- c(prelude, "",
                      build_table("clean", clean),
                      build_table("gappy", gappy),
                      "@buildclean", "@buildgappy", "")
    for (fx in fixtures) {
        for (a in arms) {
            probe_lines <- c(probe_lines, sprintf(
                '@emlRunPairwiseAnalysis: %s_id, "value", "group", "%s", "%s"',
                fx$tag, a$test, a$adj),
                sprintf('appendInfoLine: "STN ", "%s", " ", "%s", " ", string$ (emlStoreN)',
                        fx$tag, a$tag))
        }
    }
    probe_path <- file.path(work, "v143-probe.praat")
    writeLines(c('writeInfoLine: "v143"', probe_lines), probe_path)

    out <- suppressWarnings(system2("env",
        c("-u", "DISPLAY", shQuote(praat),
          shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
        stdout = TRUE, stderr = TRUE))

    ran <- !any(grepl("^Error", out))
    check_true(V, "the probe ran with no Praat error", ran)
    if (!ran) {
        cat("      v143 probe output:\n      ",
            paste(utils::tail(out, 25), collapse = "\n      "), "\n", sep = "")
    } else {
        got <- list()
        for (ln in grep("^STN ", out, value = TRUE)) {
            parts <- strsplit(ln, " ")[[1]]
            got[[paste(parts[2], parts[3])]] <- parts[4]
        }
        for (fx in fixtures) {
            for (a in arms) {
                key <- paste(fx$tag, a$tag)
                raw <- got[[key]]
                check_true(V, sprintf("[%s/%s] emlStoreN was printed at all", fx$tag, a$tag),
                           !is.null(raw))
                if (is.null(raw)) next
                is_num <- !identical(raw, "--undefined--") &&
                    !is.na(suppressWarnings(as.numeric(raw)))
                check_true(V, sprintf("[%s/%s] emlStoreN is a number, not undefined",
                                      fx$tag, a$tag), is_num)
                if (is_num) {
                    check(V, sprintf("[%s/%s] emlStoreN vs length()-sum oracle",
                                      fx$tag, a$tag),
                          as.numeric(raw), fx$n, tol = 0)
                }
            }
        }
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v143 pairwise .stN -- total complete-case N")
    eml_exit()
}
