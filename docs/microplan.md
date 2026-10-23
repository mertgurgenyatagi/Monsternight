# Microplan

The [first playable](roadmap.md#1-first-playable), built in about 23 parts. `/microplan` plans three parts at a time in detail, and a rough roadmap to the end (see `.claude/skills/microplan/SKILL.md`). It runs in its own session, after part 3, 6, 9 and so on.

## Building a part

One part per session, on its own branch from `development`. A part session reads `README.md`, this file, and only the docs and code its part touches.

A part is done when:

1. It runs in Godot with no errors or warnings.
2. Everything in its Polish list is in: animated, with its sounds, nothing glossed over.
3. Claude has checked it by running the game, not just by reading the code.
4. Three screenshots of the finished part, taken from the running game, are saved in `screenshots/part_NN/` (like `part_01/`) as `1.png`, `2.png` and `3.png`. Pick the three moments that show the part best.
5. Its Part notes are written. The branch is committed, pushed and merged into `development`, and `development` is pushed. Then check out `development`, so the next session starts there. The part session never waits for the user: it does the whole cycle, and the user reviews afterwards and asks for changes in a later session. This needs no git approval (see README, Handover 3).

If a part turns out too big, split it (5a, 5b) instead of rushing it.

## Parts

### Part 4: Turn order roll and the timer candle

**Goal:** Begin on the setup screen leads to the turn order roll. The players' name cards flip face down, shuffle like a deck, deal out in a row, and flip face up one by one to reveal the turn order. The reusable timer candle is built and proven on its own, ready for every decision from part 5 on.

**Builds:**
- **One pregame scene, `src/pregame/`,** for the turn order roll now and monster select in part 5 (Claude's choice: the cards that settle into the turn order stay on screen and become the pickers' cards, with no scene change between). Setup's Begin now goes here through `Scenes.change_to`.
- **`Match.roll_turn_order()`.** It shuffles `players` into turn order, so the array order *is* the turn order from here on. The rules code decides the order first, and the animation only shows it.
- **`PlayerCard`** (`src/pregame/player_card.gd`): a read-only paper card from `card.png` with the player's name, a big turn number in the display font, and a blank back for face down. It's built so part 5 can add the monster's portrait and color. It reuses the look of setup's `name_card.gd`, which is editable and stays separate.
- **`PaperMotion.flip(piece, at_middle: Callable)`:** squeezes `scale.x` to 0, calls `at_middle` to swap the face, and opens again. Monsters turning around in part 8 use it too.
- **The candle, `src/ui/candle.gd`,** one reusable timer for every decision:
  - `start(seconds)`, `stop()`, signal `timed_out`, and `time_left`.
  - `candle.png` burns down from the top as time runs out: shrink it from its base, don't squash the whole picture.
  - `flame.png` sits on the wick and rides down with it.
  - It doesn't pause while Settings is open, because the match keeps running.
- **Leaving the turn order:** after the reveal, a short beat, then the cards shrink and rise into a strip along the top in turn order. Part 5's monster row drops in below them. Until then the scene stops there and prints `Match` to the log.

**Polish:**
- The cards drop in face up in seating order, as setup left them. They flip face down one after another (`flip`, a quick ripple from left to right), then gather into a stack in the middle.
- **The shuffle:** a few quick passes where cards lift out of the stack in small arcs and tuck back in at another height, each with a soft `flip` at low volume. About 2 s in all, never a blur.
- **The deal:** the cards fly out of the stack one at a time to their places in the row, each landing with a quiet `card_slam` and a tiny settle.
- **The reveal:** the cards flip face up from first to last, with a gap between them. Each shows its name and turn number, which pops in a moment after the flip.
- The first player's card gives a small hop when it lands face up, so the player who moves first is clear.
- The rising into the top strip is one smooth, staggered move, not all at once.
- **The candle's flame** flickers all the time with small, uneven scale and tilt changes, stepping at 25 FPS like everything else.
- In the last 3 seconds the flame sputters harder and `timer_low` plays once.
- At zero the flame shrinks to nothing and `timer_out` plays.
- **Relighting:** the candle springs back to full height with a little overshoot, and the flame pops back on.
- `title.ogg` carries on through the turn order roll.

**Assets:** `ui/card.png`, `candle.png` and `flame.png`; `sfx/flip`, `card_slam`, `timer_low` and `timer_out`. Nothing missing.

**Check:**
- Run the roll with 2, 5 and 8 players, and confirm in the log that `Match.players` is in the order the cards show.
- Make one contact sheet with `capture.py` (a short run) for the flip, shuffle and deal.
- Run the candle in a small test scene for 5 s: it burns down, sputters at 3 s, goes out, fires `timed_out`, and relights.
- **Carried over from part 3:** prove one real path with the MCP's simulated input. Type a name with the keyboard on the setup screen, click Begin, and see the roll start.

**Risks:** Eight cards in one row at the top must still leave the names readable. Use two rows of four if they don't fit, as setup does.

### Part 5: Monster select

**Goal:** After the turn order, the 8 monsters stand in a row on their paper stands. Players pick in reverse turn order, each against a 30 s candle. Taken monsters grey out, every pick plays the monster's voice, and each player's card takes on their monster's portrait and color.

**Builds:**
- **`Monsters` data** (`src/data/monsters.gd`): the 8 monsters in the order of characters.md, each with an id, a translated name key (`MONSTER_DRACULA` and so on), its color, and the paths to its body, portrait and three voices. Sample the colors from the art, so the tint agrees with the drawing. From here on, everything that needs a monster's look reads it from this one file.
- **`Match`:** each player gets a `monster` id, set through one rules call (`Match.pick_monster(player, id)`) that refuses a monster that's already taken. Also add `Match.free_monsters()`.
- **The monster row** in the pregame scene, below the cards. Each monster is a `Sprite2D` on `stand.png`, with `PaperShadow`. The row fits all 8 across 1920 px, at about 300 px tall.
- **The pick loop:**
  1. Picks go from the last player in the turn order to the first.
  2. The picker's card lifts out of the strip.
  3. A prompt in the body font appears under the strip, like "Ayşe, pick your monster", with the candle beside it on 30 s.
  4. The player clicks a free monster. If time runs out, a random free monster is picked instead.
- **The last monster** (Claude's choice): with 8 players, the last picker has only one monster left. It's picked for them automatically after a short beat, with no candle.
- **`PaperMotion.hop(piece)`:** a lift-and-set-down with squash. Part 8's moving pieces reuse it.
- **After the last pick:** a beat, then the board. Until part 6 builds it, the scene stops there and prints `Match` with the monsters.

**Polish:**
- The monsters drop in one after another, from left to right, once the cards have settled in the strip. Then each sways gently, out of step with the others.
- **Hovering a free monster:**
  - It lifts with `ui_hover`.
  - Its name fades in under it, in the display font and in its color.
  - Moving away lowers it again and fades the name.
- **Picking:**
  - The monster hops, and its `<name>_pick` voice plays.
  - Its portrait flies up from the row to the picker's card and lands there with `card_slam`.
  - The card's border tints in the monster's color, and the card settles back into the strip.
- **A taken monster:**
  - It greys out and darkens over about 0.3 s, and stops swaying.
  - The picker's name stays under it in plain ink.
  - Hovering it does nothing. Clicking it plays `ui_denied` and shakes it.
- **The candle** relights for each new picker. When time runs out, the flame goes out with `timer_out`, then the random pick plays exactly like a click, voice included.
- **The prompt** swaps between pickers with a small flip, never a hard cut.
- The music switches to `select.ogg` as the monsters drop in. It's missing, so `title.ogg` fades out.

**Assets:** all 16 monster images in `monsters/`, `monsters/stand.png`, `ui/card.png`, `candle.png` and `flame.png`; all 24 voices, though only the 8 `_pick` voices play here; `sfx/ui_hover`, `ui_denied`, `card_slam`, `timer_low` and `timer_out`; `music/select.ogg` (missing, and fine to be missing).

**Check:**
- Do a full select with 2 players and with 8, including the automatic last pick.
- Let one candle run out, and see that the random pick takes only a free monster.
- Click a taken monster.
- Confirm the monsters in `Match` match the cards.
- Use one contact sheet for a pick, and real MCP clicks for one pick and one denied click.

**Risks:** The pick voices differ in loudness. If one stands out, fix it in `process_sounds.py` and don't add a volume table in code.

### Part 6: The board's scenery

**Goal:** After monster select, the board appears: five paper locations side by side, with layers sliding past at different speeds. The camera glides once from the castle gate back to the village start. As it crosses each location, the sky tint and the ambience change with it, and everything is gently alive.

**Builds:**
- **`src/board/board.tscn`.** Monster select now leads here.
- **The board's layout data** (`src/board/board_layout.gd`): each location's x range, worked out from board.md's space counts at about 220 px a space. The first split spans about the width of `church_hill.png` (about 2400 px). It also sets the heights of the lanes: the main road, the upper lanes (church hill and boardwalk), and the lower lanes (graveyard and bog). Everything must fit in one 1080-tall view. Part 7 puts the spaces on these lanes, so nothing in the scenery is placed by hand where the path will go.
- **The sky:** the existing `Sky` stays fixed to the screen, on a canvas layer behind everything.
- **The layers,** as `Parallax2D` layers from back to front:
  1. The far strips, scrolling slowly.
  2. The mid props: houses, trees, the church and the castle.
  3. The ground strips and the lane level, at full speed.
  4. A thin layer of foreground fog, a little faster than the camera.
- **Locations meeting:** neighbouring far and ground strips overlap and fade into each other. A tall prop stands on each seam.
- **`Camera2D`** with limits at the board's ends, and a `glide_to(x)` that parts 8 and 10 will reuse to follow the active player.
- **The intro glide** (Claude's choice): it holds on the castle gate for a moment, then glides about 6 s to the village start, easing in and out. A click skips it. This shows everyone where the race ends.
- **Location tracking:** whenever the camera's centre moves into another location, the sky tints with `Sky.tint` and the ambience crossfades with `Sound.play_ambience`. This brings "ambience follows the camera" forward from the old part 14.
- **The props per location:**
  - **Village:** the two houses, repeated with a flipped copy for variety, and the lamps.
  - **Graveyard:** stones, trees, the church hill, and the church on top.
  - **Forest:** both trees and the mushrooms.
  - **Swamp:** the water, the boardwalk on the upper lane, cypresses, and reeds.
  - **Castle:** the castle on its cliff, the torches, and `castle_gate.png` at the very end.

**Polish:**
- Fog strips drift slowly sideways and loop seamlessly. They're thick in the village and swamp, and thin wisps in the graveyard.
- Village lamps glow with a soft radial glow, made in the engine with a `GradientTexture2D` and additive blending. The glow flickers now and then.
- Castle torches each carry a `flame.png` that flickers like the candle's flame. Reuse its flicker code, don't copy it.
- The forest mushrooms pulse with a faint glow.
- The swamp water bobs slowly up and down and drifts a little.
- Trees and reeds sway very slightly from their base, out of step with each other.
- Bats flap across now and then over the graveyard and the castle. Reuse `bat.gd`, adapted to fly through the world rather than the screen if it needs to be.
- At the castle, lightning flashes the sky now and then, with `Sky.flash()`, as on the title.
- **Sky tints** (Claude picks the exact colors, colorful and never bleak):
  - **Village:** misty violet-blue.
  - **Graveyard:** green-violet.
  - **Forest:** deep teal.
  - **Swamp:** sickly olive-green.
  - **Castle:** blood red and purple.
- Ambience fades in under the board as it appears, and the title music fades out.
- Every prop gets `PaperShadow`.

**Assets:**
- Every image in `scenery/`, plus `ui/flame.png`.
- `ambience/village`, `graveyard`, `forest`, `swamp` and `castle`.
- The board music is missing and isn't needed until part 12.

**Check:**
- Run the intro glide and make one `capture.py` contact sheet.
- Then move the camera to each location in a script, and save one screenshot of each from the viewport. Use three of them for `screenshots/part_06/`.
- Check that the sky tint and the ambience switch at every boundary, in the log.
- Watch for seams in the tiled strips, and for frame drops with all five locations loaded.

**Risks:**
- This is the biggest part so far. If it runs long, split it:
  - **6a:** the layers, the camera, the layout data, the village and the graveyard.
  - **6b:** the forest, the swamp, the castle, and the intro glide.
- The lane heights are a first guess, and part 7 may move them. Keep every prop's position tied to `board_layout.gd`, so moving a lane doesn't mean moving props by hand.

## Roadmap

Rough past part 6. Parts 1 to 3 are done (see the Log).

4. Turn order roll and the timer candle.
5. Monster select.
6. The board's scenery, with ambience following the camera.
7. The board path: spaces built from `board_layout.gd`, icons, path dots, both splits, signposts, and the castle gate as the finish.
8. Monster pieces: the stand, the shadow, `hop` and `flip`, and the camera following the active player.
9. The HUD: the portrait strip with blood and coins, the raised active portrait, and the turn counter.
10. The die and the turn loop: roll, move, `turn_start`, and the 5 s candle.
11. Quick spaces: coin, spikes, thief and church, with icons flying to the HUD.
12. Death and respawn (crumple, fly to the start, unfold), and the board music following the leader.
13. Splits: signpost arrows and the 10 s candle.
14. Challenge: pick an opponent, then a stake card, with invalid stakes greyed out and the 20 s candle.
15. The VS card, the countdown, and the coin flip.
16. Duel results: the win pose and the crumple, voices, gold and blood flying across, deaths in duels, and the swap.
17. The swap handicap (3 rounds), the no-opponent fallback, and finishing at the castle gate (the flag and `sting_finish`).
18. Match end: 12 turns, `sting_final_turn`, the early end, and tracking the stats.
19. The trophy ceremony: the curtain, drumrolls, trophies, and the leaderboard with its tiebreaker.
20. Fun stats, then back to the setup screen.
21. Esc settings during a match, and a sweep of translations and edge cases. This includes what parts 2 and 3 left untested: a fullscreen relaunch, closing Settings with Esc, a click outside or the back button, and dragging the sliders.
22. Full playtests and tuning: the board's length and the 12 turns.
23. Bug bash and the final polish pass. Drop the Godot MCP's autoloads from the release build.

## Part notes

Each part session adds a few lines when it finishes: what got built, what changed from the plan, surprises, and anything left over or buggy. The next Microplan reads these instead of the code.

### Part 6 notes

- **Built:** `src/board/`:
  - `board.tscn` and `board.gd`: the intro glide from the castle gate (a click skips it), and location tracking (`Sky.tint`, `Sound.play_ambience`, bats, and lightning over the castle). The pregame now ends with `Scenes.change_to` the board.
  - `board_layout.gd` (`BoardLayout`): `locations()`, `location_at(x)`, `width()`, `gate_x()`, `lane_y(Lane.MAIN / UPPER / LOWER, x)`, and `layer_x(x, scroll)`. The world runs from 0 to 11,720 px: the village is 0 to 2,480 (with a 500 px lead-in), the graveyard is the hill's 2,400, the forest 1,980, the swamp 1,540, and the castle 3,320 (with 900 px for the gate). The lanes: the road at y 900, upper 640, lower 990. A split's paths ease away from the road over its `ramp` (600 px up the hill, 220 in the swamp).
  - `board_camera.gd` (`BoardCamera`): `glide_to(x, duration)` (by default it takes longer the further it goes), `jump_to(x)`, and `center_x()`.
  - `scenery.gd` places every strip and prop from the layout. `strip.gdshader` tiles a strip, fades its ends, and drifts fog and water. `glow.gd` (`Glow`) is the additive radial glow, with `flicker`, `pulse` and `jitter`.
- **Layers:** Far (scroll 0.5), Mid (0.9: houses, trees, the castle), Lanes (1.0: the ground strips, hill, church, stones, lamps, mushrooms, water, boardwalk, reeds, torches and the gate) and Fog (1.2). A piece in a scrolled layer goes at `BoardLayout.layer_x(world_x, scroll)`. Part 7 should add the path to Lanes, after the ground strips, so it's under the foreground fog.
- **Changed from the plan:** the small props (lamps, stones, mushrooms, reeds, torches), the church and the hill are in the lane layer, so they don't slide against the road. The mid layer would hide behind the hill. The swamp's ground lies 110 px lower than the others, so the water shows between the boardwalk and the bog. The torches stand along the road and on either side of the gate. Fog: foreground wisps over the village, graveyard and swamp, plus a bank behind the village and swamp props; none in the forest or castle.
- **Fixed on the way:** `Sky.tint` had never worked: it bound its arguments in the wrong order. `PaperShadow` now copies a sprite's region. `bat.gd` flies across whatever is in view, under a camera too, and has an `active` switch.
- **Surprise:** an OGG still playing when the game ends is reported as 4 leaked objects. `Sound` now catches the window's close request and quits through `Sound.quit()`, which stops every player and waits two frames. Title's Quit uses it too. `--quit-after` can't be caught, so `capture.py` runs still print that leak at exit. It's harmless.
- **Checked:** a contact sheet of the intro glide; the log shows every boundary (castle, swamp, forest, graveyard, village); a steady 25 FPS during the glide; a click mid-glide skipped home in 0.9 s; one screenshot of each location. A 2-player pregame ran through to the board. Screenshots are in `screenshots/part_06/`.
- **Not done:** the Godot MCP failed to connect, so the click was pushed with `Input.parse_input_event`. I didn't listen to the ambience crossfades. The lane heights are a first guess: the lower lane at 990 runs over the ground's soil, low on the screen.

### Part 5 notes

- **Built:** `Monsters` (`src/data/monsters.gd`: ids, colors, `name_key`, `body`, `portrait`, `voice`), `Match.pick_monster` and `free_monsters` (each player has `monster`, "" until picked), `MonsterPiece` (`src/pregame/monster_piece.gd`, with `grey.gdshader`), `PlayerCard.set_monster` (framed portrait in the monster's color, via `portrait_frame.png`), `PaperMotion.sway_stop`, and the pick loop in `pregame.gd` (`_select_monsters`, `_pick_for`, `_pick`). `PaperMotion.flip` now takes any CanvasItem. The scene ends by printing `Match` with the monsters.
- **Changed from the plan:** Dorian's art is burgundy, which sits next to Dracula's red, so his color is the pink the design asks for (`#d6457f`). A taken monster's picker name is cream, not dark ink, because the sky is dark. `hop` already existed from part 4.
- **Surprise:** a Control's `scale` can't be exactly zero (Godot clamps it to 1e-5), so never test `scale == Vector2.ZERO`; use a flag.
- **Checked:** with 2 and 8 players, including the automatic last pick; a timed-out candle picked a free monster; a click on a taken monster; `Match` matched the cards. A temporary driver (deleted) pushed real mouse events into the viewport. Screenshots are in `screenshots/part_05/`.
- **Not done:** the Godot editor wasn't open, so the MCP's clicks weren't used. `select.ogg` is missing, so `title.ogg` just fades out. No volume table was needed for the voices, but I didn't listen to them. The candle sits over the moon on the right.

### Part 4 notes

- **Built:** `src/pregame/` (`pregame.tscn`, `pregame.gd`, `player_card.gd`), `Match.roll_turn_order()`, `src/ui/candle.gd` and `flame.gd`, and `src/ui/candle_test.tscn` (a 5 s burn and relight, printing to the log). Setup's Begin goes to the pregame.
- **New in `PaperMotion`:** `flip`, `hop` (part 5 reuses it, don't add it again), `fly_to` (arc, and sets the rest position and scale) and `tuck`.
- **`Flame`** is its own class (a flickering flame whose origin is its base, with `sputter`, `snuff()` and `light()`). Part 6's torches reuse it. The candle's body is a stretched plain slice of wax under a fixed cap (wick and drips), so it shrinks from its base.
- **Pregame:** it runs a step at a time in `_ready`. Run on its own, it starts a test match of the count after `--` (default 4). After the strip rises it prints `Match`. Part 5 continues from the end of `_ready`. The cards are in `_cards` (seating order), found by `_card_for(player)`, and sit in the strip at scale 0.5, y 105.
- **Checked:** 2, 5 and 8 players: the log order matched the cards. The candle burns 5 s, sputters at 3 s left, fires `timed_out`, and relights. A scripted run typed a name, clicked Begin, and reached the roll. Screenshots are in `screenshots/part_04/`.
- **Not done:** the Godot editor wasn't open, so the MCP's simulated input wasn't used. The scripted run pushed real key and mouse events instead. The candle isn't in a screenshot (it isn't used on screen until part 5). `capture.py` now passes game args after the scene.

### Built so far (parts 1 to 3, absorbed by Microplan 2)

- **Code** is in `src/`:
  - Autoloads: `Sound` (`play`, `play_music`, `play_ambience`), `Scenes` (`change_to`, the paper transition, the texture and the cursor), `Settings` (`Settings.open()` from anywhere), and `Match`.
  - `PaperMotion` holds `drop_in`, `set_down`, `lift_away`, `sway`, `pop_in`, `pop_out`, `lift`, `squash`, `slide_in`, `move_to`, `shake` and `crumple`. New motion goes here.
  - Shadows: `PaperShadow.add(piece)`.
  - `Sky` has `tint()` and `flash()`, and `bat.gd` flies across the screen.
  - `src/ui/` has `PaperButton`, `PaperSlider` and `PaperToggle`.
- **The MCP:** its simulated clicks use window coordinates (1280 × 720).
- **Screenshots** come from the viewport in a plain run. Never run `--write-movie` for long.
- **Still open:**
  - There's no thunder sound, and no music at all yet.
  - What parts 2 and 3 left untested is on the roadmap's part 21.
  - The MCP's autoloads must be dropped from the release build, in part 23.

## Log

- **2026-10-23, Microplan 1:** planned parts 1 to 3: the foundation and title, settings, and setup. Sketched the roadmap to part 24.
- **2026-10-23, Microplan 2:** parts 1 to 3 are done (the foundation and title, settings, and setup). Planned parts 4 to 6: the turn order roll and the candle, monster select, and the board's scenery. Roadmap changes:
  - The turn order roll and monster select now share one pregame scene.
  - "Ambience follows the camera" moved from the old part 14 into part 6, where the camera and the locations are built. The rest of the old part 14, the music following the leader, is too small for a part of its own, so it joined part 12.
  - The end moved from 24 to 23.
