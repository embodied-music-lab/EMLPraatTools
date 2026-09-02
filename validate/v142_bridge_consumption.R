# ============================================================================
# v142_bridge_consumption.R -- the figure CONSUMES the published result
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS FILE IS FOR
#
# docs/RULING_RESULT_STORE.md sections (c) and (d). Drawing a figure used to
# RE-RUN the analysis the figure annotates. Two things came of that, and the
# ruling names both: a SECOND full report in the Info window -- Ian's driven
# Kruskal-Wallis to violin session, the defect the store exists to remove --
# and numbers that could differ from the ones the user was shown at the
# analysis door, because nothing tied the two runs together.
#
# The read side is @emlConsumeGroupResult, and this file holds it to the
# reprint rule, which is the part that is most easily got wrong:
#
#   no change      the figure draws from the store. EXACTLY ONE report exists
#                  in the Info window -- the one the analysis door printed --
#                  and the draw adds ZERO lines.
#   changed setting  ONE line naming the change, in the contract's form:
#                  "Recomputed: adjustment method holm -> bonferroni." Then
#                  the updated brackets. NO second report block.
#   changed data   the figure re-runs and says so. It never quietly draws the
#                  stale one.
#
# AND THE VALIDITY TEST IS THE FINGERPRINT, NOT A CONSUMED-ONCE STAMP. The
# ruling is explicit that a result is legitimately consumed by MANY figures
# until the data or a result-affecting setting changes, so this file asserts
# the second and third draws off one publication are as silent as the first,
# and that no spent flag exists to make them anything else.
#
# HOW IT IS MEASURED. harness/bridgeconsume/run.sh stands a publication up BY
# HAND in the store's published names and drives @emlRunAnnotationComparison
# against it, writing CONSUME.tsv. That is deliberate rather than a stopgap:
# the read side's contract is "given these globals, do this", and a probe that
# could only run once the write site existed would be testing the pair and not
# the rule. The write site's own probe is harness/resultstore.
#
# WHAT THE PROBE READS BACK is what a reader of the figure has: the verdict,
# whether a report was authorised, the announcement line, the whole of the
# Info window that draw produced, the omnibus sentence, the bracket count and
# each bracket's group indices, p, effect size and label.
#
# THE SOURCE HALF IS NOT DECORATION HERE. Two properties cannot be measured
# from one driven artefact and are asserted against the source instead: that
# the canonical settings rendering CANNOT SEE the explanations gate, and that
# the two words for the group order are written in exactly one place. Both are
# failures that would show up as a re-run announced for a change nobody made,
# which is a slow, quiet defect a driven leg would have to be built to catch
# on purpose.
#
# Base R only. Reads source and one measured artefact; drives nothing.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v142"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

annot_path <- repo_path("plugin", "graphs", "eml-annotation-procedures.praat")
out_path   <- repo_path("plugin", "graphs", "eml-output.praat")
stats_out  <- repo_path("plugin", "stats", "eml-output.praat")
form_path  <- repo_path("plugin", "graphs", "eml-graphs-form.praat")
tsv_path   <- repo_path("harness", "bridgeconsume", "out", "CONSUME.tsv")

read_code <- function(path) {
    if (!file.exists(path)) return(character(0))
    x <- readLines(path, warn = FALSE)
    # Join Praat's "..." continuations, strip comments, trim. The same
    # normalisation v69 and v76 use, and for the same reason: a claim written
    # across two source lines is one statement.
    out <- character(0)
    for (ln in x) {
        t <- sub("^[[:space:]]+", "", ln)
        if (grepl("^\\.\\.\\.", t) && length(out)) {
            out[length(out)] <- paste0(out[length(out)], " ",
                                       sub("^\\.\\.\\.[[:space:]]*", "", t))
        } else {
            out <- c(out, t)
        }
    }
    out <- sub("^;.*$", "", out)
    out <- sub("^#.*$", "", out)
    trimws(out)
}

proc_body <- function(code, name) {
    s <- grep(sprintf("^procedure %s(:|$)", name), code)
    if (!length(s)) return(character(0))
    e <- grep("^endproc$", code)
    e <- e[e > s[1]]
    if (!length(e)) return(character(0))
    code[(s[1] + 1):(e[1] - 1)]
}

annot <- read_code(annot_path)
sout  <- read_code(stats_out)
form  <- read_code(form_path)

have_annot <- length(annot) > 0
have_sout  <- length(sout) > 0
have_form  <- length(form) > 0
have_tsv   <- file.exists(tsv_path)

check_true(V, "the annotation bridge source is present", have_annot)
check_true(V, "the output layer source is present", have_sout)
check_true(V, "the graphs form source is present", have_form)
check_true(V, "harness/bridgeconsume has been driven", have_tsv)

# ---------------------------------------------------------------------------
# THE ARTEFACT
# ---------------------------------------------------------------------------
tsv <- data.frame(case = character(0), field = character(0),
                  value = character(0), stringsAsFactors = FALSE)
if (have_tsv) {
    raw <- readLines(tsv_path, warn = FALSE)
    raw <- raw[nzchar(raw)]
    parts <- lapply(raw, function(ln) {
        p <- strsplit(ln, "\t", fixed = TRUE)[[1]]
        length(p) <- 3L
        p[is.na(p)] <- ""
        p
    })
    tsv <- as.data.frame(do.call(rbind, parts), stringsAsFactors = FALSE)
    names(tsv) <- c("case", "field", "value")
    tsv <- tsv[tsv$case != "case", , drop = FALSE]
}

fv <- function(case, field) {
    r <- tsv[tsv$case == case & tsv$field == field, , drop = FALSE]
    if (!nrow(r)) return(NA_character_)
    r$value[1]
}
fn <- function(case, field) suppressWarnings(as.numeric(fv(case, field)))
have_case <- function(case) any(tsv$case == case)

# The probe writes the Info window with newlines turned into " | ", so an
# empty cell means the draw printed nothing at all. THAT IS THE MEASUREMENT
# the no-change leg rests on and it is worth naming: not "no report", but no
# line of any kind.
said <- function(case) {
    x <- fv(case, "infoLines")
    if (is.na(x)) return(NA_character_)
    trimws(gsub("\\|", "", x))
}

# ===========================================================================
# 1. THE NO-CHANGE PATH -- ZERO LINES, AND MANY FIGURES OFF ONE RESULT
# ===========================================================================
NOCHANGE <- c("consume_anova", "consume_anova_again", "consume_anova_brackets",
              "twogroup_consume", "before_edit", "before_reorder",
              "before_refusal", "tukey_ignores_correction")
for (cs in NOCHANGE) {
    check_true(V, sprintf("%s: the probe ran this leg", cs), have_case(cs))
    if (!have_case(cs)) next
    check_true(V, sprintf("%s: the figure CONSUMED the published result", cs),
               identical(fv(cs, "verdict"), "consume") &&
               identical(fv(cs, "consumed"), "1"))
    check_true(V, sprintf("%s: no report is authorised -- the analysis door's is the only one", cs),
               identical(fv(cs, "printReport"), "0"))
    check_true(V, sprintf("%s: the draw printed NOTHING, not one line", cs),
               identical(said(cs), ""))
    check_true(V, sprintf("%s: and there is no announcement to make", cs),
               identical(fv(cs, "note"), ""))
    check_true(V, sprintf("%s: the figure still carries an omnibus sentence", cs),
               nzchar(fv(cs, "omnibus")) && grepl(":", fv(cs, "omnibus"),
                                                  fixed = TRUE))
    check_true(V, sprintf("%s: and both halves of the bracket caption", cs),
               nzchar(fv(cs, "captionTest")) && nzchar(fv(cs, "captionAdjust")))
}

# ONE RESULT, MANY FIGURES. The ruling separates this from the axis request,
# which is consumed once by design, and forbids a spent flag. Three draws off
# one publication, and the second and third are as silent as the first.
if (all(vapply(c("consume_anova", "consume_anova_again",
                 "consume_anova_brackets"), have_case, TRUE))) {
    check_true(V, "one publication serves a second figure, and a third",
               identical(fv("consume_anova", "verdict"), "consume") &&
               identical(fv("consume_anova_again", "verdict"), "consume") &&
               identical(fv("consume_anova_brackets", "verdict"), "consume"))
    check_true(V, "and every one of the three draws is silent",
               identical(said("consume_anova"), "") &&
               identical(said("consume_anova_again"), "") &&
               identical(said("consume_anova_brackets"), ""))
    # THE DISPLAY SETTINGS STILL APPLY. The store holds numbers; the layout is
    # chosen at draw time, so one stored result draws as a matrix and as
    # brackets without re-running anything.
    check_true(V, "a consumed result redraws at another layout without a re-run",
               identical(fv("consume_anova", "matrixN"), "3") &&
               identical(fv("consume_anova_brackets", "bracketN"), "3") &&
               identical(fv("consume_anova_brackets", "matrixN"), "0"))
}

# THE NUMBERS ARE THE SAME NUMBERS. A consumed figure and the figure the
# analysis computed must quote the same p and the same effect size, to the
# last digit -- that is the second half of the driven defect, and it is not
# covered by counting report lines.
if (have_case("twogroup_cold") && have_case("twogroup_consume")) {
    for (k in c("bracketN", "bracket1.i", "bracket1.j", "bracket1.p",
                "bracket1.d", "bracket1.label", "omnibus", "captionTest",
                "captionAdjust")) {
        check_true(V, sprintf("consumed and computed agree on %s", k),
                   !is.na(fv("twogroup_cold", k)) &&
                   identical(fv("twogroup_cold", k), fv("twogroup_consume", k)))
    }
}

# ===========================================================================
# 2. THE CHANGED-SETTING PATH -- ONE LINE, IN THE CONTRACT'S FORM
# ===========================================================================
# The ruling quotes the shape: "Recomputed: adjustment method holm ->
# bonferroni." One line, naming the change, and no second report block.
SETTING_LEGS <- list(
    changed_testtype   = "analysis one-way anova + tukey -> kruskal-wallis + dunn",
    changed_correction = "adjustment method holm -> bonferroni",
    changed_sort       = "group order table order -> alphabetical")

for (cs in names(SETTING_LEGS)) {
    check_true(V, sprintf("%s: the probe ran this leg", cs), have_case(cs))
    if (!have_case(cs)) next
    check_true(V, sprintf("%s: the verdict is a settings change, not a data change", cs),
               identical(fv(cs, "verdict"), "settings"))
    check_true(V, sprintf("%s: no second report block is authorised", cs),
               identical(fv(cs, "printReport"), "0"))
    check_true(V, sprintf("%s: the announcement is exactly the contract's line", cs),
               identical(fv(cs, "note"),
                         paste0("Recomputed: ", SETTING_LEGS[[cs]], ".")))
    # ONE LINE, AND ONLY ONE. The Info window for this draw is the
    # announcement and nothing else -- no report, no note, no second sentence.
    check_true(V, sprintf("%s: the draw printed that line and nothing else", cs),
               identical(said(cs), fv(cs, "note")))
    check_true(V, sprintf("%s: and the brackets were updated, not reused", cs),
               nzchar(fv(cs, "omnibus")))
}

# THE ANNOUNCEMENT IS ASCII. Every string in this plugin that can reach a file
# must be, and an announcement is exactly the sort of line a user copies into
# a log or a recorded script. The ruling's own text uses a typographic arrow;
# the built line uses "->".
for (cs in names(SETTING_LEGS)) {
    if (!have_case(cs)) next
    check_true(V, sprintf("%s: the announcement is ASCII", cs),
               !is.na(fv(cs, "note")) &&
               !grepl("[^\x01-\x7f]", fv(cs, "note")))
}

# THE TEST TYPE LEG ACTUALLY MOVED THE NUMBERS, which is what makes it a
# result-affecting setting rather than a display one. A leg that announced a
# change and drew the old omnibus would satisfy every line above.
if (have_case("consume_anova") && have_case("changed_testtype")) {
    check_true(V, "the changed setting really produced a different analysis",
               !identical(fv("consume_anova", "omnibus"),
                          fv("changed_testtype", "omnibus")) &&
               grepl("Kruskal-Wallis", fv("changed_testtype", "omnibus"),
                     fixed = TRUE))
}

# ===========================================================================
# 3. THE DATA PATH -- INCLUDING THE LEG IAN'S 24 AUGUST RULING INVERTED
# ===========================================================================
# "any change to the data including reordering of rows forces the mismatch
# error and redoing of the stats." Row order is result-affecting here because
# emlGroupSortAlphabetical initialises to 0 and group indices come back in
# discovery order, so moving one group's rows above another's flips the sign
# of t, of Cohen's d, of rank-biserial r and of every Tukey mean difference.
DATA_LEGS <- c("edited_cell", "reordered_rows")
for (cs in DATA_LEGS) {
    check_true(V, sprintf("%s: the probe ran this leg", cs), have_case(cs))
    if (!have_case(cs)) next
    check_true(V, sprintf("%s: the cache does NOT hold", cs),
               identical(fv(cs, "verdict"), "data") &&
               identical(fv(cs, "consumed"), "0"))
    check_true(V, sprintf("%s: the report is reprinted", cs),
               identical(fv(cs, "printReport"), "1"))
    check_true(V, sprintf("%s: under the 24 August line", cs),
               identical(fv(cs, "note"),
                         "Data changed since this analysis was last run; re-measured."))
}

# THE REORDER LEG IS THE ONE THAT USED TO ASSERT THE OPPOSITE. It is paired
# with the draw immediately before it, which DID consume, so the leg measures
# a transition rather than a state -- a reader can see that the only thing
# between them was the row move.
if (have_case("before_reorder") && have_case("reordered_rows")) {
    check_true(V, "a within-table row reorder turns a hit into a miss",
               identical(fv("before_reorder", "verdict"), "consume") &&
               identical(fv("reordered_rows", "verdict"), "data"))
}
if (have_case("before_edit") && have_case("edited_cell")) {
    check_true(V, "and so does one edited cell",
               identical(fv("before_edit", "verdict"), "consume") &&
               identical(fv("edited_cell", "verdict"), "data"))
    check_true(V, "the re-measured figure carries the NEW numbers",
               !identical(fv("before_edit", "omnibus"),
                          fv("edited_cell", "omnibus")))
}

# ===========================================================================
# 3b. THE REMAP -- CELL BY CELL, BOTH LAYOUTS, BOTH ARMS
# ===========================================================================
# THE ONE FAILURE IN THIS MECHANISM THAT IS SILENT AND WORST is a p-value
# drawn over the wrong pair of violins. annotBracketI[] and annotBracketJ[]
# are POSITIONS ON THE X AXIS, in @emlCountGroups' order; the store's
# matrices are indexed by emlStoreGroupLabel$[], which for a one-way ANOVA is
# Tukey's alphabetical sort. @emlStoreGroupMap maps label by label between
# them, and an off-by-one there produces a figure that is entirely
# well-formed and says something false.
#
# So the artefact carries a COMPUTED and a CONSUMED draw of the same
# comparison at each layout on each arm, and every observable of the two is
# compared: the group labels along the matrix, every cell's text, its
# significance flag and its effect size, every bracket's two group indices,
# its p, its effect size and its label, the omnibus sentence and both halves
# of the caption. Not a summary of them -- each one, by name.
REMAP <- list(
    c("remap_par_matrix_computed",  "remap_par_matrix_consumed"),
    c("remap_par_bracket_computed", "remap_par_bracket_consumed"),
    c("remap_non_matrix_computed",  "remap_non_matrix_consumed"),
    c("remap_non_bracket_computed", "remap_non_bracket_consumed"))

for (pr in REMAP) {
    a <- pr[1]; b <- pr[2]
    check_true(V, sprintf("%s: both draws are on the artefact", a),
               have_case(a) && have_case(b))
    if (!(have_case(a) && have_case(b))) next

    check_true(V, sprintf("%s: one computed, one consumed", a),
               identical(fv(a, "verdict"), "none") &&
               identical(fv(b, "verdict"), "consume"))

    fields <- union(tsv$field[tsv$case == a], tsv$field[tsv$case == b])
    # The four that are ABOUT the two draws differing, rather than about the
    # figure: they are asserted above and would make this comparison vacuous
    # in the wrong direction if they were included.
    fields <- setdiff(fields, c("verdict", "consumed", "printReport", "note",
                                "infoLines"))
    check_true(V, sprintf("%s: the comparison has a real corpus of observables (%d)",
                          a, length(fields)),
               length(fields) >= 15)
    bad <- fields[vapply(fields, function(k)
        !identical(fv(a, k), fv(b, k)), TRUE)]
    check_true(V,
        sprintf("%s: every one of the %d observables is identical%s", a,
                length(fields),
                if (length(bad)) paste0(" -- differs at: ",
                                        paste(bad, collapse = ", ")) else ""),
        length(bad) == 0)
}

# ===========================================================================
# 4. A PUBLICATION THAT IS NOT ABOUT THIS COMPARISON IS A MISS
# ===========================================================================
# And it is a MISS, not a data change: "Data changed since this analysis was
# last run" is a sentence about an edit, and saying it over a figure of a
# different table is a claim about something that did not happen. Measured
# before the guard existed and recorded in @emlConsumeGroupResult's header.
MISS_LEGS <- c("cold_anova", "twogroup_cold", "threegroup_vs_twogroup_store",
               "store_refusal", "store_old_schema")
for (cs in MISS_LEGS) {
    check_true(V, sprintf("%s: the probe ran this leg", cs), have_case(cs))
    if (!have_case(cs)) next
    check_true(V, sprintf("%s: the verdict is a plain miss", cs),
               identical(fv(cs, "verdict"), "none"))
    check_true(V, sprintf("%s: the report prints, as the FIRST report of this result", cs),
               identical(fv(cs, "printReport"), "1"))
    check_true(V, sprintf("%s: and nothing is announced about data nobody changed", cs),
               identical(fv(cs, "note"), ""))
    check_true(V, sprintf("%s: the draw itself printed nothing", cs),
               identical(said(cs), ""))
}

# A REFUSAL IN THE STORE IS NOT A RESULT, and an unknown schema does not
# upgrade. Both are paired with the draw before them so the transition is
# visible.
if (have_case("store_refusal")) {
    check_true(V, "a publication marked invalid is never consumed",
               identical(fv("store_refusal", "verdict"), "none"))
}
if (have_case("store_old_schema")) {
    check_true(V, "a store written under an older schema does not upgrade",
               identical(fv("store_old_schema", "verdict"), "none"))
}

# ===========================================================================
# 5. THERE IS NO SPENT FLAG
# ===========================================================================
# The ruling separates the result store from ruling A's axis request, which is
# consumed once BY DESIGN, and says a result is legitimately consumed by many
# figures. A consumed-once stamp would satisfy §1's first leg and fail its
# second; this is the source half of the same claim, and it is cheap.
if (have_annot) {
    body_consume <- proc_body(annot, "emlConsumeGroupResult")
    check_true(V, "@emlConsumeGroupResult exists", length(body_consume) > 0)
    check_true(V, "and it writes no published name -- the read side never writes the store",
               !any(grepl("^emlStore[A-Za-z]*[#$]?(\\[[^]]*\\])?[[:space:]]*=[^=]",
                          body_consume)))
    check_true(V, "and marks nothing spent, consumed-once or used",
               !any(grepl("spent|consumedOnce|alreadyUsed", body_consume,
                          ignore.case = TRUE)))
}

# ===========================================================================
# 6. THE CANONICAL SETTINGS RENDERING CANNOT SEE THE EXPLANATIONS GATE
# ===========================================================================
# THE STRUCTURAL HALF OF THE RULING'S "RENDERED, NOT FILTERED".
#
# The comparison that decides whether a setting changed is made against a
# canonical rendering of the settings. That rendering must not move when the
# user toggles explanations, or every draw would announce a change nobody
# made -- and it must not be produced by filtering explanation lines out of a
# report, because v132's permutation drive measured that a filter cannot be
# made to work: half the explanations are whole lines carrying no marker that
# separates them from a disclosure line.
#
# What is built is a rendering FROM THE SETTING VALUES, which consults no gate
# at all. That is stronger than lowering the gate for the scope, which would
# guarantee today's lines and say nothing about a line added tomorrow through
# @emlReportLine -- and it keeps emlShowExplanations out of the doors' own
# write set, which v112's census walk reads as "this is the door's scratch,
# not a setting".
#
# So the guarantee is asserted here, by text, over the four procedures that
# make up the rendering and the comparison.
RENDER_PROCS <- c("emlRenderResultSettings", "emlSettingsChangeNote",
                  "emlSettingsVocabulary")
if (have_sout) {
    for (nm in RENDER_PROCS) {
        b <- proc_body(sout, nm)
        check_true(V, sprintf("@%s exists", nm), length(b) > 0)
        if (!length(b)) next
        check_true(V, sprintf("@%s never names emlShowExplanations", nm),
                   !any(grepl("emlShowExplanations", b, fixed = TRUE)))
        check_true(V, sprintf("@%s never touches emlWizardExplain$", nm),
                   !any(grepl("emlWizardExplain\\$", b)))
        check_true(V, sprintf("@%s calls no reporter that consults the gate", nm),
                   !any(grepl("@emlReportLine|@emlReportLineString|@emlReportPWithExact",
                              b)))
    }

    # AND IT IS A RENDERING, NOT A FILTER: nothing in it reads report text.
    b <- proc_body(sout, "emlRenderResultSettings")
    check_true(V, "the rendering is built from values, not cut out of a report",
               length(b) > 0 &&
               !any(grepl("index\\s*\\(|replace_regex\\$|extractLine\\$|info\\$",
                          b)))
}

# ===========================================================================
# 7. THE TWO WORDS FOR THE GROUP ORDER ARE WRITTEN IN ONE PLACE
# ===========================================================================
# THE DRY RULE THIS REPOSITORY WORKS TO: state the canon in a procedure AND
# add a text check that the copies agree, because a procedure records a rule
# and cannot stop somebody typing the word again somewhere else.
#
# Two surfaces need the same word for emlGroupSortAlphabetical:
# @emlReportGroupOrderLine, which discloses the order on every grouped
# comparison report, and @emlRenderResultSettings, whose rendering is compared
# AS TEXT to decide whether a stored result still holds. A second spelling in
# either would announce a settings change nobody made, on every draw, for
# ever.
if (have_sout) {
    b <- proc_body(sout, "emlGroupOrderName")
    check_true(V, "@emlGroupOrderName exists and is the canon", length(b) > 0)
    check_true(V, "it holds both words",
               length(b) > 0 &&
               any(grepl('"alphabetical"', b, fixed = TRUE)) &&
               any(grepl('"table order"', b, fixed = TRUE)))
    check_true(V, "@emlReportGroupOrderLine takes its word from it, not from a literal",
               {
                   r <- proc_body(sout, "emlReportGroupOrderLine")
                   length(r) > 0 && any(grepl("@emlGroupOrderName:", r,
                                              fixed = TRUE)) &&
                   !any(grepl('"alphabetical"|"table order"', r))
               })
}

# COUNTED OVER THE WHOLE PLUGIN, not over one file: a second spelling would
# most likely arrive in the graphs layer, next to the control the user sets.
# COUNTED OVER THE WHOLE PLUGIN, not over one file: a second spelling would
# most likely arrive in the graphs layer, next to the control the user sets.
# "table order" is the READER'S word and is the one counted; the store's own
# token for the same state is "table", written once in @emlStoreKeyTake, and
# the two vocabularies are deliberately different -- which is exactly why the
# reader's word may not be written twice.
plug_files <- list.files(repo_path("plugin"), pattern = "\\.praat$",
                         recursive = TRUE, full.names = TRUE)
# dev/ carries the phase-2 test suites, which quote the words to assert them.
plug_files <- plug_files[!grepl("/dev/", plug_files, fixed = TRUE)]
order_hits <- 0L
for (f in plug_files) {
    x <- readLines(f, warn = FALSE)
    x <- sub("^[[:space:]]*[;#].*$", "", x)
    order_hits <- order_hits +
        sum(grepl('^[[:space:]]*[.A-Za-z][A-Za-z0-9_.]*\\$[[:space:]]*=[[:space:]]*"table order"$', x))
}
check_true(V, sprintf("the reader's word for table order is assigned in exactly one place (%d assignments)",
                      order_hits),
           order_hits == 1L)
check_true(V, "and neither the report line nor the settings rendering writes it",
           {
               r <- proc_body(sout, "emlReportGroupOrderLine")
               q <- proc_body(sout, "emlRenderResultSettings")
               !any(grepl('"table order"', c(r, q), fixed = TRUE))
           })

# ===========================================================================
# 7b. THE TWO DOORS NAME THE SAME ANALYSIS THE SAME WAY
# ===========================================================================
# THE DRY RULE, APPLIED WHERE ITS FAILURE IS SILENTEST. The menu door
# publishes what it ran as a test token -- "welch t", "one-way anova + tukey"
# -- and the graph door has to say the same thing about the same analysis or
# the store's identity comparison can never match, so every figure re-runs and
# announces a change nobody made. @emlBridgeStoreIdentity is the graph door's
# half of that vocabulary; stats/eml-analysis.praat is the menu door's.
#
# A rename on either side is exactly the edit that would break this quietly:
# nothing errors, no number moves, and the cache simply stops hitting. So the
# tokens are held together by text -- every token the bridge can produce must
# occur as a `.stTest$ =` literal in the analysis layer, and the correction
# tokens likewise.
analysis_path <- repo_path("plugin", "stats", "eml-analysis.praat")
if (have_annot && file.exists(analysis_path)) {
    ana <- read_code(analysis_path)
    b <- proc_body(annot, "emlBridgeStoreIdentity")
    check_true(V, "@emlBridgeStoreIdentity exists", length(b) > 0)

    bridge_tokens <- unique(sub('^\\.test\\$ = "(.*)"$', "\\1",
                                grep('^\\.test\\$ = "', b, value = TRUE)))
    check_true(V, sprintf("the bridge names four analyses (%s)",
                          paste(bridge_tokens, collapse = ", ")),
               length(bridge_tokens) == 4L && all(nzchar(bridge_tokens)))

    menu_tokens <- unique(sub('^\\.stTest\\$ = "(.*)"$', "\\1",
                              grep('^\\.stTest\\$ = "', ana, value = TRUE)))
    for (tk in bridge_tokens) {
        check_true(V,
            sprintf("the menu door writes the same token for '%s'", tk),
            tk %in% menu_tokens)
    }

    # AND THE ADJUSTMENT IS EMPTY EXCEPT ON DUNN'S, which is not a detail: a
    # Tukey figure drawn while the form's Adjustment menu happens to hold
    # "bonferroni" must still match a Tukey analysis that never applied it,
    # because Tukey's p is already family-wise and the menu door records ""
    # for it. Publishing the menu's value there would make every Tukey figure
    # miss against its own menu run, for ever, silently.
    check_true(V, "the bridge writes an empty adjustment on every arm but Dunn's",
               sum(grepl('^\\.correction\\$ = ""$', b)) == 2L)
}

# ===========================================================================
# 8. THE FORM OBEYS THE BRIDGE, AND ADDS NO RULE OF ITS OWN
# ===========================================================================
# @emlReportBridgeStats prints the FULL analysis report, and the duplicate
# report is the driven defect. The bridge is the only thing that knows whether
# it computed anything, so the bridge decides and the form obeys through one
# gate. Five arms call it; a sixth that called the reporter directly would put
# the duplicate report back on one graph type only, which is exactly the shape
# of defect this tree keeps finding.
if (have_form) {
    direct <- grep("^@emlReportBridgeStats:", form)
    gated  <- grep("^@emlGraphsReportBridgeIfNew:", form)
    check_true(V, sprintf("every bridge arm reports through the gate (%d gated)",
                          length(gated)),
               length(gated) >= 4)
    check_true(V, "and no arm calls the reporter directly, past it",
               length(direct) == 0)
}
if (have_annot) {
    g <- proc_body(annot, "emlGraphsReportBridgeIfNew")
    check_true(V, "@emlGraphsReportBridgeIfNew exists", length(g) > 0)
    check_true(V, "it reads the bridge's decision through variableExists",
               length(g) > 0 &&
               any(grepl('variableExists ("emlRunAnnotationComparison.printReport")',
                         g, fixed = TRUE)))
    check_true(V, "and prints when it cannot tell -- silence has to be earned",
               length(g) > 0 && any(grepl("^\\.print = 1$", g)))
}

# ===========================================================================
# 9. THE READ SIDE IS NOT A SECOND WRITE SITE
# ===========================================================================
# Section (d) allows the store exactly one writer. A reader that could also
# write is a second writer with a different name, which is the whole failure
# the single-writer contract exists to prevent. The bridge's own re-runs
# therefore go THROUGH that writer, guarded on the global it declares when it
# is loaded, so a tree carrying the read side and not yet the writer draws
# correctly and simply never caches.
if (have_annot) {
    body_bridge <- proc_body(annot, "emlRunAnnotationComparison")
    check_true(V, "the bridge publishes its re-runs through the store's one writer",
               any(grepl("^@emlPublishAnalysisResult:", body_bridge)))
    check_true(V, "guarded on the schema global the writer declares at load",
               any(grepl('variableExists ("emlStoreFormat$")', body_bridge,
                         fixed = TRUE)))
    # PUBLISHES ONLY WHAT IT COMPUTED. Re-publishing a consumed result would
    # be the read side writing the store back through the front door: the
    # numbers would survive, but the KEY and the identity would be re-stamped
    # by a pass that measured nothing, and the store's single-writer contract
    # would be answering to itself.
    check_true(V, "and it publishes only what it computed, never what it consumed",
               {
                   i <- grep("^@emlPublishAnalysisResult:", body_bridge)
                   length(i) == 1 &&
                   any(grepl("^if \\.consumed = 0 and", body_bridge[max(1, i - 30):i]))
               })
    check_true(V, "no file outside the store's own writes a published name",
               !any(grepl("^emlStore(Format\\$|Valid|Kind\\$|Key\\$|NGroups|Alpha)[[:space:]]*=[^=]",
                          annot)))
}

if (!exists("EML_SUITE")) {
    eml_report("v142 -- the figure consumes the published result (ruling sections c and d)")
    eml_exit()
}
