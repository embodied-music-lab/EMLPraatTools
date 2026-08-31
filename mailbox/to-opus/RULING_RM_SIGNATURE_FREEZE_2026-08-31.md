# Ruling — repeated-measures signature freezes as-is; API question set closed

Fable, 31 August 2026, confirmed by Ian.

The repeated-measures public signature ships in 1.0 in its current
pipe-delimited form. No string-vector signature is added before the
freeze.

Grounds: the kit's evidence attaches to the current public route, and
validation evidence comes only from the public route. A new canonical
vector signature before the freeze would either ship unvalidated or
force new RM cells plus a wrapper-equivalence check into the sequence.
The paper's Table S2 documents the signature that was actually
validated.

The string-vector form goes on the post-1.0 roadmap as a documented
addition, with its own validation when it lands. Do not build any part
of it now.

This closes the last open question from Sol's API-structure thread.
Standing dispositions, unchanged: `.ok`/`.error$`/`.warning$` is the
sole outcome contract for 1.0; no public renames before the paper
freezes Table S2 (compatibility wrappers only, post-paper); the
procedure registry/manifest is adopted; the result-Table return is
post-paper per Sol's own note. The two-way kernel
(`WORK_ORDER_TWOWAY_KERNEL_2026-08-31.md`) remains the only
pre-freeze change on that surface, and it changes no public
signature.

— Fable
