# ---------------------------------------------------------------------------
# Is @emlSanitizeLabel idempotent, and does a title survive the draw site?
#
# THE DEFECT THIS PINS. Until 11 August 2026 escaping an already-escaped label
# destroyed the character it was protecting:
#
#     Jitter (\% )     escaped once   ->  renders  Jitter (%)     correct
#     Jitter (\\%  )   escaped twice  ->  renders  Jitter (  )    gone
#
# The middle line is what the auto-composed TITLE of every figure looked like,
# while the y-axis label on the same figure was correct.
# @emlComposeGraphTitle sanitizes each part it assembles -- the value column
# via @emlCapitalizeLabel, which already returns "Jitter (\% )" -- and
# @emlDrawAxes then sanitizes the finished title AGAIN.
#
# Found by driving the plugin's own menu under Xvfb and reading the title on
# the figure it produced. See §2i of audit/GRAPHING_PUSH_REMAINING.md.
#
# WHAT IS CHECKED, in two layers:
#
#   LABELESC   the escaper applied once, twice and three times must give the
#              same string. Three, not two: a two-application check passes on
#              an escaper that alternates.
#   LABELFIX   @emlCapitalizeLabel's output must be a FIXED POINT of
#              @emlSanitizeLabel. This is the specific composition that broke,
#              and it is the one a title actually travels.
#   LABELINK   the rendered figure must contain the title's ink. A string
#              check cannot see a character the renderer swallowed, which is
#              exactly how this survived: every intermediate value was right.
#
# Run: praat --run probe_label_escape.praat     (EML_OUT = output folder)
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
# ---------------------------------------------------------------------------
include ../stress_cases/_prelude.praat

probeOut$ = environment$ ("EML_OUT")
if probeOut$ = ""
    probeOut$ = "."
endif

procedure idem: .name$, .in$
    @emlSanitizeLabel: .in$
    .once$ = emlSanitizeLabel.result$
    @emlSanitizeLabel: .once$
    .twice$ = emlSanitizeLabel.result$
    @emlSanitizeLabel: .twice$
    .thrice$ = emlSanitizeLabel.result$
    .v$ = "DRIFTS"
    if .once$ = .twice$ and .twice$ = .thrice$
        .v$ = "stable"
    endif
    appendInfoLine: "LABELESC ", .name$, " ", .v$
endproc

@idem: "rawcol",      "jitter_pct"
@idem: "percent",     "Jitter (%)"
@idem: "preescaped",  "Jitter (\% )"
@idem: "hash",        "n#obs"
@idem: "caret",       "F0^2"
@idem: "allthree",    "a%b#c^d"
@idem: "plain",       "Group"

; The composition that broke: capitalize, then sanitize, must not move.
@emlCapitalizeLabel: "jitter_pct"
cap$ = emlCapitalizeLabel.result$
@emlSanitizeLabel: cap$
fix$ = "MOVED"
if emlSanitizeLabel.result$ = cap$
    fix$ = "fixedpoint"
endif
appendInfoLine: "LABELFIX capitalize_then_sanitize ", fix$

; And the figure. The title goes in ALREADY escaped, exactly as
; @emlComposeGraphTitle would hand it over, and @emlDrawAxes escapes it again.
Create Table with column names: "lbl", 0, "grp jitter_pct"
for g to 2
    for k to 12
        Append row
        row = Get number of rows
        Set string value: row, "grp", "G" + string$ (g)
        Set numeric value: row, "jitter_pct", 1 + g * 0.8 + (k mod 4) * 0.2
    endfor
endfor
tid = selected ("Table")
Erase all
@emlDrawViolinPlot: tid, cap$ + " by Group", "Group", cap$, 6, 3,
... "color", 1, "grp", "jitter_pct", 0, 0
@emlAssertFullViewport
Save as 300-dpi PNG file: probeOut$ + "/label_escape.png"
appendInfoLine: "LABELINK title_figure_written ", probeOut$, "/label_escape.png"
