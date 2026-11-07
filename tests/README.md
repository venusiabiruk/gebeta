# Shared tests

`test_cases.json` is the single source of truth for engine behavior.
Both `engine_python` and `app_flutter` must pass every case in CI.

## Proposed case format (agree on it in week 1)
```json
{
  "id": "spec_example_1",
  "description": "Worked example 1 from the rules spec",
  "player": 0,
  "state_before": { "holes": [0,0,0,0,0,0,0,0,0,0,0,0], "pits": [0,0] },
  "move": 0,
  "state_after":  { "holes": [0,0,0,0,0,0,0,0,0,0,0,0], "pits": [0,0] },
  "game_over": false
}
```

## Cases to add (from the tech stack doc)
1. The six worked examples from the spec
2. Player 1 mirror cases (opposite hole is `11 - i`)
3. A hole with 13+ seeds (lap over the start hole)
4. A loop-abort case from the cycling positions in the spec simulation
5. Game-end cases: no seeds on the mover's side, leftover seeds, draw
