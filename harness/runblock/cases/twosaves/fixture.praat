# One table, one pass, one save -- the ordinary case the ruling must leave
# exactly where it was.
Create Table with column names: "vt", 0, "grp val"
st = 606060
for g from 1 to 2
    for k from 1 to 12
        st = (1103515245 * st + 12345) mod 2147483648
        Append row
        r = Get number of rows
        Set string value: r, "grp", "G" + string$ (g)
        Set numeric value: r, "val", 5 + g * 1.5 + (st / 2147483648 - 0.5) * 1.2
    endfor
endfor
tableVt = selected ("Table")
