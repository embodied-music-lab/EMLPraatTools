Create Table with column names: "demo", 3, "id tag"
tableId = selected ("Table")
for r to 3
    selectObject: tableId
    Set string value: r, "id", "S" + string$ (r)
    Set string value: r, "tag", "keep"
endfor
