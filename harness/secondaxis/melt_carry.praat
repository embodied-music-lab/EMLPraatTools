include fixture.praat
# THE WIDE-FORMAT PATH, WHICH DRAWS FROM A DIFFERENT OBJECT.
#
# Two or more series in wide format are MELTED into a three-column table --
# time, eml_series, eml_value -- and that table is what the draw procedure is
# handed. The right-hand series is chosen from the ORIGINAL table's columns,
# which the melt does not carry, so the form copies it in under its own name
# through @emlGraphsCarrySecondColumn.
#
# This case builds the melt the way the form builds it, calls that procedure,
# and draws the figure from the melted table: two series on the left from the
# wide columns, and the contact quotient on the right, read from a column that
# was not in the melted table until the procedure put it there.
nDataRows = Get number of rows
tsSeriesCol$[1] = "f0"
tsSeriesCol$[2] = "cq"
tsNSeries = 2
nMeltRows = nDataRows * tsNSeries
meltId = Create Table with column names: "eml_melt", nMeltRows, "t eml_series eml_value"
meltRow = 0
for iSeries from 1 to tsNSeries
    for iRow from 1 to nDataRows
        meltRow = meltRow + 1
        selectObject: objectId
        val$ = Get value: iRow, "t"
        timeVal = number (val$)
        val$ = Get value: iRow, tsSeriesCol$[iSeries]
        dataVal = number (val$)
        selectObject: meltId
        Set numeric value: meltRow, "t", timeVal
        Set string value: meltRow, "eml_series", tsSeriesCol$[iSeries]
        Set numeric value: meltRow, "eml_value", dataVal
    endfor
endfor

@emlGraphsCarrySecondColumn: objectId, meltId, "cq", nDataRows

; THE COLUMN IS THERE, AND IT HOLDS THE SOURCE'S NUMBERS. Read back before
; anything is drawn, so a failure here names the copy rather than the figure.
selectObject: meltId
nCols_melt = Get number of columns
nRows_melt = Get number of rows
appendInfoLine: "MELTCOLS ", nCols_melt
appendInfoLine: "MELTROWS ", nRows_melt
r1$ = Get value: 1, "cq"
selectObject: objectId
s1$ = Get value: 1, "cq"
appendInfoLine: "CARRY1 ", r1$, " ", s1$
; The row the mapping has to get right: the first row of the SECOND series'
; block is row 1 of the source again.
selectObject: meltId
r2$ = Get value: nDataRows + 1, "cq"
appendInfoLine: "CARRY2 ", r2$, " ", s1$
; And the last row of the melt is the last row of the source.
rN$ = Get value: nMeltRows, "cq"
selectObject: objectId
sN$ = Get value: nDataRows, "cq"
appendInfoLine: "CARRYN ", rN$, " ", sN$

objectId = meltId
valueColName$ = "eml_value"
groupColName$ = "eml_series"
y_axis_label$ = "Value"
title$ = "Wide format, melted, with a right axis"
emlSecondAxisOn = 1
emlSecondAxisCol$ = "cq"
emlSecondAxisLabel$ = "Contact quotient"
emlSecondAxisStyle = 3
@emlGraphsDrawWithLegendRoom
@secondReport
@secondSave
