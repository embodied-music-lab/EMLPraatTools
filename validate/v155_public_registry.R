# ============================================================================
# v155_public_registry.R -- the public-surface registry against the tree
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS ENFORCES. mailbox/to-opus/RULING_PUBLIC_SURFACE_2026-09-01.md:
# a procedure is public if and only if it has a row in
# plugin_EML_StatsGraphs/REGISTRY.tsv. Reachability is not the test -- all
# 357+ procedures matching eml[A-Z]... are reachable the moment a script
# includes the tree, because Praat's `include` is a parse-time text paste.
# Membership is by INTENT, recorded in that one file, seeded by exactly three
# sources named in the ruling. This validator enforces the ruling's four
# named checks, each reported separately:
#
#   1. ROWS RESOLVE          every row names a real procedure, in the file
#                            it claims, with the signature it claims.
#   2. RECORDER CONTAINMENT  every procedure call stats/eml-record.praat can
#                            emit into a generated user script has a row.
#   3. GENERATION CHECK      docs / the barrel / Table S2 are meant to be
#                            GENERATED from the registry, with a text check
#                            that the generated artefacts match it. That
#                            generation does not exist yet. This check says
#                            so, honestly, rather than passing on an empty
#                            population -- the exact defect (a check that
#                            passes because there is nothing to check) that
#                            got a previous validator in this repo rejected.
#   4. EROSION               a procedure that presents itself as a
#                            user-facing entry point -- the emlRun* name
#                            pattern, or a graph-type dispatch branch -- but
#                            carries no registry row fails the suite.
#
# CHECK 2'S METHOD, and why it is a regex over source text rather than a
# call-graph walk. The registry cares about the literal TEXT a generated
# script ends up containing, not about what is reachable by calling.
# Every site in the recorder (and its callers) that assembles that text
# does so by concatenating a Praat string literal that opens
# `"@emlSomething` -- `.code$ = "@emlDrawViolinPlot: data, ...`,
# `.text$ = .text$ + "@emlInitDrawingDefaults" + newline$`, and so on -- so
# grep-ing every non-dev/ .praat file in the tree for the pattern
# `"@eml[A-Z]\w*` and reading off the name after the quote finds every site
# that assembles emittable text, by construction, with no procedure list to
# keep in sync by hand. dev/ (tests, tools, docs, the tutorial) is excluded
# because it quotes procedure names as prose and as test-section titles
# ("@emlTestSection: "@emlCronbachAlpha -- refusals""), never as code being
# assembled for a generated script.
#
# THREE NAMED FALSE POSITIVES survive that exclusion and are exempted below,
# each with the reason inline -- the same convention v107's EXEMPT list uses
# for commands that legitimately do not record. A name that regex-matches
# and is in neither the registry nor this exemption list is a NEW finding,
# not a silent pass: the check names it and fails.
#
# CHECK 4'S SOURCE-2 HALF only covers the graph-type dispatch table
# (@emlGraphsDispatchDraw's `graph_type = N` branches, the concrete
# mechanism the ruling's own memo discusses) plus the QQ door named by hand.
# It would NOT catch an entirely new kind of door -- a fresh top-level tool
# added to setup.praat that funnels through no dispatch table at all. That
# is a known limit of this check, stated here rather than left to be
# discovered later; source 1's half (every emlRun* name) has no such gap,
# because it re-derives the whole population from the tree every run.
#
# Base R only. Reads source; drives nothing.
# ============================================================================

V <- "v155"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

plug <- repo_path("plugin_EML_StatsGraphs")
registry_path <- file.path(plug, "REGISTRY.tsv")

# ----------------------------------------------------------------------------
# Load the registry. `#`-prefixed and blank lines are the header block;
# quote = "" because the description column carries literal double quotes
# (column names, ellipses, error-message fragments quoted verbatim) that are
# not CSV/TSV quoting.
# ----------------------------------------------------------------------------
ok_present <- check_true(V, "REGISTRY.tsv exists", file.exists(registry_path))
if (!ok_present) {
    if (!exists("EML_SUITE")) { eml_report("v155 -- the public registry"); eml_exit() }
}

raw_lines <- readLines(registry_path, warn = FALSE)
data_lines <- raw_lines[!grepl("^#", raw_lines) & nzchar(trimws(raw_lines))]
reg <- read.delim(text = paste(data_lines, collapse = "\n"),
                   stringsAsFactors = FALSE, quote = "",
                   colClasses = "character")

check_true(V, "registry has the five columns the ruling asks for",
           identical(names(reg), c("name", "file", "signature", "description", "sources")))
check_true(V, "registry has at least one row", nrow(reg) >= 1)
check_true(V, "registry names are unique (no duplicate procedure rows)",
           !any(duplicated(reg$name)))

reg_names <- reg$name

cat(sprintf("\n  REGISTRY.tsv: %d rows\n", nrow(reg)))
src_counts <- table(unlist(strsplit(reg$sources, ",")))
for (s in sort(names(src_counts))) {
    cat(sprintf("    source %s: %d rows\n", s, src_counts[[s]]))
}

# ============================================================================
# CHECK 1 -- ROWS RESOLVE
# ============================================================================
# Every row's (file, name) pair must exist, and the `procedure ...:` line it
# names must match the registry's `signature` column EXACTLY after
# whitespace normalisation (Praat's `...` continuation lines mean the same
# logical header can be split across lines with arbitrary indentation).

norm_ws <- function(s) trimws(gsub("\\s+", " ", s))

resolve_one <- function(name, file, signature) {
    path <- file.path(plug, file)
    if (!file.exists(path)) return(list(ok = FALSE, why = "file does not exist"))
    lines <- readLines(path, warn = FALSE)
    # A procedure header: `procedure NAME:` or bare `procedure NAME` at
    # (possibly indented) line start, not inside a comment. Praat continues
    # a long parameter list with `...` on following lines, so the header as
    # WRITTEN may span several source lines; joining a bounded run of them
    # and re-trimming is what makes a multi-line signature comparable to the
    # registry's single-line copy.
    hdr_pat <- paste0("^\\s*procedure\\s+", name, "\\s*(:|$)")
    hit <- which(grepl(hdr_pat, lines))
    if (length(hit) == 0L) return(list(ok = FALSE, why = "no `procedure` line found"))
    if (length(hit) > 1L) return(list(ok = FALSE,
        why = sprintf("defined %d times (lines %s)", length(hit),
                       paste(hit, collapse = ", "))))
    i <- hit[1]
    joined <- lines[i]
    j <- i + 1L
    while (j <= length(lines) && grepl("^\\s*\\.\\.\\.", lines[j])) {
        joined <- paste0(joined, " ", sub("^\\s*\\.\\.\\.\\s*", "", lines[j]))
        j <- j + 1L
    }
    got <- norm_ws(joined)
    want <- norm_ws(signature)
    if (!identical(got, want)) {
        return(list(ok = FALSE, why = sprintf(
            "signature mismatch at %s:%d\n        registry: %s\n        actual:   %s",
            file, i, want, got)))
    }
    list(ok = TRUE, why = "")
}

for (k in seq_len(nrow(reg))) {
    r <- reg[k, ]
    res <- resolve_one(r$name, r$file, r$signature)
    check_true(V, sprintf("[resolve] %s (%s)", r$name, r$file), res$ok)
    if (!res$ok) cat(sprintf("      %s: %s\n", r$name, res$why))
}

# ============================================================================
# CHECK 2 -- RECORDER CONTAINMENT
# ============================================================================
plugin_files <- list.files(plug, pattern = "\\.praat$", recursive = TRUE,
                            full.names = TRUE)
# Exclude dev/ (tests, tools, docs, tutorial): procedure names there are
# quoted as prose and as test-section titles, never assembled as code
# destined for a generated script. Also exclude sprites/ and anything under
# a build/out scratch tree that might have been left beside the source
# (none expected; the filter is defensive).
rel <- sub(paste0("^", plug, "/?"), "", plugin_files)
# scripts/eml-quick-start.praat prints a cheat sheet of procedure names to
# the Info window (`appendInfoLine: "       @emlTTest: group1#, group2#..."`)
# for a human to read -- it is a tutorial, not part of the recorder
# pipeline, and contributes nine names to a naive scan (emlTTest,
# emlMannWhitneyU, emlSpearmanCorrelation, emlKruskalWallis,
# emlPairwiseWilcoxon, emlMatchedPairsR, emlScheffe, emlBenjaminiHochberg,
# emlFormatP) that a generated script never contains. Excluded by file
# rather than by nine separate name exemptions, since every match in it is
# the same kind of false positive for the same reason.
scan_files <- plugin_files[!grepl("^dev/", rel) &
                            rel != "scripts/eml-quick-start.praat"]

# Named false positives: the naive scan finds these because a Praat string
# literal happens to open `"@emlSomething`, but in each case the string is
# never the text a generated script ends up containing. See the header
# comment above CHECK 2 for the general rule; the reason for each name is
# inline here so it can be re-verified against the cited line.
EXEMPT <- c(
    emlSavePanel = paste(
        "stats/eml-output.praat:~4438 records the INTERACTIVE call as the",
        "step's raw code, and stats/eml-record.praat's emlRecordRender",
        "unconditionally rewrites every \"save\"-kind step from",
        "\"@emlSavePanel:\" to \"@emlRecordReplaySave:\" before emission",
        "(the replace$ call ~line 5312). The literal text \"@emlSavePanel:\"",
        "therefore never reaches a generated script; @emlRecordReplaySave",
        "is the one that does, and it has its own row."),
    emlAugmentFrom = paste(
        "stats/eml-result-writer.praat ~line 394: the match is inside an",
        "exitScript: developer error message inside @emlAugmentNum",
        "(\"... called before @emlAugmentFrom.\"), not code assembled for",
        "emission. @emlAugmentFrom is never itself recorder-emitted."),
    emlRenderResultSettings = paste(
        "stats/eml-output.praat ~line 1090: the match is inside the",
        "procedure's OWN .error$ self-diagnostic (\"@emlRenderResultSettings",
        "does not render '<kind>'\"), not code assembled for emission.")
)

# LEADING WHITESPACE INSIDE THE STRING, ALLOWED. A step's own indentation
# is baked into the literal -- @emlDrawAnnotations and @emlDrawAnnotationBlock
# are both emitted as `"    @emlDrawAnnotations: ..."` (four literal spaces,
# so the generated script indents the call inside its `if` block). A pattern
# requiring the quote to butt directly against `@eml` missed both on the
# first pass of writing this check; `\\s*` is why it does not miss them now.
pat <- "\"\\s*@eml([A-Z][A-Za-z0-9_]*)"
hits <- list()  # name -> character vector of "file:line"
for (f in scan_files) {
    lines <- tryCatch(readLines(f, warn = FALSE), error = function(e) character(0))
    for (i in seq_along(lines)) {
        m <- gregexpr(pat, lines[i])[[1]]
        if (m[1] == -1L) next
        caps <- regmatches(lines[i], m)
        for (cap in caps) {
            name <- sub("^\"\\s*@", "", cap)
            frel <- sub(paste0("^", plug, "/?"), "", f)
            hits[[name]] <- c(hits[[name]], sprintf("%s:%d", frel, i))
        }
    }
}

emitted_names <- setdiff(names(hits), names(EXEMPT))

for (nm in names(EXEMPT)) {
    attest(V, sprintf("exempted from source-3 scan: %s", nm), EXEMPT[[nm]])
}

not_registered <- setdiff(emitted_names, reg_names)
check_true(V,
           sprintf("every recorder-emittable call name has a registry row%s",
                   if (length(not_registered))
                       paste0(" -- NEW, unregistered: ",
                              paste(not_registered, collapse = ", "))
                   else ""),
           length(not_registered) == 0L)
if (length(not_registered)) {
    for (nm in not_registered) {
        cat(sprintf("      %s found at: %s\n", nm,
                     paste(hits[[nm]], collapse = "; ")))
    }
}

check_true(V,
           sprintf("recorder-emittable names found: %d (source-3 rows in registry: %d)",
                   length(emitted_names), sum(grepl("3", reg$sources))),
           length(emitted_names) >= 1L)

# ============================================================================
# CHECK 3 -- GENERATION CHECK
# ============================================================================
# The ruling's mechanism item 3: docs, the barrel, and Table S2 are meant to
# be GENERATED from this registry, with a text check that the generated
# artefacts match it. None of that exists yet, and this check says so
# honestly -- attested, and named individually -- rather than reporting a
# pass on a population of zero artefacts, which is indistinguishable from a
# working generator without the sentence below.
attest(V,
       "docs generated from REGISTRY.tsv: NOT WIRED",
       "No script renders docs/API_EXPORT.md, docs/RECIPES.md or any other doc from REGISTRY.tsv; both are hand-maintained prose today. No generator to check the output of exists.")
attest(V,
       "the barrel generated from REGISTRY.tsv: NOT WIRED",
       "setup.praat's eml-lib-user.praat barrel is generated from the hand-maintained emlSetupModule$[] table (setup.praat ~line 397), which lists FILES to include, not procedures to call -- it is not derived from REGISTRY.tsv and nothing checks that it could be.")
attest(V,
       "Table S2 generated from REGISTRY.tsv: NOT WIRED, AND NO SUCH FILE EXISTS",
       "Table S2 is referenced only in mailbox/ correspondence (MEMO_PUBLIC_SURFACE_UNDEFINED_2026-09-01.md, the ruling answering it) as a future manuscript supplementary table keyed to the canonical names Ian has not yet accepted (ruling section 3). No file plays that role in this repository today, generated or otherwise.")
check_true(V,
           "generation check reports its true state: NOTHING is generated from REGISTRY.tsv yet (see the three attestations above)",
           TRUE)

# ============================================================================
# CHECK 4 -- EROSION
# ============================================================================
# A procedure that presents itself as a user-facing entry point but carries
# no registry row must fail the suite. Two halves, matching the ruling's two
# named triggers.

# ---- 4a. every emlRun* procedure anywhere in the tree, re-derived fresh ---
proc_pat <- "^\\s*procedure\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*(:|$)"
all_procs <- character(0)
for (f in plugin_files) {
    lines <- tryCatch(readLines(f, warn = FALSE), error = function(e) character(0))
    keep <- grepl(proc_pat, lines) &
            !grepl("^\\s*[#;]", lines)
    if (any(keep)) {
        # sub() with \\1 replaces only the MATCHED prefix and leaves
        # whatever follows it (the rest of the parameter list) glued on --
        # ".*$" has to be part of the pattern so the whole line is consumed
        # and only the captured name survives.
        nm <- sub(paste0(proc_pat, ".*$"), "\\1", lines[keep])
        all_procs <- c(all_procs, nm)
    }
}
all_procs <- unique(all_procs)
run_pattern_procs <- grep("^emlRun[A-Z]", all_procs, value = TRUE)

missing_run <- setdiff(run_pattern_procs, reg_names)
check_true(V,
           sprintf("every emlRun* procedure in the tree has a registry row (found %d)%s",
                   length(run_pattern_procs),
                   if (length(missing_run))
                       paste0(" -- MISSING: ", paste(missing_run, collapse = ", "))
                   else ""),
           length(missing_run) == 0L)

# ---- 4b. every branch of the graph-type dispatch table -------------------
# @emlGraphsDispatchDraw (graphs/eml-graphs-form.praat) is the one place
# EML Graphs' "graph_type" chooser turns a user's menu/wizard choice into a
# draw call; a graph type added there without a registry row is exactly the
# erosion the ruling names. emlDrawQQPlot is added by hand: it is a second,
# separate door (the normality check and the wizard draw it directly, never
# through this dispatch table) and would not appear in this scan.
form_path <- file.path(plug, "graphs", "eml-graphs-form.praat")
dispatch_targets <- character(0)
if (file.exists(form_path)) {
    fl <- readLines(form_path, warn = FALSE)
    start <- which(grepl("^procedure emlGraphsDispatchDraw\\b", fl))
    if (length(start) == 1L) {
        endp <- which(grepl("^endproc", fl))
        stop_at <- endp[endp > start][1]
        body <- fl[start:stop_at]
        # CODE ONLY. The procedure's own header comments (and one line
        # inside the body) discuss @emlDrawLegend / @emlDrawLegendPanel in
        # prose while explaining a DIFFERENT call path entirely (the legend
        # is drawn from inside each @emlDraw* procedure, not dispatched
        # here) -- a bare `@name` regex with no quote requirement, unlike
        # CHECK 2's, would pick up a comment mention as if it were a call.
        # Dropping every line whose trimmed text opens with `;` or `#`
        # keeps this to the actual `@emlDrawXxx: ...` dispatch statements.
        code_body <- body[!grepl("^\\s*[#;]", body)]
        m <- gregexpr("@emlDraw[A-Za-z0-9_]+", code_body)
        caps <- unlist(regmatches(code_body, m))
        dispatch_targets <- unique(sub("^@", "", caps))
    }
}
check_true(V, "@emlGraphsDispatchDraw was found and parsed",
           length(dispatch_targets) > 0L)

known_secondary_doors <- c("emlDrawQQPlot")
draw_doors <- union(dispatch_targets, known_secondary_doors)
missing_draw <- setdiff(draw_doors, reg_names)
check_true(V,
           sprintf("every graph-type dispatch target (+ known secondary doors) has a registry row (found %d)%s",
                   length(draw_doors),
                   if (length(missing_draw))
                       paste0(" -- MISSING: ", paste(missing_draw, collapse = ", "))
                   else ""),
           length(missing_draw) == 0L)

attest(V,
       "erosion check's source-2 half is scoped to the graph-type dispatch table",
       "A brand-new top-level door that funnels through no dispatch table (not a graph_type branch, not an emlRun* name) would not be caught by this check. See the file header.")

attest(V,
       "erosion check demonstrated: temporarily deleting a registry row made this exact check fail, restoring the row made it pass again, and the restored file was confirmed byte-identical to the original (sha256)",
       "Demonstrated by hand during authoring, 2026-09-01: emlRunPairedAnalysis's row removed, `Rscript validate/v155_public_registry.R` run and observed to FAIL check 4a naming it, the row restored verbatim, re-run observed to PASS, and `sha256sum` before/after matched. Not re-run automatically on every suite pass because doing so would mean this file mutating REGISTRY.tsv on disk as a side effect of validation, which is worse than the property it would be proving.")

if (!exists("EML_SUITE")) { eml_report("v155 -- the public registry"); eml_exit() }
