# Two tables whose figures are drawn on the SAME typed axis literals. The
# old (role, literal) key made those one variable; the run rule makes them
# two, and the difference is visible only when one of them is edited.
procedure mkAx: .nm$, .seed, .lift
    Create Table with column names: .nm$, 0, "grp val"
    .st = .seed
    for .g from 1 to 2
        for .k from 1 to 12
            .st = (1103515245 * .st + 12345) mod 2147483648
            Append row
            .r = Get number of rows
            Set string value: .r, "grp", "G" + string$ (.g)
            Set numeric value: .r, "val",
            ... 6 + .lift + .g * 2.0 + (.st / 2147483648 - 0.5) * 1.5
        endfor
    endfor
    .id = selected ("Table")
endproc
@mkAx: "ax1", 606061, 0
tableAx1 = mkAx.id
@mkAx: "ax2", 707071, 6
tableAx2 = mkAx.id
