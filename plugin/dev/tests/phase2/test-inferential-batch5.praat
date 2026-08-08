# ============================================================================
# EML Stats : Test Suite — Inferential Statistics (Batch 5)
# ============================================================================
# Tests: @emlBonferroni, @emlHolm, @emlBenjaminiHochberg
# Date: 3 March 2026
#
# Reference values computed via statsmodels.stats.multitest.multipletests
# (3 Mar 2026) and independently verified via R p.adjust() in
# verify-inferential-batch5.R.
#
# Include order: utilities (for @emlSortWithIndex) -> inferential -> test helpers
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

include ../../../stats/eml-core-utilities.praat
include ../../../stats/eml-inferential.praat
include ../eml-test-helpers.praat

@emlTestInit

tolerance = 0.001
tightTolerance = 0.000001


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 1: @emlBonferroni
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlBonferroni"

# --- 1.1: Textbook 5-value mix ---
# Raw: {0.001, 0.013, 0.029, 0.05, 0.8}
# Expected: {0.005, 0.065, 0.145, 0.25, 1.0}
@emlBonferroni: {0.001, 0.013, 0.029, 0.05, 0.8}
@emlTestAssertEqualStr: "BON-1.1 no error", "", emlBonferroni.error$
@emlTestAssertEqualNum: "BON-1.1 k", 5, emlBonferroni.k, tightTolerance
@emlTestAssertEqualNum: "BON-1.1 p1", 0.005, emlBonferroni.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BON-1.1 p2", 0.065, emlBonferroni.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BON-1.1 p3", 0.145, emlBonferroni.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "BON-1.1 p4", 0.25, emlBonferroni.adjusted# [4], tightTolerance
@emlTestAssertEqualNum: "BON-1.1 p5", 1.0, emlBonferroni.adjusted# [5], tightTolerance

# --- 1.2: All significant ---
@emlBonferroni: {0.001, 0.005, 0.01, 0.02}
@emlTestAssertEqualNum: "BON-1.2 p1", 0.004, emlBonferroni.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BON-1.2 p2", 0.02, emlBonferroni.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BON-1.2 p3", 0.04, emlBonferroni.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "BON-1.2 p4", 0.08, emlBonferroni.adjusted# [4], tightTolerance

# --- 1.3: All nonsignificant (capping at 1.0) ---
@emlBonferroni: {0.2, 0.4, 0.6, 0.8}
@emlTestAssertEqualNum: "BON-1.3 p1", 0.8, emlBonferroni.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BON-1.3 p2", 1.0, emlBonferroni.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BON-1.3 p3", 1.0, emlBonferroni.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "BON-1.3 p4", 1.0, emlBonferroni.adjusted# [4], tightTolerance

# --- 1.4: Single p-value (k=1, no adjustment) ---
@emlBonferroni: {0.03}
@emlTestAssertEqualNum: "BON-1.4 single", 0.03, emlBonferroni.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BON-1.4 k", 1, emlBonferroni.k, tightTolerance

# --- 1.5: p=0 edge ---
@emlBonferroni: {0.0, 0.01, 0.05}
@emlTestAssertEqualNum: "BON-1.5 p=0", 0.0, emlBonferroni.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BON-1.5 p2", 0.03, emlBonferroni.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BON-1.5 p3", 0.15, emlBonferroni.adjusted# [3], tightTolerance

# --- 1.6: p=1 edge ---
@emlBonferroni: {0.01, 0.5, 1.0}
@emlTestAssertEqualNum: "BON-1.6 p1", 0.03, emlBonferroni.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BON-1.6 p2", 1.0, emlBonferroni.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BON-1.6 p3", 1.0, emlBonferroni.adjusted# [3], tightTolerance

# --- 1.7: Tied p-values ---
@emlBonferroni: {0.01, 0.01, 0.05, 0.05}
@emlTestAssertEqualNum: "BON-1.7 p1", 0.04, emlBonferroni.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BON-1.7 p2", 0.04, emlBonferroni.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BON-1.7 p3", 0.2, emlBonferroni.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "BON-1.7 p4", 0.2, emlBonferroni.adjusted# [4], tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 2: @emlHolm
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlHolm"

# --- 2.1: Textbook 5-value mix ---
# Raw: {0.001, 0.013, 0.029, 0.05, 0.8}
# Sorted asc: 0.001, 0.013, 0.029, 0.05, 0.8
# Multiplied: 0.001*5=0.005, 0.013*4=0.052, 0.029*3=0.087, 0.05*2=0.1, 0.8*1=0.8
# Running max: 0.005, 0.052, 0.087, 0.1, 0.8
@emlHolm: {0.001, 0.013, 0.029, 0.05, 0.8}
@emlTestAssertEqualStr: "HOLM-2.1 no error", "", emlHolm.error$
@emlTestAssertEqualNum: "HOLM-2.1 p1", 0.005, emlHolm.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.1 p2", 0.052, emlHolm.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.1 p3", 0.087, emlHolm.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.1 p4", 0.1, emlHolm.adjusted# [4], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.1 p5", 0.8, emlHolm.adjusted# [5], tightTolerance

# --- 2.2: All significant (monotonicity enforced) ---
# Raw: {0.001, 0.005, 0.01, 0.02}
# Multiplied: 0.004, 0.015, 0.02, 0.02
# Running max: 0.004, 0.015, 0.02, 0.02
@emlHolm: {0.001, 0.005, 0.01, 0.02}
@emlTestAssertEqualNum: "HOLM-2.2 p1", 0.004, emlHolm.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.2 p2", 0.015, emlHolm.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.2 p3", 0.02, emlHolm.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.2 p4", 0.02, emlHolm.adjusted# [4], tightTolerance

# --- 2.3: Reverse sorted input (index mapping test) ---
# Raw: {0.5, 0.1, 0.05, 0.01, 0.001}
# Same values as TC-6 but reversed — adjusted must map to original positions
# Expected: {0.5, 0.2, 0.15, 0.04, 0.005}
@emlHolm: {0.5, 0.1, 0.05, 0.01, 0.001}
@emlTestAssertEqualNum: "HOLM-2.3 p1 (was 0.5)", 0.5, emlHolm.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.3 p2 (was 0.1)", 0.2, emlHolm.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.3 p3 (was 0.05)", 0.15, emlHolm.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.3 p4 (was 0.01)", 0.04, emlHolm.adjusted# [4], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.3 p5 (was 0.001)", 0.005, emlHolm.adjusted# [5], tightTolerance

# --- 2.4: Capping + monotonicity ---
# Raw: {0.04, 0.06, 0.08, 0.3, 0.7}
# Sorted: 0.04, 0.06, 0.08, 0.3, 0.7
# Multiplied: 0.04*5=0.2, 0.06*4=0.24, 0.08*3=0.24, 0.3*2=0.6, 0.7*1=0.7
# Running max: 0.2, 0.24, 0.24, 0.6, 0.7
@emlHolm: {0.04, 0.06, 0.08, 0.3, 0.7}
@emlTestAssertEqualNum: "HOLM-2.4 p1", 0.2, emlHolm.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.4 p2", 0.24, emlHolm.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.4 p3", 0.24, emlHolm.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.4 p4", 0.6, emlHolm.adjusted# [4], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.4 p5", 0.7, emlHolm.adjusted# [5], tightTolerance

# --- 2.5: Single p-value ---
@emlHolm: {0.03}
@emlTestAssertEqualNum: "HOLM-2.5 single", 0.03, emlHolm.adjusted# [1], tightTolerance

# --- 2.6: Tied p-values ---
# Raw: {0.01, 0.01, 0.05, 0.05}
# Sorted: 0.01, 0.01, 0.05, 0.05
# Multiplied: 0.01*4=0.04, 0.01*3=0.03, 0.05*2=0.1, 0.05*1=0.05
# Running max: 0.04, 0.04, 0.1, 0.1
@emlHolm: {0.01, 0.01, 0.05, 0.05}
@emlTestAssertEqualNum: "HOLM-2.6 p1", 0.04, emlHolm.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.6 p2", 0.04, emlHolm.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.6 p3", 0.1, emlHolm.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.6 p4", 0.1, emlHolm.adjusted# [4], tightTolerance

# --- 2.7: All nonsignificant (capping) ---
@emlHolm: {0.2, 0.4, 0.6, 0.8}
@emlTestAssertEqualNum: "HOLM-2.7 p1", 0.8, emlHolm.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.7 p2", 1.0, emlHolm.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.7 p3", 1.0, emlHolm.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.7 p4", 1.0, emlHolm.adjusted# [4], tightTolerance

# --- 2.8: p=0 edge ---
@emlHolm: {0.0, 0.01, 0.05}
@emlTestAssertEqualNum: "HOLM-2.8 p=0", 0.0, emlHolm.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.8 p2", 0.02, emlHolm.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "HOLM-2.8 p3", 0.05, emlHolm.adjusted# [3], tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 3: @emlBenjaminiHochberg
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "@emlBenjaminiHochberg"

# --- 3.1: Textbook 5-value mix ---
# Raw: {0.001, 0.013, 0.029, 0.05, 0.8}
# Sorted asc: 0.001(r1), 0.013(r2), 0.029(r3), 0.05(r4), 0.8(r5)
# Process desc: 0.8*5/5=0.8, 0.05*5/4=0.0625, 0.029*5/3=0.04833,
#               0.013*5/2=0.0325, 0.001*5/1=0.005
# Running min (from top): 0.8, 0.0625, 0.04833, 0.0325, 0.005
@emlBenjaminiHochberg: {0.001, 0.013, 0.029, 0.05, 0.8}
@emlTestAssertEqualStr: "BH-3.1 no error", "", emlBenjaminiHochberg.error$
@emlTestAssertEqualNum: "BH-3.1 p1", 0.005, emlBenjaminiHochberg.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BH-3.1 p2", 0.0325, emlBenjaminiHochberg.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BH-3.1 p3", 0.04833, emlBenjaminiHochberg.adjusted# [3], tolerance
@emlTestAssertEqualNum: "BH-3.1 p4", 0.0625, emlBenjaminiHochberg.adjusted# [4], tightTolerance
@emlTestAssertEqualNum: "BH-3.1 p5", 0.8, emlBenjaminiHochberg.adjusted# [5], tightTolerance

# --- 3.2: All significant ---
# Raw: {0.001, 0.005, 0.01, 0.02}
# Process desc: 0.02*4/4=0.02, 0.01*4/3=0.01333, 0.005*4/2=0.01, 0.001*4/1=0.004
# Running min: 0.02, 0.01333, 0.01, 0.004
@emlBenjaminiHochberg: {0.001, 0.005, 0.01, 0.02}
@emlTestAssertEqualNum: "BH-3.2 p1", 0.004, emlBenjaminiHochberg.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BH-3.2 p2", 0.01, emlBenjaminiHochberg.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BH-3.2 p3", 0.01333, emlBenjaminiHochberg.adjusted# [3], tolerance
@emlTestAssertEqualNum: "BH-3.2 p4", 0.02, emlBenjaminiHochberg.adjusted# [4], tightTolerance

# --- 3.3: Reverse sorted input (index mapping) ---
# Raw: {0.5, 0.1, 0.05, 0.01, 0.001}
# Expected (same as ascending input, mapped back):
# {0.5, 0.125, 0.08333, 0.025, 0.005}
@emlBenjaminiHochberg: {0.5, 0.1, 0.05, 0.01, 0.001}
@emlTestAssertEqualNum: "BH-3.3 p1 (was 0.5)", 0.5, emlBenjaminiHochberg.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BH-3.3 p2 (was 0.1)", 0.125, emlBenjaminiHochberg.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BH-3.3 p3 (was 0.05)", 0.08333, emlBenjaminiHochberg.adjusted# [3], tolerance
@emlTestAssertEqualNum: "BH-3.3 p4 (was 0.01)", 0.025, emlBenjaminiHochberg.adjusted# [4], tightTolerance
@emlTestAssertEqualNum: "BH-3.3 p5 (was 0.001)", 0.005, emlBenjaminiHochberg.adjusted# [5], tightTolerance

# --- 3.4: Capping + monotonicity ---
# Raw: {0.04, 0.06, 0.08, 0.3, 0.7}
# Process desc: 0.7*5/5=0.7, 0.3*5/4=0.375, 0.08*5/3=0.13333,
#               0.06*5/2=0.15→clamped to 0.13333, 0.04*5/1=0.2→clamped to 0.13333
# Running min: 0.7, 0.375, 0.13333, 0.13333, 0.13333
@emlBenjaminiHochberg: {0.04, 0.06, 0.08, 0.3, 0.7}
@emlTestAssertEqualNum: "BH-3.4 p1", 0.13333, emlBenjaminiHochberg.adjusted# [1], tolerance
@emlTestAssertEqualNum: "BH-3.4 p2", 0.13333, emlBenjaminiHochberg.adjusted# [2], tolerance
@emlTestAssertEqualNum: "BH-3.4 p3", 0.13333, emlBenjaminiHochberg.adjusted# [3], tolerance
@emlTestAssertEqualNum: "BH-3.4 p4", 0.375, emlBenjaminiHochberg.adjusted# [4], tightTolerance
@emlTestAssertEqualNum: "BH-3.4 p5", 0.7, emlBenjaminiHochberg.adjusted# [5], tightTolerance

# --- 3.5: All nonsignificant ---
# Raw: {0.2, 0.4, 0.6, 0.8}
# Process desc: 0.8*4/4=0.8, 0.6*4/3=0.8, 0.4*4/2=0.8, 0.2*4/1=0.8
# Running min: 0.8, 0.8, 0.8, 0.8
@emlBenjaminiHochberg: {0.2, 0.4, 0.6, 0.8}
@emlTestAssertEqualNum: "BH-3.5 p1", 0.8, emlBenjaminiHochberg.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BH-3.5 p2", 0.8, emlBenjaminiHochberg.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BH-3.5 p3", 0.8, emlBenjaminiHochberg.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "BH-3.5 p4", 0.8, emlBenjaminiHochberg.adjusted# [4], tightTolerance

# --- 3.6: Single p-value ---
@emlBenjaminiHochberg: {0.03}
@emlTestAssertEqualNum: "BH-3.6 single", 0.03, emlBenjaminiHochberg.adjusted# [1], tightTolerance

# --- 3.7: Tied p-values ---
# Raw: {0.01, 0.01, 0.05, 0.05}
# Sorted asc: 0.01(r1), 0.01(r2), 0.05(r3), 0.05(r4)
# Process desc: 0.05*4/4=0.05, 0.05*4/3=0.06667→min=0.05,
#               0.01*4/2=0.02→min=0.02, 0.01*4/1=0.04→min=0.02
# Wait, running min from top: 0.05, min(0.05,0.06667)=0.05, min(0.05,0.02)=0.02, min(0.02,0.04)=0.02
# Expected: {0.02, 0.02, 0.05, 0.05}
@emlBenjaminiHochberg: {0.01, 0.01, 0.05, 0.05}
@emlTestAssertEqualNum: "BH-3.7 p1", 0.02, emlBenjaminiHochberg.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BH-3.7 p2", 0.02, emlBenjaminiHochberg.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BH-3.7 p3", 0.05, emlBenjaminiHochberg.adjusted# [3], tightTolerance
@emlTestAssertEqualNum: "BH-3.7 p4", 0.05, emlBenjaminiHochberg.adjusted# [4], tightTolerance

# --- 3.8: Large k=10 ---
@emlBenjaminiHochberg: {0.001, 0.005, 0.01, 0.02, 0.03, 0.04, 0.05, 0.1, 0.5, 0.9}
@emlTestAssertEqualNum: "BH-3.8 p1", 0.01, emlBenjaminiHochberg.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BH-3.8 p2", 0.025, emlBenjaminiHochberg.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BH-3.8 p3", 0.03333, emlBenjaminiHochberg.adjusted# [3], tolerance
@emlTestAssertEqualNum: "BH-3.8 p4", 0.05, emlBenjaminiHochberg.adjusted# [4], tightTolerance
@emlTestAssertEqualNum: "BH-3.8 p5", 0.06, emlBenjaminiHochberg.adjusted# [5], tightTolerance
@emlTestAssertEqualNum: "BH-3.8 p6", 0.06667, emlBenjaminiHochberg.adjusted# [6], tolerance
@emlTestAssertEqualNum: "BH-3.8 p7", 0.07143, emlBenjaminiHochberg.adjusted# [7], tolerance
@emlTestAssertEqualNum: "BH-3.8 p8", 0.125, emlBenjaminiHochberg.adjusted# [8], tightTolerance
@emlTestAssertEqualNum: "BH-3.8 p9", 0.55556, emlBenjaminiHochberg.adjusted# [9], tolerance
@emlTestAssertEqualNum: "BH-3.8 p10", 0.9, emlBenjaminiHochberg.adjusted# [10], tightTolerance

# --- 3.9: p=0 and p=1 edges ---
@emlBenjaminiHochberg: {0.0, 0.01, 0.05}
@emlTestAssertEqualNum: "BH-3.9 p=0", 0.0, emlBenjaminiHochberg.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BH-3.9 p2", 0.015, emlBenjaminiHochberg.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BH-3.9 p3", 0.05, emlBenjaminiHochberg.adjusted# [3], tightTolerance

@emlBenjaminiHochberg: {0.01, 0.5, 1.0}
@emlTestAssertEqualNum: "BH-3.10 p1", 0.03, emlBenjaminiHochberg.adjusted# [1], tightTolerance
@emlTestAssertEqualNum: "BH-3.10 p2", 0.75, emlBenjaminiHochberg.adjusted# [2], tightTolerance
@emlTestAssertEqualNum: "BH-3.10 p3", 1.0, emlBenjaminiHochberg.adjusted# [3], tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 4: Error handling
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "Error handling"

# --- 4.1: Empty vector — Bonferroni ---
@emlBonferroni: zero# (0)
@emlTestAssertTrue: "BON-4.1 error on empty", emlBonferroni.error$ <> ""

# --- 4.2: Empty vector — Holm ---
@emlHolm: zero# (0)
@emlTestAssertTrue: "HOLM-4.2 error on empty", emlHolm.error$ <> ""

# --- 4.3: Empty vector — BH ---
@emlBenjaminiHochberg: zero# (0)
@emlTestAssertTrue: "BH-4.3 error on empty", emlBenjaminiHochberg.error$ <> ""


# ══════════════════════════════════════════════════════════════════════════════
# TEST GROUP 5: Cross-method consistency
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSection: "Cross-method consistency"

# --- 5.1: Bonferroni >= Holm >= BH (for all values in same input) ---
# Using TC-1 data
@emlBonferroni: {0.001, 0.013, 0.029, 0.05, 0.8}
bonP1 = emlBonferroni.adjusted# [2]
@emlHolm: {0.001, 0.013, 0.029, 0.05, 0.8}
holmP1 = emlHolm.adjusted# [2]
@emlBenjaminiHochberg: {0.001, 0.013, 0.029, 0.05, 0.8}
bhP1 = emlBenjaminiHochberg.adjusted# [2]

@emlTestAssertTrue: "5.1 Bonferroni >= Holm (p2)", bonP1 >= holmP1 - tightTolerance
@emlTestAssertTrue: "5.1 Holm >= BH (p2)", holmP1 >= bhP1 - tightTolerance

# --- 5.2: All three agree for k=1 ---
@emlBonferroni: {0.042}
bonSingle = emlBonferroni.adjusted# [1]
@emlHolm: {0.042}
holmSingle = emlHolm.adjusted# [1]
@emlBenjaminiHochberg: {0.042}
bhSingle = emlBenjaminiHochberg.adjusted# [1]
@emlTestAssertEqualNum: "5.2 all equal at k=1 (Bon=Holm)", bonSingle, holmSingle, tightTolerance
@emlTestAssertEqualNum: "5.2 all equal at k=1 (Holm=BH)", holmSingle, bhSingle, tightTolerance


# ══════════════════════════════════════════════════════════════════════════════
# SUMMARY
# ══════════════════════════════════════════════════════════════════════════════

@emlTestSummary
