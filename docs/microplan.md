# Microplan

The [final game](roadmap.md#2-final-game), built in parts after the first playable's 24. The numbers go on from there, so the first part of this plan is 25. `/microplan` plans three parts at a time in detail, and a rough roadmap to the end (see `.claude/skills/microplan/SKILL.md`). It runs in its own session, after part 27, 30, 33 and so on.

- **The brief:** the user's direction for the final game is [final_game_brief.md](questionnaire_answers/final_game_brief.md), saved word for word. Until part 25 updates the docs, it wins over any doc that disagrees (17 turns, 2 players, two finishing trophies, Haxball and the racing game are all out of date).
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

**Interactive parts.** Parts 25 and 26 need the user at the keyboard: they wait for answers and for files, so they break rule 5's "never waits", and the overnight automation must not start them. Points 1 to 4 and 6 to 7 apply only where the part runs the game. Such a part still ends with `q7Zk#x2`, but only once it is finished and merged, never while it waits.

If a part turns out too big, split it (25a, 25b) instead of rushing it.

## Parts

Three careful, low-commitment parts: settle the design, get the assets, and try the camera. Nothing in them locks in the code for the rules, powers, minigames or online play, so the Microplan after part 27 plans those with everything known.

### Part 25: Questionnaires for the final game

**Goal:** every open design question of the final game has an answer from the user, saved word for word, and the docs say the final game instead of the first playable.

**Builds:**
- **The questionnaires, 16 on,** in the same shell as 1 to 15 (https://claude.ai/artifact/4EQdWyaX3PzgggQHBMe2Xi). Read it with the Artifact tool first, change only the `QUESTIONNAIRE` block (`number`, `title`, `questions[{text, hint}]`), and republish to the same URL. One at a time: the user fills it in and pastes the answers, Claude saves them as `docs/questionnaire_answers/questionnaire_16.md` and so on **as they are, with no commentary**, then makes the next one. Earlier answers sharpen later questions.
- **Topics.** Five questions each, about four questionnaires. The session writes the questions, but every item below must be covered, either as its own question or as part of one. Don't ask again what the brief or its chat answers already settle.
  - **16, the powers:**
    - Dracula: does the steal still happen at full blood, with the victims losing and Dracula staying at 3? Does "one behind or one forward" follow the road through forks, so it reaches both paths of a split? Are finished players and the start safe?
    - Medusa: what if a player is caught twice before their turn? Does a missed turn show (a stone piece, a skipped portrait)? Is a landing by swap a landing, for her and for Dracula?
    - Death at 1 blood: spikes do nothing, but can Death be challenged for blood at 1 blood, can Dracula take Death's last drops, and what does a blood-stake loss do?
    - Mr. Hyde's "duel advantage": what it is in each of the five minigames (a bigger paddle, a heavier sumo, a head start in tug of war...), or one shared rule such as a head start.
    - Cthulhu: does a respawn give 4 blood? Frankenstein: does "nothing" include the blood a challenger loses in a death match, and do they still count the duel as a loss? How do players learn the powers (monster select card, a pop on the board when a power fires)?
  - **17, the minigames:** one question each for Pong, Sumo, kafa topu (confirm it means head soccer: a side view, a big head, one goal each), Tug of War (S only) and Run n Dodge (jump and duck only). Each covers its view (side or top-down), what wins the first point, a time limit with what happens at the limit, and a draw (both hit in the same frame). Plus one question on whether a game has one arena or a few at random (Q14 left this open), and whether the minigames get music.
  - **18, the board and the rules:** board size by lobby: a fixed layout for each lobby size, or one rolled fresh every match? How the 65 to 46 spaces are shared out: the stretches shrink in proportion, forks and their lengths stay or shrink? Which minigame goes on which space now that there are five: the boardwalk-or-bog choice by game, or random? With the swap-only opt-out, what does the space do: nothing, or a coin? Does the hot-seat setup screen stay as a local mode (it's how every part is tested), or go once online works?
  - **19, online play on itch.io:** a browser build needs a relay. Research the options first and put two or three in the hints with Claude's pick: who runs it (a free host the user signs up for, or a peer-to-peer link through a public signaling server), the cost, and latency between Turkish cities. Then: the lobby (a room code, a link, or a list), what happens when a player drops or reloads, whether a Windows build is still made next to the web one, and how many friends test it and when.
  - **20, if needed:** whatever 16 to 19 opened up. Anything after that goes to chat.
- **The docs, after the last answers:** `game_rules.md` (3 to 8 players, the turn table, the trophies, the swap opt-out, the powers' rules), `board.md` (sizes by lobby, the 1:1:1 mix, the five minigame spaces), `minigames.md` (the new list with each game's rules, Haxball, racing and the FPS out, the old candidates list cut down), `characters.md` (the powers table, the open questions answered), `screens.md` (the lobby, power moments, the opt-out button), `tech.md` (online, the relay, the web build) and `roadmap.md`. Then README's Status. The memory note about the questionnaire loop is reopened for 16 on.

**Polish:**
- Each question is short and plain, and its hint gives two to four concrete options and Claude's recommendation, as in 1 to 15.
- Use the user's own words for the games ("kafa topu", "Run n Dodge") in the questions, and the English names in the docs once confirmed.
- Docs only change after the last questionnaire, all in one go (the old loop's rule).

**Assets:** none.

**Check:** every questionnaire's answers are in `docs/questionnaire_answers/`. After the docs pass, search the docs for leftovers and fix each: "17 turns", "2 to 8", "Haxball", "racing", "FPS", "Second to reach", "None yet". No game run and no screenshots: this part changes no code.

**Risks:** the answers can open new questions without end. Stop at questionnaire 20, and ask anything after that in chat. If an answer changes what parts 26 or 27 do, add a line under their Risks.

### Part 26: Asset retrieval

**Goal:** every new image and sound the final game needs is listed, made, processed into `assets/`, and approved by the user, so later parts only wire them in.

**Builds:**
- **The list** in `docs/assets.md`, worked out from part 25's docs. Keep it small (principle 2). What it will at least hold:
  - The four new minigame icons: sumo, kafa topu, tug of war, Run n Dodge (Pong's exists), each with its `_rim` version from `tools/images/make_outlines.py`. `haxball.png`, `racing.png` and `fps.png` stay until the board stops using them; their removal is a later part's job.
  - Each minigame's pieces as paper cutouts on a painted table: a table or arena, the players' pieces in the monster's color or by tint, the ball, the rope, the obstacles. Prefer one grey piece that gets the monster's color in the engine to eight colored copies.
  - Power moments, only where motion alone can't carry them, such as Medusa's stone or Dracula's blood drop (`blood.png` may already do it).
  - The lobby, if the answers need more than the existing paper card, panel and button, such as a room code card or a ready tick.
  - Sounds: each minigame's hits, bounces, whistle, rope creak, jump, duck and crash; each power's moment (steal, stone, the skipped turn); the lobby (someone joins, ready, start).
  - Music: only the names of any new tracks. The user makes the music separately.
- **The prompts:** Gemini prompts in `docs/asset_prompts.md` in the same style as the old ones, with their Processing notes, and sound prompts as entries in `tools/sounds/gen_sound_prompts.py`, which rebuilds `docs/sound_prompts.md` (never edit that doc by hand).
- **Images:** the user makes them in Gemini and drops the raws in `images_raw/`. `tools/images/process_images.py` gets their processing rules, and is run on them. Then `make_outlines.py` for the icons.
- **Sounds:** `tools/sounds/make_sounds.py` with `ELEVENLABS_API_KEY` (ask the user for it, and never write it down), then `process_sounds.py`, then the phone review page (`build_review.py`, published as an artifact with its files) for the user to rate. Remake the rejects.

**Polish:**
- The new art must sit with the old: the same paper texture and palette, the same light from the top left, the same cream rims on icons. A contact sheet of each new image beside an old one of its kind (a new icon beside `pong.png`, a new piece beside a monster) for the user to judge.
- The new sounds are matched to the old ones by level: check their mean levels against the median file that part 23's `Sound.TRIM` was worked out from, and note any trim the wiring part should set.

**Assets:** this part makes them. **Missing, as before:** all music, and `sting_final_turn`.

**Check:** every new file in `assets.md` exists under its name, and `--headless --import` imports them with no errors. The contact sheets are saved as `screenshots/part_26/1.png` to `3.png` (icons, minigame pieces, the rest). The user has approved the sound review page.

**Risks:** the user makes the images by hand, which can take more than one sitting: split into 26a (the list, the prompts and the sounds) and 26b (the images) if it does. A minigame whose rules part 25 couldn't settle gets no art yet.

### Part 27: The camera tweak

**Goal:** the board is seen from a little further out and a little higher, and the existing scenery still reads as one real place. The user judges it from a before-and-after sheet. The last high camera was reverted because the scenery looked fake, so this one stays slight and is easy to undo.

**Builds:**
- **Zoom out:** one `BoardCamera.ZOOM` constant (start at 0.88, so the view is about 2,180 × 1,227 world px). Every 960 that means "half the screen" becomes half the zoomed view: the clamps in `BoardCamera` (`_process`, `glide_to`, `jump_to`), `BoardLayout.layer_x`, and `scenery.gd`'s `beyond`. The camera's `limit_top` and `limit_bottom` grow to fit the taller view, centred on the old 540.
- **The raised angle,** faked in 2D with `BoardLayout`'s constants only, nothing new drawn: the ground strips a little taller (`GROUND_Y` up about 30 px), the upper and lower lanes a little further from the road (about 10% more), the far layers a little higher, so the horizon rises, and `PROP_BASE_Y` and `HILL_TOP_Y` following. Tune by eye in small steps.
- **Covering the bigger view:** the sky (its own `CanvasLayer`), the moon and the stars fill the screen; the ground strips, the dark road strip and the fog reach the bottom edge with no hard end; the church hill and the castle keep their proportions; the scenery's ends still cover both ends of the board.
- **Things placed for the old screen:** the die (`DIE_RISE`), the branch arrows at (+260, -470) and (+260, -340), the floating half-size candles, the gate's onlookers, the progress track from the sweeping changes, the bats' flight (`bat.gd` already reads the canvas transform), and every world-to-HUD flight (coins, blood, the duel's coins). Find them by searching for `960`, `center_x()` and `global_position` in `src/board/`, and make each read the camera's zoom.

**Polish:**
- **Screen sizes:** the monsters, spaces and scenery get smaller on screen, which is the point. The things you click (the die, the branch arrows, the candles) are scaled by `1 / ZOOM`, so they stay the size they are now.
- **Motion:** the glide and follow speeds (`SPEED`, `FOLLOW_SPEED`, the 2,600 px/s cap) are in world px, so divide them by `ZOOM` to keep their feel on screen. The death's flight still keeps the ball in the middle of the screen.
- **Parallax:** with the zoom, the far layers must still slide slower than the road and never show an edge; walk the whole board with the intro glide and look.
- No new effects and no new motion.

**Assets:** none new. If an image can't cover the bigger view (a ground strip ends, the hill's edge shows), note it for the next Microplan instead of making a new one.

**Check:**
- A plain run with a temporary screenshot script (not committed): the same six views before and after (the village start, the graveyard fork with its arrows, the church hill, the forest, the swamp fork, the castle gate with onlookers), as one before-and-after contact sheet for the user. Shoot the "before" from `development` first.
- An 8-player crowd at a fork, a death flight from far away, and a coin flight to the HUD, all landing in the right place. 25 FPS on the church hill and the castle.
- Screenshots: the sheet, the fork, and the castle.

**Risks:**
- The user may not like it, as with the last high camera. Every change sits in `BoardCamera` and `BoardLayout` constants, so retuning or undoing it is a few numbers. Say so in the notes.
- `Parallax2D` under a zoom: if the layers drift, fix `layer_x` and the scenery's placement together, never piece by piece.
- Part 25 may decide the board shrinks to 46 spaces for 8 players, and a later part builds that. Nothing here should depend on the board's length.

## Roadmap

Very rough. The Microplan after part 27 rewrites it with part 25's answers in hand.

25. Questionnaires 16 on, and the docs for the final game.
26. Asset retrieval: the list, the prompts, the images and the sounds.
27. The camera tweak: zoom out and raise the angle slightly.
28. The small rules: 3 to 8 players, the turn table by lobby size, the one finishing trophy, and the swap-only opt-out.
29. The board by lobby size: lengths from the brief's table, half empty and the filled half split between quick and minigame spaces, the five minigame spaces with their new icons.
30. Powers I: monster select shows the powers, and the passive ones (Wolfman's roll, Cthulhu's start, Death, Dorian Gray's swap, Frankenstein as challenger).
31. Powers II: Dracula's steal and Medusa's stone, with their moments on the board.
32. An online spike: a web export running in a browser, and two browser tabs talking through the relay from questionnaire 19. Throwaway code, to find the real problems early.
33. The minigame frame: from the VS card into a minigame and back, the shared table, the controls, the first point, input through one seam so online can feed it later, and Mr. Hyde's advantage hook.
34. Pong.
35. Tug of War.
36. Sumo.
37. Run n Dodge.
38. Kafa topu.
39. Online I: the lobby (join, names, ready, start) and the web build.
40. Online II: the board over the network (the host runs the rules, everyone draws), the timers and absent players.
41. Online III: the minigames over the network, and everyone watching.
42. Online IV: drops, reloads, the host leaving, and the itch.io page.
43. Playtests with friends, tuning (the brief's turn table checked with the powers), and the bug bash.
44. The release on itch.io.

## Part notes

Each part session adds a few lines when it finishes: what got built, what changed from the plan, surprises, and anything left over or buggy. The next Microplan reads these instead of the code.

## Log

- **2026-10-23 to 24, Microplans 1 to 8:** the first playable, parts 1 to 24. See [microplan_first_playable.md](microplan_first_playable.md#log).
- **2026-10-24, Microplan 9:** the start of the final game, from the user's brief. Planned parts 25 to 27: the questionnaires, asset retrieval, and the camera tweak (the user asked for these three, and picked the camera as the non-committal third). Sketched the roadmap to part 44. The order of minigames and online play is open: the online spike at 32 is there to test the riskiest unknown before the minigame frame is built on top of it. The old microplan was archived, and its notes stay as the code map.
