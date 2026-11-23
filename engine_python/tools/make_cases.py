"""Generate tests/test_cases.json from an implementation that is independent of engine.py.

Expected results come from /tmp/gebeta_sim.py (the reference simulator used for the spec's
worked examples). The six spec examples are also checked against the values printed in the spec.
"""
import json, random, sys
sys.path.insert(0, __import__("os").path.dirname(__import__("os").path.abspath(__file__)))
from reference_sim import play  # independent reference implementation

OUT = sys.argv[1]
rng = random.Random(2026)


def reason_from_log(log):
    last = log[-1]
    if "capture" in last: return "captured"
    if "step cap" in last: return "sowing_cap"
    if "opponent side" in last: return "opponent_side"
    if "opposite" in last and "empty" in last: return "opposite_empty"
    raise ValueError(last)


def encode(holes, pits, player):
    start = 0 if player == 0 else 6
    return holes[start:] + holes[:start] + [pits[player], pits[1 - player]]


def legal(holes, player):
    lo = 0 if player == 0 else 6
    return [i for i in range(lo, lo + 6) if holes[i] > 0]


def make_case(name, holes, pits, player, move):
    nb, ns, log = play(holes, pits, player, move)
    return {
        "name": name, "player": player, "holes": holes, "pits": pits, "turns": 0,
        "legal_moves": legal(holes, player), "encoded": encode(holes, pits, player),
        "move": move,
        "expect": {"holes": nb, "pits": ns, "turn_ended": reason_from_log(log), "next_player": 1 - player},
    }


cases = []

# 1. The six worked examples from the Rules Spec, checked against the spec's printed answers.
spec = [
    ("spec-1-relay-then-capture", [4]*12, 2, [6,6,2,7,1,6, 1,0,6,6,0,1], 6),
    ("spec-2-relay-ends-on-opponent-side", [4]*12, 5, [6,0,1,6,6,2, 7,1,6,1,6,6], 0),
    ("spec-3-capture", [0,0,0,1,0,2, 3,2,5,0,0,4], 3, [0,0,0,0,1,2, 3,0,5,0,0,4], 2),
    ("spec-4-own-side-opposite-empty", [0,1,0,0,0,0, 0,0,0,0,0,0], 1, [0,0,1,0,0,0, 0,0,0,0,0,0], 0),
    ("spec-5-ends-on-opponent-side", [0,0,0,0,0,2, 0,0,3,0,0,0], 5, [0,0,0,0,0,0, 1,1,3,0,0,0], 0),
    ("spec-6-full-lap-capture", [0,0,0,0,0,12, 0,0,0,0,0,0], 5, [1,1,1,1,1,1, 0,1,1,1,1,1], 1),
]
for name, holes, move, want_holes, want_pit0 in spec:
    c = make_case(name, list(holes), [0, 0], 0, move)
    assert c["expect"]["holes"] == want_holes, (name, c["expect"]["holes"])
    assert c["expect"]["pits"] == [want_pit0, 0], (name, c["expect"]["pits"])
    cases.append(c)

# 2. Mirror of the spec examples for player 1 (rotate the board by 6 holes).
for name, holes, move, _, _ in spec:
    rot = holes[6:] + holes[:6]
    cases.append(make_case(name.replace("spec-", "mirror-p1-"), rot, [0, 0], 1, (move + 6) % 12))

# 3. Random positions, balanced across the four turn_end reasons.
targets = {"captured": 70, "opponent_side": 70, "opposite_empty": 40, "sowing_cap": 4}
counts = {k: 0 for k in targets}
tries = 0
while any(counts[k] < targets[k] for k in targets) and tries < 400000:
    tries += 1
    hole_total = rng.randint(12, 48)
    holes = [0] * 12
    for _ in range(hole_total):
        holes[rng.randrange(12)] += 1
    rest = 48 - hole_total
    p0 = rng.randint(0, rest)
    pits = [p0, rest - p0]
    player = rng.randrange(2)
    moves = legal(holes, player)
    if not moves:
        continue
    move = rng.choice(moves)
    c = make_case("", holes, pits, player, move)
    r = c["expect"]["turn_ended"]
    if counts[r] >= targets[r]:
        continue
    counts[r] += 1
    c["name"] = f"random-{r}-{counts[r]:02d}"
    cases.append(c)

# 4. Game-end cases, written by hand from the spec's game-end rules.
end_cases = [
    {"name": "new-game-not-over", "player": 0, "holes": [4]*12, "pits": [0, 0], "turns": 0,
     "expect": {"game_over": False}},
    {"name": "mover-empty-other-keeps-leftovers", "player": 0, "holes": [0]*6 + [3,1,0,2,0,0], "pits": [18, 24], "turns": 40,
     "expect": {"game_over": True, "final_pits": [18, 30], "winner": 1}},
    {"name": "mover-empty-draw-24-24", "player": 0, "holes": [0]*6 + [1,1,0,0,0,0], "pits": [24, 22], "turns": 40,
     "expect": {"game_over": True, "final_pits": [24, 24], "winner": -1}},
    {"name": "player1-empty-player0-wins", "player": 1, "holes": [1,2,0,0,3,0] + [0]*6, "pits": [20, 22], "turns": 40,
     "expect": {"game_over": True, "final_pits": [26, 22], "winner": 0}},
    {"name": "turn-cap-compares-pits-only", "player": 0, "holes": [1,0,0,0,0,0, 0,0,0,2,0,0], "pits": [25, 20], "turns": 300,
     "expect": {"game_over": True, "final_pits": [25, 20], "winner": 0}},
    {"name": "turn-cap-draw", "player": 1, "holes": [1,0,0,0,0,0, 0,0,0,3,0,0], "pits": [22, 22], "turns": 300,
     "expect": {"game_over": True, "final_pits": [22, 22], "winner": -1}},
    {"name": "one-turn-before-cap-not-over", "player": 0, "holes": [1,0,0,0,0,0, 0,0,0,2,0,0], "pits": [25, 20], "turns": 299,
     "expect": {"game_over": False}},
]
for c in end_cases:
    assert sum(c["holes"]) + sum(c["pits"]) == 48, c["name"]

doc = {
    "version": 1,
    "about": "Shared test cases for the Python and Dart engines. Boards list holes 0-11; pits are [player 0, player 1]. "
             "turn_ended is the reason on the last turn_end event. encoded is encode(state) before the move. "
             "legal_moves is for the player to move. Expected values come from an independent reference simulator.",
    "move_cases": cases,
    "end_cases": end_cases,
}
with open(OUT, "w", encoding="utf-8") as f:
    json.dump(doc, f, indent=1)
print("wrote", len(cases), "move cases and", len(end_cases), "end cases;", counts, "tries", tries)
