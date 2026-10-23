# Microplan

The [first playable](roadmap.md#1-first-playable), built in about 24 parts. `/microplan` plans three parts at a time in detail, and a rough roadmap to the end (see `.claude/skills/microplan/SKILL.md`). It runs in its own session, after part 3, 6, 9 and so on.

## Building a part

One part per session, on its own branch from `development`. A part session reads `README.md`, this file, and only the docs and code its part touches.

A part is done when:

1. It runs in Godot with no errors or warnings.
2. Everything in its Polish list is in: animated, with its sounds, nothing glossed over.
3. Claude has checked it by running the game, not just by reading the code.
4. The user has seen it and approved it.
5. Its Part notes are written, and the branch is merged into `development`.

If a part turns out too big, split it (5a, 5b) instead of rushing it.

## Parts

### Part 1: Foundation and title screen

**Goal:** The game opens on the title screen. The curtain opens on the logo under a night sky, and Play, Settings and Quit wait to be clicked. Quit closes the curtain and exits. Play and Settings respond to the mouse but lead nowhere yet: parts 3 and 2 wire them up.

**Builds:**
- **First, Godot MCP.** Create `project.godot` and enable the plugin in `addons/godot_mcp/`. Register its three autoloads (`MCPRuntimeBridge`, `MCPInputBridge`, `MCPScreenshotBridge` from `addons/godot_mcp/services/`), as `../Tavernaball/project.godot` does. Open the editor in the background, and confirm the MCP tools answer before building anything else.
- `project.godot`: 1920 × 1080, stretch mode `canvas_items` with aspect `keep`, and the title as the main scene.
- **Import settings.** Run one headless import, then set the 5 ambience files to loop. Turn on mipmaps for art, because nearly everything is drawn smaller than its file and would shimmer without them.
- **Audio buses:** Music and SFX. Ambience and voices go through SFX, as Settings says.
- **`Sound` autoload.** It plays a sound effect by name, with a slight random pitch so repeats don't sound identical. It picks one of `hop_1` to `hop_3`. It crossfades music and ambience. If a music file is missing, it plays nothing and says nothing, because the music arrives later.
- **`Scenes` autoload.** Changes scenes with one paper transition used everywhere. Music keeps playing through a change unless the new scene asks for another track.
- **Translations:** `locale/strings.csv` with English, and every player-facing string goes through `tr()` from the start.
- **Theme:** both fonts, a `button.png` stretched sideways for buttons, and `panel.png` for panels.
- **The paper look:**
  - `paper_texture.png` laid faintly over everything, on a top canvas layer.
  - The skeleton-hand cursor.
  - One shared soft shadow for every piece: a darkened, offset copy of the piece behind it.
- **Paper motion library:** one shared script of reusable tweens, so every screen moves the same way. Part 1 needs the drop-in, the gentle sway, pop-in, and the hover lift with press squash. Later parts add hop, flip and crumple here, not as one-off tweens.
- **Sky:** a reusable night sky with a gradient, the paper moon, and twinkling stars. The board reuses it in part 6 with a tint for each location.
- **Title screen.** The curtain starts closed. It parts with a soft overshoot, the logo drops in and keeps swaying, and the three buttons pop in one after another. Now and then a bat flaps across behind the logo. `title.ogg` plays once it exists.

**Polish:**
- The curtain halves ease open, slowing at the end, with a little settle.
- The logo hangs and sways, never perfectly still.
- Stars twinkle out of step with each other.
- Buttons lift on hover with `ui_hover`, and squash on click with `ui_click`.
- Nothing pops into view: everything enters and leaves with motion.
- Quit closes the curtain before the window closes.

**Assets:** `ui/curtain.png`, `curtain_top.png`, `logo.png`, `button.png`, `panel.png` and `cursor.png`; `scenery/moon.png`, `star.png`, `bat.png` and `paper_texture.png`; `sfx/ui_hover` and `ui_click`; `fonts/display.ttf` and `body.ttf`; `music/title.ogg` (missing, and fine to be missing).

**Check:**
- The console run and the MCP error log show no errors or warnings.
- Use the MCP's game screenshots and simulated mouse for the hover and the clicks.
- Use `--write-movie` frames for the motion: the curtain opening and the quit.
- The game looks right in a 1280 × 720 window as well as at 1920 × 1080.

**Risks:** The MCP's three runtime autoloads mustn't ship in a release build. Note it for the final part.

### Part 2: Settings

**Goal:** Settings opens from the title as a paper panel, with music volume, sound effects volume, and fullscreen. Changes take effect at once and are remembered next launch.

**Builds:**
- **`Settings` autoload.** It loads and saves `user://settings.cfg` and applies it at startup, before the title appears.
- **The settings panel as a reusable overlay.** The title opens it now. Esc will open it over the board later, so it must not pause anything or depend on the title.
- **Paper controls:** two sliders and a fullscreen toggle.
- **Ways to close it:** a back button, Esc, or a click outside the panel.

**Polish:**
- The panel drops in like a card being set down, with `card_slam` played quietly, and lifts away when it closes.
- Moving the music slider changes the volume live. Letting go of the effects slider plays a sample effect at the new volume.
- Switching to fullscreen keeps everything placed correctly.
- While the panel is open, the title behind it dims a little but keeps moving.

**Assets:** `ui/panel.png` and `button.png`, and `sfx/card_slam`, `ui_click` and `ui_hover`.

**Check:**
- Change every setting, quit, relaunch, and see that each one was kept.
- Every way of closing the panel works.
- No errors.

**Open question for the user:** there's no art for slider handles or the toggle. The options are to reuse a piece we have (`path_dot`, `coin`, `flag`), or for the user to make one small image.

### Part 3: Setup screen and match state

**Goal:** Play leads to the setup screen. Choose 2 to 8 players and type a name for each. Begin is ready once the setup is valid, and Back returns to the title.

**Builds:**
- **`Match`, the one place match state lives** (see tech.md). Part 3 holds the players and their names. It's built so the later parts can add monster, blood, coins, position, trophies and stats, and so the rules code is the only thing that changes it. Later, online play has the host run it.
- **The setup screen.** Each player is a paper name card with a typed name. Add and remove buttons change the count, with a minimum of 2 and a maximum of 8.
- **Name rules** (Claude's choice):
  - Names are trimmed and capped at 12 characters.
  - A blank name falls back to "Player N".
  - Duplicate names are refused, so players can tell each other apart before they have colors.
- **Turkish characters:** the players are in Turkey, so ç, ğ, ı, İ, ö, ş and ü must type and display correctly in both fonts.
- **Begin** stores the players in `Match`. It leads to the turn order roll once part 4 builds it.

**Polish:**
- A new card slides in from the side and settles with a wobble. A removed card crumples away with `crumple`.
- The add button refuses past 8 with `ui_denied` and a shake, and the remove button does the same below 2.
- The text cursor and the selected name look like ink on paper.
- A duplicate name shakes its card.
- `title.ogg` carries on from the title without restarting.
- Play and Back use the same paper transition.

**Assets:** `ui/card.png`, `button.png` and `panel.png`, and `sfx/crumple`, `ui_denied`, `ui_click` and `ui_hover`.

**Check:**
- Fill in 2 players and 8 players.
- Type Turkish names.
- Try the edge cases: blank names, duplicates, adding past 8, removing below 2.
- Leave and come back to see the cards are rebuilt cleanly.
- Confirm the contents of `Match` in the log.

## Roadmap

Very rough, past part 3.

4. The timer candle (shared by every decision), and the turn order roll: name cards shuffle and settle.
5. Monster select: the row of 8, reverse-order picks, greyed-out monsters, pick voices, and the 30 s candle.
6. The board's scenery: sky tints, parallax layers and props for all 5 locations, and the life in it (fog, bats, flickering lamps and torches).
7. The board path: spaces built from data, icons, path dots, both splits, signposts, and the castle gate.
8. Monster pieces: the stand, the shadow, hopping and flipping, and the camera following the active player.
9. The HUD: the portrait strip with blood and coins, the raised active portrait, and the turn counter.
10. The die and the turn loop: roll, move, `turn_start`, and the roll timer.
11. Quick spaces: coin, spikes, thief and church, with icons flying to the HUD.
12. Death and respawn: crumple, fly to the start, unfold.
13. Splits: signpost arrows and the path timer.
14. Board audio: ambience follows the camera, and the music follows the leader.
15. Challenge: pick an opponent, then a stake card, with invalid stakes greyed out and the 20 s timer.
16. The VS card, the countdown, and the coin flip.
17. Duel results: the win pose and the crumple, voices, gold and blood flying across, deaths in duels, and the swap.
18. The swap handicap (3 rounds), the no-opponent fallback, and finishing at the castle gate (the flag and `sting_finish`).
19. Match end: 12 turns, `sting_final_turn`, the early end, and tracking the stats.
20. The trophy ceremony: the curtain, drumrolls, trophies, and the leaderboard with its tiebreaker.
21. Fun stats, then back to the setup screen.
22. Esc settings during a match, and a translation and edge-case sweep.
23. Full playtests and tuning: board length and the 12 turns.
24. Bug bash and the final polish pass.

## Part notes

Each part session adds a few lines when it finishes: what got built, what changed from the plan, surprises, and anything left over or buggy. The next Microplan reads these instead of the code.

## Log

- **2026-10-23, Microplan 1:** planned parts 1 to 3: the foundation and title, settings, and setup. Sketched the roadmap to part 24.
