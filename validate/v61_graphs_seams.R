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

# D6. THE THREE TYPES WITH NO ANNOTATION-LAYOUT MENU SAY SO.
# Histogram, GroupedViolin and GroupedBox force annotLayoutMode = 3 in the
# draw path, because a significance bracket has no pair of x positions to span
# on a histogram or a two-factor panel. The repair was not to add a menu -- a
# menu whose only honest entry is the one already in force is not a choice --
# it was to replace the absent field with the FACT, in a comment widget the
# user reads. Nothing else in the suite reads that sentence, so the page it
# sits on is checked as well as the count: a page that regained the menu and
# kept the sentence would be lying, and a page that lost the sentence is the
# finding back. Bounded by the enclosing beginPause .. endPause, which is the
# only page scope this form has.
.d6 <- grep("^\\s*comment: \"Comparisons appear as a matrix panel below the plot\\.\"\\s*$",
            fcode)
check("v61", "three pages state the forced matrix layout instead of offering a menu (D6)",
      3L, length(.d6), tol = 0)
.begins <- grep("^\\s*beginPause:", fcode)
.ends   <- grep("endPause:", fcode)
.d6bad <- vapply(.d6, function(i) {
    b <- .begins[.begins < i]; e <- .ends[.ends > i]
    if (!length(b) || !length(e)) return(TRUE)
    any(grepl("optionmenu: \"Annotation layout\"", fcode[max(b):min(e)], fixed = TRUE))
}, logical(1))
check_true("v61",
           sprintf("and each states it on a page that offers NO Annotation layout menu (%d of %d clean)",
                   sum(!.d6bad), length(.d6)),
           length(.d6) > 0 && !any(.d6bad))

# ---------------------------------------------------------------------------
# 2a. D5 -- THE ADJUSTMENT MENU IS GONE FROM THE PARAMETRIC ARM (RULING 1a)
# ---------------------------------------------------------------------------
# WHAT THIS SECTION USED TO SAY, and why it does not say it any more.
#
# Until 15 August 2026 this file held ONE check here: that all six dialogs
# offering the menu qualified its label with "(nonparametric post-hoc only)".
# The reasoning was that the audit had measured a Tukey draw md5-identical
# under Holm and under Bonferroni while the Dunn arm honoured the same menu;
# that the statistics agree with the code, because Tukey's p comes from the
# studentized range and is already family-wise, so a Holm or Bonferroni step
# on top would DOUBLE-correct; and that with nothing honest for the menu to do
# on that arm, the label was the entire defence -- one string, worth pinning
# against a tidy-up that would have dropped it as clutter. That comment ended
# by naming what would overturn it: "IF IAN RULES OTHERWISE -- disable the
# field on the parametric arm ... this check is the first thing to revisit. It
# asserts a disclosure, not a behaviour."
#
# RULING 1a, 15 August 2026, is that ruling. The statistics were accepted and
# the remedy was not: a live-looking control that is silently ignored is the
# same class of defect as D11's group-column fields, which stayed editable
# while their tickbox was clear and were then thrown away at the commit. That
# was fixed by GATING the fields, and this is fixed the same way. So the pin
# changes with the behaviour: the label check stays, because the label is
# still on the arm that still reads it and is now simply TRUE, but it is no
# longer the defence. THE GATE IS.
#
# WHAT THE FAILURE LOOKS LIKE, in both directions, because this is a fix that
# can fail two ways and only one of them is loud:
#
#   THE FIELD COMES BACK on a parametric page and is ignored again. Silent:
#   the figure is correct, the number is correct, and the user has been shown
#   a control that does nothing. That is the defect this closes.
#
#   THE READ COMES BACK WITHOUT THE FIELD. Praat does not delete a pause
#   variable when the field goes away -- it keeps the value the last dialog
#   that HAD the field left in it. So an ungated read does not abort; it
#   silently commits a stale adjustment method from a different graph type,
#   possibly from earlier in the same session. That failure is worse than the
#   one being fixed and it is even quieter, which is why the checks below
#   count the reads and the gates SEPARATELY.
#
# WHAT COULD NOT HAVE CAUGHT EITHER.
#
#   * A NUMERIC VALIDATOR, again, and more completely than usual: the whole
#     finding is that the number does NOT move. v09's Tukey p is identical
#     under every adjustment setting and that is the correct behaviour; the
#     defect was entirely in what the dialog implied about it.
#
#   * harness/gui_adv AND v51. Their advanced journey is PARAMETRIC and
#     two-group, so it never reaches a k >= 3 post-hoc at all, and a two-group
#     comparison has no multiplicity to adjust. The page they drive shows the
#     menu and neither of them looks at it.
#
#   * A SCREENSHOT ON ITS OWN. harness/graphseams/adjustarm.sh takes two, and
#     they are in the artefact set because a person should be able to look --
#     but a picture cannot say whether the value was READ, and reading a field
#     that is not on the screen is the failure above.
#
# WHAT SEPARATES THEM NOW: there is one control, so there is nothing to gate.
# The family and its correction are two outputs of one chosen row, and the row
# is on every one of the six dialogs unconditionally. A gate variable existed
# to answer "was the correction field even built"; with the row always built,
# the question has no content and the checks below assert the shape that
# replaced it instead.
#
# SIX MENUS, ONE PER ANNOTATE-CAPABLE PAGE. A seventh would be a page that
# grew one outside the registry; a fifth would be a page that lost the ability
# to choose a test at all.
check("v61", "the comparison menu stands on six dialogs and no more",
      6L, sum(grepl('optionmenu: "Comparison"', fcode)), tol = 0)

# AND EVERY ONE OF THEM IS THE SHARED LIST. The rows come from one procedure,
# so a page cannot quietly offer a different set of tests from its siblings --
# which is what six hand-copied option blocks would eventually become.
.menuAt <- grep('optionmenu: "Comparison"', fcode)
.rowsAt <- grep("^\\s*@emlComparisonMenuRows\\s*$", fcode)
check("v61", "every comparison menu draws its rows from the one registry",
      6L,
      sum(vapply(.menuAt, function(i) any(.rowsAt == i + 1), logical(1))),
      tol = 0)

# AND EVERY ONE IS SEEDED FROM WHAT THE PAGE LAST USED, through the inverse of
# the same registry. A page seeded any other way would open on a row that does
# not match the figure it last drew.
check("v61", "and every menu is seeded through the inverse map",
      6L, sum(grepl("^\\s*@emlComparisonToMenu:", fcode)), tol = 0)

# THE REGISTRY IS SINGULAR. Three procedures, defined once each. Two
# definitions of the forward map is how the six pages drift apart again.
check("v61", "the comparison registry is defined exactly once",
      3L,
      sum(grepl("^procedure emlComparisonMenuRows\\s*$", fcode)) +
      sum(grepl("^procedure emlComparisonFromMenu:", fcode)) +
      sum(grepl("^procedure emlComparisonToMenu:", fcode)),
      tol = 0)

# THE HEADER GUARD, ON EVERY PAGE. The list carries category headings as rows,
# because Praat has no other way to group a menu, so a user can land on one.
# Six guards, and each one refuses only the Draw button -- refusing the
# toggle would trap a user who wanted to switch modes.
check("v61", "six pages refuse a category heading",
      6L, sum(grepl("^\\s*if emlComparisonFromMenu\\.isHeader = 1\\s*$", fcode)),
      tol = 0)

# AND THE REFUSAL CANNOT DRAW. The guard clears the button value; a bare
# `else` on the dispatch would catch that cleared value and draw anyway, which
# is a refusal that prints its message and then does the thing it refused.
# Naming the Draw arm is what makes the refusal real, so the count of named
# arms is pinned to the count of guards.
# Stated as the absence of the hazard, and scoped to the pages that carry the
# guard. A page without a comparison menu may end its dispatch with a bare
# `else` safely -- nothing clears its button value. A page WITH one may not:
# the cleared value would fall into that else and draw the figure the guard
# just refused. So for each guard, the first draw below it must sit on a
# named arm.
.guardAt <- grep("^\\s*if emlComparisonFromMenu\\.isHeader = 1\\s*$", fcode)
.doneAt  <- grep("^\\s*\\w+FormDone = 1\\s*$", fcode)
check("v61", "and no guarded page starts its draw from a bare else",
      0L,
      sum(vapply(.guardAt, function(g) {
          after <- .doneAt[.doneAt > g]
          if (!length(after)) return(FALSE)
          # the draw arm is the LAST done-flag in this page's dispatch, since
          # "Go Back" sets one too and sits above it
          d <- after[min(2L, length(after))]
          grepl("^\\s*else\\s*$", fcode[d - 1])
      }, logical(1))),
      tol = 0)

# NOTHING READS THE RETIRED FIELDS. `test_type` and `adjustment_method` were
# the two controls' variables. Praat cannot unset a form variable, so a read
# left behind would return whatever the last dialog that had the field set,
# silently -- the exact failure the one-control shape removes.
check("v61", "no page reads the retired two-control fields",
      0L,
      sum(grepl("\\btest_type\\b", fcode)) +
      sum(grepl("\\badjustment_method\\b", fcode)) +
      sum(grepl("\\badjustOffered\\b", fcode)),
      tol = 0)

# THE FAMILY IS RESOLVED FROM THE ROW, NEVER RE-DERIVED. The subtlety this
# records: a page that decided the family by testing its own remembered
# test-type variable would be testing a value written from the row a moment
# earlier on three of the six pages, and a value one press old on the others.
# One resolution per commit, from the menu row, is what keeps the family and
# the correction in step.
.resolveAt <- grep("^\\s*@emlComparisonFromMenu:", fcode)
check("v61",
      "the family is resolved from the chosen row at every site that needs it",
      TRUE,
      length(.resolveAt) >= 12L)
check("v61",
      "and no commit re-derives it from a remembered test-type variable",
      0L,
      sum(grepl("^\\s*if (tmp\\w*TestType|prev_\\w*AnnotTestType) = 2\\s*$",
                fcode[unlist(lapply(.resolveAt,
                                    function(i) i:min(length(fcode), i + 6)))])),
      tol = 0)

# ---------------------------------------------------------------------------
# 2b. NO RAW fixed$ REACHES THE INFO WINDOW FROM THIS FILE
# ---------------------------------------------------------------------------
# HOUSE RULE, 15 August 2026: statistics print at fixed decimals, p in APA
# style, and no raw double reaches the Info window; full precision belongs to
# the CSV export. `fixed$` is not a fixed-precision formatter -- it prints
# max (precision, -floor (log10 |v|)) decimals, so it ESCALATES silently on
# small magnitudes, and it returns a bare "0" for exact zero. A sibling sweep
# found seven call sites in this file. All seven were `appendInfoLine:`
# arguments -- Info-window output, not figure text -- so all seven are in
# scope, and all seven now go through @eml_fixed, which lives in
# stats/eml-output.praat and is the one implementation.
#
# THE CHECK READS CODE, NOT COMMENTS, and that is not incidental. The fix left
# two comment blocks that explain the rule and therefore contain the string
# `fixed$` several times; a check written against the raw file would match the
# COMMENT EXPLAINING THE FIX and pass on a file where the fix had been
# reverted and the comment left behind. `.code()` strips comment lines before
# any of this runs, which is why the expected count is exactly zero rather
# than a threshold someone tuned until it passed.
check("v61", "no raw fixed$ call survives in the graphs form",
      0L, sum(grepl("(^|[^_[:alnum:]])fixed\\$", fcode)), tol = 0)
check("v61", "and the seven sites go through @eml_fixed instead",
      7L, sum(grepl("@eml_fixed:", fcode)), tol = 0)
# AND THE PROCEDURE EXISTS WHERE IT IS CALLED FROM. A call to a procedure
# Praat cannot find is a RUN-time abort, not a parse error, and these seven
# sit on diagnostic branches that a happy-path drive never enters -- so a
# rename would go unnoticed until a user with a crowded legend met it. The
# file is read here rather than reusing section 3's copy because that one is
# loaded further down, and a check that depends on the order of two unrelated
# sections is a check waiting to be moved.
.outp <- Sys.getenv("EML_OUTPUT_FILE", unset = "")
if (!nzchar(.outp)) .outp <- repo_path(file.path("plugin", "stats",
                                                 "eml-output.praat"))
check_true("v61", "and @eml_fixed is defined in eml-output",
           any(grepl("^procedure eml_fixed:", .code(.outp))))

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

# ---------------------------------------------------------------------------
# 4. THE ADJUSTMENT MENU, DRIVEN ON BOTH ARMS (RULING 1a)
# ---------------------------------------------------------------------------
#     bash harness/graphseams/adjustarm.sh
#
# Two legs from one driver, differing in ONE seeded value -- the arm. Same
# graph type, same table, same columns, same advanced mode, same presets. A
# pair like that is the only arrangement in which a difference in the dialog
# can be attributed to the arm; two separately written legs would leave every
# difference arguable.
ad <- Sys.getenv("EML_ADJUST_DIR", unset = "")
if (!nzchar(ad)) ad <- repo_path(file.path("harness", "graphseams", "adjust_out"))
haveAdj <- check_true("v61",
                      "the adjustment-arm artefact exists (bash harness/graphseams/adjustarm.sh)",
                      dir.exists(ad) && file.exists(file.path(ad, "ADJUSTARM.tsv")))
if (haveAdj) {
    aa <- .kv(file.path(ad, "ADJUSTARM.tsv"))
    .a <- function(k) { v <- aa[[k]]; if (is.null(v)) "" else as.character(v) }
    .ai <- function(k) suppressWarnings(as.integer(.a(k)))

    # 4a. THE RUN WAS THE EXPERIMENT IT CLAIMS TO BE. Checked before anything
    # is concluded from it, for the reason section 3a gives: if the preset
    # failed to apply, both legs took the SAME arm, agreed with each other,
    # and proved nothing. The arm each leg actually took is read back out of
    # the form, not assumed from the leg's name.
    check_true("v61", "the nonparametric leg really took the Dunn arm",
               .a("nonparametric_testtype") == "nonparametric")
    check_true("v61", "and the parametric leg really took the Tukey arm",
               .a("parametric_testtype") == "parametric")
    # AND BOTH WERE ANNOTATING. An unannotated draw never reaches a post-hoc
    # at all, so the adjustment method would be moot on both arms and the two
    # legs would agree for a reason that has nothing to do with the fix.
    check("v61", "both legs were annotating", 2L,
          sum(c(.ai("nonparametric_annotate"), .ai("parametric_annotate")) == 1L,
              na.rm = TRUE), tol = 0)
    # AND BOTH COMPLETED. The failure mode of an ungated read is not an abort
    # -- Praat keeps a stale pause variable -- but the failure mode of a
    # MIS-gated one is, so the run is asked whether it survived before it is
    # asked what it decided.
    check("v61", "neither leg died on an undefined variable", 0L,
          sum(c(.ai("nonparametric_unknown_variable"),
                .ai("parametric_unknown_variable")), na.rm = TRUE), tol = 0)
    check("v61", "and each leg drew and saved exactly one figure", 2L,
          sum(c(.ai("nonparametric_pngs"), .ai("parametric_pngs")) == 1L,
              na.rm = TRUE), tol = 0)

    # 4b. THE GATE. One integer per arm, read out of the form after the last
    # commit, so it is the value that actually decided whether
    # adjustment_method was read back.
    check("v61", "the Dunn arm still offers the adjustment menu", 1L,
          .ai("nonparametric_offered"), tol = 0)
    check("v61", "and the Tukey arm does not (RULING 1a)", 0L,
          .ai("parametric_offered"), tol = 0)

    # 4c. THE SECOND WITNESS, AND IT KNOWS NOTHING ABOUT THE FIRST. The
    # Column Mapping page's height in pixels, measured from the window
    # manager. The hole this closes is specific: a "fix" that set the flag to
    # 0 and left the optionmenu on the dialog would report 4b perfectly and
    # still be showing the user a dead control. Two arms of the same page with
    # the same height have the same rows on them, whatever the flag says.
    #
    # THE SCREEN IS 1400px TALL IN THAT RIG, NOT 1000. A window manager clamps
    # a dialog to the screen, so on the 1000px display run.sh uses -- which is
    # 1000px because the §6 clipping finding is about a 1000px display -- both
    # arms would report the same clamped number and this witness would be dead
    # while looking alive.
    #
    # MEASURED 15 Aug 2026: 918 px nonparametric, 923 px parametric. The
    # parametric arm is the TALLER of the two by five pixels, which is not
    # what one expects from removing a row and is worth writing down: a Praat
    # `comment:` spans the full dialog width and is a slightly taller row than
    # the optionmenu it replaced. Five pixels on a page that fits is a cost
    # worth paying for a control that is not a lie; it is recorded rather than
    # asserted at a particular value, because the number belongs to a GTK
    # theme and would make this check a tripwire for the sandbox.
    check_true("v61",
               sprintf(paste0("the two arms are not the same dialog ",
                              "(%s px nonparametric, %s px parametric)"),
                       .a("nonparametric_dialog_height"),
                       .a("parametric_dialog_height")),
               !is.na(.ai("nonparametric_dialog_height")) &&
               !is.na(.ai("parametric_dialog_height")) &&
               .ai("nonparametric_dialog_height") > 0 &&
               .ai("parametric_dialog_height") !=
                   .ai("nonparametric_dialog_height"))

    # 4d. THE CONSEQUENCE. On the parametric arm the page must not write
    # annotCorrectionMethod$ AT ALL, so the bridge must still be handed the
    # file-scope default. This is a different statement from 4b: a page could
    # set the flag, drop the field, and still commit a value from some other
    # source, and the bridge would be told a method the user never chose.
    check_true("v61",
               sprintf("the Tukey arm left the correction untouched (%s)",
                       .a("parametric_correction")),
               .a("parametric_correction") == "holm")
    # AND THE DUNN ARM STILL DELIVERS ONE. Zero on both arms would pass the
    # check above and would mean the menu had stopped working on the arm that
    # reads it -- the opposite defect, and the one that changes a number.
    check_true("v61",
               sprintf("and the Dunn arm still delivers one (%s)",
                       .a("nonparametric_correction")),
               .a("nonparametric_correction") %in%
                   c("holm", "bonferroni", "bh"))
}

# ---------------------------------------------------------------------------
# 5. THE RECORDED AXIS: A CHOICE, OR ONE DATASET'S ANSWER? (RULING 10)
# ---------------------------------------------------------------------------
#     bash harness/graphseams/axischoice.sh
#
# RULING 10, 15 August 2026. A recorded draw step must carry the user's axis
# CHOICE. If the user left the axis on auto, the emitted call must say auto
# and let the draw resolve the range from the data at replay time; if the user
# typed a range, it must come back as variables in the emitted script's
# editable header block, referenced by the call, so that the one place a user
# edits for new data is still the top block.
#
# BOTH HALVES OF THAT RULING ARE NOW MET, AND THIS SECTION CHECKS THEM RATHER
# THAN ATTESTING THEM. Until 17 August 2026 sections 5d and 5e below were
# `attest` calls -- measured numbers recorded WITHOUT an assertion, because the
# files that had to change were not that pass's to edit. They have since
# changed: @emlRecordViolin in plugin/graphs/eml-draw-procedures.praat routes
# the axis through @emlRecordAxisRequest so the recorded call carries the
# REQUEST, and @emlRecordAxisNote publishes the resolved range for the header
# block, where @emlRecordColumnManifest declares `axisYMin` / `axisYMax` beside
# the column names. The call now names those variables in both cases. So the
# attestations became assertions on the same pass that re-drove the rig; an
# attestation left standing over repaired numbers stops being stale and starts
# being false.
#
# WHY IT MATTERS. The recorded script is the plugin's retargeting surface --
# the whole editable header block exists so that one edit re-points the
# workflow at other data. A frozen frame means the statistics recompute
# honestly on the new table while the FIGURE stays at the original table's
# extent: clipped, or swimming.
#
# WHAT THE FAILURE LOOKED LIKE, AND WHAT THE RIG SHOWS NOW. Silent, and
# spectacularly so. Measured 15 Aug 2026: a violin recorded on auto over data
# spanning 194.5 .. 248.5 emitted `..., 180.000000, 270.000000`; replayed
# against a table spanning 1083.6 .. 1245.5 it drew a titled, labelled,
# tick-marked, gridded frame with ALL ONE HUNDRED POINTS off the top of it and
# no warning anywhere -- 52,758 bytes of PNG with no ink inside the frame.
# Re-driven 17 Aug 2026 against the repaired tree, the same leg emits
# `..., groupCol$, valueCol$, axisYMin, axisYMax`, resolves 1000 .. 1300 on the
# retargeted table, and leg3.png is now 83,869 bytes and BYTE-IDENTICAL to
# leg4.png, the native auto draw of that table. Both PNGs are in
# harness/graphseams/axis_out/ and the pair is still worth opening: the old one
# is what a frozen frame looks like, and it is not subtle.
#
# WHAT COULD NOT HAVE CAUGHT IT.
#
#   * harness/record/roundtrip_graph.sh, which is the closest thing that
#     existed and is a good rig. It records a figure, replays the emitted
#     script and compares the two PNGs byte for byte -- ON THE SAME DATA. A
#     baked-in axis is exactly right on the same data. The comparison it makes
#     is the one this defect cannot fail.
#
#   * EVERY VALIDATOR THAT READS A NUMBER. Nothing computed moves. The
#     statistics in the replayed script recompute correctly on the new table;
#     it is only the frame that does not follow them, and no report, no CSV
#     and no tidy frame carries the frame.
#
#   * A ONE-LEGGED RETARGET TEST. This is the subtle one and it is why the rig
#     has four legs and then four more. "The axis did not change" is not a
#     finding on its own -- it is also what a correct emitter reports when the
#     retargeted data happens to resolve to the same range. The ANSWER KEY is
#     a NATIVE auto draw of the retargeted table: what the user would have got
#     from the form. Leg 3 must equal that, not merely differ from leg 1.
#
# WHAT SEPARATES THEM: the axis the replay RESOLVED, read back out of the draw
# procedure that drew it, against the axis the native draw resolved. And the
# emitted call itself, counted for bare decimal literals in its numeric tail:
# `0, 0` is the auto sentinel and is not a resolved literal.
ax <- Sys.getenv("EML_AXIS_DIR", unset = "")
if (!nzchar(ax)) ax <- repo_path(file.path("harness", "graphseams", "axis_out"))
haveAx <- check_true("v61",
                     "the axis-choice artefact exists (bash harness/graphseams/axischoice.sh)",
                     dir.exists(ax) && file.exists(file.path(ax, "AXIS.tsv")))
if (haveAx) {
    x <- .kv(file.path(ax, "AXIS.tsv"))
    .x <- function(k) { v <- x[[k]]; if (is.null(v)) "" else as.character(v) }
    .xn <- function(k) suppressWarnings(as.numeric(.x(k)))
    .xi <- function(k) suppressWarnings(as.integer(.x(k)))

    # 5a. THE RUN WAS THE EXPERIMENT IT CLAIMS TO BE. The retargeted table has
    # to be genuinely somewhere else, or "the frame did not follow" is a claim
    # about two ranges that overlap and nobody could tell apart. DISJOINT is
    # the requirement, and it is asserted rather than assumed: the fixtures
    # are generated in the harness and a later edit could quietly move them
    # together, at which point every check below would pass on a rig that had
    # stopped testing anything.
    check_true("v61",
               sprintf(paste0("the retargeted table is disjoint from the ",
                              "original (%s..%s vs %s..%s)"),
                       .x("leg1_data_lo"), .x("leg1_data_hi"),
                       .x("leg3_data_lo"), .x("leg3_data_hi")),
               !is.na(.xn("leg1_data_hi")) && !is.na(.xn("leg3_data_lo")) &&
               .xn("leg3_data_lo") > .xn("leg1_data_hi"))
    # AND THE ANSWER KEY IS NOT THE ORIGINAL AXIS. If a native auto draw of
    # the retargeted table resolved to the same range as the original, the
    # frozen and the correct figure would be the same figure and the whole
    # rig would be blind.
    check_true("v61",
               sprintf("and a native auto draw of it resolves elsewhere (%s..%s vs %s..%s)",
                       .x("leg1_axis_lo"), .x("leg1_axis_hi"),
                       .x("leg4_axis_lo"), .x("leg4_axis_hi")),
               !is.na(.xn("leg4_axis_lo")) &&
               (.xn("leg4_axis_lo") != .xn("leg1_axis_lo") ||
                .xn("leg4_axis_hi") != .xn("leg1_axis_hi")))

    # 5b. THE SAME-DATA LEG. The ruling names it, and it is the leg that
    # protects the numbers: a change that makes the frame follow the data is
    # worthless if it also makes the frame WANDER on data that did not change.
    # Byte for byte, because the same procedure on the same data at the same
    # viewport on the same build has no licence to differ at all.
    check("v61",
          sprintf("the emitted script reproduces its own figure exactly (%s bytes)",
                  .x("leg1_png_bytes")),
          1L, .xi("same_data_identical"), tol = 0)
    # AND THE FIGURE IT REPRODUCES HAS ITS DATA ON IT. Byte-equality alone is
    # the trivially-passing kind of check: two blank pages are byte-identical
    # too, and an over-eager axis is exactly what produces one. The first
    # draft of this pair guarded that with a FILE SIZE THRESHOLD, and the rig
    # itself disproved it -- leg3.png is a completely empty frame and weighs
    # 52 KB, comfortably over any threshold anyone would have picked. Size
    # does not distinguish a figure from a frame. Containment does: the axis
    # the recorded figure resolved must bracket the data it was resolved from,
    # which is what having the violins on the page MEANS.
    check_true("v61",
               sprintf(paste0("and its axis holds its data, so it is a figure ",
                              "and not a frame (%s..%s over %s..%s)"),
                       .x("leg1_axis_lo"), .x("leg1_axis_hi"),
                       .x("leg1_data_lo"), .x("leg1_data_hi")),
               !is.na(.xn("leg1_axis_lo")) && !is.na(.xn("leg1_data_lo")) &&
               .xn("leg1_axis_lo") <= .xn("leg1_data_lo") &&
               .xn("leg1_axis_hi") >= .xn("leg1_data_hi"))

    # 5c. THE RETARGETED LEG, ON A RECORDER THAT ALREADY HONOURS THE RULING.
    # This is the POSITIVE CONTROL and it is the most useful thing the rig
    # found. The box plot's recorder is a plain @emlRecordDrawStep and builds
    # its call from `string$ (.vMin)` -- the REQUEST -- so a user's auto is
    # emitted as `0, 0` and the replay resolves the range from whatever table
    # it is pointed at. Measured 15 Aug 2026: recorded on data spanning
    # 194.5..248.5 at an axis of 180..260, replayed on the retargeted table it
    # resolved 1060..1280 and drew a figure BYTE-IDENTICAL to a native auto
    # draw of that table.
    #
    # Without this leg, section 5d below would be a check that cannot go green
    # for the right reason: it could not distinguish "the emitter cannot emit
    # auto" from "the rig cannot detect a rescale".
    check("v61",
          "a box plot recorded on auto emits no resolved literals (RULING 10a)",
          0L, .xi("box_call_literals"), tol = 0)
    check("v61",
          sprintf(paste0("and its replay rescales to the retargeted data ",
                         "(%s..%s, native %s..%s)"),
                  .x("leg7_axis_lo"), .x("leg7_axis_hi"),
                  .x("leg8_axis_lo"), .x("leg8_axis_hi")),
          1L, .xi("box_retarget_matches_native"), tol = 0)

    # 5d. THE VIOLIN, WHICH WENT ITS OWN WAY AND HAS BEEN BROUGHT BACK
    #     (RULING 10a).
    #
    # The emission is @emlRecordViolin in
    # plugin/graphs/eml-draw-procedures.praat. It built its .code$ from
    # `fixed$ (emlDrawViolinPlot.yMin, 6)` -- the RESOLVED axis -- rather than
    # from its own .vMin argument, which is the request; every other draw
    # recorder in the plugin already used the request, so it was one procedure
    # out of step rather than a policy the plugin held. It now routes both ends
    # through @emlRecordAxisRequest and publishes the resolved pair through
    # @emlRecordAxisNote, so the call carries the request and the header block
    # carries the range.
    #
    # FOUR STATEMENTS, KEPT APART, because "the emitted file mentions auto
    # somewhere" is not the claim and never was:
    #
    #   the CALL carries no resolved literal      auto_call_literals
    #   the HEADER BLOCK declares the axis pair   auto_hdr_axis
    #   the resolved range is still WRITTEN DOWN  auto_resolved_comment
    #   the REPLAY rescales, against the answer   retarget_matches_native
    #     key rather than merely against leg 1
    #
    # The third is not decoration. The resolved numbers are what a reader needs
    # to know what the recorded figure actually looked like; moving them out of
    # the call would have LOST them if they were not put somewhere, and the
    # somewhere is the @emlRecordResult comment beside the step. A fix that
    # drops the record is a different defect, not this one repaired.
    check("v61",
          sprintf("a violin recorded on AUTO emits no resolved literals (RULING 10a): %s",
                  .x("auto_call_tail")),
          0L, .xi("auto_call_literals"), tol = 0)
    check("v61",
          "and the emitted script declares axisYMin/axisYMax in its header block",
          2L, .xi("auto_hdr_axis"), tol = 0)
    check("v61",
          "and still records what the range RESOLVED to, beside the step",
          1L, .xi("auto_resolved_comment"), tol = 0)
    # THE REPLAY, AGAINST THE ANSWER KEY. leg3 is the emitted script run on the
    # retargeted table; leg4 is a native auto draw of that same table. Byte
    # equality of the two PNGs is the statement, for the reason 5a gives: "the
    # axis changed" is not a finding on its own.
    check("v61",
          sprintf(paste0("and its replay on retargeted data rescales to the ",
                         "native draw (%s..%s over data %s..%s, native %s..%s)"),
                  .x("leg3_axis_lo"), .x("leg3_axis_hi"),
                  .x("leg3_data_lo"), .x("leg3_data_hi"),
                  .x("leg4_axis_lo"), .x("leg4_axis_hi")),
          1L, .xi("retarget_matches_native"), tol = 0)
    # AND THE RETARGETED FIGURE HAS ITS DATA ON IT. The same containment 5b
    # applies to leg 1, applied to the leg that used to fail: an axis that
    # brackets its data is what having the violins on the page MEANS, and the
    # frozen frame -- 180..270 over data at 1083..1245 -- failed exactly this.
    check_true("v61",
               sprintf("and that axis holds the retargeted data (%s..%s over %s..%s)",
                       .x("leg3_axis_lo"), .x("leg3_axis_hi"),
                       .x("leg3_data_lo"), .x("leg3_data_hi")),
               !is.na(.xn("leg3_axis_lo")) && !is.na(.xn("leg3_data_lo")) &&
               .xn("leg3_axis_lo") <= .xn("leg3_data_lo") &&
               .xn("leg3_axis_hi") >= .xn("leg3_data_hi"))

    # 5e. THE EXPLICIT RANGE (RULING 10b), ALSO CLOSED.
    # A user who TYPED a range gets it back as `axisYMin = 150` in the emitted
    # script's editable header block, referenced by the call. The lift is
    # @emlRecordColumnManifest in plugin/stats/eml-record.praat, which used to
    # lift QUOTED literals only -- it is table-driven by argument position and
    # a numeric argument is not a quoted one -- and now carries the axis pair
    # alongside the column names.
    #
    # THREE PARTS, AND EITHER OF THE FIRST TWO ALONE IS THE DEFECT WEARING THE
    # FIX'S CLOTHES: a header variable nothing reads is a dead preset channel,
    # which is the D4 shape this same file pins in section 2; a call naming a
    # variable nobody declares does not parse at all. The third is placement --
    # a declaration BELOW the first step is not in the editable block, and the
    # block is the whole contract, since it is the one place ruling 9 asks a
    # user to edit.
    check("v61",
          sprintf("a typed range comes back as axisYMin in the header block (RULING 10b): %s",
                  .x("expl_call_tail")),
          1L, .xi("expl_hdr_min"), tol = 0)
    check("v61", "and axisYMax with it",
          1L, .xi("expl_hdr_max"), tol = 0)
    check("v61", "and the draw call references the two variables, not the numbers",
          1L, .xi("expl_call_refs_vars"), tol = 0)
    check("v61", "and the declaration is inside the editable block, above step 1",
          1L, .xi("expl_hdr_in_block"), tol = 0)
}

if (!exists("EML_SUITE")) {
    eml_report("v61 graphs seams: the crash, the preset, the duplicate block, the legend, the adjustment arm, the recorded axis")
    eml_exit()
}
