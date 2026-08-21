Read Table from comma-separated file: "/home/claude/repo/harness/edithook/out/H_input.csv"
appendInfoLine: "REPLAY opened|", selected$ ()
runScript: "/home/claude/repo/harness/edithook/out/H_naive.praat"
nocheck selectObject: "Table H_input"
if numberOfSelected () = 1
    Save as comma-separated file: "/home/claude/repo/harness/edithook/out/H_naive_table.csv"
    .a = Extract rows where column (text): "group", "is equal to", "A"
    .m = Get mean: "f0_Hz"
    appendInfoLine: "REPLAY groupA mean|", fixed$ (.m, 4)
else
    appendInfoLine: "REPLAY groupA mean|NO TABLE"
endif
