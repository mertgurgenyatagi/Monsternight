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
- **Shot in the Dark keeps the paper look**: a paper card, paper number boxes and a paper keypad.

## Frame rate

The whole game runs at **25 FPS**, so every movement steps like stop motion on paper. The user chose this on 2026-10-23.

## Monsters

- Each monster is one cutout on a small paper stand, like a board game piece.
- They **hop** from space to space, like a game piece being picked up and set down.
- They **flip like a card** when they turn around.
- Each monster's color shows on it and around its portrait (see [characters.md](characters.md)).

## Scenery

- **Layers of paper** slide past at different speeds as the camera moves, which gives depth.
- The scenery is built from separate cutouts (houses, trees, gravestones) placed in the engine, not one big painting, so the board can change length during tuning.
- The game draws the sky as a gradient, tinted for each location, with a paper moon and stars.

## Camera

- A side view of the board, not a full top-down view.
- The camera follows whoever is rolling.
- In the final game it sits slightly further out and slightly higher (the brief), and the scenery must still read as one real place. Part 27 did it: zoom 0.88 (`BoardCamera.ZOOM`) and a slightly higher horizon.

## Audio

The user picked the instruments and left the rest to Claude (Q13).

- **Organ and theremin.**
- **One main melody,** the Monsternight theme, runs through all the music. Every track is a version of it.
- **The board music follows the leader.** Each location has its own version of the theme, and the one that plays is wherever the leading player is, so the music moves from the village to the castle as the race goes on. Following the camera would switch tracks every turn. The board tracks share one tempo and key, so they crossfade cleanly.
- **Ambience follows the camera:** wind, crows, owls, frogs, and thunder, quietly under the music.
- Shot in the Dark has its own sounds; its music loop (`shot`) comes with the user's music files.
- **Every action has a sound:** the die, each hop, flips, each kind of space, duels, the timer countdown.
- **Each monster has three sounds:** when it's picked, when it wins, and when it loses. They're laughs, howls, and hisses with no words, so nothing needs translating.
- No narrator.

## Assets

Real assets are used from the start, with no placeholder shapes. Claude lists everything needed in [assets.md](assets.md), and the user gets it.
