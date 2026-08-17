# ============================================================================
# EML Praat Tools — Stats Wizard
# ============================================================================
# Purpose: Question-driven statistical analysis wizard. Routes research
#          questions to the appropriate test via chained dialogs, runs the
#          analysis, and reports results in the Info window.
#
#          Three layers of access (this script = Layer 1):
#            Layer 1 — Wizard: Question-driven entry for clinicians/students
#            Layer 2 — Direct tools: Named tests from EML Tools menu
#            Layer 3 — Scripting API: Include-file procedures for power users
#
# Version: 2.6
# Date: 8 August 2026
#
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use
# per your target journal's policy. Suggested language:
#
#   "Praat analysis scripts were developed using the EML PraatGen
#    Scripting Assistant (Howell, Embodied Music Lab) with code
#    generation by Claude (Anthropic). All scripts were reviewed,
#    tested, and validated by Ian Howell."
#
# The script author assumes responsibility for the correctness and
# appropriate application of this code.
# ============================================================================

include eml-lib-lmm.praat

# ── Wizard mode: enable third-column explanations ────────────────────────
emlShowExplanations = 1

# ── Check Table or TableOfReal selection ──────────────────────────────────

nTables = numberOfSelected ("Table")
nToR = numberOfSelected ("TableOfReal")
hasTable = 0
tableId = 0
nCols = 0

if nTables = 1 and nToR = 0
    tableId = selected ("Table")
    tableName$ = selected$ ("Table")
    displayTable$ = replace$ (tableName$, "_", " ", 0)
    hasTable = 1
elsif nTables = 0 and nToR = 1
    torId = selected ("TableOfReal")
    torName$ = selected$ ("TableOfReal")
    selectObject: torId
    To Table: "Group"
    tableId = selected ("Table")
    tableName$ = selected$ ("Table")
    displayTable$ = replace$ (torName$, "_", " ", 0)
    ... + " (converted)"
    hasTable = 1
    # THE SAME DEFAULT ROW LABELS AS EVERY OTHER DOOR, r1..rn. The wizard
    # coerces on its own rather than through @emlWrapperInit — a fourth
    # coercion site, and one that names its label column "Group" instead of
    # "row" — so it had none of the conversion-side repair. On a TableOfReal
    # the user never labelled, `To Table:` writes the literal "?" into every
    # cell of that column, and the sentence below then claimed row labels
    # were in it. Filling the gaps here makes the claim true and keeps the
    # column classifying as labels rather than as a measurement.
    #
    # WHAT IS DELIBERATELY NOT DONE HERE. The column is still called "Group",
    # not "row", and the converted Table is still not renamed
    # eml_converted_<source> the way the other three doors now rename it.
    # Both are visible to the user — one in every column menu on this path,
    # one in the object list — so both are the author's call, not a repair.
    @eml_defaultRowLabels: tableId, "Group"
    if eml_defaultRowLabels.nDefaulted > 0
        appendInfoLine: "Converted TableOfReal """, torName$,
        ... """ to Table. Row labels are in column ""Group""; ",
        ... eml_defaultRowLabels.nDefaulted, " row(s) had none and were "
        ... + "given default labels r1..rn."
    else
        appendInfoLine: "Converted TableOfReal """, torName$,
        ... """ to Table. Row labels are in column ""Group""."
    endif
    appendInfoLine: ""
elsif nTables = 0 and nToR = 0
    hasTable = 0
else
    # THE PLUGIN'S OWN SURFACE. A raw `exitScript:` with a
    # message is shown by Praat as its own error window with "Script exited.
    # ... Command ... not executed." under it, which is the interpreter's
    # stack in place of a refusal. "entry" mode is the one written for a
    # refusal that happens before any form exists — it names what to select
    # and offers no Back, because there is nothing behind it yet.
    @emlErrorDialog: "The wizard works on one table at a time, and the "
    ... + "Objects window currently has " + string$ (nTables + nToR)
    ... + " suitable object(s) selected.",
    ... "one Table|one TableOfReal|nothing at all, for example data", "entry"
    exitScript: ""
endif


# ###########################################################################
# MAIN WIZARD LOOP
# ###########################################################################

# Persistence variables (survive across loop iterations / Back navigation)
prevCheckNorm = 0
prevGoal = 1
prevObsType = 1
prevGroupDesign = 1
prevRelType = 1
# 1 = Welch (unequal variances), 2 = pooled/Student (equal variances)
prevVarAssume = 1

runAgain = 1
while runAgain = 1

wizCanDraw = 0
# Drawing and exporting are separate capabilities and were gated by one
# flag. Repeated measures and Friedman set wizCanDraw = 0 because there is no
# figure for them yet — which also removed the CSV button from two analyses
# the CSV migration had already built exports for.
#
# EVERY BRANCH THAT RUNS AN ANALYSIS SETS wizCanExport. Describe and
# normality included: @emlRunDescriptiveAnalysis declares, the wizard's
# Describe-by-group goes through it rather than running its own summary, and
# the standalone normality page calls @emlRunNormalityAnalysis rather than the
# wizard's pre-check diagnostic. All three declare.
#
# The one branch that does not set it is the LMM page: mixed models are TABLED
# and the route into them is disconnected, so there is no user-reachable path
# to it. validate/v49 checks that by name rather than by silence.
wizCanExport = 0
wizDrawSource$ = ""
wizTestType$ = "parametric"
wizPairedCol1$ = ""
wizPairedCol2$ = ""
wizTwoWayFactor1$ = ""
wizTwoWayFactor2$ = ""
dataCol$ = ""
groupCol$ = ""
corrCol1$ = ""
corrCol2$ = ""

# ── Refresh column names on each loop iteration ───────────────────────────

if hasTable
    selectObject: tableId
    @emlTableColumnNames: tableId
    nCols = emlTableColumnNames.nCols
    if nCols < 2
        # Same routing as the selection refusal above. No remedy is offered:
        # every wizard route needs two columns, so there is nothing else to
        # send the user to, and naming a menu entry that would also refuse is
        # worse than saying nothing.
        @emlErrorDialog: "The wizard compares or relates two things, so it "
        ... + "needs at least two columns, and """ + displayTable$
        ... + """ has " + string$ (nCols) + ".", "", "entry"
        exitScript: ""
    endif
endif


# ═══════════════════════════════════════════════════════════════════════════
# Q1: RESEARCH GOAL
# ═══════════════════════════════════════════════════════════════════════════

label Q1_GOAL

beginPause: "EML Stats Wizard"
    if hasTable
        comment: "📋 Table: " + displayTable$
    else
        comment: "📋 No Table selected — example data will be created."
    endif
    comment: "─────────────────────────────────────"
    comment: ""
    comment: "⚖️ Are my groups different?"
    comment: "     → Compare groups or conditions"
    comment: ""
    comment: "📈 Do two variables move together?"
    comment: "     → Examine a relationship"
    comment: ""
    comment: "📊 What does my data look like?"
    comment: "     → Describe or summarize"
    comment: ""
    comment: "🎯 Can I predict an outcome?"
    comment: "     → Predict from one or more variables"
    comment: ""
    comment: "· · · · · · · · · · · · · · · · · · · · ·"
    comment: ""
    comment: "⬜ Classify observations (coming soon)"
    comment: "⬜ Reduce dimensionality (coming soon)"
    comment: ""
    comment: "─────────────────────────────────────"
    optionmenu: "Research goal", prevGoal
        option: "⚖️ Compare groups or conditions"
        option: "📈 Examine a relationship"
        option: "📊 Describe or summarize"
        option: "🎯 Predict an outcome"
        option: "⬜ Classify observations"
        option: "⬜ Reduce dimensionality"
    comment: ""
clicked = endPause: "Quit", "Continue", 2, 0
if clicked = 1
    exitScript: ""
endif
goal = research_goal
prevGoal = goal


# ═══════════════════════════════════════════════════════════════════════════
# BRANCH A: COMPARE GROUPS OR CONDITIONS
# ═══════════════════════════════════════════════════════════════════════════

if goal = 1

    # ── A1: Independent or paired? ─────────────────────────────────────────

    label A1_OBS_TYPE

    beginPause: "Compare — Observation type"
        comment: "Were the same people measured more than once?"
        comment: ""
        optionmenu: "Observation type", prevObsType
            option: "No — different groups (independent)"
            option: "Yes — same people, repeated (paired)"
        comment: ""
    clicked = endPause: "Quit", "Back", "Continue", 3, 0
    if clicked = 1
        exitScript: ""
    elsif clicked = 2
        goto Q1_GOAL
    endif
    obsType = observation_type
    prevObsType = obsType


    # ── A2: INDEPENDENT — How many groups? ─────────────────────────────────

    if obsType = 1

        label A2_INDEP_DESIGN

        beginPause: "Compare independent — Design"
            comment: "How many groups are you comparing?"
            comment: ""
            optionmenu: "Group design", prevGroupDesign
                option: "Two groups"
                option: "Three or more groups"
                option: "Two-factor design (two grouping variables)"
            comment: ""
        clicked = endPause: "Quit", "Back", "Continue", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto A1_OBS_TYPE
        endif
        groupDesign = group_design
        prevGroupDesign = groupDesign


        # ── A2a: TWO INDEPENDENT GROUPS ───────────────────────────────────

        if groupDesign = 1

            @wizardPrepareTable: "twogroups"
            dataDefault = wizardPrepareTable.dataDefault
            groupDefault = wizardPrepareTable.groupDefault

            normChecked = 0
            normDefault = 1
            normSummary$ = ""

            label A2A_NORM_PAGE

            beginPause: "Two groups — Select columns"
                comment: "📋 Table: " + displayTable$
                comment: "─────────────────────────────────────"
                comment: ""
                optionmenu: "Data column", dataDefault
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
                optionmenu: "Group column", groupDefault
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
                comment: ""
                boolean: "Check normality", prevCheckNorm
                comment: ""
                comment: "· · · · · · · · · · · · · · · · · · · · ·"
                comment: ""
                comment: "ℹ️ Normality tells you whether a parametric"
                comment: "     test (more powerful) or nonparametric"
                comment: "     test (fewer assumptions) is appropriate."
            clicked = endPause: "Quit", "Back", "Continue", 3, 0
            if clicked = 1
                exitScript: ""
            elsif clicked = 2
                goto A2_INDEP_DESIGN
            endif
            dataCol$ = data_column$
            groupCol$ = group_column$

            # Preserve column indices for Back navigation, through
            # @wizardColIdx, the one idiom every page in the file uses.
            @wizardColIdx: dataCol$
            dataDefault = wizardColIdx.idx
            @wizardColIdx: groupCol$
            groupDefault = wizardColIdx.idx

            # Validate group count before proceeding
            selectObject: tableId
            @emlCountGroups: tableId, groupCol$
            if emlCountGroups.nGroups <> 2
                # This guard always returned to the column page, which was
                # right, but it said so through a bare @pauseScript whose only
                # buttons are Stop and Continue — neither of which states what
                # it does, and neither of which names the design that would
                # work. Same surface as every other error now.
                @emlErrorDialog: "Expected 2 groups in """
                ... + groupCol$ + """, found "
                ... + string$ (emlCountGroups.nGroups)
                ... + ". Select a different group column.",
                ... "Three or more groups — on the Design page", "wizard"
                if not emlErrorDialog.back
                    exitScript: ""
                endif
                goto A2A_NORM_PAGE
            endif

            prevCheckNorm = check_normality
            if check_normality
                @wizardNormCheck: "group", tableId, dataCol$,
                ... groupCol$
                normDefault = wizardNormCheck.recommendation
                normChecked = 1
                normSummary$ = wizardNormCheck.summary$
            endif

            # ── Test config page ──────────────────────────────────────

            label A2A_TEST_PAGE

            beginPause: "Two independent groups — Choose test"
                comment: "📋 Table: " + displayTable$
                comment: "     " + replace$ (dataCol$, "_", " ", 0)
                ... + " · by "
                ... + replace$ (groupCol$, "_", " ", 0)
                comment: "─────────────────────────────────────"
                if normChecked
                    comment: ""
                    if normDefault = 1
                        comment: "✅ Normality looks reasonable"
                        comment: "     A parametric test should be safe here."
                    else
                        comment: "❌ Normality not supported"
                        comment: "     Consider nonparametric, or check Info"
                        comment: "     window — see Shapiro-Wilk details."
                    endif
                    comment: ""
                    comment: "· · · · · · · · · · · · · · · · · · · · ·"
                endif
                comment: ""
                comment: "Parametric — independent-samples t-test, Cohen's d"
                comment: "More statistical power. Assumes approximate normality."
                comment: ""
                comment: "Nonparametric — Mann-Whitney U, rank-biserial r"
                comment: "Works on any distribution. Tests rank order, not means."
                comment: ""
                comment: "─────────────────────────────────────"
                optionmenu: "Test approach", normDefault
                    option: "Parametric"
                    option: "Nonparametric"
                comment: ""
                comment: "Variance assumption (parametric only):"
                comment: "     Welch does not assume equal group variances"
                comment: "     and is the safer default."
                optionmenu: "Variance assumption", prevVarAssume
                    option: "Welch (unequal variances)"
                    option: "Pooled (equal variances)"
                boolean: "Clear Info window", 0
                comment: ""
            clicked = endPause: "Quit", "Back", "Run", 3, 0
            if clicked = 1
                exitScript: ""
            elsif clicked = 2
                goto A2A_NORM_PAGE
            endif

            if clear_Info_window
                @emlClearInfo
            endif

            # ── Dispatch ───────────────────────────────────────────────

            @wizardNormLabel: normChecked, normSummary$, test_approach

            prevVarAssume = variance_assumption
            if variance_assumption = 2
                wizEqualVar = 1
                wizTName$ = "Student t-test, pooled variance (Cohen's d)"
            else
                wizEqualVar = 0
                wizTName$ = "Welch t-test, unequal variances (Cohen's d)"
            endif

            if test_approach = 1
                wizTestType$ = "parametric"
                @wizardReportPlan: "Two independent groups",
                ... wizardNormLabel.result$,
                ... wizTName$,
                ... "n/a", dataCol$, groupCol$, "", displayTable$
                @emlRunTwoGroupAnalysis: tableId, dataCol$,
                ... groupCol$, "parametric", wizEqualVar
                if emlRunTwoGroupAnalysis.error$ <> ""
                    # An analysis error must not tear down the wizard. Return
                    # the user into the back-chain with every answer intact.
                    @emlErrorDialog: emlRunTwoGroupAnalysis.error$, emlRunTwoGroupAnalysis.remedy$, "wizard"
                    if emlErrorDialog.back
                        goto A2A_NORM_PAGE
                    endif
                    exitScript: ""
                endif
            else
                wizTestType$ = "nonparametric"
                @wizardReportPlan: "Two independent groups",
                ... wizardNormLabel.result$,
                ... "Mann-Whitney U (rank-biserial r)",
                ... "n/a", dataCol$, groupCol$, "", displayTable$
                @emlRunTwoGroupAnalysis: tableId, dataCol$,
                ... groupCol$, "nonparametric", wizEqualVar
                if emlRunTwoGroupAnalysis.error$ <> ""
                    # An analysis error must not tear down the wizard. Return
                    # the user into the back-chain with every answer intact.
                    @emlErrorDialog: emlRunTwoGroupAnalysis.error$, emlRunTwoGroupAnalysis.remedy$, "wizard"
                    if emlErrorDialog.back
                        goto A2A_NORM_PAGE
                    endif
                    exitScript: ""
                endif
            endif
            wizCanDraw = 1
            wizCanExport = 1
            wizDrawSource$ = "group"

            goto WIZ_WHAT_NEXT


        # ── A2b: THREE OR MORE INDEPENDENT GROUPS ─────────────────────────

        elsif groupDesign = 2

            @wizardPrepareTable: "kgroups"
            dataDefault = wizardPrepareTable.dataDefault
            groupDefault = wizardPrepareTable.groupDefault

            normChecked = 0
            normDefault = 1
            normSummary$ = ""

            label A2B_NORM_PAGE

            beginPause: "Three+ groups — Select columns"
                comment: "📋 Table: " + displayTable$
                comment: "─────────────────────────────────────"
                comment: ""
                optionmenu: "Data column", dataDefault
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
                optionmenu: "Group column", groupDefault
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
                comment: ""
                boolean: "Check normality", prevCheckNorm
                comment: ""
                comment: "· · · · · · · · · · · · · · · · · · · · ·"
                comment: ""
                comment: "ℹ️ Normality tells you whether a parametric"
                comment: "     test (more powerful) or nonparametric"
                comment: "     test (fewer assumptions) is appropriate."
            clicked = endPause: "Quit", "Back", "Continue", 3, 0
            if clicked = 1
                exitScript: ""
            elsif clicked = 2
                goto A2_INDEP_DESIGN
            endif
            dataCol$ = data_column$
            groupCol$ = group_column$

            # Preserve column indices for Back navigation, through
            # @wizardColIdx, the one idiom every page in the file uses.
            @wizardColIdx: dataCol$
            dataDefault = wizardColIdx.idx
            @wizardColIdx: groupCol$
            groupDefault = wizardColIdx.idx

            # Validate group count before proceeding
            selectObject: tableId
            @emlCountGroups: tableId, groupCol$
            if emlCountGroups.nGroups < 3
                # As above — same guard, same surface.
                if emlCountGroups.nGroups = 2
                    @emlErrorDialog: "Only 2 groups in """
                    ... + groupCol$
                    ... + """. This branch compares three or more.",
                    ... "Two groups — on the Design page", "wizard"
                else
                    @emlErrorDialog: "Fewer than 2 groups in """
                    ... + groupCol$
                    ... + """. Select a different group column.",
                    ... "", "wizard"
                endif
                if not emlErrorDialog.back
                    exitScript: ""
                endif
                goto A2B_NORM_PAGE
            endif

            prevCheckNorm = check_normality
            if check_normality
                @wizardNormCheck: "group", tableId, dataCol$,
                ... groupCol$
                normDefault = wizardNormCheck.recommendation
                normChecked = 1
                normSummary$ = wizardNormCheck.summary$
            endif

            # ── Test config page ──────────────────────────────────────

            label A2B_TEST_PAGE

            beginPause: "Three or More Groups — Test"
                comment: "Data: " + replace$ (dataCol$, "_", " ", 0)
                ... + "    Group: "
                ... + replace$ (groupCol$, "_", " ", 0)
                if normChecked
                    comment: ""
                    if normDefault = 1
                        comment: "Normality: reasonable"
                        ... + " — parametric test pre-selected"
                    else
                        comment: "Normality: not supported"
                        ... + " — nonparametric test pre-selected"
                    endif
                    comment: "See Info window for full"
                    ... + " Shapiro-Wilk assessment."
                endif
                comment: ""
                comment: "├── Parametric: one-way ANOVA with post-hoc"
                comment: "      └── More powerful when normality holds"
                comment: "└── Nonparametric: Kruskal-Wallis with Dunn"
                comment: "      └── Fewer assumptions"
                comment: ""
                optionmenu: "Test approach", normDefault
                    option: "Parametric"
                    option: "Nonparametric"
                comment: ""
                comment: "If the overall test is significant, the wizard will compare"
                comment: "each pair of groups. How cautious should those comparisons be?"
                comment: ""
                optionmenu: "Correction approach", 1
                    option: "Standard (recommended)"
                    option: "Conservative (fewer false positives, may miss real differences)"
                    option: "Liberal (more sensitive, higher false positive risk)"
                boolean: "Clear Info window", 0
                comment: ""
            clicked = endPause: "Quit", "Back", "Run", 3, 0
            if clicked = 1
                exitScript: ""
            elsif clicked = 2
                goto A2B_NORM_PAGE
            endif

            if clear_Info_window
                @emlClearInfo
            endif

            # ── Map correction approach ────────────────────────────────────

            corrApproach = correction_approach

            # ── Dispatch: ANOVA or KW ──────────────────────────────────────

            @wizardNormLabel: normChecked, normSummary$, test_approach

            if test_approach = 1
                wizTestType$ = "parametric"

                # Map correction to post-hoc method name. The name must
                # match the test actually dispatched below, including
                # whether it is gated on ANOVA significance: Tukey is run
                # by the ANOVA orchestrator unconditionally, Scheffe and
                # pairwise Welch t only when the ANOVA is significant.
                if corrApproach = 1
                    phMethod$ = "Tukey HSD (all pairs)"
                elsif corrApproach = 2
                    phMethod$ = "Scheffe if ANOVA significant"
                else
                    phMethod$ = "Pairwise Welch t, BH adjusted,"
                    ... + " if ANOVA significant"
                endif

                @wizardReportPlan: "Three or more independent groups",
                ... wizardNormLabel.result$,
                ... "One-way ANOVA (η²)",
                ... phMethod$,
                ... dataCol$, groupCol$, "", displayTable$

                doTukey = 0
                if corrApproach = 1
                    doTukey = 1
                endif

                @emlRunAnovaAnalysis: tableId, dataCol$, groupCol$, doTukey
                if emlRunAnovaAnalysis.error$ <> ""
                    # An analysis error must not tear down the wizard. Return
                    # the user into the back-chain with every answer intact.
                    @emlErrorDialog: emlRunAnovaAnalysis.error$, emlRunAnovaAnalysis.remedy$, "wizard"
                    if emlErrorDialog.back
                        goto A2B_NORM_PAGE
                    endif
                    exitScript: ""
                endif

                # Post-hoc if significant
                # corrApproach=1 (Tukey) already reported by ANOVA orchestrator
                if emlOneWayAnova.p < 0.05 and emlOneWayAnova.nGroups >= 3
                    if corrApproach = 2
                        @emlRunPairwiseAnalysis: tableId, dataCol$,
                        ... groupCol$, "scheffe", "none"
                        if emlRunPairwiseAnalysis.error$ <> ""
                            appendInfoLine: "NOTE: Post-hoc error — "
                            ... + emlRunPairwiseAnalysis.error$
                        endif
                    elsif corrApproach = 3
                        @emlRunPairwiseAnalysis: tableId, dataCol$,
                        ... groupCol$, "welch", "bh"
                        if emlRunPairwiseAnalysis.error$ <> ""
                            appendInfoLine: "NOTE: Post-hoc error — "
                            ... + emlRunPairwiseAnalysis.error$
                        endif
                    endif
                endif

            else
                wizTestType$ = "nonparametric"

                # @emlRunKWAnalysis is called with doDunn = 1 below, so
                # Dunn runs on all pairs regardless of the KW p-value.
                if corrApproach = 1
                    phMethod$ = "Dunn (Holm), all pairs"
                    adjMethod$ = "holm"
                elsif corrApproach = 2
                    phMethod$ = "Dunn (Bonferroni), all pairs"
                    adjMethod$ = "bonferroni"
                else
                    phMethod$ = "Dunn (BH), all pairs"
                    adjMethod$ = "bh"
                endif

                @wizardReportPlan: "Three or more independent groups",
                ... wizardNormLabel.result$,
                ... "Kruskal-Wallis (ε²)",
                ... phMethod$,
                ... dataCol$, groupCol$, "", displayTable$

                @emlRunKWAnalysis: tableId, dataCol$, groupCol$, 1,
                ... adjMethod$
                if emlRunKWAnalysis.error$ <> ""
                    # An analysis error must not tear down the wizard. Return
                    # the user into the back-chain with every answer intact.
                    @emlErrorDialog: emlRunKWAnalysis.error$, emlRunKWAnalysis.remedy$, "wizard"
                    if emlErrorDialog.back
                        goto A2B_NORM_PAGE
                    endif
                    exitScript: ""
                endif
            endif

            wizCanDraw = 1
            wizCanExport = 1
            wizDrawSource$ = "group"

            goto WIZ_WHAT_NEXT


        # ── A2c: TWO-FACTOR DESIGN ────────────────────────────────────────

        elsif groupDesign = 3

            @wizardPrepareTable: "twofactor"
            dataDefault = wizardPrepareTable.dataDefault
            f1Default = wizardPrepareTable.f1Default
            f2Default = wizardPrepareTable.f2Default

            label A2C_TWOFACTOR

            beginPause: "Two-Factor Design"
                comment: "Select the columns that hold your data. You need one"
                comment: "measurement column and two columns that define groups."
                comment: ""
                comment: "Table: " + displayTable$
                optionmenu: "Data column", dataDefault
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
                optionmenu: "Factor 1", f1Default
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
                optionmenu: "Factor 2", f2Default
                for iCol from 1 to nCols
                    option: emlTableColumnNames.name$[iCol]
                endfor
                boolean: "Clear Info window", 0
                comment: ""
            clicked = endPause: "Quit", "Back", "Run", 3, 0
            if clicked = 1
                exitScript: ""
            elsif clicked = 2
                goto A2_INDEP_DESIGN
            endif

            # This page had no preserve step at all — its three seeds
            # were written once at A2C entry and never again, so both
            # `goto A2C_TWOFACTOR` returns re-rendered the guess. Worse, the
            # Run button is on this page: a user who pressed Run without
            # touching anything after such a return got the GUESSED model
            # run and reported as if it were theirs.
            @wizardColIdx: data_column$
            dataDefault = wizardColIdx.idx
            @wizardColIdx: factor_1$
            f1Default = wizardColIdx.idx
            @wizardColIdx: factor_2$
            f2Default = wizardColIdx.idx

            if factor_1$ = factor_2$
                # A correctable selection mistake must not end the wizard.
                @emlErrorDialog: "Factor 1 and Factor 2 must be different columns.", "", "wizard"
                if emlErrorDialog.back
                    goto A2C_TWOFACTOR
                endif
                exitScript: ""
            endif

            if clear_Info_window
                @emlClearInfo
            endif

            dataCol$ = data_column$
            groupCol$ = factor_1$

            @wizardReportPlan: "Two-factor design",
            ... "n/a", "Two-way ANOVA",
            ... "n/a", data_column$, factor_1$ + " × " + factor_2$,
            ... "", displayTable$

            @emlRunTwoWayAnalysis: tableId, data_column$,
            ... factor_1$, factor_2$
            if emlRunTwoWayAnalysis.error$ <> ""
                # An analysis error must not tear down the wizard. Return
                # the user into the back-chain with every answer intact.
                @emlErrorDialog: emlRunTwoWayAnalysis.error$, emlRunTwoWayAnalysis.remedy$, "wizard"
                if emlErrorDialog.back
                    goto A2C_TWOFACTOR
                endif
                exitScript: ""
            endif

            wizCanDraw = 1
            wizCanExport = 1
            wizDrawSource$ = "twoway"
            wizTwoWayFactor1$ = factor_1$
            wizTwoWayFactor2$ = factor_2$
            wizTestType$ = "parametric"

            goto WIZ_WHAT_NEXT

        endif


    # ── A3: PAIRED / REPEATED ─────────────────────────────────────────────

    else

        # A3 entry gate: two conditions (paired) or three-or-more (RM). (H4)
        label A3_NCOND_PAGE
        beginPause: "Paired / repeated — how many conditions?"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            comment: "How many repeated measurements per subject?"
            optionmenu: "Conditions", 1
                option: "Two (paired t-test / Wilcoxon)"
                option: "Three or more (RM-ANOVA / Friedman)"
            comment: ""
            comment: "Each condition is its own column; each row is one"
            comment: "subject measured under every condition (wide format)."
        clicked = endPause: "Quit", "Back", "Continue", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto A1_OBS_TYPE
        endif
        if conditions = 2
            goto A3K_PREP
        endif

        @wizardPrepareTable: "paired"
        col1Default = wizardPrepareTable.col1Default
        col2Default = wizardPrepareTable.col2Default

        normChecked = 0
        normDefault = 1
        normSummary$ = ""

        label A3_NORM_PAGE

        beginPause: "Paired — Select columns"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            optionmenu: "Column 1", col1Default
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            optionmenu: "Column 2", col2Default
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            comment: ""
            boolean: "Check normality", prevCheckNorm
            comment: ""
            comment: "· · · · · · · · · · · · · · · · · · · · ·"
            comment: ""
            comment: "ℹ️ Normality tells you whether a parametric"
            comment: "     test (more powerful) or nonparametric"
            comment: "     test (fewer assumptions) is appropriate."
        clicked = endPause: "Quit", "Back", "Continue", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto A1_OBS_TYPE
        endif

        # BEFORE the guard, not after it. This page is re-entered by
        # `goto A3_NORM_PAGE` from the guard below and from two sites on the
        # test page, and a preserve step under the guard would be skipped on
        # the one return the user is most likely to take, so the page would
        # come back showing @wizardPrepareTable's guess.
        @wizardColIdx: column_1$
        col1Default = wizardColIdx.idx
        @wizardColIdx: column_2$
        col2Default = wizardColIdx.idx
        prevCheckNorm = check_normality

        if column_1$ = column_2$
            # A correctable selection mistake must not end the wizard.
            @emlErrorDialog: "Please select two different columns.", "", "wizard"
            if emlErrorDialog.back
                goto A3_NORM_PAGE
            endif
            exitScript: ""
        endif

        if check_normality
            @wizardNormCheck: "paired", tableId, column_1$,
            ... column_2$
            normDefault = wizardNormCheck.recommendation
            normChecked = 1
            normSummary$ = wizardNormCheck.summary$
        endif

        # ── Test config page ──────────────────────────────────────────

        label A3_TEST_PAGE

        beginPause: "Paired / repeated — Choose test"
            comment: "📋 Table: " + displayTable$
            comment: "     " + replace$ (column_1$, "_", " ", 0)
            ... + " · vs · "
            ... + replace$ (column_2$, "_", " ", 0)
            comment: "─────────────────────────────────────"
            if normChecked
                comment: ""
                if normDefault = 1
                    comment: "✅ Differences look normally distributed"
                    comment: "     A parametric test should be safe here."
                else
                    comment: "❌ Normality of differences not supported"
                    comment: "     Consider nonparametric, or check Info"
                    comment: "     window — see Shapiro-Wilk details."
                endif
                comment: ""
                comment: "· · · · · · · · · · · · · · · · · · · · ·"
            endif
            comment: ""
            comment: "Parametric — Paired t-test, Cohen's d"
            comment: "More powerful when differences are approximately normal."
            comment: ""
            comment: "Nonparametric — Wilcoxon signed-rank, r"
            comment: "Works on any distribution. Fewer assumptions."
            comment: ""
            comment: "─────────────────────────────────────"
            optionmenu: "Test approach", normDefault
                option: "Parametric"
                option: "Nonparametric"
            boolean: "Clear Info window", 0
            comment: ""
        clicked = endPause: "Quit", "Back", "Run", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto A3_NORM_PAGE
        endif

        if clear_Info_window
            @emlClearInfo
        endif

        @wizardNormLabel: normChecked, normSummary$, test_approach

        if test_approach = 1
            @wizardReportPlan: "Two paired / repeated measures",
            ... wizardNormLabel.result$,
            ... "Paired t-test (Cohen's d)",
            ... "n/a", column_1$, "", column_2$, displayTable$
            @emlRunPairedAnalysis: tableId, column_1$, column_2$,
            ... "parametric"
            wizTestType$ = "parametric"
        else
            @wizardReportPlan: "Two paired / repeated measures",
            ... wizardNormLabel.result$,
            ... "Wilcoxon signed-rank (r)",
            ... "n/a", column_1$, "", column_2$, displayTable$
            @emlRunPairedAnalysis: tableId, column_1$, column_2$,
            ... "nonparametric"
            wizTestType$ = "nonparametric"
        endif
        if emlRunPairedAnalysis.error$ <> ""
            # An analysis error must not tear down the wizard. Return
            # the user into the back-chain with every answer intact.
            @emlErrorDialog: emlRunPairedAnalysis.error$, emlRunPairedAnalysis.remedy$, "wizard"
            if emlErrorDialog.back
                goto A3_NORM_PAGE
            endif
            exitScript: ""
        endif

        # Paired path — enable spaghetti plot draw
        wizPairedCol1$ = column_1$
        wizPairedCol2$ = column_2$
        wizCanDraw = 1
        wizCanExport = 1
        wizDrawSource$ = "paired"

        goto WIZ_WHAT_NEXT

        # ── A3K: THREE OR MORE REPEATED CONDITIONS (RM-ANOVA / Friedman) ──
        #
        # The six condition slots are NOT seeded with fixed option indices
        # 2/3/4 against a list whose first entry is "(none)" — i.e. table
        # columns 1, 2 and 3 whatever they contain. On a wide RM table column
        # 1 is normally the subject identifier, so that default selection
        # makes a string ID column into "Condition 1" and drops the last real
        # condition. Every row then reads as missing on that
        # condition and the analysis failed with "Need at least 2
        # Complete-case subjects" on complete data.
        #
        # The list offered here is therefore built, not assumed: numeric
        # columns only, with the column @emlGuessColumnRoles identifies as
        # the subject identifier removed even when it is numeric. Because
        # "(none)" is item 1 of THAT list, seeds 2/3/4 now mean the first
        # three genuine conditions.
        label A3K_PREP

        @wizardPrepareTable: "paired"
        @emlGuessColumnRoles: tableId
        a3kSubjIdx = emlGuessColumnRoles.subjectIdx

        a3kN = 0
        for iCol from 1 to nCols
            if iCol <> a3kSubjIdx
                @emlValidateNumericColumn: tableId,
                ... emlTableColumnNames.name$[iCol]
                if emlValidateNumericColumn.nNumeric > 0
                    a3kN = a3kN + 1
                    a3kName$[a3kN] = emlTableColumnNames.name$[iCol]
                endif
            endif
        endfor

        if a3kN < 3
            # Say which requirement is unmet, before the user picks anything.
            # The shortfall is in the TABLE's shape, and naming it here is
            # not the
            # same as telling a user with complete data that it is incomplete.
            @emlErrorDialog: "Repeated measures needs at least 3 numeric"
            ... + " condition columns. This Table has " + string$ (a3kN) + ".",
            ... "Each condition needs its own numeric column, with one row"
            ... + " per subject (wide format).|A column of text — a subject"
            ... + " name or a condition label — cannot be a condition.|If a"
            ... + " condition column is being read as text, run"
            ... + " Check & repair data on it.", "wizard"
            if emlErrorDialog.back
                goto A3_NCOND_PAGE
            endif
            exitScript: ""
        endif

        # Seeds. Three slots filled, the rest left empty: a fourth or fifth
        # numeric column is as likely to be a covariate as a condition, and
        # adding one is a visible choice while removing a wrong one is not.
        for iSlot from 1 to 6
            a3kSel[iSlot] = 1
        endfor
        a3kSel[1] = 2
        a3kSel[2] = 3
        a3kSel[3] = 4
        a3kTest = 1
        a3kPost = 1
        a3kAdj = 2
        a3kClear = 0

        label A3K_SELECT_PAGE

        beginPause: "Repeated measures — select condition columns"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            comment: "Pick the columns holding the repeated conditions"
            comment: "(select (none) to leave a slot empty; need >= 3)."
            comment: "Only numeric columns are listed — " + string$ (a3kN)
            ... + " of them."
            optionmenu: "Condition 1", a3kSel[1]
                option: "(none)"
                for iCol from 1 to a3kN
                    option: a3kName$[iCol]
                endfor
            optionmenu: "Condition 2", a3kSel[2]
                option: "(none)"
                for iCol from 1 to a3kN
                    option: a3kName$[iCol]
                endfor
            optionmenu: "Condition 3", a3kSel[3]
                option: "(none)"
                for iCol from 1 to a3kN
                    option: a3kName$[iCol]
                endfor
            optionmenu: "Condition 4", a3kSel[4]
                option: "(none)"
                for iCol from 1 to a3kN
                    option: a3kName$[iCol]
                endfor
            optionmenu: "Condition 5", a3kSel[5]
                option: "(none)"
                for iCol from 1 to a3kN
                    option: a3kName$[iCol]
                endfor
            optionmenu: "Condition 6", a3kSel[6]
                option: "(none)"
                for iCol from 1 to a3kN
                    option: a3kName$[iCol]
                endfor
            comment: ""
            optionmenu: "Test approach", a3kTest
                option: "Parametric (RM-ANOVA)"
                option: "Nonparametric (Friedman)"
            boolean: "Pairwise post hoc", a3kPost
            optionmenu: "Adjustment", a3kAdj
                option: "bonferroni"
                option: "holm"
                option: "bh"
            boolean: "Clear Info window", a3kClear
        clicked = endPause: "Quit", "Back", "Run", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto A3_NCOND_PAGE
        endif

        # Carry every answer back into the form. This page is re-entered
        # by goto on three separate error paths, and before this it re-rendered
        # from the seeds — so a user sent back by an error was shown the same
        # selection that had just failed, with no sign it had not been kept.
        @wizardCondSlot: condition_1$
        a3kSel[1] = wizardCondSlot.idx
        @wizardCondSlot: condition_2$
        a3kSel[2] = wizardCondSlot.idx
        @wizardCondSlot: condition_3$
        a3kSel[3] = wizardCondSlot.idx
        @wizardCondSlot: condition_4$
        a3kSel[4] = wizardCondSlot.idx
        @wizardCondSlot: condition_5$
        a3kSel[5] = wizardCondSlot.idx
        @wizardCondSlot: condition_6$
        a3kSel[6] = wizardCondSlot.idx
        a3kTest = test_approach
        a3kPost = pairwise_post_hoc
        a3kAdj = adjustment
        a3kClear = clear_Info_window

        if clear_Info_window
            @emlClearInfo
        endif

        # Build the "|"-delimited condition list and count non-empty slots.
        condList$ = ""
        nCond = 0
        if condition_1$ <> "(none)"
            condList$ = condList$ + condition_1$ + "|"
            nCond = nCond + 1
        endif
        if condition_2$ <> "(none)"
            condList$ = condList$ + condition_2$ + "|"
            nCond = nCond + 1
        endif
        if condition_3$ <> "(none)"
            condList$ = condList$ + condition_3$ + "|"
            nCond = nCond + 1
        endif
        if condition_4$ <> "(none)"
            condList$ = condList$ + condition_4$ + "|"
            nCond = nCond + 1
        endif
        if condition_5$ <> "(none)"
            condList$ = condList$ + condition_5$ + "|"
            nCond = nCond + 1
        endif
        if condition_6$ <> "(none)"
            condList$ = condList$ + condition_6$ + "|"
            nCond = nCond + 1
        endif

        if nCond < 3
            # A correctable selection mistake must not end the wizard.
            @emlErrorDialog: "Repeated measures needs at least 3 condition columns.", "", "wizard"
            if emlErrorDialog.back
                goto A3K_SELECT_PAGE
            endif
            exitScript: ""
        endif

        if test_approach = 1
            @wizardReportPlan: "Repeated measures (k conditions)",
            ... "n/a", "RM-ANOVA (Greenhouse-Geisser)",
            ... "n/a", condList$, "", "", displayTable$
            @emlRunRepeatedMeasuresAnalysis: tableId, "", condList$,
            ... pairwise_post_hoc, adjustment$
            if emlRunRepeatedMeasuresAnalysis.error$ <> ""
                # An analysis error must not tear down the wizard. Return
                # the user into the back-chain with every answer intact.
                @emlErrorDialog: emlRunRepeatedMeasuresAnalysis.error$, emlRunRepeatedMeasuresAnalysis.remedy$, "wizard"
                if emlErrorDialog.back
                    goto A3K_SELECT_PAGE
                endif
                exitScript: ""
            endif
            wizTestType$ = "parametric"
        else
            @wizardReportPlan: "Repeated measures (k conditions)",
            ... "n/a", "Friedman test",
            ... "n/a", condList$, "", "", displayTable$
            @emlRunFriedmanAnalysis: tableId, "", condList$,
            ... pairwise_post_hoc, adjustment$
            if emlRunFriedmanAnalysis.error$ <> ""
                # An analysis error must not tear down the wizard. Return
                # the user into the back-chain with every answer intact.
                @emlErrorDialog: emlRunFriedmanAnalysis.error$, emlRunFriedmanAnalysis.remedy$, "wizard"
                if emlErrorDialog.back
                    goto A3K_SELECT_PAGE
                endif
                exitScript: ""
            endif
            wizTestType$ = "nonparametric"
        endif

        # RM-ANOVA and Friedman have no figure yet, but they DO have a
        # Tidy/glance/augment export.
        wizCanDraw = 0
        wizCanExport = 1
        goto WIZ_WHAT_NEXT

    endif


# ═══════════════════════════════════════════════════════════════════════════
# BRANCH B: EXAMINE A RELATIONSHIP
# ═══════════════════════════════════════════════════════════════════════════

elsif goal = 2

    label B1_RELATIONSHIP

    beginPause: "Relationship — What type?"
        comment: "🔗 How strongly do two variables move together?"
        comment: "     → Correlation"
        comment: ""
        comment: "🎯 Can one variable predict another?"
        comment: "     → Regression"
        comment: ""
        comment: "· · · · · · · · · · · · · · · · · · · · ·"
        comment: ""
        comment: "⬜ Categorical association (coming soon)"
        comment: "↩️ One continuous + one categorical"
        comment: "     → This is a group comparison — use Compare"
        comment: ""
        comment: "─────────────────────────────────────"
        optionmenu: "Relationship type", prevRelType
            option: "🔗 Correlation (both continuous)"
            option: "🎯 Regression (both continuous)"
            option: "⬜ Categorical association (coming soon)"
            option: "↩️ One continuous + one categorical"
        comment: ""
    clicked = endPause: "Quit", "Back", "Continue", 3, 0
    if clicked = 1
        exitScript: ""
    elsif clicked = 2
        goto Q1_GOAL
    endif
    relType = relationship_type
    prevRelType = relType

    if relType = 2

        # ── Regression: Column Selection ──────────────────────────────────

        @wizardPrepareTable: "regression"
        col1Default = wizardPrepareTable.col1Default
        col2Default = wizardPrepareTable.col2Default

        label B_REG_COLUMNS

        beginPause: "Regression — Select columns"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            comment: "Select the predictor (X) and response (Y) columns."
            comment: ""
            comment: "The predictor is the variable you think explains"
            comment: "or causes change in the response."
            comment: "→ e.g., Training hours (X) predicts Jitter (Y)"
            comment: ""
            comment: "· · · · · · · · · · · · · · · · · · · · ·"
            comment: ""
            optionmenu: "Predictor column", col1Default
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            optionmenu: "Response column", col2Default
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            boolean: "Clear Info window", 0
            comment: ""
        clicked = endPause: "Quit", "Back", "Run", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto B1_RELATIONSHIP
        endif

        # No preserve step here either, and Run is on this page.
        @wizardColIdx: predictor_column$
        col1Default = wizardColIdx.idx
        @wizardColIdx: response_column$
        col2Default = wizardColIdx.idx

        if predictor_column$ = response_column$
            # A correctable selection mistake must not end the wizard.
            @emlErrorDialog: "Please select two different columns.", "", "wizard"
            if emlErrorDialog.back
                goto B_REG_COLUMNS
            endif
            exitScript: ""
        endif

        if clear_Info_window
            @emlClearInfo
        endif

        @wizardReportPlan: "Simple linear regression",
        ... "n/a (residual normality assumed)",
        ... "OLS regression (R², F-test)",
        ... "n/a", predictor_column$, "", response_column$, displayTable$

        @emlRunRegressionAnalysis: tableId, response_column$, predictor_column$
        if emlRunRegressionAnalysis.error$ <> ""
            # An analysis error must not tear down the wizard. Return
            # the user into the back-chain with every answer intact.
            @emlErrorDialog: emlRunRegressionAnalysis.error$, emlRunRegressionAnalysis.remedy$, "wizard"
            if emlErrorDialog.back
                goto B_REG_COLUMNS
            endif
            exitScript: ""
        endif

        # Set draw presets for scatter plot with regression line
        corrCol1$ = predictor_column$
        corrCol2$ = response_column$
        wizCanDraw = 1
        wizCanExport = 1
        wizDrawSource$ = "regression"

        goto WIZ_WHAT_NEXT

    elsif relType = 3
        @wizardStub: "Categorical association (chi-squared)",
        ... "planned"
        goto WIZ_WHAT_NEXT
    elsif relType = 4
        # One continuous + one categorical = group comparison
        # Skip the goal question — route directly to observation type
        goal = 1
        goto A1_OBS_TYPE
    endif

    # ── Correlation: Normality + Columns ───────────────────────────────────

    @wizardPrepareTable: "correlation"
    col1Default = wizardPrepareTable.col1Default
    col2Default = wizardPrepareTable.col2Default

    normChecked = 0
    normDefault = 1
    normSummary$ = ""

    label B_NORM_PAGE

    beginPause: "Correlation — Select columns"
        comment: "📋 Table: " + displayTable$
        comment: "─────────────────────────────────────"
        comment: ""
        optionmenu: "Column 1", col1Default
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$[iCol]
        endfor
        optionmenu: "Column 2", col2Default
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$[iCol]
        endfor
        comment: ""
        boolean: "Check normality", prevCheckNorm
        comment: ""
        comment: "· · · · · · · · · · · · · · · · · · · · ·"
        comment: ""
        comment: "ℹ️ Normality tells you whether Pearson r"
        comment: "     (parametric) or Spearman ρ (nonparametric)"
        comment: "     is the better choice for your data."
    clicked = endPause: "Quit", "Back", "Continue", 3, 0
    if clicked = 1
        exitScript: ""
    elsif clicked = 2
        goto B1_RELATIONSHIP
    endif

    corrCol1$ = column_1$
    corrCol2$ = column_2$

    # BEFORE the guard, not after it — as at A3_NORM_PAGE. The guard's
    # own `goto B_NORM_PAGE` skipped straight past the preserve step, so the
    # page came back holding the guess rather than the user's two columns.
    @wizardColIdx: corrCol1$
    col1Default = wizardColIdx.idx
    @wizardColIdx: corrCol2$
    col2Default = wizardColIdx.idx
    prevCheckNorm = check_normality

    if column_1$ = column_2$
        # A correctable selection mistake must not end the wizard.
        @emlErrorDialog: "Please select two different columns.", "", "wizard"
        if emlErrorDialog.back
            goto B_NORM_PAGE
        endif
        exitScript: ""
    endif

    if check_normality
        @wizardNormCheck: "correlation", tableId, corrCol1$,
        ... corrCol2$
        normDefault = wizardNormCheck.recommendation
        normChecked = 1
        normSummary$ = wizardNormCheck.summary$
    endif

    # ── Test config page ──────────────────────────────────────────────

    label B_TEST_PAGE

    beginPause: "Correlation — Choose test"
        comment: "📋 Table: " + displayTable$
        comment: "     " + replace$ (corrCol1$, "_", " ", 0)
        ... + " · vs · "
        ... + replace$ (corrCol2$, "_", " ", 0)
        comment: "─────────────────────────────────────"
        if normChecked
            comment: ""
            if normDefault = 1
                comment: "✅ Normality looks reasonable"
                comment: "     Pearson r should be safe here."
            else
                comment: "❌ Normality not supported"
                comment: "     Consider Spearman, or check Info"
                comment: "     window — see Shapiro-Wilk details."
            endif
            comment: ""
            comment: "· · · · · · · · · · · · · · · · · · · · ·"
        endif
        comment: ""
        comment: "Pearson r — linear association"
        comment: "Assumes bivariate normality. Most powerful when met."
        comment: ""
        comment: "Spearman ρ — monotonic association"
        comment: "Rank-based. No distributional assumptions."
        comment: ""
        comment: "─────────────────────────────────────"
        optionmenu: "Test approach", normDefault
            option: "Pearson r"
            option: "Spearman rho"
        boolean: "Clear Info window", 0
        comment: ""
    clicked = endPause: "Quit", "Back", "Run", 3, 0
    if clicked = 1
        exitScript: ""
    elsif clicked = 2
        goto B_NORM_PAGE
    endif

    if clear_Info_window
        @emlClearInfo
    endif

    @wizardNormLabel: normChecked, normSummary$, test_approach

    if test_approach = 1
        @wizardReportPlan: "Correlation",
        ... wizardNormLabel.result$, "Pearson r",
        ... "n/a", corrCol1$, "", corrCol2$, displayTable$
        @emlRunCorrelationAnalysis: tableId, corrCol1$,
        ... corrCol2$, "pearson"
    else
        @wizardReportPlan: "Correlation",
        ... wizardNormLabel.result$, "Spearman ρ",
        ... "n/a", corrCol1$, "", corrCol2$, displayTable$
        @emlRunCorrelationAnalysis: tableId, corrCol1$,
        ... corrCol2$, "spearman"
    endif
    if emlRunCorrelationAnalysis.error$ <> ""
        # An analysis error must not tear down the wizard. Return
        # the user into the back-chain with every answer intact.
        @emlErrorDialog: emlRunCorrelationAnalysis.error$, emlRunCorrelationAnalysis.remedy$, "wizard"
        if emlErrorDialog.back
            goto B_TEST_PAGE
        endif
        exitScript: ""
    endif

    wizCanDraw = 1
    wizCanExport = 1
    wizDrawSource$ = "correlation"

    goto WIZ_WHAT_NEXT


# ═══════════════════════════════════════════════════════════════════════════
# BRANCH C: DESCRIBE OR SUMMARIZE
# ═══════════════════════════════════════════════════════════════════════════

elsif goal = 3

    label C1_DESCRIBE

    beginPause: "Describe — What to summarize"
        comment: "📊 What does one variable look like?"
        comment: "     → Distribution of a single variable"
        comment: ""
        comment: "📊 How do groups compare on a variable?"
        comment: "     → Distributions broken down by group"
        comment: ""
        comment: "🔍 Is the data approximately bell-curved?"
        comment: "     → Normality check (Shapiro-Wilk)"
        comment: ""
        comment: "─────────────────────────────────────"
        optionmenu: "Describe goal", 1
            option: "📊 Distribution of a single variable"
            option: "📊 Compare distributions across groups"
            option: "🔍 Check normality"
        comment: ""
    clicked = endPause: "Quit", "Back", "Continue", 3, 0
    if clicked = 1
        exitScript: ""
    elsif clicked = 2
        goto Q1_GOAL
    endif
    descGoal = describe_goal

    if descGoal = 1

        # ── Single variable ───────────────────────────────────────────────

        @wizardPrepareTable: "describe"
        dataDefault = wizardPrepareTable.dataDefault

        label C_SINGLE

        beginPause: "Describe — Select column"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            optionmenu: "Data column", dataDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            boolean: "Clear Info window", 0
            comment: ""
        clicked = endPause: "Quit", "Back", "Run", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto C1_DESCRIBE
        endif

        # No preserve step here either, and Run is on this page.
        @wizardColIdx: data_column$
        dataDefault = wizardColIdx.idx

        if clear_Info_window
            @emlClearInfo
        endif

        @emlRunDescriptiveAnalysis: tableId, data_column$
        # Describe must be able to save, which needs the orchestrator to
        # declare -- the Save button is offered only when there is something
        # to export.
        wizCanExport = 1
        if emlRunDescriptiveAnalysis.error$ <> ""
            # An analysis error must not tear down the wizard. Return
            # the user into the back-chain with every answer intact.
            @emlErrorDialog: emlRunDescriptiveAnalysis.error$, emlRunDescriptiveAnalysis.remedy$, "wizard"
            if emlErrorDialog.back
                goto C_SINGLE
            endif
            exitScript: ""
        endif

        goto WIZ_WHAT_NEXT

    elsif descGoal = 2

        # ── By group ──────────────────────────────────────────────────────

        @wizardPrepareTable: "kgroups"
        dataDefault = wizardPrepareTable.dataDefault
        groupDefault = wizardPrepareTable.groupDefault

        label C_BYGROUP

        beginPause: "Describe by group — Select columns"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            optionmenu: "Data column", dataDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            optionmenu: "Group column", groupDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            boolean: "Clear Info window", 0
            comment: ""
        clicked = endPause: "Quit", "Back", "Run", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto C1_DESCRIBE
        endif

        if clear_Info_window
            @emlClearInfo
        endif

        @wizardRunDescribeByGroup: tableId, data_column$,
        ... group_column$

        # Describe must be able to save.
        wizCanExport = 1

        goto WIZ_WHAT_NEXT

    else

        # ── Normality check ───────────────────────────────────────────────

        @wizardPrepareTable: "describe"
        dataDefault = wizardPrepareTable.dataDefault

        label C_NORMALITY

        beginPause: "Normality check — Select column"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            optionmenu: "Data column", dataDefault
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            boolean: "Clear Info window", 0
            comment: ""
        clicked = endPause: "Quit", "Back", "Run", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto C1_DESCRIBE
        endif

        if clear_Info_window
            @emlClearInfo
        endif

        # THE SHIPPED ORCHESTRATOR, not the wizard's local diagnostic.
        # @wizardNormCheck exists to feed a RECOMMENDATION into a test-choice
        # page -- it runs in "group", "paired" and "correlation" modes ahead
        # of a decision. Standing alone on the Describe menu it was doing a
        # different job with the same code, and it declares nothing, which is
        # why this page had no Save button.
        #
        # @emlRunNormalityAnalysis is the analysis a user asked for when they
        # chose "Check normality": it reports Shapiro-Wilk with the shape
        # statistics and calls @emlDeclareNormalityResult, which has existed
        # and been correct since before this page did. Routing here rather
        # than adding a declare to @wizardNormCheck is the DRY answer -- the
        # menu path and the wizard path now run the same procedure.
        @emlRunNormalityAnalysis: tableId, data_column$, "single"
        if emlRunNormalityAnalysis.error$ <> ""
            @emlErrorDialog: emlRunNormalityAnalysis.error$,
            ... emlRunNormalityAnalysis.remedy$, "wizard"
            if emlErrorDialog.back
                goto C1_DESCRIBE
            endif
            exitScript: ""
        endif

        # Normality must be able to save.
        wizCanExport = 1

        goto WIZ_WHAT_NEXT

    endif


# ═══════════════════════════════════════════════════════════════════════════
# BRANCHES D, E, F: STUBS
# ═══════════════════════════════════════════════════════════════════════════

elsif goal = 4

    # ── Mixed models: DISCONNECTED from the wizard ────────────────────────
    #
    # Linear mixed models are tabled for end users, the wizard included.
    # Nothing is deleted. The engine
    # (stats/eml-lmm.praat, 32 procedures), the standalone wrapper
    # (scripts/eml-lmm.praat) and the formula page below are all intact.
    #
    # WHAT IS DISCONNECTED IS THE ROUTE, and only the route. A "Predict —
    # model type" page offering "Simple linear regression" and "Mixed model"
    # would be a question with one live answer, so goal 4 goes straight to
    # the regression columns and D_LMM_FORMULA has no user-reachable entry.
    #
    # The other two routes are closed the same way: setup.praat does not
    # register the "Linear mixed model..." menu entry or the
    # Objects-window button. With this page gone there is no surface left.
    #
    # TO RECONNECT: restore the block below, which is the page verbatim as
    # it stood. Nothing else has to change — D_LMM_FORMULA, the include of
    # stats/eml-lmm.praat, and the back-chain into Q1_GOAL are all still in
    # place and still correct.
    #
    #     label D_MODEL_TYPE
    #     beginPause: "Predict — model type"
    #         comment: "📋 Table: " + displayTable$
    #         comment: "─────────────────────────────────────"
    #         comment: ""
    #         comment: "Is your data clustered, repeated, or nested?"
    #         comment: "(e.g., several measures per singer, per school, per trial)"
    #         optionmenu: "Model type", 1
    #             option: "Simple linear regression (independent rows)"
    #             option: "Mixed model (clustered / repeated / nested)"
    #     clicked = endPause: "Quit", "Back", "Continue", 3, 0
    #     if clicked = 1
    #         exitScript: ""
    #     elsif clicked = 2
    #         goto Q1_GOAL
    #     endif
    #     if model_type = 2
    #         goto D_LMM_FORMULA
    #     endif
    #
    # D_LMM_FORMULA's own Back button targets Q1_GOAL — the page a user would
    # have come from — because there is no model-type page to go back to.

    # ── Predict an outcome (simple linear regression) ─────────────────────

    @wizardPrepareTable: "regression"
    col1Default = wizardPrepareTable.col1Default
    col2Default = wizardPrepareTable.col2Default

    label D_PREDICT_COLUMNS

    beginPause: "Predict — Select columns"
        comment: "📋 Table: " + displayTable$
        comment: "─────────────────────────────────────"
        comment: ""
        comment: "Select the predictor (what drives the change)"
        comment: "and the outcome (what you're trying to predict)."
        comment: "→ e.g., Practice hours predicts vibrato regularity"
        comment: ""
        comment: "· · · · · · · · · · · · · · · · · · · · ·"
        comment: ""
        optionmenu: "Predictor column", col1Default
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$[iCol]
        endfor
        optionmenu: "Outcome column", col2Default
        for iCol from 1 to nCols
            option: emlTableColumnNames.name$[iCol]
        endfor
        boolean: "Clear Info window", 0
        comment: ""
    clicked = endPause: "Quit", "Back", "Run", 3, 0
    if clicked = 1
        exitScript: ""
    elsif clicked = 2
        goto Q1_GOAL
    endif

    # No preserve step here either, and Run is on this page.
    @wizardColIdx: predictor_column$
    col1Default = wizardColIdx.idx
    @wizardColIdx: outcome_column$
    col2Default = wizardColIdx.idx

    if predictor_column$ = outcome_column$
        # A correctable selection mistake must not end the wizard.
        @emlErrorDialog: "Please select two different columns.", "", "wizard"
        if emlErrorDialog.back
            goto D_PREDICT_COLUMNS
        endif
        exitScript: ""
    endif

    if clear_Info_window
        @emlClearInfo
    endif

    @wizardReportPlan: "Simple linear regression",
    ... "n/a (residual normality assumed)",
    ... "OLS regression (R², F-test)",
    ... "n/a", predictor_column$, "", outcome_column$, displayTable$

    @emlRunRegressionAnalysis: tableId, outcome_column$, predictor_column$
    if emlRunRegressionAnalysis.error$ <> ""
        # An analysis error must not tear down the wizard. Return
        # the user into the back-chain with every answer intact.
        @emlErrorDialog: emlRunRegressionAnalysis.error$, emlRunRegressionAnalysis.remedy$, "wizard"
        if emlErrorDialog.back
            goto D_PREDICT_COLUMNS
        endif
        exitScript: ""
    endif

    corrCol1$ = predictor_column$
    corrCol2$ = outcome_column$
    wizCanDraw = 1
    wizCanExport = 1
    wizDrawSource$ = "regression"

    goto WIZ_WHAT_NEXT

    # ── Mixed model formula page ──────────────────────────────────────────
    #
    # UNREACHABLE as of 6 August 2026 — see the note under "elsif goal = 4"
    # above. Kept live rather than commented out for two reasons: a fifty-
    # line block reinstated by uncommenting is a fresh chance to introduce a
    # bug, and while the code still parses, harness/check_includes.py keeps
    # verifying that its four calls into stats/eml-lmm.praat resolve. That
    # is the check that can catch an unresolvable call, and it only works on
    # code that is still there to check.
    #
    # The cost of that choice is that eml-lmm.praat is still included and so
    # still parsed on every wizard launch. It is dead weight, not a user
    # surface. If the load time is worth reclaiming, the include and this
    # block come out together — never one without the other, which is how an
    # unresolvable call gets left behind.
    label D_LMM_FORMULA
    dColHint$ = ""
    for iCol from 1 to nCols
        if iCol > 1
            dColHint$ = dColHint$ + ", "
        endif
        dColHint$ = dColHint$ + emlTableColumnNames.name$[iCol]
    endfor
    beginPause: "Mixed model — formula"
        comment: "📋 Table: " + displayTable$
        comment: "Columns: " + dColHint$
        comment: "─────────────────────────────────────"
        comment: "lme4-style formula, e.g.  y ~ x + (1 + x | group)"
        comment: "(1 | group) = random intercept per group."
        sentence: "Formula", "y ~ x + (1 | group)"
        optionmenu: "Contrast coding", 1
            option: "treatment"
            option: "sum"
            option: "helmert"
            option: "poly"
        boolean: "Use REML", 1
        boolean: "Report R squared", 1
        boolean: "Report confidence intervals", 1
        boolean: "Clear Info window", 1
    clicked = endPause: "Quit", "Back", "Run", 3, 0
    if clicked = 1
        exitScript: ""
    elsif clicked = 2
        # Was D_MODEL_TYPE, which was removed when mixed models were
        # disconnected. Q1_GOAL is where a user would now have come from.
        goto Q1_GOAL
    endif
    if clear_Info_window
        @emlClearInfo
    endif
    @wizardReportPlan: "Linear mixed model",
    ... "n/a", "Mixed model (REML, Satterthwaite df)",
    ... "n/a", formula$, "", "", displayTable$
    @emlRunLMMAnalysis: tableId, formula$, contrast_coding$, use_REML,
    ... report_R_squared, report_confidence_intervals
    if emlRunLMMAnalysis.error$ <> ""
        # An analysis error must not tear down the wizard. Return
        # the user into the back-chain with every answer intact.
        @emlErrorDialog: emlRunLMMAnalysis.error$, emlRunLMMAnalysis.remedy$, "wizard"
        if emlErrorDialog.back
            goto D_LMM_FORMULA
        endif
        exitScript: ""
    endif
    wizCanDraw = 0
    goto WIZ_WHAT_NEXT
elsif goal = 5
    @wizardStub: "Classification (discriminant analysis)",
    ... "planned"
elsif goal = 6
    @wizardStub: "Dimensionality reduction (PCA, MDS)",
    ... "planned"
endif


# ═══════════════════════════════════════════════════════════════════════════
# WHAT NEXT?
# ═══════════════════════════════════════════════════════════════════════════

@emlCSVInit

label WIZ_WHAT_NEXT

# Four button sets, from two independent flags. Before this, one flag
# decided both, so an analysis with no figure also lost its export.
if wizCanDraw and wizCanExport
    beginPause: "Analysis complete"
        comment: "📊 Results are in the Info window."
    clicked = endPause: "Done", "Save", "Draw", "New", 3, 0
    if clicked = 1
        runAgain = 0
        goto WIZ_LOOP_END
    elsif clicked = 2
        goto WIZ_EXPORT_CSV
    elsif clicked = 3
        goto WIZ_DRAW_FIGURE
    else
        runAgain = 1
        goto WIZ_LOOP_END
    endif
elsif wizCanExport
    beginPause: "Analysis complete"
        comment: "📊 Results are in the Info window."
    clicked = endPause: "Done", "Save", "New", 3, 0
    if clicked = 1
        runAgain = 0
        goto WIZ_LOOP_END
    elsif clicked = 2
        goto WIZ_EXPORT_CSV
    else
        runAgain = 1
        goto WIZ_LOOP_END
    endif
elsif wizCanDraw
    beginPause: "Analysis complete"
        comment: "📊 Results are in the Info window."
    clicked = endPause: "Done", "Draw", "New", 3, 0
    if clicked = 1
        runAgain = 0
        goto WIZ_LOOP_END
    elsif clicked = 2
        goto WIZ_DRAW_FIGURE
    else
        runAgain = 1
        goto WIZ_LOOP_END
    endif
else
    beginPause: "Analysis complete"
        comment: "📊 Results are in the Info window."
    clicked = endPause: "Done", "New", 2, 0
    if clicked = 1
        runAgain = 0
    else
        runAgain = 1
    endif
    goto WIZ_LOOP_END
endif

# ── CSV Export ────────────────────────────────────────────────────────────
#
# NOT defaultDirectory$ — the PLUGIN's own script folder — which would land
# a user's results inside the install tree, where an upgrade can remove them
# and where nobody looks for data. Every other wrapper exports from
# homeDirectory$ and remembers the last folder used. The wizard does
# the same, which also picks up the tidy/glance/augment fork that
# @emlExportStatsCSV alone does not have.

label WIZ_EXPORT_CSV

# ONE PANEL FOR EVERY OUTPUT. This was @emlWrapperExportCSV,
# which wrote only the numbers and remembered its own folder.
# @emlSavePanel offers the results AND the Info window report
# under one folder and one stem. 0 = there is no figure here;
# nothing has been drawn at the end of an analysis.
@emlSavePanel: 0, tableName$ + "_results",
... emlLastCSVFolder$
if emlSavePanel.cancelled = 0
    emlLastCSVFolder$ = emlSavePanel.folder$
endif
goto WIZ_WHAT_NEXT


# ═══════════════════════════════════════════════════════════════════════════
# DRAW FIGURE — preset → @emlGraphsWorkflow
# ═══════════════════════════════════════════════════════════════════════════

label WIZ_DRAW_FIGURE

if wizDrawSource$ = "group"
    emlGraphsPresetType = 7
    emlGraphsPresetDataCol$ = dataCol$
    emlGraphsPresetGroupCol$ = groupCol$
    emlGraphsPresetTestType$ = wizTestType$
    emlGraphsPresetAnnotate = 1
    @emlGraphsWorkflow: tableId
elsif wizDrawSource$ = "correlation"
    emlGraphsPresetType = 8
    emlGraphsPresetXCol$ = corrCol1$
    emlGraphsPresetYCol$ = corrCol2$
    emlGraphsPresetAnnotate = 1
    @emlGraphsWorkflow: tableId
elsif wizDrawSource$ = "regression"
    emlGraphsPresetType = 8
    emlGraphsPresetXCol$ = corrCol1$
    emlGraphsPresetYCol$ = corrCol2$
    emlGraphsPresetAnnotate = 1
    emlGraphsPresetRegressionLine = 1
    @emlGraphsWorkflow: tableId
elsif wizDrawSource$ = "paired"
    # Reshape to long format for spaghetti plot.
    # Main-body code: undotted variable names (dot-prefix is procedure-local
    # convention only — Rule 5C). (L4)
    selectObject: tableId
    plNRows = Get number of rows
    # NAMED AFTER THE USER'S TABLE, NOT AFTER THE RESHAPE. This read
    # "pairedLong", and the graph layer takes both its title and its save
    # stem from the name of the object it is drawing — so the wizard's
    # spaghetti plot was titled "... (pairedLong)" over a figure of the
    # user's data and saved as pairedLong_Spaghetti_Plot_<stamp>: a
    # deliverable named after a transient the user never created and never
    # sees again. eml-compare-paired.praat carried the identical line and was
    # fixed on 15 August 2026; this is the same fix, and the note above that
    # one explains why the suffix is "_long" rather than the bare table name.
    # The two Tables sit side by side in the object list for the length of
    # the draw, and two Tables sharing a name is exactly the ambiguity
    # @emlRecordSource counts and warns about.
    plLongId = Create Table with column names: tableName$ + "_long",
    ... plNRows * 2, { "Subject", "Condition", "Value" }
    for plIRow from 1 to plNRows
        selectObject: tableId
        plV1 = Get value: plIRow, wizPairedCol1$
        plV2 = Get value: plIRow, wizPairedCol2$
        plR1 = (plIRow - 1) * 2 + 1
        plR2 = (plIRow - 1) * 2 + 2
        selectObject: plLongId
        Set string value: plR1, "Subject", string$ (plIRow)
        Set string value: plR1, "Condition", wizPairedCol1$
        Set numeric value: plR1, "Value", plV1
        Set string value: plR2, "Subject", string$ (plIRow)
        Set string value: plR2, "Condition", wizPairedCol2$
        Set numeric value: plR2, "Value", plV2
    endfor
    # ── axis labels that name the measure ──────────────────────────
    # "Subject", "Condition" and "Value" are the reshape's ROLE names, and
    # the graph layer derives its axis labels from column names — so the
    # y-axis, the only place the measured quantity could appear, read
    # "Value". The real names are here at the call site. The measure is the
    # two columns' common stem where they have one (jitter_pre /
    # jitter_post -> "jitter", trimmed back to a word boundary), and both
    # names otherwise; what is left over names the contrast the x-axis
    # actually shows ("pre vs post"), which is what "Condition" stood in for.
    plCommon = 0
    plStop = 0
    for plK from 1 to min (length (wizPairedCol1$), length (wizPairedCol2$))
        if plStop = 0
            if left$ (wizPairedCol1$, plK) = left$ (wizPairedCol2$, plK)
                plCommon = plK
            else
                plStop = 1
            endif
        endif
    endfor
    plStem$ = left$ (wizPairedCol1$, plCommon)
    plAtBoundary = 0
    while plStem$ <> "" and plAtBoundary = 0
        if right$ (plStem$, 1) = "_" or right$ (plStem$, 1) = " "
        ... or right$ (plStem$, 1) = "."
            plAtBoundary = 1
        else
            plStem$ = left$ (plStem$, length (plStem$) - 1)
        endif
    endwhile
    if plStem$ <> ""
        plStem$ = left$ (plStem$, length (plStem$) - 1)
    endif
    # Registered RAW, underscores and all: the graph layer's own token
    # formatter is what turns SPL_dB into "SPL (dB)" and F0_Hz into
    # "F0 (Hz)". De-underscoring here would hand it "SPL dB" and lose
    # the unit.
    if plStem$ <> ""
        plMeasure$ = plStem$
        plFactor$ = mid$ (wizPairedCol1$, length (plStem$) + 2, 1000)
        ... + " vs " + mid$ (wizPairedCol2$, length (plStem$) + 2, 1000)
    else
        plMeasure$ = wizPairedCol1$ + " / " + wizPairedCol2$
        plFactor$ = wizPairedCol1$ + " vs " + wizPairedCol2$
    endif

    emlGraphsPresetType = 13
    # The graph layer's half is a registry keyed by column name
    # (graphs/eml-graph-procedures.praat), consulted by the spaghetti page's
    # @emlCapitalizeLabel calls on spCondCol$ / spValueCol$. It is cleared
    # straight after the figure: the keys are role names as generic as
    # "Value" and would otherwise leak into the next graph of the session.
    @emlSetLabelOverride: "Value", plMeasure$
    @emlSetLabelOverride: "Condition", plFactor$
    @emlGraphsWorkflow: plLongId
    @emlClearLabelOverrides
    removeObject: plLongId
    selectObject: tableId
elsif wizDrawSource$ = "twoway"
    # The two-way draw hands over BOTH factors: handing over factor 1 only
    # makes the default grouped violin drop the second factor. Consumed by
    # the Grouped Violin preset branch in graphs/eml-graphs-form.praat, which
    # matches the name against the column list and clears the preset
    # afterwards.
    emlGraphsPresetType = 11
    emlGraphsPresetGroupCol$ = wizTwoWayFactor1$
    emlGraphsPresetDataCol$ = dataCol$
    emlGraphsPresetSubgroupCol$ = wizTwoWayFactor2$
    @emlGraphsWorkflow: tableId
endif

goto WIZ_WHAT_NEXT

label WIZ_LOOP_END

endwhile


# ###########################################################################
# PROCEDURES
# ###########################################################################


# ============================================================================
# @wizardReportPlan — Analysis plan summary (wizard path only)
# ============================================================================

procedure wizardReportPlan: .design$, .normality$, .test$,
... .posthoc$, .col1$, .col2$, .col3$, .table$
    .border$ = "══════════════════════════════════════════════"
    .indent$ = "  "
    appendInfoLine: ""
    appendInfoLine: .border$
    appendInfoLine: .indent$ + "EML Stats Wizard — Analysis Plan"
    appendInfoLine: .border$
    appendInfoLine: ""
    @emlPadRight: "Design:", 16
    appendInfoLine: .indent$ + emlPadRight.result$ + .design$
    @emlPadRight: "Normality:", 16
    appendInfoLine: .indent$ + emlPadRight.result$ + .normality$
    @emlPadRight: "Test:", 16
    appendInfoLine: .indent$ + emlPadRight.result$ + .test$
    if .posthoc$ <> "n/a"
        @emlPadRight: "Post-hoc:", 16
        appendInfoLine: .indent$ + emlPadRight.result$ + .posthoc$
    endif
    if .col2$ <> ""
        @emlPadRight: "Data column:", 16
        appendInfoLine: .indent$ + emlPadRight.result$
        ... + replace$ (.col1$, "_", " ", 0)
        @emlPadRight: "Group column:", 16
        appendInfoLine: .indent$ + emlPadRight.result$
        ... + replace$ (.col2$, "_", " ", 0)
    else
        @emlPadRight: "Column 1:", 16
        appendInfoLine: .indent$ + emlPadRight.result$
        ... + replace$ (.col1$, "_", " ", 0)
        if .col3$ <> ""
            @emlPadRight: "Column 2:", 16
            appendInfoLine: .indent$ + emlPadRight.result$
            ... + replace$ (.col3$, "_", " ", 0)
        endif
    endif
    @emlPadRight: "Table:", 16
    appendInfoLine: .indent$ + emlPadRight.result$ + .table$
    appendInfoLine: ""
    appendInfoLine: .border$
    appendInfoLine: .indent$ + "Running analysis..."
    appendInfoLine: .border$
    appendInfoLine: ""
endproc


# ============================================================================
# @wizardNormDiag — Normality diagnostic (skewness + kurtosis)
# ============================================================================

procedure wizardNormDiag: .data#, .label$
    .recommendation = 1
    @emlSkewness: .data#
    @emlKurtosis: .data#
    .sk = emlSkewness.result
    .ku = emlKurtosis.result
    .n = size (.data#)

    # ── THE DISPLAY STANDARD ──────────────────────────────────────────────
    #
    # These four numbers are the wizard's OWN report lines -- the preview it
    # prints before it recommends parametric or nonparametric -- and none of
    # them is a bare fixed$ call. Praat's fixed$ is not a fixed-precision
    # formatter: it returns the LARGER of the precision it is given and
    # however many decimals are needed to show one significant digit, and a
    # bare "0" for an exact zero. Measured on 6.6.30:
    #
    #     Skewness:     0.00000000000000005      asked for 3 decimals
    #     Shapiro-Wilk: W = 0.5899, p = 0.00000000001    asked for 4
    #
    # The first is a symmetric column whose skewness is zero and whose
    # arithmetic landed a few ulps away from it. The second is an ordinary
    # strongly-skewed column at n = 60. Neither is a rare input; a normality
    # PREVIEW is precisely where a near-zero statistic and a floor-crossing p
    # are the expected cases rather than the corner ones.
    #
    # The shared formatter @eml_fixed (stats/eml-output.praat) keeps fixed$'s
    # answer whenever fixed$ honoured the request -- so every line fixed$ gets
    # right prints identically -- and rounds properly when it did not.
    # Nothing computed moves: the
    # recommendation below reads .sk, .ku and emlShapiroWilk.p, not these
    # strings, and @emlNormalityRecommendation is called with the raw values.
    #
    # AND p PRINTS IN APA STYLE. @emlFormatP is what the rest of the plugin's
    # reports use, so this line reads "p < .001" rather than
    # "p = 0.00000000001", and ".551" rather than "0.5514". The unrounded
    # value is NOT
    # appended here as @emlInlineP would append it -- this is a two-line
    # diagnostic whose only consequence is the binary recommendation printed
    # underneath it, and the same p is reported to full precision by
    # @emlRunNormalityAnalysis and exported by the CSV writers, which is
    # where full precision belongs.
    .displayLabel$ = replace$ (.label$, "_", " ", 0)
    appendInfoLine: "  ", .displayLabel$, " (n = ", .n, ")"
    @eml_fixed: .sk, 3
    appendInfoLine: "    Skewness:     ", eml_fixed.result$
    @eml_fixed: .ku, 3
    appendInfoLine: "    Kurtosis (excess): ", eml_fixed.result$

    # Shapiro-Wilk formal test
    @emlShapiroWilk: .data#
    if emlShapiroWilk.error$ = ""
        @eml_fixed: emlShapiroWilk.w, 4
        .wTxt$ = eml_fixed.result$
        @emlFormatP: emlShapiroWilk.p
        appendInfoLine: "    Shapiro-Wilk: W = ", .wTxt$,
        ... ", ", emlFormatP.formatted$
    else
        appendInfoLine: "    Shapiro-Wilk: ", emlShapiroWilk.error$
    endif

    # ── Decision hierarchy ────────────────────────────────────────────────
    #
    # The rule is NOT restated here. It lives in @emlNormalityRecommendation
    # (stats/eml-analysis.praat), reached through eml-lib-lmm.praat, and this
    # procedure calls it. Until 8 August the wizard carried a hand-maintained
    # second copy — correct, but a copy, and the third copy (the per-group
    # branch of eml-check-normality.praat) had already drifted to hard-coded
    # Thresholds and the retired `skKurtFail or swFail` gate.
    #
    # This call site is the reason the shared procedure takes a bare
    # (skewness, kurtosis, n, swP, swError$) rather than a Table and a column
    # name: @wizardNormDiag is handed a vector — one group's values, or
    # paired differences — and must not disturb wizard state.
    # @emlNormalityRecommendation prints nothing and declares nothing, so it
    # is safe to call from here.
    #
    # Everything below the call is PRESENTATION. The wizard picks its
    # wording from the returned flags; it does not re-derive the answer.
    # Thresholds print from the same shared constants the rule tests
    # (emlSkewThreshold = 2, emlKurtosisThreshold = 7, in
    # Stats/eml-output.praat). They were once hard-coded 1 and 3 here.
    @emlNormalityRecommendation: .sk, .ku, .n,
    ... emlShapiroWilk.p, emlShapiroWilk.error$
    .shapeSevere = emlNormalityRecommendation.shapeSevere
    .swUsable = emlNormalityRecommendation.swUsable
    .swFail = emlNormalityRecommendation.swFail
    .largeNOverride = emlNormalityRecommendation.largeNOverride
    .isParametric = 0
    if emlNormalityRecommendation.recommendation$ = "parametric"
        .isParametric = 1
    endif

    ; These two are the shared THRESHOLDS rather than statistics, and at
    ; their shipped values (2 and 7) fixed$ and @eml_fixed give the same
    ; string. They are routed anyway: every unrouted fixed$ call looks like
    ; the safe one, and a module with a single door to the formatter is a
    ; module whose display standard can be checked by counting rather than by
    ; reading.
    @eml_fixed: emlSkewThreshold, 0
    .skThreshTxt$ = eml_fixed.result$
    @eml_fixed: emlKurtosisThreshold, 0
    .shapeMsg$ = "    → Skewness/kurtosis outside typical limits"
    ... + " (|skew| < " + .skThreshTxt$
    ... + ", |excess kurt| < " + eml_fixed.result$ + ")"

    # The answer, converted to the wizard's 1/2 encoding. It is READ from the
    # shared procedure, not recomputed — the branches below choose wording
    # only, and none of them assigns .recommendation.
    .recommendation = 2
    if .isParametric
        .recommendation = 1
    endif

    if .swUsable
        if .largeNOverride
            # Large-n override: Shapiro-Wilk rejects departures too small to
            # matter for a parametric test once n is large.
            appendInfoLine: "    → Shapiro-Wilk rejects normality, but "
            ... + "departure is"
            appendInfoLine: "      practically negligible at n = ",
            ... .n, " (shape within limits)"
        elsif .swFail
            appendInfoLine: "    → Shapiro-Wilk rejects normality "
            ... + "(p < 0.05)"
            if .shapeSevere
                appendInfoLine: .shapeMsg$
            endif
        else
            # The test did not reject. Severe shape is still REPORTED, but it
            # does not overturn the test's finding.
            if .shapeSevere
                appendInfoLine: .shapeMsg$
                appendInfoLine: "    → Shapiro-Wilk does not reject normality"
                ... + " (p >= 0.05); shape is"
                appendInfoLine: "      reported but does not overturn the test"
            else
                appendInfoLine: "    → Normality appears reasonable"
            endif
        endif
    else
        # Shapiro-Wilk unavailable (n outside its defined range, zero range,
        # or an internal error). The backup case, and the only one in which
        # shape decides anything.
        if .shapeSevere
            appendInfoLine: .shapeMsg$
            appendInfoLine: "    → Shapiro-Wilk unavailable; shape decides"
        else
            appendInfoLine: "    → Shapiro-Wilk unavailable; shape within "
            ... + "limits"
        endif
    endif
    appendInfoLine: ""
endproc


# ============================================================================
# @wizardNormCheck — Mode-aware normality assessment harness
# ============================================================================
# Orchestrates normality checking across test path types. Writes a
# normality assessment report to the Info window and returns an overall
# recommendation that the caller uses to pre-select parametric vs
# nonparametric on loop-back.
#
# Arguments:
#   .mode$   — "single"      : test .col1$ alone
#              "group"       : test .col1$ per group defined by .col2$
#              "paired"      : test differences (.col1$ minus .col2$)
#              "correlation" : test both .col1$ and .col2$
#   .tableId — Table object ID
#   .col1$   — data column (or first measurement column)
#   .col2$   — group column (group), second measurement (paired/corr),
#              or "" (single)
#
# Output:
#   .recommendation — 1 = parametric reasonable, 2 = nonparametric
#   .summary$       — one-line summary for carry-forward display

procedure wizardNormCheck: .mode$, .tableId, .col1$, .col2$
    .recommendation = 1
    .summary$ = ""
    .anyFail = 0

    selectObject: .tableId
    .tableName$ = replace$ (selected$ ("Table"), "_", " ", 0)

    appendInfoLine: "══════════════════════════════════════════════"
    appendInfoLine: "  Normality Assessment"
    appendInfoLine: "══════════════════════════════════════════════"
    appendInfoLine: ""
    appendInfoLine: "  Table: ", .tableName$
    if .mode$ = "group"
        appendInfoLine: "  Testing: ",
        ... replace$ (.col1$, "_", " ", 0),
        ... " per group (",
        ... replace$ (.col2$, "_", " ", 0), ")"
    elsif .mode$ = "paired"
        appendInfoLine: "  Testing: differences (",
        ... replace$ (.col1$, "_", " ", 0), " minus ",
        ... replace$ (.col2$, "_", " ", 0), ")"
    elsif .mode$ = "correlation"
        appendInfoLine: "  Testing: ",
        ... replace$ (.col1$, "_", " ", 0), " and ",
        ... replace$ (.col2$, "_", " ", 0)
    else
        appendInfoLine: "  Testing: ",
        ... replace$ (.col1$, "_", " ", 0)
    endif
    appendInfoLine: ""

    if .mode$ = "group"
        # Per-group testing
        selectObject: .tableId
        @emlCountGroups: .tableId, .col2$
        if emlCountGroups.error$ <> ""
            appendInfoLine: "  Error: ", emlCountGroups.error$
        else
            for .g from 1 to emlCountGroups.nGroups
                @eml_getGroupData: .tableId, .col1$, .col2$,
                ... emlCountGroups.groupLabel$[.g]
                if eml_getGroupData.n >= 3
                    @wizardNormDiag: eml_getGroupData.data#,
                    ... emlCountGroups.groupLabel$[.g]
                    if wizardNormDiag.recommendation = 2
                        .anyFail = 1
                    endif
                else
                    appendInfoLine: "  ",
                    ... emlCountGroups.groupLabel$[.g],
                    ... " (n = ", eml_getGroupData.n,
                    ... "): too few for normality test"
                    appendInfoLine: ""
                endif
            endfor
        endif

    elsif .mode$ = "paired"
        # Test differences
        selectObject: .tableId
        @emlExtractPairedColumns: .tableId, .col1$, .col2$
        if emlExtractPairedColumns.error$ = ""
            .diffs# = emlExtractPairedColumns.data1#
            ... - emlExtractPairedColumns.data2#
            .diffLabel$ = .col1$ + " minus " + .col2$
            if size (.diffs#) >= 3
                @wizardNormDiag: .diffs#, .diffLabel$
                if wizardNormDiag.recommendation = 2
                    .anyFail = 1
                endif
            else
                appendInfoLine: "  Fewer than 3 paired differences."
            endif
        else
            appendInfoLine: "  Error: ",
            ... emlExtractPairedColumns.error$
        endif

    elsif .mode$ = "correlation"
        # Test both variables
        selectObject: .tableId
        @emlExtractColumn: .tableId, .col1$
        if emlExtractColumn.n >= 3
            @wizardNormDiag: emlExtractColumn.data#, .col1$
            if wizardNormDiag.recommendation = 2
                .anyFail = 1
            endif
        else
            appendInfoLine: "  ", .col1$, ": too few values"
            appendInfoLine: ""
        endif
        selectObject: .tableId
        @emlExtractColumn: .tableId, .col2$
        if emlExtractColumn.n >= 3
            @wizardNormDiag: emlExtractColumn.data#, .col2$
            if wizardNormDiag.recommendation = 2
                .anyFail = 1
            endif
        else
            appendInfoLine: "  ", .col2$, ": too few values"
            appendInfoLine: ""
        endif

    else
        # "single" — test one column
        selectObject: .tableId
        @emlExtractColumn: .tableId, .col1$
        if emlExtractColumn.n >= 3
            @wizardNormDiag: emlExtractColumn.data#, .col1$
            if wizardNormDiag.recommendation = 2
                .anyFail = 1
            endif
        else
            appendInfoLine: "  ", .col1$,
            ... ": fewer than 3 valid values"
            appendInfoLine: ""
        endif
    endif

    # Overall recommendation
    appendInfoLine: "──────────────────────────────────────────────"
    if .anyFail
        .recommendation = 2
        .summary$ = "Checked — normality not supported"
        appendInfoLine: "  Recommendation: nonparametric test"
    else
        .recommendation = 1
        .summary$ = "Checked — normality reasonable"
        appendInfoLine: "  Recommendation: parametric test is "
        ... + "reasonable"
    endif
    appendInfoLine: ""
endproc

# ============================================================================
# @wizardNormLabel — Construct normality label for report plan
# ============================================================================
# Reusable by wizard paths and wrapper scripts.
#
# Arguments:
#   .normChecked — 0/1: was normality formally assessed?
#   .summary$    — one-line summary from @wizardNormCheck (if checked)
#   .testApproach — 1 = parametric, 2 = nonparametric
#
# Output:
#   .result$     — label string for @wizardReportPlan normality field

procedure wizardNormLabel: .normChecked, .summary$, .testApproach
    if .normChecked
        .result$ = .summary$
    else
        if .testApproach = 1
            .result$ = "Assumed (normal)"
        else
            .result$ = "Not assumed"
        endif
    endif
endproc


# ============================================================================
# @wizardPrepareTable — Ensure table exists and guess column defaults
# ============================================================================
# If no table is selected, creates an example data set. Then guesses
# column roles via @emlGuessColumnRoles. Modifies the main-body globals
# tableId, hasTable, tableName$, displayTable$, nCols.
#
# Arguments:
#   .hint$ — passed to @wizardCreateExample ("groups", "twofactor",
#            "paired", "correlation", "describe")
#
# Output (all dot-prefixed):
#   .dataDefault   — best-guess data column index
#   .groupDefault  — best-guess group/factor column index
#   .col1Default   — best-guess first measurement column
#   .col2Default   — best-guess second measurement column
#   .f1Default     — best-guess factor 1 column
#   .f2Default     — best-guess factor 2 column

# ============================================================================
# @wizardCondSlot — position of a column name in the A3K condition list
# ============================================================================
# The repeated-measures form hands back NAMES; its optionmenus are seeded
# with POSITIONS in the filtered numeric-column list built at A3K_PREP, whose
# item 1 is "(none)". This converts one to the other so the form can be
# Re-rendered with what the user actually chose.
#
# Arguments:
#   .name$ - a column name, or "(none)"
#
# Output:
#   .idx   - menu position (1 = "(none)"); 1 for any name not in the list

procedure wizardCondSlot: .name$
    .idx = 1
    for .i from 1 to a3kN
        if a3kName$ [.i] = .name$
            .idx = .i + 1
        endif
    endfor
endproc


# ============================================================================
# @wizardColIdx — Column NAME back to its optionmenu POSITION
# ============================================================================
# The sibling of @wizardCondSlot above, for every OTHER column optionmenu in
# the wizard. Those menus are seeded with a POSITION in emlTableColumnNames
# and hand back a NAME; a page re-entered by `goto` re-renders from the seed,
# so unless the name is converted back and written into the seed the page
# Shows @wizardPrepareTable's GUESS rather than what the user chose.
#
# Why a procedure and not the four-line loop it replaces: nine error-return
# sites across six pages need this, the loop had been hand-copied to two of
# them and omitted from the other four pages entirely, and a hand-copied
# loop is exactly what stops propagating. One call per menu, everywhere.
#
# Arguments:
#   .name$ - a column name as returned by an optionmenu
#
# Output:
#   .idx   - position in emlTableColumnNames; 1 for a name not in the list
#            (unreachable from a menu, whose options ARE that list)

procedure wizardColIdx: .name$
    .idx = 1
    for .i from 1 to nCols
        if emlTableColumnNames.name$ [.i] = .name$
            .idx = .i
        endif
    endfor
endproc


procedure wizardPrepareTable: .hint$
    if hasTable = 0
        @wizardCreateExample: .hint$
        tableId = wizardCreateExample.tableId
        tableName$ = selected$ ("Table")
        displayTable$ = replace$ (tableName$, "_", " ", 0)
        @emlTableColumnNames: tableId
        nCols = emlTableColumnNames.nCols
        hasTable = 1
        .dataDefault = wizardCreateExample.dataDefault
        .groupDefault = wizardCreateExample.groupDefault
        .col1Default = wizardCreateExample.col1Default
        .col2Default = wizardCreateExample.col2Default
        .f1Default = wizardCreateExample.factor1Default
        .f2Default = wizardCreateExample.factor2Default
    else
        @emlGuessColumnRoles: tableId
        .dataDefault = emlGuessColumnRoles.dataIdx
        .groupDefault = emlGuessColumnRoles.groupIdx
        .col2Default = emlGuessColumnRoles.dataIdx2
        .f1Default = emlGuessColumnRoles.factor1Idx
        .f2Default = emlGuessColumnRoles.factor2Idx
        if .dataDefault = 0
            .dataDefault = 1
        endif
        .col1Default = .dataDefault
        if .groupDefault = 0
            .groupDefault = min (2, nCols)
        endif
        if .col2Default = 0
            .col2Default = min (2, nCols)
        endif
        if .f1Default = 0
            .f1Default = min (2, nCols)
        endif
        if .f2Default = 0
            .f2Default = min (3, nCols)
        endif
    endif
endproc


# ============================================================================
# @wizardRunDescribeByGroup — Descriptives per group
# ============================================================================
# No orchestrator for grouped descriptives yet — stays as direct call.

procedure wizardRunDescribeByGroup: .tableId, .dataCol$, .groupCol$
    selectObject: .tableId
    @emlCountGroups: .tableId, .groupCol$
    if emlCountGroups.error$ <> ""
        exitScript: emlCountGroups.error$
    endif
    .nG = emlCountGroups.nGroups

    # Snapshot the group labels before any later call can overwrite the
    # @emlCountGroups outputs.
    for .g from 1 to .nG
        .gLabel$[.g] = emlCountGroups.groupLabel$[.g]
    endfor

    .dData$ = replace$ (.dataCol$, "_", " ", 0)
    .dGrp$ = replace$ (.groupCol$, "_", " ", 0)

    @emlReportHeader: "Descriptive Statistics by Group"
    @emlReportLineString: "Table", displayTable$
    @emlReportLineString: "Data column", .dData$
    @emlReportLineString: "Group column", .dGrp$
    @emlReportLine: "Groups", .nG, 0
    @emlReportBlank

    @emlReportDescriptiveHeader

    # EXPORTABLE -- describe must be able to save. The LEGACY buffer, not
    # the broom collectors, for the
    # reason set out above @emlCSVAddDescriptiveRow in stats/eml-analysis.praat:
    # the tidy vocabulary is a whitelist and would drop every statistic here
    # except the term. One legacy row per group per statistic, which is the
    # long format's natural shape for exactly this.
    @emlCSVInit
    @emlCSVSetTable: displayTable$

    for .g from 1 to .nG
        @eml_getGroupData: .tableId, .dataCol$, .groupCol$,
        ... .gLabel$[.g]
        .gDisplay$ = replace$ (.gLabel$[.g], "_", " ", 0)
        .gN = eml_getGroupData.n

        # ONE PASS, NOT THREE. This called @emlMean, @emlSD and @emlMedian
        # separately; @emlDescribe computes those and thirteen more from the
        # same vector, so the reported row and the declared row are now the
        # same numbers by construction rather than by both being right.
        @emlDescribe: eml_getGroupData.data#
        .gMean = emlDescribe.mean
        .gSD = emlDescribe.sd
        .gMed = emlDescribe.median

        @emlReportDescriptiveRow: .gDisplay$, .gN,
        ... .gMean, .gSD, .gMed
        @emlCSVAddDescriptiveRow: .gDisplay$
    endfor

    @emlReportFooter
endproc


# ============================================================================
# @wizardCreateExample — Create example data set for exploration
# ============================================================================

procedure wizardCreateExample: .hint$
    .tableId = 0
    .dataDefault = 1
    .groupDefault = 2
    .col1Default = 1
    .col2Default = 2
    .factor1Default = 2
    .factor2Default = 2

    # Describe the demo table to the user (two lines for beginPause)
    if .hint$ = "twogroups"
        .desc1$ = "Control vs Patient (N=20 each)"
        .desc2$ = "Columns: F0 (Hz) and jitter (%)"
    elsif .hint$ = "kgroups"
        .desc1$ = "Soprano / Mezzo / Alto (N=15 each)"
        .desc2$ = "Columns: SPL (dB) and vibrato rate (Hz)"
    elsif .hint$ = "twofactor"
        .desc1$ = "Voice Type × Task (Soprano/Alto × Speech/Singing)"
        .desc2$ = "N=12 per cell, data column: SPL (dB)"
    elsif .hint$ = "paired"
        .desc1$ = "Pre/post voice therapy (N=20 subjects)"
        .desc2$ = "Columns: jitter and HNR, before and after"
    elsif .hint$ = "correlation"
        .desc1$ = "Speaking F0 vs singing F0 (N=30 speakers)"
        .desc2$ = "Plus age as a covariate"
    elsif .hint$ = "regression"
        .desc1$ = "Practice hours predicting vibrato regularity (N=25)"
        .desc2$ = "Plus experience (years) as a covariate"
    elsif .hint$ = "describe"
        .desc1$ = "Voice measures with different distributions (N=40)"
        .desc2$ = "F0 (normal), shimmer (skewed), jitter (mild skew)"
    else
        .desc1$ = "General voice science demo data"
        .desc2$ = ""
    endif

    beginPause: "No table selected"
        comment: "📋 The wizard needs a Table to analyze."
        comment: "A demo table will be created for this analysis:"
        comment: ""
        comment: .desc1$
        comment: .desc2$
        comment: ""
        comment: "The table will open so you can inspect the data."
        comment: "Or quit, select your own Table, and restart."
    clicked = endPause: "Quit", "Create Demo", 2, 0
    if clicked = 1
        exitScript: ""
    endif

    # ── Create the appropriate demo table ──────────────────────────────

    if .hint$ = "twogroups"
        .tableId = Create Table with column names: "demo_two_groups",
            ... 40, "Subject Group F0_Hz Jitter_Pct"
        for .i from 1 to 20
            Set string value: .i, "Subject", "S" + string$ (.i)
            Set string value: .i, "Group", "Control"
            Set numeric value: .i, "F0_Hz", randomGauss (120, 15)
            Set numeric value: .i, "Jitter_Pct",
                ... max (0.1, randomGauss (0.8, 0.3))
        endfor
        for .i from 21 to 40
            Set string value: .i, "Subject", "S" + string$ (.i)
            Set string value: .i, "Group", "Patient"
            Set numeric value: .i, "F0_Hz", randomGauss (140, 25)
            Set numeric value: .i, "Jitter_Pct",
                ... max (0.1, randomGauss (2.1, 0.8))
        endfor
        .dataDefault = 3
        .groupDefault = 2
        .col1Default = 3
        .col2Default = 4
        .factor1Default = 2
        .factor2Default = 2

    elsif .hint$ = "kgroups"
        .tableId = Create Table with column names: "demo_three_groups",
            ... 45, "Singer Voice_Type SPL_dB Vibrato_Rate_Hz"
        for .i from 1 to 15
            Set string value: .i, "Singer", "Singer_" + string$ (.i)
            Set string value: .i, "Voice_Type", "Soprano"
            Set numeric value: .i, "SPL_dB", randomGauss (92, 4)
            Set numeric value: .i, "Vibrato_Rate_Hz",
                ... max (3, randomGauss (5.8, 0.6))
        endfor
        for .i from 16 to 30
            Set string value: .i, "Singer", "Singer_" + string$ (.i)
            Set string value: .i, "Voice_Type", "Mezzo"
            Set numeric value: .i, "SPL_dB", randomGauss (88, 5)
            Set numeric value: .i, "Vibrato_Rate_Hz",
                ... max (3, randomGauss (5.5, 0.7))
        endfor
        for .i from 31 to 45
            Set string value: .i, "Singer", "Singer_" + string$ (.i)
            Set string value: .i, "Voice_Type", "Alto"
            Set numeric value: .i, "SPL_dB", randomGauss (85, 4)
            Set numeric value: .i, "Vibrato_Rate_Hz",
                ... max (3, randomGauss (5.2, 0.5))
        endfor
        .dataDefault = 3
        .groupDefault = 2
        .col1Default = 3
        .col2Default = 4
        .factor1Default = 2
        .factor2Default = 2

    elsif .hint$ = "twofactor"
        .tableId = Create Table with column names: "demo_two_factor",
            ... 48, "Subject Voice_Type Task SPL_dB"
        .row = 0
        for .iVoice from 1 to 2
            if .iVoice = 1
                .vt$ = "Soprano"
                .baseSPL = 90
            else
                .vt$ = "Alto"
                .baseSPL = 85
            endif
            for .iTask from 1 to 2
                if .iTask = 1
                    .task$ = "Speech"
                    .taskFx = 0
                else
                    .task$ = "Singing"
                    .taskFx = 8
                endif
                for .iSubj from 1 to 12
                    .row = .row + 1
                    Set string value: .row, "Subject",
                        ... .vt$ + "_" + string$ (.iSubj)
                    Set string value: .row, "Voice_Type", .vt$
                    Set string value: .row, "Task", .task$
                    .inter = 0
                    if .iVoice = 1 and .iTask = 2
                        .inter = 3
                    endif
                    Set numeric value: .row, "SPL_dB",
                        ... .baseSPL + .taskFx + .inter
                        ... + randomGauss (0, 3)
                endfor
            endfor
        endfor
        .dataDefault = 4
        .groupDefault = 2
        .col1Default = 4
        .col2Default = 4
        .factor1Default = 2
        .factor2Default = 3

    elsif .hint$ = "paired"
        .tableId = Create Table with column names: "demo_pre_post",
            ... 20, "Subject Jitter_Pre Jitter_Post HNR_Pre HNR_Post"
        for .i from 1 to 20
            Set string value: .i, "Subject", "P" + string$ (.i)
            .preJ = max (0.1, randomGauss (2.5, 0.8))
            Set numeric value: .i, "Jitter_Pre", .preJ
            Set numeric value: .i, "Jitter_Post",
                ... max (0.1, .preJ - randomGauss (0.8, 0.4))
            .preH = randomGauss (18, 4)
            Set numeric value: .i, "HNR_Pre", .preH
            Set numeric value: .i, "HNR_Post",
                ... .preH + randomGauss (3, 1.5)
        endfor
        .dataDefault = 2
        .groupDefault = 1
        .col1Default = 2
        .col2Default = 3
        .factor1Default = 1
        .factor2Default = 1

    elsif .hint$ = "correlation"
        .tableId = Create Table with column names: "demo_F0_relationship",
            ... 30, "Speaker Speaking_F0_Hz Singing_F0_Hz Age_Years"
        for .i from 1 to 30
            Set string value: .i, "Speaker", "Spk" + string$ (.i)
            .spkF0 = max (80, randomGauss (160, 40))
            Set numeric value: .i, "Speaking_F0_Hz", .spkF0
            Set numeric value: .i, "Singing_F0_Hz",
                ... max (150, .spkF0 * 2.1 + randomGauss (0, 30))
            Set numeric value: .i, "Age_Years",
                ... round (randomUniform (22, 65))
        endfor
        .dataDefault = 2
        .groupDefault = 1
        .col1Default = 2
        .col2Default = 3
        .factor1Default = 1
        .factor2Default = 1

    elsif .hint$ = "regression"
        .tableId = Create Table with column names:
            ... "demo_practice_effect", 25,
            ... "Singer Practice_Hrs_Wk Vibrato_Regularity_Pct Experience_Yrs"
        for .i from 1 to 25
            Set string value: .i, "Singer", "S" + string$ (.i)
            .hrs = max (1, randomGauss (12, 5))
            Set numeric value: .i, "Practice_Hrs_Wk", .hrs
            .reg = 40 + 3.2 * .hrs + randomGauss (0, 8)
            Set numeric value: .i, "Vibrato_Regularity_Pct",
                ... min (100, max (10, .reg))
            Set numeric value: .i, "Experience_Yrs",
                ... max (1, round (.hrs * 0.8 + randomGauss (0, 3)))
        endfor
        .dataDefault = 3
        .groupDefault = 1
        .col1Default = 2
        .col2Default = 3
        .factor1Default = 1
        .factor2Default = 1

    else
        # "describe" and fallback
        .tableId = Create Table with column names:
            ... "demo_voice_measures", 40,
            ... "Subject F0_Hz Shimmer_Pct Jitter_Pct"
        for .i from 1 to 40
            Set string value: .i, "Subject", "S" + string$ (.i)
            Set numeric value: .i, "F0_Hz", randomGauss (180, 30)
            Set numeric value: .i, "Shimmer_Pct",
                ... exp (randomGauss (0.7, 0.5))
            Set numeric value: .i, "Jitter_Pct",
                ... max (0.05, randomGauss (1.2, 0.6))
        endfor
        .dataDefault = 2
        .groupDefault = 1
        .col1Default = 2
        .col2Default = 3
        .factor1Default = 1
        .factor2Default = 1
    endif

    selectObject: .tableId
    View & Edit
endproc


# ============================================================================
# @wizardStub — Standard message for unimplemented terminals
# ============================================================================

procedure wizardStub: .analysis$, .batch$
    appendInfoLine: "── Not Yet Available ──"
    appendInfoLine: ""
    appendInfoLine: "  ", .analysis$, " is planned for a future update."
    appendInfoLine: ""
    appendInfoLine: "  In the meantime, you can use the named tools"
    appendInfoLine: "  in the EML Tools menu for available analyses."
    appendInfoLine: ""
endproc
