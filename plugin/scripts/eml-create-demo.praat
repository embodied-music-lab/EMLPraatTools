# ============================================================================
# EML Praat Tools — Create Demo Tables
# ============================================================================
# Purpose: Generate synthetic voice-science Tables for testing EML Tools
#          and tutorials. Creates realistic data with known properties.
#          One demo table per wizard analysis path.
# Date: 11 May 2026
# Version: 2.0
# v2.0: Added regression, two-way ANOVA, and normality demos.
#        All 7 wizard analysis paths now have a matching demo table.
# v1.0: Initial release with 4 demo types.
#
# ATTRIBUTION
# Framework: EML Praat Assistant by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# ============================================================================

beginPause: "Create Demo Table"
    comment: "Select the type of demo data to generate."
    comment: "Each table is designed for a specific analysis path."
    comment: ""
    optionmenu: "Demo type", 1
        option: "Two groups (N=40) — t-test / Mann-Whitney"
        option: "Three groups (N=45) — ANOVA / Kruskal-Wallis"
        option: "Paired measures (N=20) — paired t-test / Wilcoxon"
        option: "Correlation (N=30) — Pearson / Spearman"
        option: "Regression (N=25) — simple linear regression"
        option: "Two-way design (N=48) — two-way ANOVA"
        option: "Normality check (N=40) — normal vs skewed"
clicked = endPause: "Quit", "Create", 2, 0
if clicked = 1
    exitScript: ""
endif

# ============================================================================
# 1. Two independent groups: patients vs controls
# ============================================================================

if demo_type = 1
    tableId = Create Table with column names: "demo_2groups", 40,
        ... "subject group F0_Hz jitter_pct"
    for i from 1 to 20
        Set string value: i, "subject", "S" + string$ (i)
        Set string value: i, "group", "Control"
        Set numeric value: i, "F0_Hz", randomGauss (120, 15)
        Set numeric value: i, "jitter_pct",
            ... max (0.1, randomGauss (0.8, 0.3))
    endfor
    for i from 21 to 40
        Set string value: i, "subject", "S" + string$ (i)
        Set string value: i, "group", "Patient"
        Set numeric value: i, "F0_Hz", randomGauss (140, 25)
        Set numeric value: i, "jitter_pct",
            ... max (0.1, randomGauss (2.1, 0.8))
    endfor
    description$ = "Two-group comparison (Control vs Patient)."
        ... + newline$ + "  Try: Compare groups → Independent → Two groups"
        ... + newline$ + "  Data column: jitter_pct or F0_Hz"
        ... + newline$ + "  Group column: group"

# ============================================================================
# 2. Three independent groups: soprano / mezzo / alto
# ============================================================================

elsif demo_type = 2
    tableId = Create Table with column names: "demo_3groups", 45,
        ... "singer voice_type SPL_dB vibrato_rate_Hz"
    for i from 1 to 15
        Set string value: i, "singer", "Singer_" + string$ (i)
        Set string value: i, "voice_type", "Soprano"
        Set numeric value: i, "SPL_dB", randomGauss (92, 4)
        Set numeric value: i, "vibrato_rate_Hz",
            ... max (3, randomGauss (5.8, 0.6))
    endfor
    for i from 16 to 30
        Set string value: i, "singer", "Singer_" + string$ (i)
        Set string value: i, "voice_type", "Mezzo"
        Set numeric value: i, "SPL_dB", randomGauss (88, 5)
        Set numeric value: i, "vibrato_rate_Hz",
            ... max (3, randomGauss (5.5, 0.7))
    endfor
    for i from 31 to 45
        Set string value: i, "singer", "Singer_" + string$ (i)
        Set string value: i, "voice_type", "Alto"
        Set numeric value: i, "SPL_dB", randomGauss (85, 4)
        Set numeric value: i, "vibrato_rate_Hz",
            ... max (3, randomGauss (5.2, 0.5))
    endfor
    description$ = "Three-group comparison (Soprano / Mezzo / Alto)."
        ... + newline$ + "  Try: Compare groups → Independent → Three or more"
        ... + newline$ + "  Data column: SPL_dB or vibrato_rate_Hz"
        ... + newline$ + "  Group column: voice_type"

# ============================================================================
# 3. Paired: same subjects measured pre and post therapy
# ============================================================================

elsif demo_type = 3
    tableId = Create Table with column names: "demo_paired", 20,
        ... "subject jitter_pre jitter_post HNR_pre HNR_post"
    for i from 1 to 20
        Set string value: i, "subject", "P" + string$ (i)
        preJitter = max (0.1, randomGauss (2.5, 0.8))
        Set numeric value: i, "jitter_pre", preJitter
        Set numeric value: i, "jitter_post",
            ... max (0.1, preJitter - randomGauss (0.8, 0.4))
        preHNR = randomGauss (18, 4)
        Set numeric value: i, "HNR_pre", preHNR
        Set numeric value: i, "HNR_post", preHNR + randomGauss (3, 1.5)
    endfor
    description$ = "Paired pre/post therapy comparison."
        ... + newline$ + "  Try: Compare groups → Paired / repeated"
        ... + newline$ + "  Column 1: jitter_pre (or HNR_pre)"
        ... + newline$ + "  Column 2: jitter_post (or HNR_post)"

# ============================================================================
# 4. Correlation: speaking F0 vs singing F0
# ============================================================================

elsif demo_type = 4
    tableId = Create Table with column names: "demo_correlation", 30,
        ... "speaker speaking_F0_Hz singing_F0_Hz age_years"
    for i from 1 to 30
        Set string value: i, "speaker", "Spk" + string$ (i)
        speakF0 = max (80, randomGauss (160, 40))
        Set numeric value: i, "speaking_F0_Hz", speakF0
        Set numeric value: i, "singing_F0_Hz",
            ... max (150, speakF0 * 2.1 + randomGauss (0, 30))
        Set numeric value: i, "age_years",
            ... round (randomUniform (22, 65))
    endfor
    description$ = "Bivariate relationship (speaking F0 vs singing F0)."
        ... + newline$ + "  Try: Examine a relationship → Correlation"
        ... + newline$ + "  Column X: speaking_F0_Hz"
        ... + newline$ + "  Column Y: singing_F0_Hz"

# ============================================================================
# 5. Regression: practice hours predicting vibrato regularity
# ============================================================================

elsif demo_type = 5
    tableId = Create Table with column names: "demo_regression", 25,
        ... "singer practice_hrs_wk vibrato_regularity_pct experience_yrs"
    for i from 1 to 25
        Set string value: i, "singer", "S" + string$ (i)
        practiceHrs = max (1, randomGauss (12, 5))
        Set numeric value: i, "practice_hrs_wk", practiceHrs
        # Clear linear relationship: more practice → more regular vibrato
        regularity = 40 + 3.2 * practiceHrs + randomGauss (0, 8)
        Set numeric value: i, "vibrato_regularity_pct",
            ... min (100, max (10, regularity))
        # Covariate: correlated with practice but adds independent info
        Set numeric value: i, "experience_yrs",
            ... max (1, round (practiceHrs * 0.8 + randomGauss (0, 3)))
    endfor
    description$ = "Predictor → outcome relationship."
        ... + newline$ + "  Try: Predict an outcome (or Examine → Regression)"
        ... + newline$ + "  Predictor (X): practice_hrs_wk"
        ... + newline$ + "  Response (Y): vibrato_regularity_pct"

# ============================================================================
# 6. Two-way ANOVA: voice type × task
# ============================================================================

elsif demo_type = 6
    tableId = Create Table with column names: "demo_twoway", 48,
        ... "subject voice_type task SPL_dB"
    row = 0
    for iVoice from 1 to 2
        if iVoice = 1
            voiceType$ = "Soprano"
            baseSPL = 90
        else
            voiceType$ = "Alto"
            baseSPL = 85
        endif
        for iTask from 1 to 2
            if iTask = 1
                task$ = "Speech"
                taskEffect = 0
            else
                task$ = "Singing"
                taskEffect = 8
            endif
            for iSubj from 1 to 12
                row = row + 1
                Set string value: row, "subject",
                    ... voiceType$ + "_" + string$ (iSubj)
                Set string value: row, "voice_type", voiceType$
                Set string value: row, "task", task$
                # Main effects + interaction: sopranos gain more SPL in singing
                interaction = 0
                if iVoice = 1 and iTask = 2
                    interaction = 3
                endif
                Set numeric value: row, "SPL_dB",
                    ... baseSPL + taskEffect + interaction
                    ... + randomGauss (0, 3)
            endfor
        endfor
    endfor
    description$ = "Two-factor design (voice_type × task)."
        ... + newline$ + "  Try: Compare groups → Independent → Two-factor design"
        ... + newline$ + "  Data column: SPL_dB"
        ... + newline$ + "  Factor 1: voice_type"
        ... + newline$ + "  Factor 2: task"
        ... + newline$ + "  Note: contains an interaction effect"

# ============================================================================
# 7. Normality check: normal vs skewed columns
# ============================================================================

elsif demo_type = 7
    tableId = Create Table with column names: "demo_normality", 40,
        ... "subject F0_Hz shimmer_pct jitter_pct"
    for i from 1 to 40
        Set string value: i, "subject", "S" + string$ (i)
        # F0: approximately normal
        Set numeric value: i, "F0_Hz", randomGauss (180, 30)
        # Shimmer: right-skewed (lognormal-ish)
        # exp(randomGauss) produces lognormal distribution
        Set numeric value: i, "shimmer_pct",
            ... exp (randomGauss (0.7, 0.5))
        # Jitter: mildly skewed (Gaussian with floor)
        Set numeric value: i, "jitter_pct",
            ... max (0.05, randomGauss (1.2, 0.6))
    endfor
    description$ = "Data with different distributional shapes."
        ... + newline$ + "  Try: Describe or summarize → Check normality"
        ... + newline$ + "  F0_Hz: approximately normal"
        ... + newline$ + "  shimmer_pct: right-skewed (try nonparametric)"
        ... + newline$ + "  jitter_pct: mildly skewed"

endif

selectObject: tableId
writeInfoLine: "Created demo Table: ", selected$ ("Table")
appendInfoLine: ""
appendInfoLine: description$
appendInfoLine: ""
appendInfoLine: "Select the Table and use the EML Tools menu or Wizard."
