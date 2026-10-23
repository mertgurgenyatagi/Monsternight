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
| Graveyard, the low road | about 6 spaces | spikes and thieves only |
| Church, over the hill | about 10 spaces | churches and coins only |

The graveyard is a gamble: it's shorter, but it hurts. The church path costs about one extra roll, but it heals and pays. This is the only place where the quick spaces aren't spread evenly.

### Second split: boardwalk or bog

Both swamp paths are about 7 spaces long and have the usual quick spaces. Only their minigames differ:

| Path | Minigame spaces |
|---|---|
| Boardwalk, the upper path | Pong and Haxball |
| Bog, the lower path | Racing and the FPS |

The choice is about which games you'd rather duel in.

## Space mix

- Roughly 3 quick spaces for every 2 minigame spaces, on every stretch.
- Coin, spikes, thief, and church show up about equally often everywhere except the first split.
- Outside the second split, the minigame spaces are shared evenly between Pong, Haxball, racing, and the FPS. The sword fight gets spaces once its rules are settled.

## Length

These are starting numbers. They get tuned in playtesting so that on average 2 players reach the end in 12 turns.

| Stretch | Spaces |
|---|---|
| Foggy village | 9 |
| First split | 6 or 10 |
| Dark forest | 9 |
| Second split | 7 |
| Dracula's castle | 11 |
| **Total** | **42 through the graveyard, 46 past the church** |

Twelve rolls of one die average 42 spaces. Deaths and swaps set players back, so not everyone makes it.

## Camera

A side view, not top-down. The camera follows whoever is rolling. See [art_and_audio.md](art_and_audio.md#camera).
