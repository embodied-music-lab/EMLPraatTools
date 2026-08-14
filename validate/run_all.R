#!/usr/bin/env Rscript
# ============================================================================
# EML Praat Tools — validation suite runner
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
    # literals. It was written `plugin_EMLPraatTools` for the real
    # `plugin_EML_Praat_Tools` and pasted into eleven `include` lines of every
    # script the recorder emitted, so every recorded script was unrunnable.
    # Three things had to be true at once for that to survive: the phase1 test
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
    "v54_batch_praatgen.R"
)

cat("EML Praat Tools validation suite\n")
cat("R ", R.version$major, ".", R.version$minor, "  ",
    format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n", sep = "")

for (s in scripts) {
    cat("\n>> ", s, "\n", sep = "")
    source(file.path(HERE, s), local = new.env(parent = globalenv()))
}

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

eml_exit()
