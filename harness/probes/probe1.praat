out$ = "/home/claude/drive/out/probe1.txt"
writeFileLine: out$, "praat=", praatVersion$
appendFileLine: out$, "prefdir=", preferencesDirectory$
appendFileLine: out$, "PLUGIN_LOADED"
Quit
