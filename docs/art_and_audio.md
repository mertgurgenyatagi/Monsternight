# Art and Audio

## Principles

The user's three rules for everything that gets built (Q15). The bold lines are the user's words, and the notes say how they apply.

1. **Simple objects brought to life by animations.** Each thing is one flat paper piece. The life comes from motion in the engine: hops, squash and stretch, wobble, flips, flicker. No frame-by-frame animation.
2. **Professionalism through minimalism.** Fewer pieces, each one finished. If something doesn't earn its place, leave it out.
3. **Unity of theme.** The board, the screens, the minigames, and the music all belong to the same paper night: one paper texture over everything, two fonts, one main melody.

## Visual style

- **Paper cutout.** Flat cutout characters and scenery.
- **References:** the South Park movie (closest), Paper Mario and Don't Starve (close-ish).
- **Not:** pixel art, 3D (like Coraline), silhouette shadow puppets (like Lotte Reiniger), Tearaway, or Hollow Knight.
- **Mood:** hellishly colorful and animated, never bleak. The horror is played for fun.
- The board should be full of lively Halloween animation: drifting fog, flapping bats, flickering candles and torches.
- **Minigames keep the paper look**, like Pong played with cardboard paddles and a paper ball on a painted table (Q12).

## Frame rate

The whole game runs at **25 FPS**, so every movement steps like stop motion on paper. The user chose this on 2026-10-23.

## Monsters

- Each monster is one cutout on a small paper stand, like a board game piece.
- They **hop** from space to space, like a game piece being picked up and set down.
- They **flip like a card** when they turn around.
- Each monster's color shows on it and around its portrait (see [characters.md](characters.md)).

## Scenery

- **A paper diorama.** The ground is a flat paper sheet seen from above, and everything on it (monsters, houses, trees, gravestones, lamps) is an upright cutout drawn from the front, standing on it like a pop-up book. The depth comes from these standing pieces over the flat ground.
- The scenery is built from separate cutouts (houses, trees, gravestones) placed in the engine, not one big painting, so the board can change length during tuning.
- **No sky on the board.** The high camera looks down at the ground, so there's no horizon. The sky (a gradient with a paper moon and stars) stays on the menu screens.

## Camera

The user changed the camera on 2026-10-23, after part 6, because the side view was "like looking at the horizon, almost at eye level".

- **A high camera, like League of Legends:** zoomed out and looking down at the board at a steep angle, about 55°. It's still not a full top-down view, as Q03 asked.
- The board winds across the ground, so the paths use the screen's height as well as its width.
- The camera follows whoever is rolling.

## Contrast

The user's rule from the same day: **the players and the spaces must be extremely easy to tell apart from the scenery.** It's as important as the three principles.

- **The ground is quiet:** dark, muted and low in contrast, with nothing round in it that could look like a space.
- **The spaces are loud:** thick tokens with a dark edge and a pale face, colored in strong, saturated colors.
- **The monsters are the brightest things on the board,** standing on stands in their own colors.
- **The game dims the scenery cutouts** a little, so the pieces and the spaces are always the brightest and most saturated things on the board.
- **Nothing covers them:** fog, bats and other effects never sit over a space or a piece.
- **The check:** in a greyscale screenshot of any part of the board, every space and every piece can still be found at a glance.

## Audio

The user picked the instruments and left the rest to Claude (Q13).

- **Organ and theremin.**
- **One main melody,** the Monsternight theme, runs through all the music. Every track is a version of it.
- **The board music follows the leader.** Each location has its own version of the theme, and the one that plays is wherever the leading player is, so the music moves from the village to the castle as the race goes on. Following the camera would switch tracks every turn. The board tracks share one tempo and key, so they crossfade cleanly.
- **Ambience follows the camera:** wind, crows, owls, frogs, and thunder, quietly under the music.
- **Every action has a sound:** the die, each hop, flips, each kind of space, duels, the timer candle.
- **Each monster has three sounds:** when it's picked, when it wins, and when it loses. They're laughs, howls, and hisses with no words, so nothing needs translating.
- No narrator.

## Assets

Real assets are used from the start, with no placeholder shapes. Claude lists everything needed in [assets.md](assets.md), and the user gets it.
