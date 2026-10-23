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

If a part turns out too big, split it (7a, 7b) instead of rushing it.

## Parts

All three stay in part 6's **side view**. The high camera was tried and reverted (see README), so don't bring it back.

### Part 7: The board path

**Goal:** The road is laid out across the board, from a start token in the village to the castle gate. There are 42 spaces on the shortest way, both splits with their signposts, paper scraps between the spaces, and a flag at the gate. Every space shows what it does at a glance. Nothing moves along it yet.

**Builds:**
- **`BoardPath`** (`src/board/board_path.gd`, static like `BoardLayout`): the path as rules data, which `Match` and the board both read.
  - Each node has an id, a world position, a lane, a kind, and `next`: one id, or two at a fork, upper path first.
  - The kinds: `start`, `coin`, `spikes`, `thief`, `church`, `pong`, `haxball`, `racing`, `fps`, and `finish`.
  - The type sequence is written out by hand in one const, so the board is the same every match. The positions come from `BoardLayout`. Space the nodes evenly along each lane's curve, not just along x, so the ramps don't bunch them up.
  - Calls: `node(id)`, `start()`, `finish()`, `next(id)`, `is_fork(id)`.
- **The start** is a node before the first village space: a plain paper token with no icon and no tint. Players begin here and come back here when they die. It isn't counted among the spaces.
- **The finish** is a node at `BoardLayout.gate_x()`, in front of the gate. Any roll that reaches it counts (part 17). It isn't counted among the spaces either.
- **The space mix** (board.md and game_rules.md: about 3 quick spaces for every 2 minigame spaces):

  | Stretch | Spaces | Quick | Minigame |
  |---|---|---|---|
  | Village | 9 | 5, one of each kind plus one more | 4: Pong, Haxball, racing, FPS |
  | Graveyard (lower) | 6 | 4: 2 spikes, 2 thieves | 2 |
  | Church (upper) | 10 | 6: 3 churches, 3 coins | 4 |
  | Forest | 9 | 5 | 4: one of each |
  | Boardwalk (upper) | 7 | 4: one of each | 3: Pong and Haxball only |
  | Bog (lower) | 7 | 4: one of each | 3: racing and the FPS only |
  | Castle | 11 | 7 | 4: one of each |

  Claude's choices for the order: the first village space is a quick space, never two identical spaces in a row, and the minigames outside the second split come out even across the four games. No sword fight spaces yet.
- **The forks:** the last village space forks to the church (upper) and the graveyard (lower). The last forest space forks to the boardwalk (upper) and the bog (lower). Each pair joins again at the next stretch's first space.
- **The space view** (`src/board/space.gd`). The user chose this look on 2026-10-23:
  - `space.png` lies **flat on the ground**: squashed into an oval, as seen from a low angle. Try a y-scale of about 0.45 and judge it in a screenshot.
  - Its **icon stands up on it** like a small cutout, with its base on the middle of the oval.
  - The token is tinted by its kind. Each quick space takes its icon's color: gold for coin, steel for spikes, grim green for thief, and warm candle-cream for church. All four minigame spaces share one tint, a deep violet, so a duel space reads as one thing, and the icon tells which game. Claude picks the exact colors, and they must stand out from every location's ground.
  - Monsters stand on the token in part 8 and may cover the icon. That's fine.
- **Path dots:** three `path_dot.png` scraps between each pair of neighbouring spaces, following the lane's curve. Each has a slightly different rotation and size, from a fixed seed, so they look hand-laid but are the same every match.
- **Signposts:** `signpost.png` stands just behind the road between the fork's space and the two paths, in the lane layer, behind the tokens. The arrows are part 13's.
- **The flag:** `flag.png` planted at the finish, beside the gate.
- **The node order:** the path goes in `Lanes`, after the ground strips and before the props in front, so it's under the foreground fog (part 6 notes). Add a y-sorted `Pieces` node above the path and empty for now. Part 8 puts the monsters in it, so a piece on the lower lane draws in front of one on the upper lane.
- **Lane heights, carried over from part 6:** the lower lane at y 990 runs over the soil and roots, low on the screen. Retune `BoardLayout`'s `MAIN_Y`, `UPPER_Y` and `LOWER_Y` so that every space sits on a visible walking surface: the grass, the stone road, the boardwalk, or the bog's mud, never the soil or the water. Leave room for a 200 px tall monster above each space, and keep everything clear of the top 220 px, where part 9's portrait strip goes. The props follow the layout, so they move with it.
- **Props off the path:** no prop in the lane layer may stand in front of a token. Move any lamp, stone, reed or torch that does, through `scenery.gd`'s layout code, never by hand.

**Polish:**
- The icons breathe: each one rises and sinks a few pixels on its base, slowly and out of step with the others, stepping at 25 FPS.
- The minigame icons tilt a little now and then, like something about to start.
- The church icon's space has a faint, warm `Glow` pulse. The coin icon glints now and then with a quick squash. Spikes and thief stay still apart from the breathing, so the good spaces look inviting and the bad ones look still and wary.
- Path dots get no motion. They're the quiet part.
- The flag flutters: a small, uneven skew from its pole, like `Flame`'s flicker but slower.
- The signposts creak very slightly: a slow sway of under a degree, from their base.
- Every token, icon, signpost and the flag gets `PaperShadow`. A token's shadow is small and close, because it lies on the ground.
- The intro glide (part 6) already passes over the whole path, so the path is simply there. It doesn't animate in.

**Assets:** `board/space.png`, `path_dot.png` and `signpost.png`; `icons/coin`, `spikes`, `thief`, `church`, `pong`, `haxball`, `racing`, `fps` and `flag`. Nothing missing, and no new sounds.

**Check:**
- In the log, print each stretch's space count and kinds. The way through the graveyard must be 42 spaces and the way past the church 46, plus the start and the finish.
- Walk `BoardPath` from the start to the finish by every route in a script, and check that both ways at each fork join again.
- Save one screenshot of each location from the viewport, with the camera moved there by a script. The graveyard and swamp shots must show both paths of their split. Check that no space sits on the soil or the water, and that no prop covers a token.
- Check that it still runs at 25 FPS during the intro glide.

**Risks:**
- Flat ovals can look like holes or like stickers on the screen if the tint and shadow are wrong. Compare a few y-scales in one contact sheet before choosing.
- Spaces on the steep part of the church hill may tilt or bunch up. If the ramp is too steep for even spacing, lengthen it in `BoardLayout`.
- Moving the lanes may move props into the sky or into each other. Look at every location again after any change.

### Part 8: Monster pieces

**Goal:** When the intro glide ends, every player's monster drops onto the start on its paper stand. Pieces hop space by space along the path, the camera follows the one that's moving, and pieces that share a space stand together in a small crowd. A script drives the moves for now. The die comes in part 10.

**Builds:**
- **`Match`:** each player gets `space`, the `BoardPath` id they stand on, starting at `BoardPath.start()`. Add `Match.move_to(player, id)` as the one rules call that changes it. Blood and coins come in part 9.
- **`BoardPiece`** (`src/board/board_piece.gd`): the monster's body (`Monsters.body`) on `stand.png`, with `PaperShadow`, about 200 px tall in all. Part 5's `MonsterPiece` already builds a body on a stand. Share that code (a common base, or a helper they both call) instead of copying it. The grey-out and hover stay only on monster select's piece.
- **The pieces** go in part 7's `Pieces` node, one per player, found by `Board.piece_for(player)`.
- **Crowds:** when several pieces share a space, they spread out on it. Up to 4 stand in a row across the token, and pieces 5 to 8 make a second row a little higher and behind. Y-sorting keeps the front row in front. When a piece arrives or leaves, the others shuffle to their new spots with `move_to`.
- **Walking:** `Board.walk(player, steps) -> Signal` hops the piece from space to space. Each hop is a short arc to the next space and a squash on landing. Reuse `PaperMotion.fly_to` with a low arc, or add `PaperMotion.hop_to` if it needs its own feel. Never copy a tween.
  - **At a fork,** the walk waits on a `choose_branch(player, fork) -> Signal` hook. In part 8 it picks a random path after a short beat. Part 13 replaces that with the signpost and its arrows. Mark it clearly as the placeholder.
  - **At the finish,** the walk stops on it even if steps are left. Finishing itself is part 17.
  - The rules decide each step through `BoardPath.next`, and the piece only shows it. At the end of the walk, `Match.move_to` records where it stopped.
- **The camera follows:** `BoardCamera.follow(node)` keeps a piece near the middle of the screen with a soft lag, and `stop()` ends it. `glide_to` stays for jumps between players. The sky and the ambience already follow the camera.
- **Facing:** every piece faces right, the way the race goes. `PaperMotion.flip` already exists for when a piece first turns around, but nothing in the first playable needs that yet, so don't add facing code.

**Polish:**
- **Arriving:** when the intro glide settles on the start, the pieces drop onto it one at a time in turn order (`set_down`). Each lands with a `hop_*` sound and a squash, then shuffles into the crowd.
- Idle pieces sway gently, out of step with each other, as on monster select. A walking piece stops swaying and starts again when it lands.
- **Each hop:** a quick crouch before it leaves, a low arc, and a squash on landing, with one of `hop_1` to `hop_3`. Never the same sound twice in a row. Leave a beat of about 0.12 s between hops, so a roll of 6 can be counted by ear.
- **The last hop** of a walk lands a touch heavier: a bigger squash and a little settle.
- Hops up or down a split's ramp follow the lane, so a piece climbing the church hill visibly climbs.
- The camera eases in behind a piece that starts walking. It never snaps.
- A piece leaving a crowd steps out of it before its first hop, and the crowd closes up behind it.

**Assets:** `monsters/` (all 8 bodies and `stand.png`); `sfx/hop_1`, `hop_2` and `hop_3`. Nothing missing.

**Check:**
- With 2 and with 8 players, see all pieces drop onto the start after the glide, and the 8-player crowd stays readable.
- With a temporary script (not committed), walk players in turn by random steps of 1 to 6 until everyone reaches the finish. Check in the log that `Match` agrees with where each piece stands, that both forks get taken, and that walks stop at the finish.
- Make one contact sheet from timed viewport screenshots of a 6-space walk up the church hill.
- Check that it runs at 25 FPS with 8 pieces swaying and the camera following.

**Risks:**
- Foreground fog over the village and swamp may hide the pieces. If it does, thin the fog over the lanes. Don't drop it.
- An 8-piece crowd on one oval may spill onto the path dots or the next space. Pieces may overlap each other a little, like a real crowd of game pieces, but the crowd must stay on its own space.

### Part 9: The HUD

**Goal:** Along the top of the board, a strip of paper portraits shows every player in turn order, with their name, blood drops and coins. The active player's portrait is raised, a finished player's portrait gets a flag, and "Turn 1 of 12" sits in a corner. Every change to blood or coins is animated, ready for the spaces and duels to use.

**Builds:**
- **`Match`:** each player gets `blood` (3) and `coins` (0). Add `Match.turn` (starting at 1), `const TURNS := 12`, and two rules calls: `change_blood(player, delta)`, kept between 0 and 3, and `change_coins(player, delta)`, never below 0. Each returns the change that really happened. Dying at 0 blood is part 12, not here.
- **`Hud`** (`src/board/hud.gd`, its own scene on a `CanvasLayer` over the board and under Settings), with:
  - `set_active(player)`, `set_finished(player)` and `set_turn(n)`.
  - `show_blood(player)` and `show_coins(player)`, which animate the portrait to match `Match`. The rules change `Match` first, then the board tells the HUD.
  - `anchor(player, "blood" | "coins") -> Vector2`, the screen position of that counter. Part 11's icons and part 16's flying coins and blood aim at it.
- **`HudPortrait`:** `portrait_frame.png` tinted in the monster's color, with `Monsters.portrait` inside it. Under the frame is the name in the body font. Under the name is a row of three `blood.png` drops, and next to it `coin.png` with the count in the display font. A lost drop is an empty dark outline (the same drop, darkened and faded), so the player can always count to three.
- **The layout:** centred along the top, in turn order. Eight portraits must fit across 1920 px, with the turn counter clear of them, at about 190 px each. The strip stays inside the top 220 px that part 7 keeps clear. It sits where the pregame's card strip ended (y about 105), so the board picks up where monster select left off.
- **The turn counter:** a small `panel.png` tag in the top-left corner, with "Turn 1 of 12" in the display font. The text goes in `locale/strings.csv` (`TURN_COUNTER`), as every player-facing string does. The file only has English so far.
- **When it appears:** after part 8's pieces have landed on the start, the HUD comes in.

**Polish:**
- **Coming in:** the portraits drop in one after another from left to right (`drop_in`), and the turn counter slides in from the left after them.
- Each portrait hangs and sways very slightly, out of step with the others, like a card pinned at the top.
- **The active portrait** drops lower than the others with `lift`, its frame's color brightens, and its sway stops. The one before it rises back into line at the same time. Silent: part 10's `turn_start` chime goes with it.
- **Losing blood:** the drop falls off the portrait, shrinks, and fades as it falls, with `blood_lose`. Its empty outline stays behind. The portrait gives a small `shake`.
- **Gaining blood:** the outline fills with a `pop_in` and `blood_gain`.
- **Coins:** the count ticks one coin at a time, never jumping. Each tick plays `coin_gain` or `coin_lose` and squashes the coin icon. Big changes tick faster, so no count takes more than about 1 s.
- **Finishing:** `flag.png` pops in on the portrait's corner and flutters like part 7's flag. The portrait greys a little, the same way a taken monster does in monster select (reuse `grey.gdshader`), so it reads as "out of the race".
- **A new turn:** the counter's number flips (`PaperMotion.flip` with `flip`) to the next one. On the last turn the tag turns blood red, ready for part 18's `sting_final_turn`.
- The HUD doesn't move with the camera, and the board's fog stays under it.

**Assets:** `ui/portrait_frame.png` and `panel.png`; all 8 `monsters/*_portrait.png`; `icons/blood`, `coin` and `flag`; `sfx/blood_lose`, `blood_gain`, `coin_gain`, `coin_lose` and `flip`. Nothing missing.

**Check:**
- With 2, 5 and 8 players, the strip fits, the names are readable, and the counter doesn't touch it.
- With a temporary script (not committed), go through the active player, lose and gain blood (including trying to go above 3 and below 0), gain 7 coins and lose 3, finish a player, and move to turn 12. Check that `Match` and the HUD agree in the log after each step.
- Make one contact sheet from timed viewport screenshots of the blood, coin and flag animations.
- Use the MCP's clicks to check that the HUD doesn't swallow clicks meant for the board below it. Part 14 will make the portraits clickable.

**Risks:** Turkish names with tall letters (Ğ, İ, Ş) under small portraits may clip. Test one, like "Ayşegül".

## Roadmap

Rough past part 9. Parts 1 to 6 are done (see the Log).

7. The board path: `BoardPath`, the start, the spaces lying flat with standing icons, path dots, signposts, the flag at the gate, and retuned lane heights.
8. Monster pieces: the stand and shadow, crowds on a space, walking and hopping, a random placeholder at forks, and the camera following.
9. The HUD: the portrait strip with blood and coins, the raised active portrait, the flag for finished players, and the turn counter.
10. The die and the turn loop: roll, walk, `turn_start`, the 5 s candle, and moving on to the next player and turn.
11. Quick spaces: coin, spikes, thief and church, with their sounds and icons flying to the HUD.
12. Death and respawn (crumple, fly to the start, unfold), and the board music following the leader.
13. Splits: signpost arrows and the 10 s candle, replacing part 8's random placeholder.
14. Challenge: pick an opponent's portrait, then a stake card, with invalid stakes greyed out and the 20 s candle.
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

### Part 7 notes (the board path)

- **Built:** `BoardPath` (`src/board/board_path.gd`: `node`, `start`, `finish`, `next`, `is_fork`, `ids`, `stretch`, `routes`, `report`), `BoardPathView` (`path_view.gd`: the road strip, dots, signposts, spaces and the flag), `Space` (`space.gd`), `Flag` (`flag.gd`, reusable by the HUD) and `PaperMotion.breathe` and `tilt`. The board scene adds the path and an empty y-sorted `Pieces` node to the Lanes layer after the scenery. Routes: 42 spaces through the graveyard, 46 past the church, both forks rejoin (checked in a script).
- **Changed by the user during the build:**
  - **Two of every three spaces are empty:** a plain token, kind `empty`, where nothing happens. Per stretch, filled spaces are village 3, church 3, graveyard 2, forest 3, boardwalk 2, bog 2, castle 4. The microplan's mix table is replaced by the `kinds` strings in `BoardPath`. Outside the second split each minigame appears once; the graveyard has none. Parts 11 and 16 treat `empty` as "nothing happens".
  - **Contrast:** the token and icons are baked with outlines (`tools/images/make_outlines.py`: dark rim on the token, cream rim on icons), the token is lifted brighter, a dark strip of road runs under the spaces, the far and mid layers and the ground are dimmed (`scenery.gd`'s `DIM`), and the foreground fog is halved. **Part 8 should give the monsters a cream outline the same way** (bake it, don't use a shader: a custom canvas shader came out darker and without an outline here).
  - **Icon look:** icons are about 108 px, stand a little below the token's middle on a small dark pool, and are the same size whatever the kind (the coin and FPS icons are scaled down).
- **Layout changes:** the lanes are now `MAIN_Y` 880, `UPPER_Y` 650 and `LOWER_Y` 930. The hill moved up (`HILL_TOP_Y` 565) so the church spaces stand on grass. The swamp got `pad: 2.0` spaces of width, so its ramps lie outside its spaces. The board is 440 px longer; the gate is at x 11612.
- **Token size:** 165 × 73 px, with 220 px between spaces, so the gap holds three small dots. An 8-monster crowd (part 8) has to fit on that.
- **Unchanged:** the finish token is plain like an empty space; the flag beside the gate marks it. Reeds in the swamp sit behind the bog's tokens, never in front.
- **Checked:** 25 FPS during the intro glide; screenshots in `screenshots/part_07/`.

### Part 8 notes (monster pieces)

- **Built:** `MonsterFigure` (`src/data/monster_figure.gd`: the body on its stand with shadows, shared by `MonsterPiece` and the new `BoardPiece`), `BoardPiece` (`src/board/board_piece.gd`: sway, `walked` and `branch_chosen` signals), `PaperMotion.hop_to`, `BoardCamera.follow`, and in `Board`: `piece_for`, `walk`, the placeholder `choose_branch`, crowds and the arrival drop (`pieces_landed` signal). `Match` players now have `space` (starting at `BoardPath.START`) and `Match.move_to`. `Sound.play("hop")` never repeats a hop twice in a row.
- **Outlines:** as part 7's notes asked, the monsters and the stand are baked with a cream outline (stand: dark) by `tools/images/make_outlines.py` into `monsters/<id>_rim.png` and `stand_rim.png`: bodies 182 px tall, stand 66 px wide.
- **Crowds:** 4 to a row, 52 px apart, the front row 16 px below the token's middle; each row behind stands 34 px higher, and even-sized back rows shift half a step so heads show between the front ones. Eight pieces overlap a lot but stay on their token.
- **Walking:** each hop is a 0.07 s crouch, a 0.27 s arc, a squash, then a 0.12 s beat. A piece steps out to the token's front before its first hop. Only the last hop of a walk joins the crowd, and a walk stops at the finish. `Match.move_to` is called at the end of the walk. After it the camera glides onto the piece.
- **Camera:** `follow(node)` lags softly, eases in over 0.7 s and is capped at 2600 px/s; `stop()` and `glide_to` end it.
- **Checked:** 8 players all walked to the finish with random rolls (13 rounds): `Match` agreed with every piece, both forks were taken both ways, no piece strayed from its space. 2- and 8-player landings and a 6-space hill climb are in `screenshots/part_08/`. The frame rate stays at 25 between screenshots; it only dipped while the test script saved PNGs.
- **Not checked:** the Godot MCP was connected only late in the session, and nothing in this part needs its clicks, so it was used just to run the game and read errors. The hop sounds and the feel of the squashes have not been listened to or judged by the user.

### Built so far (parts 1 to 6, absorbed by Microplan 3)

- **Code** is in `src/`:
  - Autoloads: `Sound` (`play`, `play_music`, `play_ambience`, and `quit()`, which every way out of the game goes through so no OGG leaks), `Scenes` (`change_to`, the paper transition, the texture and the cursor), `Settings` (`Settings.open()` from anywhere), and `Match` (players in turn order, with `name` and `monster`; `roll_turn_order`, `pick_monster` and `free_monsters`).
  - `PaperMotion` holds `drop_in`, `set_down`, `lift_away`, `sway`, `sway_stop`, `pop_in`, `pop_out`, `lift`, `squash`, `slide_in`, `move_to`, `flip`, `hop`, `fly_to`, `tuck`, `shake` and `crumple`. New motion goes here.
  - Shadows: `PaperShadow.add(piece)`, which copies a sprite's region.
  - `Sky` has `tint()` and `flash()`. `bat.gd` flies across whatever is in view and has an `active` switch.
  - `src/ui/` has `PaperButton`, `PaperSlider`, `PaperToggle`, the `Candle` (`start`, `stop`, `timed_out`, `time_left`) and `Flame` (`sputter`, `snuff`, `light`).
  - `Monsters` (`src/data/monsters.gd`) is the one place for a monster's look: `name_key`, `color`, `body`, `portrait` and `voice`.
  - `src/pregame/`: the turn order roll and monster select in one scene, `PlayerCard`, and `MonsterPiece` with `grey.gdshader`. It ends with `Scenes.change_to` the board.
  - `src/board/`: the board scene with the intro glide (a click skips it) and location tracking, `BoardLayout` (locations, `lane_y`, `gate_x`, `layer_x`), `BoardCamera` (`glide_to`, `jump_to`, `center_x`), `scenery.gd`, `strip.gdshader` and `Glow`.
- **The board's layers:** Far (scroll 0.5), Mid (0.9), Lanes (1.0) and Fog (1.2). A piece in a scrolled layer goes at `BoardLayout.layer_x(world_x, scroll)`. The world runs from 0 to 11,720 px.
- **Gotchas:**
  - A Control's `scale` can't be exactly zero (Godot clamps it to 1e-5), so use a flag, never `scale == Vector2.ZERO`.
  - `--quit-after` runs print a harmless leak of 4 objects at exit, because the window's close request can't be caught there.
  - Run on its own, the pregame starts a test match of the count after `--` (default 4).
- **Testing:** the Godot MCP didn't connect in parts 4 to 6, so those parts were checked with scripted input instead. Microplan 3 found the cause: another Claude session's server was holding port 6505. **The MCP is required from part 7 on.** If it acts up, kill every other Claude session and reconnect, as the README says, rather than falling back.
- **Screenshots** come from the viewport in a plain run. Never use `--write-movie` (see README).
- **Still open:**
  - There's no thunder sound and no music at all yet. `select.ogg` and the board tracks are missing, and the music just fades.
  - Nobody has listened to the ambience crossfades or the pick voices.
  - In monster select, the candle sits over the moon on the right.
  - What parts 2 and 3 left untested is on the roadmap's part 21.
  - The MCP's autoloads must be dropped from the release build, in part 23.

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
