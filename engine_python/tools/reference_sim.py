MAX_SOWINGS = 1000

def opposite(i): return 11 - i
def side(i): return 0 if i < 6 else 1

def play(board, stores, player, start, trace=False):
    """board: list of 12 ints; stores: [s0, s1]. Returns (board, stores, log)."""
    b = list(board); s = list(stores); log = []
    assert side(start) == player and b[start] > 0
    pos = start
    n = 0
    while True:
        seeds = b[pos]; b[pos] = 0; n += 1
        log.append(f"pick {pos} ({seeds})")
        cur = pos
        for _ in range(seeds):
            cur = (cur + 1) % 12
            b[cur] += 1
        was_empty = b[cur] == 1
        if not was_empty:
            if n >= MAX_SOWINGS:
                log.append("step cap, turn ends"); break
            pos = cur
            continue
        if side(cur) != player:
            log.append(f"last in empty {cur} (opponent side): turn ends"); break
        opp = opposite(cur)
        if b[opp] == 0:
            log.append(f"last in empty {cur}, opposite {opp} empty: turn ends"); break
        cap = b[opp]; b[opp] = 0; s[player] += cap
        log.append(f"last in empty {cur}, capture {cap} from {opp}")
        break
    return b, s, log

def show(b, s):
    top = b[6:12][::-1]  # opponent row as seen by player 0, left to right: 11..6
    return f"P1 row (11..6): {top}  P1 store {s[1]}\nP0 row (0..5):  {b[0:6]}  P0 store {s[0]}"

if __name__ == "__main__":
    start = [4]*12
    cases = []
    cases.append(("Opening move 2 by P0", start, [0,0], 0, 2))
    cases.append(("Opening move 5 by P0", start, [0,0], 0, 5))
    cases.append(("Capture", [0,0,0,1,0,2, 3,0,5,0,0,4], [0,0], 0, 3))
    cases.append(("Land empty own side, opposite empty", [0,1,0,0,0,0, 0,0,0,0,0,0], [0,0], 0, 1))
    cases.append(("Last seed lands on opponent empty hole", [0,0,0,0,0,2, 0,0,3,0,0,0], [0,0], 0, 5))
    cases.append(("Lap of 12 returns to start hole", [0,0,0,0,0,12, 0,0,0,0,0,0], [0,0], 0, 5))
    for name, b, s, p, m in cases:
        print("==", name, f"(P{p} plays {m})")
        print("before:\n" + show(b, s))
        nb, ns, log = play(b, s, p, m)
        print("log:", "; ".join(log))
        print("after:\n" + show(nb, ns))
        print()
    # relay + loop check from random positions
    import random
    random.seed(1)
    capped = 0; total = 0
    for _ in range(20000):
        b = [0]*12
        for _ in range(48): b[random.randrange(12)] += 1
        p = random.randrange(2)
        moves = [i for i in range(12) if side(i)==p and b[i]>0]
        if not moves: continue
        m = random.choice(moves)
        _, _, log = play(b, [0,0], p, m)
        total += 1
        if "step cap" in log[-1]: capped += 1
    print("random positions tested", total, "step cap hit", capped)
