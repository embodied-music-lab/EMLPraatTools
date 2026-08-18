# ONE table drawn twice, plus a same-shape TWIN with different numbers for
# the retarget drive to point run 2 at.
procedure mkOne: .nm$, .seed, .lift
    Create Table with column names: .nm$, 0, "grp val other"
    .st = .seed
    for .g from 1 to 2
        for .k from 1 to 12
            .st = (1103515245 * .st + 12345) mod 2147483648
            Append row
            .r = Get number of rows
            Set string value: .r, "grp", "G" + string$ (.g)
            Set numeric value: .r, "val",
            ... 5 + .lift + .g * 1.5 + (.st / 2147483648 - 0.5) * 1.2
            .st = (1103515245 * .st + 12345) mod 2147483648
            Set numeric value: .r, "other",
            ... 12 + .lift + .g * 2.5 + (.st / 2147483648 - 0.5) * 1.4
        endfor
    endfor
    .id = selected ("Table")
endproc
@mkOne: "one", 505050, 0
tableOne = mkOne.id
@mkOne: "twin", 818181, 6
tableTwin = mkOne.id
