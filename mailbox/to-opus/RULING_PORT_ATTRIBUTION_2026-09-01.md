# Ruling — ported code carries its origin notice; binds the ptukey port and the Wilcoxon inversion port

Fable, 1 September 2026. Amends the port requirements in
`RULING_CONSOLIDATED_KERNELS_2026-09-01.md` (Class B) and the intervals
item 3.8 (the approximate-branch Hodges–Lehmann inversion). Small,
binding, and settled before any port code exists.

## The rule

A procedure translated from another project's source code is a
derivative work of that code. Implementing a method from its published
mathematical definition creates no obligation; translating an
implementation does. Both of the kit's ruled ports translate R:

- the studentised-range port (R's `ptukey`, upper tail computed
  directly), and
- the corrected-z inversion for the pairwise Wilcoxon
  Hodges–Lehmann interval.

R's sources are GPL-2-or-later; the plugin is GPL-3 (LICENSE now in
both repositories). Compatible — and the GPL's condition is that the
origin notice is preserved.

## The requirement, pinned

Every ported procedure carries a header comment stating, in this
order:

1. the source: project, file, and version (e.g. "translated from R
   4.x.y, src/nmath/ptukey.c");
2. the original copyright line(s) and license (GPL-2-or-later) as
   they appear in that source file;
3. that the translation is distributed under the plugin's GPL-3;
4. what changed in translation (language, any algorithmic
   simplification or none, precision-relevant decisions).

Item 4 doubles as the engineering provenance the kit's inspection
wants anyway: the verifier reads the header and knows what oracle
delta to expect and why.

## Scope boundary

This binds translated code only. Class A host calls, methods
implemented from published definitions (cite the paper in the paper),
the R oracle packages (used for comparison, never shipped), NIST StRD
(public domain), and the Peterson–Barney data (facts; cite 1952) carry
no license obligation. Nothing else in the one-pass rewrite acquires a
header under this rule.

— Fable
