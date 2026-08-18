# Two tables that each call their count column "n" -- the collision the
# (role, literal) key used to collapse into one variable.
Create Table with column names: "cityA", 0, "site n"
st = 20260817
for g from 1 to 2
    for k from 1 to 12
        st = (1103515245 * st + 12345) mod 2147483648
        Append row
        r = Get number of rows
        Set string value: r, "site", "Site " + string$ (g)
        Set numeric value: r, "n", 3 + g * 1.5 + (st / 2147483648 - 0.5) * 1.2
    endfor
endfor
tableA = selected ("Table")
Create Table with column names: "cityB", 0, "ward n"
st = 77770001
for g from 1 to 2
    for k from 1 to 12
        st = (1103515245 * st + 12345) mod 2147483648
        Append row
        r = Get number of rows
        Set string value: r, "ward", "Ward " + string$ (g)
        Set numeric value: r, "n", 9 + g * 2.0 + (st / 2147483648 - 0.5) * 1.6
    endfor
endfor
tableB = selected ("Table")
