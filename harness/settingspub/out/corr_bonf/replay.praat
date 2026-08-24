Text writing preferences: "UTF-8"
Read Table from comma-separated file: "/home/claude/repo/harness/settingspub/out/corr_bonf/fx.csv"
clearinfo
include /home/claude/repo/harness/settingspub/out/corr_bonf/emitted.praat
writeFileLine: "/home/claude/repo/harness/settingspub/out/corr_bonf/replay_info.txt", info$ ()
procedure spOut: .key$, .value$
    appendFileLine: "/home/claude/repo/harness/settingspub/out/SETTINGSPUB.tsv", .key$, tab$, .value$
endproc
@spOut: "corr_bonf_replay_brackets", string$ (annotBracketN)
@spOut: "corr_bonf_replay_adjust", annotBracketAdjust$
for b from 1 to annotBracketN
    @spOut: "corr_bonf_replay_p" + string$ (b), fixed$ (annotBracketP[b], 6)
    @spOut: "corr_bonf_replay_label" + string$ (b), annotBracketLabel$[b]
endfor
if variableExists ("annotAlpha")
    @spOut: "corr_bonf_replay_alpha_inforce", string$ (annotAlpha)
else
    @spOut: "corr_bonf_replay_alpha_inforce", "<unset>"
endif
if variableExists ("emlGroupSortAlphabetical")
    @spOut: "corr_bonf_replay_sort_inforce", string$ (emlGroupSortAlphabetical)
else
    @spOut: "corr_bonf_replay_sort_inforce", "<unset>"
endif
if variableExists ("annotCorrectionMethod$")
    @spOut: "corr_bonf_replay_corr_inforce", annotCorrectionMethod$
else
    @spOut: "corr_bonf_replay_corr_inforce", "<unset>"
endif
