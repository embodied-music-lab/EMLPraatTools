# ============================================================================
# EML Praat Tools — Derivative-Free Optimizers
# ============================================================================
# File: eml-optimizer.praat
# Version: 2.0
# Date: 13 May 2026
#
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# License: GPL-3.0-or-later
#
# Two optimizers with identical output interface:
#   @emlNelderMead  — Simplex method with bound projection
#   @emlBOBYQA      — Powell's BOBYQA (Bound Optimization BY Quadratic
#                     Approximations). Faithful port from C reference by
#                     É. Thiébaut, itself a translation of Powell's Fortran.
#
# BOBYQA is the optimizer lme4 uses (via R's minqa::bobyqa). It builds a
# quadratic interpolation model and solves a trust-region subproblem with
# box constraints at each iteration.
#
# Objective function protocol:
#   The caller defines a procedure with signature:
#     procedure <name>: .x#
#         ... compute f(x) ...
#         <name>.value = f
#     endproc
#   The optimizer calls it via dynamic dispatch: @'.objectiveProc$': .x#
#
# Dependencies: eml-linalg.praat (for future LMM use; not needed by optimizer)
# ============================================================================

# ============================================================================
# EML Praat Tools — Derivative-Free Optimizers
# ============================================================================
# File: eml-optimizer.praat
# Version: 1.0
# Date: 13 May 2026
#
# Author: Ian Howell, Embodied Music Lab (www.embodiedmusiclab.com)
# Development: Claude (Anthropic)
# License: GPL-3.0-or-later
#
# Two optimizers with identical interfaces:
#   @emlNelderMead     — Simplex method with bound projection (complete)

#
# A faithful port of Powell's BOBYQA (the optimizer lme4 uses) is pending
# derivative-free and support bound constraints.
#
# Objective function protocol:
#   The caller defines a procedure with signature:
#     procedure <name>: .x#
#         ... compute f(x) ...
#         <name>.value = f
#     endproc
#   The optimizer calls it via dynamic dispatch: @'.objectiveProc$': .x#
#
# Dependencies: eml-linalg.praat (for BOBYQA model solve)
# ============================================================================

# ============================================================================
# @emlProjectOntoBounds
# Project a vector onto [lower, upper] box constraints.
# ============================================================================
procedure emlProjectOntoBounds: .x#, .lower#, .upper#
    .d = size (.x#)
    .result# = zero# (.d)
    for .i from 1 to .d
        .result# [.i] = max (.lower# [.i], min (.upper# [.i], .x# [.i]))
    endfor
endproc

# ============================================================================
# @emlNelderMead
# Nelder-Mead simplex optimizer with bound constraints.
#
# Input:
#   .objectiveProc$  — name of objective procedure (see protocol above)
#   .x0#             — initial point (d-vector)
#   .lower#          — lower bounds (use -1e30 for unbounded)
#   .upper#          — upper bounds (use 1e30 for unbounded)
#   .tolerance       — convergence tolerance on simplex diameter
#   .maxEval         — maximum function evaluations
#
# Output:
#   .xOpt#           — optimal point
#   .fOpt            — objective value at optimum
#   .nEval           — evaluations used
#   .convergence     — 0=converged, 1=maxEval reached
#   .error$          — "" on success
# ============================================================================
procedure emlNelderMead: .objectiveProc$, .x0#, .lower#, .upper#,
    ... .tolerance, .maxEval
    .d = size (.x0#)
    .nVert = .d + 1
    .error$ = ""
    .nEval = 0
    .convergence = 1

    # Simplex coefficients
    .alpha = 1.0
    .gamma = 2.0
    .rho = 0.5
    .sigma = 0.5

    # Initialize simplex: x0 plus d perturbations
    # Store vertices as parallel vectors (Praat has no 3D arrays)
    # .vx'.v'# = vertex v coordinates, .vf'.v' = vertex v function value
    @emlProjectOntoBounds: .x0#, .lower#, .upper#
    .vx1# = emlProjectOntoBounds.result#
    @'.objectiveProc$': .vx1#
    .vf1 = '.objectiveProc$'.value
    .nEval = .nEval + 1

    for .v from 2 to .nVert
        .pertIdx = .v - 1
        .vx'.v'# = zero# (.d)
        for .k from 1 to .d
            .vx'.v'# [.k] = .vx1# [.k]
        endfor
        # Perturb dimension .pertIdx AWAY from the nearer active bound, so that
        # projection onto bounds cannot collapse the simplex in this dimension
        # when the start coordinate sits at/near a bound (L3). Always-+step
        # would flatten a vertex that starts at its upper bound.
        .step = 0.05
        if abs (.vx'.v'# [.pertIdx]) > 0.001
            .step = 0.05 * abs (.vx'.v'# [.pertIdx])
        endif
        .distUpper = .upper# [.pertIdx] - .vx'.v'# [.pertIdx]
        .distLower = .vx'.v'# [.pertIdx] - .lower# [.pertIdx]
        if .distUpper < .distLower
            .vx'.v'# [.pertIdx] = .vx'.v'# [.pertIdx] - .step
        else
            .vx'.v'# [.pertIdx] = .vx'.v'# [.pertIdx] + .step
        endif
        @emlProjectOntoBounds: .vx'.v'#, .lower#, .upper#
        .vx'.v'# = emlProjectOntoBounds.result#
        @'.objectiveProc$': .vx'.v'#
        .vf'.v' = '.objectiveProc$'.value
        .nEval = .nEval + 1
    endfor

    # Main loop
    repeat
        # 1. Order vertices: find best, worst, second-worst
        .bestIdx = 1
        .worstIdx = 1
        .bestF = .vf1
        .worstF = .vf1
        for .v from 2 to .nVert
            if .vf'.v' < .bestF
                .bestF = .vf'.v'
                .bestIdx = .v
            endif
            if .vf'.v' > .worstF
                .worstF = .vf'.v'
                .worstIdx = .v
            endif
        endfor
        .secWorstIdx = .bestIdx
        .secWorstF = .bestF
        for .v from 1 to .nVert
            if .v <> .worstIdx and .vf'.v' > .secWorstF
                .secWorstF = .vf'.v'
                .secWorstIdx = .v
            endif
        endfor

        # 2. Check convergence: simplex diameter
        .diam = 0
        for .v from 1 to .nVert
            if .v <> .bestIdx
                .dist = 0
                for .k from 1 to .d
                    .diff = .vx'.v'# [.k] - .vx'.bestIdx'# [.k]
                    .dist = .dist + .diff * .diff
                endfor
                .dist = sqrt (.dist)
                if .dist > .diam
                    .diam = .dist
                endif
            endif
        endfor
        if .diam < .tolerance
            .convergence = 0
            goto END_NM
        endif

        # 2b. Also converge on function-value spread (standard Nelder-Mead
        # criterion). A simplex can flatten in objective value while its
        # geometric diameter is still above tolerance; checking diameter alone
        # over-iterates and, for the profile-CI objectives, can stall. Converge
        # when the best-to-worst objective gap is negligible relative to the
        # objective magnitude.
        .fmin = .vf'.bestIdx'
        .fmax = .fmin
        for .v from 1 to .nVert
            if .vf'.v' > .fmax
                .fmax = .vf'.v'
            endif
        endfor
        if .fmax - .fmin < .tolerance * (abs (.fmin) + .tolerance)
            .convergence = 0
            goto END_NM
        endif

        # 3. Compute centroid (excluding worst vertex)
        .centroid# = zero# (.d)
        for .v from 1 to .nVert
            if .v <> .worstIdx
                for .k from 1 to .d
                    .centroid# [.k] = .centroid# [.k] + .vx'.v'# [.k]
                endfor
            endif
        endfor
        for .k from 1 to .d
            .centroid# [.k] = .centroid# [.k] / .d
        endfor

        # 4. Reflection
        .xr# = zero# (.d)
        for .k from 1 to .d
            .xr# [.k] = .centroid# [.k]
                ... + .alpha * (.centroid# [.k] - .vx'.worstIdx'# [.k])
        endfor
        @emlProjectOntoBounds: .xr#, .lower#, .upper#
        .xr# = emlProjectOntoBounds.result#
        @'.objectiveProc$': .xr#
        .fr = '.objectiveProc$'.value
        .nEval = .nEval + 1

        if .fr < .secWorstF and .fr >= .bestF
            # Accept reflection
            .vx'.worstIdx'# = .xr#
            .vf'.worstIdx' = .fr
        elif .fr < .bestF
            # Try expansion
            .xe# = zero# (.d)
            for .k from 1 to .d
                .xe# [.k] = .centroid# [.k]
                    ... + .gamma * (.xr# [.k] - .centroid# [.k])
            endfor
            @emlProjectOntoBounds: .xe#, .lower#, .upper#
            .xe# = emlProjectOntoBounds.result#
            @'.objectiveProc$': .xe#
            .fe = '.objectiveProc$'.value
            .nEval = .nEval + 1
            if .fe < .fr
                .vx'.worstIdx'# = .xe#
                .vf'.worstIdx' = .fe
            else
                .vx'.worstIdx'# = .xr#
                .vf'.worstIdx' = .fr
            endif
        else
            # Contraction
            if .fr < .worstF
                # Outside contraction
                .xc# = zero# (.d)
                for .k from 1 to .d
                    .xc# [.k] = .centroid# [.k]
                        ... + .rho * (.xr# [.k] - .centroid# [.k])
                endfor
                @emlProjectOntoBounds: .xc#, .lower#, .upper#
                .xc# = emlProjectOntoBounds.result#
                @'.objectiveProc$': .xc#
                .fc = '.objectiveProc$'.value
                .nEval = .nEval + 1
                if .fc <= .fr
                    .vx'.worstIdx'# = .xc#
                    .vf'.worstIdx' = .fc
                else
                    goto SHRINK_NM
                endif
            else
                # Inside contraction
                .xc# = zero# (.d)
                for .k from 1 to .d
                    .xc# [.k] = .centroid# [.k]
                        ... + .rho * (.vx'.worstIdx'# [.k] - .centroid# [.k])
                endfor
                @emlProjectOntoBounds: .xc#, .lower#, .upper#
                .xc# = emlProjectOntoBounds.result#
                @'.objectiveProc$': .xc#
                .fc = '.objectiveProc$'.value
                .nEval = .nEval + 1
                if .fc < .worstF
                    .vx'.worstIdx'# = .xc#
                    .vf'.worstIdx' = .fc
                else
                    goto SHRINK_NM
                endif
            endif
            goto SKIP_SHRINK_NM
            label SHRINK_NM
            # Shrink: move all vertices toward best
            for .v from 1 to .nVert
                if .v <> .bestIdx
                    for .k from 1 to .d
                        .vx'.v'# [.k] = .vx'.bestIdx'# [.k]
                            ... + .sigma * (.vx'.v'# [.k] - .vx'.bestIdx'# [.k])
                    endfor
                    @emlProjectOntoBounds: .vx'.v'#, .lower#, .upper#
                    .vx'.v'# = emlProjectOntoBounds.result#
                    @'.objectiveProc$': .vx'.v'#
                    .vf'.v' = '.objectiveProc$'.value
                    .nEval = .nEval + 1
                endif
            endfor
            label SKIP_SHRINK_NM
        endif
    until .nEval >= .maxEval

    label END_NM

    # Find best vertex
    .bestIdx = 1
    .bestF = .vf1
    for .v from 2 to .nVert
        if .vf'.v' < .bestF
            .bestF = .vf'.v'
            .bestIdx = .v
        endif
    endfor

    .xOpt# = .vx'.bestIdx'#
    .fOpt = .bestF
endproc

# ============================================================================
# @emlBOBYQAUpdate — Rank-1 update of BMAT and ZMAT
# Port of Powell's UPDATE subroutine.
# ============================================================================
procedure emlBOBYQAUpdate: .n, .npt, .bmat##, .zmat##, .vlag#, .beta,
    ... .denom, .knew
    .ndim = .npt + .n
    .nptm = .npt - .n - 1
    .w# = zero# (.ndim)

    # Find threshold for treating ZMAT elements as zero
    .ztest = 0
    for .k from 1 to .npt
        for .j from 1 to .nptm
            .temp = abs (.zmat## [.k, .j])
            .ztest = max (.ztest, .temp)
        endfor
    endfor
    .ztest = .ztest * 1e-20

    # Apply rotations that put zeros in the KNEW-th row of ZMAT
    for .j from 2 to .nptm
        if abs (.zmat## [.knew, .j]) > .ztest
            .tempa = .zmat## [.knew, 1]
            .tempb = .zmat## [.knew, .j]
            .temp = sqrt (.tempa * .tempa + .tempb * .tempb)
            .tempa = .tempa / .temp
            .tempb = .tempb / .temp
            for .i from 1 to .npt
                .temp = .tempa * .zmat## [.i, 1] + .tempb * .zmat## [.i, .j]
                .zmat## [.i, .j] = .tempa * .zmat## [.i, .j]
                    ... - .tempb * .zmat## [.i, 1]
                .zmat## [.i, 1] = .temp
            endfor
        endif
        .zmat## [.knew, .j] = 0
    endfor

    # Put first NPT components of KNEW-th column of HLAG into W
    for .i from 1 to .npt
        .w# [.i] = .zmat## [.knew, 1] * .zmat## [.i, 1]
    endfor
    .alpha = .w# [.knew]
    .tau = .vlag# [.knew]
    .vlag# [.knew] = .vlag# [.knew] - 1

    # Complete the updating of ZMAT
    .temp = sqrt (.denom)
    .tempb = .zmat## [.knew, 1] / .temp
    .tempa = .tau / .temp
    for .i from 1 to .npt
        .zmat## [.i, 1] = .tempa * .zmat## [.i, 1] - .tempb * .vlag# [.i]
    endfor

    # Update BMAT
    for .j from 1 to .n
        .jp = .npt + .j
        .w# [.jp] = .bmat## [.knew, .j]
        .tempa = (.alpha * .vlag# [.jp] - .tau * .w# [.jp]) / .denom
        .tempb = (-.beta * .w# [.jp] - .tau * .vlag# [.jp]) / .denom
        for .i from 1 to .jp
            .bmat## [.i, .j] = .bmat## [.i, .j]
                ... + .tempa * .vlag# [.i] + .tempb * .w# [.i]
            if .i > .npt
                .bmat## [.jp, .i - .npt] = .bmat## [.i, .j]
            endif
        endfor
    endfor
endproc

# ============================================================================
# @emlBOBYQATrsbox — Trust region step with box constraints
# Port of Powell's TRSBOX subroutine.
# Truncated conjugate gradient with active-set bound handling.
# ============================================================================
procedure emlBOBYQATrsbox: .n, .npt, .xpt##, .xOpt#, .gopt#, .hq##,
    ... .pq#, .sl#, .su#, .delta
    # Work vectors
    .xnew# = zero# (.n)
    .d# = zero# (.n)
    .gnew# = zero# (.n)
    .xbdi# = zero# (.n)
    .s# = zero# (.n)
    .hs# = zero# (.n)
    .hred# = zero# (.n)

    # Initialize bound indicators and step
    .iterc = 0
    .nact = 0
    for .i from 1 to .n
        .xbdi# [.i] = 0
        if .xOpt# [.i] <= .sl# [.i]
            if .gopt# [.i] >= 0
                .xbdi# [.i] = -1
            endif
        elsif .xOpt# [.i] >= .su# [.i]
            if .gopt# [.i] <= 0
                .xbdi# [.i] = 1
            endif
        endif
        if .xbdi# [.i] <> 0
            .nact = .nact + 1
        endif
        .d# [.i] = 0
        .gnew# [.i] = .gopt# [.i]
    endfor
    .delsq = .delta * .delta
    .qred = 0
    .crvmin = -1

    .angbd = 0
    .dredg = 0
    .dredsq = 0
    .ggsav = 0
    .gredsq = 0
    .rdnext = 0
    .sredg = 0
    .xsav = 0
    .iact = 0
    .itcsav = 0
    .itermax = 0

    # ---------- CG RESTART ----------
    label trs_L20
    .beta_cg = 0
    label trs_L30
    .stepsq = 0
    for .i from 1 to .n
        if .xbdi# [.i] <> 0
            .s# [.i] = 0
        elsif .beta_cg = 0
            .s# [.i] = -.gnew# [.i]
        else
            .s# [.i] = .beta_cg * .s# [.i] - .gnew# [.i]
        endif
        .stepsq = .stepsq + .s# [.i] * .s# [.i]
    endfor
    if .stepsq = 0
        goto trs_L190
    endif
    if .beta_cg = 0
        .gredsq = .stepsq
        .itermax = .iterc + .n - .nact
    endif
    if .gredsq * .delsq <= .qred * 1e-4 * .qred
        goto trs_L190
    endif

    # Compute HS = H*S (goto to shared matrix-vector product)
    goto trs_L210
    label trs_L50
    .resid = .delsq
    .ds = 0
    .shs = 0
    for .i from 1 to .n
        if .xbdi# [.i] = 0
            .resid = .resid - .d# [.i] * .d# [.i]
            .ds = .ds + .s# [.i] * .d# [.i]
            .shs = .shs + .s# [.i] * .hs# [.i]
        endif
    endfor
    if .resid <= 0
        goto trs_L90
    endif
    .temp = sqrt (.stepsq * .resid + .ds * .ds)
    if .ds < 0
        .blen = (.temp - .ds) / .stepsq
    else
        .blen = .resid / (.temp + .ds)
    endif
    if .shs > 0
        .stplen = .gredsq / .shs
        .stplen = min (.blen, .stplen)
    else
        .stplen = .blen
    endif

    # Reduce stplen to preserve bounds
    .iact = 0
    for .i from 1 to .n
        if .s# [.i] <> 0
            .xsum = .xOpt# [.i] + .d# [.i]
            if .s# [.i] > 0
                .temp = (.su# [.i] - .xsum) / .s# [.i]
            else
                .temp = (.sl# [.i] - .xsum) / .s# [.i]
            endif
            if .temp < .stplen
                .stplen = .temp
                .iact = .i
            endif
        endif
    endfor

    # Update crvmin, gnew, d
    .sdec = 0
    if .stplen > 0
        .iterc = .iterc + 1
        .temp = .shs / .stepsq
        if .iact = 0 and .temp > 0
            .crvmin = min (.crvmin, .temp)
            if .crvmin = -1
                .crvmin = .temp
            endif
        endif
        .ggsav = .gredsq
        .gredsq = 0
        for .i from 1 to .n
            .gnew# [.i] = .gnew# [.i] + .stplen * .hs# [.i]
            if .xbdi# [.i] = 0
                .gredsq = .gredsq + .gnew# [.i] * .gnew# [.i]
            endif
            .d# [.i] = .d# [.i] + .stplen * .s# [.i]
        endfor
        .sdec = .stplen * (.ggsav - 0.5 * .stplen * .shs)
        .sdec = max (.sdec, 0)
        .qred = .qred + .sdec
    endif

    # Restart CG if new bound hit
    if .iact > 0
        .nact = .nact + 1
        .xbdi# [.iact] = 1
        if .s# [.iact] < 0
            .xbdi# [.iact] = -1
        endif
        .delsq = .delsq - .d# [.iact] * .d# [.iact]
        if .delsq <= 0
            goto trs_L90
        endif
        goto trs_L20
    endif

    # Check if stplen < blen (more CG iterations possible)
    if .stplen < .blen
        if .iterc = .itermax
            goto trs_L190
        endif
        if .sdec <= .qred * 0.01
            goto trs_L190
        endif
        .beta_cg = .gredsq / .ggsav
        goto trs_L30
    endif
    label trs_L90
    .crvmin = 0

    # ---------- ALTERNATIVE ITERATION ----------
    label trs_L100
    if .nact >= .n - 1
        goto trs_L190
    endif
    .dredsq = 0
    .dredg = 0
    .gredsq = 0
    for .i from 1 to .n
        if .xbdi# [.i] = 0
            .dredsq = .dredsq + .d# [.i] * .d# [.i]
            .dredg = .dredg + .d# [.i] * .gnew# [.i]
            .gredsq = .gredsq + .gnew# [.i] * .gnew# [.i]
            .s# [.i] = .d# [.i]
        else
            .s# [.i] = 0
        endif
    endfor
    .itcsav = .iterc
    goto trs_L210

    # Set 2D search direction orthogonal to reduced D
    label trs_L120
    .iterc = .iterc + 1
    .temp = .gredsq * .dredsq - .dredg * .dredg
    if .temp <= .qred * 1e-4 * .qred
        goto trs_L190
    endif
    .temp = sqrt (.temp)
    for .i from 1 to .n
        if .xbdi# [.i] = 0
            .s# [.i] = (.dredg * .d# [.i] - .dredsq * .gnew# [.i]) / .temp
        else
            .s# [.i] = 0
        endif
    endfor
    .sredg = -.temp

    # Compute angbd (upper bound on tan(half-angle))
    .angbd = 1
    .iact = 0
    for .i from 1 to .n
        if .xbdi# [.i] = 0
            .tempa = .xOpt# [.i] + .d# [.i] - .sl# [.i]
            .tempb = .su# [.i] - .xOpt# [.i] - .d# [.i]
            if .tempa <= 0
                .nact = .nact + 1
                .xbdi# [.i] = -1
                goto trs_L100
            elsif .tempb <= 0
                .nact = .nact + 1
                .xbdi# [.i] = 1
                goto trs_L100
            endif
            .ssq = .d# [.i] * .d# [.i] + .s# [.i] * .s# [.i]
            .temp = .xOpt# [.i] - .sl# [.i]
            .temp = .ssq - .temp * .temp
            if .temp > 0
                .temp = sqrt (.temp) - .s# [.i]
                if .angbd * .temp > .tempa
                    .angbd = .tempa / .temp
                    .iact = .i
                    .xsav = -1
                endif
            endif
            .temp = .su# [.i] - .xOpt# [.i]
            .temp = .ssq - .temp * .temp
            if .temp > 0
                .temp = sqrt (.temp) + .s# [.i]
                if .angbd * .temp > .tempb
                    .angbd = .tempb / .temp
                    .iact = .i
                    .xsav = 1
                endif
            endif
        endif
    endfor
    goto trs_L210

    # Compute curvatures for alternative iteration
    label trs_L150
    .shs = 0
    .dhs = 0
    .dhd = 0
    for .i from 1 to .n
        if .xbdi# [.i] = 0
            .shs = .shs + .s# [.i] * .hs# [.i]
            .dhs = .dhs + .d# [.i] * .hs# [.i]
            .dhd = .dhd + .d# [.i] * .hred# [.i]
        endif
    endfor

    # Search for best angle
    .redmax = 0
    .isav = 0
    .redsav = 0
    .iu = floor (.angbd * 17.0 + 3.1)
    for .ii from 1 to .iu
        .angt = .angbd * .ii / .iu
        .sth = (.angt + .angt) / (1 + .angt * .angt)
        .temp = .shs + .angt * (.angt * .dhd - .dhs - .dhs)
        .rednew = .sth * (.angt * .dredg - .sredg - 0.5 * .sth * .temp)
        if .rednew > .redmax
            .redmax = .rednew
            .isav = .ii
            .rdprev = .redsav
        elsif .ii = .isav + 1
            .rdnext = .rednew
        endif
        .redsav = .rednew
    endfor
    if .isav = 0
        goto trs_L190
    endif
    if .isav < .iu
        .temp = (.rdnext - .rdprev) / (.redmax + .redmax - .rdprev - .rdnext)
        .angt = .angbd * (.isav + 0.5 * .temp) / .iu
    endif
    .cth = (1 - .angt * .angt) / (1 + .angt * .angt)
    .sth = (.angt + .angt) / (1 + .angt * .angt)
    .temp = .shs + .angt * (.angt * .dhd - .dhs - .dhs)
    .sdec = .sth * (.angt * .dredg - .sredg - 0.5 * .sth * .temp)
    if .sdec <= 0
        goto trs_L190
    endif

    # Update gnew, d, hred
    .dredg = 0
    .gredsq = 0
    for .i from 1 to .n
        .gnew# [.i] = .gnew# [.i] + (.cth - 1) * .hred# [.i] + .sth * .hs# [.i]
        if .xbdi# [.i] = 0
            .d# [.i] = .cth * .d# [.i] + .sth * .s# [.i]
            .dredg = .dredg + .d# [.i] * .gnew# [.i]
            .gredsq = .gredsq + .gnew# [.i] * .gnew# [.i]
        endif
        .hred# [.i] = .cth * .hred# [.i] + .sth * .hs# [.i]
    endfor
    .qred = .qred + .sdec
    if .iact > 0 and .isav = .iu
        .nact = .nact + 1
        .xbdi# [.iact] = .xsav
        goto trs_L100
    endif
    if .sdec > .qred * 0.01
        goto trs_L120
    endif

    # ---------- FINALIZE ----------
    label trs_L190
    .dsq = 0
    for .i from 1 to .n
        .temp = .xOpt# [.i] + .d# [.i]
        .temp = min (.temp, .su# [.i])
        .xnew# [.i] = max (.temp, .sl# [.i])
        if .xbdi# [.i] = -1
            .xnew# [.i] = .sl# [.i]
        endif
        if .xbdi# [.i] = 1
            .xnew# [.i] = .su# [.i]
        endif
        .d# [.i] = .xnew# [.i] - .xOpt# [.i]
        .dsq = .dsq + .d# [.i] * .d# [.i]
    endfor
    goto trs_done

    # ---------- HESSIAN-VECTOR PRODUCT: HS = H*S ----------
    label trs_L210
    for .j from 1 to .n
        .hs# [.j] = 0
        for .i from 1 to .j
            if .i < .j
                .hs# [.j] = .hs# [.j] + .hq## [.i, .j] * .s# [.i]
            endif
            .hs# [.i] = .hs# [.i] + .hq## [.i, .j] * .s# [.j]
        endfor
    endfor
    for .k from 1 to .npt
        if .pq# [.k] <> 0
            .temp = 0
            for .j from 1 to .n
                .temp = .temp + .xpt## [.k, .j] * .s# [.j]
            endfor
            .temp = .temp * .pq# [.k]
            for .i from 1 to .n
                .hs# [.i] = .hs# [.i] + .temp * .xpt## [.k, .i]
            endfor
        endif
    endfor
    # Route to appropriate continuation
    if .crvmin <> 0
        goto trs_L50
    endif
    if .iterc > .itcsav
        goto trs_L150
    endif
    for .i from 1 to .n
        .hred# [.i] = .hs# [.i]
    endfor
    goto trs_L120

    label trs_done
endproc

# ============================================================================
# @emlBOBYQAAltmov — Geometry improvement step
# Port of Powell's ALTMOV subroutine.
# ============================================================================
procedure emlBOBYQAAltmov: .n, .npt, .xpt##, .xOpt#, .bmat##, .zmat##,
    ... .sl#, .su#, .kopt, .knew, .adelt
    .ndim = .npt + .n
    .nptm = .npt - .n - 1
    .xnew# = zero# (.n)
    .xalt# = zero# (.n)
    .glag# = zero# (.n)
    .hcol# = zero# (.npt)
    .w# = zero# (2 * .n)
    .csave = 0
    .stpsav = 0
    .step = 0
    .ksav = 0
    .ibdsav = 0

    # Build KNEW-th column of H matrix (leading NPT elements)
    for .j from 1 to .nptm
        .temp = .zmat## [.knew, .j]
        for .k from 1 to .npt
            .hcol# [.k] = .hcol# [.k] + .temp * .zmat## [.k, .j]
        endfor
    endfor
    .alpha = .hcol# [.knew]
    .ha = 0.5 * .alpha

    # Gradient of KNEW-th Lagrange function at XOPT
    for .i from 1 to .n
        .glag# [.i] = .bmat## [.knew, .i]
    endfor
    for .k from 1 to .npt
        .temp = 0
        for .j from 1 to .n
            .temp = .temp + .xpt## [.k, .j] * .xOpt# [.j]
        endfor
        .temp = .hcol# [.k] * .temp
        for .i from 1 to .n
            .glag# [.i] = .glag# [.i] + .temp * .xpt## [.k, .i]
        endfor
    endfor

    # Search along lines through XOPT and each interpolation point
    .presav = 0
    for .k from 1 to .npt
        if .k = .kopt
            # skip
        else
            .dderiv = 0
            .distsq = 0
            for .i from 1 to .n
                .temp = .xpt## [.k, .i] - .xOpt# [.i]
                .dderiv = .dderiv + .glag# [.i] * .temp
                .distsq = .distsq + .temp * .temp
            endfor
            .subd = .adelt / sqrt (.distsq)
            .slbd = -.subd
            .ilbd = 0
            .iubd = 0
            .sumin = min (1, .subd)

            # Revise bounds for SL/SU constraints
            for .i from 1 to .n
                .temp = .xpt## [.k, .i] - .xOpt# [.i]
                if .temp > 0
                    if .slbd * .temp < .sl# [.i] - .xOpt# [.i]
                        .slbd = (.sl# [.i] - .xOpt# [.i]) / .temp
                        .ilbd = -.i
                    endif
                    if .subd * .temp > .su# [.i] - .xOpt# [.i]
                        .subd = (.su# [.i] - .xOpt# [.i]) / .temp
                        .subd = max (.subd, .sumin)
                        .iubd = .i
                    endif
                elsif .temp < 0
                    if .slbd * .temp > .su# [.i] - .xOpt# [.i]
                        .slbd = (.su# [.i] - .xOpt# [.i]) / .temp
                        .ilbd = .i
                    endif
                    if .subd * .temp < .sl# [.i] - .xOpt# [.i]
                        .subd = (.sl# [.i] - .xOpt# [.i]) / .temp
                        .subd = max (.subd, .sumin)
                        .iubd = -.i
                    endif
                endif
            endfor

            if .k = .knew
                .diff = .dderiv - 1
                .step = .slbd
                .vl = .slbd * (.dderiv - .slbd * .diff)
                .isbd = .ilbd
                .temp = .subd * (.dderiv - .subd * .diff)
                if abs (.temp) > abs (.vl)
                    .step = .subd
                    .vl = .temp
                    .isbd = .iubd
                endif
                .tempd = 0.5 * .dderiv
                .tempa = .tempd - .diff * .slbd
                .tempb = .tempd - .diff * .subd
                if .tempa * .tempb < 0
                    .temp = .tempd * .tempd / .diff
                    if abs (.temp) > abs (.vl)
                        .step = .tempd / .diff
                        .vl = .temp
                        .isbd = 0
                    endif
                endif
            else
                .step = .slbd
                .vl = .slbd * (1 - .slbd)
                .isbd = .ilbd
                .temp = .subd * (1 - .subd)
                if abs (.temp) > abs (.vl)
                    .step = .subd
                    .vl = .temp
                    .isbd = .iubd
                endif
                if .subd > 0.5
                    if abs (.vl) < 0.25
                        .step = 0.5
                        .vl = 0.25
                        .isbd = 0
                    endif
                endif
                .vl = .vl * .dderiv
            endif

            # Compute PREDSQ and maintain best
            .temp = .step * (1 - .step) * .distsq
            .predsq = .vl * .vl * (.vl * .vl + .ha * .temp * .temp)
            if .predsq > .presav
                .presav = .predsq
                .ksav = .k
                .stpsav = .step
                .ibdsav = .isbd
            endif
        endif
    endfor

    # Construct XNEW satisfying bound constraints
    for .i from 1 to .n
        .temp = .xOpt# [.i] + .stpsav * (.xpt## [.ksav, .i] - .xOpt# [.i])
        .temp = min (.temp, .su# [.i])
        .xnew# [.i] = max (.temp, .sl# [.i])
    endfor
    if .ibdsav < 0
        .xnew# [-.ibdsav] = .sl# [-.ibdsav]
    endif
    if .ibdsav > 0
        .xnew# [.ibdsav] = .su# [.ibdsav]
    endif

    # Compute constrained Cauchy step in w#
    .bigstp = .adelt + .adelt
    .iflag = 0
    .cauchy = 0
    label alt_cauchy_loop
    .wfixsq = 0
    .ggfree = 0
    for .i from 1 to .n
        .w# [.i] = 0
        .tempa = min (.xOpt# [.i] - .sl# [.i], .glag# [.i])
        .tempb = max (.xOpt# [.i] - .su# [.i], .glag# [.i])
        if .tempa > 0 or .tempb < 0
            .w# [.i] = .bigstp
            .ggfree = .ggfree + .glag# [.i] * .glag# [.i]
        endif
    endfor
    if .ggfree = 0
        .cauchy = 0
        goto alt_done
    endif

    # Fix more components of W
    label alt_fix_loop
    .temp = .adelt * .adelt - .wfixsq
    if .temp > 0
        .wsqsav = .wfixsq
        .step = sqrt (.temp / .ggfree)
        .ggfree = 0
        for .i from 1 to .n
            if .w# [.i] = .bigstp
                .temp = .xOpt# [.i] - .step * .glag# [.i]
                if .temp <= .sl# [.i]
                    .w# [.i] = .sl# [.i] - .xOpt# [.i]
                    .wfixsq = .wfixsq + .w# [.i] * .w# [.i]
                elsif .temp >= .su# [.i]
                    .w# [.i] = .su# [.i] - .xOpt# [.i]
                    .wfixsq = .wfixsq + .w# [.i] * .w# [.i]
                else
                    .ggfree = .ggfree + .glag# [.i] * .glag# [.i]
                endif
            endif
        endfor
        if .wfixsq > .wsqsav and .ggfree > 0
            goto alt_fix_loop
        endif
    endif

    # Set remaining free components and XALT
    .gw = 0
    for .i from 1 to .n
        if .w# [.i] = .bigstp
            .w# [.i] = -.step * .glag# [.i]
            .temp = .xOpt# [.i] + .w# [.i]
            .temp = min (.temp, .su# [.i])
            .xalt# [.i] = max (.temp, .sl# [.i])
        elsif .w# [.i] = 0
            .xalt# [.i] = .xOpt# [.i]
        elsif .glag# [.i] > 0
            .xalt# [.i] = .sl# [.i]
        else
            .xalt# [.i] = .su# [.i]
        endif
        .gw = .gw + .glag# [.i] * .w# [.i]
    endfor

    # Curvature of KNEW-th Lagrange function along W
    .curv = 0
    for .k from 1 to .npt
        .temp = 0
        for .j from 1 to .n
            .temp = .temp + .xpt## [.k, .j] * .w# [.j]
        endfor
        .curv = .curv + .hcol# [.k] * .temp * .temp
    endfor
    if .iflag = 1
        .curv = -.curv
    endif
    if .curv > -.gw and .curv < -(1 + sqrt (2)) * .gw
        .scale = -.gw / .curv
        for .i from 1 to .n
            .temp = .xOpt# [.i] + .scale * .w# [.i]
            .temp = min (.temp, .su# [.i])
            .xalt# [.i] = max (.temp, .sl# [.i])
        endfor
        .temp = 0.5 * .gw * .scale
        .cauchy = .temp * .temp
    else
        .temp = .gw + 0.5 * .curv
        .cauchy = .temp * .temp
    endif

    # Try reversed GLAG direction
    if .iflag = 0
        for .i from 1 to .n
            .glag# [.i] = -.glag# [.i]
            .w# [.n + .i] = .xalt# [.i]
        endfor
        .csave = .cauchy
        .iflag = 1
        goto alt_cauchy_loop
    endif

    if .csave > .cauchy
        for .i from 1 to .n
            .xalt# [.i] = .w# [.n + .i]
        endfor
        .cauchy = .csave
    endif

    label alt_done
endproc

# ============================================================================
# @emlBOBYQAInit — Initialize interpolation set and quadratic model
# Port of Powell's PRELIM subroutine.
# ============================================================================
procedure emlBOBYQAInit: .n, .npt, .objectiveProc$, .x#, .xl#, .xu#,
    ... .rhoBeg, .maxFun, .sl#, .su#
    .ndim = .npt + .n
    .np = .n + 1
    .nptm = .npt - .np
    .rhosq = .rhoBeg * .rhoBeg
    .recip = 1 / .rhosq
    .stepa = 0
    .stepb = 0
    .fbeg = 0
    .ipt = 0
    .jpt = 0

    # Initialize structures
    .xbase# = zero# (.n)
    .xpt## = zero## (.npt, .n)
    .fval# = zero# (.npt)
    .gopt# = zero# (.n)
    .hq## = zero## (.n, .n)
    .pq# = zero# (.npt)
    .bmat## = zero## (.ndim, .n)
    .zmat## = zero## (.npt, max (1, .nptm))
    .nf = 0
    .kopt = 1

    # Set XBASE to initial x
    for .j from 1 to .n
        .xbase# [.j] = .x# [.j]
    endfor

    # Build initial interpolation points and evaluate
    repeat
        .nfm = .nf
        .nfx = .nf - .n
        .nf = .nf + 1

        if .nfm <= 2 * .n
            if .nfm >= 1 and .nfm <= .n
                .stepa = .rhoBeg
                if .su# [.nfm] = 0
                    .stepa = -.stepa
                endif
                .xpt## [.nf, .nfm] = .stepa
            elsif .nfm > .n
                .stepa = .xpt## [.nf - .n, .nfx]
                .stepb = -.rhoBeg
                if .sl# [.nfx] = 0
                    .stepb = 2 * .rhoBeg
                    .stepb = min (.stepb, .su# [.nfx])
                endif
                if .su# [.nfx] = 0
                    .stepb = -2 * .rhoBeg
                    .stepb = max (.stepb, .sl# [.nfx])
                endif
                .xpt## [.nf, .nfx] = .stepb
            endif
        else
            .itemp = floor ((.nfm - .np) / .n)
            .jpt = .nfm - .itemp * .n - .n
            .ipt = .jpt + .itemp
            if .ipt > .n
                .itemp = .jpt
                .jpt = .ipt - .n
                .ipt = .itemp
            endif
            .xpt## [.nf, .ipt] = .xpt## [.ipt + 1, .ipt]
            .xpt## [.nf, .jpt] = .xpt## [.jpt + 1, .jpt]
        endif

        # Evaluate objective at new point
        for .j from 1 to .n
            .temp = .xbase# [.j] + .xpt## [.nf, .j]
            .temp = max (.temp, .xl# [.j])
            .x# [.j] = min (.temp, .xu# [.j])
            if .xpt## [.nf, .j] = .sl# [.j]
                .x# [.j] = .xl# [.j]
            endif
            if .xpt## [.nf, .j] = .su# [.j]
                .x# [.j] = .xu# [.j]
            endif
        endfor
        @'.objectiveProc$': .x#
        .f = '.objectiveProc$'.value
        .fval# [.nf] = .f
        if .nf = 1
            .fbeg = .f
            .kopt = 1
        elsif .f < .fval# [.kopt]
            .kopt = .nf
        endif

        # Set BMAT, ZMAT, GOPT, HQ elements
        if .nf <= 2 * .n + 1
            if .nf >= 2 and .nf <= .n + 1
                .gopt# [.nfm] = (.f - .fbeg) / .stepa
                if .npt < .nf + .n
                    .bmat## [1, .nfm] = -1 / .stepa
                    .bmat## [.nf, .nfm] = 1 / .stepa
                    .bmat## [.npt + .nfm, .nfm] = -0.5 * .rhosq
                endif
            elsif .nf >= .n + 2
                .temp = (.f - .fbeg) / .stepb
                .diff = .stepb - .stepa
                .hq## [.nfx, .nfx] = 2 * (.temp - .gopt# [.nfx]) / .diff
                .gopt# [.nfx] = (.gopt# [.nfx] * .stepb - .temp * .stepa) / .diff
                if .stepa * .stepb < 0
                    if .f < .fval# [.nf - .n]
                        .fval# [.nf] = .fval# [.nf - .n]
                        .fval# [.nf - .n] = .f
                        if .kopt = .nf
                            .kopt = .nf - .n
                        endif
                        .xpt## [.nf - .n, .nfx] = .stepb
                        .xpt## [.nf, .nfx] = .stepa
                    endif
                endif
                .bmat## [1, .nfx] = -(.stepa + .stepb) / (.stepa * .stepb)
                .bmat## [.nf, .nfx] = -0.5 / .xpt## [.nf - .n, .nfx]
                .bmat## [.nf - .n, .nfx] = -.bmat## [1, .nfx] - .bmat## [.nf, .nfx]
                .zmat## [1, .nfx] = sqrt (2) / (.stepa * .stepb)
                .zmat## [.nf, .nfx] = sqrt (0.5) / .rhosq
                .zmat## [.nf - .n, .nfx] = -.zmat## [1, .nfx] - .zmat## [.nf, .nfx]
            endif
        else
            # Off-diagonal second derivatives
            .ih_row = min (.jpt, .ipt)
            .ih_col = max (.jpt, .ipt)
            .temp = .xpt## [.nf, .ipt] * .xpt## [.nf, .jpt]
            .hq## [.ih_row, .ih_col] = (.fbeg - .fval# [.ipt + 1]
                ... - .fval# [.jpt + 1] + .f) / .temp
            .hq## [.ih_col, .ih_row] = .hq## [.ih_row, .ih_col]
            .zmat## [1, .nfx] = .recip
            .zmat## [.nf, .nfx] = .recip
            .zmat## [.ipt + 1, .nfx] = -.recip
            .zmat## [.jpt + 1, .nfx] = -.recip
        endif
    until .nf >= .npt or .nf >= .maxFun
endproc

# ============================================================================
# @emlBOBYQARescue — Recovery when conditioning degrades
# Port of Powell's RESCUE subroutine. Called rarely.
# ============================================================================
procedure emlBOBYQARescue: .n, .npt, .objectiveProc$, .xl#, .xu#, .maxFun,
    ... .xbase#, .xpt##, .fval#, .xOpt#, .gopt#, .hq##, .pq#,
    ... .bmat##, .zmat##, .sl#, .su#, .nf, .delta, .kopt
    .ndim = .npt + .n
    .np = .n + 1
    .nptm = .npt - .np
    .sfrac = 0.5 / .np
    .beta = 0
    .denom = 0
    .ptsaux## = zero## (2, .n)
    .ptsid# = zero# (.npt)
    .vlag# = zero# (.ndim)
    .w# = zero# (.ndim + .npt)

    # Shift interpolation points so XOPT is origin; zero ZMAT
    .sumpq = 0
    .winc = 0
    for .k from 1 to .npt
        .distsq = 0
        for .j from 1 to .n
            .xpt## [.k, .j] = .xpt## [.k, .j] - .xOpt# [.j]
            .distsq = .distsq + .xpt## [.k, .j] * .xpt## [.k, .j]
        endfor
        .sumpq = .sumpq + .pq# [.k]
        .w# [.ndim + .k] = .distsq
        .winc = max (.winc, .distsq)
        for .j from 1 to .nptm
            .zmat## [.k, .j] = 0
        endfor
    endfor

    # Update HQ for XBASE shift to trust region center
    for .j from 1 to .n
        .w# [.j] = 0.5 * .sumpq * .xOpt# [.j]
        for .k from 1 to .npt
            .w# [.j] = .w# [.j] + .pq# [.k] * .xpt## [.k, .j]
        endfor
        for .i from 1 to .j
            .hq## [.i, .j] = .hq## [.i, .j] + .w# [.i] * .xOpt# [.j]
                ... + .w# [.j] * .xOpt# [.i]
            .hq## [.j, .i] = .hq## [.i, .j]
        endfor
    endfor

    # Shift XBASE, SL, SU, XOPT; set PTSAUX; zero BMAT
    .fbase = .fval# [.kopt]
    for .j from 1 to .n
        .xbase# [.j] = .xbase# [.j] + .xOpt# [.j]
        .sl# [.j] = .sl# [.j] - .xOpt# [.j]
        .su# [.j] = .su# [.j] - .xOpt# [.j]
        .xOpt# [.j] = 0
        .ptsaux## [1, .j] = min (.delta, .su# [.j])
        .ptsaux## [2, .j] = max (-.delta, .sl# [.j])
        if .ptsaux## [1, .j] + .ptsaux## [2, .j] < 0
            .temp = .ptsaux## [1, .j]
            .ptsaux## [1, .j] = .ptsaux## [2, .j]
            .ptsaux## [2, .j] = .temp
        endif
        if abs (.ptsaux## [2, .j]) < 0.5 * abs (.ptsaux## [1, .j])
            .ptsaux## [2, .j] = 0.5 * .ptsaux## [1, .j]
        endif
        for .i from 1 to .ndim
            .bmat## [.i, .j] = 0
        endfor
    endfor

    # Set provisional interpolation point identifiers
    .ptsid# [1] = .sfrac
    for .j from 1 to .n
        .jp = .j + 1
        .jpn = .jp + .n
        .ptsid# [.jp] = .j + .sfrac
        if .jpn <= .npt
            .ptsid# [.jpn] = .j / .np + .sfrac
            .temp = 1 / (.ptsaux## [1, .j] - .ptsaux## [2, .j])
            .bmat## [.jp, .j] = -.temp + 1 / .ptsaux## [1, .j]
            .bmat## [.jpn, .j] = .temp + 1 / .ptsaux## [2, .j]
            .bmat## [1, .j] = -.bmat## [.jp, .j] - .bmat## [.jpn, .j]
            .zmat## [1, .j] = sqrt (2) / abs (.ptsaux## [1, .j] * .ptsaux## [2, .j])
            .zmat## [.jp, .j] = .zmat## [1, .j] * .ptsaux## [2, .j] * .temp
            .zmat## [.jpn, .j] = -.zmat## [1, .j] * .ptsaux## [1, .j] * .temp
        else
            .bmat## [1, .j] = -1 / .ptsaux## [1, .j]
            .bmat## [.jp, .j] = 1 / .ptsaux## [1, .j]
            .bmat## [.j + .npt, .j] = -0.5 * (.ptsaux## [1, .j] * .ptsaux## [1, .j])
        endif
    endfor

    # Set remaining identifiers with ZMAT elements
    if .npt >= .n + .np
        for .k from 2 * .np to .npt
            .iw = floor ((.k - .np - 0.5) / .n)
            .ip = .k - .np - .iw * .n
            .iq = .ip + .iw
            if .iq > .n
                .iq = .iq - .n
            endif
            .ptsid# [.k] = .ip + .iq / .np + .sfrac
            .temp = 1 / (.ptsaux## [1, .ip] * .ptsaux## [1, .iq])
            .zmat## [1, .k - .np] = .temp
            .zmat## [.ip + 1, .k - .np] = -.temp
            .zmat## [.iq + 1, .k - .np] = -.temp
            .zmat## [.k, .k - .np] = .temp
        endfor
    endif

    .nrem = .npt
    .kold = 1
    .knew = .kopt

    # ---------- REORDER LOOP ----------
    label rsc_L80
    for .j from 1 to .n
        .temp = .bmat## [.kold, .j]
        .bmat## [.kold, .j] = .bmat## [.knew, .j]
        .bmat## [.knew, .j] = .temp
    endfor
    for .j from 1 to .nptm
        .temp = .zmat## [.kold, .j]
        .zmat## [.kold, .j] = .zmat## [.knew, .j]
        .zmat## [.knew, .j] = .temp
    endfor
    .ptsid# [.kold] = .ptsid# [.knew]
    .ptsid# [.knew] = 0
    .w# [.ndim + .knew] = 0
    .nrem = .nrem - 1
    if .knew <> .kopt
        .temp = .vlag# [.kold]
        .vlag# [.kold] = .vlag# [.knew]
        .vlag# [.knew] = .temp

        # Call UPDATE
        @emlBOBYQAUpdate: .n, .npt, .bmat##, .zmat##, .vlag#,
            ... .beta, .denom, .knew
        .bmat## = emlBOBYQAUpdate.bmat##
        .zmat## = emlBOBYQAUpdate.zmat##
        .vlag# = emlBOBYQAUpdate.vlag#
        if .nrem = 0
            goto rsc_L350
        endif
        for .k from 1 to .npt
            .w# [.ndim + .k] = abs (.w# [.ndim + .k])
        endfor
    endif

    # Pick original interpolation point to reinstate
    label rsc_L120
    .dsqmin = 0
    for .k from 1 to .npt
        if .w# [.ndim + .k] > 0
            if .dsqmin = 0 or .w# [.ndim + .k] < .dsqmin
                .knew = .k
                .dsqmin = .w# [.ndim + .k]
            endif
        endif
    endfor
    if .dsqmin = 0
        goto rsc_L260
    endif

    # Form W-vector of the chosen point
    for .j from 1 to .n
        .w# [.npt + .j] = .xpt## [.knew, .j]
    endfor
    for .k from 1 to .npt
        .sum = 0
        if .k = .kopt
            # skip
        elsif .ptsid# [.k] = 0
            for .j from 1 to .n
                .sum = .sum + .w# [.npt + .j] * .xpt## [.k, .j]
            endfor
        else
            .ip = floor (.ptsid# [.k])
            if .ip > 0
                .sum = .w# [.npt + .ip] * .ptsaux## [1, .ip]
            endif
            .iq = floor (.np * .ptsid# [.k] - .ip * .np)
            if .iq > 0
                .iw2 = 1
                if .ip = 0
                    .iw2 = 2
                endif
                .sum = .sum + .w# [.npt + .iq] * .ptsaux## [.iw2, .iq]
            endif
        endif
        .w# [.k] = 0.5 * .sum * .sum
    endfor

    # Calculate VLAG and BETA for reinstating XPT(KNEW,.)
    for .k from 1 to .npt
        .sum = 0
        for .j from 1 to .n
            .sum = .sum + .bmat## [.k, .j] * .w# [.npt + .j]
        endfor
        .vlag# [.k] = .sum
    endfor
    .beta = 0
    for .j from 1 to .nptm
        .sum = 0
        for .k from 1 to .npt
            .sum = .sum + .zmat## [.k, .j] * .w# [.k]
        endfor
        .beta = .beta - .sum * .sum
        for .k from 1 to .npt
            .vlag# [.k] = .vlag# [.k] + .sum * .zmat## [.k, .j]
        endfor
    endfor
    .bsum = 0
    .distsq = 0
    for .j from 1 to .n
        .sum = 0
        for .k from 1 to .npt
            .sum = .sum + .bmat## [.k, .j] * .w# [.k]
        endfor
        .jp = .j + .npt
        .bsum = .bsum + .sum * .w# [.jp]
        for .ip2 from .npt + 1 to .ndim
            .sum = .sum + .bmat## [.ip2, .j] * .w# [.ip2]
        endfor
        .bsum = .bsum + .sum * .w# [.jp]
        .vlag# [.jp] = .sum
        .distsq = .distsq + .xpt## [.knew, .j] * .xpt## [.knew, .j]
    endfor
    .beta = 0.5 * .distsq * .distsq + .beta - .bsum
    .vlag# [.kopt] = .vlag# [.kopt] + 1

    # Choose KOLD (provisional point to replace)
    .denom = 0
    .vlmxsq = 0
    for .k from 1 to .npt
        if .ptsid# [.k] <> 0
            .hdiag = 0
            for .j from 1 to .nptm
                .hdiag = .hdiag + .zmat## [.k, .j] * .zmat## [.k, .j]
            endfor
            .den = .beta * .hdiag + .vlag# [.k] * .vlag# [.k]
            if .den > .denom
                .kold = .k
                .denom = .den
            endif
        endif
        .temp = .vlag# [.k] * .vlag# [.k]
        .vlmxsq = max (.vlmxsq, .temp)
    endfor
    if .denom <= .vlmxsq * 0.01
        .w# [.ndim + .knew] = -.w# [.ndim + .knew] - .winc
        goto rsc_L120
    endif
    goto rsc_L80

    # ---------- FINALIZE: update model with new points ----------
    label rsc_L260
    for .kpt from 1 to .npt
        if .ptsid# [.kpt] = 0
            # skip (already reinstated)
        else
            if .nf >= .maxFun
                .nf = -1
                goto rsc_L350
            endif
            # Update HQ for removal of old point
            for .j from 1 to .n
                .w# [.j] = .xpt## [.kpt, .j]
                .xpt## [.kpt, .j] = 0
            endfor
            .temp_pq = .pq# [.kpt]
            for .j from 1 to .n
                for .i from 1 to .j
                    .hq## [.i, .j] = .hq## [.i, .j] + .temp_pq * .w# [.i] * .w# [.j]
                    .hq## [.j, .i] = .hq## [.i, .j]
                endfor
            endfor
            .pq# [.kpt] = 0

            # Set new interpolation point
            .ip = floor (.ptsid# [.kpt])
            .iq = floor (.np * .ptsid# [.kpt] - .ip * .np)
            .xp = 0
            .xq = 0
            if .ip > 0
                .xp = .ptsaux## [1, .ip]
                .xpt## [.kpt, .ip] = .xp
            endif
            if .iq > 0
                .xq = .ptsaux## [1, .iq]
                if .ip = 0
                    .xq = .ptsaux## [2, .iq]
                endif
                .xpt## [.kpt, .iq] = .xq
            endif

            # Compute model value at new point
            .vquad = .fbase
            if .ip > 0
                .vquad = .vquad + .xp * (.gopt# [.ip] + 0.5 * .xp * .hq## [.ip, .ip])
            endif
            if .iq > 0
                .vquad = .vquad + .xq * (.gopt# [.iq] + 0.5 * .xq * .hq## [.iq, .iq])
                if .ip > 0
                    .vquad = .vquad + .xp * .xq * .hq## [.ip, .iq]
                endif
            endif
            for .k from 1 to .npt
                .temp = 0
                if .ip > 0
                    .temp = .temp + .xp * .xpt## [.k, .ip]
                endif
                if .iq > 0
                    .temp = .temp + .xq * .xpt## [.k, .iq]
                endif
                .vquad = .vquad + 0.5 * .pq# [.k] * .temp * .temp
            endfor

            # Evaluate objective
            for .i from 1 to .n
                .temp = .xbase# [.i] + .xpt## [.kpt, .i]
                .temp = max (.temp, .xl# [.i])
                .w# [.i] = min (.temp, .xu# [.i])
                if .xpt## [.kpt, .i] = .sl# [.i]
                    .w# [.i] = .xl# [.i]
                endif
                if .xpt## [.kpt, .i] = .su# [.i]
                    .w# [.i] = .xu# [.i]
                endif
            endfor
            .nf = .nf + 1
            @'.objectiveProc$': .w#
            .f = '.objectiveProc$'.value
            .fval# [.kpt] = .f
            if .f < .fval# [.kopt]
                .kopt = .kpt
            endif
            .diff = .f - .vquad

            # Update gradient and implicit Hessian
            for .i from 1 to .n
                .gopt# [.i] = .gopt# [.i] + .diff * .bmat## [.kpt, .i]
            endfor
            for .k from 1 to .npt
                .sum = 0
                for .j from 1 to .nptm
                    .sum = .sum + .zmat## [.k, .j] * .zmat## [.kpt, .j]
                endfor
                .temp = .diff * .sum
                if .ptsid# [.k] = 0
                    .pq# [.k] = .pq# [.k] + .temp
                else
                    .ip2 = floor (.ptsid# [.k])
                    .iq2 = floor (.np * .ptsid# [.k] - .ip2 * .np)
                    if .ip2 = 0
                        .hq## [.iq2, .iq2] = .hq## [.iq2, .iq2]
                            ... + .temp * (.ptsaux## [2, .iq2] * .ptsaux## [2, .iq2])
                    else
                        .hq## [.ip2, .ip2] = .hq## [.ip2, .ip2]
                            ... + .temp * (.ptsaux## [1, .ip2] * .ptsaux## [1, .ip2])
                        if .iq2 > 0
                            .hq## [.iq2, .iq2] = .hq## [.iq2, .iq2]
                                ... + .temp * (.ptsaux## [1, .iq2] * .ptsaux## [1, .iq2])
                            .hq## [.ip2, .iq2] = .hq## [.ip2, .iq2]
                                ... + .temp * .ptsaux## [1, .ip2] * .ptsaux## [1, .iq2]
                            .hq## [.iq2, .ip2] = .hq## [.ip2, .iq2]
                        endif
                    endif
                endif
            endfor
            .ptsid# [.kpt] = 0
        endif
    endfor

    label rsc_L350
endproc

# ============================================================================
# @emlBOBYQA — Bound Optimization BY Quadratic Approximation
# Faithful port of Powell (2009) from C reference by É. Thiébaut.

#
# Input:
#   .objectiveProc$  — name of objective procedure
#   .x0#             — initial point (d-vector)
#   .lower#          — lower bounds (-1e30 for unbounded)
#   .upper#          — upper bounds (1e30 for unbounded)
#   .rhoBeg          — initial trust region radius
#   .rhoEnd          — final TR radius (convergence tolerance)
#   .maxEval         — maximum function evaluations
#   .npt             — interpolation points (0 = auto = 2d+1)
#
# Output: same as @emlNelderMead
#   .xOpt#, .fOpt, .nEval, .convergence, .error$
# ============================================================================
procedure emlBOBYQA: .objectiveProc$, .x0#, .lower#, .upper#,
    ... .rhoBeg, .rhoEnd, .maxEval, .npt
    .d = size (.x0#)
    .error$ = ""
    .nEval = 0
    .convergence = 1

    # Validate and set npt
    .nptMin = .d + 2
    .nptMax = (.d + 1) * (.d + 2) / 2
    if .npt < .nptMin or .npt > .nptMax
        .npt = 2 * .d + 1
        if .npt > .nptMax
            .npt = .nptMax
        endif
    endif

    .n = .d
    .np = .n + 1
    .ndim = .npt + .n
    .nptm = .npt - .np

    # Set up initial x, sl, su (from bobyqa() driver)
    .x# = .x0#
    .sl# = zero# (.n)
    .su# = zero# (.n)
    for .j from 1 to .n
        .temp = .upper# [.j] - .lower# [.j]
        if .temp < .rhoBeg + .rhoBeg
            .error$ = "Bounds too close: upper-lower < 2*rhoBeg"
            .xOpt# = .x0#
            .fOpt = undefined
            goto bob_exit
        endif
        .sl# [.j] = .lower# [.j] - .x# [.j]
        .su# [.j] = .upper# [.j] - .x# [.j]
        if .sl# [.j] >= -.rhoBeg
            if .sl# [.j] >= 0
                .x# [.j] = .lower# [.j]
                .sl# [.j] = 0
                .su# [.j] = .temp
            else
                .x# [.j] = .lower# [.j] + .rhoBeg
                .sl# [.j] = -.rhoBeg
                .temp = .upper# [.j] - .x# [.j]
                .su# [.j] = max (.temp, .rhoBeg)
            endif
        elsif .su# [.j] <= .rhoBeg
            if .su# [.j] <= 0
                .x# [.j] = .upper# [.j]
                .sl# [.j] = -.temp
                .su# [.j] = 0
            else
                .x# [.j] = .upper# [.j] - .rhoBeg
                .tempa = .lower# [.j] - .x# [.j]
                .tempb = -.rhoBeg
                .sl# [.j] = min (.tempa, .tempb)
                .su# [.j] = .rhoBeg
            endif
        endif
    endfor

    # Call PRELIM
    @emlBOBYQAInit: .n, .npt, .objectiveProc$, .x#, .lower#, .upper#,
        ... .rhoBeg, .maxEval, .sl#, .su#
    .xbase# = emlBOBYQAInit.xbase#
    .xpt## = emlBOBYQAInit.xpt##
    .fval# = emlBOBYQAInit.fval#
    .gopt# = emlBOBYQAInit.gopt#
    .hq## = emlBOBYQAInit.hq##
    .pq# = emlBOBYQAInit.pq#
    .bmat## = emlBOBYQAInit.bmat##
    .zmat## = emlBOBYQAInit.zmat##
    .nf = emlBOBYQAInit.nf
    .kopt = emlBOBYQAInit.kopt
    .x# = emlBOBYQAInit.x#

    .xoptCur# = zero# (.n)
    .xoptsq = 0
    for .i from 1 to .n
        .xoptCur# [.i] = .xpt## [.kopt, .i]
        .xoptsq = .xoptsq + .xoptCur# [.i] * .xoptCur# [.i]
    endfor
    .fsave = .fval# [1]

    if .nf < .npt
        .error$ = "Too many evaluations during initialization"
        .convergence = 1
        goto bob_finalize
    endif

    .kbase = 1
    .rho = .rhoBeg
    .delta = .rho
    .nresc = .nf
    .ntrits = 0
    .diffa = 0
    .diffb = 0
    .diffc = 0
    .itest = 0
    .nfsav = .nf

    # Work vectors
    .xnew# = zero# (.n)
    .xalt# = zero# (.n)
    .dv# = zero# (.n)
    .vlag# = zero# (.ndim)
    .w# = zero# (3 * .ndim)

    .adelt = 0
    .alpha = 0
    .cauchy = 0
    .denom = 0
    .diff = 0
    .knew = 0
    .dsq = 0

    # ======== L20: Update GOPT if needed ========
    label bob_L20
    if .kopt <> .kbase
        for .j from 1 to .n
            for .i from 1 to .j
                if .i < .j
                    .gopt# [.j] = .gopt# [.j] + .hq## [.i, .j] * .xoptCur# [.i]
                endif
                .gopt# [.i] = .gopt# [.i] + .hq## [.i, .j] * .xoptCur# [.j]
            endfor
        endfor
        if .nf > .npt
            for .k from 1 to .npt
                .temp = 0
                for .j from 1 to .n
                    .temp = .temp + .xpt## [.k, .j] * .xoptCur# [.j]
                endfor
                .temp = .pq# [.k] * .temp
                for .i from 1 to .n
                    .gopt# [.i] = .gopt# [.i] + .temp * .xpt## [.k, .i]
                endfor
            endfor
        endif
    endif

    # ======== L60: Trust region step ========
    label bob_L60
    @emlBOBYQATrsbox: .n, .npt, .xpt##, .xoptCur#, .gopt#, .hq##,
        ... .pq#, .sl#, .su#, .delta
    .xnew# = emlBOBYQATrsbox.xnew#
    .dv# = emlBOBYQATrsbox.d#
    .dsq = emlBOBYQATrsbox.dsq
    .crvmin = emlBOBYQATrsbox.crvmin
    .dnorm = sqrt (.dsq)
    .dnorm = min (.dnorm, .delta)
    if .dnorm < 0.5 * .rho
        .ntrits = -1
        .tempa = 10 * .rho
        .distsq = .tempa * .tempa
        if .nf <= .nfsav + 2
            goto bob_L650
        endif
        .errbig = max (.diffa, .diffb)
        .errbig = max (.errbig, .diffc)
        .frhosq = .rho * 0.125 * .rho
        if .crvmin > 0 and .errbig > .frhosq * .crvmin
            goto bob_L650
        endif
        .bdtol = .errbig / .rho
        for .j from 1 to .n
            .bdtest = .bdtol
            if .xnew# [.j] = .sl# [.j]
                .bdtest = .w# [.j]
            endif
            if .xnew# [.j] = .su# [.j]
                .bdtest = -.w# [.j]
            endif
            if .bdtest < .bdtol
                .curv = .hq## [.j, .j]
                for .k from 1 to .npt
                    .curv = .curv + .pq# [.k] * (.xpt## [.k, .j] * .xpt## [.k, .j])
                endfor
                .bdtest = .bdtest + 0.5 * .curv * .rho
                if .bdtest < .bdtol
                    goto bob_L650
                endif
            endif
        endfor
        goto bob_L680
    endif
    .ntrits = .ntrits + 1

    # ======== L90: Check XBASE shift ========
    label bob_L90
    if .dsq <= .xoptsq * 0.001
        .fracsq = .xoptsq * 0.25
        .sumpq = 0
        for .k from 1 to .npt
            .sumpq = .sumpq + .pq# [.k]
            .sum = -0.5 * .xoptsq
            for .i from 1 to .n
                .sum = .sum + .xpt## [.k, .i] * .xoptCur# [.i]
            endfor
            .w# [.npt + .k] = .sum
            .temp = .fracsq - 0.5 * .sum
            for .i from 1 to .n
                .w# [.i] = .bmat## [.k, .i]
                .vlag# [.i] = .sum * .xpt## [.k, .i] + .temp * .xoptCur# [.i]
                .ip = .npt + .i
                for .j from 1 to .i
                    .bmat## [.ip, .j] = .bmat## [.ip, .j]
                        ... + .w# [.i] * .vlag# [.j] + .vlag# [.i] * .w# [.j]
                endfor
            endfor
        endfor

        # Revisions of BMAT that depend on ZMAT
        for .jj from 1 to .nptm
            .sumz = 0
            .sumw = 0
            for .k from 1 to .npt
                .sumz = .sumz + .zmat## [.k, .jj]
                .vlag# [.k] = .w# [.npt + .k] * .zmat## [.k, .jj]
                .sumw = .sumw + .vlag# [.k]
            endfor
            for .j from 1 to .n
                .sum = (.fracsq * .sumz - 0.5 * .sumw) * .xoptCur# [.j]
                for .k from 1 to .npt
                    .sum = .sum + .vlag# [.k] * .xpt## [.k, .j]
                endfor
                .w# [.j] = .sum
                for .k from 1 to .npt
                    .bmat## [.k, .j] = .bmat## [.k, .j] + .sum * .zmat## [.k, .jj]
                endfor
            endfor
            for .i from 1 to .n
                .ip = .i + .npt
                .temp = .w# [.i]
                for .j from 1 to .i
                    .bmat## [.ip, .j] = .bmat## [.ip, .j] + .temp * .w# [.j]
                endfor
            endfor
        endfor

        # Complete shift
        for .j from 1 to .n
            .w# [.j] = -0.5 * .sumpq * .xoptCur# [.j]
            for .k from 1 to .npt
                .w# [.j] = .w# [.j] + .pq# [.k] * .xpt## [.k, .j]
                .xpt## [.k, .j] = .xpt## [.k, .j] - .xoptCur# [.j]
            endfor
            for .i from 1 to .j
                .hq## [.i, .j] = .hq## [.i, .j]
                    ... + .w# [.i] * .xoptCur# [.j] + .xoptCur# [.i] * .w# [.j]
                .hq## [.j, .i] = .hq## [.i, .j]
                .bmat## [.npt + .i, .j] = .bmat## [.npt + .j, .i]
            endfor
        endfor
        for .i from 1 to .n
            .xbase# [.i] = .xbase# [.i] + .xoptCur# [.i]
            .xnew# [.i] = .xnew# [.i] - .xoptCur# [.i]
            .sl# [.i] = .sl# [.i] - .xoptCur# [.i]
            .su# [.i] = .su# [.i] - .xoptCur# [.i]
            .xoptCur# [.i] = 0
        endfor
        .xoptsq = 0
    endif

    if .ntrits = 0
        goto bob_L210
    endif
    goto bob_L230

    # ======== L190: Call RESCUE ========
    label bob_L190
    .nfsav = .nf
    .kbase = .kopt
    @emlBOBYQARescue: .n, .npt, .objectiveProc$, .lower#, .upper#, .maxEval,
        ... .xbase#, .xpt##, .fval#, .xoptCur#, .gopt#, .hq##, .pq#,
        ... .bmat##, .zmat##, .sl#, .su#, .nf, .delta, .kopt
    .xbase# = emlBOBYQARescue.xbase#
    .xpt## = emlBOBYQARescue.xpt##
    .fval# = emlBOBYQARescue.fval#
    .xoptCur# = emlBOBYQARescue.xOpt#
    .gopt# = emlBOBYQARescue.gopt#
    .hq## = emlBOBYQARescue.hq##
    .pq# = emlBOBYQARescue.pq#
    .bmat## = emlBOBYQARescue.bmat##
    .zmat## = emlBOBYQARescue.zmat##
    .sl# = emlBOBYQARescue.sl#
    .su# = emlBOBYQARescue.su#
    .nf = emlBOBYQARescue.nf
    .kopt = emlBOBYQARescue.kopt

    .xoptsq = 0
    if .kopt <> .kbase
        for .i from 1 to .n
            .xoptCur# [.i] = .xpt## [.kopt, .i]
            .xoptsq = .xoptsq + .xoptCur# [.i] * .xoptCur# [.i]
        endfor
    endif
    if .nf < 0
        .nf = .maxEval
        goto bob_maxfun
    endif
    .nresc = .nf
    if .nfsav < .nf
        .nfsav = .nf
        goto bob_L20
    endif
    if .ntrits > 0
        goto bob_L60
    endif

    # ======== L210: Geometry improvement (ALTMOV) ========
    label bob_L210
    @emlBOBYQAAltmov: .n, .npt, .xpt##, .xoptCur#, .bmat##, .zmat##,
        ... .sl#, .su#, .kopt, .knew, .adelt
    .xnew# = emlBOBYQAAltmov.xnew#
    .xalt# = emlBOBYQAAltmov.xalt#
    .alpha = emlBOBYQAAltmov.alpha
    .cauchy = emlBOBYQAAltmov.cauchy
    for .i from 1 to .n
        .dv# [.i] = .xnew# [.i] - .xoptCur# [.i]
    endfor

    # ======== L230: Compute VLAG and BETA ========
    label bob_L230
    for .k from 1 to .npt
        .suma = 0
        .sumb = 0
        .sum = 0
        for .j from 1 to .n
            .suma = .suma + .xpt## [.k, .j] * .dv# [.j]
            .sumb = .sumb + .xpt## [.k, .j] * .xoptCur# [.j]
            .sum = .sum + .bmat## [.k, .j] * .dv# [.j]
        endfor
        .w# [.k] = .suma * (0.5 * .suma + .sumb)
        .vlag# [.k] = .sum
        .w# [.npt + .k] = .suma
    endfor
    .beta_up = 0
    for .jj from 1 to .nptm
        .sum = 0
        for .k from 1 to .npt
            .sum = .sum + .zmat## [.k, .jj] * .w# [.k]
        endfor
        .beta_up = .beta_up - .sum * .sum
        for .k from 1 to .npt
            .vlag# [.k] = .vlag# [.k] + .sum * .zmat## [.k, .jj]
        endfor
    endfor
    .dsq = 0
    .bsum = 0
    .dx = 0
    for .j from 1 to .n
        .dsq = .dsq + .dv# [.j] * .dv# [.j]
        .sum = 0
        for .k from 1 to .npt
            .sum = .sum + .w# [.k] * .bmat## [.k, .j]
        endfor
        .bsum = .bsum + .sum * .dv# [.j]
        .jp = .npt + .j
        for .i from 1 to .n
            .sum = .sum + .bmat## [.jp, .i] * .dv# [.i]
        endfor
        .vlag# [.jp] = .sum
        .bsum = .bsum + .sum * .dv# [.j]
        .dx = .dx + .dv# [.j] * .xoptCur# [.j]
    endfor
    .beta_up = .dx * .dx + .dsq * (.xoptsq + .dx + .dx + 0.5 * .dsq)
        ... + .beta_up - .bsum
    .vlag# [.kopt] = .vlag# [.kopt] + 1

    # Denominator selection
    if .ntrits = 0
        .denom = .vlag# [.knew] * .vlag# [.knew] + .alpha * .beta_up
        if .denom < .cauchy and .cauchy > 0
            for .i from 1 to .n
                .xnew# [.i] = .xalt# [.i]
                .dv# [.i] = .xnew# [.i] - .xoptCur# [.i]
            endfor
            .cauchy = 0
            goto bob_L230
        endif
        if .denom <= 0.5 * (.vlag# [.knew] * .vlag# [.knew])
            if .nf > .nresc
                goto bob_L190
            endif
            goto bob_cancel
        endif
    else
        .delsq = .delta * .delta
        .scaden = 0
        .biglsq = 0
        .knew = 0
        for .k from 1 to .npt
            if .k <> .kopt
                .hdiag = 0
                for .jj from 1 to .nptm
                    .hdiag = .hdiag + .zmat## [.k, .jj] * .zmat## [.k, .jj]
                endfor
                .den = .beta_up * .hdiag + .vlag# [.k] * .vlag# [.k]
                .distsq = 0
                for .j from 1 to .n
                    .tempa = .xpt## [.k, .j] - .xoptCur# [.j]
                    .distsq = .distsq + .tempa * .tempa
                endfor
                .temp = .distsq / .delsq
                .temp = .temp * .temp
                .temp = max (1, .temp)
                if .temp * .den > .scaden
                    .scaden = .temp * .den
                    .knew = .k
                    .denom = .den
                endif
                .temp = .temp * .vlag# [.k] * .vlag# [.k]
                .biglsq = max (.biglsq, .temp)
            endif
        endfor
        if .scaden <= 0.5 * .biglsq
            if .nf > .nresc
                goto bob_L190
            endif
            goto bob_cancel
        endif
    endif

    # ======== L360: Evaluate objective ========
    label bob_L360
    for .i from 1 to .n
        .tempa = .xbase# [.i] + .xnew# [.i]
        .tempa = max (.tempa, .lower# [.i])
        .x# [.i] = min (.tempa, .upper# [.i])
        if .xnew# [.i] = .sl# [.i]
            .x# [.i] = .lower# [.i]
        endif
        if .xnew# [.i] = .su# [.i]
            .x# [.i] = .upper# [.i]
        endif
    endfor
    if .nf >= .maxEval
        goto bob_maxfun
    endif
    .nf = .nf + 1
    @'.objectiveProc$': .x#
    .f = '.objectiveProc$'.value
    if .ntrits = -1
        .fsave = .f
        goto bob_done
    endif

    # Quadratic model prediction
    .fopt = .fval# [.kopt]
    .vquad = 0
    for .j from 1 to .n
        .vquad = .vquad + .dv# [.j] * .gopt# [.j]
        for .i from 1 to .j
            .temp = .dv# [.i] * .dv# [.j]
            if .i = .j
                .temp = 0.5 * .temp
            endif
            .vquad = .vquad + .hq## [.i, .j] * .temp
        endfor
    endfor
    for .k from 1 to .npt
        .vquad = .vquad + 0.5 * .pq# [.k] * (.w# [.npt + .k] * .w# [.npt + .k])
    endfor
    .diff = .f - .fopt - .vquad
    .diffc = .diffb
    .diffb = .diffa
    .diffa = abs (.diff)
    if .dnorm > .rho
        .nfsav = .nf
    endif

    # Trust region step: update delta
    if .ntrits > 0
        if .vquad >= 0
            goto bob_stepfail
        endif
        .ratio = (.f - .fopt) / .vquad
        if .ratio <= 0.1
            .delta = .delta * 0.5
            .delta = min (.delta, .dnorm)
        elsif .ratio <= 0.7
            .delta = .delta * 0.5
            .delta = max (.delta, .dnorm)
        else
            .tempa = .dnorm + .dnorm
            .delta = .delta * 0.5
            .delta = max (.delta, .tempa)
        endif
        if .delta <= .rho * 1.5
            .delta = .rho
        endif

        # Recalculate KNEW if f < fopt
        if .f < .fopt
            .ksav = .knew
            .densav = .denom
            .delsq = .delta * .delta
            .scaden = 0
            .biglsq = 0
            .knew = 0
            for .k from 1 to .npt
                .hdiag = 0
                for .jj from 1 to .nptm
                    .hdiag = .hdiag + .zmat## [.k, .jj] * .zmat## [.k, .jj]
                endfor
                .den = .beta_up * .hdiag + .vlag# [.k] * .vlag# [.k]
                .distsq = 0
                for .j from 1 to .n
                    .temp = .xpt## [.k, .j] - .xnew# [.j]
                    .distsq = .distsq + .temp * .temp
                endfor
                .temp = .distsq / .delsq
                .temp = .temp * .temp
                .temp = max (1, .temp)
                if .temp * .den > .scaden
                    .scaden = .temp * .den
                    .knew = .k
                    .denom = .den
                endif
                .temp = .temp * (.vlag# [.k] * .vlag# [.k])
                .biglsq = max (.biglsq, .temp)
            endfor
            if .scaden <= 0.5 * .biglsq
                .knew = .ksav
                .denom = .densav
            endif
        endif
    endif

    # Call UPDATE
    @emlBOBYQAUpdate: .n, .npt, .bmat##, .zmat##, .vlag#, .beta_up,
        ... .denom, .knew
    .bmat## = emlBOBYQAUpdate.bmat##
    .zmat## = emlBOBYQAUpdate.zmat##
    .vlag# = emlBOBYQAUpdate.vlag#

    # Update HQ: absorb PQ[knew] into explicit Hessian
    .pqold = .pq# [.knew]
    .pq# [.knew] = 0
    for .i from 1 to .n
        .temp = .pqold * .xpt## [.knew, .i]
        for .j from 1 to .i
            .hq## [.j, .i] = .hq## [.j, .i] + .temp * .xpt## [.knew, .j]
            .hq## [.i, .j] = .hq## [.j, .i]
        endfor
    endfor
    # Update PQ from ZMAT
    for .jj from 1 to .nptm
        .temp = .diff * .zmat## [.knew, .jj]
        for .k from 1 to .npt
            .pq# [.k] = .pq# [.k] + .temp * .zmat## [.k, .jj]
        endfor
    endfor

    # Include new interpolation point; update GOPT
    .fval# [.knew] = .f
    for .i from 1 to .n
        .xpt## [.knew, .i] = .xnew# [.i]
        .w# [.i] = .bmat## [.knew, .i]
    endfor
    for .k from 1 to .npt
        .suma = 0
        for .jj from 1 to .nptm
            .suma = .suma + .zmat## [.knew, .jj] * .zmat## [.k, .jj]
        endfor
        .sumb = 0
        for .j from 1 to .n
            .sumb = .sumb + .xpt## [.k, .j] * .xoptCur# [.j]
        endfor
        .temp = .suma * .sumb
        for .i from 1 to .n
            .w# [.i] = .w# [.i] + .temp * .xpt## [.k, .i]
        endfor
    endfor
    for .i from 1 to .n
        .gopt# [.i] = .gopt# [.i] + .diff * .w# [.i]
    endfor

    # Update XOPT, GOPT, KOPT if f < fopt
    if .f < .fopt
        .kopt = .knew
        .xoptsq = 0
        for .j from 1 to .n
            .xoptCur# [.j] = .xnew# [.j]
            .xoptsq = .xoptsq + .xoptCur# [.j] * .xoptCur# [.j]
            for .i from 1 to .j
                if .i < .j
                    .gopt# [.j] = .gopt# [.j] + .hq## [.i, .j] * .dv# [.i]
                endif
                .gopt# [.i] = .gopt# [.i] + .hq## [.i, .j] * .dv# [.j]
            endfor
        endfor
        for .k from 1 to .npt
            .temp = 0
            for .j from 1 to .n
                .temp = .temp + .xpt## [.k, .j] * .dv# [.j]
            endfor
            .temp = .pq# [.k] * .temp
            for .i from 1 to .n
                .gopt# [.i] = .gopt# [.i] + .temp * .xpt## [.k, .i]
            endfor
        endfor
    endif

    # Test whether to replace model with least Frobenius norm interpolant
    if .ntrits > 0
        for .k from 1 to .npt
            .vlag# [.k] = .fval# [.k] - .fval# [.kopt]
            .w# [.k] = 0
        endfor
        for .j from 1 to .nptm
            .sum = 0
            for .k from 1 to .npt
                .sum = .sum + .zmat## [.k, .j] * .vlag# [.k]
            endfor
            for .k from 1 to .npt
                .w# [.k] = .w# [.k] + .sum * .zmat## [.k, .j]
            endfor
        endfor
        for .k from 1 to .npt
            .sum = 0
            for .j from 1 to .n
                .sum = .sum + .xpt## [.k, .j] * .xoptCur# [.j]
            endfor
            .w# [.k + .npt] = .w# [.k]
            .w# [.k] = .sum * .w# [.k]
        endfor
        .gqsq = 0
        .gisq = 0
        for .i from 1 to .n
            .sum = 0
            for .k from 1 to .npt
                .sum = .sum + .bmat## [.k, .i] * .vlag# [.k]
                    ... + .xpt## [.k, .i] * .w# [.k]
            endfor
            if .xoptCur# [.i] = .sl# [.i]
                .tempa = min (0, .gopt# [.i])
                .gqsq = .gqsq + .tempa * .tempa
                .tempa = min (0, .sum)
                .gisq = .gisq + .tempa * .tempa
            elsif .xoptCur# [.i] = .su# [.i]
                .tempa = max (0, .gopt# [.i])
                .gqsq = .gqsq + .tempa * .tempa
                .tempa = max (0, .sum)
                .gisq = .gisq + .tempa * .tempa
            else
                .gqsq = .gqsq + .gopt# [.i] * .gopt# [.i]
                .gisq = .gisq + .sum * .sum
            endif
            .vlag# [.npt + .i] = .sum
        endfor
        .itest = .itest + 1
        if .gqsq < 10 * .gisq
            .itest = 0
        endif
        if .itest >= 3
            for .i from 1 to .n
                .gopt# [.i] = .vlag# [.npt + .i]
            endfor
            for .i from 1 to .npt
                .pq# [.i] = .w# [.npt + .i]
            endfor
            .hq## = zero## (.n, .n)
            .itest = 0
        endif
    endif

    # Branch decisions
    if .ntrits = 0
        goto bob_L60
    endif
    if .f <= .fopt + 0.1 * .vquad
        goto bob_L60
    endif

    .tempa = 2 * .delta
    .tempb = 10 * .rho
    .tempa = .tempa * .tempa
    .tempb = .tempb * .tempb
    .distsq = max (.tempa, .tempb)

    # ======== L650: Check point distances ========
    label bob_L650
    .knew = 0
    for .k from 1 to .npt
        .sum = 0
        for .j from 1 to .n
            .tempa = .xpt## [.k, .j] - .xoptCur# [.j]
            .sum = .sum + .tempa * .tempa
        endfor
        if .sum > .distsq
            .knew = .k
            .distsq = .sum
        endif
    endfor

    if .knew > 0
        .dist = sqrt (.distsq)
        if .ntrits = -1
            .tempa = 0.1 * .delta
            .tempb = 0.5 * .dist
            .delta = min (.tempa, .tempb)
            if .delta <= .rho * 1.5
                .delta = .rho
            endif
        endif
        .ntrits = 0
        .adelt = 0.1 * .dist
        .adelt = min (.adelt, .delta)
        .adelt = max (.adelt, .rho)
        .dsq = .adelt * .adelt
        goto bob_L90
    endif
    if .ntrits = -1
        goto bob_L680
    endif
    if .ratio > 0
        goto bob_L60
    endif
    if max (.delta, .dnorm) > .rho
        goto bob_L60
    endif

    # ======== L680: Reduce RHO ========
    label bob_L680
    if .rho > .rhoEnd
        .delta = 0.5 * .rho
        .ratio = .rho / .rhoEnd
        if .ratio <= 16
            .rho = .rhoEnd
        elsif .ratio <= 250
            .rho = sqrt (.ratio) * .rhoEnd
        else
            .rho = 0.1 * .rho
        endif
        .delta = max (.delta, .rho)
        .ntrits = 0
        .nfsav = .nf
        goto bob_L60
    endif

    # Final Newton-Raphson step if needed
    if .ntrits = -1
        goto bob_L360
    endif

    # ======== DONE ========
    label bob_done
    if .fval# [.kopt] <= .fsave
        for .i from 1 to .n
            .tempa = .xbase# [.i] + .xoptCur# [.i]
            .tempa = max (.tempa, .lower# [.i])
            .x# [.i] = min (.tempa, .upper# [.i])
            if .xoptCur# [.i] = .sl# [.i]
                .x# [.i] = .lower# [.i]
            endif
            if .xoptCur# [.i] = .su# [.i]
                .x# [.i] = .upper# [.i]
            endif
        endfor
        .f = .fval# [.kopt]
    endif
    .xOpt# = .x#
    .fOpt = .f
    .nEval = .nf
    .convergence = 0
    goto bob_exit

    label bob_maxfun
    .error$ = "Maximum function evaluations reached"
    goto bob_finalize

    label bob_cancel
    .error$ = "Cancellation in denominator"
    goto bob_finalize

    label bob_stepfail
    .error$ = "Trust region step failed to reduce Q"
    goto bob_finalize

    label bob_finalize
    for .i from 1 to .n
        .tempa = .xbase# [.i] + .xoptCur# [.i]
        .tempa = max (.tempa, .lower# [.i])
        .x# [.i] = min (.tempa, .upper# [.i])
        if .xoptCur# [.i] = .sl# [.i]
            .x# [.i] = .lower# [.i]
        endif
        if .xoptCur# [.i] = .su# [.i]
            .x# [.i] = .upper# [.i]
        endif
    endfor
    .xOpt# = .x#
    .fOpt = .fval# [.kopt]
    .nEval = .nf

    label bob_exit
endproc
