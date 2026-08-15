# ============================================================================
# v61_graphs_seams.R -- the graphs form's seams, and how to tell them apart
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHY THIS FILE EXISTS. The 14 August 2026 stress-test audit's headline about
# the graphing layer is that its duplicated statistics engine AGREES WITH THE
# WRAPPERS EVERYWHERE TESTED -- every bridge-arm statistic recomputed against
# scipy, no mismatches. Its findings are all of the other kind: the numbers are
# right and the plumbing around them leaks. Five of those leaks are held here.
#
#   NEW-G9-1 / S6  THE ONLY CRASH REACHABLE FROM A DEFAULT JOURNEY. An
#                  annotated nonparametric draw on three or more groups died
#                  with "Unknown variable: emlKruskalWallis.rMatrix##" -- and
#                  only when the omnibus was SIGNIFICANT, because that is the
#                  branch on which @emlBridgeGroupComparison runs Dunn's test,
#                  and @emlReportKWComparison then stops computing the pairwise
#                  rank-biserial matrix for itself and reads the one its header
#                  says "the orchestrator guarantees". stats/eml-analysis.praat
#                  does guarantee it, one line after the same call. The graphs
#                  bridge is a SECOND orchestrator and guaranteed nothing. The
#                  whole graphs session went down with it: no figure, no pause
#                  form, a truncated report, and Praat's recovery text pointing
#                  the user at a window that no longer existed. As the audit
#                  put it, the crash triggered precisely when a user had a
#                  result worth annotating.
#
#   D7             THE WRAPPER'S ANNOTATE PRESET, LOST AT EVERY BEGINNER DRAW.
#                  Six commit sites set annotate = 0. That is the author's
#                  ruling of 13 Aug 2026 -- beginner mode draws only what its
#                  own dialog offers -- and it is not being overturned here:
#                  the beginner page now OFFERS the tickbox, pre-ticked, on the
#                  pass where a wrapper actually asked. Before that, the
#                  default journey (run a test, press Draw, press Draw) drew a
#                  significant result unannotated, and the request came back
#                  only if the user happened to toggle to Advanced.
#
#   NEW-G8-3       DUPLICATE RESULT BLOCKS, ONE PER DRAW. Nine draws in one
#                  graphs session put nine value-identical blocks in the
#                  exported CSV -- 162 rows where 18 were the analysis. Same
#                  init-discipline family as v57's NEW-G1-1, and the rule the
#                  audit asked to be written down is the one both now follow:
#                  INIT ONCE PER PRESS, ACCUMULATE PER LOOP.
#
#   D8             LEGEND PLACEMENT COMMITS ONLY IN ADVANCED MODE. "Separate
#                  figure", chosen once in an advanced session, persists to
#                  config and is read by every later draw -- so a beginner Save
#                  emitted an unrequested <stem>_legend.png from a dialog that
#                  had never mentioned legends.
#
#   D1/D2 + D11 + D4 (static)  Custom axis labels persisted to config with zero
#                  reads and blanked at every page entry; group-column fields
#                  live while their tickbox is clear and then discarded; and a
#                  preset channel with no producer anywhere in the plugin.
#
# WHAT THE FAILURE LOOKS LIKE. Four of the five are SILENT. A lost annotate
# preset draws a clean figure. A duplicated result block is a longer file of
# correct numbers. A leaked legend is an extra file. A blanked axis label is an
# empty box. Only the fifth announces itself, and it announces itself by
# killing the session.
#
# WHAT COULD NOT HAVE CAUGHT THEM, and each reason is closed below.
#
#   * EVERY NUMERIC VALIDATOR IN THIS SUITE, and the audit itself. v10
#     recomputes the Kruskal-Wallis orchestrator against R, and the crash is
#     not in the orchestrator -- it is in the graphs layer's own call sequence
#     into the same procedures. Not one number changes in any of these five.
#     v57 says the same thing about NEW-G1-1 and it is worth repeating: a
#     validator built to ask "is this number right" cannot ask "is this number
#     the only one left", or "did anything reach the figure at all".
#
#   * harness/gui_e2e. It draws in BEGINNER mode, where annotate was forced to
#     0, so the bridge never ran -- the KW crash is outside its journey BY
#     CONSTRUCTION, and so was D7's consequence.
#
#   * harness/gui_adv AND v51, which are the closest thing that existed. v51
#     drives the annotate preset and counts report sections to prove it
#     survived, which is exactly the technique used here -- but its journey is
#     PARAMETRIC and two-group. A two-group comparison never reaches the k>=3
#     branch, so no arrangement of that harness could have met the crash. Its
#     "toggle to Advanced and read the tickbox" also measures the RESCUE rather
#     than the default journey: it proves the setting can be got back, not that
#     a user who never toggles ever had it.
#
#   * A FILE-SET CHECK, for D7 and for the KW draw both. This is the subtle
#     part and v51 already recorded it: an annotated draw and an unannotated
#     one leave the SAME filenames on disk. Same stems, same shapes, different
#     author.
#
# WHAT DOES SEPARATE THEM, seam by seam -- because a check that cannot
# distinguish the two states is not a check:
#
#   KW crash   THE THREE RANK-BISERIAL VALUES. The matrix HEADING is printed
#              one line before the read that used to abort, so the heading
#              proves nothing: the audit's own screenshot has it, above an
#              error dialog. The numbers under it are what only a completed
#              draw can produce, and they are independently known -- scipy puts
#              them at 0.5822, 0.7867 and 0.4400 (g9.verify.md), which the
#              reporter prints to three places as 0.582, 0.787 and 0.440.
#              Measured 15 Aug 2026 by driving the harness against a copy of
#              eml-annotation-procedures.praat with the declaration removed:
#              Praat exit 255, no report file at all, no figure, versus a
#              5022-byte report carrying all three values. THE OMNIBUS p IS
#              CHECKED FIRST, because the crash only ever fired on the
#              significant branch: a fixture that drifted above alpha would
#              make every check below pass while testing the branch that never
#              had the defect.
#
#   D7         ONE INTEGER: how many "Kruskal-Wallis H Test" banners the saved
#              report carries. The driver's own orchestrator writes one. The
#              annotation bridge writes a second, and can only do so if
#              annotate was still 1 at the beginner commit. 1 = lost, 2 =
#              honoured. Measured with the six commit arms reverted: 1 section,
#              3178 bytes, and a figure with nothing on it.
#
#   NEW-G8-3   THE MULTIPLICITY OF ONE KEY. Three Draws, one export. Row count
#              alone can be argued with -- a grouped scatter legitimately
#              writes three analyses -- so what is counted is how many times
#              the same (table, analysis, term, field) appears. One press
#              writes each exactly once. Measured before the fix: 2, from the
#              legend-room second pass, on a run whose three presses were
#              already deduped by the press-level reset.
#
#   D8         A FILE THAT SHOULD NOT EXIST. The leg's config is seeded with
#              legendPlacement: 4 -- exactly what quitting an advanced session
#              with "Separate figure" leaves behind -- and then draws in
#              beginner mode and saves. Everything else about the artefact set
#              is identical either way, including the figure, which carries no
#              legend in the broken case either: the legend was parked
#              off-extent for a second file nobody asked for.
#
#     bash harness/graphseams/run.sh
#     Rscript validate/v61_graphs_seams.R
#
# Input: harness/graphseams/out/{SEAMS.tsv,DIALOGS_*.tsv,ARTEFACTS_*.tsv} and
#        the two source files, for the static half.
#        $EML_SEAMS_DIR, $EML_GRAPHSFORM_FILE and $EML_ANNOTPROC_FILE override,
#        for break tests.
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

form <- Sys.getenv("EML_GRAPHSFORM_FILE", unset = "")
if (!nzchar(form)) form <- repo_path(file.path("plugin", "graphs",
                                               "eml-graphs-form.praat"))
annot <- Sys.getenv("EML_ANNOTPROC_FILE", unset = "")
if (!nzchar(annot)) annot <- repo_path(file.path("plugin", "graphs",
                                                 "eml-annotation-procedures.praat"))

check_true("v61", "the graphs form is present", file.exists(form))
check_true("v61", "the annotation procedures are present", file.exists(annot))

.joined <- function(path) {
    if (!file.exists(path)) return(character(0))
    raw <- readLines(path, warn = FALSE)
    out <- character(0)
    for (ln in raw) {
        if (grepl("^\\s*\\.\\.\\.", ln) && length(out)) {
            out[length(out)] <- paste0(out[length(out)], " ",
                                       sub("^\\s*\\.\\.\\.\\s*", "", ln))
        } else out <- c(out, ln)
    }
    out
}
.code <- function(path) {
    x <- .joined(path)
    x[!grepl("^\\s*(#|;)", x)]
}
fcode <- .code(form)
acode <- .code(annot)

# ---------------------------------------------------------------------------
# 1. THE PAIRWISE MATRIX IS DECLARED ON THE SIGNIFICANT BRANCH (NEW-G9-1)
# ---------------------------------------------------------------------------
# Static, and it is here as well as in the drive for one reason: it says WHERE.
# The drive proves the session survives; only the source can say that it
# survives because the bridge copies Dunn's matrix rather than because someone
# put a fallback compute in the reporter. Those are different fixes with
# different futures -- the second leaves the "guaranteed by orchestrator"
# contract broken for the next caller.
check_true("v61",
           "the graphs bridge copies Dunn's rank-biserial matrix into emlKruskalWallis",
           any(grepl("emlKruskalWallis\\.rMatrix##\\s*=\\s*emlDunnTest\\.rMatrix##",
                     acode)))

# THE COPY IS ON THE SIGNIFICANT BRANCH. Praat has no block scope a static
# reader can lean on, so the anchor is the two lines that bracket it: the call
# to @emlDunnTest, which happens only under `if .pOmnibus < .alpha`, and the
# copy, which must come after it and before the branch closes.
.dunnAt <- grep("@emlDunnTest\\s*:", acode)
.copyAt <- grep("emlKruskalWallis\\.rMatrix##\\s*=\\s*emlDunnTest\\.rMatrix##", acode)
check_true("v61",
           "the copy follows the bridge's own @emlDunnTest call, not a global fallback",
           length(.dunnAt) > 0 && length(.copyAt) > 0 &&
           any(vapply(.copyAt, function(i) any(.dunnAt < i & .dunnAt > i - 30),
                      logical(1))))

# ---------------------------------------------------------------------------
# 2. THE STATIC SEAMS: D4, D1/D2, D11
# ---------------------------------------------------------------------------
# D4. A preset channel with no producer. The audit's wording is worth keeping:
# dead preset channels are how D7-shaped defects get built -- a consumer
# contract nothing exercises is a contract nobody can be shown to have kept.
check("v61", "the dot-size preset channel has no reads left (D4)",
      0L, sum(grepl("emlGraphsPresetDotSize|emlGraphsPresetShowDots", fcode)),
      tol = 0)

# D1/D2. The store is type-keyed and it is READ. The old failure was not that
# the value was stored wrongly -- it was that every page entry blanked the two
# variables before anything could restore them.
check_true("v61", "custom axis labels have a per-type store that is written",
           any(grepl("prevAxisXLabel\\$\\s*\\[graph_type\\]\\s*=", fcode)))
# AND THE STORE IS INITIALISED FOR EVERY TYPE. Praat has no empty default for
# an indexed variable: reading one that was never assigned aborts the script
# with "Undefined indexed variable". The write above is not enough on its own,
# and the omission is invisible to every beginner journey because the seed
# procedure only reads in advanced mode -- which is how it reached a drive.
check_true("v61", "and the store is initialised for every registered type",
           any(grepl("prevAxisXLabel\\$\\s*\\[iAxisLbl\\]\\s*=", fcode)) &&
           any(grepl("for iAxisLbl from 1 to nGraphTypes", fcode)))
check_true("v61", "and read back at page entry",
           any(grepl("tmpXLabel\\$\\s*=\\s*prevAxisXLabel\\$", fcode)))
check("v61",
      "every column-mapping page seeds its labels through the one procedure",
      13L, sum(grepl("^\\s*@emlSeedAxisLabels\\s*$", fcode)), tol = 0)
# AND NO PAGE STILL BLANKS THEM ON ENTRY. Thirteen pages, and a single one left
# with the old two-line reset would lose the label for its own type only --
# which is precisely the shape of defect that survives a spot check. The
# INDENT is what separates the two sites, and it has to be, because the
# statement is identical: at page scope (eight spaces) it is the defect; inside
# the toggle handler (twenty or more) it is the beginner reset, which is
# correct and must stay.
check("v61", "no page-entry blanking of the label fields survives",
      0L, sum(grepl('^\\s{8}tmpXLabel\\$ = ""\\s*$', fcode)), tol = 0)
check("v61", "and the thirteen beginner-mode resets are still there",
      13L, sum(grepl('^\\s{20,}tmpXLabel\\$ = ""\\s*$', fcode)), tol = 0)

# The subtitle half: seeded from the config it was already being saved to.
check_true("v61", "the subtitle field is seeded from the saved config (D1/D2)",
           any(grepl("prev_subtitle\\$\\s*=\\s*config_subtitle\\$", fcode)))

# D11. Three graph types, three gates, and each gate read again where the
# commit used to take the value it had just hidden.
for (g in c("scatterGroupShown", "histGroupShown", "spGroupShown")) {
    check_true("v61",
               sprintf("the group fields are gated on the tickbox (%s)", g),
               sum(grepl(paste0("\\b", g, "\\b"), fcode)) >= 4)
}

# D5 IS NOT FIXED HERE, AND THIS CHECK IS WHY IT IS SAFE TO LEAVE ALONE.
#
# The audit measured that a Tukey draw is md5-identical under Holm and under
# Bonferroni while the Dunn arm honours the same menu, and filed it as
# severity 3. The plugin's own comment at the preset site says the parametric
# branch never reads .correction$ and that changing it belongs to
# eml-annotation-procedures.praat. The statistics agree with the code: Tukey's
# p comes from the studentized range distribution and is already family-wise
# controlled, so a Holm or Bonferroni step on top of it would DOUBLE-correct --
# there is no honest thing for the menu to do on that arm. What there is, is
# saying so, and every one of the six dialogs that offers the menu already
# qualifies its label. That qualifier is what this pins: it is the entire
# defence, it is one string, and a tidy-up that dropped it as clutter would
# turn a documented limitation back into a silent one.
#
# IF IAN RULES OTHERWISE -- disable the field on the parametric arm, or make
# Tukey report its own correction in the figure -- this check is the first
# thing to revisit. It asserts a disclosure, not a behaviour.
check("v61", "every adjustment menu says which arm reads it (D5 disclosure)",
      6L, sum(grepl('optionmenu: "Adjustment method \\(nonparametric post-hoc only\\)"',
                    fcode)), tol = 0)

# D8. The single write to the drawing layer's placement global is overridden in
# beginner mode -- and NOT by writing config, which would destroy the advanced
# preference the user still owns.
check_true("v61", "beginner mode overrides the legend placement for the draw (D8)",
           any(grepl("emlLegendPlacement\\s*=\\s*1", fcode)))
# AND THE PERSISTED KEY STILL HAS EXACTLY FIVE WRITERS: the load default, the
# config parser, the two clamp arms, and @emlCommitLegendPlacement. A sixth
# would be the tempting version of this fix -- commit a beginner default over
# the user's advanced choice -- which trades the leak for silently forgetting
# what they picked. The count is what says which fix was made.
check("v61", "the persisted legend key gained no new writer (D8)",
      5L, sum(grepl("^\\s*config_legendPlacement\\s*=", fcode)), tol = 0)

# D7. Six pages, six beginner arms, and the count is the check: five would be a
# graph type that silently kept the old behaviour.
# TWELVE TICKBOXES: the six advanced blocks that always had one, and the six
# beginner arms that now do. Eleven would be a graph type left behind, which is
# exactly the shape of defect a spot check blesses.
check("v61", "the annotate tickbox is on twelve dialog arms, not six (D7)",
      12L, sum(grepl('boolean: "Annotate results on graph"', fcode)), tol = 0)
check("v61", "and twelve preset arms decide whether it is shown",
      12L, sum(grepl("elsif emlGraphsPresetAnnotate > 0", fcode)), tol = 0)
# EIGHTEEN READS: six advanced commits, six beginner commits, six toggles. The
# anchor matters -- `prev_adv_bar_annotate = annotate_results_on_graph` is the
# mode STASH and is a different statement, and an unanchored pattern counts it.
check("v61", "and the tickbox is read back at eighteen commit and toggle sites",
      18L, sum(grepl("^\\s*annotate\\s*=\\s*annotate_results_on_graph\\s*$", fcode)),
      tol = 0)

# NEW-G8-3. The press-level reset, and the pass-level rewind that the drive
# found was still needed after it.
check_true("v61", "the scatter arm resets the collector once per press (NEW-G8-3)",
           any(grepl("graph_type = 8 and annotate = 1 and scatterAnalysisType > 0",
                     fcode)))
# THROUGH THE ROW-ONLY RESET, NOT @emlCSVInit. The distinction is the fix: the
# scatter's reporters do not declare, so clearing the declaration here would
# delete a live one rather than correct a stale one.
check_true("v61", "and does so without touching the three-file declaration",
           any(grepl("@emlCSVInitRows", fcode)) &&
           !any(grepl("emlResult_declared", fcode)))
check_true("v61", "the thrown-away legend-room pass rewinds its rows",
           any(grepl("@emlCSVMark", fcode)) && any(grepl("@emlCSVRewind", fcode)))
# AND THE TWO PROCEDURES EXIST WHERE THE COLLECTOR DOES. A call to a procedure
# Praat cannot find is a run-time abort, not a parse error, so nothing but a
# drive or this check stands between a rename and a dead Draw button.
outp <- Sys.getenv("EML_OUTPUT_FILE", unset = "")
if (!nzchar(outp)) outp <- repo_path(file.path("plugin", "stats", "eml-output.praat"))
ocode <- .code(outp)
check_true("v61", "the row-only reset and the mark/rewind pair are defined in eml-output",
           any(grepl("^procedure emlCSVInitRows\\s*$", ocode)) &&
           any(grepl("^procedure emlCSVMark\\s*$", ocode)) &&
           any(grepl("^procedure emlCSVRewind\\s*$", ocode)))

# ---------------------------------------------------------------------------
# 3. THE DRIVE
# ---------------------------------------------------------------------------
gs <- Sys.getenv("EML_SEAMS_DIR", unset = "")
if (!nzchar(gs)) gs <- repo_path(file.path("harness", "graphseams", "out"))

have <- check_true("v61",
                   "the seam artefact exists (bash harness/graphseams/run.sh)",
                   dir.exists(gs) && file.exists(file.path(gs, "SEAMS.tsv")))
if (!have) {
    if (!exists("EML_SUITE")) { eml_report("v61 graphs seams"); eml_exit() }
}

.kv <- function(path) {
    if (!file.exists(path)) return(list())
    x <- read.delim(path, header = FALSE, sep = "\t", quote = "",
                    stringsAsFactors = FALSE, fill = TRUE)
    setNames(as.list(trimws(as.character(x[[2]]))), trimws(as.character(x[[1]])))
}
s <- .kv(file.path(gs, "SEAMS.tsv"))
.num <- function(k) suppressWarnings(as.numeric(s[[k]]))
.int <- function(k) suppressWarnings(as.integer(s[[k]]))
# helpers.R does not export a null-coalescing operator and this file is not the
# place to add one to it: a missing key must read as "" here, not as NULL
# propagating into grepl() and quietly returning logical(0).
.str <- function(k) { v <- s[[k]]; if (is.null(v)) "" else as.character(v) }

if (length(s)) {

# --- 3a. THE RUN WAS THE EXPERIMENT IT CLAIMS TO BE -------------------------
# Checked before anything is concluded from it. Every check below is about a
# branch that only exists when the omnibus is significant and the journey is
# the beginner one; a run that quietly took the other branch would be clean
# and would prove nothing, which is the failure v51's header is about.
check_true("v61",
           sprintf("the KW omnibus was significant on the beginner leg (p = %s)",
                   s[["kw_omnibus_p"]]),
           !is.na(.num("kw_omnibus_p")) && .num("kw_omnibus_p") < 0.05)
check_true("v61",
           sprintf("and on the standalone advanced leg (p = %s)",
                   s[["kwadv_omnibus_p"]]),
           !is.na(.num("kwadv_omnibus_p")) && .num("kwadv_omnibus_p") < 0.05)

# THE CRASH LEG RAN NOTHING FIRST, and this is the check that keeps this file
# honest. Driven 15 Aug 2026 with the bridge's declaration deleted, a leg whose
# driver called @emlRunKWAnalysis before handing over completed every dialog
# and wrote every value: the ORCHESTRATOR had already declared the matrix, so
# the bridge's omission could not show. A one-section report is what says the
# annotation bridge is the only thing that reported on this leg.
check("v61",
      "the crash leg reported once and only from the bridge (nothing ran first)",
      1L,
      if (!is.na(.int("kwadv_report_bytes")) && .int("kwadv_report_bytes") > 0)
          length(grep("Kruskal-Wallis H Test",
                      readLines(file.path(gs, "report_kwadv.utf8.txt"),
                                warn = FALSE))) else -1L,
      tol = 0)

d0 <- file.path(gs, "DIALOGS_kwadv.tsv")
if (check_true("v61", "the crash leg's dialog chain was recorded",
               file.exists(d0) && file.info(d0)$size > 0)) {
    t0 <- read.delim(d0, header = FALSE, sep = "\t", quote = "",
                     stringsAsFactors = FALSE, fill = TRUE)
    check("v61", "the crash leg pressed no toggle (advanced came from the config)",
          0L, sum(trimws(as.character(t0[[3]])) == "Advanced"), tol = 0)
    check_true("v61", "the crash leg reached the save receipt",
               any(trimws(as.character(t0[[2]])) == "Saved"))
}

d <- file.path(gs, "DIALOGS_kw.tsv")
if (check_true("v61", "the KW dialog chain was recorded",
               file.exists(d) && file.info(d)$size > 0)) {
    tsv <- read.delim(d, header = FALSE, sep = "\t", quote = "",
                      stringsAsFactors = FALSE, fill = TRUE)
    titles <- trimws(as.character(tsv[[2]]))
    labels <- trimws(as.character(tsv[[3]]))
    # NO TOGGLE ANYWHERE ON THIS LEG. That is the whole difference from v51's
    # journey and the reason this one measures the default path: the moment a
    # run presses Advanced, annotate is restored by the toggle handler and the
    # beginner commit is no longer what is under test.
    check("v61", "the KW leg never left beginner mode", 0L,
          sum(labels == "Advanced"), tol = 0)
    check_true("v61", "the KW leg drew from the column-mapping page",
               any(grepl("Column Mapping", titles) & labels == "Draw"))
    check_true("v61", "the KW leg reached the save receipt", any(titles == "Saved"))
    check_true("v61", "the workflow was not asked for an object it was handed",
               !any(grepl("No .* selected", titles)))
}

# --- 3b. THE CRASH IS GONE, AND THE FIGURE IS THE ONE THAT WAS ASKED FOR ----
check("v61", "the crash leg did not die on an undefined variable (NEW-G9-1)",
      0L, .int("kwadv_unknown_variable"), tol = 0)
check("v61", "nor did the beginner leg",
      0L, .int("kw_unknown_variable"), tol = 0)
check_true("v61", "the crash leg wrote a report at all",
           !is.na(.int("kwadv_report_bytes")) && .int("kwadv_report_bytes") > 2000)
# THE THREE VALUES. Not the heading, which the crashed run also printed.
rb <- strsplit(trimws(.str("kwadv_rb_values")), "\\s+")[[1]]
check_true("v61",
           sprintf("the rank-biserial matrix carries scipy's three values (%s)",
                   paste(rb, collapse = " ")),
           all(c("0.582", "0.787", "0.440") %in% rb))
check_true("v61", "the matrix printed one row per group plus its header",
           !is.na(.int("kwadv_rb_matrix_rows")) && .int("kwadv_rb_matrix_rows") >= 3)
# AND THE FIGURE AND ITS FRAMES SURVIVED THE DRAW. The crash took the whole
# session, so "did anything reach disk" is a separate statement from "was the
# matrix printed": the abort happened between them.
check_true("v61", "the crash leg saved its figure and its frames",
           !is.na(.int("kwadv_artefacts")) && .int("kwadv_artefacts") >= 3)

# --- 3c. THE PRESET SURVIVED THE BEGINNER DRAW (D7) -------------------------
# One integer, for the reason in the header: the second banner can only exist
# if annotate was 1 at the commit, and on this journey nothing else could have
# put it back.
check("v61",
      "the report carries TWO analysis sections, not one (the bridge ran)",
      2L, if (!is.na(.int("kw_report_sections"))) .int("kw_report_sections") else -1L,
      tol = 0)
# A SECOND WITNESS, deliberately independent of the string match: a rename of
# the report banner would break the count above while leaving the behaviour
# correct, and the pair disagreeing is itself informative. 3178 bytes broken,
# 5022 fixed, measured 15 Aug 2026.
check_true("v61",
           sprintf("the report is the annotated size, not the bare one (%s bytes)",
                   s[["kw_report_bytes"]]),
           !is.na(.int("kw_report_bytes")) && .int("kw_report_bytes") > 4000)
# The bridge wipes the declaration on its way through and must re-declare, or
# the export drops to the legacy single file. Necessary, not sufficient --
# v51's section 3 makes the same point about the same procedure.
check_true("v61", "the annotated draw exported the broom frames",
           !is.na(.int("kw_tidy")) && .int("kw_tidy") >= 1)

# --- 3d. ONE ANALYSIS, HOWEVER MANY DRAWS (NEW-G8-3) ------------------------
check_true("v61",
           sprintf("the scatter leg pressed Draw more than once (%s redraws)",
                   s[["scatter_draws"]]),
           !is.na(.int("scatter_draws")) && .int("scatter_draws") >= 2)
check("v61",
      "no (table, analysis, term, field) key appears twice in the export",
      1L, if (!is.na(.int("scatter_max_dupe"))) .int("scatter_max_dupe") else -1L,
      tol = 0)
# THE ROW COUNT IS THE SECOND WITNESS and it is a different kind of statement:
# the multiplicity check would pass on an EMPTY file, and an empty file is what
# an over-eager reset produces. Two groups, nine fields each: 18.
check("v61", "and the export is the one analysis, whole", 18L,
      if (!is.na(.int("scatter_csv_rows"))) .int("scatter_csv_rows") else -1L,
      tol = 0)

# --- 3e. NO LEGEND FILE NOBODY ASKED FOR (D8) -------------------------------
check_true("v61",
           sprintf("the leg really did start from a Separate-figure config (%s)",
                   s[["legend_config_seed"]]),
           grepl("legendPlacement: 4", .str("legend_config_seed")))
check("v61", "a beginner save emits no _legend.png (D8)",
      0L, if (!is.na(.int("legend_files"))) .int("legend_files") else -1L, tol = 0)
# AND THE FIGURE WAS STILL SAVED. Emitting nothing at all would also score zero
# legend files, which is the trivial way to pass this check and a worse defect
# than the one it is here for.
check("v61", "and the figure itself was written", 1L,
      if (!is.na(.int("legend_pngs"))) .int("legend_pngs") else -1L, tol = 0)

# --- 3f. A BUTTON ROW THAT IS ON THE SCREEN (§6) ----------------------------
# The window manager clamps a dialog to the screen, so a height equal to the
# screen minus its border does not mean "it fits" -- it means the rest is off
# the bottom. Measured on a screen tall enough not to clamp it: 1065px before
# the row trim, 999px after, against 976px of usable height at 1000. This check
# is therefore EXPECTED TO FAIL until the advanced page is split, and it is
# written as an attest rather than a check so that it records the number
# without asserting a fix nobody has made yet.
attest("v61",
       sprintf(paste0("the advanced scatter dialog is %s px on a %s px screen ",
                      "-- still clamped; the split page is the open fix"),
               s[["scatter_adv_dialog_height"]], s[["screen_height"]]),
       "harness/graphseams/out/DIALOGS_scatter.tsv, measured 15 Aug 2026")

# --- 3g. THE ARTEFACTS -------------------------------------------------------
a <- file.path(gs, "ARTEFACTS_kw.tsv")
if (check_true("v61", "an artefact list was written for the KW leg",
               file.exists(a))) {
    art <- read.delim(a, header = FALSE, sep = "\t", quote = "",
                      stringsAsFactors = FALSE, fill = TRUE)
    nm <- trimws(as.character(art[[1]]))
    check_true("v61", "the figure was written", any(grepl("\\.png$", nm)))
    check_true("v61", "the report was written", any(grepl("_report\\.txt$", nm)))
    # ONE STAMP for the whole press, as everywhere else the panel writes.
    st <- regmatches(nm, regexpr("[0-9]{8}_[0-9]{6}", nm))
    check_true("v61",
               sprintf("every saved file shares one timestamp (%s)",
                       paste(unique(st), collapse = " | ")),
               length(unique(st)) == 1)
}

}

if (!exists("EML_SUITE")) {
    eml_report("v61 graphs seams: the crash, the preset, the duplicate block, the legend")
    eml_exit()
}
