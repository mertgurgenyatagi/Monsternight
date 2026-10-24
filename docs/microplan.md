# Microplan

The [final game](roadmap.md#2-final-game), built in parts after the first playable's 24. The numbers go on from there. `/microplan` plans three parts at a time in detail, and a rough roadmap to the end (see `.claude/skills/microplan/SKILL.md`). It runs in its own session, after part 36, 39, 42 and so on.

- **The brief:** the user's direction for the final game is [final_game_brief.md](questionnaire_answers/final_game_brief.md), saved word for word. The design docs ([game_rules.md](game_rules.md), [board.md](board.md), [characters.md](characters.md), [minigames.md](minigames.md), [screens.md](screens.md), [tech.md](tech.md)) say what the final game is. Questionnaires ended at 18; the rest is Claude's call.
- **The code map:** the first playable's Part notes ("Built so far" in [microplan_first_playable.md](microplan_first_playable.md#part-notes)) describe the code as it stands, and "The code since part 24" below adds what parts 25 to 33 changed. Read the section your part touches instead of rereading the code.

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

If a part turns out too big, split it (31a, 31b) instead of rushing it.

## Parts

Three parts: the first three of the four minigames, each plugged into the finished frame (part 33) through `Minigames.GAMES`. Pong first (the simplest physics, and the closest to the frame's stub), Tug of War next (the smallest, one key, which also tests the action key on both sets), Sumo third (circle physics that Head Soccer, part 37, builds on). Every game is a `Minigame` subclass in `src/minigames/`, draws its own table in the frame's 1920 x 1080 space around `Minigame.TABLE_CENTER` (table 1480 x 640, y 220 to 860), reads keys only through `MinigameInput`, calls `finish(side)` or `finish(Minigame.DRAW)`, and applies `edge` (Mr. Hyde: 0 or 0.1) in its own way, written down in its Part notes. Each game lasts about 20 to 30 seconds, with no time limit (Q17).

**Shared by all three:**
- **Pong (part 34):** `PongGame` (`src/minigames/pong_game.gd`), registered with `preload` in `Minigames.GAMES` (a class name is not a constant expression there). Table `pong_table.png` at 1480 x 640 with the playfield `FIELD` (1378 x 554) inside its cream border; paddles `paddle.png` 30 x 120 tinted, ball `crumpled.png`. `step(delta)` is the whole physics (public, for drivers); paddles 640 px/s (`* (1 + edge)` for the challenger), serve 700 px/s eased in over 0.4 s, +10% per paddle hit up to 1250 (the user asked for a faster serve and faster speed-up while testing), return angle up to 52 degrees by where the paddle is hit, sub-steps of half a ball radius. First ball past a line ends it, never a draw. Squash, hop and droop after the point, paper-bit puff, ball spin; sounds `paddle_hit` and `bounce`. New string `KEYS_UPDOWN`. Checked headless (lone paddle loses on each side, the cap holds with perfect tracking over 30 hits, paddle speeds 704 and 640) and in a plain run through the frame with scripted tracking, 25 FPS, three screenshots. The Hyde win-rate test was too noisy to show anything (33/60 both ways); the speed ratio is the real check. Not done: real keys through the MCP, and the Turkish string by eye.
- **Test habit:** a headless driver sets `MinigameInput.source` to a scripted function, steps the game with fixed time and asserts the winner. A few real key presses through the MCP `simulate_key` once per game is enough to prove the keys work.
- **Edge:** a small, invisible lean for the challenger (not a head start anyone can see). A driver checks that at 0.1 the challenger wins more often than at 0 with equal scripted play.
- **Keys:** the keycaps come from `controls()`. One computer: left side W A S D and Q (action); right side the arrows and K. Keep every game to what one hand can do, since two hands on one keyboard may ghost.
- **Table look:** a paper cutout on the dark table, from the `assets/art/minigames/` images, with no per-frame allocations.

### Part 34: Pong

**Goal:** a minigame space of kind `pong` plays real Pong: two cardboard paddles, a crumpled-paper ball, first goal wins.

**Builds:**
- **`PongGame`** (`src/minigames/pong_game.gd`), registered as `Minigames.GAMES["pong"]`. The table is `pong_table.png` scaled to 1480 x 640, the paddles are `paddle.png` tinted with `color_of(side)`, the ball is `crumpled.png`. The challenger is the left paddle.
- **Movement:** `MinigameInput.direction(side).y` moves the paddle at a fixed speed (about 640 px/s), clamped to the table. Arrows only.
- **Ball:** after the go it eases in over 0.4 s from the middle towards a random side at a gentle speed, then speeds up about 6% on each paddle hit, up to a cap. Where the ball strikes the paddle bends its angle (centre goes straight, the ends go steep). The table's top and bottom bounce it. The first ball past a paddle's line is the point and the other side wins. Never a draw.
- **Hyde's edge:** the challenger's paddle moves 10% faster (`speed * (1 + edge)`).
- **Fixed-step physics** in `_physics_process`, split into sub-steps so the ball never moves more than half its radius at once and can't tunnel through a paddle.
- **Sounds:** `paddle_hit` on a paddle (pitch up a hair with the ball's speed), `bounce` on a wall.

**Polish:**
- The paddle squashes on a hit (0.1 s) and springs back. The ball spins with its speed and leaves no trail (minimalism).
- A small puff of paper bits where the ball crosses the goal line; the scoring side's paddle hops once, the other's droops.
- The first serve is slow enough that a ready player is never beaten by it.
- A side with no key down, or an absent side, does not move, and loses by not playing.
- `controls()` gives the up and down keycap line for each side.

**Assets:** `pong_table`, `paddle`, `crumpled`, `paddle_hit`, `bounce`. None new.

**Check:**
- Headless: the ball bounces off the walls and paddles and never tunnels at the speed cap; scripted paddle tracking makes a long rally and a lone paddle loses; the first ball past a line finishes with the right winner; the speed cap holds; the Hyde test.
- A plain run: a 4-player game, force a Pong space, play it with the MCP keys once, see the winner applied. 25 FPS.
- Screenshots: the ball mid-rally, a paddle squash, the result.

**Risks:** first goal wins can end in seconds if a side stands still. That's accepted (nobody can refuse a duel, and "shitty" is the standard).

### Part 35: Tug of War

**Goal:** a minigame space of kind `tug_of_war` plays Tug of War: a rope with a marker, each press of the action key pulls it your way, and past your line wins.

**Builds:**
- **`TugGame`** (`src/minigames/tug_game.gd`), registered as `GAMES["tug_of_war"]`. Side view: the rope (`rope.png`, 121 px tall, tiled sideways, scaled up if it looks weak) across the table; the `ribbon.png` marker at the middle; two lines (cut-paper flags) at each side; each player's portrait pawn at its end of the rope, leaning back as they pull. The challenger is on the left.
- **Rules:** one key, `MinigameInput.just_pressed(side, "action")` (Q on the left, K on the right; S online). Each press moves the marker a step towards that side. The marker also creeps back to the middle slowly, so mashing has to keep up and a single lead doesn't hold (tuned in the build). Two presses in the same physics frame cancel. The first marker past a line wins. If both cross in one frame, the bigger lead that step wins, else the challenger (written down). Never a draw.
- **Hyde's edge:** each of the challenger's pulls is 10% stronger.
- **Sound:** `rope_pull` on each press, with a little pitch jitter, one voice per side so it isn't a machine gun.

**Polish:**
- The rope pulls taut on each press (a quick x-scale pulse) and the marker wiggles with a damped wave; the pawns lean and straighten with each press, and the one losing ground slides on their feet.
- Flat paper-bit dust puffs at the pawns' feet when they pull; the ribbon flutters with the marker's speed.
- The line the marker crosses flashes once (a tilt pop) before the frame's win beat.
- A small "Mash Q" / "Mash K" hint by each pawn fades after the first press.
- `controls()` gives the one-key line.

**Assets:** `rope`, `ribbon`, `rope_pull`. None new.

**Check:**
- Headless: one press per side moves the marker equally; alternating presses stay near the middle; the faster presser wins; same-frame cancellation; the creep back; Hyde's 10%; a held key does not repeat.
- A plain run: a Tug of War space, real Q and K presses through the MCP, the winner applied. 25 FPS.
- Screenshots: the opening, mid-pull with the lean, the crossing.

**Risks:** OS key repeat must never count as presses (the seam rolls `just_pressed` once per physics frame; check by holding). The creep-back sets who wins; part 42 retunes it with friends.

### Part 36: Sumo

**Goal:** a minigame space of kind `sumo` plays Sumo: two round pieces on a round ring push each other with the arrow keys; out of the ring loses, and both out at once is a draw that replays.

**Builds:**
- **`CirclePhysics`** (`src/minigames/circle_physics.gd`, small static helpers: collide two circles, bounce a circle off a wall or a circle), kept reusable because Head Soccer (part 37) needs it.
- **`SumoGame`** (`src/minigames/sumo_game.gd`), registered as `GAMES["sumo"]`. From above: `sumo_ring.png` as a circle centred on the table (radius about 290 px); the pieces are tinted `space.png` with portraits, a little larger than a board token. They start on opposite sides, held still until the go.
- **Physics:** the input is an acceleration, friction slows each piece, speed is capped. Pieces collide as circles (restitution about 0.7) and the closing speed adds to the shove, so a charge hits harder. A piece whose centre leaves the ring falls and loses. Both falling in the same physics frame is `Minigame.DRAW`. A, S and D do nothing and the ring never shrinks (Q17).
- **Fixed step with sub-steps**, as in Pong, so a fast hit never skips the collision.
- **Hyde's edge:** the challenger's piece is 10% heavier (shoves harder, is shoved less), invisible.
- **Sounds:** `sumo_bump` on a collision, with volume following the closing speed. The fall reuses `bounce` pitched down (noted).

**Polish:**
- On a bump both pieces squash along the line of impact and spring back, with a small puff of paper bits at the contact point; the ring jiggles a pixel or two on a hard hit.
- Each piece tilts into its move; its shadow stretches with its speed.
- The fall: the piece shrinks, spins a little and fades away, and the other's portrait hops before the frame's win beat.
- `controls()` gives the four-arrow keycap line.

**Assets:** `sumo_ring`, `space` (tinted), `sumo_bump`. None new.

**Check:**
- Headless: a pushed piece goes out and loses; two out in one frame gives a draw (and the frame replays it); a head-on hit of equal pieces sends both back equally; Hyde's heavier piece wins more head-ons; sub-steps stop tunnelling; a still opponent is eventually pushed out.
- A plain run: a Sumo space, arrows and WASD through the MCP, the winner applied. 25 FPS.
- Screenshots: the opening, a bump with the squash, the fall.

**Risks:** the feel of the circle physics decides the game and Head Soccer's ball extends it, so tune friction and restitution by playing. Diagonals on one keyboard can ghost against the opponent's keys: the push is an acceleration, so a lost key just feels like a slower piece.

## Roadmap

Very rough. The next Microplan (after part 36) rewrites it. It still ends at 43. The end may still move: the four minigames and the online parts are the big unknowns, and the spike (part 32) is where we learn how big the online part is.

25. Questionnaires 16 to 18 and the docs. (done)
26. Asset retrieval. (done)
27. The camera tweak. (done)
28. The lobby-size rules, and the swap opt-out. (done)
29. The board for each lobby size, with the four minigame spaces. (done)
30. Powers I: the passive ones. (done)
31. Powers II: Dracula's steal and Medusa's stone. (done)
32. An online spike with a local relay (no Cloudflare account needed yet). (done)
33. The minigame frame. (done)
34. Pong.
35. Tug of War.
36. Sumo.
37. Head Soccer.
38. Online I: the lobby (join, names, ready, start), the web build, and the Cloudflare deploy. Ask the user for the free Cloudflare account and which friends test.
39. Online II: the board over the network (the host runs the rules, everyone draws), the timers and absent players.
40. Online III: the minigames over the network, and everyone watching.
41. Online IV: drops, reloads, the host leaving, and the itch.io page.
42. Playtests with friends, tuning (the brief's turn table checked with the powers), and the bug bash.
43. The release on itch.io.

## Part notes

Each part session adds a few lines when it finishes: what got built, what changed from the plan, surprises, and anything left over or buggy. The next Microplan reads these instead of the code.

### The code since part 24 (parts 25 to 34; the frame and spike notes stay for parts 34 to 38)

- **Design and assets (parts 25, 26):** four minigames (Pong, Sumo, Head Soccer, Tug of War), no minigame music, no time limit, Mr. Hyde's edge only when he challenges; online play is Claude's call (`tech.md`). Images in `assets/art/minigames/`: `pong_table`, `paddle` (grey, to tint), `sumo_ring`, `goal` (faces right, mirror for the left), `ball`, `boot` (grey, to tint), `rope` (121 px tall, tiles sideways), `ribbon`. Reused: Pong's ball is `crumpled.png`, sumo pieces are tinted `space.png` with portraits, Head Soccer's heads are portraits on `boot.png`. Sounds in `assets/audio/sfx/`: `whistle`, `paddle_hit`, `bounce`, `kick`, `jump`, `sumo_bump`, `rope_pull`, `power`, `stone`, `stone_crack`, `join`, `leave`, `ready`, `start`. Lobby sounds are short synthetic blips. The rope is thin: scale it in the engine if weak. The Gemini key has no image quota; the user makes images by hand.
- **Camera (part 27):** `BoardCamera.ZOOM := 0.88` (1.0 undoes it) with `HALF_WIDTH`/`HALF_HEIGHT`. Raised-angle constants: `GROUND_Y` 750, `PROP_BASE_Y` 810, `HILL_TOP_Y` 542, `UPPER_Y` 627, `LOWER_Y` 935, `FAR_Y` 350, `WATER_Y` 670, fog bank 570, `MAIN_Y` 880. Clickable things are scaled by `1 / ZOOM`. **Known blemish:** `scenery.gd`'s `_ground_fill` stretches each ground strip's bottom rows down 200 px, leaving faint root streaks; a taller ground image would fix it. The user's verdict on the zoom (`screenshots/part_27/1.png`) was never recorded in the README, so assume it stays.
- **Rules (part 28):** `Match.MIN_PLAYERS` 3, `TURNS_BY_LOBBY`, static `Match.turns` set by `start`. `results()` gives `by.finish` 1 to the first finisher only. Setup defaults to 4 players and stops at 3. `Challenge` returns `{opponent, stake: Challenge.WALK}` for a walk away; `Board.land` ends the space with nothing given. A headless `-s` script can't see autoloads in `_init`; use `_process`. Running the board as a child of a driver scene works for forcing a challenge.
- **Board (part 29):** `BoardRoller` rolls `kinds` per stretch at runtime; `Match.start` seeds `Match.board_rng` (`-- --seed N` replays) and keeps `Match.board_kinds`; `Board._enter_tree` calls `BoardPath.configure(size, kinds)` (which calls `BoardLayout.configure`) before camera and scenery. Kinds: `p` pong, `u` sumo, `e` head_soccer, `w` tug_of_war, plus the old quick ones; the graveyard and church path have minigames too. Icons `pong`, `sumo`, `head_soccer`, `tug_of_war` (with `_rim`, baked by `make_outlines.py`); all share the purple token. Intro glide is `min(7.5, width / 2100)` s. `BoardPath` holds `_nodes`, `_stretch_ids`, `_kinds` statics; `next(id)` gives the following ids (two at a fork), `routes()` every way. The branch arrows have no icon list (the plan assumed one). "Play again" to a new size was not played, only tested headless.
- **Powers (part 30):** `Match.roll_bonus`, `max_blood`/`min_blood`, `blood_is_safe`, `duel_result` (returns `free`), `Duel.swap_wins`/`roll_rounds(stake, swap_wins)`. `PowerPop.show_over(parent, at, text, scale)` is the pop; `Hud.portrait_node(player)` gives a portrait to fly blood to or tint. `Board._play_turns` is the turn loop: glide, die, walk `face + bonus`, `land` or `finish`, then `Match.next_player()`. Strings `POWER_*` and `POP_*`. Not seen by eye: the Turkish power lines, the "Easy!" pop, Death's challenge pop.
- **Powers II (part 31):** `BoardPath.nearby(id)` (with `previous(id)`, a reverse map built in `_link`) gives the space and one behind and ahead; the start and the finish are never nearby. `Match` players carry `stone` and `just_missed`; `nearby_players`, `drain` (returns the victims), `petrify` (returns who turned), and the skip lives in `next_player`, which cracks a stone player, sets `just_missed` (cleared when that player's next real turn ends) and records them in `Match.cracked` (`take_cracked()` hands them to the board). `Board.land` runs `_power_drain` / `_power_stone` before the space; `_play_turns` runs `_crack` for each cracked player after `next_player`. `BoardPiece.set_stone`, `HudPortrait.set_stone` (the grey shader) and `Hud.set_stone` do the grey; no extra rim was drawn, since the piece's own baked cream outline greys with the body. Strings `POP_DRAIN`, `POP_STONE`, `POP_CRACK`. Checked headless (nearby at a fork and a join, drain, petrify, skips with 8 players, last turn) and in a plain run, 25 FPS. The real turn loop with a forced Medusa was not played through; the crack was driven the way the loop does it. Not seen by eye: the Turkish pops.
- **Online spike (part 32):** throwaway, on `part-32-online-spike`. `tools/relay/` is a Cloudflare Worker (`src/index.js`, `wrangler.toml`, SQLite-backed Durable Object `Room`, Hibernation API) run with `npm install` then `npm run dev` (wrangler dev on port 8787), no account needed. It upgrades `/room/<CODE>`, gives each socket an id (a counter in the room's storage, so ids are never reused) and forwards JSON: client sends `{to, data}` (`to` 0 means everyone else), gets `{t: hello|join|leave|msg}`. `src/spike/spike.tscn` and `spike.gd` (code-built UI: relay URL, code, Host, Join, Leave, Ping) are reached by `-- --spike` or `?spike` on the page's address (the one hook, in `title.gd`); `?spike&relay=ws://...` changes the relay. A "Web" preset was added to `export_presets.cfg` (no threads). **Protocol decided: our own JSON over `WebSocketPeer`**, not Godot's multiplayer protocol; I didn't try the forwarder, because the Godot client expects a Godot server to assign ids and relay for it, so a pure forwarder would have to imitate that handshake for no gain; parts 38 to 40 write their own small RPC layer (the host runs the rules, so it is a few message kinds). **Checked in Playwright on `localhost`:** two tabs exchange ping and pong; a third joining sees both; leaving and rejoining the same code works (new id). Relay alone, Node to Node: median 9 ms, worst 17 ms for a round trip over `wrangler dev`. In the game the ping shows 11 to 55 ms, because replies wait for the next 25 FPS frame (up to 40 ms each way), and a tab in the background answered in 130 to 600 ms (the browser throttles it), so **an online player's tab must stay in front, and timers must not depend on a background tab's answers**. **Export:** only `web_nothreads_*.zip` was fetched, by HTTP range requests out of the 1 GB `.tpz`, into `%APPDATA%\Godot\export_templates\4.7.2.stable` (the full download was too slow). Web export of the whole game: `.pck` 34 MB, `.wasm` 39.5 MB (gzip 10 MB), total about 74 MB raw and about 44 MB gzipped (`python -m http.server` doesn't gzip; itch.io does). First load on localhost: canvas up in under a second, the title ready in about 5 s (wasm compile). Export takes 13 s through `tools/release/build_release.py --stage` (no MCP in the build), then `--import` and `--export-release Web`. Things learnt: Playwright keyboard input only reaches the tab in front (`bringToFront` before typing); the editor logs "Unreferenced static string" BUG lines when a headless run quits (harmless noise). **Risks for the real thing:** the itch.io iframe and its size limits (check the 74 MB against itch.io's HTML5 limits, files may need to be under 200 MB each, 1000 files), audio unlock needs a click first (the title's Play is one), `wrangler dev` is local only: the deploy, the Workers free-plan limits and the real latency from Turkey are part 38's to measure. Nothing of the spike stays except possibly `tools/relay/`.
- **Minigame frame (part 33):** `src/minigames/`: `Minigame` (base: `setup(left, right, challenger_side, edge)`, `controls()` gives `[[key ids], translation key]` lines for the keycaps, `begin()`, `finish(side)`, `finished(winner_side)` with `Minigame.DRAW` = -1 replaying the round, `active`, `color_of(side)`), `MinigameInput` (static seam: `pressed`/`just_pressed(side, key)`, `direction(side)`, keys up/left/down/right/action/special/dash; left WASD+Q E R, right arrows+K L ;; `source` Callable and `absent` sides for the network; `just_pressed` rolls once per physics frame), `Minigames.for_kind(kind)` (the `GAMES` dict is where parts 34 to 37 register their scripts; the rest play `StubGame`), and `MinigameFrame` (a CanvasLayer replacing `Duel` on the board: VS strips, keycaps, 3-2-1 with `ui_click` and `whistle`, the game in a `_stage` node, small portraits that hop and droop, a `DuelTally` and "Round n" for swaps, a draw banner, the winner banner). `play(challenger, opponent, stake, kind)` returns `{winner, loser, rounds}`; static `settled(rounds, needed)` and `edge_for(challenger)` are the testable rules. The challenger is always side 0 (left). A games node draws its own table in 1920 x 1080 space around `Minigame.TABLE_CENTER` (table 1480 x 640, so y 220 to 860 clears the HUD above and the tally and banner below). Strings `KEYS_MOVE`, `MINI_GET_READY`, `MINI_DRAW`, `MINI_ROUND`. `Duel` stays only for `swap_wins`/`roll_rounds`; nothing calls its coin flip. A full-screen STOP control blocks board clicks while the frame is up. Checked headless (rounds, Hyde's edge, the two key sets apart) and in a plain run of a 3-round swap with scripted keys through `MinigameInput.source`: all three rounds, the tally and the result worked, no errors. Not played: a real keyboard through the MCP, the draw banner, Hyde's edge in a game, and the Turkish strings by eye. No game uses `edge` yet. FPS was only measured with screenshots saving, so it read low (2 to 20); the frame adds no per-frame work beyond the stub. Keyboards may ghost with two sets at once: keep each game to what two hands can do.
- **Test habit:** headless drivers for rules, plain runs with a temporary uncommitted script for screenshots and `Engine.get_frames_per_second()`; never `--write-movie`.

## Log

- **2026-10-23 to 24, Microplans 1 to 8:** the first playable, parts 1 to 24. See [microplan_first_playable.md](microplan_first_playable.md#log).
- **2026-10-24, Microplan 9:** the start of the final game, from the user's brief. Planned parts 25 to 27: the questionnaires, asset retrieval, and the camera tweak. Sketched the roadmap to part 44.
- **2026-10-24, Microplan 10:** planned parts 28 to 30: the lobby-size rules, the board for each lobby size, and the passive powers. The roadmap ends at 43 because Run n Dodge is out (part 25), and Head Soccer goes last of the four minigames (it has the most new physics).
- **2026-10-24, Microplan 11:** planned parts 31 to 33: Dracula and Medusa, the online spike, and the minigame frame. The roadmap is unchanged (still ends at 43). One change inside it: the spike (32) runs against a local `wrangler dev` relay, so the overnight automation is not blocked waiting for a Cloudflare account; the account is asked for at part 38, when the real deploy happens. The frame (33) takes the one-computer key sets as Claude's call: WASD with Q, E, R for the left player; the arrows with K, L and ; for the right.
- **2026-10-24, Microplan 12:** planned parts 34 to 36: Pong, Tug of War and Sumo, each a `Minigame` subclass plugged into `Minigames.GAMES`. The roadmap is unchanged (still ends at 43). Order: Pong, then Tug of War (smallest, tests the action key), then Sumo, whose circle physics goes into a small reusable `CirclePhysics` for Head Soccer (37). Mr. Hyde's edge is a hidden 10% in each game (paddle speed, pull strength, piece weight).
