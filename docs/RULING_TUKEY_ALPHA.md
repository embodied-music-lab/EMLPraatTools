# Ruling — the Tukey family-wise level travels as an argument

Verification session → executing session, 21 Aug 2026. Answers the open
question in OPEN_ITEMS ("Newly ordered, 20 Aug"): does the confidence
level reach @emlTukeyHSD as a new argument through @emlOneWayAnova, or
as an ambient resolution at the reporter?

**AS AN ARGUMENT.** @emlOneWayAnova gains .alpha; all ~25 call sites are
updated mechanically in one commit (callers with a user alpha pass it;
callers with none pass 0.05 explicitly — the default becomes visible at
every site instead of buried in one). The reporter-side ambient read is
REJECTED: a kernel reading a global is the recorder/store disease in a
statistics procedure — invisible state deciding a reported number. The
week's whole direction is explicit state; kernels take arguments.
(Praat has no optional arguments, so the arity change is unavoidable —
and a 25-site mechanical sweep under the suite is cheap and safe; the
cancellation-fix and canon sweeps were larger.)

Consequences in the same commit family: the report heading becomes
dynamic — "<level>% family-wise CI" from the alpha in force, never a
fixed "95%"; the Tukey export frame's conf.low/conf.high and .qCritical
follow the argument; the graphs-layer callers pass annotAlpha (which
the result store will later carry as part of the analysis request —
this ruling is store-compatible by construction).

PINS: the committed three-group fixture driven at alpha .05 and .01
must produce DIFFERENT interval bounds and headings (the current
byte-identical pair is the negative control); oracle qtukey/TukeyHSD in
R at both levels; the stars beside the table continue to obey the same
alpha, asserted in the same leg.

Two adjacent dispositions while ruling here:
- The seven harness/graphaxes FAC fixtures running very-accurate ON:
  regenerate to canon — fixtures measuring something the plugin does
  not do are miscalibrated instruments, and the pitch-canon ruling
  says "everywhere, dev and fixtures included." (Flagged to Ian in
  OPEN_ITEMS; this is the ruling unless he objects.)
- The two graphs-form call sites still spelling the FAC parameter tail
  literally: join them to the owning procedure per the A2 change order
  — "they agree; they are not joined" is exactly the drift setup A2
  exists to prevent.

— verification session
