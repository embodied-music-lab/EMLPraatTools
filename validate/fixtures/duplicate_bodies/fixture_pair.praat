# ============================================================================
# validate/fixtures/duplicate_bodies/fixture_pair.praat
# ============================================================================
# Ian Howell -- Embodied Music Lab -- GPL-3.0-or-later
#
# RED-DEMO FIXTURE for validate/vNNN_duplicate_bodies.R's self-test. Two
# procedures with the same 40+-token computation, differing only in a
# numeric literal and a couple of local-variable names -- exactly the shape
# duplicate_bodies.py's normalisation (mask numbers to N, mask .local
# identifiers to .V) is supposed to see through. This file is scanned ONLY
# by the self-test, in isolation, never as part of the main plugin-tree
# scan (which walks plugin_EML_StatsGraphs/, not validate/fixtures/).
# ============================================================================

procedure fixtureAlphaCompute: .n
    .sum = 0
    .count = 0
    for .i from 1 to .n
        .value = .i * 2 + 1
        .sum = .sum + .value
        .count = .count + 1
        if .value > 10
            .flag = 1
        else
            .flag = 0
        endif
        .running = .sum / .count
        .scaled = .running * 3.5
        .adjusted = .scaled - 0.5
        .clamped = .adjusted
        if .clamped < 0
            .clamped = 0
        endif
        appendInfoLine: "step ", .i, " value=", .value, " running=", .running
    endfor
    .mean = .sum / .count
    .variance = 0
    for .j from 1 to .n
        .dev = .j - .mean
        .variance = .variance + .dev * .dev
    endfor
    .variance = .variance / .count
    .result = .mean + .variance
endproc

procedure fixtureBetaCompute: .n
    .total = 0
    .tally = 0
    for .k from 1 to .n
        .amount = .k * 2 + 1
        .total = .total + .amount
        .tally = .tally + 1
        if .amount > 10
            .marker = 1
        else
            .marker = 0
        endif
        .avg = .total / .tally
        .stretched = .avg * 3.5
        .shifted = .stretched - 0.5
        .bounded = .shifted
        if .bounded < 0
            .bounded = 0
        endif
        appendInfoLine: "step ", .k, " value=", .amount, " running=", .avg
    endfor
    .center = .total / .tally
    .spread = 0
    for .m from 1 to .n
        .diff = .m - .center
        .spread = .spread + .diff * .diff
    endfor
    .spread = .spread / .tally
    .outcome = .center + .spread
endproc
