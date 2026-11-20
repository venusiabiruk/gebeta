# Gebeta v1 Rules Spec

Full spec document: <paste the link to the Rules Spec here>

The rules below are what both engines implement. They are the same rules as
section 1 of the Implementation Guide. A rule is Frozen when all three people
have agreed to it. Changing a Frozen rule follows "Changing the contract".

| # | Rule | Choice | Status |
|---|---|---|---|
| 1 | Board | 12 holes, 4 seeds each, 48 seeds in total, one capture pit per player | Frozen |
| 2 | Direction | Counterclockwise: hole 11 is followed by hole 0. Player 0 owns holes 0-5, player 1 owns 6-11 | Frozen |
| 3 | Pits | At the owner's right-hand end. They only receive captures and are never sown into | Frozen |
| 4 | Sowing | Lift all seeds from one of your own holes that has seeds. Drop one per hole starting at the next hole, including the starting hole on a full lap | Frozen |
| 5 | Relay | If the last seed lands in a hole that already had seeds, lift that hole (with the new seed) and keep sowing | Frozen |
| 6 | Capture | If the last seed lands in an empty hole on your side and the opposite hole has seeds, move the opposite hole's seeds to your pit. The landing seed stays | Frozen |
| 7 | No capture | Landing in an empty hole on the opponent's side, or with an empty opposite hole, ends the turn with no capture | Frozen |
| 8 | After a turn | The other player moves. There is no extra turn after a capture | Frozen |
| 9 | Sowing cap | After 1000 lifts in one turn, if the last seed still lands in an occupied hole, the turn ends with no capture | Frozen |
| 10 | Game over | When the player to move has no seeds on their side (checked before each turn). A player cannot pass | Frozen |
| 11 | Leftover seeds | If the mover has no seeds, the other player adds the seeds on their own side to their pit | Frozen |
| 12 | Turn cap | After 300 turns the game stops and the pits are compared as they stand | Frozen |
| 13 | Winner | More seeds in the final pit wins. Equal pits (24 to 24) are a draw | Frozen |
| 14 | First move | The first game starts with a random player, then the first player alternates. The human may choose to always go first or second | Frozen |

Changes need all three people (see CODEOWNERS for docs/).
