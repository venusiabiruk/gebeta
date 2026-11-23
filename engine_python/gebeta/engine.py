"""Gebeta v1 rules engine (the Python copy).

Follows the Gebeta v1 Rules Spec:
  * 12 holes in a ring, numbered 0 to 11 counterclockwise.
    Player 0 owns holes 0-5, player 1 owns holes 6-11.
  * Each player has a capture pit. Pits are never part of the sowing loop.
  * The hole opposite hole i is 11 - i.
  * A turn is a chain of sowings (relay) that ends on the first landing in an empty hole.

The Dart engine must behave identically. tests/test_cases.json is the shared proof.
"""
from dataclasses import dataclass
from typing import List, Tuple

HOLES = 12
SEEDS_PER_HOLE = 4
SOWING_CAP = 1000      # per turn; the turn ends with no capture when reached
GAME_TURN_CAP = 300    # per game; pits are then compared as they stand

DRAW = -1

# turn_end reasons (same strings in the Dart engine)
CAPTURED = "captured"
OPPONENT_SIDE = "opponent_side"
OPPOSITE_EMPTY = "opposite_empty"
SOWING_CAP_REACHED = "sowing_cap"


@dataclass(frozen=True)
class GameState:
    holes: Tuple[int, ...]      # 12 hole counts
    pits: Tuple[int, int]       # (pit of player 0, pit of player 1)
    player: int                 # whose turn it is: 0 or 1
    turns: int = 0              # turns played so far in this game


def new_game(first_player: int = 0) -> GameState:
    return GameState((SEEDS_PER_HOLE,) * HOLES, (0, 0), first_player, 0)


def owner(hole: int) -> int:
    return 0 if hole < 6 else 1


def opposite(hole: int) -> int:
    return 11 - hole


def side_total(holes, player: int) -> int:
    return sum(holes[0:6]) if player == 0 else sum(holes[6:12])


def legal_moves(state: GameState) -> List[int]:
    """Holes on the mover's side that still hold seeds."""
    lo = 0 if state.player == 0 else 6
    return [i for i in range(lo, lo + 6) if state.holes[i] > 0]


def apply_move(state: GameState, hole: int):
    """Play one full turn. Returns (new_state, events). The old state is never changed.

    events is a list of tuples:
      ("lift", hole, seeds)      seeds lifted from a hole (the first lift, and each relay)
      ("sow", hole)              one seed dropped into a hole
      ("capture", hole, seeds)   seeds moved from the opposite hole into the mover's pit
      ("turn_end", reason)       one of captured, opponent_side, opposite_empty, sowing_cap
    """
    if hole not in legal_moves(state):
        raise ValueError(f"hole {hole} is not a legal move for player {state.player}")

    player = state.player
    b = list(state.holes)
    pits = list(state.pits)
    events = []
    pos = hole
    lifts = 0

    while True:
        seeds = b[pos]
        b[pos] = 0
        lifts += 1
        events.append(("lift", pos, seeds))
        cur = pos
        for _ in range(seeds):
            cur = (cur + 1) % HOLES
            b[cur] += 1
            events.append(("sow", cur))

        was_empty = b[cur] == 1
        if not was_empty:                      # relay: lift from the landing hole
            if lifts >= SOWING_CAP:
                events.append(("turn_end", SOWING_CAP_REACHED))
                break
            pos = cur
            continue

        if owner(cur) != player:               # empty hole on the opponent's side
            events.append(("turn_end", OPPONENT_SIDE))
            break
        opp = opposite(cur)
        if b[opp] == 0:                        # empty hole on your side, opposite empty
            events.append(("turn_end", OPPOSITE_EMPTY))
            break
        captured = b[opp]                      # empty hole on your side, opposite has seeds
        b[opp] = 0
        pits[player] += captured
        events.append(("capture", opp, captured))
        events.append(("turn_end", CAPTURED))
        break

    new_state = GameState(tuple(b), (pits[0], pits[1]), 1 - player, state.turns + 1)
    return new_state, events


def is_game_over(state: GameState) -> bool:
    """Over when the mover has no seeds, or the game-turn cap is reached."""
    return not legal_moves(state) or state.turns >= GAME_TURN_CAP


def final_pits(state: GameState) -> Tuple[int, int]:
    """Pits after leftover seeds are given to their owner.

    If the mover has no seeds, the other player keeps the seeds on their own side.
    If the game stopped at the turn cap, the pits are compared as they stand.
    """
    pits = list(state.pits)
    if not legal_moves(state):
        other = 1 - state.player
        pits[other] += side_total(state.holes, other)
    return pits[0], pits[1]


def winner(state: GameState) -> int:
    """0, 1, or DRAW (-1). Only meaningful when is_game_over(state)."""
    p0, p1 = final_pits(state)
    if p0 > p1:
        return 0
    if p1 > p0:
        return 1
    return DRAW


def encode(state: GameState) -> Tuple[int, ...]:
    """14 integers from the mover's point of view.

    The 12 holes rotated so the mover's first hole comes first (mover's 6 holes, then the
    opponent's 6), then the mover's pit, then the opponent's pit. Integers only: the model
    divides by 48 itself, which keeps floating point out of the shared tests.
    """
    start = 0 if state.player == 0 else 6
    rotated = state.holes[start:] + state.holes[:start]
    me, them = state.player, 1 - state.player
    return tuple(rotated) + (state.pits[me], state.pits[them])


def decode_move(state: GameState, k: int) -> int:
    """Turn the model's relative move number (0-5, the mover's k-th hole) into a hole."""
    start = 0 if state.player == 0 else 6
    return start + k
