# ============================================================================
# validate/probes/to_table_probe.praat
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# KIT FIXTURE PROBE for @emlToTable (plugin_EML_StatsGraphs/graphs/
# eml-graph-procedures.praat), the object-to-table CLASS DISPATCHER rebuilt
# in wave/emltotable-object-converter (REGISTRY.tsv's own correction note
# names the rebuild). Shaped after validate/probes/vectors_to_table_probe.praat
# and validate/vectors_to_table_oracle.tsv (the B11 wave's six graded
# vector-to-table fixtures) -- one graded fixture per CLASS ARM here instead
# of per vector shape, because what varies across @emlToTable's callers is
# the selected object's class, not a vector count.
#
# ONE FIXTURE OBJECT PER ARM, BUILT DETERMINISTICALLY, RIGHT HERE. Every
# input is a small fixed literal (a 2x2 TableOfReal, a hand-set Matrix, a
# synthesised 200 Hz sine) so the graded cells are reproducible bit-for-bit
# on the same Praat version -- no external audio file, no randomness, no
# `include` of any fixture-builder file the way validate/fixtures/
# vectors_to_table/vectors_to_table_fixtures.praat is split out, because
# unlike @emlVectorsToTable's script-level-vector fixtures, @emlToTable's
# fixtures ARE Praat objects, and an object is exactly as easy to build next
# to the call that consumes it as in a separate file -- splitting would only
# add a second file with no reader who needs the objects on their own.
#
# THIS FILE SELF-CHECKS. Unlike validate/tools/run_vectors_to_table_probe.praat
# (which blindly regenerates its oracle and leaves comparison to a later
# run), every field written to validate/to_table_oracle.tsv here is written
# by @ttp_check alongside the value @ttp_check independently expects --
# a fixed literal for anything the procedure's source hard-codes (an error
# sentence, a warning sentence, a formant-decimals count), or a value
# RECOMPUTED FRESH from the object itself for anything that depends on the
# audio (a bin's own frequency, a native "Down to Table" run on a second
# copy of the same Formant). A mismatch prints inline as the run happens;
# the run's final line is the pass/fail tally, so a broken arm is visible
# without opening the TSV at all.
#
# THE FREQUENCY-FROM-BIN ASSERTION (fixture to04_ltas) is the one point the
# whole probe exists to nail down: @emlToTable's Ltas arm claims its
# frequency_Hz column is EXACTLY `Get frequency from bin number`, never a
# bandwidth-times-index recomputation (see @emlReadLtasBins's own header).
# to04_ltas re-reads every bin's frequency directly from the *same* Ltas
# object after @emlToTable has already run, and compares it cell-by-cell
# against what the built Table actually holds -- not a hand-typed constant,
# because a hand-typed constant could not tell a correct read from a
# plausible-looking recomputation that happens to match at one probe-chosen
# frequency.
#
# HOW TO RUN
#
#   /usr/local/bin/praat6630 --run validate/probes/to_table_probe.praat
#
# Regenerates validate/to_table_oracle.tsv and prints a PASS/FAIL line per
# fixture plus a final tally. A later run that disagrees with the tally
# recorded in this header's own commit message is the thing to investigate.
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab -- www.embodiedmusiclab.com
# Code generation: Claude (Anthropic)
# Script author: Ian Howell -- created and verified by this individual
# ============================================================================

include ../../plugin_EML_StatsGraphs/graphs/eml-graph-procedures.praat
include ../../plugin_EML_StatsGraphs/stats/eml-extract.praat

# ---- small local helpers ---------------------------------------------------

procedure ttp_tsvHeader: .path$
    deleteFile: .path$
    appendFileLine: .path$, "fixture", tab$, "field", tab$, "value"
endproc

procedure ttp_writeField: .path$, .fixture$, .field$, .value$
    appendFileLine: .path$, .fixture$, tab$, .field$, tab$, .value$
endproc

# Writes .actual$ to the oracle under (.fixture$, .field$) and grades it
# against .expected$ in the same step -- see the file header's note on why
# this probe self-checks rather than only recording.
procedure ttp_check: .fixture$, .field$, .expected$, .actual$
    @ttp_writeField: ttp_outTsv$, .fixture$, .field$, .actual$
    ttp_total = ttp_total + 1
    if .actual$ = .expected$
        ttp_pass = ttp_pass + 1
    else
        ttp_fail = ttp_fail + 1
        appendInfoLine: "  MISMATCH ", .fixture$, ".", .field$,
        ... ": expected [", .expected$, "] got [", .actual$, "]"
    endif
endproc

procedure ttp_getCell: .tableId, .row, .colLabel$
    selectObject: .tableId
    .result$ = Get value: .row, .colLabel$
endproc

ttp_outTsv$ = "../to_table_oracle.tsv"
@ttp_tsvHeader: ttp_outTsv$
ttp_total = 0
ttp_pass = 0
ttp_fail = 0
emptyNames$# = empty$# (0)

appendInfoLine: "=== to_table_probe ==="

# ============================================================================
# to01_table -- Table arm: a COPY, names applied, source left untouched
# ============================================================================
appendInfoLine: newline$, "-- to01_table --"
to01_src = Create Table with column names: "to01_src", 3, "id score"
for to01_r to 3
    Set numeric value: to01_r, "id", to01_r
    Set numeric value: to01_r, "score", to01_r * 10
endfor
to01_names$# = { "ID", "Score" }
@emlToTable: to01_src, to01_names$#

@ttp_check: "to01_table", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to01_table", "sourceType", "Table", emlToTable.sourceType$
@ttp_check: "to01_table", "nRows", "3", string$ (emlToTable.nRows)
@ttp_check: "to01_table", "nCols", "2", string$ (emlToTable.nCols)
@ttp_check: "to01_table", "warning", "", emlToTable.warning$
@ttp_check: "to01_table", "error", "", emlToTable.error$
@ttp_check: "to01_table", "tableId_gt0", "1", string$ (emlToTable.tableId > 0)
@ttp_check: "to01_table", "tableId_differs_from_source", "1",
... string$ (emlToTable.tableId <> to01_src)

selectObject: to01_src
to01_srcIdCol$ = Get column label: 1
@ttp_check: "to01_table", "source_untouched_col1", "id", to01_srcIdCol$

for to01_r to 3
    @ttp_getCell: emlToTable.tableId, to01_r, "ID"
    @ttp_check: "to01_table", "cell_ID_" + string$ (to01_r),
    ... string$ (to01_r), ttp_getCell.result$
    @ttp_getCell: emlToTable.tableId, to01_r, "Score"
    @ttp_check: "to01_table", "cell_Score_" + string$ (to01_r),
    ... string$ (to01_r * 10), ttp_getCell.result$
endfor
removeObject: to01_src, emlToTable.tableId

# ============================================================================
# to02_tableofreal -- row labels -> column 1, "?" repaired to r<row>
# ============================================================================
appendInfoLine: newline$, "-- to02_tableofreal --"
to02_src = Create TableOfReal: "to02_src", 2, 2
Set row label (index): 1, "alpha"
Set row label (index): 2, "?"
Set column label (index): 1, "colA"
Set column label (index): 2, "colB"
Set value: 1, 1, 11
Set value: 1, 2, 12
Set value: 2, 1, 21
Set value: 2, 2, 22
@emlToTable: to02_src, emptyNames$#

@ttp_check: "to02_tableofreal", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to02_tableofreal", "sourceType", "TableOfReal", emlToTable.sourceType$
@ttp_check: "to02_tableofreal", "nRows", "2", string$ (emlToTable.nRows)
@ttp_check: "to02_tableofreal", "nCols", "3", string$ (emlToTable.nCols)
@ttp_check: "to02_tableofreal", "warning", "", emlToTable.warning$
@ttp_check: "to02_tableofreal", "error", "", emlToTable.error$

selectObject: emlToTable.tableId
to02_col1$ = Get column label: 1
to02_col2$ = Get column label: 2
to02_col3$ = Get column label: 3
@ttp_check: "to02_tableofreal", "col1_label", "row", to02_col1$
@ttp_check: "to02_tableofreal", "col2_label", "colA", to02_col2$
@ttp_check: "to02_tableofreal", "col3_label", "colB", to02_col3$

@ttp_getCell: emlToTable.tableId, 1, "row"
@ttp_check: "to02_tableofreal", "rowlabel_row1", "alpha", ttp_getCell.result$
@ttp_getCell: emlToTable.tableId, 2, "row"
@ttp_check: "to02_tableofreal", "rowlabel_row2_repaired", "r2", ttp_getCell.result$

@ttp_getCell: emlToTable.tableId, 1, "colA"
@ttp_check: "to02_tableofreal", "cell_colA_row1", "11", ttp_getCell.result$
@ttp_getCell: emlToTable.tableId, 2, "colA"
@ttp_check: "to02_tableofreal", "cell_colA_row2", "21", ttp_getCell.result$
@ttp_getCell: emlToTable.tableId, 1, "colB"
@ttp_check: "to02_tableofreal", "cell_colB_row1", "12", ttp_getCell.result$
@ttp_getCell: emlToTable.tableId, 2, "colB"
@ttp_check: "to02_tableofreal", "cell_colB_row2", "22", ttp_getCell.result$
removeObject: to02_src, emlToTable.tableId

# ============================================================================
# to03_matrix -- numbered columns, x/y-not-carried warning
# ============================================================================
appendInfoLine: newline$, "-- to03_matrix --"
to03_src = Create simple Matrix: "to03_src", 2, 2, "0"
Set value: 1, 1, 1
Set value: 1, 2, 2
Set value: 2, 1, 3
Set value: 2, 2, 4
@emlToTable: to03_src, emptyNames$#

to03_matrixNote$ = "A Matrix reaches a Table through a TableOfReal; the " +
... "x/y sampling (domain, dx, dy) is not carried into the Table, only " +
... "the cell values and default row/column numbering."

@ttp_check: "to03_matrix", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to03_matrix", "sourceType", "Matrix", emlToTable.sourceType$
@ttp_check: "to03_matrix", "nRows", "2", string$ (emlToTable.nRows)
@ttp_check: "to03_matrix", "nCols", "3", string$ (emlToTable.nCols)
@ttp_check: "to03_matrix", "warning", to03_matrixNote$, emlToTable.warning$
@ttp_check: "to03_matrix", "error", "", emlToTable.error$

selectObject: emlToTable.tableId
to03_col1$ = Get column label: 1
to03_col2$ = Get column label: 2
to03_col3$ = Get column label: 3
@ttp_check: "to03_matrix", "col1_label", "row", to03_col1$
@ttp_check: "to03_matrix", "col2_label", "Column_1", to03_col2$
@ttp_check: "to03_matrix", "col3_label", "Column_2", to03_col3$

@ttp_getCell: emlToTable.tableId, 1, "row"
@ttp_check: "to03_matrix", "rowlabel_row1_repaired", "r1", ttp_getCell.result$
@ttp_getCell: emlToTable.tableId, 2, "row"
@ttp_check: "to03_matrix", "rowlabel_row2_repaired", "r2", ttp_getCell.result$

@ttp_getCell: emlToTable.tableId, 1, "Column_1"
@ttp_check: "to03_matrix", "cell_Column_1_row1", "1", ttp_getCell.result$
@ttp_getCell: emlToTable.tableId, 2, "Column_1"
@ttp_check: "to03_matrix", "cell_Column_1_row2", "3", ttp_getCell.result$
@ttp_getCell: emlToTable.tableId, 1, "Column_2"
@ttp_check: "to03_matrix", "cell_Column_2_row1", "2", ttp_getCell.result$
@ttp_getCell: emlToTable.tableId, 2, "Column_2"
@ttp_check: "to03_matrix", "cell_Column_2_row2", "4", ttp_getCell.result$
removeObject: to03_src, emlToTable.tableId

# ============================================================================
# to04_ltas -- frequency_Hz MUST equal "Get frequency from bin number"
# ============================================================================
appendInfoLine: newline$, "-- to04_ltas --"
to04_snd = Create Sound from formula: "to04_snd", "Mono", 0, 0.3, 8000,
... "0.5 * sin(2 * pi * 200 * x)"
selectObject: to04_snd
to04_src = To Ltas: 100
selectObject: to04_src
to04_nBins = Get number of bins
@emlToTable: to04_src, emptyNames$#

@ttp_check: "to04_ltas", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to04_ltas", "sourceType", "Ltas", emlToTable.sourceType$
@ttp_check: "to04_ltas", "nCols", "2", string$ (emlToTable.nCols)
@ttp_check: "to04_ltas", "warning", "", emlToTable.warning$
@ttp_check: "to04_ltas", "error", "", emlToTable.error$
@ttp_check: "to04_ltas", "nRows_equals_nBins", "1",
... string$ (emlToTable.nRows = to04_nBins)

to04_freqOk = 1
to04_levelOk = 1
for to04_b to to04_nBins
    selectObject: to04_src
    to04_freqLive = Get frequency from bin number: to04_b
    to04_levelLive = Get value in bin: to04_b
    @ttp_getCell: emlToTable.tableId, to04_b, "frequency_Hz"
    if number (ttp_getCell.result$) <> to04_freqLive
        to04_freqOk = 0
    endif
    @ttp_getCell: emlToTable.tableId, to04_b, "level_dB"
    if number (ttp_getCell.result$) <> to04_levelLive
        to04_levelOk = 0
    endif
endfor
@ttp_check: "to04_ltas", "frequency_matches_bin_number_every_row", "1",
... string$ (to04_freqOk)
@ttp_check: "to04_ltas", "level_matches_get_value_in_bin_every_row", "1",
... string$ (to04_levelOk)
removeObject: to04_snd, to04_src, emlToTable.tableId

# ============================================================================
# to05_spectrum -- built via To Ltas (1-to-1), same bin count as a direct
# To Ltas (1-to-1) run on an untouched copy of the same Spectrum
# ============================================================================
appendInfoLine: newline$, "-- to05_spectrum --"
to05_snd = Create Sound from formula: "to05_snd", "Mono", 0, 0.3, 8000,
... "0.5 * sin(2 * pi * 200 * x)"
selectObject: to05_snd
to05_src = To Spectrum: "yes"
@emlToTable: to05_src, emptyNames$#

to05_expectWarning$ = "Converted via To Ltas (1-to-1) before reading bins, " +
... "so the table reflects the LTAS's own bin resolution, not a raw " +
... "real/imaginary readout of the Spectrum."

@ttp_check: "to05_spectrum", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to05_spectrum", "sourceType", "Spectrum", emlToTable.sourceType$
@ttp_check: "to05_spectrum", "nCols", "2", string$ (emlToTable.nCols)
@ttp_check: "to05_spectrum", "warning", to05_expectWarning$, emlToTable.warning$
@ttp_check: "to05_spectrum", "error", "", emlToTable.error$
@ttp_check: "to05_spectrum", "source_not_consumed", "1",
... string$ (numberOfSelected ("Spectrum") >= 0)

selectObject: to05_src
to05_chkSpec = Copy: "to05_chk"
selectObject: to05_chkSpec
to05_chkLtas = To Ltas (1-to-1)
selectObject: to05_chkLtas
to05_chkBins = Get number of bins
@ttp_check: "to05_spectrum", "nRows_equals_independent_to_ltas_1to1", "1",
... string$ (emlToTable.nRows = to05_chkBins)
removeObject: to05_snd, to05_src, to05_chkLtas, emlToTable.tableId

# ============================================================================
# to06_pitch -- one row per VOICED frame, via @emlExtractPitchValues
# ============================================================================
appendInfoLine: newline$, "-- to06_pitch --"
to06_snd = Create Sound from formula: "to06_snd", "Mono", 0, 0.3, 8000,
... "0.5 * sin(2 * pi * 200 * x)"
selectObject: to06_snd
to06_src = To Pitch: 0, 75, 600
@emlToTable: to06_src, emptyNames$#
@emlExtractPitchValues: to06_src, "Hertz"

to06_expectWarning$ = ""
if emlExtractPitchValues.nUnvoiced > 0
    to06_expectWarning$ = string$ (emlExtractPitchValues.nUnvoiced) + " of " +
    ... string$ (emlExtractPitchValues.nTotal) + " frame(s) were unvoiced " +
    ... "and dropped."
endif

@ttp_check: "to06_pitch", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to06_pitch", "sourceType", "Pitch", emlToTable.sourceType$
@ttp_check: "to06_pitch", "nCols", "2", string$ (emlToTable.nCols)
@ttp_check: "to06_pitch", "error", "", emlToTable.error$
@ttp_check: "to06_pitch", "nRows_equals_extractor_voiced_count", "1",
... string$ (emlToTable.nRows = emlExtractPitchValues.n)
@ttp_check: "to06_pitch", "warning", to06_expectWarning$, emlToTable.warning$
removeObject: to06_snd, to06_src, emlToTable.tableId

# ============================================================================
# to07_intensity -- one row per frame, via @emlExtractIntensityFrames
# ============================================================================
appendInfoLine: newline$, "-- to07_intensity --"
to07_snd = Create Sound from formula: "to07_snd", "Mono", 0, 0.3, 8000,
... "0.5 * sin(2 * pi * 200 * x)"
selectObject: to07_snd
to07_src = To Intensity: 75, 0, "yes"
@emlToTable: to07_src, emptyNames$#
@emlExtractIntensityFrames: to07_src

@ttp_check: "to07_intensity", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to07_intensity", "sourceType", "Intensity", emlToTable.sourceType$
@ttp_check: "to07_intensity", "nCols", "2", string$ (emlToTable.nCols)
@ttp_check: "to07_intensity", "warning", "", emlToTable.warning$
@ttp_check: "to07_intensity", "error", "", emlToTable.error$
@ttp_check: "to07_intensity", "nRows_equals_extractor_frame_count", "1",
... string$ (emlToTable.nRows = emlExtractIntensityFrames.nTotal)
removeObject: to07_snd, to07_src, emlToTable.tableId

# ============================================================================
# to08_harmonicity -- one row per DEFINED frame, via
# @emlExtractHarmonicityFrames
# ============================================================================
appendInfoLine: newline$, "-- to08_harmonicity --"
to08_snd = Create Sound from formula: "to08_snd", "Mono", 0, 0.3, 8000,
... "0.5 * sin(2 * pi * 200 * x)"
selectObject: to08_snd
to08_src = To Harmonicity (cc): 0.01, 75, 0.1, 1.0
@emlToTable: to08_src, emptyNames$#
@emlExtractHarmonicityFrames: to08_src

to08_expectWarning$ = ""
if emlExtractHarmonicityFrames.nUndefined > 0
    to08_expectWarning$ = string$ (emlExtractHarmonicityFrames.nUndefined) +
    ... " of " + string$ (emlExtractHarmonicityFrames.nTotal) + " frame(s) " +
    ... "had no harmonicity estimate and were dropped."
endif

@ttp_check: "to08_harmonicity", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to08_harmonicity", "sourceType", "Harmonicity", emlToTable.sourceType$
@ttp_check: "to08_harmonicity", "nCols", "2", string$ (emlToTable.nCols)
@ttp_check: "to08_harmonicity", "error", "", emlToTable.error$
@ttp_check: "to08_harmonicity", "nRows_equals_extractor_defined_count", "1",
... string$ (emlToTable.nRows = emlExtractHarmonicityFrames.n)
@ttp_check: "to08_harmonicity", "warning", to08_expectWarning$, emlToTable.warning$
removeObject: to08_snd, to08_src, emlToTable.tableId

# ============================================================================
# to09_formant -- native "Down to Table", checked against a SECOND identical
# call made directly on a copy of the same Formant object
# ============================================================================
appendInfoLine: newline$, "-- to09_formant --"
to09_snd = Create Sound from formula: "to09_snd", "Mono", 0, 0.3, 8000,
... "0.5 * sin(2 * pi * 200 * x)"
selectObject: to09_snd
to09_src = To Formant (burg): 0, 5, 5500, 0.025, 50
@emlToTable: to09_src, emptyNames$#

to09_expectWarning$ = "Frame number omitted; time, formant count, every " +
... "F1..Fn frequency and B1..Bn bandwidth included, all at 20 decimal " +
... "places."

@ttp_check: "to09_formant", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to09_formant", "sourceType", "Formant", emlToTable.sourceType$
@ttp_check: "to09_formant", "warning", to09_expectWarning$, emlToTable.warning$
@ttp_check: "to09_formant", "error", "", emlToTable.error$

selectObject: to09_src
to09_chkFormant = Copy: "to09_chk"
selectObject: to09_chkFormant
to09_chkTable = Down to Table: "no", "yes", 20, "no", 20, "yes", 20, "yes"
selectObject: to09_chkTable
to09_chkRows = Get number of rows
to09_chkCols = Get number of columns
@ttp_check: "to09_formant", "nRows_equals_native_down_to_table", "1",
... string$ (emlToTable.nRows = to09_chkRows)
@ttp_check: "to09_formant", "nCols_equals_native_down_to_table", "1",
... string$ (emlToTable.nCols = to09_chkCols)

to09_labelsMatch = 1
to09_valuesMatch = 1
for to09_c to to09_chkCols
    selectObject: to09_chkTable
    to09_chkLabel$ = Get column label: to09_c
    selectObject: emlToTable.tableId
    to09_gotLabel$ = Get column label: to09_c
    if to09_chkLabel$ <> to09_gotLabel$
        to09_labelsMatch = 0
    else
        for to09_r to to09_chkRows
            @ttp_getCell: to09_chkTable, to09_r, to09_chkLabel$
            to09_chkVal$ = ttp_getCell.result$
            @ttp_getCell: emlToTable.tableId, to09_r, to09_gotLabel$
            if ttp_getCell.result$ <> to09_chkVal$
                to09_valuesMatch = 0
            endif
        endfor
    endif
endfor
@ttp_check: "to09_formant", "column_labels_match_native_call", "1",
... string$ (to09_labelsMatch)
@ttp_check: "to09_formant", "cell_values_match_native_call", "1",
... string$ (to09_valuesMatch)
removeObject: to09_snd, to09_src, to09_chkFormant, to09_chkTable,
... emlToTable.tableId

# ============================================================================
# to10_sound -- Sound arm: one row per sample, time_s + one column per
# channel, EVERY cell equal to the source sample bit for bit
# ============================================================================
appendInfoLine: newline$, "-- to10_sound --"
to10_fs = 100
to10_nSampNominal = 5
to10_src = Create Sound from formula: "to10_src", 2, 0,
... to10_nSampNominal / to10_fs, to10_fs,
... "if row = 1 then sin(2*pi*137*x) else cos(2*pi*211*x) + 0.5 fi"
selectObject: to10_src
to10_nCh = Get number of channels
to10_nSamp = Get number of samples
to10_fsLive = Get sampling frequency
@emlToTable: to10_src, emptyNames$#

to10_expectWarning$ = string$ (to10_nSamp) + " rows, " + string$ (to10_nCh) +
... " channels, " + string$ (to10_fsLive) + " Hz"

@ttp_check: "to10_sound", "ok", "1", string$ (emlToTable.ok)
@ttp_check: "to10_sound", "sourceType", "Sound", emlToTable.sourceType$
@ttp_check: "to10_sound", "nRows", string$ (to10_nSamp), string$ (emlToTable.nRows)
@ttp_check: "to10_sound", "nCols", string$ (to10_nCh + 1), string$ (emlToTable.nCols)
@ttp_check: "to10_sound", "warning", to10_expectWarning$, emlToTable.warning$
@ttp_check: "to10_sound", "error", "", emlToTable.error$

selectObject: emlToTable.tableId
to10_col1$ = Get column label: 1
@ttp_check: "to10_sound", "col1_label", "time_s", to10_col1$
for to10_c to to10_nCh
    selectObject: emlToTable.tableId
    to10_colLabel$ = Get column label: to10_c + 1
    @ttp_check: "to10_sound", "col_label_" + string$ (to10_c),
    ... "channel_" + string$ (to10_c), to10_colLabel$
endfor

# Bit-for-bit check: every time_s and channel cell must match a fresh read
# straight off the source Sound, exactly (number() equality, no tolerance) --
# the same style as to04_ltas's frequency-from-bin assertion.
to10_timeOk = 1
to10_valuesOk = 1
for to10_r to to10_nSamp
    selectObject: to10_src
    to10_tLive = Get time from sample number: to10_r
    @ttp_getCell: emlToTable.tableId, to10_r, "time_s"
    if number (ttp_getCell.result$) <> to10_tLive
        to10_timeOk = 0
    endif
    for to10_c to to10_nCh
        selectObject: to10_src
        to10_vLive = Get value at sample number: to10_c, to10_r
        @ttp_getCell: emlToTable.tableId, to10_r, "channel_" + string$ (to10_c)
        if number (ttp_getCell.result$) <> to10_vLive
            to10_valuesOk = 0
        endif
    endfor
endfor
@ttp_check: "to10_sound", "time_matches_get_time_from_sample_number_every_row",
... "1", string$ (to10_timeOk)
@ttp_check: "to10_sound", "cells_match_source_sample_every_row_bit_for_bit",
... "1", string$ (to10_valuesOk)
removeObject: to10_src, emlToTable.tableId

# ============================================================================
# to11_refuse_colcount -- .columnNames$# count mismatch, naming the count
# ============================================================================
appendInfoLine: newline$, "-- to11_refuse_colcount --"
to11_src = Create Table with column names: "to11_src", 2, "a b"
to11_badNames$# = { "OnlyOneName" }
@emlToTable: to11_src, to11_badNames$#

to11_expectError$ = "emlToTable: .columnNames$# has 1 name(s) but the " +
... "table built from this Table has 2 column(s) -- pass one name per " +
... "column, in order, or an empty vector to keep the default names."
to11_expectRemedy$ = "Pass exactly 2 name(s) in .columnNames$#, in column " +
... "order, or an empty vector."

@ttp_check: "to11_refuse_colcount", "ok", "0", string$ (emlToTable.ok)
@ttp_check: "to11_refuse_colcount", "sourceType", "Table", emlToTable.sourceType$
@ttp_check: "to11_refuse_colcount", "tableId_gt0", "0",
... string$ (emlToTable.tableId > 0)
@ttp_check: "to11_refuse_colcount", "nRows", "0", string$ (emlToTable.nRows)
@ttp_check: "to11_refuse_colcount", "nCols", "0", string$ (emlToTable.nCols)
@ttp_check: "to11_refuse_colcount", "error", to11_expectError$, emlToTable.error$
@ttp_check: "to11_refuse_colcount", "remedy", to11_expectRemedy$,
... emlToTable.remedy$
removeObject: to11_src

# ============================================================================
# to12_refuse_unknown -- an object class emlToTable does not handle refuses,
# naming a remedy (the Sound refusal fixture this replaces is retired -- a
# Sound now converts, see to10_sound above -- but a refusal path must still
# be graded)
# ============================================================================
appendInfoLine: newline$, "-- to12_refuse_unknown --"
to12_src = Create Strings as file list: "to12_src", "*.eml_nonexistent_glob"
@emlToTable: to12_src, emptyNames$#

to12_expectError$ = "emlToTable: does not know how to make a Table from a " +
... "Strings."
to12_expectRemedy$ = "Select a Table, TableOfReal, Matrix, Ltas, Spectrum, " +
... "Pitch, Intensity, Harmonicity or Formant object and call emlToTable " +
... "again."

@ttp_check: "to12_refuse_unknown", "ok", "0", string$ (emlToTable.ok)
@ttp_check: "to12_refuse_unknown", "sourceType", "Strings", emlToTable.sourceType$
@ttp_check: "to12_refuse_unknown", "tableId_gt0", "0",
... string$ (emlToTable.tableId > 0)
@ttp_check: "to12_refuse_unknown", "nRows", "0", string$ (emlToTable.nRows)
@ttp_check: "to12_refuse_unknown", "nCols", "0", string$ (emlToTable.nCols)
@ttp_check: "to12_refuse_unknown", "error", to12_expectError$, emlToTable.error$
@ttp_check: "to12_refuse_unknown", "remedy", to12_expectRemedy$,
... emlToTable.remedy$
removeObject: to12_src

# ---- tally -------------------------------------------------------------
appendInfoLine: newline$, "=== to_table_probe: ", string$ (ttp_pass), "/",
... string$ (ttp_total), " checks passed (", string$ (ttp_fail), " failed) ==="
if ttp_fail = 0
    appendInfoLine: "to_table_probe: ALL ARMS PASS"
else
    appendInfoLine: "to_table_probe: ", string$ (ttp_fail), " CHECK(S) FAILED"
endif
appendInfoLine: "to_table_probe: wrote validate/to_table_oracle.tsv"
