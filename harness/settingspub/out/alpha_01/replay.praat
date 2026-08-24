Text writing preferences: "UTF-8"
Read Table from comma-separated file: "/home/claude/repo/harness/settingspub/out/alpha_01/fx.csv"
clearinfo
include /home/claude/repo/harness/settingspub/out/alpha_01/emitted.praat
writeFileLine: "/home/claude/repo/harness/settingspub/out/alpha_01/replay_info.txt", info$ ()
procedure spOut: .key$, .value$
    appendFileLine: "/home/claude/repo/harness/settingspub/out/SETTINGSPUB.tsv", .key$, tab$, .value$
endproc
@spOut: "alpha_01_replay_brackets", string$ (annotBracketN)
@spOut: "alpha_01_replay_adjust", annotBracketAdjust$
for b from 1 to annotBracketN
    @spOut: "alpha_01_replay_p" + string$ (b), fixed$ (annotBracketP[b], 6)
    @spOut: "alpha_01_replay_label" + string$ (b), annotBracketLabel$[b]
endfor
if variableExists ("annotAlpha")
    @spOut: "alpha_01_replay_alpha_inforce", string$ (annotAlpha)
else
    @spOut: "alpha_01_replay_alpha_inforce", "<unset>"
endif
if variableExists ("emlGroupSortAlphabetical")
    @spOut: "alpha_01_replay_sort_inforce", string$ (emlGroupSortAlphabetical)
else
    @spOut: "alpha_01_replay_sort_inforce", "<unset>"
endif
if variableExists ("annotCorrectionMethod$")
    @spOut: "alpha_01_replay_corr_inforce", annotCorrectionMethod$
else
    @spOut: "alpha_01_replay_corr_inforce", "<unset>"
endif
