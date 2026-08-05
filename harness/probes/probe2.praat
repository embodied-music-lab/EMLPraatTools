out$ = "/home/claude/drive/out/probe2.txt"
writeFileLine: out$, "start ", praatVersion$
beginPause: "Test dialog"
    comment: "A comment"
    optionmenu: "Pick one", 2
        option: "alpha"
        option: "beta"
        option: "gamma"
    real: "Some number", 3.5
clicked = endPause: "Quit", "Run", 2, 0
appendFileLine: out$, "clicked=", clicked
appendFileLine: out$, "pick_one=", pick_one, " pick_one$=", pick_one$
appendFileLine: out$, "some_number=", some_number
appendFileLine: out$, "DONE"
