Create Table with column names: "demo", 3, "id colA colB"
tableId = selected ("Table")
for r to 3
    selectObject: tableId
    Set string value: r, "id", "S" + string$ (r)
    Set string value: r, "colA", "A" + string$ (r)
    Set string value: r, "colB", "B" + string$ (r)
endfor
# The duplicate arrives with the data, exactly as a CSV would deliver it.
selectObject: tableId
Rename column (by number): 3, "colA"
