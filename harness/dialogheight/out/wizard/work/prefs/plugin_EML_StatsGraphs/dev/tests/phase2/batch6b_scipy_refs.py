import numpy as np
from scipy import stats
from itertools import combinations

print("=" * 70)
print("EML Stats Batch 6B — Reference Value Computation (scipy)")
print("=" * 70)

def pairwise_t(groups, labels, method='bonferroni', welch=True):
    """All-pairs t-tests with p-value adjustment."""
    k = len(groups)
    pairs = list(combinations(range(k), 2))
    n_pairs = len(pairs)
    
    raw_p = []
    t_values = []
    df_values = []
    cohen_d = []
    
    for (i, j) in pairs:
        if welch:
            res = stats.ttest_ind(groups[i], groups[j], equal_var=False)
        else:
            res = stats.ttest_ind(groups[i], groups[j], equal_var=True)
        raw_p.append(res.pvalue)
        t_values.append(res.statistic)
        df_values.append(len(groups[i]) + len(groups[j]) - 2 if not welch else res.df)
        
        # Cohen's d (pooled)
        n1, n2 = len(groups[i]), len(groups[j])
        s1, s2 = np.std(groups[i], ddof=1), np.std(groups[j], ddof=1)
        pooled_sd = np.sqrt(((n1-1)*s1**2 + (n2-1)*s2**2) / (n1+n2-2))
        d = (np.mean(groups[i]) - np.mean(groups[j])) / pooled_sd if pooled_sd > 0 else 0
        cohen_d.append(d)
    
    # Adjust
    raw_arr = np.array(raw_p)
    if method == 'bonferroni':
        adj_p = np.minimum(raw_arr * n_pairs, 1.0)
    elif method == 'holm':
        order = np.argsort(raw_arr)
        adj_p = np.zeros(n_pairs)
        running_max = 0
        for rank_idx, orig_idx in enumerate(order):
            adj_val = min(raw_arr[orig_idx] * (n_pairs - rank_idx), 1.0)
            running_max = max(running_max, adj_val)
            adj_p[orig_idx] = running_max
    
    print(f"\n  Pairwise t-tests ({method}, {'Welch' if welch else 'Student'}):")
    for idx, (i, j) in enumerate(pairs):
        print(f"    ({labels[i]} vs {labels[j]}): t={t_values[idx]:.8f}, "
              f"raw_p={raw_p[idx]:.8f}, adj_p={adj_p[idx]:.8f}, d={cohen_d[idx]:.6f}")
    
    return t_values, raw_p, list(adj_p), cohen_d, df_values


def pairwise_mwu(groups, labels, method='bonferroni'):
    """All-pairs Mann-Whitney U with p-value adjustment."""
    k = len(groups)
    pairs = list(combinations(range(k), 2))
    n_pairs = len(pairs)
    
    raw_p = []
    u_values = []
    rbs = []  # rank-biserial r
    
    for (i, j) in pairs:
        res = stats.mannwhitneyu(groups[i], groups[j], alternative='two-sided')
        raw_p.append(res.pvalue)
        u_values.append(res.statistic)
        # rank-biserial: r = 1 - 2*U/(n1*n2)
        n1, n2 = len(groups[i]), len(groups[j])
        u1 = res.statistic
        u2 = n1 * n2 - u1
        r = (u1 - u2) / (n1 * n2)
        rbs.append(r)
    
    raw_arr = np.array(raw_p)
    if method == 'bonferroni':
        adj_p = np.minimum(raw_arr * n_pairs, 1.0)
    elif method == 'holm':
        order = np.argsort(raw_arr)
        adj_p = np.zeros(n_pairs)
        running_max = 0
        for rank_idx, orig_idx in enumerate(order):
            adj_val = min(raw_arr[orig_idx] * (n_pairs - rank_idx), 1.0)
            running_max = max(running_max, adj_val)
            adj_p[orig_idx] = running_max
    
    print(f"\n  Pairwise MWU ({method}):")
    for idx, (i, j) in enumerate(pairs):
        print(f"    ({labels[i]} vs {labels[j]}): U={u_values[idx]:.4f}, "
              f"raw_p={raw_p[idx]:.8f}, adj_p={adj_p[idx]:.8f}, r_rb={rbs[idx]:.6f}")
    
    return u_values, raw_p, list(adj_p), rbs


def scheffe_test(groups, labels):
    """Scheffé all-pairs post-hoc from one-way ANOVA."""
    k = len(groups)
    all_data = np.concatenate(groups)
    group_labels = np.concatenate([np.full(len(g), i) for i, g in enumerate(groups)])
    N = len(all_data)
    
    # ANOVA MSE
    grand_mean = np.mean(all_data)
    ss_within = sum(np.sum((g - np.mean(g))**2) for g in groups)
    df_within = N - k
    mse = ss_within / df_within
    
    pairs = list(combinations(range(k), 2))
    
    print(f"\n  Scheffé test (MSE={mse:.6f}, df_within={df_within}):")
    f_values = []
    p_values = []
    
    for (i, j) in pairs:
        diff = np.mean(groups[i]) - np.mean(groups[j])
        se = np.sqrt(mse * (1.0/len(groups[i]) + 1.0/len(groups[j])))
        # Scheffé F = (contrast^2 / (k-1)) / MSE_contrast
        # Or equivalently: F_scheffe = t^2 / (k-1)
        t_val = diff / se
        f_scheffe = t_val**2 / (k - 1)
        # p from F distribution with (k-1, df_within)
        p = 1 - stats.f.cdf(f_scheffe, k - 1, df_within)
        f_values.append(f_scheffe)
        p_values.append(p)
        print(f"    ({labels[i]} vs {labels[j]}): diff={diff:.4f}, "
              f"F_scheffe={f_scheffe:.6f}, p={p:.8f}")
    
    return f_values, p_values


# ======================================================================
# TEST SET 1: 3 groups, clear separation (reuse from Batch 6 ANOVA)
# ======================================================================
print(f"\n{'=' * 60}")
print("  PT-1: 3 groups, clear separation")
print(f"{'=' * 60}")
g1 = np.array([23, 25, 27, 22, 26], dtype=float)
g2 = np.array([30, 33, 29, 31, 34], dtype=float)
g3 = np.array([18, 20, 22, 19, 17], dtype=float)
labels = ["g1", "g2", "g3"]

pairwise_t([g1, g2, g3], labels, 'bonferroni', welch=True)
pairwise_t([g1, g2, g3], labels, 'holm', welch=True)
pairwise_mwu([g1, g2, g3], labels, 'bonferroni')
scheffe_test([g1, g2, g3], labels)

# ======================================================================
# TEST SET 2: 3 groups, no effect
# ======================================================================
print(f"\n{'=' * 60}")
print("  PT-2: 3 groups, no effect")
print(f"{'=' * 60}")
g4 = np.array([10, 11, 12, 10.5, 11.5], dtype=float)
g5 = np.array([10.5, 11, 11.5, 10, 12], dtype=float)
g6 = np.array([11, 10.5, 11.5, 10, 12], dtype=float)
labels2 = ["g1", "g2", "g3"]

pairwise_t([g4, g5, g6], labels2, 'bonferroni')
pairwise_mwu([g4, g5, g6], labels2, 'bonferroni')

# ======================================================================
# TEST SET 3: 4 groups, unequal sizes (matches Batch 7 KW-3)
# ======================================================================
print(f"\n{'=' * 60}")
print("  PT-3: 4 groups, unequal sizes")
print(f"{'=' * 60}")
g7 = np.array([5, 6, 7, 5, 6], dtype=float)
g8 = np.array([8, 9, 10, 8], dtype=float)
g9 = np.array([5, 6, 7], dtype=float)
g10 = np.array([12, 13, 14, 12, 13, 15], dtype=float)
labels3 = ["g1", "g2", "g3", "g4"]

pairwise_t([g7, g8, g9, g10], labels3, 'bonferroni')
pairwise_mwu([g7, g8, g9, g10], labels3, 'bonferroni')
scheffe_test([g7, g8, g9, g10], labels3)

# ======================================================================
# TEST SET 4: 2 groups only (degenerate case — should equal single test)
# ======================================================================
print(f"\n{'=' * 60}")
print("  PT-4: 2 groups (should match single t-test / MWU)")
print(f"{'=' * 60}")
g11 = np.array([5, 7, 9, 6, 8], dtype=float)
g12 = np.array([10, 12, 11, 13, 14], dtype=float)

pairwise_t([g11, g12], ["A", "B"], 'bonferroni')
# Verify: single test
res_single = stats.ttest_ind(g11, g12, equal_var=False)
print(f"\n  Single Welch t-test: t={res_single.statistic:.8f}, p={res_single.pvalue:.8f}")
print(f"  (Should match pairwise with k=2, adjustment is p*1 = p)")

pairwise_mwu([g11, g12], ["A", "B"], 'bonferroni')
res_mwu = stats.mannwhitneyu(g11, g12, alternative='two-sided')
print(f"\n  Single MWU: U={res_mwu.statistic:.4f}, p={res_mwu.pvalue:.8f}")

# ======================================================================
# TEST SET 5: Scheffé vs Tukey cross-check
# ======================================================================
print(f"\n{'=' * 60}")
print("  PT-5: Scheffé should be more conservative than Bonferroni-t")
print(f"{'=' * 60}")
# Scheffé p should be >= pairwise t (Bonferroni) p for same data
t_vals, t_raw, t_adj, t_d, t_df = pairwise_t([g1, g2, g3], labels, 'bonferroni')
s_f, s_p = scheffe_test([g1, g2, g3], labels)
print("\n  Conservatism check:")
for idx, (i, j) in enumerate(combinations(range(3), 2)):
    print(f"    ({labels[i]} vs {labels[j]}): Bonf-t adj_p={t_adj[idx]:.6f}, "
          f"Scheffé p={s_p[idx]:.6f}, "
          f"Scheffé >= Bonf-t: {s_p[idx] >= t_adj[idx] - 1e-10}")

