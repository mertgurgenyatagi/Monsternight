# Microplan

The [final game](roadmap.md#2-final-game), built in parts after the first playable's 24. The numbers go on from there. `/microplan` plans three parts at a time in detail, and a rough roadmap to the end (see `.claude/skills/microplan/SKILL.md`). It runs in its own session, after part 30, 33, 36 and so on.

- **The brief:** the user's direction for the final game is [final_game_brief.md](questionnaire_answers/final_game_brief.md), saved word for word. The design docs ([game_rules.md](game_rules.md), [board.md](board.md), [characters.md](characters.md), [minigames.md](minigames.md), [screens.md](screens.md), [tech.md](tech.md)) say what the final game is. Questionnaires ended at 18; the rest is Claude's call.
- **The code map:** the first playable's Part notes ("Built so far" in [microplan_first_playable.md](microplan_first_playable.md#part-notes)) describe the code as it stands. Read the section your part touches instead of rereading the code.

## Building a part

One part per session, on its own branch from `development`. A part session reads `README.md`, this file, and only the docs and code its part touches.

A part is done when:

1. It runs in Godot with no errors or warnings.
2. Everything in its Polish list is in: animated, with its sounds, nothing glossed over.
3. Claude has checked it by running the game, not just by reading the code.
4. Three screenshots of the finished part, taken from the running game, are saved in `screenshots/part_NN/` as `1.png`, `2.png` and `3.png`. Pick the three moments that show the part best.
5. Its Part notes are written. The branch is committed, pushed and merged into `development`, and `development` is pushed. Then check out `development`, so the next session starts there. The part session never waits for the user: it does the whole cycle, and the user reviews afterwards and asks for changes in a later session. This needs no git approval (see README, Handover 3).
6. The session disconnects from the Godot MCP, so the next one gets its port (see README, Handover 5).
7. The Godot editor is closed (after the MCP server is ended), because an open editor gets in the way of the overnight automation's screen watching. A Microplan session closes it too.
8. The session's last message ends with `q7Zk#x2` as a line of its own, which the overnight automation looks for (see README, Handover 6). A Microplan session ends the same way.

If a part turns out too big, split it (28a, 28b) instead of rushing it.

## Parts

Three parts that turn the first playable's rules into the final game's, without any minigame or online code: the lobby-size rules, the board built for each lobby size, and the passive powers. Each is playable by hand with the hot-seat setup screen (kept as the local mode, and how every part is tested). Duels are still the coin flip until the minigame frame (part 33).

### Part 28: The lobby-size rules

**Goal:** a match is 3 to 8 players, its turn count follows the lobby's size, only the first finisher gets a finishing trophy, and a challenger can walk away from a swap-only duel. Plus a look at the camera leftovers from part 27.

**Builds:**
- **`Match`:** `TURNS` (const 17) becomes a static var `turns`, set by `Match.start` from a table `TURNS_BY_LOBBY` (3:20, 4:17, 5:15, 6:14, 7:13, 8:12; see `game_rules.md`). `Board`, `Hud` (the "Turn 3/17" tag, the last-turn squash) and `_last_turn` read it. `Match.reset` leaves it alone (the next `start` sets it).
- **Setup screen:** the player count runs 3 to 8, defaulting to 4; the Begin button says why it is off below 3 (a short line, new string in both languages). Check what the old 2-player default touched (`setup.gd`, `pregame.gd`'s test match of 2, `ceremony.gd`'s test matches).
- **Trophies:** `Match.results()` gives the finishing trophy to the first finisher only, 1 trophy (the first-finisher copy-twice in the ceremony goes: `first` round shows one). Second and later finishers get none. Gold and duels trophies stay, ties share. The tiebreaker keeps its order. The ceremony's rounds, and the leaderboard's `×N`, follow `results()`; the early end ("Everyone else is home") now triggers when all but one have finished, as before.
- **The swap opt-out:** in `Challenge`, when the only valid stake for the chosen opponent is swap (gold and blood both greyed), the challenger gets a "Walk away" paper button beside the cards. Picking it, or letting the 20 s timer run out onto it, ends the space like an empty one (nothing is given: not even the coin the old "nobody to duel" fallback gives). A timeout still picks a random valid choice, and walking away counts as valid and can be chosen by that dice. Nobody with an opponent but no valid stake: walk away is the only choice, taken without asking after a short banner.

**Polish:**
- The "Walk away" button is a `PaperButton` that pops in with the cards, with `ui_click`; when pressed the cards lift away and the piece does a small shrug (`PaperMotion.tilt`), with no new sound. Its text in English and Turkish.
- The lobby-size turns change the HUD's counter text: check the longest ("Turn 12/12", "Last turn!") still fits.
- The first-finisher trophy is shown once on the leaderboard, ceremony pops are unchanged otherwise.

**Assets:** none.

**Check:**
- Headless: `Match.results()` for a first finisher with several behind, ties in gold and duels, and nobody finishing; `Match.start` with 3 to 8 sets `turns` to the table; 2 is refused.
- A plain sped-up run with 3 players (20 turns, last-turn banner on turn 20) and 8 (12). A forced swap-only choice shows "Walk away"; clicking it by MCP ends the space, and the timeout run picks it sometimes.
- The part 27 leftovers by eye in a plain run: the fork with its arrows, a far death flight, the die. Fix a number in `BoardCamera`/`BoardLayout` only if something is clearly off; if the user's verdict on the zoom has come in the README, follow it.
- Screenshots: the 8-player HUD at turn 1 of 12, the "Walk away" button, the ceremony's leaderboard with one trophy for the first finisher.

**Risks:** the ceremony and stats were written for two finishing trophies; read `Match.results()`'s `by` shape and the ceremony's rounds before changing them. The user may reply to part 27 with "undo the zoom": that is `ZOOM = 1.0` plus the constants listed in the Part 27 notes.

### Part 29: The board for each lobby size

**Goal:** each lobby size gets its own road, from 46 to 65 spaces on average, rolled fresh every match, with the four minigame spaces on it. The scenery fits every length.

**Builds:**
- **`BoardRoller`** (new, `src/board/board_roller.gd`): the logic of `tools/board/roll_board.py` in GDScript, so the board is rolled at runtime. Input: the lobby size and the bags from `board.md`'s Space mix. Output: the `kinds` string of each of the seven stretches. Half empty; the filled half split into quick spaces and minigame spaces 1 to 1; the quick ones in equal numbers of the four kinds (the graveyard's only spikes and thieves, the church path's only churches and coins), the minigames in equal numbers of the four games, an odd space going to a random kind. Each stretch is a shuffled bag. Use a `RandomNumberGenerator` that `Match.start` seeds, and keep `--seed N` working on the board for tests.
- **`BoardLayout`:** the village, forest and castle space counts come from the lobby size (table in `board.md`: village 14/12/11/10/9/8, forest the same, castle 17/16/13/11/10/10). The splits stay (graveyard 8, church 12, boardwalk and bog 10). `_locations`, `hill_width()` and `BoardPath._nodes` are cached statics, so add `BoardLayout.configure(size)` and `BoardPath.configure(size, kinds)`, which clear them and rebuild. `Board` calls them before building the scenery.
- **`BoardPath`:** `KINDS` gets `p` pong, `u` sumo, `e` head soccer and `w` tug of war (`s` spikes and `h` church are taken), with the kinds named `pong`, `sumo`, `head_soccer`, `tug_of_war`. `STRETCHES` loses its hard-coded kinds string and gets lengths from the size. `racing` and `fps` kinds go.
- **Scenery:** `scenery.gd`'s `_spots(location, first, last, gap)` already keeps the props' density, so a shorter village or a longer castle should only change the number of props. Check every length (the board is 44 to 67 spaces wide, about 12,000 to 16,500 px), the far layers' ends, the moon/star/sky coverage, the progress track, the intro glide time (scale `INTRO_GLIDE` with the width so it never feels slower than 7.5 s), and the church hill's width.
- **Minigame icons:** `Space` shows the icon of its kind. The four icons are `pong.png`, `sumo.png`, `tug_of_war.png` and `haxball.png` (rename it `head_soccer.png`, and its `_rim`, and the `.import` files; fix every reference). The unused `racing` and `fps` icons are deleted (files and imports) once nothing references them. `docs/assets.md` is updated.
- **The ground fix** (if the user kept the zoom): a taller ground strip for the village at least, to remove part 27's root streaks; ask nothing, just regenerate with the existing tool or note it if the art needs a new Gemini image.
- **`tools/board/roll_board.py`** stays as the offline sanity tool but must print the same kinds counts; a short note in the Part notes, or delete it if the GDScript replaces it entirely.

**Polish:**
- The minigame spaces' hover and wake are the same as the old duel-space ones. Each of the four games reads clearly from its icon, with the cream rim.
- The branch choice arrows list up to 4 icons of each path, most common first, as before; with four new kinds, the church path still shows churches and coins, the graveyard spikes and thieves, the swamp paths a mix.
- The board's intro glide is the same feel at every width.
- The progress track and the signposts keep working at every width.

**Assets:** the icons from part 26 (`sumo`, `tug_of_war` and the renamed `head_soccer`; Pong's exists).

**Check:**
- Headless: for every lobby size 3 to 8, over 500 rolls, the route lengths (shortest and longest) average to the brief's number, every stretch's bag counts are exact, and the church and graveyard hold only their kinds.
- A plain run for 3 and for 8 players: walk the intro glide over the whole board and look for edges, gaps in the sky, missing props. 25 FPS on the church hill and the castle at both widths. No errors or warnings.
- Screenshots: a 3-player village start, an 8-player castle, and the swamp fork with its arrows' new icons.

**Risks:** the size of the rewrite of the cached statics: do `configure` first and test with 8 then 3 in one session (the ceremony's "Play again" must rebuild for a new size). Minigame icons: if two of them look alike at the board's size, tell the user.

### Part 30: Powers I, the passive ones

**Goal:** monster select tells you each monster's power, and the six powers that need no other player's board position work: the Wolf Man's roll, Cthulhu's start, Death, Dorian Gray's swap, Frankenstein as challenger, and the pop of a word when a power fires. Dracula, Medusa (the "nearby" ones) and Mr. Hyde's edge come later.

**Builds:**
- **`Monsters`:** a `power_key` for each monster, and `strings.csv` lines (English and Turkish) for the eight cards' short power line (the table's wording in `characters.md`).
- **Monster select:** the card/piece shows its power line (a small paper tag under the name). It must fit 8 cards.
- **`Match`:**
  - `roll()` adds 1 for the Wolf Man (move 2 to 7); `Match.max_blood(player)` is 4 for Cthulhu and 3 for others, replacing `MAX_BLOOD` in `change_blood`, `die` and the HUD's drops; Cthulhu starts with 4 blood and 1 coin (and keeps its respawn at 4, with no coin).
  - Death's blood never drops below 1 in `change_blood`, and spikes at 1 blood do nothing. `Match.stakes` greys blood when Death has 1 blood (as challenger or challenged).
  - Frankenstein as the challenger loses nothing on `duel_result`: no coin, no blood, no death. The loss still counts as a loss in `duels_won` for the winner and as a started duel for him.
  - Dorian Gray as the challenger needs 1 win in a swap: `Duel.roll_rounds(stake, challenger_wins_needed)`.
- **The pops:** a `PowerPop` (small paper label, `pop_in`, rise and `pop_out`) over the piece or the die, with `Sound.play("power")`. "+1" beside the Wolf Man's die, "4" in Cthulhu's HUD blood on the drop-in (no pop needed), "Safe!" when Death's spikes do nothing or his blood stake is greyed, "Free!" on Frankenstein's lost duel, "Easy!" on Dorian's swap. New strings in both languages. Dracula and Medusa's pops are for part 31.
- **HUD:** the blood drops show a fourth for Cthulhu, with the same flights.
- **Sounds:** `Sound.TRIM` gets about +3 dB for `paddle_hit` and `stone` (part 26's note), though they are used later.

**Polish:**
- The Wolf Man's die shows its real face, then the "+1" pops beside it and the move count includes it.
- Death's "Safe!" is a shrug (`PaperMotion.tilt`) with the pop, not a death.
- The monster cards' power lines are in the display font, same size, and readable in Turkish.

**Assets:** none new (`power.ogg` and the display font exist).

**Check:**
- Headless: the six powers against the rules in `characters.md`: roll ranges (Wolf Man 2 to 7, others 1 to 6), blood caps, Death never below 1, Frankenstein's losses, Dorian's swap rounds (2,000 runs, Dorian's win rate against the old 12.4%), and that nothing changes for a monster without the power.
- A plain run, 8 players with every monster: monster select shows 8 power lines; the board runs a few sped-up turns; Cthulhu has 4 drops; a forced spikes landing for Death at 1 blood does nothing. No errors or warnings. 25 FPS.
- Screenshots: monster select with the power lines, the Wolf Man's "+1", and Cthulhu's four drops.

**Risks:** `MAX_BLOOD` is used by the HUD, `Match.die` and `change_blood`; search before changing. The stake greying for Death at 1 blood needs a rule in `Match.stakes`: when blood is greyed and gold is not valid (the opponent has no coins) and swap is, the opt-out from part 28 applies.

## Roadmap

Very rough. The next Microplan (after part 30) rewrites it. It ends at 43 now, not 44: Run n Dodge (old 37) is out, as part 25 decided. The end may still move.

25. Questionnaires 16 to 18 and the docs. (done)
26. Asset retrieval. (done)
27. The camera tweak. (done)
28. The lobby-size rules, and the swap opt-out.
29. The board for each lobby size, with the four minigame spaces.
30. Powers I: the passive ones.
31. Powers II: Dracula's steal and Medusa's stone ("nearby" along the road), with their moments on the board.
32. An online spike: a web export in a browser, and two tabs talking through the Cloudflare relay. Throwaway code. Ask the user for the free Cloudflare account and which friends test, before this part.
33. The minigame frame: from the VS card into a minigame and back, the shared table, the two local key sets, the first point, input through one seam so online can feed it later, and Mr. Hyde's advantage hook.
34. Pong.
35. Tug of War.
36. Sumo.
37. Head Soccer.
38. Online I: the lobby (join, names, ready, start) and the web build.
39. Online II: the board over the network (the host runs the rules, everyone draws), the timers and absent players.
40. Online III: the minigames over the network, and everyone watching.
41. Online IV: drops, reloads, the host leaving, and the itch.io page.
42. Playtests with friends, tuning (the brief's turn table checked with the powers), and the bug bash.
43. The release on itch.io.

## Part notes

Each part session adds a few lines when it finishes: what got built, what changed from the plan, surprises, and anything left over or buggy. The next Microplan reads these instead of the code.

### Carried over from parts 25 to 27 (absorbed by Microplan 10)

- **Design:** questionnaires 16 to 18 are answered and saved; 19 was never filled in and the user ended them ("Use your own judgement for the rest"), so online play is Claude's call, marked in `tech.md`. Four minigames (Pong, Sumo, Head Soccer, Tug of War), no minigame music, no time limit, Mr. Hyde's edge only when he challenges.
- **Assets (part 26):** 10 images and 14 sounds, all approved. Icons `sumo` and `tug_of_war` (with `_rim`); `assets/art/minigames/` holds `pong_table`, `paddle` (grey, to tint), `sumo_ring`, `goal` (faces right, mirror for the left), `ball`, `boot` (grey, to tint), `rope` (121 px tall, tiles sideways) and `ribbon`. Sounds in `assets/audio/sfx/`: `whistle`, `paddle_hit`, `bounce`, `kick`, `jump`, `sumo_bump`, `rope_pull`, `power`, `stone`, `stone_crack`, `join`, `leave`, `ready`, `start`. Head Soccer keeps `haxball.png` (to be renamed `head_soccer.png` in part 29). Reused for the final game (see `assets.md`): Pong's ball is `crumpled.png`, sumo pieces are tinted `space.png` with portraits, Head Soccer's heads are portraits on `boot.png`, Medusa's stone is the piece tinted grey. `Sound.TRIM` has nothing for the new sounds yet; `paddle_hit` and `stone` want about +3 dB. The rope is thin: scale it in the engine if weak. The Gemini key has no image quota, so `tools/images/make_images.py` needs billing; the user makes images by hand. Lobby sounds are short synthetic blips; only `start` is a door.
- **Camera (part 27):** `BoardCamera.ZOOM := 0.88` (the one number; 1.0 undoes it) with `HALF_WIDTH`/`HALF_HEIGHT`; limits -73 to 1153. Constants for the raised angle: `GROUND_Y` 780→750, `PROP_BASE_Y` 840→810, `HILL_TOP_Y` 565→542, `UPPER_Y` 650→627, `LOWER_Y` 930→935, `FAR_Y` 380→350, `WATER_Y` 700→670, the fog bank 600→570; `MAIN_Y` stays 880. Clickable things (die, candle, branch arrows) are scaled by `1 / ZOOM`. `scenery.gd`'s `_ground_fill` stretches each ground strip's bottom rows down 200 px: **known blemish**, faint vertical root streaks at the bottom edge, which a taller ground image would fix. **Not checked by eye:** the fork with arrows, the death flight, the church hill and castle at 25 FPS in motion, the die. The user's verdict on the before-and-after sheet (`screenshots/part_27/1.png`) was still pending.
- **Board code today:** the `kinds` strings in `BoardPath.STRETCHES` are hand-baked from `tools/board/roll_board.py` (seed 1031), `BoardLayout.LOCATIONS` has fixed space counts (12, 12, 12, 10, 15), and `BoardPath`, `BoardLayout` cache statics. `Match.TURNS` is a const 17, `Match.MAX_BLOOD` 3. `KINDS` still holds `x` haxball, `r` racing and `f` fps. Part 28 to 30 change these.

### Part 28: the lobby-size rules (done 2026-10-24)

- **`Match`:** `MIN_PLAYERS` is 3, `TURNS_BY_LOBBY` holds the table, and `Match.turns` is a static var set by `start` (`Board`, `Hud` read it; `TURNS` is gone). `results()` gives `by.finish` 1 to the first finisher only; the ceremony's "second" round is gone and "first" throws one copy.
- **Setup:** the default is 4 cards and Remove stops at 3, so Begin can never be off for too few players: the planned "why it is off" line was not needed and not added.
- **Walk away:** `Challenge` returns `{opponent, stake: Challenge.WALK}` when the challenger walks away (button under the cards when swap is the only valid stake; it is in the timeout's random pick). With no valid stake at all the banner says "Nothing to win here" and walks away alone. `Board.land` tilts the piece and ends the space with nothing given. New strings `CHALLENGE_WALK`, `CHALLENGE_NOTHING`.
- **Checked:** headless table, results and refusal of 2; an 8-player board (HUD "Turn 1 of 12" fits) and a clicked Walk away; the 8-player ceremony. Not done: the sped-up 3-player 20-turn run and the timeout-picks-walk run were not played out (kept short); the camera leftovers were not touched.
- **Test hint:** a headless `-s` script can't see autoloads in `_init`; use `_process`. Running the board as a child of a driver scene works for forcing a challenge.

## Log

- **2026-10-23 to 24, Microplans 1 to 8:** the first playable, parts 1 to 24. See [microplan_first_playable.md](microplan_first_playable.md#log).
- **2026-10-24, Microplan 9:** the start of the final game, from the user's brief. Planned parts 25 to 27: the questionnaires, asset retrieval, and the camera tweak. Sketched the roadmap to part 44.
- **2026-10-24, Microplan 10:** planned parts 28 to 30: the lobby-size rules, the board for each lobby size, and the passive powers. They are the rules that don't need minigames or networking, so they can be tested by hand in the hot-seat mode. The roadmap now ends at 43 because Run n Dodge is out (part 25), and Head Soccer goes last of the four minigames (it has the most new physics). Dracula and Medusa wait for part 31 because "nearby" depends on the new board. The online spike stays at 32, ahead of the minigame frame, so the riskiest unknown is found before the frame is built over it. Part 27's unchecked items are folded into part 28.
