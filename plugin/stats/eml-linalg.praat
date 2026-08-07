# ============================================================================
# EML Praat Tools — Numerical Linear Algebra Layer
# ============================================================================
# File: eml-linalg.praat
# Version: 1.0
# Date: 13 May 2026
#
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# License: GPL-3.0-or-later
#
# Provides matrix decomposition and solution procedures for the LMM engine.
# All procedures operate on Praat ## matrix variables (dense).
#
# Dependencies: None (uses only Praat built-in matrix primitives)
#
# Procedures:
#   @emlCholesky           — Cholesky decomposition (A = L L')
#   @emlTriangularLogDet   — log-determinant from triangular factor
#   @emlLogDeterminant     — log-determinant of SPD matrix
#   @emlForwardSolve       — forward substitution (L x = b)
#   @emlBackSolve          — back substitution (L' x = b)
#   @emlCholeskySolve      — solve A x = b via Cholesky
#   @emlCholeskySolveMulti — solve A X = B (matrix RHS)
#   @emlCholeskyInverse    — inverse of SPD matrix via Cholesky
# ============================================================================

# ============================================================================
# @emlCholesky
# Cholesky decomposition of a symmetric positive-definite matrix.
# Output: .l## (lower-triangular), .n (dimension), .error$ ("" on success)
# ============================================================================
procedure emlCholesky: .a##
    .n = numberOfRows (.a##)
    .l## = zero## (.n, .n)
    .error$ = ""

    # Check square
    if numberOfColumns (.a##) <> .n
        .error$ = "Matrix is not square"
        goto END_CHOLESKY
    endif

    # Check symmetry to a RELATIVE tolerance. A fixed absolute 1e-10 spuriously
    # rejects legitimately-symmetric matrices whose entries are large (e.g.
    # X'X at large N), where floating-point round-off in the symmetric-by-
    # construction products exceeds 1e-10 in absolute terms. Scale by the
    # magnitude of the two entries being compared.
    for .i from 1 to .n
        for .j from .i + 1 to .n
            .symScale = 1
            if abs (.a## [.i, .j]) > .symScale
                .symScale = abs (.a## [.i, .j])
            endif
            if abs (.a## [.j, .i]) > .symScale
                .symScale = abs (.a## [.j, .i])
            endif
            if abs (.a## [.i, .j] - .a## [.j, .i]) > 1e-10 * .symScale
                .error$ = "Matrix is not symmetric (row " + string$ (.i)
                    ... + ", col " + string$ (.j) + ")"
                goto END_CHOLESKY
            endif
        endfor
    endfor

    # Cholesky factorization (Golub & Van Loan)
    for .j from 1 to .n
        .sum = 0
        for .k from 1 to .j - 1
            .sum = .sum + .l## [.j, .k] * .l## [.j, .k]
        endfor
        .diag = .a## [.j, .j] - .sum
        if .diag <= 0
            .error$ = "Matrix is not positive definite (failed at index "
                ... + string$ (.j) + ")"
            goto END_CHOLESKY
        endif
        .l## [.j, .j] = sqrt (.diag)

        for .i from .j + 1 to .n
            .sum = 0
            for .k from 1 to .j - 1
                .sum = .sum + .l## [.i, .k] * .l## [.j, .k]
            endfor
            .l## [.i, .j] = (.a## [.i, .j] - .sum) / .l## [.j, .j]
        endfor
    endfor

    label END_CHOLESKY
endproc

# ============================================================================
# @emlTriangularLogDet
# Log-determinant from an already-computed lower-triangular factor.
# result = 2 * sum(log(L[i,i]))
# ============================================================================
procedure emlTriangularLogDet: .l##
    .n = numberOfRows (.l##)
    .result = 0
    for .i from 1 to .n
        .result = .result + ln (.l## [.i, .i])
    endfor
    .result = 2 * .result
endproc

# ============================================================================
# @emlLogDeterminant
# Log-determinant of a symmetric positive-definite matrix via Cholesky.
# ============================================================================
procedure emlLogDeterminant: .a##
    .error$ = ""
    @emlCholesky: .a##
    if emlCholesky.error$ <> ""
        .error$ = emlCholesky.error$
        .result = undefined
    else
        @emlTriangularLogDet: emlCholesky.l##
        .result = emlTriangularLogDet.result
    endif
endproc

# ============================================================================
# @emlForwardSolve
# Forward substitution: solve L * x = b where L is lower-triangular.
# ============================================================================
procedure emlForwardSolve: .l##, .b#
    .n = size (.b#)
    .x# = zero# (.n)
    .error$ = ""

    for .i from 1 to .n
        if abs (.l## [.i, .i]) < 1e-15
            .error$ = "Singular triangular matrix at index " + string$ (.i)
            goto END_FWDSOLVE
        endif
        .sum = 0
        for .j from 1 to .i - 1
            .sum = .sum + .l## [.i, .j] * .x# [.j]
        endfor
        .x# [.i] = (.b# [.i] - .sum) / .l## [.i, .i]
    endfor

    label END_FWDSOLVE
endproc

# ============================================================================
# @emlBackSolve
# Back substitution: solve L' * x = b where L is lower-triangular
# (so L' is upper-triangular).
# ============================================================================
procedure emlBackSolve: .l##, .b#
    .n = size (.b#)
    .x# = zero# (.n)
    .error$ = ""

    for .ii from 1 to .n
        .i = .n + 1 - .ii
        if abs (.l## [.i, .i]) < 1e-15
            .error$ = "Singular triangular matrix at index " + string$ (.i)
            goto END_BKSOLVE
        endif
        .sum = 0
        for .j from .i + 1 to .n
            .sum = .sum + .l## [.j, .i] * .x# [.j]
        endfor
        .x# [.i] = (.b# [.i] - .sum) / .l## [.i, .i]
    endfor

    label END_BKSOLVE
endproc

# ============================================================================
# @emlCholeskySolve
# Solve A * x = b for symmetric positive-definite A via Cholesky.
# Cholesky(A) -> L; ForwardSolve(L, b) -> y; BackSolve(L, y) -> x
# ============================================================================
procedure emlCholeskySolve: .a##, .b#
    .error$ = ""

    @emlCholesky: .a##
    if emlCholesky.error$ <> ""
        .error$ = emlCholesky.error$
        .x# = zero# (size (.b#))
        goto END_CHOLSOLVE
    endif

    @emlForwardSolve: emlCholesky.l##, .b#
    if emlForwardSolve.error$ <> ""
        .error$ = emlForwardSolve.error$
        .x# = zero# (size (.b#))
        goto END_CHOLSOLVE
    endif

    @emlBackSolve: emlCholesky.l##, emlForwardSolve.x#
    if emlBackSolve.error$ <> ""
        .error$ = emlBackSolve.error$
        .x# = zero# (size (.b#))
        goto END_CHOLSOLVE
    endif

    .x# = emlBackSolve.x#

    label END_CHOLSOLVE
endproc

# ============================================================================
# @emlCholeskySolveMulti
# Solve A * X = B for multiple right-hand sides (matrix RHS).
# ============================================================================
procedure emlCholeskySolveMulti: .a##, .b##
    .n = numberOfRows (.b##)
    .m = numberOfColumns (.b##)
    .x## = zero## (.n, .m)
    .error$ = ""

    # Single Cholesky factorization
    @emlCholesky: .a##
    if emlCholesky.error$ <> ""
        .error$ = emlCholesky.error$
        goto END_CHOLMULTI
    endif

    # Solve column by column using the same factor
    for .col from 1 to .m
        # Extract column
        .rhs# = zero# (.n)
        for .row from 1 to .n
            .rhs# [.row] = .b## [.row, .col]
        endfor

        @emlForwardSolve: emlCholesky.l##, .rhs#
        if emlForwardSolve.error$ <> ""
            .error$ = emlForwardSolve.error$
            goto END_CHOLMULTI
        endif

        @emlBackSolve: emlCholesky.l##, emlForwardSolve.x#
        if emlBackSolve.error$ <> ""
            .error$ = emlBackSolve.error$
            goto END_CHOLMULTI
        endif

        # Store solution column
        for .row from 1 to .n
            .x## [.row, .col] = emlBackSolve.x# [.row]
        endfor
    endfor

    label END_CHOLMULTI
endproc

# ============================================================================
# @emlCholeskyInverse
# Inverse of a symmetric positive-definite matrix via Cholesky.
# Uses CholeskySolveMulti with identity RHS.
# ============================================================================
procedure emlCholeskyInverse: .a##
    .n = numberOfRows (.a##)
    .error$ = ""

    # Create identity matrix
    .eye## = zero## (.n, .n)
    for .i from 1 to .n
        .eye## [.i, .i] = 1
    endfor

    @emlCholeskySolveMulti: .a##, .eye##
    if emlCholeskySolveMulti.error$ <> ""
        .error$ = emlCholeskySolveMulti.error$
        .inv## = zero## (.n, .n)
    else
        .inv## = emlCholeskySolveMulti.x##
    endif
endproc

# ============================================================================
# @emlForwardSolveMulti
# Forward substitution for matrix RHS: L * X = B
# Input: .l## (lower-triangular), .b## (n × m)
# Output: .x## (n × m), .error$
# ============================================================================
procedure emlForwardSolveMulti: .l##, .b##
    .n = numberOfRows (.l##)
    .m = numberOfColumns (.b##)
    .x## = zero## (.n, .m)
    .error$ = ""
    for .j from 1 to .m
        .col# = zero# (.n)
        for .i from 1 to .n
            .col# [.i] = .b## [.i, .j]
        endfor
        @emlForwardSolve: .l##, .col#
        if emlForwardSolve.error$ <> ""
            .error$ = emlForwardSolve.error$
            goto END_FWDMULTI
        endif
        for .i from 1 to .n
            .x## [.i, .j] = emlForwardSolve.x# [.i]
        endfor
    endfor
    label END_FWDMULTI
endproc

# ============================================================================
# @emlBackSolveMulti
# Back substitution for matrix RHS: L' * X = B
# Input: .l## (lower-triangular), .b## (n × m)
# Output: .x## (n × m), .error$
# ============================================================================
procedure emlBackSolveMulti: .l##, .b##
    .n = numberOfRows (.l##)
    .m = numberOfColumns (.b##)
    .x## = zero## (.n, .m)
    .error$ = ""
    for .j from 1 to .m
        .col# = zero# (.n)
        for .i from 1 to .n
            .col# [.i] = .b## [.i, .j]
        endfor
        @emlBackSolve: .l##, .col#
        if emlBackSolve.error$ <> ""
            .error$ = emlBackSolve.error$
            goto END_BKMULTI
        endif
        for .i from 1 to .n
            .x## [.i, .j] = emlBackSolve.x# [.i]
        endfor
    endfor
    label END_BKMULTI
endproc
