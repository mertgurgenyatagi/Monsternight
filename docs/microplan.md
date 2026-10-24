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
7. The Godot editor is closed (after the MCP server is ended), because an open editor gets in the way of the overnight automation's screen watching. A Microplan session closes it too.
8. The session's last message ends with `q7Zk#x2` as a line of its own, which the overnight automation looks for (see README, Handover 6). A Microplan session ends the same way. If the README says the process is over, the line is left out.

If a part turns out too big, split it (7a, 7b) instead of rushing it.

## Parts

The last three parts. Parts 22 and 23 are sweeps and tuning, not new features; part 24 closes the first playable. All stay in part 6's **side view**. Because they touch every scene, each ends by running the full loop (title, setup, board, ceremony, stats, setup) once.

### Part 22: Esc settings in a match, Turkish, and the untested leftovers

**Goal:** Esc opens Settings anywhere in a match without stopping it, the game can be played in Turkish, and the things parts 2 and 3 left untested are proven.

**Builds:**
- **Esc in a match:** `Settings.open()` already works from anywhere. `Board`, `Pregame`, `Ceremony` and the stats open it on Esc (one small shared helper, not copied four times). The match keeps running: no `get_tree().paused`, timers and the candle go on. Esc again, the back button or a click outside closes it. While it is open, board clicks (die, branch arrows, portraits, duel cards) must not leak through to the scene underneath: check each.
- **Turkish:** `strings.csv` gets a `tr` column for every key (the fonts cover Turkish letters). Settings gets a language toggle if it has none (check `Settings`), saved with the other settings. Long Turkish names and cards must still fit: check the longest in the HUD, the VS card, the stat titles and the ceremony stands. Plurals and "x N" lines go through the format, not code.
- **Leftovers from parts 2 and 3:** a fullscreen relaunch (the saved mode comes back), closing Settings with Esc, a click outside, and the back button, and dragging both sliders with the mouse (check the bus volume values).
- **Edge-case sweep:** a 2-player and an 8-player match through the pregame; a player who never rolls (timeouts only) for a whole turn; `Match` after `reset()` once more. Fix small things; bigger ones become a note for part 23 or 24.

**Polish:**
- **Open and close:** the overlay uses the existing paper motion (`drop_in` / `lift_away`) with `ui_click`; the dim behind it fades, never pops. Identical in every scene.
- **In-match line:** while Settings is open during a match, a small line "The night goes on" (new string, English and Turkish) sits under the title.
- **Translations:** no English string may show in Turkish mode. A temporary script lists keys with an empty `tr` cell and any `tr` text identical to the English (to review by eye).

**Assets:** none. **Missing:** all music and `sting_final_turn` (the user makes them).

**Check:**
- MCP: press Esc on the board mid-roll, click the die behind the overlay (nothing happens), close, the die still works; the same in a duel and the ceremony. One screenshot with Settings open over the board.
- Turkish: one plain run through the title, setup and a sped-up board with `TURNS` lowered (revert after); a contact sheet of four screens. 25 FPS.

**Risks:** input leaking through the overlay is the likely bug. A language change needs `TranslationServer.set_locale` and a refresh of labels already on screen: check which scenes build their text once.

### Part 23: Full playtests and tuning

**Goal:** the first playable plays well from start to finish with the real numbers, and its pace and fairness are measured rather than guessed.

**Builds:**
- **A sped-up bot match** (a temporary script, not committed, random choices through the existing timeouts): 8 players, the real 17 turns. Respect the no-long-runs rule: run in short chunks, or run the turn loop headless with animations skipped by a temporary test flag that is removed afterwards. Collect: how many finish by turn 17 (target about 2), the gold and duel spread, deaths per player, and the real match length at normal speed (estimated from average turn time).
- **Tuning from the numbers:** only these knobs, each with a one-line reason in the notes: `Match.TURNS`, the space mix in `roll_board.py` (a new seed if the forest's six empty spaces bother the user: ask), the coin and blood amounts, the timers. The user's decisions (57 and 61 spaces, one die, 17 turns, one empty for every filled one) change only if the numbers are clearly off, and then ask first.
- **Pacing trims:** list the longest dead moments (intro glide 7.5 s, a far death 4.7 s, the duel 9.5 s, the ceremony 40 s) and cut only what is clearly too long, keeping the Polish intact. Per-turn time at 8 players matters most.

**Polish:**
- **The feel pass:** run the game normally and watch for a pop, a snap or a missed beat in the walk, the die, the duel and the ceremony; fix each with existing `PaperMotion` calls. No new effects.
- **Frame rate:** read `Engine.get_frames_per_second()` on the heaviest views (8-player HUD, church hill with fog, the duel with the dim, the ceremony). Under 25: look at the cause (Glow polygons and shadow copies first).
- **Audio balance:** list the loudest and quietest sounds per bus by file peak and fix with `volume_db` in `Sound`, not the files. Untested by ear: the user judges.

**Assets:** none missing besides the music.

**Check:** the bot results as a short table in the Part notes; three screenshots of the heaviest views; no errors or warnings in any run.

**Risks:** tuning can go on forever. Stop at: about 2 of 8 finishing by turn 17 (1 to 3 is fine), no stat or trophy that nobody ever gets, and 25 FPS everywhere.

### Part 24: Bug bash and the release build

**Goal:** the first playable is done: nothing in the notes' "Still open" list is a bug, and a release build runs.

**Builds:**
- **The bug bash:** run what earlier parts logged as "not run": the board-to-setup second match, the quiet card on screen, the ending's buttons, an MCP click on Continue, and 8-player monster select. Then one real playthrough with the MCP's simulated input on a short match (`TURNS` lowered, reverted after), reading `get_editor_errors` and the output log at the end.
- **Release:** the Godot MCP's autoloads (`MCPRuntimeBridge`, `MCPInputBridge`, `MCPScreenshotBridge`) and the plugin must not ship. Do it through an export preset (exclude `addons/godot_mcp/*`, `screenshots/*`, `images_raw/*`, `audio_raw/*`, `tools/*`, `docs/*`) and a release-only override or a script that strips the three autoload lines, whichever is smaller; the development project keeps the MCP. Export a Windows build and launch it for a few seconds; check it reaches the title with no console errors. Export templates may need installing: ask the user.
- **Docs:** README Status to the finished state, `docs/roadmap.md` marks the first playable done, `docs/tech.md` gets a short "Building a release" section.

**Polish:** the window title and icon (check what `project.godot` has), `Sound.quit()` leaving no leaks in the release build, every scene starting with `Sound` and `Settings` state from the saved file.

**Assets:** the icon, if there is none, from the logo already in `assets/art/`. Nothing new made.

**Check:** the exported build starts and shows the title, setup and a few seconds of board; the MCP autoloads are not in its project; no errors in the output.

**The end:** part 24 is the last. When it is merged, the README's Status says "The first playable is done; the process is over", so later sessions do nothing and write no `q7Zk#x2` (README, Handover 6). Part 24's own last message still ends with `q7Zk#x2`.

## Roadmap

Parts 1 to 21 are done (see the Log and the part notes). The end stays at 24.

22. Esc settings in a match, Turkish, the untested leftovers from parts 2 and 3, and an edge-case sweep.
23. Full playtests with bots, tuning from the numbers, pacing and frame rate.
24. The bug bash, the release build without the MCP, and the finished docs. The process is over after it.

## Part notes

Each part session adds a few lines when it finishes: what got built, what changed from the plan, surprises, and anything left over or buggy. The next Microplan reads these instead of the code.

### Built so far (parts 1 to 21, absorbed by Microplans 3 to 8)

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
- **Duel results (part 17):**
  - `Match.duel_result(winner, loser, challenger, stake)` gives `{coins, blood, swapped, died}` and bumps `duels_started` (challenger), `challenged` (opponent) and `duels_won` (winner), which every player carries from `start`. Gold is 1 coin from the loser to the winner (real change, so a loser with 0 coins moves none), blood is 1 off the loser, a swap trades `space` through `move_to` only if the challenger won.
  - `Board.duel_end(winner, loser, challenger, stake)` is awaited by `land` after `Duel.play`. The winner's pose (`_win_pose`: voice, flare, 15% grow, hop, tilt) and the loser's (`_lose_pose`: voice, crumple, ball, unfold with `respawn`) run together, about 1.6 s. A dying loser only cries out and then goes through `die`, with the camera first gliding to them if they are the opponent. A coin flies counter to counter, a lost drop is the HUD's own (`show_blood`).
  - The swap (`_swap`) lifts both pieces 110 px, updates both crowds, and tosses them over crossing arcs (the opponent's lower) in the death's flight time, with the camera riding the challenger. The other piece crosses the screen at the middle.
  - Checked: headless every stake with each side winning, deaths for the opponent and the challenger (HUD-less numbers right), and a real turn loop with a blood duel; contact sheets of the win pose and the swap. Not done: the sped-up 17-turn 8-player run (headless timers were too slow to reach it), and no MCP click run (the runtime bridge timed out on a temporary scene). Gold and blood flights were not screenshotted at the moment of flight.
- **The handicap and the gate (part 18):**
  - `Duel._decide` rolls the flips through the static `Duel.roll_rounds(stake)`: gold and blood are one flip, a swap goes on while the challenger wins, until 3 wins or the opponent's first. `play` gives `{winner, loser, rounds}` (true = the challenger took the flip; the last decides). 20,000 runs gave the challenger 12.4% of swaps and 50% of gold and blood.
  - `DuelTally` (three pips for the challenger, one for the opponent) pops in as the cards part; each flip fills a pip with `ui_click` (pitch 1.5 for the challenger, 0.65 for the opponent). A repeat flip pops the coin out, counts "2, 1" at 0.6 speed, then flips again. I read "a shortened countdown" as two quick numbers.
  - `Match.finish(player)` gives the place and keeps `finish_order`. `Board.finish(player)` runs after a walk that ends on `BoardPath.FINISH` (the walk already stops at the gate, so an overshoot is lost for free): `GateDoors` (halves of `castle_gate.png` that narrow, over a warm light polygon, a child of the gate sprite, reached through `Scenery.doors()`), a gate flare, `Sound.sting("sting_finish")`, a flag planted on the piece (a child of it), the HUD flag, and a `PlaceTag` ("1st", gold for the first; new strings `PLACE_1` to `PLACE_8`) held 2 s. Then the piece hops to its onlooker slot (330 px right of the gate, 56 px apart, 4 to a row) and `BoardPiece.watch()` flips it to face left and sways and breathes slowly.
  - `Sound.play` has a `pitch` argument, and `Sound.sting(name, length)` ducks the Music bus by 16 dB through an `AudioEffectAmplify` of its own for `length` seconds; a missing file is silent. **Untested by ear** (the sting is missing).
  - Checked: three players finishing on their first rolls from `k15`, with the fourth carrying on (`next_player` skipped the finished); the contact sheets of the tally, the gate and the onlookers. Not run: an 8-player sped-up match to turn 17, the roll to the gate from other distances and from the church path (the walk code is the same for all), and no MCP click run. FPS read 18 to 25.
- **Match end (part 19):**
  - `Match.over()` (turn `TURNS` played out, or one or no unfinished player) and `next_player` returns false by it. `Match.results()` gives `{player, trophies, finish, gold, duels, rank, by}` best first (`by` is `{finish, gold, duels}`, the trophies of each kind, which part 20's rounds can read), and `Match.stats()` gives `{key, players, value}` for `deaths`, `duels_started`, `challenged` and the new `spike_blood` (added from `start`, counted in `Match.land`'s spikes branch only). Checked headless: a simple win, gold and duel ties, shared ranks, nobody finishing, 7 of 8 finishing, and the stats.
  - `Board._play_turns` ends through `_end_match()`. `_last_turn()` (sting, `Sky.flash`, `Hud.last_turn` squash, a red shaking `PaperBanner` "Last turn!") runs once when `Match.turn` reaches `TURNS`. `_banner(text, hold, shaky)` is the reusable paper banner (`PaperBanner`, `src/board/paper_banner.gd`) on the HUD layer at y 330. The early end shows "Everyone else is home" after the finisher's gate scene, then the end beat: `Hud.dim()`, `BoardPiece.wait()` for unfinished pieces, the music fades, the camera glides to the gate (2 s) with `_flare_gate()`, "The night is over" for 2 s, the results and stats are printed, and the scene changes to `res://src/ceremony/ceremony.tscn` if it exists, else the title.
  - `Candle.gust()` exists for the candle's sputter, but no candle is on screen at a turn change, so it never fires. `strings.csv` has only English (no Turkish column exists yet). The sting is missing, so silent. Checked in sped-up runs (3 players, `TURNS` lowered to 2; and 2 players with one finishing at once); `TURNS` is back at 17. Not run: a full 17-turn 8-player match, and no MCP click run.
- **The trophy ceremony (part 20):**
  - `Curtain` (`src/ui/curtain.gd`, `set_spread`, `move(spread, duration, delay)`) is the title's curtain lifted out, and the title uses it now. `Board._close_curtain()` drops one on layer 85 after "The night is over" (valance first, 1.3 s, a 0.6 s hold) and changes the scene itself with `change_scene_to_file`, not `Scenes.change_to`, so no paper sheet shows. `Ceremony` starts with its own curtain closed and opens it (`fly` plays as the swish; there is no `paper_swish`).
  - `Ceremony` (`src/ceremony/ceremony.gd`) reads `Match.results()`. Pieces (`BoardPiece` in a `slot` Node2D with the name and a hidden trophy count) stand in a row at y 800, finishers first by place, then the rest by rank, 175 px from the sides at most and 280 apart at most. Rounds: `duels`, `gold`, `second`, `first` (the first finisher gets two trophy copies, so a count of 2); a kind nobody won is skipped. Each round is the card (`PaperBanner` at y 270), a 3 s drumroll with the spotlight (`Glow.aim`, new) narrowing and the stands trembling 1 to 5 px, 0.3 s of silence, the winners stepping forward and lit (everyone else is dimmed to 0.6 and claps with `tilt`), the trophy popping in with a flare, spinning and flying to each winner's count 0.2 s apart. The count's `x N` shows only after the first trophy lands.
  - The leaderboard tosses the pieces into rank order, a paper panel rises with `1st Name ×3` rows (ties share a rank), rank 1 gets a flare, a crown trophy, a hop and the `_win` voice, and players with nothing are dimmed with a shrug. The "Continue" button (`CEREMONY_CONTINUE`) goes to the setup screen for now; part 21 puts the stats in between. Run alone, the scene makes a test match (`-- 8` or `-- 4 quiet`).
  - Layout: the valance covers the top 160 px, so the card and the panel sit under it. Whole ceremony about 40 s. `ceremony.ogg` is missing (silent). Strings are English only (no Turkish column yet).
  - Checked: 8 and 3 players with ties, the order of the rounds against `Match.results()` (the counts shown equal `trophies`), a real 3-player board with `TURNS` at 2 handing over (back to 17), 25 FPS in a plain run. The quiet match (nobody wins) skipped the rounds and the crown. Not run: an MCP click on the Continue button.
- **Fun stats and the return (part 21):**
  - `Match.reset()` clears players, `finish_order`, `turn`, `current`, `_arrivals` and `_turns_done`; the ceremony calls it when leaving, so `Match.names()` is empty and the setup screen opens with blank cards. Checked headless: after a reset `players` is empty, turn 1, and a new `start` gives fresh players (space `start`, `spike_blood` 0, `next_player` true).
  - After "Continue" the leaderboard lifts away and `Match.stats()` gets one card each (`_stat_card`: the title from `STAT_<KEY>_TITLE`, the holders' portraits that hop, their names, and the count-up in 0.5 s with a rising `ui_click` tick, singular lines through `STAT_<KEY>_ONE`), 2.2 s held, then `lift_away`. With no stats a single "A very quiet night" card shows. Then "Play again" (setup, through the paper sheet) and "Quit" (the title, which has its own closed curtain) leave through the ceremony's curtain closing (1.3 s, 0.6 s hold), with the music and ambience faded out.
  - Checked in a sped-up plain run (4 players; a death tie, a single holder with a count of 1, a count of 4 and 5): the cards, 25 FPS, and "Play again" changing the scene. Not run: the full board-to-setup second match, the quiet card on screen, the Turkish strings (still English only), and a screenshot of the ending's buttons.
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
- **2026-10-24, Microplan 7:** parts 16 to 18 are done (the VS card, duel results, the swap handicap and the gate). Planned parts 19 to 21: match end and the stats, the trophy ceremony, and the fun stats with the return to setup. Roadmap changes:
  - None in the order or the end (still 24). `Match.results()` and `stats()` are built in part 19 so that 20 and 21 only draw. Part 21 adds `Match.reset()`, since the autoload outlives a match.
- **2026-10-24, Microplan 8:** parts 19 to 21 are done (match end, the trophy ceremony, fun stats and the return). Planned the last three, 22 to 24: Esc settings in a match with Turkish and the untested leftovers, playtests and tuning, and the bug bash with the release build. Roadmap changes:
  - None in the order; the end stays at 24 and is now fixed. Turkish was planned in earlier parts but never done (`strings.csv` is English only), so part 22 does it in one go. Part 24 ends the process, so the README will say so afterwards.
