# Three tables, each with a column called "n". Three passes, three runs.
procedure mkTable: .nm$, .grpCol$, .seed, .base, .spread
    Create Table with column names: .nm$, 0, .grpCol$ + " n"
    .st = .seed
    for .g from 1 to 2
        for .k from 1 to 10
            .st = (1103515245 * .st + 12345) mod 2147483648
            Append row
            .r = Get number of rows
            Set string value: .r, .grpCol$, "L" + string$ (.g)
            Set numeric value: .r, "n",
            ... .base + .g * .spread + (.st / 2147483648 - 0.5) * 1.0
        endfor
    endfor
    .id = selected ("Table")
endproc
@mkTable: "t1", "site", 111, 2.5, 1.0
t1 = mkTable.id
@mkTable: "t2", "ward", 222, 9.0, 2.0
t2 = mkTable.id
@mkTable: "t3", "block", 333, 20.0, 4.0
t3 = mkTable.id
