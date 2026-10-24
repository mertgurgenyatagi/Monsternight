# Board

## Layout

There is one board, and it's the same every match. It's a road through classic horror locations, played from left to right:

1. Foggy village (start)
2. Graveyard, with a church on the hill above it (first split)
3. Dark forest
4. Swamp (second split)
5. Dracula's castle (the finish is the castle gate)

Each location has its own look. See [art_and_audio.md](art_and_audio.md).

## Path splits

The user accepted two splits (Q07) and left the details to Claude (Q12). At a split, one path runs higher on the screen and the other lower, and they join again afterwards.

### First split: graveyard or church

| Path | Length | Quick spaces |
|---|---|---|
| Graveyard, the low road | 8 spaces | spikes and thieves only |
| Church, over the hill | 12 spaces | churches and coins, and one minigame |

The graveyard is a gamble: it's shorter, but it hurts. The church path costs about one extra roll, but it heals and pays. This is the only place where the quick spaces aren't spread evenly.

### Second split: boardwalk or bog

Both swamp paths are 10 spaces long. Only their minigames differ:

| Path | Minigame spaces |
|---|---|
| Boardwalk, the upper path | Pong and Haxball |
| Bog, the lower path | Racing and the FPS |

The choice is about which games you'd rather duel in.

## Space mix

The user decided the board's length and mix on 2026-10-23: **one empty space for every filled one**, still one die. The layout was rolled once by `tools/board/roll_board.py` (seed 1031) and is written into `BoardPath`, so it's the same every match. Only the kinds are rolled; the stretch lengths and the forks stay fixed. Each part of the road has a bag with exact counts, shuffled with no other rule on the order, so the ratio is exact and the order is pure chance.

| Bag | Spaces | Empty | Filled |
|---|---|---|---|
| Main road: the village, forest and castle as one bag | 39 | 20 | 19: one of each minigame, and 15 quick spaces, 4 of each kind but one, which gets 3 |
| Church | 12 | 6 | 6: one minigame, and 5 churches and coins (3 and 2) |
| Graveyard | 8 | 4 | 4: 2 spikes, 2 thieves |
| Boardwalk | 10 | 5 | 5: Pong, Haxball, and 3 quick spaces of any kind |
| Bog | 10 | 5 | 5: racing, the FPS, and 3 quick spaces of any kind |

The graveyard way is 29 empty and 28 filled, and the church way 31 and 30. The sword fight gets spaces once its rules are settled. To reroll, run the script with `--seed N`.

## Length

17 turns of one die (3.5 spaces on average) is about 60 spaces, so on average about 2 players reach the end. Deaths and swaps set players back, so not everyone makes it. A match runs longer than the 30-minute target, and that's accepted. The lengths get checked in playtesting.

| Stretch | Spaces |
|---|---|
| Foggy village | 12 |
| First split | 8 or 12 |
| Dark forest | 12 |
| Second split | 10 |
| Dracula's castle | 15 |
| **Total** | **57 through the graveyard, 61 past the church** |

The board is about 15,500 px wide.

## Camera

A side view, not top-down. The camera follows whoever is rolling. See [art_and_audio.md](art_and_audio.md#camera).
