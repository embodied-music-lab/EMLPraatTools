import numpy as np
from scipy import stats
from itertools import combinations

print("=" * 70)
print("EML Stats Batch 7 — Reference Value Computation (scipy)")
print("=" * 70)

# ======================================================================
# KRUSKAL-WALLIS
# ======================================================================

def kw_full(groups, label):
    """Compute KW with all outputs needed for test assertions."""
    print(f"\n{'=' * 60}")
    print(f"  {label}")
    print(f"{'=' * 60}")
    
    for i, g in enumerate(groups):
        print(f"  Group {i+1}: {list(g)}")
    
    # scipy KW
    res = stats.kruskal(*groups)
    H = res.statistic
    p = res.pvalue
    k = len(groups)
    N = sum(len(g) for g in groups)
    df = k - 1
    
    print(f"\n  H = {H:.10f}")
    print(f"  p = {p:.10f}")
    print(f"  df = {df}")
    print(f"  N = {N}")
    print(f"  k = {k}")
    
    # Epsilon-squared (Tomczak formula A)
    eps_sq = H / (N - 1)
    print(f"  epsilon_sq (H/(N-1)) = {eps_sq:.10f}")
    
    # Global ranks and mean ranks per group
    all_data = np.concatenate(groups)
    ranks = stats.rankdata(all_data, method='average')
    
    idx = 0
    for i, g in enumerate(groups):
        n_i = len(g)
        group_ranks = ranks[idx:idx+n_i]
        mean_rank = np.mean(group_ranks)
        print(f"  Group {i+1}: n={n_i}, mean_rank={mean_rank:.6f}")
        idx += n_i
    
    # Tie correction factor
    # T = 1 - sum(t^3 - t) / (N^3 - N) where t = tie group sizes
    unique, counts = np.unique(ranks, return_counts=True)
    tie_sum = sum(c**3 - c for c in counts if c > 1)
    tie_correction = 1 - tie_sum / (N**3 - N)
    print(f"  tie_correction = {tie_correction:.10f}")
    print(f"  has_ties = {1 if tie_sum > 0 else 0}")
    
    return H, p, df, N, k, eps_sq, tie_correction


def dunn_test(groups, label, method='bonferroni'):
    """Compute Dunn's test with p-value adjustment."""
    print(f"\n  --- Dunn's post-hoc ({method}) ---")
    
    k = len(groups)
    N = sum(len(g) for g in groups)
    
    # Global ranks
    all_data = np.concatenate(groups)
    ranks = stats.rankdata(all_data, method='average')
    
    # Mean ranks and sizes per group
    group_ranks = []
    group_sizes = []
    idx = 0
    for g in groups:
        n_i = len(g)
        group_ranks.append(ranks[idx:idx+n_i])
        group_sizes.append(n_i)
        idx += n_i
    
    mean_ranks = [np.mean(gr) for gr in group_ranks]
    
    # Tie correction
    unique, counts = np.unique(ranks, return_counts=True)
    tie_sum = sum(c**3 - c for c in counts if c > 1)
    
    # Variance of ranks (tie-corrected)
    # sigma^2 = [N(N+1)/12 - sum(t^3 - t)/(12(N-1))] for Dunn's
    sigma_sq = (N * (N + 1) / 12.0)
    if tie_sum > 0:
        sigma_sq -= tie_sum / (12.0 * (N - 1))
    
    # All pairwise comparisons
    pairs = list(combinations(range(k), 2))
    n_pairs = len(pairs)
    raw_p = []
    z_values = []
    
    for (i, j) in pairs:
        diff = mean_ranks[i] - mean_ranks[j]
        se = np.sqrt(sigma_sq * (1.0/group_sizes[i] + 1.0/group_sizes[j]))
        z = diff / se
        # Two-tailed p
        p = 2 * stats.norm.sf(abs(z))
        raw_p.append(p)
        z_values.append(z)
        print(f"  Pair ({i+1},{j+1}): z={z:.8f}, raw_p={p:.8f}")
    
    # Adjust p-values
    raw_p_arr = np.array(raw_p)
    if method == 'bonferroni':
        adj_p = np.minimum(raw_p_arr * n_pairs, 1.0)
    elif method == 'holm':
        # Holm step-down
        order = np.argsort(raw_p_arr)
        adj_p = np.zeros(n_pairs)
        running_max = 0
        for rank_idx, orig_idx in enumerate(order):
            multiplier = n_pairs - rank_idx
            adj_val = min(raw_p_arr[orig_idx] * multiplier, 1.0)
            running_max = max(running_max, adj_val)
            adj_p[orig_idx] = running_max
    elif method == 'bh':
        order = np.argsort(raw_p_arr)
        adj_p = np.zeros(n_pairs)
        running_min = 1.0
        for rank_idx in range(n_pairs - 1, -1, -1):
            orig_idx = order[rank_idx]
            bh_rank = rank_idx + 1
            adj_val = min(raw_p_arr[orig_idx] * n_pairs / bh_rank, 1.0)
            running_min = min(running_min, adj_val)
            adj_p[orig_idx] = running_min
    
    for idx, (i, j) in enumerate(pairs):
        print(f"  Pair ({i+1},{j+1}): adj_p ({method}) = {adj_p[idx]:.8f}")
    
    return z_values, raw_p, list(adj_p)


# ======================================================================
# TEST SET 1: 3 groups, clear effect, no ties
# ======================================================================
g1 = np.array([23, 25, 27, 22, 26])
g2 = np.array([30, 33, 29, 31, 34])
g3 = np.array([18, 20, 22, 19, 17])
kw_full([g1, g2, g3], "KW-1: 3 groups, clear effect, no ties")
dunn_test([g1, g2, g3], "Dunn-1", "bonferroni")

# ======================================================================
# TEST SET 2: 3 groups, no effect (identical distributions)
# ======================================================================
g4 = np.array([10, 11, 12, 10.5, 11.5])
g5 = np.array([10.5, 11, 11.5, 10, 12])
g6 = np.array([11, 10.5, 11.5, 10, 12])
kw_full([g4, g5, g6], "KW-2: 3 groups, no effect (identical)")
dunn_test([g4, g5, g6], "Dunn-2", "bonferroni")

# ======================================================================
# TEST SET 3: 4 groups, unequal sizes, with ties
# ======================================================================
g7 = np.array([5, 6, 7, 5, 6])
g8 = np.array([8, 9, 10, 8])
g9 = np.array([5, 6, 7])
g10 = np.array([12, 13, 14, 12, 13, 15])
kw_full([g7, g8, g9, g10], "KW-3: 4 groups, unequal sizes, ties")
dunn_test([g7, g8, g9, g10], "Dunn-3", "bonferroni")
dunn_test([g7, g8, g9, g10], "Dunn-3-holm", "holm")

# ======================================================================
# TEST SET 4: 2 groups (should match MWU)
# ======================================================================
g11 = np.array([5, 7, 9, 6, 8])
g12 = np.array([10, 12, 11, 13, 14])
kw_full([g11, g12], "KW-4: 2 groups (verify matches chi-sq of MWU z^2)")
# Verify: for 2 groups, H = z^2 from MWU
mwu_res = stats.mannwhitneyu(g11, g12, alternative='two-sided')
print(f"  MWU verification: U={mwu_res.statistic}, p={mwu_res.pvalue:.10f}")

# ======================================================================
# TEST SET 5: Large groups (approximation robustness)
# ======================================================================
np.random.seed(42)
g13 = np.random.normal(50, 10, 30)
g14 = np.random.normal(55, 10, 30)
g15 = np.random.normal(45, 10, 30)
kw_full([g13, g14, g15], "KW-5: Large groups (n=30 each)")
dunn_test([g13, g14, g15], "Dunn-5", "bonferroni")

# ======================================================================
# TEST SET 6: Edge case — single observation per group
# ======================================================================
g16 = np.array([1.0])
g17 = np.array([2.0])
g18 = np.array([3.0])
kw_full([g16, g17, g18], "KW-6: Single obs per group")

# ======================================================================
# TEST SET 7: All identical values
# ======================================================================
g19 = np.array([5, 5, 5])
g20 = np.array([5, 5, 5])
print(f"\n{'=' * 60}")
print(f"  KW-7: All identical values")
print(f"{'=' * 60}")
try:
    res = stats.kruskal(g19, g20)
    print(f"  H = {res.statistic}, p = {res.pvalue}")
except Exception as e:
    print(f"  scipy raises: {e}")
    print(f"  Expected: H=0, p=1 (or NaN)")

# ======================================================================
# EPSILON-SQUARED VERIFICATION
# ======================================================================
print(f"\n{'=' * 60}")
print(f"  Epsilon-squared formula verification")
print(f"{'=' * 60}")
# From Test Set 1
H1 = 11.58  # approximate
N1 = 15
k1 = 3
eps_A = H1 / (N1 - 1)
eps_B = (H1 - k1 + 1) / (N1 - k1)
print(f"  H={H1}, N={N1}, k={k1}")
print(f"  Formula A (Tomczak): {eps_A:.6f}")
print(f"  Formula B (Kelley):  {eps_B:.6f}")
print(f"  Difference: {abs(eps_A - eps_B):.6f} ({abs(eps_A-eps_B)/eps_A*100:.1f}%)")

