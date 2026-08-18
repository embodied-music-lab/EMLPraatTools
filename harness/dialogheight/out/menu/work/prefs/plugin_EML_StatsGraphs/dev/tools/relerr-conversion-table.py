#!/usr/bin/env python3
# relerr-conversion-table.py -- the provenance record for the 31 assertion
# sites converted from absolute to relative tolerance.
#
# Each row is (file, line, label, the literal as it stood BEFORE conversion,
# the full-precision external reference it was checked against, and the
# relative band adopted). Printing this table regenerates the measured
# margin for each site on demand instead of relying on a chat transcript.
#
# This is a record, not a mutator. See relerr-convert-APPLIED.py for the
# one-shot in-place converter, which has already run and is not re-runnable.
#
# (file, line, label, old_literal_str, external_ref, proposed_band)
SITES = [
 ("batch6",  248, "4 Treatment p",          "0.0000000002", 1.8417416012516266e-10, 1e-9),
 ("batch6b", 399, "Sch-3 p(1,4)",           "0.00000013",   1.2908179064156406e-07, 1e-9),
 ("batch6",  488, "6 G1vG4 p [1,4]",        "0.0000000024", 2.4493583827833731e-09, 1e-5),
 ("batch6",  494, "6 G3vG4 p [3,4]",        "0.0000000024", 2.4493583827833731e-09, 1e-5),
 ("batch6b", 401, "Sch-3 p(3,4)",           "0.00000125",   1.25167562686556e-06,   1e-9),
 ("batch6",  484, "6 G1vG2 p [1,2]",        "0.000168",     0.0001678125368753669,  1e-5),
 ("batch6",  490, "6 G2vG3 p [2,3]",        "0.000168",     0.0001678125368753669,  1e-5),
 ("batch6b", 362, "Sch-1 p(2,3)",           "0.00000254",   2.5365408557837916e-06, 1e-9),
 ("batch6b", 165, "PT-3 adj p(1,4)",        "0.00000482",   4.8248724387226795e-06, 1e-9),
 ("batch6",  569, "7 Tukey G1vG2 p [1,2]",  "0.000502",     0.00050241679335449874, 1e-5),
 ("batch6b", 113, "PT-1 raw p(2,3)",        "0.00001155",   1.1548137118699003e-05, 1e-9),
 ("batch6",  571, "7 Tukey G1vG3 p [1,3]",  "0.003167",     0.0031672735041667899,  1e-5),
 ("batch6b", 121, "PT-1 adj p(2,3) Bonf",   "0.00003464",   3.4644411356097008e-05, 1e-9),
 ("batch6b", 202, "PT-1 adj p(2,3) Holm",   "0.00003464",   3.4644411356097008e-05, 1e-9),
 ("batch6",  820, "10 BvC p [2,3]",         "0.004909",     0.0049093339786908663,  1e-5),
 ("batch3",  125, "MWU-2.3 p(2)",           "0.00003",      2.5375976669349799e-05, 1e-9),
 ("batch6",  390, "5 FactorB p",            "0.000000797",  7.9713953719715604e-07, 1e-9),
 ("batch6",  818, "10 AvC p [1,3]",         "0.01004",      0.010044272660155618,   1e-5),
 ("batch6",  141, "3 p",                    "0.001053",     0.0010528257933665353,  1e-9),
 ("batch6b", 167, "PT-3 adj p(2,4)",        "0.00145398",   0.001453982146481067,   1e-9),
 ("batch6b", 169, "PT-3 adj p(3,4)",        "0.00162428",   0.0016242762642005777,  1e-9),
 ("batch6",  573, "7 Tukey G2vG3 p [2,3]",  "0.0000017",    1.6833576830244112e-06, 1e-5),
 ("batch6",   65, "1 p",                    "0.0000024783", 2.4783299490103907e-06, 1e-9),
 ("batch7",  373, "Dunn-1 raw p(2,3)",      "0.00045952",   0.0004595179363709061,  1e-9),
 ("batch3",   97, "MWU-1.7 p(2)",           "0.00507539",   0.0050753923152739256,  1e-9),
 ("batch6",  492, "6 G2vG4 p [2,4]",        "0.0000056",    5.6000977631809334e-06, 1e-5),
 ("batch2",   45, "Set A p (1-tail)",       "0.0620",       0.062013531328777301,   1e-9),
 ("batch6b", 358, "Sch-1 p(1,2)",           "0.00070802",   0.00070802301066272538, 1e-9),
 ("batch2",  138, "Set A p (1-tail)",       "0.0773",       0.077309261564224629,   1e-9),
 ("batch6b", 109, "PT-1 raw p(1,2)",        "0.00083766",   0.00083766493825540253, 1e-9),
 ("batch6",  397, "5 Interact p",           "0.00000939",   9.3942090860376175e-06, 1e-9),
]


# ---------------------------------------------------------------------------
# REPORTER
#
# Persisted 3 Aug 2026. The original /tmp/conv/table.py was a bare data
# module: it exited 0 and printed nothing, which is indistinguishable from a
# tool that ran every check and passed. This reporter makes the module state
# and check a claim.
#
# WHAT THIS TOOL VERIFIES (and what it does not)
#
# The conversion did two things at each site: it replaced a ROUNDED decimal
# literal with the FULL-PRECISION external reference, and it swapped an
# absolute tolerance for a relative band. The post-conversion agreement
# between Praat's computed value and the reference is measured by RUNNING
# the suites -- this tool cannot and does not measure it. Do not read the
# numbers below as a pass margin for the assertions.
#
# What this tool DOES check, from saved data alone, is the premise of the
# conversion: that every pre-conversion literal was a faithful rounding of
# the reference it was standing in for. Formally, for a literal printed to
# d decimal places,
#
#     |old_literal - external_ref|  <=  0.5 * 10^-d      (half a unit in
#                                                         the last place)
#
# If that holds, the conversion preserved meaning and only added precision.
# If it fails at any site, the literal and the reference disagree by more
# than rounding can explain -- which would mean the site was checking a
# DIFFERENT number than the reference claims, and the conversion silently
# changed what the assertion tests. That is a real defect, and it is the
# reason this check exists.
#
# The rounding column also shows why the conversion was necessary: several
# literals were rounded to ~1e-4 relative, so a 1e-9 relative band applied
# to the OLD literal would have failed. Replacing the literal was not
# cosmetic.
#
# Exit status: 0 if every literal is a faithful rounding, 1 otherwise.
# ---------------------------------------------------------------------------

def decimals_of(lit):
    """Number of digits printed after the decimal point in the literal."""
    if "." not in lit:
        return 0
    return len(lit.split(".", 1)[1])


def main():
    rows = []
    for f, line, label, old_str, ref, band in SITES:
        old = float(old_str)
        d = decimals_of(old_str)
        half_ulp = 0.5 * (10.0 ** -d)
        diff = abs(old - ref)
        rel_round = diff / abs(ref)
        faithful = diff <= half_ulp
        headroom = (half_ulp / diff) if diff > 0 else float("inf")
        rows.append((f, line, label, old_str, ref, band,
                     d, half_ulp, diff, rel_round, faithful, headroom))

    rows_sorted = sorted(rows, key=lambda r: r[11])

    print("REL-ERR CONVERSION PROVENANCE -- %d sites" % len(rows))
    print("")
    print("Check: each pre-conversion literal is a faithful rounding of the")
    print("external reference that replaced it (|old - ref| <= 0.5 ulp).")
    print("The 'rounding' column is the relative error the OLD literal")
    print("carried -- it is NOT a post-conversion assertion margin.")
    print("")
    hdr = "%-8s %5s  %-24s %-14s %-24s %-8s %-10s %-10s %s" % (
        "file", "line", "label", "old literal", "external ref",
        "band", "0.5ulp", "rounding", "faithful")
    print(hdr)
    print("-" * len(hdr))
    for (f, line, label, old_str, ref, band, d, half_ulp,
         diff, rel_round, faithful, headroom) in rows_sorted:
        print("%-8s %5d  %-24s %-14s %-24.17g %-8.0e %-10.1e %-10.3e %s" % (
            f, line, label, old_str, ref, band, half_ulp, rel_round,
            "yes" if faithful else "NO"))

    bad = [r for r in rows if not r[10]]
    worst = rows_sorted[0]
    print("")
    print("sites: %d" % len(rows))
    print("tightest rounding headroom: %.2f of 0.5 ulp used at %s:%d %s" % (
        1.0 / worst[11] if worst[11] else 0.0, worst[0], worst[1], worst[2]))
    print("largest old-literal rounding error: %.3e relative (%s:%d %s)" % (
        max(r[9] for r in rows),
        *[(r[0], r[1], r[2]) for r in rows if r[9] == max(x[9] for x in rows)][0]))
    print("bands in use: %s" % ", ".join(
        sorted({"%.0e" % r[5] for r in rows})))

    if bad:
        print("")
        print("FAIL: %d literal(s) differ from the reference by more than "
              "rounding can explain --" % len(bad))
        print("the conversion changed WHAT these assertions test:")
        for r in bad:
            print("  %s:%d %s  old=%s ref=%.17g diff=%.3e > 0.5ulp=%.1e" % (
                r[0], r[1], r[2], r[3], r[4], r[8], r[7]))
        return 1

    print("")
    print("PASS: all %d pre-conversion literals are faithful roundings of "
          "their references." % len(rows))
    print("The conversion added precision without changing any expected value.")
    print("")
    print("NOTE: post-conversion agreement between Praat and the references is")
    print("measured by running the suites, not by this tool.")
    return 0


if __name__ == "__main__":
    import sys
    sys.exit(main())
