"""Run the shared test file against the Python engine.

Usage (from the repo root):  python engine_python/run_tests.py
Exit code 0 means every case passed. CI should run this on every push.
"""
import json
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)

from gebeta.engine import (GameState, apply_move, decode_move, encode, is_game_over,  # noqa: E402
                           legal_moves, winner, final_pits)

CASES = os.path.join(HERE, "..", "tests", "test_cases.json")
TRACES = os.path.join(HERE, "..", "tests", "event_traces.json")
KNOWN_VERSION = 1


def state_from(case):
    return GameState(tuple(case["holes"]), tuple(case["pits"]), case["player"], case.get("turns", 0))


def main():
    with open(CASES, encoding="utf-8") as f:
        data = json.load(f)

    failures = []
    if data.get("version") != KNOWN_VERSION:
        print(f"test_cases.json version {data.get('version')} is not {KNOWN_VERSION}; update the runner")
        sys.exit(1)

    for c in data["move_cases"]:
        s = state_from(c)
        got_legal = legal_moves(s)
        if got_legal != c["legal_moves"]:
            failures.append((c["name"], "legal_moves", c["legal_moves"], got_legal))
        got_enc = list(encode(s))
        if got_enc != c["encoded"]:
            failures.append((c["name"], "encode", c["encoded"], got_enc))
        if c["encoded"][:6] and decode_move(s, 0) != (0 if s.player == 0 else 6):
            failures.append((c["name"], "decode_move", None, None))
        ns, _events = apply_move(s, c["move"])
        e = c["expect"]
        got = {"holes": list(ns.holes), "pits": list(ns.pits), "turn_ended": _events[-1][1],
               "next_player": ns.player}
        for key in ("holes", "pits", "turn_ended", "next_player"):
            if got[key] != e[key]:
                failures.append((c["name"], key, e[key], got[key]))

    for c in data["end_cases"]:
        s = state_from(c)
        e = c["expect"]
        got = {"game_over": is_game_over(s)}
        if e["game_over"]:
            got["final_pits"] = list(final_pits(s))
            got["winner"] = winner(s)
        for key, want in e.items():
            if got.get(key) != want:
                failures.append((c["name"], key, want, got.get(key)))

    with open(TRACES, encoding="utf-8") as f:
        traces = json.load(f)
    if traces.get("version") != KNOWN_VERSION:
        print(f"event_traces.json version {traces.get('version')} is not {KNOWN_VERSION}")
        sys.exit(1)
    for t in traces["cases"]:
        s = state_from(t)
        _ns, evs = apply_move(s, t["move"])
        got = [list(e) for e in evs]
        if got != t["events"]:
            failures.append((t["name"], "events", t["events"][:6], got[:6]))

    total = len(data["move_cases"]) + len(data["end_cases"]) + len(traces["cases"])
    if failures:
        print(f"FAILED {len(failures)} check(s) in {total} cases")
        for f in failures[:20]:
            print("  ", f)
        sys.exit(1)
    print(f"OK: all {total} cases passed ({len(data['move_cases'])} move cases, {len(data['end_cases'])} end cases)")


if __name__ == "__main__":
    main()
