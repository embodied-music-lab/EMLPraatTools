#!/usr/bin/env python3
"""
build_coverage_map.py -- generates walkthrough/kit/coverage_map.tsv from
plugin_EML_StatsGraphs/REGISTRY.tsv and walkthrough/kit/matrix.tsv.

Run from the repo root:  python3 walkthrough/kit/build_coverage_map.py
Prints the TSV to stdout. To (re)write the committed file:
    python3 walkthrough/kit/build_coverage_map.py > walkthrough/kit/coverage_map.tsv

WHAT "numerically_covered" MEANS HERE, PRECISELY
-------------------------------------------------
walkthrough/kit/README.md states the kit's own scope: "The EML procedures
library contains 17 procedures" -- the distinct values of matrix.tsv's
`procedure` column, each run through both RUN_ME_FIRST.praat and
run_analyses.R and diffed by compare.R against an R oracle. A REGISTRY.tsv
row is "numerically_covered" here if and only if its name is one of those
17 -- i.e. it has at least one row (cell) in matrix.tsv. That is a
mechanical, re-derivable test: no hand-maintained yes/no list.

covering_kit_cells lists every matrix.tsv cell_id for that procedure,
semicolon-separated, in file order.

kind is inferred from the name/description, not hand-typed per row:
  - starts with "emlRun"                                -> analysis
  - description contains the bridge's own self-description,
    "the second path to the same statistics"             -> analysis
    (catches emlRunAnnotationComparison, which does not match emlRun*
    but runs the same four tests as the stats menu -- see
    mailbox/to-opus/RULING_REGISTRY_VERDICTS_2026-09-01.md #4)
  - else starts with "emlDraw"                           -> drawing
  - else                                                  -> utility

reason_if_not_covered is generated per kind:
  - drawing / utility rows get a templated clause plus the list of
    validate/*.R files that reference the procedure by name (grepped at
    build time, not hand-listed), because for these kinds "not numerically
    covered" is the CORRECT, by-design state (no scalar R-comparable
    output exists) rather than a gap.
  - emlRunLMMAnalysis and emlRunAnnotationComparison are the two exceptions:
    both are kind=analysis (they compute real statistics), so kind alone
    does not excuse the missing coverage. Their reasons are hardcoded
    below because they cite specific rulings, not a mechanical pattern:
    RULING_REGISTRY_VERDICTS_2026-09-01.md section 1 (LMM: ruled out of
    the 1.0 registry, removal not yet executed in REGISTRY.tsv) and
    section 4 (Bridge: duplicate implementation, unification ordered but
    not yet done). These are genuine, tracked gaps, not by-kind
    exclusions -- see mailbox/to-fable/REPORT_COVERAGE_MAP_2026-09-02.md.
"""
import glob
import os
import re
import sys

# Paths are relative to the CURRENT WORKING DIRECTORY, which must be the
# repo root -- see the "Run from the repo root" note above. This mirrors
# every other walkthrough/kit/*.R script in this repo (compare.R,
# run_analyses.R), none of which locate the root from __file__ either.
REGISTRY_PATH = os.path.join("plugin_EML_StatsGraphs", "REGISTRY.tsv")
MATRIX_PATH = os.path.join("walkthrough", "kit", "matrix.tsv")
VALIDATE_GLOB = os.path.join("validate", "*.R")

# The two documented, ruling-cited exceptions: kind=analysis rows that are
# NOT numerically covered for a reason that is NOT "correct for its kind"
# (unlike drawing/utility rows) but is nonetheless a tracked, ruled-on
# state rather than an unnoticed miss. See module docstring.
HARDCODED_REASONS = {
    "emlRunLMMAnalysis": (
        "GAP, tracked: kind=analysis (fits a real model and reports "
        "coefficients/CIs), so by kind it belongs in the kit like its 14 "
        "emlRun* siblings, and lme4/lmerTest are installed in this "
        "environment -- nothing blocks building an oracle. It has zero "
        "matrix.tsv cells today. Per Ian's ruling "
        "(mailbox/to-opus/RULING_REGISTRY_VERDICTS_2026-09-01.md #1), the "
        "row is ordered OUT of the registry for 1.0 (post-1.0; menu and "
        "wizard doors withdrawn) via the same exclusion-list mechanism "
        "used for emlRunReliabilityAnalysis -- but that removal has not "
        "executed: REGISTRY.tsv still carries this row (43 rows, 2026-09-02 "
        "compile) and validate/v155_public_registry.R's RUN_EXCLUSIONS "
        "list does not yet name it. Until the removal lands, this is a "
        "real, open gap, not a by-design exclusion."
    ),
    "emlRunAnnotationComparison": (
        "GAP, tracked: kind=analysis (runs the actual t-test/Mann-Whitney/"
        "ANOVA/Kruskal-Wallis behind a figure's annotation brackets -- 'the "
        "second path to the same statistics as the stats menu', its own "
        "REGISTRY.tsv description). It has zero matrix.tsv cells today "
        "because it currently carries its OWN duplicate implementation of "
        "those four tests rather than calling the Family A dispatch the "
        "kit's 200+96+67... cells already exercise. Per Ian's ruling "
        "(mailbox/to-opus/RULING_REGISTRY_VERDICTS_2026-09-01.md #4), "
        "unifying the bridge onto Family A is ordered before the "
        "authoritative run, after which 'the kit's canonical-route "
        "coverage picks up the unified path' -- not yet done, so today "
        "this row is genuinely uncovered, not correctly excluded."
    ),
}


def read_registry_rows(path):
    rows = []
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    header_seen = False
    for line in lines:
        if not line.strip():
            continue
        if line.startswith("#"):
            continue
        cols = line.split("\t")
        if not header_seen:
            assert cols[0] == "name", "unexpected REGISTRY.tsv header: %r" % (cols,)
            header_seen = True
            continue
        name, file_, signature, description, sources = (cols + [""] * 5)[:5]
        rows.append({"name": name, "description": description})
    assert header_seen, "REGISTRY.tsv header row not found"
    return rows


def read_matrix_cells(path):
    """procedure -> ordered list of cell_id, in file order."""
    cells = {}
    with open(path, encoding="utf-8") as fh:
        lines = fh.read().split("\n")
    header_seen = False
    for line in lines:
        if not line.strip():
            continue
        if line.startswith("#"):
            continue
        cols = line.split("\t")
        if not header_seen:
            assert cols[0] == "cell_id", "unexpected matrix.tsv header: %r" % (cols,)
            header_seen = True
            continue
        cell_id, lane, procedure = cols[0], cols[1], cols[2]
        cells.setdefault(procedure, []).append(cell_id)
    assert header_seen, "matrix.tsv header row not found"
    return cells


def classify_kind(name, description):
    if name.startswith("emlRun"):
        return "analysis"
    if "the second path to the same statistics" in description:
        return "analysis"
    if name.startswith("emlDraw"):
        return "drawing"
    return "utility"


_validate_files_cache = None


def validators_mentioning(name):
    global _validate_files_cache
    if _validate_files_cache is None:
        _validate_files_cache = sorted(glob.glob(VALIDATE_GLOB))
    hits = []
    pattern = re.compile(re.escape(name))
    for path in _validate_files_cache:
        try:
            with open(path, encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError:
            continue
        if pattern.search(text):
            hits.append(os.path.basename(path))
    return hits


def first_clause(description):
    """The description up to its first '. ' or period, for a short gloss."""
    m = re.search(r"^(.*?\.)(\s|$)", description)
    clause = m.group(1) if m else description
    # Drop a trailing period for smoother embedding in our own sentence.
    return clause[:-1] if clause.endswith(".") else clause


def build_reason(name, description, kind):
    if name in HARDCODED_REASONS:
        return HARDCODED_REASONS[name]
    validators = validators_mentioning(name)
    if validators:
        checked_by = "Checked structurally instead by " + "; ".join(validators) + "."
    else:
        checked_by = "No validate/*.R file references it by name (UNMEASURED beyond this grep)."
    gloss = first_clause(description)
    if kind == "drawing":
        return (
            "drawing procedure (%s) -- renders a Praat Picture-window "
            "figure, not a scalar statistic. The kit (matrix.tsv/"
            "quantities.tsv; see walkthrough/kit/results/coverage.md) "
            "compares only the 17 procedures that return numbers, so a "
            "figure has nothing there to numerically diff against. %s"
            % (gloss, checked_by)
        )
    if kind == "utility":
        return (
            "utility procedure (%s) -- internal plumbing/orchestration "
            "with no scalar statistical result of its own, so there is no "
            "R-computed number to compare it against. %s"
            % (gloss, checked_by)
        )
    # Should not be reached: every non-hardcoded analysis row is covered.
    return "UNCLASSIFIED -- %s" % checked_by


def main():
    registry_rows = read_registry_rows(REGISTRY_PATH)
    matrix_cells = read_matrix_cells(MATRIX_PATH)

    out = []
    out.append(
        "# coverage_map.tsv -- generated by walkthrough/kit/build_coverage_map.py"
    )
    out.append(
        "# DO NOT HAND-EDIT. Regenerate with:"
        " python3 walkthrough/kit/build_coverage_map.py > walkthrough/kit/coverage_map.tsv"
    )
    out.append(
        "# One row per plugin_EML_StatsGraphs/REGISTRY.tsv row (43 as of the"
        " 2026-09-01 compile). numerically_covered=yes means the name is one"
        " of the 17 procedures walkthrough/kit/matrix.tsv actually runs and"
        " compare.R diffs against an R oracle."
    )
    out.append(
        "registry_name\tkind\tnumerically_covered\tcovering_kit_cells\treason_if_not_covered"
    )

    n_yes = 0
    n_no = 0
    for row in registry_rows:
        name = row["name"]
        description = row["description"]
        kind = classify_kind(name, description)
        cells = matrix_cells.get(name, [])
        if cells:
            numerically_covered = "yes"
            covering = ";".join(cells)
            reason = ""
            n_yes += 1
        else:
            numerically_covered = "no"
            covering = ""
            reason = build_reason(name, description, kind)
            n_no += 1
        out.append(
            "\t".join([name, kind, numerically_covered, covering, reason])
        )

    sys.stdout.write("\n".join(out) + "\n")
    sys.stderr.write(
        "build_coverage_map.py: %d registry rows, %d numerically_covered=yes,"
        " %d numerically_covered=no\n" % (len(registry_rows), n_yes, n_no)
    )


if __name__ == "__main__":
    main()
