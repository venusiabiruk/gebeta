# Gebeta

Mobile version of the traditional Ethiopian game Gebeta (v1).

- ML opponent trained with self-play
- Single player: Novice, Amateur, Master
- Two-player mode on one phone

## Repository layout

| Folder | Purpose | Owner |
|---|---|---|
| `engine_python/` | Python game engine, minimax baseline, ML training | Dev A |
| `app_flutter/` | Flutter app + Dart engine | Dev B / Dev C |
| `tests/` | Shared `test_cases.json` that BOTH engines must pass | everyone |
| `docs/` | Rules spec, tech stack and timeline, notes | everyone |

## Golden rule
The Dart engine and the Python engine must behave identically.
Both read `tests/test_cases.json`. CI runs on every push.

## Team workflow
1. Never push directly to `main`. Create a branch: `git checkout -b feature/short-name`
2. Open a Pull Request, get one review, make sure CI is green, then merge.
3. Branch names: `engine/...`, `app/...`, `docs/...`, `tests/...`

See `CONTRIBUTING.md` for details.
