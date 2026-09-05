# ============================================================================
# v134 — the error-read lint (punch list item 9.2)
# ============================================================================
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
# THE RULE, ruled in full 25 Aug 2026 (Lane 9 / ERROR_CENSUS_2026-08-25.md):
#
#   A CALL TO AN ERROR-PRODUCING PROCEDURE MUST BE FOLLOWED BY A READ OF THAT
#   CALL'S .error$ BEFORE ANY NUMERIC OUTPUT OF THE SAME CALL IS USED.
#
# WHY. The census's headline finding is that callers check failure BY PROXY:
# they gate on a DERIVED count (`.n >= 3`, `.nGroups <> 2`) instead of reading
# `.error$`. The producers zero their numeric outputs on failure, so a real
# failure -- a bad column name, a non-numeric cell -- gets misreported as
# "too few observations" or "0 groups", with a plausible, WRONG, generic
# reason, while the producer's own error text is discarded. Fifteen of twenty
# unchecked sites in scripts/ do exactly this. A lint that accepted a proxy
# gate (reading `.n` but never `.error$`) as a pass would accept the defect it
# exists to catch -- so the rule is stated on `.error$` specifically, not on
# "some check happened".
#
# ---------------------------------------------------------------------------
# THE TWO POPULATIONS, DERIVED FROM THE TREE, NOT ASSERTED
# ---------------------------------------------------------------------------
# Population 1 -- error-producing procedures: every `procedure NAME: ...`
# whose own body assigns its local `.error$` (anchored at the start of a
# statement, so `.error$ = ""` and `.error$ = someCall.error$` both count,
# and `if .error$ <> ""` -- a READ -- does not). This is exactly what the
# Outputs: header convention documents by hand throughout stats/*.praat; the
# lint re-derives it from the body instead of trusting the comment.
#
# Population 2 -- call sites: every `@NAME: ...` / `call NAME` where NAME is
# in population 1. Of those, the ones this check actually AUDITS are the
# subset whose caller goes on to read some OTHER field of that same call
# (`NAME.result`, `NAME.n`, `NAME.nGroups$`, ...) -- a call whose output is
# never touched has nothing to check by proxy or otherwise, and is reported
# separately rather than padding either population.
#
# The census (docs/ERROR_CENSUS_2026-08-25.md, docs/error-census/*.tsv) is
# the SEED AND CALIBRATION for these counts, not the source of them -- this
# file rebuilds both populations from the tree itself, mechanically, every
# run. A wide gap from the census's 182 producers / 247 call sites is a
# finding worth reporting on its own, not something to force into agreement.
#
# ---------------------------------------------------------------------------
# WHAT "READ BEFORE USE" MEANS, MECHANICALLY
# ---------------------------------------------------------------------------
# For each audited call site the scope searched runs from the line after the
# call to the end of the enclosing procedure (or, for a call made in a
# script's main body, to the end of the file) -- the same boundary v113 uses
# for a dialog's cancel path, because it is the same fact: a procedure ends,
# or the next call to the SAME producer starts a new output cycle and ends
# this one's relevance first.
#
# Within that scope: the first line (if any) that reads `NAME.error$` and the
# first line (if any) that reads any other `NAME.<field>` are located. Three
# outcomes:
#   OK                the error read comes at or before the first field read.
#   UNCHECKED         a field is read; `.error$` is never read in scope.
#   USED-BEFORE-CHECK a field is read; `.error$` IS read, but only later.
# All three outcomes are text-only, order-only. It is not branch-aware (v113
# is, for the escape hatch, because a MISSED read there is silent data
# corruption; here a checked-late or checked-on-a-different-branch site is
# still a defect worth a human's eyes, so erring toward reporting is the
# right conservatism and a plain top-to-bottom read gets there without
# needing the branch machinery this lint does not otherwise require).
#
# ---------------------------------------------------------------------------
# PROVABLY-CANNOT-FAIL SITES
# ---------------------------------------------------------------------------
# A call site can be adjudicated exempt when reaching that call with a failed
# .error$ is provably impossible on that path (the census's NOT-APPLICABLE
# verdict). The exemption is carried in TWO PLACES, and both must agree:
#   1. EXEMPT_SITES below -- keyed on file + callee + the call's own source
#      text, never on a line number, so an edit above the site does not
#      silently invalidate or misfile the pin.
#   2. A comment carrying the literal marker ERROR-READ EXEMPT, written IN
#      THE PRAAT SOURCE within the 20 lines above the call, stating the
#      reason. The list here only names WHICH site; the reason lives at the
#      site, so a reader who has seen nothing but the .praat file still gets
#      the argument.
# A site whose marker is missing, or whose text no longer matches a real
# violation, reds this check -- the pin cannot silently rot in either
# direction, and it can only ever shrink (KNOWN_EXEMPT_CEILING, below).
#
# ---------------------------------------------------------------------------
# THE VACUITY KIT (v113 is the model)
# ---------------------------------------------------------------------------
#   1. The v98 import (index_procedures / CALL_RE / plugin_files) is asserted
#      complete before first use.
#   2. The derived producer count clears a floor -- a resolver that found
#      nothing would make every other gate pass by having nothing to check.
#   3. THE GATE: at least one call site was AUDITED (output actually used).
#      Zero audited sites is this check's own failure mode, named and red.
#   4. A seeded violation -- a real producer, called and its `.result` read
#      with no `.error$` in between, appended to a COPY of the tree via the
#      same EML_DIALOG_SRC door v98/v113 use -- goes red through this same
#      code, and the identical text in the real tree does not exist there.
#
# Base R only. No packages.
# ============================================================================

if (!exists("eml_report")) {
    .a <- commandArgs(FALSE); .f <- sub("^--file=", "", .a[grep("^--file=", .a)])
    source(file.path(if (length(.f)) dirname(normalizePath(.f)) else ".", "helpers.R"))
}

V98_FILE <- repo_path("validate", "v98_field_names.R")
V98_IMPORTS <- c("index_procedures", "CALL_RE", "plugin_files")

V98 <- new.env(parent = globalenv())
for (.e in parse(V98_FILE)) {
    if (is.call(.e) && length(.e) >= 3L &&
        identical(as.character(.e[[1]]), "<-")) {
        .nm <- as.character(.e[[2]])
        if (length(.nm) == 1L && .nm %in% V98_IMPORTS) eval(.e, V98)
    }
}
V98_MISSING <- setdiff(V98_IMPORTS, ls(V98))

# Asserted here, before the first use -- see v113's identical note. A rename
# in v98 stops THIS check with a named message instead of aborting the whole
# suite from inside the first call to a function that no longer exists.
check_true("v134", "the v98 procedure-index / call-site machinery was imported, entire",
           length(V98_MISSING) == 0L)
if (length(V98_MISSING)) {
    cat("v98 NO LONGER DEFINES:", paste(V98_MISSING, collapse = ", "), "\n")
    cat("v134 cannot audit a call site without it; stopping here rather than\n")
    cat("aborting the suite from the first call site.\n")
    eml_report("v134")
    quit(save = "no", status = 0)
}

# ---------------------------------------------------------------------------
# Generic text helpers (v113 redefines these locally rather than importing
# them from v98; they are not the derivation v98 owns, so this file does the
# same rather than reaching for a third copy).
# ---------------------------------------------------------------------------
strip_literals <- function(s) gsub("\"[^\"]*\"", "\"\"", s)
is_comment <- function(s) grepl("^\\s*[#;]", s) || !nzchar(trimws(s))
escape_rx <- function(s) gsub("([.\\^$|()\\[\\]{}*+?])", "\\\\\\1", s, perl = TRUE)

# ---------------------------------------------------------------------------
# Population 1 -- error-producing procedures. Anchored at the start of a
# statement so a READ (`if .error$ <> ""`) never counts, and `==` is excluded
# so a comparison spelled with two equals signs is not mistaken for a write.
# ---------------------------------------------------------------------------
ERROR_ASSIGN_RE <- "^\\s*\\.error\\$\\s*=(?!=)"

is_producer <- function(p) {
    for (raw in p$lines) {
        if (is_comment(raw)) next
        if (grepl(ERROR_ASSIGN_RE, strip_literals(raw), perl = TRUE)) return(TRUE)
    }
    FALSE
}

derive_producers <- function(procs) {
    keep <- vapply(names(procs), function(nm) is_producer(procs[[nm]]), logical(1))
    names(procs)[keep]
}

# ---------------------------------------------------------------------------
# Population 2 -- call sites to a producer, with the scope each one's audit
# runs over already attached (end of the enclosing procedure, or end of file
# for a call made outside any indexed procedure -- a script's main body).
# ---------------------------------------------------------------------------
find_call_sites <- function(files, producers, procs) {
    by_file <- list()
    for (nm in names(procs)) {
        p <- procs[[nm]]
        by_file[[p$file]] <- c(by_file[[p$file]],
                               list(list(name = nm, first = p$first,
                                        last = p$first + length(p$lines) - 1L)))
    }
    sites <- list()
    for (f in files) {
        code <- readLines(f, warn = FALSE)
        ranges <- by_file[[f]]
        for (i in seq_along(code)) {
            raw <- code[i]
            if (is_comment(raw)) next
            st <- strip_literals(raw)
            m <- regmatches(st, regexec(V98$CALL_RE, st))[[1]]
            if (length(m) != 3L) next
            callee <- m[3]
            if (!(callee %in% producers)) next
            enc <- if (length(ranges))
                Filter(function(r) i >= r$first && i <= r$last, ranges)
            else list()
            scope_end <- if (length(enc)) enc[[1]]$last else length(code)
            enc_name  <- if (length(enc)) enc[[1]]$name else "<top-level>"
            # A call's arguments can continue onto following lines, each
            # marked with a leading "...". Those lines are still part of THIS
            # statement, not the post-call scope this site's audit reads --
            # folded into the site's own text (so two calls that share a head
            # line but differ only in a continued argument still get distinct
            # keys) and skipped over when the audited scope begins.
            full_text <- trimws(raw)
            k <- i + 1L
            while (k <= length(code) && grepl("^\\s*\\.\\.\\.", code[k])) {
                full_text <- paste(full_text, trimws(code[k]))
                k <- k + 1L
            }
            sites[[length(sites) + 1L]] <- list(
                file = f, line = i, callee = callee, text = full_text,
                proc = enc_name,
                scope_start = k, scope_end = scope_end)
        }
    }
    sites
}

# ---------------------------------------------------------------------------
# classify_site -- OK / UNCHECKED / USED-BEFORE-CHECK / NO-OUTPUT-USED, per
# the rule stated in the header. The scan stops early if the SAME producer is
# called again in scope: a second call starts a new output cycle and nothing
# after it can belong to the first call's audit.
# ---------------------------------------------------------------------------
classify_site <- function(site, code) {
    if (site$scope_start > site$scope_end)
        return(list(status = "NO-OUTPUT-USED", error_line = NA_integer_,
                    field_line = NA_integer_, fields = character(0)))
    cn <- escape_rx(site$callee)
    err_pat <- paste0("(^|[^A-Za-z0-9_.$])", cn, "\\.error\\$")
    fld_pat <- paste0("(^|[^A-Za-z0-9_.$])", cn,
                      "\\.(?!error\\$)[A-Za-z_][A-Za-z0-9_]*\\$?")
    err_line <- NA_integer_; fld_line <- NA_integer_; fields <- character(0)
    cap <- min(site$scope_end, site$line + 400L)
    for (j in seq(site$scope_start, cap)) {
        raw <- code[j]
        if (is_comment(raw)) next
        st <- strip_literals(raw)
        if (is.na(err_line) && grepl(err_pat, st, perl = TRUE)) err_line <- j
        mm <- regmatches(st, gregexpr(fld_pat, st, perl = TRUE))[[1]]
        if (length(mm)) {
            if (is.na(fld_line)) fld_line <- j
            fields <- c(fields, mm)
        }
        cm <- regmatches(st, regexec(V98$CALL_RE, st))[[1]]
        if (length(cm) == 3L && identical(cm[3], site$callee) && j > site$line)
            break
    }
    if (is.na(fld_line))
        return(list(status = "NO-OUTPUT-USED", error_line = err_line,
                    field_line = fld_line, fields = fields))
    if (is.na(err_line))
        return(list(status = "UNCHECKED", error_line = err_line,
                    field_line = fld_line, fields = fields))
    if (err_line <= fld_line)
        return(list(status = "OK", error_line = err_line,
                    field_line = fld_line, fields = fields))
    list(status = "USED-BEFORE-CHECK", error_line = err_line,
        field_line = fld_line, fields = fields)
}

# ---------------------------------------------------------------------------
# audit_files -- the whole check over any file set. The seeded demonstration
# runs through this same function.
# ---------------------------------------------------------------------------
audit_files <- function(files) {
    procs <- V98$index_procedures(files)
    producers <- derive_producers(procs)
    sites <- find_call_sites(files, producers, procs)
    code_cache <- new.env(parent = emptyenv())
    get_code <- function(f) {
        if (!exists(f, envir = code_cache, inherits = FALSE))
            assign(f, readLines(f, warn = FALSE), envir = code_cache)
        get(f, envir = code_cache, inherits = FALSE)
    }
    for (i in seq_along(sites))
        sites[[i]]$cls <- classify_site(sites[[i]], get_code(sites[[i]]$file))
    list(procs = procs, producers = producers, sites = sites)
}

# Keyed on file, enclosing procedure, callee and the call's own source text --
# never a line number, so an edit above the site does not silently misfile a
# pin (v113's rationale, identical here). The enclosing procedure name is
# what tells apart two calls whose head line reads identically because their
# arguments differ only on a continuation line below it.
site_key <- function(s) sprintf("%s|%s|%s|%s", basename(s$file), s$proc,
                                s$callee, s$text)

audited     <- function(a) Filter(function(s) s$cls$status != "NO-OUTPUT-USED", a$sites)
violating   <- function(a) Filter(function(s) s$cls$status %in%
                                  c("UNCHECKED", "USED-BEFORE-CHECK"), a$sites)

# ---------------------------------------------------------------------------
# THE TEACHING MESSAGE.
# ---------------------------------------------------------------------------
teach <- function(s) {
    sprintf(paste0(
"%s:%d  @%s -- %s\n",
"  %s\n",
"  Rule: a call to an error-producing procedure must be followed by a read\n",
"        of its .error$ before any numeric output of that call is used.\n",
"  Fix:  read %s.error$ (or propagate it into your own .error$) before using\n",
"        %s\n"),
        basename(s$file), s$line, s$callee, s$text,
        switch(s$cls$status,
              "UNCHECKED" = sprintf("never reads %s.error$; uses %s at line %d",
                                    s$callee, s$cls$fields[1], s$cls$field_line),
              "USED-BEFORE-CHECK" = sprintf(
                  "uses %s at line %d, BEFORE reading %s.error$ at line %d",
                  s$cls$fields[1], s$cls$field_line, s$callee, s$cls$error_line)),
        s$callee, s$cls$fields[1])
}

# ===========================================================================
# THE SHIPPED TREE
# ===========================================================================
shipped <- audit_files(V98$plugin_files())

cat(sprintf(
"v134: population 1 -- %d procedures error-producing (of %d procedures indexed).\n",
    length(shipped$producers), length(shipped$procs)))
cat(sprintf(
"v134: population 2 -- %d call sites to a producer; %d of those go on to use a\n",
    length(shipped$sites), length(audited(shipped))))
cat("v134: numeric output of that call, and are the ones this check audits.\n")

tbl <- table(vapply(shipped$sites, function(s) s$cls$status, character(1)))
for (nm in names(tbl)) cat(sprintf("v134:   %-18s %d\n", nm, tbl[[nm]]))

# ---------------------------------------------------------------------------
# GATE -- the import (asserted above, at point of use) and the producer floor.
# The census counted 182 by per-row human read across every module; this
# derivation is a stricter, mechanical, single rule -- a procedure counts only
# when ITS OWN body assigns its local .error$ -- and lands at roughly half
# that (measured: 93 of 630 procedures indexed). That gap is reported here
# rather than forced into agreement (the punch list names this as an
# acceptable, worth-reporting outcome): the floor below guards against the
# scanner finding nothing, not against disagreeing with the census's broader
# human judgment call.
# ---------------------------------------------------------------------------
check_true("v134",
           sprintf("at least 50 error-producing procedures were derived (%d; census counted 182 by a broader, per-row human read -- see the note above this gate)",
                   length(shipped$producers)),
           length(shipped$producers) >= 50L)

# ---------------------------------------------------------------------------
# THE GATE NAMED IN THE PUNCH LIST: a check that examined zero call sites
# passes vacuously. Reported and asserted, not just asserted.
# ---------------------------------------------------------------------------
check_true("v134",
           sprintf("at least one call site was audited (output actually used): %d audited of %d calls to a producer",
                   length(audited(shipped)), length(shipped$sites)),
           length(audited(shipped)) > 0L)

# ===========================================================================
# PROVABLY-CANNOT-FAIL SITES -- committed, adjudicated, counted, shrink-only.
# The reason for each is written IN THE PRAAT SOURCE, at the site (the marker
# "ERROR-READ EXEMPT" in a comment within 20 lines above the call) -- this
# list only says WHICH site, never WHY.
# ---------------------------------------------------------------------------
EXEMPT_SITES <- c(
    "eml-analysis.praat|emlExtractConditionMatrix|emlAuditColumn|@emlAuditColumn: .tableId, .colLabel$ [.j]",
    "eml-analysis.praat|emlRMPostHoc|emlBenjaminiHochberg|@emlBenjaminiHochberg: .rawP#",
    "eml-analysis.praat|emlRMPostHoc|emlBonferroni|@emlBonferroni: .rawP#",
    "eml-analysis.praat|emlRMPostHoc|emlHolm|@emlHolm: .rawP#",
    # RESTORED 2026-09-05, RULING_CLUSTER_CLAUSE_SCOPED_2026-09-04: a
    # fix-cluster site comes out unless the accepted triage table dispositions
    # that exact site SAFE with a written mechanism. These five do (the
    # .nBlankRows argument at eml-analysis.praat:120,534,957,1268,1826,
    # unchanged since the table was written), so they stay adjudicated
    # exempt while the other 20 countGroups FIX sites are fixed
    # (Gate A4 cluster 2, ORDER_A4_CLUSTER2_COUNTGROUPS_2026-09-05).
    "eml-analysis.praat|emlRunTwoGroupAnalysis|emlCountGroups|@emlCountGroups: .tableId, .groupCol$",
    "eml-analysis.praat|emlRunAnovaAnalysis|emlCountGroups|@emlCountGroups: .tableId, .groupCol$",
    "eml-analysis.praat|emlRunKruskalWallisAnalysis|emlCountGroups|@emlCountGroups: .tableId, .groupCol$",
    "eml-analysis.praat|emlRunPairwiseAnalysis|emlCountGroups|@emlCountGroups: .tableId, .groupCol$",
    "eml-analysis.praat|emlReportPairwiseDescriptives|emlCountGroups|@emlCountGroups: .tableId, .groupCol$",
    "eml-analysis.praat|emlRunNormalityAnalysis|emlShapiroWilk|@emlShapiroWilk: .data#",
    "eml-analysis.praat|emlRunRepeatedMeasuresAnalysis|emlRMAnovaTest|@emlRMAnovaTest: .data##, .n, .k",
    "eml-anova-kernel.praat|emlAnovaKernelTwoWayPostHoc|emlBenjaminiHochberg|@emlBenjaminiHochberg: .rawP#",
    "eml-anova-kernel.praat|emlAnovaKernelTwoWayPostHoc|emlBonferroni|@emlBonferroni: .rawP#",
    "eml-anova-kernel.praat|emlAnovaKernelTwoWayPostHoc|emlHolm|@emlHolm: .rawP#",
    "eml-check-normality.praat|<top-level>|emlDrawQQPlot|@emlDrawQQPlot: qqData#, qqLabel$, 6, 4.5, \"color\", 1",
    "eml-check-normality.praat|<top-level>|emlShapiroWilk|@emlShapiroWilk: .data#",
    "eml-extract.praat|emlAnalysisFingerprint|eml_fpCompose|@eml_fpCompose: .tableId, 1, .columnList$, \"\"",
    "eml-extract.praat|emlDataFingerprint|eml_fpCompose|@eml_fpCompose: .tableId, 0, \"\", \"\"",
    "eml-extract.praat|emlExtractColumn|emlAuditColumn|@emlAuditColumn: .tableId, .columnName$",
    "eml-extract.praat|emlGroupFingerprint|eml_fpCompose|@eml_fpCompose: .tableId, 2, .dataCol$, .groupCol$",
    "eml-inferential.praat|emlDunnTest|emlBenjaminiHochberg|@emlBenjaminiHochberg: .rawP#",
    "eml-inferential.praat|emlDunnTest|emlBonferroni|@emlBonferroni: .rawP#",
    "eml-inferential.praat|emlDunnTest|emlHolm|@emlHolm: .rawP#",
    "eml-inferential.praat|emlPairwiseT|emlBenjaminiHochberg|@emlBenjaminiHochberg: .rawP#",
    "eml-inferential.praat|emlPairwiseT|emlBonferroni|@emlBonferroni: .rawP#",
    "eml-inferential.praat|emlPairwiseT|emlHolm|@emlHolm: .rawP#",
    "eml-inferential.praat|emlPairwiseWilcoxon|emlBenjaminiHochberg|@emlBenjaminiHochberg: .rawP#",
    "eml-inferential.praat|emlPairwiseWilcoxon|emlBonferroni|@emlBonferroni: .rawP#",
    "eml-inferential.praat|emlPairwiseWilcoxon|emlHolm|@emlHolm: .rawP#",
    "eml-studentized-range.praat|emlInvStudentizedRangeQ|emlStudentizedRangeQ|@emlStudentizedRangeQ: .qHi, .k, .df, .nranges",
    "eml-studentized-range.praat|emlInvStudentizedRangeQ|emlStudentizedRangeQ|@emlStudentizedRangeQ: .qMid, .k, .df, .nranges",
    "eml-wizard.praat|<top-level>|emlDrawQQPlot|@emlDrawQQPlot: wizNormQQData#, wizNormQQLabel$, 6, 4.5, \"color\", 1",
    "eml-wizard.praat|<top-level>|emlShapiroWilk|@emlShapiroWilk: wizNormGData#",
    # ADDED 2026-09-05, Gate A4 wave 1 remainder (ORDER_LANES_2026-09-05):
    # the LMM module's only wizard entry point (label D_LMM_FORMULA in
    # scripts/eml-wizard.praat) has no live `goto` reaching it from the
    # active dispatch -- the file's own comments say outright the label
    # has no user-reachable entry, and no other caller in the plugin
    # reaches emlLMM/emlBOBYQA/emlNelderMead/emlParseFormula/
    # emlCholeskySolve. Matches RULING_REGISTRY_VERDICTS_2026-09-01 SS1
    # ("menu and wizard doors withdrawn; public post-1.0"), same
    # disposition and reasoning as the triage table's row for each of
    # these 13 keys (19 physical call sites; six pairs of the
    # emlNelderMead keys below each cover two call sites sharing
    # identical literal text within the same procedure).
    "eml-lmm.praat|emlBootstrapCI|emlLMM|@emlLMM: .bootTable, .formula$, .contrastCoding$, .useREML, 5000",
    "eml-lmm.praat|emlLMM|emlBOBYQA|@emlBOBYQA: \"emlProfiledDeviance\", .thetaInit#, ... emlRandomEffectsZ.thetaLower#, .thetaUpper#, ... .rhoBeg, .rhoEnd, .maxIter, .npt",
    "eml-lmm.praat|emlLikelihoodRatioTest|emlCholeskySolve|@emlCholeskySolve: .xtx##, .xty#",
    "eml-lmm.praat|emlLikelihoodRatioTest|emlLMM|@emlLMM: .tableId, .formulaFull$, .contrastCoding$, 0, 10000",
    "eml-lmm.praat|emlLikelihoodRatioTest|emlLMM|@emlLMM: .tableId, .formulaReduced$, .contrastCoding$, 0, 10000",
    "eml-lmm.praat|emlLikelihoodRatioTest|emlParseFormula|@emlParseFormula: .formulaReduced$",
    "eml-lmm.praat|emlProfileCI|emlBOBYQA|@emlBOBYQA: \"emlProfiledDeviance\", .thetaML#, ... emlRandomEffectsZ.thetaLower#, .thetaUpper#, ... 0.1, 1e-6, 2000, 0",
    "eml-lmm.praat|emlProfileCI|emlNelderMead|@emlNelderMead: \"emlProfileObjSig01\", .wsPoint#, ... .innerLower#, .innerUpper#, 1e-6, 200",
    "eml-lmm.praat|emlProfileCI|emlNelderMead|@emlNelderMead: \"emlProfileObjSig01\", .wsPoint#, ... .innerLower#, .innerUpper#, 1e-6, 300",
    "eml-lmm.praat|emlProfileCI|emlNelderMead|@emlNelderMead: \"emlProfileObjSigma\", .wsTheta#, ... .thetaLowerAll#, .thetaUpperAll#, 1e-6, 200",
    "eml-lmm.praat|emlProfileCI|emlNelderMead|@emlNelderMead: \"emlProfileObjSigma\", .wsTheta#, ... .thetaLowerAll#, .thetaUpperAll#, 1e-6, 300",
    "eml-lmm.praat|emlProfileCI|emlNelderMead|@emlNelderMead: \"emlProfileObjSv\", .wsPoint#, ... .innerLower#, .innerUpper#, 1e-6, 200",
    "eml-lmm.praat|emlProfileCI|emlNelderMead|@emlNelderMead: \"emlProfileObjSv\", .wsPoint#, ... .innerLower#, .innerUpper#, 1e-6, 300"
)
# 34 -> 33 on 2026-09-03 with the countGroups leak's removal, then 33 -> 28 the
# same day with the re-audit ordered by the same ruling (the other five
# emlCountGroups pins, individually triage-SAFE, still belonged to a named FIX
# cluster and came out). 28 -> 33 on 2026-09-05, RULING_CLUSTER_CLAUSE_SCOPED_
# 2026-09-04, restoring those same five now that the rest of the countGroups
# cluster is fixed out from under them (Gate A4 cluster 2). 33 -> 46 later the
# same day, Gate A4 wave 1 remainder (ORDER_LANES_2026-09-05): the 13
# eml-lmm.praat keys above, all SAFE by the same severed-door reasoning,
# while every other remaining FIX-disposition row in the triage table (20
# sites across 6 other files) was fixed in code instead of pinned. The
# ceiling FOLLOWS the list, in whichever direction it moves: a ceiling left
# above the list is room for the next wrong pin to fit without tripping
# anything.
KNOWN_EXEMPT_CEILING <- 46L

has_exempt_marker <- function(s, code) {
    lo <- max(1L, s$line - 20L)
    any(grepl("ERROR-READ EXEMPT", code[lo:s$line], fixed = TRUE))
}

viol_now  <- violating(shipped)
found_keys <- vapply(viol_now, site_key, character(1))
new_reads  <- sort(setdiff(found_keys, EXEMPT_SITES))
gone       <- sort(setdiff(EXEMPT_SITES, found_keys))

# Every pinned site must still carry its marker in the source, keyed the same
# way the census/production code reads it.
code_cache2 <- new.env(parent = emptyenv())
get_code2 <- function(f) {
    if (!exists(f, envir = code_cache2, inherits = FALSE))
        assign(f, readLines(f, warn = FALSE), envir = code_cache2)
    get(f, envir = code_cache2, inherits = FALSE)
}
marker_missing <- character(0)
for (s in viol_now) {
    k <- site_key(s)
    if (k %in% EXEMPT_SITES && !has_exempt_marker(s, get_code2(s$file)))
        marker_missing <- c(marker_missing, sprintf("%s (%s:%d)", k, basename(s$file), s$line))
}

if (length(viol_now)) {
    cat(sprintf("\nv134: %d violating call site(s) found (before exemptions):\n\n",
               length(viol_now)))
    for (s in viol_now) cat(teach(s), "\n")
}

if (length(new_reads)) {
    cat("v134: VIOLATIONS OUTSIDE THE EXEMPT SET (these must be fixed, not pinned):\n")
    cat(paste0("  ", new_reads, "\n"))
}
check_true("v134",
           sprintf("every violating call site is either fixed or in the adjudicated exempt set (%d unadjudicated of %d violating)",
                   length(new_reads), length(viol_now)),
           length(new_reads) == 0L)

if (length(gone)) {
    cat("v134: PINNED EXEMPT SITES THAT NO LONGER VIOLATE THE RULE -- remove from EXEMPT_SITES:\n")
    cat(paste0("  ", gone, "\n"))
}
check_true("v134",
           sprintf("the exempt set matches exactly what still needs it (%d pinned, %d still violate)",
                   length(EXEMPT_SITES), length(found_keys)),
           length(gone) == 0L)

if (length(marker_missing)) {
    cat("v134: PINNED EXEMPT SITES MISSING THEIR 'ERROR-READ EXEMPT' SOURCE MARKER:\n")
    cat(paste0("  ", marker_missing, "\n"))
}
check_true("v134",
           sprintf("every pinned exempt site carries its reason at the site (%d missing)",
                   length(marker_missing)),
           length(marker_missing) == 0L)

check_true("v134",
           sprintf("the exempt list has not grown past its known ceiling (%d pinned, ceiling %d)",
                   length(EXEMPT_SITES), KNOWN_EXEMPT_CEILING),
           length(EXEMPT_SITES) <= KNOWN_EXEMPT_CEILING)

cat(sprintf(
"\nv134: %d site(s) redden the lint today (unadjudicated, of %d audited call sites; %d pinned exempt).\n",
    length(new_reads), length(audited(shipped)), length(EXEMPT_SITES)))

# ===========================================================================
# THE SEEDED VIOLATION
# ===========================================================================
# A real producer (emlSkewness), called with its numeric output read and no
# .error$ read anywhere in between, appended to a COPY of the tree through
# the same EML_DIALOG_SRC door v98/v113 use. Nothing in the shipped tree is
# touched; the identical text is confirmed ABSENT from it below, so the
# demonstration proves the seed did the planting, not that the site already
# existed.
# ---------------------------------------------------------------------------
seed_root <- file.path(tempdir(), "v134_seeded_tree")
unlink(seed_root, recursive = TRUE)

src_files <- V98$plugin_files()
src_root  <- Sys.getenv("EML_DIALOG_SRC", unset = "")
if (!nzchar(src_root)) src_root <- repo_path("plugin_EML_StatsGraphs")
src_root  <- sub("/+$", "", src_root)
for (f in src_files) {
    rel <- sub(paste0("^", src_root, "/"), "", f)
    dst <- file.path(seed_root, rel)
    dir.create(dirname(dst), recursive = TRUE, showWarnings = FALSE)
    file.copy(f, dst, overwrite = TRUE)
}

seed_target <- file.path(seed_root, "scripts", "eml-check-normality.praat")
seed_ok <- FALSE
SEED_CALL_LINE  <- "    @emlSkewness: v134_seeded_vec#"
SEED_READ_LINE  <- "    v134_seeded_result = emlSkewness.result"
if (file.exists(seed_target)) {
    sl <- readLines(seed_target, warn = FALSE)
    sl <- c(sl, "", "; v134 SEEDED VIOLATION -- planted for the demonstration, not shipped.",
            SEED_CALL_LINE, SEED_READ_LINE)
    writeLines(sl, seed_target)
    seed_ok <- TRUE
}
check_true("v134", "the seeded violation was appended to the copied tree",
           seed_ok)

old_src <- Sys.getenv("EML_DIALOG_SRC", unset = NA)
Sys.setenv(EML_DIALOG_SRC = seed_root)
seeded <- audit_files(V98$plugin_files())
if (is.na(old_src)) Sys.unsetenv("EML_DIALOG_SRC") else
    Sys.setenv(EML_DIALOG_SRC = old_src)

check_true("v134", "EML_DIALOG_SRC pointed the same audit at the seeded copy",
           length(seeded$sites) == length(shipped$sites) + 1L)

seed_site <- Filter(function(s)
    basename(s$file) == "eml-check-normality.praat" &&
        identical(s$text, trimws(SEED_CALL_LINE)),
    seeded$sites)

if (length(seed_site) == 1L) {
    cat("\nv134: SEEDED VIOLATION, CAUGHT:\n\n")
    cat(teach(seed_site[[1]]), "\n")
}

check_true("v134",
           "the seeded call site is classified UNCHECKED",
           length(seed_site) == 1L &&
               identical(seed_site[[1]]$cls$status, "UNCHECKED"))

seed_key <- if (length(seed_site) == 1L) site_key(seed_site[[1]]) else NA_character_
check_true("v134",
           "the seeded violation is red and is not covered by the exempt set",
           !is.na(seed_key) && (seed_key %in% setdiff(
               vapply(violating(seeded), site_key, character(1)), EXEMPT_SITES)))

# The identical call+read pair must not already exist, unseeded, in the real
# tree -- otherwise the demonstration would prove nothing about the seed.
ship_same <- Filter(function(s)
    basename(s$file) == "eml-check-normality.praat" &&
        identical(s$text, trimws(SEED_CALL_LINE)),
    shipped$sites)
check_true("v134",
           "that exact call+read pair is absent from the shipped tree before seeding",
           length(ship_same) == 0L)

unlink(seed_root, recursive = TRUE)

if (!exists("EML_SUITE")) {
    eml_report("v134 the error-read lint"); eml_exit()
}
