2026-11-12 - Roles: Person 1 = anansi-sime (E1, U1, A1), Person 2 = TsiOnshime (E2, U2, A2), Person 3 = venusiabiruk (E3, U3, A3).

2026-11-20 - Contract wins over the person briefs: constant names, toJson, positional TurnResult, paths, Phase/GameMode/GameSnapshot all follow sections 1-8 (S-03 items 1-9, 11).
2026-11-20 - FirstMove is { alternate, human, ai }; game 1 of alternate is random; two-player always alternates.
2026-11-20 - Stores gain StatsStore.lastFirstPlayer/setLastFirstPlayer/reset and SoundService.setEnabled; SettingsStore gains music, haptics, animation speed and board theme.
2026-11-20 - Weights file uses the section 6 schema; manifest.json (useNetworkForMaster, gates) added to the contract.
2026-11-20 - AiService is abstract in ai_service.dart; LevelConfig/configFor in levels.dart; random rate is an integer percent.
2026-11-20 - Dart depth-8 minimax target is under 50 ms; measure on a cheap Android phone before adding an isolate.
2026-11-20 - Each owner pushes their own day-1 stubs; Person 1 pushes types, turn.dart, engine.dart.
2026-11-20 - Defaults confirmed (S-04): sowing cap 1000, turn cap 300, draw 24-24, 400-game pass marks, network 14-128-128, DAgger, timings lift 200 / sow 30-220 / capture 450 ms, 600 ms think time.
2026-11-20 - Master uses the network alone when its gate passed, else depth-8 minimax; AI search runs in an isolate only if the cheap-phone speed test shows stutter.
2026-11-20 - UI additions agreed (S-05): BoardView speed/theme/skip, GameController setPaused/restartGame, screens splash/opponent select/pause/how to play, landscape only, bundled fonts, haptics via HapticFeedback.
2026-11-20 - Out of scope for v1: other languages and language picker, hints, undo, pass-the-phone screen.
2026-11-20 - Rules Spec items all marked Frozen (docs/rules_spec.md, I-03).
