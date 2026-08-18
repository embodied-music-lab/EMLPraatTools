# A box plot's roles and a scatter's roles do not overlap: xCol and yCol
# appear in run 2 and nowhere in run 1.
Create Table with column names: "box", 0, "grp val"
st = 4242
for g from 1 to 2
    for k from 1 to 10
        st = (1103515245 * st + 12345) mod 2147483648
        Append row
        r = Get number of rows
        Set string value: r, "grp", "G" + string$ (g)
        Set numeric value: r, "val", 4 + g + (st / 2147483648 - 0.5) * 1.5
    endfor
endfor
tableBox = selected ("Table")
Create Table with column names: "sc", 0, "xx yy cohort"
st = 991177
for g from 1 to 2
    for k from 1 to 14
        st = (1103515245 * st + 12345) mod 2147483648
        Append row
        r = Get number of rows
        Set string value: r, "cohort", "C" + string$ (g)
        Set numeric value: r, "xx", k + g * 3 + (st / 2147483648 - 0.5) * 2
        st = (1103515245 * st + 12345) mod 2147483648
        Set numeric value: r, "yy", 10 + k * 1.2 + g * 4
        ... + (st / 2147483648 - 0.5) * 3
    endfor
endfor
tableSc = selected ("Table")
