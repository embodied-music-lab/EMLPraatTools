#!/usr/bin/env python3
# ============================================================================
# run-tests.py — EML Praat Tools test runner
# ============================================================================
# Purpose: Discover and execute the Praat test suites under dev/tests/, one
#          process per suite, and classify each result according to the TEST
#          RESULT REPORTING CONTRACT (v1.1) documented at the head of
#          dev/tests/eml-test-helpers.praat.
#
#          The contract's binding clause is that a runner MUST NOT treat
#          "exit 0" as sufficient evidence of a green suite. Praat's exit
#          status is binary (0 = clean, 255 = exitScript/failed assert), so
#          the three required outcomes (PASS / FAIL / INCOMPLETE) are carried
#          by a stdout sentinel:
#
#              EMLTEST-RESULT: status=PASS passed=57 failed=0 skipped=0 total=57
#
#          Absence of the sentinel means the suite died before reaching
#          @emlTestSummary and is reported as NO-SENTINEL, which is a failure,
#          not a pass.
#
# Date: 3 August 2026
# Version: 1.0
#
# ATTRIBUTION
# Framework: EML PraatGen by Ian Howell
#            Embodied Music Lab — www.embodiedmusiclab.com
#            https://github.com/embodied-music-lab/PraatGen
# Code generation: Claude (Anthropic)
# Script author: Ian Howell — created and verified by this individual
#
# RESEARCH USE DISCLOSURE
# If this script is used in research or publication, disclose AI use per your
# target journal's policy.
# ============================================================================
#
# Usage:
#     python3 dev/tools/run-tests.py [options]
#
#     --praat PATH     Praat binary. Default: resolve from $PRAAT, then PATH
#                      (praat_barren, praat), then common install locations.
#     --tests DIR      Test root. Default: <plugin>/dev/tests
#     --filter SUBSTR  Only run suites whose relative path contains SUBSTR.
#     --timeout SECS   Per-suite timeout. Default 300.
#     --json PATH      Write machine-readable results to PATH.
#     --list           Discover and print suites, run nothing.
#     --verbose        Echo each suite's stdout tail on non-PASS.
#
# Exit status: 0 only if every discovered suite reported status=PASS.
#              1 otherwise (including "no suites discovered").
# ============================================================================

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

# ----------------------------------------------------------------------------
# Discovery exclusions
# ----------------------------------------------------------------------------
# Files under dev/tests/ that are not test suites. Matched against the path
# relative to the test root, with forward slashes.
#
#   eml-test-helpers.praat        the shared assertion library itself
#   phase2/_margins_generated.praat  generated diagnostic (build_margins.py);
#                                    prints per-site margins, has no assertions
EXCLUDED_RELPATHS = {
    "eml-test-helpers.praat",
    "phase2/_margins_generated.praat",
}

# Any file whose basename starts with one of these is skipped. Underscore
# prefix is the established convention for generated/partial files.
EXCLUDED_PREFIXES = ("_",)

SENTINEL_RE = re.compile(
    r"^EMLTEST-RESULT:\s*"
    r"status=(?P<status>\w+)\s+"
    r"passed=(?P<passed>-?\d+)\s+"
    r"failed=(?P<failed>-?\d+)\s+"
    r"skipped=(?P<skipped>-?\d+)\s+"
    r"total=(?P<total>-?\d+)\s*$",
    re.MULTILINE,
)

# Outcome vocabulary.
PASS = "PASS"
FAIL = "FAIL"
INCOMPLETE = "INCOMPLETE"
NO_SENTINEL = "NO-SENTINEL"
TIMEOUT = "TIMEOUT"
ERROR = "ERROR"

# Expected-failure vocabulary. A suite whose whole purpose is to prove the
# harness still refuses bad input must report FAIL to be doing its job.
XFAIL = "XFAIL"      # matched a declared non-PASS expectation  -> green
XPASS = "XPASS"      # was expected to fail and did not         -> red

GREEN = {PASS, XFAIL}

# ----------------------------------------------------------------------------
# Declared expectations
# ----------------------------------------------------------------------------
# Keyed on the suite path relative to the test root, forward slashes.
#
# A suite listed here is a NEGATIVE CONTROL: an assertion helper that never
# fails is indistinguishable from one that never runs, so these suites feed
# the helpers input they must refuse. Their declared expectation is part of
# the contract, and the suite's own header states it.
#
# Reporting rules:
#   observed == expected  -> XFAIL, green. The control fired.
#   observed != expected  -> XPASS, red.  Either the harness stopped
#                            enforcing, or the suite changed and this
#                            declaration is stale. Both need a human.
#
# Do NOT add a suite here to silence a real failure. The only legitimate
# entry is a file that documents its own expected non-PASS result and would
# be meaningless if it passed.
EXPECTED_STATUS = {
    # Header: "Expected: status=FAIL passed=0 failed=4 skipped=0 total=4
    #          A PASS from this file means the harness has stopped enforcing."
    "test-helpers-selftest-negative.praat": FAIL,
}


def plugin_root() -> Path:
    """Plugin root, derived from this file's location (dev/tools/run-tests.py)."""
    return Path(__file__).resolve().parent.parent.parent


def resolve_praat(explicit: str | None) -> Path:
    """Locate a Praat binary.

    Resolution is by intent, not by pinned path: an explicit --praat wins,
    then $PRAAT, then whatever is on PATH, then the conventional sandbox and
    system locations. The barren edition is preferred because the suites are
    non-GUI and barren needs no X server.
    """
    if explicit:
        p = Path(explicit).expanduser()
        if not p.exists():
            raise SystemExit(f"--praat: no such file: {p}")
        return p.resolve()

    env = os.environ.get("PRAAT")
    if env:
        p = Path(env).expanduser()
        if p.exists():
            return p.resolve()

    for name in ("praat_barren", "praat"):
        found = shutil.which(name)
        if found:
            return Path(found).resolve()

    candidates = [
        Path.home() / "praat_barren",
        Path.home() / "praat",
        Path("/home/claude/praat_barren"),
        Path("/home/claude/praat"),
        Path("/usr/local/bin/praat_barren"),
        Path("/usr/local/bin/praat"),
        Path("/Applications/Praat.app/Contents/MacOS/Praat"),
    ]
    for c in candidates:
        if c.exists():
            return c.resolve()

    raise SystemExit(
        "Could not locate a Praat binary. Pass --praat PATH, set $PRAAT, or "
        "put praat_barren on PATH."
    )


def discover(test_root: Path, filt: str | None) -> list[Path]:
    """Every .praat under test_root that is a test suite, sorted by path."""
    suites = []
    for path in sorted(test_root.rglob("*.praat")):
        rel = path.relative_to(test_root).as_posix()
        if rel in EXCLUDED_RELPATHS:
            continue
        if path.name.startswith(EXCLUDED_PREFIXES):
            continue
        if filt and filt not in rel:
            continue
        suites.append(path)
    return suites


def classify(returncode: int, stdout: str) -> tuple[str, dict]:
    """Apply the RESULT REPORTING CONTRACT to one suite's output.

    The sentinel is authoritative when present. Exit status alone is never
    sufficient: a suite that exits 0 having skipped checks is INCOMPLETE, and
    a suite that exits 0 without ever reaching @emlTestSummary is NO-SENTINEL
    (a failure), not PASS.
    """
    matches = list(SENTINEL_RE.finditer(stdout))
    if not matches:
        return NO_SENTINEL, {}

    # A suite could in principle emit more than one sentinel (nested include of
    # another suite). The last one is the summary that ended the run.
    m = matches[-1]
    counts = {
        "passed": int(m.group("passed")),
        "failed": int(m.group("failed")),
        "skipped": int(m.group("skipped")),
        "total": int(m.group("total")),
        "sentinels": len(matches),
    }
    status = m.group("status").upper()

    # Cross-check the sentinel against the counts and the exit status. A
    # disagreement means the helper library and the runner disagree about the
    # contract, which is itself a failure — never silently prefer the label.
    if counts["failed"] > 0:
        derived = FAIL
    elif counts["skipped"] > 0:
        derived = INCOMPLETE
    else:
        derived = PASS

    # More than one of these can be true at once, so they accumulate rather
    # than overwrite — an earlier diagnosis must not be erased by a later one.
    notes: list[str] = []

    if status != derived:
        notes.append(f"sentinel said {status}, counts imply {derived}")
        status = derived

    if derived == PASS and returncode != 0:
        notes.append(f"sentinel said PASS but process exited {returncode}")
        status = FAIL
    if derived == FAIL and returncode == 0:
        notes.append("sentinel reported failures but process exited 0")

    if notes:
        counts["contract_mismatch"] = "; ".join(notes)

    return status, counts


def apply_expectation(rec: dict, rel: str) -> dict:
    """Fold a declared expectation into the observed status.

    Mutates and returns rec. The observed status is preserved in
    rec["observed"] so the JSON keeps the raw measurement; rec["status"] is
    what the summary and the exit code use.

    An expected-fail suite that matches its declaration becomes XFAIL (green).
    One that deviates in ANY direction becomes XPASS (red) — including the
    case where it fails differently than declared (e.g. TIMEOUT instead of
    FAIL), because that is not the control firing, it is the control breaking.
    """
    rec["observed"] = rec["status"]
    expected = EXPECTED_STATUS.get(rel)
    rec["expected"] = expected
    if expected is None:
        return rec
    if rec["status"] == expected:
        rec["status"] = XFAIL
    else:
        rec["counts"]["expectation_mismatch"] = (
            f"declared expected={expected}, observed={rec['observed']}"
        )
        rec["status"] = XPASS
    return rec


def run_suite(praat: Path, suite: Path, timeout: int) -> dict:
    """Run one suite in its own process and classify the result.

    One process per suite is required, not an optimization: @emlTestSummary
    calls exitScript: on failure, which would abort a shared driver before the
    remaining suites ran.
    """
    rec = {
        "suite": suite.as_posix(),
        "status": ERROR,
        "returncode": None,
        "counts": {},
        "stdout": "",
        "stderr": "",
    }
    with tempfile.TemporaryDirectory(prefix="eml_praat_prefs_") as prefdir:
        cmd = [
            str(praat),
            "--run",
            f"--pref-dir={prefdir}",
            "--utf8",
            str(suite),
        ]
        try:
            proc = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=timeout,
                # Praat's `include` resolves relative to the script's own
                # location, so cwd does not affect suite resolution. Run from
                # the suite's directory anyway so any relative file I/O in a
                # suite behaves as it would when run by hand.
                cwd=str(suite.parent),
            )
        except subprocess.TimeoutExpired as exc:
            rec["status"] = TIMEOUT
            rec["stdout"] = (exc.stdout or b"").decode("utf-8", "replace") \
                if isinstance(exc.stdout, bytes) else (exc.stdout or "")
            rec["stderr"] = f"timed out after {timeout}s"
            return rec
        except OSError as exc:
            rec["status"] = ERROR
            rec["stderr"] = str(exc)
            return rec

    rec["returncode"] = proc.returncode
    rec["stdout"] = proc.stdout
    rec["stderr"] = proc.stderr
    rec["status"], rec["counts"] = classify(proc.returncode, proc.stdout)
    return rec


def fmt_table(results: list[dict], test_root: Path) -> str:
    rows = []
    width = max((len(Path(r["suite"]).relative_to(test_root).as_posix())
                 for r in results), default=10)
    width = max(width, 5)
    rows.append(f"{'suite'.ljust(width)}  {'status'.ljust(11)}  "
                f"{'pass':>5} {'fail':>5} {'skip':>5} {'total':>6}  exit")
    rows.append("-" * (width + 48))
    for r in results:
        rel = Path(r["suite"]).relative_to(test_root).as_posix()
        c = r["counts"]
        def n(k):
            return str(c[k]) if k in c else "-"
        rc = "-" if r["returncode"] is None else str(r["returncode"])
        rows.append(
            f"{rel.ljust(width)}  {r['status'].ljust(11)}  "
            f"{n('passed'):>5} {n('failed'):>5} {n('skipped'):>5} "
            f"{n('total'):>6}  {rc}"
        )
    return "\n".join(rows)


def main() -> int:
    root = plugin_root()
    ap = argparse.ArgumentParser(
        description="Run the EML Praat Tools test suites and enforce the "
                    "TEST RESULT REPORTING CONTRACT (v1.1)."
    )
    ap.add_argument("--praat", default=None)
    ap.add_argument("--tests", default=str(root / "dev" / "tests"))
    ap.add_argument("--filter", default=None)
    ap.add_argument("--timeout", type=int, default=300)
    ap.add_argument("--json", default=None)
    ap.add_argument("--list", action="store_true")
    ap.add_argument("--verbose", action="store_true")
    args = ap.parse_args()

    test_root = Path(args.tests).resolve()
    if not test_root.is_dir():
        print(f"No such test directory: {test_root}", file=sys.stderr)
        return 1

    suites = discover(test_root, args.filter)
    if not suites:
        print(f"No test suites discovered under {test_root}", file=sys.stderr)
        return 1

    if args.list:
        for s in suites:
            print(s.relative_to(test_root).as_posix())
        print(f"\n{len(suites)} suite(s).")
        return 0

    praat = resolve_praat(args.praat)
    print(f"Praat:  {praat}")
    print(f"Tests:  {test_root}")
    print(f"Suites: {len(suites)}\n")

    results = []
    for suite in suites:
        rel = suite.relative_to(test_root).as_posix()
        print(f"  running {rel} ... ", end="", flush=True)
        rec = apply_expectation(run_suite(praat, suite, args.timeout), rel)
        results.append(rec)
        c = rec["counts"]
        detail = ""
        if c:
            detail = (f" ({c['passed']}/{c['total']} passed, "
                      f"{c['failed']} failed, {c['skipped']} skipped)")
        if rec["expected"] is not None:
            detail += f" [expected {rec['expected']}, observed {rec['observed']}]"
        print(f"{rec['status']}{detail}")
        if args.verbose and rec["status"] not in GREEN:
            tail = "\n".join(rec["stdout"].splitlines()[-25:])
            if tail:
                print("    --- stdout tail ---")
                for line in tail.splitlines():
                    print(f"    {line}")
            if rec["stderr"].strip():
                print("    --- stderr ---")
                for line in rec["stderr"].strip().splitlines()[-15:]:
                    print(f"    {line}")

    print("\n" + fmt_table(results, test_root))

    by_status: dict[str, int] = {}
    for r in results:
        by_status[r["status"]] = by_status.get(r["status"], 0) + 1

    # Negative-control suites are counted separately. Folding their deliberate
    # failures into the headline total would read as four real regressions and
    # would mask a real one appearing beside them.
    real = [r for r in results if r.get("expected") is None]
    control = [r for r in results if r.get("expected") is not None]

    total_checks = sum(r["counts"].get("total", 0) for r in real)
    total_failed = sum(r["counts"].get("failed", 0) for r in real)
    total_skipped = sum(r["counts"].get("skipped", 0) for r in real)

    control_checks = sum(r["counts"].get("total", 0) for r in control)
    control_failed = sum(r["counts"].get("failed", 0) for r in control)

    print("\nSummary: " + ", ".join(
        f"{k}={v}" for k, v in sorted(by_status.items())
    ))
    print(f"Checks:  {total_checks} declared, {total_failed} failed, "
          f"{total_skipped} skipped "
          f"(counted only in suites that emitted a sentinel)")
    if control:
        print(f"Controls: {len(control)} negative-control suite(s), "
              f"{control_checks} checks, {control_failed} failed by design "
              f"(excluded from the line above)")

    mismatches = []
    for r in results:
        rel_r = Path(r["suite"]).relative_to(test_root).as_posix()
        for key in ("contract_mismatch", "expectation_mismatch"):
            if key in r["counts"]:
                mismatches.append((rel_r, key, r["counts"][key]))
    if mismatches:
        print("\nMismatches:")
        for rel_r, key, msg in mismatches:
            print(f"  {rel_r} [{key}]: {msg}")

    if args.json:
        payload = {
            "praat": str(praat),
            "test_root": str(test_root),
            "suites": [
                {k: v for k, v in r.items() if k not in ("stdout", "stderr")}
                for r in results
            ],
            "by_status": by_status,
            "totals": {
                "checks": total_checks,
                "failed": total_failed,
                "skipped": total_skipped,
                "control_suites": len(control),
                "control_checks": control_checks,
                "control_failed_by_design": control_failed,
            },
        }
        Path(args.json).write_text(json.dumps(payload, indent=2))
        print(f"\nJSON written to {args.json}")

    green = all(r["status"] in GREEN for r in results)
    return 0 if green else 1


if __name__ == "__main__":
    sys.exit(main())
