/// Constants of the Gebeta rules. The Python twin is engine_python/gebeta/engine.py, with UPPER_SNAKE_CASE names.
///

/// Where both are in scope, import this file with a prefix:
/// `import 'constants.dart' as constants;`

library;

/// Holes on the board, 6 per player.
const int holes = 12;

/// Seeds in each hole at the start of a game.
const int seedsPerHole = 4;

/// Seeds in the game (holes plus pits, always).
const int totalSeeds = 48;

/// Most lifts in one turn before the turn is stopped with no capture.
const int sowingCap = 1000;

/// Most turns in one game before the game is stopped.
const int gameTurnCap = 300;

/// The winner value for a drawn game.
const int draw = -1;