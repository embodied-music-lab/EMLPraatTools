#!/usr/bin/env Rscript
# ============================================================================
# EML Stats & Graphs — validation suite runner
#
# Ian Howell — Embodied Music Lab — GPL-3.0-or-later
#
#   Rscript validate/run_all.R
#
# Base R only. No packages are installed or loaded. Exits 1 if any check
# fails, so it can be wired to CI unchanged.
#
# Read REGISTRY.md first — it says what each script covers, which of them
# pin known defects (and therefore SHOULD fail once those defects are
# fixed), and which checks are still awaiting a GUI drive.
# ============================================================================

.a <- commandArgs(FALSE)
.f <- sub("^--file=", "", .a[grep("^--file=", .a)])
HERE <- if (length(.f)) dirname(normalizePath(.f)) else getwd()
Sys.setenv(EML_VALIDATE_DIR = HERE)

source(file.path(HERE, "helpers.R"))
EML_SUITE <- TRUE

# ============================================================================
# A RUN THAT CHECKED NOTHING MUST NOT LOOK LIKE A RUN THAT PASSED
# ============================================================================
# ON 18 AUGUST 2026 THIS FILE RAN ZERO VALIDATORS, TWICE, AND NOTHING SAID SO.
# A trailing comma was left in the list below -- the last entry followed by a
# comma, with the closing bracket under it. R PARSES THAT. It refuses only when
# it evaluates:
#
#     Error in c("v01_pairwise_welch_bonferroni.R", ... :  argument 91 is empty
#
# so the list never came into existence, not one validator was sourced, and the
# run ended before the first check. Two commits went out reported green.
#
# THE DEFECT WAS NOT THE COMMA. It was that nothing else about the run looked
# any different. Measured on this machine: `Rscript validate/run_all.R` does
# exit 1 on that error. But the command README.md gives a reader is
#
#     Rscript validate/run_all.R | tee /tmp/suite.log
#
# and a shell pipeline reports the LAST command's status, so tee's 0 is what
# anybody sees unless `set -o pipefail` was said first (the release workflow
# says it; a person at a terminal does not). What is left to read is the log --
# and the log of a run that did nothing differs from the log of a clean run
# only by ABSENCE. Neither has a FAIL line in it. Silence and success are the
# same shape, and the eye reaches for the same conclusion.
#
# So the three questions below are asked out loud, and any one of them
# answered wrongly ends the run with a banner rather than with nothing:
# was every script in the list real and sourced, did R get through the run at
# all, and did the run record a plausible number of checks.

# THE BANNER, AND WHY ITS STATUS IS 2. A red check exits 1; this exits 2, so a
# caller that cares can tell "the suite ran and something failed" from "the
# suite did not run". Every caller that only asks about zero is served either
# way. The text is what matters more than the number: it is written to be
# unmissable at the foot of a log that otherwise ends in silence.
eml_abort <- function(headline, detail = character(0)) {
    bar <- strrep("!", 78)
    cat("\n", bar, "\n", sep = "")
    cat("!! THE VALIDATION SUITE DID NOT RUN TO COMPLETION -- THIS IS NOT A PASS\n")
    cat(bar, "\n", sep = "")
    cat(headline, "\n", sep = "")
    for (d in detail) cat("   ", d, "\n", sep = "")
    cat("\nNo verdict was reached. Treat this run as having checked NOTHING,\n")
    cat("whatever the exit status of a pipeline you ran it through.\n")
    cat(bar, "\n", sep = "")
    flush(stdout())
    quit(status = 2, runLast = FALSE)
}

# QUESTION TWO, INSTALLED FIRST, BECAUSE IT IS THE ONE THAT CATCHES THE LIST
# ITSELF. An empty argument is refused while `scripts <- c(...)` is being
# evaluated, which is before any code below it exists to inspect anything. The
# only thing that can speak at that moment is an error handler already in
# place. It covers the general case too: a validator that dies mid-run leaves
# every validator after it unrun, and that is also not a pass.
options(error = function() {
    msg <- unlist(strsplit(sub("[[:space:]]+$", "", geterrmessage()), "\n",
                           fixed = TRUE))
    eml_abort("R raised an error and the run stopped where it stood:",
              c(msg, "",
                "A trailing comma in the script list below arrives here, as",
                "\"argument N is empty\" -- the list is then never built and no",
                "validator is sourced."))
})

scripts <- c(
    "v01_pairwise_welch_bonferroni.R",
    "v02_pairwise_holm_differential.R",
    "v03_rm_anova_greenhouse_geisser.R",
    "v04_friedman.R",
    "v05_paired_t.R",
    "v06_D15_effect_size_defect.R",
    "v07_redpath_degenerate_inputs.R",
    # Orchestrator suites, 5 August 2026. These cover stats/eml-analysis.praat
    # — the layer that assembles a report out of already-oracled primitives.
    "v08_twogroup_orchestrator.R",
    "v09_anova_tukey_orchestrator.R",
    "v10_kruskal_dunn_orchestrator.R",
    "v11_twoway_orchestrator.R",
    "v12_correlation_orchestrator.R",
    "v13_regression_orchestrator.R",
    "v14_descriptive_orchestrator.R",
    "v15_normality_orchestrator.R",
    "v16_csv_export.R",
    # v17 needs only stock R in BASE mode (it uses broom when broom is
    # installed and falls back to base R otherwise, and says which), so it
    # belongs in the runner like the rest. Added 6 Aug 2026 -- it had been
    # written standalone and was invisible to a reviewer following the
    # instructions in REGISTRY.
    "v17_broom_parity.R",
    # v18 is the Tier B grid: the shipping statistical procedures over 16
    # designed shapes rather than one GUI-driven table each. Stock R, and it
    # reads committed evidence like every other script, so it belongs in the
    # runner. It is DIFFERENT EVIDENCE from v01-v15, not more of it -- those
    # check the printed report, this checks the procedure behind it.
    "v18_sweep_parity.R",
    # v19 is the NIST StRD tier. It contributes checks only when the .dat
    # files have been ingested (they are not redistributable), and prints a
    # loud SKIP otherwise rather than silently contributing nothing.
    "v19_nist_strd.R",
    # v20 is the first CSV migration checkpoint: the SHIPPING ANOVA path in
    # broom's three-file shape. Distinct from v17, which checks the writer
    # called directly by a harness. A path is not converted until it has a
    # check at this level.
    "v20_shipping_anova_broom.R",
    # v21 is the rest of the CSV migration: the other ten shipping paths in
    # broom's three-file shape, every file written by the orchestrator the
    # menu calls. Includes the assertion that htest paths write NO augment,
    # since broom has none for them.
    "v21_shipping_paths_broom.R",
    # v22 covers the Ruling 1 numerics: Brown-Forsythe (median-centred
    # Levene), Welch's k-sample F, and Games-Howell. None of the three
    # existed before the ruling, so nothing above reaches them. Includes the
    # k = 2 identity -- Welch's F is Welch t-squared, which is what keeps
    # Tier A property A1 honest once these are reachable from the reporter.
    "v22_homogeneity.R",
    # v23 checks the Q-Q figure's own point pairs against qnorm/ppoints and
    # sort(x), so the figure and the reported W are bound to the same points.
    # Also pins the Blom-vs-qqnorm plotting-position difference above n = 10
    # rather than leaving it to be discovered.
    "v23_qq_points.R",
    # v24 checks leverage, Cook's distance and the leverage-corrected
    # standardised residual against hatvalues/cooks.distance/rstandard.
    # It pins the OLD .std.resid form as WRONG, so reverting the augment
    # site turns this red rather than passing quietly.
    "v24_influence.R",
    # v25 is Ruling 1 at the REPORT level -- two captures from the same input
    # file differing only in data column, so the conditional can be asserted
    # in BOTH directions. The absent case carries the ruling's real
    # constraint: on data that does not trip the check, a run must look as it
    # did before the feature existed, and the primary F must still be aov()'s
    # pooled F rather than oneway.test()'s.
    "v25_anova_showboth.R",
    # v26 is Ruling 3(a) at the report level, same two-direction shape as v25:
    # the interaction caveat must appear when the interaction is significant
    # and stay away when it is not, and the three F values must be identical
    # either way. Also pins that the caveat sits under the table it qualifies
    # rather than under the effect sizes, per the D98 placement ruling.
    "v26_twoway_caveat.R",
    # v27 is the D111 uniformity guard: every Table-consuming draw procedure,
    # given no usable data, must fall back to a unit axis and draw the
    # labelled empty frame. The histogram used to `goto` past its own `Axes:`
    # and write a blank white page. Includes a static check that no `goto`
    # returns to the draw library, which is how the defect got in.
    # Reads harness/stress_out/, so harness/stress_graphs.sh must run first --
    # same dependency shape as v23 on harness/qq_drive.sh.
    "v27_empty_frames.R",
    # v28 guards column TYPE. Praat has two column readers that disagree: the
    # row-wise one returns undefined for a text cell, which every other path
    # already drops, but `Report two-way anova:` numericises the column as a
    # whole and substitutes each value's ALPHABETICAL RANK. The two-way test
    # therefore reported F = 132.92, p = 6.9e-15 on a column of singers'
    # names. One bad cell is enough. Asserts the refusal by exact message AND
    # that every legitimate analysis still runs -- a guard that refused
    # everything would pass the first half alone.
    "v28_column_type_guard.R",
    # v29 is the figure-disclosure ruling: "draw the image as the image unless
    # someone asks to annotate". Info window always, the figure only when
    # Annotate is ticked, the user's subtitle never. The ANNOTATE-OFF direction
    # is the load-bearing half -- that is the ruling. Includes a static ban on
    # assigning to emlSubtitle$ in the draw library, the same shape as v27's
    # static ban on goto. Reads harness/disclosure/out/.
    "v29_figure_disclosure.R",
    # v30 pins that an error return in the wizard keeps the USER'S columns.
    # The wizard said "Nothing has been lost" and then re-rendered from a
    # column guess; a user who pressed Run without touching anything got a
    # different analysis reported as theirs. Asserts from before/after captures
    # that the fixed one never names a guessed column.
    "v30_wizard_state.R",
    # v31 pins the gridline-mode encoding. Two incompatible encodings shared
    # one persisted key, so drawing a scatter with gridlines off left a
    # histogram's dropdown blank and refusing to proceed -- on disk, so it
    # survived a restart. One canonical encoding now, translated at the
    # dialog. The registry checks are the load-bearing half: they fail at
    # INCLUDE time if a future graph type omits its entry, which is how the
    # bug got in.
    "v31_gridmode.R",
    # v32 pins the plot rectangle. The dimensions a user types describe the
    # DATA AREA, not the data area plus its furniture -- if a legend carves
    # space out of the 6 x 4 someone asked for, "make my figure square" stops
    # being satisfiable. So the plot rectangle must be identical in all five
    # legend placements, and a legend that needs room outside it has to grow
    # the SAVED IMAGE instead. 205 renders from two fixtures. The GEOMETRY
    # RIG (harness/legend/case.praat) holds the figure constant while the
    # legend sweeps: the legend matrix at three figure sizes with no placement
    # declared, which is what every existing caller supplies, the five
    # placements driven one render each, a real four-group comparison matrix
    # under the plot, and the red paths. The DEMONSTRATION
    # (harness/legend/series_case.praat) drives @emlDrawTimeSeries and
    # @emlDrawScatterPlot -- a multi-series line chart and a grouped scatter,
    # where the number of legend entries IS the number of series and the
    # corner is the one @emlPlaceElements scored rather than one the fixture
    # chose -- and measures how much DATA the key sits on at placement 1,
    # against a control render of the same figure on the same axis with the
    # legend suppressed. Every number is measured on the rendered PIXELS, not
    # read back from what the script believed it drew -- both sides of that
    # comparison are computed by the same arithmetic and move together. Also
    # pins the D135 over-wide label, both before and after it was closed, and
    # the static rule that a legend renderer draws into the rectangle it was
    # HANDED. Reads harness/legend/out/, so harness/legend/run.sh must run
    # first -- same dependency shape as v27 on harness/stress_graphs.sh.
    "v32_legend_geometry.R",
    # v33 pins EXCLUSION PARITY: the figure drops the rows the analysis drops.
    # They did not agree until 11 Aug 2026 -- the stats path read cells with
    # @eml_readCell and every draw procedure with Praat's own numericiser, so
    # "1,5" was dropped by an ANOVA and plotted as 1. The omnibus line painted
    # onto a figure then described a different data set from the figure. Both
    # counts are produced in Praat by the plugin's own procedures; this script
    # compares them and never classifies a cell itself.
    #     bash harness/parity/run.sh
    "v33_exclusion_parity.R",
    # v34 pins LABEL ESCAPING. @emlSanitizeLabel was not idempotent, so the
    # auto-composed title of every figure was escaped twice and lost the
    # character it was protecting: "Jitter (%)" rendered as "Jitter (  )" in
    # the title while the y-axis label on the same figure was correct. Found
    # by reading a figure the plugin's own menu produced.
    #     bash harness/disclosure/run.sh
    "v34_label_escape.R",
    # v35 pins the plugin ASSEMBLED rather than its parts. Fifteen menu entry
    # points were dead at parse time and the Draw branch of every analysis
    # threw away the Table it was handed, while every other check in this
    # suite was green -- because nothing here had ever loaded the barrel all
    # sixteen wrappers load, or raised one of the plugin's dialogs.
    #     bash harness/wrappers/run.sh && bash harness/gui_e2e/run.sh
    "v35_assembly.R",
    # v36 closes §17: 39 stress figures were rendered and ten were judged.
    # "29 OK" was the DRIVER's verdict -- praat did not error and a PNG
    # appeared -- and it was the verdict on the cases named after the
    # pathologies: violin_zerovar, violin_n1, violin_spanzero,
    # violin_undefined, the two scale extremes, the two bin-count extremes,
    # ts_duplicate_times, legend_cap. It could not be written earlier. §14:
    # 22 of the 39 drew unseeded randomGauss, so their ink and chroma were a
    # different number every run and nothing was pinnable. Seeded 12 Aug, so
    # RESULTS.tsv is finally the baseline it always looked like: this pins all
    # 39 measurements at the driver's own 5% margin, declares the population
    # through eml_census, and asserts each pathology on what its log and its
    # canvas ACTUALLY carry -- the skipped-row count derived from the fixture
    # rather than transcribed, the bin count against the argument the case
    # passed, legend containment recomputed from the two rectangles instead of
    # read off the case's own verdict, and violin_longlabels' taller canvas,
    # which is the only evidence anywhere that its labels are not clipped.
    # Complements v27 over the same artefact: v27 owns the ten empty frames
    # and asserts inequalities, this pins values and owns the other 29.
    #     bash harness/stress_graphs.sh
    "v36_stress_output.R",
    # v37 pins DETERMINISM: each of the ten Table-consuming draw procedures,
    # given one seeded fixture in two separate Praat processes, writes the same
    # bytes twice. harness/determinism/run.sh was the only harness in the tree
    # no R script read, so the 10/10 byte-identical figure the audit quotes was
    # the harness reporting on itself -- and determinism is what licenses
    # reading a diff of two renders as a regression, so every byte-for-byte
    # claim downstream inherited that. The load-bearing check re-compares the
    # two PNGs off disk in R rather than reading the driver's verdict column.
    #     bash harness/determinism/run.sh
    "v37_determinism.R",
    # v39 pins the RECORDER driven the way a user drives it: 27 operations
    # through separate script scopes in one Praat process, which is the menu
    # model. Every test before harness/record_e2e started the recording in the
    # same scope that added the steps, so none of them could have seen that the
    # draw capture hook never fired from a menu or that the phrase registry was
    # never loaded by the shipped plugin. Coverage is pinned as a FLOOR, and
    # "did not run" is checked separately because a crashed operation and one
    # with no capture hook look identical in the step count.
    #     bash harness/record_e2e/run.sh
    "v39_record_coverage.R",
    # v40 pins the OPPOSITE run: the same 27 operations with the recorder NOT
    # LOADED. The recorder is optional -- a user script or a PraatGen
    # companion includes the stats and graphs files directly -- and every
    # capture hook is guarded on its PRESENCE for that reason. Every shipped
    # barrel includes it, so no harness that loads a barrel can tell whether
    # the guard is still there; on 12 Aug 2026 it was removed twice in one
    # afternoon and reached a green suite both times.
    #     bash harness/norecord/run.sh
    "v40_norecord.R",
    # v41 pins that a BLANK group cell is missing data, not a category.
    # @emlCountGroups had no test for an empty normalised label, so a blank
    # became a group -- and the count is k in every df, every post-hoc family
    # size and every legend. One blank cell in a genuine two-group table made
    # the t-test refuse and route the user to ANOVA. No fixture in the tree had
    # a blank GROUP cell (every harness blank is in a value column), so nothing
    # could catch it; harness/blankgroup supplies the one that was missing.
    #     bash harness/blankgroup/run.sh
    "v41_blank_group.R",
    # v42 pins @emlGraphsDrawWithLegendRoom -- the form's two-pass headroom
    # loop, which draws, measures, and if the legend needs y-axis room throws
    # the first pass away and draws again. It was extracted to file scope so
    # that a probe could drive it and no probe ever did, so the loop, its pass
    # counter, its per-type axis read-back and @emlGraphsDispatchDraw had
    # never run outside a live dialog. harness/legend covers the headroom
    # arithmetic by reimplementing it; that is not this procedure.
    #     bash harness/legendroom/run.sh
    "v42_legend_room.R",
    # v43 pins the three helpers that live INSIDE eml-graphs-form.praat and
    # are called only from inside it. @emlGenerateUniquePath is the
    # non-destructive-save promise -- every figure, legend, CSV and recorded
    # script routes through it and its whole job is that an existing file is
    # never silently overwritten. Nothing asserted that, because nothing had
    # ever loaded that file outside a live dialog, and a regression there
    # produces no red test and no wrong number: it destroys a figure the user
    # drew an hour ago. @emlGraphsCSVDefaultName's slug rules keep a path
    # separator out of a filename, and @emlGraphsCSVRowAnalysis is the RFC
    # 4180 field reader underneath them.
    #     bash harness/formhelpers/run.sh
    "v43_form_helpers.R",
    # v44 pins where Tab actually goes in a Praat pause dialog. harness/gui_e2e
    # carried two incompatible laws for this and had measured neither, and the
    # one written into its case table was wrong: Tab visits every FIELD before
    # it reaches a button, Return in an entry presses the DEFAULT rather than
    # the focused widget, and `folder:` is a GtkTextView that swallows Tab as
    # literal whitespace -- so a forward walk on the Save Figure dialog reaches
    # no button at any count and corrupts the output path on the way. The
    # replacement runs backward: shift+Tab xN presses the Nth button from the
    # end, on every shape, without ever entering a field.
    #     bash harness/tabwalk/run.sh
    "v44_tab_walk.R",
    # v45 pins the workflow driven to TEARDOWN. v35 asserts that it advances;
    # until 13 Aug 2026 nothing asserted that it finishes, because the harness
    # stopped at the column-mapping dialog and the whole span past the draw
    # commit -- Save Figure, Export Results, Redraw, teardown -- had never run
    # outside a live dialog. Driving it found that the harness was arriving at
    # a post-draw dialog no user reaches (three buttons, no Exp CSV, because
    # the driver skipped the analysis the wrapper runs first) and that the run
    # saved its figure into the home directory.
    #     bash harness/gui_e2e/run.sh
    "v45_gui_teardown.R",
    # v46 is STATIC, and that is the point. The plugin writes CSV in two
    # formats and one `if` decides which; that `if` used to live inside the
    # stats menu's export, so the graphs form's Exp CSV button could not reach
    # it and wrote the legacy format for analyses the rest of the plugin
    # exported as broom frames. Nothing could catch it: v20/v21 enumerate the
    # stats-MENU orchestrators, and coverage.R compares rendered cases against
    # claimed cases -- neither can see a path that produces no artefact at all,
    # and that button had never been pressed. The population that needed
    # checking was a set of CALL SITES, which is a property of the source.
    # Needs no harness run, which is why it cannot be outrun by a button
    # nobody presses.
    "v46_export_surface.R",
    # v47 pins the plugin's INSTALL FOLDER NAME, which cannot be derived from
    # anything in this tree -- Praat gives a script no way to learn its own
    # plugin folder, so the name is a convention duplicated across a dozen
    # literals. A recorder that misspells `plugin_EML_StatsGraphs` pastes the
    # misspelling into eleven `include` lines of every script it emits, and
    # every recorded script is unrunnable. Three things had to be true at once
    # for exactly that to survive here undetected: the phase1 test
    # ASSERTED THE WRONG STRING, harness/record/roundtrip.sh -- the one
    # harness that runs the emitted script -- overrides the root by design,
    # and nothing read the name out of a rendered artefact. v47 reads
    # harness/record_e2e's recording, which is rendered by the unmodified
    # production path, and compares it against an EXECUTABLE oracle: the
    # folder the walk rigs actually symlink.
    "v47_plugin_folder_name.R",
    # v48 is the journey check v46 cannot be. v46 is static: it proves each
    # wrapper's call site exists and names the panel, and every claim it makes
    # was true while all nine non-graphing Save buttons were dead -- they
    # passed emlLastCSVFolder$, nothing seeded it, and Praat evaluates a
    # procedure's arguments before entering it. A static check cannot see an
    # unbound argument, and harness/wrappers asks only whether a script
    # parses. v48 reads harness/savepaths, which presses the button on every
    # caller and checks that the panel came up, that it wrote, and that what
    # it wrote shares one folder and one base name -- the panel's whole
    # contract. Its coverage check reads the callers out of the SOURCE, so a
    # new wrapper with a Save button fails this file until somebody drives it.
    "v48_save_paths.R",
    # v49 is the population neither v46 nor v48 can see. Both reason about
    # CALLERS of the save panel; a path that offers no Save button is not a
    # caller, so a branch that cannot export is outside both by construction.
    # Three were: the wizard's Describe, Describe by group and Check
    # normality, plus the standalone Check normality wrapper, which ran an
    # orchestrator that had declared correctly for weeks and then offered the
    # user no way to keep the result. None of them failed loudly -- the button
    # was simply absent, and an absent button reads as a decision. One had
    # even been written down as one. v49 enumerates the wizard's terminal
    # branches and the analysis wrappers out of the source and fails if any of
    # them cannot reach the export step.
    "v49_every_path_exports.R",
    # v50 is the CODE/API export path -- @emlExportResultFiles called from a
    # user's own Praat script, with no dialog anywhere. It works, and until
    # 14 Aug 2026 it was neither documented nor exercised: every check above
    # it reaches the exporter through a BUTTON, so a caller who never presses
    # one is outside all of them. Reads harness/api_export, which is headless
    # -- no Xvfb, no window manager -- and covers both arms of the fork, the
    # collision walk, and the fresh-session call with nothing declared, which
    # is the case that used to abort on Praat's non-short-circuiting `and`.
    "v50_api_export.R",
    # v51 drives the graphs form in ADVANCED mode, which harness/gui_e2e never
    # does -- it draws in beginner mode, where annotate is forced to 0, so the
    # annotation bridge never runs and the preset-restore branch is never
    # entered. Both fixes of 13 Aug 2026 lived outside every existing check BY
    # CONSTRUCTION and rested on my having read the code.
    #
    # They fail as SILENCE: no error, no missing file, no warning. And the file
    # set cannot separate them, because an annotated draw and an unannotated
    # one both leave tidy and glance on disk -- written by the bridge in one
    # case and by the caller's orchestrator in the other. What separates them
    # is the Info report: one "Two-Group Comparison" section if the preset was
    # lost, two if it survived and the bridge reported on top.
    "v51_advanced_mode.R",
    # v52 is the batch module's acoustic surface, under the author's ruling of
    # 14 Aug 2026: Praat validates its own DSP, and we do not re-derive its
    # pitch tracker or its cepstrum. What is OURS is the call -- the right
    # command, the canonical PraatGen parameter set, applied to the right
    # object for the right purpose.
    #
    # A parameter set does not announce its own corruption. Change 0.02 to 0.2
    # in the jitter call and every file still yields a number, the CSV keeps
    # its shape, the suite stays green, and the column is quietly a different
    # measurement than its header names. Nothing downstream can notice. The
    # only defence is a pin, argument by argument.
    #
    # The harness half is a different kind of evidence and cannot be folded in:
    # static text cannot prove ARGUMENT ORDER, because Praat's positional forms
    # accept a number wherever a number is expected. A ceiling landing in the
    # max-candidates slot returns a plausible wrong number rather than an
    # error. Only running the call settles it -- and only at the target
    # version, which is why v52 reports the four 6.6-era calls as MISSING
    # evidence on an older sandbox instead of passing over them.
    "v52_acoustic_calls.R",
    # v53 is the batch FLOW, as against v52's acoustic CALLS. The module had no
    # error containment at all: an unguarded `Read from file:` on a 0-byte wav
    # ended the script at exit 255, and because the CSV is written AFTER the
    # loop, one clipped take in a 500-file corpus produced no output whatever --
    # and nothing said which file did it. That is the shape of failure this
    # file exists for. A file that cannot be analysed is now a ROW, not an
    # absence, and v53 drives seven corpora to prove it.
    #
    # The TextGrid branch could not be settled by a file check either: a
    # constrained run and an unconstrained one leave the same CSV with the same
    # columns. What separates them is the NUMBER -- a sound that is 130 Hz then
    # 260 Hz with only its second half labelled reads 194 unconstrained and 260
    # constrained. The difference IS the evidence that the constraint applied.
    "v53_batch_flow.R",
    # v54 checks the module against the PraatGen corpus itself -- the framework
    # repo, read rather than remembered: COMMANDS_*.txt for signatures,
    # APPENDIX_C for dialogs, APPENDIX_D for ranges, APPENDIX_F for UX. Every
    # pin cites file and section so a reader can check it.
    #
    # The find worth naming: three `Get mean` calls share a NAME across Pitch,
    # Intensity and Harmonicity and do not share a SIGNATURE -- Harmonicity
    # takes two arguments and no unit string. Nothing but the catalogue
    # separates them, and passing the wrong arity is an abort mid-batch, not a
    # wrong number. The module has all three right; now it stays right.
    "v54_batch_praatgen.R",
    # ------------------------------------------------------------------
    # v55-v63: the 15 August 2026 audit response.
    #
    # An external stress-test session drove roughly 350 dialogs, recomputed
    # 150+ printed statistics independently, and put every finding past a
    # verifier instructed to refute it. Its verdict on the arithmetic was
    # zero mismatches at printed precision. Every defect it found lived at
    # an edge: an editor that addresses columns by name, entry points that
    # die before their dialog, saves that abort on a slash, exports that
    # drop all but the last column. These nine files are that response.
    # ------------------------------------------------------------------
    # The editor could silently destroy the WRONG column's data -- the
    # audit's only severity 1. Delete honoured the menu selection in the UI
    # and deleted the first label match; with duplicates present the second
    # column was unreachable by every editor operation. Praat 6.6.30 has no
    # positional Table addressing at all (measured: six candidate command
    # names, none available), so the fix is a rename-to-sentinel shim.
    "v55_editor_addressing.R",
    # Two saves killed the session on legitimate input: a slash in the base
    # name, and an unwritable folder. Measured at 6.6.30, this filesystem
    # refuses exactly one character; the sanitiser takes the cross-platform
    # union anyway. The sanitise happens ABOVE the stem-uniquing walk, and
    # v56 checks the ORDER -- one stamp per press is the panel's contract.
    "v56_save_guards.R",
    # Multi-column normality Save exported ONE column: the collectors were
    # re-initialised per column instead of per press. The one exported row
    # was numerically perfect, which is what made it hard to see. The rule
    # that falls out, and that v57 pins: init once per press, accumulate
    # per loop. The ANOVA augment fix is here too -- it had been exporting
    # resid/sigma under broom's .std.resid name, a uniform 4.4% understatement.
    "v57_export_integrity.R",
    # A recorded advanced figure replayed without its annotation bracket or
    # its jittered points. Ian's ruling of 14 Aug made replay NON-INTERACTIVE
    # -- the SPSS model, dialogs author syntax and syntax runs headless -- so
    # a recorded save now embeds folder and base name as literals and takes a
    # fresh stamp at replay. A faithful replay is not byte-identical (the
    # recorder emits axes at 6 dp), so v58 identifies rather than compares:
    # zero pixels differing from the original, 2740 from a bare draw.
    "v58_recorder_replay.R",
    # Eleven registered entry points crashed before their dialog opened.
    # Ian ruled MAKE OPERABLE, not unregister -- "dead doors are worse than
    # absent features". v59's enumeration unit is the REGISTRATION, which is
    # the population every other validator here excludes by construction:
    # v46 checks call sites, savepaths checks callers, v49 needs an artefact.
    # v49 could not see the one wrapper with no Save because its population
    # filter required a procedure that wrapper did not call.
    "v59_entry_points.R",
    # The paired wrapper's New-after-Draw rebound to the deleted internal
    # reshape table and dead-ended; Check & repair told users a ragged CSV
    # was clean and Praat's own reader then refused it. The reader's rule was
    # measured over a 35-file battery, not guessed.
    "v60_wrapper_paths.R",
    # The graphs seams. The Kruskal-Wallis annotated draw crashed exactly
    # when the omnibus was SIGNIFICANT -- the only crash reachable from a
    # default journey, and it fired precisely when a user had a result worth
    # annotating. Note the shape of the near-miss: driving the KW wrapper
    # first made the break test PASS, because the wrapper had already
    # declared the matrix. Only the standalone journey shows it.
    "v61_graphs_seams.R",
    # Stereo channel handling had three procedures and zero callers, so a
    # stereo Sound converted to Pitch silently: 220 Hz left and 330 Hz right
    # gave 110 Hz, an F0 in neither channel. Ian ruled it ABSOLUTELY
    # NECESSARY. Also here: a sustained tone that drew as chaos over a
    # collapsed axis, which the audit's own probe had already localised to
    # tick precision rather than to the pitch analysis -- the values were
    # exact to 1e-6 Hz.
    "v62_graphs_axes_channels.R",
    # Six doors coerce a Matrix or TableOfReal into a Table, and after the
    # audit response three of them disagreed about the row-label column.
    # v63 asserts r1..rn PER DOOR rather than comparing doors to each other:
    # three doors agreeing on the wrong thing would satisfy a parity check,
    # which is exactly how the two .std.resid arms diverged for a week.
    "v63_coercion_parity.R",
    # ------------------------------------------------------------------
    # v64-v66: the 15 August author rulings, which are mostly one finding.
    #
    # `fixed$` is not a fixed-precision formatter. Measured on 6.6.30 it
    # uses max(precision, -floor(log10|v|)) and returns a bare "0" for
    # exact zero, so fixed$(-1e-16, 4) prints -0.0000000000000001 and
    # fixed$(0, 4) prints 0 in a column padded for six characters. Every
    # rounded number in the plugin went through it. The visible symptoms
    # were a skewness of -1e-16 in a Describe report and a two-way table
    # whose SS ran into its MS -- seventeen decimals in a sixteen-wide
    # column -- and they were one bug wearing three hats.
    #
    # The rule the author set: statistics print at fixed 4 decimals, p in
    # APA style, and NO raw double reaches the Info window. Full precision
    # belongs to the CSV export, which still uses string$ deliberately.
    # ------------------------------------------------------------------
    # v64 owns the formatter itself and the coercion naming. Ruling 5:
    # source matrix column k is now Column_k. It had been Column_{k+1},
    # because the header repair numbered by TABLE position where the row
    # label occupies slot 1 -- so a user asking for "column 2 of my
    # matrix" picked Column_2 and got column 1's data.
    "v64_display_and_coercion.R",
    # v65 owns the rule in the wizard and the analysis orchestrators. The
    # break test worth knowing about: clamping every number to a zero of
    # the right width is the FIX-SHAPED FIX -- it satisfies every width
    # assertion, and it takes a value check to catch it.
    "v65_display_standard.R",
    # v66 owns the draw layer. Three things there, and the axis one is the
    # reason a validator can be worth more than a figure: a violin
    # recorded with the axis on AUTO emitted its resolved range as
    # literals, so replaying it on other data produced a fully furnished,
    # titled, gridded frame with zero ink inside it and nothing warning.
    # Note what that defeats -- a size threshold. The empty frame weighs
    # 53 KB. v66 asserts ink inside the frame instead.
    "v66_draw_layer.R",
    # ------------------------------------------------------------------
    # v67-v72: the second batch of 15 August rulings.
    #
    # The one worth reading twice is the axis. A figure recorded with the
    # y-axis left on AUTO baked its RESOLVED range into the emitted call,
    # so replaying it on other data produced a titled, labelled, gridded,
    # tick-marked frame with zero ink inside it and nothing warning. The
    # author's ruling: the emitted script's editable block always carries
    # axisYMin/axisYMax, reading 0.0 and 0.0 when the user chose auto --
    # the same sentinel the dialog states -- with the resolved range kept
    # as a note for the reader.
    #
    # Note what that class of defect defeats: a size threshold. The empty
    # frame weighs MORE than the repaired one (48,870 bytes against
    # 48,531), so "the file is big enough to be a real figure" cannot even
    # be pointed the right way at it. v67 asserts ink inside the frame.
    # ------------------------------------------------------------------
    # The Spectrum drew nothing when its range held exactly one bin,
    # because Praat's Draw: joins bin points with segments and one point
    # is no segment -- the peak of the tone landed on the axis rather than
    # on the paper. Ruled "draw what you can": a stem to the frame floor.
    # The dB conversion was the trap. The obvious
    # 10*log10((re^2+im^2)/4e-10) is 10.32 dB LOW, because Draw: plots
    # spectral DENSITY; verified against To Ltas (1-to-1) at five bin
    # widths and then pinned in pixels against Praat's own two-bin figure.
    # Reachability scales with 1/duration, so a 0.15 s token has 5.4 Hz
    # bins and any zoom under ~11 Hz emptied the frame.
    "v67_axis_and_spectrum.R",
    # The form destroyed the evidence before the recorder could see it:
    # it converts auto into explicit ahead of the draw on two paths, the
    # legend-room second pass and the bracket headroom. It now publishes
    # the untouched request, type-dispatched -- because the pair is NOT one
    # variable. A waveform is handed ampMin/ampMax and a spectrum
    # powerMin/powerMax, so publishing valueMin for a waveform would have
    # put an amplitude range in a slot the amplitude dialog never showed.
    "v68_form_axis_and_display.R",
    # A bracket-layout figure disclosed neither its post-hoc test nor its
    # correction, while matrix layout disclosed both -- and bracket layout
    # is the one that puts p-values directly ON the picture. The report
    # always named them, so nothing was hidden from a reader who had the
    # report; the figure is what leaves the session. Precedent taken from
    # ggstatsplot, which captions every figure with the pairwise test and
    # the adjustment, and from SPSS, which states the adjustment beneath
    # its pairwise display.
    "v69_bracket_disclosure.R",
    # p printed APA style and then appended the exact value through
    # string$, Praat's round-trip renderer -- seventeen significant digits
    # of a number the sentence beside it had already rounded. The tail
    # itself is deliberate and stays: flooring at .001 flattens 5.8e-07,
    # 2.1e-13 and 3.0e-04 into one string nine orders of magnitude apart.
    # Bounded to 3 significant figures. @emlReportAlpha keeps its
    # escalation, and now says why: alpha is a CRITERION, not a statistic,
    # and capping it at 4 decimals would print a threshold of .0001 as
    # zero.
    "v70_p_precision.R",
    # Skewness and kurtosis join the tidy vocabulary, closing the
    # asymmetry where single-column normality exported them and
    # multi-column lost them. The hazard on the way in is that the tidy
    # vocabulary is a WHITELIST walked by @eml_orderedCols, so a column
    # not in it is silently dropped -- an earlier attempt shipped a file
    # containing only term and method. Also here: the RM-ANOVA warning
    # string was printed AND exported from one variable, two destinations
    # with opposite rules, so formatting it would have silently edited an
    # exported value. Split.
    "v71_tidy_vocab_and_warning.R",
    # Batch voice analysis is registered. It had been unregistered for
    # want of coverage, which it now has -- and the condition on
    # registering it was a GUI drive through the real dialog, because a
    # registered menu entry that has never been clicked is exactly the
    # dead door the audit's severity-2 findings were about.
    "v72_batch_registration.R",
    # v73: the same subject as v77 further down, in the other evidentiary
    # shape. v77 drives Praat live and keeps nothing; this one is the shape
    # REGISTRY states as the suite's rule -- a
    # number the plugin PRINTED, read out of a COMMITTED capture, against a
    # number R computes from the same COMMITTED input -- so it is the half of
    # the evidence that survives on a machine with no Praat and that a reviewer
    # can diff between releases. evidence/info/v73_directional_info.txt is the
    # first committed capture of a one-tailed p anywhere in this tree, which is
    # also why no golden-file diff could ever have found the defect: there was
    # nothing recorded to have changed from.
    #
    # THE POPULATION THE PREVIOUS 72 DID NOT COVER is not a procedure, a menu
    # path or a data shape -- every one of these five families was already read
    # by v08, v12 and v18. It is a RELATION BETWEEN TWO RUNS. Each of those
    # files asserts one run against R; the defect made every single run
    # correct-looking and only the PAIR wrong, so a suite built entirely out of
    # per-run assertions was blind to it by construction and stayed green on 72
    # validators. This file's unit of evidence is the reversed pair.
    #
    # It also carries the two boundary cases the parametric families cannot
    # reach. The wrong-direction perfect effect (r = -1 against H1: r > 0) is
    # the one place the tail is written out by an explicit `if` rather than
    # taken from studentQ, and the answer there is p = 1 EXACTLY -- certainty
    # in the other direction, not significance. And Mann-Whitney is driven as
    # the CONTROL: its exact tails share the point mass at the observed U, so
    # they sum to 4/3 rather than 1 and its two-sided p is a clamp rather than
    # a doubling. Both invariants therefore have a driven counterexample in the
    # same file that asserts them, which is what keeps ten sum-to-1 checks from
    # being ten assertions of nothing.
    #     bash harness/directional/run.sh
    "v73_directional_p.R",
    # v74: change order 7, ruling A. Praat cannot unset a variable, so the
    # graphs form's axis publication -- the two globals ruling 10(b) added,
    # which say what the user asked for before the form resolves it -- lived
    # for the whole process. @emlRecordAxisRequest preferred them whenever
    # they EXISTED, so "some form ran earlier this session" was
    # indistinguishable from "this draw came from the form": after one press
    # of Draw at 0 .. 100, a recorded Q-Q step declared axisYMax = 100.0 on a
    # figure whose only axis argument is its own auto sentinel.
    #
    # The publication now carries a STEP STAMP, and the stamp is what carries
    # the state because the PAIR cannot: 0/0 IS the auto sentinel, so a reset
    # pair reads as a published AUTO request. Note what that class of defect
    # defeats -- every existing rig, all green on a tree with the bug in it.
    # The leak needs TWO DRAWS IN ONE PROCESS with only the first going
    # through the form, and no harness in this tree performed that sequence;
    # harness/consumeonce does. No pixel changed, either: the figure is drawn
    # on the axis the draw procedure resolves whatever the recorder writes
    # down, so no image comparison can see this one.
    "v74_axis_consume_once.R",
    # AUTHOR RULING B, CHANGE ORDER 8, 16 AUGUST 2026 -- ONE PRESS OF DRAW,
    # ONE RECORDED STEP. @emlGraphsDrawWithLegendRoom draws a legend-bearing
    # figure, measures where the legend landed, and draws it again on a
    # widened axis with the first pass discarded. NEW-G8-3 rewound the CSV
    # collector between those passes on 15 August and left the RECORDER
    # running, so one press emitted the same figure twice -- and, worse than
    # the duplication, the block's resolved-range note quotes the first step
    # to use an axis pair, so it named the axis of the pass that was thrown
    # away: 195.0000 .. 235.0000 beside a figure drawn at 195 .. 275. Under
    # ruling 10(b) an auto axis is emitted as the 0.0 sentinel, which makes
    # that note the file's ONLY record of where the figure sat.
    #
    # The repair is the twin of the CSV pair -- @emlRecordMark /
    # @emlRecordRewind, which name no legend and no pass -- and v75 asserts it
    # on the emitted script rather than on the source, because the obvious
    # implementation passes a source check and fails: Praat refuses to remove
    # a Table's only row and `nocheck` in front of that refusal is a skip, so
    # a figure drawn as the first thing in a recording kept its discarded pass
    # in silence. The note is then proved in BYTES: the block is edited to the
    # two numbers the note itself quotes and the resulting figure is
    # byte-identical to the one the recording drew.
    "v75_legend_single_step.R",
    # AUTHOR RULING C, CHANGE ORDER 9, 16 AUGUST 2026 -- EVERY BRACKET-BEARING
    # FIGURE NAMES ITS TEST. Both two-group arms of @emlBridgeGroupComparison
    # composed an omnibus string, handed it back for the Info window and set
    # annotTextN on NEITHER path; only the k >= 3 arms did. So the form's
    # post-dispatch stage had no line to route into the corner box and a Welch
    # drive left the session carrying a bracket, "***, d = -6.08" and no test
    # name anywhere on it -- v69 measured exactly that and recorded it as an
    # attestation, because closing it was a ruling rather than an
    # implementation detail.
    #
    # This is the THIRD time this shape has been repaired one arm at a time:
    # ruling 1b gave the matrix layout a post-hoc sub-line and left the
    # bracket layout silent, ruling 11 gave the bracket layout a caption on
    # the k >= 3 arms and left k = 2 silent. So v76's subject is the
    # INVARIANT, not the two arms that were fixed. It parses the bridge into a
    # block tree, enumerates every site that writes a bracket label, and
    # requires each one to be DOMINATED by an annotTextN = 1 -- a statement at
    # an enclosing level, not merely one somewhere in the same arm. That
    # distinction is measured rather than argued: the text_n_in_matrix break
    # moves the Welch arm's line inside its own `if .useMatrix`, where an
    # arm-scoped grep still finds it and the bracket path still names nothing.
    # A fifth arm added without a test name goes red with no figure to drive.
    #
    # And the enumeration is only half. The new_arm_silent break is red on the
    # source with every rendered figure unchanged; the no_route break leaves
    # the bridge perfect, deletes the form's route into the corner block, and
    # every source check passes while no figure says anything. Each half sees
    # what the other cannot, so §3 and §4 read the test name back off driven
    # figures with tesseract -- §4 for every leg that has a bracket, out of
    # the leg's own emitted omnibus, so a leg driving a future arm is covered
    # on its first run.
    "v76_bracket_names_test.R",
    # v77: the P0 of 16 August 2026, and the twin of v73 below -- the two
    # were authored in parallel and numbered on landing, so read them as one
    # subject in two evidentiary shapes. The parametric one-tailed p was
    # studentQ(|t|, df) -- the smaller tail of the ABSOLUTE statistic, so
    # swapping the two groups returned the same p both ways and the test
    # could not see the direction it claimed to be testing. Now a fixed
    # alternative, matching what .tails = 1 already meant in
    # @emlMannWhitneyU and @emlWilcoxonSignedRank, with .pGreater, .pLess
    # and .alternative$ exposed and four @...Alt entry points that name the
    # alternative in words. Every registered menu path passes tails = 2, so
    # nothing shipped ever printed the wrong number -- which makes the
    # TWO-sided p the regression to guard, and this file pins all five of
    # them against R at 1e-14 as well as the ten one-tailed ones at 1e-12.
    # This file drives Praat LIVE out of R, which is what lets it sweep
    # counterfactual kernels and measure studentQ on the binary; nothing it
    # reads outlives the run. v73 is the committed-capture half.
    "v77_one_tailed_direction.R",
    # v78 is the only script here whose subject is the REPOSITORY rather than
    # a number the plugin printed: MANIFEST.txt describing the tree it ships
    # with, every @call resolving in its own include closure, the front-door
    # documents linking no missing file, and a CI workflow that runs this
    # suite without a secret. All four were red on 16 August 2026 and three of
    # them had been red long enough that nobody was reading them -- the
    # manifest for twelve days, the include checker with 21 false positives in
    # 22 reports, and plugin/README.md pointing at two pages that have never
    # existed. They are in the suite because a check that lives outside the
    # thing CI runs is a check nobody runs; being here is what makes
    # regenerating the manifest the only route to a green suite.
    "v78_repo_hygiene.R",
    # v79 is the only script here whose subject is a file that is NOT IN THE
    # REPOSITORY: plugin_EML_StatsGraphs, the folder Praat installs, which
    # plugin/dev/tools/build-release.py makes out of plugin/. It cannot be
    # committed, and the reason is the defect it exists to catch -- git records
    # the executable bit and nothing else, so a checked-in copy of the artefact
    # would be a copy with the mode evidence stripped off it. So v79 BUILDS the
    # artefact while the suite runs (0.5 s) and asserts against that: the folder
    # name against the recorder, both digests reproduced by a second build, the
    # whole include closure, and -- the strongest thing in the file -- the zip
    # unpacked under `umask 077` with every mode measured on what unzip
    # produced rather than on what the builder chmodded. That is the only
    # reading in this tree taken on a tree nobody chmodded, and the only one
    # that can see a zip carrying no entry for its own top-level folder, which
    # leaves the whole plugin at 0700 and unreadable to every other account
    # with all 322 files inside it recorded perfectly.
    #
    # The three facts that need an X server -- the menu walk, the falsifier
    # walk, and the label read off the photograph -- come from a committed
    # record, and the header says at length how that record is kept from
    # rotting: bound by digest to setup.praat and to the script the walk
    # reaches, required to carry the key set of a FINISHED run (the evidence at
    # the previous commit was an aborted one, 18 lines of 25, stopping before
    # the falsifier), and censused so that every scalar in it is read by
    # something. That census is the one that matters: the harness's mode
    # counter and its quickstart exit status were both being written and
    # neither was being read, so a run under a restrictive umask and a run
    # whose headless leg died at exit 255 both left it exiting 0.
    #     bash harness/release/run.sh
    "v79_release_artefact.R",
    # v80 is a LINT, and it is the only one here. Every other script reads a
    # number the plugin printed or a claim the repository makes; this one
    # reads the shipped source and rejects a sentence in it. AUTHOR RULING,
    # pre-release: a shipped file describes what the code does, never what it
    # used to do wrong. Defect and change history belongs in git and in
    # plugin/dev/HISTORY_LEDGER.md, and the reason is not tidiness -- a header
    # entry reading "the guard was on .nGroups, which was always true" makes a
    # claim about a version nobody has, standing beside claims about the code
    # in front of the reader, in a file where nothing can tell them apart.
    # That sentence is also the one part of the file this suite cannot
    # exercise, so it is the part that can be wrong indefinitely and stay
    # green.
    #
    # IT IS IN THE RUNNER BECAUSE THE SWEEP'S COMPLETENESS CANNOT BE READ. The
    # sweep it closes removed 1,623 lines of header narration across 27 files
    # and rephrased 78 more, and the failure mode of proving that by reading
    # is a missed line, which looks exactly like a line that was considered
    # and kept. A predicate cannot miss one. So the sweep was DONE when this
    # went green, and it stays done because this now stands guard: the next
    # fix that writes its own history into a shipped header turns the suite
    # red in the commit that wrote it, naming the file and the line.
    #
    # ITS TEN PATTERNS ARE THE CAPTURE TOOL'S. plugin/dev/tools/
    # extract-history.py copied every block into the ledger BEFORE any of it
    # was deleted, using the same list, so "everything this lint would reject
    # was first written down verbatim" is a property of the two files rather
    # than of anyone's memory. R cannot import a Python list, so v80 re-derives
    # the list out of the tool's source and asserts the two are identical;
    # edit one and the suite goes red.
    #
    # EXCEPTIONS ARE A FILE. validate/v80_history_allowlist.tsv carries path,
    # line-pattern and a one-line justification, for the prose that collides
    # with a pattern by naming a developer file whose NAME contains one. An
    # entry that matches nothing is reported as a FAILURE, not skipped: a
    # stale exception tells its reader the tree still holds a line it does
    # not, and waits to excuse some future line on a justification written
    # about another one.
    "v80_shipped_history.R",
    # v81 is a page of documentation, EXECUTED. plugin/docs/RECIPES.md
    # documents the direct-kernel API -- a Table becomes two vectors, the
    # vectors go into @emlTTest and its relatives -- and that surface has the
    # least protection in the plugin, because nothing inside the plugin calls
    # it: every menu command goes through an orchestrator.
    #
    # THE BYTES THAT SHIP ARE THE BYTES THAT RUN. harness/recipes/extract.py
    # lifts each script out of the .md and Praat runs that file; run.sh
    # substitutes exactly two path prefixes -- the install folder and the data
    # folder, the only two things in a pasted script that belong to the
    # reader's machine -- then substitutes them back and demands the original
    # returns byte for byte. Nothing in this tree holds a second copy of a
    # recipe, and v81 re-implements the fence grammar in R and compares
    # out/scripts/R<n>.praat with the page, so a harness that quietly ran its
    # own copy is caught from the other side.
    #
    # A CAPTURE CANNOT PIN ITSELF, so there are three anchors and none of them
    # is the capture. THE PAGE: each "What it printed" block must appear as a
    # contiguous run of lines in that recipe's output, so moving a number makes
    # the page wrong and v81 names the recipe and the line. BASE R: t, Welch
    # df, both p's, Cohen's d, Hedges' g, the paired t, Pearson r and the
    # one-way ANOVA's SS / F / eta-squared are recomputed from the committed
    # fixtures, because the page and the plugin agreeing with each other is not
    # either of them being right. THE PROCEDURE HEADERS: every @call must
    # exist, every procedure.field a recipe READS must be one that procedure
    # assigns, and every argument list the page prints must be the real
    # signature. That last one is what the page is most exposed to -- the
    # extractors return .group1# and .data1#, not the names anyone would guess,
    # and a plausible wrong name reads as correct prose while returning a stale
    # value from the previous call.
    "v81_recipes.R",
    # v82 is the one include line a user writes, and the file setup.praat has
    # to generate for that line to exist. The problem it closes is a property
    # of Praat rather than of this plugin, and v82 re-measures it on the live
    # binary before asserting anything else: `include` is a parse-time text
    # paste, and a relative path inside an included file resolves against the
    # TOP-LEVEL script's folder. So scripts/eml-lib.praat, whose lines read
    # "../stats/...", resolves them against the USER's folder and finds
    # nothing -- and no static file can compute where it was installed to.
    # setup.praat can, because Praat runs it from the plugin's own folder at
    # every launch, and it writes scripts/eml-lib-user.praat with full paths.
    #
    # FOUR THINGS CAN GO WRONG AND ALL FOUR ARE DRIVEN, in sandboxes this file
    # builds from plugin/ into tempdir(): a barrel left stale on disk (seeded,
    # then required to be repaired, and the repair compared byte for byte
    # against a regeneration from nothing); an include list that drifts from
    # the one @emlRecordRender writes into recorded scripts (compared against
    # a real recording made on the same installation, never against a list
    # retyped in the validator); an unchanged launch that writes anyway, read
    # to the nanosecond, which is a REQUIREMENT and not an optimisation
    # because Praat 7 challenges a script that touches disk; and a second copy
    # of the root arithmetic, which is read off the source because no drive
    # can see a duplicate that happens to agree today.
    #
    # AND THE SELF-HEALING IS DRIVEN RATHER THAN ARGUED. Two sandboxes move an
    # installed plugin -- carrying its now-wrong barrel with it -- and launch
    # Praat at the new location; the second move is the one Praat itself makes
    # between 6.x and 7.x, ~/.praat-dir to ~/.config/praat. Both then RUN a
    # user script whose only library line is the generated barrel, because
    # plausible-looking paths are not evidence that paths resolve.
    "v82_generated_barrel.R",
    # v83 is the only script here whose subject is THIS SUITE'S OWN CLAIM TO
    # BE PINNING ANYTHING. Every other file asks whether the plugin is right;
    # this one asks whether the file that says so would notice if it stopped
    # being right.
    #
    # THE FACT IT ENFORCES, and it was measured three times before it was
    # written down. A COMMITTED ARTEFACT IS A WITNESS STATEMENT, NOT A LIVE
    # WITNESS. harness/legend/out/RESULTS.tsv records what the plugin did on
    # the afternoon somebody drove it, and it goes on recording that, in
    # perfect confidence, after the code it describes has been rewritten or
    # reverted. A check that reads only the artefact therefore pins THE
    # ARTEFACT: it proves the file still says what it said, never that the code
    # still does what the file says. The two are indistinguishable in a green
    # run and they are not the same claim.
    #
    # The three sightings: validate/tools/redrive_census.sh re-drove 34
    # harnesses and only 9 reproduced their committed artefacts, 15 differed,
    # and several of the stale ones were what the suite was quoting to state
    # things about the plugin that had stopped being true; v29 asserts 144
    # renders no commit in this repository's history has ever been able to
    # produce; and the findings-ledger backfill reverted plugin/ WHOLESALE, ran
    # 36 validators against it, and eight rows' pinning validators stayed
    # GREEN -- every one of the eight pinned by a validator whose only input is
    # a committed harness artefact. The first and the third are one decoupling
    # seen from opposite ends.
    #
    # So the repair is a DEFINITION rather than eight one-off fixes: a ledger
    # row's pinnedBy may only name a validator that REGENERATES ITS EVIDENCE
    # FROM SOURCE OR DRIVES PRAAT LIVE WITHIN THE RUN. Artefact-only checks are
    # untouched and lose nothing -- v03 settling a printed p against R at half
    # a display ULP is an ORACLE AGREEMENT and is the reason a reviewer with no
    # Praat can still check the statistics. They simply are not PINS, because a
    # pin's whole claim is "something would notice", and the backfill measured
    # what these notice.
    #
    # IT CARRIES NO LIST. A hand-kept table of which validator is which class
    # would be one more thing that can quietly disagree with the tree, which is
    # the disease and not the cure, so v83 sources validate/tools/
    # evidence_census.R and classifies every validator from its own parse tree
    # on every run -- and additionally asserts that the committed census record
    # reproduces from that live classification, so the census's artefact is
    # held to the standard this file exists to state rather than being its one
    # exception.
    #
    # AND IT IS VACUITY-GUARDED IN BOTH DIRECTIONS, because there are exactly
    # two ways it could be green and mean nothing. A classifier that matched
    # nothing would find no artefact-only pins: so v77 and v70 must come back
    # LIVE, v80 SOURCE, v01 and v37 ARTEFACT-ONLY, each named, and the outcome
    # must be a partition rather than a constant -- a broken classifier cannot
    # satisfy assertions pointing in opposite directions. An empty ledger would
    # satisfy the rule vacuously: so an unreadable ledger, a zero-row ledger,
    # and a ledger in which no row claims a pin at all are each a FAILURE.
    # It is READ-ONLY on the ledger. It names the row, the validator and the
    # class, and leaves the editing to a human.
    "v83_pin_definition.R",
    # v84 is a check on an ABSENCE: the figure that must not be drawn. Six axis
    # pairs reach the graphs form from its dialogs, and a pair whose maximum is
    # below its minimum has two readings that nothing in the pair separates --
    # the numbers were reversed, or one side was set and the other left at its
    # default. A Praat field cannot be blank, so a floor of 300 with no ceiling
    # arrives as (300, 0), which is byte-identical to 0 and 300 typed
    # backwards. The form used to choose the first reading and rewrite the
    # pair; a user asking for a floor of 300 got a ceiling of 300, and nothing
    # said so, because the only disclosure on that path speaks when a DATA
    # POINT falls outside the range and after the rewrite the data sits inside
    # it. It refuses now, and refusing means no figure.
    #
    # SO THE SUBJECT IS THE "INSTEAD OF", WHICH NO READ OF THE SOURCE REACHES.
    # The file could hold a perfect refusal, called from the right place, and
    # still draw. harness/axisrefuse/run.sh therefore brings up Xvfb, a window
    # manager and a COMPOSITOR, launches the shipped form seven times, types
    # the reversed pair into the dialog field whose label the message quotes,
    # and records the sequence of dialog titles, the refusal's text read back
    # off its own pixels with tesseract, and the ink in the Picture window at
    # the moment of the refusal against that leg's own empty reading. The
    # compositor is instrument rather than decoration: without one the region a
    # modal dialog covers comes back from XGetImage as a black rectangle, which
    # reads as a very large figure.
    #
    # THE CONTROL LEG POINTS THE OTHER WAY. 0 is both the auto sentinel and an
    # ordinary bound, so (0, 0) and (0, 400) must both DRAW. A repair that read
    # 0 as "left blank" would satisfy every refusal leg and take the range away
    # from everyone who typed a zero bound.
    #
    # AND TWO SOURCE RULES THAT EXTEND THEMSELVES, because a seventh pair added
    # next year is on no transcript: three consecutive statements of the shape
    # `a = b`, `b = c`, `c = a` are a swap whatever the names are and there
    # must be none -- HEAD has six -- and every axis for which the dialogs
    # offer BOTH a minimum and a maximum field must be named to the refusal.
    "v84_axis_refusal.R",
    # v85's subject is not the plugin, and not this suite -- it is the ZIP
    # GITHUB ATTACHES TO A RELEASE WITHOUT BEING ASKED. It builds that archive
    # with `git archive` and opens it, because .gitattributes is a set of
    # patterns and reading patterns is not knowing what a user received. On
    # 17 August 2026 that asset was 84 MB across 3,945 entries to deliver a
    # 4.5 MB plugin. v85 also holds the relationship between the two exclusion
    # lists this repository now has: RELEASE_EXCLUDE.tsv is the sole authority
    # inside plugin/ and .gitattributes the sole authority outside it, and v85
    # recomputes both halves of that partition from RELEASE_EXCLUDE.tsv on
    # every run rather than keeping a second copy of it.
    "v85_source_archive_shape.R",
    # v86's subject is a FIGURE FORMAT THE HOST MAY NOT HAVE. Praat's manual
    # puts "Save as PDF file..." on Macintosh and Linux only, and a command
    # that does not exist does not fail quietly -- it ends the script where it
    # stands, which inside the Save panel takes the receipt, the panel's
    # return and the caller's loop with it. The panel does not ask which
    # operating system it is on: it attempts the save under `nocheck` and then
    # looks for the file, so one piece of code reads both answers and a later
    # Praat that moves its platform support needs no edit here. v86 drives six
    # saves against a real Picture window -- four on a Praat that has all
    # three formats, two on a copy of the panel whose vector command has been
    # renamed to one Praat has not got -- reads the markers out of the bytes
    # itself, and requires the redirect to have been SEEN firing: naming the
    # format that failed, naming PNG, EPS and PDF as the alternatives, and
    # carrying the path of the PNG that is still on disk. Every save the panel
    # claims is now a file it found, the PNG included.
    "v86_vector_figure_export.R",
    # v87's subject is WHICH RUN A VARIABLE BELONGS TO. The editable block at
    # the top of a recorded script names every object, column, axis pair and
    # figure format by the pass that produced it -- run 1's is groupCol$,
    # run 2's is groupCol2$ -- and it does so whether or not run 1 used that
    # role and whether or not the two name the same column. The naming used to
    # key on (role, literal text), so a column called "n" in two different
    # tables collapsed into one variable governing both, and one axis pair was
    # shared across every figure while its resolved-value note quoted only the
    # first. v87 drives eight sessions whose run structure is fixed by the
    # driver -- two runs on two tables, a run using roles the run before it
    # had not, three runs, one pass that saves twice, two runs drawn on the
    # same typed axis literals -- and requires the block to be exactly the set
    # of names the ruling gives, each step to read only its own run's
    # variables, and the one-pass session to be character-identical to what a
    # plugin built from HEAD emits. Two legs edit ONE line of a block and
    # replay: the run that was edited must land on an independently drawn
    # reference and the run that was not must be byte-identical, which is the
    # whole promise of naming by run rather than by value.
    "v87_run_scoped_block.R",
    # v88 is the check that reads the barrel as a POPULATION rather than as a
    # list. setup.praat's module table is the whole of what a user's one
    # include line loads, and on 18 August 2026 two finished, oracled modules
    # were found sitting outside it -- four procedures no script a user could
    # write was able to load, for as long as they had existed. Nothing here
    # could have said so: v82 pins the table against a list retyped inside
    # v82 and against the recorder's block, both satisfied by a change made
    # in both places; v78's include closure asks whether includes RESOLVE,
    # and a module never included dangles nothing; everything else reaches a
    # procedure by calling it. v88 walks stats/ and graphs/ off disk and
    # requires every file to be in the table or in the reasoned
    # not-in-barrel rows beneath it, which live in setup.praat and nowhere
    # else.
    #     bash harness/barrelpop/break.sh
    "v88_barrel_population.R",

    # ------------------------------------------------------------------
    # The survey core statistics. Four kernels a voice researcher needs
    # before a questionnaire can be reported at all, each pinned against
    # an oracle computed in base R from the same numbers -- no package is
    # required to run any of these.
    # ------------------------------------------------------------------
    "v90_lane_alpha_oracle.R",   # Cronbach's alpha against a base-R oracle:
                                 # covariance-matrix alpha, the Feldt
                                 # confidence interval through qf, and the
                                 # alpha-if-item-deleted drops. Where the
                                 # psych package happens to be installed it
                                 # cross-checks the oracle itself at 1e-12
                                 # and says which mode it ran in, the same
                                 # arrangement v17 has with broom. Drives
                                 # Praat live; carries its own seeded-defect
                                 # negative control.
    "v91_lane_chisq_oracle.R",   # chi-square independence and Cramer's V
                                 # against chisq.test on both correction
                                 # settings, the warning behaviour, and the
                                 # refusal on a zero margin. Drives Praat
                                 # live; negative control inside.
    "v92_lane_wilson_oracle.R",  # the Wilson interval against
                                 # prop.test(correct = FALSE), including the
                                 # endpoints at no successes and at all
                                 # successes, where the ordinary formula is
                                 # at its worst, plus two published pins.
                                 # Drives Praat live; negative control inside.
    "v93_lane_alpha_influence_oracle.R"
                                 # the respondent-influence jackknife against
                                 # a base-R leave-one-out oracle: every
                                 # dropped-respondent alpha and its change,
                                 # the equality between the full-sample alpha
                                 # here and the one the alpha kernel reports,
                                 # and -- the part that matters to whoever
                                 # reads the output -- that a flagged
                                 # respondent is named by their row in the
                                 # ORIGINAL table, not by their position
                                 # after incomplete rows were dropped.
                                 # Drives Praat live.
    ,
    "v94_page_composition.R"     # page composition: the draw dialog's erase
                                 # tickbox and typed panel origin, the extent
                                 # union as the page, the parked separate
                                 # legend taking its band below that union,
                                 # the save panel naming a page, and the
                                 # recorder carrying the page a figure went
                                 # on. Its first section is the one that
                                 # matters most -- the same figure drawn
                                 # through the controls at their defaults and
                                 # with those globals never assigned, compared
                                 # byte for byte, so the default path is
                                 # proved unmoved rather than asserted.
                                 # Reads harness/compose.
    ,
    "v95_second_axis.R"          # the second vertical axis and the pens: two
                                 # series in one draw, the right series taking
                                 # the palette's next slot, an auto right-hand
                                 # range placed at the same fractions of the
                                 # box the left series occupies, the four line
                                 # styles measured on the rendered ink, the
                                 # refusal every other figure type gives in
                                 # the words its own shape earns, the emitted
                                 # script replaying a two-scale figure byte
                                 # for byte, and the dialogs driven under Xvfb
                                 # so that the follow-up page is photographed
                                 # re-presenting itself on a column it cannot
                                 # use. Section 12 is the measurement that
                                 # settled the one thing the ruling left open:
                                 # Praat's margin commands draw in black
                                 # whatever colour is current, so the right
                                 # scale cannot wear its series' colour.
                                 # Reads harness/secondaxis.
    ,
    "v96_line_style.R"           # the four pens. Every line this plugin drew
                                 # before this change order was solid: there
                                 # was no call to a line-style command
                                 # anywhere in the graphs layer and no option
                                 # for one. There is now a menu on every type
                                 # that strokes a series, and the proof is a
                                 # RUN STRUCTURE rather than a pixel count --
                                 # where the ink stops and starts along the
                                 # stroke -- because no count separates Dashed
                                 # from Dashed-dotted. Four presses of Draw
                                 # differing in one option must give four
                                 # distinct signatures, in the order the
                                 # geometry predicts, with the margins stated.
                                 # The reset is pinned on a SECOND figure
                                 # drawn in the same process: a bar chart
                                 # after a dotted line chart must be the bar
                                 # chart drawn alone, byte for byte, and a bar
                                 # chart sets no pen of its own, so nothing in
                                 # its code would be wrong if the pen leaked.
                                 # Reads harness/linestyle.
    ,
    "v97_line_tree.R"             # the line chart's question tree. The page
                                 # used to open by asking how the user's FILE
                                 # was shaped -- a question the plugin can
                                 # answer for itself -- instead of what the
                                 # columns MEAN, which is the one thing no
                                 # file records and which decides whether the
                                 # figure has one vertical axis or two. The
                                 # storage question is gone, the column page
                                 # is built from the table with no ceiling
                                 # where five hardcoded slots used to be, the
                                 # interval is offered only where the table
                                 # carries repeats and names how many, and
                                 # three unlike measurements are refused
                                 # toward stacked panels. Driven as DIALOGS,
                                 # because the claims are about what a user
                                 # can reach: harness/linetree photographs
                                 # every page before dismissing it and reads
                                 # the form's variables back out of the
                                 # process that drew. Both refusals are pinned
                                 # on the words displayed, including the last
                                 # line, which was drawn under the OK button
                                 # until this harness saw it.
                                 # Reads harness/linetree.
    ,
    "v98_field_names.R"          # Praat derives a dialog field's variable
                                 # name from its LABEL, truncating at the
                                 # first character that is not a letter,
                                 # digit, space or underscore. "Right-hand
                                 # axis" therefore derives `right`, the code
                                 # reading `right_hand_axis` aborts, and the
                                 # label looks perfectly correct while every
                                 # two-measurement line chart refuses to
                                 # draw. That shipped once. This walks every
                                 # dialog field in the tree and asserts each
                                 # label derives its whole name, and that no
                                 # two fields in one dialog derive the same
                                 # name -- a collision being a wrong value
                                 # rather than an error, and so worse.
                                 # Source only; reads no harness.
    ,
    "v99_form_variable_locality.R" # Praat names a field's variable for you and
                                 # that variable is a global it cannot unset,
                                 # so the same label on two pages is one
                                 # variable -- deliberate here, since thirteen
                                 # graph pages share `gridline_mode` and
                                 # friends. What makes the sharing safe is that
                                 # every page reads its own fields the moment
                                 # its dialog closes. A page that OFFERS a
                                 # field and never reads it silently draws
                                 # from whatever the last page that did offer
                                 # it left behind: the user types a number and
                                 # nothing happens, with no error anywhere.
                                 # This asserts every dialog reads every field
                                 # it offers, before another dialog offering
                                 # the same field can overwrite it. It has to
                                 # be green before any wording pass that makes
                                 # labels shorter, because shorter labels
                                 # collide more.
                                 # Source only; reads no harness.
    ,
    "v100_box_geometry.R"        # Praat stores a viewport as an OUTER rectangle
                                 # and converts it using the margins in effect
                                 # at that moment, and margin width is a
                                 # function of font size -- so a figure whose
                                 # font size changes between two
                                 # coordinate-dependent commands draws them on
                                 # two different rectangles, and nothing
                                 # errors. The figure saves, the pixel counts
                                 # every other harness takes come back normal,
                                 # and the only witness is where the ink
                                 # landed. This reads the frame, the ticks and
                                 # the plotted extremes out of a saved EPS as
                                 # numbers and asserts they are one rectangle,
                                 # for all thirteen figure types, with two
                                 # break tests that move the font by one point
                                 # and must turn it red.
                                 # Reads harness/boxgeom.
    ,
    "v101_dispatch_coverage.R"   # thirteen figure types reach the page through
                                 # the form's dispatch, and until this existed
                                 # nothing drove any of them through it. Every
                                 # other harness calls a draw procedure
                                 # directly or drives one type through the
                                 # dialogs, so a fault in the seam between the
                                 # form and a draw procedure was reachable by a
                                 # user and by nothing here -- which is how a
                                 # scatter that aborted with recording off
                                 # reached the author's machine. One Praat
                                 # process per type, because an abort kills the
                                 # process and a loop would stop at the first
                                 # failure. Recorded and unrecorded are separate
                                 # legs: the fault that shipped was invisible
                                 # with recording on.
                                 # Reads harness/dispatch.
    ,
    "v102_correlate_grouping.R"  # the correlation wrapper builds its grouping
                                 # menu before the page opens, from the X and Y
                                 # of the previous pass, while X and Y are
                                 # chosen on that same page -- so a column just
                                 # moved onto X is still on the menu, and
                                 # picking it correlates a variable against
                                 # itself split by itself. It does not error:
                                 # it prints a report whose every number is an
                                 # artefact of the grouping. Neither the source
                                 # checks nor the parse drive can see that, so
                                 # the buttons are pressed in that order and
                                 # the output read.
                                 # Reads harness/correlgroup.
    ,
    "v103_legend_encoding.R"     # legend placement has the same shape gridline
                                 # mode has -- one registry, one seed, one
                                 # commit, one clamp -- and until now nothing
                                 # asserted any of it. What the numbers on disk
                                 # MEAN is decided by the option lists, so six
                                 # dialogs whose lists drifted apart would put
                                 # a legend somewhere the user did not choose
                                 # with nothing red. Registry, dispatch,
                                 # seed/commit counts and the six option lists,
                                 # character-identical and in order.
                                 # Source only; reads no harness.
    ,
    "v104_ascii_fold.R"          # one non-ASCII character makes Praat rewrite
                                 # a whole file as UTF-16 -- measured, on
                                 # 6.6.30 -- and R, pandas and Excel cannot
                                 # read it. The fold at the CSV and report
                                 # boundary is what stops a user's export
                                 # becoming unopenable, and nothing drove a
                                 # curly quote or a degree sign through it. The
                                 # bytes on disk are read as bytes, because the
                                 # tools that read them as text are the ones
                                 # whose behaviour is the defect.
                                 # Reads harness/asciifold.
    ,
    "v105_pitch_parity.R"        # the pitch parameters agree across the graph,
                                 # batch, recorder and test paths BY HAND. A
                                 # single flag drifting moves a reported mean
                                 # by about a hertz on a short token -- a wrong
                                 # number in someone's paper, with nothing red
                                 # anywhere. Every To Pitch call in the tree is
                                 # found and censused, executed calls told from
                                 # the ones a recorded script only emits, so a
                                 # call site added later and not enumerated
                                 # turns this red rather than passing unseen.
                                 # Source only; reads no harness.
    ,
    "v106_wizard_wording.R"      # the wizard's two design questions decide
                                 # which test runs. Labelling the whole
                                 # within-subject branch "paired" sent a user
                                 # with three or more conditions to the
                                 # independent option, which runs a
                                 # between-subjects test on within-subject
                                 # data. Pins the two ruled sentences and the
                                 # absence of the two they replaced, and the
                                 # value lines rather than the gloss wording.
                                 # Source only; reads no harness.
    ,
    "v107_record_census.R"       # of the 42 commands the menu registers, which
                                 # ones leave a trace in a recorded script. The
                                 # universe is read from setup.praat, so a
                                 # command added tomorrow is in the population
                                 # tomorrow. Four record nothing today and are
                                 # named with what each one loses; the list is
                                 # a ratchet, red if a fifth appears AND red if
                                 # one is fixed without its line being removed.
                                 # Source only; reads no harness.
    ,
    "v108_fisher_alpha_oracle.R" # the Fisher-z interval printed beside r takes
                                 # its level from the Alpha the user set on the
                                 # dialog, like every other interval on that
                                 # figure. A hardcoded 1.96 agrees with
                                 # cor.test at exactly one alpha and misstates
                                 # every other one while printing a fixed
                                 # "95% CI" label over it. Drives the shipped
                                 # reporter live at alpha = .05 and .01 against
                                 # cor.test(conf.level = 1 - alpha), reads the
                                 # bracket out of the Info text, and asserts
                                 # the .01 interval is strictly wider at both
                                 # ends and that the label names its own level.
                                 # The unset-annotAlpha headless path is driven
                                 # for the documented 0.05 fallback. Drives
                                 # Praat live; negative control inside.
    ,
    "v109_report_ci_alpha_oracle.R" # the same rule for the three intervals
                                 # that spell the level as a TAIL PROBABILITY
                                 # rather than as a z value, which is why a
                                 # search for 1.96 cannot see them: the
                                 # two-group report's CI of the difference,
                                 # the regression coefficient table's CI
                                 # column, and the Feldt interval on
                                 # Cronbach's alpha. Drives all three live at
                                 # two alphas against t.test, confint(lm) and
                                 # the published Feldt form, requires each
                                 # printed label to name the level it used,
                                 # and requires every bound to move when the
                                 # alpha does. The headless path is driven for
                                 # the documented 0.05 fallback. Drives Praat
                                 # live; one negative control per site.
    ,
    "v110_roundtrip_replay.R"    # the recorded script IS the session, run
                                 # again. One recording of eight user actions,
                                 # then the emitted file run three times in
                                 # fresh Praat processes: the colleague's
                                 # replay, the same replay out of a Praat set
                                 # hostile first (another typeface, font size
                                 # 60, thick red lines, the page and the
                                 # coordinate system redefined, a drawing
                                 # already on the page), and a retarget leg
                                 # over a second fixture that has to come out
                                 # DIFFERENT or every comparison above is a
                                 # constant. Requires the session's numbers,
                                 # its five result files and its figure back
                                 # byte for byte -- zero differing pixels,
                                 # hostile included -- with a control that
                                 # measures those same settings moving an
                                 # ordinary Praat drawing by 10,206 to 196,601
                                 # pixels. Also censuses the recorder's whole
                                 # step-kind vocabulary, read out of the
                                 # sources rather than declared, against the
                                 # kinds the emitted file carries. Reads
                                 # harness/roundtrip/out/ROUNDTRIP.tsv.
    ,
    "v111_cold_start_census.R"   # every door, opened from the state a
                                 # first-time user is actually in: NOTHING
                                 # SELECTED. One fixture, and it is the
                                 # absence of a fixture -- which is why no
                                 # other rig had it, since every one of them
                                 # begins by making a table. The population is
                                 # the twenty commands setup.praat registers,
                                 # read through the same walk v107 uses, plus
                                 # the wizard's fifteen branches, which count
                                 # separately because Ian's crash was
                                 # branch-ORDER dependent. Each leg must
                                 # either refuse honestly -- the plugin's own
                                 # refusal, its own dialog, or its own
                                 # sentence -- or answer the "No table
                                 # selected" page and carry on to a column
                                 # page, which is where the crash was. A raw
                                 # Praat error fails; so does the rig failing
                                 # to drive, under its own name. Ratcheted in
                                 # both directions on the leg name, and
                                 # refuted by a resolver gate that fails on a
                                 # walk of zero and prints how many entry
                                 # points it covered. Reads
                                 # harness/coldstart/out/COLDSTART.tsv.
    ,
    "v112_settings_census.R"     # every setting the DRAWING LAYER reads,
                                 # classified as one that changes the result
                                 # or one that changes only what is shown.
                                 # A setting in neither list goes red. The
                                 # population is derived from the two doors
                                 # the store ruling names -- their declared
                                 # parameters, plus every global their call
                                 # closure reads that the plugin assigns
                                 # somewhere and the closure itself does not
                                 # write. Never from the dialog: a dialog
                                 # cannot show a setting that has no control,
                                 # and one of the fifteen has none. Ratcheted
                                 # both ways, and refuted by a resolver gate
                                 # that fails on a walk of zero. Reads
                                 # harness/settings/out/SETTINGS.tsv.
    ,
    "v113_cancel_path_reads.R"   # the escape hatch is permitted only where
                                 # its path reads no typed field value. For
                                 # every dialog whose window-close maps to a
                                 # safe never-mind, the path taken on that
                                 # press must reach no read of the page's own
                                 # field names before they are reassigned.
                                 # Shares v98's resolver rather than carrying
                                 # a second copy, so rows a procedure
                                 # contributes to a page are part of the
                                 # subject here too. Fails on a walk of zero
                                 # and prints how many paths it covered.
    ,
    "v114_fingerprint_suite.R"   # the data fingerprint's own 278 legs, run
                                 # from inside this suite. They live in the
                                 # phase2 tree, which this suite does not
                                 # call, so a shipped component's only
                                 # evidence was evidence it wrote about
                                 # itself. Reads both channels the test
                                 # contract names -- the process exit status
                                 # AND the printed result line -- because
                                 # exit 0 alone is what that contract forbids
                                 # a runner to trust. Fails on a missing file,
                                 # an unresolvable Praat, an unparseable
                                 # result, or a total of zero.
    ,
    "v115_settings_publication.R" # the three settings that change a result
                                 # and travel as globals -- the correction
                                 # method, the interval level, and the group
                                 # ordering -- reach the recorded script, and
                                 # a replay obeys them. Driven at two values
                                 # each, so a leg cannot pass on the default
                                 # it would fall back to. Reads
                                 # harness/settingspub/out/SETTINGSPUB.tsv.
    ,
    "v117_pair_group_placement.R" # every two-box numeric row in the graphs
                                 # form sits under the heading that says what
                                 # it is: a row whose parenthetical names an
                                 # orientation on the page is an axis range
                                 # and renders under the axes heading, and a
                                 # row under that heading names an
                                 # orientation. Closes v84's blind spot -- its
                                 # roster is derived from the axes heading, so
                                 # a range misfiled under any other heading
                                 # escapes the refusal sweep entirely and is
                                 # silently rewritten instead of refused.
                                 # Reads the graphs form's dialog source.
    ,
    "v122_posthoc_never_gated.R"  # a post-hoc the user chose runs whatever
                                 # the omnibus said -- on every door -- and
                                 # the report says what that means: the
                                 # caution line at the alpha in force, and
                                 # the effect-size caption when the post-hoc
                                 # is off. Driven through the menu, the
                                 # wizard (real GUI under Xvfb) and the
                                 # graph doors on a fixture whose omnibus is
                                 # not significant, with the tables oracled
                                 # against aov / TukeyHSD / kruskal.test.
                                 # The second half is static and is the
                                 # ratchet: no call to a post-hoc, pairwise
                                 # or effect-size producer sits under an
                                 # omnibus p anywhere in the shipping tree.
                                 # Reads harness/posthocgate/out/.
    ,
    "v123_nummiss.R"             # @emlCheckNumericColumn counts Praat's
                                 # native missing cell as missing rather
                                 # than as non-numeric. A column holding one
                                 # undefined cell used to vanish from every
                                 # dialog that filters on this check instead
                                 # of being analysed complete-case. Reads
                                 # evidence/info/v123_nummiss_info.txt.
    ,
    "v124_describesniff.R"       # Describe Table's numeric-column filter
                                 # reads every row rather than the first
                                 # five: a column whose opening rows are
                                 # missing is offered, and a column that
                                 # turns to text below the sampled window is
                                 # not. Reads
                                 # evidence/info/v124_describesniff_info.txt.
    ,
    "v125_group_order_persistence.R"  # the ordering clause is printed by
                                 # every grouped comparison reporter, worded
                                 # as approved, and printed always rather
                                 # than only where explanations are on. The
                                 # group-order choice lives for a session and
                                 # not on disk: absent from the config file's
                                 # load and save, present as a session
                                 # restore. Population derived from the
                                 # reporters themselves.
    ,
    "v126_normality_coverage.R"  # an assessment that could not test every
                                 # group says so, and never generalises over
                                 # a group it did not examine. Population
                                 # derived from the too-small-to-test skip
                                 # idiom rather than from a list of the two
                                 # places that use it.
    ,
    "v116_frozen_choice_conformance.R"  # a door that freezes a choice its
                                 # sibling offers must say so in its output.
                                 # Reads the reviewed correspondence map, which
                                 # has its own author: a wrong map makes this
                                 # noisy, an incomplete one makes it blind, and
                                 # only blindness is caught by the count gate.
                                 # Reports how many correspondences it walked.
    ,
    "v127_door_agreement_census.R"  # every intent reachable through more than
                                 # one door, on a fixture built so that two
                                 # doors mapping the data differently give
                                 # loudly different numbers. Each leg asserts
                                 # the doors agree to the oracle, or that they
                                 # say plainly they show different models.
                                 # Silent disagreement is the only red. Reads
                                 # harness/doorcensus/out/DOORCENSUS.tsv.
    ,
    "v128_wizard_flow_invariant.R"  # the wizard's goto-chained pages: every
                                 # label some goto jumps back to must write
                                 # the user's answer back into the seed
                                 # variable (@wizardColIdx / @wizardCondSlot)
                                 # BEFORE that goto, or the re-render shows
                                 # the plugin's guess instead of what was
                                 # typed. Label set, jump targets and
                                 # preservable fields are all derived from
                                 # scripts/eml-wizard.praat itself, so a page
                                 # added later is in scope by construction;
                                 # reports how many labels it walked, and
                                 # seeds one write-back out through
                                 # EML_DIALOG_SRC to prove it can go red.
    ,
    "v130_explanations_gate.R"  # punch list 6.1: one fixture (Kruskal-
                                 # Wallis, no Dunn) through the wizard (GUI,
                                 # harness/wizardback), a menu dialog with
                                 # "Annotate results with explanations" off,
                                 # and the same dialog on (headless,
                                 # harness/explaingate) -- identical
                                 # statistics on all four captures, the
                                 # explanation line present only where the
                                 # ruling says on. Also reads the source
                                 # shape of @emlHandleCommonFields and
                                 # @emlGraphsWorkflow's entry. Red demo:
                                 # harness/explaingate/break.sh.
    ,
    "v131_explanation_wiring.R" # punch list 6.2: the seven reporter sites in
                                 # stats/eml-analysis.praat and
                                 # stats/eml-output.praat that gained
                                 # explanation lines -- pairwise (Welch,
                                 # Student, Scheffe, Wilcoxon), RM ANOVA,
                                 # Friedman, and descriptive statistics.
                                 # Drives each measure with explanations off
                                 # and on (harness/explainwiring) and asserts
                                 # the statistics are byte-identical once the
                                 # explanation lines are stripped, plus a
                                 # source-shape section anchoring each site's
                                 # read of emlShowExplanations. Red demo:
                                 # harness/explainwiring/break.sh.
    ,
    "v132_routing_split.R"      # the language batch's DISCLOSURE/EXPLANATION
                                 # routing, over WHOLE reports rather than a
                                 # list of sentences: subtracts the
                                 # explanations-off report from the
                                 # explanations-on one across nineteen
                                 # analyses (harness/routingsplit) and asserts
                                 # no line the toggle removes is a labelled
                                 # statistic row, nothing appears only when
                                 # the toggle is off, and the off leg carries
                                 # no stray two-tab suffix. Carries risk R1's
                                 # settings-permutation drive (display toggle
                                 # x group sort x alpha, harness/routingsplit/
                                 # permute.sh) and records what R1 cannot
                                 # assert while no result store exists. Red
                                 # demo: harness/routingsplit/break.sh.
    ,
    "v133_dialog_field_guard.R"  # a procedure that reads a dialog field must
                                 # not stop the script when it is called
                                 # without one. Praat ends a script on an
                                 # unset variable, so an unguarded read is a
                                 # dead script rather than a wrong number.
                                 # Derives the fields from the block that
                                 # declares them and the call sites from the
                                 # tree, and reports how many of each it
                                 # walked.
    ,
    "v134_error_read_lint.R"     # punch list 9.2: a call to an error-producing
                                 # procedure must be followed by a read of that
                                 # call's .error$ before any numeric output of
                                 # it is used. Derives both populations from
                                 # the tree (producers that assign .error$;
                                 # call sites that go on to read another field
                                 # of the same call) and reports how many of
                                 # each it walked. Vacuity kit: v98 import
                                 # asserted, audited-site and producer floors,
                                 # exempt-set staleness gates, and a seeded
                                 # violation confirmed caught. RED BY DESIGN
                                 # until item 9.3's sweep reaches zero -- the
                                 # tag is not cut while this shows red.
    ,
    "v135_errorprop91.R"         # punch list 9.1: the four hand fixes -- the
                                 # missing else in @emlRequireNumericColumn,
                                 # the effect-size matrices printing n/a
                                 # instead of a zero-filled cell for a failed
                                 # pair, the standalone normality checker
                                 # printing the producer's error text instead
                                 # of undefined W and p, and "both" mode
                                 # disclosing a single-arm failure. Reads the
                                 # committed red and green captures under
                                 # harness/errorprop91/ and harness/normality/
                                 # out/site3/; never re-derives from live
                                 # Praat.
    ,
    "v136_regression_grouping.R" # punch list 4.5: per-group regression
                                 # fits beside the overall one, ported from
                                 # the correlate dialog's pattern into ONE
                                 # shared procedure (@emlRunGroupedRegression)
                                 # both the menu door and both wizard
                                 # regression pages call. Oracled against
                                 # base R's lm() per group on Sol's Simpson
                                 # fixture (harness/regressiongroup/). Red
                                 # demo: harness/doorcensus's own leg5,
                                 # which fails on purpose against the
                                 # pre-port source; this file's own
                                 # structural section reads red the same
                                 # way against the pre-fix eml-regress.praat
                                 # and eml-wizard.praat.
    ,
    "v137_correlation_scope.R"   # punch list 8.3: the scatter page's
                                 # "Relationships shown" scope control
                                 # (Per group / Overall / Both, each line
                                 # labeled) -- replaces the interim
                                 # per-group-only disclosure language batch
                                 # item 15 also specifies, confirmed absent
                                 # from the tree before this item. Oracled
                                 # against base R's cor.test() per scope on
                                 # Sol's Simpson-for-correlation fixture
                                 # (harness/corrscope/, leg6 of the door
                                 # census). Red demo: harness/corrscope/
                                 # run.sh --red, driven against the
                                 # pre-fix eml-draw-procedures.praat at git
                                 # HEAD -- committed and reusable, not a
                                 # scratch run.
)

# ---------------------------------------------------------------------------
# QUESTION ONE: IS EVERY ENTRY IN THAT LIST A REAL SCRIPT?
# ---------------------------------------------------------------------------
# The comma that started this is refused by the handler above, but it is one
# member of a family and the loudest member at that. The quiet ones survive
# evaluation: c("a.R", "", "b.R") is a perfectly good character vector, a NULL
# entry disappears without trace and shortens the list by one, and a renamed
# file leaves an entry pointing at nothing. `source()` on a missing file does
# error -- but on a file that has been emptied it does not, and a validator
# reduced to nothing contributes no checks and no complaint.
#
# So the list is read as data before a line of it is run, and the whole list is
# reported at once rather than one fault per run.
faults <- character(0)
if (!is.character(scripts)) {
    faults <- c(faults, sprintf("the list is %s, not a character vector",
                                class(scripts)[1]))
} else {
    if (!length(scripts)) faults <- c(faults, "the list is empty")
    na <- which(is.na(scripts))
    if (length(na))
        faults <- c(faults, sprintf("entry %d is NA", na))
    blank <- which(!is.na(scripts) & !nzchar(trimws(scripts)))
    if (length(blank))
        faults <- c(faults, sprintf(
            "entry %d is empty -- a stray comma or a deleted name", blank))
    dupe <- unique(scripts[duplicated(scripts)])
    if (length(dupe))
        faults <- c(faults, sprintf("%s is listed more than once", dupe))
    real <- scripts[!is.na(scripts) & nzchar(trimws(scripts))]
    paths <- file.path(HERE, real)
    gone <- real[!file.exists(paths)]
    if (length(gone))
        faults <- c(faults, sprintf("%s is not in %s", gone, HERE))
    here <- real[file.exists(paths)]
    sz <- file.size(file.path(HERE, here))
    if (any(sz == 0))
        faults <- c(faults, sprintf("%s is an empty file", here[sz == 0]))

    # ---------------------------------------------------------------------
    # AND THE OTHER DIRECTION, WHICH IS THE ONE THAT ACTUALLY BIT.
    # ---------------------------------------------------------------------
    # Everything above asks whether each NAME in the list is a real file.
    # Nothing asked whether each real FILE is in the list, and that asymmetry
    # is silent by construction: a validator nobody lists contributes no
    # checks and no complaint, so the suite reports green over a check that
    # never ran. v100_box_geometry.R sat written, passing and unlisted for a
    # day -- the one check standing between the font-geometry defect class
    # and a repeat, reporting nothing.
    #
    # The population is every file in this folder named vNN_*.R. The four
    # that are not validators -- this file, the coverage census, the shared
    # helpers and the LRE oracle -- do not match that shape, so the rule
    # needs no exception list to maintain.
    onDisk <- sort(grep("^v[0-9]+_.*\\.R$",
                        list.files(HERE), value = TRUE))
    unlisted <- setdiff(onDisk, real)
    if (length(unlisted))
        faults <- c(faults, sprintf(
            "%s is in %s but not in the list -- it would never run", unlisted,
            HERE))
}
if (length(faults))
    eml_abort(sprintf("the script list is not a list of scripts (%d fault(s)):",
                      length(faults)),
              faults)

cat("EML Stats & Graphs validation suite\n")
cat("R ", R.version$major, ".", R.version$minor, "  ",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")
cat(length(scripts), " scripts to source from ", HERE, "\n", sep = "")

# COUNTED, NOT ASSUMED. The loop cannot silently skip an iteration today, and
# that is exactly the kind of thing a later rewrite -- a tryCatch put round the
# source() so "one bad script does not stop the suite", say -- changes without
# meaning to. The counter costs one integer and holds the promise open.
n_sourced <- 0L
# AND WHAT EACH ONE PUT IN THE ACCUMULATOR, read off EML_RESULTS itself rather
# than inferred from the id a script writes into its rows. The two are not the
# same thing: v07_redpath_degenerate_inputs.R records under R1..R7, so a guess
# that a file named v07 files its checks under "v07" reports it silent when it
# is the opposite. Row counts before and after are exact and need to know
# nothing about naming.
contributed <- integer(length(scripts))
for (i in seq_along(scripts)) {
    s <- scripts[i]
    cat("\n>> ", s, "\n", sep = "")
    before <- length(EML_RESULTS$rows)
    source(file.path(HERE, s), local = new.env(parent = globalenv()))
    contributed[i] <- length(EML_RESULTS$rows) - before
    n_sourced <- n_sourced + 1L
}
if (n_sourced != length(scripts))
    eml_abort("not every script in the list was sourced:",
              sprintf("%d of %d ran", n_sourced, length(scripts)))

# THE COVERAGE PASS, LAST AND ONLY HERE. coverage.R compares what every
# validator above CLAIMED, recorded through eml_claim() as each one ran,
# against the population it reads off each artefact itself. It needs all the
# claims, so it cannot run before them, and it does nothing when run alone.
#
# It is what asks the question no single validator can: for each thing a
# driver renders, is there SOME authored check that names it? On 12 Aug 2026
# the answer for 29 of the 39 stress cases was no, and every check in the
# tree was green. See §19 of audit/GRAPHING_PUSH_REMAINING.md.
cat("\n>> coverage.R\n")
source(file.path(HERE, "coverage.R"), local = new.env(parent = globalenv()))

df <- eml_report("SUMMARY — all scripts")

if (!is.null(df)) {
    # P4, 6 Aug 2026. This aggregate counted attestations while the headline
    # did not, so the per-script column summed to 460 against a headline of
    # 454 and R7 read 8/8 with an ATST inside it. Two presentations of the
    # same run must not disagree. Attestations are excluded here and reported
    # in their own column instead.
    chk <- df[df$expect != "attested", , drop = FALSE]
    cat("\nBy script id:\n")
    agg <- aggregate(pass ~ id, data = chk,
                     FUN = function(x) sprintf("%d/%d", sum(x), length(x)))
    names(agg) <- c("id", "passed")
    att <- df[df$expect == "attested", , drop = FALSE]
    if (nrow(att)) {
        n_att <- as.data.frame(table(att$id), stringsAsFactors = FALSE)
        names(n_att) <- c("id", "attested")
        agg <- merge(agg, n_att, by = "id", all.x = TRUE)
        agg$attested[is.na(agg$attested)] <- 0L
    }
    print(agg, row.names = FALSE)
}

# ---------------------------------------------------------------------------
# QUESTION THREE: DID THE RUN RECORD A PLAUSIBLE NUMBER OF CHECKS?
# ---------------------------------------------------------------------------
# THE FLOOR IS THE LENGTH OF THE LIST, AND IT IS DERIVED RATHER THAN TYPED.
#
# WHAT THIS GUARD IS FOR: catastrophic non-execution. The list never built, the
# accumulator was reset between scripts, a refactor left every validator
# recording into an environment nobody reads. It is NOT a coverage measure and
# must not be allowed to become one, because a number that tracks the real
# total goes red on the next commit that adds a check, and a number people edit
# on every commit is a number nobody reads.
#
# A LITERAL IS THE WRONG SHAPE, and this repository has the receipts. v79 held
# a floor of "at least 100 include lines in the installed tree"; the artefact
# legitimately fell to 42 when dev/ joined RELEASE_EXCLUDE.tsv, and until that
# day the number had never once been the thing that failed. A hardcoded total
# here would be the same object, checked more often.
#
# A FLOOR OF 1 IS ALSO THE WRONG SHAPE. One validator running and ninety not is
# the disaster this block exists for, and it clears a floor of 1 comfortably.
#
# ONE CHECK PER SOURCED SCRIPT is the weakest statement a broken run still
# cannot satisfy. On the run this line was written against the ratio was 13,637
# checks over 91 sourced files -- 150 to 1 -- so the floor sits two orders of
# magnitude under the truth and moves by itself: add a validator, the floor
# rises by one, and nobody edits anything.
#
# IT IS AN AGGREGATE ON PURPOSE, because a rule of "every script contributes a
# check" is false on a clean machine. v19_nist_strd.R contributes nothing until
# the NIST .dat files have been ingested -- they are not redistributable -- and
# prints a loud SKIP instead. Those scripts are NAMED below rather than counted,
# so a reader sees which ones were quiet without the suite refusing to pass.
n_checks <- if (is.null(df)) 0L else sum(df$expect != "attested")
floor_checks <- n_sourced

quiet <- scripts[contributed == 0L]
# Printed only when SOME script was quiet. When every one of them is, the list
# is the whole suite and the banner below says it better.
if (length(quiet) && length(quiet) < length(scripts))
    cat("\nrecorded nothing: ", paste(quiet, collapse = ", "), "\n", sep = "")

if (n_checks < floor_checks)
    eml_abort("the run recorded too few checks to have happened:",
              c(sprintf("%d check(s) from %d sourced script(s)",
                        n_checks, n_sourced),
                sprintf("the floor is one check per sourced script, %d here",
                        floor_checks),
                "",
                "This is not a coverage judgement. A number this low means the",
                "checks did not run or were not recorded at all."))

eml_exit()
