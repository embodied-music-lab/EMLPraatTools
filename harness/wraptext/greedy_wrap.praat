# ---------------------------------------------------------------------------
# THE PLAIN GREEDY WRAPPER — the baseline harness/wraptext/run.sh measures the
# shipped @emlWrapText against.
#
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# This is @emlWrapText with the "label = value" rule taken out and nothing
# else changed: the last space at or immediately after the width limit, wins,
# whatever sits either side of it. run.sh splices it into a staged copy of the
# plugin so that @emlDrawAnnotationBlock's fit loop -- which calls
# @emlWrapText by name -- runs against it unmodified.
#
# It is a FIXTURE, not plugin code. Nothing installs it and nothing includes
# it from the tree; keeping it here is what lets the comparison be re-run
# after the shipped procedure changes again.
# ---------------------------------------------------------------------------
procedure emlWrapText: .s$, .width
    .nLines = 0
    .rest$ = .s$
    while length (.rest$) > 0
        if length (.rest$) <= .width
            .nLines += 1
            .line$ [.nLines] = .rest$
            .rest$ = ""
        else
            # Last space at or immediately after the width limit. Breaking at
            # .width + 1 is correct: a space in that position means the word
            # ends exactly on the limit.
            .cut = 0
            for .i from 1 to .width + 1
                if mid$ (.rest$, .i, 1) = " "
                    .cut = .i
                endif
            endfor
            if .cut = 0
                # A single token longer than the line. Hard-break it rather
                # than emit an over-long line: column names can be arbitrary.
                .nLines += 1
                .line$ [.nLines] = left$ (.rest$, .width)
                .rest$ = mid$ (.rest$, .width + 1, length (.rest$))
            else
                .nLines += 1
                .line$ [.nLines] = left$ (.rest$, .cut - 1)
                .rest$ = mid$ (.rest$, .cut + 1, length (.rest$))
            endif
        endif
    endwhile
    if .nLines = 0
        .nLines = 1
        .line$ [1] = ""
    endif
endproc
