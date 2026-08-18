#!/usr/bin/env python3
# batch2_scipy_refs.py -- external reference generator for the two batch2
# one-tailed p-values and the batch7 Dunn-1 |z| literals.
#
# batch2 has no R verifier (verify-inferential-batch2.R does not exist despite
# the suite header claiming it). These references come from scipy and
# scikit-posthocs, so the batch2 one-tailed checks and the Dunn |z| recovery
# have an external source rather than a self-consistency check.
#
# Note on Spearman: scipy's alternative="greater" uses a permutation/AS89
# route distinct from the t-distribution survival function, so BOTH are
# printed -- the difference is a property of the reference, not an error.
#
import numpy as np, pandas as pd
import scipy.stats as st
import scikit_posthocs as sp

print("scipy", st.__name__, __import__("scipy").__version__, "| scikit-posthocs", sp.__version__)
print()

# ---------------------------------------------------------------- batch2
# test-inferential-batch2.praat:45  "Set A p (1-tail)" Pearson
# test-inferential-batch2.praat:138 "Set A p (1-tail)" Spearman
x = np.array([1.,2.,3.,4.,5.]); y = np.array([2.,4.,5.,4.,5.])

r  = st.pearsonr(x, y)
rs = st.spearmanr(x, y)
n = len(x); df = n - 2

# scipy >=1.9 exposes one-sided alternatives directly on pearsonr
p1_pearson_direct = st.pearsonr(x, y, alternative="greater").pvalue
t_p = r.statistic * np.sqrt(df / (1 - r.statistic**2))
p1_pearson_t = st.t.sf(t_p, df)

t_s = rs.statistic * np.sqrt(df / (1 - rs.statistic**2))
p1_spearman_t = st.t.sf(t_s, df)
p1_spearman_direct = st.spearmanr(x, y, alternative="greater").pvalue

print("batch2:45  Pearson  r  = %.17g" % r.statistic)
print("batch2:45  Pearson  t  = %.17g" % t_p)
print("REF: batch2 Pearson  Set A p (1-tail) [scipy pearsonr alternative=greater] = %.17g" % p1_pearson_direct)
print("REF: batch2 Pearson  Set A p (1-tail) [t-dist sf]                          = %.17g" % p1_pearson_t)
print("batch2:138 Spearman rho= %.17g" % rs.statistic)
print("batch2:138 Spearman t  = %.17g" % t_s)
print("REF: batch2 Spearman Set A p (1-tail) [t-dist sf]                          = %.17g" % p1_spearman_t)
print("     (scipy spearmanr alternative=greater uses a permutation/AS89 route: %.17g)" % p1_spearman_direct)
print()

# ---------------------------------------------------------------- batch7 Dunn-1
g1 = [23,25,27,22,26]; g2 = [30,33,29,31,34]; g3 = [18,20,22,19,17]
df_long = pd.DataFrame({
    "Value": g1+g2+g3,
    "Group": ["G1"]*5 + ["G2"]*5 + ["G3"]*5,
})
raw = sp.posthoc_dunn(df_long, val_col="Value", group_col="Group", p_adjust=None)
bon = sp.posthoc_dunn(df_long, val_col="Value", group_col="Group", p_adjust="bonferroni")
print("scikit-posthocs raw p matrix:\n", raw.to_string(float_format=lambda v: "%.17g" % v))
print()
for (a,b) in [("G1","G2"),("G1","G3"),("G2","G3")]:
    print("REF: Dunn-1 raw p(%s,%s) = %.17g" % (a[1], b[1], raw.loc[a,b]))
for (a,b) in [("G1","G2"),("G1","G3"),("G2","G3")]:
    print("REF: Dunn-1 adj p(%s,%s) Bonf = %.17g" % (a[1], b[1], min(bon.loc[a,b],1.0)))

# recover z from p for a cross-check against the suite's z literals
print()
for (a,b),zlit in [(("G1","G2"),-1.80473438),(("G1","G3"),1.69857354),(("G2","G3"),3.50330792)]:
    z = st.norm.isf(raw.loc[a,b]/2.0)
    print("  |z|(%s,%s) recovered = %.17g   suite literal = %.8f  |lit| match=%s"
          % (a,b,z,zlit, abs(abs(zlit)-z) < 1e-7))
