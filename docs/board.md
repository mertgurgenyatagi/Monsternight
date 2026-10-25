# Board

## Layout

The board is a road through classic horror locations, played from left to right:

1. Foggy village (start)
2. Graveyard, with a church on the hill above it (first split)
3. Dark forest
4. Swamp (second split)
5. Dracula's castle (the finish is the castle gate)

Each location has its own look. See [art_and_audio.md](art_and_audio.md).

The road's length comes from the lobby's size (the brief), and the kinds of its spaces are **shuffled fresh every match**, so friends who play often don't learn it by heart (Claude's call, Q18).

## Path splits

The user accepted two splits (Q07) and left the details to Claude (Q12). At a split, one path runs higher on the screen and the other lower, and they join again afterwards. **The splits are the same at every lobby size** (Claude's call, Q18).

### First split: graveyard or church

| Path | Length | Quick spaces |
|---|---|---|
| Graveyard, the low road | 8 spaces | spikes and thieves only |
| Church, over the hill | 12 spaces | churches and coins only |

The graveyard is a gamble: it's shorter, but it hurts. The church path costs about one extra roll, but it heals and pays. This is the only place where the quick spaces aren't spread evenly.

### Second split: boardwalk or bog

Both swamp paths are 10 spaces long, with the same mix. Since the spaces are shuffled every match, the choice is about the spaces you can see on each.

## Space mix

In every part of the road (the brief):

- **Half the spaces are empty.**
- **Half the filled spaces are minigames,** each one of the four question groups at random (Q18, Microplan 15). The other half are quick spaces.
- On the main road and the swamp paths, the quick spaces are the four kinds in equal numbers. The graveyard's are spikes and thieves, and the church path's are churches and coins, half and half (Claude's call, Q18).
- Each part of the road is a bag with exact counts, shuffled with no other rule on the order. When a count doesn't split evenly, the odd space goes to a random side.

## Length

The board length in the brief is the average of the shortest way (through the graveyard) and the longest (past the church). The two splits are fixed, so the village, the forest and the castle take the difference, shared out as today's 12, 12 and 15 (Claude's call, Q18):

| Players | Turns | Village | Forest | Castle | Shortest way | Longest way | Average |
|---|---|---|---|---|---|---|---|
| 3 | 20 | 14 | 14 | 17 | 63 | 67 | 65 |
| 4 | 17 | 12 | 12 | 16 | 58 | 62 | 60 |
| 5 | 15 | 11 | 11 | 13 | 53 | 57 | 55 |
| 6 | 14 | 10 | 10 | 11 | 49 | 53 | 51 |
| 7 | 13 | 9 | 9 | 10 | 46 | 50 | 48 |
| 8 | 12 | 8 | 8 | 10 | 44 | 48 | 46 |

The first playable's road is 57 or 61 spaces and about 15,500 px wide. The board's width now changes with the lobby, and the scenery has to fit every length.

## Camera

A side view, not top-down. The camera follows whoever is rolling, and in the final game it sits slightly further out and slightly higher (the brief, part 27). See [art_and_audio.md](art_and_audio.md#camera).
