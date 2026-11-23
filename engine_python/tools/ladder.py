"""Strength ladder for the proposed Gebeta v1 rules.
Players: random, greedy, minimax depth 1..N. Prints win rates with 95% intervals.
"""
import random, sys, time, math
from multiprocessing import Pool

SOW_CAP = 1000
TURN_CAP = 300

def turn(h, player, start):
    """One full turn under the proposed rules. Returns (new_holes, pit_gain)."""
    b = list(h)
    pos = start
    n = 0
    while True:
        seeds = b[pos]; b[pos] = 0; n += 1
        cur = pos
        for _ in range(seeds):
            cur = (cur + 1) % 12
            b[cur] += 1
        if b[cur] != 1:
            if n >= SOW_CAP:
                return b, 0
            pos = cur
            continue
        if (cur < 6) != (player == 0):
            return b, 0
        opp = 11 - cur
        if b[opp] == 0:
            return b, 0
        cap = b[opp]; b[opp] = 0
        return b, cap

def legal(h, player):
    r = range(0, 6) if player == 0 else range(6, 12)
    return [i for i in r if h[i] > 0]

def side_sum(h, player):
    return sum(h[0:6]) if player == 0 else sum(h[6:12])

NODES = [0]

def nega(h, pits, player, depth, alpha, beta):
    NODES[0] += 1
    moves = legal(h, player)
    if not moves:
        mine = pits[player]
        theirs = pits[1 - player] + side_sum(h, 1 - player)
        return (mine - theirs) * 10
    if depth == 0:
        return pits[player] - pits[1 - player]
    kids = []
    for m in moves:
        nh, g = turn(h, player, m)
        kids.append((g, nh))
    kids.sort(key=lambda x: -x[0])
    best = -10**9
    for g, nh in kids:
        np_ = list(pits); np_[player] += g
        v = -nega(nh, np_, 1 - player, depth - 1, -beta, -alpha)
        if v > best: best = v
        if best > alpha: alpha = best
        if alpha >= beta: break
    return best

def choose(kind, h, pits, player, rng):
    moves = legal(h, player)
    if kind == "random":
        return rng.choice(moves)
    import re
    mt = re.match(r"^(greedy|mm\d+)~(\d+)$", kind)
    if mt:
        # forms: greedy~50 = greedy but 50% random moves; mm3~20 = minimax depth 3 but 20% random moves
        if rng.random() * 100 < int(mt.group(2)):
            return rng.choice(moves)
        kind = mt.group(1)
    if kind == "greedy":
        best = None; pick = []
        for m in moves:
            _, g = turn(h, player, m)
            if best is None or g > best: best = g; pick = [m]
            elif g == best: pick.append(m)
        return rng.choice(pick)
    d = int(kind[2:])  # "mm3"
    rng.shuffle(moves)
    best = -10**9; bm = moves[0]; alpha = -10**9
    for m in moves:
        nh, g = turn(h, player, m)
        np_ = list(pits); np_[player] += g
        v = -nega(nh, np_, 1 - player, d - 1, -10**9, -alpha)
        if v > best: best = v; bm = m
        if best > alpha: alpha = best
    return bm

def play_game(args):
    kinds, seed = args  # kinds = (kind for player 0, kind for player 1)
    rng = random.Random(seed)
    h = [4] * 12; pits = [0, 0]; player = 0; turns = 0
    NODES[0] = 0
    node_counts = [0, 0]; move_counts = [0, 0]
    while True:
        if not legal(h, player):
            other = 1 - player
            pits[other] += side_sum(h, other)
            break
        if turns >= TURN_CAP:
            break
        before = NODES[0]
        m = choose(kinds[player], h, pits, player, rng)
        node_counts[player] += NODES[0] - before; move_counts[player] += 1
        nh, g = turn(h, player, m)
        h = nh; pits[player] += g
        player = 1 - player; turns += 1
    return pits[0] - pits[1], turns, node_counts, move_counts

def wilson(w, n, z=1.96):
    p = w / n
    den = 1 + z * z / n
    c = (p + z * z / (2 * n)) / den
    r = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / den
    return c - r, c + r

def match(a, b, n, pool, base_seed=0):
    jobs = []
    for i in range(n):
        if i % 2 == 0: jobs.append(((a, b), base_seed + i))
        else: jobs.append(((b, a), base_seed + i))
    res = pool.map(play_game, jobs, chunksize=2)
    score = 0.0; margin = 0; first_wins = 0; turns = 0
    nodes_a = 0; moves_a = 0
    sf = 0.0; ss = 0.0
    for i, (diff, t, nc, mc) in enumerate(res):
        a_is_first = (i % 2 == 0)
        a_diff = diff if a_is_first else -diff
        pt = 1 if a_diff > 0 else (0.5 if a_diff == 0 else 0)
        if a_is_first: sf += pt
        else: ss += pt
        if a_diff > 0: score += 1
        elif a_diff == 0: score += 0.5
        if diff > 0: first_wins += 1
        elif diff == 0: first_wins += 0.5
        margin += a_diff; turns += t
        ai = 0 if a_is_first else 1
        nodes_a += nc[ai]; moves_a += mc[ai]
    lo, hi = wilson(score, n)
    return dict(a=a, b=b, n=n, rate=score / n, lo=lo, hi=hi, margin=margin / n, asfirst=sf / ((n + 1) // 2), assecond=ss / (n // 2),
                first=first_wins / n, turns=turns / n,
                nodes=(nodes_a / moves_a) if moves_a else 0)

if __name__ == "__main__":
    pairs = [x.split(":") for x in sys.argv[2:]]
    n = int(sys.argv[1])
    t0 = time.time()
    with Pool(2) as pool:
        for a, b in pairs:
            t1 = time.time()
            r = match(a, b, n, pool)
            print(f"{a:>7} vs {b:<7} n={r['n']:<4} {a} score {r['rate']*100:5.1f}%  (95% range {r['lo']*100:4.1f}-{r['hi']*100:4.1f})  as-first {r['asfirst']*100:5.1f}%  as-second {r['assecond']*100:5.1f}%  avg margin {r['margin']:+5.1f}  first-player share {r['first']*100:4.1f}%  avg turns {r['turns']:4.0f}  nodes/move({a}) {r['nodes']:8.0f}  [{time.time()-t1:4.0f}s]", flush=True)
    print("total", round(time.time() - t0), "s")
