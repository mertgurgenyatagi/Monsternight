# Microplan

The [first playable](roadmap.md#1-first-playable), built in about 24 parts. `/microplan` plans three parts at a time in detail, and a rough roadmap to the end (see `.claude/skills/microplan/SKILL.md`). It runs in its own session, after part 3, 6, 9 and so on.

## Building a part

One part per session, on its own branch from `development`. A part session reads `README.md`, this file, and only the docs and code its part touches.

A part is done when:

1. It runs in Godot with no errors or warnings.
2. Everything in its Polish list is in: animated, with its sounds, nothing glossed over.
3. Claude has checked it by running the game, not just by reading the code.
4. Three screenshots of the finished part, taken from the running game, are saved in `screenshots/part_NN/` (like `part_01/`) as `1.png`, `2.png` and `3.png`. Pick the three moments that show the part best.
5. Its Part notes are written. The branch is committed, pushed and merged into `development`, and `development` is pushed. Then check out `development`, so the next session starts there. The part session never waits for the user: it does the whole cycle, and the user reviews afterwards and asks for changes in a later session. This needs no git approval (see README, Handover 3).
6. The session disconnects from the Godot MCP, so the next one gets its port (see README, Handover 5).

If a part turns out too big, split it (7a, 7b) instead of rushing it.

## Parts

All three stay in part 6's **side view**. The high camera was tried and reverted (see README), so don't bring it back.

### Part 10: The longer, random board

**Goal:** The road is 57 spaces through the graveyard and 61 past the church, half of them empty, and the filled ones fall in an order with no pattern. The layout was rolled once by a script and is written into `BoardPath`, so it's the same every match. A match is 17 turns. The scenery stretches to fit, and nothing looks thinned out.

**The user's decisions (2026-10-23):** 57 spaces on the shortest way, the graveyard way. One empty space for every filled one (1:1, replacing both the 2:1 of part 7 and the 1.5:1 noted in the README). Still one die. 17 turns, so that about 2 players reach the end (57 ÷ 3.5 ≈ 16.3 rolls, plus a little room for deaths and swaps). Matches run longer than the 30-minute target; that's accepted.

**Builds:**
- **The stretch lengths** (in `BoardLayout.LOCATIONS` and `BoardPath.STRETCHES`). The church still costs about one extra roll:

  | Stretch | Spaces |
  |---|---|
  | Village | 12 |
  | Graveyard (lower) or church (upper) | 8 or 12 |
  | Forest | 12 |
  | Boardwalk (upper) or bog (lower) | 10 |
  | Castle | 15 |
  | **Total** | **57 through the graveyard, 61 past the church** |

- **What is rolled, and what isn't.** Only the kinds of the spaces are rolled. The stretch lengths, the forks and their places stay as above: the forks belong to the graveyard and the swamp art, so they can't move. Claude's choice.
- **The bags.** Each part of the road gets a bag with exact counts, and the roll shuffles it, uniformly, with no other rules on the order (no "never two alike in a row", no spacing). So the ratio is exact and the order is pure chance.

  | Bag | Spaces | Empty | Filled |
  |---|---|---|---|
  | Main road: the village, forest and castle as one bag | 39 | 20 | 19: one of each minigame, and 15 quick spaces, 4 of each kind but one, which gets 3 (rolled) |
  | Church | 12 | 6 | 6: one minigame (rolled), and 5 churches and coins (3 and 2, which way rolled) |
  | Graveyard | 8 | 4 | 4: 2 spikes, 2 thieves. No minigame, as now |
  | Boardwalk | 10 | 5 | 5: Pong, Haxball, and 3 quick spaces of any kind (rolled) |
  | Bog | 10 | 5 | 5: racing, the FPS, and 3 quick spaces of any kind (rolled) |

  The graveyard way is 29 empty and 28 filled, and the church way 31 and 30: as near 1:1 as an odd count allows. The whole board is 40 empty and 39 filled. The main road is one bag, so one stretch may come out richer than another; that's the randomness the user asked for. The graveyard way has 6 minigame spaces in 57, about the same share as now (4 in 42), so duels don't make the longer match longer still.
- **The roll script:** `tools/board/roll_board.py`, Python with only the standard library. It fills the bags, shuffles them with a seed, and writes the `kinds` strings into `board_path.gd`'s `STRETCHES`, changing nothing else in the file. It prints the seed and each stretch's kinds. The same seed always gives the same board, and `--seed N` rerolls. Run it once, commit the result, and note the seed in `BoardPath`'s comment and in the README's Layout list. The game never rolls the board at runtime, so online play needs no syncing.
- **`BoardPath`:** fix the doubled sentence in `STRETCHES`' comment, and say that `kinds` is rolled by the script, not written by hand. Nothing else changes.
- **The church hill:** 12 church spaces need about 2,840 px, and `church_hill.png` is 2,400 px wide. Stretch the hill sprite sideways to fit (about 1.18) and work its width out from the church count, not `HILL_WIDTH`'s fixed 2,400. `church_x` and the tombstones follow it. Keep its height, so the plateau stays at `HILL_TOP_Y`.
- **The scenery:** `scenery.gd` places props at fixed fractions of each location (`for at in [0.2, 0.44, …]`), so wider locations would thin out. Add spots so each location keeps about the props per 1,000 px it has now, through the layout code, never by hand. No prop in front of a token, and the swamp's reeds still behind the bog's tokens.
- **The board's length:** about 15,500 px, up from 11,720. The intro glide goes from 6 s to about 7.5 s, so its speed barely changes. Judge it by eye.
- **`Match.TURNS`** becomes 17. The HUD's counter and its red last turn already read it.
- **The docs:** update `board.md` (the length table, the space mix, the rolled layout), `game_rules.md` (17 turns, one empty space for every filled one), `screens.md` ("Turn 5 of 17") and `roadmap.md` (17 turns), so they match the code. They mention the user's decision and its date.

**Polish:**
- Nothing new moves. Check that the spaces, the breathing icons, the dots and the signposts all still look as they did, now on a longer road.
- The stretched hill must still look like paper, not like a smeared picture. If it does, compare 1.18 sideways with a uniform scale in one contact sheet before choosing.

**Assets:** what parts 6 and 7 already use. Nothing missing, and no new sounds.

**Check:**
- In the log, print `BoardPath.report()`, both route lengths (57 and 61), each route's empty and filled counts, and the seed.
- Run the script twice with the seed and check `board_path.gd` doesn't change. Check in a script that every bag's counts came out exact.
- Walk every route in a script from the start to the finish, as in part 7.
- With a temporary script (not committed), walk 4 players with random rolls until all reach the finish, as in part 8, and check that `Match` agrees with every piece.
- Save one screenshot of each location, including the whole church hill and both swamp paths. No space on the soil or water, no prop over a token, no bare stretch of scenery.
- 25 FPS during the intro glide.

**Risks:**
- A shuffle can give a long run of empty spaces, or three spikes in a row. That's allowed: it's what "absolutely random" means. If the user wants a reroll after seeing it, rerun with a new seed.
- The castle gets 15 spaces in 3,300 px, and the gate and its lead-out must still fit after the last one. Look at the castle's end.

### Part 11: The die and the turn loop

**Goal:** The game plays itself through: on each turn, the camera glides to the player, their portrait drops, a paper die lands above their monster, and the candle burns. Click the die, or let the candle go out, and the die tumbles, lands, and the monster hops that many spaces. Then the next player goes, and after the last player the turn counter flips, up to turn 17.

**Builds:**
- **`Match`:**
  - `current`, the index of the active player, and `active()`.
  - `roll() -> int`, 1 to 6. The rules decide the number; the die only shows it.
  - `next_player() -> bool` moves to the next player who hasn't finished, and to the next turn after the last one. It returns false when turn 17 is over. Give each player `finished` (false) now, so the skip is there; part 18 sets it.
- **`Die`** (`src/board/die.gd`): the six `die_N.png` faces on one sprite, with `PaperShadow`, and a click area. `offer()` drops it in and makes it clickable, and it emits `clicked`. `tumble(value) -> Signal` plays the roll and ends on that face.
- **Where the die goes:** in the world, above the active piece's head, in a node over `Pieces`, so it's always on screen with the player. On the upper lane it must stay below the HUD's 220 px. The `Candle` stands beside it, scaled down to about half, because its full 400 px is the pregame's size.
- **The turn loop** in `Board`, after the HUD has come in:
  1. The camera glides to the active piece. The HUD's `set_active` and the `turn_start` chime come as it settles.
  2. The die is offered, and the candle starts at 5 s.
  3. A click on the die, or `timed_out`, gives `Match.roll()`, and the die tumbles to it.
  4. `walk(player, value)`.
  5. `land(player, id) -> Signal`, a hook that part 12 fills. For now it does nothing and returns at once. Mark it clearly.
  6. `Match.next_player()`. On a new turn, the HUD's `set_turn`. When it returns false, the loop stops and logs "Match over". The ending is part 19's.
- **Clicks:** only the die takes clicks during a turn, and only while it's offered. A click elsewhere does nothing. The intro's skip click must not also roll.

**Polish:**
- **The die arrives** with `drop_in` from above the screen, lands with a small squash, then idles: a slow bob and a slight wobble, out of step with the piece's sway, so it asks to be clicked.
- **Hovering** lifts it a little and grows it, like a `PaperButton`, with the cursor changing the same way.
- **The roll:** a quick crouch, then a toss up in a short arc, spinning. Its face changes every other frame to a random face, never the same twice in a row, with `die_roll`. It lands with `die_land`, gives two small bounces with squashes, and settles straight on the number. The face gives one small pop so the number reads.
- It holds about 0.5 s so everyone sees the number, then pops out as the piece takes its first hop.
- **The candle** lights as the die lands. A click snuffs it (`stop()`), and it lifts away. Its low warning and its going out are already in `Candle`. On a timeout, the die gives a small shake, then rolls by itself, so it's clear nobody clicked.
- **Between players:** a beat of about 0.4 s after the piece lands, then the camera glides on. It never snaps.
- **A new turn:** the counter flips (part 9), after the last player's piece has landed and before the first player's glide.

**Assets:** `board/die_1.png` to `die_6.png`; `ui/candle.png` and `flame.png`; `sfx/die_roll`, `die_land` and `turn_start`, and the candle's `timer_low` and `timer_out`. Nothing missing.

**Check:**
- With the MCP's clicks, roll a few turns by clicking the die, with 2 players. Check that a click on the HUD and a click beside the die do nothing (part 9 left this unchecked).
- With a temporary script (not committed) that speeds the game up (`Engine.time_scale`), let the candles run out through all 17 turns with 8 players. In the log, every roll, where each piece stops, and the turn number; check that `Match` agrees, that the loop stops after turn 17, and that a player forced to `finished` is skipped.
- One contact sheet of the die's arrival, tumble and landing from timed screenshots.
- 25 FPS with 8 pieces, the die and the candle.

**Risks:**
- On a crowded space, the die must sit above the back row's heads. Check with 8 players on the start.
- At half size, the candle's flame may look too small. Judge it in a screenshot next to the die.

### Part 12: Quick spaces

**Goal:** Landing on a coin, spikes, thief or church space does what it says, and you see it happen: the space springs to life, and the coin or blood flies to or from the player's portrait. Empty spaces do nothing. Minigame spaces wait for part 15.

**Builds:**
- **`Match.land(player) -> Dictionary`:** the rules for the space the player stands on, through `change_coins` and `change_blood`: coin +1 coin, spikes −1 blood, thief −1 coin, church +1 blood. It returns the kind and the real changes, so a thief on 0 coins or a church on 3 blood changes nothing.
- **`Board.land`** (part 11's hook) calls it, plays the effect for the kind, then tells the HUD (`show_coins`, `show_blood`) as the flying piece arrives. It returns when the effect is done.
- **Flying to the HUD:** the flying icon is a copy that lives on the HUD's layer. It starts at the space's screen position (from the camera) and aims at `Hud.anchor(player, …)`. The space's own icon stays where it is.
- **Empty spaces:** nothing, at once. **Minigame spaces:** nothing yet; log "duel here, part 15".
- **0 blood:** spikes can take the last drop. Call a `died(player)` hook, which only logs for now; part 13 makes the death. Until then the player plays on at 0.

**Polish:**
- **Every filled space** reacts to the piece landing: its icon jumps a little, before its own effect.
- **Coin:** a coin springs up from the token, spins like a flipped coin (its x-scale squeezing through 0) and glints, then flies in an arc to the coin counter with `fly`, shrinking to the counter's size. On arrival the count ticks up with `coin_gain` (part 9).
- **Spikes:** the spikes shoot up out of the token, stretching up fast with an overshoot, with `spikes`. The piece jolts up and shakes. The HUD's drop falls off with `blood_lose` (part 9). The spikes sink back slowly.
- **Thief:** the hand darts up with `thief`. If the player has a coin, a coin flies down from their counter into the hand (the count ticks down with `coin_lose`), and the hand closes on it with a squash and ducks back into the token. With no coins, the hand grabs at the air, wiggles, and sinks back empty, with no coin sound.
- **Church:** `church` rings, and the token's warm `Glow` flares. A blood drop rises from the church icon and flies to the portrait, where the empty outline fills with `blood_gain`. On full blood the bell and the glow still come, and the drop rises above the piece and fades instead of flying.
- The camera holds on the piece during the effect. The whole effect is about 1.2 s, then the next player.

**Assets:** `icons/coin`, `spikes`, `thief`, `church` and `blood` (with the `_rim` versions on the tokens); `sfx/coin_gain`, `coin_lose`, `spikes`, `thief`, `church`, `fly`, `blood_lose` and `blood_gain`. Nothing missing.

**Check:**
- With a temporary script (not committed), land a player on each kind, and on the edge cases: a thief on 0 coins, a church on 3 blood, spikes on 1 blood (the `died` hook logs). Check that `Match` and the HUD agree after each.
- One contact sheet of each of the four effects from timed screenshots.
- A sped-up 17-turn match with 5 players, as in part 11, with the effects in.
- 25 FPS during the coin's flight.

**Risks:** The flight starts in the world and ends on the HUD, which don't move together. If the camera is still easing when the icon leaves, the start can jump. Take the start position once, when the icon leaves the token.

## Roadmap

Rough past part 12. Parts 1 to 9 are done (see the Log).

10. The longer, random board: 57 and 61 spaces, one empty for every filled one, rolled once by a script, the stretched hill, 17 turns.
11. The die and the turn loop: the die above the piece, the 5 s candle, rolling, walking, and moving on to the next player and turn.
12. Quick spaces: coin, spikes, thief and church, with their effects, sounds, and icons flying to and from the HUD.
13. Death and respawn (crumple, fly to the start, unfold, coins lost), filling part 12's `died` hook, and the board music following the leader.
14. Splits: signpost arrows and the 10 s candle, replacing part 8's random placeholder.
15. Challenge: pick an opponent's portrait, then a stake card, with invalid stakes greyed out and the 20 s candle.
16. The VS card, the countdown, and the coin flip.
17. Duel results: the win pose and the crumple, voices, gold and blood flying across, deaths in duels, and the swap.
18. The swap handicap (3 rounds), the no-opponent fallback, and finishing at the castle gate (the flag and `sting_finish`).
19. Match end: 17 turns, `sting_final_turn`, the early end, and tracking the stats.
20. The trophy ceremony: the curtain, drumrolls, trophies, and the leaderboard with its tiebreaker.
21. Fun stats, then back to the setup screen.
22. Esc settings during a match, and a sweep of translations and edge cases. This includes what parts 2 and 3 left untested: a fullscreen relaunch, closing Settings with Esc, a click outside or the back button, and dragging the sliders.
23. Full playtests and tuning: the 17 turns and the 57 spaces, and a reroll of the board if the user wants one.
24. Bug bash and the final polish pass. Drop the Godot MCP's autoloads from the release build.

## Part notes

Each part session adds a few lines when it finishes: what got built, what changed from the plan, surprises, and anything left over or buggy. The next Microplan reads these instead of the code.

### Part 10 notes

- **Built:** the road is 57 spaces through the graveyard and 61 past the church (12, 8 or 12, 12, 10, 15). `tools/board/roll_board.py` rolled the kinds with seed 1031 and wrote them into `BoardPath`; running it twice leaves the file unchanged, and it asserts every bag's counts. The graveyard way is 29 empty and 28 filled, and the church way 31 and 30. `Match.TURNS` is 17, and the intro glide 7.5 s. The board is 15,460 px wide.
- **Hill and scenery:** `BoardLayout.hill_width()` (2,840) replaces `HILL_WIDTH`, and the hill sprite is stretched sideways by `hill_width() / HILL_IMAGE_WIDTH` (1.18). It still looks like paper, so no uniform-scale comparison was needed. `scenery.gd`'s `_spots(location, first, last, gap)` places props about a fixed gap apart, so every location keeps its old density.
- **Checked:** every route walked in a script (57, 57, 61, 61 spaces), and 4 players with random rolls all reached the finish in 20 rounds with `Match` and every piece agreeing. 25 FPS during the intro glide. One screenshot of each location was looked at.
- **Left over:** the forest has six empty spaces in a row (its spaces 6 to 11), which the rules allow. If the user dislikes it, rerun with `--seed N`. The castle's own building stands at 0.4 of its length as before, and between it and the gate there are only torches.

### Part 11 notes

- **Built:** `Match` has `current`, `active()`, `roll()`, `next_player()` and a `finished` flag on every player. `Die` (`src/board/die.gd`: `place`, `offer`, `nudge`, `tumble`, `leave`, and the `clicked` signal) and the turn loop in `Board._play_turns`. `Board.land(player, id)` is the hook for part 12 (marked PLACEHOLDER; it returns the next frame). The die sits `DIE_RISE` (300 px) over the piece, and 34 px higher per extra crowd row. The candle is at half size, to its right, and lifts away on a click.
- **Checked:** with 8 players at 12x speed and one forced to `finished`, all 17 turns ran, the finished player never rolled, and the loop logged "Match over" after turn 17. With 2 players, MCP clicks beside the die and on the HUD did nothing, and a click on the die snuffed the candle and rolled. The intro skip click doesn't roll. 25 FPS with 8 pieces, the die and the candle (dips only while screenshots were being saved). Screenshots are in `screenshots/part_11/`.
- **Surprises:** the MCP's click coordinates are the window's (1920 × 1080 in the editor's run), not 1280 × 720 as the README says. A timed-out roll shakes the die for 0.25 s first.
- **Left over:** nobody has listened to the die sounds or judged the tumble by eye in motion.

### Built so far (parts 1 to 9, absorbed by Microplans 3 and 4)

- **Code** is in `src/`:
  - Autoloads: `Sound` (`play`, `play_music`, `play_ambience`, and `quit()`, which every way out of the game goes through so no OGG leaks; `play("hop")` never repeats a hop twice in a row), `Scenes` (`change_to`, the paper transition, the texture and the cursor), `Settings` (`Settings.open()` from anywhere), and `Match` (players in turn order, each with `name`, `monster`, `space`, `blood` and `coins`; `turn`, `TURNS`, `MAX_BLOOD`; `roll_turn_order`, `pick_monster`, `free_monsters`, `move_to`, and `change_blood` / `change_coins`, which return the real change).
  - `PaperMotion` holds `drop_in`, `set_down`, `lift_away`, `sway`, `sway_stop`, `pop_in`, `pop_out`, `lift` (it only raises), `squash`, `slide_in`, `move_to`, `flip`, `hop`, `hop_to`, `fly_to`, `tuck`, `breathe`, `tilt`, `shake` and `crumple`. New motion goes here.
  - Shadows: `PaperShadow.add(piece)`, which copies a sprite's region.
  - `Sky` has `tint()` and `flash()`. `bat.gd` flies across whatever is in view and has an `active` switch.
  - `src/ui/` has `PaperButton`, `PaperSlider`, `PaperToggle`, the `Candle` (`start`, `stop`, `timed_out`, `time_left`; 120 × 400) and `Flame` (`sputter`, `snuff`, `light`).
  - `src/data/`: `Monsters` is the one place for a monster's look (`name_key`, `color`, `body`, `portrait`, `voice`), and `MonsterFigure` is the body on its stand with shadows, shared by monster select's `MonsterPiece` and the board's `BoardPiece`.
  - `src/pregame/`: the turn order roll and monster select in one scene, `PlayerCard`, and `MonsterPiece` with `grey.gdshader`.
  - `src/board/`:
    - The board scene with the intro glide (`INTRO_GLIDE`, a click skips it) and location tracking. `Board` has `hud()`, `piece_for`, `walk`, the placeholder `choose_branch`, crowds, and the arrival drop, which fires `pieces_landed`; the HUD comes in then.
    - `BoardLayout` (locations, `lane_y`, `gate_x`, `layer_x`; lanes at `MAIN_Y` 880, `UPPER_Y` 650, `LOWER_Y` 930) and `BoardPath` (`node`, `start`, `finish`, `next`, `is_fork`, `ids`, `stretch`, `routes`, `report`; kinds from the `kinds` strings, `.` is `empty`).
    - `BoardPathView` (`path_view.gd`: the dark road strip, the dots, signposts, spaces and the flag), `Space`, `Flag` (also on the HUD), `BoardCamera` (`glide_to`, `jump_to`, `follow`, `stop`, `center_x`), `BoardPiece` (sway, `walked` and `branch_chosen`), `scenery.gd` (`DIM`, `FOG`), `strip.gdshader` and `Glow`.
    - `Hud` (a `CanvasLayer` at layer 20: `come_in`, `set_active`, `set_finished`, `set_turn`, `show_blood`, `show_coins`, `anchor`) and `HudPortrait`.
- **The board's layers:** Far (scroll 0.5), Mid (0.9), Lanes (1.0) and Fog (1.2). A piece in a scrolled layer goes at `BoardLayout.layer_x(world_x, scroll)`. The path and the y-sorted `Pieces` node are in Lanes, after the scenery.
- **Sizes:** a token is 165 × 73 px, with 220 px between spaces and three dots in each gap. Icons are about 108 px. Monsters are 182 px tall on a 66 px stand. Crowds stand 4 to a row, 52 px apart, each row behind 34 px higher. The HUD's portraits are 184 px apart and end at about y 215; the turn tag is top-left, 172 × 52 px.
- **Walking:** each hop is a 0.07 s crouch, a 0.27 s arc, a squash and a 0.12 s beat. `Match.move_to` is called at the end of the walk, then the camera glides onto the piece. `follow` eases in over 0.7 s and is capped at 2,600 px/s.
- **Outlines** are baked, never shaded: `tools/images/make_outlines.py` makes the token's and stand's dark rims and the icons' and monsters' cream rims (`*_rim.png`). A canvas shader came out darker and without an outline.
- **Gotchas:**
  - A Control's `scale` can't be exactly zero (Godot clamps it to 1e-5), so use a flag, never `scale == Vector2.ZERO`.
  - `--quit-after` runs print a harmless leak of 4 objects at exit, because the window's close request can't be caught there.
  - Run on its own, the pregame starts a test match of the count after `--` (default 4).
  - `grey.gdshader` drops a sprite's tint, so a finished portrait's frame is greyed by a blend instead.
- **Testing:** the Godot MCP is required (see README). Screenshots come from the viewport in a plain run, never `--write-movie`.
- **Still open:**
  - No thunder sound and no music at all yet. `select.ogg` and the board tracks are missing, and the music just fades.
  - Nobody has listened to the ambience crossfades, the pick voices, the hop sounds or the HUD's sounds, or judged the squashes and the HUD's animations.
  - In monster select, the candle sits over the moon on the right. On the right of an 8-player HUD strip, the moon sits behind a couple of coin counts; the outlines keep them readable.
  - What parts 2 and 3 left untested is on the roadmap's part 22. The MCP's autoloads must be dropped from the release build, in part 24.

## Log

- **2026-10-23, Microplan 1:** planned parts 1 to 3: the foundation and title, settings, and setup. Sketched the roadmap to part 24.
- **2026-10-23, Microplan 2:** parts 1 to 3 are done (the foundation and title, settings, and setup). Planned parts 4 to 6: the turn order roll and the candle, monster select, and the board's scenery. Roadmap changes:
  - The turn order roll and monster select now share one pregame scene.
  - "Ambience follows the camera" moved from the old part 14 into part 6, where the camera and the locations are built. The rest of the old part 14, the music following the leader, is too small for a part of its own, so it joined part 12.
  - The end moved from 24 to 23.
- **2026-10-23, Microplan 3:** parts 4 to 6 are done (the turn order roll and the candle, monster select, and the board's scenery). The high-camera design adjustment was tried and reverted, so the side view stands. Planned parts 7 to 9: the board path, monster pieces, and the HUD. The user chose spaces that lie flat on the ground as ovals, with their icons standing up on them. Roadmap changes:
  - Part 7 also retunes the lane heights, carried over from part 6, and adds the start token and the finish.
  - Part 8 now does the walking, with a random placeholder at forks that part 13 replaces. `flip` for turning pieces around is dropped from part 8, because nothing in the first playable turns a piece around yet.
  - Blood, coins and the turn number go into `Match` in part 9, with the HUD that shows them. The HUD also gets the finished flag now, which part 17 only calls.
  - The end stays at 23.
- **2026-10-23, Microplan 4:** parts 7 to 9 are done (the board path, monster pieces, and the HUD). The user decided the board: 57 spaces on the graveyard way (61 past the church), one empty space for every filled one, still one die, and 17 turns instead of 12 so that about 2 players still finish. Planned parts 10 to 12: the longer, random board, the die and the turn loop, and the quick spaces. Roadmap changes:
  - A new part 10 lengthens the board and rolls its kinds once with a script, with exact counts in each bag and no rule on the order. The stretch lengths and the forks stay fixed. Part 22's length tuning moved up into it; the playtests (now part 23) only check it.
  - The die and the turn loop, the quick spaces, and everything after them move down one. Part 12 leaves a `died` hook, which part 13 fills with the death.
  - The end moved from 23 to 24, for the new part 10.
