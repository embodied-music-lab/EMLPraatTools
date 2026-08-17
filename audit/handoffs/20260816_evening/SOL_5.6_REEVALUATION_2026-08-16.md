# EML Praat Tools — recheck and handoff for Claude

**Repository:** <https://github.com/embodied-music-lab/EMLPraatTools>  
**Remote commit reviewed:** `7d540263ac1c6b1f0add352c114479a97a1f6af1` (`main`, 16 August 2026)  
**Previous review baseline:** `e4678243cae4a5d5532975a87be4f035ec7767c1`  
**Scope note:** Ian is actively working on the `plugin_EML_Praat_Tools` folder/package naming. Do not treat that naming work as a new or unattended defect.

## Purpose of this handoff

This document explains:

1. What continuous integration means in this repository.
2. What GitHub can and cannot verify automatically.
3. Which findings from the 15 August external review are now satisfactorily closed.
4. Which release-assurance problems remain.
5. The recommended next actions and acceptance criteria.

## What “CI” means here

In this context, **CI means continuous integration**, not confidence interval.

Continuous integration is an automated test runner attached to the GitHub repository. It is implemented through **GitHub Actions**, using this file:

```text
.github/workflows/validate.yml
```

When the workflow runs, GitHub creates a fresh temporary Ubuntu computer and performs the steps written in that YAML file. The current workflow:

1. Checks out the repository from GitHub.
2. Installs R.
3. Installs the shared-library dependencies supplied by Ubuntu’s Praat package.
4. Downloads the full Praat 6.6.30 Linux build required by the plugin’s validation contract.
5. Prints the exact R, Python, and Praat versions being used.
6. Runs:

```bash
Rscript validate/run_all.R
```

7. Marks the workflow green if the command exits successfully and red if any validator returns a failure.

### Does GitHub “verify the plugin”?

Only in a carefully defined sense.

GitHub does not understand statistics, inspect the interface intelligently, or certify the software. It follows the repository’s instructions and reports whether those instructions passed on a fresh machine. The quality of the verification therefore depends on the quality, independence, and coverage of the tests in `validate/` and `harness/`.

A green workflow can establish that:

- The repository works on a clean Linux runner rather than only on the developer’s existing machine.
- Required files and dependencies have not been omitted.
- The manifest and include-closure checks pass.
- The R numerical comparisons and live Praat validators pass.
- A code change did not violate the particular behaviors encoded in the test suite.
- The precise commit tested can be associated with a visible green or red result.

A green workflow does **not** by itself establish that:

- Every possible dataset produces a correct answer.
- Untested statistical methods or interface paths are correct.
- Old committed screenshots and harness artifacts were genuinely regenerated from the current source.
- The packaged ZIP installs correctly or has safe file permissions.
- The plugin works identically on macOS and Windows.
- Figures are visually correct unless the tests measure the relevant pixels or text.
- The statistical and graphing product is as broad as R, JASP, jamovi, or comparable systems.

Continuous integration is therefore a **repeatable enforcement mechanism**, not an external scientific certification.

## Current CI inconsistency

The workflow is well specified, including the correct full Praat build, but its current trigger is manual only:

```yaml
on:
  workflow_dispatch:
```

The workflow comments explain that this is temporary while the repository is transferred to GitHub directory by directory.

However, the newly added repository-hygiene validator, `validate/v78_repo_hygiene.R`, explicitly requires both:

```yaml
push:
pull_request:
```

The plugin README and `plugin/MANIFEST.txt` also say validation runs on every push. Consequently, the exact uploaded commit `7d54026` cannot pass its own v78 validator in its present form. The reported `12,400 / 12,400` run appears to describe the source tree before the workflow was temporarily changed to manual-only, not the exact current GitHub commit.

This is not a statistical regression. It is a repository-state and reporting inconsistency.

### Required resolution

After the transfer is complete:

1. Restore `push:` and `pull_request:` triggers. Keeping `workflow_dispatch:` as an additional manual option is reasonable.
2. Run the workflow on the exact final remote commit.
3. Confirm that v78 passes rather than being skipped or weakened.
4. Record the tested commit SHA with the validation result.
5. Update claims such as “checked on every push” only after that behavior is actually active.

If manual-only operation is to remain intentional, then the README, manifest, and v78 must all describe that narrower contract. The stronger solution is to restore automatic triggers.

## Findings now closed to the external reviewer’s satisfaction

### 1. Directional one-tailed p-values — closed

The original public scripting API used `studentQ(abs(t), df)` for one-tailed t-tests and correlations. This selected the smaller tail in whichever direction the observed effect happened to fall. Swapping the groups could therefore return the same small p-value in both directions.

The repair is satisfactory:

- The signed statistic now determines the tail.
- `pGreater` and `pLess` are exposed separately.
- `alternative$` states which hypothesis `.p` represents.
- Explicit `@...Alt` procedures accept `"two-sided"`, `"greater"`, or `"less"`.
- Wrong-direction perfect negative correlation returns `pGreater = 1`, not 0.
- Existing two-sided behavior is protected against regression.
- v73 checks a committed capture against R.
- v77 drives Praat live and compares Welch, Student, paired t, Pearson, and Spearman in forward and reversed directions against R oracles.

This was the only independently identified wrong numerical result. It is convincingly repaired.

### 2. One-bin Spectrum and LTAS rendering — closed

A window containing exactly one Spectrum bin previously drew the frame, axes, labels, and grid but no data. Praat’s normal `Draw:` joins points with line segments, so one point produces no segment.

The plugin now draws the single bin as a stem. The same defect was addressed for LTAS Curve mode. v67 verifies:

- Zero-, one-, and two-bin cases.
- The stem’s actual frequency.
- Its height against the corresponding point in a two-bin control.
- Its extension to the frame floor.
- Clipping at the axis ceiling.
- No stem when the bin is below the visible range.
- Actual interior pixels rather than merely file existence or file size.

### 3. Tidy skewness and kurtosis — closed

Skewness and kurtosis are now included in the tidy vocabulary and declared per row. v71 verifies column presence, order, numerical values, asymmetric mirror fixtures, and consistency with glance output.

The result writer also gained `@eml_vocabCheck`, which refuses an unknown result-column name at declaration time. This addresses the deeper risk that an unrecognized field could otherwise be silently omitted from the written file.

### 4. Recorder axis semantics — closed

The recorder now distinguishes the user’s request from the range resolved during drawing:

- Auto remains represented by the `0.0 / 0.0` sentinel and rescales on replay.
- Explicit limits are lifted into the editable configuration block.
- Formless procedure calls retain the limits passed by their caller.
- Published form state is consumed once through a step stamp.
- A later draw in the same Praat process cannot inherit an earlier form’s stale range.
- The stamp is refreshed at dispatch to account for an intervening annotation-recording step.

The new validation is sequence-sensitive and tests the multi-draw, same-process case that the previous suite missed.

### 5. Legend two-pass recorder duplication — closed

A graph requiring two drawing passes for legend room previously recorded two draw steps for one user action and documented the discarded first-pass range. The recorder now marks and rewinds in parallel with the CSV collector. One press produces one final draw step, and replay is checked against the original figure.

### 6. Bracket figures naming their test — closed

Two-group figures could contain a significance bracket and effect size without naming the statistical test. The bridge now supplies the test text. v76 checks the invariant structurally across every bracket-producing arm and reads the text from driven figures.

### 7. Batch Voice Analysis registration — closed for the registration question

Batch Voice Analysis is now registered in `setup.praat`. Before registration, the real menu entry and real dialog were driven through a successful CSV write. This supplements the existing validation of acoustic calls, control flow, error rows, output paths, and PraatGen conformance.

This clears the earlier objection that an untested door was being advertised. It does not constitute macOS/Windows validation of the batch workflow.

### 8. Manifest — closed

The current manifest check passes:

```bash
python3 plugin/dev/tools/build-manifest.py --check
```

Result:

```text
MANIFEST.txt is current.
```

The current manifest contains no undescribed TODO rows, and v78 incorporates the generator’s own `--check` rather than reimplementing it.

### 9. Include checker — closed

The include checker now distinguishes real entry scripts, include-only barrel fragments, documented tutorial omissions, and existence-guarded optional calls.

Current result:

```text
include closure: every @call resolves, 26 entry script(s),
4 existence-guarded optional call(s) allowed
```

The repair also exposed one genuine unguarded dependency rather than merely suppressing all warnings.

### 10. Broken local documentation links — narrowly closed

The README no longer promises `docs/procedure-reference.md` and `docs/recipes.md`, which never existed. It now points readers toward procedure headers, the manifest, `docs/API_EXPORT.md`, `setup.praat`, and the script recorder.

This closes the broken-link defect. It does not eliminate the usability limitation created by having 492 procedures without a generated, searchable API reference.

### 11. Critical stale captures and numerical display issues — closed

The load-bearing RM-ANOVA/Friedman capture was regenerated under the new p-value display format. Its parser and extremely small tolerance were re-derived rather than relaxed. Skewness display, raw-double leakage, matrix source-column numbering, axis-label clearance, result-warning separation, and related active-path formatting issues have also received targeted validators.

### 12. Assertion-vacuity scan — remains satisfactory

The independently rerun scanner reports:

```text
parsed: 712 / 712
vacuous: 0
unparsed: 0
misuse: 0
unresolved tolerance: 0
```

## Remaining release-assurance problems

### 1. Much of the committed harness evidence does not reproduce

The new `validate/tools/redrive_census.sh` is an important improvement because it tests whether committed evidence can actually be regenerated from the checked-in source and drivers.

The repository’s current audit status reports, across 34 harnesses and 2,093 artifact files:

- 9 harnesses reproduce byte-for-byte.
- 7 run but contain expected clock/path instability.
- 15 differ.
- 1 driver fails.
- 2 have no artifacts.
- 14 have no shell driver.

Several stale artifacts have been shown to describe already-repaired defects as still open. Other evidence came from a harness state that cannot reproduce it from the repository. A green R comparison against a stale committed capture may still prove that the number in that text file agrees with R; it does not prove that current plugin code would generate that file.

Recommended redrive order from the repository’s own status record:

1. `graphseams`, with the v61 prose corrected in the same change.
2. `markers` and `patterns` after repairing their stale identifiers.
3. `gui_e2e`.
4. `legend`, together with its pinned pixel constants.
5. `savepaths` and `api_export`.
6. `edittable`.
7. `normality` only after it has an actual validator.

The release criterion should not be “every PNG is byte-identical on every machine.” It should be that every load-bearing artifact has a reproducible driver, and platform-/clock-dependent fields are normalized explicitly rather than ignored informally.

### 2. Built-plugin installation is not yet tested

The repository correctly states that Git cannot represent the reported `0600` packaging failure. A clean checkout cannot prove that the final archive has safe permissions.

The release artifact needs a separate test that:

- Builds the actual ZIP or distribution folder.
- Applies readable permissions, such as `0644` for ordinary files.
- Installs it into a fresh Praat profile as a different/non-owner user where possible.
- Starts Praat and enumerates the registered menu entries.
- Executes at least one path for every registered input object type.
- Verifies the exact folder/package name Ian ultimately chooses.

Linux can be automated. macOS and Windows require their own runners or real-machine verification.

### 3. Graphing/statistics unification remains pending

Graphing-door statistics still use a partly separate orchestration path. The current audit reports numerical agreement, but duplicated result logic remains a maintenance risk.

The agreed acceptance test is “one result through every door”:

- Same included/excluded rows.
- Same test family and alternative.
- Same estimate and effect size.
- Same degrees of freedom.
- Same raw and adjusted p-values.
- Same method and adjustment labels.
- Same result represented in Info, CSV, figure annotation, and recorded script.

This remains appropriately scheduled after the current plugin work settles.

### 4. Front-door documentation remains inconsistent

The root README still says “coming soon” and carries an older list of high-severity open findings. The current status file reports a substantially different state. The manifest and plugin README say CI runs on every push, while the uploaded workflow is manual-only.

Before release, choose one current status source and make the front doors derive from or link to it. Historical audit records can remain historical, but readers should not have to determine which dated document overrides which other dated document.

### 5. Broader product limitations remain

These were comparison findings rather than immediate correctness bugs and have not been eliminated:

- The Stats Wizard treats normality too much like a deterministic switch between parametric and nonparametric procedures.
- No integrated simple-effects, estimated-marginal-means, custom-contrast, or interaction-plot workflow.
- Mixed models remain tabled and reliability remains incomplete.
- Model diagnostics remain narrower than established statistical packages.
- No first-class vector PDF/SVG/EPS export in the graph workflow.
- Graphs are fixed families rather than a composable grammar.
- Headless/project-level reproducibility remains less complete than in R, jamovi, or JASP.
- No generated navigable reference for the public scripting API.

These should be described as scope or roadmap unless the release claims imply broader parity.

## Commands Claude should run on the exact current commit

```bash
git fetch origin main
git rev-parse origin/main

python3 plugin/dev/tools/build-manifest.py --check
python3 harness/check_includes.py
python3 -m compileall -q plugin/dev validate harness
python3 plugin/dev/tools/scan-assertion-vacuity.py plugin/dev/tests/phase2

Rscript validate/run_all.R
```

The first four commands currently pass at `7d54026`. The full R/Praat suite must be rerun on a machine with R and the full Praat 6.6.30 or later available on `PATH`.

After enabling automatic CI, Claude should also verify the public GitHub Actions result for the exact commit rather than quoting a suite total from an audit document.

## Recommended immediate queue for Claude

1. **Do not revisit the one-tailed statistical repair unless a new failing oracle is found.** It is adequately fixed and guarded.
2. **Finish repository transfer and restore automatic CI triggers.** Run the exact uploaded commit.
3. **Reconcile v78, the workflow, README, and manifest claims.** They must state one consistent CI contract.
4. **Redrive the load-bearing stale harnesses in the documented order.** Commit source, artifacts, and validator changes together.
5. **Build and install-test the actual release artifact.** Include permissions and the final plugin-folder name.
6. **Update the root README in Ian’s voice.** Keep historical defect narratives in the audit tree rather than the shipping plugin unless Ian explicitly retains an exception.
7. **Complete graph/statistics unification last**, using “one result through every door” as the acceptance test.

## Bottom-line assessment

The external review’s principal numerical defect is now convincingly repaired. The Spectrum, tidy-output, recorder, Batch-registration, manifest, and include-closure fixes are also satisfactory.

The remaining obstacle to a public release is no longer a known wrong number in a registered analysis. It is the assurance chain: the exact GitHub commit must run automatically and pass; load-bearing harness evidence must be reproducible; the actual packaged plugin must be installed and tested; and release-facing documentation must describe one coherent current state.
