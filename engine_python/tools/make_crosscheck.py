"""Writes tests/crosscheck.json: random positions with the Python engine's result.

Run from the repo root:
    python engine_python/tools/make_crosscheck.py --n 10000 --seed 7
Do NOT commit the output file. Each result is also compared with the
independent reference_sim.py.
"""
import argparse
import json
import os
import random
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, ".."))
sys.path.insert(0, HERE)

from gebeta.engine import GameState, apply_move, legal_moves  # noqa: E402
from reference_sim import play  # noqa: E402

DEFAULT_OUT = os.path.join(HERE, "..", "..", "tests", "crosscheck.json")


def random_state(rng):
    """Random position with 48 seeds in total and a mover who can move."""
    while True:
        in_holes = rng.randint(1, 48)
        holes = [0] * 12
        for _ in range(in_holes):
            holes[rng.randrange(12)] += 1
        rest = 48 - in_holes
        p0 = rng.randint(0, rest)
        state = GameState(tuple(holes), (p0, rest - p0), rng.randrange(2),
                          rng.randint(0, 299))
        if legal_moves(state):
            return state


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--n", type=int, default=10000)
    parser.add_argument("--seed", type=int, default=7)
    parser.add_argument("--out", default=DEFAULT_OUT)
    args = parser.parse_args()

    rng = random.Random(args.seed)
    cases = []
    mismatches = 0
    for i in range(args.n):
        s = random_state(rng)
        move = rng.choice(legal_moves(s))
        new, events = apply_move(s, move)

        ref_holes, ref_pits, _log = play(list(s.holes), list(s.pits), s.player, move)
        if ref_holes != list(new.holes) or ref_pits != list(new.pits):
            mismatches += 1
            print("MISMATCH with reference_sim at case", i)

        cases.append({
            "name": "cc-%05d" % i,
            "player": s.player,
            "holes": list(s.holes),
            "pits": list(s.pits),
            "turns": s.turns,
            "move": move,
            "expect": {
                "holes": list(new.holes),
                "pits": list(new.pits),
                "player": new.player,
                "turns": new.turns,
                "events": [list(e) for e in events],
            },
        })

    out = os.path.abspath(args.out)
    os.makedirs(os.path.dirname(out), exist_ok=True)
    with open(out, "w", encoding="utf-8") as f:
        json.dump({"version": 1, "seed": args.seed, "cases": cases}, f,
                  separators=(",", ":"))
    print("Wrote %d cases to %s" % (len(cases), out))
    print("Mismatches against reference_sim:", mismatches)
    sys.exit(1 if mismatches else 0)


if __name__ == "__main__":
    main()