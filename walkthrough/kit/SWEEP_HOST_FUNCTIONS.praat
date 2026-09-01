# ===========================================================================
# SWEEP_HOST_FUNCTIONS.praat -- the cancellation-signature sweep.
#
# Fable, RULING_UNIQUENESS_SWEEP_2026-09-01: sweep every retained host
# special function into the far tail against the R oracles. The diagnostic is
# the SIGNATURE, not the tolerance. Absolute error flat at ULP-of-1.0 while p
# shrinks means the upper tail is computed as 1 - CDF and every significant
# digit is destroyed by the subtraction. Absolute error shrinking with p means
# the tail is computed directly and the function is clean.
#
# Writes one row per evaluation to sweep_host_<version>.tsv beside this
# script. Each function writes its own name BEFORE evaluating, so a build
# lacking one halts with the last line naming it.
# ===========================================================================

out$ = "sweep_host_" + praatVersion$ + ".tsv"
writeFileLine: out$, "fn	arg1	arg2	arg3	value"

# --- upper-tail probability functions --------------------------------------

for i from 1 to 45
    z = 0.5 + (i - 1) * 0.2
    appendFileLine: out$, "gaussQ	", z, "	", "	", "	", gaussQ (z)
endfor

for i from 1 to 60
    t = 0.5 + (i - 1) * 0.4
    appendFileLine: out$, "studentQ	", t, "	45	", "	", studentQ (t, 45)
endfor

for i from 1 to 60
    x = 1 + (i - 1) * 2.5
    appendFileLine: out$, "chiSquareQ	", x, "	5	", "	", chiSquareQ (x, 5)
endfor

for i from 1 to 60
    f = 1 + (i - 1) * 1.2
    appendFileLine: out$, "fisherQ	", f, "	4	45	", fisherQ (f, 4, 45)
endfor

for i from 1 to 40
    q = 2 + (i - 1) * 0.4
    tq = Get TukeyQ: q, 5, 45, 1
    appendFileLine: out$, "TukeyQ	", q, "	5	45	", tq
endfor

# --- inverse functions: feed p from 1e-1 down to 1e-15 ---------------------

for i from 1 to 30
    p = 10 ^ (-0.5 * i)
    appendFileLine: out$, "invGaussQ	", p, "	", "	", "	", invGaussQ (p)
endfor

for i from 1 to 30
    p = 10 ^ (-0.5 * i)
    appendFileLine: out$, "invStudentQ	", p, "	45	", "	", invStudentQ (p, 45)
endfor

for i from 1 to 30
    p = 10 ^ (-0.5 * i)
    appendFileLine: out$, "invChiSquareQ	", p, "	5	", "	", invChiSquareQ (p, 5)
endfor

for i from 1 to 30
    p = 10 ^ (-0.5 * i)
    appendFileLine: out$, "invFisherQ	", p, "	4	45	", invFisherQ (p, 4, 45)
endfor

for i from 1 to 24
    p = 10 ^ (-0.5 * i)
    itq = Get invTukeyQ: p, 5, 45, 1
    appendFileLine: out$, "invTukeyQ	", p, "	5	45	", itq
endfor

writeInfoLine: "sweep complete -> ", out$
