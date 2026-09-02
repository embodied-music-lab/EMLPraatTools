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
#                            pattern, a graph-type dispatch branch, or a
#                            door registration in setup.praat (an ACTIVE
#                            `Add menu command:` / `Add action command:`
#                            line) -- but carries no registry row fails the
#                            suite. One documented exception: emlRun* names
#                            on the RUN_EXCLUSIONS list below, each carrying
#                            its own reason, are not erosion by decision.
#
# CHECK 2'S METHOD, and why it is a regex over source text rather than a
# call-graph walk. The registry cares about the literal TEXT a generated
# script ends up containing, not about what is reachable by calling.
# Every site in the recorder (and its callers) that assembles that text
# does so by concatenating a Praat string literal that opens
# `"@emlSomething` -- `.code$ = "@emlDrawViolinPlot: data, ...`,
# `.text$ = .text$ + "@emlInitializeDrawingDefaults" + newline$`, and so on -- so
# grep-ing every non-dev/ .praat file in the tree for the pattern
# `"@eml[A-Z]\w*` and reading off the name after the quote finds every site
# that assembles emittable text, by construction, with no procedure list to
# keep in sync by hand. dev/ (tests, tools, docs, the tutorial) is excluded
# because it quotes procedure names as prose and as test-section titles
# ("@emlTestSection: "@emlCronbachAlpha -- refusals""), never as code being
# assembled for a generated script.
#
# FOUR NAMED FALSE POSITIVES survive that exclusion and are exempted below,
# each with the reason inline -- the same convention v107's EXEMPT list uses
# for commands that legitimately do not record. A name that regex-matches
# and is in neither the registry nor this exemption list is a NEW finding,
# not a silent pass: the check names it and fails.
#
# CHECK 4'S SOURCE-2 HALF (4b) only covers the graph-type dispatch table
# (@emlGraphsDispatchDraw's `graph_type = N` branches, the concrete
# mechanism the ruling's own memo discusses) plus the QQ door named by hand.
# By itself it would NOT catch an entirely new kind of door -- a fresh
# top-level tool added to setup.praat that funnels through no dispatch
# table at all. That gap is closed by 4c below, which re-derives, from
# setup.praat itself, every ACTIVE `Add menu command:` / `Add action
# command:` line's target script and scans that script's own text for real
# @eml(Run|Draw)... call sites. 4c is a fresh-every-run derivation, like
# source 1's half, not a hand-kept list -- restoring emlDrawLMMForest's
# withdrawn menu entry (scripts/eml-lmm.praat, which calls it directly)
# would trip 4c the day the entry comes back, before anyone remembers to
# add a row. 4c's own honest limit: it scans only the file the door names
# DIRECTLY, one level, not files that script goes on to `include` -- a name
# introduced only inside a further include from a door script would not be
# caught. Source 1's half (every emlRun* name) has no comparable gap of any
# kind, because it re-derives the whole population from the tree every run
# with no notion of "one level" at all.
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
    emlRunReliabilityAnalysis = paste(
        "stats/eml-analysis.praat:4068 builds the literal",
        "\"@emlRunReliabilityAnalysis: data, ...\" as the .code$ argument to",
        "@emlRecordAnalysisStep, but the procedure sets .error$",
        "unconditionally (it is an unimplemented stub, v1.2 item 7) and",
        "@emlRecordAnalysisStep (stats/eml-record.praat ~line 1319) takes",
        "its \"if .error$ <> \"\" ... refusal ... goto END\" branch before",
        ".code$ is ever read whenever .error$ is non-empty -- which, here,",
        "is always. The .code$ literal is therefore dead text; the second",
        "grep hit for this name (eml-analysis.praat:4115) is prose in a",
        "comment, matching nothing this check's quote-anchored pattern",
        "would call a call. Removed from the registry by the same ruling",
        "(RUN_EXCLUSIONS above carries the full reason)."),
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

# EXPLICIT, DOCUMENTED EXCLUSION LIST -- the only way an emlRun* name may be
# absent from the registry without failing this check. Fable's ruling on
# emlRunReliabilityAnalysis: "Table S2 documents working public surface; an
# unconditional-error stub is not surface" -- so its row came out of
# REGISTRY.tsv. Left as a bare setdiff() that would have made removing the
# row silently defeat 4a, which is the opposite of what a check named
# EROSION is for. Adding a name here is therefore a deliberate, reviewable
# act: it must carry its own reason, inline, same convention as CHECK 2's
# EXEMPT list above -- and the two checks immediately below hold this list
# accountable rather than trusting it blind: an excluded name that is no
# longer an emlRun* procedure at all, or that no longer needs excluding
# because a row now covers it, is flagged rather than left to go stale.
RUN_EXCLUSIONS <- c(
    emlRunReliabilityAnalysis = paste(
        "Unimplemented stub (v1.2 item 7), stats/eml-analysis.praat:",
        "unconditionally sets .error$ and computes nothing; has no real",
        "call site anywhere in the plugin (the two other hits for this",
        "name are the recorder assembling call TEXT into a generated",
        "script, and a comment -- not calls). Excluded from",
        "REGISTRY.tsv by ruling (Fable, 2026-09-01: 'an unconditional-",
        "error stub is not surface') and excluded here from the erosion",
        "check for the same reason -- unimplemented; excluded until it",
        "works."),
    emlRunLMMAnalysis = paste(
        "Implemented and validated (stats/eml-lmm.praat), but its menu",
        "entry and the wizard's mixed-model page are both withdrawn -- no",
        "door reaches it today. Excluded from REGISTRY.tsv for 1.0 by",
        "ruling (Ian, RULING_REGISTRY_VERDICTS_2026-09-01.md section 1:",
        "'post-1.0 procedure: implemented and validated, menu and wizard",
        "doors withdrawn, public after 1.0'). Excluded here from the",
        "erosion check for the same reason -- public by the emlRun* name",
        "pattern alone, with no interactive path, until the doors reopen.")
)

for (nm in names(RUN_EXCLUSIONS)) {
    attest(V, sprintf("erosion check excludes emlRun* name: %s", nm), RUN_EXCLUSIONS[[nm]])
}

stale_exclusions <- setdiff(names(RUN_EXCLUSIONS), run_pattern_procs)
check_true(V,
           sprintf("RUN_EXCLUSIONS names are all still real emlRun* procedures in the tree (not stale)%s",
                   if (length(stale_exclusions))
                       paste0(" -- STALE, remove from the list: ", paste(stale_exclusions, collapse = ", "))
                   else ""),
           length(stale_exclusions) == 0L)

redundant_exclusions <- intersect(names(RUN_EXCLUSIONS), reg_names)
check_true(V,
           sprintf("RUN_EXCLUSIONS names are still absent from the registry (the exclusion is still needed)%s",
                   if (length(redundant_exclusions))
                       paste0(" -- now registered, exclusion is redundant: ", paste(redundant_exclusions, collapse = ", "))
                   else ""),
           length(redundant_exclusions) == 0L)

missing_run <- setdiff(setdiff(run_pattern_procs, reg_names), names(RUN_EXCLUSIONS))
check_true(V,
           sprintf("every emlRun* procedure in the tree has a registry row, or a documented exclusion (found %d, %d excluded)%s",
                   length(run_pattern_procs), length(intersect(run_pattern_procs, names(RUN_EXCLUSIONS))),
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

# ---- 4c. every ACTIVE door registration's directly-called emlRun*/emlDraw* -
# procedure has a registry row ----------------------------------------------
# Closes the gap named above: 4a only catches an emlRun*-named procedure and
# 4b only catches a graph-type dispatch branch, so neither would notice a
# withdrawn tool's menu entry coming back if the tool calls a differently-
# named procedure directly. This half re-derives, from setup.praat, every
# ACTIVE (uncommented) `Add menu command:` / `Add action command:` line's
# target script (`scripts/....praat`), then scans that script's own source
# text for real @eml(Run|Draw)... CALL SITES -- a call statement, `@emlFoo`
# or `@emlFoo:` sitting at the start of a line after only whitespace, never
# preceded by a quote (which is what a string literal assembling recorder
# text, CHECK 2's target, would show instead). This is exactly the guard
# that makes it safe today for emlDrawLMMForest to have no registry row:
# its menu entry is withdrawn, so scripts/eml-lmm.praat (which calls
# @emlDrawLMMForest directly) is not an active door and 4c does not scan it
# -- restore that entry and 4c scans the script, finds the call, and fails
# until a row exists. See the demonstration attestation below.
setup_path <- file.path(plug, "setup.praat")
door_scripts <- character(0)
if (file.exists(setup_path)) {
    setup_lines <- readLines(setup_path, warn = FALSE)
    active_door_lines <- setup_lines[grepl("^\\s*Add (menu|action) command:", setup_lines)]
    dm <- gregexpr("scripts/[A-Za-z0-9_.-]+\\.praat", active_door_lines)
    door_scripts <- unique(unlist(regmatches(active_door_lines, dm)))
}
check_true(V,
           sprintf("setup.praat parsed for active door registrations (found %d target scripts)",
                   length(door_scripts)),
           length(door_scripts) > 0L)

door_call_pat <- "^\\s*@eml(Run|Draw)[A-Za-z0-9_]*"
door_hit_locs <- list()  # name -> character vector of "script:line"
for (ds in door_scripts) {
    dpath <- file.path(plug, ds)
    if (!file.exists(dpath)) next
    dlines <- tryCatch(readLines(dpath, warn = FALSE), error = function(e) character(0))
    for (i in seq_along(dlines)) {
        if (grepl(door_call_pat, dlines[i])) {
            cap <- regmatches(dlines[i], regexpr("@eml(Run|Draw)[A-Za-z0-9_]*", dlines[i]))
            nm <- sub("^@", "", cap)
            door_hit_locs[[nm]] <- c(door_hit_locs[[nm]], sprintf("%s:%d", ds, i))
        }
    }
}
door_names <- names(door_hit_locs)
missing_door <- setdiff(door_names, reg_names)
check_true(V,
           sprintf("every active door's directly-called emlRun*/emlDraw* procedure has a registry row (%d door scripts scanned, %d names found)%s",
                   length(door_scripts), length(door_names),
                   if (length(missing_door))
                       paste0(" -- MISSING: ", paste(missing_door, collapse = ", "))
                   else ""),
           length(missing_door) == 0L)
if (length(missing_door)) {
    for (nm in missing_door) {
        cat(sprintf("      %s found at: %s\n", nm, paste(door_hit_locs[[nm]], collapse = "; ")))
    }
}

attest(V,
       "erosion check's source-2 half: 4b is scoped to the graph-type dispatch table; 4c covers active door registrations generally",
       "4b alone would not catch a brand-new top-level door that funnels through no dispatch table. 4c closes that: it re-derives setup.praat's active door-to-script wiring fresh every run and scans each door script's own text for direct emlRun*/emlDraw* call sites. 4c's own remaining limit: one level only -- a call reachable solely through a further `include` inside the door script would not be seen. See the file header.")

attest(V,
       "erosion check demonstrated (4a): temporarily deleting a registry row made this exact check fail, restoring the row made it pass again, and the restored file was confirmed byte-identical to the original (sha256)",
       "Demonstrated by hand during authoring, 2026-09-01: emlRunPairedAnalysis's row removed, `Rscript validate/v155_public_registry.R` run and observed to FAIL check 4a naming it, the row restored verbatim, re-run observed to PASS, and `sha256sum` before/after matched. Not re-run automatically on every suite pass because doing so would mean this file mutating REGISTRY.tsv on disk as a side effect of validation, which is worse than the property it would be proving.")

attest(V,
       "erosion check demonstrated (4c, door registration): a scratch copy of the plugin tree with emlDrawLMMForest's withdrawn menu entry restored made this exact check FAIL naming emlDrawLMMForest, and the real repository's setup.praat was never touched",
       "Demonstrated by hand during authoring, 2026-09-01, entirely in /tmp -- see the agent's report for the exact commands and their output, including the sha256sum proving the real setup.praat in this repository was read-only throughout. setup.praat is outside this task's file boundary (two other agents are editing it live), so the demonstration ran against a scratch copy rather than the tracked file: a scratch `Add menu command:` line for \"Linear Mixed Model...\" -> scripts/eml-lmm.praat was added, `Rscript` run against the scratch tree and observed to FAIL 4c naming emlDrawLMMForest at scripts/eml-lmm.praat, then the scratch copy was discarded (not reverted -- there was nothing in the real tree to revert).")

if (!exists("EML_SUITE")) { eml_report("v155 -- the public registry"); eml_exit() }
