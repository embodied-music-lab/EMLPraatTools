# ============================================================================
# EML Stats & Graphs — Stats Wizard
# ============================================================================
# Purpose: Question-driven statistical analysis wizard. Routes research
#          questions to the appropriate test via chained dialogs, runs the
#          analysis, and reports results in the Info window.
#
#          Three layers of access (this script = Layer 1):
#            Layer 1 — Wizard: Question-driven entry for clinicians/students
#            Layer 2 — Direct tools: Named tests from EML Stats & Graphs menu
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
# Q-Q draw for the normality page (punch list 4.6). Not part of
# eml-lib-graphs.praat yet, so pulled in here directly — same reason and
# same relative path eml-check-normality.praat's own header gives.
include ../graphs/eml-draw-qq.praat

# ── Wizard mode: enable third-column explanations ────────────────────────
emlShowExplanations = 1

# ── Check Table or TableOfReal selection ──────────────────────────────────

nTables = numberOfSelected ("Table")
nToR = numberOfSelected ("TableOfReal")
hasTable = 0
tableId = 0
nCols = 0
# THE NAME EVERY PAGE PRINTS EXISTS FROM THE FIRST LINE.
#
# Fourteen pages print "Table: " + displayTable$, and the table itself is not
# always there when they do: with nothing selected the wizard invents example
# data, and it invents it at the point the chosen branch needs columns --
# which on some branches is AFTER a page that has already printed the name.
# Praat stops the script dead on an unset variable, so such a page does not
# render blank, it raises "Unknown variable" over a form the user has just
# clicked Continue on.
#
# Seeding it here means no page can reach an unset name, whatever order a
# future branch puts its questions in, and it is the one line that cannot be
# forgotten by the fifteenth page. @wizardPrepareTable overwrites it with the
# real name the moment the example table exists.
displayTable$ = "none selected — example data will be created"

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

# ONE TRIP ROUND THE WIZARD IS ONE RECORDED RUN, for the reason the graphs
# form gives at its own pass loop: "Start over" returns here inside the same
# script scope, and the recorder names an emitted script's variables by the
# run they came from. Guarded on the recorder's load flag like every other
# call into it.
if variableExists ("emlRecordLoaded")
    @emlRecordNewRun
endif

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
wizPairedHasSubjectCol = 0
wizPairedSubjectCol$ = ""
wizPairedHasGroupCol = 0
wizPairedGroupCol$ = ""
wizTwoWayFactor1$ = ""
wizTwoWayFactor2$ = ""
dataCol$ = ""
groupCol$ = ""
corrCol1$ = ""
corrCol2$ = ""
# Correlation group column (punch list 4.4) — seeded by NAME, not index:
# the filtered candidate list is rebuilt every time B_TEST_PAGE is
# rendered and its indices are not stable (same reasoning as the menu
# door's selGroupName$, eml-correlate.praat).
wizCorrGrpSelName$ = ""
# Regression group column (punch list 4.5) — same seeded-by-name idiom.
# Shared by both wizard regression entry points (B_REG_COLUMNS under
# "Relationship > Regression" and D_PREDICT_COLUMNS under "Predict an
# outcome"): only one of the two runs per wizard session, so one seed
# variable is enough, exactly as wizDrawSource$ above is shared across
# every branch that can draw.
wizRegGrpSelName$ = ""
wizRegDrawGroupCol$ = ""
# Group order (punch list 4.7): the menu door's own "Table order /
# Alphabetical" dropdown, added to the group-based wizard pages. Reset to
# the default once per wizard launch — the session-persistence rule does
# not apply here, since the wizard runs fresh per launch (A9 in the
# hardcode review).
wizGroupOrderDefault = 1

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
        # WITHIN-SUBJECT, not "paired", on this branch label. "Paired" is the
        # proper name of exactly one test -- the paired t-test -- and that test
        # exists only at k = 2. This page is the fork that sends a user with
        # THREE OR MORE conditions on to RM-ANOVA / Friedman, so a label that
        # says "paired" tells a user with four conditions that this is not
        # their answer. What they pick instead is the other option, and a
        # between-subjects test then runs on within-subject data: it completes,
        # it prints, and it is wrong in the direction nobody checks, because
        # the subject-to-subject variance stays in the error term and the
        # effect the design was built to see is buried under it. "Paired" is
        # kept where it is the name of the thing -- the k = 2 option on the A3
        # gate page below.
        optionmenu: "Observation type", prevObsType
            option: "No — different groups (independent)"
            option: "Yes — same people, measured more than once (within-subject)"
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
                comment: "     test (fewer assumptions) is recommended."
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
                comment: "More statistical power. Welch does not assume equal"
                comment: "group variances and is the safer default."
                comment: ""
                comment: "Nonparametric — Mann-Whitney U, rank-biserial r"
                comment: "Works on any distribution. Tests rank order, not means."
                comment: ""
                comment: "─────────────────────────────────────"
                @emlWizard2GroupTestToMenu: normDefault, prevVarAssume
                optionmenu: "Test", emlWizard2GroupTestToMenu.row
                    @emlWizard2GroupTestRows
                optionmenu: "Group order", wizGroupOrderDefault
                    option: "Table order"
                    option: "Alphabetical"
                boolean: "Clear Info window", 0
                comment: ""
            clicked = endPause: "Quit", "Back", "Run", 3, 0
            if clicked = 1
                exitScript: ""
            elsif clicked = 2
                goto A2A_NORM_PAGE
            endif

            # BEFORE the header guard below, not after — its own
            # `goto A2A_TEST_PAGE` must not skip this preserve step (v128).
            wizGroupOrderDefault = group_order

            # A CATEGORY HEADER IS NOT A CHOICE. Same guard the graph-type
            # menu uses (graphs/eml-graphs-form.praat), reused rather than
            # reinvented: a parallel mapping marks the header rows, the
            # chosen row is remapped through it, and landing on a header
            # re-shows the page with a small box instead of dispatching a
            # test the row never named. This file already returns to a page
            # by `goto` rather than a repeat loop, so the re-show does the
            # same, back to this page's own label.
            @emlWizard2GroupTestFromMenu: test
            if emlWizard2GroupTestFromMenu.isHeader = 1
                beginPause: "Please choose a test."
                    comment: "The item you selected is a category header."
                    comment: "Please choose a test from the list."
                endPause: "OK", 1, 0
                goto A2A_TEST_PAGE
            endif

            if clear_Info_window
                @emlClearInfo
            endif

            # ── Dispatch ───────────────────────────────────────────────

            # ONE SOURCE FOR THE CHOSEN ROW. test_approach, prevVarAssume and
            # wizTName$ all come off @emlWizard2GroupTestFromMenu's decode of
            # the SAME row the user picked, so the report can never name a
            # test other than the one dispatched below.
            test_approach = emlWizard2GroupTestFromMenu.testApproach
            prevVarAssume = emlWizard2GroupTestFromMenu.varAssume
            wizEqualVar = prevVarAssume - 1
            wizTName$ = emlWizard2GroupTestFromMenu.reportName$

            # Group order (punch list 4.7) — same single flag every menu
            # door funnels the user's choice through (stats/eml-output.praat).
            if group_order = 2
                emlGroupSortAlphabetical = 1
            else
                emlGroupSortAlphabetical = 0
            endif

            @wizardNormLabel: normChecked, normSummary$, test_approach

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
            elsif test_approach = 2
                wizTestType$ = "nonparametric"
                @wizardReportPlan: "Two independent groups",
                ... wizardNormLabel.result$,
                ... wizTName$,
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
            else
                # "Both" — dispatched the way the menu door's "Both parametric
                # and nonparametric" row is (eml-compare-groups.praat): one
                # call, testType$ = "both", straight into
                # @emlRunTwoGroupAnalysis. The draw preset that follows
                # (WIZ_DRAW_FIGURE) reads wizTestType$, and the menu door's own
                # Draw preset on this row is "parametric" (its dispatch falls
                # into the same `else` that testChoice = 1/2 use) — matched
                # here rather than invented.
                wizTestType$ = "parametric"
                @wizardReportPlan: "Two independent groups",
                ... wizardNormLabel.result$,
                ... wizTName$,
                ... "n/a", dataCol$, groupCol$, "", displayTable$
                @emlRunTwoGroupAnalysis: tableId, dataCol$,
                ... groupCol$, "both", wizEqualVar
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
                comment: "     test (fewer assumptions) is recommended."
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
                # THIS PARAGRAPH USED TO PROMISE THE GATE. It opened "If the
                # overall test is significant, the wizard compares each pair of
                # groups", which was true of two of the six rows below and is
                # true of none of them now: a post-hoc the user chooses always
                # runs (punch list 2026-08-25, lane 3.1/3.2). The replacement
                # is the approved wording, language batch item 4 revision 6,
                # verbatim, and it is dialog text -- always visible, since the
                # explanations toggle does not reach a dialog page. The Dunn/
                # pairwise-Wilcoxon sentence is the revision-6 addition that
                # explains why the grid needed the three Wilcoxon rows (4.3):
                # Dunn is not a substitute for pairwise Wilcoxon, and vice
                # versa -- they rank differently.
                comment: "Pairwise comparisons run when you choose them, and every pairwise"
                comment: "option adjusts for multiple comparisons. Tukey, Scheffe, Holm, and"
                comment: "Bonferroni keep the chance of any false positive at or below the"
                comment: "stated level; Benjamini-Hochberg instead limits the expected share"
                comment: "of false positives, which is less strict. Dunn compares groups on"
                comment: "the shared ranking from the overall test; pairwise Wilcoxon re-ranks"
                comment: "each pair on its own. The overall test and the pairwise results are"
                comment: "reported together."
                comment: ""
                @emlWizard3GroupTestToMenu: normDefault
                optionmenu: "Test", emlWizard3GroupTestToMenu.row
                    @emlWizard3GroupTestRows
                optionmenu: "Group order", wizGroupOrderDefault
                    option: "Table order"
                    option: "Alphabetical"
                boolean: "Clear Info window", 0
                comment: ""
            clicked = endPause: "Quit", "Back", "Run", 3, 0
            if clicked = 1
                exitScript: ""
            elsif clicked = 2
                goto A2B_NORM_PAGE
            endif

            # BEFORE the header guard below, not after — its own
            # `goto A2B_TEST_PAGE` must not skip this preserve step (v128).
            wizGroupOrderDefault = group_order

            # A CATEGORY HEADER IS NOT A CHOICE. Same guard as the two-group
            # test page above and the graph-type menu it was reused from: a
            # parallel mapping marks the header rows, the chosen row is
            # remapped through it, and landing on a header re-shows this
            # page with a small box instead of dispatching a test the row
            # never named.
            @emlWizard3GroupTestFromMenu: test
            if emlWizard3GroupTestFromMenu.isHeader = 1
                beginPause: "Please choose a test."
                    comment: "The item you selected is a category header."
                    comment: "Please choose a test from the list."
                endPause: "OK", 1, 0
                goto A2B_TEST_PAGE
            endif

            if clear_Info_window
                @emlClearInfo
            endif

            # ── Map the row ────────────────────────────────────────────────
            # test_approach, phTest$, phAdj$ and phLabel$ all decode off the
            # ONE row the user picked, so the pairing dispatched below is
            # always the pairing the row named — never a leftover from a
            # different row. phTest$ = "" means the row's own "only, no
            # pairwise tests" choice — punch list 4.2 — and is the row's
            # choice now, not a hardcoded doDunn/doTukey.

            test_approach = emlWizard3GroupTestFromMenu.testApproach
            phTest$ = emlWizard3GroupTestFromMenu.phTest$
            phAdj$ = emlWizard3GroupTestFromMenu.phAdj$
            phLabel$ = emlWizard3GroupTestFromMenu.phLabel$

            # Group order (punch list 4.7) — same single flag every menu
            # door funnels the user's choice through (stats/eml-output.praat).
            if group_order = 2
                emlGroupSortAlphabetical = 1
            else
                emlGroupSortAlphabetical = 0
            endif

            # ── Dispatch: ANOVA or KW ──────────────────────────────────────

            @wizardNormLabel: normChecked, normSummary$, test_approach

            if test_approach = 1
                wizTestType$ = "parametric"

                # A row value states what runs and never why -- language
                # batch item 14. "n/a" for the no-pairwise row hides the
                # Post-hoc line in @wizardReportPlan the same way every other
                # "n/a" posthoc value in this file does.
                if phTest$ = ""
                    phMethod$ = "n/a"
                else
                    phMethod$ = phLabel$
                endif

                @wizardReportPlan: "Three or more independent groups",
                ... wizardNormLabel.result$,
                ... "One-way ANOVA (η²)",
                ... phMethod$,
                ... dataCol$, groupCol$, "", displayTable$

                doTukey = 0
                if phTest$ = "tukey"
                    doTukey = 1
                endif

                # THE OMNIBUS IS NOT THE WHOLE RUN ON EVERY ROW, and the
                # ANOVA report has no way of knowing that by itself. With
                # Tukey off it prints the pairwise effect-size matrix under a
                # caption saying no pairwise significance test was run -- true
                # of that report, false of a run whose row named a pairwise
                # test, and contradicted a few lines later by the table the
                # user chose. RAISED FOR THIS CALL AND LOWERED IMMEDIATELY
                # AFTER, the way @emlGraphsWorkflow brackets
                # emlShowExplanations: a flag left raised would silence the
                # caption on the next analysis in the session, which is the
                # failure mode every scoped global in this tree has had at
                # least once.
                emlPairwiseFollows = 0
                if phTest$ = "scheffe" or phTest$ = "welch" or phTest$ = "student"
                    emlPairwiseFollows = 1
                endif
                @emlRunAnovaAnalysis: tableId, dataCol$, groupCol$, doTukey
                emlPairwiseFollows = 0
                if emlRunAnovaAnalysis.error$ <> ""
                    # An analysis error must not tear down the wizard. Return
                    # the user into the back-chain with every answer intact.
                    @emlErrorDialog: emlRunAnovaAnalysis.error$, emlRunAnovaAnalysis.remedy$, "wizard"
                    if emlErrorDialog.back
                        goto A2B_NORM_PAGE
                    endif
                    exitScript: ""
                endif

                # THE POST-HOC THE USER CHOSE, RUN — every parametric
                # pairwise row, unconditionally (punch list lane 3.1/3.2; no
                # p-value gate, no hardcoded alpha). @emlRunPairwiseAnalysis
                # takes the SAME test$/adjMethod$ vocabulary the standalone
                # pairwise dialog uses (eml-pairwise.praat) — welch, student
                # or scheffe, with holm, bonferroni or bh — decoded above off
                # the row rather than invented here, so the grid this row
                # picks from is the SAME complete grid the standalone dialog
                # offers (punch list 4.3). Tukey (phTest$ = "tukey") is
                # reported by the ANOVA orchestrator itself and needs no call
                # here; phTest$ = "" (no pairwise tests) needs none either.
                if phTest$ = "scheffe" or phTest$ = "welch" or phTest$ = "student"
                    @emlRunPairwiseAnalysis: tableId, dataCol$,
                    ... groupCol$, phTest$, phAdj$
                    if emlRunPairwiseAnalysis.error$ <> ""
                        appendInfoLine: "NOTE: Post-hoc error — "
                        ... + emlRunPairwiseAnalysis.error$
                    else
                        # THE CAUTION BELONGS TO THE TABLE IT QUALIFIES, and
                        # on this door the post-hoc's table is a report of its
                        # own, printed by @emlRunPairwiseAnalysis after the
                        # ANOVA's. The wizard is the one place that holds both
                        # halves -- the omnibus it just ran and the post-hoc it
                        # just ran -- so the wizard is where the line is asked
                        # for. Same procedure, same wording, same routing as
                        # the two reporters that carry it themselves.
                        @emlPostHocCaution: emlOneWayAnova.p
                    endif
                endif

            else
                wizTestType$ = "nonparametric"

                # doDunn is the row's own choice now (punch list 4.2) — the
                # "Kruskal-Wallis only" row passes doDunn = 0 to
                # @emlRunKruskalWallisAnalysis the way the menu KW wrapper's own
                # "Kruskal-Wallis" row does (eml-compare-kw.praat), instead of
                # the old doDunn = 1 literal.
                doDunn = 0
                adjMethod$ = "holm"
                if phTest$ = "dunn"
                    doDunn = 1
                    adjMethod$ = phAdj$
                endif

                if phTest$ = ""
                    phMethod$ = "n/a"
                else
                    phMethod$ = phLabel$
                endif

                @wizardReportPlan: "Three or more independent groups",
                ... wizardNormLabel.result$,
                ... "Kruskal-Wallis (ε²)",
                ... phMethod$,
                ... dataCol$, groupCol$, "", displayTable$

                # SAME BRACKET AS THE ANOVA BRANCH ABOVE, and for the same
                # reason: with Dunn off, @emlReportKWComparison's own
                # effect-size caption (@emlEffectMatrixCaption) would say "no
                # pairwise significance tests were run" even on the row that
                # is about to run pairwise Wilcoxon a few lines down. Raised
                # around the KW call, lowered immediately after.
                emlPairwiseFollows = 0
                if phTest$ = "wilcoxon"
                    emlPairwiseFollows = 1
                endif
                @emlRunKruskalWallisAnalysis: tableId, dataCol$, groupCol$, doDunn,
                ... adjMethod$
                emlPairwiseFollows = 0
                if emlRunKruskalWallisAnalysis.error$ <> ""
                    # An analysis error must not tear down the wizard. Return
                    # the user into the back-chain with every answer intact.
                    @emlErrorDialog: emlRunKruskalWallisAnalysis.error$, emlRunKruskalWallisAnalysis.remedy$, "wizard"
                    if emlErrorDialog.back
                        goto A2B_NORM_PAGE
                    endif
                    exitScript: ""
                endif

                # PAIRWISE WILCOXON, THE ROW THE USER CHOSE — punch list 4.3.
                # Dunn is not a substitute: Dunn re-uses the KW omnibus's own
                # ranking, while pairwise Wilcoxon re-ranks each pair on its
                # own, so this is a second engine call, exactly the shape the
                # Scheffe/Welch/Student rows already take above. Same
                # @emlRunPairwiseAnalysis call the standalone pairwise
                # dialog makes for this cell (test$ = "wilcoxon"), decoded
                # off the row, not invented here.
                if phTest$ = "wilcoxon"
                    @emlRunPairwiseAnalysis: tableId, dataCol$,
                    ... groupCol$, phTest$, phAdj$
                    if emlRunPairwiseAnalysis.error$ <> ""
                        appendInfoLine: "NOTE: Post-hoc error — "
                        ... + emlRunPairwiseAnalysis.error$
                    else
                        @emlPostHocCaution: emlKruskalWallis.p
                    endif
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
            ... "not assessed", "Two-way ANOVA",
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
            # CONDITIONS, not "measurements". The k things counted here are
            # LEVELS OF THE WITHIN-SUBJECT FACTOR -- SPSS's term, and what the
            # wide format glossed below already encodes: ONE measurement, taken
            # under k circumstances. Asking how many "measurements per subject"
            # invites the reader to count DIFFERENT VARIABLES -- F0 and SPL and
            # jitter -- which is a plotting question and not this one. A user
            # who reads it that way answers "three or more" for three unrelated
            # columns and is handed an RM-ANOVA across incommensurable units:
            # an F, a p and a Greenhouse-Geisser correction computed over Hz,
            # decibels and percent as though they were one measurement. It read
            # that way to the author of this plugin, so it will read that way
            # to a student.
            comment: "Under how many conditions was each subject measured?"
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

        # Paired figure columns (punch list 4.8) — seeded the way the menu
        # door's paired wrapper seeds its own Subject column
        # (eml-compare-paired.praat): the guessed subject column, +1 for
        # the leading "(row number)" entry. Group column has no guess, so
        # it opens on "(none)".
        @emlGuessColumnRoles: tableId
        wizSubjDefault = emlGuessColumnRoles.subjectIdx + 1
        wizGroupColDefault = 1

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
            comment: "     test (fewer assumptions) is recommended."
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

        beginPause: "Paired — Choose test"
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
            @emlWizardPairedTestToMenu: normDefault
            optionmenu: "Test", emlWizardPairedTestToMenu.row
                @emlWizardPairedTestRows
            comment: ""
            comment: "For spaghetti plot (optional):"
            optionmenu: "Subject column", wizSubjDefault
                option: "(row number)"
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            optionmenu: "Group column", wizGroupColDefault
                option: "(none)"
            for iCol from 1 to nCols
                option: emlTableColumnNames.name$[iCol]
            endfor
            boolean: "Clear Info window", 0
            comment: ""
        clicked = endPause: "Quit", "Back", "Run", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto A3_NORM_PAGE
        endif

        # BEFORE the header guard below, not after — its own
        # `goto A3_TEST_PAGE` must not skip this preserve step (v128).
        wizSubjDefault = subject_column
        wizGroupColDefault = group_column

        # A CATEGORY HEADER IS NOT A CHOICE. Same guard as the two-group
        # test page.
        @emlWizardPairedTestFromMenu: test
        if emlWizardPairedTestFromMenu.isHeader = 1
            beginPause: "Please choose a test."
                comment: "The item you selected is a category header."
                comment: "Please choose a test from the list."
            endPause: "OK", 1, 0
            goto A3_TEST_PAGE
        endif

        if clear_Info_window
            @emlClearInfo
        endif

        test_approach = emlWizardPairedTestFromMenu.testApproach
        wizTName$ = emlWizardPairedTestFromMenu.reportName$

        @wizardNormLabel: normChecked, normSummary$, test_approach

        if test_approach = 1
            @wizardReportPlan: "Two conditions (paired)",
            ... wizardNormLabel.result$,
            ... wizTName$,
            ... "n/a", column_1$, "", column_2$, displayTable$
            @emlRunPairedAnalysis: tableId, column_1$, column_2$,
            ... "parametric"
            wizTestType$ = "parametric"
        elsif test_approach = 2
            @wizardReportPlan: "Two conditions (paired)",
            ... wizardNormLabel.result$,
            ... wizTName$,
            ... "n/a", column_1$, "", column_2$, displayTable$
            @emlRunPairedAnalysis: tableId, column_1$, column_2$,
            ... "nonparametric"
            wizTestType$ = "nonparametric"
        else
            # "Both" — dispatched the way the menu door's paired wrapper
            # dispatches its own "Both" row (eml-compare-paired.praat):
            # testType$ = "both" straight into @emlRunPairedAnalysis. The
            # draw preset that follows (WIZ_DRAW_FIGURE) has no paired-test
            # dependence, so wizTestType$ = "parametric" here is only the
            # report/preserve label, not a draw choice.
            @wizardReportPlan: "Two conditions (paired)",
            ... wizardNormLabel.result$,
            ... wizTName$,
            ... "n/a", column_1$, "", column_2$, displayTable$
            @emlRunPairedAnalysis: tableId, column_1$, column_2$,
            ... "both"
            wizTestType$ = "parametric"
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

        # Subject / group columns for the spaghetti plot (punch list 4.8),
        # decoded the way the menu door's paired wrapper decodes its own
        # two menus (eml-compare-paired.praat): index 1 is the leading
        # placeholder entry, 2+ is a real column.
        wizPairedHasSubjectCol = 0
        wizPairedSubjectCol$ = ""
        if subject_column > 1
            wizPairedHasSubjectCol = 1
            wizPairedSubjectCol$ = emlTableColumnNames.name$ [subject_column - 1]
        endif
        wizPairedHasGroupCol = 0
        wizPairedGroupCol$ = ""
        if group_column > 1
            wizPairedHasGroupCol = 1
            wizPairedGroupCol$ = emlTableColumnNames.name$ [group_column - 1]
        endif

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
            ... "not assessed", "RM-ANOVA (Greenhouse-Geisser)",
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
            ... "not assessed", "Friedman test",
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

        # ── candidate grouping columns (punch list 4.5) ────────────────
        # Rebuilt every time this label is reached -- @wizardRegGrpCandidates
        # filters against the CURRENT col1Default/col2Default, so a
        # predictor or response bound on the previous pass through this
        # same page cannot still be offered as the grouping column.
        wizRegPredName$ = emlTableColumnNames.name$ [col1Default]
        wizRegRespName$ = emlTableColumnNames.name$ [col2Default]
        @wizardRegGrpCandidates: wizRegPredName$, wizRegRespName$
        wizRegGrpSelIdx = 1
        for iG from 1 to wizRegGrpN
            if wizRegGrpName$ [iG] = wizRegGrpSelName$
                wizRegGrpSelIdx = iG + 1
            endif
        endfor

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
            comment: ""
            optionmenu: "Group column", wizRegGrpSelIdx
                option: "(none — overall only)"
            for iCol from 1 to wizRegGrpN
                option: wizRegGrpName$ [iCol]
            endfor
            if wizRegGrpN = 0
                comment: "     (no column in this Table has a usable number"
                comment: "     of groups — overall only)"
            endif
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

        # Leading "(none)" entry: a position in the FILTERED list, not a
        # column index -- same idiom as the correlation page's group menu.
        # Preserved BEFORE the error checks below (v128), so neither error's
        # own `goto B_REG_COLUMNS` re-renders the page showing "(none)"
        # instead of what was just chosen.
        wizRegHasGroupCol = 0
        wizRegGroupCol$ = ""
        if group_column > 1
            wizRegHasGroupCol = 1
            wizRegGroupCol$ = wizRegGrpName$ [group_column - 1]
        endif
        wizRegGrpSelName$ = wizRegGroupCol$

        if predictor_column$ = response_column$
            # A correctable selection mistake must not end the wizard.
            @emlErrorDialog: "Please select two different columns.", "", "wizard"
            if emlErrorDialog.back
                goto B_REG_COLUMNS
            endif
            exitScript: ""
        elsif wizRegHasGroupCol and (wizRegGroupCol$ = predictor_column$ or wizRegGroupCol$ = response_column$)
            # THE STALE GROUP LIST -- same hazard as the menu door's own
            # regression dialog and v102's correlate-dialog original: the
            # candidate list is built from the PREVIOUS pass's predictor and
            # response, so moving either onto the current grouping column
            # is refused rather than silently run.
            staleMsg$ = "The grouping column """ + wizRegGroupCol$ + """ is now"
            staleMsg$ = staleMsg$ + " one of the two columns being"
            staleMsg$ = staleMsg$ + " regressed, so it cannot also group"
            staleMsg$ = staleMsg$ + " them. Nothing was run. The list of"
            staleMsg$ = staleMsg$ + " grouping columns was built before you"
            staleMsg$ = staleMsg$ + " changed the predictor or response"
            staleMsg$ = staleMsg$ + " column; Back will rebuild it for the"
            staleMsg$ = staleMsg$ + " columns you have now chosen."
            @emlErrorDialog: staleMsg$, "", "wizard"
            wizRegGrpSelName$ = ""
            if emlErrorDialog.back
                goto B_REG_COLUMNS
            endif
            exitScript: ""
        endif

        if clear_Info_window
            @emlClearInfo
        endif

        @wizardReportPlan: "Simple linear regression",
        ... "not assessed (residual normality assumed)",
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

        # Per-group regression (punch list 4.5) -- @emlLinearRegression ran
        # once above for the whole table and its globals still hold that
        # overall fit; @emlRunGroupedRegressionAnalysis reads them before anything
        # else runs.
        if wizRegHasGroupCol
            selectObject: tableId
            @emlRunGroupedRegressionAnalysis: tableId, predictor_column$,
            ... response_column$, wizRegGroupCol$
        endif

        # Set draw presets for scatter plot with regression line
        corrCol1$ = predictor_column$
        corrCol2$ = response_column$
        wizCanDraw = 1
        wizCanExport = 1
        wizDrawSource$ = "regression"
        wizRegDrawGroupCol$ = wizRegGroupCol$

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

    # ── Group column candidates (punch list 4.4) ───────────────────────
    #
    # Same filter as the menu door's correlation dialog
    # (eml-correlate.praat): a grouping column has to be able to grade the
    # correlation, so corrCol1$/corrCol2$ themselves are excluded, as are
    # single-valued columns and near-unique columns (one group per row).
    # Ceiling is 12 levels or n/3, whichever is smaller — n/3 keeps every
    # group above the n >= 3 the per-group loop below enforces, and past a
    # dozen levels a grouped report stops being readable. Rebuilt every
    # time this label is reached, because corrCol1$/corrCol2$ can change
    # on a Back-and-return.
    selectObject: tableId
    wizCorrGrpNRows = Get number of rows
    wizCorrGrpMaxLevels = min (12, max (2, floor (wizCorrGrpNRows / 3)))
    wizCorrGrpN = 0
    for wizCorrIcol from 1 to nCols
        wizCorrCand$ = emlTableColumnNames.name$ [wizCorrIcol]
        if wizCorrCand$ <> corrCol1$ and wizCorrCand$ <> corrCol2$
            wizCorrLevels = 0
            wizCorrOver = 0
            for wizCorrIrow from 1 to wizCorrGrpNRows
                if wizCorrOver = 0
                    selectObject: tableId
                    wizCorrCell$ = Get value: wizCorrIrow, wizCorrCand$
                    @eml_normalizeLabel: wizCorrCell$
                    wizCorrNorm$ = eml_normalizeLabel.result$
                    wizCorrSeen = 0
                    for wizCorrIlev from 1 to wizCorrLevels
                        if wizCorrLevel$ [wizCorrIlev] = wizCorrNorm$
                            wizCorrSeen = 1
                        endif
                    endfor
                    if wizCorrSeen = 0
                        wizCorrLevels = wizCorrLevels + 1
                        wizCorrLevel$ [wizCorrLevels] = wizCorrNorm$
                        if wizCorrLevels > wizCorrGrpMaxLevels
                            wizCorrOver = 1
                        endif
                    endif
                endif
            endfor
            if wizCorrOver = 0 and wizCorrLevels >= 2
                wizCorrGrpN = wizCorrGrpN + 1
                wizCorrGrpName$ [wizCorrGrpN] = wizCorrCand$
            endif
        endif
    endfor

    # Seed from the user's last choice by NAME.
    wizCorrGrpSelIdx = 1
    for wizCorrIg from 1 to wizCorrGrpN
        if wizCorrGrpName$ [wizCorrIg] = wizCorrGrpSelName$
            wizCorrGrpSelIdx = wizCorrIg + 1
        endif
    endfor

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
        optionmenu: "Test", normDefault
            option: "Pearson r"
            option: "Spearman rho"
            option: "Both Pearson and Spearman"
        comment: ""
        optionmenu: "Group column", wizCorrGrpSelIdx
            option: "(none — overall only)"
        for wizCorrIcol from 1 to wizCorrGrpN
            option: wizCorrGrpName$ [wizCorrIcol]
        endfor
        if wizCorrGrpN = 0
            comment: "     (no column in this Table has a usable number"
            comment: "     of groups — overall only)"
        endif
        boolean: "Clear Info window", 0
        comment: ""
    clicked = endPause: "Quit", "Back", "Run", 3, 0
    if clicked = 1
        exitScript: ""
    elsif clicked = 2
        goto B_NORM_PAGE
    endif

    # Leading "(none)" entry: this is a position in the FILTERED list, not
    # a column index — same idiom as the menu door.
    wizCorrHasGroupCol = 0
    wizCorrGroupCol$ = ""
    if group_column > 1
        wizCorrHasGroupCol = 1
        wizCorrGroupCol$ = wizCorrGrpName$ [group_column - 1]
    endif
    wizCorrGrpSelName$ = wizCorrGroupCol$

    # BEFORE the error check below, not after it (v128) — its own
    # `goto B_TEST_PAGE` (the analysis-error Back path) must not skip these
    # two preserve steps, or the redraw shows the normality guess and
    # "(none — overall only)" instead of what was just chosen. Group column
    # is a NAME saved above; @wizardCorrGrpIdx is its round-trip back to the
    # FILTERED list's POSITION, the same idiom @wizardCondSlot uses for the
    # repeated-measures condition slots. Test has no name to translate — the
    # chosen row already IS its own seed — so it is the direct copy every
    # other flat, non-column menu in this file uses (e.g. Group order).
    @wizardCorrGrpIdx: wizCorrGrpSelName$
    wizCorrGrpSelIdx = wizardCorrGrpIdx.idx
    normDefault = test

    if clear_Info_window
        @emlClearInfo
    endif

    # Field is named "Test" (language batch item 3), so Praat binds it to
    # `test`, not `test_approach` — the flat three-row list needs no
    # header-guard decode, so `test` is used directly as the approach index.
    test_approach = test

    @wizardNormLabel: normChecked, normSummary$, test_approach

    if test_approach = 1
        wizCorrTestType$ = "pearson"
        @wizardReportPlan: "Correlation",
        ... wizardNormLabel.result$, "Pearson r",
        ... "n/a", corrCol1$, "", corrCol2$, displayTable$
        @emlRunCorrelationAnalysis: tableId, corrCol1$,
        ... corrCol2$, "pearson"
    elsif test_approach = 2
        wizCorrTestType$ = "spearman"
        @wizardReportPlan: "Correlation",
        ... wizardNormLabel.result$, "Spearman ρ",
        ... "n/a", corrCol1$, "", corrCol2$, displayTable$
        @emlRunCorrelationAnalysis: tableId, corrCol1$,
        ... corrCol2$, "spearman"
    else
        # "Both" — dispatched the way the menu door's correlation wrapper
        # dispatches its own "Both" row (eml-correlate.praat): testType$ =
        # "both" straight into @emlRunCorrelationAnalysis.
        wizCorrTestType$ = "both"
        @wizardReportPlan: "Correlation",
        ... wizardNormLabel.result$, "Both Pearson and Spearman",
        ... "n/a", corrCol1$, "", corrCol2$, displayTable$
        @emlRunCorrelationAnalysis: tableId, corrCol1$,
        ... corrCol2$, "both"
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

    # ── Per-group correlations (punch list 4.4) ─────────────────────────
    #
    # SAME PATTERN, SAME PROCEDURES as the menu door's per-group block
    # (eml-correlate.praat) — two passes, the first only counting complete
    # pairs per group so the block can be announced with its own header
    # and counts before any group prints, and so the groups too small to
    # analyse (n < 3) are named on one summary line. One export, with the
    # grouping in a real column: tidy is rebuilt with every row labelled
    # in `term` ("(overall)" / "<group column> = <level>"), the same
    # convention the menu door's own grouped export uses.
    if wizCorrHasGroupCol
        selectObject: tableId
        @emlCountGroups: tableId, wizCorrGroupCol$
        wizPgTotal = emlCountGroups.nGroups
        wizPgRun = 0
        wizPgSkipped = 0
        wizPgSkipList$ = ""
        wizPgSkipMore = 0
        for wizPgI from 1 to wizPgTotal
            wizPgLabel$ [wizPgI] = emlCountGroups.groupLabel$ [wizPgI]
            selectObject: tableId
            @eml_getGroupPairedData: tableId, corrCol1$, corrCol2$,
            ... wizCorrGroupCol$, wizPgLabel$ [wizPgI]
            wizPgN [wizPgI] = eml_getGroupPairedData.n
            if wizPgN [wizPgI] >= 3
                wizPgRun = wizPgRun + 1
            else
                wizPgSkipped = wizPgSkipped + 1
                if length (wizPgSkipList$) < 45
                    if wizPgSkipList$ <> ""
                        wizPgSkipList$ = wizPgSkipList$ + ", "
                    endif
                    wizPgSkipList$ = wizPgSkipList$
                    ... + replace$ (wizPgLabel$ [wizPgI], "_", " ", 0)
                else
                    wizPgSkipMore = wizPgSkipMore + 1
                endif
            endif
        endfor
        if wizPgSkipMore > 0
            wizPgSkipList$ = wizPgSkipList$ + ", and "
            ... + string$ (wizPgSkipMore) + " more"
        endif

        @emlUnderscoreToSpace: wizCorrGroupCol$
        wizPgColDisplay$ = emlUnderscoreToSpace.result$
        @emlReportHeader: "Correlation by " + wizPgColDisplay$
        @emlReportLineString: "Grouping column", wizPgColDisplay$
        @emlReportLine: "Groups", wizPgTotal, 0
        @emlReportLine: "Analysed", wizPgRun, 0

        # Overall rows are re-emitted from the orchestrator's own captured
        # values before the per-group rows, so the export is never left
        # half-built and a grouped run does not silently drop its overall
        # fit the way the pre-fix menu door once did.
        wizPgCsvN = emlCSV_n
        @emlTidyClear
        if wizCorrTestType$ = "pearson" or wizCorrTestType$ = "both"
            @emlTidyRow: "(overall)"
            @emlTidyNum: "estimate", emlRunCorrelationAnalysis.pearR
            @emlTidyNum: "statistic", emlRunCorrelationAnalysis.pearT
            @emlTidyNum: "p.value", emlRunCorrelationAnalysis.pearP
            @emlTidyNum: "parameter", emlRunCorrelationAnalysis.pearDf
            @emlTidyStr: "method", "Pearson's product-moment correlation"
            @emlTidyStr: "alternative", "two.sided"
        endif
        if wizCorrTestType$ = "spearman" or wizCorrTestType$ = "both"
            @emlTidyRow: "(overall)"
            @emlTidyNum: "estimate", emlRunCorrelationAnalysis.spearRho
            @emlTidyNum: "statistic", emlRunCorrelationAnalysis.spearT
            @emlTidyNum: "p.value", emlRunCorrelationAnalysis.spearP
            @emlTidyNum: "parameter", emlRunCorrelationAnalysis.spearDf
            @emlTidyStr: "method", "Spearman's rank correlation rho"
            @emlTidyStr: "alternative", "two.sided"
        endif

        for wizPgI from 1 to wizPgTotal
            if wizPgN [wizPgI] >= 3
                wizPgDisplay$ = replace$ (wizPgLabel$ [wizPgI], "_", " ", 0)
                selectObject: tableId
                @eml_getGroupPairedData: tableId, corrCol1$, corrCol2$,
                ... wizCorrGroupCol$, wizPgLabel$ [wizPgI]
                wizPgX# = eml_getGroupPairedData.dataX#
                wizPgY# = eml_getGroupPairedData.dataY#
                wizPgThisN = eml_getGroupPairedData.n
                wizPgExcluded = eml_getGroupPairedData.nExcluded
                wizPgTerm$ = wizCorrGroupCol$ + " = " + wizPgLabel$ [wizPgI]
                if wizCorrTestType$ = "pearson" or wizCorrTestType$ = "both"
                    @emlPearsonCorrelation: wizPgX#, wizPgY#, 2
                    wizPgPearR = emlPearsonCorrelation.r
                    wizPgPearT = emlPearsonCorrelation.t
                    wizPgPearDf = emlPearsonCorrelation.df
                    wizPgPearP = emlPearsonCorrelation.p
                    wizPgPearErr$ = emlPearsonCorrelation.error$
                endif
                if wizCorrTestType$ = "spearman" or wizCorrTestType$ = "both"
                    @emlSpearmanCorrelationDispatch: wizPgX#, wizPgY#, 2
                    wizPgSpearRho = emlSpearmanCorrelation.rho
                    wizPgSpearT = emlSpearmanCorrelation.t
                    wizPgSpearDf = emlSpearmanCorrelation.df
                    wizPgSpearP = emlSpearmanCorrelation.p
                    wizPgSpearErr$ = emlSpearmanCorrelation.error$
                endif
                @emlReportCorrelationAnalysis: tableName$
                ... + " -- " + wizPgColDisplay$ + " = " + wizPgDisplay$,
                ... corrCol1$, corrCol2$, wizPgThisN, wizCorrTestType$
                if wizPgExcluded > 0
                    wizPgExclNote$ = "  Note: " + string$ (wizPgExcluded)
                    ... + " row(s) excluded for missing data"
                    ... + " (analyzed n = " + string$ (wizPgThisN)
                    ... + " complete pairs)."
                    appendInfoLine: wizPgExclNote$
                endif
                if wizCorrTestType$ = "pearson" or wizCorrTestType$ = "both"
                    if wizPgPearErr$ = ""
                        @emlTidyRow: wizPgTerm$
                        @emlTidyNum: "estimate", wizPgPearR
                        @emlTidyNum: "statistic", wizPgPearT
                        @emlTidyNum: "p.value", wizPgPearP
                        @emlTidyNum: "parameter", wizPgPearDf
                        @emlTidyStr: "method",
                        ... "Pearson's product-moment correlation"
                        @emlTidyStr: "alternative", "two.sided"
                    endif
                endif
                if wizCorrTestType$ = "spearman" or wizCorrTestType$ = "both"
                    if wizPgSpearErr$ = ""
                        @emlTidyRow: wizPgTerm$
                        @emlTidyNum: "estimate", wizPgSpearRho
                        @emlTidyNum: "statistic", wizPgSpearT
                        @emlTidyNum: "p.value", wizPgSpearP
                        @emlTidyNum: "parameter", wizPgSpearDf
                        @emlTidyStr: "method",
                        ... "Spearman's rank correlation rho"
                        @emlTidyStr: "alternative", "two.sided"
                    endif
                endif
            endif
        endfor

        # The legacy rows the per-group reporter calls appended carry a
        # fabricated table name and duplicate what tidy now holds properly
        # labelled, so the buffer is truncated back to the overall analysis
        # — same restore the menu door's own per-group block does.
        emlCSV_n = wizPgCsvN
        @emlGlanceNum: "n.groups", wizPgRun

        if wizPgSkipped > 0
            @emlReportBlank
            @emlReportLineString: "Skipped (n < 3)",
            ... string$ (wizPgSkipped) + " of " + string$ (wizPgTotal)
            ... + ": " + wizPgSkipList$
        endif
        if wizPgRun = 0
            appendInfoLine: "  No group has 3 or more complete "
            ... + "pairs — a coarser grouping column would give"
            appendInfoLine: "  correlations that can be computed."
        endif
        appendInfoLine: emlReportHeader.border$
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
        #
        # Punch list 4.6: the orchestrator's own modes -- single column,
        # all numeric columns, one column by group -- language batch item 5,
        # verbatim. The page offers all three; the other two are the menu
        # door's own modes (eml-check-normality.praat), copied here with the
        # same procedures so the two doors print the same reading for the
        # same data.

        @wizardPrepareTable: "describe"
        dataDefault = wizardPrepareTable.dataDefault
        @wizardPrepareTable: "kgroups"
        groupDefault = wizardPrepareTable.groupDefault

        # Numeric columns only, same filter the menu door applies before its
        # own dialog opens -- a non-numeric column cannot go through
        # Shapiro-Wilk. Computed once; the table does not change mid-branch.
        selectObject: tableId
        wizNormNNumeric = 0
        for wizNormIcol from 1 to nCols
            wizNormCand$ = emlTableColumnNames.name$ [wizNormIcol]
            @emlCheckNumericColumn: tableId, wizNormCand$
            if emlCheckNumericColumn.isNumeric
                wizNormNNumeric = wizNormNNumeric + 1
                wizNormNumericCol$ [wizNormNNumeric] = wizNormCand$
            endif
        endfor

        wizNormModeDefault = 1
        wizNormDataNumDefault = 1

        label C_NORMALITY

        beginPause: "Normality check"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            optionmenu: "Check", wizNormModeDefault
                option: "One column"
                option: "All numeric columns"
                option: "One column, by group"
            comment: ""
        clicked = endPause: "Quit", "Back", "Continue", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto C1_DESCRIBE
        endif

        # BEFORE the branch below -- its own goto back to C_NORMALITY (the
        # numeric-column guard, and every column page's Back) must not skip
        # this preserve step (v128).
        wizNormModeDefault = check

        if check = 2 or check = 3
            if wizNormNNumeric = 0
                # ROUTED THROUGH THE PLUGIN'S ERROR SURFACE, same wording as
                # the menu door's entry refusal (eml-check-normality.praat) --
                # this page is reached mid-wizard rather than at entry, so it
                # offers Back rather than the "entry" style's no-remedy exit.
                @emlErrorDialog: "Normality is a property of a numeric "
                ... + "variable, and none of the " + string$ (nCols)
                ... + " column(s) in """ + displayTable$
                ... + """ reads as numbers.", "", "wizard"
                if emlErrorDialog.back
                    goto C_NORMALITY
                endif
                exitScript: ""
            endif
        endif

        if check = 1
            goto C_NORM_SINGLE
        elsif check = 2
            goto C_NORM_ALL
        else
            goto C_NORM_GROUP
        endif

        # ── Mode 1: one column ───────────────────────────────────────────

        label C_NORM_SINGLE

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
            goto C_NORMALITY
        endif

        # BEFORE the goto below -- v128.
        @wizardColIdx: data_column$
        dataDefault = wizardColIdx.idx

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
                goto C_NORM_SINGLE
            endif
            exitScript: ""
        endif

        # Normality must be able to save.
        wizCanExport = 1

        # Q-Q draw (punch list 4.6) -- one column, no group.
        wizNormQQGrouped = 0
        wizNormQQN = 1
        wizNormQQCol$ [1] = data_column$
        wizNormQQLastCol = 1
        wizNormQQLastGroup = 1
        wizCanDraw = 1
        wizDrawSource$ = "normality"

        goto WIZ_WHAT_NEXT

        # ── Mode 2: all numeric columns ──────────────────────────────────

        label C_NORM_ALL

        beginPause: "Normality check — All numeric columns"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            comment: "Will test normality for all "
            ... + string$ (wizNormNNumeric) + " numeric columns:"
            for wizNormIcol from 1 to min (wizNormNNumeric, 8)
                comment: "  " + wizNormNumericCol$ [wizNormIcol]
            endfor
            if wizNormNNumeric > 8
                comment: "  ... and "
                ... + string$ (wizNormNNumeric - 8) + " more"
            endif
            comment: ""
            boolean: "Clear Info window", 0
            comment: ""
        clicked = endPause: "Quit", "Back", "Run", 3, 0
        if clicked = 1
            exitScript: ""
        elsif clicked = 2
            goto C_NORMALITY
        endif

        if clear_Info_window
            @emlClearInfo
        endif

        # SAME ORCHESTRATOR, called once per column with "both" so the
        # results accumulate into one export frame -- the same call, with
        # the same third argument, the menu door's own all-columns branch
        # makes (eml-check-normality.praat).
        for wizNormIsel from 1 to wizNormNNumeric
            selectObject: tableId
            @emlRunNormalityAnalysis: tableId,
            ... wizNormNumericCol$ [wizNormIsel], "both"
            if emlRunNormalityAnalysis.error$ <> ""
                appendInfoLine: "NOTE: ", wizNormNumericCol$ [wizNormIsel],
                ... " -- ", emlRunNormalityAnalysis.error$
            endif
        endfor

        wizCanExport = 1

        # Q-Q draw (punch list 4.6) -- every numeric column, no group.
        wizNormQQGrouped = 0
        wizNormQQN = wizNormNNumeric
        for wizNormIsel from 1 to wizNormNNumeric
            wizNormQQCol$ [wizNormIsel] = wizNormNumericCol$ [wizNormIsel]
        endfor
        wizNormQQLastCol = 1
        wizNormQQLastGroup = 1
        wizCanDraw = 1
        wizDrawSource$ = "normality"

        goto WIZ_WHAT_NEXT

        # ── Mode 3: one column, by group ──────────────────────────────────

        label C_NORM_GROUP

        beginPause: "Normality check — Select column and group"
            comment: "📋 Table: " + displayTable$
            comment: "─────────────────────────────────────"
            comment: ""
            optionmenu: "Data column", wizNormDataNumDefault
            for wizNormIcol from 1 to wizNormNNumeric
                option: wizNormNumericCol$ [wizNormIcol]
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
            goto C_NORMALITY
        endif

        # BEFORE the goto below -- v128-style preserve, same idiom every
        # page in this file uses.
        wizNormDataNumDefault = data_column
        @wizardColIdx: group_column$
        groupDefault = wizardColIdx.idx

        if clear_Info_window
            @emlClearInfo
        endif

        wizNormGCol$ = wizNormNumericCol$ [data_column]
        wizNormGGroupCol$ = group_column$

        # SAME PER-GROUP DIAGNOSTIC, same procedures, as the menu door's
        # grouped branch (eml-check-normality.praat) -- copied verbatim
        # (for this one column, where the menu door loops it over every
        # numeric column) so the two doors print the identical reading for
        # the identical data. This branch declares nothing (same as the
        # menu door's own grouped branch); Save is still offered, matching
        # the menu door's panel, which is present regardless of mode.
        appendInfoLine: "══════════════════════════════════════════════"
        appendInfoLine: "  Normality Assessment"
        appendInfoLine: "  Table: ", displayTable$
        wizNormGDisplayGrp$ = replace$ (wizNormGGroupCol$, "_", " ", 0)
        appendInfoLine: "  Grouped by: ", wizNormGDisplayGrp$
        appendInfoLine: "══════════════════════════════════════════════"
        appendInfoLine: ""

        wizNormGDisplayCol$ = replace$ (wizNormGCol$, "_", " ", 0)
        appendInfoLine: "── ", wizNormGDisplayCol$, " ──"
        appendInfoLine: ""
        selectObject: tableId
        @emlCountGroups: tableId, wizNormGGroupCol$
        wizNormGAllOK = 1
        wizNormGNAssessed = 0
        wizNormQQGroupN = emlCountGroups.nGroups
        for wizNormGg from 1 to wizNormQQGroupN
            wizNormQQGroupLabel$ [wizNormGg] = emlCountGroups.groupLabel$ [wizNormGg]
        endfor

        for wizNormGg from 1 to emlCountGroups.nGroups
            wizNormGLabel$ = emlCountGroups.groupLabel$ [wizNormGg]
            wizNormGGDisplay$ = replace$ (wizNormGLabel$, "_", " ", 0)
            selectObject: tableId
            @eml_getGroupData: tableId, wizNormGCol$, wizNormGGroupCol$,
            ... wizNormGLabel$

            if eml_getGroupData.n >= 3
                wizNormGNAssessed = wizNormGNAssessed + 1
                wizNormGData# = eml_getGroupData.data#
                wizNormGN = eml_getGroupData.n

                @emlShapiroWilk: wizNormGData#
                wizNormGSwW = emlShapiroWilk.w
                wizNormGSwP = emlShapiroWilk.p

                @emlSkewness: wizNormGData#
                wizNormGSkew = emlSkewness.result
                @emlKurtosis: wizNormGData#
                wizNormGKurt = emlKurtosis.result

                @emlNormalityRecommendation: wizNormGSkew, wizNormGKurt,
                ... wizNormGN, emlShapiroWilk.p, emlShapiroWilk.error$
                wizNormGLargeNOverride = emlNormalityRecommendation.largeNOverride
                wizNormGRec$ = emlNormalityRecommendation.recommendation$
                wizNormGNonparam = 0
                if wizNormGRec$ = "nonparametric"
                    wizNormGNonparam = 1
                endif

                @eml_fixed: wizNormGSwW, 4
                wizNormGWTxt$ = eml_fixed.result$
                @eml_fixed: wizNormGSkew, 3
                wizNormGSkewTxt$ = eml_fixed.result$
                @eml_fixed: wizNormGKurt, 3
                wizNormGKurtTxt$ = eml_fixed.result$
                @emlFormatP: wizNormGSwP
                appendInfoLine: "  ", wizNormGGDisplay$, " (n = ", wizNormGN, "):"
                appendInfoLine: "    W = ", wizNormGWTxt$,
                ... "  ", emlFormatP.formatted$
                appendInfoLine: "    Skewness = ", wizNormGSkewTxt$,
                ... "  Kurtosis (excess) = ", wizNormGKurtTxt$

                @eml_fixed: emlSkewThreshold, 0
                wizNormGSkewLimit$ = eml_fixed.result$
                @eml_fixed: emlKurtosisThreshold, 0
                wizNormGKurtLimit$ = eml_fixed.result$
                wizNormGCriteria$ = "thresholds: Shapiro-Wilk p < .05, |skew| >= "
                ... + wizNormGSkewLimit$ + ", |excess kurt| >= " + wizNormGKurtLimit$
                if wizNormGLargeNOverride
                    appendInfoLine: "    → Shapiro-Wilk rejects at the 5%"
                    ... + " level; shape statistics are within the"
                    ... + " thresholds at n = " + string$ (wizNormGN)
                    ... + " (" + wizNormGCriteria$ + ")"
                elsif wizNormGNonparam
                    appendInfoLine: "    → Strong departure from normality"
                    ... + " in this group's marginal distribution ("
                    ... + wizNormGCriteria$ + ")"
                    wizNormGAllOK = 0
                else
                    appendInfoLine: "    → No strong departure in this"
                    ... + " group's marginal distribution ("
                    ... + wizNormGCriteria$ + ")"
                endif
            else
                appendInfoLine: "  ", wizNormGGDisplay$, " (n = ",
                ... eml_getGroupData.n, "): skipped (n < 3)"
            endif
        endfor

        appendInfoLine: ""
        if wizNormGAllOK
            if wizNormGNAssessed < emlCountGroups.nGroups
                appendInfoLine: "  Summary: No strong departure in the"
                ... + " groups large enough to test (",
                ... wizNormGNAssessed, " of ", emlCountGroups.nGroups,
                ... " assessed)."
            else
                appendInfoLine: "  Summary: no group in this column shows a"
                ... + " strong departure"
            endif
        else
            appendInfoLine: "  Summary: one or more groups in this column"
            ... + " show a strong departure"
        endif
        appendInfoLine: ""
        appendInfoLine: "══════════════════════════════════════════════"

        wizCanExport = 1

        # Q-Q draw (punch list 4.6) -- one column, by group.
        wizNormQQGrouped = 1
        wizNormQQN = 1
        wizNormQQCol$ [1] = wizNormGCol$
        wizNormQQGroupCol$ = wizNormGGroupCol$
        wizNormQQLastCol = 1
        wizNormQQLastGroup = 1
        wizCanDraw = 1
        wizDrawSource$ = "normality"

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

    # ── candidate grouping columns (punch list 4.5) ────────────────────
    # Same reasoning as B_REG_COLUMNS's own block above: rebuilt every time
    # this label is reached, filtered against the CURRENT col1Default/
    # col2Default so a predictor or outcome bound on the previous pass
    # cannot still be offered as the grouping column.
    wizRegPredName$ = emlTableColumnNames.name$ [col1Default]
    wizRegRespName$ = emlTableColumnNames.name$ [col2Default]
    @wizardRegGrpCandidates: wizRegPredName$, wizRegRespName$
    wizRegGrpSelIdx = 1
    for iG from 1 to wizRegGrpN
        if wizRegGrpName$ [iG] = wizRegGrpSelName$
            wizRegGrpSelIdx = iG + 1
        endif
    endfor

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
        comment: ""
        optionmenu: "Group column", wizRegGrpSelIdx
            option: "(none — overall only)"
        for iCol from 1 to wizRegGrpN
            option: wizRegGrpName$ [iCol]
        endfor
        if wizRegGrpN = 0
            comment: "     (no column in this Table has a usable number"
            comment: "     of groups — overall only)"
        endif
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

    # Leading "(none)" entry: a position in the FILTERED list, not a column
    # index. Preserved BEFORE the error checks below (v128), so neither
    # error's own `goto D_PREDICT_COLUMNS` re-renders the page showing
    # "(none)" instead of what was just chosen.
    wizRegHasGroupCol = 0
    wizRegGroupCol$ = ""
    if group_column > 1
        wizRegHasGroupCol = 1
        wizRegGroupCol$ = wizRegGrpName$ [group_column - 1]
    endif
    wizRegGrpSelName$ = wizRegGroupCol$

    if predictor_column$ = outcome_column$
        # A correctable selection mistake must not end the wizard.
        @emlErrorDialog: "Please select two different columns.", "", "wizard"
        if emlErrorDialog.back
            goto D_PREDICT_COLUMNS
        endif
        exitScript: ""
    elsif wizRegHasGroupCol and (wizRegGroupCol$ = predictor_column$ or wizRegGroupCol$ = outcome_column$)
        # THE STALE GROUP LIST -- see B_REG_COLUMNS's own comment above.
        staleMsg$ = "The grouping column """ + wizRegGroupCol$ + """ is now"
        staleMsg$ = staleMsg$ + " one of the two columns being"
        staleMsg$ = staleMsg$ + " regressed, so it cannot also group"
        staleMsg$ = staleMsg$ + " them. Nothing was run. The list of"
        staleMsg$ = staleMsg$ + " grouping columns was built before you"
        staleMsg$ = staleMsg$ + " changed the predictor or outcome"
        staleMsg$ = staleMsg$ + " column; Back will rebuild it for the"
        staleMsg$ = staleMsg$ + " columns you have now chosen."
        @emlErrorDialog: staleMsg$, "", "wizard"
        wizRegGrpSelName$ = ""
        if emlErrorDialog.back
            goto D_PREDICT_COLUMNS
        endif
        exitScript: ""
    endif

    if clear_Info_window
        @emlClearInfo
    endif

    @wizardReportPlan: "Simple linear regression",
    ... "not assessed (residual normality assumed)",
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

    # Per-group regression (punch list 4.5) -- see B_REG_COLUMNS's own
    # comment above; the precondition is identical.
    if wizRegHasGroupCol
        selectObject: tableId
        @emlRunGroupedRegressionAnalysis: tableId, predictor_column$,
        ... outcome_column$, wizRegGroupCol$
    endif

    corrCol1$ = predictor_column$
    corrCol2$ = outcome_column$
    wizCanDraw = 1
    wizCanExport = 1
    wizDrawSource$ = "regression"
    wizRegDrawGroupCol$ = wizRegGroupCol$

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
    ... "not assessed", "Mixed model (REML, Satterthwaite df)",
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
    # Punch list 4.5: the drawn lines match the report. Without this the
    # scatter would fall back to its own default (overall only), so a
    # grouped regression's Draw button would disagree with the per-group
    # report just printed -- the exact shape the menu door's own Draw
    # dispatch already avoids (eml-regress.praat's "if hasGroupCol").
    if wizRegDrawGroupCol$ <> ""
        emlGraphsPresetGroupCol$ = wizRegDrawGroupCol$
    endif
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
    # Subject / group columns (punch list 4.8): the menu door's paired
    # wrapper (eml-compare-paired.praat) reads the real subject label when
    # one was chosen and adds a "Group" column to the long table when one
    # was chosen; row number and no group were this branch's own invention,
    # wrong whenever the rows are not one per subject in order.
    if wizPairedHasGroupCol
        plLongId = Create Table with column names: tableName$ + "_long",
        ... plNRows * 2, { "Subject", "Condition", "Value", "Group" }
    else
        plLongId = Create Table with column names: tableName$ + "_long",
        ... plNRows * 2, { "Subject", "Condition", "Value" }
    endif
    for plIRow from 1 to plNRows
        selectObject: tableId
        plV1 = Get value: plIRow, wizPairedCol1$
        plV2 = Get value: plIRow, wizPairedCol2$
        if wizPairedHasSubjectCol
            plSubjLabel$ = Get value: plIRow, wizPairedSubjectCol$
        else
            plSubjLabel$ = string$ (plIRow)
        endif
        if wizPairedHasGroupCol
            plGroupLabel$ = Get value: plIRow, wizPairedGroupCol$
        endif
        plR1 = (plIRow - 1) * 2 + 1
        plR2 = (plIRow - 1) * 2 + 2
        selectObject: plLongId
        Set string value: plR1, "Subject", plSubjLabel$
        Set string value: plR1, "Condition", wizPairedCol1$
        Set numeric value: plR1, "Value", plV1
        Set string value: plR2, "Subject", plSubjLabel$
        Set string value: plR2, "Condition", wizPairedCol2$
        Set numeric value: plR2, "Value", plV2
        if wizPairedHasGroupCol
            Set string value: plR1, "Group", plGroupLabel$
            Set string value: plR2, "Group", plGroupLabel$
        endif
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
elsif wizDrawSource$ = "normality"
    # Q-Q draw (punch list 4.6) — NOT through @emlGraphsWorkflow/presets:
    # a Q-Q plot is drawn directly by @emlDrawQQPlot, the same procedure
    # and the same picker the menu door's own Draw branch uses
    # (eml-check-normality.praat), because a normality run may have tested
    # more than one column (mode 2) or one column across groups (mode 3),
    # and there is no single "the" column/group to assume.
    beginPause: "Draw Q-Q plot"
        comment: "📈 A normal Q-Q plot is drawn for one column at a time."
        comment: "─────────────────────────────────────"
        comment: "Points on the line mean the column matches a normal"
        comment: "distribution; systematic curves away from it do not."
        comment: ""
        optionmenu: "Plot column", wizNormQQLastCol
        for wizNormIcol from 1 to wizNormQQN
            option: wizNormQQCol$ [wizNormIcol]
        endfor
        if wizNormQQGrouped
            comment: ""
            comment: "This run tested this column WITHIN a group, so the"
            comment: "plot needs a group too."
            optionmenu: "Plot group", wizNormQQLastGroup
            for wizNormIg from 1 to wizNormQQGroupN
                option: wizNormQQGroupLabel$ [wizNormIg]
            endfor
        endif
    qqClicked = endPause: "Cancel", "Draw plot", 2, 0

    if qqClicked = 2
        wizNormQQLastCol = plot_column
        wizNormQQPlotCol$ = wizNormQQCol$ [plot_column]
        wizNormQQLabel$ = wizNormQQPlotCol$
        wizNormQQReady = 0
        wizNormQQFail$ = ""

        if wizNormQQGrouped
            wizNormQQLastGroup = plot_group
            wizNormQQPlotGroup$ = wizNormQQGroupLabel$ [plot_group]
            wizNormQQLabel$ = wizNormQQPlotCol$ + " — " + wizNormQQPlotGroup$
            selectObject: tableId
            @eml_getGroupData: tableId, wizNormQQPlotCol$,
            ... wizNormQQGroupCol$, wizNormQQPlotGroup$
            if eml_getGroupData.error$ <> ""
                wizNormQQFail$ = eml_getGroupData.error$
            else
                wizNormQQData# = eml_getGroupData.data#
                wizNormQQReady = 1
            endif
        else
            # Every row, undefined cells included: @emlDrawQQPlot drops
            # them itself and counts them onto the figure.
            selectObject: tableId
            wizNormQQNRows = Get number of rows
            wizNormQQData# = zero# (wizNormQQNRows)
            for wizNormIrow from 1 to wizNormQQNRows
                selectObject: tableId
                wizNormQQData# [wizNormIrow] = Get value: wizNormIrow,
                ... wizNormQQPlotCol$
            endfor
            wizNormQQReady = 1
        endif

        # Nested, not ANDed — Praat evaluates both sides of `and`, so a
        # variable defined only on the ready path would abort on the
        # failure path if this were one `if ... and ...`.
        if wizNormQQReady = 1
            @emlDrawQQPlot: wizNormQQData#, wizNormQQLabel$, 6, 4.5, "color", 1
            if emlDrawQQPlot.drew = 0
                wizNormQQFail$ = emlDrawQQPlot.error$
            else
                appendInfoLine: ""
                appendInfoLine: "Q-Q plot drawn: ", wizNormQQLabel$,
                ... "  (n = ", emlDrawQQPlot.n, ")"
                if emlDrawQQPlot.nDropped > 0
                    appendInfoLine: "  ", emlDrawQQPlot.nDropped,
                    ... " row(s) excluded as missing."
                endif

                ; RECORD WORKFLOW. Same hook as the standalone Check
                ; normality wrapper's own Q-Q call (scripts/eml-check-
                ; normality.praat) -- see that site for the full reasoning
                ; on why this lives here rather than inside @emlDrawQQPlot,
                ; why only the success branch records, and why .code$
                ; rebuilds .data# rather than naming `data`.
                if variableExists ("emlRecordLoaded")
                    if wizNormQQGrouped
                        .wizQqCode$ = "@eml_getGroupData: data, """
                        ... + wizNormQQPlotCol$ + """, """
                        ... + wizNormQQGroupCol$ + """, """
                        ... + wizNormQQPlotGroup$ + """" + newline$
                        ... + "data# = eml_getGroupData.data#"
                    else
                        .wizQqCode$ = "data# = zero# (Get number of rows)"
                        ... + newline$ + "for iRow from 1 to size (data#)"
                        ... + newline$ + "    data# [iRow] = Get value: iRow, """
                        ... + wizNormQQPlotCol$ + """" + newline$ + "endfor"
                    endif
                    .wizQqCode$ = .wizQqCode$ + newline$
                    ... + "@emlDrawQQPlot: data#, """ + wizNormQQLabel$
                    ... + """, 6, 4.5, ""color"", 1"
                    @emlRecordDrawStep: tableId, "Normal Q-Q plot",
                    ... wizNormQQLabel$,
                    ... "Points on the line mean the column matches a normal distribution; a systematic curve away from it does not.",
                    ... .wizQqCode$,
                    ... "In the GUI: the wizard's normality check, then Draw Q-Q plot for a tested column",
                    ... ""
                endif
            endif
        endif

        if wizNormQQFail$ <> ""
            beginPause: "Cannot draw this Q-Q plot"
                comment: "⚠  No figure was drawn."
                comment: "─────────────────────────────────────"
                @emlWrapText: wizNormQQFail$, 62
                for wizNormIwrap from 1 to emlWrapText.nLines
                    comment: emlWrapText.line$ [wizNormIwrap]
                endfor
                comment: "─────────────────────────────────────"
                comment: ""
                comment: "Column: " + replace$ (wizNormQQLabel$, "_", " ", 0)
                comment: "The results already in the Info window are"
                comment: "unaffected. Choose another column and try again."
            wizNormQQDismissed = endPause: "OK", 1, 0
        endif

        selectObject: tableId
    endif
endif

goto WIZ_WHAT_NEXT

label WIZ_LOOP_END

endwhile


# ###########################################################################
# PROCEDURES
# ###########################################################################


# ============================================================================
# THE TWO-GROUP TEST MENU — one control, no expressible mismatch
# ============================================================================
# Collapses "Test approach" (Parametric / Nonparametric) and "Variance
# assumption" (Welch / Pooled) into one list. Variance assumption was drawn
# and read on every pass of the old page, but @emlRunTwoGroupAnalysis never
# consulted it once Test approach chose Nonparametric — the same hazard THE
# COMPARISON MENU in graphs/eml-graphs-form.praat names: a sibling control on
# a static page cannot react to the choice beside it, so the two can only
# ever agree by luck. One row per honest choice removes the possibility
# rather than guarding it; see docs/RULING_DEAD_CONTROLS.md #3.
#
# HEADERS ARE ROWS, AND THE GUARD IS THE ONE THE GRAPH-TYPE MENU USES.
# graphs/eml-graphs-form.praat marks a header with 0 in a parallel array and
# re-shows the page when the remap lands there; its own Comparison list
# reuses the identical idea. This file already returns to a page by `goto`
# rather than a repeat loop, so the re-show below does the same: a small
# dialog, then `goto` back to this page's own label.
# ----------------------------------------------------------------------------
# @emlWizard2GroupTestRows
# Emits the option rows. Called INSIDE the "Test" optionmenu, immediately
# after the field line.
# ----------------------------------------------------------------------------
procedure emlWizard2GroupTestRows
    option: "-- Parametric --"
    option: "Welch t (unequal variances; default)"
    option: "Student t (pooled variances)"
    option: "-- Nonparametric --"
    option: "Mann-Whitney U"
    option: "-- Both --"
    option: "Welch t and Mann-Whitney U"
endproc

# ----------------------------------------------------------------------------
# @emlWizard2GroupTestFromMenu: .row
# Outputs: .isHeader     (1 = a category header, not a choice)
#          .testApproach (1 = parametric, 2 = nonparametric, 3 = both — the
#                         dispatch passes "both" straight to
#                         @emlRunTwoGroupAnalysis, the way the menu door's
#                         "Both parametric and nonparametric" row does)
#          .varAssume    (1 = Welch/unequal, 2 = pooled/Student — the same
#                         1/2 encoding the old "Variance assumption" menu
#                         used, so prevVarAssume needs no reshaping)
#          .reportName$  (the exact string @wizardReportPlan prints for this
#                         row — the ONE source, so the report can never name
#                         a test other than the one the row describes)
# ----------------------------------------------------------------------------
procedure emlWizard2GroupTestFromMenu: .row
    .isHeader = 0
    .testApproach = 1
    .varAssume = 1
    .reportName$ = "Welch t-test, unequal variances (Cohen's d)"
    if .row = 1 or .row = 4 or .row = 6
        .isHeader = 1
    elsif .row = 3
        .varAssume = 2
        .reportName$ = "Student t-test, pooled variance (Cohen's d)"
    elsif .row = 5
        .testApproach = 2
        .reportName$ = "Mann-Whitney U (rank-biserial r)"
    elsif .row = 7
        .testApproach = 3
        .reportName$ = "Welch t and Mann-Whitney U"
    endif
endproc

# ----------------------------------------------------------------------------
# @emlWizard2GroupTestToMenu: .testApproach, .varAssume
# The inverse, for seeding the menu from the normality recommendation (or
# from a returning user's own answer). Never returns a header row.
# ----------------------------------------------------------------------------
procedure emlWizard2GroupTestToMenu: .testApproach, .varAssume
    .row = 2
    if .testApproach = 2
        .row = 5
    elsif .varAssume = 2
        .row = 3
    endif
endproc


# ============================================================================
# THE PAIRED TEST MENU — same one-list collapse, language batch item 2
# ============================================================================
# "Test approach" (Parametric / Nonparametric), two plain rows with no header
# and no Both, collapsed into one list with the header-guard idiom the
# two-group menu above already carries.
# ----------------------------------------------------------------------------
# @emlWizardPairedTestRows
# ----------------------------------------------------------------------------
procedure emlWizardPairedTestRows
    option: "-- Parametric --"
    option: "Paired t-test"
    option: "-- Nonparametric --"
    option: "Wilcoxon signed-rank"
    option: "-- Both --"
    option: "Paired t-test and Wilcoxon signed-rank"
endproc

# ----------------------------------------------------------------------------
# @emlWizardPairedTestFromMenu: .row
# Outputs: .isHeader, .testApproach (1 = parametric, 2 = nonparametric,
#          3 = both), .reportName$
# ----------------------------------------------------------------------------
procedure emlWizardPairedTestFromMenu: .row
    .isHeader = 0
    .testApproach = 1
    .reportName$ = "Paired t-test (Cohen's d)"
    if .row = 1 or .row = 3 or .row = 5
        .isHeader = 1
    elsif .row = 4
        .testApproach = 2
        .reportName$ = "Wilcoxon signed-rank (r)"
    elsif .row = 6
        .testApproach = 3
        .reportName$ = "Paired t-test and Wilcoxon signed-rank"
    endif
endproc

# ----------------------------------------------------------------------------
# @emlWizardPairedTestToMenu: .testApproach
# ----------------------------------------------------------------------------
procedure emlWizardPairedTestToMenu: .testApproach
    .row = 2
    if .testApproach = 2
        .row = 4
    endif
endproc


# ============================================================================
# THE THREE-OR-MORE-GROUP TEST MENU — grid unfrozen, punch list 4.2 / 4.3
# ============================================================================
# The three-row-per-family collapse (Tukey / Scheffe / pairwise-Welch-BH,
# Dunn-Holm / Dunn-Bonferroni / Dunn-BH) is replaced by the SAME complete
# choices the standalone pairwise dialog offers (eml-pairwise.praat: test x
# adjustment x t-variant), plus the two "only, no pairwise tests" rows the
# old grid never had (the ANOVA's and the Kruskal-Wallis's own "alone" row,
# language batch item 4). One list, header-guard idiom, same shape as the
# two-group and paired menus above.
#
# 4.3 CORRECTION: the first wording of 4.3 said "parametric post-hoc rows"
# and the grid above shipped without the standalone dialog's rank-based
# cells — pairwise Wilcoxon with Holm/Bonferroni/Benjamini-Hochberg. Dunn is
# not a substitute: Dunn compares groups on the shared ranking from the
# overall Kruskal-Wallis test, while pairwise Wilcoxon re-ranks each pair on
# its own — a different engine call, not a relabelling of Dunn. The three
# rows below close that gap; the grid is now the WHOLE standalone dialog.
# ----------------------------------------------------------------------------
# @emlWizard3GroupTestRows
# ----------------------------------------------------------------------------
procedure emlWizard3GroupTestRows
    option: "-- Parametric (one-way ANOVA) --"
    ; NO ROW HERE CARRIES A GATING CLAUSE: no post-hoc is conditioned on the
    ; ANOVA p (punch list lane 3.1/3.2), and the omnibus-only row is a row
    ; the user can choose rather than a hardcoded doTukey/doDunn (4.2). Every
    ; string below is language batch item 4, verbatim.
    option: "ANOVA only, no pairwise tests"
    option: "Tukey HSD, all pairs (standard)"
    option: "Scheffe, all pairs (conservative)"
    option: "Pairwise Welch t, Holm (standard)"
    option: "Pairwise Welch t, Bonferroni (conservative)"
    option: "Pairwise Welch t, Benjamini-Hochberg (less strict)"
    option: "Pairwise Student t, Holm (standard)"
    option: "Pairwise Student t, Bonferroni (conservative)"
    option: "Pairwise Student t, Benjamini-Hochberg (less strict)"
    option: "-- Nonparametric (Kruskal-Wallis) --"
    option: "Kruskal-Wallis only, no pairwise tests"
    option: "Dunn, Holm (standard)"
    option: "Dunn, Bonferroni (conservative)"
    option: "Dunn, Benjamini-Hochberg (less strict)"
    ; PUNCH LIST 4.3 — the three rows the first wording of this item left
    ; out. Dunn is not a substitute for these: Dunn compares groups on the
    ; shared ranking from the overall test, while pairwise Wilcoxon re-ranks
    ; each pair on its own. Decoded like the twelve rows above, into the
    ; SAME @emlRunPairwiseAnalysis call the standalone pairwise dialog makes
    ; (test$ = "wilcoxon"), not a parallel path.
    option: "Pairwise Wilcoxon, Holm (standard)"
    option: "Pairwise Wilcoxon, Bonferroni (conservative)"
    option: "Pairwise Wilcoxon, Benjamini-Hochberg (less strict)"
endproc

# ----------------------------------------------------------------------------
# @emlWizard3GroupTestFromMenu: .row
# Outputs: .isHeader
#          .testApproach (1 = parametric/ANOVA, 2 = nonparametric/KW)
#          .phTest$ ("" = no pairwise tests; else "tukey", "scheffe",
#                    "welch", "student" under ANOVA, or "dunn"/"wilcoxon"
#                    under KW — "tukey" and "dunn" are the wizard's own
#                    decode, "welch"/"student"/"scheffe"/"wilcoxon" go
#                    straight into @emlRunPairwiseAnalysis's .test$, unchanged)
#          .phAdj$  (the adjustment for the row's pairwise test — "none" for
#                    Scheffe, else "holm"/"bonferroni"/"bh", the SAME
#                    .adjMethod$ vocabulary @emlRunPairwiseAnalysis and
#                    @emlRunKruskalWallisAnalysis already take)
#          .phLabel$ (the exact string @wizardReportPlan prints for this
#                    row's post-hoc — the ONE source, so the plan can never
#                    name a post-hoc other than the one the row describes)
# ----------------------------------------------------------------------------
procedure emlWizard3GroupTestFromMenu: .row
    .isHeader = 0
    .testApproach = 1
    .phTest$ = ""
    .phAdj$ = ""
    .phLabel$ = "ANOVA only, no pairwise tests"
    if .row = 1 or .row = 11
        .isHeader = 1
    elsif .row = 3
        .phTest$ = "tukey"
        .phLabel$ = "Tukey HSD, all pairs"
    elsif .row = 4
        .phTest$ = "scheffe"
        .phAdj$ = "none"
        .phLabel$ = "Scheffe, all pairs"
    elsif .row = 5
        .phTest$ = "welch"
        .phAdj$ = "holm"
        .phLabel$ = "Pairwise Welch t, Holm"
    elsif .row = 6
        .phTest$ = "welch"
        .phAdj$ = "bonferroni"
        .phLabel$ = "Pairwise Welch t, Bonferroni"
    elsif .row = 7
        .phTest$ = "welch"
        .phAdj$ = "bh"
        .phLabel$ = "Pairwise Welch t, Benjamini-Hochberg"
    elsif .row = 8
        .phTest$ = "student"
        .phAdj$ = "holm"
        .phLabel$ = "Pairwise Student t, Holm"
    elsif .row = 9
        .phTest$ = "student"
        .phAdj$ = "bonferroni"
        .phLabel$ = "Pairwise Student t, Bonferroni"
    elsif .row = 10
        .phTest$ = "student"
        .phAdj$ = "bh"
        .phLabel$ = "Pairwise Student t, Benjamini-Hochberg"
    elsif .row = 12
        .testApproach = 2
        .phLabel$ = "Kruskal-Wallis only, no pairwise tests"
    elsif .row = 13
        .testApproach = 2
        .phTest$ = "dunn"
        .phAdj$ = "holm"
        .phLabel$ = "Dunn, Holm"
    elsif .row = 14
        .testApproach = 2
        .phTest$ = "dunn"
        .phAdj$ = "bonferroni"
        .phLabel$ = "Dunn, Bonferroni"
    elsif .row = 15
        .testApproach = 2
        .phTest$ = "dunn"
        .phAdj$ = "bh"
        .phLabel$ = "Dunn, Benjamini-Hochberg"
    elsif .row = 16
        .testApproach = 2
        .phTest$ = "wilcoxon"
        .phAdj$ = "holm"
        .phLabel$ = "Pairwise Wilcoxon, Holm"
    elsif .row = 17
        .testApproach = 2
        .phTest$ = "wilcoxon"
        .phAdj$ = "bonferroni"
        .phLabel$ = "Pairwise Wilcoxon, Bonferroni"
    elsif .row = 18
        .testApproach = 2
        .phTest$ = "wilcoxon"
        .phAdj$ = "bh"
        .phLabel$ = "Pairwise Wilcoxon, Benjamini-Hochberg"
    else
        .testApproach = 2
        .phLabel$ = "Kruskal-Wallis only, no pairwise tests"
    endif
endproc

# ----------------------------------------------------------------------------
# @emlWizard3GroupTestToMenu: .testApproach
# The inverse, for seeding the menu from the normality recommendation. Seeds
# to the standard row in each family — Tukey under parametric, Dunn-Holm
# under nonparametric — the same defaults the old three-row grid seeded to.
# Never returns a header row.
# ----------------------------------------------------------------------------
procedure emlWizard3GroupTestToMenu: .testApproach
    .row = 3
    if .testApproach = 2
        .row = 13
    endif
endproc


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
    .nGroupsIncomplete = 0

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
            # COVERAGE. A group too small to test (n < 3) is skipped below
            # and never examined. .nAssessed and .skipList$ let the summary
            # and recommendation say so, instead of speaking for a group
            # this run never looked at. Language batch item 13, verbatim.
            .nAssessed = 0
            .nGroupsIncomplete = 0
            .skipList$ = ""
            for .g from 1 to emlCountGroups.nGroups
                @eml_getGroupData: .tableId, .col1$, .col2$,
                ... emlCountGroups.groupLabel$[.g]
                if eml_getGroupData.n >= 3
                    .nAssessed = .nAssessed + 1
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
                    .nGroupsIncomplete = 1
                    if .skipList$ <> ""
                        .skipList$ = .skipList$ + ", "
                    endif
                    .skipList$ = .skipList$
                    ... + emlCountGroups.groupLabel$[.g]
                    ... + " (n = " + string$ (eml_getGroupData.n)
                    ... + ") too small to test (needs 3)"
                endif
            endfor
            if .nGroupsIncomplete
                appendInfoLine: "  Assessed ", .nAssessed, " of ",
                ... emlCountGroups.nGroups, " groups; ", .skipList$, "."
                appendInfoLine: ""
            endif
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
        if .mode$ = "group" and .nGroupsIncomplete
            # Coverage was incomplete: the recommendation says so rather
            # than generalising over a group it never tested. Language
            # batch item 13, verbatim.
            appendInfoLine: "  Recommendation: parametric test is "
            ... + "reasonable, based on the groups large enough to test."
        else
            appendInfoLine: "  Recommendation: parametric test is "
            ... + "reasonable"
        endif
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
# @wizardCorrGrpIdx — Correlation group-column NAME back to its FILTERED
#                      optionmenu POSITION
# ============================================================================
# Same shape as @wizardCondSlot above — a "(none)" leading entry over a
# candidate list built at runtime rather than the full column list — but for
# the correlation group column (punch list 4.4), whose candidates
# (wizCorrGrpName$ / wizCorrGrpN) are a filtered subset of the columns, not
# @wizardCondSlot's a3k condition slots. Reads wizCorrGrpName$/wizCorrGrpN
# rather than taking them as arguments, exactly as @wizardCondSlot reads
# a3kName$/a3kN — this page has exactly one such menu, so one hard-wired
# reader is the same choice A3K_SELECT_PAGE already made for its six.
#
# Arguments:
#   .name$ - a group column name as saved from group_column (empty string
#            for "no group"), or a name absent from @wizCorrGrpName$'s
#            current list (the columns re-filter every time B_NORM_PAGE
#            recomputes them, so a column swap can drop a saved name)
#
# Output:
#   .idx   - position in the "(none) + candidates" list; 1 (none) when
#            .name$ is "" or is absent from the current candidates

procedure wizardCorrGrpIdx: .name$
    .idx = 1
    for .i from 1 to wizCorrGrpN
        if wizCorrGrpName$ [.i] = .name$
            .idx = .i + 1
        endif
    endfor
endproc


# ============================================================================
# @wizardRegGrpCandidates / @wizardRegGrpIdx -- regression group column
# (punch list 4.5), shared by both wizard regression entry points
# ============================================================================
# Same filter as the correlate dialog's own candidate scan (v102's hazard,
# and @wizardCorrGrpIdx's sibling above): a grouping column has to be able
# to grade the regression, which rules out the predictor and response
# columns themselves, single-valued columns, and near-unique columns. Ceiling
# is 12 levels or n/3, whichever is smaller.
#
# ONE procedure for BOTH wizard regression pages (B_REG_COLUMNS and
# D_PREDICT_COLUMNS) rather than two independent copies -- the DRY law in
# CLAUDE.md ("state the canon once in a procedure"). Sets the UNDOTTED
# globals wizRegGrpName$[] / wizRegGrpN, the same idiom @wizardCorrGrpIdx's
# sibling reads.
#
# Arguments:
#   .predCol$, .respCol$ -- the CURRENT predictor/response names (translated
#                           from col1Default/col2Default by the caller), so
#                           calling this fresh every time either page renders
#                           cannot offer a column that is now bound to X or Y.
procedure wizardRegGrpCandidates: .predCol$, .respCol$
    selectObject: tableId
    .nRows = Get number of rows
    .maxLevels = min (12, max (2, floor (.nRows / 3)))
    wizRegGrpN = 0
    for .iCol from 1 to nCols
        .cand$ = emlTableColumnNames.name$ [.iCol]
        if .cand$ <> .predCol$ and .cand$ <> .respCol$
            .levels = 0
            .over = 0
            for .iRow from 1 to .nRows
                if .over = 0
                    selectObject: tableId
                    .cell$ = Get value: .iRow, .cand$
                    @eml_normalizeLabel: .cell$
                    .norm$ = eml_normalizeLabel.result$
                    .seen = 0
                    for .iLev from 1 to .levels
                        if .level$ [.iLev] = .norm$
                            .seen = 1
                        endif
                    endfor
                    if .seen = 0
                        .levels = .levels + 1
                        .level$ [.levels] = .norm$
                        if .levels > .maxLevels
                            .over = 1
                        endif
                    endif
                endif
            endfor
            if .over = 0 and .levels >= 2
                wizRegGrpN = wizRegGrpN + 1
                wizRegGrpName$ [wizRegGrpN] = .cand$
            endif
        endif
    endfor
endproc

procedure wizardRegGrpIdx: .name$
    .idx = 1
    for .i from 1 to wizRegGrpN
        if wizRegGrpName$ [.i] = .name$
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
    appendInfoLine: "  in the EML Stats & Graphs menu for available analyses."
    appendInfoLine: ""
endproc
