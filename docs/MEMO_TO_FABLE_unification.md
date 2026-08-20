# Memo to Fable — the stats/graphs unification

Sent 19 Aug 2026. Kept in the repo because the container it was written in
is disposable and this is the open question the next phase waits on.

## The recomputation is demonstrated, not theorised

Ian ran a Kruskal-Wallis on a three-group table, then drew a violin plot.
The Info window carried TWO complete Kruskal-Wallis reports, timestamped
fifteen seconds apart, identical in every digit — same H, df, p,
epsilon-squared, the same mean ranks, the same Dunn matrix.

The second is the graph door recomputing the analysis. The annotation
layer's own header states the design: the bridge procedures "run the
appropriate statistical test, then populate brackets."

## They agreed by luck, and the source says so

The correction the brackets use is resolved from a variable the GRAPHS FORM
sets, defaulting to Holm. The correction the report used came from the
argument the statistics door was given. Nothing carries the first to the
second. Ian's analysis happened to use Holm and the form's default is Holm.

The form also OFFERS three settings that change the result — test type,
adjustment method, alpha — on every group figure. So the graph door can run
a different test, under a different correction, at a different threshold,
and print it beneath a report that says something else.

## The split is small enough to enumerate

RESULT-AFFECTING, must come from the analysis: test type, adjustment
method, alpha.

DISPLAY-ONLY, the figure owns them: significance style, show
non-significant, show effect sizes, layout mode.

## Ian's ruling on the shape

The graph carries the analysis's settings forward. Changing a
result-affecting setting from the graph re-runs and says so in one line in
the Info window. Changing nothing recomputes nothing and prints nothing.
The duplicate-report stopgap rolls into this rather than shipping first.

## What we would like ruled

a. **Keying.** The store must be keyed to data identity, not settings
   alone — table, columns, and enough about the rows to know the table has
   not changed. Row count is cheap; a checksum over the two columns is
   exact and costs a pass. We lean to the checksum.
b. **Whether the display/result split gets the recorder's validator
   treatment** — the two lists together accounting for every setting the
   bridge reads, so a setting added later cannot land on the wrong side
   silently.
c. **Where the store lives.** Praat has no result object. Globals are
   invisible and unbounded; a Table is inspectable but Ian has objected to
   recorder bookkeeping tables in the Objects window.
d. **Scope.** Group comparison only, or also the correlation bridge and the
   pitch doors? The pitch item is the same principle in the acoustics layer.

## Sequencing we believe in but have not been given

The store should land BEFORE the recorder state publication, because the
recorder wants to emit from exactly this store. Built the other way round,
the recorder publishes a pile of globals and is then rewritten.

## Since the memo went

The comparison control on the six draw pages was rebuilt as ONE list, so
the family and its correction come from one chosen row. That removes the
graph door's ability to disagree with ITSELF; it does not remove its
ability to disagree with the analysis, which is what this memo is about.
