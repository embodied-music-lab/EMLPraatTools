# ============================================================================
# v112_settings_census.R -- every setting the draw layer reads is classified
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# WHAT THIS IS FOR.
#
# Drawing a figure is going to stop recomputing an analysis it has already
# run, and reuse the stored result instead. Two questions decide whether the
# stored result still holds. "Did the DATA change" is the per-group
# fingerprint of RULING_RESULT_STORE.md section (a), which is built. "Did the
# SETTINGS change" is this file.
#
# The ruling's section (b) is the contract: two lists, DECLARED AS DATA in one
# place rather than as comments -- the settings that change the computed
# result, and the settings that only change how it looks -- and a validator
# that asserts every setting the bridge reads is in exactly one of them. A
# setting in neither is RED, because an unclassified setting is one the graph
# door will silently treat as harmless: change it, get the old numbers back,
# and be told nothing.
#
# IT IS A DERIVATION, AND THAT IS THE WHOLE POINT.
#
# The obvious way to write this file is to open the graphs dialog, read the
# controls off it, and type them in. That produces a list that is wrong in two
# directions at once, and both of them have already happened in this tree.
#
#   THE DIALOG MOVES. The graph pages were regrouped twice on 24 August 2026:
#   pages merged, fields renamed, ranges folded into paired rows. Every
#   regrouped page now carries a REMAP block whose entire job is to copy the
#   label-derived names back onto the names the drawing code reads, expressly
#   so the dialog can keep moving while those names stay put
#   (RULING_DIALOG_COMPACTION section 1). The draw layer is the stable layer.
#   A census keyed on the dialog would be re-typed every time a field was
#   renamed; keyed on the draw layer it survives the rename by construction.
#
#   A DIALOG-DERIVED LIST MISSES SETTINGS WITH NO CONTROL. emlGroupSortAlpha-
#   betical has no field of its own anywhere. The graphs form sets it from
#   config_groupSort, it is declared as a default in stats/eml-extract.praat,
#   and @emlCountGroups reads it -- so it reaches every group comparison the
#   bridge runs and no dialog sweep would ever have found it. It is
#   result-affecting, and it is not one of the three controls the ruling
#   counted: measured on a two-group table (harness/settings/out/SETTINGS.tsv)
#   it turns "Welch t: t(10.0) = 12.25 ... d = 7.07" over groups Zebra|Alpha
#   into "t(10.0) = -12.25 ... d = -7.07" over groups Alpha|Zebra. Sign and
#   names together. This file finds it by walking the code, not by being told.
#
# HOW THE POPULATION IS DERIVED. Two doors compute a result at DRAW time, and
# the ruling names both: @emlBridgeGroupComparison, which runs the t-test,
# Mann-Whitney, ANOVA, Kruskal-Wallis, Tukey and Dunn behind a figure's
# brackets, and @emlDrawScatterPlot, which computes r and p from
# annotCorrType$ on the way past. From each door:
#
#   * its DECLARED PARAMETERS are settings -- that is how the form hands
#     alpha, the test type and the layout in. They are named <door>.<param>,
#     which is also how Praat itself would address them.
#   * every GLOBAL its transitive @-call closure READS is a candidate. A
#     candidate is kept when the plugin ASSIGNS it somewhere (so it is a
#     variable of this plugin and not a word of the Praat language -- `if`,
#     `min`, `fixed$` and `selectObject` are never assigned) and when NOTHING
#     IN THE DOORS' OWN CLOSURE assigns it (so it arrives from outside rather
#     than being the door's own output or scratch -- annotBracketP and
#     annotMatrixN are what the analysis PRODUCES, not settings fed into it).
#
# The walk is the same shape as v107's call-graph walk and v111's population
# read. It lives in this file rather than in helpers.R for the reason v107's
# walk lived in v107 until v111 needed it: one consumer, one place. The day a
# second validator needs this population it moves to helpers.R, whole.
#
# WHAT THE WALK CANNOT SEE, said plainly rather than left to be discovered.
# Double-quoted strings are blanked before identifiers are read, so a global
# named only inside a string literal -- `variableExists ("annotAlpha")` -- is
# invisible to it. Every such name in the tree is also read unquoted on the
# next line or two, which is why the population is not short of them; but a
# setting reachable ONLY through `'name$'` interpolation built at run time
# would be missed, and no static reader of Praat can do better.
#
# THE RATCHET RUNS BOTH WAYS. A newly read setting that neither list names is
# RED -- the day the draw layer starts reading it, not the day a figure comes
# back with stale numbers. A classification whose setting the draw layer no
# longer reads is ALSO RED, so the lists cannot outlive what they describe. A
# stale entry is the failure this family exists to prevent and it would be
# ironic to build one in (v107's KNOWN_SILENT, v111's KNOWN_BRANCHES).
#
# IT REFUSES TO PASS VACUOUSLY. Every assertion below is of the form "for
# every setting in the population ...", and every one of them is true of an
# empty population -- which is what a renamed door, or a walk that silently
# stopped resolving, produces. So section 4 is a resolver gate: it FAILS on a
# population of zero and it REPORTS THE COUNTS -- how many settings were
# walked, how many are result-affecting, how many display-only, how many
# unclassified -- because a number can be audited against itself and "looks
# fine" cannot.
#
# THE RED DEMONSTRATION is harness/settings/seed_violation.sh: a COPY of the
# shipped plugin with one extra global read into the scatter's correlation
# block and declared nowhere in either list, audited by this file unmodified
# through $EML_SETTINGS_SRC -- the same variable harness/settings/run.sh
# takes. What goes red is this check, not a rehearsal of it.
#
# THE CLASSIFICATION IS MEASURED WHERE READING WOULD BE A GUESS.
# harness/settings/run.sh runs the group-comparison door twice per setting,
# changing one setting between the runs, and writes down what came out.
# Section 6 holds this file to that evidence in the one direction the evidence
# supports: a setting whose RESULT keys moved MUST be in the result-affecting
# list. A setting whose keys held still proves nothing -- it is one negative
# on one table -- and is not used to lower anything.
#
# Base R only. Reads source and one measured artefact; drives nothing.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

V <- "v112"

if (!exists("check_true")) source(file.path(
    Sys.getenv("EML_VALIDATE_DIR", unset = "validate"), "helpers.R"))

# $EML_SETTINGS_SRC points the POPULATION half of this file at a tree other
# than the shipped one. No drive is needed for the red demonstration, because
# the population is read from source.
# It names a REPOSITORY ROOT, not a plugin folder -- the same thing
# harness/settings/run.sh takes, so the seeding script sets one variable and
# both ends follow it.
src <- Sys.getenv("EML_SETTINGS_SRC", unset = "")
plug <- if (nzchar(src)) {
    file.path(src, "plugin_EML_StatsGraphs")
} else {
    repo_path("plugin_EML_StatsGraphs")
}

# The measured artefact, from the same variable run.sh writes to.
measured <- Sys.getenv("EML_SETTINGS_OUT", unset = "")
if (!nzchar(measured))
    measured <- repo_path("harness", "settings", "out", "SETTINGS.tsv")

# ---------------------------------------------------------------------------
# THE DOORS. Named here and asserted to exist, because a renamed door does not
# make this file complain -- it makes the population empty, and an empty
# population satisfies every assertion under it.
# ---------------------------------------------------------------------------
DOORS <- c("emlBridgeGroupComparison", "emlDrawScatterPlot")

# ---------------------------------------------------------------------------
# 1. THE DERIVATION
# ---------------------------------------------------------------------------
# eml_settings_population -- of everything the draw-time analysis reads, which
# names are settings arriving from outside it.
#
#   root   the plugin tree to walk
#   doors  the procedures that compute a result at draw time
#   ->     data.frame(name, door, kind), kind in {"parameter","global"},
#          with attributes "procedures" (how many bodies the walk visited)
#          and "doors_found" (which of the named doors were resolved).
# ---------------------------------------------------------------------------
eml_settings_population <- function(root, doors) {
    files <- list.files(root, pattern = "\\.praat$", recursive = TRUE,
                        full.names = TRUE)
    files <- files[!grepl("/dev/", files, fixed = TRUE)]

    # A comment line contributes nothing, and a double-quoted string is text
    # rather than code: `annotBracketPosthoc$ = "Comparison: Welch t-test"`
    # must not make `Comparison` an identifier. Both leading `#` and leading
    # `;` are comments here -- the tree uses both, knowingly (CLAUDE.md).
    strip <- function(t) {
        t <- sub("^[[:space:]]*[;#].*$", "", t)
        gsub('"[^"]*"', " ", t)
    }

    bodies <- list()
    sigs   <- list()
    allsrc <- list()
    for (p in files) {
        ln <- readLines(p, warn = FALSE)
        allsrc[[p]] <- ln
        starts <- grep("^procedure [A-Za-z]", ln)
        ends   <- grep("^endproc[[:space:]]*$", ln)
        for (s in starts) {
            e <- ends[ends > s]
            if (!length(e)) next
            e <- e[1]
            nm <- sub("^procedure ([A-Za-z0-9_]+).*$", "\\1", ln[s])
            bodies[[nm]] <- c(bodies[[nm]], ln[s:e])
            sigs[[nm]]   <- ln[s]
        }
    }

    calls_in <- function(t) unique(sub("^@", "",
        unlist(regmatches(t, gregexpr("@[A-Za-z0-9_]+", t)))))

    # An identifier is a lower-case-initial word NOT preceded by a dot (a
    # procedure-local), an @ (a call) or another word character. `.alpha` and
    # `emlCountGroups.groupLabel$` therefore contribute nothing here, which is
    # right: procedure locals are not settings, and a qualified read names the
    # procedure, not a global.
    IDRX <- "(?<![.@[:alnum:]_])[a-z][A-Za-z0-9_]*[#$]?"
    ids_in <- function(t) unlist(regmatches(t, gregexpr(IDRX, t, perl = TRUE)))

    # An assignment is a line whose first token is an undotted name followed
    # by `=` (or an indexing bracket and then `=`). `==` is a comparison and
    # is excluded; `+=` is knowingly present in this tree and is an
    # assignment.
    WRX <- paste0("^[[:space:]]*([a-z][A-Za-z0-9_]*[#$]?)(\\[[^]]*\\])?",
                  "[[:space:]]*(\\+=|-=|\\*=|/=|=)([^=]|$)")
    writes_in <- function(t) {
        m <- grep(WRX, t, perl = TRUE, value = TRUE)
        unique(sub("^[[:space:]]*([a-z][A-Za-z0-9_]*[#$]?).*$", "\\1", m))
    }

    closure <- function(rootproc) {
        seen <- character(0); front <- rootproc
        while (length(front)) {
            n <- front[1]; front <- front[-1]
            if (n %in% seen) next
            seen <- c(seen, n)
            b <- bodies[[n]]
            if (is.null(b)) next
            front <- c(front, setdiff(calls_in(strip(b)), seen))
        }
        seen
    }

    params_of <- function(nm) {
        s <- sigs[[nm]]
        if (is.null(s)) return(character(0))
        a <- sub("^procedure [A-Za-z0-9_]+[[:space:]]*:?", "", s)
        unlist(regmatches(a, gregexpr("\\.[A-Za-z0-9_]+[#$]?", a)))
    }

    found <- doors[doors %in% names(bodies)]

    # ASSIGNED SOMEWHERE IN THE PLUGIN -- the test that separates a variable
    # of this plugin from a word of the Praat language. Nothing ever writes to
    # `if`, `mean`, `numberOfSelected` or `newline$`, so nothing of that kind
    # survives it, and no hand-kept list of Praat vocabulary has to be carried
    # here and kept current with the interpreter.
    assigned <- unique(unlist(lapply(allsrc, function(l) writes_in(strip(l)))))

    # WRITTEN INSIDE THE DOORS' OWN CLOSURE -- the test that separates a
    # setting arriving from outside from the analysis's own output. The union
    # over ALL doors, not per door: annotBracketP is written by the bridge and
    # read by the scatter's drawing, and it is the result either way.
    allcl  <- unique(unlist(lapply(found, closure)))
    alltxt <- strip(unlist(bodies[allcl]))
    ownwr  <- writes_in(alltxt)

    rows <- list()
    for (d in found) {
        for (p in params_of(d))
            rows[[length(rows) + 1L]] <- data.frame(
                name = paste0(d, p), door = d, kind = "parameter",
                stringsAsFactors = FALSE)
        cl  <- closure(d)
        txt <- strip(unlist(bodies[cl]))
        gl  <- setdiff(intersect(unique(ids_in(txt)), assigned),
                       c(ownwr, names(bodies)))
        for (g in sort(gl))
            rows[[length(rows) + 1L]] <- data.frame(
                name = g, door = d, kind = "global", stringsAsFactors = FALSE)
    }
    out <- if (length(rows)) do.call(rbind, rows) else
        data.frame(name = character(0), door = character(0),
                   kind = character(0), stringsAsFactors = FALSE)
    attr(out, "procedures")  <- length(allcl)
    attr(out, "doors_found") <- found
    out
}

ok_tree <- check_true(V, "the plugin tree the census reads is present",
                      dir.exists(plug))
if (!ok_tree) {
    if (!exists("EML_SUITE")) { eml_report("v112 -- the settings census"); eml_exit() }
}

pop <- eml_settings_population(plug, DOORS)
settings <- sort(unique(pop$name))

missing_door <- setdiff(DOORS, attr(pop, "doors_found"))
check_true(V,
           sprintf("both draw-time analysis doors resolve in the source%s",
                   if (length(missing_door))
                       paste0(" -- NOT FOUND: ", paste(missing_door, collapse = ", "))
                   else ""),
           length(missing_door) == 0)

# ---------------------------------------------------------------------------
# 2. THE TWO LISTS, DECLARED AS DATA
# ---------------------------------------------------------------------------
# RULING_RESULT_STORE.md section (b): "The two lists are DECLARED AS DATA in
# one place, not comments". They are these two vectors and nowhere else. Each
# entry carries the reason it is where it is, because a bare name in a list is
# a decision nobody can audit -- and because the reason is what a person needs
# when the answer has to be revisited.
#
# WHAT THE SPLIT MEANS, stated once. The store's question is binary: given a
# stored result, does changing this setting oblige a re-run? RESULT_AFFECTING
# means yes. DISPLAY_ONLY means no -- the same numbers, drawn or written
# differently. The ruling calls the second list "settings that only affect
# appearance"; a handful of entries below affect neither the numbers nor the
# picture but the RECORDED SCRIPT, because the recorder's capture procedures
# sit inside the doors' call graph and read the form's globals to write them
# down. They are in the second list because the store must not re-run for
# them, and each one says so in its own reason rather than being dressed up as
# a pen colour.
#
# MEASURED evidence is harness/settings/out/SETTINGS.tsv, quoted inline.
# READ evidence names the line that settles it. Neither is a guess, and where
# a classification rests on a condition that is not yet true, the condition is
# written into the reason rather than left in somebody's head.

RESULT_AFFECTING <- c(
    # -- the data the comparison is computed from. Result-affecting in the
    #    plainest sense; carried by the section (a) fingerprint rather than by
    #    a settings comparison, but a change here must re-run either way and
    #    a list that omitted them would be making a claim it cannot support.
    "emlBridgeGroupComparison.tableId" =
        "the table the comparison runs on",
    "emlBridgeGroupComparison.dataCol$" =
        "the numeric column compared",
    "emlBridgeGroupComparison.factorCol$" =
        "the column the groups come from",
    "emlDrawScatterPlot.objectId" =
        "the table the correlation runs on",
    "emlDrawScatterPlot.colX$" =
        "the x column the correlation runs on",
    "emlDrawScatterPlot.colY$" =
        "the y column the correlation runs on",

    # -- the three the ruling counted
    "emlBridgeGroupComparison.testType$" =
        paste("parametric or nonparametric: which test runs at all.",
              "MEASURED: one-way ANOVA F(2,15) = 277.80 with Tukey p =",
              "6e-9 becomes Kruskal-Wallis H(2) = 15.19 with Dunn p = .103",
              "on the same table"),
    "annotCorrectionMethod$" =
        paste("the multiple-comparison adjustment Dunn's test applies; read",
              "from the global, not passed as an argument.",
              "MEASURED: Zebra-Mid p = .1027 under holm, .1540 under",
              "bonferroni, and the figure's adjustment caption changes with",
              "it"),
    "emlBridgeGroupComparison.alpha" =
        paste("the threshold the significance verdict is taken at. It moves",
              "no p-value, it moves the VERDICT.",
              "MEASURED on a borderline pair (p = .039): annotMatrixSig goes",
              "1 at alpha .05 and 0 at alpha .01"),

    # -- the one no dialog has a control for, found by the walk
    "emlGroupSortAlphabetical" =
        paste("the order @emlCountGroups discovers the groups in, which is",
              "the order every pairwise contrast is formed in. No control of",
              "its own: the graphs form sets it from config_groupSort and",
              "stats/eml-extract.praat declares the default.",
              "MEASURED: Zebra|Alpha with t = +12.25, d = +7.07 becomes",
              "Alpha|Zebra with t = -12.25, d = -7.07 -- sign and names",
              "together"),

    # -- the alpha the intervals are built at, which is a second channel
    "annotAlpha" =
        paste("the alpha @emlCIAlphaInForce hands every confidence interval",
              "in the reporters, and the ladder @emlFormatStars applies.",
              "Pinned by v109 (the correlation interval honours alpha).",
              "Distinct from the .alpha ARGUMENT above: the form passes one",
              "dialog value into both, nothing makes them equal, and",
              "harness/settings/out/SETTINGS.tsv records what a caller that",
              "separates them gets"),

    # -- the scatter door
    "annotCorrType$" =
        paste("pearson, spearman, both or empty: which coefficient is",
              "computed, and, through it, whether the drawn and reported fit",
              "is OLS or Theil-Sen",
              "(graphs/eml-draw-procedures.praat, the .useTheilSen branch)"),
    "scatterAnalysisType" =
        paste("which of correlation and regression is run and reported at",
              "draw time; it also flips .reportedOLS, which forces the drawn",
              "line to the estimator the report used"),
    "emlDrawScatterPlot.groupCol$" =
        paste("empty gives one pooled correlation over every point; a column",
              "name gives one correlation PER GROUP, computed on that",
              "group's rows. Not a colour choice -- a different set of",
              "statistics"),
    "emlDrawScatterPlot.annotate" =
        paste("gates whether the correlation and the regression are computed",
              "and reported at all; with it 0 there is no result to store")
)

DISPLAY_ONLY <- c(
    # -- the four the ruling counted
    "emlBridgeGroupComparison.style$" =
        paste("p-value, stars or both: the TEXT of the bracket label.",
              "MEASURED: every p and every d identical, only",
              "dis.label changes ('p < .001, d = 6.93' / '***, d = 6.93')"),
    "emlBridgeGroupComparison.showNS" =
        paste("whether non-significant brackets are drawn.",
              "MEASURED on Dunn's test: showNS 0 publishes one bracket and",
              "showNS 1 publishes three, and the p of the pair present in",
              "both is .000292 either way. Suppression of publication, not a",
              "different result -- and section (d)'s single write site",
              "removes even the suppression"),
    "emlBridgeGroupComparison.showEffect" =
        paste("whether effect sizes are shown.",
              "MEASURED: p unchanged; the d values go from computed to",
              "undefined. CONDITIONAL: display-only holds because section",
              "(d) requires the store to state the WHOLE result on every",
              "run. In the bridge as it stands showEffect = 0 means Cohen's",
              "d is never computed, so a result published under it cannot",
              "serve a later figure that wants effect sizes"),
    "emlBridgeGroupComparison.layoutMode" =
        paste("brackets or a comparison matrix.",
              "MEASURED: same omnibus, same labels, same post-hoc and the",
              "same formatted p in both layouts. NOTE for the store: the",
              "matrix arm publishes abs(d) and a FORMATTED p where the",
              "bracket arm publishes signed d and a numeric p, so the store",
              "must publish the signed numeric result and let each layout",
              "take what it needs"),

    # -- the scatter's own drawing controls
    "scatterDotSize" = "dot radius",
    "scatterShowDots" = "whether the points are drawn at all",
    "scatterShowFormula" =
        "whether the fitted equation is written on the figure",
    "scatterRegressionLine" =
        paste("whether the fit is DRAWN. NOTE for the store: with",
              "annotCorrType$ = spearman and no regression report, this is",
              "the only path that computes a Theil-Sen fit, so the store",
              "must publish that fit rather than leave it to the drawing"),
    "emlDrawScatterPlot.title$" = "the figure title",
    "emlDrawScatterPlot.xLabel$" = "the x axis label",
    "emlDrawScatterPlot.yLabel$" = "the y axis label",
    "emlDrawScatterPlot.vpW" = "viewport width in inches",
    "emlDrawScatterPlot.vpH" = "viewport height in inches",
    "emlDrawScatterPlot.colorMode$" = "colour or black and white ink",
    "emlDrawScatterPlot.gridMode" = "which gridlines are drawn",
    "emlDrawScatterPlot.xMin" =
        paste("axis limit. The correlation is computed on .xData#/.yData#,",
              "which is every complete pair; a point outside the axes is",
              "clipped by @emlSetPatternScale when it is DRAWN and is still",
              "in the fit"),
    "emlDrawScatterPlot.xMax" = "axis limit; see .xMin",
    "emlDrawScatterPlot.yMin" = "axis limit; see .xMin",
    "emlDrawScatterPlot.yMax" = "axis limit; see .xMin",

    # -- annotation presentation
    "annotStyle$" =
        "the graphs-layer copy of the label style; formatting only",

    # -- layout measurement, published by the matrix measurer for the drawing
    "emlMatrixLayout_suppressed" =
        "whether the matrix panel had to be dropped for want of room",
    "emlMatrixLayout_yMax" = "the top of the matrix panel, in world units",
    "totalCanvasHeight" = "the page height the panel is laid out on",
    "emlGraphsAxisYReqMax" = "the y axis range the user asked for",
    "emlGraphsAxisYReqMin" = "the y axis range the user asked for",

    # -- page furniture
    "emlFont$" = "typeface",
    "emlSubtitle$" = "the subtitle line",
    "emlShowAxisNameX" = "whether the x axis is named",
    "emlShowAxisNameY" = "whether the y axis is named",
    "emlShowAxisValuesX" = "whether x tick values are printed",
    "emlShowAxisValuesY" = "whether y tick values are printed",
    "emlShowTicksX" = "whether x ticks are drawn",
    "emlShowTicksY" = "whether y ticks are drawn",
    "emlShowInnerBox" = "whether the inner frame is drawn",
    "emlShowExplanations" =
        paste("whether the reporters append their plain-language column.",
              "@emlReportLine prints the same formatted value either way and",
              "adds emlWizardExplain$ after two tabs when this is on. A menu",
              "analysis dialog's own toggle (punch list 6.1, language batch",
              "item 9) and @emlRecordCaptureStats now publishes it on",
              "analysis and draw steps (6.3) beside the three settings that",
              "ARE result-affecting -- it is a user choice a replay must",
              "reproduce, which is a narrower bar than 'changes a number'"),
    "emlLegendPlacement" = "which corner the legend sits in",
    "legendFill$" = "legend swatch fill",
    "legendPattern" = "legend swatch pattern",
    "legendStyle" = "legend swatch line style",

    # -- read ONLY by the recorder's capture procedures, which sit inside the
    #    doors' call graph because the bridge records the step it just ran.
    #    They change what the RECORDED SCRIPT says. They change neither the
    #    numbers nor the picture, so the store must not re-run for them --
    #    which is why they are in this list and not a third one -- but the
    #    reason says what they really are rather than calling them appearance.
    "annotate" =
        paste("whether statistical annotation was asked for. Read by",
              "@emlDiscloseBegin, which puts it in the figure's disclosure,",
              "and by two recorder captures. It gates nothing the scatter",
              "computes -- the scatter's own .annotate ARGUMENT does that,",
              "and that one is result-affecting"),
    "graph_type" =
        "recorder transcript only: which figure type the captured step names",
    "dataYMax_forAnnotation" =
        "recorder transcript only: the headroom figure the capture records",
    "emlEraseFirst" =
        "recorder transcript only: whether the page was erased before drawing",
    "emlLineStyle" =
        "recorder transcript only: the series pen the capture writes down",
    "emlSeriesRole$" =
        paste("what the series stand for, which is half of what",
              "@emlSecondAxisGate decides a refusal on; also captured with",
              "the pens. Reaches no statistic"),
    "emlSecondAxisOn" =
        paste("whether a second y axis was asked for. @emlSecondAxisGate",
              "refuses it out loud for the types that cannot carry one and",
              "@emlSetAdaptiveTheme reserves the margin for it; the recorder",
              "captures it with the pens. Reaches no statistic"),
    "emlSecondAxisCol$" = "recorder transcript only: second-axis column",
    "emlSecondAxisLabel$" = "recorder transcript only: second-axis label",
    "emlSecondAxisMin" = "recorder transcript only: second-axis range",
    "emlSecondAxisMax" = "recorder transcript only: second-axis range",
    "emlSecondAxisStyle" = "recorder transcript only: second-axis pen",
    "prev_boxShowJitter" =
        "recorder transcript only: the box plot's jitter switch, captured for replay",
    "prev_gbShowJitter" =
        "recorder transcript only: the grouped box's jitter switch",
    "prev_gvShowJitter" =
        "recorder transcript only: the grouped violin's jitter switch",
    "prev_violinShowJitter" =
        "recorder transcript only: the violin's jitter switch"
)

# ---------------------------------------------------------------------------
# 3. ONE PROPERTY, ASSERTED PER MEMBER: IN EXACTLY ONE LIST
# ---------------------------------------------------------------------------
in_result  <- settings %in% names(RESULT_AFFECTING)
in_display <- settings %in% names(DISPLAY_ONLY)

unclassified <- settings[!in_result & !in_display]
both         <- settings[in_result & in_display]

check_true(V,
           sprintf("every setting the draw layer reads is classified%s",
                   if (length(unclassified))
                       paste0(" -- UNCLASSIFIED: ",
                              paste(utils::head(unclassified, 8), collapse = ", "),
                              if (length(unclassified) > 8)
                                  sprintf(" (+%d more)", length(unclassified) - 8)
                              else "")
                   else ""),
           length(unclassified) == 0)

check_true(V,
           sprintf("no setting is in both lists%s",
                   if (length(both))
                       paste0(" -- IN BOTH: ", paste(both, collapse = ", "))
                   else ""),
           length(both) == 0)

# THE OTHER DIRECTION OF THE RATCHET. A classification whose setting the draw
# layer no longer reads is a line describing something that is gone, and the
# next person to read the list is entitled to believe every line in it.
declared <- unique(c(names(RESULT_AFFECTING), names(DISPLAY_ONLY)))
stale <- setdiff(declared, settings)
check_true(V,
           sprintf("no classification names a setting the draw layer no longer reads%s",
                   if (length(stale))
                       paste0(" -- STALE, delete its line: ",
                              paste(utils::head(stale, 8), collapse = ", "),
                              if (length(stale) > 8)
                                  sprintf(" (+%d more)", length(stale) - 8)
                              else "")
                   else ""),
           length(stale) == 0)

check_true(V, "no name is declared twice within one list",
           !any(duplicated(names(RESULT_AFFECTING))) &&
           !any(duplicated(names(DISPLAY_ONLY))))

check_true(V, "every classification carries a reason, not just a name",
           all(nzchar(RESULT_AFFECTING)) && all(nzchar(DISPLAY_ONLY)))

if (length(unclassified)) {
    cat("\n  A setting in this list is read by the draw-time analysis and is\n",
        "  in neither list, so the graph door has no way to know whether\n",
        "  changing it obliges a re-run. Put it in RESULT_AFFECTING or in\n",
        "  DISPLAY_ONLY above, WITH THE REASON -- and where reading the code\n",
        "  does not settle it, measure it: harness/settings/run.sh runs the\n",
        "  door at two values of one setting and writes down what moved.\n",
        sep = "")
}

# ---------------------------------------------------------------------------
# 4. THE RESOLVER GATE -- THE REFUTATION OF A VACUOUS PASS
# ---------------------------------------------------------------------------
n_all <- length(settings)
n_res <- sum(in_result)
n_dis <- sum(in_display)
n_unc <- length(unclassified)

check_true(V,
           sprintf("RESOLVER: %d settings read, %d result-affecting, %d display-only, %d unclassified",
                   n_all, n_res, n_dis, n_unc),
           n_all > 0)

check_true(V,
           sprintf("RESOLVER: the walk visited %d procedure bodies across %d doors",
                   attr(pop, "procedures"), length(attr(pop, "doors_found"))),
           attr(pop, "procedures") > 0 &&
           length(attr(pop, "doors_found")) == length(DOORS))

# BOTH DOORS CONTRIBUTED. A walk that resolved one door and silently lost the
# other still reports a healthy total, because the bridge alone is most of the
# population.
per_door <- table(pop$door)
check_true(V,
           sprintf("RESOLVER: each door contributed settings (%s)",
                   paste(sprintf("%s=%d", names(per_door), as.integer(per_door)),
                         collapse = ", ")),
           length(per_door) == length(DOORS) && all(per_door > 0))

# THE ONE THE BRIEF SAYS THE DERIVATION MUST FIND BY CONSTRUCTION. Asserted by
# name, and it is not a hand entry: it is here only if the walk put it here.
# If a future refactor stops the draw layer reading it, this goes red and the
# ratchet above goes red with it, which is the correct pair of complaints.
check_true(V,
           "the derivation surfaces emlGroupSortAlphabetical, which no dialog controls",
           "emlGroupSortAlphabetical" %in% settings)

# ---------------------------------------------------------------------------
# 5. THE MEASURED EVIDENCE
# ---------------------------------------------------------------------------
ok_meas <- check_true(V, "the measured settings artefact is present",
                      file.exists(measured))
if (ok_meas) {
    raw <- readLines(measured, warn = FALSE)
    raw <- raw[nzchar(raw)]
    f <- strsplit(raw, "\t", fixed = TRUE)
    hdr <- f[[1]]
    f <- f[-1]
    fld <- function(i) vapply(f, function(r) if (length(r) >= i) r[i] else "", "")
    ev <- data.frame(setting = fld(1), variant = fld(2), key = fld(3),
                     value = fld(4), stringsAsFactors = FALSE)

    # obs.* rows are observations recorded for a reader, not settings under
    # classification. Named here so they cannot be mistaken for either.
    obs <- grepl("^obs\\.", ev$setting)
    meas_settings <- sort(unique(ev$setting[!obs]))

    check_true(V,
               sprintf("RESOLVER: the probe measured %d settings at two values each",
                       length(meas_settings)),
               length(meas_settings) > 0)

    off_pop <- setdiff(meas_settings, settings)
    check_true(V,
               sprintf("every measured setting is in the derived population%s",
                       if (length(off_pop))
                           paste0(" -- MEASURED BUT NOT READ: ",
                                  paste(off_pop, collapse = ", "))
                       else ""),
               length(off_pop) == 0)

    # MOVED, DEFINED ONCE. A `res.` key is the analysis result; a key present
    # in only one variant is SUPPRESSION (showNS drops a bracket) and a value
    # of "undefined" is the quantity not being computed (showEffect), which is
    # the same suppression wearing a value. Only two DEFINED values that
    # differ are the result moving. See the probe's header.
    moved_of <- function(s) {
        e <- ev[ev$setting == s & grepl("^res\\.", ev$key), , drop = FALSE]
        vs <- unique(e$variant)
        if (length(vs) != 2) return(NA)
        a <- e[e$variant == vs[1], ]; b <- e[e$variant == vs[2], ]
        shared <- intersect(a$key, b$key)
        av <- a$value[match(shared, a$key)]
        bv <- b$value[match(shared, b$key)]
        keep <- av != "undefined" & bv != "undefined"
        any(av[keep] != bv[keep])
    }
    moved <- vapply(meas_settings, moved_of, logical(1))

    wrong <- names(moved)[!is.na(moved) & moved &
                          !(names(moved) %in% names(RESULT_AFFECTING))]
    check_true(V,
               sprintf("every setting MEASURED to move the result is classified result-affecting%s",
                       if (length(wrong))
                           paste0(" -- MOVES THE RESULT BUT IS NOT IN THE LIST: ",
                                  paste(wrong, collapse = ", "))
                       else ""),
               length(wrong) == 0)

    unpaired <- names(moved)[is.na(moved)]
    check_true(V,
               sprintf("every measured setting was run at exactly two values%s",
                       if (length(unpaired))
                           paste0(" -- ", paste(unpaired, collapse = ", "))
                       else ""),
               length(unpaired) == 0)

    check_true(V,
               sprintf("RESOLVER: %d of %d measured settings moved the result",
                       sum(moved, na.rm = TRUE), length(meas_settings)),
               sum(moved, na.rm = TRUE) > 0)

    # A SETTING THAT HELD STILL IS NOT THEREBY DISPLAY-ONLY, and this file
    # does not pretend otherwise -- it is one negative on one table. It is
    # reported so a reader can see which classifications rest on reading
    # alone.
    still <- names(moved)[!is.na(moved) & !moved]
    if (length(still))
        cat("\n  Held still on the probe's tables (evidence for display-only,",
            "\n  not proof of it): ", paste(still, collapse = ", "), "\n", sep = "")
} else {
    cat("\n  harness/settings/out/SETTINGS.tsv is written by\n",
        "  bash harness/settings/run.sh. Without it the classifications in\n",
        "  section 2 rest on reading alone, and this file says so rather\n",
        "  than passing over the silence.\n", sep = "")
}

if (!exists("EML_SUITE")) { eml_report("v112 -- the settings census"); eml_exit() }
