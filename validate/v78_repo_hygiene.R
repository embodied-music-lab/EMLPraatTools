# ============================================================================
# v78_repo_hygiene.R -- the four checks that keep the repository honest about
# itself: the manifest, the include closure, the front-door links, and CI
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS
#
# Every check in this suite except this one is about a NUMBER the plugin
# printed. This one is about the repository's statements about itself, and it
# exists because all four of the things below were red at once on 16 August
# 2026, and three of them had been red long enough that nobody was reading
# them:
#
#   MANIFEST.txt had been stale since 4 August -- twelve days. It is a
#   generated file that is checked in, so it goes stale whenever any listed
#   file changes size, which is most commits. `--check` existed and was
#   correct the whole time; nothing ran it. A check nobody runs is not a
#   check, so the point of this file is not that the manifest is green today,
#   it is that regenerating it is now the only way to get a green suite.
#
#   harness/check_includes.py reported 22 entry scripts with unresolved
#   calls, of which 21 were the checker's own false positives -- Praat's ";"
#   comments read as code, and four include-list barrels checked as if they
#   were scripts. A checker with a 95% false-positive rate teaches its reader
#   to ignore it, which is worse than not having it, because the one true
#   entry was in the list the whole time.
#
#   plugin/README.md pointed at docs/procedure-reference.md and
#   docs/recipes.md. Neither file has ever existed.
#
#   There was no .github/workflows at all, which is why the three above could
#   sit red. The workflow runs THIS SUITE, and this file is in the suite, so
#   the four checks gate each other: CI runs the suite, the suite runs these
#   checks, and these checks include "CI exists and runs the suite".
#
# WHAT THIS FILE DOES NOT DO. It does not re-implement the manifest generator
# or the include checker in R. It runs them and reads their exit status,
# because a second implementation would be a second thing to keep in step and
# the first divergence would be invisible. That costs a python3, which the
# suite did not previously need; python3 is present on every GitHub runner
# image and on every machine that can run the tools under plugin/dev/tools/,
# and its absence is reported as a FAILED check rather than a skip -- a
# missing interpreter is exactly the state in which the manifest quietly
# rotted, so it is not something to pass over quietly.
#
#     Rscript validate/v78_repo_hygiene.R
#
# Input: the source tree only. No harness artefact, no Praat.
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

ROOT <- repo_path(".")
plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
WORKFLOW <- Sys.getenv("EML_CI_WORKFLOW", unset = "")
if (!nzchar(WORKFLOW)) WORKFLOW <- repo_path(".github", "workflows", "validate.yml")

py <- Sys.which("python3")
have_py <- nzchar(py)
check_true("v78", "python3 is available (the two static checkers are python)",
           have_py)

run_tool <- function(cmd, args, wd) {
    old <- setwd(wd); on.exit(setwd(old))
    out <- suppressWarnings(system2(cmd, args, stdout = TRUE, stderr = TRUE))
    st <- attr(out, "status")
    list(status = if (is.null(st)) 0L else as.integer(st), out = out)
}

# ---------------------------------------------------------------------------
# 1. THE MANIFEST DESCRIBES THE TREE IT SHIPS WITH
# ---------------------------------------------------------------------------
# The assertion is the generator's own --check, not a re-derivation here.
# --check re-renders the manifest from the tree and compares, ignoring only
# the "# Generated:" date line, so it fails on a changed line count, a
# changed Version: header, a new file, a deleted file, and -- through the
# folded sprites/ row -- on any change to the sprite set.
if (have_py) {
    r <- run_tool(py, c("dev/tools/build-manifest.py", "--check"), plug)
    check_true("v78",
               sprintf("MANIFEST.txt is current (build-manifest.py --check: %s)",
                       paste(utils::tail(r$out, 1), collapse = "")),
               r$status == 0L)
} else {
    check_true("v78", "MANIFEST.txt is current (build-manifest.py --check)",
               FALSE)
}

# NO ROW MAY BE LEFT UNDESCRIBED. --check passes whether or not the curated
# column says anything, because a TODO is a legitimate rendered state for a
# file that has just arrived. It is not a legitimate state for a file that
# has been in the tree a while: on 16 August 2026 fifteen rows had been
# waiting for a description since 4 August. Nothing else in the tree can tell
# the difference, so the rule here is the simple one.
man <- readLines(file.path(plug, "MANIFEST.txt"), warn = FALSE)
rows <- man[!grepl("^\\s*#", man) & grepl("\\|", man)]
todo <- rows[grepl("TODO:", rows, fixed = TRUE)]
check_true("v78",
           sprintf("no manifest row is left as TODO (%s)",
                   if (length(todo)) paste(sub(" *\\|.*", "", todo), collapse = ", ")
                   else "none"),
           length(todo) == 0)
check_true("v78", sprintf("the manifest has rows (%d)", length(rows)),
           length(rows) > 0)

# THE HEADER'S FILE COUNT IS THE TREE'S FILE COUNT. --check would catch a
# wrong count too, since the header is rendered; this is here because the
# count is the one thing in the manifest a reader is likely to quote, and a
# separate arithmetic path saying the same number is worth the two lines.
hdr <- grep("^# Generated:", man, value = TRUE)
n_claimed <- suppressWarnings(as.integer(
    sub(".*\\|\\s*([0-9]+) files.*", "\\1", hdr[1])))
n_real <- length(list.files(plug, recursive = TRUE, all.files = TRUE,
                            no.. = TRUE))
# The walk above sees MANIFEST.txt, dotfiles and __pycache__, none of which
# the manifest lists; subtract them the same way collect() skips them.
walked <- list.files(plug, recursive = TRUE, all.files = TRUE, no.. = TRUE)
walked <- walked[!grepl("(^|/)__pycache__/", walked)]
walked <- walked[!grepl("(^|/)\\.", walked)]
walked <- walked[basename(walked) != "MANIFEST.txt"]
walked <- walked[!grepl("\\.(bak|pyc|orig|rej|swp|tmp)$", walked)]
check_true("v78",
           sprintf("the manifest header's file count is the tree's (%s claimed, %d walked)",
                   n_claimed, length(walked)),
           !is.na(n_claimed) && n_claimed == length(walked))

# ---------------------------------------------------------------------------
# 2. EVERY @CALL RESOLVES IN ITS OWN INCLUDE CLOSURE
# ---------------------------------------------------------------------------
# The defect class is the 6 August one: Praat resolves a procedure name at
# CALL time, so a wrapper that calls into a module it does not include parses
# cleanly, opens its dialog, and dies the instant Run is pressed.
if (have_py) {
    r <- run_tool(py, c("harness/check_includes.py", "plugin"), ROOT)
    bad <- grep("^UNRESOLVED", r$out, value = TRUE)
    check_true("v78",
               sprintf("every @call resolves in its closure (%s)",
                       if (length(bad)) paste(bad, collapse = "; ")
                       else paste(utils::tail(r$out, 1), collapse = "")),
               r$status == 0L)
    # THE GUARD AWARENESS IS ASSERTED, NOT ASSUMED. The checker passes
    # trivially if it stops finding calls at all -- a broken regex would be
    # indistinguishable from a clean tree. So the run must also report that
    # it saw entry scripts, and that it allowed at least one existence-
    # guarded optional call, which is the feature that made it green.
    tail_line <- paste(utils::tail(r$out, 1), collapse = "")
    n_entry <- suppressWarnings(as.integer(
        sub(".*resolves, ([0-9]+) entry script.*", "\\1", tail_line)))
    n_opt <- suppressWarnings(as.integer(
        sub(".*, ([0-9]+) existence-guarded.*", "\\1", tail_line)))
    check_true("v78",
               sprintf("the checker examined entry scripts (%s)", n_entry),
               !is.na(n_entry) && n_entry >= 20)
    check_true("v78",
               sprintf("the checker recognised existence-guarded calls (%s)", n_opt),
               !is.na(n_opt) && n_opt >= 1)
} else {
    check_true("v78", "every @call resolves in its closure", FALSE)
    check_true("v78", "the checker examined entry scripts", FALSE)
    check_true("v78", "the checker recognised existence-guarded calls", FALSE)
}

# ---------------------------------------------------------------------------
# 3. THE FRONT-DOOR DOCUMENTS POINT AT FILES THAT EXIST
# ---------------------------------------------------------------------------
# WHAT COUNTS AS A LINK. Backticked or bracketed, containing a "/" (so a bare
# `gui.sh` mentioned in a sentence about harness/ is not a claim about a path
# relative to the document), no whitespace (so a shell fragment like
# `infotext > out/file.txt` is not read as a file name), and carrying a
# suffix this repository actually uses. Resolved against the document's own
# directory first and then the repository root, because both conventions
# appear in these files and both are legible to a reader.
docs <- c("README.md", "START_HERE.md",
          file.path("plugin", "README.md"),
          file.path("validate", "README.md"))
suffix <- "\\.(md|praat|py|R|csv|txt|sh|json|ya?ml|tsv)$"
dead <- character(0)
looked <- 0L
for (d in docs) {
    p <- repo_path(d)
    if (!file.exists(p)) { dead <- c(dead, paste0(d, " (document missing)")); next }
    src <- readLines(p, warn = FALSE)
    src <- paste(src, collapse = "\n")
    refs <- c(regmatches(src, gregexpr("`[^`\n]+`", src))[[1]],
              regmatches(src, gregexpr("\\]\\([^)\n]+\\)", src))[[1]])
    refs <- gsub("^`|`$|^\\]\\(|\\)$", "", refs)
    refs <- sub("#.*$", "", refs)
    refs <- unique(trimws(refs))
    refs <- refs[grepl("/", refs, fixed = TRUE)]
    refs <- refs[!grepl("[[:space:]]", refs)]
    refs <- refs[grepl(suffix, refs)]
    refs <- refs[!grepl("^(https?|ftp)://", refs)]
    for (ref in refs) {
        looked <- looked + 1L
        here <- normalizePath(file.path(dirname(p), ref), mustWork = FALSE)
        there <- normalizePath(file.path(ROOT, ref), mustWork = FALSE)
        if (!file.exists(here) && !file.exists(there)) {
            dead <- c(dead, paste0(d, " -> ", ref))
        }
    }
}
check_true("v78",
           sprintf("the front-door documents link no missing file (%s)",
                   if (length(dead)) paste(dead, collapse = "; ") else "none dead"),
           length(dead) == 0)
# THE SCANNER MUST BE FINDING SOMETHING. A regex that matched nothing would
# report zero dead links forever, which is the same shape of vacuity v78's
# subject is about in the first place.
check_true("v78",
           sprintf("the link scanner resolved references (%d)", looked),
           looked >= 20)

# The two pages that were promised and never written are named in
# plugin/README.md as absent. If either is ever added, this check goes red and
# whoever added it can delete the paragraph saying it does not exist.
pr <- paste(readLines(file.path(plug, "README.md"), warn = FALSE), collapse = "\n")
check_true("v78",
           "plugin/README.md no longer offers docs/procedure-reference.md or docs/recipes.md",
           !grepl("`docs/procedure-reference\\.md`", pr) &&
           !grepl("`docs/recipes\\.md`", pr))
check_true("v78",
           "neither promised page has since been written (if it has, drop the note)",
           !file.exists(file.path(plug, "docs", "procedure-reference.md")) &&
           !file.exists(file.path(plug, "docs", "recipes.md")))

# The procedure count plugin/README.md states, recomputed. It is there so a
# reader can see why no signature list was written; a wrong figure would be
# an argument resting on a number that is not true.
n_proc <- 0L
for (f in c(list.files(file.path(plug, "stats"), "\\.praat$", full.names = TRUE),
            list.files(file.path(plug, "graphs"), "\\.praat$", full.names = TRUE))) {
    n_proc <- n_proc + sum(grepl("^procedure ", readLines(f, warn = FALSE)))
}
stated <- suppressWarnings(as.integer(
    sub(".*define ([0-9]+) procedures.*", "\\1",
        grep("define [0-9]+ procedures", strsplit(pr, "\n")[[1]], value = TRUE)[1])))
check_true("v78",
           sprintf("plugin/README.md's procedure count is the tree's (%s stated, %d counted)",
                   stated, n_proc),
           !is.na(stated) && stated == n_proc)

# ---------------------------------------------------------------------------
# 4. CI RUNS THIS SUITE, AND ASKS NOBODY FOR A SECRET
# ---------------------------------------------------------------------------
check_true("v78", ".github/workflows/validate.yml exists",
           file.exists(WORKFLOW))
if (file.exists(WORKFLOW)) {
    wf <- readLines(WORKFLOW, warn = FALSE)
    body <- paste(wf, collapse = "\n")
    code <- wf[!grepl("^\\s*#", wf)]
    codebody <- paste(code, collapse = "\n")

    check_true("v78", "the workflow runs Rscript validate/run_all.R",
               grepl("Rscript validate/run_all\\.R", codebody))

    # THE TRIGGERS ARE READ OUT OF THE `on:` BLOCK, not matched anywhere in
    # the file: "push" appears in this workflow's prose and a bare grep would
    # be satisfied by a comment. The block is the lines after `on:` that are
    # indented, up to the next line that is not.
    on_at <- grep("^on:\\s*$", code)
    on_block <- character(0)
    if (length(on_at)) {
        for (i in seq(on_at[1] + 1L, length(code))) {
            if (grepl("^[^[:space:]]", code[i])) break
            on_block <- c(on_block, code[i])
        }
    }
    check_true("v78", "the workflow has an on: block",
               length(on_at) == 1 && length(on_block) > 0)
    check_true("v78", "the workflow triggers on push",
               any(grepl("^\\s+push:", on_block)))
    check_true("v78", "the workflow triggers on pull_request",
               any(grepl("^\\s+pull_request:", on_block)))

    # THE SUITE'S REAL DEPENDENCIES ARE INSTALLED. R alone is not enough --
    # seven validators drive a Praat and fail without one, and the barren
    # edition fails v59 -- so a workflow that installed only R would be red
    # on its first run. See the workflow's own header for the measurement.
    check_true("v78", "the workflow installs R", grepl("r-base", codebody))
    check_true("v78", "the workflow installs a Praat at or above the floor",
               grepl("praat6630_linux-x64v3\\.tar\\.gz", codebody))
    check_true("v78", "the Praat it installs is not the barren edition",
               !grepl("x64v3-barren", codebody))

    # NO SECRET, NO TOKEN. A hygiene workflow that needs credentials cannot
    # run on a fork's pull request, which is most of the pull requests a
    # public plugin gets.
    check_true("v78",
               sprintf("the workflow reads no secret or token (%s)",
                       paste(grep("secrets\\.|\\$\\{\\{\\s*github\\.token",
                                  code, value = TRUE), collapse = "; ")),
               !grepl("secrets\\.", codebody) &&
               !grepl("\\$\\{\\{\\s*github\\.token", codebody))
    check_true("v78", "the workflow asks for no more than read permission",
               grepl("permissions:", codebody) &&
               grepl("contents:\\s*read", codebody) &&
               !grepl("contents:\\s*write", codebody))

    # No `continue-on-error` and no `|| true`: the point of the job is that a
    # nonzero exit from run_all.R fails the build.
    check_true("v78", "no step swallows a failure",
               !grepl("continue-on-error", codebody) &&
               !grepl("\\|\\|\\s*true", codebody))

    # The floor is stated in exactly one more place than harness/_env.sh, so
    # they are checked against each other rather than both being trusted.
    envsh <- paste(readLines(repo_path("harness", "_env.sh"), warn = FALSE),
                   collapse = "\n")
    floor_env <- sub(".*_eml_min_version=([0-9]+).*", "\\1", envsh)
    check_true("v78",
               sprintf("the workflow's Praat matches harness/_env.sh's floor (%s)",
                       floor_env),
               grepl(paste0("praat", floor_env, "_linux"), codebody))
} else {
    for (w in c("the workflow runs Rscript validate/run_all.R",
                "the workflow has an on: block",
                "the workflow triggers on push",
                "the workflow triggers on pull_request")) {
        check_true("v78", w, FALSE)
    }
}

if (!exists("EML_SUITE")) {
    eml_report("v78 repository hygiene: manifest, includes, links, CI")
    eml_exit()
}
