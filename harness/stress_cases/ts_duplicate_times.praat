include _prelude.praat
# Six rows, two observations at each of three times. A time series drawn from
# unaggregated long-format data — the shape every EML stats tool produces.
t = Create Table with column names: "dup", 6, "time val"
Set numeric value: 1, "time", 1
Set numeric value: 1, "val", 10
Set numeric value: 2, "time", 1
Set numeric value: 2, "val", 20
Set numeric value: 3, "time", 2
Set numeric value: 3, "val", 12
Set numeric value: 4, "time", 2
Set numeric value: 4, "val", 22
Set numeric value: 5, "time", 3
Set numeric value: 5, "val", 14
Set numeric value: 6, "time", 3
Set numeric value: 6, "val", 24
Erase all
@emlDrawTimeSeries: t, "Two observations per time point", "Time", "Value", 6, 4, "color", 1, "time", "val", "", 0, 0, 0, 0
@stressSave: 6, 4
