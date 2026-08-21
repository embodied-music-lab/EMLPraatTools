# ============================================================================
# EML Stats & Graphs — Demo tables: the seven generators, callable
# ============================================================================
# Purpose: build one synthetic voice-science Table per wizard analysis path,
#          from a seed, with no dialog. scripts/eml-create-demo.praat is the
#          dialog in front of this; a recorded script calls it directly.
#
# Date: 21 August 2026
# Version: 1.0
#
# WHY THE BUILDER IS A LIBRARY PROCEDURE AND NOT THE WRAPPER'S BODY.
#
# A recorded workflow that ran on a demo table has to be able to REBUILD that
# table, or the script it emits opens with "this object must already be open"
# and cannot say where the data came from. The rebuild cannot be a call to the
# wrapper. MEASURED on Praat 6.6.30, 21 August 2026: a script whose dialog is
# `beginPause:` refuses arguments —
#
#     runScript: "child.praat", 5
#     Error: Found 1 arguments but expected only 0.
#
# — so `runScript:` on scripts/eml-create-demo.praat can only put the dialog
# back in front of whoever replays the file, which is exactly what a replayed
# recording must not do (see @emlRecordReplaySave for the same rule and the
# same reason). One procedure, called by the dialog and by the emitted script,
# is the only arrangement in which the two cannot drift apart.
#
# THE SEED IS AN ARGUMENT, AND IT IS WHAT MAKES A REPLAY A REPLAY.
#
# Every branch below draws from randomGauss or randomUniform, so the same
# call twice is two different tables. MEASURED, same session:
#
#     random_initializeWithSeedUnsafelyButPredictably (20260821)
#         randomGauss (120, 15)  ->  106.913163, then 101.683546
#     the same seed again        ->  106.913163, then 101.683546
#     seed 7                     ->  105.411557
#
# so a recorded seed reproduces the recorded table exactly, and a recorded
# call without one reproduces only its shape. The caller mints the seed and
# the recorder writes it into the emitted script; this procedure applies it
# and does not choose it, because the value has to be the one that was
# recorded rather than one this file picks each time it runs.
#
# WHAT A SEED DOES NOT SURVIVE. It reproduces the table only against the same
# generator: change a mean or add a column below and the same seed builds a
# different table. That is a property of seeding and not of this file, and it
# is why the emitted script names the seed in a comment a reader can see
# rather than burying it.
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


# ----------------------------------------------------------------------------
# @emlDemoTable: .demoType, .seed
# Build demo table number .demoType, seeded with .seed.
#
# .demoType is the position in the wrapper's option menu, 1 to 7, and the
# numbering is the wrapper's: a recorded script carries the number the user
# chose, so renumbering the menu renumbers every recording ever made from it.
#
# .seed is applied before the first draw and is never chosen here. Pass the
# seed the recording carries to rebuild the recorded table; pass a fresh one
# for fresh data.
#
# Outputs: .tableId       the new Table, left selected
#          .name$         its full "Table <name>", for the recorder
#          .description$  the wrapper's on-screen guide to the table
# ----------------------------------------------------------------------------
procedure emlDemoTable: .demoType, .seed
    ; THE SEED FIRST, BEFORE ANY BRANCH DRAWS. Applied unconditionally: type 6
    ; is the only branch whose structure is fixed, and even it adds Gaussian
    ; noise to every cell, so there is no demo table this does not govern.
    random_initializeWithSeedUnsafelyButPredictably (.seed)

    .tableId = 0
    .description$ = ""

    # ============================================================================
    # 1. Two independent groups: patients vs controls
    # ============================================================================

    if .demoType = 1
        .tableId = Create Table with column names: "demo_2groups", 40,
            ... "subject group F0_Hz jitter_pct"
        for .i from 1 to 20
            Set string value: .i, "subject", "S" + string$ (.i)
            Set string value: .i, "group", "Control"
            Set numeric value: .i, "F0_Hz", randomGauss (120, 15)
            Set numeric value: .i, "jitter_pct",
                ... max (0.1, randomGauss (0.8, 0.3))
        endfor
        for .i from 21 to 40
            Set string value: .i, "subject", "S" + string$ (.i)
            Set string value: .i, "group", "Patient"
            Set numeric value: .i, "F0_Hz", randomGauss (140, 25)
            Set numeric value: .i, "jitter_pct",
                ... max (0.1, randomGauss (2.1, 0.8))
        endfor
        .description$ = "Two-group comparison (Control vs Patient)."
            ... + newline$ + "  Data column: jitter_pct or F0_Hz"
            ... + newline$ + "  Group column: group"
            ... + newline$ + "  Note: both measures carry a real built-in"
            ... + newline$ + "        difference — Patients average 2.1% jitter"
            ... + newline$ + "        against 0.8%, and 140 Hz against 120 Hz."
            ... + newline$ + "  Try: Stats Wizard → Compare groups or conditions"
            ... + newline$ + "       → No — different groups (independent)"
            ... + newline$ + "       → Two groups"
            ... + newline$ + "  Or go straight there: New → EML Stats & Graphs →"
            ... + newline$ + "       Compare two groups..."

    # ============================================================================
    # 2. Three independent groups: soprano / mezzo / alto
    # ============================================================================

    elsif .demoType = 2
        .tableId = Create Table with column names: "demo_3groups", 45,
            ... "singer voice_type SPL_dB vibrato_rate_Hz"
        for .i from 1 to 15
            Set string value: .i, "singer", "Singer_" + string$ (.i)
            Set string value: .i, "voice_type", "Soprano"
            Set numeric value: .i, "SPL_dB", randomGauss (92, 4)
            Set numeric value: .i, "vibrato_rate_Hz",
                ... max (3, randomGauss (5.8, 0.6))
        endfor
        for .i from 16 to 30
            Set string value: .i, "singer", "Singer_" + string$ (.i)
            Set string value: .i, "voice_type", "Mezzo"
            Set numeric value: .i, "SPL_dB", randomGauss (88, 5)
            Set numeric value: .i, "vibrato_rate_Hz",
                ... max (3, randomGauss (5.5, 0.7))
        endfor
        for .i from 31 to 45
            Set string value: .i, "singer", "Singer_" + string$ (.i)
            Set string value: .i, "voice_type", "Alto"
            Set numeric value: .i, "SPL_dB", randomGauss (85, 4)
            Set numeric value: .i, "vibrato_rate_Hz",
                ... max (3, randomGauss (5.2, 0.5))
        endfor
        .description$ = "Three-group comparison (Soprano / Mezzo / Alto)."
            ... + newline$ + "  Data column: SPL_dB or vibrato_rate_Hz"
            ... + newline$ + "  Group column: voice_type"
            ... + newline$ + "  Note: both measures decline across the three"
            ... + newline$ + "        voice types — SPL_dB at 92 / 88 / 85 dB,"
            ... + newline$ + "        vibrato_rate_Hz at 5.8 / 5.5 / 5.2 Hz."
            ... + newline$ + "        The SPL gap is the larger of the two."
            ... + newline$ + "  Try: Stats Wizard → Compare groups or conditions"
            ... + newline$ + "       → No — different groups (independent)"
            ... + newline$ + "       → Three or more groups"
            ... + newline$ + "  Or go straight there: New → EML Stats & Graphs →"
            ... + newline$ + "       Compare k groups (ANOVA)... or"
            ... + newline$ + "       Compare k groups (Kruskal-Wallis)..."

    # ============================================================================
    # 3. Paired: same subjects measured pre and post therapy
    # ============================================================================

    elsif .demoType = 3
        .tableId = Create Table with column names: "demo_paired", 20,
            ... "subject jitter_pre jitter_post HNR_pre HNR_post"
        for .i from 1 to 20
            Set string value: .i, "subject", "P" + string$ (.i)
            .preJitter = max (0.1, randomGauss (2.5, 0.8))
            Set numeric value: .i, "jitter_pre", .preJitter
            Set numeric value: .i, "jitter_post",
                ... max (0.1, .preJitter - randomGauss (0.8, 0.4))
            .preHNR = randomGauss (18, 4)
            Set numeric value: .i, "HNR_pre", .preHNR
            Set numeric value: .i, "HNR_post", .preHNR + randomGauss (3, 1.5)
        endfor
        .description$ = "Paired pre/post therapy comparison."
            ... + newline$ + "  Column 1: jitter_pre (or HNR_pre)"
            ... + newline$ + "  Column 2: jitter_post (or HNR_post)"
            ... + newline$ + "  Note: therapy is built in — jitter drops by"
            ... + newline$ + "        about 0.8% and HNR rises by about 3 dB"
            ... + newline$ + "        for every subject, so both tests should"
            ... + newline$ + "        come out significant."
            ... + newline$ + "  Try: Stats Wizard → Compare groups or conditions"
            ... + newline$ + "       → Yes — same people, measured more"
            ... + newline$ + "         than once (within-subject)"
            ... + newline$ + "       → Two (paired t-test / Wilcoxon)"
            ... + newline$ + "  Or go straight there: New → EML Stats & Graphs →"
            ... + newline$ + "       Compare paired..."

    # ============================================================================
    # 4. Correlation: speaking F0 vs singing F0
    # ============================================================================

    elsif .demoType = 4
        .tableId = Create Table with column names: "demo_correlation", 30,
            ... "speaker speaking_F0_Hz singing_F0_Hz age_years"
        for .i from 1 to 30
            Set string value: .i, "speaker", "Spk" + string$ (.i)
            .speakF0 = max (80, randomGauss (160, 40))
            Set numeric value: .i, "speaking_F0_Hz", .speakF0
            Set numeric value: .i, "singing_F0_Hz",
                ... max (150, .speakF0 * 2.1 + randomGauss (0, 30))
            Set numeric value: .i, "age_years",
                ... round (randomUniform (22, 65))
        endfor
        .description$ = "Bivariate relationship (speaking F0 vs singing F0)."
            ... + newline$ + "  Column X: speaking_F0_Hz"
            ... + newline$ + "  Column Y: singing_F0_Hz"
            ... + newline$ + "  Note: singing F0 is built as 2.1 × speaking F0"
            ... + newline$ + "        plus noise, so expect a strong positive r."
            ... + newline$ + "        age_years is drawn independently and should"
            ... + newline$ + "        show no relationship — a useful contrast."
            ... + newline$ + "  Try: Stats Wizard → Examine a relationship"
            ... + newline$ + "       → Correlation (both continuous)"
            ... + newline$ + "  Or go straight there: New → EML Stats & Graphs →"
            ... + newline$ + "       Correlate two columns..."

    # ============================================================================
    # 5. Regression: practice hours predicting vibrato .regularity
    # ============================================================================

    elsif .demoType = 5
        .tableId = Create Table with column names: "demo_regression", 25,
            ... "singer practice_hrs_wk vibrato_regularity_pct experience_yrs"
        for .i from 1 to 25
            Set string value: .i, "singer", "S" + string$ (.i)
            .practiceHrs = max (1, randomGauss (12, 5))
            Set numeric value: .i, "practice_hrs_wk", .practiceHrs
            # Clear linear relationship: more practice → more regular vibrato
            .regularity = 40 + 3.2 * .practiceHrs + randomGauss (0, 8)
            Set numeric value: .i, "vibrato_regularity_pct",
                ... min (100, max (10, .regularity))
            # Covariate: correlated with practice but adds independent info
            Set numeric value: .i, "experience_yrs",
                ... max (1, round (.practiceHrs * 0.8 + randomGauss (0, 3)))
        endfor
        .description$ = "Predictor → outcome relationship."
            ... + newline$ + "  Predictor (X): practice_hrs_wk"
            ... + newline$ + "  Response (Y): vibrato_regularity_pct"
            ... + newline$ + "  Note: the generator uses .regularity = 40 +"
            ... + newline$ + "        3.2 × practice + noise, so the fitted slope"
            ... + newline$ + "        should land near 3.2 and the intercept near"
            ... + newline$ + "        40. Values are clipped at 100%, which flattens"
            ... + newline$ + "        the slope a little at the top of the range."
            ... + newline$ + "  Try: Stats Wizard → Predict an outcome"
            ... + newline$ + "       (or Examine a relationship → Regression)"
            ... + newline$ + "  Or go straight there: New → EML Stats & Graphs →"
            ... + newline$ + "       Linear regression..."

    # ============================================================================
    # 6. Two-way ANOVA: voice type × task
    # ============================================================================

    elsif .demoType = 6
        .tableId = Create Table with column names: "demo_twoway", 48,
            ... "subject voice_type task SPL_dB"
        .row = 0
        for .iVoice from 1 to 2
            if .iVoice = 1
                .voiceType$ = "Soprano"
                .baseSPL = 90
            else
                .voiceType$ = "Alto"
                .baseSPL = 85
            endif
            for .iTask from 1 to 2
                if .iTask = 1
                    .task$ = "Speech"
                    .taskEffect = 0
                else
                    .task$ = "Singing"
                    .taskEffect = 8
                endif
                for .iSubj from 1 to 12
                    .row = .row + 1
                    Set string value: .row, "subject",
                        ... .voiceType$ + "_" + string$ (.iSubj)
                    Set string value: .row, "voice_type", .voiceType$
                    Set string value: .row, "task", .task$
                    # Main effects + .interaction: sopranos gain more SPL in singing
                    .interaction = 0
                    if .iVoice = 1 and .iTask = 2
                        .interaction = 3
                    endif
                    Set numeric value: .row, "SPL_dB",
                        ... .baseSPL + .taskEffect + .interaction
                        ... + randomGauss (0, 3)
                endfor
            endfor
        endfor
        .description$ = "Two-factor design (voice_type × task)."
            ... + newline$ + "  Data column: SPL_dB"
            ... + newline$ + "  Factor 1: voice_type"
            ... + newline$ + "  Factor 2: task"
            ... + newline$ + "  Note: contains two main effects (singing +8 dB,"
            ... + newline$ + "        Soprano +5 dB) and an .interaction —"
            ... + newline$ + "        Sopranos gain a further 3 dB when singing."
            ... + newline$ + "  Try: Stats Wizard → Compare groups or conditions"
            ... + newline$ + "       → No — different groups (independent)"
            ... + newline$ + "       → Two-factor design (two grouping variables)"
            ... + newline$ + "  Or go straight there: New → EML Stats & Graphs →"
            ... + newline$ + "       Compare two-way (ANOVA)..."

    # ============================================================================
    # 7. Normality check: normal vs skewed columns
    # ============================================================================

    elsif .demoType = 7
        .tableId = Create Table with column names: "demo_normality", 40,
            ... "subject F0_Hz shimmer_pct jitter_pct"
        for .i from 1 to 40
            Set string value: .i, "subject", "S" + string$ (.i)
            # F0: approximately normal
            Set numeric value: .i, "F0_Hz", randomGauss (180, 30)
            # Shimmer: right-skewed (lognormal-ish)
            # exp(randomGauss) produces lognormal distribution
            Set numeric value: .i, "shimmer_pct",
                ... exp (randomGauss (0.7, 0.5))
            # Jitter: mildly skewed (Gaussian with floor)
            Set numeric value: .i, "jitter_pct",
                ... max (0.05, randomGauss (1.2, 0.6))
        endfor
        .description$ = "Data with different distributional shapes."
            ... + newline$ + "  F0_Hz: approximately normal"
            ... + newline$ + "  shimmer_pct: right-skewed (try nonparametric)"
            ... + newline$ + "  jitter_pct: mildly skewed"
            ... + newline$ + "  Try: Stats Wizard → Describe or summarize"
            ... + newline$ + "       → Check normality"
            ... + newline$ + "  Or go straight there: New → EML Stats & Graphs →"
            ... + newline$ + "       Check normality (all columns)..."

    endif

    ; A TYPE OUTSIDE THE MENU BUILDS NOTHING AND SAYS SO, rather than falling
    ; through to `selected$ ()` on whatever the caller happened to have
    ; selected and reporting it as a demo table. A recorded script carrying a
    ; number this file does not know is a plugin older or newer than the
    ; recording, which is worth a sentence rather than a wrong object.
    if .tableId = 0
        .name$ = ""
        .description$ = "No demo table of type " + string$ (.demoType)
        ... + ". This plugin builds types 1 to 7."
        goto END_EML_DEMO_TABLE
    endif

    selectObject: .tableId
    .name$ = selected$ ()

    label END_EML_DEMO_TABLE
endproc
