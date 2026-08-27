# ============================================================================
# v147 — @emlSpearmanCorrelationDispatch: the AS 89 exact Spearman p, wired
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS SETTLES. docs/WORK_ORDER_SPEARMAN_EXACT_2026-08-27.md (item
# 3.10) wires @emlSpearmanExactP (the AS 89 port, already landed and
# oracled by the porting agent against R's own C_pRho across n = 2..2000)
# to every door that produces a Spearman p. The wiring is ONE new procedure,
# @emlSpearmanCorrelationDispatch (plugin/stats/eml-inferential.praat),
# which decides R's own branch law --
#     TIES <- (min(length(unique(x)), length(unique(y))) < n)
# -- ties present routes to the existing t-approximation, no ties routes to
# @emlSpearmanExactP -- and every live call site that used to call
# @emlSpearmanCorrelation directly now calls this dispatch instead. Neither
# @emlSpearmanCorrelation nor @emlSpearmanExactP is touched.
#
# THE SIX LIVE CALL SITES, all now wired (verified below by source, not by
# assumption): the correlation orchestrator (stats/eml-analysis.praat,
# @emlRunCorrelationAnalysis); the per-group correlation, in BOTH places it
# lives (scripts/eml-correlate.praat's dialog and scripts/eml-wizard.praat's
# own per-group loop); and the scatter's draw-time annotation, in all THREE
# places it computes a Spearman p (graphs/eml-draw-procedures.praat's
# ungrouped, per-group and overall/pooled blocks). @emlBridgeCorrelation
# (graphs/eml-annotation-procedures.praat) is UNUSED -- no caller, per this
# plugin's own header comment and dev/HISTORY_LEDGER.md -- so it is not a
# door and is left untouched, as is @emlSpearmanCorrelationAlt, which has no
# caller anywhere in the tree either (a scripting-only entry point, not a
# door a menu or the wizard reaches).
#
# THE ORACLE. R's cor.test(x, y, method = "spearman"), read directly --
# base R's own default dispatch (exact when there are no ties and n is
# small enough that this grid never leaves that regime; the normal
# approximation, with R's own warning, when ties are present). No package,
# no re-derivation: the plugin's kernel is a port of the same C routine
# cor.test itself calls.
#
# THE GRID, Fable's own words: "n from 5 to 50, rho spanning -1 to +1
# INCLUDING BOTH BOUNDARY CELLS (rho = +/-1), with and without ties,
# against cor.test." Every n from 5 to 50 (46 values) carries four cells:
# rho = +1 (identity permutation), rho = -1 (full reversal), a mid-range
# rho (a random permutation of 1..n, still tie-free by construction), and a
# ties-present case (one forced duplicate in x, y left a clean
# permutation) -- 184 cells, driven directly against
# @emlSpearmanCorrelationDispatch. Every cell asserts the p-value, the rho
# @emlSpearmanCorrelation itself computed (unchanged, sanity only), the
# .hasTies flag against R's own unique() count, and the .method$ branch tag
# against which method R actually took on that data.
#
# THE THREE RED DEMONSTRATIONS Fable's order names, built the way v144 and
# v145 are: the shipped source is copied to a scratch file, ONE line is
# mutated, and the mutant is driven exactly like the real thing. Per the
# standing rule (docs/WORK_ORDER_INTERVALS_2026-08-26.md's amendment,
# "assert identity with the specified wrong computation, NEVER a direction
# or a magnitude narrative"), each demonstration asserts the mutant's
# number DIFFERS from the correct oracle AND MATCHES, exactly, a NAMED
# wrong computation -- not "is off by some amount".
#
#   A. AN ASYMPTOTIC p PRINTED ON AN EXACT-ELIGIBLE CELL. One line,
#      ".p = emlSpearmanExactP.p", is replaced with ".p = .pAsymptotic" --
#      the branch still SAYS "exact" (the tag is untouched) but the number
#      it carries is the t-approximation. Driven on a no-ties n = 25
#      fixture built to land near rho = -0.9792 -- Fable's own named case,
#      where the order's memo states the asymptotic p (1.9e-17) and R's
#      default (6.3e-7) visibly disagree. The mutant's p differs from the
#      correct AS 89 oracle and is IDENTICAL to that same probe's own
#      .pAsymptotic field -- the specific wrong number this defect would
#      print, not a description of how wrong it is.
#
#   B. A TIES CASE THAT FAILS TO FALL BACK TO THE T-APPROXIMATION. One
#      line inside the SAME branch, "if .hasTies = 1", is changed to
#      "if .hasTies = 2" -- a condition that can never fire, so a
#      ties-present sample falls through to the exact branch regardless.
#      Driven on a ties-present fixture, the mutant's p differs from R's
#      correct (t-approximation) oracle and is IDENTICAL to
#      @emlSpearmanExactP applied directly to that same rho and n --
#      the AS 89 formula computed on data it was never meant to see,
#      named and reproduced rather than described.
#
#   C. THE rho = 1 BOUNDARY CELL COMPARED AGAINST THE WRONG METHOD. The
#      SAME mutant as A, driven instead on a rho = +1 fixture (identity
#      permutation, n = 8). @emlSpearmanCorrelation's own asymptotic
#      branch sets p = 0 EXACTLY at |rho| = 1 (t is infinite in the
#      limit) -- so the wrong computation at this boundary is not "some
#      other small number", it is the literal constant 0. The mutant's p
#      is asserted to equal 0 exactly (tol = 0) and to differ from the
#      correct AS 89 exact p at this cell, which the grid above already
#      shows is a specific small POSITIVE number, not zero.
#
# HOW THE STRINGS STAY DARK. Fable's order: "exact method (AS 89)" and "t
# approximation (ties present)" go to Ian's language batch, unapproved --
# "compute the values, expose them as outputs a check can read, print
# nothing," the same shape every interval item since item 2 has followed
# (v144, v145, v146). @emlSpearmanCorrelationDispatch's .method$ is
# therefore an INTERNAL two-word tag ("exact" / "t approximation"), the
# same shape @emlMannWhitneyU.method$ already carries, and not the drafted
# sentence -- no call site gained a print, and @emlReportCorrelationAnalysis
# (the shared reporter every door already runs through) was not touched at
# all. This file asserts both halves: the two drafted sentences appear
# NOWHERE in executable source (comments only, where this file's own
# header just used them), and NOWHERE in any driven Info-window text
# across the whole grid and all three red demonstrations.
#
# Base R only. Requires a Praat at or above the plugin's floor; skips (not
# fails) below it, the same convention v108/v143/v144/v145/v146 use.
#
# Registered in validate/run_all.R.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v147"

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
    cat(paste0("      SKIP: v147 needs Praat >= 6.6.30 to drive the procedure;\n",
               "            found ", if (is.na(pv)) "none" else pv, ".\n"))
    check_true(V,
               sprintf("a Praat at or above the plugin's floor is available (found %s)",
                       if (is.na(pv)) "none" else pv),
               FALSE)
} else {

    work <- file.path(tempdir(), "v147")
    unlink(work, recursive = TRUE)
    dir.create(work, showWarnings = FALSE, recursive = TRUE)
    prefs <- file.path(work, "prefs")
    dir.create(prefs, showWarnings = FALSE)

    INF <- file.path(plug, "stats", "eml-inferential.praat")

    prelude <- function(inferential_file) c(
        paste0("include ", file.path(plug, "stats", "eml-core-utilities.praat")),
        paste0("include ", file.path(plug, "stats", "eml-core-descriptive.praat")),
        paste0("include ", file.path(plug, "stats", "eml-extract.praat")),
        paste0("include ", file.path(plug, "stats", "eml-output.praat")),
        paste0("include ", inferential_file),
        paste0("include ", file.path(plug, "stats", "eml-result-writer.praat")),
        paste0("include ", file.path(plug, "graphs", "eml-graph-procedures.praat")),
        paste0("include ", file.path(plug, "graphs", "eml-annotation-procedures.praat")),
        paste0("include ", file.path(plug, "stats", "eml-analysis.praat")))

    drive <- function(probe_path, secs = "240") {
        suppressWarnings(system2("timeout",
            c(secs, "env", "-u", "DISPLAY", shQuote(praat),
              shQuote(paste0("--pref-dir=", prefs)), "--run", shQuote(probe_path)),
            stdout = TRUE, stderr = TRUE))
    }

    vec_lit <- function(v) paste0("{", paste(sprintf("%.0f", v), collapse = ", "), "}")
    num <- function(s) if (identical(s, "--undefined--")) NA_real_ else as.numeric(s)

    DARK_SENTENCES <- c("exact method (AS 89)", "t approximation (ties present)")

    # ---------------------------------------------------------------------
    # PART 0 -- STRUCTURAL: every door is wired, and nothing else changed.
    # ---------------------------------------------------------------------
    inf_src   <- readLines(INF, warn = FALSE)
    ana_src   <- readLines(file.path(plug, "stats", "eml-analysis.praat"), warn = FALSE)
    corr_src  <- readLines(file.path(plug, "scripts", "eml-correlate.praat"), warn = FALSE)
    wiz_src   <- readLines(file.path(plug, "scripts", "eml-wizard.praat"), warn = FALSE)
    draw_src  <- readLines(file.path(plug, "graphs", "eml-draw-procedures.praat"), warn = FALSE)
    bridge_src <- readLines(file.path(plug, "graphs", "eml-annotation-procedures.praat"), warn = FALSE)

    check_true(V, "@emlSpearmanCorrelationDispatch is defined exactly once",
               sum(grepl("^procedure emlSpearmanCorrelationDispatch:", inf_src)) == 1)

    n_dispatch_calls <- function(src) sum(grepl("@emlSpearmanCorrelationDispatch:", src, fixed = TRUE))
    check_true(V, "the correlation orchestrator (eml-analysis.praat, @emlRunCorrelationAnalysis) calls the dispatch",
               n_dispatch_calls(ana_src) == 1)
    check_true(V, "the per-group correlation door in scripts/eml-correlate.praat calls the dispatch",
               n_dispatch_calls(corr_src) == 1)
    check_true(V, "the per-group correlation door in scripts/eml-wizard.praat calls the dispatch",
               n_dispatch_calls(wiz_src) == 1)
    check_true(V, "all three scatter draw-time annotation call sites (ungrouped, per-group, overall/pooled) call the dispatch",
               n_dispatch_calls(draw_src) == 3)

    # And no live call site still reaches @emlSpearmanCorrelation directly.
    # Three raw occurrences are correct and named: the dispatch's OWN
    # internal call (inside its body in eml-inferential.praat), the
    # scripting-only @emlSpearmanCorrelationAlt (no caller anywhere in the
    # tree -- not a door), and @emlBridgeCorrelation (UNUSED, no caller,
    # per this file's own header comment).
    raw_inf   <- sum(grepl("^\\s*@emlSpearmanCorrelation:\\s", inf_src))
    raw_bridge <- sum(grepl("@emlSpearmanCorrelation:\\s", bridge_src, fixed = FALSE))
    check_true(V,
               sprintf("exactly one raw @emlSpearmanCorrelation call remains in eml-inferential.praat (the dispatch's own internal call; found %d)",
                       raw_inf),
               raw_inf == 1)
    check_true(V,
               sprintf("exactly one raw @emlSpearmanCorrelation call remains in eml-annotation-procedures.praat (the UNUSED @emlBridgeCorrelation; found %d)",
                       raw_bridge),
               raw_bridge == 1)
    check_true(V, "@emlBridgeCorrelation is confirmed unused (no caller anywhere in the tree)",
               sum(grepl("@emlBridgeCorrelation:", c(ana_src, corr_src, wiz_src, draw_src, bridge_src), fixed = TRUE)) == 0)
    check_true(V, "@emlSpearmanCorrelationAlt has no caller anywhere in the tree (not a door)",
               sum(grepl("@emlSpearmanCorrelationAlt:", c(ana_src, corr_src, wiz_src, draw_src, bridge_src, inf_src), fixed = TRUE)) == 0)

    # -- the strings stay dark: not in executable source anywhere --------
    all_src_lines <- c(inf_src, ana_src, corr_src, wiz_src, draw_src, bridge_src)
    is_comment <- grepl("^\\s*[#;]", all_src_lines)
    exec_lines <- all_src_lines[!is_comment]
    for (s in DARK_SENTENCES) {
        check_true(V, sprintf("the drafted sentence '%s' appears in no executable source line (comments only)", s),
                   !any(grepl(s, exec_lines, fixed = TRUE)))
    }
    # And @emlReportCorrelationAnalysis's Spearman block gained no new
    # "Method" print line -- the report layer itself was not touched.
    rep_start <- grep("^procedure emlReportCorrelationAnalysis:", bridge_src)
    rep_end <- rep_start[1] - 1 + which(bridge_src[rep_start[1]:length(bridge_src)] == "endproc")[1]
    rep_body <- bridge_src[rep_start[1]:rep_end]
    sp_if <- grep('if \\.testType\\$ = "spearman" or \\.testType\\$ = "both"', rep_body)
    check_true(V, "@emlReportCorrelationAnalysis's Spearman block prints no Method line (report layer untouched)",
               length(sp_if) >= 1 &&
               !any(grepl('emlReportLineString:\\s*"Method"', rep_body[sp_if[length(sp_if)]:length(rep_body)])))

    # ---------------------------------------------------------------------
    # PART 1 -- THE GRID: n = 5..50, rho +/-1 boundary + mid + ties, x4.
    # ---------------------------------------------------------------------
    set.seed(14700)
    grid <- list()
    glines <- c(prelude(INF), "",
        "procedure v147cell: .tag$, .a#, .b#",
        "    @emlSpearmanCorrelationDispatch: .a#, .b#, 2",
        "    .p$ = fixed$ (emlSpearmanCorrelationDispatch.p, 15)",
        "    .rho$ = fixed$ (emlSpearmanCorrelationDispatch.rho, 15)",
        "    .m$ = emlSpearmanCorrelationDispatch.method$",
        "    .ht = emlSpearmanCorrelationDispatch.hasTies",
        "    .err$ = emlSpearmanCorrelationDispatch.error$",
        "    appendInfoLine: \"CELL \", .tag$, \" \", .p$, \" \", .rho$, \" [\", .m$, \"] \", .ht, \" [\", .err$, \"]\"",
        "endproc", "")

    for (n in 5:50) {
        ident <- 1:n
        rev_ <- n:1
        mid <- sample(n)
        tiesx <- 1:n; tiesx[2] <- tiesx[1]
        tiesy <- sample(n)

        cells <- list(
            plus1  = list(x = ident, y = ident),
            minus1 = list(x = ident, y = rev_),
            mid    = list(x = ident, y = mid),
            ties   = list(x = tiesx, y = tiesy)
        )
        for (cTag in names(cells)) {
            key <- sprintf("n%02d_%s", n, cTag)
            grid[[key]] <- cells[[cTag]]
            glines <- c(glines,
                sprintf("x# = %s", vec_lit(cells[[cTag]]$x)),
                sprintf("y# = %s", vec_lit(cells[[cTag]]$y)),
                sprintf('@v147cell: "%s", x#, y#', key))
        }
    }
    grid_path <- file.path(work, "v147-grid.praat")
    writeLines(c('writeInfoLine: "v147 grid"', glines), grid_path)
    outG <- drive(grid_path)
    ranG <- !any(grepl("^Error", outG))
    check_true(V, "the main grid probe ran with no Praat error", ranG)

    if (!ranG) {
        cat("      v147 grid probe output:\n      ",
            paste(utils::tail(outG, 30), collapse = "\n      "), "\n", sep = "")
    } else {
        gotG <- list()
        for (ln in grep("^CELL ", outG, value = TRUE)) {
            m <- regmatches(ln, regexec(
                "^CELL (\\S+) (\\S+) (\\S+) \\[([^]]*)\\] (\\S+) \\[(.*)\\]$", ln))[[1]]
            if (length(m) == 7) {
                gotG[[m[2]]] <- list(p = num(m[3]), rho = num(m[4]), meth = m[5],
                                     ht = as.integer(m[6]), err = m[7])
            }
        }
        nChecked <- 0L
        nExactCells <- 0L; nTiesCells <- 0L
        for (key in names(grid)) {
            fx <- grid[[key]]
            cell <- gotG[[key]]
            check_true(V, sprintf("[%s] a cell was printed at all", key), !is.null(cell))
            if (is.null(cell)) next
            check_true(V, sprintf("[%s] .error$ is empty on a well-formed sample", key),
                       identical(cell$err, ""))

            ct <- suppressWarnings(cor.test(fx$x, fx$y, method = "spearman"))
            # cor.test(method = "spearman")'s own $method string is the same
            # literal text ("Spearman's rank correlation rho") on BOTH
            # branches -- unlike wilcox.test, it does not name its branch in
            # $method. The branch is instead cor.test.default's own TIES
            # test, copied verbatim in @emlSpearmanCorrelationDispatch's
            # header and reproduced here exactly the same way.
            nUniqX <- length(unique(fx$x)); nUniqY <- length(unique(fx$y))
            rTies <- as.integer(min(nUniqX, nUniqY) < length(fx$x))
            rBranch <- if (rTies == 1L) "t approximation" else "exact"

            tol_p <- max(1e-12, abs(ct$p.value) * 1e-8)
            check(V, sprintf("[%s] p vs cor.test(method=\"spearman\")", key),
                  cell$p, ct$p.value, tol = tol_p)
            check(V, sprintf("[%s] rho vs cor()", key),
                  cell$rho, unname(ct$estimate), tol = 1e-10)
            check_true(V, sprintf("[%s] .hasTies matches R's own unique() test", key),
                       identical(cell$ht, rTies))
            check_true(V, sprintf("[%s] .method$ is the branch R's cor.test took (%s)", key, rBranch),
                       identical(cell$meth, rBranch))

            if (identical(rBranch, "exact")) nExactCells <- nExactCells + 1L
            else nTiesCells <- nTiesCells + 1L
            nChecked <- nChecked + 1L
        }
        check(V, "grid cells checked (46 values of n x 4 cases)", nChecked, 184, tol = 0)
        check_true(V, sprintf("the grid actually exercises BOTH branches (%d exact, %d t-approximation cells)",
                              nExactCells, nTiesCells),
                   nExactCells > 0 && nTiesCells > 0)
        # The two named boundary cells, singled out as their own assertion
        # per Fable's own wording ("INCLUDING BOTH BOUNDARY CELLS").
        for (n in 5:50) {
            for (cTag in c("plus1", "minus1")) {
                key <- sprintf("n%02d_%s", n, cTag)
                cell <- gotG[[key]]
                if (!is.null(cell)) {
                    check(V, sprintf("[boundary %s] rho is exactly %s%d", key,
                                     if (cTag == "plus1") "+" else "-", 1),
                          cell$rho, if (cTag == "plus1") 1 else -1, tol = 1e-10)
                }
            }
        }

        # -- dark strings never printed across the whole grid drive ------
        for (s in DARK_SENTENCES) {
            check_true(V, sprintf("[grid] the drafted sentence '%s' never printed", s),
                       !any(grepl(s, outG, fixed = TRUE)))
        }
    }

    # ---------------------------------------------------------------------
    # PART 2 -- ONE DOOR DRIVEN END TO END, not just called directly.
    # ---------------------------------------------------------------------
    # The grid above calls @emlSpearmanCorrelationDispatch directly. This
    # part proves the WIRING itself: @emlRunCorrelationAnalysis (the
    # correlation orchestrator door) is driven on a Table exactly as the
    # menu runs it, and its own captured/restored .spearP is asserted to
    # equal the SAME value the direct dispatch call produces on identical
    # data -- both the no-ties (exact) and the ties (t-approximation) case.
    door_lines <- c(prelude(INF), "",
        'procedure v147table: .tag$, .a#, .b#',
        '    .id = Create Table with column names: "t147", 0, "x y"',
        '    .n = size (.a#)',
        '    for .i from 1 to .n',
        '        Append row',
        '        Set numeric value: .i, "x", .a#[.i]',
        '        Set numeric value: .i, "y", .b#[.i]',
        '    endfor',
        '    @emlRunCorrelationAnalysis: .id, "x", "y", "spearman"',
        '    .p$ = fixed$ (emlRunCorrelationAnalysis.spearP, 15)',
        '    @emlSpearmanCorrelationDispatch: .a#, .b#, 2',
        '    .direct$ = fixed$ (emlSpearmanCorrelationDispatch.p, 15)',
        '    appendInfoLine: "DOOR ", .tag$, " ", .p$, " ", .direct$',
        '    removeObject: .id',
        'endproc', "")
    door_fixtures <- list(
        no_ties = grid[["n25_minus1"]],
        ties    = grid[["n20_ties"]]
    )
    for (tag in names(door_fixtures)) {
        fx <- door_fixtures[[tag]]
        door_lines <- c(door_lines,
            sprintf("x# = %s", vec_lit(fx$x)),
            sprintf("y# = %s", vec_lit(fx$y)),
            sprintf('@v147table: "%s", x#, y#', tag))
    }
    door_path <- file.path(work, "v147-door.praat")
    writeLines(c('writeInfoLine: "v147 door"', door_lines), door_path)
    outD <- drive(door_path)
    ranD <- !any(grepl("^Error", outD))
    check_true(V, "the end-to-end orchestrator-door probe ran with no Praat error", ranD)
    if (!ranD) {
        cat("      v147 door probe output:\n      ",
            paste(utils::tail(outD, 30), collapse = "\n      "), "\n", sep = "")
    } else {
        gotD <- list()
        for (ln in grep("^DOOR ", outD, value = TRUE)) {
            m <- regmatches(ln, regexec("^DOOR (\\S+) (\\S+) (\\S+)$", ln))[[1]]
            if (length(m) == 4) gotD[[m[2]]] <- list(door = num(m[3]), direct = num(m[4]))
        }
        for (tag in names(door_fixtures)) {
            cell <- gotD[[tag]]
            check_true(V, sprintf("[door %s] a cell was printed", tag), !is.null(cell))
            if (is.null(cell)) next
            check(V, sprintf("[door %s] @emlRunCorrelationAnalysis's own .spearP equals the direct dispatch call, bit for bit -- ONE computation site, driven two ways", tag),
                  cell$door, cell$direct, tol = 1e-12)
        }
        for (s in DARK_SENTENCES) {
            check_true(V, sprintf("[door] the drafted sentence '%s' never printed", s),
                       !any(grepl(s, outD, fixed = TRUE)))
        }
    }

    # ---------------------------------------------------------------------
    # RED DEMO A and RED DEMO C share one mutant: the exact branch's p is
    # overwritten with the asymptotic one, while .method$ still says
    # "exact" -- the defect that looks right.
    # ---------------------------------------------------------------------
    needleA <- "            .p = emlSpearmanExactP.p"
    hitA <- which(inf_src == needleA)
    check_true(V, "red demos A/C's seed line exists in source, exactly once", length(hitA) == 1)

    asym_red <- nzchar(Sys.getenv("EML_ASYMPTOTIC_RED", unset = ""))
    ties_red <- nzchar(Sys.getenv("EML_TIES_RED", unset = ""))
    boundary_red <- nzchar(Sys.getenv("EML_BOUNDARY_RED", unset = ""))

    if (length(hitA) == 1) {
        mutA_lines <- inf_src
        mutA_lines[hitA] <- "            .p = .pAsymptotic"
        mutA_dir <- file.path(work, "mutantA"); dir.create(mutA_dir, showWarnings = FALSE)
        mutA <- file.path(mutA_dir, "eml-inferential.praat")
        writeLines(mutA_lines, mutA)

        acLines <- c(prelude(mutA), "",
            "procedure v147ac: .tag$, .a#, .b#",
            "    @emlSpearmanCorrelationDispatch: .a#, .b#, 2",
            "    .p$ = fixed$ (emlSpearmanCorrelationDispatch.p, 15)",
            "    .pa$ = fixed$ (emlSpearmanCorrelationDispatch.pAsymptotic, 15)",
            "    .m$ = emlSpearmanCorrelationDispatch.method$",
            "    appendInfoLine: \"REDAC \", .tag$, \" \", .p$, \" \", .pa$, \" [\", .m$, \"]\"",
            "endproc", "")
        # A: Fable's own named no-ties case, n = 25, rho ~= -0.9792.
        fxA <- list(x = 1:25,
                    y = c(25,23,22,21,24,18,20,17,19,15,16,13,14,12,10,9,11,6,8,5,3,7,4,1,2))
        # C: the rho = +1 boundary, n = 8, small enough that the exact permutation p at this boundary is a nonzero double rather than an underflow to 0 -- verified at n = 10 to underflow, which would make this demonstration vacuous there.
        fxC <- list(x = 1:8, y = 1:8)
        acLines <- c(acLines,
            sprintf("x# = %s", vec_lit(fxA$x)), sprintf("y# = %s", vec_lit(fxA$y)),
            '@v147ac: "A", x#, y#',
            sprintf("x# = %s", vec_lit(fxC$x)), sprintf("y# = %s", vec_lit(fxC$y)),
            '@v147ac: "C", x#, y#')
        ac_path <- file.path(work, "v147-ac.praat")
        writeLines(c('writeInfoLine: "v147 red A/C"', acLines), ac_path)
        outAC <- drive(ac_path)
        ranAC <- !any(grepl("^Error", outAC))
        check_true(V, "[red A/C] the mutant probe ran", ranAC)
        if (!ranAC) {
            cat("      v147 red-A/C probe output:\n      ",
                paste(utils::tail(outAC, 30), collapse = "\n      "), "\n", sep = "")
        } else {
            gotAC <- list()
            for (ln in grep("^REDAC ", outAC, value = TRUE)) {
                m <- regmatches(ln, regexec("^REDAC (\\S+) (\\S+) (\\S+) \\[([^]]*)\\]$", ln))[[1]]
                if (length(m) == 5) gotAC[[m[2]]] <- list(p = num(m[3]), pa = num(m[4]), meth = m[5])
            }

            # -- RED DEMO A --------------------------------------------------
            cellA <- gotAC[["A"]]
            check_true(V, "[red A] the mutant printed a cell", !is.null(cellA))
            if (!is.null(cellA)) {
                ctA <- suppressWarnings(cor.test(fxA$x, fxA$y, method = "spearman"))
                check_true(V, "[red A] .method$ still says \"exact\" -- the defect that looks right",
                           identical(cellA$meth, "exact"))
                if (asym_red) {
                    cat("      EML_ASYMPTOTIC_RED: asserting the mutant's p equals the\n")
                    cat("      correct AS 89 oracle -- EXPECTED to FAIL.\n")
                    check(V, "[RED A] mutant p vs correct AS 89 oracle (must go red)",
                          cellA$p, ctA$p.value, tol = 1e-8)
                } else {
                    check(V, "[red A] mutant p DIFFERS from the correct AS 89 oracle",
                          cellA$p, ctA$p.value, tol = 1e-8, expect = "differ")
                    check(V, "[red A] mutant p is IDENTICAL to the specified wrong computation -- this same probe's own .pAsymptotic",
                          cellA$p, cellA$pa, tol = 1e-10)
                }
            }

            # -- RED DEMO C --------------------------------------------------
            cellC <- gotAC[["C"]]
            check_true(V, "[red C] the mutant printed a cell", !is.null(cellC))
            if (!is.null(cellC)) {
                ctC <- suppressWarnings(cor.test(1:8, 1:8, method = "spearman"))
                if (boundary_red) {
                    cat("      EML_BOUNDARY_RED: asserting the mutant's p at rho = 1 equals\n")
                    cat("      the correct AS 89 oracle -- EXPECTED to FAIL.\n")
                    check(V, "[RED C] mutant p at rho=1 vs correct AS 89 oracle (must go red)",
                          cellC$p, ctC$p.value, tol = 1e-8)
                } else {
                    check(V, "[red C] mutant p at the rho = 1 boundary DIFFERS from the correct AS 89 exact oracle",
                          cellC$p, ctC$p.value, tol = 1e-8, expect = "differ")
                    check(V, "[red C] mutant p at the rho = 1 boundary is IDENTICAL to the specified wrong computation -- the literal constant 0",
                          cellC$p, 0, tol = 0)
                    check_true(V, "[red C] the CORRECT oracle at this same boundary cell is NOT zero -- a specific small positive number",
                               is.finite(ctC$p.value) && ctC$p.value > 0)
                }
            }
            for (s in DARK_SENTENCES) {
                check_true(V, sprintf("[red A/C] the drafted sentence '%s' never printed", s),
                           !any(grepl(s, outAC, fixed = TRUE)))
            }
        }
    }

    # ---------------------------------------------------------------------
    # RED DEMO B -- a ties case that fails to fall back to the
    # t-approximation: "if .hasTies = 1" -> "if .hasTies = 2", inside the
    # SAME procedure, located relative to demo A/C's anchor line rather
    # than by a non-unique fixed string.
    # ---------------------------------------------------------------------
    needleB <- "        if .hasTies = 1"
    # The nearest occurrence of the (non-unique) guard line BEFORE demo
    # A/C's unique anchor -- @emlSpearmanCorrelationDispatch's own copy.
    hitB <- if (length(hitA) == 1) max(which(inf_src[seq_len(hitA - 1)] == needleB)) else NA_integer_
    check_true(V, "red demo B's seed site (.hasTies guard, this procedure's own copy) located",
               length(hitB) == 1 && is.finite(hitB) &&
               identical(inf_src[hitB + 1], '            .method$ = "t approximation"'))
    if (length(hitB) == 1 && is.finite(hitB)) {
        mutB_lines <- inf_src
        mutB_lines[hitB] <- "        if .hasTies = 2"
        mutB_dir <- file.path(work, "mutantB"); dir.create(mutB_dir, showWarnings = FALSE)
        mutB <- file.path(mutB_dir, "eml-inferential.praat")
        writeLines(mutB_lines, mutB)

        bLines <- c(prelude(mutB), "",
            "procedure v147b: .a#, .b#",
            "    @emlSpearmanCorrelationDispatch: .a#, .b#, 2",
            "    .p$ = fixed$ (emlSpearmanCorrelationDispatch.p, 15)",
            "    .m$ = emlSpearmanCorrelationDispatch.method$",
            "    .rho = emlSpearmanCorrelationDispatch.rho",
            "    .n = emlSpearmanCorrelationDispatch.n",
            "    @emlSpearmanExactP: .rho, .n, 2",
            "    .named$ = fixed$ (emlSpearmanExactP.p, 15)",
            "    appendInfoLine: \"REDB \", .p$, \" \", .named$, \" [\", .m$, \"]\"",
            "endproc", "")
        fxB <- grid[["n20_ties"]]
        bLines <- c(bLines,
            sprintf("x# = %s", vec_lit(fxB$x)), sprintf("y# = %s", vec_lit(fxB$y)),
            "@v147b: x#, y#")
        b_path <- file.path(work, "v147-b.praat")
        writeLines(c('writeInfoLine: "v147 red B"', bLines), b_path)
        outB <- drive(b_path)
        ranB <- !any(grepl("^Error", outB))
        check_true(V, "[red B] the mutant probe ran", ranB)
        if (!ranB) {
            cat("      v147 red-B probe output:\n      ",
                paste(utils::tail(outB, 30), collapse = "\n      "), "\n", sep = "")
        } else {
            ln <- grep("^REDB ", outB, value = TRUE)
            check_true(V, "[red B] the mutant printed a cell", length(ln) == 1)
            if (length(ln) == 1) {
                m <- regmatches(ln, regexec("^REDB (\\S+) (\\S+) \\[([^]]*)\\]$", ln))[[1]]
                pB <- num(m[2]); namedWrong <- num(m[3]); methB <- m[4]
                ctB <- suppressWarnings(cor.test(fxB$x, fxB$y, method = "spearman"))
                check_true(V, "[red B] .method$ still says \"exact\" on ties-present data -- the fallback that failed to fire",
                           identical(methB, "exact"))
                if (ties_red) {
                    cat("      EML_TIES_RED: asserting the mutant's p equals the correct\n")
                    cat("      t-approximation oracle -- EXPECTED to FAIL.\n")
                    check(V, "[RED B] mutant p vs correct t-approximation oracle (must go red)",
                          pB, ctB$p.value, tol = 1e-8)
                } else {
                    check(V, "[red B] mutant p DIFFERS from R's correct t-approximation oracle",
                          pB, ctB$p.value, tol = 1e-8, expect = "differ")
                    check(V, "[red B] mutant p is IDENTICAL to the specified wrong computation -- AS 89 applied directly to this ties-present rho and n",
                          pB, namedWrong, tol = 1e-10)
                }
            }
            for (s in DARK_SENTENCES) {
                check_true(V, sprintf("[red B] the drafted sentence '%s' never printed", s),
                           !any(grepl(s, outB, fixed = TRUE)))
            }
        }
    }

    # ---------------------------------------------------------------------
    # BOUNDARY TASK, report only: confirm the plugin offers no Kendall
    # correlation. Grepped once, here, so the fact is attested in the same
    # file that carries the rest of this item's evidence.
    # ---------------------------------------------------------------------
    kendall_hits <- character(0)
    for (f in list.files(plug, pattern = "\\.praat$", recursive = TRUE, full.names = TRUE)) {
        if (grepl("[/\\\\]dev[/\\\\]tests[/\\\\]", f)) next
        ls <- readLines(f, warn = FALSE)
        hit <- grep("kendall", ls, ignore.case = TRUE)
        if (length(hit)) kendall_hits <- c(kendall_hits,
            sprintf("%s:%d: %s", f, hit, trimws(ls[hit])))
    }
    only_w <- length(kendall_hits) == 0 ||
        all(grepl("Kendall.s W|kendalls\\.w", kendall_hits, ignore.case = TRUE))
    check_true(V,
               sprintf("the plugin offers no Kendall rank correlation between two variables (%d Kendall hit(s), %s)",
                       length(kendall_hits),
                       if (length(kendall_hits) == 0) "none at all"
                       else if (only_w) "all of them Kendall's W, the Friedman concordance effect size -- an unrelated statistic"
                       else "SOME HITS ARE NOT KENDALL'S W -- RE-CHECK, this may need its own item"),
               only_w)
}

if (!exists("EML_SUITE")) {
    eml_report("v147 -- the AS 89 exact Spearman p, wired to every door")
    eml_exit()
}
