# Game Rules

How a match of Monsternight is played. The goal is to keep the rules relatively simple.

## Match

- **3 to 8 players** (the brief). Usually 4 or 5. Two players can't start a match.
- One match is about 30 minutes. This is a rough target, not a fixed requirement.
- A match lasts a fixed number of **turns**. A turn means every player moves once. The number, and the board's length, come from the lobby's size (the brief):

| Players | Turns | Board length (the average of the shortest and longest way) |
|---|---|---|
| 3 | 11 | 65 |
| 4 | 10 | 60 |
| 5 | 9 | 55 |
| 6 | 8 | 51 |
| 7 | 8 | 48 |
| 8 | 7 | 46 |

- The match ends after the last turn, or **right away once all players but one have reached the end**.
- The board's length is fixed for each lobby size, and its spaces are shuffled fresh every match. See [board.md](board.md).

## Match flow

1. **Lobby.** The host opens a room and the other players join. See [screens.md](screens.md#lobby).
2. **Turn order roll.** Turn order is decided at random and stays the same for the whole match.
3. **Monster select.** Players pick in reverse turn order, so the player who moves last picks first. Each monster can only be picked once, and each has a power (see [characters.md](characters.md#powers)).
4. **Turns.** On your turn, you roll and move, choose a path at any split, and resolve the space you land on.
5. **Trophy ceremony.** When the match ends, trophies are handed out, followed by fun stats. See [screens.md](screens.md#trophy-ceremony).
6. **Back to the lobby.**

## Moving

- Roll **two six-sided dice** and move the sum (2 to 12). The Wolf Man adds 1 per die (+2)..
- A space only does something if you **land** on it. Passing over a space does nothing.
- Several players can stand on the same space. Nothing happens when they do.
- Any roll that reaches the end counts. You don't need the exact number.
- A player who reaches the end sits out for the rest of the match and watches.
- **A missed turn** (from Medusa's stone) skips your whole turn: no roll, no move, no space.

## Winning: trophies

When the match ends, everyone counts their trophies and the leaderboard is ranked by trophy count. Trophy counts stay secret until the ceremony.

| Achievement | Trophies |
|---|---|
| First to reach the end | 1 |
| Most gold when the match ends | 1 |
| Most minigames won (swap duels count) | 1 |

- Only the first player to reach the end gets a finishing trophy (the brief).
- If players tie for most gold or for most minigames won, they all get the trophy.
- There's no trophy for blood.
- **Tiebreaker:** among players with the same trophy count, the one with the finishing trophy ranks higher, then the one with a gold trophy, then the one with a minigame trophy.

## Blood (health)

- Everyone starts with **3 drops of blood**, and blood can't go above 3. Cthulhu starts with 4, and 4 is Cthulhu's cap.
- At 0 blood you die and go back to the start. You lose **all** your coins and come back with full blood (4 for Cthulhu). There are no checkpoints.
- Death can't be killed: Death's blood never drops below 1.

## Coins (gold)

- Coins count toward the "most gold" trophy.
- You gain and lose coins on board spaces and in duels. Cthulhu starts with 1.
- You lose all of them when you die.

## Board spaces

| Space | Effect |
|---|---|
| Coin | Gain 1 coin |
| Spikes | Lose 1 blood |
| Thief | Lose 1 coin |
| Church | Gain 1 blood (up to your cap) |
| Minigame spaces | Four spaces (The Atlas, The Archive, The Lab, The Stage), one for each group of Shot in the Dark questions. Landing on one starts a duel. See [minigames.md](minigames.md). |

- **One of every two spaces is empty** (the user's call, 2026-10-23): nothing happens when a piece lands there.
- **Half the filled spaces are minigames** (the brief), and the other half are the four quick spaces. See [board.md](board.md#space-mix).
- The four quick spaces show up about equally often, in every area of the board. The two paths of the first split are the one exception (see [board.md](board.md#first-split-graveyard-or-church)).
- **Powers fire before the space.** When Dracula or Medusa lands, the power happens first, then the space.

## Decision timers

Every decision has a time limit. When it runs out, a random valid choice is made for that player. The same timers play for a player who is away online.

| Decision | Time |
|---|---|
| Roll the die | 5 s |
| Pick a path at a split | 10 s |
| Pick an opponent and a stake (or Back, or walk away) | 20 s for all of it together |
| Pick a monster | 30 s |

## Cruelty

Players should be able to be pretty cruel to each other. The cruel moves are stealing coins and swapping places, both through duels (see [minigames.md](minigames.md)), and the powers of Dracula and Medusa.

## Ruled out

- No items and no shop.
- No toll gates and no trading coins for souls.
- No free-for-all minigames. Every minigame is a 1v1.
- No betting.
- No narrator.
- No text chat and no reactions. Watchers just watch.
- No match settings. The number of turns comes from the lobby's size, and the timer lengths are fixed.
