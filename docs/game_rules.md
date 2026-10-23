# Game Rules

How a match of Monsternight is played. The goal is to keep the rules relatively simple.

## Match

- 2 to 8 players. Usually 4 or 5.
- One match is about 30 minutes. This is a rough target, not a fixed requirement.
- A match lasts a fixed number of **turns**. A turn means every player moves once. The number is **12**, tuned during playtesting so that **on average 2 players reach the end**.
- The match ends after the last turn, or **right away once all players but one have reached the end**.
- There is one board, and it's the same every match. See [board.md](board.md).

## Match flow

1. **Lobby.** The host opens a lobby and the other players join. See [screens.md](screens.md#lobby).
2. **Turn order roll.** Turn order is decided at random and stays the same for the whole match.
3. **Monster select.** Players pick in reverse turn order, so the player who moves last picks first. Each monster can only be picked once.
4. **Turns.** On your turn, you roll and move, choose a path at any split, and resolve the space you land on.
5. **Trophy ceremony.** When the match ends, trophies are handed out, followed by fun stats. See [screens.md](screens.md#trophy-ceremony).
6. **Back to the lobby.**

## Moving

- Roll **one six-sided die**.
- A space only does something if you **land** on it. Passing over a space does nothing.
- Several players can stand on the same space. Nothing happens when they do.
- Any roll that reaches the end counts. You don't need the exact number.
- A player who reaches the end sits out for the rest of the match and watches.

## Winning: trophies

When the match ends, everyone counts their trophies and the leaderboard is ranked by trophy count. Trophy counts stay secret until the ceremony.

| Achievement | Trophies |
|---|---|
| First to reach the end | 2 |
| Second to reach the end | 1 |
| Most gold when the match ends | 1 |
| Most minigames won (swap duels count) | 1 |

- Reaching the end third or later earns nothing.
- If players tie for most gold or for most minigames won, they all get the trophy.
- There's no trophy for blood.
- **Tiebreaker:** among players with the same trophy count, the one with a finishing trophy ranks higher, then the one with a gold trophy, then the one with a minigame trophy.

## Blood (health)

- Everyone starts with **3 drops of blood**. Blood can't go above 3.
- At 0 blood you die and go back to the start. You lose **all** your coins and come back with full blood. There are no checkpoints.

## Coins (gold)

- Coins count toward the "most gold" trophy.
- You gain and lose coins on board spaces and in duels.
- You lose all of them when you die.

## Board spaces

| Space | Effect |
|---|---|
| Coin | Gain 1 coin |
| Spikes | Lose 1 blood |
| Thief | Lose 1 coin |
| Church | Gain 1 blood (up to 3) |
| Minigame spaces | Each minigame has its own space. Landing on one starts a duel of that game. See [minigames.md](minigames.md). |

- **One of every two spaces is empty** (the user's call, 2026-10-23): nothing happens when a piece lands there. The filled half is mostly quick spaces (coin, spikes, thief, church), with a minigame space or a few on each stretch.
- **A match is 17 turns** (the user's call, 2026-10-23), so that about 2 players reach the end of the 57-space board.
- The four quick spaces show up about equally often, in every area of the board. The two paths of the first split are the one exception (see [board.md](board.md#first-split-graveyard-or-church)).

## Decision timers

Every decision has a time limit. When it runs out, a random valid choice is made for that player. The timers already run in the first playable.

| Decision | Time |
|---|---|
| Roll the die | 5 s |
| Pick a path at a split | 10 s |
| Pick an opponent and a stake | 20 s for both together |
| Pick a monster | 30 s |

## Cruelty

Players should be able to be pretty cruel to each other. The cruel moves are stealing coins and swapping places, and both happen through duels (see [minigames.md](minigames.md)).

## Ruled out

- No items and no shop.
- No toll gates and no trading coins for souls.
- No free-for-all minigames. Every minigame is a 1v1.
- No betting.
- No narrator.
- No text chat and no reactions. Watchers just watch.
- No match settings. The number of turns and the timer lengths are fixed.
