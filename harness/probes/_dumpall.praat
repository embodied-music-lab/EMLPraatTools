names$# = { "demo_paired", "demo_3groups", "demo_correlation", "demo_regression", "demo_twoway" }
for k from 1 to size (names$#)
    nm$ = names$# [k]
    select all
    n = numberOfSelected ()
    id = 0
    for i from 1 to n
        if selected$ (i) = "Table " + nm$
            id = selected (i)
        endif
    endfor
    if id > 0
        selectObject: id
        nr = Get number of rows
        nc = Get number of columns
        out$ = "/home/claude/drive/out/dump_" + nm$ + ".csv"
        hdr$ = ""
        for c from 1 to nc
            selectObject: id
            lab$ = Get column label: c
            lab$[c] = lab$
            if c > 1
                hdr$ = hdr$ + ","
            endif
            hdr$ = hdr$ + lab$
        endfor
        writeFileLine: out$, hdr$
        for r from 1 to nr
            row$ = ""
            for c from 1 to nc
                selectObject: id
                cl$ = lab$[c]
                v$ = Get value: r, cl$
                if c > 1
                    row$ = row$ + ","
                endif
                row$ = row$ + v$
            endfor
            appendFileLine: out$, row$
        endfor
    endif
endfor
