# Two tables, so that two passes each draw a figure and each save it with a
# different format choice.
procedure mkS: .nm$, .seed, .lift
    Create Table with column names: .nm$, 0, "grp val"
    .st = .seed
    for .g from 1 to 2
        for .k from 1 to 12
            .st = (1103515245 * .st + 12345) mod 2147483648
            Append row
            .r = Get number of rows
            Set string value: .r, "grp", "G" + string$ (.g)
            Set numeric value: .r, "val",
            ... 5 + .lift + .g * 1.5 + (.st / 2147483648 - 0.5) * 1.2
        endfor
    endfor
    .id = selected ("Table")
endproc
@mkS: "sa", 121212, 0
tableSa = mkS.id
@mkS: "sb", 343434, 10
tableSb = mkS.id
