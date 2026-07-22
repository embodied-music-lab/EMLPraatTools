# ============================================================================
# Test: @emlShapiroWilk
# ============================================================================
# Verifies Shapiro-Wilk implementation against scipy.stats.shapiro
# reference values (Rule 32 computational verification).
#
# Run from the EML Stats plugin directory, or adjust include paths.
# ============================================================================

include ../../../stats/eml-core-descriptive.praat

writeInfoLine: "Testing @emlShapiroWilk..."
appendInfoLine: ""

nPass = 0
nFail = 0
wTol = 1e-5
pTol = 5e-3

# ============================================================================
# Helper: compare W and p against reference
# ============================================================================
procedure checkSW: .label$, .data#, .refW, .refP
    @emlShapiroWilk: .data#
    if emlShapiroWilk.error$ <> ""
        appendInfoLine: "FAIL " + .label$ + ": error = "
        ... + emlShapiroWilk.error$
        nFail = nFail + 1
    else
        .wDiff = abs (emlShapiroWilk.w - .refW)
        .pDiff = abs (emlShapiroWilk.p - .refP)
        .wOk = .wDiff < wTol
        .pOk = .pDiff < pTol
        if .wOk and .pOk
            appendInfoLine: "PASS " + .label$
            ... + ": W=" + fixed$ (emlShapiroWilk.w, 6)
            ... + ", p=" + fixed$ (emlShapiroWilk.p, 6)
            nPass = nPass + 1
        else
            appendInfoLine: "FAIL " + .label$
            ... + ": W=" + fixed$ (emlShapiroWilk.w, 8)
            ... + " (ref " + fixed$ (.refW, 8) + ")"
            ... + ", p=" + fixed$ (emlShapiroWilk.p, 8)
            ... + " (ref " + fixed$ (.refP, 8) + ")"
            if not .wOk
                appendInfoLine: "  W diff = " + fixed$ (.wDiff, 10)
            endif
            if not .pOk
                appendInfoLine: "  p diff = " + fixed$ (.pDiff, 10)
            endif
            nFail = nFail + 1
        endif
    endif
endproc


# ============================================================================
# Test 1: n=3, perfectly linear (should give W=1, p=1)
# Reference: scipy W=1.0000000000, p=1.0000000000
# ============================================================================
@checkSW: "n=3 linear", {1, 2, 3}, 1.0, 1.0

# ============================================================================
# Test 2: n=4, normal-ish
# Reference: scipy W=0.9620300734, p=0.7916779440
# ============================================================================
@checkSW: "n=4", {3.1, 4.2, 3.8, 4.5}, 0.96203007, 0.79168

# ============================================================================
# Test 3: n=5, normal-ish
# Reference: scipy W=0.9899774665, p=0.9796155111
# ============================================================================
@checkSW: "n=5", {2.3, 1.8, 2.5, 2.1, 2.0}, 0.98997747, 0.97962

# ============================================================================
# Test 4: n=10, normal
# Reference: scipy W=0.9076501529, p=0.2652369416
# ============================================================================
testData4# = {92.96, 96.49, 96.49, 97.93, 107.45,
    ... 108.14, 109.72, 111.51, 122.85, 123.69}
@checkSW: "n=10 normal", testData4#, 0.90765015, 0.26524

# ============================================================================
# Test 5: n=20, uniform (moderate departure)
# Reference: scipy W=0.9227371577, p=0.1118741841
# ============================================================================
testData5# = {8.86, 0.78, 9.8, 2.48, 7.53, 5.27, 9.08, 8.84, 0.89, 5.17,
    ... 3.44, 2.12, 3.61, 2.71, 7.62, 4.78, 0.99, 2.75, 7.94, 5.14}
@checkSW: "n=20 uniform", testData5#, 0.92273716, 0.11187

# ============================================================================
# Test 6: n=30, normal
# Reference: scipy W=0.9621368662, p=0.3508717524
# ============================================================================
testData6# = {39.14, 59.97, 52.83, 34.94, 44.21, 66.51, 25.73, 45.71, 62.66,
    ... 41.33, 43.21, 49.05, 64.91, 43.61, 45.56, 45.66, 72.06, 71.87,
    ... 60.04, 53.86, 57.37, 64.91, 40.64, 61.76, 37.46, 43.62, 59.07,
    ... 35.71, 48.6, 41.38}
@checkSW: "n=30 normal", testData6#, 0.96213687, 0.35087

# ============================================================================
# Test 7: n=30, exponential (should reject normality)
# Reference: scipy W=0.9039740162, p=0.0105199665
# ============================================================================
testData7# = {1.43, 0.89, 7.65, 8.26, 4.91, 4.63, 10.84, 7.12, 1.0, 0.81,
    ... 2.86, 2.43, 4.29, 0.79, 5.8, 3.16, 4.22, 5.19, 6.42, 5.71,
    ... 1.0, 0.63, 1.39, 0.04, 2.23, 0.79, 3.91, 9.73, 1.12, 0.72}
@checkSW: "n=30 exponential", testData7#, 0.90397402, 0.01052

# ============================================================================
# Test 8: Error handling — n < 3
# ============================================================================
@emlShapiroWilk: {1, 2}
if emlShapiroWilk.error$ <> ""
    appendInfoLine: "PASS n<3 error: " + emlShapiroWilk.error$
    nPass = nPass + 1
else
    appendInfoLine: "FAIL n<3 error: should have reported error"
    nFail = nFail + 1
endif

# ============================================================================
# Test 9: Error handling — constant data
# ============================================================================
@emlShapiroWilk: {5, 5, 5, 5}
if emlShapiroWilk.error$ <> ""
    appendInfoLine: "PASS constant data error: " + emlShapiroWilk.error$
    nPass = nPass + 1
else
    appendInfoLine: "FAIL constant data error: should have reported error"
    nFail = nFail + 1
endif

# ============================================================================
# Summary
# ============================================================================
appendInfoLine: ""
appendInfoLine: "============================="
nTotal = nPass + nFail
appendInfoLine: string$ (nPass) + "/" + string$ (nTotal) + " PASSED"
if nFail > 0
    appendInfoLine: string$ (nFail) + " FAILED"
else
    appendInfoLine: "All tests passed."
endif
