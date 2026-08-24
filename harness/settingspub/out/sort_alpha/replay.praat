Text writing preferences: "UTF-8"
Read Table from comma-separated file: "/home/claude/repo/harness/settingspub/out/sort_alpha/fx.csv"
clearinfo
include /home/claude/repo/harness/settingspub/out/sort_alpha/emitted.praat
writeFileLine: "/home/claude/repo/harness/settingspub/out/sort_alpha/replay_info.txt", info$ ()
procedure spOut: .key$, .value$
    appendFileLine: "/home/claude/repo/harness/settingspub/out/SETTINGSPUB.tsv", .key$, tab$, .value$
endproc
@spOut: "sort_alpha_replay_brackets", string$ (annotBracketN)
@spOut: "sort_alpha_replay_adjust", annotBracketAdjust$
for b from 1 to annotBracketN
    @spOut: "sort_alpha_replay_p" + string$ (b), fixed$ (annotBracketP[b], 6)
    @spOut: "sort_alpha_replay_label" + string$ (b), annotBracketLabel$[b]
endfor
if variableExists ("annotAlpha")
    @spOut: "sort_alpha_replay_alpha_inforce", string$ (annotAlpha)
else
    @spOut: "sort_alpha_replay_alpha_inforce", "<unset>"
endif
if variableExists ("emlGroupSortAlphabetical")
    @spOut: "sort_alpha_replay_sort_inforce", string$ (emlGroupSortAlphabetical)
else
    @spOut: "sort_alpha_replay_sort_inforce", "<unset>"
endif
if variableExists ("annotCorrectionMethod$")
    @spOut: "sort_alpha_replay_corr_inforce", annotCorrectionMethod$
else
    @spOut: "sort_alpha_replay_corr_inforce", "<unset>"
endif
