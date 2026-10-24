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

All three stay in part 6's **side view**. The high camera was tried and reverted (see README), so don't bring it back. Part 16 gives `Duel.play(challenger, opponent, stake) -> {winner, loser}`; parts 17 and 18 start from there.

### Part 16: The VS card, the countdown and the coin flip

**Goal:** After the challenge, a paper VS card slams down with both monsters and the stake, a 3, 2, 1 counts down, and a coin flip decides the winner, who is announced. Nothing changes on the board yet (part 17 applies the result).

**Builds:**
- **`Duel`** (`src/board/duel.gd`), a node on its own `CanvasLayer` above the HUD (layer 30), with an awaitable `play(challenger, opponent, stake) -> Dictionary` giving `{winner, loser}` (the player dictionaries). `Board.land`'s minigame branch awaits it right after the confirm beat and replaces the log line. It logs "Duel won by X (coin flip)".
- **The flip is one function, `Duel._decide(challenger, opponent, stake)`,** returning the winner at random with `randf()`. Part 18 changes only this for the swap handicap. A minigame later replaces it as a whole.
- **A dim and a hold.** The board keeps running under a dimmed backdrop (a black `ColorRect` fading to 0.55), the camera stays put. The HUD stays visible above the dim for the portraits, below the card layer.
- **The music.** `Sound.play_music("duel")` while the duel plays, and `Board._follow_leader()` puts the board track back when it ends. The file `duel.ogg` is missing, so it's silence for now.

**Polish:**
- **The VS card:** two `card.png` cards, scale about 0.9, one for each monster, slam in from the sides and tilt a few degrees toward each other with `card_slam` (one slam each, 0.15 s apart). Each shows the monster's `portrait` over the card, its name from `Translations` in `display.ttf` and in the monster's `color`. A big paper "VS" (`display.ttf`, cream with a dark rim) drops between them with a third `card_slam` and a small screen shake (the `PaperMotion.shake` on the layer's root, 6 px).
- **The stake** sits under the VS: the icon (`coin`, `blood` or `swap`) on a small paper strip with its line ("Take 1 coin"), popping in with `pop_in`. The challenger's card is marked with a small "challenger" tag (new string) and sits left.
- **The idle:** both cards `breathe` gently, and the portraits blink as they do on the HUD, if `HudPortrait` already does something similar to copy (look, don't invent).
- **The countdown:** the cards slide apart and the card pair shrinks a bit, then a huge 3, 2, 1 in `display.ttf` pops at the center, each with `countdown` and a squash that settles within 0.8 s, then the number tears away. "Go" is not shown as a word; `countdown_go` plays as the coin leaves.
- **The coin flip:** the `coin.png` is flicked up from between the cards with `coin_flip`, spins (a fast `scale.x` squash cycle to fake the flip), slows, and lands with a bounce. One face shows the challenger's color rim and the other the opponent's (a tint, no new art). The coin comes to rest on the winner's side, and the pause before the result is 0.4 s so it feels like suspense.
- **The announcement:** the winner's card lifts, grows and gets a `Glow.flare`; the loser's card greys with `grey.gdshader` and tips back. A short paper banner "X wins!" drops in, held 1.2 s. Then the cards lift away with `lift_away` and the dim fades.
- **Skip nothing:** no key skips it; the whole thing is about 8 s.

**Assets:** `ui/card.png`, `coin.png`, the icons, the monsters' portraits, `sfx/card_slam`, `countdown`, `countdown_go`, `coin_flip`, `flip`. **Missing:** `duel.ogg`, which the user makes (silence for now).

**Check:**
- With a temporary script (not committed): run `Duel.play` for 4 monster pairs with each stake, check the cards fit (the longest name, Frankenstein's, and the longest stake line) and that both of the winners get picked over 40 runs.
- Run the full path with the MCP's clicks, 3 players: land on a minigame space, pick an opponent and a stake, and watch the VS card come after the confirm beat; the next player's turn starts after the banner.
- One contact sheet of the slam, the countdown, the flip and the announcement. 25 FPS.

**Risks:** the HUD and the card layer both draw portraits; make sure the cards cover nothing but the dim. The flip's fake spin must read as a coin at a glance.

### Part 17: Duel results

**Goal:** The result of a duel really happens: the winner poses, the loser crumples, and the coins, blood or places move across the board. A duel can kill, and the dead respawn.

**Builds:**
- **`Match.duel_result(winner, loser, challenger, stake) -> Dictionary`:** the rules. Gold: 1 coin from the loser to the winner if the challenger won; if the challenger lost, the challenger pays 1 coin to the opponent. Blood: the loser of the duel loses 1 blood. Swap: only when the challenger won, `space` of both swap; if the challenger lost, nothing. It returns `{coins, blood, swapped, died}` with real changes through `change_coins`/`change_blood`, and also counts `duels_won` for the winner (part 19's stats read it; keep `duels_started` and `challenged` counters too, bumped here).
- **`Board.duel_end(winner, loser, ...)`**, a coroutine awaited after `Duel.play`, doing the visible half. A death goes through `Board.die` (part 13) so the death and respawn are the ones the user already saw. The challenger's turn then ends.
- **Voices:** `voices/<monster>_win` and `_lose` from `Monsters` (`voice` key; look at how the pick voice is read).
- **The swap:** the two pieces trade places with the new `swap` motion, a shared `PaperMotion` helper if none fits (arcs that cross over each other).
- **Stat counters** in `Match`: `duels_won`, `duels_started`, `challenged` (the spikes' blood count for the "Pincushion" stat doesn't exist yet; part 19 adds it).

**Polish:**
- **The win pose:** the winner's piece squashes, grows 15%, and does a small jump with `hop`, `tilt`, and its `_win` voice; a `Glow.flare` under it. The loser's piece `crumple`s with its `_lose` voice and `crumple`, then unfolds back (the non-freeing crumple from part 13, then `unfold`) unless it dies.
- **Gold:** the coin flies from the loser's HUD counter to the winner's on the HUD layer (the flyers the coin space already uses), with `coin_lose` on the loser's side and `coin_gain` on landing. Both counts tick.
- **Blood:** a drop breaks off the loser's HUD portrait with `blood_lose`, the portrait shakes; a challenger-lose in a blood duel drops the challenger's drop the same way. A death is a `Board.die`, whose camera and flight run in full.
- **Swap:** the camera glides to the middle of the two pieces, both lift, `swap` plays, they cross in arcs and set down; the camera follows the challenger to their new space. The crowd slots are re-run so crowded spaces line up. Nobody gets a space effect from a swap.
- Winning a duel on the move gives no extra move. The challenger's space effect is the duel; afterwards the turn passes on.
- **The camera:** during gold and blood it holds on the challenger's piece; the HUD does the work.

**Assets:** `voices/*_win`, `*_lose`, `sfx/crumple`, `respawn`, `fly`, `swap`, `coin_lose`, `coin_gain`, `blood_lose`, `blood_gain`. Nothing missing.

**Check:**
- A temporary script that forces every combination (stake × challenger wins or loses) and checks the `Match` numbers and the HUD agree. A death match (blood on 1 blood, 0 coins) kills the loser, and the challenger with 1 blood who loses dies too.
- A swap on crowded spaces, on a fork's two paths, and with the start; a swap across the church (graveyard way vs past it) is allowed since the token ids are all that move.
- A sped-up 8-player match that forces duels on every minigame landing for 17 turns must end with consistent totals and no errors.
- One contact sheet of the win pose, a coin flying, a blood drop and a swap. 25 FPS.

**Risks:** a swap between pieces thousands of pixels apart shouldn't whip the camera: fly the pieces, not the camera (the camera glides to the middle and then to the challenger, like the death's flight). A duel death while the winner sits in the same spot as the respawn must still line up.

### Part 18: The swap handicap and finishing at the gate

**Goal:** A swap duel is the rigged 3-to-1 it should be, and players really can finish: reaching the castle gate gives the flag, the sting, and a seat on the sidelines.

**Builds:**
- **The swap handicap.** `Duel._decide` runs rounds. For a swap the challenger needs 3 round wins before the opponent wins 1; gold and blood stay at one round. It returns `{winner, loser}` as before, plus the rounds. The coin flip is fair, so the challenger wins a swap 1 time in 8. That's what the rule says; the playtest in part 23 can judge it.
- **The rounds on screen.** For a swap the card pair keeps a small tally under the VS: three empty pips for the challenger, one for the opponent. Each flip is a quicker repeat (no VS slam, a shortened countdown at 1 s a number), and each pip fills with a tick. The flip stops at the first decisive result.
- **Finishing.** The walk (`Board._walk`) stops at the gate when the steps reach it. `Match.finish(player) -> int` sets `finished`, remembers the order in a `finish_order` (the first gets the trophy in part 19), and returns the place. `Board.finish(player)` is the coroutine: the piece hops onto the gate, then the gate and flag moments in Polish play.
- **The sit-out.** A finished player's piece stays at the gate in a row of onlookers (their own slots by finish order, standing a little to the right of the gate), `set_finished` on the HUD (flag) and `next_player` skips them. A finished player isn't a duel target (part 15 already enforces it) and can't die (part 13).
- **The edge cases.** A roll that overshoots the gate counts (any roll that reaches the end). Overshooting steps are lost. If the finishing roll was on a fork's path, that's fine since the route ends at the gate anyway. If this is the last unfinished player but one, part 19 ends the match; for now the match just carries on with the one left until turn 17.

**Polish:**
- **The gate:** when the first (or any) piece arrives, the gate doors `castle_gate.png` swing open slightly (a squash/stretch on a lit slot) with a warm `Glow.flare`, `sting_finish` plays once, and `Sound.play_music` ducks for its 3 s then comes back.
- **The flag:** the piece plants a flag (`flag.png`, the one already used by the HUD): it pops in over the piece with a sway, and the HUD portrait greys with the flag as part 9 built it. The camera holds on the gate for 2 s, then the next player.
- **A place tag:** a small paper tag "1st", "2nd" ... pops over the piece for 2 s (from `Translations`; new strings), so finishing order reads. The first finisher's tag is gold (the 2-trophy finish, from part 19), the others plain.
- **The onlookers:** each finished piece `breathe`s and sways slowly, and they face the board. `PaperMotion.sway` has the motion for it.
- **The pips of the handicap:** fill with `ui_click` (high pitch if the challenger took it, dull for the opponent); three pips for the challenger drop into the tally with `pop_in`.

**Assets:** `scenery/castle_gate.png`, `icons/flag.png`, `sfx/ui_click`, `countdown`, `coin_flip`, `card_slam`, `sting_finish`. **Missing:** `sting_finish.ogg` (music the user makes), so the code plays it by name and it is silent for now; the ducking is then untested by ear.

**Check:**
- Force a roll to the gate from 1, 3 and 6 spaces away (overshoot too), from the church path and from the main lane. `Match.finish` order is right; `next_player` skips the finished; the sped-up 8-player match keeps running to turn 17 with some finished.
- Run 200 handicap rounds in a script: the challenger should win a swap about 12.5% of the time, and gold/blood about 50%.
- One contact sheet of the tally, the gate opening and the flag, three onlookers standing. 25 FPS.

**Risks:** pieces at the gate share the end of the road with the castle's scenery and the signpost; check the onlookers' row doesn't hide the doors. A finished player who held the lead is also the leader for the music (part 13 already counts them furthest).

## Roadmap

Rough past part 18. Parts 1 to 15 are done (see the Log and the part notes).

13. Death and respawn, and the board music following the leader.
14. Splits: the signpost's arrows with a 10 s candle.
15. Challenge: the opponent's portrait, then the stake card, with the 20 s candle and the coin fallback.
16. The VS card, the countdown, and the coin flip.
17. Duel results: the win pose and the crumple, voices, gold and blood flying across, deaths in duels (using part 13's `Board.die`), and the swap.
18. The swap handicap (3 rounds) and finishing at the castle gate (the flag, `sting_finish`, the onlookers). The no-opponent fallback was already done in part 15.
19. Match end: 17 turns, `sting_final_turn`, the early end, and tracking the stats (the spikes' blood count is new; the duel counters come from part 17).
20. The trophy ceremony: the curtain, drumrolls, trophies, and the leaderboard with its tiebreaker.
21. Fun stats, then back to the setup screen.
22. Esc settings during a match, and a sweep of translations and edge cases. This includes what parts 2 and 3 left untested: a fullscreen relaunch, closing Settings with Esc, a click outside or the back button, and dragging the sliders.
23. Full playtests and tuning: the 17 turns and the 57 spaces, and a reroll of the board if the user wants one.
24. Bug bash and the final polish pass. Drop the Godot MCP's autoloads from the release build.

## Part notes

Each part session adds a few lines when it finishes: what got built, what changed from the plan, surprises, and anything left over or buggy. The next Microplan reads these instead of the code.

### Built so far (parts 1 to 16, absorbed by Microplans 3 to 6)

- **Board (parts 10, 11, 12):**
  - The road is 57 spaces through the graveyard and 61 past the church (12, 8 or 12, 12, 10, 15), 15,460 px wide, rolled by `tools/board/roll_board.py` with seed 1031. `Match.TURNS` is 17, the intro glide 7.5 s. `BoardLayout.hill_width()` (2,840) stretches the church hill, and `scenery.gd`'s `_spots(location, first, last, gap)` keeps the props' density.
  - `Match` has `current`, `active()`, `roll()`, `next_player()`, a `finished` flag on every player, and `land(player)`, which returns `{kind, coins, blood}` with the real changes.
  - `Die` (`src/board/die.gd`: `place`, `offer`, `nudge`, `tumble`, `leave`, `clicked`) and the turn loop in `Board._play_turns`. The die sits `DIE_RISE` (300 px) over the piece, 34 px higher per extra crowd row; the half-size candle is to its right. A timed-out roll shakes the die for 0.25 s first.
  - `Board.land(player, id)` is a coroutine: it wakes the space (`Space.wake` / `rest`) and plays the effect (coin, spikes, thief, church) with flyers on the HUD's layer, after waiting for the camera to settle. The spikes and the thief's hand are a stand-in copy in a `Front` node over the pieces. minigame spaces log "Duel here, part 15".
- **Death and the music (part 13):**
  - `Match.die(player)` zeroes coins, refills blood, moves the player to the start, counts `deaths` and returns `{coins, blood}` (nothing for a finished player). Every move stamps `arrived`, and `Match.leader()` is the furthest along by the node's x (a finished player is furthest, a tie goes to the earliest `arrived`).
  - `Board.die(player)` is the coroutine, and `land` awaits it after spikes. Part 17 calls it for a duel death. It runs `Match.die`, then `PaperMotion.crumple(piece, 0.5, false)`, `BoardPiece.fold(true)` (the ball, `crumpled.png`, 96 px), the coins spilling (up to 5) with the HUD count jumping to 0 in one tick, a 150 px rise, the toss to the start's crowd slot, a bounce, `fold(false)` and `unfold`, a `Glow` flare on the start, the blood refilling 0.2 s apart, and a 1.2 s hold. About 4.7 s from a far death.
  - The flight takes 1.2 s (no distance) to 2.0 s (the whole board). **The camera does not `follow` the ball:** the cap of 2,600 px/s would lose a ball flying 7,500 px/s, so `glide_to` takes the same time with the same sine easing as `PaperMotion.toss`, which keeps the ball in the middle of the screen. At the peak the scenery scrolls about 11,000 px/s.
  - `Board._follow_leader()` picks `board_<location of the leader>` (graveyard covers the church, swamp covers the boardwalk and the bog) after every walk and death and when the pieces have landed, and logs "Music: ...". The tracks don't exist yet, so it plays silence.
  - There is no `unfold` sound in `assets/`, so the unfolding plays `respawn` alone.
- **Splits (part 14):**
  - `BranchChoice` (`src/board/branch_choice.gd`, in Lanes after `Front`): `ask(fork, path_view)` gives the chosen id. Two `arrow.png` options float in the sky at (+260, -470) and (+260, -340) from the fork's token, not on the road, because the church's first space and icon filled every spot near the signpost. Each has the stretch's name (`STRETCH_*` keys in `strings.csv`) and up to 4 icons of that path, most common first, read from `BoardPath`. The 10 s half-size candle floats over the pieces at (-60, -230).
  - `BoardPathView.light_path(lit, dimmed)` and `clear_light()` fade the lit path's spaces, dots and strip up and the other's down. `nudge_signpost(fork)` swings the post when a piece lands on it. `Board.choose_branch` keeps its signature; `_choose` glides the camera 330 px past the fork, then `follow`s the piece again.
  - A timeout shakes both arrows, lights a random one for 0.55 s, then drops the other. Checked: 8 players, 11 forks sped up, both paths taken at both forks, routes still 57, 57, 61, 61; an MCP click beside the arrows did nothing and one on the lower arrow chose it. The 25 FPS bar read 19 in a plain run with the editor open.

- **Challenge (part 15):**
  - `Match.opponents(player)` and `Match.stakes(challenger, opponent)` ("gold", "blood", "swap") are the rules. `Challenge` (`src/board/challenge.gd`, a child of `Hud`, screen coordinates) has `ask(challenger)`, giving `{opponent, stake}`, or `{}` with nobody to duel. `Board.land` awaits it for a minigame space and logs "Duel here, part 16: A vs B, stake gold"; with `{}` it gives 1 coin through the coin effect. Part 16 starts from that log line.
  - `Hud` has `set_pickable(players)`, `clear_pickable()`, `set_lit(player, on)`, `shake(players)`, `portrait_at(player)` and the `portrait_clicked` signal. `HudPortrait` carries an `Area2D` over its frame, with `picked` and `denied` signals.
  - The banner sits at y 272, the 20 s candle (scale 0.4) right of it, and the cards (scale 0.47) at y 600 under the chosen portrait, clamped 330 px from the screen's sides. Checked: MCP clicks on a greyed portrait and card did nothing, then a valid one chose; 24 sped-up timeout runs with 5 players were all valid (gold, blood and swap all seen); the coin fallback worked. FPS read 15 in a plain run with the editor open.
  - The confirm beat is 0.6 s after the candle lifts away. There is no VS card yet, so the result is only logged.
- **The VS card (part 16):**
  - `Duel` (`src/board/duel.gd`, `CanvasLayer` 30, a child of `Board`) has `play(challenger, opponent, stake)` giving `{winner, loser}`, and `_decide(challenger, opponent, stake)`, the fair `randf()` coin flip that part 18 changes. `Board.land` awaits it after the confirm beat, then resets `_track_name` and calls `_follow_leader()`. It logs "Duel won by X (coin flip)". The dim is a `ColorRect` on its own layer 15, under the HUD (20), so the portraits stay bright. The music is `Sound.play_music("duel")` (the file is missing, so silence).
  - It runs about 9.5 s: the cards slam (scale 0.9, 310 px each side of x 960, y 470), the VS drops with a 6 px jolt, the stake strip pops in at y 810 and holds 0.9 s, then the cards part to 520 px and shrink to 0.7, 3, 2, 1 pop at the center (0.74 s each), the coin is flicked and spins by squashing its width (12 half turns end on the challenger's color, 11 on the opponent's) and lands 170 px to the winner's side, then the winner's card lifts with a `Glow.flare`, the loser's greys with `grey.gdshader` and tips, and the banner "X wins!" holds 1.6 s. `HudPortrait` has no blink, so the cards only `breathe`.
  - New strings `DUEL_VS`, `DUEL_CHALLENGER` and `DUEL_WINS`. A Label's `size` springs back to its text's width, so `_label` clips its text (`clip_text`) and sets the size last. Checked: a forced duel on the board with MCP clicks on the opponent's portrait and a stake card (Bob chosen, the VS came after the confirm beat, the turn code carried on), 40 flips gave 18 challenger wins, and the screenshots show the longest name ("Frankenstein's Monster") fits.
- **Code** is in `src/`:
  - Autoloads: `Sound` (`play`, `play_music`, `play_ambience`, and `quit()`, which every way out of the game goes through so no OGG leaks; `play("hop")` never repeats a hop twice in a row), `Scenes` (`change_to`, the paper transition, the texture and the cursor), `Settings` (`Settings.open()` from anywhere), and `Match` (players in turn order, each with `name`, `monster`, `space`, `blood`, `coins` and `finished`; `turn`, `TURNS`, `MAX_BLOOD`; `roll_turn_order`, `pick_monster`, `free_monsters`, `move_to`, and `change_blood` / `change_coins`, which return the real change).
  - `PaperMotion` holds `drop_in`, `set_down`, `lift_away`, `sway`, `sway_stop`, `pop_in`, `pop_out`, `lift` (it only raises), `squash`, `slide_in`, `move_to`, `flip`, `hop`, `hop_to`, `fly_to`, `tuck`, `breathe`, `tilt`, `shake`, `stretch`, `crumple` (it frees the piece at the end unless `free` is off), `unfold`, `toss` and `bounce`. New motion goes here.
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
- **2026-10-24, Microplan 6:** parts 13 to 15 are done (death and the music, splits, challenge). Planned parts 16 to 18: the VS card with the countdown and coin flip, the duel results, and the swap handicap with finishing at the gate. Roadmap changes:
  - The no-opponent fallback left part 18, because part 15 already built it.
  - The duel counters (`duels_won`, `duels_started`, `challenged`) are kept from part 17, so part 19's stats don't have to hunt for them. The end stays at 24.
