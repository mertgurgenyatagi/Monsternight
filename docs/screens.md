# Screens

What players see and click, from the title screen to the trophy ceremony. The user settled the board's HUD, how duels open and close, and typed names in the lobby. The rest was left to Claude.

## Title screen

The logo in front of a theater curtain, with Play, Settings, and Quit.

## Lobby

- The host opens a lobby. Players join and type a name.
- Everyone sees who's in, and each player clicks Ready.
- The host starts the match once everyone is ready. 2 to 8 players.

Online play comes last (see [roadmap.md](roadmap.md)). Until then, a **setup screen** takes the lobby's place: pick the number of players and type each name.

## Turn order roll

The players' name cards shuffle and settle into the turn order.

## Monster select

- The 8 monsters stand in a row, and the player whose pick it is clicks one.
- Monsters that are already taken are greyed out.
- Picks go in reverse turn order, 30 seconds each. When time runs out, a random monster is picked.
- From here on, each player shows in their monster's color (see [characters.md](characters.md)).

## Board

### Always on screen

- A strip of paper portraits along the top, one per player, in turn order. Each shows the player's blood drops and coin count. The active player's portrait is raised, and a player who has finished gets a flag.
- A turn counter in a corner, such as "Turn 5 of 17".
- Trophy counts and duel wins are **not** shown. They stay secret until the ceremony.

### Mouse controls

On the board, everything is a mouse click.

| Decision | What you click |
|---|---|
| Roll | The die |
| Pick a path | One of the two arrows at the signpost |
| Challenge | An opponent's portrait, then a stake card: gold, blood, or swap. Invalid stakes are greyed out. |

For every decision, a candle burns down next to the choice. When it goes out, a random valid choice is made.

### Dying

The monster crumples into a paper ball, flies back to the start, and unfolds there with full blood.

## Duels

1. A paper "VS" card slams down with both monsters' portraits and the stake.
2. A 3, 2, 1 countdown.
3. The round. In the first playable, this is a coin flip.
4. The winner does a short victory pose, the loser crumples like paper, and the coins or blood fly across to the board.

Everyone else watches.

## Trophy ceremony

The curtain opens. Trophies are handed out one at a time, then the leaderboard, then the fun stats. After that, everyone goes back to the lobby.

### Fun stats

The user left these to Claude.

| Stat | Title |
|---|---|
| Most deaths | Frequent Corpse |
| Most duels started | The Bully |
| Most times challenged | The Punching Bag |
| Most blood lost to spikes | The Pincushion |

A stat only shows if someone scored at least 1. Tied players are shown together.

## Settings

The user left these to Claude, except that the number of turns and the timer lengths are fixed.

- Music volume
- Sound effects volume (ambience and monster voices included)
- Fullscreen or windowed

Settings open from the title screen, and with Esc during a match. The match keeps running.
