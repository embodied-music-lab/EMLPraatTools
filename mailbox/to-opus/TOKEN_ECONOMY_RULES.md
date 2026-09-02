## Token economy for delegated work

These rules govern how much a delegated task is given and asked to
return. They apply to every Agent call and every workflow `agent()`
task, all models, all projects. Most token waste is not the wrong
model; it is the right model handed too much and returning too much.
Place this section directly under the delegation and workflow rules,
in the same file, so agents inherit both together.

1. **Input discipline.** A task prompt carries the slice it needs,
   never the file. Search first; hand line ranges or excerpts. Never
   spawn an agent to read what a one-line search in the parent
   answers.

2. **Output discipline.** Every task prompt states the shape of the
   return: "return the verdict line and the three numbers, not the
   transcript." Unrequested narration is pure spend and pollutes the
   parent's context for every later turn.

3. **Split mixed tasks.** A search-then-edit job runs as two cheap
   agents, not one expensive one. The searcher's findings become a
   small prompt for the editor; the editor never re-searches.

4. **One verification, at the end, scoped to the diff.** Builders
   build and do not self-verify. One agent verifies everything once,
   checking what the changes touch and the interactions between them.
   Full test suites run at gates, not per task.

5. **Reuse instead of rerun.** On a retry or extension of a workflow,
   resume the prior run so unchanged tasks return from cache; never
   relaunch from scratch. An agent that regenerates a file that
   already exists on disk, instead of reading it, is a defect.

6. **Fail fast on a broken premise.** Every task carries an abort
   condition: "if the file does not contain X, stop and report — do
   not improvise." An agent continuing confidently past a wrong
   premise is the most expensive failure mode there is.

7. **Check for in-flight work before launching.** After a compaction
   or any gap, read the running-task list before starting anything. A
   clean working tree is not evidence that no agent is running — an
   agent still reading produces no edits and looks identical to one
   that never started. Duplicate launches have cost hundreds of
   thousands of tokens in a single incident.

8. **Narrow scope per task.** One task, one small stated scope, quick
   finish. Long everything-rerunning jobs block interaction, hide
   failures, and correlate with dropped work. Verify only what the
   change touches; re-run the rest separately and deliberately.

9. **Search tools and absence claims.** ripgrep is the default search
   tool, but it skips gitignored paths by default — generated output
   directories included. A zero-hit search that supports an "it
   doesn't exist" claim must be rerun with `--no-ignore` before the
   claim is made.
