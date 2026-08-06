#!/usr/bin/env python3
# ============================================================================
# oracle_check.py — compare the values helpers.R actually computed
# (oracle_values.csv, written by oracle_dump.R) against independent
# implementations in scipy, pingouin and scikit-posthocs, on the same
# committed inputs.
#
# Optional tier. The base suite's zero-dependency charter is untouched:
# run_all.R never calls this. Run it in CI where Python is available:
#
#     Rscript validate/oracle/oracle_dump.R
#     python3 validate/oracle/oracle_check.py
#
# Exit 0 iff every value agrees within its tolerance.
# requirements.txt pins the oracle packages.
# ============================================================================
import sys, math
from pathlib import Path
import numpy as np
import pandas as pd
from scipy import stats
import pingouin as pg
import scikit_posthocs as sp

HERE = Path(__file__).resolve().parent
CSV  = HERE.parent.parent / "evidence" / "csv"

R = pd.read_csv(HERE / "oracle_values.csv").set_index("stat")

def rval(k): return float(R.loc[k, "value"])
def rtol(k): return float(R.loc[k, "tol"])

py = {}

# --- RM-ANOVA / GG / Friedman / W on demo_rm3_input -------------------------
d = pd.read_csv(CSV / "demo_rm3_input.csv")
conds = ["SPL_soft", "SPL_medium", "SPL_loud"]
long = d.melt(id_vars="singer", value_vars=conds, var_name="cond", value_name="y")
aov = pg.rm_anova(data=long, dv="y", within="cond", subject="singer",
                  correction=True, detailed=True)
py["rm_anova_F"]  = float(aov["F"].iloc[0])
py["rm_anova_gg"] = float(aov["eps"].iloc[0])
Y = d[conds].to_numpy()
fr = stats.friedmanchisquare(*[Y[:, i] for i in range(Y.shape[1])])
py["friedman_chisq"] = float(fr.statistic)
py["kendalls_w"] = float(fr.statistic) / (Y.shape[0] * (Y.shape[1] - 1))

# --- paired effect sizes on demo_paired_input -------------------------------
dp = pd.read_csv(CSV / "demo_paired_input.csv")
pre, post = dp["jitter_pre"].to_numpy(), dp["jitter_post"].to_numpy()
# dz via an independent identity: t_paired / sqrt(n)
py["cohens_dz"] = float(stats.ttest_rel(pre, post).statistic) / math.sqrt(len(pre))
diff = pre - post; diff = diff[diff != 0]
rk = stats.rankdata(np.abs(diff)); Wplus = rk[diff > 0].sum()
tot = len(diff) * (len(diff) + 1) / 2
py["rank_biserial_paired"] = (Wplus - (tot - Wplus)) / tot   # Kerby difference

# --- two-group on v08_twogroup_input ----------------------------------------
d8 = pd.read_csv(CSV / "v08_twogroup_input.csv")
a = d8.loc[d8.group == "Control", "jitter_pct"].to_numpy()
b = d8.loc[d8.group == "Patient", "jitter_pct"].to_numpy()
py["cohens_d_pooled"] = float(pg.compute_effsize(a, b, eftype="cohen"))
py["hedges_g"]        = float(pg.compute_effsize(a, b, eftype="hedges"))
py["rank_biserial_indep"] = 2 * float(pg.compute_effsize(a, b, eftype="CLES")) - 1

# --- KW / Dunn / epsilon-squared / Holm on v10_kw_dunn_input ----------------
d10 = pd.read_csv(CSV / "v10_kw_dunn_input.csv")
groups = [d10.loc[d10.voice_type == l, "SPL_dB"] for l in ["Soprano", "Mezzo", "Alto"]]
H = float(stats.kruskal(*groups).statistic)
py["kw_H"] = H
N = len(d10)
py["epsilon_squared"] = H / ((N**2 - 1) / (N + 1))
ph = sp.posthoc_dunn(d10, val_col="SPL_dB", group_col="voice_type")
py["dunn_p_Soprano_Mezzo"] = float(ph.loc["Soprano", "Mezzo"])
py["dunn_p_Soprano_Alto"]  = float(ph.loc["Soprano", "Alto"])
py["dunn_p_Mezzo_Alto"]    = float(ph.loc["Mezzo", "Alto"])
raw = np.array([py["dunn_p_Soprano_Mezzo"], py["dunn_p_Soprano_Alto"],
                py["dunn_p_Mezzo_Alto"]])
from statsmodels.stats.multitest import multipletests
adj = multipletests(raw, method="holm")[1]
py["holm_adj_1"], py["holm_adj_2"], py["holm_adj_3"] = map(float, adj)

# --- G1/G2 on v14 -----------------------------------------------------------
d14 = pd.read_csv(CSV / "v14_descriptive_input.csv")
x = d14["SPL_dB"].to_numpy()
py["skewness_g1"]     = float(stats.skew(x, bias=False))
py["excess_kurtosis"] = float(stats.kurtosis(x, bias=False))

# --- Shapiro-Wilk on v15 ----------------------------------------------------
d15 = pd.read_csv(CSV / "v15_normality_input.csv")
for nm in ["F0_Hz", "shimmer_pct", "jitter_pct"]:
    sw = stats.shapiro(d15[nm].to_numpy())
    py[f"shapiro_W_{nm}"] = float(sw.statistic)
    py[f"shapiro_p_{nm}"] = float(sw.pvalue)

# --- compare ----------------------------------------------------------------
fails = 0
print(f"{'':8}{'statistic':28}{'helpers.R':>18}{'oracle':>18}{'|diff|':>12}")
for k in R.index:
    if k not in py:
        print(f"{'MISSING':8}{k:28}  no Python oracle implemented"); fails += 1
        continue
    dv = abs(rval(k) - py[k])
    ok = dv <= rtol(k)
    fails += (not ok)
    print(f"{'OK' if ok else 'DISAGREE':8}{k:28}{rval(k):>18.10f}{py[k]:>18.10f}{dv:>12.2e}")
extra = set(py) - set(R.index)
if extra:
    print("oracle-side values with no dump counterpart:", sorted(extra)); fails += 1
print(f"\n{len(R)} statistics, {len(R) - fails} agree, {fails} disagree")
sys.exit(1 if fails else 0)
