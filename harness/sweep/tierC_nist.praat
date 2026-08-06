# ============================================================================
# tierC_nist.praat -- run the plugin against NIST StRD certified datasets.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# These datasets are built to break sums-of-squares routines. SiRstv carries
# "3 Constant Leading Digits": every observation sits near 196, and the
# between-instrument sum of squares is 0.0511. A routine using the textbook
# computational form
#
#     SS = sum(x^2) - sum(x)^2 / n
#
# subtracts two numbers near 962000 to get 0.05, and loses about six digits
# doing it. A two-pass routine that centres first does not. Nothing about the
# ordinary demo tables distinguishes the two; this does.
#
#     EML_NIST_DIR=evidence/nist praat --run harness/sweep/tierC_nist.praat
#
# Emits results.csv; validate/v19_nist_strd.R scores it in log relative error
# against the certified values parsed out of NIST's own .dat file.
# ============================================================================

include ../../plugin/stats/eml-core-utilities.praat
include ../../plugin/stats/eml-core-descriptive.praat
include ../../plugin/stats/eml-extract.praat
include ../../plugin/stats/eml-output.praat
include ../../plugin/stats/eml-inferential.praat

Text writing preferences: "UTF-8"

nistDir$ = environment$ ("EML_NIST_DIR")
if nistDir$ = ""
    nistDir$ = "../../evidence/nist"
endif

# Every *_data.csv in the directory, so adding a dataset is a download and a
# re-run, not an edit here.
strings = Create Strings as file list: "nist", nistDir$ + "/*_data.csv"
nFiles = Get number of strings

results$ = "dataset,statistic,value" + newline$
nRun = 0

for f from 1 to nFiles
    selectObject: strings
    fname$ = Get string: f
    dsName$ = replace$ (fname$, "_data.csv", "", 0)

    tid = Read Table from comma-separated file: nistDir$ + "/" + fname$

    # NIST writes the ANOVA factor as an integer. The plugin groups on string
    # equality, so the column is used as-is -- "1" and "2" are perfectly good
    # labels and no recoding is done, which keeps the input byte-identical to
    # what nist_ingest.R wrote.
    @emlOneWayAnova: tid, "value", "grp", 0

    if emlOneWayAnova.error$ <> ""
        results$ = results$ + dsName$ + ",error,1" + newline$
    else
        results$ = results$ + dsName$ + ",df.between,"
        ... + string$ (emlOneWayAnova.dfBetween) + newline$
        results$ = results$ + dsName$ + ",sumsq.between,"
        ... + string$ (emlOneWayAnova.ssBetween) + newline$
        results$ = results$ + dsName$ + ",meansq.between,"
        ... + string$ (emlOneWayAnova.msBetween) + newline$
        results$ = results$ + dsName$ + ",statistic,"
        ... + string$ (emlOneWayAnova.fValue) + newline$
        results$ = results$ + dsName$ + ",df.within,"
        ... + string$ (emlOneWayAnova.dfWithin) + newline$
        results$ = results$ + dsName$ + ",sumsq.within,"
        ... + string$ (emlOneWayAnova.ssWithin) + newline$
        results$ = results$ + dsName$ + ",meansq.within,"
        ... + string$ (emlOneWayAnova.msWithin) + newline$
        results$ = results$ + dsName$ + ",r.squared,"
        ... + string$ (emlOneWayAnova.etaSquared) + newline$
        results$ = results$ + dsName$ + ",residual.sd,"
        ... + string$ (sqrt (emlOneWayAnova.msWithin)) + newline$
        nRun = nRun + 1
    endif

    removeObject: tid
endfor

removeObject: strings
writeFileLine: nistDir$ + "/results.csv", results$
writeInfoLine: "Tier C: ", nRun, " of ", nFiles, " NIST dataset(s) run"
