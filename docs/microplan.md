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
7. The session's last message ends with `q7Zk#x2` as a line of its own, which the overnight automation looks for (see README, Handover 6). A Microplan session ends the same way. If the README says the process is over, the line is left out.

If a part turns out too big, split it (7a, 7b) instead of rushing it.

## Parts

All three stay in part 6's **side view**. The high camera was tried and reverted (see README), so don't bring it back.

### Part 13: Death and respawn, and the music

**Goal:** A player who loses their last drop of blood dies for real: they crumple into a paper ball, fly back to the start, and unfold there with full blood and no coins. The board music is wired to follow the leader, ready for when the tracks arrive.

**Builds:**
- **`Match.die(player) -> Dictionary`:** the rules. Coins go to 0, blood to `MAX_BLOOD`, `space` to the start, and `deaths` goes up by 1 (the stats of part 19 need it, so keep the count now). It returns the coins lost. A `finished` player can't die.
- **`Board.died(player)`** (part 12's hook) becomes a coroutine, `Board.die(player)`, that plays the death and returns when the monster stands at the start. `land` awaits it, so the next player waits. Part 17 calls the same function for a duel's death.
- **A non-freeing crumple.** `PaperMotion.crumple` frees the piece at the end. Add a `free` argument (default true) so the piece can stay alive, crumpled, and fly. `PaperMotion.unfold(piece)` is new: the reverse, with an overshoot.
- **The start crowd.** The piece leaves its old space (`_leave`/`_settle`) and joins the start's crowd on arrival (`_slot`), so a crowded start still lines up.
- **The leader and the music.** `Match.leader()` returns the player furthest along the road (a finished player counts as furthest; on a tie, the one who got there first). `Board` finds which location the leader is in and calls `Sound.play_music("board_<location>")` after every move, so the music changes when the lead does, never when the camera does. The graveyard and church share a track, and so do the boardwalk and the bog (`board_swamp`).

**Polish:**
- **The crumple:** the monster stops, folds into a paper ball with `crumple`, with the `crumple` sound.
- **Coins lost:** if the player had coins, a few small coins spill out of the ball, fall and fade, while the HUD counter drops to 0 with `coin_lose` (one tick, not one per coin).
- **The flight:** the ball rises, then flies in a high arc over the road back to the start with `fly`, spinning. The camera follows the ball (`follow`, same easing and cap as walking). The flight takes 1.2 s to 2.0 s by distance, never longer.
- **The unfolding:** the ball lands on the start token with a squash and a small bounce, then unfolds into the monster with `unfold` and `respawn`. The HUD's blood drops refill one by one with `blood_gain`. A small `Glow.flare` on the token.
- The camera holds on the start for a beat after the unfolding, then the next player.
- **The leader's track** crossfades with the existing music fade, about 3 s. Nothing happens when the leader moves within a location, or when the file doesn't exist (missing tracks make silence, not errors, as now).

**Assets:** `sfx/crumple`, `respawn`, `fly`, `coin_lose`, `blood_gain`; the pieces' art. **Missing:** the five `board_*.ogg` tracks, which the user makes. The code is written for the names in `docs/assets.md`; the part can only be checked by the log, not by ear.

**Check:**
- With a temporary script (not committed): kill a player at the castle with coins, one at the start (a short flight), and one standing on a crowded space. Check `Match` and the HUD agree afterwards, and the start's crowd lines up with 8 players there.
- A finished player can't die. Spikes on 1 blood run the whole death, then the next player's turn.
- Print `Match.leader()` and the chosen track name through a sped-up 17-turn match with 5 players; the track must only change when the lead changes location.
- One contact sheet of the crumple, the flight and the unfolding from timed screenshots. 25 FPS during the flight.

**Risks:** the flight crosses up to 15,000 px, so the camera must not whip. A crumpled piece has a small scale, so its shadow and outline must shrink with it.

### Part 14: Splits

**Goal:** At the two forks the player picks the path: a signpost shows two arrows, a 10 s candle burns, and a click sends the monster up or down. When the candle goes out, a random path is taken. This replaces part 8's random placeholder.

**Builds:**
- **`Board.choose_branch(player, fork)`** keeps its signature (an awaitable that gives the chosen id), so `_walk` doesn't change. The placeholder is removed.
- **The choice UI.** The signpost is already on the road (`signpost.png`, part 7). Two `arrow.png` buttons spring from it, one pointing up-right for the upper path and one down-right for the lower. Each has a small label with the stretch's name from `Translations` (graveyard or church, boardwalk or bog) and a few of that path's icons in a row, read from `BoardPath`'s kinds, never typed by hand.
- **The candle** at the signpost, 10 s, half size like the die's.
- **Only the arrows take clicks** while the choice is open.
- **A roll that ends exactly on the fork** doesn't ask; the choice comes with the next move, and only when the player has steps left past the fork (`BoardPath.is_fork` tells).

**Polish:**
- The signpost sways when the piece arrives, as if nudged. The arrows pop in one after the other with `pop_in`.
- **Hover** lifts and grows an arrow, like a `PaperButton`, and the path it leads to lights up: its dots and spaces fade up a little, the other path dims. This is the point of the choice, so it must read.
- **The camera** eases to the fork's center so both paths are in view, then back onto the piece after the choice. Judge by eye how far; tokens must stay readable.
- **A click:** the chosen arrow squashes with `ui_click`, the other drops away with `lift_away`, the candle is snuffed, and the piece hops along the chosen path.
- **A timeout:** the same shake as the die's, then the random pick lights up its arrow before the hop, so it's clear nobody clicked.

**Assets:** `board/signpost.png`, `arrow.png`, the icons, `ui/candle.png`, `flame.png`; `sfx/ui_click`, `ui_hover`, `timer_low`, `timer_out`. Nothing missing.

**Check:**
- With the MCP's clicks, 2 players walk through each fork, once choosing each arrow. A click beside the arrows does nothing.
- With a temporary script (not committed), let the candle run out at both forks many times, sped up; both paths must get taken.
- Walk every route in a script as before (57, 57, 61, 61), and check the 8-player sped-up 17-turn match still ends. Test a forced roll that ends on the fork.
- One contact sheet of the arrows popping in, a hover and the camera pull-back. 25 FPS.

**Risks:** the lower path (`LOWER_Y` 930) may sit under the arrows or the candle. Check both forks in a screenshot.

### Part 15: Challenge

**Goal:** Landing on a minigame space asks for a challenge: the player clicks an opponent's portrait, then a stake card, with a 20 s candle for both together. The choice is shown, and the game logs the duel (the VS card is part 16). With nobody to duel, the space acts as a coin space.

**Builds:**
- **`Match.opponents(player) -> Array`:** every other player who hasn't finished.
- **`Match.stakes(challenger, opponent) -> Array`:** the valid stakes. Gold if the opponent has a coin, blood if they have blood, swap if the two stand on different spaces. (Part 18 refines the swap.)
- **`Challenge`** (`src/board/challenge.gd`), a node on the HUD's layer, with an awaitable `ask(challenger) -> Dictionary` giving `{opponent, stake}`. A timeout picks at random from the valid ones, so it always returns.
- **`Board.land`**'s minigame branch calls it and logs "Duel here, part 16: A vs B, stake gold", handing the choice on for part 16. With no opponents it plays the coin effect instead.
- **The HUD** gets `set_pickable(players)` and `clear_pickable()`, and a `portrait_clicked(player)` signal.

**Polish:**
- **Step 1, the opponent:** a small paper banner drops in under the strip ("Pick an opponent", from `Translations`). The valid portraits bob and light their frames; hovering lifts one, a click squashes it with `ui_click`. The challenger and the finished are greyed and give `ui_denied`.
- **Step 2, the stake:** three paper cards (`card.png`) fan out under the chosen portrait: gold, blood, swap, each with its icon and a short line ("Take 1 coin", "Take 1 blood", "Swap places"). Invalid ones are greyed with `ui_denied`; valid ones lift on hover. A click slaps the card down with `card_slam` and the others fall away.
- **The candle** (20 s) at the banner's corner for both steps together, lifting away after the second click. It must not restart between steps. On a timeout it picks a valid opponent, then a valid stake, with a shake and a beat between so it's clear nobody clicked.
- **The confirm beat:** the chosen portrait and card stay lit for about 0.6 s before part 16's VS card.
- The camera stays on the piece; the HUD does the work. It must fit 8 players: cards go under the strip, never over the portraits.

**Assets:** `ui/card.png`, `portrait_frame.png`, `candle.png`, `flame.png`; `icons/coin`, `blood`, `swap`; `sfx/card_slam`, `ui_click`, `ui_denied`, `ui_hover`, `timer_low`, `timer_out`. Nothing missing.

**Check:**
- With the MCP's clicks, 3 players: force a player onto a minigame space with a temporary script, click an opponent and a stake. Clicks on greyed portraits and cards give only the denied sound.
- Edge cases through a script: an opponent with 0 coins (gold greyed), everyone else finished (coin fallback), both on the same space (swap greyed).
- Let the candle run out with 5 players many times; the random choices must always be valid.
- One contact sheet of the banner, the cards and the confirm beat, with 8 players. 25 FPS.

**Risks:** 8 portraits at 184 px leave little room for the banner and cards; check the layout at 8 players.

## Roadmap

Rough past part 15. Parts 1 to 12 are done (see the Log).

13. Death and respawn (crumple, fly to the start, unfold, coins lost), filling part 12's `died` hook, and the board music following the leader.
14. Splits: the signpost's arrows with a 10 s candle, replacing part 8's random placeholder.
15. Challenge: pick an opponent's portrait, then a stake card, with invalid stakes greyed out and the 20 s candle.
16. The VS card, the countdown, and the coin flip.
17. Duel results: the win pose and the crumple, voices, gold and blood flying across, deaths in duels (using part 13's `Board.die`), and the swap.
18. The swap handicap (3 rounds), the no-opponent fallback, and finishing at the castle gate (the flag and `sting_finish`).
19. Match end: 17 turns, `sting_final_turn`, the early end, and tracking the stats.
20. The trophy ceremony: the curtain, drumrolls, trophies, and the leaderboard with its tiebreaker.
21. Fun stats, then back to the setup screen.
22. Esc settings during a match, and a sweep of translations and edge cases. This includes what parts 2 and 3 left untested: a fullscreen relaunch, closing Settings with Esc, a click outside or the back button, and dragging the sliders.
23. Full playtests and tuning: the 17 turns and the 57 spaces, and a reroll of the board if the user wants one.
24. Bug bash and the final polish pass. Drop the Godot MCP's autoloads from the release build.

## Part notes

Each part session adds a few lines when it finishes: what got built, what changed from the plan, surprises, and anything left over or buggy. The next Microplan reads these instead of the code.

### Built so far (parts 1 to 12, absorbed by Microplans 3 to 5)

- **Board (parts 10, 11, 12):**
  - The road is 57 spaces through the graveyard and 61 past the church (12, 8 or 12, 12, 10, 15), 15,460 px wide, rolled by `tools/board/roll_board.py` with seed 1031. `Match.TURNS` is 17, the intro glide 7.5 s. `BoardLayout.hill_width()` (2,840) stretches the church hill, and `scenery.gd`'s `_spots(location, first, last, gap)` keeps the props' density.
  - `Match` has `current`, `active()`, `roll()`, `next_player()`, a `finished` flag on every player, and `land(player)`, which returns `{kind, coins, blood}` with the real changes.
  - `Die` (`src/board/die.gd`: `place`, `offer`, `nudge`, `tumble`, `leave`, `clicked`) and the turn loop in `Board._play_turns`. The die sits `DIE_RISE` (300 px) over the piece, 34 px higher per extra crowd row; the half-size candle is to its right. A timed-out roll shakes the die for 0.25 s first.
  - `Board.land(player, id)` is a coroutine: it wakes the space (`Space.wake` / `rest`) and plays the effect (coin, spikes, thief, church) with flyers on the HUD's layer, after waiting for the camera to settle. The spikes and the thief's hand are a stand-in copy in a `Front` node over the pieces. `Board.died(player)` only logs; minigame spaces log "Duel here, part 15".
- **Code** is in `src/`:
  - Autoloads: `Sound` (`play`, `play_music`, `play_ambience`, and `quit()`, which every way out of the game goes through so no OGG leaks; `play("hop")` never repeats a hop twice in a row), `Scenes` (`change_to`, the paper transition, the texture and the cursor), `Settings` (`Settings.open()` from anywhere), and `Match` (players in turn order, each with `name`, `monster`, `space`, `blood`, `coins` and `finished`; `turn`, `TURNS`, `MAX_BLOOD`; `roll_turn_order`, `pick_monster`, `free_monsters`, `move_to`, and `change_blood` / `change_coins`, which return the real change).
  - `PaperMotion` holds `drop_in`, `set_down`, `lift_away`, `sway`, `sway_stop`, `pop_in`, `pop_out`, `lift` (it only raises), `squash`, `slide_in`, `move_to`, `flip`, `hop`, `hop_to`, `fly_to`, `tuck`, `breathe`, `tilt`, `shake`, `stretch` and `crumple` (which frees the piece at the end). New motion goes here.
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
  - The MCP's click coordinates are the window's (1920 × 1080 in the editor's run), not 1280 × 720.
- **Testing:** the Godot MCP is required (see README). Screenshots come from the viewport in a plain run, never `--write-movie`. A sped-up match (`Engine.time_scale`) with a temporary script is how the turn loop gets checked.
- **Still open:**
  - No thunder sound and no music at all yet. `select.ogg` and the board tracks are missing, and the music just fades.
  - Nobody has listened to the ambience crossfades, the pick voices, the hop sounds, the HUD's sounds, the die's sounds or the quick spaces' sounds, or judged the squashes, the tumble and the effects in motion.
  - The forest has six empty spaces in a row (seed 1031); `--seed N` rerolls if the user dislikes it. The castle has only torches between its building and the gate.
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
- **2026-10-24, Microplan 5:** parts 10 to 12 are done (the longer random board, the die and the turn loop, and the quick spaces). Planned parts 13 to 15: death and respawn with the music wiring, the splits, and the challenge. Roadmap changes:
  - None in the order or the end (still 24). Part 13 adds a `deaths` count for part 19's stats and a non-freeing `crumple`, and part 17 reuses its `Board.die` for duel deaths.
  - The board music is wired in part 13 but can't be heard until the user makes the five board tracks.
