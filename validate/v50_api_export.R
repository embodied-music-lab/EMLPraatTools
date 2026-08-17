# ============================================================================
# v50_api_export.R -- @emlExportResultFiles called as CODE, and documented
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. @emlExportResultFiles is one procedure with three
# callers. Two of them are inside the plugin and both are dialogs:
# @emlSavePanel and the graphs form's Exp CSV button. The third is a voice
# researcher's own Praat script, and the procedure's own header names it --
#
#     "this procedure is also the CODE/API export path -- dialog-free,
#      callable from a user's own script -- and there the first call in a
#      fresh session has nothing set. The guard existed because that case is
#      real, and it was the one case the guard could not survive."
#
# -- which is a defect report about a caller nothing in this tree had ever
# been. It was found by reading, fixed on 14 August 2026, and the case it was
# fixed for stayed undriven.
#
# WHAT THE EXISTING FILES CANNOT SEE, and it is not one gap but four.
#
# v46 is STATIC. It reads eml-output.praat and proves the procedure exists
# exactly once and that every export dialog reaches a writer through it. Every
# claim it makes is true and none of them runs anything.
#
# v48 is a JOURNEY check and its journeys all begin at a dialog. Every one of
# its eleven legs arrives at the exporter through @emlSavePanel, which has
# ALREADY established that there is something to export (it only offers the
# CSV tickbox when emlCSV_n > 0 or emlResult_declared = 1) and has ALREADY
# called createFolder: on the folder the user typed. Both of those are the
# PANEL's preconditions. An API caller inherits neither, so the two cases that
# distinguish the API path -- an export with nothing declared at all, and an
# export into a folder that does not exist -- are exactly the two v48's
# population is constructed to exclude.
#
# v49 enumerates terminal branches of the WIZARD. Same dialogs, same
# preconditions.
#
# And nothing at all read the documentation. A documented example that nobody
# runs is a guess about an API; this repository has shipped two of those and
# both were found by a user rather than by a check.
#
# So this file's population is the set of API CALLS: for each way a script can
# call the procedure, did it return what its own header says it returns, did
# the files named in .fileList$ actually arrive, and does plugin/docs/API_EXPORT.md
# still describe what happened.
#
# THE THREE CHECKS THAT MATTER MOST, because they are the ones no reading
# could have settled:
#
#   1. `fresh` -- nothing ran, so emlResult_declared is not 0 but ABSENT. It
#      must come back declared=0 nWritten=0 reason=empty and NOT abort.
#   2. `collide` -- the same export twice. The BASE is uniqued once, against
#      the tidy frame, so the second call must produce a COMPLETE second set
#      under the walked base, not frame 1 of the new set beside frames 2 and 3
#      of the old one.
#   3. The example in plugin/docs/API_EXPORT.md is compared LINE BY LINE against the
#      script the harness actually ran. Prose that drifts from the code it
#      documents fails here rather than in somebody's project folder.
#
#     bash harness/api_export/run.sh
#     Rscript validate/v50_api_export.R
#
# Input: harness/api_export/out/ -- ARTEFACTS.tsv (name<TAB>bytes), one
#        <leg>.outputs.tsv per leg, and every file the legs wrote -- plus the
#        plugin source and plugin/docs/API_EXPORT.md. $EML_API_EXPORT_DIR,
#        $EML_PLUGIN_DIR and $EML_DOCS_DIR override, for break tests.
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

ap <- Sys.getenv("EML_API_EXPORT_DIR", unset = "")
if (!nzchar(ap)) ap <- repo_path(file.path("harness", "api_export", "out"))
plug <- Sys.getenv("EML_PLUGIN_DIR", unset = "")
if (!nzchar(plug)) plug <- repo_path("plugin")
docs <- Sys.getenv("EML_DOCS_DIR", unset = "")
if (!nzchar(docs)) docs <- repo_path("plugin", "docs")

# readable -- a file that is there AND has bytes in it.
#
# FOUND BY A BREAK TEST, 14 August 2026. Truncating anova_spl_glance.csv to
# zero bytes made read.csv() halt the whole script, so the one check that would
# have named the problem -- "no manifest entry is empty" -- never printed and
# the run reported an R error instead of a FAIL. A validator that dies is
# strictly worse than one that fails by name: the failure it was built to
# describe is exactly the state that stops it describing anything.
readable <- function(id, what, p) {
    ok <- file.exists(p) && isTRUE(file.info(p)$size > 0)
    check_true("v50", what, ok)
    ok
}

check_true("v50", "the api_export artefact exists (bash harness/api_export/run.sh)",
           dir.exists(ap))
if (!dir.exists(ap)) {
    if (!exists("EML_SUITE")) { eml_report("v50 api export"); eml_exit() }
}

# ---------------------------------------------------------------------------
# 0. THE MANIFEST, AND THAT IT DESCRIBES THE DIRECTORY IT CLAIMS TO
# ---------------------------------------------------------------------------
# ARTEFACTS.tsv is one line per file the run produced. It is read rather than
# the directory itself for the same reason v48 reads its TSVs: a check that
# listed the folder would agree with whatever happened to be lying there,
# including the leftovers of a previous run.
manp <- file.path(ap, "ARTEFACTS.tsv")
man <- data.frame(name = character(0), bytes = numeric(0),
                  stringsAsFactors = FALSE)
if (check_true("v50", "ARTEFACTS.tsv was written", file.exists(manp))) {
    man <- read.delim(manp, header = FALSE, sep = "\t", quote = "",
                      stringsAsFactors = FALSE, fill = TRUE,
                      col.names = c("name", "bytes"))
    man$name <- trimws(as.character(man$name))
    man$bytes <- suppressWarnings(as.numeric(man$bytes))
}
check_true("v50", sprintf("the manifest has rows (%d)", nrow(man)),
           nrow(man) > 0)

# EVERY LINE OF THE MANIFEST IS A FILE THAT IS THERE AND IS NOT EMPTY. A
# zero-byte CSV is the shape a half-finished write leaves behind, and it would
# satisfy every "was a file written" check in this file.
absent <- man$name[!file.exists(file.path(ap, man$name))]
check_true("v50",
           sprintf("every manifest entry is a file on disk (missing: %s)",
                   if (length(absent)) paste(absent, collapse = ", ") else "none"),
           length(absent) == 0)
empty <- man$name[is.na(man$bytes) | man$bytes <= 0]
check_true("v50",
           sprintf("no manifest entry is empty (%s)",
                   if (length(empty)) paste(empty, collapse = ", ") else "none empty"),
           length(empty) == 0)

# ---------------------------------------------------------------------------
# 1. COVERAGE: every leg the driver can run, ran
# ---------------------------------------------------------------------------
# READ OUT OF THE DRIVER, not out of a list kept here. A list kept here would
# agree with itself forever; the driver is the thing that changes. A ninth leg
# added to api_export.praat and not wired into run.sh fails this file by name.
drvp <- Sys.getenv("EML_API_DRIVER", unset = "")
if (!nzchar(drvp))
    drvp <- repo_path(file.path("harness", "api_export", "api_export.praat"))
declared_legs <- character(0)
if (readable("v50", "the driver source is readable", drvp)) {
    dl <- readLines(drvp, warn = FALSE)
    dl <- dl[!grepl("^\\s*[#;]", dl)]
    hit <- regmatches(dl, regexpr('leg\\$ = "[^"]+"', dl))
    declared_legs <- sort(unique(sub('^leg\\$ = "([^"]+)"$', "\\1", hit)))
}
check_true("v50", sprintf("the driver defines legs (%s)",
                          paste(declared_legs, collapse = ", ")),
           length(declared_legs) >= 7)

present_legs <- sort(sub("\\.outputs\\.tsv$", "",
                         man$name[grepl("\\.outputs\\.tsv$", man$name)]))
undriven <- setdiff(declared_legs, present_legs)
check_true("v50",
           sprintf("every leg the driver defines was driven (undriven: %s)",
                   if (length(undriven)) paste(undriven, collapse = ", ") else "none"),
           length(undriven) == 0)

# THE DOCUMENTED EXAMPLE IS THE NINTH LEG and run.sh owns it, because it is
# not run through the driver at all -- it is run from a staged copy in a folder
# outside the plugin, which is the whole point of it.
check_true("v50", "the documented example was run (example.log)",
           "example.log" %in% man$name)

# ---------------------------------------------------------------------------
# READING A LEG'S REPORT
# ---------------------------------------------------------------------------
# <leg>.outputs.tsv is key<TAB>value, one record per CALL of the exporter,
# each record opening with a `leg` key. `collide` and `loop` call it twice, so
# a reader that assumed one record per file would silently drop the second
# call -- which in `collide` is the entire subject of the leg.
read_leg <- function(leg) {
    p <- file.path(ap, paste0(leg, ".outputs.tsv"))
    if (!file.exists(p)) return(list())
    ln <- readLines(p, warn = FALSE)
    ln <- ln[nzchar(ln)]
    recs <- list(); cur <- NULL
    for (l in ln) {
        kv <- strsplit(l, "\t", fixed = TRUE)[[1]]
        k <- kv[1]; v <- if (length(kv) > 1) kv[2] else ""
        if (identical(k, "leg")) {
            if (!is.null(cur)) recs[[length(recs) + 1L]] <- cur
            cur <- list(files = character(0), skipped = character(0))
        }
        if (is.null(cur)) next
        if (identical(k, "file")) {
            cur$files <- c(cur$files, v)
        } else if (identical(k, "skipped")) {
            cur$skipped <- c(cur$skipped, v)
        } else {
            cur[[k]] <- v
        }
    }
    if (!is.null(cur)) recs[[length(recs) + 1L]] <- cur
    recs
}

num <- function(rec, k) suppressWarnings(as.numeric(rec[[k]]))

# Every path .fileList$ names has to be a file the manifest knows about. This
# is the join that makes the procedure's own report checkable: a procedure
# that counted a write it did not perform would pass every check on .nWritten.
files_present <- function(rec) all(rec$files %in% man$name)

# ---------------------------------------------------------------------------
# 2. THE DECLARED ARM -- five frames, and the two staged extras
# ---------------------------------------------------------------------------
d <- read_leg("declared")
if (check_true("v50", "declared: the exporter reported once", length(d) == 1)) {
    r <- d[[1]]
    check("v50", "declared: .declared is 1", 1, num(r, "declared"), tol = 0)
    check("v50", "declared: .success is 1", 1, num(r, "success"), tol = 0)
    check("v50", "declared: .nWritten is 5", 5, num(r, "nWritten"), tol = 0)
    check_true("v50", "declared: .reason$ is empty on a clean export",
               identical(r$reason, ""))
    # THE LEGACY OUTPUT MUST STAY EMPTY ON THIS ARM. .actualPath$ is documented
    # as the legacy arm's single file; a value here would mean the fork ran
    # both ways, which is how a set and a long-format file end up side by side.
    check_true("v50", "declared: .actualPath$ is empty on the broom arm",
               identical(r$actualPath, ""))
    want <- c("anova_spl_tidy.csv", "anova_spl_glance.csv",
              "anova_spl_augment.csv", "anova_spl_posthoc_tidy.csv",
              "anova_spl_effectsize_tidy.csv")
    check_true("v50",
               sprintf("declared: the five frames were named (%s)",
                       paste(setdiff(want, r$files), collapse = ", ")),
               setequal(want, r$files))
    check_true("v50", "declared: every named frame is in the manifest",
               files_present(r))
    check_true("v50", "declared: nothing was skipped when all three verbs had rows",
               length(r$skipped) == 0)
}

# THE FRAMES ARE BROOM-SHAPED, checked on the header rather than taken on
# trust. v17 owns broom parity in general; what is asserted here is only that
# the API path produced the same shape the dialog path does, because an export
# that wrote the right NUMBER of files with the wrong contents would satisfy
# everything above.
tp <- file.path(ap, "anova_spl_tidy.csv")
if (readable("v50", "declared: the tidy frame is readable and non-empty", tp)) {
    h <- strsplit(readLines(tp, n = 1, warn = FALSE), ",", fixed = TRUE)[[1]]
    check_true("v50",
               sprintf("declared: the tidy frame leads with broom's `term` (%s)",
                       paste(h, collapse = " ")),
               length(h) > 0 && identical(h[1], "term"))
}
gp <- file.path(ap, "anova_spl_glance.csv")
if (readable("v50", "declared: the glance frame is readable and non-empty", gp)) {
    g <- read.csv(gp, stringsAsFactors = FALSE)
    check("v50", "declared: glance is one row per model", 1L, nrow(g), tol = 0)
    check_true("v50", "declared: glance names the analysis it describes",
               "method" %in% names(g) && identical(g$method[1], "One-way ANOVA"))
}

# ---------------------------------------------------------------------------
# 3. .skipped$ -- an absent file that is explained rather than missing
# ---------------------------------------------------------------------------
# A verb with no rows produces no file, and that is indistinguishable on disk
# from a write that failed. .skipped$ is the whole of the difference, and the
# ANOVA leg can never exercise it because ANOVA fills all three verbs.
p <- read_leg("partial")
if (check_true("v50", "partial: the exporter reported once", length(p) == 1)) {
    r <- p[[1]]
    check("v50", "partial: .declared is 1", 1, num(r, "declared"), tol = 0)
    check("v50", "partial: .nWritten is 2, not 3", 2, num(r, "nWritten"), tol = 0)
    check_true("v50", "partial: no augment file was written",
               !any(grepl("_augment\\.csv$", r$files)))
    check_true("v50",
               sprintf("partial: .skipped$ says which verb and why (%s)",
                       paste(r$skipped, collapse = " | ")),
               length(r$skipped) == 1 && grepl("^augment:", r$skipped[1]))
    check_true("v50", "partial: every named frame is in the manifest",
               files_present(r))
}

# ---------------------------------------------------------------------------
# 4. THE LEGACY ARM -- one long-format file, from the one path that takes it
# ---------------------------------------------------------------------------
lg <- read_leg("legacy")
if (check_true("v50", "legacy: the exporter reported once", length(lg) == 1)) {
    r <- lg[[1]]
    check("v50", "legacy: .declared is 0", 0, num(r, "declared"), tol = 0)
    check("v50", "legacy: .success is 1", 1, num(r, "success"), tol = 0)
    check("v50", "legacy: .nWritten is 1", 1, num(r, "nWritten"), tol = 0)
    check_true("v50", "legacy: .actualPath$ names the file that was written",
               identical(r$actualPath, "describe_spl.csv"))
    check_true("v50", "legacy: .fileList$ agrees with .actualPath$",
               identical(r$files, "describe_spl.csv"))
    check_true("v50", "legacy: no broom frame was written under that base",
               !any(grepl("^describe_spl_(tidy|glance|augment)\\.csv$", man$name)))
}
lp <- file.path(ap, "describe_spl.csv")
if (readable("v50", "legacy: the long-format file is readable and non-empty",
             lp)) {
    h <- strsplit(readLines(lp, n = 1, warn = FALSE), ",", fixed = TRUE)[[1]]
    # THE SIX-COLUMN SHAPE IS THE WHOLE POINT OF THIS ARM. It is one row per
    # NUMBER, not one row per term, and a reader on the R side reshapes it. If
    # this ever becomes a broom frame, the fork has moved and the document is
    # wrong.
    check_true("v50",
               sprintf("legacy: the long format is table/analysis/term/... (%s)",
                       paste(h, collapse = " ")),
               identical(h, c("table", "analysis", "term", "term_type",
                              "field", "value")))
}

# ---------------------------------------------------------------------------
# 5. ONE ARM OR THE OTHER, ACROSS EVERY CALL
# ---------------------------------------------------------------------------
# Checked as an exclusive-or rather than as two expectations, for the same
# reason v48 does: a call producing BOTH shapes would mean the fork ran twice
# or the collectors leaked, and neither would fail a check that merely asked
# for one of them.
for (leg in intersect(c("declared", "collide", "partial", "loop", "legacy"),
                      present_legs)) {
    for (rec in read_leg(leg)) {
        broom  <- any(grepl("_tidy\\.csv$", rec$files)) &&
                  any(grepl("_glance\\.csv$", rec$files))
        legacy <- length(rec$files) == 1 &&
                  !grepl("_(tidy|glance|augment)\\.csv$", rec$files[1])
        check_true("v50",
                   sprintf("%s/%s: exactly one arm (broom=%s legacy=%s)",
                           leg, rec$phase, broom, legacy),
                   xor(broom, legacy))
        check_true("v50", sprintf("%s/%s: .nWritten equals the file count",
                                  leg, rec$phase),
                   isTRUE(num(rec, "nWritten") == length(rec$files)))
    }
}

# ---------------------------------------------------------------------------
# 6. COLLISION: the BASE is walked once, and the whole set follows it
# ---------------------------------------------------------------------------
cl <- read_leg("collide")
if (check_true("v50", "collide: the exporter reported twice", length(cl) == 2)) {
    a <- cl[[1]]; b <- cl[[2]]
    check("v50", "collide: the first call wrote five frames",
          5, num(a, "nWritten"), tol = 0)
    check("v50", "collide: the second call wrote five frames too",
          5, num(b, "nWritten"), tol = 0)
    check_true("v50", "collide: the first call used the base it was given",
               setequal(a$files,
                        c("twice_tidy.csv", "twice_glance.csv",
                          "twice_augment.csv", "twice_posthoc_tidy.csv",
                          "twice_effectsize_tidy.csv")))
    # THE CLAIM. Not "a second tidy file appeared" -- EVERY frame of the second
    # set, including the two staged extras, carries the walked base. Uniquing
    # per file instead of per base would give twice_1_tidy.csv beside a
    # twice_glance.csv that had just overwritten the first run's, and only a
    # set-level assertion can tell those apart.
    check_true("v50",
               sprintf("collide: the whole second set carries the walked base (%s)",
                       paste(b$files, collapse = ", ")),
               setequal(b$files,
                        c("twice_1_tidy.csv", "twice_1_glance.csv",
                          "twice_1_augment.csv", "twice_1_posthoc_tidy.csv",
                          "twice_1_effectsize_tidy.csv")))
    check_true("v50", "collide: both sets survive on disk",
               files_present(a) && files_present(b))
    # AND THE FIRST SET WAS NOT TOUCHED. Same analysis both times, so the two
    # sets must be byte-identical; a difference would mean the second call
    # rewrote the first.
    f1 <- file.path(ap, "twice_tidy.csv"); f2 <- file.path(ap, "twice_1_tidy.csv")
    if (file.exists(f1) && file.exists(f2)) {
        check_true("v50", "collide: the first set was not overwritten",
                   identical(readLines(f1, warn = FALSE),
                             readLines(f2, warn = FALSE)))
    }
}

# ---------------------------------------------------------------------------
# 7. THE BATCH PATTERN: each analysis refills, it does not accumulate
# ---------------------------------------------------------------------------
lo <- read_leg("loop")
if (check_true("v50", "loop: the exporter reported once per column",
               length(lo) == 2)) {
    for (i in seq_along(lo)) {
        r <- lo[[i]]
        check("v50", sprintf("loop/%s: five frames", r$phase),
              5, num(r, "nWritten"), tol = 0)
        check_true("v50", sprintf("loop/%s: every named frame is on disk", r$phase),
                   files_present(r))
    }
    # NO WALKED BASE. Each column exports under its own name, so nothing
    # should have collided -- a _1_ here would mean two columns wrote to one
    # base, which is the bug the documented loop exists to steer round.
    check_true("v50", "loop: neither column collided with the other",
               !any(grepl("^loop_.*_1_tidy\\.csv$", man$name)))
    # AND THE SECOND EXPORT DESCRIBES THE SECOND COLUMN. The collectors are
    # refilled by each analysis; if they accumulated, or if the second
    # analysis's declaration failed, the second file would still be the first
    # column's numbers under the second column's name -- which is precisely the
    # failure mode documented for the LMM path.
    t1 <- file.path(ap, "loop_SPL_dB_tidy.csv")
    t2 <- file.path(ap, "loop_vibrato_rate_Hz_tidy.csv")
    if (file.exists(t1) && file.exists(t2)) {
        check_true("v50", "loop: the two exports are not the same numbers",
                   !identical(readLines(t1, warn = FALSE),
                              readLines(t2, warn = FALSE)))
    }
}

# ---------------------------------------------------------------------------
# 8. THE FRESH SESSION -- the case the dialogs cannot reach
# ---------------------------------------------------------------------------
# emlResult_declared is not 0 here, it is ABSENT: no orchestrator ran, so
# @emlCSVInit never ran either. The guard is written as nested ifs because
# Praat evaluates BOTH operands of `and` before applying it and would abort on
# the very case the guard exists for. This is the check for that.
fr <- read_leg("fresh")
if (check_true("v50", "fresh: the exporter reported once", length(fr) == 1)) {
    r <- fr[[1]]
    check("v50", "fresh: .declared is 0", 0, num(r, "declared"), tol = 0)
    check("v50", "fresh: .success is 0", 0, num(r, "success"), tol = 0)
    check("v50", "fresh: .nWritten is 0", 0, num(r, "nWritten"), tol = 0)
    check_true("v50", "fresh: .reason$ is \"empty\", not a write error",
               identical(r$reason, "empty"))
    check_true("v50", "fresh: .fileList$ names nothing", length(r$files) == 0)
    # THE PINNED WART. .actualPath$ is set on the legacy arm even when nothing
    # was written, so after an empty export it names a file that does not
    # exist. plugin/docs/API_EXPORT.md warns about it; it is asserted here so that a
    # future fix is noticed and the warning removed, rather than the document
    # quietly becoming wrong in the safe direction.
    check_true("v50",
               "fresh: .actualPath$ names a file that was NOT written (documented wart)",
               identical(r$actualPath, "nothing_declared.csv"))
}
check_true("v50", "fresh: no file was created by an empty export",
           !("nothing_declared.csv" %in% man$name))

# AND THE RUN SURVIVED IT. Abort is the failure this leg is about, and a leg
# that died would have no report at all -- so the marker is checked as well as
# the numbers.
flog <- file.path(ap, "fresh.log")
if (readable("v50", "fresh: the leg produced a log", flog)) {
    fl <- readLines(flog, warn = FALSE)
    check_true("v50", "fresh: the script ran to the end rather than aborting",
               any(fl == "APIEXPORT DONE leg=fresh"))
    check_true("v50", "fresh: Praat raised no error",
               !any(grepl("^Error", fl)))
}

# ---------------------------------------------------------------------------
# 9. THE FOLDER PRECONDITION -- asserted in the document, proven here
# ---------------------------------------------------------------------------
nf <- read_leg("nofolder")
if (check_true("v50", "nofolder: the leg reported", length(nf) == 1)) {
    r <- nf[[1]]
    check_true("v50", "nofolder: the export aborted", identical(r$aborted, "1"))
    # NOT MERELY WRONG -- GONE. Praat discards a procedure's locals when it
    # unwinds, so a caller who skipped createFolder: has no .success to test
    # and no .reason$ to read. The document says so; this is why it can.
    check_true("v50",
               "nofolder: the procedure's outputs are unreadable afterwards",
               identical(r$outputsReadable, "0"))
    check_true("v50", "nofolder: no frame was written",
               identical(r$tidyFileExists, "0"))
}

# AND THE SOURCE SAYS WHY. The document's claim is about the plugin, not about
# one run: the panel creates the folder and the exporter does not. Read out of
# eml-output.praat so that moving createFolder: into the exporter -- which
# would be a fine fix -- fails this file and the paragraph gets rewritten.
op <- file.path(plug, "stats", "eml-output.praat")
if (readable("v50", "the export source is readable", op)) {
    ol <- readLines(op, warn = FALSE)
    st <- grep("^procedure emlExportResultFiles", ol)
    en <- grep("^endproc\\s*$", ol)
    if (check_true("v50", "@emlExportResultFiles exists exactly once",
                   length(st) == 1)) {
        body <- ol[st:(en[en > st][1])]
        body <- body[!grepl("^\\s*[#;]", body)]
        check_true("v50",
                   "@emlExportResultFiles does not create the folder itself",
                   !any(grepl("createFolder", body, fixed = TRUE)))
    }
    sp <- grep("^procedure emlSavePanel", ol)
    if (check_true("v50", "@emlSavePanel exists exactly once", length(sp) == 1)) {
        pbody <- ol[sp:(en[en > sp][1])]
        pbody <- pbody[!grepl("^\\s*[#;]", pbody)]
        # THE PANEL STILL CREATES IT; IT NO LONGER DOES SO WITH A BARE LINE.
        # 15 August 2026, NEW-G12-5: `createFolder:` sitting bare in the panel
        # was the EARLIEST place a save could kill the session -- under an
        # unwritable parent it raises "Cannot create folder" inside
        # @emlSavePanel, before a single tickbox is honoured, so the receipt
        # never draws and the caller's post-analysis loop never runs again.
        # The creation moved into @eml_saveFolderWritable, which does it with
        # `nocheck` and then proves the result with a probe write. The
        # document's claim -- the panel creates the folder, the exporter does
        # not -- is unchanged and still what the plugin does; only the line it
        # is written on moved. Checked as "the panel is responsible", which is
        # what the paragraph actually asserts.
        check_true("v50", "@emlSavePanel does create it, which is the asymmetry",
                   any(grepl("createFolder:", pbody, fixed = TRUE)) ||
                   any(grepl("@eml_saveFolderWritable:", pbody, fixed = TRUE)))
    }
}

# ---------------------------------------------------------------------------
# 10. WHICH ORCHESTRATORS DECLARE -- the document against the source
# ---------------------------------------------------------------------------
# The fork is on the DECLARATION, so "which analyses give you broom frames" is
# the first thing a script author needs and the first thing that goes stale.
# The classification is derived from eml-analysis.praat and eml-lmm.praat --
# never from a list kept in this file, which could only ever agree with itself.
#
#   declares      body calls an @emlDeclare* procedure
#   legacy        body calls @emlCSVAdd* and does not declare
#   neither       body does neither, and must not be described as exportable
classify <- function(paths) {
    out <- list()
    for (p in paths) {
        if (!file.exists(p)) next
        x <- readLines(p, warn = FALSE)
        x <- x[!grepl("^\\s*[#;]", x)]
        st <- grep("^procedure\\s+emlRun", x)
        en <- grep("^endproc\\s*$", x)
        for (s in st) {
            e <- en[en > s][1]
            if (is.na(e)) next
            nm <- sub("^procedure\\s+([A-Za-z0-9_]+).*$", "\\1", x[s])
            b <- x[s:e]
            out[[nm]] <- if (any(grepl("@emlDeclare", b, fixed = TRUE))) {
                "declares"
            } else if (any(grepl("@emlCSVAdd", b, fixed = TRUE))) {
                "legacy"
            } else "neither"
        }
    }
    out
}
cls <- classify(c(file.path(plug, "stats", "eml-analysis.praat"),
                  file.path(plug, "stats", "eml-lmm.praat")))
check_true("v50", sprintf("the source has orchestrators to classify (%d)",
                          length(cls)),
           length(cls) >= 13)

docp <- file.path(docs, "API_EXPORT.md")
doc <- character(0)
if (readable("v50", "plugin/docs/API_EXPORT.md exists and has content", docp)) {
    doc <- readLines(docp, warn = FALSE)
}
check_true("v50", sprintf("the document has content (%d lines)", length(doc)),
           length(doc) > 80)

blob <- paste(doc, collapse = "\n")
for (nm in names(cls)) {
    check_true("v50", sprintf("the document names @%s (%s)", nm, cls[[nm]]),
               grepl(nm, blob, fixed = TRUE))
}
# AND IT PUTS THEM ON THE RIGHT SIDE. Naming an orchestrator is not enough --
# the harmful error is describing a legacy path as broom-shaped, which sends a
# reader looking for a _tidy.csv that will never be written. The declaring
# block of the document is delimited by its own headings and read as a unit.
h_decl <- grep("^\\*\\*These DECLARE\\*\\*", doc)
h_not  <- grep("^\\*\\*This one does NOT\\*\\*", doc)
if (check_true("v50", "the document has a DECLARE / does NOT split",
               length(h_decl) == 1 && length(h_not) == 1 && h_not > h_decl)) {
    declBlock <- paste(doc[h_decl:(h_not - 1)], collapse = "\n")
    notBlock  <- paste(doc[h_not:length(doc)], collapse = "\n")
    for (nm in names(cls)) {
        inDecl <- grepl(nm, declBlock, fixed = TRUE)
        if (identical(cls[[nm]], "declares")) {
            check_true("v50", sprintf("@%s is listed as declaring", nm), inDecl)
        } else {
            check_true("v50",
                       sprintf("@%s is NOT listed as declaring (it is %s)",
                               nm, cls[[nm]]),
                       !inDecl && grepl(nm, notBlock, fixed = TRUE))
        }
    }
}

# EVERY OUTPUT THE PROCEDURE SETS IS DESCRIBED. Read off the procedure's own
# header, which is the contract; an output the document omits is an output a
# script author will not know to check.
for (o in c(".declared", ".success", ".nWritten", ".fileList\\$",
            ".skipped\\$", ".actualPath\\$", ".reason\\$")) {
    check_true("v50", sprintf("the document describes %s",
                              gsub("\\\\", "", o)),
               grepl(o, blob))
}
# AND THE THREE VALUES OF .reason$, because "empty" is the one that reads as a
# failure and is not one.
for (o in c('"empty"', '"write"')) {
    check_true("v50", sprintf("the document names reason %s", o),
               grepl(o, blob, fixed = TRUE))
}

# ---------------------------------------------------------------------------
# 11. THE DOCUMENTED EXAMPLE IS THE SCRIPT THAT RAN
# ---------------------------------------------------------------------------
# The example in §3 is compared line by line against
# harness/api_export/doc_example.praat, which run.sh executes from a folder
# outside the plugin. Two lines are exempt and only two: the input path and the
# output path, which the harness substitutes and a user types for themselves.
# Blank lines are dropped from both sides -- markdown fences and Praat scripts
# do not agree about trailing whitespace, and the comparison is about the code.
exp <- Sys.getenv("EML_API_EXAMPLE", unset = "")
if (!nzchar(exp))
    exp <- repo_path(file.path("harness", "api_export", "doc_example.praat"))

norm <- function(v) {
    v <- trimws(v)
    v <- v[nzchar(v)]
    v[!grepl("^(inputFile\\$|outputFolder\\$)\\s*=", v)]
}

# ONLY A FENCED ```praat BLOCK IS A CANDIDATE, and the reason is that a naive
# walk over consecutive fence lines also walks the PROSE BETWEEN blocks -- the
# region from one closing fence to the next opening one is a pair like any
# other. Any sentence in that prose that quotes an include line inline then
# reads as the example, and the comparison below is against a paragraph.
fence <- grep("^```", doc)
docEx <- character(0)
for (i in seq_len(max(0, length(fence) - 1))) {
    if (!grepl("^```praat", doc[fence[i]])) next
    blk <- doc[(fence[i] + 1):(fence[i + 1] - 1)]
    if (any(grepl("include ~/.praat-dir/plugin_EML_StatsGraphs", blk,
                  fixed = TRUE))) { docEx <- blk; break }
}
if (check_true("v50", sprintf("the document carries a runnable example (%d lines)",
                              length(docEx)),
               length(docEx) > 20)) {
    hx <- character(0)
    if (readable("v50", "the harness copy of the example exists", exp)) {
        h <- readLines(exp, warn = FALSE)
        b <- grep("^# --- BEGIN DOCUMENTED BODY ---$", h)
        e <- grep("^# --- END DOCUMENTED BODY ---$", h)
        inc <- grep("^include ", h)
        if (check_true("v50", "the harness copy is marked up as expected",
                       length(b) == 1 && length(e) == 1 && length(inc) > 0)) {
            hx <- c(h[inc], h[(b + 1):(e - 1)])
        }
    }
    a <- norm(docEx); bb <- norm(hx)
    diffn <- if (length(a) == length(bb)) sum(a != bb) else NA_integer_
    check_true("v50",
               sprintf("the documented example is the script that ran (doc %d lines, harness %d, differing %s)",
                       length(a), length(bb),
                       if (is.na(diffn)) "n/a" else as.character(diffn)),
               length(a) > 0 && identical(a, bb))
}

# AND IT RAN. The example is the one leg whose failure a reader would meet
# first, so its log is read for the marker and for the values it printed.
elog <- file.path(ap, "example.log")
if (readable("v50", "the example produced a log", elog)) {
    el <- readLines(elog, warn = FALSE)
    check_true("v50", "example: the script ran to the end",
               any(el == "APIEXPORT DONE leg=example"))
    check_true("v50", "example: Praat raised no error",
               !any(grepl("^Error", el)))
    check_true("v50", "example: it reported declared = 1",
               any(grepl("^declared : 1$", trimws(el))))
    check_true("v50", "example: it reported five files written",
               any(grepl("^written  : 5$", trimws(el))))
}
exFrames <- man$name[grepl("^example\\.anova_by_voice_type_", man$name)]
check("v50", "example: five frames arrived under the documented base name",
      5L, length(exFrames), tol = 0)

# ---------------------------------------------------------------------------
# 12. COVERAGE ACCOUNTING
# ---------------------------------------------------------------------------
# Every leg in the artefact is asserted on by something above. The population
# is the leg list read off the manifest, not the one this file loops over, so a
# leg added to the harness and to nothing else surfaces as an orphan rather
# than passing silently -- the failure eml_census exists for.
eml_census("v50", "api_export leg",
           present = present_legs,
           accounted = c("declared", "collide", "partial", "loop", "legacy",
                         "fresh", "nofolder"))
eml_claim("v50", "api_export", c(present_legs, "example"))

if (!exists("EML_SUITE")) {
    eml_report("v50 api export: @emlExportResultFiles called as code, and documented")
    eml_exit()
}
