tableId = Create Table with column names: "test", 3, "name value group"
Set string value: 1, "name", "Alice"
Set numeric value: 1, "value", 10
Set string value: 1, "group", "A"

selectObject: tableId
nCols = Get number of columns
for iCol from 1 to nCols
    col$ = Get column label: iCol
    # Try to read as string first - if it's numeric, this returns the number as string
    val$ = Get value: 1, col$
    # Numeric columns: nocheck Get value will return a number
    # String columns: Get value returns a string
    # The test: can it be parsed as a number?
    appendInfoLine: col$, ": ", val$
endfor

removeObject: tableId
