# ============================================================================
# v81_recipes.R -- the recipes page is code, and this is the code review
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS FILE IS FOR. plugin/docs/RECIPES.md documents the direct-kernel
# API: a Table becomes two vectors, the vectors go into @emlTTest and its
# relatives, and numbers come back in variables. That is the surface a voice
# researcher writing their own script uses, and it is the surface with the
# least protection, because nothing in the plugin calls it -- the menus go
# through the orchestrators. Prose about an API nobody runs is a guess about
# an API. The house rule from v50 is the design brief: a documented example
# is a tested example.
#
# THE THREE ANCHORS, and the reason there are three.
#
# A capture cannot pin itself. If the only comparison were "does
# harness/recipes/out/R1.out agree with harness/recipes/out/R1.out", then a
# change to the plugin that moved a number would move the capture too and the
# check would follow it down. So every printed number is held against
# something OUTSIDE the capture:
#
#   1. THE PAGE. Each recipe's "What it printed" block must appear, line for
#      line and in order, inside that recipe's capture. Move a number and the
#      page is wrong; this file says which recipe and which line. That is the
#      pin in the plainest sense -- the documentation is the expected value.
#
#   2. BASE R. t, df, p, Cohen's d, Hedges' g, the paired t, Pearson r, and
#      the one-way ANOVA's SS / F / eta-squared are recomputed here from the
#      committed fixtures and compared with the numbers PARSED OUT of the
#      capture. The page and the plugin agreeing with each other is not the
#      same as either being right.
#
#   3. THE PROCEDURE HEADERS. Every `@call` the page makes must be a
#      procedure that exists, every `procedure.field` the recipes READ must be
#      a field that procedure actually assigns, and every argument list the
#      page's annotation blocks print must match the real signature. This is
#      the class of error the page is most exposed to and the hardest to see
#      by reading: the extractors return `.group1#` and `.data1#`, not the
#      names anyone would guess, and a plausible wrong name reads as correct
#      prose and returns zero in a script.
#
# AND ONE MORE, WHICH IS NOT A NUMBER. The harness runs the bytes that ship:
# extract.py lifts each script out of the .md and Praat runs that file. This
# file checks that claim from the other side, in R, without importing the
# extractor -- out/scripts/R<n>.praat is compared byte for byte with the
# fenced block in the page. A harness that quietly ran its own copy would
# fail here, which is the only thing that makes "verbatim" mean anything.
#
#     bash harness/recipes/run.sh
#     Rscript validate/v81_recipes.R
#
# Input: harness/recipes/out/ -- scripts/, EXTRACT.tsv, RESULTS.tsv,
#        FILES.tsv, one <recipe>.out per recipe -- plus plugin/docs/RECIPES.md,
#        the plugin source, and harness/recipes/fixtures/.
#        $EML_RECIPES_DIR, $EML_RECIPES_DOC and $EML_PLUGIN_DIR override, for
#        break tests.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

ID  <- "v81"
OUT <- Sys.getenv("EML_RECIPES_DIR",
                  unset = repo_path("harness", "recipes", "out"))
DOC <- Sys.getenv("EML_RECIPES_DOC",
                  unset = repo_path("plugin", "docs", "RECIPES.md"))
PLUGIN <- Sys.getenv("EML_PLUGIN_DIR", unset = repo_path("plugin"))
FIX <- repo_path("harness", "recipes", "fixtures")

rd <- function(p) if (file.exists(p)) readLines(p, warn = FALSE) else character(0)

# ---------------------------------------------------------------------------
# THE PAGE, PARSED. One pass, three products, from one fence grammar, so the
# script blocks and the output blocks cannot be identified by two rules that
# disagree:
#
#   ```praat  opening a block whose first non-blank line is `include `
#             -> that recipe's SCRIPT
#   ```praat  otherwise                     -> an ANNOTATION block (comments)
#   ```       with no language              -> a PINNED OUTPUT excerpt
#
# The same grammar harness/recipes/extract.py uses, written again here rather
# than imported: this file's job is to disagree with the harness if the
# harness ever stops running what the page prints.
# ---------------------------------------------------------------------------
parse_page <- function(path) {
    lines <- rd(path)
    recipe <- NA_character_
    scripts <- list(); annots <- list(); outs <- list()
    in_fence <- FALSE; lang <- ""; buf <- character(0)
    for (ln in lines) {
        if (in_fence) {
            if (grepl("^```", ln)) {
                in_fence <- FALSE
                body <- buf[nzchar(trimws(buf))]
                if (identical(lang, "praat")) {
                    if (length(body) && grepl("^include ", body[1])) {
                        if (!is.na(recipe)) scripts[[recipe]] <- buf
                    } else if (!is.na(recipe)) {
                        annots[[length(annots) + 1L]] <-
                            list(recipe = recipe, lines = buf)
                    }
                } else if (identical(lang, "") && !is.na(recipe)) {
                    outs[[length(outs) + 1L]] <-
                        list(recipe = recipe, lines = buf)
                }
                buf <- character(0)
                next
            }
            buf <- c(buf, ln)
            next
        }
        if (grepl("^```", ln)) {
            in_fence <- TRUE
            lang <- sub("^```", "", ln)
            lang <- trimws(lang)
            buf <- character(0)
            next
        }
        m <- regmatches(ln, regexec("^## +(R[0-9]+)\\b", ln))[[1]]
        if (length(m) == 2) recipe <- m[2]
    }
    list(scripts = scripts, annots = annots, outs = outs,
         headings = unique(unlist(regmatches(
             lines, regexec("^## +(R[0-9]+)\\b", lines)))[c(FALSE, TRUE)]))
}

page <- parse_page(DOC)
recipes <- names(page$scripts)

# ---------------------------------------------------------------------------
# THE PLUGIN'S PROCEDURES, PARSED. name -> the set of output fields the body
# assigns. An assignment is what makes a field readable by a caller; a field
# only ever mentioned in a comment is not one, which is exactly the confusion
# this map exists to settle.
#
# `.data#[.idx] = .val` counts as an assignment to `.data#`: a vector filled
# element by element is still a vector the caller reads.
# ---------------------------------------------------------------------------
proc_fields <- local({
    srcs <- c(list.files(file.path(PLUGIN, "stats"), "\\.praat$", full.names = TRUE),
              list.files(file.path(PLUGIN, "graphs"), "\\.praat$", full.names = TRUE))
    map <- list(); args <- list()
    for (s in srcs) {
        cur <- NA_character_
        for (ln in rd(s)) {
            h <- regmatches(ln, regexec(
                "^procedure +([A-Za-z][A-Za-z0-9_]*)[ ]*:?[ ]*(.*)$", ln))[[1]]
            if (length(h) == 3) {
                cur <- h[2]
                if (is.null(map[[cur]])) map[[cur]] <- character(0)
                a <- trimws(strsplit(h[3], ",")[[1]])
                args[[cur]] <- a[nzchar(a)]
                next
            }
            if (grepl("^endproc", ln)) { cur <- NA_character_; next }
            if (is.na(cur)) next
            f <- regmatches(ln, regexec(
                "^[ \t]*\\.([A-Za-z][A-Za-z0-9_]*)(##|#|\\$)?(\\[[^]]*\\])?[ ]*=[^=]",
                ln))[[1]]
            if (length(f) >= 3) {
                map[[cur]] <- unique(c(map[[cur]], paste0(".", f[2], f[3])))
            }
        }
    }
    list(fields = map, args = args)
})

n_procs <- length(proc_fields$fields)
n_fields <- sum(vapply(proc_fields$fields, length, integer(1)))

# ---------------------------------------------------------------------------
# 1. THE HARNESS RUNS THE BYTES THAT SHIP
# ---------------------------------------------------------------------------
cat("\n-- 1. verbatim: the file Praat ran is the file the page prints --\n")
for (r in recipes) {
    ran <- rd(file.path(OUT, "scripts", paste0(r, ".praat")))
    shipped <- page$scripts[[r]]
    check_true(ID, sprintf("%s: the script Praat ran is the page's, byte for byte", r),
               length(ran) > 0 && identical(ran, shipped))
    if (length(ran) > 0 && !identical(ran, shipped)) {
        n <- max(length(ran), length(shipped))
        a <- c(ran, rep(NA, n - length(ran)))
        b <- c(shipped, rep(NA, n - length(shipped)))
        d <- which(is.na(a) != is.na(b) | (!is.na(a) & !is.na(b) & a != b))[1]
        check_true(ID, sprintf("  %s: first divergence at line %d: page has %s",
                               r, d, substr(if (is.na(b[d])) "<nothing>" else b[d], 1, 40)),
                   FALSE)
    }
}

# ---------------------------------------------------------------------------
# 2. EVERY RECIPE RAN, AND PRINTED SOMETHING
# ---------------------------------------------------------------------------
cat("\n-- 2. every recipe ran --\n")
res <- if (file.exists(file.path(OUT, "RESULTS.tsv")))
    read.delim(file.path(OUT, "RESULTS.tsv"), stringsAsFactors = FALSE) else
    data.frame(recipe = character(0), exit = integer(0), lines = integer(0))

captures <- list()
for (r in recipes) {
    row <- res[res$recipe == r, , drop = FALSE]
    check_true(ID, sprintf("%s: Praat exited 0", r),
               nrow(row) == 1 && row$exit[1] == 0)
    cap <- rd(file.path(OUT, paste0(r, ".out")))
    captures[[r]] <- sub("[ \t]+$", "", cap)
    check_true(ID, sprintf("%s: the capture is not empty (%d line(s))", r, length(cap)),
               length(cap) > 0)
}

# ---------------------------------------------------------------------------
# 3. THE PAGE IS THE EXPECTED VALUE
#
# Each "What it printed" block must be a CONTIGUOUS run of lines inside that
# recipe's capture. Contiguous and in order, not a set of lines that happen to
# be present somewhere: a report that printed the right numbers in the wrong
# places would not be the report the page shows.
#
# Trailing whitespace is stripped from both sides before comparing. The
# plugin's tables pad their last column, and an editor that trims the page on
# save would otherwise turn this red for a change nobody made to a number.
# ---------------------------------------------------------------------------
cat("\n-- 3. each printed block appears in its recipe's capture --\n")
contiguous_at <- function(hay, needle) {
    if (!length(needle) || length(needle) > length(hay)) return(0L)
    for (i in seq_len(length(hay) - length(needle) + 1L)) {
        if (identical(hay[i:(i + length(needle) - 1L)], needle)) return(i)
    }
    0L
}
n_out_blocks <- 0L
out_by_recipe <- list()
for (b in page$outs) {
    r <- b$recipe
    n_out_blocks <- n_out_blocks + 1L
    want <- sub("[ \t]+$", "", b$lines)
    at <- contiguous_at(captures[[r]], want)
    out_by_recipe[[r]] <- c(out_by_recipe[[r]], at)
    check_true(ID, sprintf("%s: the page's %d printed line(s) are in the capture",
                           r, length(want)),
               at > 0)
    if (at == 0) {
        hit <- which(vapply(want, function(w) !(w %in% captures[[r]]), logical(1)))
        first <- if (length(hit)) want[hit[1]] else want[1]
        check_true(ID, sprintf("  %s: the capture does not print: %s",
                               r, substr(first, 1, 52)), FALSE)
    }
}
# THE SCAN EXAMINED A REAL POPULATION. A fence grammar that stopped matching
# would leave every check above vacuously true, which is how a scanner goes
# quietly blind. The floor is well under today's count, so adding a recipe
# does not turn this red; a grammar that stopped matching does.
check_true(ID, sprintf("the page yielded printed blocks to compare (%d block(s), %d recipe(s))",
                       n_out_blocks, length(recipes)),
           n_out_blocks >= 5 && length(recipes) >= 5)

# ---------------------------------------------------------------------------
# 4. THE NUMBERS, AGAINST BASE R
#
# Parsed out of the captures with the same one-line-one-number reader, so a
# capture that stopped printing a line fails on the missing value rather than
# on a wrong one.
# ---------------------------------------------------------------------------
cat("\n-- 4. the printed numbers, recomputed --\n")
num_after <- function(r, pattern) {
    ln <- grep(pattern, captures[[r]], value = TRUE)
    if (!length(ln)) return(NA_real_)
    m <- regmatches(ln[1], regexec(pattern, ln[1]))[[1]]
    if (length(m) < 2) return(NA_real_)
    suppressWarnings(as.numeric(m[2]))
}

g <- read.csv(file.path(FIX, "spl_by_group.csv"), stringsAsFactors = FALSE)
sop <- g$spl[g$group == "soprano"]
mez <- g$spl[g$group == "mezzo"]
tt  <- t.test(sop, mez)
tl  <- t.test(sop, mez, alternative = "less")
sp  <- sqrt(((length(sop) - 1) * var(sop) + (length(mez) - 1) * var(mez)) /
            (length(sop) + length(mez) - 2))
dd  <- (mean(sop) - mean(mez)) / sp
JJ  <- 1 - 3 / (4 * (length(sop) + length(mez) - 2) - 1)

check(ID, "R1 n soprano",  num_after("R1", "^n soprano = ([0-9]+)"),  length(sop), tol = 0)
check(ID, "R1 n mezzo",    num_after("R1", "n mezzo = ([0-9]+)"),     length(mez), tol = 0)
check(ID, "R1 excluded",   num_after("R1", "excluded = ([0-9]+)"),    0,           tol = 0)
check(ID, "R1 Welch t",    num_after("R1", "^t = (-?[0-9.]+)"),       unname(tt$statistic))
check(ID, "R1 Welch df",   num_after("R1", "df = ([0-9.]+)"),         unname(tt$parameter), tol = 5e-3)
check(ID, "R1 two-sided p", num_after("R1", "  p = ([0-9.]+)"),       tt$p.value)
check(ID, "R1 one-tailed p (H1 less)",
      num_after("R1", "^H1 soprano < mezzo: p = ([0-9.]+)"),          tl$p.value)
check(ID, "R1 Cohen's d",  num_after("R1", "^d = (-?[0-9.]+)"),       dd)
check(ID, "R1 Hedges' g",  num_after("R1", "Hedges' g = (-?[0-9.]+)"), dd * JJ)

pp   <- read.csv(file.path(FIX, "pre_post.csv"), stringsAsFactors = FALSE)
ok   <- !is.na(pp$pre) & !is.na(pp$post)
pre  <- pp$pre[ok]; post <- pp$post[ok]
ptt  <- t.test(pre, post, paired = TRUE)
cor2 <- cor.test(pre, post)

check(ID, "R2 complete pairs", num_after("R2", "^complete pairs: ([0-9]+)"), sum(ok), tol = 0)
check(ID, "R2 rows dropped",   num_after("R2", "\\(dropped: ([0-9]+)\\)"),   sum(!ok), tol = 0)
check(ID, "R2 paired t",       num_after("R2", "^paired t = (-?[0-9.]+)"),   unname(ptt$statistic))
check(ID, "R2 paired df",      num_after("R2", "df = ([0-9]+)"),             unname(ptt$parameter), tol = 0)
check(ID, "R2 paired p",       num_after("R2", "paired t.*  p = ([0-9.]+)"), ptt$p.value)
check(ID, "R2 Pearson r",      num_after("R2", "^r = (-?[0-9.]+)"),          unname(cor2$estimate))
check(ID, "R2 Pearson p",      num_after("R2", "^r = -?[0-9.]+  p = ([0-9.]+)"), cor2$p.value)

# R3/R4 -- the one-way ANOVA the orchestrator printed, against aov().
three <- read.csv(repo_path("evidence", "csv", "demo_3groups_input.csv"),
                  stringsAsFactors = FALSE)
anova_ref <- function(col) {
    s <- summary(aov(three[[col]] ~ factor(three$voice_type)))[[1]]
    ss <- s[["Sum Sq"]]
    list(ssb = ss[1], ssw = ss[2], dfb = s[["Df"]][1], dfw = s[["Df"]][2],
         f = s[["F value"]][1], eta = ss[1] / sum(ss))
}
a_spl <- anova_ref("SPL_dB")
check(ID, "R3 ANOVA SS between", num_after("R3", "^Between +([0-9.]+)"), a_spl$ssb, tol = 5e-3)
check(ID, "R3 ANOVA SS within",  num_after("R3", "^Within +([0-9.]+)"),  a_spl$ssw, tol = 5e-3)
check(ID, "R3 ANOVA df between", num_after("R3", "^Between +[0-9.]+ +([0-9]+)"), a_spl$dfb, tol = 0)
check(ID, "R3 ANOVA F",          num_after("R3", "^Between +[0-9.]+ +[0-9]+ +[0-9.]+ +([0-9.]+)"),
      a_spl$f, tol = 5e-4)
check(ID, "R3 eta-squared",      num_after("R3", "eta-squared = ([0-9.]+)"), a_spl$eta, tol = 5e-4)
check(ID, "R3 files written",    num_after("R3", "files written = ([0-9]+)"), 5, tol = 0)
check(ID, "R3 declared",         num_after("R3", "^declared = ([0-9]+)"),     1, tol = 0)

# R4 runs the same analysis twice, on two columns. The capture holds two full
# reports, so the SECOND report's F is read from the tail of the file -- a
# reader that took the first match would pass while measuring R3's column
# again.
a_vib <- anova_ref("vibrato_rate_Hz")
batch <- grep("^BATCH ", captures$R4)
check_true(ID, "R4 printed one BATCH line per column", length(batch) == 2)
f_lines <- grep("^Between ", captures$R4)
check_true(ID, "R4 printed one ANOVA table per column", length(f_lines) == 2)
r4f <- function(i) {
    if (length(f_lines) < i) return(NA_real_)
    m <- regmatches(captures$R4[f_lines[i]],
                    regexec("^Between +[0-9.]+ +[0-9]+ +[0-9.]+ +([0-9.]+)",
                            captures$R4[f_lines[i]]))[[1]]
    if (length(m) < 2) NA_real_ else as.numeric(m[2])
}
check(ID, "R4 F, first column (SPL_dB)",           r4f(1), a_spl$f, tol = 5e-4)
check(ID, "R4 F, second column (vibrato_rate_Hz)", r4f(2), a_vib$f, tol = 5e-4)
b4 <- function(i) {
    if (length(batch) < i) return(NA_real_)
    m <- regmatches(captures$R4[batch[i]],
                    regexec("written = ([0-9]+)", captures$R4[batch[i]]))[[1]]
    if (length(m) < 2) NA_real_ else as.numeric(m[2])
}
check(ID, "R4 files written, first column",  b4(1), 5, tol = 0)
check(ID, "R4 files written, second column", b4(2), 5, tol = 0)

# R5 -- the fixture is synthesised by harness/recipes/make_sound.praat, so its
# fundamental and its vibrato are known quantities rather than a measurement
# of a recording nobody can re-derive. 196 Hz carrier, modulation index 2.0 at
# 5 Hz = a deviation of +/- 10 Hz. The SD of a sinusoid of amplitude A is
# A/sqrt(2), and its quartiles are at -/+ A*sin(pi/4), which is the same
# number -- so the median, the SD and the two quartiles are three independent
# predictions from one generator, and a pitch tracker that had started
# reporting something else could not satisfy all of them.
#
# THE TOLERANCES ARE LOOSER ON THE SPREAD THAN ON THE CENTRE, and the reason
# is the analysis window rather than slack. Autocorrelation reads F0 over a
# window several periods long, so a frame straddling a turning point of a 5 Hz
# modulation reports an average across it: the measured distribution sits
# INSIDE the ideal one and the quartiles pull toward the median. 2 Hz on a
# +/- 10 Hz modulation still refuses a tracker that reported semitones, a
# different fundamental, or no vibrato at all -- all of which move these by
# far more.
dev <- 2.0 * 5
r5n     <- num_after("R5", "^voiced frames: ([0-9]+)")
r5total <- num_after("R5", "of ([0-9]+) \\(")
r5pct   <- num_after("R5", "\\(([0-9.]+)% voiced\\)")
check(ID, "R5 percent voiced is n/nTotal", r5pct, 100 * r5n / r5total, tol = 0.05)
check_true(ID, "R5 the silent window left frames unvoiced",
           is.finite(r5n) && is.finite(r5total) && r5n < r5total)
check(ID, "R5 median F0 is the synthesised carrier",
      num_after("R5", "^median F0 = ([0-9.]+)"), 196, tol = 0.5)
check(ID, "R5 SD is the vibrato's, A/sqrt(2)",
      num_after("R5", "^SD = ([0-9.]+)"), dev / sqrt(2), tol = 0.6)
check(ID, "R5 lower quartile is 196 - A*sin(pi/4)",
      num_after("R5", "^IQR = ([0-9.]+)"), 196 - dev * sin(pi / 4), tol = 2.0)
check(ID, "R5 upper quartile is 196 + A*sin(pi/4)",
      num_after("R5", "^IQR = [0-9.]+ to ([0-9.]+)"), 196 + dev * sin(pi / 4), tol = 2.0)
check(ID, "R5 interquartile width is 2*A*sin(pi/4)",
      num_after("R5", "^IQR = [0-9.]+ to ([0-9.]+)") -
      num_after("R5", "^IQR = ([0-9.]+)"), 2 * dev * sin(pi / 4), tol = 2.0)

# ---------------------------------------------------------------------------
# 5. THE PAGE AGAINST THE PROCEDURE HEADERS
#
# The failure this section is for: a field name that reads perfectly and does
# not exist. Praat does not complain about `emlExtractGroupVectors.data1#` --
# it is simply an unset variable, and an unset numeric variable in an
# expression stops the script with a message about the variable, not about the
# procedure. Worse, a name that IS set by some earlier call returns a stale
# value and the script runs to completion printing nonsense.
# ---------------------------------------------------------------------------
cat("\n-- 5. every name the page uses exists in the source --\n")
check_true(ID, sprintf("the source yielded procedures to resolve against (%d procedures, %d fields)",
                       n_procs, n_fields),
           n_procs >= 200 && n_fields >= 800)

# (a) every @call inside a praat fence is a procedure that exists
called <- character(0)
for (r in recipes) called <- c(called, page$scripts[[r]])
for (b in page$annots) called <- c(called, b$lines)
calls <- unique(unlist(regmatches(called,
    gregexpr("@[A-Za-z][A-Za-z0-9_]*", called))))
calls <- sub("^@", "", calls)
unknown <- calls[!(calls %in% names(proc_fields$fields))]
check_true(ID, sprintf("every @call on the page is a real procedure (%d call(s))",
                       length(calls)),
           length(unknown) == 0 && length(calls) >= 20)
if (length(unknown)) {
    check_true(ID, sprintf("  no such procedure: %s",
                           paste(head(unknown, 6), collapse = ", ")), FALSE)
}

# (b) every field a RECIPE SCRIPT reads is one the procedure assigns
n_reads <- 0L
for (r in recipes) {
    src <- page$scripts[[r]]
    hits <- unlist(regmatches(src, gregexpr(
        "\\b(eml[A-Za-z0-9_]*)\\.([A-Za-z][A-Za-z0-9_]*)(##|#|\\$)?", src)))
    bad <- character(0)
    for (h in hits) {
        m <- regmatches(h, regexec(
            "^(eml[A-Za-z0-9_]*)\\.([A-Za-z][A-Za-z0-9_]*)(##|#|\\$)?$", h))[[1]]
        p <- m[2]; f <- paste0(".", m[3], m[4])
        n_reads <- n_reads + 1L
        known <- proc_fields$fields[[p]]
        if (is.null(known) || !(f %in% known)) bad <- c(bad, paste0(p, f))
    }
    check_true(ID, sprintf("%s: every field it reads is one the procedure sets (%d read(s))",
                           r, length(hits)),
               length(bad) == 0 && length(hits) > 0)
    if (length(bad)) {
        check_true(ID, sprintf("  %s: no such output: %s", r,
                               paste(unique(bad), collapse = ", ")), FALSE)
    }
}
check_true(ID, sprintf("the recipes read enough fields to be worth resolving (%d)", n_reads),
           n_reads >= 25)

# (c) every ANNOTATION BLOCK's argument list is the real signature, and every
#     output it lists is really an output. Only the lines after `Returns:` or
#     `Output:` are read for output names, and only the part of a line to the
#     left of its ` - ` description, so prose cannot be mistaken for a field.
n_annot <- 0L; n_annot_fields <- 0L
for (b in page$annots) {
    hdr <- grep("^# @[A-Za-z][A-Za-z0-9_]*:", b$lines)
    for (k in seq_along(hdr)) {
        start <- hdr[k]
        stop  <- if (k < length(hdr)) hdr[k + 1L] - 1L else length(b$lines)
        m <- regmatches(b$lines[start],
                        regexec("^# @([A-Za-z][A-Za-z0-9_]*):[ ]*(.*)$",
                                b$lines[start]))[[1]]
        p <- m[2]
        doc_args <- trimws(strsplit(m[3], ",")[[1]])
        doc_args <- doc_args[nzchar(doc_args)]
        real_args <- proc_fields$args[[p]]
        n_annot <- n_annot + 1L
        check_true(ID, sprintf("%s: the page's argument list is @%s's signature",
                               b$recipe, p),
                   !is.null(real_args) && identical(doc_args, real_args))
        if (!is.null(real_args) && !identical(doc_args, real_args)) {
            check_true(ID, sprintf("  page says (%s); source says (%s)",
                                   paste(doc_args, collapse = ", "),
                                   paste(real_args, collapse = ", ")), FALSE)
        }

        seg <- b$lines[start:stop]
        ret <- grep("^#[ ]*(Returns|Output):", seg)
        if (!length(ret)) next
        tail_lines <- seg[ret[1]:length(seg)]
        lhs <- sub(" +- .*$", "", tail_lines)
        toks <- unique(unlist(regmatches(lhs, gregexpr(
            "(?<![A-Za-z0-9_.])\\.[A-Za-z][A-Za-z0-9_]*(##|#|\\$)?", lhs,
            perl = TRUE))))
        known <- proc_fields$fields[[p]]
        bad <- toks[!(toks %in% known)]
        n_annot_fields <- n_annot_fields + length(toks)
        check_true(ID, sprintf("%s: every output the page lists for @%s is one it sets (%d)",
                               b$recipe, p, length(toks)),
                   length(bad) == 0 && length(toks) > 0)
        if (length(bad)) {
            check_true(ID, sprintf("  @%s does not set: %s", p,
                                   paste(bad, collapse = ", ")), FALSE)
        }
    }
}
check_true(ID, sprintf("the annotation blocks were read (%d procedure(s), %d field name(s))",
                       n_annot, n_annot_fields),
           n_annot >= 8 && n_annot_fields >= 40)

# ---------------------------------------------------------------------------
# 6. WHAT THE RECIPES WROTE
#
# R3 and R4 are the only recipes that put anything on disk, and what they put
# there is the whole point of them. The frames are named by broom's
# convention, and a set that arrived short a frame is the failure the loop
# recipe's `.success` habit is about.
# ---------------------------------------------------------------------------
cat("\n-- 6. the files R3 and R4 wrote --\n")
files <- if (file.exists(file.path(OUT, "FILES.tsv")))
    read.delim(file.path(OUT, "FILES.tsv"), stringsAsFactors = FALSE) else
    data.frame(recipe = character(0), file = character(0), bytes = integer(0))
suffixes <- c("_tidy.csv", "_glance.csv", "_augment.csv",
              "_posthoc_tidy.csv", "_effectsize_tidy.csv")
for (spec in list(list(r = "R3", bases = "anova_by_voice_type"),
                  list(r = "R4", bases = c("anova_SPL_dB", "anova_vibrato_rate_Hz")))) {
    got <- files[files$recipe == spec$r, , drop = FALSE]
    want <- as.vector(outer(spec$bases, suffixes, paste0))
    check_true(ID, sprintf("%s wrote the %d broom frame(s) it reported",
                           spec$r, length(want)),
               setequal(got$file, want))
    check_true(ID, sprintf("%s wrote no empty frame", spec$r),
               nrow(got) > 0 && all(got$bytes > 0))
    check_true(ID, sprintf("%s's frames are committed beside the capture", spec$r),
               nrow(got) > 0 &&
               all(file.exists(file.path(OUT, paste0(spec$r, ".", got$file)))))
}

# ---------------------------------------------------------------------------
# 7. NOTHING WENT UNLOOKED-AT
# ---------------------------------------------------------------------------
cat("\n-- 7. coverage --\n")
check_true(ID, sprintf("every ## R<n> heading on the page has a runnable script (%d)",
                       length(page$headings)),
           setequal(page$headings, recipes) && length(recipes) >= 5)
check_true(ID, "every recipe the page defines was driven",
           setequal(recipes, res$recipe))
check_true(ID, "every recipe has at least one printed block pinned",
           setequal(names(out_by_recipe), recipes))
eml_census(ID, "recipe", present = res$recipe, accounted = recipes)
eml_claim(ID, "recipes_out", recipes)

# THE GUARD IS NOT DECORATION. eml_exit() calls quit(status = 1) as soon as
# ANY check in the run has failed, so an unguarded call here is a no-op only
# while the whole suite is green and a hard stop the moment it is not. Under
# run_all.R that would end the run at this file -- silently, with a total that
# looks like a complete pass -- and take the scripts after it with it,
# coverage.R among them. The pass that finds green checks measuring nothing
# must not be the first thing a red suite switches off.
if (!exists("EML_SUITE")) {
    eml_report("v81 -- plugin/docs/RECIPES.md, run and pinned")
    eml_exit()
}
