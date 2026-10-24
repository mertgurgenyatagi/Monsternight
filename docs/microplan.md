# Microplan

The [final game](roadmap.md#2-final-game), built in parts after the first playable's 24. The numbers go on from there. `/microplan` plans three parts at a time in detail, and a rough roadmap to the end (see `.claude/skills/microplan/SKILL.md`). It runs in its own session, after part 33, 36, 39 and so on.

- **The brief:** the user's direction for the final game is [final_game_brief.md](questionnaire_answers/final_game_brief.md), saved word for word. The design docs ([game_rules.md](game_rules.md), [board.md](board.md), [characters.md](characters.md), [minigames.md](minigames.md), [screens.md](screens.md), [tech.md](tech.md)) say what the final game is. Questionnaires ended at 18; the rest is Claude's call.
- **The code map:** the first playable's Part notes ("Built so far" in [microplan_first_playable.md](microplan_first_playable.md#part-notes)) describe the code as it stands, and "The code since part 24" below adds what parts 25 to 30 changed. Read the section your part touches instead of rereading the code.

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

Three parts: the last two powers (Dracula and Medusa) with their moments on the board, a throwaway online spike that finds the riskiest unknown early, and the minigame frame that every game plugs into. After part 33 the rules, the board and the powers are all in, in the hot-seat mode, and the first minigame can be built on a finished frame. Duels stay the coin flip until the frame is in.

### Part 31: Powers II, Dracula and Medusa

**Goal:** when Dracula lands, he drains 1 blood from each player nearby and the blood flies to him; when Medusa lands, each player nearby turns to grey stone and misses their next turn, with the stone cracking off on their turn. Both fire before the space they land on.

**Builds:**
- **`BoardPath.nearby(id)`** (new, static): the ids that count as nearby for a landing on `id`: the space itself, one behind and one ahead, following the road (`characters.md#nearby`). At a fork, "ahead" is the first space of both paths; where the paths join, "behind" is the last space of both. A reverse map (`_previous`, built with `_nodes`) gives "behind"; `next(id)` gives "ahead". The START and FINISH nodes are not nearby for anyone (they are safe).
- **`Match`:**
  - `nearby_players(player)`: the other players whose `space` is in `BoardPath.nearby(player.space)`, skipping the finished and those still on the start. Called only for a landing from a roll (the board calls it; a swap never does).
  - Dracula: `drain(player)` returns the victims (blood 2 or more), lowers each by 1 through `change_blood` (so Death's floor and caps hold), and gives Dracula +1 each up to `max_blood`. The steal happens at full blood: victims lose, Dracula stays.
  - Medusa: `petrify(player)` marks every nearby player `stone = true`, except one with `just_missed` set (nobody misses two turns in a row). `next_player()` consults it: a stone player's turn is skipped for roll, move and space, the stone is cleared, `just_missed` is set and cleared once that player has moved. The turn counter and `_last_turn` follow the skip as a normal turn; check an 8-player game where several are stoned at once.
- **`Board.land`:** before the space's own effect, Dracula's `_power_drain` and Medusa's `_power_stone` run (only when the landing came from a roll, which `_play_turns` knows).
- **Dracula's moment:** a "Drain!" `PowerPop` over Dracula; for each victim a `PowerPop` "-1" is not needed (the blood drop leaving is the sign); the drops fly from the victim's HUD portrait to Dracula's, as every blood flight does (`Hud` already animates a blood change). The victims' pieces recoil with `PaperMotion.tilt`.
- **Medusa's moment:** "Stone!" over each victim's piece, the piece turns grey (a modulate tween; the piece's shadow stays), with no new art: tint the piece's own portrait grey and add a flat grey paper rim. `Sound.play("stone")` for the turn to stone and `stone_crack` on the victim's turn, where the grey flakes off (a quick scale pop and the tint returning) and a banner-less "Free!"-style pop shows "Crack!". Stone players keep being valid duel targets.
- **HUD:** a stone player's portrait gets the same grey tint, so the whole table sees who misses a turn.
- Strings (English and Turkish): `POP_DRAIN`, `POP_STONE`, `POP_CRACK`.

**Polish:**
- The stone arrives in a short beat: Medusa's pop, then the victims go grey one after another (a tiny stagger so they never change together), each with a squash.
- The crack is a small shake, a flash of the old colour, and the turn glides on without the die.
- Dracula's drops fly in a stagger, and the camera stays on him.
- The sounds `stone` and `stone_crack` have their trims set (done in part 30); `power` for the pops.

**Assets:** none new. `power.ogg`, `stone.ogg` and `stone_crack.ogg` exist; the grey is a tint of existing art.

**Check:**
- Headless: `BoardPath.nearby` at a normal space, a fork, a join, the start and the finish, for sizes 3 and 8; Dracula steals from two nearby players, not from one with 1 blood, and stays at 3 when full; Death's victim never drops below 1; Medusa stones nearby players and not a `just_missed` one; `next_player` skips a stone player once and never twice in a row; a swap never fires either power.
- A plain 8-player run with Dracula and Medusa forced next to others (set `space` directly): both powers fire before the space, the stone cracks on its turn, 25 FPS. No errors or warnings.
- Screenshots: Dracula's drain with the flying drops, Medusa's stoned pieces, the crack.

**Risks:** the turn loop (`Board._play_turns`) is where skips live: keep the skip inside `Match.next_player`, not in the loop, so a future online host runs the same rule. A stone player standing on a fork is still "nearby" for the next landing.

### Part 32: The online spike

**Goal:** prove the riskiest unknown: two browser tabs, one Cloudflare-style WebSocket relay, one tiny Godot web build in which a room code connects the tabs and a click in one shows up in the other, with the measured round-trip. Throwaway code on its own branch: nothing of it stays unless part 38 reuses a piece.

**Builds:**
- **The relay** in `tools/relay/` (new): a Cloudflare Worker with one Durable Object per room, WebSocket Hibernation API. It accepts a socket on `/room/<code>`, tells each peer its id and the peer list, and forwards a message to one peer or to all. The spike runs it **locally with `wrangler dev`**, so it needs no Cloudflare account yet (an account is only needed to deploy, part 38; ask the user for it then, with which friends test). `wrangler` is run with `npx`. Do not install anything global.
- **A throwaway scene** `src/spike/spike.tscn` (not on the title): a code field, Host/Join, a list of peers, and a button that sends "ping" with a timestamp to everyone, plus the reply's round-trip in ms. Godot side: `WebSocketMultiplayerPeer`, the relay speaking the Godot multiplayer protocol as a pure forwarder if that is tractable, otherwise a tiny hand-made JSON protocol over `WebSocketPeer` (the spike decides, and writes down which).
- **The web export:** install the web export templates if missing (see `docs/tech.md`; the Windows templates were also missing at part 24), export the spike without threads, and serve it with `python -m http.server`. Two Playwright tabs open it, join one room and exchange pings. A report in the Part notes: what worked, what was slow, the measured round trip on localhost, and the risks for the real thing.
- A short decision note in `docs/tech.md`: the protocol chosen, how big the export is, and the load time.

**Polish:** none; it is a spike. Keep it ugly and small, and never touch the real game's scenes except the one test hook that opens the spike scene.

**Assets:** none.

**Check:** two Playwright tabs on `localhost` exchange a ping and a pong through the local relay; a third joining the same code sees both; leaving and rejoining the room with the same code works. The web export's file size and first-load time are noted.

**Risks:** the export templates may not install (large download: ask the user before downloading if it fails or is blocked); a browser build may behave differently from the editor's run (audio unlock, input focus). If the Godot multiplayer protocol is not feasible over a plain forwarder, the fallback is a JSON protocol and an RPC layer of our own. That decides how parts 39 and 40 are written, so record it.

### Part 33: The minigame frame

**Goal:** a minigame space now takes you from the challenge to a VS card, into a (stub) minigame that plays a full round for two chosen players with real keyboard input, and back to the board with the result applied. The coin-flip duel is gone. Everything every game needs is in the frame, so parts 34 to 37 each add only a game.

**Builds:**
- **`Minigame`** (new base class, `src/minigames/minigame.gd`): what a game implements. `setup(left_player, right_player, challenger_side, edges)` places the two; `read_input(side)` comes from the seam below; the game emits `finished(winner_side)` (or `draw`, which replays the round, per `minigames.md#draws`). Mr. Hyde's edge arrives as an `edge` number (0 or about 0.1) that each game's part applies.
- **`MinigameInput`** (new, the seam): the games read the two sides' keys only through it (`MinigameInput.pressed(side, key)` for arrows, A, S, D; and `just_pressed`). In the one-computer mode it maps two keyboard sets: the left side uses **W A S D** as up, left, down, right plus **Q** (action), **E** (special), **R** (dash); the right side uses the **arrow keys** plus **K**, **L**, **;**. (Claude's call, `minigames.md#controls`: the fixed key names A, S, D describe the online keys; one computer needs two sets.) Later, the network feeds the same calls. An absent side reads as nothing pressed.
- **`MinigameFrame`** (new scene, `src/minigames/minigame_frame.tscn`): on a minigame space, after `Challenge` returns, the board hands the pair and the stake to the frame, which shows the VS card (two portraits, names, the stake), the instructions (the game's key line for each side, 2 s), a 3-2-1 countdown with `ui_click` ticks and `whistle`, the game, then the result: the winner's pop and the loser's, `whistle`, and back to the board. The frame returns `{winner, loser}`, and `Board` applies it with the existing `duel_end` path. The frame is a layer above the board, which keeps its place (the camera stays; only the table is covered, like a curtain).
- **The stub game** `src/minigames/stub_game.gd` (a throwaway square on a table that the two sides move, first to touch a flag wins), so the frame is checked end to end. Parts 34 to 37 replace it kind by kind through a table `Minigames.for_kind(kind)` (`pong`, `sumo`, `head_soccer`, `tug_of_war`); until a game exists, its kind uses the stub.
- **Everyone watches:** the frame draws the table the same for the two players and anyone else, from the game's state (no input from watchers), so online can send state to watchers later. The watchers' view is the same node tree; in the local mode there are no extra watchers.
- **Mr. Hyde's hook:** the frame passes `edge = 0.1` when the challenger is Mr. Hyde, and 0 otherwise.
- **Swap handicap rounds:** a swap duel is several rounds (`Duel.roll_rounds` was a stand-in): the frame plays rounds until the challenger has won 3 before losing 1 (Dorian: 1), showing a tally between rounds. `DuelTally` (`src/board/duel_tally.gd`) already draws this; check it fits.
- **`Duel`** (the coin flip) stays as the code for the `roll_rounds` maths and the tests, but nothing calls its coin flip on the board any more.
- Strings (both languages): the VS card's key lines, "Get ready", "Draw, again!".

**Polish:**
- The VS card slams in as two torn paper strips from the sides (`PaperMotion.pop_in`/`tilt`), with the portraits wobbling; the instructions line shows each side's keys as small paper keycaps.
- The countdown numbers pop and fade with the `ui_click`, then `whistle`; the stub's end has the winner's portrait jump and the loser's slump (the existing `_win_pose`/`_lose_pose` poses).
- A draw shows a short "Draw, again!" banner and replays; the round count and tally between swap rounds slide in and out.
- No music in minigames (the brief); only their own sounds.

**Assets:** `whistle`, `ui_click`, existing portraits; none new.

**Check:**
- Headless: `MinigameInput` maps both key sets to the right sides and does not mix them; the frame's round logic gives swap results like `Duel.roll_rounds` and handles draws; Hyde's edge is 0.1 only as challenger.
- A plain run with 4 players: land on a minigame space (force a kind), pick an opponent, play the stub with real key presses (MCP `simulate_key`, it is enough to prove the keys work), see the winner applied to coins/blood/swap. A swap duel plays several rounds with the tally. 25 FPS.
- Screenshots: the VS card, the countdown over the stub table, the result back on the board.

**Risks:** the frame sits over the board, which uses mouse clicks and the candle: make sure no board click leaks through while the frame is up. The two key sets on one keyboard can ghost (some keyboards can't register three keys at once); keep each game to what two hands can do, and note it. The seam's design decides how the online input is plugged in part 40: keep it a plain function, not a node tied to the keyboard.

## Roadmap

Very rough. The next Microplan (after part 33) rewrites it. It still ends at 43. The end may still move: the four minigames and the online parts are the big unknowns, and the spike (part 32) is where we learn how big the online part is.

25. Questionnaires 16 to 18 and the docs. (done)
26. Asset retrieval. (done)
27. The camera tweak. (done)
28. The lobby-size rules, and the swap opt-out. (done)
29. The board for each lobby size, with the four minigame spaces. (done)
30. Powers I: the passive ones. (done)
31. Powers II: Dracula's steal and Medusa's stone. (done)
32. An online spike with a local relay (no Cloudflare account needed yet). (done)
33. The minigame frame.
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

### The code since part 24 (absorbed by Microplan 11)

- **Design and assets (parts 25, 26):** four minigames (Pong, Sumo, Head Soccer, Tug of War), no minigame music, no time limit, Mr. Hyde's edge only when he challenges; online play is Claude's call (`tech.md`). Images in `assets/art/minigames/`: `pong_table`, `paddle` (grey, to tint), `sumo_ring`, `goal` (faces right, mirror for the left), `ball`, `boot` (grey, to tint), `rope` (121 px tall, tiles sideways), `ribbon`. Reused: Pong's ball is `crumpled.png`, sumo pieces are tinted `space.png` with portraits, Head Soccer's heads are portraits on `boot.png`. Sounds in `assets/audio/sfx/`: `whistle`, `paddle_hit`, `bounce`, `kick`, `jump`, `sumo_bump`, `rope_pull`, `power`, `stone`, `stone_crack`, `join`, `leave`, `ready`, `start`. Lobby sounds are short synthetic blips. The rope is thin: scale it in the engine if weak. The Gemini key has no image quota; the user makes images by hand.
- **Camera (part 27):** `BoardCamera.ZOOM := 0.88` (1.0 undoes it) with `HALF_WIDTH`/`HALF_HEIGHT`. Raised-angle constants: `GROUND_Y` 750, `PROP_BASE_Y` 810, `HILL_TOP_Y` 542, `UPPER_Y` 627, `LOWER_Y` 935, `FAR_Y` 350, `WATER_Y` 670, fog bank 570, `MAIN_Y` 880. Clickable things are scaled by `1 / ZOOM`. **Known blemish:** `scenery.gd`'s `_ground_fill` stretches each ground strip's bottom rows down 200 px, leaving faint root streaks; a taller ground image would fix it. The user's verdict on the zoom (`screenshots/part_27/1.png`) was never recorded in the README, so assume it stays.
- **Rules (part 28):** `Match.MIN_PLAYERS` 3, `TURNS_BY_LOBBY`, static `Match.turns` set by `start`. `results()` gives `by.finish` 1 to the first finisher only. Setup defaults to 4 players and stops at 3. `Challenge` returns `{opponent, stake: Challenge.WALK}` for a walk away; `Board.land` ends the space with nothing given. A headless `-s` script can't see autoloads in `_init`; use `_process`. Running the board as a child of a driver scene works for forcing a challenge.
- **Board (part 29):** `BoardRoller` rolls `kinds` per stretch at runtime; `Match.start` seeds `Match.board_rng` (`-- --seed N` replays) and keeps `Match.board_kinds`; `Board._enter_tree` calls `BoardPath.configure(size, kinds)` (which calls `BoardLayout.configure`) before camera and scenery. Kinds: `p` pong, `u` sumo, `e` head_soccer, `w` tug_of_war, plus the old quick ones; the graveyard and church path have minigames too. Icons `pong`, `sumo`, `head_soccer`, `tug_of_war` (with `_rim`, baked by `make_outlines.py`); all share the purple token. Intro glide is `min(7.5, width / 2100)` s. `BoardPath` holds `_nodes`, `_stretch_ids`, `_kinds` statics; `next(id)` gives the following ids (two at a fork), `routes()` every way. The branch arrows have no icon list (the plan assumed one). "Play again" to a new size was not played, only tested headless.
- **Powers (part 30):** `Match.roll_bonus`, `max_blood`/`min_blood`, `blood_is_safe`, `duel_result` (returns `free`), `Duel.swap_wins`/`roll_rounds(stake, swap_wins)`. `PowerPop.show_over(parent, at, text, scale)` is the pop; `Hud.portrait_node(player)` gives a portrait to fly blood to or tint. `Board._play_turns` is the turn loop: glide, die, walk `face + bonus`, `land` or `finish`, then `Match.next_player()`. Strings `POWER_*` and `POP_*`. Not seen by eye: the Turkish power lines, the "Easy!" pop, Death's challenge pop.
- **Powers II (part 31):** `BoardPath.nearby(id)` (with `previous(id)`, a reverse map built in `_link`) gives the space and one behind and ahead; the start and the finish are never nearby. `Match` players carry `stone` and `just_missed`; `nearby_players`, `drain` (returns the victims), `petrify` (returns who turned), and the skip lives in `next_player`, which cracks a stone player, sets `just_missed` (cleared when that player's next real turn ends) and records them in `Match.cracked` (`take_cracked()` hands them to the board). `Board.land` runs `_power_drain` / `_power_stone` before the space; `_play_turns` runs `_crack` for each cracked player after `next_player`. `BoardPiece.set_stone`, `HudPortrait.set_stone` (the grey shader) and `Hud.set_stone` do the grey; no extra rim was drawn, since the piece's own baked cream outline greys with the body. Strings `POP_DRAIN`, `POP_STONE`, `POP_CRACK`. Checked headless (nearby at a fork and a join, drain, petrify, skips with 8 players, last turn) and in a plain run, 25 FPS. The real turn loop with a forced Medusa was not played through; the crack was driven the way the loop does it. Not seen by eye: the Turkish pops.
- **Online spike (part 32):** throwaway, on `part-32-online-spike`. `tools/relay/` is a Cloudflare Worker (`src/index.js`, `wrangler.toml`, SQLite-backed Durable Object `Room`, Hibernation API) run with `npm install` then `npm run dev` (wrangler dev on port 8787), no account needed. It upgrades `/room/<CODE>`, gives each socket an id (a counter in the room's storage, so ids are never reused) and forwards JSON: client sends `{to, data}` (`to` 0 means everyone else), gets `{t: hello|join|leave|msg}`. `src/spike/spike.tscn` and `spike.gd` (code-built UI: relay URL, code, Host, Join, Leave, Ping) are reached by `-- --spike` or `?spike` on the page's address (the one hook, in `title.gd`); `?spike&relay=ws://...` changes the relay. A "Web" preset was added to `export_presets.cfg` (no threads). **Protocol decided: our own JSON over `WebSocketPeer`**, not Godot's multiplayer protocol; I didn't try the forwarder, because the Godot client expects a Godot server to assign ids and relay for it, so a pure forwarder would have to imitate that handshake for no gain; parts 38 to 40 write their own small RPC layer (the host runs the rules, so it is a few message kinds). **Checked in Playwright on `localhost`:** two tabs exchange ping and pong; a third joining sees both; leaving and rejoining the same code works (new id). Relay alone, Node to Node: median 9 ms, worst 17 ms for a round trip over `wrangler dev`. In the game the ping shows 11 to 55 ms, because replies wait for the next 25 FPS frame (up to 40 ms each way), and a tab in the background answered in 130 to 600 ms (the browser throttles it), so **an online player's tab must stay in front, and timers must not depend on a background tab's answers**. **Export:** only `web_nothreads_*.zip` was fetched, by HTTP range requests out of the 1 GB `.tpz`, into `%APPDATA%\Godot\export_templates\4.7.2.stable` (the full download was too slow). Web export of the whole game: `.pck` 34 MB, `.wasm` 39.5 MB (gzip 10 MB), total about 74 MB raw and about 44 MB gzipped (`python -m http.server` doesn't gzip; itch.io does). First load on localhost: canvas up in under a second, the title ready in about 5 s (wasm compile). Export takes 13 s through `tools/release/build_release.py --stage` (no MCP in the build), then `--import` and `--export-release Web`. Things learnt: Playwright keyboard input only reaches the tab in front (`bringToFront` before typing); the editor logs "Unreferenced static string" BUG lines when a headless run quits (harmless noise). **Risks for the real thing:** the itch.io iframe and its size limits (check the 74 MB against itch.io's HTML5 limits, files may need to be under 200 MB each, 1000 files), audio unlock needs a click first (the title's Play is one), `wrangler dev` is local only: the deploy, the Workers free-plan limits and the real latency from Turkey are part 38's to measure. Nothing of the spike stays except possibly `tools/relay/`.
- **Test habit:** headless drivers for rules, plain runs with a temporary uncommitted script for screenshots and `Engine.get_frames_per_second()`; never `--write-movie`.

## Log

- **2026-10-23 to 24, Microplans 1 to 8:** the first playable, parts 1 to 24. See [microplan_first_playable.md](microplan_first_playable.md#log).
- **2026-10-24, Microplan 9:** the start of the final game, from the user's brief. Planned parts 25 to 27: the questionnaires, asset retrieval, and the camera tweak. Sketched the roadmap to part 44.
- **2026-10-24, Microplan 10:** planned parts 28 to 30: the lobby-size rules, the board for each lobby size, and the passive powers. The roadmap ends at 43 because Run n Dodge is out (part 25), and Head Soccer goes last of the four minigames (it has the most new physics).
- **2026-10-24, Microplan 11:** planned parts 31 to 33: Dracula and Medusa, the online spike, and the minigame frame. The roadmap is unchanged (still ends at 43). One change inside it: the spike (32) runs against a local `wrangler dev` relay, so the overnight automation is not blocked waiting for a Cloudflare account; the account is asked for at part 38, when the real deploy happens. The frame (33) takes the one-computer key sets as Claude's call: WASD with Q, E, R for the left player; the arrows with K, L and ; for the right.
